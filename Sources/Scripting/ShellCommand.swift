//
//  ShellCommand.swift
//  
//  Copyright © 2022, 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import Foundation
import SystemPackage

/// An executable shell command.
public final class ShellCommand {
    /// The full file path of the command.
    public var path: FilePath
    /// The arguments to pass.
    public var arguments: [String]
    /// The environment variables to pass to the process.
    ///
    /// If the environment is `nil`, the process will inherit
    /// the environment from its parent.
    public var environment: [String : String]?
    /// The termination status of the process.
    public var terminationStatus: Status = 0
    /// The termination reason for the process.
    public var terminationReason = Process.TerminationReason.exit
    /// The current status of the process.
    public var isRunning = false
    /// The underlying process to run.
    @usableFromInline
    var process = Process()

    /// Initialise the shell command from a file path.
    ///
    /// This initialiser takes a verbatim file path and
    /// creates an executable shell command from
    /// that path.  The file designated by that path
    /// needs to exist and be a valid executable.
    ///
    /// - Parameters:
    ///   - path: The file path to the executable.
    ///   - environment: The environment to pass to the proces, if any.
    ///   - arguments: The arguments to pass to the process.
    @inlinable
    public init(path: FilePath, environment: [String : String]? = nil, arguments: [String] = []) {
        self.path = path
        self.arguments = arguments
        self.environment = environment
    }

    /// Run a shell command.
    @discardableResult @inlinable
    public func run() -> Result<Status, Error> {
        Result(catching: run)
    }


    /// Run a shell command.
    @discardableResult @inlinable
    public func run() throws -> Status {
        Task { try await run() }
        return terminationStatus
    }

    /// Asynchronously run a shell command.
    @discardableResult @inlinable
    public func run() async throws -> Status {
        try setupProcess()
        let process = self.process
        terminationStatus = try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                continuation.resume(returning: process.terminationStatus)
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        terminationReason = process.terminationReason
        return terminationStatus
    }

    /// Launch the process associated with the shell command.
    @inlinable
    public func launch() throws {
        guard !isRunning else { throw Errno.alreadyInProgress }
        isRunning = true
        do {
            try process.run()
        } catch {
            isRunning = false
            throw error
        }
    }

    /// Set up the process for the shell.
    public func setupProcess() throws {
        guard !isRunning else { throw Errno.alreadyInProgress }
        process = Process()
        if let environment = environment {
            process.environment = environment
        }
        let launchPath = path.string
        process.executableURL = URL(fileURLWithPath: launchPath, isDirectory: false)
        process.arguments = arguments
        process.terminationHandler = { [weak self] process in
            DispatchQueue.main.async { [weak self] in
                process.waitUntilExit()
                self?.terminationStatus = process.terminationStatus
                self?.isRunning = false
                try? self?.setupProcess()
            }
        }
    }
}

/// Convenience constructors and methods
public extension ShellCommand {
    /// String initialiser.
    ///
    /// This initialiser attempts to find the full path
    /// of the given command.
    ///
    /// - Parameters:
    ///   - command: The command represented by the receiver.
    ///   - environment: The environment to pass to the proces, if any.
    ///   - arguments: The arguments to pass to the process.
    @inlinable
    convenience init(_ command: String, environment: [String : String]? = nil, arguments: [String] = []) {
        let searchPath = environment?["PATH"] ?? ProcessInfo.processInfo.environment["PATH"] ?? ""
        let searchResult = search(for: command, in: searchPath)
        let fullCommand: String
#if os(Linux)
        fullCommand = searchResult?.path ?? command
#else
        if #available(macOS 13.0, *) {
            fullCommand = searchResult?.path(percentEncoded: false) ?? command
        } else {
            fullCommand = searchResult?.path ?? command
        }
#endif
        let fullPath = FilePath(fullCommand)
        self.init(path: fullPath, environment: environment, arguments: arguments)
    }
}

/// Convenience Operators
public extension ShellCommand {
    /// Run the given shell command and redirect its output
    /// to the string.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputString: The string that should be filled with the output of the command.
    @discardableResult @inlinable
    static func > (_ command: ShellCommand, _ outputString: inout String) -> Result<Status, Error> {
        command.run()
    }
}
