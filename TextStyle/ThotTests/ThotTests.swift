//
//  ThotTests.swift
//  ThotTests
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import XCTest
@testable import Thot

class ThotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEmptyText() {
        let elements = ElementParser.parse(text: "")
        XCTAssertTrue(elements.count == 0)
    }
    
    func test(text: String, equalTo comparedElements: [Element], file: StaticString = #file, line: UInt = #line) {
        let parsedElements = ElementParser.parse(text: text)
        for i in 0..<parsedElements.count {
            XCTAssertEqual(parsedElements[i].openTag, comparedElements[i].openTag, "openTag", file: file, line: line)
            XCTAssertEqual(parsedElements[i].closeTag, comparedElements[i].closeTag, "closeTag", file: file, line: line)
            XCTAssertEqual(parsedElements[i].content, comparedElements[i].content, "content", file: file, line: line)
        }
    }
    
    func testOneTag() {
        let text = "<title>Hello world !</title>"
        let elements = [
            Element(openTag: "title", content: "Hello world !", closeTag: "title")
        ]
        test(text: text, equalTo: elements)
    }
    
    func testTwoTags() {
        let text = "<title>Hello world !</title><body>This can be a description</body>"
        let elements = [
            Element(openTag: "title", content: "Hello world !", closeTag: "title"),
            Element(openTag: "body", content: "This can be a description", closeTag: "body")
        ]
        test(text: text, equalTo: elements)
    }
    
    func testThreeTags() {
        let text = "<title>Hello world !</title><body>This can be a description</body><title>Another Title</title>"
        let elements = [
            Element(openTag: "title", content: "Hello world !", closeTag: "title"),
            Element(openTag: "body", content: "This can be a description", closeTag: "body"),
            Element(openTag: "title", content: "Another Title", closeTag: "title")
        ]
        test(text: text, equalTo: elements)
    }
    
    func testThreeSimilarTags() {
        let text = "<title>Hello world !</title><title>Another Title</title><title>One more Title</title>"
        let elements = [
            Element(openTag: "title", content: "Hello world !", closeTag: "title"),
            Element(openTag: "title", content: "Another Title", closeTag: "title"),
            Element(openTag: "title", content: "One more Title", closeTag: "title")
        ]
        test(text: text, equalTo: elements)
    }
    
    func testEscapingCharacters() {
        let text = "<title>Hello \n world !</title><title>Another Title \\<\\></title>"
        let elements = [
            Element(openTag: "title", content: "Hello \n world !", closeTag: "title"),
            Element(openTag: "title", content: "Another Title <>", closeTag: "title"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownEmphasize() {
        let text = "<title>*Hello world !*</title><body>*This is a body*</body>"
        let elements = [
            Element(openTag: "title:em", content: "Hello world !", closeTag: "title:em"),
            Element(openTag: "body:em", content: "This is a body", closeTag: "body:em"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownEmphasizeAlternative() {
        let text = "<title>_Hello world !_</title>"
        let elements = [
            Element(openTag: "title:em", content: "Hello world !", closeTag: "title:em"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownDoubleEmphasize() {
        let text = "<title>*Hello**world !*</title><body>*This is a body*</body>"
        let elements = [
            Element(openTag: "title:em", content: "Hello", closeTag: "title:em"),
            Element(openTag: "title:em", content: "world !", closeTag: "title:em"),
            Element(openTag: "body:em", content: "This is a body", closeTag: "body:em"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownDoubleEmphasizeAlternative() {
        let text = "<title>*Hello*_world !_</title><body>_This is a body_</body>"
        let elements = [
            Element(openTag: "title:em", content: "Hello", closeTag: "title:em"),
            Element(openTag: "title:em", content: "world !", closeTag: "title:em"),
            Element(openTag: "body:em", content: "This is a body", closeTag: "body:em"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownStrong() {
        let text = "<title>**Hello world !**</title>"
        let elements = [
            Element(openTag: "title:st", content: "Hello world !", closeTag: "title:st"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownStrongAlternative() {
        let text = "<title>__Hello world !__</title>"
        let elements = [
            Element(openTag: "title:st", content: "Hello world !", closeTag: "title:st"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownDoubleStrong() {
        let text = "<title>__Hello____world !__</title><body>__This is a body__</body>"
        let elements = [
            Element(openTag: "title:st", content: "Hello", closeTag: "title:st"),
            Element(openTag: "title:st", content: "world !", closeTag: "title:st"),
            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownDoubleStrongWithEmphasize() {
        let text = "<title>__Hello___world !_</title><body>__This is a body__</body>"
        
        let elements = [
            Element(openTag: "title:st", content: "Hello", closeTag: "title:st"),
            Element(openTag: "title:em", content: "world !", closeTag: "title:em"),
            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownDoubleEmphasizeAndStrong() {
        let text = "<title>_Hello__world !_</title><body>__This is a body__</body>"
        let elements = [
            Element(openTag: "title:em", content: "Hello", closeTag: "title:em"),
            Element(openTag: "title:em", content: "world !", closeTag: "title:em"),
            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownEmphasizeAndStrong() {
        let text = "<title>*Hello world !*</title><body>**This is a body**</body>"
        let elements = [
            Element(openTag: "title:em", content: "Hello world !", closeTag: "title:em"),
            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownOutside() {
        let text = "<title>Hello world !</title>*LOL*<body>**This is a body**</body>"
        let elements = [
            Element(openTag: "title", content: "Hello world !", closeTag: "title"),
            Element(openTag: "em", content:"LOL", closeTag: "em"),
            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testPerformanceSingleTag() {
        let text = "<title>Hello world !</title>"
        self.measure {
            _ = ElementParser.parse(text: text)
        }
    }
    
    func testPerformanceMultipleTags() {
        let text = "<title>*Hello world !*</title><body>**This is a body**</body>"
        self.measure {
            _ = ElementParser.parse(text: text)
        }
    }
    
    func testPerformanceMultipleTagsComplex() {
        let text = "<title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title><title>Hello world !</title>"
        self.measure {
            _ = ElementParser.parse(text: text)
        }
    }
    
    func testPerformanceMultipleTagsComplexWithMardowns() {
        let text = "<title>**Hello world !**</title><title>__Hello__ **world** *!*</title><title>**Hello** __world__ _!_</title><title>_Hello_ __world !__</title><title>*Hello world !*</title><title>**Hello** **world** **!**</title><title>__Hello__ _world_ _!_</title><title>__Hello world !__</title><title>__Hello__ world__ !__</title><title>_Hello_ **world** _!_</title><title>**Hello world !**</title><title>__Hello__ **world** *!*</title><title>**Hello** __world__ _!_</title><title>_Hello_ __world !__</title><title>*Hello world !*</title><title>**Hello** **world** **!**</title><title>__Hello__ _world_ _!_</title><title>__Hello world !__</title><title>__Hello__ world__ !__</title><title>_Hello_ **world** _!_</title><title>**Hello world !**</title><title>__Hello__ **world** *!*</title><title>**Hello** __world__ _!_</title><title>_Hello_ __world !__</title><title>*Hello world !*</title><title>**Hello** **world** **!**</title><title>__Hello__ _world_ _!_</title><title>__Hello world !__</title><title>__Hello__ world__ !__</title><title>_Hello_ **world** _!_</title>"
        self.measure {
            _ = ElementParser.parse(text: text)
        }
    }

}
