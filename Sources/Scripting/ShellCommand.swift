//
//  ShellCommand.swift
//  
//  Copyright © 2022, 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import Foundation
import SystemPackage

/// An executable shell command.
///
/// A `ShellCommand` references an underlying Process,
/// its associated file path, ccommand line arguments,
/// environment, pipes, and I/O handlers.
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
    /// The standard input handle for the Process
    public var standardInput: IOHandle?
    /// The standard output handle for the Process
    public var standardOutput: IOHandle?
    /// The standard error handle for the Process
    public var standardError: IOHandle?
    /// The underlying process to run.
    @usableFromInline var process = Process()
    /// The standard input pipe for the Process.
    @usableFromInline var inputPipe: Pipe? {
        get { return standardInput as? Pipe }
        set { standardInput = newValue }
    }
    /// The standard input pipe for the Process.
    @usableFromInline var outputPipe: Pipe? {
        get { return standardOutput as? Pipe }
        set { standardOutput = newValue }
    }
    /// The standard error pipe for the Process.
    @usableFromInline var errorPipe: Pipe? {
        get { return standardError as? Pipe }
        set { standardError = newValue }
    }
    /// Process input handler.
    ///
    /// This handler runs in the background and is called whenever
    /// the process produces output.
    ///
    /// - Note: set to `nil` to disable output handling.
    @usableFromInline var inputHandler: (() async throws -> Data?)?
    /// Process output handler.
    ///
    /// This handler runs in the background and is called whenever
    /// the process produces output.
    ///
    /// - Note: set to `nil` to disable output handling.
    @usableFromInline var outputHandler: ((Data) async -> Void)?
    /// Process error handler.
    ///
    /// This handler runs in the background and is called whenever
    /// the process produces errors.
    ///
    /// - Note: set to `nil` to disable error handling.
    @usableFromInline var errorHandler: ((Data) async -> Void)?

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

    /// Terminate the running executable.
    ///
    /// This function will try its best to terminate
    /// the underlying executable.  There is no
    /// guarantee that this will be successful.
    @inlinable
    public func terminate() {
        guard isRunning else { return }
        process.terminate()
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
        guard isRunning else {
            print("is not running")
            fflush(stdout)
            return false
        }
        process.interrupt()
        return true
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
        process.standardInput = standardInput
        process.standardOutput = standardOutput
        if let pipe = outputPipe {
            if let outputHandler = outputHandler {
                pipe.fileHandleForReading.readabilityHandler = { fileHandle in
                    let data = fileHandle.availableData
                    Task { @MainActor in
                        await outputHandler(data)
                    }
                }
            }
        }
        process.standardError = standardError
        if let pipe = errorPipe {
            if let errorHandler = errorHandler {
                pipe.fileHandleForReading.readabilityHandler = { fileHandle in
                    let data = fileHandle.availableData
                    Task { @MainActor in
                        await errorHandler(data)
                    }
                }
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

extension ShellCommand: Executable {
    /// Asynchronously run a shell command.
    ///
    /// This program will launch the command and wait for the process to complete.
    ///
    /// - Returns: The exit status of the process.
    @discardableResult @inlinable
    public func run() async throws -> Status {
        try setupProcess()
        let process = self.process
        try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                continuation.resume(returning: ())
            }
            do {
                try launch()
                if let inputHandler = inputHandler,
                   let stdin = inputPipe?.fileHandleForWriting {
                    Task.detached {
                        defer { try? stdin.close() }
                        while let data = try await inputHandler() {
                            if #available(macOS 10.15.4, *) {
                                try stdin.write(contentsOf: data)
                            } else {
                                stdin.write(data)
                            }
                        }
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
#if os(Linux)
        try? await Task.sleep(nanoseconds: 1)
#endif
        process.waitUntilExit()
        terminationStatus = process.terminationStatus
        terminationReason = process.terminationReason
        if let outputHandler = self.outputHandler,
           let fileHandle = outputPipe?.fileHandleForReading {
            let data: Data?
            if #available(macOS 10.15.4, *) {
                data = try fileHandle.readToEnd()
            } else {
                data = fileHandle.readDataToEndOfFile()
            }
            if let data = data {
                await outputHandler(data)
            }
        }
        if let errorHandler = self.errorHandler,
           let fileHandle = errorPipe?.fileHandleForReading {
            let data: Data?
            if #available(macOS 10.15.4, *) {
                data = try fileHandle.readToEnd()
            } else {
                data = fileHandle.readDataToEndOfFile()
            }
            if let data = data {
                await errorHandler(data)
            }
        }
        return terminationStatus
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
        guard let oldHandler = self.inputHandler else {
            standardInput = Pipe()
            self.inputHandler = inputHandler
            return
        }
        self.inputHandler = {
            if let data = try await oldHandler() { return data }
            return try await inputHandler()
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
    public func onOutput(call outputHandler: @escaping (Data) async -> Void) {
        guard let oldHandler = self.outputHandler else {
            standardOutput = Pipe()
            self.outputHandler = outputHandler
            return
        }
        self.outputHandler = {
            await oldHandler($0)
            await outputHandler($0)
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
    public func onError(call errorHandler: @escaping (Data) async -> Void) {
        guard let oldHandler = self.errorHandler else {
            standardError = Pipe()
            self.errorHandler = errorHandler
            return
        }
        self.errorHandler = {
            await oldHandler($0)
            await errorHandler($0)
        }
    }
}
