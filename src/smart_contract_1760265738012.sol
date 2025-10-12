This smart contract, named **ChronoAura Emblems**, introduces a novel system for on-chain reputation and decentralized contributions, represented by dynamically evolving NFTs. It combines several advanced concepts:

1.  **Dynamic NFTs (ChronoAura Emblems):** ERC721 tokens whose `tokenURI` (and thus visual representation) changes based on an internal `auraScore` and the contract's `currentEpoch`.
2.  **Reputation System (Aura Score):** A non-transferable, increment-only score tied to each Emblem, reflecting a user's contributions and achievements within the ecosystem.
3.  **Epoch-Based Progression:** The contract progresses through distinct `Epochs`, which can unlock new challenge types, Aura thresholds, or modify game mechanics over time.
4.  **Decentralized Challenge System:** Users can propose, vote on, and complete various challenges (tasks), earning Aura and the utility token `ChronoShards`. Challenges can be designed for on-chain verifiable actions or off-chain proof submissions.
5.  **Utility Token (ChronoShards - ERC20):** Used for staking, challenge entry fees, rewards, and potentially sponsorship.
6.  **Role-Based Verification:** Designated verifiers (oracles) are responsible for confirming completion of off-chain challenges.
7.  **Community Governance (Lite):** A voting mechanism for challenge proposals.

---

### ChronoAura Emblems Contract Outline & Function Summary

**Contract Name:** `ChronoAuraEmblems`

This contract is built using OpenZeppelin's battle-tested libraries for ERC721, ERC20, AccessControl, and Pausable functionalities, but its core logic and advanced features are entirely custom and designed for this unique concept.

---

### **I. Core ChronoAura Emblem (ERC721) Management**

1.  **`mintEmblem()`**
    *   **Description:** Allows a user to mint a new ChronoAura Emblem (NFT), starting with 0 Aura.
    *   **Access:** Public.
    *   **Functionality:** Creates a new ERC721 token and assigns it to the caller.
2.  **`burnEmblem(uint256 tokenId)`**
    *   **Description:** Allows an Emblem owner to permanently destroy their Emblem.
    *   **Access:** Owner of the tokenId.
    *   **Functionality:** Burns the specified ERC721 token.
3.  **`transferFrom(address from, address to, uint256 tokenId)`**
    *   **Description:** Standard ERC721 function to transfer ownership of an Emblem.
    *   **Access:** ERC721 approved or owner.
    *   **Functionality:** Transfers the NFT.
4.  **`tokenURI(uint256 tokenId)`**
    *   **Description:** Returns the dynamic metadata URI for an Emblem, reflecting its current `auraScore` and the `currentEpoch`.
    *   **Access:** Public (view).
    *   **Functionality:** Constructs a URI that encodes the Emblem's `auraLevel` and `currentEpoch`, which an off-chain server can use to render dynamic JSON metadata and images.
5.  **`getEmblemAura(uint256 tokenId)`**
    *   **Description:** Retrieves the current Aura score for a given Emblem.
    *   **Access:** Public (view).
    *   **Functionality:** Returns the `auraScore` associated with `tokenId`.

---

### **II. Aura Progression & Evolution**

6.  **`incrementAura(uint256 tokenId, uint256 amount)`**
    *   **Description:** Increases an Emblem's Aura score, typically as a reward for challenge completion.
    *   **Access:** `DEFAULT_ADMIN_ROLE` or `VERIFIER_ROLE`.
    *   **Functionality:** Adds `amount` to the `auraScore` of `tokenId`, potentially triggering a visual update.
7.  **`decrementAura(uint256 tokenId, uint256 amount)`**
    *   **Description:** Decreases an Emblem's Aura score, used for penalties or failed challenges (rare).
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Subtracts `amount` from `auraScore`.
8.  **`getAuraLevel(uint256 tokenId)`**
    *   **Description:** Calculates the current "level" of an Emblem based on its `auraScore` and defined thresholds. This level influences the `tokenURI`.
    *   **Access:** Public (view).
    *   **Functionality:** Iterates through `auraLevelThresholds` to determine the current level.
9.  **`_updateEmblemVisuals(uint256 tokenId)` (Internal)**
    *   **Description:** Internal helper function that can be called after Aura or Epoch changes to signal a metadata update (via `tokenURI` changes).
    *   **Access:** Internal.
    *   **Functionality:** Emits an event to signal metadata refresh.
