import 'dart:convert';                          
import 'package:shared_preferences/shared_preferences.dart';  
import '../models/materia.dart';                 

// Classe de serviço responsável por toda a persistência de dados da aplicação
// Utiliza SharedPreferences para armazenar dados localmente no dispositivo
class StorageService {
  // Constantes que definem as chaves usadas no SharedPreferences
  // Usar constantes evita erros de digitação e facilita manutenção
  static const String _materiasKey = 'materias';           
  static const String _progressoKey = 'progresso_diario';  

  // Método estático que salva a lista completa de matérias no armazenamento local
  // Recebe uma lista de objetos Materia e a converte para JSON antes de salvar
  static Future<void> salvarMaterias(List<Materia> materias) async {
    try {
      // Obtém uma instância do SharedPreferences (armazenamento local)
      final prefs = await SharedPreferences.getInstance();
      
    
      // .map() aplica a transformação em cada elemento da lista
      // toJson() converte o objeto para Map, jsonEncode() converte Map para String
      final List<String> materiasJson = materias
          .map((materia) => jsonEncode(materia.toJson()))
          .toList();
      
      // Salva a lista de strings JSON no SharedPreferences
      // setStringList() é específico para listas de strings
      await prefs.setStringList(_materiasKey, materiasJson);
    } catch (e) {
      // Captura qualquer erro durante o processo de salvamento
      // Em produção, seria melhor usar um sistema de logging mais robusto
      print('Erro ao salvar matérias: $e');
    }
  }

  // Método estático que carrega a lista de matérias do armazenamento local
  // Retorna uma lista de objetos Materia ou lista vazia se não houver dados
  static Future<List<Materia>> carregarMaterias() async {
    try {
      // Obtém uma instância do SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Tenta recuperar a lista de strings JSON usando a chave definida
      // O "?" indica que o resultado pode ser null se a chave não existir
      final List<String>? materiasJson = prefs.getStringList(_materiasKey);

      // Se não há dados salvos, retorna uma lista vazia
      if (materiasJson == null) return [];

      // Converte cada string JSON de volta para objeto Materia
      // jsonDecode() converte String para Map, fromJson() converte Map para Materia
      return materiasJson
          .map((json) => Materia.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      // Em caso de erro, imprime o erro e retorna lista vazia
      // Garante que a aplicação não quebra mesmo com dados corrompidos
      print('Erro ao carregar matérias: $e');
      return [];
    }
  }

  // Método que salva o progresso diário do usuário
  // Recebe um Map com estatísticas do dia e salva com a data atual como chave
  static Future<void> salvarProgressoDiario(Map<String, dynamic> progresso) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Obtém a data atual no formato ISO (YYYY-MM-DD)
      // toIso8601String() retorna formato "2023-10-15T14:30:00.000Z"
      // split('T')[0] pega apenas a parte da data "2023-10-15"
      final hoje = DateTime.now().toIso8601String().split('T')[0];
      
      // Salva o progresso com uma chave única baseada na data
      // Isso permite armazenar o progresso de cada dia separadamente
      await prefs.setString('${_progressoKey}_$hoje', jsonEncode(progresso));
    } catch (e) {
      print('Erro ao salvar progresso: $e');
    }
  }

  // Método que carrega o progresso dos últimos 7 dias
  // Retorna uma lista de Maps contendo os dados de progresso de cada dia
  static Future<List<Map<String, dynamic>>> carregarProgressoSemanal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Lista que armazenará o progresso de cada dia da semana
      final List<Map<String, dynamic>> progressoSemanal = [];

      // Loop que itera pelos últimos 7 dias (0 = hoje, 1 = ontem, etc.)
      for (int i = 0; i < 7; i++) {
        // Calcula a data de cada dia subtraindo 'i' dias da data atual
        final data = DateTime.now().subtract(Duration(days: i));
        
        // Converte a data para string no formato YYYY-MM-DD
        final dataString = data.toIso8601String().split('T')[0];
        
        // Tenta recuperar o progresso salvo para esta data específica
        final progressoJson = prefs.getString('${_progressoKey}_$dataString');

        // Se existe dados para este dia
        if (progressoJson != null) {
          // Converte o JSON de volta para Map
          final progresso = jsonDecode(progressoJson);
          
          // Adiciona a data ao Map para referência
          progresso['data'] = dataString;
          
          // Adiciona este dia à lista de progresso semanal
          progressoSemanal.add(progresso);
        }
        // Se não há dados para este dia, simplesmente não adiciona nada
        // Isso significa que dias sem estudo não aparecerão nos gráficos
      }

      return progressoSemanal;
    } catch (e) {
      print('Erro ao carregar progresso semanal: $e');
      return [];
    }
  }

  // Método utilitário para limpar todos os dados salvos
  // Útil para reset da aplicação ou durante desenvolvimento/testes
  static Future<void> limparDados() async {
    // Obtém instância do SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // Remove TODOS os dados salvos pela aplicação
    // CUIDADO: Este método apaga tudo irreversivelmente
    await prefs.clear();
  }
}

