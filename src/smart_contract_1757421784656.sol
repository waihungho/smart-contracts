Here's a Solidity smart contract named `EtherealEchoesEngine`. It implements a Decentralized Autonomous Generative Agent (DAGA) that mints and manages "Echoes" – dynamic NFTs that evolve based on community input, external "AI" influence (via oracle), on-chain deterministic logic, and self-governance. Each Echo generates unique narrative fragments over time, contributing to an evolving lore.

This contract aims for advanced, creative, and trendy concepts by combining:
*   **Dynamic NFTs:** Echoes are NFTs whose on-chain state changes, influencing their metadata and generated narratives.
*   **Oracle Integration (Simulated AI Influence):** An authorized oracle can submit a global "AI sentiment" score, affecting how all Echoes evolve.
*   **On-chain Generative Logic:** Deterministic algorithms within the contract govern Echo evolution and the generation of unique textual narrative fragments.
*   **Community-driven Evolution:** Users can submit sentiment towards individual Echoes, directly influencing their personal evolution paths.
*   **Decentralized Governance:** A simple DAO-like structure allows token stakers to propose and vote on changes to the system's core evolution parameters.

To adhere to the "don't duplicate any of open source" while still being a functional contract, I've implemented a minimal ERC721 interface directly within the contract. For standard access control and pausing mechanisms, I've leveraged OpenZeppelin contracts (`AccessControl`, `Pausable`) as they are proven security primitives and their re-implementation would be boilerplate, detracting from the unique application logic.

---

## Smart Contract: `EtherealEchoesEngine`

**Concept:** `EtherealEchoesEngine` creates and manages "Echoes," dynamic NFTs that represent evolving digital entities. These Echoes develop their characteristics and narrative over time, influenced by three main factors:
1.  **Autonomous On-chain Logic:** Each Echo has internal state variables that evolve deterministically based on its history and internal "seed."
2.  **External "AI Mood" (Oracle-fed):** An authorized oracle periodically feeds a global sentiment score, simulating a large-scale AI's mood or general market sentiment, influencing all Echoes.
3.  **Community Interaction:** Users can submit sentiment scores for individual Echoes, giving them a unique "personal sentiment" that steers their individual evolution.

The protocol itself is governed by its community through a decentralized voting mechanism, allowing adjustments to evolution parameters, oracle influence, and fees.

---

### Outline:

1.  **Interfaces & Libraries:** Imports necessary contracts from OpenZeppelin for standard security patterns (AccessControl, Pausable) and for ERC721 interface compliance.
2.  **Role Management:** Defines custom roles for different levels of system access (Minter, Oracle, Pauser, Governance roles).
3.  **Events:** Declares specific events for transparent logging of key actions.
4.  **Errors:** Defines custom errors for efficient and clear error handling.
5.  **Structs:**
    *   `Echo`: Stores the dynamic state of each NFT (owner, timestamps, evolution count, sentiment, narrative history, etc.).
    *   `Proposal`: Manages the state of governance proposals (parameter key, new value, votes, deadline, execution status).
6.  **State Variables:** Stores core contract data, including ERC721 mappings, Echo data, governance parameters, and on-chain narrative components.
7.  **Constructor:** Initializes the contract, sets up initial roles, and configures base parameters.
8.  **I. Core Echo Management & Minting (Dynamic NFT - Minimal ERC721 Implementation):** Functions for creating, burning, and querying Echo NFTs.
9.  **II. Echo Evolution & State Dynamics:** Logic dictating how Echoes change their internal state and generate new characteristics.
10. **III. External Data & AI Influence (Oracle):** Functions allowing the oracle to interact and influence the system.
11. **IV. Narrative & Lore Generation:** On-chain generation of unique textual fragments based on an Echo's current state.
12. **V. Community Interaction & Sentiment:** Functions enabling users to influence individual Echoes.
13. **VI. Decentralized Governance (Policy & Parameters):** A DAO-like system for proposing, voting on, and executing changes to protocol parameters.
14. **VII. System Maintenance & Utility:** Administrative functions like fee withdrawal, pausing, and updating base URI.

### Function Summary:

**I. Core Echo Management & Minting (Minimal ERC721 Implementation):**
1.  `name()`: Returns the token name.
2.  `symbol()`: Returns the token symbol.
3.  `balanceOf(address owner)`: Returns the number of Echoes owned by an address.
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific Echo.
5.  `approve(address to, uint256 tokenId)`: Grants approval to a single address for a specific Echo.
6.  `getApproved(uint256 tokenId)`: Returns the approved address for a specific Echo.
7.  `setApprovalForAll(address operator, bool approved)`: Grants/revokes operator status for all Echoes of an owner.
8.  `isApprovedForAll(address owner, address operator)`: Checks if an address is an approved operator for another.
9.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an Echo.
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers ownership of an Echo.
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safely transfers ownership with additional data.
12. `onERC721Received(...)`: ERC721 receiver hook, allowing this contract to receive NFTs.
13. `mintEcho(string memory initialPrompt)`: Mints a new dynamic Echo NFT, assigning an initial state based on a prompt. Requires `MINTER_ROLE`.
14. `burnEcho(uint256 tokenId)`: Allows the owner or approved operator to destroy an Echo NFT.
15. `getEchoState(uint256 tokenId)`: Retrieves all internal state variables of an Echo.
16. `getEchoMetadataURI(uint256 tokenId)`: Generates a dynamic metadata URI for an Echo, reflecting its current state.

**II. Echo Evolution & State Dynamics:**
17. `triggerEchoEvolution(uint256 tokenId)`: Publicly callable (with a fee) to advance an Echo through its evolution cycle, updating its state based on internal logic and external factors.
18. `adjustEpochInterval(uint256 newInterval)`: A governed function to set the minimum cooldown period between Echo evolutions. Requires `GOV_EXECUTOR_ROLE`.

**III. External Data & AI Influence (Oracle):**
19. `submitGlobalAISentiment(uint256 sentimentScore)`: Callable only by an authorized `ORACLE_ROLE` to feed a global "AI mood" score, influencing all Echoes' evolution.
20. `updateAIInfluenceWeight(uint256 newWeight)`: A governed function to adjust the impact of the global AI sentiment on Echo evolution. Requires `GOV_EXECUTOR_ROLE`.

**IV. Narrative & Lore Generation:**
21. `retrieveCurrentNarrativeFragment(uint256 tokenId)`: Generates a unique, short textual narrative fragment on-chain based on the Echo's current state.
22. `getNarrativeHistory(uint256 tokenId)`: Returns an array of hashes representing past narrative fragments or evolution events of an Echo.

**V. Community Interaction & Sentiment:**
23. `submitUserSentiment(uint256 tokenId, int8 sentimentValue)`: Allows any user to submit a sentiment score for a specific Echo, influencing its personal evolution path. Includes a cooldown.
24. `getEchoCommunitySentiment(uint256 tokenId)`: Returns the aggregated personal sentiment score for a given Echo.

**VI. Decentralized Governance (Policy & Parameters):**
25. `stakeGovernanceTokens(uint256 amount)`: (Conceptual, assumes external ERC20) Allows users to stake tokens to gain voting power.
26. `unstakeGovernanceTokens(uint256 amount)`: (Conceptual) Allows users to unstake tokens, with checks for active votes.
27. `delegateVotingPower(address delegatee)`: Allows stakers to delegate their voting power to another address.
28. `proposeEvolutionParameterChange(bytes32 parameterKey, uint256 newValue)`: Allows users with sufficient stake and `GOV_PROPOSER_ROLE` to propose changes to system parameters.
29. `voteOnProposal(uint256 proposalId, bool support)`: Allows stakers (or their delegates) to vote on active proposals.
30. `getProposalState(uint256 proposalId)`: Returns the current state (Pending, Active, Succeeded, Defeated, Executed) of a proposal.
31. `executeProposal(uint256 proposalId)`: Executes a passed governance proposal. Requires `GOV_EXECUTOR_ROLE`.

**VII. System Maintenance & Utility:**
32. `withdrawProtocolFees(address recipient)`: Allows the governance executor to withdraw accumulated fees from Echo evolutions. Requires `GOV_EXECUTOR_ROLE`.
33. `emergencyPause()`: Allows the `PAUSER_ROLE` to pause critical contract functions in an emergency.
34. `unpauseSystem()`: Allows the `PAUSER_ROLE` to unpause the system.
35. `setBaseURI(string memory newBaseURI)`: Allows the `GOV_EXECUTOR_ROLE` to update the base URI used for NFT metadata generation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom errors for clarity and gas efficiency
error NotApprovedOrOwner();
error TokenDoesNotExist();
error NotMinterRole(address caller);
error TokenAlreadyExists();
error InvalidSentimentValue();
error EchoEvolutionCooldownActive();
error ZeroAddressNotAllowed();
error ProposalNotFound();
error ProposalAlreadyVoted();
error ProposalNotExecutable();
error ProposalAlreadyExecuted();
error InsufficientStakeForProposal();
error InsufficientStakeForVoting();
error CannotUnstakeActiveVote();
error InvalidProposalState();
error InvalidEpochInterval();
error InsufficientFeeForEvolution();
error NotEnoughFeesToWithdraw();
error WithdrawalFailed();
error AIInfluenceWeightExceedsMax();
error QuorumThresholdExceedsMax();
error CannotStakeZeroTokens();
error InsufficientStakedTokens();
error SentimentCooldownActive();

