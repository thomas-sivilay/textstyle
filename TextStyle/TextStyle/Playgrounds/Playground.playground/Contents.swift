//: A UIKit based Playground to present user interface

import UIKit
import PlaygroundSupport
import XCTest

struct Style: Decodable {
    let name: String?
    let size: CGFloat
    let color: UIColor
    let alignment: NSTextAlignment
    let kern: CGFloat
    let lineHeightMultiple: CGFloat
    let paragraphSpacing: CGFloat
    let numberOfLines: Int
    var markdown: Markdown
    
    private enum CodingKeys: String, CodingKey {
        case name
        case size
        case color
        case alignment
        case kern
        case lineHeightMultiple
        case paragraphSpacing
        case numberOfLines
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let name = try values.decodeIfPresent(String.self, forKey: .name)
        let size = try values.decodeIfPresent(CGFloat.self, forKey: .size)
        let colorString = try values.decodeIfPresent(String.self, forKey: .color)
        let alignmentString = try values.decodeIfPresent(String.self, forKey: .alignment)
        let kern = try values.decodeIfPresent(CGFloat.self, forKey: .kern)
        let lineHeightMultiple = try values.decodeIfPresent(CGFloat.self, forKey: .lineHeightMultiple)
        let paragraphSpacing = try values.decodeIfPresent(CGFloat.self, forKey: .paragraphSpacing)
        let numberOfLines = try values.decodeIfPresent(Int.self, forKey: .numberOfLines)
        
        let color = ColorAdapter.uiColor(from: colorString) ?? .black
        let alignment = AlignmentAdapter.nsTextAlignment(from: alignmentString) ?? .natural
        
        self = .init(name: name,
                     size: size ?? 13.0,
                     color: color,
                     alignment: alignment,
                     kern: kern ?? 0.0,
                     lineHeightMultiple: lineHeightMultiple ?? 0.0,
                     paragraphSpacing: paragraphSpacing ?? 0.0,
                     numberOfLines: numberOfLines ?? 1,
                     markdown: .none)
        return
    }
    
    init(name: String? = nil,
         size: CGFloat = 13.0,
         color: UIColor = .black,
         alignment: NSTextAlignment = .natural,
         kern: CGFloat = 0.0,
         lineHeightMultiple: CGFloat = 0.0,
         paragraphSpacing: CGFloat = 0.0,
         numberOfLines: Int = 1,
         markdown: Markdown = .none
    ) {
        self.name = name
        self.size = size
        self.color = color
        self.alignment = alignment
        self.kern = kern
        self.lineHeightMultiple = lineHeightMultiple
        self.paragraphSpacing = paragraphSpacing
        self.numberOfLines = numberOfLines
        self.markdown = markdown
    }
}

final class ColorAdapter {
    class func uiColor(from string: String?) -> UIColor? {
        guard let string = string else {
            return nil
        }
        
        switch string {
        case "black":
            return .black
        case "white":
            return .white
        case "red":
            return .red
        case "blue":
            return .blue
        case "green":
            return .green
        default:
            return nil
        }
    }
}

final class AlignmentAdapter {
    class func nsTextAlignment(from string: String?) -> NSTextAlignment? {
        guard let string = string else {
            return nil
        }
        
        switch string {
        case "natural":
            return .natural
        case "left":
            return .left
        case "right":
            return .right
        case "center":
            return .center
        default:
            return nil
        }
    }
}

enum StyleOrAttributes {
    case style(name: String)
    case attributes(style: Style)
}

struct RichText {
    var text: String
}

extension RichText: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        self = RichText(text: text)
    }
}

struct TextStyle {
    var text: String
    var style: StyleOrAttributes
}

extension TextStyle: Decodable {
    private enum CodingKeys: String, CodingKey {
        case text
        case style
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let text = try container.decode(String.self, forKey: .text)
        
        // To refactor
        if let style = try? container.decodeIfPresent(Style.self, forKey: .style) {
            self = TextStyle(text: text, style: StyleOrAttributes.attributes(style: style!))
        } else if let name = try? container.decodeIfPresent(String.self, forKey: .style) {
            self = TextStyle(text: text, style: StyleOrAttributes.style(name: name!))
        } else {
            fatalError()
        }
    }
}

struct Theme: Decodable {
    let styles: [String: Style] // name-id: Style
    
    func style(with tag: String) -> Style? {
        let splittedTag = tag.split(separator: ":")
        let styleName = splittedTag[0]
        var style = styles[String(styleName)]
        
        if splittedTag.count > 1 {
            let markdown = splittedTag[1]
            switch markdown {
            case "em":
                style?.markdown = .emphasize
                break
            case "st":
                style?.markdown = .strong
                break
            default:
                break
            }
        }
        
        
        return style
    }
}

enum Markdown: Int {
    case none
    case emphasize // * * or _ _ -> italic
    case strong // ** ** or __ __ -> bold
//    case strikethrough
//    case underline
//    case code // monospace
}

