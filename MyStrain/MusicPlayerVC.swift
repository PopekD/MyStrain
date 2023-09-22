import UIKit
import AVFoundation
import AVKit
import MediaPlayer

class MusicPlayerVC: UIViewController{

    
    
    var playerViewController: AVPlayerViewController!
    var player: AVPlayer!
    var url: URL?
    var img: UIImage?
    var SongTitle: String?
    var imageView: UIImageView?
    let session = AVAudioSession.sharedInstance()

    override func viewDidLoad() {
        super.viewDidLoad()

        
        setupAudioSession()
        setupPlayerViewController()
        setupImageView()
        setupTitleScrollView()
        setupPlayer()
    }

        

    func setupAudioSession() {
        guard let url = url else {
            print("Reached MusicPlayerVC without a URL")
            return
        }

        print("Reached MusicPlayerVC")
        
        
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            print("Audio session setup error: \(error.localizedDescription)")
        }
    }

    func setupPlayerViewController() {
        playerViewController = AVPlayerViewController()
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.bounds


        let gradientColors = [
            UIColor.black,
            UIColor.black,
            UIColor.black
        ]

        let gradientLayer = GradientHelper.createGradientLayer(
            for: view,
            colors: gradientColors,
            startPoint: CGPoint(x: 0.0, y: 0.0),
            endPoint: CGPoint(x: 1.0, y: 1.0)
        )

        playerViewController.contentOverlayView?.layer.insertSublayer(gradientLayer, at: 0)
    }

    func setupImageView() {
        imageView = UIImageView(frame: CGRect(x: 18, y: 200, width: 360, height: 240))
        imageView?.layer.masksToBounds = true
        imageView?.layer.borderWidth = 1.5
        imageView?.layer.borderColor = UIColor.white.cgColor
        imageView?.layer.cornerRadius = 2
        imageView?.image = img
        playerViewController.contentOverlayView?.addSubview(imageView!)
    }



    func setupTitleScrollView() {
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = SongTitle!
        titleLabel.textColor = UIColor.init(hex: "#800080")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 25)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
                
       let wholeText = SongTitle! + "     "
       let textSize = (SongTitle! as NSString).size(withAttributes: [NSAttributedString.Key.font: titleLabel.font!])
       let textToAnimateSize = (wholeText as NSString).size(withAttributes: [NSAttributedString.Key.font: titleLabel.font!])
                
       let titleScrollView = UIScrollView(frame: CGRect(x: imageView!.frame.minX, y: imageView!.frame.maxY, width: 0, height: 0))
       titleScrollView.translatesAutoresizingMaskIntoConstraints = true
       titleScrollView.addSubview(titleLabel)
       playerViewController.contentOverlayView?.addSubview(titleScrollView)
        
       titleScrollView.frame = CGRectMake(imageView!.frame.minX, imageView!.frame.maxY + 10,imageView!.frame.width, 30)
     
        let totalScrollDistance = textToAnimateSize.width - titleScrollView.frame.width

        // Create an animation block to scroll to the right
        let scrollRightAnimation: () -> Void = {
            titleScrollView.contentOffset.x = totalScrollDistance + titleScrollView.frame.width
        }


        if textSize.width > titleScrollView.frame.width
       {
        titleLabel.text = SongTitle! + "     " + SongTitle!
         let scrollDuration = Double(textSize.width) / 50.0
            func scrollAnimation() {
                UIView.animate(withDuration: scrollDuration, delay: 4.0, options: [.curveLinear], animations: scrollRightAnimation) { (_) in

                    titleScrollView.contentOffset.x = titleScrollView.contentOffset.x - (totalScrollDistance + titleScrollView.frame.width)
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
        if let player = self.player
        {
            player.pause()
            self.player = nil
        }
        let asset = AVURLAsset(url: url)
        
        Task {
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
            
            let durationS = CMTimeGetSeconds(self.player.currentItem!.duration)

            updateNowPlayingInfo(title: SongTitle!, artwork: img!, time: durationS)
            updateMiniPlayer(withTitle: SongTitle!, artist: "Artist Name", albumImage: img)
            MiniPlayerView.shared.unhide()
        }
    }
    
    
    func updateNowPlayingInfo(title: String, artwork: UIImage, time:Float64) {

        let artwork = MPMediaItemArtwork(boundsSize: artwork.size) { (_) -> UIImage in
            return artwork
        }

        
        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtwork: artwork,
            MPMediaItemPropertyPlaybackDuration: time / 2
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        playerViewController.updatesNowPlayingInfoCenter = false
    }
    
    func updateMiniPlayer(withTitle title: String, artist: String, albumImage: UIImage?) {
        MiniPlayerView.shared.update(withSongTitle: title, artist: artist, albumImage: albumImage)
    }
    
}
