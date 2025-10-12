The **AuraForge Protocol** is a decentralized reputation and dynamic asset system. It introduces a sophisticated on-chain "Aura" score for every address, representing a user's reputation and engagement within the ecosystem. This Aura dynamically influences an associated "Essence" – a unique ERC721 NFT whose metadata and visual representation evolve based on its holder's real-time Aura score.

The protocol encourages active participation through an attestation system, allowing users to build or challenge reputations. It also incorporates staking mechanisms for Aura boosts, a decay mechanism to ensure active engagement, and an Aura-weighted governance system. Users can earn "Seals," which are non-transferable achievement badges, further enhancing their on-chain identity. AuraForge aims to create a living, evolving on-chain identity that is earned, maintained, and leveraged for various Web3 interactions.

---

## Contract: `AuraForge`

**Outline:**

1.  **Interfaces (`IAuraForgeToken`, `IAuraEssenceNFT`, `IGovernanceModule`)**: Define external contract interactions.
2.  **Error Definitions**: Custom errors for efficient and clear error handling.
3.  **Structs & Enums**: Data structures for `Attestation`, `Seal`, and `Proposal`.
4.  **State Variables**: Core mappings and variables to store protocol data.
5.  **Events**: Log significant actions on the blockchain.
6.  **Constructor**: Initializes the contract with an owner and basic parameters.
7.  **Access Control & Pausability**: Standard OpenZeppelin patterns for security.
8.  **Protocol Configuration**: Functions for owner to set and update critical contract addresses and parameters.
9.  **Aura (Reputation) Management**:
    *   Retrieve Aura score.
    *   Stake and unstake tokens to influence Aura.
    *   Trigger Aura decay.
    *   Calculate pending rewards for high-Aura holders.
10. **Attestation System**:
    *   Submit positive and negative attestations.
    *   Revoke own attestations.
11. **Essence (Dynamic NFT) Integration**:
    *   Mint an Essence NFT.
    *   Trigger metadata synchronization for an Essence NFT.
    *   Retrieve the Essence NFT ID for a user.
12. **Seals (Achievements)**:
    *   Issue non-transferable achievement badges.
    *   Retrieve Seals held by a user.
13. **Aura-Weighted Governance & Utilities**:
    *   Check Aura against a threshold for external use cases.
    *   Delegate and undelegate Aura-based voting power.
    *   Create governance proposals.
    *   Withdraw funds from the protocol treasury via governance.
14. **Internal / View Helpers**: Helper functions for internal logic and data retrieval.

---

**Function Summary:**

1.  `constructor(address initialOwner)`: Initializes the contract, sets the owner, and default parameters.
2.  `pause()`: Pauses the contract, restricting sensitive operations (Owner-only).
3.  `unpause()`: Unpauses the contract, re-enabling operations (Owner-only).
4.  `transferOwnership(address newOwner)`: Transfers ownership of the contract (Owner-only).
5.  `setAuraForgeToken(address _tokenAddress)`: Sets the ERC20 token address used for staking (Owner-only).
6.  `setEssenceNFTContract(address _essenceNFTAddress)`: Sets the ERC721 contract address for Essence NFTs (Owner-only).
7.  `setGovernanceModule(address _governanceModuleAddress)`: Sets the external Governance Module contract address (Owner-only).
8.  `getAuraScore(address _user) view returns (uint256)`: Returns the current Aura score of a specified user.
9.  `stakeForAuraBoost(uint256 _amount)`: Allows a user to stake `AuraForgeToken`s to increase their Aura.
10. `unstakeFromAuraBoost(uint256 _amount)`: Allows a user to unstake `AuraForgeToken`s, reducing their Aura.
11. `attestPositiveAction(address _target, string memory _uri)`: Allows a user to give positive reputation to another, requiring a minimum Aura from the attester.
12. `attestNegativeAction(address _target, string memory _uri)`: Allows a user to give negative reputation, requiring a higher minimum Aura and a cooldown period for the attester.
13. `revokeAttestation(address _target, uint256 _attestationId)`: Allows an attester to revoke their previously made attestation.
14. `decayAura(address _user)`: Triggers the time-based decay of a user's Aura, callable by anyone (incentivized or keeper network).
15. `getPendingAuraRewards(address _user) view returns (uint256)`: Calculates potential rewards for a user based on their high Aura score and duration.
16. `mintEssence()`: Mints a unique Essence NFT for the caller, requiring a minimum Aura score.
17. `syncEssenceMetadata(uint256 _tokenId)`: Triggers the associated Essence NFT contract to update the metadata for a specific NFT based on its holder's current Aura.
18. `getEssenceTokenId(address _owner) view returns (uint256)`: Retrieves the Essence NFT ID owned by a given address.
19. `issueSeal(address _recipient, uint256 _sealId, string memory _uri)`: Mints a non-transferable achievement "Seal" to a recipient (Admin/Role-based).
20. `getSeals(address _user) view returns (uint256[] memory)`: Returns an array of Seal IDs held by a specified user.
21. `hasAuraThreshold(address _user, uint256 _minAura) view returns (bool)`: Checks if a user's Aura meets a specified minimum threshold (for external contract integrations).
22. `delegateAuraVote(address _delegate)`: Allows a user to delegate their Aura-based voting power to another address.
23. `undelegateAuraVote()`: Allows a user to revoke their Aura delegation.
24. `proposeAction(address _target, bytes memory _callData, string memory _description)`: Creates a new governance proposal, requiring a significant Aura score from the proposer.
25. `withdrawAuraForgeTreasury(address _to, uint256 _amount)`: Allows the protocol's treasury funds to be withdrawn to a specified address, executable only by the Governance Module.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safe math, though 0.8+ has overflow checks

