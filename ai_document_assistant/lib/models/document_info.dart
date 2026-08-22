class DocumentInfo {
  const DocumentInfo({
    required this.filename,
    required this.pages,
    required this.chunks,
  });

  final String filename;
  final int pages;
  final int chunks;

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      filename: json['filename'] as String? ?? 'Unknown PDF',
      pages: (json['pages'] as num?)?.toInt() ?? 0,
      chunks: (json['chunks'] as num?)?.toInt() ?? 0,
    );
  }
}
