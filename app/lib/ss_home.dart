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
import 'class_search.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  DateTime _selectedDay = DateTime.now();
  int bottomNavSelection = 0;

  String? selectedClassId;

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
                    color: Colors.purple, shape: BoxShape.circle)),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getScheduleForSelectedDay(_selectedDay),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data!;

                if (events.isEmpty) {
                  return Center(child: Text('No events today'));
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    // Create a clickable container
                    return GestureDetector(
                      onTap: () {
                        // Navigate to the detailed view
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScheduleDetailPage(
                              classId: event['classId'],
                              scheduleId: event['scheduleId'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0), // Space between items
                        padding:
                            EdgeInsets.all(16.0), // Space inside the border
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100, // Light background color
                          border: Border.all(
                              color: Colors.grey,
                              width: 1.0), // Border around the item
                          borderRadius:
                              BorderRadius.circular(8.0), // Rounded corners
                        ),
                        // Content of the schedule item
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${event['courseCode']} - ${event['courseName']}',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                                height:
                                    4.0), // Add a bit of spacing between lines
                            Text('Professor: ${event['professorName']}'),
                            Text('Activity: ${event['activityName']}'),
                            Text('Type: ${event['type']}'),
                            Text(
                              'Time: ${DateFormat('HH:mm').format(event['startTime'])} - ${DateFormat('HH:mm').format(event['endTime'])}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: role == 'Student'
          ? Container()
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ActionPage()));
              },
              child: Icon(Icons.add),
            ),
    );
  }

  Future<List<Map<String, dynamic>>> _getScheduleForSelectedDay(
      DateTime selectedDay) async {
    // Normalize the selected day
    DateTime normalizedDay =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    List<Map<String, dynamic>> events = [];

    try {
      // Fetch all classes the user is associated with
      final userService = UserService();
      final String? email = userService.email;

      // Depending on the user's role, fetch relevant classes
      List<String> classIds = [];

      if (userService.role == 'Teacher') {
        // For teachers, get classes they teach
        final classQuery = await FirebaseFirestore.instance
            .collection('classes')
            .where('userEmail', isEqualTo: email)
            .get();
        classIds = classQuery.docs.map((doc) => doc.id).toList();
      } else {
        // For students and TAs, get classes they are enrolled in
        classIds = await ClassSearch().getEnrolledClassIds(email!);
      }

      // Fetch schedules for those classes
      for (String classId in classIds) {
        final scheduleSnapshot = await FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('schedule')
            .get();

        for (var doc in scheduleSnapshot.docs) {
          final data = doc.data();
          final startTime = (data['startTime'] as Timestamp).toDate();
          final endTime = (data['endTime'] as Timestamp).toDate();

          // Check if the event is on the selected day
          if (isSameDay(startTime, normalizedDay)) {
            // Fetch class details
            final classDoc = await FirebaseFirestore.instance
                .collection('classes')
                .doc(classId)
                .get();
            final classData = classDoc.data();

            // Get professor's name
            final professorEmail = classData?['userEmail'] ?? '';
            final professorName =
                await ClassSearch().getNameByEmail(professorEmail);

            events.add({
              'classId': classId,
              'scheduleId': doc.id,
              'courseName': classData?['courseName'] ?? 'Unknown Course',
              'courseCode': classData?['courseCode'] ?? 'Unknown Code',
              'professorName': professorName,
              'activityName': data['name'] ?? 'No Title',
              'type': data['type'] ?? 'No Type',
              'startTime': startTime,
              'endTime': endTime,
            });
          }
        }
      }

      // Sort events in chronological order
      events.sort((a, b) =>
          (a['startTime'] as DateTime).compareTo(b['startTime'] as DateTime));

      return events;
    } catch (e) {
      print('Error fetching schedule: $e');
      return [];
    }
  }
/*
  void _bookOfficeHour(BuildContext context, String name, DateTime startTime,
      DateTime endTime, String teacherEmail) async {
    final userService = UserService();
    final String? studentEmail = userService.email;

    if (studentEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User email not found. Please log in again.')));
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

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

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Office hour booked successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to book office hour. Please try again.')));
    } finally {
      Navigator.of(context).pop(); // Close the loading indicator
    }
  }
 */

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

