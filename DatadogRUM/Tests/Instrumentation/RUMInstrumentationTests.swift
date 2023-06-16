/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import XCTest
import TestUtilities
@testable import DatadogInternal
@testable import DatadogRUM

class RUMInstrumentationTests: XCTestCase {
    func testWhenOnlyUIKitViewsPredicateIsConfigured_itInstrumentsUIViewController() throws {
        // When
        let instrumentation = RUMInstrumentation(
            configuration: .init(
                uiKitRUMViewsPredicate: UIKitRUMViewsPredicateMock(),
                uiKitRUMUserActionsPredicate: nil,
                longTaskThreshold: nil
            ),
            dateProvider: SystemDateProvider()
        )

        // Then
        withExtendedLifetime(instrumentation) {
            DDAssertActiveSwizzlings([
                "UIViewController.viewDidAppear:",
                "UIViewController.viewDidDisappear:",
            ])
            XCTAssertNil(instrumentation.longTasks)
        }
    }

    func testWhenOnlyUIKitActionsPredicateIsConfigured_itInstrumentsUIApplication() throws {
        // When
        let instrumentation = RUMInstrumentation(
            configuration: .init(
                uiKitRUMViewsPredicate: nil,
                uiKitRUMUserActionsPredicate: UIKitRUMUserActionsPredicateMock(),
                longTaskThreshold: nil
            ),
            dateProvider: SystemDateProvider()
        )

        // Then
        withExtendedLifetime(instrumentation) {
            DDAssertActiveSwizzlings(["UIApplication.sendEvent:"])
            XCTAssertNil(instrumentation.longTasks)
        }
    }

    func testWhenOnlyLongTasksThresholdIsConfigured_itInstrumentsRunLoop() throws {
        // When
        let instrumentation = RUMInstrumentation(
            configuration: .init(
                uiKitRUMViewsPredicate: nil,
                uiKitRUMUserActionsPredicate: nil,
                longTaskThreshold: 0.5
            ),
            dateProvider: SystemDateProvider()
        )

        // Then
        try withExtendedLifetime(instrumentation) {
            DDAssertActiveSwizzlings([])
            let beginRunLoopObserver = try XCTUnwrap(instrumentation.longTasks?.observer_begin)
            let endRunLoopObserver = try XCTUnwrap(instrumentation.longTasks?.observer_end)
            XCTAssertTrue(CFRunLoopContainsObserver(RunLoop.main.getCFRunLoop(), beginRunLoopObserver, .commonModes))
            XCTAssertTrue(CFRunLoopContainsObserver(RunLoop.main.getCFRunLoop(), endRunLoopObserver, .commonModes))
        }
    }

    func testGivenAllInstrumentationsConfigured_whenSubscribed_itSetsSubsciberInRespectiveHandlers() throws {
        // Given
        let instrumentation = RUMInstrumentation(
            configuration: .init(
                uiKitRUMViewsPredicate: UIKitRUMViewsPredicateMock(),
                uiKitRUMUserActionsPredicate: UIKitRUMUserActionsPredicateMock(),
                longTaskThreshold: 0.5
            ),
            dateProvider: SystemDateProvider()
        )
        let subscriber = RUMCommandSubscriberMock()

        // When
        instrumentation.publish(to: subscriber)

        // Then
        withExtendedLifetime(instrumentation) {
            XCTAssertIdentical(instrumentation.viewsHandler.subscriber, subscriber)
            XCTAssertIdentical((instrumentation.actionsHandler as? UIKitRUMUserActionsHandler)?.subscriber, subscriber)
            XCTAssertIdentical(instrumentation.longTasks?.subscriber, subscriber)
        }
    }
}

internal func DDAssertActiveSwizzlings(_ expectedSwizzledSelectors: [String], file: StaticString = #filePath, line: UInt = #line) {
    _DDEvaluateAssertion(message: "Only \(expectedSwizzledSelectors) swizzlings should be active", file: file, line: line) {
        let actual = activeSwizzlingNames.sorted()
        let expected = expectedSwizzledSelectors.sorted()

        guard actual == expected else {
            throw DDAssertError.expectedFailure("actual swizzlings: \(actual) don't match expected ones: \(expected)")
        }
    }
}
