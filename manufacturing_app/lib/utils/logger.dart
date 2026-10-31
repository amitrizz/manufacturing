import 'package:logger/logger.dart' as log;

class Logger {
  static late log.Logger _instance;
  static log.Logger get instance => _instance;
  
  static void init() {
    _instance = log.Logger(
      printer: log.PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: log.DateTimeFormat.dateAndTime,
      ),
      level: log.Level.debug,
    );
  }
  
  void d(dynamic message) => _instance.d(message);
  void i(dynamic message) => _instance.i(message);
  void w(dynamic message) => _instance.w(message);
  void e(dynamic message, {dynamic error, StackTrace? stackTrace}) => _instance.e(message, error: error, stackTrace: stackTrace);
  void v(dynamic message) => _instance.t(message);
}