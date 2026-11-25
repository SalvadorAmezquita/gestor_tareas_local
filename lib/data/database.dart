import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DataClassName('TareaRegistro')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo =>
      text().customConstraint('NOT NULL CHECK (length(trim(titulo)) > 0)')();
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'gestor_tareas',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.dart.js'),
                onResult: (result) {
                  if (result.chosenImplementation ==
                      WasmStorageImplementation.inMemory) {
                    unawaited(result.resolvedExecutor.close());
                    throw StateError(
                      'El navegador no permite almacenamiento persistente.',
                    );
                  }
                },
              ),
            ),
      );

  @override
  int get schemaVersion => 1;

  static String validarTitulo(String titulo) {
    final limpio = titulo.trim();
    if (limpio.isEmpty) {
      throw ArgumentError('Escribe un título que no esté vacío.');
    }
    return limpio;
  }

  Stream<List<TareaRegistro>> observarTareas() =>
      (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<List<TareaRegistro>> listarTareas() =>
      (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<int> agregarTarea(String titulo) =>
      into(tareas)
          .insert(TareasCompanion.insert(titulo: validarTitulo(titulo)));

  Future<int> editarTitulo(int id, String titulo) =>
      (update(tareas)..where((t) => t.id.equals(id))).write(
        TareasCompanion(titulo: Value(validarTitulo(titulo))),
      );

  Future<int> cambiarEstado(int id, bool completada) =>
      (update(tareas)..where((t) => t.id.equals(id))).write(
        TareasCompanion(completada: Value(completada)),
      );

  Future<int> eliminarTarea(int id) =>
      (delete(tareas)..where((t) => t.id.equals(id))).go();
}
