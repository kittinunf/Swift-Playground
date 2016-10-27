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
    let login: String
    let avatarUrl: String
}

protocol UserResponse : Response { }

extension UserResponse {
    func parse(data: Data) -> User? {
        let dict = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : Any]
        let id = dict["id"] as! Int
        let login = dict["login"] as! String
        let avatarUrl = dict["avatar_url"] as! String
        return User(id: id, login: login, avatarUrl: avatarUrl)
    }
}

protocol UserArrayResponse : Response { }

extension UserArrayResponse {
    func parse(data: Data) -> [User]? {
        let arr = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [[String : Any]]
        return arr.map { dict in
            let id = dict["id"] as! Int
            let login = dict["login"] as! String
            let avatarUrl = dict["avatar_url"] as! String
            return User(id: id, login: login, avatarUrl: avatarUrl)
        }
    }
}

extension User {
    static func get(name: String) -> Observable<Result<User, RequestError>> {
        return Github.GetUser(with: name).call().map { $0.0 }
    }

    static func getAll() -> Observable<Result<[User], RequestError>> {
        return Github.GetAllUser().call().map { $0.0 }
    }

    static func get(name: String, handler: @escaping (Result<User, RequestError>) -> ()) {
        return Github.GetUser(with: name).call { (result, response) in
            handler(result)
        }
    }
}

extension Github {
    fileprivate struct GetUser: RequestCallable, UserResponse {
        typealias T = User

        let baseURL: URL = URL(string: url)!

        let method: Method = .get
        var path: String {
            get {
                return "/users/\(name)"
            }
        }

        let name: String
        init(with name: String) {
            self.name = name
        }
    }

    fileprivate struct GetAllUser: RequestCallable, UserArrayResponse {
        typealias T = [User]

        let baseURL: URL = URL(string: url)!

        let method: Method = .get
        var path: String {
            get {
                return "/users"
            }
        }
    }
}

