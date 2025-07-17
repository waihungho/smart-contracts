Here's a Solidity smart contract system, named "AetherForge," designed to explore advanced concepts like dynamic Soul-Bound Tokens (SBTs), adaptive bonding curves influenced by reputation, and gamified on-chain governance with AI oracle integration. It avoids direct duplication of existing large open-source projects by combining these elements in a novel way.

---

# AetherForge Protocol: A Decentralized Evolution Engine

## Outline

This protocol consists of three inter-connected smart contracts:

1.  **`AetherForgeCore.sol`**: The central hub for user interactions, managing Aether-Essence NFTs (AENs), and orchestrating the gamified governance/challenge system.
2.  **`AetherEssenceNFT.sol`**: An ERC721-compliant contract for "Aether-Essence" NFTs (AENs). These are Soul-Bound Tokens (SBTs), meaning they are non-transferable, and possess dynamic attributes influenced by on-chain activity and external oracle data.
3.  **`AEONToken.sol`**: An ERC20 token serving as the utility and governance token for the AetherForge ecosystem. It implements an adaptive bonding curve for its price discovery, which can be influenced by the overall network's reputation.

## Function Summary (22 Functions)

### A. AetherForgeCore Functions (System & AEN Interaction)

1.  **`constructor(address _aeonToken, address _aenNFT)`**: Initializes the core protocol, linking it to the AEON Token and Aether-Essence NFT contracts. Sets up initial roles for system management.
2.  **`mintAetherEssence()`**: Allows a user to mint their first and only Soul-Bound Aether-Essence NFT (AEN). This is a one-time operation per address.
3.  **`selectAffinityPath(uint256 _affinityId)`**: Enables an AEN holder to select a specific "Affinity Path" (e.g., Builder, Governor, Explorer) for their AEN, specializing its role and potential benefits within the ecosystem.
4.  **`updateAENReputation(uint256 _tokenId, uint256 _newReputationScore)`**: Callable only by a designated `AI_ORACLE_ROLE` address, this function updates an AEN's `reputationScore` based on external AI-driven analysis. This score dynamically influences AEN attributes and AEON tokenomics.
5.  **`evolveAENRarity()`**: Allows an AEN holder to spend accumulated `essencePoints` to upgrade their AEN's visual rarity tier, unlocking new potential features or enhanced governance weight.
6.  **`getAENAttributes(uint256 _tokenId)` (view)**: Retrieves all current dynamic attributes (essence points, reputation, rarity, affinity) of a specified AEN.
7.  **`getAENByOwner(address _owner)` (view)**: Returns the `tokenId` of the AEN owned by a given address.
8.  **`getAffinityPathDetails(uint256 _affinityId)` (view)**: Provides details about a specific predefined affinity path, including its name and description.

### B. AEONToken Functions (Token & Adaptive Bonding Curve)

9.  **`buyAEON(uint256 _ethAmount)` (payable)**: Allows users to purchase AEON tokens from the protocol's bonding curve using ETH. The price is dynamically calculated.
10. **`sellAEON(uint256 _aeonAmount)`**: Allows users to sell AEON tokens back to the protocol's bonding curve for ETH. The amount of ETH received is dynamically calculated.
11. **`getAEONPrice()` (view)**: Calculates and returns the current price of 1 AEON in terms of ETH, based on the adaptive bonding curve, AEON supply, and the protocol's average reputation score.
12. **`updateBondingCurveParameters(uint256 _supplyFactor, uint256 _reputationFactor)`**: Callable by a designated `AI_ORACLE_ROLE` or governance, this function adjusts the key parameters (`priceSlopeSupplyFactor`, `priceSlopeReputationFactor`) that influence the AEON bonding curve's slope, adapting it to network conditions.
13. **`distributeAEONRewards(uint256 _tokenId, uint256 _amount)`**: Internal/restricted function, callable by the `AetherForgeCore` contract, used to distribute AEON tokens to specific AEN holders as rewards (e.g., for challenge completion).

### C. Gamified Governance & Challenges Functions

