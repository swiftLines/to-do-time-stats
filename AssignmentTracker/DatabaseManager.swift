//
//  DatabaseManager.swift
//  AssignmentTracker
//
//  Created by Jeremy Underwood on 3/19/25.
//

import Foundation
import SQLite

typealias Expression = SQLite.Expression

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?

    private let courses = Table("courses")
    private let assignments = Table("assignments")
    private let timeLogs = Table("time_logs")
    private let userPreferences = Table("user_preferences")
    
    // Courses
    private let courseID = Expression<Int64>("id")
    private let courseName = Expression<String>("name")
    // private let estimatedHours = Expression<Int>("estimated_hours")

    // Assignments
    private let assignmentID = Expression<Int64>("id")
    private let assignmentTitle = Expression<String>("title")
    private let courseIDFK = Expression<Int64>("course_id")
    private let dueDate = Expression<Date>("due_date")
    private let assignmentEstimatedHours = Expression<Int>("estimated_hours")
    private let status = Expression<String>("status")
    private let colorCode = Expression<String>("color_code")

    // Time Logs
    private let logID = Expression<Int64>("id")
    private let assignmentIDFK = Expression<Int64>("assignment_id")
    private let dateLogged = Expression<Date>("date_logged")
    private let hoursLogged = Expression<Double>("hours_logged")

    // User Preferences Columns
    private let preferenceID = Expression<Int64>("id")
    private let darkMode = Expression<Bool>("dark_mode")
    private let autoSuggestions = Expression<Bool>("auto_suggestions")
    private let reminders = Expression<Bool>("reminders")
    private let weekStartDay = Expression<String>("week_start_day")

    private init() {
        do {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("assignments_tracker.sqlite").path
            db = try Connection(path)
            createTables()
        } catch {
            print("Error initializing database: \(error)")
        }
    }

    private func createTables() {
        do {
            try db?.run(courses.create(ifNotExists: true) { table in
                table.column(courseID, primaryKey: .autoincrement)
                table.column(courseName)
                // table.column(estimatedHours)
            })

            try db?.run(assignments.create(ifNotExists: true) { table in
                table.column(assignmentID, primaryKey: .autoincrement)
                table.column(assignmentTitle)
                table.column(courseIDFK)
                table.column(dueDate)
                table.column(assignmentEstimatedHours)
                table.column(status)
                table.column(colorCode)
            })

            try db?.run(timeLogs.create(ifNotExists: true) { table in
                table.column(logID, primaryKey: .autoincrement)
                table.column(assignmentIDFK)
                table.column(dateLogged)
                table.column(hoursLogged)
            })

            try db?.run(userPreferences.create(ifNotExists: true) { table in
                table.column(preferenceID, primaryKey: .autoincrement)
                table.column(darkMode, defaultValue: false)
                table.column(autoSuggestions, defaultValue: true)
                table.column(reminders, defaultValue: true)
                table.column(weekStartDay, defaultValue: "Wednesday")
            })
        } catch {
            print("Error creating tables: \(error)")
        }
    }

    // MARK: - CRUD Operations

    func addCourse(name: String) {
        do {
            let insert = courses.insert(courseName <- name)
            try db?.run(insert)
        } catch {
            print("Error adding course: \(error)")
        }
    }

    func addAssignment(title: String, courseID: Int64, dueDate: Date, estimatedHours: Int, colorCode: String) {
        do {
            let insert = assignments.insert(
                assignmentTitle <- title,
                courseIDFK <- courseID,
                self.dueDate <- dueDate,
                assignmentEstimatedHours <- estimatedHours,
                status <- "Incomplete",
                self.colorCode <- colorCode
            )
            try db?.run(insert)
        } catch {
            print("Error adding assignment: \(error)")
        }
    }

    func logTime(assignmentID: Int64, date: Date, hours: Double) {
        guard hours <= 1.0 else {
            print("Cannot log more than 1 hour at a time.")
            return
        }
        do {
            let insert = timeLogs.insert(
                assignmentIDFK <- assignmentID,
                dateLogged <- date,
                hoursLogged <- hours
            )
            try db?.run(insert)
        } catch {
            print("Error logging time: \(error)")
        }
    }

    func getAssignments(forCourse courseID: Int64) -> [String] {
        var assignmentsList: [String] = []
        do {
            let query = assignments.filter(courseIDFK == courseID)
            for assignment in try db!.prepare(query) {
                assignmentsList.append(assignment[assignmentTitle])
            }
        } catch {
            print("Error retrieving assignments: \(error)")
        }
        return assignmentsList
    }

    func updateAssignmentStatus(assignmentID: Int64, newStatus: String) {
        do {
            let assignmentToUpdate = assignments.filter(self.assignmentID == assignmentID)
            try db?.run(assignmentToUpdate.update(status <- newStatus))
        } catch {
            print("Error updating assignment status: \(error)")
        }
    }
    
    func getAllCourseNames() -> [String] {
        var names: [String] = []
        do {
            for course in try db!.prepare(courses) {
                names.append(course[courseName])
            }
        } catch {
            print("Error fetching course names: \(error)")
        }
        return names
    }
    
    func getAssignmentsForCourse(named inputCourseName: String) -> [Assignment] {
        var results: [Assignment] = []
        do {
            // First find course ID
            let courseQuery = courses.filter(courseName == inputCourseName)
            guard let courseRow = try db?.pluck(courseQuery) else { return [] }
            let courseIDValue = courseRow[courseID]

            let assignmentQuery = assignments.filter(courseIDFK == courseIDValue)
            for row in try db!.prepare(assignmentQuery) {
                let logged = getLoggedHours(for: row[assignmentID])
                let assignment = Assignment(
                    id: row[assignmentID],
                    title: row[assignmentTitle],
                    dueDate: row[dueDate],
                    estimatedHours: row[assignmentEstimatedHours],
                    loggedHours: logged
                )
                results.append(assignment)
            }
        } catch {
            print("Error loading assignments: \(error)")
        }
        return results
    }
    
    func addAssignment(title: String, inputCourseName: String, dueDate: Date, estimatedHours: Int, colorCode: String) {
        do {
            let courseQuery = courses.filter(courseName == inputCourseName)
            guard let courseRow = try db?.pluck(courseQuery) else { return }
            let courseIDValue = courseRow[courseID]

            let insert = assignments.insert(
                assignmentTitle <- title,
                courseIDFK <- courseIDValue,
                self.dueDate <- dueDate,
                assignmentEstimatedHours <- estimatedHours,
                status <- "Incomplete",
                self.colorCode <- colorCode
            )
            try db?.run(insert)
        } catch {
            print("Error adding assignment: \(error)")
        }
    }

    func getLoggedHours(for assignmentID: Int64) -> Double {
        var total: Double = 0
        do {
            let logs = timeLogs.filter(assignmentIDFK == assignmentID)
            for log in try db!.prepare(logs) {
                total += log[hoursLogged]
            }
        } catch {
            print("Error calculating logged hours: \(error)")
        }
        return total
    }

}
