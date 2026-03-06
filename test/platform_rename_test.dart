import 'dart:io';
import 'package:change_project_name/change_project_name.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rename_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('Android renaming', () {
    test('getOldPackageName from build.gradle', () async {
      final appDir = Directory(p.join(tempDir.path, 'android/app'))..createSync(recursive: true);
      final gradleFile = File(p.join(appDir.path, 'build.gradle'));
      await gradleFile.writeAsString('''
android {
    defaultConfig {
        applicationId "com.old.package"
    }
}
''');

      final packageName = await getOldPackageName(tempDir);
      expect(packageName, equals('com.old.package'));
    });

    test('getOldPackageName from build.gradle.kts', () async {
      final appDir = Directory(p.join(tempDir.path, 'android/app'))..createSync(recursive: true);
      final gradleFile = File(p.join(appDir.path, 'build.gradle.kts'));
      await gradleFile.writeAsString('''
android {
    namespace = "com.old.namespace"
    defaultConfig {
        applicationId = "com.old.package"
    }
}
''');

      final packageName = await getOldPackageName(tempDir);
      // It should prefer applicationId if both exist in our current regex implementation
      expect(packageName, equals('com.old.package'));
    });

    test('updateAndroidAppName', () async {
      final manifestDir = Directory(p.join(tempDir.path, 'android/app/src/main'))..createSync(recursive: true);
      final manifestFile = File(p.join(manifestDir.path, 'AndroidManifest.xml'));
      await manifestFile.writeAsString('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="Old Name">
    </application>
</manifest>
''');

      await updateAndroidAppName(tempDir, 'New Name');

      final content = await manifestFile.readAsString();
      expect(content, contains('android:label="New Name"'));
    });

    test('updateAndroidPackageName and directory structure', () async {
      // Setup directory structure
      final sourceDir = Directory(p.join(tempDir.path, 'android/app/src/main/kotlin/com/old/app'))..createSync(recursive: true);
      final ktFile = File(p.join(sourceDir.path, 'MainActivity.kt'));
      await ktFile.writeAsString('package com.old.app\n\nclass MainActivity {}');

      final gradleFile = File(p.join(tempDir.path, 'android/app/build.gradle'))..createSync(recursive: true);
      await gradleFile.writeAsString('applicationId "com.old.app"');

      // Execute rename
      await updateAndroidPackageName(tempDir, 'com.old.app', 'com.new.name');

      // Verify gradle file
      expect(await gradleFile.readAsString(), contains('applicationId "com.new.name"'));

      // Verify directory structure
      final newSourceDir = Directory(p.join(tempDir.path, 'android/app/src/main/kotlin/com/new/name'));
      expect(newSourceDir.existsSync(), isTrue);
      expect(sourceDir.existsSync(), isFalse);

      // Verify file content
      final newKtFile = File(p.join(newSourceDir.path, 'MainActivity.kt'));
      expect(newKtFile.existsSync(), isTrue);
      expect(await newKtFile.readAsString(), contains('package com.new.name'));
    });
  });

  group('iOS renaming', () {
    test('updateIOSBundleId', () async {
      final xcodeDir = Directory(p.join(tempDir.path, 'ios/Runner.xcodeproj'))..createSync(recursive: true);
      final pbxprojFile = File(p.join(xcodeDir.path, 'project.pbxproj'));
      await pbxprojFile.writeAsString('''
PRODUCT_BUNDLE_IDENTIFIER = com.old.bundle;
PRODUCT_BUNDLE_IDENTIFIER = com.old.bundle;
''');

      await updateIOSBundleId(tempDir, 'com.new.bundle');

      final content = await pbxprojFile.readAsString();
      expect(content.contains('com.old.bundle'), isFalse);
      expect(content, contains('PRODUCT_BUNDLE_IDENTIFIER = com.new.bundle;'));
    });

    test('updateIOSAppName', () async {
      final runnerDir = Directory(p.join(tempDir.path, 'ios/Runner'))..createSync(recursive: true);
      final infoPlistFile = File(p.join(runnerDir.path, 'Info.plist'));
      await infoPlistFile.writeAsString('''
<dict>
	<key>CFBundleDisplayName</key>
	<string>Old Name</string>
	<key>CFBundleName</key>
	<string>old_name</string>
</dict>
''');

      await updateIOSAppName(tempDir, 'New Name');

      final content = await infoPlistFile.readAsString();
      expect(content, contains('<key>CFBundleDisplayName</key>\n\t<string>New Name</string>'));
      expect(content, contains('<key>CFBundleName</key>\n\t<string>New Name</string>'));
    });
  });

  group('Git integration', () {
    test('isGitRepository identifies repo', () async {
      // 1. Not a repo
      expect(await isGitRepository(tempDir), isFalse);

      // 2. Is a repo (mock .git folder)
      Directory(p.join(tempDir.path, '.git')).createSync();
      expect(await isGitRepository(tempDir), isTrue);
    });

    test('createGitCommit', () async {
      // Initialize real git repo for this test
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      
      // Configure git user for CI environments
      await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.name', 'Tester'], workingDirectory: tempDir.path);

      final testFile = File(p.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('hello');

      final success = await createGitCommit(tempDir, 'test commit');
      expect(success, isTrue);

      final logResult = await Process.run('git', ['log', '-1', '--pretty=%s'], workingDirectory: tempDir.path);
      expect(logResult.stdout.toString().trim(), equals('test commit'));
    });
  });
}
