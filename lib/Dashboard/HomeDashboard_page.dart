import 'package:astravision/Dashboard/ProjectsDashboard_page.dart';
import 'package:flutter/material.dart';

enum ProjectType { design, animation, video, threeD }

class Project {
  final String title;
  final String thumbnail;
  final DateTime lastEdited;
  final ProjectType type;

  Project({
    required this.title,
    required this.thumbnail,
    required this.lastEdited,
    required this.type,
  });
}

class Activity {
  final String action;
  final String projectName;
  final DateTime time;
  final String userAvatar;

  Activity({
    required this.action,
    required this.projectName,
    required this.time,
    required this.userAvatar,
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
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

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  final List<Project> _recentProjects = [
    Project(
      title: 'Brand Identity Design',
      thumbnail: 'assets/thumbnails/project1.jpg',
      lastEdited: DateTime.now().subtract(const Duration(hours: 2)),
      type: ProjectType.design,
    ),
    Project(
      title: 'Product Promo Video',
      thumbnail: 'assets/thumbnails/project2.jpg',
      lastEdited: DateTime.now().subtract(const Duration(days: 1)),
      type: ProjectType.video,
    ),
    Project(
      title: 'Website Mockup',
      thumbnail: 'assets/thumbnails/project3.jpg',
      lastEdited: DateTime.now().subtract(const Duration(days: 3)),
      type: ProjectType.design,
    ),
  ];

  final List<Activity> _recentActivities = [
    Activity(
      action: 'Updated',
      projectName: 'Brand Identity Design',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      userAvatar: 'assets/avatars/user1.jpg',
    ),
    Activity(
      action: 'Commented on',
      projectName: 'Product Promo Video',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      userAvatar: 'assets/avatars/user2.jpg',
    ),
    Activity(
      action: 'Created',
      projectName: 'Website Mockup',
      time: DateTime.now().subtract(const Duration(days: 1)),
      userAvatar: 'assets/avatars/user1.jpg',
    ),
    Activity(
      action: 'Shared',
      projectName: 'Tutorial Animation',
      time: DateTime.now().subtract(const Duration(days: 2)),
      userAvatar: 'assets/avatars/user3.jpg',
    ),
  ];

  bool _isSidebarExpanded = true;
  int _selectedSidebarIndex = 0; // Home is selected by default
  String _searchQuery = '';

  // Responsive breakpoints
  bool get _isSmallScreen => MediaQuery.of(context).size.width < 800;
  bool get _isMediumScreen =>
      MediaQuery.of(context).size.width < 1100 &&
      MediaQuery.of(context).size.width >= 800;

  // Navigation method
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
        // Already on home page, no navigation needed
        break;
      case 1: // Projects
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
        break;
      case 2: // Assets
        // Navigate to Assets page when implemented
        break;
      case 3: // Community
        // Navigate to Community page when implemented
        break;
    }
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
              width:
                  _isSidebarExpanded
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

                      // Home dashboard content
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeCard(),
                            const SizedBox(height: 24),
                            _buildStatsRow(),
                            const SizedBox(height: 32),
                            _buildRecentProjectsSection(),
                            const SizedBox(height: 32),
                            _buildActivitySection(),
                          ],
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
                ..._recentProjects
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
          color:
              isSelected
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

  // Remaining methods are unchanged
  // _buildRecentProjectItem, _buildAppBar, _buildWelcomeCard, etc.

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
            'Home',
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
                  hintText: 'Search...',
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

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E44FF), Color(0xFF9772FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E44FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Alex!',
                  style: TextStyle(
                    fontSize: _isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have 3 unfinished projects. Continue where you left off.',
                  style: TextStyle(
                    fontSize: _isSmallScreen ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Continue Working'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6E44FF),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_isSmallScreen)
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Icon(
                Icons.auto_awesome,
                size: 100,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Projects',
            '12',
            Icons.folder_outlined,
            const Color(0xFF6E44FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '8',
            Icons.check_circle_outline,
            const Color(0xFF44A4FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'In Progress',
            '4',
            Icons.timelapse,
            const Color(0xFFFF6E44),
          ),
        ),
        if (!_isSmallScreen) const SizedBox(width: 16),
        if (!_isSmallScreen)
          Expanded(
            child: _buildStatCard(
              'Team Members',
              '5',
              Icons.people_outline,
              const Color(0xFF44FF6E),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildRecentProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Projects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF6E44FF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRecentProjectsGrid(),
      ],
    );
  }

  Widget _buildRecentProjectsGrid() {
    // Adjust grid based on screen size
    int crossAxisCount = 3;
    if (_isSmallScreen) {
      crossAxisCount = 1;
    } else if (_isMediumScreen) {
      crossAxisCount = 2;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _recentProjects.length,
      itemBuilder: (context, index) {
        final project = _recentProjects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Project project) {
    return Container(
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
                        color: _getProjectColor(project.type).withOpacity(0.2),
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
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
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
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF6E44FF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: Column(
            children: _recentActivities.map(_buildActivityItem).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Activity activity) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),

          // Activity details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'You ${activity.action.toLowerCase()} ',
                        style: const TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: activity.projectName,
                        style: const TextStyle(
                          color: Color(0xFF6E44FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatLastEdited(activity.time),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // Action icon
          Icon(
            _getActivityIcon(activity.action),
            color: _getActivityColor(activity.action),
            size: 20,
          ),
        ],
      ),
    );
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

  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'Updated':
        return Icons.edit;
      case 'Commented on':
        return Icons.comment;
      case 'Created':
        return Icons.add_circle;
      case 'Shared':
        return Icons.share;
      default:
        return Icons.access_time;
    }
  }

  Color _getActivityColor(String action) {
    switch (action) {
      case 'Updated':
        return const Color(0xFF44A4FF); // Blue
      case 'Commented on':
        return const Color(0xFFFF6E44); // Orange
      case 'Created':
        return const Color(0xFF44FF6E); // Green
      case 'Shared':
        return const Color(0xFF6E44FF); // Purple
      default:
        return Colors.grey;
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
}
