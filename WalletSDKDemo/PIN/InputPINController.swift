import UIKit
import CYBAVOWallet

protocol PinCodeDelegate: class {
    func onPin(code: String)
}

protocol PinCodeInputUI {
    var delegate: PinCodeDelegate? {get set}
}

class InputPINController : UIViewController, PinCodeInputUI {
    @IBOutlet weak var pincode: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var recoveryCode: String?
    weak var delegate: PinCodeDelegate?
    
    override func viewDidLoad() {
        pincode.delegate = self
        nextButton.isEnabled = false
    }
    
    @IBAction func onNext(_ sender: Any) {
        guard let code = pincode.text else {
            return
        }
        nextButton.isUserInteractionEnabled = false
        print("pin code \(code)")
        if let delegate = delegate {
            delegate.onPin(code: code)
            return
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        print("InputPINController viewDidAppear ")
        pincode.becomeFirstResponder()
    }
}

let PINCODE_LENGTH = 8
extension InputPINController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0
        if (range.length + range.location > currentCharacterCount){
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length
        if newLength >= PINCODE_LENGTH {
            DispatchQueue.main.async {
                self.pincode.resignFirstResponder()
                self.nextButton.isEnabled = true
            }
        }
        return newLength <= PINCODE_LENGTH
    }
}
