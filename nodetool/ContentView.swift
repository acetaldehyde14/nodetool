import SwiftUI
import Foundation
import EventKit
import IOKit.ps
import ScriptingBridge
struct ActionButtonsRow: View {
    var body: some View {
        HStack(spacing: 8) {
            // Medication tracker
            DynamicIslandMedicationButton()// Just add this line after your DynamicIslandMedicationButton
            // Just add this line after your DynamicIslandMedicationButton
            ProductivityButton()
            
            Spacer()
            LogViewerButton()
            // Study session quick start
            StudyButton()
            
            // Focus mode
            FocusButton()
        }
        .padding(.horizontal, 16)
    }
}



struct ContentView: View {
    @State private var currentTime = Date()
    @State private var calendar = Calendar.current
    @Binding var contentOpacity: Double
    @Binding var showingAIHelper: Bool
    @State private var batteryLevel: Int = 100
    @State private var isCharging: Bool = false
    @State private var events: [EKEvent] = []
    @State private var spotifyTrackInfo = "No track playing"
    @State private var isSpotifyPlaying = false
    @State private var currentArtist = "No artist"
    @State private var currentTrack = "No track"
    @State private var weatherTemp = "12°"
    @State private var weatherCondition = "Light Rain"
    @State private var location = "Current Location"
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let eventStore = EKEventStore()
    let ollamaURL = "http://aiweb.tutelagegroup.com" // Replace with your Ollama server URL

    var body: some View {
        VStack(spacing: 8) {
            // Main display with time and date
            HStack {
                // Left side - Weather
                VStack(alignment: .leading, spacing: 2) {
                    Text(weatherTemp)
                        .font(.system(size: 22, weight: .medium))
                    Text(location)
                        .font(.system(size: 12))
                        .opacity(0.7)
                }
                
                Spacer()
                
                // Center - Time and Date
                VStack(spacing: 2) {
                    Text(timeString)
                        .font(.system(size: 36, weight: .semibold))
                    Text(dateString)
                        .font(.system(size: 13))
                        .opacity(0.8)
                }
                
                Spacer()
                
                // Right side - Weather condition
                VStack(alignment: .trailing, spacing: 2) {
                    HStack {
                        Image(systemName: weatherIcon)
                            .font(.system(size: 20))
                        Text(weatherCondition)
                            .font(.system(size: 14))
                    }
                    Text("Humidity: 65%")
                        .font(.system(size: 12))
                        .opacity(0.7)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            
            // Quick Action Buttons
            ActionButtonsRow()
            .padding(.horizontal, 16)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 8)
            
            // Calendar events
            VStack(alignment: .leading, spacing: 4) {
                ForEach(events.prefix(2), id: \.eventIdentifier) { event in
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text(event.title ?? "Untitled Event")
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                        Spacer()
                        Text(formatEventTime(event.startDate))
                            .font(.system(size: 14))
                            .opacity(0.8)
                    }
                }
                
                if events.isEmpty {
                    HStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                        Text("No upcoming events")
                            .font(.system(size: 14))
                            .opacity(0.7)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 8)
            
            // Spotify controls
            HStack {
                // Album art placeholder (can be improved with actual album art)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                    )
                
                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentTrack)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    Text(currentArtist)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Playback controls
                HStack(spacing: 12) {
                    Button(action: previousTrack) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: playPauseSpotify) {
                        Image(systemName: isSpotifyPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: nextTrack) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Battery status
                HStack(spacing: 4) {
                    Image(systemName: batteryIcon)
                        .font(.system(size: 14))
                    Text("\(batteryLevel)%")
                        .font(.system(size: 12))
                }
                .padding(.leading, 8)
                
                // AI Helper button - updated to use the shared binding
                Button(action: {
                    showingAIHelper = true
                    // This tells AppDelegate not to collapse while showing AI helper
                    let appDelegate = AppDelegate.shared
                    appDelegate.cancelCollapseTimer()
                }) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 6)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .foregroundColor(.white)
        .opacity(contentOpacity)
        .background(Color.black.opacity(0.01)) // Makes hover detection more reliable
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            requestCalendarAccess()
            updateBatteryStatus()
            updateSpotifyStatus()
            simulateWeatherData() // In a real app, you'd fetch actual weather data
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateBatteryStatus()
            updateCalendarEvents()
            updateSpotifyStatus()
        }
    }
    
    // Rest of your ContentView implementation...

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        return formatter.string(from: currentTime)
    }

