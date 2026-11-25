import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/database.dart';
import 'package:gestor_tareas_local/screens/tareas_page.dart';

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(MaterialApp(home: TareasPage(database: db)));
    await tester.pumpAndSettle();
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    // Drift libera la cach? de Streams con Timer.run. Avanzar el reloj
    // simulado permite completar ese temporizador antes de cerrar SQLite.
    await tester.pump(Duration.zero);
    await db.close();
  });

  testWidgets(
    'Permite agregar, editar, completar y eliminar desde la pantalla',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await tester.pumpWidget(MaterialApp(home: TareasPage(database: db)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Mi tarea');
      await tester.tap(find.text('Agregar tarea'));
      await tester.pumpAndSettle();
      expect(find.text('Mi tarea'), findsOneWidget);
      await tester.tap(find.byTooltip('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Tarea editada');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Tarea editada'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect((await db.listarTareas()).single.completada, isTrue);
      await tester.tap(find.byTooltip('Eliminar'));
      await tester.pumpAndSettle();
      expect(await db.listarTareas(), isEmpty);
      await tester.pumpWidget(const SizedBox());
      // Drift libera la cach? de Streams con Timer.run. Avanzar el reloj
      // simulado permite completar ese temporizador antes de cerrar SQLite.
      await tester.pump(Duration.zero);
      await db.close();
    },
  );
}
