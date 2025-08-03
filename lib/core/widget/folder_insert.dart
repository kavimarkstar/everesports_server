import 'package:everesports_server/theme/colors.dart';
import 'package:everesports_server/widget/common_ElevatedButton_icon.dart';
import 'package:flutter/material.dart';

Widget folderInsert(
  BuildContext context,
  String selectedFolderPath,
  bool isLoading,
  Function() selectFolder,
  Function() loadFolderContents,
  Function() insertFiles,
  Function() insertFolders,
  Function() autoRunRunBat,
) {
  return // Folder Selection Section
  Card(
    elevation: 4,
    color: AppColors.card,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder, color: AppColors.icon, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Selected Folder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedFolderPath,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: loadFolderContents,
                    tooltip: 'Refresh folder contents',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: commonElevatedButtonIcon(
                  context,
                  'Select Folder',
                  Icons.folder_open,
                  selectFolder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: commonElevatedButtonIcon(
                  context,
                  'Insert Files',
                  Icons.file_upload,
                  insertFiles,
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: commonElevatedButtonIcon(
                  context,
                  'Insert Folders',
                  Icons.folder_copy,
                  insertFolders,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: commonElevatedButtonIcon(
                  context,
                  'Auto Run run.bat',
                  Icons.auto_awesome,
                  autoRunRunBat,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
