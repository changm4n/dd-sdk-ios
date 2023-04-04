/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import UIKit

/// The context of recording subtree hierarchy.
///
/// Some fields are mutable, so `NodeRecorders` can specialise it for their subtree traversal.
internal struct ViewTreeRecordingContext {
    /// The context of the Recorder.
    let recorder: Recorder.Context
    /// The coordinate space to convert node positions to.
    let coordinateSpace: UICoordinateSpace
    /// Generates stable IDs for traversed views.
    let ids: NodeIDGenerator
    /// Text obfuscator applied to all non-sensitive texts. No-op if privacy mode is disabled.
    /// Can be overwriten in by `NodeRecorder` if their subtree recording requires different masking.
    var textObfuscator: TextObfuscating
    /// Text obfuscator applied to user selection texts (such as labels in picker control).
    var selectionTextObfuscator: TextObfuscating
    /// Text obfuscator applied to all sensitive texts (such as passwords or e-mail address).
    let sensitiveTextObfuscator: TextObfuscating
    /// Provides base64 image data with a built in caching mechanism.
    let imageDataProvider: ImageDataProviding
}

internal struct ViewTreeRecorder {
    /// An array of enabled node recorders.
    ///
    /// The order in this this array  should be managed consciously. For each node, the implementation loops
    /// through `nodeRecorders` and stops on the one that recorded node semantics with highes importance.
    let nodeRecorders: [NodeRecorder]

    /// Creates `Nodes` for given view and its subtree hierarchy.
    func recordNodes(for anyView: UIView, in context: ViewTreeRecordingContext) -> [Node] {
        var nodes: [Node] = []
        recordRecursively(nodes: &nodes, view: anyView, context: context)
        return nodes
    }

    // MARK: - Private

    private func recordRecursively(nodes: inout [Node], view: UIView, context: ViewTreeRecordingContext) {
        let semantics = nodeSemantics(for: view, in: context)

        if !semantics.nodes.isEmpty {
            nodes.append(contentsOf: semantics.nodes)
        }

        switch semantics.subtreeStrategy {
        case .record:
            for subview in view.subviews {
                recordRecursively(nodes: &nodes, view: subview, context: context)
            }
        case .ignore:
            break
        }
    }

    private func nodeSemantics(for view: UIView, in context: ViewTreeRecordingContext) -> NodeSemantics {
        let attributes = ViewAttributes(
            frameInRootView: view.convert(view.bounds, to: context.coordinateSpace),
            view: view
        )

        var semantics: NodeSemantics = UnknownElement.constant

        for nodeRecorder in nodeRecorders {
            guard let nextSemantics = nodeRecorder.semantics(of: view, with: attributes, in: context) else {
                continue
            }

            if nextSemantics.importance >= semantics.importance {
                semantics = nextSemantics

                if nextSemantics.importance == .max {
                    // We know the current semantics is best we can get, so skip querying other `nodeRecorders`:
                    break
                }
            }
        }

        return semantics
    }
}
