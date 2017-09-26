//
//  QueueSongViewController.swift
//  SongScrape
//
//  Created by Punya Chatterjee on 9/16/17.
//  Copyright © 2017 Punya Chatterjee. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SpotifyLogin

class QueueSongViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var spotifyDoneLoading = true
    var appleDoneLoading = true
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //later, put in a conditional to check if this is the spotify or apple section
        if section == 0 {
            return spotifySongs.count
        }
        return appleSongs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath)
        var service: String?
        let song: Song?
        if indexPath.section == 0 {
            //Spotify
            song = spotifySongs[indexPath.row]
        } else {
            //Apple Music
            song = appleSongs[indexPath.row]
        }
        cell.textLabel?.text = song!.title
        cell.detailTextLabel?.text = song!.artist + " - " + song!.album
        cell.imageView?.image = song!.artwork
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Spotify"
        }
        return "Apple Music"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBAction func searchPress(_ sender: Any) {
        searchAllServices()
    }
    
    func searchAllServices() {
        dismissKeyboard()
        spotifyDoneLoading = false
        appleDoneLoading = false
        spotifySongs.removeAll()
        appleSongs.removeAll()
        updateActivityIndicator()
        
        let query = searchBar.text
        let fixedQuery = query!.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
        
        /* Search Spotify */
        if UserDefaults.standard.bool(forKey: "SpotifyEnabled") {
            let spotifySearchUrl = "https://api.spotify.com/v1/search?q=\(fixedQuery)&market=US&type=track&limit=5"
            SpotifyLogin.shared.getAccessToken { (accessToken, error) in
                if error != nil {
                    //failed to get access token
                } else {
                    self.callSpotify(url: spotifySearchUrl, token: accessToken!)
                }
            }
            
        } else {
            spotifyDoneLoading = true
        }
        
        /* Search Apple */
        if UserDefaults.standard.bool(forKey: "AppleMusicEnabled") {
            print("Apple is enabled! About to search...")
            guard let storefrontId = UserDefaults.standard.string(forKey: "AppleStorefrontId") else {
                print("Could not fetch storefront ID for search")
                return }
            var appleSearchUrl = "https://itunes.apple.com/search?term=\(fixedQuery)&entity=song&s=\(storefrontId)&limit=5"
            print("URL: \(appleSearchUrl)")
            callApple(url: appleSearchUrl)
        } else {
            print("Apple is disabled. No search.")
            appleDoneLoading = true
        }
    }
    
    
    var sptToken: String?
    var searchUrl = "https://api.spotify.com/v1/search?q=Kendrick+Lamar&market=US&type=track&limit=3"
    var names: [String] = []
    var spotifySongs: [Song] = []
    var appleSongs: [Song] = []
    var storefrontId: String?
    
    func tableView(_ tableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (indexPath.section == 0) {
            addSongAndReturn(songToSend: spotifySongs[indexPath.row])
        } else {
            addSongAndReturn(songToSend: appleSongs[indexPath.row])
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setInsetsToZero()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //registerForKeyboardNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //callAlamo(url: searchUrl)
        //print("The token we got here: \(sptToken)")
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        searchBar.delegate = self
        
        resultsTableView.alpha = 0.0
        //registerForKeyboardNotifications()
        
        //let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        //view.addGestureRecognizer(tap)
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //searchActive = false;
        searchAllServices()
    }
    
    func dismissKeyboard() {
        //print("********Dismiss*")
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        searchBar.endEditing(true)
        view.endEditing(true)
    }
    
    func callApple(url: String) {
        Alamofire.request(url).responseJSON(completionHandler: { response in
            //print("JSON response:")
            let j = JSON(data: response.data!)
            print("QueueSongVC: Apple//")
            print(j)
            
            let items = j["results"].arrayValue
            for item in items {
                let songTitle = item["trackName"].stringValue
                let artist = item["artistName"].stringValue
                let album = item["collectionName"].stringValue
                let trackId = item["trackId"].stringValue
                let artworkUrl = item["artworkUrl100"].stringValue
                let newArtworkUrl = artworkUrl.replacingOccurrences(of: "/100x100bb.jpg", with: "/300x300bb.jpg")
                let hdImageUrl = artworkUrl.replacingOccurrences(of: "/100x100bb.jpg", with: "/640x640bb.jpg")
                let duration = item["trackTimeMillis"].doubleValue
                guard let data = NSData(contentsOf: URL(string: newArtworkUrl)!)  else {
                    //print("Could not get data")
                    return
                }
                let artwork = UIImage(data: data as Data)
                let thisSong = Song(title: songTitle, artist: artist, album: album,  artwork: artwork, service: .applemusic, spotifyUri: nil, duration: duration, appleId: trackId, hdImageUrl: hdImageUrl)
                self.appleSongs.append(thisSong)
                //self.resultsTableView.reloadData()
            }
            //let track = j["results"].arrayValue[0]
            //let trackName = track["trackName"].stringValue
            //let trackId = track["trackId"].stringValue
            self.appleDoneLoading = true
            self.updateActivityIndicator()
            self.resultsTableView.reloadData()
        })
    }
    
    func callSpotify(url: String, token: String) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, headers: headers).responseJSON(completionHandler: { response in
            
            let j = JSON(data: response.data!)
            print("QueueSongVC: Spotify//")
            print(j)
            let items = j["tracks"]["items"].arrayValue
            for item in items {
                let songTitle = item["name"].stringValue
                let artist = item["artists"][0]["name"].stringValue
                let album = item["album"]["name"].stringValue
                let uri = item["uri"].stringValue
                let artworkUrl = item["album"]["images"][1]["url"].stringValue
                let duration = item["duration_ms"].doubleValue
                let data = NSData(contentsOf: URL(string: artworkUrl)!)
                let artwork = UIImage(data: data as! Data)
                let hdImageUrl = item["album"]["images"][0]["url"].stringValue
                let thisSong = Song(title: songTitle, artist: artist, album: album, artwork: artwork, service: .spotify, spotifyUri: uri, duration: duration, appleId: nil, hdImageUrl: hdImageUrl)
                self.spotifySongs.append(thisSong)
                self.names.append(item["name"].stringValue)
            }
            self.spotifyDoneLoading = true
            self.updateActivityIndicator()
            self.resultsTableView.reloadData()
        })
    }
    
    func updateActivityIndicator() {
        if spotifyDoneLoading && appleDoneLoading {
            self.indicator.stopAnimating()
            resultsTableView.alpha = 1.0
        } else {
            self.indicator.startAnimating()
            resultsTableView.alpha = 0.3
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addSongAndReturn(songToSend: Song) {
        self.indicator.startAnimating()
        if let data = NSData(contentsOf: URL(string: songToSend.hdImageUrl!)!) {
            let artwork = UIImage(data: data as Data)
            songToSend.artwork = artwork
        } else {
            print("Could not get high resolution image")
        }
        self.indicator.stopAnimating()
        if let presenter = presentingViewController as? PlayerTableViewController {
            presenter.queue.append(songToSend)
        }
        dismiss(animated: true, completion: nil)
    }
    
    /* KEYBOARD DISMISSAL */
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector:
            #selector(keyboardWasShown(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:
            #selector(keyboardWillBeHidden(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    @objc func keyboardWasShown(_ notificiation: NSNotification) {
        print("KEY SHOWN")
        guard let info = notificiation.userInfo,
            let keyboardFrameValue =
            info[UIKeyboardFrameBeginUserInfoKey] as? NSValue
            else {
                print("couldn't get keyboard frame")
                return }
        let keyboardFrame = keyboardFrameValue.cgRectValue
        let keyboardSize = keyboardFrame.size
        
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0,
                                             keyboardSize.height, 0.0)
        resultsTableView.contentInset = contentInsets
        resultsTableView.scrollIndicatorInsets = contentInsets
        print("set insets!")
    }
    @objc func keyboardWillBeHidden(_ notification: NSNotification) {
        print("KEY HIDDEN")
        setInsetsToZero()
    }
    
    func setInsetsToZero() {
        let contentInsets = UIEdgeInsets.zero
        resultsTableView.contentInset = contentInsets
        resultsTableView.scrollIndicatorInsets = contentInsets
    }


}
