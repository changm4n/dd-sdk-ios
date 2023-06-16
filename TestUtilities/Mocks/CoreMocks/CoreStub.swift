/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation
import DatadogInternal

/// The most basic implementation of core.
/// It only does what you tell it to do and **nothing else**.
///
/// It can be used to both:
/// - spy on no-return methods called on `DatadogCoreProtocol`
/// - mock return values for other methods
public class CoreStub: DatadogCoreProtocol {
    public init() {}

    // MARK: - Spy

    /// Spied calls to `register(feature:T)`
    public internal(set) var registeredFeatures: [DatadogFeature] = []

    /// Spied calls to `set(feature:attributes:)`
    public internal(set) var featureAttributesSet: [String: FeatureBaggage] = [:]

    /// Spied calls to `send(message:else:)`
    public internal(set) var messagesSent: [FeatureMessage] = []

    public func register<T>(feature: T) throws where T : DatadogFeature {
        registeredFeatures.append(feature)
    }

    public func set(feature: String, attributes: @escaping () -> FeatureBaggage) {
        featureAttributesSet[feature] = attributes()
    }

    public func send(message: FeatureMessage, else fallback: @escaping () -> Void) {
        messagesSent.append(message)
    }

    // MARK: - Stub

    /// Mocked return values for `get(feature:) -> T?`
    public internal(set) var returnGetFeature: ((Any.Type) -> Any?)? = nil

    /// Mocked return values for `scope(for:) -> FeatureScope?`
    public internal(set) var returnScopeForFeature: ((String) -> FeatureScope?)? = nil

    public func get<T>(feature type: T.Type) -> T? where T : DatadogFeature {
        return returnGetFeature?(type) as? T
    }

    public func scope(for feature: String) -> FeatureScope? {
        return returnScopeForFeature?(feature)
    }
}
