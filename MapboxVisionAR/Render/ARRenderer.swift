import MetalKit
import MapboxVision
import MapboxVisionARNative

// design
let kArrowColor = float4(0.2745, 0.4117, 0.949, 0.99)
let kGridColor = float4(0.952, 0.0549, 0.3607, 0.95)

// world transforms
let kTurnOffsetAfterOriginM = Float(10)  // meters
let kArrowMaxLengthM        = Float(25)  // meters
let kMinArrowMidOffset      = Float(0.5) // meters
let kAnimResetArrowSpeed    = Float(10)  // meters / sec

struct DefaultVertexUniforms {
    var viewProjectionMatrix: float4x4
    var modelMatrix: float4x4
    var normalMatrix: float3x3
}

struct ArrowVertexUniforms {
    var viewProjectionMatrix: float4x4
    var modelMatrix: float4x4
    var normalMatrix: float3x3
    var p0: float3
    var p1: float3
    var p2: float3
    var p3: float3
}

struct FragmentUniforms {
    var cameraWorldPosition = float3(0, 0, 0)
    var ambientLightColor = float3(0, 0, 0)
    var specularColor = float3(1, 1, 1)
    var baseColor = float3(1, 1, 1)
    var opacity = Float(1)
    var specularPower = Float(1)
    var light = ARLight()
}

struct LaneFragmentUniforms {
    var baseColor = float4(1, 1, 1, 1)
};

private let textureMappingVertices: [Float] = [
//   X     Y    Z       U    V
    -1.0, -1.0, 0.0,    0.0, 1.0,
     1.0, -1.0, 0.0,    1.0, 1.0,
    -1.0,  1.0, 0.0,    0.0, 0.0,
    
     1.0,  1.0, 0.0,    1.0, 0.0,
     1.0, -1.0, 0.0,    1.0, 1.0,
    -1.0,  1.0, 0.0,    0.0, 0.0
]

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

class ARRenderer: NSObject, MTKViewDelegate {
    
    private let device: MTLDevice
    #if !targetEnvironment(simulator)
    private var textureCache: CVMetalTextureCache?
    #endif
    private let commandQueue: MTLCommandQueue
    private let vertexDescriptor: MDLVertexDescriptor = ARRenderer.makeVertexDescriptor()
    private let renderPipelineDefault: MTLRenderPipelineState
    private let renderPipelineArrow: MTLRenderPipelineState
    private let renderPipelineBackground: MTLRenderPipelineState
    private let samplerStateDefault: MTLSamplerState
    private let depthStencilStateDefault: MTLDepthStencilState
    
    private var viewProjectionMatrix = matrix_identity_float4x4
    private var defaultLight = ARLight()
    
    private let scene = ARScene()
    private var time = Float(0)
    private var dt = Float(0)
    
    private let gridNode = ARNode(name: "Grid")
    private let arrowNode = ARNode(name: "Arrow")
    private let bundle = Bundle(for: ARRenderer.self)
    
    private var arrowStartPoint = float3(0, 0, 0)
    private var arrowEndPoint = float3(0, 0, 0)
    private var arrowMidPoint = float3(0, 0, 0)
    
    private let backgroundVertexBuffer: MTLBuffer
    
    enum ARRendererError: LocalizedError {
        case cantCreateCommandQueue
        case cantCreateTextureCache
        case cantCreateBuffer
        case cantFindMeshFile(String)
        case meshFileIsEmpty(String)
        case cantFindFunctions
    }
    