class ScheduleDetailPage extends StatefulWidget {
  final String classId;
  final String scheduleId;

  ScheduleDetailPage({required this.classId, required this.scheduleId});

  @override
  _ScheduleDetailPageState createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  Map<String, dynamic>? scheduleData;
  Map<String, dynamic>? classData;
  String? professorName;
  bool isLoading = true;
  String? userRole;
  String? userEmail;
  List<Map<String, dynamic>> tas = [];
  bool isLoadingTA = true;
  bool isUserProfessor = false;
  bool isUserStudent = false;
  bool isUserTAInOfficeHour = false;

  late DateTime startTime;
  late DateTime endTime;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final userService = UserService();
    userRole = userService.role;
    userEmail = userService.email;

    await _fetchScheduleDetails();
    await _determineUserRoles();
    if (scheduleData?['type'] == 'Office') {
      await _fetchTAList();
    }

    if (scheduleData != null) {
      // Initialize startTime and endTime from scheduleData
      startTime = (scheduleData!['startTime'] as Timestamp).toDate();
      endTime = (scheduleData!['endTime'] as Timestamp).toDate();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchScheduleDetails() async {
    try {
      // Fetch schedule data
      final scheduleDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .get();
      scheduleData = scheduleDoc.data() ?? {};

      setState(() {
        scheduleData = scheduleDoc.data();
        if (scheduleData != null) {
          startTime = (scheduleData!['startTime'] as Timestamp).toDate();
          endTime = (scheduleData!['endTime'] as Timestamp).toDate();
        }
      });

      // Fetch class data
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      classData = classDoc.data();

      // Get professor's name
      final professorEmail = classData?['userEmail'] ?? '';
      professorName = await ClassSearch().getNameByEmail(professorEmail);
    } catch (e) {
      print('Error fetching schedule details: $e');
    }
  }

  Future<void> _determineUserRoles() async {
    // Check if user is professor
    final professorEmail = classData?['userEmail'] ?? '';
    isUserProfessor = (userEmail == professorEmail);

    // Check if user is student in the class
    final studentDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('students')
        .doc(userEmail)
        .get();
    isUserStudent = studentDoc.exists;

    if (scheduleData?['type'] == 'Office') {
      // Check if user is TA assigned to the office hour
      final taDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .collection('TA')
          .doc(userEmail)
          .get();
      isUserTAInOfficeHour = taDoc.exists;
    }
  }

  Future<void> _fetchTAList() async {
    try {
      final taSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .collection('TA')
          .get();

      tas = await Future.wait(
        taSnapshot.docs.map((doc) async {
          final email = doc.id;
          final name = await ClassSearch().getNameByEmail(email);
          return {'email': email, 'name': name};
        }),
      );
    } catch (e) {
      print('Error fetching TA list: $e');
      tas = [];
    }

    setState(() {
      isLoadingTA = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || scheduleData == null || classData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Schedule Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isOfficeHours = scheduleData?['type'] == 'Office';

    return Scaffold(
      appBar: AppBar(title: Text('Schedule Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display general information
            Text(
              '${classData?['courseCode']} - ${classData?['courseName']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Professor: $professorName'),
            SizedBox(height: 10),
            Text('Activity: ${scheduleData?['name']}'),
            Text('Type: ${scheduleData?['type']}'),
            Text(
              'Time: ${DateFormat('yyyy-MM-dd HH:mm').format((scheduleData?['startTime'] as Timestamp).toDate())} - ${DateFormat('yyyy-MM-dd HH:mm').format((scheduleData?['endTime'] as Timestamp).toDate())}',
            ),
            SizedBox(height: 20),
            // Different views based on role and schedule type
            if (!isOfficeHours && isUserStudent)
              _buildStudentNonOfficeHoursView()
            else if (!isOfficeHours && isUserProfessor)
              _buildProfessorNonOfficeHoursView()
            else if (isOfficeHours && isUserStudent && !isUserTAInOfficeHour)
              _buildStudentOfficeHoursView()
            else if (isOfficeHours && (isUserProfessor || isUserTAInOfficeHour))
              _buildProfessorOrTAOfficeHoursView()
            else
              SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  // Non-Office Hours - Student View
  Widget _buildStudentNonOfficeHoursView() {
    // Nothing else to display
    return SizedBox.shrink();
  }

  // Non-Office Hours - Professor View
  Widget _buildProfessorNonOfficeHoursView() {
    final TextEditingController nameController =
        TextEditingController(text: scheduleData?['name']);
    final TextEditingController typeController =
        TextEditingController(text: scheduleData?['type']);

    DateTime startTime = (scheduleData?['startTime'] as Timestamp).toDate();
    DateTime endTime = (scheduleData?['endTime'] as Timestamp).toDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Activity Name'),
        ),
        // Start Time Picker
        ListTile(
          title: Text(
              'Start Time: ${DateFormat('yyyy-MM-dd HH:mm').format(startTime)}'),
          trailing: Icon(Icons.calendar_today),
          onTap: () async {
            DateTime? picked = await showDateTimePicker(context, startTime);
            if (picked != null) {
              setState(() {
                startTime = picked;
              });
            }
          },
        ),
        // End Time Picker
        ListTile(
          title: Text(
              'End Time: ${DateFormat('yyyy-MM-dd HH:mm').format(endTime)}'),
          trailing: Icon(Icons.calendar_today),
          onTap: () async {
            DateTime? picked = await showDateTimePicker(context, endTime);
            if (picked != null) {
              setState(() {
                endTime = picked;
              });
            }
          },
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _saveScheduleItem(
              nameController.text, typeController.text, startTime, endTime),
          child: Text('Save Changes'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _deleteScheduleItem,
          child: Text('Delete Scheduled Item'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }

  // Student Office Hours View
  Widget _buildStudentOfficeHoursView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .collection('bookings')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        final bookings = snapshot.data!.docs;
        bool hasBooked = bookings.any((doc) => doc.id == userEmail);
        int currentBookings = bookings.length;
        int? maxBookings = scheduleData?['maxBookings'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Status and Button
            Text(
              'Bookings: $currentBookings / ${scheduleData?['maxBookings']?.toString() ?? '\u221E'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (hasBooked) {
                  _cancelOfficeHourBooking();
                } else if (maxBookings == null ||
                    currentBookings < maxBookings) {
                  _bookOfficeHour(currentBookings, maxBookings);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No booking slots available.')),
                  );
                }
              },
              child: Text(hasBooked ? 'Cancel Booking' : 'Book Office Hour'),
            ),
            SizedBox(height: 20),

            // List of TAs
            Text('TAs Available:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (isLoadingTA)
              CircularProgressIndicator()
            else if (tas.isEmpty)
              Text('No TAs assigned yet.')
            else
              Column(
                children: tas.map((ta) {
                  return ListTile(
                    title: Text(ta['name']),
                    subtitle: Text(ta['email']),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }


  void _cancelOfficeHourBooking() async {
    try {
      final userService = UserService();

      final String? userEmail = userService.email;
      final String? userRole = userService.role;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      final userName = userDoc.data()?['name'] ?? 'Unknown User';
      final taNames = tas.map((ta) => ta['name']).join(', ');

      // Delete the booking from Firestore for student
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .collection('bookings')
          .doc(userEmail)
          .delete();

      // Delete related notifications for student and teacher
      final notificationQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('title', isEqualTo: 'Booking Confirmed!')
          .get();

      if (notificationQuery.docs.isNotEmpty) {
        for (var doc in notificationQuery.docs) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(doc.id)
              .delete();
        }
      }

      final teacherNotificationQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('title', isEqualTo: 'New booking made by $userName')
          .get();

      if (teacherNotificationQuery.docs.isNotEmpty) {
        for (var doc in teacherNotificationQuery.docs) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(doc.id)
              .delete();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking cancelled successfully.')),
      );

      setState(() {
        // Update the UI to reflect booking status
      });
    } catch (e) {
      print('Error cancelling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking.')),
      );
    }
  }



  void _bookOfficeHour(int currentBookings, int? maxBookings) async {
    if (maxBookings != null && currentBookings >= maxBookings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No booking slots available.')),
      );
      return;
    }

    try {
      final userService = UserService();
      final String? userEmail = userService.email;
      final String? userRole = userService.role;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      final userName = userDoc.data()?['name'] ?? 'Unknown User';
      final taNames = tas.map((ta) => ta['name']).join(', ');

      // Add the booking to Firestore
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .collection('bookings')
          .doc(userEmail)
          .set({'email': userEmail});

      // Notifications and SnackBar logic based on user role
      if (userRole == 'Student') {
        String notificationTitle = 'Booking Confirmed!';
        String notificationMessage = 'You have successfully booked $taNames office hour.';

        await FirebaseFirestore.instance.collection('notifications').add({
          'title': notificationTitle,
          'message': notificationMessage,
          'timestamp': DateTime.now(),
          'read': false,
          'role': 'Student',
        });

        // Show success message for the student
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Office hour booked successfully.')),
        );

        // Notify the teacher
        String teacherNotificationTitle = 'New booking made by $userName';
        String teacherNotificationMessage = '$userName booked office hours for $taNames.';

        await FirebaseFirestore.instance.collection('notifications').add({
          'title': teacherNotificationTitle,
          'message': teacherNotificationMessage,
          'timestamp': DateTime.now(),
          'read': false,
          'role': 'Teacher',
        });
      }

      setState(() {});

    } catch (e) {
      print('Error booking office hour: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book office hour.')),
      );
    }
  }


  Widget _buildProfessorOrTAOfficeHoursView() {
    final TextEditingController maxBookingsController = TextEditingController(
      text: scheduleData?['maxBookings']?.toString() ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Time Picker
        ListTile(
          title: Text(
              'Start Time: ${DateFormat('yyyy-MM-dd HH:mm').format(startTime)}'),
          trailing: Icon(Icons.calendar_today),
          onTap: () async {
            DateTime? picked = await showDateTimePicker(context, startTime);
            if (picked != null) {
              setState(() {
                startTime = picked; // Update state
              });
            }
          },
        ),

        // End Time Picker
        ListTile(
          title: Text(
              'End Time: ${DateFormat('yyyy-MM-dd HH:mm').format(endTime)}'),
          trailing: Icon(Icons.calendar_today),
          onTap: () async {
            DateTime? picked = await showDateTimePicker(context, endTime);
            if (picked != null) {
              setState(() {
                endTime = picked; // Update state
              });
            }
          },
        ),

        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _saveScheduleItem(
              scheduleData?['name'], scheduleData?['type'], startTime, endTime),
          child: Text('Save Time Changes'),
        ),

        // Editable fields
        TextField(
          controller: maxBookingsController,
          decoration: InputDecoration(labelText: 'Max Bookings'),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () =>
              _updateMaxBookings(int.tryParse(maxBookingsController.text)),
          child: Text('Update Max Bookings'),
        ),
        SizedBox(height: 20),

        // List of students who booked office hours
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('schedule')
              .doc(widget.scheduleId)
              .collection('bookings')
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }
            final bookings = snapshot.data!.docs;
            int currentBookings = bookings.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Bookings: $currentBookings / ${scheduleData?['maxBookings']?.toString() ?? '\u221E'}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text('Students who booked:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...bookings.map((doc) {
                  final email = doc.id;
                  return FutureBuilder<String>(
                    future: ClassSearch().getNameByEmail(email),
                    builder: (context, nameSnapshot) {
                      if (!nameSnapshot.hasData) {
                        return ListTile(
                          title: Text('Loading...'),
                        );
                      }
                      final name = nameSnapshot.data!;
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(email),
                      );
                    },
                  );
                }).toList(),
              ],
            );
          },
        ),
        SizedBox(height: 20),

        // Display TA list
        Text('TAs Assigned:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (isLoadingTA)
          CircularProgressIndicator()
        else if (tas.isEmpty)
          Text('No TAs assigned yet.')
        else
          Column(
            children: tas.map((ta) {
              return ListTile(
                title: Text(ta['name']),
                subtitle: Text(ta['email']),
                trailing: isUserProfessor
                    ? IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () => _removeTA(ta['email']),
                      )
                    : null,
              );
            }).toList(),
          ),
        SizedBox(height: 20),

        // Add TA Button (only professors can see this)
        if (isUserProfessor)
          ElevatedButton(
            onPressed: _addTA,
            child: Text('Add TA'),
          ),

        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _deleteScheduleItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('Delete Scheduled Item'),
        ),
      ],
    );
  }

  Future<void> _updateMaxBookings(int? newMaxBookings) async {
    try {
      if (newMaxBookings == null || newMaxBookings < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid value for 'max bookings'.")),
        );
        return;
      }

      // Save maxBookings to Firestore
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .update({'maxBookings': newMaxBookings});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Max bookings updated successfully.')),
      );

      // Update local state and schedule data to reflect the changes
      setState(() {
        scheduleData!['maxBookings'] = newMaxBookings;
      });
    } catch (e) {
      print('Error updating max bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update max bookings.')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableTAs() async {
    try {
      // Step 1: Fetch all students marked as TAs for the class
      final taSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .where('isTA', isEqualTo: true) // Filter only TAs
          .get();

      List<Map<String, dynamic>> allTAs = await Future.wait(
        taSnapshot.docs.map((doc) async {
          final email = doc.id; // Document ID is the email
          final name = await ClassSearch().getNameByEmail(email);
          return {'email': email, 'name': name};
        }),
      );

      // Step 2: Fetch TAs currently assigned to this office hour
      final assignedTASnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .collection('TA')
          .get();

      final assignedTAEmails =
          assignedTASnapshot.docs.map((doc) => doc.id).toSet();

      // Step 3: Filter out already assigned TAs
      List<Map<String, dynamic>> availableTAs = allTAs.where((ta) {
        return !assignedTAEmails.contains(ta['email']);
      }).toList();

      return availableTAs;
    } catch (e) {
      print('Error fetching available TAs: $e');
      return [];
    }
  }

  void _addTA() async {
    List<Map<String, dynamic>> availableTAs = await _fetchAvailableTAs();

    // If no eligible TAs are available
    if (availableTAs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No available TAs for this office hour.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a TA to Assign'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableTAs.length,
              itemBuilder: (context, index) {
                final ta = availableTAs[index];
                return ListTile(
                  title: Text(ta['name']),
                  subtitle: Text(ta['email']),
                  onTap: () async {
                    await _addTAToOfficeHour(ta['email']);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addTAToOfficeHour(String taEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .collection('TA')
          .doc(taEmail)
          .set({'email': taEmail});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TA added successfully.')),
      );
      setState(() {
        isLoadingTA = true;
        _fetchTAList();
      });
    } catch (e) {
      print('Error adding TA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add TA.')),
      );
    }
  }

  void _removeTA(String taEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .collection('TA')
          .doc(taEmail)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TA removed.')),
      );
      setState(() {
        tas.removeWhere((ta) => ta['email'] == taEmail);
      });
    } catch (e) {
      print('Error removing TA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove TA.')),
      );
    }
  }

  void _saveScheduleItem(
      String? name, String? type, DateTime startTime, DateTime endTime) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .update({
        'name': name,
        'type': type,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes saved successfully.')),
      );
      setState(() {
        scheduleData!['name'] = name;
        scheduleData!['type'] = type;
        scheduleData!['startTime'] = Timestamp.fromDate(startTime);
        scheduleData!['endTime'] = Timestamp.fromDate(endTime);
      });
    } catch (e) {
      print('Error saving schedule item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes.')),
      );
    }
  }

  void _deleteScheduleItem() async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('schedule')
          .doc(widget.scheduleId)
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Scheduled item deleted.')));
      Navigator.pop(context);
    } catch (e) {
      print('Error deleting schedule item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete scheduled item.')),
      );
    }
  }

  Future<DateTime?> showDateTimePicker(
      BuildContext context, DateTime initialDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
