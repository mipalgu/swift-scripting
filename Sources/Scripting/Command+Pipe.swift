//
//  Command+Pipe.swift
//
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import Foundation

infix operator <&
infix operator <<&
infix operator &<<
infix operator &<

/// Convenience Operators
public extension Command {
    /// Pipe the given data into the given shell command.
    ///
    /// - Parameters:
    ///   - inputData: The data to provide to the command via `stdin`.
    ///   - command: The command to execute.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func | (_ inputData: Data, _ command: Command) async -> Command {
        if case .error(_) = command { return command }
        return command.provide(input: inputData)
    }

    /// Pipe the given string into the given shell command.
    ///
    /// - Parameters:
    ///   - inputData: The string to provide to the command via `stdin`.
    ///   - command: The command to execute.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func | (_ inputString: String, _ command: Command) async -> Command {
        if case .error(_) = command { return command }
        do {
            try fromString(inputString, command.provide(input:))
        } catch {
            return .error(error)
        }
        return command
    }
}
