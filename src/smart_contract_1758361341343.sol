This smart contract, named `AetherForge`, explores advanced concepts in Web3 by creating a dynamic, AI-augmented creative studio on the blockchain. It features two novel NFT types:

1.  **SynapseNFTs**: These are not just images; they represent conceptual "creative fragments" or "AI prompt structures." They can be combined (fused) or refined through AI. Their metadata is dynamic and evolves based on AI interaction and community engagement, reflecting their "potential" or "synergy."
2.  **ArtisticOutputNFTs**: These are the actual creative works generated using SynapseNFTs and an AI oracle. Creators retain ownership and can set royalties, fostering a direct creator economy.

The contract integrates with a decentralized AI Oracle for off-chain computation (content generation, metadata refinement) and uses a robust DAO structure with a unique "Influence Points" reputation system for governance and curation.

---

### Contract Outline & Function Summary

**Contract Name:** `AetherForge`

**Core Concepts:**
*   **Dynamic NFTs:** SynapseNFTs evolve, can be fused, and their metadata is updated by AI.
*   **AI Oracle Integration:** Triggers off-chain AI computation for content generation and metadata refinement, receiving results on-chain.
*   **Reputation-Based DAO:** "Influence Points" dictate voting power and access, driving decentralized governance.
*   **Creator Economy:** `ArtisticOutputNFTs` with creator-defined royalties for generated content.
*   **Creative Challenges:** Community-driven contests to foster creation and curation.

---

### Function Summary

**I. Core Infrastructure & Access Control**

1.  `constructor()`: Initializes the contract, sets up roles (admin, AI Oracle, Synapse Minter, etc.).
2.  `setAIOracleAddress(address _newOracle)`: Admin/DAO function to update the trusted AI oracle address.
3.  `setAetherForgeConfig(uint256 _baseFusionCost, uint256 _proposalThreshold, uint256 _challengeDuration, uint256 _royaltyFeeFraction)`: Admin/DAO function to set various core operational parameters (costs, DAO thresholds, durations).
4.  `depositTreasury()`: Allows users to deposit ETH into the protocol treasury, which can be used for AI bounties, rewards, etc.
5.  `withdrawTreasuryFunds(address recipient, uint256 amount)`: DAO/Admin function to disburse funds from the treasury.

**II. SynapseNFTs (ERC721 - AI Prompt Elements)**

6.  `mintBaseSynapse(address to, string memory initialMetadataURI)`: Allows `SYNAPSE_MINTER_ROLE` to mint foundational SynapseNFTs.
7.  `fuseSynapseNFTs(uint256[] calldata tokenIdsToBurn, string memory fusionPrompt)`: Users burn multiple SynapseNFTs as input, providing a `fusionPrompt`. This triggers an AI oracle request to create a new, potentially more advanced SynapseNFT or a direct `ArtisticOutputNFT`. Requires a `baseFusionCost`.
8.  `requestSynapseRefinement(uint256 tokenId, string memory refinementPrompt)`: User requests the AI oracle to refine an existing SynapseNFT's "potential" or metadata based on a new prompt, evolving its utility.
9.  `updateSynapsePotential(uint256 tokenId, uint256 newPotentialScore, string memory newMetadataURI)`: Called by the `AI_ORACLE_ROLE` to update a SynapseNFT's internal "potential" score and external metadata URI after AI processing.
10. `getSynapseDetails(uint256 tokenId)`: A view function to retrieve all stored details of a specific SynapseNFT.

**III. Artistic Output NFTs (ERC721 - AI-Generated Creations)**

11. `requestArtisticOutput(uint256[] calldata synapseTokenIds, string memory creativePrompt, uint256 royaltyBasisPoints)`: Users initiate the generation of an `ArtisticOutputNFT` by providing SynapseNFTs and a creative prompt. They also set an initial royalty percentage. This triggers an AI oracle request.
12. `mintArtisticOutputNFT(address creator, string memory metadataURI, uint256 artisticOutputId, uint256 royaltyBasisPoints)`: Called by the `AI_ORACLE_ROLE` to finalize the creation and mint the `ArtisticOutputNFT` to the designated creator after AI generation.
13. `updateArtisticOutputRoyalty(uint256 artisticOutputId, uint256 newRoyaltyBasisPoints)`: Allows the creator of an `ArtisticOutputNFT` to adjust their royalty percentage for future sales.
14. `distributeArtisticOutputRoyalties(uint256 artisticOutputId, address seller, address buyer, uint256 amount)`: A mechanism (intended to be called by marketplaces or manually) to distribute royalties from an `ArtisticOutputNFT` sale to the creator and the AetherForge treasury.

**IV. DAO & Influence System**

15. `earnInfluencePoints(address user, uint256 amount, string memory reason)`: Called by `INFLUENCE_AWARDER_ROLE` (admin, oracles, or automated systems) to award Influence Points for valuable contributions.
16. `delegateInfluence(address delegatee)`: Allows users to delegate their Influence Points (voting power) to another address.
17. `submitProposal(string memory description, address targetContract, bytes memory callData, string memory justification)`: Users with sufficient Influence Points can submit governance proposals for contract changes or treasury actions.
18. `voteOnProposal(uint256 proposalId, bool support)`: Users cast their vote (using their Influence Points) on active proposals.
19. `executeProposal(uint256 proposalId)`: Executes a proposal once it has passed the voting period and threshold.

**V. Creative Challenges & Curation**

20. `startCreativeChallenge(string memory title, string memory description, uint256 submissionDeadline, uint256 rewardPool)`: `CHALLENGE_MANAGER_ROLE` or DAO initiates a new creative challenge with specific parameters and rewards.
21. `submitChallengeEntry(uint256 challengeId, uint256 artisticOutputId)`: Users submit their `ArtisticOutputNFTs` as entries to an ongoing challenge.
22. `voteOnChallengeEntry(uint256 challengeId, uint256 artisticOutputId, uint8 score)`: Community members (potentially with weighted Influence Points) can score or vote on challenge entries.
23. `finalizeChallenge(uint256 challengeId)`: `CHALLENGE_MANAGER_ROLE` or DAO finalizes a challenge, determines winners based on votes, and distributes rewards (e.g., Influence Points, ETH from `rewardPool`).

