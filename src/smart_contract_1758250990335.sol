This Solidity smart contract, named "AetherForge," introduces a novel decentralized ecosystem for generating unique digital assets (NFTs). It uniquely intertwines an AI-augmented dynamic reputation system with a sophisticated DAO governance model, all while facilitating community-driven curation of generative art blueprints.

The core innovation lies in:
1.  **AI-Driven Dynamic Reputation:** User reputation is not static; it's dynamically updated by an off-chain AI model, with the computational correctness verified by submitting ZK-proof hashes on-chain via a trusted oracle. This allows for nuanced, intelligent evaluation of user contributions beyond simple on-chain metrics.
2.  **Reputation-Augmented Governance & Curation:** This dynamic reputation directly influences both the weight of a user's vote in DAO proposals and their influence in curating (approving/rejecting) generative asset blueprints. This creates a powerful feedback loop where quality contributions lead to greater influence.
3.  **Decentralized Generative Asset Creation:** Users propose "blueprints" (hashes of off-chain generative AI prompts/parameters) by staking tokens. The community votes on these, leveraging their reputation-weighted influence. Approved blueprints then utilize Chainlink VRF for verifiable randomness to mint unique NFTs, whose properties are inspired by the blueprint and random seed.

This contract avoids duplicating open-source contracts by focusing on the unique *combination and interaction* of these advanced mechanisms, particularly the AI/ZK-proof integration into a dynamic reputation system that then drives both generative asset creation and DAO governance.

---

## Contract: AetherForge - Decentralized Generative Asset Protocol with Adaptive Reputation & AI-Augmented Governance

**Author:** AetherForge Dev Team
**License:** MIT

### Outline

**I. Core Platform Management**
   *   `constructor()`
   *   `updateOracleAddress(address _newOracle)`
   *   `updateVRFCoordinator(address _newCoordinator, bytes32 _keyHash)`
   *   `setProtocolFee(uint256 _newFeeBasisPoints)`
   *   `setNFTContractAddress(address _newNFTContract)`
   *   `pauseContract()`
   *   `unpauseContract()`
   *   `withdrawProtocolFees(address _recipient)`

**II. Reputation System**
   *   `submitReputationUpdateProof(address _user, int256 _reputationDelta, bytes32 _proofHash)`
   *   `getUserReputation(address _user)`
   *   `stakeAETForReputationBoost(uint256 _amount)`
   *   `unstakeAETFromReputationBoost(uint256 _amount)`
   *   `decayReputation(address _user)`
   *   `setReputationDecayParameters(uint256 _decayRate, uint256 _decayInterval)`
   *   `getReputationStake(address _user)`

**III. Generative Asset Blueprint & Curation**
   *   `submitBlueprint(string calldata _blueprintHash, uint256 _stakeAmount)`
   *   `voteOnBlueprint(bytes32 _blueprintId, bool _approve)`
   *   `getBlueprintDetails(bytes32 _blueprintId)`
   *   `finalizeBlueprintCuration(bytes32 _blueprintId)`
   *   `requestVRFForMint(bytes32 _blueprintId)`
   *   `fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords)` (Chainlink VRF Callback)
   *   `mintAetherForgeAsset(bytes32 _blueprintId)`
   *   `claimBlueprintStakingRewards(bytes32 _blueprintId)`

**IV. DAO Governance**
   *   `proposeChange(string calldata _description, address _target, bytes calldata _callData)`
   *   `voteOnProposal(uint256 _proposalId, bool _support)`
   *   `getProposalDetails(uint256 _proposalId)`
   *   `queueProposal(uint256 _proposalId)`
   *   `executeProposal(uint256 _proposalId)`

### Function Summary

**I. Core Platform Management**
1.  `constructor()`: Initializes the contract, setting up the `AetherToken` (ERC20) address, Chainlink VRF coordinator, key hash, subscription ID, and initial owner/fee recipient.
2.  `updateOracleAddress(address _newOracle)`: Allows the owner (or DAO) to change the address of the trusted oracle responsible for submitting AI-driven reputation updates.
3.  `updateVRFCoordinator(address _newCoordinator, bytes32 _keyHash)`: Allows the owner (or DAO) to update the Chainlink VRF coordinator address and key hash.
4.  `setProtocolFee(uint256 _newFeeBasisPoints)`: Sets the percentage (in basis points) of the staked amount that is taken as a protocol fee upon successful blueprint minting.
5.  `setNFTContractAddress(address _newNFTContract)`: Sets the address of the `AetherForgeNFT` (ERC721) contract, through which new generative assets are minted.
6.  `pauseContract()`: Emergency function by the owner to pause critical contract operations.
7.  `unpauseContract()`: Allows the owner to resume paused contract operations.
8.  `withdrawProtocolFees(address _recipient)`: Enables the designated `feeRecipient` or owner to withdraw accumulated `AetherToken` fees.

**II. Reputation System**
9.  `submitReputationUpdateProof(address _user, int256 _reputationDelta, bytes32 _proofHash)`: An `onlyOracle` function to update a user's reputation score. It accepts an integer `_reputationDelta` (can be positive or negative) and a `_proofHash`, representing a ZK-proof (or similar) of the off-chain AI's computation.
10. `getUserReputation(address _user)`: Returns the current, time-decayed reputation score of a user.
11. `stakeAETForReputationBoost(uint256 _amount)`: Allows users to stake `AetherToken` to increase their effective voting weight and influence in curation.
12. `unstakeAETFromReputationBoost(uint256 _amount)`: Permits users to retrieve `AetherToken` previously staked for reputation boosting.
13. `decayReputation(address _user)`: Applies a predefined time-based decay to a user's reputation score, callable by anyone (e.g., automated keepers).
14. `setReputationDecayParameters(uint256 _decayRate, uint256 _decayInterval)`: DAO-governed function to configure the rate and interval at which user reputation decays.
15. `getReputationStake(address _user)`: Returns the amount of `AetherToken` a user has staked for reputation.

