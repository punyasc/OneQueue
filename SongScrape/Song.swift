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
    var startTime:Int?
    
    enum Service {
        case spotify, applemusic, soundcloud, local
    }
    
    init(title:String, artist:String, album:String, artwork: UIImage?, service:Service, spotifyUri:String?, startTime:Int?, appleId:String?) {
        self.title = title
        self.artist = artist
        self.album = album
        if let artwork = artwork {
            self.artwork = artwork
        } else {
            self.artwork = #imageLiteral(resourceName: "placeholder")
        }
        self.service = service
        self.spotifyUri = spotifyUri
        self.startTime = startTime
        self.appleId = appleId
    }
}
