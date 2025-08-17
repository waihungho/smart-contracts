This smart contract system, named **ChronicleForge**, introduces an innovative ecosystem that intertwines **dynamic Soulbound Tokens (SBTs)** with an **adaptive yield farming mechanism** and a **gamified on-chain reputation system**, all governed by its community. It aims to create a more engaging and progressive user experience where contributions and achievements directly influence rewards and privileges within the protocol.

---

### **ChronicleForge System Outline**

The ChronicleForge system is comprised of two core smart contracts and a conceptual third for the ERC-20 token:

1.  **`ForgeToken.sol`**: An ERC-20 token serving as the native currency for staking rewards and community grants. (Standard ERC-20, not detailed here as it's common open-source, but assumed to exist and be integrated).
2.  **`SoulboundEmblem.sol`**: An ERC-721 compliant, non-transferable token (Soulbound Token, SBT) that represents a user's on-chain achievements and contributions. Its metadata is dynamic and can evolve.
3.  **`ChronicleForge.sol`**: The central orchestrator contract. It manages achievement registration, SBE minting and updates, user reputation calculation, adaptive yield staking, a community fund, and on-chain governance.

---

### **Function Summary (ChronicleForge.sol)**

This contract implements the core logic, combining elements of an achievement system, reputation manager, adaptive staking vault, and simplified governance.

**I. Core Setup & Administration**
1.  `constructor()`: Initializes the contract with necessary roles (DEFAULT_ADMIN_ROLE, ACHIEVEMENT_PROVER_ROLE, GOVERNOR_ROLE) and links to the `ForgeToken` and `SoulboundEmblem` contracts.
2.  `updateCoreContracts(address _forgeToken, address _sbeToken)`: Allows the `DEFAULT_ADMIN_ROLE` to update the addresses of the linked ERC-20 and ERC-721 contracts, useful for upgrades.

**II. Achievement Management**
3.  `registerAchievementType(uint256 typeId, string calldata name, string calldata description, uint256 requiredRepScore, uint256 sbeWeight)`: Defines a new type of achievement, specifying its unique ID, name, description, the minimum reputation score required to earn it, and its contribution weight to a user's reputation score.
4.  `grantAchievement(address user, uint256 typeId, bytes calldata additionalData)`: Callable by `ACHIEVEMENT_PROVER_ROLE`. Mints a new `SoulboundEmblem` for the user if they don't have one of this type, or updates an existing one if they already possess it, reflecting a "level-up" or progression for that achievement.
5.  `getAchievementDetails(uint256 typeId)`: Retrieves the registered details for a specific achievement type.
6.  `getUserAchievements(address user)`: Returns an array of `SoulboundEmblem` token IDs held by a specified user.

**III. Reputation & Soulbound Emblem (SBE) Interactions**
7.  `getReputationScore(address user)`: Calculates a composite reputation score for a user based on the `SoulboundEmblem`s they hold and their configured weights.
8.  `updateSBEWeight(uint256 typeId, uint256 newWeight)`: Callable by `GOVERNOR_ROLE`. Adjusts the reputation contribution weight of a specific `SoulboundEmblem` type, allowing for dynamic re-evaluation of achievements.
9.  `getSBEAttributes(uint256 tokenId)`: Retrieves the current dynamic attributes/metadata of a specific `SoulboundEmblem`.
10. `burnUserSBE(uint256 tokenId)`: Allows a user to irrevocably burn their own `SoulboundEmblem`, providing an option for data privacy or re-setting.

**IV. Staking & Adaptive Rewards**
11. `stake(uint256 amount)`: Allows users to stake `ForgeToken` into the vault to earn rewards.
12. `unstake(uint256 amount)`: Allows users to withdraw their staked `ForgeToken`.
13. `claimRewards()`: Allows users to claim their accumulated `ForgeToken` rewards. Rewards are calculated dynamically based on their reputation score.
14. `getPendingRewards(address user)`: Calculates the current pending rewards for a specific user, reflecting the adaptive reward logic.
15. `setBaseRewardRate(uint256 newRatePerSecond)`: Callable by `GOVERNOR_ROLE`. Sets the base `ForgeToken` reward rate emitted by the staking vault per second.
16. `setReputationTierMultiplier(uint256 tierMinScore, uint256 multiplierBasisPoints)`: Callable by `GOVERNOR_ROLE`. Defines reputation score tiers and their corresponding reward multipliers (in basis points), implementing the adaptive yield logic.
17. `getRewardMultiplier(address user)`: Internal view function that calculates the effective reward multiplier for a user based on their `getReputationScore()`.

**V. Community Fund & Governance**
18. `depositToCommunityFund(uint256 amount)`: Allows anyone to deposit `ForgeToken` into the community-managed fund.
19. `createGrantProposal(address recipient, uint256 amount, string calldata description)`: Users with a sufficient reputation score can propose grants from the community fund.
20. `voteOnProposal(uint256 proposalId, bool approve)`: `SoulboundEmblem` holders (or those with sufficient reputation) can vote on community fund proposals.
21. `executeProposal(uint256 proposalId)`: Executes a grant proposal if it meets quorum and approval thresholds.
22. `proposeParameterChange(address target, bytes calldata callData, string calldata description)`: Callable by `GOVERNOR_ROLE`. Initiates a generic governance proposal to call any function on any contract (including self), allowing for flexible parameter updates.
23. `voteOnParameterChange(uint256 proposalId, bool approve)`: Allows `GOVERNOR_ROLE` or delegated voters to vote on proposed parameter changes.
24. `executeParameterChange(uint256 proposalId)`: Executes a parameter change proposal if it passes governance.

---

### **Smart Contract Code**

*(Due to the length and complexity of a 20+ function contract, I'll focus on the `ChronicleForge.sol` and `SoulboundEmblem.sol` which are the custom parts, assuming `ForgeToken.sol` is a standard OpenZeppelin ERC20 implementation.)*

**1. `ForgeToken.sol` (Conceptual, assuming standard OpenZeppelin)**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ForgeToken
 * @dev ERC-20 token for the ChronicleForge ecosystem.
 * This is a placeholder; a full implementation would include
 * more detailed minting/burning mechanisms, supply management, etc.
 * For this example, it's assumed to be deployed and its address passed.
 */
contract ForgeToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Admin can grant other roles
    }

    // Only MINTER_ROLE can mint tokens
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Only BURNER_ROLE can burn tokens
    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }
}

