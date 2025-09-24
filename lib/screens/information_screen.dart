import 'package:flutter/material.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key});

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  final List<Map<String, dynamic>> _infoCategories = [
    {
      'title': 'Rules & Regulations',
      'emoji': '📋',
      'description': 'Important rules and regulations to follow',
      'color': Colors.blue,
    },
    {
      'title': 'Safety Information',
      'emoji': '🛡️',
      'description': 'Safety tips and emergency contacts',
      'color': Colors.red,
    },
    {
      'title': 'Visa & Documents',
      'emoji': '📄',
      'description': 'Visa requirements and documentation',
      'color': Colors.green,
    },
    {
      'title': 'Accommodation',
      'emoji': '🏠',
      'description': 'Accommodation options and booking tips',
      'color': Colors.orange,
    },
    {
      'title': 'Transportation',
      'emoji': '🚗',
      'description': 'Transportation options and tips',
      'color': Colors.purple,
    },
    {
      'title': 'Culture & Customs',
      'emoji': '🎭',
      'description': 'Cultural information and customs',
      'color': Colors.teal,
    },
    {
      'title': 'Language Support',
      'emoji': '🗣️',
      'description': 'Language learning resources',
      'color': Colors.indigo,
    },
    {
      'title': 'Emergency Contacts',
      'emoji': '🚨',
      'description': 'Emergency contacts and procedures',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Information'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement search functionality
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search information',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _infoCategories.length,
        itemBuilder: (context, index) {
          final category = _infoCategories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: category['color'].withOpacity(0.1),
                child: Text(
                  category['emoji'],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              title: Text(
                category['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(category['description']),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Navigate to category details
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening ${category['title']}...'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
