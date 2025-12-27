import 'package:change_project_name/change_project_name.dart';
import 'package:test/test.dart';

void main() {
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
}
