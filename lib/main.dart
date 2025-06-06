import 'package:flutter/material.dart';                   
import 'package:estuda_ai_novo/screens/home_screen.dart';  
import 'screens/home_screen.dart';                         
import 'screens/adicionar_materia_screen.dart';            
import 'screens/resumo_screen.dart';                      
import 'screens/desempenho_screen.dart';                   


// Esta é a primeira função executada quando o app é iniciado
void main() {
  // runApp() inicializa o Flutter e define o widget raiz da aplicação
  // Recebe um widget que será a base de toda a árvore de widgets
  runApp(const EstudaAiApp());
}

// Classe principal da aplicação - herda de StatelessWidget
// StatelessWidget é usado quando o widget não muda de estado
// Esta classe configura as propriedades globais da aplicação
class EstudaAiApp extends StatelessWidget {
  // Construtor da classe com super.key para otimização do Flutter
  const EstudaAiApp({super.key});

  // Método obrigatório que constrói a interface do widget
  // Define toda a configuração global da aplicação
  @override
  Widget build(BuildContext context) {
    // MaterialApp é o widget raiz para aplicações Material Design
    // Fornece funcionalidades básicas como navegação, tema, localização
    return MaterialApp(
      // Título da aplicação (aparece no gerenciador de tarefas do sistema)
      title: 'Estuda Aí',
      
      // Remove a banner "DEBUG" que aparece no canto superior direito durante desenvolvimento
      // Em produção, esta banner não aparece automaticamente
      debugShowCheckedModeBanner: false,
      
      // Configuração do tema visual da aplicação
      theme: ThemeData(
        // Define a paleta de cores primária usando Material Design
        // Colors.blue gera automaticamente tons claros e escuros
        primarySwatch: Colors.blue,
        
        // Cor primária específica (azul Material Design)
        // 0xFF indica cor opaca, 2196F3 é o código hexadecimal da cor
        primaryColor: const Color(0xFF2196F3),
        
        // Cor de fundo padrão para todas as telas da aplicação
        // F5F5F5 é um cinza muito claro, quase branco
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        
        // Configurações específicas para barras de aplicação (AppBar)
        appBarTheme: const AppBarTheme(
          elevation: 0,           // Remove sombra da AppBar (visual mais limpo)
          centerTitle: true,      // Centraliza o título na AppBar
        ),
      ),
      
      // Define qual tela será exibida primeiro quando o app for aberto
      // HomeScreen é a tela principal com a lista de matérias
      home: const HomeScreen(),
    );
  }
}
