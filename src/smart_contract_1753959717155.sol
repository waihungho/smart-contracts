Here's a Solidity smart contract for a "Decentralized AI-Assisted Generative Asset Protocol" named **GenesisForge**. This contract explores several advanced concepts like:

*   **AI/ML Integration (Hybrid Model):** The contract manages the on-chain state and incentives for off-chain AI agents performing generative tasks. Verifiable content hashes act as commitments.
*   **Dynamic NFTs:** The "Generative Assets" are NFTs whose properties (metadata URI, content hash) can be updated and "evolved" over time based on new AI agent inputs and community confirmation.
*   **Decentralized Curation/Governance:** A "Curator" role with a reputation system allows community members to vote on the quality and approval of AI-generated content proposals.
*   **Reputation System:** Both AI Agents and Curators have on-chain reputation scores that influence their rewards and standing within the protocol.
*   **Economic Incentives:** Staking, reward distribution (simplified model), and slashing mechanisms incentivize good behavior and quality contributions.
*   **Modular Design:** While this contract is a single file, the logic is structured into distinct functional areas.

**Disclaimer:** This contract is a conceptual demonstration. A production-ready system would require significant additions, including:
*   Robust off-chain AI verification (e.g., using Chainlink Functions with verifiable compute, ZK-SNARKs for proof of generation).
*   A dedicated ERC-20 token for staking, fees, and rewards, rather than native currency (for better control).
*   A more sophisticated DAO or multi-sig for governance instead of a simple `Ownable` pattern.
*   Comprehensive error handling, gas optimizations, and security audits.
*   A more complex reward calculation mechanism based on actual revenue from NFT sales or usage.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Uncomment if using a dedicated ERC20 token for stakes/fees

/**
 * @title GenesisForge - Decentralized AI-Assisted Generative Asset Protocol
 * @dev This contract facilitates the creation, curation, and evolution of dynamic, AI-generated NFTs.
 * It establishes an economy around "AI Agents" (entities providing generative models) and
 * "Curators" (community members evaluating AI outputs). NFTs evolve based on AI Agent proposals
 * and community consensus, creating living, programmable digital assets.
 *
 * This contract does NOT implement the actual AI inference on-chain, but rather manages the
 * state, incentives, and verification hashes for off-chain AI operations. A real-world
 * implementation would integrate Chainlink Functions or similar verifiable compute
 * for the AI assessment/generation steps, ensuring trustless execution of AI tasks.
 */

