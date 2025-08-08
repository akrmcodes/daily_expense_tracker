import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../views/folder_details_screen.dart';

class FolderList extends StatelessWidget {
  final List<FolderModel> folders;
  final void Function(FolderModel folder)? onFolderTap;

  const FolderList({Key? key, required this.folders, this.onFolderTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "المجلدات",
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 10),
        ...folders.map((folder) {
          return Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                folder.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: folder.parentFolderId != null
                  ? const Text("مجلد فرعي")
                  : null,
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                if (onFolderTap != null) {
                  onFolderTap!(folder);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FolderDetailsScreen(folderId: folder.key as int),
                    ),
                  );
                }
              },
            ),
          );
        }).toList(),
      ],
    );
  }
}
