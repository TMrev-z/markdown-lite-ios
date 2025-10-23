//
//  MarkdownLiteApp.swift
//  MarkdownLite
//
//  Created by TMiyazaki on 2025/10/23.
//

import SwiftUI
import GoogleSignIn

@main
struct MarkdownLiteApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
