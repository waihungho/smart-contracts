This smart contract, **EvoSphere**, introduces a novel ecosystem for **Dynamic NFTs (EvoNodes)** and **Collaborative AI-Augmented Creation**, governed by a Decentralized Autonomous Organization (DAO). It's designed to be advanced, creative, and avoids duplicating existing open-source projects by uniquely combining several trendy concepts: on-chain dynamic assets, proof-of-contribution/curation for AI content, and a robust DAO governance model for an "AI layer".

---

## EvoSphere Smart Contract: Outline and Function Summary

**Core Concepts:**
1.  **EvoNodes (Dynamic NFTs):** ERC721 NFTs whose metadata and characteristics dynamically change based on user interactions, staked "Essence" tokens, and the integration of community-curated AI creations.
2.  **Essence Token (ERC20):** A utility and governance token. It's used as collateral for minting EvoNodes, awarded for valuable contributions (e.g., submitting and curating AI content), and grants voting power in the DAO.
3.  **AI Synthesis Proposals:** A decentralized mechanism where users propose off-chain AI-generated content (e.g., image hashes, text hashes, 3D model data) for integration into the EvoSphere ecosystem, often with EvoNodes.
4.  **Community Curation & Challenge System:** DAO members actively vote on AI creation proposals to ensure quality and relevance. A robust challenge system allows users to dispute low-quality or fraudulent submissions, fostering a self-correcting content ecosystem.
5.  **Staked Evolution:** EvoNodes require staked Essence tokens to exist and accrue "Essence Points" over time. These points, along with linked AI creations, drive the EvoNode's evolution through different stages.
6.  **DAO Governance:** Critical protocol parameters, whitelisting of external AI models, and treasury management are controlled by token-weighted votes from Essence token holders.

**Contract Architecture:**
*   **`EvoSphere` (Main Contract):** Manages all core logic, including EvoNode evolution, AI content proposal lifecycle, DAO governance, and interaction with the ERC721 and ERC20 tokens.
*   **`EvoSphereERC721` (Inner ERC721 Contract):** Represents the EvoNodes (Dynamic NFTs). It's an `ERC721Enumerable` extension for efficient querying of owned tokens and includes custom logic to prevent direct transfers, ensuring EvoNode management solely through the `EvoSphere` core contract.
*   **`EvoSphereEssence` (Inner ERC20 Contract):** Represents the Essence token. It allows the `EvoSphere` core contract to mint and burn tokens based on protocol logic (e.g., rewards, staking).

**Function Summary (at least 20 functions, grouped by functionality):**

**I. EvoNode (Dynamic NFT) Management (via `EvoSphereERC721` and `EvoSphere`):**
1.  `mintEvoNode(uint256 _stakeAmount)`: Mints a new EvoNode for the caller by staking `_stakeAmount` of Essence tokens.
2.  `burnEvoNode(uint256 _tokenId)`: Burns an EvoNode, returning the staked collateral Essence tokens to the owner.
3.  `triggerEvolution(uint256 _tokenId)`: Initiates an EvoNode's evolution to the next stage if it meets accumulated Essence points and time criteria.
4.  `linkAICreationToNode(uint256 _tokenId, uint256 _proposalId)`: Links a community-approved AI creation to a specific EvoNode, potentially enhancing its attributes and consuming Essence points.
5.  `getNodeDetails(uint256 _tokenId)`: *View*: Retrieves all stored details of a given EvoNode.
6.  `getEvolutionStage(uint256 _tokenId)`: *View*: Returns the human-readable name of an EvoNode's current evolution stage.
7.  `tokenURI(uint256 tokenId)`: Overridden `ERC721` function that generates a dynamic JSON metadata URI (Base64 encoded) reflecting the EvoNode's current stage and attributes.

**II. Essence Token (ERC20) & Staking (via `EvoSphereEssence` and `EvoSphere`):**
8.  `claimEssence()`: Allows users to claim their accumulated Essence rewards from their EvoNodes.
9.  `getClaimableEssence(address _user)`: *View*: Calculates the total Essence a user is currently able to claim across all their EvoNodes.
10. `stakeForNode(address _user, uint256 _amount)`: *Internal*: Handles the transfer of Essence tokens for staking purposes (used by `mintEvoNode`).
11. `unstakeFromNode(address _user, uint256 _amount)`: *Internal*: Handles the return of staked Essence tokens (used by `burnEvoNode`).
12. `_accrueEssencePoints(uint256 _tokenId)`: *Internal*: Calculates and adds passive Essence points to an EvoNode based on time elapsed since last interaction.

**III. AI Synthesis & Curation:**
13. `submitAICreationProposal(string memory _promptHash, string memory _contentHash, uint256 _externalAIModelId, string memory _metadataURI)`: Submits a proposal for an off-chain AI-generated asset, requiring a bond in Essence tokens.
14. `voteOnAICreationProposal(uint256 _proposalId, bool _approve)`: Allows Essence token holders to vote on AI creation proposals, influencing their approval.
15. `challengeAICreationProposal(uint256 _proposalId, string memory _reason)`: Enables users to challenge an AI creation proposal, requiring a larger bond and initiating a dispute resolution phase.
16. `finalizeAICreationProposal(uint256 _proposalId)`: Resolves an AI creation proposal, distributing rewards/penalties based on voting results or challenge outcomes.
17. `resolveAICreationChallenge(uint256 _challengeId, bool _successful)`: Admin/DAO-controlled function to explicitly resolve a challenge, setting its outcome.
18. `registerExternalAIModel(string memory _modelName, string memory _modelURI, string memory _description)`: DAO-controlled function to whitelist external AI models that can be referenced in proposals.
19. `getAICreationProposalDetails(uint256 _proposalId)`: *View*: Provides detailed information about an AI creation proposal.

**IV. DAO Governance & Protocol Parameters:**
20. `submitGovernanceProposal(address _target, bytes calldata _callData, string memory _description)`: Allows users (with sufficient Essence) to propose changes to the protocol.
21. `voteOnGovernanceProposal(uint256 _proposalId, bool _approve)`: Enables Essence token holders to vote on general governance proposals.
22. `executeGovernanceProposal(uint256 _proposalId)`: Executes a governance proposal that has successfully passed the voting and quorum thresholds.
23. `setProtocolParameter(bytes32 _paramName, uint256 _value)`: DAO-controlled function to dynamically update core protocol parameters (e.g., minimum stake, voting thresholds).
24. `updateEvolutionRule(uint8 _stage, uint256 _essenceRequired, uint256 _timeThreshold, string memory _stageName, string memory _metadataPrefix)`: DAO-controlled function to modify the evolution criteria and associated metadata for EvoNode stages.

