import Foundation
import SwiftUI

// Main data models
struct MedicationIntake: Codable, Identifiable {
    var id = UUID()
    var timestamp: Date
    var dosage: Double // in mg
    var conditions: [String] // e.g., "after food", "with coffee", "after sleep"
    var effectRating: Int? // Scale 1-10, nil if not yet rated
    var durationMinutes: Int? // How long effects lasted in minutes, nil if not yet recorded
    var notes: String
    var effectPattern: [EffectDataPoint]? // Timeline of effect changes
    
    // Metadata for machine learning
    var sleepHours: Double?
    var stressLevel: Int? // 1-10
    var hydrationLevel: Int? // 1-10
    var exercisedBefore: Bool?
    var foodIntakeBefore: Bool?
}

struct EffectDataPoint: Codable, Identifiable {
    var id = UUID()
    var timeOffset: Int // minutes from intake
    var effectStrength: Int // 1-10
    var notes: String
}

struct StudySession: Codable, Identifiable {
    var id = UUID()
    var relatedMedicationIntake: UUID? // Link to medication intake if applicable
    var startTime: Date
    var endTime: Date?
    var productivityRating: Int? // 1-10
    var focusRating: Int? // 1-10
    var breaksTaken: [StudyBreak]
    var notes: String
    var subjectStudied: String
}

struct StudyBreak: Codable, Identifiable {
    var id = UUID()
    var startTime: Date
    var durationMinutes: Int
    var breakType: String // "walk", "snack", "rest", etc.
    var effectivenessRating: Int? // 1-10
}

struct OptimalPlan: Codable {
    var recommendedIntakeTime: Date
    var recommendedDosage: Double
    var recommendedConditions: [String]
    var expectedDuration: Int
    var studyPlan: [StudyPlanSegment]
    var confidence: Double // 0-1, algorithm's confidence in this plan
    var reasoning: String // Explanation of why this plan was chosen
}

struct StudyPlanSegment: Codable, Identifiable {
    var id = UUID()
    var startOffset: Int // minutes from medication intake
    var duration: Int // in minutes
    var activityType: String // "intense focus", "creative work", "break", etc.
    var notes: String
}

// Main controller class for medication tracking and optimization
class MedicationTrackerManager: ObservableObject {
    @Published var medicationIntakes: [MedicationIntake] = []
    @Published var studySessions: [StudySession] = []
    @Published var currentOptimalPlan: OptimalPlan?
    
    private let userDefaults = UserDefaults.standard
    private let medicationIntakesKey = "medicationIntakes"
    private let studySessionsKey = "studySessions"
    
    init() {
        loadData()
    }
    
    // MARK: - Data Management
    
    func loadData() {
        if let medicationData = userDefaults.data(forKey: medicationIntakesKey),
           let studyData = userDefaults.data(forKey: studySessionsKey) {
            
            let decoder = JSONDecoder()
            
            do {
                medicationIntakes = try decoder.decode([MedicationIntake].self, from: medicationData)
                studySessions = try decoder.decode([StudySession].self, from: studyData)
            } catch {
                print("Error decoding medication data: \(error)")
                medicationIntakes = []
                studySessions = []
            }
        }
    }
    
    func saveData() {
        let encoder = JSONEncoder()
        
        do {
            let medicationData = try encoder.encode(medicationIntakes)
            let studyData = try encoder.encode(studySessions)
            
            userDefaults.set(medicationData, forKey: medicationIntakesKey)
            userDefaults.set(studyData, forKey: studySessionsKey)
        } catch {
            print("Error encoding medication data: \(error)")
        }
    }
    
    // MARK: - Medication Tracking
    
