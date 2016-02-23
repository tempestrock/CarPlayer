//
//  UIButtonWithFeatures.swift
//  CarPlayer
//
//  Created by Peter Störmer on 18.12.14.
//  Copyright (c) 2014 Tempest Rock Studios. All rights reserved.
//

import Foundation
import MediaPlayer
import UIKit


//
// An enhanced UIButton class that has some more attributes.
// These attributes are used to be handed over as data when a button is clicked.
//
class UIButtonWithFeatures: UIButton {


    var _mediaItem: MPMediaItem? = nil
    var _position: Double? = nil
    var _playAllButtonPressed: Bool? = nil
    var _artistName: String? = nil


    func setMediaItem(mediaItem: MPMediaItem) {

        _mediaItem = mediaItem

    }

    func mediaItem() -> MPMediaItem {

        assert(_mediaItem != nil, "UIButtonWithFeatures.mediaItem(): media item not initialized")
        return _mediaItem!
    }

    func setPosition(pos: Double) {

        _position = pos
    }

    func position() -> Double {

        assert(_position != nil, "UIButtonWithFeatures.position(): position not initialized")
        return _position!
    }

    func setPlayAllButtonPressed(pressed: Bool) {

        _playAllButtonPressed = pressed
    }

    func playAllButtonPressed() -> Bool {

        assert(_playAllButtonPressed != nil, "UIButtonWithFeatures.playAllButtonPressed(): flag not initialized")
        return _playAllButtonPressed!
    }

    func setArtistName(name: String) {

        _artistName = name
    }

    func artistName() -> String {

        assert(_artistName != nil, "UIButtonWithFeatures.artistName(): name not initialized")
        return _artistName!
    }

}