import MapboxVision
import MapboxVisionARNative
import MetalKit

/* Render coordinate system:
 *      Y
 *      ^
 *      |
 *      0 -----> X
 *     /
 *    /
 *   Z
 */

/* World coordinate system:
 *       Z
 *       ^  X
 *       | /
 *       |/
 * Y <-- 0
 */


class ARRenderer: NSObject {
    // MARK: - Private properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue

    #if !targetEnvironment(simulator)
    private var textureCache: CVMetalTextureCache?
    #endif

    private let vertexDescriptor: MDLVertexDescriptor = ARRenderer.makeVertexDescriptor()
    private let backgroundVertexBuffer: MTLBuffer
    private let renderPipelineDefault: MTLRenderPipelineState
    private let renderPipelineArrow: MTLRenderPipelineState
    private let renderPipelineBackground: MTLRenderPipelineState
    private let samplerStateDefault: MTLSamplerState
    private let depthStencilStateDefault: MTLDepthStencilState

    private var viewProjectionMatrix = matrix_identity_float4x4

    private let scene = ARScene()

    private var time = Float(0)
    private var dt = Float(0)

    // MARK: - Public properties

    public var frame: CVPixelBuffer?
    public var camera: ARCamera?
    public var lane: ARLane?

    // MARK: - Lifecycle

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat, depthStencilPixelFormat: MTLPixelFormat) throws {
        self.device = device

        guard let commandQueue = device.makeCommandQueue() else { throw ARRendererError.cantCreateCommandQueue }
        self.commandQueue = commandQueue
        self.commandQueue.label = "com.mapbox.ARRenderer"

        #if !targetEnvironment(simulator)
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache) == kCVReturnSuccess else {
            throw ARRendererError.cantCreateTextureCache
        }
        #endif


        let library = try device.makeDefaultLibrary(bundle: Bundle(for: type(of: self)))
        guard
            let defaultVertexFunction = library.makeFunction(name: "default_vertex_main"), // TODO: name to const
            let arrowVertexFunction = library.makeFunction(name: "arrow_vertex_main"),
            let backgroundVertexFunction = library.makeFunction(name: "map_texture_vertex"),
            let defaultFragmentFunction = library.makeFunction(name: "default_fragment_main"),
            let arrowFragmentFunction = library.makeFunction(name: "lane_fragment_main"),
            let backgroundFragmentFunction = library.makeFunction(name: "display_texture_fragment")
            else {
                throw ARRendererError.cantFindFunctions
        }

        renderPipelineDefault = try ARRenderer.makeRenderPipeline(device: device,
                                                                  vertexDescriptor: vertexDescriptor,
                                                                  vertexFunction: defaultVertexFunction,
                                                                  fragmentFunction: defaultFragmentFunction,
                                                                  colorPixelFormat: colorPixelFormat,
                                                                  depthStencilPixelFormat: depthStencilPixelFormat)

        renderPipelineArrow = try ARRenderer.makeRenderPipeline(device: device,
                                                                vertexDescriptor: vertexDescriptor,
                                                                vertexFunction: arrowVertexFunction,
                                                                fragmentFunction: arrowFragmentFunction,
                                                                colorPixelFormat: colorPixelFormat,
                                                                depthStencilPixelFormat: depthStencilPixelFormat)

        renderPipelineBackground = try ARRenderer.makeRenderBackgroundPipeline(device: device,
                                                                               vertexDescriptor: ARRenderer.makeTextureMappingVertexDescriptor(),
                                                                               vertexFunction: backgroundVertexFunction,
                                                                               fragmentFunction: backgroundFragmentFunction,
                                                                               colorPixelFormat: colorPixelFormat,
                                                                               depthStencilPixelFormat: depthStencilPixelFormat)

        samplerStateDefault = ARRenderer.makeDefaultSamplerState(device: device)
        depthStencilStateDefault = ARRenderer.makeDefaultDepthStencilState(device: device)

        guard let buffer = device.makeBuffer(bytes: ARConstants.textureMappingVertices,
                                             length: ARConstants.textureMappingVertices.count * MemoryLayout<Float>.size,
                                             options: [])
            else {
                throw ARRendererError.cantCreateBuffer
        }
        backgroundVertexBuffer = buffer

        super.init()
    }

    // MARK: Static functions

    static func makeVertexDescriptor() -> MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float3,
            offset: 0,
            bufferIndex: 0
        )
        vertexDescriptor.attributes[1] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: MemoryLayout<Float>.size * 3,
            bufferIndex: 0
        )
        vertexDescriptor.attributes[2] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: MemoryLayout<Float>.size * 6,
            bufferIndex: 0
        )
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        return vertexDescriptor
    }

    static func makeTextureMappingVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 3
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 5
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        return vertexDescriptor
    }

    static func makeRenderBackgroundPipeline(device: MTLDevice,
                                             vertexDescriptor: MTLVertexDescriptor,
                                             vertexFunction: MTLFunction,
                                             fragmentFunction: MTLFunction,
                                             colorPixelFormat: MTLPixelFormat,
                                             depthStencilPixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {

        let pipeline = MTLRenderPipelineDescriptor()
        pipeline.vertexFunction = vertexFunction
        pipeline.fragmentFunction = fragmentFunction

        pipeline.colorAttachments[0].pixelFormat = colorPixelFormat
        pipeline.depthAttachmentPixelFormat = depthStencilPixelFormat

        pipeline.vertexDescriptor = vertexDescriptor

        return try device.makeRenderPipelineState(descriptor: pipeline)
    }

    static func makeRenderPipeline(device: MTLDevice,
                                   vertexDescriptor: MDLVertexDescriptor,
                                   vertexFunction: MTLFunction,
                                   fragmentFunction: MTLFunction,
                                   colorPixelFormat: MTLPixelFormat,
                                   depthStencilPixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {

        let pipeline = MTLRenderPipelineDescriptor()
        pipeline.vertexFunction = vertexFunction
        pipeline.fragmentFunction = fragmentFunction

        pipeline.colorAttachments[0].pixelFormat = colorPixelFormat
        pipeline.colorAttachments[0].isBlendingEnabled = true
        pipeline.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
        pipeline.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
        pipeline.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha
        pipeline.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha
        pipeline.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        pipeline.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        pipeline.depthAttachmentPixelFormat = depthStencilPixelFormat

        let mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        pipeline.vertexDescriptor = mtlVertexDescriptor

        return try device.makeRenderPipelineState(descriptor: pipeline)
    }

    static func makeDefaultSamplerState(device: MTLDevice) -> MTLSamplerState {
        let sampler = MTLSamplerDescriptor()

        sampler.minFilter = .linear
        sampler.mipFilter = .linear
        sampler.magFilter = .linear

        sampler.normalizedCoordinates = true
        return device.makeSamplerState(descriptor: sampler)!
    }

    static func makeDefaultDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
        let depthStencil = MTLDepthStencilDescriptor()

        depthStencil.isDepthWriteEnabled = true
        depthStencil.depthCompareFunction = .less

        return device.makeDepthStencilState(descriptor: depthStencil)!
    }

    static func processPoint(_ wc: WorldCoordinate) -> float3 {
        return float3(Float(-wc.y), Float(wc.z), Float(-wc.x))
    }

    // MARK: - Public functions

    func initARScene() {
        scene.rootNode.removeAllChilds()

        let arLaneMesh = ARLaneMesh(device: device, vertexDescriptor: vertexDescriptor)
        let arLaneEntity = ARLaneEntity(with: arLaneMesh, and: renderPipelineArrow)
        let arrowNode = ARLaneNode(arLaneEntity: arLaneEntity)
        scene.rootNode.add(child: arrowNode)
    }

    func set(arLaneColor: UIColor) {
        scene.getChildARLaneNodes()?.first?.set(laneColor: arLaneColor)
    }

    func set(arLaneWidth: Float) {
        scene.getChildARLaneNodes()?.first?.set(laneWidth: arLaneWidth)
    }

    func set(arLight: ARLight) {
        scene.getChildARLaneNodes()?.first?.set(light: arLight)
    }

    func set(arlaneLightColor: UIColor) {
        scene.getChildARLaneNodes()?.first?.set(laneLightColor: arlaneLightColor)
    }

    func set(arLaneAmbientColor: UIColor) {
        scene.getChildARLaneNodes()?.first?.set(laneAmbientColor: arLaneAmbientColor)
    }

    func drawScene(commandEncoder: MTLRenderCommandEncoder, lane: ARLane) {
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        commandEncoder.setDepthStencilState(depthStencilStateDefault)
        commandEncoder.setRenderPipelineState(renderPipelineDefault)
        commandEncoder.setFragmentSamplerState(samplerStateDefault, index: 0)

        let viewMatrix = makeViewMatrix(trans: scene.cameraNode.position, rot: scene.cameraNode.rotation)
        viewProjectionMatrix = scene.cameraNode.projectionMatrix() * viewMatrix

        scene.rootNode.childs.forEach { arNode in
            if let arEntity = arNode.entity, let mesh = arEntity.mesh {
                commandEncoder.setRenderPipelineState(arEntity.renderPipeline ?? renderPipelineDefault)

                let modelMatrix = arNode.worldTransform()
                let material = arEntity.material

                if arNode.nodeType == .arrowNode {
                    let points = lane.curve.getControlPoints();

                    guard points.count == 4 else {
                        assertionFailure("ARLane should contains four points")
                        return
                    }

                    var vertexUniforms = ArrowVertexUniforms(
                        viewProjectionMatrix: viewProjectionMatrix,
                        modelMatrix: modelMatrix,
                        normalMatrix: normalMatrix(mat: modelMatrix),
                        p0: ARRenderer.processPoint(points[0]),
                        p1: ARRenderer.processPoint(points[1]),
                        p2: ARRenderer.processPoint(points[2]),
                        p3: ARRenderer.processPoint(points[3])
                    )
                    commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<ArrowVertexUniforms>.size, index: 1)
                } else {
                    var vertexUniforms = DefaultVertexUniforms(
                        viewProjectionMatrix: viewProjectionMatrix,
                        modelMatrix: modelMatrix,
                        normalMatrix: normalMatrix(mat: modelMatrix)
                    )
                    commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<DefaultVertexUniforms>.size, index: 1)
                }

                var fragmentUniforms = FragmentUniforms(cameraWorldPosition: scene.cameraNode.position,
                                                        ambientLightColor: material.ambientLightColor,
                                                        specularColor: material.specularColor,
                                                        baseColor: material.diffuseColor.xyz,
                                                        opacity: material.diffuseColor.w,
                                                        specularPower: material.specularPower,
                                                        light: material.light ?? ARLight.defaultLightForLane())

                commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
                commandEncoder.setFrontFacing(material.frontFaceMode)

                let vertexBuffer = mesh.vertexBuffers.first!
                commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)

                for submesh in mesh.submeshes {
                    let indexBuffer = submesh.indexBuffer
                    commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                         indexCount: submesh.indexCount,
                                                         indexType: submesh.indexType,
                                                         indexBuffer: indexBuffer.buffer,
                                                         indexBufferOffset: indexBuffer.offset)
                }
            }
        }
    }

    // MARK: - Private functions

    private func update(_ view: MTKView) {
        dt = 1 / Float(view.preferredFramesPerSecond)
        time += dt

        guard let camParams = camera else { return }
        scene.cameraNode.aspectRatio = camParams.aspectRatio
        scene.cameraNode.fovRadians = camParams.fov
        scene.cameraNode.rotation = simd_quatf.byAxis(camParams.roll - Float.pi / 2, -camParams.pitch, 0)

        scene.cameraNode.position = float3(0, camParams.height, 0);
    }

    private func makeTexture(from buffer: CVPixelBuffer) -> MTLTexture? {
        #if !targetEnvironment(simulator)
        var imageTexture: CVMetalTexture?
        guard
            let textureCache = textureCache,
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                      textureCache,
                                                      buffer,
                                                      nil,
                                                      .bgra8Unorm,
                                                      CVPixelBufferGetWidth(buffer),
                                                      CVPixelBufferGetHeight(buffer),
                                                      0,
                                                      &imageTexture) == kCVReturnSuccess
            else { return nil }
        return CVMetalTextureGetTexture(imageTexture!)
        #else
        return nil
        #endif
    }
}

extension ARRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO: update camera
    }

    func draw(in view: MTKView) {
        update(view)

        // render
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPass = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable
            else { return }

        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)

        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)
            else { return }

        if let frame = frame, let texture = makeTexture(from: frame) {
            commandEncoder.setRenderPipelineState(renderPipelineBackground)
            commandEncoder.setVertexBuffer(backgroundVertexBuffer, offset: 0, index: 0)
            commandEncoder.setFragmentTexture(texture, index: 0)
            commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: ARConstants.textureMappingVertices.count)
        }

        if let lane = lane {
            drawScene(commandEncoder: commandEncoder, lane: lane)
        }

        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
