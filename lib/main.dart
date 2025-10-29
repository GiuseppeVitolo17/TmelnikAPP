import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'utils/debug_logger.dart';
import 'theme/app_theme.dart';
import 'screens/loading_screen.dart';
import 'screens/add_project_screen.dart';
import 'screens/diary_calendar_screen.dart';
import 'screens/edit_project_offer_screen.dart';
import 'screens/project_offers_screen.dart';
import 'screens/daily_reflection_screen.dart';
import 'config/loading_config.dart';
import 'services/loading_controller.dart';
import 'services/user_role_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Log loading configuration
  LoadingConfig.logConfig();
  
  // Initialize debug logging
  await debugLogger.initializeLog();
  await debugLogger.log('App starting...');
  
  try {
    await debugLogger.firebase('Starting Firebase initialization...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await debugLogger.firebase('Firebase initialized successfully');
    print('✅ Firebase initialized successfully');
  } catch (e) {
    await debugLogger.error('Error initializing Firebase', e);
    print('❌ Error initializing Firebase: $e');
  }

  // Initialize notification service for mobile platforms
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugLogger.error('Error initializing notifications', e);
  }
  
  await debugLogger.log('Starting TmelnikApp...');
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Signal that Flutter is ready after app starts
  Future.delayed(const Duration(milliseconds: 100), () {
    loadingController.markAsReady();
  });
  
  runApp(const TmelnikApp());
}

class TmelnikApp extends StatelessWidget {
  const TmelnikApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugLogger.ui('Building TmelnikApp widget');
    
    // Use centralized theme and merge with additional customizations
    final baseTheme = buildAppTheme();
    
