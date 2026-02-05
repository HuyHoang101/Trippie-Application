//
//  WeatherService.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/4/26.
//

import Foundation
import CoreLocation
import UIKit // Để dùng UIImage

// 1. Model để hứng dữ liệu JSON từ API (Mapping)
struct OpenWeatherResponse: Codable {
    let main: MainWeather
    let weather: [WeatherDetail]
    let name: String // Tên thành phố
}

struct MainWeather: Codable {
    let temp: Double
}

struct WeatherDetail: Codable {
    let main: String // VD: Clouds, Rain
    let description: String
    let icon: String // Mã icon của OpenWeather (VD: "10d")
}

// 2. Model sạch để trả về cho UI (Giữ nguyên như cũ để ViewModel không phải sửa)
struct WeatherModel {
    let temperature: String
    let iconImage: UIImage? // Đổi sang UIImage vì ta sẽ load ảnh từ web
    let condition: String
    let cityName: String
}

class WeatherService {
    static let shared = WeatherService()
    private let apiKey = "c435e13ebc1604f798f8966f965f85df"
    
    func getWeather(for location: CLLocation) async throws -> WeatherModel {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // URL API miễn phí v2.5
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "WeatherService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 1. Gọi API
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "WeatherService", code: 500, userInfo: [NSLocalizedDescriptionKey: "API Error"])
        }
        
        // 2. Parse JSON
        let decodedData = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
        
        // 3. Xử lý dữ liệu
        let tempString = String(format: "%.0f°C", decodedData.main.temp)
        let condition = decodedData.weather.first?.main ?? "Unknown"
        let cityName = decodedData.name
        
        
        var weatherIcon: UIImage? = nil
        if let iconCode = decodedData.weather.first?.icon,
           let iconUrl = URL(string: "https://openweathermap.org/img/wn/\(iconCode)@2x.png") {
            // Tải ảnh icon nhanh gọn (trong thực tế nên cache lại)
            do {
                let (iconData, _) = try await URLSession.shared.data(from: iconUrl)
                weatherIcon = UIImage(data: iconData)
            } catch {
                print("Lỗi tải icon: \(error)")
            }
        }
        
        return WeatherModel(
            temperature: tempString,
            iconImage: weatherIcon,
            condition: condition,
            cityName: cityName
        )
    }
}
