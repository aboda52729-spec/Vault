import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pinFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _errorMessage = 'PIN must be at least 4 digits');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    final valid = await ref.read(authProvider.notifier).verifyPin(pin);
    setState(() => _isLoading = false);
    if (!valid) {
      setState(() => _errorMessage = 'Incorrect PIN');
      _pinController.clear();
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    await ref.read(authProvider.notifier).unlockWithBiometrics();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withAlpha(25),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.lock_rounded, size: 50, color: Colors.blueAccent),
            ),
            const SizedBox(height: 24),
            Text(
              'Vault',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white.withAlpha(230),
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: -20, end: 0),
            const SizedBox(height: 8),
            Text(
              'أدخل رمز القفل',
              style: TextStyle(color: Colors.white.withAlpha(128)),
            ),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _pinController,
                focusNode: _pinFocusNode,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 32, letterSpacing: 12, color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '● ● ● ●',
                  hintStyle: TextStyle(fontSize: 32, color: Colors.white.withAlpha(51), letterSpacing: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withAlpha(13),
                ),
                onSubmitted: (_) => _submitPin(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))
                  .animate().shake(duration: 400.ms),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPin,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('فتح', style: TextStyle(fontSize: 16)),
              ),
            ),
            if (state.canUseBiometrics) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _authenticateWithBiometrics,
                icon: const Icon(Icons.fingerprint, color: Colors.blueAccent),
                label: const Text('استخدم البصمة',
                    style: const TextStyle(color: Colors.blueAccent)),
              ),
            ],
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
