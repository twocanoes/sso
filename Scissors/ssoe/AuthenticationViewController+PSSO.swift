//
//  AuthenticationViewController+PSSO.swift
//  Scissors
//
//  Created by Timothy Perfitt on 5/20/24.
//

import AuthenticationServices
import CryptoKit

//
//extension AuthenticationViewController: ASAuthorizationProviderExtensionAuthorizationRequestHandler {
//
//    public func beginAuthorization(with request: ASAuthorizationProviderExtensionAuthorizationRequest) {
//        self.authorizationRequest = request
//        process(request)
//    }
//}
//
extension AuthenticationViewController: ASAuthorizationProviderExtensionRegistrationHandler {

    enum PSSORegistrationResult: String {
        case cancel, success, resetUserKeys, resetDeviceKeys
    }

    enum KeyOperation {
        case Signing
        case KeyAgreement
    }

    struct PSSORegistration: Codable {
        let deviceUUID: String
        let deviceSigningKey: String
        let deviceEncryptionKey: String
        let signKeyID: String
        let encKeyID: String
//        let user: String

        enum CodingKeys: String, CodingKey {
            case deviceUUID = "DeviceUUID"
            case deviceSigningKey = "DeviceSigningKey"
            case deviceEncryptionKey = "DeviceEncryptionKey"
            case signKeyID = "SignKeyID"
            case encKeyID = "EncKeyID"
        }
    }


    func beginDeviceRegistration(loginManager: ASAuthorizationProviderExtensionLoginManager, options: ASAuthorizationProviderExtensionRequestOptions = [], completion: @escaping (ASAuthorizationProviderExtensionRegistrationResult) -> Void) {

        NSLog("LoginSSOE: Catching device registration request")

        if options.contains(.registrationRepair) {
            NSLog("LoginSSOE: Options: Requires Repair")
        }

        if options.contains(.userInteractionEnabled) {
            NSLog("LoginSSOE: userInteractionEnabled device configuration enabled")

            // get deviceSigningPublicKey
            guard let loginManagerDeviceSigningKey = loginManager.key(for: .userDeviceSigning), let deviceSigningPublicKey = publicKeyPEMFromPrivateKey(key: loginManagerDeviceSigningKey,keyOperation: .Signing) else {
                NSLog("LoginSSOE: Unable to get deviceSigningKey.")
                completion(.failed)
                return
            }

            // get deviceSigningPublicKeyHash
            guard let deviceSigningPublicKeyHash = base64EncodedSHA256PublicKeyHash(loginManagerDeviceSigningKey) else {
                NSLog("LoginSSOE: Unable to get loginManagerDeviceSigningKey .")
                completion(.failed)
                return
            }

            // get deviceEncryptionPublicKey
            guard let loginManagerDeviceEncryptionKey = loginManager.key(for: .userDeviceEncryption), let deviceEncryptionPublicKey = publicKeyPEMFromPrivateKey(key: loginManagerDeviceEncryptionKey, keyOperation: .KeyAgreement) else {
                NSLog("LoginSSOE: Unable to get deviceEncKey.")
                completion(.failed)
                return
            }

            // get deviceEncryptionPublicKeyHash
            guard let deviceEncryptionPublicKeyHash = base64EncodedSHA256PublicKeyHash(loginManagerDeviceEncryptionKey) else {
                NSLog("LoginSSOE: Unable to get deviceEncKey hash.")
                completion(.failed)
                return
            }

            Task {
                //configure PSSO
                await self.setLoginConfig(loginManager: loginManager)

                //send the public keys and ids to the server
                try? await self.sendRegistration(body: PSSORegistration(deviceUUID: self.getSystemUUID() ?? "unknown", deviceSigningKey: deviceSigningPublicKey, deviceEncryptionKey: deviceEncryptionPublicKey, signKeyID: deviceSigningPublicKeyHash, encKeyID: deviceEncryptionPublicKeyHash))
                completion(.success)
            }
        } else {
            completion(.userInterfaceRequired)
        }
    }

    func beginUserRegistration(loginManager: ASAuthorizationProviderExtensionLoginManager, userName: String?, method authenticationMethod: ASAuthorizationProviderExtensionAuthenticationMethod, options: ASAuthorizationProviderExtensionRequestOptions = [], completion: @escaping (ASAuthorizationProviderExtensionRegistrationResult) -> Void) {
        NSLog("LoginSSOE: beginUserRegistration")

        if options.contains(.registrationRepair) {
            NSLog("LoginSSOE: Options: beginUserRegistration Requires Repair")
        }

        do {
            let defaultsUsername = UserDefaults.standard.string(forKey: DefaultKeys.Username.rawValue) ?? ""
            let user = userName ?? defaultsUsername

            let config = ASAuthorizationProviderExtensionUserLoginConfiguration(loginUserName: user )
            try loginManager.saveUserLoginConfiguration(config)
        } catch {
            NSLog("LoginSSOE: error saving user login config: \(error)")
            completion(.failed)
            return
        }

        completion(.success)
    }

