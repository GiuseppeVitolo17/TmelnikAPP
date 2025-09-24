import 'package:flutter/material.dart';
import 'project_offers_screen_local.dart';
import 'feedback_screen_local.dart';
import 'information_screen_local.dart';
import 'news_screen_local.dart';

class MainNavigationScreenLocal extends StatefulWidget {
  const MainNavigationScreenLocal({super.key});

  @override
  State<MainNavigationScreenLocal> createState() => _MainNavigationScreenLocalState();
}

class _MainNavigationScreenLocalState extends State<MainNavigationScreenLocal> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ProjectOffersScreenLocal(),
    const FeedbackScreenLocal(),
    const InformationScreenLocal(),
    const NewsScreenLocal(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'News',
          ),
        ],
      ),
    );
  }
}