**V. Treasury & Fees:**
25. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: DAO-controlled function to withdraw Essence tokens from the protocol's treasury.
26. `setTreasuryAddress(address _newTreasury)`: DAO-controlled function to update the designated treasury address.

**VI. Utilities & Access Control:**
27. `pause()`: Allows the contract owner (or DAO) to pause critical state-changing functions in emergencies.
28. `unpause()`: Allows the contract owner (or DAO) to unpause the contract.
29. `renounceOwnership()`: Allows the current owner to renounce their ownership, typically transferring it to a DAO multi-sig.
30. `getContractBalance()`: *View*: Returns the contract's current ETH balance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For tokensOfOwner
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI
import "@openzeppelin/contracts/utils/Base64.sol"; // For tokenURI


// Outline and Function Summary
// This contract, EvoSphere, is a decentralized platform for "EvoNodes" (Dynamic NFTs)
// and collaborative, DAO-governed AI-augmented content creation.
// Users stake tokens to mint EvoNodes, which evolve based on user contributions
// and community-curated AI enhancements. Contributors earn "Essence" tokens for
// submitting and validating high-quality AI content proposals.

// --- Core Concepts ---
// 1. EvoNodes (Dynamic NFTs): NFTs that possess mutable attributes and evolve through specific actions or time.
// 2. Essence Token (ERC20): Utility and governance token rewarded for contributions and used for specific actions.
// 3. AI Synthesis Proposals: Users propose off-chain AI-generated content, linking it to prompts.
// 4. Community Curation & Challenge: DAO members vote on AI proposals and can challenge submissions for quality control.
// 5. Staked Evolution: EvoNodes require staked collateral and earn "Essence" over time.
// 6. DAO Governance: Community controls protocol parameters, AI model whitelisting, and treasury.

// --- Contract Architecture ---
// - EvoSphere: Main contract managing EvoNodes, AI proposals, and core logic.
// - EvoSphereERC721: Inner ERC721 contract for EvoNodes.
// - EvoSphereEssence: Inner ERC20 contract for Essence token.

// --- Function Summary (grouped by functionality) ---

// I. EvoNode (Dynamic NFT) Management (via EvoSphereERC721)
// 1.  mintEvoNode(uint256 _stakeAmount): Mints a new EvoNode by staking _stakeAmount of Essence tokens.
// 2.  burnEvoNode(uint256 _tokenId): Burns an EvoNode, unstaking the collateral.
// 3.  triggerEvolution(uint256 _tokenId): Triggers an EvoNode's evolution based on accumulated Essence or linked AI content.
// 4.  linkAICreationToNode(uint256 _tokenId, uint256 _proposalId): Links a finalized AI creation to an EvoNode, consuming Essence.
// 5.  getNodeDetails(uint256 _tokenId): View: Returns all details of a specific EvoNode.
// 6.  getEvolutionStage(uint256 _tokenId): View: Returns the current evolution stage name of an EvoNode.
// 7.  tokenURI(uint256 tokenId): Overridden ERC721 function to generate dynamic metadata URI.

// II. Essence Token (ERC20) & Staking (via EvoSphereEssence)
// 8.  claimEssence(): Allows users to claim their accumulated Essence rewards.
// 9.  getClaimableEssence(address _user): View: Returns the amount of Essence a user can claim.
// 10. stakeForNode(address _user, uint256 _amount): Internal: Stakes Essence tokens for node creation/maintenance.
// 11. unstakeFromNode(address _user, uint256 _amount): Internal: Unstakes Essence tokens from nodes.
// 12. _accrueEssencePoints(uint256 _tokenId): Internal: Awards raw essence points to a user.

// III. AI Synthesis & Curation
// 13. submitAICreationProposal(string memory _promptHash, string memory _contentHash, uint256 _externalAIModelId, string memory _metadataURI): Submits a proposal for an AI-generated asset. Requires a bond.
// 14. voteOnAICreationProposal(uint256 _proposalId, bool _approve): Votes on an AI creation proposal.
// 15. challengeAICreationProposal(uint256 _proposalId, string memory _reason): Challenges an AI creation proposal, requiring a larger bond.
// 16. finalizeAICreationProposal(uint256 _proposalId): Finalizes an AI proposal if it passed voting or failed challenge. Rewards/penalties.
// 17. resolveAICreationChallenge(uint256 _challengeId, bool _successful): Admin/DAO function to resolve a challenge outcome.
// 18. registerExternalAIModel(string memory _modelName, string memory _modelURI, string memory _description): DAO-controlled registration of whitelisted AI models.
// 19. getAICreationProposalDetails(uint256 _proposalId): View: Returns details of an AI creation proposal.

// IV. DAO Governance & Protocol Parameters
// 20. submitGovernanceProposal(address _target, bytes calldata _callData, string memory _description): Submits a general governance proposal.
// 21. voteOnGovernanceProposal(uint256 _proposalId, bool _approve): Votes on a governance proposal (token-weighted).
// 22. executeGovernanceProposal(uint256 _proposalId): Executes a passed governance proposal.
// 23. setProtocolParameter(bytes32 _paramName, uint256 _value): DAO-controlled function to update core protocol parameters (e.g., min stake, vote thresholds).
// 24. updateEvolutionRule(uint8 _stage, uint256 _essenceRequired, uint256 _timeThreshold, string memory _stageName, string memory _metadataPrefix): DAO-controlled function to modify evolution rules for EvoNodes.

// V. Treasury & Fees
// 25. withdrawTreasuryFunds(address _recipient, uint256 _amount): DAO-controlled withdrawal from the protocol treasury.
// 26. setTreasuryAddress(address _newTreasury): DAO-controlled function to change the treasury address.

// VI. Utilities & Access Control
// 27. pause(): Pauses core functionality in emergencies (Owner/DAO).
// 28. unpause(): Unpauses core functionality (Owner/DAO).
// 29. renounceOwnership(): Renounces ownership, potentially transferring to a DAO multisig.
// 30. getContractBalance(): View: Returns the contract's ETH balance.


// --- Error Definitions ---
error InvalidAmount();
error InsufficientEssence();
error NodeNotFound();
error NotNodeOwner();
error AlreadyEvolved();
error NotReadyForEvolution();
error ProposalNotFound();
error ProposalAlreadyFinalized();
error InvalidVote();
error AlreadyVoted();
error NotActiveProposal();
error ProposalStillActive();
error NotWhitelistedModel();
error InsufficientVotes();
error ProposalAlreadyExecuted();
error Unauthorized();
error ZeroAddress();
error ChallengeFailed(); // Specific error for challenge finalization logic
error ChallengeInProgress();
error NoChallengeToResolve();
error NoEssenceToClaim();
error InvalidProposalState();


