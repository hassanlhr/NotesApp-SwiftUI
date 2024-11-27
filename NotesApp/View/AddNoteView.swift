//
//  AddNoteView.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 04/11/2024.
//

import SwiftUI

struct AddNoteView: View {
    
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var networkMonitor: NetworkMonitor

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = "Network Status"
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
            }
            .navigationTitle("Add Note")
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
        
        // Create the new note object
        let note = Note(id: UUID().uuidString, title: title, content: content, timestamp: Date(), isSynced: false)
        
        // Check for internet connectivity
        if networkMonitor.isConnectedToInternet() {
            // If connected to the internet, save the note to Firebase
            viewModel.notesManager.save(note: note) { success in
                isLoading = false
                if success {
                    // Refresh the notes list
                    viewModel.fetchNotes()  // Fetch updated notes
                    dismiss()
                } else {
                    
                    showAlert = true
                    
                    alertMessage = "Failed to save note to the cloud. Saving locally."
                    saveOffline(note: note)
                }
                
            }
        } else {
            // If not connected, save the note locally (Core Data)
            saveOffline(note: note)
        }
    }

    private func saveOffline(note: Note) {
        // Save the note offline using Core Data
        viewModel.notesManager.save(note: note) { success in
            isLoading = false
            if success {
                alertMessage = "Your note was saved locally."
                viewModel.fetchNotes()  // Fetch updated notes after saving locally
                showAlert = true
                dismiss()
            } else {
                alertMessage = "Failed to save note locally. Please try again."
                showAlert = true
            }
            
        }
    }

}

#Preview {
    AddNoteView(viewModel: NotesViewModel())
}

