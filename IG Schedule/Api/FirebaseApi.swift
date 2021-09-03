//
//  FirebaseApi.swift
//  LazyPublish
//
//  Created by KSun on 2021/6/8.
//  Copyright © 2021 SeanGuang. All rights reserved.
//

import Foundation
import SwiftyJSON
import Firebase
import FirebaseFirestore

// CH: CompletionHandler
typealias createUserCH = (Error?) -> Void
typealias scheduledPostsComplestionHandler = ([Post]?, Error?) -> Void
typealias getPostsByDateCompletionHandler = ([String:[Post]]?, Error?) -> Void
typealias igAccountsCompletionHandler = ([User]?, Error?) -> Void
typealias updateIGAccoutsCompletionHandler = (Error?) ->Void
class FirebaseApi {
    static let shared = FirebaseApi()
    private let db = Firestore.firestore()
    
    func getPosts(completionHandler: scheduledPostsComplestionHandler? = nil){
        var postedFeeds: [Post] = [Post]()
        var unpostedFeeds: [Post] = [Post]()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        AuthManager.shared.loadUser()
        guard let currentIGId = AuthManager.shared.currentUser?.id else {
            print("There is no IG Account")
            return
        }
        let collection = Firestore.firestore().collection("posts").order(by: "timeStamp", descending: true).whereField("uuid", isEqualTo: uid).whereField("instagramAcctId", isEqualTo: currentIGId)
        ProgressHUD.show()
        collection.getDocuments(completion: { (querySnapshot, err) in
            ProgressHUD.dismiss()
            if let err = err {
                completionHandler?(nil, err)
                print("Failed to fetch messages:", err)
                return
            }
            querySnapshot?.documents.forEach({ (doc) in
                let data = JSON(doc.data())
                let id = doc.documentID
                var post: Post = Post(post: data)
                post.id = id
                if post.published {
//                    postedFeeds.append(post)
                } else {
                    unpostedFeeds.append(post)
                }
            })
//            unpostedFeeds.append(contentsOf: postedFeeds)
            completionHandler?(unpostedFeeds,nil)
            return
        })
    }
    
    func getPostsByDate(completionHandler: getPostsByDateCompletionHandler? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        AuthManager.shared.loadUser()
        guard let currentIGId = AuthManager.shared.currentUser?.id else {
            print("There is no IG Account")
            return
        }
        var postsByDate: [String:[Post]] = [String:[Post]]()
        let collection = Firestore.firestore().collection("posts").whereField("uuid", isEqualTo: uid).whereField("published", isEqualTo: false).whereField("instagramAcctId", isEqualTo: currentIGId).order(by: "time", descending: false)
        ProgressHUD.show()
        collection.getDocuments(completion: { (querySnapshot, err) in
            ProgressHUD.dismiss()
            if let err = err {
                completionHandler?(nil, err)
                print("Failed to fetch messages:", err)
                return
            }
            querySnapshot?.documents.forEach({ (doc) in
                let data = JSON(doc.data())
                let id = doc.documentID
                var post: Post = Post(post: data)
                post.id = id
                
                let formatter1 = DateFormatter()
//                formatter1.dateStyle = .short
                formatter1.dateFormat = "E d MMM"
                let timeStr = formatter1.string(from: post.time!)
                print(timeStr)
                if var posts = postsByDate[timeStr] {
                    posts.append(post)
                    postsByDate[timeStr] = posts
                } else {
                    var postArray:[Post] = [Post]()
                    postArray.append(post)
                    postsByDate[timeStr] = postArray
                }
            })
            print(postsByDate)
            completionHandler?(postsByDate, nil)
        })
    }
    
    func getIGAccounts(completionHandler: igAccountsCompletionHandler? = nil){
        var users: [User] = [User]()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let collection = Firestore.firestore().collection("users").whereField("uuid", isEqualTo: uid)
        ProgressHUD.show()
        collection.getDocuments(completion: { (querySnapshot, err) in
            ProgressHUD.dismiss()
            if let err = err {
                completionHandler?(nil, err)
                print("Failed to fetch Accounts:", err)
                return
            }
            querySnapshot?.documents.forEach({ (doc) in
                let data = JSON(doc.data())
                if let instagramAccts = data["instagramAccts"].array {
                    for instagramAcct in instagramAccts {
                        let user = User(instagramAcc: JSON(instagramAcct))
                        //                        if user.isActive ?? false {
                        users.append(User(instagramAcc: JSON(instagramAcct)))
                        //                        }
                    }
                }
            })
            completionHandler?(users,nil)
            return
        })
    }
    
    func updateIGAccounts(user: User, completionHandler: updateIGAccoutsCompletionHandler? = nil){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let usersDocRef = Firestore.firestore().collection("users").document(uid)
        ProgressHUD.show()
        //        usersDocRef.updateData(["instagramAccts": FieldValue.arrayRemove(<#T##elements: [Any]##[Any]#>)([user.retunJSON().rawValue])]
        usersDocRef.updateData(["instagramAccts": FieldValue.arrayUnion([user.retunJSON().rawValue])], completion: { err in
            if (err != nil) {
                completionHandler?(err)
            } else {
                completionHandler?(nil)
            }
        })
    }
    func removeIGAccounts(user: User, completionHandler: updateIGAccoutsCompletionHandler? = nil){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let usersDocRef = Firestore.firestore().collection("users").document(uid)
        ProgressHUD.show()
        usersDocRef.updateData(["instagramAccts": FieldValue.arrayRemove([user.retunJSON().rawValue])], completion: { err in
            if (err != nil) {
                completionHandler?(err)
            } else {
                completionHandler?(nil)
            }
        })
    }
}
