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
    // MARK: Public properties

    var frame: CVPixelBuffer?
    var camera: ARCamera?
    var lane: ARLane?

    // MARK: Private properties

    /// The `ARScene` object to be rendered.
    private let scene = ARScene()
    /// The Metal device this renderer uses for rendering.
    private let device: MTLDevice
    /// The Metal command queue this renderer uses for rendering.
    private let commandQueue: MTLCommandQueue
    /// The mesh for AR lane in scene.
    private var laneMesh: MTKMesh?

    private let samplerStateDefault: MTLSamplerState
    private let depthStencilStateDefault: MTLDepthStencilState

    #if !targetEnvironment(simulator)
        private var textureCache: CVMetalTextureCache?
    #endif

    private let vertexDescriptor: MDLVertexDescriptor = ARRenderer.makeVertexDescriptor()
    private let backgroundVertexBuffer: MTLBuffer
    private let renderPipelineDefault: MTLRenderPipelineState
    private let renderPipelineLane: MTLRenderPipelineState
    private let renderPipelineBackground: MTLRenderPipelineState

    private var viewProjectionMatrix = matrix_identity_float4x4

    // MARK: Lifecycle

    /**
     Creates a renderer with the specified Metal device.

     - Parameters:
       - device: A Metal device used for drawing.
       - colorPixelFormat: The color pixel format for the current drawable's texture.
       - depthStencilPixelFormat: The format used to generate the packed depth/stencil texture.

     - Returns: A new renderer object.
     */
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
            let defaultVertexFunction = library.makeFunction(name: ARConstants.ShaderName.defaultVertexMain),
            let arrowVertexFunction = library.makeFunction(name: ARConstants.ShaderName.arrowVertexMain),
            let backgroundVertexFunction = library.makeFunction(name: ARConstants.ShaderName.mapTextureVertex),
            let defaultFragmentFunction = library.makeFunction(name: ARConstants.ShaderName.defaultFragmentMain),
            let arrowFragmentFunction = library.makeFunction(name: ARConstants.ShaderName.laneFragmentMain),
            let backgroundFragmentFunction = library.makeFunction(name: ARConstants.ShaderName.displayTextureFragment)
        else {
            throw ARRendererError.cantFindFunctions
        }

        renderPipelineDefault = try ARRenderer.makeRenderPipeline(
            device: device,
            vertexDescriptor: vertexDescriptor,
            vertexFunction: defaultVertexFunction,
            fragmentFunction: defaultFragmentFunction,
            colorPixelFormat: colorPixelFormat,
            depthStencilPixelFormat: depthStencilPixelFormat
        )

        renderPipelineLane = try ARRenderer.makeRenderPipeline(
            device: device,
            vertexDescriptor: vertexDescriptor,
            vertexFunction: arrowVertexFunction,
            fragmentFunction: arrowFragmentFunction,
            colorPixelFormat: colorPixelFormat,
            depthStencilPixelFormat: depthStencilPixelFormat
        )

        renderPipelineBackground = try ARRenderer.makeRenderBackgroundPipeline(
            device: device,
            vertexDescriptor: ARRenderer.makeTextureMappingVertexDescriptor(),
            vertexFunction: backgroundVertexFunction,
            fragmentFunction: backgroundFragmentFunction,
            colorPixelFormat: colorPixelFormat,
            depthStencilPixelFormat: depthStencilPixelFormat
        )

        samplerStateDefault = ARRenderer.makeDefaultSamplerState(device: device)
        depthStencilStateDefault = ARRenderer.makeDefaultDepthStencilState(device: device)

        guard let buffer = device.makeBuffer(bytes: ARConstants.textureMappingVertices,
                                             length: ARConstants.textureMappingVertices.count * MemoryLayout<Float>.size,
                                             options: [])
        else { throw ARRendererError.cantCreateBuffer }
        backgroundVertexBuffer = buffer

        super.init()
    }

    // MARK: Public functions

    func initARSceneForARLane() throws {
        scene.rootNode.removeAllChildNodes()
        laneMesh = try self.loadMesh(named: ARConstants.arLaneMeshName)
        scene.rootNode.add(childNode: ARLaneNode())
    }

    func set(laneVisualParameters: LaneVisualParams) {
        if let arLaneNode = scene.arLaneNode() {
            arLaneNode.set(laneColor: laneVisualParameters.color)
            arLaneNode.set(laneWidth: laneVisualParameters.width)
            arLaneNode.set(laneLightPosition: ARRenderer.renderCoordinate(from: laneVisualParameters.lightPosition))
            arLaneNode.set(laneLightColor: laneVisualParameters.lightColor)
            arLaneNode.set(laneAmbientColor: laneVisualParameters.ambientColor)
        }
    }

    // MARK: Private functions

    private func drawScene(commandEncoder: MTLRenderCommandEncoder, lane: ARLane) {
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        commandEncoder.setDepthStencilState(depthStencilStateDefault)
        commandEncoder.setRenderPipelineState(renderPipelineDefault)
        commandEncoder.setFragmentSamplerState(samplerStateDefault, index: 0)

        let viewMatrix = makeViewMatrix(
            trans: scene.cameraNode.position,
            rot: scene.cameraNode.rotation
        )
        viewProjectionMatrix = scene.cameraNode.projectionMatrix() * viewMatrix

        if let arLaneNode = scene.arLaneNode() {
            commandEncoder.setRenderPipelineState(renderPipelineLane)

            let modelMatrix = arLaneNode.worldTransform()
            let material = arLaneNode.arMaterial

            let points = lane.curve.getControlPoints()

            guard points.count == 4 else {
                assertionFailure("ARLane should contains four points")
                return
            }

            var vertexUniforms = ArrowVertexUniforms(
                viewProjectionMatrix: viewProjectionMatrix,
                modelMatrix: modelMatrix,
                normalMatrix: normalMatrix(mat: modelMatrix),
                laneWidth: arLaneNode.width,
                p0: ARRenderer.renderCoordinate(from: points[0]),
                p1: ARRenderer.renderCoordinate(from: points[1]),
                p2: ARRenderer.renderCoordinate(from: points[2]),
                p3: ARRenderer.renderCoordinate(from: points[3])
            )
            commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<ArrowVertexUniforms>.size, index: 1)

            var fragmentUniforms = FragmentUniforms(cameraWorldPosition: scene.cameraNode.position,
                                                    ambientLightColor: material.ambientLightColor,
                                                    specularColor: material.specularColor,
                                                    baseColor: material.diffuseColor.xyz,
                                                    opacity: material.diffuseColor.w,
                                                    specularPower: material.specularPower,
                                                    light: material.light)

            commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
            commandEncoder.setFrontFacing(material.frontFaceMode)

            guard let laneMesh = laneMesh else {
                return
            }

            let vertexBuffer = laneMesh.vertexBuffers.first!
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)

            for submesh in laneMesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
    }

    private func update(_ view: MTKView) {
        guard let camParams = camera else { return }
        scene.cameraNode.aspectRatio = camParams.aspectRatio
        scene.cameraNode.fovRadians = camParams.fov
        scene.cameraNode.rotation = simd_quatf.byAxis(camParams.roll - Float.pi / 2, -camParams.pitch, 0)

        scene.cameraNode.position = float3(0, camParams.height, 0)
    }

    func makeTexture(from buffer: CVPixelBuffer) -> MTLTexture? {
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

    /**
     Load the mesh with a specific name.

     - Parameters:
       - name: name of the mesh to load.

     - Throws:
       - `ARMeshError.cantFindMeshFile` in case there's no mesh file with specified name.
       - `ARMeshError.meshFileIsEmpty` in case mesh file is present, but it's empty.

     - Returns:
       Instance of `MTKMesh` suitable for use in a Metal app.
     */
    private func loadMesh(named name: String) throws -> MTKMesh {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        guard let meshURL = Bundle(for: type(of: self)).url(forResource: name, withExtension: "obj") else {
            throw ARMeshError.cantFindMeshFile(name)
        }
        let meshAsset = MDLAsset(url: meshURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        let meshes = try MTKMesh.newMeshes(asset: meshAsset, device: device).metalKitMeshes
        guard let mesh = meshes.first else { throw ARMeshError.meshFileIsEmpty(name) }
        return mesh
    }
}

extension ARRenderer {
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

    static func makeRenderBackgroundPipeline(
        device: MTLDevice,
        vertexDescriptor: MTLVertexDescriptor,
        vertexFunction: MTLFunction,
        fragmentFunction: MTLFunction,
        colorPixelFormat: MTLPixelFormat,
        depthStencilPixelFormat: MTLPixelFormat
    ) throws -> MTLRenderPipelineState {
        let pipeline = MTLRenderPipelineDescriptor()
        pipeline.vertexFunction = vertexFunction
        pipeline.fragmentFunction = fragmentFunction

        pipeline.colorAttachments[0].pixelFormat = colorPixelFormat
        pipeline.depthAttachmentPixelFormat = depthStencilPixelFormat

        pipeline.vertexDescriptor = vertexDescriptor

        return try device.makeRenderPipelineState(descriptor: pipeline)
    }

    static func makeRenderPipeline(
        device: MTLDevice,
        vertexDescriptor: MDLVertexDescriptor,
        vertexFunction: MTLFunction,
        fragmentFunction: MTLFunction,
        colorPixelFormat: MTLPixelFormat,
        depthStencilPixelFormat: MTLPixelFormat
    ) throws -> MTLRenderPipelineState {
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

    static func renderCoordinate(from worldCoordinate: WorldCoordinate) -> float3 {
        return float3(Float(-worldCoordinate.y), Float(worldCoordinate.z), Float(-worldCoordinate.x))
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
