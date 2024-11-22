import SwiftUI
import MapKit

struct LocationSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationStore: LocationStore
    @Binding var selectedLocation: Location?
    
    @State private var searchText = ""
    @State private var locations: [Location] = []
    @State private var camera: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522), // Oslo
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    @State private var showingMap = true
    
    var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search location", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: searchText) { _, _ in
                        searchLocations()
                    }
                
                Picker("View", selection: $showingMap) {
                    Text("Map").tag(true)
                    Text("List").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if showingMap {
                    Map(position: $camera) {
                        ForEach(locations) { location in
                            Marker(location.name, coordinate: location.coordinate)
                                .tint(.red)
                        }
                    }
                } else {
                    List {
                        if !locationStore.favoriteLocations.isEmpty {
                            Section("Favorites") {
                                ForEach(locationStore.favoriteLocations) { location in
                                    LocationRow(location: location, onSelect: selectLocation)
                                }
                            }
                        }
                        
                        if !locations.isEmpty {
                            Section("Search Results") {
                                ForEach(locations) { location in
                                    LocationRow(location: location, onSelect: selectLocation)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func selectLocation(_ location: Location) {
        selectedLocation = location
        dismiss()
    }
    
    private func searchLocations() {
        guard !searchText.isEmpty else {
            locations = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = defaultRegion
        
        MKLocalSearch(request: request).start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            locations = response.mapItems.map { item in
                Location(
                    name: item.name ?? "Unknown location",
                    coordinate: item.placemark.coordinate
                )
            }
            
            if !locations.isEmpty {
                camera = .region(MKCoordinateRegion(
                    center: locations[0].coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ))
            }
        }
    }
}

struct LocationRow: View {
    @EnvironmentObject private var locationStore: LocationStore
    let location: Location
    let onSelect: (Location) -> Void
    
    var body: some View {
        HStack {
            Button {
                onSelect(location)
            } label: {
                Text(location.name)
            }
            
            Spacer()
            
            Button {
                if location.isFavorite {
                    locationStore.removeFavorite(location)
                } else {
                    locationStore.addFavorite(location)
                }
            } label: {
                Image(systemName: location.isFavorite ? "star.fill" : "star")
                    .foregroundColor(location.isFavorite ? .yellow : .gray)
            }
        }
    }
} 