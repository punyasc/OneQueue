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
            print("User services already set, bypassing welcome.")
        } else {
            print("No user services set yet, take user to the login screen.")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func unwindToWelcome(unwindSegue: UIStoryboardSegue) { }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destNav = segue.destination as? UINavigationController else { return }
        guard let dest = destNav.viewControllers[0] as? LoginViewController else { return }
        dest.backButton.isEnabled = true
    }

}
