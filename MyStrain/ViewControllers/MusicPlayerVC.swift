import UIKit
import MediaPlayer

protocol MusicPlayerVCDelegate: AnyObject {
    func performSegueToChannel(videoArray: [VideoInfo], channelName: String, Url: URL?, playlistInfo: [PlayListInfo])
}

class MusicPlayerVC: UIViewController{

    weak var delegate: MusicPlayerVCDelegate?
    static var homeDelegate: ViewController?
    var url: URL?
    var img: UIImage?
    var SongTitle: String?
    var from: String?
    var progressTimer: Timer?
    private var isPlaying: Bool!
    var isSliderBeingDragged = false
    var dateText: String?
    var channelName: String?
    var channelId: String?
    let formatter = DateComponentsFormatter()
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleScrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressBar: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var DateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var ChanelButton: UIButton!
    @IBOutlet weak var backward15: UIButton!
    @IBOutlet weak var seek30: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        setupImageView()
        setupDateAndChannel()
        setupTitleScrollView()
        if(from == "cell")
        {
          setupPlayer()
          NotificationCenter.default.post(name: .playbackStateChanged, object: nil, userInfo: ["isPlaying": true])
          isPlaying = true
        }
        progressTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateProgressBar), userInfo: nil, repeats: true)
        
        progressBar.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressBar.addTarget(self, action: #selector(sliderTouchUp), for: .touchUpInside)
        volumeSlider.addTarget(self, action: #selector(volumeSliderValueChanged), for: .valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackStateChanged(_:)), name: .playbackStateChanged, object: nil)
        if(from == "miniPlayer"){isPlaying = MiniPlayerView.shared.isPlaying}
        updatePlayButton()
    }


    func setupImageView() {
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 2
        imageView.image = img
        imageView.contentMode = .scaleToFill
    }

    func setupDateAndChannel()
    {
        DateLabel.text = dateText!
        ChanelButton.setTitle(channelName!, for: .normal)
        ChanelButton.addTarget(self, action: #selector(SearchChannel), for: .touchUpInside)
        seek30.addTarget(self, action: #selector(seekTO30), for: .touchUpInside)
        backward15.addTarget(self, action: #selector(backTO15), for: .touchUpInside)
    }


    func setupTitleScrollView() {
        

       let wholeText = SongTitle! + "     "
       let textSize = (SongTitle! as NSString).size(withAttributes: [NSAttributedString.Key.font: titleLabel.font!])
       titleLabel.translatesAutoresizingMaskIntoConstraints = false
       titleLabel.text = SongTitle!
        
       let textToAnimateSize = (wholeText as NSString).size(withAttributes: [NSAttributedString.Key.font: titleLabel.font!])
                
        
     
        let totalScrollDistance = textToAnimateSize.width - titleScrollView.frame.width

        // Create an animation block to scroll to the right
        let scrollRightAnimation: () -> Void = {
            self.titleScrollView.contentOffset.x = totalScrollDistance + self.titleScrollView.frame.width
        }


        if textSize.width > titleScrollView.frame.width
       {
        titleLabel.text = SongTitle! + "     " + SongTitle!
         let scrollDuration = Double(textSize.width) / 50.0
            func scrollAnimation() {
                UIView.animate(withDuration: scrollDuration, delay: 4.0, options: [.curveLinear], animations: scrollRightAnimation) { (_) in

                    self.titleScrollView.contentOffset.x = self.titleScrollView.contentOffset.x - (totalScrollDistance + self.titleScrollView.frame.width)
                    scrollAnimation()
                }
            }
          scrollAnimation()
       }

    }


    func setupPlayer() {
        guard let url = url else {
            return
        }
        
        AudioManager.shared.playAudio(url: url, title: SongTitle!, artwork: img!)
        updateMiniPlayer(withTitle: SongTitle!, artist: "Artist Name", albumImage: img)
        MiniPlayerView.shared.unhide()

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
    @objc private func handlePlaybackStateChanged(_ notification: Notification) {
        if let isPlaying = notification.userInfo?["isPlaying"] as? Bool {

            self.isPlaying = isPlaying
            updatePlayButton()
        }
    }
    
    func updateMiniPlayer(withTitle title: String, artist: String, albumImage: UIImage?) {
        MiniPlayerView.shared.update(withSongTitle: title,
                                     artist: artist,
                                     albumImage: albumImage,
                                     dateText: dateText!,
                                     channelName: channelName!,
                                     channelID: channelId!
        )
    }
    
    func updateProgressBarFromNowPlayingInfo() {

        guard let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return
        }

        if let playbackDuration = nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] as? Double,
           let playbackPosition = AudioManager.shared.player?.currentItem?.currentTime().seconds as? Double {
            // Calculate the progress as a float value between 0.0 and 1.0
            let progress = Float(playbackPosition / playbackDuration)
            
            if playbackDuration >= 3600 { // Duration is an hour or longer
                formatter.allowedUnits = [.hour, .minute, .second]
            } else {
                formatter.allowedUnits = [.minute, .second]
            }
            
            elapsedTimeLabel.text = formatter.string(from: TimeInterval(playbackPosition))
            durationLabel.text = formatter.string(from: TimeInterval(playbackDuration - playbackPosition))
            if !isSliderBeingDragged {progressBar.value = progress}
        }
    }
    @objc func updateProgressBar() {
        updateProgressBarFromNowPlayingInfo()
    }


 
    deinit {
        progressTimer?.invalidate()
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {

        isSliderBeingDragged = true
    }
    
    @objc func sliderTouchUp(_ sender: UISlider) {
        if ((AudioManager.shared.player?.currentItem!) != nil) {
            let newTime = Double(sender.value) * AudioManager.shared.player!.currentItem!.duration.seconds
            let cmTime = CMTime(seconds: newTime, preferredTimescale: AudioManager.shared.player!.currentItem!.duration.timescale)
            AudioManager.shared.player!.currentItem?.seek(to: cmTime, completionHandler: { (_) in
                self.isSliderBeingDragged = false
            })
        }

    }
    @objc func SearchChannel()
    {
        
        dismiss(animated: true)

        Task
        {
            API.shared.searchChannelVideos(channelId: channelId!) { result in
                switch result
                {
                    case .success(let videoDictionary):
                        DispatchQueue.main.async {
                            self.delegate?.performSegueToChannel(videoArray: videoDictionary.0,channelName: self.channelName!, Url: videoDictionary.1, playlistInfo: videoDictionary.2)
                        }
                    default:
                        return
                }
            }
        }

    }
    
    @objc func seekTO30()
    {
        AudioManager.shared.seek30()
    }
    @objc func backTO15()
    {
        AudioManager.shared.back15()
    }
    @objc func volumeSliderValueChanged() {
        
    }

}
