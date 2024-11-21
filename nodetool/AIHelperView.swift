import SwiftUI

struct AIHelperView: View {
    @Binding var isPresented: Bool
    @State private var inputText: String = ""
    @State private var responseText: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedModel: String = "codellama"
    @State private var availableModels: [String] = []
    @State private var showFullScreen: Bool = false
    let ollamaURL: String
    
    var body: some View {
        if showFullScreen {
            fullScreenView
                .transition(.move(edge: .bottom))
        } else {
            compactView
                .transition(.scale)
        }
    }
    
    // Compact mini-view that appears within the dynamic island
    private var compactView: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18))
                Text("AI Helper")
                    .font(.headline)
                Spacer()
                Button(action: {
                    withAnimation {
                        showFullScreen = true
                    }
                }) {
                    Text("Expand")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Quick action buttons
            HStack(spacing: 12) {
                aiActionButton(title: "Fix Code", icon: "wrench.fill") {
                    inputText = "Fix this code: "
                    withAnimation {
                        showFullScreen = true
                    }
                }
                
                aiActionButton(title: "Optimize", icon: "bolt.fill") {
                    inputText = "Optimize this code: "
                    withAnimation {
                        showFullScreen = true
                    }
                }
                
                aiActionButton(title: "Explain", icon: "text.book.closed.fill") {
                    inputText = "Explain this code: "
                    withAnimation {
                        showFullScreen = true
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .padding(12)
        .frame(width: 350)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
        )
    }
    
    // Full screen view for detailed interaction
    private var fullScreenView: some View {
        VStack(spacing: 15) {
            // Header with close button
            HStack {
                Text("AI Code Assistant")
                    .font(.headline)
                Spacer()
                Button(action: {
                    withAnimation {
                        showFullScreen = false
                    }
                }) {
                    Image(systemName: "chevron.compact.up")
                        .font(.system(size: 20))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Model selection
            Picker("Model", selection: $selectedModel) {
                ForEach(availableModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onAppear {
                fetchAvailableModels()
            }
            
            // Text input
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter code or prompt:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextEditor(text: $inputText)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .frame(height: 150)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
            }
            
            // Action buttons
            HStack {
                Button(action: {
                    analyzeCode()
                }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Analyze")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(inputText.isEmpty || isLoading)
                
                Button(action: {
                    inputText = ""
                    responseText = ""
                }) {
                    Text("Clear")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(inputText.isEmpty && responseText.isEmpty)
            }
            
            // Loading or response area
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Thinking...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                .frame(height: 150)
            } else if !responseText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Response:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ScrollView {
                        Text(responseText)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(height: 200)
                    
                    // Action buttons for the response
                    HStack {
                        Button(action: {
                            // Copy response to clipboard
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(responseText, forType: .string)
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            // Accept suggestion - would implement actual logic here
                            isPresented = false
                        }) {
                            Label("Apply", systemImage: "checkmark")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.7))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 500)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Helper function to create action buttons
    private func aiActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption)
            }
            .frame(width: 70)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func analyzeCode() {
        isLoading = true
        guard let url = URL(string: "\(ollamaURL)/api/generate") else {
            responseText = "Invalid URL"
            isLoading = false
            return
        }
        
        let prompt = """
        Analyze this code and suggest improvements or fixes:
        \(inputText)
        """
        
        let body: [String: Any] = [
            "model": selectedModel,
            "prompt": prompt,
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = json["response"] as? String {
                    responseText = response
                } else {
                    responseText = "Error: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }.resume()
    }
    
    private func fetchAvailableModels() {
        guard let url = URL(string: "\(ollamaURL)/api/tags") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.availableModels = models.compactMap { $0["name"] as? String }
                    if !self.availableModels.isEmpty {
                        self.selectedModel = self.availableModels[0]
                    }
                }
            }
        }.resume()
    }
}

struct AIHelperView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)
            AIHelperView(isPresented: .constant(true), ollamaURL: "http://localhost:11434")
        }
    }
}
