//
//  MarkdownFile.swift
//  MarkdownLite
//
//  Markdownファイルのデータモデル
//

import Foundation

struct MarkdownFile: Identifiable, Codable, Hashable {
    let id: String // Google Drive File ID
    var name: String
    var content: String
    var modifiedDate: Date
    var mimeType: String
    var parentId: String? // フォルダID

    var isFolder: Bool {
        mimeType == "application/vnd.google-apps.folder"
    }

    init(id: String, name: String, content: String = "", modifiedDate: Date = Date(), mimeType: String = "text/markdown", parentId: String? = nil) {
        self.id = id
        self.name = name
        self.content = content
        self.modifiedDate = modifiedDate
        self.mimeType = mimeType
        self.parentId = parentId
    }
}
