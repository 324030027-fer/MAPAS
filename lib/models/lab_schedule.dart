class LabSchedule {
  final String labName;
  final List<ScheduleEntry> entries;

  LabSchedule({required this.labName, required this.entries});

  LabSchedule copyWith({String? labName, List<ScheduleEntry>? entries}) {
    return LabSchedule(
      labName: labName ?? this.labName,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() => {
        'labName': labName,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory LabSchedule.fromJson(Map<String, dynamic> json) {
    return LabSchedule(
      labName: json['labName'] as String,
      entries: (json['entries'] as List)
          .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ScheduleEntry {
  final String id;
  final String day;
  final String startTime;
  final String endTime;
  final String subject;
  final String group;
  final String teacher;

  ScheduleEntry({
    String? id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.group,
    required this.teacher,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  ScheduleEntry copyWith({
    String? day,
    String? startTime,
    String? endTime,
    String? subject,
    String? group,
    String? teacher,
  }) {
    return ScheduleEntry(
      id: id,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subject: subject ?? this.subject,
      group: group ?? this.group,
      teacher: teacher ?? this.teacher,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'group': group,
        'teacher': teacher,
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id'] as String?,
      day: json['day'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      subject: json['subject'] as String,
      group: json['group'] as String? ?? '',
      teacher: json['teacher'] as String,
    );
  }
}
