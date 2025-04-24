// stadium_map_page.dart - Prioritize walkable aisles in all modes

import 'dart:math';
import 'package:flutter/material.dart';

class StadiumMapPage extends StatefulWidget {
  @override
  State<StadiumMapPage> createState() => _StadiumMapPageState();
}

class _StadiumMapPageState extends State<StadiumMapPage> {
  final int rows = 12;
  final int cols = 30;
  List<List<String>> grid = [];
  List<List<int>> allEntrances = [[0, 9], [0, 19], [0, 29]];
  Map<String, List<int>> sectionEntrances = {
    'A': [0, 9],
    'B': [0, 19],
    'C': [0, 29],
  };

  String selectedSection = 'A';
  List<int> selectedSeat = [11, 8];
  List<int> entrance = [0, 9];
  List<List<int>> path = [];
  bool emergency = false;
  Map<String, double> crowd = {};

  @override
  void initState() {
    super.initState();
    _generateCrowd();
    _initGrid();
    _calculatePath();
  }

  void _generateCrowd() {
    final r = Random();
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        crowd['${i}_$j'] = r.nextDouble();
      }
    }
  }

  void _initGrid() {
    grid = List.generate(rows, (_) => List.generate(cols, (_) => '.'));
    for (int i = 0; i < rows; i++) {
      grid[i][9] = ' '; grid[i][19] = ' '; grid[i][29] = ' ';
    }
    grid[0][9] = 'E';
    grid[0][19] = 'E';
    grid[0][29] = 'E';
  }

  void _calculatePath() {
    List<List<int>> bestPath = [];
    double bestScore = double.infinity;

    for (var e in allEntrances) {
      final from = emergency ? selectedSeat : e;
      final to = emergency ? e : selectedSeat;
      final testPath = _aStar(grid, from, to);

      if (testPath.isNotEmpty) {
        double score = testPath.length.toDouble();
        if (score < bestScore) {
          bestScore = score;
          bestPath = testPath;
          entrance = e;
        }
      }
    }

    setState(() {
      path = bestPath;
      if (emergency && path.isEmpty) {
        Future.delayed(Duration.zero, () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ لا يوجد مسار متاح للطوارئ حالياً، جميع الطرق مزدحمة')),
          );
        });
      }
    });
  }

  void _onSeatTap(int r, int c) {
    if (grid[r][c] != '#' && grid[r][c] != ' ') {
      selectedSeat = [r, c];
      _calculatePath();
    }
  }

  Widget _buildSeat(int r, int c) {
    final isEntrance = grid[r][c] == 'E';
    final isAisle = grid[r][c] == ' ';
    final isTarget = r == selectedSeat[0] && c == selectedSeat[1];
    final isPath = path.any((p) => p[0] == r && p[1] == c);
    final density = crowd['${r}_$c'] ?? 0;

    Color color = Colors.orange;
    if (emergency && density > 0.6) color = Colors.red;
    Widget? child = Icon(Icons.event_seat, size: 14, color: Colors.white);

    if (isAisle) {
      child = Icon(Icons.directions_walk, size: 14, color: Colors.black45);
      if (isPath) color = Colors.lightBlueAccent;
      else color = Colors.white;
    } else if (isEntrance) {
      color = Colors.green;
      child = Icon(Icons.login, color: Colors.white, size: 16);
    } else if (isTarget) {
      color = Colors.blue;
    } else if (isPath) {
      color = Colors.lightBlueAccent;
    }

    return GestureDetector(
      onTap: () => _onSeatTap(r, c),
      child: Container(
        margin: EdgeInsets.all(1),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rows + 1, (r) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(cols + 1, (c) {
            if (r == 0 && c == 0) {
              return SizedBox(width: 30, height: 30);
            } else if (r == 0) {
              return SizedBox(
                width: 30,
                height: 30,
                child: Center(child: Text('${c - 1}', style: TextStyle(fontSize: 10))),
              );
            } else if (c == 0) {
              return SizedBox(
                width: 30,
                height: 30,
                child: Center(child: Text('${r - 1}', style: TextStyle(fontSize: 10))),
              );
            } else {
              return _buildSeat(r - 1, c - 1);
            }
          }),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stadium Map - Section $selectedSection'),
        actions: [
          Row(
            children: [
              Text('Emergency', style: TextStyle(color: Colors.white)),
              Switch(
                value: emergency,
                onChanged: (v) => setState(() {
                  emergency = v;
                  _calculatePath();
                }),
              ),
            ],
          ),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: sectionEntrances.keys.map((section) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedSection == section ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => setState(() {
                    selectedSection = section;
                    _calculatePath();
                  }),
                  child: Text('Section $section'),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 10),
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 3.0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: _buildGrid(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<List<int>> _aStar(List<List<String>> grid, List<int> start, List<int> goal) {
    final open = <_Node>[];
    final closed = <_Node>[];
    final startNode = _Node(start[0], start[1]);
    final goalNode = _Node(goal[0], goal[1]);
    open.add(startNode);

    while (open.isNotEmpty) {
      open.sort((a, b) => a.f.compareTo(b.f));
      final current = open.removeAt(0);
      closed.add(current);
      if (current == goalNode) return _reconstructPath(current);

      for (final n in _neighbors(current)) {
        if (closed.contains(n)) continue;

        final density = crowd['${n.row}_${n.col}'] ?? 0;
        if (emergency && density > 0.6) continue;

        final cellType = grid[n.row][n.col];
        final cost = (cellType == ' ') ? 0.5 : 1.0; // Prefer aisles

        n.g = current.g + cost;
        n.h = (n.row - goalNode.row).abs().toDouble() + (n.col - goalNode.col).abs().toDouble();
        n.parent = current;

        if (!open.contains(n)) open.add(n);
      }
    }
    return [];
  }

  List<_Node> _neighbors(_Node node) {
    final dirs = [[0,1], [1,0], [-1,0], [0,-1]];
    return dirs.map((d) => _Node(node.row + d[0], node.col + d[1])).where((n) {
      return n.row >= 0 && n.row < rows && n.col >= 0 && n.col < cols;
    }).toList();
  }

  List<List<int>> _reconstructPath(_Node n) {
    final p = <List<int>>[];
    while (n.parent != null) {
      p.insert(0, [n.row, n.col]);
      n = n.parent!;
    }
    return p;
  }
}

class _Node {
  final int row;
  final int col;
  double g;
  double h;
  _Node? parent;
  _Node(this.row, this.col, {this.g = 0, this.h = 0, this.parent});
  double get f => g + h;
  @override
  bool operator ==(Object o) => o is _Node && o.row == row && o.col == col;
  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}



