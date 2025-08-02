import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../utils/file_icon_manager.dart';
import 'website_editor_dashboard.dart';

class CreateProjectDialog extends StatefulWidget {
  final String defaultPath;

  const CreateProjectDialog({
    super.key,
    required this.defaultPath,
  });

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'Design';
  late String _projectPath;
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _projectTypes = [
    {
      'name': 'Design',
      'icon': Icons.brush_outlined,
      'color': const Color(0xFF6E44FF),
      'description': 'Create logos, UI designs, mockups and more',
    },
    {
      'name': '3D & Animation',
      'icon': Icons.animation,
      'color': const Color(0xFF44A4FF),
      'description': '3D models and animated content',
    },
    {
      'name': 'Video Editing',
      'icon': Icons.videocam_outlined,
      'color': const Color(0xFFFF6E44),
      'description': 'Edit and produce video content',
    },
    {
      'name': 'Website',
      'icon': Icons.web,
      'color': const Color(0xFF44FFBA),
      'description': 'Build responsive websites and web apps',
    },
    {
      'name': 'Photo Editor',
      'icon': Icons.image_outlined,
      'color': const Color(0xFFFF44A4),
      'description': 'Edit and enhance your photos',
    },
  ];

  @override
  void initState() {
    super.initState();
    _projectPath = widget.defaultPath;
  }

  Future<void> _selectPath() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && mounted) {
        setState(() {
          _projectPath = selectedDirectory;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting directory: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createProject() {
    if (_formKey.currentState!.validate()) {
      // Create .astro file directly in the selected path
      final astroFile = File('$_projectPath/${_nameController.text}.astro');

      if (!astroFile.existsSync()) {
        // Create JSON data with project type and icon path
        final projectData = {
          'type': _selectedType,
          'lastEdited': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Write JSON data to .astro file
        astroFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(projectData),
        );

        // Set the file icon using the application's executable
        final String exePath = Platform.resolvedExecutable;
        FileIconManager.setAstroFileIcon(astroFile.path, exePath);

        // Add project to list and close dialog
        final newProject = {
          'title': _nameController.text,
          'type': _selectedType,
          'path': astroFile.path,
          'createdAt': DateTime.now(),
        };

        // If it's a website project, open the website editor
        if (_selectedType == 'Website') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => WebsiteEditorDashboard(
                projectPath: astroFile.path,
                projectName: _nameController.text,
              ),
            ),
          );
        } else {
          // Return the new project data to be added to _projects list
          Navigator.of(context).pop(newProject);
        }
      } else {
        // Show error - file already exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A project with this name already exists in this location',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF1A1A1A),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF6E44FF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Create New Project',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Project Type Selection
            const Text(
              'SELECT PROJECT TYPE',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _projectTypes.length,
                itemBuilder: (context, index) {
                  final type = _projectTypes[index];
                  final isSelected = _selectedType == type['name'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = type['name'];
                      });
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? type['color'].withOpacity(0.2)
                            : const Color(0xFF2A2A2A),
                        border: Border.all(
                          color:
                              isSelected ? type['color'] : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(type['icon'], color: type['color'], size: 32),
                          const SizedBox(height: 12),
                          Text(
                            type['name'],
                            style: TextStyle(
                              color: isSelected ? type['color'] : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            // Selected type description
            Text(
              _projectTypes.firstWhere(
                (type) => type['name'] == _selectedType,
              )['description'],
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),

            const SizedBox(height: 24),
            // Project Details Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROJECT DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Project Name
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintText: 'Enter a name for your project',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.edit, color: Colors.grey),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a project name';
                      }
                      if (value.length < 3) {
                        return 'Project name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Project Location
                  const Text(
                    'PROJECT LOCATION',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _projectPath,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _selectPath,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E44FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Create Project'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
