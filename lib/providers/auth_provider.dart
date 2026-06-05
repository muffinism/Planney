import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:5000/api';
  }
  try {
    return Platform.isAndroid ? 'http://10.0.2.2:5000/api' : 'http://localhost:5000/api';
  } catch (_) {
    return 'http://localhost:5000/api';
  }
}

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  String? _username;
  String? _email;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];

  String? get token => _token;
  String? get username => _username;
  String? get email => _email;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;
  List<Map<String, dynamic>> get friends => _friends;
  List<Map<String, dynamic>> get incomingRequests => _incomingRequests;
  List<Map<String, dynamic>> get outgoingRequests => _outgoingRequests;

  AuthProvider() {
    _loadPersistedToken();
  }

  Future<void> _loadPersistedToken() async {
    _isLoading = true;
    notifyListeners();
    try {
      _token = await _storage.read(key: 'auth_token');
      _username = await _storage.read(key: 'username');
      _email = await _storage.read(key: 'email');
    } catch (e) {
      _errorMessage = 'Failed to load authentication state: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return await login(email, password);
      } else {
        _errorMessage = responseData['error'] ?? 'Registration failed.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = responseData['token'];
        _username = responseData['user']['username'];
        _email = responseData['user']['email'];

        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(key: 'username', value: _username);
        await _storage.write(key: 'email', value: _email);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['error'] ?? 'Login failed.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<void> logout() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      // Ignore or log secure storage deletion failures (e.g. on Web platform)
      _errorMessage = 'Failed to clear secure storage: $e';
    }
    _token = null;
    _username = null;
    _email = null;
    notifyListeners();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> fetchFriends() async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/friends'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _friends = data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else if (response.statusCode == 401) {
        await logout();
        return;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['error'] ?? 'Failed to load friends.';
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFriendRequests() async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/friends/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final incomingList = data['incoming'] as List? ?? [];
        final outgoingList = data['outgoing'] as List? ?? [];
        
        _incomingRequests = incomingList.map((item) => Map<String, dynamic>.from(item)).toList();
        _outgoingRequests = outgoingList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else if (response.statusCode == 401) {
        await logout();
        return;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['error'] ?? 'Failed to load friend requests.';
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendFriendRequest(String username) async {
    if (_token == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/friends/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'username': username}),
      );

      if (response.statusCode == 401) {
        await logout();
        return false;
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchFriendRequests();
        await fetchFriends();
        return true;
      } else {
        _errorMessage = responseData['error'] ?? 'Failed to send friend request.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> respondToFriendRequest(int requestId, String action) async {
    if (_token == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/friends/requests/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'action': action}),
      );

      if (response.statusCode == 401) {
        await logout();
        return false;
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await fetchFriendRequests();
        await fetchFriends();
        return true;
      } else {
        _errorMessage = responseData['error'] ?? 'Failed to respond to friend request.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
