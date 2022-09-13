//
//  AnnotationView.swift
//  Paddle
//
//  Created by Jack Finnis on 13/09/2022.
//

import MapKit
import UIKit

class AnnotationView: MKAnnotationView {
    var imageView = UIImageView()
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        
        if let feature = annotation as? Feature {
            imageView.removeFromSuperview()
            backgroundColor = nil
            
            let color = UIColor(feature.type.color)
            if feature.type == .lock {
                let config = UIImage.SymbolConfiguration(font: .boldSystemFont(ofSize: 20))
                let image = UIImage(systemName: "chevron.left", withConfiguration: config)
                imageView = UIImageView(image: image?.withTintColor(color, renderingMode: .alwaysOriginal))
                imageView.transform = CGAffineTransform(rotationAngle: feature.angle * .pi/180)
                imageView.contentMode = .scaleAspectFit
                imageView.center = CGPoint(x: bounds.width/2, y: bounds.height/2)
                addSubview(imageView)
            } else {
                backgroundColor = color
            }
            
            frame.size.width = 12
            frame.size.height = frame.size.width
            layer.cornerRadius = frame.size.width/2
            displayPriority = .required
            canShowCallout = true
            
            let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: SIZE/2))
            let editBtn = UIButton()
            let editImg = UIImage(systemName: "pencil", withConfiguration: config)
            editBtn.setImage(editImg, for: .normal)
            editBtn.frame.size = CGSize(width: SIZE, height: SIZE)
            leftCalloutAccessoryView = editBtn
            
            let openBtn = UIButton()
            let openImg = UIImage(systemName: "arrow.triangle.turn.up.right.circle", withConfiguration: config)
            openBtn.setImage(openImg, for: .normal)
            openBtn.frame.size = CGSize(width: SIZE, height: SIZE)
            rightCalloutAccessoryView = openBtn
        }
    }
}
