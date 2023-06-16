/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import UIKit
import Foundation
import DatadogInternal

/// A class enabling Datadog RUM features.
///
/// `RUMMonitor` allows recording user events that can be explored and analyzed in Datadog Dashboards.
/// There can be only one active `RUMMonitor`, and it should be registered/retrieved through `Global.rum`:
///
///     import Datadog
///
///     // register
///     Global.rum = RUMMonitor.initialize()
///
///     // use
///     Global.rum.startView(...)
///
public class RUMMonitor {
    // TODO: RUMM-2922 Public API comment
    public static func shared(in core: DatadogCoreProtocol = CoreRegistry.default) -> RUMMonitorProtocol {
        do {
            guard !(core is NOPDatadogCore) else {
                throw ProgrammerError(
                    description: "Datadog SDK must be initialized and RUM feature must be enabled before calling `RUMMonitor.shared(in:)`."
                )
            }
            guard let feature = core.get(feature: DatadogRUMFeature.self) else {
                throw ProgrammerError(
                    description: "RUM feature must be enabled before calling `RUMMonitor.shared(in:)`."
                )
            }

            return feature.monitor
        } catch {
            consolePrint("\(error)")
            return NOPRUMMonitor()
        }
    }
}
