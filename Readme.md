
# CMKDown

A lightweight Swift library for parsing and rendering Markdown-like text with extended syntax support for macOS applications.

## Overview

CMKDown provides a comprehensive solution for converting Markdown-like text into both HTML and NSAttributedString formats, making it ideal for macOS applications that need to display rich text content. The library extends standard Markdown syntax with additional features for colors, font sizes, images, and more.

## Features

- **Standard Markdown Support**: Headers, bold, italic, underline, strikethrough, lists, and code blocks
- **Extended Syntax**: Custom color and font size controls
- **Image Handling**: With caching and resizing capabilities
- **Dual Output**: Generate both HTML and NSAttributedString for flexible rendering
- **Color Palette**: Includes extensive color definitions (standard colors + Google Material Design palette)
- **Performance Optimized**: Efficient tokenization and rendering pipeline

## Why CMKDown?

While many Markdown libraries exist, CMKDown addresses specific needs for macOS application development:

1. **Rich Text Rendering**: Direct conversion to NSAttributedString enables seamless integration with Cocoa text components
2. **Extended Syntax**: Additional markup for colors and font sizes provides more control over text appearance
3. **Image Management**: Built-in image caching and resizing optimizes performance in document-heavy applications
4. **HTML Output**: For web-based components or export functionality
5. **Lightweight**: Minimal dependencies and focused feature set

## Installation

Add CMKDown to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/haiodo/cmkdown.git", from: "1.0.0")
]
```

## Usage

### Basic Markdown Parsing

```swift
import CMKDown

// Parse markdown text into tokens
let markdownText = """
# This is a header

This is **bold** and this is _italic_ text.

* Bullet point 1
* Bullet point 2

`code snippet`
"""

let tokens = MarkdownLexer.getTokens(code: markdownText)
```

### Rendering to NSAttributedString

```swift
import CMKDown
import Cocoa

// Create an image provider
let imageProvider = ImageProvider(scaleFactor: 2.0)

// Configure font and paragraph style
let font = NSFont.systemFont(ofSize: 14)
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.lineSpacing = 2.0

// Convert tokens to NSAttributedString
var shift = CGPoint.zero
let attributedString = MarkDownAttributedPrinter.toAttributedStr(
    tokens,
    font: font,
    paragraphStyle: paragraphStyle,
    foregroundColor: NSColor.black,
    shift: &shift,
    imageProvider: imageProvider
)

// Use in NSTextView or other text component
textView.textStorage?.setAttributedString(attributedString)
```

### Rendering to HTML

```swift
import CMKDown

// Create an image provider
let imageProvider = ImageProvider(scaleFactor: 1.0)

// Convert tokens to HTML
let html = HTMLPrinter.toHTML(
    tokens,
    originalFont: 14,
    textColor: "black",
    imageProvider: imageProvider
)

// Use in WebView or save to file
webView.loadHTMLString(html, baseURL: nil)
```

## Extended Syntax

### Colors

```markdown
// Set text color globally
"!(red) This text will be red"

// Apply color to specific text
"!(blue|This text will be blue) but this will be default color"

// Reset to default color
"!() This text uses default color"
```

### Font Sizes

```markdown
// Set font size globally
"&(20) This text uses 20pt font"

// Apply font size to specific text
"&(16|This text uses 16pt font) but this uses default size"

// Reset to default font size
"&() This text uses default font size"
```

### Images

```markdown
// Basic image
"@(image.png)"

// Image with width
"@(image.png|640)"

// Image with height
"@(image.png|x480)"

// Image with both width and height
"@(image.png|640x480)"
```

### Headers

```markdown
"# H1 Header"
"## H2 Header"
"### H3 Header"
```

### Text Formatting

```markdown
// Bold
"*Bold text*"

// Italic
"_Italic text_"

// Underline
"<Underlined text>"

// Strikethrough
"~Strikethrough text~"

// Code
"`Inline code`"

// Code block
"```
Multi-line
code block
```"

// Lists
"* List item 1
* List item 2"
```

## Color Support

CMKDown includes extensive color support with:

- Standard CSS color names
- Google Material Design color palette
- Hex color codes

Examples:
```markdown
"!(red) Red text"
"!(#FF5733) Custom hex color"
"!(blue-500) Material Design blue"
"!(deep-purple-A200) Material Design deep purple accent"
```

## Image Provider Implementation

To use images in your markdown, implement the `ImageProvider` class:

```swift
class CustomImageProvider: ImageProvider {
    override func resolveImage(name: String) -> CachedImage? {
        // Load your image here
        if let image = NSImage(named: name) {
            return CachedImage(image: image, size: image.size)
        }
        return nil
    }
}

let imageProvider = CustomImageProvider(scaleFactor: 2.0)
```

## License

CMKDown is licensed under the Eclipse Public License, Version 2.0. See [LICENSE](https://www.eclipse.org/legal/epl-2.0) for more information.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