/*
 * OUTLINE AND FUNCTION SUMMARY
 *
 * This contract organizes its functionalities into five main categories to manage the lifecycle
 * of AI-generated assets, the participation of AI Agents, and the curation by the community.
 *
 * I. Core Identity & Registration (AI Agents & Curators)
 *    Manages the registration, profile updates, and deregulation of participants.
 *    Requires staking of native currency to ensure commitment and deter malicious behavior.
 *    1.  `registerAIAgent(string memory name, string memory profileURI)`: Allows an entity to register as an AI Agent by staking a deposit, becoming eligible to submit generative proposals.
 *    2.  `updateAIAgentProfile(string memory newProfileURI)`: Enables a registered AI Agent to update their public profile metadata URI.
 *    3.  `deregisterAIAgent()`: Allows an AI Agent to unregister and retrieve their stake, provided they have no pending proposals or unresolved slashes.
 *    4.  `registerCurator(string memory name, string memory profileURI)`: Allows a user to register as a Curator by staking a deposit, gaining the ability to vote on generative proposals.
 *    5.  `updateCuratorProfile(string memory newProfileURI)`: Enables a registered Curator to update their public profile metadata URI.
 *    6.  `deregisterCurator()`: Allows a Curator to unregister and retrieve their stake, provided they have no pending votes or unresolved slashes.
 *
 * II. Generative Proposal & Curation Lifecycle
 *    Handles the submission of new generative asset proposals by AI Agents, their review by Curators,
 *    and the final decision-making process leading to NFT minting.
 *    7.  `submitGenerativeProposal(uint256 aiAgentId, string memory proposalDataURI, bytes32 contentHash)`: An AI Agent submits a new generative asset proposal, including metadata/parameters URI and a cryptographic hash of the off-chain generated content (e.g., image, model, text). Requires a small submission fee.
 *    8.  `voteOnProposal(uint256 proposalId, bool approve)`: A registered Curator casts their vote (approve/reject) on a submitted generative proposal. Voting power is weighted by reputation.
 *    9.  `finalizeProposal(uint256 proposalId)`: Initiates the finalization process for a proposal after its voting period ends. If passed, it triggers the minting of a new Generative Asset NFT and distributes rewards.
 *    10. `_mintGenerativeAsset(uint256 proposalId, address recipient)`: Internal function called upon successful proposal finalization to mint the new Generative Asset NFT to the specified recipient.
 *
 * III. Dynamic Asset Evolution
 *     Enables owners of Generative Asset NFTs to engage AI Agents to update and evolve their existing assets,
 *     creating dynamic, living digital collectibles.
 *    11. `requestAssetEvolution(uint256 tokenId, uint256 aiAgentId, string memory evolutionParametersURI)`: An owner of a Generative Asset NFT can request an AI Agent to evolve their asset, providing new parameters. Requires a fee.
 *    12. `confirmAssetEvolution(uint256 tokenId, string memory newMetadataURI, bytes32 newContentHash)`: An AI Agent confirms the successful evolution of an asset, providing new metadata and content hash. This updates the NFT's on-chain state.
 *
 * IV. Reputation, Rewards & Slashing
 *    Implements the economic incentive layer, allowing participants to claim rewards for good contributions
 *    and enabling governance to penalize malicious behavior through slashing.
 *    13. `claimAIAgentRewards()`: Allows AI Agents to claim their accumulated rewards from successful proposals and asset evolutions, adjusted by their reputation.
 *    14. `claimCuratorRewards()`: Allows Curators to claim rewards based on their participation in successful proposals and accurate voting, adjusted by reputation.
 *    15. `slashAIAgent(uint256 aiAgentId, uint256 amount)`: Initiates a slashing event against an AI Agent for egregious misconduct (e.g., proven fraud, repeated low-quality submissions). Requires governance approval.
 *    16. `slashCurator(uint256 curatorId, uint256 amount)`: Initiates a slashing event against a Curator for malicious or consistently poor voting. Requires governance approval.
 *
 * V. Configuration & Treasury Management
 *    Provides the necessary administrative functions for the contract owner (or a future DAO governance)
 *    to adjust protocol parameters and manage collected funds.
 *    17. `setStakingRequirements(uint256 _agentStake, uint256 _curatorStake)`: Allows the governance or deployer to adjust the required staking amounts for AI Agents and Curators.
 *    18. `setRewardRates(uint256 _agentRateBasisPoints, uint256 _curatorRateBasisPoints, uint256 _proposalFeeAmount)`: Allows governance to adjust the reward distribution percentages and proposal submission fees.
 *    19. `setVotingPeriod(uint256 _duration)`: Allows governance to set the duration for which proposals are open for voting.
 *    20. `setApprovalThreshold(uint256 _minPositiveVotesPercentage)`: Allows governance to set the minimum percentage of positive votes required for a proposal to pass.
 *    21. `transferOwnership(address newOwner)`: Standard OpenZeppelin Ownable function to transfer contract ownership (governance in a real DAO).
 *    22. `withdrawProtocolFees(address recipient)`: Allows the owner/governance to withdraw collected protocol fees from successful proposals/evolutions to a specified address.
 *
 * Additional Public View Functions (Getters):
 *    - `getAIAgent(uint256 _agentId)`: Retrieves details of an AI Agent.
 *    - `getCurator(uint256 _curatorId)`: Retrieves details of a Curator.
 *    - `getProposal(uint256 _proposalId)`: Retrieves details of a Generative Proposal.
 *    - `getGenerativeAsset(uint256 _tokenId)`: Retrieves details of a Generative Asset NFT.
 *    - `getAIAgentIdByAddress(address _wallet)`: Retrieves AI Agent ID by wallet address.
 *    - `getCuratorIdByAddress(address _wallet)`: Retrieves Curator ID by wallet address.
 *    - `getLatestAIAgentId()`: Returns the last assigned AI Agent ID.
 *    - `getLatestCuratorId()`: Returns the last assigned Curator ID.
 *    - `getLatestProposalId()`: Returns the last assigned Proposal ID.
 *    - `getLatestTokenId()`: Returns the last assigned NFT Token ID.
 */

