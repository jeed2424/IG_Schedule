//
//  Post.swift
//  LazyPublish
//
//  Created by KSun on 2021/3/21.
//  Copyright © 2021 SeanGuang. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper
import SwiftyJSON

struct Post : Codable{
    // User property
    var id: String!
    var isVideo: Bool = false
    var isMultiple: Bool?
    var thumbailImage: String?
    var mediaType: String = "PICTURE"
    var caption: String?
    var time: Date?
    var uid: String?
    var instagramAccountId: String?
    var latitude: Float?
    var longitude: Float?
    var tags: [String]?
    var media: [String]?
    var published: Bool = false
    init(post:JSON) {
        //        self.isActive         = post["isActive"].bool
        self.mediaType = post["mediaType"].string!
        self.caption = post["caption"].string
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ssZ"
        let date = dateFormatter.date(from:post["time"].string!)!
        self.time = date
   
        self.uid = post["uuid"].string!
        self.instagramAccountId = post["instagramAcctId"].string!
        self.longitude = post["longitude"].float
        self.latitude = post["latitude"].float
        self.tags = post["tags"].arrayObject as? [String]
        self.media = post["media"].arrayObject as? [String]
        self.thumbailImage = self.mediaType == "VIDEO" ? post["thumbnail"].string : self.media![0]
        self.isMultiple = self.media?.count == 1 ? false : true
        
        self.published = post["published"].bool!
    }
    
    //    func retunJSON() -> JSON{
    //        var dic: [String: Any] = [String: Any]()
    //        dic["name"] = self.name
    //        dic["username"] = self.username
    //        dic["profileImage"] = self.profileImage
    //        dic["id"] = self.id
    //        dic["isActive"] = self.isActive
    //        return JSON(dic)
    //    }
}
