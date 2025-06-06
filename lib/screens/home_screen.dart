// Importações necessárias para o funcionamento da tela
import 'package:flutter/material.dart';        // Biblioteca principal do Flutter para Material Design
import '../models/materia.dart';               // Modelo de dados que representa uma matéria
import '../services/storage_service.dart';     // Serviço para persistência de dados local
import '../widgets/materia_card.dart';         // Widget customizado para exibir cards de matéria
import '../widgets/custom_app_bar.dart';       // Barra superior personalizada
import 'adicionar_materia_screen.dart';        // Tela para adicionar novas matérias
import 'resumo_screen.dart';                   // Tela de resumo de uma matéria específica
import 'desempenho_screen.dart';              // Tela de gráficos e estatísticas

// Classe principal da tela inicial - herda de StatefulWidget
// StatefulWidget é usado quando a tela precisa se atualizar dinamicamente
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Método obrigatório que cria o estado associado a este widget
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Classe que gerencia o estado da HomeScreen
// Contém todas as variáveis e métodos que podem mudar durante a vida da tela
class _HomeScreenState extends State<HomeScreen> {
  // Lista que armazena todas as matérias carregadas do storage
  List<Materia> materias = [];
  
  // Flag que controla se a tela está em estado de carregamento
  bool isLoading = true;

  // Método chamado automaticamente quando a tela é criada
  // É executado apenas uma vez na vida do widget
  @override
  void initState() {
    super.initState();           // Chama o initState da classe pai
    _carregarMaterias();         // Inicia o carregamento das matérias
  }

  // Função assíncrona responsável por carregar as matérias do armazenamento local
  Future<void> _carregarMaterias() async {
    // Ativa o indicador de carregamento na interface
    setState(() => isLoading = true);

    try {
      // Tenta carregar as matérias usando o serviço de storage
      final materiasCarregadas = await StorageService.carregarMaterias();
      
      // Se bem-sucedido, atualiza o estado da tela
      setState(() {
        materias = materiasCarregadas;    // Atualiza a lista de matérias
        isLoading = false;               // Remove o indicador de carregamento
      });
    } catch (e) {
      // Em caso de erro, remove o carregamento e mostra erro
      setState(() => isLoading = false);
      _mostrarErro('Erro ao carregar matérias');
    }
  }

  // Função que alterna o status de conclusão de uma matéria específica
  Future<void> _toggleConcluido(int index) async {
    // Atualiza o estado local da matéria (marca/desmarca como concluída)
    setState(() {
      // Usa copyWith para criar uma nova instância com o campo alterado
      materias[index] = materias[index].copyWith(
        concluidoHoje: !materias[index].concluidoHoje,  // Inverte o status atual
      );
    });

    // Salva as alterações no armazenamento permanente
    await StorageService.salvarMaterias(materias);
    
    // Atualiza as estatísticas do dia baseado nas novas informações
    await _salvarProgressoDiario();
  }

  // Função que remove uma matéria após confirmação do usuário
  Future<void> _deletarMateria(int index) async {
    // Exibe um diálogo de confirmação antes de excluir
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir "${materias[index].nome}"?'),
        actions: [
          // Botão para cancelar a exclusão
          TextButton(
            onPressed: () => Navigator.pop(context, false),  // Retorna false
            child: const Text('Cancelar'),
          ),
          // Botão para confirmar a exclusão
          TextButton(
            onPressed: () => Navigator.pop(context, true),   // Retorna true
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Se o usuário confirmou a exclusão
    if (confirmar == true) {
      // Remove a matéria da lista local
      setState(() => materias.removeAt(index));
      
      // Salva a lista atualizada no storage
      await StorageService.salvarMaterias(materias);
      
      // Atualiza as estatísticas diárias
      await _salvarProgressoDiario();
    }
  }

  // Função que calcula e salva as estatísticas do progresso diário
  Future<void> _salvarProgressoDiario() async {
    // Conta o total de matérias cadastradas
    final totalMaterias = materias.length;
    
    // Conta quantas matérias foram marcadas como concluídas hoje
    final materiasCompletas = materias.where((m) => m.concluidoHoje).length;
    
    // Soma o tempo total de estudo das matérias concluídas hoje
    final tempoTotal = materias
        .where((m) => m.concluidoHoje)                    // Filtra apenas as concluídas
        .fold(0.0, (sum, m) => sum + m.tempoEstudo);      // Soma os tempos de estudo

    // Salva as estatísticas calculadas no storage para uso em relatórios
    await StorageService.salvarProgressoDiario({
      'totalMaterias': totalMaterias,
      'materiasCompletas': materiasCompletas,
      'tempoTotal': tempoTotal,
    });
  }

  // Função utilitária para exibir mensagens de erro ao usuário
  void _mostrarErro(String mensagem) {
    // Usa ScaffoldMessenger para exibir uma SnackBar na parte inferior da tela
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,    // Cor vermelha para indicar erro
      ),
    );
  }

