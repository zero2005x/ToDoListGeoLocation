//
//  ContentView.swift
//  ToDoListGeoLocation
//
//  Created by 林亮廷 on 2023/4/16.
//

import SwiftUI
import CoreLocation
import Combine
import CoreData
import QuoteKit



struct TaskEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(86400)
    
    var task: CDToDoTask?
    var saveTask: (CDToDoTask) -> Void
    
    init(task: CDToDoTask?, saveTask: @escaping (CDToDoTask) -> Void) {
        self.task = task
        self.saveTask = saveTask
        _title = State(initialValue: task?.title ?? "")
        _description = State(initialValue: task?.description ?? "")
        _dueDate = State(initialValue: task?.dueDate ?? Date().addingTimeInterval(86400))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Information")) {
                    TextField("Title (e.g., See a doctor)", text: $title)
                    TextField("Description (e.g., Take the Bus 123)", text: $description)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle(task == nil ? "Add Task" : "Edit Task")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                let newTask = CDToDoTask()
                saveTask(newTask)
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct QuotableResponse: Codable {
    let content: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ToDoListViewModel()
    @State private var showEditor = false
    @State private var selectedTask: CDToDoTask?
    
    
    var body: some View {
       
        
        NavigationView {
            VStack {
                if viewModel.tasks.isEmpty {
                    VStack {
                        Text("Your to-do list is empty.")
                            .font(.title)
                        Text("Tap the button below to add your first task.")
                            .font(.body)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.tasks) { task in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(task.title ?? "")
                                        .font(.headline)
                                    Text(task.description)
                                        .font(.subheadline)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(task.createdDate ?? Date(), style: .date)
                                    Text(task.dueDate ?? Date(), style: .date)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTask = task
                                showEditor = true
                            }
                        }
                        .onDelete(perform: { indexSet in
                            indexSet.forEach { index in
                                viewModel.removeTask(task: viewModel.tasks[index])
                            }
                        })
                    }
                }
            }
            .navigationTitle("To-Do List")
            .navigationBarItems(trailing: Button(action: {
                showEditor = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showEditor) {
                TaskEditorView(task: selectedTask, saveTask: { task in
                    if let _ = selectedTask {
                        viewModel.updateTask(task: task)
                    } else {
                        viewModel.addTask(task: task)
                    }
                    selectedTask = nil
                })
            }
            .onAppear {
                viewModel.fetchQuote()
                viewModel.loadTasks()
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"), message: Text   ("Failed to fetch quote or no Internet connection."), dismissButton: .default(Text("OK")))
            }
            VStack {
                Text("Quote of the day:")
                    .font(.headline)
                Text(viewModel.quote.isEmpty ? "Loading quote..." : viewModel.quote)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
        }
    }
    
    
}
