//
//  MPINSetupView.swift
//  SDKSample
//
//  Created by Varun on 28/12/23.
//

import SwiftUI
import LocalAuthentication

@available(iOS 15.0, *)
struct MPINSetupView: View {
    @State private var pinDigits: [String] = Array(repeating: "", count: 4)
    @State var isMPINSet: Bool
    @State private var otpEntered = 0
    @State private var mPIN = ""// Adjust this based on your logic
    @FocusState private var focusedField: Int?
    @State private var showAlert = false
    let context = LAContext()
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var onSuccess: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                headerView
                HStack{
                    Spacer()
                    ForEach(0..<4, id: \.self) { index in
                        PinDigitView(digit: $pinDigits[index], onBackspace: {
                            handleBackspace(at: index)
                        }, index: index)
                        .focused($focusedField, equals: index)
                        .onChange(of: pinDigits[index]) { newValue in
                            if newValue.count == 1 {
                                focusedField = index < 3 ? index + 1 : nil
                            }
                        }
                    }
                    Spacer()
                }
                if isMPINSet {
                    HStack {
                        Spacer()
                        Text("Forgot Mpin?")
                            .font(.footnote)
                        Button(action:  {
                            
                        }) {
                            Text("Change Mpin")
                                .font(.footnote)
                                .foregroundColor(Color(hex: 0x037EAB))
                        }
                        Spacer()
                    }.padding(.top, 24)
                }
                continueButton
                if isMPINSet {
                    if isFaceIDAvailable() {
                        HStack {
                            Rectangle().frame(width: .infinity, height: 1)
                                .opacity(0.3)
                            Text("or")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: 0x9E9E9E))
                            Rectangle().frame(width: .infinity, height: 1)
                                .opacity(0.3)
                        }.padding(.top, 24)
                        HStack {
                            Spacer()
                            Button(action:  {
                                
                            }) {
                                Text("Use Face ID").font(.footnote)
                                    .foregroundStyle(Color(hex: 0x666666))
                                Image(systemName: "faceid")
                                    .foregroundStyle(Color(hex: 0x037EAB))
                            }
                            Spacer()
                        }.padding(.top)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .onAppear {
                focusedField = 0
            }
        }.alert(isPresented: $showAlert) {
            wrongPinAlert()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Authentication Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading) {
            Text(isMPINSet ? "Enter MPIN" : otpEntered == 0 ? "Setup MPIN" : "Re-enter Mpin")
                .font(.title2).bold()
                .padding(.top)
            
            Text(isMPINSet ? "Enter your 4 digit pin to login securely" : otpEntered == 0 ? "Add a 4 digit pin to setup secure login" : "Re-enter the 4 digit pin to setup secure login")
                .font(.subheadline)
                .padding(EdgeInsets(top: 2, leading: 0, bottom: 48, trailing: 0))
        }
    }
    
    private var continueButton: some View {
        Button(action: continueButtonAction) {
            Text("Continue").font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: 0x037EAB))
                .cornerRadius(8)
        }
        .padding(.top, 24)
    }
    
    private func handleBackspace(at index: Int) {
        if index > 0 {
            pinDigits[index - 1] = ""
            focusedField = index - 1
        }
    }
    
    private func isFaceIDAvailable() -> Bool {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        }
        return true
    }
    
    private func authenticateUser() {
        
        let reason = "We need to unlock your data."
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    onSuccess()
                } else {
                    // There was a problem
                    self.alertMessage = "There was a problem authenticating you."
                    self.showingAlert = true
                }
            }
        }
        
    }
    
    private func continueButtonAction() {
        let enteredPin = pinDigits.joined()
        if otpEntered == 0 {
            mPIN = enteredPin
            if isMPINSet {
                // Verify MPIN
                verifyPin(enteredPin)
            } else {
                // Prepare for re-entering MPIN for confirmation
                otpEntered += 1
                resetPinFields()
            }
        } else {
            // Confirm MPIN
            if enteredPin == mPIN {
                // Save or handle the confirmed MPIN
                handleConfirmedMPIN(mPIN)
            } else {
                // Handle mismatch
                showWrongPinAlert()
                resetPinFields()
            }
        }
    }
    
    private func resetPinFields() {
        pinDigits = Array(repeating: "", count: 4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = 0  // Set focus to the first field after a slight delay
        }
    }
    
    private func verifyPin(_ enteredPin: String) {
        // Add logic to verify the MPIN
        let savedPin = SharedPreferenceManager.shared.getValue(forKey: "MPIN") ?? ""
        if enteredPin == savedPin {
            onSuccess()
        } else {
            showWrongPinAlert()
        }
    }
    
    private func handleConfirmedMPIN(_ mPIN: String) {
        SharedPreferenceManager.shared.setValue(mPIN, forKey: "MPIN")
        onSuccess()
    }
    
    private func showWrongPinAlert() {
        showAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showAlert = false
        }
    }
    
    private func wrongPinAlert() -> Alert {
        Alert(
            title: Text("Incorrect PIN"),
            message: Text("Please check the MPIN you entered"),
            dismissButton: .default(Text("OK"))
        )
    }
}

@available(iOS 15.0, *)
#Preview {
    MPINSetupView(isMPINSet: true, onSuccess: {
        print("Success")
    })
}
