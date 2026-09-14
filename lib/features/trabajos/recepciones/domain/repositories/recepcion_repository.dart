import 'dart:typed_data';

import '../models/recepcion_vehiculo.dart';

abstract class RecepcionRepository {
  Future<List<RecepcionVehiculo>> getAll({
    RecepcionEstado? estado,
    String? clienteId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<RecepcionVehiculo?> getById(String id);

  Future<RecepcionVehiculo> create(RecepcionVehiculo recepcion);

  Future<RecepcionVehiculo> update(RecepcionVehiculo recepcion);

  Future<String> generarSiguienteNumero({required int anio});

  Future<String> subirFotografia(Uint8List bytes, String nombreArchivo);

  Future<String> subirFirma(Uint8List bytes, String nombreArchivo);
}