enum Token {
    case string(String)
    case openMarkdown(Markdown)
    case closeMarkdown(Markdown)
    case openTag(String)
    case closeTag(String)
}

enum TokenizingError: Error {
    case unknownCharacter
    case invalidTag
}

struct Tokenizer {
    private var iterator: String.CharacterView.Iterator
    private var pushedBackCharacter: Character?
    private var buffer = String()
    private var previousMarkdown: Markdown?

    // MARK: - Initializer

    init(text: String) {
        iterator = text.characters.makeIterator()
    }

    // MARK: -

    mutating func nextToken() throws -> Token? {
        while var ch = nextCharacter() {
            switch ch {
            case "\\":
                if let nch = nextCharacter() {
                    buffer.append(nch)
                    ch = nch
                }
                break
            case "*", "_":
                if let res = checkBuffer(with: ch) {
                    return .string(res)
                } else {
                    return try markdown(startingWith: ch)
                }
            case "<":
                if let res = checkBuffer(with: ch) {
                    return .string(res)
                } else {
                    return try tag()
                }
            default:
                buffer.append(ch)
            }
        }
        return nil
    }

    // MARK: - Private
    
    private mutating func checkBuffer(with character: Character) -> String? {
        if buffer.characters.count > 0 {
            let res = buffer
            buffer = String()
            pushedBackCharacter = character
            return res
        } else {
            return nil
        }
    }
    
    private mutating func markdown(startingWith character: Character) throws -> Token {
        while let ch = nextCharacter() {
            switch ch {
            case character:
                if let markdown = previousMarkdown {
                    if markdown == .emphasize {
                        pushedBackCharacter = ch
                    }
                    previousMarkdown = nil
                    return .closeMarkdown(markdown)
                }
                previousMarkdown = .strong
                return .openMarkdown(.strong)
            default:
                pushedBackCharacter = ch
                if let markdown = previousMarkdown {
                    previousMarkdown = nil
                    return .closeMarkdown(markdown)
                }
                previousMarkdown = .emphasize
                return .openMarkdown(.emphasize)
            }
        }
        if let markdown = previousMarkdown {
            previousMarkdown = nil
            return .closeMarkdown(markdown)
        }
        previousMarkdown = .emphasize
        return .openMarkdown(.emphasize)
    }
    
    private mutating func tag() throws -> Token {
        var tokenText = String()
        while let ch = nextCharacter() {
            switch ch {
            case ">":
                if tokenText.first == "/" {
                    tokenText.removeFirst()
                    return .closeTag(tokenText)
                } else {
                    return .openTag(tokenText)
                }
            default:
                tokenText.append(ch)
            }
        }
        
        throw TokenizingError.invalidTag
    }

    private mutating func nextCharacter() -> Character? {
        if let next = pushedBackCharacter {
            pushedBackCharacter = nil
            return next
        }
        return iterator.next()
    }
}

struct Element {
    var openTag: String
    var content: String
    var closeTag: String
    
    init(openTag: String = "",
         content: String = "",
         closeTag: String = "") {
        self.openTag = openTag
        self.content = content
        self.closeTag = closeTag
    }
}

class ElementParser {
    class func parse(text: String) -> [Element] {
        var tokenizer = Tokenizer(text: text)
        return try! self.parse(with: tokenizer)
    }
    
    private enum Step {
        case open
        case content
        case close
        case unknown
    }
    
    class func parse(with tokenizer: Tokenizer) throws -> [Element] {
        var tokenizer = tokenizer
        var elements = [Element]()
        var element = Element()
        var subElement = Element()
        
        while let token = try tokenizer.nextToken() {
            switch token {
            case let .openTag(tag):
                element.openTag = tag
            case let .closeTag(tag):
                element.closeTag = tag
                elements.append(element)
                element = Element()
            case let .string(s):
                if subElement.openTag != "" {
                    subElement.content = s
                } else {
                    element.content = s
                }
            case let .openMarkdown(d):
                let markdownSymbol = d == .emphasize ? "em" : "st"
                if element.openTag != "" {
                    subElement.openTag = "\(element.openTag):\(markdownSymbol)"
                } else {
                    element.openTag = markdownSymbol
                }
            case let .closeMarkdown(d):
                let markdownSymbol = d == .emphasize ? "em" : "st"
                if element.openTag != "" && subElement.openTag != "" {
                    subElement.closeTag = "\(element.openTag):\(markdownSymbol)"
                    elements.append(subElement)
                    subElement = Element()
                } else {
                    element.closeTag = markdownSymbol
                    elements.append(element)
                    element = Element()
                }
            }
        }
        
        return elements.filter { $0.content != "" }
    }
}

extension UILabel {
    func setRichText(_ text: String, with theme: Theme) {
        self.attributedText = makeAttributedString(for: text, with: theme)
        self.numberOfLines = 0
    }
    
    func setText(_ text: String, with style: Style) {
        self.attributedText = makeAttributedString(for: text, with: style)
        self.numberOfLines = style.numberOfLines
    }
    
