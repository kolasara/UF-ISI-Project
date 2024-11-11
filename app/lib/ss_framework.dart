import 'package:app/ss_add_schedule.dart';
import 'package:flutter/material.dart';
import 'package:app/ss_home.dart';
import 'package:app/ss_profile.dart';
import 'package:app/ss_search.dart';
import 'package:app/navigation.dart';
import 'package:app/ss_classes.dart';


class SsFramework extends StatefulWidget {
  @override
  Framework createState() => Framework();
}

class Framework extends State<SsFramework> {
  // track navigation page
  int currentIndex = 0;

  // currentIndex widget page
  static final List<StatefulWidget> regions = <StatefulWidget> [
    HomePage(),
    BlankStatefulWidget(),
    ClassesPage(),
    ProfilePage(),
  ];

  // update page info
  void _onItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  // Drawing the widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: regions.elementAt(currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifications'
          ),
          BottomNavigationBarItem(icon: Icon(Icons.local_library_rounded), label: 'Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        onTap: (index) => _onItemTapped(index),

      ),
    );
  }
}

// for unused pages
class BlankStatefulWidget extends StatefulWidget {
  @override _BlankStatefulWidgetState createState() => _BlankStatefulWidgetState();
}
class _BlankStatefulWidgetState extends State<BlankStatefulWidget> {
  @override Widget build(BuildContext context) {
    return Container(); // An empty container as the widget content
  }
}