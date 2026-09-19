import 'package:flutter/material.dart';
import '../models/models.dart';

/// Bottom-sheet form used for both creating and editing a task.
class TaskEditor extends StatefulWidget {
  const TaskEditor({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  final Task? initial;
  final String submitLabel;
  final ValueChanged<TaskDraft> onSubmit;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _description = TextEditingController(text: widget.initial?.description ?? '');
  late TaskStatus _status = widget.initial?.status ?? TaskStatus.todo;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required.')));
      return;
    }
    widget.onSubmit(TaskDraft(
      title: _title.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      status: _status,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.initial == null ? 'New task' : 'Edit task',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SegmentedButton<TaskStatus>(
            segments: const [
              ButtonSegment(value: TaskStatus.todo, label: Text('To Do')),
              ButtonSegment(value: TaskStatus.inProgress, label: Text('In Progress')),
              ButtonSegment(value: TaskStatus.done, label: Text('Done')),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
        ],
      ),
    );
  }
}
