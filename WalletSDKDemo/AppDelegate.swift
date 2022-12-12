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
import UserNotifications

var PushDeviceToken = ""
let GIDSignIn_ClientID = "MY_GOOGLE_SIGN_IN_WEB_CLI_ID"

@UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerDefaultsFromSettingsBundle()
        
        UINavigationBar.appearance().barTintColor = UIColor(red: 63.0/255.0, green: 81.0/255.0, blue: 197.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        
        //redirectLogToDocuments()
        
        initWalletSDK()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {[weak self] granted, error in
                
                print("Permission granted: \(granted)")
                guard granted else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
        }
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func initWalletSDK(){
        guard let endpoints = UserDefaults.standard.string(forKey: "endpoints"), let apicode = UserDefaults.standard.string(forKey: "apicode") else {
            print("missing settings")
            return
        }
        print("endpoints [\(endpoints)]")
        WalletSdk.shared.endPoint = endpoints
        print("apicode [\(apicode)]")
        WalletSdk.shared.apiCode = apicode
        WalletSdk.shared.apnsSandbox = true
    }
    
    func registerDefaultsFromSettingsBundle()
    {
        let settingsUrl = Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
        let settingsPlist = NSDictionary(contentsOf:settingsUrl)!
        let preferences = settingsPlist["PreferenceSpecifiers"] as! [NSDictionary]
        
        var defaultsToRegister = Dictionary<String, Any>()
        
        for preference in preferences {
            guard let key = preference["Key"] as? String else {
                continue
            }
            defaultsToRegister[key] = preference["DefaultValue"]
        }
        UserDefaults.standard.register(defaults: defaultsToRegister)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        Wallets.shared.clearSecureToken() { result in
            print("clearSecureToken \(result)")
        }
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
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        PushDeviceToken = token
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
        ) {
        guard let data = userInfo["data"] as? [String: AnyObject] else {
            completionHandler(.failed)
            return
        }
        
        guard let jsonBody = data["jsonBody"] as? [String: String] else {
            completionHandler(.failed)
            return
        }
        let amount = jsonBody["amount"] as! String
        let from = jsonBody["from_address"]as! String
        let to = jsonBody["to_address"]as! String
        let out = jsonBody["out"]as! String
        let content = UNMutableNotificationContent()
        
        if(out == "true"){
            content.title = "Transaction Send"
            content.body = "Amount \(amount) from \(from)"
        }else{
            content.title = "Transaction Received"
            content.body = "Amount \(amount) to \(to)"
        }
        content.badge = 1
        content.sound = UNNotificationSound.default
        print("didReceiveRemoteNotification \(content.title)_\(content.body)")
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "notification1", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        completionHandler(.newData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
           print("didReceive", response.notification.request.content)
           completionHandler()
       }
       
   func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
       print("willPresent", notification.request.content)
       completionHandler([])

   }
}

