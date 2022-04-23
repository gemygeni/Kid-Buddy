//
//  extensios.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 9/4/21.
//

import UIKit
import CoreLocation
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
    
      func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
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
                else{
                    self.image = #imageLiteral(resourceName: "person.png")
                }
            })
            
        }).resume()
       }
    }
}

extension NSNumber {
   func convertDateFormatter() -> String {
        
    let timeBySeconds = self.doubleValue
            let date = Date(timeIntervalSince1970: timeBySeconds)
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "MM-dd  HH:mm a"
               let dateString = formatter.string(from: date)
            
            return dateString
           }
    //    let s = String(format: "%@,%f,%f,%@\n", dateString, locValue.latitude, locValue.longitude, self.currentDevice)
  
}
extension Date{
    func convertDateFormatter() -> String {
             let formatter = DateFormatter()
             formatter.timeZone = TimeZone.current
             formatter.dateFormat = "MM-dd            HH:mm a"
                let dateString = formatter.string(from: self)
             return dateString
            }
}


extension CLPlacemark {
  var abbreviation: String {
    if let name = self.name {
      return name
    }

    if let interestingPlace = areasOfInterest?.first {
      return interestingPlace
    }

    return [subThoroughfare, thoroughfare].compactMap { $0 }.joined(separator: " ")
  }
}

extension UITableView {

    func reloadWithoutAnimation() {
        let lastScrollOffset = contentOffset
        beginUpdates()
        endUpdates()
        layer.removeAllAnimations()
        setContentOffset(lastScrollOffset, animated: false)
    }
    
    
    public func reloadDataAndKeepOffset() {
        // stop scrolling
        setContentOffset(contentOffset, animated: false)
            
        // calculate the offset and reloadData
        let beforeContentSize = contentSize
        reloadData()
        layoutIfNeeded()
        let afterContentSize = contentSize
            
        // reset the contentOffset after data is updated
        let newOffset = CGPoint(
            x: contentOffset.x + (afterContentSize.width - beforeContentSize.width),
            y: contentOffset.y + (afterContentSize.height - beforeContentSize.height))
        setContentOffset(newOffset, animated: false)
    }
    
    func scrollToBottomRow() {
        DispatchQueue.main.async {
            guard self.numberOfSections > 0 else { return }

            // Make an attempt to use the bottom-most section with at least one row
            var section = max(self.numberOfSections - 1, 0)
            var row = max(self.numberOfRows(inSection: section) - 1, 0)
            var indexPath = IndexPath(row: row, section: section)

            // Ensure the index path is valid, otherwise use the section above (sections can
            // contain 0 rows which leads to an invalid index path)
            while !self.indexPathIsValid(indexPath) {
                section = max(section - 1, 0)
                row = max(self.numberOfRows(inSection: section) - 1, 0)
                indexPath = IndexPath(row: row, section: section)

                // If we're down to the last section, attempt to use the first row
                if indexPath.section == 0 {
                    indexPath = IndexPath(row: 0, section: 0)
                    break
                }
            }

            // In the case that [0, 0] is valid (perhaps no data source?), ensure we don't encounter an
            // exception here
            guard self.indexPathIsValid(indexPath) else { return }

            self.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }

    func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        let section = indexPath.section
        let row = indexPath.row
        return section < self.numberOfSections && row < self.numberOfRows(inSection: section)
    }



    
    func scrollToBottom(animated: Bool) {
        guard let dataSource = dataSource else { return }
        var lastSectionWithAtLeastOneElement = (dataSource.numberOfSections?(in: self) ?? 1) - 1
        while dataSource.tableView(self, numberOfRowsInSection: lastSectionWithAtLeastOneElement) < 1 && lastSectionWithAtLeastOneElement > 0 {
            lastSectionWithAtLeastOneElement -= 1
        }
        let lastRow = dataSource.tableView(self, numberOfRowsInSection: lastSectionWithAtLeastOneElement) - 1
        guard lastSectionWithAtLeastOneElement > -1 && lastRow > -1 else { return }
        let bottomIndex = IndexPath(item: lastRow, section: lastSectionWithAtLeastOneElement)
        scrollToRow(at: bottomIndex, at: .bottom, animated: animated)
    }

    
    
} 
