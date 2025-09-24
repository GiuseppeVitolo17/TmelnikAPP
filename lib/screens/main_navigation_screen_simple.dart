import 'package:flutter/material.dart';

class MainNavigationScreenSimple extends StatefulWidget {
  const MainNavigationScreenSimple({super.key});

  @override
  State<MainNavigationScreenSimple> createState() => _MainNavigationScreenSimpleState();
}

class _MainNavigationScreenSimpleState extends State<MainNavigationScreenSimple> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OffersScreenSimple(),
    const FeedbackScreenSimple(),
    const InformationScreenSimple(),
    const NewsScreenSimple(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tmelnik'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () async {
              // Sign out functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sign out would work here!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback_outlined),
            activeIcon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper),
            label: 'News',
          ),
        ],
      ),
    );
  }
}

class OffersScreenSimple extends StatelessWidget {
  const OffersScreenSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Project Offers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This section will show available work opportunities\nand project offers.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Instagram sharing would work here!'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share on Instagram'),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackScreenSimple extends StatelessWidget {
  const FeedbackScreenSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.feedback,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Feedback Collection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This section will collect user feedback\nand suggestions.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class InformationScreenSimple extends StatelessWidget {
  const InformationScreenSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'General Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This section will provide general information\nabout the platform and services.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class NewsScreenSimple extends StatelessWidget {
  const NewsScreenSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.newspaper,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Hot News & Interactions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This section will show the latest news\nand user interactions.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
