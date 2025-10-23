//
//  SignInView.swift
//  MarkdownLite
//
//  Google Sign-In画面
//

import SwiftUI

struct SignInView: View {
    var driveService: GoogleDriveService
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthenticating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // ロゴ
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(.appAccent)

            VStack(spacing: 12) {
                Text("Markdown Lite")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Google Driveと連携して\nMarkdownを編集")
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: signIn) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                        Text("Googleでサインイン")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isAuthenticating)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .overlay {
            if isAuthenticating {
                ProgressView()
            }
        }
    }

    private func signIn() {
        isAuthenticating = true
        errorMessage = nil

        Task {
            do {
                try await driveService.authenticate()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    errorMessage = "サインインに失敗しました"
                }
            }
        }
    }
}

#Preview {
    SignInView(driveService: GoogleDriveService())
}
