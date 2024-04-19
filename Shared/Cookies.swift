//
//  Cookies.swift
//

import Foundation

let kService = "Cookie Cache"

func cookieHeaderString(from cookieArray: [HTTPCookie]) -> String {
    let dateFormatter = ISO8601DateFormatter.init()
    var cookieStringArray = [String]()
    var cookieString = [String]()

    for httpCookie in cookieArray {
        for (key,value) in 
                [httpCookie.name:httpCookie.value,
                 "domain":httpCookie.domain,
                 "path":httpCookie.path,
                 "expires":dateFormatter.string(from:httpCookie.expiresDate ?? Date()),
                 "SameSite":httpCookie.sameSitePolicy?.rawValue ?? ""]
        {
            cookieString.append("\(key)=\(value)")
        }

        for (key,value) in
                ["secure":httpCookie.isSecure,
                "httponly":httpCookie.isHTTPOnly]
        {
            if value==true {
                cookieString.append(key)
            }
        }
        cookieStringArray.append(cookieString.joined(separator: "; "))
    }
    return cookieStringArray.joined(separator: ", ")
}


func storeCookiesInKeychain(_ cookies: [HTTPCookie] ) -> Bool  {
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false)

        let attributes = [kSecClass: kSecClassGenericPassword,
                    kSecAttrService: kService,
      kSecUseDataProtectionKeychain: false,
                      kSecValueData: data] as [String: Any]
        _ = SecItemDelete(attributes as CFDictionary)
        if SecItemAdd(attributes as CFDictionary, nil) == noErr {
            return true
        }
        print("error cookies to keychain")

    }
    catch {
        print(error.localizedDescription)
    }
    return false
}

func cookiesFromKeychain() -> [HTTPCookie]? {
    let attributes = [kSecClass: kSecClassGenericPassword,
                kSecAttrService: kService,
           kSecReturnAttributes: true,
  kSecUseDataProtectionKeychain: false,
                 kSecReturnData: true] as [String: Any]
    var item: CFTypeRef?
    if  SecItemCopyMatching(attributes as CFDictionary, &item) == 0,
        let result = item as? [String:AnyObject],
        let cookiesRaw = result[kSecValueData as String] as? Data,
        let cookies = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(cookiesRaw) as? [HTTPCookie],
        cookies.count>0 {
        return cookies
    }
    return nil
}

