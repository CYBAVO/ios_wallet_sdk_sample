//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet

class SetupPINController : InputPINUI {
    
    var pinCode: String?
    
    override func viewDidAppear(_ animated: Bool) {
        performSegue(withIdentifier: "idSetupPINCode", sender: self);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if var ui = segue.destination as? PinCodeInputUI {
            ui.delegate = self
        }
        if var ui = segue.destination as? BackupChallengeInputUI {
            ui.delegate = self
        }
    }
}


extension SetupPINController : PinCodeDelegate {
    func onPin(code: String) {
        print("SetupPINController onPin \(code)")
        pinCode = code
        self.performSegue(withIdentifier: "idSetupBackupChallenge", sender: self);
    }
}

extension SetupPINController : BackupChallengeDelegate {
    func onChallenges(_ challenges: [BackupChallenge]) {
        guard let pc = pinCode, challenges.count == 3 else {
            NavigationHelper.back(from: self)
            return
        }
        
        Auth.shared.setupPinCode(pinCode: pc) { result in
            switch result {
            case .success(_):
                self.setupBackupChallenge(challenges)
                break
            case .failure(let error):
                self.onSetPINFailed(error: error)
                break
            }
        }
    }
    
    func setupBackupChallenge(_ challenges: [BackupChallenge]) {
        guard let pc = pinCode, challenges.count == 3 else {
            NavigationHelper.back(from: self)
            return
        }
        
        Auth.shared.setupBackupChallenge(pinCode: pc, challenge1: challenges[0], challenge2: challenges[1], challenge3: challenges[2]) { result in
            switch result {
            case .success(_):
                self.onSetPINSuccessed(backNum: -1) {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "idWalletsNavi") as! UINavigationController
                    self.present(vc, animated: true)
                }
                break
            case .failure(let error):
                self.onSetPINFailed(error: error)
                break
            }
        }
    }
}