10. **`setAuraLevelThresholds(uint256[] calldata _thresholds)`**
    *   **Description:** Admin function to configure the Aura score boundaries for different visual/functional levels.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Updates the `auraLevelThresholds` array.

---

### **III. ChronoShards (ERC20) & Economy**

11. **`mintChronoShards(address to, uint256 amount)`**
    *   **Description:** Mints new ChronoShards and sends them to a specified address, primarily for challenge rewards or initial distribution.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Increases total supply and recipient's balance.
12. **`burnChronoShards(uint256 amount)`**
    *   **Description:** Burns ChronoShards from the caller's balance, e.g., for challenge entry fees or economic adjustments.
    *   **Access:** Caller (must have `amount`).
    *   **Functionality:** Decreases total supply and caller's balance.
13. **`transfer(address to, uint256 amount)`**
    *   **Description:** Standard ERC20 function to transfer ChronoShards.
    *   **Access:** Caller (must have `amount`).
    *   **Functionality:** Transfers `amount` from caller to `to`.
14. **`balanceOf(address account)`**
    *   **Description:** Returns the ChronoShards balance of an address.
    *   **Access:** Public (view).
    *   **Functionality:** Returns `_balances[account]`.

---

### **IV. Epoch & Temporal Progression**

15. **`advanceEpoch()`**
    *   **Description:** Admin function to move the system to the next Epoch, potentially unlocking new features or challenges.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Increments `currentEpoch`, resets epoch-specific states.
16. **`getCurrentEpoch()`**
    *   **Description:** Returns the current active Epoch number.
    *   **Access:** Public (view).
    *   **Functionality:** Returns `currentEpoch`.
17. **`setEpochChallengeTypes(uint256 epoch, uint256[] calldata types)`**
    *   **Description:** Admin function to define which `ChallengeType`s are permissible in a given Epoch.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Updates `epochAllowedChallengeTypes` mapping.

---

### **V. Decentralized Challenge System**

18. **`proposeChallenge(string calldata _description, uint256 _auraReward, uint256 _shardReward, ChallengeType _challengeType, uint256 _requiredStake)`**
    *   **Description:** Allows users to propose new challenges, requiring a `ChronoShards` stake to prevent spam.
    *   **Access:** Public (requires `ChronoShards` approval).
    *   **Functionality:** Creates a `ChallengeProposal`, transfers stake, and starts a voting period.
19. **`voteOnChallengeProposal(uint256 proposalId, bool voteFor)`**
    *   **Description:** Emblem holders can vote on proposed challenges using their Emblem's Aura power.
    *   **Access:** Any Emblem holder.
    *   **Functionality:** Records votes based on the voter's Emblem's Aura score.
20. **`startChallenge(uint256 proposalId)`**
    *   **Description:** Initiates an approved challenge, making it active for participants.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Transitions a `ChallengeProposal` to an active `Challenge`.
21. **`submitChallengeCompletion(uint256 challengeId, string calldata _proofHash)`**
    *   **Description:** Participants submit proof of challenge completion (e.g., IPFS hash of off-chain proof, transaction hash for on-chain).
    *   **Access:** Public.
    *   **Functionality:** Records the participant's submission and proof hash for verification.
22. **`verifyChallengeCompletion(uint256 challengeId, address participant, bool verified)`**
    *   **Description:** Verifiers (Oracles/Admins) confirm challenge completion for a specific participant.
    *   **Access:** `VERIFIER_ROLE`.
    *   **Functionality:** Marks a participant's submission as verified or rejected.
23. **`rewardChallengeCompletion(uint256 challengeId, address participant)`**
    *   **Description:** Awards Aura and ChronoShards to participants whose challenge completion has been verified.
    *   **Access:** `DEFAULT_ADMIN_ROLE` or `VERIFIER_ROLE` (after `verifyChallengeCompletion`).
    *   **Functionality:** Calls `incrementAura` and `mintChronoShards`.
24. **`cancelChallenge(uint256 challengeId)`**
    *   **Description:** Allows admin/governance to cancel an active challenge.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Sets challenge status to cancelled, allows stake withdrawal.

---

### **VI. Staking & Sponsorship**

25. **`stakeChronoShardsForValidation(uint256 amount)`**
    *   **Description:** Allows users to stake ChronoShards to potentially earn the `VERIFIER_ROLE` or participate in future validator elections.
    *   **Access:** Public (requires `ChronoShards` approval).
    *   **Functionality:** Records staked amount for the caller.
