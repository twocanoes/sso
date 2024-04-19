//
//  AuthenticationViewController.swift
//  ssoe-ios
//
//  Created by Timothy Perfitt on 4/17/24.
//

import UIKit
import WebKit
import AuthenticationServices
class AuthenticationViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    var url:URL?
    var authorizationRequest: ASAuthorizationProviderExtensionAuthorizationRequest?

    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.authorizationRequest?.doNotHandle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupWebViewAndDelegate()
    }

    override var nibName: String? {
        return "AuthenticationViewController"
    }


}
