import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'utils/debug_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  await debugLogger.log('Starting TmelnikApp...');
  runApp(const TmelnikApp());
}

class TmelnikApp extends StatelessWidget {
  const TmelnikApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugLogger.ui('Building TmelnikApp widget');
    
    return MaterialApp(
      title: 'Tmelnik - Youth Exchange Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    debugLogger.ui('Building AuthWrapper widget');
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugLogger.auth('Auth state: checking...');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking authentication...'),
                ],
              ),
            ),
          );
        }

        // If user is logged in, show main app
        if (snapshot.hasData) {
          debugLogger.auth('User is authenticated: ${snapshot.data?.email}');
          debugLogger.navigation('Navigating to MainNavigationScreen');
          return const MainNavigationScreen();
        }

        // If user is not logged in, show auth screen
        debugLogger.auth('User is not authenticated, showing auth screen');
        debugLogger.navigation('Navigating to AuthScreen');
        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

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
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        await debugLogger.auth('Email/password sign in successful');
      } else {
        await debugLogger.auth('Attempting registration with email: $_email');
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Join Tmelnik',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Google Sign In button (prominent)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
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
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Email input
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
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
                      ),
                      const SizedBox(height: 16),

                      // Password input
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value!;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                              : Text(_isLogin ? 'Sign In' : 'Create Account'),
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
                        child: Text(
                          _isLogin
                              ? 'Create an account'
                              : 'I already have an account',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ProjectOffersScreen(),
    const FeedbackScreen(),
    const InformationScreen(),
    const NewsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    debugLogger.ui('Building MainNavigationScreen widget');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tmelnik'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () async {
              await debugLogger.auth('User initiated logout');
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut(); // Sign out from Google as well
              await debugLogger.success('User logged out successfully');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          debugLogger.navigation('Navigated to screen: $index');
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback_outlined),
            activeIcon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper),
            label: 'News',
          ),
        ],
      ),
    );
  }
}

// Placeholder screens - these will be implemented with full functionality
class ProjectOffersScreen extends StatelessWidget {
  const ProjectOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Project Offers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This section will show available work opportunities\nand project offers.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Instagram sharing would work here!'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share on Instagram'),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.feedback,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Feedback Collection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This section will collect user feedback\nand suggestions.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'General Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This section will provide general information\nabout the platform and services.',
              textAlign: TextAlign.center,
            ),
          ],
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.newspaper,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Hot News & Interactions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This section will show the latest news\nand user interactions.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}