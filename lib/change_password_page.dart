import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  bool get _hasLength => _newController.text.length >= 8;
  bool get _hasNumber => _newController.text.contains(RegExp(r'[0-9]'));
  bool get _hasLetter => _newController.text.contains(RegExp(r'[a-zA-Z]'));

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user first
        String email = user.email!;
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: _currentController.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);

        // Update password
        await user.updatePassword(_newController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Failed to update password'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF003B7A);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Password', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _currentController,
                obscureText: true,
                decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val == null || val.isEmpty ? 'Enter current password' : null,
              ),
              const SizedBox(height: 16),

              const Text('New Password', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _newController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val == null || val.length < 8 ? 'Password must be at least 8 characters' : null,
              ),
              const SizedBox(height: 16),

              const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val != _newController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 20),

              // Checklist validation rules
              _RuleItem(text: 'At least 8 characters', isValid: _hasLength),
              _RuleItem(text: 'Include a number', isValid: _hasNumber),
              _RuleItem(text: 'Include a letter', isValid: _hasLetter),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _updatePassword,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String text;
  final bool isValid;

  const _RuleItem({required this.text, required this.isValid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.check_circle_outline, color: isValid ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: isValid ? Colors.green : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}