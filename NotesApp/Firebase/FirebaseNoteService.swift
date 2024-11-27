//
//  FirebaseNoteService.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 04/11/2024.
//

import Foundation
import Firebase
import FirebaseFirestore

protocol NoteServiceProtocol {
    func fetchNotes(completion: @escaping ([Note]) -> Void)
    func fetchNoteById(noteId: String, completion: @escaping (Note?) -> Void)
    func save(note: Note, completion: @escaping (Bool) -> Void)
    func update(note: Note, completion: @escaping (Bool) -> Void)
    func delete(noteId: String, completion: @escaping (Bool) -> Void)
}


class FirebaseNoteService: NoteServiceProtocol {
    
    private let db = Firestore.firestore()

    func fetchNotes(completion: @escaping ([Note]) -> Void) {
        db.collection("notes").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching notes: \(error.localizedDescription)")
                completion([])
                return
            }

            var notes: [Note] = []
            snapshot?.documents.forEach { doc in
                let note = self.documentToNote(doc)
                notes.append(note)
            }
            completion(notes)
        }
    }
    
    func fetchNoteById(noteId: String, completion: @escaping (Note?) -> Void) {
        // Firebase-specific code to fetch a note by its ID
        // For example:
        let db = Firestore.firestore()
        db.collection("notes").document(noteId).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                let note = Note(id: document.documentID, title: data["title"] as! String, content: data["content"] as! String, timestamp: data["timestamp"] as! Date, isSynced: true)
                completion(note)
            } else {
                completion(nil)
            }
        }
    }

    func save(note: Note, completion: @escaping (Bool) -> Void) {
        let noteData: [String: Any] = [
            "id": note.id,
            "title": note.title,
            "content": note.content,
            "timestamp": note.timestamp,
            "isSynced": true
        ]
        
        db.collection("notes").document(note.id).setData(noteData) { error in
            if let error = error {
                print("Error saving note: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }

    func update(note: Note, completion: @escaping (Bool) -> Void) {
        let noteData: [String: Any] = [
            "title": note.title,
            "content": note.content,
            "timestamp": note.timestamp,
            "isSynced": true
        ]
        
        db.collection("notes").document(note.id).updateData(noteData) { error in
            if let error = error {
                print("Error updating note: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }

    func delete(noteId: String, completion: @escaping (Bool) -> Void) {
        db.collection("notes").document(noteId).delete { error in
            if let error = error {
                print("Error deleting note: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }

    private func documentToNote(_ document: QueryDocumentSnapshot) -> Note {
        return Note(
            id: document["id"] as? String ?? UUID().uuidString,
            title: document["title"] as? String ?? "",
            content: document["content"] as? String ?? "",
            timestamp: document["timestamp"] as? Date ?? Date(),
            isSynced: document["isSynced"] as? Bool ?? false
        )
    }
}

