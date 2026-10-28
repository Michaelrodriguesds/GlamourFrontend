import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/services/cache_service.dart';
import 'data/services/connectivity_service.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/calendar/calendar_screen.dart';
import 'presentation/screens/appointments/appointment_form_screen.dart';
import 'presentation/screens/stats/stats_screen.dart';
import 'presentation/screens/notes/notes_screen.dart';
import 'presentation/screens/clients/clients_screen.dart';
import 'presentation/widgets/bottom_nav.dart';
import 'presentation/widgets/offline_banner.dart';
import 'providers/auth_provider.dart';
import 'providers/refresh_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // `runApp` é chamado IMEDIATAMENTE — nada é esperado (`await`) antes
  // disso. A primeira tela (splash) aparece assim que possível; a
  // inicialização (data formatting + cache + conectividade) roda depois,
  // dentro do próprio widget, em paralelo (Future.wait) em vez de em
  // sequência. Isso corta o tempo até a primeira renderização sem
  // introduzir condição de corrida: nenhuma tela que depende de
  // CacheService/ConnectivityService é construída antes de `_ready`
  // completar (ver _GlamourAppState.build abaixo).
  runApp(const ProviderScope(child: GlamourApp()));
}

class GlamourApp extends StatefulWidget {
  const GlamourApp({super.key});
  @override
  State<GlamourApp> createState() => _GlamourAppState();
}

class _GlamourAppState extends State<GlamourApp> {
  late final Future<void> _ready = _init();

  Future<void> _init() => Future.wait([
    initializeDateFormatting('pt_BR'),
    CacheService.init(),          // cache local
    ConnectivityService().init(), // monitoramento de internet
  ]);

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Glamour Agenda',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    // Em telas grandes (PC/notebook) o app não estica pela tela inteira:
    // fica centralizado com largura máxima de 1100 px. No celular a
    // largura é menor que isso e nada muda.
    builder: (context, child) => ColoredBox(
      color: AppColors.background,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
    home: FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        // Enquanto CacheService/ConnectivityService não terminaram de
        // inicializar, mostra só o splash — nada que dependa deles é
        // construído ainda, então não há risco de erro de inicialização.
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }
        return const _AuthGate();
      },
    ),
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

  // Construtores (não instâncias prontas) — cada tela só é efetivamente
  // criada (e, portanto, só dispara suas próprias requisições) na
  // primeira vez que o usuário abre aquela aba. Antes, `IndexedStack`
  // recebia as 5 telas já instanciadas de uma vez (_screens const),
  // então Home + Calendário + Estatísticas + Notas + Clientes disparavam
  // suas chamadas de API TODAS ao mesmo tempo, assim que o app abria —
  // mesmo que o usuário só fosse olhar a tela inicial.
  static const List<Widget Function()> _builders = [
    HomeScreen.new,
    CalendarScreen.new,
    StatsScreen.new,
    NotesScreen.new,
    ClientsScreen.new,
  ];

  // Quais abas já foram abertas pelo menos uma vez. Home (índice 0) já
  // começa "visitada" pois é a tela inicial. Uma vez visitada, a tela
  // continua viva dentro do IndexedStack (mesmo comportamento de antes:
  // o estado de rolagem/filtros da aba é preservado ao trocar de aba).
  final Set<int> _visited = {0};

  int _navToScreen(int navIndex) => navIndex > 2 ? navIndex - 1 : navIndex;
  int _screenToNav(int screenIndex) => screenIndex >= 2 ? screenIndex + 1 : screenIndex;

  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AppointmentFormScreen(),
        ),
      ).then((_) => ref.read(refreshProvider.notifier).state++);
      return;
    }
    final screenIndex = _navToScreen(navIndex);
    if (screenIndex != _index) ref.read(refreshProvider.notifier).state++;
    setState(() {
      _index = screenIndex;
      _visited.add(screenIndex);
    });
  }

  // Mantém o estado das abas (rolagem, filtros) quando a janela muda
  // entre "celular" e "tela larga": o conteúdo troca de lugar na árvore,
  // mas com esta chave o Flutter o move em vez de recriá-lo.
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Tela larga = PC/notebook (largura >= 800 e altura >= 500).
      // Celular, mesmo deitado, continua com a barra de baixo.
      final wide = constraints.maxWidth >= 800 && constraints.maxHeight >= 500;

      final content = KeyedSubtree(
        key: _contentKey,
        child: Column(
          children: [
            // ── Banner offline (aparece/some com animação) ────────────
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: List.generate(
                  _builders.length,
                  // Abas ainda não visitadas renderizam um espaço vazio
                  // (sem custo, sem requisição) até o usuário realmente
                  // tocar nelas pela primeira vez.
                  (i) => _visited.contains(i) ? _builders[i]() : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );

      if (!wide) {
        return Scaffold(
          body: content,
          bottomNavigationBar: AppBottomNav(
            currentIndex: _screenToNav(_index),
            onTap: _onNavTap,
          ),
        );
      }

      return Scaffold(
        body: Row(
          children: [
            AppSideNav(
              currentIndex: _screenToNav(_index),
              onTap: _onNavTap,
            ),
            Expanded(child: content),
          ],
        ),
      );
    },
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
        Text('Glamour Agenda',
            style: TextStyle(
                color: Color(0xFFF5EEF8), fontSize: 24, fontWeight: FontWeight.w700)),
        SizedBox(height: 24),
        CircularProgressIndicator(color: Color(0xFFE8527A), strokeWidth: 2.5),
      ]),
    ),
  );
}
