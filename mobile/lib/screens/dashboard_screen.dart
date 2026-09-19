import 'package:flutter/material.dart';

import '../models/models.dart';
import '../api/api_client.dart';
import '../widgets/task_tile.dart';
import '../widgets/task_editor.dart';
import 'auth_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  String? _errorString;
  TaskStatus? _statusFilter;

  bool _editorOpen = false;
  Task? _editing;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _openEditor({Task? task}) {
    setState(() {
      _editing = task;
      _editorOpen = true;
    });
  }

  Future<void> _reload() async {
    setState(() { _loading = true; _errorString = null; });
    try {
      final list = await widget.api.listTasks(status: _statusFilter?.apiValue);
      if (!mounted) return;
      setState(() { _tasks = list; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _errorString = e.message; _loading = false; });
    }
  }

  void _openCreate() => setState(() { _editing = null; _editorOpen = true; });
  void _openEdit(Task task) => setState(() { _editing = task; _editorOpen = true; });

  Future<void> _save(TaskDraft draft) async {
    Navigator.of(context).pop();
    setState(() { _editorOpen = false; _loading = true; });
    try {
      if (_editing == null) {
        await widget.api.createTask(draft);
      } else {
        await widget.api.updateTask(_editing!.id, draft);
      }
      await _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.api.deleteTask(task.id);
      await _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _logout() async {
    await widget.api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AuthScreen(api: widget.api)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(padding: const EdgeInsets.only(right: 6), child: _filterChip(null)),
                for (final s in TaskStatus.values)
                  Padding(padding: const EdgeInsets.only(right: 6), child: _filterChip(s)),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _filterChip(TaskStatus? s) {
    return ChoiceChip(
      label: Text(s?.label ?? 'All'),
      selected: _statusFilter == s,
      onSelected: (_) {
        setState(() => _statusFilter = s);
        _reload();
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorString != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_errorString!, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: _reload, child: const Text('Retry')),
        ]),
      );
    }
    if (_tasks.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 8),
          Text('No tasks yet. Tap + to add one.'),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _tasks.length,
        itemBuilder: (context, i) => TaskTile(
          task: _tasks[i],
          onTap: () => _openEdit(_tasks[i]),
          onDelete: () => _confirmDelete(_tasks[i]),
        ),
      ),
    );
  }
}

