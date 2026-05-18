import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/setup_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(setupProvider.notifier).checkPermissions());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(Icons.security_rounded, size: 72, color: Colors.blueAccent),
              ),
              const SizedBox(height: 30),
              Text('خطوات التفعيل الأساسية',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 20, end: 0),
              const SizedBox(height: 15),
              Text('لربط التطبيق بحسابك في بنكك، نحتاج لصلاحية قراءة الرسائل لاستخراج العمليات المالية فور وصولها.',
                style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _PermissionTile(
                icon: Icons.sms_rounded,
                title: 'صلاحية الرسائل (SMS)',
                isGranted: state.isSmsGranted,
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 10),
              _PermissionTile(
                icon: Icons.notifications_active_rounded,
                title: 'صلاحية الإشعارات',
                isGranted: state.isNotificationGranted,
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await ref.read(setupProvider.notifier).requestPermissions();
                          if (mounted && ref.read(setupProvider).allGranted) {
                            context.go('/');
                          }
                        },
                  child: state.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text(
                          'منح الصلاحيات والبدء',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  'تخطي الآن (وضع المحاكاة)',
                  style: TextStyle(color: Colors.white.withAlpha(100)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isGranted;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isGranted ? Colors.greenAccent.withAlpha(51) : Colors.white.withAlpha(13),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isGranted ? Colors.greenAccent : Colors.blueAccent),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isGranted ? Colors.greenAccent : Colors.white24,
          ),
        ],
      ),
    );
  }
}
