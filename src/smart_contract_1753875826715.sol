This smart contract, `EvolveVerseNexus`, embodies a Decentralized AI-Curated Adaptive Ecosystem. It integrates several advanced and creative concepts:
1.  **AI-Driven Adaptive Assets (dNFTs):** NFTs that dynamically evolve based on external AI Oracle judgments.
2.  **Reputation System & Epoch Staking:** Users stake reputation tokens (RTs) into themed epoch pools to influence asset evolution and participate in governance.
3.  **ZK-Proof Attribution (Conceptual):** Hooks for privacy-preserving contributions, allowing users to prove hidden work related to assets.
4.  **Dynamic Royalties:** Flexible royalty rates for Adaptive Assets, adjustable by originators or governance.
5.  **On-chain Challenges/Bounties:** A mechanism for the community to create and fulfill tasks related to assets.
6.  **Decentralized Protocol Governance:** A basic DAO-like structure for proposing and voting on core system parameters.

The design avoids directly duplicating large open-source libraries by implementing minimal, custom interfaces for `ReputationToken` (ERC-20 like) and `AdaptiveAsset` (ERC-721 like) that specifically serve the Nexus's needs, thus focusing the novelty on the interaction logic rather than standard token implementations.

---

## EvolveVerseNexus Smart Contract

**Outline:**

*   **I. Core Infrastructure & Interfaces:** Defines external contract interfaces (`IAIOracle`, `IReputationToken`, `IAdaptiveAsset`) to manage dependencies.
*   **II. EvolveVerseNexus: The Main Smart Contract:**
    *   **A. Storage & State Variables:** Defines all the data structures (structs, mappings) for assets, proposals, epoch pools, challenges, and governance.
    *   **B. Events:** Declarations for logging key actions, crucial for off-chain indexing and UI.
    *   **C. Modifiers:** Custom access control (`onlyAIOracle`) and state checks (`whenNotPaused`).
    *   **D. Constructor & Core Administration (Functions 1-5):** Initialization and system-level controls (pause/unpause).
    *   **E. Adaptive Asset (AA) Management (Functions 6-10):** Logic for creating, viewing, proposing, and approving evolution paths for dynamic NFTs.
    *   **F. Reputation & Staking (Functions 11-15):** Handles staking/unstaking Reputation Tokens in epoch pools, delegation, and distribution.
    *   **G. Epoch Pools & Influence (Functions 16-19):** Creation, information retrieval, influence calculation, and finalization of epoch-based staking pools.
    *   **H. Advanced & Dynamic Concepts (Functions 20-28):** Integrates ZK-proofs, challenges, dynamic royalties, and on-chain governance.
*   **III. Supporting Contracts (Minimal Implementations for Demonstration):**
    *   **A. ReputationToken:** A simplified ERC-20 token used for reputation points within the ecosystem.
    *   **B. AdaptiveAsset:** A simplified ERC-721 token representing the dynamic NFTs.
    *   **C. AIOracleMock:** A mock contract to simulate the external AI Oracle's behavior for testing.

**Function Summary (28 Functions):**

1.  `constructor(address _initialAIOracle, address _initialReputationToken, address _initialAdaptiveAsset)`: Initializes the Nexus, linking it to the AI Oracle, Reputation Token, and Adaptive Asset contracts.
2.  `setAIOracleAddress(address _newOracle)`: Allows the owner to update the AI Oracle contract address.
3.  `setReputationTokenAddress(address _newRT)`: Allows the owner to update the Reputation Token contract address.
4.  `pauseSystem()`: Allows the owner to pause core system operations for maintenance or emergencies.
5.  `unpauseSystem()`: Allows the owner to unpause the system.
6.  `createAdaptiveAsset(string memory _initialMetadataURI)`: Mints a new Adaptive Asset (AA) NFT to the caller, who becomes its originator.
7.  `getAssetInfo(uint256 _assetId)`: Retrieves detailed information about an Adaptive Asset.
8.  `proposeEvolutionPath(uint256 _assetId, string memory _newMetadataURI, bytes32 _aiJudgmentHash)`: An AA originator proposes a future evolution state for their asset, including a hash of the expected AI judgment.
9.  `approveEvolutionProposal(uint256 _assetId, uint256 _proposalId, bytes memory _aiSignedData)`: The designated AI Oracle verifies and confirms an evolution proposal using cryptographically signed data, triggering the asset's evolution.
10. `getAssetEvolutionHistory(uint256 _assetId)`: Returns the current metadata URI of an asset. (Note: A full history would typically be reconstructed off-chain from events).
11. `stakeReputation(uint256 _amount, uint256 _epochPoolId)`: Allows a user to stake Reputation Tokens (RTs) into a specific Epoch Pool to influence asset evolution.
12. `unstakeReputation(uint256 _amount, uint256 _epochPoolId)`: Allows a user to unstake RTs from an Epoch Pool.
13. `delegateReputation(address _delegatee, uint256 _amount)`: Allows a user to conceptually delegate their influence/voting power in RTs to another address.
14. `undelegateReputation(address _delegatee, uint256 _amount)`: Allows a user to revoke a portion of their delegated RTs.
15. `distributeReputation(address _recipient, uint256 _amount)`: A system function (callable by owner or specific roles) to mint and distribute Reputation Tokens, e.g., for rewards.
16. `createEpochPool(string memory _theme, uint256 _durationSeconds)`: Allows an authorized role (owner) to create a new Epoch Pool for focused staking influence.
17. `getEpochPoolInfo(uint256 _poolId)`: Retrieves details about an Epoch Pool, including total staked reputation.
18. `calculateAssetInfluenceScore(uint256 _assetId, uint256 _epochPoolId)`: Returns the total Reputation Tokens staked within a given Epoch Pool, indicating its potential collective influence.
19. `finalizeEpoch(uint256 _poolId)`: Callable by anyone after an epoch's duration, signaling its completion and potentially triggering reward distributions.
20. `submitZKAttributionProof(uint256 _assetId, bytes memory _proof, bytes32 _publicInputHash)`: Allows a user to submit a ZK-proof for a private contribution related to an asset.
21. `verifyZKProofForAttribution(uint256 _assetId, bytes memory _proof, bytes32 _publicInputHash)`: An authorized role (e.g., owner) can mark a submitted ZK-proof as verified, conceptually unlocking benefits. (Note: Actual on-chain ZK verification is complex and not fully implemented here).
22. `createChallenge(string memory _description, uint256 _rewardRT, uint256 _targetAssetId, uint256 _deadline)`: Allows anyone to create a challenge/bounty linked to an Adaptive Asset, offering an RT reward.
23. `fulfillChallenge(uint256 _challengeId, bytes memory _proofOfWork)`: Allows a user to submit their solution/proof for a challenge, receiving the reward instantly for this example.
24. `setDynamicRoyaltyRate(uint256 _assetId, uint256 _newRatePermil)`: Allows the AA originator (or governance) to set a dynamic royalty rate (in permil) for their asset.
25. `withdrawDynamicRoyalties(uint256 _assetId)`: Allows the originator of an AA to withdraw accumulated royalties (requires external marketplaces to deposit funds).
26. `depositRoyaltiesForAsset(uint256 _assetId)`: Allows an external marketplace or contract to deposit native currency (ETH) royalties for a specific asset.
27. `proposeProtocolParameterChange(string memory _description, bytes32 _paramKey, uint256 _newValue)`: Initiates a governance proposal to change a core protocol parameter.
28. `voteOnProtocolParameterChange(uint256 _proposalId, bool _support)`: Allows users to vote on an active governance proposal using their direct Reputation Token balance.
29. `executeProtocolParameterChange(uint256 _proposalId)`: Executes a governance proposal if it has met the voting quorum and threshold after the voting period ends.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For AI Oracle signature verification

