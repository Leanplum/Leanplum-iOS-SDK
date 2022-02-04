//
//  UIImage+Close.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 4.2.22..
//

import Foundation

extension UIImage {
    
    private static var diameter: CGFloat {
        32.0
    }
    
    private static var lineWidth: CGFloat {
        1.5
    }
    
    private static var backgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGray2
        } else {
            return .gray
        }
    }
    
    private static var strokeColor: UIColor {
        .black
    }
    
    
    static var closeImage: UIImage? {
        let size: CGSize = .init(width: diameter, height: diameter)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.saveGState()
        
        let rect = CGRect(origin: .zero, size: size)
        context.setFillColor(backgroundColor.cgColor)
        context.fillEllipse(in: rect)
        
        let margin: CGFloat = diameter * 2 / 3
        
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(lineWidth)
        context.move(to: .init(x: margin, y: margin))
        context.addLine(to: .init(x: diameter - margin, y: diameter - margin))
        context.move(to: .init(x: diameter - margin, y: margin))
        context.addLine(to: .init(x: margin, y: diameter - margin))
        context.strokePath()
        
        context.restoreGState()
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        return image
    }
}
