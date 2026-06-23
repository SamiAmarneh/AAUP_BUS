import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/app_user.dart';
import '../auth/auth_providers.dart';
import '../auth/user_role.dart';
import '../../features/bus_company/data/driver_providers.dart';
import 'driver_notification_service.dart';

final driverNotificationServiceProvider = Provider<DriverNotificationService>((
  ref,
) {
  return DriverNotificationService(
    driverRepository: ref.watch(driverRepositoryProvider),
  );
});

final driverNotificationControllerProvider =
    Provider<DriverNotificationController>((ref) {
      ref.keepAlive();
      final controller = DriverNotificationController(
        ref,
        ref.read(driverNotificationServiceProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

class DriverNotificationController {
  DriverNotificationController(this._ref, this._service) {
    _profileSubscription = _ref.listen(
      currentUserProfileProvider,
      (_, next) => _handleProfileChange(next),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  final DriverNotificationService _service;
  ProviderSubscription<AsyncValue<AppUser?>>? _profileSubscription;

  void _handleProfileChange(AsyncValue<AppUser?> next) {
    next.when(
      data: (profile) {
        final isDriver = profile?.role == UserRole.driver;
        final driverUid = profile?.uid ?? '';
        if (!isDriver || driverUid.isEmpty) {
          unawaited(_service.stop());
          return;
        }
        unawaited(_service.startForDriver(driverUid));
      },
      loading: () => unawaited(_service.stop()),
      error: (_, __) => unawaited(_service.stop()),
    );
  }

  void dispose() {
    _profileSubscription?.close();
    unawaited(_service.stop());
  }
}