    private var batteryIcon: String {
        if isCharging {
            return "battery.100.bolt"
        }
        switch batteryLevel {
        case 0...20: return "battery.25"
        case 21...50: return "battery.50"
        case 51...80: return "battery.75"
        default: return "battery.100"
        }
    }
    
    // Weather icon based on condition
    private var weatherIcon: String {
        switch weatherCondition.lowercased() {
        case let s where s.contains("rain"): return "cloud.rain"
        case let s where s.contains("cloud"): return "cloud"
        case let s where s.contains("sun") || s.contains("clear"): return "sun.max"
        case let s where s.contains("snow"): return "snow"
        case let s where s.contains("fog") || s.contains("mist"): return "cloud.fog"
        case let s where s.contains("wind"): return "wind"
        default: return "cloud.sun"
        }
    }

    // Format event time to be more human-readable
    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func requestCalendarAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                if granted {
                    updateCalendarEvents()
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    updateCalendarEvents()
                }
            }
        }
    }

    private func updateCalendarEvents() {
        let predicate = eventStore.predicateForEvents(
            withStart: Date(),
            end: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            calendars: nil
        )
        DispatchQueue.main.async {
            self.events = eventStore.events(matching: predicate)
                .sorted { $0.startDate < $1.startDate }
        }
    }

    private func updateBatteryStatus() {
        let powerSource = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerSourcesList = IOPSCopyPowerSourcesList(powerSource).takeRetainedValue() as Array

        for ps in powerSourcesList {
            if let powerSourceDesc = IOPSGetPowerSourceDescription(powerSource, ps).takeUnretainedValue() as? [String: Any] {
                batteryLevel = powerSourceDesc[kIOPSCurrentCapacityKey] as? Int ?? 100
                let powerSourceState = powerSourceDesc[kIOPSPowerSourceStateKey] as? String
                isCharging = powerSourceState == kIOPSACPowerValue
            }
        }
    }

    private func updateSpotifyStatus() {
        if let spotify = NSAppleScript(source: """
            tell application "Spotify"
                try
                    set currentState to player state as string
                    if currentState is not "stopped" then
                        set currentArtist to artist of current track
                        set currentTrack to name of current track
                        return currentState & "|" & currentArtist & "|" & currentTrack
                    else
                        return "stopped||"
                    end if
                on error
                    return "stopped||"
                end try
            end tell
            """)?.executeAndReturnError(nil).stringValue {

            let components = spotify.components(separatedBy: "|")
            if components.count >= 3 {
                let state = components[0]
                let artist = components[1]
                let track = components[2]

                self.isSpotifyPlaying = state == "playing"
                self.currentArtist = artist
                self.currentTrack = track
                
                if state == "playing" {
                    spotifyTrackInfo = "\(artist) - \(track)"
                } else if state == "paused" {
                    spotifyTrackInfo = "Paused: \(artist) - \(track)"
                } else {
                    spotifyTrackInfo = "No track playing"
                    self.currentArtist = "No artist"
                    self.currentTrack = "No track"
                }
            } else {
                spotifyTrackInfo = "No track playing"
                self.currentArtist = "No artist"
                self.currentTrack = "No track"
                self.isSpotifyPlaying = false
            }
        } else {
            spotifyTrackInfo = "Spotify not available"
            self.currentArtist = "No artist"
            self.currentTrack = "No track"
            self.isSpotifyPlaying = false
        }
    }

    private func playPauseSpotify() {
        NSAppleScript(source: """
            tell application "Spotify"
                if player state is playing then
                    pause
                else
                    play
                end if
            end tell
            """)?.executeAndReturnError(nil)
    }

    private func nextTrack() {
        NSAppleScript(source: """
            tell application "Spotify"
                next track
            end tell
            """)?.executeAndReturnError(nil)
    }

    private func previousTrack() {
        NSAppleScript(source: """
            tell application "Spotify"
                previous track
            end tell
            """)?.executeAndReturnError(nil)
    }
    
    // For demonstration purposes
    private func simulateWeatherData() {
        // In a real app, you would fetch this data from a weather API
        // This is just to populate the UI with sample data
        let weatherConditions = ["Light Rain", "Cloudy", "Partly Cloudy", "Sunny", "Overcast"]
        let temperatures = ["12°", "15°", "18°", "22°", "9°"]
        let locations = ["San Francisco", "New York", "London", "Tokyo", "Current Location"]
        
        let randomIndex = Int.random(in: 0..<weatherConditions.count)
        weatherCondition = weatherConditions[randomIndex]
        weatherTemp = temperatures[randomIndex]
        location = locations[randomIndex]
    }
}

