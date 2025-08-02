import 'package:astravision/Dashboard/ExternalFiles/ProjectDashboard/createNewProject_window.dart';
import 'package:astravision/Dashboard/HomeDashboard_page.dart';
import 'package:flutter/material.dart';
import '../services/project_opener.dart';
import '../services/project_service.dart';

enum ProjectType { design, animation, video, threeD }

class Project {
  final String title;
  final String thumbnail;
  final DateTime lastEdited;
  final ProjectType type;
  final String path;

  Project({
    required this.title,
    required this.thumbnail,
    required this.lastEdited,
    required this.type,
    required this.path,
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    const double spacing = 30;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ProjectService _projectService = ProjectService();
  List<Project> _projects = [];
  String _selectedFilter = 'All Projects';
  String _searchQuery = '';
  bool _isGridView = true;
  int _sortOption = 0; // 0: Last edited, 1: Name, 2: Type
  bool _isSidebarExpanded = true;
  int _selectedSidebarIndex = 1; // Projects is selected by default

  // Responsive breakpoints
  bool get _isSmallScreen => MediaQuery.of(context).size.width < 800;
  bool get _isMediumScreen =>
      MediaQuery.of(context).size.width < 1100 &&
      MediaQuery.of(context).size.width >= 800;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await _projectService.loadProjects();
    setState(() {
      _projects = projects;
    });
  }

  void _navigateToPage(int index, BuildContext context) {
    setState(() {
      _selectedSidebarIndex = index;
    });

    // Close sidebar on small screens after navigation
    if (_isSmallScreen) {
      setState(() {
        _isSidebarExpanded = false;
      });
    }

    // Handle navigation based on selected index
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeDashboardPage()),
        );
        break;
      case 1: // Projects

