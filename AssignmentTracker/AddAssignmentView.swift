//
//  Untitled.swift
//  AssignmentTracker
//
//  Created by Jeremy Underwood on 4/5/25.
//

import SwiftUI

struct AddAssignmentView: View {
    let courseName: String
    var onAdd: () -> Void

    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var estimatedHours: Int = 1

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Assignment")
                .font(.title2)

            TextField("Assignment Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                .padding(.horizontal)

            Picker("Estimated Hours", selection: $estimatedHours) {
                ForEach(1...20, id: \.self) { hour in
                    Text("\(hour) hour\(hour > 1 ? "s" : "")")
                }
            }
            .padding(.horizontal)

            Button("Save Assignment") {
                saveAssignment()
                onAdd()
            }
            .buttonStyle(.borderedProminent)
            .padding()

            Spacer()
        }
        .padding()
        .frame(width: 350, height: 300)
    }

    private func saveAssignment() {
        DatabaseManager.shared.addAssignment(
            title: title,
            inputCourseName: courseName,
            dueDate: dueDate,
            estimatedHours: estimatedHours,
            colorCode: "blue" // placeholder for future
        )
    }
}

struct AddAssignmentView_Previews: PreviewProvider {
    static var previews: some View {
        AddAssignmentView(courseName: "Math", onAdd: {})
    }
}
