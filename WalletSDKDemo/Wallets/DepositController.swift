//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet
import Toast_Swift
import Photos

class DepositController : UIViewController {
    @IBOutlet weak var currencyView: CurrencyView!
    @IBOutlet weak var qrcodeImageView: UIImageView!
    @IBOutlet weak var walletAddressLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UITextView!
    
    var qrcodeImage: CIImage?
    var wallet: Wallet?
    
    override func viewDidLoad() {
        if let wallet = wallet {
            currencyView.setSymbol(wallet.currencySymbol)
            
            let data = wallet.address.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
            
            let filter = CIFilter(name: "CIQRCodeGenerator")
            
            filter?.setValue(data, forKey: "inputMessage")
            filter?.setValue("Q", forKey: "inputCorrectionLevel")
            
            walletAddressLabel.text = wallet.address
            descriptionLabel.text = "Send only \(wallet.currencySymbol) to this deposit address. Sending any other coin or token to the address may result in the loss of your deposit"
            if let sourceImage = filter?.outputImage {
                let scaleX = 200 / sourceImage.extent.size.width
                let scaleY = 200 / sourceImage.extent.size.height
                let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                qrcodeImage = sourceImage.transformed(by: transform)
                if let image = qrcodeImage {
                    qrcodeImageView.image = UIImage(ciImage: image)
                }
            }
        }
    }
    @IBAction func onCopyAddress(_ sender: Any) {
        if let wallet = wallet {
            UIPasteboard.general.string = wallet.address
            self.view.makeToast("Address copied", duration: 1.0)
        }
    }
    @IBAction func onSaveQRCode(_ sender: Any) {
        let context = CIContext(options: nil)
        if let ciImage = qrcodeImage, let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let newImage = UIImage(cgImage: cgImage)
            UIImageWriteToSavedPhotosAlbum(newImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil);
        }
        
    }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("didFinishSavingWithError \(error.localizedDescription)")
        } else {
            self.view.makeToast("QR code saved", duration: 1.0)
        }
    }
}
