import 'package:astravision/Dashboard/HomeDashboard_page.dart';
import 'package:astravision/Dashboard/ExternalFiles/ProjectDashboard/website_editor_dashboard.dart';
import 'package:astravision/project_launcher.dart';
import 'package:astravision/login_page.dart';
import 'package:astravision/register_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

// Class to hold launch arguments
class LaunchArguments {
  final String? projectPath;
  final String? projectName;
  final String? projectType;

  LaunchArguments({this.projectPath, this.projectName, this.projectType});
}

// Global variable to store launch arguments
late LaunchArguments launchArgs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get launch arguments from ProjectLauncher
  final args = await ProjectLauncher.getLaunchArguments();

  // Initialize launch arguments with the parsed values
  launchArgs = LaunchArguments(
    projectPath: args['projectPath'],
    projectName: args['projectName'],
    projectType: args['projectType'],
  );

  runApp(const AstraVision());
}

class AstraVision extends StatelessWidget {
  const AstraVision({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstraVision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6E44FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E44FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: _determineInitialScreen(),
    );
  }

  Widget _determineInitialScreen() {
    print('Determining initial screen...');
    print(
      'Launch args: ${launchArgs.projectPath}, ${launchArgs.projectName}, ${launchArgs.projectType}',
    );

    // Check if app was launched with a project
    if (launchArgs.projectPath != null &&
        launchArgs.projectName != null &&
        launchArgs.projectType != null) {
      // Check if it's a website project
      if (launchArgs.projectType?.toLowerCase() == 'website') {
        print('Opening website editor for ${launchArgs.projectName}');
        return WebsiteEditorDashboard(
          projectPath: launchArgs.projectPath!,
          projectName: launchArgs.projectName!,
        );
      }
    }

    print('Opening splash screen');
    return const SplashScreen();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    Timer(const Duration(milliseconds: 2000), () {
      setState(() {
        _showButtons = true;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background design elements
          Positioned.fill(child: CustomPaint(painter: BackgroundPainter())),

          // Grid pattern overlay
          Opacity(
            opacity: 0.15,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/grid_pattern.png'),
                  repeat: ImageRepeat.repeat,
                  scale: 3.0,
                ),
              ),
            ),
          ),

          // Design elements that represent app functionality
          Positioned(
            top: 120,
            left: 40,
            child: DesignElement(
              icon: Icons.category_outlined,
              color: Colors.teal.withOpacity(0.7),
              size: 50,
            ),
          ),
          Positioned(
            top: 80,
            right: 60,
            child: DesignElement(
              icon: Icons.brush_outlined,
              color: Colors.amber.withOpacity(0.7),
              size: 40,
            ),
          ),
          Positioned(
            bottom: 140,
            left: 60,
            child: DesignElement(
              icon: Icons.palette_outlined,
              color: Colors.pink.withOpacity(0.7),
              size: 45,
            ),
          ),
          Positioned(
            bottom: 180,
            right: 50,
            child: DesignElement(
              icon: Icons.layers_outlined,
              color: Colors.green.withOpacity(0.7),
              size: 42,
            ),
          ),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6E44FF).withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF6E44FF).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glowing effect
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF6E44FF).withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.2, 1.0],
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.auto_awesome,
                                size: 80,
                                color: const Color(0xFF6E44FF),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF6E44FF), Color(0xFF9C7AFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'AstraVision',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Advanced Design & Prototyping',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFAAAAAA),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 80),
                        AnimatedOpacity(
                          opacity: _showButtons ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 800),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 240,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 240,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RegisterPage(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF6E44FF),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HomeDashboardPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Continue as Guest',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFAAAAAA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for creating abstract background
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    // Create background gradient
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1E1E1E),
          const Color(0xFF121212),
          Colors.black.withOpacity(0.9),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw design-related elements
    drawDesignGrid(canvas, size);
    drawAbstractShapes(canvas, size);
  }

  void drawDesignGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    for (int i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        gridPaint,
      );
    }

    // Draw vertical lines
    for (int i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        gridPaint,
      );
    }
  }

  void drawAbstractShapes(Canvas canvas, Size size) {
    // Draw some abstract shapes that suggest design software
    final random = math.Random(42); // Fixed seed for consistency

    // Draw circles representing design elements
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 20.0 + random.nextDouble() * 80;

      final circlePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF6E44FF).withOpacity(0.1);

      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }

    // Draw some connecting lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.08);

    for (int i = 0; i < 8; i++) {
      final x1 = random.nextDouble() * size.width;
      final y1 = random.nextDouble() * size.height;
      final x2 = random.nextDouble() * size.width;
      final y2 = random.nextDouble() * size.height;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }

    // Draw some rectangles representing artboards
    final rectPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.teal.withOpacity(0.1);

    for (int i = 0; i < 3; i++) {
      final x = random.nextDouble() * size.width * 0.7;
      final y = random.nextDouble() * size.height * 0.7;
      final width = 50.0 + random.nextDouble() * 100;
      final height = 70.0 + random.nextDouble() * 100;

      canvas.drawRect(Rect.fromLTWH(x, y, width, height), rectPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated design element widget
class DesignElement extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const DesignElement({
    Key? key,
    required this.icon,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  State<DesignElement> createState() => _DesignElementState();
}

class _DesignElementState extends State<DesignElement>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: widget.size * 0.6,
              ),
            ),
          ),
        );
      },
    );
  }
}
