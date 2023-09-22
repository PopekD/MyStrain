//
//  MiniPlayer.swift
//  MyStrain
//
//  Created by Dawid on 21.9.2023.
//

import Foundation
import UIKit

class MiniPlayerView: UIView {

    static let shared = MiniPlayerView()
    
    // UI components for the mini player
    private let albumImageView: UIImageView
    private let songTitleLabel: UILabel
    private let artistLabel: UILabel
    private let playButton: UIButton
    private let previousButton: UIButton
    private let nextButton: UIButton
    
    // Initialize the mini player view
    override init(frame: CGRect) {
        
        
        albumImageView = UIImageView()
        songTitleLabel = UILabel()
        artistLabel = UILabel()
        playButton = UIButton(type: .system)
        nextButton = UIButton(type: .system)
        previousButton = UIButton(type: .system)
        
        print(frame)
        super.init(frame: frame)
        self.isHidden = true;
        
        configureUI()
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func unhide()
    {
        self.isHidden = false;
    }
    private func configureUI() {
        // Customize appearance of albumImageView, labels, and buttons
        // ...

        // Example configuration:
        albumImageView.contentMode = .scaleAspectFill
        songTitleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        
        playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playButton.tintColor = UIColor.init(hex: "#800080")
        playButton.translatesAutoresizingMaskIntoConstraints = false
        
        previousButton.setImage(UIImage(systemName: "backward.frame.fill"), for: .normal)
        previousButton.tintColor = UIColor.init(hex: "#800080")
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        
        nextButton.setImage(UIImage(systemName: "forward.frame.fill"), for: .normal)
        nextButton.tintColor = UIColor.init(hex: "#800080")
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        // Add targets for button actions (e.g., playButtonTapped, nextButtonTapped)
        previousButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }

    // Set up Auto Layout constraints for UI components
    private func setupConstraints() {
        // Define constraints for albumImageView
        albumImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(albumImageView)
        NSLayoutConstraint.activate([
            albumImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            albumImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            albumImageView.widthAnchor.constraint(equalToConstant: 70),
            albumImageView.heightAnchor.constraint(equalToConstant: 70)
        ])

        // Define constraints for songTitleLabel
        songTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(songTitleLabel)
        NSLayoutConstraint.activate([
            songTitleLabel.leadingAnchor.constraint(equalTo: albumImageView.trailingAnchor, constant: 50),
            songTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            songTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8), // Adjust the top anchor as needed
            songTitleLabel.widthAnchor.constraint(equalToConstant: 150),
        ])
        
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(previousButton)
        NSLayoutConstraint.activate([
            previousButton.leadingAnchor.constraint(equalTo: songTitleLabel.trailingAnchor, constant: 8),
            previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            previousButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        ])
        // Define constraints for playButton
        playButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor, constant: 8),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        ])

        // Define constraints for nextButton
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(nextButton)
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            nextButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        ])
    }


    // Implement actions for button taps
    @objc private func playButtonTapped() {
        // Handle play button tap
        // Implement your audio playback logic here
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
    func update(withSongTitle title: String, artist: String, albumImage: UIImage?) {
        // Update the UI components with the provided information
        print("Reached miniview" + title)
        songTitleLabel.text = title
        artistLabel.text = artist
        albumImageView.image = albumImage
    }
}
