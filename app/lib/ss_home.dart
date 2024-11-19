import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart';
import 'navigation.dart';
import 'ss_search.dart';
import 'ss_add_schedule.dart';
import 'package:intl/intl.dart';


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
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _showFilterWindow(context);
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
            calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle
                )
            ),
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
      floatingActionButton: role == 'Student' ? Container() : FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ActionPage())
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildStudentScheduleForSelectedDay(DateTime selectedDay) {
    final normalizedDay =
    DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    return [
      StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('classes info')
            .where('date', isEqualTo: Timestamp.fromDate(normalizedDay))
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData){
            return Center(child: CircularProgressIndicator());
          }
          final events = (snapshot.data! as QuerySnapshot).docs;
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
    final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    return [
      StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc('euKvpKCE5ct6dHkAwSvm') // MIGHT WANT TO RENAME THIS TO BE EASIER TO CODE LATER!!!
            .collection('schedule')
            .where('startTime',
            isLessThanOrEqualTo: Timestamp.fromDate(
                selectedDay.add(Duration(hours: 23, minutes: 59))))
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final startTime = (data['startTime'] as Timestamp).toDate();
            return isSameDay(startTime, selectedDay);
          }).toList();

          if (events.isEmpty) {
            return Center(child: Text('No events today'));
          }

          return Column(
            children: events.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final startTime = (data['startTime'] as Timestamp).toDate();
              final endTime = (data['endTime'] as Timestamp).toDate();
              final name = data['name'] ?? 'No Title';
              final type = data['type'] ?? 'No Type';

              return _buildDetailedScheduleTile(name, startTime, endTime, type);
            }).toList(),
          );
        },
      ),
    ];
  }


  Widget _buildDetailedScheduleTile(
      String name, DateTime startTime, DateTime endTime, String type) {
    // Format the start and end times to display only hour and minute
    String startFormatted = DateFormat('HH:mm').format(startTime);
    String endFormatted = DateFormat('HH:mm').format(endTime);

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Colors.grey.shade200, // Light gray color
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            '$type',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 8),
          Text(
            'Start Time: $startFormatted',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'End Time: $endFormatted',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
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


  void _saveInfo(String title, DateTime dateTime) {
    FirebaseFirestore.instance.collection('classes').add({
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