    private func makeAttributedString(for text: String, with theme: Theme) -> NSAttributedString {
        let elements = ElementParser.parse(text: text)
        var richText = [(String, Style)]()

        let aText = NSMutableAttributedString()
        
        elements.forEach { element in
            if let style = theme.style(with: element.openTag), element.openTag == element.closeTag {
                richText.append((element.content, style))
            } else {
                // error
                print("ERROR, can't find style with name: \(element.openTag)")
            }
        }
        
        richText.forEach {
            aText.append(makeAttributedString(for: $0.0, with: $0.1))
        }
        
        return aText
    }
    
    private func makeAttributedString(for text: String, with style: Style) -> NSAttributedString {
        let attributes = makeAttributes(for: style)
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    private func makeAttributes(for style: Style) -> [NSAttributedStringKey: Any] {
        var attributes = [NSAttributedStringKey: Any]()
        attributes[NSAttributedStringKey.foregroundColor] = style.color
        
        if style.markdown == Markdown.emphasize {
            attributes[NSAttributedStringKey.font] = UIFont.italicSystemFont(ofSize: style.size)
        } else if style.markdown == Markdown.strong {
            attributes[NSAttributedStringKey.font] = UIFont.boldSystemFont(ofSize: style.size)
        } else {
            attributes[NSAttributedStringKey.font] = UIFont.systemFont(ofSize: style.size)
        }
        
        attributes[NSAttributedStringKey.kern] = style.kern
        attributes[NSAttributedStringKey.paragraphStyle] = makeParagraphStyle(for: style)
        
        return attributes
    }
    
    private func makeParagraphStyle(for style: Style) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = style.alignment
        paragraphStyle.lineHeightMultiple = style.lineHeightMultiple
        paragraphStyle.paragraphSpacing = style.paragraphSpacing
        
        return paragraphStyle
    }
}

final class Render {
    var theme: Theme?
    
    func render(label: UILabel, with textStyle: TextStyle) {
        var style = Style()
        
        switch textStyle.style {
        case let .style(name):
            if let theme = theme, let themeStyle = theme.styles[name] {
                style = themeStyle
            }
        case let .attributes(attributes):
            style = attributes
        }
        
        label.setText(textStyle.text, with: style)
    }
    
    func render(label: UILabel, with richText: RichText) {
        label.setRichText(richText.text, with: theme!)
        label.numberOfLines = 0
    }
}

let themeJSON = """
{
    "styles": {
        "title": { "name": "title", "size": 26.0, "color": "red", "alignmenent": "center" },
        "body": { "name": "body", "size": 17.0, "color": "blue", "alignmenent": "left" }
    }
}
""".data(using: .utf8)!

let viewControllerJSON = """
{
"textStyle1": { "text": "Hello World!", "style": "title" },
"textStyle2": { "text": "Welcome to my new framework", "style": "body" },
"textStyle3": { "text": "Backend driven style but layout is done on app side", "style": { "size": 14.0, "color": "green"} },
"textStyle4": "<title>__Hello__ *World!*</title><body>Not</body><title>LOL</title>"
}
""".data(using: .utf8)!

final class myViewController : UIViewController {
    
    private struct MyViewControllerData: Decodable {
        let textStyle1: TextStyle
        let textStyle2: TextStyle
        let textStyle3: TextStyle
        let textStyle4: RichText
    }
    
    private var label1: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        return label
    }()
    private var label2: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 50, width: 300, height: 50))
        return label
    }()
    private var label3: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 100, width: 300, height: 50))
        return label
    }()
    private var label4: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 150, width: 300, height: 150))
        return label
    }()
    
    private var render: Render = Render()
    
    private var data = MyViewControllerData(textStyle1: TextStyle(text: "", style: StyleOrAttributes.style(name: "toto")),
                                            textStyle2: TextStyle(text: "", style: StyleOrAttributes.style(name: "toto")),
                                            textStyle3: TextStyle(text: "", style: StyleOrAttributes.style(name: "toto")),
                                            textStyle4: RichText(text: ""))
        {
        didSet {
            [(label1, data.textStyle1),
             (label2, data.textStyle2),
             (label3, data.textStyle3)]
                .forEach {
                    render.render(label: $0.0, with: $0.1)
                }
            
            // To improve
            render.render(label: label4, with: data.textStyle4)
        }
    }
    
    private var theme: Theme?
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        
        [label1, label2, label3, label4].forEach {
            view.addSubview($0)
        }
        
        loadData()
        
        self.view = view
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        do {
            theme = try decoder.decode(Theme.self, from: themeJSON)
            render.theme = theme
            data = try decoder.decode(MyViewControllerData.self, from: viewControllerJSON)
        } catch {
            print(error)
        }
    }
}

//PlaygroundPage.current.liveView = myViewController()

final class Tests: XCTestCase {
    
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

Tests.defaultTestSuite.run()

