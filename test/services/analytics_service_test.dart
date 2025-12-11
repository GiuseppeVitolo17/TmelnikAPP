import 'package:flutter_test/flutter_test.dart';
import 'package:tmelnik_app/services/analytics_service.dart';

void main() {
  group('AnalyticsService Tests', () {
    test('AnalyticsService should be a singleton', () {
      final instance1 = AnalyticsService();
      final instance2 = AnalyticsService();
      
      expect(instance1, equals(instance2));
    });

    test('AnalyticsService should initialize without errors', () async {
      final service = AnalyticsService();
      
      // Should not throw
      await service.initialize();
      
      expect(service.analytics, isNotNull);
    });

    test('logEvent should handle null parameters', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw
      await service.logEvent('test_event');
    });

    test('logEvent should handle parameters', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw
      await service.logEvent('test_event', parameters: {
        'param1': 'value1',
        'param2': 123,
      });
    });

    test('logLogin should work', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw
      await service.logLogin(loginMethod: 'google');
    });

    test('logSignUp should work', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw
      await service.logSignUp(signUpMethod: 'email');
    });

    test('logProjectView should work', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw
      await service.logProjectView('project-123', 'Test Project');
    });

    test('logProjectApplication should work', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw
      await service.logProjectApplication('project-123', 'Test Project', 'ngo-123');
    });

    test('setUserId should work', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw
      await service.setUserId('user-123');
      await service.setUserId(null);
    });

    test('setUserProperty should work', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw
      await service.setUserProperty('test_property', 'test_value');
      await service.setUserProperty('test_property', null);
    });
  });
}

