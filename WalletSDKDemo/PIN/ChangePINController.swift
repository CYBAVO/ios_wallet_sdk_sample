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
    var currentPinSecret : PinSecret?
    var newPinSecret : PinSecret?
    
    @IBOutlet weak var currentCode: UITextField! 
    @IBOutlet weak var newCode: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    func refreshSubmitButton(){
        guard
                let current = currentCode.text, !current.isEmpty,
                let new = newCode.text, !new.isEmpty
                else {
            sendButton.isUserInteractionEnabled = false
            return
        }
        sendButton.isUserInteractionEnabled = true
    }
    override func viewDidLoad() {
        [currentCode, newCode].forEach{ textField in
//            textField?.addDoneCancelToolbar()
//            textField?.setBottomBorder()
            textField?.delegate = self
        }
        sendButton.isUserInteractionEnabled = false
    }
    @IBAction func onSubmit(_ sender: Any) {
        guard let newPinCode = newCode.text, let currentPinCode = currentCode.text, let newPinSecret = self.newPinSecret, let currentPinSecret = self.currentPinSecret else {
            return
        }
        if currentPinCode.count != PINCODE_LENGTH {
            let successAlert = UIAlertController(title: "Current PIN code length must be \(PINCODE_LENGTH)", message: nil, preferredStyle: .alert)
            successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                self.currentCode.text = ""
                self.currentCode.becomeFirstResponder()
            }))
            self.present(successAlert, animated: true)
        }
        if newPinCode.count != PINCODE_LENGTH {
            let successAlert = UIAlertController(title: "New pin code length must be \(PINCODE_LENGTH)", message: nil, preferredStyle: .alert)
            successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                self.newCode.text = ""
                self.newCode.becomeFirstResponder()
            }))
            self.present(successAlert, animated: true)
        };
        Auth.shared.changePinCode(newPinSecret: newPinSecret, currentPinSecret: currentPinSecret) { result in
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
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        let pinInput = PinInputViewController(nibName: "PinInputViewController", bundle: nil)
        pinInput.callback = { pinSecret in
            textField.text = "******"
            if(textField == self.currentCode){
                self.currentPinSecret = pinSecret
            }else{
                self.newPinSecret = pinSecret
            }
            
            self.refreshSubmitButton()
        }
        pinInput.hideForgot = textField == self.newCode
        pinInput.titleText = "Enter \(textField.placeholder!)"
        present(pinInput, animated: true, completion: nil)
        return false
    }
}
