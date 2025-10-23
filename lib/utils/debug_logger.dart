// Export the appropriate implementation based on platform
export 'debug_logger_web.dart' if (dart.library.io) 'debug_logger_mobile.dart';

