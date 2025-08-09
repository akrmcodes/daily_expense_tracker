// lib/widgets/folder_tile.dart
import 'package:flutter/material.dart';

class FolderTile extends StatelessWidget {
  final String title;
  final double? balance;     // رصيد المجلد (اختياري)
  final bool isSubfolder;    // لعرض "مجلد فرعي"
  final VoidCallback onTap;

  const FolderTile({
    super.key,
    required this.title,
    required this.onTap,
    this.balance,
    this.isSubfolder = false,
  });

  @override
  Widget build(BuildContext context) {
    final balanceColor = (balance ?? 0) >= 0 ? Colors.green : Colors.red;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.folder),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: isSubfolder ? const Text('مجلد فرعي') : null,
        trailing: balance != null
            ? Text(
                (balance!).toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: balanceColor,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
