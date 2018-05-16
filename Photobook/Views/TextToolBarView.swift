//
//  TextToolBarView.swift
//  Photobook
//
//  Created by Jaime Landazuri on 01/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

@objc protocol TextToolBarViewDelegate {
    func didSelectFontType(_ type: FontType)
}

class TextToolBarView: UIView {
    
    @IBOutlet private var toolButtons: [UIButton]! {
        didSet { toolButtons.first?.isSelected = true }
    }
    private var selectedIndex = 0
    
    weak var delegate: TextToolBarViewDelegate?
    
    private func buttonIndex(for fontType: FontType) -> Int {
        switch fontType {
        case .plain: return 0
        case .classic: return 1
        case .solid: return 2
        }
    }
    
    private func select(index: Int) {
        guard selectedIndex != index else { return }
        
        toolButtons[selectedIndex].isSelected = false
        toolButtons[index].isSelected = true
        selectedIndex = index
    }
    
    func select(fontType: FontType) {
        let index = buttonIndex(for: fontType)
        select(index: index)
    }
    
    @IBAction func tappedToolButton(_ sender: UIButton) {
        let index = toolButtons.index(of: sender)!
        select(index: index)
        
        let fontType = FontType(rawValue: index)!
        delegate?.didSelectFontType(fontType)
    }
}
