//
//  GoogleDriveService.swift
//  MarkdownLite
//
//  Google Drive API連携サービス (REST API使用)
//

import Foundation
import Combine
import SwiftUI
import GoogleSignIn

class GoogleDriveService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var files: [MarkdownFile] = []

    private var accessToken: String?
    private let baseURL = "https://www.googleapis.com/drive/v3"

    // MARK: - Authentication

    func authenticate() async throws {
        guard let presentingViewController = await getRootViewController() else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No presenting view controller"])
        }

        let signInConfig = GIDConfiguration(clientID: "YOUR_CLIENT_ID") // Google Cloud Consoleで取得

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController,
            hint: nil,
            additionalScopes: ["https://www.googleapis.com/auth/drive.file"]
        )

        accessToken = result.user.accessToken.tokenString
        await MainActor.run {
            isAuthenticated = true
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        accessToken = nil
        isAuthenticated = false
    }

    // MARK: - File Operations

    func fetchFiles(folderId: String? = nil) async throws -> [MarkdownFile] {
        guard let token = accessToken else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        var urlString = "\(baseURL)/files?fields=files(id,name,mimeType,modifiedTime,parents)"
        if let folderId = folderId {
            urlString += "&q='\(folderId)'+in+parents"
        } else {
            urlString += "&q='root'+in+parents"
        }

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(DriveFileListResponse.self, from: data)

        return response.files.map { file in
            MarkdownFile(
                id: file.id,
                name: file.name,
                content: "",
                modifiedDate: ISO8601DateFormatter().date(from: file.modifiedTime) ?? Date(),
                mimeType: file.mimeType,
                parentId: file.parents?.first
            )
        }
    }

    func downloadFile(fileId: String) async throws -> String {
        guard let token = accessToken else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let urlString = "\(baseURL)/files/\(fileId)?alt=media"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }

    func uploadFile(fileId: String, content: String) async throws {
        guard let token = accessToken else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let urlString = "https://www.googleapis.com/upload/drive/v3/files/\(fileId)?uploadType=media"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("text/markdown", forHTTPHeaderField: "Content-Type")
        request.httpBody = content.data(using: .utf8)

        _ = try await URLSession.shared.data(for: request)
    }

    func createFile(name: String, content: String, parentId: String?) async throws -> MarkdownFile {
        guard let token = accessToken else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Step 1: Create file metadata
        let metadata: [String: Any] = [
            "name": name,
            "mimeType": "text/markdown",
            "parents": parentId != nil ? [parentId!] : ["root"]
        ]

        let metadataData = try JSONSerialization.data(withJSONObject: metadata)

        let boundary = "----Boundary\(UUID().uuidString)"
        var body = Data()

        // Multipart body
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataData)
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/markdown\r\n\r\n".data(using: .utf8)!)
        body.append(content.data(using: .utf8)!)
        body.append("\r\n--\(boundary)--".data(using: .utf8)!)

        let urlString = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let file = try JSONDecoder().decode(DriveFile.self, from: data)

        return MarkdownFile(
            id: file.id,
            name: file.name,
            content: content,
            modifiedDate: Date(),
            mimeType: file.mimeType,
            parentId: parentId
        )
    }

    func deleteFile(fileId: String) async throws {
        guard let token = accessToken else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let urlString = "\(baseURL)/files/\(fileId)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Helper

    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
}

// MARK: - Response Models

struct DriveFileListResponse: Codable {
    let files: [DriveFile]
}

struct DriveFile: Codable {
    let id: String
    let name: String
    let mimeType: String
    let modifiedTime: String
    let parents: [String]?
}
