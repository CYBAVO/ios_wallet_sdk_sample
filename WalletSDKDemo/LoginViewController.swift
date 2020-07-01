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

class LoginViewController: UIViewController, GIDSignInUIDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    @IBOutlet weak var signInButton: GIDSignInButton!
    @IBOutlet weak var appleAuthView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
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
        GIDSignIn.sharedInstance().signIn()
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


