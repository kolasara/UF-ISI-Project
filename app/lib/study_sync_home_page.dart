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
    DateTime(2024, 10, 30): [
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
    return [
      StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('classes info')
            .where('date', isEqualTo: normalizedDay)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData){
            return Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!.docs;
          if (events.isEmpty){
            return Center(child: Text('No events today'));
          }
          return Column(
            children: events.map((doc){
              final data = doc.data() as Map<String, dynamic>;
              return _buildScheduleTile(
                data['title'] ?? 'No Title',
                data['time'] ?? 'No Time',
              );
            }).toList(),
          );
        },
      ),
    ];
  }

  List<Widget> _buildTeacherScheduleForSelectedDay(DateTime selectedDay) {
    final normalizedDay =
    DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    return [
      StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('classes info')
            .where('date', isEqualTo: normalizedDay)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!.docs;
          if (events.isEmpty) {
            return Center(child: Text('No events today'));
          }
          return Column(
            children: events.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildScheduleTile(
                data['title'] ?? 'No Title',
                data['time'] ?? 'No Time',
              );
            }).toList(),
          );
        },
      ),
    ];
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
    DateTime? selectedDateTime;

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
                decoration: InputDecoration(labelText: 'Class'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  selectedDateTime = await _selectDateTime(context);
                },
                child: Text(
                  selectedDateTime == null
                      ? 'Select Date & Time'
                      : 'Selected: ${selectedDateTime!.toString()}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (classController.text.isNotEmpty && selectedDateTime != null) {
                  _saveInfo(classController.text, selectedDateTime!);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<DateTime?> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }

  void _saveInfo(String title, DateTime dateTime) {
    FirebaseFirestore.instance.collection('classes info').add({
      'title': title,
      'time': '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
      'date': DateTime(dateTime.year, dateTime.month, dateTime.day),
    }).then((_){
      setState(() {
        _studentSchedule[dateTime] ??= []; //initialize somehow
        _studentSchedule[dateTime]!.add({
          'title': title,
          'time': '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
        });
      });
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
