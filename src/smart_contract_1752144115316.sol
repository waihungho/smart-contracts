Okay, here is a Solidity smart contract implementing a concept called "Chronicle Shards". This contract combines elements of dynamic NFTs, on-chain achievement tracking, and a decentralized attestation/challenge system. It avoids basic ERC-20/ERC-721 templates and common DeFi/DAO patterns, aiming for a unique interaction model.

It focuses on:
1.  **Dynamic NFTs (Chronicle Shards):** ERC-721 tokens representing a user's on-chain journey.
2.  **On-Chain Achievements:** Defining specific milestones or actions users can "unlock".
3.  **Attestation System:** Users can claim (attest) they've achieved something, backed by a deposit.
4.  **Challenge System:** Others can challenge attestations, also with a deposit.
5.  **Owner/Admin Resolution:** The contract owner (or designated admins) resolves challenges and approves/rejects attestations, distributing challenge/attestation deposits based on outcomes.
6.  **Dynamic Metadata:** The NFT's metadata (tier, unlocked achievements) changes based on the approved achievements.
7.  **Tier System:** Shards advance through tiers based on the number of approved achievements.

---

**Outline and Function Summary**

**Contract Name:** `ChronicleShards`

**Core Concept:** A system for issuing dynamic, achievement-tracking NFTs (Chronicle Shards) on the blockchain, managed via a semi-decentralized attestation and challenge mechanism.

**Inherits:**
*   `ERC721`: Standard NFT functionality.
*   `Ownable`: Basic ownership and administrative control.

**State Variables:**
*   NFT details (`name`, `symbol`).
*   Token counter (`_nextTokenId`).
*   Base URI for metadata (`_baseURI`).
*   Minter addresses (`minters`).
*   Achievement Type definitions (`AchievementType`, `_achievementTypes`, `_nextAchievementTypeId`).
*   Unlocked achievements per token (`_unlockedAchievements`).
*   Chronicle Tier per token (`_chronicleTiers`).
*   Attestation details (`Attestation`, `_attestations`, `_nextAttestationId`).
*   Challenge details (`Challenge`, `_challenges`, `_nextChallengeId`).
*   Attestation/Challenge parameters (`_challengePeriod`, `_challengeDeposit`, `_attestationsPaused`).
*   Mapping of Attestation ID to associated Challenge IDs (`_attestationChallenges`).

**Events:**
*   `AchievementTypeDefined`: New achievement type created.
*   `ChronicleShardMinted`: A new NFT is minted.
*   `AchievementAttested`: User submits an achievement claim.
*   `AttestationResolved`: Attestation is approved or rejected.
*   `ChallengeInitiated`: An attestation is challenged.
*   `ChallengeResolved`: A challenge dispute is resolved.
*   `ChronicleTierUpdated`: A shard's tier changes.
*   `MinterAdded`, `MinterRemoved`: Minter role changes.
*   `ChallengePeriodSet`, `ChallengeDepositSet`: Parameters updated.
*   `AttestationsPaused`: Attestation system paused/unpaused.

**Structs:**
*   `AchievementType`: Defines an achievement (ID, name, description, a simple criteria flag for now).
*   `Attestation`: Represents a user's claim (claimer, token ID, achievement ID, state, submission time).
*   `Challenge`: Represents a challenge against an attestation (challenger, attestation ID, state, deposit amount).

**Enums:**
*   `AttestationState`: `Pending`, `Approved`, `Rejected`, `Challenged`.
*   `ChallengeState`: `Open`, `ChallengerWins`, `AttesterWins`, `Draw` (Draw not used in this logic, but good practice).

**Functions (Total: 27 custom functions + standard ERC721/Ownable):**

