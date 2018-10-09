//
//  ArrayExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

extension Array {
    
    /// Move the value from and to the specified indices of the collection.
    ///
    /// Both parameters must be valid indices of the collection that are not
    /// equal to `endIndex`. Calling `moveTo(_:_:)` with the same index as both
    /// `i` and `j` has no effect.
    ///
    /// - Parameters:
    ///   - i: The index to move the value from.
    ///   - j: The index to move the value to.
    public mutating func move(_ i: Int, to j: Int){
        
        let itemToMove = self[i]
        self.remove(at: i)
        self.insert(itemToMove, at: j)
    }
    
}
