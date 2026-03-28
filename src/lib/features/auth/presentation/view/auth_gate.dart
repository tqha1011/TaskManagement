import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_view.dart';
import '../../../main/view/screens/main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder continously checks the auth state
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Wait response from Supabase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if there is an active session ( user logged in )
        final session = snapshot.data?.session;

        // if session exists -> Navigate to MainScreen
        if (session != null) {
          return const MainScreen();
        }

        // if session not exists -> Navigate to LoginView
        return const LoginView();
      },
    );
  }
}