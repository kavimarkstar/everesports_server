import 'dart:io';

import 'package:everesports_server/theme/colors.dart';
import 'package:flutter/material.dart';

class FolderList extends StatefulWidget {
  final String selectedFolderPath;
  final List<String> breadcrumb;
  final String currentPath;
  final List<FileSystemEntity> folderContents;
  final bool isLoading;
  final Function() loadFolderContents;
  final Function(String) runBatFile;
  final Function(String, String) navigateToFolder;

  const FolderList({
    super.key,
    required this.selectedFolderPath,
    required this.breadcrumb,
    required this.currentPath,
    required this.folderContents,
    required this.isLoading,
    required this.loadFolderContents,
    required this.runBatFile,
    required this.navigateToFolder,
  });

  @override
  State<FolderList> createState() => _FolderListState();
}

class _FolderListState extends State<FolderList> {
  late List<String> breadcrumb;
  late String currentPath;

  @override
  void initState() {
    super.initState();
    breadcrumb = List.from(widget.breadcrumb);
    currentPath = widget.currentPath;
  }

  @override
  void didUpdateWidget(FolderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    breadcrumb = List.from(widget.breadcrumb);
    currentPath = widget.currentPath;
  }

  String getPathFromBreadcrumb() {
    if (breadcrumb.isEmpty) return '';
    return breadcrumb.join(Platform.pathSeparator);
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Breadcrumb Navigation
        if (breadcrumb.isNotEmpty) ...[
          Card(
            color: AppColors.card,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.navigation, color: AppColors.icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < breadcrumb.length; i++) ...[
                            if (i > 0) ...[
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.icon.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                            ],
                            GestureDetector(
                              onTap: () async {
                                if (i < breadcrumb.length - 1) {
                                  setState(() {
                                    breadcrumb = breadcrumb
                                        .take(i + 1)
                                        .toList();
                                    currentPath = getPathFromBreadcrumb();
                                  });
                                  await widget.loadFolderContents();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: i == breadcrumb.length - 1
                                      ? AppColors.icon.withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  breadcrumb[i],
                                  style: TextStyle(
                                    color: i == breadcrumb.length - 1
                                        ? AppColors.icon
                                        : AppColors.textSecondary,
                                    fontWeight: i == breadcrumb.length - 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Folder Contents Section
        if (currentPath.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.list, color: AppColors.icon, size: 20),
              const SizedBox(width: 8),
              Text(
                'Folder Contents (${widget.folderContents.length} items)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Card(
                  color: AppColors.card,
                  elevation: 2,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 1,
                    child: ListView.builder(
                      itemCount: widget.folderContents.length,
                      itemBuilder: (context, index) {
                        final item = widget.folderContents[index];
                        final isDirectory = item is Directory;
                        final stat = item.statSync();
                        final size = isDirectory
                            ? '--'
                            : formatFileSize(stat.size);
                        final modified = DateTime.fromMillisecondsSinceEpoch(
                          stat.modified.millisecondsSinceEpoch,
                        );

                        return ListTile(
                          leading: Icon(
                            isDirectory
                                ? Icons.folder
                                : Icons.insert_drive_file,
                            color: isDirectory ? AppColors.icon : mainColor,
                          ),
                          title: Text(
                            item.path.split(Platform.pathSeparator).last,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: item.path.toLowerCase().endsWith('run.bat')
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Size: $size • Modified: ${modified.toString().split('.')[0]}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isDirectory)
                                IconButton(
                                  icon: Icon(
                                    Icons.open_in_new,
                                    color: AppColors.icon,
                                  ),
                                  onPressed: () => widget.navigateToFolder(
                                    item.path,
                                    item.path
                                        .split(Platform.pathSeparator)
                                        .last,
                                  ),
                                  tooltip: 'Open folder',
                                ),
                              if (!isDirectory &&
                                  item.path.toLowerCase().endsWith('.bat'))
                                IconButton(
                                  icon:
                                      item.path.toLowerCase().endsWith(
                                        'run.bat',
                                      )
                                      ? Icon(
                                          Icons.auto_awesome,
                                          color: AppColors.accent,
                                        )
                                      : Icon(
                                          Icons.play_arrow,
                                          color: AppColors.icon,
                                        ),
                                  onPressed: () => widget.runBatFile(item.path),
                                  tooltip:
                                      item.path.toLowerCase().endsWith(
                                        'run.bat',
                                      )
                                      ? 'Auto run run.bat file'
                                      : 'Run .bat file',
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline,
                                  color: AppColors.icon,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        item.path
                                            .split(Platform.pathSeparator)
                                            .last,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Path: ${item.path}',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Type: ${isDirectory ? 'Directory' : 'File'}',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Size: $size',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Modified: ${modified.toString().split('.')[0]}',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(
                                            'Close',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ],
      ],
    );
  }
}
