import Foundation
import CoreLocation
import UIKit

class LocationUpdateService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationUpdateService()
    
    private var locationManager: CLLocationManager?
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 10.0 // 10 seconds
    private let baseURL = "https://seasonksa.com/api"
    
    private var lastLocation: CLLocation?
    private var lastUpdateTime: Date?
    
    override init() {
        super.init()
        setupLocationManager()
        logGroupIdsStatus()
    }
    
    private func logGroupIdsStatus() {
        print("📊 Group IDs Status on Service Creation:")
        let jsonKey = "flutter.tracked_group_ids"
        let commaKey = "tracked_group_ids"
        let duplicateKey = "flutter.flutter.tracked_group_ids"
        
        var jsonValue: String?
        var commaValue: String?
        var duplicateValue: String?
        
        if let prefs = UserDefaults(suiteName: "group.com.season.app") {
            jsonValue = prefs.string(forKey: jsonKey)
            commaValue = prefs.string(forKey: commaKey)
            duplicateValue = prefs.string(forKey: duplicateKey)
        }
        
        if jsonValue == nil {
            jsonValue = UserDefaults.standard.string(forKey: jsonKey)
        }
        if commaValue == nil {
            commaValue = UserDefaults.standard.string(forKey: commaKey)
        }
        if duplicateValue == nil {
            duplicateValue = UserDefaults.standard.string(forKey: duplicateKey)
        }
        
        print("   flutter.tracked_group_ids: '\(jsonValue ?? "nil")'")
        print("   tracked_group_ids: '\(commaValue ?? "nil")'")
        print("   flutter.flutter.tracked_group_ids: '\(duplicateValue ?? "nil")'")
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 10 // Update when moved 10 meters
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
    }
    
    func startLocationUpdates() {
        guard let locationManager = locationManager else { return }
        
        // Request authorization - always request "always" permission
        let status = locationManager.authorizationStatus
        
        // If not determined, request "always" authorization
        if status == .notDetermined {
            print("📍 Requesting 'Always' location permission...")
            locationManager.requestAlwaysAuthorization()
            return
        }
        
        // If denied or restricted, log warning but still try to start
        if status == .denied || status == .restricted {
            print("⚠️ Location permission denied or restricted - status: \(status.rawValue)")
            print("⚠️ Location updates may not work when app is terminated")
            // Still try to start - might work with when-in-use permission
        }
        
        // Check if we have "always" permission
        if status == .authorizedAlways {
            print("✅ 'Always' location permission granted")
        } else if status == .authorizedWhenInUse {
            print("⚠️ Only 'When In Use' permission granted - requesting 'Always' permission...")
            // Try to request always permission again
            locationManager.requestAlwaysAuthorization()
        }
        
        // Start location updates regardless of permission status
        // The system will handle permissions
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        
        // Start periodic timer as backup
        startPeriodicTimer()
        
        print("✅ Location updates started")
    }
    
    func stopLocationUpdates() {
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringSignificantLocationChanges()
        updateTimer?.invalidate()
        updateTimer = nil
        print("🛑 Location updates stopped")
    }
    
    private func startPeriodicTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.sendLocationIfNeeded()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        lastLocation = location
        lastUpdateTime = Date()
        
        // Send location immediately
        sendLocationToAllGroups(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        if status == .authorizedAlways {
            print("✅ 'Always' location permission granted - location updates will work even when app is terminated")
            startLocationUpdates()
        } else if status == .authorizedWhenInUse {
            print("⚠️ Only 'When In Use' permission granted - requesting 'Always' permission...")
            // Request always permission again
            manager.requestAlwaysAuthorization()
            // Still start updates - they'll work in foreground/background
            startLocationUpdates()
        } else if status == .notDetermined {
            print("📍 Location permission not determined - requesting 'Always' permission...")
            manager.requestAlwaysAuthorization()
        } else {
            print("⚠️ Location authorization not granted: \(status.rawValue)")
            print("⚠️ Location updates may not work - please grant 'Always' permission in Settings")
        }
    }
    
    // MARK: - Location Sending
    
    private func sendLocationIfNeeded() {
        guard let location = lastLocation else {
            // Try to get last known location
            if let location = locationManager?.location {
                sendLocationToAllGroups(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            return
        }
        
        // Send if enough time has passed
        if let lastUpdate = lastUpdateTime {
            let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
            if timeSinceUpdate >= updateInterval {
                sendLocationToAllGroups(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
        } else {
            sendLocationToAllGroups(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }
    
    private func sendLocationToAllGroups(latitude: Double, longitude: Double) {
        guard let token = getAuthToken() else {
            print("⚠️ No auth token found")
            return
        }
        
        let groupIds = getGroupIds()
        if groupIds.isEmpty {
            print("⚠️ No group IDs found - cannot send location updates")
            return
        }
        
        print("📍 Sending location to \(groupIds.count) groups: \(groupIds)")
        
        // Send to all groups
        for groupId in groupIds {
            sendLocationToGroup(groupId: groupId, latitude: latitude, longitude: longitude, token: token)
        }
    }
    
    private func sendLocationToGroup(groupId: Int, latitude: Double, longitude: Double, token: String) {
        let urlString = "\(baseURL)/groups/\(groupId)/location"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        let jsonBody: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            print("❌ Error creating JSON body: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error sending location to group \(groupId): \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    print("✅ Location sent to group \(groupId)")
                } else {
                    print("⚠️ Failed to send location to group \(groupId): HTTP \(httpResponse.statusCode)")
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - SharedPreferences Access
    
    private func getAuthToken() -> String? {
        // Access Flutter's SharedPreferences
        // Flutter stores data in UserDefaults with "flutter." prefix
        if let prefs = UserDefaults(suiteName: "group.com.season.app") {
            return prefs.string(forKey: "flutter.auth_token")
        }
        return UserDefaults.standard.string(forKey: "flutter.auth_token")
    }
    
    private func getGroupIds() -> [Int] {
        var groupIds: [Int] = []
        
        // Method 1: Try JSON format (flutter.tracked_group_ids)
        let jsonKey = "flutter.tracked_group_ids"
        var groupIdsJson: String?
        
        // Try app group first, then standard UserDefaults
        if let prefs = UserDefaults(suiteName: "group.com.season.app") {
            groupIdsJson = prefs.string(forKey: jsonKey)
        }
        if groupIdsJson == nil {
            groupIdsJson = UserDefaults.standard.string(forKey: jsonKey)
        }
        
        print("🔍 Method 1 - Reading flutter.tracked_group_ids")
        print("   Value: '\(groupIdsJson ?? "nil")'")
        print("   IsNil: \(groupIdsJson == nil)")
        print("   IsEmpty: \(groupIdsJson?.isEmpty ?? true)")
        print("   Length: \(groupIdsJson?.count ?? 0)")
        
        if let jsonString = groupIdsJson, !jsonString.isEmpty, jsonString != "null", jsonString != "[]" {
            let parsed = parseGroupIdsFromString(jsonString)
            print("   Parsed result: \(parsed)")
            if !parsed.isEmpty {
                groupIds.append(contentsOf: parsed)
                print("✅ Found \(groupIds.count) group IDs from JSON format")
            } else {
                print("⚠️ JSON string was not empty but parsing returned empty list")
                print("   Original string: '\(jsonString)'")
            }
        } else {
            print("⚠️ flutter.tracked_group_ids is null, empty, or invalid")
            print("   Value was: '\(groupIdsJson ?? "nil")'")
        }
        
        // Method 2: Try comma-separated string format (tracked_group_ids)
        if groupIds.isEmpty {
            print("🔍 Method 2 - Trying tracked_group_ids (without flutter. prefix)")
            let commaKey = "tracked_group_ids"
            var commaSeparated: String?
            
            if let prefs = UserDefaults(suiteName: "group.com.season.app") {
                commaSeparated = prefs.string(forKey: commaKey)
            }
            if commaSeparated == nil {
                commaSeparated = UserDefaults.standard.string(forKey: commaKey)
            }
            
            print("   Value: '\(commaSeparated ?? "nil")'")
            if let commaString = commaSeparated, !commaString.isEmpty, commaString != "null" {
                let parsed = parseGroupIdsFromString(commaString)
                print("   Parsed result: \(parsed)")
                if !parsed.isEmpty {
                    groupIds.append(contentsOf: parsed)
                    print("✅ Found \(parsed.count) group IDs from comma-separated format")
                }
            } else {
                print("   tracked_group_ids is null or empty: '\(commaSeparated ?? "nil")'")
            }
        }
        
        // Method 3: Try duplicate key flutter.flutter.tracked_group_ids
        if groupIds.isEmpty {
            print("🔍 Method 3 - Trying duplicate key flutter.flutter.tracked_group_ids")
            let duplicateKey = "flutter.flutter.tracked_group_ids"
            var duplicateValue: String?
            
            if let prefs = UserDefaults(suiteName: "group.com.season.app") {
                duplicateValue = prefs.string(forKey: duplicateKey)
            }
            if duplicateValue == nil {
                duplicateValue = UserDefaults.standard.string(forKey: duplicateKey)
            }
            
            print("   Value: '\(duplicateValue ?? "nil")'")
            if let dupString = duplicateValue, !dupString.isEmpty, dupString != "null", dupString != "[]" {
                let parsed = parseGroupIdsFromString(dupString)
                print("   Parsed result: \(parsed)")
                if !parsed.isEmpty {
                    groupIds.append(contentsOf: parsed)
                    print("✅ Found \(parsed.count) group IDs from duplicate key!")
                }
            } else {
                print("   Duplicate key is null or empty: '\(duplicateValue ?? "nil")'")
            }
        }
        
        if groupIds.isEmpty {
            print("⚠️ No group IDs found in UserDefaults after trying all methods")
            
            // Log all keys for debugging
            let standardDefaults = UserDefaults.standard
            let allKeys = standardDefaults.dictionaryRepresentation().keys
            let groupRelatedKeys = allKeys.filter { $0.contains("group") || $0.contains("tracked") }
            print("🔍 Debugging all group-related keys:")
            for key in groupRelatedKeys {
                let value = standardDefaults.string(forKey: key) ?? standardDefaults.object(forKey: key)
                print("   Key: '\(key)'")
                print("   Value: '\(value ?? "nil")'")
                print("   ---")
            }
        }
        
        return groupIds
    }
    
    private func parseGroupIdsFromString(_ jsonString: String) -> [Int] {
        print("   Parsing group IDs from string: '\(jsonString)' (length=\(jsonString.count))")
        
        // Check if empty or invalid
        if jsonString.isEmpty || jsonString == "null" || jsonString == "[]" {
            print("   Group IDs string is empty or null")
            return []
        }
        
        // Try parsing as JSON array first
        if jsonString.hasPrefix("[") {
            guard let data = jsonString.data(using: .utf8),
                  let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
                print("   Failed to parse as JSON array")
                return []
            }
            
            print("   JSON array length: \(jsonArray.count)")
            let parsed = jsonArray.compactMap { item -> Int? in
                if let intValue = item as? Int {
                    print("   JSON array item: \(intValue)")
                    return intValue > 0 ? intValue : nil
                } else if let stringValue = item as? String, let intValue = Int(stringValue) {
                    print("   JSON array item (string): \(intValue)")
                    return intValue > 0 ? intValue : nil
                }
                return nil
            }
            print("   Parsed from JSON array: \(parsed)")
            return parsed
        } else {
            // Try parsing as comma-separated string
            let parts = jsonString.split(separator: ",")
            print("   Comma-separated parts: \(parts)")
            
            let parsed = parts.compactMap { part -> Int? in
                let trimmed = part.trimmingCharacters(in: .whitespaces)
                if let value = Int(trimmed) {
                    print("   Comma-separated value '\(trimmed)' -> \(value)")
                    return value > 0 ? value : nil
                }
                return nil
            }
            print("   Parsed from comma-separated: \(parsed)")
            return parsed
        }
    }
}

