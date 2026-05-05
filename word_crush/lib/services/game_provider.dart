import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grid_cell.dart';
import '../models/letter_points.dart';
import 'word_service.dart';

class GameRecord {
  final int id;
  final String playerName;
  final String date;
  final String gridSize;
  final int score;
  final int wordCount;
  final String longestWord; 
  final String duration;
  final int durationSeconds;

  GameRecord({
    required this.id,
    required this.playerName,
    required this.date,
    required this.gridSize,
    required this.score,
    required this.wordCount,
    required this.longestWord,
    required this.duration,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerName': playerName,
        'date': date,
        'gridSize': gridSize,
        'score': score,
        'wordCount': wordCount,
        'longestWord': longestWord,
        'duration': duration,
        'durationSeconds': durationSeconds,
      };
  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
      id: json['id'],
      playerName: json['playerName'] ?? "Anonim",
      date: json['date'],
      gridSize: json['gridSize'],
      score: json['score'],
      wordCount: json['wordCount'],
      longestWord: json['longestWord'],
      duration: json['duration'],
      durationSeconds: json['durationSeconds'] ?? 0);
}

class GameProvider with ChangeNotifier {
  final WordService _wordService = WordService();

  String userName = "";
  int gold = 100000;
  List<GameRecord> gameHistory = [];

  Map<String, int> jokers = {
    'balik': 0,
    'tekerlek': 0,
    'lolipop': 0,
    'degistirme': 0,
    'karistirma': 0,
    'parti': 0,
  };

  String? activeJoker;
  Offset? firstSwapCell;

  int score = 0;
  int movesLeft = 25;
  int gridSize = 8;
  List<List<GridCell>> grid = [];
  List<Offset> selectedIndices = [];
  String currentWord = "";
  List<String> lastComboWords = [];
  int lastComboCount = 0;
  int possibleWordCount = 0;
  bool isProcessing = false;
  bool isGameOver = false;

  int sessionWordCount = 0;
  String sessionLongestWord = "";
  DateTime? sessionStartTime;

  final Map<String, double> letterFrequencies = {
    'A': 11.92,
    'E': 8.91,
    'İ': 8.66,
    'L': 5.92,
    'R': 6.72,
    'N': 4.5,
    'K': 4.66,
    'M': 3.75,
    'T': 3.31,
    'S': 3.01,
    'Y': 2.85,
    'D': 4.7,
    'H': 1.15,
    'U': 3.24,
    'O': 2.47,
    'B': 2.84,
    'Ü': 1.85,
    'Ş': 1.78,
    'Z': 1.5,
    'C': 1.39,
    'P': 0.88,
    'Ç': 1.15,
    'G': 1.25,
    'Ğ': 1.13,
    'Ö': 0.77,
    'I': 5.11,
    'F': 0.46,
    'V': 0.98,
    'J': 0.05,
  };

  Future<void> init() async {
    await _wordService.loadDictionary();
    await loadGlobalData();
    if (userName.isNotEmpty) {
      await loadUserData(userName);
    }
    _generateGrid();
  }

