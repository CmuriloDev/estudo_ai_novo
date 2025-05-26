// Importações necessárias para o funcionamento da tela
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/materia.dart';
import '../widgets/custom_app_bar.dart';

// Widget Stateful que representa a tela de adicionar nova matéria
class AdicionarMateriaScreen extends StatefulWidget {
  const AdicionarMateriaScreen({super.key});

  @override
  State<AdicionarMateriaScreen> createState() => _AdicionarMateriaScreenState();
}

// Estado da tela de adicionar matéria, contém toda a lógica e interface
class _AdicionarMateriaScreenState extends State<AdicionarMateriaScreen> {
  // Chave global para validar o formulário antes de salvar
  final _formKey = GlobalKey<FormState>();
  
  // Controlador para capturar o texto digitado no campo nome
  final _nomeController = TextEditingController();
  
  // Variável que armazena o tempo de estudo selecionado (padrão: 1 hora)
  double _tempoEstudo = 1.0;
  
  // Variável que indica se a matéria já foi estudada hoje (padrão: false)
  bool _concluidoHoje = false;

  @override
  void dispose() {
    // Libera a memória do controlador quando a tela é destruída
    // Importante para evitar vazamento de memória
    _nomeController.dispose();
    super.dispose();
  }

  // Método principal que valida e salva a nova matéria
  void _salvarMateria() {
    // Verifica se todos os campos do formulário são válidos
    if (_formKey.currentState!.validate()) {
      // Cria um novo objeto Materia com os dados inseridos
      final novaMateria = Materia(
        // Gera um ID único baseado no timestamp atual
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        // Remove espaços extras do nome
        nome: _nomeController.text.trim(),
        // Tempo selecionado no slider
        tempoEstudo: _tempoEstudo,
        // Status de conclusão do checkbox
        concluidoHoje: _concluidoHoje,
        // Registra o momento da criação
        dataCriacao: DateTime.now(),
      );

      // Fecha a tela e retorna a nova matéria para a tela anterior
      Navigator.pop(context, novaMateria);
    }
  }

  // Método que exibe um diálogo com caracteres especiais para facilitar digitação
  void _mostrarCaracteresEspeciais() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Caracteres Especiais'),
        content: Wrap(
          // Espaçamento horizontal entre caracteres
          spacing: 8,
          // Espaçamento vertical entre linhas
          runSpacing: 8,
          children: [
            // Lista de caracteres acentuados comuns em português
            'á', 'à', 'ã', 'â', 'é', 'ê', 'í', 'ó', 'ô', 'õ', 'ú', 'ç',
            'Á', 'À', 'Ã', 'Â', 'É', 'Ê', 'Í', 'Ó', 'Ô', 'Õ', 'Ú', 'Ç'
          ].map((char) => InkWell(
            // Ao tocar em um caractere
            onTap: () {
              // Obtém a posição atual do cursor no campo de texto
              final cursorPos = _nomeController.selection.baseOffset;
              // Obtém o texto atual
              final text = _nomeController.text;
              // Insere o caractere na posição do cursor
              final newText = text.substring(0, cursorPos) + char + text.substring(cursorPos);
              // Atualiza o campo de texto com o novo valor
              _nomeController.value = TextEditingValue(
                text: newText,
                // Move o cursor para depois do caractere inserido
                selection: TextSelection.collapsed(offset: cursorPos + 1),
              );
              // Fecha o diálogo
              Navigator.pop(context);
            },
            // Visual de cada caractere no diálogo
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                char,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar customizada com título da tela
      appBar: const CustomAppBar(title: 'Adicionar Matéria'),
      // Permite rolagem quando o teclado aparece
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            // Associa a chave do formulário para validação
            key: _formKey,
            child: Column(
              // Estica os widgets filhos para ocupar toda largura
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card para o campo de nome da matéria
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
                        // Label do campo
                        const Text(
                          'Nome da Matéria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Campo de texto para inserir o nome
                        TextFormField(
                          // Conecta o controlador ao campo
                          controller: _nomeController,
                          // Define teclado de texto normal
                          keyboardType: TextInputType.text,
                          // Capitaliza primeira letra de cada palavra
                          textCapitalization: TextCapitalization.words,
                          // Habilita sugestões do teclado
                          enableSuggestions: true,
                          // Habilita autocorreção
                          autocorrect: true,
                          // Limite máximo de caracteres
                          maxLength: 50,
                          decoration: InputDecoration(
                            // Texto de dica quando campo está vazio
                            hintText: 'Ex: Matemática, Física, História...',
                            // Ícone à esquerda do campo
                            prefixIcon: const Icon(Icons.book),
                            // Botão de caracteres especiais à direita
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.text_fields),
                              onPressed: _mostrarCaracteresEspeciais,
                              tooltip: 'Caracteres especiais',
                            ),
                            // Estilo da borda do campo
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // Remove contador de caracteres visual
                            counterText: '',
                          ),
                          // Validação do campo
                          validator: (value) {
                            // Verifica se está vazio
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, insira o nome da matéria';
                            }
                            // Verifica tamanho mínimo
                            if (value.trim().length < 3) {
                              return 'O nome deve ter pelo menos 3 caracteres';
                            }
                            // Campo válido
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card para o slider de tempo de estudo
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Label do slider
                            const Text(
                              'Tempo de Estudo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Valor atual selecionado
                            Text(
                              '${_tempoEstudo.toStringAsFixed(1)} horas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Slider para selecionar tempo
                        Slider(
                          // Valor atual do slider
                          value: _tempoEstudo,
                          // Valor mínimo (30 minutos)
                          min: 0.5,
                          // Valor máximo (8 horas)
                          max: 8.0,
                          // Número de divisões (incrementos de 0.5)
                          divisions: 15,
                          // Label que aparece ao arrastar
                          label: '${_tempoEstudo.toStringAsFixed(1)}h',
                          // Callback quando o valor muda
                          onChanged: (value) {
                            // Atualiza o estado com novo valor
                            setState(() => _tempoEstudo = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        // Labels dos extremos do slider
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

                // Card para o checkbox de conclusão
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    // Título do checkbox
                    title: const Text(
                      'Concluído hoje?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Descrição adicional
                    subtitle: const Text(
                      'Marque se você já estudou esta matéria hoje',
                    ),
                    // Valor atual do checkbox
                    value: _concluidoHoje,
                    // Callback quando o valor muda
                    onChanged: (value) {
                      // Atualiza o estado (usa ?? para evitar null)
                      setState(() => _concluidoHoje = value ?? false);
                    },
                    // Ícone à esquerda que muda conforme o estado
                    secondary: Icon(
                      _concluidoHoje
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _concluidoHoje ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Linha com botões de ação
                Row(
                  children: [
                    // Botão Cancelar (50% da largura)
                    Expanded(
                      child: OutlinedButton(
                        // Fecha a tela sem salvar
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Botão Salvar (50% da largura)
                    Expanded(
                      child: ElevatedButton(
                        // Chama método para validar e salvar
                        onPressed: _salvarMateria,
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