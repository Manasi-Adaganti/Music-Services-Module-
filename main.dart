// pubspec.yaml

name: music_services_app
description: A Flutter project to display music services from Firestore.

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/icons/


// main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel(ServiceRepository())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Services Module',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

// ------------------- Model -------------------
class ServiceModel {
  final String title;
  final String description;
  final String icon;

  ServiceModel({required this.title, required this.description, required this.icon});

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
    );
  }
}

// ------------------- Repository -------------------
class ServiceRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<List<ServiceModel>> fetchServices() async {
    final snapshot = await _firestore.collection('services').get();
    return snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
  }
}

// ------------------- ViewModel -------------------
class HomeViewModel extends ChangeNotifier {
  final ServiceRepository repository;
  HomeViewModel(this.repository);

  List<ServiceModel> _services = [];
  List<ServiceModel> get services => _services;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();
    _services = await repository.fetchServices();
    _isLoading = false;
    notifyListeners();
  }
}

// ------------------- View -------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<HomeViewModel>().loadServices());
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Music Services")),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3 / 2,
              ),
              itemBuilder: (context, index) {
                final service = viewModel.services[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailScreen(serviceTitle: service.title),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(service.icon, height: 40),
                          const SizedBox(height: 8),
                          Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(service.description, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ServiceDetailScreen extends StatelessWidget {
  final String serviceTitle;
  const ServiceDetailScreen({super.key, required this.serviceTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Service Detail")),
      body: Center(
        child: Text("You tapped on: $serviceTitle", style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
