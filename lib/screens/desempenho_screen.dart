import 'package:flutter/material.dart';        
import 'package:fl_chart/fl_chart.dart';       
import 'package:intl/intl.dart';              
import 'package:shared_preferences/shared_preferences.dart';  
import 'dart:convert';                         
import '../services/storage_service.dart';     
import '../widgets/custom_app_bar.dart';       

// Classe principal da tela de desempenho - herda de StatefulWidget
// Esta tela exibe estatísticas e gráficos do progresso de estudos do usuário
class DesempenhoScreen extends StatefulWidget {
  const DesempenhoScreen({super.key});

  @override
  State<DesempenhoScreen> createState() => _DesempenhoScreenState();
}

// Classe que gerencia o estado da tela de desempenho
class _DesempenhoScreenState extends State<DesempenhoScreen> {
  // Flag que controla se os dados estão sendo carregados
  bool isLoading = true;

  // === VARIÁVEIS PARA ESTATÍSTICAS DO MÊS ===
  
  // Total de matérias que foram estudadas no mês
  int totalMateriasEstudadas = 0;
  
  // Total de horas estudadas no mês
  double totalHorasEstudadas = 0;
  
  // Array com horas estudadas por dia da semana
  // Índices: 0=Domingo, 1=Segunda, 2=Terça, 3=Quarta, 4=Quinta, 5=Sexta, 6=Sábado
  List<double> horasPorDiaSemana = [0, 0, 0, 0, 0, 0, 0];
  
  // Mapa que armazena horas estudadas por data específica (formato YYYY-MM-DD)
  Map<String, double> horasPorDia = {};

  // Controle de qual mês está sendo exibido (permite navegar entre meses)
  DateTime mesAtual = DateTime.now();

  // Método chamado quando a tela é criada
  @override
  void initState() {
    super.initState();
    _carregarDadosDoMes();  // Carrega os dados do mês atual
  }