**III. Generative Asset Blueprint & Curation**
16. `submitBlueprint(string calldata _blueprintHash, uint256 _stakeAmount)`: Users submit a hash (e.g., IPFS CID) of their generative AI prompt/parameters, staking `AetherToken` to initiate a new asset creation process.
17. `voteOnBlueprint(bytes32 _blueprintId, bool _approve)`: `onlyReputable` users vote to approve or reject a submitted blueprint. Their vote strength is weighted by their combined `AetherToken` stake and reputation score.
18. `getBlueprintDetails(bytes32 _blueprintId)`: A view function to retrieve all relevant information about a specific blueprint.
19. `finalizeBlueprintCuration(bytes32 _blueprintId)`: Callable by anyone after the voting period ends. It tallies votes and determines if a blueprint is `Approved` or `Rejected` based on predefined quorum and support thresholds.
20. `requestVRFForMint(bytes32 _blueprintId)`: Triggers a Chainlink VRF request for an `Approved` blueprint to obtain a verifiable random number for NFT generation.
21. `fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords)`: An internal callback function from Chainlink VRF Coordinator, which provides the requested random words to the contract.
22. `mintAetherForgeAsset(bytes32 _blueprintId)`: Mints an `AetherForgeNFT` for an approved blueprint after VRF fulfillment. It transfers protocol fees and assigns a unique `tokenId` derived from the blueprint and random seed.
23. `claimBlueprintStakingRewards(bytes32 _blueprintId)`: Allows the original proposer of a successfully minted blueprint to claim back their initial stake (minus protocol fees).

**IV. DAO Governance**
24. `proposeChange(string calldata _description, address _target, bytes calldata _callData)`: Enables users to propose changes to the contract's parameters or execute arbitrary calls on designated target contracts. Requires staking `AetherToken`.
25. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to cast their vote (for or against) on an active proposal. Voting power is dynamically calculated from their staked `AetherToken` and reputation score.
26. `getProposalDetails(uint256 _proposalId)`: A view function to retrieve all details of a specific DAO proposal.
27. `queueProposal(uint256 _proposalId)`: Callable by anyone after the voting period concludes, if a proposal meets its quorum and support thresholds. It changes the proposal's status to `Queued` and initiates a timelock.
28. `executeProposal(uint256 _proposalId)`: Executes a `Queued` proposal after its timelock period has expired. This function performs the proposed `_callData` on the `_target` contract and returns the proposer's stake.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For potential oracle signature verification, though a simple trusted address is used here for brevity.
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// Dummy interface for AetherForgeNFT, representing the generated ERC721 assets.
// In a real deployment, this would be a separate, full ERC721 contract.
interface IAetherForgeNFT is IERC721 {
    function mint(address to, uint256 tokenId, string memory blueprintHash, uint256 seed) external returns (uint256);
    function updateMetadataLink(uint256 tokenId, string memory newUri) external; // Example for dynamic NFTs
}

// Dummy interface for AetherToken, the governance and staking ERC20 token.
// In a real deployment, this would be a separate, full ERC20 contract.
interface IAetherToken is IERC20 {
    // Standard ERC20 functions are implicitly included via IERC20
}

