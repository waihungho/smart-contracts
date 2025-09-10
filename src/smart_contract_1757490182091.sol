This smart contract, named `AetherForge`, introduces a novel decentralized autonomous organization (DAO) for collaborative, AI-assisted creative endeavors. It combines several advanced and trending concepts: dynamic, non-transferable reputation tokens (Soulbound-like), AI oracle integration for content generation/verification, and a DAO-governed system for curating AI-generated NFTs and managing communal resources.

---

### Contract: `AetherForge`

**Description:** `AetherForge` is a decentralized autonomous organization (DAO) designed to foster collaborative, AI-assisted creative endeavors. It enables participants to submit creative prompts, facilitates the generation and curation of AI outputs (represented as unique NFTs), and manages a community treasury to fund AI model access and reward contributors. Reputation, embodied by non-transferable `AetherShards`, dictates voting power and influence within the collective.

---

### Outline and Function Summary

**I. Core Management & Access Control**
1.  **`constructor`**: Initializes the contract with an owner, oracle address, and sets initial parameters.
2.  **`setOracleAddress(address _newOracleAddress)`**: Sets or updates the address of the trusted AI Oracle for external data.
3.  **`pauseContract()`**: Allows the owner or governor to pause critical contract functions in emergencies.
4.  **`unpauseContract()`**: Allows the owner or governor to unpause the contract after an emergency.
5.  **`setAetherShardsContract(address _shardsContract)`**: Links the `AetherForge` to the `AetherShards` (reputation token) contract.
6.  **`setAetherGemsContract(address _gemsContract)`**: Links the `AetherForge` to the `AetherGems` (NFT for AI works) contract.
7.  **`proposeNewGovernor(address _newGovernorCandidate)`**: Initiates a DAO vote to transfer the governor role to a new address, requiring `MIN_SHARDS_FOR_PROPOSAL`.

**II. AetherShards (Reputation System)**
*(These functions interact with the `IAetherShards` external contract interface)*
8.  **`registerParticipant()`**: Allows a new user to join the collective and receive an initial allocation of `AetherShards`.
9.  **`awardShards(address _recipient, uint256 _amount)`**: Admin/DAO awards `AetherShards` to a participant for meritorious contributions.
10. **`deductShards(address _recipient, uint256 _amount)`**: Admin/DAO deducts `AetherShards` from a participant for infractions or failed proposals.
11. **`getShardsBalance(address _participant)`**: Returns the current `AetherShards` balance (reputation score) of a participant.

**III. Creative Process: Prompts & AI Outputs**
12. **`submitPromptIdea(string memory _promptText)`**: A participant submits a textual prompt concept for AI generation and optionally attaches an ETH bounty.
13. **`submitAIOutputClaim(uint256 _promptId, string memory _aiModelUsed, bytes32 _outputHash, string memory _metadataURI)`**: A prompt engineer submits the hash of an AI-generated output, linking it to a `PromptIdea` and potentially claiming its associated bounty. Requires `MIN_SHARDS_FOR_PROPOSAL`.
14. **`voteOnAIOutputClaim(uint256 _claimId, bool _support)`**: Participants vote on the validity and quality of a submitted `AIOutputClaim`, weighted by their `AetherShards`.
15. **`executeAIOutputClaimApproval(uint256 _claimId)`**: Executes the outcome of a passed `AIOutputClaim` vote, minting an `AetherGem` NFT, distributing ETH bounty, and rewarding `AetherShards`.

**IV. AetherGems (NFTs for Curated AI Works)**
*(These functions interact with the `IAetherGems` external contract interface)*
16. **`getAetherGemMetadataURI(uint256 _tokenId)`**: Retrieves the URI for the metadata of a specific `AetherGem` NFT. (Assumes getter on `IAetherGems`).
17. **`getAetherGemOwner(uint256 _tokenId)`**: Returns the current owner of a given `AetherGem` NFT. (Assumes getter on `IAetherGems`).

**V. Treasury & Resource Allocation (DAO Governance)**
18. **`depositFunds(address _token, uint256 _amount)`**: Allows users or external entities to deposit ETH (via `receive()` fallback) or ERC-20 tokens into the `AetherForge` treasury.
19. **`proposeTreasuryAllocation(TreasuryAllocationType _type, address _targetAddress, uint256 _amount, bytes memory _data)`**: A participant proposes how to allocate funds from the treasury (e.g., AI model subscriptions, bounties, operational costs). Requires `MIN_SHARDS_FOR_PROPOSAL`.
20. **`voteOnTreasuryAllocation(uint256 _proposalId, bool _support)`**: Participants vote on a `TreasuryAllocation` proposal, weighted by their `AetherShards`.
21. **`executeTreasuryAllocation(uint256 _proposalId)`**: Executes a passed `TreasuryAllocation` proposal, transferring funds as specified.
22. **`withdrawStuckFunds(address _tokenAddress, uint256 _amount)`**: Allows the governor to recover accidentally sent ETH or ERC-20 tokens from the contract.

