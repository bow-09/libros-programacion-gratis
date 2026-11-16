class Book {
  const Book({
    required this.id,
    required this.title,
    required this.url,
    required this.formats,
    required this.categoryId,
    required this.categoryTitle,
    this.author,
    this.pdfUrl,
    this.epubUrl,
    this.note,
  });

  final String id;
  final String title;
  final String url;
  final List<String> formats;
  final String categoryId;
  final String categoryTitle;
  final String? author;
  final String? pdfUrl;
  final String? epubUrl;
  final String? note;

  factory Book.fromJson(Map<String, dynamic> json, BookCategory category) => Book(
    id: json['id'] as String,
    title: json['titulo'] as String,
    url: json['url'] as String,
    formats: (json['formatos'] as List).cast<String>(),
    categoryId: category.id,
    categoryTitle: category.title,
    author: json['autor'] as String?,
    pdfUrl: json['pdfUrl'] as String?,
    epubUrl: json['epubUrl'] as String?,
    note: json['nota'] as String?,
  );
}

class BookCategory {
  BookCategory({
    required this.id,
    required this.title,
    required this.group,
    required this.description,
  });

  final String id;
  final String title;
  final String group;
  final String description;
  final List<Book> books = [];

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    final category = BookCategory(
      id: json['id'] as String,
      title: json['titulo'] as String,
      group: json['grupo'] as String,
      description: json['descripcion'] as String,
    );
    for (final b in json['libros'] as List) {
      category.books.add(Book.fromJson(b as Map<String, dynamic>, category));
    }
    return category;
  }
}

class Catalog {
  Catalog(this.categories)
    : books = [for (final c in categories) ...c.books],
      _byId = {
        for (final c in categories)
          for (final b in c.books) b.id: b,
      };

  final List<BookCategory> categories;
  final List<Book> books;
  final Map<String, Book> _byId;

  Book? byId(String id) => _byId[id];

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog([
    for (final c in json['categorias'] as List) BookCategory.fromJson(c as Map<String, dynamic>),
  ]);

  List<Book> search({String query = '', String? categoryId, String? format}) {
    final q = normalize(query);
    return [
      for (final b in books)
        if ((categoryId == null || b.categoryId == categoryId) &&
            (format == null || b.formats.contains(format)) &&
            (q.isEmpty ||
                normalize('${b.title} ${b.author ?? ''} ${b.categoryTitle}').contains(q)))
          b,
    ];
  }
}

const _accents = {
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
};

/// Minúsculas y sin tildes, para que "programacion" encuentre "Programación".
String normalize(String value) =>
    value.toLowerCase().split('').map((c) => _accents[c] ?? c).join().trim();
