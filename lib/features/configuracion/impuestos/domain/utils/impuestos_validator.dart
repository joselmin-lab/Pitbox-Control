double? parsePorcentajeImpuesto(String? value) {
  final normalized = (value ?? '').replaceAll(',', '.').trim();
  return double.tryParse(normalized);
}

String? validarPorcentajeImpuesto(String? value) {
  final parsed = parsePorcentajeImpuesto(value);
  if (parsed == null) {
    return 'Ingresa un valor numérico válido.';
  }
  if (parsed < 0 || parsed > 100) {
    return 'El valor debe estar entre 0 y 100.';
  }
  return null;
}

String? validarSumaImpuestos({
  required double porcentajeIva,
  required double porcentajeIt,
}) {
  if (porcentajeIva + porcentajeIt > 100) {
    return 'La suma de IVA + IT no puede superar 100%.';
  }
  return null;
}