14. **`proposeChallenge(string calldata _title, string calldata _description, uint256 _rewardPoolAEON, uint256 _minReputation)`**: Allows AEN holders (meeting a minimum reputation threshold) to propose new on-chain challenges for the community to vote on and participate in.
15. **`voteOnChallengeProposal(uint256 _challengeId, bool _support)`**: AEN holders vote on proposed challenges. Their voting power is dynamically weighted by their AEN's `essencePoints`, `reputationScore`, and `rarityTier`.
16. **`executeChallenge(uint256 _challengeId)`**: Callable by a designated `CHALLENGE_VERIFIER_ROLE` after a challenge proposal has successfully passed voting. This transitions the challenge to an "Active" state.
17. **`submitChallengeCompletion(uint256 _challengeId, address[] calldata _participants)`**: Callable by the `CHALLENGE_VERIFIER_ROLE` once an active challenge has been completed, triggering the distribution of `essencePoints` and `AEON` rewards to the specified participants.
18. **`claimChallengeEssencePoints(uint256 _challengeId)`**: Allows verified participants of a completed challenge to claim their accrued `essencePoints` into their AEN.
19. **`getChallengeStatus(uint256 _challengeId)` (view)**: Returns the current status (Proposed, Active, Completed, Failed) and details of a specific challenge.
20. **`delegateVotingPower(address _delegatee)`**: Allows an AEN holder to delegate their AEN's calculated voting power to another address.
21. **`revokeVotingDelegation()`**: Revokes an existing voting delegation, returning voting power back to the delegator's AEN.
22. **`calculateTotalVotingPower(address _voter)` (view)**: Calculates and returns the total weighted voting power for a given address, considering their AEN attributes and any delegated power.

---

## Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- AetherEssenceNFT.sol ---
// ERC721-compliant (but Soul-Bound) contract for Aether-Essence NFTs (AENs)
contract AetherEssenceNFT is ERC721, AccessControl {
    using SafeMath for uint256;

    // Roles for managing NFT attributes and system access
    bytes32 public constant CORE_PROTOCOL_ROLE = keccak256("CORE_PROTOCOL_ROLE");

    // AEN Dynamic Attributes Structure
    struct AENAttributes {
        uint256 essencePoints;      // Accumulate through challenges, participation
        uint256 reputationScore;    // Influenced by AI Oracle (0-1000)
        uint256 rarityTier;         // 0 (Common) to N (Legendary), upgradeable
        uint256 affinityPathId;     // 0 (None), 1 (Builder), 2 (Governor), 3 (Explorer)
    }

    // Mappings for AEN data
    mapping(uint256 => AENAttributes) public aenData;           // tokenId => attributes
    mapping(address => uint256) public ownerToTokenId;          // owner address => tokenId (for SBT enforcement)
    mapping(address => bool) public hasMintedAEN;               // Tracks if an address has minted an AEN

    // Events
    event AENMinted(address indexed owner, uint224 tokenId);
    event AENAttributesUpdated(uint256 indexed tokenId, uint256 essencePoints, uint256 reputationScore, uint256 rarityTier, uint256 affinityPathId);
    event AffinityPathSelected(uint256 indexed tokenId, uint256 indexed pathId);

    constructor() ERC721("AetherEssence", "AEN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // --- Internal/Restricted NFT Minting & Management ---

    function _mintAEN(address to) internal returns (uint256) {
        require(!hasMintedAEN[to], "AEN: Address already has an AEN");

        uint256 tokenId = _nextTokenId();
        _safeMint(to, tokenId);
        
        aenData[tokenId] = AENAttributes({
            essencePoints: 0,
            reputationScore: 100, // Starting reputation
            rarityTier: 0,
            affinityPathId: 0
        });
        ownerToTokenId[to] = tokenId;
        hasMintedAEN[to] = true;

        emit AENMinted(to, tokenId);
        return tokenId;
    }

    // Only the CORE_PROTOCOL_ROLE can update AEN attributes
    function _updateAENAttributes(uint256 tokenId, uint256 newEssencePoints, uint256 newReputation, uint256 newRarity, uint256 newAffinity) internal {
        require(ownerOf(tokenId) != address(0), "AEN: Invalid token ID"); // Ensure token exists

        AENAttributes storage attributes = aenData[tokenId];
        attributes.essencePoints = newEssencePoints;
        attributes.reputationScore = newReputation;
        attributes.rarityTier = newRarity;
        attributes.affinityPathId = newAffinity;

        emit AENAttributesUpdated(tokenId, newEssencePoints, newReputation, newRarity, newAffinity);
    }

    // Only the CORE_PROTOCOL_ROLE can update specific AEN attributes
    function _updateAENEssencePoints(uint256 tokenId, uint256 pointsToAdd) internal {
        require(ownerOf(tokenId) != address(0), "AEN: Invalid token ID");
        AENAttributes storage attributes = aenData[tokenId];
        attributes.essencePoints = attributes.essencePoints.add(pointsToAdd);
        emit AENAttributesUpdated(tokenId, attributes.essencePoints, attributes.reputationScore, attributes.rarityTier, attributes.affinityPathId);
    }

    function _setAENReputation(uint256 tokenId, uint256 newReputation) internal {
        require(ownerOf(tokenId) != address(0), "AEN: Invalid token ID");
        require(newReputation <= 1000, "AEN: Reputation score out of bounds (0-1000)"); // Max reputation
        AENAttributes storage attributes = aenData[tokenId];
        attributes.reputationScore = newReputation;
        emit AENAttributesUpdated(tokenId, attributes.essencePoints, attributes.reputationScore, attributes.rarityTier, attributes.affinityPathId);
    }

    function _setAENRarity(uint256 tokenId, uint256 newRarity) internal {
        require(ownerOf(tokenId) != address(0), "AEN: Invalid token ID");
        AENAttributes storage attributes = aenData[tokenId];
        attributes.rarityTier = newRarity;
        emit AENAttributesUpdated(tokenId, attributes.essencePoints, attributes.reputationScore, attributes.rarityTier, attributes.affinityPathId);
    }

    function _setAENAffinity(uint256 tokenId, uint256 newAffinity) internal {
        require(ownerOf(tokenId) != address(0), "AEN: Invalid token ID");
        AENAttributes storage attributes = aenData[tokenId];
        require(attributes.affinityPathId == 0, "AEN: Affinity path already set");
        require(newAffinity > 0 && newAffinity <= 3, "AEN: Invalid affinity path ID"); // 1,2,3 for Builder, Governor, Explorer
        attributes.affinityPathId = newAffinity;
        emit AffinityPathSelected(tokenId, newAffinity);
        emit AENAttributesUpdated(tokenId, attributes.essencePoints, attributes.reputationScore, attributes.rarityTier, attributes.affinityPathId);
    }

    // --- Soul-Bound Token (SBT) Enforcement ---
    // Override transfer functions to prevent transfers
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AEN: Aether-Essence NFTs are soul-bound and non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AEN: Aether-Essence NFTs are soul-bound and non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert("AEN: Aether-Essence NFTs are soul-bound and non-transferable.");
    }

    // Disable burning as well, if desired for true soul-binding.
    // Uncomment if burning should also be prevented.
    // function _burn(uint256 tokenId) internal override {
    //     revert("AEN: Aether-Essence NFTs cannot be burned.");
    // }

    // Private counter for token IDs
    uint256 private _tokenIds;
    function _nextTokenId() private returns (uint256) {
        _tokenIds++;
        return _tokenIds;
    }
}

