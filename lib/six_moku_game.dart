import 'package:flutter/material.dart';

enum Player { none, black, white }

class SixMokuGame extends StatefulWidget {
  const
  SixMokuGame({super.key});

  @override
  State<SixMokuGame> createState() => _SixMokuGameState();
}

class _SixMokuGameState extends State<SixMokuGame> {
  int boardSize = 19;
  static const int winCount = 6;
  static const int minBoardSize = 10;
  static const int maxBoardSize = 20;

  late List<List<Player>> board;
  Player currentPlayer = Player.black;
  bool gameOver = false;
  String gameStatus = '黑棋先行 - 第一手必须下在棋盘中心';
  List<List<int>>? firstMovePositions;
  bool isFirstMove = true;
  int selectedFirstMoveCount = 0;
  List<List<int>> tempFirstMoves = [];

  // 悔棋相关变量
  List<Map<String, dynamic>> moveHistory = [];
  bool canUndo = false;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    board = List.generate(
      boardSize,
      (_) => List.generate(boardSize, (_) => Player.none),
    );
    currentPlayer = Player.black;
    gameOver = false;
    gameStatus = '黑棋先行 - 第一手必须下在棋盘中心';
    firstMovePositions = null;
    isFirstMove = true;
    selectedFirstMoveCount = 0;
    tempFirstMoves = [];
    moveHistory.clear();
    canUndo = false;
  }

  void _showBoardSizeDialog() {
    int tempBoardSize = boardSize;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: const Text('设置棋盘大小'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('选择棋盘大小（10-20）：'),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempBoardSize.toDouble(),
                    min: minBoardSize.toDouble(),
                    max: maxBoardSize.toDouble(),
                    divisions: maxBoardSize - minBoardSize,
                    label: '$tempBoardSize × $tempBoardSize',
                    onChanged: (double value) {
                      dialogSetState(() {
                        tempBoardSize = value.toInt();
                      });
                    },
                  ),
                  Text('当前大小：$tempBoardSize × $tempBoardSize'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      boardSize = tempBoardSize;
                    });
                    Navigator.of(context).pop();
                    _initializeBoard();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleCellTap(int row, int col) {
    if (gameOver || board[row][col] != Player.none) return;

    // 黑棋第一手强制下在中心
    if (isFirstMove && (row != 9 || col != 9)) return;

    if (isFirstMove) {
      _handleFirstMove(row, col);
    } else {
      _handleRegularMove(row, col);
    }
  }

  void _saveToHistory(int row, int col, Player player, bool wasFirstMove, int moveCount) {
    moveHistory.add({
      'row': row,
      'col': col,
      'player': player,
      'wasFirstMove': wasFirstMove,
      'moveCount': moveCount,
      'currentPlayer': currentPlayer,
      'gameStatus': gameStatus,
      'isFirstMove': isFirstMove,
      'selectedFirstMoveCount': selectedFirstMoveCount,
      'tempFirstMoves': List.from(tempFirstMoves),
    });
    canUndo = true;
  }

  void _handleFirstMove(int row, int col) {
    if (row != 9 || col != 9) return; // 必须下在中心

    _saveToHistory(row, col, currentPlayer, true, 1);

    setState(() {
      board[row][col] = currentPlayer;
      tempFirstMoves.add([row, col]);
      selectedFirstMoveCount++;

      // 第一手完成
      firstMovePositions = List.from(tempFirstMoves);
      isFirstMove = false;
      currentPlayer = Player.white;
      gameStatus = '白棋回合 - 请下两子';
      tempFirstMoves.clear();
      selectedFirstMoveCount = 0;
    });
  }

  void _handleRegularMove(int row, int col) {
    if (tempFirstMoves.any((pos) => pos[0] == row && pos[1] == col)) {
      // 取消选择
      setState(() {
        tempFirstMoves.removeWhere((pos) => pos[0] == row && pos[1] == col);
        board[row][col] = Player.none;
        selectedFirstMoveCount--;
        gameStatus = '${_playerName(currentPlayer)}回合 - 还需下 ${2 - selectedFirstMoveCount} 子';
      });
      return;
    }

    if (selectedFirstMoveCount >= 2) return;

    _saveToHistory(row, col, currentPlayer, false, selectedFirstMoveCount + 1);

    setState(() {
      board[row][col] = currentPlayer;
      tempFirstMoves.add([row, col]);
      selectedFirstMoveCount++;

      // 每下一子都检查是否获胜
      bool hasWon = false;
      if (_checkWin(row, col, currentPlayer)) {
        gameOver = true;
        gameStatus = '${_playerName(currentPlayer)}获胜！';
        _showWinDialog(currentPlayer);
        hasWon = true;
      }

      if (!hasWon) {
        if (selectedFirstMoveCount == 2) {
          // 两子都下完了，检查平局并切换玩家
          if (_isBoardFull()) {
            gameOver = true;
            gameStatus = '平局！';
            _showDrawDialog();
          } else {
            tempFirstMoves.clear();
            selectedFirstMoveCount = 0;
            currentPlayer = currentPlayer == Player.black ? Player.white : Player.black;
            gameStatus = '${_playerName(currentPlayer)}回合 - 请下两子';
          }
        } else {
          gameStatus = '${_playerName(currentPlayer)}回合 - 还需下 ${2 - selectedFirstMoveCount} 子';
        }
      }
    });
  }

  void _undoMove() {
    if (moveHistory.isEmpty) return;

    setState(() {
      final lastMove = moveHistory.removeLast();

      // 恢复棋盘状态
      board[lastMove['row']][lastMove['col']] = Player.none;

      // 恢复游戏状态
      currentPlayer = lastMove['currentPlayer'];
      gameStatus = lastMove['gameStatus'];
      isFirstMove = lastMove['isFirstMove'];
      selectedFirstMoveCount = lastMove['selectedFirstMoveCount'];
      tempFirstMoves = List<List<int>>.from(lastMove['tempFirstMoves']);

      // 更新悔棋按钮状态
      canUndo = moveHistory.isNotEmpty;

      // 游戏重新开始
      gameOver = false;
    });
  }

  bool _checkWin(int row, int col, Player player) {
    final directions = [
      [0, 1],   // 水平
      [1, 0],   // 垂直
      [1, 1],   // 对角线 \
      [1, -1],  // 对角线 /
    ];

    for (final dir in directions) {
      int count = 1;

      // 正向检查
      for (int i = 1; i < winCount; i++) {
        int newRow = row + dir[0] * i;
        int newCol = col + dir[1] * i;

        if (newRow < 0 || newRow >= boardSize ||
            newCol < 0 || newCol >= boardSize ||
            board[newRow][newCol] != player) {
          break;
        }
        count++;
      }

      // 反向检查
      for (int i = 1; i < winCount; i++) {
        int newRow = row - dir[0] * i;
        int newCol = col - dir[1] * i;

        if (newRow < 0 || newRow >= boardSize ||
            newCol < 0 || newCol >= boardSize ||
            board[newRow][newCol] != player) {
          break;
        }
        count++;
      }

      if (count >= winCount) return true;
    }

    return false;
  }

  bool _isBoardFull() {
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == Player.none) return false;
      }
    }
    return true;
  }

  String _playerName(Player player) {
    switch (player) {
      case Player.black:
        return '黑棋';
      case Player.white:
        return '白棋';
      default:
        return '';
    }
  }

  Color _getCellColor(Player player) {
    switch (player) {
      case Player.black:
        return Colors.black;
      case Player.white:
        return Colors.white;
      default:
        return Colors.transparent;
    }
  }

  Color? _getCellBackgroundColor(int row, int col) {
    if (isFirstMove) {
      if (tempFirstMoves.any((pos) => pos[0] == row && pos[1] == col)) {
        return Colors.green[100];
      }
    }
    return null;
  }

  void _resetGame() {
    setState(() {
      _initializeBoard();
    });
  }

  void _showWinDialog(Player winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('游戏结束'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: 64,
                color: winner == Player.black ? Colors.black : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                '${_playerName(winner)}获胜！',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  void _showDrawDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('游戏结束'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.handshake,
                size: 64,
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              Text(
                '平局！',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('六子棋'),
        backgroundColor: Colors.brown[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_3x3, color: Colors.white),
            onPressed: _showBoardSizeDialog,
            tooltip: '设置棋盘大小',
          ),
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            onPressed: canUndo ? _undoMove : null,
            tooltip: '悔棋',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetGame,
            tooltip: '重新开始',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.brown[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (!isFirstMove) ...[
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: currentPlayer == Player.black ? Colors.black : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      gameStatus,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!gameOver)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFirstMove ? '$selectedFirstMoveCount/1' : '$selectedFirstMoveCount/2',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.brown[300],
                    border: Border.all(color: Colors.brown[700]!, width: 2),
                  ),
                  child: CustomPaint(
                    painter: BoardPainter(boardSize: boardSize),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: boardSize,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: boardSize * boardSize,
                      itemBuilder: (context, index) {
                        final row = index ~/ boardSize;
                        final col = index % boardSize;
                        
                        return GestureDetector(
                          onTap: gameOver ? null : () => _handleCellTap(row, col),
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: board[row][col] != Player.none
                                  ? Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: _getCellColor(board[row][col]),
                                        shape: BoxShape.circle,
                                        border: board[row][col] == Player.white
                                            ? Border.all(color: Colors.black, width: 2)
                                            : Border.all(color: Colors.grey[300]!, width: 1),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 2,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.brown[100],
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('游戏规则：', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('1. 黑棋第一手必须下在棋盘中心'),
                Text('2. 之后双方轮流下两子'),
                Text('3. 先连成6子者获胜'),
                Text('4. 棋盘满时为平局'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final int boardSize;

  BoardPainter({required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[600]!
      ..strokeWidth = 1.0;

    final cellSize = size.width / boardSize;
    final halfCellSize = cellSize / 2;

    // 绘制竖线
    for (int i = 0; i < boardSize; i++) {
      final x = i * cellSize + halfCellSize;
      canvas.drawLine(
        Offset(x, halfCellSize),
        Offset(x, size.height - halfCellSize),
        paint,
      );
    }

    // 绘制横线
    for (int i = 0; i < boardSize; i++) {
      final y = i * cellSize + halfCellSize;
      canvas.drawLine(
        Offset(halfCellSize, y),
        Offset(size.width - halfCellSize, y),
        paint,
      );
    }

    // 绘制天元和星位
    final starPaint = Paint()
      ..color = Colors.brown[800]!
      ..strokeWidth = 3.0;

    final starPositions = [
      [3, 3], [3, 9], [3, 15],
      [9, 3], [9, 9], [9, 15],
      [15, 3], [15, 9], [15, 15],
    ];

    for (final pos in starPositions) {
      if (pos[0] < boardSize && pos[1] < boardSize) {
        final x = pos[1] * cellSize + halfCellSize;
        final y = pos[0] * cellSize + halfCellSize;
        canvas.drawCircle(Offset(x, y), 3.0, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}