    public var frame: CVPixelBuffer?
    public var camera: ARCamera?
    public var lane: ARLane?
    
    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat, depthStencilPixelFormat: MTLPixelFormat) throws {
        self.device = device
        
        #if !targetEnvironment(simulator)
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache) == kCVReturnSuccess else {
            throw ARRendererError.cantCreateTextureCache
        }
        #endif
        guard let commandQueue = device.makeCommandQueue() else { throw ARRendererError.cantCreateCommandQueue }
        self.commandQueue = commandQueue
        self.commandQueue.label = "com.mapbox.ARRenderer"
        
        let library = try device.makeDefaultLibrary(bundle: bundle)
        
        guard
        let defaultVertexFunction = library.makeFunction(name: "default_vertex_main"),
        let arrowVertexFunction = library.makeFunction(name: "arrow_vertex_main"),
        let backgroundVertexFunction = library.makeFunction(name: "map_texture_vertex"),
        let defaultFragmentFunction = library.makeFunction(name: "default_fragment_main"),
        let arrowFragmentFunction = library.makeFunction(name: "lane_fragment_main"),
        let backgroundFragmentFunction = library.makeFunction(name: "display_texture_fragment")
        else { throw ARRendererError.cantFindFunctions }
        
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
        
        guard let buffer = device.makeBuffer(bytes: textureMappingVertices, length: textureMappingVertices.count * MemoryLayout<Float>.size, options: []) else {
            throw ARRendererError.cantCreateBuffer
        }
        backgroundVertexBuffer = buffer
            
        super.init()
    }
    
    private func loadMesh(name: String) throws -> MTKMesh {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        guard let meshURL = bundle.url(forResource: name, withExtension: "obj") else {
            throw ARRendererError.cantFindMeshFile(name)
        }
        let meshAsset = MDLAsset(url: meshURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        let meshes = try MTKMesh.newMeshes(asset: meshAsset, device: device).metalKitMeshes
        guard let mesh = meshes.first else { throw ARRendererError.meshFileIsEmpty(name) }
        return mesh
    }
    
    func initScene() {
        // load resources
//        let gridMesh = loadMesh(name: "grid")
//        let gridEntity = AREntity(mesh: gridMesh)
//        gridEntity.material.diffuseColor = kGridColor
//        gridEntity.material.specularPower = 500
//        gridNode.entity = gridEntity
//        scene.rootNode.add(child: gridNode)

        do {
            let arrowMesh = try loadMesh(name: "lane")
            let arrowEntity = AREntity(mesh: arrowMesh)
            arrowEntity.material.diffuseColor = kArrowColor
            arrowEntity.material.specularPower = 100
            arrowEntity.material.specularColor = float3(1, 1, 1) //kArrowColor.xyz
            arrowEntity.material.ambientLightColor = kArrowColor.xyz //float3(0.5, 0.5, 0.5)
            arrowEntity.renderPipeline = renderPipelineArrow
            
            arrowNode.entity = arrowEntity
            arrowNode.position = float3(0, 0, 0)
            scene.rootNode.add(child: arrowNode)
            
            // configure default light
            defaultLight = ARLight(color: float3(1, 1, 1), position: float3(0, 7, 0))
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    static func makeVertexDescriptor() -> MDLVertexDescriptor {
        
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float3,
            offset: 0,
            bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: MemoryLayout<Float>.size * 3,
            bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: MemoryLayout<Float>.size * 6,
            bufferIndex: 0)
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
    
    func update(_ view: MTKView) {
        dt = 1 / Float(view.preferredFramesPerSecond)
        time += dt
        
        guard let camParams = camera else { return }
        scene.camera.aspectRatio = camParams.aspectRatio
        scene.camera.fovRadians = camParams.fov
        scene.camera.rotation = simd_quatf.byAxis(camParams.roll - Float.pi / 2, -camParams.pitch, 0)

        scene.camera.position = float3(0, camParams.height, 0);
    }
    
    func drawScene(commandEncoder: MTLRenderCommandEncoder, lane: ARLane) {
        
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        commandEncoder.setDepthStencilState(depthStencilStateDefault)
        commandEncoder.setRenderPipelineState(renderPipelineDefault)
        commandEncoder.setFragmentSamplerState(samplerStateDefault, index: 0)
        
        let viewMatrix = makeViewMatrix(trans: scene.camera.position, rot: scene.camera.rotation)
        viewProjectionMatrix = scene.camera.projectionMatrix() * viewMatrix
        
        // TODO: reorder for less pixeloverdraw
        scene.rootNode.childs.forEach { (node) in
            if let entity = node.entity, let mesh = entity.mesh {
                
                if let pipeline = entity.renderPipeline {
                    commandEncoder.setRenderPipelineState(pipeline)
                } else {
                    commandEncoder.setRenderPipelineState(renderPipelineDefault)
                }

                let modelMatrix = node.worldTransform()
                let material = entity.material
                // TODO: make it in common case
                if node === arrowNode {
                    let points = lane.curve.getControlPoints();
                    
                    guard points.count == 4 else {
                        assertionFailure("ARLane should contains four points")
                        return
                    }

                    let arrowControlPoints = [
                        ARRenderer.processPoint(points[0]),
                        ARRenderer.processPoint(points[1]),
                        ARRenderer.processPoint(points[2]),
                        ARRenderer.processPoint(points[3]),
                    ]
                    
                    var vertexUniforms = ArrowVertexUniforms(
                        viewProjectionMatrix: viewProjectionMatrix,
                        modelMatrix: modelMatrix,
                        normalMatrix: normalMatrix(mat: modelMatrix),
                        p0: arrowControlPoints[0],
                        p1: arrowControlPoints[1],
                        p2: arrowControlPoints[2],
                        p3: arrowControlPoints[3])
                    commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<ArrowVertexUniforms>.size, index: 1)
                    
//                    var fragmentUniforms = LaneFragmentUniforms(baseColor: material.diffuseColor)
//
//                    commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<LaneFragmentUniforms>.size, index: 0)
                } else {
                    var vertexUniforms = DefaultVertexUniforms(
                        viewProjectionMatrix: viewProjectionMatrix,
                        modelMatrix: modelMatrix,
                        normalMatrix: normalMatrix(mat: modelMatrix))
                    commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<DefaultVertexUniforms>.size, index: 1)
                    
                    
                }
                
                let light = material.light ?? defaultLight
                var fragmentUniforms = FragmentUniforms(cameraWorldPosition: scene.camera.position,
                                                        ambientLightColor: material.ambientLightColor,
                                                        specularColor: material.specularColor,
                                                        baseColor: material.diffuseColor.xyz,
                                                        opacity: material.diffuseColor.w,
                                                        specularPower: material.specularPower,
                                                        light: light)
                
                commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)

                commandEncoder.setFrontFacing(material.frontFaceMode)

                // commandEncoder.setFragmentTexture(baseColorTexture, index: 0)

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
            commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: textureMappingVertices.count)
        }

        if let lane = lane {
            drawScene(commandEncoder: commandEncoder, lane: lane)
        }
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func makeTexture(from buffer: CVPixelBuffer) -> MTLTexture? {
        #if !targetEnvironment(simulator)
        var imageTexture: CVMetalTexture?
        guard let textureCache = textureCache,
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, buffer, nil, .bgra8Unorm, CVPixelBufferGetWidth(buffer), CVPixelBufferGetHeight(buffer), 0, &imageTexture) == kCVReturnSuccess
        else { return nil }
        return CVMetalTextureGetTexture(imageTexture!)
        #else
        return nil
        #endif
    }
}
