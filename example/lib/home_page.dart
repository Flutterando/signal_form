import 'package:flutter/material.dart';
import 'wizard_form/pages/wizard_page.dart';
import 'simple_form/simple_form_page.dart';
import 'bloc_form/pages/bloc_form_page.dart';
import 'riverpod_form/pages/riverpod_form_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplos do Signal Form'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Explorar Signal Form',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha um exemplo abaixo para ver a biblioteca de formulários reativa, fluente e fortemente tipada em ação.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _ExampleCard(
                title: 'Login Simples & Cadastro',
                description:
                    'Um fluxo clássico de autenticação com validação de senha, confirmação de campos e lógica condicional.',
                icon: Icons.lock_open,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SimpleFormPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _ExampleCard(
                title: 'Wizard Multi-Etapas',
                description:
                    'Um fluxo de registro passo-a-passo com validação de subformulários, indicadores de progresso e serialização JSON estruturada.',
                icon: Icons.assistant_navigation,
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WizardPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _ExampleCard(
                title: 'Integração BLoC',
                description:
                    'Um formulário de feedback mostrando como o Signal Form se integra perfeitamente ao flutter_bloc para gerenciamento de estado assíncrono e tratamento de erros.',
                icon: Icons.swap_horiz_rounded,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlocFormPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _ExampleCard(
                title: 'Integração Riverpod',
                description:
                    'O mesmo form de feedback usando AsyncNotifier do Riverpod — ref.watch, ref.listen e ref.read em ação com Signal Form.',
                icon: Icons.bolt_rounded,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RiverpodFormPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