**VI. Oracle Interaction**
*(These functions interact with the `IAetherForgeOracle` external contract interface)*
23. **`requestOracleData(bytes32 _queryId, string memory _url, bytes memory _callbackFunction)`**: Requests specific data (e.g., AI model status, pricing, or output verification) from the connected AI Oracle.
24. **`receiveOracleData(bytes32 _queryId, bytes memory _data)`**: A callback function, only callable by the trusted oracle, to deliver requested data back to the contract.

**VII. View & Utility Functions**
25. **`getPromptIdea(uint256 _promptId)`**: Retrieves the detailed information for a specific `PromptIdea`.
26. **`getAIOutputClaim(uint256 _claimId)`**: Retrieves the detailed information for a specific `AIOutputClaim`.
27. **`getTreasuryBalance()`**: Returns the total ETH balance currently held in the `AetherForge` treasury.
28. **`getTotalAetherShardsSupply()`**: Returns the total amount of `AetherShards` currently in circulation. (Assumes getter on `IAetherShards`).
29. **`getCurrentGovernor()`**: Returns the address currently designated as the main governor of the `AetherForge`.

---

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Interfaces for Dependent Contracts ---

interface IAetherShards {
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function initialShards() external view returns (uint256); // For new participants to receive
    function totalShardsSupply() external view returns (uint256); // Total supply for quorum calculation
}

interface IAetherGems is IERC721 {
    // AetherForge will mint these NFTs to represent curated AI works
    function mint(address to, uint256 promptId, uint256 claimId, string memory tokenURI) external returns (uint256);
    // IERC721 already provides ownerOf, tokenURI, etc.
}

interface IAetherForgeOracle {
    // Generic function for requesting data from the oracle
    function requestData(bytes32 queryId, string memory url, bytes memory callbackFunction, uint256 fee) external;
    // More specific functions could be added here, e.g., for AI model status, output verification, etc.
}

/**
 * @title AetherForge
 * @dev A Decentralized Autonomous Organization (DAO) for collaborative, AI-assisted creative work.
 * It manages reputation (AetherShards), curates AI-generated content (AetherGems NFTs),
 * and allocates treasury funds through reputation-weighted governance.
 */