// --- AEONToken.sol ---
// ERC20 token with an adaptive bonding curve
contract AEONToken is ERC20, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant CORE_PROTOCOL_ROLE = keccak256("CORE_PROTOCOL_ROLE");
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");

    uint256 public ethReserve; // ETH held by the contract for bonding curve
    uint256 public totalAEONSupplyBonded; // AEON minted/burned through the curve

    // Adaptive Bonding Curve Parameters
    // Price = (BASE_AEON_PRICE + (totalAEONSupplyBonded / 1e18 * priceSlopeSupplyFactor / 1e6) - (avgReputation / 1e18 * priceSlopeReputationFactor / 1e6)) / 1e18
    uint256 public constant BASE_AEON_PRICE = 100000000000000; // 0.0001 ETH (1e14 wei) - Base price in wei
    uint256 public priceSlopeSupplyFactor;    // Multiplier for supply impact on price (e.g., 1e6 -> 1)
    uint256 public priceSlopeReputationFactor; // Multiplier for reputation impact on price (e.g., 1e6 -> 1)
    uint256 public avgNetworkReputation;       // Overall network average reputation (0-1000)

    // Events
    event AEONBought(address indexed buyer, uint256 ethAmount, uint256 aeonAmount, uint256 currentPrice);
    event AEONSold(address indexed seller, uint256 aeonAmount, uint256 ethAmount, uint256 currentPrice);
    event BondingCurveParametersUpdated(uint256 supplyFactor, uint256 reputationFactor);
    event AverageNetworkReputationUpdated(uint256 newAvgReputation);

    constructor() ERC20("AEON", "AEON") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Initial parameters for the bonding curve (adjust as needed)
        priceSlopeSupplyFactor = 500000; // 0.5 (scaled by 1e6)
        priceSlopeReputationFactor = 200000; // 0.2 (scaled by 1e6)
        avgNetworkReputation = 100; // Initial average reputation
    }

    // C.2. Buy AEON: Users buy AEON from the bonding curve using ETH
    function buyAEON(uint256 _ethAmount) public payable nonReentrant returns (uint256) {
        require(msg.value == _ethAmount && _ethAmount > 0, "AEON: Invalid ETH amount provided.");

        uint256 currentPricePerAEON = getAEONPrice(); // Price in wei per AEON
        require(currentPricePerAEON > 0, "AEON: Current AEON price is zero or negative.");

        // Calculate amount of AEON to mint based on current price
        uint256 aeonToMint = _ethAmount.mul(1e18).div(currentPricePerAEON); // AEON is 18 decimals

        require(aeonToMint > 0, "AEON: Not enough ETH to buy any AEON.");

        _mint(msg.sender, aeonToMint);
        ethReserve = ethReserve.add(_ethAmount);
        totalAEONSupplyBonded = totalAEONSupplyBonded.add(aeonToMint);

        emit AEONBought(msg.sender, _ethAmount, aeonToMint, currentPricePerAEON);
        return aeonToMint;
    }

    // C.3. Sell AEON: Users sell AEON back to the bonding curve for ETH
    function sellAEON(uint256 _aeonAmount) public nonReentrant returns (uint256) {
        require(_aeonAmount > 0, "AEON: Amount must be greater than zero.");
        require(balanceOf(msg.sender) >= _aeonAmount, "AEON: Insufficient AEON balance.");

        uint256 currentPricePerAEON = getAEONPrice(); // Price in wei per AEON
        uint256 ethToReturn = _aeonAmount.mul(currentPricePerAEON).div(1e18); // ETH to return (wei)

        require(ethReserve >= ethToReturn, "AEON: Not enough ETH reserve for sale.");

        _burn(msg.sender, _aeonAmount);
        ethReserve = ethReserve.sub(ethToReturn);
        totalAEONSupplyBonded = totalAEONSupplyBonded.sub(_aeonAmount);
        
        payable(msg.sender).transfer(ethToReturn);

        emit AEONSold(msg.sender, _aeonAmount, ethToReturn, currentPricePerAEON);
        return ethToReturn;
    }

    // C.4. Get AEON Price: Calculates current price of 1 AEON in ETH (wei)
    function getAEONPrice() public view returns (uint256) {
        uint256 supplyTerm = totalAEONSupplyBonded.div(1e18).mul(priceSlopeSupplyFactor).div(1e6); // Scale AEON supply and factor
        uint256 reputationTerm = avgNetworkReputation.mul(priceSlopeReputationFactor).div(1e6); // Scale reputation and factor

        // Simplified linear adaptive price model
        // Price = (BASE_AEON_PRICE + (supply increase drives price up) - (reputation increase drives price down, making it more accessible))
        uint256 calculatedPrice = BASE_AEON_PRICE.add(supplyTerm);
        if (calculatedPrice > reputationTerm) { // Ensure price doesn't go negative or too low
            calculatedPrice = calculatedPrice.sub(reputationTerm);
        } else {
            calculatedPrice = BASE_AEON_PRICE.div(10); // Minimum price floor
        }

        // Add a floor price to prevent crash
        if (calculatedPrice < BASE_AEON_PRICE.div(5)) { // e.g., 20% of base price
            calculatedPrice = BASE_AEON_PRICE.div(5);
        }

        return calculatedPrice; // Price in wei per AEON (18 decimals implied for AEON)
    }

    // C.5. Update Bonding Curve Parameters: Callable by AI_ORACLE_ROLE or governance
    function updateBondingCurveParameters(uint256 _supplyFactor, uint256 _reputationFactor) public onlyRole(AI_ORACLE_ROLE) {
        require(_supplyFactor > 0 && _reputationFactor > 0, "AEON: Factors must be positive.");
        priceSlopeSupplyFactor = _supplyFactor;
        priceSlopeReputationFactor = _reputationFactor;
        emit BondingCurveParametersUpdated(_supplyFactor, _reputationFactor);
    }

    // Update the average network reputation score (influences bonding curve)
    function updateAverageNetworkReputation(uint256 _newAvgReputation) public onlyRole(AI_ORACLE_ROLE) {
        require(_newAvgReputation <= 1000, "AEON: Average reputation score out of bounds (0-1000)");
        avgNetworkReputation = _newAvgReputation;
        emit AverageNetworkReputationUpdated(_newAvgReputation);
    }

    // C.6. Distribute AEON Rewards: Called by AetherForgeCore to reward participants
    function distributeAEONRewards(address _to, uint256 _amount) public onlyRole(CORE_PROTOCOL_ROLE) {
        _mint(_to, _amount);
    }

    // Allow ETH to be received for bonding curve
    receive() external payable {
        // ETH received should primarily be through buyAEON
        // But this is here to catch any direct sends if needed.
    }
}


