import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/screens/company_calendar_screen.dart';
import 'package:calendar_app/screens/employee_list_screen.dart';
import 'package:calendar_app/screens/create_company_screen.dart';

class CompanyOwnerHomeScreen extends StatefulWidget {
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

    List<Widget> _pages = [
      selectedCompany == null ? _buildNoCompanySelected() : CompanyCalendarScreen(),
      selectedCompany == null ? _buildNoCompanySelected() : EmployeeListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Company Calendar'),
        actions: [
          DropdownButton<String>(
            underline: Container(),
            icon: Icon(Icons.business, color: Colors.white),
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
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
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
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CreateCompanyScreen()),
                );
              },
              tooltip: 'Create Company',
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
            Text('You don\'t have any companies yet.'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CreateCompanyScreen()),
                );
              },
              child: Text('Create Company'),
            ),
          ] else
            Text('Please select a company from the dropdown menu.'),
        ],
      ),
    );
  }
}
