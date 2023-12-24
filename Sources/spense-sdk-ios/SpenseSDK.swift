//
//  SpenseSdk.swift
//  spense-sdk-ios
//
//  Created by Varun on 13/11/23.
//

import UIKit

@available(iOS 15.0, *)
public class SpenseSDK {
    public var hostName: String? = nil
    
    public init(hostName: String? = nil) {
        self.hostName = hostName
    }
    
    public func checkLogin() async throws -> [String: Any] {
        return try await NetworkManager.shared.makeRequest(url: URL(string: "\(hostName ?? "https://partner.uat.spense.money")/api/user/logged_in")!, method: "GET")
    }
    
    public func login(token: String) async throws -> [String: Any] {
        return try await NetworkManager.shared.makeRequest(url: URL(string: "\(hostName ?? "https://partner.uat.spense.money")/api/user/token")!, method: "POST", jsonPayload: ["token": token])
    }
    
    public func open(on viewController: UIViewController, withURL urlString: String) {
        let webVC = WebViewController(urlString: urlString)
        let navVC = UINavigationController(rootViewController: webVC)
        navVC.modalPresentationStyle = .fullScreen
        viewController.present(navVC, animated: true, completion: nil)
    }
}
