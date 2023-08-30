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
    var id: String

    init(id: String) {
        self.id = id
        super.init(nibName: nil, bundle: nil)
    }

    // Required initializer since you're providing a custom init
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        playerViewController = AVPlayerViewController()
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.bounds

        let videoURL = URL(string: "https://www.youtube.com/embed/\(id)")!
        player = AVPlayer(url: videoURL)
        playerViewController.player = player
    }
}

