enum ARMeshError: LocalizedError {
    case cantFindMeshFile(String)
    case meshFileIsEmpty(String)
}
