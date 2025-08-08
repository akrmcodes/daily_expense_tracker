import 'package:hive/hive.dart';

part 'folder_model.g.dart';

@HiveType(typeId: 1)
class FolderModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int? parentFolderId;

  FolderModel({required this.name, this.parentFolderId});
}
