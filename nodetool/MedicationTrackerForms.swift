import SwiftUI

struct AddMedicationIntakeView: View {
    @ObservedObject var medicationTracker: MedicationTrackerManager
    @Binding var isPresented: Bool
    
    @State private var dosage: Double = 10.0
    @State private var conditions: [String] = []
    @State private var notes: String = ""
    @State private var sleepHours: Double = 7.0
    @State private var stressLevel: Int = 5
    @State private var hydrationLevel: Int = 5
    @State private var exercisedBefore: Bool = false
    @State private var foodIntakeBefore: Bool = true
    
    // Predefined condition options
    private let conditionOptions = [
        "After food", "With coffee", "After sleep",
        "With water", "While stressed", "After exercise",
        "Empty stomach", "Morning", "Afternoon", "Evening"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Log Medication")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Medication Details
                    GroupBox(label: Text("Medication Details").font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Ritalin")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Stepper(value: $dosage, in: 5...20, step: 2.5) {
                                    HStack {
                                        Text("Dosage:")
                                        Text("\(dosage, specifier: "%.1f") mg")
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            
                            DatePicker("Time Taken", selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
                        }
                        .padding(8)
                    }
                    
                    // Conditions
                    GroupBox(label: Text("Conditions").font(.headline)) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(conditionOptions, id: \.self) { condition in
                                    Button(action: {
                                        toggleCondition(condition)
                                    }) {
                                        Text(condition)
                                            .font(.system(size: 12))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(conditions.contains(condition) ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(conditions.contains(condition) ? .white : .primary)
                                            .cornerRadius(15)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(8)
                    }
                    
                    // Additional Factors
                    GroupBox(label: Text("Additional Factors").font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Sleep Last Night")
                                    Spacer()
                                    Text("\(sleepHours, specifier: "%.1f") hours")
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: $sleepHours, in: 0...12, step: 0.5)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Current Stress Level")
                                Spacer()
                                ForEach(1...5, id: \.self) { level in
                                    Image(systemName: level <= stressLevel ? "star.fill" : "star")
                                        .foregroundColor(level <= stressLevel ? .orange : .gray)
                                        .onTapGesture {
                                            stressLevel = level
                                        }
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Hydration Level")
                                Spacer()
                                ForEach(1...5, id: \.self) { level in
                                    Image(systemName: level <= hydrationLevel ? "drop.fill" : "drop")
                                        .foregroundColor(level <= hydrationLevel ? .blue : .gray)
                                        .onTapGesture {
                                            hydrationLevel = level
                                        }
                                }
                            }
                            
                            Divider()
                            
                            Toggle("Exercised Today", isOn: $exercisedBefore)
                            
                            Divider()
                            
                            Toggle("Taken with Food", isOn: $foodIntakeBefore)
                        }
                        .padding(8)
                    }
                    
                    // Notes
                    GroupBox(label: Text("Notes").font(.headline)) {
                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .font(.body)
                            .padding(4)
                    }
                    
                    // Save Button
                    HStack {
                        Spacer()
                        Button(action: saveMedication) {
                            Text("Log Medication")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 150)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .keyboardShortcut(.defaultAction)
                        Spacer()
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 700)
    }
    
    private func toggleCondition(_ condition: String) {
        if conditions.contains(condition) {
            conditions.removeAll { $0 == condition }
        } else {
            conditions.append(condition)
        }
    }
    
    private func saveMedication() {
        medicationTracker.addMedicationIntake(
            dosage: dosage,
            conditions: conditions,
            notes: notes,
            sleepHours: sleepHours,
            stressLevel: stressLevel,
            hydrationLevel: hydrationLevel,
            exercisedBefore: exercisedBefore,
            foodIntakeBefore: foodIntakeBefore
        )
        
        isPresented = false
    }
}

struct RateMedicationView: View {
    @ObservedObject var medicationTracker: MedicationTrackerManager
    let intakeID: UUID
    @Binding var isPresented: Bool
    
    @State private var effectRating: Int = 5
    @State private var durationMinutes: Double = 180
    @State private var effectNotes: String = ""
    @State private var showingAddPoint: Bool = false
    
