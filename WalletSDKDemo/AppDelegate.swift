//
//  AppDelegate.swift
//  WalletSDKDemo
//
//  Created by Vincent Huang on 2018/12/28.
//  Copyright © 2018 Cybavo. All rights reserved.
//

import UIKit
import GoogleSignIn
import Foundation
import SwiftEventBus
import CYBAVOWallet
import SwiftyUserDefaults

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("\(error.localizedDescription)")
        } else {
            // Perform any operations on signed in user here.
            let userId = user.userID                  // For client-side use only!
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let email = user.profile.email
            print("user:\(String(describing: userId)), idToken:\(String(describing: idToken)), fullName:\(String(describing: fullName)), email:\(String(describing: email))")
            
            let encodedData = try! NSKeyedArchiver.archivedData(withRootObject: user, requiringSecureCoding: false)
            UserDefaults.standard.setValue(encodedData, forKey: "googlesignin_user")
            
            SwiftEventBus.post("google_signed_in", sender: user.authentication.idToken)
        }
    }
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UINavigationBar.appearance().barTintColor = UIColor(red: 63.0/255.0, green: 81.0/255.0, blue: 197.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        
        //redirectLogToDocuments()
        
        GIDSignIn.sharedInstance().clientID = "992053546599-7d8jrjpq7o8nfu0hbr6hib18pshug5u2.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self
        
        initWalletSDK()

        return true
    }

    func initWalletSDK(){
        var endpoint = Defaults[.endpoint]
        endpoint = "http://192.168.99.230:8080/v1/mw"
        if endpoint == nil || (endpoint?.isEmpty)! {
            endpoint = Bundle.main.object(forInfoDictionaryKey: "endpoint_default") as? String
            if let newValue = endpoint {
                Defaults[.endpoint] = newValue
            }
        }

        if let endpoint = endpoint {
            CYBAVOWallet.shared.endPoint = endpoint
        }
        CYBAVOWallet.shared.apiCode = "{{your api code}}"
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func redirectLogToDocuments() {
        
        let allPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = allPaths.first!
        let pathForLog = documentsDirectory.appendingFormat("/mylog.txt")
        
        freopen(pathForLog.cString(using: String.Encoding.ascii)!, "a+", stderr)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url as URL?,
                                                 sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }
}

