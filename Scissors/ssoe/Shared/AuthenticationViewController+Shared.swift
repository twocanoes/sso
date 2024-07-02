//
//  AuthenticationViewController+Shared.swift
//  Scissors
//
//  Created by Timothy Perfitt on 4/4/24.
//

import Foundation
import AuthenticationServices
import WebKit

protocol WebViewSSOProtocol {
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!)
}

protocol ExtensionAuthorizationRequestProtocol {
    func process(_ request:ASAuthorizationProviderExtensionAuthorizationRequest)
}

extension AuthenticationViewController:WKNavigationDelegate, WebViewSSOProtocol {

    @IBAction func cancelButtonPressed(_ sender: Any) {

//        self.authorizationRequest?.doNotHandle()

//        UIApplication().open(URL(string: "scissors://")!)
//        let content = UNMutableNotificationContent()
//
//        content.title="Open Camera"
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//
//        // add our notification request
//        UNUserNotificationCenter.current().add(request)


    }

    func setupWebViewAndDelegate() {
        if let url = url {
            webView.navigationDelegate=self
            var request = URLRequest(url: url)
            let cookies = getCookies()

            if let cookies = cookies {
                request.setValue(combineCookies(cookies: cookies), forHTTPHeaderField: "Cookie")
            }
            request.httpShouldHandleCookies=true
            webView.load(request)
        }
    }

    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard let url = url,
              let webViewURL = webView.url,
        let callbackURLString = UserDefaults.standard.string(forKey: DefaultKeys.CallbackURLString.rawValue) else {
            return
        }

        if (webViewURL.absoluteString.starts(with: callbackURLString) == false) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({ cookies in
                let headers: [String:String] = [
                    "Location": webViewURL.absoluteString,
                    "Set-Cookie": combineCookies(cookies: cookies)
                ]
                storeCookies(cookies)
                if let response = HTTPURLResponse.init(url: url, statusCode: 302, httpVersion: nil, headerFields: headers) {
                    self.authorizationRequest?.complete(httpResponse: response, httpBody: nil)
                }
            })
        }

    }
}
extension AuthenticationViewController:ExtensionAuthorizationRequestProtocol {

    func process(_ request:ASAuthorizationProviderExtensionAuthorizationRequest){
        url=request.url
        request.presentAuthorizationViewController(completion: { (success, error) in
            if error != nil {
                request.complete(error: error!)
            }
        })
    }
}
extension AuthenticationViewController: ASAuthorizationProviderExtensionAuthorizationRequestHandler {

    public func beginAuthorization(with request: ASAuthorizationProviderExtensionAuthorizationRequest) {
        self.authorizationRequest = request

//        request.doNotHandle()
        process(request)
    }
}
