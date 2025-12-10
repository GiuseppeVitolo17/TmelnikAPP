import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'screens/news_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/manage_ngos_screen.dart';
import 'screens/manage_users_screen.dart';
import 'config/loading_config.dart';
import 'services/loading_controller.dart';
import 'services/user_role_service.dart';
import 'services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background handler for FCM (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolate
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  // Forward to notification service to build local notification
  try {
    NotificationService.notificationsEnabled = true;
    await NotificationService().initialize();
    await NotificationService().handleRemoteMessage(message, fromBackground: true);
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations (non-blocking)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase (critical - must be done before runApp)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('✅ Firebase initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error initializing Firebase: $e');
    }
  }

  // Register FCM background handler (non-blocking)
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) {
      print('Error setting FCM background handler: $e');
    }
  }
  
  // Run app immediately - don't block UI
  runApp(const TmelnikApp());
  
  // Initialize non-critical services in background after UI is ready
  _initializeBackgroundServices();
}

/// Initialize non-critical services in background to avoid blocking app startup
void _initializeBackgroundServices() {
  // Use microtask to run after current frame
  Future.microtask(() async {
    try {
      // Initialize debug logging in background (non-blocking)
      debugLogger.initializeLog().then((_) {
        debugLogger.log('App started');
      }).catchError((e) {
        if (kDebugMode) print('Log init error: $e');
      });
      
      // Restore Google session in background (non-blocking)
      _restoreGoogleSession();
      
      // Initialize notifications in background (non-blocking)
      _initializeNotifications();
    } catch (e) {
      if (kDebugMode) print('Background init error: $e');
    }
  });
}

/// Restore Google Sign-In session in background
Future<void> _restoreGoogleSession() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      final google = GoogleSignIn();
      final silent = await google.signInSilently().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
      if (silent != null) {
        final ga = await silent.authentication;
        if (ga.idToken != null) {
          final credential = GoogleAuthProvider.credential(
            accessToken: ga.accessToken,
            idToken: ga.idToken,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (kDebugMode) {
            print('✅ Google session restored');
          }
        }
      }
    }
  } catch (e) {
    // Silent fail - not critical for app startup
    if (kDebugMode) {
      print('Session restore failed (non-critical): $e');
    }
  }
}

