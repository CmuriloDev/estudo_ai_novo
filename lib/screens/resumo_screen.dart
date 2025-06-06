import 'package:flutter/material.dart';        
import '../models/materia.dart';               
import '../services/wikipedia_service.dart';   // Serviço para integração com a API da Wikipedia
import '../widgets/custom_app_bar.dart';       

// Classe principal da tela de resumo - herda de StatefulWidget
// Esta tela exibe detalhes de uma matéria específica e temas relacionados da Wikipedia
class ResumoScreen extends StatefulWidget {
  const ResumoScreen({super.key});

  // Método obrigatório que cria o estado associado a este widget
  @override
  State<ResumoScreen> createState() => _ResumoScreenState();
}

// Classe que gerencia o estado da ResumoScreen
class _ResumoScreenState extends State<ResumoScreen> {
  // Variável que armazenará a matéria recebida como parâmetro de navegação
  late Materia materia;
  
  // Lista que armazena os temas relacionados encontrados na Wikipedia
  List<String> temasRelacionados = [];
  
  // Flag que controla se a busca por temas está em andamento
  bool isLoading = false;
  
  // Variável que armazena mensagens de erro, se houver
  String? erroMensagem;

  // Método chamado quando as dependências da tela mudam
  // É executado após o build e quando há mudanças nas dependências
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Recupera a matéria passada como argumento na navegação
    // O "!" indica que temos certeza de que o argumento existe
    materia = ModalRoute.of(context)!.settings.arguments as Materia;
    
    // Inicia a busca por temas relacionados na Wikipedia
    _buscarTemasRelacionados();
  }

  // Função assíncrona que busca temas relacionados à matéria na Wikipedia
  Future<void> _buscarTemasRelacionados() async {
    // Ativa o estado de carregamento e limpa erros anteriores
    setState(() {
      isLoading = true;
      erroMensagem = null;
    });

    try {
      // Chama o serviço da Wikipedia para buscar temas relacionados
      final temas = await WikipediaService.buscarTemasRelacionados(materia.nome);

      // Verifica se o widget ainda está montado antes de atualizar o estado
      // Previne erros se o usuário sair da tela durante a requisição
      if (mounted) {
        setState(() {
          temasRelacionados = temas;    // Atualiza a lista de temas
          isLoading = false;           // Remove o indicador de carregamento
        });
      }
    } catch (e) {
      // Em caso de erro na requisição
      if (mounted) {
        setState(() {
          erroMensagem = 'Erro ao buscar temas relacionados';
          isLoading = false;
        });
      }
    }
  }

  // Método principal que constrói a interface da tela
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior personalizada com título da matéria
      appBar: CustomAppBar(
        title: materia.nome,              // Nome da matéria como título
        actions: [
          // Botão de refresh para recarregar os temas relacionados
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _buscarTemasRelacionados,  // Chama a função de busca novamente
          ),
        ],
      ),
      
      // Corpo da tela com scroll vertical para acomodar todo o conteúdo
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),    // Margem interna de 16px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,  // Alinha à esquerda
            children: [
              // Card principal com informações da matéria
              Card(
                elevation: 4,                      // Sombra do card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),  // Bordas arredondadas
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título da seção de informações
                      const Text(
                        'Informações da Matéria',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),      // Espaçamento vertical
                      
                      // Linha de informação: Nome da matéria
                      _buildInfoRow(
                        Icons.book,
                        'Matéria',
                        materia.nome,
                      ),
                      const SizedBox(height: 12),
                      
                      // Linha de informação: Tempo de estudo formatado
                      _buildInfoRow(
                        Icons.timer,
                        'Tempo de Estudo',
                        '${materia.tempoEstudo.toStringAsFixed(1)} horas',  // 1 casa decimal
                      ),
                      const SizedBox(height: 12),
                      
                      // Linha de informação: Status com cor condicional
                      _buildInfoRow(
                        Icons.check_circle,
                        'Status',
                        materia.concluidoHoje ? 'Concluído' : 'Pendente',
                        statusColor: materia.concluidoHoje ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      
                      // Linha de informação: Data de criação formatada
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Adicionado em',
                        _formatarData(materia.dataCriacao),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),        // Espaçamento entre seções

              // Título da seção de temas relacionados
              const Text(
                'Temas Relacionados (Wikipedia)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Seção condicional para exibir diferentes estados dos temas relacionados
              
              // Estado 1: Carregando
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),  // Indicador de progresso circular
                )
              
              // Estado 2: Erro na requisição
              else if (erroMensagem != null)
                Card(
                  color: Colors.red[50],              // Fundo vermelho claro
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700]),  // Ícone de erro
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            erroMensagem!,            // Mensagem de erro
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              
              // Estado 3: Nenhum tema encontrado
              else if (temasRelacionados.isEmpty)
                  Card(
                    color: Colors.orange[50],         // Fundo laranja claro
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange[700]),  // Ícone informativo
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Nenhum tema relacionado encontrado',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                
                // Estado 4: Temas encontrados - constrói cards para cada tema
                else
                  // Mapeia cada tema para um widget FutureBuilder
                  ...temasRelacionados.map((tema) => FutureBuilder<String>(
                    // Para cada tema, busca seu resumo na Wikipedia
                    future: WikipediaService.buscarResumo(tema),
                    
                    // Builder que constrói o widget baseado no estado da Future
                    builder: (context, snapshot) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),  // Margem inferior
                        elevation: 2,                               // Sombra menor
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {},                             // Ação ao tocar (vazia por enquanto)
                          borderRadius: BorderRadius.circular(12), // Efeito de toque arredondado
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabeçalho do tema com ícone e título
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.article,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tema,                       // Nome do tema
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Conteúdo condicional baseado no estado da requisição do resumo
                                if (snapshot.connectionState == ConnectionState.waiting)
                                  // Carregando resumo
                                  const LinearProgressIndicator()
                                else if (snapshot.hasData)
                                  // Resumo carregado com sucesso
                                  Text(
                                    snapshot.data!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 3,                    // Máximo 3 linhas
                                    overflow: TextOverflow.ellipsis, // "..." se exceder
                                  )
                                else
                                  // Erro ao carregar resumo
                                  Text(
                                    'Erro ao carregar resumo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red[700],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )).toList(),                                      // Converte para lista de widgets
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper que constrói uma linha de informação padronizada
  // Recebe ícone, label, valor e opcionalmente uma cor para o status
  Widget _buildInfoRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      children: [
        // Ícone da informação
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        
        // Label descritivo
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        // Valor da informação (pode ter cor personalizada)
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,                 // Usa cor personalizada se fornecida
            ),
          ),
        ),
      ],
    );
  }

  // Função utilitária que formata uma data no padrão brasileiro (DD/MM/AAAA)
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    //      ↑ Dia com 2 dígitos                    ↑ Mês com 2 dígitos                          ↑ Ano
  }
}