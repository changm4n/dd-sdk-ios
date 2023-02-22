/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import XCTest
@testable import TestUtilities
@testable import DatadogSessionReplay

class UISliderRecorderTests: XCTestCase {
    private let recorder = UISliderRecorder()
    private let slider = UISlider()
    private var viewAttributes: ViewAttributes = .mockAny()

    func testWhenSliderIsNotVisible() throws {
        // When
        viewAttributes = .mock(fixture: .invisible)

        // Then
        let semantics = try XCTUnwrap(recorder.semantics(of: slider, with: viewAttributes, in: .mockAny()))
        XCTAssertTrue(semantics is InvisibleElement)
        XCTAssertNil(semantics.wireframesBuilder)
    }

    func testWhenSliderIsVisible() throws {
        // Given
        slider.thumbTintColor = .mockRandom()
        slider.minimumTrackTintColor = .mockRandom()
        slider.maximumTrackTintColor = .mockRandom()
        slider.isEnabled = .mockRandom()

        // When
        viewAttributes = .mock(fixture: .visible())

        // Then
        let semantics = try XCTUnwrap(recorder.semantics(of: slider, with: viewAttributes, in: .mockAny()) as? SpecificElement)
        XCTAssertFalse(semantics.recordSubtree, "Slider's subtree should not be recorded")

        let builder = try XCTUnwrap(semantics.wireframesBuilder as? UISliderWireframesBuilder)
        XCTAssertEqual(builder.attributes, viewAttributes)
        XCTAssertEqual(builder.isEnabled, slider.isEnabled)
        XCTAssertEqual(builder.thumbTintColor, slider.thumbTintColor?.cgColor)
        XCTAssertEqual(builder.minTrackTintColor, slider.minimumTrackTintColor?.cgColor)
        XCTAssertEqual(builder.maxTrackTintColor, slider.maximumTrackTintColor?.cgColor)
    }

    func testWhenViewIsNotOfExpectedType() {
        // When
        let view = UITextField()

        // Then
        XCTAssertNil(recorder.semantics(of: view, with: viewAttributes, in: .mockAny()))
    }
}