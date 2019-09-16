//
//  File.swift
//  question
//
//  Created by ShopBack on 2019/7/28.
//  Copyright © 2019 Boring. All rights reserved.
//

import UIKit

class PaddingLabel: UILabel {

    @IBInspectable var topInset: CGFloat = 3.0
    @IBInspectable var bottomInset: CGFloat = 3.0
    @IBInspectable var leftInset: CGFloat = 3.0
    @IBInspectable var rightInset: CGFloat = 3.0

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += topInset + bottomInset
            contentSize.width += leftInset + rightInset
            return contentSize
        }
    }
}
