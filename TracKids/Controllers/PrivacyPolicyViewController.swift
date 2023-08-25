//
//  PrivacyPolicyViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 13/10/2022.
//

import UIKit
import WebKit
class PrivacyPolicyViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        showWebviewContent()
    }

    func showWebviewContent() {
        if let filePath = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "html") {
            let request = NSURLRequest(url: filePath)
            webView.load(request as URLRequest)
            print("privacy url is \(filePath.absoluteString)")
        }
    }
}
