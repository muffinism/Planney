class ItineraryActivity {
  final int id;
  final int tripId;
  final String agendaTitle;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String? agendaDetails;

  ItineraryActivity({
    required this.id,
    required this.tripId,
    required this.agendaTitle,
    required this.startDatetime,
    required this.endDatetime,
    this.agendaDetails,
  });

  factory ItineraryActivity.fromJson(Map<String, dynamic> json) {
    return ItineraryActivity(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      tripId: json['trip_id'] is int ? json['trip_id'] : int.parse(json['trip_id'].toString()),
      agendaTitle: json['agenda_title'] as String,
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: DateTime.parse(json['end_datetime'] as String),
      agendaDetails: json['agenda_details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'agenda_title': agendaTitle,
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime.toIso8601String(),
      'agenda_details': agendaDetails,
    };
  }
}

class TripMember {
  final int id;
  final String username;
  final String email;

  TripMember({
    required this.id,
    required this.username,
    required this.email,
  });

  factory TripMember.fromJson(Map<String, dynamic> json) {
    return TripMember(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}

class Trip {
  final int id;
  final String tripTitle;
  final DateTime startDate;
  final DateTime endDate;
  final String initiatorUsername;
  final List<ItineraryActivity> itineraries;
  final List<TripMember> members;

  Trip({
    required this.id,
    required this.tripTitle,
    required this.startDate,
    required this.endDate,
    required this.initiatorUsername,
    required this.itineraries,
    required this.members,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    var itinerariesList = json['itineraries'] as List? ?? [];
    List<ItineraryActivity> parsedItineraries = itinerariesList
        .map((i) => ItineraryActivity.fromJson(i as Map<String, dynamic>))
        .toList();

    var membersList = json['members'] as List? ?? [];
    List<TripMember> parsedMembers = membersList
        .map((m) => TripMember.fromJson(m as Map<String, dynamic>))
        .toList();

    return Trip(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      tripTitle: json['trip_title'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      initiatorUsername: json['initiator_username'] as String,
      itineraries: parsedItineraries,
      members: parsedMembers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_title': tripTitle,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'initiator_username': initiatorUsername,
      'itineraries': itineraries.map((i) => i.toJson()).toList(),
      'members': members.map((m) => m.toJson()).toList(),
    };
  }
}
