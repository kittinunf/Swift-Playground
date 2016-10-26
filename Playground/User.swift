//
//  User.swift
//  Playground
//
//  Created by kittinun-vantasin on 10/26/16.
//  Copyright © 2016 kittinun-vantasin. All rights reserved.
//

import Foundation
import RxSwift
import Result

struct User {
    let id: Int
    let followers: Int
    let company: String
    let avatarUrl: String
}

protocol UserResponse : Response { }

extension UserResponse {
    func parse(data: Data) -> User? {
        let dict = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Dictionary<String, Any>
        let id = dict["id"] as! Int
        let followers = dict["followers"] as! Int
        let company = dict["company"] as! String
        let avatarUrl = dict["avatar_url"] as! String
        return User(id: id, followers: followers, company: company, avatarUrl: avatarUrl)
    }
}

extension User {
    static func get(name: String) -> Observable<Result<User, RequestError>> {
        return GithubClient.UserAPI(name: name).call().map { $0.0 }
    }
}

extension GithubClient {
    fileprivate struct UserAPI: ObservableRequestCallable, UserResponse {
        typealias T = User

        let baseURL: URL = URL(string: url)!

        var method: Method { return .get }
        var path: String {
            get {
                return "/users/\(name)"
            }
        }

        let name: String
        init(name: String) {
            self.name = name
        }
    }
}

