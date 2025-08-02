import 'package:flutter/material.dart';
import 'website_editor_dashboard.dart';

class FileItemWidget extends StatelessWidget {
  final String filePath;
  final String fileName;
  final String fileType;
  final IconData fileIcon;

  const FileItemWidget({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => _handleDoubleTap(context),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(fileIcon, size: 40, color: _getIconColor()),
            const SizedBox(height: 8),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleDoubleTap(BuildContext context) {
    if (fileType.toLowerCase() == 'websites') {
      WebsiteEditorDashboard.handleFileOpen(context, filePath, fileName);
    }
    // Add other file type handlers here
  }

  Color _getIconColor() {
    switch (fileType.toLowerCase()) {
      case 'websites':
        return const Color(0xFF6E44FF);
      case 'image':
        return const Color(0xFF44A4FF);
      case 'document':
        return const Color(0xFFFF6E44);
      default:
        return Colors.grey;
    }
  }
}
