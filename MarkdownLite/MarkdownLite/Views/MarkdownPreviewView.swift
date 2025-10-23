//
//  MarkdownPreviewView.swift
//  MarkdownLite
//
//  Markdownプレビュー
//

import SwiftUI
import WebKit

struct MarkdownPreviewView: UIViewRepresentable {
    let content: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .white
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = renderMarkdownToHTML(content)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func renderMarkdownToHTML(_ markdown: String) -> String {
        // 簡易的なMarkdown→HTML変換（基本的なもののみ）
        var html = markdown

        // ヘッダー
        html = html.replacingOccurrences(of: #"^######\s+(.+)$"#, with: "<h6>$1</h6>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^#####\s+(.+)$"#, with: "<h5>$1</h5>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^####\s+(.+)$"#, with: "<h4>$1</h4>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^###\s+(.+)$"#, with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^##\s+(.+)$"#, with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^#\s+(.+)$"#, with: "<h1>$1</h1>", options: .regularExpression)

        // 太字・イタリック
        html = html.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)

        // コード
        html = html.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)

        // リンク
        html = html.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)

        // 改行
        html = html.replacingOccurrences(of: "\n", with: "<br>")

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {
                    font-family: -apple-system, system-ui, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: #111;
                    padding: 16px;
                    max-width: 820px;
                    margin: 0 auto;
                }
                h1 { font-size: 28px; margin: 24px 0 16px; }
                h2 { font-size: 24px; margin: 20px 0 12px; }
                h3 { font-size: 20px; margin: 16px 0 8px; }
                code {
                    background: #F8F8F8;
                    border: 1px solid #EEEEEE;
                    border-radius: 4px;
                    padding: 2px 6px;
                    font-family: ui-monospace, Menlo, Consolas, monospace;
                    font-size: 13px;
                }
                a {
                    color: #007AFF;
                    text-decoration: none;
                }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
    }
}

#Preview {
    MarkdownPreviewView(content: "# Hello\n\nThis is **bold** and *italic*.")
}
