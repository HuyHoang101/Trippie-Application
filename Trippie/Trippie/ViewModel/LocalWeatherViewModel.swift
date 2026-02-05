//
//  LocalWeatherViewModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/4/26.
//

import Foundation
import Combine
import CoreLocation

class LocalWeatherViewModel: ObservableObject {
    // Output cho View lắng nghe
    @Published var weatherInfo: WeatherModel?
    @Published var weatherAdvice: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchCurrentWeather() {
        self.isLoading = true
        self.errorMessage = nil
        
        Task { @MainActor in
            do {
                // 1. Lấy vị trí
                let location = try await LocationManager.shared.requestLocation()
                
                // 2. Lấy thời tiết từ vị trí đó
                let weather = try await WeatherService.shared.getWeather(for: location)
                
                // 3. Cập nhật UI
                self.weatherInfo = weather
                self.weatherAdvice = self.generateAdvice(for: weather)
                self.isLoading = false
                
            } catch {
                print("❌ Error fetching weather: \(error.localizedDescription)")
                self.errorMessage = "Unable to load weather"
                self.isLoading = false
            }
        }
    }
    
    private func generateAdvice(for model: WeatherModel) -> String {
        let temp = model.temperature // Ví dụ: "21°C"
        let condition = model.condition // Ví dụ: "Rain", "Clear"
        
        // Dùng Emoji cho sinh động
        switch condition {
        case "Rain", "Drizzle", "Thunderstorm":
            return "It's raining 🌧️ and \(temp). Though not great for going out, it's the perfect time to plan a trip!"
            
        case "Clear":
            return "It's sunny ☀️ and \(temp). What a beautiful day to hang out or start an adventure!"
            
        case "Clouds":
            return "It's cloudy ☁️ and \(temp). A chill day, maybe grab a coffee and plan your next journey?"
            
        case "Snow":
            return "It's snowing ❄️ and \(temp). Stay warm inside and dream of your next summer trip!"
            
        case "Mist", "Fog", "Haze":
             return "It's foggy 🌫️ and \(temp). A bit mysterious out there, great mood for trip planning."
            
        default:
            // Trường hợp lạ hoặc mặc định
            return "It's \(condition) and \(temp) outside. Always a good time to explore something new!"
        }
    }
}
