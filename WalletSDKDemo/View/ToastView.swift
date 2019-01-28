//Copyright (c) 2019 Cybavo. All rights reserved.

import Foundation
import UIKit

class ToastView : NSObject{
    
    static var instance : ToastView = ToastView()
    
    var windows = UIApplication.shared.windows
    let rv = (UIApplication.shared.keyWindow?.subviews.first)!
    
    func showLoadingView() {
        clear()
        let frame = CGRect(x: 0, y: 0, width: 78, height: 78)
        
        let loadingContainerView = UIView()
        loadingContainerView.layer.cornerRadius = 12
        loadingContainerView.backgroundColor = UIColor(red:0, green:0, blue:0, alpha: 0.8)
        
        let indicatorWidthHeight :CGFloat = 36
        let loadingIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        loadingIndicatorView.frame = CGRect(x: frame.width/2 - indicatorWidthHeight/2, y: frame.height/2 - indicatorWidthHeight/2, width: indicatorWidthHeight, height: indicatorWidthHeight)
        loadingIndicatorView.startAnimating()
        loadingContainerView.addSubview(loadingIndicatorView)
        
        let window = UIWindow()
        window.backgroundColor = UIColor.clear
        window.frame = frame
        loadingContainerView.frame = frame
        
        window.windowLevel = UIWindow.Level.alert
        window.center = CGPoint(x: rv.center.x, y: rv.center.y)
        window.isHidden = false
        window.addSubview(loadingContainerView)
        
        windows.append(window)
        
    }
    
    func showToast(content:String , imageName:String="icon_cool", duration:CFTimeInterval=1.5) {
        print("show toast")
        clear()
        let frame = CGRect(x: 0, y: 0, width: 130, height: 60)
        
        let toastContainerView = UIView()
        toastContainerView.layer.cornerRadius = 10
        toastContainerView.backgroundColor = UIColor(red:0, green:0, blue:0, alpha: 0.7)
        
        if let image = UIImage(named: imageName) {
            let iconWidthHeight :CGFloat = 36
            let toastIconView = UIImageView(image: image)
            toastIconView.frame = CGRect(x: (frame.width - iconWidthHeight)/2, y: 15, width: iconWidthHeight, height: iconWidthHeight)
            toastContainerView.addSubview(toastIconView)
        }
        let toastContentView = UILabel(frame: CGRect(x: 0, y: 0, width: 130, height: 60))
        toastContentView.font = UIFont.systemFont(ofSize: 14)
        toastContentView.textColor = UIColor.white
        toastContentView.text = content
        toastContentView.lineBreakMode = .byWordWrapping
        toastContentView.numberOfLines = 2
        toastContentView.textAlignment = NSTextAlignment.center
        toastContainerView.addSubview(toastContentView)
        
        
        let window = UIWindow()
        window.backgroundColor = UIColor.clear
        window.frame = frame
        toastContainerView.frame = frame
        
        window.windowLevel = UIWindow.Level.alert
        window.center = CGPoint(x: rv.center.x, y: rv.center.y * 16/10)
        window.isHidden = false
        window.addSubview(toastContainerView)
        windows.append(window)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: {
            self.removeToast(window)
        })
    }
    
    func removeToast(_ window: UIWindow) {
        if let index = windows.index(of: window) {
            // print("find the window and remove it at index \(index)")
            windows.remove(at: index)
        }
    }
    
    func clear() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        windows.removeAll(keepingCapacity: false)
    }
}
