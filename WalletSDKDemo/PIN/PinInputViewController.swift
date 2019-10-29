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
    var pinInputIndecatorView: PinInputIndicatorView?
    //MARK: Property
    var pinInputView: NumericPinCodeInputView?
    let kPasswordDigit = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = titleText
        forgotButton.isHidden = hideForgot
        pinInputIndecatorView = PinInputIndicatorView(frame: CGRect(x: titleLabel.bounds.minX, y: titleLabel.bounds.minY + titleLabel.bounds.height + 10, width: 250, height: 35))
        
        
        pinInputView = NumericPinCodeInputView(frame: CGRect(x: pinInputIndecatorView!.bounds.minX, y: pinInputIndecatorView!.bounds.minY + pinInputIndecatorView!.bounds.height + 10, width: 250, height: 400))
        pinInputView?.setOnPinInputListener(delegate: self)
        let lightGray = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
        let darkGray = UIColor(red: 59.0/255.0, green: 59.0/255.0, blue: 58.0/255.0, alpha: 1.0)
  
        pinInputView?.styleAttr = CYBAVOWallet.StyleAttr(
            fixedOrder: false,
            disabled: false,
            buttonWidth: 70,
            buttonHeight: 70,
            horizontalSpacing: 5,
            verticalSpacing: 7,
            buttonTextColor: darkGray,
            buttonTextColorPressed: lightGray,
            buttonTextColorDisabled: UIColor.red,
            buttonBackgroundColor: lightGray,
            buttonBackgroundColorPressed: darkGray,
            buttonBackgroundColorDisabled: UIColor.yellow,
            buttonBorderRadius: 33,
            buttonBorderWidth: 0,
            buttonBorderColor: UIColor.green,
            buttonBorderColorPressed: UIColor.blue,
            buttonBorderColorDisabled: UIColor.orange,
            backspaceButtonWidth: 70,
            backspaceButtonHeight: 70,
            backspaceButtonTextColor: darkGray,
            backspaceButtonTextColorPressed: lightGray,
            backspaceButtonTextColorDisabled: UIColor.yellow,
            backspaceButtonBackgroundColor: lightGray,
            backspaceButtonBackgroundColorPressed: darkGray,
            backspaceButtonBackgroundColorDisabled: UIColor.red,
            backspaceButtonBorderRadius: 33,
            backspaceButtonBorderWidth: 0,
            backspaceButtonBorderColor: UIColor.blue,
            backspaceButtonBorderColorPressed: UIColor.red,
            backspaceButtonBorderColorDisabled: UIColor.black)
       
        pinInputIndecatorView!.strokeColor = darkGray
        pinInputIndecatorView!.fillColor = lightGray
        pinInputIndecatorView!.drawText = true
        pinInputIndecatorView!.filledPlaceholder = "*"
        pinInputIndecatorView!.unfilledPlaceholder = "-"
        
        stackView.addArrangedSubview(pinInputIndecatorView!)
        stackView.addArrangedSubview(pinInputView!)
    
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

extension PinInputViewController: CYBAVOWallet.OnPinInputListener {
    func onChanged(length: Int) {
        pinInputIndecatorView!.inputDotCount = length
        if(length == pinInputView!.getMaxLength()){
            var pinSecret = pinInputView!.submit()
            callback?(pinSecret)
            dismiss(animated: true, completion: nil)
        }
    }
}

