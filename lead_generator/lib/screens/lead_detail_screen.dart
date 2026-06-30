import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lead_generator/models/lead_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeadDetailScreen extends StatefulWidget {
  final Lead lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoadingTeam = false;
  String? _teamError;
  bool _teamFetchAttempted = false;

  @override
  void initState() {
    super.initState();
    _fetchTeamMembers();
  }

  Future<void> _fetchTeamMembers() async {
    setState(() {
      _isLoadingTeam = true;
      _teamError = null;
      _teamFetchAttempted = true;
    });

    try {
      // Get domain from website
      String? domain;
      if (widget.lead.website != null && widget.lead.website!.isNotEmpty) {
        try {
          domain = Uri.parse(widget.lead.website!).host;
          if (domain.startsWith('www.')) {
            domain = domain.substring(4);
          }
        } catch (e) {
          print('Error parsing domain: $e');
        }
      }

      final url = Uri.parse('http://localhost:5000/lead/team');
      print('📡 Calling team API: $url');
      print('📡 Payload: business_name=${widget.lead.businessName}, domain=$domain');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_name': widget.lead.businessName,
          'domain': domain,
        }),
      );

      print('📊 Team API Response status: ${response.statusCode}');
      print('📊 Team API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final team = data['team'] as List? ?? [];
          print('✅ Found ${team.length} team members');
          setState(() {
            _teamMembers = List<Map<String, dynamic>>.from(team);
            _isLoadingTeam = false;
            if (team.isEmpty) {
              _teamError = 'No team members found for this business';
            }
          });
        } else {
          setState(() {
            _isLoadingTeam = false;
            _teamError = data['message'] ?? 'Failed to load team data';
          });
        }
      } else {
        setState(() {
          _isLoadingTeam = false;
          _teamError = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('❌ Error fetching team: $e');
      setState(() {
        _isLoadingTeam = false;
        _teamError = 'Could not connect to server: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasTeam = _teamMembers.isNotEmpty;
    final showOwnerFallback = !_isLoadingTeam && !hasTeam && widget.lead.ownerName.isNotEmpty;
    final showEmptyMessage = !_isLoadingTeam && !hasTeam && _teamFetchAttempted;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lead.businessName,
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== BUSINESS NAME HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.business, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    widget.lead.businessName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.lead.ownerName.isNotEmpty)
                    Text(
                      'Owner: ${widget.lead.ownerName}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== KEY PEOPLE / TEAM SECTION =====
            if (_isLoadingTeam)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Fetching team members...'),
                    ],
                  ),
                ),
              )
            else if (hasTeam)
              _buildTeamSection(context, _teamMembers, isDarkMode)
            else if (showOwnerFallback)
              _buildSection(
                context,
                title: 'Key People',
                icon: Icons.person,
                children: [
                  _buildPersonTile(
                    context,
                    name: widget.lead.ownerName,
                    title: 'Owner',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Text(
                      'Owner information provided from business listing',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              )
            else if (showEmptyMessage)
              _buildSection(
                context,
                title: 'Key People',
                icon: Icons.people,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _teamError ?? 'No team members found',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Team information could not be retrieved for this business',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // ===== CONTACT SECTION =====
            if (widget.lead.phone.isNotEmpty ||
                widget.lead.email.isNotEmpty ||
                widget.lead.website.isNotEmpty)
              _buildSection(
                context,
                title: 'Contact Information',
                icon: Icons.contact_phone,
                children: [
                  if (widget.lead.phone.isNotEmpty)
                    _buildDetailTile(
                      context,
                      icon: Icons.phone,
                      label: 'Phone',
                      value: widget.lead.phone,
                      onTap: () => _launchUrl(
                        context,
                        'tel:${widget.lead.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '')}',
                      ),
                      isDarkMode: isDarkMode,
                    ),
                  if (widget.lead.email.isNotEmpty)
                    _buildDetailTile(
                      context,
                      icon: Icons.email,
                      label: 'Email',
                      value: widget.lead.email,
                      onTap: () => _launchUrl(context, 'mailto:${widget.lead.email}'),
                      isDarkMode: isDarkMode,
                    ),
                  if (widget.lead.website.isNotEmpty)
                    _buildDetailTile(
                      context,
                      icon: Icons.language,
                      label: 'Website',
                      value: widget.lead.website,
                      onTap: () => _launchUrl(context, widget.lead.website),
                      isDarkMode: isDarkMode,
                    ),
                ],
              ),

            const SizedBox(height: 16),

            // ===== LOCATION SECTION =====
            if (widget.lead.address.isNotEmpty)
              _buildSection(
                context,
                title: 'Location',
                icon: Icons.location_on,
                children: [
                  _buildDetailTile(
                    context,
                    icon: Icons.location_on,
                    label: 'Address',
                    value: widget.lead.address,
                    onTap: () => _launchUrl(
                      context,
                      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.lead.address)}',
                    ),
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // ===== SOCIAL MEDIA SECTION =====
            if (widget.lead.socialMedia.isNotEmpty)
              _buildSection(
                context,
                title: 'Social Media',
                icon: Icons.share,
                children: [
                  _buildDetailTile(
                    context,
                    icon: Icons.share,
                    label: 'Social Media',
                    value: widget.lead.socialMedia,
                    onTap: () {
                      String handle = widget.lead.socialMedia.replaceFirst('@', '');
                      _launchUrl(context, 'https://instagram.com/$handle');
                    },
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // ===== RATINGS SECTION =====
            if ((widget.lead.rating != null && widget.lead.rating!.isNotEmpty) ||
                (widget.lead.reviews != null && widget.lead.reviews!.isNotEmpty))
              _buildSection(
                context,
                title: 'Ratings & Reviews',
                icon: Icons.star,
                children: [
                  if (widget.lead.rating != null && widget.lead.rating!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Rating: ${widget.lead.rating} / 5.0',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.lead.reviews != null && widget.lead.reviews!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.comment, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.lead.reviews} reviews',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 24),

            // ===== ACTION BUTTONS =====
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.lead.phone.isNotEmpty)
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 20,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(
                        context,
                        'tel:${widget.lead.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '')}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                  ),
                if (widget.lead.website.isNotEmpty)
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 20,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(context, widget.lead.website),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Visit'),
                    ),
                  ),
                if (widget.lead.address.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(
                        context,
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.lead.address)}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.map),
                      label: const Text('Open in Maps'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== BUILD TEAM SECTION =====
  Widget _buildTeamSection(BuildContext context, List<Map<String, dynamic>> team, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Key People (${team.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...team.map((person) => _buildPersonTile(
              context,
              name: person['name'] ?? 'Unknown',
              title: person['title'] ?? '',
              email: person['email'] ?? '',
              phone: person['phone'] ?? '',
              linkedin: person['linkedin_url'] ?? '',
              isDarkMode: isDarkMode,
            )).toList(),
          ],
        ),
      ),
    );
  }

  // ===== BUILD PERSON TILE =====
  Widget _buildPersonTile(BuildContext context, {
    required String name,
    required String title,
    String email = '',
    String phone = '',
    String linkedin = '',
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (linkedin.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.link, size: 18),
                  onPressed: () => _launchUrl(context, linkedin),
                  tooltip: 'LinkedIn Profile',
                ),
            ],
          ),
          if (email.isNotEmpty || phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  if (email.isNotEmpty)
                    InkWell(
                      onTap: () => _launchUrl(context, 'mailto:$email'),
                      child: Row(
                        children: [
                          const Icon(Icons.email, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (email.isNotEmpty && phone.isNotEmpty)
                    const SizedBox(width: 12),
                  if (phone.isNotEmpty)
                    InkWell(
                      onTap: () => _launchUrl(context, 'tel:${phone.replaceAll(RegExp(r'[\s\-\(\)]'), '')}'),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===== BUILD SECTION =====
  Widget _buildSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // ===== BUILD DETAIL TILE =====
  Widget _buildDetailTile(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      decoration: TextDecoration.underline,
                      decorationColor: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ===== LAUNCH URL =====
  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}