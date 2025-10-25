import 'package:flutter/material.dart';
import '../../models/task.dart';

class ChecklistItemWidget extends StatelessWidget {
  final ChecklistItem item;
  final Function(bool?)? onChanged;
  final Function()? onAddSub;
  final Function()? onDeadline;
  final Function()? onMenu;

  const ChecklistItemWidget({
    required this.item,
    this.onChanged,
    this.onAddSub,
    this.onDeadline,
    this.onMenu,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Checkbox(
            value: item.isChecked,
            onChanged: onChanged,
          ),
          title: Text(
            item.text,
            style: TextStyle(decoration: item.isChecked ? TextDecoration.lineThrough : null),
          ),
          subtitle: item.deadline != null
              ? Text('Дедлайн: ${item.deadline!.day}.${item.deadline!.month}.${item.deadline!.year}',
              style: const TextStyle(fontSize: 13, color: Colors.redAccent))
              : null,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_sub') onAddSub?.call();
              if (value == 'deadline') onDeadline?.call();
              if (value == 'menu') onMenu?.call();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'add_sub', child: Text('Додати підпункт')),
              const PopupMenuItem(value: 'deadline', child: Text('Дедлайн')),
              const PopupMenuItem(value: 'menu', child: Text('Ще...')),
            ],
          ),
        ),
        if (item.subItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              children: item.subItems
                  .map((sub) => ChecklistItemWidget(
                item: sub,
                onChanged: onChanged,
                onAddSub: onAddSub,
                onDeadline: onDeadline,
                onMenu: onMenu,
              ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}