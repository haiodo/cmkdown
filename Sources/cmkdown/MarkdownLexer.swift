//
//  MarkdownParser.swift
//  Tenniarb
//
//  Created by Andrey Sobolev on 18.09.2019.
//  Copyright © 2019 Andrey Sobolev. All rights reserved.
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

import Foundation

public class MarkdownLexer {
    private var bufferCount: Int = 0
    private var pos: Int = 0
    private var currentLine: Int = 0
    private var currentChar: Int = 0
    
    private var lineState = true
    
    private var tokenBuffer: [MarkdownToken] = []
    private var code: String
    private var it: String.Iterator
    private var nextChar: Character?
    private var currentCharValue: Character
    private var prevCharacter: Character = "\0"
    
    public var errorHandler: ((_ error: LexerError, _ startPos:Int, _ pos: Int ) -> Void)?
    
    public init( _ code: String) {
        self.code = code
        self.it = code.makeIterator()
        
        if let cc = self.it.next() {
            self.currentCharValue = cc
        } else {
            self.currentCharValue = "\0"
        }
        self.bufferCount = self.code.count
    }
    
    public func revert(tok: MarkdownToken) {
        tokenBuffer.insert(tok, at: 0)
    }
    
    private func add(type: MarkdownTokenType, literal: String, startPos: Int) {
        let c = literal.count
        self.tokenBuffer.append(
            MarkdownToken(type: type, literal: literal, line: currentLine, col: currentChar - c, pos: startPos, size: c)
        )
    }
    
    private func add(check pattern: inout String, startPos: Int) {
        if !pattern.isEmpty {
            self.add(type: .text, literal: pattern, startPos: startPos)
            pattern.removeAll()
        }
    }
    
    private func add(literal: String, startPos: Int) {
        let c = literal.count
        self.tokenBuffer.append(
            MarkdownToken(type: .text, literal: literal, line: currentLine, col: currentChar - c, pos: startPos, size: c)
        )
    }
    
    private func inc() {
        self.currentChar += 1
        self.pos += 1
        self.prevCharacter = self.currentCharValue
        if let nc = self.nextChar {
            self.currentCharValue = nc
            self.nextChar = nil
        } else {
            if let cc = self.it.next() {
                self.currentCharValue = cc
            } else {
                self.currentCharValue = "\0"
            }
        }
    }
    
    private func next() -> Character {
        if let nc = self.nextChar {
            return nc
        }
        if let ncc = self.it.next() {
            self.nextChar = ncc
        }
        if let nc = self.nextChar {
            return nc
        }
        return "\0"
    }
    
