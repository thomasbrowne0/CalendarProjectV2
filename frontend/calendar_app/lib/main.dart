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
import 'package:calendar_app/cubit/calendar_cubit.dart';

void main() {
  runApp(const MyApp());
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
          dispose: (_, service) => service.dispose(),
        ),

        ChangeNotifierProxyProvider2<ApiService, WebSocketService, AuthProvider>(
          create: (_) => AuthProvider(null, null), // Initial placeholder
          update: (context, apiService, webSocketService, previousAuthProvider) =>
              AuthProvider(
                apiService,
                webSocketService,
                previousAuthProvider: previousAuthProvider
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
                  brightness: Brightness.light,
                ),
                darkTheme: ThemeData(
                  primarySwatch: Colors.blue,
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  brightness: Brightness.dark,
                ),
                themeMode: ThemeMode.system,
                home: auth.isAuth
                    ? (auth.isCompanyOwner
                        ? const CompanyOwnerHomeScreen()
                        : const EmployeeHomeScreen())
                    : FutureBuilder(
                        future: auth.tryAutoLogin(),
                        builder: (ctx, authResultSnapshot) {
                          if (authResultSnapshot.connectionState == ConnectionState.waiting) {
                            return const Scaffold(body: Center(child: CircularProgressIndicator()));
                          }
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