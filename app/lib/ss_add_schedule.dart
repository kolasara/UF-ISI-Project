import 'package:flutter/material.dart';
import 'navigation.dart';

// Todo and add class functionallity

class ActionPage extends StatefulWidget {
  @override
  Action createState() => Action();
}

class Action extends State<ActionPage> {
  TextEditingController classController = TextEditingController();

  List<bool> isSelected = List.generate(7, (_) => false);
  List<String> days = ["S", "M", "T", "W", "T", "F", "S"];

  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // start time picker
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _startTime
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  // end time picker
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _endTime
    );
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
        lastDate: DateTime(2101)
    );
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
        lastDate: DateTime(2101)
    );
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
              Text('Select Type'),
              SizedBox(height: 16),
              TypeSelector(),
              SizedBox(height: 16),
              TextField(
                controller: classController,
                decoration: InputDecoration(labelText: 'Activity Name'),
              ),
              SizedBox(height: 16),
              DateSelector(),
              // time
              SizedBox(height: 16),
              Row(
                children: <Widget>[
                  ElevatedButton(
                      onPressed: () => _selectStartTime(context),
                      child: Text("Start Time")
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => _selectEndTime(context),
                      child: Text("End Time")
                  ),
                ],
              ),
              // date
              Row(
                children: <Widget>[
                  ElevatedButton(
                      onPressed: () => _selectStartDate(context),
                      child: Text("Start Date")
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => _selectEndDate(context),
                      child: Text("End Date")
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: Text('Create'),
              )
            ],
          )
        )
    );
  }
}

// Type selector
enum Type {Class, Disscussion, Office}

// Type selector Widget
class TypeSelector extends StatefulWidget {

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
enum Days {Sunday, Monday, Tuesday, Wednsday, Thursday, Friday, Saturday}

// Days selector Widget
class DateSelector extends StatefulWidget {

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
          ButtonSegment(value: Days.Wednsday, label: Text('W')),
          ButtonSegment(value: Days.Thursday, label: Text('T')),
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