**VI. AI Oracle Callbacks & Verification**

24. `receiveAIGenerationResult(bytes32 requestId, bool success, string memory resultData, uint256[] memory involvedTokenIds)`: This is the generic callback function for the `AI_ORACLE_ROLE`. It receives results from off-chain AI computations and routes them to the appropriate internal logic (e.g., minting an NFT, updating Synapse metadata) based on the `requestId`. This design allows a single callback for various AI requests.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For easier token enumeration (optional, but good for discovery)

/**
 * @title AetherForge
 * @dev A smart contract for an AI-augmented creative studio, featuring dynamic NFTs,
 *      an AI oracle integration, a reputation-based DAO, and a creator economy.
 *      It allows users to fuse "SynapseNFTs" (AI prompt elements) to generate
 *      "ArtisticOutputNFTs" (AI-generated creations) and govern the studio.
 *
 * Outline & Function Summary:
 *
 * I. Core Infrastructure & Access Control
 *    1. constructor(): Initializes contract, sets roles.
 *    2. setAIOracleAddress(address _newOracle): Admin/DAO to update AI oracle.
 *    3. setAetherForgeConfig(...): Admin/DAO to set operational parameters.
 *    4. depositTreasury(): Allows ETH deposits to treasury.
 *    5. withdrawTreasuryFunds(address recipient, uint256 amount): DAO/Admin to disburse funds.
 *
 * II. SynapseNFTs (ERC721 - AI Prompt Elements)
 *    6. mintBaseSynapse(address to, string memory initialMetadataURI): SYNAPSE_MINTER_ROLE mints foundational SynapseNFTs.
 *    7. fuseSynapseNFTs(uint256[] calldata tokenIdsToBurn, string memory fusionPrompt): Users burn SynapseNFTs to request AI fusion for new SynapseNFTs or ArtisticOutputs.
 *    8. requestSynapseRefinement(uint256 tokenId, string memory refinementPrompt): Users request AI to refine an existing SynapseNFT's potential.
 *    9. updateSynapsePotential(uint256 tokenId, uint256 newPotentialScore, string memory newMetadataURI): AI_ORACLE_ROLE updates SynapseNFT metadata post-AI processing.
 *    10. getSynapseDetails(uint256 tokenId): View function for SynapseNFT data.
 *
 * III. Artistic Output NFTs (ERC721 - AI-Generated Creations)
 *    11. requestArtisticOutput(uint256[] calldata synapseTokenIds, string memory creativePrompt, uint256 royaltyBasisPoints): Users initiate generation of ArtisticOutputNFTs, setting royalties.
 *    12. mintArtisticOutputNFT(address creator, string memory metadataURI, uint256 artisticOutputId, uint256 royaltyBasisPoints): AI_ORACLE_ROLE mints the final ArtisticOutputNFT.
 *    13. updateArtisticOutputRoyalty(uint256 artisticOutputId, uint256 newRoyaltyBasisPoints): Creator adjusts their ArtisticOutputNFT royalty.
 *    14. distributeArtisticOutputRoyalties(...): Distributes royalties from ArtisticOutputNFT sales.
 *
 * IV. DAO & Influence System
 *    15. earnInfluencePoints(address user, uint256 amount, string memory reason): INFLUENCE_AWARDER_ROLE awards Influence Points.
 *    16. delegateInfluence(address delegatee): Users delegate their Influence for voting.
 *    17. submitProposal(...): Users with enough Influence submit governance proposals.
 *    18. voteOnProposal(uint256 proposalId, bool support): Users vote on proposals using Influence.
 *    19. executeProposal(uint256 proposalId): Executes a passed proposal.
 *
 * V. Creative Challenges & Curation
 *    20. startCreativeChallenge(...): CHALLENGE_MANAGER_ROLE/DAO initiates a challenge.
 *    21. submitChallengeEntry(uint256 challengeId, uint256 artisticOutputId): Users submit ArtisticOutputNFTs to challenges.
 *    22. voteOnChallengeEntry(uint256 challengeId, uint256 artisticOutputId, uint8 score): Community votes/scores challenge entries.
 *    23. finalizeChallenge(uint256 challengeId): CHALLENGE_MANAGER_ROLE/DAO finalizes challenge, awards winners.
 *
 * VI. AI Oracle Callbacks & Verification
 *    24. receiveAIGenerationResult(...): Generic callback for AI_ORACLE_ROLE to process AI results.
 */
