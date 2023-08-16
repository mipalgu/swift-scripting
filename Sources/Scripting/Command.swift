//
//  Command.swift
//  
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 21/1/2023.
//
import Foundation

/// An executable script command.
///
/// This command references an executable
/// command and its execution state.
///
/// The execution state either represents
/// a reference to the executable itself or
/// an error state.  Any operation performed
/// on an error state will do nothing, but
/// preserve the error state.
///
/// - Note: Executables usually have reference
/// semantics, so copying a Command will
/// **not** give you a new executable value,
/// just a reference to an existing executable.
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

    /// Initialise a Shell command from a file.
    ///
    /// - Parameters:
    ///   - file: The file represented by the receiver.
    @inlinable
    init(file: String) {
        let fileIO = FileIO(file)
        self = .executable(fileIO)
    }

    /// Synchronously perform an action.
    ///
    /// This method will perform the provided action
    /// only if the command is not in an error state.
    /// If the command in in an error state, it will simply
    /// pass through the error.
    ///
    /// - Parameter action: The action to perform.
    @inlinable
    func perform(_ action: (Executable) throws -> Void) -> Self {
        guard case let .executable(command) = self else { return self }
        do {
            try action(command)
        } catch {
            return .error(error)
        }
        return self
    }

    /// Synchronously perform an action.
    ///
    /// This method will perform the provided action
    /// only if the command is not in an error state.
    /// If the command in in an error state, it will simply
    /// pass through the error.
    ///
    /// - Parameter action: The action to perform.
    @inlinable
    func perform(_ action: (Executable) throws -> Self) -> Self {
        guard case let .executable(command) = self else { return self }
        do {
            return try action(command)
        } catch {
            return .error(error)
        }
    }

    /// Asynchronously perform an action.
    ///
    /// This method will perform the provided action
    /// only if the command is not in an error state.
    /// If the command in in an error state, it will simply
    /// pass through the error.
    ///
    /// - Parameter action: The action to perform.
    @inlinable
    func perform(_ action: (Executable) async throws -> Void) async -> Self {
        guard case let .executable(command) = self else { return self }
        do {
            try await action(command)
        } catch {
            return .error(error)
        }
        return self
    }

    /// Asynchronously perform an action.
    ///
    /// This method will perform the provided action
    /// only if the command is not in an error state.
    /// If the command in in an error state, it will simply
    /// pass through the error.
    ///
    /// - Parameter action: The action to perform.
    @inlinable
    func perform(_ action: (Executable) async throws -> Self) async -> Self {
        guard case let .executable(command) = self else { return self }
        do {
            return try await action(command)
        } catch {
            return .error(error)
        }
    }
}

/// Convenience extension.
extension Command: ExpressibleByStringLiteral {
    /// Initialise a command from a string.
    /// - Parameter value: The command to parse and its arguments.
    @inlinable
    public init(stringLiteral value: String) {
        let arguments = parse(command: value)
        self.init(arguments[0], arguments: Array(arguments[1...]))
    }

}

/// Executable conformance
extension Command: Executable {
    /// The standard input file handle of the command.
    @inlinable public var standardInput: IOHandle? {
        get {
            guard case let .executable(executable) = self else { return nil }
            return executable.standardInput
        }
        set {
            guard case var .executable(executable) = self else { return }
            executable.standardInput = newValue
            self = .executable(executable)
        }
    }

    /// The standard output file handle of the command.
    @inlinable public var standardOutput: IOHandle? {
        get {
            guard case let .executable(executable) = self else { return nil }
            return executable.standardOutput
        }
        set {
            guard case var .executable(executable) = self else { return }
            executable.standardOutput = newValue
            self = .executable(executable)
        }
    }

    /// The standard error file handle of the command.
    @inlinable public var standardError: IOHandle? {
        get {
            guard case let .executable(executable) = self else { return nil }
            return executable.standardError
        }
        set {
            guard case var .executable(executable) = self else { return }
            executable.standardError = newValue
            self = .executable(executable)
        }
    }

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

    /// Terminate the running executable.
    ///
    /// This function will try its best to terminate
    /// the underlying executable.  There is no
    /// guarantee that this will be successful.
    @inlinable
    public func terminate() {
        guard case let .executable(command) = self else { return }
        if let shellCommand = command as? ShellCommand {
            shellCommand.terminate()
        }
    }

    /// Terminate the running executable via Interrupt.
    ///
    /// This function will trigger an interrupt with a
    /// default behaviour of terminating the process.
    /// This was implemented as a fail safe incase the
    /// process fails to terminate through conventional
    /// means.
    @inlinable
    public func interrupt() -> Bool {
        guard case let .executable(command) = self else { return false }
        guard let shellCommand = command as? ShellCommand else { return false }
        return shellCommand.interrupt()
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
