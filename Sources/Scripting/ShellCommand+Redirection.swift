//
//  ShellCommand+Redirection.swift
//  
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import Foundation

infix operator >&
infix operator >>&
infix operator &>>
infix operator &>

/// Convenience Operators
public extension ShellCommand {
    /// Run the given shell command and append its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >> (_ command: ShellCommand, _ outputData: inout Data) async -> Result<Status, Error> {
        var data = outputData
        let status: Status
        do {
            status = try await command.run(onOutput: {
                data.append($0)
            })
        } catch {
            return .failure(error)
        }
        if let fileHandle = command.standardOutput?.fileHandleForReading {
            data.append(fileHandle.availableData)
        }
        outputData = data
        return .success(status)
    }

    /// Run the given shell command and append its error output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func &>> (_ command: ShellCommand, _ outputData: inout Data) async -> Result<Status, Error> {
        var data = outputData
        let status: Status
        do {
            status = try await command.run(onError: {
                data.append($0)
            })
        } catch {
            return .failure(error)
        }
        if let fileHandle = command.standardError?.fileHandleForReading {
            data.append(fileHandle.availableData)
        }
        outputData = data
        return .success(status)
    }

    /// Run the given shell command and append all its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >>& (_ command: ShellCommand, _ outputData: inout Data) async -> Result<Status, Error> {
        var data = outputData
        let status: Status
        do {
            let callback: (Data) async -> Void = {
                data.append($0)
            }
            status = try await command.run(onOutput: callback, onError: callback)
        } catch {
            return .failure(error)
        }
        if let fileHandle = command.standardError?.fileHandleForReading {
            data.append(fileHandle.availableData)
        }
        if let fileHandle = command.standardOutput?.fileHandleForReading {
            data.append(fileHandle.availableData)
        }
        outputData = data
        return .success(status)
    }

    /// Run the given shell command and redirect its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func > (_ command: ShellCommand, _ outputData: inout Data) async -> Result<Status, Error> {
        var data = Data()
        let result = await command >> data
        outputData = data
        return result
    }

    /// Run the given shell command and redirect its error output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func &> (_ command: ShellCommand, _ outputData: inout Data) async -> Result<Status, Error> {
        var data = Data()
        let result = await command &>> data
        outputData = data
        return result
    }

    /// Run the given shell command and redirect all its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >& (_ command: ShellCommand, _ outputData: inout Data) async -> Result<Status, Error> {
        var data = Data()
        let result = await command >>& data
        outputData = data
        return result
    }

    /// Run the given shell command and append its output
    /// to the given string.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputString: The string that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >> (_ command: ShellCommand, _ outputString: inout String) async -> Result<Status, Error> {
        var outputData = Data()
        let result = await command >> outputData
        if let string = String(data: outputData, encoding: .utf8) ?? String(data: outputData, encoding: .utf16) {
            outputString += string
        }
        return result
    }

    /// Run the given shell command and redirect its output
    /// to the given string.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputString: The string that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func > (_ command: ShellCommand, _ outputString: inout String) async -> Result<Status, Error> {
        var outputData = Data()
        let result = await command > outputData
        if let string = String(data: outputData, encoding: .utf8) ?? String(data: outputData, encoding: .utf16) {
            outputString = string
        }
        return result
    }
}
