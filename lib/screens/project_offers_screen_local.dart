import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectOffersScreenLocal extends StatefulWidget {
  const ProjectOffersScreenLocal({super.key});

  @override
  State<ProjectOffersScreenLocal> createState() => _ProjectOffersScreenLocalState();
}

class _ProjectOffersScreenLocalState extends State<ProjectOffersScreenLocal> {
  final List<Map<String, dynamic>> _offers = [
    {
      'id': '1',
      'title': 'Summer Project in Croatia',
      'description': 'Join our team for an exciting summer project in the beautiful coastal city of Split, Croatia. Work on environmental conservation and community development initiatives.',
      'targeting': 'Students, Volunteers',
      'location': 'Split, Croatia',
      'duration': '2 months (July-August)',
      'requirements': 'Fluent English, teamwork skills, passion for environment',
      'benefits': ['Free accommodation', 'Food allowance', 'Travel insurance', 'Cultural excursions'],
      'contact': '@tmelnik_croatia',
      'expires': '2024-06-15',
    },
    {
      'id': '2',
      'title': 'Tech Internship in Germany',
      'description': 'An opportunity for aspiring software developers to intern at a leading tech company in Berlin. Gain hands-on experience with cutting-edge technologies and work on real-world projects.',
      'targeting': 'Computer Science Students, Recent Graduates',
      'location': 'Berlin, Germany',
      'duration': '3 months (September-November)',
      'requirements': 'Proficiency in Python/Java, basic German, problem-solving skills',
      'benefits': ['Monthly stipend', 'Mentorship program', 'Networking events', 'Potential full-time offer'],
      'contact': '@tmelnik_germany',
      'expires': '2024-07-01',
    },
    {
      'id': '3',
      'title': 'Cultural Exchange in Spain',
      'description': 'Experience the vibrant culture of Spain while teaching English to local students. Immerse yourself in Spanish traditions and improve your language skills.',
      'targeting': 'Language Enthusiasts, Gap Year Students',
      'location': 'Seville, Spain',
      'duration': '6 months (October-March)',
      'requirements': 'Native English speaker, basic Spanish, teaching experience preferred',
      'benefits': ['Homestay accommodation', 'Weekly Spanish classes', 'Cultural activities', 'Travel opportunities'],
      'contact': '@tmelnik_spain',
      'expires': '2024-07-01',
    },
  ];

  Future<void> _shareToInstagram(Map<String, dynamic> offer) async {
    final text = '''🚀 ${offer['title']}

📍 ${offer['location']}
⏰ ${offer['duration']}
🎯 ${offer['targeting']}

${offer['description']}

✅ Benefits:
${offer['benefits'].map((b) => '• $b').join('\n')}

📱 Contact: ${offer['contact']}

#TmelnikProject #TravelOpportunity #WorkAbroad''';

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: text));

    // Open Instagram in default browser
    final instagramUrl = Uri.parse('https://www.instagram.com/');
    await launchUrl(instagramUrl);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer text copied to clipboard! Instagram opened in browser.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Offers'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer['title'],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    offer['description'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12.0),
                  _buildInfoRow(context, Icons.location_on, offer['location']),
                  _buildInfoRow(context, Icons.access_time, offer['duration']),
                  _buildInfoRow(context, Icons.person, offer['targeting']),
                  const SizedBox(height: 12.0),
                  Text(
                    'Benefits:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ... (offer['benefits'] as List<String>).map((benefit) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Text('• $benefit', style: Theme.of(context).textTheme.bodyMedium),
                  )),
                  const SizedBox(height: 12.0),
                  Text(
                    'Contact: ${offer['contact']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareToInstagram(offer),
                      icon: const Icon(Icons.share),
                      label: const Text('Share on Instagram'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
