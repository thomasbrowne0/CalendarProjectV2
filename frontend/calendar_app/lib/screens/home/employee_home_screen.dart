import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/screens/company/company_calendar_screen.dart';
import 'package:calendar_app/screens/employee/employee_list_screen.dart';
import 'package:calendar_app/widgets/display/home_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuth && authProvider.user != null &&
          !authProvider.user!.isCompanyOwner) {
        final String? employeeCompanyId = authProvider.companyId;

        if (employeeCompanyId != null && employeeCompanyId.isNotEmpty) {
          Provider.of<CompanyProvider>(context, listen: false)
              .selectCompany(employeeCompanyId)
              .then((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }).catchError((error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    'Failed to load company data: ${error.toString()}')),
              );
            }
          });
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(
                  'Your company information is missing. Please log in again.')),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final company = companyProvider.selectedCompany;
    final user = Provider
        .of<AuthProvider>(context)
        .user;

    List<Widget> pages = [
      company == null ? _buildNoCompanyFound() : const CompanyCalendarScreen(),
      company == null ? _buildNoCompanyFound() : const EmployeeListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(company?.name ?? 'Company Calendar'),
        actions: [
          AppBarActions(
            additionalAction: Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  '${user?.firstName} ${user?.lastName}',
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : pages[_selectedIndex],
      bottomNavigationBar: CalendarBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildNoCompanyFound() {
    return const Center(
      child: Text(
          'No company information found. Please contact your administrator.'),
    );
  }
}
