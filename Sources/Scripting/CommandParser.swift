//
//  CommandParser.swift
//  
//  Copyright © 2023 Rene Hexel.  All rights reserved.
//  Created by Rene Hexel on 21/1/2023.
//
import Foundation

/// Parse the given command.
///
/// This function parses the given command string,
/// using the same algorighm that shells use, i.e.,
/// whitespaces separate arguments, except where
/// quoted with a single or double quote.  Environment
/// variables prefixed with a `$` sign are expanded
/// from the given environment.  A backslash `\` character
/// escapes the next character.
///
/// - Note: currently, this does not parse nested variables.
///
/// - Parameters:
///   - command: The command to parse.
///   - environment: Dictionary representing the environment.
public func parse(
    command: String,
    environment: [String : String] = [:])
-> [String] {
    var arguments = [String]()
    var argument = ""
    var inQuotes = false
    var inDoubleQuotes = false
    var escapeNext = false
    var variable = ""
    var variableContent: String { String(variable[variable.index(after: variable.startIndex)...]) }
    for c in command {
        if escapeNext {
            switch c {
            case "0": arguments.append("\0")
            case "n": arguments.append("\n")
            case "r": arguments.append("\r")
            case "t": arguments.append("\t")
            default:
                argument.append(c)
            }
            escapeNext = false
        } else if c == "\\" {
            escapeNext = true
        } else if c == "$" {
            if inQuotes {
                argument.append(c)
            } else {
                if !variable.isEmpty {
                    argument.append(environment[variableContent] ?? "")
                }
                variable = "$"
            }
        } else if c.isLetter || c.isNumber || c == "_" {
            if !variable.isEmpty {
                variable.append(c)
            } else {
                argument.append(c)
            }
        } else {
            if !variable.isEmpty {
                argument.append(environment[variableContent] ?? "")
                variable = ""
            }
            if c.isWhitespace {
                if !inQuotes && !inDoubleQuotes {
                    if !argument.isEmpty {
                        arguments.append(argument)
                        argument = ""
                    }
                } else {
                    argument.append(c)
                }
            } else if c == "\"" {
                if inQuotes {
                    argument.append(c)
                } else {
                    if inDoubleQuotes {
                        arguments.append(argument)
                        argument = ""
                    }
                    inDoubleQuotes.toggle()
                }
            } else if c == "'" {
                if inDoubleQuotes {
                    argument.append(c)
                } else {
                    if inQuotes {
                        arguments.append(argument)
                        argument = ""
                    }
                    inQuotes.toggle()
                }
            } else {
                argument.append(c)
            }
        }
    }
    if !argument.isEmpty {
        arguments.append(argument)
    }
    return arguments
}
