import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/trip.dart';
import 'auth_provider.dart';

class TripProvider with ChangeNotifier {
  String? _token;
  VoidCallback? _onUnauthorized;
  List<Trip> _trips = [];
  Trip? _currentTrip;
  bool _isLoading = false;
  String? _errorMessage;

  List<Trip> get trips => _trips;
  Trip? get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void update(String? token, VoidCallback onUnauthorized) {
    _token = token;
    _onUnauthorized = onUnauthorized;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  String _formatDateSafe(DateTime dt) {
    final localDt = dt.toLocal(); 
    final year = localDt.year.toString();
    final month = localDt.month.toString().padLeft(2, '0');
    final day = localDt.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  String _formatDateTimeSafe(DateTime dt) {
    final localDt = dt.toLocal();
    final year = localDt.year.toString();
    final month = localDt.month.toString().padLeft(2, '0');
    final day = localDt.day.toString().padLeft(2, '0');
    final hour = localDt.hour.toString().padLeft(2, '0');
    final min = localDt.minute.toString().padLeft(2, '0');
    final sec = localDt.second.toString().padLeft(2, '0');
    return "$year-$month-$day $hour:$min:$sec";
  }

  Future<void> fetchTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/trips'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _trips = data.map((json) => Trip.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        _onUnauthorized?.call();
        return;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['error'] ?? 'Failed to load trips.';
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTripDetails(int tripId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/trips/$tripId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _currentTrip = Trip.fromJson(data);
      } else if (response.statusCode == 401) {
        _onUnauthorized?.call();
        return;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['error'] ?? 'Failed to load trip details.';
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTrip({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String initiatorUsername,
    List<int>? memberIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/trips'),
        headers: _headers,
        body: json.encode({
          'trip_title': title,
          'start_date': _formatDateSafe(startDate),
          'end_date': _formatDateSafe(endDate),
          'initiator_username': initiatorUsername,
          if (memberIds != null) 'members': memberIds,
        }),
      );

      if (response.statusCode == 401) {
        _onUnauthorized?.call();
        return false;
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        await fetchTrips(); 
        return true;
      } else {
        _errorMessage = responseData['error'] ?? 'Failed to create trip.';
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

  Future<bool> updateTrip({
    required int tripId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String initiatorUsername,
    List<int>? memberIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/trips/$tripId'),
        headers: _headers,
        body: json.encode({
          'trip_title': title,
          'start_date': _formatDateSafe(startDate),
          'end_date': _formatDateSafe(endDate),
          'initiator_username': initiatorUsername,
          if (memberIds != null) 'members': memberIds,
        }),
      );

      if (response.statusCode == 401) {
        _onUnauthorized?.call();
        return false;
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await fetchTrips(); 
        if (_currentTrip?.id == tripId) {
          await fetchTripDetails(tripId);
        }
        return true;
      } else {
        _errorMessage = responseData['error'] ?? 'Failed to update trip.';
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

  Future<bool> deleteTrip(int tripId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/trips/$tripId'),
        headers: _headers,
      );

      if (response.statusCode == 401) {
        _onUnauthorized?.call();
        return false;
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _trips.removeWhere((t) => t.id == tripId);
        if (_currentTrip?.id == tripId) {
          _currentTrip = null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['error'] ?? 'Failed to delete trip.';
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

  Future<bool> addItinerary({
    required int tripId,
    required String agendaTitle,
    required DateTime startDatetime,
    required DateTime endDatetime,
    String? agendaDetails,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/trips/$tripId/itinerary'),
        headers: _headers,
        body: json.encode({
          'agenda_title': agendaTitle,
          'start_datetime': _formatDateTimeSafe(startDatetime),
          'end_datetime': _formatDateTimeSafe(endDatetime),
          'agenda_details': agendaDetails,
        }),
      );

      if (response.statusCode == 401) {
        _onUnauthorized?.call();
        return false;
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        await fetchTripDetails(tripId);
        return true;
      } else {
        _errorMessage = responseData['error'] ?? 'Failed to add itinerary activity.';
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

  Future<bool> updateItineraryActivity({
    required int tripId,
    required int itineraryId,
    required String agendaTitle,
    required DateTime startDatetime,
    required DateTime endDatetime,
    String? agendaDetails,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/trips/$tripId/itinerary/$itineraryId'),
        headers: _headers,
        body: json.encode({
          'agenda_title': agendaTitle,
          'start_datetime': _formatDateTimeSafe(startDatetime),
          'end_datetime': _formatDateTimeSafe(endDatetime),
          'agenda_details': agendaDetails,
        }),
      );
      if (response.statusCode == 401) {
        _onUnauthorized?.call();
        return false;
      }
      if (response.statusCode == 200) {
        await fetchTripDetails(tripId); 
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItineraryActivity(int tripId, int itineraryId) async {
    _isLoading = true; notifyListeners();
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/trips/$tripId/itinerary/$itineraryId'),
        headers: _headers,
      );
      
      if (response.statusCode == 401) {
        _onUnauthorized?.call();
        return false;
      }
      if (response.statusCode == 200) {
        await fetchTripDetails(tripId);
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['error'] ?? 'Failed to delete activity.';
        _isLoading = false; notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false; notifyListeners();
      return false;
    }
  }
}