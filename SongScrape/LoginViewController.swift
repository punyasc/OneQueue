//
//  LoginViewController.swift
//  SongScrape
//
//  Created by Punya Chatterjee on 8/9/17.
//  Copyright © 2017 Punya Chatterjee. All rights reserved.
//

import UIKit
import StoreKit
import MediaPlayer

class LoginViewController: UIViewController, MPMediaPickerControllerDelegate {
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    let searchUrlBase = "https://api.spotify.com/v1/search?q="
    var thisStorefrontId:String?
    var servicesUpdated = false
    var cameFromWelcomeScreen = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backButton.isEnabled = cameFromWelcomeScreen
        servicesUpdated = false
        if UserDefaults.standard.bool(forKey: "SpotifyEnabled") {
            updateUISpotifyEnabled()
        } else {
            updateUISpotifyDisabled()
        }
        if UserDefaults.standard.bool(forKey: "AppleMusicEnabled") {
            updateUIAppleEnabled()
        } else {
            updateUIAppleDisabled()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        servicesUpdated = false
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spotifyConnectionInit()
        NotificationCenter.default.addObserver(self, selector: Selector("updateAfterFirstLogin"), name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
    }
    
    @IBAction func unwindToLogin(unwindSegue: UIStoryboardSegue) { }
    
    func spotifyConnectionInit() {
        SPTAuth.defaultInstance().clientID = "87f97846fb5d4f37a2e117bda6acc229"
        SPTAuth.defaultInstance().redirectURL = URL(string: "SongScrape://returnAfterLogin")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope,
                                                     SPTAuthPlaylistReadPrivateScope,
                                                     SPTAuthPlaylistModifyPublicScope,
                                                     SPTAuthPlaylistModifyPrivateScope]
        loginUrl = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
    }
    
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var spotifyImage: UIImageView!
    @IBOutlet weak var applemusicImage: UIImageView!
    
    @IBOutlet weak var spotifyLoginButton: UIButton!
    @IBOutlet weak var spotifyLoginLabel: UILabel!
    @IBAction func spotifyLoginPress(_ sender: Any) {
        
        servicesUpdated = true
        if UserDefaults.standard.bool(forKey: "SpotifyEnabled") {
            //disable Spotify
            updateUISpotifyDisabled()
        } else {
            //enable Spotify
            if UIApplication.shared.openURL(loginUrl!) {
                if auth.canHandle(auth.redirectURL) {
                    print("LoginVC: Initializing Spotify connection.")
                } else {
                    print("LoginVC: Failed to initialize Spotify connection.")
                }
            }
        }
        
    }
    
    @IBOutlet weak var applemusicLoginButton: UIButton!
    @IBOutlet weak var applemusicLoginLabel: UILabel!
    @IBAction func applemusicLoginPress(_ sender: Any) {
        servicesUpdated = true
        if UserDefaults.standard.bool(forKey: "AppleMusicEnabled") {
            //disable Apple Music
            updateUIAppleDisabled()
        } else {
            //enable Apple Music
            appleMusicCheckIfDeviceCanPlayback()
            appleMusicRequestPermission()
            appleMusicFetchStorefrontRegion()
        }
    }
    