    var intake: MedicationIntake? {
        medicationTracker.medicationIntakes.first { $0.id == intakeID }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Rate Medication Effect")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let intake = intake {
                        // Medication Info
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Ritalin \(String(format: "%.1f", intake.dosage))mg")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("Taken at \(formatTime(intake.timestamp))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !intake.conditions.isEmpty {
                                    HStack {
                                        ForEach(intake.conditions, id: \.self) { condition in
                                            Text(condition)
                                                .font(.caption)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            .padding(8)
                        }
                        
                        // Effect Rating
                        GroupBox(label: Text("Overall Effectiveness").font(.headline)) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Poor")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    ForEach(1...10, id: \.self) { rating in
                                        Image(systemName: rating <= effectRating ? "star.fill" : "star")
                                            .foregroundColor(rating <= effectRating ? .yellow : .gray)
                                            .font(.system(size: 16))
                                            .onTapGesture {
                                                effectRating = rating
                                            }
                                    }
                                    
                                    Spacer()
                                    
                                    Text("Excellent")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(effectRating) / 10")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .padding(8)
                        }
                        
                        // Duration
                        GroupBox(label: Text("Duration of Effect").font(.headline)) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Duration:")
                                    Spacer()
                                    Text(formatDuration(Int(durationMinutes)))
                                        .fontWeight(.medium)
                                }
                                
                                Slider(value: $durationMinutes, in: 30...480, step: 30)
                                
                                HStack {
                                    Text("30 min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("8 hours")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(8)
                        }
                        
                        // Effect Pattern
                        if let pattern = intake.effectPattern, !pattern.isEmpty {
                            GroupBox(label: Text("Effect Timeline").font(.headline)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(pattern.sorted(by: { $0.timeOffset < $1.timeOffset }), id: \.timeOffset) { point in
                                        HStack {
                                            Text("\(point.timeOffset) min")
                                                .frame(width: 70, alignment: .leading)
                                            
                                            HStack(spacing: 2) {
                                                ForEach(0..<10) { i in
                                                    Rectangle()
                                                        .fill(i < point.effectStrength ? getColorForStrength(point.effectStrength) : Color.gray.opacity(0.2))
                                                        .frame(width: 15, height: 8)
                                                }
                                            }
                                            
                                            Text("\(point.effectStrength)/10")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .font(.caption)
                                    }
                                    
                                    Button(action: {
                                        showingAddPoint = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Effect Point")
                                        }
                                        .font(.caption)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.top, 4)
                                }
                                .padding(8)
                            }
                        }
                        
                        // Notes
                        GroupBox(label: Text("Additional Notes").font(.headline)) {
                            TextEditor(text: $effectNotes)
                                .frame(height: 80)
                                .font(.body)
                                .padding(4)
                        }
                        
                        // Save Button
                        HStack {
                            Spacer()
                            Button(action: saveRating) {
                                Text("Save Rating")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 150)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut(.defaultAction)
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 700)
        .sheet(isPresented: $showingAddPoint) {
            AddEffectPointView(
                medicationTracker: medicationTracker,
                intakeID: intakeID,
                showingAddPoint: $showingAddPoint
            )
        }
    }
    
    private func saveRating() {
        medicationTracker.completeMedicationIntake(
            intakeID: intakeID,
            effectRating: effectRating,
            durationMinutes: Int(durationMinutes)
        )
        
        isPresented = false
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    private func getColorForStrength(_ strength: Int) -> Color {
        switch strength {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...8: return .yellow
        case 9...10: return .green
        default: return .gray
        }
    }
}

struct AddEffectPointView: View {
    @ObservedObject var medicationTracker: MedicationTrackerManager
    let intakeID: UUID
    @Binding var showingAddPoint: Bool
    
    @State private var timeOffset: Double = 30
    @State private var currentEffectStrength: Int = 5
    @State private var effectNotes: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Effect Point")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Cancel") {
                    showingAddPoint = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Time After Taking").font(.headline)) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Time:")
                            Spacer()
                            Text("\(Int(timeOffset)) minutes")
                                .fontWeight(.medium)
                        }
                        
                        Slider(value: $timeOffset, in: 0...480, step: 15)
                        
                        HStack {
                            Text("Now")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("8 hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                }
                
                GroupBox(label: Text("Effect Strength").font(.headline)) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { Double(currentEffectStrength) },
                                    set: { currentEffectStrength = Int($0) }
                                ), in: 1...10, step: 1)
                            
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(currentEffectStrength) / 10")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding(8)
                }
                
                GroupBox(label: Text("Notes").font(.headline)) {
                    TextEditor(text: $effectNotes)
                        .frame(height: 60)
                        .font(.body)
                        .padding(4)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: addEffectPoint) {
                        Text("Add Point")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 120)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    Spacer()
                }
            }
            .padding()
        }
        .frame(width: 400, height: 450)
    }
    
    private func addEffectPoint() {
        medicationTracker.updateEffectPattern(
            for: intakeID,
            timeOffset: Int(timeOffset),
            effectStrength: currentEffectStrength,
            notes: effectNotes
        )
        
        showingAddPoint = false
    }
}

