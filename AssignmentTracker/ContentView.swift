//
//  ContentView.swift
//  AssignmentTracker
//
//  Created by Jeremy Underwood on 3/19/25.
//

import SwiftUI

struct ContentView: View {
    @State private var courseName: String = ""
    @State private var estimatedHours: String = ""

    var body: some View {
        VStack {
            Text("Assignment Tracker")
                .font(.largeTitle)
                .padding()

            TextField("Course Name", text: $courseName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Estimated Hours", text: $estimatedHours)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                // .keyboardType(.numberPad) iOS only
                .padding()

            Button(action: {
                if let hours = Int(estimatedHours) {
                    DatabaseManager.shared.addCourse(name: courseName, estimatedHours: hours)
                }
            }) {
                Text("Add Course")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
