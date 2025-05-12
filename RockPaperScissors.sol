// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RockPaperScissors
 * @dev Two-player Rock-Paper-Scissors where deployer sets stake and first move,
 *      and challenger joins by providing move and matching the stake.
 */
contract RockPaperScissors {
    uint public stake;
    address payable public player1;
    address payable public player2;
    string public move1;
    string public move2;
    bool public finished;

    event GameStarted(address indexed player1, uint stake, string move1);
    event GameJoined(address indexed player2, string move2);
    event Draw();
    event GameResolved(address winner);

    modifier notFinished() {
        require(!finished, "Game already finished");
        _;
    }

    // stake amount in wei each player must send
    // first player's move: "Rock", "Paper", or "Scissors"
    constructor(uint _stake, string memory _move1) payable notFinished {
        require(_stake > 0, "Stake must be > 0");
        require(msg.value == _stake, "Incorrect stake");
        require(isValidMove(_move1), "Invalid move");

        stake = _stake;
        player1 = payable(msg.sender);
        move1 = _move1;
        emit GameStarted(msg.sender, _stake, _move1);
    }


    // Challenger joins by sending the same stake and their move.
    function join(string memory _move2) external payable notFinished {
        require(player2 == address(0), "Game full");
        require(msg.value == stake, "Incorrect stake");
        require(isValidMove(_move2), "Invalid move");

        player2 = payable(msg.sender);
        move2 = _move2;
        emit GameJoined(msg.sender, _move2);

        _resolve();
    }

    function _resolve() internal notFinished {
        finished = true;

        bytes32 h1 = keccak256(bytes(move1));
        bytes32 h2 = keccak256(bytes(move2));

        // Draw: refund both
        if (h1 == h2) {
            player1.transfer(stake);
            player2.transfer(stake);
            emit Draw();
            return;
        }

        // Determine winner
        bool player1Wins =
            (h1 == keccak256(bytes("Rock")) && h2 == keccak256(bytes("Scissors"))) ||
            (h1 == keccak256(bytes("Scissors")) && h2 == keccak256(bytes("Paper"))) ||
            (h1 == keccak256(bytes("Paper")) && h2 == keccak256(bytes("Rock")));

        address payable winner = player1Wins ? player1 : player2;
        winner.transfer(address(this).balance);
        emit GameResolved(winner);
    }

    function isValidMove(string memory _move) internal pure returns (bool) {
        bytes32 h = keccak256(bytes(_move));
        return
            h == keccak256(bytes("Rock")) ||
            h == keccak256(bytes("Paper")) ||
            h == keccak256(bytes("Scissors"));
    }
}
