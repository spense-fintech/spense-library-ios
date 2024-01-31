//
//  SwiftUIView.swift
//  
//
//  Created by Varun on 29/01/24.
//

import SwiftUI


@available(iOS 16.0, *)
struct BankingDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var cif = ""
    @State private var dob = Date()
    @State private var pan = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var navigateToDeviceBinding = false
    var onSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(alignment: .leading) {
                    Image(systemName: "arrow.backward")
                        .padding(.top, 16)
                        .padding(.leading, 12).onTapGesture {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    Text("Enter details")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.top, 28)
                        .padding(.leading, 16)
                    Text("These are the details which is linked to the savings account you created through SBM web. Your CIF id information was shared by SBM through email at the time of account creation")
                        .font(.system(size: 12))
                        .padding(.top, 1)
                        .padding(.leading, 16)
                    
                    TextField("CIF", text: $cif)
                        .keyboardType(.emailAddress)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .frame(height: 60)
                        .background(Color(hex: 0xEBECEF))
                        .foregroundColor(Color(hex: 0x212121))
                        .accentColor(Color(hex: 0x666666))
                        .cornerRadius(8)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 24)
                        .padding(.horizontal)
                    
                    TextField("PAN", text: $pan)
                        .keyboardType(.emailAddress)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .frame(height: 60)
                        .background(Color(hex: 0xEBECEF))
                        .foregroundColor(Color(hex: 0x212121))
                        .accentColor(Color(hex: 0x666666))
                        .cornerRadius(8)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 24)
                        .padding(.horizontal)
                    
                    DatePicker("DOB", selection: $dob, displayedComponents: .date)
                        .datePickerStyle(DefaultDatePickerStyle())
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.leading)
                        .frame(height: 60)
                        .foregroundColor(Color(hex: 0x666666))
                        .multilineTextAlignment(.leading)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    
                    NavigationLink(destination: DeviceBindingWaitingView(onSuccess: onSuccess, onReset: {
                        print("reset cif entry page")
                    }), isActive: $navigateToDeviceBinding) {
                        Button(action: {
                            Task {
                                let isoFormatter = ISO8601DateFormatter()
                                isoFormatter.formatOptions = [.withInternetDateTime]
                                
                                let date = isoFormatter.date(from: dob.ISO8601Format())
                                
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd"
                                
                                print(dateFormatter.string(from: date ?? Date()))
                                if cif.isEmpty {
                                    alertMessage = "CIF cannot be empty"
                                    showAlert = true
                                    return
                                }
                                if pan.isEmpty {
                                    alertMessage = "PAN cannot be empty"
                                    showAlert = true
                                    return
                                }
                                
                                navigateToDeviceBinding = true
                            }
                        }) {
                            Text("Continue").font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: 0x037EAB))
                                .cornerRadius(8)
                        }
                        .padding(.top, 24)
                        .padding(.horizontal)
                        
                    }
                }
            }.background(Color(hex: 0xF5F5F5))
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
        }.navigationBarBackButtonHidden(true)
            .toolbar(.hidden)
    }
}

@available(iOS 16.0, *)
#Preview {
    BankingDetailsView(onSuccess: {
        print("onSuccess")
    })
}
