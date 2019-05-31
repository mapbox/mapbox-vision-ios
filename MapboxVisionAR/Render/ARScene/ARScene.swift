class ARScene {
    // MARK: - Properties

    var rootNode = ARRootNode()
    var cameraNode = ARCameraNode()

    // MARK: - Public methods

    func getChildARLaneNodes() -> [ARLaneNode] {
        return rootNode.childs.compactMap { $0 as? ARLaneNode }
    }
}
