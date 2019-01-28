//Copyright (c) 2019 Cybavo. All rights reserved.

import Foundation
import Alamofire
import ObjectMapper
import AlamofireObjectMapper

let StatusOK = 200
let StatusSessionExpired = 401

class Requests {
    static func get<T: BaseMappable>(_ url: String, headers: HTTPHeaders? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) {
        Alamofire.request(Config.shared.endPoint + url, headers: headers).responseObject { (response: DataResponse<T>) in
            guard let statusCode = response.response?.statusCode else {
                completionHandler(response)
                return
            }
            
            if statusCode == StatusSessionExpired {
                Auth.shared.si
            }
            onSuccess(GetUserStateResult(userState: UserState(setPin: getUserStateResponse.setPIN)))
            
        }
    }
}
