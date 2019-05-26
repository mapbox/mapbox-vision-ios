extension OutputStream {
    func write(string: String) {
        let _ = string.data(using: .utf8)?.withUnsafeBytes { ptr in
            self.write(ptr, maxLength: string.lengthOfBytes(using: .utf8))
        }
    }
}
