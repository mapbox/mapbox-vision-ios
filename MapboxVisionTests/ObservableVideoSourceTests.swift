@testable import MapboxVision
import XCTest

private enum Constants {
    static let numberOfConcurrentMethodCalls = 10000
    static let expectedTestTimeout = 5.0
}

class ObservableVideoSourceTests: XCTestCase {
    private var observableVideoSource: ObservableVideoSource!
    private var callsCounter: Int!

    private var testExpectation: XCTestExpectation!

    private var concurrentQueue = DispatchQueue(label: "com.mapbox.MapboxVision.ObservableVideoSourceTests.concurrentQueue",
                                                qos: .default,
                                                attributes: .concurrent)
    private var serialQueue = DispatchQueue(label: "com.mapbox.MapboxVision.ObservableVideoSourceTests.serialQueue",
                                            qos: .default)

    override func setUp() {
        super.setUp()
        self.observableVideoSource = ObservableVideoSource()
    }

    // MARK: - Tests

    func testAddMethodDoesNotThrowWhenIsCalledSerially() {
        // Given state from setUp()

        // When
        for _ in 1...Constants.numberOfConcurrentMethodCalls {
            let observer = VideoSourceObserverMock()

            // Then
            XCTAssertNoThrow(observableVideoSource.add(observer: observer))
        }
    }

    func testRemoveMethodDoesNotThrowWhenIsCalledSerially() {
        // Given state from setUp()

        let observers = [VideoSourceObserverMock].init(repeating: VideoSourceObserverMock(),
                                                       count: Constants.numberOfConcurrentMethodCalls)

        for idx in 0..<Constants.numberOfConcurrentMethodCalls {
            observableVideoSource.add(observer: observers[idx])
        }

        // When
        for idx in 0..<Constants.numberOfConcurrentMethodCalls {
            // Then
            XCTAssertNoThrow(observableVideoSource.remove(observer: observers[idx]))
        }
    }

    func testNotifyMethodDoesNotThrowWhenIsCalledSerially() {
        // Given state from setUp()

        // When
        for _ in 1...Constants.numberOfConcurrentMethodCalls {
            // Then
            XCTAssertNoThrow(observableVideoSource.notify { _ in })
        }
    }

    func testAddAndNotifyMethodsDoNotThrowWhenAreCalledInParallel() {
        // Given
        testExpectation = XCTestExpectation(description: "add(:) and notify() methods handle concurrent method calls properly.")
        callsCounter = 1

        // When
        for idx in 1...Constants.numberOfConcurrentMethodCalls {
            if idx.isMultiple(of: 2) {
                concurrentQueue.async {
                    let observer = VideoSourceObserverMock()
                    XCTAssertNoThrow(self.observableVideoSource.add(observer: observer))
                    self.incrementCallsCounter()
                }
            } else {
                concurrentQueue.async {
                    XCTAssertNoThrow(self.observableVideoSource.notify { _ in })
                    self.incrementCallsCounter()
                }
            }
        }

        // Then
        wait(for: [testExpectation], timeout: Constants.expectedTestTimeout)
    }

    func testRemoveAndNotifyMethodsWontCrashWhenAreCalledInParallel() {
        // Given
        testExpectation = XCTestExpectation(description: "remove(:) and notify() methods handle concurrent method calls properly.")
        callsCounter = 1

        let observers = [VideoSourceObserverMock].init(repeating: VideoSourceObserverMock(),
                                                       count: Constants.numberOfConcurrentMethodCalls)

        for idx in 0..<Constants.numberOfConcurrentMethodCalls {
            observableVideoSource.add(observer: observers[idx])
        }

        // When
        for idx in 0..<Constants.numberOfConcurrentMethodCalls {
            if idx.isMultiple(of: 2) {
                concurrentQueue.async {
                    XCTAssertNoThrow(self.observableVideoSource.remove(observer: observers[idx]))
                    self.incrementCallsCounter()
                }
            } else {
                concurrentQueue.async {
                    XCTAssertNoThrow(self.observableVideoSource.notify { _ in })
                    self.incrementCallsCounter()
                }
            }
        }

        // Then
        wait(for: [testExpectation], timeout: Constants.expectedTestTimeout)
    }

    // MARK: - Helper functions

    private func incrementCallsCounter() {
        serialQueue.async {
            self.callsCounter += 1
            if self.callsCounter == Constants.numberOfConcurrentMethodCalls {
                self.testExpectation.fulfill()
            }
        }
    }
}

private class VideoSourceObserverMock: VideoSourceObserver {}
