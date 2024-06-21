// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mafia {
    enum Role { None, Assassin, Policeman, Civilian }
    
    struct Player {
        address wallet;
        Role role;
        bool isAlive;
    }

    Player[4] public players;
    mapping(address => uint) public playerIds;
    uint public assassinId;
    uint public policemanId;

    uint[4] public votes;
    bool public votingOpen;
    
    event RoleAssigned(address indexed player, Role role);
    event Voted(address indexed voter, uint targetId);
    event Executed(uint targetId);

    // Function to assign roles to players
    function assignRoles(address[4] memory _players) public {
        // Check if roles have already been assigned
        require(players[0].wallet == address(0), "Roles already assigned");

        // Assign roles to each player
        players[0] = Player(_players[0], Role.Assassin, true);
        players[1] = Player(_players[1], Role.Policeman, true);
        players[2] = Player(_players[2], Role.Civilian, true);
        players[3] = Player(_players[3], Role.Civilian, true);

        // Store player details and emit RoleAssigned event
        for (uint i = 0; i < 4; i++) {
            playerIds[_players[i]] = i; // Map player's address to their ID
            emit RoleAssigned(_players[i], players[i].role); // Emit event for role assignment
        }

        // Set IDs for special roles
        assassinId = 0; // ID for Assassin
        policemanId = 1; // ID for Policeman
        votingOpen = false; // Initialize voting status
    }

    // Function for the Assassin to perform an action
    function performAssassinAction(uint targetId) public {
        require(playerIds[msg.sender] == assassinId, "Only assassin can perform this action");
        require(targetId != assassinId, "Cannot target self");
        require(players[targetId].isAlive, "Target must be alive");

        // Mark the target player as dead
        players[targetId].isAlive = false;
    }

    // Function to start voting
    function startVoting() public {
        require(!votingOpen, "Voting is already open");
        votingOpen = true; // Open the voting round
    }

    // Function to vote for a player to be executed
    function vote(uint targetId) public {
        require(votingOpen, "Voting is not open"); // Check if voting is open
        uint voterId = playerIds[msg.sender];
        require(players[voterId].isAlive, "You must be alive to vote"); // Check if voter is alive
        require(players[targetId].isAlive, "Target must be alive"); // Check if target is alive

        votes[targetId] += 1; // Increment the vote count for the target
        emit Voted(msg.sender, targetId); // Emit a Voted event
    }

    // Function to end voting and execute the player with most votes
    function endVoting() public {
        require(votingOpen, "Voting is not open");
        votingOpen = false; // Close the voting round

        // Determine the player with the most votes
        uint maxVotes = 0;
        uint maxVotedId = 0;
        bool tie = false;

        for (uint i = 0; i < 4; i++) {
            if (votes[i] > maxVotes) {
                maxVotes = votes[i];
                maxVotedId = i;
                tie = false; // Reset tie flag when a new max is found
            } else if (votes[i] == maxVotes && maxVotes > 0) {
                tie = true; // Set tie flag if another player has the same max votes
            }
        }

        // Handle tie scenario (for simplicity, no one is executed in case of a tie)
        if (!tie && maxVotes > 0) {
            players[maxVotedId].isAlive = false; // Mark the player with most votes as dead
            emit Executed(maxVotedId); // Emit an Executed event
        }

        // Reset votes for next round
        for (uint i = 0; i < 4; i++) {
            votes[i] = 0;
        }
    }
}
