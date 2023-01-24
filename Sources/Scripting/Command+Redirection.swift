//
//  ShellCommand+Redirection.swift
//  
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import Foundation
import SystemPackage

infix operator >&
infix operator >>&
infix operator &>>
infix operator &>

/// Convenience Operators
public extension Command {
    /// Run the given shell command, providing its input
    /// from the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - inputData: The data to provide to the command via `stdin`.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func < (_ command: Command, _ inputData: Data) async -> Command {
        if case .error(_) = command { return command }
        return command.provide(input: inputData)
    }
    /// Run the given shell command and append its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >> (_ command: Command, _ outputData: inout Data) async -> Command {
        if case .error(_) = command { return command }
        do {
            outputData.append(try await command.runReturningStandardOutput())
        } catch {
            return .error(error)
        }
        return command
    }

    /// Run the given shell command and append its error output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func &>> (_ command: Command, _ outputData: inout Data) async -> Command {
        if case .error(_) = command { return command }
        do {
            outputData.append(try await command.runReturningErrorOutput())
        } catch {
            return .error(error)
        }
        return command
    }

    /// Run the given shell command and append all its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >>& (_ command: Command, _ outputData: inout Data) async -> Command {
        if case .error(_) = command { return command }
        do {
            outputData.append(try await command.runReturningAllOutput())
        } catch {
            return .error(error)
        }
        return command
    }

    /// Run the given shell command and redirect its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func > (_ command: Command, _ outputData: inout Data) async -> Command {
        if case .error(_) = command { return command }
        do {
            outputData = try await command.runReturningStandardOutput()
        } catch {
            return .error(error)
        }
        return command
    }

    /// Run the given shell command and redirect its error output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func &> (_ command: Command, _ outputData: inout Data) async -> Command {
        if case .error(_) = command { return command }
        do {
            outputData = try await command.runReturningErrorOutput()
        } catch {
            return .error(error)
        }
        return command
    }

    /// Run the given shell command and redirect all its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >& (_ command: Command, _ outputData: inout Data) async -> Command {
        if case .error(_) = command { return command }
        do {
            outputData = try await command.runReturningAllOutput()
        } catch {
            return .error(error)
        }
        return command
    }

    /// Run the given shell command and append its output
    /// to the given string.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputString: The string that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >> (_ command: Command, _ outputString: inout String) async -> Command {
        var outputData = Data()
        let result = await command >> outputData
        if let string = String(data: outputData, encoding: .utf8) ?? String(data: outputData, encoding: .utf16) {
            outputString += string
        }
        return result
    }

    /// Run the given shell command and append its error output
    /// to the given string.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputString: The string that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func &>> (_ command: Command, _ outputString: inout String) async -> Command {
        var outputData = Data()
        let result = await command &>> outputData
        if let string = String(data: outputData, encoding: .utf8) ?? String(data: outputData, encoding: .utf16) {
            outputString += string
        }
        return result
    }

    /// Run the given shell command and append all its output
    /// to the given string.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputString: The string that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >>& (_ command: Command, _ outputString: inout String) async -> Command {
        var outputData = Data()
        let result = await command >>& outputData
        if let string = String(data: outputData, encoding: .utf8) ?? String(data: outputData, encoding: .utf16) {
            outputString += string
        }
        return result
    }

    /// Run the given shell command and redirect its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputFile: The file that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func > (_ command: Command, _ outputFile: FileIO) async -> Command {
        switch command {
        case .error(_):
            return command
        case let .executable(executable):
            guard let shellCommand = executable as? ShellCommand else { return .error(Errno.notSupported) }
            do {
                try outputFile.open(mode: .write)
                guard let handle = outputFile.handle else { return .error(Errno.noSuchFileOrDirectory) }
                shellCommand.standardOutput = handle
                try await command.run()
            } catch {
                return .error(error)
            }
        }
        return command
    }

    /// Run the given shell command and redirect its output
    /// to the given string.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputString: The string that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func > (_ command: Command, _ outputString: inout String) async -> Command {
        var outputData = Data()
        let result = await command > outputData
        if let string = String(data: outputData, encoding: .utf8) ?? String(data: outputData, encoding: .utf16) {
            outputString = string
        }
        return result
    }

    /// Run the given shell command and redirect all its output
    /// to the given string.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputString: The data that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >& (_ command: Command, _ outputString: inout
                    String) async -> Command {
        var outputData = Data()
        let result = await command >& outputData
        if let string = String(data: outputData, encoding: .utf8) ?? String(data: outputData, encoding: .utf16) {
            outputString = string
        }
        return result
    }
}