    @IBAction func donePress(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "UserServicesSet")
        UserDefaults.standard.synchronize()
        if cameFromWelcomeScreen {
            cameFromWelcomeScreen = false
            print("LoginVC: Presenting player as modal")
            performSegue(withIdentifier: "DoneChoosingServices", sender: self)
        } else {
            print("LoginVC: Unwinding to player")
            performSegue(withIdentifier: "ServicesUpdated", sender: self)
        }
    }
    
    @objc func updateAfterFirstLogin() {
        if let sessionObj:AnyObject = UserDefaults.standard.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            updateUISpotifyEnabled()
            UserDefaults.standard.set(self.session.accessToken, forKey: "SpotifyToken")
            UserDefaults.standard.synchronize()
        } else {
            print("LoginVC: Failed to enable Spotify")
        }
    }
    
    func updateUISpotifyEnabled() {
        spotifyImage.alpha = 1
        spotifyLoginLabel.text = "Enabled"
        spotifyLoginButton.setTitle("Sign Out", for: .normal)
        UserDefaults.standard.set(true, forKey: "SpotifyEnabled")
        UserDefaults.standard.synchronize()
    }
    
    func updateUISpotifyDisabled() {
        spotifyImage.alpha = 0.4
        spotifyLoginLabel.text = "Disabled"
        spotifyLoginButton.setTitle("Sign In", for: .normal)
        UserDefaults.standard.set(false, forKey: "SpotifyEnabled")
        UserDefaults.standard.synchronize()
    }
    
    func updateUIAppleEnabled() {
        applemusicImage.alpha = 1
        applemusicLoginLabel.text = "Enabled"
        applemusicLoginButton.setTitle("Sign Out", for: .normal)
        UserDefaults.standard.set(true, forKey: "AppleMusicEnabled")
        UserDefaults.standard.synchronize()
    }
    
    func updateUIAppleDisabled() {
        applemusicImage.alpha = 0.4
        applemusicLoginLabel.text = "Disabled"
        applemusicLoginButton.setTitle("Sign In", for: .normal)
        UserDefaults.standard.set(false, forKey: "AppleMusicEnabled")
        UserDefaults.standard.synchronize()
    }
    
    
    func appleMusicCheckIfDeviceCanPlayback() {
        let serviceController = SKCloudServiceController()
        serviceController.requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
            switch capability {
            case []:
                print("The user doesn't have an Apple Music subscription available. Now would be a good time to prompt them to buy one?")
            case SKCloudServiceCapability.musicCatalogPlayback:
                print("The user has an Apple Music subscription and can playback music!")
            case SKCloudServiceCapability.addToCloudMusicLibrary:
                print("The user has an Apple Music subscription, can playback music AND can add to the Cloud Music Library")
            default: break
            }
        }
    }
    
    func appleMusicRequestPermission() {
        switch SKCloudServiceController.authorizationStatus() {
        case .authorized:
            print("The user's already authorized - we don't need to do anything more here, so we'll exit early.")
            updateUIAppleEnabled()
            return
        case .denied:
            print("The user has selected 'Don't Allow' in the past - so we're going to show them a different dialog to push them through to their Settings page and change their mind, and exit the function early.")
            let alert = UIAlertController(title: "Allow Apple Music access", message: "Please allow Apple Music access in your Settings app.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title:"OK", style: UIAlertActionStyle.default, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
            // Show an alert to guide users into the Settings
            return
        case .notDetermined:
            print("The user hasn't decided yet - so we'll break out of the switch and ask them.")
            
            // Tell user to hit sign in again
            break
        case .restricted:
            print("User may be restricted; for example, if the device is in Education mode, it limits external Apple Music usage. This is similar behaviour to Denied.")
            return
        }
        let alert = UIAlertController(title: "Allow Apple Music access", message: "In case Apple Music has not already been enabled, press Sign In again.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title:"OK", style: UIAlertActionStyle.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
        SKCloudServiceController.requestAuthorization { (status:SKCloudServiceAuthorizationStatus) in
            switch status {
            case .authorized:
                print("All good - the user tapped 'OK', so you're clear to move forward and start playing.")
                self.updateUIAppleEnabled()
            case .denied:
                print("The user tapped 'Don't allow'. Read on about that below...")
            case .notDetermined:
                print("The user hasn't decided or it's not clear whether they've confirmed or denied.")
            default: break
            }
        }
    }
  
    
    func appleMusicFetchStorefrontRegion() {
        let serviceController = SKCloudServiceController()
        serviceController.requestStorefrontIdentifier { (storefrontId:String?, err:Error?) in
            guard err == nil else {
                print("An error occured. Handle it here.")
                return
            }
            
            guard let storefrontId = storefrontId, storefrontId.characters.count >= 6 else {
                print("Handle the error - the callback didn't contain a valid storefrontID.")
                return
                
            }
            let indexRange = storefrontId.startIndex..<storefrontId.index(storefrontId.startIndex, offsetBy: 5)
            let trimmedId = storefrontId.substring(with: indexRange)
            self.thisStorefrontId = trimmedId
            print("Success! The user's storefront ID is: \(trimmedId)")
            UserDefaults.standard.set(self.thisStorefrontId, forKey: "AppleStorefrontId")
            UserDefaults.standard.synchronize()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? PlayerTableViewController else { return }
        if servicesUpdated {
            dest.spotifySession = self.session
            dest.thisStorefrontId = self.thisStorefrontId
        }
    }

}