import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cotizacion_provider.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/cotizaciones_list_screen.dart';
import 'screens/cotizacion_create_screen.dart';
import 'screens/cotizacion_detail_screen.dart';
import 'screens/cotizacion_edit_screen.dart';

void main() {
  runApp(const GeappApp());
}

class GeappApp extends StatelessWidget {
  const GeappApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CotizacionProvider()),
      ],
      child: MaterialApp(
        title: 'GEAPP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/':                   (_) => const _SplashRouter(),
          '/login':              (_) => const LoginScreen(),
          '/registro':           (_) => const RegistroScreen(),
          '/cotizaciones':       (_) => const CotizacionesListScreen(),
          '/cotizacion/crear':   (_) => const CotizacionCreateScreen(),
          '/cotizacion/detalle': (_) => const CotizacionDetailScreen(),
          '/cotizacion/editar':  (_) => const CotizacionEditScreen(),
        },
      ),
    );
  }
}

/// Splash que verifica token y redirige a login o cotizaciones
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    // Pequeño delay para que el árbol de widgets esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.checkToken();
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          auth.isAuthenticated ? '/cotizaciones' : '/login',
        );
      }
    } catch (_) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A237E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.request_quote_rounded, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'GEAPP',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
