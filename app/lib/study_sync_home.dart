import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'search_field.dart';

class StudySyncHomePage extends StatefulWidget {
  @override
  _StudySyncHomePageState createState() => _StudySyncHomePageState();
}

class _StudySyncHomePageState extends State<StudySyncHomePage> {
  DateTime _selectedDay = DateTime.now();

  final Map<DateTime, List<Map<String, String>>> _schedule = {
    DateTime(2024, 10, 26): [
      {"title": "COP4600", "time": "9:35-10:25"},
    ],
    DateTime(2024, 10, 22): [
      {"title": "CEN3101", "time": "11:35-12:25"},
    ],

  };

  DateTime _normDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StudySync - Calendar'),
        // make it like a beige kind of color maybe
        backgroundColor: Colors.deepOrange[100],
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SearchField(),
              );
            },
          ),

        ],
      ),
      body: Column(
        children: [
          // Calendar widget that lets users pick a date
          TableCalendar(
            focusedDay: _selectedDay,
            firstDay: DateTime(2022),
            lastDay: DateTime(2030),
            // need a weekly view based on the design
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            // make each day selectable
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
          ),

          // Dynamically load the schedule based on the selected date
          Expanded(
            child: ListView(
              children: _buildScheduleForSelectedDay(_selectedDay),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _ShowFilterWindow(context),
        child: Icon(Icons.filter_list),
        backgroundColor: Colors.blueGrey,
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'To-Do',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
      ),
    );
  }

  // add the filter function here with dummy data
  void _ShowFilterWindow(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtering'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: Text('Class #1'),
                value: false,
                onChanged: (bool? value) {

                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Apply'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      }
    );
  }


  // Helper function to build schedule tiles for the selected day
  List<Widget> _buildScheduleForSelectedDay(DateTime selectedDay) {
    final normalizedDay = _normDate(selectedDay);
    if (_schedule.containsKey(normalizedDay)) {
      return _schedule[normalizedDay]!.map((event) {
        return _buildScheduleTile(event["title"]!, event["time"]!);
      }).toList();
    } else {
      return [Center(child: Text("No events for this day"))];
    }
  }

  // Method to build a schedule tile with event name and time
  Widget _buildScheduleTile(String title, String time) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Colors.pink.shade200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
