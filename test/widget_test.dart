import 'package:flutter_test/flutter_test.dart';
import 'package:groupflow/core/theme/app_theme.dart';

void main() {
  test('GroupFlow themes use Material 3 and an indigo primary color', () {
    final theme = AppTheme.light();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppTheme.indigo);
  });
}
