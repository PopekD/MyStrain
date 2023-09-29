//
//  MiniPlayer.swift
//  MyStrain
//
//  Created by Dawid on 21.9.2023.
//

import Foundation
import UIKit
import MediaPlayer
class MiniPlayerView: UIView {

    static let shared = MiniPlayerView()
    
    // UI components for the mini player
    private let albumImageView: UIImageView?
    private let songTitleLabel: UILabel?
    private let artistLabel: UILabel
    private let playButton: UIButton
    private let progressBar: UIProgressView
    private var dateText: String
    private var channelName: String
    private var channelID: String
    var progressTimer: Timer?
    var isPlaying: Bool!

    // Initialize the mini player view
    override init(frame: CGRect) {
        
        
        albumImageView = UIImageView()
        songTitleLabel = UILabel()
        artistLabel = UILabel()
        playButton = UIButton(type: .system)
        progressBar = UIProgressView()
        dateText = String()
        channelName = String()
        channelID = String()
        
        super.init(frame: frame)
        self.isHidden = true;
        
        progressTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateProgressBar), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackStateChanged(_:)), name: .playbackStateChanged, object: nil)
        configureUI()
        setupConstraints()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func unhide()
    {
        self.isHidden = false;
    }
    private func configureUI() {

        albumImageView!.contentMode = .scaleAspectFill
        songTitleLabel!.font = UIFont.boldSystemFont(ofSize: 16)
        
        
        playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playButton.tintColor = UIColor.white
        playButton.translatesAutoresizingMaskIntoConstraints = false
        

        progressBar.progress = 0
        progressBar.tintColor = UIColor.init(hex: "#6f2da8")
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        
        
        playButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
    }

    // Set up Auto Layout constraints for UI components
    private func setupConstraints() {
        // Define constraints for albumImageView
        albumImageView!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(albumImageView!)
        NSLayoutConstraint.activate([
            albumImageView!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25),
            albumImageView!.centerYAnchor.constraint(equalTo: centerYAnchor),
            albumImageView!.widthAnchor.constraint(equalToConstant: 70),
            albumImageView!.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        // Define constraints for songTitleLabel
        songTitleLabel!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(songTitleLabel!)
        NSLayoutConstraint.activate([
            songTitleLabel!.leadingAnchor.constraint(equalTo: albumImageView!.trailingAnchor, constant: 35),
            songTitleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor),
            songTitleLabel!.topAnchor.constraint(equalTo: topAnchor, constant: 8), // Adjust the top anchor as needed
            songTitleLabel!.widthAnchor.constraint(equalToConstant: 200),
        ])
        

        playButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: songTitleLabel!.trailingAnchor, constant: 8),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        ])


        progressBar.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(progressBar)
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            progressBar.heightAnchor.constraint(equalToConstant: 4),
        ])

    }

    private func updatePlayButton() {
        if isPlaying {
            // Audio is currently playing, show the pause button
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            playButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        } else {
            // Audio is paused or stopped, show the play button
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        }
    }

    @objc private func pauseButtonTapped() {

        AudioManager.shared.pauseAudio()
    }
    @objc private func playButtonTapped() {

        AudioManager.shared.resumeAudio()
    }
    @objc private func previousButtonTapped() {
        // Handle play button tap
        // Implement your audio playback logic here
    }

    @objc private func nextButtonTapped() {
        // Handle next button tap
        // Implement logic to skip to the next track
    }

    // Update the mini player with information about the currently playing item
    func update(withSongTitle title: String, artist: String, albumImage: UIImage?, dateText: String?, channelName: String?, channelID: String?) {
        // Update the UI components with the provided information
        print("Reached miniview" + title)
        songTitleLabel!.text = title
        artistLabel.text = artist
        albumImageView!.image = albumImage
        self.dateText = dateText!
        self.channelName = channelName!
        self.channelID = channelID!
    }
    

    @objc private func handlePlaybackStateChanged(_ notification: Notification) {
        if let isPlaying = notification.userInfo?["isPlaying"] as? Bool {

            self.isPlaying = isPlaying
            updatePlayButton()
        }
    }
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MusicPlayerVC") as! MusicPlayerVC
        vc.img = albumImageView?.image
        vc.SongTitle = songTitleLabel?.text
        vc.from = "miniPlayer"
        vc.dateText = dateText
        vc.channelName = channelName
        vc.channelId = channelID
        vc.delegate = MusicPlayerVC.homeDelegate
        if let navigationController = UIApplication.shared.windows.first?.rootViewController as? UITabBarController {
            navigationController.present(vc, animated: true)
        }

    }
    
    func updateProgressBarFromNowPlayingInfo() {

        guard let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return
        }

        if let playbackDuration = nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] as? Double,
           let playbackPosition = AudioManager.shared.player?.currentItem?.currentTime().seconds as? Double {
            // Calculate the progress as a float value between 0.0 and 1.0
            let progress = Float(playbackPosition / playbackDuration)
            progressBar.setProgress(progress, animated: true)
        }
    }
    @objc func updateProgressBar() {

        updateProgressBarFromNowPlayingInfo()
    }

}
