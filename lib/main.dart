import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/kasir_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';
import 'core/navigation/app_routes.dart';
// import 'core/navigation/route_names.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'styles/color_style.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KasirProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'Kasir App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.primary,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

///
/// AuthWrapper sebagai gerbang autentikasi
///
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      try {
        if (mounted) {
          context.read<AuthProvider>().checkLoginStatus();
        }
      } catch (e) {
        debugPrint('Error checking login status: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const LoadingScreen();
        }

        // Update TransactionProvider token when user is authenticated
        try {
          if (authProvider.isAuthenticated && authProvider.token != null) {
            final transactionProvider = context.read<TransactionProvider>();
            transactionProvider.updateToken(authProvider.token!);

            // Update ProductProvider tokoId for data isolation
            final productProvider = context.read<ProductProvider>();
            if (authProvider.tokoId > 0) {
              productProvider.updateTokoId(authProvider.tokoId);
            }

            // Update TransactionProvider tokoId for data isolation
            if (authProvider.tokoId > 0) {
              transactionProvider.updateTokoId(authProvider.tokoId);
            }
          }
        } catch (e) {
          debugPrint('Error updating providers: $e');
        }

        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late AnimationController _textAnimationController;
  late Animation<int> _dotAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    if (!mounted || _isInitialized) return;

    // Delay sebelum memulai animasi
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _isInitialized) return;

      try {
        _animationController = AnimationController(
          duration: const Duration(seconds: 2),
          vsync: this,
        );

        _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

        _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.linear),
        );

        _animationController.repeat(reverse: true);

        // Animation for moving dots
        _textAnimationController = AnimationController(
          duration: const Duration(milliseconds: 1500),
          vsync: this,
        );

        _dotAnimation = IntTween(begin: 1, end: 4).animate(
          CurvedAnimation(
            parent: _textAnimationController,
            curve: Curves.linear,
          ),
        );

        _textAnimationController.repeat();

        // Progress bar animation from 0 to 100%
        _progressController = AnimationController(
          duration: const Duration(seconds: 3),
          vsync: this,
        );

        _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

        _progressController.repeat();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        // Handle initialization errors
        debugPrint('Error initializing animations: $e');
      }
    });
  }

  @override
  void dispose() {
    try {
      if (_isInitialized) {
        if (_animationController.isAnimating) {
          _animationController.stop();
        }
        _animationController.dispose();

        if (_textAnimationController.isAnimating) {
          _textAnimationController.stop();
        }
        _textAnimationController.dispose();

        if (_progressController.isAnimating) {
          _progressController.stop();
        }
        _progressController.dispose();
      }
    } catch (e) {
      // Ignore disposal errors during hot restart
      debugPrint('Error disposing controllers: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isInitialized
                ? AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.point_of_sale,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.point_of_sale,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
            const SizedBox(height: 32),
            const Text(
              'Kasir App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistem Kasir Modern',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkgreen,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _isInitialized
                ? AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Column(
                        children: [
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              value: _progressAnimation.value,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF007211),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_progressAnimation.value * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkgreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Column(
                    children: [
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                          value: 0.0,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF007211),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '0%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkgreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),
            _isInitialized
                ? AnimatedBuilder(
                    animation: _dotAnimation,
                    builder: (context, child) {
                      String dots = '.' * _dotAnimation.value;
                      return Text(
                        'Memuat data$dots',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.darkgreen,
                        ),
                      );
                    },
                  )
                : const Text(
                    'Memuat data',
                    style: TextStyle(fontSize: 14, color: AppColors.darkgreen),
                  ),
          ],
        ),
      ),
    );
  }
}