        break;
      case 2: // Assets
        // Navigate to Assets page when implemented
        break;
      case 3: // Community
        // Navigate to Community page when implemented
        break;
    }
  }

  List<Project> get _filteredProjects {
    return _projects.where((project) {
      // Filter by project type
      if (_selectedFilter != 'All Projects' &&
          !project.type.name.toLowerCase().contains(
                _selectedFilter.toLowerCase(),
              )) {
        return false;
      }

      // Filter by search
      if (_searchQuery.isNotEmpty &&
          !project.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        // Sort based on selected option
        switch (_sortOption) {
          case 0: // Last edited
            return b.lastEdited.compareTo(a.lastEdited);
          case 1: // Name
            return a.title.compareTo(b.title);
          case 2: // Type
            return a.type.name.compareTo(b.type.name);
          default:
            return 0;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Row(
        children: [
          // Sidebar
          if (!_isSmallScreen || _isSidebarExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _isSidebarExpanded
                  ? (_isSmallScreen
                      ? MediaQuery.of(context).size.width * 0.85
                      : 240)
                  : 70,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: _buildSidebar(),
            ),

          // Main content
          Expanded(
            child: Column(
              children: [
                _buildAppBar(),
                _buildFilterBar(),
                Expanded(
                  child: Stack(
                    children: [
                      // Grid pattern background
                      Opacity(
                        opacity: 0.05,
                        child: CustomPaint(
                          painter: GridPainter(),
                          size: Size(
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height,
                          ),
                        ),
                      ),

                      // Projects grid/list
                      _filteredProjects.isEmpty
                          ? _buildEmptyState()
                          : _isGridView
                              ? _buildProjectsGrid()
                              : _buildProjectsList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProject,
        backgroundColor: const Color(0xFF6E44FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        // Logo and app name
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6E44FF).withOpacity(0.3),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Color(0xFF6E44FF),
                ),
              ),
              if (_isSidebarExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: const Text(
                    'AstraVision',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (_isSmallScreen && _isSidebarExpanded) Spacer(),
              if (_isSmallScreen && _isSidebarExpanded)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSidebarExpanded = false;
                    });
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Menu items
        _buildSidebarItem(Icons.home_outlined, 'Home', 0),
        _buildSidebarItem(Icons.folder_outlined, 'Projects', 1),
        _buildSidebarItem(Icons.image_outlined, 'Assets', 2),
        _buildSidebarItem(Icons.people_outline, 'Community', 3),

        const SizedBox(height: 16),
        const Divider(color: Color(0xFF2A2A2A)),
        const SizedBox(height: 16),

        // Recent projects section
        if (_isSidebarExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECENT PROJECTS',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                // Recent projects list
                ..._projects
                    .take(3)
                    .map((project) => _buildRecentProjectItem(project))
                    .toList(),
              ],
            ),
          ),

        const Spacer(),

        // User profile
        if (_isSidebarExpanded)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alex Morgan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pro Account',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.grey,
                    size: 18,
                  ),
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final isSelected = _selectedSidebarIndex == index;

    return InkWell(
      onTap: () => _navigateToPage(index, context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6E44FF).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6E44FF) : Colors.grey[400],
              size: 20,
            ),
            if (_isSidebarExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isSelected ? const Color(0xFF6E44FF) : Colors.grey[300],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjectItem(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getProjectColor(project.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getProjectIcon(project.type),
                size: 16,
                color: _getProjectColor(project.type),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatLastEdited(project.lastEdited),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sidebar toggle for small screens
          if (_isSmallScreen)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSidebarExpanded = true;
                });
              },
            ),

          // Page title
          Text(
            'Projects',
            style: TextStyle(
              fontSize: _isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const Spacer(),

          // Search bar (hidden on small screens)
          if (!_isSmallScreen)
            Container(
              width: _isMediumScreen ? 180 : 240,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

          // Action buttons
          if (!_isSmallScreen)
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.grey[300]),
              onPressed: () {},
            ),

          // Search icon for small screens
          if (_isSmallScreen)
            IconButton(
              icon: Icon(Icons.search, color: Colors.grey[300]),
              onPressed: () {
                // Show search modal
              },
            ),

          // User avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF6E44FF).withOpacity(0.2),
            child: const Icon(Icons.person, size: 18, color: Color(0xFF6E44FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          // Project type filter
          Container(
            padding: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedFilter,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 20,
              ),
              underline: Container(),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              hint: const Text(
                'Filter by',
                style: TextStyle(color: Colors.grey),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFilter = newValue!;
                });
              },
              items: <String>[
                'All Projects',
                'Design',
                'Animation',
                'Video',
                '3D',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      if (value != 'All Projects')
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            _getFilterIcon(value),
                            size: 16,
                            color: _getFilterColor(value),
                          ),
                        ),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          if (!_isSmallScreen)
            // Sort options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Sort:',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _sortOption,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                      size: 20,
                    ),
                    underline: Container(),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (int? newValue) {
                      setState(() {
                        _sortOption = newValue!;
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Last edited')),
                      DropdownMenuItem(value: 1, child: Text('Name')),
                      DropdownMenuItem(value: 2, child: Text('Type')),
                    ],
                  ),
                ],
              ),
            ),

          const Spacer(),

          // View toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildViewToggleButton(Icons.grid_view_rounded, true),
                _buildViewToggleButton(Icons.view_list_rounded, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(IconData icon, bool isGrid) {
    final isSelected = _isGridView == isGrid;

    return InkWell(
      onTap: () {
        setState(() {
          _isGridView = isGrid;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6E44FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[400],
          size: 18,
        ),
      ),
    );
  }

  Widget _buildProjectsGrid() {
    // Adjust grid based on screen size
    int crossAxisCount = 3;
    if (_isSmallScreen) {
      crossAxisCount = 1;
    } else if (_isMediumScreen) {
      crossAxisCount = 2;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _filteredProjects.length,
        itemBuilder: (context, index) {
          final project = _filteredProjects[index];
          return _buildProjectCard(project);
        },
      ),
    );
  }

  Widget _buildProjectsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProjects.length,
      itemBuilder: (context, index) {
        final project = _filteredProjects[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildProjectListItem(project),
        );
      },
    );
  }

  Widget _buildProjectCard(Project project) {
    return GestureDetector(
      onDoubleTap: () {
        ProjectOpener.openProject(context, project.path);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _getProjectColor(project.type).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    // Project icon centered
                    Center(
                      child: Icon(
                        _getProjectIcon(project.type),
                        size: 40,
                        color: _getProjectColor(project.type),
                      ),
                    ),

                    // Type badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getProjectColor(
                            project.type,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getProjectIcon(project.type),
                              size: 12,
                              color: _getProjectColor(project.type),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              project.type.name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getProjectColor(project.type),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Menu button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(
                          Icons.more_horiz,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Project info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatLastEdited(project.lastEdited),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectListItem(Project project) {
    return GestureDetector(
      onDoubleTap: () {
        ProjectOpener.openProject(context, project.path);
      },
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            // Project thumbnail/icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _getProjectColor(project.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  _getProjectIcon(project.type),
                  size: 24,
                  color: _getProjectColor(project.type),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Project info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatLastEdited(project.lastEdited),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!_isSmallScreen)
              // Project type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: _getProjectColor(project.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getProjectIcon(project.type),
                      size: 14,
                      color: _getProjectColor(project.type),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      project.type.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getProjectColor(project.type),
                      ),
                    ),
                  ],
                ),
              ),

            // Actions menu
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 60, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Create a new project to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create New Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E44FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter.toLowerCase()) {
      case 'design':
        return Icons.brush;
      case 'animation':
        return Icons.animation;
      case 'video':
        return Icons.videocam;
      case '3d':
        return Icons.view_in_ar;
      default:
        return Icons.folder;
    }
  }

  Color _getFilterColor(String filter) {
    switch (filter.toLowerCase()) {
      case 'design':
        return const Color(0xFF6E44FF); // Purple
      case 'animation':
        return const Color(0xFF44A4FF); // Blue
      case 'video':
        return const Color(0xFFFF6E44); // Orange
      case '3d':
        return const Color(0xFF44FF6E); // Green
      default:
        return Colors.grey;
    }
  }

  ProjectType _getProjectTypeFromString(String type) {
    switch (type) {
      case 'Design':
        return ProjectType.design;
      case '3D & Animation':
        return ProjectType.threeD;
      case 'Video Editing':
        return ProjectType.video;
      default:
        return ProjectType.design;
    }
  }

  Color _getProjectColor(ProjectType type) {
    switch (type) {
      case ProjectType.design:
        return const Color(0xFF6E44FF); // Purple
      case ProjectType.animation:
        return const Color(0xFF44A4FF); // Blue
      case ProjectType.video:
        return const Color(0xFFFF6E44); // Orange
      case ProjectType.threeD:
        return const Color(0xFF44FF6E); // Green
    }
  }

  IconData _getProjectIcon(ProjectType type) {
    switch (type) {
      case ProjectType.design:
        return Icons.brush_outlined;
      case ProjectType.animation:
        return Icons.animation;
      case ProjectType.video:
        return Icons.videocam_outlined;
      case ProjectType.threeD:
        return Icons.view_in_ar_outlined;
    }
  }

  String _formatLastEdited(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _createProject() async {
    final defaultProjectsDir =
        await ProjectService.getDefaultProjectsDirectory();
    showDialog(
      context: context,
      builder: (context) =>
          CreateProjectDialog(defaultPath: defaultProjectsDir),
    ).then((result) async {
      if (result != null) {
        // Reload projects after creating a new one
        _loadProjects();
      }
    });
  }
}
