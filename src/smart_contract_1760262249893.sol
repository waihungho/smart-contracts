Okay, this is an ambitious and exciting challenge! I've designed a smart contract called `AetherCanvas` that aims to integrate several advanced and trendy concepts:

*   **Generative AI Artwork Curation:** A decentralized process for proposing and approving AI-generated art, making it truly community-driven.
*   **Dynamic NFTs (dNFTs):** Artworks that can evolve or be regenerated based on governance decisions or oracle inputs, adding a living element to digital art.
*   **Zero-Knowledge Proof (ZKP) Enhanced Governance:** Allowing for private or conditional voting where certain aspects of a vote (e.g., specific conditions met off-chain) can be proven without revealing the underlying data.
*   **Reputation System:** Curators and proposers earn reputation for positive contributions, which influences their voting power.
*   **Delegated Voting:** Participants can delegate their voting power to trusted curators.
*   **Oracle Integration:** A trusted oracle can push verified off-chain data (like new AI outputs) to update NFTs.
*   **Decentralized Treasury:** For funding AI generation, rewarding contributors, and managing contract parameters.

The contract provides a robust framework, focusing on the unique logic and interactions. For production-grade quality, integration with a battle-tested ERC721 library (like OpenZeppelin's) and a specific ZKP verifier contract (e.g., for Groth16 or PLONK) would be essential.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // For contract ownership and admin controls
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // ERC721 Token Standard Interface
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol"; // ERC721 Metadata Extension Interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // ERC20 Token Standard Interface for withdrawals

// --- Outline and Function Summary ---
// Contract Name: AetherCanvas
// Core Idea: A decentralized protocol for curating, funding, and dynamically evolving AI-generated artworks as NFTs, 
//            governed by a community using both direct and Zero-Knowledge Proof (ZKP) based voting mechanisms, 
//            and incorporating a reputation system.
//
// Key Features:
// 1. AI Artwork Proposals: Users stake tokens to propose prompts for AI generation and submit resulting artworks.
// 2. Dynamic NFTs (dNFTs): Artworks (NFTs) can have their metadata (and thus appearance) updated based on successful
//    regeneration proposals or verified oracle data, making them "living" pieces.
// 3. ZKP-Enhanced Governance: Enables private or conditional voting for certain proposals by verifying Zero-Knowledge Proofs
//    on-chain, without revealing sensitive voter data or conditions.
// 4. Curator Reputation System: Rewards active and effective curators with reputation points, which amplify their voting power.
// 5. Decentralized Treasury: Manages collected funds (ETH) to pay for AI generation, reward contributors, and fund ecosystem growth.
// 6. Oracle Integration: Allows a trusted off-chain oracle to submit verified data, crucial for dynamic NFT updates and ZKP contexts.
// 7. Delegated Voting: Stakers can delegate their voting power to another address, promoting expert-based governance.
//
// Functions (32 total):
//
// I. Core NFT Management (Implements IERC721 functionally, focusing on AetherCanvas's specific usage)
//    1.  name(): Returns the name of the NFT collection.
//    2.  symbol(): Returns the symbol of the NFT collection.
//    3.  balanceOf(address owner): Returns the number of NFTs owned by an address.
//    4.  ownerOf(uint256 artworkId): Returns the owner of an NFT.
//    5.  tokenURI(uint256 artworkId): Returns the metadata URI for an NFT, supporting dynamic updates.
//    6.  getApproved(uint256 artworkId): Returns the approved address for an NFT.
//    7.  isApprovedForAll(address owner, address operator): Checks if an operator is approved for all NFTs of an owner.
//    8.  mintArtwork(address to, uint256 artworkId, string calldata initialURI, bytes32 promptHash, uint256 promptProposalId): Mints a new artwork NFT after DAO approval.
//    9.  updateArtworkURI(uint256 artworkId, string calldata newURI): Allows the DAO or oracle to update an NFT's metadata URI, enabling dynamic NFTs.
//    10. transferFrom(address from, address to, uint256 artworkId): Standard ERC721 transfer.
//    11. approve(address to, uint256 artworkId): Standard ERC721 approval.
//    12. setApprovalForAll(address operator, bool approved): Standard ERC721 operator approval.
//    13. getArtworkDetails(uint256 artworkId): View function to retrieve all stored artwork details.
//    14. burnArtwork(uint256 artworkId): Allows an artwork to be burned (e.g., if deemed inappropriate by DAO or owner).
//
// II. AI Prompt & Generation Management
//    15. proposePrompt(string calldata promptText, bytes32 expectedOutputHash): Users propose a prompt for AI generation, staking tokens.
//    16. submitAIArtwork(uint256 promptProposalId, string calldata finalURI, bytes32 actualOutputHash): A proposer submits the generated artwork (URI and hash) for curation.
//    17. requestAIReGeneration(uint256 artworkId, string calldata newPromptText): Initiates a DAO proposal to regenerate an existing artwork with a new prompt.
//
// III. Curation & Approval (DAO Governance)
//    18. castArtworkVote(uint256 promptProposalId, bool approve): Curators vote on approving a submitted artwork or regeneration request. Voting power is dynamic.
//    19. finalizeArtworkProposal(uint256 promptProposalId): Finalizes voting for an artwork, minting if approved, and manages stakes/reputation.
//    20. proposeSystemParameterChange(bytes32 parameterKey, bytes calldata newValueEncoded): Proposes changes to core contract parameters.
//    21. castParameterVote(uint256 paramProposalId, bool approve): Votes on system parameter changes.
//    22. delegateVote(address delegatee): Delegates voting power to another address.
//
// IV. ZKP-Enhanced Governance
//    23. submitZKPVote(uint256 proposalId, bytes calldata proof, bytes calldata publicInputs): Submits a Zero-Knowledge Proof for a conditional/private vote.
//    24. tallyZKPVote(uint256 proposalId, bytes calldata auxiliaryData): Owner/DAO-privileged function to trigger ZKP vote tallying.
//    25. setZKPVerifierAddress(address verifierAddress): Sets the address of the trusted ZKP verifier contract.
//
// V. Reputation & Staking
//    26. stakeTokens(uint256 amount): Users stake ETH to gain voting power and participate as curators.
//    27. unstakeTokens(uint256 amount): Allows users to unstake after a cooldown period, revoking delegation if applicable.
//    28. getCuratorReputation(address curator): View function to get a curator's current reputation score.
//    29. updateCuratorReputation(address curator, int256 changeAmount): Privileged/DAO-controlled function to adjust reputation.
//
// VI. Treasury & Funding
//    30. fundTreasury(): Allows anyone to send ETH to the contract treasury.
//    31. proposeTreasuryWithdrawal(address recipient, uint256 amount, string calldata description): DAO proposal to withdraw funds.
//    32. executeTreasuryWithdrawal(uint256 withdrawalProposalId): Executes a DAO-approved withdrawal.
//
// VII. Oracle Integration
//    33. setOracleAddress(address _oracleAddress): Sets the address of the trusted oracle.
//    34. submitOracleData(uint256 artworkId, string calldata newURI, bytes32 newOutputHash): An oracle submits verified data, potentially triggering NFT updates.
//
// VIII. System Configuration & Safety
//    35. pauseContract(): Pauses sensitive functions in emergency (Owner-controlled).
//    36. unpauseContract(): Unpauses the contract.
//    37. setVotingPeriod(uint256 newPeriod): Updates the duration for all general voting periods (Owner-controlled for simplicity).
//    38. withdrawERC20Tokens(address tokenAddress, uint256 amount): Emergency withdrawal for accidentally sent ERC20s (owner only).
//
// Total functions: 38 (Exceeds 20 requirement)
//
// Note: For a real-world scenario, you would integrate a robust ZKP verifier contract (e.g., PLONK, Groth16)
//       that adheres to the `IZKPVerifier` interface. The `stakeTokens` currently accepts ETH, but could be
//       modified to accept a custom ERC20 token. The `Ownable` modifier is used for core admin settings,
//       but a full DAO would route most of these functions through governance proposals.

// Interface for a hypothetical ZKP Verifier contract
interface IZKPVerifier {
    function verifyProof(bytes calldata proof, bytes32[] calldata publicInputs) external view returns (bool);
}

contract AetherCanvas is Ownable, IERC721, IERC721Metadata {
    // --- State Variables ---

    // ERC721 Specifics
    string private _name;
    string private _symbol;
    uint256 private _nextTokenId; // Counter for next available artwork ID
    mapping(uint256 => address) private _owners; // artworkId => owner address
    mapping(address => uint256) private _balances; // owner address => NFT count
    mapping(uint256 => address) private _tokenApprovals; // artworkId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved status
    mapping(uint256 => string) private _tokenURIs; // artworkId => current metadata URI (for dynamic NFTs)

    // Artwork & Prompt Management
    struct Artwork {
        address creator;
        bytes32 promptHash; // Hash of the initial prompt text
        string currentURI;  // Current metadata URI
        uint256 promptProposalId; // Link to the original prompt proposal that generated it
        bool isActive;      // True if the artwork is active and not burned/deactivated
        uint256 generationTimestamp; // Timestamp of NFT minting
    }
    mapping(uint256 => Artwork) private _artworks; // artworkId => Artwork details

    struct PromptProposal {
        address proposer;
        string promptText;
        bytes32 expectedOutputHash; // Hash provided by the proposer (pre-submission)
        bytes32 actualOutputHash;   // Hash of the submitted artwork (post-submission)
        string finalURI;            // URI of the submitted artwork (post-submission)
        uint256 stakeAmount;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yeas; // Total voting power for approval
        uint256 nays; // Total voting power for rejection
        bool submitted; // True if artwork has been submitted for this prompt
        bool finalized; // True if voting has concluded and outcome processed
        bool approved;  // True if the artwork was approved by the DAO
        mapping(address => bool) hasVoted; // effectiveVoter => true if voted
    }
    mapping(uint256 => PromptProposal) private _promptProposals;
    uint256 private _nextPromptProposalId; // Counter for next prompt proposal ID

    // DAO Governance (for system parameters)
    struct GovernanceProposal {
        bytes32 parameterKey; // A unique identifier for the parameter (e.g., keccak256("PROMPT_VOTING_PERIOD"))
        bytes newValueEncoded; // The new value for the parameter, ABI-encoded
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yeas;
        uint256 nays;
        bool finalized;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    mapping(uint256 => GovernanceProposal) private _governanceProposals;
    uint256 private _nextGovernanceProposalId;

    // Treasury Governance
    struct TreasuryWithdrawalProposal {
        address proposer; // The address that proposed the withdrawal
        address recipient;
        uint256 amount;
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yeas;
        uint256 nays;
        bool finalized;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    mapping(uint256 => TreasuryWithdrawalProposal) private _treasuryProposals;
    uint256 private _nextTreasuryProposalId;

    // ZKP Governance
    address public zkpVerifierAddress; // Address of the external ZKP verifier contract
    mapping(uint256 => mapping(address => bool)) private _hasZKPVoted; // proposalId => effectiveVoter => true if voted with ZKP
    mapping(uint256 => uint256) private _zkpYeas; // proposalId => total ZKP voting power for 'yes'
    mapping(uint256 => uint256) private _zkpNays; // proposalId => total ZKP voting power for 'no'

    // Reputation & Staking
    struct Curator {
        uint256 stakedTokens; // Amount of ETH staked by the curator
        uint256 reputationScore; // Reputation points earned
        uint256 unstakeCooldownEndTime; // Timestamp when unstaking becomes possible
        address delegatedTo; // The address to which this curator's voting power is delegated
    }
    mapping(address => Curator) private _curators; // address => Curator details

    mapping(address => uint256) private _delegatedVotingPower; // delegatee address => total voting power delegated to them

    // Oracle Integration
    address public oracleAddress; // Trusted oracle address

    // System Parameters (set by owner, ideally updated by governance proposals)
    uint256 public constant MIN_STAKE_FOR_PROPOSAL = 0.1 ether; // Minimum ETH stake to create a proposal
    uint256 public promptProposalVotingPeriod = 3 days; // Duration for artwork/regeneration voting
    uint256 public governanceVotingPeriod = 5 days;    // Duration for system parameter voting
    uint256 public treasuryVotingPeriod = 5 days;      // Duration for treasury withdrawal voting
    uint256 public unstakeCooldownPeriod = 7 days;     // Cooldown period after unstaking before funds can be withdrawn

    // Pausability
    bool public paused; // True if the contract is paused, preventing critical operations

    // --- Events ---
    event NFTMinted(address indexed to, uint256 indexed artworkId, string uri, bytes32 promptHash);
    event NFTURIUpdated(uint256 indexed artworkId, string newURI);
    event Transfer(address indexed from, address indexed to, uint256 indexed artworkId); // ERC721
    event Approval(address indexed owner, address indexed approved, uint256 indexed artworkId); // ERC721
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // ERC721

    event PromptProposed(uint256 indexed proposalId, address indexed proposer, bytes32 expectedOutputHash);
    event ArtworkSubmitted(uint256 indexed proposalId, address indexed submitter, string finalURI, bytes32 actualOutputHash);
    event ArtworkProposedForReGeneration(uint256 indexed artworkId, address indexed proposer, string newPromptText);

    event ArtworkVoteCast(uint256 indexed proposalId, address indexed effectiveVoter, bool approve);
    event ArtworkProposalFinalized(uint256 indexed proposalId, bool approved, uint256 artworkId);

    event GovernanceProposalCreated(uint256 indexed proposalId, bytes32 parameterKey, bytes newValue);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed effectiveVoter, bool approve);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bytes32 parameterKey, bytes newValue);

    event ZKPVoteCast(uint256 indexed proposalId, address indexed effectiveVoter, bytes32 proofHash);
    event ZKPVoteTallied(uint256 indexed proposalId, uint256 yeas, uint256 nays);

    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed staker, uint256 amount);
    event ReputationUpdated(address indexed curator, int256 changeAmount, uint256 newReputation);
    event VoteDelegated(address indexed delegator, address indexed delegatee);

    event TreasuryFunded(address indexed funder, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 indexed proposalId, address indexed proposer, address indexed recipient, uint256 amount);
    event TreasuryWithdrawalExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetherCanvas: Only oracle can call this function");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) {
        _name = name_;
        _symbol = symbol_;
        _nextTokenId = 1;
        _nextPromptProposalId = 1;
        _nextGovernanceProposalId = 1;
        _nextTreasuryProposalId = 1;
        paused = false; // Contract starts unpaused
    }

    // --- ERC721 View Functions (I. Core NFT Management - part 1) ---

    /// @notice Returns the name of the NFT collection.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the NFT collection.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @dev Checks if an artwork with the given ID exists.
    function _exists(uint256 artworkId) internal view returns (bool) {
        return _owners[artworkId] != address(0);
    }

    /// @notice Returns the number of NFTs owned by `owner`.
    /// @param owner The address to query the balance of.
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /// @notice Returns the owner of the NFT specified by `artworkId`.
    /// @param artworkId The identifier for an NFT.
    function ownerOf(uint256 artworkId) public view virtual override returns (address) {
        address owner = _owners[artworkId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /// @notice Returns the metadata URI for the NFT specified by `artworkId`.
    /// @param artworkId The identifier for an NFT.
    function tokenURI(uint256 artworkId) public view virtual override returns (string memory) {
        require(_exists(artworkId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[artworkId];
    }

    /// @notice Get the approved address for an NFT.
    /// @param artworkId The NFT to find the approved address for.
    /// @return The approved address for the given NFT, or the zero address if no address is approved.
    function getApproved(uint256 artworkId) public view virtual override returns (address) {
        require(_exists(artworkId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[artworkId];
    }

    /// @notice Query if an address is an authorized operator for another address.
    /// @param owner The address that owns the NFTs.
    /// @param operator The address that acts on behalf of the owner.
    /// @return True if `operator` is an approved operator for `owner`, false otherwise.
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --- Internal ERC721 Logic ---

    /// @dev Internal mint function, used by `mintArtwork` after DAO approval.
    function _mint(address to, uint256 artworkId, string memory initialURI, bytes32 promptHash, uint256 promptProposalId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(artworkId), "ERC721: token already minted");

        _balances[to]++;
        _owners[artworkId] = to;
        _tokenURIs[artworkId] = initialURI;

        _artworks[artworkId] = Artwork({
            creator: to,
            promptHash: promptHash,
            currentURI: initialURI,
            promptProposalId: promptProposalId,
            isActive: true,
            generationTimestamp: block.timestamp
        });

        emit NFTMinted(to, artworkId, initialURI, promptHash);
        emit Transfer(address(0), to, artworkId); // ERC721 compliance: mint is transfer from zero address
    }

    /// @dev Internal transfer function.
    function _transfer(address from, address to, uint256 artworkId) internal {
        require(ownerOf(artworkId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), artworkId); // Clear approvals
        _balances[from]--;
        _balances[to]++;
        _owners[artworkId] = to;

        emit Transfer(from, to, artworkId);
    }

    /// @dev Internal approve function.
    function _approve(address to, uint256 artworkId) internal {
        _tokenApprovals[artworkId] = to;
        emit Approval(ownerOf(artworkId), to, artworkId);
    }

    /// @dev Checks if `spender` is approved or is the owner of `artworkId`.
    function _isApprovedOrOwner(address spender, uint256 artworkId) internal view returns (bool) {
        address owner_ = ownerOf(artworkId);
        return (spender == owner_ || getApproved(artworkId) == spender || isApprovedForAll(owner_, spender));
    }

    // --- I. Core NFT Management (part 2) ---

    /// @notice Mints a new artwork NFT after DAO approval.
    /// This function is primarily called internally by `finalizeArtworkProposal` once a prompt has been approved.
    /// @param to The address to mint the NFT to.
    /// @param artworkId The ID of the artwork.
    /// @param initialURI The initial metadata URI of the artwork.
    /// @param promptHash The hash of the prompt that generated this artwork.
    /// @param promptProposalId The ID of the prompt proposal that led to this mint.
    function mintArtwork(address to, uint256 artworkId, string calldata initialURI, bytes32 promptHash, uint256 promptProposalId) 
        public virtual whenNotPaused {
        // Only the contract itself (via a successful DAO proposal) or the owner can initiate minting.
        require(msg.sender == address(this) || msg.sender == owner(), "AetherCanvas: Not authorized to mint directly");
        _mint(to, artworkId, initialURI, promptHash, promptProposalId);
    }

    /// @notice Allows the DAO or oracle to update an NFT's metadata URI, enabling dynamic NFTs.
    /// @param artworkId The ID of the artwork to update.
    /// @param newURI The new metadata URI.
    function updateArtworkURI(uint256 artworkId, string calldata newURI) public virtual whenNotPaused {
        require(_exists(artworkId), "AetherCanvas: Artwork does not exist");
        // Only the artwork owner, an approved operator, the contract itself (via DAO action), or the oracle can update URI.
        require(msg.sender == ownerOf(artworkId) || _isApprovedOrOwner(msg.sender, artworkId) || msg.sender == address(this) || msg.sender == oracleAddress, "AetherCanvas: Not authorized to update URI");
        
        _tokenURIs[artworkId] = newURI;
        _artworks[artworkId].currentURI = newURI;
        emit NFTURIUpdated(artworkId, newURI);
    }

    /// @notice Standard ERC721 transfer function.
    /// @param from The address of the current owner.
    /// @param to The address of the new owner.
    /// @param artworkId The ID of the artwork to transfer.
    function transferFrom(address from, address to, uint256 artworkId) public virtual override whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, artworkId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, artworkId);
    }

    /// @notice Standard ERC721 approval function.
    /// @param to The address to be granted approval.
    /// @param artworkId The NFT to be approved.
    function approve(address to, uint256 artworkId) public virtual override whenNotPaused {
        address owner_ = ownerOf(artworkId);
        require(to != owner_, "ERC721: approval to current owner");
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[artworkId] = to;
        emit Approval(owner_, to, artworkId);
    }

    /// @notice Standard ERC721 operator approval function.
    /// @param operator The address to be granted/revoked approval for all tokens.
    /// @param approved True to approve, false to revoke.
    function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice View function to retrieve all stored artwork details.
    /// @param artworkId The ID of the artwork.
    /// @return An `Artwork` struct containing creator, prompt hash, current URI, prompt proposal ID, active status, and generation timestamp.
    function getArtworkDetails(uint256 artworkId) public view returns (Artwork memory) {
        require(_exists(artworkId), "AetherCanvas: Artwork does not exist");
        return _artworks[artworkId];
    }

    /// @notice Allows an artwork to be burned (e.g., if deemed inappropriate by DAO or owner).
    /// @param artworkId The ID of the artwork to burn.
    function burnArtwork(uint256 artworkId) public whenNotPaused {
        require(_exists(artworkId), "AetherCanvas: Artwork does not exist");
        // For simplicity, only owner or contract owner can burn. In a full DAO, this would be a proposal.
        require(msg.sender == owner() || msg.sender == ownerOf(artworkId), "AetherCanvas: Not authorized to burn artwork");

        address tokenOwner = ownerOf(artworkId);
        _approve(address(0), artworkId); // Clear approvals
        
        _balances[tokenOwner]--;
        delete _owners[artworkId];
        delete _tokenURIs[artworkId];
        _artworks[artworkId].isActive = false; // Mark as inactive

        emit Transfer(tokenOwner, address(0), artworkId); // ERC721 compliance: burn is transfer to zero address
    }

    // --- II. AI Prompt & Generation Management ---

    /// @notice Users propose a prompt for AI generation, staking tokens (ETH).
    /// The stake is held until the artwork is finalized (approved or rejected).
    /// @param promptText The text of the AI prompt.
    /// @param expectedOutputHash A cryptographic hash of the expected AI output, provided by the proposer for later verification.
    function proposePrompt(string calldata promptText, bytes32 expectedOutputHash) public payable whenNotPaused {
        require(msg.value >= MIN_STAKE_FOR_PROPOSAL, "AetherCanvas: Insufficient stake for proposal");
        
        // Stake the value directly from msg.value
        _curators[msg.sender].stakedTokens += msg.value; 
        
        uint256 proposalId = _nextPromptProposalId++;
        _promptProposals[proposalId] = PromptProposal({
            proposer: msg.sender,
            promptText: promptText,
            expectedOutputHash: expectedOutputHash,
            actualOutputHash: bytes32(0),
            finalURI: "",
            stakeAmount: msg.value,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + promptProposalVotingPeriod,
            yeas: 0,
            nays: 0,
            submitted: false,
            finalized: false,
            approved: false,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit PromptProposed(proposalId, msg.sender, expectedOutputHash);
        emit TokensStaked(msg.sender, msg.value);
    }

    /// @notice A proposer submits the actual AI-generated artwork (URI and hash) for curation after proposing a prompt.
    /// This makes the artwork eligible for community voting.
    /// @param promptProposalId The ID of the prompt proposal.
    /// @param finalURI The metadata URI of the generated artwork.
    /// @param actualOutputHash The actual cryptographic hash of the AI-generated output.
    function submitAIArtwork(uint256 promptProposalId, string calldata finalURI, bytes32 actualOutputHash) public whenNotPaused {
        PromptProposal storage proposal = _promptProposals[promptProposalId];
        require(proposal.proposer == msg.sender, "AetherCanvas: Only original proposer can submit artwork");
        require(!proposal.submitted, "AetherCanvas: Artwork already submitted for this proposal");
        require(proposal.creationTime + promptProposalVotingPeriod > block.timestamp, "AetherCanvas: Prompt voting period has ended. Cannot submit artwork for an expired proposal.");
        
        proposal.finalURI = finalURI;
        proposal.actualOutputHash = actualOutputHash;
        proposal.submitted = true;

        // In a more robust system, `actualOutputHash` might be verified against `expectedOutputHash` here,
        // possibly with oracle assistance for complex AI outputs. For simplicity, we store it.

        emit ArtworkSubmitted(promptProposalId, msg.sender, finalURI, actualOutputHash);
    }

    /// @notice Initiates a DAO proposal to regenerate an existing artwork with a new prompt.
    /// This adds a dynamic element to NFTs, allowing them to evolve.
    /// @param artworkId The ID of the artwork to regenerate.
    /// @param newPromptText The new prompt text to use for regeneration.
    function requestAIReGeneration(uint256 artworkId, string calldata newPromptText) public payable whenNotPaused {
        require(_exists(artworkId), "AetherCanvas: Artwork does not exist");
        require(msg.value >= MIN_STAKE_FOR_PROPOSAL, "AetherCanvas: Insufficient stake for regeneration proposal");

        _curators[msg.sender].stakedTokens += msg.value; // Stake for the proposal

        uint256 proposalId = _nextPromptProposalId++; // Uses the same proposal struct type
        _promptProposals[proposalId] = PromptProposal({
            proposer: msg.sender,
            promptText: newPromptText,
            expectedOutputHash: bytes32(0), // Not directly applicable for regeneration request; new hash comes via oracle if approved
            actualOutputHash: bytes32(0),
            finalURI: "",
            stakeAmount: msg.value,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + promptProposalVotingPeriod,
            yeas: 0,
            nays: 0,
            submitted: false, // For regeneration, true means a new AI output has been submitted by oracle
            finalized: false,
            approved: false,
            hasVoted: new mapping(address => bool)
        });

        emit ArtworkProposedForReGeneration(artworkId, msg.sender, newPromptText);
        emit PromptProposed(proposalId, msg.sender, keccak256(abi.encodePacked(newPromptText))); // Hash of new prompt
        emit TokensStaked(msg.sender, msg.value);
    }

    // --- Internal Voting Power Calculation (for III. Curation & Approval) ---

    /// @dev Returns the effective address that holds the voting power for a given account.
    /// If an account has delegated, this returns the delegatee's address; otherwise, it returns the account's own address.
    function _getEffectiveVoter(address account) internal view returns (address) {
        address delegatee = _curators[account].delegatedTo;
        if (delegatee == address(0)) {
            return account; // Not delegated, so they vote for themselves
        }
        return delegatee; // Delegated, so their delegatee votes
    }

    /// @dev Calculates the total voting power of an address, including its own stake/reputation and delegated power.
    /// If an address has delegated its *own* voting power, its direct contribution is nullified, but it still
    /// benefits from power delegated *to* it.
    /// @param _voter The address to query the voting power for.
    /// @return The total effective voting power.
    function _getVotingPower(address _voter) internal view returns (uint256) {
        uint256 ownContribution = 0;
        // Check if the voter has delegated their power *away* from themselves.
        // If _curators[_voter].delegatedTo is address(0) or _voter, they control their own vote.
        if (_curators[_voter].delegatedTo == address(0) || _curators[_voter].delegatedTo == _voter) {
            ownContribution = _curators[_voter].stakedTokens + _curators[_voter].reputationScore;
        }
        // Add any power that has been delegated *to* this address.
        uint256 delegatedInPower = _delegatedVotingPower[_voter];

        return ownContribution + delegatedInPower;
    }

    // --- III. Curation & Approval (DAO Governance) ---

    /// @notice Curators vote to approve or reject a submitted artwork or a regeneration request.
    /// Voting power is based on staked tokens and reputation, potentially delegated.
    /// @param promptProposalId The ID of the prompt/regeneration proposal.
    /// @param approve True for approval, false for rejection.
    function castArtworkVote(uint256 promptProposalId, bool approve) public whenNotPaused {
        PromptProposal storage proposal = _promptProposals[promptProposalId];
        require(proposal.creationTime > 0, "AetherCanvas: Prompt proposal does not exist");
        require(proposal.submitted, "AetherCanvas: Artwork not yet submitted for this proposal");
        require(block.timestamp <= proposal.votingEndTime, "AetherCanvas: Voting period has ended");
        require(!proposal.finalized, "AetherCanvas: Proposal already finalized");
        
        address effectiveVoter = _getEffectiveVoter(msg.sender);
        require(_getVotingPower(effectiveVoter) > 0, "AetherCanvas: Voter has no voting power or has delegated");
        require(!proposal.hasVoted[effectiveVoter], "AetherCanvas: Effective voter already voted on this proposal");

        uint256 votingPower = _getVotingPower(effectiveVoter);
        if (approve) {
            proposal.yeas += votingPower;
        } else {
            proposal.nays += votingPower;
        }
        proposal.hasVoted[effectiveVoter] = true;

        emit ArtworkVoteCast(promptProposalId, effectiveVoter, approve);
    }

    /// @notice Finalizes the voting for an artwork proposal, minting the NFT if approved,
    /// and managing the proposer's stake and reputation.
    /// @param promptProposalId The ID of the prompt proposal.
    function finalizeArtworkProposal(uint256 promptProposalId) public whenNotPaused {
        PromptProposal storage proposal = _promptProposals[promptProposalId];
        require(proposal.creationTime > 0, "AetherCanvas: Prompt proposal does not exist");
        require(proposal.submitted, "AetherCanvas: Artwork not yet submitted for this proposal");
        require(block.timestamp > proposal.votingEndTime, "AetherCanvas: Voting period has not ended yet");
        require(!proposal.finalized, "AetherCanvas: Proposal already finalized");

        proposal.finalized = true;
        if (proposal.yeas > proposal.nays) {
            proposal.approved = true;
            uint256 newArtworkId = _nextTokenId++;
            _mint(proposal.proposer, newArtworkId, proposal.finalURI, proposal.actualOutputHash, promptProposalId);
            
            // Return proposer's stake + small reputation boost for successful proposals
            (bool success, ) = payable(proposal.proposer).call{value: proposal.stakeAmount}("");
            require(success, "AetherCanvas: Failed to send back stake to proposer");

            _curators[proposal.proposer].stakedTokens -= proposal.stakeAmount;
            _curators[proposal.proposer].reputationScore += 10; // Reputation boost
            emit TokensUnstaked(proposal.proposer, proposal.stakeAmount);
            emit ReputationUpdated(proposal.proposer, 10, _curators[proposal.proposer].reputationScore);
            emit ArtworkProposalFinalized(promptProposalId, true, newArtworkId);
        } else {
            // Proposal rejected, return proposer's stake - small reputation penalty
            (bool success, ) = payable(proposal.proposer).call{value: proposal.stakeAmount}("");
            require(success, "AetherCanvas: Failed to send back stake to proposer");
            _curators[proposal.proposer].stakedTokens -= proposal.stakeAmount;
            _curators[proposal.proposer].reputationScore = _curators[proposal.proposer].reputationScore >= 5 ? _curators[proposal.proposer].reputationScore - 5 : 0; // Reputation penalty
            emit TokensUnstaked(proposal.proposer, proposal.stakeAmount);
            emit ReputationUpdated(proposal.proposer, -5, _curators[proposal.proposer].reputationScore);
            emit ArtworkProposalFinalized(promptProposalId, false, 0); // artworkId 0 for rejected
        }
        // If the proposer had delegated their vote, their delegation needs to be cleared if stake is 0
        if (_curators[proposal.proposer].stakedTokens == 0) {
             _curators[proposal.proposer].delegatedTo = address(0);
        }
    }

    /// @notice Proposes changes to system parameters (e.g., voting period, fees).
    /// @param parameterKey A hash representing the parameter to change (e.g., `keccak256("PROMPT_VOTING_PERIOD")`).
    /// @param newValueEncoded The new value for the parameter, ABI-encoded.
    function proposeSystemParameterChange(bytes32 parameterKey, bytes calldata newValueEncoded) public payable whenNotPaused {
        require(msg.value >= MIN_STAKE_FOR_PROPOSAL, "AetherCanvas: Insufficient stake for proposal");
        _curators[msg.sender].stakedTokens += msg.value;

        uint256 proposalId = _nextGovernanceProposalId++;
        _governanceProposals[proposalId] = GovernanceProposal({
            parameterKey: parameterKey,
            newValueEncoded: newValueEncoded,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + governanceVotingPeriod,
            yeas: 0,
            nays: 0,
            finalized: false,
            executed: false,
            hasVoted: new mapping(address => bool)
        });

        emit GovernanceProposalCreated(proposalId, parameterKey, newValueEncoded);
        emit TokensStaked(msg.sender, msg.value);
    }

    /// @notice Votes on system parameter changes.
    /// @param paramProposalId The ID of the parameter change proposal.
    /// @param approve True for approval, false for rejection.
    function castParameterVote(uint256 paramProposalId, bool approve) public whenNotPaused {
        GovernanceProposal storage proposal = _governanceProposals[paramProposalId];
        require(proposal.creationTime > 0, "AetherCanvas: Governance proposal does not exist");
        require(block.timestamp <= proposal.votingEndTime, "AetherCanvas: Voting period has ended");
        require(!proposal.finalized, "AetherCanvas: Proposal already finalized");

        address effectiveVoter = _getEffectiveVoter(msg.sender);
        require(_getVotingPower(effectiveVoter) > 0, "AetherCanvas: Voter has no voting power or has delegated");
        require(!proposal.hasVoted[effectiveVoter], "AetherCanvas: Effective voter already voted on this proposal");

        uint256 votingPower = _getVotingPower(effectiveVoter);
        if (approve) {
            proposal.yeas += votingPower;
        } else {
            proposal.nays += votingPower;
        }
        proposal.hasVoted[effectiveVoter] = true;

        emit GovernanceVoteCast(paramProposalId, effectiveVoter, approve);
    }

    /// @notice Finalizes a system parameter change proposal and executes it if approved.
    /// This function should typically be called after the voting period ends.
    /// @param paramProposalId The ID of the governance proposal.
    function finalizeGovernanceProposal(uint256 paramProposalId) public whenNotPaused {
        GovernanceProposal storage proposal = _governanceProposals[paramProposalId];
        require(proposal.creationTime > 0, "AetherCanvas: Governance proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "AetherCanvas: Voting period has not ended yet");
        require(!proposal.finalized, "AetherCanvas: Proposal already finalized");

        proposal.finalized = true;
        if (proposal.yeas > proposal.nays) {
            // Proposal approved, execute the parameter change.
            // This would involve a switch or mapping to apply the encoded value to the correct state variable.
            // For simplicity, we only have `setVotingPeriod` directly callable by owner for now.
            // A full DAO would have a robust dispatcher.
            // Here, we'll just emit an event indicating it was approved.
            proposal.executed = true; // Mark as executed for now.
            emit GovernanceProposalExecuted(paramProposalId, proposal.parameterKey, proposal.newValueEncoded);
        }
        // In a full DAO, proposer's stake handling (return/slash) would be here.
    }

    /// @notice Delegates voting power to another address.
    /// The delegator's staked tokens and reputation contribute to the delegatee's total voting power.
    /// @param delegatee The address to delegate voting power to.
    function delegateVote(address delegatee) public whenNotPaused {
        require(msg.sender != delegatee, "AetherCanvas: Cannot delegate to self");
        require(_curators[msg.sender].stakedTokens > 0, "AetherCanvas: No tokens staked to delegate");

        address currentDelegatee = _curators[msg.sender].delegatedTo;

        if (currentDelegatee == delegatee) {
            return; // Already delegated to this address
        }

        // If msg.sender was previously delegated to someone else (not self or address(0))
        if (currentDelegatee != address(0) && currentDelegatee != msg.sender) {
            _delegatedVotingPower[currentDelegatee] -= _curators[msg.sender].stakedTokens;
        }
        // If msg.sender was not delegated or self-delegated, their voting power was calculated directly.
        // No need to adjust _delegatedVotingPower[msg.sender] here.

        // Set new delegatee
        _curators[msg.sender].delegatedTo = delegatee;
        // Add msg.sender's stake to the new delegatee's total delegated power
        _delegatedVotingPower[delegatee] += _curators[msg.sender].stakedTokens;

        emit VoteDelegated(msg.sender, delegatee);
    }

    // --- IV. ZKP-Enhanced Governance ---

    /// @notice Submits a Zero-Knowledge Proof for a conditional or private vote.
    /// This allows voters to prove they meet certain criteria or vote in a specific way without revealing full details.
    /// @param proposalId The ID of the proposal being voted on (can be any proposal type).
    /// @param proof The serialized ZKP proof (e.g., Groth16, PLONK proof).
    /// @param publicInputs The public inputs for the ZKP verifier, specific to the circuit.
    function submitZKPVote(uint256 proposalId, bytes calldata proof, bytes calldata publicInputs) public whenNotPaused {
        require(zkpVerifierAddress != address(0), "AetherCanvas: ZKP Verifier not set");
        
        address effectiveVoter = _getEffectiveVoter(msg.sender);
        require(!_hasZKPVoted[proposalId][effectiveVoter], "AetherCanvas: Effective voter already voted with ZKP on this proposal");
        require(_getVotingPower(effectiveVoter) > 0, "AetherCanvas: Voter has no voting power or has delegated");
        
        // Convert `bytes calldata publicInputs` to `bytes32[] calldata`
        // Assuming publicInputs is a tightly packed sequence of bytes32
        require(publicInputs.length % 32 == 0, "AetherCanvas: Invalid publicInputs length");
        bytes32[] memory zkpPublicInputs = new bytes32[](publicInputs.length / 32);
        for (uint i = 0; i < publicInputs.length / 32; i++) {
            assembly {
                zkpPublicInputs[i] := mload(add(add(publicInputs, 0x20), mul(i, 0x20)))
            }
        }

        // Call the external ZKP verifier contract
        bool verified = IZKPVerifier(zkpVerifierAddress).verifyProof(proof, zkpPublicInputs);
        require(verified, "AetherCanvas: ZKP verification failed");

        // The outcome of the vote ('yes' or 'no') would be embedded in the publicInputs based on the ZKP circuit design.
        // For this example, let's assume `zkpPublicInputs[0]` directly encodes the vote:
        // `keccak256("VOTE_YES")` for an approval, `keccak256("VOTE_NO")` for a rejection.
        bool voteOutcomeIsYes = (zkpPublicInputs[0] == keccak256("VOTE_YES")); // Placeholder logic

        uint256 votingPower = _getVotingPower(effectiveVoter);
        if (voteOutcomeIsYes) {
            _zkpYeas[proposalId] += votingPower;
        } else {
            _zkpNays[proposalId] += votingPower;
        }
        _hasZKPVoted[proposalId][effectiveVoter] = true;

        emit ZKPVoteCast(proposalId, effectiveVoter, keccak256(abi.encodePacked(proof, publicInputs)));
    }

    /// @notice Owner/DAO-privileged function to trigger the final tallying of ZKP votes for a specific proposal.
    /// This would typically happen after the ZKP voting period ends.
    /// @param proposalId The ID of the proposal for which ZKP votes are being tallied.
    /// @param auxiliaryData Any additional data needed for final tallying (e.g., specific parameters or thresholds).
    function tallyZKPVote(uint256 proposalId, bytes calldata auxiliaryData) public onlyOwner whenNotPaused {
        // This function would combine ZKP votes with regular votes or stand alone depending on proposal type.
        // For simplicity, we just finalize the ZKP tally and emit.
        // A real system would integrate this into specific proposal finalization logic (e.g., `finalizeArtworkProposal`).
        emit ZKPVoteTallied(proposalId, _zkpYeas[proposalId], _zkpNays[proposalId]);
        // The `auxiliaryData` could be used to pass extra parameters to influence the tally result
        // or to specify how ZKP votes interact with regular votes.
    }

    /// @notice Sets the address of the trusted ZKP verifier contract.
    /// Only the contract owner can set this.
    /// @param verifierAddress The address of the `IZKPVerifier` compliant contract.
    function setZKPVerifierAddress(address verifierAddress) public onlyOwner whenNotPaused {
        require(verifierAddress != address(0), "AetherCanvas: Verifier address cannot be zero");
        zkpVerifierAddress = verifierAddress;
        // In a real scenario, you might want to check if the address actually implements IZKPVerifier.
    }

    // --- V. Reputation & Staking ---

    /// @notice Users stake tokens (ETH in this example) to gain voting power and participate as curators.
    /// @param amount The amount of tokens (ETH) to stake.
    function stakeTokens(uint256 amount) public payable whenNotPaused {
        require(msg.value == amount, "AetherCanvas: Sent value must match amount to stake");
        _curators[msg.sender].stakedTokens += amount;
        
        // If the user has delegated their vote, increase the delegatee's total delegated power.
        address currentDelegatee = _curators[msg.sender].delegatedTo;
        if (currentDelegatee != address(0) && currentDelegatee != msg.sender) {
            _delegatedVotingPower[currentDelegatee] += amount;
        }

        emit TokensStaked(msg.sender, amount);
    }

    /// @notice Allows users to unstake their tokens after a cooldown period.
    /// If the user had delegated their vote, the delegation is broken if all tokens are unstaked.
    /// @param amount The amount of tokens (ETH) to unstake.
    function unstakeTokens(uint256 amount) public whenNotPaused {
        require(_curators[msg.sender].stakedTokens >= amount, "AetherCanvas: Insufficient staked tokens");
        require(_curators[msg.sender].unstakeCooldownEndTime == 0 || block.timestamp > _curators[msg.sender].unstakeCooldownEndTime, "AetherCanvas: Unstaking cooldown period active");

        address currentDelegatee = _curators[msg.sender].delegatedTo;

        if (currentDelegatee != address(0) && currentDelegatee != msg.sender) {
            // If delegated to another address, reduce that delegatee's delegated power
            _delegatedVotingPower[currentDelegatee] -= amount;
        } 
        // If currentDelegatee is address(0) or msg.sender, no change to _delegatedVotingPower is needed for msg.sender

        _curators[msg.sender].stakedTokens -= amount;
        
        // If all tokens are unstaked, clear any delegation.
        if (_curators[msg.sender].stakedTokens == 0) {
            _curators[msg.sender].delegatedTo = address(0);
        }

        _curators[msg.sender].unstakeCooldownEndTime = block.timestamp + unstakeCooldownPeriod;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "AetherCanvas: Failed to send ETH back");

        emit TokensUnstaked(msg.sender, amount);
    }

    /// @notice View function to get a curator's current reputation score.
    /// @param curator The address of the curator.
    /// @return The reputation score.
    function getCuratorReputation(address curator) public view returns (uint256) {
        return _curators[curator].reputationScore;
    }

    /// @notice Privileged function to adjust a curator's reputation based on curation quality or other metrics.
    /// This function would typically be called via a successful DAO governance proposal
    /// or by a trusted oracle based on performance metrics. For this example, only the owner or oracle can call it directly.
    /// @param curator The address of the curator whose reputation to update.
    /// @param changeAmount The amount to change the reputation by (can be negative).
    function updateCuratorReputation(address curator, int256 changeAmount) public whenNotPaused {
        require(msg.sender == owner() || msg.sender == oracleAddress, "AetherCanvas: Only owner or oracle can update reputation directly");

        uint256 currentRep = _curators[curator].reputationScore;
        uint256 newRep;

        if (changeAmount > 0) {
            newRep = currentRep + uint256(changeAmount);
        } else {
            // Ensure reputation doesn't go below zero
            newRep = currentRep >= uint256(-changeAmount) ? currentRep - uint256(-changeAmount) : 0;
        }
        _curators[curator].reputationScore = newRep;
        emit ReputationUpdated(curator, changeAmount, newRep);
    }

    // --- VI. Treasury & Funding ---

    /// @notice Allows anyone to send funds (ETH) to the contract treasury.
    function fundTreasury() public payable whenNotPaused {
        require(msg.value > 0, "AetherCanvas: Must send ETH to fund treasury");
        emit TreasuryFunded(msg.sender, msg.value);
    }

    /// @notice DAO proposal to withdraw funds for AI costs, rewards, etc.
    /// @param recipient The address to receive the funds.
    /// @param amount The amount of funds to withdraw.
    /// @param description A description of the withdrawal purpose.
    function proposeTreasuryWithdrawal(address recipient, uint256 amount, string calldata description) public payable whenNotPaused {
        require(msg.value >= MIN_STAKE_FOR_PROPOSAL, "AetherCanvas: Insufficient stake for proposal");
        _curators[msg.sender].stakedTokens += msg.value;

        uint256 proposalId = _nextTreasuryProposalId++;
        _treasuryProposals[proposalId] = TreasuryWithdrawalProposal({
            proposer: msg.sender,
            recipient: recipient,
            amount: amount,
            description: description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + treasuryVotingPeriod,
            yeas: 0,
            nays: 0,
            finalized: false,
            executed: false,
            hasVoted: new mapping(address => bool)
        });

        emit TreasuryWithdrawalProposed(proposalId, msg.sender, recipient, amount);
        emit TokensStaked(msg.sender, msg.value);
    }

    /// @notice Curators vote on treasury withdrawal proposals.
    /// @param withdrawalProposalId The ID of the treasury withdrawal proposal.
    /// @param approve True for approval, false for rejection.
    function castTreasuryVote(uint256 withdrawalProposalId, bool approve) public whenNotPaused {
        TreasuryWithdrawalProposal storage proposal = _treasuryProposals[withdrawalProposalId];
        require(proposal.creationTime > 0, "AetherCanvas: Treasury proposal does not exist");
        require(block.timestamp <= proposal.votingEndTime, "AetherCanvas: Voting period has ended");
        require(!proposal.finalized, "AetherCanvas: Proposal already finalized");

        address effectiveVoter = _getEffectiveVoter(msg.sender);
        require(_getVotingPower(effectiveVoter) > 0, "AetherCanvas: Voter has no voting power or has delegated");
        require(!proposal.hasVoted[effectiveVoter], "AetherCanvas: Effective voter already voted on this proposal");

        uint256 votingPower = _getVotingPower(effectiveVoter);
        if (approve) {
            proposal.yeas += votingPower;
        } else {
            proposal.nays += votingPower;
        }
        proposal.hasVoted[effectiveVoter] = true;

        emit GovernanceVoteCast(withdrawalProposalId, effectiveVoter, approve); // Re-use event for now
    }

    /// @notice Executes a DAO-approved treasury withdrawal.
    /// @param withdrawalProposalId The ID of the withdrawal proposal.
    function executeTreasuryWithdrawal(uint256 withdrawalProposalId) public whenNotPaused {
        TreasuryWithdrawalProposal storage proposal = _treasuryProposals[withdrawalProposalId];
        require(proposal.creationTime > 0, "AetherCanvas: Treasury proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "AetherCanvas: Voting period has not ended yet");
        require(!proposal.executed, "AetherCanvas: Proposal already executed");
        require(!proposal.finalized, "AetherCanvas: Proposal not finalized yet"); 

        proposal.finalized = true; // Mark as finalized
        if (proposal.yeas > proposal.nays) {
            require(address(this).balance >= proposal.amount, "AetherCanvas: Insufficient treasury balance");
            (bool success, ) = payable(proposal.recipient).call{value: proposal.amount}("");
            require(success, "AetherCanvas: Failed to execute treasury withdrawal");
            proposal.executed = true;
            emit TreasuryWithdrawalExecuted(withdrawalProposalId, proposal.recipient, proposal.amount);
        }
        // In a real system, proposer's stake would be returned/slashed here.
        // For simplicity, we assume stake is returned on finalize for now.
    }

    // --- VII. Oracle Integration ---

    /// @notice Sets the address of the trusted oracle. Only the contract owner can set this.
    /// @param _oracleAddress The address of the oracle contract.
    function setOracleAddress(address _oracleAddress) public onlyOwner whenNotPaused {
        require(_oracleAddress != address(0), "AetherCanvas: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }

    /// @notice An oracle submits verified data, potentially triggering NFT updates (e.g., for regeneration).
    /// @param artworkId The ID of the artwork to update.
    /// @param newURI The new metadata URI from the oracle (e.g., pointing to a regenerated image).
    /// @param newOutputHash The new output hash from the oracle, verifying the new content.
    function submitOracleData(uint256 artworkId, string calldata newURI, bytes32 newOutputHash) public onlyOracle whenNotPaused {
        require(_exists(artworkId), "AetherCanvas: Artwork does not exist");
        
        // Update artwork details based on oracle data
        _artworks[artworkId].currentURI = newURI;
        _artworks[artworkId].promptHash = newOutputHash; // Update the hash associated with the current state
        _tokenURIs[artworkId] = newURI;

        emit NFTURIUpdated(artworkId, newURI);
    }

    // --- VIII. System Configuration & Safety ---

    /// @notice Pauses sensitive functions in case of emergency. Only the contract owner can call this.
    function pauseContract() public onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract. Only the contract owner can call this.
    function unpauseContract() public onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Updates the duration for all general voting periods.
    /// For simplicity, callable by owner. In a full DAO, this would be via `proposeSystemParameterChange` & `finalizeGovernanceProposal`.
    /// @param newPeriod The new voting period in seconds.
    function setVotingPeriod(uint256 newPeriod) public onlyOwner whenNotPaused {
        require(newPeriod > 0, "AetherCanvas: Voting period must be greater than zero");
        promptProposalVotingPeriod = newPeriod;
        governanceVotingPeriod = newPeriod;
        treasuryVotingPeriod = newPeriod;
    }

    /// @notice Allows the contract owner to withdraw accidentally sent ERC20 tokens.
    /// This is an emergency function and should not be used for regular treasury management.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    function withdrawERC20Tokens(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
    }
}
```