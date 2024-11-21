import SwiftUI
import AppKit

// Keep track of window delegates
private var delegateStore = [String: Any]()

// Custom sheet presenter that ensures proper sizing and presentation
struct ProperSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> SheetContent
    let width: CGFloat
    let height: CGFloat
    
    @State private var window: NSWindow?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    openSheet()
                } else {
                    closeSheet()
                }
            }
    }
    
    private func openSheet() {
        guard window == nil else { return }
        
        // Create a new window for the sheet
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        // Center the window on screen
        window.center()
        
        // Set the content view
        window.contentView = NSHostingView(rootView: self.content())
        
        // Set window properties
        window.title = "Medication Tracker"
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        // Store reference to window
        self.window = window
        
        // Set the window delegate to handle closing
        let delegateId = UUID().uuidString
        let delegate = SheetWindowDelegate(isPresented: $isPresented)
        window.delegate = delegate
        
        // Keep the delegate alive while the window is open
        delegateStore[delegateId] = delegate
    }
    
    private func closeSheet() {
        window?.close()
        window = nil
    }
}

// Window delegate to handle closing events
class SheetWindowDelegate: NSObject, NSWindowDelegate {
    @Binding var isPresented: Bool
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        isPresented = false
    }
}

// Extension to make it easy to use the custom sheet presenter
extension View {
    func properSheet<Content: View>(
        isPresented: Binding<Bool>,
        width: CGFloat = 600,
        height: CGFloat = 700,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(ProperSheetModifier(isPresented: isPresented, content: content, width: width, height: height))
    }
}
