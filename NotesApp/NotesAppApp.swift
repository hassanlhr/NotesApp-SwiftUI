//
//  NotesAppApp.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 04/11/2024.
//

import SwiftUI
import FirebaseCore
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        FirebaseApp.configure()
        
        registerBackgroundTasks()
        
        return true
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Sync notes when the app becomes active
        let viewModel = NotesViewModel()
        viewModel.syncOfflineNotes()  // Sync when app becomes active if online
    }
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.myapp.syncNotes", using: nil) { task in
            self.handleSyncBackgroundTask(task: task as! BGAppRefreshTask)
        }
        
    }
        
    func handleSyncBackgroundTask(task: BGAppRefreshTask) {
        let expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        task.expirationHandler = expirationHandler
        
        // Perform sync task in background
        syncNotesInBackground {
            task.setTaskCompleted(success: true)
        }
        
        // Schedule next sync
        scheduleNextSync()
    }
        
    func syncNotesInBackground(completion: @escaping () -> Void) {
        // Perform the sync logic here by using NotesManager to sync notes
        let notesManager = NotesManager(persistenceService: CoreDataService(), noteService: FirebaseNoteService())
        notesManager.attemptSync()
        
        completion()
    }
        
    func scheduleNextSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.myapp.syncNotes")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15) // Schedule next sync in 15 minutes
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to submit background task: \(error)")
        }
    }
}

@main
struct NotesAppApp: App {
    let persistenceController = PersistenceController.shared
    
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            NotesListView()
                .environmentObject(networkMonitor)
        }
    }
}