contract AetherForge is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    address public aetherShardsContract; // Address of the AetherShards (reputation token) contract
    address public aetherGemsContract;   // Address of the AetherGems (NFT for AI works) contract
    address public aiOracleAddress;      // Address of the trusted AI Oracle
    address public currentGovernor;      // The address currently designated as the main DAO governor

    uint256 public constant VOTING_PERIOD_DURATION = 7 days;           // Duration for all voting periods
    uint256 public constant MIN_SHARDS_FOR_PROPOSAL = 1000 * 1e18;     // Min shards needed to submit a proposal (e.g., 1000 tokens)
    uint256 public constant QUORUM_PERCENTAGE = 20;                    // 20% of total shards needed for a proposal to meet quorum
    uint256 public constant MAJORITY_PERCENTAGE = 51;                  // 51% of *voted* shards needed for approval

    uint256 public nextPromptId;                       // Counter for unique prompt ideas
    uint256 public nextClaimId;                        // Counter for unique AI output claims
    uint256 public nextTreasuryAllocationProposalId;   // Counter for treasury allocation proposals
    uint256 public nextGovernorProposalId;             // Counter for governor change proposals

    // --- Structs ---

    struct PromptIdea {
        uint256 id;
        address creator;
        string promptText;
        uint256 bountyAmount;   // ETH attached as a bounty for fulfilling the prompt
        uint256 submissionTime;
        bool active;            // True if prompt is open for claims, false if an output is approved
    }

    struct AIOutputClaim {
        uint256 id;
        uint256 promptId;      // Link to the original prompt idea
        address claimant;      // The address who submitted this AI output
        string aiModelUsed;    // e.g., "DALL-E3", "Midjourney-v5", "GPT-4"
        bytes32 outputHash;    // Cryptographic hash of the AI-generated content (e.g., image, text, audio)
        string metadataURI;    // URI pointing to actual content and its details (e.g., IPFS CID)
        uint256 submissionTime;
        bool approved;         // True if the claim was approved by DAO vote
        bool executed;         // True if the claim execution (NFT mint, bounty transfer) was performed
        uint256 yesVotes;      // Total AetherShards weight for 'yes'
        uint256 noVotes;       // Total AetherShards weight for 'no'
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this claim
        uint256 votingEndTime;
    }

    enum TreasuryAllocationType {
        AIModelSubscription,    // Funds for subscribing to AI models
        ContributorBountyPool,  // General bounty pool for contributors
        OperationalCosts,       // General operational expenses
        Custom                  // For unlisted purposes, requires more specific `data`
    }

    struct TreasuryAllocationProposal {
        uint256 id;
        address proposer;
        TreasuryAllocationType proposalType;
        address targetAddress;  // The address to send funds to
        uint256 amount;         // Amount of ETH to transfer
        bytes data;             // Extra data for custom proposals or specific details
        uint256 submissionTime;
        bool executed;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        uint256 votingEndTime;
    }

    struct GovernorProposal {
        uint256 id;
        address proposer;
        address newGovernorCandidate; // The address proposed to become the new governor
        uint256 submissionTime;
        bool executed;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        uint256 votingEndTime;
    }

    // --- Mappings ---

    mapping(uint256 => PromptIdea) public promptIdeas;
    mapping(uint256 => AIOutputClaim) public aiOutputClaims;
    mapping(uint256 => TreasuryAllocationProposal) public treasuryAllocationProposals;
    mapping(uint256 => GovernorProposal) public governorProposals;

    // --- Events ---

    event OracleAddressUpdated(address indexed newOracleAddress);
    event AetherShardsContractSet(address indexed shardsContract);
    event AetherGemsContractSet(address indexed gemsContract);
    event NewParticipantRegistered(address indexed participant, uint256 initialShards);
    event ShardsAwarded(address indexed recipient, uint256 amount);
    event ShardsDeducted(address indexed recipient, uint256 amount);
    event PromptIdeaSubmitted(uint256 indexed promptId, address indexed creator, uint256 bountyAmount);
    event AIOutputClaimSubmitted(uint256 indexed claimId, uint256 indexed promptId, address indexed claimant, bytes32 outputHash);
    event AIOutputClaimVoted(uint256 indexed claimId, address indexed voter, bool support, uint256 voteWeight);
    event AIOutputClaimApproved(uint256 indexed claimId, uint256 indexed promptId, uint256 gemTokenId, address claimant, uint256 bountyAmount);
    event FundsDeposited(address indexed depositor, uint256 amount); // For both ETH and ERC20
    event TreasuryAllocationProposed(uint256 indexed proposalId, address indexed proposer, TreasuryAllocationType proposalType, uint256 amount);
    event TreasuryAllocationVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event TreasuryAllocationExecuted(uint256 indexed proposalId, address indexed target, uint256 amount);
    event GovernorProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address indexed newGovernor);
    event GovernorProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event GovernorChanged(address indexed oldGovernor, address indexed newGovernor);
    event OracleDataRequested(bytes32 indexed queryId, string url, bytes callbackFunction);
    event OracleDataReceived(bytes32 indexed queryId, bytes data);

    // --- Modifiers ---

    modifier onlyGovernor() {
        // Allows both the contract's Ownable owner and the DAO-appointed currentGovernor to act
        require(msg.sender == owner() || msg.sender == currentGovernor, "AetherForge: Only governor or owner can perform this action");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == aiOracleAddress, "AetherForge: Only the registered AI Oracle can call this function");
        _;
    }

    modifier hasMinShards(uint256 _amount) {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        require(IAetherShards(aetherShardsContract).balanceOf(msg.sender) >= _amount, "AetherForge: Insufficient AetherShards to propose");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Initializes the AetherForge contract.
     * @param _aiOracleAddress The address of the trusted AI oracle contract.
     * @param _initialGovernor The address designated as the initial DAO governor.
     */
    constructor(address _aiOracleAddress, address _initialGovernor) Ownable(msg.sender) {
        require(_aiOracleAddress != address(0), "AetherForge: Oracle address cannot be zero");
        require(_initialGovernor != address(0), "AetherForge: Initial governor cannot be zero");

        aiOracleAddress = _aiOracleAddress;
        currentGovernor = _initialGovernor; // Can be different from the contract owner
        nextPromptId = 1;
        nextClaimId = 1;
        nextTreasuryAllocationProposalId = 1;
        nextGovernorProposalId = 1;

        emit OracleAddressUpdated(_aiOracleAddress);
        emit GovernorChanged(address(0), _initialGovernor);
    }

    // --- I. Core Management & Access Control ---

    /**
     * @dev Sets or updates the address of the trusted AI Oracle.
     * @param _newOracleAddress The new address for the AI oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) external onlyGovernor {
        require(_newOracleAddress != address(0), "AetherForge: New oracle address cannot be zero");
        aiOracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(_newOracleAddress);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     * Can only be called by the current governor or owner.
     */
    function pauseContract() external onlyGovernor {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Can only be called by the current governor or owner.
     */
    function unpauseContract() external onlyGovernor {
        _unpause();
    }

    /**
     * @dev Links the AetherForge contract to the AetherShards (reputation token) contract.
     * @param _shardsContract The address of the AetherShards contract.
     */
    function setAetherShardsContract(address _shardsContract) external onlyGovernor {
        require(_shardsContract != address(0), "AetherForge: Shards contract address cannot be zero");
        aetherShardsContract = _shardsContract;
        emit AetherShardsContractSet(_shardsContract);
    }

    /**
     * @dev Links the AetherForge contract to the AetherGems (NFT for AI works) contract.
     * @param _gemsContract The address of the AetherGems contract.
     */
    function setAetherGemsContract(address _gemsContract) external onlyGovernor {
        require(_gemsContract != address(0), "AetherForge: Gems contract address cannot be zero");
        aetherGemsContract = _gemsContract;
        emit AetherGemsContractSet(_gemsContract);
    }

    /**
     * @dev Initiates a DAO vote to transfer the governor role to a new address.
     * Requires the caller to hold `MIN_SHARDS_FOR_PROPOSAL` AetherShards.
     * @param _newGovernorCandidate The address proposed to become the new governor.
     */
    function proposeNewGovernor(address _newGovernorCandidate) external whenNotPaused hasMinShards(MIN_SHARDS_FOR_PROPOSAL) {
        require(_newGovernorCandidate != address(0), "AetherForge: New governor candidate cannot be zero address");
        require(_newGovernorCandidate != currentGovernor, "AetherForge: Candidate is already the current governor");

        uint256 proposalId = nextGovernorProposalId++;
        governorProposals[proposalId] = GovernorProposal({
            id: proposalId,
            proposer: msg.sender,
            newGovernorCandidate: _newGovernorCandidate,
            submissionTime: block.timestamp,
            executed: false,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp.add(VOTING_PERIOD_DURATION)
        });
        emit GovernorProposalSubmitted(proposalId, msg.sender, _newGovernorCandidate);
    }

    // --- II. AetherShards (Reputation System) ---

    /**
     * @dev Allows a new user to join the collective and receive an initial allocation of AetherShards.
     * A participant can only register once.
     */
    function registerParticipant() external whenNotPaused {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        IAetherShards shards = IAetherShards(aetherShardsContract);
        require(shards.balanceOf(msg.sender) == 0, "AetherForge: Participant already registered");

        shards.mint(msg.sender, shards.initialShards()); // Assuming initialShards() exists on IAetherShards
        emit NewParticipantRegistered(msg.sender, shards.initialShards());
    }

    /**
     * @dev Awards AetherShards to a participant for meritorious contributions.
     * Only callable by the current governor or owner.
     * @param _recipient The address to receive the shards.
     * @param _amount The amount of shards to award.
     */
    function awardShards(address _recipient, uint256 _amount) external onlyGovernor {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        require(_recipient != address(0), "AetherForge: Recipient cannot be zero address");
        require(_amount > 0, "AetherForge: Amount must be greater than zero");
        IAetherShards(aetherShardsContract).mint(_recipient, _amount);
        emit ShardsAwarded(_recipient, _amount);
    }

    /**
     * @dev Deducts AetherShards from a participant for infractions or failed proposals.
     * Only callable by the current governor or owner.
     * @param _recipient The address to deduct shards from.
     * @param _amount The amount of shards to deduct.
     */
    function deductShards(address _recipient, uint256 _amount) external onlyGovernor {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        require(_recipient != address(0), "AetherForge: Recipient cannot be zero address");
        require(_amount > 0, "AetherForge: Amount must be greater than zero");
        IAetherShards(aetherShardsContract).burn(_recipient, _amount);
        emit ShardsDeducted(_recipient, _amount);
    }

    /**
     * @dev Returns the current AetherShards balance (reputation score) of a participant.
     * @param _participant The address whose shard balance is queried.
     * @return The amount of AetherShards held by the participant.
     */
    function getShardsBalance(address _participant) external view returns (uint256) {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        return IAetherShards(aetherShardsContract).balanceOf(_participant);
    }

    // --- III. Creative Process: Prompts & AI Outputs ---

    /**
     * @dev Allows a participant to submit a creative prompt idea for AI generation.
     * Optionally, ETH can be attached as a bounty to incentivize prompt engineers.
     * @param _promptText The textual description of the creative prompt.
     */
    function submitPromptIdea(string memory _promptText) external payable whenNotPaused {
        require(bytes(_promptText).length > 0, "AetherForge: Prompt text cannot be empty");

        uint256 promptId = nextPromptId++;
        promptIdeas[promptId] = PromptIdea({
            id: promptId,
            creator: msg.sender,
            promptText: _promptText,
            bountyAmount: msg.value,
            submissionTime: block.timestamp,
            active: true
        });
        emit PromptIdeaSubmitted(promptId, msg.sender, msg.value);
    }

    /**
     * @dev Allows a prompt engineer to submit an AI-generated output claim for a specific prompt.
     * This claim includes a hash of the content, the AI model used, and a link to metadata/content.
     * Requires the claimant to hold `MIN_SHARDS_FOR_PROPOSAL` AetherShards.
     * @param _promptId The ID of the prompt this output is for.
     * @param _aiModelUsed The name/version of the AI model used for generation.
     * @param _outputHash A cryptographic hash of the AI-generated content.
     * @param _metadataURI A URI pointing to the actual content and its metadata (e.g., IPFS CID).
     */
    function submitAIOutputClaim(
        uint256 _promptId,
        string memory _aiModelUsed,
        bytes32 _outputHash,
        string memory _metadataURI
    ) external whenNotPaused hasMinShards(MIN_SHARDS_FOR_PROPOSAL) {
        require(_promptId > 0 && _promptId < nextPromptId, "AetherForge: Invalid prompt ID");
        PromptIdea storage prompt = promptIdeas[_promptId];
        require(prompt.active, "AetherForge: Prompt is not active or already fulfilled");
        require(bytes(_aiModelUsed).length > 0, "AetherForge: AI model used cannot be empty");
        require(_outputHash != bytes32(0), "AetherForge: Output hash cannot be empty");
        require(bytes(_metadataURI).length > 0, "AetherForge: Metadata URI cannot be empty");

        uint256 claimId = nextClaimId++;
        aiOutputClaims[claimId] = AIOutputClaim({
            id: claimId,
            promptId: _promptId,
            claimant: msg.sender,
            aiModelUsed: _aiModelUsed,
            outputHash: _outputHash,
            metadataURI: _metadataURI,
            submissionTime: block.timestamp,
            approved: false,
            executed: false,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp.add(VOTING_PERIOD_DURATION)
        });
        emit AIOutputClaimSubmitted(claimId, _promptId, msg.sender, _outputHash);
    }

    /**
     * @dev Allows participants to vote on the validity and quality of a submitted AI output claim.
     * Voting power is weighted by the voter's AetherShards balance.
     * @param _claimId The ID of the AI output claim to vote on.
     * @param _support True for 'yes' (approve), false for 'no' (reject).
     */
    function voteOnAIOutputClaim(uint256 _claimId, bool _support) external whenNotPaused {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        require(_claimId > 0 && _claimId < nextClaimId, "AetherForge: Invalid claim ID");
        AIOutputClaim storage claim = aiOutputClaims[_claimId];
        require(claim.votingEndTime > block.timestamp, "AetherForge: Voting period has ended");
        require(!claim.hasVoted[msg.sender], "AetherForge: Already voted on this claim");

        uint256 voterShards = IAetherShards(aetherShardsContract).balanceOf(msg.sender);
        require(voterShards > 0, "AetherForge: Must have AetherShards to vote");

        if (_support) {
            claim.yesVotes = claim.yesVotes.add(voterShards);
        } else {
            claim.noVotes = claim.noVotes.add(voterShards);
        }
        claim.hasVoted[msg.sender] = true;
        emit AIOutputClaimVoted(_claimId, msg.sender, _support, voterShards);
    }

    /**
     * @dev Executes a passed AI output claim, minting an AetherGem NFT,
     * transferring the bounty, and rewarding the claimant with AetherShards.
     * Callable by the current governor or owner after the voting period ends and criteria are met.
     * @param _claimId The ID of the AI output claim to execute.
     */
    function executeAIOutputClaimApproval(uint256 _claimId) external onlyGovernor nonReentrant {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        require(aetherGemsContract != address(0), "AetherForge: AetherGems contract not set");
        require(_claimId > 0 && _claimId < nextClaimId, "AetherForge: Invalid claim ID");
        AIOutputClaim storage claim = aiOutputClaims[_claimId];
        require(!claim.executed, "AetherForge: Claim already executed");
        require(claim.votingEndTime <= block.timestamp, "AetherForge: Voting period is still active"); // Voting period must have ended

        uint256 totalShardsSupply = IAetherShards(aetherShardsContract).totalShardsSupply();
        uint256 totalVotedShards = claim.yesVotes.add(claim.noVotes);

        require(totalVotedShards.mul(100).div(totalShardsSupply) >= QUORUM_PERCENTAGE, "AetherForge: Quorum not met");
        require(claim.yesVotes.mul(100).div(totalVotedShards) >= MAJORITY_PERCENTAGE, "AetherForge: Majority not met");

        claim.approved = true;
        claim.executed = true;
        promptIdeas[claim.promptId].active = false; // Deactivate prompt after an output is approved

        // Mint AetherGem NFT
        IAetherGems gems = IAetherGems(aetherGemsContract);
        uint256 tokenId = gems.mint(claim.claimant, claim.promptId, claim.id, claim.metadataURI);

        // Distribute bounty and rewards
        PromptIdea storage prompt = promptIdeas[claim.promptId];
        if (prompt.bountyAmount > 0) {
            payable(claim.claimant).transfer(prompt.bountyAmount);
        }
        // Reward for successful claim
        IAetherShards(aetherShardsContract).mint(claim.claimant, 500 * 1e18); // Example fixed reward

        emit AIOutputClaimApproved(_claimId, claim.promptId, tokenId, claim.claimant, prompt.bountyAmount);
    }

    // --- IV. AetherGems (NFTs for Curated AI Works) ---

    /**
     * @dev Retrieves the URI for the metadata of a specific AetherGem NFT.
     * @param _tokenId The ID of the AetherGem NFT.
     * @return The metadata URI string.
     */
    function getAetherGemMetadataURI(uint256 _tokenId) external view returns (string memory) {
        require(aetherGemsContract != address(0), "AetherForge: AetherGems contract not set");
        return IAetherGems(aetherGemsContract).tokenURI(_tokenId);
    }

    /**
     * @dev Returns the current owner of a given AetherGem NFT.
     * @param _tokenId The ID of the AetherGem NFT.
     * @return The address of the NFT owner.
     */
    function getAetherGemOwner(uint256 _tokenId) external view returns (address) {
        require(aetherGemsContract != address(0), "AetherForge: AetherGems contract not set");
        return IAetherGems(aetherGemsContract).ownerOf(_tokenId);
    }

    // --- V. Treasury & Resource Allocation (DAO Governance) ---

    /**
     * @dev Fallback function to receive direct ETH deposits into the treasury.
     * Emits a FundsDeposited event.
     */
    receive() external payable {
        if (msg.value > 0) {
            emit FundsDeposited(msg.sender, msg.value);
        }
    }

    /**
     * @dev Allows users or external entities to deposit ERC-20 tokens into the AetherForge treasury.
     * @param _token The address of the ERC-20 token.
     * @param _amount The amount of ERC-20 tokens to deposit.
     */
    function depositFunds(address _token, uint256 _amount) external whenNotPaused {
        require(_amount > 0, "AetherForge: Amount must be greater than zero");
        require(_token != address(0), "AetherForge: Token address cannot be zero");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows a participant to propose how to allocate funds from the treasury.
     * Requires the proposer to hold `MIN_SHARDS_FOR_PROPOSAL` AetherShards.
     * @param _type The type of treasury allocation (e.g., AIModelSubscription).
     * @param _targetAddress The address to send funds to.
     * @param _amount The amount of ETH to transfer.
     * @param _data Extra data for specific details or custom proposals.
     */
    function proposeTreasuryAllocation(
        TreasuryAllocationType _type,
        address _targetAddress,
        uint256 _amount,
        bytes memory _data
    ) external whenNotPaused hasMinShards(MIN_SHARDS_FOR_PROPOSAL) {
        require(_targetAddress != address(0), "AetherForge: Target address cannot be zero");
        require(_amount > 0, "AetherForge: Amount must be greater than zero");

        uint256 proposalId = nextTreasuryAllocationProposalId++;
        treasuryAllocationProposals[proposalId] = TreasuryAllocationProposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: _type,
            targetAddress: _targetAddress,
            amount: _amount,
            data: _data,
            submissionTime: block.timestamp,
            executed: false,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp.add(VOTING_PERIOD_DURATION)
        });
        emit TreasuryAllocationProposed(proposalId, msg.sender, _type, _amount);
    }

    /**
     * @dev Allows participants to vote on a treasury allocation proposal.
     * Voting power is weighted by the voter's AetherShards balance.
     * @param _proposalId The ID of the treasury allocation proposal.
     * @param _support True for 'yes' (approve), false for 'no' (reject).
     */
    function voteOnTreasuryAllocation(uint256 _proposalId, bool _support) external whenNotPaused {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        require(_proposalId > 0 && _proposalId < nextTreasuryAllocationProposalId, "AetherForge: Invalid proposal ID");
        TreasuryAllocationProposal storage proposal = treasuryAllocationProposals[_proposalId];
        require(proposal.votingEndTime > block.timestamp, "AetherForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherForge: Already voted on this proposal");

        uint256 voterShards = IAetherShards(aetherShardsContract).balanceOf(msg.sender);
        require(voterShards > 0, "AetherForge: Must have AetherShards to vote");

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(voterShards);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterShards);
        }
        proposal.hasVoted[msg.sender] = true;
        emit TreasuryAllocationVoted(_proposalId, msg.sender, _support, voterShards);
    }

    /**
     * @dev Executes a passed treasury allocation proposal, transferring ETH from the treasury.
     * Callable by the current governor or owner after the voting period ends and criteria are met.
     * @param _proposalId The ID of the treasury allocation proposal to execute.
     */
    function executeTreasuryAllocation(uint256 _proposalId) external onlyGovernor nonReentrant {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        require(_proposalId > 0 && _proposalId < nextTreasuryAllocationProposalId, "AetherForge: Invalid proposal ID");
        TreasuryAllocationProposal storage proposal = treasuryAllocationProposals[_proposalId];
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(proposal.votingEndTime <= block.timestamp, "AetherForge: Voting period is still active"); // Voting period must have ended

        uint256 totalShardsSupply = IAetherShards(aetherShardsContract).totalShardsSupply();
        uint256 totalVotedShards = proposal.yesVotes.add(proposal.noVotes);

        require(totalVotedShards.mul(100).div(totalShardsSupply) >= QUORUM_PERCENTAGE, "AetherForge: Quorum not met");
        require(proposal.yesVotes.mul(100).div(totalVotedShards) >= MAJORITY_PERCENTAGE, "AetherForge: Majority not met");

        // Execute the transfer
        require(address(this).balance >= proposal.amount, "AetherForge: Insufficient treasury balance for transfer");
        payable(proposal.targetAddress).transfer(proposal.amount);
        proposal.executed = true;

        emit TreasuryAllocationExecuted(_proposalId, proposal.targetAddress, proposal.amount);
    }

    /**
     * @dev Allows the governor to recover accidentally sent ERC-20 tokens or ETH from the contract.
     * Sends funds to the contract owner.
     * @param _tokenAddress The address of the token (ERC-20) or address(0) for ETH.
     * @param _amount The amount to withdraw.
     */
    function withdrawStuckFunds(address _tokenAddress, uint256 _amount) external onlyGovernor {
        if (_tokenAddress == address(0)) { // ETH
            payable(owner()).transfer(_amount);
        } else { // ERC20
            IERC20(_tokenAddress).transfer(owner(), _amount);
        }
    }

    /**
     * @dev Allows participants to vote on a proposal to change the DAO's governor.
     * Voting power is weighted by the voter's AetherShards balance.
     * @param _proposalId The ID of the governor change proposal.
     * @param _support True for 'yes' (approve), false for 'no' (reject).
     */
    function voteOnGovernorProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        require(_proposalId > 0 && _proposalId < nextGovernorProposalId, "AetherForge: Invalid proposal ID");
        GovernorProposal storage proposal = governorProposals[_proposalId];
        require(proposal.votingEndTime > block.timestamp, "AetherForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherForge: Already voted on this proposal");

        uint256 voterShards = IAetherShards(aetherShardsContract).balanceOf(msg.sender);
        require(voterShards > 0, "AetherForge: Must have AetherShards to vote");

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(voterShards);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterShards);
        }
        proposal.hasVoted[msg.sender] = true;
        emit GovernorProposalVoted(_proposalId, msg.sender, _support, voterShards);
    }

    /**
     * @dev Executes a passed governor change proposal, updating the `currentGovernor` address.
     * Callable by the current governor or owner after the voting period ends and criteria are met.
     * @param _proposalId The ID of the governor change proposal to execute.
     */
    function executeGovernorProposal(uint256 _proposalId) external onlyGovernor nonReentrant {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        require(_proposalId > 0 && _proposalId < nextGovernorProposalId, "AetherForge: Invalid proposal ID");
        GovernorProposal storage proposal = governorProposals[_proposalId];
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(proposal.votingEndTime <= block.timestamp, "AetherForge: Voting period is still active"); // Voting period must have ended

        uint256 totalShardsSupply = IAetherShards(aetherShardsContract).totalShardsSupply();
        uint256 totalVotedShards = proposal.yesVotes.add(proposal.noVotes);

        require(totalVotedShards.mul(100).div(totalShardsSupply) >= QUORUM_PERCENTAGE, "AetherForge: Quorum not met");
        require(proposal.yesVotes.mul(100).div(totalVotedShards) >= MAJORITY_PERCENTAGE, "AetherForge: Majority not met");

        address oldGovernor = currentGovernor;
        currentGovernor = proposal.newGovernorCandidate;
        proposal.executed = true;

        emit GovernorChanged(oldGovernor, currentGovernor);
    }


    // --- VI. Oracle Interaction ---

    /**
     * @dev Requests specific data from the connected AI Oracle.
     * Only callable by the current governor or owner.
     * @param _queryId A unique identifier for this data request.
     * @param _url The URL/endpoint for the oracle to fetch data from.
     * @param _callbackFunction The function on this contract for the oracle to call back with results.
     */
    function requestOracleData(bytes32 _queryId, string memory _url, bytes memory _callbackFunction) external onlyGovernor {
        require(aiOracleAddress != address(0), "AetherForge: AI Oracle address not set");
        // Assuming the oracle contract has a `requestData` function
        IAetherForgeOracle(aiOracleAddress).requestData(_queryId, _url, _callbackFunction, 0); // Assuming 0 fee or fee handled off-chain
        emit OracleDataRequested(_queryId, _url, _callbackFunction);
    }

    /**
     * @dev Callback function, only callable by the trusted oracle, to deliver requested data.
     * The specific logic depends on what data is being requested and how it's used
     * (e.g., verifying AI model output, updating AI model costs, etc.).
     * @param _queryId The ID of the original data request.
     * @param _data The data returned by the oracle.
     */
    function receiveOracleData(bytes32 _queryId, bytes memory _data) external onlyOracle {
        // Process the data received from the oracle.
        // This is a placeholder; real implementation would parse _data based on _queryId.
        emit OracleDataReceived(_queryId, _data);
    }


    // --- VII. View & Utility Functions ---

    /**
     * @dev Retrieves the detailed information for a specific PromptIdea.
     * @param _promptId The ID of the prompt idea.
     * @return A PromptIdea struct containing all details.
     */
    function getPromptIdea(uint256 _promptId) external view returns (PromptIdea memory) {
        require(_promptId > 0 && _promptId < nextPromptId, "AetherForge: Invalid prompt ID");
        return promptIdeas[_promptId];
    }

    /**
     * @dev Retrieves the detailed information for a specific AIOutputClaim.
     * @param _claimId The ID of the AI output claim.
     * @return An AIOutputClaim struct containing all details.
     */
    function getAIOutputClaim(uint256 _claimId) external view returns (AIOutputClaim memory) {
        require(_claimId > 0 && _claimId < nextClaimId, "AetherForge: Invalid claim ID");
        return aiOutputClaims[_claimId];
    }

    /**
     * @dev Returns the total ETH balance currently held in the AetherForge treasury.
     * @return The current ETH balance.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the total amount of AetherShards currently in circulation.
     * @return The total supply of AetherShards.
     */
    function getTotalAetherShardsSupply() external view returns (uint256) {
        require(aetherShardsContract != address(0), "AetherForge: AetherShards contract not set");
        return IAetherShards(aetherShardsContract).totalShardsSupply();
    }

    /**
     * @dev Returns the address currently designated as the main governor of the AetherForge.
     * This address has elevated permissions within the DAO.
     * @return The current governor's address.
     */
    function getCurrentGovernor() external view returns (address) {
        return currentGovernor;
    }
}
```

---

### Mock Contracts (for testing purposes)

These contracts are minimal implementations of `AetherShards` and `AetherGems`. In a real production environment, `AetherShards` would be a dedicated Soulbound Token (SBT) implementation, ensuring non-transferability, and `AetherGems` would be a robust ERC721 NFT with potentially more complex metadata and features.

```solidity
// Mock AetherShards.sol
// For demonstration, this is a simplified ERC20, but conceptually it should be non-transferable (SBT).
// A true SBT would override transfer/transferFrom to revert, making it soulbound.
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AetherShards is ERC20, Ownable {
    uint256 public initialShardsAmount = 100 * (10 ** decimals()); // Amount new participants get

    constructor() ERC20("AetherShards", "ASH") Ownable(msg.sender) {
        // Mint some initial shards to the deployer for testing and initial governance
        _mint(msg.sender, 1000000 * (10 ** decimals()));
    }

    /**
     * @dev Sets the amount of shards a new participant receives upon registration.
     * @param _amount The new initial amount of shards.
     */
    function setInitialShards(uint256 _amount) external onlyOwner {
        initialShardsAmount = _amount;
    }

    /**
     * @dev Mints new AetherShards to an address. Restricted to the owner (AetherForge).
     * @param to The recipient address.
     * @param amount The amount of shards to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns AetherShards from an address. Restricted to the owner (AetherForge).
     * @param from The address to burn shards from.
     * @param amount The amount of shards to burn.
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    // In a true Soulbound Token, these functions would revert to prevent transfers:
    // function transfer(address to, uint256 amount) public pure override returns (bool) {
    //     revert("AetherShards: This token is non-transferable (Soulbound)");
    // }
    // function transferFrom(address from, address to, uint256 amount) public pure override returns (bool) {
    //     revert("AetherShards: This token is non-transferable (Soulbound)");
    // }

    /**
     * @dev Returns the amount of AetherShards a new participant receives.
     */
    function initialShards() external view returns (uint256) {
        return initialShardsAmount;
    }

    /**
     * @dev Returns the total supply of AetherShards.
     */
    function totalShardsSupply() external view returns (uint256) {
        return totalSupply();
    }
}


// Mock AetherGems.sol
// A simplified ERC721 NFT contract for demonstrating AetherForge's functionality.
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AetherGems is ERC721, Ownable {
    uint256 private _nextTokenId; // Counter for unique token IDs

    constructor() ERC721("AetherGems", "AGEM") Ownable(msg.sender) {
        _nextTokenId = 1; // Start token IDs from 1
    }

    /**
     * @dev Mints a new AetherGem NFT. Restricted to the owner (AetherForge).
     * @param to The recipient address for the new NFT.
     * @param promptId The ID of the prompt idea associated with this gem.
     * @param claimId The ID of the AI output claim associated with this gem.
     * @param tokenURI The URI for the NFT's metadata (e.g., IPFS CID).
     * @return The ID of the newly minted token.
     */
    function mint(address to, uint256 promptId, uint256 claimId, string memory tokenURI) external onlyOwner returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI); // Set the URI for this specific gem
        // In a more complex scenario, promptId and claimId might be stored directly in a mapping here.
        return newTokenId;
    }

    /**
     * @dev Burns an AetherGem NFT. Restricted to the owner (AetherForge).
     * @param tokenId The ID of the token to burn.
     */
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
```