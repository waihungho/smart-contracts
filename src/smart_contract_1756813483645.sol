This Solidity smart contract, **SynergyNet**, is designed as an adaptive, decentralized professional identity and skill validation platform. It introduces several advanced and creative concepts:

1.  **Soulbound Professional Identity NFTs (PINs):** Users mint non-transferable ERC721 tokens representing their professional identity, acting as a base for their on-chain profile.
2.  **Soulbound Skill Orbs:** Instead of separate tokens, skills are represented as data structures (orbs) tied directly to a user's PIN. These orbs have levels and are earned through peer attestations and validator approvals, making them truly non-transferable and intrinsic to the identity.
3.  **Dynamic Reputation System:** Each PIN holder has a reputation score that dynamically adjusts based on positive contributions (attestations received, validated skills) and gradually decays over time if not actively maintained, promoting continuous engagement.
4.  **Adaptive Parameters with Oracle Integration:** The system can dynamically adjust critical parameters (like skill demand factors influencing reputation/rewards) based on data provided by a trusted oracle, simulating real-world market relevance for skills.
5.  **Decentralized Autonomous Organization (DAO) Governance:** PIN holders govern the platform, proposing and voting on new skill categories, validator appointments, and adjustments to core system parameters (e.g., voting period, quorum, reputation decay rate).
6.  **Synergy Pool for Incentives:** A native token (ETH/MATIC) pool provides rewards for validators, high-quality attestors, and other significant contributors, aligning incentives within the network.

This combination of Soulbound Tokens, dynamic reputation, oracle-driven adaptation, and DAO governance for professional identity and skill validation aims to be unique and forward-thinking, addressing real-world needs for verifiable digital credentials in a decentralized manner.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline: SynergyNet - An Adaptive Decentralized Professional Identity & Skill Validation Platform

// SynergyNet is a decentralized platform designed to foster professional identity, validate skills,
// and manage reputation within a community. It leverages Soulbound Tokens (SBTs) for professional
// identities and skill attestations, a dynamic reputation system, and a DAO for community governance.
// The system incorporates adaptive parameters influenced by external oracles and community consensus
// to ensure relevance and responsiveness.

// I. Core Identity & Skill Management
//    Manages the creation and updates of user's Soulbound Professional Identity NFTs (PINs)
//    and their associated Soulbound Skill Orbs (SBTs) which represent verified skills.
//    Includes functions for peer attestations and validator approvals. PINs are ERC721-compliant,
//    but non-transferable. Skill Orbs are data structures linked to PINs, representing levels.

// II. Reputation System
//    Handles a dynamic, decaying reputation score for each user (associated with their PIN),
//    influenced by successful attestations and contributions. Reputation decays over time
//    if not actively maintained, promoting continuous engagement.

// III. Dynamic Parameters & Oracles
//    Enables the system to adapt its behavior (e.g., attestation weighting, reputation decay rate)
//    based on on-chain activity, external data from authorized oracles (e.g., market demand for skills),
//    or governance decisions, making the system responsive to real-world conditions.

// IV. Governance (DAO)
//    Provides a decentralized autonomous organization (DAO) framework for the community
//    (PIN holders) to propose and vote on key system changes. This includes creating new skill categories,
//    appointing/removing validators, and adjusting system parameters.

// V. Synergy Pool & Rewards
//    Manages a pool of native tokens (ETH/MATIC/etc.) used to incentivize and reward active participants
//    like attestors, validators, and contributors. Funds can be deposited by anyone and are distributed
//    based on DAO-approved rules or internal reward mechanisms.

// VI. Essential Helper / View
//    Contains common utility functions and view functions for querying contract state.

// --- Function Summary ---

// I. Core Identity & Skill Management (7 functions)
// 1.  mintProfessionalIdentityNFT(string calldata _metadataURI): Creates a new Soulbound Professional Identity NFT (PIN) for the caller. Returns the new PIN ID.
// 2.  updateProfessionalIdentityMetadata(uint256 _pinId, string calldata _newMetadataURI): Allows the owner of a PIN to update its associated metadata URI.
// 3.  requestSkillOrbMint(uint256 _pinId, string calldata _skillCategory, string calldata _proofHash): Initiates a request for a new Skill Orb of a specific category for a PIN.
// 4.  attestSkill(uint256 _attesterPinId, uint256 _subjectPinId, string calldata _skillCategory, uint8 _rating, string calldata _attestationProofHash): Allows one PIN holder to attest to another's skill, providing a rating and proof hash.
// 5.  validateSkillOrbRequest(uint256 _requestId, bool _approve): A designated validator reviews a Skill Orb mint request and approves/rejects it based on attestations.
// 6.  upgradeSkillOrbLevel(uint256 _pinId, string calldata _skillCategory, string calldata _newProofHash): Allows a user to submit new proofs to upgrade an existing Skill Orb's level.
// 7.  getSkillOrbsByPIN(uint256 _pinId): Retrieves all Skill Orbs (category and level) associated with a given PIN.