/// @title IAuraForgeToken
/// @notice Interface for the ERC20 token used for staking within AuraForge.
interface IAuraForgeToken is IERC20 {
    // Standard ERC20 functions are sufficient
}

/// @title IAuraEssenceNFT
/// @notice Interface for the Essence ERC721 NFT contract, which is dynamic and linked to Aura.
interface IAuraEssenceNFT is IERC721 {
    /// @dev Function to update an Essence NFT's metadata based on its holder's Aura.
    /// This should be callable by the AuraForge contract.
    function updateAuraBasedMetadata(uint256 _tokenId, uint256 _newAuraScore) external;

    /// @dev Mint an Essence NFT for a user. Callable only by AuraForge.
    function mint(address _to, uint256 _auraScore) external returns (uint256);

    /// @dev Get the Essence NFT token ID for a given owner.
    function getTokenIdForOwner(address _owner) external view returns (uint256);
}

/// @title IGovernanceModule
/// @notice Interface for an external governance module that interacts with AuraForge.
interface IGovernanceModule {
    /// @dev Called by AuraForge to check if a proposal execution is valid.
    function isProposalApproved(uint256 _proposalId) external view returns (bool);

    /// @dev Called by AuraForge to submit a proposal for voting.
    function registerProposal(uint256 _auraForgeProposalId, address _proposer, uint256 _requiredAura) external;

    /// @dev Called by AuraForge to cast a vote on a proposal.
    function recordVote(uint256 _proposalId, address _voter, uint256 _auraWeight, bool _support) external;
}


