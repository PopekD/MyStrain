//
//  GradientHelper.swift
//  MyStrain
//
//  Created by Dawid on 18.9.2023.
//

import Foundation
import UIKit

class GradientHelper {
    static func createGradientLayer(for view: UIView, colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        return gradientLayer
    }
}
