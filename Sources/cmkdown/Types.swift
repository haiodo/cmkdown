//
//  Types.swift
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

public enum MarkdownTokenType {
    case text
    case bold   // * bold \* text * - all until next *
    case italic // _ italic \_ text * - all until next _
    case image // @(image name|640x480), @(image name|640), @(image name|x480)
    case color // !(red), !(#ffeeff), !(red|word) !()- default color => global text color
    case font // &(20|word), &(20) Some text &() - Define a different font-size option
    case expression // ${expression}
    case title // ## Title value
    case bullet // * some value
    case code   // `some code`
    case underline // <underscore>
    case scratch // ~text~
    case eof
}

public class MarkdownToken {
    public let type: MarkdownTokenType
    public let literal: String
    public let line: Int
    public let col: Int
    public let pos: Int
    public let size: Int
    
    init( type: MarkdownTokenType, literal: String, line: Int = 0, col:Int = 0, pos:Int = 0, size:Int = 0) {
        self.type = type
        self.literal = literal
        self.line = line
        self.col = col
        self.pos = pos
        self.size = size
    }
}

extension MarkdownToken: Hashable {
    public static func == (lhs: MarkdownToken, rhs: MarkdownToken) -> Bool {
        return lhs.type == rhs.type && lhs.literal == rhs.literal && lhs.line == rhs.line && lhs.col == lhs.col && lhs.pos == rhs.pos && lhs.size == rhs.size;
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.type)
        hasher.combine(self.literal)
        hasher.combine(self.col)
        hasher.combine(self.pos)
        hasher.combine(self.size)
    }
}

public enum LexerError {
    case EndOfLineReadString
    case EndOfExpressionReadError
    case UTF8Error
}