// --- EvoSphere Core Contract ---
contract EvoSphere is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    EvoSphereERC721 public evoNodes;
    EvoSphereEssence public essenceToken;

    address public treasuryAddress;

    // EvoNode related
    struct EvoNode {
        uint256 tokenId;
        address owner;
        uint256 stakeAmount; // Amount of Essence staked
        uint256 essencePoints; // Accumulated Essence for evolution/rewards
        uint8 evolutionStage;
        uint256 lastInteractionTime;
        bytes32 attributesHash; // Hash of current attributes (points to off-chain data)
        uint256 linkedAICreationId; // ID of the AI creation linked to this node (0 if none)
    }
    mapping(uint256 => EvoNode) public evoNodeDetails; // tokenId => EvoNode
    Counters.Counter private _evoNodeIds;

    // Evolution rules (stage => requirements)
    struct EvolutionRule {
        uint256 essenceRequired;
        uint256 timeThreshold; // seconds since last evolution/mint
        string stageName;
        string metadataPrefix; // Prefix for tokenURI based on stage
    }
    mapping(uint8 => EvolutionRule) public evolutionRules;
    uint8 public maxEvolutionStage; // Max stage defined by rules

    // AI Creation Proposal related
    enum ProposalState { Pending, Voting, Challenged, Finalized, Rejected }
    enum VoteType { Approve, Reject }

    struct AICreationProposal {
        uint256 id;
        address proposer;
        string promptHash; // Hash of the input prompt
        string contentHash; // Hash of the AI-generated content (e.g., IPFS CID)
        string metadataURI; // URI for off-chain metadata (e.g., JSON on IPFS)
        uint256 externalAIModelId; // ID of the whitelisted AI model used
        uint256 submitTime;
        ProposalState state;
        uint256 bondAmount;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 challengeId; // If challenged, ID of the related challenge
    }
    mapping(uint256 => AICreationProposal) public aiCreationProposals;
    Counters.Counter private _aiProposalIds;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnAIProposal;

    struct AIChallenge {
        uint256 id;
        uint256 proposalId;
        address challenger;
        string reason;
        uint256 challengeTime;
        uint256 bondAmount;
        bool resolved;
        bool successful; // True if challenge was successful (proposal rejected)
    }
    mapping(uint256 => AIChallenge) public aiChallenges;
    Counters.Counter private _aiChallengeIds;

    struct ExternalAIModel {
        string name;
        string uri;
        string description;
        bool whitelisted;
    }
    mapping(uint256 => ExternalAIModel) public externalAIModels;
    Counters.Counter private _aiModelIds;

    // Governance Proposal related
    enum GovernanceProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        address target; // Address of contract to call
        bytes callData; // Calldata for execution
        string description;
        uint252 submitTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        GovernanceProposalState state;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    Counters.Counter private _govProposalIds;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnGovProposal;

    // Protocol Parameters (adjustable by DAO)
    mapping(bytes32 => uint256) public protocolParameters;

    // Events
    event EvoNodeMinted(uint256 indexed tokenId, address indexed owner, uint256 stakeAmount);
    event EvoNodeBurned(uint256 indexed tokenId, address indexed owner, uint256 finalEssencePoints);
    event EvoNodeEvolved(uint256 indexed tokenId, uint8 newStage, bytes32 newAttributesHash);
    event AICreationProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string promptHash, string contentHash);
    event AICreationProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event AICreationProposalChallenged(uint256 indexed proposalId, uint256 indexed challengeId, address indexed challenger);
    event AICreationProposalFinalized(uint256 indexed proposalId, ProposalState finalState, uint256 rewardAmount);
    event AICreationLinkedToNode(uint256 indexed tokenId, uint256 indexed proposalId);
    event ExternalAIModelRegistered(uint256 indexed modelId, string modelName);
    event EssenceClaimed(address indexed user, uint256 amount);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 value);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event TreasuryAddressSet(address indexed newAddress);

    // --- Constructor ---
    constructor(
        address _essenceTokenAddress,
        address _evoNodesAddress,
        address _treasuryAddress
    ) Ownable(msg.sender) Pausable() {
        if (_essenceTokenAddress == address(0) || _evoNodesAddress == address(0) || _treasuryAddress == address(0)) {
            revert ZeroAddress();
        }
        essenceToken = EvoSphereEssence(_essenceTokenAddress);
        evoNodes = EvoSphereERC721(_evoNodesAddress);
        treasuryAddress = _treasuryAddress;

        // Set initial protocol parameters
        protocolParameters["MIN_EVONODE_STAKE"] = 100 * (10 ** 18); // 100 Essence
        protocolParameters["AI_PROPOSAL_BOND"] = 10 * (10 ** 18); // 10 Essence
        protocolParameters["AI_CHALLENGE_BOND_MULTIPLIER"] = 2; // 2x AI_PROPOSAL_BOND
        protocolParameters["AI_VOTING_PERIOD"] = 3 days;
        protocolParameters["AI_MIN_VOTES_REQUIRED"] = 5; // Minimum votes for an AI proposal to pass
        protocolParameters["AI_APPROVAL_THRESHOLD_PERCENT"] = 60; // 60% approval needed
        protocolParameters["GOV_VOTING_PERIOD"] = 7 days;
        protocolParameters["GOV_QUORUM_PERCENT"] = 5; // 5% of total Essence supply
        protocolParameters["GOV_APPROVAL_THRESHOLD_PERCENT"] = 65; // 65% approval needed
        protocolParameters["ESSENCE_ACCRUAL_RATE"] = 1 * (10 ** 18); // 1 Essence per unit time for nodes (e.g., per day/week, context based on triggerEvolution)
        protocolParameters["NODE_ESSENCE_BURN_RATE"] = 5 * (10 ** 17); // 0.5 Essence burned per AI link

        // Initial evolution rules
        // Stage 0: Hatchling
        evolutionRules[0] = EvolutionRule(0, 0, "Hatchling", "ipfs://QmbZ1.../0.json"); // Placeholder IPFS CID
        // Stage 1: Juvenile (requires 50 Essence points & 7 days)
        evolutionRules[1] = EvolutionRule(50 * (10 ** 18), 7 days, "Juvenile", "ipfs://QmbZ2.../1.json"); // Placeholder IPFS CID
        // Stage 2: Mature (requires 150 Essence points & 30 days)
        evolutionRules[2] = EvolutionRule(150 * (10 ** 18), 30 days, "Mature", "ipfs://QmbZ3.../2.json"); // Placeholder IPFS CID
        maxEvolutionStage = 2; // Set max stage
    }

    // --- Modifiers ---
    modifier onlyEvoSphereInternalCall() {
        // This modifier restricts calls to internal sub-contracts (EvoSphereERC721 or EvoSphereEssence)
        require(msg.sender == address(evoNodes) || msg.sender == address(essenceToken), "EvoSphere: Not authorized internal caller");
        _;
    }

    // --- I. EvoNode (Dynamic NFT) Management ---
    /**
     * @notice Mints a new EvoNode by staking a specified amount of Essence tokens.
     * The staked tokens are transferred from the caller to this contract.
     * @param _stakeAmount The amount of Essence tokens to stake for the new EvoNode.
     * @return tokenId The ID of the newly minted EvoNode.
     */
    function mintEvoNode(uint256 _stakeAmount) public nonReentrant whenNotPaused returns (uint256) {
        if (_stakeAmount < protocolParameters["MIN_EVONODE_STAKE"]) {
            revert InsufficientEssence();
        }

        // Transfer stake from user to this contract
        if (!essenceToken.transferFrom(msg.sender, address(this), _stakeAmount)) {
            revert InsufficientEssence();
        }

        _evoNodeIds.increment();
        uint256 newTokenId = _evoNodeIds.current();

        EvoNode storage newNode = evoNodeDetails[newTokenId];
        newNode.tokenId = newTokenId;
        newNode.owner = msg.sender;
        newNode.stakeAmount = _stakeAmount;
        newNode.essencePoints = 0; // Starts with 0 points
        newNode.evolutionStage = 0; // Starts at stage 0 (Hatchling)
        newNode.lastInteractionTime = block.timestamp;
        newNode.attributesHash = keccak256(abi.encodePacked("initial_attributes", newTokenId, block.timestamp)); // Placeholder hash for initial attributes
        newNode.linkedAICreationId = 0;

        evoNodes.mint(msg.sender, newTokenId);

        emit EvoNodeMinted(newTokenId, msg.sender, _stakeAmount);
        return newTokenId;
    }

    /**
     * @notice Burns an EvoNode, unstaking the collateral Essence tokens back to the owner.
     * Only the owner of the EvoNode can burn it.
     * @param _tokenId The ID of the EvoNode to burn.
     */
    function burnEvoNode(uint256 _tokenId) public nonReentrant whenNotPaused {
        EvoNode storage node = evoNodeDetails[_tokenId];
        if (node.tokenId == 0) {
            revert NodeNotFound();
        }
        if (node.owner != msg.sender) {
            revert NotNodeOwner();
        }

        uint256 unstakeAmount = node.stakeAmount;
        uint256 finalEssencePoints = node.essencePoints; // Points are lost on burn if not claimed

        // Transfer staked tokens back
        if (!essenceToken.transfer(msg.sender, unstakeAmount)) {
            revert InvalidAmount(); // Should not happen if balance exists
        }

        evoNodes.burn(_tokenId);

        // Delete node data
        delete evoNodeDetails[_tokenId];

        emit EvoNodeBurned(_tokenId, msg.sender, finalEssencePoints);
    }

    /**
     * @notice Triggers an EvoNode's evolution if it meets the criteria for the next stage.
     * Criteria include accumulated Essence points and time since last evolution/mint.
     * @param _tokenId The ID of the EvoNode to evolve.
     */
    function triggerEvolution(uint256 _tokenId) public nonReentrant whenNotPaused {
        EvoNode storage node = evoNodeDetails[_tokenId];
        if (node.tokenId == 0) {
            revert NodeNotFound();
        }
        if (node.owner != msg.sender) {
            revert NotNodeOwner();
        }

        // Accrue any pending essence points before checking evolution
        _accrueEssencePoints(_tokenId);

        uint8 currentStage = node.evolutionStage;
        uint8 nextStage = currentStage + 1;

        if (nextStage > maxEvolutionStage) {
            revert AlreadyEvolved(); // Node is at max stage
        }

        EvolutionRule storage nextRule = evolutionRules[nextStage];
        if (node.essencePoints < nextRule.essenceRequired ||
            (block.timestamp - node.lastInteractionTime) < nextRule.timeThreshold) {
            revert NotReadyForEvolution();
        }

        // Perform evolution
        node.evolutionStage = nextStage;
        node.lastInteractionTime = block.timestamp;
        // Generate new attributes hash (e.g., from stage name and time)
        node.attributesHash = keccak256(abi.encodePacked(nextRule.stageName, block.timestamp, _tokenId));

        emit EvoNodeEvolved(_tokenId, nextStage, node.attributesHash);
    }

    /**
     * @notice Links a finalized AI creation to an EvoNode, potentially affecting its attributes or evolution.
     * Requires consumption of a certain amount of Essence points from the EvoNode.
     * @param _tokenId The ID of the EvoNode to link the AI creation to.
     * @param _proposalId The ID of the finalized AI creation proposal.
     */
    function linkAICreationToNode(uint256 _tokenId, uint256 _proposalId) public nonReentrant whenNotPaused {
        EvoNode storage node = evoNodeDetails[_tokenId];
        if (node.tokenId == 0) {
            revert NodeNotFound();
        }
        if (node.owner != msg.sender) {
            revert NotNodeOwner();
        }

        AICreationProposal storage proposal = aiCreationProposals[_proposalId];
        if (proposal.id == 0 || proposal.state != ProposalState.Finalized) {
            revert ProposalNotFound();
        }

        // Accrue any pending essence points before consuming
        _accrueEssencePoints(_tokenId);

        uint256 essenceBurnCost = protocolParameters["NODE_ESSENCE_BURN_RATE"];
        if (node.essencePoints < essenceBurnCost) {
            revert InsufficientEssence();
        }

        node.essencePoints -= essenceBurnCost; // Consume Essence for linking
        node.linkedAICreationId = _proposalId;
        // Further enhance attributes hash based on AI content hash
        node.attributesHash = keccak256(abi.encodePacked(node.attributesHash, proposal.contentHash, block.timestamp));
        node.lastInteractionTime = block.timestamp; // Mark interaction time

        emit AICreationLinkedToNode(_tokenId, _proposalId);
    }

    /**
     * @notice Gets the detailed information of a specific EvoNode.
     * @param _tokenId The ID of the EvoNode.
     * @return EvoNode struct containing all node details.
     */
    function getNodeDetails(uint256 _tokenId) public view returns (EvoNode memory) {
        return evoNodeDetails[_tokenId];
    }

    /**
     * @notice Gets the human-readable name of an EvoNode's current evolution stage.
     * @param _tokenId The ID of the EvoNode.
     * @return The name of the evolution stage.
     */
    function getEvolutionStage(uint256 _tokenId) public view returns (string memory) {
        EvoNode storage node = evoNodeDetails[_tokenId];
        if (node.tokenId == 0) {
            revert NodeNotFound();
        }
        return evolutionRules[node.evolutionStage].stageName;
    }

    // --- II. Essence Token (ERC20) & Staking ---

    /**
     * @notice Allows users to claim their accumulated Essence rewards.
     * This function transfers accumulated essencePoints from EvoNodes to the user.
     */
    function claimEssence() public nonReentrant whenNotPaused {
        uint256 totalClaimable = 0;
        uint256 ownerTokenCount = evoNodes.balanceOf(msg.sender);
        
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            uint256 tokenId = evoNodes.tokenOfOwnerByIndex(msg.sender, i);
            EvoNode storage node = evoNodeDetails[tokenId];
            // Accrue any pending essence points before claiming
            _accrueEssencePoints(tokenId);
            totalClaimable += node.essencePoints;
            node.essencePoints = 0; // Reset points after claiming
        }

        if (totalClaimable == 0) {
            revert NoEssenceToClaim();
        }

        essenceToken.mint(msg.sender, totalClaimable); // Mint and transfer Essence
        emit EssenceClaimed(msg.sender, totalClaimable);
    }

    /**
     * @notice Returns the total amount of Essence a user can claim from their EvoNodes.
     * @param _user The address of the user.
     * @return The total claimable Essence.
     */
    function getClaimableEssence(address _user) public view returns (uint256) {
        uint256 totalClaimable = 0;
        uint256 ownerTokenCount = evoNodes.balanceOf(_user);

        for (uint256 i = 0; i < ownerTokenCount; i++) {
            uint256 tokenId = evoNodes.tokenOfOwnerByIndex(_user, i);
            EvoNode storage node = evoNodeDetails[tokenId];
            // Simulate accrual for current view
            uint256 timeDelta = block.timestamp - node.lastInteractionTime;
            uint256 potentialAccrual = (timeDelta * protocolParameters["ESSENCE_ACCRUAL_RATE"]) / 1 days; // Assuming per day rate
            totalClaimable += node.essencePoints + potentialAccrual;
        }
        return totalClaimable;
    }

    /**
     * @notice Internal function to stake Essence tokens for node creation/maintenance.
     * Called by `mintEvoNode`.
     * @param _user The address from which tokens are transferred.
     * @param _amount The amount of Essence tokens to stake.
     */
    function stakeForNode(address _user, uint256 _amount) internal onlyEvoSphereInternalCall {
        if (!essenceToken.transferFrom(_user, address(this), _amount)) {
            revert InsufficientEssence();
        }
    }

    /**
     * @notice Internal function to unstake Essence tokens from nodes.
     * Called by `burnEvoNode`.
     * @param _user The address to which tokens are transferred.
     * @param _amount The amount of Essence tokens to unstake.
     */
    function unstakeFromNode(address _user, uint256 _amount) internal onlyEvoSphereInternalCall {
        if (!essenceToken.transfer(_user, _amount)) {
            revert InvalidAmount(); // Should not happen if balance exists
        }
    }

    /**
     * @notice Internal function to accrue Essence points to a specific EvoNode.
     * Called internally by claimEssence and triggerEvolution to update points based on time.
     * @param _tokenId The ID of the EvoNode to accrue points for.
     */
    function _accrueEssencePoints(uint256 _tokenId) internal {
        EvoNode storage node = evoNodeDetails[_tokenId];
        uint256 timeDelta = block.timestamp - node.lastInteractionTime;
        uint256 accrued = (timeDelta * protocolParameters["ESSENCE_ACCRUAL_RATE"]) / 1 days; // Example: per 1 day
        node.essencePoints += accrued;
        node.lastInteractionTime = block.timestamp;
    }


    // --- III. AI Synthesis & Curation ---

    /**
     * @notice Submits a proposal for an AI-generated asset.
     * Proposer stakes a bond.
     * @param _promptHash Hash of the input prompt used for AI generation.
     * @param _contentHash Hash of the AI-generated content (e.g., IPFS CID for image/text).
     * @param _externalAIModelId ID of the whitelisted AI model used for generation.
     * @param _metadataURI URI for off-chain metadata describing the asset.
     * @return proposalId The ID of the new AI creation proposal.
     */
    function submitAICreationProposal(
        string memory _promptHash,
        string memory _contentHash,
        uint256 _externalAIModelId,
        string memory _metadataURI
    ) public nonReentrant whenNotPaused returns (uint256) {
        if (!externalAIModels[_externalAIModelId].whitelisted) {
            revert NotWhitelistedModel();
        }
        uint256 bond = protocolParameters["AI_PROPOSAL_BOND"];
        if (!essenceToken.transferFrom(msg.sender, address(this), bond)) {
            revert InsufficientEssence();
        }

        _aiProposalIds.increment();
        uint256 newProposalId = _aiProposalIds.current();

        AICreationProposal storage newProposal = aiCreationProposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.promptHash = _promptHash;
        newProposal.contentHash = _contentHash;
        newProposal.metadataURI = _metadataURI;
        newProposal.externalAIModelId = _externalAIModelId;
        newProposal.submitTime = block.timestamp;
        newProposal.state = ProposalState.Voting; // Immediately open for voting
        newProposal.bondAmount = bond;

        emit AICreationProposalSubmitted(newProposalId, msg.sender, _promptHash, _contentHash);
        return newProposalId;
    }

    /**
     * @notice Votes on an AI creation proposal.
     * Only addresses with a certain amount of Essence tokens or an EvoNode can vote.
     * Vote weight can be based on Essence holdings or number/stage of EvoNodes.
     * For simplicity, this example uses Essence balance as vote weight.
     * @param _proposalId The ID of the AI creation proposal.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnAICreationProposal(uint256 _proposalId, bool _approve) public nonReentrant whenNotPaused {
        AICreationProposal storage proposal = aiCreationProposals[_proposalId];
        if (proposal.id == 0 || proposal.state != ProposalState.Voting) {
            revert NotActiveProposal();
        }
        if (hasVotedOnAIProposal[_proposalId][msg.sender]) {
            revert AlreadyVoted();
        }
        if (block.timestamp > proposal.submitTime + protocolParameters["AI_VOTING_PERIOD"]) {
            revert InvalidVote(); // Voting period ended
        }

        uint256 voteWeight = essenceToken.balanceOf(msg.sender);
        if (voteWeight == 0) {
            revert InvalidVote(); // Must hold Essence to vote
        }

        if (_approve) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        hasVotedOnAIProposal[_proposalId][msg.sender] = true;

        emit AICreationProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice Challenges an AI creation proposal if it is deemed low quality or fraudulent.
     * Requires a larger bond than the submission bond.
     * @param _proposalId The ID of the AI creation proposal to challenge.
     * @param _reason A string describing the reason for the challenge.
     */
    function challengeAICreationProposal(uint256 _proposalId, string memory _reason) public nonReentrant whenNotPaused {
        AICreationProposal storage proposal = aiCreationProposals[_proposalId];
        if (proposal.id == 0 || (proposal.state != ProposalState.Voting && proposal.state != ProposalState.Pending)) {
            revert NotActiveProposal();
        }
        if (proposal.challengeId != 0) {
            revert ChallengeInProgress();
        }

        uint256 challengeBond = proposal.bondAmount * protocolParameters["AI_CHALLENGE_BOND_MULTIPLIER"];
        if (!essenceToken.transferFrom(msg.sender, address(this), challengeBond)) {
            revert InsufficientEssence();
        }

        _aiChallengeIds.increment();
        uint256 newChallengeId = _aiChallengeIds.current();

        AIChallenge storage newChallenge = aiChallenges[newChallengeId];
        newChallenge.id = newChallengeId;
        newChallenge.proposalId = _proposalId;
        newChallenge.challenger = msg.sender;
        newChallenge.reason = _reason;
        newChallenge.challengeTime = block.timestamp;
        newChallenge.bondAmount = challengeBond;
        newChallenge.resolved = false;
        newChallenge.successful = false;

        proposal.state = ProposalState.Challenged;
        proposal.challengeId = newChallengeId;

        emit AICreationProposalChallenged(_proposalId, newChallengeId, msg.sender);
    }

    /**
     * @notice Finalizes an AI proposal. This can be called by anyone after the voting period ends or a challenge is resolved.
     * Distributes rewards or burns bonds based on outcome.
     * @param _proposalId The ID of the AI creation proposal to finalize.
     */
    function finalizeAICreationProposal(uint256 _proposalId) public nonReentrant whenNotPaused {
        AICreationProposal storage proposal = aiCreationProposals[_proposalId];
        if (proposal.id == 0 || proposal.state == ProposalState.Finalized || proposal.state == ProposalState.Rejected) {
            revert ProposalNotFound();
        }

        if (proposal.state == ProposalState.Challenged) {
            AIChallenge storage challenge = aiChallenges[proposal.challengeId];
            if (!challenge.resolved) {
                revert ChallengeInProgress(); // Challenge needs to be resolved first (e.g., via off-chain oracle or further DAO vote)
            }
            if (challenge.successful) {
                // Challenge was successful: proposer loses bond, challenger gets reward
                // Challenger gets back their bond + proposer's bond. Proposer loses all.
                if (!essenceToken.transfer(challenge.challenger, proposal.bondAmount + challenge.bondAmount)) {
                    revert InvalidAmount();
                }
                proposal.state = ProposalState.Rejected;
                emit AICreationProposalFinalized(_proposalId, ProposalState.Rejected, 0);
            } else {
                // Challenge failed: challenger loses bond, proposer gets reward
                // Challenger's bond goes to proposer + treasury
                uint256 challengerLoss = challenge.bondAmount;
                uint256 proposerReward = challengerLoss / 2; // Example: 50% to proposer
                uint256 treasuryCut = challengerLoss - proposerReward;
                
                if (!essenceToken.transfer(proposal.proposer, proposal.bondAmount + proposerReward)) {
                    revert InvalidAmount();
                }
                if (treasuryCut > 0 && !essenceToken.transfer(treasuryAddress, treasuryCut)) {
                    revert InvalidAmount();
                }
                proposal.state = ProposalState.Finalized;
                emit AICreationProposalFinalized(_proposalId, ProposalState.Finalized, proposal.bondAmount + proposerReward);
            }
        } else if (block.timestamp <= proposal.submitTime + protocolParameters["AI_VOTING_PERIOD"]) {
            revert ProposalStillActive(); // Voting period not over
        } else { // Voting period ended, not challenged
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            if (totalVotes < protocolParameters["AI_MIN_VOTES_REQUIRED"]) {
                // Not enough votes, proposal fails
                proposal.state = ProposalState.Rejected;
                // Return proposer's bond
                if (!essenceToken.transfer(proposal.proposer, proposal.bondAmount)) {
                    revert InvalidAmount();
                }
                emit AICreationProposalFinalized(_proposalId, ProposalState.Rejected, 0);
                return;
            }

            uint256 approvalPercentage = (proposal.votesFor * 100) / totalVotes;

            if (approvalPercentage >= protocolParameters["AI_APPROVAL_THRESHOLD_PERCENT"]) {
                proposal.state = ProposalState.Finalized;
                // Proposer gets bond back + a small reward from treasury/system if desired
                if (!essenceToken.transfer(proposal.proposer, proposal.bondAmount)) {
                    revert InvalidAmount();
                }
                // Optional: Mint additional essence for proposer as reward
                essenceToken.mint(proposal.proposer, proposal.bondAmount / 10); // Example reward
                emit AICreationProposalFinalized(_proposalId, ProposalState.Finalized, proposal.bondAmount);
            } else {
                proposal.state = ProposalState.Rejected;
                // Proposer loses bond (or portion of it) to treasury
                if (!essenceToken.transfer(treasuryAddress, proposal.bondAmount)) {
                    revert InvalidAmount();
                }
                emit AICreationProposalFinalized(_proposalId, ProposalState.Rejected, 0);
            }
        }
    }

    /**
     * @notice Resolves an AI creation challenge. This function would typically be called by a trusted oracle or DAO vote.
     * For this example, it's callable by the contract owner for demonstration purposes.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _successful True if the challenge was successful (meaning the original proposal was invalid), false otherwise.
     */
    function resolveAICreationChallenge(uint256 _challengeId, bool _successful) public onlyOwner {
        AIChallenge storage challenge = aiChallenges[_challengeId];
        if (challenge.id == 0 || challenge.resolved) {
            revert NoChallengeToResolve();
        }

        challenge.resolved = true;
        challenge.successful = _successful;

        // Trigger finalization of the associated proposal
        finalizeAICreationProposal(challenge.proposalId);
    }


    /**
     * @notice Registers an external AI model as whitelisted. Only callable by the DAO via governance.
     * Whitelisted models can be referenced in AI creation proposals.
     * @param _modelName The name of the AI model.
     * @param _modelURI URI providing more info about the model (e.g., source, documentation).
     * @param _description A brief description of the model.
     * @return modelId The ID of the newly registered model.
     */
    function registerExternalAIModel(
        string memory _modelName,
        string memory _modelURI,
        string memory _description
    ) public onlyOwner returns (uint256) { // In a full DAO, this would be callable via executeGovernanceProposal
        _aiModelIds.increment();
        uint256 newModelId = _aiModelIds.current();
        externalAIModels[newModelId] = ExternalAIModel({
            name: _modelName,
            uri: _modelURI,
            description: _description,
            whitelisted: true
        });
        emit ExternalAIModelRegistered(newModelId, _modelName);
        return newModelId;
    }

    /**
     * @notice Gets the detailed information of an AI creation proposal.
     * @param _proposalId The ID of the AI creation proposal.
     * @return AICreationProposal struct containing all proposal details.
     */
    function getAICreationProposalDetails(uint256 _proposalId) public view returns (AICreationProposal memory) {
        return aiCreationProposals[_proposalId];
    }

    // --- IV. DAO Governance & Protocol Parameters ---

    /**
     * @notice Submits a general governance proposal.
     * Callable by anyone, but must meet minimum stake/token requirements to be considered.
     * @param _target The address of the contract to call if the proposal passes.
     * @param _callData The calldata to be executed on the target contract.
     * @param _description A description of the proposal.
     * @return proposalId The ID of the new governance proposal.
     */
    function submitGovernanceProposal(
        address _target,
        bytes calldata _callData,
        string memory _description
    ) public nonReentrant whenNotPaused returns (uint256) {
        // Require minimum Essence balance to propose
        if (essenceToken.balanceOf(msg.sender) < protocolParameters["MIN_EVONODE_STAKE"]) { // Reusing parameter, adjust if needed
            revert InsufficientEssence();
        }

        _govProposalIds.increment();
        uint256 newProposalId = _govProposalIds.current();

        GovernanceProposal storage newGovProposal = governanceProposals[newProposalId];
        newGovProposal.id = newProposalId;
        newGovProposal.proposer = msg.sender;
        newGovProposal.target = _target;
        newGovProposal.callData = _callData;
        newGovProposal.description = _description;
        newGovProposal.submitTime = block.timestamp;
        newGovProposal.votingEndTime = block.timestamp + protocolParameters["GOV_VOTING_PERIOD"];
        newGovProposal.state = GovernanceProposalState.Active;
        newGovProposal.executed = false;

        emit GovernanceProposalSubmitted(newProposalId, msg.sender, _description);
        return newProposalId;
    }

    /**
     * @notice Votes on a general governance proposal.
     * Vote weight is based on the caller's Essence token balance at the time of voting.
     * @param _proposalId The ID of the governance proposal.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _approve) public nonReentrant whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0 || proposal.state != GovernanceProposalState.Active) {
            revert NotActiveProposal();
        }
        if (hasVotedOnGovProposal[_proposalId][msg.sender]) {
            revert AlreadyVoted();
        }
        if (block.timestamp > proposal.votingEndTime) {
            revert InvalidVote(); // Voting period ended
        }

        uint256 voteWeight = essenceToken.balanceOf(msg.sender);
        if (voteWeight == 0) {
            revert InvalidVote(); // Must hold Essence to vote
        }

        if (_approve) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        hasVotedOnGovProposal[_proposalId][msg.sender] = true;

        emit GovernanceProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice Executes a passed governance proposal.
     * Anyone can call this after the voting period ends and the proposal has succeeded.
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) public nonReentrant whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0 || proposal.executed) {
            revert ProposalNotFound();
        }
        if (block.timestamp <= proposal.votingEndTime) {
            revert ProposalStillActive();
        }

        uint256 totalEssenceSupply = essenceToken.totalSupply();
        uint256 quorum = (totalEssenceSupply * protocolParameters["GOV_QUORUM_PERCENT"]) / 100;
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

        if (totalVotes < quorum) {
            proposal.state = GovernanceProposalState.Failed;
            revert InsufficientVotes(); // Not enough participation
        }

        uint256 approvalPercentage = (proposal.votesFor * 100) / totalVotes;

        if (approvalPercentage >= protocolParameters["GOV_APPROVAL_THRESHOLD_PERCENT"]) {
            // Proposal passed, execute it
            proposal.state = GovernanceProposalState.Succeeded;
            (bool success, ) = proposal.target.call(proposal.callData);
            if (!success) {
                // If execution fails, mark as failed but keep success status for voting outcome
                proposal.state = GovernanceProposalState.Failed;
                revert("EvoSphere: Proposal execution failed");
            }
            proposal.executed = true;
            proposal.state = GovernanceProposalState.Executed;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.state = GovernanceProposalState.Failed;
            revert InsufficientVotes(); // Did not meet approval threshold
        }
    }

    /**
     * @notice DAO-controlled function to update core protocol parameters.
     * This function is callable by the owner, but intended to be called via a successful governance proposal.
     * @param _paramName The keccak256 hash of the parameter name (e.g., keccak256("MIN_EVONODE_STAKE")).
     * @param _value The new value for the parameter.
     */
    function setProtocolParameter(bytes32 _paramName, uint256 _value) public onlyOwner { // Intended to be DAO callable via executeGovernanceProposal
        protocolParameters[_paramName] = _value;
        emit ProtocolParameterUpdated(_paramName, _value);
    }

    /**
     * @notice DAO-controlled function to modify the rules for EvoNode evolution stages.
     * This function is callable by the owner, but intended to be called via a successful governance proposal.
     * @param _stage The evolution stage number.
     * @param _essenceRequired The new amount of Essence points required for this stage.
     * @param _timeThreshold The new time threshold (in seconds) required for this stage.
     * @param _stageName The new human-readable name for this stage.
     * @param _metadataPrefix The new IPFS/URI prefix for metadata images for this stage.
     */
    function updateEvolutionRule(
        uint8 _stage,
        uint256 _essenceRequired,
        uint256 _timeThreshold,
        string memory _stageName,
        string memory _metadataPrefix
    ) public onlyOwner { // Intended to be DAO callable via executeGovernanceProposal
        evolutionRules[_stage] = EvolutionRule({
            essenceRequired: _essenceRequired,
            timeThreshold: _timeThreshold,
            stageName: _stageName,
            metadataPrefix: _metadataPrefix
        });
        if (_stage > maxEvolutionStage) {
            maxEvolutionStage = _stage;
        }
    }

    // --- V. Treasury & Fees ---

    /**
     * @notice Allows withdrawal of funds from the contract's treasury to a specified recipient.
     * This function is callable by the owner, but intended to be called via a successful governance proposal.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of funds (Essence tokens) to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyOwner nonReentrant { // Intended to be DAO callable via executeGovernanceProposal
        if (_recipient == address(0)) {
            revert ZeroAddress();
        }
        if (_amount == 0 || essenceToken.balanceOf(address(this)) < _amount) {
            revert InvalidAmount();
        }
        if (!essenceToken.transfer(_recipient, _amount)) {
            revert InvalidAmount();
        }
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /**
     * @notice Sets the address of the protocol treasury.
     * This function is callable by the owner, but intended to be called via a successful governance proposal.
     * @param _newTreasury The new treasury address.
     */
    function setTreasuryAddress(address _newTreasury) public onlyOwner { // Intended to be DAO callable via executeGovernanceProposal
        if (_newTreasury == address(0)) {
            revert ZeroAddress();
        }
        treasuryAddress = _newTreasury;
        emit TreasuryAddressSet(_newTreasury);
    }

    // --- VI. Utilities & Access Control ---

    /**
     * @notice Pauses the contract, preventing certain state-changing operations.
     * Callable by the owner (or DAO via governance).
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, re-enabling state-changing operations.
     * Callable by the owner (or DAO via governance).
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Returns the current ETH balance of the contract.
     * @return The ETH balance.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Fallback and Receive functions to ensure ETH sent directly is handled (though not core to Essence-based system)
    receive() external payable {}
    fallback() external payable {}
}

// --- EvoSphereERC721 (Inner Contract for EvoNodes) ---
contract EvoSphereERC721 is ERC721Enumerable, Ownable { // Inherits ERC721Enumerable for tokensOfOwnerByIndex
    address public evoSphereCore; // Address of the main EvoSphere contract

    constructor(address _evoSphereCore) ERC721("EvoSphereNode", "EVN") Ownable(msg.sender) {
        if (_evoSphereCore == address(0)) revert ZeroAddress();
        evoSphereCore = _evoSphereCore;
    }

    modifier onlyEvoSphereCore() {
        require(msg.sender == evoSphereCore, "ERC721: Only EvoSphere core contract can call this");
        _;
    }

    // Internal function to allow EvoSphere contract to mint tokens
    function mint(address to, uint256 tokenId) public onlyEvoSphereCore {
        _mint(to, tokenId);
    }

    // Internal function to allow EvoSphere contract to burn tokens
    function burn(uint256 tokenId) public onlyEvoSphereCore {
        _burn(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Generates a dynamic token URI based on the EvoNode's current attributes.
     * This is a critical feature for Dynamic NFTs.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        // Fetch EvoNode details from the main EvoSphere contract
        EvoSphere evoSphere = EvoSphere(evoSphereCore);
        EvoSphere.EvoNode memory node = evoSphere.evoNodeDetails(tokenId);
        EvoSphere.EvolutionRule memory rule = evoSphere.evolutionRules(node.evolutionStage);

        // Construct JSON metadata. Essence amounts are divided by 10^18 for human readability.
        string memory json = string(abi.encodePacked(
            '{"name": "EvoNode #', Strings.toString(tokenId),
            '", "description": "An evolving digital entity on EvoSphere. Current stage: ', rule.stageName, '",',
            '"image": "', rule.metadataPrefix, // Use metadataPrefix from evolution rule for image
            '", "attributes": [',
                '{"trait_type": "Evolution Stage", "value": "', rule.stageName, '"},',
                '{"trait_type": "Essence Points", "value": "', Strings.toString(node.essencePoints / (10 ** 18)), '"},', 
                '{"trait_type": "Stake Amount", "value": "', Strings.toString(node.stakeAmount / (10 ** 18)), '"},',
                '{"trait_type": "Last Interaction", "value": "', Strings.toString(node.lastInteractionTime), '"},',
                '{"trait_type": "Linked AI Creation", "value": "', Strings.toString(node.linkedAICreationId), '"}'
            ']}'
        ));

        // Encode JSON as Base64 and prefix with data URI scheme
        string memory baseURI = "data:application/json;base64,";
        return string(abi.encodePacked(baseURI, Base64.encode(bytes(json))));
    }

    /**
     * @dev Overrides the default `_beforeTokenTransfer` to prevent direct transfers.
     * EvoNodes are non-transferable directly by users, ensuring their management
     * is solely through the EvoSphere core contract's staking and burning mechanisms.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // Allow minting (from address(0)), burning (to address(0)), and transfers initiated by core contract
        // This ensures NFTs can only be managed via the EvoSphere core logic.
        if (from != address(0) && to != address(0)) { // Normal transfer
            require(msg.sender == evoSphereCore, "ERC721: Tokens are non-transferable directly. Use EvoSphere functions.");
        }
    }
}


// --- EvoSphereEssence (Inner Contract for Essence Token) ---
contract EvoSphereEssence is ERC20, Ownable {
    address public evoSphereCore; // Address of the main EvoSphere contract

    constructor(address _evoSphereCore) ERC20("EvoSphere Essence", "ESS") Ownable(msg.sender) {
        if (_evoSphereCore == address(0)) revert ZeroAddress();
        evoSphereCore = _evoSphereCore;
        // Example: Mint initial supply to the core contract or deployer for liquidity/initial treasury.
        // For a real scenario, initial minting strategy needs careful consideration.
        // _mint(msg.sender, 1_000_000 * (10 ** 18)); // Mints 1,000,000 ESS to the deployer
    }

    modifier onlyEvoSphereCore() {
        require(msg.sender == evoSphereCore, "ERC20: Only EvoSphere core contract can call mint/burn");
        _;
    }

    // Internal function to allow EvoSphere contract to mint tokens
    function mint(address to, uint256 amount) public onlyEvoSphereCore {
        _mint(to, amount);
    }

    // Internal function to allow EvoSphere contract to burn tokens
    function burn(address from, uint256 amount) public onlyEvoSphereCore {
        _burn(from, amount);
    }
}
```