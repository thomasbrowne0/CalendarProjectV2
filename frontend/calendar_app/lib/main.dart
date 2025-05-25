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
import 'package:calendar_app/providers/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
            child: Consumer2<AuthProvider, ThemeProvider>(
              builder: (ctx, auth, themeProvider, _) => MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Company Calendar',
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF3F51B5),
                    secondary: Color(0xFFFF4081),
                    onBackground: Color(0xFF212121),
                    surface: Colors.white,
                    onSurface: Color(0xFF212121),
                  ),
                  textTheme: const TextTheme(
                    bodyLarge: TextStyle(color: Color(0xFF212121)),
                    bodyMedium: TextStyle(color: Color(0xFF212121)),
                    titleMedium: TextStyle(color: Color(0xFF757575)),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF3F51B5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  cardTheme: CardTheme(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  floatingActionButtonTheme: const FloatingActionButtonThemeData(
                    backgroundColor: Color(0xFFFF4081),
                    foregroundColor: Colors.white,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF3F51B5)),
                    ),
                  ),
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF3F51B5),
                    secondary: Color(0xFFFF4081),
                    background: Color(0xFF121212),
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  ),
                  textTheme: const TextTheme(
                    bodyLarge: TextStyle(color: Colors.white),
                    bodyMedium: TextStyle(color: Colors.white),
                    titleMedium: TextStyle(color: Color(0xFFB0BEC5)),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF3F51B5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  cardTheme: CardTheme(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  floatingActionButtonTheme: const FloatingActionButtonThemeData(
                    backgroundColor: Color(0xFFFF4081),
                    foregroundColor: Colors.white,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF3F51B5)),
                    ),
                  ),
                ),
                themeMode: themeProvider.themeMode,
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