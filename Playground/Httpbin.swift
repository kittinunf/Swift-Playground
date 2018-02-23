//
//  Httpbin.swift
//  Playground
//
//  Created by kittinun-vantasin on 12/20/16.
//  Copyright © 2016 kittinun-vantasin. All rights reserved.
//

import Foundation
import JSON

struct HttpBinGet {
    let origin: String
    let url: String
    let args: [String : Any]
}

extension HttpBinGet : JSONDeserializable {
    init(jsonRepresentation: JSONDictionary) throws {
        origin = try decode(jsonRepresentation, key: "origin")
        url = try decode(jsonRepresentation, key:  "url")
        args = try decode(jsonRepresentation, key: "args")
    }
}

struct HttpBinHeaders {
    let headers: [String : Any]
}

extension HttpBinHeaders : JSONDeserializable {
    init(jsonRepresentation: JSONDictionary) throws {
        headers = try decode(jsonRepresentation, key: "headers")
    }
}

protocol HttpBinGetResponse : Deserializable {}

extension HttpBinGetResponse {
    func deserialize(data: Data) -> HttpBinGet? {
        let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : Any]
        return try? HttpBinGet(jsonRepresentation: json)
    }
}

protocol HttpBinHeadersResponse : Deserializable {}

extension HttpBinHeadersResponse {
    func deserialize(data: Data) -> HttpBinHeaders? {
        let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : Any]
        return try? HttpBinHeaders(jsonRepresentation: json)
    }
}

extension HttpBin {
    struct Get: RequestCallable, HttpBinGetResponse {
        typealias T = HttpBinGet

        let baseURL: URL = URL(string: url)!
        let method: Method = .get
        let path: String = "/get"
        var queryParam: [String : Any] {
            return ["foo": "bar"]
        }
    }

    struct Post: RequestCallable, HttpBinGetResponse, Serializable {
        typealias T = HttpBinGet

        let baseURL: URL = URL(string: url)!
        let method: Method = .post
        let path: String = "/post"

        let get: HttpBinGet

        init(get: HttpBinGet) {
            self.get = get
        }

        var body: [String : Any] {
            return serialize(t: get)
        }

        func serialize(t: HttpBinGet) -> [String : Any] {
            return ["origin" : get.origin,
                    "url": get.url]
        }
    }

    struct Headers: RequestCallable, HttpBinHeadersResponse {
        typealias T = HttpBinHeaders

        let baseURL: URL = URL(string: url)!
        let method: Method = .post
        let path: String = "/headers"
    }
}