struct StartStudySessionView: View {
    @ObservedObject var medicationTracker: MedicationTrackerManager
    @Binding var isPresented: Bool
    
    @State private var subjectStudied: String = ""
    @State private var notes: String = ""
    @State private var selectedMedicationID: UUID?
    
    // Get today's medication intakes
    private var todayIntakes: [MedicationIntake] {
        medicationTracker.medicationIntakes
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Start Study Session")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Study Details").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Subject/Topic", text: $subjectStudied)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        DatePicker("Start Time", selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
                    }
                    .padding(8)
                }
                
                GroupBox(label: Text("Related Medication").font(.headline)) {
                    if todayIntakes.isEmpty {
                        Text("No medications taken today")
                            .foregroundColor(.secondary)
                            .padding(8)
                    } else {
                        VStack(spacing: 8) {
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
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(8)
                                    .background(selectedMedicationID == intake.id ? Color.blue.opacity(0.1) : Color.clear)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(8)
                    }
                }
                
                GroupBox(label: Text("Notes").font(.headline)) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .font(.body)
                        .padding(4)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: saveStudySession) {
                        Text("Start Session")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 150)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    Spacer()
                }
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }
    
    private func saveStudySession() {
        medicationTracker.startStudySession(
            subjectStudied: subjectStudied,
            medicationID: selectedMedicationID,
            notes: notes
        )
        
        isPresented = false
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct CompleteStudySessionView: View {
    @ObservedObject var medicationTracker: MedicationTrackerManager
    let sessionID: UUID
    @Binding var isPresented: Bool
    
    @State private var focusRating: Int = 5
    @State private var productivityRating: Int = 5
    @State private var comprehensionRating: Int = 5
    @State private var notes: String = ""
    
    var session: StudySession? {
        medicationTracker.studySessions.first { $0.id == sessionID }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Complete Study Session")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let session = session {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(session.subjectStudied)
                                    .font(.headline)
                                
                                Text("Started: \(formatTime(session.startTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Duration: \(formatDuration(Int(Date().timeIntervalSince(session.startTime) / 60)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                        }
                        
                        GroupBox(label: Text("Focus Level").font(.headline)) {
                            VStack(spacing: 8) {
                                HStack {
                                    ForEach(1...10, id: \.self) { rating in
                                        Image(systemName: rating <= focusRating ? "star.fill" : "star")
                                            .foregroundColor(rating <= focusRating ? .yellow : .gray)
                                            .onTapGesture {
                                                focusRating = rating
                                            }
                                    }
                                }
                                Text("\(focusRating) / 10")
                                    .font(.caption)
                            }
                            .padding(8)
                        }
                        
                        GroupBox(label: Text("Productivity").font(.headline)) {
                            VStack(spacing: 8) {
                                HStack {
                                    ForEach(1...10, id: \.self) { rating in
                                        Image(systemName: rating <= productivityRating ? "star.fill" : "star")
                                            .foregroundColor(rating <= productivityRating ? .yellow : .gray)
                                            .onTapGesture {
                                                productivityRating = rating
                                            }
                                    }
                                }
                                Text("\(productivityRating) / 10")
                                    .font(.caption)
                            }
                            .padding(8)
                        }
                        
                        GroupBox(label: Text("Comprehension").font(.headline)) {
                            VStack(spacing: 8) {
                                HStack {
                                    ForEach(1...10, id: \.self) { rating in
                                        Image(systemName: rating <= comprehensionRating ? "star.fill" : "star")
                                            .foregroundColor(rating <= comprehensionRating ? .yellow : .gray)
                                            .onTapGesture {
                                                comprehensionRating = rating
                                            }
                                    }
                                }
                                Text("\(comprehensionRating) / 10")
                                    .font(.caption)
                            }
                            .padding(8)
                        }
                        
                        GroupBox(label: Text("Notes").font(.headline)) {
                            TextEditor(text: $notes)
                                .frame(height: 80)
                                .font(.body)
                                .padding(4)
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: saveCompletion) {
                                Text("Complete Session")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 150)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut(.defaultAction)
                            Spacer()
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 550)
    }
    
    private func saveCompletion() {
        medicationTracker.completeStudySession(
            sessionID: sessionID,
            focusRating: focusRating,
            productivityRating: productivityRating,
            comprehensionRating: comprehensionRating,
            notes: notes
        )
        
        isPresented = false
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}
