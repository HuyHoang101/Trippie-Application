//
//  LocationManager.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/4/26.
//

import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // Lấy thời tiết ko cần chính xác từng mét
    }
    
    // Hàm gọi 1 dòng là lấy được location
    func requestLocation() async throws -> CLLocation {
        // Kiểm tra quyền
        let status = manager.authorizationStatus
        
        if status == .denied || status == .restricted {
            throw NSError(domain: "Location", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission Denied"])
        }
        
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation() // Bắt đầu lấy vị trí 1 lần
        }
    }
    
    // MARK: - Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // Trả về kết quả cho hàm await phía trên
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Nếu user vừa cấp quyền xong thì tự động request lại
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
