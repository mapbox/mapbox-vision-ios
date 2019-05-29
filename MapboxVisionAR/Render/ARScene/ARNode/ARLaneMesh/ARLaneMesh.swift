import MetalKit

class ARLaneMesh {
    // MARK: - Public properties

    private(set) var mtkMesh: MTKMesh!

    // MARK: - Private properties

    private let device: MTLDevice!
    private let vertexDescriptor: MDLVertexDescriptor!

    // MARK: - Lifecycle

    init(device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) {
        self.device = device
        self.vertexDescriptor = vertexDescriptor
        do {
            self.mtkMesh = try loadMesh(name: "lane")
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    // MARK: Private functions

    private func loadMesh(name: String) throws -> MTKMesh {
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