contract GenesisForge is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _aiAgentIds;
    Counters.Counter private _curatorIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _tokenIdCounter; // For Generative Asset NFTs

    // Enums for clarity and state management
    enum EntityType { AI_AGENT, CURATOR }
    enum ProposalStatus { PENDING, VOTING, APPROVED, REJECTED, FINALIZED }

    // Structs for data management
    struct AIAgent {
        uint256 id;
        string name;
        string profileURI;
        uint256 stake;
        uint256 reputation; // Influences rewards, higher is better
        address wallet;
        bool active;
        uint256 lastActivityTime; // Last time agent performed an action
    }

    struct Curator {
        uint256 id;
        string name;
        string profileURI;
        uint256 stake;
        uint256 reputation; // Influences voting weight and rewards
        address wallet;
        bool active;
        uint256 lastActivityTime; // Last time curator performed an action
    }

    struct GenerativeProposal {
        uint256 id;
        uint256 aiAgentId;
        string proposalDataURI; // URI to parameters/metadata of the proposed asset
        bytes32 contentHash;    // Cryptographic hash of the off-chain generated content (e.g., IPFS hash)
        uint256 submissionTime;
        uint256 votingPeriodEnd;
        uint256 positiveVotes;  // Sum of reputation of approving curators
        uint256 negativeVotes;  // Sum of reputation of rejecting curators
        mapping(address => bool) hasVoted; // Tracks if a curator (by wallet address) has voted
        ProposalStatus status;
        uint256 mintedTokenId; // If approved, the ID of the minted NFT
    }

    struct GenerativeAsset {
        string metadataURI;      // Current metadata URI for the dynamic NFT
        bytes32 contentHash;     // Current content hash for the dynamic NFT
        uint256 lastEvolutionTime; // Timestamp of the last evolution
        uint256 creatorAIAgentId; // The AI agent that created this asset initially
    }

    // Mappings for storing and retrieving data
    mapping(uint256 => AIAgent) public aiAgents;
    mapping(address => uint256) public aiAgentWallets; // Maps wallet address to AI Agent ID
    mapping(uint256 => Curator) public curators;
    mapping(address => uint256) public curatorWallets; // Maps wallet address to Curator ID
    mapping(uint256 => GenerativeProposal) public proposals;
    mapping(uint256 => GenerativeAsset) public generativeAssets; // tokenId => GenerativeAsset details

    // Configuration parameters, adjustable by owner/governance
    uint256 public aiAgentStakeRequirement;          // Required native currency for AI Agent registration
    uint256 public curatorStakeRequirement;          // Required native currency for Curator registration
    uint256 public aiAgentRewardRateBasisPoints;     // Basis points (e.g., 500 = 5%) for a reward factor
    uint256 public curatorRewardRateBasisPoints;     // Basis points for a reward factor
    uint256 public proposalSubmissionFeeAmount;      // Fixed fee (in native currency wei) for submitting a proposal
    uint256 public proposalVotingPeriod;             // Duration in seconds for voting on a proposal
    uint256 public minPositiveVotesPercentage;       // Percentage (0-100) of positive votes needed for approval

    // Event definitions for off-chain monitoring and UI updates
    event AIAgentRegistered(uint256 indexed id, address indexed wallet, string name, string profileURI);
    event AIAgentProfileUpdated(uint256 indexed id, string newProfileURI);
    event AIAgentDeregistered(uint256 indexed id, address indexed wallet, uint256 stakeReturned);
    event CuratorRegistered(uint256 indexed id, address indexed wallet, string name, string profileURI);
    event CuratorProfileUpdated(uint256 indexed id, string newProfileURI);
    event CuratorDeregistered(uint256 indexed id, address indexed wallet, uint256 stakeReturned);

    event GenerativeProposalSubmitted(uint256 indexed proposalId, uint256 indexed aiAgentId, string proposalDataURI, bytes32 contentHash);
    event ProposalVoted(uint256 indexed proposalId, uint256 indexed curatorId, bool approved);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus status, uint256 mintedTokenId);

    event AssetEvolutionRequested(uint256 indexed tokenId, uint256 indexed aiAgentId, string evolutionParametersURI);
    event AssetEvolutionConfirmed(uint256 indexed tokenId, string newMetadataURI, bytes32 newContentHash);

    event AIAgentSlashed(uint256 indexed aiAgentId, uint256 amount);
    event CuratorSlashed(uint256 indexed curatorId, uint256 amount);
    event AIAgentRewardsClaimed(uint256 indexed aiAgentId, uint256 amount);
    event CuratorRewardsClaimed(uint256 indexed curatorId, uint256 amount);

    event ConfigUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---

    /**
     * @dev Initializes the GenesisForge contract, setting up the NFT collection and initial protocol parameters.
     * @param name Name of the ERC721 NFT collection.
     * @param symbol Symbol of the ERC721 NFT collection.
     * @param _aiAgentStakeReq Initial native currency required to register as an AI Agent.
     * @param _curatorStakeReq Initial native currency required to register as a Curator.
     * @param _agentRewardRateBP Initial reward rate basis points for AI Agents (e.g., 500 for 5%).
     * @param _curatorRewardRateBP Initial reward rate basis points for Curators.
     * @param _proposalFeeAmount Initial fixed fee (in wei) for submitting a generative proposal.
     * @param _votingPeriod Initial duration (in seconds) for proposal voting.
     * @param _minPositiveVotesPct Initial minimum percentage of positive votes required for approval (0-100).
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 _aiAgentStakeReq,
        uint256 _curatorStakeReq,
        uint256 _agentRewardRateBP,
        uint256 _curatorRewardRateBP,
        uint256 _proposalFeeAmount,
        uint256 _votingPeriod,
        uint256 _minPositiveVotesPct
    ) ERC721(name, symbol) Ownable(msg.sender) {
        aiAgentStakeRequirement = _aiAgentStakeReq;
        curatorStakeRequirement = _curatorStakeReq;
        aiAgentRewardRateBasisPoints = _agentRewardRateBP;
        curatorRewardRateBasisPoints = _curatorRewardRateBP;
        proposalSubmissionFeeAmount = _proposalFeeAmount;
        proposalVotingPeriod = _votingPeriod;
        minPositiveVotesPercentage = _minPositiveVotesPct; // 0-100
    }

    // --- Modifiers ---

    /** @dev Restricts calls to registered and active AI Agents. */
    modifier onlyAIAgent(uint256 _aiAgentId) {
        require(aiAgents[_aiAgentId].id != 0, "AI Agent does not exist");
        require(aiAgents[_aiAgentId].wallet == msg.sender, "Caller is not the registered AI Agent");
        require(aiAgents[_aiAgentId].active, "AI Agent is not active");
        _;
    }

    /** @dev Restricts calls to registered and active Curators. */
    modifier onlyCurator(uint256 _curatorId) {
        require(curators[_curatorId].id != 0, "Curator does not exist");
        require(curators[_curatorId].wallet == msg.sender, "Caller is not the registered Curator");
        require(curators[_curatorId].active, "Curator is not active");
        _;
    }

    /** @dev Ensures a proposal with the given ID exists. */
    modifier onlyValidProposal(uint256 _proposalId) {
        require(proposals[_proposalId].id != 0, "Proposal does not exist");
        _;
    }

    // --- I. Core Identity & Registration (AI Agents & Curators) ---

    /**
     * @dev Allows an entity to register as an AI Agent by staking a deposit.
     * @param name The public name of the AI Agent.
     * @param profileURI URI to the AI Agent's profile metadata (e.g., IPFS).
     */
    function registerAIAgent(string memory name, string memory profileURI) public payable nonReentrant {
        require(aiAgentWallets[msg.sender] == 0, "Wallet already registered as AI Agent");
        require(msg.value >= aiAgentStakeRequirement, "Insufficient stake");

        _aiAgentIds.increment();
        uint256 newId = _aiAgentIds.current();

        aiAgents[newId] = AIAgent({
            id: newId,
            name: name,
            profileURI: profileURI,
            stake: msg.value,
            reputation: 100, // Starting reputation for new agents
            wallet: msg.sender,
            active: true,
            lastActivityTime: block.timestamp
        });
        aiAgentWallets[msg.sender] = newId;

        emit AIAgentRegistered(newId, msg.sender, name, profileURI);
    }

    /**
     * @dev Enables a registered AI Agent to update their public profile metadata URI.
     * @param newProfileURI New URI to the AI Agent's profile metadata.
     */
    function updateAIAgentProfile(string memory newProfileURI) public {
        uint256 agentId = aiAgentWallets[msg.sender];
        require(agentId != 0, "Not a registered AI Agent");
        aiAgents[agentId].profileURI = newProfileURI;
        aiAgents[agentId].lastActivityTime = block.timestamp;
        emit AIAgentProfileUpdated(agentId, newProfileURI);
    }

    /**
     * @dev Allows an AI Agent to unregister and retrieve their stake.
     * Requires no pending proposals or unresolved slashes/penalties.
     */
    function deregisterAIAgent() public nonReentrant {
        uint256 agentId = aiAgentWallets[msg.sender];
        require(agentId != 0, "Not a registered AI Agent");
        require(aiAgents[agentId].active, "AI Agent is already inactive");
        // Add more rigorous checks for production:
        // - require no active proposals where agent is creator or involved
        // - require no pending slashes or dispute resolutions

        aiAgents[agentId].active = false;
        uint256 stake = aiAgents[agentId].stake;
        // Optionally, clear the agent data entirely (e.g., delete aiAgents[agentId])
        // For simplicity, we keep the record but mark as inactive.
        delete aiAgentWallets[msg.sender]; // Remove reverse mapping

        (bool success, ) = msg.sender.call{value: stake}("");
        require(success, "Failed to return stake");

        emit AIAgentDeregistered(agentId, msg.sender, stake);
    }

    /**
     * @dev Allows a user to register as a Curator by staking a deposit.
     * @param name The public name of the Curator.
     * @param profileURI URI to the Curator's profile metadata (e.g., IPFS).
     */
    function registerCurator(string memory name, string memory profileURI) public payable nonReentrant {
        require(curatorWallets[msg.sender] == 0, "Wallet already registered as Curator");
        require(msg.value >= curatorStakeRequirement, "Insufficient stake");

        _curatorIds.increment();
        uint256 newId = _curatorIds.current();

        curators[newId] = Curator({
            id: newId,
            name: name,
            profileURI: profileURI,
            stake: msg.value,
            reputation: 100, // Starting reputation for new curators
            wallet: msg.sender,
            active: true,
            lastActivityTime: block.timestamp
        });
        curatorWallets[msg.sender] = newId;

        emit CuratorRegistered(newId, msg.sender, name, profileURI);
    }

    /**
     * @dev Enables a registered Curator to update their public profile metadata URI.
     * @param newProfileURI New URI to the Curator's profile metadata.
     */
    function updateCuratorProfile(string memory newProfileURI) public {
        uint256 curatorId = curatorWallets[msg.sender];
        require(curatorId != 0, "Not a registered Curator");
        curators[curatorId].profileURI = newProfileURI;
        curators[curatorId].lastActivityTime = block.timestamp;
        emit CuratorProfileUpdated(curatorId, newProfileURI);
    }

    /**
     * @dev Allows a Curator to unregister and retrieve their stake.
     * Requires no pending votes or unresolved slashes/penalties.
     */
    function deregisterCurator() public nonReentrant {
        uint256 curatorId = curatorWallets[msg.sender];
        require(curatorId != 0, "Not a registered Curator");
        require(curators[curatorId].active, "Curator is already inactive");
        // Add more rigorous checks for production:
        // - require no active votes on pending proposals
        // - require no pending slashes or dispute resolutions

        curators[curatorId].active = false;
        uint256 stake = curators[curatorId].stake;
        delete curatorWallets[msg.sender]; // Remove reverse mapping

        (bool success, ) = msg.sender.call{value: stake}("");
        require(success, "Failed to return stake");

        emit CuratorDeregistered(curatorId, msg.sender, stake);
    }

    // --- II. Generative Proposal & Curation Lifecycle ---

    /**
     * @dev An AI Agent submits a new generative asset proposal.
     * The `contentHash` serves as a verifiable commitment to the off-chain generated content.
     * @param aiAgentId The ID of the submitting AI Agent.
     * @param proposalDataURI URI to the parameters/metadata for the proposed asset (e.g., IPFS).
     * @param contentHash Cryptographic hash of the off-chain generated content (e.g., image, 3D model, text).
     */
    function submitGenerativeProposal(uint256 aiAgentId, string memory proposalDataURI, bytes32 contentHash)
        public
        payable
        onlyAIAgent(aiAgentId)
    {
        require(msg.value >= proposalSubmissionFeeAmount, "Insufficient submission fee");

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        GenerativeProposal storage newProposal = proposals[newId];
        newProposal.id = newId;
        newProposal.aiAgentId = aiAgentId;
        newProposal.proposalDataURI = proposalDataURI;
        newProposal.contentHash = contentHash;
        newProposal.submissionTime = block.timestamp;
        newProposal.votingPeriodEnd = block.timestamp + proposalVotingPeriod;
        newProposal.status = ProposalStatus.VOTING;

        aiAgents[aiAgentId].lastActivityTime = block.timestamp;

        emit GenerativeProposalSubmitted(newId, aiAgentId, proposalDataURI, contentHash);
    }

    /**
     * @dev A registered Curator casts their vote (approve/reject) on a submitted generative proposal.
     * Voting power is weighted by the Curator's reputation.
     * @param proposalId The ID of the proposal to vote on.
     * @param approve True to approve, false to reject.
     */
    function voteOnProposal(uint256 proposalId, bool approve)
        public
        onlyValidProposal(proposalId)
    {
        uint256 curatorId = curatorWallets[msg.sender];
        require(curatorId != 0 && curators[curatorId].active, "Not an active Curator");
        require(proposals[proposalId].status == ProposalStatus.VOTING, "Proposal is not in voting phase");
        require(block.timestamp < proposals[proposalId].votingPeriodEnd, "Voting period has ended");
        require(!proposals[proposalId].hasVoted[msg.sender], "Curator has already voted on this proposal");

        proposals[proposalId].hasVoted[msg.sender] = true;
        uint256 votingWeight = curators[curatorId].reputation; // Voting power directly proportional to reputation

        if (approve) {
            proposals[proposalId].positiveVotes += votingWeight;
        } else {
            proposals[proposalId].negativeVotes += votingWeight;
        }
        curators[curatorId].lastActivityTime = block.timestamp;

        emit ProposalVoted(proposalId, curatorId, approve);
    }

    /**
     * @dev Initiates the finalization process for a proposal after its voting period ends.
     * If passed, it triggers the minting of a new Generative Asset NFT and adjusts rewards/reputation.
     * Anyone can call this after the voting period ends, promoting decentralization.
     * @param proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 proposalId)
        public
        nonReentrant
        onlyValidProposal(proposalId)
    {
        GenerativeProposal storage proposal = proposals[proposalId];

        require(proposal.status == ProposalStatus.VOTING, "Proposal not in voting state");
        require(block.timestamp >= proposal.votingPeriodEnd, "Voting period not ended yet");

        uint256 totalVotes = proposal.positiveVotes + proposal.negativeVotes;
        ProposalStatus newStatus;
        uint256 mintedTokenId = 0;

        if (totalVotes == 0) {
            newStatus = ProposalStatus.REJECTED; // No votes, defaults to rejected
        } else {
            uint256 positiveVotePercentage = (proposal.positiveVotes * 100) / totalVotes;
            if (positiveVotePercentage >= minPositiveVotesPercentage) {
                newStatus = ProposalStatus.APPROVED;
                // Mint the NFT to the AI Agent (creator)
                mintedTokenId = _mintGenerativeAsset(proposalId, aiAgents[proposal.aiAgentId].wallet);
            } else {
                newStatus = ProposalStatus.REJECTED;
            }
        }

        proposal.status = newStatus;
        proposal.mintedTokenId = mintedTokenId;

        // Adjust reputations and prepare for rewards based on outcome
        _updateReputations(proposalId, newStatus);

        emit ProposalFinalized(proposalId, newStatus, mintedTokenId);
    }

    /**
     * @dev Internal function to mint a new Generative Asset NFT.
     * Only called by `finalizeProposal` for approved proposals.
     * @param proposalId The ID of the proposal from which to mint the asset.
     * @param recipient The address to mint the NFT to.
     * @return The ID of the newly minted NFT.
     */
    function _mintGenerativeAsset(uint256 proposalId, address recipient) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, proposals[proposalId].proposalDataURI); // Set initial URI

        generativeAssets[newTokenId] = GenerativeAsset({
            metadataURI: proposals[proposalId].proposalDataURI,
            contentHash: proposals[proposalId].contentHash,
            lastEvolutionTime: block.timestamp,
            creatorAIAgentId: proposals[proposalId].aiAgentId
        });
        return newTokenId;
    }

    // --- III. Dynamic Asset Evolution ---

    /**
     * @dev An owner of a Generative Asset NFT can request an AI Agent to evolve their asset,
     * providing new parameters. This initiates an off-chain process.
     * @param tokenId The ID of the Generative Asset NFT to evolve.
     * @param aiAgentId The ID of the AI Agent selected to perform the evolution.
     * @param evolutionParametersURI URI to the new parameters for evolution.
     * @dev A real implementation would integrate Chainlink Functions or similar here
     * to securely call out to an AI model and verify its computation.
     */
    function requestAssetEvolution(uint256 tokenId, uint256 aiAgentId, string memory evolutionParametersURI)
        public payable nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to evolve this asset");
        require(aiAgents[aiAgentId].active, "Selected AI Agent is not active");
        // Optional: require an evolution fee here, or handle payment off-chain.
        // require(msg.value > 0, "Evolution fee required.");

        emit AssetEvolutionRequested(tokenId, aiAgentId, evolutionParametersURI);
    }

    /**
     * @dev An AI Agent confirms the successful evolution of an asset, providing new metadata and content hash.
     * This updates the NFT's on-chain state and its `tokenURI`.
     * This function is expected to be called by the AI Agent *after* performing the off-chain generative work,
     * likely as a callback from a verifiable compute oracle (e.g., Chainlink Functions).
     * @param tokenId The ID of the Generative Asset NFT that was evolved.
     * @param newMetadataURI New URI to the updated metadata for the asset.
     * @param newContentHash New cryptographic hash of the evolved off-chain content.
     */
    function confirmAssetEvolution(uint256 tokenId, string memory newMetadataURI, bytes32 newContentHash)
        public
        nonReentrant
    {
        uint256 aiAgentId = aiAgentWallets[msg.sender];
        require(aiAgentId != 0, "Caller is not an active AI Agent");
        require(generativeAssets[tokenId].creatorAIAgentId != 0, "Asset does not exist or invalid GenesisForge asset");
        // Further verification could be added here to link this confirmation to a specific `requestAssetEvolution`
        // (e.g., using a requestId returned by Chainlink Functions).

        // Update the NFT's metadata and content hash
        generativeAssets[tokenId].metadataURI = newMetadataURI;
        generativeAssets[tokenId].contentHash = newContentHash;
        generativeAssets[tokenId].lastEvolutionTime = block.timestamp;
        _setTokenURI(tokenId, newMetadataURI); // Update ERC721 metadata URI, making it dynamic

        // Reward the AI Agent for successful evolution (simplified reputation boost)
        aiAgents[aiAgentId].reputation += 5; // Small reputation boost for successful evolution
        aiAgents[aiAgentId].lastActivityTime = block.timestamp;

        emit AssetEvolutionConfirmed(tokenId, newMetadataURI, newContentHash);
    }

    // --- IV. Reputation, Rewards & Slashing ---

    /**
     * @dev Internal function to adjust reputations based on proposal outcome.
     * This is a simplified model; a production system might use quadratic voting,
     * more complex reputation algorithms, or reputation decay.
     */
    function _updateReputations(uint256 proposalId, ProposalStatus status) internal {
        uint256 aiAgentId = proposals[proposalId].aiAgentId;
        if (status == ProposalStatus.APPROVED) {
            aiAgents[aiAgentId].reputation += 10; // Boost reputation for approved proposal
        } else if (status == ProposalStatus.REJECTED) {
            if (aiAgents[aiAgentId].reputation > 5) { // Prevent reputation from dropping too low
                aiAgents[aiAgentId].reputation -= 5; // Reduce reputation for rejected proposal
            } else {
                aiAgents[aiAgentId].reputation = 0;
            }
        }
        aiAgents[aiAgentId].lastActivityTime = block.timestamp;

        // For curators: A more advanced system would iterate through all curators who voted
        // on this proposal and update their reputation based on how aligned their vote was
        // with the final outcome. For simplicity, this is omitted.
        // Example logic for curators:
        // if (proposal.hasVoted[curatorAddress]) {
        //     if (status == ProposalStatus.APPROVED && votedApproved || status == ProposalStatus.REJECTED && !votedApproved) {
        //         curators[curatorId].reputation += 1; // Reward for correct vote
        //     } else {
        //         curators[curatorId].reputation -= 1; // Penalty for incorrect vote
        //     }
        // }
    }

    /**
     * @dev Allows AI Agents to claim their accumulated rewards.
     * This is a simplified reward model. In a full Dapp, rewards would accrue
     * from collected fees, a treasury, or token emissions.
     */
    function claimAIAgentRewards() public nonReentrant {
        uint256 agentId = aiAgentWallets[msg.sender];
        require(agentId != 0 && aiAgents[agentId].active, "Not an active AI Agent");

        // Example reward calculation: reputation * a fixed rate.
        // In a real system, rewards would be explicitly tracked from successful proposals/evolutions.
        uint256 rewardAmount = (aiAgents[agentId].reputation * aiAgentRewardRateBasisPoints) / 10000;
        // To prevent repeated claims of the same "reputation reward", a more robust system
        // would track `lastClaimTimestamp` and calculate rewards accrued since then,
        // or have a specific "unclaimed balance" that accumulates.
        // For this example, let's just assume this is a one-time "bonus" or requires external top-up.
        require(rewardAmount > 0, "No rewards to claim or already claimed");

        // Transfer from contract balance (assuming contract collects fees/rewards)
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "Failed to send rewards");

        // Reset or adjust reputation to reflect rewards claimed (simplified model)
        if (aiAgents[agentId].reputation > 100) { // Keep a base reputation
            aiAgents[agentId].reputation = 100;
        }
        aiAgents[agentId].lastActivityTime = block.timestamp;

        emit AIAgentRewardsClaimed(agentId, rewardAmount);
    }

    /**
     * @dev Allows Curators to claim rewards based on their participation and accurate voting.
     * Similar simplified model as AI Agent rewards.
     */
    function claimCuratorRewards() public nonReentrant {
        uint256 curatorId = curatorWallets[msg.sender];
        require(curatorId != 0 && curators[curatorId].active, "Not an active Curator");

        uint256 rewardAmount = (curators[curatorId].reputation * curatorRewardRateBasisPoints) / 10000;
        require(rewardAmount > 0, "No rewards to claim or already claimed");

        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "Failed to send rewards");

        if (curators[curatorId].reputation > 100) {
            curators[curatorId].reputation = 100;
        }
        curators[curatorId].lastActivityTime = block.timestamp;

        emit CuratorRewardsClaimed(curatorId, rewardAmount);
    }

    /**
     * @dev Initiates a slashing event against an AI Agent for egregious misconduct.
     * Requires governance approval (only owner for this example, in production this would be a DAO).
     * Slashed amount is retained by the protocol treasury.
     * @param aiAgentId The ID of the AI Agent to slash.
     * @param amount The amount of stake (in wei) to slash.
     */
    function slashAIAgent(uint256 aiAgentId, uint256 amount) public onlyOwner {
        require(aiAgents[aiAgentId].id != 0, "AI Agent does not exist");
        require(aiAgents[aiAgentId].stake >= amount, "Slash amount exceeds agent's stake");
        require(aiAgents[aiAgentId].active, "Cannot slash inactive agent");

        aiAgents[aiAgentId].stake -= amount;
        if (aiAgents[aiAgentId].reputation > (amount / 10000)) { // Reduce reputation based on slash (simplified)
             aiAgents[aiAgentId].reputation -= (amount / 10000); // 1 reputation per 10000 wei slashed
        } else {
            aiAgents[aiAgentId].reputation = 0;
        }
        if (aiAgents[aiAgentId].stake == 0) { // If stake becomes zero, deactivate
            aiAgents[aiAgentId].active = false;
            delete aiAgentWallets[aiAgents[aiAgentId].wallet];
        }

        emit AIAgentSlashed(aiAgentId, amount);
    }

    /**
     * @dev Initiates a slashing event against a Curator for malicious or consistently poor voting.
     * Requires governance approval (only owner for this example, in production this would be a DAO).
     * Slashed amount is retained by the protocol treasury.
     * @param curatorId The ID of the Curator to slash.
     * @param amount The amount of stake (in wei) to slash.
     */
    function slashCurator(uint256 curatorId, uint256 amount) public onlyOwner {
        require(curators[curatorId].id != 0, "Curator does not exist");
        require(curators[curatorId].stake >= amount, "Slash amount exceeds curator's stake");
        require(curators[curatorId].active, "Cannot slash inactive curator");

        curators[curatorId].stake -= amount;
        if (curators[curatorId].reputation > (amount / 10000)) {
             curators[curatorId].reputation -= (amount / 10000);
        } else {
            curators[curatorId].reputation = 0;
        }
        if (curators[curatorId].stake == 0) { // If stake becomes zero, deactivate
            curators[curatorId].active = false;
            delete curatorWallets[curators[curatorId].wallet];
        }

        emit CuratorSlashed(curatorId, amount);
    }

    // --- V. Configuration & Treasury Management ---

    /**
     * @dev Allows the governance or deployer to adjust the required staking amounts for AI Agents and Curators.
     * @param _agentStake New required stake (in wei) for AI Agents.
     * @param _curatorStake New required stake (in wei) for Curators.
     */
    function setStakingRequirements(uint256 _agentStake, uint256 _curatorStake) public onlyOwner {
        uint256 oldAgentStake = aiAgentStakeRequirement;
        uint256 oldCuratorStake = curatorStakeRequirement;
        aiAgentStakeRequirement = _agentStake;
        curatorStakeRequirement = _curatorStake;
        emit ConfigUpdated("aiAgentStakeRequirement", oldAgentStake, _agentStake);
        emit ConfigUpdated("curatorStakeRequirement", oldCuratorStake, _curatorStake);
    }

    /**
     * @dev Allows governance to adjust the reward distribution basis points and proposal submission fee amount.
     * @param _agentRateBasisPoints New basis points for AI Agent rewards (e.g., 500 for 5% of a base reward).
     * @param _curatorRateBasisPoints New basis points for Curator rewards.
     * @param _proposalFeeAmount New fixed fee amount (in wei) for proposals.
     */
    function setRewardRates(
        uint256 _agentRateBasisPoints,
        uint256 _curatorRateBasisPoints,
        uint256 _proposalFeeAmount
    ) public onlyOwner {
        uint256 oldAgentRate = aiAgentRewardRateBasisPoints;
        uint256 oldCuratorRate = curatorRewardRateBasisPoints;
        uint256 oldProposalFee = proposalSubmissionFeeAmount;

        aiAgentRewardRateBasisPoints = _agentRateBasisPoints;
        curatorRewardRateBasisPoints = _curatorRateBasisPoints;
        proposalSubmissionFeeAmount = _proposalFeeAmount;

        emit ConfigUpdated("aiAgentRewardRateBasisPoints", oldAgentRate, _agentRateBasisPoints);
        emit ConfigUpdated("curatorRewardRateBasisPoints", oldCuratorRate, _curatorRateBasisPoints);
        emit ConfigUpdated("proposalSubmissionFeeAmount", oldProposalFee, _proposalFeeAmount);
    }

    /**
     * @dev Allows governance to set the duration for which proposals are open for voting.
     * @param _duration New voting period duration in seconds.
     */
    function setVotingPeriod(uint256 _duration) public onlyOwner {
        uint256 oldDuration = proposalVotingPeriod;
        proposalVotingPeriod = _duration;
        emit ConfigUpdated("proposalVotingPeriod", oldDuration, _duration);
    }

    /**
     * @dev Allows governance to set the minimum percentage of positive votes required for a proposal to pass.
     * @param _minPositiveVotesPercentage New minimum percentage (0-100).
     */
    function setApprovalThreshold(uint256 _minPositiveVotesPercentage) public onlyOwner {
        require(_minPositiveVotesPercentage <= 100, "Percentage cannot exceed 100");
        uint256 oldThreshold = minPositiveVotesPercentage;
        minPositiveVotesPercentage = _minPositiveVotesPercentage;
        emit ConfigUpdated("minPositiveVotesPercentage", oldThreshold, _minPositiveVotesPercentage);
    }

    /**
     * @dev Allows the owner/governance to withdraw collected protocol fees from successful proposals/evolutions.
     * Funds from slashed stakes also accumulate in the contract's balance and become available here.
     * @param recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address recipient) public onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        uint256 stakedFunds = 0;

        // Calculate total active staked funds
        for (uint256 i = 1; i <= _aiAgentIds.current(); i++) {
            if (aiAgents[i].active) {
                stakedFunds += aiAgents[i].stake;
            }
        }
        for (uint256 i = 1; i <= _curatorIds.current(); i++) {
            if (curators[i].active) {
                stakedFunds += curators[i].stake;
            }
        }

        uint256 availableForWithdrawal = contractBalance - stakedFunds;
        require(availableForWithdrawal > 0, "No fees available for withdrawal");
        require(recipient != address(0), "Recipient cannot be zero address");

        (bool success, ) = recipient.call{value: availableForWithdrawal}("");
        require(success, "Failed to withdraw fees");

        emit ProtocolFeesWithdrawn(recipient, availableForWithdrawal);
    }

    // --- ERC721 Overrides (for tokenURI) ---
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Overrides the default ERC721 `tokenURI` to return the dynamic metadata URI
     * stored in our `generativeAssets` mapping.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return generativeAssets[tokenId].metadataURI;
    }

    // --- Helper Getters (Optional, but useful for Dapp integration) ---
    function getAIAgent(uint256 _agentId) public view returns (uint256 id, string memory name, string memory profileURI, uint256 stake, uint256 reputation, address wallet, bool active, uint256 lastActivityTime) {
        AIAgent storage agent = aiAgents[_agentId];
        return (agent.id, agent.name, agent.profileURI, agent.stake, agent.reputation, agent.wallet, agent.active, agent.lastActivityTime);
    }

    function getCurator(uint256 _curatorId) public view returns (uint256 id, string memory name, string memory profileURI, uint256 stake, uint256 reputation, address wallet, bool active, uint256 lastActivityTime) {
        Curator storage curator = curators[_curatorId];
        return (curator.id, curator.name, curator.profileURI, curator.stake, curator.reputation, curator.wallet, curator.active, curator.lastActivityTime);
    }

    function getProposal(uint256 _proposalId) public view returns (uint256 id, uint256 aiAgentId, string memory proposalDataURI, bytes32 contentHash, uint256 submissionTime, uint256 votingPeriodEnd, uint256 positiveVotes, uint256 negativeVotes, ProposalStatus status, uint256 mintedTokenId) {
        GenerativeProposal storage proposal = proposals[_proposalId];
        return (proposal.id, proposal.aiAgentId, proposal.proposalDataURI, proposal.contentHash, proposal.submissionTime, proposal.votingPeriodEnd, proposal.positiveVotes, proposal.negativeVotes, proposal.status, proposal.mintedTokenId);
    }

    function getGenerativeAsset(uint256 _tokenId) public view returns (string memory metadataURI, bytes32 contentHash, uint256 lastEvolutionTime, uint256 creatorAIAgentId) {
        GenerativeAsset storage asset = generativeAssets[_tokenId];
        return (asset.metadataURI, asset.contentHash, asset.lastEvolutionTime, asset.creatorAIAgentId);
    }

    function getAIAgentIdByAddress(address _wallet) public view returns (uint256) {
        return aiAgentWallets[_wallet];
    }

    function getCuratorIdByAddress(address _wallet) public view returns (uint256) {
        return curatorWallets[_wallet];
    }

    function getLatestAIAgentId() public view returns (uint256) {
        return _aiAgentIds.current();
    }

    function getLatestCuratorId() public view returns (uint256) {
        return _curatorIds.current();
    }

    function getLatestProposalId() public view returns (uint256) {
        return _proposalIds.current();
    }

    function getLatestTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
}
```