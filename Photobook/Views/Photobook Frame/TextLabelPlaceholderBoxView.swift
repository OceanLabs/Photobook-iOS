//
//  TextLabelPlaceholderBoxView.swift
//  Photobook
//
//  Created by Jaime Landazuri on 23/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class TextLabelPlaceholderBoxView: UIView {
    var color: ProductColor = .white
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let lineColor: CGColor
        
        switch color {
        case .white:
            lineColor = UIColor.darkText.cgColor
        case .black:
            lineColor = UIColor.lightText.cgColor
        }
        
        // Pages behind
        context.setStrokeColor(lineColor)
        context.setLineWidth(0.5)
        
        context.move(to: CGPoint(x: 0.0, y: rect.maxY * 0.5 - 1.0))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.5 - 1.0))
        context.move(to: CGPoint(x: 0.0, y: rect.maxY * 0.5 + 1.0))
        context.addLine(to: CGPoint(x: rect.maxX * 0.8, y: rect.maxY * 0.5 + 1.0))
        
        context.strokePath()
    }
}

