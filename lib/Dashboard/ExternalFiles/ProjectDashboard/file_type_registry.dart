import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class FileTypeRegistry {
  static final FileTypeRegistry _instance = FileTypeRegistry._internal();
  factory FileTypeRegistry() => _instance;
  FileTypeRegistry._internal();

  final Map<String, FileTypeInfo> _fileTypes = {
    'website': FileTypeInfo(
      type: 'Website',
      icon: Icons.web,
      extensions: ['.astro'],
      defaultDirectory: 'Projects',
    ),
    'images': FileTypeInfo(
      type: 'Images',
      icon: Icons.image,
      extensions: ['.png', '.jpg', '.jpeg', '.gif'],
      defaultDirectory: 'Images',
    ),
    'documents': FileTypeInfo(
      type: 'Documents',
      icon: Icons.description,
      extensions: ['.doc', '.pdf', '.txt'],
      defaultDirectory: 'Documents',
    ),
  };

  Future<FileTypeInfo?> getFileTypeInfo(String filePath) async {
    // First check the .astro file content
    if (filePath.toLowerCase().endsWith('.astro')) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final projectData = json.decode(content);
          final type = projectData['type'] as String?;
          if (type != null) {
            return _fileTypes[type.toLowerCase()];
          }
        }
      } catch (e) {
        print('Error reading .astro file: $e');
      }
    }

    // Then check by extension
    final extension = filePath.toLowerCase().split('.').last;
    for (var fileType in _fileTypes.values) {
      if (fileType.extensions.contains('.$extension')) {
        return fileType;
      }
    }

    // Finally check by directory
    for (var fileType in _fileTypes.values) {
      if (filePath.contains('/${fileType.defaultDirectory}/')) {
        return fileType;
      }
    }

    return null;
  }

  IconData getFileIcon(String filePath) {
    return _fileTypes['website']?.icon ?? Icons.insert_drive_file;
  }

  String getFileType(String filePath) {
    return _fileTypes['website']?.type ?? 'Unknown';
  }

  Future<bool> isWebsiteFile(String filePath) async {
    try {
      if (filePath.toLowerCase().endsWith('.astro')) {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final projectData = json.decode(content);
          return projectData['type']?.toString().toLowerCase() == 'website';
        }
      }
    } catch (e) {
      print('Error checking website file: $e');
    }
    return false;
  }
}

class FileTypeInfo {
  final String type;
  final IconData icon;
  final List<String> extensions;
  final String defaultDirectory;

  FileTypeInfo({
    required this.type,
    required this.icon,
    required this.extensions,
    required this.defaultDirectory,
  });
}
