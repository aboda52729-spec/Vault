import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../services/bankak_store.dart';
import 'dashboard.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isSmsGranted = false;
  bool _isNotificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final smsStatus = await Permission.sms.status;
    final notificationStatus = await Permission.notification.status;
    setState(() {
      _isSmsGranted = smsStatus.isGranted;
      _isNotificationGranted = notificationStatus.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.notification,
    ].request();

    setState(() {
      _isSmsGranted = statuses[Permission.sms]?.isGranted ?? false;
      _isNotificationGranted = statuses[Permission.notification]?.isGranted ?? false;
    });

    if (_isSmsGranted && _isNotificationGranted) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainDashboard()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BankakStore>(context);
    final isAr = store.isArabic;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.security_rounded, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 30),
            Text(
              isAr ? 'خطوات التفعيل الأساسية' : 'Essential Activation Steps',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              isAr 
                ? 'لربط التطبيق بحسابك في بنكك، نحتاج لصلاحية قراءة الرسائل لاستخراج العمليات المالية فور وصولها.'
                : 'To connect the app with your Bankak account, we need permission to read SMS to extract transactions as they arrive.',
              style: TextStyle(color: Colors.white.withAlpha(150)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _PermissionTile(
              icon: Icons.sms_rounded,
              title: isAr ? 'صلاحية الرسائل (SMS)' : 'SMS Permission',
              isGranted: _isSmsGranted,
            ),
            const SizedBox(height: 10),
            _PermissionTile(
              icon: Icons.notifications_active_rounded,
              title: isAr ? 'صلاحية الإشعارات' : 'Notifications Permission',
              isGranted: _isNotificationGranted,
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _requestPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  isAr ? 'منح الصلاحيات والبدء' : 'Grant Permissions & Start',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainDashboard()),
                );
              },
              child: Text(
                isAr ? 'تخطي الآن (وضع المحاكاة)' : 'Skip for now (Simulation Mode)',
                style: TextStyle(color: Colors.white.withAlpha(100)),
              ),
            ),
          ],
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
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 15),
          Expanded(child: Text(title)),
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isGranted ? Colors.greenAccent : Colors.white24,
          ),
        ],
      ),
    );
  }
}