    public func getToken() -> MarkdownToken? {
        if !self.tokenBuffer.isEmpty {
            return self.tokenBuffer.removeFirst()
        }
        
        var r: String = ""
        var startPos = self.pos
        
        var wasWhiteSpace = self.pos == 0
        if self.pos > 0 && self.pos < self.bufferCount {
            switch prevCharacter {
            case " ", "\t", "\r","\n":
                wasWhiteSpace = true
            default:
                break
            }
        }
        
        while self.pos < self.bufferCount {
            let cc = currentCharValue
            switch (cc) {
            case " ", "\t":
                // Preserve spaces and tabs in text
                if r.isEmpty {
                    startPos = self.pos
                }
                r.append(cc)
                self.inc()
                wasWhiteSpace = true
            case "\r", "\n":
                // Add current text buffer before newline
                if !r.isEmpty {
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                }
                // Add newline as separate token
                self.add(type: .text, literal: String(cc), startPos: self.pos)
                self.inc()
                if cc == "\n" {
                    self.currentLine += 1
                    self.currentChar = 0
                    lineState = true // Mark as new line is started and we need to capture prefixes.
                }
                wasWhiteSpace = true
                startPos = self.pos
            case "\\":
                // Skip next if required to skip
                let nc = self.next()
                if r.isEmpty {
                    startPos = self.pos
                }
                self.inc()
                switch nc {
                case "@", "$", "*", "_", "#", "<", "~", "!":
                    r.append(nc)
                    self.inc()
                default:
                    r.append(cc)
                }
                wasWhiteSpace = false
            case "@":
                let nc = self.next()
                if nc == "(" {
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                    readUntil(r: &r, startLit: "(", endLit: ")", type: .image)
                } else {
                    if r.isEmpty {
                        startPos = self.pos
                    }
                    r.append(cc)
                    self.inc()
                }
                wasWhiteSpace = false
                break;
            case "!":
                let nc = self.next()
                if nc == "(" {
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                    readUntil(r: &r, startLit: "(", endLit: ")", type: .color, addEmpty: true)
                }
                else {
                    if r.isEmpty {
                        startPos = self.pos
                    }
                    r.append(cc)
                    self.inc()
                }
                wasWhiteSpace = false
                break;
            case "&":
                let nc = self.next()
                if nc == "(" {
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                    readUntil(r: &r, startLit: "(", endLit: ")", type: .font, addEmpty: true)
                }
                else {
                    if r.isEmpty {
                        startPos = self.pos
                    }
                    r.append(cc)
                    self.inc()
                }
                wasWhiteSpace = false
                break;
            case "*":
                // Check if this is bullets list, if we have at least 1 space and all spaces before it will be bullet.
                if lineState && next() == " " {
                    // Only whitespaces before, and at least one space
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                    r.append(cc)
                    self.inc()
                    self.add(type: .bullet, literal: r, startPos: startPos)
                    r.removeAll()
                } else if( wasWhiteSpace && next() != " " ) {
                    self.add(check: &r, startPos: startPos) // Add previous line
                    startPos = self.pos
                    self.inc()
                    // This is potentially ** ** - strong or * * emphasize
                    if processUntilCharExceptNewLine(&r, "*") {
                        self.add(type: .bold, literal: r, startPos: startPos)
                    } else {
                        if r == "" {
                            r.append("*") // Just *
                        }
                        self.add(type: .text, literal: r, startPos: startPos)
                    }
                    r.removeAll()
                } else {
                    // Just *
                    if r.isEmpty {
                        startPos = self.pos
                    }
                    r.append(cc)
                    self.inc()
                }
                wasWhiteSpace = false
                
                break;
            case "_":
                let nc = self.next()
                if wasWhiteSpace && nc != " " {
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                    self.inc()
                    if processUntilCharExceptNewLine(&r, "_") {
                        self.add(type: .italic, literal: r, startPos: startPos)
                    } else {
                        self.add(type: .text, literal: r, startPos: startPos)
                    }
                    r.removeAll()
                } else {
                    if r.isEmpty {
                        startPos = self.pos
                    }
                    r.append(cc)
                    self.inc()
                }
                wasWhiteSpace = false
                
                break;
            case "<":
                let nc = self.next()
                if wasWhiteSpace && nc != " " {
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                    self.inc()
                    if processUntilCharExceptNewLine(&r, ">") {
                        self.add(type: .underline, literal: r, startPos: startPos)
                    } else {
                        self.add(type: .text, literal: r, startPos: startPos)
                    }
                    r.removeAll()
                } else {
                    if r.isEmpty {
                        startPos = self.pos
                    }
                    r.append(cc)
                    self.inc()
                }
                wasWhiteSpace = false
                
                break;
            case "~":
                let nc = self.next()
                if wasWhiteSpace && nc != " " {
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                    self.inc()
                    if processUntilCharExceptNewLine(&r, "~") {
                        self.add(type: .scratch, literal: r, startPos: startPos)
                    } else {
                        self.add(type: .text, literal: r, startPos: startPos)
                    }
                    r.removeAll()
                } else {
                    if r.isEmpty {
                        startPos = self.pos
                    }
                    r.append(cc)
                    self.inc()
                }
                wasWhiteSpace = false
                
                break;
            case "#":
                self.add(check: &r, startPos: startPos)
                startPos = self.pos
                r.append(cc)
                self.inc()
                self.processUntilNewLine(&r)
                wasWhiteSpace = true
                self.add(type: .title, literal: r, startPos: startPos)
                r.removeAll()
                break;
            case "$":
                let nc = self.next()
                if nc == "(" {
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                    readUntil(r: &r, startLit: "(", endLit: ")", type: .expression)
                } else if nc == "{" {
                    self.add(check: &r, startPos: startPos)
                    startPos = self.pos
                    readUntil(r: &r, startLit: "{", endLit: "}", type: .expression)
                } else {
                    if r.isEmpty {
                        startPos = self.pos
                    }
                    r.append(cc)
                    self.inc()
                }
                wasWhiteSpace = false
                break;
            case "`":
                self.add(check: &r, startPos: startPos)
                startPos = self.pos
                self.readUntilWithEscaping(r: &r, lit: "`", type: .code )
                wasWhiteSpace = false
                break;
            default:
                wasWhiteSpace = false
                if r.isEmpty {
                    startPos = self.pos
                }
                r.append(cc)
                self.inc()
            }
            // Do not collect more whitespace characters.
            if !wasWhiteSpace {
                lineState = false
            }
        }
        
        self.add(check: &r, startPos: startPos)
        
        if self.pos == self.bufferCount {
            self.add(type: .eof, literal: "\0", startPos: self.pos)
            self.inc()
        }
        
        if !self.tokenBuffer.isEmpty {
            return self.tokenBuffer.removeFirst()
        } else {
            return nil
        }
    }
    
