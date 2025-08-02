import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class ProjectLauncher {
  static Future<Map<String, String?>> getLaunchArguments() async {
    try {
      // Get the launch arguments from the platform
      final List<String> args = Platform.executableArguments;

      // For development/testing - if no args, check if there's a project file in current directory
      String? projectPath;
      if (args.isEmpty) {
        final currentDir = Directory.current;
        final files = currentDir.listSync();
        for (var file in files) {
          if (file.path.toLowerCase().endsWith('.astro')) {
            projectPath = file.path;
            break;
          }
        }
      } else {
        // Parse the project path from arguments
        for (int i = 0; i < args.length; i++) {
          if (args[i] == '--project-path' && i + 1 < args.length) {
            projectPath = args[i + 1];
            break;
          }
        }
      }

      // If no project path found, return null values
      if (projectPath == null) {
        return {'projectPath': null, 'projectName': null, 'projectType': null};
      }

      // Get the project name from the path
      final projectName = path.basename(projectPath).replaceAll('.astro', '');

      String? projectType;
      // Read the project type from the .astro file
      if (projectPath.toLowerCase().endsWith('.astro')) {
        try {
          final file = File(projectPath);
          if (await file.exists()) {
            final content = await file.readAsString();
            // Parse JSON content
            final projectData = json.decode(content);
            projectType = projectData['type'] as String?;
          }
        } catch (e) {
          print('Error reading .astro file: $e');
        }
      }

      print('Launching project:');
      print('Path: $projectPath');
      print('Name: $projectName');
      print('Type: $projectType');

      return {
        'projectPath': projectPath,
        'projectName': projectName,
        'projectType': projectType,
      };
    } catch (e) {
      print('Error parsing launch arguments: $e');
      return {'projectPath': null, 'projectName': null, 'projectType': null};
    }
  }
}
