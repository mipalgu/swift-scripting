//
//  Executable.swift
//
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 21/1/2023.
//
import Foundation
import SystemPackage

/// Abstract representation of an executable command.
public protocol Executable {
    /// The standard input I/O handle of the executable.
    var standardInput: IOHandle? { get set }
    /// The standard output I/O handle of the executable.
    var standardOutput: IOHandle? { get set }
    /// The standard error I/O handle of the executable.
    var standardError: IOHandle? { get set }
    /// Launch the underlying command.
    ///
    /// This method will start the command,
    /// but may not wait for its execution to
    /// complete.
    func launch() throws
    /// Run the underlying command to completion.
    ///
    /// This method will start the command asynchronously
    /// and can be awaited to complete
    ///
    /// - Returns: The completion status.
    @discardableResult
    func run() async throws -> Status
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
    func onInput(_ inputHandler: @escaping () async throws -> Data?)
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
    func onOutput(call outputHandler: @escaping (Data) async -> Void)
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
    func onError(call errorHandler: @escaping (Data) async -> Void)
}

/// Default implementation of convenience methods
public extension Executable {
    /// Set up standard input redirection from the given input data.
    ///
    /// - Parameter input: The input data to provide.
    /// - Returns: The receiver.
    @inlinable @discardableResult
    func redirectInput(from input: Data) -> Self {
        var inputData: Data? = input
        onInput {
            defer { inputData = nil }
            return inputData
        }
        return self
    }
    /// Set up standard input redirection from the given input file.
    ///
    /// - Parameter input: The input file to redirect `stdin` from.
    /// - Returns: The receiver.
    @inlinable @discardableResult
    func redirectInput(from inputFile: FileIO) throws -> Self {
        try inputFile.open(mode: .read)
        guard let handle = inputFile.handle else { throw Errno.noSuchFileOrDirectory }
        var this = self
        this.standardInput = handle
        return this
    }
    /// Set up standard output redirection to the given file.
    ///
    /// - Parameter outputFile: The output file to append to.
    /// - Returns: The receiver.
    @inlinable @discardableResult
    func redirectOutput(to outputFile: FileIO) throws -> Self {
        try outputFile.open(mode: .write)
        guard let handle = outputFile.handle else { throw Errno.noSuchFileOrDirectory }
        var this = self
        this.standardOutput = handle
        return this
    }
    /// Set up standard error redirection to the given file.
    ///
    /// - Parameter outputFile: The output file to append to.
    /// - Returns: The receiver.
    @inlinable @discardableResult
    func redirectErrorOutput(to outputFile: FileIO) throws -> Self {
        try outputFile.open(mode: .write)
        guard let handle = outputFile.handle else { throw Errno.noSuchFileOrDirectory }
        var this = self
        this.standardError = handle
        return this
    }
    /// Set up standard output redirection, appending to the given file.
    ///
    /// - Parameter outputFile: The output data to append to.
    /// - Returns: The receiver.
    @inlinable @discardableResult
    func appendOutput(to outputFile: FileIO) throws -> Self {
        try outputFile.open(mode: .append)
        guard let handle = outputFile.handle else { throw Errno.noSuchFileOrDirectory }
        var this = self
        this.standardOutput = handle
        return this
    }
    /// Set up standard error redirection, appending to the given file.
    ///
    /// - Parameter outputFile: The output data to append to.
    /// - Returns: The receiver.
    @inlinable @discardableResult
    func appendErrorOutput(to outputFile: FileIO) throws -> Self {
        try outputFile.open(mode: .append)
        guard let handle = outputFile.handle else { throw Errno.noSuchFileOrDirectory }
        var this = self
        this.standardError = handle
        return this
    }
    /// Run, returning both standad output and standard error data.
    ///
    /// This will run the underlying executable and return
    /// any data received from the executable's standard output
    /// and standard error.
    ///
    /// - Throws: This method will pass through any errors thrown by `run()`.
    @inlinable
    func runReturningOutput() async throws -> (output: Data, error: Data) {
        var stdoutData = Data()
        var stderrData = Data()
        onOutput { stdoutData.append($0) }
        onError  { stderrData.append($0) }
        try await run()
        return (output: stdoutData, error: stderrData)
    }
    /// Run, returning standard output Data.
    ///
    /// This will run the underlying executable and return
    /// any data received from the executable's standard output.
    ///
    /// - Throws: This method will pass through any errors thrown by `run()`.
    @inlinable
    func runReturningStandardOutput() async throws -> Data {
        var data = Data()
        onOutput { data.append($0) }
        try await run()
        return data
    }
    /// Run, returning standard error data.
    ///
    /// This will run the underlying executable and return
    /// any data received from the executable's standard error.
    ///
    /// - Throws: This method will pass through any errors thrown by `run()`.
    @inlinable
    func runReturningErrorOutput() async throws -> Data {
        var data = Data()
        onError { data.append($0) }
        try await run()
        return data
    }
    /// Run, returning data containing all output.
    ///
    /// This will run the underlying executable and return
    /// any data received from the executable's standard
    /// output and error.
    ///
    /// - Throws: This method will pass through any errors thrown by `run()`.
    @inlinable
    func runReturningAllOutput() async throws -> Data {
        var data = Data()
        onOutput { data.append($0) }
        onError  { data.append($0) }
        try await run()
        return data
    }
    /// Run, providing the given input string.
    ///
    /// This will run the underlying executable,
    /// providing the given input string as standard input.
    ///
    /// - Parameter input: The input to provide.
    @inlinable
    func provide(input: String) throws -> Self {
        try fromString(input, redirectInput(from:))
    }
    /// Run, returning both standad output and standard error data as a string.
    ///
    /// This will run the underlying executable and return
    /// any data received from the executable's standard output
    /// and standard error.
    ///
    /// - Throws: This method will pass through any errors thrown by `run()`.
    @inlinable
    func runReturningStringOutput() async throws -> (output: String, error: String) {
        let (stdout, stderr) = try await runReturningOutput()
        let outString = String(data: stdout, encoding: .utf8) ?? String(data: stdout, encoding: .utf16) ?? ""
        let errString = String(data: stderr, encoding: .utf8) ?? String(data: stderr, encoding: .utf16) ?? ""
        return (outString, errString)
    }
    /// Run, returning standard output as a string.
    ///
    /// This will run the underlying executable and return
    /// any data received from the executable's standard output.
    ///
    /// - Throws: This method will pass through any errors thrown by `run()`.
    @inlinable
    func runReturningStandardOutputString() async throws -> String {
        try await asString(runReturningStandardOutput)
    }
    /// Run, returning standard error data.
    ///
    /// This will run the underlying executable and return
    /// any data received from the executable's standard error.
    ///
    /// - Throws: This method will pass through any errors thrown by `run()`.
    @inlinable
    func runReturningErrorOutputString() async throws -> String {
        try await asString(runReturningErrorOutput)
    }
    /// Run, returning a string containing all output.
    ///
    /// This will run the underlying executable and return
    /// any data received from the executable's standard
    /// output and error.
    ///
    /// - Throws: This method will pass through any errors thrown by `run()`.
    @inlinable
    func runReturningAllOutputString() async throws -> String {
        try await asString(runReturningAllOutput)
    }
}

/// Call the given method and convert its output to a string.
/// - Parameter call: The method to call.
/// - Throws: This method will throw if the called method throws.
/// - Returns: The data returned by `call()` converted to a string.
@usableFromInline
func asString(_ call: () async throws -> Data) async throws -> String {
    let outputData = try await call()
    let string = String(data: outputData, encoding: .utf8) ?? String(data: outputData, encoding: .utf16) ?? ""
    return string
}

/// Convert the given string to data and call the given method.
/// - Parameter call: The method to call.
/// - Throws: This method will throw if the called method throws.
/// - Returns: The data returned by `call()` converted to a string.
@usableFromInline @discardableResult
func fromString<T>(_ string: String, _ call: (Data) throws -> T) throws -> T {
    guard let data = string.data(using: .utf8, allowLossyConversion: true) else {
        throw Errno.invalidArgument
    }
    let output = try call(data)
    return output
}
