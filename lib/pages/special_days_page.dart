import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';

/// 特殊日子（生日、纪念日等）：
/// 以带 annualDate（MM-DD）的思绪记录——万物皆思绪，每年同日循环展示
class SpecialDaysPage extends StatelessWidget {
  const SpecialDaysPage({super.key});

  Future<void> _add(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    var picked = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.addSpecialDay),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration:
                    InputDecoration(labelText: l.specialDayNameHint),
                onSubmitted: (_) => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(l.specialDayDate),
                trailing: Text(DateFormat.yMMMd(
                        Localizations.localeOf(context).toString())
                    .format(picked)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: picked,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => picked = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.confirm),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await appDb.insertThought(
      content: name,
      day: AppDatabase.today(),
      annualDate:
          '${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
    );
  }

  /// MM-DD → 本地化短日期（如 10月1日）
  String _formatDate(String md, String locale) {
    final m = int.parse(md.substring(0, 2));
    final d = int.parse(md.substring(3, 5));
    return DateFormat.MMMd(locale).format(DateTime(2024, m, d));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(title: Text(l.specialDaysTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context),
        tooltip: l.addSpecialDay,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ThoughtEntry>>(
        stream: appDb.watchAnnualEvents(),
        builder: (context, snap) {
          final events = snap.data ?? const <ThoughtEntry>[];
          if (events.isEmpty) {
            return Center(
              child: Text(
                l.specialDayEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l.specialDaysHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final e in events)
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.celebration_outlined,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    title: Text(e.content),
                    subtitle: Text(_formatDate(e.annualDate!, locale)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => confirmDelete(context, e),
                    ),
                    onTap: () => showEntryEditor(context, existing: e),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
