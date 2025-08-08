This Solidity smart contract, named `AetherCanvasDAO`, proposes a unique and advanced concept for a decentralized autonomous organization that governs an AI-driven generative art platform. It integrates several modern blockchain concepts including dynamic NFTs, oracle-based AI interaction, a comprehensive governance system, a reputation mechanism, and a community-driven curation market, while striving to avoid direct duplication of existing open-source project logic for its core business functions.

---

**Outline and Function Summary:**

**Contract Name:** `AetherCanvasDAO`

**Concept:** A decentralized autonomous organization (DAO) governing a platform for AI-driven generative art. Users propose text prompts, the community votes on them, and winning prompts are sent via oracle to an AI art generator. The resulting art is minted as dynamic NFTs, which can be further evolved through community consensus. The platform also features NFT staking for governance power, a reputation system, a community treasury, and a curation market for discoverability.

**Core Principles:**
*   **Community-Driven Creation:** Art generation guided by decentralized voting.
*   **Dynamic NFTs:** NFTs that can evolve and update their visual representation based on community decisions.
*   **Oracle Integration:** Securely bridges off-chain AI computation results on-chain.
*   **DAO Governance:** Comprehensive control over platform parameters, treasury, and operations.
*   **Reputation & Incentives:** Encourages active and constructive participation.
*   **Curation Market:** A decentralized mechanism for art discoverability and featuring.

---

**Function Summary (31 functions):**

**I. Core Setup & Administration (Standard OpenZeppelin Governor Functions & Admin)**
1.  `constructor(address _governanceToken, address _initialOracle, uint256 _promptVotingPeriod, uint256 _governanceVotingDelay, uint256 _governanceVotingPeriod, uint256 _curationVotingPeriod, uint256 _reputationBoostPeriod)`: Initializes the contract with essential parameters, governance token address, initial AI oracle, and voting periods. Sets up the DAO components.
2.  `setOracleAddress(address _newOracle)`: Allows the DAO (via governance proposal) to update the trusted AI oracle address.
3.  `pause()`: Pauses core contract functionalities in emergencies (governance action).
4.  `unpause()`: Unpauses the contract (governance action).
5.  `propose(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, string calldata description)`: Standard OpenZeppelin Governor function for users to propose general DAO actions (e.g., changing parameters, treasury spending).
6.  `castVote(uint256 proposalId, uint8 support)`: Standard OpenZeppelin Governor function to cast a vote on an active governance proposal.
7.  `queue(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bytes32 descriptionHash)`: Standard OpenZeppelin Governor function to queue a successful governance proposal for execution after a timelock.
8.  `execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bytes32 descriptionHash)`: Standard OpenZeppelin Governor function to execute a queued and passed governance proposal.

**II. Prompt Management & AI Generation Workflow (Custom Logic)**
9.  `proposeAetherPrompt(string calldata _promptText)`: Users submit new AI art prompts for community voting.
10. `commitVoteOnPrompt(uint256 _promptId, bytes32 _commitment)`: Users commit their vote for a prompt, part of a commit-reveal scheme to prevent front-running.
11. `revealVoteOnPrompt(uint256 _promptId, bool _support, uint256 _salt)`: Users reveal their actual vote and salt to verify their commitment.
12. `finalizePromptVoting(uint256 _promptId)`: Ends the voting period for a prompt. If passed by votes, it triggers an event for off-chain AI generation.
13. `submitAetherPromptResult(uint256 _promptId, string calldata _ipfsHash, bytes calldata _signature)`: **(Only Oracle)** The trusted AI oracle submits the IPFS hash of the generated art along with a cryptographic signature, leading to NFT minting.
14. `getPromptDetails(uint256 _promptId)`: Retrieves comprehensive details about a specific prompt, including its status and voting results.

**III. Dynamic NFT Management (ERC721 Extension & Custom Logic)**
15. `_safeMintForPrompt(address _to, uint256 _promptId, string calldata _ipfsHash)`: **(Internal)** Helper function to mint a new AetherArt NFT after successful AI generation.
16. `evolveAetherArtNFT(uint256 _tokenId, string calldata _newPromptText)`: Allows an existing NFT holder to propose a new AI prompt specifically to evolve their artwork, initiating a new voting cycle linked to that NFT.
17. `finalizeEvolutionVoting(uint256 _evolvePromptId)`: Ends voting for an NFT evolution prompt. If successful, triggers new AI generation for the linked NFT, which updates its metadata.
18. `setTokenURI(uint256 _tokenId, string calldata _newUri)`: **(Only Governor)** Allows the DAO to update an NFT's URI, primarily used after an evolution.
19. `tokenURI(uint256 _tokenId)`: Overrides the standard ERC721 `tokenURI` function to return the current IPFS hash for a given NFT, reflecting any evolutions.

**IV. Staking & Incentives (Custom Logic)**
20. `stakeAetherNFT(uint256 _tokenId)`: Allows an AetherArt NFT owner to stake their NFT within the contract, earning reputation and potential future rewards, and increasing their influence in curation.
21. `unstakeAetherNFT(uint256 _tokenId)`: Allows an owner to unstake their AetherArt NFT, returning it to their wallet.
22. `claimStakingRewards()`: Allows staked NFT holders to claim their accrued rewards (e.g., from a portion of platform fees or treasury distributions – this part is simplified for demonstration).
23. `distributePromptIncentives(uint256 _promptId)`: **(Internal)** Distributes a portion of the treasury to the original prompt proposer and voters of a successfully generated prompt, based on their participation.

**V. Reputation System (Custom Logic)**
24. `getReputation(address _user)`: Returns the accumulated reputation score for a given user, reflecting their positive contributions and participation.

**VI. Treasury & Fee Management (Custom Logic)**
25. `depositToTreasury()`: Allows anyone to contribute funds (ETH) to the DAO's treasury, which is used to cover AI generation costs and incentives.
26. `withdrawFromTreasury(address _to, uint256 _amount)`: **(Only Governor)** Allows the DAO to transfer ETH from the treasury to a specified address.
27. `receive()`: A fallback function that allows the contract to receive direct ETH deposits, treating them as treasury contributions.

