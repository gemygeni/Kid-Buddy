//
//  extensios.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 9/4/21.
//

import UIKit
import CoreLocation
// MARK: - UIViewController extension
extension UIViewController {
    // MARK: extension var to get contents of ViewController if it embedded in NavigationController.
    var contents: UIViewController {
        if let VC = self as? UINavigationController {
            return VC.visibleViewController ?? self
        } else {
            return self
        }
    }
    // MARK: extension var to get root ViewController of NavigationController.
    var rootViewController: UIViewController {
        if let VC = self as? UINavigationController {
            return VC.viewControllers.first ?? self
        } else {
            return self
        }
    }
    // MARK: function to show Alert with given title and body.
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true) {
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                self.dismiss(animated: true, completion: nil)
            }
            print("Debug: present Alert Done")
        }
    }
}

// MARK: - UIImage extension.
extension UIImage {
    // MARK: function to resize image with given width and height.
    func resize(_ width: CGFloat, _ height: CGFloat) -> UIImage? {
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

let imageCache = NSCache<NSString, AnyObject>()
// MARK: - UIImageView extension.
extension UIImageView {
    // MARK: function to load and cache image to imageview from specific url
    func loadImageUsingCacheWithUrlString(_ urlString: String) {
        self.image = nil
        // check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }

        // otherwise fire off a new download
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
                // download hit an error so lets return out
                if let error = error {
                    print(error)
                    return
                }
                DispatchQueue.main.async(execute: {
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                        self.image = downloadedImage
                    } else {
                        self.image = #imageLiteral(resourceName: "person.png")
                    }
                })
            })
            .resume()
        }
    }

    // MARK: function to enable zooming to imageview's image.
    func enableZoom() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(startZooming(_:)))
        isUserInteractionEnabled = true
        addGestureRecognizer(pinchGesture)
    }

    @objc private func startZooming(_ sender: UIPinchGestureRecognizer) {
        let scaleResult = sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale)
        guard let scale = scaleResult, scale.a > 1, scale.d > 1 else { return }
        sender.view?.transform = scale
        sender.scale = 1
    }
}

// MARK: - NSNumber extension.
extension NSNumber {
    // MARK: function to convert timestamp number to date format.
    func convertDateFormatter() -> String {
        let timeBySeconds = self.doubleValue
        let date = Date(timeIntervalSince1970: timeBySeconds)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MM-dd  HH:mm a"
        let dateString = formatter.string(from: date)
        return dateString
    }
}

// MARK: - NSNumber extension.
extension Date {
    // MARK: function to convert date format to string.
    func convertDateFormatter() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MM-dd            HH:mm a"
        let dateString = formatter.string(from: self)
        return dateString
    }

    // MARK: function to Return the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
}

// MARK: - UITableView extension.
extension UITableView {
    // MARK: function to reload tableview with keeping the offset.
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

    // MARK: function to scroll down to last row of tableview .
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

            self.scrollToRow(at: indexPath, at: .none, animated: false)
        }
    }
    // MARK: function to chack if the indexpath of scrolling row of tableview is vaild .
    func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        let section = indexPath.section
        let row = indexPath.row
        return section < self.numberOfSections && row < self.numberOfRows(inSection: section)
    }
}

// MARK: extension function to download the URL into the data using the extension from UNNotificationAttachment. And save it in UserDefaults.
extension UNNotificationAttachment {
    static func download(imageFileIdentifier: String, data: Data, options: [NSObject: AnyObject]?)
    -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        if let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.Trackids.extension") {
            do {
                let newDirectory = directory.appendingPathComponent("Images")
                if !fileManager.fileExists(atPath: newDirectory.path) {
                    try? fileManager.createDirectory(at: newDirectory, withIntermediateDirectories: true, attributes: nil)
                }
                let fileURL = newDirectory.appendingPathComponent(imageFileIdentifier)
                do {
                    try data.write(to: fileURL, options: [])
                } catch {
                    print("Unable to load data: \(error)")
                }
                let pref = UserDefaults(suiteName: "group.Trackids.extension")
                pref?.set(data, forKey: "NOTIF_IMAGE")
                pref?.synchronize()
                let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: options)
                return imageAttachment
            } catch let error {
                print("Error: \(error)")
            }
        }
        return nil
    }
}
