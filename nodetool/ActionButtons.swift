import SwiftUI
import Foundation

// Study button implementation
struct StudyButton: View {
    @State private var showingStartSession = false
    @StateObject private var medicationTracker = MedicationTrackerManager()
    
    var body: some View {
        Button(action: {
            // Notify about button interaction to prevent window collapse
            NotificationCenter.default.post(name: NSNotification.Name("ButtonInteraction"), object: nil)
            showingStartSession = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text("Study")
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.8))
            )
            .foregroundColor(.white)
        }
        // Use the existing NoCollapseButtonStyle instead of redeclaring it
        .buttonStyle(PlainButtonStyle())
        .properSheet(isPresented: $showingStartSession, width: 500, height: 600) {
                   StudySessionView(medicationTracker: medicationTracker)
               }
    }
}

// Focus mode button implementation
struct FocusButton: View {
    @State private var isFocusModeActive = false
    @State private var focusDuration: TimeInterval = 25 * 60 // 25 minutes in seconds
    @State private var timer: Timer?
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var showingSettings = false
    
    var body: some View {
        Button(action: {
            // Notify about button interaction to prevent window collapse
            NotificationCenter.default.post(name: NSNotification.Name("ButtonInteraction"), object: nil)
            
            if isFocusModeActive {
                // Stop focus mode
                stopFocusMode()
            } else {
                // Show settings or start with default settings
                showingSettings = true
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isFocusModeActive ? "moon.stars.fill" : "moon.stars")
                
                if isFocusModeActive {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 12))
                } else {
                    Text("Focus")
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocusModeActive ? Color.purple : Color.purple.opacity(0.8))
            )
            .foregroundColor(.white)
        }
        // Use the existing NoCollapseButtonStyle instead of redeclaring it
        .buttonStyle(PlainButtonStyle())
        .properSheet(isPresented: $showingSettings, width: 500, height: 400) {
                    FocusModeSettingsView(
                        duration: $focusDuration,
                        onStart: {
                            startFocusMode()
                            showingSettings = false
                        },
                        onCancel: {
                            showingSettings = false
                        }
                    )
                }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startFocusMode() {
        isFocusModeActive = true
        timeRemaining = focusDuration
        
        // Start the timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Time's up - notify user and end focus mode
                sendFocusModeCompletionNotification()
                stopFocusMode()
            }
        }
    }
    
    private func stopFocusMode() {
        timer?.invalidate()
        timer = nil
        isFocusModeActive = false
    }
    
    private func sendFocusModeCompletionNotification() {
        let notification = NSUserNotification()
        notification.title = "Focus Time Complete"
        notification.informativeText = "Great job! You've completed your focus session."
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// The ActionButtonsRow component to use in ContentView
struct QuickActionButtonsRow: View {
    var body: some View {
        HStack(spacing: 8) {
            // Medication tracker
            DynamicIslandMedicationButton()
            // Just add this line after your DynamicIslandMedicationButton
            
            Spacer()
            
            // Study session quick start
            StudyButton()
            
            // Focus mode
            FocusButton()
        }
        .padding(.horizontal, 16)
    }
}

// Supporting views for the buttons
struct StudySessionView: View {
    @ObservedObject var medicationTracker: MedicationTrackerManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var subjectStudied: String = ""
    @State private var notes: String = ""
    @State private var selectedMedicationID: UUID?
    @State private var startTime = Date()
    
    // Get today's medication intakes
    private var todayIntakes: [MedicationIntake] {
        medicationTracker.medicationIntakes
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Study Details")) {
                    TextField("Subject/Topic", text: $subjectStudied)
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Related Medication")) {
                    if todayIntakes.isEmpty {
                        Text("No medications taken today")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(todayIntakes) { intake in
                            Button(action: {
                                selectedMedicationID = intake.id
                            }) {
                                HStack {
                                    Text("Ritalin \(String(format: "%.1f", intake.dosage))mg")
                                    Text("(\(formatTime(intake.timestamp)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if selectedMedicationID == intake.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: saveStudySession) {
                        Text("Start Session")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Start Study Session")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Notify that a sheet is showing to prevent window collapse
            NotificationCenter.default.post(name: NSNotification.Name("ButtonInteraction"), object: nil)
        }
    }
    
    private func saveStudySession() {
        guard !subjectStudied.isEmpty else { return }
        
        // Create the study session
        let sessionID = medicationTracker.startStudySession(
            relatedMedicationIntake: selectedMedicationID,
            subjectStudied: subjectStudied,
            notes: notes
        )
        
        // Show confirmation
        let notification = NSUserNotification()
        notification.title = "Study Session Started"
        notification.informativeText = "You're now studying \(subjectStudied)"
        NSUserNotificationCenter.default.deliver(notification)
        
        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// Focus mode settings view
struct FocusModeSettingsView: View {
    @Binding var duration: TimeInterval
    let onStart: () -> Void
    let onCancel: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedPreset = 1 // 0 = custom, 1 = 25min, 2 = 45min, 3 = 60min
    @State private var customMinutes: Double = 25
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Focus Duration")) {
                    Picker("Duration", selection: $selectedPreset) {
                        Text("Custom").tag(0)
                        Text("25 minutes (Pomodoro)").tag(1)
                        Text("45 minutes").tag(2)
                        Text("60 minutes").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    // Use the built-in onChange instead
                    .onChange(of: selectedPreset) { newValue in
                        switch newValue {
                        case 0: // Custom - don't change the value
                            break
                        case 1:
                            duration = 25 * 60
                            customMinutes = 25
                        case 2:
                            duration = 45 * 60
                            customMinutes = 45
                        case 3:
                            duration = 60 * 60
                            customMinutes = 60
                        default:
                            break
                        }
                    }
                    
                    if selectedPreset == 0 {
                        VStack {
                            Text("\(Int(customMinutes)) minutes")
                                .font(.headline)
                            
                            Slider(value: $customMinutes, in: 5...120, step: 5)
                                // Use the built-in onChange
                                .onChange(of: customMinutes) { newValue in
                                    duration = newValue * 60
                                }
                        }
                        .padding(.top, 8)
                    }
                }
                
                Section(header: Text("Focus Mode Settings")) {
                    Toggle("Block Notifications", isOn: .constant(true))
                    Toggle("Do Not Disturb", isOn: .constant(true))
                }
                
                Section {
                    Button(action: {
                        onStart()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Start Focus Mode")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Focus Mode")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        onCancel()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Notify that a sheet is showing to prevent window collapse
            NotificationCenter.default.post(name: NSNotification.Name("ButtonInteraction"), object: nil)
            
            // Initialize custom minutes from duration
            customMinutes = duration / 60
            
            // Set the preset based on the current duration
            switch Int(duration / 60) {
            case 25:
                selectedPreset = 1
            case 45:
                selectedPreset = 2
            case 60:
                selectedPreset = 3
            default:
                selectedPreset = 0
            }
        }
    }
}
