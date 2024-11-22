import SwiftUI
import MapKit

struct LocationSearchBar: View {
    let placeholder: String
    @Binding var location: Location?
    @State private var searchText = ""
    @State private var suggestions: [MKLocalSearchCompletion] = []
    @State private var completer: MKLocalSearchCompleter
    @State private var isSearching = false
    @StateObject private var delegate = SearchCompleterDelegate()
    @State private var showingCommonLocations = false
    
    init(placeholder: String, location: Binding<Location?>) {
        self.placeholder = placeholder
        self._location = location
        
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        self._completer = State(initialValue: completer)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField(placeholder, text: $searchText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            suggestions = []
                        } else {
                            completer.queryFragment = newValue
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        suggestions = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Menu {
                    ForEach(CommonLocation.locations) { location in
                        Button(location.name) {
                            self.location = location
                            self.searchText = location.name
                            suggestions = []
                        }
                    }
                } label: {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            if !suggestions.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            SuggestionRow(suggestion: suggestion) {
                                searchLocation(from: suggestion)
                            }
                            if suggestion != suggestions.last {
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 4)
                .frame(maxHeight: 300)
            }
        }
        .onAppear {
            delegate.onUpdate = { newSuggestions in
                suggestions = newSuggestions
            }
            completer.delegate = delegate
        }
    }
    
    private func searchLocation(from suggestion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: suggestion)
        
        MKLocalSearch(request: searchRequest).start { response, error in
            guard let response = response,
                  let item = response.mapItems.first else {
                return
            }
            
            let newLocation = Location(
                name: suggestion.title + (suggestion.subtitle.isEmpty ? "" : ", \(suggestion.subtitle)"),
                coordinate: item.placemark.coordinate
            )
            
            location = newLocation
            searchText = suggestion.title
            suggestions = []
        }
    }
}

struct CommonLocationsView: View {
    @Binding var location: Location?
    @Binding var searchText: String
    @Binding var showingPopover: Bool
    
    var body: some View {
        List {
            ForEach(CommonLocation.locations, id: \.id) { location in
                Button {
                    self.location = location
                    self.searchText = location.name
                    self.showingPopover = false
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                        Text(location.name)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .listStyle(.plain)
        .frame(minWidth: 250, maxHeight: 300)
    }
}

class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    var onUpdate: (([MKLocalSearchCompletion]) -> Void)?
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate?(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}

struct SuggestionRow: View {
    let suggestion: MKLocalSearchCompletion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Image(systemName: getSuggestionIcon())
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.title)
                            .foregroundColor(.primary)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func getSuggestionIcon() -> String {
        if suggestion.title.contains("Street") || suggestion.title.contains("Road") {
            return "road.lanes"
        } else if suggestion.subtitle.contains("Restaurant") || suggestion.subtitle.contains("Café") {
            return "fork.knife"
        } else if suggestion.subtitle.contains("Store") || suggestion.subtitle.contains("Shop") {
            return "cart"
        } else {
            return "mappin"
        }
    }
}

#Preview {
    LocationSearchBar(placeholder: "Search location", location: .constant(nil))
        .padding()
} 