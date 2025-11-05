import Testing
@testable import cmkdown

func printTokens(_ tokens: [MarkdownToken]) -> String {
    var s = ""
    var i = 0
    for token in tokens {
        s += "#\(i):\(token.type):\(token.literal)\n"
        i += 1
    }
    return s
}

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    
    let tokens = MarkdownLexer.getTokens(code: "*Display* queries/paths\nin *Responses*\nRM-13104")
        
    #expect(tokens.count == 8)
    
    #expect(tokens[0].pos == 0)
    #expect(tokens[0].literal == "Display")
    #expect(tokens[0].type == .bold)
}

@Test func hWorld() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    
    let tokens = MarkdownLexer.getTokens(code: "Hello World!")
    
    Swift.debugPrint(printTokens(tokens))
    
    #expect(tokens.count == 2)
    #expect(tokens[0].type == .text)
    #expect(tokens[0].literal == "Hello World!")
    #expect(tokens[1].type == .eof)
}

@Test func testBoldParsing2() {
    let tokens = MarkdownLexer.getTokens(code: """
        * 1. *Re-connect* local NSM only(if pod are same)
        * 1.1 Modify NSMD(1/2) stored connection info
        * 1.2 do Request() on local Dataplane
        * 1.3 return connection to NSC/NSE.
        * - Dataplane/NSMD1 is potential fail points here.
        * 2. Cleanup and configure new connection.
        * 2.1 NSMD1 do *Close()* on local Dataplane.
        * 2.2 NSMD1 do Close() on remote NSMD2
        * 2.3 NDMS2 do Close() on local DataPlane
        * 2.4 NSMD2 do Close() on local NSE
        * 2.5 do "Connection" with all steps again.
        """)
    Swift.debugPrint(printTokens(tokens))
    #expect(tokens.count == 37)
    
    #expect(tokens[22].pos == 279)
    #expect(tokens[22].literal == "Close()")
    #expect(tokens[22].type == .bold)
}

@Test func testBasicParsing() {
    let lexer = MarkdownLexer(
        """
    *box* text
    # title A

    Regular text *bold* line _italic_ line.

    @(my_image|640)

    """)
    
    var tokens:[MarkdownToken] = []
            
    while true {
        guard let t = lexer.getToken() else {
            break
        }
        tokens.append(t)
    }
    
    Swift.debugPrint(printTokens(tokens))
    
    #expect(tokens.count == 15)
            
    #expect(tokens[10].pos == 61)
    #expect(tokens[12].literal == "my_image|640")
    #expect(tokens[12].type == .image)
}

@Test func testItalicParsing() {
    let tokens = MarkdownLexer.getTokens(code: "_italic_ text _more italic_")
    #expect(tokens.count == 4)
    
    #expect(tokens[0].pos == 0)
    #expect(tokens[0].literal == "italic")
    #expect(tokens[0].type == .italic)
    
    #expect(tokens[2].pos == 14)
    #expect(tokens[2].literal == "more italic")
    #expect(tokens[2].type == .italic)
}

@Test func testCodeParsing() {
    let tokens = MarkdownLexer.getTokens(code: "`code` and more `more code`")
    #expect(tokens.count == 4)
    
    #expect(tokens[0].pos == 1)
    #expect(tokens[0].literal == "code")
    #expect(tokens[0].type == .code)
    
    #expect(tokens[2].pos == 17)
    #expect(tokens[2].literal == "more code")
    #expect(tokens[2].type == .code)
}

@Test func testTitleParsing() {
    let tokens = MarkdownLexer.getTokens(code: "# Title\n## Second Title\n### Third Title")
    Swift.debugPrint(printTokens(tokens))
    #expect(tokens.count == 4)
    
    #expect(tokens[0].pos == 0)
    #expect(tokens[0].literal == "# Title")
    #expect(tokens[0].type == .title)
    
    #expect(tokens[1].pos == 8)
    #expect(tokens[1].literal == "## Second Title")
    #expect(tokens[1].type == .title)
    
    #expect(tokens[2].pos == 24)
    #expect(tokens[2].literal == "### Third Title")
    #expect(tokens[2].type == .title)
}

@Test func testUnderlineParsing() {
    let tokens = MarkdownLexer.getTokens(code: "<underline> text <more underline>")
    Swift.debugPrint(printTokens(tokens))
    #expect(tokens.count == 4)
    
    #expect(tokens[0].pos == 0)
    #expect(tokens[0].literal == "underline")
    #expect(tokens[0].type == .underline)
    
    #expect(tokens[2].pos == 17)
    #expect(tokens[2].literal == "more underline")
    #expect(tokens[2].type == .underline)
}