    return MaterialApp(
      title: 'Tmelnik - Youth Exchange Management',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isGuestMode = false;

  void _enterGuestMode() {
    setState(() {
      _isGuestMode = true;
    });
    debugLogger.auth('Entered guest mode');
  }

  void _exitGuestMode() {
    setState(() {
      _isGuestMode = false;
    });
    debugLogger.auth('Exited guest mode');
  }

  @override
  Widget build(BuildContext context) {
    debugLogger.ui('Building AuthWrapper widget');
    
    // If in guest mode, show main app with guest restrictions
    if (_isGuestMode) {
      return MainNavigationScreen(
        isGuestMode: true,
        onLoginRequested: _exitGuestMode,
      );
    }
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugLogger.auth('Auth state: checking...');
          return const LoadingScreen();
        }

        // If user is logged in, show main app
        if (snapshot.hasData) {
          debugLogger.auth('User is authenticated: ${snapshot.data?.email}');
          debugLogger.navigation('Navigating to MainNavigationScreen');
          return const MainNavigationScreen(isGuestMode: false);
        }

        // If user is not logged in, show auth screen
        debugLogger.auth('User is not authenticated, showing auth screen');
        debugLogger.navigation('Navigating to AuthScreen');
        return AuthScreen(onGuestModeRequested: _enterGuestMode);
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  final VoidCallback? onGuestModeRequested;
  
  const AuthScreen({super.key, this.onGuestModeRequested});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLogin = true;
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    await debugLogger.auth('Starting email/password authentication');

    try {
      if (_isLogin) {
        await debugLogger.auth('Attempting sign in with email: $_email');
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        // Initialize user role in Firestore
        if (userCredential.user != null) {
          await userRoleService.initializeUserRole(userCredential.user!);
        }
        await debugLogger.auth('Email/password sign in successful');
      } else {
        await debugLogger.auth('Attempting registration with email: $_email');
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        // Initialize user role in Firestore
        if (userCredential.user != null) {
          await userRoleService.initializeUserRole(userCredential.user!);
        }
        await debugLogger.auth('Email/password registration successful');
      }
    } catch (e) {
      await debugLogger.error('Email/password authentication failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    await debugLogger.auth('Starting Google Sign-In');

    try {
      // Try to sign out first to clear any cached credentials
      await debugLogger.auth('Signing out from any cached Google session');
      await _googleSignIn.signOut();
      
      // Try silent sign-in first
      await debugLogger.auth('Attempting silent Google Sign-In');
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      if (googleUser == null) {
        await debugLogger.auth('Silent sign-in failed, trying interactive sign-in');
        
        // Use interactive sign-in with timeout
        googleUser = await _googleSignIn.signIn()
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                debugLogger.auth('Google Sign-In timeout after 30 seconds');
                throw Exception('Google Sign-In timeout');
              },
            );
      }

      if (googleUser == null) {
        await debugLogger.auth('User cancelled Google Sign-In');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google sign-in was cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await debugLogger.auth('Google Sign-In successful, getting authentication details');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      await debugLogger.auth('Creating Firebase credential');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await debugLogger.auth('Signing in to Firebase with Google credential');
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Initialize user role in Firestore
      if (userCredential.user != null) {
        await userRoleService.initializeUserRole(userCredential.user!);
      }
      
      await debugLogger.auth('Google Sign-In completed successfully');
      await debugLogger.success('User authenticated: ${userCredential.user?.email}');

    } catch (e) {
      await debugLogger.error('Google Sign-In failed', e);
      
      if (mounted) {
        String errorMessage = 'Google sign-in failed. Please try again.';
        
        // Handle specific error types
        if (e.toString().contains('popup_closed')) {
          errorMessage = 'Google sign-in popup was closed. Please try again.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        } else if (e.toString().contains('NetworkError')) {
          errorMessage = 'Network error retrieving token. Check Firebase configuration.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Use Email/Password',
              textColor: Colors.white,
              onPressed: () {
                // Focus on email field
                FocusScope.of(context).requestFocus();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugLogger.ui('Building AuthScreen widget');
    
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const SizedBox(height: 20),
                  // Logo/Icon section - icona Tmelnik senza quadrato
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback se l'icona non esiste
                      return const Icon(
                        Icons.account_tree,
                        size: 80,
                        color: AppColors.primaryBlue,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Join Tmelnik',
                    style: const TextStyle(
                      fontSize: 24,
                          fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLogin 
                        ? 'Sign in to continue your adventure'
                        : 'Create your account to get started',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Login Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: AppRadius.large,
                      boxShadow: AppShadows.soft,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      // Google Sign In button (prominent)
                          ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.medium,
                              ),
                          ),
                          icon: const Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                                fontSize: 16,
                            ),
                          ),
                        ),
                          const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey[300],
                                  thickness: 1,
                                ),
                              ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                    fontSize: 12,
                              ),
                            ),
                          ),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey[300],
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                      // Email input
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundGrey,
                              prefixIcon: const Icon(Icons.email, color: AppColors.textSecondary, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          if (value == null || value.isEmpty || !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _email = value!;
                        },
                            onFieldSubmitted: (_) {
                              // Focus on password field when Enter is pressed
                              FocusScope.of(context).nextFocus();
                            },
                      ),
                      const SizedBox(height: 16),

                      // Password input
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundGrey,
                              prefixIcon: const Icon(Icons.lock, color: AppColors.textSecondary, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        obscureText: true,
                            textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value!;
                        },
                            onFieldSubmitted: (_) {
                              // Submit form when Enter is pressed on password field
                              if (!_isLoading) {
                                _submit();
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                      // Submit button
                          ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.medium,
                              ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Toggle between login and registration
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                            ),
                        child: Text(
                          _isLogin
                              ? 'Create an account'
                              : 'I already have an account',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Guest mode button
                  OutlinedButton(
                          onPressed: _isLoading ? null : () {
                            widget.onGuestModeRequested?.call();
                          },
                          style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                            ),
                          ),
                          child: const Text(
                            'Continue as Guest',
                            style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'View projects and news without login',
                        style: TextStyle(
                      fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                  const SizedBox(height: 20),
                    ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final bool isGuestMode;
  final VoidCallback? onLoginRequested;
  
  const MainNavigationScreen({
    super.key, 
    this.isGuestMode = false,
    this.onLoginRequested,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens {
    if (widget.isGuestMode) {
      return [
        const ProjectOffersScreen(), // Projects are always accessible
        GuestLoginScreen(title: 'Daily reflection', onLoginRequested: widget.onLoginRequested),
        GuestLoginScreen(title: 'Diary', onLoginRequested: widget.onLoginRequested), // Diary requires login
        const NewsScreen(), // News are always accessible
      ];
    }
    return [
      const ProjectOffersScreen(),
      const DailyReflectionScreen(),
      const DiaryCalendarScreen(),
      const NewsScreen(),
    ];
  }

  String get _currentScreenTitle {
    // Centralized header titles for all screens
    switch (_currentIndex) {
      case 0:
        return 'Plan your next trip';
      case 1:
        return 'Daily reflection';
      case 2:
        return 'Diary';
      case 3:
        return 'News';
      default:
        return widget.isGuestMode ? 'Tmelnik (Guest)' : 'Tmelnik';
    }
  }

  /// Builds a reusable header widget matching the Projects screen style
  Widget _buildHeader(String title) {
    final isGuestMode = widget.isGuestMode;
    
    // Get emoji based on screen title
    String headerEmoji;
    switch (title) {
      case 'Plan your next trip':
        headerEmoji = '🌍';
        break;
      case 'Daily reflection':
        headerEmoji = '✏️';
        break;
      case 'Diary':
        headerEmoji = '📅';
        break;
      case 'News':
        headerEmoji = '📰';
        break;
      default:
        headerEmoji = '🌍';
    }
    
    // Emoji container size (square)
    const double emojiSize = 40.0;
    const double emojiContainerSize = 56.0; // Container size (square)
    const double emojiPadding = (emojiContainerSize - emojiSize) / 2; // Center the emoji
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      width: double.infinity,
      height: emojiContainerSize + 24, // Container size + vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emoji container - square with fixed size, properly centered
          Container(
            width: emojiContainerSize,
            height: emojiContainerSize,
            alignment: Alignment.center, // Center the content
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.backgroundGrey,
            ),
            child: Text(
              headerEmoji,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: emojiSize,
                height: 1.0, // Remove extra line height
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Titolo - vertically centered
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2, // Better line height
                ),
              ),
            ),
          ),
          // Profile/Logout button
            IconButton(
              onPressed: () async {
              if (isGuestMode) {
                widget.onLoginRequested?.call();
              } else {
                await debugLogger.auth('User initiated logout');
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
                await debugLogger.success('User logged out successfully');
              }
            },
            icon: Icon(
              isGuestMode ? Icons.login : Icons.person,
              color: Colors.black,
            ),
            tooltip: isGuestMode ? 'Login' : 'Profile',
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugLogger.ui('Building MainNavigationScreen widget');
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // Increased to match new header height
        child: _buildHeader(_currentScreenTitle),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
    setState(() {
            _currentIndex = index;
          });
          debugLogger.navigation('Navigated to screen: $index');
        },
          selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_outlined),
              activeIcon: Icon(Icons.edit_note),
              label: 'Reflection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Diary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper),
            label: 'News',
          ),
        ],
      ),
          ),
        );
      }
}

