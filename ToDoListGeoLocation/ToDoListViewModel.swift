//
//  ToDoListViewModel.swift
//  ToDoListGeoLocation
//
//  Created by 林亮廷 on 2023/4/16.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine
import QuoteKit
import CoreData


//struct ToDoTask: Identifiable, Codable {
//    var id = UUID()
//    var title: String
//    var description: String
//    var createdDate: Date
//    var dueDate: Date
//    var location: CLLocationCoordinate2D
//}

/*
 struct ToDoTask: Identifiable, Codable {
     var id = UUID()
     var title: String
     var description: String
     var createdDate: Date
     var dueDate: Date
     var location: CLLocationCoordinate2D
     
     var latitude: CLLocationDegrees {
         return location.latitude
     }
     
     var longitude: CLLocationDegrees {
         return location.longitude
     }
 }
 */

class ToDoListViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var tasks: [CDToDoTask] = []
    @Published var quote: String = ""
    @Published var showError: Bool = false
    private let persistentContainer: NSPersistentContainer
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    
    override init() {
        self.persistentContainer = NSPersistentContainer(name: "CDToDoTask")
        self.persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
    }
    
    
    
    
    
    // Implement CLLocationManagerDelegate to get user's current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user's location: \(error)")
    }
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func loadTasks() {
        let request: NSFetchRequest<CDToDoTask> = CDToDoTask.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "dueDate", ascending: false)
        request.sortDescriptors = [sortDescriptor]

        do {
            let result = try persistentContainer.viewContext.fetch(request)
            tasks = result.map { $0 }
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }
    
    
    func fetchQuote() {
        let url = URL(string: "https://api.quotable.io/random")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(QuotableResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.quote = result.content
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showError = true
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showError = true
                }
            }
        }.resume()
    }
    
    
    func addTask(task: CDToDoTask) {
                let newTask = CDToDoTask(context:persistentContainer.viewContext)
                newTask.id = UUID()
                newTask.title = task.title
        newTask.taskDescription = task.description
                newTask.createdDate = task.createdDate
                newTask.dueDate = task.dueDate
        newTask.latitude = task.latitude
        newTask.longitude = task.longitude
                do {
                    try persistentContainer.viewContext.save()
                    tasks.append(newTask)
                    tasks.sort { $0.dueDate ?? Date() > $1.dueDate ?? Date() }
                } catch {
                    print("Error saving task: \(error)")
                }
    }
    
//    func updateTask(task: ToDoTask) {
//                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
//                    tasks[index].title = task.title
//                    tasks[index].description = task.description
//                    tasks[index].dueDate = task.dueDate
//                    tasks[index].location.latitude = task.location.latitude
//                    tasks[index].location.longitude = task.location.longitude
//
//                    do {
//                        try persistentContainer.viewContext.save()
//                        tasks.sort { $0.dueDate > $1.dueDate }
//                    } catch {
//                        print("Error updating task: \(error)")
//                    }
//                }
//    }
    
    func updateTask(task: CDToDoTask) {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDToDoTask")
        request.predicate = NSPredicate(format: "id == %@", task.id as! CVarArg)
        request.fetchLimit = 1

        do {
            let result = try context.fetch(request) as! [CDToDoTask]
            if let cdTask = result.first {
                cdTask.title = task.title
                cdTask.taskDescription = task.description
                cdTask.dueDate = task.dueDate
                cdTask.latitude = task.latitude
                cdTask.longitude = task.longitude

                try context.save()
                tasks.sort { $0.dueDate ?? Date() > $1.dueDate ?? Date() }
            }
        } catch {
            print("Error updating task: \(error)")
        }
    }

    func removeTask(task: CDToDoTask) {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDToDoTask")
        request.predicate = NSPredicate(format: "id == %@", (task.id ?? UUID()) as UUID as CVarArg,() as! CVarArg)
        request.fetchLimit = 1

        do {
            let result = try context.fetch(request) as! [CDToDoTask]
            if let cdTask = result.first {
                context.delete(cdTask)

                try context.save()
                tasks.removeAll { $0.id == task.id }
            }
        } catch {
            print("Error removing task: \(error)")
        }
    }
}


extension CLLocationCoordinate2D: Codable {
    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try values.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try values.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

