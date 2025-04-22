// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LandRegistry is Ownable, ReentrancyGuard {
    constructor() Ownable(msg.sender) {}

    struct Land {
        string what3words;
        address owner;
        uint256 claimedAt;
        bool isClaimed;
    }

    // Mapping from what3words to Land
    mapping(string => Land) public lands;

    // Array of lands owned by each user
    mapping(address => string[]) public userLands;

    // Mapping from user to their neighbors' lands
    mapping(address => mapping(string => bool)) public userNeighbors;

    // Contract addresses
    address public landSwap;
    address public userRegistry;

    // Constants
    uint256 public constant MAX_CLAIM_DISTANCE = 3; // 9 feet ≈ 3 meters

    // Events
    event LandClaimed(
        address indexed owner,
        string what3words,
        uint256 timestamp
    );
    event LandReleased(
        address indexed owner,
        string what3words,
        uint256 timestamp
    );
    event LandSurrounded(
        string what3words,
        address newOwner,
        uint256 timestamp
    );
    event LandUpdated(string what3words, address newOwner, uint256 timestamp);
    event LandBatchUpdated(
        string[] what3words,
        address newOwner,
        uint256 timestamp
    );

    // Modifiers
    modifier onlyAuthorized() {
        require(
            msg.sender == owner() ||
                msg.sender == landSwap ||
                msg.sender == userRegistry,
            "Not authorized"
        );
        _;
    }

    // Function to set the LandSwap contract address
    function setLandSwap(address _landSwap) external onlyOwner {
        require(_landSwap != address(0), "Invalid address");
        landSwap = _landSwap;
    }

    // Function to set the UserRegistry contract address
    function setUserRegistry(address _userRegistry) external onlyOwner {
        require(_userRegistry != address(0), "Invalid address");
        userRegistry = _userRegistry;
    }

    function claimLand(string memory what3words) external nonReentrant {
        require(!lands[what3words].isClaimed, "Land already claimed");
        require(bytes(what3words).length > 0, "Invalid what3words");

        lands[what3words] = Land({
            what3words: what3words,
            owner: msg.sender,
            claimedAt: block.timestamp,
            isClaimed: true
        });

        userLands[msg.sender].push(what3words);
        emit LandClaimed(msg.sender, what3words, block.timestamp);
    }

    function releaseLand(string memory what3words) external nonReentrant {
        require(lands[what3words].isClaimed, "Land not claimed");
        require(
            lands[what3words].owner == msg.sender || userRegistry == msg.sender,
            "Not the owner or user registry contract"
        );

        address landOwner = lands[what3words].owner;
        lands[what3words].isClaimed = false;
        lands[what3words].owner = address(0);

        // Remove from user's lands array
        string[] storage landsArray = userLands[landOwner];
        for (uint256 i = 0; i < landsArray.length; i++) {
            if (
                keccak256(bytes(landsArray[i])) == keccak256(bytes(what3words))
            ) {
                // Swap with last element and pop
                landsArray[i] = landsArray[landsArray.length - 1];
                landsArray.pop();
                break;
            }
        }

        emit LandReleased(landOwner, what3words, block.timestamp);
    }

    function getUserLands(
        address user
    ) external view returns (string[] memory) {
        return userLands[user];
    }

    function getLandDetails(
        string memory what3words
    ) external view returns (Land memory) {
        return lands[what3words];
    }

    // Function to update land details (used by LandSwap)
    function updateLand(
        string memory what3words,
        Land memory newLand
    ) external onlyAuthorized nonReentrant {
        require(lands[what3words].isClaimed, "Land not claimed");
        require(bytes(what3words).length > 0, "Invalid what3words");

        address oldOwner = lands[what3words].owner;
        address newOwner = newLand.owner;

        // Update the land
        lands[what3words] = newLand;

        // Update user lands arrays
        if (oldOwner != newOwner) {
            // Remove from old owner's array
            string[] storage oldOwnerLands = userLands[oldOwner];
            for (uint256 i = 0; i < oldOwnerLands.length; i++) {
                if (
                    keccak256(bytes(oldOwnerLands[i])) ==
                    keccak256(bytes(what3words))
                ) {
                    oldOwnerLands[i] = oldOwnerLands[oldOwnerLands.length - 1];
                    oldOwnerLands.pop();
                    break;
                }
            }

            // Add to new owner's array
            if (newOwner != address(0)) {
                userLands[newOwner].push(what3words);
            }
        }

        emit LandUpdated(what3words, newLand.owner, block.timestamp);
    }

    // Function to batch update lands (optimization)
    function batchUpdateLands(
        string[] memory what3words,
        address newOwner
    ) external onlyAuthorized nonReentrant {
        require(what3words.length > 0, "Empty array");
        require(newOwner != address(0), "Invalid owner");

        for (uint256 i = 0; i < what3words.length; i++) {
            if (lands[what3words[i]].isClaimed) {
                address oldOwner = lands[what3words[i]].owner;
                lands[what3words[i]].owner = newOwner;

                // Update user lands arrays
                if (oldOwner != newOwner) {
                    // Remove from old owner's array
                    string[] storage oldOwnerLands = userLands[oldOwner];
                    for (uint256 j = 0; j < oldOwnerLands.length; j++) {
                        if (
                            keccak256(bytes(oldOwnerLands[j])) ==
                            keccak256(bytes(what3words[i]))
                        ) {
                            oldOwnerLands[j] = oldOwnerLands[
                                oldOwnerLands.length - 1
                            ];
                            oldOwnerLands.pop();
                            break;
                        }
                    }

                    // Add to new owner's array
                    userLands[newOwner].push(what3words[i]);
                }
            }
        }

        emit LandBatchUpdated(what3words, newOwner, block.timestamp);
    }
}
