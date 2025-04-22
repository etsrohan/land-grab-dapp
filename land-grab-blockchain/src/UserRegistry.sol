// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LandRegistry} from "./LandRegistry.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract UserRegistry is ReentrancyGuard {
    LandRegistry public landRegistry;

    struct User {
        address userAddress;
        string username;
        bool isActive;
        uint256 createdAt;
        uint256 lastActive;
    }

    // Constants
    uint256 public constant MIN_USERNAME_LENGTH = 3;
    uint256 public constant MAX_USERNAME_LENGTH = 32;
    bytes32 public constant USERNAME_REGEX =
        keccak256(abi.encodePacked("^[a-zA-Z0-9_]+$"));

    // Mappings
    mapping(address => User) public users;
    mapping(string => address) public usernameToAddress;
    mapping(address => uint256) public userLandCount;

    // Events
    event UserRegistered(
        address indexed user,
        string username,
        uint256 timestamp
    );
    event UserDeleted(address indexed user, uint256 timestamp);
    event UsernameChanged(
        address indexed user,
        string oldUsername,
        string newUsername,
        uint256 timestamp
    );

    constructor(address _landRegistry) {
        require(_landRegistry != address(0), "Invalid land registry address");
        landRegistry = LandRegistry(_landRegistry);
    }

    function registerUser(string memory username) external nonReentrant {
        require(!users[msg.sender].isActive, "User already registered");
        require(
            usernameToAddress[username] == address(0),
            "Username already taken"
        );
        require(_isValidUsername(username), "Invalid username format");

        users[msg.sender] = User({
            userAddress: msg.sender,
            username: username,
            isActive: true,
            createdAt: block.timestamp,
            lastActive: block.timestamp
        });

        usernameToAddress[username] = msg.sender;
        emit UserRegistered(msg.sender, username, block.timestamp);
    }

    function deleteUser() external nonReentrant {
        require(users[msg.sender].isActive, "User not registered");

        // Get user's lands
        string[] memory userLands = landRegistry.getUserLands(msg.sender);

        // Release all user's lands
        for (uint256 i = 0; i < userLands.length; i++) {
            // Check if the user still owns the land
            LandRegistry.Land memory land = landRegistry.getLandDetails(
                userLands[i]
            );
            if (land.owner == msg.sender) {
                landRegistry.releaseLand(userLands[i]);
            }
        }

        // Store username for event emission
        string memory username = users[msg.sender].username;

        // Delete user data
        delete usernameToAddress[username];
        delete users[msg.sender];
        delete userLandCount[msg.sender];

        emit UserDeleted(msg.sender, block.timestamp);
    }

    function changeUsername(string memory newUsername) external nonReentrant {
        require(users[msg.sender].isActive, "User not registered");
        require(
            usernameToAddress[newUsername] == address(0),
            "Username already taken"
        );
        require(_isValidUsername(newUsername), "Invalid username format");

        string memory oldUsername = users[msg.sender].username;
        delete usernameToAddress[oldUsername];

        users[msg.sender].username = newUsername;
        users[msg.sender].lastActive = block.timestamp;
        usernameToAddress[newUsername] = msg.sender;

        emit UsernameChanged(
            msg.sender,
            oldUsername,
            newUsername,
            block.timestamp
        );
    }

    function getUser(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }

    function getUserByUsername(
        string memory username
    ) external view returns (User memory) {
        return users[usernameToAddress[username]];
    }

    function _isValidUsername(
        string memory username
    ) internal pure returns (bool) {
        bytes memory usernameBytes = bytes(username);
        if (
            usernameBytes.length < MIN_USERNAME_LENGTH ||
            usernameBytes.length > MAX_USERNAME_LENGTH
        ) {
            return false;
        }

        for (uint256 i = 0; i < usernameBytes.length; i++) {
            bytes1 char = usernameBytes[i];
            if (
                !(char >= 0x30 && char <= 0x39) && // 0-9
                !(char >= 0x41 && char <= 0x5A) && // A-Z
                !(char >= 0x61 && char <= 0x7A) && // a-z
                char != 0x5F // _
            ) {
                return false;
            }
        }
        return true;
    }
}
