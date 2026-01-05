import SwiftUI
import Foundation

struct MedicationTrackerView: View {
    @StateObject private var medicationTracker = MedicationTrackerManager()
    @State private var showingAddIntakeSheet = false
    @State private var showingAddSessionSheet = false
    @State private var selectedTab = 0
    @State private var isShowingRatingView = false
    @State private var selectedIntakeID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Medication Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    medicationTracker.generateOptimalPlan()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.trailing, 8)
                
                Menu {
                    Button("Log Medication", action: { showingAddIntakeSheet = true })
                    Button("Start Study Session", action: { showingAddSessionSheet = true })
                } label: {
                    Image(systemName: "plus")
                        .padding(5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 5)
            
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Today").tag(0)
                Text("Analytics").tag(1)
                Text("History").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            // Content based on selected tab
            Group {
                if selectedTab == 0 {
                    todayView
                } else if selectedTab == 1 {
                    analyticsView
                } else {
                    historyView
                }
            }
        }
        .sheet(isPresented: $showingAddIntakeSheet) {
            AddMedicationIntakeView(medicationTracker: medicationTracker, isPresented: $showingAddIntakeSheet)
        }
        .sheet(isPresented: $showingAddSessionSheet) {
            StartStudySessionView(medicationTracker: medicationTracker, isPresented: $showingAddSessionSheet)
        }
        .sheet(isPresented: $isShowingRatingView) {
            if let id = selectedIntakeID {
                RateMedicationView(medicationTracker: medicationTracker, intakeID: id, isPresented: $isShowingRatingView)
            }
        }
    }
    
    
    // Today view shows current plan and recent tracking
    var todayView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Streak & stats card
                HStack(spacing: 20) {
                    VStack {
                        Text("\(medicationTracker.getCurrentStreak())")
                            .font(.system(size: 36, weight: .bold))
                        Text("Day Streak")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    
                    VStack {
                        Text("\(medicationTracker.studySessions.filter { Calendar.current.isDateInToday($0.startTime) }.count)")
                            .font(.system(size: 36, weight: .bold))
                        Text("Sessions Today")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Today's medication
                SectionTitleView(title: "Today's Medication")
                
                if let todayIntake = medicationTracker.medicationIntakes.first(where: { Calendar.current.isDateInToday($0.timestamp) }) {
                    MedicationIntakeCard(intake: todayIntake) {
                        // Rate this medication
                        selectedIntakeID = todayIntake.id
                        isShowingRatingView = true
                    }
                    .padding(.horizontal)
                } else {
                    Button(action: {
                        showingAddIntakeSheet = true
                    }) {
                        HStack {
                            Image(systemName: "pills")
                            Text("Log Today's Medication")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
                
                // Optimal Plan
                SectionTitleView(title: "Recommended Plan")
                
                if let plan = medicationTracker.currentOptimalPlan {
                    OptimalPlanCard(plan: plan)
                        .padding(.horizontal)
                } else {
                    Text("Add more medication data to get personalized recommendations.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // Active or Recent Study Sessions
                SectionTitleView(title: "Today's Study Sessions")
                
                let todaySessions = medicationTracker.studySessions
                    .filter { Calendar.current.isDateInToday($0.startTime) }
                    .sorted { $0.startTime > $1.startTime }
                
                if !todaySessions.isEmpty {
                    ForEach(todaySessions) { session in
                        StudySessionCard(session: session)
                            .padding(.horizontal)
                    }
                } else {
                    Button(action: {
                        showingAddSessionSheet = true
                    }) {
                        HStack {
                            Image(systemName: "book")
                            Text("Start Study Session")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // Analytics view shows insights and patterns
    // Analytics view shows insights and patterns
    var analyticsView: some View {
        ScrollView {
            if medicationTracker.medicationIntakes.isEmpty {
                // Empty state when no data
                VStack(spacing: 20) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.top, 60)
                    
                    Text("No Data Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Start logging medication intakes to see effectiveness insights, trends, and analytics")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: {
                        showingAddIntakeSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Your First Medication")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Effectiveness Insights
                    SectionTitleView(title: "Effectiveness Insights")
                    
                    Text(medicationTracker.getEffectivenessInsights())
                        .font(.body)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    // Medication Effectiveness Chart
                    SectionTitleView(title: "Effectiveness Over Time")
                    
                    MedicationEffectivenessChart(medicationIntakes: medicationTracker.medicationIntakes)
                        .frame(height: 200)
                        .padding()
                    
                    // Study Session Performance
                    if !medicationTracker.studySessions.isEmpty {
                        SectionTitleView(title: "Study Performance")
                        
                        StudyPerformanceChart(studySessions: medicationTracker.studySessions)
                            .frame(height: 200)
                            .padding()
                    } else {
                        SectionTitleView(title: "Study Performance")
                        
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No study sessions yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showingAddSessionSheet = true
                            }) {
                                Text("Start First Session")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Pattern Analysis
                    SectionTitleView(title: "Pattern Analysis")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Best Time to Take Medication")
                            .font(.headline)
                        
                        let bestTimeData = getBestTimeData()
                        
                        if bestTimeData.isEmpty {
                            VStack(spacing: 8) {
                                Text("Track more medications with ratings to see optimal timing patterns")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            HStack(alignment: .bottom, spacing: 4) {
                                ForEach(0..<24) { hour in
                                    VStack {
                                        let value = bestTimeData[hour] ?? 0
                                        let height = min(100.0, Double(value) * 10)
                                        
                                        Rectangle()
                                            .fill(getColorForHour(hour: hour, value: value))
                                            .frame(height: max(height, 5))
                                        
                                        if hour % 3 == 0 {
                                            Text("\(hour)")
                                                .font(.system(size: 8))
                                                .rotationEffect(.degrees(-45))
                                        }
                                    }
                                }
                            }
                            .frame(height: 120)
                            .padding(.vertical)
                            
                            Text("Hours of Day (0-23)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }

    }
    
    // History view shows past medications and sessions
    var historyView: some View {
        List {
            Section(header: Text("Medication History")) {
                ForEach(medicationTracker.medicationIntakes.sorted(by: { $0.timestamp > $1.timestamp })) { intake in
                    MedicationHistoryRow(intake: intake)
                }
            }
            
            Section(header: Text("Study Sessions")) {
                ForEach(medicationTracker.studySessions.sorted(by: { $0.startTime > $1.startTime })) { session in
                    StudySessionHistoryRow(session: session)
                }
            }
        }
        .listStyle(DefaultListStyle()) // Changed from InsetGroupedListStyle to DefaultListStyle
    }
    
    // Helper methods for analytics
    func getBestTimeData() -> [Int: Double] {
        // Group intakes by hour and get average effectiveness
        var hourlyData: [Int: [Int]] = [:]
        
        for intake in medicationTracker.medicationIntakes {
            guard let effectRating = intake.effectRating else { continue }
            
            let hour = Calendar.current.component(.hour, from: intake.timestamp)
            if hourlyData[hour] == nil {
                hourlyData[hour] = []
            }
            hourlyData[hour]?.append(effectRating)
        }
        
        // Calculate averages
        var result: [Int: Double] = [:]
        
        for (hour, ratings) in hourlyData {
            result[hour] = Double(ratings.reduce(0, +)) / Double(ratings.count)
        }
        
        return result
    }
    
    func getColorForHour(hour: Int, value: Double) -> Color {
        if value <= 0 {
            return Color.gray.opacity(0.3)
        } else if value < 5 {
            return Color.blue.opacity(0.3 + (value * 0.1))
        } else if value < 7 {
            return Color.blue.opacity(0.7)
        } else {
            return Color.blue
        }
    }
}

// Supporting views
struct SectionTitleView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.horizontal)
            .padding(.top, 8)
    }
}

struct MedicationIntakeCard: View {
    let intake: MedicationIntake
    let onRateAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Ritalin \(String(format: "%.1f", intake.dosage))mg")
                        .font(.headline)
                    
                    Text("Taken at \(formatTime(intake.timestamp))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if intake.effectRating == nil {
                    Button(action: onRateAction) {
                        Text("Rate")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    HStack {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= (intake.effectRating ?? 0) / 2 ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                        }
                    }
                }
            }
            
            // Conditions
            if !intake.conditions.isEmpty {
                HStack {
                    ForEach(intake.conditions, id: \.self) { condition in
                        Text(condition)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 4)
            }
            
            // Notes if any
            if !intake.notes.isEmpty {
                Text(intake.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            // Effect timeline if available
            if let pattern = intake.effectPattern, !pattern.isEmpty {
                EffectTimelineView(pattern: pattern)
                    .frame(height: 40)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct EffectTimelineView: View {
    let pattern: [EffectDataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Timeline line
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 2)
                
                // Effect points
                ForEach(pattern) { point in
                    Circle()
                        .fill(getColorForStrength(point.effectStrength))
                        .frame(width: 8, height: 8)
                        .position(x: getXPosition(timeOffset: point.timeOffset, width: geometry.size.width),
                                y: geometry.size.height / 2)
                }
            }
        }
    }
    
    private func getXPosition(timeOffset: Int, width: CGFloat) -> CGFloat {
        // Assume timeline represents 8 hours (480 minutes)
        let maxTime = 480.0
        let normalizedPosition = min(1.0, Double(timeOffset) / maxTime)
        return width * CGFloat(normalizedPosition)
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

struct OptimalPlanCard: View {
    let plan: OptimalPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Optimal Plan")
                        .font(.headline)
                    
                    Text("Confidence: \(Int(plan.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Ritalin \(String(format: "%.1f", plan.recommendedDosage))mg")
                    .font(.headline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Time recommendation
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                
                Text("Best time: \(formatTime(plan.recommendedIntakeTime))")
                    .font(.subheadline)
            }
            
            // Recommended conditions
            if !plan.recommendedConditions.isEmpty {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)
                    
                    Text("Recommended conditions:")
                        .font(.subheadline)
                }
                
                HStack {
                    ForEach(plan.recommendedConditions, id: \.self) { condition in
                        Text(condition)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
            
            // Study plan segments
            VStack(alignment: .leading, spacing: 6) {
                Text("Suggested Study Plan")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(plan.studyPlan) { segment in
                    HStack {
                        Text("\(formatMinutes(segment.startOffset))")
                            .font(.system(size: 12))
                            .frame(width: 60, alignment: .leading)
                        
                        Rectangle()
                            .fill(getColorForActivity(segment.activityType))
                            .frame(width: CGFloat(segment.duration) / 3, height: 16)
                            .cornerRadius(3)
                        
                        Text(segment.activityType)
                            .font(.system(size: 12))
                        
                        Spacer()
                        
                        Text("\(segment.duration) min")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 4)
            
            // Reasoning
            Text(plan.reasoning)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
            let hours = minutes / 60
            let mins = minutes % 60
            if hours > 0 {
                return "\(hours)h \(mins)m"
            } else {
                return "\(mins)m"
            }
        }
        
        private func getColorForActivity(_ activity: String) -> Color {
            switch activity.lowercased() {
            case let s where s.contains("intense"): return .green
            case let s where s.contains("focus"): return .blue
            case let s where s.contains("break"): return .orange
            case let s where s.contains("rest"): return .orange
            case let s where s.contains("creative"): return .purple
            case let s where s.contains("wind"): return .gray
            default: return .blue.opacity(0.7)
            }
        }
    }

    struct StudySessionCard: View {
        let session: StudySession
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(session.subjectStudied)
                            .font(.headline)
                        
                        Text("Started at \(formatTime(session.startTime))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let endTime = session.endTime {
                        VStack(alignment: .trailing) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatDuration(from: session.startTime, to: endTime))
                                .font(.subheadline)
                        }
                    } else {
                        Text("In Progress")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(16)
                    }
                }
                
                // Productivity rating if available
                if let productivityRating = session.productivityRating {
                    HStack {
                        Text("Productivity:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= productivityRating / 2 ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                        }
                        
                        Spacer()
                        
                        if let focusRating = session.focusRating {
                            Text("Focus: \(focusRating)/10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Break information
                if !session.breaksTaken.isEmpty {
                    Text("\(session.breaksTaken.count) breaks taken")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        
        private func formatDuration(from startDate: Date, to endDate: Date) -> String {
            let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
            let hours = diffComponents.hour ?? 0
            let minutes = diffComponents.minute ?? 0
            
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }

    // Charts for analytics view
    struct MedicationEffectivenessChart: View {
        let medicationIntakes: [MedicationIntake]
        
        var body: some View {
            VStack {
                if let chartData = prepareChartData(), !chartData.isEmpty {
                    GeometryReader { geometry in
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(chartData, id: \.date) { item in
                                VStack {
                                    // Bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.color)
                                        .frame(width: max(geometry.size.width / CGFloat(chartData.count) - 10, 5),
                                               height: item.height * geometry.size.height * 0.8)
                                    
                                    // Date label
                                    Text(formatDate(item.date))
                                        .font(.system(size: 8))
                                        .rotationEffect(.degrees(-45))
                                        .frame(width: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal)
                    }
                } else {
                    Text("Not enough data to display chart")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        
        private func prepareChartData() -> [(date: Date, height: CGFloat, color: Color)]? {
            // Filter to intakes with ratings
            let ratedIntakes = medicationIntakes
                .filter { $0.effectRating != nil }
                .sorted { $0.timestamp < $1.timestamp }
            
            // Return if not enough data
            guard ratedIntakes.count >= 3 else { return nil }
            
            // Take the most recent intakes (up to 10)
            let recentIntakes = Array(ratedIntakes.suffix(10))
            
            // Prepare data
            return recentIntakes.map { intake in
                let rating = intake.effectRating ?? 0
                let normalizedHeight = CGFloat(rating) / 10.0
                let color = getColorForRating(rating)
                
                return (date: intake.timestamp, height: normalizedHeight, color: color)
            }
        }
        
        private func getColorForRating(_ rating: Int) -> Color {
            switch rating {
            case 1...3: return .red
            case 4...6: return .orange
            case 7...8: return .yellow
            case 9...10: return .green
            default: return .gray
            }
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "d/M"
            return formatter.string(from: date)
        }
    }

    struct StudyPerformanceChart: View {
        let studySessions: [StudySession]
        
        var body: some View {
            VStack {
                if let chartData = prepareChartData(), !chartData.isEmpty {
                    GeometryReader { geometry in
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(chartData, id: \.date) { item in
                                VStack {
                                    // Bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.color)
                                        .frame(width: max(geometry.size.width / CGFloat(chartData.count) - 10, 5),
                                               height: item.height * geometry.size.height * 0.8)
                                    
                                    // Date label
                                    Text(formatDate(item.date))
                                        .font(.system(size: 8))
                                        .rotationEffect(.degrees(-45))
                                        .frame(width: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal)
                    }
                } else {
                    Text("Not enough data to display chart")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        
        private func prepareChartData() -> [(date: Date, height: CGFloat, color: Color)]? {
            // Filter to sessions with ratings
            let ratedSessions = studySessions
                .filter { $0.productivityRating != nil }
                .sorted { $0.startTime < $1.startTime }
            
            // Return if not enough data
            guard ratedSessions.count >= 3 else { return nil }
            
            // Take the most recent sessions (up to 10)
            let recentSessions = Array(ratedSessions.suffix(10))
            
            // Prepare data
            return recentSessions.map { session in
                let rating = session.productivityRating ?? 0
                let normalizedHeight = CGFloat(rating) / 10.0
                let color = getColorForRating(rating)
                
                return (date: session.startTime, height: normalizedHeight, color: color)
            }
        }
        
        private func getColorForRating(_ rating: Int) -> Color {
            switch rating {
            case 1...3: return .red
            case 4...6: return .orange
            case 7...8: return .yellow
            case 9...10: return .green
            default: return .gray
            }
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "d/M"
            return formatter.string(from: date)
        }
    }

    // History list items
    struct MedicationHistoryRow: View {
        let intake: MedicationIntake
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Ritalin \(String(format: "%.1f", intake.dosage))mg")
                        .font(.headline)
                    
                    Spacer()
                    
                    if let rating = intake.effectRating {
                        Text("\(rating)/10")
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(getColorForRating(rating).opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Text(formatDate(intake.timestamp))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !intake.conditions.isEmpty {
                    Text(intake.conditions.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy h:mm a"
            return formatter.string(from: date)
        }
        
        private func getColorForRating(_ rating: Int) -> Color {
            switch rating {
            case 1...3: return .red
            case 4...6: return .orange
            case 7...8: return .yellow
            case 9...10: return .green
            default: return .gray
            }
        }
    }

    struct StudySessionHistoryRow: View {
        let session: StudySession
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.subjectStudied)
                        .font(.headline)
                    
                    Spacer()
                    
                    if let endTime = session.endTime {
                        Text(formatDuration(from: session.startTime, to: endTime))
                            .font(.subheadline)
                    } else {
                        Text("In Progress")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Text(formatDate(session.startTime))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let productivityRating = session.productivityRating {
                    Text("Productivity: \(productivityRating)/10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy h:mm a"
            return formatter.string(from: date)
        }
        
        private func formatDuration(from startDate: Date, to endDate: Date) -> String {
            let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
            let hours = diffComponents.hour ?? 0
            let minutes = diffComponents.minute ?? 0
            
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }
