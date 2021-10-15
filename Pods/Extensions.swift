//
//  extensios.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 9/4/21.
//

import UIKit
extension UIViewController {
    var contents : UIViewController {
        if let VC = self as? UINavigationController {
            return VC.visibleViewController ?? self
        }
        else {
            return self
        }
    }
    var rootViewController : UIViewController {
        if let VC = self as? UINavigationController{
            return VC.viewControllers.first ?? self
        }
        else {
            return self
        }
    }
}


extension UIImage {
    func applyBlurEffect()-> UIImage {
        let imageToBlur = CIImage(image: self)
        let filter =  CIFilter(name: "CIGaussianBlur")
        filter?.setValue(imageToBlur, forKey: "inputImage")
        filter?.setValue(5, forKey: "inputRadius")
        let resultImage = filter?.value(forKey: "outputImage") as? CIImage
        let blurredImage = UIImage(ciImage: resultImage!)
        return blurredImage
    }
    
        func resize(_ width: CGFloat, _ height:CGFloat) -> UIImage? {
            let widthRatio  = width / size.width
            let heightRatio = height / size.height
            let ratio = widthRatio > heightRatio ? heightRatio : widthRatio
            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            self.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
    

}

//caching image
let imageCache = NSCache<NSString , AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(_ urlString: String) {
        self.image = nil
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        //otherwise fire off a new download
        if let url = URL(string: urlString){
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            //download hit an error so lets return out
            if let error = error {
                print(error)
                return
            }
            DispatchQueue.main.async(execute: {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                    self.image = downloadedImage
                }
            })
            
        }).resume()
       }
    }
}

