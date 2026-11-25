import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/database.dart';

void main() {
  test('Rechaza títulos vacíos al crear y editar; recorta espacios', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    for (final titulo in ['', '   ', '\n\t']) {
      expect(() => db.agregarTarea(titulo), throwsArgumentError);
    }
    expect(await db.listarTareas(), isEmpty);
    final id = await db.agregarTarea('  Estudiar SQLite  ');
    expect(() => db.editarTitulo(id, '  '), throwsArgumentError);
    expect((await db.listarTareas()).single.titulo, 'Estudiar SQLite');
  });

  test(
    'CRUD persiste al cerrar y reabrir un archivo SQLite real (P1-P4)',
    () async {
      final dir = await Directory.systemTemp.createTemp('tareas_test_');
      final file = File('${dir.path}/tareas.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      Future<void> reabrir() async {
        await db.close();
        db = AppDatabase(NativeDatabase(file));
      }

      final primero = await db.agregarTarea('Uno');
      final segundo = await db.agregarTarea('Dos');
      final tercero = await db.agregarTarea('Tres');
      expect({primero, segundo, tercero}.length, 3);
      await reabrir();
      expect((await db.listarTareas()).map((t) => t.titulo), [
        'Uno',
        'Dos',
        'Tres',
      ]);
      await db.cambiarEstado(primero, true);
      await reabrir();
      expect((await db.listarTareas()).first.completada, isTrue);
      await db.editarTitulo(segundo, 'Dos editada');
      await reabrir();
      expect((await db.listarTareas())[1].titulo, 'Dos editada');
      await db.eliminarTarea(tercero);
      await reabrir();
      expect((await db.listarTareas()).map((t) => t.id), [primero, segundo]);
      await db.cambiarEstado(primero, false);
      await reabrir();
      expect((await db.listarTareas()).first.completada, isFalse);
    },
  );

  test('La consulta reactiva recibe las escrituras', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final eventos = StreamIterator(db.observarTareas());
    addTearDown(eventos.cancel);
    expect(await eventos.moveNext(), isTrue);
    expect(eventos.current, isEmpty);
    await db.agregarTarea('Reactiva');
    expect(await eventos.moveNext(), isTrue);
    expect(eventos.current.single.titulo, 'Reactiva');
  });
}
