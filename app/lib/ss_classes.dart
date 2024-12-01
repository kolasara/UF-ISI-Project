import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart';
import 'navigation.dart';
import 'ss_search.dart';
import 'ss_add_schedule.dart';
import 'class_search.dart';

class ClassesPage extends StatefulWidget {
  @override
  ClassesPageState createState() => ClassesPageState();
}

class ClassesPageState extends State<ClassesPage> {
  DateTime _selectedDay = DateTime.now();
  int bottomNavSelection = 0;

  // Filters for class search
  String? courseCodeFilter;
  String? courseNameFilter;
  String? userEmailFilter;

  @override
  Widget build(BuildContext context) {
    // Get user data
    final userService = UserService();
    final role = userService.role;
    final String? email = userService.email;

    final classSearch = ClassSearch();

    return Scaffold(
      appBar: buildAppBar(
        'Classes',
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show filter window when filter icon is pressed
              _showFilterWindow(context);
            },
          ),
        ],
      ),
      body: role == 'Teacher'
          ? FutureBuilder<List<String>>(
              future: classSearch.getClassDocumentIdsByEmail(email!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error fetching classes'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No classes found.'));
                }

                final classIds = snapshot.data!;

                return ClassListView(classIds: classIds);
              },
            )
          // Student view: display signed-up classes and class search
          : _buildStudentView(email),
      floatingActionButton: role == 'Student'
          ? Container()
          : FloatingActionButton(
              onPressed: () {
                _openAddClass(context);
              },
              child: Icon(Icons.add),
            ),
    );
  }

  Widget _buildStudentView(String? email) {
    return Column(
      children: [
        // Display signed-up classes
        Expanded(
          flex: 1,
          child: _buildSignedUpClasses(email),
        ),
        Divider(),
        // Display class search and sign-up
        Expanded(
          flex: 2,
          child: _buildStudentClassSearch(),
        ),
      ],
    );
  }

  // Method to build the signed-up classes section
  Widget _buildSignedUpClasses(String? email) {
    if (email == null) {
      return Center(child: Text('User email not found.'));
    }

    // Initialize the ClassSearch instance
    final classSearch = ClassSearch();

    return FutureBuilder<List<String>>(
      // Use the new method to fetch enrolled class IDs
      future: classSearch.getEnrolledClassIds(email),
      builder: (context, enrolledSnapshot) {
        if (!enrolledSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final enrolledClassIds = enrolledSnapshot.data!;

        if (enrolledClassIds.isEmpty) {
          return Center(child: Text('You have not signed up for any classes.'));
        }

        return FutureBuilder<QuerySnapshot>(
          // Fetch details for all enrolled classes
          future: FirebaseFirestore.instance.collection('classes').get(),
          builder: (context, classSnapshot) {
            if (!classSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final classDocs = classSnapshot.data!.docs;
            final enrolledClasses = classDocs
                .where((doc) => enrolledClassIds.contains(doc.id))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Your Classes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: enrolledClasses.map((doc) {
                      final classData = doc.data() as Map<String, dynamic>;
                      final courseCode =
                          classData['courseCode'] ?? 'Unknown Code';
                      final courseName =
                          classData['courseName'] ?? 'Unknown Name';
                      final userEmail =
                          classData['userEmail'] ?? 'Unknown Email';

                      return ListTile(
                        title: Text('$courseCode - $courseName'),
                        subtitle: Text('By $userEmail'),
                        trailing: ElevatedButton(
                          child: Text('Leave Class'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white),
                          onPressed: () => _unSignUpFromClass(doc.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to get enrolled classes
  Future<List<Map<String, dynamic>>> _getEnrolledClasses(
      List<QueryDocumentSnapshot> classDocs, String email) async {
    final enrolledClasses = <Map<String, dynamic>>[];

    for (var doc in classDocs) {
      final classData = doc.data() as Map<String, dynamic>;
      final classId = doc.id;

      try {
        // Check if the student is in the 'students' subcollection
        final studentDocRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('students')
            .doc(email);

        final docSnapshot = await studentDocRef.get();
        if (docSnapshot.exists) {
          enrolledClasses.add({
            'classId': classId,
            'classData': classData,
          });
        }
      } catch (e) {
        print('Error checking enrollment for class $classId: $e');
      }
    }

    return enrolledClasses;
  }

  // Method to build the class search and sign-up interface
  Widget _buildStudentClassSearch() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Search and Sign Up for Classes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _buildClassList(),
        ),
      ],
    );
  }

  // Method to build the class list based on filters
  Widget _buildClassList() {
    Query classesQuery = FirebaseFirestore.instance.collection('classes');

    // Since Firestore doesn't support full text search, fetch all and filter locally
    return FutureBuilder<QuerySnapshot>(
      future: classesQuery.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> classes = snapshot.data!.docs;

        // Apply local filtering for partial matches
        classes = classes.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final courseCode = data['courseCode']?.toString().toLowerCase() ?? '';
          final courseName = data['courseName']?.toString().toLowerCase() ?? '';
          final userEmail = data['userEmail']?.toString().toLowerCase() ?? '';

          final courseCodeMatch = courseCodeFilter == null ||
              courseCode.contains(courseCodeFilter!.toLowerCase());
          final courseNameMatch = courseNameFilter == null ||
              courseName.contains(courseNameFilter!.toLowerCase());
          final userEmailMatch = userEmailFilter == null ||
              userEmail.contains(userEmailFilter!.toLowerCase());

          return courseCodeMatch && courseNameMatch && userEmailMatch;
        }).toList();

        if (classes.isEmpty) {
          return Center(child: Text('No classes found.'));
        }

        return ListView(
          children: classes.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final classId = doc.id;
            final courseCode = data['courseCode'] ?? 'Unknown Code';
            final courseName = data['courseName'] ?? 'Unknown Name';
            final userEmail = data['userEmail'] ?? 'Unknown Email';

            return ListTile(
              title: Text('$courseCode - $courseName'),
              subtitle: Text('By $userEmail'),
              trailing: ElevatedButton(
                child: Text('Sign Up'),
                onPressed: () => _signUpForClass(classId),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Method to handle student sign-up for a class
  void _signUpForClass(String classId) async {
    final userService = UserService();
    final String? email = userService.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User email not found. Please log in again.')),
      );
      return;
    }

    final studentData = {
      'email': email,
      'isTA': false,
    };

    try {
      final studentDocRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(email);

      // Check if the student is already signed up
      final docSnapshot = await studentDocRef.get();
      if (docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already signed up for this class.')),
        );
        return;
      }

      // Add the student's information to the 'students' subcollection
      await studentDocRef.set(studentData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully signed up for the class!')),
      );

      // Refresh the view to show the new class in the signed-up section
      setState(() {});
    } catch (e) {
      print('Error signing up for class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign up for the class.')),
      );
    }
  }

  // *** New Method to handle student un-sign-up from a class ***
  void _unSignUpFromClass(String classId) async {
    final userService = UserService();
    final String? email = userService.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User email not found. Please log in again.')),
      );
      return;
    }

    try {
      final studentDocRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(email);

      // Check if the student is signed up
      final docSnapshot = await studentDocRef.get();
      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are not signed up for this class.')),
        );
        return;
      }

      // Remove the student's information from the 'students' subcollection
      await studentDocRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have left the class.')),
      );

      // Refresh the view to remove the class from the signed-up section
      setState(() {});
    } catch (e) {
      print('Error leaving the class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave the class.')),
      );
    }
  }

  // Method to show the filter window
  void _showFilterWindow(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Filter Classes"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Course Code'),
                  onChanged: (value) {
                    courseCodeFilter = value.trim();
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Course Name'),
                  onChanged: (value) {
                    courseNameFilter = value.trim();
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: "Professor's Email"),
                  onChanged: (value) {
                    userEmailFilter = value.trim();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Apply filters and refresh the class list
                setState(() {});
                Navigator.of(context).pop();
              },
              child: Text('Apply'),
            ),
            TextButton(
              onPressed: () {
                // Reset filters and refresh the class list
                setState(() {
                  courseCodeFilter = null;
                  courseNameFilter = null;
                  userEmailFilter = null;
                });
                Navigator.of(context).pop();
              },
              child: Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  // Existing method to open add class dialog for teachers
  void _openAddClass(BuildContext context) {
    final courseCodeController = TextEditingController();
    final courseNameController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Class"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: courseCodeController,
                  decoration: InputDecoration(labelText: 'Course Code'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: courseNameController,
                  decoration: InputDecoration(labelText: 'Course Name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final courseCode = courseCodeController.text.trim();
                  final courseName = courseNameController.text.trim();
                  final userEmail = UserService().email;

                  await FirebaseFirestore.instance.collection('classes').add({
                    'courseCode': courseCode,
                    'courseName': courseName,
                    'userEmail': userEmail,
                  });

                  Navigator.of(context).pop();
                },
                child: Text('Submit'),
              ),
            ],
          );
        });
  }
}

// Existing ClassListView for teachers
class ClassListView extends StatelessWidget {
  final List<String> classIds;

  ClassListView({required this.classIds});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: classIds.length,
      itemBuilder: (context, index) {
        final classId = classIds[index];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('classes')
              .doc(classId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                title: Text('Loading...'),
              );
            } else if (snapshot.hasError) {
              return ListTile(
                title: Text('Error loading class'),
              );
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return ListTile(
                title: Text('Class not found'),
              );
            } else {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final courseCode = data['courseCode'] ?? 'Unknown Code';
              final courseName = data['courseName'] ?? 'Unknown Name';

              return ListTile(
                title: Text(courseName),
                subtitle: Text('Code: $courseCode'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteClass(context, classId),
                ),
                onTap: () {
                  // Navigate to class details or perform another action
                },
              );
            }
          },
        );
      },
    );
  }

  // Method to delete a class
  void _deleteClass(BuildContext context, String classId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Class deleted successfully.')),
      );
    } catch (e) {
      print('Error deleting class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete the class.')),
      );
    }
  }
}
