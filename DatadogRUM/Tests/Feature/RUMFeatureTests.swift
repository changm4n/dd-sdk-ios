/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import XCTest
import TestUtilities
@testable import DatadogRUM
@testable import DatadogInternal

class RUMFeatureTests: XCTestCase {
    private var core: SingleFeatureCoreMock<RUMFeature>! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUpWithError() throws {
        core = SingleFeatureCoreMock()
    }

    override func tearDown() {
        core = nil
    }

    func testWhenNotRegisteredToCore_thenRUMMonitorIsNotAvailable() {
        // When
        XCTAssertNil(core.get(feature: RUMFeature.self))

        // Then
        XCTAssertTrue(RUMMonitor.shared(in: core) is NOPRUMMonitor)
    }

    func testWhenRegisteredToCore_thenRUMMonitorIsAvailable() throws {
        // Given
        let rum = try RUMFeature(in: core, configuration: .mockAny())

        // When
        try core.register(feature: rum)

        // Then
        XCTAssertTrue(RUMMonitor.shared(in: core) is Monitor)
    }

    func testWhenInstrumentationIsEnabled_itSubscribesRUMMonitorToInstrumentationHandlers() throws {
        // Given
        let rum = try RUMFeature(
            in: core,
            configuration: .mockWith(
                instrumentation: .init(
                    uiKitRUMViewsPredicate: UIKitRUMViewsPredicateMock(),
                    uiKitRUMUserActionsPredicate: UIKitRUMUserActionsPredicateMock(),
                    longTaskThreshold: 0.5
                )
            )
        )

        // When
        try core.register(feature: rum)
        XCTAssertTrue(RUMMonitor.shared(in: core) is Monitor)

        // Then
        let viewsSubscriber = rum.instrumentation.viewsHandler.subscriber
        let actionsSubscriber = (rum.instrumentation.actionsHandler as? UIKitRUMUserActionsHandler)?.subscriber
        let longTasksSubscriber = rum.instrumentation.longTasks?.subscriber
        XCTAssertIdentical(viewsSubscriber, RUMMonitor.shared(in: core) as? RUMCommandSubscriber)
        XCTAssertIdentical(actionsSubscriber, RUMMonitor.shared(in: core) as? RUMCommandSubscriber)
        XCTAssertIdentical(longTasksSubscriber, RUMMonitor.shared(in: core) as? RUMCommandSubscriber)
    }

    func testWhenInstrumentationIsNotEnabled_itSubscribesRUMMonitorToViewsHandlers() throws {
        // Given
        let rum = try RUMFeature(
            in: core,
            configuration: .mockWith(
                instrumentation: .init(
                    uiKitRUMViewsPredicate: nil,
                    uiKitRUMUserActionsPredicate: nil,
                    longTaskThreshold: nil
                )
            )
        )

        // When
        try core.register(feature: rum)
        XCTAssertTrue(RUMMonitor.shared(in: core) is Monitor)

        // Then
        let viewsSubscriber = rum.instrumentation.viewsHandler.subscriber
        XCTAssertIdentical(
            viewsSubscriber,
            RUMMonitor.shared(in: core) as? RUMCommandSubscriber,
            "It must always subscribe `RUMMonitor` to `RUMViewsHandler` as it is required for manual SwiftUI instrumentation"
        )
        XCTAssertNil(rum.instrumentation.actionsHandler)
        XCTAssertNil(rum.instrumentation.longTasks)
    }

    func testWhenFirstPartyHostsAreSet_itEnablesNetworkInstrumentationFeature() throws {
        let core = CoreStub()

        // When
        let rum = try RUMFeature(
            in: core,
            configuration: .mockWith(
                firstPartyHosts: .init(["foo.com": [.datadog]])
            )
        )

        // Then
        let networkInstrumentation = try XCTUnwrap(
            core.registeredFeatures.first(where: { $0 is NetworkInstrumentationFeature }) as? NetworkInstrumentationFeature,
            "It should enable `NetworkInstrumentationFeature`"
        )
        let rumResourcesHandler = try XCTUnwrap(
            networkInstrumentation.handlers.first(where: { $0 is URLSessionRUMResourcesHandler }) as? URLSessionRUMResourcesHandler,
            "It should register `URLSessionRUMResourcesHandler` to `NetworkInstrumentationFeature`"
        )
        XCTAssertIdentical(
            rumResourcesHandler.subscriber,
            rum.monitor,
            "It must subscribe `RUMMonitor` to `URLSessionRUMResourcesHandler`"
        )
    }

    func testWhenFirstPartyHostsAreNotSet() throws {
        let core = CoreStub()

        // When
        _ = try RUMFeature(
            in: core,
            configuration: .mockWith(
                firstPartyHosts: nil
            )
        )

        // Then
        XCTAssertFalse(core.registeredFeatures.contains(where: { $0 is NetworkInstrumentationFeature }))
    }

    func testWhenCustomIntakeURLIsSet_itConfiguresRequestBuilder() throws {
        let randomURL: URL = .mockRandom()

        // When
        let rum = try RUMFeature(
            in: core,
            configuration: .mockWith(
                customIntakeURL: randomURL
            )
        )

        // Then
        XCTAssertEqual((rum.requestBuilder as? RequestBuilder)?.customIntakeURL, randomURL)
    }

    func testWhenCustomIntakeURLIsNotSet() throws {
        // When
        let rum = try RUMFeature(
            in: core,
            configuration: .mockWith(
                customIntakeURL: nil
            )
        )

        // Then
        XCTAssertNil((rum.requestBuilder as! RequestBuilder).customIntakeURL)
    }

    func testGivenDebugRUMConfigured_whenRegistered_itEnablesDebuggingInRUMMonitor() throws {
        // TODO: RUMM-2922
    }

    func testGivenDebugRUMEnvConfigured_whenRegistered_itEnablesDebuggingInRUMMonitor() throws {
        // TODO: RUMM-2922
    }

    func testWhenRegistered_itSendsConfigurationTelemetry() throws {
        // TODO: RUMM-2922
    }

    func testItReceivesTelemetry() throws {
        // TODO: RUMM-2922
    }

    func testItReceivesErrors() throws {
        // TODO: RUMM-2922
    }

    func testItReceivesWebViewEvents() throws {
        // TODO: RUMM-2922
    }

    func testItReceivesCrashReports() throws {
        // TODO: RUMM-2922
    }
}
