//
//  PlaylistVC.swift
//  MyStrain
//
//  Created by Dawid on 2.10.2023.
//

import Foundation
import UIKit

class PlaylistVC: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    var Videos = [VideoInfo]()
    var PlaylistIMG: UIImage?
    var PlaylistName: String?
    
    @IBOutlet weak var Results: UITableView!
    @IBOutlet weak var PlaylistNameUI: UILabel!
    @IBOutlet weak var PlaylistIMGUI: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Results.delegate = self
        Results.dataSource = self
        setUpUI()
    }
    
    func setUpUI()
    {
        PlaylistNameUI.text = PlaylistName!
        PlaylistIMGUI.layer.masksToBounds = true
        PlaylistIMGUI.layer.cornerRadius = 10
        PlaylistIMGUI.image = PlaylistIMG!
        PlaylistIMGUI.contentMode = .scaleToFill
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        
        let search = Videos[indexPath.row]
        
        content.text = search.title
        cell.backgroundColor = UIColor.clear
        
        let url = URL(string: "https://i.ytimg.com/vi/\(search.videoId)/hqdefault.jpg")
        
        if let imageURL = url {
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    
                    let targetSize = CGSize(width: 80, height: 80)
                    
                    let scaledImage = image.scalePreservingAspectRatio(
                        targetSize: targetSize
                    )
                    
                    DispatchQueue.main.async {
                        content.image = scaledImage
                        cell.contentConfiguration = content
                    }
                }
            }.resume()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let search = Videos[indexPath.row]
        
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.startAnimating()
        tableView.cellForRow(at: indexPath)?.accessoryView = loadingIndicator
        
        let urlString = URL(string: "https://i.ytimg.com/vi/\(search.videoId)/hqdefault.jpg")
        var img: UIImage?
        if let imageURL = urlString {
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    img = image
                }
            }.resume()
        }
        AudioManager.shared.resetQue()
        AudioManager.shared.addToQueue(id: search.videoId)
        AudioManager.shared.playNextPlaylist() {result in
            switch(result)
            {
            case(.success(_)):
                DispatchQueue.main.async {
                    AudioManager.shared.showMusciPlayer(navigation: self.navigationController!,from: "cell", videoThumbnail: img!)
                    loadingIndicator.stopAnimating()
                }
            case(.failure(let error)):
                print(error.localizedDescription)
            }
        }
        
    
    }
}
