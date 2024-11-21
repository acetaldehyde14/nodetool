import SwiftUI
import Foundation
import IOKit.ps

struct CompactView: View {
    @State private var currentTime = Date()
    @State private var isSpotifyPlaying = false
    @State private var batteryLevel: Int = 100
    @State private var isCharging: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 10) {
            // Time display
            Text(timeString)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            // Center pill indicator
            HStack(spacing: 4) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3, height: 3)
                }
            }
            
            Spacer()
            
            // Battery status
            HStack(spacing: 3) {
                Image(systemName: batteryIcon)
                    .font(.system(size: 9))
                    .foregroundColor(batteryColor)
                
                Text("\(batteryLevel)%")
                    .font(.system(size: 9))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(timer) { _ in
            currentTime = Date()
            updateSpotifyStatus()
            updateBatteryStatus()
        }
        .onAppear {
            updateSpotifyStatus()
            updateBatteryStatus()
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
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
    
    private var batteryColor: Color {
        if isCharging {
            return .green
        }
        switch batteryLevel {
        case 0...20: return .red
        case 21...50: return .yellow
        default: return .white
        }
    }
    
    private func updateSpotifyStatus() {
        if let spotify = NSAppleScript(source: """
            tell application "Spotify"
                try
                    set currentState to player state as string
                    return currentState
                on error
                    return "stopped"
                end try
            end tell
            """)?.executeAndReturnError(nil).stringValue {
            
            isSpotifyPlaying = spotify == "playing"
        } else {
            isSpotifyPlaying = false
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
}

