import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart';
import 'navigation.dart';
import 'ss_search.dart';
import 'ss_add_schedule.dart';
import 'package:intl/intl.dart';
import 'ss_notifications.dart';
import 'package:rxdart/rxdart.dart';

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
          if (role == 'Student')
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: () {
              _showFilterWindow(context);
            },
          ),
          if (role == 'Teacher')
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: () {
                _showStudentList(context);
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
    final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final userService = UserService();
    final String? email = userService.email;
    if (email == null) {
      return [
        Center(child: Text('User email not found. Please log in again.')),
      ];
    }

    return [
      FutureBuilder(
        future: _isUserSignedUpOrTeacherCreatedClass('euKvpKCE5ct6dHkAwSvm', email),
        builder: (context, AsyncSnapshot<bool> snapshot1) {
          if (!snapshot1.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final isSignedUpForClass1 = snapshot1.data!;

          return FutureBuilder(
            future: _isUserSignedUpOrTeacherCreatedClass(
                'lkcZRTgbT82iNYfGkwMg', email),
            builder: (context, AsyncSnapshot<bool> snapshot2) {
              if (!snapshot2.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final isSignedUpForClass2 = snapshot2.data!;

              return FutureBuilder(
                future: _isUserSignedUpOrTeacherCreatedClass(
                    'jJTbO8wTb46B27zk8935', email),
                builder: (context, AsyncSnapshot<bool> snapshot3) {
                  if (!snapshot3.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final isSignedUpForClass3 = snapshot3.data!;

                  final eventsClass1 = isSignedUpForClass1
                      ? FirebaseFirestore.instance
                      .collection('classes')
                      .doc('euKvpKCE5ct6dHkAwSvm')
                      .collection('schedule')
                      .where('startTime',
                      isLessThanOrEqualTo: Timestamp.fromDate(
                          selectedDay.add(Duration(hours: 23, minutes: 59))))
                      .snapshots()
                      : null;

                  final eventsClass2 = isSignedUpForClass2
                      ? FirebaseFirestore.instance
                      .collection('classes')
                      .doc('lkcZRTgbT82iNYfGkwMg')
                      .collection('schedule')
                      .where('startTime',
                      isLessThanOrEqualTo: Timestamp.fromDate(
                          selectedDay.add(Duration(hours: 23, minutes: 59))))
                      .snapshots()
                      : null;

                  final eventsClass3 = isSignedUpForClass3
                      ? FirebaseFirestore.instance
                      .collection('classes')
                      .doc('jJTbO8wTb46B27zk8935')
                      .collection('schedule')
                      .where('startTime',
                      isLessThanOrEqualTo: Timestamp.fromDate(
                          selectedDay.add(Duration(hours: 23, minutes: 59))))
                      .snapshots()
                       :null;

                  final officehours3 = isSignedUpForClass3
                      ? FirebaseFirestore.instance
                      .collection('classes')
                      .doc('jJTbO8wTb46B27zk8935')
                      .collection('officehours')
                      .where('startTime',
                      isLessThanOrEqualTo: Timestamp.fromDate(
                          selectedDay.add(Duration(hours: 23, minutes: 59))))
                      .snapshots()
                      :null;




                  return Column(
                    children: [
                      if (eventsClass1 != null)
                        StreamBuilder(
                          stream: eventsClass1,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            final events1 = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final startTime = (data['startTime'] as Timestamp)
                                  .toDate();
                              return isSameDay(startTime, selectedDay);
                            }).toList();

                            return Column(
                              children: events1.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final startTime = (data['startTime'] as Timestamp)
                                    .toDate();
                                final endTime = (data['endTime'] as Timestamp)
                                    .toDate();
                                final name = data['name'] ?? 'No Title';
                                final type = data['type'] ?? 'No Type';
                                return _buildDetailedScheduleTile(
                                    name, startTime, endTime, type);
                              }).toList(),
                            );
                          },
                        ),
                      if (eventsClass2 != null)
                        StreamBuilder(
                          stream: eventsClass2,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            final events2 = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final startTime = (data['startTime'] as Timestamp)
                                  .toDate();
                              return isSameDay(startTime, selectedDay);
                            }).toList();


                            return Column(
                              children: events2.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final startTime = (data['startTime'] as Timestamp)
                                    .toDate();
                                final endTime = (data['endTime'] as Timestamp)
                                    .toDate();
                                final name = data['name'] ?? 'No Title';
                                final type = data['type'] ?? 'No Type';
                                return _buildDetailedScheduleTile(
                                    name, startTime, endTime, type);
                              }).toList(),
                            );
                          },
                        ),
                      if (eventsClass3 != null)
                        StreamBuilder(
                          stream: eventsClass3,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            final events3 = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final startTime = (data['startTime'] as Timestamp)
                                  .toDate();
                              return isSameDay(startTime, selectedDay);
                            }).toList();


                            return Column(
                              children: events3.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final startTime = (data['startTime'] as Timestamp)
                                    .toDate();
                                final endTime = (data['endTime'] as Timestamp)
                                    .toDate();
                                final name = data['name'] ?? 'No Title';
                                final type = data['type'] ?? 'No Type';
                                return _buildDetailedScheduleTile(
                                    name, startTime, endTime, type);
                              }).toList(),
                            );
                          },
                        ),
                      if (officehours3 != null)
                        StreamBuilder(
                          stream: officehours3,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            final eventsoffice3 = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final startTime = (data['startTime'] as Timestamp)
                                  .toDate();
                              return isSameDay(startTime, selectedDay);
                            }).toList();


                            return Column(
                              children: eventsoffice3.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final startTime = (data['startTime'] as Timestamp)
                                    .toDate();
                                final endTime = (data['endTime'] as Timestamp)
                                    .toDate();
                                final name = data['name'] ?? 'No Title';
                                final type = data['type'] ?? 'No Type';
                                final teacherEmail = data['teacherEmail'] ?? 'No teacher email';
                                // ADD GESTURE DEDECTOR HERE
                                return GestureDetector(
                                  onTap: () => _showBookingWindow(context, name, startTime, endTime, teacherEmail),
                                  child: _buildDetailedScheduleTile(name, startTime, endTime, type),
                                );

                              }).toList(),
                            );
                          },
                        ),

                    ],
                  );
                },
              );
            },
          );
        },
      ),
    ];
  }


  void _bookOfficeHour(BuildContext context, String name, DateTime startTime, DateTime endTime, String teacherEmail) async {
    final userService = UserService();
    final String? studentEmail = userService.email;

    if (studentEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User email not found. Please log in again.')));
      return;
    }

    // Create booking document in Firestore
    await FirebaseFirestore.instance.collection('bookings').add({
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'students': studentEmail,
      'teachers': teacherEmail,
      'timestamp': DateTime.now(),
    });

    // Create notification for the teacher
    await FirebaseFirestore.instance.collection('notifications').add({
      'teacherEmail': teacherEmail,
      'message': 'You have a new booking from $studentEmail for $name.',
      'timestamp': DateTime.now(),
      'read': false,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Office hour booked successfully.')));
    Navigator.of(context).pop();
  }

  void _showBookingWindow(BuildContext context, String name, DateTime startTime, DateTime endTime, String teacherEmail) {
    String startFormatted = DateFormat('HH:mm').format(startTime);
    String endFormatted = DateFormat('HH:mm').format(endTime);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Book Office Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: $name'),
              Text('Start Time: $startFormatted'),
              Text('End Time: $endFormatted'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Book'),
              onPressed: () {
                _bookOfficeHour(context, name, startTime, endTime, teacherEmail);
              },
            ),
          ],
        );
      },
    );
  }


  List<Widget> _buildTeacherScheduleForSelectedDay(DateTime selectedDay) {
    final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final classIds = ['lkcZRTgbT82iNYfGkwMg', 'jJTbO8wTb46B27zk8935', 'euKvpKCE5ct6dHkAwSvm'];

    List<Stream<QuerySnapshot>> streams = classIds.map((classId) {
      return FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('schedule')
          .where('startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedDay))
          .where('startTime',
          isLessThanOrEqualTo: Timestamp.fromDate(
              normalizedDay.add(Duration(hours: 23, minutes: 59))))
          .snapshots();
    }).toList();

    return [
      StreamBuilder(
        stream: CombineLatestStream.list(streams),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> allDocs = [];
          for (var snap in snapshot.data!) {
            allDocs.addAll(snap.docs);
          }

          final events = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final startTime = (data['startTime'] as Timestamp).toDate();
            return isSameDay(startTime, normalizedDay);
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



  Future<bool> _isUserSignedUpOrTeacherCreatedClass(String classId, String email) async {
    try {
      final studentDocRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(email);
      final studentDocSnapshot = await studentDocRef.get();
      if (studentDocSnapshot.exists) {
        return true;
      }
      final teacherDocRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('teachers')
          .doc(email);
      final teacherDocSnapshot = await teacherDocRef.get();
      if (teacherDocSnapshot.exists) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking class signup or creation: $e');
      return false;
    }
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

  void _showStudentList(BuildContext context) async {
    try {
      showDialog(
        context: context,
        builder: (context) => Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .get();

      Navigator.pop(context);

      final List<DocumentSnapshot> studentDocs = studentSnapshot.docs;

      if (studentDocs.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('No Students Found'),
              content: Text('There are no students in the database.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Student List'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: studentDocs.length,
                itemBuilder: (context, index) {
                  final studentName = studentDocs[index]['name'] ?? 'Unknown';
                  return ListTile(
                    leading: Icon(Icons.person),
                    title: Text(studentName),
                    trailing: TextButton(
                      onPressed: () {
                        _assignStudent(context, studentName);
                      },
                      child: Text('Assign to TA'),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to load students: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  void _assignStudent(BuildContext context, String studentName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$studentName assigned!')),
    );
  }


}
