import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/background_container.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String? _message;

  Future<void> _reauthenticate() async {
    final user = _auth.currentUser;
    final cred = EmailAuthProvider.credential(
      email: user!.email!,
      password: _currentPasswordController.text.trim(),
    );

    try {
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();

      if (code.contains('wrong-password') || code.contains('invalid-credential')) {
        setState(() {
          _message = "Incorrect current password.";  // does not work !
        });
      } else {
        setState(() {
          _message = "Incorrect current password.";
        });
      }

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _message = null);
      throw Exception();
    }
  }

  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    _currentPasswordController.clear();
    _newPasswordController.clear();

    try {
      await _reauthenticate();
    } catch (_) {
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _message = "Password must be at least 6 characters.";
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _message = null);
      return;
    }

    if (currentPassword == newPassword) {
      setState(() {
        _message = "New password cannot be the same as current password.";
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _message = null);
      return;
    }

    try {
      await _auth.currentUser!.updatePassword(newPassword);
      setState(() {
        _message = "Password updated successfully!";
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _message = null);
    } catch (e) {
      setState(() {
        _message = "Failed to update password: $e";
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _message = null);
    }
  }



  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BackgroundContainer(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Center(
              child: Text(
                "ImScaler",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Email: ${user?.email ?? 'Not available'}",
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildInputField("Current Password", _currentPasswordController, obscureText: true),
                      const SizedBox(height: 16),
                      _buildInputField("New Password", _newPasswordController, obscureText: true),
                      const SizedBox(height: 8),
                      _roundedButton("Update Password", _updatePassword),
                      const SizedBox(height: 24),
                      _roundedButton("Logout", _logout),
                      const SizedBox(height: 16),
                      if (_message != null)
                        Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _roundedButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 45),
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
