//
//  PinDigitFieldView.swift
//  SDKSample
//
//  Created by Varun on 28/12/23.
//
import SwiftUI

@available(iOS 14.0, *)
struct PinDigitView: View {
    @Binding var digit: String
    var onBackspace: () -> Void
    let index: Int
    @State private var previousDigit = ""
    
    var body: some View {
        TextField("", text: $digit)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .frame(width: 48, height: 48)
            .background(Color("LightGray"))
            .cornerRadius(48)
            .padding(1)
        //            .onReceive(digit.publisher.collect()) {
        //                if $0.isEmpty && !previousDigit.isEmpty {
        //                    onBackspace()
        //                }
        //                previousDigit = $0 // Update the previous digit
        //                self.digit = String($0.prefix(1))
        //            }
            .onChange(of: digit) { newValue in
                if newValue.isEmpty && !previousDigit.isEmpty {
                    onBackspace()
                }
                previousDigit = digit  // Update the previous digit
            }
            .onReceive(digit.publisher.collect()) {
                self.digit = String($0.prefix(1))
            }
    }
}
