import 'package:app/user_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  DateTime _selectedDay = DateTime.now();

  final userService = UserService();

  @override
  Widget build(BuildContext context) {
    final normalizedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final startOfDay = normalizedDay;
    final endOfDay = normalizedDay.add(Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999));

    final String? userEmail = userService.email;
    final String? userRole = userService.role;

    // Debug Statements
    print('Start of Day: $startOfDay');
    print('End of Day: $endOfDay');
    print('User Role: $userRole');

    return Scaffold(
      appBar: buildAppBar(
        'Notifications',
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {},
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
                  .where('timestamp', isLessThanOrEqualTo: endOfDay)
                  .where('role', isEqualTo: userRole)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No events today'));
                }

                final events = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final data = events[index].data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp;
                    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp.toDate());

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(data['title'] ?? 'No Title'),
                        subtitle: Text(
                          '${data['message'] ?? 'No Description'}\n$formattedDate',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
}