    private func processUntilNewLine( _ r: inout String) {
        // End of line comment
        while self.pos < self.bufferCount {
            let cc = currentCharValue
            if cc == "\n" {
                self.currentLine += 1
                lineState = true // Mark as new line is started and we need to capture prefixes.
                self.inc()
                self.currentChar = 0
                break
            }
            r.append(cc)
            self.inc()
        }
    }
    
    private func processUntilCharExceptNewLine( _ r: inout String, _ c: Character) -> Bool {
        // End of line comment
        while self.pos < self.bufferCount {
            let cc = currentCharValue
            if cc == "\n" {
                self.currentLine += 1
                self.inc()
                self.currentChar = 0
                lineState = true // Mark as new line is started and we need to capture prefixes.
                return false
            }
            if cc == c {
                // We found out character, return
                self.inc()
                return true
            }
            r.append(cc)
            self.inc()
        }
        return false
    }
    
    private func readUntilWithEscaping( r: inout String, lit: Character, type: MarkdownTokenType) {
        self.inc()
        
        var foundEnd = false
        let stPos = self.pos
        var content = ""
        while self.pos < self.bufferCount {
            let curChar = currentCharValue
            if  curChar == "\n" {
                self.currentLine += 1;
                self.currentChar = 0;
                content.append(curChar)
            }
            else if curChar == lit {
                self.add(type: type, literal: content, startPos: stPos)
                content.removeAll()
                self.inc()
                foundEnd = true
                break
            }
            else if (curChar == "\\" && self.next() == lit) {
                content.append(self.next())
                self.inc()
            } else {
                content.append(curChar)
            }
            self.inc()
        }
        if !content.isEmpty {
            self.add(type: type, literal: content, startPos: stPos)
            content.removeAll()
        }
        if !foundEnd {
            if let h = self.errorHandler {
                h(.EndOfLineReadString, stPos, pos)
            }
        }
    }
    
    private func readUntil( r: inout String, startLit: Character, endLit: Character, type: MarkdownTokenType, addEmpty: Bool = false) {
        self.inc()
        self.inc()
        
        let stPos = self.pos
        var foundEnd = false
        var indent = 1
        let startLine = self.currentLine
        var content = ""
        while self.pos < self.bufferCount {
            let curChar = currentCharValue
            if  curChar == "\n" {
                self.currentLine += 1;
                self.currentChar = 0;
                content.append(curChar)
            }
            else if curChar == startLit {
                indent += 1
                content.append(curChar)
            }
            else if curChar == endLit {
                indent -= 1
                if indent == 0 {
                    foundEnd = true
                    break
                }
                else {
                    content.append(curChar)
                }
            }
            else {
                content.append(curChar)
            }
            self.inc()
        }
        
        if !foundEnd {
            if let h = self.errorHandler {
                h(.EndOfExpressionReadError, stPos, pos)
            }
        }
        else {
            if !content.isEmpty || addEmpty {
                let c = content.count
                self.tokenBuffer.append(
                    MarkdownToken(type: type, literal: String(content), line: startLine, col: currentChar - c, pos: stPos, size: c)
                )
                content.removeAll()
            }
            self.inc()
        }
    }
    
    public static func getTokens(code: String ) -> [MarkdownToken] {
        let lexer = MarkdownLexer(code)
        var tokens:[MarkdownToken] = []
        
        while true {
            guard let t = lexer.getToken() else {
                break
            }
            tokens.append(t)
        }
        return tokens
    }
}
