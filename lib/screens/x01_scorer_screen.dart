import 'package:flutter/material.dart';

/// Dart-Eingabe-Modifikator für den aktuellen Pfeil
enum InputMultiplier { single, double, triple }

/// Modell für einen einzelnen geworfenen Pfeil
class DartThrow {
  final int baseValue;
  final InputMultiplier multiplier;

  DartThrow({required this.baseValue, this.multiplier = InputMultiplier.single});

  int get points {
    if (baseValue == 50) return 50;
    if (baseValue == 25 && multiplier == InputMultiplier.double) return 50;
    switch (multiplier) {
      case InputMultiplier.double:
        return baseValue * 2;
      case InputMultiplier.triple:
        return baseValue * 3;
      case InputMultiplier.single:
      default:
        return baseValue;
    }
  }

  String get label {
    if (baseValue == 0) return '0';
    if (baseValue == 50) return 'BULL';
    if (baseValue == 25) return multiplier == InputMultiplier.double ? 'BULL' : '25';
    
    switch (multiplier) {
      case InputMultiplier.double:
        return 'D$baseValue';
      case InputMultiplier.triple:
        return 'T$baseValue';
      case InputMultiplier.single:
      default:
        return '$baseValue';
    }
  }
}

/// Voll responsiver X01-Scorer im Modern Dark Theme
class X01ScorerScreen extends StatefulWidget {
  final String playerId;
  final String playerName;

  const X01ScorerScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<X01ScorerScreen> createState() => _X01ScorerScreenState();
}

class _X01ScorerScreenState extends State<X01ScorerScreen> {
  // Spielzustand
  final List<int> _x01Options = [101, 201, 301, 501, 701, 901, 1001];
  int _selectedStartScore = 501;
  bool _gameStarted = false;
  
  late int _startScore;
  late int _currentRemainingScore;

  // Wurf-Verlauf
  final List<List<DartThrow>> _legHistory = [];
  final List<DartThrow> _currentTurnDarts = [];

  // Aktiver Modifikator
  InputMultiplier _activeMultiplier = InputMultiplier.single;

  // Farbpalette
  static const Color _bgDark = Color(0xFF111317);
  static const Color _cardDark = Color(0xFF1B1E26);
  static const Color _buttonDark = Color(0xFF242834);
  static const Color _neonGreen = Color(0xFF00E676);

  void _startGame() {
    setState(() {
      _startScore = _selectedStartScore;
      _currentRemainingScore = _startScore;
      _legHistory.clear();
      _currentTurnDarts.clear();
      _activeMultiplier = InputMultiplier.single;
      _gameStarted = true;
    });
  }

