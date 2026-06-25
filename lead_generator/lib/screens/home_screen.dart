import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/lead_provider.dart';
import '../models/lead_model.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;
  
  List<Lead>? _cachedSavedLeads;
  bool _isLoadingSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedLeads();
    });
  }

  Future<void> _loadSavedLeads() async {
    if (_isLoadingSaved) return;
    _isLoadingSaved = true;
    
    try {
      final provider = Provider.of<LeadProvider>(context, listen: false);
      final leads = await provider.getSavedLeads();
      setState(() {
        _cachedSavedLeads = leads;
        _isLoadingSaved = false;
      });
    } catch (e) {
      print('Error loading saved leads: $e');
      setState(() {
        _isLoadingSaved = false;
      });
    }
  }

  Future<void> _refreshSavedLeads() async {
    try {
      final provider = Provider.of<LeadProvider>(context, listen: false);
      final leads = await provider.getSavedLeads();
      setState(() {
        _cachedSavedLeads = leads;
      });
    } catch (e) {
      print('Error refreshing saved leads: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export leads to CSV',
            onPressed: () {
              final provider = Provider.of<LeadProvider>(context, listen: false);
              if (provider.leads.isNotEmpty) {
                _exportLeadsToCSV(provider.leads);
              } else {
                Fluttertoast.showToast(
                  msg: 'No leads to export',
                  backgroundColor: Colors.orange,
                  textColor: Colors.white,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final shouldLogout = await _showLogoutDialog();
              if (shouldLogout) {
                await Provider.of<AuthProvider>(context, listen: false).signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildSearchTab() : _buildSavedLeadsTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 1) {
              _refreshSavedLeads();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved Leads',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    final leadProvider = Provider.of<LeadProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Enter business name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _performSearch(value, leadProvider);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: leadProvider.isLoading
                    ? null
                    : () {
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text, leadProvider);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: leadProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Error Message
          if (leadProvider.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      leadProvider.errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: Colors.red[400]),
                    onPressed: () {
                      leadProvider.clearError();
                    },
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Results Count with clear button
          if (leadProvider.leads.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${leadProvider.leads.length} leads',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    leadProvider.clearLeads();
                  },
                  child: const Text('Clear Results'),
                ),
              ],
            ),
          
          const SizedBox(height: 8),
          
          // Results List
          Expanded(
            child: leadProvider.isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Searching for leads...'),
                      ],
                    ),
                  )
                : leadProvider.leads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No leads found',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching with a different business name',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Example: "Apollo Hospital Mumbai"',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildExampleChip('Apollo Hospital Mumbai'),
                                _buildExampleChip('Taj Hotel Mumbai'),
                                _buildExampleChip('Dominos Mumbai'),
                              ],
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: leadProvider.leads.length,
                        itemBuilder: (context, index) {
                          final lead = leadProvider.leads[index];
                          return _buildLeadCard(lead, leadProvider, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedLeadsTab() {
    if (_isLoadingSaved) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading saved leads...'),
          ],
        ),
      );
    }

    final leads = _cachedSavedLeads ?? [];

    if (leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No saved leads',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save leads from the search tab',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              icon: const Icon(Icons.search),
              label: const Text('Go to Search'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${leads.length} saved leads',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: () {
                  _showDeleteAllDialog();
                },
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                label: const Text(
                  'Delete All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: leads.length,
            itemBuilder: (context, index) {
              final lead = leads[index];
              return _buildSavedLeadCard(lead);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeadCard(Lead lead, LeadProvider provider, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Result number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lead.businessName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  tooltip: 'Save lead',
                  onPressed: () async {
                    try {
                      await provider.saveLead(lead);
                      Fluttertoast.showToast(
                        msg: 'Lead saved!',
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                      );
                      await _refreshSavedLeads();
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: 'Failed to save: ${e.toString()}',
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (lead.ownerName.isNotEmpty)
              _buildInfoRow(Icons.person, lead.ownerName),
            if (lead.phone.isNotEmpty)
              _buildInfoRow(Icons.phone, lead.phone, isClickable: true),
            if (lead.email.isNotEmpty)
              _buildInfoRow(Icons.email, lead.email, isClickable: true),
            if (lead.socialMedia.isNotEmpty)
              _buildInfoRow(Icons.share, lead.socialMedia, isClickable: true),
            if (lead.address.isNotEmpty)
              _buildInfoRow(Icons.location_on, lead.address),
            if (lead.website.isNotEmpty)
              _buildInfoRow(Icons.language, lead.website, isClickable: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedLeadCard(Lead lead) {
    final provider = Provider.of<LeadProvider>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.businessName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete lead',
                  onPressed: () async {
                    try {
                      await provider.deleteLead(lead.id!);
                      Fluttertoast.showToast(
                        msg: 'Lead deleted',
                        backgroundColor: Colors.orange,
                        textColor: Colors.white,
                      );
                      await _refreshSavedLeads();
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: 'Failed to delete: ${e.toString()}',
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (lead.ownerName.isNotEmpty)
              _buildInfoRow(Icons.person, lead.ownerName),
            if (lead.phone.isNotEmpty)
              _buildInfoRow(Icons.phone, lead.phone, isClickable: true),
            if (lead.email.isNotEmpty)
              _buildInfoRow(Icons.email, lead.email, isClickable: true),
            if (lead.socialMedia.isNotEmpty)
              _buildInfoRow(Icons.share, lead.socialMedia, isClickable: true),
            if (lead.address.isNotEmpty)
              _buildInfoRow(Icons.location_on, lead.address),
            if (lead.website.isNotEmpty)
              _buildInfoRow(Icons.language, lead.website, isClickable: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isClickable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: isClickable ? () => _copyToClipboard(text) : null,
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isClickable ? Colors.blue[700] : Colors.grey[800],
                  decoration: isClickable ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (isClickable)
              Icon(
                Icons.copy,
                size: 14,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _performSearch(label, Provider.of<LeadProvider>(context, listen: false));
      },
    );
  }

  void _performSearch(String query, LeadProvider provider) async {
    FocusScope.of(context).unfocus();
    final results = await provider.searchLeads(query);
    
    if (results.isEmpty && provider.errorMessage == null) {
      Fluttertoast.showToast(
        msg: 'No leads found for "$query"',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(
      msg: 'Copied to clipboard!',
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }

  Future<void> _exportLeadsToCSV(List<Lead> leads) async {
    try {
      StringBuffer csvBuffer = StringBuffer();
      
      csvBuffer.writeln('Business Name,Owner Name,Phone,Email,Social Media,Address,Website');
      
      for (var lead in leads) {
        List<String> row = [
          _escapeCSV(lead.businessName),
          _escapeCSV(lead.ownerName),
          _escapeCSV(lead.phone),
          _escapeCSV(lead.email),
          _escapeCSV(lead.socialMedia),
          _escapeCSV(lead.address),
          _escapeCSV(lead.website),
        ];
        csvBuffer.writeln(row.join(','));
      }
      
      String csv = csvBuffer.toString();
      
      final directory = await getTemporaryDirectory();
      final fileName = 'leads_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '📊 Here are my leads from Lead Generator!',
      );
      
      if (mounted) {
        Fluttertoast.showToast(
          msg: '✅ Exported ${leads.length} leads successfully!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: '❌ Export failed: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  String _escapeCSV(String value) {
    if (value.isEmpty) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showDeleteAllDialog() {
    final provider = Provider.of<LeadProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Leads'),
        content: const Text('Are you sure you want to delete all saved leads? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteAllLeads();
                Fluttertoast.showToast(
                  msg: 'All leads deleted',
                  backgroundColor: Colors.orange,
                  textColor: Colors.white,
                );
                await _refreshSavedLeads();
              } catch (e) {
                Fluttertoast.showToast(
                  msg: 'Failed to delete: $e',
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}