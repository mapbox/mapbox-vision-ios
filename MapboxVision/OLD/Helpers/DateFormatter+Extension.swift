import Foundation

extension DateFormatter {
    static func createRecordingFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ssZ"
        return dateFormatter
    }
}
