enum RecordSynchronizerError: LocalizedError {
    case syncFileCreationFail(URL)
    case noRequestedFiles([RecordFileType], URL)
}
