import SwiftUI
import AppKit
import Vision
import Foundation
import OSLog
import ScreenCaptureKit

class ProductivityMonitor: NSObject {
    static let shared = ProductivityMonitor()
    
    @Published var isEnabled = false
    @Published var currentActivity: String = "Unknown"
    private var timer: Timer?
    
    // Logging
    private let logger = Logger(subsystem: "com.nodetool.app", category: "ProductivityMonitor")
    
    // Log to store activity history and errors
    private var activityLog: [ActivityLogEntry] = []
    private var errorLog: [ErrorLogEntry] = []
    
    // Ollama API configuration for MiniCPM-v model
    private let ollamaURL = "http://aiweb.tutelagegroup.com" // Your Ollama server URL
    private let ollamaModel = "minicpm-v" // The model name
    
    // List of distracting apps/websites (blacklist)
    private let distractingApps = [
        "Facebook", "Twitter", "Instagram", "TikTok", "YouTube",
        "Reddit", "Netflix", "Twitch", "Discord", "Games", "facebook.com",
        "twitter.com", "instagram.com", "tiktok.com", "youtube.com",
        "reddit.com", "netflix.com", "twitch.tv", "discord.com"
    ]
    
    // Time interval for screenshots (1 minute)
    private let screenshotInterval: TimeInterval = 15
    
    // Initialize
    private override init() {
        super.init()
        logger.info("ProductivityMonitor initialized")
        
        // Create necessary directories
        createDirectories()
        
        // Load logs
        loadLogs()
    }
    
    // MARK: - Directory Management
    
    // Get the project directory
    private func getProjectDirectory() -> URL {
        // Get the current working directory (project directory)
        let currentWorkingPath = FileManager.default.currentDirectoryPath
        return URL(fileURLWithPath: currentWorkingPath)
    }
    
    private func getScreenshotsDirectory() -> URL {
        // Get a permanent, absolute path to save screenshots
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenshotsDir = documentsDir.appendingPathComponent("nodetool/screenshots", isDirectory: true)
        
        // Ensure directory exists
        if !FileManager.default.fileExists(atPath: screenshotsDir.path) {
            do {
                try FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true, attributes: nil)
                print("Created screenshots directory at: \(screenshotsDir.path)")
                logToMainLog("Created screenshots directory at: \(screenshotsDir.path)")
            } catch {
                print("Failed to create screenshots directory: \(error.localizedDescription)")
                logToMainLog("Failed to create screenshots directory: \(error.localizedDescription)")
            }
        }
        
