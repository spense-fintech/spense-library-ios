//
//  SpenseSdk.swift
//  spense-sdk-ios
//
//  Created by Varun on 13/11/23.
//

import UIKit
import SwiftUI

@available(iOS 16.0, *)
public class SpenseLibrary {
    
    public private(set) var hostName: String?
    var onMPINSetupSuccess: (() -> Void)?
    
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
    
    public func bindDevice(on viewController: UIViewController, completion: @escaping () -> Void) {
        //        onMPINSetupSuccess = completion
        let isMPINSet = !(SharedPreferenceManager.shared.getValue(forKey: "MPIN") ?? "").isEmpty
        if (isMPINSet) {
            let rootView = AnyView(MPINSetupView(isMPINSet: true, onSuccess: {
                viewController.dismiss(animated: true, completion: completion)
            }))
            
            let hostingController = UIHostingController(rootView: rootView)
            hostingController.modalPresentationStyle = .fullScreen
            viewController.present(hostingController, animated: true, completion: nil)
        } else {
            Task {
                let bank = "spense"
                print(self.hostName!)
                guard let hostName = self.hostName else {
                    throw SpenseError.hostnameNotSet
                }
                print(hostName)
                let checkProductsResponse = try await NetworkManager.shared.makeRequest(url: URL(string: "\(hostName)/api/banking/\(bank)/accounts/count")!, method: "GET")
                if ((checkProductsResponse["count"] as! Int) < 1) {
                    await MainActor.run {
                        viewController.dismiss(animated: true, completion: completion)
                    }
                } else {
                    let rootView = AnyView(BankingDetailsView(onSuccess: {
                        Task {
                            await MainActor.run {
                                viewController.dismiss(animated: true, completion: completion)
                            }
                        }
                    }))
                    await MainActor.run {
                        let hostingController = UIHostingController(rootView: rootView)
                        hostingController.modalPresentationStyle = .fullScreen
                        viewController.present(hostingController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    public func unbindDevice() {
        SharedPreferenceManager.shared.setValue("", forKey: "MPIN")
    }
    
    public func open(on viewController: UIViewController, withSlug slug: String) {
        let webVC = WebViewController(urlString: "\(hostName ?? "https://partner.uat.spense.money")\(slug)")
        let navVC = UINavigationController(rootViewController: webVC)
        navVC.modalPresentationStyle = .fullScreen
        viewController.present(navVC, animated: true, completion: nil)
    }
    
    public func getViewController(withSlug slug: String) -> UINavigationController {
        let webVC = WebViewController(urlString: "\(hostName ?? "https://partner.uat.spense.money")\(slug)")
        let navVC = UINavigationController(rootViewController: webVC)
        navVC.modalPresentationStyle = .fullScreen
        return navVC
    }
}

public enum SpenseError: Error {
    case hostnameNotSet
}
