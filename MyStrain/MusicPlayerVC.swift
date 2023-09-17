//
//  MusicPlayerVC.swift
//  MyStrain
//
//  Created by Nini on 28.8.2023.
//

import UIKit
import AVFoundation
import AVKit

class MusicPlayerVC: UIViewController {

    var playerViewController: AVPlayerViewController!
    var player: AVPlayer!
    var url: URL?
    var img: UIImage?


    override func viewDidLoad()  {
        super.viewDidLoad()
        if let img = img {
            
            
        }
        if let url = url {
            print("Reached MusicPlayerVC with URL: \(url)")
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            } catch {
                print("Audio session setup error: \(error.localizedDescription)")
            }
        } else {
            print("Reached MusicPlayerVC without a URL")
        }
        

        
        playerViewController = AVPlayerViewController()
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.bounds
        var imageView : UIImageView
        imageView  = UIImageView(frame:CGRectMake(18, 300, 360, 240));
        imageView.image = img
        playerViewController.contentOverlayView?.addSubview(imageView)
        let asset = AVURLAsset(url: url!)
        Task
        {
            let duration = try await CMTimeGetSeconds(asset.load(.duration))
            let halfDuration = duration / 2.0

            
            let timescale = CMTimeScale(NSEC_PER_SEC)

            
            let halfDurationTime = CMTime(seconds: halfDuration, preferredTimescale: timescale)

            let item = AVPlayerItem(asset: asset)
            item.forwardPlaybackEndTime = halfDurationTime

            let avPlayer = AVPlayer(playerItem: item)
            
            player = avPlayer
            playerViewController.player = player
            player.play()
        }
    }
}


