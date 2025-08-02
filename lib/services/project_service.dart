import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import '../Dashboard/ProjectsDashboard_page.dart';

class ProjectService {
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  static Future<String> getDefaultProjectsDirectory() async {
    // Get user's Documents folder on Windows
    final userHome = Platform.environment['USERPROFILE']!;
    final documentsDir = path.join(userHome, 'Documents');
    final projectsDir = path.join(documentsDir, 'AstraVision Projects');

    // Create the directory if it doesn't exist
    final directory = Directory(projectsDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return projectsDir;
  }

  Future<List<Project>> loadProjects() async {
    List<Project> projects = [];
    try {
      final projectsDirectory = await getDefaultProjectsDirectory();
      final directory = Directory(projectsDirectory);
      if (!await directory.exists()) {
        return projects;
      }

      await for (var entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.astro')) {
          try {
            final content = await entity.readAsString();
            final projectData = json.decode(content);

            projects.add(
              Project(
                title: path.basenameWithoutExtension(entity.path),
                thumbnail: 'assets/Logo.png',
                lastEdited: DateTime.parse(
                  projectData['lastEdited'] ?? DateTime.now().toIso8601String(),
                ),
                type: _getProjectTypeFromString(
                  projectData['type'] ?? 'Design',
                ),
                path: entity.path,
              ),
            );
          } catch (e) {
            print('Error loading project ${entity.path}: $e');
          }
        }
      }

      // Sort projects by last edited date
      projects.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
    } catch (e) {
      print('Error loading projects: $e');
    }
    return projects;
  }

  ProjectType _getProjectTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'design':
        return ProjectType.design;
      case '3d & animation':
      case '3d':
        return ProjectType.threeD;
      case 'video editing':
      case 'video':
        return ProjectType.video;
      case 'animation':
        return ProjectType.animation;
      default:
        return ProjectType.design;
    }
  }
}
