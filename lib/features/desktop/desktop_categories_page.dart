part of 'desktop_shell_screen_v2.dart';

class DesktopCategoriesPage extends StatelessWidget {
  const DesktopCategoriesPage({
    super.key,
    required this.categories,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ItemCategory> categories;
  final bool canManage;
  final VoidCallback onAdd;
  final Future<void> Function({ItemCategory? category}) onEdit;
  final Future<void> Function(ItemCategory category) onDelete;

  @override
  Widget build(BuildContext context) {
    return DesktopSimpleListPage<ItemCategory>(
      title: 'Kategori',
      subtitle: 'Atur sistem penamaan yang dipakai saat peralatan didaftarkan dan dirawat.',
      actionLabel: 'Tambah kategori',
      onAction: canManage ? onAdd : null,
      items: categories,
      searchHint: 'Cari nama kategori atau status',
      searchText: (category) => '${category.name} ${category.isActive ? 'aktif' : 'nonaktif'}',
      itemBuilder: (category) => DesktopSimpleTile(
        title: category.name,
        subtitle: category.isActive ? 'Tersedia untuk registrasi barang' : 'Disembunyikan dari alur registrasi',
        status: category.isActive ? 'Aktif' : 'Nonaktif',
        onEdit: canManage ? () => onEdit(category: category) : null,
        onDelete: canManage ? () => onDelete(category) : null,
      ),
    );
  }
}
