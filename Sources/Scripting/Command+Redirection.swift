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

/// Input redirection
public extension Command {
    /// Provide the given data as input for the command.
    ///
    /// - Parameters:
    ///   - inputData: The data to provide to the command via `stdin`.
    /// - Returns: The command with its input redirected.
    @inlinable
    func redirect(from inputData: Data) -> Command {
        perform { $0.redirectInput(from: inputData) }
    }

    /// Modify the given shell command and redirect its input
    /// from the given file.
    ///
    /// - Parameters:
    ///   - inputFile: The file providing the input of the command.
    /// - Returns: The command with its input redirected.
    @inlinable
    func redirect(from inputFile: FileIO) async -> Command {
        perform { try $0.redirectInput(from: inputFile) }
    }

    /// Redirect the output of the command
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func redirectStandardOutput(to outputFile: FileIO) -> Command {
        perform {
            try $0.redirectOutput(to: outputFile)
        }
    }
    /// Run the given shell command and redirect its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runRedirectingStandardOutput(to outputFile: FileIO) async -> Command {
        await redirectStandardOutput(to: outputFile).perform {
            try await $0.run()
        }
    }
    /// Run the given shell command and redirect its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - outputData: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runRedirectingStandardOutput(to outputData: inout Data) async -> Command {
        await perform {
            outputData = try await $0.runReturningStandardOutput()
        }
    }

    /// Configure the receiver to append its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func appendStandardOutput(to outputFile: FileIO) -> Command {
        perform {
            try $0.appendOutput(to: outputFile)
        }
    }
    /// Run the given shell command and redirect its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runAppendingStandardOutput(to outputFile: FileIO) async -> Command {
        await appendStandardOutput(to: outputFile).perform {
            try await $0.run()
        }
    }
    /// Run the given shell command and appending its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - outputData: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runAppendingStandardOutput(to outputData: inout Data) async -> Command {
        await perform {
            outputData.append(try await $0.runReturningStandardOutput())
        }
    }

    /// Redirect the error output of the receiver
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func redirectStandardError(to outputFile: FileIO) -> Command {
        perform {
            try $0.redirectErrorOutput(to: outputFile)
        }
    }
    /// Run the given shell command and redirect its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runRedirectingStandardError(to outputFile: FileIO) async -> Command {
        await redirectStandardError(to: outputFile).perform {
            try await $0.run()
        }
    }
    /// Run the given shell command and redirect its error output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - outputData: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runRedirectingStandardError(to outputData: inout Data) async -> Command {
        await perform {
            outputData.append(try await $0.runReturningErrorOutput())
        }
    }

    /// Configure the receiver to append its error output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func appendStandardError(to outputFile: FileIO) -> Command {
        perform {
            try $0.appendErrorOutput(to: outputFile)
        }
    }
    /// Run the given shell command and redirect its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runAppendingStandardError(to outputFile: FileIO) async -> Command {
        await appendStandardError(to: outputFile).perform {
            try await $0.run()
        }
    }
    /// Run the given shell command and append its error output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - outputData: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runAppendingStandardError(to outputData: inout Data) async -> Command {
        await perform {
            outputData.append(try await $0.runReturningErrorOutput())
        }
    }

    /// Redirect all the output of the receiver
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func redirectAll(to outputFile: FileIO) -> Command {
        perform {
            var executable = try $0.redirectErrorOutput(to: outputFile)
            executable.standardOutput = outputFile.handle
            return self
        }
    }
    /// Run the given shell command and redirect all its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runRedirectingAllOutput(to outputFile: FileIO) async -> Command {
        await redirectAll(to: outputFile).perform {
            try await $0.run()
        }
    }
    /// Run the given shell command and redirect all its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - outputData: The data that should contain all output of the command
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runRedirectingAllOutput(to outputData: inout Data) async -> Command {
        await perform {
            outputData = try await $0.runReturningAllOutput()
        }
    }

    /// Append all the output of the receiver
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func appendAll(to outputFile: FileIO) -> Command {
        perform {
            var executable = try $0.appendErrorOutput(to: outputFile)
            executable.standardOutput = outputFile.handle
            return self
        }
    }
    /// Run the given shell command and append all its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - outputFile: The data that should contain the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runAppendingAllOutput(to outputFile: FileIO) async -> Command {
        await appendAll(to: outputFile).perform {
            try await $0.run()
        }
    }
    /// Run the given shell command and append all its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - outputData: The data that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    func runAppendingAllOutput(to outputData: inout Data) async -> Command {
        await perform {
            outputData.append(try await $0.runReturningAllOutput())
        }
    }
}

/// Convenience Operators
public extension Command {
    /// Modify the given shell command, providing its input
    /// from the given data.
    ///
    /// - Parameters:
    ///   - command: The command whose input to redirect.
    ///   - inputData: The data to provide to the command via `stdin`.
    /// - Returns: The command in a state where it can be run with its input redirected, or representing an error state.
    @inlinable
    static func < (_ command: Command, _ inputData: Data) async -> Command {
        command.redirect(from: inputData)
    }

    /// Modify the given shell command and redirect its input
    /// from the given file.
    ///
    /// - Parameters:
    ///   - command: The command whose input to redirect.
    ///   - inputFile: The file providing the input of the command.
    /// - Returns: The command in a state where it can be run with its input redirected, or representing an error state.
    @inlinable
    static func < (_ command: Command, _ inputFile: FileIO) async -> Command {
        await command.redirect(from: inputFile)
    }

    /// Run the given shell command and append its output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    static func >> (_ command: Command, _ outputData: inout Data) async -> Command {
        await command.runAppendingStandardOutput(to: &outputData)
    }

    /// Run the given shell command and append its error output
    /// to the given data.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputData: The data that should have the output of the command appended.
    /// - Returns: The result of executing the command.
    @discardableResult @inlinable
    static func &>> (_ command: Command, _ outputData: inout Data) async -> Command {
        await command.runAppendingStandardError(to: &outputData)
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
        await command.runAppendingAllOutput(to: &outputData)
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
        await command.runRedirectingStandardOutput(to: &outputData)
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
        await command.runRedirectingStandardError(to: &outputData)
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
        await command.runRedirectingAllOutput(to: &outputData)
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

    /// Run the given shell command and redirect its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputFile: The file that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func > (_ command: Command, _ outputFile: FileIO) async -> Command {
        await command.runRedirectingStandardOutput(to: outputFile)
    }

    /// Run the given shell command and append its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputFile: The file that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func >> (_ command: Command, _ outputFile: FileIO) async -> Command {
        await command.runAppendingStandardOutput(to: outputFile)
    }

    /// Run the given shell command and redirect its error output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputFile: The file that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func &> (_ command: Command, _ outputFile: FileIO) async -> Command {
        await command.runRedirectingStandardError(to: outputFile)
    }

    /// Run the given shell command and append its output
    /// to the given file.
    ///
    /// - Parameters:
    ///   - command: The command to execute.
    ///   - outputFile: The file that should be filled with the output of the command.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func &>> (_ command: Command, _ outputFile: FileIO) async -> Command {
        await command.runAppendingStandardError(to: outputFile)
    }
}
