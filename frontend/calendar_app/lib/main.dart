import 'package:calendar_app/screens/company_calendar_screen.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/blocs/calendar_cubit.dart';
import 'firabase_options.dart'

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<WebSocketService>(
          create: (context) => WebSocketService(
            Provider.of<ApiService>(context, listen: false),
          ),
          // Add dispose to clean up WebSocketService resources
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProxyProvider<ApiService, AuthProvider>(
          create: (_) => AuthProvider(null),
          update: (_, apiService, __) => AuthProvider(apiService),

        // AuthProvider now depends on ApiService and WebSocketService
        // Assuming AuthProvider's constructor was updated to:
        // AuthProvider(ApiService? api, WebSocketService? ws, {AuthProvider? previousAuthProvider})
        ChangeNotifierProxyProvider2<ApiService, WebSocketService, AuthProvider>(
          create: (_) => AuthProvider(null, null), // Initial placeholder
          update: (context, apiService, webSocketService, previousAuthProvider) =>
              AuthProvider(
                apiService,
                webSocketService,
                previousAuthProvider: previousAuthProvider // Pass previous instance
              ),
        ),
        ChangeNotifierProxyProvider2<ApiService, AuthProvider, CompanyProvider>(
          create: (_) => CompanyProvider(null, null),
          update: (_, apiService, authProvider, __) => CompanyProvider(apiService, authProvider),
        ),

        // CalendarProvider depends on ApiService and AuthProvider
        // Assuming CalendarProvider constructor is: CalendarProvider(ApiService? api, AuthProvider? auth)
        ChangeNotifierProxyProvider2<ApiService, AuthProvider, CalendarProvider>(
          create: (_) => CalendarProvider(null, null),
          update: (_, apiService, authProvider, __) => CalendarProvider(apiService, authProvider),
        ),
        BlocProvider<CalendarCubit>(
          create: (context) => CalendarCubit(
            Provider.of<ApiService>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final apiService = Provider.of<ApiService>(context, listen: false);
          final webSocketService = Provider.of<WebSocketService>(context, listen: false);

          return MultiBlocProvider(
            providers: [
              BlocProvider<CalendarCubit>(
                create: (context) => CalendarCubit(apiService, webSocketService),
              ),
            ],
            child: Consumer<AuthProvider>(
              builder: (ctx, auth, _) => MaterialApp(
                title: 'Company Calendar',
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                ),
                // Handle initial authentication state and auto-login attempt
                home: auth.isAuth
                    ? (auth.isCompanyOwner
                        ? const CompanyOwnerHomeScreen()
                        : const EmployeeHomeScreen())
                    : FutureBuilder(
                        future: auth.tryAutoLogin(),
                        builder: (ctx, authResultSnapshot) {
                          if (authResultSnapshot.connectionState == ConnectionState.waiting) {
                            // Show a loading indicator while trying to auto-login
                            return const Scaffold(body: Center(child: CircularProgressIndicator()));
                          }
                          // After tryAutoLogin, check auth.isAuth again
                          return auth.isAuth
                              ? (auth.isCompanyOwner ? const CompanyOwnerHomeScreen() : const EmployeeHomeScreen())
                              : const LoginScreen();
                        },
                      ),
              ),
            ),
          );
        }
      ),
    );
  }
}