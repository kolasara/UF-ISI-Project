import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_field.dart';
import 'profile.dart';
import 'user_service.dart';
import 'navigation.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  DateTime _selectedDay = DateTime.now();
  int bottomNavSelection = 0;
  // Dummy schedules for demonstration; in a real scenario, fetch from Firestore
  Map<DateTime, List<Map<String, String>>> _studentSchedule = {
    DateTime(2024, 10, 26): [
      {"title": "COP4600", "time": "9:35-10:25"}
    ],
    DateTime(2024, 10, 22): [
      {"title": "CEN3101", "time": "11:35-12:25"}
    ],
  };
  Map<DateTime, List<String>> _teacherSchedule = {};

  @override
  Widget build(BuildContext context) {
    //Get user data
    final userService = UserService();
    final role = userService.role;

    return Scaffold(
      appBar: buildAppBar(
        'Calendar',
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: SearchField());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDay,
            firstDay: DateTime(2022),
            lastDay: DateTime(2030),
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
          ),
          Expanded(
            child: ListView(
              children: role == 'Student'
                  ? _buildStudentScheduleForSelectedDay(_selectedDay)
                  : _buildTeacherScheduleForSelectedDay(_selectedDay),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (role == 'Student') {
            _showFilterWindow(context);
          } else {
            _openAddClass(context);
          }
        },
        child: Icon(role == 'Student' ? Icons.filter_list : Icons.add_circle),
        backgroundColor: Colors.blueGrey,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, 0),
    );
  }

  List<Widget> _buildStudentScheduleForSelectedDay(DateTime selectedDay) {
    final normalizedDay =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    if (_studentSchedule.containsKey(normalizedDay)) {
      return _studentSchedule[normalizedDay]!.map((event) {
        return _buildScheduleTile(event["title"]!, event["time"]!);
      }).toList();
    } else {
      return [Center(child: Text("No events for this day"))];
    }
  }

  List<Widget> _buildTeacherScheduleForSelectedDay(DateTime selectedDay) {
    if (_teacherSchedule[selectedDay] != null) {
      return _teacherSchedule[selectedDay]!.map((event) {
        return _buildScheduleTile(
            event, 'xx:xx - yy:yy'); // Placeholder for time
      }).toList();
    } else {
      return [Center(child: Text("No events for this day"))];
    }
  }

  Widget _buildScheduleTile(String title, String time) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Colors.pink.shade200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(time, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _openAddClass(BuildContext context) {
    TextEditingController classController = TextEditingController();
    TextEditingController timeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: classController,
                  decoration: InputDecoration(labelText: 'Class')),
              TextField(
                  controller: timeController,
                  decoration: InputDecoration(labelText: 'Time')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _saveInfo(classController.text, timeController.text);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveInfo(String title, String time) {
    FirebaseFirestore.instance.collection('classes info').add({
      'title': title,
      'time': time,
      'date': _selectedDay,
    });
  }

  // Dummy Filter method for Student
  void _showFilterWindow(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filtering'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: Text('Class #1'),
                value: false,
                onChanged: (bool? value) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Apply'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
