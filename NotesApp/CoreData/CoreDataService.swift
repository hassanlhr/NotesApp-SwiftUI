//
//  CoreDataService.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 04/11/2024.
//

import Foundation
import CoreData

protocol PersistenceProtocol {
    func noteExists(noteId: String) -> Bool
    func saveNoteEntity(note: Note) -> Bool
    func fetchNoteEntities() -> [Note]
    func updateNoteEntity(note: Note) -> Bool
    func deleteNoteEntity(noteId: String) -> Bool
    func updateNoteSyncStatus(noteId: String, isSynced: Bool)
}


class CoreDataService: PersistenceProtocol {
    
    private let context = PersistenceController.shared.container.viewContext
    
    func noteExists(noteId: String) -> Bool {
        let fetchRequest: NSFetchRequest<Notes> = Notes.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteId)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Failed to check existence: \(error)")
            return false
        }
    }


    func saveNoteEntity(note: Note) -> Bool {
        let newNote = Notes(context: context)
        newNote.id = note.id
        newNote.title = note.title
        newNote.content = note.content
        newNote.timestamp = note.timestamp
        newNote.isSynced = false

        do {
            try context.save()
            return true
        } catch {
            print("Failed to save note: \(error)")
            return false
        }
    }

    func fetchNoteEntities() -> [Note] {
        let fetchRequest: NSFetchRequest<Notes> = Notes.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.map { $0.notes }
        } catch {
            print("Failed to fetch notes: \(error)")
            return []
        }
    }

    func updateNoteSyncStatus(noteId: String, isSynced: Bool) {
        let fetchRequest: NSFetchRequest<Notes> = Notes.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteId)

        do {
            let results = try context.fetch(fetchRequest)
            if let noteEntity = results.first {
                noteEntity.isSynced = isSynced
                try context.save()
            }
        } catch {
            print("Failed to update sync status: \(error)")
        }
    }

    func updateNoteEntity(note: Note) -> Bool {
        let fetchRequest: NSFetchRequest<Notes> = Notes.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", note.id)

        do {
            let results = try context.fetch(fetchRequest)
            if let noteEntity = results.first {
                noteEntity.title = note.title
                noteEntity.content = note.content
                noteEntity.timestamp = note.timestamp
                // Handle syncing status as needed
                try context.save()
                return true
            }
        } catch {
            print("Failed to update note: \(error)")
        }
        return false
    }

    func deleteNoteEntity(noteId: String) -> Bool {
        let fetchRequest: NSFetchRequest<Notes> = Notes.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteId)

        do {
            let results = try context.fetch(fetchRequest)
            if let noteEntity = results.first {
                context.delete(noteEntity)
                try context.save()
                return true
            }
        } catch {
            print("Failed to delete note: \(error)")
        }
        return false
    }
}

