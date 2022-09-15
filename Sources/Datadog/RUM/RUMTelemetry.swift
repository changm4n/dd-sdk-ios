/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

/// Sends Telemetry events to RUM.
///
/// `RUMTelemetry` complies to `Telemetry` protocol allowing sending telemetry
/// events accross features.
///
/// Events are reported up to 100 per sessions with a sampling mechanism that is
/// configured at initialisation. Duplicates are discared.
internal final class RUMTelemetry: Telemetry {
    /// Maximium number of telemetry events allowed per user sessions.
    static let MaxEventsPerSessions: Int = 100

    let core: DatadogCoreProtocol
    let dateProvider: DateProvider
    let sampler: Sampler

    /// Keeps track of current session
    private var currentSessionID: String?

    /// Keeps track of event's ids recorded during a user session.
    private var eventIDs: Set<String> = []

    /// Queue for processing RUM Telemetry
    private let queue = DispatchQueue(
        label: "com.datadoghq.rum-telemetry",
        target: .global(qos: .utility)
    )

    /// Creates a RUM Telemetry instance.
    ///
    /// - Parameters:
    ///   - core: Datadog core instance.
    ///   - dateProvider: Current device time provider.
    ///   - sampler: Telemetry events sampler.
    init(
        in core: DatadogCoreProtocol,
        dateProvider: DateProvider,
        sampler: Sampler
    ) {
        self.core = core
        self.dateProvider = dateProvider
        self.sampler = sampler
    }

    /// Sends a `TelemetryDebugEvent` event.
    /// see. https://github.com/DataDog/rum-events-format/blob/master/schemas/telemetry/debug-schema.json
    ///
    /// The current RUM context info is applied if available, including session ID, view ID,
    /// and action ID.
    ///
    /// - Parameters:
    ///   - id: Identity of the debug log, this can be used to prevent duplicates.
    ///   - message: The debug message.
    func debug(id: String, message: String) {
        let date = dateProvider.now

        record(event: id) { context, writer in
            let attributes = context.featuresAttributes["rum"]

            let applicationId = attributes?["application_id", type: String.self]
            let sessionId = attributes?["session_id", type: String.self]
            let viewId = attributes?["view.id", type: String.self]
            let actionId = attributes?["user_action.id", type: String.self]

            let event = TelemetryDebugEvent(
                dd: .init(),
                action: actionId.map { .init(id: $0) },
                application: applicationId.map { .init(id: $0) },
                date: date.addingTimeInterval(context.serverTimeOffset).timeIntervalSince1970.toInt64Milliseconds,
                experimentalFeatures: nil,
                service: "dd-sdk-ios",
                session: sessionId.map { .init(id: $0) },
                source: .init(rawValue: context.source) ?? .ios,
                telemetry: .init(message: message),
                version: context.sdkVersion,
                view: viewId.map { .init(id: $0) }
            )

            writer.write(value: event)
        }
    }

    /// Sends a `TelemetryErrorEvent` event.
    /// see. https://github.com/DataDog/rum-events-format/blob/master/schemas/telemetry/error-schema.json
    ///
    /// The current RUM context info is applied if available, including session ID, view ID,
    /// and action ID.
    ///
    /// - Parameters:
    ///   - id: Identity of the debug log, this can be used to prevent duplicates.
    ///   - message: Body of the log
    ///   - kind: The error type or kind (or code in some cases).
    ///   - stack: The stack trace or the complementary information about the error.
    func error(id: String, message: String, kind: String?, stack: String?) {
        let date = dateProvider.now

        record(event: id) { context, writer in
            let attributes = context.featuresAttributes["rum"]

            let applicationId = attributes?["application_id", type: String.self]
            let sessionId = attributes?["session_id", type: String.self]
            let viewId = attributes?["view.id", type: String.self]
            let actionId = attributes?["user_action.id", type: String.self]

            let event = TelemetryErrorEvent(
                dd: .init(),
                action: actionId.map { .init(id: $0) },
                application: applicationId.map { .init(id: $0) },
                date: date.addingTimeInterval(context.serverTimeOffset).timeIntervalSince1970.toInt64Milliseconds,
                experimentalFeatures: nil,
                service: "dd-sdk-ios",
                session: sessionId.map { .init(id: $0) },
                source: .init(rawValue: context.source) ?? .ios,
                telemetry: .init(error: .init(kind: kind, stack: stack), message: message),
                version: context.sdkVersion,
                view: viewId.map { .init(id: $0) }
            )

            writer.write(value: event)
        }
    }

    private func record(event id: String, operation: @escaping (DatadogContext, Writer) -> Void) {
        guard
            let rum = core.v1.scope(for: RUMFeature.self),
            sampler.sample()
        else {
            return
        }

        rum.eventWriteContext { context, writer in
            // reset recorded events on session renewal
            let attributes = context.featuresAttributes["rum"]
            let sessionId = attributes?["session_id", type: String.self]

            self.queue.async {
                if sessionId != self.currentSessionID {
                    self.currentSessionID = sessionId
                    self.eventIDs = []
                }

                // record up de `MaxEventsPerSessions`, discard duplicates
                if self.eventIDs.count < RUMTelemetry.MaxEventsPerSessions, !self.eventIDs.contains(id) {
                    self.eventIDs.insert(id)
                    operation(context, writer)
                }
            }
        }
    }
}
