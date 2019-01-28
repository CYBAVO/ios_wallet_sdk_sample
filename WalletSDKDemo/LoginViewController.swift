//
//  DataViewController.swift
//  WalletSDKDemo
//
//  Created by Vincent Huang on 2018/12/28.
//  Copyright © 2018 Cybavo. All rights reserved.
//

import UIKit
import GoogleSignIn
import SwiftEventBus
import CYBAVOWallet

class LoginViewController: UIViewController, GIDSignInUIDelegate {

    @IBOutlet weak var signInButton: GIDSignInButton!


    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        SwiftEventBus.unregister(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        SwiftEventBus.onMainThread(self, name: "google_signed_in") { result in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func onSignInClick(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }
}

extension LoginViewController : GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        print("GIDSignInDelegate didSignInFor")
    }
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        print("GIDSignInDelegate present")
    }
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        print("GIDSignInDelegate dismiss")
    }
}


