import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';

/// 写作模板管理页：列表 + 新建/编辑/删除 + 上移下移排序
class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.manageTemplates)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTemplateEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l.newTemplate),
      ),
      body: StreamBuilder<List<EntryTemplate>>(
        stream: appDb.watchEntryTemplates(),
        builder: (context, snap) {
          final templates = snap.data ?? const <EntryTemplate>[];
          if (templates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.templatesEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: templates.length,
                itemBuilder: (context, i) {
                  final t = templates[i];
                  final preview = t.content.trim();
                  return Card(
                    child: ListTile(
                      title: Text(t.name),
                      subtitle: preview.isEmpty
                          ? null
                          : Text(
                              preview,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () => showTemplateEditor(context, existing: t),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.keyboard_arrow_up),
                            tooltip: l.moveUp,
                            onPressed: i == 0
                                ? null
                                : () => appDb.moveEntryTemplate(t.id, -1),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            tooltip: l.moveDown,
                            onPressed: i == templates.length - 1
                                ? null
                                : () => appDb.moveEntryTemplate(t.id, 1),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline),
                            tooltip: l.delete,
                            onPressed: () => _confirmDelete(context, t),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, EntryTemplate t) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteTemplateTitle),
        content: Text(t.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) await appDb.deleteEntryTemplate(t.id);
  }
}

/// 新建/编辑模板对话框
Future<void> showTemplateEditor(
  BuildContext context, {
  EntryTemplate? existing,
}) async {
  final l = AppLocalizations.of(context)!;
  final isCreate = existing == null;
  final nameController = TextEditingController(text: existing?.name ?? '');
  final contentController =
      TextEditingController(text: existing?.content ?? '');
  String? nameError;
  String? contentError;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(isCreate ? l.newTemplate : l.editTemplate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: isCreate,
                decoration: InputDecoration(
                  labelText: l.templateName,
                  border: const OutlineInputBorder(),
                  errorText: nameError,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: l.templateContent,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  errorText: contentError,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.templateHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final content = contentController.text;
              setState(() {
                nameError = name.isEmpty ? l.templateNameEmpty : null;
                contentError =
                    content.trim().isEmpty ? l.templateContentEmpty : null;
              });
              if (nameError != null || contentError != null) return;
              Navigator.pop(context, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );

  if (ok == true) {
    final name = nameController.text.trim();
    final content = contentController.text.trim();
    if (existing == null) {
      await appDb.createEntryTemplate(name: name, content: content);
    } else {
      await appDb.updateEntryTemplate(existing.id, name: name, content: content);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.saved)));
    }
  }
  nameController.dispose();
  contentController.dispose();
}
