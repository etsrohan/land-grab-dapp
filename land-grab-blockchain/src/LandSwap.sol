// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LandRegistry} from "./LandRegistry.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LandSwap is ReentrancyGuard {
    LandRegistry public landRegistry;

    struct SwapProposal {
        address proposer;
        string proposerLand;
        string targetLand;
        bool isActive;
        uint256 createdAt;
        uint256 expiresAt;
    }

    // Constants
    uint256 public constant SWAP_EXPIRY_TIME = 1 days;
    uint256 public constant MAX_ACTIVE_SWAPS = 10;

    // Mappings
    mapping(address => SwapProposal) public swapProposals;
    mapping(address => mapping(address => bool)) public swapApprovals;
    mapping(address => uint256) public activeSwapCount;

    // Events
    event SwapProposed(
        address indexed proposer,
        string proposerLand,
        string targetLand,
        uint256 expiresAt
    );
    event SwapApproved(
        address indexed approver,
        address indexed proposer,
        uint256 timestamp
    );
    event SwapExecuted(
        address indexed proposer,
        string proposerLand,
        string targetLand,
        uint256 timestamp
    );
    event SwapCancelled(
        address indexed proposer,
        string proposerLand,
        string targetLand,
        uint256 timestamp
    );
    event SwapExpired(
        address indexed proposer,
        string proposerLand,
        string targetLand,
        uint256 timestamp
    );

    constructor(address _landRegistry) {
        require(_landRegistry != address(0), "Invalid land registry address");
        landRegistry = LandRegistry(_landRegistry);
    }

    function proposeSwap(
        string memory proposerLand,
        string memory targetLand
    ) external nonReentrant {
        require(
            landRegistry.getLandDetails(proposerLand).owner == msg.sender,
            "Not the owner of proposer land"
        );
        require(
            landRegistry.getLandDetails(targetLand).isClaimed,
            "Target land not claimed"
        );
        require(
            landRegistry.getLandDetails(targetLand).owner != msg.sender,
            "Cannot swap with yourself"
        );
        require(
            activeSwapCount[msg.sender] < MAX_ACTIVE_SWAPS,
            "Too many active swaps"
        );
        require(
            !swapProposals[msg.sender].isActive,
            "Already has active proposal"
        );

        uint256 expiresAt = block.timestamp + SWAP_EXPIRY_TIME;
        swapProposals[msg.sender] = SwapProposal({
            proposer: msg.sender,
            proposerLand: proposerLand,
            targetLand: targetLand,
            isActive: true,
            createdAt: block.timestamp,
            expiresAt: expiresAt
        });

        // Proposer auto-approves their own swap
        swapApprovals[msg.sender][
            landRegistry.getLandDetails(targetLand).owner
        ] = true;

        activeSwapCount[msg.sender]++;
        emit SwapProposed(msg.sender, proposerLand, targetLand, expiresAt);
    }

    function approveSwap(address proposer) external nonReentrant {
        SwapProposal memory proposal = swapProposals[proposer];
        require(proposal.isActive, "No active proposal");
        require(
            landRegistry.getLandDetails(proposal.targetLand).owner ==
                msg.sender,
            "Not the owner of target land"
        );
        require(block.timestamp < proposal.expiresAt, "Swap proposal expired");

        swapApprovals[msg.sender][proposer] = true;
        emit SwapApproved(msg.sender, proposer, block.timestamp);

        // If both parties have approved, execute the swap
        if (
            swapApprovals[msg.sender][proposer] &&
            swapApprovals[proposer][msg.sender]
        ) {
            _executeSwap(proposal);
        }
    }

    function _executeSwap(SwapProposal memory proposal) internal {
        // Get the current owners
        address proposerOwner = landRegistry
            .getLandDetails(proposal.proposerLand)
            .owner;
        address targetOwner = landRegistry
            .getLandDetails(proposal.targetLand)
            .owner;

        // Create new land entries with swapped owners
        LandRegistry.Land memory newProposerLand = LandRegistry.Land({
            what3words: proposal.proposerLand,
            owner: targetOwner,
            claimedAt: block.timestamp,
            isClaimed: true
        });

        LandRegistry.Land memory newTargetLand = LandRegistry.Land({
            what3words: proposal.targetLand,
            owner: proposerOwner,
            claimedAt: block.timestamp,
            isClaimed: true
        });

        // Update the lands
        landRegistry.updateLand(proposal.proposerLand, newProposerLand);
        landRegistry.updateLand(proposal.targetLand, newTargetLand);

        // Reset the proposal and approvals
        swapProposals[proposal.proposer].isActive = false;
        swapApprovals[proposal.proposer][msg.sender] = false;
        swapApprovals[msg.sender][proposal.proposer] = false;
        activeSwapCount[proposal.proposer]--;

        emit SwapExecuted(
            proposal.proposer,
            proposal.proposerLand,
            proposal.targetLand,
            block.timestamp
        );
    }

    function cancelSwap() external nonReentrant {
        SwapProposal memory proposal = swapProposals[msg.sender];
        require(proposal.isActive, "No active proposal");

        swapProposals[msg.sender].isActive = false;
        activeSwapCount[msg.sender]--;

        emit SwapCancelled(
            msg.sender,
            proposal.proposerLand,
            proposal.targetLand,
            block.timestamp
        );
    }

    function checkAndExpireSwaps() external {
        address[] memory users = new address[](MAX_ACTIVE_SWAPS);
        uint256 count = 0;

        // Find expired swaps
        for (uint256 i = 0; i < MAX_ACTIVE_SWAPS; i++) {
            address user = address(uint160(i + 1)); // Simple way to iterate through addresses
            if (
                swapProposals[user].isActive &&
                block.timestamp >= swapProposals[user].expiresAt
            ) {
                users[count] = user;
                count++;
            }
        }

        // Expire the found swaps
        for (uint256 i = 0; i < count; i++) {
            SwapProposal memory proposal = swapProposals[users[i]];
            swapProposals[users[i]].isActive = false;
            activeSwapCount[users[i]]--;

            emit SwapExpired(
                users[i],
                proposal.proposerLand,
                proposal.targetLand,
                block.timestamp
            );
        }
    }
}
