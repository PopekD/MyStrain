//
//  AudioManager.swift
//  MyStrain
//
//  Created by Dawid on 24.9.2023.
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit




class AudioManager {
    
    static let shared = AudioManager() // Singleton instance
    var progressTimer: Timer?
    private var currentPlaybackPosition: Float64!
    var player: AVPlayer?
    private let session = AVAudioSession.sharedInstance()
    private var statusObservation: NSKeyValueObservation?
    private init() {
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            setupMediaPlayerNotificationView()
        } catch {
            print("Audio session setup error: \(error.localizedDescription)")
        }
    }

    // Function to play audio
    func playAudio(url: URL, title: String, artwork: UIImage) {
        
        let asset = AVURLAsset(url: url)
        
        Task {

            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 1
            let avPlayer = AVPlayer(playerItem: item)

            
            player = avPlayer
            
            self.statusObservation = nil
            self.statusObservation = self.player?.currentItem?.observe(\AVPlayerItem.status) { [weak self] item, _ in
                guard let self = self else { return }
                // prevent reading duration from an outdated item:
                guard item == self.player?.currentItem else { return }
                if item.status == .readyToPlay {
                    updateNowPlayingInfo(title: title, artwork: artwork, duration: item.duration.seconds)
                    progressTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateNowPlayingInfoPeriodic), userInfo: nil, repeats: true)
                }
            }
            
            player!.play()

        }
    }

    // Function to pause audio
    func pauseAudio() {
        player?.pause()
        NotificationCenter.default.post(name: .playbackStateChanged, object: nil, userInfo: ["isPlaying": false])

    }

    // Function to resume audio
    func resumeAudio() {
        player?.play()
        NotificationCenter.default.post(name: .playbackStateChanged, object: nil, userInfo: ["isPlaying": true])

    }

    // Function to stop audio
    func stopAudio() {
        player = nil
        
    }

    
    func updateNowPlayingInfo(title: String, artwork: UIImage, duration: Double) {

        let artwork = MPMediaItemArtwork(boundsSize: artwork.size) { (_) -> UIImage in
            return artwork
        }

        
        
        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtwork: artwork,
            MPMediaItemPropertyPlaybackDuration: duration ,

        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
    }
    @objc private func updateNowPlayingInfoPeriodic()
    {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player!.currentItem!.currentTime().seconds
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func setupMediaPlayerNotificationView() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Handle the play command
        commandCenter.playCommand.addTarget { [unowned self] event in
            self.resumeAudio()

            return .success
        }
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            self.pauseAudio()
            
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                
                let positionTime = CMTime(seconds: event.positionTime, preferredTimescale: player!.currentItem!.duration.timescale)
                
                player!.currentItem?.seek(to: positionTime, completionHandler: { (_) in})
                
            }
            return .success
        }
    }


}
