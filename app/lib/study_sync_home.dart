import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'search_field.dart';

class StudySyncHomePage extends StatefulWidget {
  @override
  _StudySyncHomePageState createState() => _StudySyncHomePageState();
}

class _StudySyncHomePageState extends State<StudySyncHomePage> {
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<String>> _schedule = {
    // connect to the schedule here
  };

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

      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Office Hours',
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

  // Helper function to build schedule tiles for the selected day
  List<Widget> _buildScheduleForSelectedDay(DateTime selectedDay) {
    if (_schedule[selectedDay] != null) {
      // If there is a schedule for the selected day, show the events
      return _schedule[selectedDay]!.map((event) {
        return _buildScheduleTile(event, 'xx:xx - yy:yy'); // Placeholder for time
      }).toList();
    } else {
      // If no events are scheduled, show an empty message
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
