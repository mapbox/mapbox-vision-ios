class ARScene {
    // MARK: - Properties

    var rootNode = ARNode(type: .rootNode)
    var cameraNode = ARCameraNode()

    // MARK: - Public methods

    func getChildARLaneNodes() -> [ARLaneNode]? {
        return self.rootNode.childs.filter { $0.nodeType == .arrowNode } as? [ARLaneNode]
    }
}
