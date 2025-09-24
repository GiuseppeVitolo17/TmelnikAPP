import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final List<Map<String, dynamic>> _sampleNews = [
    {
      'title': 'New Opportunities in Croatia',
      'content': 'We have exciting new work opportunities available in Dubrovnik for the summer season. Apply now!',
      'type': 'news',
      'emoji': '📰',
      'isHot': true,
      'time': '2 hours ago',
      'likes': 15,
      'comments': 3,
    },
    {
      'title': 'Travel Safety Update',
      'content': 'Important safety information for all travelers. Please read the updated guidelines.',
      'type': 'announcement',
      'emoji': '📢',
      'isHot': false,
      'time': '1 day ago',
      'likes': 8,
      'comments': 1,
    },
    {
      'title': 'Monthly Feedback Survey',
      'content': 'Help us improve our services by completing this quick survey about your recent experience.',
      'type': 'questionnaire',
      'emoji': '📝',
      'isHot': true,
      'time': '3 days ago',
      'likes': 12,
      'comments': 7,
    },
    {
      'title': 'Success Story: Maria from Spain',
      'content': 'Read about Maria\'s amazing experience working in Germany for 6 months.',
      'type': 'success',
      'emoji': '🏆',
      'isHot': false,
      'time': '1 week ago',
      'likes': 25,
      'comments': 5,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News & Updates'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement refresh functionality
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh news',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sampleNews.length,
        itemBuilder: (context, index) {
          final news = _sampleNews[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        news['emoji'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          news['title'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (news['isHot'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'HOT',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news['content'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        news['time'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.favorite_outline, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        news['likes'].toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.comment_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        news['comments'].toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement create post functionality
        },
        tooltip: 'Create Post',
        child: const Icon(Icons.add),
      ),
    );
  }
}
