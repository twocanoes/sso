//
//  AuthenticationViewController.swift
//  ssoe
//
//  Created by Timothy Perfitt on 3/25/24.
//

import Cocoa
import AuthenticationServices
import WebKit
import CryptoKit
class AuthenticationViewController2: NSViewController {

    var url:URL?
    var authorizationRequest: ASAuthorizationProviderExtensionAuthorizationRequest?

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        if let path = Bundle.main.path(forResource: "defaults", ofType: "plist"){
            let defaultsInfoPlist = NSDictionary(contentsOfFile: path)
            UserDefaults.standard.register(defaults: defaultsInfoPlist as! [String : Any])
        }

    }
    override func viewDidAppear() {
        super.viewDidAppear()
        setupWebViewAndDelegate()

        view.window?.setContentSize(NSMakeSize(600, 600))

    }
    override var nibName: NSNib.Name? {
        return NSNib.Name("AuthenticationViewController")
    }
}