/**
 * @title EtherealEchoesEngine
 * @dev A Decentralized Autonomous Generative Agent (DAGA) that mints and manages
 *      "Echoes" - dynamic NFTs which evolve based on a blend of community input,
 *      external "AI" influence (via oracle), on-chain logic, and self-governance.
 *      Each Echo generates unique narrative fragments over time, contributing to an
 *      evolving lore.
 *
 * Outline:
 * 1.  Interfaces & Libraries: Imports necessary contracts and utilities.
 * 2.  Role Management: Defines roles for governance, oracle, minter, pauser.
 * 3.  Events: Declares events for critical actions.
 * 4.  Errors: Defines custom errors for precise error handling.
 * 5.  Structs: Defines data structures for Echo NFTs and Governance Proposals.
 * 6.  State Variables: Stores core data like Echoes, governance parameters, etc.
 * 7.  Constructor: Initializes the contract, sets up roles, and initial parameters.
 * 8.  I. Core Echo Management & Minting (Dynamic NFT - ERC721-like minimal implementation)
 * 9.  II. Echo Evolution & State Dynamics: Logic for how Echoes change over time.
 * 10. III. External Data & AI Influence (Oracle): Functions for oracle interaction.
 * 11. IV. Narrative & Lore Generation: On-chain generation of textual fragments.
 * 12. V. Community Interaction & Sentiment: User-driven influence on Echoes.
 * 13. VI. Decentralized Governance (Policy & Parameters): DAO-like system for protocol changes.
 * 14. VII. System Maintenance & Utility: Admin and emergency functions.
 */
