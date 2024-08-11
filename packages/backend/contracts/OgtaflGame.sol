// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OgtaflGame is Ownable {
    uint8 public constant BOARD_SIZE = 11;

    address public attacker; // Attacker
    address public defender; // Defender
    address public winner;

    // King NFTs staked by players
    uint256 public player1KingTokenId;
    uint256 public player2KingTokenId;

    IERC721 public kingNFTContract;

    enum GameState { Waiting, Active, Completed }
    GameState public gameState;

    bool public isAttackerTurn;

    // Board Representation
    // 0 => Empty
    // 1 => Attacker
    // 2 => Defender
    // 3 => King
    uint8[BOARD_SIZE][BOARD_SIZE] public board;

    mapping(address => bool) public isPlayer;

    event GameStarted(address player1, address player2);
    event MoveMade(address player, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY);
    event GameWon(address winner, uint256 wonKingTokenId);

    modifier onlyPlayers() {
        require(isPlayer[msg.sender], "Not a player");
        _;
    }

    modifier gameInState(GameState _state) {
        require(gameState == _state, "Invalid game state for this action");
        _;
    }

    modifier onlyCurrentPlayer() {
        if (isAttackerTurn) {
            require(msg.sender == attacker, "Not your turn");
        } else {
            require(msg.sender == defender, "Not your turn");
        }
        _;
    }

    constructor(address _kingNFTContract) Ownable(msg.sender) {
        kingNFTContract = IERC721(_kingNFTContract);
        gameState = GameState.Waiting;
    }

    /** @dev Start the game by staking King NFTs from both players.
      * @param _player1 Address of player1.
      * @param _player1KingTokenId Token ID of player1's King NFT.
      * @param _player2 Address of player2.
      * @param _player2KingTokenId Token ID of player2's King NFT.
      */
    function startGame(
        address _player1,
        uint256 _player1KingTokenId,
        address _player2,
        uint256 _player2KingTokenId
    ) public gameInState(GameState.Waiting) {
        require(
            kingNFTContract.ownerOf(_player1KingTokenId) == _player1 &&
            kingNFTContract.ownerOf(_player2KingTokenId) == _player2,
            "Players must own the NFTs they stake"
        );

        // TODO: Randomize attacker/defender using Chainlink VRF
        attacker = _player1;
        defender = _player2;
        isPlayer[attacker] = true;
        isPlayer[defender] = true;

        player1KingTokenId = _player1KingTokenId;
        player2KingTokenId = _player2KingTokenId;

        kingNFTContract.transferFrom(attacker, address(this), player1KingTokenId);
        kingNFTContract.transferFrom(defender, address(this), player2KingTokenId);

        initializeBoard();

        gameState = GameState.Active;

        // Attacker starts first
        isAttackerTurn = true;

        emit GameStarted(attacker, defender);
    }

    /** @dev Initialize the board with starting positions. */
    function initializeBoard() internal {
        for (uint8 i = 0; i < BOARD_SIZE; i++) {
            for (uint8 j = 0; j < BOARD_SIZE; j++) {
                board[i][j] = 0;
            }
        }

        // Attackers
        placePiece(0, 3, 1);
        placePiece(0, 4, 1);
        placePiece(0, 5, 1);
        placePiece(0, 6, 1);
        placePiece(0, 7, 1);

        placePiece(1, 5, 1);

        placePiece(3, 0, 1);
        placePiece(4, 0, 1);
        placePiece(5, 0, 1);
        placePiece(6, 0, 1);
        placePiece(7, 0, 1);

        placePiece(5, 1, 1);

        placePiece(10, 3, 1);
        placePiece(10, 4, 1);
        placePiece(10, 5, 1);
        placePiece(10, 6, 1);
        placePiece(10, 7, 1);

        placePiece(9, 5, 1);

        placePiece(3, 10, 1);
        placePiece(4, 10, 1);
        placePiece(5, 10, 1);
        placePiece(6, 10, 1);
        placePiece(7, 10, 1);

        placePiece(5, 9, 1);

        // Defenders
        placePiece(5, 3, 2);
        placePiece(3, 5, 2);
        placePiece(4, 5, 2);
        placePiece(5, 4, 2);
        placePiece(5, 5, 3); // King
        placePiece(5, 6, 2);
        placePiece(6, 5, 2);
        placePiece(7, 5, 2);
        placePiece(5, 7, 2);
    }

    /** @dev Place a piece on the board.
      * @param x X-coordinate.
      * @param y Y-coordinate.
      * @param piece Type of piece (1: Attacker, 2: Defender, 3: King).
      */
    function placePiece(uint8 x, uint8 y, uint8 piece) internal {
        board[x][y] = piece;
    }

    /** @dev Make a move on the board.
      * @param fromX Starting X-coordinate.
      * @param fromY Starting Y-coordinate.
      * @param toX Destination X-coordinate.
      * @param toY Destination Y-coordinate.
      */
    function makeMove(
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY
    ) public onlyPlayers gameInState(GameState.Active) onlyCurrentPlayer {
        require(
            isValidCoordinate(fromX, fromY) && isValidCoordinate(toX, toY),
            "Invalid coordinates"
        );
        uint8 movingPiece = board[fromX][fromY];
        require(movingPiece != 0, "No piece at the source");
        require(board[toX][toY] == 0, "Destination not empty");

        if (isAttackerTurn) {
            require(movingPiece == 1, "You can only move your own pieces");
        } else {
            require(movingPiece == 2 || movingPiece == 3, "You can only move your own pieces");
        }

        require(
            (fromX == toX || fromY == toY) && isPathClear(fromX, fromY, toX, toY),
            "Invalid move"
        );

        board[toX][toY] = movingPiece;
        board[fromX][fromY] = 0;

        emit MoveMade(msg.sender, fromX, fromY, toX, toY);

        checkForCapture(toX, toY);

        if (checkForWin()) {
            concludeGame();
            return;
        }

        isAttackerTurn = !isAttackerTurn;
    }

    /** @dev Check if coordinates are within the board. */
    function isValidCoordinate(uint8 x, uint8 y) internal pure returns (bool) {
        return x < BOARD_SIZE && y < BOARD_SIZE;
    }

    /** @dev Check if the path between two coordinates is clear. */
    function isPathClear(
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY
    ) internal view returns (bool) {
        if (fromX == toX) {
            uint8 minY = fromY < toY ? fromY + 1 : toY + 1;
            uint8 maxY = fromY > toY ? fromY - 1 : toY - 1;
            for (uint8 y = minY; y <= maxY; y++) {
                if (board[fromX][y] != 0) {
                    return false;
                }
            }
        } else if (fromY == toY) {
            uint8 minX = fromX < toX ? fromX + 1 : toX + 1;
            uint8 maxX = fromX > toX ? fromX - 1 : toX - 1;
            for (uint8 x = minX; x <= maxX; x++) {
                if (board[x][fromY] != 0) {
                    return false;
                }
            }
        } else {
            return false; // Movement must be orthogonal
        }
        return true;
    }

    /** @dev Check and execute captures around the moved piece.
      * @param x X-coordinate of the moved piece.
      * @param y Y-coordinate of the moved piece.
      */
    function checkForCapture(uint8 x, uint8 y) internal {
        // Check in all four directions
        if (x > 1) {
            attemptCapture(x - 1, y, x - 2, y);
        }
        if (x < BOARD_SIZE - 2) {
            attemptCapture(x + 1, y, x + 2, y);
        }
        if (y > 1) {
            attemptCapture(x, y - 1, x, y - 2);
        }
        if (y < BOARD_SIZE - 2) {
            attemptCapture(x, y + 1, x, y + 2);
        }
    }

    /** @dev Attempt to capture a piece.
      * @param targetX X-coordinate of the potential victim piece.
      * @param targetY Y-coordinate of the potential victim piece.
      * @param oppositeX X-coordinate opposite to the moved piece.
      * @param oppositeY Y-coordinate opposite to the moved piece.
      */
    function attemptCapture(
        uint8 targetX,
        uint8 targetY,
        uint8 oppositeX,
        uint8 oppositeY
    ) internal {
        if (!isValidCoordinate(oppositeX, oppositeY)) {
            return;
        }

        uint8 movingPlayerPiece = isAttackerTurn ? 1 : 2;
        uint8 opponentPiece = isAttackerTurn ? 2 : 1;
        uint8 targetPiece = board[targetX][targetY];
        uint8 oppositePiece = board[oppositeX][oppositeY];

        // King requires special capture rules
        if (targetPiece == 3) {
            // King is captured when surrounded on four sides
            if (
                isSurrounded(targetX, targetY)
            ) {
                board[targetX][targetY] = 0; // Remove King
            }
        } else if (targetPiece == opponentPiece) {
            if (oppositePiece == movingPlayerPiece || isThrone(oppositeX, oppositeY)) {
                if (isAdjacentToMovingPiece(targetX, targetY, movingPlayerPiece)) {
                    board[targetX][targetY] = 0; // Capture
                }
            }
        }
    }

    /** @dev Check if a piece is surrounded on four sides. */
    function isSurrounded(uint8 x, uint8 y) internal view returns (bool) {
        uint8 enemyPiece = isAttackerTurn ? 1 : 2;
        // Check up
        if (x == 0 || board[x - 1][y] != enemyPiece) {
            return false;
        }
        // Check down
        if (x == BOARD_SIZE - 1 || board[x + 1][y] != enemyPiece) {
            return false;
        }
        // Check left
        if (y == 0 || board[x][y - 1] != enemyPiece) {
            return false;
        }
        // Check right
        if (y == BOARD_SIZE - 1 || board[x][y + 1] != enemyPiece) {
            return false;
        }
        return true;
    }

    /** @dev Check if a coordinate is the throne (center square). */
    function isThrone(uint8 x, uint8 y) internal pure returns (bool) {
        return x == BOARD_SIZE / 2 && y == BOARD_SIZE / 2;
    }

    /** @dev Check if the moving piece is adjacent to target coordinate. */
    function isAdjacentToMovingPiece(
        uint8 targetX,
        uint8 targetY,
        uint8 movingPlayerPiece
    ) internal view returns (bool) {
        if (targetX > 0 && board[targetX - 1][targetY] == movingPlayerPiece) {
            return true;
        }
        if (targetX < BOARD_SIZE - 1 && board[targetX + 1][targetY] == movingPlayerPiece) {
            return true;
        }
        if (targetY > 0 && board[targetX][targetY - 1] == movingPlayerPiece) {
            return true;
        }
        if (targetY < BOARD_SIZE - 1 && board[targetX][targetY + 1] == movingPlayerPiece) {
            return true;
        }
        return false;
    }

    /** @dev Check for win conditions. */
    function checkForWin() internal view returns (bool) {
        // If King is captured, attacker wins
        if (!isKingOnBoard()) {
            return true;
        }

        // If King reaches any corner, defender wins
        if (isKingAtCorner()) {
            return true;
        }

        return false;
    }

    /** @dev Check if the King is still on the board. */
    function isKingOnBoard() internal view returns (bool) {
        for (uint8 i = 0; i < BOARD_SIZE; i++) {
            for (uint8 j = 0; j < BOARD_SIZE; j++) {
                if (board[i][j] == 3) {
                    return true;
                }
            }
        }
        return false;
    }

    /** @dev Check if the King is at any corner of the board. */
    function isKingAtCorner() internal view returns (bool) {
        if (board[0][0] == 3) return true;
        if (board[0][BOARD_SIZE - 1] == 3) return true;
        if (board[BOARD_SIZE - 1][0] == 3) return true;
        if (board[BOARD_SIZE - 1][BOARD_SIZE - 1] == 3) return true;
        return false;
    }

    /** @dev Conclude the game, determine the winner, and transfer NFTs accordingly. */
    function concludeGame() internal {
        gameState = GameState.Completed;

        // Determine winner
        if (!isKingOnBoard()) {
            // Attacker wins
            winner = attacker;
        } else if (isKingAtCorner()) {
            // Defender wins
            winner = defender;
        } else {
            revert("No win condition met");
        }

        uint256 wonKingTokenId = winner == attacker ? player2KingTokenId : player1KingTokenId;

        // Transfer the loser's King NFT to the winner
        kingNFTContract.transferFrom(address(this), winner, wonKingTokenId);

        // Return the winner's own King NFT
        uint256 winnerKingTokenId = winner == attacker ? player1KingTokenId : player2KingTokenId;
        kingNFTContract.transferFrom(address(this), winner, winnerKingTokenId);

        emit GameWon(winner, wonKingTokenId);
    }

    /** @dev Get the current state of the board. */
    function getBoard() public view returns (uint8[BOARD_SIZE][BOARD_SIZE] memory) {
        return board;
    }
}
