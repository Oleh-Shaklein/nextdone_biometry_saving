import 'package:flutter/material.dart';

Future<void> showDoneDialog(BuildContext context, VoidCallback onArchive, VoidCallback onDelete) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Ви виконали завдання!'),
      content: const Text('Що зробити із завданням?'),
      actions: [
        TextButton(
          onPressed: onDelete,
          child: const Text('Видалити'),
        ),
        TextButton(
          onPressed: onArchive,
          child: const Text('Заархівувати'),
        ),
      ],
    ),
  );
}