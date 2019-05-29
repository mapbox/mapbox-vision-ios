// swiftlint:disable large_tuple

extension UIColor {
    func rgbaComponents() -> (CGFloat, CGFloat, CGFloat, CGFloat)? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        return self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) ? (red, green, blue, alpha) : nil
    }

    func rgbComponents() -> (CGFloat, CGFloat, CGFloat)? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0

        return self.getRed(&red, green: &green, blue: &blue, alpha: nil) ? (red, green, blue) : nil
    }
}
