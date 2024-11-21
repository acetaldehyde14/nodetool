import SwiftUI

struct DynamicIslandMedicationButton: View {
    @StateObject private var medicationTracker = MedicationTrackerManager()
    @State private var showingMedicationTracker = false
    @State private var showingQuickLogSheet = false
    
    private var todayIntake: MedicationIntake? {
        medicationTracker.medicationIntakes
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }
    
    var body: some View {
        Button(action: {
            // Notify about button interaction
            NotificationCenter.default.post(name: NSNotification.Name("ButtonInteraction"), object: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // If a medication was taken today and not rated, show quick log sheet
                if let intake = todayIntake, intake.effectRating == nil {
                    showingQuickLogSheet = true
                } else {
                    // Otherwise show the full tracker
                    showingMedicationTracker = true
                }
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "pill")
                
                if let intake = todayIntake {
                    if let rating = intake.effectRating {
                        // Show rating if available
                        Text("\(rating)/10")
                            .font(.system(size: 12))
                    } else {
                        // Show time since intake
                        Text(formatTimeSince(intake.timestamp))
                            .font(.system(size: 12))
                    }
                } else {
                    Text("Ritalin")
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(getPillBackground())
            )
            .foregroundColor(.white)
            .contentShape(Rectangle()) // Ensure the entire button is clickable
        }
        .buttonStyle(PlainButtonStyle())
        // Use standard SwiftUI sheet instead of properSheet
        .sheet(isPresented: $showingMedicationTracker) {
            // We don't pass any parameters to MedicationTrackerView since it seems
            // it doesn't take any based on the error
            MedicationTrackerView()
        }
        .sheet(isPresented: $showingQuickLogSheet) {
            if let intake = todayIntake {
                QuickMedicationLog(
                    medicationTracker: medicationTracker,
                    intakeID: intake.id,
                    isPresented: $showingQuickLogSheet,
                    onShowFullTracker: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingMedicationTracker = true
                        }
                    }
                )
            }
        }
    }
    
    private func getPillBackground() -> Color {
        if let intake = todayIntake {
            // Determine color based on time since intake
            let hoursSince = Calendar.current.dateComponents([.hour], from: intake.timestamp, to: Date()).hour ?? 0
            
            if intake.effectRating != nil {
                // If rated, use a muted color
                return Color.purple.opacity(0.7)
            } else if hoursSince < 2 {
                // Recently taken, active
                return Color.green
            } else if hoursSince < 4 {
                // Mid-duration
                return Color.blue
            } else {
                // Wearing off
                return Color.orange
            }
        } else {
            // No medication taken today
            return Color.gray
        }
    }
    
    private func formatTimeSince(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date, to: Date())
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// Quick log view that appears when you tap the pill icon and have an unrated medication
struct QuickMedicationLog: View {
    @ObservedObject var medicationTracker: MedicationTrackerManager
    let intakeID: UUID
    @Binding var isPresented: Bool
    let onShowFullTracker: () -> Void
    
    @State private var currentEffect: Int = 5
    @State private var notes: String = ""
    
    var intake: MedicationIntake? {
        medicationTracker.medicationIntakes.first { $0.id == intakeID }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("How's your Ritalin working?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let intake = intake {
                        Text("Taken \(formatTimeSince(intake.timestamp)) ago")
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            // Current effectiveness rating
            VStack(spacing: 5) {
                Text("Current effectiveness")
                    .font(.headline)
                
                HStack {
                    Text("1")
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { Double(currentEffect) },
                        set: { currentEffect = Int($0) }
                    ), in: 1...10, step: 1)
                    
                    Text("10")
                        .foregroundColor(.secondary)
                }
                
                Text("\(currentEffect)/10")
                    .font(.title)
                    .padding(.top, 5)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            
            // Quick notes
            VStack(alignment: .leading, spacing: 5) {
                Text("Quick notes")
                    .font(.headline)
                
                TextField("How are you feeling? (optional)", text: $notes)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Log buttons
            HStack(spacing: 15) {
                Button(action: {
                    logPoint()
                }) {
                    Text("Log Data Point")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    isPresented = false
                    onShowFullTracker()
                }) {
                    Text("Full Tracker")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    private func logPoint() {
        // Calculate minutes since medication was taken
        let minutesSince: Int
        if let intake = intake {
            minutesSince = Calendar.current.dateComponents([.minute], from: intake.timestamp, to: Date()).minute ?? 0
        } else {
            minutesSince = 0
        }
        
        // Add data point to the medication
        medicationTracker.updateEffectPattern(
            for: intakeID,
            timeOffset: minutesSince,
            effectStrength: currentEffect,
            notes: notes
        )
        
        // Create a small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
    
    private func formatTimeSince(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date, to: Date())
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
