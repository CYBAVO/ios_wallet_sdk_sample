//
//  SignInInfo.swift
//  WalletSDKDemo
//
//  Created by Eva Hsu on 2020/6/12.
//  Copyright © 2020 Cybavo. All rights reserved.
//

import Foundation
open class Identity : NSObject{
   public var idToken: String = ""
   public var provider: String = ""
   public var name: String = ""
   public var email: String = ""
   public var avatar: String = ""
}
