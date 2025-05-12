// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OddsAndEvens
 * @dev Two-player game where each player picks 0 or 1, and the sum determines the winner:
 *      If even, "evens" player wins; if odd, "odds" player wins. Uses commit-reveal for fairness.
 */

contract OddsAndEvens {
    uint public stake; // player bet amount
    address payable public player1;
    address payable public player2;
    bool public gameStarted;
    bool public gameJoined;
    bool public revealed;

    enum Role { None, Odds, Evens } // player roles
    Role public player1Role;
    Role public player2Role;

    bytes32 public commitment; // player1's hashed move + secret
    uint8 public move2; // player2's move (0 or 1)
    uint8 public move1; // revealed move from Player1
    string private secret; // player1's secret used in hash

    // events
    event GameCommitted(address indexed player1, Role role, uint stake);
    event GameJoined(address indexed player2, Role role, uint8 move);
    event MoveRevealed(uint8 move1, string secret);
    event Winner(address winner);
    event Draw();

    // restrict to only player1
    modifier onlyPlayer1() {
        require(msg.sender == player1, "Only player 1");
        _;
    }

    // prevent duplicate reveals
    modifier notRevealed() {
        require(!revealed, "Already revealed");
        _;
    }

    // player1 commits to hash and picks role
    function commitMove(bytes32 _commitment, Role _role) external payable {
        require(!gameStarted, "Game already started");
        require(msg.value > 0, "Stake must be > 0");
        require(_role == Role.Odds || _role == Role.Evens, "Invalid role");

        player1 = payable(msg.sender);
        stake = msg.value;
        commitment = _commitment;
        player1Role = _role;
        gameStarted = true;

        emit GameCommitted(msg.sender, _role, msg.value);
    }

    // player2 joins the game and chooses their move
    function joinGame(uint8 _move, Role _role) external payable {
        require(gameStarted && !gameJoined, "Cannot join");
        require(msg.value == stake, "Stake mismatch");
        require(_move == 0 || _move == 1, "Invalid move");
        require(_role != player1Role && (_role == Role.Odds || _role == Role.Evens), "Invalid or same role");

        player2 = payable(msg.sender);
        player2Role = _role;
        move2 = _move;
        gameJoined = true;

        emit GameJoined(msg.sender, _role, _move);
    }

    // player1 reveals move and secret as proof
    function revealMove(uint8 _move1, string memory _secret) external onlyPlayer1 notRevealed {
        require(gameJoined, "Game not joined");
        require(keccak256(abi.encodePacked(_move1, _secret)) == commitment, "Invalid reveal");

        move1 = _move1;
        secret = _secret;
        revealed = true;

        emit MoveRevealed(_move1, _secret);

        _resolve();
    }

    // resolve game and transfer winnings
    function _resolve() internal {
        uint8 total = move1 + move2;
        bool even = (total % 2 == 0);
        address payable winner;

        // determine winner
        if ((even && player1Role == Role.Evens) || (!even && player1Role == Role.Odds)) {
            winner = player1;
        } 
        else {
            winner = player2;
        }

        // transfer total pot to winner
        winner.transfer(address(this).balance);
        emit Winner(winner);
    }

    function hashMove(uint8 _move, string memory _secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_move, _secret));
    }
  constructor(address _player1, bytes32 _commitment, Role _role) payable {
    require(msg.value > 0, "Stake must be > 0");
    require(_role == Role.Odds || _role == Role.Evens, "Invalid role");

    player1 = payable(_player1); // use passed-in address
    stake = msg.value;
    commitment = _commitment;
    player1Role = _role;
    gameStarted = true;

    emit GameCommitted(_player1, _role, msg.value);
}

}
