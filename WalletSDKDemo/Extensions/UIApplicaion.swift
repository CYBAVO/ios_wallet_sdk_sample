//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit

extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "default_endpoints") as? String
    }
}
