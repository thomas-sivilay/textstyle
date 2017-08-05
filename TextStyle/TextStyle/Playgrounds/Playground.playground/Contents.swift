//: A UIKit based Playground to present user interface
  
import UIKit
import PlaygroundSupport

struct Style: Decodable {
    let size: CGFloat
    let color: UIColor
    let alignment: NSTextAlignment
    let kern: CGFloat
    let lineHeightMultiple: CGFloat
    let paragraphSpacing: CGFloat
    let numberOfLines: Int
    
    private enum CodingKeys: String, CodingKey {
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
        let size = try values.decodeIfPresent(CGFloat.self, forKey: .size)
        let colorString = try values.decodeIfPresent(String.self, forKey: .color)
        let alignmentString = try values.decodeIfPresent(String.self, forKey: .alignment)
        let kern = try values.decodeIfPresent(CGFloat.self, forKey: .kern)
        let lineHeightMultiple = try values.decodeIfPresent(CGFloat.self, forKey: .lineHeightMultiple)
        let paragraphSpacing = try values.decodeIfPresent(CGFloat.self, forKey: .paragraphSpacing)
        let numberOfLines = try values.decodeIfPresent(Int.self, forKey: .numberOfLines)
        
        let color = ColorAdapter.uiColor(from: colorString) ?? .black
        let alignment = AlignmentAdapter.nsTextAlignment(from: alignmentString) ?? .natural
        
        self = .init(size: size ?? 13.0,
                     color: color,
                     alignment: alignment,
                     kern: kern ?? 0.0,
                     lineHeightMultiple: lineHeightMultiple ?? 0.0,
                     paragraphSpacing: paragraphSpacing ?? 0.0,
                     numberOfLines: numberOfLines ?? 1)
        return
    }
    
    init(size: CGFloat = 13.0,
         color: UIColor = .black,
         alignment: NSTextAlignment = .natural,
         kern: CGFloat = 0.0,
         lineHeightMultiple: CGFloat = 0.0,
         paragraphSpacing: CGFloat = 0.0,
         numberOfLines: Int = 1
    ) {
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

struct TextStyle: Decodable {
    let text: String
    let style: Style
}

extension UILabel {
    func setTextStyle(_ textStyle: TextStyle) {
        self.attributedText = makeAttributedString(for: textStyle)
        self.numberOfLines = textStyle.style.numberOfLines
    }
    
    private func makeAttributedString(for textStyle: TextStyle) -> NSAttributedString {
        let attributes = makeAttributes(for: textStyle.style)
        return NSAttributedString(string: textStyle.text, attributes: attributes)
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

let viewControllerJSON = """
{
"textStyle1": { "text": "Hello World!", "style": { "size": 26.0, "color": "black", "alignment": "center"} },
"textStyle2": { "text": "Welcome to my new framework", "style": { "size": 13.0 } },
"textStyle3": { "text": "Backend driven style but layout is done on app side", "style": { "size": 14.0, "color": "green"} }
}
""".data(using: .utf8)!

final class myViewController : UIViewController {
    
    private struct myViewControllerData: Decodable {
        let textStyle1: TextStyle
        let textStyle2: TextStyle
        let textStyle3: TextStyle
    }
    
    let s1 = Style(size: 16.0,
                   color: .red,
                   alignment: .left,
                   kern: 1.0,
                   numberOfLines: 0)
    
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
    
    private var data = myViewControllerData(textStyle1: TextStyle(text: "", style: Style()),
                                            textStyle2: TextStyle(text: "", style: Style()),
                                            textStyle3: TextStyle(text: "", style: Style()))
        {
        didSet {
            label1.setTextStyle(data.textStyle1)
            label2.setTextStyle(data.textStyle2)
            label3.setTextStyle(data.textStyle3)
        }
    }
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        
        [label1, label2, label3].forEach {
            view.addSubview($0)
        }
        
        loadData()
        
        self.view = view
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        do {
            data = try decoder.decode(myViewControllerData.self, from: viewControllerJSON)
        } catch {
            print(error)
        }
    }
}

PlaygroundPage.current.liveView = myViewController()
