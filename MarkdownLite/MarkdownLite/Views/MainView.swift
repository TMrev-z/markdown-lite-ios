//
//  MainView.swift
//  MarkdownLite
//
//  メインビュー：サイドバー + エディター + プレビュー
//

import SwiftUI

struct MainView: View {
    @StateObject private var driveService = GoogleDriveService()
    @State private var selectedFile: MarkdownFile?
    @State private var showingSignIn = false

    var body: some View {
        NavigationSplitView {
            // サイドバー（ファイル一覧）
            SidebarView(
                driveService: driveService,
                selectedFile: $selectedFile
            )
        } detail: {
            // エディター + プレビュー
            if let file = selectedFile {
                EditorView(file: file, driveService: driveService)
            } else {
                ContentUnavailableView(
                    "ファイルを選択してください",
                    systemImage: "doc.text",
                    description: Text("左のサイドバーからMarkdownファイルを選択")
                )
            }
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView(driveService: driveService)
        }
        .onAppear {
            if !driveService.isAuthenticated {
                showingSignIn = true
            }
        }
    }
}

#Preview {
    MainView()
}
