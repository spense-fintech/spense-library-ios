//
//  SwiftUIView.swift
//  
//
//  Created by Varun on 25/01/24.
//

import SwiftUI

@available(iOS 16.0, *)
struct LoaderView: View {
    var body: some View {
        ZStack {
                    Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(2)
                            .frame(width: 75, height: 75)
                            .padding(.horizontal, 48)
                        
                        Text("Please wait!")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: 0x212121))
                            .padding(.top)
                            
                        // Process text
                        Text("Processing...")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: 0x666666))
                            .padding(.top, 8)
                    }
                    .padding(24) // Adjust padding to match your Android layout
                    .background(Color.white) // CardView background
                    .cornerRadius(12) // Adjust the corner radius as per your Android `cardCornerRadius`
                    .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.2) // Adjust width and height as needed
                }
    }
}

@available(iOS 16.0, *)
#Preview {
    LoaderView()
}