// --- AetherForgeCore.sol ---
// Central hub for AENs, Gamified Governance, and Protocol Logic
contract AetherForgeCore is AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // Roles
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");
    bytes32 public constant CHALLENGE_VERIFIER_ROLE = keccak256("CHALLENGE_VERIFIER_ROLE");

    // Linked Contracts
    AEONToken public aeonToken;
    AetherEssenceNFT public aenNFT;

    // Affinity Paths (Enum-like mapping for clarity)
    mapping(uint256 => string) public affinityPathNames;
    mapping(uint256 => string) public affinityPathDescriptions;

    // Challenge System
    enum ChallengeStatus { Proposed, Active, Completed, Failed }

    struct Challenge {
        string title;
        string description;
        uint256 rewardPoolAEON;         // AEON set aside for rewards
        uint256 minReputationRequired;  // Min AEN reputation to propose
        uint256 proposalTimestamp;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        address proposer;
        ChallengeStatus status;
        mapping(address => bool) hasVoted; // Tracks if an address (or its delegate) has voted
        mapping(address => bool) hasClaimedEssencePoints; // Tracks if a participant has claimed points
    }

    mapping(uint256 => Challenge) public challenges;
    uint256 public nextChallengeId;
    uint256 public constant CHALLENGE_VOTE_PERIOD = 3 days; // Example: 3 days for voting

    // Voting Delegation
    mapping(address => address) public votingDelegations; // delegator => delegatee

    // Events
    event AENMinted(address indexed owner, uint256 tokenId);
    event AffinityPathSelected(uint256 indexed tokenId, uint256 indexed pathId);
    event AENReputationUpdated(uint256 indexed tokenId, uint256 newReputation);
    event AENRarityEvolved(uint256 indexed tokenId, uint256 newRarityTier);
    event ChallengeProposed(uint256 indexed challengeId, address indexed proposer, string title);
    event ChallengeVote(uint256 indexed challengeId, address indexed voter, bool support, uint256 votingPower);
    event ChallengeStatusChanged(uint256 indexed challengeId, ChallengeStatus newStatus);
    event ChallengeCompleted(uint256 indexed challengeId, address[] participants, uint256 aeonDistributed);
    event EssencePointsClaimed(uint256 indexed challengeId, uint256 indexed tokenId, uint256 points);
    event VotingDelegated(address indexed delegator, address indexed delegatee);
    event VotingDelegationRevoked(address indexed delegator);

    // D.1. Constructor: Initialize protocol with token/NFT addresses
    constructor(address _aeonToken, address _aenNFT) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AI_ORACLE_ROLE, msg.sender); // Admin can be initial AI oracle
        _grantRole(CHALLENGE_VERIFIER_ROLE, msg.sender); // Admin can be initial verifier

        aeonToken = AEONToken(_aeonToken);
        aenNFT = AetherEssenceNFT(_aenNFT);

        // Grant CORE_PROTOCOL_ROLE to this contract on AEON and AEN contracts
        AetherEssenceNFT(_aenNFT).grantRole(AetherEssenceNFT.CORE_PROTOCOL_ROLE, address(this));
        AEONToken(_aeonToken).grantRole(AEONToken.CORE_PROTOCOL_ROLE, address(this));

        // Define Affinity Paths
        affinityPathNames[1] = "Builder"; affinityPathDescriptions[1] = "Focuses on creating and contributing to protocol infrastructure.";
        affinityPathNames[2] = "Governor"; affinityPathDescriptions[2] = "Specializes in decentralized governance and decision-making.";
        affinityPathNames[3] = "Explorer"; affinityPathDescriptions[3] = "Aims to discover new opportunities and expand the ecosystem.";
    }

    // D.2. Mint Aether-Essence NFT (AEN)
    function mintAetherEssence() public whenNotPaused nonReentrant {
        require(!aenNFT.hasMintedAEN(msg.sender), "AetherForge: You already own an AEN.");
        aenNFT._mintAEN(msg.sender);
        emit AENMinted(msg.sender, aenNFT.ownerToTokenId(msg.sender));
    }

    // D.3. Select Affinity Path for AEN
    function selectAffinityPath(uint256 _affinityId) public whenNotPaused {
        uint256 tokenId = aenNFT.ownerToTokenId(msg.sender);
        require(tokenId != 0, "AetherForge: You must own an AEN to select an affinity path.");
        require(aenNFT.aenData(tokenId).affinityPathId == 0, "AetherForge: Affinity path already selected for your AEN.");
        require(affinityPathNames[_affinityId] != "", "AetherForge: Invalid affinity path ID.");

        aenNFT._setAENAffinity(tokenId, _affinityId);
        emit AffinityPathSelected(tokenId, _affinityId);
    }

    // D.4. Update AEN Reputation (AI Oracle Only)
    function updateAENReputation(uint256 _tokenId, uint256 _newReputationScore) public onlyRole(AI_ORACLE_ROLE) whenNotPaused {
        require(aenNFT.ownerOf(_tokenId) != address(0), "AetherForge: Token ID does not exist.");
        aenNFT._setAENReputation(_tokenId, _newReputationScore);
        emit AENReputationUpdated(_tokenId, _newReputationScore);
    }

    // D.5. Evolve AEN Rarity
    function evolveAENRarity() public whenNotPaused {
        uint256 tokenId = aenNFT.ownerToTokenId(msg.sender);
        require(tokenId != 0, "AetherForge: You must own an AEN to evolve its rarity.");

        AetherEssenceNFT.AENAttributes memory currentAttributes = aenNFT.aenData(tokenId);
        uint256 currentRarity = currentAttributes.rarityTier;
        uint256 requiredEssencePoints;

        // Define rarity tiers and required points
        if (currentRarity == 0) { // Common to Uncommon
            requiredEssencePoints = 100;
        } else if (currentRarity == 1) { // Uncommon to Rare
            requiredEssencePoints = 300;
        } else if (currentRarity == 2) { // Rare to Epic
            requiredEssencePoints = 800;
        } else if (currentRarity == 3) { // Epic to Legendary
            requiredEssencePoints = 2000;
        } else {
            revert("AetherForge: AEN is already at maximum rarity or invalid tier.");
        }

        require(currentAttributes.essencePoints >= requiredEssencePoints, "AetherForge: Insufficient Essence Points for rarity evolution.");

        aenNFT._updateAENAttributes(
            tokenId,
            currentAttributes.essencePoints.sub(requiredEssencePoints),
            currentAttributes.reputationScore,
            currentRarity.add(1),
            currentAttributes.affinityPathId
        );
        emit AENRarityEvolved(tokenId, currentRarity.add(1));
    }

    // D.6. Get AEN Attributes (View Function)
    function getAENAttributes(uint256 _tokenId) public view returns (uint256 essencePoints, uint256 reputationScore, uint256 rarityTier, uint256 affinityPathId) {
        AetherEssenceNFT.AENAttributes memory attributes = aenNFT.aenData(_tokenId);
        return (attributes.essencePoints, attributes.reputationScore, attributes.rarityTier, attributes.affinityPathId);
    }

    // D.7. Get AEN By Owner (View Function)
    function getAENByOwner(address _owner) public view returns (uint256) {
        return aenNFT.ownerToTokenId(_owner);
    }

    // D.8. Get Affinity Path Details (View Function)
    function getAffinityPathDetails(uint256 _affinityId) public view returns (string memory name, string memory description) {
        return (affinityPathNames[_affinityId], affinityPathDescriptions[_affinityId]);
    }

    // --- Gamified Governance & Challenges ---

    // D.14. Propose Challenge
    function proposeChallenge(string calldata _title, string calldata _description, uint256 _rewardPoolAEON, uint256 _minReputation) public whenNotPaused nonReentrant {
        uint256 proposerAENId = aenNFT.ownerToTokenId(msg.sender);
        require(proposerAENId != 0, "AetherForge: You must own an AEN to propose a challenge.");
        require(aenNFT.aenData(proposerAENId).reputationScore >= _minReputation, "AetherForge: Insufficient reputation to propose this challenge.");
        require(_rewardPoolAEON > 0, "AetherForge: Challenge must have an AEON reward pool.");
        
        // Transfer AEON rewards from proposer to contract for escrow
        require(aeonToken.transferFrom(msg.sender, address(this), _rewardPoolAEON), "AetherForge: Failed to transfer AEON for reward pool.");

        uint256 id = nextChallengeId++;
        challenges[id] = Challenge({
            title: _title,
            description: _description,
            rewardPoolAEON: _rewardPoolAEON,
            minReputationRequired: _minReputation,
            proposalTimestamp: block.timestamp,
            voteEndTime: block.timestamp.add(CHALLENGE_VOTE_PERIOD),
            yesVotes: 0,
            noVotes: 0,
            proposer: msg.sender,
            status: ChallengeStatus.Proposed,
            hasVoted: new mapping(address => bool)(), // Initialize mapping
            hasClaimedEssencePoints: new mapping(address => bool)()
        });
        emit ChallengeProposed(id, msg.sender, _title);
    }

    // D.15. Vote On Challenge Proposal
    function voteOnChallengeProposal(uint256 _challengeId, bool _support) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Proposed, "AetherForge: Challenge is not in proposed state.");
        require(block.timestamp <= challenge.voteEndTime, "AetherForge: Voting period has ended.");

        address voterAddress = msg.sender;
        if (votingDelegations[msg.sender] != address(0)) {
            voterAddress = votingDelegations[msg.sender]; // Use delegate's vote if delegated
        }

        require(!challenge.hasVoted[voterAddress], "AetherForge: You or your delegate have already voted on this challenge.");

        uint256 voterAENId = aenNFT.ownerToTokenId(voterAddress);
        require(voterAENId != 0, "AetherForge: Only AEN holders can vote.");

        uint256 votingPower = calculateTotalVotingPower(voterAddress);
        require(votingPower > 0, "AetherForge: You have no voting power.");

        if (_support) {
            challenge.yesVotes = challenge.yesVotes.add(votingPower);
        } else {
            challenge.noVotes = challenge.noVotes.add(votingPower);
        }
        challenge.hasVoted[voterAddress] = true; // Mark the actual voter (or delegate) as having voted

        emit ChallengeVote(_challengeId, msg.sender, _support, votingPower);
    }

    // D.16. Execute Challenge (If Passed Voting)
    function executeChallenge(uint256 _challengeId) public onlyRole(CHALLENGE_VERIFIER_ROLE) whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Proposed, "AetherForge: Challenge is not in proposed state.");
        require(block.timestamp > challenge.voteEndTime, "AetherForge: Voting period is still active.");

        if (challenge.yesVotes > challenge.noVotes) {
            challenge.status = ChallengeStatus.Active;
            emit ChallengeStatusChanged(_challengeId, ChallengeStatus.Active);
        } else {
            challenge.status = ChallengeStatus.Failed;
            // Optionally refund AEON to proposer if failed or distribute to governance treasury
            aeonToken.transfer(challenge.proposer, challenge.rewardPoolAEON);
            emit ChallengeStatusChanged(_challengeId, ChallengeStatus.Failed);
        }
    }

    // D.17. Submit Challenge Completion (by Verifier)
    function submitChallengeCompletion(uint256 _challengeId, address[] calldata _participants) public onlyRole(CHALLENGE_VERIFIER_ROLE) whenNotPaused nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Active, "AetherForge: Challenge is not active.");
        require(_participants.length > 0, "AetherForge: No participants provided for completion.");

        challenge.status = ChallengeStatus.Completed;

        // Distribute AEON rewards
        uint256 aeonPerParticipant = challenge.rewardPoolAEON.div(_participants.length);
        for (uint256 i = 0; i < _participants.length; i++) {
            require(aenNFT.ownerToTokenId(_participants[i]) != 0, "AetherForge: Participant must own an AEN.");
            aeonToken.distributeAEONRewards(_participants[i], aeonPerParticipant);
        }
        
        emit ChallengeCompleted(_challengeId, _participants, challenge.rewardPoolAEON);
        emit ChallengeStatusChanged(_challengeId, ChallengeStatus.Completed);
    }

    // D.18. Claim Challenge Essence Points
    function claimChallengeEssencePoints(uint256 _challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Completed, "AetherForge: Challenge not completed yet.");
        
        uint256 tokenId = aenNFT.ownerToTokenId(msg.sender);
        require(tokenId != 0, "AetherForge: You must own an AEN to claim points.");
        
        // This simple check assumes _participants array from submitChallengeCompletion is available or re-verified.
        // For a more robust system, participants would need to register for the challenge or be provably part of it.
        // For this example, we'll assume any AEN owner can claim if the challenge is completed.
        // In a real dApp, a proof might be submitted here.
        require(!challenge.hasClaimedEssencePoints[msg.sender], "AetherForge: You have already claimed essence points for this challenge.");

        // Example: Essence points awarded based on challenge complexity/impact
        uint256 pointsToAward = 50; // Arbitrary, could be dynamic per challenge type

        aenNFT._updateAENEssencePoints(tokenId, pointsToAward);
        challenge.hasClaimedEssencePoints[msg.sender] = true;
        
        emit EssencePointsClaimed(_challengeId, tokenId, pointsToAward);
    }


    // D.19. Get Challenge Status (View Function)
    function getChallengeStatus(uint256 _challengeId) public view returns (string memory title, ChallengeStatus status, uint256 yesVotes, uint256 noVotes, uint256 voteEndTime) {
        Challenge memory challenge = challenges[_challengeId];
        return (challenge.title, challenge.status, challenge.yesVotes, challenge.noVotes, challenge.voteEndTime);
    }

    // D.20. Delegate Voting Power
    function delegateVotingPower(address _delegatee) public whenNotPaused {
        require(aenNFT.ownerToTokenId(msg.sender) != 0, "AetherForge: You must own an AEN to delegate voting power.");
        require(_delegatee != address(0), "AetherForge: Cannot delegate to zero address.");
        require(_delegatee != msg.sender, "AetherForge: Cannot delegate to yourself.");
        votingDelegations[msg.sender] = _delegatee;
        emit VotingDelegated(msg.sender, _delegatee);
    }

    // D.21. Revoke Voting Delegation
    function revokeVotingDelegation() public whenNotPaused {
        require(votingDelegations[msg.sender] != address(0), "AetherForge: No active delegation to revoke.");
        delete votingDelegations[msg.sender];
        emit VotingDelegationRevoked(msg.sender);
    }

    // D.22. Calculate Total Voting Power (View Function)
    function calculateTotalVotingPower(address _voter) public view returns (uint256) {
        uint256 tokenId = aenNFT.ownerToTokenId(_voter);
        if (tokenId == 0) {
            return 0; // No AEN, no voting power
        }

        AetherEssenceNFT.AENAttributes memory attributes = aenNFT.aenData(tokenId);
        
        // Simple weighted sum:
        // Base points + (Reputation score / 100) + (Rarity tier * 10)
        // Adjust weights as needed for desired influence
        uint256 basePower = attributes.essencePoints;
        uint256 reputationBonus = attributes.reputationScore.div(10); // Max 100 bonus for 1000 rep
        uint256 rarityBonus = attributes.rarityTier.mul(50); // Each tier adds 50 points

        return basePower.add(reputationBonus).add(rarityBonus);
    }

    // --- Admin & Pause Functions ---
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setAIOracleAddress(address _newOracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newOracle != address(0), "AetherForge: Invalid address");
        // Revoke old role if exists and grant new
        _revokeRole(AI_ORACLE_ROLE, getRoleMember(AI_ORACLE_ROLE, 0)); // Simple for single oracle
        _grantRole(AI_ORACLE_ROLE, _newOracle);
    }

    function setChallengeVerifierAddress(address _newVerifier) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newVerifier != address(0), "AetherForge: Invalid address");
        // Revoke old role if exists and grant new
        _revokeRole(CHALLENGE_VERIFIER_ROLE, getRoleMember(CHALLENGE_VERIFIER_ROLE, 0)); // Simple for single verifier
        _grantRole(CHALLENGE_VERIFIER_ROLE, _newVerifier);
    }

    // Fallback function to prevent accidental ETH sends
    fallback() external payable {
        revert("AetherForge: ETH not accepted directly. Use buyAEON or specific functions.");
    }
}
```