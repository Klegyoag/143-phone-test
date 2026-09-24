import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/account_recovery_screen.dart';
import '../features/auth/presentation/recovery_code_screen.dart';
import '../features/auth/presentation/recovery_confirm_screen.dart';
import '../features/auth/presentation/regenerate_recovery_code_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/couple/presentation/couple_setup_screen.dart';
import '../features/calls/presentation/call_session_screen.dart';
import '../features/couple/presentation/invite_flow_screen.dart';
import '../features/couple/presentation/invite_scanner_screen.dart';
import '../features/legal/presentation/legal_screen.dart';
import '../features/home/presentation/daily_connection_screen.dart';
import '../features/home/presentation/widget_quick_ping_screen.dart';
import '../features/memories/presentation/memory_detail_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/shell/presentation/main_shell.dart';
import '../features/startup/presentation/bootstrap_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/bootstrap',
  routes: [
    GoRoute(path: '/bootstrap', builder: (_, __) => const BootstrapScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/', redirect: (_, __) => '/bootstrap'),
    GoRoute(path: '/recover-account', builder: (_, __) => const AccountRecoveryScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/recovery-code', builder: (_, state) => RecoveryCodeScreen(code: (state.extra ?? '').toString())),
    GoRoute(path: '/recovery-confirm', builder: (_, __) => const RecoveryConfirmScreen()),
    GoRoute(path: '/regenerate-recovery-code', builder: (_, __) => const RegenerateRecoveryCodeScreen()),
    GoRoute(path: '/legal', builder: (_, __) => const LegalScreen()),
    GoRoute(path: '/daily', builder: (_, __) => const DailyConnectionScreen()),
    GoRoute(path: '/widget-ping', builder: (_, __) => const WidgetQuickPingScreen()),
    GoRoute(path: '/invite-scan', builder: (_, __) => const InviteScannerScreen()),
    GoRoute(path: '/invite/:token', builder: (_, state) => InviteFlowScreen(token: Uri.decodeComponent(state.pathParameters['token'] ?? ''))),
    GoRoute(path: '/couple-setup', builder: (_, __) => const CoupleSetupScreen()),
    GoRoute(path: '/memory/:id', builder: (_, state) => MemoryDetailScreen(memoryId: state.pathParameters['id'] ?? '')),
    GoRoute(
      path: '/call/:id',
      builder: (_, state) => CallSessionScreen(
        callId: state.pathParameters['id'] ?? '',
        type: state.uri.queryParameters['type'] ?? 'audio',
        incoming: state.uri.queryParameters['incoming'] == '1',
      ),
    ),
    GoRoute(path: '/account-unavailable', builder: (_, __) => const AccountUnavailableScreen()),
    GoRoute(path: '/couple-unavailable', builder: (_, __) => const CoupleSpaceUnavailableScreen()),
    GoRoute(path: '/offline-startup', builder: (_, __) => const OfflineStartupScreen()),
    GoRoute(
      path: '/app',
      builder: (_, state) {
        final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
        return MainShell(initialIndex: tab.clamp(0, 4).toInt());
      },
    ),
  ],
);
