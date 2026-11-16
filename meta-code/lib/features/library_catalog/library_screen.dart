import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/links.dart';
import 'library_models.dart';
import 'library_providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';
  String? _categoryId;
  String? _format;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar el catálogo: $e')),
        data: (data) {
          final results = data.search(query: _query, categoryId: _categoryId, format: _format);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por título, autor o tema',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Categoría'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todas')),
                          for (final c in data.categories)
                            DropdownMenuItem(value: c.id, child: Text(c.title)),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _format,
                        decoration: const InputDecoration(labelText: 'Formato'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: 'HTML', child: Text('Web')),
                          DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                          DropdownMenuItem(value: 'EPUB', child: Text('EPUB')),
                        ],
                        onChanged: (v) => setState(() => _format = v),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${results.length} de ${data.books.length} libros',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? const Center(child: Text('Ningún libro coincide con la búsqueda.'))
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, i) => BookTile(book: results[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BookTile extends StatelessWidget {
  const BookTile({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final subtitle = [?book.author, book.categoryTitle].join(' · ');
    return ListTile(
      title: Text(book.title),
      subtitle: Text(subtitle),
      trailing: Text(book.formats.join(' · '), style: Theme.of(context).textTheme.labelSmall),
      onTap: () => showBookSheet(context, book),
    );
  }
}

void showBookSheet(BuildContext context, Book book) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title, style: Theme.of(context).textTheme.titleLarge),
            if (book.author != null) Text(book.author!),
            if (book.note != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(book.note!)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => openLink(context, book.url),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir'),
                ),
                if (book.pdfUrl != null && book.pdfUrl != book.url)
                  OutlinedButton(
                    onPressed: () => openLink(context, book.pdfUrl!),
                    child: const Text('PDF'),
                  ),
                if (book.epubUrl != null)
                  OutlinedButton(
                    onPressed: () => openLink(context, book.epubUrl!),
                    child: const Text('EPUB'),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
