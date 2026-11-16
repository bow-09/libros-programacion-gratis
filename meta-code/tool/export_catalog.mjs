// Genera assets/data/libros_catalogo.json a partir del catálogo de librosgratis.dev.
// Uso: node meta-code/tool/export_catalog.mjs   (desde la raíz del repositorio, Node >= 22.18)
import { writeFileSync } from 'node:fs';
import { librarySections, getLocalPdfBook } from '../../web/src/data/library.ts';

const SITE = 'https://librosgratis.dev';
const abs = (href) => (href ? (href.startsWith('/') ? SITE + href : href) : undefined);

const categorias = librarySections.map((s) => ({
  id: s.slug,
  titulo: s.title,
  grupo: s.group,
  descripcion: s.description,
  libros: s.books.map((original) => {
    const b = getLocalPdfBook(original) ?? original; // añade el EPUB local si existe
    return {
    id: b.id,
    titulo: b.title,
    autor: b.author ?? null,
    formatos: b.formats ?? [],
    url: abs(b.href),
    pdfUrl: abs(b.pdfHref ?? (/\.pdf$/i.test(b.href) ? b.href : undefined)) ?? null,
    epubUrl: abs(b.epubHref) ?? null,
    nota: b.note ?? null,
    };
  }),
}));

const out = {
  fuente: 'https://github.com/midudev/libros-programacion-gratis',
  totalCategorias: categorias.length,
  totalLibros: categorias.reduce((n, c) => n + c.libros.length, 0),
  categorias,
};
writeFileSync(new URL('../assets/data/libros_catalogo.json', import.meta.url), JSON.stringify(out, null, 2) + '\n');
console.log(`${out.totalLibros} libros en ${out.totalCategorias} categorías`);
