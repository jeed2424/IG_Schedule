//
//  ApiWrapper.swift
//  LazyPublish
//
//  Created by KSun on 2021/6/8.
//  Copyright © 2021 SeanGuang. All rights reserved.
//

//
//  AFWrapperClass.swift
//  BiPocSearch
//
//  Created by Dheeraj Chauhan on 04/11/20.
//  Copyright © 2020 enAct eServices. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import NVActivityIndicatorView
import SwiftyJSON

class ApiWrapper{
    
    class func requestPOSTURL(_ strURL : String, params : Parameters, success:@escaping ([String: Any]) -> Void, failure:@escaping (NSError) -> Void){
        
        let token = UserDefaults.standard.value(forKey: Constant.Keys.token) as? String ?? ""
        let urlwithPercentEscapes = strURL.addingPercentEncoding( withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        AF.request(urlwithPercentEscapes!, method: .put, parameters: params, encoding: JSONEncoding.default, headers: ["Authorization":"Bearer \(token)","Content-Type":"application/json"])
            .responseJSON { (response) in
                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any] {
                        success(JSON)
                    }
                case .failure(let error):
                    let error : NSError = error as NSError
                    let message:String = error.localizedDescription
                    failure(error)
                    // print(failure)
                    
                }
        }
    }
    
    class func requestPOSTURLWithoutToken(_ strURL : String, params : Parameters, success:@escaping (JSON) -> Void, failure:@escaping (NSError) -> Void){
        let url =  URL(string:strURL)
        AF.request(url!, method: .post, parameters: params)
            .responseJSON { (response) in
                
                switch response.result {
                    
                case .success(let value):
                    ProgressHUD.dismiss()
                    
                    let jsonObjc = JSON(value)
                    
                    if response.response?.statusCode == 200 {
                        
                        success(jsonObjc)
                    }
                    else if response.response?.statusCode == 400 || response.response?.statusCode == 401 {
                        
//                        UserDefaults.standard.removeObject(forKey: Constant.Keys.token)
                        print(jsonObjc.error)
                        self.handle401Error()
                    }
                    
                case .failure(let error):
                    ProgressHUD.dismiss()
                    let error : NSError = error as NSError
                    print(error)
                    failure(error)
                }
        }
    }
    
    class func requestParaEncodingPOSTURL(_ strURL : String, method:HTTPMethod, params : Parameters, success: @escaping (JSON) -> Void, failure: @escaping (NSError) -> Void) {
        
        let token = UserDefaults.standard.value(forKey: Constant.Keys.token) as? String ?? ""
        let ulr =  URL(string:strURL)
        var request = URLRequest(url: ulr!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if token != "" {
            
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let data = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        
        
        if let json = json {
            
            request.httpBody = json.data(using: String.Encoding.utf8.rawValue);
        }
        AF.request(request as URLRequestConvertible).responseJSON { response in
            
            switch response.result {
                
            case .success(let value):
                
                print(response.response?.statusCode)
                let jsonObjc = JSON(value)
                
                if response.response?.statusCode == 200{
                    
                    success(jsonObjc)
                }
                else if response.response?.statusCode == 400 || response.response?.statusCode == 401 {
                    
                    UserDefaults.standard.removeObject(forKey: Constant.Keys.token)
                    self.handle401Error()
                }
                else {
                    
                    success(jsonObjc)
                }
                
            case .failure(let error):
                
                let error : NSError = error as NSError
                //   print("hhhjjh",error)
                let message:String = error.localizedDescription
                //  IJProgressView.shared.hideProgressView()
                
                failure(error)
                // print(failure)
            }
            
        }
    }
    
    
    class func requestUrlEncodedPOSTURL(_ strURL : String, params : Parameters, success:@escaping (JSON) -> Void, failure:@escaping (NSError) -> Void){
        
        let urlwithPercentEscapes = strURL.addingPercentEncoding( withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        AF.request(urlwithPercentEscapes!, method: .post, parameters: params, encoding: URLEncoding.default, headers: ["Content-Type":"application/json"])
            .responseJSON { (response) in
                
                switch response.result {
                    
                case .success(let value):
                    ProgressHUD.dismiss()
                    
                    let jsonObjc = JSON(value)
                    
                    if response.response?.statusCode == 200 {
                        
                        success(jsonObjc)
                    }
                    else if response.response?.statusCode == 400 || response.response?.statusCode == 401 {
                        
                        UserDefaults.standard.removeObject(forKey: Constant.Keys.token)
                        self.handle401Error()
                    }
                    
                case .failure(let error):
                    ProgressHUD.dismiss()
                    let error : NSError = error as NSError
                    print(error)
                    failure(error)
                }
        }
    }
    
    class func requestPOSTURLWithHeader(_ strURL : String, params : Parameters, success:@escaping ([String: Any]) -> Void, failure:@escaping (NSError) -> Void){
        
        let token = UserDefaults.standard.value(forKey: Constant.Keys.token) as? String ?? ""
        var header:HTTPHeaders?
        header  = ["Authorization":"Bearer \(token)","Content-Type": "application/json"]
        
        
        let urlwithPercentEscapes = strURL.addingPercentEncoding( withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        AF.request(urlwithPercentEscapes!, method: .post, parameters: params, encoding: JSONEncoding.prettyPrinted, headers: header)
            .response { (response) in
                
                if response.response?.statusCode == 201 {
                    
                    success([:])
                }
                else{
                    
                    switch response.result {
                    case .success(let value):
                        
                        if let JSON = value as? [String : Any] {
                            
                            success(JSON)
                        }
                        else if response.response?.statusCode == 400 || response.response?.statusCode == 401 {
                            
                            UserDefaults.standard.removeObject(forKey: Constant.Keys.token)
                            self.handle401Error()
                        }
                        else {
                            success([:])
                        }
                        
                    case .failure(let error):
                        
                        let error : NSError = error as NSError
                        //   print("hhhjjh",error)
                        let message:String = error.localizedDescription
                        //  IJProgressView.shared.hideProgressView()
                        
                        failure(error)
                        // print(failure)
                    }
                    
                }
        }
    }
    
    class func handle401Error() {
        
        let message = "Your sessions has been expired. Please login again."
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action) in
                
                ProgressHUD.dismiss()
                UserDefaults.standard.removeObject(forKey: Constant.Keys.token)
                //                let vc = UIStoryboard(name: kAuthStoryboardIdentifier, bundle: nil).instantiateViewController(withIdentifier: "AuthWelcomeVC") as! AuthWelcomeVC
                //                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                
            }))
            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
        }
    }
}
extension UIApplication {
    
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
