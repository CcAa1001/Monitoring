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
      title: tr('Kategori'),
      subtitle: tr('Atur sistem penamaan yang dipakai saat peralatan didaftarkan dan dirawat.'),
      actionLabel: tr('Tambah kategori'),
      onAction: canManage ? onAdd : null,
      items: categories,
      searchHint: tr('Cari nama kategori atau status'),
      searchText: (category) => '${category.name} ${category.isActive ? tr('aktif') : tr('nonaktif')}',
      itemBuilder: (category) => DesktopSimpleTile(
        title: category.name,
        subtitle: category.isActive ? tr('Tersedia untuk registrasi barang') : tr('Disembunyikan dari alur registrasi'),
        status: category.isActive ? tr('Aktif') : tr('Nonaktif'),
        onEdit: canManage ? () => onEdit(category: category) : null,
        onDelete: canManage ? () => onDelete(category) : null,
      ),
    );
  }
}
