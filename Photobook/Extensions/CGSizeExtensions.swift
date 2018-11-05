//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

extension CGSize {
    
    func resizeAspectFill(_ targetSize: CGSize) -> CGSize {
        let sourceAspectRatio = self.width / self.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        if sourceAspectRatio >= targetAspectRatio {
            return CGSize(width: targetSize.height * sourceAspectRatio, height: targetSize.height)
        }
        return CGSize(width: targetSize.width, height: targetSize.width / sourceAspectRatio)
    }

    static func * (size: CGSize, scalar: CGFloat) -> CGSize {
        return CGSize(width: size.width * scalar, height: size.height * scalar)
    }    
    static func * (scalar: CGFloat, size: CGSize) -> CGSize { return size * scalar }

    static func * (size: CGSize, scalar: Double) -> CGSize { return size * CGFloat(scalar) }
    static func * (scalar: Double, size: CGSize) -> CGSize { return size * scalar }

    static func ==~(lhs: CGSize, rhs: CGSize) -> Bool {
        return (abs(lhs.width - rhs.width) <= CGFloat.minPrecision) &&
                (abs(lhs.height - rhs.height) <= CGFloat.minPrecision)
    }
}
