import SwiftUI
import MapKit

struct EditTripView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tripStore: TripStore
    
    // MARK: - Properties
    @State private var description: String
    @State private var selectedUsers: Set<User>
    @State private var selectedDate: Date
    @State private var kilometers: String
    @State private var selectedZone: Zone
    let originalTrip: Trip
    
    // Route properties
    @State private var isUsingRoute: Bool
    @State private var startLocation: Location?
    @State private var endLocation: Location?
    @State private var route: MKRoute?
    @State private var isCalculatingRoute = false
    
    @StateObject private var locationManager = LocationManager.shared
    @State private var camera: MapCameraPosition
    
    // MARK: - Initialization
    init(trip: Trip) {
        self.originalTrip = trip
        _description = State(initialValue: trip.description)
        _selectedUsers = State(initialValue: trip.participants)
        _selectedDate = State(initialValue: trip.date)
        _kilometers = State(initialValue: String(format: "%.1f", trip.kilometers))
        _selectedZone = State(initialValue: trip.selectedZone)
        
        // Initialize route-related properties with stored values
        _isUsingRoute = State(initialValue: trip.isUsingRoute)
        _startLocation = State(initialValue: trip.startLocation)
        _endLocation = State(initialValue: trip.endLocation)
        
        // Initialize map with the correct location
        let center = trip.startLocation?.coordinate ?? 
                     trip.endLocation?.coordinate ?? 
                     CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522)
        
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        _camera = State(initialValue: .region(region))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Trip Details").font(.headline)) {
                TextField("Description", text: $description)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .listRowBackground(Color.clear)
            
            Section(header: Text("Date").font(.headline)) {
                DatePicker(
                    "Trip Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
            }
            .listRowBackground(Color.clear)
            
            Section(header: Text("Participants").font(.headline)) {
                ForEach(User.users) { user in
                    HStack {
                        Text(user.name)
                        Spacer()
                        if selectedUsers.contains(user) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedUsers.contains(user) {
                            selectedUsers.remove(user)
                        } else {
                            selectedUsers.insert(user)
                        }
                    }
                }
            }
            .listRowBackground(Color.clear)
            
            Section(header: Text("Distance").font(.headline)) {
                Toggle("Calculate using route", isOn: $isUsingRoute)
                
                if isUsingRoute {
                    VStack(spacing: 12) {
                        LocationSearchBar(
                            placeholder: "Starting point",
                            location: $startLocation
                        )
                        
                        LocationSearchBar(
                            placeholder: "Destination",
                            location: $endLocation
                        )
                        
                        if let currentRoute = route {
                            routeDetailsView(route: currentRoute)
                        } else if isCalculatingRoute {
                            ProgressView("Calculating route...")
                        }
                    }
                } else {
                    TextField("Kilometers", text: $kilometers)
                        .keyboardType(.decimalPad)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    if let kilometers = Double(kilometers),
                       let price = calculatePrice(kilometers: kilometers) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text(String(format: "%.2f kr", price))
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .listRowBackground(Color.clear)
            
            Section(header: Text("Zone").font(.headline)) {
                Picker("Select Zone", selection: $selectedZone) {
                    ForEach(Zone.zones) { zone in
                        Text("\(zone.name) (\(zone.priceDescription))")
                            .tag(zone)
                    }
                }
                .pickerStyle(.menu)
            }
            .listRowBackground(Color.clear)
            
            Section {
                Button("Save Changes") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled((!isUsingRoute && kilometers.isEmpty) || selectedUsers.isEmpty)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Edit Trip")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: startLocation) { _, _ in calculateRoute() }
        .onChange(of: endLocation) { _, _ in calculateRoute() }
        .onChange(of: isUsingRoute) { _, newValue in
            if !newValue {
                clearRouteData()
            }
        }
        .onAppear {
            // Calculate initial route if needed
            if isUsingRoute && startLocation != nil && endLocation != nil {
                calculateRoute()
            }
        }
    }
    
    private func routeDetailsView(route: MKRoute) -> some View {
        VStack {
            HStack {
                Image(systemName: "ruler")
                Text(String(format: "%.1f km", route.distance / 1000))
            }
            
            if let price = calculatePrice(kilometers: route.distance / 1000) {
                HStack {
                    Image(systemName: "creditcard")
                    Text(String(format: "%.2f kr", price))
                }
            }
            
            Map(position: $camera) {
                if let start = startLocation {
                    Marker("Start", coordinate: start.coordinate)
                        .tint(.green)
                }
                if let end = endLocation {
                    Marker("End", coordinate: end.coordinate)
                        .tint(.red)
                }
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 3)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private func calculatePrice(kilometers: Double) -> Double? {
        guard kilometers > 0 else { return nil }
        return kilometers * selectedZone.pricePerKm
    }
    
    private func clearRouteData() {
        startLocation = nil
        endLocation = nil
        route = nil
    }
    
    private func calculateRoute() {
        guard isUsingRoute,
              let startLocation = startLocation,
              let endLocation = endLocation else {
            route = nil
            return
        }
        
        isCalculatingRoute = true
        
        let request = MKDirections.Request()
        request.transportType = .automobile
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endLocation.coordinate))
        
        MKDirections(request: request).calculate { response, error in
            isCalculatingRoute = false
            
            if let error = error {
                print("Route calculation error: \(error.localizedDescription)")
                return
            }
            
            if let route = response?.routes.first {
                self.route = route
                self.kilometers = String(format: "%.1f", route.distance / 1000)
                
                let coordinates = [startLocation.coordinate, endLocation.coordinate]
                let mapRect = coordinates.reduce(MKMapRect.null) { rect, coordinate in
                    let point = MKMapPoint(coordinate)
                    let pointRect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
                    return rect.union(pointRect)
                }
                
                let padding = 1.5
                let paddedRect = mapRect.insetBy(dx: -mapRect.width * padding, dy: -mapRect.height * padding)
                camera = .region(MKCoordinateRegion(paddedRect))
            }
        }
    }
    
    private func saveChanges() {
        let kilometers: Double
        if isUsingRoute {
            guard let route = route else { return }
            kilometers = route.distance / 1000
        } else {
            guard let manualKilometers = Double(self.kilometers) else { return }
            kilometers = manualKilometers
        }
        
        let updatedTrip = Trip(
            id: originalTrip.id,
            car: originalTrip.car,
            date: selectedDate,
            kilometers: kilometers,
            description: description,
            participants: selectedUsers,
            isOsloArea: selectedZone.isOsloArea,
            isUsingRoute: isUsingRoute,
            startLocation: startLocation,
            endLocation: endLocation,
            selectedZone: selectedZone
        )
        
        tripStore.updateTrip(updatedTrip)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditTripView(trip: Trip(
            id: UUID(),
            car: Car(id: UUID(), name: "Roy", licensePlate: "EV89790"),
            date: Date(),
            kilometers: 10,
            description: "Test Trip",
            participants: Set(User.users),
            isOsloArea: true,
            selectedZone: Zone.zones[0]
        ))
        .environmentObject(TripStore())
    }
} 