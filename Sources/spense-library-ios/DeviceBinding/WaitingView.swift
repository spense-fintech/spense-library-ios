//
//  SwiftUIView.swift
//
//
//  Created by Varun on 27/12/23.
//

import SwiftUI

@available(iOS 15.0, *)
struct WaitingView: View {
    
    @Binding var currentScreen: DeviceBindingWaitingView.Screen
    @Binding var isShowingMessageCompose: Bool
    @Binding var deviceAuthCode: String
    @Binding var deviceId: Int
    @Binding var deviceBindingId: String
    
    private func initiateDeviceBinding() async {
        do {
            let parameters = await ["device_uuid": UIDevice.current.identifierForVendor?.uuidString ?? "", "device_binding_id": deviceBindingId, "manufacturer": "Apple", "model": UIDevice.modelName, "os": "iOS", "os_version": UIDevice.current.systemVersion, "app_version": PackageInfo.version] as [String : Any]
            print(parameters)
            let response = try await NetworkManager.shared.makeRequest(url: URL(string: "https://partner.uat.spense.money/api/device/bind")!, method: "POST", jsonPayload: parameters)
            print(response)
            if let authCode = response["device_auth"] as? String {
                DispatchQueue.main.async {
                    self.deviceAuthCode = authCode
                    self.deviceId = response["device_id"] as! Int
                    self.isShowingMessageCompose = true
                }
            } else {
                currentScreen = .failure
            }
        } catch {
            print(error)
            currentScreen = .failure
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Please wait\nVerifying your device")
                .multilineTextAlignment(.center)
                .font(.system(size: 18, weight: .semibold))
            
            // Replace with an appropriate loader or GIF
            ProgressView()
                .scaleEffect(1.5, anchor: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.6))
        .onAppear {
            Task {
                await initiateDeviceBinding()
            }
        }
    }
}


//#Preview {
//    WaitingView()
//}
