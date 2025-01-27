import SwiftUI
import CoreLocation
import Foundation

struct ContentView: View {
    @State private var cityName: String = ""
    @State private var temperature: String = "..°C"
    @State private var weatherDescription: String = ""
    @State private var weatherIcon: String = "cloud.sun.fill"
    
    var body: some View {
        VStack {
            Text(cityName)
                .font(.largeTitle)
                .padding()
            
            Image(systemName: weatherIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding()
           
            Text(weatherDescription)
                .bold()
                .font(.title2)
                .padding()

            
            Text(temperature)
                .font(.system(size: 50))
                .bold()
            
            Spacer()
        }
        .onAppear {
            WeatherService.fetchWeather(for: "Istanbul") { result in
                switch result {
                case .success(let weatherResponse):
                    cityName = weatherResponse.name
                    temperature = String(format: "%.1f°C", weatherResponse.main.temp)
                    weatherDescription = weatherResponse.weather.first?.description ?? "No description"
                    weatherIcon = weatherResponse.weather.first?.icon ?? "cloud.sun.fill"
                case .failure(let error):
                    print("Hata: \(error.localizedDescription)")
                }
            }
        }
        .padding()
        .background(Image("clouds"))
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var manager = CLLocationManager()
    @Published var location = CLLocation()
    
    override init(){
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first!
    }
}

struct WeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
}

struct Main: Codable {
    let temp: Double
}

struct Weather: Codable {
    let description: String
    let icon: String
}

class WeatherService {
    static func fetchWeather(for city: String, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        let apiKey = "XXX"
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&units=metric&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "WeatherServiceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(NSError(domain: "WeatherServiceError", code: 0, userInfo: [NSLocalizedDescriptionKey: error?.localizedDescription ?? "Unknown error"])))
                return
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                completion(.success(weatherResponse))
            } catch {
                print("Hata: \(error)")
                completion(.failure(NSError(domain: "WeatherServiceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Decoding error"])))
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}