  void _onDartHit(int baseValue) {
    if (_currentTurnDarts.length >= 3) return;

    InputMultiplier mult = _activeMultiplier;
    if (baseValue == 50) mult = InputMultiplier.single;
    if (baseValue == 25 && mult == InputMultiplier.triple) mult = InputMultiplier.single;

    final throwResult = DartThrow(baseValue: baseValue, multiplier: mult);

    setState(() {
      _currentTurnDarts.add(throwResult);
      _activeMultiplier = InputMultiplier.single;

      final currentTurnPoints = _currentTurnDarts.fold(0, (sum, d) => sum + d.points);

      if (currentTurnPoints == _currentRemainingScore) {
        _finishTurn();
        _showWinnerDialog();
      } else if (currentTurnPoints > _currentRemainingScore || _currentRemainingScore - currentTurnPoints == 1) {
        // BUST (Überworfen oder auf 1 Punkt Rest bei Double-Out-Regel gefallen)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bust! (Überworfen)'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 1),
          ),
        );
        _currentTurnDarts.clear();
      } else if (_currentTurnDarts.length == 3) {
        _finishTurn();
      }
    });
  }

  void _finishTurn() {
    final turnPoints = _currentTurnDarts.fold(0, (sum, d) => sum + d.points);
    _currentRemainingScore -= turnPoints;
    _legHistory.add(List.from(_currentTurnDarts));
    _currentTurnDarts.clear();
  }

  void _undoLastDart() {
    setState(() {
      if (_currentTurnDarts.isNotEmpty) {
        _currentTurnDarts.removeLast();
      } else if (_legHistory.isNotEmpty) {
        final lastTurn = _legHistory.removeLast();
        final turnPoints = lastTurn.fold(0, (sum, d) => sum + d.points);
        _currentRemainingScore += turnPoints;
        _currentTurnDarts.addAll(lastTurn);
        _currentTurnDarts.removeLast();
      }
    });
  }

  // --- STATISTIK BERECHNUNGEN ---
  int get _totalDartsThrown {
    final historyDarts = _legHistory.fold(0, (sum, turn) => sum + turn.length);
    return historyDarts + _currentTurnDarts.length;
  }

  int get _totalPointsScored => _startScore - _currentRemainingScore;

  double get _overallAverage {
    if (_totalDartsThrown == 0) return 0.0;
    return (_totalPointsScored / _totalDartsThrown) * 3;
  }

  int get _lastTurnScore {
    if (_legHistory.isEmpty) return 0;
    return _legHistory.last.fold(0, (sum, d) => sum + d.points);
  }

  String? get _checkoutRecommendation {
    final remaining = _currentRemainingScore - _currentTurnDarts.fold(0, (sum, d) => sum + d.points);
    if (remaining > 170 || remaining < 2) return null;
    if (remaining == 170) return 'T20 • T20 • BULL';
    if (remaining == 141) return 'T17 • BULL • D20';
    if (remaining == 100) return 'T20 • D20';
    if (remaining == 40) return 'D20';
    if (remaining % 2 == 0 && remaining <= 40) {
      return 'D${remaining ~/ 2}';
    }
    return 'Single Setup';
  }

  void _showWinnerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text('Leg Beendet! 🎉', style: TextStyle(color: Colors.white)),
        content: Text(
          'Glückwunsch ${widget.playerName}!\nGeworfene Darts: $_totalDartsThrown\nAverage: ${_overallAverage.toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentRemainingScore = _startScore;
                _legHistory.clear();
                _currentTurnDarts.clear();
              });
            },
            child: const Text('Neues Leg', style: TextStyle(color: _neonGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: Text(
          '${_gameStarted ? _startScore : 501} • First to 3 legs • SI/DO',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: !_gameStarted ? _buildGameSetupView() : _buildActiveGameView(),
      ),
    );
  }

  /// SETUP-SCREEN (scrollbar für ganz kleine Geräte)
  Widget _buildGameSetupView() {
    return Center(
      child: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(24),
          color: _cardDark,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.gps_fixed, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'X01 Spiel konfigurieren',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  value: _selectedStartScore,
                  dropdownColor: _buttonDark,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Start-Punktzahl wählen',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange)),
                    prefixIcon: Icon(Icons.flag, color: Colors.deepOrange),
                  ),
                  items: _x01Options.map((score) {
                    return DropdownMenuItem(value: score, child: Text('$score Points'));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedStartScore = value);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'SPIEL STARTEN',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _startGame,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// HAUPTSPIEL-SCREEN (Responsiv in 2 Expanded-Blöcke geteilt)
  Widget _buildActiveGameView() {
    final currentScore = _currentRemainingScore - _currentTurnDarts.fold(0, (sum, d) => sum + d.points);

    return Column(
      children: [
        // OBERE HÄLFTE: Scoreboard, Stats, Empfehlung (Flex: 45%)
        Expanded(
          flex: 45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Verteilt Platz automatisch!
              children: [
                // 1. Spieler Karten
                Row(
                  children: [
                    Expanded(child: _buildPlayerCard(name: widget.playerName, score: currentScore.toInt(), avg: _overallAverage, isActive: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPlayerCard(name: 'Gegner', score: _startScore, avg: 0.0, isActive: false)),
                  ],
                ),

                // 2. Riesige Restpunktzahl (FittedBox verhindert Overflow)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$currentScore',
                    style: const TextStyle(fontSize: 90, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2),
                  ),
                ),

                // 3. 3-Dart-Punkte-Indikatoren
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final hasThrow = index < _currentTurnDarts.length;
                    final label = hasThrow ? _currentTurnDarts[index].label : '•';
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 50,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _cardDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: hasThrow ? _neonGreen : Colors.transparent, width: 1.5),
                      ),
                      child: Center(
                        child: Text(label, style: TextStyle(color: hasThrow ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    );
                  }),
                ),

                // 4. Kompakte Statistikzeile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniStat('Avg', _overallAverage.toStringAsFixed(1)),
                    _buildMiniStat('Darts', '$_totalDartsThrown'),
                    _buildMiniStat('Last', '$_lastTurnScore'),
                  ],
                ),

                // 5. Checkout-Bar
                if (_checkoutRecommendation != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _neonGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _neonGreen, width: 1),
                      ),
                      child: Text(
                        'CHECKOUT: $_checkoutRecommendation',
                        style: const TextStyle(color: _neonGreen, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // UNTERE HÄLFTE: Das Numpad (Flex: 55%)
        Expanded(
          flex: 55,
          child: _buildResponsiveNumpad(),
        ),
      ],
    );
  }

  /// Spieler-Kachel
  Widget _buildPlayerCard({required String name, required int score, required double avg, required bool isActive}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? _neonGreen : Colors.transparent, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('$score', style: TextStyle(color: isActive ? _neonGreen : Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
          Text('Ø ${avg.toStringAsFixed(1)}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ],
      ),
    );
  }

  /// Mini Stat
  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  /// 100% responsives Numpad (passt sich an jede Bildschirmgröße an)
  Widget _buildResponsiveNumpad() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildNumpadRow([1, 2, 3, 4, 5]),
          const SizedBox(height: 6),
          _buildNumpadRow([6, 7, 8, 9, 10]),
          const SizedBox(height: 6),
          _buildNumpadRow([11, 12, 13, 14, 15]),
          const SizedBox(height: 6),
          _buildNumpadRow([16, 17, 18, 19, 20]),
          const SizedBox(height: 6),
          // Zeile für 0, 25, Bull, Backspace
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildKeyButton(label: '0', onTap: () => _onDartHit(0))),
                const SizedBox(width: 6),
                Expanded(child: _buildKeyButton(label: '25', onTap: () => _onDartHit(25))),
                const SizedBox(width: 6),
                Expanded(child: _buildKeyButton(label: 'BULL', textColor: Colors.redAccent, onTap: () => _onDartHit(50))),
                const SizedBox(width: 6),
                Expanded(child: _buildKeyButton(icon: Icons.backspace_outlined, onTap: _undoLastDart)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Zeile für Double / Triple
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildModifierButton(
                    label: 'DOUBLE',
                    isSelected: _activeMultiplier == InputMultiplier.double,
                    onTap: () => setState(() => _activeMultiplier = _activeMultiplier == InputMultiplier.double ? InputMultiplier.single : InputMultiplier.double),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModifierButton(
                    label: 'TRIPLE',
                    isSelected: _activeMultiplier == InputMultiplier.triple,
                    onTap: () => setState(() => _activeMultiplier = _activeMultiplier == InputMultiplier.triple ? InputMultiplier.single : InputMultiplier.triple),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hilfs-Methode, um eine Zeile aus 5 Zahlen generisch zu bauen
  Widget _buildNumpadRow(List<int> numbers) {
    return Expanded(
      child: Row(
        children: numbers.map((n) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: n == numbers.last ? 0 : 6.0),
              child: _buildKeyButton(label: '$n', onTap: () => _onDartHit(n)),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Button-Design für das Keyboard
  Widget _buildKeyButton({String? label, IconData? icon, Color? textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(color: _buttonDark, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 20)
              : Text(label!, style: TextStyle(color: textColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  /// Double/Triple Buttons
  Widget _buildModifierButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? _neonGreen : _buttonDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _neonGreen : Colors.white12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}