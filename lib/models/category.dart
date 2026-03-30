class Category {
  final int? id;
  final String name;
  final String icon;
  final int color;

  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'],
        name: map['name'],
        icon: map['icon'],
        color: map['color'],
      );

  static List<Category> get defaults => [
        Category(id: 1, name: 'Alimentation', icon: '🍔', color: 0xFFFF6B6B),
        Category(id: 2, name: 'Transport', icon: '🚗', color: 0xFF4ECDC4),
        Category(id: 3, name: 'Santé', icon: '🏥', color: 0xFF45B7D1),
        Category(id: 4, name: 'Shopping', icon: '🛍️', color: 0xFFF9CA24),
        Category(id: 5, name: 'Famille', icon: '👨‍👩‍👧', color: 0xFF6C5CE7),
        Category(id: 6, name: 'Télécom', icon: '📱', color: 0xFFA29BFE),
        Category(id: 7, name: 'Transfert', icon: '💸', color: 0xFF00B894),
        Category(id: 8, name: 'Autre', icon: '📦', color: 0xFFB2BEC3),
      ];
}
