import 'package:flutter/material.dart';        
import '../models/materia.dart';               
import '../widgets/custom_app_bar.dart';       

// Classe principal da tela - StatefulWidget permite mudanças de estado
class AdicionarMateriaScreen extends StatefulWidget {
  const AdicionarMateriaScreen({super.key});

  @override
  State<AdicionarMateriaScreen> createState() => _AdicionarMateriaScreenState();
}

// Classe de estado que gerencia os dados da tela
class _AdicionarMateriaScreenState extends State<AdicionarMateriaScreen> {
  // Chave global para validação do formulário
  final _formKey = GlobalKey<FormState>();
  
  // Controlador para o campo de texto do nome da matéria
  final _nomeController = TextEditingController();

  // Variáveis de estado para armazenar os valores selecionados
  double _tempoEstudo = 1.0;        // Tempo padrão de estudo (1 hora)
  bool _concluidoHoje = false;      // Status se foi concluído hoje (padrão: não)

  // Método chamado quando o widget é destruído - limpa recursos
  @override
  void dispose() {
    _nomeController.dispose();  // Libera a memória do controlador
    super.dispose();
  }

  // Método para salvar uma nova matéria
  void _salvarMateria() {
    // Verifica se o formulário é válido (passou em todas as validações)
    if (_formKey.currentState!.validate()) {
      // Cria uma nova instância de Matéria com os dados preenchidos
      final novaMateria = Materia(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ID único baseado no timestamp
        nome: _nomeController.text.trim(),                    // Nome da matéria (remove espaços extras)
        tempoEstudo: _tempoEstudo,                           // Tempo de estudo selecionado
        concluidoHoje: _concluidoHoje,                       // Status de conclusão
        dataCriacao: DateTime.now(),                         // Data e hora atual
      );

      // Retorna para a tela anterior enviando a nova matéria como resultado
      Navigator.pop(context, novaMateria);
    }
  }

  // Método que constrói a interface da tela
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior personalizada com título
      appBar: const CustomAppBar(title: 'Adicionar Matéria'),
      
      // Corpo da tela com scroll para telas menores
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Espaçamento interno de 16px
          child: Form(
            key: _formKey, // Conecta o formulário com a chave de validação
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Elementos ocupam toda largura
              children: [
                
                // === SEÇÃO 1: CAMPO NOME DA MATÉRIA ===
                Card(
                  elevation: 2, // Sombra do cartão
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Bordas arredondadas
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título da seção
                        const Text(
                          'Nome da Matéria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8), // Espaçamento vertical
                        
                        // Campo de texto para o nome da matéria
                        TextFormField(
                          controller: _nomeController,                    // Conecta com o controlador
                          keyboardType: TextInputType.text,              // Tipo de teclado
                          textCapitalization: TextCapitalization.words,  // Primeira letra maiúscula
                          enableSuggestions: true,                       // Habilita sugestões
                          autocorrect: true,                             // Correção automática
                          maxLength: 50,                                 // Máximo 50 caracteres
                          decoration: InputDecoration(
                            hintText: 'Ex: Matemática, Física, História...', // Texto de exemplo
                            prefixIcon: const Icon(Icons.book),             // Ícone de livro
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            counterText: '', // Remove contador de caracteres
                          ),
                          // Função de validação do campo
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, insira o nome da matéria';
                            }
                            if (value.trim().length < 3) {
                              return 'O nome deve ter pelo menos 3 caracteres';
                            }
                            return null; // Validação passou
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Espaçamento entre seções

                // === SEÇÃO 2: SELETOR DE TEMPO DE ESTUDO ===
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho com título e valor atual
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tempo de Estudo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Mostra o valor atual selecionado
                            Text(
                              '${_tempoEstudo.toStringAsFixed(1)} horas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).primaryColor, // Cor do tema
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Slider para selecionar tempo
                        Slider(
                          value: _tempoEstudo,           // Valor atual
                          min: 0.5,                     // Mínimo: 30 minutos
                          max: 8.0,                     // Máximo: 8 horas
                          divisions: 15,                // 15 divisões no slider
                          label: '${_tempoEstudo.toStringAsFixed(1)}h', // Label que aparece ao arrastar
                          onChanged: (value) {
                            setState(() => _tempoEstudo = value); // Atualiza o estado
                          },
                        ),
                        const SizedBox(height: 8),
                        
                        // Labels mostrando valores mínimo e máximo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '30 min',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '8 horas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // === SEÇÃO 3: CHECKBOX "CONCLUÍDO HOJE" ===
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'Concluído hoje?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Marque se você já estudou esta matéria hoje',
                    ),
                    value: _concluidoHoje,              // Valor atual do checkbox
                    onChanged: (value) {
                      setState(() => _concluidoHoje = value ?? false); // Atualiza estado
                    },
                    // Ícone que muda baseado no estado
                    secondary: Icon(
                      _concluidoHoje
                          ? Icons.check_circle           // Ícone quando marcado
                          : Icons.radio_button_unchecked, // Ícone quando desmarcado
                      color: _concluidoHoje ? Colors.green : Colors.grey, // Cor dinâmica
                    ),
                  ),
                ),
                const SizedBox(height: 32), // Espaçamento maior antes dos botões

                // === SEÇÃO 4: BOTÕES DE AÇÃO ===
                Row(
                  children: [
                    // Botão Cancelar (ocupa metade da largura)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context), // Volta sem salvar
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16), // Espaçamento entre botões
                    
                    // Botão Salvar (ocupa metade da largura)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _salvarMateria, // Chama função de salvar
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}