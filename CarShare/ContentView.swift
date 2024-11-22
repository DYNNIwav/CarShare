//
//  ContentView.swift
//  CarShare
//
//  Created by Pål Omland Eilevstjønn on 21/11/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var tripStore = TripStore()
    @StateObject private var locationStore = LocationStore()
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        TabView {
            TripRegistrationView()
                .tabItem {
                    Label("New Trip", systemImage: "car.fill")
                }
            
            TripHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
        .environmentObject(tripStore)
        .environmentObject(locationStore)
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
}

#Preview {
    ContentView()
}