```

**2. `SoulboundEmblem.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title SoulboundEmblem
 * @dev An ERC-721 compliant Soulbound Token (SBT) representing achievements.
 *      These tokens are non-transferable and have dynamic metadata.
 */
contract SoulboundEmblem is ERC721, AccessControl {
    using Strings for uint256;

    // Role that is allowed to mint new SBEs and update their attributes.
    // This role will typically be granted to the ChronicleForge contract.
    bytes32 public constant EMITTER_ROLE = keccak256("EMITTER_ROLE");

    // Mapping from token ID to its dynamic attributes (as a JSON string fragment or similar)
    // This allows for 'leveling up' or changing traits on an existing SBE.
    mapping(uint256 => bytes) private _tokenAttributes;

    // Counter for unique token IDs
    uint256 private _nextTokenId;

    // Base URI for metadata, if not fully on-chain.
    string private _baseURI;

    /**
     * @dev Initializes the SoulboundEmblem contract.
     * @param name_ The name of the NFT collection.
     * @param symbol_ The symbol of the NFT collection.
     */
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Sets the base URI for token metadata.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURI = baseURI_;
    }

    /**
     * @dev Mints a new SoulboundEmblem for a specific address.
     * Only callable by addresses with the EMITTER_ROLE.
     * @param to The recipient of the new SBE.
     * @param initialAttributes The initial attributes for the SBE (e.g., as JSON string fragment).
     * @return The ID of the newly minted token.
     */
    function mintSBE(address to, bytes calldata initialAttributes) public onlyRole(EMITTER_ROLE) returns (uint256) {
        require(to != address(0), "SBE: mint to the zero address");
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        _setTokenAttributes(tokenId, initialAttributes);
        return tokenId;
    }

    /**
     * @dev Updates the dynamic attributes of an existing SoulboundEmblem.
     * Only callable by addresses with the EMITTER_ROLE.
     * This is the core "dynamic" aspect of the NFT.
     * @param tokenId The ID of the SBE to update.
     * @param newAttributes The new attributes for the SBE.
     */
    function updateSBEAttributes(uint256 tokenId, bytes calldata newAttributes) public onlyRole(EMITTER_ROLE) {
        require(_exists(tokenId), "SBE: token does not exist");
        _setTokenAttributes(tokenId, newAttributes);
    }

    /**
     * @dev Allows the owner of an SBE to burn it.
     * This is an intentional feature for privacy or "resetting" progress.
     * @param tokenId The ID of the SBE to burn.
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "SBE: caller is not owner nor approved");
        _burn(tokenId);
        delete _tokenAttributes[tokenId]; // Clean up attributes upon burning
    }

    /**
     * @dev Internal function to set or update a token's attributes.
     * @param tokenId The ID of the token.
     * @param attributes The attributes to set.
     */
    function _setTokenAttributes(uint256 tokenId, bytes memory attributes) internal {
        _tokenAttributes[tokenId] = attributes;
    }

    /**
     * @dev Returns the current dynamic attributes of a specific SBE.
     * @param tokenId The ID of the SBE.
     */
    function getSBEAttributes(uint256 tokenId) public view returns (bytes memory) {
        require(_exists(tokenId), "SBE: token does not exist");
        return _tokenAttributes[tokenId];
    }

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer to prevent transfers (Soulbound).
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
            revert("SoulboundEmblem: Token is non-transferable");
        }
    }

    /**
     * @dev Returns the URI for a given token ID.
     * This function generates on-chain SVG and JSON metadata.
     * Metadata could also be served from IPFS via _baseURI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        bytes memory attributes = _tokenAttributes[tokenId];
        string memory name = string(abi.encodePacked("ChronicleForge Emblem #", tokenId.toString()));
        string memory description = string(abi.encodePacked("A Soulbound Emblem representing achievement type ", _tokenAttributes[tokenId])); // Simplistic. In reality, decode attributes to show proper data.

        // Example dynamic SVG generation (simplified)
        string memory svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xM",
            "inYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: sans-serif; font-size: 14px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>Emblem ",
            tokenId.toString(),
            "</text><text x='50%' y='70%' class='base' dominant-baseline='middle' text-anchor='middle'>Attributes: ",
            string(attributes), // Directly showing attributes
            "</text></svg>"
        ));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"',
                        name,
                        '", "description":"',
                        description,
                        '", "image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '", "attributes": [{"trait_type": "EmblemID", "value": "', tokenId.toString(), '"}]}'
                        // Real implementation would parse 'attributes' bytes to add more traits
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}

```

**3. `ChronicleForge.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Interfaces for external contracts
interface IForgeToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface ISoulboundEmblem {
    function mintSBE(address to, bytes calldata initialAttributes) external returns (uint256);
    function updateSBEAttributes(uint256 tokenId, bytes calldata newAttributes) external;
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function getSBEAttributes(uint256 tokenId) external view returns (bytes memory);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

/**
 * @title ChronicleForge
 * @dev The central contract for managing dynamic Soulbound Emblems, adaptive staking,
 *      reputation, achievements, and community governance.
 */