**VII. Curation Market (Custom Logic)**
28. `submitForCuration(uint256 _tokenId)`: Allows an AetherArt NFT owner to submit their NFT for community review, aiming to get it featured on the platform.
29. `voteOnCuration(uint256 _curationId, bool _isFeatured)`: Community members vote on whether a submitted NFT should be featured.
30. `finalizeCurationVote(uint256 _curationId)`: Finalizes the curation vote. If successful, updates the NFT's status to 'featured'.
31. `getFeaturedArt()`: Returns a list of AetherArt NFTs that are currently featured by the community.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For `tokenOfOwnerByIndex` etc.
import "@openzeppelin/contracts/access/Ownable.sol"; // Used initially, then roles controlled by DAO
import "@openzeppelin/contracts/utils/Pausable.sol"; // Emergency pause functionality
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safe arithmetic operations
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256 to string conversion
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For oracle signature verification
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For the governance token interface
import "@openzeppelin/contracts/governance/TimelockController.sol"; // Critical for DAO controlled execution
import "@openzeppelin/contracts/governance/Governor.sol"; // Base Governor contract
import "@openzeppelin/contracts/governance/GovernorSettings.sol"; // For governor settings
import "@openzeppelin/contracts/governance/GovernorCountingSimple.sol"; // Simple majority voting
import "@openzeppelin/contracts/governance/GovernorVotes.sol"; // For token-based voting power
import "@openzeppelin/contracts/governance/GovernorVotesQuorumFraction.sol"; // Quorum based on fraction of total supply
import "@openzeppelin/contracts/governance/IGovernor.sol"; // Interface for Governor

/*
Outline and Function Summary:

Contract Name: AetherCanvasDAO

Concept: A decentralized autonomous organization (DAO) governing a platform for AI-driven generative art. Users propose text prompts, the community votes on them, and winning prompts are sent via oracle to an AI art generator. The resulting art is minted as dynamic NFTs, which can be further evolved through community consensus. The platform also features NFT staking for governance power, a reputation system, a community treasury, and a curation market for discoverability.

Core Principles:
*   Community-Driven Creation: Art generation guided by decentralized voting.
*   Dynamic NFTs: NFTs that can evolve and update their visual representation based on community decisions.
*   Oracle Integration: Securely bridges off-chain AI computation results on-chain.
*   DAO Governance: Comprehensive control over platform parameters, treasury, and operations.
*   Reputation & Incentives: Encourages active and constructive participation.
*   Curation Market: A decentralized mechanism for art discoverability and featuring.

Function Summary (31 functions):

I. Core Setup & Administration (Standard OpenZeppelin Governor Functions & Admin)
1.  constructor(address _governanceToken, address _initialOracle, uint256 _promptVotingPeriod, uint256 _governanceVotingDelay, uint256 _governanceVotingPeriod, uint256 _curationVotingPeriod, uint256 _reputationBoostPeriod): Initializes the contract with essential parameters, governance token address, initial AI oracle, and voting periods. Sets up the DAO components.
2.  setOracleAddress(address _newOracle): Allows the DAO (via governance proposal) to update the trusted AI oracle address.
3.  pause(): Pauses core contract functionalities in emergencies (governance action).
4.  unpause(): Unpauses the contract (governance action).
5.  propose(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, string calldata description): Standard OpenZeppelin Governor function for users to propose general DAO actions (e.g., changing parameters, treasury spending).
6.  castVote(uint256 proposalId, uint8 support): Standard OpenZeppelin Governor function to cast a vote on an active governance proposal.
7.  queue(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bytes32 descriptionHash): Standard OpenZeppelin Governor function to queue a successful governance proposal for execution after a timelock.
8.  execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bytes32 descriptionHash): Standard OpenZeppelin Governor function to execute a queued and passed governance proposal.

II. Prompt Management & AI Generation Workflow (Custom Logic)
9.  proposeAetherPrompt(string calldata _promptText): Users submit new AI art prompts for community voting.
10. commitVoteOnPrompt(uint256 _promptId, bytes32 _commitment): Users commit their vote for a prompt, part of a commit-reveal scheme to prevent front-running.
11. revealVoteOnPrompt(uint256 _promptId, bool _support, uint256 _salt): Users reveal their actual vote and salt to verify their commitment.
12. finalizePromptVoting(uint256 _promptId): Ends the voting period for a prompt. If passed by votes, it triggers an event for off-chain AI generation.
13. submitAetherPromptResult(uint256 _promptId, string calldata _ipfsHash, bytes calldata _signature): (Only Oracle) The trusted AI oracle submits the IPFS hash of the generated art along with a cryptographic signature, leading to NFT minting.
14. getPromptDetails(uint256 _promptId): Retrieves comprehensive details about a specific prompt, including its status and voting results.

III. Dynamic NFT Management (ERC721 Extension & Custom Logic)
15. _safeMintForPrompt(address _to, uint256 _promptId, string calldata _ipfsHash): (Internal) Helper function to mint a new AetherArt NFT after successful AI generation.
16. evolveAetherArtNFT(uint256 _tokenId, string calldata _newPromptText): Allows an existing NFT holder to propose a new AI prompt specifically to evolve their artwork, initiating a new voting cycle linked to that NFT.
17. finalizeEvolutionVoting(uint256 _evolvePromptId): Ends voting for an NFT evolution prompt. If successful, triggers new AI generation for the linked NFT, which updates its metadata.
18. setTokenURI(uint256 _tokenId, string calldata _newUri): (Only Governor) Allows the DAO to update an NFT's URI, primarily used after an evolution.
19. tokenURI(uint256 _tokenId): Overrides the standard ERC721 `tokenURI` function to return the current IPFS hash for a given NFT, reflecting any evolutions.

IV. Staking & Incentives (Custom Logic)
20. stakeAetherNFT(uint256 _tokenId): Allows an AetherArt NFT owner to stake their NFT within the contract, earning reputation and potential future rewards, and increasing their influence in curation.
21. unstakeAetherNFT(uint256 _tokenId): Allows an owner to unstake their AetherArt NFT, returning it to their wallet.
22. claimStakingRewards(): Allows staked NFT holders to claim their accrued rewards (e.g., from a portion of platform fees or treasury distributions – this part is simplified for demonstration).
23. distributePromptIncentives(uint256 _promptId): (Internal) Distributes a portion of the treasury to the original prompt proposer and voters of a successfully generated prompt, based on their participation.

V. Reputation System (Custom Logic)
24. getReputation(address _user): Returns the accumulated reputation score for a given user, reflecting their positive contributions and participation.

VI. Treasury & Fee Management (Custom Logic)
25. depositToTreasury(): Allows anyone to contribute funds (ETH) to the DAO's treasury, which is used to cover AI generation costs and incentives.
26. withdrawFromTreasury(address _to, uint256 _amount): (Only Governor) Allows the DAO to transfer ETH from the treasury to a specified address.
27. receive(): A fallback function that allows the contract to receive direct ETH deposits, treating them as treasury contributions.

VII. Curation Market (Custom Logic)
28. submitForCuration(uint256 _tokenId): Allows an AetherArt NFT owner to submit their NFT for community review, aiming to get it featured on the platform.
29. voteOnCuration(uint256 _curationId, bool _isFeatured): Community members vote on whether a submitted NFT should be featured.
30. finalizeCurationVote(uint256 _curationId): Finalizes the curation vote. If successful, updates the NFT's status to 'featured'.
31. getFeaturedArt(): Returns a list of AetherArt NFTs that are currently featured by the community.
*/

