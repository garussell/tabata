//
//  ContentView.swift
//  tabata
//
//  Created by Allen Russell on 2/27/26.
//

import SwiftUI

/// Root view: owns the ViewModel and routes between the timer and completion screens.
struct ContentView: View {
    @State private var viewModel = TabataViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.phase == .complete {
                    CompletionView(viewModel: viewModel)
                        .navigationTitle("Complete!")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    TimerView(viewModel: viewModel)
                        .navigationTitle("Tabata")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: viewModel.phase == .complete)
        }
    }
}

#Preview {
    ContentView()
}
