//
//  HTMLPrinterTests.swift
//  TenniarbTests
//
//  Created by [Your Name] on [Current Date].
//

import Testing
// Import your library module. This name must match the one in your Package.swift file.
@testable import cmkdown
import Cocoa

// MARK: - Mocks and Helpers

/// A mock provider for testing purposes.
class MockImageProvider: ImageProvider {
    override func resolveImage(path: String) -> (NSImage?, CGRect) {
        // For testing, we return a dummy 100x50 image and rect.
        let size = CGSize(width: 100, height: 50)
        let image = NSImage(size: size)
        return (image, CGRect(origin: .zero, size: size))
    }
}

/// A helper function to run the full lexer-to-printer pipeline.
func generateHTML(from markdown: String, imageProvider: ImageProvider = MockImageProvider(1)) -> String {
    let tokens = MarkdownLexer.getTokens(code: markdown)
    let value = HTMLPrinter.toHTML(tokens, originalFont: 16.0, textColor: "black", imageProvider: imageProvider)
    Swift.debugPrint("GEN", value.replacingOccurrences(of: "\n", with: "\\n"))
    return value
}

// MARK: - Tests

/// Tests plain text conversion.
@Test func testPlainText() {
    let markdown = "Hello, world!"
    let expectedHTML = "<div><span>Hello, world!</span></div>"
    #expect(generateHTML(from: markdown) == expectedHTML, "Plain text test failed.")
}
