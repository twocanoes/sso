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
extension AuthenticationViewController:WebViewSSOProtocol, WKNavigationDelegate {

    func setupWebViewAndDelegate() {
        if let url = url {
            webView.navigationDelegate=self
            var request = URLRequest(url: url)
            let cookies = cookiesFromKeychain()

            if let cookies = cookies {
                request.setValue(cookieHeaderString(from: cookies), forHTTPHeaderField: "Cookie")
            }
            request.httpShouldHandleCookies=true
            webView.load(request)
        }
    }

    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard let url = url, let webViewURL = webView.url else {

            return
        }
        if let authorizationRequestHost = authorizationRequest?.url.host, webViewURL.host() != authorizationRequestHost {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({ cookies in
                let headers: [String:String] = [
                    "Location": webViewURL.absoluteString,
                    "Set-Cookie": cookieHeaderString(from: cookies)
                ]
                let _ = storeCookiesInKeychain(cookies)
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

        process(request)
    }
}


