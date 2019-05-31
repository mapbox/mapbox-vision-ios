// swiftlint:disable comma

import simd

enum ARConstants {
    static let ARLaneDefaultColor = float4(0.2745, 0.4117, 0.949, 0.99)
    static let textureMappingVertices: [Float] = [
        // X   Y    Z       U    V
        -1.0, -1.0, 0.0,    0.0, 1.0,
         1.0, -1.0, 0.0,    1.0, 1.0,
        -1.0,  1.0, 0.0,    0.0, 0.0,

         1.0,  1.0, 0.0,    1.0, 0.0,
         1.0, -1.0, 0.0,    1.0, 1.0,
        -1.0,  1.0, 0.0,    0.0, 0.0
    ]

    enum ShaderName {
        static let defaultVertexMain = "default_vertex_main"
        static let arrowVertexMain = "arrow_vertex_main"
        static let mapTextureVertex =  "map_texture_vertex"
        static let defaultFragmentMain = "default_fragment_main"
        static let laneFragmentMain = "lane_fragment_main"
        static let displayTextureFragment = "display_texture_fragment"
    }
}
