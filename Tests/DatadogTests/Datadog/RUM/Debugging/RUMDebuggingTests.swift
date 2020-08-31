/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

#if targetEnvironment(simulator)
import XCTest
import UIKit
@testable import Datadog

class RUMDebuggingTests: XCTestCase {
    func testWhenOneRUMViewIsActive_itDisplaysSingleRUMViewOutline() throws {
        let expectation = self.expectation(description: "Render RUMDebugging")

        // when
        let applicationScope = RUMApplicationScope(
            rumApplicationID: "abc-123",
            dependencies: .mockAny(),
            samplingRate: 100
        )
        _ = applicationScope.process(
            command: RUMStartViewCommand.mockWith(identity: mockView, path: "FirstViewController")
        )

        let debugging = RUMDebuggingInSimulator()
        debugging.debug(applicationScope: applicationScope)

        DispatchQueue.main.async { expectation.fulfill() }
        waitForExpectations(timeout: 1, handler: nil)

        // then
        let canvas = try XCTUnwrap(
            UIApplication.shared.keyWindow?.subviews.first { $0 is RUMDebugView },
            "Cannot find `RUMDebugging` canvas."
        )

        XCTAssertEqual(canvas.subviews.count, 1)
        let viewOutline = try XCTUnwrap(canvas.subviews.first)
        let viewOutlineLabel = try XCTUnwrap(viewOutline.subviews.first as? UILabel)
        XCTAssertEqual(viewOutlineLabel.text, "FirstViewController # ACTIVE")
    }

    func testWhenOneRUMViewIsInactive_andSecondIsActive_itDisplaysTwoRUMViewOutlines() throws {
        let expectation = self.expectation(description: "Render RUMDebugging")

        // when
        let applicationScope = RUMApplicationScope(
            rumApplicationID: "abc-123",
            dependencies: .mockAny(),
            samplingRate: 100
        )
        _ = applicationScope.process(
            command: RUMStartViewCommand.mockWith(identity: mockView, path: "FirstViewController")
        )
        _ = applicationScope.process(
            command: RUMStartResourceCommand.mockAny()
        )
        _ = applicationScope.process(
            command: RUMStartViewCommand.mockWith(identity: mockView, path: "SecondViewController")
        )

        let debugging = RUMDebuggingInSimulator()
        debugging.debug(applicationScope: applicationScope)

        DispatchQueue.main.async { expectation.fulfill() }
        waitForExpectations(timeout: 1, handler: nil)

        // then
        let canvas = try XCTUnwrap(
            UIApplication.shared.keyWindow?.subviews.first { $0 is RUMDebugView },
            "Cannot find `RUMDebugging` canvas."
        )

        XCTAssertEqual(canvas.subviews.count, 2)
        let firstViewOutline = try XCTUnwrap(canvas.subviews.first)
        let firstViewOutlineLabel = try XCTUnwrap(firstViewOutline.subviews.first as? UILabel)
        XCTAssertEqual(firstViewOutlineLabel.text, "FirstViewController # INACTIVE")
        let secondViewOutline = try XCTUnwrap(canvas.subviews.dropFirst().first)
        let secondViewOutlineLabel = try XCTUnwrap(secondViewOutline.subviews.first as? UILabel)
        XCTAssertEqual(secondViewOutlineLabel.text, "SecondViewController # ACTIVE")
        XCTAssertLessThan(firstViewOutlineLabel.alpha, secondViewOutlineLabel.alpha)
    }
}

#endif