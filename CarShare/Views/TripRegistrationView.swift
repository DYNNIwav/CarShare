import SwiftUI
import MapKit

struct TripRegistrationView: View {
    // MARK: - Properties
    // Core properties
    @EnvironmentObject private var tripStore: TripStore
    @State private var selectedCar: Car?
    @State private var description: String = ""
    @State private var selectedUsers: Set<User> = []
    @State private var selectedDate = Date()
    @State private var showingConfirmation = false
    
    // Distance calculation properties
    @State private var kilometers: String = ""
    @State private var isUsingRoute = false
    @State private var startLocation: Location?
    @State private var endLocation: Location?
    @State private var route: MKRoute?
    @State private var isCalculatingRoute = false
    
    // Location and map properties
    @StateObject private var locationManager = LocationManager.shared
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var camera: MapCameraPosition
    
    // Zone properties
    @State private var selectedZone: Zone = Zone.zones[0]
    
    // Constants
    let cars = [
        Car(id: UUID(), name: "Roy", licensePlate: "EV89790")
    ]
    
    // MARK: - Initialization
    init() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        _camera = State(initialValue: .region(region))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                carSection
                distanceSection
                dateSection
                participantsSection
                detailsSection
                zoneSection
                registerSection
            }
            .navigationTitle("Register Trip")
            .onChange(of: startLocation) { _, _ in calculateRoute() }
            .onChange(of: endLocation) { _, _ in calculateRoute() }
            .onChange(of: isUsingRoute) { _, newValue in
                if !newValue {
                    clearRouteData()
                }
            }
            .alert("Trip Registered", isPresented: $showingConfirmation) {
                Button("OK") { }
            } message: {
                Text("The trip has been successfully registered.")
            }
            .onAppear {
                selectedCar = cars[0]
            }
        }
    }
    
    // MARK: - View Sections
    private var carSection: some View {
        Section(header: Text("Car")) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.blue)
                Text("Roy (Ford Focus)")
                    .font(.headline)
            }
        }
    }
    
    private var distanceSection: some View {
        Section(header: Text("Distance")) {
            Toggle("Calculate using route", isOn: $isUsingRoute)
            
            if isUsingRoute {
                routeInputView
            } else {
                manualInputView
            }
        }
    }
    
    private var routeInputView: some View {
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
    }
    
    private var manualInputView: some View {
        VStack {
            TextField("Kilometers", text: $kilometers)
                .keyboardType(.decimalPad)
            
            if let kilometers = Double(kilometers),
               let price = calculatePrice(kilometers: kilometers) {
                HStack {
                    Image(systemName: "creditcard")
                    Text(String(format: "%.2f kr", price))
                }
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
            
            routeMapView(route: route)
        }
    }
    
    private func routeMapView(route: MKRoute) -> some View {
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
    
    private var dateSection: some View {
        Section(header: Text("Date")) {
            DatePicker(
                "Trip Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
        }
    }
    
    private var participantsSection: some View {
        Section(header: Text("Participants")) {
            ForEach(User.users) { user in
                Toggle(user.name, isOn: Binding(
                    get: { selectedUsers.contains(user) },
                    set: { isSelected in
                        if isSelected {
                            selectedUsers.insert(user)
                        } else {
                            selectedUsers.remove(user)
                        }
                    }
                ))
            }
        }
    }
    
    private var detailsSection: some View {
        Section(header: Text("Trip Details")) {
            TextField("Description", text: $description)
        }
    }
    
    private var zoneSection: some View {
        Section(header: Text("Zone")) {
            Picker("Select Zone", selection: $selectedZone) {
                ForEach(Zone.zones) { zone in
                    Text("\(zone.name) (\(zone.priceDescription))")
                        .tag(zone)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    private var registerSection: some View {
        Section {
            Button("Register Trip") {
                registerTrip()
            }
            .disabled((!isUsingRoute && kilometers.isEmpty) || 
                     (isUsingRoute && route == nil) || 
                     selectedUsers.isEmpty)
        }
    }
    
    // MARK: - Helper Methods
    private func clearRouteData() {
        startLocation = nil
        endLocation = nil
        route = nil
    }
    
    private func calculatePrice(kilometers: Double) -> Double? {
        guard kilometers > 0 else { return nil }
        return kilometers * selectedZone.pricePerKm
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
    
    private func registerTrip() {
        guard let car = selectedCar else { return }
        
        let kilometers: Double
        if isUsingRoute {
            guard let route = route else { return }
            kilometers = route.distance / 1000
        } else {
            guard let manualKilometers = Double(self.kilometers) else { return }
            kilometers = manualKilometers
        }
        
        let trip = Trip(
            id: UUID(),
            car: car,
            date: selectedDate,
            kilometers: kilometers,
            description: description,
            participants: selectedUsers,
            isOsloArea: selectedZone.isOsloArea
        )
        
        tripStore.addTrip(trip)
        
        // Reset form
        self.description = ""
        self.selectedUsers = []
        self.selectedDate = Date()
        self.selectedZone = Zone.zones[0]
        if isUsingRoute {
            clearRouteData()
        } else {
            self.kilometers = ""
        }
        self.showingConfirmation = true
    }
}

#Preview {
    TripRegistrationView()
        .environmentObject(TripStore())
} 