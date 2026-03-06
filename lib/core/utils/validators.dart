/// Validadores para os campos do formulário
class Validators {
  Validators._();

  static String? required(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return '$fieldName é obrigatório';
    return null;
  }

  static String? clientName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nome da cliente é obrigatório';
    if (v.trim().length < 2) return 'Nome muito curto';
    return null;
  }

  static String? price(String? v) {
    if (v == null || v.trim().isEmpty) return 'Valor é obrigatório';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return 'Valor inválido';
    if (n < 0)     return 'Valor não pode ser negativo';
    return null;
  }

  static String? notes(String? v) {
    if (v != null && v.length > 500) return 'Máximo 500 caracteres';
    return null;
  }
}