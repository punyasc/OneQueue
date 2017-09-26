//
//  PlayerTableViewController.swift
//  SongScrape
//
//  Created by Punya Chatterjee on 9/19/17.
//  Copyright © 2017 Punya Chatterjee. All rights reserved.
//

import UIKit
import AVFoundation
import StoreKit
import MediaPlayer
import AVKit
import UIImageColors
import SpotifyLogin

extension UIColor {
    
    func add(overlay: UIColor) -> UIColor {
        var bgR: CGFloat = 0
        var bgG: CGFloat = 0
        var bgB: CGFloat = 0
        var bgA: CGFloat = 0

        var fgR: CGFloat = 0
        var fgG: CGFloat = 0
        var fgB: CGFloat = 0
        var fgA: CGFloat = 0
        
        self.getRed(&bgR, green: &bgG, blue: &bgB, alpha: &bgA)
        overlay.getRed(&fgR, green: &fgG, blue: &fgB, alpha: &fgA)
        
        let r = fgA * fgR + (1 - fgA) * bgR
        let g = fgA * fgG + (1 - fgA) * bgG
        let b = fgA * fgB + (1 - fgA) * bgB
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}


class PlayerTableViewController: UITableViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    var deleteMode = false
    var nothingPlaying = true
    var oldQueueCount = 0
    var auth = SPTAuth.defaultInstance()!
    var spotifySession:SPTSession?
    var player: SPTAudioStreamingController?
    var isPaused = true
    var queue = [Song]() {
        willSet {
            oldQueueCount = queue.count
        }
        didSet {
            if queue.count < 1 {
                editButton.alpha = 0.0
            } else {
                editButton.alpha = 1.0
            }
            if nothingPlaying {
                refreshQueue()
            }
        }
    }
    var lastSong:Song?
    var thisStorefrontId:String?
    var applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queueTable.reloadData()
        queueTable.setEditing(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //TODO: SAVE ALL STATE INFO SO IT CAN BE RETURNED TO
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.editButton.alpha = 0.0
        updateUINothingPlaying()
        
        SpotifyLogin.shared.getAccessToken { (accessToken, error) in
            if error != nil {
                print("PlayerTVC: Failed to get access token")
                //failed to get access token
            } else {
                print("PlayerTVC: About to initialize player")
                self.initializePlayerWithToken(accessToken!)
            }
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.pauseAll()
            self.isPaused = true
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.playAll()
            self.isPaused = false
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.skipForward()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.skipBackward()
            return .success
        }
        
        applicationMusicPlayer.beginGeneratingPlaybackNotifications()
        applicationMusicPlayer.repeatMode = .none
        
        NotificationCenter.default.addObserver(forName:Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object:nil, queue:nil, using:applePlaybackChanged)
        queueTable.reloadData()
    }
    