  Future<void> loadGlobalData() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('currentUserName') ?? "";
    final historyJson = prefs.getStringList('gameHistory') ?? [];
    gameHistory = historyJson
        .map((item) => GameRecord.fromJson(jsonDecode(item)))
        .toList();
    notifyListeners();
  }

  Future<void> loadUserData(String name) async {
    final prefs = await SharedPreferences.getInstance();
    userName = name;
    await prefs.setString('currentUserName', name);

    gold = prefs.getInt('${name}_gold') ?? 100000;

    String? jokerJson = prefs.getString('${name}_jokers');
    if (jokerJson != null) {
      Map<String, dynamic> decoded = jsonDecode(jokerJson);
      jokers = decoded.map((key, value) => MapEntry(key, value as int));
    } else {
      jokers = {
        'balik': 0,
        'tekerlek': 0,
        'lolipop': 0,
        'degistirme': 0,
        'karistirma': 0,
        'parti': 0
      };
    }
    notifyListeners();
  }

  Future<void> updateUserName(String newName) async {
    await loadUserData(newName);
    notifyListeners();
  }

  Future<void> _saveUserData() async {
    if (userName.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${userName}_gold', gold);
    await prefs.setString('${userName}_jokers', jsonEncode(jokers));
  }

  Future<void> buyJoker(String type, int price) async {
    if (gold >= price) {
      gold -= price;
      jokers[type] = (jokers[type] ?? 0) + 1;
      await _saveUserData();
      notifyListeners();
    }
  }

  Future<void> saveGameResult() async {
    final sessionEndTime = DateTime.now();
    String durationStr = "0 sn";
    int durationSec = 0;
    if (sessionStartTime != null) {
      final diff = sessionEndTime.difference(sessionStartTime!);
      durationSec = diff.inSeconds;
      durationStr =
          diff.inMinutes > 0 ? "${diff.inMinutes} dk" : "${diff.inSeconds} sn";
    }
    final newRecord = GameRecord(
      id: gameHistory.length + 1,
      playerName: userName.isEmpty ? "Oyuncu" : userName,
      date:
          "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}",
      gridSize: "${gridSize}x$gridSize",
      score: score,
      wordCount: sessionWordCount,
      longestWord: sessionLongestWord,
      duration: durationStr,
      durationSeconds: durationSec,
    );
    gameHistory.insert(0, newRecord);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'gameHistory', gameHistory.map((e) => jsonEncode(e.toJson())).toList());
    await _saveUserData();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    gameHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gameHistory');
    notifyListeners();
  }

  void selectJoker(String type) {
    if (isGameOver) return;
    if ((jokers[type] ?? 0) > 0 && !isProcessing) {
      if (activeJoker == 'degistirme' && firstSwapCell != null) {
        grid[firstSwapCell!.dx.toInt()][firstSwapCell!.dy.toInt()].isSelected = false;
      }
      activeJoker = type;
      firstSwapCell = null;
      if (type == 'balik') {
        _useBalikJoker();
      } else if (type == 'karistirma') {
        _useKaristirmaJoker();
      } else if (type == 'parti') {
        _usePartiJoker();
      }
      notifyListeners();
    }
  }

  void _useBalikJoker() async {
    isProcessing = true;
    jokers['balik'] = jokers['balik']! - 1;
    activeJoker = null;
    
    // Set kullanarak 5 farklı ve dolu hücre seç
    Set<String> selected = {};
    int attempts = 0;
    while (selected.length < 5 && attempts < 100) {
      int r = Random().nextInt(gridSize);
      int c = Random().nextInt(gridSize);
      if (grid[r][c].letter != "") {
        selected.add("$r,$c");
      }
      attempts++;
    }
    
    // Patlatma animasyonunu tetikle
    for (String coord in selected) {
      var parts = coord.split(',');
      int r = int.parse(parts[0]);
      int c = int.parse(parts[1]);
      grid[r][c].isExploding = true;
    }
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 350));
    
    // Hücreleri temizle
    for (String coord in selected) {
      var parts = coord.split(',');
      int r = int.parse(parts[0]);
      int c = int.parse(parts[1]);
      grid[r][c] = GridCell(letter: "", points: 0);
    }
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 150));
    _applyGravity();
    await _saveUserData();
    _updatePossibleWordCount();
    if (possibleWordCount == 0) shuffleGrid();
    isProcessing = false;
    notifyListeners();
  }

  void _useKaristirmaJoker() async {
    isProcessing = true;
    jokers['karistirma'] = jokers['karistirma']! - 1;
    activeJoker = null;

    // PDF: Mevcut harflerin pozisyonlarını karıştır (yeni harf üretme)
    List<GridCell> allCells = [];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        allCells.add(grid[r][c]);
      }
    }
    allCells.shuffle(Random());
    int index = 0;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        grid[r][c] = allCells[index++];
      }
    }

    _updatePossibleWordCount();
    // Eğer karıştırma sonrası kelime yoksa bir daha karıştır
    if (possibleWordCount == 0) {
      allCells.shuffle(Random());
      index = 0;
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          grid[r][c] = allCells[index++];
        }
      }
      _updatePossibleWordCount();
    }

    await _saveUserData();
    isProcessing = false;
    notifyListeners();
  }

  void _usePartiJoker() async {
    isProcessing = true;
    jokers['parti'] = jokers['parti']! - 1;
    activeJoker = null;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        grid[r][c] = GridCell(letter: "", points: 0);
      }
    }
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _applyGravity();
    await _saveUserData();
    _updatePossibleWordCount();
    if (possibleWordCount == 0) shuffleGrid();
    isProcessing = false;
    notifyListeners();
  }

  void handleCellTapForJoker(int r, int c) {
    if (activeJoker == 'lolipop') {
      jokers['lolipop'] = jokers['lolipop']! - 1;
      grid[r][c] = GridCell(letter: "", points: 0);
      _finishJokerAction();
    } else if (activeJoker == 'tekerlek') {
      jokers['tekerlek'] = jokers['tekerlek']! - 1;
      for (int i = 0; i < gridSize; i++) {
        grid[r][i] = GridCell(letter: "", points: 0);
        grid[i][c] = GridCell(letter: "", points: 0);
      }
      _finishJokerAction();
    } else if (activeJoker == 'degistirme') {
      if (firstSwapCell == null) {
        firstSwapCell = Offset(r.toDouble(), c.toDouble());
        grid[r][c].isSelected = true;
        notifyListeners();
      } else {
        int r1 = firstSwapCell!.dx.toInt();
        int c1 = firstSwapCell!.dy.toInt();
        if ((r1 - r).abs() <= 1 && (c1 - c).abs() <= 1) {
          GridCell temp = grid[r1][c1];
          grid[r1][c1] = grid[r][c];
          grid[r][c] = temp;
          grid[r1][c1].isSelected = false;
          grid[r][c].isSelected = false;
          jokers['degistirme'] = jokers['degistirme']! - 1;
          _finishJokerAction();
        } else {
          grid[r1][c1].isSelected = false;
          firstSwapCell = null;
          notifyListeners();
        }
      }
    }
  }

  void _finishJokerAction() async {
    isProcessing = true;
    activeJoker = null;
    firstSwapCell = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _applyGravity();
    await _saveUserData();
    _updatePossibleWordCount();
    if (possibleWordCount == 0) shuffleGrid();
    isProcessing = false;
    notifyListeners();
  }

  void _applyGravity() {
    for (int c = 0; c < gridSize; c++) {
      List<GridCell> column = [];
      for (int r = gridSize - 1; r >= 0; r--) {
        if (grid[r][c].letter != "") {
          column.add(grid[r][c]);
        }
      }
      // Yeni üretilen hücreleri isDropping olarak işaretle (düşme animasyonu)
      while (column.length < gridSize) {
        GridCell newCell = _getRandomCell();
        newCell.isDropping = true;
        column.add(newCell);
      }
      for (int r = 0; r < gridSize; r++) {
        grid[gridSize - 1 - r][c] = column[r];
      }
    }
    notifyListeners();

    // Kısa bir süre sonra düşme animasyonunu kaldır
    Future.delayed(const Duration(milliseconds: 400), () {
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          grid[r][c].isDropping = false;
        }
      }
      notifyListeners();
    });
  }

  void initializeGame(int size, int moves) {
    gridSize = size;
    movesLeft = moves;
    score = 0;
    sessionWordCount = 0;
    sessionLongestWord = "";
    sessionStartTime = DateTime.now();
    isGameOver = false;
    isProcessing = false;
    activeJoker = null;
    firstSwapCell = null;
    lastComboCount = 0;
    lastComboWords = [];
    _generateGrid();
    _updatePossibleWordCount();
    notifyListeners();
  }

  void findHints() {
    Set<String> foundWords = _getAllPossibleWords();
    debugPrint("💡 Bulunabilir Kelimeler: $foundWords");
  }

  Set<String> _getAllPossibleWords() {
    Set<String> foundWords = {};
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        _dfsCollect(r, c, "", [], foundWords);
      }
    }
    return foundWords;
  }

  void _dfsCollect(
      int r, int c, String current, List<Offset> visited, Set<String> found) {
    String word = current + grid[r][c].letter;
    if (!_wordService.isValidPrefix(word)) return;
    
    if (word.length >= 3 && _wordService.isValidWord(word)) {
      found.add(word);
    }
    if (word.length >= 10) return; // Prefix koruması sayesinde 10'a kadar çıkabiliriz
    visited.add(Offset(r.toDouble(), c.toDouble()));
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        int nr = r + dr;
        int nc = c + dc;
        if (nr >= 0 &&
            nr < gridSize &&
            nc >= 0 &&
            nc < gridSize &&
            !visited.contains(Offset(nr.toDouble(), nc.toDouble()))) {
          _dfsCollect(nr, nc, word, List.from(visited), found);
        }
      }
    }
  }

  void _updatePossibleWordCount() {
    // PDF Kural 8/9: Ortak harf kullanmayacak şekilde kelime sayısı
    possibleWordCount = _wordService.findPossibleWords(grid, gridSize).length;
    notifyListeners();
  }

  void _generateGrid() {
    // PDF Kural: Tamamen rastgele yerine kurallı harf üretimi uygulanır.
    // Türkçe harf frekansları, komşuluk ilişkileri ve sözlük kontrolü
    // dikkate alınarak grid üzerinde en az 1 anlamlı kelime oluşacak
    // şekilde harf yerleşimi düzenlenir.

    // Adım 1: Frekans tabanlı rastgele doldur
    grid = List.generate(
        gridSize, (r) => List.generate(gridSize, (c) => _getRandomCell()));

    // Adım 2: Grid üzerinde en az 1 kelime olacak şekilde
    // sözlükten kelime(ler) yerleştir
    if (!_hasPossibleWords()) {
      _plantWordsIntoGrid();
    }

    // Adım 3: Güvenlik — hala kelime yoksa tekrar dene
    int retries = 0;
    while (!_hasPossibleWords() && retries < 20) {
      grid = List.generate(
          gridSize, (r) => List.generate(gridSize, (c) => _getRandomCell()));
      _plantWordsIntoGrid();
      retries++;
    }

    _updatePossibleWordCount();
  }

  /// Sözlükten rastgele kelimeler seçip grid üzerine komşuluk kurallarına
  /// uygun şekilde yerleştirir. Bu sayede grid her zaman çözülebilir olur.
  void _plantWordsIntoGrid() {
    final random = Random();

    // Sözlükten grid boyutuna uygun kelimeleri filtrele (3-6 harf arası)
    int maxLen = gridSize < 8 ? 4 : 6;
    List<String> candidates = _wordService.getWordsInRange(3, maxLen);
    if (candidates.isEmpty) return;

    // Daha kolay kelime bulunabilmesi için grid boyutunun 2 katı kadar kelime yerleştir
    int wordsToPlant = gridSize * 2;

    for (int w = 0; w < wordsToPlant; w++) {
      candidates.shuffle(random);

      for (int attempt = 0; attempt < 10; attempt++) {
        String word = candidates[random.nextInt(candidates.length)];
        if (_tryPlaceWord(word, random)) break;
      }
    }
  }

  /// Bir kelimeyi grid üzerinde rastgele bir konuma, komşuluk kurallarına
  /// uygun olarak yerleştirmeye çalışır.
  bool _tryPlaceWord(String word, Random random) {
    int startR = random.nextInt(gridSize);
    int startC = random.nextInt(gridSize);

    // DFS ile kelimenin harflerini komşu hücrelere yerleştir
    List<List<int>> path = [];
    Set<String> visited = {};

    if (_placeLetterDFS(word, 0, startR, startC, path, visited, random)) {
      // Başarılı — harfleri grid'e yaz
      for (int i = 0; i < path.length; i++) {
        int r = path[i][0];
        int c = path[i][1];
        String letter = word[i].toUpperCase();
        grid[r][c] = GridCell(
          letter: letter,
          points: LetterPoints.points[letter] ?? 1,
        );
      }
      return true;
    }
    return false;
  }

  bool _placeLetterDFS(String word, int charIndex, int r, int c,
      List<List<int>> path, Set<String> visited, Random random) {
    if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) return false;
    if (visited.contains('$r,$c')) return false;

    visited.add('$r,$c');
    path.add([r, c]);

    if (charIndex == word.length - 1) return true; // Tüm harfler yerleşti

    // 8 yönü karıştırarak dene (rastgelelik için)
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];
    directions.shuffle(random);

    for (var dir in directions) {
      int nr = r + dir[0];
      int nc = c + dir[1];
      if (_placeLetterDFS(word, charIndex + 1, nr, nc, path, visited, random)) {
        return true;
      }
    }

    // Backtrack
    path.removeLast();
    visited.remove('$r,$c');
    return false;
  }


  void shuffleGrid({int retryCount = 0}) {
    if (retryCount > 10) return; // Sonsuz rekürsyon koruması
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // PDF/Forum: Özel güçler korunarak harfler yeniden oluşturulmalıdır
        String? existingPower = grid[r][c].specialPower;
        GridCell newCell = _getRandomCell();
        
        grid[r][c] = GridCell(
          letter: newCell.letter,
          points: newCell.points,
          specialPower: existingPower, // Gücü koru!
        );
      }
    }
    _updatePossibleWordCount();
    if (possibleWordCount == 0) {
      shuffleGrid(retryCount: retryCount + 1);
    }
    notifyListeners();
  }

  GridCell _getRandomCell() {
    double totalWeight = letterFrequencies.values.reduce((a, b) => a + b);
    double randomValue = Random().nextDouble() * totalWeight;
    double currentWeight = 0;
    String selectedLetter = 'A';
    for (var entry in letterFrequencies.entries) {
      currentWeight += entry.value;
      if (randomValue <= currentWeight) {
        selectedLetter = entry.key;
        break;
      }
    }
    return GridCell(
        letter: selectedLetter,
        points: LetterPoints.points[selectedLetter] ?? 1);
  }

  void onCellTap(int row, int col) {
    if (isProcessing || isGameOver) return;
    if (activeJoker != null) {
      handleCellTapForJoker(row, col);
      return;
    }
    if (selectedIndices.isEmpty) {
      _selectCell(row, col);
    } else {
      Offset last = selectedIndices.last;
      if ((last.dx - row).abs() <= 1 && (last.dy - col).abs() <= 1) {
        if (!selectedIndices
            .contains(Offset(row.toDouble(), col.toDouble()))) {
          _selectCell(row, col);
        }
      }
    }
  }

  void _selectCell(int row, int col) {
    grid[row][col].isSelected = true;
    selectedIndices.add(Offset(row.toDouble(), col.toDouble()));
    currentWord += grid[row][col].letter;
    notifyListeners();
  }

  Future<void> submitWord() async {
    if (isProcessing || isGameOver || activeJoker != null) return;
    
    final int wordLength = currentWord.length;
    if (wordLength == 0) return; // Hiçbir şey seçilmediyse hamle gitmesin

    isProcessing = true;
    lastComboWords = [];
    notifyListeners();

    // PDF Kuralı: Hamle yalnızca kelime denemesi (3+ harf) yapıldığında düşer
    if (movesLeft > 0 && wordLength >= 3) {
      movesLeft--;
    }

    if (wordLength >= 3 && _wordService.isValidWord(currentWord)) {
      await _processValidWord();
    } else {
      _resetSelection();
    }

    if (movesLeft == 0) {
      isGameOver = true;
      await saveGameResult();
    } else {
      _updatePossibleWordCount();
      if (possibleWordCount == 0) {
        shuffleGrid();
      }
    }
    
    isProcessing = false;
    notifyListeners();
  }

  Future<void> _processValidWord() async {
    sessionWordCount++;
    if (currentWord.length > sessionLongestWord.length) {
      sessionLongestWord = currentWord;
    }
    Set<Offset> totalExplosion = Set.from(selectedIndices);
    for (var pos in selectedIndices) {
      String? power = grid[pos.dx.toInt()][pos.dy.toInt()].specialPower;
      if (power != null) {
        _activatePower(pos.dx.toInt(), pos.dy.toInt(), power, totalExplosion);
      }
    }
    // PDF kuralı: Puan, kelimenin harf puanlarından hesaplanır
    int wordScore = LetterPoints.calculateScore(currentWord);
    List<String> subWords = _wordService.findSubWords(currentWord);
    lastComboWords = subWords;
    lastComboCount = subWords.length + 1; // Ana kelime + alt kelimeler

    for (var sub in subWords) {
      wordScore += LetterPoints.calculateScore(sub);
    }
    score += wordScore;
    gold += (wordScore ~/ 2);
    _checkSpecialPowers();

    // Adım 1: Patlatılacak hücreleri isExploding olarak işaretle
    Offset lastPos = selectedIndices.last;
    for (var pos in totalExplosion) {
      if (pos == lastPos && currentWord.length >= 4) continue;
      grid[pos.dx.toInt()][pos.dy.toInt()].isExploding = true;
    }
    notifyListeners();

    // Adım 2: Patlatma animasyonu için bekle
    await Future.delayed(const Duration(milliseconds: 350));

    // Adım 3: Patlatılan hücreleri boşalt
    for (var pos in totalExplosion) {
      if (pos == lastPos && currentWord.length >= 4) continue;
      grid[pos.dx.toInt()][pos.dy.toInt()] = GridCell(letter: "", points: 0);
    }
    notifyListeners();

    // Adım 4: Yerçekimi (düşme animasyonu _applyGravity içinde)
    await Future.delayed(const Duration(milliseconds: 150));
    _applyGravity();
    _resetSelection();
  }

  void _activatePower(int r, int c, String type, Set<Offset> explosionSet) {
    if (type == "row") {
      for (int i = 0; i < gridSize; i++) {
        explosionSet.add(Offset(r.toDouble(), i.toDouble()));
      }
    } else if (type == "column") {
      for (int i = 0; i < gridSize; i++) {
        explosionSet.add(Offset(i.toDouble(), c.toDouble()));
      }
    } else if (type == "area") {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          int nr = r + dr;
          int nc = c + dc;
          if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
            explosionSet.add(Offset(nr.toDouble(), nc.toDouble()));
          }
        }
      }
    } else if (type == "mega") {
      for (int dr = -2; dr <= 2; dr++) {
        for (int dc = -2; dc <= 2; dc++) {
          int nr = r + dr;
          int nc = c + dc;
          if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
            explosionSet.add(Offset(nr.toDouble(), nc.toDouble()));
          }
        }
      }
    }
  }

  void _checkSpecialPowers() {
    if (currentWord.length < 4) return;
    Offset last = selectedIndices.last;
    int r = last.dx.toInt();
    int c = last.dy.toInt();
    if (currentWord.length == 4) {
      grid[r][c].specialPower = "row";
    } else if (currentWord.length == 5) {
      grid[r][c].specialPower = "area";
    } else if (currentWord.length == 6) {
      grid[r][c].specialPower = "column";
    } else if (currentWord.length >= 7) {
      grid[r][c].specialPower = "mega";
    }
  }

  void _resetSelection() {
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        grid[r][c].isSelected = false;
      }
    }
    selectedIndices.clear();
    currentWord = "";
  }

  void cancelSelection() {
    _resetSelection();
    notifyListeners();
  }

  bool _hasPossibleWords() {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (_dfsCheck(r, c, "", [])) return true;
      }
    }
    return false;
  }

  bool _dfsCheck(int r, int c, String current, List<Offset> visited) {
    String nextWord = current + grid[r][c].letter;
    if (!_wordService.isValidPrefix(nextWord)) return false;
    if (nextWord.length >= 3 && _wordService.isValidWord(nextWord)) return true;
    if (nextWord.length >= 8) return false;
    visited.add(Offset(r.toDouble(), c.toDouble()));
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        int nr = r + dr;
        int nc = c + dc;
        if (nr >= 0 &&
            nr < gridSize &&
            nc >= 0 &&
            nc < gridSize &&
            !visited.contains(Offset(nr.toDouble(), nc.toDouble()))) {
          if (_dfsCheck(nr, nc, nextWord, List.from(visited))) return true;
        }
      }
    }
    return false;
  }
}
