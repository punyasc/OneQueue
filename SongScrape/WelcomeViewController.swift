//
//  WelcomeViewController.swift
//  SongScrape
//
//  Created by Punya Chatterjee on 9/19/17.
//  Copyright © 2017 Punya Chatterjee. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.bool(forKey: "UserServicesSet") {
            performSegue(withIdentifier: "BypassLogin", sender: self)
            print("yah")
        } else {
            print("nah")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @IBAction func unwindToWelcome(unwindSegue: UIStoryboardSegue) { }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
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
        } */
        
        guard let destNav = segue.destination as? UINavigationController else { return }
        guard let dest = destNav.viewControllers[0] as? LoginViewController else { return }
        dest.backButton.isEnabled = true
    }

}
