import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/lead_model.dart';

class LeadProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Lead> _leads = [];
  List<Lead> _savedLeads = [];
  bool _isLoading = false;
  bool _isLoadingSaved = false;
  String? _errorMessage;

  List<Lead> get leads => _leads;
  List<Lead> get savedLeads => _savedLeads;
  bool get isLoading => _isLoading;
  bool get isLoadingSaved => _isLoadingSaved;
  String? get errorMessage => _errorMessage;

  // ===== GET API BASE URL =====
  String get _apiBaseUrl {
    // For Flutter Web
    return 'http://localhost:5000';
  }

  // ===== HELPER: Get user's sub-collection reference =====
  CollectionReference get _userLeadsCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('leads');
  }

  // ===== CREATE USER DOCUMENT =====
  Future<void> createUserDocument() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? 'User',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('✅ User document created');
      }
    } catch (e) {
      print('❌ Error creating user document: $e');
      rethrow;
    }
  }

  // ===== SEARCH LEADS =====
  Future<List<Lead>> searchLeads(String businessName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '$_apiBaseUrl/scrape';
      print('📡 Calling API: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'business_name': businessName}),
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['leads'] != null) {
          List<Lead> results = (data['leads'] as List)
              .map((lead) => Lead.fromJson(lead))
              .toList();
          
          _leads = results;
          return results;
        } else {
          _leads = [];
          return [];
        }
      } else {
        throw Exception('Failed to fetch leads: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      _errorMessage = 'Could not connect to server. Make sure the API is running.';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== SAVE LEAD =====
  Future<void> saveLead(Lead lead) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      print('👤 User ID: ${user.uid}');
      print('💼 Saving lead: ${lead.businessName}');

      await createUserDocument();

      final existing = await _userLeadsCollection
          .where('businessName', isEqualTo: lead.businessName)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('This lead is already saved');
      }

      await _userLeadsCollection.add({
        'businessName': lead.businessName,
        'ownerName': lead.ownerName,
        'phone': lead.phone,
        'email': lead.email,
        'socialMedia': lead.socialMedia,
        'address': lead.address,
        'website': lead.website,
        'savedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Lead saved successfully!');
      await getSavedLeads();
    } catch (e) {
      print('❌ Error in saveLead: $e');
      rethrow;
    }
  }

  // ===== GET SAVED LEADS =====
  Future<List<Lead>> getSavedLeads() async {
    _isLoadingSaved = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _savedLeads = [];
        return [];
      }

      print('📱 Fetching leads for user: ${user.uid}');

      final snapshot = await _userLeadsCollection
          .orderBy('savedAt', descending: true)
          .get();

      print('📊 Found ${snapshot.docs.length} leads');

      final leads = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        
        return Lead(
          id: doc.id,
          businessName: data?['businessName'] as String? ?? 'Unknown',
          ownerName: data?['ownerName'] as String? ?? '',
          phone: data?['phone'] as String? ?? '',
          email: data?['email'] as String? ?? '',
          socialMedia: data?['socialMedia'] as String? ?? '',
          address: data?['address'] as String? ?? '',
          website: data?['website'] as String? ?? '',
        );
      }).toList();

      _savedLeads = leads;
      return leads;
    } catch (e) {
      print('❌ Error fetching saved leads: $e');
      _errorMessage = e.toString();
      _savedLeads = [];
      return [];
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  // ===== DELETE LEAD =====
  Future<void> deleteLead(String id) async {
    try {
      await _userLeadsCollection.doc(id).delete();
      await getSavedLeads();
    } catch (e) {
      rethrow;
    }
  }

  // ===== DELETE ALL LEADS =====
  Future<void> deleteAllLeads() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final snapshot = await _userLeadsCollection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _savedLeads = [];
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ===== DEBUG =====
  Future<void> debugCheckUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }
      
      print('👤 User UID: ${user.uid}');
      print('👤 User Email: ${user.email}');
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      print('📄 User document exists: ${userDoc.exists}');
      
      if (userDoc.exists) {
        print('📄 User data: ${userDoc.data()}');
      }
      
      final leadsSnapshot = await _userLeadsCollection.get();
      print('📊 Leads found: ${leadsSnapshot.docs.length}');
      
      for (var doc in leadsSnapshot.docs) {
        print('📝 Lead: ${doc.data()}');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  // ===== CLEAR ERROR =====
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ===== CLEAR LEADS =====
  void clearLeads() {
    _leads = [];
    notifyListeners();
  }
}