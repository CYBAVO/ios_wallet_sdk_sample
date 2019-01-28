//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet

class CurrencyView : UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var currencyIcon: UIImageView!
    @IBOutlet var currencyLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    func setSymbol(_ symbol: String){
        currencyIcon.image = UIImage(named: symbol.replacingOccurrences(of: "-", with: "_").lowercased())
        currencyLabel.text = symbol
    }

    func setupSubviews() {
        Bundle.main.loadNibNamed("CurrencyView", owner: self, options:
            nil)
        contentView.fixInView(self)
    }
}

extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}

