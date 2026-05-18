import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final setupProvider = StateNotifierProvider<SetupNotifier, SetupState>((ref) {
  return SetupNotifier();
});

class SetupState {
  final bool isSmsGranted;
  final bool isNotificationGranted;
  final bool isLoading;

  const SetupState({
    this.isSmsGranted = false,
    this.isNotificationGranted = false,
    this.isLoading = false,
  });

  SetupState copyWith({
    bool? isSmsGranted,
    bool? isNotificationGranted,
    bool? isLoading,
  }) {
    return SetupState(
      isSmsGranted: isSmsGranted ?? this.isSmsGranted,
      isNotificationGranted: isNotificationGranted ?? this.isNotificationGranted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get allGranted => isSmsGranted && isNotificationGranted;
}

class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier() : super(const SetupState());

  Future<void> checkPermissions() async {
    final sms = await Permission.sms.status;
    final notif = await Permission.notification.status;
    state = state.copyWith(
      isSmsGranted: sms.isGranted,
      isNotificationGranted: notif.isGranted,
    );
  }

  Future<void> requestPermissions() async {
    state = state.copyWith(isLoading: true);
    final statuses = await [
      Permission.sms,
      Permission.notification,
    ].request();
    state = state.copyWith(
      isSmsGranted: statuses[Permission.sms]?.isGranted ?? false,
      isNotificationGranted: statuses[Permission.notification]?.isGranted ?? false,
      isLoading: false,
    );
  }
}