@Test func testScratchParsing() {
    let tokens = MarkdownLexer.getTokens(code: "~scratch~ text ~more scratch~")
    #expect(tokens.count == 4)
    
    #expect(tokens[0].pos == 0)
    #expect(tokens[0].literal == "scratch")
    #expect(tokens[0].type == .scratch)
    
    #expect(tokens[2].pos == 15)
    #expect(tokens[2].literal == "more scratch")
    #expect(tokens[2].type == .scratch)
}

@Test func testColorParsing() {
    let tokens = MarkdownLexer.getTokens(code: "!(red) text !(#ff0000) more")
    #expect(tokens.count == 5)
    
    #expect(tokens[0].pos == 2)
    #expect(tokens[0].literal == "red")
    #expect(tokens[0].type == .color)
    
    #expect(tokens[2].pos == 14)
    #expect(tokens[2].literal == "#ff0000")
    #expect(tokens[2].type == .color)
}

@Test func testFontParsing() {
    let tokens = MarkdownLexer.getTokens(code: "&(14) text &(20) more")
    #expect(tokens.count == 5)
    
    #expect(tokens[0].pos == 2)
    #expect(tokens[0].literal == "14")
    #expect(tokens[0].type == .font)
    
    #expect(tokens[2].pos == 13)
    #expect(tokens[2].literal == "20")
    #expect(tokens[2].type == .font)
}

@Test func testExpressionParsing() {
    let tokens = MarkdownLexer.getTokens(code: "${expression} text ${another}")
    #expect(tokens.count == 4)
    
    #expect(tokens[0].pos == 2)
    #expect(tokens[0].literal == "expression")
    #expect(tokens[0].type == .expression)
    
    #expect(tokens[2].pos == 21)
    #expect(tokens[2].literal == "another")
    #expect(tokens[2].type == .expression)
}

@Test func testComplexMarkdown() {
    let tokens = MarkdownLexer.getTokens(code: """
        # Main Title
        
        This is *bold* and _italic_ text with `code` and <underline> and ~scratch~.
        
        * Bullet item
          * Nested bullet
        
        !(red) Colored text !(#ff0000) more colored.
        
        &(14) Font size 14 &(20) font size 20.
        
        ${expression} and ${another expression}
        
        @(image.png|640x480) Image with size.
        """)
    
    Swift.debugPrint(printTokens(tokens))
    #expect(tokens.count == 43)
    
    // Check title
    #expect(tokens[0].pos == 0)
    #expect(tokens[0].literal == "# Main Title")
    #expect(tokens[0].type == .title)
    
    // Check bold
    #expect(tokens[3].pos == 22)
    #expect(tokens[3].literal == "bold")
    #expect(tokens[3].type == .bold)
    
    // Check italic
    #expect(tokens[5].pos == 33)
    #expect(tokens[5].literal == "italic")
    #expect(tokens[5].type == .italic)
    
    // Check code
    #expect(tokens[7].pos == 53)
    #expect(tokens[7].literal == "code")
    #expect(tokens[7].type == .code)
    
    // Check underline
    #expect(tokens[9].pos == 63)
    #expect(tokens[9].literal == "underline")
    #expect(tokens[9].type == .underline)
    
    // Check scratch
    #expect(tokens[11].pos == 79)
    #expect(tokens[11].literal == "scratch")
    #expect(tokens[11].type == .scratch)
    
    // Check newline
    #expect(tokens[14].pos == 90)
    #expect(tokens[14].literal == "\n")
    #expect(tokens[14].type == .text)
    
    // Check bullet
    #expect(tokens[15].pos == 91)
    #expect(tokens[15].literal == "*")
    #expect(tokens[15].type == .bullet)
    
    // Check nested bullet
    #expect(tokens[19].pos == 107)
    #expect(tokens[19].literal == "*")
    #expect(tokens[19].type == .bullet)
    
    // Check color
    #expect(tokens[23].pos == 126)
    #expect(tokens[23].literal == "red")
    #expect(tokens[23].type == .color)
    
    // Check second color
    #expect(tokens[25].pos == 146)
    #expect(tokens[25].literal == "#ff0000")
    #expect(tokens[25].type == .color)
    
    // Check font
    #expect(tokens[29].pos == 172)
    #expect(tokens[29].literal == "14")
    #expect(tokens[29].type == .font)
    
    // Check second font
    #expect(tokens[31].pos == 191)
    #expect(tokens[31].literal == "20")
    #expect(tokens[31].type == .font)
    
    // Check expression
    #expect(tokens[35].pos == 212)
    #expect(tokens[35].literal == "expression")
    #expect(tokens[35].type == .expression)
    
    // Check second expression
    #expect(tokens[37].pos == 230)
    #expect(tokens[37].literal == "another expression")
    #expect(tokens[37].type == .expression)
    
    // Check image
    #expect(tokens[40].pos == 253)
    #expect(tokens[40].literal == "image.png|640x480")
    #expect(tokens[40].type == .image)
}
