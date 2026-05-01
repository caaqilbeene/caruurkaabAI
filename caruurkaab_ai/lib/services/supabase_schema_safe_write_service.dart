import 'package:supabase_flutter/supabase_flutter.dart';

class SchemaSafeWriteResult {
  final Set<String> removedColumns;
  final Map<String, dynamic> savedPayload;

  const SchemaSafeWriteResult({
    required this.removedColumns,
    required this.savedPayload,
  });
}

class SupabaseSchemaSafeWriteService {
  static Future<SchemaSafeWriteResult> insertWithFallback({
    required String table,
    required Map<String, dynamic> payload,
  }) {
    return _writeWithFallback(
      table: table,
      payload: payload,
      perform: (workingPayload) async {
        await Supabase.instance.client.from(table).insert(workingPayload);
      },
    );
  }

  static Future<SchemaSafeWriteResult> updateWithFallback({
    required String table,
    required Map<String, dynamic> payload,
    required String eqColumn,
    required dynamic eqValue,
  }) {
    return _writeWithFallback(
      table: table,
      payload: payload,
      perform: (workingPayload) async {
        await Supabase.instance.client
            .from(table)
            .update(workingPayload)
            .eq(eqColumn, eqValue);
      },
    );
  }

  static Future<SchemaSafeWriteResult> _writeWithFallback({
    required String table,
    required Map<String, dynamic> payload,
    required Future<void> Function(Map<String, dynamic> workingPayload) perform,
  }) async {
    final workingPayload = Map<String, dynamic>.from(payload);
    final removedColumns = <String>{};

    while (true) {
      try {
        await perform(workingPayload);
        return SchemaSafeWriteResult(
          removedColumns: removedColumns,
          savedPayload: Map<String, dynamic>.from(workingPayload),
        );
      } on PostgrestException catch (e) {
        final missingColumn = extractMissingColumn(e, table: table);
        final canRecover =
            isMissingColumnError(e) &&
            missingColumn != null &&
            workingPayload.containsKey(missingColumn) &&
            !removedColumns.contains(missingColumn);
        if (!canRecover) rethrow;
        workingPayload.remove(missingColumn);
        removedColumns.add(missingColumn);
      }
    }
  }

  static bool isMissingColumnError(PostgrestException e) {
    if (e.code == 'PGRST204' || e.code == '42703') return true;
    final combined = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return combined.contains('column') && combined.contains('does not exist');
  }

  static String? extractMissingColumn(PostgrestException e, {String? table}) {
    final combined = '${e.message} ${e.details} ${e.hint}';

    if (table != null && table.trim().isNotEmpty) {
      final pgrstByTable = RegExp(
        "Could not find the '([^']+)' column of '${RegExp.escape(table)}'",
        caseSensitive: false,
      ).firstMatch(combined);
      if (pgrstByTable != null) return pgrstByTable.group(1);

      final pgByTable = RegExp(
        'column\\s+${RegExp.escape(table)}\\.([a-zA-Z0-9_]+)\\s+does not exist',
        caseSensitive: false,
      ).firstMatch(combined);
      if (pgByTable != null) return pgByTable.group(1);
    }

    final pgrstGeneric = RegExp(
      r"Could not find the '([^']+)' column",
      caseSensitive: false,
    ).firstMatch(combined);
    if (pgrstGeneric != null) return pgrstGeneric.group(1);

    final pgGeneric = RegExp(
      r'column\s+[a-zA-Z0-9_]+\.(?:\"?)([a-zA-Z0-9_]+)(?:\"?)\s+does not exist',
      caseSensitive: false,
    ).firstMatch(combined);
    return pgGeneric?.group(1);
  }

  static String friendlyError(Object? error) {
    if (error == null) return 'Unknown database error.';
    if (error is PostgrestException) {
      final parts = <String>[];
      final message = error.message.trim();
      final details = (error.details ?? '').toString().trim();
      final hint = (error.hint ?? '').toString().trim();
      final code = (error.code ?? '').toString().trim();
      if (message.isNotEmpty) parts.add(message);
      if (details.isNotEmpty) parts.add(details);
      if (hint.isNotEmpty) parts.add('Hint: $hint');
      if (code.isNotEmpty) parts.add('Code: $code');
      if (parts.isNotEmpty) return parts.join(' | ');
    }
    return error.toString();
  }
}
