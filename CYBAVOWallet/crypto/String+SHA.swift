//
//  sha.swift
//  CYBAVOWallet
//
//  Created by Vincent Huang on 2018/12/19.
//  Copyright © 2018 Cybavo. All rights reserved.
//

import Foundation
import CryptoSwift

extension String {
    func sha256(times: Int = 1) -> String {
        var result = self
        for _ in 1...times {
            result = Data(bytes: result.bytes).sha256().toHexString()
        }
        return result
    }
}