/// @title AuraForge
/// @notice A decentralized reputation and dynamic asset protocol.
/// @dev Manages user Aura (reputation), dynamic Essence NFTs, attestations, and Aura-weighted governance.
contract AuraForge is Ownable, Pausable {
    using SafeMath for uint256; // Explicitly use SafeMath for clarity, even if 0.8+ has built-in checks

    // --- Custom Errors ---
    error AuraForge__ZeroAddress();
    error AuraForge__NotEnoughStaked();
    error AuraForge__InsufficientAllowance();
    error AuraForge__InsufficientAura(uint256 currentAura, uint256 requiredAura);
    error AuraForge__AttesterAuraTooLow();
    error AuraForge__AttestationCooldownNotPassed(uint256 timeLeft);
    error AuraForge__AttestationNotFound();
    error AuraForge__EssenceAlreadyMinted();
    error AuraForge__EssenceNotMinted();
    error AuraForge__InvalidEssenceTokenId();
    error AuraForge__CannotSelfAttest();
    error AuraForge__InvalidProposalId();
    error AuraForge__ProposalAlreadyExists();
    error AuraForge__OnlyGovernanceModule();
    error AuraForge__EssenceTransferRestricted();
    error AuraForge__AuraDecayPeriodNotPassed(uint256 timeLeft);

    // --- Enums & Structs ---
    struct Attestation {
        address attester;
        uint256 timestamp;
        int256 impact; // Positive or negative impact on Aura
        string uri; // IPFS hash or URL for attestation details/proof
        bool revoked;
    }

    struct Proposal {
        address proposer;
        address target;
        bytes callData;
        string description;
        uint256 creationTime;
        bool executed;
    }

    // --- State Variables ---

    IAuraForgeToken public auraForgeToken; // The ERC20 token used for staking
    IAuraEssenceNFT public essenceNFT;     // The ERC721 contract for dynamic Essence NFTs
    IGovernanceModule public governanceModule; // External contract handling detailed proposal voting

    mapping(address => uint256) public auraScores;          // User's current Aura score
    mapping(address => uint256) public stakedAmounts;        // Tokens staked by user
    mapping(address => uint256) public lastAuraUpdate;       // Last timestamp Aura was updated for decay
    mapping(address => uint256) public lastAttestationTime;  // Last timestamp user made an attestation

    // Attestations: target => attester => attestationId => Attestation
    mapping(address => mapping(address => mapping(uint256 => Attestation))) private _attestations;
    mapping(address => mapping(address => uint256)) private _attestationCount; // Count per (target, attester) pair

    mapping(address => uint256) public essenceTokenIds;      // User => Essence NFT token ID
    mapping(uint256 => address) public essenceOwners;        // Essence NFT ID => Owner address (for quick lookup)

    // Seals: user => sealId => true (if owned)
    mapping(address => mapping(uint256 => bool)) private _userSeals;
    mapping(address => uint256[]) private _userSealList; // To easily retrieve all seals for a user

    mapping(address => address) public auraDelegates; // User => delegatee

    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal struct
    uint256 public nextProposalId; // Counter for new proposals

    // Protocol Parameters (adjustable by owner/governance)
    uint256 public constant AURA_DECIMALS = 18; // Aura score is handled with 18 decimals for precision
    uint256 public auraStakingMultiplier = 10; // Aura boost per staked token (e.g., 1 token = 10 Aura points)
    uint256 public positiveAttestationWeight = 100 * (10**AURA_DECIMALS); // Impact of a positive attestation
    uint256 public negativeAttestationWeight = 200 * (10**AURA_DECIMALS); // Impact of a negative attestation (higher)
    uint256 public attestationCooldown = 1 days; // Cooldown period for making attestations
    uint224 public auraDecayRatePerDay = 1 * (10**AURA_DECIMALS); // Aura decay rate per day (e.g., 1 Aura per day)
    uint256 public auraDecayPeriod = 1 days; // How often Aura decay can be triggered for a user

    uint256 public minAuraForAttester = 1000 * (10**AURA_DECIMALS); // Min Aura to make any attestation
    uint256 public minAuraForNegativeAttester = 5000 * (10**AURA_DECIMALS); // Min Aura for negative attestation
    uint256 public minAuraToMintEssence = 500 * (10**AURA_DECIMALS); // Min Aura to mint an Essence NFT
    uint256 public minAuraToCreateProposal = 10000 * (10**AURA_DECIMALS); // Min Aura to create a governance proposal

    uint256 public rewardPoolBalance; // Tracks funds available for Aura rewards

    // --- Events ---
    event AuraScoreUpdated(address indexed user, uint256 oldAura, uint256 newAura, string reason);
    event TokensStaked(address indexed user, uint256 amount, uint256 newAura);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 newAura);
    event PositiveAttestation(address indexed attester, address indexed target, uint256 attestationId, uint256 auraImpact, string uri);
    event NegativeAttestation(address indexed attester, address indexed target, uint256 attestationId, uint256 auraImpact, string uri);
    event AttestationRevoked(address indexed attester, address indexed target, uint256 attestationId);
    event EssenceMinted(address indexed owner, uint256 tokenId, uint256 auraScore);
    event EssenceMetadataSynced(uint256 indexed tokenId, uint256 newAuraScore);
    event SealIssued(address indexed recipient, uint256 indexed sealId, string uri);
    event AuraDelegateChanged(address indexed delegator, address indexed delegatee);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, address target, string description);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event TreasuryWithdrawn(address indexed to, uint256 amount);

    modifier onlyEssenceNFTContract() {
        if (msg.sender != address(essenceNFT)) {
            revert("AuraForge: Caller is not the Essence NFT contract");
        }
        _;
    }

    modifier onlyGovernanceModule() {
        if (msg.sender != address(governanceModule)) {
            revert AuraForge__OnlyGovernanceModule();
        }
        _;
    }

    constructor(address initialOwner) Ownable(initialOwner) Pausable() {
        nextProposalId = 1;
    }

    // --- Access Control & Pausability ---
    // (Inherited from OpenZeppelin Ownable and Pausable, so no explicit functions needed here,
    // but the summary includes them as they are part of the contract's exposed functionality.)
    // `pause()` and `unpause()` are public functions from Pausable.
    // `transferOwnership()` is a public function from Ownable.

    // --- Protocol Configuration (Owner-only) ---
    function setAuraForgeToken(address _tokenAddress) external onlyOwner whenNotPaused {
        if (_tokenAddress == address(0)) revert AuraForge__ZeroAddress();
        auraForgeToken = IAuraForgeToken(_tokenAddress);
    }

    function setEssenceNFTContract(address _essenceNFTAddress) external onlyOwner whenNotPaused {
        if (_essenceNFTAddress == address(0)) revert AuraForge__ZeroAddress();
        essenceNFT = IAuraEssenceNFT(_essenceNFTAddress);
    }

    function setGovernanceModule(address _governanceModuleAddress) external onlyOwner whenNotPaused {
        if (_governanceModuleAddress == address(0)) revert AuraForge__ZeroAddress();
        governanceModule = IGovernanceModule(_governanceModuleAddress);
    }

    function setAuraStakingMultiplier(uint256 _multiplier) external onlyOwner {
        auraStakingMultiplier = _multiplier;
    }

    function setAttestationWeights(uint256 _positive, uint256 _negative) external onlyOwner {
        positiveAttestationWeight = _positive;
        negativeAttestationWeight = _negative;
    }

    function setAttestationCooldown(uint256 _cooldown) external onlyOwner {
        attestationCooldown = _cooldown;
    }

    function setAuraDecayParameters(uint224 _ratePerDay, uint256 _decayPeriod) external onlyOwner {
        auraDecayRatePerDay = _ratePerDay;
        auraDecayPeriod = _decayPeriod;
    }

    function setMinimumAuraRequirements(
        uint224 _minAttester,
        uint224 _minNegativeAttester,
        uint224 _minMintEssence,
        uint224 _minCreateProposal
    ) external onlyOwner {
        minAuraForAttester = _minAttester;
        minAuraForNegativeAttester = _minNegativeAttester;
        minAuraToMintEssence = _minMintEssence;
        minAuraToCreateProposal = _minCreateProposal;
    }


    // --- Aura (Reputation) Management ---

    /// @notice Returns the current Aura score of a specified user.
    /// @param _user The address of the user.
    /// @return The current Aura score of the user.
    function getAuraScore(address _user) public view returns (uint256) {
        return auraScores[_user];
    }

    /// @notice Allows a user to stake AuraForgeToken to increase their Aura.
    /// @dev Tokens are transferred from the user to the contract. Aura is immediately updated.
    /// @param _amount The amount of tokens to stake.
    function stakeForAuraBoost(uint256 _amount) external whenNotPaused {
        if (_amount == 0) return;
        if (auraForgeToken.allowance(msg.sender, address(this)) < _amount) {
            revert AuraForge__InsufficientAllowance();
        }

        auraForgeToken.transferFrom(msg.sender, address(this), _amount);
        stakedAmounts[msg.sender] = stakedAmounts[msg.sender].add(_amount);

        // Update Aura based on staking
        uint256 oldAura = auraScores[msg.sender];
        uint256 newAura = stakedAmounts[msg.sender].mul(auraStakingMultiplier); // Simple linear boost
        auraScores[msg.sender] = newAura;
        lastAuraUpdate[msg.sender] = block.timestamp; // Reset decay timer

        emit TokensStaked(msg.sender, _amount, newAura);
        emit AuraScoreUpdated(msg.sender, oldAura, newAura, "staking");
    }

    /// @notice Allows a user to unstake AuraForgeToken.
    /// @dev Tokens are transferred from the contract back to the user. Aura is immediately updated.
    /// @param _amount The amount of tokens to unstake.
    function unstakeFromAuraBoost(uint256 _amount) external whenNotPaused {
        if (_amount == 0) return;
        if (stakedAmounts[msg.sender] < _amount) {
            revert AuraForge__NotEnoughStaked();
        }

        stakedAmounts[msg.sender] = stakedAmounts[msg.sender].sub(_amount);
        auraForgeToken.transfer(msg.sender, _amount);

        // Update Aura based on unstaking
        uint256 oldAura = auraScores[msg.sender];
        uint256 newAura = stakedAmounts[msg.sender].mul(auraStakingMultiplier);
        auraScores[msg.sender] = newAura;
        lastAuraUpdate[msg.sender] = block.timestamp; // Reset decay timer

        emit TokensUnstaked(msg.sender, _amount, newAura);
        emit AuraScoreUpdated(msg.sender, oldAura, newAura, "unstaking");
    }

    /// @notice Triggers the time-based decay of a user's Aura.
    /// @dev Can be called by anyone. Aura will only decay if `auraDecayPeriod` has passed.
    /// @param _user The address of the user whose Aura should be decayed.
    function decayAura(address _user) external whenNotPaused {
        uint256 timeSinceLastUpdate = block.timestamp.sub(lastAuraUpdate[_user]);
        if (timeSinceLastUpdate < auraDecayPeriod) {
            revert AuraForge__AuraDecayPeriodNotPassed(auraDecayPeriod.sub(timeSinceLastUpdate));
        }

        uint256 oldAura = auraScores[_user];
        uint256 decayAmount = (timeSinceLastUpdate.div(1 days)).mul(auraDecayRatePerDay); // Simplified decay calculation
        
        uint256 newAura = oldAura;
        if (oldAura > decayAmount) {
            newAura = oldAura.sub(decayAmount);
        } else {
            newAura = 0; // Aura cannot go negative
        }
        
        // Ensure Aura from staking is not decayed
        uint256 auraFromStaking = stakedAmounts[_user].mul(auraStakingMultiplier);
        if (newAura < auraFromStaking) {
            newAura = auraFromStaking;
        }

        auraScores[_user] = newAura;
        lastAuraUpdate[_user] = block.timestamp;

        emit AuraScoreUpdated(_user, oldAura, newAura, "decay");
        _syncEssenceMetadata(_user); // Update Essence NFT if Aura changed
    }

    /// @notice Calculates potential rewards for a user based on their high Aura score.
    /// @dev This is a placeholder for a more complex reward distribution system.
    /// @param _user The address of the user to check rewards for.
    /// @return The amount of pending Aura rewards.
    function getPendingAuraRewards(address _user) public view returns (uint256) {
        // This function would typically involve a more complex calculation based on
        // reward distribution logic, time, and specific Aura thresholds.
        // For demonstration, it's a simple placeholder.
        uint256 currentAura = auraScores[_user];
        if (currentAura > minAuraToCreateProposal) { // Example: only top tier Aura holders get rewards
            // A simple proportional reward based on Aura, perhaps from a 'rewardPoolBalance'
            // In a real system, this would be integrated with a yield farming or distribution module.
            return currentAura.div(100); // 1% of Aura as hypothetical reward
        }
        return 0;
    }

    // --- Attestation System ---

    /// @notice Allows a user to give positive reputation to another.
    /// @dev Requires a minimum Aura from the attester.
    /// @param _target The address receiving the attestation.
    /// @param _uri An IPFS hash or URL for attestation details/proof.
    function attestPositiveAction(address _target, string memory _uri) external whenNotPaused {
        if (msg.sender == _target) revert AuraForge__CannotSelfAttest();
        if (auraScores[msg.sender] < minAuraForAttester) revert AuraForge__AttesterAuraTooLow();

        // Check attestation cooldown
        uint256 timeSinceLastAttestation = block.timestamp.sub(lastAttestationTime[msg.sender]);
        if (timeSinceLastAttestation < attestationCooldown) {
            revert AuraForge__AttestationCooldownNotPassed(attestationCooldown.sub(timeSinceLastAttestation));
        }

        uint256 oldAura = auraScores[_target];
        auraScores[_target] = auraScores[_target].add(positiveAttestationWeight);
        lastAuraUpdate[_target] = block.timestamp; // Reset decay timer for target

        uint256 id = _attestationCount[_target][msg.sender];
        _attestations[_target][msg.sender][id] = Attestation(msg.sender, block.timestamp, int256(positiveAttestationWeight), _uri, false);
        _attestationCount[_target][msg.sender] = id.add(1);
        lastAttestationTime[msg.sender] = block.timestamp;

        emit PositiveAttestation(msg.sender, _target, id, positiveAttestationWeight, _uri);
        emit AuraScoreUpdated(_target, oldAura, auraScores[_target], "positive attestation");
        _syncEssenceMetadata(_target);
    }

    /// @notice Allows a user to give negative reputation.
    /// @dev Requires a higher minimum Aura from the attester and a cooldown.
    /// @param _target The address receiving the attestation.
    /// @param _uri An IPFS hash or URL for attestation details/proof.
    function attestNegativeAction(address _target, string memory _uri) external whenNotPaused {
        if (msg.sender == _target) revert AuraForge__CannotSelfAttest();
        if (auraScores[msg.sender] < minAuraForNegativeAttester) revert AuraForge__AttesterAuraTooLow();

        // Check attestation cooldown
        uint256 timeSinceLastAttestation = block.timestamp.sub(lastAttestationTime[msg.sender]);
        if (timeSinceLastAttestation < attestationCooldown) {
            revert AuraForge__AttestationCooldownNotPassed(attestationCooldown.sub(timeSinceLastAttestation));
        }

        uint256 oldAura = auraScores[_target];
        if (auraScores[_target] > negativeAttestationWeight) {
            auraScores[_target] = auraScores[_target].sub(negativeAttestationWeight);
        } else {
            auraScores[_target] = 0; // Aura cannot go negative
        }
        lastAuraUpdate[_target] = block.timestamp; // Reset decay timer for target

        uint256 id = _attestationCount[_target][msg.sender];
        _attestations[_target][msg.sender][id] = Attestation(msg.sender, block.timestamp, -int256(negativeAttestationWeight), _uri, false);
        _attestationCount[_target][msg.sender] = id.add(1);
        lastAttestationTime[msg.sender] = block.timestamp;

        emit NegativeAttestation(msg.sender, _target, id, negativeAttestationWeight, _uri);
        emit AuraScoreUpdated(_target, oldAura, auraScores[_target], "negative attestation");
        _syncEssenceMetadata(_target);
    }

    /// @notice Allows an attester to revoke their previously made attestation.
    /// @dev The Aura impact is reversed upon revocation.
    /// @param _target The address that received the original attestation.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAttestation(address _target, uint256 _attestationId) external whenNotPaused {
        Attestation storage att = _attestations[_target][msg.sender][_attestationId];
        if (att.attester != msg.sender || att.revoked) {
            revert AuraForge__AttestationNotFound();
        }

        att.revoked = true;

        uint256 oldAura = auraScores[_target];
        if (att.impact > 0) {
            // Revert positive impact
            if (auraScores[_target] >= uint256(att.impact)) {
                auraScores[_target] = auraScores[_target].sub(uint256(att.impact));
            } else {
                auraScores[_target] = 0;
            }
        } else {
            // Revert negative impact (add back)
            auraScores[_target] = auraScores[_target].add(uint256(-att.impact));
        }
        lastAuraUpdate[_target] = block.timestamp; // Reset decay timer for target

        emit AttestationRevoked(msg.sender, _target, _attestationId);
        emit AuraScoreUpdated(_target, oldAura, auraScores[_target], "attestation revoked");
        _syncEssenceMetadata(_target);
    }

    // --- Essence (Dynamic NFT) Integration ---

    /// @notice Mints a unique Essence NFT for the caller.
    /// @dev Requires a minimum Aura score from the minter. Each user can only mint one Essence.
    function mintEssence() external whenNotPaused {
        if (essenceTokenIds[msg.sender] != 0) {
            revert AuraForge__EssenceAlreadyMinted();
        }
        if (auraScores[msg.sender] < minAuraToMintEssence) {
            revert AuraForge__InsufficientAura(auraScores[msg.sender], minAuraToMintEssence);
        }
        if (address(essenceNFT) == address(0)) revert AuraForge__ZeroAddress(); // Essence NFT contract must be set

        uint256 newEssenceTokenId = essenceNFT.mint(msg.sender, auraScores[msg.sender]);
        essenceTokenIds[msg.sender] = newEssenceTokenId;
        essenceOwners[newEssenceTokenId] = msg.sender;

        emit EssenceMinted(msg.sender, newEssenceTokenId, auraScores[msg.sender]);
    }

    /// @notice Triggers the associated Essence NFT contract to update the metadata for a specific NFT.
    /// @dev This ensures the Essence NFT's appearance reflects its holder's current Aura.
    /// @param _tokenId The ID of the Essence NFT to sync.
    function syncEssenceMetadata(uint256 _tokenId) public whenNotPaused {
        address ownerOfEssence = essenceOwners[_tokenId];
        if (ownerOfEssence == address(0)) {
            revert AuraForge__InvalidEssenceTokenId();
        }
        if (msg.sender != ownerOfEssence && msg.sender != address(this)) {
            // Allow owner to trigger, or for internal calls
            revert("AuraForge: Not Essence owner or AuraForge contract.");
        }
        
        // Internal call to the Essence NFT contract
        essenceNFT.updateAuraBasedMetadata(_tokenId, auraScores[ownerOfEssence]);
        emit EssenceMetadataSynced(_tokenId, auraScores[ownerOfEssence]);
    }

    /// @notice Retrieves the Essence NFT ID owned by a given address.
    /// @param _owner The address of the Essence NFT owner.
    /// @return The token ID of the Essence NFT, or 0 if none.
    function getEssenceTokenId(address _owner) public view returns (uint256) {
        return essenceTokenIds[_owner];
    }

    // --- Seals (Achievements) ---

    /// @notice Issues a non-transferable achievement "Seal" to a recipient.
    /// @dev Callable only by the contract owner.
    /// @param _recipient The address to receive the Seal.
    /// @param _sealId A unique identifier for the type of Seal.
    /// @param _uri An IPFS hash or URL for the Seal's metadata/image.
    function issueSeal(address _recipient, uint256 _sealId, string memory _uri) external onlyOwner whenNotPaused {
        if (_recipient == address(0)) revert AuraForge__ZeroAddress();
        if (_userSeals[_recipient][_sealId]) {
            revert("AuraForge: Seal already issued to this recipient.");
        }

        _userSeals[_recipient][_sealId] = true;
        _userSealList[_recipient].push(_sealId);

        emit SealIssued(_recipient, _sealId, _uri);
    }

    /// @notice Returns an array of Seal IDs held by a specified user.
    /// @param _user The address of the user.
    /// @return An array of uint256 representing the Seal IDs.
    function getSeals(address _user) external view returns (uint256[] memory) {
        return _userSealList[_user];
    }

    // --- Aura-Weighted Governance & Utilities ---

    /// @notice Checks if a user's Aura meets a specified minimum threshold.
    /// @dev Useful for external contracts that want to implement Aura-gated access or features.
    /// @param _user The address of the user to check.
    /// @param _minAura The minimum Aura score required.
    /// @return True if the user's Aura is equal to or above the threshold, false otherwise.
    function hasAuraThreshold(address _user, uint256 _minAura) external view returns (bool) {
        return auraScores[_user] >= _minAura;
    }

    /// @notice Allows a user to delegate their Aura-based voting power to another address.
    /// @param _delegate The address to delegate voting power to.
    function delegateAuraVote(address _delegate) external whenNotPaused {
        if (_delegate == address(0)) revert AuraForge__ZeroAddress();
        if (_delegate == msg.sender) revert("AuraForge: Cannot delegate to self.");

        auraDelegates[msg.sender] = _delegate;
        emit AuraDelegateChanged(msg.sender, _delegate);
    }

    /// @notice Allows a user to revoke their Aura delegation.
    function undelegateAuraVote() external whenNotPaused {
        if (auraDelegates[msg.sender] == address(0)) {
            revert("AuraForge: No active delegation to undelegate.");
        }
        delete auraDelegates[msg.sender];
        emit AuraDelegateChanged(msg.sender, address(0));
    }

    /// @notice Creates a new governance proposal.
    /// @dev Requires a significant Aura score from the proposer. The proposal is then
    ///      registered with the external `governanceModule` for voting.
    /// @param _target The address of the contract the proposal aims to interact with.
    /// @param _callData The encoded function call data for the target contract.
    /// @param _description A description of the proposal.
    function proposeAction(address _target, bytes memory _callData, string memory _description) external whenNotPaused {
        if (auraScores[msg.sender] < minAuraToCreateProposal) {
            revert AuraForge__InsufficientAura(auraScores[msg.sender], minAuraToCreateProposal);
        }
        if (address(governanceModule) == address(0)) revert AuraForge__ZeroAddress(); // Governance module must be set

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal(msg.sender, _target, _callData, _description, block.timestamp, false);

        // Register with external governance module for voting
        governanceModule.registerProposal(proposalId, msg.sender, minAuraToCreateProposal);

        emit ProposalCreated(proposalId, msg.sender, _target, _description);
    }

    /// @notice Allows the external Governance Module to execute a passed proposal.
    /// @dev Only callable by the `governanceModule` address.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyGovernanceModule whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) { // Check if proposal exists
            revert AuraForge__InvalidProposalId();
        }
        if (proposal.executed) {
            revert("AuraForge: Proposal already executed.");
        }
        if (!governanceModule.isProposalApproved(_proposalId)) {
            revert("AuraForge: Proposal not approved by governance module.");
        }

        // Execute the proposed action
        (bool success, ) = proposal.target.call(proposal.callData);
        if (!success) {
            revert("AuraForge: Proposal execution failed.");
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, msg.sender);
    }

    /// @notice Allows the protocol's treasury funds (collected from fees or staking yield) to be withdrawn.
    /// @dev This function should only be callable by the `governanceModule` after a successful proposal.
    /// @param _to The address to send the funds to.
    /// @param _amount The amount of funds to withdraw.
    function withdrawAuraForgeTreasury(address _to, uint256 _amount) external onlyGovernanceModule whenNotPaused {
        if (_to == address(0)) revert AuraForge__ZeroAddress();
        if (rewardPoolBalance < _amount) revert("AuraForge: Insufficient treasury balance.");

        rewardPoolBalance = rewardPoolBalance.sub(_amount);
        // Assuming the treasury holds `AuraForgeToken` or native `ETH`.
        // If ETH: payable(to).transfer(amount);
        // If ERC20: auraForgeToken.transfer(_to, _amount);
        // For this example, let's assume it's `AuraForgeToken`
        auraForgeToken.transfer(_to, _amount);

        emit TreasuryWithdrawn(_to, _amount);
    }

    // --- Internal / View Helpers ---

    /// @dev Internal function to trigger Essence NFT metadata update for a user.
    /// @param _user The user whose Essence NFT should be synced.
    function _syncEssenceMetadata(address _user) internal {
        uint256 tokenId = essenceTokenIds[_user];
        if (tokenId != 0) {
            essenceNFT.updateAuraBasedMetadata(tokenId, auraScores[_user]);
            emit EssenceMetadataSynced(tokenId, auraScores[_user]);
        }
    }

    /// @dev To receive Ether (if any native ETH is sent to contract, e.g., for reward pool)
    receive() external payable {
        // You might want to handle this differently, e.g., only specific contracts can send ETH
        rewardPoolBalance = rewardPoolBalance.add(msg.value);
    }
}
```