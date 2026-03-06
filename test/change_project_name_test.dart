import 'dart:convert';
import 'dart:io';
import 'package:change_project_name/change_project_name.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectConfig', () {
    test('CPN-004: Parse from JSON', () {
      final json = {
        "name": "new_name",
        "app_name": "New App",
        "package_name": "com.example.new",
        "custom_replacements": {
          "Old": "New"
        },
        "options": {
          "backup": false,
          "commit": true,
          "refresh": false
        }
      };

      final config = ProjectConfig.fromJson(json);

      expect(config.name, equals('new_name'));
      expect(config.appName, equals('New App'));
      expect(config.packageName, equals('com.example.new'));
      expect(config.customReplacements, equals({'Old': 'New'}));
      expect(config.backup, isFalse);
      expect(config.commit, isTrue);
      expect(config.refresh, isFalse);
    });

    test('CPN-004: Partial JSON', () {
      final json = {
        "name": "only_name"
      };

      final config = ProjectConfig.fromJson(json);

      expect(config.name, equals('only_name'));
      expect(config.appName, isNull);
      expect(config.customReplacements, isEmpty);
      expect(config.backup, isNull);
    });

    test('CPN-004: Generate template', () async {
      final tempDir = await Directory.systemTemp.createTemp('cpn_config_test_');
      final configPath = '${tempDir.path}/rename.json';
      await ProjectConfig.generateTemplate(configPath);

      final file = File(configPath);
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      final json = jsonDecode(content);
      expect(json['name'], equals('new_project_name'));
      expect(json['options']['backup'], isTrue);

      await tempDir.delete(recursive: true);
    });
  });

  group('isValidPackageName', () {
    test('valid names', () {
      expect(isValidPackageName('myapp'), isTrue);
      expect(isValidPackageName('my_app'), isTrue);
      expect(isValidPackageName('my_app_v2'), isTrue);
      expect(isValidPackageName('a'), isTrue);
    });

    test('invalid names', () {
      expect(isValidPackageName('MyApp'), isFalse); // Uppercase
      expect(isValidPackageName('my-app'), isFalse); // Hyphen
      expect(isValidPackageName('1app'), isFalse); // Starts with number
      expect(isValidPackageName('_app'), isFalse); // Starts with underscore (Wait, is underscore allowed at start?)
      // The regex was r'^[a-z][a-z0-9_]*$'
      // So it must start with a letter.
    });

    test('names starting with underscore', () {
        // The regex `r'^[a-z][a-z0-9_]*$'` enforces starting with a lowercase letter.
        // Standard Dart package convention says "all lowercase, with underscores to separate words".
        // It generally implies starting with a letter.
        expect(isValidPackageName('_private'), isFalse); 
    });
  });

  group('normalizeName', () {
    test('converts spaces to underscores', () {
      expect(normalizeName('my app'), equals('my_app'));
    });

    test('converts to lowercase', () {
      expect(normalizeName('MyApp'), equals('my_app'));
    });

    test('removes special characters', () {
      expect(normalizeName('my-app!'), equals('my_app'));
    });

    test('trims underscores from ends', () {
      expect(normalizeName('  _my_app_  '), equals('my_app'));
    });

    test('handles multiple separators', () {
      expect(normalizeName('my---app'), equals('my_app'));
      expect(normalizeName('my   app'), equals('my_app'));
    });
  });

  group('ProjectRenamer Integration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cpn_test_');

      // Create a mock Flutter project
      await File('${tempDir.path}/pubspec.yaml').writeAsString('name: old_name\nversion: 1.0.0\n');
      await Directory('${tempDir.path}/lib').create();
      await File('${tempDir.path}/lib/main.dart').writeAsString('import "package:old_name/old_name.dart";\n// CustomReplaceTag\n');
      await Directory('${tempDir.path}/android/app').create(recursive: true);
      await File('${tempDir.path}/android/app/build.gradle').writeAsString('applicationId "com.example.old_name"\n');
      await Directory('${tempDir.path}/ios/Runner').create(recursive: true);
      await File('${tempDir.path}/ios/Runner/Info.plist').writeAsString('<key>CFBundleDisplayName</key><string>Old Name</string>\n');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('CPN-003: Backup creation', () async {
      final renamer = ProjectRenamer(
        projectDir: tempDir,
        shouldBackup: true,
        shouldRefresh: false, // Don't run flutter commands
      );

      await renamer.rename('old_name', 'new_name');

      // Check if backup exists
      final backupDirs = tempDir.listSync().whereType<Directory>().where((d) => d.path.contains('.cpn_backup_'));
      expect(backupDirs.length, equals(1));

      final backupDir = backupDirs.first;
      expect(await File('${backupDir.path}/pubspec.yaml').exists(), isTrue);
      expect(await Directory('${backupDir.path}/lib').exists(), isTrue);
      expect(await File('${backupDir.path}/lib/main.dart').exists(), isTrue);

      final backupPubspec = await File('${backupDir.path}/pubspec.yaml').readAsString();
      expect(backupPubspec, contains('name: old_name'));
    });

    test('CPN-003: Custom search and replace', () async {
      final renamer = ProjectRenamer(
        projectDir: tempDir,
        shouldBackup: false,
        shouldRefresh: false,
        customReplacements: {
          'CustomReplaceTag': 'ReplacedSuccess',
          'Old Name': 'New Display Name',
        },
      );

      await renamer.rename('old_name', 'new_name', newAppName: 'New Display Name');

      // Check main.dart
      final mainContent = await File('${tempDir.path}/lib/main.dart').readAsString();
      expect(mainContent, contains('ReplacedSuccess'));
      expect(mainContent, isNot(contains('CustomReplaceTag')));

      // Check Info.plist
      final infoPlist = await File('${tempDir.path}/ios/Runner/Info.plist').readAsString();
      expect(infoPlist, contains('New Display Name'));
    });
  });
}

