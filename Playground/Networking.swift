import Foundation
import Result
import RxSwift

enum Method: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct RequestError: Error {
    enum ErrorKind: Int {
        case unknown = -1

        case badRequest = 400
        case unauthorized = 401
        case forbidden = 403
        case notFound = 404
        case internalServer = 500

        case deserialization = 999
    }

    let kind: ErrorKind
}

protocol Serializable {
    func toDict() -> [String: AnyObject]
}

protocol Requestable {
    static func baseURL() -> URL
}

protocol Request {
    var baseURL: URL { get }
    var method: Method { get }
    var path: String { get }
    var body: [String: AnyObject]? { get }
    var header: [String: AnyObject]? { get }
    var queryParam: [String: AnyObject]? { get }
}

extension Request {
    var method: Method { return .get }
    var path: String { return "" }
    var body: [String: AnyObject]? { return nil }
    var header: [String: AnyObject]? { return nil }
    var queryParam: [String: AnyObject]? { return nil }
}

protocol RequestConstructable : Request {
    func createRequest() -> URLRequest?
}

extension RequestConstructable {
    func createRequest() -> URLRequest? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else { return nil }

        components.path += path

        let query = queryParam?.reduce([URLQueryItem]()) { acc , dict in
            var mutable = acc
            mutable?.append(URLQueryItem(name: dict.0, value: dict.1 as? String))
            return mutable
        }

        components.queryItems = query

        guard let constructedURL = components.url else { return nil }

        var request = URLRequest(url: constructedURL)
        request.httpMethod = method.rawValue
        if let body = body {
            if request.httpMethod != Method.get.rawValue {
                request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            }
        }

        header?.forEach { key, value in
            request.addValue(String(describing: value), forHTTPHeaderField: key)
        }

        return request
    }
}

protocol Response {
    associatedtype T

    func parse(data: Data) -> T?
}

extension Response {
    func parse(data: Data) -> T? {
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? T
    }
}

protocol StringResponse : Response { }

protocol IntResponse: Response { }

extension StringResponse {
    func parse(data: Data) -> String? {
        return String(data: data, encoding: String.Encoding.utf8)
    }
}

extension IntResponse {
    func parse(data: Data) -> Int? {
        if let responseString =  String(data: data, encoding: String.Encoding.utf8) {
            return Int(responseString)
        } else {
            return nil
        }
    }
}

protocol ObservableRequestCallable : RequestConstructable, Response {
    func call() -> Observable<(Result<T, RequestError>, HTTPURLResponse?)>
}

extension ObservableRequestCallable {
    func call() -> Observable<(Result<T, RequestError>, HTTPURLResponse?)> {
        return Observable.create { observer in
            let session = URLSession.shared
            guard let request = self.createRequest() else { return Disposables.create() }

            let task = session.dataTask(with: request) { data, response, error in
                if let response = response as? HTTPURLResponse {
                    if !(200...299 ~= response.statusCode) {
                        let error = RequestError(kind: RequestError.ErrorKind(rawValue: response.statusCode)!)
                        observer.onNext((.failure(error), response))
                    } else if let data = data, let result = self.parse(data: data)  {
                        observer.onNext((.success(result), response))
                    } else {
                        let error = RequestError(kind: .deserialization)
                        observer.onNext((.failure(error), response))
                    }
                } else {
                    let error = RequestError(kind: .unknown)
                    observer.onNext((.failure(error), nil))
                }
                observer.onCompleted()
            }

            task.resume()

            return Disposables.create(with: task.cancel)
        }
    }
}

struct GithubClient {
    static let url = "https://api.github.com"
}
