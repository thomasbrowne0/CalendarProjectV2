import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/theme_provider.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// This class centralizes all app-wide providers used in the app.
/// It returns a list of providers for use in the main app widget tree.
class ProviderConfig {

  /// Returns a list of providers to be injected into the widget tree.
  static List<SingleChildWidget> getProviders() {
    return [

      /// Provides the ThemeProvider for handling theme switching (light/dark).
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
      ),

      /// Provides an instance of ApiService, responsible for REST API calls.
      Provider<ApiService>(
        create: (_) => ApiService(),
      ),

      /// Provides a singleton instance of WebSocketService that depends on ApiService.
      /// Automatically disposes the WebSocket connection when not needed.
      Provider<WebSocketService>(
        create: (context) => WebSocketService(
          Provider.of<ApiService>(context, listen: false),
        ),
        dispose: (_, service) => service.dispose(),
      ),

      /// Provides AuthProvider that depends on ApiService and WebSocketService.
      /// Updates when either dependency changes.
      ChangeNotifierProxyProvider2<ApiService, WebSocketService, AuthProvider>(
        create: (_) => AuthProvider(null, null),
        update: (
            context,
            apiService,
            webSocketService,
            previousAuthProvider,
            ) =>
            AuthProvider(
              apiService,
              webSocketService,
              previousAuthProvider: previousAuthProvider,
            ),
      ),

      /// Provides CompanyProvider which depends on ApiService, AuthProvider, and WebSocketService.
      /// This provider listens to changes in its three dependencies.
      ChangeNotifierProxyProvider3<ApiService, AuthProvider, WebSocketService, CompanyProvider>(
        create: (_) => CompanyProvider(null, null, null),
        update: (
            context,
            apiService,
            authProvider,
            webSocketService,
            _,
            ) =>
            CompanyProvider(
              apiService,
              authProvider,
              webSocketService,
            ),
      ),

      /// Provides CalendarProvider which depends on ApiService and AuthProvider.
      /// Updates when either dependency changes.
      ChangeNotifierProxyProvider2<ApiService, AuthProvider, CalendarProvider>(
        create: (_) => CalendarProvider(null, null),
        update: (
            context,
            apiService,
            authProvider,
            _,
            ) =>
            CalendarProvider(
              apiService,
              authProvider,
            ),
      ),
    ];
  }
}
