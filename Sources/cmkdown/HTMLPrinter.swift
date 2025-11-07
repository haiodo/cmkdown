//
//  HTMLPrinter.swift
//  cmkdown
//
//  Copyright © 2025 Andrey Sobolev. All rights reserved.
//
//  Licensed under the Eclipse Public License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License. You may
//  obtain a copy of the License at https://www.eclipse.org/legal/epl-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
//  See the License for the specific language governing permissions and
//  limitations under the License.

import CoreGraphics
import Foundation

typealias htmlAttrType = String

public class HTMLPrinter {
    private static func calcTitleFontSize(_ text: String, fontSize: CGFloat) -> (String, CGFloat, Int) {
        var hlevel = 0
        var calch = true
        var result = ""
        for c in text {
            if calch {
                if c == "#" {
                    hlevel += 1
                    continue
                } else if c == " " || c == "\t" {
                    continue
                }
                else {
                    calch = false
                }
            }
            result.append(c)
        }
        return (result, fontSize + 5 - CGFloat(hlevel * 2), hlevel)
    }
    
    private static func htmlStr(_ text: String, _ attributes: [String: String]) -> String {
        if attributes.isEmpty {
            return text
        }
        
        var attrs = ""
        for (key, value) in attributes {
            attrs += " \(key)=\"\(value)\""
        }
        
        return "<span\(attrs)>\(text)</span>"
    }
    
    public static func toHTML(_ tokens: [MarkdownToken], originalFont: CGFloat, textColor: String, imageProvider: ImageProvider) -> String {
        // The wrapper div no longer has a default font-size style.
        var result = "<div>"
        
        // State variables for the *current* effective style.
        var currentColor = ""
        var currentFontSize = originalFont
        
        // State variables to track the *last* style applied to an element,
        // to minimize redundant style attributes.
        var lastAppliedColor = ""
        var lastAppliedFontSize = originalFont
        
        var pos = 0
        var prevMultiCode = false
        var lastLiteral = ""
        var lastToken: MarkdownTokenType = .eof
        var inList = false
        
        for t in tokens {
            var literal = t.literal
            
            // Escape HTML special characters in text
            literal = literal
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
            
            if prevMultiCode {
                prevMultiCode = false
                if literal.hasPrefix("\n") {
                    literal = String(literal.suffix(literal.count-1))
                }
                let colorValue = parseColor("grey-200")
                result += "<pre style=\"background-color: \(colorToHex(colorValue)); color: black;\">\n</pre>"
            }
            
            if t.type != .eof {
                lastToken = t.type
            }
            
            switch t.type {
            case .text:
                var styleAttributes = [String]()
                
                // Only include font-size if it changed from the last applied size
                if currentFontSize != lastAppliedFontSize {
                    styleAttributes.append("font-size: \(currentFontSize)px")
                    lastAppliedFontSize = currentFontSize
                }
                
                // Only include color if it changed from the last applied color
                if currentColor != lastAppliedColor {
                    styleAttributes.append(currentColor)
                    lastAppliedColor = currentColor
                }
                
                let styleAttr = styleAttributes.isEmpty ? "" : " style=\"\(styleAttributes.joined(separator: "; "))\""
                result += "<span\(styleAttr)>\(literal)</span>"
                
            case .bold:
                result += "<strong>\(literal)</strong>"
            case .bullet:
                if !inList {
                    result += "<ul style=\"margin-left: \(5 * literal.count)px;\">\n"
                    inList = true
                }
                result += "<li>\(literal)</li>\n"
            case .image:
                let (image, rect) = imageProvider.resolveImage(path: t.literal)
                if let img = image, let r = rect {
                    let width = r.width
                    let height = r.height
                    result += "<img src=\"\(t.literal)\" width=\"\(width)\" height=\"\(height)\" alt=\"\(t.literal)\" />"
                }
            case .italic:
                result += "<em>\(literal)</em>"
            case .underline:
                result += "<u>\(literal)</u>"
            case .scratch:
                result += "<del>\(literal)</del>"
            case .title:
                let (title, titleSize, hlevel) = calcTitleFontSize(literal, fontSize: originalFont)
                let headerTag = "h\(min(max(hlevel, 1), 6))" // Ensure h1-h6
                result += "<\(headerTag) style=\"font-size: \(titleSize)px;\">\(title)</\(headerTag)>\n"
            case .color:
                if let splitPos = literal.firstIndex(of: "|") {
                    let color = String(literal.prefix(upTo: splitPos))
                    let word = String(literal.suffix(from: literal.index(after: splitPos)))
                    
                    let colorValue = parseColor(color)
                    let colorHex = colorToHex(colorValue)
                    result += "<span style=\"color: \(colorHex);\">\(word)</span>"
                } else {
                    if literal.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count == 0 {
                        // Reset color to default (empty)
                        currentColor = ""
                    } else {
                        // Set new global color
                        currentColor = "color: \(colorToHex(parseColor(literal)));"
                    }
                }
            case .font:
                if let splitPos = literal.firstIndex(of: "|") {
                    if let fontSize = Double(String(literal.prefix(upTo: splitPos))) {
                        let word = String(literal.suffix(from: literal.index(after: splitPos)))
                        // Inline font size, always apply the style
                        result += "<span style=\"font-size: \(fontSize)px;\(currentColor)\">\(word)</span>"
                    }
                } else {
                    if literal.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count == 0 {
                        // Reset font size to default
                        currentFontSize = originalFont
                    } else {
                        if let fontSize = Double(String(literal)) {
                            // Set new global font size
                            currentFontSize = CGFloat(fontSize)
                        }
                    }
                }
            case .code:
                let colorValue = parseColor("grey-200")
                if literal.contains("\n") {
                    if !literal.hasPrefix("\n") && !lastLiteral.hasSuffix("\n") {
                        result += "<br>"
                    }
                    if !literal.hasSuffix("\n") {
                        prevMultiCode = true
                    }
                    result += "<pre style=\"background-color: \(colorToHex(colorValue)); color: black;\">\(literal)</pre>"
                } else {
                    result += "<code style=\"background-color: \(colorToHex(colorValue)); color: black;\">\(literal)</code>"
                }
            case .eof:
                break
            default:
                break
            }
            pos += 1
            lastLiteral = literal
        }
        
        if inList {
            result += "</ul>\n"
        }
        
        if lastToken == .image {
            result += "<br>"
        }
        
        result += "</div>"
        
        return result
    }
}
