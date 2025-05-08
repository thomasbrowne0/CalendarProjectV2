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
        _isLoading = true;
      });
      final user = Provider.of<AuthProvider>(context).user;
      // For employees, we need to load their company
      if (user != null && !user.isCompanyOwner) {
        // Get company ID from user claims (this might need to be adjusted based on your actual implementation)
        String companyId = ''; // This should come from user claims
        Provider.of<CompanyProvider>(context).selectCompany(companyId).then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final company = companyProvider.selectedCompany;
    final user = Provider.of<AuthProvider>(context).user;

    List<Widget> pages = [
      company == null ? _buildNoCompanyFound() : const CompanyCalendarScreen(),
      company == null ? _buildNoCompanyFound() : const EmployeeListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(company?.name ?? 'Company Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
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
