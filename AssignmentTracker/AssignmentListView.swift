//
//  AssignmentListView.swift
//  AssignmentTracker
//
//  Created by Jeremy Underwood on 4/5/25.
//

import SwiftUI
import Foundation

struct Assignment: Identifiable {
    let id: Int64
    let title: String
    let dueDate: Date
    let estimatedHours: Int
    var loggedHours: Double = 0.0
}


struct AssignmentListView: View {
    let courseName: String

    @State private var assignments: [Assignment] = []
    @State private var showingAddAssignment = false
    @State private var selectedLogTime: [Int64: Double] = [:] // Tracks dropdown selection per assignment

    var body: some View {
        VStack {
            List(assignments) { assignment in
                VStack(alignment: .leading, spacing: 6) {
                    Text(assignment.title)
                        .font(.headline)

                    Text("Due: \(formattedDate(assignment.dueDate))")
                        .font(.subheadline)

                    Text("Logged: \(String(format: "%.2f", assignment.loggedHours))h / \(assignment.estimatedHours)h")
                        .font(.caption)
                        .foregroundColor(.gray)

                    // Dropdown for logging time
                    Picker("Log Time", selection: Binding(
                        get: { selectedLogTime[assignment.id] ?? 0.25 },
                        set: { selectedLogTime[assignment.id] = $0 }
                    )) {
                        ForEach([0.10, 0.15, 0.20, 0.25, 0.30, 0.45, 0.50, 0.75, 1.0], id: \.self) { value in
                            Text("\(Int(value * 60)) min").tag(value)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 4)

                    Button("Log Time") {
                        let hours = selectedLogTime[assignment.id] ?? 0.25
                        logTime(for: assignment.id, hours: hours)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 4)
                }
                .padding(.vertical, 6)
            }

            Button("Add Assignment") {
                showingAddAssignment = true
            }
            .padding()
        }
        .navigationTitle(courseName)
        .onAppear(perform: loadAssignments)
        .sheet(isPresented: $showingAddAssignment) {
            AddAssignmentView(courseName: courseName, onAdd: {
                loadAssignments()
                showingAddAssignment = false
            })
        }
    }

    func loadAssignments() {
        assignments = DatabaseManager.shared.getAssignmentsForCourse(named: courseName)
    }

    func logTime(for assignmentID: Int64, hours: Double) {
        DatabaseManager.shared.logTime(assignmentID: assignmentID, date: Date(), hours: hours)
        loadAssignments()
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
