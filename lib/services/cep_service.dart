import 'dart:convert';
import 'package:http/http.dart' as http;

class CepService {
  static Future<Map<String, dynamic>> consultar(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{8}$').hasMatch(digits)) {
      throw const FormatException('Informe um CEP válido com 8 dígitos.');
    }
    final uri = Uri.https('viacep.com.br', '/ws/$digits/json/');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Não foi possível consultar o CEP (HTTP ${response.statusCode}).');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (data['erro'] == true) throw const FormatException('CEP não encontrado. Confira os números.');
    return data;
  }
}
