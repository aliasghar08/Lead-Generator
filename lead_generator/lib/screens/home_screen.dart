import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;
  
  List<Lead>? _cachedSavedLeads;
  bool _isLoadingSaved = false;
  Set<String> _savedLeadIds = {};

  // Search suggestions
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;
  
  // 🌍 Global famous places and businesses
  final List<String> _globalBusinesses = [
    'Mayo Clinic Rochester',
    'Cleveland Clinic Ohio',
    'Johns Hopkins Hospital Baltimore',
    'Massachusetts General Hospital Boston',
    'Singapore General Hospital',
    'Shifa International Hospital Islamabad',
    'Aga Khan University Hospital Karachi',
    'Ziauddin Hospital Karachi',
    'Combined Military Hospital Rawalpindi',
    'Apollo Hospitals India',
    'Fortis Hospital India',
    'Bumrungrad International Hospital Bangkok',
    'Gleneagles Hospital Singapore',
    'Mount Elizabeth Hospital Singapore',
    'Royal Melbourne Hospital Australia',
    'St. Thomas Hospital London',
    'Charité Berlin Germany',
    'Burj Al Arab Dubai',
    'Atlantis The Palm Dubai',
    'Marriott Marquis Dubai',
    'Ritz-Carlton New York',
    'Waldorf Astoria New York',
    'The Plaza New York',
    'Ritz Paris',
    'The Savoy London',
    'The Ritz London',
    'Marina Bay Sands Singapore',
    'Sands Casino Singapore',
    'The Venetian Las Vegas',
    'Bellagio Las Vegas',
    'MGM Grand Las Vegas',
    'Four Seasons Toronto',
    'Fairmont Banff Springs Canada',
    'Pearl Continental Hotel Karachi',
    'Serena Hotel Islamabad',
    'Marriott Hotel Karachi',
    'Avari Hotel Lahore',
    'Pearl Continental Hotel Lahore',
    'Faletti\'s Hotel Lahore',
    'Taj Mahal Palace Mumbai',
    'Oberoi Mumbai',
    'Oberoi Delhi',
    'Taj Lake Palace Udaipur',
    'Shangri-La Kuala Lumpur',
    'Mandarin Oriental Hong Kong',
    'Peninsula Hong Kong',
    'Raffles Singapore',
    'The Fullerton Hotel Singapore',
    'The Ritz-Carlton Hong Kong',
    'Four Seasons Hong Kong',
    'The Landmark Mandarin Oriental Hong Kong',
    'The St. Regis Singapore',
    'The Westin Singapore',
    'DHA Lahore',
    'DHA Karachi',
    'Bahria Town Rawalpindi',
    'Bahria Town Lahore',
    'Bahria Town Karachi',
    'Defence Housing Authority Lahore',
    'Gulshan-e-Iqbal Karachi',
    'Clifton Karachi',
    'Blue Area Islamabad',
    'F-8 Islamabad',
    'E-11 Islamabad',
    'Johar Town Lahore',
    'Gulberg Lahore',
    'Model Town Lahore',
    'Cavite City Philippines',
    'Makati City Philippines',
    'BGC Taguig Philippines',
    'Bonifacio Global City Taguig',
    'Legazpi Village Makati',
    'Salcedo Village Makati',
    'Ayala Center Makati',
    'Ortigas Center Pasig',
    'Eastwood City Quezon City',
    'Newport City Pasay',
    'MOA Complex Pasay',
    'Alabang Muntinlupa',
    'Nuvali Laguna',
    'Central Business District Singapore',
    'Orchard Road Singapore',
    'Marina Bay Singapore',
    'Suntec City Singapore',
    'Raffles Place Singapore',
    'Shenton Way Singapore',
    'Downtown Core Singapore',
    'Bugis Singapore',
    'Chinatown Singapore',
    'Little India Singapore',
    'Kampong Glam Singapore',
    'Tanjong Pagar Singapore',
    'Clarke Quay Singapore',
    'Boat Quay Singapore',
    'Robertson Quay Singapore',
    'Holland Village Singapore',
    'East Coast Singapore',
    'West Coast Singapore',
    'Woodlands Singapore',
    'Jurong East Singapore',
    'Tampines Singapore',
    'Bedok Singapore',
    'Ang Mo Kio Singapore',
    'Bishan Singapore',
    'Toa Payoh Singapore',
    'Serangoon Singapore',
    'Punggol Singapore',
    'Sengkang Singapore',
    'Pasir Ris Singapore',
    'Dubai Mall UAE',
    'Mall of the Emirates Dubai',
    'Ibn Battuta Mall Dubai',
    'Centaurus Mall Islamabad',
    'Lucky One Mall Karachi',
    'Emporium Mall Lahore',
    'Faisalabad City',
    'Gulberg Lahore',
    'Defence Housing Authority Lahore',
    'Avenue 5 Dubai',
    'The Dubai Fountain Dubai',
    'Burj Khalifa Dubai',
    'Palm Jumeirah Dubai',
    'JBR Dubai',
    'Dubai Marina Dubai',
    'Business Bay Dubai',
    'Al Barsha Dubai',
    'Jumeirah Beach Residence Dubai',
    'La Mer Dubai',
    'City Walk Dubai',
    'Boxpark Dubai',
    'Alserkal Avenue Dubai',
    'Dubai Design District Dubai',
    'Dubai Silicon Oasis Dubai',
    'Dubai Internet City Dubai',
    'Dubai Media City Dubai',
    'Dubai Knowledge Park Dubai',
    'Dubai Healthcare City Dubai',
    'Dubai International Financial Centre Dubai',
    'Dubai World Trade Centre Dubai',
    'Dubai International Airport Dubai',
    'Al Maktoum International Airport Dubai',
    'Dubai South Dubai',
    'Dubai Land Dubai',
    'Motor City Dubai',
    'Dubai Sports City Dubai',
    'Dubai Hills Estate Dubai',
    'Arabian Ranches Dubai',
    'Emirates Hills Dubai',
    'Jumeirah Lakes Towers Dubai',
    'Dubai Silicon Oasis Dubai',
    'International City Dubai',
    'Dubai Festival City Dubai',
    'Dubai Waterfront Dubai',
    'Dubai Creek Harbour Dubai',
    'Dubai Opera Dubai',
    'Dubai Frame Dubai',
    'Museum of the Future Dubai',
    'Dubai Miracle Garden Dubai',
    'Dubai Butterfly Garden Dubai',
    'Dubai Garden Glow Dubai',
    'Dubai Safari Dubai',
    'Dubai Aquarium Dubai',
    'Dubai Underwater Zoo Dubai',
    'Dubai Ice Rink Dubai',
    'Dubai Fountains Dubai',
    'Noma Copenhagen',
    'Osteria Francescana Italy',
    'Eleven Madison Park New York',
    'Gaggan Bangkok',
    'Ultraviolet Shanghai',
    'Central Peru',
    'D.O.M. Brazil',
    'Arzak Spain',
    'Mugaritz Spain',
    'Alinea Chicago',
    'The Ledbury London',
    'The Fat Duck UK',
    'Restaurant Gordon Ramsay London',
    'Le Bernardin New York',
    'Per Se New York',
    'Daniel New York',
    'Jean-Georges New York',
    'The French Laundry Napa',
    'Manresa Los Gatos',
    'Saison San Francisco',
    'Atelier Crenn San Francisco',
    'Quince San Francisco',
    'Benu San Francisco',
    'Coi San Francisco',
    'The Restaurant at Meadowood Napa',
    'SingleThread Healdsburg',
    'Pujol Mexico City',
    'Quintonil Mexico City',
    'Boragó Chile',
    'Maido Peru',
    'Gaggan Anand Bangkok',
    'Le Du Bangkok',
    'Sühring Bangkok',
    'Pastelaria Bangkok',
    'Eat Me Bangkok',
    'Bo.Lan Bangkok',
    'Nahm Bangkok',
    'Jaan by Kirk Westaway Singapore',
    'Odette Singapore',
    'Les Amis Singapore',
    'Restaurant André Singapore',
    'Waku Ghin Singapore',
    'Cut Singapore',
    'Salt n Pepper Islamabad',
    'Butt Karahi Lahore',
    'Kolachi Karachi',
    'Monal Islamabad',
    'The Polo Lounge Lahore',
    'Cafe Aylanto Lahore',
    'Fuchsia Kitchen Lahore',
    'Bundu Khan Lahore',
    'Phoenicia Lahore',
    'Spice Bazaar Lahore',
    'The Pantry Lahore',
    'Roasters Lahore',
    'Second Cup Lahore',
    'Coffee Bean & Tea Leaf Lahore',
    'Gloria Jean\'s Lahore',
    'Tim Hortons Lahore',
    'McDonald\'s Lahore',
    'KFC Lahore',
    'Pizza Hut Lahore',
    'Dominos Lahore',
    'Subway Lahore',
    'Burger King Lahore',
    'Taco Bell Lahore',
    'Wendy\'s Lahore',
    'Dunkin\' Donuts Lahore',
    'Baskin Robbins Lahore',
    'Cold Stone Creamery Lahore',
    'Haagen-Dazs Lahore',
    'Cinnabon Lahore',
    'Auntie Anne\'s Lahore',
    'Cinnabon Lahore',
    'Dunkin\' Donuts Lahore',
  ];

  // Search history (cached)
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedLeads();
    });
    
    _searchController.addListener(_updateSuggestions);
  }

  void _updateSuggestions() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }

    _isSearching = true;
    
    final allSources = [..._globalBusinesses, ..._searchHistory];
    final filtered = allSources
        .where((item) => item.toLowerCase().contains(query))
        .toList()
        .take(8)
        .toList();

    setState(() {
      _suggestions = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  void _addToHistory(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      if (!_searchHistory.contains(query)) {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 20) {
          _searchHistory.removeLast();
        }
      }
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
        _savedLeadIds = leads.map((l) => l.id ?? '').toSet();
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
        _savedLeadIds = leads.map((l) => l.id ?? '').toSet();
      });
    } catch (e) {
      print('Error refreshing saved leads: $e');
    }
  }

  bool _isLeadSaved(Lead lead) {
    if (lead.id == null || lead.id!.isEmpty) {
      return _cachedSavedLeads?.any((l) => l.businessName == lead.businessName) ?? false;
    }
    return _savedLeadIds.contains(lead.id);
  }

  String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    
    try {
      Uri uri = Uri.parse(url);
      String host = uri.host;
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      String path = uri.path;
      if (path.length > 15) {
        path = path.substring(0, 12) + '...';
      }
      return host + path;
    } catch (e) {
      return url.substring(0, 40) + '...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        // Close suggestions when tapping on background
        if (_showSuggestions) {
          setState(() {
            _showSuggestions = false;
          });
        }
        _searchFocusNode.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar with suggestions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search businesses worldwide...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _suggestions = [];
                                      _showSuggestions = false;
                                      _isSearching = false;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onChanged: (value) {
                          _updateSuggestions();
                        },
                        onTap: () {
                          // Show suggestions when tapping on text field
                          if (_searchController.text.isNotEmpty && _suggestions.isNotEmpty) {
                            setState(() {
                              _showSuggestions = true;
                            });
                          }
                        },
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _addToHistory(value);
                            _performSearch(value, leadProvider);
                            setState(() {
                              _showSuggestions = false;
                            });
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
                                _addToHistory(_searchController.text);
                                _performSearch(_searchController.text, leadProvider);
                                setState(() {
                                  _showSuggestions = false;
                                });
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
                
                // Suggestions dropdown - directly below the search bar
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Suggestions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${_suggestions.length} results',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 0.5),
                          // List of suggestions
                          ..._suggestions.map((suggestion) {
                            return InkWell(
                              onTap: () {
                                // Perform search and close suggestions
                                _searchController.text = suggestion;
                                _addToHistory(suggestion);
                                _performSearch(suggestion, leadProvider);
                                setState(() {
                                  _showSuggestions = false;
                                  _suggestions = [];
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 18,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        suggestion,
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Error message
            if (leadProvider.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.red[900] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDarkMode ? Colors.red[700]! : Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: isDarkMode ? Colors.red[300] : Colors.red[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leadProvider.errorMessage!,
                        style: TextStyle(
                          color: isDarkMode ? Colors.red[300] : Colors.red[700],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: isDarkMode ? Colors.red[300] : Colors.red[400]),
                      onPressed: () {
                        leadProvider.clearError();
                      },
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Results
            if (leadProvider.leads.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Found ${leadProvider.leads.length} leads',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
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
            
            // Main content area
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
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No leads found',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try searching with a different business name',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildExampleChip('Burj Al Arab Dubai'),
                                    _buildExampleChip('Marina Bay Sands Singapore'),
                                    _buildExampleChip('Mayo Clinic Rochester'),
                                    _buildExampleChip('Shifa Hospital Islamabad'),
                                  ],
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildSavedLeadsTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 80,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No saved leads',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save leads from the search tab',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSaved = _isLeadSaved(lead);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.green : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  tooltip: isSaved ? 'Saved' : 'Save lead',
                  onPressed: () async {
                    if (isSaved) {
                      Fluttertoast.showToast(
                        msg: 'Lead already saved!',
                        backgroundColor: Colors.orange,
                        textColor: Colors.white,
                      );
                    } else {
                      try {
                        await provider.saveLead(lead);
                        setState(() {
                          _savedLeadIds.add(lead.id ?? lead.businessName);
                          _refreshSavedLeads();
                        });
                        Fluttertoast.showToast(
                          msg: 'Lead saved!',
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                      } catch (e) {
                        Fluttertoast.showToast(
                          msg: 'Failed to save: ${e.toString()}',
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (lead.ownerName.isNotEmpty)
              _buildInfoRow(Icons.person, lead.ownerName, isDarkMode),
            if (lead.phone.isNotEmpty)
              _buildInfoRow(Icons.phone, lead.phone, isDarkMode, isClickable: true, isPhone: true),
            if (lead.email.isNotEmpty)
              _buildInfoRow(Icons.email, lead.email, isDarkMode, isClickable: true, isEmail: true),
            if (lead.socialMedia.isNotEmpty)
              _buildInfoRow(Icons.share, lead.socialMedia, isDarkMode, isClickable: true, isSocial: true),
            if (lead.address.isNotEmpty)
              _buildInfoRow(Icons.location_on, lead.address, isDarkMode, isClickable: true, isAddress: true),
            if (lead.website.isNotEmpty)
              _buildInfoRow(Icons.language, _truncateUrl(lead.website), isDarkMode, isClickable: true, isWebsite: true, fullText: lead.website),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedLeadCard(Lead lead) {
    final provider = Provider.of<LeadProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDarkMode ? Colors.grey[850] : Colors.white,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete lead',
                  onPressed: () async {
                    try {
                      await provider.deleteLead(lead.id!);
                      setState(() {
                        _savedLeadIds.remove(lead.id);
                      });
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
              _buildInfoRow(Icons.person, lead.ownerName, isDarkMode),
            if (lead.phone.isNotEmpty)
              _buildInfoRow(Icons.phone, lead.phone, isDarkMode, isClickable: true, isPhone: true),
            if (lead.email.isNotEmpty)
              _buildInfoRow(Icons.email, lead.email, isDarkMode, isClickable: true, isEmail: true),
            if (lead.socialMedia.isNotEmpty)
              _buildInfoRow(Icons.share, lead.socialMedia, isDarkMode, isClickable: true, isSocial: true),
            if (lead.address.isNotEmpty)
              _buildInfoRow(Icons.location_on, lead.address, isDarkMode, isClickable: true, isAddress: true),
            if (lead.website.isNotEmpty)
              _buildInfoRow(Icons.language, _truncateUrl(lead.website), isDarkMode, isClickable: true, isWebsite: true, fullText: lead.website),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDarkMode, {
    bool isClickable = false,
    bool isPhone = false,
    bool isEmail = false,
    bool isWebsite = false,
    bool isSocial = false,
    bool isAddress = false,
    String? fullText,
  }) {
    Color textColor;
    if (isClickable) {
      textColor = isDarkMode ? Colors.lightBlue[300]! : Colors.blue[700]!;
    } else {
      textColor = isDarkMode ? Colors.grey[300]! : Colors.grey[800]!;
    }
    
    final displayText = text;
    final actionText = fullText ?? text;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: isClickable ? () => _handleTap(actionText, isPhone, isEmail, isWebsite, isSocial, isAddress) : null,
        child: Row(
          children: [
            Icon(icon, size: 16, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: textColor,
                  decoration: isClickable ? TextDecoration.underline : null,
                  fontSize: 14,
                ),
              ),
            ),
            if (isClickable)
              Icon(
                Icons.open_in_new,
                size: 14,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(String text, bool isPhone, bool isEmail, bool isWebsite, bool isSocial, bool isAddress) async {
    try {
      String url;
      
      if (isPhone) {
        String phone = text.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        if (!phone.startsWith('+') && !phone.startsWith('0')) {
          phone = '+91$phone';
        }
        url = 'tel:$phone';
      } else if (isEmail) {
        url = 'mailto:$text';
      } else if (isWebsite) {
        if (!text.startsWith('http://') && !text.startsWith('https://')) {
          url = 'https://$text';
        } else {
          url = text;
        }
      } else if (isSocial) {
        if (text.startsWith('@')) {
          url = 'https://instagram.com/${text.substring(1)}';
        } else if (text.contains('facebook.com')) {
          url = 'https://$text';
        } else {
          url = 'https://$text';
        }
      } else if (isAddress) {
        String encodedAddress = Uri.encodeComponent(text);
        url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      } else {
        if (!text.startsWith('http://') && !text.startsWith('https://')) {
          url = 'https://$text';
        } else {
          url = text;
        }
      }
      
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: text));
        Fluttertoast.showToast(
          msg: 'Copied to clipboard!',
          backgroundColor: Colors.blue,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: text));
      Fluttertoast.showToast(
        msg: 'Copied to clipboard!',
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildExampleChip(String label) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      onPressed: () {
        _searchController.text = label;
        _addToHistory(label);
        _performSearch(label, Provider.of<LeadProvider>(context, listen: false));
        setState(() {
          _showSuggestions = false;
        });
      },
    );
  }

  void _performSearch(String query, LeadProvider provider) async {
    _searchFocusNode.unfocus();
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
                setState(() {
                  _savedLeadIds.clear();
                });
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
    _searchController.removeListener(_updateSuggestions);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}