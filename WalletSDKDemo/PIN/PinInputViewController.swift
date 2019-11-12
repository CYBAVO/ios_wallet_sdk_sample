//
//  PinInputViewController.swift
//  WalletSDKDemo
//
//  Created by evahsu on 2019/9/28.
//  Copyright © 2019 Cybavo. All rights reserved.
//

import UIKit
import CYBAVOWallet
class PinInputViewController: UIViewController{
    var callback: ((_ pinSecret: PinSecret) -> ())?
    var titleText: String = "Input PIN code"
    var hideForgot = false

    @IBOutlet weak var forgotButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    //MARK: Property
    var pinInputView: PinInputView!
    let kPasswordDigit = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = titleText
        forgotButton.isHidden = hideForgot
        pinInputView = PinInputView.create(in: stackView, digit: kPasswordDigit)
        pinInputView.setOnPinInputListener(delegate: self)
        let lightGray = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
        let darkGray = UIColor(red: 59.0/255.0, green: 59.0/255.0, blue: 58.0/255.0, alpha: 1.0)
        
        pinInputView.styleAttr = StyleAttr(
            fixedOrder: false,
            buttonWidth: 70,
            buttonHeight: 70,
            buttonTextColor: darkGray,
            buttonTextColorPressed: lightGray,
            buttonBackgroundColor: lightGray,
            buttonBackgroundColorPressed: darkGray,
            buttonBorderRadius: 72,
            buttonBorderWidth: 0,
            buttonBorderColor: UIColor.red,
            buttonBorderColorPressed: UIColor.blue,
            backspaceButtonWidth: 70,
            backspaceButtonHeight: 70,
            backspaceButtonTextFont: nil,
            backspaceButtonTextColor: darkGray,
            backspaceButtonTextColorPressed: lightGray,
            backspaceButtonBackgroundColor: lightGray,
            backspaceButtonBackgroundColorPressed: darkGray,
            backspaceButtonBorderRadius: 72,
            backspaceButtonBorderWidth: 0,
            backspaceButtonBorderColor: UIColor.blue,
            backspaceButtonBorderColorPressed: UIColor.red,
            indicatorStrokeColor: darkGray,
            indicatorFillColor: lightGray,
            indicatorHeight: 17,
            UnfilledPlaceholder: "-",
            filledPlaceholder: "*",
            backspaceButtonText: "⌫")
//        pinInputView.deleteButtonLocalizedTitle = "⌫"
        
    }
    @IBAction func onCancle(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func onForgotClick(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        let storyboard = UIStoryboard(name: "PIN", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "idForgotPINController") as! RestorePINController
        self.present(vc, animated: false)
        
        
    }
}

extension PinInputViewController: OnPinInputListener {
    func onChanged(length: Int) {
        if(length == pinInputView.getMaxLength()){
            var pinSecret = pinInputView.submit()
            callback?(pinSecret)
            dismiss(animated: true, completion: nil)
        }
    }
}