// II. Reputation System (3 functions)
// 8.  getReputationScore(uint256 _pinId): Returns the current dynamic reputation score for a PIN, factoring in decay.
// 9.  _updateReputation(uint256 _pinId, int256 _change): Internal helper function to adjust a PIN's reputation score.
// 10. _applyReputationDecay(uint256 _pinId): Internal helper function to apply reputation decay based on elapsed time since last update.

// III. Dynamic Parameters & Oracles (3 functions)
// 11. setOracleAddress(address _newOracle): Sets the address of an authorized data oracle. Only callable by the DAO (via proposal execution).
// 12. updateSkillDemandFactor(string calldata _skillCategory, uint256 _demandFactor): An authorized oracle reports the demand factor for a specific skill (0-100).
// 13. getSkillDemandFactor(string calldata _skillCategory): Retrieves the current demand factor for a skill.

// IV. Governance (DAO) (8 functions)
// 14. proposeNewSkillCategory(string calldata _categoryName, string calldata _description): Proposes a new Skill Orb category that the community can vote on.
// 15. proposeNewValidator(address _newValidatorAddress, string calldata _metadataURI): Proposes an address to become a recognized validator for skill attestations.
// 16. voteOnProposal(uint256 _proposalId, bool _support): Allows PIN holders to cast their vote on active proposals.
// 17. executeProposal(uint256 _proposalId): Executes a passed proposal if it has passed its voting period and met quorum/majority requirements.
// 18. setVotingPeriod(uint256 _newPeriod): Sets the duration for voting periods in seconds. Callable only by the DAO (via proposal execution).
// 19. setQuorumThreshold(uint256 _newThreshold): Sets the minimum percentage of total voting power required for a proposal to pass (0-100). Callable only by the DAO (via proposal execution).
// 20. getProposalDetails(uint256 _proposalId): Retrieves all details of a specific governance proposal.
// 21. getUserVote(uint256 _proposalId, address _voter): Checks if a specific address has voted on a proposal and their choice.

// V. Synergy Pool & Rewards (3 functions)
// 22. depositIntoSynergyPool(): Allows any user to deposit native tokens (e.g., Ether) into the Synergy Pool.
// 23. rewardParticipant(uint256 _pinId, uint256 _amount): Distributes a specified amount of native tokens from the Synergy Pool to a PIN holder as a reward. Callable by DAO (via proposal execution).
// 24. withdrawSynergyPoolFunds(address _recipient, uint256 _amount): Allows the DAO to withdraw funds from the Synergy Pool to a specified recipient. Callable by DAO (via proposal execution).

// VI. Essential Helper / View (1 function + additional views)
// 25. isValidator(address _addr): Checks if a given address is currently a registered validator.
//     getTotalPINs(): Returns the total number of Professional Identity NFTs minted.
//     getTotalProposals(): Returns the total number of governance proposals.
//     getSynergyPoolBalance(): Returns the current balance of native tokens in the Synergy Pool.
//     getOwnerOfPIN(uint256 _pinId): Returns the address owner of a specific PIN.
//     getPinIdByAddress(address _owner): Returns the PIN ID for a given address.

