import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media/app_theme.dart';
import 'package:social_media/services/auth_service.dart';
import 'package:social_media/widgets/glass_container.dart';
import 'package:social_media/home_screen.dart';
import 'package:social_media/models/user_model.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          displayLarge: TextStyle(color: Colors.black),
          displayMedium: TextStyle(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E), // Very dark background
        cardColor: const Color(0xFF2D2D2D), // Slightly lighter dark grey
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4A574), // Light gold color
          secondary: Color(0xFFD4A574), // Light gold for accents
          surface: Color(0xFF2D2D2D), // Card color
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFD4A574), // Light gold icons
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4A574), // Light gold buttons
            foregroundColor: Colors.white,
          ),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthWrapper(
        onThemeChanged: toggleDarkMode,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final void Function(bool) onThemeChanged;
  final bool isDarkMode;

  const AuthWrapper({super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();

    return StreamBuilder<User?>(
      stream: _auth.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is logged in, get user data and navigate to home
          return FutureBuilder<UserModel?>(
            future: _auth.getCurrentUserModel(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                return HomeScreen(
                  user: userSnapshot.data!,
                  onThemeChanged: onThemeChanged,
                  isDarkMode: isDarkMode,
                );
              } else {
                // Fallback to auth page if user data not found
                return const AuthPage();
              }
            },
          );
        } else {
          // User is not logged in, show auth page
          return const AuthPage();
        }
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _auth = AuthService();
  bool isLogin = true;
  bool isForgot = false;
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _user = TextEditingController();
  
  // Password visibility toggles
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;

  // Field visibility toggles
  bool _showUsername = false;
  bool _showEmail = false;

  void _handleAction() async {
    try {
      if (isForgot) {
        await _auth.resetPassword(_email.text);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent to your email!')));
      } else if (isLogin) {
        await _auth.login(_email.text, _pass.text);
        // Navigation will be handled automatically by StreamBuilder in AuthWrapper
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful!')));
      } else {
        await _auth.signUp(_email.text, _pass.text, _user.text);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome ${_user.text}!')));
        // Navigation will be handled automatically by StreamBuilder in AuthWrapper
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isDesktop = screenSize.width >= 1200;
    
    // Get theme mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Responsive container width
    double containerWidth = isMobile ? screenSize.width * 0.9 : 
                           isTablet ? screenSize.width * 0.6 : 400;
    
    // Responsive padding
    double horizontalPadding = isMobile ? 20 : 40;
    double verticalPadding = isMobile ? 20 : 30;
    
    // Responsive font size
    double titleFontSize = isMobile ? 24 : isTablet ? 28 : 32;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/anime_collage_bg.png'), 
            fit: BoxFit.cover, 
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, 
              vertical: verticalPadding
            ),
            child: GlassContainer(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 20 : 30),
                width: containerWidth,
                constraints: BoxConstraints(
                  minWidth: isMobile ? 280 : 350,
                  maxWidth: isDesktop ? 500 : double.infinity,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isForgot ? 'Reset Pass' : (isLogin ? 'Log In' : 'Register'),
                      style: TextStyle(
                        fontSize: titleFontSize, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                    SizedBox(height: isMobile ? 20 : 25),
                    if (!isLogin && !isForgot) ...[
                      TextField(
                        controller: _user, 
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.primaryButtonColor),
                          ),
                        ),
                        style: TextStyle(fontSize: isMobile ? 16 : 18),
                      ),
                      SizedBox(height: isMobile ? 12 : 15),
                    ],
                    TextField(
                      controller: _email, 
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.primaryButtonColor),
                        ),
                      ),
                      style: TextStyle(fontSize: isMobile ? 16 : 18),
                    ),
                    if (!isForgot) ...[
                      SizedBox(height: isMobile ? 12 : 15),
                      TextField(
                        controller: _pass, 
                        obscureText: _obscureLoginPassword, 
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.primaryButtonColor),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureLoginPassword = !_obscureLoginPassword;
                              });
                            },
                          ),
                        ),
                        style: TextStyle(fontSize: isMobile ? 16 : 18),
                      ),
                    ],
                    if (isLogin && !isForgot) 
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => isForgot = true),
                          child: Text(
                            'Forgot Password?', 
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: isMobile ? 14 : 16
                            )
                          )
                        ),
                      ),
                    SizedBox(height: isMobile ? 16 : 20),
                    SizedBox(
                      width: double.infinity,
                      height: isMobile ? 45 : 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryButtonColor, 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                          )
                        ),
                        onPressed: _handleAction,
                        child: Text(
                          isForgot ? 'Submit' : (isLogin ? 'Login' : 'Create Account'), 
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 16 : 18
                          )
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() { isLogin = !isLogin; isForgot = false; }),
                      child: Text(
                        isLogin ? 'Register here' : 'Login here', 
                        style: TextStyle(
                          color: Colors.black, 
                          decoration: TextDecoration.underline,
                          fontSize: isMobile ? 14 : 16
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}