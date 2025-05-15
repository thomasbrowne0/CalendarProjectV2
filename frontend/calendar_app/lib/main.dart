import 'package:flutter/material.dart';
import 'package:calendar_app/screens/login_screen.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/screens/company_owner_home_screen.dart';
import 'package:calendar_app/screens/employee_home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/blocs/calendar_cubit.dart';

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

        // CompanyProvider depends on ApiService and AuthProvider
        // Assuming CompanyProvider constructor is: CompanyProvider(ApiService? api, AuthProvider? auth)
        ChangeNotifierProxyProvider3<ApiService, AuthProvider, WebSocketService, CompanyProvider>(
        create: (_) => CompanyProvider(null, null, null), // Add null for webSocketService
        update: (context, apiService, authProvider, webSocketService, _) => 
        CompanyProvider(apiService, authProvider, webSocketService), // Add webSocketService
        ),

        // CalendarProvider depends on ApiService and AuthProvider
        // Assuming CalendarProvider constructor is: CalendarProvider(ApiService? api, AuthProvider? auth)
        ChangeNotifierProxyProvider2<ApiService, AuthProvider, CalendarProvider>(
          create: (_) => CalendarProvider(null, null), // Initial placeholder
          update: (context, apiService, authProvider, _) => // Ignore previous CalendarProvider instance
              CalendarProvider(apiService, authProvider),
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