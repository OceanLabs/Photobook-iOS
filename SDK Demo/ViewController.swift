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
import Photobook

let baseImageURL = "https://s3.amazonaws.com/psps/sdk_static/"

let sizes: [Int: CGSize] = [1: CGSize(width: 1824, height: 1216), 10: CGSize(width: 3456, height: 2592), 11: CGSize(width: 2494, height: 1927), 12: CGSize(width: 3210, height: 2167), 13: CGSize(width: 2400, height: 1818), 14: CGSize(width: 2359, height: 2268), 15: CGSize(width: 2683, height: 2012), 16: CGSize(width: 3456, height: 2592), 17: CGSize(width: 5616, height: 3744), 18: CGSize(width: 2942, height: 2448), 19: CGSize(width: 1822, height: 2448), 2: CGSize(width: 612, height: 612), 20: CGSize(width: 2345, height: 1465), 21: CGSize(width: 3264, height: 2448), 22: CGSize(width: 3264, height: 2414), 23: CGSize(width: 3264, height: 2448), 24: CGSize(width: 5184, height: 3456), 25: CGSize(width: 3264, height: 2448), 26: CGSize(width: 1391, height: 1043), 27: CGSize(width: 3465, height: 2578), 28: CGSize(width: 2400, height: 1648), 29: CGSize(width: 3264, height: 2448), 3: CGSize(width: 843, height: 960), 30: CGSize(width: 2400, height: 1660), 31: CGSize(width: 3153, height: 2225), 32: CGSize(width: 4928, height: 3264), 33: CGSize(width: 2356, height: 1754), 34: CGSize(width: 5184, height: 3456), 35: CGSize(width: 4928, height: 3264), 36: CGSize(width: 5184, height: 3456), 37: CGSize(width: 4928, height: 3264), 38: CGSize(width: 4928, height: 3264), 39: CGSize(width: 2400, height: 1712), 4: CGSize(width: 1034, height: 1034), 40: CGSize(width: 3056, height: 2135), 41: CGSize(width: 3029, height: 2559), 42: CGSize(width: 2400, height: 1710), 43: CGSize(width: 5152, height: 3864), 44: CGSize(width: 4252, height: 2816), 45: CGSize(width: 2957, height: 4435), 46: CGSize(width: 2633, height: 2040), 47: CGSize(width: 5184, height: 3456), 48: CGSize(width: 4175, height: 2783), 49: CGSize(width: 1800, height: 1199), 5: CGSize(width: 2048, height: 1362), 50: CGSize(width: 4288, height: 2848), 6: CGSize(width: 2048, height: 1152), 7: CGSize(width: 1600, height: 1144), 8: CGSize(width: 1882, height: 2509), 9: CGSize(width: 3264, height: 2448)]

let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")
let processingOrderBackupFile = photobookDirectory.appending("ProcessingOrder.dat")

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PhotobookSDK.shared.environment = .test
        PhotobookSDK.shared.kiteApiKey = "78b798ff366815c833dfa848654aba43b71a883a"
        PhotobookSDK.shared.kiteUrlScheme = "photobookdemo78b798ff"
    }

    @IBAction func createPhotobookWithWebPhotos(_ sender: Any) {
        var assets = [PhotobookAsset]()
        
        for imageNumber in 1...20 {
            let asset = PhotobookAsset(withUrl: URL(string: baseImageURL + "\(imageNumber).jpg")!, size: sizes[imageNumber]!)
            assets.append(asset)
        }
        guard let photobookViewController = PhotobookSDK.shared.photobookViewController(with: assets, completion: { source, _ in
            source.navigationController?.popToRootViewController(animated: true)
        }) else { return }
        navigationController?.pushViewController(photobookViewController, animated: true)
    }
    
    @IBAction func launchBasketWithPDF(_ sender: Any) {
        let destinationPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/SDKDemo/")
        try? FileManager.default.createDirectory(atPath: destinationPath, withIntermediateDirectories: false, attributes: nil)
        
        let coverPdfInBundle = Bundle.main.path(forResource: "exampleCover", ofType: "pdf")!
        let coverFilePath = destinationPath.appending("exampleCover.pdf")

        let insidePdfInBundle = Bundle.main.path(forResource: "exampleInside", ofType: "pdf")!
        let insideFilePath = destinationPath.appending("exampleInside.pdf")

        try? FileManager.default.copyItem(atPath: coverPdfInBundle, toPath: coverFilePath)
        try? FileManager.default.copyItem(atPath: insidePdfInBundle, toPath: insideFilePath)
        
        let options: [String: Any] = ["finish": "matte"]
        guard let photobookProduct = PDFBookProduct(templateId: "hdbook_297x210", coverFilePath: coverFilePath, insideFilePath: insideFilePath, pageCount: 20, options: options) else {
            print("Could not create photo book product")
            return
        }
        PhotobookSDK.shared.addProductToBasket(photobookProduct)
        showBasket(sender)
    }
    
    @IBAction func clearProcessingOrder(_ sender: Any) {
        try? FileManager.default.removeItem(atPath: processingOrderBackupFile)
    }
    
    @IBAction func showBasket(_ sender: Any) {
        if let viewController = PhotobookSDK.shared.checkoutViewController(dismissClosure: { [weak welf = self] (viewController, success) in
            welf?.navigationController?.popToRootViewController(animated: true)
        }) {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
