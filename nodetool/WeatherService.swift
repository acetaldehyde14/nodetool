import Foundation
import CoreLocation

// Weather data structure
struct WeatherData: Codable {
    let main: Main
    let weather: [Weather]
    let name: String
    
    struct Main: Codable {
        let temp: Double
        let humidity: Int
    }
    
    struct Weather: Codable {
        let description: String
        let icon: String
    }
}

class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentTemperature = "N/A"
    @Published var weatherCondition = "N/A"
    @Published var location = "Unknown"
    @Published var humidity = 0
    @Published var weatherIcon = "cloud"
    
    private let locationManager = CLLocationManager()
    private let apiKey = "YOUR_API_KEY" // Replace with your OpenWeatherMap API key
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        
        if let location = locations.last {
            fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }
    
    func fetchWeather(latitude: Double, longitude: Double) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&units=metric&appid=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching weather: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                DispatchQueue.main.async {
                    self.updateUI(with: weatherData)
                }
            } catch {
                print("Error decoding weather data: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func updateUI(with weatherData: WeatherData) {
        self.currentTemperature = "\(Int(round(weatherData.main.temp)))°"
        
        if let condition = weatherData.weather.first?.description {
            self.weatherCondition = condition.capitalized
        }
        
        self.location = weatherData.name
        self.humidity = weatherData.main.humidity
        
        if let iconString = weatherData.weather.first?.icon {
            self.weatherIcon = mapIconToSystemName(iconString)
        }
    }
    
    private func mapIconToSystemName(_ iconCode: String) -> String {
        // Map OpenWeatherMap icon codes to SF Symbols
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "cloud.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
    
    // For demo/development when you don't have an API key
    func loadDemoData() {
        self.currentTemperature = "18°"
        self.weatherCondition = "Light Rain"
        self.location = "San Francisco"
        self.humidity = 65
        self.weatherIcon = "cloud.rain"
    }
}
