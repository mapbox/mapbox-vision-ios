import Foundation

extension UserDefaults {
    func setDefaultValue(_ value: Any?, forKey: String) {
        if object(forKey: forKey) == nil {
            setValue(value, forKey: forKey)
        }
    }
}
