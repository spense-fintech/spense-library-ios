//
//  SwiftUIView.swift
//
//
//  Created by Varun on 27/12/23.
//

import SwiftUI

@available(iOS 16.0, *)
struct DeviceBindingWaitingView: View {
    
    @State private var currentScreen: Screen = .waiting
    @State private var isShowingMessageCompose = false
    @State private var deviceAuthCode = ""
    @State private var deviceId = 0
    @State private var timer: Timer? = nil
    @State private var pollingCounter = 0
    @State private var deviceBindingId = UUID().uuidString
    var onSuccess: () -> Void
    var onReset: () -> Void
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            switch currentScreen {
            case .waiting:
                WaitingView(currentScreen: $currentScreen, isShowingMessageCompose: $isShowingMessageCompose, deviceAuthCode: $deviceAuthCode, deviceId: $deviceId, deviceBindingId: $deviceBindingId)
            case .failure:
                FailureView(currentScreen: $currentScreen)
            case .mpinsetup:
                MPINSetupView(isMPINSet: false, onSuccess: onSuccess, onReset: onReset)
            }
        }
        .onChange(of: deviceAuthCode) { newValue in
            if !newValue.isEmpty {
                isShowingMessageCompose = true
            }
        }
        .sheet(isPresented: $isShowingMessageCompose, onDismiss: startPolling) {
            MessageComposeView(recipients: ["9220592205"], body: "CGFWT \(deviceAuthCode)")
        }
        .loader(isLoading: $isLoading)
    }
    
    private func startPolling() {
        isLoading = true
        pollingCounter = 0
        timer?.invalidate() // Invalidate any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            if pollingCounter < 6 {
                pollingCounter += 1
                Task {
                    await checkDeviceBindingStatus()
                }
            } else {
                timer?.invalidate()
                Task {
                    await handleFailure()
                }
            }
        }
    }
    
    private func checkDeviceBindingStatus() async {
        do {
            let bank = "spense"
            let response = try await NetworkManager.shared.makeRequest(url: URL(string: "\(SpenseLibrarySingleton.shared.instance.hostName ?? "https://partner.uat.spense.money")/api/device/\(bank)/binding/status/\(UIDevice.current.identifierForVendor?.uuidString ?? "")")!, method: "GET")
            if response["status"] as? String == "SUCCESS" {
                timer?.invalidate()
                isLoading = false
                SharedPreferenceManager.shared.setValue(deviceBindingId, forKey: "device_binding_id")
                DispatchQueue.main.async {
                    currentScreen = .mpinsetup // Navigate to success view
                }
            } else if response["status"] as? String == "FAILURE" {
                timer?.invalidate()
                await handleFailure()
            }
        } catch {
            print(error)
            await handleFailure()
        }
    }
    
    private func handleFailure() async {
        await failDeviceBinding()
        DispatchQueue.main.async {
            currentScreen = .failure
        }
    }
    
    private func failDeviceBinding() async {
        do {
            let bank = "spense"
            let parameters = ["device_id": deviceId] as [String : Any]
            let response = try await NetworkManager.shared.makeRequest(url: URL(string: "\(SpenseLibrarySingleton.shared.instance.hostName ?? "https://partner.uat.spense.money")/api/device/\(bank)/bind")!, method: "PUT", jsonPayload: parameters)
            isLoading = false
        } catch {
            print(error)
            isLoading = false
        }
    }
    
    enum Screen {
        case waiting, failure, mpinsetup
    }
}


@available(iOS 16.0, *)
#Preview {
    DeviceBindingWaitingView(onSuccess: {
        print("Success DeviceBindingWaitingView")
    }, onReset: {
        print("Reset DeviceBindingWaitingView")
    })
}
