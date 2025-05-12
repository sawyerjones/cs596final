// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Lottery
 * @dev Two-player Lottert where deployer sets ticket price. Then they interact with the contract and purchase tickets first,
 *      and challenger joins by purchasing tickets. Each player can only buy tickets once.
 */
 contract Lottery {
    uint ticket_price;
    address payable address1;
    address payable address2;
    mapping(address => uint256) public ticketAmount;
    bool public game_status = false;

    event TicketsPurchased(address player, uint amount);
    event WinnerSelected(address winner, uint prize);
    event GameReset();
   
    // when contract is deployed we set the ticket price
    constructor(uint _ticket_price) {
        require(_ticket_price > 0, "Ticket prices must be > 0");
        // convert ticket prices into ether
        ticket_price = _ticket_price * 1 ether;
    }

    function buyTickets(uint purchase_amount) external payable {
        // confirm this is the first purchase
        require(ticketAmount[msg.sender] == 0, "You have already purchased tickets this round.");
        // get and confirm the total amount of ether player will spend
        uint total_price = ticket_price * purchase_amount;
        require(msg.value >= total_price, "You do not have enough ether to purchase that many tickets");
        // assign player addresses
        if (address1 == address(0)) {
            address1 = payable(msg.sender);
        } else if (address2 == address(0) && msg.sender != address1) {
            address2 = payable(msg.sender);
            game_status = true; // both players are now in
        } else {
            require(false, "Game already has two players");
        }
        // update sender's ticket amount

        ticketAmount[msg.sender] = purchase_amount;
        emit TicketsPurchased(msg.sender, purchase_amount);
        // auto start if both players joined
        if (game_status) {
            selectWinner();
        }
    }

    function selectWinner() public {
        // confirm both players have bought tickets
        require(address1 != address(0) && address2 != address(0), "Waiting for players");
        require(ticketAmount[address1] > 0 && ticketAmount[address2] > 0, "Both players must buy tickets");
        // get total tickets, calculate odds
        uint totalTickets = ticketAmount[address1] + ticketAmount[address2];
        // generate a random number
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % totalTickets;
        // determine winner
        address payable winner;
        if (randomNumber < ticketAmount[address1]) {
            winner = address1;
        } else {
            winner = address2;
        }
        uint prize = address(this).balance;
        // transfer funds to winner
        (bool sent, ) = winner.call{value: prize}("");
        require(sent, "Failed to send prize");
        
        emit WinnerSelected(winner, prize);
        
        // reset for next game
        cleanup();
    }
    
    function cleanup() public {
        // reset addresses
        address1 = payable(address(0));
        address2 = payable(address(0));
        // reset game state
        game_status = false;
        // reset ticket balances
        if (ticketAmount[address1] > 0) {
            ticketAmount[address1] = 0;
        }
        if (ticketAmount[address2] > 0) {
            ticketAmount[address2] = 0;
        }
        emit GameReset();
    }
    }
