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

enum PigError: Error {
    case parsing
}

// Utilities to deal with PIG images
class Pig {
    
    static var apiClient = APIClient.shared
    
    /// Uploads an image to PIG
    ///
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - completion: Completion block returning a URL or an error
    static func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        
        apiClient.uploadImage(image, imageName: "OrderSummaryPreviewImage.png") { result in
            if case .failure(let error) = result {
                completion(.failure(error))
                return
            }
            let json = try! result.get()
            
            guard let dictionary = json as? [String: AnyObject], let url = dictionary["full"] as? String else {
                print("Pig: Couldn't parse URL of uploaded image")
                completion(.failure(PigError.parsing))
                return
            }
            completion(.success(url))
        }
    }

    
    /// Generates the PIG URL of the preview image
    ///
    /// - Parameters:
    ///   - baseUrlString: The URL of the background image to use
    ///   - coverUrlString: The cover image or subject
    ///   - size: The required size for the resulting image
    /// - Returns: The URL of the preview image
    static func previewImageUrl(withBaseUrlString baseUrlString: String, coverUrlString: String, size: CGSize) -> URL? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        let urlString = baseUrlString + "&image=" + coverUrlString + "&size=\(width)x\(height)" + "&fill_mode=match"
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            return nil
        }
        
        return url
    }

    /// Fetches a composite image from PIG
    ///
    /// - Parameters:
    ///   - url: The URL of the preview image
    ///   - completion: Completion block returning an image
    static func fetchPreviewImage(with url: URL, completion: @escaping (UIImage?) -> Void) {
        apiClient.downloadImage(url) { result in
            let image = try? result.get()
            completion(image)
        }
    }
}