contract SynergyNet is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeMath for int256;

    // --- State Variables ---

    // PIN (Professional Identity NFT)
    Counters.Counter private _pinIds;
    // Mapping from PIN ID to the owner's address
    mapping(uint256 => address) public pinIdToOwner;
    // Mapping from owner address to their PIN ID (assuming one PIN per address)
    mapping(address => uint256) public ownerToPinId;
    // Mapping from PIN ID to its metadata URI
    mapping(uint256 => string) private _tokenURIs;
    // Mapping from PIN ID to reputation data
    struct ReputationData {
        int256 score;
        uint256 lastUpdateTimestamp;
    }
    mapping(uint256 => ReputationData) public reputationOf;

    // Skill Orbs (SBTs)
    struct SkillOrb {
        string category;
        uint8 level; // 0 for non-existent, 1+ for verified levels
        uint256 lastUpgradeTimestamp;
        string currentProofHash; // Hash of the proof for current level
    }
    // Mapping from PIN ID to a specific skill category to its SkillOrb data
    mapping(uint256 => mapping(string => SkillOrb)) public skillOrbsOfPin;
    // List of active skill categories
    string[] public approvedSkillCategories;
    mapping(string => bool) public isSkillCategoryApproved;

    // Attestations
    struct Attestation {
        uint256 attesterPinId;
        uint256 subjectPinId;
        string skillCategory;
        uint8 rating; // 1-10
        string attestationProofHash; // IPFS hash or similar
        uint256 timestamp;
    }
    Counters.Counter private _attestationIds;
    mapping(uint256 => Attestation) public attestations;
    // To track attestations for a given skill request, or simply for reputation calculation
    mapping(uint256 => mapping(string => uint256[])) public skillAttestationsForPin; // pinId => skillCategory => attestationIds

    // Skill Orb Requests (for new mints or upgrades)
    enum RequestStatus { Pending, Approved, Rejected }
    struct SkillOrbRequest {
        uint256 requestId;
        uint256 pinId;
        string skillCategory;
        string proofHash; // Initial proof for the request
        RequestStatus status;
        address proposer; // The address who requested this
        uint256 creationTimestamp;
    }
    Counters.Counter private _skillOrbRequestIds;
    mapping(uint256 => SkillOrbRequest) public skillOrbRequests;

    // Validators
    mapping(address => bool) public isValidator;
    address[] public activeValidators;

    // Dynamic Parameters & Oracles
    address public trustedOracle;
    mapping(string => uint256) public skillDemandFactors; // 0-100, impacts reputation/rewards
    uint256 public constant REPUTATION_DECAY_PERIOD = 7 days; // How often decay is applied
    uint256 public reputationDecayRate = 10; // Points per decay period (e.g., 10 points per week)

    // DAO Governance
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum ProposalType { NewSkillCategory, NewValidator, RemoveValidator, SetVotingPeriod, SetQuorumThreshold, SetReputationDecayRate, SetOracleAddress, RewardParticipant }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        // hasVoted cannot be stored in a struct within a mapping directly.
        // It's handled by a separate mapping: `mapping(uint256 => mapping(address => bool)) public proposalVoters;`
        ProposalState state;
        bytes callData; // Encoded function call for execution
        address target; // Target contract for execution
        string stringParam; // Generic string parameter for proposals (e.g., skill category name)
        address addressParam; // Generic address parameter for proposals (e.g., validator address)
        uint256 uint256Param; // Generic uint256 parameter for proposals (e.g., voting period)
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVoters; // proposalId => voterAddress => hasVoted

    uint256 public votingPeriod = 7 days; // Default voting period in seconds
    uint256 public quorumThreshold = 50; // Percentage of total voting power needed (0-100)

    // Events
    event PINMinted(uint256 indexed pinId, address indexed owner, string metadataURI);
    event PINMetadataUpdated(uint256 indexed pinId, string newMetadataURI);
    event SkillOrbRequested(uint256 indexed requestId, uint256 indexed pinId, string skillCategory, string proofHash);
    event SkillOrbValidated(uint256 indexed requestId, uint256 indexed pinId, string skillCategory, bool approved, uint8 level);
    event SkillOrbUpgraded(uint256 indexed pinId, string skillCategory, uint8 newLevel, string newProofHash);
    event SkillAttested(uint256 indexed attestationId, uint256 indexed attesterPinId, uint256 indexed subjectPinId, string skillCategory, uint8 rating);
    event ReputationUpdated(uint256 indexed pinId, int256 oldScore, int256 newScore, string reason);
    event OracleAddressSet(address indexed newOracle);
    event SkillDemandFactorUpdated(string indexed skillCategory, uint256 demandFactor);
    event NewSkillCategoryProposed(uint256 indexed proposalId, string categoryName);
    event NewValidatorProposed(uint256 indexed proposalId, address validatorAddress);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ParticipantRewarded(uint256 indexed pinId, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event VotingPeriodSet(uint256 newPeriod);
    event QuorumThresholdSet(uint256 newThreshold);
    event ReputationDecayRateSet(uint256 newRate);


    // --- Constructor ---
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        // Initial setup, owner is the deployer, who can also act as "DAO executor" in this simplified example.
    }

    // --- Modifiers ---
    modifier onlyPINOwner(uint256 _pinId) {
        require(ownerOf(_pinId) == msg.sender, "SynergyNet: Not PIN owner");
        _;
    }

    modifier onlyPINHolder() {
        require(ownerToPinId[msg.sender] != 0, "SynergyNet: Caller must hold a PIN");
        _;
    }

    modifier onlyValidator() {
        require(isValidator[msg.sender], "SynergyNet: Caller is not a validator");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "SynergyNet: Caller is not the trusted oracle");
        _;
    }

    // This modifier simulates the DAO's execution power. In a full DAO, this would typically
    // be `msg.sender == address(this)` for proposals executed by the DAO contract itself.
    // For this example, the `owner()` (deployer) is given this role for simplicity.
    modifier onlyDAOExecutor() {
        require(msg.sender == owner(), "SynergyNet: Not authorized DAO executor");
        _;
    }

    // --- ERC721 Overrides (for Soulbound functionality) ---
    // Make NFTs non-transferable (soulbound)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0)) { // Allow minting, but not transfers from an existing holder
            revert("SynergyNet: PINs are soulbound and cannot be transferred");
        }
    }

    // Disable `approve` for soulbound tokens
    function approve(address to, uint254 tokenId) public pure override {
        revert("SynergyNet: PINs are soulbound and cannot be approved");
    }

    // Disable `setApprovalForAll` for soulbound tokens
    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("SynergyNet: PINs are soulbound and cannot be approved");
    }

    // Disable `transferFrom` for soulbound tokens
    function transferFrom(address from, address to, uint254 tokenId) public pure override {
        revert("SynergyNet: PINs are soulbound and cannot be transferred");
    }

    // Disable `safeTransferFrom` for soulbound tokens
    function safeTransferFrom(address from, address to, uint254 tokenId) public pure override {
        revert("SynergyNet: PINs are soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint254 tokenId, bytes calldata data) public pure override {
        revert("SynergyNet: PINs are soulbound and cannot be transferred");
    }

    // --- I. Core Identity & Skill Management ---

    /// @notice Mints a new Professional Identity NFT (PIN) for the caller. Each address can only have one PIN.
    /// @param _metadataURI The IPFS URI or similar pointing to the PIN's metadata.
    /// @return The ID of the newly minted PIN.
    function mintProfessionalIdentityNFT(string calldata _metadataURI) public returns (uint256) {
        require(ownerToPinId[msg.sender] == 0, "SynergyNet: Address already owns a PIN");

        _pinIds.increment();
        uint256 newPinId = _pinIds.current();

        pinIdToOwner[newPinId] = msg.sender;
        ownerToPinId[msg.sender] = newPinId;
        _safeMint(msg.sender, newPinId);
        _setTokenURI(newPinId, _metadataURI);

        // Initialize reputation for the new PIN
        reputationOf[newPinId] = ReputationData({
            score: 0, // Start with 0 reputation
            lastUpdateTimestamp: block.timestamp
        });

        emit PINMinted(newPinId, msg.sender, _metadataURI);
        return newPinId;
    }

    /// @notice Allows the owner of a PIN to update its associated metadata URI.
    /// @param _pinId The ID of the PIN to update.
    /// @param _newMetadataURI The new IPFS URI or similar for the PIN's metadata.
    function updateProfessionalIdentityMetadata(uint256 _pinId, string calldata _newMetadataURI) public onlyPINOwner(_pinId) {
        require(_exists(_pinId), "SynergyNet: PIN does not exist");
        _setTokenURI(_pinId, _newMetadataURI);
        emit PINMetadataUpdated(_pinId, _newMetadataURI);
    }

    /// @notice Initiates a request for a new Skill Orb or an upgrade for an existing one.
    ///         Requires the skill category to be approved by DAO.
    /// @param _pinId The ID of the PIN requesting the Skill Orb.
    /// @param _skillCategory The category of the skill (e.g., "Solidity Development").
    /// @param _proofHash A hash of off-chain proof (e.g., project link, certificate hash).
    function requestSkillOrbMint(uint256 _pinId, string calldata _skillCategory, string calldata _proofHash) public onlyPINOwner(_pinId) {
        require(_exists(_pinId), "SynergyNet: PIN does not exist");
        require(isSkillCategoryApproved[_skillCategory], "SynergyNet: Skill category not approved by DAO");

        _skillOrbRequestIds.increment();
        uint256 newRequestId = _skillOrbRequestIds.current();

        skillOrbRequests[newRequestId] = SkillOrbRequest({
            requestId: newRequestId,
            pinId: _pinId,
            skillCategory: _skillCategory,
            proofHash: _proofHash,
            status: RequestStatus.Pending,
            proposer: msg.sender,
            creationTimestamp: block.timestamp
        });

        emit SkillOrbRequested(newRequestId, _pinId, _skillCategory, _proofHash);
    }

    /// @notice Allows one PIN holder to attest to another's skill. This contributes to the subject's reputation and skill validation.
    /// @param _attesterPinId The ID of the PIN holder making the attestation.
    /// @param _subjectPinId The ID of the PIN holder whose skill is being attested.
    /// @param _skillCategory The category of the skill being attested.
    /// @param _rating A rating for the skill (1-10, higher is better).
    /// @param _attestationProofHash An off-chain proof hash for the attestation.
    function attestSkill(uint256 _attesterPinId, uint256 _subjectPinId, string calldata _skillCategory, uint8 _rating, string calldata _attestationProofHash) public onlyPINOwner(_attesterPinId) {
        require(_exists(_subjectPinId), "SynergyNet: Subject PIN does not exist");
        require(_attesterPinId != _subjectPinId, "SynergyNet: Cannot attest to your own skill");
        require(isSkillCategoryApproved[_skillCategory], "SynergyNet: Skill category not approved");
        require(_rating > 0 && _rating <= 10, "SynergyNet: Rating must be between 1 and 10");

        // Apply reputation decay to both before processing attestation
        _applyReputationDecay(_attesterPinId);
        _applyReputationDecay(_subjectPinId);

        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();

        attestations[newAttestationId] = Attestation({
            attesterPinId: _attesterPinId,
            subjectPinId: _subjectPinId,
            skillCategory: _skillCategory,
            rating: _rating,
            attestationProofHash: _attestationProofHash,
            timestamp: block.timestamp
        });

        skillAttestationsForPin[_subjectPinId][_skillCategory].push(newAttestationId);

        // Update subject's reputation based on attestation
        // Example: rating * (base + demand factor). Max demand factor 100, so 2x impact.
        int256 reputationBoost = int256(_rating).mul(100 + int256(skillDemandFactors[_skillCategory])).div(100);
        _updateReputation(_subjectPinId, reputationBoost);

        emit SkillAttested(newAttestationId, _attesterPinId, _subjectPinId, _skillCategory, _rating);
    }

    /// @notice A designated validator reviews a Skill Orb mint request and approves/rejects it.
    ///         Upon approval, a Skill Orb is minted or upgraded for the PIN.
    /// @param _requestId The ID of the Skill Orb request.
    /// @param _approve True to approve, false to reject.
    function validateSkillOrbRequest(uint256 _requestId, bool _approve) public onlyValidator {
        SkillOrbRequest storage req = skillOrbRequests[_requestId];
        require(req.requestId != 0 && req.status == RequestStatus.Pending, "SynergyNet: Request not pending or does not exist");
        require(_exists(req.pinId), "SynergyNet: Target PIN does not exist");

        // Logic to determine if enough attestations exist for approval (simplified for now)
        // A real system would have a more complex logic, e.g., average rating, min attestations.
        // For this example, a validator simply makes a decision.

        if (_approve) {
            req.status = RequestStatus.Approved;
            SkillOrb storage existingOrb = skillOrbsOfPin[req.pinId][req.skillCategory];

            // If it's a new skill orb, level 1, otherwise increment level
            uint8 newLevel = (existingOrb.level == 0) ? 1 : existingOrb.level.add(1);
            
            existingOrb.category = req.skillCategory;
            existingOrb.level = newLevel;
            existingOrb.lastUpgradeTimestamp = block.timestamp;
            existingOrb.currentProofHash = req.proofHash; // Use the proof from the request

            // Grant reputation boost for successfully validated skill
            _updateReputation(req.pinId, 50); // Significant boost for new skill/level

            emit SkillOrbValidated(_requestId, req.pinId, req.skillCategory, true, newLevel);
        } else {
            req.status = RequestStatus.Rejected;
            // Optionally, penalize reputation for rejection
            _updateReputation(req.pinId, -10);
            emit SkillOrbValidated(_requestId, req.pinId, req.skillCategory, false, 0);
        }
        // Reward validator for their work (simplified to fixed amount)
        // In a real system, this would be based on complexity, number of attestations, etc.
        // This is a direct call for simplicity, but could also be a DAO-approved action.
        if (address(this).balance >= 1 ether / 50) { // Check if pool has funds
            _rewardParticipant(ownerToPinId[msg.sender], 1 ether / 50);
        }
    }

    /// @notice Allows a user to submit new proofs to upgrade an existing Skill Orb's level.
    ///         This initiates a new request that needs validator approval.
    /// @param _pinId The ID of the PIN to upgrade.
    /// @param _skillCategory The category of the skill to upgrade.
    /// @param _newProofHash A hash of the new off-chain proof for the upgrade.
    function upgradeSkillOrbLevel(uint256 _pinId, string calldata _skillCategory, string calldata _newProofHash) public onlyPINOwner(_pinId) {
        require(_exists(_pinId), "SynergyNet: PIN does not exist");
        require(skillOrbsOfPin[_pinId][_skillCategory].level > 0, "SynergyNet: Skill Orb does not exist for this PIN, cannot upgrade");

        // Initiate a new request, similar to minting a new orb. The validator will see the existing level
        // and decide to increment it upon approval.
        requestSkillOrbMint(_pinId, _skillCategory, _newProofHash);
    }

    /// @notice Retrieves all Skill Orbs (category and level) associated with a given PIN.
    /// @param _pinId The ID of the PIN.
    /// @return An array of SkillOrb structs.
    function getSkillOrbsByPIN(uint256 _pinId) public view returns (SkillOrb[] memory) {
        require(_exists(_pinId), "SynergyNet: PIN does not exist");
        SkillOrb[] memory userSkillOrbs = new SkillOrb[](approvedSkillCategories.length);
        uint256 count = 0;
        for (uint256 i = 0; i < approvedSkillCategories.length; i++) {
            string memory category = approvedSkillCategories[i];
            if (skillOrbsOfPin[_pinId][category].level > 0) {
                userSkillOrbs[count] = skillOrbsOfPin[_pinId][category];
                count++;
            }
        }
        // Resize array to actual count for gas efficiency when returning
        SkillOrb[] memory result = new SkillOrb[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userSkillOrbs[i];
        }
        return result;
    }


    // --- II. Reputation System ---

    /// @notice Returns the current dynamic reputation score for a PIN, factoring in decay.
    /// @param _pinId The ID of the PIN.
    /// @return The current reputation score.
    function getReputationScore(uint256 _pinId) public view returns (int256) {
        require(_exists(_pinId), "SynergyNet: PIN does not exist");
        ReputationData memory rep = reputationOf[_pinId];

        uint256 timeElapsed = block.timestamp.sub(rep.lastUpdateTimestamp);
        uint256 decayPeriods = timeElapsed.div(REPUTATION_DECAY_PERIOD);

        int256 currentScore = rep.score.sub(int256(decayPeriods.mul(reputationDecayRate)));
        return currentScore > 0 ? currentScore : 0; // Reputation cannot go below 0
    }

    /// @notice Internal helper function to adjust a PIN's reputation score.
    /// @param _pinId The ID of the PIN.
    /// @param _change The amount to change the reputation by (can be negative).
    function _updateReputation(uint256 _pinId, int256 _change) internal {
        require(_exists(_pinId), "SynergyNet: PIN does not exist");

        // Apply decay first
        _applyReputationDecay(_pinId);

        ReputationData storage rep = reputationOf[_pinId];
        int256 oldScore = rep.score;
        int256 newScore = rep.score.add(_change);
        
        rep.score = newScore > 0 ? newScore : 0; // Reputation cannot go below 0
        rep.lastUpdateTimestamp = block.timestamp; // Update timestamp only when score changes
        emit ReputationUpdated(_pinId, oldScore, rep.score, ""); // Empty reason for internal calls
    }

    /// @notice Internal helper function to apply reputation decay based on elapsed time since last update.
    ///         This function is called before any reputation-altering action.
    /// @param _pinId The ID of the PIN.
    function _applyReputationDecay(uint256 _pinId) internal {
        require(_exists(_pinId), "SynergyNet: PIN does not exist");
        ReputationData storage rep = reputationOf[_pinId];

        uint256 timeElapsed = block.timestamp.sub(rep.lastUpdateTimestamp);
        uint256 decayPeriods = timeElapsed.div(REPUTATION_DECAY_PERIOD);

        if (decayPeriods > 0) {
            int256 oldScore = rep.score;
            int256 decayAmount = int256(decayPeriods.mul(reputationDecayRate));
            rep.score = rep.score.sub(decayAmount);
            rep.score = rep.score > 0 ? rep.score : 0; // Ensure score doesn't go below zero
            rep.lastUpdateTimestamp = block.timestamp;
            emit ReputationUpdated(_pinId, oldScore, rep.score, "Decay");
        }
    }


    // --- III. Dynamic Parameters & Oracles ---

    /// @notice Sets the address of an authorized data oracle. Only callable by the DAO.
    /// @param _newOracle The address of the new oracle.
    function setOracleAddress(address _newOracle) public onlyDAOExecutor {
        require(_newOracle != address(0), "SynergyNet: Oracle address cannot be zero");
        trustedOracle = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    /// @notice An authorized oracle reports the demand factor for a specific skill.
    ///         This demand factor (0-100) can influence reputation, rewards, etc.
    /// @param _skillCategory The skill category for which to update demand.
    /// @param _demandFactor The new demand factor (0-100).
    function updateSkillDemandFactor(string calldata _skillCategory, uint256 _demandFactor) public onlyOracle {
        require(isSkillCategoryApproved[_skillCategory], "SynergyNet: Skill category not approved");
        require(_demandFactor <= 100, "SynergyNet: Demand factor cannot exceed 100");
        skillDemandFactors[_skillCategory] = _demandFactor;
        emit SkillDemandFactorUpdated(_skillCategory, _demandFactor);
    }

    /// @notice Retrieves the current demand factor for a skill.
    /// @param _skillCategory The skill category to query.
    /// @return The demand factor (0-100).
    function getSkillDemandFactor(string calldata _skillCategory) public view returns (uint256) {
        return skillDemandFactors[_skillCategory];
    }


    // --- IV. Governance (DAO) ---

    /// @notice Proposes a new Skill Orb category that the community can vote on.
    /// @param _categoryName The name of the new skill category.
    /// @param _description A description of the skill category.
    /// @return The ID of the newly created proposal.
    function proposeNewSkillCategory(string calldata _categoryName, string calldata _description) public onlyPINHolder returns (uint256) {
        require(!isSkillCategoryApproved[_categoryName], "SynergyNet: Skill category already exists or is approved");
        // Check if there's an active proposal for this category
        for(uint i = 1; i <= _proposalIds.current(); i++) {
            Proposal storage p = proposals[i];
            if (p.proposalType == ProposalType.NewSkillCategory &&
                keccak256(abi.encodePacked(p.stringParam)) == keccak256(abi.encodePacked(_categoryName)) &&
                (p.state == ProposalState.Active || p.state == ProposalState.Pending)) {
                revert("SynergyNet: Proposal for this skill category already active or pending.");
            }
        }

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        bytes memory callData = abi.encodeWithSelector(
            this.executeAddSkillCategory.selector,
            _categoryName
        );

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.NewSkillCategory,
            proposer: msg.sender,
            description: string(abi.encodePacked("Propose new skill category: ", _categoryName, " - ", _description)),
            startBlock: block.number,
            endBlock: block.number + (votingPeriod.div(12)), // Assuming ~12 seconds per block
            forVotes: 0,
            againstVotes: 0,
            state: ProposalState.Active,
            callData: callData,
            target: address(this),
            stringParam: _categoryName,
            addressParam: address(0),
            uint256Param: 0
        });
        emit NewSkillCategoryProposed(proposalId, _categoryName);
        return proposalId;
    }

    /// @notice Internal function to add a skill category, callable only by `executeProposal`.
    function executeAddSkillCategory(string calldata _categoryName) internal onlyDAOExecutor {
        require(!isSkillCategoryApproved[_categoryName], "SynergyNet: Skill category already approved");
        approvedSkillCategories.push(_categoryName);
        isSkillCategoryApproved[_categoryName] = true;
    }

    /// @notice Proposes an address to become a recognized validator for skill attestations.
    /// @param _newValidatorAddress The address to propose as a new validator.
    /// @param _metadataURI Metadata for the validator's profile.
    /// @return The ID of the newly created proposal.
    function proposeNewValidator(address _newValidatorAddress, string calldata _metadataURI) public onlyPINHolder returns (uint256) {
        require(_newValidatorAddress != address(0), "SynergyNet: Validator address cannot be zero");
        require(!isValidator[_newValidatorAddress], "SynergyNet: Address is already a validator");
        // Check if there's an active proposal for this validator
        for(uint i = 1; i <= _proposalIds.current(); i++) {
            Proposal storage p = proposals[i];
            if (p.proposalType == ProposalType.NewValidator &&
                p.addressParam == _newValidatorAddress &&
                (p.state == ProposalState.Active || p.state == ProposalState.Pending)) {
                revert("SynergyNet: Proposal for this validator already active or pending.");
            }
        }

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        bytes memory callData = abi.encodeWithSelector(
            this.executeAddValidator.selector,
            _newValidatorAddress
        );

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.NewValidator,
            proposer: msg.sender,
            description: string(abi.encodePacked("Propose new validator: ", _metadataURI)),
            startBlock: block.number,
            endBlock: block.number + (votingPeriod.div(12)),
            forVotes: 0,
            againstVotes: 0,
            state: ProposalState.Active,
            callData: callData,
            target: address(this),
            stringParam: _metadataURI,
            addressParam: _newValidatorAddress,
            uint256Param: 0
        });
        emit NewValidatorProposed(proposalId, _newValidatorAddress);
        return proposalId;
    }

    /// @notice Internal function to add a validator, callable only by `executeProposal`.
    function executeAddValidator(address _validatorAddress) internal onlyDAOExecutor {
        require(!isValidator[_validatorAddress], "SynergyNet: Address is already a validator");
        isValidator[_validatorAddress] = true;
        activeValidators.push(_validatorAddress);
    }

    /// @notice Allows PIN holders to cast their vote on active proposals.
    ///         Each PIN counts as one vote.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyPINHolder {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "SynergyNet: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "SynergyNet: Proposal not active");
        require(block.number <= proposal.endBlock, "SynergyNet: Voting period has ended");
        require(!proposalVoters[_proposalId][msg.sender], "SynergyNet: Already voted on this proposal");

        proposalVoters[_proposalId][msg.sender] = true;
        if (_support) {
            proposal.forVotes = proposal.forVotes.add(1); // 1 PIN = 1 vote
        } else {
            proposal.againstVotes = proposal.againstVotes.add(1); // 1 PIN = 1 vote
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed proposal if it has passed its voting period and met quorum/majority requirements.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "SynergyNet: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "SynergyNet: Proposal not active");
        require(block.number > proposal.endBlock, "SynergyNet: Voting period not ended");

        uint256 totalPINs = _pinIds.current(); // Total supply of PINs is total voting power
        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);

        // Check Quorum
        require(totalPINs > 0, "SynergyNet: No PINs minted, no voting power"); // Avoid div by zero
        require(totalVotes.mul(100) >= totalPINs.mul(quorumThreshold), "SynergyNet: Quorum not met");

        // Check Majority
        if (proposal.forVotes > proposal.againstVotes) {
            // Proposal passed
            proposal.state = ProposalState.Succeeded;

            // Execute the specific action based on proposal type
            (bool success, ) = proposal.target.call(proposal.callData);
            require(success, "SynergyNet: Proposal execution failed");

            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal failed
            proposal.state = ProposalState.Failed;
        }
    }

    /// @notice Sets the duration for voting periods in seconds. Callable only by the DAO.
    /// @param _newPeriod The new voting period in seconds.
    function setVotingPeriod(uint256 _newPeriod) public onlyDAOExecutor {
        require(_newPeriod > 0, "SynergyNet: Voting period must be greater than zero");
        votingPeriod = _newPeriod;
        emit VotingPeriodSet(_newPeriod);
    }

    /// @notice Sets the minimum percentage of total voting power required for a proposal to pass (0-100). Callable only by the DAO.
    /// @param _newThreshold The new quorum threshold percentage.
    function setQuorumThreshold(uint256 _newThreshold) public onlyDAOExecutor {
        require(_newThreshold <= 100, "SynergyNet: Quorum threshold cannot exceed 100%");
        quorumThreshold = _newThreshold;
        emit QuorumThresholdSet(_newThreshold);
    }

    /// @notice Sets the reputation decay rate. Callable only by the DAO.
    /// @param _newRate The new reputation decay rate (points per decay period).
    function setReputationDecayRate(uint256 _newRate) public onlyDAOExecutor {
        reputationDecayRate = _newRate;
        emit ReputationDecayRateSet(_newRate);
    }

    /// @notice Retrieves all details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A tuple containing all proposal details.
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id,
        ProposalType proposalType,
        address proposer,
        string memory description,
        uint256 startBlock,
        uint256 endBlock,
        uint256 forVotes,
        uint256 againstVotes,
        ProposalState state,
        bytes memory callData,
        address target,
        string memory stringParam,
        address addressParam,
        uint256 uint256Param
    ) {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "SynergyNet: Proposal does not exist");
        return (
            p.id,
            p.proposalType,
            p.proposer,
            p.description,
            p.startBlock,
            p.endBlock,
            p.forVotes,
            p.againstVotes,
            p.state,
            p.callData,
            p.target,
            p.stringParam,
            p.addressParam,
            p.uint256Param
        );
    }

    /// @notice Checks if a specific address has voted on a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _voter The address of the voter.
    /// @return True if voted, false otherwise.
    function getUserVote(uint256 _proposalId, address _voter) public view returns (bool) {
        return proposalVoters[_proposalId][_voter];
    }


    // --- V. Synergy Pool & Rewards ---

    /// @notice Allows any user to deposit native tokens (e.g., Ether) into the Synergy Pool.
    function depositIntoSynergyPool() public payable {
        require(msg.value > 0, "SynergyNet: Deposit amount must be greater than zero");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Distributes a specified amount of native tokens from the Synergy Pool to a PIN holder as a reward.
    ///         Callable by DAO (via proposal execution).
    /// @param _pinId The ID of the PIN holder to reward.
    /// @param _amount The amount of native tokens to reward.
    function rewardParticipant(uint256 _pinId, uint256 _amount) public onlyDAOExecutor {
        require(_exists(_pinId), "SynergyNet: PIN does not exist");
        require(_amount > 0, "SynergyNet: Reward amount must be greater than zero");
        require(address(this).balance >= _amount, "SynergyNet: Insufficient funds in Synergy Pool");

        address recipient = pinIdToOwner[_pinId];
        (bool success, ) = recipient.call{value: _amount}("");
        require(success, "SynergyNet: Failed to send reward");

        // Apply a reputation boost for receiving a reward
        // Example: 10 reputation per 1 ETH rewarded, scaled
        _updateReputation(_pinId, int256(_amount.mul(10).div(1 ether)));

        emit ParticipantRewarded(_pinId, _amount);
    }

    /// @notice Allows the DAO to withdraw funds from the Synergy Pool to a specified recipient.
    ///         This would typically be for operational costs, grant funding, etc., approved via governance.
    /// @param _recipient The address to send the funds to.
    /// @param _amount The amount of native tokens to withdraw.
    function withdrawSynergyPoolFunds(address _recipient, uint256 _amount) public onlyDAOExecutor {
        require(_recipient != address(0), "SynergyNet: Recipient address cannot be zero");
        require(_amount > 0, "SynergyNet: Withdrawal amount must be greater than zero");
        require(address(this).balance >= _amount, "SynergyNet: Insufficient funds in Synergy Pool");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "SynergyNet: Failed to withdraw funds");

        emit FundsWithdrawn(_recipient, _amount);
    }


    // --- VI. Essential Helper / View ---

    /// @notice Checks if a given address is currently a registered validator.
    /// @param _addr The address to check.
    /// @return True if the address is a validator, false otherwise.
    function isValidator(address _addr) public view returns (bool) {
        return isValidator[_addr];
    }

    /// @notice Returns the total number of PINs minted.
    function getTotalPINs() public view returns (uint256) {
        return _pinIds.current();
    }

    /// @notice Returns the total number of proposals.
    function getTotalProposals() public view returns (uint256) {
        return _proposalIds.current();
    }

    /// @notice Returns the current balance of the Synergy Pool.
    function getSynergyPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the owner of a PIN.
    function getOwnerOfPIN(uint256 _pinId) public view returns (address) {
        require(_exists(_pinId), "SynergyNet: PIN does not exist");
        return ownerOf(_pinId);
    }

    /// @notice Returns the PIN ID for a given address.
    function getPinIdByAddress(address _owner) public view returns (uint256) {
        return ownerToPinId[_owner];
    }
}
```