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
import JSON

struct User {
    let id: Int
    let login: String
    let avatarUrl: String
}

extension User : JSONDeserializable {
    init(jsonRepresentation: JSONDictionary) throws {
        id = try decode(jsonRepresentation, key: "id")
        login = try decode(jsonRepresentation, key: "login")
        avatarUrl = try decode(jsonRepresentation, key: "avatar_url")
    }
}

protocol UserResponse : Response { }

extension UserResponse {
    func parse(data: Data) -> User? {
        let dict = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : Any]
        return try? User(jsonRepresentation: dict)
    }
}

protocol UserArrayResponse : Response { }

extension UserArrayResponse {
    func parse(data: Data) -> [User]? {
        let arr = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [[String : Any]]
        return try? arr.map(User.init)
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

