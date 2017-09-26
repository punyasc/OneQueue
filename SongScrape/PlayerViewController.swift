//
//  PlayerViewController.swift
//  SongScrape
//
//  Created by Punya Chatterjee on 8/9/17.
//  Copyright © 2017 Punya Chatterjee. All rights reserved.
//

import UIKit
import AVFoundation
import StoreKit
import MediaPlayer
import AVKit
//import YouTubeSourceParserKit
//import YouTubePlayer

class PlayerViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate, UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queue.count
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var service: String?
        var cell:UITableViewCell?
        let song = queue[indexPath.row]
        if song.service == .spotify {
            cell = tableView.dequeueReusableCell(withIdentifier: "SpotifyItem", for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "AppleItem", for: indexPath)
        }
        cell!.imageView?.image = song.artwork!
        cell!.textLabel?.text = song.title
        cell!.detailTextLabel?.text = song.artist + " - " + song.album
        print("CELL INFO:")
        print(cell!.textLabel?.text)
        return cell!
    }
    
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
            print(queue)
            
            if nothingPlaying {
                refreshQueue()
            }
            //print("Song added to queue!")
            //refreshQueue()
        }
    }
    var lastSong:Song?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queueTable.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.albumArtView.image = #imageLiteral(resourceName: "placeholder")
        self.titleLabel.text = "No Music Playing"
        self.artistAlbumLabel.text = "Queue up songs below"
        self.playPauseButton.setTitle("Play", for: .normal)

        spotifyInit()
        if let spotifySession = spotifySession {
            initializePlayer(authSession: spotifySession)
        } else {
            print("Failed to retrieve Spotify session.")
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            //Update your button here for the pause command
            print("-----PAUSE COMMAND")
            self.pauseAll()
            self.isPaused = true
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            //Update your button here for the play command
            print("+++++PLAY COMMAND")
            self.playAll()
            self.isPaused = false
            return .success
        }
        
        queueTable.delegate = self
        queueTable.dataSource = self
        queueTable.reloadData()
    }
    
    func setLockInfo(for song:Song)
    {
        let url = URL(string: "https://sslf.ulximg.com/image/355x355/cover/1505402492_be4f62b504d3f75bc123f83d7400ed41.jpg/45d408a79e33d844aa4d68ea1ac77193/1505402492_9ce6885ec6a8b2102730453ad10b66c4.jpg")
        let data = try? Data(contentsOf: url!)
        let art = MPMediaItemArtwork.init(image: song.artwork!)
        let songInfo :[String : Any] = [MPMediaItemPropertyTitle: song.title ,MPMediaItemPropertyArtwork : art, MPMediaItemPropertyArtist: song.artist, MPNowPlayingInfoPropertyElapsedPlaybackTime: 0, MPMediaItemPropertyPlaybackDuration: 100, MPNowPlayingInfoPropertyPlaybackRate: 1]
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
    }
    
    @IBAction func unwindToPlayer(unwindSegue: UIStoryboardSegue) { }
    @IBOutlet weak var queueTable: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistAlbumLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var albumArtView: UIImageView!
    
    @IBAction func trackBackPress(_ sender: Any) {
        isPaused = false
        applicationMusicPlayer.pause()
        player!.setIsPlaying(false, callback: { error in
            if error != nil {
                print("Error seeking backward (1)")
            }
        })
        guard let lastSong = lastSong  else {
            print("Error seeking backward (2)")
            return
        }
        queue.insert(lastSong, at: 0)
        //refreshQueue()
    }
    
    @IBAction func trackForwardPress(_ sender: Any) {
        isPaused = false
        if lastSong!.spotifyUri != nil {
            player!.setIsPlaying(false, callback: { error in
                if error != nil {
                    print("Error skipping forward (1)")
                }
            })
        }
        if lastSong!.appleId != nil {
            applicationMusicPlayer.pause()
            refreshQueue()
        }
        
        
        //refreshQueue()
    }
    
    func playAll() {
        queueTable.reloadData()
        playPauseButton.setTitle("Pause", for: .normal)
        
        if lastSong!.spotifyUri != nil {
            player?.setIsPlaying(true, callback: { error in
                if error != nil {
                    print("error playing music")
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
        if lastSong!.spotifyUri != nil {
            player?.setIsPlaying(false, callback: { error in
                if error != nil {
                    print("error pausing music")
                    return
                }
            })
        }
        if lastSong!.appleId != nil {
            applicationMusicPlayer.pause()
        }
    }
    
    @IBAction func pausePlayPress(_ sender: Any) {
        print("Tried to reload data")
        if isPaused {
            //play state
            playAll()
        } else {
            //pause state
            pauseAll()
        }
        isPaused = !isPaused
    }
    
    func refreshQueue() {
        print("---QUEUE REFRESHED---")
        //if isPaused {
            if queue.count > 0 {
                isPaused = false
                nothingPlaying = false
                playPauseButton.setTitle("Pause", for: .normal)
                
                switch queue[0].service {
                case .spotify:
                        playSongWithSpotify(song: queue[0])
                case .applemusic:
                        appleMusicPlayTrackId([queue[0].appleId!])
                        self.titleLabel.text = queue[0].title
                        self.artistAlbumLabel.text = "\(queue[0].artist) - \(queue[0].album)"
                default:
                    print("no music playing")
                }
                lastSong = queue[0]
                //updateNowPlayingCenter(title: lastSong!.title, artist: lastSong!.artist)
                queue.removeFirst()
                
            } else {
                print("queue empty!")
                nothingPlaying = true
                self.albumArtView.image = #imageLiteral(resourceName: "placeholder")
                self.titleLabel.text = "No Music Playing"
                self.artistAlbumLabel.text = "Queue up songs below"
            }
        //}
        queueTable.reloadData()
    }
    
/*** SPOTIFY CODE BEGINS ****/
    
    var sptToken: String?
    
    func playSongWithSpotify(song: Song) {
        self.player?.playSpotifyURI(song.spotifyUri!, startingWith: 0, startingWithPosition: Double(song.startTime!), callback: { (error) in
            if (error != nil) {
                print("Error playing music: \(error)")
            } else {
                //print("playing!")
                self.setLockInfo(for: song)
                self.albumArtView.image = song.artwork!
                self.titleLabel.text = "\(song.title)"
                self.artistAlbumLabel.text = "\(song.artist) - \(song.album)"
                self.playPauseButton.setTitle("Pause", for: .normal)
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
    
    func initializePlayer(authSession:SPTSession){
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
            
            
            sptToken = authSession.accessToken
        } else {
            print("player not initialized")
        }
    }
/*** SPOTIFY CODE ENDS *****/
    
/*** APPLE MUSIC CODE BEGINS *****/
    
    var thisStorefrontId:String?
    let applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
    
    // -- OR --
    let systemMusicPlayer:MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer
    
    // 2. Playback a track!
    func appleMusicPlayTrackId(_ ids:[String]) {
        print("Apple music is about to queue ids")
        applicationMusicPlayer.setQueue(with: ids)
        //systemMusicPlayer.prepareToPlay()
        //systemMusicPlayer.play()
        //applicationMusicPlayer.prepareToPlay()
        applicationMusicPlayer.play()
    }
    
/*** APPLE MUSIC CODE ENDS *******/
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /* older implementation, make sure to put this back in since this sends the apple storefront id
        guard let aqv = segue.destination as? AddQueueViewController else { return }
        aqv.storefrontId = self.thisStorefrontId
        */
        print("TOKEN BEING SENT: \(sptToken!)")
        guard let qst = segue.destination as? QueueSongViewController else { return }
        print("SENT!!!")
        qst.sptToken = self.sptToken
        qst.storefrontId = self.thisStorefrontId
        print(qst.storefrontId)
    }


}
