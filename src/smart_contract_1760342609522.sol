This smart contract, named "Chrysalis," is designed as an adaptive reputation and resource allocation protocol. It aims to foster a dynamic digital commons where users earn non-transferable reputation by contributing verifiable attestations. This reputation then influences their ability to participate in governance (proposing and voting on adaptive protocol parameters) and claim resources from dynamically configured pools. The protocol's rules and resource allocation formulas can evolve over time through collective decision-making, adapting to the community's needs and observed behavior.

**Key Advanced Concepts & Uniqueness:**

1.  **Adaptive Rules Engine:** Core protocol parameters (like reputation rewards, challenge bonds, reputation decay rates) are not static but can be proposed and updated through a reputation-weighted governance mechanism. This allows the protocol to dynamically adjust its economic incentives and security measures.
2.  **Lazy Reputation Decay:** User reputation naturally decays over time (per epoch), encouraging continuous engagement. The decay is calculated on-the-fly when a user's reputation is queried or involved in a transaction, optimizing gas costs by avoiding global iterations.
3.  **Dynamic Resource Pools:** The contract supports multiple resource pools, each capable of holding different assets (e.g., ETH, ERC20 tokens). Crucially, each pool can have its own "adaptive allocation formula" (e.g., linear, quadratic, inverse reputation weighting) that determines how resources are distributed. These formulas can also be updated via governance.
4.  **Verifiable Attestations & Challenges:** A mechanism for users to submit claims (attestations) that, once verified by a trusted oracle, contribute to their reputation. A challenge system is included, allowing stakeholders to dispute attestations, with penalties for false claims or malicious challenges.
5.  **Soul-Bound Stakeholder Badges (NFTs):** Users can mint non-transferable NFT badges that visually represent their reputation tier. These badges are "upgradable" or have dynamic metadata that reflects their current reputation, acting as a visible proof of their standing within the Chrysalis ecosystem.

---

**Outline:**

*   **I. Core Infrastructure & Access**
    *   Initialization, administrative functions, pausing.
*   **II. Reputation System (Soul-Bound)**
    *   Submission, verification, and challenge of attestations, reputation queries, and internal management.
*   **III. Adaptive Parameters & Governance**
    *   Proposals, voting, execution of parameter changes, epoch management.
*   **IV. Dynamic Resource Pools**
    *   Creation, contribution, and adaptive claiming from resource pools.
*   **V. NFT Integration (Stakeholder Badges)**
    *   Tier management, minting, and "upgrading" of non-transferable reputation NFTs.
*   **VI. Utility & Administrative**
    *   Owner withdrawal functions for various assets.

---

**Function Summary (26 functions):**

1.  `constructor(address _attestationVerifier, address _stakeholderBadgeNFT)`: Initializes the contract, setting the attestation verifier, stakeholder badge NFT contract address, and initial epoch configurations.
2.  `setAttestationVerifier(address _newVerifier)`: Allows the owner to update the address of the trusted attestation verifier.
3.  `updateEpochDuration(uint256 _newDuration)`: Allows the owner to change the duration of each epoch.
4.  `pause()` (from Pausable): Allows the owner to pause all sensitive contract operations in emergencies.
5.  `unpause()` (from Pausable): Allows the owner to unpause the contract after a pause.
6.  `submitAttestation(bytes32 _dataHash, string memory _metadataURI)`: Users submit a claim or data for verification, increasing potential reputation.
7.  `verifyAttestation(uint256 _attestationId)`: Called by the designated `attestationVerifier` to confirm a submitted attestation, awarding reputation to the submitter.
8.  `getReputation(address _user)`: Retrieves the current *effective* (lazily decayed) reputation score for a given user.
9.  `challengeAttestation(uint256 _attestationId)`: Allows a stakeholder to challenge a submitted attestation by depositing a bond, initiating a dispute.
10. `resolveAttestationChallenge(uint256 _attestationId, bool _isAttestationValid, address _challenger)`: Owner/governance resolves a challenge, penalizing the submitter or challenger based on validity.
11. `proposeParameterChange(string memory _paramName, uint256 _newValue)`: Stakeholders can propose changes to core protocol parameters (e.g., reputation reward factor, challenge bond).
12. `voteOnParameterChange(uint256 _proposalId, bool _support)`: Users vote on active parameter change proposals, with their effective reputation weighted into their vote.
13. `executeParameterChange(uint256 _proposalId)`: Executes a passed parameter change proposal, updating the protocol's adaptive rules.
14. `getEpochConfig()`: Retrieves the current epoch's configuration parameters.
15. `advanceEpoch()`: Advances the protocol to the next epoch, signifying a new period and triggering time-based logic (like decay calculation on-demand).
16. `createAdaptivePool(string memory _name, address _asset, uint256 _initialAllocationFactor, AllocationFormulaType _formulaType)`: Owner/governance creates new resource pools with specified assets and adaptive allocation formulas.
17. `contributeToPool(uint256 _poolId)`: Users can contribute ETH (or ERC20 tokens in a more advanced version) to a designated adaptive resource pool.
18. `claimFromPool(uint256 _poolId)`: Stakeholders can claim resources from a pool, with the amount determined by their effective reputation and the pool's adaptive allocation formula.
19. `updatePoolAllocationFormula(uint256 _poolId, AllocationFormulaType _newFormulaType)`: Owner/governance can update the allocation formula for an existing resource pool.
20. `getPoolAllocationPreview(uint256 _poolId, address _user)`: Allows a user to see an estimate of how much they would receive from a pool based on current rules and their reputation.
21. `initializeStakeholderTiers(uint256[] memory _minReputations, string[] memory _names)`: Owner sets up the reputation thresholds and names for different stakeholder badge tiers.
22. `getStakeholderTier(uint256 _reputation)`: Returns the stakeholder tier ID and name for a given reputation score.
23. `mintStakeholderBadge()`: Allows an eligible user to mint a non-transferable NFT badge representing their stakeholder tier.
24. `upgradeStakeholderBadge()`: Notifies the system to update a user's existing stakeholder badge (e.g., by triggering metadata refresh) to reflect their current, potentially higher, reputation tier.
25. `withdrawEth(address payable _to, uint256 _amount)`: Allows the owner to withdraw accumulated ETH (e.g., forfeited challenge bonds) from the contract.
26. `withdrawERC20(address _token, address _to, uint256 _amount)`: Allows the owner to withdraw accumulated ERC20 tokens from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For stakeholder badges
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For multi-asset pools

