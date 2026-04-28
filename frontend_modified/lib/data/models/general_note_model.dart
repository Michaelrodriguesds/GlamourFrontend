/// Modelo de Anotação Geral — alinhado com backend Note schema
class GeneralNote {
  final String   id;
  final String   title;
  final String   content;
  final String   tag;      // lembrete | financeiro | estoque | geral
  final String   color;    // hex color string (#B47FD4)
  final bool     pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeneralNote({
    required this.id,
    required this.title,
    required this.content,
    required this.tag,
    required this.color,
    required this.pinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GeneralNote.fromJson(Map<String, dynamic> json) {
    // Suporta campo "tag" (string, novo backend) e retrocompatibilidade
    // com "tags" (array, caso venha de versão antiga)
    String resolvedTag = 'geral';
    final rawTag  = json['tag'];
    final rawTags = json['tags'];
    if (rawTag != null && rawTag is String && rawTag.isNotEmpty) {
      resolvedTag = rawTag;
    } else if (rawTags != null && rawTags is List && rawTags.isNotEmpty) {
      resolvedTag = rawTags.first.toString();
    }

    return GeneralNote(
      id:        json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title:     json['title']     ?? '',
      content:   json['content']   ?? '',
      tag:       resolvedTag,
      color:     json['color']     ?? '#B47FD4',
      pinned:    json['pinned']    ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title':   title,
    'content': content,
    'tag':     tag,      // ← envia como string simples (backend espera "tag")
    'color':   color,
    'pinned':  pinned,
  };

  GeneralNote copyWith({
    String?   id,
    String?   title,
    String?   content,
    String?   tag,
    String?   color,
    bool?     pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      GeneralNote(
        id:        id        ?? this.id,
        title:     title     ?? this.title,
        content:   content   ?? this.content,
        tag:       tag       ?? this.tag,
        color:     color     ?? this.color,
        pinned:    pinned    ?? this.pinned,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}