//
//  MVC_Controller.swift
//  CarPlayer
//
//  Created by Peter Störmer on 05.12.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import Foundation
import MediaPlayer
import CoreLocation
import AVFoundation     // For the lyrics



enum MusicSkippingDirection {

    case Previous
    case Next

}




//
// The class MVC_Controller plays the controller in the model-view-controller concept of this app.
// The attributes of this class represent the model.
//
class MVC_Controller {

    // ----- Attributes ----------------

    // The music player that is not only fed by queries in this app but actually gets changes also from "outside":
    private var _musicPlayer: MPMusicPlayerController

    // Due to a bug in the notification of state changes, we have to implement the playbackState ourselves:
    private var _musicPlayerIsPlaying: Bool

    // The number of tracks currently stored in the playback list or nil if this value is unavailable
    private var _currentNumberOfTracks: Int?

    // The album id dictionary contains per artist name a list of the corresponding unique album IDs for this artist:
    private var _albumIDDict: [ String : [ NSNumber ]]

    // The album's name if the album's ID is given:
    private var _albumNameForID: [ NSNumber : String ]

    // _longArtistName contains the long name of an artist for the short name given. E.g.: _longArtistName["Beatles"] = "The Beatles"
    private var _longArtistName: [ String : String ]

    // A sorted array of the artists' short names (e.g. "Beatles"):
    private var _sortedArtistShortNames: Array<String>

    // A special dictionary for those albums that are compilations:
    private var _compilationAlbum: Array<String>

    // A list of genre names, having a unique genre ID as key:
    private var _genreName: [ NSNumber : String ]

    // The currently selected artist:
    private var _currentArtist: String?

    // The list of IDs of currently selected albums:
    private var _currentAlbumIDList: Array<NSNumber>?

    // The list of currently playing tracks:
    private var _currentPlaylist: Array<MPMediaItem>?

    // For each artist the image to be stored:
    private var _artworkForArtist: [ String : MPMediaItemArtwork? ]

    // For each artist the total number of tracks that the artist has in the music library:
    private var _numOfTracksForArtist: [ String : Int ]

    // For each album ID the total number of music (!) tracks that the album has in the music library:
    private var _numOfTracksForAlbumID: [ NSNumber : Int ]

    // A boolean flag that tells us whether or not the user jumped to the player view directly:
    private var _directJumpToPlayer: Bool

    // A value that is used for the brightness adjustment. nil means that the brightness has not been set before.
    private var _prevPinchScale: CGFloat?

    // The currently visible view:
    private var _currentlyVisibleView: UIViewController! = nil

    // A flag that says whether the user has changed their selection compared to the previous selection:
    private var _userSelectionHasChanged: Bool?

    // The speed display mode can be 0 = off, 1 = speed only, or 2 = all (may be an enum in the future):
    private var _speedDisplayMode: Int
    private let _numOfSpeedDisplayModes = 3

    private var _previousSkippingDirection: MusicSkippingDirection = .Next

    // A percentage (between 0.0 and 1.0) that tells the outer callers how far we are with the initial load:
    private var _initialLoadState: Double = 0.0


    // ----- Constants ----------------

    // Special "artists":
    let _compilationTitle: String = "Compilations"
    let _playlistsTitle: String = "Playlists"
    let _genreTitlePrefix: String = "Genre:"
    let _oners: String = "1ers"                     // special "artist" grouping for those artists that only have one track

    // A list of playlists that shall not appear in the list of all playlists:
    let _playlistBlacklist: [String] = [ "Einkäufe", "alle iPhone-Titel", "alle Musiktitel" ]

    // The "music" media type:
    let MPMediaTypeMusic = UInt(MPMediaType.Music.rawValue)


    // ----- Methods ----------------

