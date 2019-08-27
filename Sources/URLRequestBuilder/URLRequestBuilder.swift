//
//  URLRequestBuilder.swift
//  Requests
//
//  Created by Daniel Byon on 8/5/19.
//  Copyright 2019 Daniel Byon.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

import Foundation

// MARK: - HTTPMethod
public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case HEAD
    case OPTIONS
    case CONNECT
}

// MARK: - URLRequestBuilderError
public enum URLRequestBuilderError: Error {
    case failedToCreateURL
}

// MARK: - Completion Handler
public typealias URLRequestBuilderCompletion = (Result<URLRequest, Error>) -> Void

// MARK: - URLRequestBuilder
public struct URLRequestBuilder {

    // MARK: Builder Functions

    public static func makeRequest(withEndpoint endpoint: Endpoint,
                                   baseURL: URL,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyData: Data? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        makeRequest(withPath: endpoint.path, baseURL: baseURL, method: method, queryItems: queryItems, bodyData: bodyData, headerFields: headerFields, transformers: transformers, completion: completion)
    }

    public static func makeRequest(withPath path: String,
                                   baseURL: URL,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyData: Data? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            completion(.failure(URLRequestBuilderError.failedToCreateURL))
            return
        }
        makeRequest(withURL: url, method: method, queryItems: queryItems, bodyData: bodyData, headerFields: headerFields, transformers: transformers, completion: completion)
    }

    public static func makeRequest(withFullURLString urlString: String,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyData: Data? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        guard let url = URL(string: urlString) else {
            completion(.failure(URLRequestBuilderError.failedToCreateURL))
            return
        }
        makeRequest(withURL: url, method: method, queryItems: queryItems, bodyData: bodyData, headerFields: headerFields, transformers: transformers, completion: completion)
    }

    public static func makeRequest(withURL url: URL,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyData: Data? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completion(.failure(URLRequestBuilderError.failedToCreateURL))
            return
        }
        makeRequest(withComponents: components, method: method, queryItems: queryItems, bodyData: bodyData, headerFields: headerFields, transformers: transformers, completion: completion)
    }

    public static func makeRequest(withComponents components: URLComponents,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyData: Data? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        var components = components

        var allQueryItems = components.queryItems ?? []
        if let queryItems = queryItems?.map({ URLQueryItem(name: $0.key, value: $0.value) }) {
            allQueryItems += queryItems
        }
        components.queryItems = allQueryItems

        guard let url = components.url else {
            completion(.failure(URLRequestBuilderError.failedToCreateURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = bodyData

        headerFields?.forEach {
            request.addValue($0.value, forHTTPHeaderField: $0.key)
        }

        if let transformers = transformers {
            applyTransformers(transformers, to: request, completion: completion)
        } else {
            completion(.success(request))
        }
    }

    private static func applyTransformers(_ transformers: [URLRequestTransforming], to request: URLRequest, completion: @escaping URLRequestBuilderCompletion) {
        var returnRequest = request
        var returnError: Error? = nil

        let group = DispatchGroup()
        for transformer in transformers {
            group.enter()
            transformer.transformRequest(returnRequest) { result in
                switch result {
                case .success(let transformed):
                    returnRequest = transformed
                case .failure(let error):
                    returnError = error
                }
                group.leave()
            }
            group.wait()
            if let _ = returnError {
                break
            }
        }

        if let returnError = returnError {
            completion(.failure(returnError))
        } else {
            completion(.success(returnRequest))
        }
    }

    // MARK: Private

    private init() { }

}
