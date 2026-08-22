class SourceChunk {
  const SourceChunk({
    required this.chunk,
    required this.chunkIndex,
    required this.score,
    required this.text,
    required this.filename,
    required this.page,
  });

  final int chunk;
  final int chunkIndex;
  final double score;
  final String text;
  final String filename;
  final int? page;

  factory SourceChunk.fromJson(Map<String, dynamic> json) {
    return SourceChunk(
      chunk: (json['chunk'] as num?)?.toInt() ?? 0,
      chunkIndex: (json['chunk_index'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      text: json['text'] as String? ?? '',
      filename: json['filename'] as String? ?? 'Unknown PDF',
      page: (json['page'] as num?)?.toInt(),
    );
  }
}

class AskResponse {
  const AskResponse({
    required this.question,
    required this.answer,
    required this.sources,
  });

  final String question;
  final String answer;
  final List<SourceChunk> sources;

  factory AskResponse.fromJson(Map<String, dynamic> json) {
    final sourcesJson = json['sources'];
    final sources = <SourceChunk>[];
    if (sourcesJson is List) {
      for (final item in sourcesJson) {
        if (item is Map<String, dynamic>) {
          sources.add(SourceChunk.fromJson(item));
        }
      }
    }

    return AskResponse(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      sources: sources,
    );
  }
}
