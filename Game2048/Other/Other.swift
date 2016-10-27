//
//  ViewControllerExtensions.swift
//  SportCarClient
//
//  Created by 黄延 on 16/1/10.
//  Copyright © 2016年 WoodyHuang. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /**
     弹出一个一段时间之后自动消失的对话框
     
     - parameter message:       显示的文字内容
     - parameter maxLastLength: 最大显示的时长
     */
    func showToast(_ message: String, maxLastLength: Double=2, onSelf: Bool = false) {
        assert(Thread.isMainThread)
        let superview = onSelf ? self.view! : UIApplication.shared.keyWindow!.rootViewController!.view!
        //        let superview = self.view
        
        let messageHeight: CGFloat = (message as NSString).boundingRect(with: CGSize(width: 170, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)], context: nil).height
        
        let toastContainer = UIView()
        toastContainer.backgroundColor = UIColor(red: 0.067, green: 0.051, blue: 0.051, alpha: 1)
        toastContainer.layer.addDefaultShadow(6, opacity: 0.3, offset: CGSize(width: 0, height: 4))
        toastContainer.clipsToBounds = false
        superview.addSubview(toastContainer)
        superview.bringSubview(toFront: toastContainer)
        toastContainer.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(superview)
            make.bottom.equalTo(superview.snp.top)
            make.size.equalTo(CGSize(width: 200, height: messageHeight + 30))
        }
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.lineBreakMode = .byCharWrapping
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = UIColor.white
        lbl.textAlignment = .center
        toastContainer.addSubview(lbl)
        lbl.text = message
        lbl.snp.makeConstraints { (make) -> Void in
            //            make.edges.equalTo(toastContainer)
            make.center.equalTo(toastContainer)
            make.size.equalTo(CGSize(width: 170, height: messageHeight))
        }
        //
        superview.layoutIfNeeded()
        toastContainer.snp.remakeConstraints { (make) -> Void in
            make.centerX.equalTo(superview)
            make.top.equalTo(superview).offset(40 + 44)
            make.size.equalTo(CGSize(width: 200, height: messageHeight + 30))
        }
        UIView.animate(withDuration: 0.3, delay: maxLastLength, options: [], animations: { () -> Void in
            toastContainer.snp.remakeConstraints { (make) -> Void in
                make.centerX.equalTo(superview)
                make.bottom.equalTo(superview.snp.top)
                make.size.equalTo(CGSize(width: 200, height: messageHeight + 30))
            }
            superview.layoutIfNeeded()
        }) { (_) -> Void in
            toastContainer.removeFromSuperview()
        }
    }
    
    
    func hideToast(_ toast: UIView) {
        if toast.tag == 0 {
            UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: { () -> Void in
                toast.layer.opacity = 0
            }) { (_) -> Void in
                toast.removeFromSuperview()
            }
        } else {
            let bg = toast.subviews[0]
            let t = toast.subviews[1]
            t.snp.remakeConstraints({ (make) in
                make.centerX.equalTo(toast.superview!)
                make.top.equalTo(toast.superview!.snp.bottom).offset(30)
                make.width.equalTo(250)
                make.height.equalTo(150)
            })
            UIView.animate(withDuration: 0.3, animations: {
                bg.layer.opacity = 0
                toast.superview?.layoutIfNeeded()
                }, completion: { (_) in
                    toast.removeFromSuperview()
            })
        }
    }
}

extension CALayer {
    func addDefaultShadow(
        _ blur: CGFloat = 2,
        color: UIColor = UIColor.black,
        opacity: Float = 0.4,
        offset: CGSize = CGSize(width: 0, height: 3)
        ) {
        self.shadowRadius = blur
        self.shadowColor = color.cgColor
        self.shadowOpacity = opacity
        self.shadowOffset = offset
    }
}


