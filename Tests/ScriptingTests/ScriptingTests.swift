import XCTest
@testable import Scripting

final class ScriptingTests: XCTestCase {
    func testPathSearch() {
        if #available(macOS 13.0, *) {
            XCTAssertEqual(search(for: "ls", in: "/bin")?.path(percentEncoded: false), "/bin/ls")
        } else {
            XCTAssertEqual(search(for: "ls", in: "/bin")?.path, "/bin/ls")
        }
    }

    func testHello() throws {
        var string = ""
        ShellCommand("/bin/echo", arguments: ["hello"]) > string
        XCTAssertEqual(string, "hello\n")
    }
}
