import '../models/taller_info.dart';

bool tallerInfoPermiteCrearProformas(TallerInfo? info) {
  final nombre = info?.nombre.trim() ?? '';
  if (nombre.isEmpty) {
    return false;
  }
  return nombre.toLowerCase() != 'mi taller';
}