// ProjectOffersScreen is now in screens/project_offers_screen.dart

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: AppRadius.large,
            boxShadow: AppShadows.soft,
          ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: AppRadius.large,
                ),
                child: const Icon(
              Icons.feedback,
                  size: 64,
              color: Colors.green,
            ),
              ),
              const SizedBox(height: 24),
            const Text(
              'Feedback Collection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
              ),
            ),
              const SizedBox(height: 16),
              Text(
              'This section will collect user feedback\nand suggestions.',
              textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}


class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: AppRadius.large,
            boxShadow: AppShadows.soft,
          ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: AppRadius.large,
                ),
                child: const Icon(
              Icons.newspaper,
                  size: 64,
              color: Colors.red,
            ),
              ),
              const SizedBox(height: 24),
            const Text(
              'Hot News & Interactions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
              ),
            ),
              const SizedBox(height: 16),
              Text(
              'This section will show the latest news\nand user interactions.',
              textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class GuestLoginScreen extends StatelessWidget {
  final String title;
  final VoidCallback? onLoginRequested;
  
  const GuestLoginScreen({
    super.key,
    required this.title,
    this.onLoginRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: AppRadius.large,
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: AppRadius.large,
                ),
                child: Icon(
                Icons.lock_outline,
                  size: 64,
                color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to access $title section',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onLoginRequested,
                icon: const Icon(Icons.login),
                label: const Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Continue as guest to view projects and news',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}