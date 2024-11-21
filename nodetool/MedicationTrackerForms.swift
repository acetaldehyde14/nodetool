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
        NavigationView {
            Form {
                Section(header: Text("Medication Details")) {
                    HStack {
                        Text("Ritalin")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Dosage picker
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
                
                Section(header: Text("Conditions")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(conditionOptions, id: \.self) { condition in
                                Button(action: {
                                    toggleCondition(condition)
                                }) {
                                    Text(condition)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(conditions.contains(condition) ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(conditions.contains(condition) ? .white : .primary)
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Section(header: Text("Additional Factors")) {
                    HStack {
                        Text("Sleep Last Night")
                        Spacer()
                        Text("\(sleepHours, specifier: "%.1f") hours")
                    }
                    Slider(value: $sleepHours, in: 0...12, step: 0.5)
                    
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
                    
                    Toggle("Exercised Today", isOn: $exercisedBefore)
                    Toggle("Taken with Food", isOn: $foodIntakeBefore)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: saveMedication) {
                        Text("Log Medication")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Log Medication")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
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
    
    @State private var effectRating: Int = 7
    @State private var durationMinutes: Double = 240
    @State private var currentEffectStrength: Int = 7
    @State private var timeOffset: Double = 0
    @State private var effectNotes: String = ""
    @State private var showingAddPoint = false
    
    // Get the intake we're rating
    private var intake: MedicationIntake? {
        medicationTracker.medicationIntakes.first { $0.id == intakeID }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Overall Rating")) {
                    if let intake = intake {
                        HStack {
                            Text("Ritalin \(String(format: "%.1f", intake.dosage))mg")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("Taken at \(formatTime(intake.timestamp))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Effectiveness (1-10)")
                            .font(.subheadline)
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(effectRating) },
                                set: { effectRating = Int($0) }
                            ), in: 1...10, step: 1)
                            
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(effectRating) / 10")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 5)
                    }
                }
                
                Section(header: Text("Duration")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Total Duration")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(formatDuration(Int(durationMinutes)))")
                                .font(.subheadline)
                        }
                        
                        Slider(value: $durationMinutes, in: 30...480, step: 15)
                    }
                }
                
                Section(header: Text("Effectiveness Timeline")) {
                    if let pattern = intake?.effectPattern, !pattern.isEmpty {
                        ForEach(pattern.sorted(by: { $0.timeOffset < $1.timeOffset })) { point in
                            HStack {
                                Label("\(formatDuration(point.timeOffset))", systemImage: "clock")
                                
                                Spacer()
                                
                                Text("\(point.effectStrength)/10")
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(getColorForStrength(point.effectStrength).opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Button(action: { showingAddPoint = true }) {
                        Label("Add Effect Point", systemImage: "plus.circle")
                    }
                }
                
                Section {
                    Button(action: saveRating) {
                        Text("Save Rating")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Rate Medication")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingAddPoint) {
                addEffectPointView
            }
        }
    }
    
    var addEffectPointView: some View {
        NavigationView {
            Form {
                Section(header: Text("Time Since Taking Medication")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Time Offset")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(formatDuration(Int(timeOffset)))")
                                .font(.subheadline)
                        }
                        
                        Slider(value: $timeOffset, in: 0...480, step: 15)
                    }
                }
                
                Section(header: Text("Effectiveness at This Time")) {
                    VStack(alignment: .leading) {
                        Text("Effectiveness (1-10)")
                            .font(.subheadline)
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(currentEffectStrength) },
                                set: { currentEffectStrength = Int($0) }
                            ), in: 1...10, step: 1)
                            
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(currentEffectStrength) / 10")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 5)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $effectNotes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: addEffectPoint) {
                        Text("Add Point")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Add Effect Point")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        showingAddPoint = false
                    }
                }
            }
        }
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
    
    private func saveRating() {medicationTracker.completeMedicationIntake(
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
    NavigationView {
        Form {
            Section(header: Text("Study Details")) {
                TextField("Subject/Topic", text: $subjectStudied)
                
                DatePicker("Start Time", selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
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
                    isPresented = false
                }
            }
        }
    }
}

private func saveStudySession() {
    guard !subjectStudied.isEmpty else { return }
    
    medicationTracker.startStudySession(
        relatedMedicationIntake: selectedMedicationID,
        subjectStudied: subjectStudied,
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

struct EndStudySessionView: View {
@ObservedObject var medicationTracker: MedicationTrackerManager
@Binding var isPresented: Bool
let sessionID: UUID

@State private var productivityRating: Int = 7
@State private var focusRating: Int = 7
@State private var additionalNotes: String = ""

var body: some View {
    NavigationView {
        Form {
            Section(header: Text("Rate Your Session")) {
                VStack(alignment: .leading) {
                    Text("Productivity (1-10)")
                        .font(.subheadline)
                    
                    HStack {
                        Text("Poor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { Double(productivityRating) },
                            set: { productivityRating = Int($0) }
                        ), in: 1...10, step: 1)
                        
                        Text("Excellent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(productivityRating) / 10")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 5)
                }
                
                VStack(alignment: .leading) {
                    Text("Focus (1-10)")
                        .font(.subheadline)
                    
                    HStack {
                        Text("Distracted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { Double(focusRating) },
                            set: { focusRating = Int($0) }
                        ), in: 1...10, step: 1)
                        
                        Text("Focused")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(focusRating) / 10")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 5)
                }
            }
            
            Section(header: Text("Additional Notes")) {
                TextEditor(text: $additionalNotes)
                    .frame(minHeight: 100)
            }
            
            Section {
                Button(action: endSession) {
                    Text("End Session")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("End Study Session")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Cancel") {
                    isPresented = false
                }
            }
        }
    }
}

private func endSession() {
    medicationTracker.endStudySession(
        sessionID: sessionID,
        productivityRating: productivityRating,
        focusRating: focusRating,
        additionalNotes: additionalNotes
    )
    
    isPresented = false
}
}

struct AddStudyBreakView: View {
@ObservedObject var medicationTracker: MedicationTrackerManager
@Binding var isPresented: Bool
let sessionID: UUID

@State private var duration: Double = 5
@State private var breakType: String = "Rest"
@State private var notes: String = ""

private let breakTypes = ["Rest", "Walk", "Snack", "Social Media", "Exercise", "Meditation"]

var body: some View {
    NavigationView {
        Form {
            Section(header: Text("Break Details")) {
                Picker("Break Type", selection: $breakType) {
                    ForEach(breakTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(Int(duration)) minutes")
                }
                
                Slider(value: $duration, in: 1...30, step: 1)
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 50)
            }
            
            Section {
                Button(action: addBreak) {
                    Text("Start Break")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Take a Break")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Cancel") {
                    isPresented = false
                }
            }
        }
    }
}

private func addBreak() {
    medicationTracker.recordStudyBreak(
        sessionID: sessionID,
        durationMinutes: Int(duration),
        breakType: breakType
    )
    
    isPresented = false
}
}

struct RateBreakView: View {
@ObservedObject var medicationTracker: MedicationTrackerManager
@Binding var isPresented: Bool
let sessionID: UUID
let breakID: UUID

@State private var effectivenessRating: Int = 7

var body: some View {
    NavigationView {
        Form {
            Section(header: Text("Rate Break Effectiveness")) {
                VStack(alignment: .leading) {
                    Text("How refreshed do you feel? (1-10)")
                        .font(.subheadline)
                    
                    HStack {
                        Text("Not at all")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { Double(effectivenessRating) },
                            set: { effectivenessRating = Int($0) }
                        ), in: 1...10, step: 1)
                        
                        Text("Very")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(effectivenessRating) / 10")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 5)
                }
            }
            
            Section {
                Button(action: rateBreak) {
                    Text("Save Rating")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Rate Break")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Cancel") {
                    isPresented = false
                }
            }
        }
    }
}

private func rateBreak() {
    medicationTracker.rateBreakEffectiveness(
        sessionID: sessionID,
        breakID: breakID,
        effectivenessRating: effectivenessRating
    )
    
    isPresented = false
}
}
