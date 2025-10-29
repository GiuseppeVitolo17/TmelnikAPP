import 'package:flutter/material.dart';
import '../widgets/project_card.dart';
import '../services/pexels_service.dart';

class ProjectOffersScreen extends StatefulWidget {
  const ProjectOffersScreen({super.key});

  @override
  State<ProjectOffersScreen> createState() => _ProjectOffersScreenState();
}

class _ProjectOffersScreenState extends State<ProjectOffersScreen> {
  // Example projects data
  final List<Map<String, String>> projects = [
    {
      'title': 'Project Berlin',
      'dates': '14 July / 19 July',
      'city': 'Berlin',
    },
    {
      'title': 'Project Brno',
      'dates': '17 July / 25 July',
      'city': 'Brno',
    },
    {
      'title': 'Project Krakow',
      'dates': '27 July / 3 August',
      'city': 'Krakow',
    },
  ];

  void _handleApply(String projectTitle) {
    // TODO: Implement apply functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Apply button tapped for $projectTitle'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleInfo(String projectTitle) {
    // TODO: Implement infopack functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Infopack button tapped for $projectTitle'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: projects.map((project) {
          final city = project['city']!;
          final title = project['title']!;
          final dates = project['dates']!;

          return FutureBuilder<String>(
            future: PexelsService.fetchCityImageUrl(city),
            builder: (context, snapshot) {
              String imagePath;
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show empty string while loading - ProjectCard will show placeholder
                imagePath = '';
              } else if (snapshot.hasData) {
                imagePath = snapshot.data!;
              } else {
                // Fallback to empty string on error - ProjectCard will show placeholder
                imagePath = '';
              }

              return ProjectCard(
                imagePathOrUrl: imagePath,
                title: title,
                dates: dates,
                onApply: () => _handleApply(title),
                onInfo: () => _handleInfo(title),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}