  // Método principal que constrói a interface da tela
  // É chamado sempre que setState() é executado
  @override
  Widget build(BuildContext context) {
    return Scaffold(                    // Estrutura básica de uma tela Flutter
      // Barra superior da aplicação
      appBar: CustomAppBar(
        title: 'Estuda Aí',
        actions: [
          // Botão para navegar para a tela de desempenho/estatísticas
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DesempenhoScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
    decoration: BoxDecoration(
    image: DecorationImage(
    image: AssetImage('assets/images/Papel de Parede Adesivo NUVEM.jpeg'), // Altere o caminho para sua imagem
    fit: BoxFit.cover,
      ),
    ),
      // Corpo principal da tela - usa condicionais para decidir o que exibir
      child: isLoading
          ? const Center(child: CircularProgressIndicator())    // Mostra loading
          : materias.isEmpty
          ? _buildEmptyState()                                  // Mostra tela vazia
          : _buildMateriasList(),
      ),                             // Mostra lista de matérias
      
      // Botão flutuante para adicionar novas matérias
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navega para a tela de adicionar matéria e aguarda o resultado
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdicionarMateriaScreen()),
          );

          // Se uma nova matéria foi criada (resultado não é null)
          if (resultado != null && resultado is Materia) {
            setState(() => materias.add(resultado));          // Adiciona à lista local
            await StorageService.salvarMaterias(materias);    // Salva no storage
          }
        },
        backgroundColor: Theme.of(context).primaryColor,      // Cor do tema
        child: const Icon(Icons.add),                         // Ícone de "+"
      ),
    );
  }

  // Widget que constrói a tela quando não há matérias cadastradas
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,         // Centraliza verticalmente
        children: [
          // Ícone grande de escola
          Icon(
            Icons.school,
            size: 100,
            color: Colors.grey[400],                          // Cor acinzentada suave
          ),
          const SizedBox(height: 16),                        // Espaçamento vertical
          
          // Texto principal informativo
          Text(
            'Nenhuma matéria cadastrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),                         // Espaçamento menor
          
          // Texto de orientação ao usuário
          Text(
            'Toque no + para adicionar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],                        // Cor mais clara
            ),
          ),
        ],
      ),
    );
  }

  // Widget que constrói a lista principal quando há matérias cadastradas
  Widget _buildMateriasList() {
    return Column(
      children: [
        // Container do card de resumo/estatísticas no topo
        Container(
          margin: const EdgeInsets.all(16),                  // Margem externa
          padding: const EdgeInsets.all(16),                 // Espaçamento interno
          decoration: BoxDecoration(
            // Cor de fundo com transparência baseada na cor primária
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),         // Bordas arredondadas
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribui igualmente
            children: [
              // Item de resumo: Total de matérias
              _buildResumoItem(
                'Total',
                materias.length.toString(),                   // Converte número para string
                Icons.book,
              ),
              
              // Item de resumo: Matérias concluídas hoje
              _buildResumoItem(
                'Concluídas',
                materias.where((m) => m.concluidoHoje).length.toString(),
                Icons.check_circle,
              ),
              
              // Item de resumo: Total de horas estudadas hoje
              _buildResumoItem(
                'Horas',
                materias
                    .where((m) => m.concluidoHoje)            // Filtra concluídas
                    .fold(0.0, (sum, m) => sum + m.tempoEstudo) // Soma os tempos
                    .toStringAsFixed(1),                      // Formata com 1 casa decimal
                Icons.timer,
              ),
            ],
          ),
        ),
        
        // Lista scrollável de matérias que ocupa o espaço restante
        Expanded(
          child: ListView.builder(
            itemCount: materias.length,                      // Número de itens na lista
            itemBuilder: (context, index) {                 // Função que constrói cada item
              return MateriaCard(
                materia: materias[index],                     // Passa a matéria atual
                
                // Callback para quando o card é tocado (navegar para resumo)
                onTap: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResumoScreen(),
                      settings: RouteSettings(arguments: materias[index]), // Passa a matéria como argumento
                    ),
                  );
                  
                  // Se houve alteração na tela de resumo, recarrega os dados
                  if (resultado == true) {
                    _carregarMaterias();
                  }
                },
                
                // Callback para marcar/desmarcar como concluído
                onToggleConcluido: () => _toggleConcluido(index),
                
                // Callback para excluir a matéria
                onDelete: () => _deletarMateria(index),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget que constrói cada item individual do card de resumo
  Widget _buildResumoItem(String label, String valor, IconData icon) {
    return Column(
      children: [
        // Ícone representativo do item
        Icon(icon, color: Theme.of(context).primaryColor),
        
        const SizedBox(height: 4),                          // Pequeno espaçamento
        
        // Valor numérico em destaque
        Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,                     // Texto em negrito
          ),
        ),
        
        // Label descritivo menor
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],                         // Cor mais suave
          ),
        ),
      ],
    );
  }
}

