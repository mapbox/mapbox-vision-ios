/// The error that occurred during creation AR mesh.
enum ARMeshError: LocalizedError {
    /// Mesh file can't be found. Parametrized with name of resource file that contains mesh.
    case cantFindMeshFile(String)
    /// Mesh file is empty. Parametrized with name of resource file that contains mesh.
    case meshFileIsEmpty(String)

    var errorDescription: String? {
        switch self {
        case .cantFindMeshFile(let fileName):
            return "Mesh file \(fileName) can't be found."
        case .meshFileIsEmpty(let fileName):
            return "Mesh file \(fileName) is empty."
        }
    }
}
