//
//  AppDelegate.swift
//  SongScrape
//
//  Created by Punya Chatterjee on 8/8/17.
//  Copyright © 2017 Punya Chatterjee. All rights reserved.
//

import UIKit
import SpotifyLogin
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var auth = SPTAuth()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //auth.redirectURL     = URL(string: "SongScrape://returnAfterLogin")
        //auth.sessionUserDefaultsKey = "current session"
        SpotifyLogin.shared.configure(clientID: "87f97846fb5d4f37a2e117bda6acc229", clientSecret: "61083133aebd4690ad102f87385cd8d3", redirectURL: URL(string: "onequeue://returnafterlogin")!)
        
        if UserDefaults.standard.bool(forKey: "UserServicesSet") {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "PlayerTVC")
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }
        
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = SpotifyLogin.shared.applicationOpenURL(url) { (error) in
            if error == nil {
                //NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
            }
        }
        return handled
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


}

