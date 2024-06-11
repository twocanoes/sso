//
//  AuthenticationViewController.swift
//  ssoe-ios
//
//  Created by Timothy Perfitt on 4/5/24.
//

import UIKit
import AuthenticationServices
import WebKit

class AuthenticationViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    var url:URL?
    var authorizationRequest: ASAuthorizationProviderExtensionAuthorizationRequest?

    override func viewDidLoad() {

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupWebViewAndDelegate()
    }

    override var nibName: String? {
        return "AuthenticationViewController"
    }
}



