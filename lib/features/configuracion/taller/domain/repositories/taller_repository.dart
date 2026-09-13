import 'dart:typed_data';

import '../models/taller_info.dart';

abstract class TallerRepository {
  Future<TallerInfo> getInfo();
  Future<TallerInfo> guardarInfo(TallerInfo info);
  Future<String> subirLogo(Uint8List bytes, String nombreArchivo);
  Future<void> eliminarLogoPorUrl(String logoUrl);
}
