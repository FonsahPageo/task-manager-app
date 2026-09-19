import 'package:flutter/material.dart';
import '../models/models.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, this.onTap, this.onDelete});

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (task.status) {
      TaskStatus.todo => Colors.amber,
      TaskStatus.inProgress => Colors.lightBlue,
      TaskStatus.done => Colors.green,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        onTap: onTap,
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: (task.description == null || task.description!.isEmpty)
            ? null
            : Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
        leading: CircleAvatar(radius: 6, backgroundColor: color),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(task.status.label, style: theme.textTheme.labelSmall),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
