import 'package:flutter/material.dart';
import '../widgets/full_calendar.dart';
import '../widgets/memo_widget.dart';
import '../widgets/friend_list.dart';

class ExpandedCalendarScreen extends StatefulWidget {
  final DateTime selectedDate;

  ExpandedCalendarScreen({required this.selectedDate});

  @override
  _ExpandedCalendarScreenState createState() => _ExpandedCalendarScreenState();
}

class _ExpandedCalendarScreenState extends State<ExpandedCalendarScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.selectedDate.toString().split(' ')[0]}')),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FullCalendar(selectedDate: widget.selectedDate, isExpanded: true),
              ),
              Expanded(
                flex: 1,
                child: MemoWidget(date: widget.selectedDate),
              ),
            ],
          ),
          Expanded(
            child: FriendList(),
          ),
        ],
      ),
    );
  }
}