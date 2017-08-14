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
    case strikethrough
    case underline
//    case code // monospace
}

final class ElementParser {
    
    private enum Step {
        case open
        case content
        case close
        case unknown
    }
    
    private enum ElementType {
        case openTag(String)
        case content(String)
        case closeTag(String)
    }
    
    class func parse(text: String) -> [Element] {
        guard text.characters.count > 0 else {
            return [Element]()
        }
        
        var offset = 0
        var string = ""
        var step = Step.unknown
        var element = Element(openTag: "", content: "", closeTag: "")
        var elements = [Element]()
        var subElements = [Element]()
        var markdownSymbol = ""
        
        while offset < text.characters.count {
            let character = text.characters[text.characters.index(text.characters.startIndex, offsetBy: offset)]
            let nextIndex = text.characters.index(text.characters.startIndex, offsetBy: offset + 1, limitedBy: text.characters.endIndex)
            
            switch String(character) {
            case "*", "_":
                var nextCharacter: String? = nil
                if let nextIndex = nextIndex {
                    nextCharacter = String(text.characters[nextIndex])
                }
                
                if (markdownSymbol.characters.count == 1 && markdownSymbol == String(character)) || (markdownSymbol.characters.count == 2 && markdownSymbol == (String(character) + nextCharacter!)) {
                    // CLOSING
                    switch step {
                    case .content:
                        // EMBEDDED
                        let symbol = markdownSymbol == "*" || markdownSymbol == "_" ? "em" : "st"
                        let openTag = "\(element.openTag):\(symbol)"
                        subElements.append(Element(openTag: openTag, content: string, closeTag: ""))
                        string = ""
                        break
                    default:
                        break
                    }
                    markdownSymbol = ""
                } else {
                    if nextCharacter == String(character) {
                        markdownSymbol = String(character) + nextCharacter!
                        offset += 1
                    } else {
                        markdownSymbol = String(character)
                    }
                }
                break
            case "\\":
                if let nextIndex = nextIndex {
                    offset += 1
                    string += String(text.characters[nextIndex])
                }
                break
            case "<":
                if string.characters.count > 0 {
                    element.content = string
                    string = ""
                }
                step = .open
                break
            case ">":
                if step != .content {
                    if step == .open {
                        element.openTag = string
                    } else if step == .close {
                        element.closeTag = string
                        print("e: \(element)")
                        for var element in subElements {
                            element.closeTag = element.openTag
                            elements.append(element)
                        }
                        subElements = [Element]()
                        elements.append(element)
                        element = Element(openTag: "", content: "", closeTag: "")
                        step = .unknown
                    }
                    string = ""
                }
                step = .content
                break
            case "/":
                step = .close
            default:
                string += String(character)
                break
            }
            
            offset += 1
        }
        
        return elements
    }
}

struct Element {
    var openTag: String
    var content: String
    var closeTag: String
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
        var elements = ElementParser.parse(text: text)
        var richText = [(String, Style)]()

