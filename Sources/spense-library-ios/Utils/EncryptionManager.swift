//
//  File.swift
//
//
//  Created by Varun on 30/01/24.
//

import CryptoKit
import Foundation
import SwiftyRSA

@available(iOS 16.0, *)
struct EncryptionManager {
    static func generateAESKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    static func encryptAES(data: String, key: SymmetricKey) -> Data? {
        guard let dataToEncrypt = data.data(using: .utf8) else { return nil }
        let iv = AES.GCM.Nonce()
        
        do {
            let sealedBox = try AES.GCM.seal(dataToEncrypt, using: key, nonce: iv)
            return iv + sealedBox.ciphertext
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    static func decryptAES(encryptedData: Data, key: SymmetricKey) -> String? {
        guard encryptedData.count > 12 else { return nil }
        do {
            let iv = try AES.GCM.Nonce(data: encryptedData.prefix(12))
            let ciphertext = encryptedData.dropFirst(12)
            
            
            let sealedBox = try AES.GCM.SealedBox(nonce: iv, ciphertext: ciphertext, tag: Data()) // Include an empty tag
            
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
    
    static func encryptRSA(base64EncodedString: String, publicKey: SecKey) -> String? {
        do {
            let publicKey = try PublicKey(reference: publicKey)

            // Convert the base64 encoded string to Data
            guard let data = Data(base64Encoded: base64EncodedString) else { return nil }

            // Create Clear object
            let clear = ClearMessage(data: data)

            // Encrypt using OAEP SHA-256
            let encrypted = try clear.encrypted(with: publicKey, padding: .OAEP)

            // Return base64 encoded encrypted string
            return encrypted.base64String
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    static func getPublicKeyAndKid() async throws -> (SecKey, String) {
        let (publicKeyString, kid) = try await getPublicKeyAndKidString()
        
        let publicKey = try convertPEMStringToSecKey(publicKeyString)
        return (publicKey, kid)
    }
    
    private static func getPublicKeyAndKidString() async throws -> (String, String) {
        guard let keyWeb = SharedPreferenceManager.shared.getValue(forKey: "key_web"),
              let kid = SharedPreferenceManager.shared.getValue(forKey: "kid") else {
            let response = try await fetchPublicKeyResponse()
            
            guard let keyData = response.first?.value,
                  let publicKeyString = keyData["public"] as? String,
                  let kid = keyData["kid"] as? String else {
                throw NetworkError.invalidPublicKey
            }
            
            SharedPreferenceManager.shared.setValue(publicKeyString, forKey: "key_web")
            SharedPreferenceManager.shared.setValue(kid, forKey: "kid")
            return (publicKeyString, kid)
        }
        return (keyWeb, kid)
    }
    
    private static func fetchPublicKeyResponse() async throws -> [String: [String: String]] {
        let (data, _) = try await URLSession.shared.data(from: URL(string: "\(SpenseLibrarySingleton.shared.instance.hostName ?? "https://partner.uat.spense.money")/api/network/keys")!)
        print(data)
        
        guard let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]] else {
            throw NetworkError.invalidPublicKey
        }
        return response
    }
    
    private static func convertPEMStringToSecKey(_ pemString: String) throws -> SecKey {
        let base64String = pemString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        guard let data = Data(base64Encoded: base64String) else {
            throw NetworkError.invalidPublicKey
        }
        
        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        
        guard let secKey = SecKeyCreateWithData(data as CFData, options as CFDictionary, nil) else {
            throw NetworkError.invalidPublicKey
        }
        
        return secKey
    }
}