    func registrationDidComplete() {
        NSLog("LoginSSOE: Registration completed")
    }

    func setLoginConfig(loginManager: ASAuthorizationProviderExtensionLoginManager) async {

        let urlPath = UserDefaults().string(forKey:DefaultKeys.PSSOUrlPathString.rawValue ) ?? ""
        let tokenEndpoint = UserDefaults().string(forKey:DefaultKeys.TokenEndpoint.rawValue ) ?? "tokenEndpoint"
        let jwksEndpoint = UserDefaults().string(forKey:DefaultKeys.JwksEndpoint.rawValue ) ?? ".well-known/jwks.json"
        let nonceEndpont = UserDefaults().string(forKey:DefaultKeys.NonceEndpoint.rawValue ) ?? "nonce"
        if let tokenEndpoint = URL(string: urlPath + tokenEndpoint),
           let jwksEndpoint = URL(string: urlPath + jwksEndpoint),
           let nonceEndpoint = URL(string: urlPath + nonceEndpont) {
            do {
                let config = ASAuthorizationProviderExtensionLoginConfiguration(clientID: "psso", issuer: urlPath, tokenEndpointURL: tokenEndpoint, jwksEndpointURL: jwksEndpoint, audience: "idp.twocanoes.com")
                config.nonceEndpointURL = nonceEndpoint
                    config.keyEndpointURL = tokenEndpoint

                try loginManager.saveLoginConfiguration(config)
            } catch {
                NSLog("LoginSSOE: error saving config: \(error)")
            }
        } else {
            NSLog("LoginSSOE: Unable to make URLs :(")
        }
    }

    func supportedGrantTypes() -> ASAuthorizationProviderExtensionSupportedGrantTypes {
        NSLog("LoginSSOE: checking grant types")

        //tell PSSO that our service supports password grant type
        let types:ASAuthorizationProviderExtensionSupportedGrantTypes = .password
//        types.insert(.jwtBearer)  //smart card,
//        types.insert(.saml1_1)  // WSTrust
//        types.insert(.saml2_0) // WSTrust (dynamic?)

        return types
    }

    //we support version 2 so let PSSO know
    func protocolVersion() -> ASAuthorizationProviderExtensionPlatformSSOProtocolVersion {
        NSLog("LoginSSOE: checking protocol version")
        return .version2_0
    }

    //sen registration to our service.
    private func sendRegistration(body: PSSORegistration) async throws {
        NSLog("LoginSSOE sendRegistration")

        let encoder = JSONEncoder()

        if  let urlPath = UserDefaults().string(forKey:DefaultKeys.PSSOUrlPathString.rawValue ) ,
                let registrationEndpoint = UserDefaults().string(forKey:DefaultKeys.RegistrationEndpoint.rawValue ),
            let registrationURL = URL(string: urlPath + registrationEndpoint),
            let data = try? encoder.encode(body){

            var request = URLRequest(url: registrationURL)
            request.httpMethod = "POST"
            NSLog("LoginSSOE POSTING sendRegistration")

            let (_, _) = try await URLSession.shared.upload(
                for: request,
                from: data
            )

        }
    }

    public func getSystemUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        guard let rawUUID = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        else { return nil }
        let uuid = rawUUID.takeUnretainedValue()
        if let result = uuid as? String {
            return result
        }
        return nil
    }
    private func publicKeyPEMFromPrivateKey(key: SecKey, keyOperation:KeyOperation) -> String? {

        var err: Unmanaged<CFError>?
        guard let publicKey = SecKeyCopyPublicKey(key) else {
            NSLog("LoginSSOE: Unable to get publicKey.")
            return nil
        }
        guard  let pubKeyData = SecKeyCopyExternalRepresentation(publicKey, &err) as Data? else {
            NSLog("LoginSSOE: error in SecKeyCopyExternalRepresentation.")
            return nil

        }
        switch keyOperation {
        case .KeyAgreement:
            guard let newKey = try? P256.KeyAgreement.PublicKey(x963Representation: pubKeyData) else {
                return nil
            }
            return newKey.pemRepresentation

        case .Signing:
            guard let newKey = try? P256.Signing.PublicKey(x963Representation: pubKeyData) else {
                return nil
            }
            return newKey.pemRepresentation

        }
    }

    private func base64EncodedSHA256PublicKeyHash(_ key:SecKey) -> String?{
        var err: Unmanaged<CFError>?

        guard let publicKey = SecKeyCopyPublicKey(key) else {
            NSLog("LoginSSOE: Unable to get publicKey.")
            return nil
        }
        guard let pubKeyData  = SecKeyCopyExternalRepresentation(publicKey, &err) as Data? else {
            NSLog("LoginSSOE: Unable to SecKeyCopyExternalRepresentation.")

            return nil
        }
        let hash = SHA256.hash(data: pubKeyData)
        
        return Data(hash).base64EncodedString()

    }
}

