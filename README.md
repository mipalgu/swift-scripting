# Scripting

A package for shell-like scripting in Swift.

## Overview

This package provides a low-boilerplate means of scripting in Swift.
You can write scripts that resemble shell scripts, but utilise Swift's
structured concurrency.
Essentially, this means that, apart from the `await` keyword and double quotes, the syntax is very similar to that of a typical shell script.

Here are some examples:

```Swift
await "echo hello"
await "echo hello" > "outputfile.txt"
await "echo hello" | "cat -n" > "outputfile.txt"
await "echo $PATH" | #"tr ':' '\n'"# | "cat -n" > "outputfile.txt"
```
