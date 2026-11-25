import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/database.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key, this.database});
  final AppDatabase? database;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final _tituloController = TextEditingController();
  late final AppDatabase _db;
  StreamSubscription<List<TareaRegistro>>? _subscription;
  List<TareaRegistro> _tareas = [];
  bool _cargando = true;
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase();
    _escuchar();
  }

  void _escuchar() {
    _subscription = _db.observarTareas().listen(
      (tareas) {
        if (!mounted) return;
        setState(() {
          _tareas = tareas;
          _cargando = false;
          _error = null;
        });
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Error al consultar SQLite: $error');
        if (!mounted) return;
        setState(() {
          _cargando = false;
          _error = 'No se pudieron cargar las tareas. Intenta de nuevo.';
        });
      },
    );
  }

  Future<void> _reintentar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    await _subscription?.cancel();
    if (mounted) _escuchar();
  }

  Future<void> _guardar(Future<void> Function() accion) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await accion();
    } on ArgumentError catch (error) {
      _mensaje(error.message.toString());
    } catch (error) {
      debugPrint('Error al escribir en SQLite: $error');
      _mensaje('No se pudo guardar el cambio. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _agregar() => _guardar(() async {
    await _db.agregarTarea(_tituloController.text);
    if (mounted) _tituloController.clear();
  });

  Future<void> _editar(TareaRegistro tarea) async {
    final titulo = await showDialog<String>(
      context: context,
      builder: (_) => _EditarDialog(titulo: tarea.titulo),
    );
    if (titulo == null || !mounted) return;
    await _guardar(() async {
      await _db.editarTitulo(tarea.id, titulo);
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    if (widget.database == null) unawaited(_db.close());
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gestor de tareas')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              enabled: !_ocupado && !_cargando && _error == null,
              onSubmitted: (_) => _agregar(),
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _ocupado || _cargando || _error != null
                  ? null
                  : _agregar,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            if (_ocupado) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          TextButton(
                            onPressed: _reintentar,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _tareas.isEmpty
                  ? const Center(child: Text('Todavía no hay tareas guardadas'))
                  : ListView.builder(
                      itemCount: _tareas.length,
                      itemBuilder: (context, index) {
                        final tarea = _tareas[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: tarea.completada,
                              onChanged: _ocupado
                                  ? null
                                  : (valor) {
                                      if (valor != null) {
                                        _guardar(() async {
                                          await _db.cambiarEstado(
                                            tarea.id,
                                            valor,
                                          );
                                        });
                                      }
                                    },
                            ),
                            title: Text(
                              tarea.titulo,
                              style: TextStyle(
                                decoration: tarea.completada
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              tarea.completada ? 'Completada' : 'Pendiente',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit),
                                  onPressed: _ocupado
                                      ? null
                                      : () => _editar(tarea),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: _ocupado
                                      ? null
                                      : () => _guardar(() async {
                                          await _db.eliminarTarea(tarea.id);
                                        }),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EditarDialog extends StatefulWidget {
  const _EditarDialog({required this.titulo});
  final String titulo;
  @override
  State<_EditarDialog> createState() => _EditarDialogState();
}

class _EditarDialogState extends State<_EditarDialog> {
  late final _controller = TextEditingController(text: widget.titulo);
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar tarea'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Título'),
        onFieldSubmitted: (_) => _aceptar(),
        validator: (valor) =>
            (valor ?? '').trim().isEmpty ? 'Escribe un título.' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _aceptar, child: const Text('Guardar')),
    ],
  );
}
