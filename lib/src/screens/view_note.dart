import 'dart:convert';
import 'dart:io';

import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes_app_flutter/src/models/note.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewNote extends StatefulWidget {
  const ViewNote({super.key, required this.onNoteUpdated, required this.note});

  final Function(Note) onNoteUpdated;
  final Note note;

  @override
  State<ViewNote> createState() => _ViewNoteState();
}

class _ViewNoteState extends State<ViewNote> {
  final titleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<EditorState> _editorKey = GlobalKey();
  FleatherController? _controller;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
    _initController();
    titleController.text = widget.note.title;
  }

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
  }

  // Future<void> _pickImage() async {
  //   final picker = ImagePicker();
  //   final image = await picker.pickImage(source: ImageSource.gallery);
  //   if (image != null && _controller != null) {
  //     final selection = _controller!.selection;
  //     _controller!.replaceText(
  //       selection.baseOffset,
  //       selection.extentOffset - selection.baseOffset,
  //       EmbeddableObject('image', inline: false, data: {
  //         'source_type': kIsWeb ? 'url' : 'file',
  //         'source': image.path,
  //       }),
  //     );
  //     _controller!.replaceText(
  //       selection.baseOffset + 1,
  //       0,
  //       '\n',
  //       selection: TextSelection.collapsed(offset: selection.baseOffset + 2),
  //     );
  //   }
  // }

  // Future<void> _pickImage() async {
  //   final picker = ImagePicker();
  //   final image = await picker.pickImage(source: ImageSource.gallery);
  //   if (image != null && _controller != null) {
  //     final selection = _controller!.selection;
  //     final imageBytes = await File(image.path).readAsBytes();
  //     final base64Image = base64Encode(imageBytes); // Convert image to base64

  //     _controller!.replaceText(
  //       selection.baseOffset,
  //       selection.extentOffset - selection.baseOffset,
  //       EmbeddableObject('image', inline: false, data: {
  //         'source_type': 'base64',
  //         'source': base64Image, // Store the base64 string
  //       }),
  //     );
  //     _controller!.replaceText(
  //       selection.baseOffset + 1,
  //       0,
  //       '\n',
  //       selection: TextSelection.collapsed(offset: selection.baseOffset + 2),
  //     );
  //   }
  // }

  Future<void> _initController() async {
    try {
      String sanitizedContent =
          widget.note.content.replaceAll(RegExp(r'\\[bfnrt/"]'), '');
      final List<dynamic> deltaList = jsonDecode(sanitizedContent);

      final delta = Delta.fromJson(deltaList);

      if (delta.isNotEmpty && !delta.last.data.toString().endsWith('\n')) {
        deltaList.add({"insert": "\n"});
      }

      final updatedDelta = Delta.fromJson(deltaList);

      final doc = ParchmentDocument.fromDelta(updatedDelta);

      _controller = FleatherController(document: doc);
    } catch (err, st) {
      print('Error initializing the controller: $err\n$st');
      _controller = FleatherController();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: const Text('Create Note')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String jsonData = jsonEncode(
              _controller?.document.toDelta().toJson()); // Save as JSON

          final note = Note(
            id: widget.note.id,
            title: titleController.text,
            content: jsonData, // Use the JSON-encoded content
            timestamp: "", // Use the formatted date and time
          );
          widget.onNoteUpdated(note); // Pass back the new note
          Navigator.of(context).pop(); // Close the screen
        },
        child: const Icon(Icons.save),
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TextFormField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 28),
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: "Title"),
                ),
                FleatherToolbar(
                  editorKey: _editorKey,
                  children: [
                    ToggleStyleButton(
                      attribute: ParchmentAttribute.bold,
                      icon: Icons.format_bold,
                      controller: _controller!,
                    ),
                    ToggleStyleButton(
                      attribute: ParchmentAttribute.italic,
                      icon: Icons.format_italic,
                      controller: _controller!,
                    ),
                    ToggleStyleButton(
                      attribute: ParchmentAttribute.underline,
                      icon: Icons.format_underline,
                      controller: _controller!,
                    ),
                    ToggleStyleButton(
                      attribute: ParchmentAttribute.block.bulletList,
                      controller: _controller!,
                      icon: Icons.format_list_bulleted,
                    ),
                    IndentationButton(controller: _controller!),
                    IndentationButton(
                        controller: _controller!, increase: false),
                    UndoRedoButton.undo(controller: _controller!),
                    UndoRedoButton.redo(controller: _controller!),
                  ],
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                Expanded(
                  child: FleatherEditor(
                    controller: _controller!,
                    focusNode: _focusNode,
                    editorKey: _editorKey,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    onLaunchUrl: _launchUrl,
                    maxContentWidth: 800,
                    embedBuilder: _embedBuilder,
                  ),
                ),
              ],
            ),
    );
  }

  // Widget _embedBuilder(BuildContext context, EmbedNode node) {
  //   if (node.value.type == 'image') {
  //     final sourceType = node.value.data['source_type'];
  //     ImageProvider? image;
  //     if (sourceType == 'assets') {
  //       image = AssetImage(node.value.data['source']);
  //     } else if (sourceType == 'file') {
  //       image = FileImage(File(node.value.data['source']));
  //     } else if (sourceType == 'url') {
  //       image = NetworkImage(node.value.data['source']);
  //     }
  //     if (image != null) {
  //       return Padding(
  //         padding: const EdgeInsets.only(left: 4, right: 2, top: 2, bottom: 2),
  //         child: image != null
  //             ? Expanded(
  //                 child: Image(
  //                   image: image,
  //                   fit: BoxFit.contain,
  //                 ),
  //               )
  //             : SizedBox.shrink(),
  //       );
  //     }
  //   }
  //   return defaultFleatherEmbedBuilder(context, node);
  // }

  Widget _embedBuilder(BuildContext context, EmbedNode node) {
    if (node.value.type == 'image') {
      final sourceType = node.value.data['source_type'];
      ImageProvider? image;

      if (sourceType == 'base64') {
        final base64String = node.value.data['source'];
        final imageBytes =
            base64Decode(base64String); // Decode the base64 string
        image = MemoryImage(imageBytes); // Use MemoryImage to display the image
      } else if (sourceType == 'assets') {
        image = AssetImage(node.value.data['source']);
      } else if (sourceType == 'file') {
        image = FileImage(File(node.value.data['source']));
      } else if (sourceType == 'url') {
        image = NetworkImage(node.value.data['source']);
      }

      if (image != null) {
        return Padding(
          padding: const EdgeInsets.only(left: 4, right: 2, top: 2, bottom: 2),
          child: Expanded(
            child: Image(
              image: image,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
    }
    return defaultFleatherEmbedBuilder(context, node);
  }

  void _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    }
  }
}
