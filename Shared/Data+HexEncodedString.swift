//
//  Data+HexEncodedString.swift
//  Smart Card Utility iOS
//
//  Created by Timothy Perfitt on 4/21/21.
//  Copyright © 2021 Twocanoes Software. All rights reserved.
//

import Foundation
extension Data {
    func date() -> Date? {
        guard self.count==8, self[7]==("Z" as Character).asciiValue else {
            return nil
        }

        let stringDate = self[0..<self.count-2].map { (a) -> String in
            String(format: "%02hhi", a)
        }.joined()+"Z"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMddHHmmZ"


        return formatter.date(from: stringDate)
    }

    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
extension Data {
    init?(hexString: String) {
        let strippedString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let length = strippedString.count / 2
        var data = Data(capacity: length)
        for i in 0 ..< length {
            let j = strippedString.index(strippedString.startIndex, offsetBy: i * 2)
            let k = strippedString.index(j, offsetBy: 2)
            let bytes = strippedString[j..<k]
            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
