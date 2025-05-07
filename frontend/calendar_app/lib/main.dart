import 'package:flutter/material.dart';
import 'package:calendar_app/screens/login_screen.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/screens/company_owner_home_screen.dart';  // Add this import
import 'package:calendar_app/screens/employee_home_screen.dart';      // Add this import

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<WebSocketService>(
          create: (context) => WebSocketService(
            Provider.of<ApiService>(context, listen: false),
          ),
        ),
        ChangeNotifierProxyProvider<ApiService, AuthProvider>(
          create: (_) => AuthProvider(null),
          update: (_, apiService, __) => AuthProvider(apiService),
        ),
        ChangeNotifierProxyProvider2<ApiService, AuthProvider, CompanyProvider>(
          create: (_) => CompanyProvider(null, null),
          update: (_, apiService, authProvider, __) => CompanyProvider(apiService, authProvider),
        ),
        ChangeNotifierProxyProvider2<ApiService, AuthProvider, CalendarProvider>(
          create: (_) => CalendarProvider(null, null),
          update: (_, apiService, authProvider, __) => CalendarProvider(apiService, authProvider),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Company Calendar',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: auth.isAuth 
              ? auth.isCompanyOwner
                  ? CompanyOwnerHomeScreen() 
                  : EmployeeHomeScreen()
              : LoginScreen(),
        ),
      ),
    );
  }
}
