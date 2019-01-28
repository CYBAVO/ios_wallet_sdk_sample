//Copyright (c) 2019 Cybavo. All rights reserved.

import Foundation
import UIKit

class NavigationHelper {
    static func back(from viewControlller : UIViewController) {
        back(1, from: viewControlller)
    }
    static func back(_ num: Int, from viewControlller : UIViewController) {
        for i in 0..<(viewControlller.navigationController?.viewControllers.count)! {
            if viewControlller.navigationController?.viewControllers[i] == viewControlller {
                _ = viewControlller.navigationController?.popToViewController(viewControlller.navigationController?.viewControllers[safe: i-num] ?? viewControlller, animated: true)
                break
            }
        }
    }
}