    func addMedicationIntake(dosage: Double, conditions: [String], notes: String,
                            sleepHours: Double? = nil, stressLevel: Int? = nil,
                            hydrationLevel: Int? = nil, exercisedBefore: Bool? = nil,
                            foodIntakeBefore: Bool? = nil) {
        
        let newIntake = MedicationIntake(
            timestamp: Date(),
            dosage: dosage,
            conditions: conditions,
            effectRating: nil,
            durationMinutes: nil,
            notes: notes,
            effectPattern: [],
            sleepHours: sleepHours,
            stressLevel: stressLevel,
            hydrationLevel: hydrationLevel,
            exercisedBefore: exercisedBefore,
            foodIntakeBefore: foodIntakeBefore
        )
        
        medicationIntakes.append(newIntake)
        saveData()
    }
    
    func updateEffectPattern(for intakeID: UUID, timeOffset: Int, effectStrength: Int, notes: String) {
        guard let index = medicationIntakes.firstIndex(where: { $0.id == intakeID }) else { return }
        
        let dataPoint = EffectDataPoint(
            timeOffset: timeOffset,
            effectStrength: effectStrength,
            notes: notes
        )
        
        if medicationIntakes[index].effectPattern == nil {
            medicationIntakes[index].effectPattern = []
        }
        
        medicationIntakes[index].effectPattern?.append(dataPoint)
        medicationIntakes[index].effectPattern?.sort(by: { $0.timeOffset < $1.timeOffset })
        
        saveData()
    }
    
    func completeMedicationIntake(intakeID: UUID, effectRating: Int, durationMinutes: Int) {
        guard let index = medicationIntakes.firstIndex(where: { $0.id == intakeID }) else { return }
        
        medicationIntakes[index].effectRating = effectRating
        medicationIntakes[index].durationMinutes = durationMinutes
        
        saveData()
        generateOptimalPlan() // Generate new plan based on updated data
    }
    
    // MARK: - Study Session Tracking
    
    func startStudySession(relatedMedicationIntake: UUID? = nil, subjectStudied: String, notes: String) -> UUID {
        let newSession = StudySession(
            relatedMedicationIntake: relatedMedicationIntake,
            startTime: Date(),
            endTime: nil,
            productivityRating: nil,
            focusRating: nil,
            breaksTaken: [],
            notes: notes,
            subjectStudied: subjectStudied
        )
        
        studySessions.append(newSession)
        saveData()
        return newSession.id
    }
    
    func endStudySession(sessionID: UUID, productivityRating: Int, focusRating: Int, additionalNotes: String = "") {
        guard let index = studySessions.firstIndex(where: { $0.id == sessionID }) else { return }
        
        studySessions[index].endTime = Date()
        studySessions[index].productivityRating = productivityRating
        studySessions[index].focusRating = focusRating
        
        if !additionalNotes.isEmpty {
            studySessions[index].notes += "\nFollow-up: \(additionalNotes)"
        }
        
        saveData()
    }
    
    func recordStudyBreak(sessionID: UUID, durationMinutes: Int, breakType: String) {
        guard let index = studySessions.firstIndex(where: { $0.id == sessionID }) else { return }
        
        let newBreak = StudyBreak(
            startTime: Date(),
            durationMinutes: durationMinutes,
            breakType: breakType,
            effectivenessRating: nil
        )
        
        studySessions[index].breaksTaken.append(newBreak)
        saveData()
    }
    
    func rateBreakEffectiveness(sessionID: UUID, breakID: UUID, effectivenessRating: Int) {
        guard let sessionIndex = studySessions.firstIndex(where: { $0.id == sessionID }),
              let breakIndex = studySessions[sessionIndex].breaksTaken.firstIndex(where: { $0.id == breakID }) else { return }
        
        studySessions[sessionIndex].breaksTaken[breakIndex].effectivenessRating = effectivenessRating
        saveData()
    }
    
    // MARK: - Machine Learning & Optimization
    