/// Initialize notification service in background
Future<void> _initializeNotifications() async {
  try {
    // Load preference first (fast)
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    NotificationService.notificationsEnabled = enabled;
    
    // Only initialize if enabled
    if (enabled) {
      // Initialize in background without blocking
      NotificationService().initialize().catchError((e) {
        if (kDebugMode) {
          print('Notification init error (non-critical): $e');
        }
      });
    }
  } catch (e) {
    // Silent fail - not critical
    if (kDebugMode) {
      print('Notification preference load error: $e');
    }
  }
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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
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
            animationDuration: const Duration(milliseconds: 200),
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
        
        // Check if email is verified
        if (userCredential.user != null) {
          // Reload user to get latest email verification status
          await userCredential.user!.reload();
          final currentUser = FirebaseAuth.instance.currentUser;
          
          if (currentUser != null && !currentUser.emailVerified) {
            // Email not verified - show warning and option to resend
            await debugLogger.auth('User email not verified: $_email');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ Email not verified. Check your email or resend the verification link.'),
                      SizedBox(height: 4),
                      Text(
                        '💡 Tip: Check your spam folder if you don\'t see the email!',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 8),
                  action: SnackBarAction(
                    label: 'Resend',
                    textColor: Colors.white,
                    onPressed: () async {
                      try {
                        await currentUser.sendEmailVerification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('📧 Verification email sent!'),
                                  SizedBox(height: 4),
                                  Text(
                                    '⚠️ Check your spam folder if not in inbox',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.blue,
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                        await debugLogger.auth('Verification email resent to: $_email');
                      } catch (e) {
                        await debugLogger.error('Failed to resend verification email', e);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            }
            // Note: We still allow login even if email is not verified
            // If you want to block login, uncomment the following lines:
            // await FirebaseAuth.instance.signOut();
            // return;
          }
          
          // Initialize user role in Firestore
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
          
          // Send email verification
          await debugLogger.auth('Sending email verification to: $_email');
          await userCredential.user!.sendEmailVerification();
          await debugLogger.auth('Email verification sent successfully');
          
          // Show success message with email verification info
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ Account created! Check your email to verify your account.'),
                    SizedBox(height: 4),
                    Text(
                      '⚠️ If you don\'t see it, check your spam folder!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Resend email',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await userCredential.user!.sendEmailVerification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📧 Verification email sent!'),
                                SizedBox(height: 4),
                                Text(
                                  '⚠️ Check your spam folder if not in inbox',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 5),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            );
            
            // Don't sign out - let EmailVerificationScreen handle the blocking
            // User will be redirected to verification screen automatically
            await debugLogger.auth('User registered, will be shown verification screen');
          }
        }
        await debugLogger.auth('Email/password registration successful');
      }
    } on FirebaseAuthException catch (e) {
      await debugLogger.error('Email/password authentication failed', e);
      String errorMessage = 'Si è verificato un errore';
      
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'La password è troppo debole. Usa almeno 6 caratteri.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Questa email è già registrata. Prova ad accedere.';
          break;
        case 'invalid-email':
          errorMessage = 'L\'indirizzo email non è valido.';
          break;
        case 'user-not-found':
          errorMessage = 'Nessun account trovato con questa email.';
          break;
        case 'wrong-password':
          errorMessage = 'Password errata. Riprova.';
          break;
        case 'user-disabled':
          errorMessage = 'Questo account è stato disabilitato.';
          break;
        case 'too-many-requests':
          errorMessage = 'Troppi tentativi. Riprova più tardi.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operazione non consentita.';
          break;
        default:
          errorMessage = e.message ?? 'Errore di autenticazione: ${e.code}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      await debugLogger.error('Unexpected error in authentication', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore imprevisto: $e'),
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
      // Try silent sign-in first (do not force sign-out to preserve persistence)
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
                  // Logo/Icon section - Tmelnik icon without colored square
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if the icon asset is missing
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
  bool _emailVerified = true;
  bool _checkingEmailStatus = true;

  @override
  void initState() {
    super.initState();
    // FCM token is now handled silently by NotificationService
    _checkEmailVerificationStatus();
  }

  Future<void> _checkEmailVerificationStatus() async {
    // Check in background - don't block UI
    Future.microtask(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Reload user to get latest email verification status (with timeout)
          await user.reload().timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          );
          final currentUser = FirebaseAuth.instance.currentUser;
          if (mounted) {
            setState(() {
              _emailVerified = currentUser?.emailVerified ?? true;
              _checkingEmailStatus = false;
            });
          }
        } catch (e) {
          // Silent fail - default to verified
          if (mounted) {
            setState(() {
              _emailVerified = true;
              _checkingEmailStatus = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _checkingEmailStatus = false;
          });
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📧 Email di verifica inviata! Controlla la tua casella di posta.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await debugLogger.auth('Verification email resent to: ${user.email}');
      } catch (e) {
        await debugLogger.error('Failed to resend verification email', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nell\'invio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<bool>(
        stream: userRoleService.adminStatusStream,
        builder: (context, adminSnapshot) {
          final isAdmin = adminSnapshot.data ?? false;
          
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Menu items
                  _buildMenuTile(
                    context: context,
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: 'View your information',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'Manage app preferences',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  // Admin-only menu items
                  if (isAdmin) ...[
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, size: 16, color: Colors.purple[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Panel',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildMenuTile(
                      context: context,
                      icon: Icons.business,
                      title: 'Manage NGOs',
                      subtitle: 'Create and manage organizations',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageNGOScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuTile(
                      context: context,
                      icon: Icons.people,
                      title: 'Manage Users',
                      subtitle: 'Assign roles and permissions',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageUsersScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  const Divider(height: 1),
              _buildMenuTile(
                context: context,
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await debugLogger.auth('User confirmed logout');
                    await FirebaseAuth.instance.signOut();
                    await GoogleSignIn().signOut();
                    await debugLogger.success('User logged out successfully');
                  }
                },
                isDestructive: true,
              ),
              const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : AppColors.primaryBlue,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

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
    const double emojiSize = 32.0;
    const double emojiContainerSize = 44.0; // Smaller square for mobile header
    const double emojiPadding = (emojiContainerSize - emojiSize) / 2; // Center the emoji
    
    return SafeArea(
      bottom: false,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        width: double.infinity,
      height: emojiContainerSize + 18, // Container size + vertical padding
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2, // Better line height
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        ),
          ),
          // Profile/Logout button
            IconButton(
              onPressed: () async {
              if (isGuestMode) {
                widget.onLoginRequested?.call();
              } else {
                _showProfileMenu(context);
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
          ),
        );
  }

  Widget _buildEmailVerificationBanner() {
    if (_checkingEmailStatus || _emailVerified || widget.isGuestMode) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Email not verified',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your email (including spam folder) and click the verification link',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _resendVerificationEmail,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              'Resend',
              style: TextStyle(
                color: Colors.orange[900],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.orange[700],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _emailVerified = true; // Hide banner for this session
              });
            },
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
      body: Column(
        children: [
          _buildEmailVerificationBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
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
          // Check email verification status when switching screens
          _checkEmailVerificationStatus();
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


// NewsScreen is now in screens/news_screen.dart with RSS feed integration

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