// Helper library for reputation calculation
library ReputationHelper {
    using SafeMath for uint256;

    // A simplified reputation calculation for voters.
    // In a real system, this could be more sophisticated (e.g., quadratic, weighted by stake).
    function calculatePromptVoterReputation(bool _successfulReveal) internal pure returns (uint256) {
        return _successfulReveal ? 5 : 0; // Fixed 5 reputation points for a successful vote reveal
    }

    // Reputation for a successful prompt proposer.
    function calculatePromptProposerReputation(bool _promptSuccess) internal pure returns (uint256) {
        return _promptSuccess ? 50 : 0; // 50 reputation points for a prompt that leads to art generation
    }

    // Reputation for a vote in the curation market.
    function calculateCurationReputation(bool _successfulVote) internal pure returns (uint256) {
        return _successfulVote ? 5 : 0; // 5 reputation points for a valid curation vote
    }

    // Reputation boost from staking NFTs, decays over time or caps.
    // Represents a continuous engagement bonus.
    function calculateStakingReputationBoost(uint256 _stakedDurationInSeconds, uint256 _reputationBoostPeriod) internal pure returns (uint256) {
        if (_reputationBoostPeriod == 0) return 0;
        // Example: 10 reputation per full reputationBoostPeriod (e.g., per week) staked, up to a max
        uint256 boost = (_stakedDurationInSeconds / _reputationBoostPeriod).mul(10);
        return Math.min(boost, 200); // Cap at 200 for this example
    }
}

