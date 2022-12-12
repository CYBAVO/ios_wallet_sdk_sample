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
import AuthenticationServices

class LoginViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @IBOutlet weak var signInButton: GIDSignInButton!
    @IBOutlet weak var appleAuthView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            let authorizationAppleIDButton: ASAuthorizationAppleIDButton = ASAuthorizationAppleIDButton()
            authorizationAppleIDButton.addTarget(self, action: #selector(pressSignInWithAppleButton), for: UIControl.Event.touchUpInside)
            
            authorizationAppleIDButton.frame = self.appleAuthView.bounds
            self.appleAuthView.addSubview(authorizationAppleIDButton)
        }
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
        let config = GIDConfiguration(clientID: GIDSignIn_ClientID)
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { user, error in

            if let error = error {
                print("Google signin delegate error: \(error.localizedDescription)")
                SwiftEventBus.post("google_signed_in_failed")
                return
            }

            if let user = user, let idToken = user.authentication.idToken {
                // Perform any operations on signed in user here.
                let userId = user.userID                  // For client-side use only!
                let idToken = idToken // Safe to send to the server
                let fullName = user.profile?.name
                let email = user.profile?.email
                print("user:\(String(describing: userId)), idToken:\(String(describing: idToken)), fullName:\(String(describing: fullName)), email:\(String(describing: email))")

                let encodedData = try! NSKeyedArchiver.archivedData(withRootObject: user, requiringSecureCoding: false)
                UserDefaults.standard.setValue(encodedData, forKey: "googlesignin_user")
                let identity = Identity()
                identity.provider = "Google"
                identity.idToken = idToken
                SwiftEventBus.post("google_signed_in", sender: identity)
            }
        }
    }
    
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    @objc func pressSignInWithAppleButton() {
        if #available(iOS 13.0, *) {
            let authorizationAppleIDRequest: ASAuthorizationAppleIDRequest = ASAuthorizationAppleIDProvider().createRequest()
            authorizationAppleIDRequest.requestedScopes = [.fullName, .email]

            let controller: ASAuthorizationController = ASAuthorizationController(authorizationRequests: [authorizationAppleIDRequest])

            controller.delegate = self
            controller.presentationContextProvider = self

            controller.performRequests()
        }
    }
    /// apple sing in success
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
                
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let identity = Identity()
            identity.provider = "Apple"
            if let idTokenData = appleIDCredential.identityToken{
                identity.idToken = String(decoding: idTokenData, as: UTF8.self)
            }
            if let fullName = appleIDCredential.fullName, let givenName = fullName.givenName, let lastName = fullName.familyName {
                //this is only for demo. In production app, please do this by locale
                identity.name = getFullName(firstName: givenName, lastName: lastName)
            }else{
                identity.name = UIDevice.current.name
            }
            identity.email = appleIDCredential.email ?? ""
            SwiftEventBus.post("apple_signed_in", sender: identity)
        }
    }
    
    /// apple signin fail
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
                
        switch (error) {
        case ASAuthorizationError.canceled:
            break
        case ASAuthorizationError.failed:
            break
        case ASAuthorizationError.invalidResponse:
            break
        case ASAuthorizationError.notHandled:
            break
        case ASAuthorizationError.unknown:
            break
        default:
            break
        }
                    
        print("didCompleteWithError: \(error.localizedDescription)")
    }
    //combine firstName and lastName depends on if it's chinese or not
    func getFullName(firstName: String, lastName: String) -> String{
        if((firstName.range(of: "\\p{Han}", options: .regularExpression) != nil) &&
            (lastName.range(of: "\\p{Han}", options: .regularExpression) != nil)){
                return "\(lastName)\(firstName)"
        }
        return "\(firstName) \(lastName)"
    }
}


