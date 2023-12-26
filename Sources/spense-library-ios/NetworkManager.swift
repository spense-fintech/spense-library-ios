//
//  NetworkManager.swift
//  SDKTest
//
//  Created by Varun on 30/10/23.
//

import Foundation

@available(iOS 15.0, *)
public class NetworkManager {
    public static let shared = NetworkManager()
    
    private init() {}
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        return URLSession(configuration: configuration)
    }()
    
    public func makeRequest(url: URL, method: String, headers: [String: String]? = nil, jsonPayload: [String: Any]? = nil) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Set headers if provided
        headers?.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Set JSON payload if provided
        if let jsonPayload = jsonPayload {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: jsonPayload)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw error
            }
        }
        
        let (data, _) = try await session.data(for: request)
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
            print("JSON \(json)")
            guard let jsonDictionary = json as? [String: Any] else {
                throw NetworkError.invalidJSONFormat
            }
            return jsonDictionary
        } catch {
            throw error
        }
    }
}

enum NetworkError: Error, Equatable {
    case noData
    case invalidJSONFormat
}
