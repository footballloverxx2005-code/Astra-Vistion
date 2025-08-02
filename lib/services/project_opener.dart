import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../Dashboard/ExternalFiles/ProjectDashboard/website_editor_dashboard.dart';

class ProjectOpener {
  static Future<void> openProject(BuildContext context, String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('Project file not found');
      }

      // Read and parse the .astro file
      final content = await file.readAsString();
      final projectData = json.decode(content);

      // Get the project name from the file path
      final projectName = filePath
          .split(Platform.pathSeparator)
          .last
          .replaceAll('.astro', '');

      // Open appropriate editor based on project type
      if (projectData['type'] == 'Website') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => WebsiteEditorDashboard(
                  projectPath: filePath,
                  projectName: projectName,
                ),
          ),
        );
      }
      // Add other project types here as needed
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening project: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
