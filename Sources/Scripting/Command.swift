//
//  Executable.swift
//  
//
//  Created by Rene Hexel on 21/1/2023.
//
import Foundation

/// An executable script command.
///
/// This command represents a
/// command and its execution state.
public enum Command {
    /// The shell command underlying this command.
    case executable(Executable)
    /// The error status of the command.
    case error(Error)
}

/// Convenience constructors and methods.
public extension Command {
    /// Initialise a Shell command from a string.
    ///
    /// - Parameters:
    ///   - command: The command represented by the receiver.
    ///   - environment: The environment to pass to the proces, if any.
    ///   - arguments: The arguments to pass to the process.
    @inlinable
    init(_ command: String, environment: [String : String]? = nil, arguments: [String] = []) {
        let shellCommand = ShellCommand(command, environment: environment, arguments: arguments)
        self = .executable(shellCommand)
    }
}

/// Convenience extension.
extension Command: ExpressibleByStringLiteral {
    /// Initialise a command from a string.
    /// - Parameter value: The command to parse and its arguments.
    @inlinable
    public init(stringLiteral value: String) {
        self.init(value)
    }

}

/// Executable conformance
extension Command: Executable {
    /// Launch the underlying command.
    ///
    /// This method will start the command,
    /// but may not wait for its execution to
    /// complete.
    @inlinable
    public func launch() throws {
        switch self {
        case let .error(error):
            throw error
        case let .executable(executable):
            try executable.launch()
        }
    }
    /// Run the underlying command to completion.
    ///
    /// This method will start the command asynchronously
    /// and can be awaited to complete
    ///
    /// - Returns: The completion status.
    @discardableResult @inlinable
    public func run() async throws -> Status {
        switch self {
        case let .error(error):
            throw error
        case let .executable(executable):
            return try await executable.run()
        }
    }
    /// Register an input handler.
    ///
    /// The input handler is asynchronous
    /// and provides data whenever available.
    /// The handler needs to be called repeatedly,
    /// until it returns `nil`.
    ///
    /// - Note: multiple input handlers can be chained
    ///         by calling this method repeatedly.
    ///
    /// - Parameter inputHandler: The input handler to run.
    @inlinable
    public func onInput(_ inputHandler: @escaping () async throws -> Data?) {
        if case let .executable(executable) = self {
            executable.onInput(inputHandler)
        }
    }
    /// Register an output handler.
    ///
    /// The output handler takes data
    /// and gets called whenever the
    /// standard output channel has data
    /// available.
    ///
    /// - Note: multiple output handlers can be chained
    ///         by calling this method repeatedly.
    ///
    /// - Parameter outputHandler: The output handler to run.
    @inlinable
    public func onOutput(call outputHandler: @escaping (Data) async -> Void) {
        if case let .executable(executable) = self {
            executable.onOutput(call: outputHandler)
        }
    }
    /// Register an error handler.
    ///
    /// The output handler takes data
    /// and gets called whenever the
    /// standard error channel has data
    /// available.
    ///
    /// - Note: multiple error handlers can be chained
    ///         by calling this method repeatedly.
    ///
    /// - Parameter errorHandler: The error handler to run.
    @inlinable
    public func onError(call errorHandler: @escaping (Data) async -> Void) {
        if case let .executable(executable) = self {
            executable.onError(call: errorHandler)
        }
    }
}