    //
    // The "constructor"
    //
    init() {

        // DEBUG println("MVC_Controller.init()")

        // Initialize the music player as a system music player (continuing to play the music even if the app is closed):
        _musicPlayer = MPMusicPlayerController.systemMusicPlayer()
        _musicPlayerIsPlaying = false
        _currentNumberOfTracks = nil

        // Always repeat the respective music queue:
        _musicPlayer.repeatMode = MPMusicRepeatMode.All
        
        // Initialize the album dictionary and its sorted key lists:
        _longArtistName = [ String : String ]()
        _sortedArtistShortNames = Array<String>()
        _albumIDDict = [ String : [ NSNumber ]]()
        _albumNameForID = [ NSNumber : String ]()

        // Initialize list of track numbers:
        _numOfTracksForArtist = [ String: Int ]()

        // Initialize list of track numbers per album ID:
        _numOfTracksForAlbumID = [ NSNumber : Int ]()

        // Initialize the special dictionary for compilations:
        _compilationAlbum = Array<String>()

        // Initalize the genre names:
        _genreName = [ NSNumber : String ]()

        // Initialize the current artist with "non-existent":
        _currentArtist = nil

        // Initialize the current album ID list with "non-existent":
        _currentAlbumIDList = nil

        // Initialize the current playlist as "non-existent":
        _currentPlaylist = nil

        // Initialize the artwork list:
        _artworkForArtist = [ String : MPMediaItemArtwork? ]()

        // Initially, no direct jump to the player view is intended:
        _directJumpToPlayer = false

        // Inititally the user selection flag is set to "non-existent":
        _userSelectionHasChanged = nil

        // Initially, the speed display mode is "off"
        _speedDisplayMode = 0

        // Load the speed display mode from disk:
        _savior.loadSpeedDisplayMode(&_speedDisplayMode)

        // Check if the MPMusicplayer is already playing:
        checkIfMusicIsPlaying()

        // Fill the album dictionary according to what can be found in the music library.
        // Do this asynchronously:
        let qualityOfServiceClass: Int = Int(QOS_CLASS_BACKGROUND.rawValue)
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            self.fillAlbumDictionary()
        })
    }


    //
    // Checks if the music player is already playing (because it was playing right when the app started).
    // Due to issues with the "playbackState" in iOS this is not completely reliable. W.T.F...
    //
    func checkIfMusicIsPlaying() {

        if _musicPlayer.playbackState == MPMusicPlaybackState.Playing {

            // We assume that the player is already playing.
            _musicPlayerIsPlaying = true
        }

    }


    //
    // Returns the currently played item.
    //
    func nowPlayingItem() -> MPMediaItem {

        // Assert that the nowPlayingItem exists:
        assert(_musicPlayer.nowPlayingItem != nil, "MVC_Controller.nowPlayingItem(): nowPlayingItem does not exist.")
        
        return _musicPlayer.nowPlayingItem!
    }


    //
    // Returns true if the artist and the album of the currently playing song
    // are equal to the previously selected artist and album.
    //
    func albumAndArtistWerePreviouslySelected() -> Bool {

        assert(_userSelectionHasChanged != nil, "MVC_Controller.albumAndArtistWerePreviouslySelected(): user selection uninitialized")

        return !_userSelectionHasChanged!
    }


    //
    // Returns the state of the initial loading phase as a percentage of completion.
    // < 1.0: not completely finished
    // == 1.0: finished
    //
    func initialLoadState() -> Double {

        return _initialLoadState

    }


    //
    // Fills the album dictionary ("_albumIDDict") according to what can be found in the music library.
    // This is done in the following way:
    // For each song in the music library the artist name and the album ID are found out.
    // If the album ID is new for this artist, it is added to the list _albumIDDict[artistname].
    // Genres are handles just as artist names. So if the genre of the given song is new, the list _albumIDDict[genrename]
    // is created, and
    //
    func fillAlbumDictionary() {

        // DEBUG print("MVC_Controller.fillAlbumDictionary(): Starting")

        // Create initial query:
        let songsQuery = MPMediaQuery.songsQuery()

        // Filter out those items that are not music:
        let predicateJustMusic = MPMediaPropertyPredicate(value: MPMediaTypeMusic, forProperty: MPMediaItemPropertyMediaType)
        songsQuery.addFilterPredicate(predicateJustMusic)

        // Initialize the load state:
        _initialLoadState = 0.0

        // Find out the number of tracks:
        let numOfTracks = songsQuery.items!.count
        var trackCounter: Int = 0

        // Fill the artist dictionary:
        for song in songsQuery.items! {

            _initialLoadState = (Double(trackCounter) / Double(numOfTracks)) * 0.905
            trackCounter += 1

            // "song" has type MPMediaItem

            // Skip stuff that is not music:
            if !trackCanBePlayed(song) {

                // Handle the number of tracks visited so far:
                continue
            }

            // This is a song that can be regarded "normal" and can be added to the song dictionary

            let artistName: String = artistNameOfTrack(song)

            // --- Store album IDs for the given artist ---
            // Fill the album dictionary with a new album name if this has not been stored before:
            if _albumIDDict[artistName] == nil {

                // This artist is new to the list, the list is still nil
                // => Create a new album ID list:
                _albumIDDict[artistName] = [ NSNumber ]()
                _artworkForArtist[artistName] = song.artwork

                let shortArtistName = shortNameForLongName(artistName)
                _longArtistName[shortArtistName] = artistName
            }

            // Get the album ID for the currently checked track:
            let albumID: NSNumber = song.valueForProperty(MPMediaItemPropertyAlbumPersistentID) as! NSNumber

            // Check if the album is unkown so far for the current artist:
            if ((_albumIDDict[artistName]!).indexOf(albumID) == nil) {

                // Store the album name for this album ID if this has not been done before:
                if _albumNameForID[albumID] == nil {
                    _albumNameForID[albumID] = song.albumTitle
                    // DEBUG println("ID \(albumID) has album title \(_albumNameForID[albumID])")
                }

                // This album ID was unknown so far. => Add it to the list of album IDs:
                addAlbumIDAtRightPlace(&_albumIDDict[artistName]!, albumTitle: song.albumTitle!, albumIDToBeAdded: albumID)
            }

            // --- Increase number of tracks for this artist ---
            if _numOfTracksForArtist[artistName] == nil {

                _numOfTracksForArtist[artistName] = 0
            }
            _numOfTracksForArtist[artistName]! += 1
            

            // --- Store album IDs for the given genre ---
            let genreNameOfThisTrack: String! = song.valueForProperty(MPMediaItemPropertyGenre) as! String!
            if genreNameOfThisTrack != nil {

                let genreTitle: String = _genreTitlePrefix + genreNameOfThisTrack

                // Fill the album dictionary with a new album name if this has not been stored before:
                if _albumIDDict[genreTitle] == nil {

                    //print("Genre: \"\(genreTitle)\" has an empty list")
                    // This genre is new to the list, the list is still nil
                    // => Create a new album ID list:

                    _albumIDDict[genreTitle] = [ NSNumber ]()
                    _artworkForArtist[genreTitle] = nil
                    _longArtistName[genreNameOfThisTrack] = genreTitle
                    _numOfTracksForArtist[genreTitle] = 0
                }

                // Check if the album is new to the genre:
                if ((_albumIDDict[genreTitle]!).indexOf(albumID) == nil) {

                    // This album ID was unknown so far. => Add it to the list of album IDs:
                    //print("Adding albumID \"\(albumID)\" with title: \"\(song.albumTitle!)\" to the ID list of \"\(genreTitle)\".")
                    addAlbumIDAtRightPlace(&_albumIDDict[genreTitle]!, albumTitle: song.albumTitle!, albumIDToBeAdded: albumID)

                    if (genreTitle == "Genre:Indie-Pop") {
                      // DEBUG print("albumIDDict is \"\(_albumIDDict[genreTitle]![0])\".")
                    }

                }

                // --- Increase number of tracks for this genre ---
                if _numOfTracksForArtist[genreTitle] == nil {

                    _numOfTracksForArtist[genreTitle] = 0
                }
                _numOfTracksForArtist[genreTitle]! += 1
            }

            // --- Increase number of tracks for the given album ID ---
            if _numOfTracksForAlbumID[albumID] == nil {

                _numOfTracksForAlbumID[albumID] = 0
            }
            _numOfTracksForAlbumID[albumID]! += 1

        } // for

        // DEBUG println("after loop: \(_initialLoadState)")

        createOners()
        // DEBUG println("after oners: \(_initialLoadState)")

        // --- Create the artificial artist "Playlists" ---
        addPlaylistsAsArtist()
        // DEBUG println("after play lists: \(_initialLoadState)")

        // Create the sorted list of artist short names:
        _sortedArtistShortNames = Array(_longArtistName.keys).sort(<)

        // Finalize the load state:
        _initialLoadState = 1.0

        // DEBUG printCompleteAlbumDictionary()

        // DEBUG print("MVC_Controller.fillAlbumDictionary(): Finished")
    }


    //
    // Returns true if the given track can be played by the Car Player.
    //
    func trackCanBePlayed(track: MPMediaItem) -> Bool {

        // Set flag whether the track is actually a song:
        let trackIsMusic: Bool = (track.valueForProperty(MPMediaItemPropertyMediaType) as! UInt == MPMediaTypeMusic)
        if !trackIsMusic {

            // We skip this track
            // DEBUG println("track ”\(track.title!!)\" is not music => skipping")
            return false
        }

        // Set flag whether the track is only a dream in the clouds:
        let trackHangsInTheClouds = track.valueForProperty(MPMediaItemPropertyIsCloudItem) as! Bool
        if trackHangsInTheClouds {

            // We skip this track
            // DEBUG println("track ”\(track.title!!)\" is just a dream in the clouds => skipping")
            return false
        }

        // Set the artist name to be either the album artist or "Compilations" if the track is part of a compilation
        let artistName: String! = artistNameOfTrack(track)

        // track titles should never be empty but we check nevertheless:
        let trackTitlesAreEmpty = ((artistName == nil) || (track.albumTitle == nil) || (track.albumTitle == ""))
        if trackTitlesAreEmpty {
            // We skip this track
            // DEBUG print("Track titles are empty => skipping")
            return false
        }

        return true
    }


    //
    // Adds the albumID to the given array. This is not done by simply appending it at the end but by
    // looking at the album title and putting it in the place that puts the albums in an alphabetical order.
    //
    func addAlbumIDAtRightPlace(inout idArray: Array<NSNumber>, albumTitle: String, albumIDToBeAdded: NSNumber) {

        // DEBUG print("addAlbumIDAtRightPlace(\(albumTitle), \(albumIDToBeAdded))")
        var foundPosition = false

        for index in 0 ..< idArray.count {

            let albumTitleAtIndexPosition = _albumNameForID[idArray[index]]!
            if albumTitle < albumTitleAtIndexPosition {

                // DEBUG print("Adding at position \(index).")
                // We have found the right position
                idArray.insert(albumIDToBeAdded, atIndex: index)

                // Stop searching the array:
                foundPosition = true
                break
            }
        }

        if !foundPosition {

            // DEBUG print("Adding at the end of the list.")
            // We add the albumID at the end of the array:
            idArray.append(albumIDToBeAdded)
            return
        }
    }


    //
    // Creates a short version of the artist long name (e.g. "Beatles" instead of "The Beatles")
    //
    func shortNameForLongName(longName: String) -> String {

        if longName.hasPrefix("The ") || longName.hasPrefix("Die ") {

            // These prefixes are to be cut off.
            let index: String.Index = longName.startIndex.advancedBy(4)
            return longName.substringFromIndex(index)

        } else {

            // Nothing to be done. The short name equals the long name:
            return longName
        }
    }


    //
    // Returns the album artist name for the given track.
    //
    func artistNameOfTrack(track: MPMediaItem) -> String {

        // Set flag whether the track is part of a compilation:
        let trackIsInCompilation = track.valueForProperty(MPMediaItemPropertyIsCompilation) as! Bool

        // Set the artist name to be either the album artist or "Compilations" if the track is part of a compilation
        let artistName: String! = (trackIsInCompilation ? _compilationTitle : track.albumArtist)

        return artistName
    }


    //
    // Creates the special artist "1ers", containing all the albums of artists that only have one track in the complete dictionary.
    // Removes these artists from the list of artists.
    //
    func createOners() {

        var transferredArtists = Array<String>()

        var onerCounter: Int = 0
        let initialLoadStateBefore = _initialLoadState

        for (artistName, numberOfTracks) in _numOfTracksForArtist {

            _initialLoadState = initialLoadStateBefore + ((Double(onerCounter) / Double(_numOfTracksForArtist.count)) * 0.0305)
            onerCounter += 1

            if numberOfTracks != 1 {

                // Not an interesting artist
                continue
            }

            // This artist has only one track.

            // Initialize album dictionary if it does not exist, yet:
            if _albumIDDict[_oners] == nil {

                _albumIDDict[_oners] = [ NSNumber ]()
                _artworkForArtist[_oners] = nil
                _longArtistName[_oners] = _oners
                _numOfTracksForArtist[_oners] = 0
            }

            let albumID: NSNumber = _albumIDDict[artistName]![0]
            addAlbumIDAtRightPlace(&_albumIDDict[_oners]!, albumTitle: _albumNameForID[albumID]!, albumIDToBeAdded: albumID)

            // Increase number of tracks for this special "oners" artist:
            _numOfTracksForArtist[_oners]! += 1

            // Save this artist name for later deletion:
            transferredArtists.append(artistName)
        }

        // Remove the transferred artists from the main list:
        for artistName in transferredArtists {

            _albumIDDict.removeValueForKey(artistName)
            _artworkForArtist.removeValueForKey(artistName)
            _numOfTracksForArtist.removeValueForKey(artistName)

            let shortArtistName = shortNameForLongName(artistName)
            _longArtistName.removeValueForKey(shortArtistName)
        }
    }


    //
    // Adds the somewhat artificial artist "Playlists" and its albums to the list of artists.
    //
    func addPlaylistsAsArtist() {

        // Initialize the album ID dictionary for playlists:
        _albumIDDict[_playlistsTitle] = [ NSNumber ]()
        _artworkForArtist[_playlistsTitle] = nil
        _longArtistName[_playlistsTitle] = _playlistsTitle
        _numOfTracksForArtist[_playlistsTitle] = 0

        let playlistQuery = MPMediaQuery.playlistsQuery()
      //  let collNum = playlistQuery.collections!.count
        // DEBUG println("number of collections: \(collNum)")

        let numOfPlaylists = playlistQuery.collections!.count
        var playlistCounter = 0
        let initialLoadStateBefore = _initialLoadState

        // DEBUG println("numOfPlaylists: \(numOfPlaylists)")

        // Fill the artist dictionary:
        for playlist in playlistQuery.collections! {

            _initialLoadState = initialLoadStateBefore + ((Double(playlistCounter) / Double(numOfPlaylists)) * 0.0705)
            playlistCounter += 1
            // DEBUG println("playlistCounter: \(playlistCounter), _initialLoadState: \(_initialLoadState)")

            let playlistName: String! = playlist.valueForProperty(MPMediaPlaylistPropertyName) as! String!

            if _playlistBlacklist.indexOf(playlistName) != nil {

                // This playlist name is on the blacklist. => Do not take it into account.
                continue
            }

            let playlistID = playlist.valueForProperty(MPMediaPlaylistPropertyPersistentID) as! NSNumber

            // DEBUG println("\(playlistID): \(playlistName)")

            // Add the playlist ID to the list of playlist IDs:
            addAlbumIDAtRightPlace(&_albumIDDict[_playlistsTitle]!, albumTitle: playlistName, albumIDToBeAdded: playlistID)

            // Store the album name for this playlist ID:
            _albumNameForID[playlistID] = playlistName

            // Find out about the real number of tracks in the playlist. Unfortunately, this is simple counting...
            _numOfTracksForAlbumID[playlistID] = 0
            let query = MPMediaQuery.songsQuery()
            let predicateJustThisPlaylist = MPMediaPropertyPredicate(value: playlistID, forProperty: MPMediaPlaylistPropertyPersistentID)
            query.addFilterPredicate(predicateJustThisPlaylist)
            assert(query.items != nil, "MVC_Controller.addPlaylistsAsArtist(): Got kaputt query result.")
            assert(query.items!.count > 0, "MVC_Controller.addPlaylistsAsArtist(): Got empty query result.")
            for queryItem in query.items! {

                if trackCanBePlayed(queryItem) {

                    _numOfTracksForAlbumID[playlistID]! += 1
                }
            }

            _numOfTracksForArtist[_playlistsTitle]! += _numOfTracksForAlbumID[playlistID]!
        }
    }


    //
    // Creates a playlist for the given artist and album ID list and hands it over to the music player.
    // "artist" may also be "Compilations" and "Playlists". For the latter, the "album ID list" is a list of tracks in the selected playlist.
    //
    func createPlaylist(artist: String, albumIDList: Array<NSNumber>) {

        // Set the flag whether the album is a playlist:
        let albumIsPlaylist = (artist == _playlistsTitle)

        // Create a new list of media items:
        _currentPlaylist = Array<MPMediaItem>()

        for albumID in albumIDList {

            // Create initial query:
            var query: MPMediaQuery!

            // Depending on whether we are looking at a playlist or a "real" album, the sorting of songs is different:
            query = (albumIsPlaylist ? MPMediaQuery.albumsQuery() : MPMediaQuery.songsQuery())

            // Set the predicate for the album query:
            let predicateJustOneAlbum = MPMediaPropertyPredicate(value: albumID,
                forProperty: (albumIsPlaylist ? MPMediaPlaylistPropertyPersistentID : MPMediaItemPropertyAlbumPersistentID))
            query.addFilterPredicate(predicateJustOneAlbum)

            assert(query.items != nil, "MVC_Controller.createPlayList(): Got kaputt query result.")
            assert(query.items!.count > 0, "MVC_Controller.createPlayList(): Got empty query result.")

            // Experience is that the "predicateJustMusic" does not work properly. We therefore have to filter out
            // non-music items manually.

            for queryItem in query.items! {

                if trackCanBePlayed(queryItem) {

                    // This item is OK => append it to the new list:
                    _currentPlaylist!.append(queryItem)
                    
                } else {
                    
                    // DEBUG println("Skipping \"\(queryItem.title!!)\".")
                }
            }
        }

        // Set the current number of tracks for later use:
        _currentNumberOfTracks = _currentPlaylist!.count
        
        let mediaCollection = MPMediaItemCollection(items: _currentPlaylist!)

        _musicPlayer.setQueueWithItemCollection(mediaCollection)
    }


    //
    // Tells the music player to create a playlist of songs for the current artist and the current album ID list
    //
    func createPlayListOfCurrentArtistAndAlbumIDs() {

        assert(_currentArtist != nil, "MVC_Controller.createPlayListOfCurrentArtistAndAlbum(): Current artist does not exist.")
        assert(_currentAlbumIDList != nil, "MVC_Controller.createPlayListOfCurrentArtistAndAlbum(): Current album ID list does not exist.")

        createPlaylist(_currentArtist!, albumIDList: _currentAlbumIDList!)
    }
    
    
    //
    // Tells the music player to create a playlist of songs for the current artist and the given list of album IDs.
    //
    func createPlayListOfCurrentArtist(albumIDList: Array<NSNumber>) {

        assert(_currentArtist != nil, "MVC_Controller.createPlayListOfCurrentArtist(): Current artist does not exist.")

        createPlaylist(_currentArtist!, albumIDList: albumIDList)
    }


    //
    // Set the name of the current artist.
    //
    func setCurrentArtist(artistName: String) {

        _currentArtist = artistName
    }


    //
    // Returns true if the current artist is actually not an artist but the "Compilations" list.
    //
    func currentArtistIsCompilation() -> Bool {

        return _currentArtist == _compilationTitle
    }


    //
    // Sets the currently playing track to the one given as parameter.
    //
    func setTrack(track: MPMediaItem) {

        var switchOnAfterSetting = false

        if musicPlayerIsPlaying() {
            togglePlaying()
            switchOnAfterSetting = true
        }

        _musicPlayer.nowPlayingItem = track
        if switchOnAfterSetting {
            togglePlaying()
        }
    }


    //
    // Returns the overall duration of the currently playing track in seconds.
    //
    func durationOfCurrentTrack() -> Double {

        return nowPlayingItem().playbackDuration
    }


    //
    // Positions the current track to the given position.
    // "newPosition" must be between 0.0 and 1.0.
    //
    func setCurrentTrackPosition(var newPosition: Double) {

        // Correct possibly bad input values:
        if newPosition < 0.0 {
            newPosition = 0.0
        } else if newPosition > 1.0 {
            newPosition = 1.0
        }

        let newPositionInSeconds = newPosition * durationOfCurrentTrack()
        // DEBUG println("MVC_Controller.setCurrentTrackPosition(): newPosition is \(newPosition) = \(newPositionInSeconds)secs.")

        _musicPlayer.currentPlaybackTime = newPositionInSeconds
    }


    //
    // Returns the currently set artist.
    //
    func currentArtist() -> String {

        assert(_currentArtist != nil, "MVC_Controller.currentArtist(): Current artist does not exist")
        return _currentArtist!
    }


    //
    // Returns the list of songs currently playing.
    //
    func currentPlaylist() -> Array<MPMediaItem> {

        assert(_currentPlaylist != nil, "MVC_Controller.currentPlaylist(): not inizialized")
        return _currentPlaylist!
    }


    //
    // Sets the list of the IDs of the currently selected albums.
    // Sets the shuffle mode according to the second parameter.
    //
    func setCurrentAlbumIDList(albumIDList: Array<NSNumber>, setShuffleMode: Bool) {

        checkIfUserSelectionHasChanged(albumIDList, setShuffleMode: setShuffleMode)
        // DEBUG println("MVC_Controller.setCurrentAlbumList(): _userSelectionHasChanged: \(_userSelectionHasChanged)")

        _currentAlbumIDList = albumIDList

        if setShuffleMode {

            // A list of albums is played in shuffle mode:
            _controller.switchOnShuffleMode()
        } else {

            // A single album is played without shuffle mode:
            _controller.switchOffShuffleMode()
        }
    }


    //
    // Finds out whether or not the user has changed the selection compared to the currently playing stuff.
    //
    func checkIfUserSelectionHasChanged(albumIDList: Array<NSNumber>, setShuffleMode: Bool) {

        // Check whether the flag has never been set before:
        if _userSelectionHasChanged == nil {

            // DEBUG println("1. -> out")
            _userSelectionHasChanged = true
            return
        }

        // Check if the shuffle mode has changed:
        if ((_musicPlayer.shuffleMode == MPMusicShuffleMode.Songs) && !setShuffleMode) ||
            ((_musicPlayer.shuffleMode == MPMusicShuffleMode.Off) && setShuffleMode) {

            // DEBUG println("2. -> out")
            _userSelectionHasChanged = true
            return
        }

        // Check if the current settings are unknown:
        if (_currentArtist == nil) || (_currentAlbumIDList == nil) || (_currentAlbumIDList!.count == 0) {

            // DEBUG println("3. -> out")
            _userSelectionHasChanged = true
            return
        }

        // TODO: Add some kind of check for the artist. Otherwise e.g. two albums named "Unplugged" of two different artists will be
        //       regarded the same. The second one will not be started.
        //       something like:       ((_currentArtist == _compilationTitle) || (_currentArtist == _musicPlayer.nowPlayingItem.albumArtist)))


        // Check the number of albums:
        if _currentAlbumIDList!.count != albumIDList.count {

            // DEBUG println("4. -> out")
            _userSelectionHasChanged = true
            return
        }

        // For each album in the list: check for differences:
        for albumID in albumIDList {

            if ((_currentAlbumIDList!).indexOf(albumID) == nil) {

                // DEBUG println("5. (\"\(albumID)\") -> out")
                _userSelectionHasChanged = true
                return
            }
        }

        // If we are still here, then no changes have been made:
        // DEBUG println("6. -> no changes")
        _userSelectionHasChanged = false
    }
    

    //
    // Returns true if the music player is playing.
    //
    func musicPlayerIsPlaying() -> Bool {

        return _musicPlayerIsPlaying
    }


