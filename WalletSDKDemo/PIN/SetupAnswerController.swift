//
//  SetupAnswerController.swift
//  WalletSDKDemo
//
//  Created by Vincent Huang on 2019/1/4.
//  Copyright © 2019 Cybavo. All rights reserved.
//

import UIKit
import CYBAVOWallet

protocol BackupChallengeDelegate: class {
    func onChallenges(_ challenges: [BackupChallenge])
}

protocol BackupChallengeInputUI {
    var delegate: BackupChallengeDelegate? {get set}
}

let questions = [
    "What was your childhood nickname?",
    "What is the name of your favorite childhood friend?",
    "In what city or town did your mother and father meet?",
    "What is the middle name of your oldest child?",
    "What is your favorite team?",
    "What is your favorite movie?",
    "What was your favorite sport in high school?",
    "What was your favorite food as a child?",
    "What is the first name of the boy or girl that you first kissed?",
    "What was the make and model of your first car?",
    "What was the name of the hospital where you were born?",
    "Who is your childhood sports hero?",
    "What school did you attend for sixth grade?",
    "What was the last name of your third grade teacher?",
    "In what town was your first job?",
    "What was the name of the company where you had your first job?"
]

class SetupAnswerController : UIViewController, BackupChallengeInputUI {
    @IBOutlet weak var question1: UIPickerView!
    @IBOutlet weak var question2: UIPickerView!
    @IBOutlet weak var question3: UIPickerView!
    @IBOutlet weak var answer1: UITextField!
    @IBOutlet weak var answer2: UITextField!
    @IBOutlet weak var answer3: UITextField!
    
    //var pinCode: String?
    //var recoveryCode: String?
    var delegate: BackupChallengeDelegate?
    
    override func viewDidAppear(_ animated: Bool) {
        question1.dataSource = self
        question2.dataSource = self
        question3.dataSource = self
        question1.delegate = self
        question2.delegate = self
        question3.delegate = self
        question1.selectRow(0, inComponent: 0, animated: false)
        question2.selectRow(1, inComponent: 0, animated: false)
        question3.selectRow(2, inComponent: 0, animated: false)
        
        answer1.delegate = self
        answer2.delegate = self
        answer3.delegate = self
        
        answer1.becomeFirstResponder()
    }
    
    @IBAction func onNext(_ sender: Any) {
        guard let a1 = answer1.text, let a2 = answer2.text, let a3 = answer3.text else {
            return
        }
        
        do {
            let c1 = try BackupChallenge(question: questions[question1.selectedRow(inComponent: 0)], answer: a1)
            let c2 = try BackupChallenge(question: questions[question2.selectedRow(inComponent: 0)], answer: a2)
            let c3 = try BackupChallenge(question: questions[question3.selectedRow(inComponent: 0)], answer: a3)
            
            if let delegate = delegate {
                delegate.onChallenges([c1, c2, c3])
                return
            } 
        } catch {
          //handle invalid challenge case
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func onSetPINSuccessed(){
        let successAlert = UIAlertController(title: "Setup PIN successful", message: nil, preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(successAlert, animated: true)
    }
    func onSetPINFailed(error: ApiError){
        let failAlert = UIAlertController(title: "Setup PIN failed", message: error.description, preferredStyle: .alert)
        failAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(failAlert, animated: true)
    }
}

extension SetupAnswerController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return questions.count
    }
}

extension SetupAnswerController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return questions[row]
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(40)
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel
        
        if let view = view {
            label = view as! UILabel
        }
        else {
            label = UILabel(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 36))
        }
        
        label.text = questions[row]
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.sizeToFit()
        
        return label
    }
}

extension SetupAnswerController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
