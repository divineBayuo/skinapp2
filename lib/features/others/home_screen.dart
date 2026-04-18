import 'package:flutter/material.dart';
import 'package:skinapp2/models/user.dart';

class HomeScreen extends StatefulWidget {
  final AccessRole role;
  const HomeScreen({super.key, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
