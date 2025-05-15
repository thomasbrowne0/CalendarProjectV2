import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/screens/company_calendar_screen.dart';
import 'package:calendar_app/screens/employee_list_screen.dart';
import 'package:calendar_app/widgets/home_widget.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  _EmployeeHomeScreenState createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuth && authProvider.user != null && !authProvider.user!.isCompanyOwner) {
        final employeeCompanyId = authProvider.companyId;
        if (employeeCompanyId != null && employeeCompanyId.isNotEmpty) {
          Provider.of<CompanyProvider>(context, listen: false)
              .selectCompany(employeeCompanyId)
              .then((_) {
            if (mounted) setState(() => _isLoading = false);
          }).catchError((error) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load company data: $error')),
              );
            }
          });
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your company information is missing. Please log in again.')),
            );
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final company = Provider.of<CompanyProvider>(context).selectedCompany;

    final pages = [
      company == null ? _buildNoCompanyFound() : const CompanyCalendarScreen(),
      company == null ? _buildNoCompanyFound() : const EmployeeListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(company?.name ?? 'Company Calendar'),
        actions: const [UserProfileMenu(textColor: Colors.white)],
      ),
      body: LoadingWrapper(isLoading: _isLoading, child: pages[_selectedIndex]),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        isOwner: false,
      ),
    );
  }

  Widget _buildNoCompanyFound() {
    return const Center(
      child: Text('No company information found. Please contact your administrator.'),
    );
  }
}
