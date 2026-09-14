import '../models/taller_info.dart';

bool tallerInfoPermiteCrearProformas(TallerInfo? info) {
  final nombre = info?.nombre.trim() ?? '';
  final telefono = info?.telefono?.trim() ?? '';
  final correo = info?.correo?.trim() ?? '';
  if (nombre.isEmpty) {
    return false;
  }
  return telefono.isNotEmpty || correo.isNotEmpty;
}
