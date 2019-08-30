import Foundation
import MapboxVisionNative

extension CoreConfig {
    static var basic: CoreConfig {
        let config = CoreConfig()

        config.useDetectionMapping = true

        return config
    }
}
