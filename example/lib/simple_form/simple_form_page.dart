import 'package:flutter/material.dart';
import 'login_form.dart';
import 'register_form.dart';

class SimpleFormPage extends StatefulWidget {
  const SimpleFormPage({super.key});

  @override
  State<SimpleFormPage> createState() => _SimpleFormPageState();
}

class _SimpleFormPageState extends State<SimpleFormPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticação'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Entrar', icon: Icon(Icons.login)),
            Tab(text: 'Cadastrar', icon: Icon(Icons.person_add)),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: const [LoginForm(), RegisterForm()],
        ),
      ),
    );
  }
}
