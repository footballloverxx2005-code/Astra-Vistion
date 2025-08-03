import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'file_type_registry.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart'; // Add this import for keyboard events
import '../../../Dashboard/HomeDashboard_page.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ScreenSettings {
  double width;
  double height;
  double minWidth;
  EdgeInsets padding;
  EdgeInsets margin;
  Color backgroundColor;
  String scrollBehavior;
  String clipping;

  ScreenSettings({
    this.width = 1920,
    this.height = 1080,
    this.minWidth = 0,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.backgroundColor = Colors.white,
    this.scrollBehavior = 'Scroll with page',
    this.clipping = 'No clipping',
  });
}

class WebsiteEditorDashboard extends StatefulWidget {
  final String projectPath;
  final String projectName;

  const WebsiteEditorDashboard({
    super.key,
    required this.projectPath,
    required this.projectName,
  });

  static Future<void> handleFileOpen(
    BuildContext context,
    String filePath,
    String fileName,
  ) async {
    final registry = FileTypeRegistry();
    if (await registry.isWebsiteFile(filePath)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebsiteEditorDashboard(
            projectPath: filePath,
            projectName: fileName,
          ),
        ),
      );
    }
  }

  @override
  State<WebsiteEditorDashboard> createState() =>
      _WebsiteEditorDashboardPageState();
}

class _WebsiteEditorDashboardPageState extends State<WebsiteEditorDashboard> {
  Map<String, dynamic> _projectData = {
    'type': 'Website',
    'lastEdited': DateTime.now().toString(),
    'createdAt': DateTime.now().toString(),
  };

  // Add state for zoom control
  double _currentZoom = 1.0;
  final double _minZoom = 0.1;
  final double _maxZoom = 5.0;
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  int _selectedIndex = 0;
  int _selectedToolbarIndex = 0;
  List<Map<String, dynamic>> _interactions = [];
  int? _selectedInteractionIndex;
  bool _showInteractionDetails = false;
  double _timerDelay = 0;
  bool _runOnce = false;

  // Add state for folder expansion
  Map<String, bool> _expandedFolders = {
    'Main': true,
    'Assets': false,
    'Screen': true, // Add Screen folder and set it to expanded by default
  };

  // Add state for selected folder
  String _selectedFolder = 'Main';

  // Add state for cursor type
  MouseCursor _currentCursor = SystemMouseCursors.basic;
  bool _isResizing = false;
  bool _isMoving = false;
  bool _isRotating = false;
  bool _isCornerHovered = false;
  bool _isRotateCornerHovered = false;
  bool _canExpand = true; // Add state for expand functionality

  // Add state for Vev folder and subfolders
  Map<String, bool> _vevSubfolders = {
    'Navigation': false,
    'Layout': false,
    'Image': false,
    'Video': false,
    'Text': false,
    'Form': false,
    'Data': false,
    'Embed': false,
    'Social': false,
    'Audio': false,
  };
  bool _vevFolderExpanded = true;

  // Add state for screen element selection
  bool _isScreenSelected = false;

  // Add state for right sidebar tab selection
  String _selectedRightTab = 'Style';

  // Add state for selected toolbar tool
  int _selectedToolIndex = 0;

  // Add screen settings to state
  final ScreenSettings _screenSettings = ScreenSettings();

  // Add state for color picker and swatches
  bool _showColorPicker = false;
  List<Color> _swatches = [
    Colors.white,
    Colors.black,
    Colors.grey,
    const Color(0xFF4A4A4A),
    const Color(0xFF00A3FF),
  ];
  TextEditingController _hexController = TextEditingController();
  bool _isValidHex = true;

  // Burger menu color picker state
  bool _showBurgerMenuColorPicker = false;
  TextEditingController _burgerMenuHexController = TextEditingController();
  bool _isBurgerMenuHexValid = true;

  // Container color picker state
  bool _showContainerColorPicker = false;
  TextEditingController _containerHexController = TextEditingController();
  bool _isContainerHexValid = true;

  // Add state for hovered element preview
  bool _showPreview = false;
  String _hoveredElement = '';
  Offset _hoveredElementPosition = Offset.zero;

  // Add state for dragging components
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

  // Add state for components added to the screen
  List<Map<String, dynamic>> _screenComponents = [];

  // Add ScrollController
  final ScrollController _navigationScrollController = ScrollController();

  // Add ScrollController for component library
  final ScrollController _componentLibraryController = ScrollController();

  // Add ScrollController for right sidebar
  final ScrollController _rightSidebarController = ScrollController();

  // Add state for container drawing
  bool _isDrawingContainer = false;
  Offset? _containerStartPoint;
  Offset? _containerEndPoint;

  // Add state for guidelines and position indicators
  bool _showGuidelines = false;
  double? _distanceFromTop;
  double? _distanceFromLeft;
  double? _distanceFromRight;
  double? _distanceFromBottom;
  bool _isHorizontalCentered = false;
  bool _isVerticalCentered = false;
  Map<String, dynamic>? _movingComponent;

  // Add state for container border radius
  Map<String, double> _containerBorderRadius = {
    'topLeft': 4.0,
    'topRight': 4.0,
    'bottomLeft': 4.0,
    'bottomRight': 4.0,
  };

  // Add state for box shadow
  bool _showBoxShadowControls = false;

  // Add state for selected component interactions
  List<Map<String, dynamic>>? _selectedComponentInteractions;

  // Add state for mode switching
  bool _isAnimationMode = false;

  // Add a list to hold created animations
  List<Map<String, dynamic>> _animations = [];

  // Add a TextEditingController for the animation name dialog
  final TextEditingController _animationNameController =
      TextEditingController();

  // 1. Add state for selected animation
  int? _selectedAnimationIndex;

  // 1. Add state for selected frame and per-animation keyframes
  int _selectedFrame = 0;
  
  // Recording state for keyframes
  bool _isRecording = false;
  
  // Animation playback state
  bool _isPlaying = false;
  Timer? _animationTimer;
  int _currentPlaybackFrame = 0;
  double _animationSpeed = 1.0; // Speed multiplier (1.0 = normal speed)
  
  // Helper method to generate unique IDs for elements
  String _generateElementId(String type) {
    return '${type}_${DateTime.now().millisecondsSinceEpoch}_${_screenComponents.length}';
  }
  
