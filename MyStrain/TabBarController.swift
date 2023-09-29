//
//  TabBarController.swift
//  MyStrain
//
//  Created by Dawid on 23.9.2023.
//

import Foundation
import UIKit


class TabBarController: UITabBarController {
    let miniPlayerViewHeight: CGFloat = 70
    let miniPlayerView = MiniPlayerView.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        miniPlayerView.frame = CGRect(x: 0,
                                      y: (tabBar.frame.minY - (tabBar.frame.maxY - tabBar.frame.minY) - 55),
                                      width: view.frame.width,
                                      height: miniPlayerViewHeight)
        miniPlayerView.backgroundColor = UIColor.black.withAlphaComponent(0.80)
        view.addSubview(miniPlayerView)
    }
}

