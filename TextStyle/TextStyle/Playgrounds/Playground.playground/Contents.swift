//: A UIKit based Playground to present user interface
  
import UIKit
import PlaygroundSupport

class myViewController : UIViewController {

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 30))
        label.text = "Hello World!"
        label.textColor = .black
        
        view.addSubview(label)
        self.view = view
    }
   
}

PlaygroundPage.current.liveView = myViewController()
