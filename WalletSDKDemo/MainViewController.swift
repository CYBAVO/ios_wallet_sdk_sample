//
//  MainViewController.swift
//  WalletSDKDemo
//
//  Created by Vincent Huang on 2018/12/28.
//  Copyright © 2018 Cybavo. All rights reserved.
//

import UIKit
import GoogleSignIn
import Foundation
import CYBAVOWallet
import SwiftEventBus
import Toast_Swift

class MainViewController: UIViewController {
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    var currentState: SignInState = .Unknown
    
    override func viewDidLoad() {
        Auth.shared.addSignInStateDelegate(self)

        SwiftEventBus.onMainThread(self, name: "google_signed_in") { result in
            guard let identity = result?.object as? Identity else {
                return
            }
            print("LoginVC google_signed_in")
            self.doSignIn(identity: identity)
        }
        
        SwiftEventBus.onMainThread(self, name: "google_signed_in_failed") { result in
            self.showSignIn()
        }
        
        SwiftEventBus.onMainThread(self, name: "apple_signed_in") { result in
            guard let identity = result?.object as? Identity else {
                return
            }
            print("LoginVC apple_signed_in")
            self.doSignIn(identity: identity)
        }
        let transform = CGAffineTransform(scaleX: 2.0, y: 2.0);
        indicatorView.transform = transform
    }
    
    func showSignIn(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.present(vc, animated: true, completion: nil)
    }
    
    func showMain() {
        Auth.shared.getUserState { result in
            switch result {
            case .success(let getUserStateResult):
                if getUserStateResult.userState.setPin {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "idWalletsNavi") as! UINavigationController
                    self.present(vc, animated: false)
                } else {
                    let storyboard = UIStoryboard(name: "PIN", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "idSetupPINNavi") as! UINavigationController
                    self.present(vc, animated: false)
                }
                break
            case .failure(let error):
                print("getUserStateResult failed \(error)")
                self.showSignIn()
                break
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        indicatorView.startAnimating()
        print("viewDidAppear Auth.shared.getSignInState() \(Auth.shared.getSignInState())")
        showUIBySignInState(state: Auth.shared.getSignInState())
    }

    override func viewDidDisappear(_ animated: Bool) {
        indicatorView.stopAnimating()
    }
    
    func doSignIn(identity: Identity) {
        print("cybavo doSignIn")
        Auth.shared.signIn(token: identity.idToken, identityProvider: identity.provider) { result in
            switch result {
            case .success(_):
                print("cybavo signed in")
                Auth.shared.setPushDeviceToken(deviceToken: PushDeviceToken) { result in
                    switch result {
                    case .success(_):
                        print("cybavo setPushDeviceToken done")
                        break
                    case .failure(let error):
                        print("cybavo setPushDeviceToken error \(error)")
                        break
                    }
                }
                self.dismiss(animated: true, completion: nil)
                break
            case .failure(let error):
                print("cybavo signIn error \(error)")
                if error.code == .ErrRegistrationRequired {
                    self.doSignUp(identity: identity)
                }
                self.showSignIn()
                break
            }
        }
    }
    
    func doSignUp(identity: Identity) {

        var extras: [String:String] = [:]
        extras["user_name"] = identity.name //Required for Apple Auth. Optional for other services
        Auth.shared.signUp(token: identity.idToken, identityProvider: identity.provider, extras: extras) { result in
            switch result {
            case .success(_):
                print("cybavo signed up")
                self.doSignIn(identity: identity)
                break
            case .failure(let error):
                print("cybavo signup error \(error)")
            }
        }
    }

    func hasUserData() -> Bool {
        guard let userData = UserDefaults.standard.value(forKey: "googlesignin_user") as? Data else {
            NSLog("no googlesignin_user")
            return false
        }
        
        guard let user = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(userData) else {
            NSLog("unable to unarchive")
            return false
        }

        print("user \(user) logged in")
        return true
    }
    
    func renewSession() {
        GIDSignIn.sharedInstance().signInSilently()
    }
    
    func showUIBySignInState(state: SignInState) {
        guard currentState != state else {
            return
        }
        print("showUIBySignInState \(state)")
        currentState = state
        switch state {
        case .SignedIn:
            print("showMain")
            showMain()
        case .SignedOut:
            print("showSignIn")
            showSignIn()
        case .SessionExpired:
            ToastView.instance.showToast(content: "Session expired. Trying to establish session.", duration: 2.0)
            print("renewSession")
            renewSession()
        case .SessionInvalid:
            ToastView.instance.showToast(content: "Invalid session. Please login again.", duration: 2.0)
            print("SessionInvalid")
            self.dismiss(animated: false)
            GIDSignIn.sharedInstance().signOut()
            showSignIn()
        default:
            showSignIn()
        }
    }
}

extension MainViewController : SignInStateDelegate {
    func onUserStateChanged(state: SignInState) {
        showUIBySignInState(state: state)
    }
}
