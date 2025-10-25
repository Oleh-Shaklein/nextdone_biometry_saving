// import 'task.dart';

// class ChecklistItem {
//   final String id;
//   final String text;
//   bool isChecked;

//   ChecklistItem({
//     required this.id,
//     required this.text,
//     this.isChecked = false,
//   });

//   ChecklistItem copyWith({
//     String? id,
//     String? text,
//     bool? isChecked,
//   }) {
//     return ChecklistItem(
//       id: id ?? this.id,
//       text: text ?? this.text,
//       isChecked: isChecked ?? this.isChecked,
//     );
//   }
// }

// class Checklist extends Task {
//   final List<ChecklistItem> items;

//   Checklist({
//     required String id,
//     required String title,
//     required this.items,
//     required DateTime date,
//   }) : super(
//           id: id,
//           title: title,
//           date: date,
//         );

//   Checklist copyWith({
//     String? id,
//     String? title,
//     List<ChecklistItem>? items,
//   }) {
//     return Checklist(
//       id: id ?? this.id,
//       title: title ?? this.title,
//       items: items ?? this.items,
//       date: date,
//     );
//   }

//   @override
//   String get type => 'checklist';
// }
