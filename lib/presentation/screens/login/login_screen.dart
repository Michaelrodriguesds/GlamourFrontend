import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool  _obscure  = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      _userCtrl.text.trim(),
      _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final loading = state.status == AuthStatus.checking;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ────────────────────
                  const Center(
                    child: Text('🌸', style: TextStyle(fontSize: 56)),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Glamour Agenda',
                      style: TextStyle(
                        color:      AppColors.text,
                        fontSize:   26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Agenda Estética',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Usuário ─────────────────
                  const Text('Usuário', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller:  _userCtrl,
                    style: const TextStyle(color: AppColors.text),
                    decoration:  const InputDecoration(
                      hintText:    'glamour',
                      prefixIcon:  Icon(Icons.person_outline, color: AppColors.textMuted),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o usuário' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Senha ───────────────────
                  const Text('Senha', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller:   _passCtrl,
                    obscureText:  _obscure,
                    style: const TextStyle(color: AppColors.text),
                    decoration:   InputDecoration(
                      hintText:    '••••••••',
                      prefixIcon:  const Icon(Icons.lock_outline, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                  ),
                  const SizedBox(height: 12),

                  // ── Erro ────────────────────
                  if (state.error != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:        AppColors.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:       Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.rose, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Botão ───────────────────
                  ElevatedButton(
                    onPressed: loading ? null : _login,
                    child: loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('ENTRAR'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}