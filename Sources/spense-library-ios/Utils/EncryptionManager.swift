//
//  File.swift
//
//
//  Created by Varun on 30/01/24.
//

import CryptoKit
import Foundation
import Security

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
            // Prepend IV to the ciphertext only (ignoring the tag)
            return iv + sealedBox.ciphertext
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    static func decryptAES(encryptedData: Data, key: SymmetricKey) -> String? {
        guard encryptedData.count > 12 else {
            print("Decryption error: Data too short")
            return nil
        }

        let iv = encryptedData.prefix(12)
        let ciphertext = encryptedData.dropFirst(12)

        print("Nonce size: \(iv.count), Ciphertext size: \(ciphertext.count)")

        do {
            let nonce = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: Data())
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }


    
    static func encryptRSA(base64EncodedString: String, publicKey: SecKey) -> String? {
        guard let dataToEncrypt = Data(base64Encoded: base64EncodedString) else { return nil }
        
        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA256
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            print("Algorithm not supported.")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let cipherText = SecKeyCreateEncryptedData(publicKey, algorithm, dataToEncrypt as CFData, &error) else {
            if let error = error?.takeRetainedValue() {
                print("Encryption error: \(error)")
            }
            return nil
        }
        
        return (cipherText as Data).base64EncodedString()
    }
    
    static func decryptRSA(base64EncodedString: String, privateKey: SecKey) -> String? {
        guard let dataToDecrypt = Data(base64Encoded: base64EncodedString) else {
            print("Failed to decode base64 string")
            return nil
        }
        
        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA256
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
            print("Algorithm not supported.")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let clearText = SecKeyCreateDecryptedData(privateKey, algorithm, dataToDecrypt as CFData, &error) else {
            if let error = error?.takeRetainedValue() {
                print("Decryption error: \(error)")
            }
            return nil
        }
        
        return String(data: clearText as Data, encoding: .utf8)
    }
    
    static func getPublicKeyAndKid() async throws -> (SecKey, String) {
        let (publicKeyString, kid) = try await getPublicKeyAndKidString()
        
        print(publicKeyString, kid)
        
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
        let (data, _) = try await URLSession.shared.data(from: URL(string: ServiceNames.NETWORK_KEYS)!)
        
        guard let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]] else {
            throw NetworkError.invalidPublicKey
        }
        return response
    }
    
    static func convertPEMStringToSecKey(_ pemString: String) throws -> SecKey {
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
    
    static func convertPrivatePEMStringToSecKey(_ pemString: String) throws -> SecKey {
        let base64String = pemString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        guard let data = Data(base64Encoded: base64String) else {
            throw NetworkError.invalidPrivateKey
        }
        
        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        
        guard let secKey = SecKeyCreateWithData(data as CFData, options as CFDictionary, nil) else {
            throw NetworkError.invalidPrivateKey
        }
        
        return secKey
    }
}
