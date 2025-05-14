import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mads_safebox/riverpod/loggeduserprovider.dart';
import 'package:mads_safebox/widgets/logoutbutton.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page${user!.nome}', maxLines: 2),
        actions: const [
          LogoutButton(),
        ],
      ),
    );
  }
}

