class Apod {
  final String? title;
  final String? date;
  final String? explanation;
  final String? url;
  final String? mediaType;

  Apod({this.title, this.date, this.explanation, this.url, this.mediaType});

  factory Apod.fromJson(Map<String, dynamic> json) {
    return Apod(
      title: json['title'] as String?,
      date: json['date'] as String?,
      explanation: json['explanation'] as String?,
      url: json['url'] as String?,
      mediaType: json['media_type'] as String?,
    );
  }
}
