import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/services/websocket_service.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/theme_provider.dart';
import 'package:provider/single_child_widget.dart';

class ProviderConfig {
  static List<SingleChildWidget> getProviders() {
    return [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      Provider<ApiService>(create: (_) => ApiService()),
      Provider<WebSocketService>(
        create: (context) => WebSocketService(
          Provider.of<ApiService>(context, listen: false),
        ),
        dispose: (_, service) => service.dispose(),
      ),
      ChangeNotifierProxyProvider2<ApiService, WebSocketService, AuthProvider>(
        create: (_) => AuthProvider(null, null),
        update: (context, apiService, webSocketService, previousAuthProvider) =>
            AuthProvider(
              apiService,
              webSocketService,
              previousAuthProvider: previousAuthProvider,
            ),
      ),
      ChangeNotifierProxyProvider3<ApiService, AuthProvider, WebSocketService, CompanyProvider>(
        create: (_) => CompanyProvider(null, null, null),
        update: (context, apiService, authProvider, webSocketService, _) =>
            CompanyProvider(apiService, authProvider, webSocketService),
      ),
      ChangeNotifierProxyProvider2<ApiService, AuthProvider, CalendarProvider>(
        create: (_) => CalendarProvider(null, null),
        update: (context, apiService, authProvider, _) =>
            CalendarProvider(apiService, authProvider),
      ),
    ];
  }
}