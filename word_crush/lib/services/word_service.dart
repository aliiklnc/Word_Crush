import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/grid_cell.dart';

class WordService {
  Set<String> _dictionary = {};
  Set<String> _prefixes = {};

  Future<void> loadDictionary() async {
    try {
      final String response = await rootBundle.loadString('assets/words.json');
      final data = await json.decode(response);
      _dictionary = Set<String>.from(data['words']);
      
      for (String word in _dictionary) {
        for (int i = 1; i <= word.length; i++) {
          _prefixes.add(word.substring(0, i));
        }
      }
      
      print("Sözlük yüklendi: ${_dictionary.length} kelime. Önekler: ${_prefixes.length}");
    } catch (e) {
      print("Sözlük yükleme hatası: $e");
    }
  }

  bool isValidWord(String word) {
    return _dictionary.contains(word.toUpperCase());
  }
  
  bool isValidPrefix(String prefix) {
    return _prefixes.contains(prefix.toUpperCase());
  }

  /// Sözlükten belirli uzunluk aralığındaki kelimeleri döndürür.
  /// Kurallı harf üretimi için kullanılır.
  List<String> getWordsInRange(int minLen, int maxLen) {
    return _dictionary
        .where((w) => w.length >= minLen && w.length <= maxLen)
        .toList();
  }

  List<String> findSubWords(String mainWord) {
    Set<String> found = {};
    if (mainWord.length < 3) return [];

    for (int i = 0; i < mainWord.length; i++) {
      for (int j = i + 3; j <= mainWord.length; j++) {
        String sub = mainWord.substring(i, j);
        // Ana kelimenin kendisini de iç kelime sayabiliriz (PDF öyle diyor)
        // ama GameProvider'da ana kelime zaten hesaplandığı için burada ek puan getirmemeli
        if (sub != mainWord && isValidWord(sub)) {
          found.add(sub);
        }
      }
    }
    return found.toList();
  }

  // PDF Kural 8/9: Ortak harf kullanmayacak şekilde kelime sayısını bulur
  List<String> findPossibleWords(List<List<GridCell>> grid, int gridSize) {
    List<String> foundWords = [];
    Set<String> usedCells = {};

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (usedCells.contains('$r,$c') || grid[r][c].letter == "") continue;

        List<List<int>>? path = _findAnyWordFrom(r, c, grid, gridSize, usedCells);
        if (path != null) {
          String word = path.map((p) => grid[p[0]][p[1]].letter).join();
          foundWords.add(word);
          for (var p in path) {
            usedCells.add('${p[0]},${p[1]}');
          }
        }
      }
    }
    return foundWords;
  }

  List<List<int>>? _findAnyWordFrom(int r, int c, List<List<GridCell>> grid, int gridSize, Set<String> globalUsed) {
    List<List<int>> path = [[r, c]];
    Set<String> currentPathUsed = {'$r,$c'};
    return _dfsFind(r, c, grid, gridSize, path, currentPathUsed, globalUsed);
  }

  List<List<int>>? _dfsFind(int r, int c, List<List<GridCell>> grid, int gridSize, List<List<int>> path, Set<String> currentPathUsed, Set<String> globalUsed) {
    String currentWord = path.map((p) => grid[p[0]][p[1]].letter).join();

    if (!isValidPrefix(currentWord)) return null;

    if (currentWord.length >= 3 && isValidWord(currentWord)) {
      return List.from(path);
    }

    if (currentWord.length >= 10) return null; // Derinlik artırılabilir, prefix check korur

    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        int nr = r + dr;
        int nc = c + dc;

        if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize &&
            grid[nr][nc].letter != "" &&
            !globalUsed.contains('$nr,$nc') &&
            !currentPathUsed.contains('$nr,$nc')) {
          
          path.add([nr, nc]);
          currentPathUsed.add('$nr,$nc');
          
          var result = _dfsFind(nr, nc, grid, gridSize, path, currentPathUsed, globalUsed);
          if (result != null) return result;

          path.removeLast();
          currentPathUsed.remove('$nr,$nc');
        }
      }
    }
    return null;
  }
}
