//
//  ForgotPINController.swift
//  WalletSDKDemo
//
//  Created by Vincent Huang on 2019/1/4.
//  Copyright © 2019 Cybavo. All rights reserved.
//

import UIKit
import CYBAVOWallet

class RestorePINController : InputPINUI {
    @IBOutlet weak var question1: UILabel!
    @IBOutlet weak var question2: UILabel!
    @IBOutlet weak var question3: UILabel!
    @IBOutlet weak var answer1: UITextField!
    @IBOutlet weak var answer2: UITextField!
    @IBOutlet weak var answer3: UITextField!
    
    var challenges: [BackupChallenge]?
    
    override func viewDidLoad() {
        [answer1, answer2, answer3].forEach{ textField in
            textField?.delegate = self
            textField?.setBottomBorder()
        }
       
        answer1.delegate = self
        answer2.delegate = self
        answer3.delegate = self
            
        Auth.shared.getRestoreQuestions { result in
            switch result {
            case .success(let result):
                print("getRestoreQuestions \(result)")
                let questions = [self.question1, self.question2, self.question3]
                for (index, element) in result.questions.enumerated() {
                    if let q = questions[safe: index] {
                        q?.text = element
                    }
                }
                break
            case .failure(let error):
                print("getRestoreQuestions \(error)")
                let failAlert = UIAlertController(title: "Unable to get questions", message: error.name, preferredStyle: .alert)
                failAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(failAlert, animated: true)
                break
            }
        }
    }
    
    @IBAction func onNext(_ sender: Any) {
        guard let a1 = answer1.text, let a2 = answer2.text, let a3 = answer3.text else {
            return
        }
        
        do {
            let c1 = try BackupChallenge(question: question1.text!, answer: a1)
            let c2 = try BackupChallenge(question: question2.text!, answer: a2)
            let c3 = try BackupChallenge(question: question3.text!, answer: a3)
            
            Auth.shared.verifyRestoreQuestions(challenge1: c1, challenge2: c2, challenge3: c3) { result in
                switch result {
                case .success(_):
                    self.challenges = [c1, c2, c3]
                    print("verifyRestoreQuestions \(result)")
                    self.performSegue(withIdentifier: "idInputPINCode", sender: self);
                    break
                case .failure(let error):
                    print("verifyRestoreQuestions \(error)")
                    let failAlert = UIAlertController(title: "Verify failed", message: error.name, preferredStyle: .alert)
                    failAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(failAlert, animated: true)
                    break
                }
            }
        } catch {
            //handle invalid challenge case
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "idInputPINCode" else {
            return
        }
        if var ui = segue.destination as? PinCodeInputUI {
            ui.delegate = self
        }
    }
}

extension RestorePINController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

extension RestorePINController : PinCodeDelegate {
    func onPin(code: String) {
        guard let challenges = challenges, challenges.count == 3 else {
            return
        }
        Auth.shared.restorePinCode(pinCode: code, challenge1: challenges[0], challenge2: challenges[1], challenge3: challenges[2]) { result in
            switch result {
            case .success(_):
                print("restorePinCode \(result)")
                self.onSetPINSuccessed()
                break
            case .failure(let error):
                print("restorePinCode \(error)")
                self.onSetPINFailed(error: error)
            }
        }
    }
}
