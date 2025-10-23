//
//  SidebarView.swift
//  MarkdownLite
//
//  サイドバー：ファイル一覧表示
//

import SwiftUI

struct SidebarView: View {
    var driveService: GoogleDriveService
    @Binding var selectedFile: MarkdownFile?
    @State private var searchText = ""

    var filteredFiles: [MarkdownFile] {
        if searchText.isEmpty {
            return driveService.files
        }
        return driveService.files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(filteredFiles, selection: $selectedFile) { file in
            HStack {
                Image(systemName: file.isFolder ? "folder.fill" : "doc.text")
                    .foregroundColor(file.isFolder ? .appAccent : .appTextSecondary)
                Text(file.name)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 4)
        }
        .searchable(text: $searchText, prompt: "ファイルを検索")
        .navigationTitle("Markdown Lite")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: refreshFiles) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: createNewFile) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await loadFiles()
        }
    }

    private func loadFiles() async {
        do {
            let files = try await driveService.fetchFiles()
            await MainActor.run {
                driveService.files = files
            }
        } catch {
            print("Failed to load files: \(error)")
        }
    }

    private func refreshFiles() {
        Task {
            await loadFiles()
        }
    }

    private func createNewFile() {
        Task {
            do {
                let newFile = try await driveService.createFile(
                    name: "新規ファイル.md",
                    content: "# 新規ファイル\n\n",
                    parentId: nil
                )
                await loadFiles()
                selectedFile = newFile
            } catch {
                print("Failed to create file: \(error)")
            }
        }
    }
}

#Preview {
    SidebarView(
        driveService: GoogleDriveService(),
        selectedFile: .constant(nil)
    )
}
