import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ImageNoteDialog extends StatefulWidget {
  final XFile imageFile;
  final Function(String?) onAnalyze;

  const ImageNoteDialog({
    super.key,
    required this.imageFile,
    required this.onAnalyze,
  });

  @override
  State<ImageNoteDialog> createState() => _ImageNoteDialogState();
}

class _ImageNoteDialogState extends State<ImageNoteDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a Note?'), // TODO: Localize
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(widget.imageFile.path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'e.g. "Low fat milk", "Half eaten"', // TODO: Localize
                border: OutlineInputBorder(),
                labelText: 'Note (Optional)', // TODO: Localize
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cancel
          child: Text(S.of(context).dialogCancelLabel),
        ),
        FilledButton(
          onPressed: () {
            widget.onAnalyze(_noteController.text);
          },
          child: const Text('Analyze'), // TODO: Localize
        ),
      ],
    );
  }
}
