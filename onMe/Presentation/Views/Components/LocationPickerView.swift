//
//  LocationPickerView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import CoreLocation
import MapKit

struct LocationPickerView: View {
    @Binding var selectedLocationName: String?
    @Binding var selectedLatitude: Double?
    @Binding var selectedLongitude: Double?
    
    @State private var locationManager = LocationManager()
    @State private var showingLocationPicker = false
    @State private var customLocationName = ""
    @State private var showingCustomLocationAlert = false
    @State private var currentLocationStatus: LocationStatus = .unknown
    
    enum LocationStatus {
        case unknown
        case loading
        case success(String)
        case error(String)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("位置情報（任意）", systemImage: "location.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if selectedLocationName != nil {
                    Button("削除") {
                        clearLocation()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            if let locationName = selectedLocationName {
                LocationDisplayView(
                    locationName: locationName,
                    latitude: selectedLatitude,
                    longitude: selectedLongitude
                )
            } else {
                VStack(spacing: 8) {
                    Text("位置情報を記録すると、後で支出を思い出しやすくなります")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Button(action: getCurrentLocation) {
                                HStack(spacing: 6) {
                                    if case .loading = currentLocationStatus {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "location.circle.fill")
                                            .font(.title3)
                                    }
                                    Text("現在地")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            .disabled({
                                if case .loading = currentLocationStatus {
                                    return true
                                }
                                return false
                            }())
                            
                            Button(action: { showingLocationPicker = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title3)
                                    Text("場所を検索")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        HStack {
                            Button(action: { showingCustomLocationAlert = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                        .font(.title3)
                                    Text("手入力")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.green)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // ステータス表示
                    if case .error(let message) = currentLocationStatus {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingLocationPicker) {
            LocationSearchView(
                selectedLocationName: $selectedLocationName,
                selectedLatitude: $selectedLatitude,
                selectedLongitude: $selectedLongitude
            )
        }
        .alert("場所名を入力", isPresented: $showingCustomLocationAlert) {
            TextField("例: 新宿駅、渋谷のカフェ", text: $customLocationName)
                .textInputAutocapitalization(.words)
            
            Button("追加") {
                if !customLocationName.trimmingCharacters(in: .whitespaces).isEmpty {
                    selectedLocationName = customLocationName.trimmingCharacters(in: .whitespaces)
                    selectedLatitude = nil
                    selectedLongitude = nil
                    customLocationName = ""
                }
            }
            
            Button("キャンセル", role: .cancel) {
                customLocationName = ""
            }
        } message: {
            Text("位置情報なしで場所名のみを記録できます")
        }
    }
    
    private func getCurrentLocation() {
        currentLocationStatus = .loading
        
        locationManager.requestLocation { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let location):
                    reverseGeocode(location: location)
                case .failure(let error):
                    currentLocationStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    currentLocationStatus = .error("住所の取得に失敗しました")
                    return
                }
                
                if let placemark = placemarks?.first {
                    let locationName = formatLocationName(from: placemark)
                    selectedLocationName = locationName
                    selectedLatitude = location.coordinate.latitude
                    selectedLongitude = location.coordinate.longitude
                    currentLocationStatus = .success(locationName)
                } else {
                    currentLocationStatus = .error("住所が見つかりませんでした")
                }
            }
        }
    }
    
    private func formatLocationName(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let name = placemark.name {
            components.append(name)
        } else if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        return components.isEmpty ? "現在地" : components.joined(separator: ", ")
    }
    
    private func clearLocation() {
        selectedLocationName = nil
        selectedLatitude = nil
        selectedLongitude = nil
        currentLocationStatus = .unknown
    }
}

struct LocationDisplayView: View {
    let locationName: String
    let latitude: Double?
    let longitude: Double?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(locationName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let latitude = latitude, let longitude = longitude {
                    Text("緯度: \(String(format: "%.6f", latitude)), 経度: \(String(format: "%.6f", longitude))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("座標情報なし")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let latitude = latitude, let longitude = longitude {
                Button(action: {
                    openInMaps(latitude: latitude, longitude: longitude, name: locationName)
                }) {
                    Image(systemName: "map")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func openInMaps(latitude: Double, longitude: Double, name: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps()
    }
}

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocationName: String?
    @Binding var selectedLatitude: Double?
    @Binding var selectedLongitude: Double?
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    
    var body: some View {
        NavigationView {
            VStack {
                LocationSearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                    .padding(.horizontal)
                
                if isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("検索中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("検索結果が見つかりませんでした")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("別のキーワードで検索してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    List(searchResults, id: \.self) { mapItem in
                        LocationResultRow(mapItem: mapItem) {
                            selectLocation(mapItem)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("場所を検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // 東京
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let error = error {
                    print("検索エラー: \(error)")
                    searchResults = []
                    return
                }
                
                searchResults = response?.mapItems ?? []
            }
        }
    }
    
    private func selectLocation(_ mapItem: MKMapItem) {
        selectedLocationName = mapItem.name ?? mapItem.placemark.title ?? "選択した場所"
        selectedLatitude = mapItem.placemark.coordinate.latitude
        selectedLongitude = mapItem.placemark.coordinate.longitude
        dismiss()
    }
}

struct LocationResultRow: View {
    let mapItem: MKMapItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "location.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mapItem.name ?? "場所")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let address = formatAddress(from: mapItem.placemark) {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String? {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

struct LocationSearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("場所を検索（例: 新宿駅、渋谷カフェ）", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("検索", action: onSearchButtonClicked)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((Result<CLLocation, Error>) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        self.completion = completion
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            completion(.failure(LocationError.permissionDenied))
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        @unknown default:
            completion(.failure(LocationError.unknown))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        completion?(.success(location))
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            completion?(.failure(LocationError.permissionDenied))
        case .notDetermined:
            break
        @unknown default:
            completion?(.failure(LocationError.unknown))
        }
    }
}

enum LocationError: LocalizedError {
    case permissionDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置情報の使用が許可されていません。設定から許可してください。"
        case .unknown:
            return "位置情報の取得に失敗しました。"
        }
    }
}

#Preview {
    LocationPickerView(
        selectedLocationName: .constant(nil),
        selectedLatitude: .constant(nil),
        selectedLongitude: .constant(nil)
    )
    .padding()
}