    func generateOptimalPlan() {
        // This would normally use a more sophisticated machine learning algorithm
        // For now, we'll implement a simple heuristic-based approach
        
        guard !medicationIntakes.isEmpty else { return }
        
        // 1. Find the intake with the highest effect rating
        let bestIntakes = medicationIntakes
            .filter { $0.effectRating != nil }
            .sorted { ($0.effectRating ?? 0) > ($1.effectRating ?? 0) }
            .prefix(3)
            .map { intake -> (MedicationIntake, [StudySession]?) in
                let relatedSessions = studySessions.filter { $0.relatedMedicationIntake == intake.id }
                return (intake, relatedSessions.isEmpty ? nil : relatedSessions)
            }
        
        guard !bestIntakes.isEmpty else { return }
        
        // 2. Extract patterns from the best intakes
        var recommendedTime = Date()
        var recommendedDosage = bestIntakes.first?.0.dosage ?? 10.0
        var recommendedConditions: [String] = []
        var expectedDuration = bestIntakes.first?.0.durationMinutes ?? 240
        
        // Find common conditions among effective intakes
        let allConditions = bestIntakes.flatMap { $0.0.conditions }
        let conditionCounts = Dictionary(allConditions.map { ($0, 1) }, uniquingKeysWith: +)
        recommendedConditions = conditionCounts
            .filter { $0.value > 1 } // Only include conditions that appear multiple times
            .map { $0.key }
        
        // Analyze time patterns
        if bestIntakes.count > 1 {
            // Get average dosage from best intakes
            recommendedDosage = bestIntakes.reduce(0.0) { $0 + ($1.0.dosage) } / Double(bestIntakes.count)
            
            // Get average duration from best intakes
            expectedDuration = Int(bestIntakes.reduce(0) { $0 + ($1.0.durationMinutes ?? 0) } / bestIntakes.count)
        }
        
        // 3. Analyze study sessions for optimal study plan
        var studyPlanSegments: [StudyPlanSegment] = []
        var reasoning = "Based on your \(bestIntakes.count) most effective medication sessions"
        
        // Create a study plan based on effectiveness patterns
        if let bestIntake = bestIntakes.first,
           let effectPattern = bestIntake.0.effectPattern,
           !effectPattern.isEmpty {
            
            // Sort by time offset
            let sortedPattern = effectPattern.sorted { $0.timeOffset < $1.timeOffset }
            
            // Identify peaks and create segments accordingly
            var lastOffset = 0
            
            for (i, dataPoint) in sortedPattern.enumerated() {
                let segmentDuration = dataPoint.timeOffset - lastOffset
                
                // Skip very short segments
                if segmentDuration < 10 { continue }
                
                var activityType = "moderate focus"
                
                // Determine activity type based on effect strength
                if dataPoint.effectStrength >= 8 {
                    activityType = "intense focus"
                } else if dataPoint.effectStrength <= 4 {
                    activityType = "break"
                }
                
                studyPlanSegments.append(StudyPlanSegment(
                    startOffset: lastOffset,
                    duration: segmentDuration,
                    activityType: activityType,
                    notes: "Effect strength: \(dataPoint.effectStrength)/10"
                ))
                
                lastOffset = dataPoint.timeOffset
            }
            
            // Add final segment if needed
            if let duration = bestIntake.0.durationMinutes, lastOffset < duration {
                studyPlanSegments.append(StudyPlanSegment(
                    startOffset: lastOffset,
                    duration: duration - lastOffset,
                    activityType: "winding down",
                    notes: "Effect gradually diminishing"
                ))
            }
            
            reasoning += " and your detailed effectiveness feedback."
        } else {
            // Create a generic study plan if we don't have detailed data
            // Typical pomodoro-style plan
            let studyDuration = 25
            let breakDuration = 5
            let longBreakDuration = 15
            
            var currentOffset = 0
            
            // Create 4 pomodoro cycles
            for i in 0..<4 {
                studyPlanSegments.append(StudyPlanSegment(
                    startOffset: currentOffset,
                    duration: studyDuration,
                    activityType: "focused study",
                    notes: "Pomodoro #\(i+1)"
                ))
                
                currentOffset += studyDuration
                
                // Add a longer break after every 2 pomodoros
                let isLongBreak = (i + 1) % 2 == 0
                let breakLength = isLongBreak ? longBreakDuration : breakDuration
                
                studyPlanSegments.append(StudyPlanSegment(
                    startOffset: currentOffset,
                    duration: breakLength,
                    activityType: isLongBreak ? "long break" : "short break",
                    notes: "Rest and recharge"
                ))
                
                currentOffset += breakLength
            }
            
            reasoning += ". As you provide more detailed feedback, recommendations will become more personalized."
        }
        
        // 4. Create the optimal plan
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // Set the time to 9 AM if we don't have enough data for better recommendation
        components.hour = 9
        components.minute = 0
        
        recommendedTime = calendar.date(from: components) ?? Date()
        
        let optimalPlan = OptimalPlan(
            recommendedIntakeTime: recommendedTime,
            recommendedDosage: recommendedDosage,
            recommendedConditions: recommendedConditions,
            expectedDuration: expectedDuration,
            studyPlan: studyPlanSegments,
            confidence: Double(min(bestIntakes.count, 10)) / 10.0, // Confidence based on data quality
            reasoning: reasoning
        )
        
        self.currentOptimalPlan = optimalPlan
    }
    
