//
//  Command+Pipe.swift
//
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 20/1/2023.
//
import Foundation
import SystemPackage

infix operator <&
infix operator <<&
infix operator &<<
infix operator &<

/// Convenience Operators
public extension Command {
    /// Pipe one command into another.
    ///
    /// This operator pipes standard output from one command
    /// into standard input of another command.
    ///
    /// - Parameters:
    ///   - lhs: The command whose `stdout` feeds `stdin` of `rhs`.
    ///   - rhs: The command whose `stdin` receives `stdout` from `lhs`.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func | (_ lhs: Command, _ rhs: Command) async -> Command {
        if case .error(_) = rhs { return rhs }
        if case .error(_) = lhs { return lhs }
        guard case let .executable(lhsExecutable) = lhs,
              case let .executable(rhsExecutable) = rhs,
              let lhsShellCommand = lhsExecutable as? ShellCommand,
              let rhsShellCommand = rhsExecutable as? ShellCommand,
              lhsShellCommand.standardOutput == nil,
              rhsShellCommand.standardInput == nil else {
            return .error(Errno.invalidArgument)
        }
        let pipe = Pipe()
        lhsShellCommand.standardOutput = pipe
        rhsShellCommand.standardInput = pipe
        do {
            try await lhs.run()
        } catch {
            return .error(error)
        }
        return rhs
    }

    /// Pipe the given data into the given shell command.
    ///
    /// - Parameters:
    ///   - inputData: The data to provide to the command via `stdin`.
    ///   - command: The command to execute.
    /// - Returns: The result of executing the command.
    @discardableResult
    static func | (_ inputData: Data, _ command: Command) async -> Command {
        if case .error(_) = command { return command }
        return command.redirectInput(from: inputData)
    }
}
