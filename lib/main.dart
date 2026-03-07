import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/calendar/calendar_screen.dart';
import 'presentation/screens/appointments/appointment_form_screen.dart';
import 'presentation/screens/stats/stats_screen.dart';
import 'presentation/screens/clients/clients_screen.dart';
import 'presentation/widgets/bottom_nav.dart';
import 'providers/auth_provider.dart';
import 'providers/refresh_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(const ProviderScope(child: GlamourApp()));
}

class GlamourApp extends StatelessWidget {
  const GlamourApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Glamour Agenda',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const _AuthGate(),
  );
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(authProvider).status) {
      case AuthStatus.checking:        return const _SplashScreen();
      case AuthStatus.unauthenticated: return const LoginScreen();
      case AuthStatus.authenticated:   return const _MainShell();
    }
  }
}

// ── Shell principal ───────────────────────────────────────────────
class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();
  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _index = 0;

  // 4 telas no IndexedStack — "Novo" abre como modal separado
  static const List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(),
    StatsScreen(),
    ClientsScreen(),
  ];

  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      // Aba "Novo" → abre formulário como modal
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AppointmentFormScreen(),
        ),
      ).then((_) {
        // Ao fechar o formulário → força reload de todas as telas
        ref.read(refreshProvider.notifier).state++;
      });
      return;
    }

    // Converte índice da nav (0,1,3,4) → índice do IndexedStack (0,1,2,3)
    final screenIndex = navIndex > 2 ? navIndex - 1 : navIndex;

    if (screenIndex != _index) {
      // Ao trocar de aba → força reload da tela de destino
      ref.read(refreshProvider.notifier).state++;
    }
    setState(() => _index = screenIndex);
  }

  // Nav index leva em conta que "Novo" é a posição 2
  int get _navIndex => _index >= 2 ? _index + 1 : _index;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: _screens),
    bottomNavigationBar: AppBottomNav(
      currentIndex: _navIndex,
      onTap: _onNavTap,
    ),
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🌸', style: TextStyle(fontSize: 60)),
        SizedBox(height: 16),
        Text('Glamour Agenda', style: TextStyle(color: Color(0xFFF5EEF8), fontSize: 24, fontWeight: FontWeight.w700)),
        SizedBox(height: 24),
        CircularProgressIndicator(color: Color(0xFFE8527A), strokeWidth: 2.5),
      ]),
    ),
  );
}