import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _correoCtrl  = TextEditingController();
  final _passCtrl    = TextEditingController();
  bool _obscurePass  = true;
  bool _recordar     = false;

  static const _keyCorreo  = 'saved_correo';
  static const _keyPass    = 'saved_pass';
  static const _keyRecordar = 'recordar_pass';

  @override
  void initState() {
    super.initState();
    _cargarCredenciales();
  }

  Future<void> _cargarCredenciales() async {
    final prefs = await SharedPreferences.getInstance();
    final recordar = prefs.getBool(_keyRecordar) ?? false;
    if (recordar) {
      setState(() {
        _recordar = true;
        _correoCtrl.text = prefs.getString(_keyCorreo) ?? '';
        _passCtrl.text   = prefs.getString(_keyPass)   ?? '';
      });
    }
  }

  Future<void> _guardarCredenciales(String correo, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    if (_recordar) {
      await prefs.setBool(_keyRecordar, true);
      await prefs.setString(_keyCorreo, correo);
      await prefs.setString(_keyPass, pass);
    } else {
      await prefs.remove(_keyCorreo);
      await prefs.remove(_keyPass);
      await prefs.setBool(_keyRecordar, false);
    }
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final correo = _correoCtrl.text.trim();
    final pass   = _passCtrl.text;
    await _guardarCredenciales(correo, pass);
    final auth    = context.read<AuthProvider>();
    final success = await auth.login(correo, pass);
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/cotizaciones');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / título
                const Icon(Icons.request_quote_rounded,
                    size: 72, color: Colors.white),
                const SizedBox(height: 16),
                const Text('GEAPP',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4)),
                const Text('Sistema de Cotizaciones',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 48),

                // Card del formulario
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _correoCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Ingresa tu correo' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Ingresa tu contraseña' : null,
                          ),

                          // Recordar contraseña
                          Row(
                            children: [
                              Switch(
                                value: _recordar,
                                activeColor: const Color(0xFF1A237E),
                                onChanged: (v) =>
                                    setState(() => _recordar = v),
                              ),
                              const Text('Recordar contraseña',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),

                          // Mensaje de error
                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(auth.errorMessage!,
                                        style: const TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: auth.isLoading ? null : _login,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Iniciar sesión',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Enlace a registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes cuenta?',
                        style: TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/registro'),
                      child: const Text('Regístrate',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
