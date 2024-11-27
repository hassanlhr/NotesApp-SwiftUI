//
//  NotesManager.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 04/11/2024.
//

import Foundation
import UIKit
import Combine

class NotesManager {
    
    private let persistenceService: PersistenceProtocol
    private let noteService: NoteServiceProtocol
    private let networkMonitor = NetworkMonitor() // Assume this is defined and monitors connectivity
    private var cancellables: Set<AnyCancellable> = []
    
    private var syncQueue: [Note] = [] // Queue for unsynced notes
    
    @Published var notes: [Note] = [] // Published notes that can be observed in the view
    
    init(persistenceService: PersistenceProtocol, noteService: NoteServiceProtocol) {
        self.persistenceService = persistenceService
        self.noteService = noteService
        setupNetworkMonitoring()
    }
    
//    func setupNetworkMonitoring() {
//        // Listen to network connectivity changes
//        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
//            .sink { [weak self] _ in
//                self?.attemptSync()  // Attempt sync whenever the app becomes active
//            }
//            .store(in: &cancellables)
//    }
    
    func setupNetworkMonitoring() {
        // Listen to network connectivity changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.attemptSync()  // Attempt sync whenever the app becomes active
            }
            .store(in: &cancellables)
        
        // Observe network changes for real-time syncing
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.syncNotes()
                }
            }
            .store(in: &cancellables)
    }
    
    // New method to fetch a note from Firebase by ID
    func fetchNoteFromFirebase(noteId: String, completion: @escaping (Note?) -> Void) {
        noteService.fetchNoteById(noteId: noteId) { remoteNote in
            completion(remoteNote)
        }
    }
    
    // New method to fetch offline notes from the persistence layer
    func fetchOfflineNotes() -> [Note] {
        // Assuming persistenceService has a method to fetch stored notes (e.g., Core Data)
        return persistenceService.fetchNoteEntities()
    }
    
    // Sync notes automatically on network connectivity change --Old code
//    func attemptSync() {
//        guard networkMonitor.isConnectedToInternet() else { return }
//        
//        syncQueue.forEach { note in
//            saveNoteToFirebase(note: note) { success in
//                if success {
//                    self.updateSyncStatus(note.id, isSynced: true)
//                }
//            }
//        }
//    }
    
    //New code- replace with old
    func attemptSync() {
        guard networkMonitor.isConnectedToInternet() else { return }
        
        // Fetch remote notes before syncing
        noteService.fetchNotes { remoteNotes in
            // Compare local and remote notes for conflicts
            self.persistenceService.fetchNoteEntities().forEach { localNote in
                if let remoteNote = remoteNotes.first(where: { $0.id == localNote.id }) {
                    // Handle conflict resolution (e.g., merge, overwrite, or prompt the user)
                    self.handleConflict(localNote: localNote, remoteNote: remoteNote)
                } else {
                    // No conflict, save the local note to Firebase
                    self.saveNoteToFirebase(note: localNote) { success in
                        if success {
                            self.updateSyncStatus(localNote.id, isSynced: true)
                        }
                    }
                }
            }
        }
    }
    
    //New code- added new code
    func handleConflict(localNote: Note, remoteNote: Note) {
        // Implement conflict resolution (timestamp or version-based)
        if localNote.timestamp > remoteNote.timestamp {
            // Local note is newer, update Firebase
            saveNoteToFirebase(note: localNote) { success in
                if success {
                    self.updateSyncStatus(localNote.id, isSynced: true)
                }
            }
        } else {
            // Remote note is newer, update Core Data
            updateNoteSyncStatus(noteId: remoteNote.id, isSynced: true)
            // Optionally notify the user about the conflict
        }
    }
    
    func fetchNotes(completion: @escaping ([Note]) -> Void) {
        let isFirstLaunch = UserDefaults.standard.bool(forKey: "firstLaunch")
        
        if !isFirstLaunch || networkMonitor.isConnectedToInternet() {
            noteService.fetchNotes { notes in
                notes.forEach { remoteNote in
                    if !self.persistenceService.noteExists(noteId: remoteNote.id) {
                        self.persistenceService.saveNoteEntity(note: remoteNote)
                    }
                }
                completion(notes)
                UserDefaults.standard.set(true, forKey: "firstLaunch")
            }
        } else {
//            completion(persistenceService.fetchNoteEntities())  // If offline, return local data
            
            // Fetch locally saved notes
            let localNotes = persistenceService.fetchNoteEntities()
            completion(localNotes)
        }
    }
    
    func save(note: Note, completion: @escaping (Bool) -> Void) {
        let success = persistenceService.saveNoteEntity(note: note)
        
        if success && networkMonitor.isConnectedToInternet() {
            saveNoteToFirebase(note: note, completion: completion)
        } else {
            // If offline, add to sync queue
            if !networkMonitor.isConnectedToInternet() {
                syncQueue.append(note)
            }
            completion(success)
        }
    }
    
    func saveNoteToFirebase(note: Note, completion: @escaping (Bool) -> Void) {
        noteService.save(note: note) { success in
            if success {
                self.updateSyncStatus(note.id, isSynced: true)
            }
            completion(success)
        }
    }

    func updateSyncStatus(_ noteId: String, isSynced: Bool) {
        persistenceService.updateNoteSyncStatus(noteId: noteId, isSynced: isSynced)
    }
    
    func update(note: Note, completion: @escaping (Bool) -> Void) {
        let success = persistenceService.updateNoteEntity(note: note)
        
        if success && networkMonitor.isConnectedToInternet() {
            noteService.update(note: note) { success in
                self.updateSyncStatus(note.id, isSynced: success)
                completion(success)
            }
        } else {
            completion(success)
        }
    }

    func delete(noteId: String, completion: @escaping (Bool) -> Void) {
        let success = persistenceService.deleteNoteEntity(noteId: noteId)
        
        if success && networkMonitor.isConnectedToInternet() {
            noteService.delete(noteId: noteId) { success in
                completion(success)
            }
        } else {
            completion(success)
        }
    }
    
    // Sync all unsynced notes to Firebase
    func syncNotes() {
        // Fetch all notes from Core Data that are not synced
        let unsyncedNotes = persistenceService.fetchNoteEntities().filter { !$0.isSynced }
        
        for localNote in unsyncedNotes {
            // Only sync unsynced notes to Firebase
            noteService.save(note: localNote) { success in
                if success {
                    // Update the sync status in Core Data once the note is successfully saved to Firebase
                    self.updateNoteSyncStatus(noteId: localNote.id, isSynced: true)
                }
            }
        }
    }
        
    // Update the sync status of the note in Core Data after successful Firebase sync
    private func updateNoteSyncStatus(noteId: String, isSynced: Bool) {
        if let coreDataService = persistenceService as? CoreDataService {
            coreDataService.updateNoteSyncStatus(noteId: noteId, isSynced: isSynced)
        }
    }
}


