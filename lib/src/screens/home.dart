import 'package:flutter/material.dart';
import 'package:notes_app_flutter/src/models/note.dart';
import 'package:notes_app_flutter/src/screens/create_note.dart';
import 'package:notes_app_flutter/src/screens/search.dart';
import 'package:notes_app_flutter/src/screens/view_note.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<Note>> notes;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  void fetchNotes() async {
    List<Note> fetchedNotes = await NoteService().getNotes();
    setState(() {
      notes = Future.value(fetchedNotes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Search(), // Open Search page
                  ),
                );
                fetchNotes(); // Refetch notes when returning from Search
              },
              icon: const Icon(Icons.search),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Note>>(
                future: notes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No notes available.'));
                  } else {
                    List<Note> notesList = snapshot.data!;
                    return Expanded(
                        child: ListView.builder(
                      itemCount: notesList.length,
                      itemBuilder: (context, index) {
                        final note = notesList[index];
                        return Card(
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ViewNote(
                                      note: note,
                                      onNoteUpdated: onNoteUpdated)));
                            },
                            title: Text(note.title),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _confirmDelete(context, note.id);
                                } else if (value == 'duplicate') {
                                  onNoteDuplicated(note.id);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'duplicate',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.copy, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Duplicate'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ));
                  }
                })
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CreateNote(onNewNoteCreated: onNewNoteCreated),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void onNewNoteCreated(Note note) async {
    try {
      bool success = await NoteService().createNote(note.title, note.content);
      if (success) {
        fetchNotes(); // Refresh the list of notes
      }
    } catch (e) {
      print('Error creating note: $e');
    }
  }

  void onNoteUpdated(Note note) async {
    try {
      bool success = await NoteService().updateNote(note);
      if (success) {
        fetchNotes(); // Refresh the list of notes
      }
    } catch (e) {
      print('Error updating note: $e');
    }
  }

  void onNoteDeleted(String id) async {
    try {
      bool success = await NoteService().deleteNote(id);
      if (success) {
        fetchNotes(); // Refresh the list of notes
      }
    } catch (e) {
      print('Error deleting note: $e');
    }
  }

  void onNoteDuplicated(String id) async {
    try {
      Note? noteToDuplicate = await NoteService().getNotesByID(id);
      Note newNote = Note(
        id: '',
        title: "${noteToDuplicate?.title} (Copy)",
        content: "${noteToDuplicate?.content}",
        timestamp: "",
      );

      bool success = await NoteService().createNote(
        newNote.title,
        newNote.content,
      );
      if (success) {
        fetchNotes(); // Refresh the list of notes
      }
    } catch (e) {
      print('Error duplicating note: $e');
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this note?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                onNoteDeleted(id); // Wait for deletion to complete
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
