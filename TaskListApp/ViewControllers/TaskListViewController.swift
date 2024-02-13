//
//  ViewController.swift
//  TaskListApp
//
//  Created by Alexey Efimov on 11.02.2024.
//

import UIKit

final class TaskListViewController: UITableViewController {
    private var taskList: [ToDoTask] = []
    private let cellID = "task"
    
    private let storageManager = StorageManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        fetchData()
    }
    
    @objc private func addNewTask() {
        showAlert(withTitle: "New Task", andMessage: "What do you want to do&")
    }
    
    private func fetchData() {
        let fetchRequest = ToDoTask.fetchRequest()
        
        do {
           taskList = try storageManager.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            print(error)
        }
    }
    
    private func showAlert(withTitle title: String, andMessage message: String, task: ToDoTask? = nil, indexPath: IndexPath? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Task name"
            if let task = task {
                textField.text = task.title
            }
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [unowned self] _ in
            guard let taskName = alert.textFields?.first?.text, !taskName.isEmpty else { return }
            
            if let task = task {
                task.title = taskName
                if let indexPath = indexPath {
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            } else {
                save(taskName)
            }
            
            storageManager.saveContext()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func save(_ taskName: String) {
        let task = ToDoTask(context: storageManager.persistentContainer.viewContext)
        task.title = taskName
        taskList.append(task)
        
        let indexPath = IndexPath(row: taskList.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        
        storageManager.saveContext()
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let toDoTask = taskList[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = toDoTask.title
        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - Setup UI
private extension TaskListViewController {
    func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        navBarAppearance.backgroundColor = .milkBlue
        
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        // Add button to navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        navigationController?.navigationBar.tintColor = .white
    }
}

extension TaskListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        editTask(at: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteTask(at: indexPath)
        }
    }
}

private extension TaskListViewController {
    func editTask(at indexPath: IndexPath) {
        let toDoTask = taskList[indexPath.row]
        showAlert(withTitle: "Edit Task", andMessage: "Edit your task", task: toDoTask, indexPath: indexPath)
    }
    
    func deleteTask(at indexPath: IndexPath) {
        let toDoTask = taskList[indexPath.row]
        storageManager.persistentContainer.viewContext.delete(toDoTask)
        taskList.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        storageManager.saveContext()
    }
}
