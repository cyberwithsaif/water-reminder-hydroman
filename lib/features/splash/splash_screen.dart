import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/water_log.dart';
import '../../data/models/reminder.dart';
import '../../providers/user_provider.dart';
import '../../providers/water_log_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_helper.dart';
import '../../services/notification_service.dart';
import '../../services/permission_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Remove native splash ONLY after the first frame of Splash screen is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Set a global timeout for the whole initialization process
      await _performInitialization().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('SplashScreen: Initialization timed out!');
        },
      );
    } catch (e) {
      debugPrint('SplashScreen: Error during initialization: $e');
    } finally {
      _navigateToNext();
    }
  }

  Future<void> _performInitialization() async {
    // ── CRITICAL PATH (must complete before navigation) ──

    // 1. Initialize Hive & register adapters
    try {
      await Hive.initFlutter();
      _safeRegisterAdapter(UserProfileAdapter());
      _safeRegisterAdapter(WaterLogAdapter());
      _safeRegisterAdapter(ReminderAdapter());
    } catch (e) {
      debugPrint('SplashScreen: Hive init failed: $e');
    }

    setState(() => _loadingProgress = 0.3);

    // 2. Initialize repositories (opens Hive boxes)
    try {
      await Future.wait([
        ref.read(userRepositoryProvider).init(),
        ref.read(waterLogRepositoryProvider).init(),
        ref.read(reminderRepositoryProvider).init(),
      ]);
    } catch (e) {
      debugPrint('SplashScreen: Repo init failed: $e');
    }

    setState(() => _loadingProgress = 0.6);

    // 3. Load local data into providers (fast — just reads from Hive)
    try {
      ref.read(userProfileProvider.notifier).load();
      ref.read(todayLogsProvider.notifier).load();
      // Load reminder DATA from Hive (no notification scheduling yet)
      await ref.read(remindersProvider.notifier).loadDataOnly();
    } catch (e) {
      debugPrint('SplashScreen: Provider load failed: $e');
    }

    // 4. Quick auth check (just reads saved token from Hive, no network)
    try {
      await ref
          .read(authStateProvider.notifier)
          .ensureLoaded()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('SplashScreen: Auth load timed out: $e');
    }

    setState(() => _loadingProgress = 1.0);

    // ── DEFERRED WORK (runs after homepage is visible) ──
    _runDeferredInit();
  }

  /// Non-critical initialization that runs in background after navigation.
  /// Captures provider references before the microtask to avoid using
  /// ref after the widget is disposed (race condition with navigation).
  void _runDeferredInit() {
    // Capture the notifier reference NOW, before widget disposal
    final remindersNotifier = ref.read(remindersProvider.notifier);
    final syncService = ref.read(syncServiceProvider);
    final profileNotifier = ref.read(userProfileProvider.notifier);
    final logsNotifier = ref.read(todayLogsProvider.notifier);
    final isLoggedIn = ref.read(isLoggedInProvider);

    Future.microtask(() async {
      try {
        // 1. If logged in, sync with server to get latest profile/data
        if (isLoggedIn) {
          try {
            await syncService
                .syncAll(
                  onComplete: () {
                    // Reload providers with synced data
                    profileNotifier.load();
                    logsNotifier.load();
                    remindersNotifier.loadDataOnly();
                  },
                )
                .timeout(const Duration(seconds: 10));
          } catch (e) {
            debugPrint('SplashScreen: Deferred sync failed: $e');
          }
        }

        // 2. Initialize notifications & ads in parallel
        await Future.wait([
          NotificationService.instance.initialize(),
          AdHelper.initialize(),
        ]);

        // Request all permissions (notification, exact alarm, battery optimization)
        await PermissionService.requestAll();

        // NOW schedule notifications (service is initialized, permissions requested)
        // Uses captured notifier reference (safe after widget disposal)
        await remindersNotifier.scheduleNotifications();

        debugPrint('SplashScreen: Deferred init complete');
      } catch (e) {
        debugPrint('SplashScreen: Deferred init error: $e');
      }
    });
  }

  void _safeRegisterAdapter<T>(TypeAdapter<T> adapter) {
    try {
      Hive.registerAdapter(adapter);
    } catch (_) {} // Already registered
  }

  void _navigateToNext() {
    if (!mounted) return;

    // Check auth first, then onboarding
    final isLoggedIn = ref.read(isLoggedInProvider);
    final isOnboarded = ref.read(isOnboardedProvider);

    String route;
    if (!isLoggedIn) {
      route = '/login';
    } else if (!isOnboarded) {
      route = '/onboarding';
    } else {
      route = '/main';
    }

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).primaryColor.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: -80,
              child: Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Bubble animation area
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(200, 200),
                        painter: _BubblePainter(
                          animationValue: _controller.value,
                          bubbleColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.3),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // App title - Instant display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: Theme.of(context).primaryColor,
                        size: 36,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hydroman',
                        style: GoogleFonts.manrope(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Slogan - Instant display
                  Text(
                    'Stay hydrated, stay healthy',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Loading bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: _loadingProgress),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LOADING YOUR GOALS...',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.8),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Powered by
                  Column(
                    children: [
                      Text(
                        'POWERED BY',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/images/powered_by_logo.png',
                        height: 32,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'v1.0.0',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterDropMascot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Water drop shape
        Container(
          width: 120,
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
              bottomLeft: Radius.circular(55),
              bottomRight: Radius.circular(55),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Highlight
              Positioned(
                top: 20,
                right: 25,
                child: Container(
                  width: 24,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Eyes
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 12,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              // Smile
              Positioned(
                top: 78,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 3),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
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
}

class _BubblePainter extends CustomPainter {
  final double animationValue;
  final Color bubbleColor;

  _BubblePainter({required this.animationValue, required this.bubbleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    // Drawing 1 bubble only
    final double x = center.dx;
    final double y = center.dy - (60 * animationValue);
    final double radius = 25 * (1 - animationValue * 0.5);

    canvas.drawCircle(Offset(x, y), radius, paint);

    // Add a shine effect to bubble
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(x - radius * 0.3, y - radius * 0.3),
      radius * 0.2,
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