1.  `constructor(string memory name_, string memory symbol_)`: Initializes ERC721 and Ownable.
2.  `addMinter(address minter)`: Owner adds an address capable of minting shards.
3.  `removeMinter(address minter)`: Owner removes a minter address.
4.  `isMinter(address account) view`: Checks if an address is a minter.
5.  `defineAchievementType(string memory name, string memory description, bool requiresManualReview)`: Owner defines a new achievement type.
6.  `getAchievementTypeDetails(uint256 achievementTypeId) view`: Retrieves details of an achievement type.
7.  `mintChronicleShard(address user)`: Minter creates a new Chronicle Shard NFT for a user.
8.  `attestAchievement(uint256 tokenId, uint256 achievementTypeId) payable`: User claims they unlocked an achievement for their shard. Requires deposit.
9.  `getAttestationDetails(uint256 attestationId) view`: Retrieves details of an attestation.
10. `challengeAttestation(uint256 attestationId) payable`: Any address can challenge a pending attestation. Requires deposit.
11. `getChallengesForAttestation(uint256 attestationId) view`: Lists challenge IDs for a specific attestation.
12. `resolveAttestation(uint256 attestationId, bool approved)`: Owner resolves a *pending* attestation. Approves it, unlocks achievement, updates tier, returns deposit. Rejects it, keeps deposit.
13. `resolveChallenge(uint256 challengeId, bool challengerWins)`: Owner resolves a *challenged* attestation's associated challenge. Distributes deposits based on outcome.
14. `getUnlockedAchievements(uint256 tokenId) view`: Gets the list of achievement IDs approved for a shard.
15. `getChronicleTier(uint256 tokenId) view`: Calculates and returns the current tier of a shard based on achievement count.
16. `_updateChronicleTier(uint256 tokenId)`: Internal function to calculate and update the stored tier, emitted via event.
17. `tokenURI(uint256 tokenId) view override`: Generates dynamic metadata URI based on the shard's state (achievements, tier).
18. `setChallengePeriod(uint256 duration)`: Owner sets the duration an attestation is open for challenge.
19. `getChallengePeriod() view`: Gets the current challenge period.
20. `setChallengeDeposit(uint256 amount)`: Owner sets the required deposit for attestations and challenges.
21. `getChallengeDeposit() view`: Gets the current challenge deposit amount.
22. `withdraw()`: Owner can withdraw accumulated Ether from failed attestations/challenges.
23. `getPendingAttestations() view`: Lists attestation IDs currently in the `Pending` state.
24. `getChallengedAttestations() view`: Lists attestation IDs currently in the `Challenged` state.
25. `burnChronicleShard(uint256 tokenId)`: Allows the token owner to burn their shard.
26. `pauseAttestations(bool paused)`: Owner can pause new attestation submissions.
27. `isAttestationsPaused() view`: Checks if attestations are paused.
28. `setBaseURI(string memory baseURI)`: Owner sets the base URI for `tokenURI`.

