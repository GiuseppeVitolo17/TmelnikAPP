import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectOffersScreen extends StatefulWidget {
  const ProjectOffersScreen({super.key});

  @override
  State<ProjectOffersScreen> createState() => _ProjectOffersScreenState();
}

class _ProjectOffersScreenState extends State<ProjectOffersScreen> {
  final List<Map<String, dynamic>> _sampleOffers = [
    {
      'title': 'Summer Work in Croatia',
      'location': 'Dubrovnik, Croatia',
      'duration': '3 months',
      'targeting': 'Students & Young Adults',
      'description': 'Work in hospitality and tourism during the summer season. Great opportunity to experience Croatian culture while earning money.',
      'benefits': ['Accommodation provided', 'Meals included', 'Cultural activities', 'Language lessons'],
      'contact': '@tmelnik_croatia',
      'expires': '2024-06-15',
    },
    {
      'title': 'Agricultural Work in Germany',
      'location': 'Bavaria, Germany',
      'duration': '6 months',
      'targeting': 'Physical workers',
      'description': 'Seasonal agricultural work with competitive pay and accommodation. Perfect for those who enjoy outdoor work.',
      'benefits': ['Competitive salary', 'Housing provided', 'Health insurance', 'Weekend activities'],
      'contact': '@tmelnik_germany',
      'expires': '2024-05-30',
    },
    {
      'title': 'Teaching English in Spain',
      'location': 'Barcelona, Spain',
      'duration': '1 year',
      'targeting': 'English speakers',
      'description': 'Teach English to children and adults. TEFL certification provided. Immerse yourself in Spanish culture.',
      'benefits': ['TEFL certification', 'Spanish lessons', 'Cultural immersion', 'Travel opportunities'],
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
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement filter functionality
            },
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter offers',
          ),
        ],
      ),
      body: _sampleOffers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No offers available',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new opportunities',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sampleOffers.length,
              itemBuilder: (context, index) {
                final offer = _sampleOffers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                offer['title'],
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(offer['location'], style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(offer['duration'], style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(offer['targeting'], style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          offer['description'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Benefits:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        ...offer['benefits'].map<Widget>((benefit) => Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 2),
                              child: Row(
                                children: [
                                  const Text('• ', style: TextStyle(color: Colors.green)),
                                  Expanded(child: Text(benefit)),
                                ],
                              ),
                            )),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _shareToInstagram(offer),
                                icon: const Icon(Icons.share),
                                label: const Text('Share on Instagram'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement contact functionality
                              },
                              icon: const Icon(Icons.contact_mail),
                              label: const Text('Contact'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
