import 'dart:convert';
import 'dart:io';

/// Offline helper for cleaning exported report JSON after the Base64 migration.
///
/// Usage:
///   dart run tools/cleanup_broken_reports.dart input.json output.json
///
/// The script accepts either a JSON array of reports or a JSON object with a
/// top-level `reports` array. It repairs legacy fields where possible and
/// reports entries that still need manual attention.
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tools/cleanup_broken_reports.dart input.json output.json',
    );
    exitCode = 64;
    return;
  }

  final inputFile = File(args[0]);
  final outputFile = File(args[1]);

  if (!await inputFile.exists()) {
    stderr.writeln('Input file not found: ${inputFile.path}');
    exitCode = 66;
    return;
  }

  final raw = jsonDecode(await inputFile.readAsString());
  final reports = <Map<String, dynamic>>[];

  if (raw is List) {
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        reports.add(Map<String, dynamic>.from(item));
      }
    }
  } else if (raw is Map<String, dynamic>) {
    final list = raw['reports'];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          reports.add(Map<String, dynamic>.from(item));
        }
      }
    }
  } else {
    stderr.writeln('Unsupported JSON structure. Expected array or object.');
    exitCode = 65;
    return;
  }

  var repaired = 0;
  var broken = 0;

  for (final report in reports) {
    final photoBase64 = report['photo_base64']?.toString().trim() ?? '';
    final photoUrl = report['photo_url']?.toString().trim() ?? '';
    final legacyUrl = report['photoUrl']?.toString().trim() ?? '';

    if (photoBase64.isEmpty && photoUrl.isEmpty && legacyUrl.isNotEmpty) {
      report['photo_url'] = legacyUrl;
      report['photoUrl'] = legacyUrl;
      repaired++;
      continue;
    }

    if (photoBase64.isEmpty && photoUrl.isEmpty) {
      broken++;
    }
  }

  final output = {
    'reports': reports,
    'summary': {
      'total': reports.length,
      'repaired': repaired,
      'broken': broken,
    },
  };

  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(output),
  );

  stdout.writeln(
    'Processed ${reports.length} reports. Repaired: $repaired. Still broken: $broken.',
  );
  stdout.writeln('Wrote cleaned output to ${outputFile.path}');
}