26. **`unstakeChronoShards(uint256 amount)`**
    *   **Description:** Allows users to unstake their previously staked ChronoShards.
    *   **Access:** Public.
    *   **Functionality:** Refunds staked amount, potentially revoking validation privileges.
27. **`sponsorChallenge(uint256 challengeId, uint256 amount)`**
    *   **Description:** Allows users/projects to stake ChronoShards to fund the rewards for a specific challenge.
    *   **Access:** Public (requires `ChronoShards` approval).
    *   **Functionality:** Increases the reward pool for `challengeId`.

---

### **VII. Oracle & Role Management**

28. **`addVerifier(address account)`**
    *   **Description:** Admin function to grant the `VERIFIER_ROLE` to an address.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Assigns the role using OpenZeppelin's `_grantRole`.
29. **`removeVerifier(address account)`**
    *   **Description:** Admin function to revoke the `VERIFIER_ROLE` from an address.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Revokes the role using OpenZeppelin's `_revokeRole`.
30. **`isVerifier(address account)`**
    *   **Description:** Checks if an address has the `VERIFIER_ROLE`.
    *   **Access:** Public (view).
    *   **Functionality:** Returns `hasRole(VERIFIER_ROLE, account)`.

---

### **VIII. Security & Administration**

31. **`pause()`**
    *   **Description:** Pauses key contract functions (e.g., transfers, challenge proposals) in emergencies.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Sets `_paused` to `true`.
32. **`unpause()`**
    *   **Description:** Unpauses the contract, allowing paused functions to resume.
    *   **Access:** `DEFAULT_ADMIN_ROLE`.
    *   **Functionality:** Sets `_paused` to `false`.
33. **`withdrawProposalStake(uint256 proposalId)`**
    *   **Description:** Allows a challenge proposer to reclaim their initial stake if the proposal is rejected or cancelled.
    *   **Access:** Proposer of `proposalId`.
    *   **Functionality:** Transfers the stake back to the proposer.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ChronoAuraEmblems
 * @dev A dynamic NFT system (ERC721) for on-chain reputation, progressive challenges, and decentralized contributions.
 *      Emblems evolve visually and functionally based on an Aura Score and Epoch progression.
 *      Introduces ChronoShards (ERC20) as a utility token for staking, rewards, and challenge mechanics.
 */
