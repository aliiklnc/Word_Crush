class GridCell {
  final String letter;
  final int points;
  bool isSelected;
  bool isExploding; // Patlatma animasyonu için
  bool isDropping;  // Düşme animasyonu için
  String? specialPower; // "row", "column", "area", "mega"

  GridCell({
    required this.letter,
    required this.points,
    this.isSelected = false,
    this.isExploding = false,
    this.isDropping = false,
    this.specialPower,
  });
}
