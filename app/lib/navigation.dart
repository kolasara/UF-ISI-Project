import 'package:flutter/material.dart';
import 'profile.dart';
import 'study_sync_home_page.dart';

AppBar buildAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text('StudySync - $title'),
    backgroundColor: Colors.deepOrange[100],
    actions: actions,
  );
}

Widget buildBottomNavigationBar(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(
          icon: Icon(Icons.notifications), label: 'Notifications'),
      BottomNavigationBarItem(icon: Icon(Icons.list), label: 'To-Do'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ],
    currentIndex: currentIndex,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.purple,
    onTap: (index) => itemTapped(context, index),
  );
}

void itemTapped(BuildContext context, int index) {
  switch (index) {
    case 0:
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
      break;
    case 1:
      // Navigate to Notifications page
      break;
    case 2:
      // Navigate to To-Do page
      break;
    case 3:
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => ProfilePage()),
        (route) => false,
      );
      break;
  }
}
