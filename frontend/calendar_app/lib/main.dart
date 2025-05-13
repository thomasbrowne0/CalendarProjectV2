import 'package:flutter/material.dart';
import 'package:calendar_app/screens/login_screen.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/screens/company_owner_home_screen.dart';  // Add this import
import 'package:calendar_app/screens/employee_home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();// Add this import

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<WebSocketService>(
          create: (context) => WebSocketService(
            context.read<ApiService>(),
          ),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProxyProvider<ApiService, AuthProvider>(
          create: (context) => AuthProvider(context.read<ApiService>()),
          update: (_, apiService, previous) =>
          previous ?? AuthProvider(apiService),
        ),
        ChangeNotifierProxyProvider2<ApiService, AuthProvider, CompanyProvider>(
          create: (context) => CompanyProvider(
            context.read<ApiService>(),
            context.read<AuthProvider>(),
          ),
          update: (_, apiService, authProvider, previous) =>
          previous ?? CompanyProvider(apiService, authProvider),
        ),
        ChangeNotifierProxyProvider3<ApiService, AuthProvider, WebSocketService, CalendarProvider>(
          create: (context) => CalendarProvider(
            context.read<ApiService>(),
            context.read<AuthProvider>(),
            context.read<WebSocketService>(),
          ),
          update: (_, apiService, authProvider, webSocketService, previous) =>
          previous ?? CalendarProvider(
            apiService,
            authProvider,
            webSocketService,
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Company Calendar',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: auth.isAuth 
              ? auth.isCompanyOwner
                  ? const CompanyOwnerHomeScreen() 
                  : const EmployeeHomeScreen()
              : const LoginScreen(),
        ),
      ),
    );
  }
}
