//
//  NetworkManager.swift
//  SDKTest
//
//  Created by Varun on 30/10/23.
//

import Foundation

@available(iOS 16.0, *)
public class NetworkManager {
    public static let shared = NetworkManager()
    
    private init() {}
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        return URLSession(configuration: configuration)
    }()
    
    public func makeRequest(url: URL, method: String, headers: [String: String]? = nil, jsonPayload: [String: Any]? = nil) async throws -> [String: Any] {
        let encrypted = false
        if encrypted {
            return try await makeEncryptedRequest(url: url, method: method, headers: headers, jsonPayload: jsonPayload)
        }
        return try await makeRawRequest(url: url, method: method, headers: headers!, jsonPayload: jsonPayload)
    }
    
    public func makeRawRequest(url: URL, method: String, headers: [String: String], jsonPayload: [String: Any]? = nil) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Set headers if provided
        headers.forEach { key, value in
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
        
        print("Debug Headers: \(request.allHTTPHeaderFields)")
        
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
    
    public func makeEncryptedRequest(url: URL, method: String, headers: [String: String]? = nil, jsonPayload: [String: Any]? = nil) async throws -> [String: Any] {
            
        do {
            let (publicKey, kid) = try await EncryptionManager.getPublicKeyAndKid()
            print("Debug: Public Key: \(publicKey)") // Debugging
            print("Debug: KID: \(kid)") // Debugging

            let aesKey = EncryptionManager.generateAESKey()
//            let aesKeyData = aesKey.withUnsafeBytes { Data($0) }
            let aesKeyData = Data(aesKey.withUnsafeBytes { bytes in
                Array(bytes)
            })

            print("Debug: AES Key Length: \(aesKeyData.count * 8) bits") // Debugging

            let base64EncodedAESKey = aesKeyData.base64EncodedString()
            print("Debug: Base64 Encoded AES Key: \(base64EncodedAESKey)") // Debugging

            guard let encryptedAESKey = EncryptionManager.encryptRSA(base64EncodedString: base64EncodedAESKey, publicKey: publicKey) else {
                throw NetworkError.encryptionFailed
            }
            print("Debug: Encrypted AES Key: \(encryptedAESKey)") // Debugging

            var requestHeaders = headers ?? [String: String]()
            requestHeaders["Content-Type"] = requestHeaders["Content-Type"] ?? "application/json;charset=utf-8"
            requestHeaders["key"] = encryptedAESKey
            requestHeaders["kid"] = kid

            print("Debug: Request Headers: \(requestHeaders)") // Debugging

            var encryptedPayload: [String: Any]?
            if let jsonPayload = jsonPayload {
                guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonPayload),
                      let jsonString = String(data: jsonData, encoding: .utf8) else {
                    throw NetworkError.invalidJSONFormat
                }

                guard let encryptedData = EncryptionManager.encryptAES(data: jsonString, key: aesKey) else {
                    throw NetworkError.encryptionFailed
                }
                encryptedPayload = ["encrypted": encryptedData.base64EncodedString()]

                print("Debug: Encrypted Payload: \(encryptedPayload ?? [:])") // Debugging
            }

            // Make the request
            let response = try await makeRawRequest(url: url, method: method, headers: requestHeaders, jsonPayload: encryptedPayload)

            // Decrypt the response if needed
            if let encryptedResponseString = response["encrypted"] as? String,
               let encryptedResponseData = Data(base64Encoded: encryptedResponseString) {
                guard let decryptedString = EncryptionManager.decryptAES(encryptedData: encryptedResponseData, key: aesKey) else {
                    throw NetworkError.decryptionFailed
                }

                guard let jsonData = decryptedString.data(using: .utf8),
                      let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    throw NetworkError.invalidJSONFormat
                }

                print("Debug: Decrypted Response: \(jsonObject)") // Debugging
                return jsonObject
            } else {
                print("Debug: Raw Response: \(response)") // Debugging
                return response
            }
        } catch {
            print("Debug: Error: \(error)") // Debugging
            throw error
        }
    }
}

enum NetworkError: Error, Equatable {
    case noData
    case invalidJSONFormat
    case invalidPublicKey
    case encryptionFailed
    case decryptionFailed
    case invalidPrivateKey
}