    // MARK: - Analysis & Reporting
    
    func getEffectivenessInsights() -> String {
        guard medicationIntakes.count >= 3 else {
            return "Add more medication data for personalized insights."
        }
        
        // Analyze conditions that led to most effective results
        let ratedIntakes = medicationIntakes.filter { $0.effectRating != nil }
        let averageEffectiveness = ratedIntakes.reduce(0) { $0 + ($1.effectRating ?? 0) } / ratedIntakes.count
        
        // Look for correlations between conditions and effectiveness
        var conditionEffectiveness: [String: [Int]] = [:]
        
        for intake in ratedIntakes {
            guard let rating = intake.effectRating else { continue }
            
            for condition in intake.conditions {
                if conditionEffectiveness[condition] == nil {
                    conditionEffectiveness[condition] = []
                }
                conditionEffectiveness[condition]?.append(rating)
            }
        }
        
        var insights = "Overall average effectiveness: \(averageEffectiveness)/10\n\n"
        insights += "Conditions and their effects:\n"
        
        for (condition, ratings) in conditionEffectiveness {
            let average = ratings.reduce(0, +) / ratings.count
            insights += "• \(condition): \(average)/10 (from \(ratings.count) instances)\n"
        }
        
        // Add timing insights
        insights += "\nTiming insights:\n"
        
        // Group by hour of day
        var hourlyEffectiveness: [Int: [Int]] = [:]
        
        for intake in ratedIntakes {
            guard let rating = intake.effectRating else { continue }
            
            let hour = Calendar.current.component(.hour, from: intake.timestamp)
            if hourlyEffectiveness[hour] == nil {
                hourlyEffectiveness[hour] = []
            }
            hourlyEffectiveness[hour]?.append(rating)
        }
        
        // Find the best time of day
        let bestHour = hourlyEffectiveness
            .map { (hour: $0.key, avgRating: $0.value.reduce(0, +) / $0.value.count) }
            .sorted { $0.avgRating > $1.avgRating }
            .first
        
        if let bestHour = bestHour {
            insights += "• Most effective time: Around \(bestHour.hour):00 (average rating: \(bestHour.avgRating)/10)\n"
        }
        
        return insights
    }
    
    func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        
        // Get all study days
        let studyDays = studySessions.map { calendar.startOfDay(for: $0.startTime) }
        let uniqueDays = Set(studyDays)
        
        // Sort days and check streak
        let sortedDays = uniqueDays.sorted()
        
        var currentStreak = 1
        guard !sortedDays.isEmpty else { return 0 }
        
        // Start from the most recent day
        var lastDay = sortedDays.last!
        
        // Go backward through the days
        for i in (0..<sortedDays.count-1).reversed() {
            let currentDay = sortedDays[i]
            let daysBetween = calendar.dateComponents([.day], from: currentDay, to: lastDay).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day
                currentStreak += 1
                lastDay = currentDay
            } else {
                // Streak broken
                break
            }
        }
        
        return currentStreak
    }
}
