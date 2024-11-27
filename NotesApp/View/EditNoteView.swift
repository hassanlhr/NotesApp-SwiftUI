//
//  EditNoteView.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 05/11/2024.
//

import SwiftUI

struct EditNoteView: View {
    
    var note: Note
    @ObservedObject var viewModel: NotesViewModel
    
    @State private var title: String
    @State private var content: String
    @State private var isLoading: Bool = false

    init(note: Note, viewModel: NotesViewModel) {
        self.note = note
        self.viewModel = viewModel
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarItems(trailing: Button("Save") {
                saveNote()
            })
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }

    private func saveNote() {
        isLoading = true
        let updatedNote = Note(id: note.id, title: title, content: content, timestamp: note.timestamp, isSynced: note.isSynced)

        viewModel.update(note: updatedNote) { success in
            isLoading = false
            // Handle success or error
        }
    }
}
// Preview for EditNoteView
struct EditNoteView_Previews: PreviewProvider {
    static var previews: some View {
        let mockNote = MockNote.create() // Create a mock note
        let mockViewModel = MockNotesListViewModel() // Create a mock view model
        
        return EditNoteView(note: mockNote, viewModel: mockViewModel) // Pass mock data to the view
    }
}

class MockNotesListViewModel: NotesViewModel {
    override init() {
        super.init()
        // Add any mock data or behaviors if necessary
    }

    override func update(note: Note, completion: @escaping (Bool) -> Void) {
        // Simulate a successful update
        completion(true)
    }
}

struct MockNote {
    static func create() -> Note {
        return Note(id: UUID().uuidString, title: "Sample Title", content: "Sample Content", timestamp: Date(), isSynced: false)
    }
}
