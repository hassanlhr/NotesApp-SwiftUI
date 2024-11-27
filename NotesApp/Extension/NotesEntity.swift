//
//  NotesEntity.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 05/11/2024.
//


import CoreData

extension Notes {
    var notes: Note {
        return Note(
            id: self.id ?? UUID().uuidString,  // Assuming id is a String
            title: self.title ?? "",
            content: self.content ?? "",
            timestamp: self.timestamp ?? Date(),
            isSynced: self.isSynced
        )
    }
}
