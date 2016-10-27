//
//  ColorProvider.swift
//  Game2048
//
//  Created by 黄延 on 2016/10/25.
//  Copyright © 2016年 黄延. All rights reserved.
//

import UIKit

extension UIColor {
    static func RGB(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> UIColor {
        return UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a / 100)
    }
    
    static func RGB(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        return UIColor.RGB(r: r, g: g, b: b, a: 100)
    }
}


protocol ColorProvider {
    func colorForValue(_ val: Int) -> UIColor
    func boardBackgroundColor() -> UIColor
    func tileBackgroundColor() -> UIColor
    func textColorForVal(_ val: Int) -> UIColor
}

class DefaultColorProvider: ColorProvider {
    private var colorMap: [Int: UIColor] = [
        2: UIColor.RGB(r: 240, g: 240, b: 240),
        4: UIColor.RGB(r: 237, g: 224, b: 200),
        8: UIColor.RGB(r: 242, g: 177, b: 121),
        16: UIColor.RGB(r: 245, g: 149, b: 99),
        32: UIColor.RGB(r: 246, g: 124, b: 95),
        64: UIColor.RGB(r: 246, g: 94, b: 59)
    ]
    
    func colorForValue(_ val: Int) -> UIColor {
        if let result = colorMap[val] {
            return result
        } else {
//            fatalError()
            return UIColor.red
        }
    }
    
    func textColorForVal(_ val: Int) -> UIColor {
        if val >= 256 {
            return UIColor.white
        } else {
            return UIColor.black
        }
    }
    
    func tileBackgroundColor() -> UIColor {
        return UIColor.RGB(r: 204, g: 192, b: 180)
    }
    
    func boardBackgroundColor() -> UIColor {
        return UIColor.RGB(r: 185, g: 171, b: 160)
    }
}

