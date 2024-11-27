//
//  NotesViewModel.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 04/11/2024.
//

import Foundation
import Combine
import UIKit

class NotesViewModel: ObservableObject {
    
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    
    let notesManager: NotesManager
    private var networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize NotesManager with CoreDataService and FirebaseNoteService
        let persistenceService = CoreDataService() // Or any other PersistenceService you use
        let noteService = FirebaseNoteService()    // Or any other NoteService you use for syncing
        self.notesManager = NotesManager(persistenceService: persistenceService, noteService: noteService)
        self.networkMonitor = NetworkMonitor()
        
        fetchNotes()
        setupSyncing()
    }
    
//    init(notesManager: NotesManager, networkMonitor: NetworkMonitor = NetworkMonitor()) {
//        self.notesManager = notesManager
//        self.networkMonitor = networkMonitor
//        
//        // Listen for changes in network connectivity
//        networkMonitor.$isConnected
//            .sink { [weak self] isConnected in
//                if isConnected {
//                    self?.attemptSync()  // Attempt sync when network is restored
//                }
//            }
//            .store(in: &cancellables)
//        
//        // Initially fetch the notes
//        fetchNotes()
//        setupSyncing()
//        
//    }
    
    func fetchNotes() {
        isLoading = true  // Start loading
        
        // Fetch notes using NotesManager
        notesManager.fetchNotes { [weak self] fetchedNotes in
            DispatchQueue.main.async {
                self?.notes = fetchedNotes
                self?.isLoading = false  // End loading
            }
        }
    }
    
    
    func save(note: Note, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Save the note (in Core Data or Firebase)
        notesManager.save(note: note) { [weak self] success in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                // After saving, fetch notes to refresh the list
                self?.fetchNotes()
                
                // Call the completion handler
                completion(success)
            }
        }
    }
    
    func update(note: Note, completion: @escaping (Bool) -> Void) {
        isLoading = true
        // Use NotesManager to update the note
        notesManager.update(note: note) { [weak self] success in
            DispatchQueue.main.async {
                self?.isLoading = false
                completion(success)
                self?.fetchNotes()  // Refresh the notes list after updating
            }
        }
    }
    
    func delete(noteId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        // Use NotesManager to delete the note
        notesManager.delete(noteId: noteId) { [weak self] success in
            DispatchQueue.main.async {
                self?.isLoading = false
                completion(success)
                self?.fetchNotes()  // Refresh the notes list after deletion
            }
        }
    }
    
    
    // Setup syncing of notes based on network connectivity
    private func setupSyncing() {
        // Subscribe to network change notifications and attempt sync when network is restored
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.attemptSync()  // Attempt sync whenever the app becomes active
            }
            .store(in: &cancellables)
    }

    // Attempt sync of unsynced notes
    private func attemptSync() {
        guard networkMonitor.isConnectedToInternet() else {
            // If no internet, just return
            return
        }
        
        // Sync unsynced notes
        notesManager.syncNotes()
    }
    
    // Sync notes that are saved locally (offline) to Firebase
    func syncOfflineNotes() {
        // Fetch offline notes from Core Data (local storage)
        let offlineNotes = notesManager.fetchOfflineNotes() // CoreData notes that are not yet synced
        
        // If there are offline notes, try syncing them to Firebase
        for localNote in offlineNotes {
            // Check if note exists on Firebase (to handle conflicts)
            checkIfNoteExistsOnFirebase(noteId: localNote.id) { remoteNote in
                if let remoteNote = remoteNote {
                    // Handle conflict resolution here, e.g. merge or keep the latest note
                    self.handleSyncConflict(localNote: localNote, remoteNote: remoteNote)
                } else {
                    // If no conflict, save the note to Firebase
                    self.saveToFirebase(note: localNote)
                }
            }
        }
    }

    // Check if a note already exists on Firebase (to handle conflicts)
    private func checkIfNoteExistsOnFirebase(noteId: String, completion: @escaping (Note?) -> Void) {
        notesManager.fetchNoteFromFirebase(noteId: noteId) { remoteNote in
            completion(remoteNote)
        }
    }

    // Handle conflict between local and remote notes
    private func handleSyncConflict(localNote: Note, remoteNote: Note) {
        // Example conflict resolution: keep the most recent note (based on timestamp)
        if localNote.timestamp > remoteNote.timestamp {
            // Local note is more recent, sync it to Firebase
            self.saveToFirebase(note: localNote)
        } else {
            // Remote note is more recent, no action needed (or merge if necessary)
            print("Remote note is more recent, no action needed.")
        }
    }
        
    // Save a note to Firebase and mark it as synced
    private func saveToFirebase(note: Note) {
        notesManager.saveNoteToFirebase(note: note) { success in
            if success {
                // Mark the note as synced in Core Data after successful upload
                self.updateSyncStatus(note.id, isSynced: true)
            }
        }
    }
        
    // Update the sync status of a note (sync complete)
    private func updateSyncStatus(_ noteId: String, isSynced: Bool) {
        notesManager.updateSyncStatus(noteId, isSynced: isSynced)
    }
}

