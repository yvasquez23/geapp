import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/cotizacion_provider.dart';

class CotizacionesListScreen extends StatefulWidget {
  const CotizacionesListScreen({super.key});

  @override
  State<CotizacionesListScreen> createState() => _CotizacionesListScreenState();
}

class _CotizacionesListScreenState extends State<CotizacionesListScreen> {
  final _currFmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CotizacionProvider>().fetchCotizaciones();
    });
  }

  Future<void> _refresh() =>
      context.read<CotizacionProvider>().fetchCotizaciones();

  Future<void> _confirmDelete(BuildContext ctx, int id) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cotización'),
        content: const Text('¿Estás seguro de que deseas eliminar esta cotización?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && ctx.mounted) {
      await ctx.read<CotizacionProvider>().deleteCotizacion(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final prov = context.watch<CotizacionProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Cotizaciones'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva cotización'),
        onPressed: () => Navigator.pushNamed(context, '/cotizacion/crear')
            .then((_) => _refresh()),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? _ErrorView(message: prov.error!, onRetry: _refresh)
              : prov.cotizaciones.isEmpty
                  ? _EmptyView(onRefresh: _refresh)
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: prov.cotizaciones.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final cot = prov.cotizaciones[i];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0xFF1A237E).withValues(alpha: 0.1),
                                child: Text(
                                  '#${cot.cotizacionId}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E)),
                                ),
                              ),
                              title: Text(
                                'Cotización #${cot.cotizacionId}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (cot.cotizacionFecha != null)
                                    Text(
                                        'Fecha: ${_dateFmt.format(cot.cotizacionFecha!)}',
                                        style: const TextStyle(fontSize: 12)),
                                  if (cot.clienteId != null)
                                    Text('Cliente ID: ${cot.clienteId}',
                                        style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currFmt.format(cot.cotizacionBalance ?? 0),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A237E),
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(ctx, cot.cotizacionId),
                                    child: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/cotizacion/detalle',
                                arguments: cot,
                              ).then((_) => _refresh()),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No hay cotizaciones registradas'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      );
}
