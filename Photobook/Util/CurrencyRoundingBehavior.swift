//
//  CurrencyRoundingBehavior.swift
//  Photobook
//
//  Created by Jaime Landazuri on 05/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

class CurrencyRoundingBehavior: NSDecimalNumberBehaviors {
    
    func roundingMode() -> NSDecimalNumber.RoundingMode {
        return .plain
    }
    
    func scale() -> Int16 {
        return 2
    }
    
    func exceptionDuringOperation(_ operation: Selector, error: NSDecimalNumber.CalculationError, leftOperand: NSDecimalNumber, rightOperand: NSDecimalNumber?) -> NSDecimalNumber? {
        
        return nil
    }
}
