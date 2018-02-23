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
        case methodNotAllow = 405
        case internalServer = 500

        case deserialization = 999
    }

    let kind: ErrorKind
    let error: String
}

protocol Requestable {
    static func baseURL() -> URL
}

protocol Request {
    var baseURL: URL { get }
    var method: Method { get }
    var path: String { get }
    var body: [String: Any] { get }
    var header: [String: Any] { get }
    var queryParam: [String: Any] { get }
}

extension Request {
    var method: Method { return .get }
    var path: String { return "" }
    var body: [String: Any] { return [:] }
    var header: [String: Any] { return [:] }
    var queryParam: [String: Any] { return [:] }
}

protocol RequestConstructable : Request {
    func createRequest() -> URLRequest?
}

extension RequestConstructable {
    func createRequest() -> URLRequest? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else { return nil }

        components.path += path

        let query = queryParam.reduce([URLQueryItem]()) { acc , dict in
            var mutable = acc
            mutable.append(URLQueryItem(name: dict.0, value: dict.1 as? String))
            return mutable
        }

        components.queryItems = query

        guard let constructedURL = components.url else { return nil }

        var request = URLRequest(url: constructedURL)
        request.httpMethod = method.rawValue
        if !body.isEmpty {
            if request.httpMethod != Method.get.rawValue {
                request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            }
        }

        for (key, value) in header {
            request.addValue(String(describing: value), forHTTPHeaderField: key)
        }

        return request
    }
}

protocol Deserializable {
    associatedtype T
    func deserialize(data: Data) -> T?
}

extension Deserializable {
    func deserialize(data: Data) -> T? {
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? T
    }
}

protocol Serializable {
    associatedtype T
    func serialize(t: T) -> [String : Any]
}

protocol RequestCallable : RequestConstructable, Deserializable {
    func call(with handler: @escaping (Result<T, RequestError>, HTTPURLResponse?) -> ())
    func call() -> Observable<(Result<T, RequestError>, HTTPURLResponse?)>
}

extension RequestCallable {
    func call(with handler: @escaping (Result<T, RequestError>, HTTPURLResponse?) -> ()) {
        guard let request = createRequest() else {
            let error = RequestError(kind: .unknown, error: "Request cannot be created!")
            handler(.failure(error), nil)
            return
        }

        let task = performTask(with: request, success: { (parsed, response) in
                let result: Result<T, RequestError> = .success(parsed)
                handler(result, response)
            }, failure: { (error, response) in
                let result: Result<T, RequestError> = .failure(error)
              handler(result, response)
            }, parseFailure: { (error, response) in
                let result: Result<T, RequestError> = .failure(error)
                handler(result, response)
            }) {
            }

        task.resume()
    }

    func call() -> Observable<(Result<T, RequestError>, HTTPURLResponse?)> {
        return Observable.create { observer in
            guard let request = self.createRequest() else {
                let error = RequestError(kind: .unknown, error: "Request cannot be created!")
                observer.onNext((.failure(error), nil))
                return Disposables.create()
            }

            let task = self.performTask(with: request, success: { parsed, response in
                observer.onNext((.success(parsed), response))
                }, failure: { error, response in
                    observer.onNext((.failure(error), response))
                }, parseFailure: { error, response in
                    observer.onNext((.failure(error), response))
                }, finish: { 
                    observer.onCompleted()
                })

            return Disposables.create(with: task.cancel)
        }
    }

    private func performTask(with request: URLRequest,
                             success: @escaping (T, HTTPURLResponse?) -> (),
                             failure: @escaping (RequestError, HTTPURLResponse?) -> (),
                             parseFailure: @escaping (RequestError, HTTPURLResponse?) -> (),
                             finish: @escaping () -> ()) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                let statusCode = response.statusCode
                if !(200...299 ~= statusCode) {
                    let err = RequestError(kind: RequestError.ErrorKind(rawValue: response.statusCode)!,
                                             error: data == nil ? "" : String(data: data!, encoding: .utf8)!)
                    failure(err, response)
                } else if let data = data, let result = self.deserialize(data: data)  {
                    success(result, response)
                } else {
                    parseFailure(RequestError(kind: .deserialization, error: "Deserialization problem"), response)
                }
            } else {
                failure(RequestError(kind: .unknown, error: "Unknown problem"), nil)
            }
            finish()

            
        }

        task.resume()
        return task
    }
}

extension URLRequest {
    fileprivate func convertToCurlCommand() -> String {
        let method = httpMethod ?? "GET"
        var returnValue = "curl -X \(method) "

        if let httpBody = httpBody, httpMethod == "POST" {
            let maybeBody = String(data: httpBody, encoding: String.Encoding.utf8)
            if let body = maybeBody {
                returnValue += "-d \"\(escapeTerminalString(body))\" "
            }
        }

        for (key, value) in allHTTPHeaderFields ?? [:] {
            let escapedKey = escapeTerminalString(key as String)
            let escapedValue = escapeTerminalString(value as String)
            returnValue += "\n    -H \"\(escapedKey): \(escapedValue)\" "
        }

        let URLString = url?.absoluteString ?? "<unknown url>"

        returnValue += "\n\"\(escapeTerminalString(URLString))\""
        
        returnValue += " -i -v"
        
        return returnValue
    }

    fileprivate func escapeTerminalString(_ value: String) -> String {
        return value.replacingOccurrences(of: "\"", with: "\\\"", options:[], range: nil)
    }
}
