//
//  ChangePINController.swift
//  WalletSDKDemo
//
//  Created by Vincent Huang on 2019/1/4.
//  Copyright © 2019 Cybavo. All rights reserved.
//

import UIKit
import CYBAVOWallet

class ChangePINController : UIViewController {
    @IBOutlet weak var currentCode: UITextField! 
    @IBOutlet weak var newCode: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        [currentCode, newCode].forEach{ textField in
            textField?.addDoneCancelToolbar()
            textField?.setBottomBorder()
            textField?.delegate = self
        }
        
    }
    @IBAction func onSubmit(_ sender: Any) {
        guard let newPinCode = newCode.text, let currentPinCode = currentCode.text else {
            return
        }
        Auth.shared.changePinCode(newPinCode: newPinCode, currentPinCode: currentPinCode) { result in
            switch result {
            case .success(_):
                let successAlert = UIAlertController(title: "Change pin successed", message: nil, preferredStyle: .alert)
                successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(successAlert, animated: true)
                
                print("changePinCode successed \(result)")
                break
            case .failure(let error):
                let successAlert = UIAlertController(title: "Change pin failed", message: nil, preferredStyle: .alert)
                successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(successAlert, animated: true)
                
                print("changePinCode failed \(error)")
            }
        }
    }
}

extension ChangePINController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard
            let current = currentCode.text, !current.isEmpty,
            let new = newCode.text, !new.isEmpty
            else {
                sendButton.isUserInteractionEnabled = false
                return true
        }
        sendButton.isUserInteractionEnabled = true
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