  // Show context menu for animations
  void _showAnimationContextMenu(BuildContext context, Offset position, int animationIndex) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 18),
              SizedBox(width: 12),
              Expanded(child: Text('Rename', style: TextStyle(color: Colors.white))),
              Text('F2', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 18),
              SizedBox(width: 12),
              Expanded(child: Text('Delete', style: TextStyle(color: Colors.red))),
              Text('Del', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ],
      color: Color(0xFF2D2D2D),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ).then((value) {
      if (value == 'rename') {
        _renameAnimation(animationIndex);
      } else if (value == 'delete') {
        _deleteAnimationWithConfirmation(animationIndex);
      }
    });
  }
  
  // Show context menu for elements
  void _showElementContextMenu(BuildContext context, Offset position, int elementIndex) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 18),
              SizedBox(width: 12),
              Expanded(child: Text('Rename', style: TextStyle(color: Colors.white))),
              Text('F2', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 18),
              SizedBox(width: 12),
              Expanded(child: Text('Delete', style: TextStyle(color: Colors.red))),
              Text('Del', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ],
      color: Color(0xFF2D2D2D),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ).then((value) {
      if (value == 'rename') {
        _renameElement(elementIndex);
      } else if (value == 'delete') {
        _deleteElementWithConfirmation(elementIndex);
      }
        });
  }
  
  // Rename animation dialog
  void _renameAnimation(int animationIndex) {
    if (animationIndex < 0 || animationIndex >= _animations.length) return;
    
    final currentName = _animations[animationIndex]['name'] ?? 'Animation';
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF252525),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text('Rename Animation', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Animation Name',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _animations[animationIndex]['name'] = controller.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Animation renamed to "${controller.text.trim()}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('Rename', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  
  // Delete animation with confirmation
  void _deleteAnimationWithConfirmation(int animationIndex) {
    if (animationIndex < 0 || animationIndex >= _animations.length) return;
    
    final animationName = _animations[animationIndex]['name'] ?? 'Animation';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF252525),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('Delete Animation', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete the animation "$animationName"?',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _animations.removeAt(animationIndex);
                // Reset selected animation if it was deleted
                if (_selectedAnimationIndex == animationIndex) {
                  _selectedAnimationIndex = null;
                } else if (_selectedAnimationIndex != null && _selectedAnimationIndex! > animationIndex) {
                  _selectedAnimationIndex = _selectedAnimationIndex! - 1;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Animation "$animationName" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Rename element dialog
  void _renameElement(int elementIndex) {
    if (elementIndex < 0 || elementIndex >= _screenComponents.length) return;
    
    final currentName = _screenComponents[elementIndex]['name'] ?? 'Element';
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF252525),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text('Rename Element', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Element Name',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _screenComponents[elementIndex]['name'] = controller.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Element renamed to "${controller.text.trim()}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('Rename', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  
  // Delete element with confirmation
  void _deleteElementWithConfirmation(int elementIndex) {
    if (elementIndex < 0 || elementIndex >= _screenComponents.length) return;
    
    final elementName = _screenComponents[elementIndex]['name'] ?? 'Element';
    final elementId = _screenComponents[elementIndex]['id'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF252525),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('Delete Element', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete the element "$elementName"?',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'This will also remove it from all animations.',
              style: TextStyle(color: Colors.orange.withOpacity(0.8), fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // Remove element from screen components
                _screenComponents.removeAt(elementIndex);
                
                // Remove element from all animations
                for (final animation in _animations) {
                  final frameData = animation['frame_data'] as Map<String, dynamic>?;
                  if (frameData != null) {
                    for (final frameKey in frameData.keys.toList()) {
                      final frame = frameData[frameKey] as Map<String, dynamic>?;
                      if (frame != null) {
                        frame.remove(elementId);
                      }
                    }
                  }
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Element "$elementName" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  @override
  void initState() {
    super.initState();
    _loadProjectData();
    _hexController.addListener(_updateColorFromHex);
    _initializeSampleElements();
  }

  void _initializeSampleElements() {
    // Add sample elements for testing keyframe functionality
    _screenComponents.addAll([
      {
        'id': _generateElementId('container'),
        'type': 'container',
        'name': 'Test Container',
        'position': Offset(100, 100),
        'width': 120.0,
        'height': 80.0,
        'backgroundColor': Colors.blue,
        'selected': false,
        'rotation': 0.0,
        'scale': 1.0,
        'opacity': 1.0,
      },
      {
        'id': _generateElementId('text'),
        'type': 'text',
        'name': 'Test Text',
        'position': Offset(200, 150),
        'text': 'Hello Animation',
        'fontSize': 24.0,
        'color': Colors.white,
        'selected': false,
        'rotation': 0.0,
        'scale': 1.0,
        'opacity': 1.0,
      },
    ]);
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _navigationScrollController.dispose();
    _componentLibraryController.dispose();
    _rightSidebarController.dispose();
    _hexController.dispose();
    _burgerMenuHexController.dispose();
    _containerHexController.dispose();
    _transformationController.dispose();
    _animationNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    try {
      final file = File(widget.projectPath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() {
          _projectData = json.decode(contents);
        });
      }
    } catch (e) {
      print('Error loading project data: $e');
    }
  }

  Future<void> _saveProjectData() async {
    try {
      final file = File(widget.projectPath);
      await file.writeAsString(json.encode(_projectData));
    } catch (e) {
      print('Error saving project data: $e');
    }
  }

  // Add method to update screen settings
  void _updateScreenSettings({
    double? width,
    double? height,
    double? minWidth,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    String? scrollBehavior,
    String? clipping,
  }) {
    setState(() {
      if (width != null) _screenSettings.width = width;
      if (height != null) _screenSettings.height = height;
      if (minWidth != null) _screenSettings.minWidth = minWidth;
      if (padding != null) _screenSettings.padding = padding;
      if (margin != null) _screenSettings.margin = margin;
      if (backgroundColor != null)
        _screenSettings.backgroundColor = backgroundColor;
      if (scrollBehavior != null)
        _screenSettings.scrollBehavior = scrollBehavior;
      if (clipping != null) _screenSettings.clipping = clipping;
    });
  }

  void _updateColorFromHex() {
    String hexText = _hexController.text.trim();
    if (hexText.startsWith('#')) {
      hexText = hexText.substring(1);
    }

    if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hexText)) {
      setState(() {
        _isValidHex = true;
        _screenSettings.backgroundColor =
            Color(int.parse('FF$hexText', radix: 16));
      });
    } else {
      setState(() {
        _isValidHex = false;
      });
    }
  }

  void _updateHexFromColor(Color color) {
    final hex = '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
    if (_hexController.text != hex) {
      _hexController.text = hex;
    }
  }

  void _updateBurgerMenuColorFromHex(Map<String, dynamic> component) {
    String hexText = _burgerMenuHexController.text.trim();
    if (hexText.startsWith('#')) {
      hexText = hexText.substring(1);
    }

    if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hexText)) {
      setState(() {
        _isBurgerMenuHexValid = true;
        component['menuColor'] = Color(int.parse('FF$hexText', radix: 16));
      });
    } else {
      setState(() {
        _isBurgerMenuHexValid = false;
      });
    }
  }

  void _updateBurgerMenuHexFromColor(Color color) {
    final hex = '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
    if (_burgerMenuHexController.text != hex) {
      _burgerMenuHexController.text = hex;
    }
  }

  // Helper method to execute component interactions
  void _executeComponentInteraction(
      Map<String, dynamic> component, String interactionType) {
    if (component['interactions'] == null) return;

    // Find matching interactions for this type
    final matchingInteractions = (component['interactions'] as List<dynamic>)
        .where((interaction) => interaction['type'] == interactionType)
        .toList();

    if (matchingInteractions.isEmpty) return;

    // For now, just log that the interaction was triggered
    // In a real implementation, this would perform the actual action
    print('Executing $interactionType interaction on ${component['type']}');

    // For each matching interaction, execute its actions
    for (var interaction in matchingInteractions) {
      if (interaction['actions'] != null) {
        for (var action in interaction['actions']) {
          print('Executing action: ${action['type']}');

          // Handle different action types
          switch (action['type']) {
            case 'node':
              // This would perform the Node action
              print('Performing Node action');
              break;
            // Add other action types as needed
            default:
              print('Unknown action type: ${action['type']}');
          }
        }
      }
    }
  }

  void _updateContainerColorFromHex(Map<String, dynamic> component) {
    String hexText = _containerHexController.text.trim();
    if (hexText.startsWith('#')) {
      hexText = hexText.substring(1);
    }

    if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hexText)) {
      setState(() {
        _isContainerHexValid = true;
        component['color'] = Color(int.parse('FF$hexText', radix: 16));
      });
    } else {
      setState(() {
        _isContainerHexValid = false;
      });
    }
  }

  void _updateContainerHexFromColor(Color color) {
    final hex = '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
    if (_containerHexController.text != hex) {
      _containerHexController.text = hex;
    }
  }

  void _addToSwatches(Color color) {
    bool colorExists = false;
    for (Color existingColor in _swatches) {
      if (existingColor.value == color.value) {
        colorExists = true;
        break;
      }
    }

    if (!colorExists) {
      setState(() {
        _swatches = List.from(_swatches)..add(color);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      body: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP):
              const ActivateIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (ActivateIntent intent) {
                setState(() {
                  _showPreview = !_showPreview; // Toggle preview mode
                });
                return null;
              },
            ),
          },
          child: Stack(
            children: [
              Column(
                children: [
                  _buildMenuBar(),
                  Expanded(
                    child: _isAnimationMode
                        ? Row(
                            children: [
                              // Left sidebar for Animation mode
                              Container(
                                width: 250,
                                margin: const EdgeInsets.only(
                                    left: 5, top: 5, bottom: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1C),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // Top half: Added elements
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Elements',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount:
                                                  _screenComponents.length,
                                              itemBuilder: (context, index) {
                                                final component =
                                                    _screenComponents[index];
                                                return GestureDetector(
                                                  onSecondaryTapDown: (details) {
                                                    _showElementContextMenu(
                                                      context,
                                                      details.globalPosition,
                                                      index,
                                                    );
                                                  },
                                                  child: ListTile(
                                                    title: Text(
                                                        component['name'] ??
                                                            'Element',
                                                        style: TextStyle(
                                                            color: component['selected'] == true 
                                                                ? Colors.white 
                                                                : Colors.white70,
                                                            fontWeight: component['selected'] == true 
                                                                ? FontWeight.w600 
                                                                : FontWeight.normal)),
                                                                                                         leading: Icon(Icons.widgets,
                                                         color: component['selected'] == true 
                                                             ? Colors.blue 
                                                             : Colors.white54),
                                                     trailing: Icon(Icons.more_vert, 
                                                         color: Colors.white24, size: 16),
                                                     selected: component['selected'] == true,
                                                    selectedTileColor: Colors.blue.withOpacity(0.2),
                                                    onTap: () {
                                                      setState(() {
                                                        for (var c
                                                            in _screenComponents) {
                                                          c['selected'] = false;
                                                        }
                                                        component['selected'] =
                                                            true;
                                                        _isScreenSelected = true;
                                                        _selectedRightTab = 'Animation';
                                                      });
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Divider
                                    Container(
                                        height: 1, color: Color(0xFF222222)),
                                    // Bottom half: Animations list and plus button
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text('Animations',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                IconButton(
                                                  icon: Icon(Icons.add,
                                                      color: Colors.white),
                                                  onPressed: () async {
                                                    _animationNameController
                                                        .clear();
                                                    final result =
                                                        await showDialog<
                                                            String>(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          backgroundColor:
                                                              const Color(
                                                                  0xFF232323),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12)),
                                                          title: const Text(
                                                              'Create Animation',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                          content: TextField(
                                                            controller:
                                                                _animationNameController,
                                                            autofocus: true,
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                            decoration:
                                                                const InputDecoration(
                                                              labelText:
                                                                  'Animation Name',
                                                              labelStyle: TextStyle(
                                                                  color: Colors
                                                                      .white54),
                                                              enabledBorder: UnderlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Colors.white24)),
                                                              focusedBorder: UnderlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Colors.blue)),
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(),
                                                              child: const Text(
                                                                  'Cancel',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white54)),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                if (_animationNameController
                                                                    .text
                                                                    .trim()
                                                                    .isNotEmpty) {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(_animationNameController
                                                                          .text
                                                                          .trim());
                                                                }
                                                              },
                                                              child: const Text(
                                                                  'Create'),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                    if (result != null &&
                                                        result.isNotEmpty) {
                                                      setState(() {
                                                        _animations.add({
                                                          'name': result,
                                                          'keyframes': <int>[],
                                                          'loop': false,
                                                          'speed_type': 'Normal'
                                                        });
                                                      });
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: _animations.length,
                                              itemBuilder: (context, index) {
                                                final anim = _animations[index];
                                                return GestureDetector(
                                                  onSecondaryTapDown: (details) {
                                                    _showAnimationContextMenu(
                                                      context,
                                                      details.globalPosition,
                                                      index,
                                                    );
                                                  },
                                                  child: ListTile(
                                                    title: Text(
                                                        anim['name'] ??
                                                            'Animation',
                                                        style: TextStyle(
                                                            color: Colors.white)),
                                                    leading: Icon(Icons.movie,
                                                        color: Colors.white54),
                                                    trailing: Icon(Icons.more_vert, 
                                                        color: Colors.white24, size: 16),
                                                    selected: _selectedAnimationIndex == index,
                                                    selectedTileColor: Colors.blue.withOpacity(0.2),
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedAnimationIndex =
                                                            index;
                                                      });
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Preview area with keyframe bar at the bottom
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          _buildCanvasGrid(),
                                          InteractiveViewer(
                                            key: _canvasKey,
                                            transformationController:
                                                _transformationController,
                                            minScale: _minZoom,
                                            maxScale: _maxZoom,
                                            boundaryMargin:
                                                const EdgeInsets.all(
                                                    double.infinity),
                                            onInteractionUpdate: (details) {
                                              if (details.scale != null) {
                                                setState(() {
                                                  _currentZoom =
                                                      _transformationController
                                                          .value
                                                          .getMaxScaleOnAxis();
                                                });
                                              }
                                            },
                                            child: Center(
                                              child: _buildScreenPreview(),
                                            ),
                                          ),
                                          _buildZoomControls(),
                                        ],
                                      ),
                                    ),
                                    _buildKeyframeBar(),
                                  ],
                                ),
                              ),
                              // Right sidebar for Animation mode
                              Container(
                                width: 250,
                                margin: const EdgeInsets.only(
                                  right: 5,
                                  top: 5,
                                  bottom: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1C),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // Fixed header section
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                            10,
                                          ),
                                          child: const Row(
                                            children: [
                                              Text(
                                                'Animation Settings',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: [
                                                _buildSettingsTab('Properties', true)
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                            height: 1,
                                            color: const Color(0xFF121212)),
                                      ],
                                    ),
                                    // Scrollable content section
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: _buildAnimationRightSidebarContent(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 250,
                                margin: const EdgeInsets.only(
                                  left: 5,
                                  top: 5,
                                  bottom: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1C),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: double.infinity,
                                      decoration: const BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 5),
                                          _buildIconButton(
                                              0, Icons.layers_outlined),
                                          _buildIconButton(
                                              1, Icons.grid_view_outlined),
                                          _buildIconButton(
                                              2, Icons.auto_awesome_outlined),
                                          _buildIconButton(
                                              3, Icons.image_outlined),
                                          _buildIconButton(
                                              4, Icons.video_library_outlined),
                                          const Spacer(),
                                          _buildIconButton(
                                              5, Icons.account_circle_outlined),
                                          const SizedBox(height: 5),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Container(
                                        width: 1,
                                        height: double.infinity,
                                        color: const Color(0xFF121212),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                PopupMenuButton<String>(
                                                  offset: const Offset(0, 30),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  color:
                                                      const Color(0xFF252525),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        widget.projectName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons.arrow_drop_down,
                                                        color: Colors.white54,
                                                        size: 18,
                                                      ),
                                                    ],
                                                  ),
                                                  itemBuilder: (BuildContext
                                                          context) =>
                                                      <PopupMenuEntry<String>>[
                                                    PopupMenuItem<String>(
                                                      value: 'settings',
                                                      height: 36,
                                                      child: Text(
                                                        'Website settings',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    const PopupMenuDivider(),
                                                    PopupMenuItem<String>(
                                                      value: 'delete',
                                                      height: 36,
                                                      child: Text(
                                                        'Delete page',
                                                        style: TextStyle(
                                                          color:
                                                              Color(0xFFE54D2E),
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Show different content based on selected icon
                                          if (_selectedIndex == 0)
                                            Expanded(
                                              child: _buildPagesView(),
                                            ),
                                          if (_selectedIndex == 1)
                                            Expanded(
                                              child:
                                                  _buildComponentLibraryView(),
                                            ),
                                          // Other views can be added for other icons
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Main content area - expanded to take maximum space
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        // Canvas with grid
                                        _buildCanvasGrid(),

                                        // Zoomable and draggable area
                                        InteractiveViewer(
                                          key: _canvasKey,
                                          transformationController:
                                              _transformationController,
                                          minScale: _minZoom,
                                          maxScale: _maxZoom,
                                          boundaryMargin: const EdgeInsets.all(
                                              double.infinity),
                                          onInteractionUpdate: (details) {
                                            if (details.scale != null) {
                                              setState(() {
                                                _currentZoom =
                                                    _transformationController
                                                        .value
                                                        .getMaxScaleOnAxis();
                                              });
                                            }
                                          },
                                          child: Center(
                                            child: _buildScreenPreview(),
                                          ),
                                        ),

                                        // Zoom controls overlay
                                        _buildZoomControls(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Right sidebar - made narrower
                              Container(
                                width: 250,
                                margin: const EdgeInsets.only(
                                  right: 5,
                                  top: 5,
                                  bottom: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1C),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // Fixed header section - made more compact
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                            10,
                                          ),
                                          child: const Row(
                                            children: [
                                              Text(
                                                'Settings',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: _isScreenSelected
                                                  ? [
                                                      _buildSettingsTab(
                                                        'Style',
                                                        _selectedRightTab ==
                                                            'Style',
                                                      ),
                                                      const SizedBox(width: 10),
                                                      _buildSettingsTab(
                                                        'Interactions',
                                                        _selectedRightTab ==
                                                            'Interactions',
                                                      ),
                                                    ]
                                                  : [
                                                      _buildSettingsTab(
                                                          'Page', true)
                                                    ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                            height: 1,
                                            color: const Color(0xFF121212)),
                                      ],
                                    ),
                                    // Scrollable content section
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: _buildRightSidebarContent(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build floating toolbar
  Widget _buildFloatingToolbar() {
    return Positioned(
      left: 16,
      bottom: 80, // Position above the zoom bar
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbarButton(0, Icons.mouse, 'Select'),
            _buildToolbarButton(1, Icons.pan_tool_outlined, 'Pan'),
            _buildToolbarButton(2, Icons.desktop_windows_outlined, 'Screen'),
            _buildToolbarButton(3, Icons.laptop_outlined, 'Responsive'),
            _buildToolbarButton(4, Icons.text_fields, 'Text'),
            _buildToolbarButton(5, Icons.crop_square_outlined, 'Shape'),
            _buildToolbarButton(6, Icons.videocam_outlined, 'Media'),
            _buildToolbarButton(7, Icons.square_outlined, 'Container'),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(int index, IconData icon, String tooltip) {
    final bool isSelected = _selectedToolIndex == index;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedToolIndex = index;
          });
        },
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF333333) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon,
              color: isSelected ? Colors.white : Colors.white70, size: 20),
        ),
      ),
    );
  }

  Widget _buildIconButton(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            // Reset screen selection when switching sidebar sections
            if (index != 0) {
              // If not on the Pages tab
              _isScreenSelected = false;
            }
          });
        },
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF2D2D2D) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
            if (isSelected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuBar() {
    return Container(
      height: 40,
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          _buildMenuButton('File', _buildFileMenu),
          _buildMenuButton('Edit', _buildEditMenu),
          _buildMenuButton('View', _buildViewMenu),
          _buildMenuButton('Help', _buildHelpMenu),
          // Spacer before center buttons
          const Spacer(),
          // Centered Editing/Animition buttons
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isAnimationMode = false;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor:
                      !_isAnimationMode ? Colors.blue : Colors.transparent,
                  foregroundColor:
                      !_isAnimationMode ? Colors.white : Colors.white70,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('Editing', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isAnimationMode = true;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor:
                      _isAnimationMode ? Colors.blue : Colors.transparent,
                  foregroundColor:
                      _isAnimationMode ? Colors.white : Colors.white70,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('Animition', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          // Spacer after center buttons
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${widget.projectName} - Astra Vision - Website Editor',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String title, Function buildMenuItems) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      color: const Color(0xFF252525),
      itemBuilder: (context) => buildMenuItems(),
      onSelected: (value) {
        // Handle menu item selection
        if (value == 'Preview') {
          setState(() {
            _showPreview = true;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String title, String shortcut) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          if (shortcut.isNotEmpty)
            Text(
              shortcut,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildFileMenu() {
    return [
      _buildMenuItem('New Page', 'Ctrl+N'),
      _buildMenuItem('Open Project', 'Ctrl+O'),
      _buildMenuItem('Save', 'Ctrl+S'),
      _buildMenuItem('Export Website', 'Ctrl+E'),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'close_project',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Close Project',
                style: const TextStyle(color: Colors.white70)),
            Text('Ctrl+W',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        onTap: () {
          // Add a small delay to allow the menu to close before navigation
          Future.delayed(Duration(milliseconds: 100), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const HomeDashboardPage()),
            );
          });
        },
      ),
    ];
  }

  List<PopupMenuEntry<String>> _buildEditMenu() {
    return [
      _buildMenuItem('Undo', 'Ctrl+Z'),
      _buildMenuItem('Redo', 'Ctrl+Y'),
      const PopupMenuDivider(),
      _buildMenuItem('Cut', 'Ctrl+X'),
      _buildMenuItem('Copy', 'Ctrl+C'),
      _buildMenuItem('Paste', 'Ctrl+V'),
      const PopupMenuDivider(),
      _buildMenuItem('Find', 'Ctrl+F'),
      _buildMenuItem('Replace', 'Ctrl+H'),
    ];
  }

  List<PopupMenuEntry<String>> _buildViewMenu() {
    return [
      _buildMenuItem('Preview', 'Ctrl+P'),
      _buildMenuItem('Components', 'Ctrl+B'),
      _buildMenuItem('Assets', 'Ctrl+Shift+A'),
      const PopupMenuDivider(),
      _buildMenuItem('Zoom In', 'Ctrl++'),
      _buildMenuItem('Zoom Out', 'Ctrl+-'),
      _buildMenuItem('Reset Zoom', 'Ctrl+0'),
      const PopupMenuDivider(),
      _buildMenuItem('Toggle Full Screen', 'F11'),
    ];
  }

  List<PopupMenuEntry<String>> _buildHelpMenu() {
    return [
      _buildMenuItem('Documentation', 'F1'),
      _buildMenuItem('Keyboard Shortcuts', 'Ctrl+K Ctrl+S'),
      _buildMenuItem('Template Gallery', ''),
      const PopupMenuDivider(),
      _buildMenuItem('Check for Updates', ''),
      _buildMenuItem('About', ''),
    ];
  }

  Widget _buildSettingsTab(String title, bool isSelected) {
    return InkWell(
      onTap: () {
        if (_isScreenSelected) {
          setState(() {
            _selectedRightTab = title;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF252525) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildInteractionTypeMenuItem(
    String value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInteractionsView() {
    // Get the currently selected component
    final selectedComponent = _screenComponents.firstWhere(
      (comp) => comp['selected'] == true,
      orElse: () => <String, dynamic>{},
    );

    // Show component-specific interactions if a component is selected
    final interactionsToShow = selectedComponent.isNotEmpty
        ? (selectedComponent['interactions'] as List<dynamic>?) ?? []
        : _interactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedComponent != null
                    ? '${selectedComponent['type']} interactions'
                    : 'Global interactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.add, color: Colors.white),
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                color: const Color(0xFF252525),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'on_click',
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_outlined, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text('On click',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'on_key_down',
                    child: Row(
                      children: [
                        Icon(Icons.keyboard_outlined, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text('On key down',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  setState(() {
                    final newInteraction = {
                      'type': value,
                      'name':
                          value == 'on_click' ? 'onClick' : 'onKeyboardClick',
                      'status': 'Not set',
                      'selected': false,
                      'actions': []
                    };

                    if (selectedComponent != null) {
                      // Add to component interactions
                      if (selectedComponent['interactions'] == null) {
                        selectedComponent['interactions'] = [];
                      }
                      (selectedComponent['interactions'] as List)
                          .add(newInteraction);
                    } else {
                      // Add to global interactions
                      _interactions.add(newInteraction);
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_showInteractionDetails)
          interactionsToShow.isEmpty
              ? _buildEmptyInteractionsView()
              : Column(
                  children: [
                    ...interactionsToShow.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> interaction = entry.value;
                      return _buildInteractionItem(index, interaction);
                    }).toList(),
                  ],
                )
        else
          _buildInteractionDetailsView(),
      ],
    );
  }

  Widget _buildEmptyInteractionsView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, color: Colors.white24, size: 48),
              const SizedBox(height: 16),
              Text(
                'No global interactions added',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Click + to add your first interaction',
                style: TextStyle(color: Colors.white24, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionItem(int index, Map<String, dynamic> interaction) {
    IconData getIconForType(String type) {
      switch (type) {
        case 'on_timer':
          return Icons.timer_outlined;
        case 'on_key_down':
        case 'on_key_up':
          return Icons.keyboard_outlined;
        case 'on_variable_change':
          return Icons.data_usage_outlined;
        case 'on_click':
          return Icons.touch_app_outlined;
        default:
          return Icons.touch_app_outlined;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              // Get the currently selected component
              final selectedComponent = _screenComponents.firstWhere(
                (comp) => comp['selected'] == true,
                orElse: () => <String, dynamic>{},
              );

              // Get the interactions list we're working with
              final interactionsList = selectedComponent.isNotEmpty
                  ? (selectedComponent['interactions'] as List<dynamic>?) ?? []
                  : _interactions;

              // Update selection state
              for (var i = 0; i < interactionsList.length; i++) {
                interactionsList[i]['selected'] = i == index;
              }
              _selectedInteractionIndex = index;
              _showInteractionDetails = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  getIconForType(interaction['type']),
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  interaction['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  interaction['status'],
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                if (interaction['selected'])
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNameForType(String type) {
    switch (type) {
      case 'on_click':
        return 'On click';
      case 'on_mouse_down':
        return 'On mouse down';
      case 'on_mouse_up':
        return 'On mouse up';
      case 'on_mouse_enter':
        return 'On mouse enter';
      case 'on_mouse_leave':
        return 'On mouse leave';
      case 'on_double_click':
        return 'On double click';
      case 'on_touch_start':
        return 'On touch start';
      case 'on_touch_end':
        return 'On touch end';
      case 'upon_entering_view':
        return 'Upon entering view';
      case 'upon_leaving_view':
        return 'Upon leaving view';
      case 'on_swipe':
        return 'On swipe';
      case 'on_timer':
        return 'On timer';
      case 'on_key_down':
        return 'On key down (key pressed)';
      case 'on_key_up':
        return 'On key up (key released)';
      case 'on_variable_change':
        return 'On variable change';
      case 'on_animation_start':
        return 'On animation start';
      case 'on_animation_end':
        return 'On animation end';
      default:
        return 'Unknown interaction';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'on_click':
        return Icons.touch_app;
      case 'on_mouse_down':
      case 'on_mouse_up':
      case 'on_mouse_enter':
      case 'on_mouse_leave':
        return Icons.mouse;
      case 'on_double_click':
        return Icons.touch_app;
      case 'on_touch_start':
      case 'on_touch_end':
        return Icons.touch_app;
      case 'upon_entering_view':
        return Icons.visibility;
      case 'upon_leaving_view':
        return Icons.visibility_off;
      case 'on_swipe':
        return Icons.swipe;
      case 'on_timer':
        return Icons.timer_outlined;
      case 'on_key_down':
      case 'on_key_up':
        return Icons.keyboard;
      case 'on_variable_change':
        return Icons.data_usage;
      case 'on_animation_start':
        return Icons.play_arrow;
      case 'on_animation_end':
        return Icons.stop;
      default:
        return Icons.touch_app_outlined;
    }
  }

  Widget _buildInteractionDetailsView() {
    // Get the currently selected component
    final selectedComponent = _screenComponents.firstWhere(
      (comp) => comp['selected'] == true,
      orElse: () => <String, dynamic>{},
    );

    // Get the interactions list we're working with
    final interactionsList = selectedComponent.isNotEmpty
        ? (selectedComponent['interactions'] as List<dynamic>?) ?? []
        : _interactions;

    if (_selectedInteractionIndex == null ||
        _selectedInteractionIndex! >= interactionsList.length) {
      return Container();
    }

    Map<String, dynamic> interaction =
        interactionsList[_selectedInteractionIndex!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with bolt, edit, and action icons
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showInteractionDetails = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.bolt, color: Colors.white70, size: 18),
                ),
              ),
              const SizedBox(width: 4),
              Text('>', style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                'Edit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.visibility_outlined, color: Colors.white54, size: 18),
              const SizedBox(width: 16),
              Icon(
                Icons.content_copy_outlined,
                color: Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              Icon(Icons.delete_outline, color: Colors.white54, size: 18),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Interaction type dropdown
        PopupMenuButton<String>(
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          color: const Color(0xFF252525),
          constraints: const BoxConstraints(
            maxHeight: 300, // Set max height to enable scrolling
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForType(interaction['type']),
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  interaction['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            _buildInteractionTypeMenuItem(
              'on_click',
              'On click',
              Icons.touch_app,
            ),
            _buildInteractionTypeMenuItem(
              'on_mouse_down',
              'On mouse down',
              Icons.mouse,
            ),
            _buildInteractionTypeMenuItem(
              'on_mouse_up',
              'On mouse up',
              Icons.mouse,
            ),
            _buildInteractionTypeMenuItem(
              'on_mouse_enter',
              'On mouse enter',
              Icons.mouse,
            ),
            _buildInteractionTypeMenuItem(
              'on_mouse_leave',
              'On mouse leave',
              Icons.mouse,
            ),
            _buildInteractionTypeMenuItem(
              'on_double_click',
              'On double click',
              Icons.touch_app,
            ),
            _buildInteractionTypeMenuItem(
              'on_touch_start',
              'On touch start',
              Icons.touch_app,
            ),
            _buildInteractionTypeMenuItem(
              'on_touch_end',
              'On touch end',
              Icons.touch_app,
            ),
            _buildInteractionTypeMenuItem(
              'upon_entering_view',
              'Upon entering view',
              Icons.visibility,
            ),
            _buildInteractionTypeMenuItem(
              'upon_leaving_view',
              'Upon leaving view',
              Icons.visibility_off,
            ),
            _buildInteractionTypeMenuItem(
              'on_swipe',
              'On swipe',
              Icons.swipe,
            ),
            _buildInteractionTypeMenuItem(
              'on_timer',
              'On timer',
              Icons.timer_outlined,
            ),
            _buildInteractionTypeMenuItem(
              'on_key_down',
              'On key down (key pressed)',
              Icons.keyboard,
            ),
            _buildInteractionTypeMenuItem(
              'on_key_up',
              'On key up (key released)',
              Icons.keyboard,
            ),
            _buildInteractionTypeMenuItem(
              'on_variable_change',
              'On variable change',
              Icons.data_usage,
            ),
            _buildInteractionTypeMenuItem(
              'on_animation_start',
              'On animation start',
              Icons.play_arrow,
            ),
            _buildInteractionTypeMenuItem(
              'on_animation_end',
              'On animation end',
              Icons.stop,
            ),
          ],
          onSelected: (value) {
            setState(() {
              interaction['type'] = value;
              interaction['name'] = _getNameForType(value);
            });
          },
        ),

        const SizedBox(height: 20),

        // Show delay field only for timer interaction
        if (interaction['type'] == 'on_timer') ...[
          // Delay field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Delay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.info_outline, color: Colors.white54, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: TextEditingController(text: "0"),
              style: TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _timerDelay = double.tryParse(value) ?? 0;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          // Run Once toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Run Once',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.info_outline, color: Colors.white54, size: 16),
                  ],
                ),
                Switch(
                  value: _runOnce,
                  onChanged: (value) {
                    setState(() {
                      _runOnce = value;
                    });
                  },
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.withOpacity(0.5),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[800],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show existing actions
              if (interaction['actions'] != null &&
                  interaction['actions'].isNotEmpty)
                ...interaction['actions'].map<Widget>((action) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_tree_outlined,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          action['name'] ?? action['type'],
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const Spacer(),
                        Icon(Icons.edit, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              interaction['actions'].remove(action);
                            });
                          },
                          child: Icon(Icons.delete_outline,
                              color: Colors.white54, size: 16),
                        ),
                      ],
                    ),
                  );
                }).toList()
              else
                Center(
                  child: Text(
                    'No actions added',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),

              // Add action button
              const SizedBox(height: 8),
              Center(
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      if (interaction['actions'] == null) {
                        interaction['actions'] = [];
                      }
                      if (value == 'node') {
                        interaction['actions'].add({
                          'type': 'node',
                          'name': 'Node Action',
                          'target': '',
                          'enabled': true
                        });
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'node',
                      child: Row(
                        children: [
                          Icon(Icons.account_tree_outlined,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text('Node Action',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              )),
                        ],
                      ),
                    ),
                  ],
                  child: TextButton.icon(
                    onPressed:
                        null, // This will be handled by the PopupMenuButton
                    icon: Icon(Icons.add, size: 16),
                    label: Text('Add Action'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // New method to build folder items in the sidebar
  Widget _buildFolderItem(
    String title,
    IconData icon,
    bool isExpanded,
    bool isSelected,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Fix unbounded height constraint
      children: [
        InkWell(
          onTap: () {
            // Toggle folder expansion
            setState(() {
              if (_expandedFolders.containsKey(title)) {
                _expandedFolders[title] = !_expandedFolders[title]!;
              }
              _selectedFolder = title;

              // Reset screen selection when clicking on folders other than Main
              if (title != 'Main') {
                _isScreenSelected = false;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Icon(icon, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        // Show children if expanded
        if (isExpanded && title == 'Main')
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Fix unbounded height constraint
              children: [
                // Screen item inside Main folder
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Row(
                    children: [
                      // Expansion toggle button
                      IconButton(
                        icon: Icon(
                          _expandedFolders['Screen']!
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color:
                              _isScreenSelected ? Colors.white : Colors.white70,
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _expandedFolders['Screen'] =
                                !_expandedFolders['Screen']!;
                            _selectedFolder = 'Screen';
                          });
                        },
                      ),
                      // Screen item that shows settings when clicked
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Show Screen settings when clicked
                            setState(() {
                              _isScreenSelected = true;
                              _selectedRightTab =
                                  'Style'; // Show style tab for screen settings

                              // Deselect all components
                              for (var comp in _screenComponents) {
                                comp['selected'] = false;
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isScreenSelected
                                  ? const Color(0xFF2D2D2D)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.desktop_windows_outlined,
                                  color: _isScreenSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Screen',
                                  style: TextStyle(
                                    color: _isScreenSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Show components if Screen folder is expanded
                if (_expandedFolders['Screen']!)
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // List of screen components
                        if (_screenComponents.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Text(
                              'No components added yet',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          ...(_screenComponents.map((component) {
                            final isSelected = component['selected'] == true;

                            return Container(
                              margin: const EdgeInsets.only(top: 4, bottom: 4),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    // Only allow selection and expansion if not currently resizing, moving, or rotating
                                    if (_canExpand) {
                                      // Deselect all components
                                      for (var comp in _screenComponents) {
                                        comp['selected'] = false;
                                      }
                                      // Select this component
                                      component['selected'] = true;
                                      _isScreenSelected = true;
                                      _selectedRightTab = 'Style';
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2D2D2D)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        component['type'] == 'Burger Menu'
                                            ? Icons.menu
                                            : component['type'] == 'Fan Menu'
                                                ? Icons.menu_open
                                                : Icons.widgets_outlined,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        component['name'] as String,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList()),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Method to build the Pages view (original content)
  Widget _buildPagesView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            MainAxisSize.min, // Set to min to prevent unbounded height issues
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pages',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Original Home button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                onTap: () {
                  setState(() {
                    _isScreenSelected = false;
                  });
                },
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.home_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                title: const Text(
                  'Home',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white54,
                    size: 16,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF121212)),

          // Add folder system below the divider
          const SizedBox(height: 16),

          // Main folder (expanded)
          _buildFolderItem(
            'Main',
            Icons.home_outlined,
            _expandedFolders['Main']!, // isExpanded
            _selectedFolder == 'Main', // isSelected
          ),

          // Assets folder (collapsed)
          _buildFolderItem(
            'Assets',
            Icons.folder_outlined,
            _expandedFolders['Assets']!, // isExpanded
            _selectedFolder == 'Assets', // isSelected
          ),

          // Add some space at the bottom
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Method to build the Component Library view
  Widget _buildComponentLibraryView() {
    return RawScrollbar(
      controller: _componentLibraryController,
      thumbColor: Colors.white.withOpacity(0.2),
      radius: const Radius.circular(20),
      thickness: 4,
      child: SingleChildScrollView(
        controller: _componentLibraryController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All libraries',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.person_add_outlined,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildLibraryFolder(
                'Vev library', Icons.widgets_outlined, _vevFolderExpanded),
            if (_vevFolderExpanded)
              ...(_vevSubfolders.entries.map((entry) {
                return _buildSubfolderAsFolder(
                  entry.key,
                  _getIconForSubfolder(entry.key),
                  entry.value,
                );
              }).toList()),
            const SizedBox(height: 8),
            _buildLibraryFolder('Coded components', Icons.code_outlined, false),
            const SizedBox(height: 8),
            _buildLibraryFolder(
                'Main components', Icons.dashboard_outlined, false),
          ],
        ),
      ),
    );
  }

  // Method to build library folders
  Widget _buildLibraryFolder(String title, IconData icon, bool isExpanded) {
    return InkWell(
      onTap: () {
        setState(() {
          if (title == 'Vev library') {
            _vevFolderExpanded = !_vevFolderExpanded;
          }
          // Add logic for other folders if needed
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              color: Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build subfolder as a folder with expand/collapse functionality
  Widget _buildSubfolderAsFolder(String title, IconData icon, bool isExpanded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Fix unbounded height constraint
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _vevSubfolders[title] = !_vevSubfolders[title]!;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isExpanded ? const Color(0xFF252525) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 24),
            child: title == 'Navigation'
                ? SizedBox(
                    height: 200, // Fixed height for scrollable container
                    child: RawScrollbar(
                      controller: _navigationScrollController,
                      thumbColor: Colors.white.withOpacity(0.2),
                      radius: const Radius.circular(20),
                      thickness: 4,
                      child: SingleChildScrollView(
                        controller: _navigationScrollController,
                        child: Column(
                          children: [
                            buildNavigationElement(
                                'Burger Menu', 'Burger Menu'),
                            buildNavigationElement('Fan Menu', 'Fan Menu'),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'No components',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  // Helper method to build a navigation element
  Widget buildNavigationElement(String name, String type) {
    final assetPath = type == 'Burger Menu'
        ? 'assets/websiteEditor/Navigation/burger-menu.svg'
        : 'assets/websiteEditor/Navigation/fan-menu.svg';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: Draggable<Map<String, dynamic>>(
          data: {
            'type': type,
            'name': name,
            'assetPath': assetPath,
          },
          feedback: Material(
            elevation: 4.0,
            color: Colors.transparent,
            child: Container(
              width: 200,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SvgPicture.asset(
                        assetPath,
                        width: 20,
                        height: 20,
                        fit: BoxFit.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SvgPicture.asset(
                        assetPath,
                        width: 20,
                        height: 20,
                        fit: BoxFit.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Interactive',
                                  style: TextStyle(
                                    color: Colors.blue[300],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Navigation',
                                  style: TextStyle(
                                    color: Colors.purple[300],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.drag_indicator,
                    color: Colors.white.withOpacity(0.2),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SvgPicture.asset(
                      assetPath,
                      width: 20,
                      height: 20,
                      fit: BoxFit.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Interactive',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Navigation',
                                style: TextStyle(
                                  color: Colors.purple[300],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.drag_indicator,
                  color: Colors.white.withOpacity(0.2),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get icon for subfolder
  IconData _getIconForSubfolder(String folderName) {
    switch (folderName) {
      case 'Navigation':
        return Icons.menu;
      case 'Layout':
        return Icons.grid_view;
      case 'Image':
        return Icons.image;
      case 'Video':
        return Icons.videocam;
      case 'Text':
        return Icons.text_fields;
      case 'Form':
        return Icons.input;
      case 'Data':
        return Icons.data_usage;
      case 'Embed':
        return Icons.code;
      case 'Social':
        return Icons.share;
      case 'Audio':
        return Icons.audiotrack;
      default:
        return Icons.folder;
    }
  }

  // Method to build the Style view for the right sidebar
  Widget _buildStyleView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Fix unbounded height constraint
        children: [
          const SizedBox(height: 24),
          // Size section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Size',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.aspect_ratio_outlined,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onPressed: () {
                        _updateScreenSettings(width: 1920, height: 1080);
                      },
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_full_outlined,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onPressed: () {
                        _updateScreenSettings(
                          width: _screenSettings.width == 1920
                              ? double.infinity
                              : 1920,
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Width and height fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDimensionField(
                  'W',
                  _screenSettings.width.round().toString(),
                  (value) {
                    final width = double.tryParse(value);
                    if (width != null) {
                      _updateScreenSettings(width: width);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildDimensionField(
                  'H',
                  _screenSettings.height.round().toString(),
                  (value) {
                    final height = double.tryParse(value);
                    if (height != null) {
                      _updateScreenSettings(height: height);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Min width field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDimensionField(
              'Min W',
              _screenSettings.minWidth.round().toString(),
              (value) {
                final minWidth = double.tryParse(value);
                if (minWidth != null) {
                  _updateScreenSettings(minWidth: minWidth);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          // Background section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Background',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.add, color: Colors.white54, size: 16),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showColorPicker = !_showColorPicker;
                      if (_showColorPicker) {
                        _updateHexFromColor(_screenSettings.backgroundColor);
                      }
                    });
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_color_fill,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _screenSettings.backgroundColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fill',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _showColorPicker
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showColorPicker)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _screenSettings.backgroundColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 32,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _isValidHex
                                        ? Colors.white24
                                        : Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _hexController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    hintText: '#FFFFFF',
                                    hintStyle: TextStyle(color: Colors.white38),
                                  ),
                                  onChanged: (value) {
                                    _updateColorFromHex();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.add,
                                color: Colors.white54,
                                size: 18,
                              ),
                              onPressed: () => _addToSwatches(
                                  _screenSettings.backgroundColor),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Custom swatches section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Colors',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _swatches
                                  .map((color) => Stack(
                                        children: [
                                          _buildColorOption(color),
                                          if (_swatches.indexOf(color) >= 5)
                                            Positioned(
                                              top: -4,
                                              right: -4,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _swatches.remove(color);
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 12,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build dimension input fields
  Widget _buildDimensionField(
      String label, String value, Function(String) onChanged) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: TextEditingController(text: value),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to determine which content to show in the right sidebar
  Widget _buildRightSidebarContent() {
    // Find the selected component if any
    Map<String, dynamic>? selectedComponent;
    for (var component in _screenComponents) {
      if (component['selected'] == true) {
        selectedComponent = component;
        break;
      }
    }

    if (_isScreenSelected && selectedComponent != null) {
      if (_selectedRightTab == 'Style') {
        return _buildComponentStyleView(selectedComponent);
      } else if (_selectedRightTab == 'Interactions') {
        return _buildInteractionsView();
      }
      return _buildComponentStyleView(selectedComponent); // Default return
    } else if (_isScreenSelected) {
      if (_selectedRightTab == 'Style') {
        return _buildStyleView();
      } else if (_selectedRightTab == 'Interactions') {
        return _buildInteractionsView();
      }
      return _buildStyleView(); // Default return
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meta information',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.visibility_outlined,
                  color: Colors.white54,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF383838),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 60,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF383838),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.edit_outlined,
                                color: Colors.white54,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page title',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Home',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '4/160',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Language',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'English',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Page type',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Home/Landing page',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Page path',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '/',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                      Text(
                        'index',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Meta description',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Method to build animation right sidebar content
  Widget _buildAnimationRightSidebarContent() {
    // Check if an animation is selected
    if (_selectedAnimationIndex != null && _selectedAnimationIndex! < _animations.length) {
      return _buildSelectedAnimationSettings(_animations[_selectedAnimationIndex!]);
    }
    
    // Find the selected component if any
    Map<String, dynamic>? selectedComponent;
    for (var component in _screenComponents) {
      if (component['selected'] == true) {
        selectedComponent = component;
        break;
      }
    }

    if (_isScreenSelected && selectedComponent != null) {
      return _buildComponentStyleView(selectedComponent);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Properties',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.settings,
                  color: Colors.white54,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.animation,
                  color: Colors.white54,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Select an animation or element',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click on an animation in the left panel to view its settings, or select an element to edit its properties.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }
  }

  // Animation playback methods
  void _playAnimation() {
    if (_selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      return;
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final keyframes = List<int>.from(animation['keyframes'] ?? []);
    
    if (keyframes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No keyframes found in animation. Please add keyframes before playing.'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Sort keyframes to ensure proper order
    keyframes.sort();
    
    setState(() {
      _isPlaying = true;
      _currentPlaybackFrame = 0;
    });
    
    // Start animation from frame 0 to the last keyframe
    final maxFrame = keyframes.last;
    
    // Each frame represents 1ms, but we use 16ms (60fps) for smooth animation
    // Speed can be adjusted by the speed multiplier
    final frameInterval = (16 / _animationSpeed).round().clamp(1, 1000);
    _animationTimer = Timer.periodic(Duration(milliseconds: frameInterval), (timer) {
      if (!_isPlaying || _currentPlaybackFrame > maxFrame) {
        timer.cancel();
        _animationTimer = null;
        setState(() {
          _isPlaying = false;
          _currentPlaybackFrame = 0;
        });
        return;
      }
      
              setState(() {
          _selectedFrame = _currentPlaybackFrame;
          // Apply interpolated data for current frame
          try {
            _applyInterpolatedFrameData(_currentPlaybackFrame, keyframes);
          } catch (e) {
            print('Error applying interpolated frame data: $e');
            // Continue animation even if one frame fails
          }
        });
      
      _currentPlaybackFrame++;
    });
  }
  
  // Apply saved keyframe data to elements
  void _applyKeyframeData(int frame) {
    if (_selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      return;
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final frameData = animation['frame_data'];
    
    if (frameData == null) {
      print('No frame data found for animation');
      return;
    }
    
    final currentFrameData = frameData['frame_$frame'] as Map<String, dynamic>?;
    if (currentFrameData == null) {
      print('No data found for frame $frame');
      return;
    }
    
    print('Applying keyframe data for frame $frame');
    
    // Apply data to elements using IDs
    currentFrameData.forEach((elementId, elementData) {
      if (elementId is String && elementData is Map<String, dynamic>) {
        // Find the component with matching ID
        final componentIndex = _screenComponents.indexWhere((c) => c['id'] == elementId);
        if (componentIndex != -1) {
          final component = _screenComponents[componentIndex];
          
          // Update element properties (only if not null)
          if (elementData['position'] != null) {
            component['position'] = elementData['position'];
          }
          if (elementData['rotation'] != null) {
            component['rotation'] = elementData['rotation'];
          }
          if (elementData['scale'] != null) {
            component['scale'] = elementData['scale'];
          }
          if (elementData['opacity'] != null) {
            component['opacity'] = elementData['opacity'];
          }
          
          print('Applied data to ${component['name']} (ID: $elementId): ${elementData}');
        } else {
          print('Warning: Could not find component with ID: $elementId');
        }
      }
    });
  }
  
  // Apply interpolated frame data between keyframes
  void _applyInterpolatedFrameData(int currentFrame, List<int> keyframes) {
    if (_selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      return;
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final frameData = animation['frame_data'];
    
    if (frameData == null) {
      return;
    }
    
    // Find the two keyframes to interpolate between
    int? prevKeyframe;
    int? nextKeyframe;
    
    // Find previous and next keyframes
    for (int i = 0; i < keyframes.length; i++) {
      if (keyframes[i] <= currentFrame) {
        prevKeyframe = keyframes[i];
      }
      if (keyframes[i] >= currentFrame && nextKeyframe == null) {
        nextKeyframe = keyframes[i];
        break;
      }
    }
    
    // Handle edge cases
    if (prevKeyframe == null && nextKeyframe != null) {
      // Before first keyframe - hold the first keyframe's values
      _applyKeyframeData(nextKeyframe);
      return;
    } else if (prevKeyframe != null && nextKeyframe == null) {
      // After last keyframe - hold the last keyframe's values
      _applyKeyframeData(prevKeyframe);
      return;
    } else if (prevKeyframe == null && nextKeyframe == null) {
      // No keyframes at all
      return;
    }
    
    // If we're exactly on a keyframe, apply its data directly
    if (currentFrame == prevKeyframe || currentFrame == nextKeyframe) {
      _applyKeyframeData(currentFrame);
      return;
    }
    
    // Get data for both keyframes
    final prevFrameData = frameData['frame_$prevKeyframe'] as Map<String, dynamic>?;
    final nextFrameData = frameData['frame_$nextKeyframe'] as Map<String, dynamic>?;
    
    if (prevFrameData == null || nextFrameData == null) {
      return;
    }
    
    // Calculate interpolation factor (0.0 to 1.0)
    double t = 0.0;
    if (nextKeyframe! != prevKeyframe!) {
      t = (currentFrame - prevKeyframe!) / (nextKeyframe! - prevKeyframe!);
    }
    
    // Apply interpolated data to elements using IDs
    // Get all element IDs that exist in both frames
    final commonIds = <String>[];
    for (final id in prevFrameData.keys) {
      if (id is String && nextFrameData.containsKey(id)) {
        commonIds.add(id);
      }
    }
    
    for (final elementId in commonIds) {
      final prevElementData = prevFrameData[elementId];
      final nextElementData = nextFrameData[elementId];
      
      if (prevElementData is Map<String, dynamic> && nextElementData is Map<String, dynamic>) {
        // Find the component with matching ID
        final componentIndex = _screenComponents.indexWhere((c) => c['id'] == elementId);
        if (componentIndex != -1) {
          final component = _screenComponents[componentIndex];
        
        // Interpolate position
        final prevPos = prevElementData['position'];
        final nextPos = nextElementData['position'];
        if (prevPos != null && nextPos != null) {
          Offset interpolatedPos;
          if (prevPos is Offset && nextPos is Offset) {
            interpolatedPos = Offset.lerp(prevPos, nextPos, t)!;
          } else if (prevPos is List && nextPos is List && 
                     prevPos.length >= 2 && nextPos.length >= 2) {
            final x = prevPos[0] + (nextPos[0] - prevPos[0]) * t;
            final y = prevPos[1] + (nextPos[1] - prevPos[1]) * t;
            interpolatedPos = Offset(x.toDouble(), y.toDouble());
          } else {
            interpolatedPos = prevPos is Offset ? prevPos : Offset.zero;
          }
          component['position'] = interpolatedPos;
        }
        
        // Interpolate rotation
        final prevRot = prevElementData['rotation'];
        final nextRot = nextElementData['rotation'];
        if (prevRot != null && nextRot != null) {
          component['rotation'] = prevRot + (nextRot - prevRot) * t;
        }
        
        // Interpolate scale
        final prevScale = prevElementData['scale'];
        final nextScale = nextElementData['scale'];
        if (prevScale != null && nextScale != null) {
          component['scale'] = prevScale + (nextScale - prevScale) * t;
        }
        
        // Interpolate opacity
        final prevOpacity = prevElementData['opacity'];
        final nextOpacity = nextElementData['opacity'];
        if (prevOpacity != null && nextOpacity != null) {
          component['opacity'] = prevOpacity + (nextOpacity - prevOpacity) * t;
        }
        } else {
          print('Warning: Could not find component with ID: $elementId for interpolation');
        }
      }
    }
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    setState(() {
      _isPlaying = false;
      _currentPlaybackFrame = 0;
      // Reset to first frame
      _selectedFrame = 0;
    });
    
    // Optionally reset elements to their initial positions
    // You can uncomment this if you want elements to return to start positions
    // _resetElementsToInitialState();
  }
  
  // Optional: Reset elements to their initial state
  void _resetElementsToInitialState() {
    if (_selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      return;
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final keyframes = List<int>.from(animation['keyframes'] ?? []);
    
    if (keyframes.isNotEmpty) {
      keyframes.sort();
      // Apply the first keyframe's data
      _applyKeyframeData(keyframes.first);
    }
  }
  
  // Show enhanced keyframe settings dialog
  void _showKeyframeDetails(int frame) {
    if (_selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      return;
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final frameData = animation['frame_data'] as Map<String, dynamic>?;
    
    if (frameData == null || !frameData.containsKey('frame_$frame')) {
      // Show empty keyframe dialog
      _showEmptyKeyframeDialog(frame);
      return;
    }
    
    final data = frameData['frame_$frame'] as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252525),
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Keyframe Settings - Frame $frame',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animation info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.movie, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Animation: ${animation['name'] ?? 'Unnamed'}',
                              style: const TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Frame: $frame • Elements: ${data.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Container elements
                  Text(
                    'Animated Elements:',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  ...data.entries.map((entry) {
                    final elementId = entry.key;
                    final elementData = entry.value as Map<String, dynamic>;
                    final elementName = elementData['name'] ?? 'Unknown';
                    final elementType = elementData['type'] ?? 'unknown';
                    final position = elementData['position'];
                    final rotation = elementData['rotation'] ?? 0.0;
                    final scale = elementData['scale'] ?? 1.0;
                    final opacity = elementData['opacity'] ?? 1.0;
                    
                    // Handle position as either Offset or array
                    String positionText;
                    if (position is Offset) {
                      positionText = '(${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})';
                    } else if (position is List && position.length >= 2) {
                      positionText = '(${position[0].toStringAsFixed(1)}, ${position[1].toStringAsFixed(1)})';
                    } else {
                      positionText = '(0.0, 0.0)';
                    }
                    
                    // Get type icon
                    IconData typeIcon;
                    Color typeColor;
                    switch (elementType) {
                      case 'container':
                        typeIcon = Icons.crop_square;
                        typeColor = Colors.blue;
                        break;
                      case 'text':
                        typeIcon = Icons.text_fields;
                        typeColor = Colors.green;
                        break;
                      default:
                        typeIcon = Icons.widgets;
                        typeColor = Colors.grey;
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: typeColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Element header
                          Row(
                            children: [
                              Icon(typeIcon, color: typeColor, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  elementName,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  elementType.toUpperCase(),
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Properties grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildPropertyCard('Position', positionText, Icons.my_location, Colors.red),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPropertyCard('Rotation', '${rotation.toStringAsFixed(1)}°', Icons.rotate_right, Colors.orange),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPropertyCard('Scale', '${scale.toStringAsFixed(2)}x', Icons.zoom_in, Colors.purple),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPropertyCard('Opacity', '${(opacity * 100).toStringAsFixed(0)}%', Icons.opacity, Colors.teal),
                              ),
                            ],
                          ),
                          
                          // Element ID (for debugging)
                          const SizedBox(height: 8),
                          Text(
                            'ID: $elementId',
                            style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                // Delete keyframe
                _deleteKeyframe(frame);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
              label: const Text('Delete Keyframe', style: TextStyle(color: Colors.red)),
            ),
            TextButton.icon(
              onPressed: () {
                // Apply this keyframe's data to current frame
                _applyKeyframeData(frame);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Applied keyframe $frame data to current elements'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow, color: Colors.green, size: 16),
              label: const Text('Apply Now', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.amber)),
            ),
          ],
        );
      },
    );
  }
  
  // Helper method to build property cards
  Widget _buildPropertyCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
  
  // Show dialog for empty keyframes
  void _showEmptyKeyframeDialog(int frame) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252525),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Empty Keyframe - Frame $frame',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This keyframe has no animation data.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'To add animation data to this keyframe:',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Select elements on the canvas\n2. Enable recording (red button)\n3. Move or modify the elements\n4. The keyframe will be automatically updated',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.amber)),
            ),
          ],
        );
      },
    );
  }
  
  // Delete a keyframe
  void _deleteKeyframe(int frame) {
    if (_selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      return;
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final keyframes = List<int>.from(animation['keyframes'] ?? []);
    final frameData = animation['frame_data'] as Map<String, dynamic>?;
    
    // Remove keyframe from list
    keyframes.remove(frame);
    animation['keyframes'] = keyframes;
    
    // Remove frame data
    frameData?.remove('frame_$frame');
    
    setState(() {
      // Trigger UI update
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted keyframe at frame $frame'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Check if a keyframe has data
  bool _hasKeyframeData(int frame) {
    if (_selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      return false;
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final frameData = animation['frame_data'] as Map<String, dynamic>?;
    
    if (frameData == null || !frameData.containsKey('frame_$frame')) {
      return false;
    }
    
    final data = frameData['frame_$frame'] as Map<String, dynamic>;
    return data.isNotEmpty;
  }

  // Get tooltip text for a keyframe
  String _getKeyframeTooltip(int frame) {
    if (_selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      return 'Frame $frame';
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final frameData = animation['frame_data'] as Map<String, dynamic>?;
    
    if (frameData == null || !frameData.containsKey('frame_$frame')) {
      return 'Frame $frame (No data)';
    }
    
    final data = frameData['frame_$frame'] as Map<String, dynamic>;
    final elementCount = data.length;
    
    if (elementCount == 0) {
      return 'Frame $frame (No elements)';
    }
    
    String tooltip = 'Frame $frame\nElements: $elementCount\n';
    
    // Add details for each element
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final elementName = value['name'] ?? 'Unknown';
        final position = value['position'];
        tooltip += '\n$elementName:\n';
        
        // Handle position as either Offset or array
        if (position is Offset) {
          tooltip += '  Position: (${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})\n';
        } else if (position is List && position.length >= 2) {
          tooltip += '  Position: (${position[0].toStringAsFixed(1)}, ${position[1].toStringAsFixed(1)})\n';
        } else {
          tooltip += '  Position: (0.0, 0.0)\n';
        }
        
        tooltip += '  Rotation: ${(value['rotation'] ?? 0.0).toStringAsFixed(1)}°\n';
        tooltip += '  Scale: ${(value['scale'] ?? 1.0).toStringAsFixed(2)}\n';
        tooltip += '  Opacity: ${(value['opacity'] ?? 1.0).toStringAsFixed(2)}';
      }
    });
    
    return tooltip;
  }

  // Create keyframe at current frame with selected element data
  void _createKeyframeAtCurrentFrame() {
    print('_createKeyframeAtCurrentFrame called - SelectedAnimation: $_selectedAnimationIndex, SelectedFrame: $_selectedFrame');
    
    if (_selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      print('Cannot create keyframe - no animation selected');
      // Show warning to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No animation selected. Please select an animation before creating a keyframe.'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final keyframes = List<int>.from(animation['keyframes'] ?? []);
    
    // Get selected elements
    final selectedElements = _screenComponents.where((c) => c['selected'] == true).toList();
    print('Found ${selectedElements.length} selected elements');
    
    if (selectedElements.isNotEmpty) {
      // Add current frame as keyframe if not already present
      if (!keyframes.contains(_selectedFrame)) {
        keyframes.add(_selectedFrame);
        keyframes.sort();
        animation['keyframes'] = keyframes;
        print('Added keyframe at frame $_selectedFrame');
      }
      
      // Store the current state of all selected elements at this frame
      final frameData = <String, dynamic>{};
      for (final element in selectedElements) {
        final elementId = element['id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        frameData[elementId] = {
          'id': elementId,
          'type': element['type'],
          'position': element['position'] ?? Offset.zero,
          'rotation': element['rotation'] ?? 0.0,
          'scale': element['scale'] ?? 1.0,
          'opacity': element['opacity'] ?? 1.0,
          'name': element['name'], // Also store name for reference
        };
        print('Recorded data for ${element['name']} (ID: $elementId): pos=${element['position']}, rot=${element['rotation']}, scale=${element['scale']}, opacity=${element['opacity']}');
      }
      
      // Store frame data in animation
      if (animation['frame_data'] == null) {
        animation['frame_data'] = <String, dynamic>{};
      }
      animation['frame_data']['frame_$_selectedFrame'] = frameData;
      print('Saved frame data for frame $_selectedFrame');
      
      setState(() {
        // Trigger UI update
      });
    } else {
      print('No selected elements found - cannot create keyframe');
      // Show warning to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No elements selected. Please select elements before creating a keyframe.'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Record keyframe when element properties change
  void _recordKeyframe() {
    print('_recordKeyframe called - Recording: $_isRecording, SelectedAnimation: $_selectedAnimationIndex, SelectedFrame: $_selectedFrame');
    
    if (!_isRecording || _selectedAnimationIndex == null || _selectedAnimationIndex! >= _animations.length) {
      print('Recording aborted - conditions not met');
      return;
    }
    
    final animation = _animations[_selectedAnimationIndex!];
    final keyframes = List<int>.from(animation['keyframes'] ?? []);
    
    // Always record data, even if keyframe already exists (to update current state)
    final selectedElements = _screenComponents.where((c) => c['selected'] == true).toList();
    print('Found ${selectedElements.length} selected elements');
    
    if (selectedElements.isNotEmpty) {
      // Add current frame as keyframe if not already present
      if (!keyframes.contains(_selectedFrame)) {
        keyframes.add(_selectedFrame);
        keyframes.sort();
        animation['keyframes'] = keyframes;
        print('Added keyframe at frame $_selectedFrame');
      }
      
      // Store the current state of all selected elements at this frame
      final frameData = <String, dynamic>{};
      for (final element in selectedElements) {
        final elementId = element['id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        frameData[elementId] = {
          'id': elementId,
          'type': element['type'],
          'position': element['position'] ?? Offset.zero,
          'rotation': element['rotation'] ?? 0.0,
          'scale': element['scale'] ?? 1.0,
          'opacity': element['opacity'] ?? 1.0,
          'name': element['name'], // Also store name for reference
        };
        print('Recorded data for ${element['name']} (ID: $elementId): pos=${element['position']}, rot=${element['rotation']}, scale=${element['scale']}, opacity=${element['opacity']}');
      }
      
      // Store frame data in animation
      if (animation['frame_data'] == null) {
        animation['frame_data'] = <String, dynamic>{};
      }
      animation['frame_data']['frame_$_selectedFrame'] = frameData;
      print('Saved frame data for frame $_selectedFrame');
      
      setState(() {
        // Trigger UI update
      });
    } else {
      print('No selected elements found - cannot record keyframe');
    }
  }

  // Method to build selected animation settings (Loop and Speed Type only)
  Widget _buildSelectedAnimationSettings(Map<String, dynamic> animation) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Animation info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Animation: ${animation['name'] ?? 'Unnamed'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.movie,
                  color: Colors.white54,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Animation Settings Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Animation Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Loop Setting
                _buildAnimationProperty(
                  'Loop',
                  animation['loop'] == true ? 'Enabled' : 'Disabled',
                  Icons.repeat,
                  () {
                    setState(() {
                      animation['loop'] = !(animation['loop'] ?? false);
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Speed Type Setting
                _buildAnimationProperty(
                  'Speed Type',
                  animation['speed_type'] ?? 'Normal',
                  Icons.speed,
                  () {
                    _showSpeedTypeDialog(animation);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Debug: Show saved keyframe data
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.data_object, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Saved Keyframes Data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (animation['keyframes'] != null && animation['keyframes'].isNotEmpty) ...[
                  Text(
                    'Keyframes: ${animation['keyframes'].join(', ')}',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (animation['frame_data'] != null) ...[
                    Text(
                      'Frame Data:',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    ...((animation['frame_data'] as Map<String, dynamic>).entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList()),
                  ],
                ] else ...[
                  Text(
                    'No keyframes saved yet. Enable recording and click on timeline frames or modify element properties.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Method to show speed type selection dialog
  void _showSpeedTypeDialog(Map<String, dynamic> animation) {
    final speedTypes = ['Slow', 'Normal', 'Fast', 'Custom'];
    final currentSpeedType = animation['speed_type'] ?? 'Normal';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF232323),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Select Speed Type', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: speedTypes.map((speedType) {
              return ListTile(
                title: Text(speedType, style: const TextStyle(color: Colors.white)),
                leading: Radio<String>(
                  value: speedType,
                  groupValue: currentSpeedType,
                  onChanged: (value) {
                    setState(() {
                      animation['speed_type'] = value;
                    });
                    Navigator.of(context).pop();
                  },
                  activeColor: Colors.blue,
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  // Method to build element animation view
  Widget _buildElementAnimationView(Map<String, dynamic> component) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Element info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Element: ${component['name'] ?? 'Unnamed'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.widgets,
                  color: Colors.white54,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Animation Properties Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.play_arrow, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Animation Properties',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Duration Setting
                _buildAnimationProperty(
                  'Duration',
                  '${component['animation_duration'] ?? 1.0}s',
                  Icons.schedule,
                  () {
                    // TODO: Show duration picker
                  },
                ),
                const SizedBox(height: 12),
                
                // Delay Setting
                _buildAnimationProperty(
                  'Delay',
                  '${component['animation_delay'] ?? 0.0}s',
                  Icons.pause,
                  () {
                    // TODO: Show delay picker
                  },
                ),
                const SizedBox(height: 12),
                
                // Easing Setting
                _buildAnimationProperty(
                  'Easing',
                  component['animation_easing'] ?? 'ease-in-out',
                  Icons.timeline,
                  () {
                    // TODO: Show easing picker
                  },
                ),
                const SizedBox(height: 12),
                
                // Loop Setting
                _buildAnimationProperty(
                  'Loop',
                  component['animation_loop'] == true ? 'Yes' : 'No',
                  Icons.repeat,
                  () {
                    setState(() {
                      component['animation_loop'] = !(component['animation_loop'] ?? false);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Transform Properties Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.transform, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Transform',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                                 // Position X
                 _buildSliderProperty(
                   'Position X',
                   component['position']?.dx ?? 0.0,
                   -1000,
                   1000,
                   (value) {
                     setState(() {
                       final pos = component['position'] as Offset? ?? Offset.zero;
                       component['position'] = Offset(value, pos.dy);
                       _recordKeyframe(); // Record keyframe when position changes
                     });
                   },
                 ),
                const SizedBox(height: 12),
                
                                 // Position Y
                 _buildSliderProperty(
                   'Position Y',
                   component['position']?.dy ?? 0.0,
                   -1000,
                   1000,
                   (value) {
                     setState(() {
                       final pos = component['position'] as Offset? ?? Offset.zero;
                       component['position'] = Offset(pos.dx, value);
                       _recordKeyframe(); // Record keyframe when position changes
                     });
                   },
                 ),
                 const SizedBox(height: 12),
                 
                 // Scale
                 _buildSliderProperty(
                   'Scale',
                   component['scale'] ?? 1.0,
                   0.1,
                   3.0,
                   (value) {
                     setState(() {
                       component['scale'] = value;
                       _recordKeyframe(); // Record keyframe when scale changes
                     });
                   },
                 ),
                 const SizedBox(height: 12),
                 
                 // Rotation
                 _buildSliderProperty(
                   'Rotation',
                   component['rotation'] ?? 0.0,
                   -180,
                   180,
                   (value) {
                     setState(() {
                       component['rotation'] = value;
                       _recordKeyframe(); // Record keyframe when rotation changes
                     });
                   },
                 ),
                 const SizedBox(height: 12),
                 
                 // Opacity
                 _buildSliderProperty(
                   'Opacity',
                   component['opacity'] ?? 1.0,
                   0.0,
                   1.0,
                   (value) {
                     setState(() {
                       component['opacity'] = value;
                       _recordKeyframe(); // Record keyframe when opacity changes
                     });
                   },
                 ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Helper widget to build animation property row
  Widget _buildAnimationProperty(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  // Helper widget to build slider property
  Widget _buildSliderProperty(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.blue,
            overlayColor: Colors.blue.withOpacity(0.2),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // Method to build component style view
  Widget _buildComponentStyleView(Map<String, dynamic> component) {
    final type = component['type'] as String;
    final position = component['position'] as Offset;
    final rotation = component['rotation'] as double? ?? 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Component type header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _screenComponents.remove(component);
                      _isScreenSelected = false;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Position section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Position',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDimensionField(
                  'X',
                  position.dx.round().toString(),
                  (value) {
                    final x = double.tryParse(value);
                    if (x != null) {
                      setState(() {
                        component['position'] = Offset(x, position.dy);
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildDimensionField(
                  'Y',
                  position.dy.round().toString(),
                  (value) {
                    final y = double.tryParse(value);
                    if (y != null) {
                      setState(() {
                        component['position'] = Offset(position.dx, y);
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Rotation section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Rotation',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: rotation,
                    min: 0,
                    max: 360,
                    divisions: 36,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[800],
                    label: rotation.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        component['rotation'] = value;
                      });
                    },
                  ),
                ),
                Container(
                  width: 50,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${rotation.round()}°',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Size section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Size',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDimensionField(
                  'W',
                  '200',
                  (value) {
                    // Implement width change
                  },
                ),
                const SizedBox(width: 8),
                _buildDimensionField(
                  'H',
                  '50',
                  (value) {
                    // Implement height change
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Style section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Style',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (type == 'Burger Menu')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu color
                  Text(
                    'Menu color',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showBurgerMenuColorPicker =
                            !_showBurgerMenuColorPicker;
                        if (_showBurgerMenuColorPicker) {
                          _updateBurgerMenuHexFromColor(
                              component['menuColor'] as Color? ??
                                  Colors.black87);
                        }
                      });
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_color_fill,
                            color: Colors.white54,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: component['menuColor'] as Color? ??
                                  Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Menu Color',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _showBurgerMenuColorPicker
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showBurgerMenuColorPicker)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: component['menuColor'] as Color? ??
                                      Colors.black87,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 32,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _isBurgerMenuHexValid
                                          ? Colors.white24
                                          : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _burgerMenuHexController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      hintText: '#000000',
                                      hintStyle:
                                          TextStyle(color: Colors.white38),
                                    ),
                                    onChanged: (value) {
                                      _updateBurgerMenuColorFromHex(component);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                onPressed: () => _addToSwatches(
                                    component['menuColor'] as Color? ??
                                        Colors.black87),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _swatches.map((color) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    component['menuColor'] = color;
                                    _updateBurgerMenuHexFromColor(color);
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: (component['menuColor'] as Color?)
                                                  ?.value ==
                                              color.value
                                          ? Colors.blue
                                          : Colors.white24,
                                      width: (component['menuColor'] as Color?)
                                                  ?.value ==
                                              color.value
                                          ? 2
                                          : 1,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Line thickness
                  Text(
                    'Line thickness',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: component['lineThickness'] as double? ?? 3.0,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey[800],
                          label: (component['lineThickness'] as double? ?? 3.0)
                              .round()
                              .toString(),
                          onChanged: (value) {
                            setState(() {
                              component['lineThickness'] = value;
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${(component['lineThickness'] as double? ?? 3.0).round()}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Line spacing
                  Text(
                    'Line spacing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: component['lineSpacing'] as double? ?? 5.0,
                          min: 2,
                          max: 15,
                          divisions: 13,
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey[800],
                          label: (component['lineSpacing'] as double? ?? 5.0)
                              .round()
                              .toString(),
                          onChanged: (value) {
                            setState(() {
                              component['lineSpacing'] = value;
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${(component['lineSpacing'] as double? ?? 5.0).round()}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (type == 'Container')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Container color
                  Text(
                    'Container color',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showContainerColorPicker = !_showContainerColorPicker;
                        if (_showContainerColorPicker) {
                          _updateContainerHexFromColor(
                              component['color'] as Color? ?? Colors.black);
                        }
                      });
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_color_fill,
                            color: Colors.white54,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color:
                                  component['color'] as Color? ?? Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fill Color',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _showContainerColorPicker
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showContainerColorPicker)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: component['color'] as Color? ??
                                      Colors.black,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 32,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _isContainerHexValid
                                          ? Colors.white24
                                          : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _containerHexController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      hintText: '#000000',
                                      hintStyle:
                                          TextStyle(color: Colors.white38),
                                    ),
                                    onChanged: (_) {
                                      _updateContainerColorFromHex(component);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                onPressed: () => _addToSwatches(
                                    component['color'] as Color? ??
                                        Colors.black),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _swatches.map((color) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    component['color'] = color;
                                    _updateContainerHexFromColor(color);
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: (component['color'] as Color?)
                                                  ?.value ==
                                              color.value
                                          ? Colors.blue
                                          : Colors.white24,
                                      width: (component['color'] as Color?)
                                                  ?.value ==
                                              color.value
                                          ? 2
                                          : 1,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  // Border Radius Controls
                  const SizedBox(height: 16),
                  Text(
                    'Border Radius',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Top Left corner
                  Row(
                    children: [
                      Text(
                        'Top Left',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 50,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextField(
                          controller: TextEditingController(
                              text:
                                  '${(component['borderRadiusTopLeft'] as double? ?? 4.0).round()}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            suffixText: 'px',
                            suffixStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final radius = int.tryParse(value) ?? 4;
                            setState(() {
                              component['borderRadiusTopLeft'] =
                                  radius.toDouble();
                              if (component['linkCorners'] == true) {
                                component['borderRadiusTopRight'] =
                                    radius.toDouble();
                                component['borderRadiusBottomLeft'] =
                                    radius.toDouble();
                                component['borderRadiusBottomRight'] =
                                    radius.toDouble();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Top Right corner
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Top Right',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 50,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextField(
                          controller: TextEditingController(
                              text:
                                  '${(component['borderRadiusTopRight'] as double? ?? 4.0).round()}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            suffixText: 'px',
                            suffixStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final radius = int.tryParse(value) ?? 4;
                            setState(() {
                              component['borderRadiusTopRight'] =
                                  radius.toDouble();
                              if (component['linkCorners'] == true) {
                                component['borderRadiusTopLeft'] =
                                    radius.toDouble();
                                component['borderRadiusBottomLeft'] =
                                    radius.toDouble();
                                component['borderRadiusBottomRight'] =
                                    radius.toDouble();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Bottom Left corner
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Bottom Left',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 50,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextField(
                          controller: TextEditingController(
                              text:
                                  '${(component['borderRadiusBottomLeft'] as double? ?? 4.0).round()}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            suffixText: 'px',
                            suffixStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final radius = int.tryParse(value) ?? 4;
                            setState(() {
                              component['borderRadiusBottomLeft'] =
                                  radius.toDouble();
                              if (component['linkCorners'] == true) {
                                component['borderRadiusTopLeft'] =
                                    radius.toDouble();
                                component['borderRadiusTopRight'] =
                                    radius.toDouble();
                                component['borderRadiusBottomRight'] =
                                    radius.toDouble();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Bottom Right corner
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Bottom Right',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 50,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextField(
                          controller: TextEditingController(
                              text:
                                  '${(component['borderRadiusBottomRight'] as double? ?? 4.0).round()}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            suffixText: 'px',
                            suffixStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final radius = int.tryParse(value) ?? 4;
                            setState(() {
                              component['borderRadiusBottomRight'] =
                                  radius.toDouble();
                              if (component['linkCorners'] == true) {
                                component['borderRadiusTopLeft'] =
                                    radius.toDouble();
                                component['borderRadiusTopRight'] =
                                    radius.toDouble();
                                component['borderRadiusBottomLeft'] =
                                    radius.toDouble();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Link all corners option
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Link all corners',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: component['linkCorners'] as bool? ?? false,
                        onChanged: (value) {
                          setState(() {
                            component['linkCorners'] = value;
                            if (value) {
                              // Use the top-left value for all corners
                              final radius =
                                  component['borderRadiusTopLeft'] as double? ??
                                      4.0;
                              component['borderRadiusTopRight'] = radius;
                              component['borderRadiusBottomLeft'] = radius;
                              component['borderRadiusBottomRight'] = radius;
                            }
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),

                  // Box Shadow Controls
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showBoxShadowControls = !_showBoxShadowControls;
                      });
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.blur_on,
                            color: Colors.white54,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Box Shadow',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: component['hasShadow'] as bool? ?? false,
                            onChanged: (value) {
                              setState(() {
                                component['hasShadow'] = value;
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _showBoxShadowControls
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Box Shadow Details
                  if (_showBoxShadowControls &&
                      (component['hasShadow'] == true))
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shadow Color
                          Text(
                            'Shadow Color',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: component['shadowColor'] as Color? ??
                                      Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // Show color picker for shadow color
                                    // This would be implemented similar to other color pickers
                                    setState(() {
                                      // For simplicity, just toggle between black and gray
                                      if ((component['shadowColor'] as Color?)
                                              ?.opacity ==
                                          0.3) {
                                        component['shadowColor'] =
                                            Colors.black.withOpacity(0.5);
                                      } else {
                                        component['shadowColor'] =
                                            Colors.black.withOpacity(0.3);
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF333333),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Change Color',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Shadow Blur
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Blur',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 50,
                                height: 32,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252525),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: TextField(
                                  controller: TextEditingController(
                                      text:
                                          '${(component['shadowBlur'] as double? ?? 10.0).round()}'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    suffixText: 'px',
                                    suffixStyle: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final blur = int.tryParse(value) ?? 10;
                                    setState(() {
                                      component['shadowBlur'] = blur.toDouble();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: component['shadowBlur'] as double? ?? 10.0,
                            min: 0,
                            max: 50,
                            divisions: 50,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[800],
                            onChanged: (value) {
                              setState(() {
                                component['shadowBlur'] = value;
                              });
                            },
                          ),

                          // Shadow Spread
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Spread',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 50,
                                height: 32,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252525),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: TextField(
                                  controller: TextEditingController(
                                      text:
                                          '${(component['shadowSpreadRadius'] as double? ?? 0.0).round()}'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    suffixText: 'px',
                                    suffixStyle: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final spread = int.tryParse(value) ?? 0;
                                    setState(() {
                                      component['shadowSpreadRadius'] =
                                          spread.toDouble();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: component['shadowSpreadRadius'] as double? ??
                                0.0,
                            min: -10,
                            max: 20,
                            divisions: 30,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[800],
                            onChanged: (value) {
                              setState(() {
                                component['shadowSpreadRadius'] = value;
                              });
                            },
                          ),

                          // Shadow Offset X
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Offset X',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 50,
                                height: 32,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252525),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: TextField(
                                  controller: TextEditingController(
                                      text:
                                          '${(component['shadowOffsetX'] as double? ?? 0.0).round()}'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    suffixText: 'px',
                                    suffixStyle: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final offsetX = int.tryParse(value) ?? 0;
                                    setState(() {
                                      component['shadowOffsetX'] =
                                          offsetX.toDouble();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: component['shadowOffsetX'] as double? ?? 0.0,
                            min: -20,
                            max: 20,
                            divisions: 40,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[800],
                            onChanged: (value) {
                              setState(() {
                                component['shadowOffsetX'] = value;
                              });
                            },
                          ),

                          // Shadow Offset Y
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Offset Y',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 50,
                                height: 32,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252525),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: TextField(
                                  controller: TextEditingController(
                                      text:
                                          '${(component['shadowOffsetY'] as double? ?? 4.0).round()}'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    suffixText: 'px',
                                    suffixStyle: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final offsetY = int.tryParse(value) ?? 4;
                                    setState(() {
                                      component['shadowOffsetY'] =
                                          offsetY.toDouble();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: component['shadowOffsetY'] as double? ?? 4.0,
                            min: -20,
                            max: 20,
                            divisions: 40,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[800],
                            onChanged: (value) {
                              setState(() {
                                component['shadowOffsetY'] = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Add method to build the canvas grid
  Widget _buildCanvasGrid() {
    return CustomPaint(
      painter: GridPainter(),
      child: Container(),
    );
  }

  // Update the screen preview to use settings
  Widget _buildScreenPreview() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Calculate the size while maintaining aspect ratio
        final aspectRatio = _screenSettings.width / _screenSettings.height;
        final maxWidth = constraints.maxWidth * 0.8;
        final maxHeight = constraints.maxHeight * 0.8;

        final double width;
        final double height;

        if (maxWidth / aspectRatio <= maxHeight) {
          width = maxWidth;
          height = maxWidth / aspectRatio;
        } else {
          height = maxHeight;
          width = maxHeight * aspectRatio;
        }

        // Show preview mode if enabled
        if (_showPreview) {
          return Stack(
            children: [
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: _screenSettings.backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Render all the components in preview mode
                    ..._screenComponents.map((component) {
                      // Render based on component type
                      switch (component['type']) {
                        case 'Text':
                          return Positioned(
                            left: component['position'].dx,
                            top: component['position'].dy,
                            child: Transform.rotate(
                              angle: component['rotation'] ?? 0.0,
                              child: Text(
                                component['text'] ?? 'Text',
                                style: TextStyle(
                                  fontSize: component['fontSize'] ?? 16.0,
                                  fontWeight: component['isBold']
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontStyle: component['isItalic']
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  decoration: component['isUnderlined']
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  color: component['color'] ?? Colors.black,
                                ),
                              ),
                            ),
                          );
                        case 'Button':
                          return Positioned(
                            left: component['position'].dx,
                            top: component['position'].dy,
                            child: Transform.rotate(
                              angle: component['rotation'] ?? 0.0,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      component['color'] ?? Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: Text(component['text'] ?? 'Button'),
                              ),
                            ),
                          );
                        case 'Container':
                          return Positioned(
                            left: component['position'].dx,
                            top: component['position'].dy,
                            child: Transform.rotate(
                              angle: component['rotation'] ?? 0.0,
                              child: Container(
                                width: component['width'] ?? 100,
                                height: component['height'] ?? 50,
                                decoration: BoxDecoration(
                                  color: component['color'] ?? Colors.grey,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                        component['borderRadiusTopLeft'] ??
                                            4.0),
                                    topRight: Radius.circular(
                                        component['borderRadiusTopRight'] ??
                                            4.0),
                                    bottomLeft: Radius.circular(
                                        component['borderRadiusBottomLeft'] ??
                                            4.0),
                                    bottomRight: Radius.circular(
                                        component['borderRadiusBottomRight'] ??
                                            4.0),
                                  ),
                                  boxShadow: component['hasShadow'] == true
                                      ? [
                                          BoxShadow(
                                            color: component['shadowColor'] ??
                                                Colors.black.withOpacity(0.3),
                                            blurRadius:
                                                component['shadowBlur'] ?? 10.0,
                                            spreadRadius: component[
                                                    'shadowSpreadRadius'] ??
                                                0.0,
                                            offset: Offset(
                                              component['shadowOffsetX'] ?? 0.0,
                                              component['shadowOffsetY'] ?? 4.0,
                                            ),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          );
                        case 'Image':
                          return Positioned(
                            left: component['position'].dx,
                            top: component['position'].dy,
                            child: Transform.rotate(
                              angle: component['rotation'] ?? 0.0,
                              child: Container(
                                width: component['width'] ?? 100,
                                height: component['height'] ?? 100,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: component['imageData'] != null
                                        ? MemoryImage(component['imageData'])
                                        : const AssetImage(
                                                'assets/placeholder_image.png')
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          );
                        case 'Burger Menu':
                          return Positioned(
                            left: component['position'].dx,
                            top: component['position'].dy,
                            child: Transform.rotate(
                              angle: component['rotation'] ?? 0.0,
                              child: Column(
                                children: List.generate(
                                  3,
                                  (index) => Container(
                                    width: 30,
                                    height: component['lineThickness'] ?? 3.0,
                                    margin: EdgeInsets.only(
                                      bottom: index < 2
                                          ? component['lineSpacing'] ?? 5.0
                                          : 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: component['menuColor'] ??
                                          Colors.black87,
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        default:
                          return const SizedBox.shrink();
                      }
                    }).toList(),
                  ],
                ),
              ),
              // Add exit preview button
              Positioned(
                top: 10,
                right: 10,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showPreview = false;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Exit Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          );
        }

        return DragTarget<Map<String, dynamic>>(
          onAccept: (data) {
            setState(() {
              // Create a copy of the data with position
              final componentData = Map<String, dynamic>.from(data);
              // Add unique ID
              componentData['id'] = _generateElementId(componentData['type'] ?? 'element');
              // Position at left top of the page by default
              componentData['position'] = const Offset(10, 10);
              componentData['rotation'] = 0.0; // Initialize rotation
              componentData['lineThickness'] =
                  3.0; // Default line thickness for burger menu
              componentData['lineSpacing'] =
                  5.0; // Default line spacing for burger menu
              componentData['menuColor'] =
                  Colors.black87; // Default color for burger menu

              // Add default onClick interaction with Node action for burger menu
              if (componentData['type'] == 'Burger Menu') {
                componentData['interactions'] = [
                  {
                    'type': 'on_click',
                    'name': 'onClick',
                    'status': 'Node action',
                    'selected': false,
                    'actions': [
                      {
                        'type': 'node',
                        'name': 'Node Action',
                        'target': '',
                        'enabled': true
                      }
                    ]
                  }
                ];
              }

              // Add the component to the screen
              _screenComponents.add(componentData);
            });
          },
          builder: (context, candidateData, rejectedData) {
            return MouseRegion(
              cursor: _selectedToolIndex == 7
                  ? SystemMouseCursors.precise
                  : _currentCursor,
              child: GestureDetector(
                // Handle container drawing
                onPanStart: _selectedToolIndex == 7
                    ? (details) {
                        setState(() {
                          _isDrawingContainer = true;
                          _containerStartPoint = details.localPosition;
                          _containerEndPoint = details.localPosition;

                          // Deselect all components when starting to draw
                          for (var comp in _screenComponents) {
                            comp['selected'] = false;
                          }
                        });
                      }
                    : null,
                onPanUpdate: _selectedToolIndex == 7
                    ? (details) {
                        setState(() {
                          _containerEndPoint = details.localPosition;
                        });
                      }
                    : null,
                onPanEnd: _selectedToolIndex == 7
                    ? (details) {
                        setState(() {
                          if (_containerStartPoint != null &&
                              _containerEndPoint != null) {
                            // Calculate the rectangle dimensions
                            final left = min(_containerStartPoint!.dx,
                                _containerEndPoint!.dx);
                            final top = min(_containerStartPoint!.dy,
                                _containerEndPoint!.dy);
                            final width = (_containerEndPoint!.dx -
                                    _containerStartPoint!.dx)
                                .abs();
                            final height = (_containerEndPoint!.dy -
                                    _containerStartPoint!.dy)
                                .abs();

                            // Only create container if it has meaningful dimensions
                            if (width > 10 && height > 10) {
                              // Create a new container component
                              final containerData = {
                                'id': _generateElementId('Container'),
                                'type': 'Container',
                                'name': 'Container',
                                'position': Offset(left, top),
                                'width': width,
                                'height': height,
                                'rotation': 0.0,
                                'color': Colors.black,
                                'selected': true,
                                'borderRadiusTopLeft': 4.0,
                                'borderRadiusTopRight': 4.0,
                                'borderRadiusBottomLeft': 4.0,
                                'borderRadiusBottomRight': 4.0,
                                'linkCorners': false,
                                'hasShadow': false,
                                'shadowColor': Colors.black.withOpacity(0.3),
                                'shadowBlur': 10.0,
                                'shadowSpreadRadius': 0.0,
                                'shadowOffsetX': 0.0,
                                'shadowOffsetY': 4.0,
                              };

                              // Add the container to the screen
                              _screenComponents.add(containerData);
                            }
                          }

                          // Reset drawing state
                          _isDrawingContainer = false;
                          _containerStartPoint = null;
                          _containerEndPoint = null;
                        });
                      }
                    : null,
                // Handle tap for selection
                onTap: () {
                  setState(() {
                    // Only handle taps for tools other than container drawing
                    if (_selectedToolIndex != 7) {
                      // Deselect all components
                      for (var comp in _screenComponents) {
                        comp['selected'] = false;
                      }
                    }
                  });
                },
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: _screenSettings.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    // Add tap handler to deselect all components when clicking on the canvas
                    onTap: () {
                      setState(() {
                        // Deselect all components
                        for (var comp in _screenComponents) {
                          comp['selected'] = false;
                        }
                      });
                    },
                    child: MouseRegion(
                      cursor: _currentCursor,
                      onHover: (event) {
                        // Reset cursor state
                        bool isCornerHovered = false;
                        bool isRotateCornerHovered = false;

                        // Check if we're hovering over a component corner
                        for (var component in _screenComponents) {
                          if (component['selected'] == true) {
                            final position = component['position'] as Offset;
                            final size = component['type'] == 'Burger Menu'
                                ? const Size(40, 40)
                                : const Size(100, 50);

                            // Check if mouse is near the bottom-right corner (resize)
                            final bottomRight = Offset(position.dx + size.width,
                                position.dy + size.height);
                            if ((event.localPosition - bottomRight).distance <
                                20) {
                              isCornerHovered = true;
                            }

                            // Check if mouse is near the top-right corner (rotate)
                            final topRight =
                                Offset(position.dx + size.width, position.dy);
                            if ((event.localPosition - topRight).distance <
                                20) {
                              isRotateCornerHovered = true;
                            }
                          }
                        }

                        setState(() {
                          _isCornerHovered = isCornerHovered;
                          _isRotateCornerHovered = isRotateCornerHovered;

                          if (isRotateCornerHovered) {
                            _currentCursor = SystemMouseCursors
                                .grab; // Use grab cursor for rotation
                          } else if (isCornerHovered) {
                            _currentCursor = SystemMouseCursors.resizeDownRight;
                          } else {
                            _currentCursor = SystemMouseCursors.basic;
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          // Display all components on the screen
                          ..._screenComponents.map((component) {
                            return Positioned(
                              left: (component['position'] as Offset).dx,
                              top: (component['position'] as Offset).dy,
                              child: Transform.rotate(
                                angle:
                                    ((component['rotation'] as double? ?? 0.0) *
                                        3.14159 /
                                        180),
                                child: _buildComponentWidget(component),
                              ),
                            );
                          }).toList(),

                          // Drawing overlay for container when actively drawing
                          if (_isDrawingContainer &&
                              _containerStartPoint != null &&
                              _containerEndPoint != null)
                            Positioned(
                              left: min(_containerStartPoint!.dx,
                                  _containerEndPoint!.dx),
                              top: min(_containerStartPoint!.dy,
                                  _containerEndPoint!.dy),
                              width: (_containerEndPoint!.dx -
                                      _containerStartPoint!.dx)
                                  .abs(),
                              height: (_containerEndPoint!.dy -
                                      _containerStartPoint!.dy)
                                  .abs(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                          // Guidelines and position indicators
                          if (_showGuidelines && _movingComponent != null) ...[
                            // Horizontal center guideline
                            if (_isHorizontalCentered)
                              Positioned(
                                left: 0,
                                top: _screenSettings.height / 2,
                                width: _screenSettings.width,
                                height: 1,
                                child: Container(
                                  color: Colors.red,
                                ),
                              ),

                            // Vertical center guideline
                            if (_isVerticalCentered)
                              Positioned(
                                left: _screenSettings.width / 2,
                                top: 0,
                                width: 1,
                                height: _screenSettings.height,
                                child: Container(
                                  color: Colors.red,
                                ),
                              ),

                            // Distance indicators
                            // Top distance
                            if (_distanceFromTop != null)
                              Positioned(
                                left: (_movingComponent!['position'] as Offset)
                                        .dx +
                                    (_movingComponent!['type'] == 'Burger Menu'
                                        ? 20.0
                                        : (_movingComponent!['width']
                                                    as double? ??
                                                50.0) /
                                            2),
                                top: 0,
                                height: _distanceFromTop,
                                child: Container(
                                  width: 1,
                                  color: Colors.blue.withOpacity(0.7),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: _distanceFromTop! / 2 - 10,
                                        left: -14,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.7),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          child: Text(
                                            '${_distanceFromTop!.round()} px',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Left distance
                            if (_distanceFromLeft != null)
                              Positioned(
                                left: 0,
                                top: (_movingComponent!['position'] as Offset)
                                        .dy +
                                    (_movingComponent!['type'] == 'Burger Menu'
                                        ? 20.0
                                        : (_movingComponent!['height']
                                                    as double? ??
                                                25.0) /
                                            2),
                                width: _distanceFromLeft,
                                child: Container(
                                  height: 1,
                                  color: Colors.blue.withOpacity(0.7),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: _distanceFromLeft! / 2 - 10,
                                        top: -14,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.7),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          child: Text(
                                            '${_distanceFromLeft!.round()} px',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Right distance
                            if (_distanceFromRight != null)
                              Positioned(
                                left: (_movingComponent!['position'] as Offset)
                                        .dx +
                                    (_movingComponent!['type'] == 'Burger Menu'
                                        ? 40.0
                                        : (_movingComponent!['width']
                                                as double? ??
                                            100.0)),
                                top: (_movingComponent!['position'] as Offset)
                                        .dy +
                                    (_movingComponent!['type'] == 'Burger Menu'
                                        ? 20.0
                                        : (_movingComponent!['height']
                                                    as double? ??
                                                25.0) /
                                            2),
                                width: _distanceFromRight,
                                child: Container(
                                  height: 1,
                                  color: Colors.blue.withOpacity(0.7),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: _distanceFromRight! / 2 - 10,
                                        top: -14,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.7),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          child: Text(
                                            '${_distanceFromRight!.round()} px',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Bottom distance
                            if (_distanceFromBottom != null)
                              Positioned(
                                left: (_movingComponent!['position'] as Offset)
                                        .dx +
                                    (_movingComponent!['type'] == 'Burger Menu'
                                        ? 20.0
                                        : (_movingComponent!['width']
                                                    as double? ??
                                                50.0) /
                                            2),
                                top: (_movingComponent!['position'] as Offset)
                                        .dy +
                                    (_movingComponent!['type'] == 'Burger Menu'
                                        ? 40.0
                                        : (_movingComponent!['height']
                                                as double? ??
                                            50.0)),
                                height: _distanceFromBottom,
                                child: Container(
                                  width: 1,
                                  color: Colors.blue.withOpacity(0.7),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: _distanceFromBottom! / 2 - 10,
                                        left: -14,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.7),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          child: Text(
                                            '${_distanceFromBottom!.round()} px',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],

                          // Screen dimensions indicator
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${_screenSettings.width.round()} × ${_screenSettings.height.round()}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          // Show a hint when dragging over
                          if (candidateData.isNotEmpty)
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.blue.withOpacity(0.1),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Drop to add component',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to build a component widget based on its type
  Widget _buildComponentWidget(Map<String, dynamic> component) {
    final type = component['type'] as String;
    final assetPath = component['assetPath'] as String?;
    final isSelected = component['selected'] == true;
    final lineThickness = component['lineThickness'] as double? ?? 3.0;
    final lineSpacing = component['lineSpacing'] as double? ?? 5.0;
    final menuColor = component['menuColor'] as Color? ?? Colors.black87;

    if (type == 'Burger Menu') {
      return MouseRegion(
        onEnter: (_) {
          setState(() {
            if (!_isResizing && !_isRotating) {
              _currentCursor = SystemMouseCursors.move;
            }
          });
        },
        onExit: (_) {
          setState(() {
            if (!_isResizing &&
                !_isRotating &&
                !_isCornerHovered &&
                !_isRotateCornerHovered) {
              _currentCursor = SystemMouseCursors.basic;
            }
          });
        },
        child: GestureDetector(
          onTap: () {
            setState(() {
              // Only allow selection and expansion if not currently resizing, moving, or rotating
              if (_canExpand) {
                // Deselect all components
                for (var comp in _screenComponents) {
                  comp['selected'] = false;
                }
                // Select this component
                component['selected'] = true;
                _isScreenSelected = true;
                _selectedRightTab = 'Style';

                // Reset interaction panel state when selecting a component
                _showInteractionDetails = false;
                _selectedInteractionIndex = null;
              }
            });

            // Execute any onClick interactions
            _executeComponentInteraction(component, 'on_click');
          },
          onPanStart: (details) {
            // Check if we're near the corners for resizing or rotating
            final size = const Size(40, 40);
            final bottomRight = Offset(size.width, size.height);
            final topRight = Offset(size.width, 0);

            if ((details.localPosition - topRight).distance < 20) {
              // Top-right corner - rotation
              setState(() {
                _isRotating = true;
                _isResizing = false;
                _isMoving = false;
                _canExpand = false; // Disable expand during rotation
                _currentCursor =
                    SystemMouseCursors.grab; // Use grab cursor for rotation
              });
            } else if ((details.localPosition - bottomRight).distance < 20) {
              // Bottom-right corner - resizing
              setState(() {
                _isResizing = true;
                _isRotating = false;
                _isMoving = false;
                _canExpand = false; // Disable expand during resize
                _currentCursor = SystemMouseCursors.resizeDownRight;
              });
            } else {
              // Middle - moving
              setState(() {
                _isMoving = true;
                _isResizing = false;
                _isRotating = false;
                _canExpand = false; // Disable expand during move
                _currentCursor = SystemMouseCursors.move;
                _showGuidelines = true;
                _movingComponent = component;
                _updateGuidelineDistances(component);
              });
            }
          },
          onPanUpdate: (details) {
            if (_isRotating) {
              // Handle rotation logic
              setState(() {
                // Calculate rotation based on the component's center
                final center = Offset(20, 20); // Half of the 40x40 size

                // Calculate the angle between the center and the current position
                final angle = atan2(
                      details.localPosition.dy - center.dy,
                      details.localPosition.dx - center.dx,
                    ) *
                    (180 / pi);

                // Normalize angle to 0-360 range
                double normalizedAngle = angle;
                if (normalizedAngle < 0) {
                  normalizedAngle += 360;
                }
                normalizedAngle = normalizedAngle % 360;

                // Update the rotation
                component['rotation'] = normalizedAngle;

                _currentCursor = SystemMouseCursors
                    .grabbing; // Use grabbing cursor during active rotation
              });
            } else if (_isResizing) {
              // Handle resizing logic (would need to implement size in component data)
              setState(() {
                // For now, we're just changing the cursor
                _currentCursor = SystemMouseCursors.resizeDownRight;
              });
            } else if (_isMoving) {
              // Handle moving the component
              setState(() {
                final currentPosition = component['position'] as Offset;
                final newPosition = Offset(
                  currentPosition.dx + details.delta.dx,
                  currentPosition.dy + details.delta.dy,
                );
                component['position'] = newPosition;

                // Update guidelines
                _updateGuidelineDistances(component);
              });
            }
          },
          onPanEnd: (_) {
            setState(() {
              _isResizing = false;
              _isMoving = false;
              _isRotating = false;
              _canExpand = true; // Re-enable expand after interaction ends
              _currentCursor = SystemMouseCursors.basic;
              _showGuidelines = false;
              _movingComponent = null;
              _distanceFromTop = null;
              _distanceFromLeft = null;
              _distanceFromRight = null;
              _distanceFromBottom = null;
              _isHorizontalCentered = false;
              _isVerticalCentered = false;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border:
                  isSelected ? Border.all(color: Colors.blue, width: 2) : null,
            ),
            child: Stack(
              children: [
                // Burger menu lines - always visible regardless of selection
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize:
                        MainAxisSize.min, // Fix unbounded height constraint
                    children: [
                      Container(
                        width: 24,
                        height: lineThickness,
                        color: menuColor,
                      ),
                      SizedBox(height: lineSpacing),
                      Container(
                        width: 24,
                        height: lineThickness,
                        color: menuColor,
                      ),
                      SizedBox(height: lineSpacing),
                      Container(
                        width: 24,
                        height: lineThickness,
                        color: menuColor,
                      ),
                    ],
                  ),
                ),

                // Rotation handle in top-right corner - only visible when selected
                if (isSelected)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: const Icon(
                        Icons.rotate_right,
                        color: Colors.blue,
                        size: 8,
                      ),
                    ),
                  ),

                // Resize handle in bottom-right corner - only visible when selected
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: const Icon(
                        Icons.open_in_full,
                        color: Colors.blue,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else if (type == 'Container') {
      // Get the container dimensions
      final width = component['width'] as double;
      final height = component['height'] as double;

      // Get border radius values (or use defaults)
      final topLeftRadius = component['borderRadiusTopLeft'] as double? ?? 4.0;
      final topRightRadius =
          component['borderRadiusTopRight'] as double? ?? 4.0;
      final bottomLeftRadius =
          component['borderRadiusBottomLeft'] as double? ?? 4.0;
      final bottomRightRadius =
          component['borderRadiusBottomRight'] as double? ?? 4.0;

      return MouseRegion(
        onEnter: (_) {
          setState(() {
            if (!_isResizing && !_isRotating) {
              _currentCursor = SystemMouseCursors.move;
            }
          });
        },
        onExit: (_) {
          setState(() {
            if (!_isResizing &&
                !_isRotating &&
                !_isCornerHovered &&
                !_isRotateCornerHovered) {
              _currentCursor = SystemMouseCursors.basic;
            }
          });
        },
        child: GestureDetector(
          onTap: () {
            setState(() {
              // Only allow selection and expansion if not currently resizing, moving, or rotating
              if (_canExpand) {
                // Deselect all components
                for (var comp in _screenComponents) {
                  comp['selected'] = false;
                }
                // Select this component
                component['selected'] = true;
                _isScreenSelected = true;
                _selectedRightTab = 'Style';
              }
            });
          },
          onPanStart: (details) {
            // Check if we're near the corners for resizing or rotating
            final bottomRight = Offset(width, height);
            final topRight = Offset(width, 0);

            if ((details.localPosition - topRight).distance < 20) {
              // Top-right corner - rotation
              setState(() {
                _isRotating = true;
                _isResizing = false;
                _isMoving = false;
                _canExpand = false; // Disable expand during rotation
                _currentCursor = SystemMouseCursors.grab;
              });
            } else if ((details.localPosition - bottomRight).distance < 20) {
              // Bottom-right corner - resizing
              setState(() {
                _isResizing = true;
                _isRotating = false;
                _isMoving = false;
                _canExpand = false; // Disable expand during resize
                _currentCursor = SystemMouseCursors.resizeDownRight;
              });
            } else {
              // Middle - moving
              setState(() {
                _isMoving = true;
                _isResizing = false;
                _isRotating = false;
                _canExpand = false; // Disable expand during move
                _currentCursor = SystemMouseCursors.move;
                _showGuidelines = true;
                _movingComponent = component;
                _updateGuidelineDistances(component);
              });
            }
          },
          onPanUpdate: (details) {
            if (_isRotating) {
              setState(() {
                // Calculate rotation based on the component's center
                final centerX = width / 2;
                final centerY = height / 2;

                // Calculate the angle between the center and the current position
                final dx = details.localPosition.dx - centerX;
                final dy = details.localPosition.dy - centerY;
                final angle = atan2(dy, dx) * (180 / pi);

                // Normalize angle to 0-360 range
                double normalizedAngle = angle;
                if (normalizedAngle < 0) {
                  normalizedAngle += 360;
                }
                normalizedAngle = normalizedAngle.clamp(0.0, 360.0);

                // Update the rotation with normalized angle
                component['rotation'] = normalizedAngle;

                _currentCursor = SystemMouseCursors.grabbing;
              });
            } else if (_isResizing) {
              setState(() {
                // Update width and height with resize
                final newWidth = max(20.0, width + details.delta.dx);
                final newHeight = max(20.0, height + details.delta.dy);
                component['width'] = newWidth;
                component['height'] = newHeight;

                _currentCursor = SystemMouseCursors.resizeDownRight;
              });
            } else if (_isMoving) {
              // Handle moving the component
              setState(() {
                final currentPosition = component['position'] as Offset;
                final newPosition = Offset(
                  currentPosition.dx + details.delta.dx,
                  currentPosition.dy + details.delta.dy,
                );
                component['position'] = newPosition;

                // Update guidelines
                _updateGuidelineDistances(component);
              });
            }
          },
          onPanEnd: (_) {
            setState(() {
              _isResizing = false;
              _isMoving = false;
              _isRotating = false;
              _canExpand = true; // Re-enable expand after interaction ends
              _currentCursor = SystemMouseCursors.basic;
              _showGuidelines = false;
              _movingComponent = null;
              _distanceFromTop = null;
              _distanceFromLeft = null;
              _distanceFromRight = null;
              _distanceFromBottom = null;
              _isHorizontalCentered = false;
              _isVerticalCentered = false;
            });
          },
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: component['color'] as Color? ?? Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(topLeftRadius),
                topRight: Radius.circular(topRightRadius),
                bottomLeft: Radius.circular(bottomLeftRadius),
                bottomRight: Radius.circular(bottomRightRadius),
              ),
              border:
                  isSelected ? Border.all(color: Colors.blue, width: 2) : null,
              boxShadow: component['hasShadow'] == true
                  ? [
                      BoxShadow(
                        color: component['shadowColor'] as Color? ??
                            Colors.black.withOpacity(0.3),
                        blurRadius: component['shadowBlur'] as double? ?? 10.0,
                        spreadRadius:
                            component['shadowSpreadRadius'] as double? ?? 0.0,
                        offset: Offset(
                          component['shadowOffsetX'] as double? ?? 0.0,
                          component['shadowOffsetY'] as double? ?? 4.0,
                        ),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Rotation handle in top-right corner - only visible when selected
                if (isSelected)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: const Icon(
                        Icons.rotate_right,
                        color: Colors.blue,
                        size: 8,
                      ),
                    ),
                  ),

                // Resize handle in bottom-right corner - only visible when selected
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: const Icon(
                        Icons.open_in_full,
                        color: Colors.blue,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else if (type == 'Fan Menu') {
      // Similar implementation for Fan Menu with cursor changes
      // ... existing code ...
    }

    // Default fallback for other component types
    return GestureDetector(
      onTap: () {
        setState(() {
          // Only allow selection and expansion if not currently resizing, moving, or rotating
          if (_canExpand) {
            // Deselect all components
            for (var comp in _screenComponents) {
              comp['selected'] = false;
            }
            // Select this component
            component['selected'] = true;
            _isScreenSelected = true;
            _selectedRightTab = 'Style';
          }
        });
      },
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey,
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Center(
          child: Text(
            component['name'] as String,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Add method to reset zoom
  void _resetZoom() {
    setState(() {
      _currentZoom = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  // Update the zoom controls widget
  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Row(
        children: [
          // Toolbar
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolbarButton(0, Icons.mouse, 'Select'),
                _buildToolbarButton(1, Icons.pan_tool_outlined, 'Pan'),
                _buildToolbarButton(
                    2, Icons.desktop_windows_outlined, 'Screen'),
                _buildToolbarButton(3, Icons.laptop_outlined, 'Responsive'),
                _buildToolbarButton(4, Icons.text_fields, 'Text'),
                _buildToolbarButton(5, Icons.crop_square_outlined, 'Shape'),
                _buildToolbarButton(6, Icons.videocam_outlined, 'Media'),
                _buildToolbarButton(7, Icons.square_outlined, 'Container'),
              ],
            ),
          ),
          // Zoom controls
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white70),
                  onPressed: () {
                    final zoom = _currentZoom - 0.1;
                    if (zoom >= _minZoom) {
                      setState(() {
                        _currentZoom = zoom;
                        _transformationController.value = Matrix4.identity()
                          ..scale(_currentZoom);
                      });
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                GestureDetector(
                  onTap: _resetZoom,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(_currentZoom * 100).round()}%',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white70),
                  onPressed: () {
                    final zoom = _currentZoom + 0.1;
                    if (zoom <= _maxZoom) {
                      setState(() {
                        _currentZoom = zoom;
                        _transformationController.value = Matrix4.identity()
                          ..scale(_currentZoom);
                      });
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Update the _buildColorOption method
  Widget _buildColorOption(Color color) {
    final bool isSelected = _screenSettings.backgroundColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _screenSettings.backgroundColor = color;
          _updateHexFromColor(color);
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  // Helper method for container color options
  Widget _buildColorOptionForContainer(
      Color color, Map<String, dynamic> component) {
    final bool isSelected =
        (component['color'] as Color?)?.value == color.value;

    return GestureDetector(
      onTap: () {
        setState(() {
          component['color'] = color;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  void _updateGuidelineDistances(Map<String, dynamic> component) {
    final position = component['position'] as Offset;
    final width = component['type'] == 'Burger Menu'
        ? 40.0
        : (component['width'] as double? ?? 100.0);
    final height = component['type'] == 'Burger Menu'
        ? 40.0
        : (component['height'] as double? ?? 50.0);

    // Calculate distances from edges
    _distanceFromTop = position.dy;
    _distanceFromLeft = position.dx;
    _distanceFromRight = _screenSettings.width - (position.dx + width);
    _distanceFromBottom = _screenSettings.height - (position.dy + height);

    // Calculate center alignment
    final centerX = position.dx + (width / 2);
    final centerY = position.dy + (height / 2);
    final screenCenterX = _screenSettings.width / 2;
    final screenCenterY = _screenSettings.height / 2;

    // Check if component is centered (within 5 pixels of center)
    _isHorizontalCentered = (centerX - screenCenterX).abs() < 5;
    _isVerticalCentered = (centerY - screenCenterY).abs() < 5;
  }

  // Helper method to execute component interactions

  // }

  // 2. In the animation list onTap, set _selectedAnimationIndex
  Widget _buildKeyframeBar() {
    if (_selectedAnimationIndex == null ||
        _selectedAnimationIndex! >= _animations.length) {
      return Container(
        height: 140, // Increased height
        decoration: BoxDecoration(
          color: const Color(0xFF181A1B),
          border:
              const Border(top: BorderSide(color: Color(0xFF232323), width: 2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'NO ANIMATION SELECTED',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );
    }
    final anim = _animations[_selectedAnimationIndex!];
    final List<int> keyframes = List<int>.from(anim['keyframes'] ?? []);
    const int totalFrames = 100;
    const double barHeight = 140; // Increased height
    const double timelineHeight = 70;
    const double rulerHeight = 32;
    const double frameWidth = 10.0;
    final int playheadFrame = _selectedFrame;
    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF181A1B),
        border:
            const Border(top: BorderSide(color: Color(0xFF232323), width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animation name and controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                Icon(Icons.movie, color: Colors.blue, size: 22),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    anim['name'] ?? 'Animation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Recording toggle button
                IconButton(
                  icon: Icon(
                    Icons.fiber_manual_record,
                    color: _isRecording ? Colors.red : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isRecording = !_isRecording;
                      
                      // If starting recording, immediately create a keyframe at current frame
                      if (_isRecording) {
                        if (_selectedAnimationIndex != null && _selectedAnimationIndex! < _animations.length) {
                          _createKeyframeAtCurrentFrame();
                          // Show feedback that keyframe was created
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Keyframe created at frame $_selectedFrame'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          // Show warning if no animation is selected
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No animation selected. Please select an animation before recording.'),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    });
                  },
                  tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
                ),
                // Recording status indicator
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          color: Colors.red,
                          size: 8,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'REC',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Keyframe count indicator
                if (_selectedAnimationIndex != null && _selectedAnimationIndex! < _animations.length)
                  Tooltip(
                    message: 'Keyframes: ${(_animations[_selectedAnimationIndex!]['keyframes'] as List<dynamic>?)?.length ?? 0}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.diamond,
                            color: Colors.amber,
                            size: 8,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${(_animations[_selectedAnimationIndex!]['keyframes'] as List<dynamic>?)?.length ?? 0}',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Run animation button
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.green,
                    size: 20,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _stopAnimation();
                    } else {
                      _playAnimation();
                    }
                  },
                  tooltip: _isPlaying ? 'Pause Animation' : 'Play Animation',
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.skip_previous,
                      color: Colors.white70, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedFrame =
                          (_selectedFrame - 1).clamp(0, totalFrames - 1);
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  onPressed: () {
                    // Optionally implement playback
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.skip_next, color: Colors.white70, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedFrame =
                          (_selectedFrame + 1).clamp(0, totalFrames - 1);
                    });
                  },
                ),
                const SizedBox(width: 16),
                Icon(Icons.settings, color: Colors.white24, size: 20),
                ],
              ),
            ),
          ),
          // Timeline ruler and keyframes
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  final local = details.localPosition.dx;
                  int frame =
                      (local / frameWidth).round().clamp(0, totalFrames - 1);
                  setState(() {
                    _selectedFrame = frame;
                  });
                },
                onTapDown: (details) {
                  final local = details.localPosition.dx;
                  int frame =
                      (local / frameWidth).round().clamp(0, totalFrames - 1);
                  setState(() {
                    _selectedFrame = frame;
                  });
                },
                child: Stack(
                  children: [
                    // Ruler
                    Positioned.fill(
                      top: 0,
                      child: CustomPaint(
                        painter: _TimelineRulerPainter(
                          totalFrames: totalFrames,
                          frameWidth: frameWidth,
                          rulerHeight: rulerHeight,
                        ),
                      ),
                    ),
                    // Keyframes
                    Positioned(
                      top: rulerHeight,
                      left: 0,
                      right: 0,
                      height: timelineHeight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(totalFrames, (i) {
                            final isKey = keyframes.contains(i);
                            final isPlayhead = i == playheadFrame;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  // Set the selected frame first
                                  _selectedFrame = i;
                                  
                                  if (isKey) {
                                    // Remove existing keyframe
                                    keyframes.remove(i);
                                    _animations[_selectedAnimationIndex!]['keyframes'] = keyframes;
                                    
                                    // Also remove frame data if it exists
                                    final frameData = _animations[_selectedAnimationIndex!]['frame_data'];
                                    if (frameData != null) {
                                      frameData.remove('frame_$i');
                                    }
                                  } else {
                                    // Add new keyframe
                                    keyframes.add(i);
                                    keyframes.sort();
                                    _animations[_selectedAnimationIndex!]['keyframes'] = keyframes;
                                    
                                    // If recording is enabled, save current element state
                                    if (_isRecording) {
                                      print('Recording enabled - creating keyframe at frame $i');
                                      final selectedElements = _screenComponents.where((c) => c['selected'] == true).toList();
                                      if (selectedElements.isNotEmpty) {
                                        print('Found ${selectedElements.length} selected elements to record');
                                        final frameData = <String, dynamic>{};
                                        for (final element in selectedElements) {
                                          final elementId = element['id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
                                          frameData[elementId] = {
                                            'id': elementId,
                                            'type': element['type'],
                                            'position': element['position'] ?? Offset.zero,
                                            'rotation': element['rotation'] ?? 0.0,
                                            'scale': element['scale'] ?? 1.0,
                                            'opacity': element['opacity'] ?? 1.0,
                                            'name': element['name'],
                                          };
                                        }
                                        
                                        // Store frame data in animation
                                        if (_animations[_selectedAnimationIndex!]['frame_data'] == null) {
                                          _animations[_selectedAnimationIndex!]['frame_data'] = <String, dynamic>{};
                                        }
                                        _animations[_selectedAnimationIndex!]['frame_data']['frame_$i'] = frameData;
                                        print('Saved keyframe data for frame $i');
                                      } else {
                                        print('No elements selected - cannot record keyframe');
                                      }
                                    } else {
                                      print('Recording disabled - keyframe created without element data');
                                    }
                                  }
                                });
                              },
                              onDoubleTap: () {
                                if (isKey && _hasKeyframeData(i)) {
                                  _showKeyframeDetails(i);
                                }
                              },
                              child: SizedBox(
                                width: frameWidth,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isKey)
                                      Draggable<int>(
                                        data: i,
                                        feedback: Icon(Icons.diamond,
                                            size: 18, color: Colors.amber.withOpacity(0.8)),
                                        childWhenDragging: Icon(Icons.diamond,
                                            size: 18, color: Colors.amber.withOpacity(0.3)),
                                        child: Tooltip(
                                          message: _getKeyframeTooltip(i),
                                          child: Icon(
                                            Icons.diamond,
                                            size: 18,
                                            color: _hasKeyframeData(i) ? Colors.amber : Colors.amber.withOpacity(0.5),
                                          ),
                                        ),
                                        onDragEnd: (details) {
                                          // Calculate new frame position based on drag end position
                                          final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                          final localPosition = renderBox.globalToLocal(details.offset);
                                          final newFrame = (localPosition.dx / frameWidth).round().clamp(0, totalFrames - 1);
                                          
                                          if (newFrame != i && !keyframes.contains(newFrame)) {
                                            setState(() {
                                              keyframes.remove(i);
                                              keyframes.add(newFrame);
                                              keyframes.sort();
                                              _animations[_selectedAnimationIndex!]['keyframes'] = keyframes;
                                              
                                              // Move frame data if it exists
                                              final frameData = _animations[_selectedAnimationIndex!]['frame_data'];
                                              if (frameData != null) {
                                                final oldFrameData = frameData['frame_$i'];
                                                if (oldFrameData != null) {
                                                  frameData['frame_$newFrame'] = oldFrameData;
                                                  frameData.remove('frame_$i');
                                                }
                                              }
                                            });
                                          }
                                        },
                                      ),
                                    if (isPlayhead)
                                      Positioned(
                                        top: 0,
                                        child: Container(
                                          width: 4,
                                          height: timelineHeight,
                                          color: Colors.red,
                                        ),
                                      ),
                                    if (isPlayhead)
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          width: frameWidth,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    // Frame numbers (every 10 frames)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: rulerHeight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(totalFrames ~/ 10 + 1, (i) {
                            return SizedBox(
                              width: frameWidth * 10,
                              child: Center(
                                child: Text(
                                  '${i * 10}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Show selected frame
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 2, bottom: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Frame: $_selectedFrame',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// 3. Add a custom painter for the timeline ruler
class _TimelineRulerPainter extends CustomPainter {
  final int totalFrames;
  final double frameWidth;
  final double rulerHeight;
  _TimelineRulerPainter(
      {required this.totalFrames,
      required this.frameWidth,
      required this.rulerHeight});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF232323)
      ..strokeWidth = 1;
    for (int i = 0; i <= totalFrames; i++) {
      final x = i * frameWidth;
      final isMajor = i % 10 == 0;
      final tickHeight = isMajor ? rulerHeight : rulerHeight * 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, tickHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
