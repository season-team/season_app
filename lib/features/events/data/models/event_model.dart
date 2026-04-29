class EventModel {
  final String title;
  final String date;
  final String? startAt;
  final String? endAt;
  final String city;
  final String venue;
  final String country;
  final String category;
  final String source;

  EventModel({
    required this.title,
    required this.date,
    this.startAt,
    this.endAt,
    required this.city,
    required this.venue,
    required this.country,
    required this.category,
    required this.source,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        title: json['title']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        startAt: json['start_at']?.toString(),
        endAt: json['end_at']?.toString(),
        city: json['city']?.toString() ?? '',
        venue: json['venue']?.toString() ?? '',
        country: json['country']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        source: json['source']?.toString() ?? '',
      );
}

class EventsResponse {
  final String country;
  final String language;
  final String generatedAt;
  final List<EventModel> events;

  EventsResponse({
    required this.country,
    required this.language,
    required this.generatedAt,
    required this.events,
  });

  factory EventsResponse.fromJson(Map<String, dynamic> json) => EventsResponse(
        country: json['country']?.toString() ?? '',
        language: json['language']?.toString() ?? '',
        generatedAt: json['generated_at']?.toString() ?? '',
        events: (json['events'] as List?)
                ?.map((e) => EventModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
