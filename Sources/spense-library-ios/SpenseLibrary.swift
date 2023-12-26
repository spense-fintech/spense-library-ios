//
//  SpenseSdk.swift
//  spense-sdk-ios
//
//  Created by Varun on 13/11/23.
//

import UIKit

@available(iOS 15.0, *)
public class SpenseLibrary {
    
    private(set) var hostName: String?
    
    init(hostName: String) {
        self.hostName = hostName
    }
    
    public func checkLogin() async throws -> [String: Any] {
        guard let hostName = self.hostName else {
            throw SpenseError.hostnameNotSet
        }
        return try await NetworkManager.shared.makeRequest(url: URL(string: "\(hostName)/api/user/logged_in")!, method: "GET")
    }
    
    public func login(token: String) async throws -> [String: Any] {
        guard let hostName = self.hostName else {
            throw SpenseError.hostnameNotSet
        }
        return try await NetworkManager.shared.makeRequest(url: URL(string: "\(hostName)/api/user/token")!, method: "POST", jsonPayload: ["token": token])
    }
    
    public func open(on viewController: UIViewController, withSlug slug: String) {
        let webVC = WebViewController(urlString: "\(hostName ?? "https://partner.uat.spense.money")\(slug)")
        let navVC = UINavigationController(rootViewController: webVC)
        navVC.modalPresentationStyle = .fullScreen
        viewController.present(navVC, animated: true, completion: nil)
    }
}

public enum SpenseError: Error {
    case hostnameNotSet
}
