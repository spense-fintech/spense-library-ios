//
//  SwiftUIView.swift
//  
//
//  Created by Varun on 27/12/23.
//

import SwiftUI

@available(iOS 15.0, *)
struct DeviceBindingWaitingView: View {
    @State private var currentScreen: Screen = .waiting
    @State private var selectedSIM: Int? = nil

    var body: some View {
        ZStack {
            switch currentScreen {
            case .waiting:
                WaitingView(currentScreen: $currentScreen)
            case .failure:
                FailureView(currentScreen: $currentScreen)
            case .simSelection:
                SIMSelectionView(selectedSIM: $selectedSIM, currentScreen: $currentScreen)
            }
        }
    }

    enum Screen {
        case waiting, failure, simSelection
    }
}

@available(iOS 15.0, *)
#Preview {
    DeviceBindingWaitingView()
}
