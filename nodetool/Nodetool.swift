// NodetoolApp.swift
import SwiftUI
import AppKit

@main
struct NodetoolApp: App {    // Changed from NodeToolApp to NodetoolApp to match file name
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
    }
    
    private func setupWindow() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 30
        
        let cameraOffset: CGFloat = 45
        let topPadding: CGFloat = 5
        
        let windowFrame = NSRect(
            x: (screenFrame.width - windowWidth) / 2,
            y: screenFrame.height - cameraOffset - windowHeight - topPadding,
            width: windowWidth,
            height: windowHeight
        )
        
        window = NSWindow(
            contentRect: windowFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovableByWindowBackground = true
        
        window.contentView = NSHostingView(rootView: ContentView())
        window.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: false)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window.makeKeyAndOrderFront(nil)
        return true
    }
}
