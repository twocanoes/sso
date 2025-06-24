import AuthenticationServices

let TEAM_ID = "QUR8QTGXNB"
let CONTAINER_BUNDLE_ID = "ch.argio.sso.container"
let EXTENSION_BUNDLE_ID = "ch.argio.sso.extension"
let DISPLAY_NAME = "Argio SSO"
let ISSUER = URL(string: "https://auth.argio.ch")!
let AUDIENCE = "macos"
let CLIENT_ID = "ch.argio.sso"

class AuthorizationProvider: NSObject, ASAuthorizationProviderExtensionAuthorizationRequestHandler {
    func beginAuthorization(with request: ASAuthorizationProviderExtensionAuthorizationRequest) {
        let configuration = ASAuthorizationProviderExtensionLoginConfiguration()
        configuration.issuer = ISSUER
        configuration.clientID = CLIENT_ID
        configuration.audience = AUDIENCE
        configuration.tokenEndpointURL = ISSUER.appendingPathComponent("application/o/token/")
        request.doNotHandle()
    }
}
