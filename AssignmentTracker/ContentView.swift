//
//  ContentView.swift
//  AssignmentTracker
//
//  Created by Jeremy Underwood on 3/19/25.
//

import SwiftUI

struct ContentView: View {
    @State private var courses: [String] = []
    @State private var showingAddCourse = false
    @State private var newCourseName = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(courses, id: \.self) { course in
                        NavigationLink(destination: AssignmentListView(courseName: course)) {
                            Text(course)
                        }
                    }
                }

                Button("Add Course") {
                    showingAddCourse = true
                }
                .padding()
            }
            .navigationTitle("Courses")
        }
        .onAppear(perform: loadCourses)
        .sheet(isPresented: $showingAddCourse) {
            VStack(spacing: 20) {
                Text("Add New Course")
                    .font(.headline)
                TextField("Course Name", text: $newCourseName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Add") {
                    if !newCourseName.isEmpty {
                        DatabaseManager.shared.addCourse(name: newCourseName)
                        newCourseName = ""
                        showingAddCourse = false
                        loadCourses()
                    }
                }
                .padding()
                Spacer()
            }
            .padding()
            .frame(width: 300, height: 200)
        }
    }

    func loadCourses() {
        courses = DatabaseManager.shared.getAllCourseNames()
    }
}
