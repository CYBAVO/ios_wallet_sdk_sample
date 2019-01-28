//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet

class InputPINUI : UIViewController {
    func onSetPINSuccessed(backNum: Int = 1, onOK: (()->Void)? = nil){
        let successAlert = UIAlertController(title: "Setup PIN successful", message: nil, preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
            if backNum >= 0 {
                NavigationHelper.back(backNum, from: self)
            }
            if let completion = onOK {
                completion()
            }
        }))
        self.present(successAlert, animated: true)
    }
    func onSetPINFailed(error: ApiError){
        let failAlert = UIAlertController(title: "Setup PIN failed", message: error.description, preferredStyle: .alert)
        failAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(failAlert, animated: true)
    }
}