  // Função principal que carrega todos os dados estatísticos do mês selecionado
  Future<void> _carregarDadosDoMes() async {
    // Verifica se o widget ainda está montado (previne erros se usuário sair da tela)
    if (!mounted) return;

    // Ativa o indicador de carregamento
    setState(() => isLoading = true);

    try {
      // === RESET DOS DADOS ANTES DE CARREGAR ===
      horasPorDiaSemana = [0, 0, 0, 0, 0, 0, 0];  // Zera array de dias da semana
      horasPorDia.clear();                          // Limpa mapa de dias específicos
      totalHorasEstudadas = 0;                      // Zera contador de horas
      totalMateriasEstudadas = 0;                   // Zera contador de matérias

      // === DEFINIÇÃO DO PERÍODO DO MÊS ===
      
      // Primeiro dia do mês (dia 1)
      final primeiroDia = DateTime(mesAtual.year, mesAtual.month, 1);
      
      // Último dia do mês (usando truque: primeiro dia do próximo mês menos 1 dia)
      final ultimoDia = DateTime(mesAtual.year, mesAtual.month + 1, 0);

      // Obtém acesso ao armazenamento local
      final prefs = await SharedPreferences.getInstance();

      // === LOOP ATRAVÉS DE TODOS OS DIAS DO MÊS ===
      
      // Itera desde o primeiro até o último dia do mês
      for (DateTime data = primeiroDia;
      data.isBefore(ultimoDia.add(const Duration(days: 1)));  // Inclui o último dia
      data = data.add(const Duration(days: 1))) {             // Avança um dia por iteração

        // Converte a data para string no formato ISO (YYYY-MM-DD)
        final dataString = data.toIso8601String().split('T')[0];
        
        // Tenta recuperar dados salvos para esta data específica
        // A chave segue o padrão: 'progresso_diario_YYYY-MM-DD'
        final progressoJson = prefs.getString('progresso_diario_$dataString');

        // Se existem dados salvos para este dia
        if (progressoJson != null) {
          try {
            // Converte JSON de volta para Map
            final progresso = jsonDecode(progressoJson);
            
            // Extrai horas estudadas (com fallback para 0 se não existir)
            final horas = (progresso['tempoTotal'] ?? 0).toDouble();
            
            // Extrai número de matérias completadas
            final materiasCompletas = progresso['materiasCompletas'] ?? 0;

            // === ACUMULA DADOS PARA ESTATÍSTICAS GERAIS ===
            totalHorasEstudadas += horas;
            // Garante que materiasCompletas é um inteiro antes de somar
            totalMateriasEstudadas += materiasCompletas is int ? materiasCompletas : 0;

            // === CALCULA DIA DA SEMANA E ACUMULA HORAS ===
            
            // DateTime.weekday retorna 1=Segunda até 7=Domingo
            // Precisamos converter para 0=Domingo até 6=Sábado
            final diaSemana = data.weekday == 7 ? 0 : data.weekday;
            horasPorDiaSemana[diaSemana] += horas;

            // Salva horas para esta data específica (usado no calendário visual)
            horasPorDia[dataString] = horas;
          } catch (e) {
            // Se houver erro ao processar dados de um dia específico, continua para o próximo
            print('Erro ao processar dados do dia $dataString: $e');
          }
        }
        // Se não há dados para este dia, simplesmente não adiciona nada (fica 0)
      }

      // Atualiza a interface após carregar todos os dados
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Captura erros gerais (problemas de rede, SharedPreferences, etc.)
      print('Erro geral ao carregar dados: $e');
      if (mounted) {
        setState(() => isLoading = false);
        // Exibe mensagem de erro ao usuário
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Função que permite navegar entre meses (anterior/próximo)
  void _mudarMes(int incremento) {
    setState(() {
      // Calcula novo mês somando/subtraindo o incremento
      // DateTime automaticamente ajusta ano se necessário
      mesAtual = DateTime(mesAtual.year, mesAtual.month + incremento);
    });
    // Recarrega dados do novo mês selecionado
    _carregarDadosDoMes();
  }

  // Método principal que constrói a interface da tela
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Desempenho Mensal'),
      
      // Exibe carregamento ou conteúdo principal
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(  // Permite scroll se conteúdo for maior que tela
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Controles para navegar entre meses
              _buildSeletorMes(),
              const SizedBox(height: 16),

              // Cards com resumo das estatísticas
              _buildCardsResumo(),
              const SizedBox(height: 24),

              // Gráfico de barras mostrando horas por dia da semana
              _buildGraficoSemanal(),
              const SizedBox(height: 24),

              // Calendário visual do mês (implementado na parte 2)
              _buildCalendarioMensal(),
              const SizedBox(height: 24),

              // Mensagem motivacional baseada no desempenho (implementado na parte 2)
              _buildMensagemMotivacional(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget que cria os controles de navegação entre meses
  Widget _buildSeletorMes() {
    return Card(
      elevation: 2,  // Sombra do card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botão para mês anterior
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _mudarMes(-1),  // Subtrai 1 mês
            ),
            
            // Exibe mês/ano atual
            Text(
              '${mesAtual.month}/${mesAtual.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Botão para próximo mês (desabilitado se já estiver no mês atual)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              // Só permite avançar se não estiver no mês atual
              onPressed: mesAtual.month == DateTime.now().month &&
                  mesAtual.year == DateTime.now().year
                  ? null  // null desabilita o botão
                  : () => _mudarMes(1),  // Soma 1 mês
            ),
          ],
        ),
      ),
    );
  }

  // Widget que cria os cards de resumo (Total de Horas e Matérias Estudadas)
  Widget _buildCardsResumo() {
    return Row(
      children: [
        // Card do total de horas
        Expanded(
          child: _buildResumoCard(
            'Total de Horas',
            totalHorasEstudadas.toStringAsFixed(1),  // 1 casa decimal
            Icons.timer,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),  // Espaçamento entre cards
        
        // Card do total de matérias
        Expanded(
          child: _buildResumoCard(
            'Matérias Estudadas',
            totalMateriasEstudadas.toString(),
            Icons.book,
            Colors.green,
          ),
        ),
      ],
    );
  }

  // Widget que cria o gráfico de barras das horas por dia da semana
  Widget _buildGraficoSemanal() {
    // Calcula valor máximo do eixo Y para melhor visualização
    final maxY = _calcularMaxY();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título do gráfico
        const Text(
          'Total de Horas por Dia da Semana',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Descrição explicativa
        Text(
          'Soma de todas as horas estudadas em cada dia da semana',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Container do gráfico com estilo
        Container(
          height: 300,  // Altura fixa do gráfico
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,  // Distribui barras igualmente
              maxY: maxY,  // Valor máximo do eixo Y
              
              // Configuração dos tooltips (informações ao tocar nas barras)
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dias = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
                    final quantidadeDias = _contarDiasNoMes(group.x);  // Função implementada na parte 2
                    return BarTooltipItem(
                      '${dias[group.x]}\n${rod.toY.toStringAsFixed(1)} horas\n($quantidadeDias ${quantidadeDias == 1 ? "vez" : "vezes"} no mês)',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              
              // Configuração dos títulos dos eixos
              titlesData: FlTitlesData(
                // Eixo Y (esquerda) - valores das horas
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY > 10 ? 5 : 2,  // Intervalo baseado no valor máximo
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}h',  // Formato: "5h", "10h", etc.
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                    reservedSize: 32,  // Espaço reservado para os títulos
                  ),
                ),
                // Eixo X (inferior) - dias da semana
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
                      if (value.toInt() >= 0 && value.toInt() < dias.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dias[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                // Oculta títulos dos eixos direito e superior
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              
              // Configuração da grade de fundo
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,  // Apenas linhas horizontais
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300]!,
                    strokeWidth: 1,
                  );
                },
              ),
              
              // Configuração das bordas do gráfico
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey[300]!),
              ),
              
              // Criação das barras para cada dia da semana
              barGroups: List.generate(7, (index) {
                return BarChartGroupData(
                  x: index,  // Posição no eixo X (0=Dom, 1=Seg, etc.)
                  barRods: [
                    BarChartRodData(
                      toY: horasPorDiaSemana[index],  // Altura da barra (horas estudadas)
                      color: _getCorDiaSemana(index), // Cor específica para cada dia (função na parte 2)
                      width: 30,  // Largura da barra
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),  // Bordas arredondadas no topo
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

// Widget que constrói um calendário visual do mês mostrando dias com estudo
  Widget _buildCalendarioMensal() {
    // === CÁLCULOS INICIAIS PARA O CALENDÁRIO ===
    
    // Primeiro dia do mês (sempre dia 1)
    final primeiroDia = DateTime(mesAtual.year, mesAtual.month, 1);
    
    // Último dia do mês (truque: primeiro dia do próximo mês - 1 dia)
    final ultimoDia = DateTime(mesAtual.year, mesAtual.month + 1, 0);
    
    // Quantos dias tem este mês (28, 29, 30 ou 31)
    final diasNoMes = ultimoDia.day;
    
    // Em que dia da semana começa o mês (0=Dom, 1=Seg, ..., 6=Sáb)
    // weekday retorna 1-7, então convertemos: 7 (domingo) vira 0
    final primeiroDiaSemana = primeiroDia.weekday == 7 ? 0 : primeiroDia.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        const Text(
          'Calendário de Estudos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Card container do calendário
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // === CABEÇALHO COM DIAS DA SEMANA ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']  // Dom, Seg, Ter, Qua, Qui, Sex, Sáb
                      .map((dia) => SizedBox(
                    width: 40,                    // Largura fixa para cada coluna
                    child: Center(
                      child: Text(
                        dia,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                
                // === GRADE DO CALENDÁRIO ===
                GridView.builder(
                  shrinkWrap: true,                           // Ajusta altura ao conteúdo
                  physics: const NeverScrollableScrollPhysics(), // Desabilita scroll (usa o scroll da tela)
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,                       // 7 colunas (dias da semana)
                    childAspectRatio: 1,                     // Células quadradas (1:1)
                    crossAxisSpacing: 4,                     // Espaçamento horizontal
                    mainAxisSpacing: 4,                      // Espaçamento vertical
                  ),
                  itemCount: 42,                             // 6 semanas × 7 dias = 42 células
                  itemBuilder: (context, index) {
                    // Calcula qual dia do mês esta célula representa
                    final dia = index - primeiroDiaSemana + 1;

                    // Se a célula não corresponde a um dia válido do mês, retorna espaço vazio
                    if (dia < 1 || dia > diasNoMes) {
                      return const SizedBox();
                    }

                    // Cria objeto DateTime para este dia específico
                    final data = DateTime(mesAtual.year, mesAtual.month, dia);
                    
                    // Converte para string no formato YYYY-MM-DD
                    final dataString = data.toIso8601String().split('T')[0];
                    
                    // Recupera quantas horas foram estudadas neste dia (0 se não estudou)
                    final horas = horasPorDia[dataString] ?? 0;

                    return Container(
                      decoration: BoxDecoration(
                        // === COR DE FUNDO BASEADA NAS HORAS ESTUDADAS ===
                        color: horas > 0
                            // Se estudou: azul com opacidade proporcional às horas (máximo 8h)
                            ? Colors.blue.withOpacity(horas.clamp(0, 8) / 8)
                            // Se não estudou: cinza claro
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        
                        // === BORDA ESPECIAL PARA O DIA ATUAL ===
                        border: Border.all(
                          // Se é hoje: borda azul, senão: transparente
                          color: data.day == DateTime.now().day &&
                              data.month == DateTime.now().month &&
                              data.year == DateTime.now().year
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Número do dia
                          Text(
                            dia.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              // Texto branco se estudou, preto se não estudou
                              color: horas > 0 ? Colors.white : Colors.black,
                            ),
                          ),
                          
                          // Se estudou, mostra quantas horas
                          if (horas > 0)
                            Text(
                              '${horas.toStringAsFixed(1)}h',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget que exibe uma mensagem motivacional baseada no desempenho
  Widget _buildMensagemMotivacional() {
    return Card(
      elevation: 4,           // Sombra mais pronunciada para destaque
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ícone de troféu em dourado
            Icon(
              Icons.emoji_events,
              size: 48,
              color: Colors.amber[600],
            ),
            const SizedBox(height: 8),
            
            // Mensagem personalizada baseada no total de horas
            Text(
              _getMensagemMotivacional(),    // Função que escolhe a mensagem
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,  // Texto em itálico para dar elegância
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper que cria um card de resumo padronizado
  // Usado para "Total de Horas" e "Matérias Estudadas"
  Widget _buildResumoCard(String titulo, String valor, IconData icon, Color cor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ícone representativo (timer, book, etc.)
            Icon(icon, size: 32, color: cor),
            const SizedBox(height: 8),
            
            // Valor principal (número grande e destacado)
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cor,                  // Mesma cor do ícone
              ),
            ),
            
            // Título explicativo (menor e discreto)
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função que retorna cores específicas para cada dia da semana
  // Torna o gráfico mais visual e fácil de distinguir
  Color _getCorDiaSemana(int index) {
    final cores = [
      Colors.red[400]!,      // Domingo - vermelho 
      Colors.blue[600]!,     // Segunda - azul 
      Colors.green[600]!,    // Terça - verde 
      Colors.orange[600]!,   // Quarta - laranja 
      Colors.purple[600]!,   // Quinta - roxo 
      Colors.teal[600]!,     // Sexta - azul-verde 
      Colors.indigo[600]!,   // Sábado - índigo 
    ];
    
    // Validação: retorna cinza se índice inválido
    return index >= 0 && index < cores.length ? cores[index] : Colors.grey;
  }

  // Função que conta quantas vezes um dia da semana específico aparece no mês
  // Usado nos tooltips para mostrar "4 vezes no mês", "5 vezes no mês", etc.
  int _contarDiasNoMes(int diaSemana) {
    // Mesmo cálculo de período usado em outras funções
    final primeiroDia = DateTime(mesAtual.year, mesAtual.month, 1);
    final ultimoDia = DateTime(mesAtual.year, mesAtual.month + 1, 0);
    
    int contador = 0;

    // Itera por todos os dias do mês
    for (DateTime data = primeiroDia;
    data.isBefore(ultimoDia.add(const Duration(days: 1)));
    data = data.add(const Duration(days: 1))) {
      
      // Converte weekday (1-7) para nosso formato (0-6)
      final diaSemanaData = data.weekday == 7 ? 0 : data.weekday;
      
      // Se este dia corresponde ao dia da semana procurado, conta
      if (diaSemanaData == diaSemana) {
        contador++;
      }
    }

    return contador;
  }

  // Função que calcula o valor máximo do eixo Y do gráfico
  // Garante que o gráfico sempre tenha uma escala adequada
  double _calcularMaxY() {
    double maxHoras = 0;
    
    // Encontra o maior valor entre todos os dias da semana
    for (var horas in horasPorDiaSemana) {
      if (horas > maxHoras) maxHoras = horas;
    }
    
    // Se não há dados, usa 10 como padrão
    // Se há dados, adiciona 5 ao máximo e arredonda para cima
    return maxHoras == 0 ? 10 : (maxHoras + 5).ceilToDouble();
  }

  // Função que escolhe mensagem motivacional baseada no total de horas estudadas
  // Gamificação simples para incentivar o usuário
  String _getMensagemMotivacional() {
    if (totalHorasEstudadas == 0) {
      // Nenhum estudo ainda - incentivo inicial
      return 'Comece sua jornada de estudos este mês! 🚀';
    } else if (totalHorasEstudadas < 20) {
      // Pouco estudo - encorajamento
      return 'Bom começo! Continue assim e alcance seus objetivos! 💪';
    } else if (totalHorasEstudadas < 50) {
      // Bom progresso - reconhecimento
      return 'Excelente dedicação! Você está no caminho certo! 🌟';
    } else {
      // Muito estudo - celebração
      return 'Parabéns pela incrível dedicação! Você é inspirador! 🏆';
    }
  }

}