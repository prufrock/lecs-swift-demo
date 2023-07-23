//
// Created by David Kanenwisher on 1/3/23.
//

import Foundation

/**
 The AppCore serves the global state for the application to avoid singletons(if possible):
 - manages the state of the application
 - provides access to services

 - Skipping the state machine for now.
 */
public class AppCore {
    private var context: AppCoreContext

    public var config: AppCoreConfig {
        get {
            context.config
        }
    }

    public init(_ config: AppCoreConfig) {
        context = AppCoreContext(config: config)
    }

    /**
     I'm hoping I can provide a sync and async facade over the commands services want to execute.
     */
    public func sync(_ command: ServiceCommand) {
        context.sync(command)
    }
}

public protocol ServiceCommand {}
