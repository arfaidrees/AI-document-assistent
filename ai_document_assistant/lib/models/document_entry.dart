class DocumentEntry {
  const DocumentEntry({
    required this.filename,
    required this.page,
  });

  final String filename;
  final int? page;

  factory DocumentEntry.fromJson(Map<String, dynamic> json) {
    return DocumentEntry(
      filename: json['filename'] as String? ?? 'Unknown PDF',
      page: (json['page'] as num?)?.toInt(),
    );
  }
}