// Custom interface for the Stakeholder Badge NFT contract.
// Assumes the NFT contract has specific minting/tier functions or dynamically generates metadata.
interface IStakeholderBadge {
    function mintBadge(address recipient, uint256 tier) external returns (uint256 tokenId);
    function getTier(uint256 tokenId) external view returns (uint256);
    // An `updateBadgeTier` function could be added if the NFT contract physically stores and updates tier data.
    // For this example, we assume dynamic metadata that reads from Chrysalis, or the tier is passed to a mint function.
}

// Outline:
// I. Core Infrastructure & Access
// II. Reputation System (Soul-Bound)
// III. Adaptive Parameters & Governance
// IV. Dynamic Resource Pools
// V. NFT Integration (Stakeholder Badges)
// VI. Utility & Administrative

// Function Summary:
// 1.  constructor(address _attestationVerifier, address _stakeholderBadgeNFT): Initializes the contract, setting the attestation verifier, stakeholder badge NFT contract address, and initial epoch configurations.
// 2.  setAttestationVerifier(address _newVerifier): Allows the owner to update the address of the trusted attestation verifier.
// 3.  updateEpochDuration(uint256 _newDuration): Allows the owner to change the duration of each epoch.
// 4.  pause() (from Pausable): Allows the owner to pause all sensitive contract operations in emergencies.
// 5.  unpause() (from Pausable): Allows the owner to unpause the contract after a pause.
// 6.  submitAttestation(bytes32 _dataHash, string memory _metadataURI): Users submit a claim or data for verification, increasing potential reputation.
// 7.  verifyAttestation(uint256 _attestationId): Called by the designated `attestationVerifier` to confirm a submitted attestation, awarding reputation to the submitter.
// 8.  getReputation(address _user): Retrieves the current effective (lazily decayed) reputation score for a given user.
// 9.  challengeAttestation(uint256 _attestationId): Allows a stakeholder to challenge a submitted attestation by depositing a bond, initiating a dispute.
// 10. resolveAttestationChallenge(uint256 _attestationId, bool _isAttestationValid, address _challenger): Owner/governance resolves a challenge, penalizing the submitter or challenger based on validity.
// 11. proposeParameterChange(string memory _paramName, uint256 _newValue): Stakeholders can propose changes to core protocol parameters (e.g., reputation reward factor, challenge bond).
// 12. voteOnParameterChange(uint256 _proposalId, bool _support): Users vote on active parameter change proposals, with their effective reputation weighted into their vote.
// 13. executeParameterChange(uint256 _proposalId): Executes a passed parameter change proposal, updating the protocol's adaptive rules.
// 14. getEpochConfig(): Retrieves the current epoch's configuration parameters.
// 15. advanceEpoch(): Advances the protocol to the next epoch, signifying a new period.
// 16. createAdaptivePool(string memory _name, address _asset, uint256 _initialAllocationFactor, AllocationFormulaType _formulaType): Owner/governance creates new resource pools with specified assets and adaptive allocation formulas.
// 17. contributeToPool(uint256 _poolId): Users can contribute ETH (or ERC20 tokens) to a designated adaptive resource pool.
// 18. claimFromPool(uint256 _poolId): Stakeholders can claim resources from a pool, with the amount determined by their effective reputation and the pool's adaptive allocation formula.
// 19. updatePoolAllocationFormula(uint256 _poolId, AllocationFormulaType _newFormulaType): Owner/governance can update the allocation formula for an existing resource pool.
// 20. getPoolAllocationPreview(uint256 _poolId, address _user): Allows a user to see an estimate of how much they would receive from a pool based on current rules and their reputation.
// 21. initializeStakeholderTiers(uint256[] memory _minReputations, string[] memory _names): Owner sets up the reputation thresholds and names for different stakeholder badge tiers.
// 22. getStakeholderTier(uint256 _reputation): Returns the stakeholder tier ID and name for a given reputation score.
// 23. mintStakeholderBadge(): Allows an eligible user to mint a non-transferable NFT badge representing their stakeholder tier.
// 24. upgradeStakeholderBadge(): Notifies the system to update a user's existing stakeholder badge (e.g., by triggering metadata refresh) to reflect their current, potentially higher, reputation tier.
// 25. withdrawEth(address payable _to, uint256 _amount): Allows the owner to withdraw accumulated ETH (e.g., forfeited challenge bonds) from the contract.
// 26. withdrawERC20(address _token, address _to, uint256 _amount): Allows the owner to withdraw accumulated ERC20 tokens from the contract.

