import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/screens/company_calendar_screen.dart';
import 'package:calendar_app/screens/employee_list_screen.dart';

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
    setState(() {
      _isLoading = true; // Start loading indicator
    });
    
    // Get the AuthProvider instance (listen: false because we only need to read values once here)
    final authProvider = Provider.of<AuthProvider>(context, listen: false); 
    
    // Check if the user is authenticated, has user data, and is an employee
    if (authProvider.isAuth && authProvider.user != null && !authProvider.user!.isCompanyOwner) {
      // Retrieve the companyId stored in AuthProvider (this was set during login/auto-login)
      final String? employeeCompanyId = authProvider.companyId; 

      if (employeeCompanyId != null && employeeCompanyId.isNotEmpty) {
        // If companyId is available, tell CompanyProvider to select this company
        Provider.of<CompanyProvider>(context, listen: false)
            .selectCompany(employeeCompanyId) 
            .then((_) {
          // After company selection is complete
          if (mounted) { // Check if the widget is still part of the widget tree
            setState(() {
              _isLoading = false; // Stop loading indicator
            });
          }
        }).catchError((error) {
          // If there was an error selecting the company
          if (mounted) {
            setState(() {
              _isLoading = false; // Stop loading indicator
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load company data: ${error.toString()}')),
            );
          }
        });
      } else {
        // Employee is logged in, but their companyId is missing or empty
        if (mounted) {
          setState(() {
            _isLoading = false; // Stop loading indicator
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your company information is missing. Please log in again.')),
          );
        }
      }
    } else {
      // User is not an employee, not authenticated, or user data is null
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading indicator
        });
        // Optionally, if not authenticated, you might want to navigate to the login screen
        // if (!authProvider.isAuth) {
        //   Navigator.of(context).pushReplacementNamed('/login-screen'); // Example
        // }
      }
    }
    _isInit = false; // Ensure this logic runs only once
  }
  super.didChangeDependencies();
}

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final company = companyProvider.selectedCompany;

    List<Widget> pages = [
      company == null ? _buildNoCompanyFound() : const CompanyCalendarScreen(),
      company == null ? _buildNoCompanyFound() : const EmployeeListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(company?.name ?? 'Company Calendar'),
        actions: [
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    Provider.of<AuthProvider>(context).user?.fullName ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Colleagues',
          ),
        ],
      ),
    );
  }

  Widget _buildNoCompanyFound() {
    return const Center(
      child: Text('No company information found. Please contact your administrator.'),
    );
  }
}