/*
    //
    // Prints out the current playbackState of the music player.
    //
    func printMusicPlayerPlaybackState(addInfo: String = "") {

        switch _musicPlayer.playbackState {
        case MPMusicPlaybackState.Playing: println("MVC_Controller (\(addInfo)): playbackState is \"playing\".")
        case MPMusicPlaybackState.Paused: println("MVC_Controller (\(addInfo)): playbackState is \"paused\".")
        default:
            var val: Int = _musicPlayer.playbackState.rawValue
            println("MVC_Controller (\(addInfo)): playbackState is \"\(val)\".")
        }
    }
*/
    

    //
    // Starts the music player's playing.
    //
    func playMusic() {

        // DEBUG printMusicPlayerPlaybackState(addInfo: "playMusic() before")
        _musicPlayer.play()
        _musicPlayerIsPlaying = true
        // DEBUG printMusicPlayerPlaybackState(addInfo: "playMusic() after")
    }


    //
    // Pauses the music player if it is playing. Starts it if it is not playing.
    //
    func togglePlaying() {

        if musicPlayerIsPlaying() {
            _musicPlayer.pause()
        } else {
            _musicPlayer.play()
        }
        _musicPlayerIsPlaying = !_musicPlayerIsPlaying
    }


    //
    // Switches on the musicplayer's shuffle mode.
    //
    func switchOnShuffleMode() {

        _musicPlayer.shuffleMode = MPMusicShuffleMode.Songs
    }


    //
    // Switches off the musicplayer's shuffle mode.
    //
    func switchOffShuffleMode() {

        _musicPlayer.shuffleMode = MPMusicShuffleMode.Off
    }
    

    //
    // Returns the current playback time in seconds.
    //
    func currentPlaybackTime() -> Double {

        return _musicPlayer.currentPlaybackTime

    }


    //
    // Returns the index of the currently playing item.
    // The first index possible is 1.
    //
    func indexOfNowPlayingItem() -> Int {

        return _musicPlayer.indexOfNowPlayingItem + 1

    }


    //
    // Return true if a nowPlayingItem exits.
    //
    func nowPlayingItemExists() -> Bool {

        return (_musicPlayer.nowPlayingItem != nil)
    }
    

    //
    // Returns the number of tracks currently stored in the play list of the music player.
    //
    func currentNumberOfTracks() -> Int {

        assert(_currentNumberOfTracks != nil, "MVC_Controller.currentNumberOfTracks(): undefined number of tracks.")

        return _currentNumberOfTracks!
    }


    //
    // Resets the current number of tracks to "undefined".
    //
    func resetCurrentNumberOfTracks() {

        _currentNumberOfTracks = nil
    }


    //
    // Returns true if the current number of Tracks is known.
    //
    func currentNumberOfTracksIsKnown() -> Bool {

        return (_currentNumberOfTracks != nil)
    }


    //
    // Skips into the given direction.
    //
    func skipToItem(skippingDirection: MusicSkippingDirection) {

        if skippingDirection == MusicSkippingDirection.Next {

            skipToNextItem()

        } else {

            skipToPreviousItem()
        }

    }


    //
    // Skips to the next music item.
    //
    func skipToNextItem() {

        _previousSkippingDirection = MusicSkippingDirection.Next
        _musicPlayer.skipToNextItem()

    }


    //
    // Skips to the previous music item.
    //
    func skipToPreviousItem() {

        _previousSkippingDirection = MusicSkippingDirection.Previous
        _musicPlayer.skipToPreviousItem()
        
    }


    //
    // Returns the previous skipping direction the user used last time.
    //
    func previousSkippingDirection() -> MusicSkippingDirection {

        return _previousSkippingDirection

    }

    //
    // Returns true if the currently playing track has lyrics.
    //
    func currentTrackHasLyrics() -> Bool {

        if _musicPlayer.nowPlayingItem == nil {

            return false
        }

        // DEBUG println("MVC_Controller.currentTrackHasLyrics(): nowPlayingItem = \(_musicPlayer.nowPlayingItem)")

        // This whole AV stuff is a workaround for a bug in iOS that does not respond the lyrics of a media item directly:
        let songURL = _musicPlayer.nowPlayingItem!.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL?
        if songURL == nil {

            return false
        }

        let asset = AVURLAsset(URL: songURL!, options: nil)
        let lyrics: NSString! = asset.lyrics

        // DEBUG println("MVC_Controller.currentTrackHasLyrics(): \(lyrics)")

        return (lyrics != nil) && (lyrics != "")
    }


    //
    // Returns the lyrics of the currently playing track.
    //
    func currentLyrics() -> String {

        // Internally, it is quite a struggle to get the lyrics because of a buggy Apple interface.

        let noLyricsAvailable: String = "No lyrics available."
        var lyrics: String!

        // Assert that the nowPlayingItem exists:
        if _musicPlayer.nowPlayingItem == nil {

            // DEBUG println("Lyrics: nowPlayingItem not available")
            return noLyricsAvailable
        }

        // This whole AV stuff is a workaround for a bug in iOS that does not respond the lyrics of a media item directly:
        let songURL = _musicPlayer.nowPlayingItem!.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL?
        if songURL != nil {

            let asset = AVURLAsset(URL: songURL!, options: nil)
            lyrics = asset.lyrics

        } else {

            // Unfortunately, the AssetURL is not reachable.
            // We try to get the lyrics directly:
            // DEBUG println("Lyrics: songURL not available => trying direct access")
            lyrics = _musicPlayer.nowPlayingItem!.lyrics
        }


        if (lyrics != nil) && (lyrics != "") {

            return String(lyrics)

        } else {

            // DEBUG println("Lyrics: lyrics nil or empty")
            return noLyricsAvailable
        }
    }


    //
    // Prepares the music player for notifications and sets a notification.
    // viewController: The view controller which contains the notification function to call
    // notificationFunctionName: The name of the notification function
    //
    func setNotificationHandler(viewController: UIViewController, notificationFunctionName: Selector) {

        _musicPlayer.beginGeneratingPlaybackNotifications()

        // Create a notification observer:
        NSNotificationCenter.defaultCenter().addObserver(
            viewController,
            selector: notificationFunctionName,
            name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
            object: _musicPlayer
        )
/*
        NSNotificationCenter.defaultCenter().addObserver(
            viewController,
            selector: notificationFunctionName,
            name: MPMusicPlayerControllerPlaybackStateDidChangeNotification,
            object: _musicPlayer
        )
*/
    }


    //
    // Returns the sorted list of the artists' short names.
    //
    func sortedArtistShortNames() -> Array<String> {

        return _sortedArtistShortNames
    }


    //
    // Returns the long name of an artist for a given short name. E.g. in: "Beatles", out: "The Beatles".
    //
    func longArtistName(artistShortName: String) -> String {

        assert(_longArtistName[artistShortName] != nil, "MVC_Controller.longArtistName(): No long name for \(artistShortName)")
        return _longArtistName[artistShortName]!

    }

    
    //
    // Returns the artwork for the given artist. May be nil.
    //
    func artwork(artist: String) -> MPMediaItemArtwork?? {

        return _artworkForArtist[artist]
    }


    //
    // Returns the list of album IDs of the currenly selected artist.
    //
    func albumIDListOfCurrentArtist() -> Array<NSNumber> {

        assert(_currentArtist != nil, "MVC_Controller.albumIDListOfCurrentArtist(): current artist does not exist")
        assert(_albumIDDict[_currentArtist!] != nil, "MVC_Controller.albumIDListOfCurrentArtist(): Album list of artist \"\(_currentArtist!)\" does not exist")
        return _albumIDDict[_currentArtist!]!

    }


    //
    // Returns the album name for a given album ID.
    //
    func albumName(albumID: NSNumber) -> String {

        assert(_albumNameForID[albumID] != nil, "MVC_Controller.albumName(): Album name for ID \(albumID) is unknonw")
        return _albumNameForID[albumID]!
    }


    //
    // Returns a list of stuff with respect to the given album ID.
    // The return value "artwork" is nil if no artwork is available.
    //
    func getAlbumData(albumID: NSNumber) ->  (albumName: String, artwork: MPMediaItemArtwork?, numOfTracks: Int) {

        let name = albumName(albumID)

        // Set flag whether the current artist is actually the "Playlist" entry:
        let artistIsPlaylist: Bool = (_currentArtist! == _playlistsTitle)

        // Find out about the tracks in this album:
        let query = MPMediaQuery.songsQuery()
        let predicateByAlbumID = MPMediaPropertyPredicate(value: albumID,
            forProperty: (artistIsPlaylist ? MPMediaPlaylistPropertyPersistentID : MPMediaItemPropertyAlbumPersistentID))
        query.addFilterPredicate(predicateByAlbumID)

        let numOfTracks = numberOfTracksForAlbumID(albumID)

        var art: MPMediaItemArtwork? = nil
        if !artistIsPlaylist {

            assert(numOfTracks > 0, "MVC_Controller.getAlbumData(): No track found for album ID \"\(albumID)\"")

            // Find out artwork from the first track:
            let firstTrack: MPMediaItem = query.items![0]
            art = firstTrack.artwork
        }

        return (name, art, numOfTracks)
    }


    //
    // Returns the number of albums for the given artist.
    //
    func numberOfAlbumsForArtist(artistName: String) -> Int {

        if (artistName == "Genre:Indie-Pop") {
            print("Jetzt knallts.")
        }
        assert(_albumIDDict[artistName] != nil, "MVC_Controller.numberOfAlbumsForArtist(): album ID list for artist \"\(artistName)\" is uninitialized")
        return _albumIDDict[artistName]!.count

    }


    //
    // Returns the number of tracks for the given artist.
    //
    func numberOfTracksForArtist(artistName: String) -> Int {

        assert(_numOfTracksForArtist[artistName] != nil, "MVC_Controller.numberOfTracksForArtist(): number of tracks unknown for artist \"\(artistName)\"")
        return _numOfTracksForArtist[artistName]!
    }


    //
    // Returns the number of tracks for the given artist.
    //
    func numberOfTracksForAlbumID(albumID: NSNumber) -> Int {

        assert(_numOfTracksForAlbumID[albumID] != nil, "MVC_Controller.numberOfTracksForAlbumID(): number of tracks unknown for album ID \"\(albumID)\"")
        return _numOfTracksForAlbumID[albumID]!
    }
    
    
    //
    // Returns true if it makes sense to play all tracks of the current artist.
    // This is true if the artist is not the "Playlists" and if the artist has more than only one album.
    //
    func playingAllTracksForCurrentArtistMakesSense() -> Bool {

        return ((_currentArtist! != _playlistsTitle) && (albumIDListOfCurrentArtist().count > 1))
    }


    //
    // Sets the flag that a direct jump to the player view is intended.
    //
    func setFlagOfDirectJump() {

        _directJumpToPlayer = true

    }


    //
    // Resets the flag that a direct jump to the player view is intended.
    //
    func resetFlagOfDirectJump() {

        _directJumpToPlayer = false

    }


    //
    // Returns true if the flag of a direct jump to the player view is set.
    //
    func thisWasADirectJump() -> Bool {

        return _directJumpToPlayer
    }


    //
    // Sets the brightness according to the pinchScale parameter and the difference to the previous pinchScale value.
    //
    func setBrightness(pinchScale: CGFloat) {

        if _prevPinchScale == nil {

            // This is the first time (after some time) that the pinch scale has been set.
            // => We only set the scale and wait for additional values.

            _prevPinchScale = pinchScale
            //DEBUG println("MVC_Controller.setBrightness(): Initializing _prevPinchScale to \(_prevPinchScale!).")

            return
        }

        // At this point we have a previous value and a new value. Depending on their difference, we either lighten
        // or darken the screen:

        // Constants for brighter and darker:
        let brighter = CGFloat(0.01)
        let darker = CGFloat(-0.01)

        // Current brightness which is to be adjusted:
        var curVal = UIScreen.mainScreen().brightness

        if _prevPinchScale! < pinchScale {

            // Scale has increased => lighter
            curVal += brighter
            if curVal > 1.0 {
                curVal = 1.0
            }
        } else {

            // Scale has decreased => darker
            curVal += darker
            if curVal < 0.0 {
                curVal = 0.0
            }
        }

        UIScreen.mainScreen().brightness = curVal
        //DEBUG println("MVC_Controller.setBrightness(): New brightness value: \(UIScreen.mainScreen().brightness)")

        _prevPinchScale = pinchScale
    }


    //
    // Set the currently visible view.
    //
    func setCurrentlyVisibleView(view: UIViewController) {

        _currentlyVisibleView = view
        //DEBUG println("MVC_Controller.setCurrentlyVisibleView(): View is \(_currentlyVisibleView.title!).")

    }


    //
    // Returns the currently visible view.
    //
    func currentlyVisibleView() -> UIViewController {

        assert(_currentlyVisibleView != nil, "MVC_Controller.currentlyVisibleView(): view is nil")
        return _currentlyVisibleView
    }


    //
    // Advances the speed display mode in a round robin kind of way.
    //
    func advanceSpeedDisplayMode() {

        _speedDisplayMode = (_speedDisplayMode + 1) % _numOfSpeedDisplayModes

        // Save the new value to disk:
        _savior.saveSpeedDisplayMode(_speedDisplayMode)
    }


    //
    // Returns the currently set speed display mode.
    //
    func speedDisplayMode() -> Int {

        return _speedDisplayMode
    }


    //
    // Returns the progress of the curently playing track. Values may be between 0.0 and 1.0.
    //
    func progressOfCurrentlyPlayingTrack() -> Double {

        return Double(currentPlaybackTime() / durationOfCurrentTrack())
    }
    
    
    //
    // Prints debug output.
    //
    func printlnAlbumListOfCurrentArtist() {

        if (_currentArtist == nil) {
            print("  --> current artist is empty.")
            return
        }

        printlnAlbumListOfArtist(_currentArtist!)
    }


    //
    // Prints debug output.
    //
    func printlnAlbumListOfArtist(artistName: String) {

        /*
        print("Album list of artist \(artistName):")

        let albumlist = _albumIDDict[artistName]
        if albumlist == nil {

            print("  --> Album list is empty")
            return
        }

        for albumName in albumlist! {
            print("   \(albumName)")

            // Find out about the tracks in this album:
            let query = MPMediaQuery.songsQuery()
            let predicateByAlbum = MPMediaPropertyPredicate(value: albumName, forProperty: MPMediaItemPropertyAlbumTitle)
            query.filterPredicates = NSSet(object: predicateByAlbum) as MPMediaPredicate

            // Print out the song titles:
            for mediaEntry in query.items! {
                print("          --> " + mediaEntry.title!)
            }
        }
*/
    }

    //
    // Prints the complete content of the album dictionary in a readable form as a debug output.
    //
    func printCompleteAlbumDictionary() {

        print ("Here comes the complete dictionary:")
        
        for artistName in _albumIDDict.keys {

            print("  artist: \"\(artistName)\"")

            if _albumIDDict[artistName] == nil {

                // This should not happen!
                print("    <empty album list> <-- STRANGE!")
                continue
            }

            for albumID in _albumIDDict[artistName]! {

                if let albumName = _albumNameForID[albumID] {
                    print("    album: \"\(albumName)\"")
                } else {
                    print("    album: <empty> <-- STRANGE!")
                }
            }
        }

        print ("End of the complete dictionary.")
    }

    /*
    func printlnPlayListOfMusicPlayer() {


    // Store shuffle and repeat mode:
    let originalShuffleMode = _musicPlayer.shuffleMode
    let originalRepeatMode = _musicPlayer.repeatMode
    let originalPlaybackState = _musicPlayer.playbackState

    // Set shuffle and repeat mode and stop the player for search:
    _musicPlayer.shuffleMode = MPMusicShuffleMode.Off
    _musicPlayer.repeatMode = MPMusicRepeatMode.All
    _musicPlayer.pause()


    // Loop over all entries by simply advancing until we're back at the item we started from:

    var firstSong: MPMediaItem? = _musicPlayer.nowPlayingItem

    if firstSong == nil {

    println("Playlist not available.")

    } else {

    var counter: Int = 1
    var currentSong: MPMediaItem = firstSong!

    let counterAsString: String = counter.format("03")
    println("\(counterAsString).: \(currentSong.title!)")

    _musicPlayer.skipToNextItem()
    currentSong = _musicPlayer.nowPlayingItem

    while currentSong != firstSong! {

    counter++
    let counterAsString: String = counter.format("03")
    println("\(counterAsString).: \(currentSong.title!)")

    _musicPlayer.skipToNextItem()
    currentSong = _musicPlayer.nowPlayingItem
    }
    }

    // Reset shuffle and repeat mode and playbackstate to their original values:
    _musicPlayer.shuffleMode = originalShuffleMode
    _musicPlayer.repeatMode = originalRepeatMode
    if originalPlaybackState == MPMusicPlaybackState.Playing {
    _musicPlayer.play()
    }
    }
    */

} // class MVC_Controller