// Outline:
// I. Core Infrastructure & Interfaces
//    - IAIOracle: Interface for the AI Oracle contract.
//    - IReputationToken: Interface for the custom Reputation Token (ERC-20 like).
//    - IAdaptiveAsset: Interface for the custom Adaptive Asset (ERC-721 like).
// II. EvolveVerseNexus: The Main Smart Contract
//    A. Storage & State Variables
//       - Counters for asset IDs, proposal IDs, epoch pool IDs, challenge IDs.
//       - Mappings for assets, proposals, epoch pools, challenges, and protocol parameters.
//       - Addresses for AI Oracle and Reputation Token contracts.
//       - Governance-related mappings (voters, proposals).
//    B. Events: To signal state changes off-chain.
//    C. Modifiers: Custom access control and state checks.
//    D. Constructor & Core Administration (Functions 1-5)
//    E. Adaptive Asset (AA) Management (Functions 6-10)
//    F. Reputation & Staking (Functions 11-15)
//    G. Epoch Pools & Influence (Functions 16-19)
//    H. Advanced & Dynamic Concepts (Functions 20-28)
// III. Supporting Contracts (Minimal Implementations for demonstration)
//    A. ReputationToken: A simplified ERC-20 for reputation points.
//    B. AdaptiveAsset: A simplified ERC-721 for dynamic NFTs.
//    C. AIOracleMock: A mock AI Oracle for testing purposes.

// Function Summary:
// 1.  constructor(address _initialAIOracle, address _initialReputationToken, address _initialAdaptiveAsset): Initializes the Nexus, setting up the AI Oracle and Reputation Token addresses.
// 2.  setAIOracleAddress(address _newOracle): Allows the owner to update the AI Oracle contract address.
// 3.  setReputationTokenAddress(address _newRT): Allows the owner to update the Reputation Token contract address.
// 4.  pauseSystem(): Allows the owner to pause core system operations for maintenance.
// 5.  unpauseSystem(): Allows the owner to unpause the system.
// 6.  createAdaptiveAsset(string memory _initialMetadataURI): Mints a new Adaptive Asset (AA) NFT, assigning it to the caller.
// 7.  getAssetInfo(uint256 _assetId): Retrieves detailed information about an Adaptive Asset.
// 8.  proposeEvolutionPath(uint256 _assetId, string memory _newMetadataURI, bytes32 _aiJudgmentHash): An AA originator proposes a future evolution state for their asset, including a hash representing the expected AI judgment data.
// 9.  approveEvolutionProposal(uint256 _assetId, uint256 _proposalId, bytes memory _aiSignedData): The designated AI Oracle verifies and confirms an evolution proposal using signed data, triggering the asset's evolution if conditions are met.
// 10. getAssetEvolutionHistory(uint256 _assetId): Returns the list of all past metadata URIs, providing an evolution history. (In this simplified example, it returns the current URI, actual history would be from event logs or an array).
// 11. stakeReputation(uint256 _amount, uint256 _epochPoolId): Allows a user to stake Reputation Tokens (RTs) into a specific Epoch Pool to influence asset evolution.
// 12. unstakeReputation(uint256 _amount, uint256 _epochPoolId): Allows a user to unstake RTs from an Epoch Pool.
// 13. delegateReputation(address _delegatee, uint256 _amount): Allows a user to delegate their voting/influence power in RTs to another address.
// 14. undelegateReputation(address _delegatee, uint256 _amount): Allows a user to revoke a portion of their delegated RTs.
// 15. distributeReputation(address _recipient, uint256 _amount): A system function (callable by owner or specific roles) to mint and distribute Reputation Tokens, e.g., for rewards or achievements.
// 16. createEpochPool(string memory _theme, uint256 _durationSeconds): Allows an authorized role to create a new Epoch Pool for focused staking influence.
// 17. getEpochPoolInfo(uint256 _poolId): Retrieves details about an Epoch Pool, including total staked reputation.
// 18. calculateAssetInfluenceScore(uint256 _assetId, uint256 _epochPoolId): Calculates the current influence score an asset has within a specific Epoch Pool, based on staked reputation and AI judgment. (Conceptual: AI judgment acts as a multiplier).
// 19. finalizeEpoch(uint256 _poolId): Callable by anyone after epoch duration; processes epoch results, potentially rewarding stakers or triggering final asset evolutions.
// 20. submitZKAttributionProof(uint256 _assetId, bytes memory _proof, bytes32 _publicInputHash): Allows a user to submit a ZK-proof attesting to a private contribution related to an asset. The proof is stored for potential later verification.
// 21. verifyZKProofForAttribution(uint256 _assetId, bytes memory _proof, bytes32 _publicInputHash): An authorized role (e.g., owner or specialized verifier) can mark a submitted ZK-proof as verified. (Note: Actual on-chain ZK verification is complex and typically requires precompiles or custom circuits; this is a placeholder).
// 22. createChallenge(string memory _description, uint256 _rewardRT, uint256 _targetAssetId, uint256 _deadline): Allows anyone to create a challenge/bounty linked to an Adaptive Asset, with an RT reward.
// 23. fulfillChallenge(uint256 _challengeId, bytes memory _proofOfWork): Allows a user to submit their solution/proof for a challenge. Rewards are instantly distributed for this example.
// 24. setDynamicRoyaltyRate(uint256 _assetId, uint256 _newRatePermil): Allows the AA originator or governance to set a dynamic royalty rate for an asset (e.g., 50 permil = 5%).
// 25. withdrawDynamicRoyalties(uint256 _assetId): Allows the originator of an AA to withdraw accumulated royalties (requires external sales mechanism to deposit funds).
// 26. depositRoyaltiesForAsset(uint256 _assetId): Allows an external marketplace or contract to deposit native currency royalties for a specific asset.
// 27. proposeProtocolParameterChange(string memory _description, bytes32 _paramKey, uint256 _newValue): Initiates a governance proposal to change a core protocol parameter.
// 28. voteOnProtocolParameterChange(uint256 _proposalId, bool _support): Allows users to vote on an active governance proposal using their direct reputation token balance.
// 29. executeProtocolParameterChange(uint256 _proposalId): Executes a governance proposal if it has met the voting quorum and threshold.

