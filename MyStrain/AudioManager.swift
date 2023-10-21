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

protocol AudioManagerDelegate: AnyObject {
    func audioManagerDidFinishPlaying()
}

class AudioManager {
    
    static let shared = AudioManager() // Singleton instance
    weak var delegate: AudioManagerDelegate?
    var progressTimer: Timer?
    var player: AVPlayer?
    var playlistQueue = [String]()
    private var currentPlaybackPosition: Float64!
    private let session = AVAudioSession.sharedInstance()
    private var statusObservation: NSKeyValueObservation?
    private var nowAudio: VideoInfo?
    
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


    // Function to play the next playlist in the queue
    func playNextPlaylist(completion: @escaping (Result<Bool, Error>)-> Void) {
         
        guard !playlistQueue.isEmpty else {
            return
        }
        
        Task {
            do {

                let mp3Link = try await API.shared.sendmp3LinkAsync(videoId: playlistQueue.first!)
                let videoInfo = try await API.shared.searchVideoAsync(videoId: playlistQueue.first!)

                self.nowAudio = videoInfo

                let urlString = URL(string: "https://i.ytimg.com/vi/\(nowAudio?.videoId ?? "0")/hqdefault.jpg")
                URLSession.shared.dataTask(with: urlString!) { data, response, error in
                    if error != nil {return}
                    let img = UIImage(data: data!)
                    let targetSize = CGSize(width: 100, height: 100)
                    let scaledImage = img?.scalePreservingAspectRatio(targetSize: targetSize)
                    
                    self.playAudio(url: mp3Link, title: self.nowAudio?.title ?? "", artwork: scaledImage!)
                    
                }.resume()
                playlistQueue.removeFirst()
                completion(.success(true))
            } catch {
                // Handle errors here
                print("Error: \(error)")
                completion(.failure(error))
            }
        }
    }

    func showMusciPlayer(navigation: UINavigationController, from: String, videoThumbnail: UIImage)
    {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MusicPlayerVC") as! MusicPlayerVC
        vc.SongTitle = nowAudio?.title
        vc.channelName = nowAudio?.channelName
        vc.channelId = nowAudio?.channelID
        vc.img = videoThumbnail
        vc.dateText = (nowAudio?.publishDate as? String)
        vc.from = from
        vc.delegate = MusicPlayerVC.homeDelegate
        navigation.present(vc, animated: true)
    }

    // Function to play audio from a list of URLs
    private func playAudio(url: URL, title: String, artwork: UIImage) {
        let playerItem = url
        let avQueuePlayer = AVPlayer(url: playerItem)

        self.statusObservation = avQueuePlayer.currentItem?.observe(\AVPlayerItem.status) { [weak self] item, _ in
            guard let self = self else { return }
            guard item == avQueuePlayer.currentItem else { return }

            switch (item.status)
            {
            case .readyToPlay:
                updateNowPlayingInfo(title: title, artwork: artwork, duration: item.duration.seconds)
            default:
                print("default")
            }
        }

        self.player = avQueuePlayer
        avQueuePlayer.play()
    }


    func addToQueue(id: String)
    {
        playlistQueue.append(id)
    }
    func resetQue()
    {
        playlistQueue = [String]()
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
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player!.currentItem?.currentTime().seconds
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
    func seek30() {
        guard let player = player,
              let currentItem = player.currentItem else {
            // Handle the case where the player or current item is not available
            return
        }

        let currentTime = currentItem.currentTime()
        let targetTime = CMTimeAdd(currentTime, CMTime(seconds: 30, preferredTimescale: currentTime.timescale))

        // Ensure that the target time is within the duration of the media
        let clampedTime = CMTimeClampToRange(targetTime, range: CMTimeRange(start: .zero, end: currentItem.duration))

        player.seek(to: clampedTime)
    }

    func back15()
    {
        guard let player = player,
              let currentItem = player.currentItem else {
            // Handle the case where the player or current item is not available
            return
        }

        let currentTime = currentItem.currentTime()
        let targetTime = CMTimeAdd(currentTime, CMTime(seconds: -15, preferredTimescale: currentTime.timescale))

        // Ensure that the target time is within the duration of the media
        let clampedTime = CMTimeClampToRange(targetTime, range: CMTimeRange(start: .zero, end: currentItem.duration))

        player.seek(to: clampedTime)
    }

}
