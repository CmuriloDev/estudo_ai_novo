
import 'dart:convert';                  
import 'package:http/http.dart' as http; 

// Classe de serviço responsável por integrar com a API da Wikipedia
// Fornece métodos para buscar temas relacionados e resumos de artigos
class WikipediaService {
  // URL base da API da Wikipedia em português
  // Todas as requisições serão feitas para este endpoint
  static const String _baseUrl = 'https://pt.wikipedia.org/w/api.php';

  // Método que busca temas relacionados a uma matéria usando a API OpenSearch
  // OpenSearch é uma funcionalidade da Wikipedia similar ao autocomplete
  static Future<List<String>> buscarTemasRelacionados(String materia) async {
    try {
      // Constrói a URL da requisição com parâmetros específicos
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'action': 'opensearch',      
        'search': materia,          
        'limit': '5',               
        'namespace': '0',           
        'format': 'json',           
      });

      // Executa a requisição HTTP GET de forma assíncrona
      final response = await http.get(url);

      // Verifica se a requisição foi bem-sucedida (código 200 = OK)
      if (response.statusCode == 200) {
        // Converte a resposta JSON em uma estrutura de dados Dart
        final data = jsonDecode(response.body);
        
        // A API OpenSearch retorna um array com 4 elementos:
        // [0] = termo pesquisado, [1] = títulos, [2] = descrições, [3] = URLs
        // Verifica se existe o elemento [1] (títulos) e se é uma lista
        if (data.length >= 2 && data[1] is List) {
          // Converte para List<String> e retorna os títulos encontrados
          return List<String>.from(data[1]);
        }
      }

      // Se não encontrou resultados ou houve erro, retorna lista vazia
      return [];
    } catch (e) {
      // Captura qualquer exceção (erro de rede, parsing JSON, etc.)
      print('Erro ao buscar temas na Wikipedia: $e');
      return [];
    }
  }

  // Método que busca o resumo de um artigo específico da Wikipedia
  // Usa a API Query para extrair o texto introdutório de um artigo
  static Future<String> buscarResumo(String titulo) async {
    try {
      // Constrói URL com parâmetros para buscar extratos de artigos
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'action': 'query',         
        'format': 'json',           
        'prop': 'extracts',         
        'exintro': 'true',          
        'explaintext': 'true',     
        'exsentences': '2',         
        'titles': titulo,           
      });

      // Executa a requisição HTTP GET
      final response = await http.get(url);

      // Verifica se a requisição foi bem-sucedida
      if (response.statusCode == 200) {
        // Decodifica a resposta JSON
        final data = jsonDecode(response.body);
        
        // Navega pela estrutura JSON da resposta da API
        // A estrutura é: data['query']['pages'][pageId]['extract']
        final pages = data['query']['pages'];

        // Verifica se existem páginas na resposta
        if (pages != null && pages.isNotEmpty) {
          // Pega a primeira (e geralmente única) página encontrada
          // pages é um Map onde as chaves são IDs das páginas
          final firstPage = pages.values.first;
          
          // Retorna o texto extraído ou mensagem padrão se vazio
          // O operador "??" retorna o valor da direita se o da esquerda for null
          return firstPage['extract'] ?? 'Sem resumo disponível';
        }
      }

      // Se chegou aqui, algo deu errado na requisição ou não encontrou a página
      return 'Erro ao buscar resumo';
    } catch (e) {
      // Captura qualquer exceção durante o processo
      print('Erro ao buscar resumo: $e');
      return 'Erro ao buscar resumo';
    }
  }
}