*(Plus standard ERC721 functions like `balanceOf`, `ownerOf`, `transferFrom`, `approve`, etc., provided by the inherited contract - these are >7 functions)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title ChronicleShards
/// @dev A dynamic NFT system tracking on-chain achievements via attestation and challenge.
/// Users mint "Chronicle Shards" (ERC721) which serve as unique identifiers.
/// Users can attest to having completed specific, predefined "Achievements".
/// These attestations require a deposit and are subject to a challenge period.
/// Anyone can challenge an attestation, also requiring a deposit.
/// The contract owner resolves challenges/attestations, distributing deposits based on the outcome.
/// Approved achievements are recorded on the NFT, and the NFT's tier is dynamically updated.
/// The NFT's metadata reflects its current state (unlocked achievements, tier).
contract ChronicleShards is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token Counter
    Counters.Counter private _nextTokenId;

    // Base URI for metadata
    string private _baseURI;

    // Addresses authorized to mint new shards
    mapping(address => bool) public minters;

    // Achievement Definitions
    struct AchievementType {
        uint256 id;
        string name;
        string description;
        bool requiresManualReview; // True if attestation isn't automatically approved after challenge period
    }
    mapping(uint256 => AchievementType) private _achievementTypes;
    Counters.Counter private _nextAchievementTypeId;

    // Unlocked Achievements per Token
    // tokenId => list of approved achievement type IDs
    mapping(uint256 => uint256[]) private _unlockedAchievements;

    // Chronicle Tier per Token (derived from achievement count)
    mapping(uint256 => uint256) private _chronicleTiers;

    // Attestation System
    enum AttestationState { Pending, Approved, Rejected, Challenged }
    struct Attestation {
        uint256 id;
        address claimer; // Address who attested
        uint256 tokenId;
        uint256 achievementTypeId;
        AttestationState state;
        uint64 submissionTime;
    }
    mapping(uint256 => Attestation) private _attestations;
    Counters.Counter private _nextAttestationId;
    uint256[] private _pendingAttestations; // Array to track pending attestation IDs (for view functions)
    mapping(uint256 => bool) private _isPendingAttestation; // Helper for array management
    uint256[] private _challengedAttestations; // Array to track challenged attestation IDs
     mapping(uint256 => bool) private _isChallengedAttestation; // Helper for array management

    // Challenge System
    enum ChallengeState { Open, ChallengerWins, AttesterWins, Draw }
    struct Challenge {
        uint256 id;
        address challenger;
        uint256 attestationId;
        ChallengeState state;
        uint256 depositAmount; // Amount locked by challenger
    }
    mapping(uint256 => Challenge) private _challenges;
    Counters.Counter private _nextChallengeId;
    mapping(uint256 => uint256[]) private _attestationChallenges; // attestationId => list of challengeIds

    // Attestation & Challenge Parameters
    uint256 public _challengePeriod = 3 days; // Duration attestations are open for challenge
    uint256 public _challengeDeposit = 0.01 ether; // Required ETH deposit for attesting/challenging
    bool public _attestationsPaused = false; // Global pause for new attestations


    // --- Errors ---
    error NotMinter();
    error AchievementTypeNotFound(uint256 achievementTypeId);
    error AttestationsPaused();
    error InvalidTokenId(uint256 tokenId);
    error NotTokenOwnerOrApproved(uint256 tokenId);
    error AttestationNotFound(uint256 attestationId);
    error AttestationNotPending(uint256 attestationId);
    error AttestationNotChallenged(uint256 attestationId);
    error AttestationAlreadyResolved(uint256 attestationId);
    error ChallengeNotFound(uint256 challengeId);
    error ChallengeNotOpen(uint256 challengeId);
    error IncorrectChallengeDeposit(uint256 requiredAmount);
    error NotEnoughChallenges(uint256 attestationId);
    error AttestationAlreadyApproved(uint256 attestationId);
    error TokenHasAchievement(uint256 tokenId, uint256 achievementTypeId);


    // --- Events ---
    event AchievementTypeDefined(uint256 indexed achievementTypeId, string name, string description, bool requiresManualReview);
    event ChronicleShardMinted(uint256 indexed tokenId, address indexed owner);
    event AchievementAttested(uint256 indexed attestationId, address indexed claimer, uint256 indexed tokenId, uint256 achievementTypeId);
    event AttestationResolved(uint256 indexed attestationId, AttestationState indexed newState, uint256 indexed tokenId, uint256 achievementTypeId);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed attestationId, address indexed challenger, uint256 deposit);
    event ChallengeResolved(uint256 indexed challengeId, ChallengeState indexed state, uint256 indexed attestationId);
    event ChronicleTierUpdated(uint256 indexed tokenId, uint256 newTier);
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event ChallengePeriodSet(uint256 duration);
    event ChallengeDepositSet(uint256 amount);
    event AttestationsPaused(bool paused);


    // --- Modifiers ---
    modifier onlyMinter() {
        if (!minters[msg.sender]) revert NotMinter();
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable(msg.sender) {
        // Initial owner is also the first minter
        minters[msg.sender] = true;
        emit MinterAdded(msg.sender);
    }

    // --- Admin/Minter Functions ---

    /// @dev Adds an address to the list of authorized minters.
    /// @param minter The address to add as a minter.
    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
        emit MinterAdded(minter);
    }

    /// @dev Removes an address from the list of authorized minters.
    /// @param minter The address to remove as a minter.
    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
        emit MinterRemoved(minter);
    }

    /// @dev Checks if an address is authorized to mint.
    /// @param account The address to check.
    /// @return True if the address is a minter, false otherwise.
    function isMinter(address account) public view returns (bool) {
        return minters[account];
    }

    /// @dev Defines a new achievement type that users can attest to.
    /// Only callable by the owner.
    /// @param name The name of the achievement.
    /// @param description A brief description.
    /// @param requiresManualReview If true, owner must explicitly call resolveAttestation after challenge period expires or challenge is resolved. If false, attestation is automatically approved after challenge period if no challenges occur (this auto-approval is *not* implemented here for simplicity, owner resolution is always required).
    /// @return The ID of the newly defined achievement type.
    function defineAchievementType(string memory name, string memory description, bool requiresManualReview) external onlyOwner returns (uint256) {
        _nextAchievementTypeId.increment();
        uint256 newId = _nextAchievementTypeId.current();
        _achievementTypes[newId] = AchievementType(newId, name, description, requiresManualReview);
        emit AchievementTypeDefined(newId, name, description, requiresManualReview);
        return newId;
    }

    /// @dev Gets the details of a specific achievement type.
    /// @param achievementTypeId The ID of the achievement type.
    /// @return The AchievementType struct details.
    function getAchievementTypeDetails(uint256 achievementTypeId) external view returns (AchievementType memory) {
        if (_achievementTypes[achievementTypeId].id == 0 && achievementTypeId != 0) revert AchievementTypeNotFound(achievementTypeId);
        return _achievementTypes[achievementTypeId];
    }

    // --- NFT Minting ---

    /// @dev Mints a new Chronicle Shard NFT for a specified user.
    /// Only callable by authorized minters.
    /// @param user The address to mint the token for.
    /// @return The ID of the newly minted token.
    function mintChronicleShard(address user) external onlyMinter returns (uint256) {
        _nextTokenId.increment();
        uint256 newTokenId = _nextTokenId.current();
        _safeMint(user, newTokenId);
        // Initialize token specific data
        _unlockedAchievements[newTokenId] = new uint256[](0);
        _chronicleTiers[newTokenId] = 0; // Start at tier 0

        emit ChronicleShardMinted(newTokenId, user);
        return newTokenId;
    }

    // --- Achievement & Tier Tracking (Internal) ---

    /// @dev Adds an approved achievement to a token's record.
    /// @param tokenId The ID of the shard.
    /// @param achievementTypeId The ID of the achievement type to add.
    function _addUnlockedAchievement(uint256 tokenId, uint256 achievementTypeId) internal {
        // Check if achievement is already unlocked (optional, but good practice)
        for(uint i=0; i < _unlockedAchievements[tokenId].length; i++) {
            if (_unlockedAchievements[tokenId][i] == achievementTypeId) {
                revert TokenHasAchievement(tokenId, achievementTypeId);
            }
        }
        _unlockedAchievements[tokenId].push(achievementTypeId);
        _updateChronicleTier(tokenId); // Recalculate tier
    }

    /// @dev Calculates and updates the tier of a Chronicle Shard based on its approved achievements.
    /// This is a simple example: tier is based on achievement count. Can be made more complex.
    /// @param tokenId The ID of the shard.
    function _updateChronicleTier(uint256 tokenId) internal {
        uint256 achievementCount = _unlockedAchievements[tokenId].length;
        uint256 currentTier = _chronicleTiers[tokenId];
        uint256 newTier;

        // Simple tier logic:
        if (achievementCount < 5) {
            newTier = 0;
        } else if (achievementCount < 10) {
            newTier = 1;
        } else if (achievementCount < 20) {
            newTier = 2;
        } else {
            newTier = 3; // Example: Master Tier
        }

        if (newTier != currentTier) {
            _chronicleTiers[tokenId] = newTier;
            emit ChronicleTierUpdated(tokenId, newTier);
        }
    }

    // --- Attestation System ---

    /// @dev Allows the token owner (or approved) to attest to completing an achievement for their shard.
    /// Requires a deposit. Starts the attestation in 'Pending' state.
    /// @param tokenId The ID of the shard.
    /// @param achievementTypeId The ID of the achievement type being attested to.
    function attestAchievement(uint256 tokenId, uint256 achievementTypeId) external payable {
        if (_attestationsPaused) revert AttestationsPaused();
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) revert NotTokenOwnerOrApproved(tokenId);
        if (_achievementTypes[achievementTypeId].id == 0 && achievementTypeId != 0) revert AchievementTypeNotFound(achievementTypeId);
        if (msg.value < _challengeDeposit) revert IncorrectChallengeDeposit(_challengeDeposit);

        // Optional: Check if achievement is already unlocked
         for(uint i=0; i < _unlockedAchievements[tokenId].length; i++) {
            if (_unlockedAchievements[tokenId][i] == achievementTypeId) {
                revert TokenHasAchievement(tokenId, achievementTypeId);
            }
        }

        _nextAttestationId.increment();
        uint256 attestationId = _nextAttestationId.current();

        _attestations[attestationId] = Attestation({
            id: attestationId,
            claimer: msg.sender,
            tokenId: tokenId,
            achievementTypeId: achievementTypeId,
            state: AttestationState.Pending,
            submissionTime: uint64(block.timestamp)
        });

        // Add to pending list
        _pendingAttestations.push(attestationId);
        _isPendingAttestation[attestationId] = true;

        emit AchievementAttested(attestationId, msg.sender, tokenId, achievementTypeId);
    }

    /// @dev Gets the details of a specific attestation.
    /// @param attestationId The ID of the attestation.
    /// @return The Attestation struct details.
    function getAttestationDetails(uint256 attestationId) external view returns (Attestation memory) {
        if (_attestations[attestationId].id == 0 && attestationId != 0) revert AttestationNotFound(attestationId);
        return _attestations[attestationId];
    }

     /// @dev Gets a list of attestation IDs that are currently in the `Pending` state.
    /// @return An array of pending attestation IDs.
    function getPendingAttestations() external view returns (uint256[] memory) {
        uint256[] memory pending;
        uint256 count = 0;
        // Iterate and copy valid pending IDs
        for (uint i = 0; i < _pendingAttestations.length; i++) {
             uint256 attId = _pendingAttestations[i];
             if (_isPendingAttestation[attId] && _attestations[attId].state == AttestationState.Pending) {
                 count++;
             }
        }
        pending = new uint256[](count);
        uint256 current = 0;
         for (uint i = 0; i < _pendingAttestations.length; i++) {
             uint256 attId = _pendingAttestations[i];
             if (_isPendingAttestation[attId] && _attestations[attId].state == AttestationState.Pending) {
                 pending[current] = attId;
                 current++;
             }
        }

        return pending;
    }

    /// @dev Gets a list of attestation IDs that are currently in the `Challenged` state.
    /// @return An array of challenged attestation IDs.
    function getChallengedAttestations() external view returns (uint256[] memory) {
        uint256[] memory challenged;
        uint256 count = 0;
        // Iterate and copy valid challenged IDs
        for (uint i = 0; i < _challengedAttestations.length; i++) {
             uint256 attId = _challengedAttestations[i];
             if (_isChallengedAttestation[attId] && _attestations[attId].state == AttestationState.Challenged) {
                 count++;
             }
        }
        challenged = new uint256[](count);
        uint256 current = 0;
         for (uint i = 0; i < _challengedAttestations.length; i++) {
             uint256 attId = _challengedAttestations[i];
             if (_isChallengedAttestation[attId] && _attestations[attId].state == AttestationState.Challenged) {
                 challenged[current] = attId;
                 current++;
             }
        }

        return challenged;
    }


    /// @dev Resolves a pending attestation. Only callable by the owner.
    /// If approved, adds achievement, updates tier, returns claimer's deposit.
    /// If rejected, keeps claimer's deposit.
    /// @param attestationId The ID of the attestation to resolve.
    /// @param approved Whether to approve or reject the attestation.
    function resolveAttestation(uint256 attestationId, bool approved) external onlyOwner {
        Attestation storage att = _attestations[attestationId];
        if (att.id == 0 && attestationId != 0) revert AttestationNotFound(attestationId);
        if (att.state != AttestationState.Pending) revert AttestationNotPending(attestationId);
        if (block.timestamp < att.submissionTime + _challengePeriod) {
             // Cannot resolve pending attestation before challenge period ends UNLESS it requires manual review immediately
            if(!_achievementTypes[att.achievementTypeId].requiresManualReview) {
                 revert("Attestation challenge period not over");
            }
        }

        // Mark as not pending anymore (before state change)
        _isPendingAttestation[attestationId] = false;

        if (approved) {
            att.state = AttestationState.Approved;
            // Add achievement to token's record
            _addUnlockedAchievement(att.tokenId, att.achievementTypeId);
            // Return deposit to claimer
            (bool success, ) = payable(att.claimer).call{value: _challengeDeposit}("");
            require(success, "Deposit transfer failed");
        } else {
            att.state = AttestationState.Rejected;
            // Keep deposit (it stays in the contract, owner can withdraw later)
        }

        emit AttestationResolved(attestationId, att.state, att.tokenId, att.achievementTypeId);
    }


    // --- Challenge System ---

    /// @dev Allows anyone to challenge a pending attestation. Requires a deposit.
    /// Moves the attestation to 'Challenged' state.
    /// @param attestationId The ID of the attestation to challenge.
    function challengeAttestation(uint256 attestationId) external payable {
        Attestation storage att = _attestations[attestationId];
        if (att.id == 0 && attestationId != 0) revert AttestationNotFound(attestationId);
        if (att.state != AttestationState.Pending) revert AttestationNotPending(attestationId);
        if (block.timestamp >= att.submissionTime + _challengePeriod) revert("Challenge period is over");
        if (msg.value < _challengeDeposit) revert IncorrectChallengeDeposit(_challengeDeposit);

        // Mark as not pending and move to challenged list
        _isPendingAttestation[attestationId] = false;
        _challengedAttestations.push(attestationId);
        _isChallengedAttestation[attestationId] = true;


        att.state = AttestationState.Challenged;

        _nextChallengeId.increment();
        uint256 challengeId = _nextChallengeId.current();

        _challenges[challengeId] = Challenge({
            id: challengeId,
            challenger: msg.sender,
            attestationId: attestationId,
            state: ChallengeState.Open,
            depositAmount: msg.value // Record the actual deposit amount
        });

        _attestationChallenges[attestationId].push(challengeId);

        emit ChallengeInitiated(challengeId, attestationId, msg.sender, msg.value);
    }

    /// @dev Gets the list of challenge IDs associated with a specific attestation.
    /// @param attestationId The ID of the attestation.
    /// @return An array of challenge IDs.
    function getChallengesForAttestation(uint256 attestationId) external view returns (uint256[] memory) {
         if (_attestations[attestationId].id == 0 && attestationId != 0) revert AttestationNotFound(attestationId);
         return _attestationChallenges[attestationId];
    }


    /// @dev Resolves an open challenge for a challenged attestation. Only callable by the owner.
    /// Distributes deposits based on whether the challenger wins or loses.
    /// If challenger wins, attestation is rejected, challenger gets both deposits.
    /// If challenger loses, attestation is approved, attester gets both deposits.
    /// @param challengeId The ID of the challenge to resolve.
    /// @param challengerWins Whether the challenger is deemed to have won the dispute.
    function resolveChallenge(uint256 challengeId, bool challengerWins) external onlyOwner {
        Challenge storage challenge = _challenges[challengeId];
        if (challenge.id == 0 && challengeId != 0) revert ChallengeNotFound(challengeId);
        if (challenge.state != ChallengeState.Open) revert ChallengeNotOpen(challengeId);

        Attestation storage att = _attestations[challenge.attestationId];
        if (att.id == 0 && challenge.attestationId != 0) revert AttestationNotFound(challenge.attestationId); // Should not happen if challenge exists
        if (att.state != AttestationState.Challenged) revert AttestationNotChallenged(challenge.attestationId);
        // Note: There might be multiple challenges for one attestation. This function resolves *one* challenge.
        // The owner decides the fate of the *attestation* via resolveAttestation, potentially after reviewing challenges.
        // A simpler model: resolving *any* challenge triggers resolution of the *attestation*. Let's simplify to that.
        // Resolving a challenge dictates the fate of the attestation.

        // Mark as not challenged anymore (before state change)
         _isChallengedAttestation[challenge.attestationId] = false;


        if (challengerWins) {
            challenge.state = ChallengeState.ChallengerWins;
            att.state = AttestationState.Rejected;

            // Challenger gets their deposit + Attester's deposit
            (bool success, ) = payable(challenge.challenger).call{value: challenge.depositAmount + _challengeDeposit}("");
            require(success, "Challenger payout failed");

        } else { // Attester Wins (Challenger Loses)
            challenge.state = ChallengeState.AttesterWins;
            att.state = AttestationState.Approved;

            // Attester gets their deposit + Challenger's deposit
            (bool success, ) = payable(att.claimer).call{value: _challengeDeposit + challenge.depositAmount}("");
            require(success, "Attester payout failed");

            // Add achievement to token's record only if Attester wins
             _addUnlockedAchievement(att.tokenId, att.achievementTypeId);
        }

        emit ChallengeResolved(challengeId, challenge.state, challenge.attestationId);
        emit AttestationResolved(att.id, att.state, att.tokenId, att.achievementTypeId);

        // Clean up: If this was the last open challenge for this attestation,
        // maybe remove from the _challengedAttestations array (complex to do efficiently).
        // Let's rely on the state check in getChallengedAttestations().
    }

    // --- Token Information ---

    /// @dev Gets the list of achievement type IDs that have been approved for a specific shard.
    /// @param tokenId The ID of the shard.
    /// @return An array of achievement type IDs.
    function getUnlockedAchievements(uint256 tokenId) external view returns (uint256[] memory) {
         if (ownerOf(tokenId) == address(0) && tokenId != 0) revert InvalidTokenId(tokenId); // Check if token exists
        return _unlockedAchievements[tokenId];
    }

    /// @dev Gets the current tier of a Chronicle Shard.
    /// Tier is calculated based on the number of unlocked achievements.
    /// @param tokenId The ID of the shard.
    /// @return The current tier number.
    function getChronicleTier(uint256 tokenId) external view returns (uint256) {
        if (ownerOf(tokenId) == address(0) && tokenId != 0) revert InvalidTokenId(tokenId); // Check if token exists
        // Tier is updated internally via _updateChronicleTier, just return the stored value
        return _chronicleTiers[tokenId];
    }

    /// @dev See {ERC721-tokenURI}.
    /// Generates dynamic metadata based on token state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721Metadata.URIQueryForNonexistentToken();

        uint256 currentTier = _chronicleTiers[tokenId];
        uint256[] memory achievements = _unlockedAchievements[tokenId];
        address tokenOwner = ownerOf(tokenId);

        // Build achievement list string for JSON
        string memory achievementsString = "[";
        for (uint i = 0; i < achievements.length; i++) {
            achievementsString = string(abi.encodePacked(achievementsString, uint256(achievements[i]).toString()));
            if (i < achievements.length - 1) {
                achievementsString = string(abi.encodePacked(achievementsString, ","));
            }
        }
        achievementsString = string(abi.encodePacked(achievementsString, "]"));

        // Basic JSON structure (can be expanded)
        string memory json = string(abi.encodePacked(
            '{"name": "Chronicle Shard #', uint256(tokenId).toString(),
            '", "description": "A unique Chronicle Shard representing on-chain achievements.",',
            '"attributes": [',
                '{"trait_type": "Tier", "value": ', uint256(currentTier).toString(), '},',
                '{"trait_type": "Achievements Unlocked Count", "value": ', uint256(achievements.length).toString(), '},',
                 '{"trait_type": "Owner Address", "value": "', tokenOwner.toString(), '"}',
            '],',
             '"unlocked_achievement_ids": ', achievementsString,
             // Potentially add image based on tier
            // '"image": "', _baseURI, uint256(currentTier).toString(), '.png"',
            '}'
        ));

        string memory base = _baseURI;
         if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, Base64.encode(bytes(json))));
        } else {
             // If no base URI, return data URI directly
            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        }
    }

     /// @dev Sets the base URI for token metadata.
    /// This base URI is prepended to the data URI generated in `tokenURI`.
    /// @param baseURI The new base URI.
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURI = baseURI;
    }


    // --- Parameter Management ---

    /// @dev Sets the duration for which attestations are open for challenge.
    /// @param duration The new challenge period in seconds.
    function setChallengePeriod(uint256 duration) external onlyOwner {
        _challengePeriod = duration;
        emit ChallengePeriodSet(duration);
    }

    /// @dev Gets the current challenge period duration.
    /// @return The challenge period duration in seconds.
    function getChallengePeriod() external view returns (uint256) {
        return _challengePeriod;
    }

    /// @dev Sets the required Ether deposit for submitting attestations and challenges.
    /// @param amount The new required deposit amount in Wei.
    function setChallengeDeposit(uint256 amount) external onlyOwner {
        _challengeDeposit = amount;
        emit ChallengeDepositSet(amount);
    }

    /// @dev Gets the current challenge deposit amount.
    /// @return The challenge deposit amount in Wei.
    function getChallengeDeposit() external view returns (uint256) {
        return _challengeDeposit;
    }

    /// @dev Allows the owner to pause/unpause new attestation submissions.
    /// @param paused True to pause, false to unpause.
    function pauseAttestations(bool paused) external onlyOwner {
        _attestationsPaused = paused;
        emit AttestationsPaused(paused);
    }

     /// @dev Checks if new attestations are currently paused.
    /// @return True if paused, false otherwise.
    function isAttestationsPaused() external view returns (bool) {
        return _attestationsPaused;
    }


    // --- Contract Balance & Withdrawal ---

    /// @dev Allows the owner to withdraw any accumulated Ether from the contract.
    /// This Ether comes from deposits that were not returned (e.g., rejected attestations, failed challenges).
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // --- Utility ---

    /// @dev Allows the token owner to burn their Chronicle Shard.
    /// Note: Burning removes the token, but the achievement history for the *address* isn't tracked here,
    /// only the history associated with the specific token ID.
    /// @param tokenId The ID of the shard to burn.
    function burnChronicleShard(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved(tokenId);
        _burn(tokenId);
        // Note: Achievement data for this token ID is still stored but orphaned.
        // Could optionally clear storage, but it's gas-intensive.
    }

    // --- Internal ERC721 Overrides (Optional, but good practice for clarity/hooks) ---
    // You might add _beforeTokenTransfer or _afterTokenTransfer hooks here
    // if token transfer should affect achievement tracking, but in this model
    // achievements are tied to the tokenId itself, so they transfer with the token.
}
```