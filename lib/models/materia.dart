// Classe que representa uma matéria de estudo no aplicativo
class Materia {
  // Identificador único da matéria (usado para diferenciar cada matéria)
  final String id;

  // Nome da matéria (ex: "Matemática", "Física", etc.)
  final String nome;

  // Tempo de estudo diário definido para esta matéria (em horas)
  final double tempoEstudo;

  // Indica se o usuário já estudou esta matéria hoje
  final bool concluidoHoje;

  // Data e hora em que a matéria foi criada/adicionada ao app
  final DateTime dataCriacao;

  // Lista de temas relacionados obtidos da Wikipedia API
  final List<String> temasRelacionados;

  // Construtor da classe Materia
  Materia({
    // Parâmetro obrigatório: toda matéria precisa de um ID único
    required this.id,
    required this.nome,
    required this.tempoEstudo,
    this.concluidoHoje = false,
    required this.dataCriacao,
    this.temasRelacionados = const [],
  });

  // Método que converte o objeto Materia para Map (usado para salvar no SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      // Converte todos os dados para JSON
      'id': id,
      'nome': nome,
      'tempoEstudo': tempoEstudo,
      'concluidoHoje': concluidoHoje,
      // Converte DateTime para String no formato ISO8601 (ex: "2024-01-15T10:30:00")
      'dataCriacao': dataCriacao.toIso8601String(),
      'temasRelacionados': temasRelacionados,
    };
  }

  // Factory constructor: cria uma instância de Materia a partir de um Map JSON
  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'],
      nome: json['nome'],
      tempoEstudo: json['tempoEstudo'].toDouble(),

      // Extrai o status de conclusão ou usa false se não existir
      concluidoHoje: json['concluidoHoje'] ?? false,

      // Converte a String ISO8601 de volta para DateTime
      dataCriacao: DateTime.parse(json['dataCriacao']),

      // Converte a lista dinâmica para List<String> ou cria lista vazia
      temasRelacionados: List<String>.from(json['temasRelacionados'] ?? []),
    );
  }

  // Método para criar uma cópia da matéria com algumas propriedades alteradas
  Materia copyWith({
    // Parâmetros opcionais - só muda o que for passado
    String? nome,
    double? tempoEstudo,
    bool? concluidoHoje,
    List<String>? temasRelacionados,
  }) {
    // Retorna uma nova instância de Materia
    return Materia(
      // ID permanece o mesmo (não pode ser alterado)
      id: id,

      // Se novo nome foi passado, usa ele; senão mantém o atual
      nome: nome ?? this.nome,

      // Se novo tempo foi passado, usa ele; senão mantém o atual
      tempoEstudo: tempoEstudo ?? this.tempoEstudo,

      // Se novo status foi passado, usa ele; senão mantém o atual
      concluidoHoje: concluidoHoje ?? this.concluidoHoje,

      // Data de criação permanece a mesma (não pode ser alterada)
      dataCriacao: dataCriacao,

      // Se novos temas foram passados, usa eles; senão mantém os atuais
      temasRelacionados: temasRelacionados ?? this.temasRelacionados,
    );
  }
}