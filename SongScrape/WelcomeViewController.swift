//
//  WelcomeViewController.swift
//  SongScrape
//
//  Created by Punya Chatterjee on 9/19/17.
//  Copyright © 2017 Punya Chatterjee. All rights reserved.
//

import UIKit
import SpotifyLogin

class WelcomeViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SpotifyLogin.shared.getAccessToken { (accessToken, error) in
            if error != nil {
                print("WelcomeVC: User is not logged in to Spotify. Log in.")
                // User is not logged in, show log in flow.
            } else {
                print("WelcomeVC: User is logged in to Spotify with token \(accessToken)")
            }
        }
        
        //Uncomment this once done testing the new Spotify login API
        /*
        if UserDefaults.standard.bool(forKey: "UserServicesSet") {
            performSegue(withIdentifier: "BypassLogin", sender: self)
            print("yah")
        } else {
            print("nah")
        } */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = SpotifyLoginButton(viewController: self, scopes: [.streaming])
        self.view.addSubview(button)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccessful), name: .SpotifyLoginSuccessful, object: nil)
        
        /*
        let userLoginStatus = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
        if userLoginStatus
        {
            //let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            print("@@@@SPOTIFY ALREADY LOGGIN")
        } */

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func loginSuccessful() {
        print("WelcomeVC: Spotify Login successful!")
        SpotifyLogin.shared.getAccessToken { (accessToken, error) in
            if error == nil {
                print("WelcomeVC: Access token is \(accessToken)")
            } else {
                print("error: \(error)")
            }
        }
    }
    
    @IBAction func unwindToWelcome(unwindSegue: UIStoryboardSegue) { }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PlayerTableViewController {
            if let sessionObj:AnyObject = UserDefaults.standard.object(forKey: "SpotifySession") as AnyObject? {
                let sessionDataObj = sessionObj as! Data
                let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
                dest.spotifySession = firstTimeSession
            }
            if let storefrontIdObj: AnyObject = UserDefaults.standard.object(forKey: "AppleStorefrontId") as AnyObject? {
                let storefrontId = storefrontIdObj as! String
                print("$$$Early Id: \(storefrontId)")
                dest.thisStorefrontId = storefrontId
            }
        
        } else if let dest = segue.destination as? LoginViewController {
                dest.cameFromWelcomeScreen = true
        } else {
            print("Was not a Player Table View Controller nor a Login View Controller")
        }
    }

}