// SwiftUI onHover extension for macOS
extension View {
    func onHover(perform action: @escaping (Bool) -> Void) -> some View {
        modifier(HoverModifier(hoverAction: action))
    }
}

struct HoverModifier: ViewModifier {
    let hoverAction: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .onMouseEnter { hoverAction(true) }
            .onMouseExit { hoverAction(false) }
    }
}

extension View {
    func onMouseEnter(perform action: @escaping () -> Void) -> some View {
        self.modifier(MouseEnterModifier(mouseEnter: action))
    }
    
    func onMouseExit(perform action: @escaping () -> Void) -> some View {
        self.modifier(MouseExitModifier(mouseExit: action))
    }
}

struct MouseEnterModifier: ViewModifier {
    let mouseEnter: () -> Void
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onContinuousHover(
            onChanged: { _ in
                self.mouseEnter()
            },
            onEnded: { _ in
                // Do nothing on ended
            }
        )
        #else
        content
        #endif
    }
}

struct MouseExitModifier: ViewModifier {
    let mouseExit: () -> Void
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onContinuousHover(
            onChanged: { _ in
                // Do nothing on changed
            },
            onEnded: { _ in
                self.mouseExit()
            }
        )
        #else
        content
        #endif
    }
}

// Fix for macOS hover detection
extension View {
    @ViewBuilder func onContinuousHover(
        onChanged: @escaping (CGPoint) -> Void,
        onEnded: @escaping (CGPoint) -> Void
    ) -> some View {
        #if os(macOS)
        self.overlay(
            GeometryReader { geo in
                MouseHoverView(localFrame: geo.frame(in: .local),
                              onChanged: onChanged,
                              onEnded: onEnded)
            }
        )
        #else
        self
        #endif
    }
}

#if os(macOS)
struct MouseHoverView: NSViewRepresentable {
    var localFrame: CGRect
    var onChanged: (CGPoint) -> Void
    var onEnded: (CGPoint) -> Void

    final class TrackingAreaView: NSView {
        var trackingArea: NSTrackingArea?
        var onChanged: ((CGPoint) -> Void)?
        var onEnded: ((CGPoint) -> Void)?
        var localFrame: CGRect = .zero
        
        override func updateTrackingAreas() {
            if let trackingArea = trackingArea {
                removeTrackingArea(trackingArea)
            }
            
            trackingArea = NSTrackingArea(
                rect: localFrame,
                options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved],
                owner: self,
                userInfo: nil
            )
            
            if let trackingArea = trackingArea {
                addTrackingArea(trackingArea)
            }
        }
        
        override func mouseMoved(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            onChanged?(point)
        }
        
        override func mouseEntered(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            onChanged?(point)
        }
        
        override func mouseExited(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            onEnded?(point)
        }
    }

    func makeNSView(context: Context) -> TrackingAreaView {
        let view = TrackingAreaView()
        view.localFrame = localFrame
        view.onChanged = onChanged
        view.onEnded = onEnded
        return view
    }

    func updateNSView(_ nsView: TrackingAreaView, context: Context) {
        nsView.localFrame = localFrame
        nsView.onChanged = onChanged
        nsView.onEnded = onEnded
        nsView.updateTrackingAreas()
    }
}
#endif
