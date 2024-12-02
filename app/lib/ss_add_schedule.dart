import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation.dart';
import 'user_service.dart';
import 'class_search.dart';

// Todo and add class functionallity

class ActionPage extends StatefulWidget {
  @override
  Action createState() => Action();
}

class Action extends State<ActionPage> {
  List<Map<String, String>> classList = [];
  String? selectedClassId;
  final ClassSearch classSearch = ClassSearch();

  TextEditingController nameController = TextEditingController();

  final GlobalKey<_TypeSelect> _typeSelectorKey = GlobalKey<_TypeSelect>();

  List<bool> isSelected = List.generate(7, (_) => false);
  List<String> days = ["S", "M", "T", "W", "R", "F", "S"];

  final GlobalKey<_DateSelect> _dateSelectorKey = GlobalKey<_DateSelect>();

  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final userEmail = UserService().email; // Get the user's email
    if (userEmail != null) {
      _fetchClasses(userEmail);
    }
  }

  Future<void> _fetchClasses(String email) async {
    try {
      List<String> classIds =
          await ClassSearch().getClassDocumentIdsByEmail(email);

      List<Map<String, String>> fetchedClasses = [];

      for (String id in classIds) {
        DocumentSnapshot classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(id)
            .get();
        final data = classDoc.data() as Map<String, dynamic>;
        final courseCode = data['courseCode'] ?? 'Unknown';
        final courseName = data['courseName'] ?? 'Unnamed';

        fetchedClasses.add({
          'id': id,
          'display': '$courseCode - $courseName',
        });
      }

      setState(() {
        classList = fetchedClasses;
      });
    } catch (e) {
      print('Error fetching classes: $e');
    }
  }

  // start time picker
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  // end time picker
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  // start date picker
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _startDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // end date picker
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _endDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 16),
                Text('Select Class'),
                classList.isEmpty
                    ? Text('No classes available.')
                    : DropdownButton<String>(
                        isExpanded: true,
                        value: selectedClassId,
                        hint: Text('Choose a class'),
                        items: classList.map((classData) {
                          return DropdownMenuItem<String>(
                            value: classData['id'],
                            child: Text(classData['display']!),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedClassId = newValue;
                          });
                        },
                      ),
                SizedBox(height: 16),
                SizedBox(height: 16),
                Text('Select Type'),
                SizedBox(height: 16),
                TypeSelector(
                  key: _typeSelectorKey,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Activity Name'),
                ),
                SizedBox(height: 16),
                DateSelector(
                  key: _dateSelectorKey, // Assign the global key
                ),
                // time
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: ElevatedButton(
                          onPressed: () => _selectStartTime(context),
                          child: Text("Start Time")),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: ElevatedButton(
                          onPressed: () => _selectEndTime(context),
                          child: Text("End Time")),
                    )
                  ],
                ),
                // date
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                          onPressed: () => _selectStartDate(context),
                          child: Text("Start Date")),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                          onPressed: () => _selectEndDate(context),
                          child: Text("End Date")),
                    )
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    _createSchedule();
                    Navigator.pop(context);
                  },
                  child: Text('Create'),
                )
              ],
            )));
  }

  void _createSchedule() async {
    if (selectedClassId == null) {
      // Handle error - no class selected
      print("No class selected");
      return;
    }
    final selectedDays = _dateSelectorKey.currentState?.selection ?? {};
    final String? selectedType =
        _typeSelectorKey.currentState?.selection.first.name;

    CollectionReference collectionRef;
    collectionRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(selectedClassId)
        .collection('schedule');

    DateTime current = _startDate;
    while (current.isBefore(_endDate) || current.isAtSameMomentAs(_endDate)) {
      // Check if current date matches selected days of the week
      if (selectedDays.contains(_toDaysEnum(current.weekday))) {
        // Get start and end DateTime
        DateTime startDateTime = DateTime(current.year, current.month,
            current.day, _startTime.hour, _startTime.minute);
        DateTime endDateTime = DateTime(current.year, current.month,
            current.day, _endTime.hour, _endTime.minute);

        // Add a new document to the collection
        await collectionRef.add({
          'type': selectedType,
          'name': nameController.text,
          'startTime': startDateTime,
          'endTime': endDateTime,
        });
      }
      current = current.add(Duration(days: 1));
    }
  }
}

// Type selector
enum Type { Class, Disscussion, Office }

// Type selector Widget
class TypeSelector extends StatefulWidget {
  const TypeSelector({Key? key}) : super(key: key);

  @override
  State<TypeSelector> createState() => _TypeSelect();
}

class _TypeSelect extends State<TypeSelector> {
  Set<Type> selection = <Type>{Type.Class};

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      segments: const <ButtonSegment<Type>>[
        ButtonSegment(value: Type.Class, label: Text('Class')),
        ButtonSegment(value: Type.Disscussion, label: Text('Discussion')),
        ButtonSegment(value: Type.Office, label: Text('Office Hours')),
      ],
      selected: selection,
      onSelectionChanged: (Set<Type> newSelection) {
        setState(() {
          selection = newSelection;
        });
      },
      selectedIcon: Container(),
    );
  }
}

// Days selector
enum Days { Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday }

Days _toDaysEnum(int weekday) {
  return Days.values[weekday % 7];
}

// Days selector Widget
class DateSelector extends StatefulWidget {
  const DateSelector({Key? key}) : super(key: key);

  @override
  State<DateSelector> createState() => _DateSelect();
}

class _DateSelect extends State<DateSelector> {
  Set<Days> selection = <Days>{};

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      segments: const <ButtonSegment<Days>>[
        ButtonSegment(value: Days.Sunday, label: Text('S')),
        ButtonSegment(value: Days.Monday, label: Text('M')),
        ButtonSegment(value: Days.Tuesday, label: Text('T')),
        ButtonSegment(value: Days.Wednesday, label: Text('W')),
        ButtonSegment(value: Days.Thursday, label: Text('R')),
        ButtonSegment(value: Days.Friday, label: Text('F')),
        ButtonSegment(value: Days.Saturday, label: Text('S')),
      ],
      selected: selection,
      onSelectionChanged: (Set<Days> newSelection) {
        setState(() {
          selection = newSelection;
        });
      },
      multiSelectionEnabled: true,
      emptySelectionAllowed: true,
      selectedIcon: Container(),
    );
  }
}