// I. Core Infrastructure & Interfaces

interface IAIOracle {
    // This interface defines how the EvolveVerseNexus interacts with an off-chain AI Oracle.
    // The oracle is responsible for verifying the authenticity and integrity of AI judgments.
    // In a real scenario, this would involve cryptographic signatures and potentially
    // complex data structures to prove the AI's "judgment" on an asset's evolution.
    // For this example, it's simplified to a signed message verification.
    function verifyAISignedData(bytes32 _digest, bytes memory _signature) external view returns (bool);
    function getAISignatureAddress() external view returns (address);
}

interface IReputationToken {
    // A simplified ERC-20 interface for the Reputation Token
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // Custom minting/burning functions, callable only by authorized contracts (like EvolveVerseNexus)
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
}

interface IAdaptiveAsset {
    // A simplified ERC-721 interface for the Adaptive Asset NFTs
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint255);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // Custom minting and metadata update functions, callable only by EvolveVerseNexus
    function mint(address to, uint256 tokenId, string memory uri) external;
    function updateMetadataURI(uint256 tokenId, string memory newURI) external;
}


// II. EvolveVerseNexus: The Main Smart Contract

contract EvolveVerseNexus is Ownable, Pausable {
    using Counters for Counters.Counter;

    // A. Storage & State Variables

    // Counters for unique IDs
    Counters.Counter private _assetIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _epochPoolIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _protocolProposalIds;

    // Contract interfaces
    IAIOracle public aiOracle;
    IReputationToken public reputationToken;
    IAdaptiveAsset public adaptiveAsset;

    // Structs for core entities
    struct AdaptiveAsset {
        uint256 id;
        address originator;
        string currentMetadataURI;
        uint256 currentEvolutionStage;
        uint256 lastEvolutionTime;
        uint256 dynamicRoyaltyRatePermil; // e.g., 50 permil = 5%
        uint256 accumulatedRoyalties; // In native token (ETH/Matic)
        bytes32 zkProofAttributionHash; // Stores the hash of public inputs for a submitted ZK proof
        bool zkProofVerified;
    }
    mapping(uint256 => AdaptiveAsset) public adaptiveAssets;
    
    struct EvolutionProposal {
        uint256 assetId;
        address proposer;
        string newMetadataURI;
        bytes32 aiJudgmentHash; // Hash of the AI's expected judgment data (e.g., keccak256(abi.encodePacked("AI Judgment Data for Asset X")))
        uint256 submittedTime;
        bool aiApproved;
        uint256 approvalTime;
        bool executed;
    }
    mapping(uint256 => EvolutionProposal) public evolutionProposals;

    struct EpochPool {
        uint256 id;
        string theme; // e.g., "Artistic Merit", "Technical Innovation", "Community Impact"
        uint256 startTime;
        uint256 durationSeconds;
        uint256 totalStakedReputation;
        mapping(address => uint256) stakedReputationByUser;
    }
    mapping(uint256 => EpochPool) public epochPools;
    
    // Mapping for conceptual reputation delegation for governance voting (not epoch staking)
    mapping(address => mapping(address => uint256)) public reputationDelegations; // delegator => delegatee => amount

    struct Challenge {
        uint256 id;
        address creator;
        string description;
        uint256 rewardRT; // Reputation Token reward
        uint256 targetAssetId;
        uint256 deadline;
        bool fulfilled;
        address fulfiller;
        bytes proofOfWork; // Placeholder for actual proof submission, e.g., IPFS hash
    }
    mapping(uint256 => Challenge) public challenges;

    struct ProtocolParameter {
        bytes32 key;
        uint256 value;
    }
    mapping(bytes32 => ProtocolParameter) public protocolParameters;

    struct ProtocolProposal {
        uint256 id;
        string description;
        bytes32 paramKey;
        uint256 newValue;
        uint256 quorumRequiredPermil; // Percentage (e.g., 5000 for 50%)
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalReputationSnapshot; // Snapshot of total RT supply for quorum calculation
        mapping(address => bool) hasVoted; // User => Voted status
        uint256 proposalEndTime;
        bool executed;
    }
    mapping(uint256 => ProtocolProposal) public protocolProposals;

    // B. Events
    event AdaptiveAssetCreated(uint256 indexed assetId, address indexed originator, string initialMetadataURI);
    event EvolutionProposalSubmitted(uint256 indexed assetId, uint256 indexed proposalId, address indexed proposer, string newMetadataURI, bytes32 aiJudgmentHash);
    event EvolutionProposalApproved(uint256 indexed assetId, uint256 indexed proposalId, uint256 newStage, string newMetadataURI);
    event ReputationStaked(address indexed user, uint256 indexed epochPoolId, uint256 amount);
    event ReputationUnstaked(address indexed user, uint256 indexed epochPoolId, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationDistributed(address indexed recipient, uint256 amount);
    event EpochPoolCreated(uint256 indexed poolId, string theme, uint256 durationSeconds);
    event EpochFinalized(uint256 indexed poolId, uint256 totalStakedReputation);
    event ZKAttributionProofSubmitted(uint256 indexed assetId, address indexed submitter, bytes32 publicInputHash);
    event ZKAttributionProofVerified(uint256 indexed assetId, bytes32 publicInputHash);
    event ChallengeCreated(uint256 indexed challengeId, address indexed creator, uint256 targetAssetId, uint256 rewardRT);
    event ChallengeFulfilled(uint256 indexed challengeId, address indexed fulfiller);
    event DynamicRoyaltyRateSet(uint256 indexed assetId, uint256 newRatePermil);
    event RoyaltiesWithdrawn(uint256 indexed assetId, address indexed receiver, uint256 amount);
    event RoyaltiesDeposited(uint256 indexed assetId, uint256 amount);
    event ProtocolParameterChangeProposed(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event ProtocolParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProtocolParameterChangeExecuted(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);

    // C. Modifiers
    modifier onlyAIOracle() {
        require(msg.sender == aiOracle.getAISignatureAddress(), "EVN: Caller is not the AI Oracle");
        _;
    }

    // D. Constructor & Core Administration

    /**
     * @dev Initializes the EvolveVerseNexus contract.
     * @param _initialAIOracle Address of the AI Oracle contract.
     * @param _initialReputationToken Address of the Reputation Token contract.
     * @param _initialAdaptiveAsset Address of the Adaptive Asset (NFT) contract.
     */
    constructor(address _initialAIOracle, address _initialReputationToken, address _initialAdaptiveAsset) Ownable(msg.sender) Pausable() {
        require(_initialAIOracle != address(0), "EVN: AI Oracle address cannot be zero");
        require(_initialReputationToken != address(0), "EVN: Reputation Token address cannot be zero");
        require(_initialAdaptiveAsset != address(0), "EVN: Adaptive Asset address cannot be zero");

        aiOracle = IAIOracle(_initialAIOracle);
        reputationToken = IReputationToken(_initialReputationToken);
        adaptiveAsset = IAdaptiveAsset(_initialAdaptiveAsset);

        // Initialize default protocol parameters
        protocolParameters[keccak256("MIN_STAKE_FOR_PROPOSAL")].value = 100 * (10 ** 18); // 100 RT
        protocolParameters[keccak256("MIN_VOTING_QUORUM_PERMIL")].value = 2000; // 20%
        protocolParameters[keccak256("VOTING_PERIOD_SECONDS")].value = 7 days;
        protocolParameters[keccak256("EVOLUTION_COOLDOWN_SECONDS")].value = 1 days;
    }

    /**
     * @dev Allows the owner to update the AI Oracle contract address.
     * @param _newOracle The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "EVN: New AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_newOracle);
    }

    /**
     * @dev Allows the owner to update the Reputation Token contract address.
     * @param _newRT The new address for the Reputation Token.
     */
    function setReputationTokenAddress(address _newRT) external onlyOwner {
        require(_newRT != address(0), "EVN: New RT address cannot be zero");
        reputationToken = IReputationToken(_newRT);
    }

    /**
     * @dev Allows the owner to pause core system operations.
     * Prevents critical functions from being called during maintenance or emergency.
     */
    function pauseSystem() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allows the owner to unpause the system.
     * Re-enables critical functions after maintenance.
     */
    function unpauseSystem() external onlyOwner {
        _unpause();
    }

    // E. Adaptive Asset (AA) Management

    /**
     * @dev Mints a new Adaptive Asset (AA) NFT.
     * The caller becomes the originator and initial owner.
     * @param _initialMetadataURI The initial metadata URI for the asset.
     */
    function createAdaptiveAsset(string memory _initialMetadataURI) external whenNotPaused returns (uint256) {
        _assetIds.increment();
        uint256 newAssetId = _assetIds.current();

        adaptiveAssets[newAssetId] = AdaptiveAsset({
            id: newAssetId,
            originator: msg.sender,
            currentMetadataURI: _initialMetadataURI,
            currentEvolutionStage: 0,
            lastEvolutionTime: block.timestamp,
            dynamicRoyaltyRatePermil: 0, // Default to 0%
            accumulatedRoyalties: 0,
            zkProofAttributionHash: bytes32(0),
            zkProofVerified: false
        });

        adaptiveAsset.mint(msg.sender, newAssetId, _initialMetadataURI); // Mint the actual NFT

        emit AdaptiveAssetCreated(newAssetId, msg.sender, _initialMetadataURI);
        return newAssetId;
    }

    /**
     * @dev Retrieves detailed information about an Adaptive Asset.
     * @param _assetId The ID of the Adaptive Asset.
     * @return A tuple containing asset details.
     */
    function getAssetInfo(uint256 _assetId) public view returns (
        uint256 id,
        address originator,
        string memory currentMetadataURI,
        uint256 currentEvolutionStage,
        uint256 lastEvolutionTime,
        uint256 dynamicRoyaltyRatePermil,
        uint256 accumulatedRoyalties,
        bytes32 zkProofAttributionHash,
        bool zkProofVerified
    ) {
        AdaptiveAsset storage asset = adaptiveAssets[_assetId];
        require(asset.id != 0, "EVN: Asset does not exist");
        return (
            asset.id,
            asset.originator,
            asset.currentMetadataURI,
            asset.currentEvolutionStage,
            asset.lastEvolutionTime,
            asset.dynamicRoyaltyRatePermil,
            asset.accumulatedRoyalties,
            asset.zkProofAttributionHash,
            asset.zkProofVerified
        );
    }

    /**
     * @dev Proposes a future evolution state for an Adaptive Asset.
     * Only the asset's originator can propose an evolution.
     * Includes a hash of the expected AI judgment data.
     * @param _assetId The ID of the Adaptive Asset.
     * @param _newMetadataURI The new metadata URI for the proposed evolution.
     * @param _aiJudgmentHash The keccak256 hash of the off-chain AI judgment data expected for this proposal.
     */
    function proposeEvolutionPath(uint256 _assetId, string memory _newMetadataURI, bytes32 _aiJudgmentHash) external whenNotPaused {
        AdaptiveAsset storage asset = adaptiveAssets[_assetId];
        require(asset.id != 0, "EVN: Asset does not exist");
        require(msg.sender == asset.originator, "EVN: Only asset originator can propose evolution");
        require(block.timestamp >= asset.lastEvolutionTime + protocolParameters[keccak256("EVOLUTION_COOLDOWN_SECONDS")].value, "EVN: Asset is in cooldown period");
        require(bytes(_newMetadataURI).length > 0, "EVN: New metadata URI cannot be empty");
        require(_aiJudgmentHash != bytes32(0), "EVN: AI Judgment hash cannot be zero");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        evolutionProposals[newProposalId] = EvolutionProposal({
            assetId: _assetId,
            proposer: msg.sender,
            newMetadataURI: _newMetadataURI,
            aiJudgmentHash: _aiJudgmentHash,
            submittedTime: block.timestamp,
            aiApproved: false,
            approvalTime: 0,
            executed: false
        });

        emit EvolutionProposalSubmitted(_assetId, newProposalId, msg.sender, _newMetadataURI, _aiJudgmentHash);
    }

    /**
     * @dev The AI Oracle approves an evolution proposal.
     * This function verifies the AI's signed judgment and triggers the asset's evolution.
     * @param _assetId The ID of the Adaptive Asset.
     * @param _proposalId The ID of the evolution proposal.
     * @param _aiSignedData The AI Oracle's signed data confirming the judgment.
     */
    function approveEvolutionProposal(uint256 _assetId, uint256 _proposalId, bytes memory _aiSignedData) external onlyAIOracle whenNotPaused {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.assetId == _assetId, "EVN: Proposal ID mismatch for asset");
        require(!proposal.aiApproved, "EVN: Proposal already approved by AI");
        require(!proposal.executed, "EVN: Proposal already executed");

        // Reconstruct the digest that the AI would have signed
        // This simulates verifying the AI's "judgment" on the new metadata URI for the asset
        bytes32 digest = keccak256(abi.encodePacked(_assetId, proposal.newMetadataURI, proposal.aiJudgmentHash));
        require(aiOracle.verifyAISignedData(digest, _aiSignedData), "EVN: Invalid AI signature");

        proposal.aiApproved = true;
        proposal.approvalTime = block.timestamp;
        
        // Execute the evolution
        AdaptiveAsset storage asset = adaptiveAssets[_assetId];
        asset.currentMetadataURI = proposal.newMetadataURI;
        asset.currentEvolutionStage++;
        asset.lastEvolutionTime = block.timestamp;
        proposal.executed = true;

        adaptiveAsset.updateMetadataURI(_assetId, proposal.newMetadataURI);

        emit EvolutionProposalApproved(_assetId, _proposalId, asset.currentEvolutionStage, proposal.newMetadataURI);
    }

    /**
     * @dev Returns the current metadata URI of an Adaptive Asset.
     * For a full history, off-chain indexing of `EvolutionProposalApproved` events would be used.
     * @param _assetId The ID of the Adaptive Asset.
     * @return The current metadata URI of the asset.
     */
    function getAssetEvolutionHistory(uint256 _assetId) public view returns (string memory) {
        AdaptiveAsset storage asset = adaptiveAssets[_assetId];
        require(asset.id != 0, "EVN: Asset does not exist");
        return asset.currentMetadataURI;
    }

    // F. Reputation & Staking

    /**
     * @dev Allows a user to stake Reputation Tokens (RTs) into a specific Epoch Pool.
     * These staked tokens influence asset evolution within that epoch.
     * User must have approved EvolveVerseNexus to transfer the tokens first.
     * @param _amount The amount of RTs to stake.
     * @param _epochPoolId The ID of the Epoch Pool to stake into.
     */
    function stakeReputation(uint256 _amount, uint256 _epochPoolId) external whenNotPaused {
        EpochPool storage pool = epochPools[_epochPoolId];
        require(pool.id != 0, "EVN: Epoch Pool does not exist");
        require(block.timestamp < pool.startTime + pool.durationSeconds, "EVN: Epoch Pool has ended");
        require(_amount > 0, "EVN: Stake amount must be greater than zero");

        reputationToken.transferFrom(msg.sender, address(this), _amount);

        pool.totalStakedReputation += _amount;
        pool.stakedReputationByUser[msg.sender] += _amount;

        emit ReputationStaked(msg.sender, _epochPoolId, _amount);
    }

    /**
     * @dev Allows a user to unstake RTs from an Epoch Pool.
     * @param _amount The amount of RTs to unstake.
     * @param _epochPoolId The ID of the Epoch Pool to unstake from.
     */
    function unstakeReputation(uint256 _amount, uint256 _epochPoolId) external whenNotPaused {
        EpochPool storage pool = epochPools[_epochPoolId];
        require(pool.id != 0, "EVN: Epoch Pool does not exist");
        require(pool.stakedReputationByUser[msg.sender] >= _amount, "EVN: Insufficient staked reputation");
        require(_amount > 0, "EVN: Unstake amount must be greater than zero");

        // Allow unstaking even after epoch ends, just no more influence
        pool.totalStakedReputation -= _amount;
        pool.stakedReputationByUser[msg.sender] -= _amount;

        reputationToken.transfer(msg.sender, _amount);

        emit ReputationUnstaked(msg.sender, _epochPoolId, _amount);
    }

    /**
     * @dev Allows a user to delegate their voting/influence power in RTs to another address.
     * This impacts governance voting strength (Function 28). It does not affect epoch staking.
     * @param _delegatee The address to delegate reputation to.
     * @param _amount The amount of reputation to delegate.
     */
    function delegateReputation(address _delegatee, uint256 _amount) external whenNotPaused {
        require(_delegatee != address(0), "EVN: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "EVN: Cannot delegate to self");
        require(_amount > 0, "EVN: Delegation amount must be greater than zero");
        // This function records the intention. Actual vote weight calculation (`getVoteWeight`) uses this.
        reputationDelegations[msg.sender][_delegatee] += _amount;
        emit ReputationDelegated(msg.sender, _delegatee, _amount);
    }

    /**
     * @dev Allows a user to revoke a portion of their delegated RTs.
     * @param _delegatee The address from which to undelegate.
     * @param _amount The amount of reputation to undelegate.
     */
    function undelegateReputation(address _delegatee, uint256 _amount) external whenNotPaused {
        require(_delegatee != address(0), "EVN: Delegatee cannot be zero address");
        require(reputationDelegations[msg.sender][_delegatee] >= _amount, "EVN: Insufficient delegated amount");
        require(_amount > 0, "EVN: Undelegation amount must be greater than zero");

        reputationDelegations[msg.sender][_delegatee] -= _amount;
        emit ReputationDelegated(msg.sender, _delegatee, _amount); // Re-use event
    }

    /**
     * @dev Mints and distributes Reputation Tokens.
     * This is a system function, callable by the contract owner or specific roles (e.g., after challenge fulfillment).
     * @param _recipient The address to receive the RTs.
     * @param _amount The amount of RTs to mint and transfer.
     */
    function distributeReputation(address _recipient, uint256 _amount) external onlyOwner whenNotPaused { // Or by a specific role
        require(_recipient != address(0), "EVN: Recipient cannot be zero address");
        require(_amount > 0, "EVN: Distribution amount must be greater than zero");

        reputationToken.mint(_recipient, _amount);

        emit ReputationDistributed(_recipient, _amount);
    }

    // G. Epoch Pools & Influence

    /**
     * @dev Creates a new Epoch Pool for focused staking influence.
     * Only owner can create new pools.
     * @param _theme A descriptive theme for the pool (e.g., "Artistic Merit").
     * @param _durationSeconds The duration of the epoch in seconds.
     */
    function createEpochPool(string memory _theme, uint256 _durationSeconds) external onlyOwner whenNotPaused returns (uint256) {
        require(bytes(_theme).length > 0, "EVN: Theme cannot be empty");
        require(_durationSeconds > 0, "EVN: Duration must be positive");

        _epochPoolIds.increment();
        uint256 newPoolId = _epochPoolIds.current();

        epochPools[newPoolId] = EpochPool({
            id: newPoolId,
            theme: _theme,
            startTime: block.timestamp,
            durationSeconds: _durationSeconds,
            totalStakedReputation: 0
        });

        emit EpochPoolCreated(newPoolId, _theme, _durationSeconds);
        return newPoolId;
    }

    /**
     * @dev Retrieves details about an Epoch Pool.
     * @param _poolId The ID of the Epoch Pool.
     * @return A tuple containing epoch pool details.
     */
    function getEpochPoolInfo(uint256 _poolId) public view returns (
        uint256 id,
        string memory theme,
        uint256 startTime,
        uint256 durationSeconds,
        uint256 totalStakedReputation,
        uint256 userStakedReputation
    ) {
        EpochPool storage pool = epochPools[_poolId];
        require(pool.id != 0, "EVN: Epoch Pool does not exist");
        return (
            pool.id,
            pool.theme,
            pool.startTime,
            pool.durationSeconds,
            pool.totalStakedReputation,
            pool.stakedReputationByUser[msg.sender] // Return user's own stake in this context
        );
    }

    /**
     * @dev Calculates an asset's *potential* influence score within a specific Epoch Pool.
     * This function simply returns the total reputation staked in the pool.
     * The actual "influence" on asset evolution is primarily determined by the AI Oracle's decision,
     * but higher staked reputation in relevant pools could lead to greater rewards for successful stakers.
     * @param _assetId The ID of the Adaptive Asset (for context, not directly used in score).
     * @param _epochPoolId The ID of the Epoch Pool.
     * @return The total reputation staked in the epoch pool.
     */
    function calculateAssetInfluenceScore(uint256 _assetId, uint256 _epochPoolId) public view returns (uint256 totalInfluence) {
        // _assetId is currently used for context, but not for direct calculation here.
        // In a more complex system, assets could be explicitly linked to epoch themes.
        EpochPool storage pool = epochPools[_epochPoolId];
        require(pool.id != 0, "EVN: Epoch Pool does not exist");
        return pool.totalStakedReputation;
    }


    /**
     * @dev Finalizes an Epoch Pool.
     * Can be called by anyone after the epoch duration has passed.
     * This function would typically trigger distribution of rewards to stakers based on their influence/success.
     * For simplicity, it just marks the epoch as effectively "finalized" and logs the total stake.
     * @param _poolId The ID of the Epoch Pool to finalize.
     */
    function finalizeEpoch(uint256 _poolId) external whenNotPaused {
        EpochPool storage pool = epochPools[_poolId];
        require(pool.id != 0, "EVN: Epoch Pool does not exist");
        require(block.timestamp >= pool.startTime + pool.durationSeconds, "EVN: Epoch Pool has not ended yet");
        
        // In a more robust system, this would iterate through stakers in `pool.stakedReputationByUser`
        // and calculate rewards based on their influence on successful asset evolutions as judged by the AI.
        // Example: `reputationToken.mint(stakerAddress, rewardAmount);`

        emit EpochFinalized(_poolId, pool.totalStakedReputation);
    }

    // H. Advanced & Dynamic Concepts

    /**
     * @dev Allows a user to submit a ZK-proof attesting to a private contribution related to an Adaptive Asset.
     * This proof allows for claiming attribution without revealing sensitive details on-chain.
     * The `_publicInputHash` uniquely identifies the context of the proof.
     * @param _assetId The ID of the Adaptive Asset this proof relates to.
     * @param _proof The serialized zero-knowledge proof (conceptual; likely stored off-chain).
     * @param _publicInputHash The keccak256 hash of the public inputs used in the ZK proof.
     */
    function submitZKAttributionProof(uint256 _assetId, bytes memory _proof, bytes32 _publicInputHash) external whenNotPaused {
        AdaptiveAsset storage asset = adaptiveAssets[_assetId];
        require(asset.id != 0, "EVN: Asset does not exist");
        require(asset.zkProofAttributionHash == bytes32(0) || asset.zkProofAttributionHash == _publicInputHash, "EVN: ZK proof already submitted for this asset context");
        require(_publicInputHash != bytes32(0), "EVN: Public input hash cannot be zero");
        require(bytes(_proof).length > 0, "EVN: Proof cannot be empty");

        // Store the proof hash and mark as unverified
        asset.zkProofAttributionHash = _publicInputHash;
        asset.zkProofVerified = false;

        emit ZKAttributionProofSubmitted(_assetId, msg.sender, _publicInputHash);
    }

    /**
     * @dev An authorized role (e.g., owner or specialized verifier) can mark a submitted ZK-proof as verified.
     * This function *does not perform on-chain ZK verification*. It acts as an oracle for external verification.
     * @param _assetId The ID of the Adaptive Asset.
     * @param _proof The serialized zero-knowledge proof (passed again for external verification context).
     * @param _publicInputHash The keccak256 hash of the public inputs.
     */
    function verifyZKProofForAttribution(uint256 _assetId, bytes memory _proof, bytes32 _publicInputHash) external onlyOwner whenNotPaused { // Could be specific ZKVerifier role
        AdaptiveAsset storage asset = adaptiveAssets[_assetId];
        require(asset.id != 0, "EVN: Asset does not exist");
        require(asset.zkProofAttributionHash == _publicInputHash, "EVN: Mismatch in public input hash for verification");
        require(!asset.zkProofVerified, "EVN: ZK proof already verified for this asset");
        require(bytes(_proof).length > 0, "EVN: Proof cannot be empty");

        // In a real scenario, this is where the `_proof` would be sent to a ZK verifier contract
        // or a precompile for actual on-chain verification.
        // Example: `require(Groth16Verifier.verifyProof(_proof, _publicInputHash), "Invalid ZK proof");`
        // For this example, we simply mark it as verified by an authorized caller.
        asset.zkProofVerified = true;

        // Potentially reward the submitter or update asset traits based on verified proof
        // Example: distributeReputation(asset.originator, 50 * (10 ** 18));

        emit ZKAttributionProofVerified(_assetId, _publicInputHash);
    }

    /**
     * @dev Allows anyone to create a challenge/bounty linked to an Adaptive Asset.
     * Challengers must provide a reward in RTs, which are locked in the contract.
     * @param _description A description of the challenge.
     * @param _rewardRT The amount of Reputation Tokens to reward for fulfilling the challenge.
     * @param _targetAssetId The ID of the Adaptive Asset the challenge is related to.
     * @param _deadline The timestamp by which the challenge must be fulfilled.
     */
    function createChallenge(
        string memory _description,
        uint256 _rewardRT,
        uint256 _targetAssetId,
        uint256 _deadline
    ) external whenNotPaused returns (uint256) {
        require(adaptiveAssets[_targetAssetId].id != 0, "EVN: Target asset does not exist");
        require(_rewardRT > 0, "EVN: Challenge reward must be greater than zero");
        require(_deadline > block.timestamp, "EVN: Deadline must be in the future");
        require(bytes(_description).length > 0, "EVN: Challenge description cannot be empty");

        reputationToken.transferFrom(msg.sender, address(this), _rewardRT); // Lock the reward

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            creator: msg.sender,
            description: _description,
            rewardRT: _rewardRT,
            targetAssetId: _targetAssetId,
            deadline: _deadline,
            fulfilled: false,
            fulfiller: address(0),
            proofOfWork: new bytes(0) // Empty bytes
        });

        emit ChallengeCreated(newChallengeId, msg.sender, _targetAssetId, _rewardRT);
        return newChallengeId;
    }

    /**
     * @dev Allows a user to submit their solution/proof for a challenge.
     * For this example, the reward is immediately transferred. In a real system, it might require manual review or an oracle.
     * @param _challengeId The ID of the challenge to fulfill.
     * @param _proofOfWork A hash or reference to off-chain proof of work.
     */
    function fulfillChallenge(uint256 _challengeId, bytes memory _proofOfWork) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "EVN: Challenge does not exist");
        require(!challenge.fulfilled, "EVN: Challenge already fulfilled");
        require(block.timestamp <= challenge.deadline, "EVN: Challenge deadline has passed");
        require(bytes(_proofOfWork).length > 0, "EVN: Proof of work cannot be empty");

        challenge.fulfilled = true;
        challenge.fulfiller = msg.sender;
        challenge.proofOfWork = _proofOfWork;

        reputationToken.transfer(challenge.fulfiller, challenge.rewardRT); // Transfer immediately for this example

        emit ChallengeFulfilled(_challengeId, msg.sender);
    }

    /**
     * @dev Allows the AA originator or governance to set a dynamic royalty rate for an asset.
     * This rate applies to future sales (sales mechanisms are external to this contract).
     * @param _assetId The ID of the Adaptive Asset.
     * @param _newRatePermil The new royalty rate in per thousand (e.g., 50 for 5%). Max 1000 (100%).
     */
    function setDynamicRoyaltyRate(uint256 _assetId, uint256 _newRatePermil) external whenNotPaused {
        AdaptiveAsset storage asset = adaptiveAssets[_assetId];
        require(asset.id != 0, "EVN: Asset does not exist");
        // Only originator or governance can change rate. For now, only originator.
        require(msg.sender == asset.originator, "EVN: Only asset originator can set royalty rate");
        require(_newRatePermil <= 1000, "EVN: Royalty rate cannot exceed 100%");

        asset.dynamicRoyaltyRatePermil = _newRatePermil;

        emit DynamicRoyaltyRateSet(_assetId, _newRatePermil);
    }

    /**
     * @dev Allows the originator of an AA to withdraw accumulated royalties.
     * This requires external mechanisms (e.g., marketplaces) to deposit funds into this contract.
     * @param _assetId The ID of the Adaptive Asset.
     */
    function withdrawDynamicRoyalties(uint256 _assetId) external whenNotPaused {
        AdaptiveAsset storage asset = adaptiveAssets[_assetId];
        require(asset.id != 0, "EVN: Asset does not exist");
        require(msg.sender == asset.originator, "EVN: Only asset originator can withdraw royalties");
        require(asset.accumulatedRoyalties > 0, "EVN: No royalties to withdraw");

        uint256 amount = asset.accumulatedRoyalties;
        asset.accumulatedRoyalties = 0;

        (bool success, ) = payable(asset.originator).call{value: amount}("");
        require(success, "EVN: Failed to withdraw royalties");

        emit RoyaltiesWithdrawn(_assetId, asset.originator, amount);
    }

    /**
     * @dev Allows an external marketplace or contract to deposit royalties for a specific asset.
     * This function is payable to receive native currency.
     * @param _assetId The ID of the Adaptive Asset for which royalties are being deposited.
     */
    function depositRoyaltiesForAsset(uint256 _assetId) external payable {
        AdaptiveAsset storage asset = adaptiveAssets[_assetId];
        require(asset.id != 0, "EVN: Asset does not exist");
        require(msg.value > 0, "EVN: Must send non-zero value");

        asset.accumulatedRoyalties += msg.value;
        emit RoyaltiesDeposited(_assetId, msg.value);
    }

    /**
     * @dev Initiates a governance proposal to change a core protocol parameter.
     * Requires a minimum RT balance to prevent spam.
     * @param _description A detailed description of the proposed change.
     * @param _paramKey The keccak256 hash of the parameter's name (e.g., `keccak256("MIN_STAKE_FOR_PROPOSAL")`).
     * @param _newValue The new value for the parameter.
     */
    function proposeProtocolParameterChange(
        string memory _description,
        bytes32 _paramKey,
        uint256 _newValue
    ) external whenNotPaused returns (uint256) {
        require(reputationToken.balanceOf(msg.sender) >= protocolParameters[keccak256("MIN_STAKE_FOR_PROPOSAL")].value, "EVN: Insufficient reputation to propose");

        _protocolProposalIds.increment();
        uint256 newProposalId = _protocolProposalIds.current();

        protocolProposals[newProposalId] = ProtocolProposal({
            id: newProposalId,
            description: _description,
            paramKey: _paramKey,
            newValue: _newValue,
            quorumRequiredPermil: protocolParameters[keccak256("MIN_VOTING_QUORUM_PERMIL")].value,
            votesFor: 0,
            votesAgainst: 0,
            totalReputationSnapshot: reputationToken.totalSupply(), // Snapshot total supply for quorum
            proposalEndTime: block.timestamp + protocolParameters[keccak256("VOTING_PERIOD_SECONDS")].value,
            hasVoted: new mapping(address => bool),
            executed: false
        });

        emit ProtocolParameterChangeProposed(newProposalId, _paramKey, _newValue);
        return newProposalId;
    }

    /**
     * @dev Allows users to vote on an active governance proposal using their reputation.
     * Vote weight is based on user's current RT balance.
     * For simplicity, delegated votes are not directly included in this on-chain vote tally;
     * the `delegateReputation` function provides a conceptual framework for off-chain or future on-chain liquid democracy.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProtocolParameterChange(uint256 _proposalId, bool _support) external whenNotPaused {
        ProtocolProposal storage proposal = protocolProposals[_proposalId];
        require(proposal.id != 0, "EVN: Proposal does not exist");
        require(block.timestamp <= proposal.proposalEndTime, "EVN: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "EVN: Already voted on this proposal");
        require(!proposal.executed, "EVN: Proposal already executed");

        uint256 voteWeight = reputationToken.balanceOf(msg.sender); // Direct balance for on-chain voting
        require(voteWeight > 0, "EVN: Caller has no direct voting power");

        if (_support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProtocolParameterChangeVoted(_proposalId, msg.sender, _support);
    }


    /**
     * @dev Executes a governance proposal if it has met the voting quorum and threshold after the voting period ends.
     * Callable by anyone.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeProtocolParameterChange(uint256 _proposalId) external whenNotPaused {
        ProtocolProposal storage proposal = protocolProposals[_proposalId];
        require(proposal.id != 0, "EVN: Proposal does not exist");
        require(block.timestamp > proposal.proposalEndTime, "EVN: Voting period has not ended");
        require(!proposal.executed, "EVN: Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumThreshold = (proposal.totalReputationSnapshot * proposal.quorumRequiredPermil) / 10000; // 10000 for permil basis

        // Check quorum: total votes must meet minimum participation
        require(totalVotes >= quorumThreshold, "EVN: Quorum not met");
        // Check approval: votes for must exceed votes against
        require(proposal.votesFor > proposal.votesAgainst, "EVN: Proposal did not pass");

        protocolParameters[proposal.paramKey].value = proposal.newValue;
        proposal.executed = true;

        emit ProtocolParameterChangeExecuted(_proposalId, proposal.paramKey, proposal.newValue);
    }

    // III. Supporting Contracts (Minimal Implementations for demonstration)

    /**
     * @dev Simplified ReputationToken (ERC-20 like) for demonstration.
     * Includes only functionalities necessary for EvolveVerseNexus (mint, transfer, transferFrom, allowance).
     */
    contract ReputationToken is IReputationToken {
        string public name = "Reputation Token";
        string public symbol = "RT";
        uint8 public decimals = 18;
        uint256 private _totalSupply;
        mapping(address => uint256) private _balances;
        mapping(address => mapping(address => uint256)) private _allowances;

        // EvolveVerseNexus is the only minter
        address public minter;

        constructor(address _minter) {
            minter = _minter;
        }

        function totalSupply() external view override returns (uint256) {
            return _totalSupply;
        }

        function balanceOf(address account) external view override returns (uint256) {
            return _balances[account];
        }

        function transfer(address to, uint256 amount) external override returns (bool) {
            _transfer(msg.sender, to, amount);
            return true;
        }

        function approve(address spender, uint256 amount) external override returns (bool) {
            _allowances[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
            return true;
        }

        function allowance(address owner, address spender) external view override returns (uint256) {
            return _allowances[owner][spender];
        }

        function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
            require(_balances[from] >= amount, "RT: Insufficient balance");
            require(_allowances[from][msg.sender] >= amount, "RT: Insufficient allowance");

            _transfer(from, to, amount);
            _allowances[from][msg.sender] -= amount; // Reduce allowance after transfer
            return true;
        }

        function mint(address account, uint256 amount) external override returns (bool) {
            require(msg.sender == minter, "RT: Only minter can mint");
            _mint(account, amount);
            return true;
        }

        function burn(address account, uint256 amount) external override returns (bool) {
            require(msg.sender == minter, "RT: Only minter can burn");
            _burn(account, amount);
            return true;
        }

        function _mint(address account, uint256 amount) internal {
            require(account != address(0), "RT: Mint to zero address");
            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);
        }

        function _burn(address account, uint256 amount) internal {
            require(account != address(0), "RT: Burn from zero address");
            require(_balances[account] >= amount, "RT: Burn amount exceeds balance");
            _totalSupply -= amount;
            _balances[account] -= amount;
            emit Transfer(account, address(0), amount);
        }

        function _transfer(address from, address to, uint256 amount) internal {
            require(from != address(0), "RT: Transfer from zero address");
            require(to != address(0), "RT: Transfer to zero address");
            require(_balances[from] >= amount, "RT: Insufficient balance");

            _balances[from] -= amount;
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }
    }

    /**
     * @dev Simplified AdaptiveAsset (ERC-721 like) for demonstration.
     * Includes only functionalities necessary for EvolveVerseNexus (mint, update metadata, ownership checks).
     */
    contract AdaptiveAsset is IAdaptiveAsset {
        string public name = "Adaptive Asset";
        string public symbol = "AA";

        mapping(uint256 => address) private _owners;
        mapping(address => uint256) private _balances;
        mapping(uint256 => string) private _tokenURIs;
        mapping(uint256 => address) private _tokenApprovals; // Single token approval

        address public minter; // EvolveVerseNexus is the only minter

        constructor(address _minter) {
            minter = _minter;
        }

        function balanceOf(address owner) external view override returns (uint255) {
            return _balances[owner];
        }

        function ownerOf(uint256 tokenId) external view override returns (address) {
            address owner = _owners[tokenId];
            require(owner != address(0), "AA: owner query for nonexistent token");
            return owner;
        }

        function getApproved(uint256 tokenId) external view override returns (address) {
            return _tokenApprovals[tokenId];
        }

        function isApprovedForAll(address owner, address operator) external view override returns (bool) {
            // Simplified: no operator support for brevity.
            return false;
        }

        function approve(address to, uint256 tokenId) external override {
            address owner = ownerOf(tokenId);
            require(to != owner, "AA: approval to current owner");
            require(msg.sender == owner, "AA: approve caller is not owner");
            _tokenApprovals[tokenId] = to;
            emit Approval(owner, to, tokenId);
        }

        function safeTransferFrom(address from, address to, uint256 tokenId) external override {
            _transfer(from, to, tokenId);
        }

        function transferFrom(address from, address to, uint256 tokenId) external override {
            _transfer(from, to, tokenId);
        }

        function mint(address to, uint256 tokenId, string memory uri) external override {
            require(msg.sender == minter, "AA: Only minter can mint");
            require(to != address(0), "AA: mint to the zero address");
            require(_owners[tokenId] == address(0), "AA: token already minted");

            _owners[tokenId] = to;
            _balances[to]++;
            _tokenURIs[tokenId] = uri;

            emit Transfer(address(0), to, tokenId);
        }

        function updateMetadataURI(uint256 tokenId, string memory newURI) external override {
            require(msg.sender == minter, "AA: Only minter can update metadata");
            require(_owners[tokenId] != address(0), "AA: update for nonexistent token");
            _tokenURIs[tokenId] = newURI;
            // No specific event for metadata update in ERC721, but can be added if needed for off-chain indexing.
        }

        function _transfer(address from, address to, uint256 tokenId) internal {
            require(ownerOf(tokenId) == from, "AA: transfer from incorrect owner");
            require(to != address(0), "AA: transfer to the zero address");

            // Simplified approval check: only owner can call or approved address
            require(msg.sender == from || _tokenApprovals[tokenId] == msg.sender, "AA: transfer caller is not owner nor approved");

            _balances[from]--;
            _balances[to]++;
            _owners[tokenId] = to;
            delete _tokenApprovals[tokenId]; // Clear approval upon transfer

            emit Transfer(from, to, tokenId);
        }
    }

    /**
     * @dev Mock AI Oracle for testing purposes.
     * In a real scenario, this would be a more complex contract that securely provides AI judgments.
     */
    contract AIOracleMock is IAIOracle, Ownable {
        address public signerAddress;

        constructor(address _signer) Ownable(msg.sender) {
            signerAddress = _signer;
        }

        function setSignerAddress(address _newSigner) external onlyOwner {
            signerAddress = _newSigner;
        }

        function verifyAISignedData(bytes32 _digest, bytes memory _signature) external view override returns (bool) {
            // In a real oracle, this would verify a signature from a trusted AI service.
            // For mock, we simply check if the recovered address matches the designated signer.
            return signerAddress == ECDSA.recover(ECDSA.toEthSignedMessageHash(_digest), _signature);
        }

        function getAISignatureAddress() external view override returns (address) {
            return signerAddress;
        }
    }
}
```