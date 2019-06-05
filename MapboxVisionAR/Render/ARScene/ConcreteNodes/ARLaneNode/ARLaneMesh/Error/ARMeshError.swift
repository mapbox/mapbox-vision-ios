/// The error that occurred during creation AR mesh.
enum ARMeshError: LocalizedError {
    /// Mesh file can't be found. Parametrized with name of resource file that contains mesh.
    case cantFindMeshFile(String)
    /// Mesh file is empty. Parametrized with name of resource file that contains mesh.
    case meshFileIsEmpty(String)
}