contract AetherForge is ERC721, ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");
    bytes32 public constant SYNAPSE_MINTER_ROLE = keccak256("SYNAPSE_MINTER_ROLE");
    bytes32 public constant INFLUENCE_AWARDER_ROLE = keccak256("INFLUENCE_AWARDER_ROLE");
    bytes32 public constant CHALLENGE_MANAGER_ROLE = keccak256("CHALLENGE_MANAGER_ROLE");

    // --- Counters for NFTs and Proposals ---
    Counters.Counter private _synapseTokenIds;
    Counters.Counter private _artisticOutputTokenIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _challengeIds;
    
    // --- Configuration Parameters ---
    struct AetherForgeConfig {
        uint256 baseFusionCost;            // ETH cost to fuse SynapseNFTs
        uint256 proposalThreshold;         // Min Influence points to submit a proposal
        uint256 voteQuorumFraction;        // E.g., 50 (for 50% quorum)
        uint256 proposalVotingPeriod;      // Duration in seconds for voting
        uint256 challengeDuration;         // Duration in seconds for challenges
        uint256 royaltyFeeFraction;        // Platform fee on ArtisticOutputNFT royalties (e.g., 500 for 5%)
    }
    AetherForgeConfig public config;

    // --- Addresses ---
    address public aiOracleAddress;
    address public treasuryAddress; // Where protocol fees go

    // --- SynapseNFT Structure ---
    struct SynapseNFT {
        uint256 tokenId;
        address creator;
        string metadataURI;
        uint256 potentialScore; // A score reflecting its AI-generation potential/complexity
        bytes32[] fusionHistory; // Hashes of previous fusions/refinements
    }
    mapping(uint256 => SynapseNFT) public synapseNFTs;

    // --- ArtisticOutputNFT Structure ---
    struct ArtisticOutputNFT {
        uint256 tokenId;
        address creator;
        string metadataURI;
        uint256 royaltyBasisPoints; // Basis points (e.g., 500 for 5%) for the creator
        bytes32 sourceRequestId;     // Link to the AI generation request
    }
    mapping(uint256 => ArtisticOutputNFT) public artisticOutputNFTs;

    // --- DAO & Influence System ---
    mapping(address => uint256) public influencePoints;
    mapping(address => address) public influenceDelegates;

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        string description;
        address targetContract;
        bytes callData;
        string justification;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 abstainedVotes; // Future: for more nuanced voting
        address proposer;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }
    mapping(uint256 => Proposal) public proposals;

    // --- Creative Challenges ---
    enum ChallengeState { Pending, Active, Submitting, Voting, Finalized }
    struct Challenge {
        uint256 id;
        string title;
        string description;
        address creator;
        uint256 startTimestamp;
        uint256 submissionDeadline;
        uint256 votingDeadline; // Voting ends after this
        uint256 rewardPool; // ETH or other tokens
        ChallengeState state;
        mapping(uint256 => bool) submittedEntries; // artisticOutputId => true
        mapping(address => mapping(uint256 => uint8)) entryScores; // voter => artisticOutputId => score (1-10)
        mapping(uint256 => uint256) totalEntryScores; // artisticOutputId => total score
        mapping(uint256 => uint256) totalVotersPerEntry; // artisticOutputId => count of voters
    }
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => uint256[]) public challengeEntries; // challengeId => list of artisticOutputIds

    // --- AI Oracle Request Tracking ---
    // requestId -> (creator, type, SynapseNFTs involved, ArtisticOutputNFT target ID)
    enum RequestType { Fusion, Refinement, ArtisticOutput }
    struct AIRequest {
        address requester;
        RequestType requestType;
        uint256[] involvedTokenIds; // SynapseNFTs for fusion/output, or single SynapseNFT for refinement
        string prompt; // The original prompt sent to AI
        uint256 artisticOutputIdTarget; // Only for ArtisticOutput requests, pre-allocated ID
        uint256 royaltyBasisPoints; // Only for ArtisticOutput requests
    }
    mapping(bytes32 => AIRequest) public pendingAIRequests;


    // --- Events ---
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ConfigUpdated(uint256 baseFusionCost, uint256 proposalThreshold, uint256 voteQuorumFraction, uint256 proposalVotingPeriod, uint256 challengeDuration, uint256 royaltyFeeFraction);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    event SynapseMinted(uint256 indexed tokenId, address indexed creator, string metadataURI);
    event SynapseFusedRequested(bytes32 indexed requestId, address indexed requester, uint256[] tokenIdsBurned, string fusionPrompt);
    event SynapseRefinementRequested(bytes32 indexed requestId, address indexed requester, uint256 indexed tokenId, string refinementPrompt);
    event SynapsePotentialUpdated(uint256 indexed tokenId, uint256 newPotentialScore, string newMetadataURI);

    event ArtisticOutputRequested(bytes32 indexed requestId, address indexed requester, uint256 indexed artisticOutputId, uint256[] synapseTokenIds, string creativePrompt, uint256 royaltyBasisPoints);
    event ArtisticOutputMinted(uint256 indexed tokenId, address indexed creator, string metadataURI, uint256 royaltyBasisPoints);
    event ArtisticOutputRoyaltyUpdated(uint256 indexed tokenId, uint256 newRoyaltyBasisPoints);
    event RoyaltiesDistributed(uint256 indexed artisticOutputId, address indexed creator, address indexed protocol, uint256 creatorAmount, uint256 protocolAmount);

    event InfluenceEarned(address indexed user, uint256 amount, string reason);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 influenceUsed, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);

    event ChallengeStarted(uint256 indexed challengeId, string title, address indexed creator, uint256 submissionDeadline, uint256 rewardPool);
    event ChallengeEntrySubmitted(uint256 indexed challengeId, uint256 indexed artisticOutputId, address indexed submitter);
    event ChallengeEntryVoted(uint256 indexed challengeId, uint256 indexed artisticOutputId, address indexed voter, uint8 score);
    event ChallengeFinalized(uint256 indexed challengeId, uint256[] winnerArtisticOutputIds); // Could be multiple winners

    event AIGenerationResultReceived(bytes32 indexed requestId, bool success, string resultData);

    // --- Constructor ---
    constructor(address _aiOracleAddress, address _treasuryAddress) ERC721("AetherForge Synapse", "AFSY") ERC721Enumerable {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // Admin has full power initially

        aiOracleAddress = _aiOracleAddress;
        treasuryAddress = _treasuryAddress;
        _grantRole(AI_ORACLE_ROLE, _aiOracleAddress); // Set initial AI Oracle
        _grantRole(SYNAPSE_MINTER_ROLE, msg.sender); // Admin can mint initial Synapses
        _grantRole(INFLUENCE_AWARDER_ROLE, msg.sender); // Admin can award Influence
        _grantRole(CHALLENGE_MANAGER_ROLE, msg.sender); // Admin can manage challenges

        // Set initial sensible configuration values
        config = AetherForgeConfig({
            baseFusionCost: 0.01 ether, // Example cost
            proposalThreshold: 100,      // 100 Influence points to propose
            voteQuorumFraction: 50,    // 50% quorum
            proposalVotingPeriod: 3 days, // 3 days voting
            challengeDuration: 7 days,   // 7 days for challenges
            royaltyFeeFraction: 500      // 5% platform fee (500 basis points)
        });
    }

    // --- ERC721 Overrides (for ERC721Enumerable) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Sets the address of the trusted AI Oracle.
     * @param _newOracle The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newOracle) public onlyRole(ADMIN_ROLE) {
        require(_newOracle != address(0), "New AI Oracle cannot be zero address");
        emit AIOracleAddressUpdated(aiOracleAddress, _newOracle);
        _revokeRole(AI_ORACLE_ROLE, aiOracleAddress); // Revoke old oracle's role
        aiOracleAddress = _newOracle;
        _grantRole(AI_ORACLE_ROLE, _newOracle); // Grant new oracle's role
    }

    /**
     * @dev Sets various core operational parameters for AetherForge.
     * @param _baseFusionCost ETH cost to fuse SynapseNFTs.
     * @param _proposalThreshold Minimum Influence points required to submit a proposal.
     * @param _voteQuorumFraction Percentage (e.g., 50 for 50%) of total Influence needed for a proposal to pass.
     * @param _proposalVotingPeriod Duration in seconds for a proposal's voting phase.
     * @param _challengeDuration Duration in seconds for a creative challenge.
     * @param _royaltyFeeFraction Platform fee on ArtisticOutputNFT royalties in basis points (e.g., 500 for 5%).
     */
    function setAetherForgeConfig(
        uint256 _baseFusionCost,
        uint256 _proposalThreshold,
        uint256 _voteQuorumFraction,
        uint256 _proposalVotingPeriod,
        uint256 _challengeDuration,
        uint256 _royaltyFeeFraction
    ) public onlyRole(ADMIN_ROLE) { // Could be changed to onlyRole(DAO_EXECUTOR_ROLE) after DAO is mature
        require(_voteQuorumFraction > 0 && _voteQuorumFraction <= 100, "Quorum fraction must be between 1 and 100");
        require(_royaltyFeeFraction <= 10000, "Royalty fee cannot exceed 100%"); // 10000 basis points = 100%
        config = AetherForgeConfig({
            baseFusionCost: _baseFusionCost,
            proposalThreshold: _proposalThreshold,
            voteQuorumFraction: _voteQuorumFraction,
            proposalVotingPeriod: _proposalVotingPeriod,
            challengeDuration: _challengeDuration,
            royaltyFeeFraction: _royaltyFeeFraction
        });
        emit ConfigUpdated(_baseFusionCost, _proposalThreshold, _voteQuorumFraction, _proposalVotingPeriod, _challengeDuration, _royaltyFeeFraction);
    }

    /**
     * @dev Allows users to deposit ETH into the protocol treasury.
     * This ETH can be used for AI bounties, challenge rewards, or other protocol operations.
     */
    function depositTreasury() public payable {
        require(msg.value > 0, "Must deposit non-zero ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows the ADMIN_ROLE or through a passed DAO proposal to withdraw funds from the treasury.
     * @param recipient The address to send the funds to.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawTreasuryFunds(address recipient, uint256 amount) public onlyRole(ADMIN_ROLE) {
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient treasury balance");
        require(recipient != address(0), "Recipient cannot be zero address");

        (bool success,) = recipient.call{value: amount}("");
        require(success, "Failed to withdraw funds");
        emit FundsWithdrawn(recipient, amount);
    }

    // --- II. SynapseNFTs (ERC721 - AI Prompt Elements) ---

    /**
     * @dev Allows the SYNAPSE_MINTER_ROLE to mint a new base-level SynapseNFT.
     * These are foundational components for AI interaction.
     * @param to The address to mint the SynapseNFT to.
     * @param initialMetadataURI The initial metadata URI for the SynapseNFT.
     */
    function mintBaseSynapse(address to, string memory initialMetadataURI) public onlyRole(SYNAPSE_MINTER_ROLE) {
        _synapseTokenIds.increment();
        uint256 newId = _synapseTokenIds.current();

        SynapseNFT storage newSynapse = synapseNFTs[newId];
        newSynapse.tokenId = newId;
        newSynapse.creator = to;
        newSynapse.metadataURI = initialMetadataURI;
        newSynapse.potentialScore = 0; // Initial score, will be updated by AI

        _mint(to, newId);
        emit SynapseMinted(newId, to, initialMetadataURI);
    }

    /**
     * @dev Allows a user to fuse multiple SynapseNFTs, potentially creating a new, more complex SynapseNFT
     * or directly an ArtisticOutputNFT. This action triggers an AI oracle request.
     * Requires burning the input SynapseNFTs and paying a base fusion cost.
     * @param tokenIdsToBurn An array of SynapseNFT token IDs to be fused (burnt).
     * @param fusionPrompt A textual prompt guiding the AI for the fusion process.
     */
    function fuseSynapseNFTs(uint256[] calldata tokenIdsToBurn, string memory fusionPrompt) public payable {
        require(tokenIdsToBurn.length >= 2, "Requires at least 2 SynapseNFTs for fusion");
        require(msg.value >= config.baseFusionCost, "Insufficient ETH for fusion cost");

        for (uint256 i = 0; i < tokenIdsToBurn.length; i++) {
            require(_isApprovedOrOwner(msg.sender, tokenIdsToBurn[i]), "Not owner or approved for SynapseNFT to burn");
            _burn(tokenIdsToBurn[i]);
            delete synapseNFTs[tokenIdsToBurn[i]]; // Remove from storage
        }

        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, block.timestamp, tokenIdsToBurn, fusionPrompt));
        pendingAIRequests[requestId] = AIRequest({
            requester: msg.sender,
            requestType: RequestType.Fusion,
            involvedTokenIds: tokenIdsToBurn, // Keep track of burnt IDs for potential future logic
            prompt: fusionPrompt,
            artisticOutputIdTarget: 0, // Not an artistic output directly
            royaltyBasisPoints: 0
        });

        // Funds collected go to treasury
        (bool success,) = treasuryAddress.call{value: msg.value}("");
        require(success, "Failed to send fusion cost to treasury");

        emit SynapseFusedRequested(requestId, msg.sender, tokenIdsToBurn, fusionPrompt);
        // AI Oracle will eventually call receiveAIGenerationResult with the outcome.
    }

    /**
     * @dev Allows a user to request the AI oracle to refine an existing SynapseNFT's "potential"
     * or update its metadata based on a new prompt. This evolves the SynapseNFT.
     * @param tokenId The ID of the SynapseNFT to refine.
     * @param refinementPrompt A textual prompt guiding the AI for the refinement process.
     */
    function requestSynapseRefinement(uint256 tokenId, string memory refinementPrompt) public {
        require(_exists(tokenId), "SynapseNFT does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved for SynapseNFT");

        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, block.timestamp, tokenId, refinementPrompt));
        pendingAIRequests[requestId] = AIRequest({
            requester: msg.sender,
            requestType: RequestType.Refinement,
            involvedTokenIds: new uint256[](0), // No burning for refinement
            prompt: refinementPrompt,
            artisticOutputIdTarget: 0,
            royaltyBasisPoints: 0
        });

        emit SynapseRefinementRequested(requestId, msg.sender, tokenId, refinementPrompt);
        // AI Oracle will eventually call receiveAIGenerationResult with the outcome.
    }

    /**
     * @dev Called by the AI_ORACLE_ROLE to update a SynapseNFT's internal "potential" score
     * and external metadata URI after AI processing (e.g., from a fusion or refinement request).
     * @param tokenId The ID of the SynapseNFT to update.
     * @param newPotentialScore The AI-determined new potential score.
     * @param newMetadataURI The new metadata URI (e.g., pointing to an updated JSON).
     */
    function updateSynapsePotential(uint256 tokenId, uint256 newPotentialScore, string memory newMetadataURI) public onlyRole(AI_ORACLE_ROLE) {
        require(_exists(tokenId), "SynapseNFT does not exist");
        SynapseNFT storage s = synapseNFTs[tokenId];
        s.potentialScore = newPotentialScore;
        s.metadataURI = newMetadataURI;
        emit SynapsePotentialUpdated(tokenId, newPotentialScore, newMetadataURI);
    }

    /**
     * @dev Returns all stored details of a specific SynapseNFT.
     * @param tokenId The ID of the SynapseNFT.
     * @return SynapseNFT struct.
     */
    function getSynapseDetails(uint256 tokenId) public view returns (SynapseNFT memory) {
        require(_exists(tokenId), "SynapseNFT does not exist");
        return synapseNFTs[tokenId];
    }

    // --- III. Artistic Output NFTs (ERC721 - AI-Generated Creations) ---

    /**
     * @dev Allows a user to initiate the generation of an ArtisticOutputNFT by providing
     * SynapseNFTs as inputs and a creative prompt. The user also sets an initial royalty percentage.
     * The input SynapseNFTs are burnt. This action triggers an AI oracle request.
     * @param synapseTokenIds An array of SynapseNFT token IDs to be used (burnt) for generation.
     * @param creativePrompt A textual prompt guiding the AI for the creative output.
     * @param royaltyBasisPoints The royalty percentage (in basis points, e.g., 500 for 5%) for the creator.
     */
    function requestArtisticOutput(uint256[] calldata synapseTokenIds, string memory creativePrompt, uint256 royaltyBasisPoints) public payable {
        require(synapseTokenIds.length >= 1, "Requires at least 1 SynapseNFT for artistic output");
        require(royaltyBasisPoints <= 10000, "Royalty cannot exceed 100%"); // 10000 basis points = 100%

        for (uint256 i = 0; i < synapseTokenIds.length; i++) {
            require(_isApprovedOrOwner(msg.sender, synapseTokenIds[i]), "Not owner or approved for SynapseNFT to burn");
            _burn(synapseTokenIds[i]);
            delete synapseNFTs[synapseTokenIds[i]]; // Remove from storage
        }

        _artisticOutputTokenIds.increment();
        uint256 newArtisticOutputId = _artisticOutputTokenIds.current();

        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, block.timestamp, synapseTokenIds, creativePrompt, newArtisticOutputId));
        pendingAIRequests[requestId] = AIRequest({
            requester: msg.sender,
            requestType: RequestType.ArtisticOutput,
            involvedTokenIds: synapseTokenIds,
            prompt: creativePrompt,
            artisticOutputIdTarget: newArtisticOutputId,
            royaltyBasisPoints: royaltyBasisPoints
        });

        emit ArtisticOutputRequested(requestId, msg.sender, newArtisticOutputId, synapseTokenIds, creativePrompt, royaltyBasisPoints);
        // AI Oracle will eventually call receiveAIGenerationResult with the outcome.
    }

    /**
     * @dev Called by the AI_ORACLE_ROLE to finalize the creation and mint an ArtisticOutputNFT
     * after successful AI generation.
     * @param creator The address of the original requester (creator).
     * @param metadataURI The metadata URI for the AI-generated artistic output.
     * @param artisticOutputId The pre-allocated token ID for this ArtisticOutputNFT.
     * @param royaltyBasisPoints The royalty percentage (in basis points) set by the creator.
     */
    function mintArtisticOutputNFT(address creator, string memory metadataURI, uint256 artisticOutputId, uint256 royaltyBasisPoints) public onlyRole(AI_ORACLE_ROLE) {
        // Here, the 'ArtisticOutputNFT' is a distinct ERC721 collection.
        // We handle it as a separate conceptual NFT within the same contract for simplicity,
        // but in a real system, it might be a separate ERC721 contract.
        // For this example, we simply use the same ERC721 functionality for both.

        // Ensure this ID was indeed pre-allocated by a request
        require(_artisticOutputTokenIds.current() >= artisticOutputId, "Invalid artistic output ID");

        ArtisticOutputNFT storage newArtisticOutput = artisticOutputNFTs[artisticOutputId];
        require(newArtisticOutput.tokenId == 0, "Artistic Output NFT already minted for this ID"); // Check if it's already minted
        
        newArtisticOutput.tokenId = artisticOutputId;
        newArtisticOutput.creator = creator;
        newArtisticOutput.metadataURI = metadataURI;
        newArtisticOutput.royaltyBasisPoints = royaltyBasisPoints;
        // newArtisticOutput.sourceRequestId = requestId; // Could link if request ID was passed here

        _mint(creator, artisticOutputId); // Mint to the creator
        // Override the token name/symbol for ArtisticOutput NFTs if needed, or simply differentiate by ID ranges/type.
        // For simplicity, they share the same ERC721 interface for now.

        emit ArtisticOutputMinted(artisticOutputId, creator, metadataURI, royaltyBasisPoints);
    }

    /**
     * @dev Allows the creator of an ArtisticOutputNFT to adjust their royalty percentage for future sales.
     * @param artisticOutputId The ID of the ArtisticOutputNFT.
     * @param newRoyaltyBasisPoints The new royalty percentage (in basis points, e.g., 750 for 7.5%).
     */
    function updateArtisticOutputRoyalty(uint256 artisticOutputId, uint256 newRoyaltyBasisPoints) public {
        ArtisticOutputNFT storage ao = artisticOutputNFTs[artisticOutputId];
        require(ao.tokenId != 0, "Artistic Output NFT does not exist");
        require(ao.creator == msg.sender, "Only creator can update royalty");
        require(newRoyaltyBasisPoints <= 10000, "Royalty cannot exceed 100%");

        ao.royaltyBasisPoints = newRoyaltyBasisPoints;
        emit ArtisticOutputRoyaltyUpdated(artisticOutputId, newRoyaltyBasisPoints);
    }

    /**
     * @dev A mechanism (intended to be called by marketplaces or manually by the seller)
     * to distribute royalties from an ArtisticOutputNFT sale to the creator and the AetherForge treasury.
     * @param artisticOutputId The ID of the ArtisticOutputNFT that was sold.
     * @param seller The address of the seller (who receives the net amount).
     * @param buyer The address of the buyer.
     * @param amount The total sale amount in ETH.
     */
    function distributeArtisticOutputRoyalties(uint256 artisticOutputId, address seller, address buyer, uint256 amount) public {
        // This function would typically be called by an NFT marketplace contract
        // or a specific escrow service that handles sales.
        // For this example, we simplify it as callable by anyone, but with checks.
        
        // In a real system: require(msg.sender == marketplaceAddress || hasRole(ROYALTY_DISTRIBUTOR_ROLE, msg.sender), "Unauthorized caller");

        ArtisticOutputNFT storage ao = artisticOutputNFTs[artisticOutputId];
        require(ao.tokenId != 0, "Artistic Output NFT does not exist");
        require(amount > 0, "Sale amount must be positive");

        uint256 creatorRoyalty = (amount * ao.royaltyBasisPoints) / 10000;
        uint256 protocolFee = (creatorRoyalty * config.royaltyFeeFraction) / 10000; // Platform takes a cut of creator's royalty
        uint256 netCreatorRoyalty = creatorRoyalty - protocolFee;

        // Distribute to creator
        (bool successCreator,) = ao.creator.call{value: netCreatorRoyalty}("");
        require(successCreator, "Failed to send creator royalty");

        // Distribute protocol fee to treasury
        (bool successProtocol,) = treasuryAddress.call{value: protocolFee}("");
        require(successProtocol, "Failed to send protocol fee");
        
        emit RoyaltiesDistributed(artisticOutputId, ao.creator, treasuryAddress, netCreatorRoyalty, protocolFee);
    }


    // --- IV. DAO & Influence System ---

    /**
     * @dev Awards Influence Points to a user for their contributions.
     * This can be called by the INFLUENCE_AWARDER_ROLE (admin, oracles, or automated systems).
     * @param user The address to award Influence Points to.
     * @param amount The amount of Influence Points to award.
     * @param reason A string describing why the points were awarded.
     */
    function earnInfluencePoints(address user, uint256 amount, string memory reason) public onlyRole(INFLUENCE_AWARDER_ROLE) {
        require(user != address(0), "Cannot award to zero address");
        require(amount > 0, "Amount must be greater than zero");
        influencePoints[user] += amount;
        emit InfluenceEarned(user, amount, reason);
    }

    /**
     * @dev Allows a user to delegate their Influence Points (voting power) to another address.
     * @param delegatee The address to delegate Influence to.
     */
    function delegateInfluence(address delegatee) public {
        require(delegatee != msg.sender, "Cannot delegate to self");
        influenceDelegates[msg.sender] = delegatee;
        emit InfluenceDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Internal function to get the effective influence of an address, considering delegation.
     * @param user The address to check influence for.
     * @return The effective influence points.
     */
    function getEffectiveInfluence(address user) internal view returns (uint256) {
        address delegatee = influenceDelegates[user];
        if (delegatee != address(0)) {
            return influencePoints[delegatee];
        }
        return influencePoints[user];
    }

    /**
     * @dev Allows users with sufficient Influence Points to submit a governance proposal.
     * @param description A detailed description of the proposal.
     * @param targetContract The address of the contract to call if the proposal passes.
     * @param callData The encoded function call (selector + arguments) for the targetContract.
     * @param justification An explanation for the proposal.
     */
    function submitProposal(string memory description, address targetContract, bytes memory callData, string memory justification) public {
        require(getEffectiveInfluence(msg.sender) >= config.proposalThreshold, "Not enough Influence Points to submit proposal");

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        Proposal storage newProposal = proposals[newId];
        newProposal.id = newId;
        newProposal.description = description;
        newProposal.targetContract = targetContract;
        newProposal.callData = callData;
        newProposal.justification = justification;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number + (config.proposalVotingPeriod / 12); // Assuming ~12s block time
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.proposer = msg.sender;
        newProposal.state = ProposalState.Active;

        emit ProposalSubmitted(newId, msg.sender, description, newProposal.startBlock, newProposal.endBlock);
    }

    /**
     * @dev Allows users to cast their vote on an active proposal using their Influence Points.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage p = proposals[proposalId];
        require(p.state == ProposalState.Active, "Proposal is not active");
        require(block.number <= p.endBlock, "Voting period has ended");
        require(!p.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterInfluence = getEffectiveInfluence(msg.sender);
        require(voterInfluence > 0, "No Influence Points to vote with");

        if (support) {
            p.votesFor += voterInfluence;
        } else {
            p.votesAgainst += voterInfluence;
        }
        p.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, voterInfluence, support);
    }

    /**
     * @dev Executes a passed proposal. Only callable after the voting period has ended
     * and the proposal has met the quorum and majority requirements.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage p = proposals[proposalId];
        require(p.state != ProposalState.Executed, "Proposal already executed");
        require(block.number > p.endBlock, "Voting period not ended yet");

        // Determine total Influence Points in existence for quorum calculation
        // For simplicity, we'll use a snapshot of total influence at the time of execution for now.
        // A more robust DAO would track circulating influence at proposal submission or end of voting.
        uint256 totalInfluence = 0;
        // This is a placeholder; a real system would need a way to get the total circulating influence
        // e.g., iterating through all addresses or using a token with snapshotting.
        // For now, let's assume `sumOfAllInfluencePoints()` function exists.
        // For example purposes, we assume a total supply of 'InfluenceToken' is used.
        // Here we simulate it by using a fixed value or getting the sum from a mapping of active users.
        // For now, let's simplify and make the quorum based on *voted* influence.

        // Update proposal state first
        if (p.votesFor > p.votesAgainst && (p.votesFor + p.votesAgainst) >= (getInfluencePointSupply() * config.voteQuorumFraction / 100)) { // Simplified quorum check
            p.state = ProposalState.Succeeded;
            emit ProposalStateChanged(proposalId, ProposalState.Succeeded);

            (bool success,) = p.targetContract.call(p.callData);
            require(success, "Proposal execution failed");
            p.state = ProposalState.Executed;
            emit ProposalExecuted(proposalId);
        } else {
            p.state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
        }
    }

    /**
     * @dev Helper to get a simplified total supply of influence points for quorum calculation.
     * In a real system, this would be more complex (e.g., snapshotting a token balance).
     */
    function getInfluencePointSupply() public view returns (uint256) {
        // Placeholder: In a production system, this would be either a token's totalSupply
        // or a dynamically calculated sum of active influence.
        // For demonstration, let's assume a max potential influence.
        return 1_000_000_000; // Example large number
    }

    // --- V. Creative Challenges & Curation ---

    /**
     * @dev Allows the CHALLENGE_MANAGER_ROLE or DAO to initiate a new creative challenge.
     * @param title The title of the challenge.
     * @param description A detailed description of the challenge theme/rules.
     * @param submissionDeadline The Unix timestamp when submissions close.
     * @param rewardPool The ETH reward for the challenge (optional, can be 0).
     */
    function startCreativeChallenge(string memory title, string memory description, uint256 submissionDeadline, uint256 rewardPool) public onlyRole(CHALLENGE_MANAGER_ROLE) {
        require(submissionDeadline > block.timestamp, "Submission deadline must be in the future");
        
        _challengeIds.increment();
        uint256 newId = _challengeIds.current();

        challenges[newId] = Challenge({
            id: newId,
            title: title,
            description: description,
            creator: msg.sender,
            startTimestamp: block.timestamp,
            submissionDeadline: submissionDeadline,
            votingDeadline: submissionDeadline + config.challengeDuration, // Voting starts after submission, runs for config.challengeDuration
            rewardPool: rewardPool,
            state: ChallengeState.Submitting
        });
        
        if (rewardPool > 0) {
            // Funds for the reward pool should be deposited here.
            // For simplicity, this function assumes the rewardPool is ETH from treasury or a prior deposit.
            // In reality, it would require msg.value or a transfer from treasury.
        }

        emit ChallengeStarted(newId, title, msg.sender, submissionDeadline, rewardPool);
    }

    /**
     * @dev Allows users to submit their ArtisticOutputNFTs as entries to an ongoing challenge.
     * @param challengeId The ID of the challenge.
     * @param artisticOutputId The ID of the ArtisticOutputNFT to submit.
     */
    function submitChallengeEntry(uint256 challengeId, uint256 artisticOutputId) public {
        Challenge storage c = challenges[challengeId];
        require(c.id != 0, "Challenge does not exist");
        require(c.state == ChallengeState.Submitting, "Challenge not in submission phase");
        require(block.timestamp <= c.submissionDeadline, "Submission deadline passed");
        
        ArtisticOutputNFT storage ao = artisticOutputNFTs[artisticOutputId];
        require(ao.tokenId != 0, "Artistic Output NFT does not exist");
        require(ao.creator == msg.sender, "Only owner can submit their Artistic Output NFT");
        require(!c.submittedEntries[artisticOutputId], "Artistic Output NFT already submitted to this challenge");

        c.submittedEntries[artisticOutputId] = true;
        challengeEntries[challengeId].push(artisticOutputId);

        emit ChallengeEntrySubmitted(challengeId, artisticOutputId, msg.sender);
    }

    /**
     * @dev Allows community members to vote/score challenge entries.
     * @param challengeId The ID of the challenge.
     * @param artisticOutputId The ID of the ArtisticOutputNFT entry to vote on.
     * @param score The score given to the entry (e.g., 1-10).
     */
    function voteOnChallengeEntry(uint256 challengeId, uint256 artisticOutputId, uint8 score) public {
        Challenge storage c = challenges[challengeId];
        require(c.id != 0, "Challenge does not exist");
        require(c.state == ChallengeState.Submitting || c.state == ChallengeState.Voting, "Challenge not in voting phase");
        require(block.timestamp > c.submissionDeadline && block.timestamp <= c.votingDeadline, "Voting not open or ended");
        require(c.submittedEntries[artisticOutputId], "Entry not submitted to this challenge");
        require(score > 0 && score <= 10, "Score must be between 1 and 10");
        require(c.entryScores[msg.sender][artisticOutputId] == 0, "Already voted on this entry");

        c.entryScores[msg.sender][artisticOutputId] = score;
        c.totalEntryScores[artisticOutputId] += score;
        c.totalVotersPerEntry[artisticOutputId]++;

        // Update challenge state if it's currently Submitting and voting has started
        if (c.state == ChallengeState.Submitting) {
            c.state = ChallengeState.Voting;
            emit ChallengeStateChanged(challengeId, ChallengeState.Voting);
        }

        emit ChallengeEntryVoted(challengeId, artisticOutputId, msg.sender, score);
    }

    /**
     * @dev Finalizes a creative challenge, determines winners, and distributes rewards.
     * Can only be called after the voting deadline.
     * @param challengeId The ID of the challenge to finalize.
     */
    function finalizeChallenge(uint256 challengeId) public onlyRole(CHALLENGE_MANAGER_ROLE) {
        Challenge storage c = challenges[challengeId];
        require(c.id != 0, "Challenge does not exist");
        require(c.state != ChallengeState.Finalized, "Challenge already finalized");
        require(block.timestamp > c.votingDeadline, "Voting period not ended yet");

        c.state = ChallengeState.Finalized;

        // Determine winner(s) - simple example, find max score
        uint256 highestScore = 0;
        uint256[] memory potentialWinners = challengeEntries[challengeId]; // Get all entries
        uint256[] storage actualWinners; // Store final winners

        for (uint256 i = 0; i < potentialWinners.length; i++) {
            uint256 entryId = potentialWinners[i];
            uint256 currentScore = c.totalEntryScores[entryId];

            if (currentScore > highestScore) {
                highestScore = currentScore;
                actualWinners = new uint256[](0); // Reset for new highest
                actualWinners.push(entryId);
            } else if (currentScore == highestScore && highestScore > 0) {
                actualWinners.push(entryId); // Add to winners if tied
            }
        }
        
        // Distribute rewards (example: split reward pool among winners)
        if (actualWinners.length > 0 && c.rewardPool > 0) {
            uint256 rewardPerWinner = c.rewardPool / actualWinners.length;
            for (uint256 i = 0; i < actualWinners.length; i++) {
                address winnerAddress = artisticOutputNFTs[actualWinners[i]].creator;
                (bool success,) = winnerAddress.call{value: rewardPerWinner}("");
                require(success, "Failed to send reward to winner");
                emit InfluenceEarned(winnerAddress, 100, "Won Creative Challenge"); // Also award Influence
            }
            // Clear reward pool
            c.rewardPool = 0;
        }

        emit ChallengeFinalized(challengeId, actualWinners);
        emit ChallengeStateChanged(challengeId, ChallengeState.Finalized);
    }


    // --- VI. AI Oracle Callbacks & Verification ---

    /**
     * @dev Generic callback function for the AI_ORACLE_ROLE to process results from off-chain AI computations.
     * This function routes the result to the appropriate internal logic based on the requestId.
     * @param requestId The unique ID of the original AI request.
     * @param success True if the AI computation was successful, false otherwise.
     * @param resultData A string containing the AI-generated metadata URI or other relevant data.
     * @param involvedTokenIds A list of token IDs involved in the request (e.g., new SynapseNFT, refined SynapseNFT, or ArtisticOutputNFT).
     */
    function receiveAIGenerationResult(bytes32 requestId, bool success, string memory resultData, uint256[] memory involvedTokenIds) public onlyRole(AI_ORACLE_ROLE) {
        AIRequest storage req = pendingAIRequests[requestId];
        require(req.requester != address(0), "Request ID not found or already processed");

        emit AIGenerationResultReceived(requestId, success, resultData);

        if (success) {
            if (req.requestType == RequestType.Fusion) {
                // For fusion, the AI might return metadata for a new SynapseNFT.
                // Assuming resultData is the metadataURI for a new fused Synapse.
                // Or AI returns multiple parts, which then need to be minted as new Synapses.
                // For simplicity, let's assume one new Synapse is created.
                uint256 newSynapseId = involvedTokenIds[0]; // Assuming oracle provides the new ID if one is created
                SynapseNFT storage newSynapse = synapseNFTs[newSynapseId];
                newSynapse.tokenId = newSynapseId;
                newSynapse.creator = req.requester;
                newSynapse.metadataURI = resultData;
                newSynapse.potentialScore = 10; // Initial score after fusion, AI can provide actual.
                _mint(req.requester, newSynapseId); // Mint the new fused SynapseNFT
                emit SynapseMinted(newSynapseId, req.requester, resultData);
                emit InfluenceEarned(req.requester, 5, "Successful Synapse Fusion");
            } else if (req.requestType == RequestType.Refinement) {
                // Update the metadata for the refined SynapseNFT.
                uint256 tokenId = req.involvedTokenIds[0];
                SynapseNFT storage s = synapseNFTs[tokenId];
                s.metadataURI = resultData;
                s.potentialScore += 5; // Example: refinement boosts potential
                emit SynapsePotentialUpdated(tokenId, s.potentialScore, resultData);
                emit InfluenceEarned(req.requester, 2, "Successful Synapse Refinement");
            } else if (req.requestType == RequestType.ArtisticOutput) {
                // Mint the ArtisticOutputNFT.
                mintArtisticOutputNFT(req.requester, resultData, req.artisticOutputIdTarget, req.royaltyBasisPoints);
                emit InfluenceEarned(req.requester, 10, "Successful Artistic Output Generation");
            }
        } else {
            // Handle failure: e.g., refund some cost, log error, possibly mint a "failed attempt" NFT.
            // For now, simply delete the request.
            // In a real system, the burnt SynapseNFTs might be returned or a compensation provided.
            emit InfluenceEarned(req.requester, 1, "Failed AI Request (Participation)"); // Even for failures, award some small influence.
        }

        delete pendingAIRequests[requestId]; // Clean up the request
    }
}
```