        var aText = NSMutableAttributedString()
        
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

PlaygroundPage.current.liveView = myViewController()

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
            Element(openTag: "title", content: "", closeTag: "title"),
            Element(openTag: "body:em", content: "This is a body", closeTag: "body:em"),
            Element(openTag: "body", content: "", closeTag: "body"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownEmphasizeAlternative() {
        let text = "<title>_Hello world !_</title>"
        let elements = [
            Element(openTag: "title:em", content: "Hello world !", closeTag: "title:em"),
            Element(openTag: "title", content: "", closeTag: "title"),
            ]
        test(text: text, equalTo: elements)
    }

    func testMarkdownDoubleEmphasize() {
        let text = "<title>*Hello**world !*</title><body>*This is a body*</body>"
        let elements = [
            Element(openTag: "title:em", content: "Hello", closeTag: "title:em"),
            Element(openTag: "title:em", content: "world !", closeTag: "title:em"),
            Element(openTag: "title", content: "", closeTag: "title"),
            Element(openTag: "body:em", content: "This is a body", closeTag: "body:em"),
            Element(openTag: "body", content: "", closeTag: "body"),
            ]
        test(text: text, equalTo: elements)
    }

    func testMarkdownDoubleEmphasizeAlternative() {
        let text = "<title>*Hello*_world !_</title><body>_This is a body_</body>"
        let elements = [
            Element(openTag: "title:em", content: "Hello", closeTag: "title:em"),
            Element(openTag: "title:em", content: "world !", closeTag: "title:em"),
            Element(openTag: "title", content: "", closeTag: "title"),
            Element(openTag: "body:em", content: "This is a body", closeTag: "body:em"),
            Element(openTag: "body", content: "", closeTag: "body"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownStrong() {
        let text = "<title>**Hello world !**</title>"
        let elements = [
            Element(openTag: "title:st", content: "Hello world !", closeTag: "title:st"),
            Element(openTag: "title", content: "", closeTag: "title"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownStrongAlternative() {
        let text = "<title>__Hello world !__</title>"
        let elements = [
            Element(openTag: "title:st", content: "Hello world !", closeTag: "title:st"),
            Element(openTag: "title", content: "", closeTag: "title"),
            ]
        test(text: text, equalTo: elements)
    }

    // BUG
//    func testMarkdownDoubleStrong() {
//        let text = "<title>__Hello____world !__</title><body>__This is a body__</body>"
//                let parsedElements = ElementParser.parse(text: text)
//                print(parsedElements)
//
//        let elements = [
//            Element(openTag: "title:st", content: "Hello", closeTag: "title:st"),
//            Element(openTag: "title", content: "world !", closeTag: "title"),
//            Element(openTag: "title", content: "", closeTag: "title"),
//            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
//            Element(openTag: "body", content: "", closeTag: "body"),
//            ]
//        test(text: text, equalTo: elements)
//    }

    // BUG
    func testMarkdownDoubleStrongWithEmphasize() {
        let text = "<title>__Hello___world !_</title><body>__This is a body__</body>"
//        let parsedElements = ElementParser.parse(text: text)
//        print(parsedElements)
        
        let elements = [
            Element(openTag: "title:st", content: "Hello", closeTag: "title:st"),
            Element(openTag: "title", content: "world !", closeTag: "title"),
            Element(openTag: "title", content: "", closeTag: "title"),
            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
            Element(openTag: "body", content: "", closeTag: "body"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownDoubleEmphasizeAndStrong() {
        let text = "<title>_Hello__world !_</title><body>__This is a body__</body>"
        let elements = [
            Element(openTag: "title:em", content: "Hello", closeTag: "title:em"),
            Element(openTag: "title:em", content: "world !", closeTag: "title:em"),
            Element(openTag: "title", content: "", closeTag: "title"),
            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
            Element(openTag: "body", content: "", closeTag: "body"),
            ]
        test(text: text, equalTo: elements)
    }
    
    func testMarkdownEmphasizeAndStrong() {
        let text = "<title>*Hello world !*</title><body>**This is a body**</body>"
        let elements = [
            Element(openTag: "title:em", content: "Hello world !", closeTag: "title:em"),
            Element(openTag: "title", content: "", closeTag: "title"),
            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
            Element(openTag: "body", content: "", closeTag: "body"),
            ]
        test(text: text, equalTo: elements)
    }

    func testMarkdownOutside() {
        let text = "<title>Hello world !</title>*LOL*<body>**This is a body**</body>"
        let elements = [
            Element(openTag: "title", content: "Hello world !", closeTag: "title"),
            Element(openTag: ":em", content:"LOL", closeTag: ":em"),
            Element(openTag: "body:st", content: "This is a body", closeTag: "body:st"),
            Element(openTag: "body", content: "", closeTag: "body"),
            ]
        test(text: text, equalTo: elements)
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}

Tests.defaultTestSuite.run()
