//
//  ServerApi.swift
//  LazyPublish
//
//  Created by KSun on 2021/6/8.
//  Copyright © 2021 SeanGuang. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
struct AppUrls {
    static let baseUrl = "https://us-central1-lazypublish.cloudfunctions.net/api/v1/"
    static let registerIGAccounts = baseUrl + "register"
    static let scheduleIGPosts = baseUrl + "schedule"
    static let updateIGPosts = baseUrl + "update-schedule"
    static let removeIGPosts = baseUrl + "remove-schedule"
}
class ServerApi {
    static let shared = ServerApi()
    // Get Popular Songs From Database
    func registerIGAccounts(param: [String: Any], success: @escaping([User]) -> Void, failure: @escaping(JSON) -> Void){
        var result = [User]()
        ApiWrapper.requestPOSTURLWithoutToken(AppUrls.registerIGAccounts, params: param, success: { (response) in
            guard let datum  = JSON(response)["instagramAccts"].array else {
                failure(JSON(response))
                return
            }
            for data in datum {
                result.append(User.init(instagramAcc: data))
            }
            if result.count == 0 {
                failure(JSON(response))
            }else{
                success(result)
            }
        }, failure: { (err) in
            let err = JSON(err)
            print(err)
            failure(err)
        })
    }
    
    func scheduleIGPosts(param: [String: Any], success: @escaping(JSON) -> Void, failure: @escaping(JSON) -> Void) {
        ApiWrapper.requestPOSTURLWithoutToken(AppUrls.scheduleIGPosts, params: param, success: {(response) in
            print(JSON(response))
            success(JSON(response))
        }, failure: { (error) in
            let err = JSON(error)
            print(err)
            failure(err)
        })
    }
    
    func updateIGPosts(param: [String: Any], success: @escaping(JSON) -> Void, failure: @escaping(JSON) -> Void) {
        ApiWrapper.requestPOSTURLWithoutToken(AppUrls.updateIGPosts, params: param, success: {(response) in
            print(JSON(response))
            success(JSON(response))
        }, failure: { (error) in
            let err = JSON(error)
            print(err)
            failure(err)
        })
    }
    func removeIGPost(param: [String: Any], success: @escaping(JSON) -> Void, failure: @escaping(JSON) -> Void) {
        ApiWrapper.requestPOSTURLWithoutToken(AppUrls.removeIGPosts, params: param, success: {(response) in
            print(JSON(response))
            success(JSON(response))
        }, failure: { (error) in
            let err = JSON(error)
            print(err)
            failure(err)
        })
    }}
