//
//  Note.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 04/11/2024.
//

import Foundation

struct Note: Identifiable, Codable {
    
    let id: String
    var title: String
    var content: String
    var timestamp: Date
    var isSynced: Bool
}