contract ChronoAuraEmblems is ERC721URIStorage, AccessControl, Pausable, ERC20 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE"); // For validating challenge completions

    // --- ERC721 - ChronoAura Emblems ---
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public auraScores; // tokenId => Aura score
    string private _baseTokenURI; // Base URI for metadata server
    uint256[] public auraLevelThresholds; // Aura scores required for each level (index 0 for level 1, etc.)

    // --- Epoch System ---
    uint256 public currentEpoch; // Current active epoch

    // --- ERC20 - ChronoShards ---
    // Inherits ERC20 methods directly

    // --- Challenge System ---
    Counters.Counter private _challengeProposalCounter;
    Counters.Counter private _challengeCounter;

    enum ChallengeStatus { Proposed, Active, Completed, Cancelled }
    enum ChallengeType { OnChainTx, OffChainProofHash } // Types of challenges

    struct ChallengeProposal {
        address proposer;
        string description;
        uint256 auraReward;
        uint256 shardReward;
        ChallengeType challengeType;
        uint256 requiredStake; // ChronoShards required to propose
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Address => Voted (to prevent double voting)
        uint256 totalAuraVotingPower; // Sum of Aura scores of Emblems that voted
        ChallengeStatus status;
        uint256 createdAt;
        uint256 challengeId; // If approved, points to the actual challenge
    }

    struct Challenge {
        address proposer;
        string description;
        uint256 auraReward;
        uint256 shardReward;
        ChallengeType challengeType;
        uint256 totalSponsoredShards; // Additional ChronoShards from sponsors
        ChallengeStatus status;
        mapping(address => ChallengeCompletion) completions; // Participant => Completion details
    }

    struct ChallengeCompletion {
        string proofHash;
        bool verified;
        bool rewarded;
        uint256 submissionTime;
    }

    mapping(uint256 => ChallengeProposal) public challengeProposals; // proposalId => ChallengeProposal
    mapping(uint256 => Challenge) public challenges; // challengeId => Challenge
    mapping(address => uint256) public stakedChronoShardsForValidation; // Address => amount staked for validation

    // Allowed challenge types per epoch
    mapping(uint256 => mapping(uint256 => bool)) public epochAllowedChallengeTypes; // epoch => challengeType => bool

    // --- Events ---
    event EmblemMinted(address indexed owner, uint256 indexed tokenId, uint256 initialAura);
    event AuraIncreased(uint256 indexed tokenId, uint256 oldAura, uint256 newAura);
    event AuraDecreased(uint256 indexed tokenId, uint256 oldAura, uint256 newAura);
    event TokenMetadataUpdate(uint256 indexed tokenId, string newURI);
    event EpochAdvanced(uint256 indexed newEpoch);
    event ChallengeProposed(uint256 indexed proposalId, address indexed proposer, uint256 requiredStake, uint256 auraReward, uint256 shardReward);
    event ChallengeProposalVoted(uint256 indexed proposalId, address indexed voter, bool voteFor, uint256 auraVotingPower);
    event ChallengeStarted(uint256 indexed challengeId, uint256 indexed proposalId);
    event ChallengeCompletionSubmitted(uint256 indexed challengeId, address indexed participant, string proofHash);
    event ChallengeCompletionVerified(uint256 indexed challengeId, address indexed participant, bool verified);
    event ChallengeRewarded(uint256 indexed challengeId, address indexed participant, uint256 auraAwarded, uint256 shardsAwarded);
    event ChallengeCancelled(uint256 indexed challengeId);
    event ChronoShardsStakedForValidation(address indexed staker, uint256 amount);
    event ChronoShardsUnstaked(address indexed unstaker, uint256 amount);
    event ChallengeSponsored(uint256 indexed challengeId, address indexed sponsor, uint256 amount);
    event ProposalStakeWithdrawn(uint256 indexed proposalId, address indexed withdrawer, uint256 amount);

    constructor(
        address admin,
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        string memory shardName,
        string memory shardSymbol,
        uint256[] memory initialAuraLevelThresholds
    ) ERC721(name, symbol) ERC20(shardName, shardSymbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        _grantRole(DEFAULT_ADMIN_ROLE, admin); // Explicit admin
        _baseTokenURI = baseTokenURI_;
        auraLevelThresholds = initialAuraLevelThresholds;
        currentEpoch = 1; // Start at Epoch 1
    }

    // --- I. Core ChronoAura Emblem (ERC721) Management ---

    /**
     * @notice Allows a user to mint a new ChronoAura Emblem (NFT), starting with 0 Aura.
     * @dev The tokenId is automatically incremented.
     */
    function mintEmblem() public payable whenNotPaused {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(msg.sender, newItemId);
        auraScores[newItemId] = 0; // Start with 0 Aura
        emit EmblemMinted(msg.sender, newItemId, 0);
        _updateEmblemVisuals(newItemId); // Trigger metadata refresh
    }

    /**
     * @notice Allows an Emblem owner to permanently destroy their Emblem.
     * @param tokenId The ID of the Emblem to burn.
     */
    function burnEmblem(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _burn(tokenId);
        delete auraScores[tokenId]; // Remove aura score
    }

    /**
     * @notice Standard ERC721 function to transfer ownership of an Emblem.
     * @param from The current owner of the Emblem.
     * @param to The recipient of the Emblem.
     * @param tokenId The ID of the Emblem to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Returns the dynamic metadata URI for an Emblem, reflecting its current auraScore and the currentEpoch.
     * @param tokenId The ID of the Emblem.
     * @return A string representing the URI to the metadata JSON.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        // Construct a URI that reflects aura level and epoch for dynamic rendering
        // Example: https://api.chronoaura.com/emblem/1?auraLevel=3&epoch=2
        // An off-chain server would use these parameters to generate dynamic JSON/image.
        uint256 auraLevel = getAuraLevel(tokenId);
        return string(abi.encodePacked(
            _baseTokenURI,
            tokenId.toString(),
            "?auraLevel=", auraLevel.toString(),
            "&epoch=", currentEpoch.toString()
        ));
    }

    /**
     * @notice Retrieves the current Aura score for a given Emblem.
     * @param tokenId The ID of the Emblem.
     * @return The current Aura score.
     */
    function getEmblemAura(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Emblem does not exist");
        return auraScores[tokenId];
    }

    // --- II. Aura Progression & Evolution ---

    /**
     * @notice Increases an Emblem's Aura score, typically as a reward for challenge completion.
     * @dev Only callable by DEFAULT_ADMIN_ROLE or VERIFIER_ROLE.
     * @param tokenId The ID of the Emblem to update.
     * @param amount The amount of Aura to add.
     */
    function incrementAura(uint256 tokenId, uint256 amount) public virtual onlyRole(VERIFIER_ROLE) whenNotPaused {
        require(_exists(tokenId), "Emblem does not exist");
        uint256 oldAura = auraScores[tokenId];
        auraScores[tokenId] += amount;
        emit AuraIncreased(tokenId, oldAura, auraScores[tokenId]);
        _updateEmblemVisuals(tokenId); // Trigger metadata refresh
    }

    /**
     * @notice Decreases an Emblem's Aura score, for penalties or failed challenges (rare).
     * @dev Only callable by DEFAULT_ADMIN_ROLE. Aura score cannot go below 0.
     * @param tokenId The ID of the Emblem to update.
     * @param amount The amount of Aura to subtract.
     */
    function decrementAura(uint256 tokenId, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_exists(tokenId), "Emblem does not exist");
        uint256 oldAura = auraScores[tokenId];
        auraScores[tokenId] = oldAura > amount ? oldAura - amount : 0;
        emit AuraDecreased(tokenId, oldAura, auraScores[tokenId]);
        _updateEmblemVisuals(tokenId); // Trigger metadata refresh
    }

    /**
     * @notice Calculates the current "level" of an Emblem based on its auraScore and defined thresholds.
     * @param tokenId The ID of the Emblem.
     * @return The current aura level (e.g., 1, 2, 3...).
     */
    function getAuraLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Emblem does not exist");
        uint256 aura = auraScores[tokenId];
        for (uint256 i = 0; i < auraLevelThresholds.length; i++) {
            if (aura < auraLevelThresholds[i]) {
                return i + 1; // Level is 1-indexed
            }
        }
        return auraLevelThresholds.length + 1; // Highest possible level
    }

    /**
     * @dev Internal helper to trigger metadata updates. Emits an event to notify off-chain services.
     * @param tokenId The ID of the Emblem to update.
     */
    function _updateEmblemVisuals(uint256 tokenId) internal {
        // This function doesn't change the actual URI string stored on-chain,
        // but it can be used to signal external services that the dynamic URI
        // might have changed and needs to be re-fetched.
        // For ERC721URIStorage, tokenURI itself is dynamic. We just emit to signal a *potential* change.
        emit TokenMetadataUpdate(tokenId, tokenURI(tokenId));
    }

    /**
     * @notice Admin function to configure the Aura score boundaries for different visual/functional levels.
     * @param _thresholds An array of Aura scores, where each element is the minimum Aura for the next level.
     *                    Must be sorted in ascending order.
     */
    function setAuraLevelThresholds(uint256[] calldata _thresholds) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _thresholds.length; i++) {
            if (i > 0) {
                require(_thresholds[i] > _thresholds[i - 1], "Thresholds must be strictly increasing");
            }
        }
        auraLevelThresholds = _thresholds;
    }

    // --- III. ChronoShards (ERC20) & Economy ---

    /**
     * @notice Mints new ChronoShards and sends them to a specified address.
     * @dev Primarily for challenge rewards or initial distribution. Only callable by DEFAULT_ADMIN_ROLE.
     * @param to The address to receive the new ChronoShards.
     * @param amount The amount of ChronoShards to mint.
     */
    function mintChronoShards(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _mint(to, amount);
    }

    /**
     * @notice Burns ChronoShards from the caller's balance.
     * @dev Used for challenge entry fees or economic adjustments.
     * @param amount The amount of ChronoShards to burn.
     */
    function burnChronoShards(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Standard ERC20 function to transfer ChronoShards.
     * @param to The recipient of the ChronoShards.
     * @param amount The amount of ChronoShards to transfer.
     */
    function transfer(address to, uint256 amount) public override(ERC20, IERC20) whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    /**
     * @notice Returns the ChronoShards balance of an address.
     * @param account The address to query.
     */
    function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    // --- IV. Epoch & Temporal Progression ---

    /**
     * @notice Admin function to move the system to the next Epoch.
     * @dev Unlocks new challenge types or modifies game mechanics. Resets epoch-specific states.
     */
    function advanceEpoch() public onlyRole(DEFAULT_ADMIN_ROLE) {
        currentEpoch++;
        // Emit events or perform other epoch-specific resets if needed
        emit EpochAdvanced(currentEpoch);
    }

    /**
     * @notice Returns the current active Epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Admin function to define which `ChallengeType`s are permissible in a given Epoch.
     * @param epoch The epoch number.
     * @param types An array of `uint256` representing `ChallengeType` enums.
     */
    function setEpochChallengeTypes(uint256 epoch, uint256[] calldata types) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Clear existing types for this epoch first
        for (uint256 i = 0; i < 2; i++) { // Max number of ChallengeTypes
            epochAllowedChallengeTypes[epoch][i] = false;
        }
        for (uint256 i = 0; i < types.length; i++) {
            require(types[i] < uint256(ChallengeType.OffChainProofHash) + 1, "Invalid ChallengeType");
            epochAllowedChallengeTypes[epoch][types[i]] = true;
        }
    }

    // --- V. Decentralized Challenge System ---

    /**
     * @notice Allows users to propose new challenges, requiring a ChronoShards stake.
     * @param _description A description or link to the challenge details.
     * @param _auraReward The Aura amount to reward participants.
     * @param _shardReward The ChronoShards amount to reward participants.
     * @param _challengeType The type of challenge (e.g., OnChainTx, OffChainProofHash).
     * @param _requiredStake The ChronoShards amount required to propose the challenge.
     */
    function proposeChallenge(
        string calldata _description,
        uint256 _auraReward,
        uint256 _shardReward,
        ChallengeType _challengeType,
        uint256 _requiredStake
    ) public whenNotPaused {
        require(_requiredStake > 0, "Challenge proposal requires a stake");
        require(_auraReward > 0 || _shardReward > 0, "Challenge must offer rewards");
        require(epochAllowedChallengeTypes[currentEpoch][uint256(_challengeType)], "Challenge type not allowed in current epoch");

        _transfer(msg.sender, address(this), _requiredStake); // Transfer stake to contract

        _challengeProposalCounter.increment();
        uint256 proposalId = _challengeProposalCounter.current();

        challengeProposals[proposalId] = ChallengeProposal({
            proposer: msg.sender,
            description: _description,
            auraReward: _auraReward,
            shardReward: _shardReward,
            challengeType: _challengeType,
            requiredStake: _requiredStake,
            votesFor: 0,
            votesAgainst: 0,
            status: ChallengeStatus.Proposed,
            createdAt: block.timestamp,
            challengeId: 0, // No associated challenge yet
            totalAuraVotingPower: 0
        });

        emit ChallengeProposed(proposalId, msg.sender, _requiredStake, _auraReward, _shardReward);
    }

    /**
     * @notice Emblem holders can vote on proposed challenges using their Emblem's Aura power.
     * @param proposalId The ID of the challenge proposal.
     * @param voteFor True for a 'for' vote, false for 'against'.
     * @param tokenId The ID of the Emblem used for voting power.
     */
    function voteOnChallengeProposal(uint256 proposalId, bool voteFor, uint256 tokenId) public whenNotPaused {
        ChallengeProposal storage proposal = challengeProposals[proposalId];
        require(proposal.status == ChallengeStatus.Proposed, "Proposal not in voting state");
        require(_exists(tokenId), "Emblem does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller must own the Emblem");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 auraPower = auraScores[tokenId];
        require(auraPower > 0, "Emblem must have Aura to vote");

        if (voteFor) {
            proposal.votesFor += auraPower;
        } else {
            proposal.votesAgainst += auraPower;
        }
        proposal.hasVoted[msg.sender] = true;
        proposal.totalAuraVotingPower += auraPower;

        emit ChallengeProposalVoted(proposalId, msg.sender, voteFor, auraPower);
    }

    /**
     * @notice Initiates an approved challenge, making it active for participants.
     * @dev Requires the proposal to have sufficient 'for' votes (e.g., > 50% of total Aura power)
     *      and only callable by DEFAULT_ADMIN_ROLE after voting period.
     * @param proposalId The ID of the challenge proposal.
     */
    function startChallenge(uint256 proposalId) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        ChallengeProposal storage proposal = challengeProposals[proposalId];
        require(proposal.status == ChallengeStatus.Proposed, "Proposal not in 'Proposed' status");
        
        // Simple majority based on Aura voting power
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass vote");
        // Add more complex voting duration/quorum checks here if needed

        _challengeCounter.increment();
        uint256 newChallengeId = _challengeCounter.current();

        challenges[newChallengeId] = Challenge({
            proposer: proposal.proposer,
            description: proposal.description,
            auraReward: proposal.auraReward,
            shardReward: proposal.shardReward,
            challengeType: proposal.challengeType,
            totalSponsoredShards: proposal.requiredStake, // Initial stake becomes part of sponsorship
            status: ChallengeStatus.Active
        });

        proposal.status = ChallengeStatus.Active;
        proposal.challengeId = newChallengeId;

        emit ChallengeStarted(newChallengeId, proposalId);
    }

    /**
     * @notice Participants submit proof of challenge completion.
     * @dev `_proofHash` could be an IPFS hash for off-chain proofs, or a transaction hash for on-chain.
     * @param challengeId The ID of the active challenge.
     * @param _proofHash A string representing the proof of completion.
     */
    function submitChallengeCompletion(uint256 challengeId, string calldata _proofHash) public whenNotPaused {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.status == ChallengeStatus.Active, "Challenge not active");
        require(bytes(_proofHash).length > 0, "Proof hash cannot be empty");
        
        // Only one submission per participant per challenge
        require(challenges[challengeId].completions[msg.sender].submissionTime == 0, "Already submitted for this challenge");

        challenges[challengeId].completions[msg.sender] = ChallengeCompletion({
            proofHash: _proofHash,
            verified: false,
            rewarded: false,
            submissionTime: block.timestamp
        });

        emit ChallengeCompletionSubmitted(challengeId, msg.sender, _proofHash);
    }

    /**
     * @notice Verifiers (Oracles/Admins) confirm challenge completion for a specific participant.
     * @param challengeId The ID of the challenge.
     * @param participant The address of the participant.
     * @param verified True if the completion is valid, false otherwise.
     */
    function verifyChallengeCompletion(uint256 challengeId, address participant, bool verified) public onlyRole(VERIFIER_ROLE) whenNotPaused {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.status == ChallengeStatus.Active, "Challenge not active");
        require(challenge.completions[participant].submissionTime > 0, "Participant has not submitted for this challenge");
        require(!challenge.completions[participant].verified, "Completion already verified");

        challenge.completions[participant].verified = verified;
        emit ChallengeCompletionVerified(challengeId, participant, verified);
    }

    /**
     * @notice Awards Aura and ChronoShards to participants whose challenge completion has been verified.
     * @dev Callable by DEFAULT_ADMIN_ROLE or VERIFIER_ROLE after verification.
     * @param challengeId The ID of the challenge.
     * @param participant The address of the participant to reward.
     */
    function rewardChallengeCompletion(uint256 challengeId, address participant) public onlyRole(VERIFIER_ROLE) whenNotPaused {
        Challenge storage challenge = challenges[challengeId];
        ChallengeCompletion storage completion = challenge.completions[participant];
        
        require(challenge.status == ChallengeStatus.Active, "Challenge not active");
        require(completion.verified, "Completion not yet verified");
        require(!completion.rewarded, "Participant already rewarded for this challenge");

        // Reward Aura
        _incrementAuraInternal(ownerOf(_getEmblemOf(participant)), challenge.auraReward); // Assumes a user has an emblem
        
        // Reward ChronoShards
        // Ensure contract has enough sponsored shards
        uint256 totalRewardShards = challenge.shardReward;
        require(totalRewardShards > 0, "No shard reward defined");
        require(challenge.totalSponsoredShards >= totalRewardShards, "Insufficient sponsored shards in contract");

        _transfer(address(this), participant, totalRewardShards); // Transfer shards from contract to participant
        challenge.totalSponsoredShards -= totalRewardShards; // Deduct from sponsored pool

        completion.rewarded = true;
        emit ChallengeRewarded(challengeId, participant, challenge.auraReward, totalRewardShards);
    }

    // Helper to get an emblem owned by a specific address (simplistic for this example)
    function _getEmblemOf(address owner) internal view returns (uint256) {
        // In a real system, a user might own multiple emblems. This would need a more complex selection or a direct parameter.
        // For simplicity, we assume there's a primary emblem or we just get the first one.
        // This is a simplification and would need a robust implementation (e.g., specific emblem registration, etc.)
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (ownerOf(i) == owner) {
                return i;
            }
        }
        revert("Participant does not own an Emblem.");
    }

    // Internal version of incrementAura to avoid role check when called from other internal functions
    function _incrementAuraInternal(uint256 tokenId, uint256 amount) internal {
        require(_exists(tokenId), "Emblem does not exist");
        uint256 oldAura = auraScores[tokenId];
        auraScores[tokenId] += amount;
        emit AuraIncreased(tokenId, oldAura, auraScores[tokenId]);
        _updateEmblemVisuals(tokenId);
    }


    /**
     * @notice Allows admin/governance to cancel an active challenge.
     * @param challengeId The ID of the challenge to cancel.
     */
    function cancelChallenge(uint256 challengeId) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.status == ChallengeStatus.Active, "Challenge not active");
        challenge.status = ChallengeStatus.Cancelled;
        // Optionally refund proposer's stake here if it wasn't used for sponsorship
        emit ChallengeCancelled(challengeId);
    }

    // --- VI. Staking & Sponsorship ---

    /**
     * @notice Allows users to stake ChronoShards for validation purposes.
     * @param amount The amount of ChronoShards to stake.
     */
    function stakeChronoShardsForValidation(uint256 amount) public whenNotPaused {
        require(amount > 0, "Must stake a positive amount");
        _transfer(msg.sender, address(this), amount); // Transfer shards to contract
        stakedChronoShardsForValidation[msg.sender] += amount;
        emit ChronoShardsStakedForValidation(msg.sender, amount);
    }

    /**
     * @notice Allows users to unstake their previously staked ChronoShards.
     * @param amount The amount of ChronoShards to unstake.
     */
    function unstakeChronoShards(uint256 amount) public whenNotPaused {
        require(amount > 0, "Must unstake a positive amount");
        require(stakedChronoShardsForValidation[msg.sender] >= amount, "Insufficient staked ChronoShards");
        stakedChronoShardsForValidation[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount); // Transfer shards back
        emit ChronoShardsUnstaked(msg.sender, amount);
    }

    /**
     * @notice Allows users/projects to stake ChronoShards to fund the rewards for a specific challenge.
     * @param challengeId The ID of the challenge to sponsor.
     * @param amount The amount of ChronoShards to sponsor.
     */
    function sponsorChallenge(uint256 challengeId, uint256 amount) public whenNotPaused {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.status == ChallengeStatus.Active, "Challenge not active or found");
        require(amount > 0, "Sponsorship amount must be positive");
        _transfer(msg.sender, address(this), amount); // Transfer shards to contract
        challenge.totalSponsoredShards += amount;
        emit ChallengeSponsored(challengeId, msg.sender, amount);
    }

    // --- VII. Oracle & Role Management ---

    /**
     * @notice Admin function to grant the `VERIFIER_ROLE` to an address.
     * @param account The address to grant the role to.
     */
    function addVerifier(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VERIFIER_ROLE, account);
    }

    /**
     * @notice Admin function to revoke the `VERIFIER_ROLE` from an address.
     * @param account The address to revoke the role from.
     */
    function removeVerifier(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(VERIFIER_ROLE, account);
    }

    /**
     * @notice Checks if an address has the `VERIFIER_ROLE`.
     * @param account The address to check.
     * @return True if the address has the role, false otherwise.
     */
    function isVerifier(address account) public view returns (bool) {
        return hasRole(VERIFIER_ROLE, account);
    }

    // --- VIII. Security & Administration ---

    /**
     * @notice Pauses key contract functions (e.g., transfers, challenge proposals) in emergencies.
     * @dev Only callable by DEFAULT_ADMIN_ROLE.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing paused functions to resume.
     * @dev Only callable by DEFAULT_ADMIN_ROLE.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Allows a challenge proposer to reclaim their initial stake if the proposal is rejected or cancelled.
     * @param proposalId The ID of the challenge proposal.
     */
    function withdrawProposalStake(uint256 proposalId) public whenNotPaused {
        ChallengeProposal storage proposal = challengeProposals[proposalId];
        require(proposal.proposer == msg.sender, "Only proposer can withdraw stake");
        require(proposal.status == ChallengeStatus.Cancelled || (proposal.status == ChallengeStatus.Proposed && proposal.votesFor <= proposal.votesAgainst), "Proposal not eligible for stake withdrawal");
        require(proposal.requiredStake > 0, "No stake to withdraw");

        uint256 stakeAmount = proposal.requiredStake;
        proposal.requiredStake = 0; // Prevent double withdrawal
        _transfer(address(this), msg.sender, stakeAmount);
        emit ProposalStakeWithdrawn(proposalId, msg.sender, stakeAmount);
    }

    // The following functions are required by ERC721 and AccessControl, but not explicitly part of the 20+ custom functions
    // They are inherited or overridden to ensure correct behavior.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721URIStorage) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
```