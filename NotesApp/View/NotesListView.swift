//
//  NotesListView.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 04/11/2024.
//

import SwiftUI

struct NotesListView: View {
    
    @StateObject private var viewModel = NotesViewModel()
    @State private var showAddNoteView = false
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        NavigationView {
            if sizeClass == .regular {
                // iPad or larger screens - Use a two-column layout (split view)
                HStack {
                    // Left side: List of notes
                    List {
                        ForEach(viewModel.notes) { note in
                            NavigationLink(destination: EditNoteView(note: note, viewModel: viewModel)) {
                                VStack(alignment: .leading) {
                                    Text(note.title)
                                        .font(.headline)
                                    Text(note.content)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .onDelete(perform: deleteNote) // Delete action for iPad
                    }
                    .frame(minWidth: 300) // Ensure list takes a minimum width

                    // Right side: Placeholder or Note details (will show details when a note is selected)
                    Text("Select a Note")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
                .navigationTitle("Notes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showAddNoteView.toggle() }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showAddNoteView) {
                    AddNoteView(viewModel: viewModel)
                }
            } else {
                // iPhone or smaller screens - Stacked view layout
                VStack {
                    if viewModel.isLoading {
                        ProgressView("Loading notes...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        List {
                            ForEach(viewModel.notes) { note in
                                NavigationLink(destination: EditNoteView(note: note, viewModel: viewModel)) {
                                    VStack(alignment: .leading) {
                                        Text(note.title)
                                            .font(.headline)
                                        Text(note.content)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .onDelete(perform: deleteNote) // Delete action for iPhone
                        }
                    }
                }
                .onAppear {
                    viewModel.fetchNotes()  // Ensure it fetches when the view appears
                }
                .navigationTitle("Notes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showAddNoteView.toggle() }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showAddNoteView) {
                    AddNoteView(viewModel: viewModel)
                }
            }
        }
    }
    
    private func deleteNote(at offsets: IndexSet) {
        // Delete the selected note from the viewModel
        offsets.map { viewModel.notes[$0].id }.forEach { (id: String) in
            viewModel.delete(noteId: id) { success in
                if success {
                    // Handle successful deletion (optional)
                } else {
                    // Handle failure (optional)
                }
            }
        }
    }
}

//struct NotesListView: View {
//    
//    @StateObject private var viewModel = NotesViewModel()
//    @State private var showAddNoteView = false
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                if viewModel.isLoading {
//                    ProgressView("Loading notes...")
//                        .progressViewStyle(CircularProgressViewStyle())
//                        .padding()
//                } else {
//                    List {
//                        ForEach(viewModel.notes) { note in
//                            NavigationLink(destination: EditNoteView(note: note, viewModel: viewModel)) {
//                                VStack(alignment: .leading) {
//                                    Text(note.title)
//                                        .font(.headline)
//                                    Text(note.content)
//                                        .font(.subheadline)
//                                        .lineLimit(1)
//                                }
//                            }
//                        }
//                        .onDelete(perform: deleteNote)
//                    }
//                }
//            }
//            .onAppear {
//                viewModel.fetchNotes()  // Ensure it fetches when the view appears
//            }
//            .navigationTitle("Notes")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: { showAddNoteView.toggle() }) {
//                        Image(systemName: "plus")
//                    }
//                }
//            }
//            .sheet(isPresented: $showAddNoteView) {
//                AddNoteView(viewModel: viewModel)
//            }
//        }
//    }
//        
//    private func deleteNote(at offsets: IndexSet) {
//        offsets.map { viewModel.notes[$0].id }.forEach { (id: String) in
//            viewModel.delete(noteId: id) { success in
//                if success {
//                    // Handle successful deletion (optional)
//                } else {
//                    // Handle failure (optional)
//                }
//            }
//        }
//    }
//}

#Preview {
    NotesListView()
}
