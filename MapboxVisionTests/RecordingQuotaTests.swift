@testable import MapboxVision
import XCTest

class RecordingQuotaTests: XCTestCase {
    // MARK: - Private properties

    private var refreshInterval: TimeInterval!
    private var initialMemoryQuota: Byte!
    private var recordingQuota: RecordingQuota!

    // MARK: - Test functions

    override func setUp() {
        super.setUp()
        refreshInterval = TimeInterval(Int.random(in: 1...5))
        initialMemoryQuota = 10 * .kByte

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
        XCTAssertNoThrow(try recordingQuota.reserve(memoryToReserve: memoryZeroBytes))
    }

    func testReserveMethodDoesThrowIfReservesMemoryLessThanQuota() {
        // Given
        let epsilon: Byte = 1
        let memoryToReserveLessThanQuota = initialMemoryQuota - epsilon

        // When // Then
        XCTAssertNoThrow(try recordingQuota.reserve(memoryToReserve: memoryToReserveLessThanQuota))
    }

    func testReserveMethodAllowsToReserveMemorySeveralTimesWhileMemoryQuotaIsNotExceeded() {
        // Given
        let memoryToReserveAtOneTime = 1 * .kByte
        let expectedNumberOfTimesWeCanReserveMemory = initialMemoryQuota / memoryToReserveAtOneTime

        // When
        for _ in 1...expectedNumberOfTimesWeCanReserveMemory {
            // Then
            XCTAssertNoThrow(try recordingQuota.reserve(memoryToReserve: memoryToReserveAtOneTime))
        }
    }

    func testReserveMethodThrowsAfterSeveralReservationsButOnlyIfMemoryQuotaExceeded() {
        // Given
        let memoryToReserveAtOneTime = 1 * .kByte
        let expectedNumberOfTimesWeCanReserveMemory = initialMemoryQuota / memoryToReserveAtOneTime

        for _ in 1...expectedNumberOfTimesWeCanReserveMemory {
            XCTAssertNoThrow(try recordingQuota.reserve(memoryToReserve: memoryToReserveAtOneTime))
        }

        // When // Then
        XCTAssertThrowsError(try recordingQuota.reserve(memoryToReserve: memoryToReserveAtOneTime))
    }

    func testReserveMethodThrowsIfReservesMemoryMoreThanQuota() {
        // Given
        let epsilon: Byte = 1
        let memoryToReserveExceedingQuota = initialMemoryQuota + epsilon

        // When // Then
        XCTAssertThrowsError(try recordingQuota.reserve(memoryToReserve: memoryToReserveExceedingQuota))
    }

    func testReserveMethodDoesNotThrowIfCurrentQuotaWasReset() {
        // Given
        let epsilon: Byte = 1
        let memoryToReserveMoreThanHalfAQuota = (initialMemoryQuota / 2) + epsilon
        XCTAssertNoThrow(try recordingQuota.reserve(memoryToReserve: memoryToReserveMoreThanHalfAQuota))

        // When
        Thread.sleep(forTimeInterval: refreshInterval)

        // Then
        XCTAssertNoThrow(try recordingQuota.reserve(memoryToReserve: memoryToReserveMoreThanHalfAQuota))
    }

    func testCurrentQuotaFullyResetsWhenRefreshIntervalIsTimedOut() {
        // Given
        let memoryToReserveEqualsToQuota = initialMemoryQuota!
        XCTAssertNoThrow(try recordingQuota.reserve(memoryToReserve: memoryToReserveEqualsToQuota))

        // When
        Thread.sleep(forTimeInterval: refreshInterval)

        // Then
        XCTAssertNoThrow(try recordingQuota.reserve(memoryToReserve: memoryToReserveEqualsToQuota))
    }

    // MARK: - Private functions

    func resetUserDefaultsState() {
        UserDefaults.standard.removeObject(forKey: RecordingQuota.Keys.lastResetTimeKey)
        UserDefaults.standard.removeObject(forKey: RecordingQuota.Keys.recordingMemoryQuotaKey)
    }
}