        return screenshotsDir
    }

    // And update the getLogsDirectory method similarly

    private func getLogsDirectory() -> URL {
        // Get a permanent, absolute path to save logs
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logsDir = documentsDir.appendingPathComponent("nodetool/logs", isDirectory: true)
        
        // Ensure directory exists
        if !FileManager.default.fileExists(atPath: logsDir.path) {
            do {
                try FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true, attributes: nil)
                print("Created logs directory at: \(logsDir.path)")
            } catch {
                print("Failed to create logs directory: \(error.localizedDescription)")
            }
        }
        
        return logsDir
    }
    
    // Create necessary directories
    private func createDirectories() {
        let fileManager = FileManager.default
        
        // Create screenshots directory
        let screenshotsDir = getScreenshotsDirectory()
        if !fileManager.fileExists(atPath: screenshotsDir.path) {
            do {
                try fileManager.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
                print("Created screenshots directory at: \(screenshotsDir.path)")
            } catch {
                print("Failed to create screenshots directory: \(error.localizedDescription)")
            }
        }
        
        // Create logs directory
        let logsDir = getLogsDirectory()
        if !fileManager.fileExists(atPath: logsDir.path) {
            do {
                try fileManager.createDirectory(at: logsDir, withIntermediateDirectories: true)
                print("Created logs directory at: \(logsDir.path)")
            } catch {
                print("Failed to create logs directory: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Monitoring Functions
    
    func toggleMonitoring() {
        isEnabled.toggle()
        
        if isEnabled {
            startMonitoring()
            logger.info("Productivity monitoring started")
            logToMainLog("Productivity monitoring started")
        } else {
            stopMonitoring()
            logger.info("Productivity monitoring stopped")
            logToMainLog("Productivity monitoring stopped")
        }
    }
    
    func startMonitoring() {
        stopMonitoring() // Make sure any existing timer is invalidated
        
        // Create a timer that fires every minute
        timer = Timer.scheduledTimer(withTimeInterval: screenshotInterval, repeats: true) { [weak self] _ in
            self?.captureAndAnalyzeScreen()
        }
        timer?.tolerance = 5 // Add some tolerance to be more battery-friendly
        
        // Fire immediately for testing
        self.captureAndAnalyzeScreen()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // Replace the captureAndAnalyzeScreen method in ProductivityMonitor with this version

    private func captureAndAnalyzeScreen() {
        guard isEnabled else { return }
        
        logger.info("Taking screenshot for analysis")
        logToMainLog("Taking screenshot for analysis")
        
        // Capture screenshot
        captureScreen { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let screenshot):
                // Create a timestamp for the filename
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let timestamp = dateFormatter.string(from: Date())
                let screenshotFilename = "screenshot_\(timestamp).jpg"
                
                // Get the screenshots directory - make sure it's using the absolute path
                let screenshotsDir = self.getScreenshotsDirectory()
                let screenshotURL = screenshotsDir.appendingPathComponent(screenshotFilename)
                
                // Debug: Print the full path where the screenshot will be saved
                print("Attempting to save screenshot to: \(screenshotURL.path)")
                
                // Check if the directory exists, if not create it
                if !FileManager.default.fileExists(atPath: screenshotsDir.path) {
                    do {
                        try FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true, attributes: nil)
                        print("Created screenshots directory at: \(screenshotsDir.path)")
                    } catch {
                        print("⚠️ Failed to create screenshots directory: \(error.localizedDescription)")
                        self.logToMainLog("⚠️ Failed to create screenshots directory: \(error.localizedDescription)")
                    }
                }
                
                // Convert to JPEG and save with explicit error handling
                if let tiffData = screenshot.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
                    
                    do {
                        // Explicitly write the data to the file
                        try jpegData.write(to: screenshotURL)
                        
                        // Verify the file was created
                        if FileManager.default.fileExists(atPath: screenshotURL.path) {
                            print("✅ Screenshot successfully saved to: \(screenshotURL.path)")
                            self.logToMainLog("✅ Screenshot saved to: \(screenshotURL.path)")
                            
                            // Now send the saved image to AI
                            let base64Image = jpegData.base64EncodedString()
                            self.logger.debug("Screenshot captured and saved")
                            
                            // Send to Ollama for analysis
                            self.analyzeScreenWithOllama(base64Image: base64Image, screenshotPath: screenshotURL.path) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let activity):
                                        self.currentActivity = activity
                                        self.logger.info("Current activity detected: \(activity)")
                                        self.logToMainLog("Detected activity: \(activity) from screenshot: \(screenshotFilename)")
                                        
                                        // Check if distraction blocker should activate
                                        if self.isDistraction(activity: activity) {
                                            self.logger.warning("Distraction detected: \(activity)")
                                            self.logToMainLog("⚠️ DISTRACTION DETECTED: \(activity)")
                                            self.showDistractionAlert(activity: activity)
                                            self.simulateCloseKeyCommand()
                                        }
                                        
                                    case .failure(let error):
                                        self.logger.error("Error analyzing screen: \(error.localizedDescription)")
                                        self.logToMainLog("❌ ERROR analyzing screenshot: \(error.localizedDescription)")
                                        if let urlError = error as? URLError {
                                            self.logError(message: error.localizedDescription, statusCode: urlError.errorCode, errorType: "Network Error", screenshotPath: screenshotURL.path)
                                        } else {
                                            self.logError(message: error.localizedDescription, statusCode: nil, errorType: "Analysis Error", screenshotPath: screenshotURL.path)
                                        }
                                    }
                                }
                            }
                        } else {
                            print("⚠️ Screenshot file was not created despite no errors: \(screenshotURL.path)")
                            self.logToMainLog("⚠️ Screenshot file was not created despite no errors")
                            self.logError(message: "Screenshot file was not created despite no errors", statusCode: nil, errorType: "File System Error")
                        }
                    } catch {
                        print("❌ Failed to save screenshot: \(error.localizedDescription)")
                        self.logToMainLog("❌ ERROR saving screenshot: \(error.localizedDescription)")
                        self.logError(message: error.localizedDescription, statusCode: nil, errorType: "Screenshot Save Error")
                        
                        // Fallback: Try to use the image directly without saving
                        let base64Image = jpegData.base64EncodedString()
                        self.analyzeScreenWithOllama(base64Image: base64Image, screenshotPath: "memory-only") { result in
                            // Handle result without requiring saved file
                            // (Implementation similar to above)
                        }
                    }
                } else {
                    let error = "Failed to convert screenshot to JPEG"
                    self.logger.error("\(error)")
                    self.logToMainLog("❌ ERROR: \(error)")
                    self.logError(message: error, statusCode: nil, errorType: "Image Conversion")
                }
                
            case .failure(let error):
                self.logger.error("Screen capture error: \(error.localizedDescription)")
                self.logToMainLog("❌ ERROR capturing screen: \(error.localizedDescription)")
                self.logError(message: error.localizedDescription, statusCode: nil, errorType: "Screenshot Error")
            }
        }
    }

    // Also update the getScreenshotsDirectory method for more robust path handling

    
    
    private func captureScreen(completion: @escaping (Result<NSImage, Error>) -> Void) {
        // Capture only the foreground window instead of the entire screen
        
        // Get the frontmost window's ID
        var windowList: CFArray?
        let windowListOptions: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        windowList = CGWindowListCopyWindowInfo(windowListOptions, kCGNullWindowID)
        
        if let windowList = windowList as? [[String: Any]], !windowList.isEmpty {
            // Filter to get frontmost application window
            let frontmostWindows = windowList.filter {
                // Check for windows that are on screen, visible, and not desktop elements
                let onScreen = ($0[kCGWindowIsOnscreen as String] as? Bool) ?? false
                let windowLayer = ($0[kCGWindowLayer as String] as? Int) ?? 0
                
                // Usually the active window is on layer 0
                return onScreen && windowLayer == 0
            }
            
            // Get the frontmost window ID
            if let frontWindow = frontmostWindows.first,
               let windowID = frontWindow[kCGWindowNumber as String] as? CGWindowID {
                
                // Log the window info for debugging
                let windowOwner = frontWindow[kCGWindowOwnerName as String] as? String ?? "Unknown"
                let windowName = frontWindow[kCGWindowName as String] as? String ?? "Unnamed"
                
                print("Capturing window: \(windowName) owned by \(windowOwner)")
                logToMainLog("Capturing window: \(windowName) owned by \(windowOwner)")
                
                // Create an image of this specific window
                if let windowImage = CGWindowListCreateImage(
                    CGRect.null,
                    .optionIncludingWindow,
                    windowID,
                    [.nominalResolution, .boundsIgnoreFraming]
                ) {
                    let nsImage = NSImage(cgImage: windowImage, size: NSSize(width: windowImage.width, height: windowImage.height))
                    completion(.success(nsImage))
                    return
                }
            }
        }
        
        // If the specific window capture fails, fall back to capturing the entire screen
        print("Falling back to full screen capture")
        logToMainLog("Falling back to full screen capture")
        
        if let screenRect = NSScreen.main?.frame,
           let cgImage = CGWindowListCreateImage(screenRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) {
            let nsImage = NSImage(cgImage: cgImage, size: screenRect.size)
            completion(.success(nsImage))
        } else {
            completion(.failure(NSError(domain: "ProductivityMonitor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to capture screen using any method"])))
        }
    }
    private func captureLegacyScreen(completion: @escaping (Result<NSImage, Error>) -> Void) {
        // Legacy screen capture for older macOS versions
        if let screenRect = NSScreen.main?.frame,
           let cgImage = CGWindowListCreateImage(screenRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) {
            let nsImage = NSImage(cgImage: cgImage, size: screenRect.size)
            completion(.success(nsImage))
        } else {
            completion(.failure(NSError(domain: "ProductivityMonitor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to capture screen using legacy method"])))
        }
    }
    
    private func analyzeScreenWithOllama(base64Image: String, screenshotPath: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Create URL for the Ollama API
        guard let url = URL(string: "\(self.ollamaURL)/api/generate") else {
            let error = NSError(domain: "ProductivityMonitor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama API URL"])
            logger.error("Invalid API URL: \(self.ollamaURL)/api/generate")
            logToMainLog("❌ ERROR: Invalid Ollama API URL")
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create prompt with the base64 image, asking specifically for website name only
        let prompt = """
        
        
        What website or application am I currently using in this image?
        Respond with ONLY the website name - no explanation, no introduction, no extra text.
        """
        
        // Create JSON payload for Ollama
        let payload: [String: Any] = [
            "model": ollamaModel,
            "images": [base64Image],
            "prompt": prompt,
            "stream": false,
            
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            logger.debug("Sending request to Ollama API")
            logToMainLog("Sending request to Ollama API for: \(screenshotPath)")
        } catch {
            logger.error("Failed to serialize request: \(error.localizedDescription)")
            logToMainLog("❌ ERROR serializing request: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        // Create timestamp for request
        let requestTime = Date()
        
        // Send request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Calculate response time
            let responseTime = Date().timeIntervalSince(requestTime)
            self.logger.debug("API response received in \(responseTime) seconds")
            self.logToMainLog("API response received in \(responseTime) seconds")
            
            // Check for network errors
            if let error = error {
                self.logger.error("Network error: \(error.localizedDescription)")
                self.logToMainLog("❌ ERROR: Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Log HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                self.logger.info("HTTP status code: \(httpResponse.statusCode)")
                self.logToMainLog("HTTP status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let error = NSError(
                        domain: "ProductivityMonitor",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"]
                    )
                    self.logError(
                        message: "HTTP error response",
                        statusCode: httpResponse.statusCode,
                        errorType: "HTTP Error",
                        screenshotPath: screenshotPath
                    )
                    completion(.failure(error))
                    return
                }
            }
            
            guard let data = data else {
                let error = NSError(
                    domain: "ProductivityMonitor",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "No data received"]
                )
                self.logToMainLog("❌ ERROR: No data received from API")
                self.logError(message: "No data received from API", statusCode: nil, errorType: "Empty Response", screenshotPath: screenshotPath)
                completion(.failure(error))
                return
            }
            
            do {
                // Log full response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    self.logger.debug("Received response: \(jsonString)")
                    self.logToMainLog("Received raw response: \(jsonString)")
                    
                    // Parse Ollama response
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let content = json["response"] as? String {
                        // Clean up the response
                        let cleanedResponse = content
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "\"", with: "")
                        
                        self.logToMainLog("AI detected: \"\(cleanedResponse)\" (Screenshot: \(screenshotPath))")
                        
                        // Log both the activity and the full response
                        self.logActivityWithResponse(
                            activity: cleanedResponse,
                            aiResponse: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            timestamp: Date(),
                            screenshotPath: screenshotPath
                        )
                        
                        self.logger.info("Analysis result: \"\(cleanedResponse)\"")
                        completion(.success(cleanedResponse))
                    } else {
                        let error = NSError(
                            domain: "ProductivityMonitor",
                            code: 3,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama API response format"]
                        )
                        self.logToMainLog("❌ ERROR: Invalid response format from API")
                        self.logError(message: "Invalid response format", statusCode: nil, errorType: "Parsing Error", screenshotPath: screenshotPath)
                        completion(.failure(error))
                    }
                }
            } catch {
                self.logger.error("JSON parsing error: \(error.localizedDescription)")
                self.logToMainLog("❌ ERROR: JSON parsing failed: \(error.localizedDescription)")
                self.logError(message: "JSON parsing failed: \(error.localizedDescription)", statusCode: nil, errorType: "JSON Error", screenshotPath: screenshotPath)
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func isDistraction(activity: String) -> Bool {
        // Check if the detected activity is in the blacklist
        // Convert to lowercase for case-insensitive comparison
        let lowercaseActivity = activity.lowercased()
        
        return distractingApps.contains { distractingApp in
            lowercaseActivity.contains(distractingApp.lowercased())
        }
    }
    
    private func showDistractionAlert(activity: String) {
        // Create and show distraction blocker window
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Distraction Detected!"
            alert.informativeText = "You were trying to access: \(activity)\n\nThis activity has been blocked by your distraction blocker settings."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Return to Work")
            alert.runModal()
        }
    }
    
    private func simulateCloseKeyCommand() {
        logger.info("Simulating CMD+W to close distraction")
        logToMainLog("Simulating CMD+W to close distraction")
        
        // Simulate Cmd+W keystroke
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Create key down event for Cmd+W
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true) // Command key
        cmdDown?.flags = .maskCommand
        cmdDown?.post(tap: .cghidEventTap)
        
        let wDown = CGEvent(keyboardEventSource: source, virtualKey: 0x0D, keyDown: true) // W key
        wDown?.flags = .maskCommand
        wDown?.post(tap: .cghidEventTap)
        
        // Create key up event
        let wUp = CGEvent(keyboardEventSource: source, virtualKey: 0x0D, keyDown: false)
        wUp?.flags = .maskCommand
        wUp?.post(tap: .cghidEventTap)
        
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        cmdUp?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Logging Functions
    
    // Log to main log file
    private func logToMainLog(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logLine = "[\(timestamp)] \(message)\n"
        
        let mainLogURL = getLogsDirectory().appendingPathComponent("productivity_monitor.log")
        
        // Create log file if it doesn't exist
        if !FileManager.default.fileExists(atPath: mainLogURL.path) {
            do {
                try "=== PRODUCTIVITY MONITOR LOG ===\n".write(to: mainLogURL, atomically: true, encoding: .utf8)
                print("Created main log file at: \(mainLogURL.path)")
            } catch {
                print("Failed to create main log file: \(error.localizedDescription)")
            }
        }
        
        // Append to log file
        do {
            let fileHandle = try FileHandle(forWritingTo: mainLogURL)
            fileHandle.seekToEndOfFile()
            if let data = logLine.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } catch {
            print("Failed to write to main log: \(error.localizedDescription)")
        }
    }
    
    // Log activity with AI response
    private func logActivityWithResponse(activity: String, aiResponse: String, timestamp: Date, screenshotPath: String = "") {
        let entry = ActivityLogEntry(
            timestamp: timestamp,
            activity: activity,
            isDistraction: isDistraction(activity: activity),
            aiResponse: aiResponse,
            screenshotPath: screenshotPath
        )
        
        // Add to in-memory log
        activityLog.append(entry)
        
        // Keep only the last 1000 entries
        if activityLog.count > 1000 {
            activityLog.removeFirst(activityLog.count - 1000)
        }
        
        // Save to UserDefaults
        saveLogs()
        
        // Save to files
        saveLogsToFiles()
    }
    
    private func logError(message: String, statusCode: Int?, errorType: String, screenshotPath: String = "") {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            errorMessage: message,
            statusCode: statusCode,
            errorType: errorType,
            screenshotPath: screenshotPath
        )
        
        errorLog.append(entry)
        
        // Keep only the last 1000 entries to prevent excessive memory usage
        if errorLog.count > 1000 {
            errorLog.removeFirst(errorLog.count - 1000)
        }
        
        saveLogs()
        
        // Also save to files
        saveLogsToFiles()
        
        // Log to main log file
        logToMainLog("ERROR: [\(errorType)] \(message)" + (statusCode != nil ? " (Status: \(statusCode!))" : ""))
    }
    
    // Save logs to files in the logs directory
    func saveLogsToFiles() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let logsDir = getLogsDirectory()
        
        // Save activity log to JSON file
        do {
            let activityData = try encoder.encode(self.activityLog)
            let activityLogURL = logsDir.appendingPathComponent("activity_log.json")
            try activityData.write(to: activityLogURL)
            print("Activity log saved to: \(activityLogURL.path)")
        } catch {
            print("Failed to save activity log: \(error.localizedDescription)")
            logToMainLog("❌ ERROR saving activity log: \(error.localizedDescription)")
        }
        
        // Save error log to JSON file
        do {
            let errorData = try encoder.encode(self.errorLog)
            let errorLogURL = logsDir.appendingPathComponent("error_log.json")
            try errorData.write(to: errorLogURL)
            print("Error log saved to: \(errorLogURL.path)")
        } catch {
            print("Failed to save error log: \(error.localizedDescription)")
            logToMainLog("❌ ERROR saving error log: \(error.localizedDescription)")
        }
        
        // Save CSV log for easy reading
        saveToCSVLog(logsDir)
    }
    
    // Create/update CSV log file in the specified directory
    private func saveToCSVLog(_ directory: URL) {
        // Create CSV content
        var csvContent = "Timestamp,Activity,IsDistraction,AIResponse,Screenshot\n"
        
        // Sort activity log by timestamp
        let sortedLog = activityLog.sorted { $0.timestamp < $1.timestamp }
        
        // Add each entry
        for entry in sortedLog {
            let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
            // Escape quotes in activity text and response
            let escapedActivity = entry.activity.replacingOccurrences(of: "\"", with: "\"\"")
            let escapedResponse = entry.aiResponse?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            
            csvContent += "\(timestamp),\"\(escapedActivity)\",\(entry.isDistraction),\"\(escapedResponse)\",\"\(entry.screenshotPath)\"\n"
        }
        
        // Write to file
        let csvURL = directory.appendingPathComponent("productivity_log.csv")
        do {
            try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
            print("CSV log saved to: \(csvURL.path)")
        } catch {
            print("Failed to save CSV log: \(error.localizedDescription)")
            logToMainLog("❌ ERROR saving CSV log: \(error.localizedDescription)")
        }
    }
    
    private func saveLogs() {
        // Save activity log
        if let activityData = try? JSONEncoder().encode(self.activityLog) {
            UserDefaults.standard.set(activityData, forKey: "ProductivityMonitor.activityLog")
        }
        
        // Save error log
        if let errorData = try? JSONEncoder().encode(self.errorLog) {
            UserDefaults.standard.set(errorData, forKey: "ProductivityMonitor.errorLog")
        }
    }
    
    private func loadLogs() {
        // Load activity log
        if let activityData = UserDefaults.standard.data(forKey: "ProductivityMonitor.activityLog"),
           let loadedLog = try? JSONDecoder().decode([ActivityLogEntry].self, from: activityData) {
            self.activityLog = loadedLog
            logger.info("Loaded \(self.activityLog.count) activity log entries")
            logToMainLog("Loaded \(self.activityLog.count) activity log entries")
        }
        
        // Load error log
        if let errorData = UserDefaults.standard.data(forKey: "ProductivityMonitor.errorLog"),
           let loadedLog = try? JSONDecoder().decode([ErrorLogEntry].self, from: errorData) {
            self.errorLog = loadedLog
            logger.info("Loaded \(self.errorLog.count) error log entries")
            logToMainLog("Loaded \(self.errorLog.count) error log entries")
        }
    }
    
    // MARK: - Public Methods for Accessing Logs
    
    func getActivityLog() -> [ActivityLogEntry] {
        return activityLog
    }
    
    func getErrorLog() -> [ErrorLogEntry] {
        return errorLog
    }
    
    func clearLogs() {
        activityLog.removeAll()
        errorLog.removeAll()
        saveLogs()
        saveLogsToFiles()
        logToMainLog("All logs cleared")
        logger.info("All logs cleared")
    }
    
    // Get the path to the CSV log file
    func getCSVLogPath() -> String {
        return getLogsDirectory().appendingPathComponent("productivity_log.csv").path
    }
    
    // Get the path to the main log file
    func getMainLogPath() -> String {
        return getLogsDirectory().appendingPathComponent("productivity_monitor.log").path
    }
    
    // Open the log directory in Finder
    func openLogInFinder() {
        let logsDir = getLogsDirectory()
        NSWorkspace.shared.open(logsDir)
    }
    
    // Get the contents of the main log as a string
    func getMainLogContents() -> String? {
        let mainLogURL = getLogsDirectory().appendingPathComponent("productivity_monitor.log")
        do {
            return try String(contentsOf: mainLogURL, encoding: .utf8)
        } catch {
            print("Failed to read main log: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Get the contents of the CSV log as a string
    func getCSVLogContents() -> String? {
        // Always save logs to files first
        saveLogsToFiles()
        
        let csvURL = getLogsDirectory().appendingPathComponent("productivity_log.csv")
        do {
            return try String(contentsOf: csvURL, encoding: .utf8)
        } catch {
            print("Failed to read CSV log: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Log Entry Structures
    
    struct ActivityLogEntry: Codable, Identifiable {
        var id = UUID()
        let timestamp: Date
        let activity: String
        let isDistraction: Bool
        let aiResponse: String?
        let screenshotPath: String
    }
    
    struct ErrorLogEntry: Codable, Identifiable {
        var id = UUID()
        let timestamp: Date
        let errorMessage: String
        let statusCode: Int?
        let errorType: String
        let screenshotPath: String
    }
}

// MARK: - ScreenCaptureKit Extension for macOS 14+
@available(macOS 14.0, *)
extension ProductivityMonitor: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        
        // Get the image from the sample buffer
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]],
              let attachment = attachments.first else {
            return
        }
        
        // Check if the buffer is ready to be processed
        let notSync = (attachment[kCMSampleAttachmentKey_NotSync] as? Bool) ?? false
        if notSync {
            return
        }
        
        // Get the pixel buffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Convert the image buffer to a CGImage
                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                let context = CIContext()
                guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                    return
                }
                
                // Store the CGImage - this will be accessed by the captureScreen method
                DispatchQueue.main.async {
                    // This would be better with a callback mechanism, but this is simplistic approach
                    // In a real app, you would want to use a completion handler instead
                    objc_setAssociatedObject(stream, "capturedImage", cgImage, .OBJC_ASSOCIATION_RETAIN)
                }
            }
        }

        // MARK: - LogViewerButton for viewing logs
        struct LogViewerButton: View {
            @State private var showingLogViewer = false
            
            var body: some View {
                Button(action: {
                    // Save logs before showing the viewer
                    ProductivityMonitor.shared.saveLogsToFiles()
                    
                    showingLogViewer = true
                    NotificationCenter.default.post(name: NSNotification.Name("ButtonInteraction"), object: nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Logs")
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.3))
                    )
                    .foregroundColor(.white)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showingLogViewer) {
                    LogViewerSheet(isPresented: $showingLogViewer)
                }
            }
        }

        struct LogViewerSheet: View {
            @Binding var isPresented: Bool
            @State private var logContents: String = "Loading logs..."
            @State private var logPath: String = ""
            @State private var viewMode: LogViewMode = .mainLog
            
            enum LogViewMode {
                case mainLog
                case csvLog
            }
            
            var body: some View {
                VStack(spacing: 16) {
                    HStack {
                        Text("Productivity Monitor Logs")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Picker("Log Type", selection: $viewMode) {
                            Text("Main Log").tag(LogViewMode.mainLog)
                            Text("Activity Log").tag(LogViewMode.csvLog)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                        .onChange(of: viewMode) { _ in
                            loadSelectedLog()
                        }
                        
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    
                    Text("Log file location: \(logPath)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView {
                        Text(logContents)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        Button("Open in Finder") {
                            ProductivityMonitor.shared.openLogInFinder()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("Refresh Logs") {
                            loadSelectedLog()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("Clear Logs") {
                            ProductivityMonitor.shared.clearLogs()
                            loadSelectedLog()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.bottom)
                }
                .frame(width: 800, height: 600)
                .onAppear {
                    loadSelectedLog()
                }
            }
            
            private func loadSelectedLog() {
                switch viewMode {
                case .mainLog:
                    logPath = ProductivityMonitor.shared.getMainLogPath()
                    if let contents = ProductivityMonitor.shared.getMainLogContents() {
                        logContents = contents
                    } else {
                        logContents = "No main log found or unable to read log file."
                    }
                case .csvLog:
                    logPath = ProductivityMonitor.shared.getCSVLogPath()
                    if let contents = ProductivityMonitor.shared.getCSVLogContents() {
                        logContents = contents
                    } else {
                        logContents = "No CSV log found or unable to read log file."
                    }
                }
            }
        }

        // MARK: - ProductivityButton for toggling monitoring
        struct ProductivityButton: View {
            @State private var isEnabled = false
            @State private var currentActivity = "Unknown"
            
            // Timer to update the current activity display
            private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
            
            var body: some View {
                Button(action: {
                    isEnabled.toggle()
                    
                    // Toggle the monitoring
                    ProductivityMonitor.shared.toggleMonitoring()
                    
                    // Explicitly save logs when toggling
                    ProductivityMonitor.shared.saveLogsToFiles()
                    
                    // Notify to prevent the dynamic island from collapsing immediately
                    NotificationCenter.default.post(name: NSNotification.Name("ButtonInteraction"), object: nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isEnabled ? "eye.fill" : "eye.slash")
                            .foregroundColor(isEnabled ? .green : .white)
                        
                        Text(isEnabled ? "Focus: On" : "Focus: Off")
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isEnabled ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                    )
                    .foregroundColor(.white)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .onReceive(timer) { _ in
                    if isEnabled {
                        // Update the current activity text
                        currentActivity = ProductivityMonitor.shared.currentActivity
                        
                        // Save logs periodically when enabled
                        ProductivityMonitor.shared.saveLogsToFiles()
                    }
                }
                .onAppear {
                    // Check if monitoring is already active when view appears
                    isEnabled = ProductivityMonitor.shared.isEnabled
                    
                    // Save logs when the button appears
                    ProductivityMonitor.shared.saveLogsToFiles()
                }
            }
        }
