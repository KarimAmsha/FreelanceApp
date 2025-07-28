//
//  EditProfileCardView.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 28.07.2025.
//

import SwiftUI

struct EditProfileCardView: View {
    @ObservedObject var mediaPickerViewModel: MediaPickerViewModel
    @Binding var showCustomSheet: Bool
    var imageUrl: String?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            profileImageView()
                .frame(width: 78, height: 78)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .background(Circle().fill(Color.white).frame(width: 84, height: 84))
                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
                .padding(.trailing, 2)

            Button(action: { showCustomSheet = true }) {
                Text("اضغط لرفع صورة جديدة")
                    .customFont(weight: .medium, size: 15)
                    .foregroundColor(Color.black121212())
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 2)

            Spacer()

            if mediaPickerViewModel.getImage(for: .profileImage) != nil {
                Button(action: {
                    mediaPickerViewModel.removeMedia(for: .profileImage)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())
                }
                .padding(.leading, 2)
            } else {
                Spacer().frame(width: 44)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.white, Color(.systemGray6)]), startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.03), radius: 9, x: 0, y: 3)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .environment(\.layoutDirection, .rightToLeft)
    }

    @ViewBuilder
    private func profileImageView() -> some View {
        if let selectedImage = mediaPickerViewModel.getImage(for: .profileImage) {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
        } else if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
        } else {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFill()
                .foregroundColor(.gray)
        }
    }
}
