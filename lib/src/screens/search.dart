import 'package:flutter/material.dart';
import 'package:notes_app_flutter/src/models/note.dart';
import 'package:notes_app_flutter/src/screens/view_note.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<Note> _allNotes = [];
  List<Note> _foundNotes = [];

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  void fetchNotes() async {
    try {
      List<Note> fetchedNotes = await NoteService().getNotes();
      setState(() {
        _allNotes = fetchedNotes;
        _foundNotes = _allNotes; // Initially, show all notes
      });
    } catch (e) {
      print('Error fetching notes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Notes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // Pop with a signal
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => _runFilter(value),
              decoration: const InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _foundNotes.isEmpty
                  ? const Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(fontSize: 24),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _foundNotes.length,
                      itemBuilder: (context, index) {
                        final note = _foundNotes[index];
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
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter notes based on search input
  void _runFilter(String enteredKeyword) {
    List<Note> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allNotes; // Show all notes when the search field is empty
    } else {
      results = _allNotes
          .where((note) =>
              note.title.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _foundNotes = results;
    });
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
      if (noteToDuplicate != null) {
        Note newNote = Note(
          id: '',
          title: "${noteToDuplicate.title} (Copy)",
          content: noteToDuplicate.content,
          timestamp: DateTime.now().toString(),
        );

        bool success = await NoteService().createNote(
          newNote.title,
          newNote.content,
        );
        if (success) {
          fetchNotes(); // Refresh the list of notes
        }
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
                onNoteDeleted(id);
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
