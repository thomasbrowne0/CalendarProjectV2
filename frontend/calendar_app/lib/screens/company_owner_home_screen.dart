import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/screens/company_calendar_screen.dart';
import 'package:calendar_app/screens/employee_list_screen.dart';
import 'package:calendar_app/screens/create_company_screen.dart';

class CompanyOwnerHomeScreen extends StatefulWidget {
  const CompanyOwnerHomeScreen({super.key});

  @override
  _CompanyOwnerHomeScreenState createState() => _CompanyOwnerHomeScreenState();
}

class _CompanyOwnerHomeScreenState extends State<CompanyOwnerHomeScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      Provider.of<CompanyProvider>(context).fetchCompanies().then((_) {
        final companies = Provider.of<CompanyProvider>(context, listen: false).companies;
        if (companies.isNotEmpty && Provider.of<CompanyProvider>(context, listen: false).selectedCompany == null) {
          Provider.of<CompanyProvider>(context, listen: false).selectCompany(companies[0].id);
        }
        setState(() {
          _isLoading = false;
        });
      });
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final companies = companyProvider.companies;
    final selectedCompany = companyProvider.selectedCompany;
    final user = Provider.of<AuthProvider>(context).user;

    List<Widget> pages = [
      selectedCompany == null ? _buildNoCompanySelected() : const CompanyCalendarScreen(),
      selectedCompany == null ? _buildNoCompanySelected() : const EmployeeListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Calendar'),
        actions: [
          DropdownButton<String>(
            underline: Container(),
            icon: const Icon(Icons.business, color: Colors.black),
            items: companies.map((company) {
              return DropdownMenuItem<String>(
                value: company.id,
                child: Text(company.name),
              );
            }).toList(),
            onChanged: (companyId) {
              if (companyId != null) {
                companyProvider.selectCompany(companyId);
              }
            },
            hint: Text(
              selectedCompany?.name ?? 'Select Company',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    Provider.of<AuthProvider>(context).user?.fullName ?? '',
                    style: const TextStyle(color: Colors.black),
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
            label: 'Employees',
          ),
        ],
      ),
      floatingActionButton: selectedCompany == null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
                );
              },
              tooltip: 'Create Company',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildNoCompanySelected() {
    final companies = Provider.of<CompanyProvider>(context).companies;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (companies.isEmpty) ...[
            const Text('You don\'t have any companies yet.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
                );
              },
              child: const Text('Create Company'),
            ),
          ] else
            const Text('Please select a company from the dropdown menu.'),
        ],
      ),
    );
  }
}
