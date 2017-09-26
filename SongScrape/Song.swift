//
//  Song.swift
//  SongScrape
//
//  Created by Punya Chatterjee on 8/12/17.
//  Copyright © 2017 Punya Chatterjee. All rights reserved.
//

import Foundation

class Song {
    var title:String
    var artist:String
    var album:String
    var artwork:UIImage?
    var service:Service
    var spotifyUri:String?
    var appleId:String?
    var duration:Double
    var hdImageUrl:String?
    
    enum Service {
        case spotify, applemusic, soundcloud, local
    }
    
    init(title:String, artist:String, album:String, artwork: UIImage?, service:Service, spotifyUri:String?, duration:Double, appleId:String?, hdImageUrl:String?) {
        self.title = title
        self.artist = artist
        self.album = album
        if let artwork = artwork {
            self.artwork = artwork
        } else {
            self.artwork = #imageLiteral(resourceName: "placeholder2")
        }
        self.service = service
        self.spotifyUri = spotifyUri
        self.duration = duration
        self.appleId = appleId
        self.hdImageUrl = hdImageUrl
    }
}