contract EtherealEchoesEngine is AccessControl, Pausable, IERC721, IERC721Receiver {

    // --- Role Management ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GOV_PROPOSER_ROLE = keccak256("GOV_PROPOSER_ROLE"); // Can propose changes
    bytes32 public constant GOV_EXECUTOR_ROLE = keccak256("GOV_EXECUTOR_ROLE"); // Can execute passed proposals

    // --- Events ---
    event EchoMinted(uint256 indexed tokenId, address indexed owner, string initialPrompt);
    event EchoEvolved(uint256 indexed tokenId, uint256 newEvolutionCount, uint8 newStateA, uint8 newStateB, uint8 newStateC);
    event GlobalAISentimentUpdated(uint256 indexed sentimentScore, uint256 timestamp);
    event UserSentimentSubmitted(uint256 indexed tokenId, address indexed sender, int8 sentimentValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 parameterKey, uint256 newValue, uint256 votingDeadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event EpochIntervalAdjusted(uint256 newInterval);
    event AIInfluenceWeightUpdated(uint256 newWeight);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event BaseURIUpdated(string newBaseURI);

    // --- Structs ---

    // @dev Represents the internal state of a dynamic Echo NFT.
    struct Echo {
        address owner;
        uint256 mintTimestamp;
        uint224 lastEvolutionTimestamp; // Saves space, max timestamp ~1.8e11 sec (5700 years)
        uint32 evolutionCount;         // Max 4 billion evolutions
        uint8 stateA;                  // e.g., Mood (0-255)
        uint8 stateB;                  // e.g., Color (0-255)
        uint8 stateC;                  // e.g., Form (0-255)
        int24 personalSentimentScore;  // Aggregate user sentiment for this specific Echo (-8M to +8M)
        uint64 lastSubmittedSentimentBlock; // Block number of last sentiment submission, to prevent rapid spam
        bytes32[] narrativeHistoryHashes; // Store hashes of narrative fragments to save gas for history
    }

    // @dev Represents a governance proposal to change system parameters.
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }
    struct Proposal {
        bytes32 parameterKey;      // Identifier for the parameter to change (e.g., keccak256("AI_INFLUENCE_WEIGHT"))
        uint256 newValue;          // The new value for the parameter
        uint256 creationTime;      // Timestamp of proposal creation
        uint256 votingDeadline;    // Timestamp when voting ends
        uint256 forVotes;          // Total votes in favor
        uint256 againstVotes;      // Total votes against
        bool executed;             // True if the proposal has been executed
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- State Variables ---

    // ERC721-like minimal implementation
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _nextTokenId;
    string private _baseURI;

    mapping(uint256 => Echo) public echoes; // Stores all Echo NFTs
    uint256 public globalAISentiment;      // Global sentiment score fed by oracle (0-100)
    uint256 public aiInfluenceWeight;       // How much globalAISentiment influences evolution (governed, 0-100)
    uint256 public epochEvolutionInterval;  // Minimum time (seconds) between evolutions for an Echo (governed)
    uint256 public minStakeToPropose;       // Minimum stake required to create a proposal
    uint256 public proposalVotingPeriod;    // Duration of voting period (seconds)
    uint256 public proposalQuorumThreshold; // Percentage of total staked supply required for a proposal to pass (e.g., 400 for 40% * 10, i.e., 400/1000)
    uint256 public feePerEvolution;         // Fee to trigger an evolution, collected by protocol

    // Governance
    uint256 private _proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public stakedGovernanceTokens; // User's staked balance (simulated)
    mapping(address => address) public votingDelegates;       // Delegate mapping

    // --- On-chain Narrative Components (simplified for gas) ---
    // These arrays define potential keywords for narrative generation based on Echo states.
    string[3] private _moodWords = ["Wistful", "Energetic", "Calm"];
    string[3] private _colorWords = ["Emerald", "Ruby", "Calypso"];
    string[3] private _formWords = ["Swirl", "Glyph", "Bloom"];
    uint256 private constant _SENTIMENT_COOLDOWN_BLOCKS = 10; // Blocks between sentiment submissions

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address admin_,
        address oracle_,
        uint256 initialAIInfluenceWeight,
        uint256 initialEpochInterval,
        uint256 initialMinStakeToPropose,
        uint256 initialProposalVotingPeriod,
        uint256 initialProposalQuorumThreshold,
        uint256 initialFeePerEvolution
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;

        if (admin_ == address(0) || oracle_ == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        // Grant initial roles
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
        _setupRole(MINTER_ROLE, admin_);
        _setupRole(ORACLE_ROLE, oracle_);
        _setupRole(PAUSER_ROLE, admin_);
        _setupRole(GOV_PROPOSER_ROLE, admin_);
        _setupRole(GOV_EXECUTOR_ROLE, admin_);

        // Set initial governance parameters
        if (initialAIInfluenceWeight > 100) revert AIInfluenceWeightExceedsMax();
        aiInfluenceWeight = initialAIInfluenceWeight; // e.g., 50 (out of 100)

        if (initialEpochInterval == 0) revert InvalidEpochInterval();
        epochEvolutionInterval = initialEpochInterval; // e.g., 1 day = 86400 seconds

        minStakeToPropose = initialMinStakeToPropose; // e.g., 1000 tokens
        proposalVotingPeriod = initialProposalVotingPeriod; // e.g., 3 days = 259200 seconds

        if (initialProposalQuorumThreshold > 1000) revert QuorumThresholdExceedsMax();
        proposalQuorumThreshold = initialProposalQuorumThreshold; // e.g., 400 (40% * 10)

        feePerEvolution = initialFeePerEvolution; // e.g., 0.01 ETH

        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- IERC721 Minimal Implementation ---

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert ZeroAddressNotAllowed();
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _tokenOwners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert NotApprovedOrOwner();
        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) revert NotApprovedOrOwner();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == msg.sender) revert NotApprovedOrOwner();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert("ERC721: transfer to non ERC721Receiver implementer");
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        if (ownerOf(tokenId) != from) revert NotApprovedOrOwner();
        if (to == address(0)) revert ZeroAddressNotAllowed();

        if (msg.sender != from && !isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotApprovedOrOwner();
        }

        _tokenApprovals[tokenId] = address(0); // Clear approval
        _balanceOf[from]--;
        _balanceOf[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // @dev Fallback for `safeTransferFrom` to check if recipient can receive ERC721 tokens.
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private view returns (bool)
    {
        if (to.code.length > 0) { // Check if `to` is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length > 0) {
                    revert(string(reason));
                } else {
                    revert("ERC721: transfer to non ERC721Receiver implementer (no data)");
                }
            }
        }
        return true; // `to` is an EOA
    }

    // @dev Implements `onERC721Received` for this contract to receive ERC721 tokens if needed.
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }


    // --- I. Core Echo Management & Minting (Dynamic NFT) ---

    /**
     * @dev Mints a new dynamic Echo NFT.
     *      Requires MINTER_ROLE. Mints to the caller by default.
     * @param initialPrompt A short string influencing the Echo's initial state.
     * @return The ID of the newly minted Echo.
     */
    function mintEcho(string memory initialPrompt)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        address recipient = msg.sender;

        // Deterministic initial state based on prompt hash for uniqueness
        uint256 promptHash = uint256(keccak256(abi.encodePacked(initialPrompt, block.timestamp, tokenId)));
        Echo storage newEcho = echoes[tokenId];
        newEcho.owner = recipient;
        newEcho.mintTimestamp = block.timestamp;
        newEcho.lastEvolutionTimestamp = uint224(block.timestamp);
        newEcho.evolutionCount = 0;
        newEcho.stateA = uint8(promptHash % _moodWords.length);
        newEcho.stateB = uint8((promptHash / _moodWords.length) % _colorWords.length);
        newEcho.stateC = uint8((promptHash / (_moodWords.length * _colorWords.length)) % _formWords.length);
        newEcho.personalSentimentScore = 0;
        newEcho.lastSubmittedSentimentBlock = 0;

        _balanceOf[recipient]++;
        _tokenOwners[tokenId] = recipient;

        emit Transfer(address(0), recipient, tokenId);
        emit EchoMinted(tokenId, recipient, initialPrompt);

        return tokenId;
    }

    /**
     * @dev Allows the owner of an Echo to burn it, removing it from existence.
     * @param tokenId The ID of the Echo to burn.
     */
    function burnEcho(uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId); // Checks existence and gets owner
        if (owner != msg.sender && !isApprovedForAll(owner, msg.sender)) revert NotApprovedOrOwner();

        _balanceOf[owner]--;
        delete _tokenOwners[tokenId];
        delete _tokenApprovals[tokenId];
        delete echoes[tokenId]; // Remove Echo data

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Returns all internal state variables of a given Echo.
     * @param tokenId The ID of the Echo.
     * @return owner The owner's address.
     * @return mintTimestamp The timestamp when the Echo was minted.
     * @return lastEvolutionTimestamp The timestamp of the last evolution.
     * @return evolutionCount The total number of times this Echo has evolved.
     * @return stateA, stateB, stateC Current state variables influencing its form and narrative.
     * @return personalSentimentScore The aggregated user sentiment for this Echo.
     */
    function getEchoState(uint256 tokenId)
        public
        view
        returns (
            address owner,
            uint256 mintTimestamp,
            uint256 lastEvolutionTimestamp,
            uint256 evolutionCount,
            uint8 stateA,
            uint8 stateB,
            uint8 stateC,
            int256 personalSentimentScore
        )
    {
        Echo storage echo = echoes[tokenId];
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        return (
            echo.owner,
            echo.mintTimestamp,
            echo.lastEvolutionTimestamp,
            echo.evolutionCount,
            echo.stateA,
            echo.stateB,
            echo.stateC,
            echo.personalSentimentScore
        );
    }

    /**
     * @dev Generates and returns a *dynamic* metadata URI for an Echo based on its current state.
     *      This would typically point to an API endpoint that serves JSON metadata.
     *      An off-chain service would fetch this URI and generate the metadata based on `getEchoState`
     *      and `retrieveCurrentNarrativeFragment`.
     * @param tokenId The ID of the Echo.
     * @return The metadata URI string.
     */
    function getEchoMetadataURI(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId), "/metadata.json"));
    }

    // --- II. Echo Evolution & State Dynamics ---

    /**
     * @dev Triggers an evolution cycle for a specific Echo.
     *      This function can be called by anyone but requires paying a fee.
     *      The Echo must be past its `epochEvolutionInterval` since its last evolution.
     *      The collected fee goes to the contract's balance, controlled by governance.
     * @param tokenId The ID of the Echo to evolve.
     */
    function triggerEchoEvolution(uint256 tokenId) public payable whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (msg.value < feePerEvolution) revert InsufficientFeeForEvolution();

        Echo storage echo = echoes[tokenId];
        if (block.timestamp < echo.lastEvolutionTimestamp + epochEvolutionInterval) {
            revert EchoEvolutionCooldownActive();
        }

        _evolveEchoState(tokenId);

        echo.lastEvolutionTimestamp = uint224(block.timestamp);
        echo.evolutionCount++;

        emit EchoEvolved(tokenId, echo.evolutionCount, echo.stateA, echo.stateB, echo.stateC);
    }

    /**
     * @dev Internal function to update an Echo's internal state variables based on various factors.
     *      This is the core deterministic evolution logic.
     * @param tokenId The ID of the Echo to evolve.
     */
    function _evolveEchoState(uint256 tokenId) internal {
        Echo storage echo = echoes[tokenId];

        // Simulate complex weights influencing evolution
        // Factors: Global AI sentiment, personal user sentiment, evolution count, time since last evolution.
        uint256 evolutionSeed = uint256(
            keccak256(abi.encodePacked(
                block.timestamp,
                globalAISentiment,
                echo.personalSentimentScore,
                echo.evolutionCount,
                tokenId
            ))
        );

        // Normalize sentiment scores for weighting
        uint256 normalizedAISentiment = globalAISentiment; // Assume 0-100
        // Map personal sentiment (-8M to +8M) to a smaller, positive range (e.g., 0-200) for weighting
        uint256 normalizedPersonalSentiment = uint256(int256(echo.personalSentimentScore) + 8_000_000) % 16_000_001;
        normalizedPersonalSentiment = normalizedPersonalSentiment / 80000; // Scale down to roughly 0-200

        // Calculate a combined influence score
        uint256 combinedInfluence = (normalizedAISentiment * aiInfluenceWeight) +
                                    (normalizedPersonalSentiment * (100 - aiInfluenceWeight));

        // Use the combined influence and seed to deterministically evolve states
        echo.stateA = uint8((evolutionSeed + combinedInfluence) % _moodWords.length);
        echo.stateB = uint8((evolutionSeed + (combinedInfluence / 2)) % _colorWords.length);
        echo.stateC = uint8((evolutionSeed + (combinedInfluence * 2)) % _formWords.length);

        // Gradually reduce personal sentiment over time or after evolution
        // For simplicity, let's halve it after each evolution to allow for new influence.
        echo.personalSentimentScore = int24(echo.personalSentimentScore / 2);

        // Record a hash of the current narrative fragment for history
        bytes32 currentNarrativeHash = keccak256(abi.encodePacked(retrieveCurrentNarrativeFragment(tokenId)));
        echo.narrativeHistoryHashes.push(currentNarrativeHash);
    }

    /**
     * @dev Governed function to adjust the minimum time required between evolutions for any given Echo.
     *      Requires GOV_EXECUTOR_ROLE (i.e., passed through governance proposal).
     * @param newInterval The new interval in seconds.
     */
    function adjustEpochInterval(uint256 newInterval) public onlyRole(GOV_EXECUTOR_ROLE) whenNotPaused {
        if (newInterval == 0) revert InvalidEpochInterval();
        epochEvolutionInterval = newInterval;
        emit EpochIntervalAdjusted(newInterval);
    }

    // --- III. External Data & AI Influence (Oracle) ---

    /**
     * @dev Submits a global AI sentiment score, influencing all Echoes' evolution.
     *      Callable *only by an authorized oracle*.
     *      The `sentimentScore` should be in a defined range (e.g., 0-100).
     * @param sentimentScore The new global AI sentiment score.
     */
    function submitGlobalAISentiment(uint256 sentimentScore) public onlyRole(ORACLE_ROLE) whenNotPaused {
        if (sentimentScore > 100) revert InvalidSentimentValue(); // Example range 0-100
        globalAISentiment = sentimentScore;
        emit GlobalAISentimentUpdated(sentimentScore, block.timestamp);
    }

    /**
     * @dev Governed function to adjust how much the global AI sentiment impacts Echo evolution.
     *      Requires GOV_EXECUTOR_ROLE.
     * @param newWeight The new weight (e.g., 0-100, where 100 means full influence).
     */
    function updateAIInfluenceWeight(uint256 newWeight) public onlyRole(GOV_EXECUTOR_ROLE) whenNotPaused {
        if (newWeight > 100) revert AIInfluenceWeightExceedsMax();
        aiInfluenceWeight = newWeight;
        emit AIInfluenceWeightUpdated(newWeight);
    }

    // --- IV. Narrative & Lore Generation ---

    /**
     * @dev Returns a unique, short textual fragment generated on-chain based on the Echo's current state.
     *      This is a deterministic combination of predefined words/phrases.
     * @param tokenId The ID of the Echo.
     * @return The generated narrative fragment.
     */
    function retrieveCurrentNarrativeFragment(uint256 tokenId) public view returns (string memory) {
        Echo storage echo = echoes[tokenId];
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        // Ensure indices are within bounds
        uint8 moodIndex = echo.stateA % _moodWords.length;
        uint8 colorIndex = echo.stateB % _colorWords.length;
        uint8 formIndex = echo.stateC % _formWords.length;

        // Concatenate strings for a simple narrative fragment
        return string(abi.encodePacked(
            "A ",
            _moodWords[moodIndex],
            " whisper of ",
            _colorWords[colorIndex],
            " as a ",
            _formWords[formIndex],
            "."
        ));
    }

    /**
     * @dev Returns an array of hashes of past narrative fragments or evolution events.
     *      To reconstruct the full narrative, an off-chain service would map these hashes
     *      to the actual historical fragments or use the historical state data.
     * @param tokenId The ID of the Echo.
     * @return An array of bytes32 hashes representing the Echo's narrative history.
     */
    function getNarrativeHistory(uint256 tokenId) public view returns (bytes32[] memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return echoes[tokenId].narrativeHistoryHashes;
    }

    // --- V. Community Interaction & Sentiment ---

    /**
     * @dev Allows users to submit a sentiment score for an Echo, influencing its *personal* evolution path.
     *      Sentiment is aggregated and contributes to the Echo's `personalSentimentScore`.
     *      A cooldown is implemented per Echo to prevent spamming.
     * @param tokenId The ID of the Echo.
     * @param sentimentValue An integer from -10 to 10, representing user sentiment.
     */
    function submitUserSentiment(uint256 tokenId, int8 sentimentValue) public whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (sentimentValue < -10 || sentimentValue > 10) revert InvalidSentimentValue();

        Echo storage echo = echoes[tokenId];

        // Cooldown for sentiment submission per Echo
        if (block.number <= echo.lastSubmittedSentimentBlock + _SENTIMENT_COOLDOWN_BLOCKS) {
            revert SentimentCooldownActive();
        }

        echo.personalSentimentScore += sentimentValue;
        echo.lastSubmittedSentimentBlock = uint64(block.number);

        emit UserSentimentSubmitted(tokenId, msg.sender, sentimentValue);
    }

    /**
     * @dev Returns the aggregated community sentiment score for a specific Echo.
     * @param tokenId The ID of the Echo.
     * @return The personal sentiment score.
     */
    function getEchoCommunitySentiment(uint256 tokenId) public view returns (int256) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return echoes[tokenId].personalSentimentScore;
    }

    // --- VI. Decentralized Governance (Policy & Parameters) ---

    /**
     * @dev Stakes ERC20 governance tokens to gain voting power and proposal rights.
     *      (This is a simplified internal tracking. In a real system, it would interact with an external IERC20 contract).
     * @param amount The amount of tokens to stake.
     */
    function stakeGovernanceTokens(uint256 amount) public whenNotPaused {
        if (amount == 0) revert CannotStakeZeroTokens();
        // In a real implementation: `IERC20(governanceTokenAddress).transferFrom(msg.sender, address(this), amount);`
        stakedGovernanceTokens[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Unstakes ERC20 governance tokens.
     *      Users cannot unstake if they have active votes on pending/active proposals.
     * @param amount The amount of tokens to unstake.
     */
    function unstakeGovernanceTokens(uint256 amount) public whenNotPaused {
        if (amount == 0) revert CannotStakeZeroTokens();
        if (stakedGovernanceTokens[msg.sender] < amount) revert InsufficientStakedTokens();

        // Check for active votes (simplified: iterate through proposals)
        for (uint252 i = 1; i <= _proposalCounter; i++) {
            Proposal storage p = proposals[i];
            // Check if proposal is active, and if msg.sender (or their delegate) has voted
            if (p.creationTime != 0 && p.votingDeadline > block.timestamp) {
                address effectiveVoter = votingDelegates[msg.sender] == address(0) ? msg.sender : votingDelegates[msg.sender];
                if (p.hasVoted[effectiveVoter]) {
                    revert CannotUnstakeActiveVote();
                }
            }
        }

        stakedGovernanceTokens[msg.sender] -= amount;
        // In a real implementation: `IERC20(governanceTokenAddress).transfer(msg.sender, amount);`
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Delegates voting power to another address.
     * @param delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address delegatee) public {
        if (delegatee == address(0)) revert ZeroAddressNotAllowed();
        votingDelegates[msg.sender] = delegatee;
        emit VotingPowerDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Internal helper to get effective voting power, considering delegation.
     */
    function _getVotingPower(address voter) internal view returns (uint256) {
        address effectiveVoter = votingDelegates[voter] == address(0) ? voter : votingDelegates[voter];
        return stakedGovernanceTokens[effectiveVoter];
    }

    /**
     * @dev Proposes a change to a system-wide evolution parameter.
     *      Requires GOV_PROPOSER_ROLE and `minStakeToPropose`.
     * @param parameterKey Identifier for the parameter (e.g., keccak256("AI_INFLUENCE_WEIGHT")).
     * @param newValue The new value for the parameter.
     * @return The ID of the created proposal.
     */
    function proposeEvolutionParameterChange(bytes32 parameterKey, uint256 newValue)
        public
        onlyRole(GOV_PROPOSER_ROLE)
        whenNotPaused
        returns (uint256)
    {
        if (_getVotingPower(msg.sender) < minStakeToPropose) revert InsufficientStakeForProposal();

        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        Proposal storage newProposal = proposals[proposalId];
        newProposal.parameterKey = parameterKey;
        newProposal.newValue = newValue;
        newProposal.creationTime = block.timestamp;
        newProposal.votingDeadline = block.timestamp + proposalVotingPeriod;
        newProposal.executed = false;

        emit ProposalCreated(proposalId, msg.sender, parameterKey, newValue, newProposal.votingDeadline);
        return proposalId;
    }

    /**
     * @dev Allows stakers to vote on active proposals.
     * @param proposalId The ID of the proposal.
     * @param support True for "for" votes, false for "against" votes.
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.creationTime == 0) revert ProposalNotFound();
        if (block.timestamp > proposal.votingDeadline) revert InvalidProposalState(); // Voting period ended
        
        address effectiveVoter = votingDelegates[msg.sender] == address(0) ? msg.sender : votingDelegates[msg.sender];
        if (proposal.hasVoted[effectiveVoter]) revert ProposalAlreadyVoted();

        uint256 voterPower = _getVotingPower(msg.sender);
        if (voterPower == 0) revert InsufficientStakeForVoting();

        proposal.hasVoted[effectiveVoter] = true; // Record vote for effective voter

        if (support) {
            proposal.forVotes += voterPower;
        } else {
            proposal.againstVotes += voterPower;
        }

        emit VoteCast(proposalId, msg.sender, support, voterPower);
    }

    /**
     * @dev Retrieves the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The current state (Pending, Active, Succeeded, Defeated, Executed).
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.creationTime == 0) return ProposalState.Pending;

        if (proposal.executed) return ProposalState.Executed;
        if (block.timestamp <= proposal.votingDeadline) return ProposalState.Active;

        // Voting period ended, determine outcome
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        if (totalVotes == 0) return ProposalState.Defeated; // No votes, cannot succeed

        // Check quorum: percentage of total votes needed to pass for "for" votes
        // (proposal.forVotes * 1000) / totalVotes gives percentage out of 1000.
        if (proposal.forVotes >= proposal.againstVotes &&
            (proposal.forVotes * 1000) / totalVotes >= proposalQuorumThreshold) {
             return ProposalState.Succeeded;
        }
        return ProposalState.Defeated;
    }


    /**
     * @dev Executes a passed governance proposal.
     *      Requires GOV_EXECUTOR_ROLE.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) public onlyRole(GOV_EXECUTOR_ROLE) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.creationTime == 0) revert ProposalNotFound();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (getProposalState(proposalId) != ProposalState.Succeeded) revert ProposalNotExecutable();

        // Apply the proposed change based on parameterKey
        bytes32 key = proposal.parameterKey;
        if (key == keccak256("AI_INFLUENCE_WEIGHT")) {
            updateAIInfluenceWeight(proposal.newValue); // This will re-check weight bounds
        } else if (key == keccak256("EPOCH_EVOLUTION_INTERVAL")) {
            adjustEpochInterval(proposal.newValue); // This will re-check interval bounds
        } else if (key == keccak256("MIN_STAKE_TO_PROPOSE")) {
            minStakeToPropose = proposal.newValue;
        } else if (key == keccak256("PROPOSAL_VOTING_PERIOD")) {
            proposalVotingPeriod = proposal.newValue;
        } else if (key == keccak256("PROPOSAL_QUORUM_THRESHOLD")) {
            if (proposal.newValue > 1000) revert QuorumThresholdExceedsMax();
            proposalQuorumThreshold = proposal.newValue;
        } else if (key == keccak256("FEE_PER_EVOLUTION")) {
            feePerEvolution = proposal.newValue;
        } else {
            revert("Unknown or unsupported parameter key."); // Handle unknown parameters
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    // --- VII. System Maintenance & Utility ---

    /**
     * @dev Allows the DAO/governed system to withdraw collected protocol fees.
     *      Requires GOV_EXECUTOR_ROLE.
     * @param recipient The address to send the collected fees to.
     */
    function withdrawProtocolFees(address recipient) public onlyRole(GOV_EXECUTOR_ROLE) whenNotPaused {
        if (recipient == address(0)) revert ZeroAddressNotAllowed();
        uint256 balance = address(this).balance;
        if (balance == 0) revert NotEnoughFeesToWithdraw();

        (bool success, ) = recipient.call{value: balance}("");
        if (!success) revert WithdrawalFailed();

        emit FeesWithdrawn(recipient, balance);
    }

    /**
     * @dev Allows a designated role (e.g., admin or multi-sig) to pause critical functions.
     *      Requires PAUSER_ROLE.
     */
    function emergencyPause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Allows to unpause the system.
     *      Requires PAUSER_ROLE.
     */
    function unpauseSystem() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Allows the DAO/governed system to set the base URI for metadata.
     *      Requires GOV_EXECUTOR_ROLE.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyRole(GOV_EXECUTOR_ROLE) {
        _baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // Fallback function to receive Ether for fees
    receive() external payable {}
}
```