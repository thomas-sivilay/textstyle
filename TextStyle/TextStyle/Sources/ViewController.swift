//
//  ViewController.swift
//  TextStyle
//
//  Created by Thomas Sivilay on 8/4/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import UIKit
import Thot

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

final class ViewController : UIViewController {
    
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
    
    private var render: Renderer = Renderer()
    
    private var data = MyViewControllerData(textStyle1: TextStyle(text: "", style: Style.name("toto")),
                                            textStyle2: TextStyle(text: "", style: Style.name("toto")),
                                            textStyle3: TextStyle(text: "", style: Style.name("toto")),
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
