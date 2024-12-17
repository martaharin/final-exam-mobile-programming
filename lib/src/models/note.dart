import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String timestamp;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  // Factory method to create a Note object from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? '', // Default to an empty string if 'id' is null
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] ??
          '', // Default to an empty string if 'timestamp' is null
    );
  }

  // Convert Note object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp,
    };
  }
}

class NoteService {
  final String baseUrl = 'http://localhost/noteapp';

  // Fetch all notes
  Future<List<Note>> getNotes() async {
    var url = Uri.parse('$baseUrl/read.php');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      data.map((note) => {print(Note.fromJson(note))});
      return data.map((note) => Note.fromJson(note)).toList();
    } else {
      throw Exception('Failed to load notes');
    }
  }

  Future<Note> getNotesByID(String id) async {
    var url = Uri.parse('$baseUrl/getByID.php');
    var response = await http.post(
      url,
      body: {
        'id': id,
      },
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body); // Parse JSON
      Note data = Note.fromJson(jsonData); // Convert to Note object
      return data;
    } else {
      throw Exception('Failed to load note');
    }
  }

  // Create a new note
  Future<bool> createNote(String title, String content) async {
    var url = Uri.parse('$baseUrl/create.php');
    var response = await http.post(
      url,
      body: {
        'title': title,
        'content': content,
        "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'];
    } else {
      print("Failed to create note");
      return false; // Return false in case of failure
    }
  }

  // Update an existing note
  Future<bool> updateNote(Note note) async {
    var url = Uri.parse('$baseUrl/update.php');
    var response = await http.post(
      url,
      body: {
        'id': note.id,
        'title': note.title,
        'content': note.content,
        "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['success'];
    } else {
      throw Exception('Failed to update note');
    }
  }

  // Delete a note
  Future<bool> deleteNote(String id) async {
    var url = Uri.parse('$baseUrl/delete.php');
    var response = await http.post(
      url,
      body: {
        'id': id,
      },
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to delete note");
      return false;
    }
  }
}
