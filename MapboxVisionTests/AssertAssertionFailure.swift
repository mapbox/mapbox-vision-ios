@testable import MapboxVision
import XCTest

func AssertFailure<T>(_ testcase: @autoclosure () -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    var assertionFailureOccured = false

    AssertFailureUtil.replaceAssertFailure { _, _, _ in
        assertionFailureOccured = true
    }

    _ = testcase()

    XCTAssertTrue(assertionFailureOccured, message, file: file, line: line)

    AssertFailureUtil.restoreAssertFailure()
}

func AssertNoFailure<T>(_ testcase: @autoclosure () -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    var assertionFailureOccured = false

    AssertFailureUtil.replaceAssertFailure { _, _, _ in
        assertionFailureOccured = true
    }

    _ = testcase()

    XCTAssertFalse(assertionFailureOccured, message, file: file, line: line)

    AssertFailureUtil.restoreAssertFailure()
}
