import 'package:flutter_test/flutter_test.dart';
import 'package:tmelnik_app/services/analytics_service.dart';

void main() {
  group('AnalyticsService Tests', () {
    test('AnalyticsService should be a singleton', () {
      final instance1 = AnalyticsService();
      final instance2 = AnalyticsService();
      
      expect(instance1, equals(instance2));
    });

    test('AnalyticsService should handle initialization gracefully', () async {
      final service = AnalyticsService();
      
      // Should not throw even without Firebase initialized
      // (it will log an error but not crash)
      await service.initialize();
      
      // Service should still be available even if Firebase isn't initialized in tests
      expect(service, isNotNull);
    });

    test('logEvent should handle null parameters gracefully', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw (handles Firebase not initialized gracefully)
      await service.logEvent('test_event');
    });

    test('logEvent should handle parameters gracefully', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw (handles Firebase not initialized gracefully)
      await service.logEvent('test_event', parameters: {
        'param1': 'value1',
        'param2': 123,
      });
    });

    test('logLogin should handle gracefully without Firebase', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw (handles Firebase not initialized gracefully)
      await service.logLogin(loginMethod: 'google');
    });

    test('logSignUp should handle gracefully without Firebase', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw (handles Firebase not initialized gracefully)
      await service.logSignUp(signUpMethod: 'email');
    });

    test('logProjectView should handle gracefully without Firebase', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw (handles Firebase not initialized gracefully)
      await service.logProjectView('project-123', 'Test Project');
    });

    test('logProjectApplication should handle gracefully without Firebase', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw (handles Firebase not initialized gracefully)
      await service.logProjectApplication('project-123', 'Test Project', 'ngo-123');
    });

    test('setUserId should handle gracefully without Firebase', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw (handles Firebase not initialized gracefully)
      await service.setUserId('user-123');
      await service.setUserId(null);
    });

    test('setUserProperty should handle gracefully without Firebase', () async {
      final service = AnalyticsService();
      await service.initialize();
      
      // Should not throw (handles Firebase not initialized gracefully)
      await service.setUserProperty('test_property', 'test_value');
      await service.setUserProperty('test_property', null);
    });
  });
}