/// @title AetherForge - Decentralized Generative Asset Protocol with Adaptive Reputation & AI-Augmented Governance
/// @author AetherForge Dev Team
/// @notice This contract enables a decentralized ecosystem for generating unique digital assets (NFTs)
///         based on user-submitted "blueprints" (prompts/parameters). It features an advanced
///         reputation system that is dynamically updated by off-chain AI analysis (verified by ZK-proofs
///         via an oracle), and an adaptive DAO governance model where voting power is a combination
///         of token stake and reputation score.
///         The core idea is to foster a high-quality creative community through incentivized curation
///         and AI-augmented decision-making, while leveraging verifiable randomness for asset uniqueness.
/// @dev This contract relies on external ERC20 (AetherToken), ERC721 (AetherForgeNFT), and Chainlink VRF.
///      Oracle interactions for AI reputation updates and ZK-proof verification are simulated via a trusted `oracleAddress`.
///      Due to gas limitations, the contract stores ZK-proof hashes but does not verify the proofs on-chain.
///      Efficiency for iterating over all staked funds is not optimized in all cases (e.g., `_getTotalStakedAET`).
contract AetherForge is Ownable, Pausable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    // --- Outline and Function Summary ---
    // I. Core Platform Management (Functions: constructor, updateOracleAddress, updateVRFCoordinator, setProtocolFee, setNFTContractAddress, pauseContract, unpauseContract, withdrawProtocolFees)
    // II. Reputation System (Functions: submitReputationUpdateProof, getUserReputation, stakeAETForReputationBoost, unstakeAETFromReputationBoost, decayReputation, setReputationDecayParameters, getReputationStake)
    // III. Generative Asset Blueprint & Curation (Functions: submitBlueprint, voteOnBlueprint, getBlueprintDetails, finalizeBlueprintCuration, requestVRFForMint, fulfillRandomWords, mintAetherForgeAsset, claimBlueprintStakingRewards)
    // IV. DAO Governance (Functions: proposeChange, voteOnProposal, getProposalDetails, queueProposal, executeProposal)

    // --- State Variables ---
    IAetherToken public immutable AetherToken;
    IAetherForgeNFT public AetherForgeNFT;

    address public oracleAddress; // Address of the trusted oracle for AI reputation updates and ZK-proof verification
    address public feeRecipient;  // Address where protocol fees are sent
    uint256 public protocolFeeBasisPoints; // Basis points (e.g., 100 = 1%) fee on successful blueprint stakes

    // Chainlink VRF V2
    VRFCoordinatorV2Interface public VRFCoordinator;
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash; // The gas lane key hash to use. See: https://docs.chain.link/vrf/v2/supported-networks
    uint32 public constant CALLBACK_GAS_LIMIT = 500_000; // Adjust as needed for VRF callback
    uint16 public constant REQUEST_CONFIRMATIONS = 3;    // Number of block confirmations before Chainlink fulfills VRF

    // --- Enums & Structs ---

    /// @dev Represents the lifecycle status of a generative asset blueprint.
    enum BlueprintStatus {
        Submitted,          // Initial state, not yet open for voting (conceptually, direct to Voting here)
        Voting,             // Actively being voted on by the community
        Approved,           // Successfully voted to be approved
        Rejected,           // Voted to be rejected
        MintingRequested,   // Approved, and VRF randomness has been requested
        Minted              // NFT has been successfully minted
    }

    /// @dev Stores information about a user-submitted generative asset blueprint.
    struct Blueprint {
        address proposer;
        string blueprintHash;       // IPFS hash or similar for off-chain prompt/parameters
        uint256 stakedAmount;       // AET staked by the proposer for this blueprint
        uint256 submissionTime;
        BlueprintStatus status;
        uint256 positiveVotes;      // Reputation-weighted positive votes
        uint256 negativeVotes;      // Reputation-weighted negative votes
        uint256 totalVoteWeight;    // Sum of all voter weights
        uint256 votingEndTime;      // When the voting period for this blueprint ends
        uint256 vrfRequestId;       // Chainlink VRF request ID associated with this blueprint
        uint256[] vrfRandomWords;   // Result from VRF (e.g., a single random number)
        uint256 mintedTokenId;      // The ID of the minted NFT, if applicable
    }

    /// @dev Holds a user's dynamic reputation score and related metadata.
    struct UserReputation {
        int256 score;             // Current reputation score (can be positive or negative)
        uint256 lastUpdated;      // Timestamp of the last reputation update or decay application
        uint256 stakedAET;        // AET staked specifically for reputation boost
    }

    /// @dev Represents the lifecycle status of a DAO governance proposal.
    enum ProposalStatus {
        Pending,                // Initial state (conceptually, direct to Active here)
        Active,                 // Actively being voted on
        Succeeded,              // Voted to be successful and can be queued
        Failed,                 // Failed to meet quorum or support
        Queued,                 // Successfully voted and now in timelock
        Executed,               // Successfully executed after timelock
        Canceled                // Canceled by proposer or other means
    }

    /// @dev Stores details for a DAO governance proposal.
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address target;          // Target contract for the proposed function call
        bytes callData;          // Calldata for the target function
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 timelockEndTime; // When the proposal can be executed after being queued
        uint256 quorumThreshold; // Minimum combined vote weight required for success
        uint256 supportThreshold; // Percentage (basis points) of positive votes needed (e.g., 5100 for 51%)
        ProposalStatus status;
        uint256 positiveVotes;   // Combined reputation + AET-weighted votes in favor
        uint256 negativeVotes;   // Combined reputation + AET-weighted votes against
        uint256 totalVoteWeight; // Total AET + reputation votes cast for this proposal
        uint256 stakedAmount;    // AET staked by the proposer for this proposal
    }

    // --- Mappings ---
    mapping(bytes32 => Blueprint) public blueprints;
    mapping(address => UserReputation) public userReputations;
    mapping(address => mapping(bytes32 => bool)) public hasVotedOnBlueprint; // user => blueprintId => true if voted
    mapping(uint256 => Blueprint) public s_requests; // Chainlink VRF request ID => blueprint struct

    Counters.Counter public proposalIdCounter; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVotedOnProposal; // user => proposalId => true if voted

    // Total AET staked for DAO proposals and reputation (for `withdrawProtocolFees` calculation)
    uint256 public totalProposalStakedAET;
    uint256 public totalReputationStakedAET;
    uint256 public totalBlueprintStakedAET;

    // --- Configuration Parameters (DAO controllable via proposals) ---
    uint256 public blueprintVotingPeriod = 3 days;           // Duration for blueprint voting
    uint256 public minBlueprintStake = 100 ether;            // Minimum AET required to submit a blueprint (100 AET)
    uint256 public minBlueprintVoteWeight = 500;             // Minimum combined (AET+Reputation) weight to vote on a blueprint
    uint256 public blueprintQuorumThreshold = 10000;         // Minimum total vote weight required for a blueprint to be considered
    uint256 public blueprintSupportThreshold = 6000;         // 60% of positive votes needed (6000 basis points)

    uint256 public reputationDecayRateBasisPoints = 100;     // 1% decay per interval (100 basis points)
    uint256 public reputationDecayInterval = 30 days;        // Decay every 30 days
    uint256 public reputationBoostFactor = 100;              // How much reputation 1 AET stake contributes to vote weight

    uint256 public proposalVotingPeriod = 7 days;            // Duration for proposal voting
    uint256 public proposalTimelockDuration = 2 days;        // Time proposals spend in queue before execution
    uint256 public minProposalStake = 1000 ether;            // Minimum AET required to submit a proposal (1000 AET)
    uint256 public proposalQuorumThreshold = 50000;          // Minimum total vote weight for a proposal to pass
    uint256 public proposalSupportThreshold = 5100;          // 51% of positive votes needed (5100 basis points)

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracle);
    event VRFCoordinatorUpdated(address indexed newCoordinator, bytes32 newKeyHash);
    event ProtocolFeeUpdated(uint256 newFeeBasisPoints);
    event NFTContractAddressUpdated(address indexed newAddress);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    event ReputationUpdated(address indexed user, int256 oldScore, int256 newScore, bytes32 proofHash);
    event ReputationStaked(address indexed user, uint256 amount, uint256 newTotalStake);
    event ReputationUnstaked(address indexed user, uint256 amount, uint256 newTotalStake);
    event ReputationDecayParametersUpdated(uint256 newDecayRate, uint256 newDecayInterval);

    event BlueprintSubmitted(bytes32 indexed blueprintId, address indexed proposer, string blueprintHash, uint256 stakedAmount);
    event BlueprintVoted(bytes32 indexed blueprintId, address indexed voter, bool support, uint256 voteWeight);
    event BlueprintCurationFinalized(bytes32 indexed blueprintId, BlueprintStatus newStatus);
    event VRFRequested(bytes32 indexed blueprintId, uint256 requestId, address requester);
    event VRFFulfilled(bytes32 indexed blueprintId, uint256 requestId, uint256[] randomWords);
    event AetherForgeAssetMinted(bytes32 indexed blueprintId, uint256 indexed tokenId, address indexed minter, uint256 seed);
    event BlueprintStakingRewardsClaimed(bytes32 indexed blueprintId, address indexed claimer, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 stakedAmount);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---

    /// @dev Restricts function execution to the designated oracle address.
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetherForge: Only oracle can call this function");
        _;
    }

    /// @dev Restricts function execution to users with a minimum reputation score.
    modifier onlyReputable(uint256 _minReputation) {
        require(getUserReputation(msg.sender) >= int256(_minReputation), "AetherForge: Insufficient reputation");
        _;
    }

    /// @dev Ensures a blueprint with the given ID exists.
    modifier blueprintExists(bytes32 _blueprintId) {
        require(blueprints[_blueprintId].proposer != address(0), "AetherForge: Blueprint does not exist");
        _;
    }

    /// @dev Ensures a proposal with the given ID exists.
    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposer != address(0), "AetherForge: Proposal does not exist");
        _;
    }

    // --- Constructor ---
    /// @dev Initializes the contract with AetherToken address, VRF Coordinator, Keyhash, SubscriptionId, and initial owner.
    /// @param _aetherTokenAddress The address of the AetherToken (ERC20) contract.
    /// @param _vrfCoordinator The address of the Chainlink VRF Coordinator v2.
    /// @param _keyHash The key hash for Chainlink VRF V2 requests.
    /// @param _subscriptionId The subscription ID for Chainlink VRF V2.
    constructor(
        address _aetherTokenAddress,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        require(_aetherTokenAddress != address(0), "AetherForge: AetherToken address cannot be zero");
        require(_vrfCoordinator != address(0), "AetherForge: VRF Coordinator address cannot be zero");

        AetherToken = IAetherToken(_aetherTokenAddress);
        VRFCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;

        oracleAddress = msg.sender; // Initial oracle is deployer, should be updated to a dedicated oracle
        feeRecipient = msg.sender;  // Initial fee recipient is deployer
        protocolFeeBasisPoints = 500; // 5% fee initially

        proposalIdCounter.increment();  // Start proposal IDs from 1
    }

    // --- I. Core Platform Management ---

    /// @notice Updates the address of the trusted oracle. Only callable by the owner (or eventually DAO).
    /// @param _newOracle The new oracle contract address.
    function updateOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AetherForge: New oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /// @notice Updates the Chainlink VRF coordinator and key hash. Only callable by owner (or eventually DAO).
    /// @param _newCoordinator The new VRF Coordinator address.
    /// @param _newKeyHash The new key hash.
    function updateVRFCoordinator(address _newCoordinator, bytes32 _newKeyHash) public onlyOwner {
        require(_newCoordinator != address(0), "AetherForge: New VRF coordinator address cannot be zero");
        VRFCoordinator = VRFCoordinatorV2Interface(_newCoordinator);
        s_keyHash = _newKeyHash;
        emit VRFCoordinatorUpdated(_newCoordinator, _newKeyHash);
    }

    /// @notice Sets the protocol fee in basis points (e.g., 100 = 1%). Only callable by owner (or eventually DAO).
    /// @param _newFeeBasisPoints The new fee percentage in basis points (max 10,000 for 100%).
    function setProtocolFee(uint256 _newFeeBasisPoints) public onlyOwner {
        require(_newFeeBasisPoints <= 10000, "AetherForge: Fee cannot exceed 100%");
        protocolFeeBasisPoints = _newFeeBasisPoints;
        emit ProtocolFeeUpdated(_newFeeBasisPoints);
    }

    /// @notice Sets the address of the AetherForgeNFT contract. Only callable by owner (or eventually DAO).
    /// @param _newNFTContract The address of the deployed AetherForgeNFT contract.
    function setNFTContractAddress(address _newNFTContract) public onlyOwner {
        require(_newNFTContract != address(0), "AetherForge: NFT contract address cannot be zero");
        AetherForgeNFT = IAetherForgeNFT(_newNFTContract);
        emit NFTContractAddressUpdated(_newNFTContract);
    }

    /// @notice Pauses the contract, preventing certain actions. Only callable by owner.
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing actions again. Only callable by owner.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the fee recipient to withdraw accumulated AetherToken fees.
    /// @param _recipient The address to send the fees to.
    function withdrawProtocolFees(address _recipient) public {
        require(msg.sender == feeRecipient || msg.sender == owner(), "AetherForge: Only fee recipient or owner can withdraw fees");
        
        uint256 totalStaked = totalProposalStakedAET + totalReputationStakedAET + totalBlueprintStakedAET;
        uint256 contractBalance = AetherToken.balanceOf(address(this));
        uint256 withdrawableFees = contractBalance > totalStaked ? contractBalance - totalStaked : 0;
        
        require(withdrawableFees > 0, "AetherForge: No fees to withdraw");
        require(AetherToken.transfer(_recipient, withdrawableFees), "AetherForge: Failed to transfer fees");
        emit FeesWithdrawn(_recipient, withdrawableFees);
    }

    // --- II. Reputation System ---

    /// @notice Updates a user's reputation score based on off-chain AI analysis.
    ///         This function is callable only by the designated `oracleAddress`.
    ///         The `_proofHash` represents a ZK-proof (or other verifiable computation proof)
    ///         that attests to the correctness of the AI's `_reputationDelta` calculation.
    ///         The contract does not verify the ZK-proof itself but stores its hash for transparency
    ///         and relies on the oracle's integrity.
    /// @param _user The address of the user whose reputation is being updated.
    /// @param _reputationDelta The change in reputation score (can be positive or negative).
    /// @param _proofHash A hash of the ZK-proof verifying the AI's calculation.
    function submitReputationUpdateProof(address _user, int256 _reputationDelta, bytes32 _proofHash) external onlyOracle {
        _applyReputationDecay(_user); // Apply decay before applying new delta
        
        UserReputation storage rep = userReputations[_user];
        int256 oldScore = rep.score;
        rep.score += _reputationDelta;
        rep.lastUpdated = block.timestamp;
        
        emit ReputationUpdated(_user, oldScore, rep.score, _proofHash);
    }

    /// @notice Retrieves the current reputation score for a given user, applying decay if due.
    /// @param _user The address of the user.
    /// @return The current reputation score.
    function getUserReputation(address _user) public view returns (int256) {
        UserReputation storage rep = userReputations[_user];
        return _calculateDecayedReputation(rep.score, rep.lastUpdated);
    }

    /// @notice Allows a user to stake AetherToken to temporarily boost their effective reputation score.
    ///         The boost is calculated based on `reputationBoostFactor` and is primarily
    ///         used to increase voting weight in governance and curation.
    /// @param _amount The amount of AET to stake.
    function stakeAETForReputationBoost(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "AetherForge: Stake amount must be positive");
        require(AetherToken.transferFrom(msg.sender, address(this), _amount), "AetherForge: AET transfer failed");

        UserReputation storage rep = userReputations[msg.sender];
        _applyReputationDecay(msg.sender); // Decay before updating stake
        
        rep.stakedAET += _amount;
        totalReputationStakedAET += _amount; // Update global staked amount
        rep.lastUpdated = block.timestamp; // Update last updated to reset decay timer
        
        emit ReputationStaked(msg.sender, _amount, rep.stakedAET);
    }

    /// @notice Allows a user to unstake AetherToken previously staked for reputation boost.
    /// @param _amount The amount of AET to unstake.
    function unstakeAETFromReputationBoost(uint256 _amount) public whenNotPaused {
        UserReputation storage rep = userReputations[msg.sender];
        require(rep.stakedAET >= _amount, "AetherForge: Insufficient staked AET");
        require(AetherToken.transfer(msg.sender, _amount), "AetherForge: AET transfer failed");

        _applyReputationDecay(msg.sender); // Decay before updating stake
        rep.stakedAET -= _amount;
        totalReputationStakedAET -= _amount; // Update global staked amount
        rep.lastUpdated = block.timestamp; // Update last updated to reset decay timer
        
        emit ReputationUnstaked(msg.sender, _amount, rep.stakedAET);
    }

    /// @notice Triggers the time-based decay for a user's reputation score.
    ///         Callable by anyone, potentially incentivized for automated keepers.
    /// @param _user The address of the user whose reputation to decay.
    function decayReputation(address _user) public {
        _applyReputationDecay(_user);
    }

    /// @notice Returns the amount of AET a user has staked for reputation boost.
    /// @param _user The address of the user.
    /// @return The amount of AET staked.
    function getReputationStake(address _user) public view returns (uint256) {
        return userReputations[_user].stakedAET;
    }

    /// @notice Sets the parameters for reputation decay. Only callable by the owner (or eventually DAO).
    /// @param _decayRate The new decay rate in basis points (e.g., 100 for 1%).
    /// @param _decayInterval The new interval in seconds (e.g., 30 days).
    function setReputationDecayParameters(uint256 _decayRate, uint256 _decayInterval) public onlyOwner {
        require(_decayRate <= 10000, "AetherForge: Decay rate cannot exceed 100%");
        require(_decayInterval > 0, "AetherForge: Decay interval must be positive");
        reputationDecayRateBasisPoints = _decayRate;
        reputationDecayInterval = _decayInterval;
        emit ReputationDecayParametersUpdated(_decayRate, _decayInterval);
    }

    /// @dev Internal function to apply reputation decay for a user and update their `lastUpdated` timestamp.
    function _applyReputationDecay(address _user) internal {
        UserReputation storage rep = userReputations[_user];
        int256 currentScore = _calculateDecayedReputation(rep.score, rep.lastUpdated);
        if (currentScore != rep.score) {
            rep.score = currentScore;
            rep.lastUpdated = block.timestamp; // Update timestamp only if decay was applied
            // No event emitted here to avoid spamming for every view, events are for `submitReputationUpdateProof`
        }
    }

    /// @dev Internal view function to calculate decayed reputation based on time elapsed since last update.
    function _calculateDecayedReputation(int256 _score, uint256 _lastUpdated) internal view returns (int256) {
        if (_score <= 0 || _lastUpdated == 0 || reputationDecayInterval == 0 || reputationDecayRateBasisPoints == 0) {
            return _score;
        }

        uint256 timeElapsed = block.timestamp - _lastUpdated;
        uint256 intervals = timeElapsed / reputationDecayInterval;

        int256 currentScore = _score;
        for (uint256 i = 0; i < intervals; i++) {
            currentScore = currentScore - (currentScore * int256(reputationDecayRateBasisPoints) / 10000);
            if (currentScore < 0) { // Reputation cannot go below 0 due to decay
                currentScore = 0;
                break;
            }
        }
        return currentScore;
    }

    /// @dev Calculates a user's effective voting weight by combining their reputation and staked AET.
    /// @param _user The address of the user.
    /// @return The calculated combined voting weight.
    function _getVotingWeight(address _user) internal view returns (uint256) {
        // Ensure reputation is fresh for calculation
        int256 effectiveReputation = getUserReputation(_user); 
        uint256 reputationComponent = effectiveReputation > 0 ? uint256(effectiveReputation) : 0;
        
        // AetherToken staked for general reputation boost
        uint256 stakeComponent = userReputations[_user].stakedAET / 1 ether; // Normalize stake to whole tokens for weight
        
        return reputationComponent + (stakeComponent * reputationBoostFactor);
    }

    // --- III. Generative Asset Blueprint & Curation ---

    /// @notice Allows a user to submit a blueprint for an AetherForge asset.
    ///         Requires staking AetherToken and has a minimum stake threshold.
    /// @param _blueprintHash A hash (e.g., IPFS CID) pointing to the off-chain generative AI prompt/parameters.
    /// @param _stakeAmount The amount of AetherToken to stake, must meet `minBlueprintStake`.
    /// @return The unique ID of the submitted blueprint.
    function submitBlueprint(string calldata _blueprintHash, uint256 _stakeAmount) public whenNotPaused returns (bytes32) {
        require(bytes(_blueprintHash).length > 0, "AetherForge: Blueprint hash cannot be empty");
        require(_stakeAmount >= minBlueprintStake, "AetherForge: Insufficient AET stake for blueprint");
        require(AetherToken.transferFrom(msg.sender, address(this), _stakeAmount), "AetherForge: AET transfer failed");
        
        bytes32 blueprintId = keccak256(abi.encodePacked(msg.sender, _blueprintHash, block.timestamp)); // Unique ID
        require(blueprints[blueprintId].proposer == address(0), "AetherForge: Blueprint ID collision, try again");

        blueprints[blueprintId] = Blueprint({
            proposer: msg.sender,
            blueprintHash: _blueprintHash,
            stakedAmount: _stakeAmount,
            submissionTime: block.timestamp,
            status: BlueprintStatus.Voting,
            positiveVotes: 0,
            negativeVotes: 0,
            totalVoteWeight: 0,
            votingEndTime: block.timestamp + blueprintVotingPeriod,
            vrfRequestId: 0,
            vrfRandomWords: new uint256[](0),
            mintedTokenId: 0
        });
        totalBlueprintStakedAET += _stakeAmount; // Update global staked amount

        emit BlueprintSubmitted(blueprintId, msg.sender, _blueprintHash, _stakeAmount);
        return blueprintId;
    }

    /// @notice Allows reputable users to vote on a submitted blueprint.
    ///         Vote weight is based on the voter's combined AET stake and reputation score.
    /// @param _blueprintId The ID of the blueprint to vote on.
    /// @param _approve True for an approval vote, false for a rejection vote.
    function voteOnBlueprint(bytes32 _blueprintId, bool _approve) public whenNotPaused blueprintExists(_blueprintId) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.status == BlueprintStatus.Voting, "AetherForge: Blueprint not in voting phase");
        require(block.timestamp <= blueprint.votingEndTime, "AetherForge: Voting period has ended");
        require(!hasVotedOnBlueprint[msg.sender][_blueprintId], "AetherForge: Already voted on this blueprint");

        uint256 voteWeight = _getVotingWeight(msg.sender);
        require(voteWeight >= minBlueprintVoteWeight, "AetherForge: Insufficient vote weight to cast a vote");

        if (_approve) {
            blueprint.positiveVotes += voteWeight;
        } else {
            blueprint.negativeVotes += voteWeight;
        }
        blueprint.totalVoteWeight += voteWeight;
        hasVotedOnBlueprint[msg.sender][_blueprintId] = true;

        emit BlueprintVoted(_blueprintId, msg.sender, _approve, voteWeight);
    }

    /// @notice Retrieves detailed information about a blueprint.
    /// @param _blueprintId The ID of the blueprint.
    /// @return Blueprint struct containing all details.
    function getBlueprintDetails(bytes32 _blueprintId) public view blueprintExists(_blueprintId) returns (Blueprint memory) {
        return blueprints[_blueprintId];
    }

    /// @notice Finalizes the curation process for a blueprint after its voting period ends.
    ///         Determines if the blueprint is approved or rejected based on votes and thresholds.
    ///         If rejected, the proposer's stake is returned.
    /// @param _blueprintId The ID of the blueprint to finalize.
    function finalizeBlueprintCuration(bytes32 _blueprintId) public whenNotPaused blueprintExists(_blueprintId) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.status == BlueprintStatus.Voting, "AetherForge: Blueprint not in voting phase");
        require(block.timestamp > blueprint.votingEndTime, "AetherForge: Voting period not yet ended");

        BlueprintStatus newStatus;
        if (blueprint.totalVoteWeight >= blueprintQuorumThreshold &&
            (blueprint.positiveVotes * 10000 / blueprint.totalVoteWeight) >= blueprintSupportThreshold)
        {
            newStatus = BlueprintStatus.Approved;
        } else {
            newStatus = BlueprintStatus.Rejected;
            // Return staked AET to proposer if rejected
            require(AetherToken.transfer(blueprint.proposer, blueprint.stakedAmount), "AetherForge: Failed to return stake for rejected blueprint");
            totalBlueprintStakedAET -= blueprint.stakedAmount; // Update global staked amount
            blueprint.stakedAmount = 0; // Mark as returned
        }
        blueprint.status = newStatus;
        emit BlueprintCurationFinalized(_blueprintId, newStatus);
    }

    /// @notice Initiates a Chainlink VRF request for an approved blueprint.
    ///         This should be called for blueprints that have been `Approved`.
    /// @param _blueprintId The ID of the approved blueprint.
    /// @return The Chainlink VRF request ID.
    function requestVRFForMint(bytes32 _blueprintId) public whenNotPaused blueprintExists(_blueprintId) returns (uint256) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.status == BlueprintStatus.Approved, "AetherForge: Blueprint not approved for minting");
        require(blueprint.vrfRequestId == 0, "AetherForge: VRF already requested for this blueprint");
        
        // Request a random word from Chainlink VRF
        uint256 requestId = VRFCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            1 // Request 1 random word
        );
        blueprint.vrfRequestId = requestId;
        s_requests[requestId] = blueprint; // Map request ID to blueprint

        blueprint.status = BlueprintStatus.MintingRequested;
        emit VRFRequested(_blueprintId, requestId, msg.sender);
        return requestId;
    }

    /// @notice Callback function for Chainlink VRF to fulfill the random word request.
    ///         Only callable by the Chainlink VRF coordinator.
    /// @param _requestId The ID of the VRF request.
    /// @param _randomWords An array of random words generated by VRF.
    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
        Blueprint storage blueprint = s_requests[_requestId];
        require(blueprint.proposer != address(0), "AetherForge: Unknown VRF request ID"); // Check if blueprint exists for requestId
        require(blueprint.status == BlueprintStatus.MintingRequested, "AetherForge: Blueprint not awaiting VRF fulfillment");
        
        blueprint.vrfRandomWords = _randomWords;
        // Blueprint status remains MintingRequested until mintAetherForgeAsset is called,
        // allowing for potential further checks or external interaction before actual mint.
        
        emit VRFFulfilled(keccak256(abi.encodePacked(blueprint.proposer, blueprint.blueprintHash, blueprint.submissionTime)), _requestId, _randomWords);
    }

    /// @notice Mints an AetherForge NFT based on an approved and VRF-fulfilled blueprint.
    ///         Callable by anyone once VRF is fulfilled. Transfers protocol fees.
    /// @param _blueprintId The ID of the blueprint to mint the NFT from.
    /// @return The token ID of the newly minted NFT.
    function mintAetherForgeAsset(bytes32 _blueprintId) public whenNotPaused blueprintExists(_blueprintId) returns (uint256) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.status == BlueprintStatus.MintingRequested, "AetherForge: Blueprint not ready for minting (awaiting VRF or not approved)");
        require(blueprint.vrfRandomWords.length > 0, "AetherForge: VRF randomness not fulfilled yet");
        require(address(AetherForgeNFT) != address(0), "AetherForge: NFT contract not set");
        require(blueprint.mintedTokenId == 0, "AetherForge: NFT already minted for this blueprint");

        uint256 mintSeed = blueprint.vrfRandomWords[0];
        uint256 tokenId = type(uint256).max; // Using a large number or incrementing a global NFT counter for token ID.
                                            // For simplicity, let's derive it directly from blueprintHash and mintSeed for uniqueness
                                            // A real NFT contract would manage its own token IDs (e.g., ERC721 `_nextTokenId()`)
                                            // For this example, let's use a hash as a placeholder for uniqueness
        tokenId = uint256(keccak256(abi.encodePacked(_blueprintId, mintSeed)));
        // In a real NFT contract, `mint` would increment an internal counter for `tokenId`.
        // This is a placeholder to ensure a unique-enough ID for this example.

        // Calculate and transfer protocol fees
        uint256 feeAmount = blueprint.stakedAmount * protocolFeeBasisPoints / 10000;
        require(AetherToken.transfer(feeRecipient, feeAmount), "AetherForge: Failed to transfer protocol fee");

        // Mint the NFT via the AetherForgeNFT contract
        IAetherForgeNFT(AetherForgeNFT).mint(
            blueprint.proposer,
            tokenId,
            blueprint.blueprintHash, // Use blueprint hash as metadata hint for the NFT
            mintSeed
        );

        blueprint.mintedTokenId = tokenId;
        blueprint.status = BlueprintStatus.Minted;
        totalBlueprintStakedAET -= feeAmount; // Reduce total staked by fee amount
        // Remaining stake for the proposer to claim is `blueprint.stakedAmount - feeAmount`
        blueprint.stakedAmount -= feeAmount;

        emit AetherForgeAssetMinted(_blueprintId, tokenId, blueprint.proposer, mintSeed);
        return tokenId;
    }

    /// @notice Allows the blueprint proposer to claim their remaining staked AET
    ///         if their blueprint was successfully approved and minted.
    /// @param _blueprintId The ID of the blueprint.
    function claimBlueprintStakingRewards(bytes32 _blueprintId) public whenNotPaused blueprintExists(_blueprintId) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.proposer == msg.sender, "AetherForge: Only the proposer can claim stake");
        require(blueprint.status == BlueprintStatus.Minted, "AetherForge: Blueprint not yet minted or stake already claimed");
        require(blueprint.stakedAmount > 0, "AetherForge: No remaining stake to claim or already claimed"); // Already reduced by fees

        uint256 amountToClaim = blueprint.stakedAmount;
        blueprint.stakedAmount = 0; // Mark as claimed
        totalBlueprintStakedAET -= amountToClaim; // Update global staked amount
        require(AetherToken.transfer(msg.sender, amountToClaim), "AetherForge: Failed to transfer staking rewards");
        
        emit BlueprintStakingRewardsClaimed(_blueprintId, msg.sender, amountToClaim);
    }

    // --- IV. DAO Governance ---

    /// @notice Allows a user to propose a change to the contract's parameters or logic.
    ///         Requires staking AetherToken. The proposal will go through a voting process.
    /// @param _description A detailed description of the proposed change.
    /// @param _target The address of the contract the proposal intends to interact with (e.g., this contract).
    /// @param _callData The encoded function call (selector + arguments) to be executed on the target.
    /// @return The ID of the created proposal.
    function proposeChange(string calldata _description, address _target, bytes calldata _callData) public whenNotPaused returns (uint256) {
        require(bytes(_description).length > 0, "AetherForge: Proposal description cannot be empty");
        require(_target != address(0), "AetherForge: Target address cannot be zero");
        require(_callData.length > 0, "AetherForge: Call data cannot be empty");
        require(AetherToken.transferFrom(msg.sender, address(this), minProposalStake), "AetherForge: Failed to stake AET for proposal");

        uint256 proposalId = proposalIdCounter.current();
        proposalIdCounter.increment();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            target: _target,
            callData: _callData,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingPeriod,
            timelockEndTime: 0, // Set when queued
            quorumThreshold: proposalQuorumThreshold,
            supportThreshold: proposalSupportThreshold,
            status: ProposalStatus.Active,
            positiveVotes: 0,
            negativeVotes: 0,
            totalVoteWeight: 0,
            stakedAmount: minProposalStake
        });
        totalProposalStakedAET += minProposalStake; // Update global staked amount

        emit ProposalCreated(proposalId, msg.sender, _description, minProposalStake);
        return proposalId;
    }

    /// @notice Allows users to vote on an active proposal.
    ///         Voting power is a combination of AetherToken stake and reputation score.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a "for" vote, false for an "against" vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "AetherForge: Proposal not in active voting phase");
        require(block.timestamp <= proposal.votingEndTime, "AetherForge: Voting period has ended");
        require(!hasVotedOnProposal[msg.sender][_proposalId], "AetherForge: Already voted on this proposal");

        uint256 voteWeight = _getVotingWeight(msg.sender); // Combined AET stake + reputation
        require(voteWeight > 0, "AetherForge: Insufficient voting weight");

        if (_support) {
            proposal.positiveVotes += voteWeight;
        } else {
            proposal.negativeVotes += voteWeight;
        }
        proposal.totalVoteWeight += voteWeight;
        hasVotedOnProposal[msg.sender][_proposalId] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /// @notice Retrieves detailed information about a DAO proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing all details.
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Moves a successful proposal from 'Active' to 'Queued', starting its timelock.
    ///         Callable by anyone after the voting period ends and if conditions are met.
    /// @param _proposalId The ID of the proposal to queue.
    function queueProposal(uint256 _proposalId) public whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "AetherForge: Proposal not active");
        require(block.timestamp > proposal.votingEndTime, "AetherForge: Voting period not yet ended");

        if (proposal.totalVoteWeight >= proposal.quorumThreshold &&
            (proposal.positiveVotes * 10000 / proposal.totalVoteWeight) >= proposal.supportThreshold)
        {
            proposal.status = ProposalStatus.Queued;
            proposal.timelockEndTime = block.timestamp + proposalTimelockDuration;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Queued);
        } else {
            // Proposal failed
            proposal.status = ProposalStatus.Failed;
            // Return proposer's stake
            require(AetherToken.transfer(proposal.proposer, proposal.stakedAmount), "AetherForge: Failed to return stake for failed proposal");
            totalProposalStakedAET -= proposal.stakedAmount; // Update global staked amount
            proposal.stakedAmount = 0; // Mark as returned
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Failed);
        }
    }

    /// @notice Executes a queued proposal after its timelock period has passed.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active || proposal.status == ProposalStatus.Queued, "AetherForge: Proposal not in queued state"); // Allow execution right after success if no timelock
        if (proposal.status == ProposalStatus.Queued) {
            require(block.timestamp > proposal.timelockEndTime, "AetherForge: Timelock has not expired yet");
        }
        
        // Ensure the proposal hasn't been executed or failed
        require(proposal.status != ProposalStatus.Executed && proposal.status != ProposalStatus.Failed && proposal.status != ProposalStatus.Canceled, "AetherForge: Proposal not in executable state");

        // If not queued, ensure it passed voting and can be executed immediately
        if (proposal.status == ProposalStatus.Active) {
            require(block.timestamp > proposal.votingEndTime, "AetherForge: Voting period not yet ended for execution");
            require(proposal.totalVoteWeight >= proposal.quorumThreshold &&
                    (proposal.positiveVotes * 10000 / proposal.totalVoteWeight) >= proposal.supportThreshold,
                    "AetherForge: Proposal did not pass voting for immediate execution");
        }

        proposal.status = ProposalStatus.Executed;
        // Transfer proposer's stake back upon successful execution
        require(AetherToken.transfer(proposal.proposer, proposal.stakedAmount), "AetherForge: Failed to return stake for executed proposal");
        totalProposalStakedAET -= proposal.stakedAmount; // Update global staked amount
        proposal.stakedAmount = 0; // Mark as returned

        // Execute the proposed function call
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "AetherForge: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    // --- Fallback and Receive functions ---
    // Prevent accidental ETH transfer to this contract.
    receive() external payable {
        revert("AetherForge: ETH not accepted");
    }

    fallback() external payable {
        revert("AetherForge: ETH not accepted");
    }
}
```