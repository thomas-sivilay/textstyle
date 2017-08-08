//: A UIKit based Playground to present user interface

import UIKit
import PlaygroundSupport

struct Style: Decodable {
    let name: String?
    let size: CGFloat
    let color: UIColor
    let alignment: NSTextAlignment
    let kern: CGFloat
    let lineHeightMultiple: CGFloat
    let paragraphSpacing: CGFloat
    let numberOfLines: Int
    
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
                     numberOfLines: numberOfLines ?? 1)
        return
    }
    
    init(name: String? = nil,
         size: CGFloat = 13.0,
         color: UIColor = .black,
         alignment: NSTextAlignment = .natural,
         kern: CGFloat = 0.0,
         lineHeightMultiple: CGFloat = 0.0,
         paragraphSpacing: CGFloat = 0.0,
         numberOfLines: Int = 1
    ) {
        self.name = name
        self.size = size
        self.color = color
        self.alignment = alignment
        self.kern = kern
        self.lineHeightMultiple = lineHeightMultiple
        self.paragraphSpacing = paragraphSpacing
        self.numberOfLines = numberOfLines
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
    
    private struct Element {
        var openTag: String
        var content: String
        var closeTag: String
    }
    
    private func makeAttributedString(for text: String, with theme: Theme) -> NSAttributedString {
        var elements = parse(text: text)
        var richText = [(String, Style)]()

        var aText = NSMutableAttributedString()
        
        elements.forEach { element in
            if (element.openTag == element.closeTag) {
                let style = theme.styles[element.openTag]!
                richText.append((element.content, style))
            } else {
                // error
            }
        }
        
        richText.forEach {
            aText.append(makeAttributedString(for: $0.0, with: $0.1))
        }
        
        return aText
    }
    
    private func parse(text: String) -> [Element] {
        var offset = 0
        var string = ""
        var step = Step.unknown
        var element = Element(openTag: "", content: "", closeTag: "")
        var elements = [Element]()
        
        while offset < text.characters.count {
            let character = text.characters[text.characters.index(text.characters.startIndex, offsetBy: offset)]
            
            switch String(character) {
            case "\\":
                offset += 1
                string += String(text.characters[text.characters.index(text.characters.startIndex, offsetBy: offset)])
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
                        elements.append(element)
                        element = Element(openTag: "", content: "", closeTag: "")
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
    
    private func makeAttributedString(for text: String, with style: Style) -> NSAttributedString {
        let attributes = makeAttributes(for: style)
        print(text)
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    private func makeAttributes(for style: Style) -> [NSAttributedStringKey: Any] {
        var attributes = [NSAttributedStringKey: Any]()
        attributes[NSAttributedStringKey.foregroundColor] = style.color
        attributes[NSAttributedStringKey.font] = UIFont.systemFont(ofSize: style.size)
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
"textStyle1": { "text": "Hello World!, "style": "title" },
"textStyle2": { "text": "Welcome to my new framework", "style": "body" },
"textStyle3": { "text": "Backend driven style but layout is done on app side", "style": { "size": 14.0, "color": "green"} },
"textStyle4": "<title>Hey!</title><body>Not</body><title>LOL</title>"
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