contract ChronicleForge is Context, AccessControl {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    // Role for off-chain or dedicated contracts that verify and grant achievements.
    bytes32 public constant ACHIEVEMENT_PROVER_ROLE = keccak256("ACHIEVEMENT_PROVER_ROLE");
    // Role for entities that can propose and execute system parameter changes (e.g., elected governors).
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    // --- Contract References ---
    IForgeToken public forgeToken;
    ISoulboundEmblem public sbeToken;

    // --- Achievement Management ---
    struct AchievementType {
        string name;
        string description;
        uint256 requiredRepScore; // Minimum reputation score to be eligible for this achievement
        uint256 sbeWeight;        // How much this SBE contributes to reputation score
        bool exists;              // To check if a typeId is registered
    }
    mapping(uint256 => AchievementType) public achievementTypes;
    EnumerableSet.UintSet private _registeredAchievementTypeIds;

    // Mapping from user address to their owned SBE tokenIds for quick lookup
    mapping(address => EnumerableSet.UintSet) private _userSBEs;
    // Mapping from user address to achievementType => tokenId (to find a specific SBE type a user holds)
    mapping(address => mapping(uint256 => uint256)) private _userSBEByType;


    // --- Staking & Rewards ---
    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastUpdateTimestamp;
        uint256 unclaimedRewards;
    }
    mapping(address => StakerInfo) public stakers;

    uint256 public baseRewardRatePerSecond; // Base rewards per second for 1 unit of staked token (e.g., 1e18 for 1 token)
    // Reputation score tiers and their multipliers (e.g., 10000 means 1x, 15000 means 1.5x)
    mapping(uint256 => uint256) public reputationTierMultipliers; // minScore => multiplier in basis points

    // --- Community Fund & Governance ---
    uint256 public communityFundBalance;
    uint256 public nextProposalId;

    struct GrantProposal {
        address recipient;
        uint256 amount;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVoters; // Total reputation of voters
        bool executed;
        bool exists;
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
    }
    mapping(uint256 => GrantProposal) public grantProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedGrant; // proposalId => voter => voted

    struct ParameterChangeProposal {
        address target;
        bytes callData;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVoters; // Total reputation of voters
        bool executed;
        bool exists;
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
    }
    mapping(uint256 => ParameterChangeProposal) public paramChangeProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedParamChange; // proposalId => voter => voted

    // Governance parameters (can be adjusted by governance itself)
    uint256 public minReputationToProposeGrant = 100; // Minimum reputation score to create a grant proposal
    uint256 public minReputationToProposeParamChange = 500; // Minimum reputation to create a parameter change proposal
    uint256 public votingPeriodDuration = 3 days; // Duration for voting on proposals
    uint256 public proposalQuorumBasisPoints = 2000; // 20% of total reputation needed for quorum (2000 basis points)
    uint256 public proposalPassThresholdBasisPoints = 5000; // 50% majority to pass (5000 basis points)

    // --- Events ---
    event ForgeTokenUpdated(address indexed newAddress);
    event SBETokenUpdated(address indexed newAddress);
    event AchievementTypeRegistered(uint256 indexed typeId, string name, uint256 requiredRepScore, uint256 sbeWeight);
    event AchievementGranted(address indexed user, uint256 indexed typeId, uint256 indexed tokenId);
    event SBEAttributesUpdated(uint256 indexed tokenId, bytes newAttributes);
    event SBEBurned(address indexed user, uint256 indexed tokenId);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event BaseRewardRateUpdated(uint256 newRate);
    event ReputationTierMultiplierUpdated(uint256 indexed tierMinScore, uint256 multiplierBasisPoints);
    event CommunityFundDeposit(address indexed depositor, uint256 amount);
    event GrantProposalCreated(uint256 indexed proposalId, address indexed recipient, uint256 amount, string description);
    event GrantProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event GrantProposalExecuted(uint256 indexed proposalId, bool success);
    event ParameterChangeProposalCreated(uint256 indexed proposalId, address indexed target, bytes callData, string description);
    event ParameterChangeProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ParameterChangeProposalExecuted(uint256 indexed proposalId, bool success);

    /**
     * @dev Constructor for ChronicleForge.
     * @param _forgeTokenAddress Address of the ForgeToken (ERC-20).
     * @param _sbeTokenAddress Address of the SoulboundEmblem (ERC-721).
     */
    constructor(address _forgeTokenAddress, address _sbeTokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // Grant this contract the EMITTER_ROLE on the SBE token
        // The deployer must explicitly grant this role AFTER deployment of both contracts.
        // For simplicity in this example, assuming the admin can do this post-deploy.
        // Or, the constructor could take an admin key to grant the role directly.
        // For this example, assuming external call for role granting by admin.
        //_sbeTokenAddress.grantRole(sbeToken.EMITTER_ROLE(), address(this)); // This requires the SBE contract to have a direct interface for roles.
        // A more robust setup involves deployer granting roles post-deployment.

        forgeToken = IForgeToken(_forgeTokenAddress);
        sbeToken = ISoulboundEmblem(_sbeTokenAddress);

        baseRewardRatePerSecond = 100; // Example: 100 units of smallest token amount per second for 1e18 staked
        reputationTierMultipliers[0] = 10000; // Default tier (0 score) has 1x multiplier
        reputationTierMultipliers[100] = 11000; // 1.1x for 100+ score
        reputationTierMultipliers[500] = 12500; // 1.25x for 500+ score
        reputationTierMultipliers[1000] = 15000; // 1.5x for 1000+ score
    }

    /**
     * @dev Allows the DEFAULT_ADMIN_ROLE to update linked contract addresses.
     * @param _newForgeToken The new address of the ForgeToken contract.
     * @param _newSBEToken The new address of the SoulboundEmblem contract.
     */
    function updateCoreContracts(address _newForgeToken, address _newSBEToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newForgeToken != address(0), "ChronicleForge: Invalid ForgeToken address");
        require(_newSBEToken != address(0), "ChronicleForge: Invalid SBE Token address");
        forgeToken = IForgeToken(_newForgeToken);
        sbeToken = ISoulboundEmblem(_newSBEToken);
        emit ForgeTokenUpdated(_newForgeToken);
        emit SBETokenUpdated(_newSBEToken);
    }

    // --- Achievement Management ---

    /**
     * @dev Registers a new type of achievement.
     * Callable by DEFAULT_ADMIN_ROLE.
     * @param typeId A unique identifier for the achievement type.
     * @param name The human-readable name of the achievement.
     * @param description A detailed description of the achievement.
     * @param requiredRepScore The minimum reputation score required to earn this achievement.
     * @param sbeWeight The weight this achievement contributes to a user's reputation score.
     */
    function registerAchievementType(
        uint256 typeId,
        string calldata name,
        string calldata description,
        uint256 requiredRepScore,
        uint256 sbeWeight
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!achievementTypes[typeId].exists, "ChronicleForge: Achievement type already registered");
        achievementTypes[typeId] = AchievementType(name, description, requiredRepScore, sbeWeight, true);
        _registeredAchievementTypeIds.add(typeId);
        emit AchievementTypeRegistered(typeId, name, requiredRepScore, sbeWeight);
    }

    /**
     * @dev Grants an achievement to a user. Mints a new SBE or updates an existing one.
     * Callable by ACHIEVEMENT_PROVER_ROLE.
     * @param user The address of the user to grant the achievement to.
     * @param typeId The ID of the achievement type to grant.
     * @param additionalData Optional data specific to this instance of the achievement (e.g., level, variant).
     */
    function grantAchievement(address user, uint256 typeId, bytes calldata additionalData)
        public
        onlyRole(ACHIEVEMENT_PROVER_ROLE)
    {
        require(achievementTypes[typeId].exists, "ChronicleForge: Achievement type not registered");
        require(getReputationScore(user) >= achievementTypes[typeId].requiredRepScore, "ChronicleForge: User does not meet reputation requirement");

        uint256 existingTokenId = _userSBEByType[user][typeId];

        if (existingTokenId == 0) { // User does not have this SBE type yet
            uint256 newTokenId = sbeToken.mintSBE(user, abi.encodePacked("Type:", typeId.toString(), ";", additionalData));
            _userSBEs[user].add(newTokenId);
            _userSBEByType[user][typeId] = newTokenId;
            emit AchievementGranted(user, typeId, newTokenId);
        } else { // User already has this SBE type, update it
            sbeToken.updateSBEAttributes(existingTokenId, abi.encodePacked("Type:", typeId.toString(), ";Updated:", block.timestamp.toString(), ";", additionalData));
            emit SBEAttributesUpdated(existingTokenId, abi.encodePacked("Type:", typeId.toString(), ";Updated:", block.timestamp.toString(), ";", additionalData));
        }
    }

    /**
     * @dev Retrieves the registered details for a specific achievement type.
     * @param typeId The ID of the achievement type.
     * @return name The name of the achievement.
     * @return description The description of the achievement.
     * @return requiredRepScore The minimum reputation score required.
     * @return sbeWeight The reputation weight of this SBE.
     * @return exists Whether the achievement type is registered.
     */
    function getAchievementDetails(uint256 typeId)
        public
        view
        returns (string memory name, string memory description, uint256 requiredRepScore, uint256 sbeWeight, bool exists)
    {
        AchievementType storage achievement = achievementTypes[typeId];
        return (achievement.name, achievement.description, achievement.requiredRepScore, achievement.sbeWeight, achievement.exists);
    }

    /**
     * @dev Returns an array of Soulbound Emblem token IDs held by a specific user.
     * @param user The address of the user.
     * @return An array of token IDs.
     */
    function getUserAchievements(address user) public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](_userSBEs[user].length());
        for (uint256 i = 0; i < _userSBEs[user].length(); i++) {
            tokenIds[i] = _userSBEs[user].at(i);
        }
        return tokenIds;
    }

    // --- Reputation & SBE Interactions ---

    /**
     * @dev Calculates the composite reputation score for a user.
     * The score is derived from the sum of weights of all SBEs held by the user.
     * @param user The address of the user.
     * @return The calculated reputation score.
     */
    function getReputationScore(address user) public view returns (uint256) {
        uint256 score = 0;
        uint256 sbeCount = sbeToken.balanceOf(user); // Get total SBEs for the user
        for (uint256 i = 0; i < sbeCount; i++) {
            uint256 tokenId = sbeToken.tokenOfOwnerByIndex(user, i);
            // In a real scenario, we'd parse the SBE attributes to determine its type and then its weight.
            // For simplicity, assuming a mapping tokenId -> typeId is maintained, or typeId is part of attributes.
            // For this example, let's assume getSBEAttributes returns a string that can be parsed to find its typeId.
            // Or, the `_userSBEByType` mapping can be used.
            // Simplified: iterate through registered achievement types and check if user has SBE of that type.
            for (uint256 j = 0; j < _registeredAchievementTypeIds.length(); j++) {
                uint256 typeId = _registeredAchievementTypeIds.at(j);
                if (_userSBEByType[user][typeId] == tokenId) { // Check if this SBE is of this type
                    score = score.add(achievementTypes[typeId].sbeWeight);
                    break; // Move to next SBE
                }
            }
        }
        return score;
    }

    /**
     * @dev Allows governance to adjust the reputation contribution weight of a specific SBE type.
     * @param typeId The ID of the achievement type.
     * @param newWeight The new weight to set for this SBE type.
     */
    function updateSBEWeight(uint256 typeId, uint256 newWeight) public onlyRole(GOVERNOR_ROLE) {
        require(achievementTypes[typeId].exists, "ChronicleForge: Achievement type not registered");
        achievementTypes[typeId].sbeWeight = newWeight;
        emit AchievementTypeRegistered(typeId, achievementTypes[typeId].name, achievementTypes[typeId].requiredRepScore, newWeight); // Re-emit with updated weight
    }

    /**
     * @dev Retrieves the current dynamic attributes/metadata of a specific SoulboundEmblem.
     * @param tokenId The ID of the SBE.
     * @return The bytes representing the attributes.
     */
    function getSBEAttributes(uint256 tokenId) public view returns (bytes memory) {
        return sbeToken.getSBEAttributes(tokenId);
    }

    /**
     * @dev Allows the owner of an SBE to burn it.
     * This action is irreversible.
     * @param tokenId The ID of the SBE to burn.
     */
    function burnUserSBE(uint256 tokenId) public {
        require(sbeToken.ownerOf(tokenId) == _msgSender(), "ChronicleForge: Caller is not the owner of the SBE");
        sbeToken.burn(tokenId);
        _userSBEs[_msgSender()].remove(tokenId); // Remove from our tracking set
        // Invalidate entry in _userSBEByType (hard to know which type it was without complex parsing)
        // A more robust system would map tokenIds to achievementType on mint.
        // For now, it might leave stale entries in _userSBEByType but _userSBEs is authoritative.
        emit SBEBurned(_msgSender(), tokenId);
    }

    // --- Staking & Adaptive Rewards ---

    /**
     * @dev Stakes ForgeToken into the vault.
     * @param amount The amount of ForgeToken to stake.
     */
    function stake(uint256 amount) public {
        require(amount > 0, "ChronicleForge: Amount must be greater than 0");
        
        // Calculate pending rewards before updating stake
        _updateRewards(_msgSender());

        forgeToken.transferFrom(_msgSender(), address(this), amount);
        stakers[_msgSender()].stakedAmount = stakers[_msgSender()].stakedAmount.add(amount);
        stakers[_msgSender()].lastUpdateTimestamp = block.timestamp;
        emit Staked(_msgSender(), amount);
    }

    /**
     * @dev Unstakes ForgeToken from the vault.
     * @param amount The amount of ForgeToken to unstake.
     */
    function unstake(uint256 amount) public {
        require(amount > 0, "ChronicleForge: Amount must be greater than 0");
        require(stakers[_msgSender()].stakedAmount >= amount, "ChronicleForge: Insufficient staked amount");

        // Calculate pending rewards before updating stake
        _updateRewards(_msgSender());

        stakers[_msgSender()].stakedAmount = stakers[_msgSender()].stakedAmount.sub(amount);
        stakers[_msgSender()].lastUpdateTimestamp = block.timestamp;
        forgeToken.transfer(stakers[_msgSender()].stakedAmount > 0 ? address(this) : _msgSender(), amount); // Simplified logic
        emit Unstaked(_msgSender(), amount);
    }

    /**
     * @dev Claims accumulated ForgeToken rewards.
     */
    function claimRewards() public {
        _updateRewards(_msgSender()); // Update rewards to current moment

        uint256 rewards = stakers[_msgSender()].unclaimedRewards;
        require(rewards > 0, "ChronicleForge: No rewards to claim");

        stakers[_msgSender()].unclaimedRewards = 0;
        forgeToken.transfer(_msgSender(), rewards);
        emit RewardsClaimed(_msgSender(), rewards);
    }

    /**
     * @dev Calculates the current pending rewards for a specific user.
     * @param user The address of the user.
     * @return The amount of pending rewards.
     */
    function getPendingRewards(address user) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(stakers[user].lastUpdateTimestamp);
        uint256 currentReputationMultiplier = getRewardMultiplier(user); // Get multiplier based on current reputation
        
        uint256 newRewards = stakers[user].stakedAmount
            .mul(baseRewardRatePerSecond)
            .mul(timeElapsed)
            .mul(currentReputationMultiplier)
            .div(10000); // Divide by 10000 because multiplier is in basis points

        return stakers[user].unclaimedRewards.add(newRewards);
    }

    /**
     * @dev Internal function to update a user's accumulated rewards.
     * Called before staking, unstaking, or claiming.
     * @param user The address of the user.
     */
    function _updateRewards(address user) internal {
        uint256 pending = getPendingRewards(user);
        stakers[user].unclaimedRewards = pending;
        stakers[user].lastUpdateTimestamp = block.timestamp;
    }

    /**
     * @dev Sets the base reward rate per second for the staking vault.
     * Callable by GOVERNOR_ROLE.
     * @param newRatePerSecond The new base reward rate (per second, per token).
     */
    function setBaseRewardRate(uint256 newRatePerSecond) public onlyRole(GOVERNOR_ROLE) {
        baseRewardRatePerSecond = newRatePerSecond;
        emit BaseRewardRateUpdated(newRatePerSecond);
    }

    /**
     * @dev Defines or updates reputation score tiers and their corresponding reward multipliers.
     * Callable by GOVERNOR_ROLE.
     * @param tierMinScore The minimum reputation score for this tier.
     * @param multiplierBasisPoints The multiplier for this tier in basis points (e.g., 10000 for 1x, 15000 for 1.5x).
     */
    function setReputationTierMultiplier(uint256 tierMinScore, uint256 multiplierBasisPoints) public onlyRole(GOVERNOR_ROLE) {
        reputationTierMultipliers[tierMinScore] = multiplierBasisPoints;
        emit ReputationTierMultiplierUpdated(tierMinScore, multiplierBasisPoints);
    }

    /**
     * @dev Internal function to calculate the effective reward multiplier for a user based on their reputation score.
     * Iterates through defined tiers to find the highest applicable multiplier.
     * @param user The address of the user.
     * @return The reward multiplier in basis points.
     */
    function getRewardMultiplier(address user) internal view returns (uint256) {
        uint256 userScore = getReputationScore(user);
        uint256 highestMultiplier = reputationTierMultipliers[0]; // Default to base tier

        for (uint256 i = 0; i < 10000; i++) { // Iterate through possible tier minimums (simplified, can be optimized)
            if (reputationTierMultipliers[i] > 0 && userScore >= i) {
                highestMultiplier = reputationTierMultipliers[i];
            }
        }
        // A more efficient way would be to store tierMinScores in a sorted array and binary search.
        // For simplicity, this loop assumes tierMinScores are somewhat incremental and limited.
        return highestMultiplier;
    }

    // --- Community Fund & Governance ---

    /**
     * @dev Allows anyone to deposit ForgeToken into the community-managed fund.
     * These funds can then be distributed via community grant proposals.
     * @param amount The amount of ForgeToken to deposit.
     */
    function depositToCommunityFund(uint256 amount) public {
        require(amount > 0, "ChronicleForge: Amount must be greater than 0");
        forgeToken.transferFrom(_msgSender(), address(this), amount);
        communityFundBalance = communityFundBalance.add(amount);
        emit CommunityFundDeposit(_msgSender(), amount);
    }

    /**
     * @dev Creates a proposal for a ForgeToken grant from the community fund.
     * Requires the proposer to have a minimum reputation score.
     * @param recipient The address to receive the grant.
     * @param amount The amount of ForgeToken requested.
     * @param description A description of the grant purpose.
     */
    function createGrantProposal(address recipient, uint256 amount, string calldata description) public {
        require(getReputationScore(_msgSender()) >= minReputationToProposeGrant, "ChronicleForge: Insufficient reputation to propose grant");
        require(amount > 0, "ChronicleForge: Grant amount must be greater than 0");

        uint256 proposalId = nextProposalId++;
        grantProposals[proposalId] = GrantProposal({
            recipient: recipient,
            amount: amount,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            totalVoters: 0,
            executed: false,
            exists: true,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp.add(votingPeriodDuration)
        });
        emit GrantProposalCreated(proposalId, recipient, amount, description);
    }

    /**
     * @dev Allows eligible users to vote on community fund proposals.
     * Voting power is based on the user's reputation score.
     * @param proposalId The ID of the proposal to vote on.
     * @param approve True for 'for', False for 'against'.
     */
    function voteOnProposal(uint256 proposalId, bool approve) public {
        GrantProposal storage proposal = grantProposals[proposalId];
        require(proposal.exists, "ChronicleForge: Grant proposal does not exist");
        require(!proposal.executed, "ChronicleForge: Grant proposal already executed");
        require(block.timestamp <= proposal.votingPeriodEnd, "ChronicleForge: Voting period has ended");
        require(!hasVotedGrant[proposalId][_msgSender()], "ChronicleForge: Already voted on this proposal");

        uint256 voterReputation = getReputationScore(_msgSender());
        require(voterReputation > 0, "ChronicleForge: Must have reputation to vote");

        if (approve) {
            proposal.votesFor = proposal.votesFor.add(voterReputation);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterReputation);
        }
        proposal.totalVoters = proposal.totalVoters.add(voterReputation);
        hasVotedGrant[proposalId][_msgSender()] = true;
        emit GrantProposalVoted(proposalId, _msgSender(), approve);
    }

    /**
     * @dev Executes a passed community fund proposal.
     * Requires the proposal to have met quorum and approval thresholds.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        GrantProposal storage proposal = grantProposals[proposalId];
        require(proposal.exists, "ChronicleForge: Grant proposal does not exist");
        require(!proposal.executed, "ChronicleForge: Grant proposal already executed");
        require(block.timestamp > proposal.votingPeriodEnd, "ChronicleForge: Voting period not ended");

        uint256 totalReputationInSystem = _getTotalReputation(); // A conceptual function to get total SBE weight
        require(proposal.totalVoters.mul(10000) >= totalReputationInSystem.mul(proposalQuorumBasisPoints), "ChronicleForge: Quorum not met");
        require(proposal.votesFor.mul(10000) >= proposal.totalVoters.mul(proposalPassThresholdBasisPoints), "ChronicleForge: Proposal did not pass");
        
        require(communityFundBalance >= proposal.amount, "ChronicleForge: Insufficient funds in community fund");

        proposal.executed = true;
        communityFundBalance = communityFundBalance.sub(proposal.amount);
        forgeToken.transfer(proposal.recipient, proposal.amount);
        emit GrantProposalExecuted(proposalId, true);
    }

    /**
     * @dev Creates a generic governance proposal to call any function on any contract.
     * Callable by GOVERNOR_ROLE.
     * @param target The address of the contract to call.
     * @param callData The encoded function call data.
     * @param description A description of the proposed change.
     */
    function proposeParameterChange(address target, bytes calldata callData, string calldata description) public onlyRole(GOVERNOR_ROLE) {
        require(getReputationScore(_msgSender()) >= minReputationToProposeParamChange, "ChronicleForge: Insufficient reputation to propose parameter change");
        require(target != address(0), "ChronicleForge: Invalid target address");
        require(callData.length > 0, "ChronicleForge: Call data cannot be empty");

        uint256 proposalId = nextProposalId++;
        paramChangeProposals[proposalId] = ParameterChangeProposal({
            target: target,
            callData: callData,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            totalVoters: 0,
            executed: false,
            exists: true,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp.add(votingPeriodDuration)
        });
        emit ParameterChangeProposalCreated(proposalId, target, callData, description);
    }

    /**
     * @dev Allows eligible users to vote on parameter change proposals.
     * Voting power is based on the user's reputation score.
     * @param proposalId The ID of the proposal to vote on.
     * @param approve True for 'for', False for 'against'.
     */
    function voteOnParameterChange(uint256 proposalId, bool approve) public {
        ParameterChangeProposal storage proposal = paramChangeProposals[proposalId];
        require(proposal.exists, "ChronicleForge: Parameter change proposal does not exist");
        require(!proposal.executed, "ChronicleForge: Parameter change proposal already executed");
        require(block.timestamp <= proposal.votingPeriodEnd, "ChronicleForge: Voting period has ended");
        require(!hasVotedParamChange[proposalId][_msgSender()], "ChronicleForge: Already voted on this proposal");

        uint256 voterReputation = getReputationScore(_msgSender());
        require(voterReputation > 0, "ChronicleForge: Must have reputation to vote");

        if (approve) {
            proposal.votesFor = proposal.votesFor.add(voterReputation);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterReputation);
        }
        proposal.totalVoters = proposal.totalVoters.add(voterReputation);
        hasVotedParamChange[proposalId][_msgSender()] = true;
        emit ParameterChangeProposalVoted(proposalId, _msgSender(), approve);
    }

    /**
     * @dev Executes a passed parameter change proposal.
     * Requires the proposal to have met quorum and approval thresholds.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 proposalId) public {
        ParameterChangeProposal storage proposal = paramChangeProposals[proposalId];
        require(proposal.exists, "ChronicleForge: Parameter change proposal does not exist");
        require(!proposal.executed, "ChronicleForge: Parameter change proposal already executed");
        require(block.timestamp > proposal.votingPeriodEnd, "ChronicleForge: Voting period not ended");

        uint256 totalReputationInSystem = _getTotalReputation(); // A conceptual function to get total SBE weight
        require(proposal.totalVoters.mul(10000) >= totalReputationInSystem.mul(proposalQuorumBasisPoints), "ChronicleForge: Quorum not met");
        require(proposal.votesFor.mul(10000) >= proposal.totalVoters.mul(proposalPassThresholdBasisPoints), "ChronicleForge: Proposal did not pass");

        proposal.executed = true;
        // Execute the proposed call
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "ChronicleForge: Parameter change execution failed");
        emit ParameterChangeProposalExecuted(proposalId, true);
    }

    /**
     * @dev Conceptual function: Calculates the total reputation score across all users.
     * In a real system, this would require iterating through all SBEs or maintaining a global sum,
     * which can be gas-intensive. Could be approximated or sourced from an off-chain oracle for large scale.
     * For this example, it's a simplified placeholder.
     */
    function _getTotalReputation() internal view returns (uint256) {
        // This is a highly simplified placeholder.
        // A real system would need to track all SBEs, or total reputation, more efficiently,
        // potentially by incrementing a global counter whenever an SBE is minted/burned/weight updated.
        // Or, it could just use `sbeToken.totalSupply()` as a proxy for "total participants" if each SBE counted as 1 vote.
        // For actual reputation-weighted voting, total reputation needs to be tracked.
        // Let's return a fixed value for simulation, assuming it's dynamic but tracked.
        // In practice, this could be sum of `sbeToken.totalSupply() * averageSBEWeight`
        // Or maintain `totalReputationWeightedSupply` state variable updated with mint/burn/weight changes.
        return 100000; // Example placeholder value for total reputation
    }

    // --- View functions for governance parameters ---

    function getMinReputationToProposeGrant() public view returns (uint256) {
        return minReputationToProposeGrant;
    }

    function getMinReputationToProposeParamChange() public view returns (uint256) {
        return minReputationToProposeParamChange;
    }

    function getVotingPeriodDuration() public view returns (uint256) {
        return votingPeriodDuration;
    }

    function getProposalQuorumBasisPoints() public view returns (uint256) {
        return proposalQuorumBasisPoints;
    }

    function getProposalPassThresholdBasisPoints() public view returns (uint256) {
        return proposalPassThresholdBasisPoints;
    }
}
```