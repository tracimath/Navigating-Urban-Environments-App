//
//  WebViewController.swift
//  Created by Traci Mathieu on 7/17/18.
//

import Foundation
import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate {

    var switchView = UIButton()
    var webView = WKWebView()
    var stackView = UIStackView()
    
    override func loadView() {
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackView.axis = .vertical
        // stackView.addArrangedSubview(webView)
        stackView.addArrangedSubview(switchView)
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        view.addConstraint(NSLayoutConstraint(item: stackView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: stackView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: stackView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0))
        
        let url = URL(string: "http://must.princeton.edu/Support.html")
        webView.load(URLRequest(url: url!))
        
        switchView.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        webView.uiDelegate = self
    }
    
    @objc func tapButton(_ sender: UIButton) {
        
        switch sender {
        case switchView:
            // switch back to the AR view
            self.dismiss(animated: true, completion: nil)
            print("switch to AR view")
        default:
            print("")
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated. 
    }
    
}
