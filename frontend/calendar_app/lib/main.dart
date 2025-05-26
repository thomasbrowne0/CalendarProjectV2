import 'package:flutter/material.dart';
import 'package:calendar_app/screens/auth/login_screen.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/theme_provider.dart';
import 'package:calendar_app/screens/home/company_owner_home_screen.dart';
import 'package:calendar_app/screens/home/employee_home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';
import 'package:calendar_app/config/provider_config.dart';
import 'package:calendar_app/config/theme_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProviderConfig.getProviders(),
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
                theme: ThemeConfig.lightTheme,
                darkTheme: ThemeConfig.darkTheme,
                themeMode: themeProvider.themeMode,
                home: _buildHome(auth),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildHome(AuthProvider auth) {
    if (auth.isAuth) {
      return auth.isCompanyOwner 
          ? const CompanyOwnerHomeScreen() 
          : const EmployeeHomeScreen();
    }
    
    return FutureBuilder(
      future: auth.tryAutoLogin(),
      builder: (ctx, authResultSnapshot) {
        if (authResultSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return auth.isAuth
            ? (auth.isCompanyOwner 
                ? const CompanyOwnerHomeScreen() 
                : const EmployeeHomeScreen())
            : const LoginScreen();
      },
    );
  }
}