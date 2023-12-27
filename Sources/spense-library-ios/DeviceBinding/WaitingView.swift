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
    
    private func initiateDeviceBinding() async {
        do {
            let parameters = await ["device_uuid": UIDevice.current.identifierForVendor, "manufacturer": "Apple", "model": UIDevice.modelName, "os": "iOS", "os_version": UIDevice.current.systemVersion, "app_version": PackageInfo.version] as [String : Any]
            let result = try await NetworkManager.shared.makeRequest(url: URL(string: "https://partner.uat.spense.money/api/device/bind")!, method: "POST", jsonPayload: parameters)
            print(result)
        } catch {
            print(error)
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
            // Simulate device verification delay
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                // Update this logic as per your requirement
////                currentScreen = .simSelection // or .failure
//            }
        }
    }
}


//#Preview {
//    WaitingView()
//}
