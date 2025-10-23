//
//  EditorView.swift
//  MarkdownLite
//
//  エディタービュー：Markdown編集 + プレビュー
//

import SwiftUI

struct EditorView: View {
    let file: MarkdownFile
    var driveService: GoogleDriveService

    @State private var content: String = ""
    @State private var isLoading = true
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左：エディター
                VStack(spacing: 0) {
                    // ツールバー
                    EditorToolbar(content: $content)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.appSidebarBg)

                    // テキストエディター
                    TextEditor(text: $content)
                        .font(.system(size: 14, design: .monospaced))
                        .padding(12)
                        .background(Color.appBackground)
                        .onChange(of: content) { _, newValue in
                            scheduleAutoSave(newValue)
                        }
                }
                .frame(width: geometry.size.width / 2)

                Divider()

                // 右：プレビュー
                MarkdownPreviewView(content: content)
                    .frame(width: geometry.size.width / 2)
            }
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFile()
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    private func loadFile() async {
        do {
            let fileContent = try await driveService.downloadFile(fileId: file.id)
            await MainActor.run {
                content = fileContent
                isLoading = false
            }
        } catch {
            print("Failed to load file: \(error)")
            isLoading = false
        }
    }

    private func scheduleAutoSave(_ newContent: String) {
        // 既存の保存タスクをキャンセル
        saveTask?.cancel()

        // 1秒後に保存（デバウンス）
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }

            do {
                try await driveService.uploadFile(fileId: file.id, content: newContent)
                print("Auto-saved")
            } catch {
                print("Failed to save: \(error)")
            }
        }
    }
}

// エディターツールバー
struct EditorToolbar: View {
    @Binding var content: String

    var body: some View {
        HStack(spacing: 16) {
            Button(action: { insertMarkdown("**", "**") }) {
                Image(systemName: "bold")
            }
            Button(action: { insertMarkdown("*", "*") }) {
                Image(systemName: "italic")
            }
            Button(action: { insertMarkdown("`", "`") }) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
            }
            Button(action: { insertMarkdown("[", "](url)") }) {
                Image(systemName: "link")
            }
            Spacer()
        }
        .buttonStyle(.plain)
        .foregroundColor(.appAccent)
    }

    private func insertMarkdown(_ prefix: String, _ suffix: String) {
        content += prefix + suffix
    }
}

#Preview {
    EditorView(
        file: MarkdownFile(id: "1", name: "test.md", content: "# Test"),
        driveService: GoogleDriveService()
    )
}
