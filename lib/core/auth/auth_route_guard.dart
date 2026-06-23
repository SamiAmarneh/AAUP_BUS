import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

class AuthLoginRouteGuard extends ConsumerStatefulWidget {
  const AuthLoginRouteGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthLoginRouteGuard> createState() =>
      _AuthLoginRouteGuardState();
}

class _AuthLoginRouteGuardState extends ConsumerState<AuthLoginRouteGuard> {
  var _redirectScheduled = false;

  void _redirectAuthenticatedUser() {
    if (_redirectScheduled) {
      return;
    }
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    ref.watch(signInSessionTickProvider);
    final isSignInInProgress = ref.read(authRepositoryProvider).isSignInInProgress;

    return authState.when(
      data: (user) {
        if (user != null && !isSignInInProgress) {
          _redirectAuthenticatedUser();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.child;
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => widget.child,
    );
  }
}
