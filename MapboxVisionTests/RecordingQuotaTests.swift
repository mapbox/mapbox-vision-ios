import XCTest
@testable import MapboxVision

typealias Byte = Int64

private let bytesInKByte: Byte = 1024
private let kByteInMByte: Byte = 1024

private let kByte = bytesInKByte
private let mByte = kByteInMByte * kByte

private let secondsInMinute: TimeInterval = 60
private let minutesInHour: TimeInterval = 60

private let minute = secondsInMinute
private let hour = secondsInMinute * minute

private let memoryLimit = 300.0 // mb
private let networkingMemoryLimit = 30 * mByte
private let updatingInterval = 1 * hour

class RecordingQuotaTests: XCTestCase {
    // MARK: - Properties

    private var refreshInterval: TimeInterval!
    private var initialMemoryQuota: Byte!
    private var recordingQuota: RecordingQuota!

    // MARK: - Test functions

    override func setUp() {
        super.setUp()
        refreshInterval = TimeInterval.random(in: 5...10)
        initialMemoryQuota = Byte.random(in: 5...10) * kByte

        recordingQuota = RecordingQuota(memoryQuota: initialMemoryQuota, refreshInterval: refreshInterval)
    }

    override func tearDown() {
        recordingQuota = nil
        resetUserDefaultsState()
        super.tearDown()
    }

    func testReserveMethodDoesNotThrowIfTriesToReserveZeroBytes() {
        // Given
        let memoryZeroBytes: Byte = 0

        // When // Then
        XCTAssertNoThrow(_ = try recordingQuota.reserve(memoryToReserve: memoryZeroBytes))
    }

    func testReserveMethodDoesNotThrowIfMemoryQuotaWasNotExceeded() {
        // Given
        let memoryToReserveLessThanQuota = initialMemoryQuota - 1

        // When // Then
        XCTAssertNoThrow(_ = try recordingQuota.reserve(memoryToReserve: memoryToReserveLessThanQuota))
    }

    func testReserveMethodAllowsToReserveMemorySeveralTimesIfMemoryQuotaWasNotExceeded() {
        // Given
        let memoryToReserveAtOneTime = 1 * kByte
        let expectedNumberOfTimesWeCanReserveMemory = initialMemoryQuota / memoryToReserveAtOneTime

        // When
        for _ in 1...expectedNumberOfTimesWeCanReserveMemory {
            // Then
            XCTAssertNoThrow(_ = try recordingQuota.reserve(memoryToReserve: memoryToReserveAtOneTime))
        }
    }

    func testReserveMethodThrowsAfterSeveralReservationsButOnlyIfMemoryQuotaExceeded() {
        // Given
        let memoryToReserveAtOneTime = 1 * kByte
        let expectedNumberOfTimesWeCanReserveMemory = initialMemoryQuota / memoryToReserveAtOneTime

        for _ in 1...expectedNumberOfTimesWeCanReserveMemory {
            XCTAssertNoThrow(_ = try recordingQuota.reserve(memoryToReserve: memoryToReserveAtOneTime))
        }

        // When // Then
        XCTAssertThrowsError(_ = try recordingQuota.reserve(memoryToReserve: memoryToReserveAtOneTime))
    }

    func testReserveMethodThrowsIfReservesMemoryMoreThanQuota() {
        // Given
        let memoryToReserveExceedingQuota = initialMemoryQuota + 1

        // When // Then
        XCTAssertThrowsError(_ = try recordingQuota.reserve(memoryToReserve: memoryToReserveExceedingQuota))
    }

    func testReserveMethodDoesNotThrowIfCurrentQuotaWasReset() {
        // Given
        let memoryToReserveMoreThanHalfAQuota = (initialMemoryQuota / 2) + 1
        XCTAssertNoThrow(_ = try recordingQuota.reserve(memoryToReserve: memoryToReserveMoreThanHalfAQuota))

        // When
        Thread.sleep(forTimeInterval: refreshInterval)

        // Then
        XCTAssertNoThrow(_ = try recordingQuota.reserve(memoryToReserve: memoryToReserveMoreThanHalfAQuota))
    }

    func testCurrentQuotaFullyResetsWhenRefreshIntervalIsTimedOut() {
        // Given
        let memoryToReserveEqualsToQuota = initialMemoryQuota!
        XCTAssertNoThrow(_ = try recordingQuota.reserve(memoryToReserve: memoryToReserveEqualsToQuota))

        // When
        Thread.sleep(forTimeInterval: refreshInterval)

        // Then
        XCTAssertNoThrow(_ = try recordingQuota.reserve(memoryToReserve: memoryToReserveEqualsToQuota))
    }

    // MARK: - Private functions

    func resetUserDefaultsState() {
        UserDefaults.standard.removeObject(forKey: "lastResetTimeKey")
        UserDefaults.standard.removeObject(forKey: "recordingMemoryQuota")
    }
}