    func applePlaybackChanged(not:Notification) -> Void {
        print(not.description)
        if applicationMusicPlayer.playbackState == .stopped {
            //song finished
            refreshQueue()
        } else if applicationMusicPlayer.playbackState == .paused {
            //paused
            playPauseButton.setTitle("Play", for: .normal)
            playPauseButton.setImage(#imageLiteral(resourceName: "Play Filled-100"), for: .normal)
        } else if applicationMusicPlayer.playbackState == .playing {
            //playing
            playPauseButton.setTitle("Pause", for: .normal)
            playPauseButton.setImage(#imageLiteral(resourceName: "Pause Filled-100"), for: .normal)
        }
    }
    
    
    // Outlets and actions
   
    @IBOutlet weak var tableFooterView: UIView!
    @IBOutlet weak var playViewHeader: UIView!
    @IBOutlet weak var albumArtView: UIImageView!
    @IBOutlet weak var musicSourceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistAlbumLabel: UILabel!
    @IBOutlet var queueTable: UITableView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    @IBAction func unwindToPlayer(unwindSegue: UIStoryboardSegue) {
        
    }
    
    @IBAction func addSongPress(_ sender: Any) {
        if !UserDefaults.standard.bool(forKey: "AppleMusicEnabled") && !UserDefaults.standard.bool(forKey: "SpotifyEnabled") {
            let alert = UIAlertController(title: "No Sources Chosen", message: "Sign in to at least one service to search for songs!", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title:"Not Now", style: UIAlertActionStyle.cancel, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title:"Add a service", style: UIAlertActionStyle.default, handler: { (action) in
                //UIAlertActionStyle.
                self.performSegue(withIdentifier: "ChangeServices", sender: self)
                //alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "AddSong", sender: self)
        }
    }
    
    @IBAction func editPress(_ sender: Any) {
        deleteMode = !deleteMode
        queueTable.reloadData()
        if deleteMode {
            editButton.setTitle("Done", for: .normal)
        } else {
            editButton.setTitle("Edit", for: .normal)
        }
    }
    
    @IBAction func playPausePress(_ sender: Any) {
        guard let lastSong = lastSong else { return }
        togglePlayPause()
    }
    @IBAction func skipBackwardPress(_ sender: Any) {
        guard let lastSong = lastSong else { return }
        skipBackward()
    }
    @IBAction func skipForwardPress(_ sender: Any) {
        guard let lastSong = lastSong else { return }
        skipForward()
    }
    
    func skipBackward() {
        isPaused = false
        applicationMusicPlayer.pause()
        player!.setIsPlaying(false, callback: { error in
            if error != nil {
                print("PlayerTVC: Error seeking backward with Spotify (could not pause)")
            }
        })
        guard let lastSong = lastSong  else {
            print("PlayerTVC: Error seeking backward (could not retrieve last song)")
            return
        }
        queue.insert(lastSong, at: 0)
    }
    
    func skipForward() {
        isPaused = false
        if lastSong!.spotifyUri != nil {
            player!.setIsPlaying(false, callback: { error in
                if error != nil {
                    print("PlayerTVC: Error skipping forward with Spotify (could not play)")
                }
            })
        }
        if lastSong!.appleId != nil {
            applicationMusicPlayer.stop()
        }
    }
    
    ////// Playback helper functions
    
    func setLockInfo(for song:Song)
    {
        let art = MPMediaItemArtwork.init(image: song.artwork!)
        let timeInSeconds = Int((song.duration/1000))
        let songInfo :[String : Any] = [MPMediaItemPropertyTitle: song.title ,MPMediaItemPropertyArtwork : art, MPMediaItemPropertyArtist: song.artist, MPNowPlayingInfoPropertyElapsedPlaybackTime: 0, MPMediaItemPropertyPlaybackDuration: timeInSeconds, MPNowPlayingInfoPropertyPlaybackRate: 1]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
    }
    
    func togglePlayPause() {
        if isPaused {
            playAll()
        } else {
            pauseAll()
        }
        isPaused = !isPaused
    }
    
    func playAll() {
        queueTable.reloadData()
        playPauseButton.setTitle("Pause", for: .normal)
        playPauseButton.setImage(#imageLiteral(resourceName: "Pause Filled-100"), for: .normal)
        if lastSong!.spotifyUri != nil {
            player?.setIsPlaying(true, callback: { error in
                if error != nil {
                    print("PlayerTVC: Error playing music from Spotify")
                    return
                }
            })
        }
        if lastSong!.appleId != nil {
            applicationMusicPlayer.play()
        }
    }
    
    func pauseAll() {
        queueTable.reloadData()
        playPauseButton.setTitle("Play", for: .normal)
        playPauseButton.setImage(#imageLiteral(resourceName: "Play Filled-100"), for: .normal)
        if lastSong!.spotifyUri != nil {
            player?.setIsPlaying(false, callback: { error in
                if error != nil {
                    print("PlayerTVC: Error pausing music from Spotify")
                    return
                }
            })
        }
        if lastSong!.appleId != nil {
            applicationMusicPlayer.pause()
        }
    }
    
    func refreshQueue() {
        if queue.count > 0 {
            isPaused = false
            nothingPlaying = false
            playPauseButton.setTitle("Pause", for: .normal)
            playPauseButton.setImage(#imageLiteral(resourceName: "Pause Filled-100"), for: .normal)
            switch queue[0].service {
            case .spotify:
                playSongWithSpotify(song: queue[0])
            case .applemusic:
                playSongWithApple(song: queue[0])
                
            default:
                print("PlayerTVC: no music playing")
            }
            lastSong = queue[0]
            //updateNowPlayingCenter(title: lastSong!.title, artist: lastSong!.artist)
            queue.removeFirst()
        } else {
            print("PlayerTVC: queue is empty")
            updateUINothingPlaying()
        }
        queueTable.reloadData()
    }
    
    func resetColors() {
        self.playViewHeader.backgroundColor = .white
        self.view!.backgroundColor = .white
        self.tableFooterView.backgroundColor = .white
    }
    
    func setColors(with color: UIColor) {
        let white80 = UIColor.white.withAlphaComponent(0.8)
        let newColor = color.add(overlay: white80)
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.playViewHeader.backgroundColor = newColor
            self.view!.backgroundColor = newColor
            self.tableFooterView.backgroundColor = newColor
        })
    }
    
    func updateUINothingPlaying() {
        nothingPlaying = true
        self.albumArtView.image = #imageLiteral(resourceName: "placeholder2")
        self.albumArtView.alpha = 0.4
        self.titleLabel.text = "No Music Playing"
        self.musicSourceLabel.text = " "
        self.musicSourceLabel.textColor = .black
        self.artistAlbumLabel.text = "Queue up songs below"
        self.playPauseButton.setImage(#imageLiteral(resourceName: "Play Filled-100"), for: .normal)
        resetColors()
        lastSong = nil
    }
    
    
    
    
    // Spotify Playback
    
    var sptToken: String?
    
    func playSongWithSpotify(song: Song) {
        self.player?.playSpotifyURI(song.spotifyUri!, startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("PlayerTVC: Error playing music with Spotify")
            } else {
                self.setLockInfo(for: song)
                self.albumArtView.alpha = 1.0
                self.albumArtView.image = song.artwork!
                song.artwork!.getColors { colors in
                self.setColors(with: colors.background)
                }
                self.titleLabel.text = "\(song.title)"
                self.musicSourceLabel.text = "VIA SPOTIFY"
                self.musicSourceLabel.textColor = UIColor(red:0.39, green:0.71, blue:0.36, alpha:1.0)
                self.artistAlbumLabel.text = "\(song.artist) - \(song.album)"
                self.playPauseButton.setTitle("Pause", for: .normal)
                self.playPauseButton.setImage(#imageLiteral(resourceName: "Pause Filled-100"), for: .normal)
            }
        })
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        print("isPlaying: \(isPlaying)")
        if (isPlaying) {
            //isPaused = false
            print("SONGDUN")
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try! AVAudioSession.sharedInstance().setActive(true)
        } else {
            print("SONGO")
            //isPaused = true
            if !isPaused {
                print("Song is not halted, it's over. Keep going")
                refreshQueue()
            } else {
                print("Song halted, but it's paused so we're not moving on")
            }
            try! AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    func spotifyInit() {
        SPTAuth.defaultInstance().clientID = "87f97846fb5d4f37a2e117bda6acc229"
        SPTAuth.defaultInstance().redirectURL = URL(string: "SongScrape://returnAfterLogin")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope,
                                                     SPTAuthPlaylistReadPrivateScope,
                                                     SPTAuthPlaylistModifyPublicScope,
                                                     SPTAuthPlaylistModifyPrivateScope]
    }
    
    func initializePlayerWithToken(_ accessToken: String) {
        //guard let accessToken = UserDefaults.standard.string(forKey: "SpotifyAccessToken")  else { return }
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            if self.player!.initialized {
                print("player already initialized")
            } else {
                try! player!.start(withClientId: auth.clientID)
                self.player!.login(withAccessToken: accessToken)
                print("PlayerTVC: Successful Spotify player initialization")
            }
            sptToken = accessToken
        } else {
            print("player not initialized")
        }
    }
    
    func initializePlayer(authSession:SPTSession){
        
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            if self.player!.initialized {
                print("player already initialized")
            } else {
                try! player!.start(withClientId: auth.clientID)
                self.player!.login(withAccessToken: authSession.accessToken)
            }
            sptToken = authSession.accessToken
        } else {
            print("player not initialized")
        }
    }
    
    
    // Apple Music Playback
 
    func playSongWithApple(song: Song) {
        appleMusicPlayTrackId([song.appleId!])
        setLockInfo(for: song)
        self.albumArtView.alpha = 1.0
        self.albumArtView.image = song.artwork!
        song.artwork!.getColors { colors in
            self.setColors(with: colors.background)
        }
        self.titleLabel.text = song.title
        self.musicSourceLabel.text = "VIA APPLE MUSIC"
        self.musicSourceLabel.textColor = UIColor(red:0.65, green:0.43, blue:0.76, alpha:1.0)
        self.artistAlbumLabel.text = "\(song.artist) - \(song.album)"
    }
    
    func appleMusicPlayTrackId(_ ids:[String]) {
        applicationMusicPlayer.setQueue(with: ids)
        applicationMusicPlayer.play()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destNav = segue.destination as? UINavigationController else { return }
        guard let dest = destNav.viewControllers[0] as? LoginViewController else { return }
        dest.backButton.isEnabled = false
    }
    
    
    // Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if queue.isEmpty {
            return 1
        }
        return queue.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        if queue.isEmpty {
            cell = tableView.dequeueReusableCell(withIdentifier: "NoSongsCell", for: indexPath)
            cell!.layer.cornerRadius = 5
            cell!.layer.masksToBounds = true
            return cell!
        }
        let song = queue[indexPath.row]
        if song.service == .spotify {
            cell = tableView.dequeueReusableCell(withIdentifier: "SpotifyItem", for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "AppleItem", for: indexPath)
        }
        cell!.layer.cornerRadius = 20
        cell!.layer.masksToBounds = true
        cell!.imageView?.image = song.artwork!
        cell!.textLabel?.text = song.title
        cell!.detailTextLabel?.text = song.artist + " - " + song.album
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !(queue.isEmpty && indexPath.row == 0)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if deleteMode {
            return .delete
        }
        return .none
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            queue.remove(at: indexPath.row)
            queueTable.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let movedSong = queue.remove(at: fromIndexPath.row)
        queue.insert(movedSong, at: to.row)
        queueTable.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if queue.isEmpty && indexPath.row == 0 {
            performSegue(withIdentifier: "AddSong", sender: self)
        }
    }

}
