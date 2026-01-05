# Code Snippets to Add to MedicationTrackerView.swift

## 1. Replace the analyticsView (around line 185)

Replace the entire `analyticsView` computed property with this improved version:

```swift
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
```

## 2. Improve the Today View Empty States

Find the "Upcoming medications" section in `todayView` and update it:

```swift
// In todayView, find the "Upcoming medications" section
// Replace it with:

// Upcoming medications
SectionTitleView(title: "Upcoming Medications")

if medicationTracker.upcomingMedications.isEmpty {
    VStack(spacing: 12) {
        Image(systemName: "calendar.badge.clock")
            .font(.system(size: 40))
            .foregroundColor(.gray.opacity(0.5))
        
        Text("No upcoming medications scheduled")
            .font(.subheadline)
            .foregroundColor(.secondary)
        
        Button(action: {
            // Open settings or schedule view
        }) {
            Text("Set Up Schedule")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 30)
    .background(Color.secondary.opacity(0.05))
    .cornerRadius(10)
    .padding(.horizontal)
} else {
    ForEach(medicationTracker.upcomingMedications) { medication in
        // ... existing medication card code
    }
}
```

## 3. Improve History View Empty States

Find the `historyView` and update it:

```swift
// History view shows past medications and sessions
var historyView: some View {
    List {
        Section(header: Text("Medication History")) {
            if medicationTracker.medicationIntakes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "pill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No medication history")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingAddIntakeSheet = true
                    }) {
                        Text("Log Medication")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(medicationTracker.medicationIntakes.sorted(by: { $0.timestamp > $1.timestamp })) { intake in
                    MedicationHistoryRow(intake: intake)
                }
            }
        }
        
        Section(header: Text("Study Sessions")) {
            if medicationTracker.studySessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No study sessions recorded")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingAddSessionSheet = true
                    }) {
                        Text("Start Session")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(medicationTracker.studySessions.sorted(by: { $0.startTime > $1.startTime })) { session in
                    StudySessionHistoryRow(session: session)
                }
            }
        }
    }
    .listStyle(DefaultListStyle())
}
```

## 4. Fix Chart Empty States

Find the `MedicationEffectivenessChart` struct and update it:

```swift
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
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Not enough data to display chart")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Log medications and rate their effectiveness to see trends over time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 30)
            }
        }
    }
    
    // ... rest of the implementation
}
```

## Quick Apply Instructions

1. Open `MedicationTrackerView.swift` in Xcode
2. Use Find (⌘F) to locate each section mentioned above
3. Replace the code with the improved versions
4. Save (⌘S)
5. Build and run (⌘R)

## Testing

After applying these changes:
1. Launch the app
2. Click on the medication tracker button
3. Verify the Analytics tab shows the empty state with the prompt
4. Log a medication using the button in the empty state
5. Verify the History tab shows the logged medication
6. Check that Today tab displays your streak and stats

All empty states should now show helpful messages and action buttons instead of blank space!
