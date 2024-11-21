import SwiftUI
import AppKit

// Create observable object class to share state between AppDelegate and SwiftUI views
class AppState: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var contentOpacity: Double = 0
    @Published var showingAIHelper: Bool = false
    @Published var isInteractingWithContent: Bool = false
}

@main
struct NodetoolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Initialize the shared app state before it's used
        AppDelegate.shared.appState = AppState()
    }

    var body: some Scene {
        WindowGroup {
            EmptyView() // We're not using this view since we create our window manually
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

struct MainView: View {
    @ObservedObject var appState: AppState
    let ollamaURL = "http://aiapi.tutelagegroup.com"
    
    var body: some View {
        ZStack {
            if appState.isExpanded {
                ContentView(contentOpacity: $appState.contentOpacity,
                           showingAIHelper: $appState.showingAIHelper)
                    .transition(.opacity)
            } else {
                CompactView()
                    .transition(.opacity)
            }
        }
        .background(Color.black.opacity(0.01)) // Add a nearly invisible background for better hover detection
        .sheet(isPresented: $appState.showingAIHelper) {
            AIHelperView(isPresented: $appState.showingAIHelper, ollamaURL: ollamaURL)
        }
    }
}



class TrackingView: NSView {
    weak var appDelegate: AppDelegate?
    private var interactionTimer: Timer?
    private var hoverDetectionEnabled = true
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        
        // Register for notifications from buttons
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleButtonInteraction),
            name: NSNotification.Name("ButtonInteraction"),
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        interactionTimer?.invalidate()
    }
    
    @objc private func handleButtonInteraction() {
        // When a button is clicked, disable hover detection temporarily
        disableHoverDetection(for: 2.0)
        appDelegate?.cancelCollapseTimer()
    }
    
    private func disableHoverDetection(for seconds: TimeInterval) {
        hoverDetectionEnabled = false
        interactionTimer?.invalidate()
        
        interactionTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.hoverDetectionEnabled = true
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove any existing tracking areas
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        // Add new tracking area with all tracking options
        let trackingArea = NSTrackingArea(
            rect: self.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        print("Mouse entered")
        // Only expand if hover detection is enabled and AI helper is not showing
        if hoverDetectionEnabled && !(appDelegate?.appState.showingAIHelper ?? false) {
            appDelegate?.expandWindow()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        print("Mouse exited")
        
        // Get the current mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation
        
        // Check if mouse is actually outside the window
        if let window = self.window {
            let windowFrame = window.frame
            
            // Give a small margin around the window to prevent accidental exits
            let expandedFrame = NSRect(
                x: windowFrame.origin.x - 5,
                y: windowFrame.origin.y - 5,
                width: windowFrame.width + 10,
                height: windowFrame.height + 10
            )
            
            if expandedFrame.contains(mouseLocation) {
                print("Ignoring false exit")
                return
            }
        }
        
        // Only start collapse timer if hover detection is enabled and AI helper is not showing
        if hoverDetectionEnabled && !(appDelegate?.appState.showingAIHelper ?? false) {
            appDelegate?.startCollapseTimer()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        print("Mouse down")
        let point = self.convert(event.locationInWindow, from: nil)
        
        // If click is on a control or button, disable hover detection
        if let hitView = self.hitTest(point),
           (hitView is NSControl || hitView is NSButton || hitView.className.contains("Button")) {
            disableHoverDetection(for: 2.0)
            NotificationCenter.default.post(name: NSNotification.Name("ButtonInteraction"), object: nil)
        } else {
            // Otherwise, just expand the window if needed
            if hoverDetectionEnabled && !(appDelegate?.appState.showingAIHelper ?? false) {
                appDelegate?.expandWindow()
            }
        }
    }
    
    // Improved hit test logic that better identifies interactive components
    override func hitTest(_ point: NSPoint) -> NSView? {
        if !self.bounds.contains(point) {
            return nil
        }
        
        // Recursively search for interactive components
        func findInteractiveSubview(in view: NSView, at point: NSPoint) -> NSView? {
            for subview in view.subviews.reversed() {
                let convertedPoint = view.convert(point, to: subview)
                
                if !subview.frame.contains(convertedPoint) {
                    continue
                }
                
                // First check if this is an interactive view
                if subview is NSControl ||
                   subview is NSButton ||
                   subview.className.contains("Button") ||
                   subview.className.contains("Control") {
                    return subview
                }
                
                // Then check all its subviews
                if let found = findInteractiveSubview(in: subview, at: convertedPoint) {
                    return found
                }
                
                // If it has bounds and contains the point, return it
                if subview.bounds.contains(convertedPoint) {
                    return subview
                }
            }
            
            return nil
        }
        
        // Try to find an interactive subview first
        if let interactiveSubview = findInteractiveSubview(in: self, at: point) {
            // When we find an interactive subview, disable hover detection
            disableHoverDetection(for: 0.5)
            return interactiveSubview
        }
        
        return super.hitTest(point)
    }
    
    // Actively accept first mouse to make clicks more responsive
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static let shared = AppDelegate()
    var window: NSWindow!
    var appState = AppState() // Initialize here to avoid nil issues
    private var hoverTimer: Timer?
    private let expandedHeight: CGFloat = 180 // Expanded height
    private let collapsedHeight: CGFloat = 18 // Increased height for visibility
    private let windowWidth: CGFloat = 350 // Width for the dynamic island
    private var ollamaURL = "http://aiapi.tutelagegroup.com" // URL for AI helper
    private var trackingView: TrackingView!
    private let topPadding: CGFloat = 45 // Increased padding from the top edge
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        registerForScreenChanges()
        
        // Force an expand and collapse cycle to test functionality
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.expandWindow()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.collapseWindow()
            }
        }
    }
    
    // Set up the initial window
    private func setupWindow() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        
        // Create window frame centered at the top of the screen, below camera
        let windowFrame = NSRect(
            x: (screenFrame.width - windowWidth) / 2,
            y: screenFrame.height - collapsedHeight - topPadding, // Added significant top padding
            width: windowWidth,
            height: collapsedHeight
        )

        // Create window with borderless style and full-size content
        window = NSWindow(
            contentRect: windowFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure window appearance - black pill with visibility
        window.backgroundColor = NSColor.black
        window.isOpaque = false
        window.hasShadow = true // Add shadow for visibility
        window.level = .statusBar // Keep it above other windows
        window.collectionBehavior = [.canJoinAllSpaces, .stationary] // Show on all spaces
        window.isMovableByWindowBackground = false // Fixed position
        
        // Create custom tracking view and set it as the content view
        trackingView = TrackingView(frame: window.contentRect(forFrameRect: windowFrame))
        trackingView.appDelegate = self
        window.contentView = trackingView
        
        // Add SwiftUI content inside the tracking view
        let hostingView = NSHostingView(rootView: MainView(appState: appState))
        hostingView.frame = trackingView.bounds
        hostingView.autoresizingMask = [.width, .height]
        trackingView.addSubview(hostingView)
        
        // IMPORTANT: Enable mouse moved events
        window.acceptsMouseMovedEvents = true
        
        // Set up window delegate and appearance
        window.delegate = self
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 9 // Rounded corners for dynamic island look
        window.contentView?.layer?.masksToBounds = true
        
        // Add a light border for visibility
        window.contentView?.layer?.borderWidth = 0.5
        window.contentView?.layer?.borderColor = NSColor.darkGray.cgColor
        
        // Show the window
        window.makeKeyAndOrderFront(nil)
        
        // Don't steal focus when launching
        NSApp.activate(ignoringOtherApps: false)
    }
    
    // Handle window resize notifications
    func windowDidResize(_ notification: Notification) {
        trackingView.updateTrackingAreas()
    }
    
    // Start timer to collapse window after mouse exit
    func startCollapseTimer() {
        // Cancel any existing timer
        cancelCollapseTimer()
        
        // Don't start a timer if we're interacting with content
        if appState.isInteractingWithContent {
            return
        }
        
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            // Only collapse if AI helper is not showing and we're not interacting with content
            if !(self?.appState.showingAIHelper ?? false) && !(self?.appState.isInteractingWithContent ?? false) {
                DispatchQueue.main.async {
                    self?.collapseWindow()
                }
            }
        }
    }
    
    // Cancel any pending collapse timers
    func cancelCollapseTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }
    
    // Expand the window to show full content
    func expandWindow() {
        guard !appState.isExpanded else { return }
        
        // Cancel any pending collapse
        cancelCollapseTimer()
        
        print("Expanding window")
        
        // Start with content hidden
        DispatchQueue.main.async {
            self.appState.isExpanded = true
            self.appState.contentOpacity = 0
        }
        
        // Animate window expansion
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            // Set larger corner radius for expanded state
            window.contentView?.layer?.cornerRadius = 24
            
            // Expand the window
            window.animator().setFrame(
                NSRect(
                    x: window.frame.origin.x,
                    y: window.frame.origin.y - (expandedHeight - collapsedHeight),
                    width: window.frame.width,
                    height: expandedHeight
                ),
                display: true
            )
            window.backgroundColor = NSColor.black.withAlphaComponent(0.95)
        } completionHandler: {
            // Fade in content after window has expanded
            DispatchQueue.main.async {
                withAnimation(.easeIn(duration: 0.2)) {
                    self.appState.contentOpacity = 1
                }
                self.trackingView.updateTrackingAreas() // Update tracking area after resize
            }
        }
    }
    
    // Collapse the window to minimized state
    func collapseWindow() {
        guard appState.isExpanded else { return }
        
        // Don't collapse if the AI helper is open or we're interacting with content
        if appState.showingAIHelper || appState.isInteractingWithContent {
            return
        }
        
        print("Collapsing window")
        
        // Hide content first
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                self.appState.contentOpacity = 0
            }
        }
        
        // Small delay to allow content to fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Animate window collapse
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                
                // Smaller corner radius for collapsed state
                self.window.contentView?.layer?.cornerRadius = 9
                
                // Shrink the window
                self.window.animator().setFrame(
                    NSRect(
                        x: self.window.frame.origin.x,
                        y: self.window.frame.origin.y + (self.expandedHeight - self.collapsedHeight),
                        width: self.window.frame.width,
                        height: self.collapsedHeight
                    ),
                    display: true
                )
                self.window.backgroundColor = NSColor.black
            } completionHandler: {
                DispatchQueue.main.async {
                    self.appState.isExpanded = false
                    self.trackingView.updateTrackingAreas() // Update tracking area after resize
                }
            }
        }
    }
    
    // Handle sheet presentation (like AI Helper)
    func sheetWillPresent() {
        // Make sure we don't collapse when a sheet is open
        cancelCollapseTimer()
    }
    
    // Handle screen resolution changes
    private func registerForScreenChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func screenParametersDidChange() {
        // Reposition the window if the screen changes
        let screenFrame = NSScreen.main?.frame ?? .zero
        
        // If expanded, keep it expanded but reposition
        if appState.isExpanded {
            window.setFrame(
                NSRect(
                    x: (screenFrame.width - windowWidth) / 2,
                    y: screenFrame.height - expandedHeight - topPadding,
                    width: windowWidth,
                    height: expandedHeight
                ),
                display: true
            )
        } else {
            window.setFrame(
                NSRect(
                    x: (screenFrame.width - windowWidth) / 2,
                    y: screenFrame.height - collapsedHeight - topPadding,
                    width: windowWidth,
                    height: collapsedHeight
                ),
                display: true
            )
        }
        
        // Update the tracking area after repositioning
        trackingView.updateTrackingAreas()
    }
    
    // Handle app reopening
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window.makeKeyAndOrderFront(nil)
        return true
    }
    
    // If needed, handle window resize constraints
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // Enforce minimum width
        return NSSize(width: max(frameSize.width, windowWidth), height: frameSize.height)
    }
}