contract Chrysalis is Ownable, Pausable {

    // --- Data Structures ---

    struct Attestation {
        uint256 id;
        address submitter;
        bytes32 dataHash; // A hash of the attested data (e.g., IPFS CID, content hash)
        string metadataURI; // URI pointing to attestation details, proofs, etc.
        uint256 timestamp;
        bool isVerified;
        uint256 challenges; // Number of active challenges (simplified, a real system would track challengers)
        bool hasPenalty;    // True if attestation was found false and submitter penalized
    }

    // Enum for different allocation formulas, representing adaptive behavior
    enum AllocationFormulaType {
        Linear,     // Allocation scales linearly with reputation
        Quadratic,  // Allocation scales quadratically with reputation (amplified effect)
        Inverse     // Allocation inversely scales with reputation (rewards lower reputation)
    }

    struct PoolConfig {
        uint256 id;
        string name;
        address asset; // Address of the ERC20 token, or address(0) for ETH
        uint256 totalContributions; // Total amount contributed to this pool (in wei or token units)
        uint256 initialAllocationFactor; // A base factor used in allocation calculations (scaled, e.g., 10^18)
        AllocationFormulaType allocationFormulaType; // The adaptive formula type
        bool isActive;
    }

    struct ParameterProposal {
        uint256 id;
        address proposer;
        string paramName;
        uint256 newValue;
        uint256 expiration; // Timestamp when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        bool isExecuted;
        mapping(address => bool) votedUsers; // Tracks who has voted to prevent double voting
    }

    struct EpochConfig {
        uint256 reputationRewardFactor;       // Reputation points awarded per verified attestation
        uint256 minReputationForProposal;     // Minimum reputation required to propose a parameter change
        uint256 attestationChallengeBond;     // ETH amount required to challenge an attestation
        uint256 reputationDecayRate;          // Percentage (scaled by 100 for 1%) of reputation decayed per epoch (e.g., 100 = 1%)
        uint256 minReputationToClaim;         // Minimum reputation to claim from pools
    }

    struct StakeholderTier {
        uint256 minReputation;
        string name;
    }

    // --- State Variables ---
    mapping(address => uint256) public reputationScores; // Stores the 'raw' or last effective reputation base
    mapping(address => uint256) private _lastReputationUpdateEpoch; // Tracks the epoch when reputationScores was last updated
    uint256 public totalProtocolReputation; // Aggregate reputation in the system (sum of raw scores)

    address public attestationVerifier; // Trusted oracle/contract for verifying attestations

    mapping(uint256 => Attestation) public attestations;
    uint256 public nextAttestationId;

    mapping(uint256 => PoolConfig) public adaptivePools;
    uint256 public nextPoolId;

    mapping(uint256 => ParameterProposal) public parameterProposals;
    uint256 public nextProposalId;

    EpochConfig public currentEpochConfig;
    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration of each epoch in seconds

    IERC721 public stakeholderBadgeNFT; // Reference to the ERC721 contract for badges
    mapping(address => uint256) public userBadgeTokenId; // Tracks the tokenId owned by a user
    StakeholderTier[] public stakeholderTiers;

    // --- Events ---
    event AttestationSubmitted(uint256 indexed attestationId, address indexed submitter, bytes32 dataHash);
    event AttestationVerified(uint256 indexed attestationId, address indexed verifier, address indexed submitter, uint256 reputationAwarded);
    event AttestationChallenged(uint256 indexed attestationId, address indexed challenger);
    event AttestationChallengeResolved(uint256 indexed attestationId, bool success, address indexed penalizedUser, uint256 penaltyAmount);
    event ReputationBurned(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationAdded(address indexed user, uint256 amount, uint256 newReputation);
    event ParameterProposalCreated(uint256 indexed proposalId, address indexed proposer, string paramName, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ParameterChangeExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);
    event PoolCreated(uint256 indexed poolId, string name, address indexed asset, uint256 initialAllocationFactor, AllocationFormulaType formulaType);
    event ContributedToPool(uint256 indexed poolId, address indexed contributor, address asset, uint256 amount);
    event ClaimedFromPool(uint256 indexed poolId, address indexed claimant, address asset, uint256 amount);
    event PoolAllocationFormulaUpdated(uint256 indexed poolId, AllocationFormulaType newAllocationFormulaType);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event StakeholderBadgeMinted(address indexed recipient, uint256 indexed tokenId, uint256 reputationSnapshot, uint256 tier);
    event StakeholderBadgeUpgraded(address indexed recipient, uint256 indexed tokenId, uint256 newTier, uint256 reputationSnapshot);

    // --- Modifiers ---
    modifier onlyAttestationVerifier() {
        require(msg.sender == attestationVerifier, "Not attestation verifier");
        _;
    }

    modifier onlyStakeholder(uint256 minReputation) {
        require(getReputation(msg.sender) >= minReputation, "Insufficient reputation");
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the contract with an attestation verifier and an optional stakeholder badge NFT contract.
    /// @param _attestationVerifier The address of the trusted entity that verifies attestations.
    /// @param _stakeholderBadgeNFT The address of the ERC721 contract for stakeholder badges (can be address(0) if not used).
    constructor(address _attestationVerifier, address _stakeholderBadgeNFT) Ownable(msg.sender) {
        require(_attestationVerifier != address(0), "Invalid attestation verifier address");
        attestationVerifier = _attestationVerifier;

        if (_stakeholderBadgeNFT != address(0)) {
            stakeholderBadgeNFT = IERC721(_stakeholderBadgeNFT);
        }

        currentEpochConfig = EpochConfig({
            reputationRewardFactor: 100, // Initial reputation points per verified attestation
            minReputationForProposal: 1000,
            attestationChallengeBond: 0.1 ether, // Example bond for challenging an attestation
            reputationDecayRate: 100, // 100 means 1% decay per epoch (100 / 10000 = 0.01)
            minReputationToClaim: 500
        });
        currentEpoch = 0;
        epochDuration = 30 days; // Example: 30 days per epoch
        nextAttestationId = 1;
        nextPoolId = 1;
        nextProposalId = 1;
    }

    // I. Core Infrastructure & Access

    /// @notice Allows the protocol owner to update the address of the trusted attestation verifier.
    /// @param _newVerifier The new address for the attestation verifier.
    function setAttestationVerifier(address _newVerifier) public onlyOwner {
        require(_newVerifier != address(0), "Invalid address");
        attestationVerifier = _newVerifier;
    }

    /// @notice Allows the protocol owner to change the duration of each epoch.
    /// @param _newDuration The new duration for epochs in seconds.
    function updateEpochDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "Duration must be positive");
        epochDuration = _newDuration;
    }

    // OpenZeppelin's Pausable provides `pause()` and `unpause()`.

    // II. Reputation System (Soul-Bound)

    /// @notice Users submit a claim or data for verification, potentially earning reputation.
    /// @param _dataHash A hash of the attested data (e.g., IPFS CID, content hash).
    /// @param _metadataURI URI pointing to attestation details, proofs, etc.
    /// @return attestationId The ID of the newly submitted attestation.
    function submitAttestation(bytes32 _dataHash, string memory _metadataURI) public whenNotPaused returns (uint256) {
        require(_dataHash != bytes32(0), "Empty data hash");
        // Add anti-spam or rate-limiting here if needed
        uint256 attestationId = nextAttestationId++;
        attestations[attestationId] = Attestation({
            id: attestationId,
            submitter: msg.sender,
            dataHash: _dataHash,
            metadataURI: _metadataURI,
            timestamp: block.timestamp,
            isVerified: false,
            challenges: 0,
            hasPenalty: false
        });
        emit AttestationSubmitted(attestationId, msg.sender, _dataHash);
        return attestationId;
    }

    /// @notice Called by the designated `attestationVerifier` to confirm a submitted attestation, awarding reputation to the submitter.
    /// @param _attestationId The ID of the attestation to verify.
    function verifyAttestation(uint256 _attestationId) public onlyAttestationVerifier whenNotPaused {
        Attestation storage att = attestations[_attestationId];
        require(att.id != 0, "Attestation not found");
        require(!att.isVerified, "Attestation already verified");
        require(!att.hasPenalty, "Attestation has penalty"); // Cannot verify a penalized attestation

        att.isVerified = true;
        uint256 reputationAward = currentEpochConfig.reputationRewardFactor;
        _addReputation(att.submitter, reputationAward);

        emit AttestationVerified(_attestationId, msg.sender, att.submitter, reputationAward);
    }

    /// @notice Retrieves the current *effective* (lazily decayed) reputation score for a given user.
    /// @param _user The address of the user.
    /// @return The current effective reputation score.
    function getReputation(address _user) public view returns (uint256) {
        uint256 rawRep = reputationScores[_user];
        if (rawRep == 0) return 0;

        uint256 lastUpdateEpoch = _lastReputationUpdateEpoch[_user];
        if (lastUpdateEpoch < currentEpoch) {
            uint256 epochsPassed = currentEpoch - lastUpdateEpoch;
            uint256 decayRate = currentEpochConfig.reputationDecayRate; // e.g., 100 for 1%

            if (decayRate == 0) return rawRep; // No decay configured

            // Retain factor: (10000 - decayRate) / 10000 for each epoch
            // Example: 1% decay, retain 99%. (9900 / 10000)
            uint256 retainFactor = 10000 - decayRate;
            if (retainFactor == 0) return 0; // If 100% decay (e.g., decayRate = 10000)

            for (uint i = 0; i < epochsPassed; i++) {
                rawRep = (rawRep * retainFactor) / 10000;
                if (rawRep == 0) break; // Optimization: if it decays to 0, stop
            }
        }
        return rawRep;
    }

    /// @notice Allows a stakeholder to challenge a submitted attestation by depositing a bond, initiating a dispute.
    /// @param _attestationId The ID of the attestation to challenge.
    function challengeAttestation(uint256 _attestationId) public payable whenNotPaused onlyStakeholder(currentEpochConfig.minReputationToClaim) {
        Attestation storage att = attestations[_attestationId];
        require(att.id != 0, "Attestation not found");
        require(msg.sender != att.submitter, "Cannot challenge own attestation");
        require(msg.value == currentEpochConfig.attestationChallengeBond, "Incorrect challenge bond");
        require(!att.hasPenalty, "Attestation already penalized"); // Cannot challenge an already penalized attestation

        // In a real system, this would involve storing the challenger's address and bond for later refund/forfeiture
        // and potentially a more complex arbitration mechanism (e.g., Kleros, Aragon Court).
        // For simplicity, we just increment a counter and assume the bond is held by the contract.
        att.challenges++;
        emit AttestationChallenged(_attestationId, msg.sender);
    }

    /// @notice Owner/governance resolves a challenge, penalizing the submitter or challenger based on validity.
    /// @param _attestationId The ID of the attestation that was challenged.
    /// @param _isAttestationValid True if the attestation is deemed valid, false if it's found to be false/malicious.
    /// @param _challenger The address of the user who challenged the attestation.
    function resolveAttestationChallenge(uint256 _attestationId, bool _isAttestationValid, address _challenger) public onlyOwner whenNotPaused {
        Attestation storage att = attestations[_attestationId];
        require(att.id != 0, "Attestation not found");
        require(att.challenges > 0, "Attestation not challenged"); // Ensure it was actually challenged
        require(_challenger != address(0), "Invalid challenger address");

        address penalizedUser = address(0);
        uint256 penaltyAmount = 0;

        if (!_isAttestationValid) { // Attestation was false/malicious
            penaltyAmount = currentEpochConfig.reputationRewardFactor * 2; // Double penalty for malicious
            _burnReputation(att.submitter, penaltyAmount);
            att.hasPenalty = true;
            // Refund challenger's bond
            payable(_challenger).transfer(currentEpochConfig.attestationChallengeBond);
            penalizedUser = att.submitter;
        } else { // Attestation was valid, challenger was wrong
            penaltyAmount = currentEpochConfig.reputationRewardFactor / 2; // Challenger loses some reputation
            _burnReputation(_challenger, penaltyAmount);
            // Challenger's bond is forfeited, remains in the contract's treasury.
            penalizedUser = _challenger;
        }
        att.challenges = 0; // Reset challenges for this attestation
        emit AttestationChallengeResolved(_attestationId, _isAttestationValid, penalizedUser, penaltyAmount);
    }

    // III. Adaptive Parameters & Governance

    /// @notice Stakeholders can propose changes to core protocol parameters.
    /// @param _paramName The name of the parameter to change (e.g., "reputationRewardFactor").
    /// @param _newValue The new value for the parameter.
    /// @return proposalId The ID of the newly created proposal.
    function proposeParameterChange(string memory _paramName, uint256 _newValue) public whenNotPaused onlyStakeholder(currentEpochConfig.minReputationForProposal) returns (uint256) {
        // A more robust system would use a pre-defined list of parameter keys or a more generic `_calldata` for arbitrary function calls.
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        require(paramHash == keccak256(abi.encodePacked("reputationRewardFactor")) ||
                paramHash == keccak256(abi.encodePacked("minReputationForProposal")) ||
                paramHash == keccak256(abi.encodePacked("attestationChallengeBond")) ||
                paramHash == keccak256(abi.encodePacked("reputationDecayRate")) ||
                paramHash == keccak256(abi.encodePacked("minReputationToClaim")),
                "Invalid parameter name");

        uint256 proposalId = nextProposalId++;
        parameterProposals[proposalId].id = proposalId;
        parameterProposals[proposalId].proposer = msg.sender;
        parameterProposals[proposalId].paramName = _paramName;
        parameterProposals[proposalId].newValue = _newValue;
        parameterProposals[proposalId].expiration = block.timestamp + 7 days; // 7-day voting period
        // votedUsers mapping is implicitly initialized with the struct.
        emit ParameterProposalCreated(proposalId, msg.sender, _paramName, _newValue);
        return proposalId;
    }

    /// @notice Users vote on active parameter change proposals, with their effective reputation weighted into their vote.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for "for" vote, false for "against" vote.
    function voteOnParameterChange(uint256 _proposalId, bool _support) public whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.id != 0, "Proposal not found");
        require(block.timestamp <= proposal.expiration, "Voting period ended");
        require(!proposal.isExecuted, "Proposal already executed");
        require(!proposal.votedUsers[msg.sender], "Already voted on this proposal");

        uint256 voterReputation = getReputation(msg.sender); // Use lazily decayed reputation
        require(voterReputation > 0, "Voter must have reputation");

        if (_support) {
            proposal.votesFor += voterReputation;
        } else {
            proposal.votesAgainst += voterReputation;
        }
        proposal.votedUsers[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support, voterReputation);
    }

    /// @notice Executes a passed parameter change proposal, updating the protocol's adaptive rules.
    /// @param _proposalId The ID of the proposal to execute.
    function executeParameterChange(uint256 _proposalId) public whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.id != 0, "Proposal not found");
        require(block.timestamp > proposal.expiration, "Voting period not ended");
        require(!proposal.isExecuted, "Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not passed (votesFor <= votesAgainst)");

        proposal.isExecuted = true;
        bytes32 paramHash = keccak256(abi.encodePacked(proposal.paramName));

        if (paramHash == keccak256(abi.encodePacked("reputationRewardFactor"))) {
            currentEpochConfig.reputationRewardFactor = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minReputationForProposal"))) {
            currentEpochConfig.minReputationForProposal = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("attestationChallengeBond"))) {
            currentEpochConfig.attestationChallengeBond = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("reputationDecayRate"))) {
            currentEpochConfig.reputationDecayRate = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minReputationToClaim"))) {
            currentEpochConfig.minReputationToClaim = proposal.newValue;
        }

        emit ParameterChangeExecuted(_proposalId, proposal.paramName, proposal.newValue);
    }

    /// @notice Retrieves the current epoch's configuration parameters.
    /// @return reputationRewardFactor, minReputationForProposal, attestationChallengeBond, reputationDecayRate, minReputationToClaim
    function getEpochConfig() public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            currentEpochConfig.reputationRewardFactor,
            currentEpochConfig.minReputationForProposal,
            currentEpochConfig.attestationChallengeBond,
            currentEpochConfig.reputationDecayRate,
            currentEpochConfig.minReputationToClaim
        );
    }

    /// @notice Advances the protocol to the next epoch, signifying a new period.
    function advanceEpoch() public whenNotPaused {
        require(block.timestamp >= (currentEpoch * epochDuration) + epochDuration, "Epoch not yet ended");
        currentEpoch++;
        // Reputation decay is handled lazily when reputation is read or modified.
        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    // IV. Dynamic Resource Pools

    /// @notice Owner/governance creates new resource pools with specified assets and adaptive allocation formulas.
    /// @param _name The human-readable name of the pool.
    /// @param _asset Address of the ERC20 token, or address(0) for ETH.
    /// @param _initialAllocationFactor A base factor used in allocation calculations (scaled, e.g., 10^18 for precision).
    /// @param _formulaType The adaptive formula type (e.g., Linear, Quadratic, Inverse).
    /// @return poolId The ID of the newly created pool.
    function createAdaptivePool(string memory _name, address _asset, uint256 _initialAllocationFactor, AllocationFormulaType _formulaType) public onlyOwner whenNotPaused returns (uint256) {
        require(_initialAllocationFactor > 0, "Initial factor must be positive");

        uint256 poolId = nextPoolId++;
        adaptivePools[poolId] = PoolConfig({
            id: poolId,
            name: _name,
            asset: _asset,
            totalContributions: 0,
            initialAllocationFactor: _initialAllocationFactor,
            allocationFormulaType: _formulaType,
            isActive: true
        });
        emit PoolCreated(poolId, _name, _asset, _initialAllocationFactor, _formulaType);
        return poolId;
    }

    /// @notice Users can contribute ETH or ERC20 tokens to a designated adaptive resource pool.
    /// @param _poolId The ID of the pool to contribute to.
    /// @param _amount The amount to contribute (only applicable for ERC20 contribution; ETH uses msg.value).
    function contributeToPool(uint256 _poolId, uint256 _amount) public payable whenNotPaused {
        PoolConfig storage pool = adaptivePools[_poolId];
        require(pool.id != 0, "Pool not found");
        require(pool.isActive, "Pool is inactive");

        if (pool.asset == address(0)) { // ETH contribution
            require(msg.value > 0, "Must send ETH to contribute");
            require(_amount == msg.value, "ETH amount mismatch");
            pool.totalContributions += msg.value;
            emit ContributedToPool(_poolId, msg.sender, address(0), msg.value);
        } else { // ERC20 token contribution
            require(msg.value == 0, "Do not send ETH for token contribution");
            require(_amount > 0, "Amount must be positive");
            IERC20 token = IERC20(pool.asset);
            require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
            pool.totalContributions += _amount;
            emit ContributedToPool(_poolId, msg.sender, pool.asset, _amount);
        }
    }

    /// @notice Stakeholders can claim resources from a pool, with the amount determined by their effective reputation and the pool's adaptive allocation formula.
    /// @param _poolId The ID of the pool to claim from.
    function claimFromPool(uint256 _poolId) public whenNotPaused onlyStakeholder(currentEpochConfig.minReputationToClaim) {
        PoolConfig storage pool = adaptivePools[_poolId];
        require(pool.id != 0, "Pool not found");
        require(pool.isActive, "Pool is inactive");
        require(pool.totalContributions > 0, "No funds in pool");

        uint256 claimantReputation = getReputation(msg.sender); // Use lazily decayed reputation
        require(claimantReputation >= currentEpochConfig.minReputationToClaim, "Insufficient reputation to claim");

        // Calculate share based on allocation formula
        uint256 share = _calculatePoolShare(pool, claimantReputation);
        require(share > 0, "No share calculated or too small");
        require(share <= pool.totalContributions, "Claim amount exceeds pool funds");

        pool.totalContributions -= share;

        if (pool.asset == address(0)) { // ETH withdrawal
            payable(msg.sender).transfer(share);
        } else { // ERC20 token withdrawal
            IERC20 token = IERC20(pool.asset);
            require(token.transfer(msg.sender, share), "Token transfer failed");
        }
        emit ClaimedFromPool(_poolId, msg.sender, pool.asset, share);
    }

    /// @notice Owner/governance can update the allocation formula for an existing resource pool.
    /// @param _poolId The ID of the pool to update.
    /// @param _newFormulaType The new adaptive formula type.
    function updatePoolAllocationFormula(uint256 _poolId, AllocationFormulaType _newFormulaType) public onlyOwner whenNotPaused {
        PoolConfig storage pool = adaptivePools[_poolId];
        require(pool.id != 0, "Pool not found");
        pool.allocationFormulaType = _newFormulaType;
        emit PoolAllocationFormulaUpdated(_poolId, _newFormulaType);
    }

    /// @notice Allows a user to see an estimate of how much they would receive from a pool based on current rules and their reputation.
    /// @param _poolId The ID of the pool.
    /// @param _user The address of the user.
    /// @return The estimated claimable amount.
    function getPoolAllocationPreview(uint256 _poolId, address _user) public view returns (uint256) {
        PoolConfig storage pool = adaptivePools[_poolId];
        require(pool.id != 0, "Pool not found");
        require(pool.isActive, "Pool is inactive");
        require(pool.totalContributions > 0, "No funds in pool");

        uint256 userReputation = getReputation(_user); // Use lazily decayed reputation
        if (userReputation < currentEpochConfig.minReputationToClaim) {
            return 0; // User does not meet minimum reputation
        }
        return _calculatePoolShare(pool, userReputation);
    }

    // V. NFT Integration (Stakeholder Badges)

    /// @notice Owner sets up the reputation thresholds and names for different stakeholder badge tiers.
    /// @param _minReputations An array of minimum reputation scores for each tier.
    /// @param _names An array of names for each tier, corresponding to `_minReputations`.
    function initializeStakeholderTiers(uint256[] memory _minReputations, string[] memory _names) public onlyOwner {
        require(stakeholderTiers.length == 0, "Tiers already initialized");
        require(_minReputations.length == _names.length, "Arrays must have same length");
        for(uint i=0; i < _minReputations.length; i++) {
            stakeholderTiers.push(StakeholderTier({
                minReputation: _minReputations[i],
                name: _names[i]
            }));
        }
        // Assume input is sorted by minReputation ascending.
    }

    /// @notice Returns the stakeholder tier ID and name for a given reputation score.
    /// @param _reputation The reputation score to check.
    /// @return tierId The 1-indexed ID of the tier.
    /// @return tierName The name of the tier.
    function getStakeholderTier(uint256 _reputation) public view returns (uint256 tierId, string memory tierName) {
        tierId = 0; // Default to no tier
        tierName = "None";
        for(uint i = 0; i < stakeholderTiers.length; i++) {
            if (_reputation >= stakeholderTiers[i].minReputation) {
                tierId = i + 1; // 1-indexed tier ID
                tierName = stakeholderTiers[i].name;
            } else {
                break; // Tiers are sorted, so we can stop once reputation is too low
            }
        }
        return (tierId, tierName);
    }

    /// @notice Allows an eligible user to mint a non-transferable NFT badge representing their stakeholder tier.
    function mintStakeholderBadge() public whenNotPaused {
        require(address(stakeholderBadgeNFT) != address(0), "NFT contract not set");
        uint256 userRep = getReputation(msg.sender); // Use lazily decayed reputation
        require(userRep > 0, "Insufficient reputation to mint badge");
        require(userBadgeTokenId[msg.sender] == 0, "Already possesses a stakeholder badge");

        (uint256 tierId, ) = getStakeholderTier(userRep);
        require(tierId > 0, "No eligible tier for current reputation");

        // This requires the `stakeholderBadgeNFT` to implement `IStakeholderBadge` interface
        // and allow this contract to mint.
        uint256 newTokenId = IStakeholderBadge(address(stakeholderBadgeNFT)).mintBadge(msg.sender, tierId);
        userBadgeTokenId[msg.sender] = newTokenId;
        emit StakeholderBadgeMinted(msg.sender, newTokenId, userRep, tierId);
    }

    /// @notice Notifies the system to update a user's existing stakeholder badge (e.g., by triggering metadata refresh) to reflect their current, potentially higher, reputation tier.
    function upgradeStakeholderBadge() public whenNotPaused {
        require(address(stakeholderBadgeNFT) != address(0), "NFT contract not set");
        uint256 tokenId = userBadgeTokenId[msg.sender];
        require(tokenId != 0, "No stakeholder badge to upgrade");

        uint256 userRep = getReputation(msg.sender); // Use lazily decayed reputation
        (uint256 newTierId, ) = getStakeholderTier(userRep);

        uint256 currentBadgeTier = IStakeholderBadge(address(stakeholderBadgeNFT)).getTier(tokenId);

        require(newTierId > currentBadgeTier, "Badge cannot be downgraded or is already at the highest eligible tier");

        // Assuming IStakeholderBadge has an `updateBadgeTier` function or similar
        // IStakeholderBadge(address(stakeholderBadgeNFT)).updateBadgeTier(tokenId, newTierId);
        // For this example, we'll just emit the event assuming external systems handle the metadata update
        // or the NFT contract itself has a mechanism to read the reputation from Chrysalis.
        emit StakeholderBadgeUpgraded(msg.sender, tokenId, newTierId, userRep);
    }

    // VI. Utility & Administrative

    /// @notice Allows the owner to withdraw accumulated ETH from the contract (e.g., forfeited challenge bonds, leftover contributions).
    /// @param _to The address to send the ETH to.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawEth(address payable _to, uint256 _amount) public onlyOwner whenNotPaused {
        require(_amount <= address(this).balance, "Insufficient balance");
        _to.transfer(_amount);
    }

    /// @notice Allows the owner to withdraw accumulated ERC20 tokens from the contract.
    /// @param _token The address of the ERC20 token.
    /// @param _to The address to send the tokens to.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawERC20(address _token, address _to, uint256 _amount) public onlyOwner whenNotPaused {
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient token balance");
        token.transfer(_to, _amount);
    }

    // --- Internal/Private Helpers ---

    /// @dev Internal function to add reputation to a user and update total protocol reputation.
    ///      This updates the base `reputationScores` to the new effective value and resets the decay epoch.
    /// @param _user The user's address.
    /// @param _amount The amount of reputation to add.
    function _addReputation(address _user, uint256 _amount) internal {
        uint256 currentEffectiveRep = getReputation(_user); // Get current effective reputation
        uint256 newEffectiveRep = currentEffectiveRep + _amount; // Add to effective reputation

        reputationScores[_user] = newEffectiveRep;
        _lastReputationUpdateEpoch[_user] = currentEpoch;
        totalProtocolReputation += _amount; // Keep track of raw sum (can differ from sum of effective reps)
        emit ReputationAdded(_user, _amount, newEffectiveRep);
    }

    /// @dev Internal function to burn reputation from a user and update total protocol reputation.
    ///      This updates the base `reputationScores` to the new effective value and resets the decay epoch.
    /// @param _user The user's address.
    /// @param _amount The amount of reputation to burn.
    function _burnReputation(address _user, uint256 _amount) internal {
        uint256 currentEffectiveRep = getReputation(_user); // Get current effective reputation
        if (currentEffectiveRep > _amount) {
            uint256 newEffectiveRep = currentEffectiveRep - _amount;
            reputationScores[_user] = newEffectiveRep;
            _lastReputationUpdateEpoch[_user] = currentEpoch;
            totalProtocolReputation -= _amount;
            emit ReputationBurned(_user, _amount, newEffectiveRep);
        } else {
            reputationScores[_user] = 0;
            _lastReputationUpdateEpoch[_user] = currentEpoch;
            totalProtocolReputation -= currentEffectiveRep;
            emit ReputationBurned(_user, currentEffectiveRep, 0);
        }
    }

    /// @dev Internal helper to calculate a user's share from a pool based on its adaptive formula.
    /// @param _pool The pool configuration.
    /// @param _reputation The user's effective reputation.
    /// @return The calculated share amount.
    function _calculatePoolShare(PoolConfig storage _pool, uint256 _reputation) internal view returns (uint256) {
        uint256 calculatedShare;
        // Scale reputation to match initialAllocationFactor's precision (e.g., 10^18)
        // Assume `initialAllocationFactor` is already scaled appropriately for the asset's decimals
        // For simplicity, let's assume a basic `baseFactor` derived from the initialAllocationFactor.
        uint256 baseFactor = _pool.initialAllocationFactor; // Assuming this is scaled for asset decimals and a per-reputation unit.

        if (_pool.allocationFormulaType == AllocationFormulaType.Linear) {
            calculatedShare = (_reputation * baseFactor) / 1e18; // Divide by 1e18 for scaling if baseFactor is also 1e18
        } else if (_pool.allocationFormulaType == AllocationFormulaType.Quadratic) {
            // Amplified effect: (reputation^2 * baseFactor) / (maxReputationCap^2 * scalingFactor)
            // Using a simpler quadratic effect here: (reputation * reputation * baseFactor) / (1e18 * 1e18)
            // This needs careful scaling to prevent overflow or underflow.
            // Let's simplify to: baseFactor * (reputation / X)^2
            uint256 scaledRep = _reputation / 100; // Reduce reputation for multiplication
            calculatedShare = (scaledRep * scaledRep * baseFactor) / (100 * 1e18); // Example scaling
        } else if (_pool.allocationFormulaType == AllocationFormulaType.Inverse) {
            // Rewards lower reputation more. Needs a reference point for max reputation effect.
            // Example: If reputation < 2000, award (2000 - reputation) * factor
            uint256 maxRepInverseEffect = 2000;
            if (_reputation < maxRepInverseEffect) {
                calculatedShare = ((maxRepInverseEffect - _reputation + 100) * baseFactor) / 1e18; // Add offset to prevent 0
            } else {
                calculatedShare = (100 * baseFactor) / 1e18; // Minimal for very high reputation
            }
        }
        
        // Ensure result is within reasonable bounds and accounts for total pool size
        // Cap the claim to a percentage of the total pool or a fixed max to prevent depletion by one user
        uint256 maxClaimPerUser = _pool.totalContributions / 20; // Max 5% of pool per claim, or adjust as needed.
        if (maxClaimPerUser == 0) maxClaimPerUser = 1; // Ensure a minimum possible claim (1 unit of asset)

        return calculatedShare > maxClaimPerUser ? maxClaimPerUser : calculatedShare;
    }
}
```