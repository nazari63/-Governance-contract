// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    IERC20 public votingToken;
    uint256 public proposalCount;

    struct Proposal {
        string description;
        uint256 voteCount;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(address => bool) votes;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 startTime, uint256 endTime);
    event Voted(address indexed voter, uint256 indexed proposalId, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(IERC20 _votingToken) {
        votingToken = _votingToken;
    }

    // Create a new proposal
    function createProposal(string memory description, uint256 duration) external onlyOwner {
        proposalCount++;
        uint256 proposalId = proposalCount;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        Proposal storage proposal = proposals[proposalId];
        proposal.description = description;
        proposal.startTime = startTime;
        proposal.endTime = endTime;

        emit ProposalCreated(proposalId, description, startTime, endTime);
    }

    // Vote on a proposal
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp >= proposal.startTime, "Voting has not started yet");
        require(block.timestamp <= proposal.endTime, "Voting has ended");
        require(!proposal.votes[msg.sender], "You have already voted");
        require(votingToken.balanceOf(msg.sender) > 0, "You must hold voting tokens to vote");

        if (support) {
            proposal.voteCount += votingToken.balanceOf(msg.sender);
        }

        proposal.votes[msg.sender] = true;

        emit Voted(msg.sender, proposalId, support);
    }

    // Execute the proposal (only if passed)
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp > proposal.endTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.voteCount > (votingToken.totalSupply() / 2)) {
            // Execute proposal logic here (e.g., update a state, transfer funds, etc.)
            // For demonstration, we will just emit an event
            emit ProposalExecuted(proposalId);
        }

        proposal.executed = true;
    }

    // Get proposal details
    function getProposalDetails(uint256 proposalId) external view returns (string memory, uint256, uint256, bool) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.description, proposal.voteCount, proposal.endTime, proposal.executed);
    }
}