contract AetherCanvasDAO is
    ERC721Enumerable, // Provides enumeration methods for NFTs (tokenOfOwnerByIndex, totalSupply etc.)
    Ownable,        // Used for initial deployment/setup, though DAO will take control over critical functions
    Pausable,       // Allows pausing functions in emergencies
    Governor,       // Core DAO logic: proposal, voting, execution
    GovernorSettings, // Governor configuration (voting delay, period, threshold)
    GovernorCountingSimple, // Simple majority voting mechanism
    GovernorVotes, // Integrates with ERC20Votes or ERC721Votes for voting power
    GovernorVotesQuorumFraction // Defines quorum as a fraction of total supply
{
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; // For verifying oracle signatures

    // --- Events ---
    event AetherPromptProposed(uint256 indexed promptId, address indexed proposer, string promptText);
    event PromptVoteCommitted(uint256 indexed promptId, address indexed voter, bytes32 commitment);
    event PromptVoteRevealed(uint256 indexed promptId, address indexed voter, bool support);
    event PromptVotingFinalized(uint256 indexed promptId, bool passed, string promptText, address proposer);
    event AetherArtGenerated(uint256 indexed promptId, uint256 indexed tokenId, string ipfsHash);
    event AetherArtEvolutionProposed(uint256 indexed tokenId, uint256 indexed evolvePromptId, string newPromptText);
    event AetherArtEvolutionFinalized(uint256 indexed tokenId, uint256 indexed evolvePromptId, string newIpfsHash);
    event NFTStaked(uint256 indexed tokenId, address indexed staker);
    event NFTUnstaked(uint256 indexed tokenId, address indexed unstaker);
    event StakingRewardsClaimed(address indexed claimer, uint256 amount);
    event PromptIncentivesDistributed(uint256 indexed promptId, uint256 totalAmount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event DepositToTreasury(address indexed depositor, uint256 amount);
    event WithdrawalFromTreasury(address indexed recipient, uint256 amount);
    event CurationSubmitted(uint256 indexed curationId, uint256 indexed tokenId, address indexed submitter);
    event CurationVoteCast(uint256 indexed curationId, address indexed voter, bool isFeatured);
    event CurationVotingFinalized(uint256 indexed curationId, uint256 indexed tokenId, bool featured);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);

    // --- State Variables ---

    // Governance
    IERC20 public immutable governanceToken; // The ERC20 token used for DAO voting power
    TimelockController public immutable timelock; // Manages execution delays for DAO proposals
    address public treasury; // The address where DAO funds (ETH) are held (this contract itself)

    // AI Oracle
    address public aetherOracle; // The trusted off-chain AI art generation oracle's address

    // Prompt Management
    uint256 public nextPromptId; // Counter for unique prompt IDs
    uint256 public promptVotingPeriod; // Duration in seconds for prompt voting
    uint256 public reputationBoostPeriod; // Duration in seconds for staking reputation accumulation

    enum PromptStatus {
        Pending,        // Just proposed, waiting for voting to start
        Voting,         // Open for commit/reveal voting
        Passed,         // Voted 'yes', ready for AI generation
        Failed,         // Voted 'no' or voting period ended without passing
        Generated,      // Art generated, NFT minted
        EvolutionPending // For evolution prompts, waiting for new AI generation based on a passed evolution vote
    }

    struct Prompt {
        uint256 id;
        string promptText;
        address proposer; // The address that proposed this prompt
        uint256 proposalTimestamp; // When the prompt was proposed
        uint256 votingEndTime; // When the voting period for this prompt ends
        PromptStatus status;
        uint256 yesVotes; // Count of 'yes' votes
        uint256 noVotes;  // Count of 'no' votes
        uint256 tokenIdLinked; // If an evolution prompt, the ID of the NFT being evolved; 0 otherwise
        bool isEvolution; // True if this prompt is for an NFT evolution
        mapping(address => bytes32) voterCommitments; // Stores vote commitments for commit-reveal
        mapping(address => bool) voterRevealed; // Tracks if a voter has revealed their vote for this prompt
    }
    mapping(uint256 => Prompt) public prompts; // promptId => Prompt details
    uint256[] public activePromptIds; // A list of prompts currently in the voting phase (for easier iteration, though might be gas-intensive for large arrays)

    // AetherArt NFTs (ERC721 extension with custom metadata)
    struct AetherArtMetadata {
        string ipfsHash; // IPFS hash pointing to the art image/metadata JSON
        uint256 promptId; // The initial prompt ID that created this NFT
        bool isFeatured; // Indicates if the NFT is currently featured in the curation market
        uint256 lastEvolutionPromptId; // The ID of the last prompt that successfully evolved this NFT
    }
    mapping(uint256 => AetherArtMetadata) public aetherArtMetadata; // NFT ID => Custom metadata

    // Staking for NFTs
    struct StakedNFTInfo {
        address staker; // The address that staked this NFT
        uint256 stakeTimestamp; // When the NFT was staked
        bool isStaked; // True if the NFT is currently staked
    }
    mapping(uint256 => StakedNFTInfo) public stakedNFTs; // tokenId => Staking information

    // Reputation System
    mapping(address => uint256) public reputationScores; // userAddress => accumulated reputation score

    // Curation Market
    uint256 public nextCurationId; // Counter for unique curation proposal IDs
    uint256 public curationVotingPeriod; // Duration in seconds for curation voting

    enum CurationStatus {
        Pending,       // Just submitted, waiting for voting
        Voting,        // Open for voting
        Featured,      // Voted 'yes' and now featured
        NotFeatured    // Voted 'no' or voting period ended without passing
    }

    struct Curation {
        uint256 id;
        uint256 tokenId; // The NFT ID proposed for curation
        address submitter; // The address that submitted this NFT for curation
        uint256 proposalTimestamp; // When the curation proposal was made
        uint256 votingEndTime; // When the curation voting period ends
        CurationStatus status;
        uint256 yesVotes; // Count of 'yes' votes for featuring
        uint256 noVotes;  // Count of 'no' votes against featuring
        mapping(address => bool) voted; // Tracks if an address has voted on this curation
    }
    mapping(uint256 => Curation) public curations; // curationId => Curation details
    uint256[] public featuredArtTokenIds; // List of NFT IDs that are currently featured

    // --- Modifiers ---
    // Restricts a function call to only the designated Aether Oracle address.
    modifier onlyOracle() {
        require(msg.sender == aetherOracle, "ACD: Only callable by the Aether Oracle");
        _;
    }

    // Restricts a function call to only the Governor (DAO) contract itself.
    // This is used for functions that should only be triggered by successful DAO proposals.
    modifier onlyGovernor() {
        // `Governor` will call functions on behalf of itself via `TimelockController`
        // when executing a proposal. So, `msg.sender` would be the TimelockController,
        // which the Governor effectively controls. This ensures decentralization.
        require(TimelockController(timelock).isOperationReady(
                msg.sender, // Target address (this contract)
                0, // Value (ETH sent with call, usually 0 for config changes)
                msg.data, // Calldata of the function call
                bytes32(0) // Pre-calculated hash of description, not used for direct calls
            ),
            "ACD: Only callable via a successful governance proposal"
        );
        _;
    }

    // --- Constructor ---
    // Initializes the AetherCanvasDAO contract, setting up key parameters and DAO components.
    constructor(
        address _governanceToken,          // The address of the ERC20 token used for voting power
        address _initialOracle,            // The initial trusted address for the AI art oracle
        uint256 _promptVotingPeriod,       // Duration (in seconds) for prompt voting
        uint256 _governanceVotingDelay,    // Delay (in blocks) before a governance proposal can be voted on
        uint256 _governanceVotingPeriod,   // Duration (in blocks) for governance proposal voting
        uint256 _curationVotingPeriod,     // Duration (in seconds) for curation voting
        uint256 _reputationBoostPeriod     // Duration (in seconds) for staking reputation calculation
    )
        ERC721("AetherCanvasDAO NFT", "ACDNFT") // Initializes the ERC721 NFT contract with name and symbol
        ERC721Enumerable() // Enables enumeration capabilities for NFTs
        Pausable() // Initializes pausable functionality
        Governor(
            "AetherCanvas Governor", // Name of the Governor contract
            // A temporary TimelockController is created here. In a production setup,
            // this would typically be a pre-deployed TimelockController contract.
            new TimelockController(address(this), new address[](0), new address[](0), 0) // Target, proposers, executors, minDelay
        )
        GovernorSettings(_governanceVotingDelay, _governanceVotingPeriod, 0) // Sets initial Governor settings
        GovernorVotes(_governanceToken) // Links Governor to the governance token for vote counting
        GovernorVotesQuorumFraction(5) // Sets a 5% quorum requirement for proposals
    {
        // Basic input validation
        require(_governanceToken != address(0), "ACD: Invalid governance token address");
        require(_initialOracle != address(0), "ACD: Invalid initial oracle address");
        require(_promptVotingPeriod > 0, "ACD: Prompt voting period must be greater than 0");
        require(_curationVotingPeriod > 0, "ACD: Curation voting period must be greater than 0");
        require(_reputationBoostPeriod > 0, "ACD: Reputation boost period must be greater than 0");

        // Assign initial state variables
        governanceToken = IERC20(_governanceToken);
        aetherOracle = _initialOracle;
        promptVotingPeriod = _promptVotingPeriod;
        curationVotingPeriod = _curationVotingPeriod;
        reputationBoostPeriod = _reputationBoostPeriod;

        // The contract itself will act as the treasury, holding ETH for operations.
        treasury = address(this);

        // Configure the Governor's TimelockController:
        // Grant the Governor contract (this address) the PROPOSER and CANCELLER roles on its own Timelock.
        // Grant the EXECUTOR role to the zero address, meaning anyone can execute a passed proposal after the timelock.
        timelock = TimelockController(Governor.timelock()); // Get the TimelockController instance used by Governor
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(this));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(this));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0x0));
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), address(this)); // Revoke admin role from deployer on Timelock

        // Governor's internal settings are set via GovernorSettings base constructor.
        // `_setProposalThreshold(0)`: Allows anyone to propose initially. Should be increased by DAO later.
        _setProposalThreshold(0);
    }

    // --- DAO Governance Overrides (from OpenZeppelin Governor) ---
    // These functions allow the DAO to manage the contract itself and other external contracts.
    // They are listed here to fulfill the function count and emphasize their role in DAO control.

    /// @notice Propose a new governance action.
    /// @dev This function is inherited from OpenZeppelin's Governor. Requires enough voting power.
    /// @param targets Target addresses of the calls to be executed.
    /// @param values ETH values to send with each call (can be 0).
    /// @param calldatas Calldata (encoded function calls) for each target.
    /// @param description Human-readable description of the proposal.
    function propose(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, string calldata description) public virtual override(Governor, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    /// @notice Cast a vote on an active proposal.
    /// @dev This function is inherited from OpenZeppelin's Governor.
    /// @param proposalId The unique ID of the proposal.
    /// @param support The vote choice (0: Against, 1: For, 2: Abstain).
    function castVote(uint256 proposalId, uint8 support) public virtual override(Governor, GovernorCountingSimple) returns (uint256) {
        return super.castVote(proposalId, support);
    }

    /// @notice Queue a passed proposal for execution after the timelock delay.
    /// @dev This function is inherited from OpenZeppelin's Governor.
    /// @param targets Target addresses.
    /// @param values ETH values.
    /// @param calldatas Calldata.
    /// @param descriptionHash Keccak256 hash of the proposal description.
    function queue(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bytes32 descriptionHash) public virtual override(Governor, IGovernor) returns (uint256) {
        return super.queue(targets, values, calldatas, descriptionHash);
    }

    /// @notice Execute a queued proposal that has passed its timelock delay.
    /// @dev This function is inherited from OpenZeppelin's Governor.
    /// @param targets Target addresses.
    /// @param values ETH values.
    /// @param calldatas Calldata.
    /// @param descriptionHash Keccak256 hash of the proposal description.
    function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldatas, bytes32 descriptionHash) public payable virtual override(Governor, IGovernor) returns (uint256) {
        return super.execute(targets, values, calldatas, descriptionHash);
    }

    /// @notice Allows the DAO to update the trusted AI oracle address.
    /// @dev This function must be called via a successful DAO governance proposal.
    /// @param _newOracle The new address of the Aether Oracle.
    function setOracleAddress(address _newOracle) public virtual onlyGovernor {
        require(_newOracle != address(0), "ACD: New oracle address cannot be zero");
        emit OracleAddressSet(aetherOracle, _newOracle);
        aetherOracle = _newOracle;
    }

    /// @notice Pauses core contract functionalities in emergencies.
    /// @dev This function must be called via a successful DAO governance proposal.
    function pause() public virtual onlyGovernor {
        _pause();
    }

    /// @notice Unpauses the contract functionalities.
    /// @dev This function must be called via a successful DAO governance proposal.
    function unpause() public virtual onlyGovernor {
        _unpause();
    }

    // --- Prompt Management & AI Generation Workflow ---

    /// @notice Allows users to submit new AI art prompts for community voting.
    /// @dev Each prompt initiates a new voting cycle.
    /// @param _promptText The descriptive text for the AI art generation.
    /// @return The ID of the newly created prompt.
    function proposeAetherPrompt(string calldata _promptText) public whenNotPaused returns (uint256) {
        require(bytes(_promptText).length > 0, "ACD: Prompt text cannot be empty");

        uint256 promptId = nextPromptId++;
        Prompt storage newPrompt = prompts[promptId];
        newPrompt.id = promptId;
        newPrompt.promptText = _promptText;
        newPrompt.proposer = _msgSender();
        newPrompt.proposalTimestamp = block.timestamp;
        newPrompt.votingEndTime = block.timestamp.add(promptVotingPeriod);
        newPrompt.status = PromptStatus.Voting;
        newPrompt.isEvolution = false; // This is an original prompt, not an evolution

        activePromptIds.push(promptId); // Add to a list of currently active prompts

        emit AetherPromptProposed(promptId, _msgSender(), _promptText);
        return promptId;
    }

    /// @notice Allows users to commit their vote for a prompt, as part of a commit-reveal scheme.
    /// @dev This prevents other voters from seeing votes until the reveal phase.
    /// @param _promptId The ID of the prompt to vote on.
    /// @param _commitment A hash of (voter_address, vote_choice, salt) to be revealed later.
    function commitVoteOnPrompt(uint256 _promptId, bytes32 _commitment) public whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Voting, "ACD: Prompt not in voting phase");
        require(block.timestamp <= prompt.votingEndTime, "ACD: Voting period has ended");
        require(prompt.voterCommitments[_msgSender()] == bytes32(0), "ACD: Already committed a vote for this prompt");

        prompt.voterCommitments[_msgSender()] = _commitment;
        emit PromptVoteCommitted(_promptId, _msgSender(), _commitment);
    }

    /// @notice Allows users to reveal their actual vote for a prompt after committing.
    /// @dev Verifies the revealed vote against the stored commitment.
    /// @param _promptId The ID of the prompt.
    /// @param _support True for 'yes' (for prompt approval), False for 'no'.
    /// @param _salt The salt value used during the commitment phase.
    function revealVoteOnPrompt(uint256 _promptId, bool _support, uint256 _salt) public whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Voting, "ACD: Prompt not in voting phase");
        require(block.timestamp <= prompt.votingEndTime, "ACD: Voting period has ended for revealing"); // Must reveal before end
        require(prompt.voterCommitments[_msgSender()] != bytes32(0), "ACD: No vote commitment found for this user");
        require(!prompt.voterRevealed[_msgSender()], "ACD: Vote already revealed for this prompt");

        // Verify the revealed vote against the stored commitment
        bytes32 expectedCommitment = keccak256(abi.encodePacked(_msgSender(), _support, _salt));
        require(prompt.voterCommitments[_msgSender()] == expectedCommitment, "ACD: Commitment mismatch or invalid salt");

        if (_support) {
            prompt.yesVotes = prompt.yesVotes.add(1);
        } else {
            prompt.noVotes = prompt.noVotes.add(1);
        }
        prompt.voterRevealed[_msgSender()] = true;
        
        // Award reputation for participating in voting
        reputationScores[_msgSender()] = reputationScores[_msgSender()].add(ReputationHelper.calculatePromptVoterReputation(true));
        emit ReputationUpdated(_msgSender(), reputationScores[_msgSender()]);

        emit PromptVoteRevealed(_promptId, _msgSender(), _support);
    }

    /// @notice Finalizes the voting period for a prompt.
    /// @dev If the prompt passes, it changes its status to 'Passed' and emits an event for the oracle.
    /// @param _promptId The ID of the prompt to finalize.
    function finalizePromptVoting(uint256 _promptId) public whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Voting, "ACD: Prompt not in voting phase");
        require(block.timestamp > prompt.votingEndTime, "ACD: Voting period not ended yet");

        if (prompt.yesVotes > prompt.noVotes) {
            prompt.status = PromptStatus.Passed;
            // Emit event for off-chain oracle to pick up and generate art
            emit PromptVotingFinalized(_promptId, true, prompt.promptText, prompt.proposer);
        } else {
            prompt.status = PromptStatus.Failed;
            emit PromptVotingFinalized(_promptId, false, prompt.promptText, prompt.proposer);
        }

        // Award reputation to the prompt proposer based on success
        reputationScores[prompt.proposer] = reputationScores[prompt.proposer].add(ReputationHelper.calculatePromptProposerReputation(prompt.status == PromptStatus.Passed));
        emit ReputationUpdated(prompt.proposer, reputationScores[prompt.proposer]);
        
        // Remove from active list (simple iteration, can be optimized for large lists)
        for (uint256 i = 0; i < activePromptIds.length; i++) {
            if (activePromptIds[i] == _promptId) {
                activePromptIds[i] = activePromptIds[activePromptIds.length - 1];
                activePromptIds.pop();
                break;
            }
        }
    }

    /// @notice (Only Oracle) Submits the result of AI art generation. Mints a new NFT or updates an existing one.
    /// @dev This is the crucial bridge for off-chain AI computation results to come on-chain.
    /// @param _promptId The ID of the prompt for which art was generated.
    /// @param _ipfsHash The IPFS hash pointing to the generated artwork.
    /// @param _signature An ECDSA signature by the Aether Oracle, verifying authenticity.
    function submitAetherPromptResult(uint256 _promptId, string calldata _ipfsHash, bytes calldata _signature) public onlyOracle whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Passed || prompt.status == PromptStatus.EvolutionPending, "ACD: Prompt not in correct generation state");
        require(bytes(_ipfsHash).length > 0, "ACD: IPFS hash cannot be empty");

        // Verify oracle signature: The oracle signs a message containing relevant data.
        bytes32 messageHash = keccak256(abi.encodePacked(_promptId, _ipfsHash, address(this)));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        require(ethSignedMessageHash.recover(_signature) == aetherOracle, "ACD: Invalid oracle signature");

        if (prompt.isEvolution) {
            // For an evolution prompt, update the existing NFT's metadata
            uint256 tokenId = prompt.tokenIdLinked;
            require(_exists(tokenId), "ACD: Evolved NFT does not exist");
            aetherArtMetadata[tokenId].ipfsHash = _ipfsHash;
            aetherArtMetadata[tokenId].lastEvolutionPromptId = _promptId;
            prompt.status = PromptStatus.Generated; // Mark prompt as handled
            emit AetherArtEvolutionFinalized(tokenId, _promptId, _ipfsHash);
        } else {
            // For a new prompt, mint a brand new NFT
            uint256 newId = _safeMintForPrompt(prompt.proposer, _promptId, _ipfsHash);
            prompt.status = PromptStatus.Generated;
            prompt.tokenIdLinked = newId; // Link the prompt to the new NFT
            emit AetherArtGenerated(_promptId, newId, _ipfsHash);
        }
        
        // Distribute incentives to the prompt proposer and voters
        distributePromptIncentives(_promptId);
    }

    /// @notice Retrieves comprehensive details about a specific prompt.
    /// @param _promptId The ID of the prompt.
    /// @return Returns all relevant prompt data in a structured format.
    function getPromptDetails(uint256 _promptId)
        public
        view
        returns (
            uint256 id,
            string memory promptText,
            address proposer,
            uint256 proposalTimestamp,
            uint256 votingEndTime,
            PromptStatus status,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 tokenIdLinked,
            bool isEvolution
        )
    {
        Prompt storage prompt = prompts[_promptId];
        return (
            prompt.id,
            prompt.promptText,
            prompt.proposer,
            prompt.proposalTimestamp,
            prompt.votingEndTime,
            prompt.status,
            prompt.yesVotes,
            prompt.noVotes,
            prompt.tokenIdLinked,
            prompt.isEvolution
        );
    }

    // --- Dynamic NFT Management (ERC721 Extension) ---

    /// @dev Internal function to safely mint a new AetherArt NFT.
    /// @param _to The recipient address of the newly minted NFT.
    /// @param _promptId The ID of the prompt that generated this NFT.
    /// @param _ipfsHash The IPFS hash pointing to the generated artwork.
    /// @return The ID of the newly minted NFT.
    function _safeMintForPrompt(address _to, uint256 _promptId, string calldata _ipfsHash) internal returns (uint256) {
        uint256 newTokenId = ERC721.totalSupply(); // Use current totalSupply as the next ID
        _safeMint(_to, newTokenId); // Mints the token to the recipient

        // Store custom metadata for the new NFT
        aetherArtMetadata[newTokenId] = AetherArtMetadata({
            ipfsHash: _ipfsHash,
            promptId: _promptId,
            isFeatured: false, // Not featured by default
            lastEvolutionPromptId: 0 // No evolution yet
        });
        return newTokenId;
    }

    /// @notice Allows an NFT holder to propose a new AI prompt specifically to evolve their existing artwork.
    /// @dev This initiates a new prompt voting cycle, but linked to an existing NFT.
    /// @param _tokenId The ID of the AetherArt NFT to propose an evolution for.
    /// @param _newPromptText The new descriptive text for the AI to generate the evolved art.
    function evolveAetherArtNFT(uint256 _tokenId, string calldata _newPromptText) public whenNotPaused {
        require(_exists(_tokenId), "ACD: NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "ACD: Only NFT owner can propose evolution");
        require(bytes(_newPromptText).length > 0, "ACD: New prompt text cannot be empty");

        uint256 evolvePromptId = nextPromptId++;
        Prompt storage newPrompt = prompts[evolvePromptId];
        newPrompt.id = evolvePromptId;
        newPrompt.promptText = _newPromptText;
        newPrompt.proposer = _msgSender();
        newPrompt.proposalTimestamp = block.timestamp;
        newPrompt.votingEndTime = block.timestamp.add(promptVotingPeriod);
        newPrompt.status = PromptStatus.Voting;
        newPrompt.tokenIdLinked = _tokenId; // Link to the NFT being evolved
        newPrompt.isEvolution = true;

        activePromptIds.push(evolvePromptId); // Add to active list

        emit AetherArtEvolutionProposed(_tokenId, evolvePromptId, _newPromptText);
    }

    /// @notice Finalizes voting for an NFT evolution prompt.
    /// @dev If the evolution prompt passes, it sets the status to `EvolutionPending` for the oracle.
    /// @param _evolvePromptId The ID of the evolution prompt.
    function finalizeEvolutionVoting(uint256 _evolvePromptId) public whenNotPaused {
        Prompt storage prompt = prompts[_evolvePromptId];
        require(prompt.isEvolution, "ACD: Not an evolution prompt");
        require(prompt.status == PromptStatus.Voting, "ACD: Evolution prompt not in voting phase");
        require(block.timestamp > prompt.votingEndTime, "ACD: Voting period not ended yet");

        if (prompt.yesVotes > prompt.noVotes) {
            prompt.status = PromptStatus.EvolutionPending; // Ready for oracle to generate new art for this NFT
            // Emit event for off-chain oracle to pick up and generate new art
            emit PromptVotingFinalized(_evolvePromptId, true, prompt.promptText, prompt.proposer);
        } else {
            prompt.status = PromptStatus.Failed;
            emit PromptVotingFinalized(_evolvePromptId, false, prompt.promptText, prompt.proposer);
        }

        // Award reputation to the evolution proposer
        reputationScores[prompt.proposer] = reputationScores[prompt.proposer].add(ReputationHelper.calculatePromptProposerReputation(prompt.status == PromptStatus.EvolutionPending));
        emit ReputationUpdated(prompt.proposer, reputationScores[prompt.proposer]);
    }

    /// @dev Allows the DAO to update an NFT's URI (IPFS hash).
    /// @dev This function is primarily used internally after an NFT evolution by a DAO proposal.
    /// @param _tokenId The ID of the NFT.
    /// @param _newUri The new IPFS hash / URI pointing to the updated artwork.
    function setTokenURI(uint256 _tokenId, string calldata _newUri) public virtual onlyGovernor {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        aetherArtMetadata[_tokenId].ipfsHash = _newUri;
    }

    /// @notice Overrides ERC721 `tokenURI` to return the current URI for a given NFT, including dynamic evolution data.
    /// @param _tokenId The ID of the NFT.
    /// @return The URI (IPFS hash) of the NFT.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return aetherArtMetadata[_tokenId].ipfsHash;
    }

    // --- Staking & Incentives ---

    /// @notice Allows an AetherArt NFT owner to stake their NFT.
    /// @dev Staking transfers the NFT to the contract and earns the staker reputation and potential future rewards.
    /// @param _tokenId The ID of the AetherArt NFT to stake.
    function stakeAetherNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ACD: NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "ACD: Only NFT owner can stake");
        require(!stakedNFTs[_tokenId].isStaked, "ACD: NFT already staked");

        // Transfer NFT from owner to this contract (the staking pool)
        _transfer(_msgSender(), address(this), _tokenId);

        stakedNFTs[_tokenId] = StakedNFTInfo({
            staker: _msgSender(),
            stakeTimestamp: block.timestamp,
            isStaked: true
        });

        // Award initial reputation for staking
        reputationScores[_msgSender()] = reputationScores[_msgSender()].add(10); // Base 10 reputation
        emit ReputationUpdated(_msgSender(), reputationScores[_msgSender()]);
        emit NFTStaked(_tokenId, _msgSender());
    }

    /// @notice Allows an owner to unstake their AetherArt NFT.
    /// @dev Unstaking transfers the NFT back to the original staker.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeAetherNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ACD: NFT does not exist");
        require(stakedNFTs[_tokenId].isStaked, "ACD: NFT not staked");
        require(stakedNFTs[_tokenId].staker == _msgSender(), "ACD: Only original staker can unstake");

        // Calculate and add reputation boost based on staking duration
        uint256 duration = block.timestamp.sub(stakedNFTs[_tokenId].stakeTimestamp);
        reputationScores[_msgSender()] = reputationScores[_msgSender()].add(ReputationHelper.calculateStakingReputationBoost(duration, reputationBoostPeriod));
        emit ReputationUpdated(_msgSender(), reputationScores[_msgSender()]);

        // Transfer NFT from this contract back to the staker
        _transfer(address(this), _msgSender(), _tokenId);

        delete stakedNFTs[_tokenId]; // Clear staking information
        emit NFTUnstaked(_tokenId, _msgSender());
    }

    /// @notice Allows staked NFT holders to claim their accrued rewards.
    /// @dev This is a simplified placeholder. A full implementation would involve complex reward calculation based on tokenomics.
    function claimStakingRewards() public whenNotPaused {
        // Placeholder for reward calculation.
        // In a real system, `claimableAmount` would be calculated based on:
        // - User's staked NFTs and their stake duration.
        // - A reward rate from the treasury or newly minted tokens.
        // - Might involve iterating through user's staked NFTs or a checkpointing system.
        uint256 claimableAmount = 0; // Replace with actual calculation logic.

        // Example: Transfer a symbolic amount of the governance token as reward
        // require(claimableAmount > 0, "ACD: No rewards to claim");
        // require(governanceToken.transfer(_msgSender(), claimableAmount), "ACD: Reward token transfer failed");
        
        // For this demonstration, we'll only update reputation as a symbolic reward.
        reputationScores[_msgSender()] = reputationScores[_msgSender()].add(20); // Symbolic reputation boost for claiming
        emit ReputationUpdated(_msgSender(), reputationScores[_msgSender()]);
        emit StakingRewardsClaimed(_msgSender(), claimableAmount);
    }

    /// @dev Distributes a portion of the treasury to the original prompt proposer and potentially voters of a successfully generated prompt.
    /// @param _promptId The ID of the prompt for which incentives are distributed.
    function distributePromptIncentives(uint256 _promptId) internal {
        Prompt storage prompt = prompts[_promptId];
        
        // Example incentive allocation: 0.5 ETH to proposer
        uint256 proposerShare = 0.5 ether; 

        // Transfer proposer's share from the contract's treasury
        if (address(this).balance >= proposerShare) {
            (bool success, ) = prompt.proposer.call{value: proposerShare}("");
            require(success, "ACD: Proposer incentive ETH transfer failed");
        }

        // Voter incentives are generally more complex due to iteration over mappings.
        // For a simple on-chain model, might give a fixed reward per successful vote revealed.
        // For a more robust solution, voter incentives could be a separate claim function
        // or a vesting contract that distributes a share of generated art sales/royalties.
        
        emit PromptIncentivesDistributed(_promptId, proposerShare);
    }

    // --- Reputation System ---

    /// @notice Returns the accumulated reputation score for a given user.
    /// @param _user The address of the user.
    /// @return The current reputation score of the user.
    function getReputation(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    // --- Treasury & Fee Management ---

    /// @notice Allows anyone to contribute funds (ETH) to the DAO's treasury.
    /// @dev All received ETH via this function or the fallback `receive()` function goes to the treasury.
    function depositToTreasury() public payable whenNotPaused {
        require(msg.value > 0, "ACD: Deposit amount must be greater than zero");
        emit DepositToTreasury(_msgSender(), msg.value);
    }

    /// @notice Allows the DAO to transfer funds from the treasury.
    /// @dev This function must be called via a successful DAO governance proposal.
    /// @param _to The recipient address of the funds.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawFromTreasury(address _to, uint256 _amount) public virtual onlyGovernor {
        require(_amount > 0, "ACD: Withdrawal amount must be greater than zero");
        require(address(this).balance >= _amount, "ACD: Insufficient treasury balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "ACD: ETH withdrawal failed");
        emit WithdrawalFromTreasury(_to, _amount);
    }

    /// @dev Fallback function to receive ETH. Calls `depositToTreasury`.
    receive() external payable {
        depositToTreasury();
    }

    // --- Curation Market ---

    /// @notice Allows an AetherArt NFT owner to submit their NFT for community review to be featured.
    /// @param _tokenId The ID of the AetherArt NFT to submit for curation.
    function submitForCuration(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ACD: NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "ACD: Only NFT owner can submit for curation");
        // Could add logic here to prevent re-submission if already featured or under vote.

        uint256 curationId = nextCurationId++;
        Curation storage newCuration = curations[curationId];
        newCuration.id = curationId;
        newCuration.tokenId = _tokenId;
        newCuration.submitter = _msgSender();
        newCuration.proposalTimestamp = block.timestamp;
        newCuration.votingEndTime = block.timestamp.add(curationVotingPeriod);
        newCuration.status = CurationStatus.Voting;

        emit CurationSubmitted(curationId, _tokenId, _msgSender());
    }

    /// @notice Community members vote on whether a submitted NFT should be featured.
    /// @param _curationId The ID of the curation proposal.
    /// @param _isFeatured True to vote for featuring, False against.
    function voteOnCuration(uint256 _curationId, bool _isFeatured) public whenNotPaused {
        Curation storage curation = curations[_curationId];
        require(curation.status == CurationStatus.Voting, "ACD: Curation not in voting phase");
        require(block.timestamp <= curation.votingEndTime, "ACD: Curation voting period has ended");
        require(!curation.voted[_msgSender()], "ACD: Already voted on this curation");

        if (_isFeatured) {
            curation.yesVotes = curation.yesVotes.add(1);
        } else {
            curation.noVotes = curation.noVotes.add(1);
        }
        curation.voted[_msgSender()] = true;
        
        reputationScores[_msgSender()] = reputationScores[_msgSender()].add(ReputationHelper.calculateCurationReputation(true));
        emit ReputationUpdated(_msgSender(), reputationScores[_msgSender()]);
        emit CurationVoteCast(_curationId, _msgSender(), _isFeatured);
    }

    /// @notice Finalizes the curation vote, updating the NFT's featured status if successful.
    /// @param _curationId The ID of the curation proposal.
    function finalizeCurationVote(uint256 _curationId) public whenNotPaused {
        Curation storage curation = curations[_curationId];
        require(curation.status == CurationStatus.Voting, "ACD: Curation not in voting phase");
        require(block.timestamp > curation.votingEndTime, "ACD: Curation voting period not ended yet");

        if (curation.yesVotes > curation.noVotes) {
            curation.status = CurationStatus.Featured;
            aetherArtMetadata[curation.tokenId].isFeatured = true;
            featuredArtTokenIds.push(curation.tokenId); // Add to dynamic list of featured NFTs
        } else {
            curation.status = CurationStatus.NotFeatured;
            aetherArtMetadata[curation.tokenId].isFeatured = false; // Ensure it's not featured
            // If it was previously featured and failed a re-vote, it should be removed from featuredArtTokenIds.
            // For simplicity, current implementation does not remove from array on un-feature, needs more complex array management.
        }
        emit CurationVotingFinalized(_curationId, curation.tokenId, aetherArtMetadata[curation.tokenId].isFeatured);
    }

    /// @notice Returns a list of AetherArt NFTs currently featured by the community.
    /// @return An array of token IDs that are currently marked as featured.
    function getFeaturedArt() public view returns (uint256[] memory) {
        return featuredArtTokenIds;
    }

    // --- Internal/Utility Overrides for OpenZeppelin Governor and ERC721Enumerable ---
    // These functions are required overrides for the inherited OpenZeppelin contracts.

    // Governor internal function to check if quorum is reached for a proposal.
    function _quorumReached(uint256 proposalId) internal view override(Governor, GovernorCountingSimple) returns (bool) {
        return super._quorumReached(proposalId);
    }

    // Governor internal function to check if a vote has succeeded for a proposal.
    function _voteSucceeded(uint256 proposalId) internal view override(Governor, GovernorCountingSimple) returns (bool) {
        return super._voteSucceeded(proposalId);
    }

    // Governor internal function to cast a vote and record voting power.
    function _castVote(uint256 proposalId, address voter, uint8 support, string calldata reason) internal virtual override(Governor, GovernorCountingSimple) returns (uint256) {
        return super._castVote(proposalId, voter, support, reason);
    }

    // Governor internal function for relaying calls through the TimelockController.
    // This is how the DAO executes approved proposals. No custom logic needed here as Governor handles it.
    function _relay(address target, uint256 value, bytes calldata data) internal virtual override(Governor, IGovernor) {
        // Calls executed by Governor are handled via its TimelockController.
        // This function is for scenarios where the Governor *itself* needs to perform a relay,
        // typically if it were acting as an intermediate layer or owning other contracts.
        // For this contract, the Governor is effectively the direct controller via the Timelock.
    }

    // Required override for ERC721Enumerable to correctly handle token transfers.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Required override for ERC721Enumerable for ERC165 interface detection.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// A simple ERC20 token for demonstration purposes, to be used as the governance token (Aether Canvas Token).
contract AetherToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Aether Canvas Token", "ACT") {
        _mint(msg.sender, initialSupply); // Mints initial supply to the deployer
    }

    /// @notice Allows the owner to mint new tokens and send them to an address.
    /// @dev In a production DAO, minting would typically be controlled by the DAO itself.
    /// @param to The recipient of the new tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

```