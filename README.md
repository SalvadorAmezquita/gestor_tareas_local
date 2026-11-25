# Gestor de tareas SQLite

Aplicación Flutter para agregar, consultar, editar, completar y eliminar tareas. Usa SQLite local con Drift y funciona en web, Android y Windows.

## Ejecutar

Requiere Flutter compatible con `pubspec.yaml`. Android necesita un dispositivo o emulador; Windows necesita Visual Studio con desarrollo de escritorio con C++.

```powershell
flutter pub get
flutter run -d chrome --web-port 7357
flutter run -d windows
flutter devices
flutter run -d ID_DEL_ANDROID
```

Para comprobar la persistencia web con el mismo perfil, ejecutar `flutter run -d web-server --web-port 7357` y abrir `http://localhost:7357` en el navegador habitual. Conservar el mismo origen, puerto y perfil.

## Base de datos

`lib/data/database.dart` contiene la conexión, la tabla y las operaciones. `lib/screens/tareas_page.dart` muestra las tareas mediante un Stream. Las consultas se realizan fuera de `build()` y los recursos se liberan al cerrar la pantalla.

| Campo | Tipo | Restricción |
| --- | --- | --- |
| id | INTEGER | Clave primaria autoincremental |
| titulo | TEXT | Obligatorio y no vacío |
| completada | INTEGER | Booleano 0/1, inicialmente 0 |

Los títulos se recortan y se rechazan si están vacíos o solo contienen espacios. En Android y Windows se guarda `gestor_tareas.sqlite` en el directorio de documentos de la aplicación. En web se usa SQLite WebAssembly con almacenamiento OPFS o IndexedDB, según el navegador.

Los archivos `web/sqlite3.wasm` y `web/drift_worker.dart.js` proceden de la publicación `drift-2.35.4`. El worker original se llama `drift_worker.js`. Al publicar el sitio, el servidor debe servir `.wasm` como `application/wasm` y usar HTTPS o localhost.

Si cambia el esquema, regenerar el código y preparar la migración correspondiente:

```powershell
dart run build_runner build
```

## Pruebas

```powershell
flutter analyze
flutter test
```

Las cinco pruebas automatizadas pasaron: validación, persistencia CRUD en un archivo SQLite, actualización del Stream, apertura y operaciones desde la interfaz.

Se comprobó manualmente la conservación de altas, estado, edición y eliminación tras cerrar y abrir en web, Windows y Android 13 (celular 2201117SG). En web también se comprobó recargar y cerrar/reabrir la pestaña. Se confirmó el rechazo de entradas vacías en Android; en web y Windows falta registrar esa comprobación manual.

Para repetir las pruebas: crear tres tareas, cerrar y abrir; completar una y reiniciar; editar un título y reiniciar; eliminar una y reiniciar; intentar un título vacío. En web, recargar y cerrar/reabrir la pestaña manteniendo el origen y perfil.

Borrar datos del sitio o usar modo privado puede eliminar la información. Cada instalación tiene sus propios datos; no hay sincronización entre dispositivos.

## Entrega y fuentes

El archivo editable es `reporte.docx`: incluye portada opcional, campos para los datos y espacios para capturas. Completar nombre y URL antes de entregar. La consigna original solicita la URL de GitHub y un PDF de máximo dos páginas sin portada adicional; retirar la portada opcional y exportar el contenido a PDF si se mantiene ese criterio. Incluir código, pruebas, `pubspec.yaml`, `pubspec.lock` y recursos web; excluir `build/`, `.dart_tool/` y bases personales. Mantener un historial de commits que refleje el trabajo realizado.

- https://drift.simonbinder.eu/setup/ : tablas y generación de código.
- https://drift.simonbinder.eu/platforms/web/ : SQLite WebAssembly y almacenamiento web.
- https://github.com/simolus3/drift/releases/tag/drift-2.35.4 : recursos web compatibles.

Se utilizó chatgpt para apoyar con las pruebas, documentación y algunas dudas, ejecuté las cinco pruebas automatizadas y comprobé la persistencia en los tres entornos.

