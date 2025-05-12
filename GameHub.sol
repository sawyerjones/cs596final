// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RockPaperScissors.sol";
import "./Lottery.sol";
import "./oddsEvens.sol";

/**
GameHub for deploying different games
 */
contract GameHub {
    address[] public games;

    event GameCreated(address indexed gameAddress, address indexed creator, uint stake, string move1);

    /* Deploy a new oddsEvens game */
    function createOddsAndEvensGame(bytes32 _commitment, OddsAndEvens.Role _role) external payable returns (address) {
    require(msg.value > 0, "Stake must be > 0");

    OddsAndEvens game = new OddsAndEvens{value: msg.value}(msg.sender, _commitment, _role);
    games.push(address(game));
    emit GameCreated(address(game), msg.sender, msg.value, "OddsAndEvens");
    return address(game);
    }

    /*
    Deploy a new RockPaperScissors game: sender becomes player1 and submits move.
    _move1 First player's move: "Rock", "Paper", or "Scissors"
     */
    function createRPSGame(string calldata _move1) external payable returns (address) {
        require(msg.value > 0, "Stake must be > 0");
        RockPaperScissors game = new RockPaperScissors{value: msg.value}(msg.value, _move1);
        games.push(address(game));
        emit GameCreated(address(game), msg.sender, msg.value, _move1);
        return address(game);
    }

    /* 
    Deploy a new Lottery game
    */
    function createLotteryGame(uint _ticket_price) external returns (address) {
        require(_ticket_price > 0, "Ticket price must be > 0");
        Lottery game = new Lottery(_ticket_price);
        games.push(address(game));
        emit GameCreated(address(game), msg.sender, _ticket_price, "Lottery");
        return address(game);
    }

    // Return total number of games created.
    function gameCount() external view returns (uint) {
        return games.length;
    }
}

