//: A UIKit based Playground to present user interface
  
import UIKit
import PlaygroundSupport

struct Style {
    let size: CGFloat
    let color: UIColor
    let alignment: NSTextAlignment
    let kern: CGFloat
    let lineHeightMultiple: CGFloat
    let paragraphSpacing: CGFloat
    let numberOfLines: Int
    
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

struct TextStyle {
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

class myViewController : UIViewController {
    
    let s1 = Style(size: 16.0,
                   color: .red,
                   alignment: .left,
                   kern: 1.0,
                   numberOfLines: 0)
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        
        let t1 = TextStyle(text: "Hello World! This is an exemple of textstyle using a lot of different attributes.", style: s1)
        label.setTextStyle(t1)
        
        view.addSubview(label)
        
        self.view = view
    }
}

PlaygroundPage.current.liveView = myViewController()
