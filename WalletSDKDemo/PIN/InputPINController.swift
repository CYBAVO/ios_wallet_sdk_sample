import UIKit
import CYBAVOWallet

protocol PinCodeDelegate: class {
    func onPin(pinSecret: PinSecret?)
}

protocol PinCodeInputUI {
    var delegate: PinCodeDelegate? {get set}
}

class InputPINController : UIViewController, PinCodeInputUI {
    var pinSecret: PinSecret?
    @IBOutlet weak var pincode: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    var recoveryCode: String?
    weak var delegate: PinCodeDelegate?

    override func viewDidLoad() {
        nextButton.isEnabled = false
        pincode.delegate = self
    }
    
    @IBAction func onNext(_ sender: Any) {
        guard let code = pincode.text else {
            return
        }
        nextButton.isUserInteractionEnabled = false
        if let delegate = delegate {
            delegate.onPin(pinSecret: pinSecret)
            return
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        print("InputPINController viewDidAppear ")
    }

    func refreshNext(){
        let newLength = pincode.text?.count ?? 0
        DispatchQueue.main.async {
            self.nextButton.isEnabled = newLength == PINCODE_LENGTH
        }
    }
}

let PINCODE_LENGTH = 6
extension InputPINController : UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        let pinInput = PinInputViewController(nibName: "PinInputViewController", bundle: nil)
        pinInput.callback = { pinSecret in
            print("SetupPINController onPin \(pinSecret)")
            self.pinSecret = pinSecret
            self.pincode.text = "******"
            self.refreshNext()
        }
        pinInput.hideForgot = true
        present(pinInput, animated: true, completion: nil)
        return false
    }
}
