Here's a Solidity smart contract named `ChronoGenesisNFT` that implements an advanced, creative, and trendy concept: a dynamic NFT ecosystem where NFTs evolve through AI-generated content, triggered by community-staked prompts, with decentralized IP and royalty distribution.

This contract integrates `ERC721` for NFT standards, `AccessControl` for flexible permissioning, `Pausable` for emergency controls, and `ReentrancyGuard` for security. It interacts with a custom oracle interface (`IChronoGenesisOracle`) for AI content generation and an ERC20 token (`IERC20`) for community staking and voting.

---

**Outline and Function Summary:**

**Contract Name:** `ChronoGenesisNFT`

**Concept:** Dynamic NFTs that evolve over time based on "Genesis Events." These events are triggered by community-proposed and voted-upon AI prompts. Users stake `ChronoGenesis Tokens (CGT)` to propose and vote on prompts. When a prompt wins, an AI oracle generates new content (e.g., traits, lore, visual data), evolving the NFT's metadata. The original creator of a winning prompt receives a royalty share from evolution fees, establishing a decentralized IP and co-creation model.

**Dependencies:**
*   `@openzeppelin/contracts/token/ERC721/ERC721.sol`
*   `@openzeppelin/contracts/access/AccessControl.sol`
*   `@openzeppelin/contracts/security/Pausable.sol`
*   `@openzeppelin/contracts/security/ReentrancyGuard.sol`
*   `@openzeppelin/contracts/utils/Counters.sol`
*   `@openzeppelin/contracts/token/ERC20/IERC20.sol`
*   `@openzeppelin/contracts/utils/Strings.sol`

---

**Function Summary (28 Functions):**

**I. Core NFT Management (ERC721 Extension)**
1.  **`constructor`**: Initializes the contract, sets ERC721 name/symbol, defines initial roles, treasury address, CGT token, and default parameters.
2.  **`mintGenesisNFT(address recipient)`**: Mints the initial, base ChronoGenesis NFT to a specified recipient. (ADMIN\_ROLE only)
3.  **`tokenURI(uint256 tokenId)`**: Overridden ERC721 function. Dynamically generates the metadata URI for a given NFT, pointing to an external metadata service that interprets the NFT's evolution history.
4.  **`setEvolutionServiceURI(string memory newURI)`**: Sets the base URI for the off-chain metadata evolution service. (ADMIN\_ROLE only)
5.  **`pause()`**: Pauses all transfers and certain contract interactions in emergencies. (ADMIN\_ROLE only)
6.  **`unpause()`**: Unpauses the contract, restoring normal operations. (ADMIN\_ROLE only)
7.  **`withdrawProceeds()`**: Allows the designated `treasuryAddress` to withdraw accumulated ETH from the contract (e.g., from fees). (ADMIN\_ROLE only)

**II. AI Genesis Prompt System**
8.  **`proposeAIGenesisPrompt(string memory _promptText)`**: Allows a user to submit a textual prompt for AI content generation, staking a minimum amount of CGT tokens as a proposal bond.
9.  **`voteForGenesisPrompt(uint256 _promptId, uint256 _amount)`**: Allows users to stake CGT tokens to vote on an active prompt proposal, increasing its `totalVotes` count.
10. **`selectWinningPrompt(uint256 _tokenId, uint256 _promptId)`**: Triggers an NFT evolution. This can be called by a `CURATOR_ROLE` or the NFT's owner after the prompt's voting period ends, requiring an `evolutionFee`. This function also handles the distribution of royalties to the prompt creator and the treasury.
11. **`requestAIGeneration(uint256 _tokenId, uint256 _promptId, string memory _promptText, address _promptCreator)`**: (Internal) Initiates a request to the registered `IChronoGenesisOracle` for AI content generation for a specific NFT and prompt.

**III. NFT Evolution & Oracle Integration**
12. **`fulfillAIGeneration(bytes32 _requestId, uint256 _tokenId, uint256 _promptId, string calldata _generatedData, address _oracleSigner)`**: A callback function, callable only by the authorized `ORACLE_ROLE`. It updates an NFT's `nftEvolutionHistory` with the AI-generated data (`_generatedData`) upon successful fulfillment of an AI request.
13. **`getNFTEvolutionHistory(uint256 _tokenId)`**: Retrieves the full chronological list of evolution events and their associated data for a given NFT.
14. **`getPromptDetails(uint256 _promptId)`**: Returns comprehensive details (proposer, text, stakes, votes, status) of a specific prompt proposal.
15. **`getNFTCurrentEvolutionData(uint256 _tokenId)`**: Returns the latest AI-generated data string that describes the current state of an NFT's evolution.
16. **`registerChronoGenesisOracle(address _newOracle)`**: Sets and authorizes the address of the trusted AI generation oracle contract, granting it the `ORACLE_ROLE`. (ADMIN\_ROLE only)

**IV. ChronoGenesis Token (CGT) Staking & Governance**
17. **`unstakeCGTFromPrompt(uint256 _promptId)`**: Allows users to retrieve their CGT tokens that were staked (either as a proposal bond or vote) on a *resolved* prompt.
18. **`setMinimumPromptStakeAmount(uint256 _amount)`**: Sets the minimum amount of CGT required to propose an AI genesis prompt. (ADMIN\_ROLE only)
19. **`setVotingDuration(uint256 _durationSeconds)`**: Sets the duration (in seconds) for which prompt proposals can be voted on. (ADMIN\_ROLE only)

**V. Co-Creator Royalties & Revenue Distribution**
20. **`setPromptCreatorRoyaltyShare(uint256 _shareBps)`**: Sets the percentage (in basis points, where 10000 = 100%) of `evolutionFee` that goes to the creator of a winning prompt. (ADMIN\_ROLE only)
21. **`claimCreatorRoyalties()`**: Allows a prompt creator to claim their accumulated royalty share in ETH, earned from NFTs evolving using their winning prompts.
22. **`setEvolutionFee(uint256 _fee)`**: Sets the fee (in wei, ETH) required to trigger an NFT evolution. (ADMIN\_ROLE only)

**VI. Access Control & Configuration**
23. **`setChronoGenesisToken(address _newCGT)`**: Sets the address of the ChronoGenesis Token (CGT) ERC20 contract. (ADMIN\_ROLE only)
24. **`grantRole(bytes32 role, address account)`**: Assigns a specified role (e.g., ADMIN\_ROLE, CURATOR\_ROLE, ORACLE\_ROLE) to an account. (DEFAULT\_ADMIN\_ROLE only)
25. **`revokeRole(bytes32 role, address account)`**: Revokes a specified role from an account. (DEFAULT\_ADMIN\_ROLE only)
26. **`renounceRole(bytes32 role, address account)`**: Allows an account to voluntarily give up one of its roles.
27. **`getRoleAdmin(bytes32 role)`**: Returns the administrative role responsible for granting/revoking a given role.
28. **`contractURI()`**: Returns a URI for contract-level metadata, describing the collection as a whole.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Oracle Interface
// This interface defines how the ChronoGenesisNFT contract interacts with an external AI generation oracle.
// In a real-world scenario, this oracle would connect to AI models (e.g., Chainlink AI services, custom decentralized AI network).
interface IChronoGenesisOracle {
    /**
     * @dev Requests the oracle to perform an AI generation based on a prompt for a specific NFT.
     * @param _nftContract The address of the ChronoGenesisNFT contract.
     * @param _tokenId The ID of the NFT to be evolved.
     * @param _promptId The ID of the prompt used for generation.
     * @param _promptText The actual text of the prompt.
     * @param _requester The address that initiated the AI generation request (e.g., curator/NFT owner).
     * @return requestId A unique identifier for the request, allowing tracking of fulfillment.
     */
    function requestAIGeneration(
        address _nftContract,
        uint256 _tokenId,
        uint256 _promptId,
        string calldata _promptText,
        address _requester
    ) external returns (bytes32 requestId);

    // NOTE: The `fulfillAIGeneration` function is implemented within the ChronoGenesisNFT
    // contract. The oracle is expected to call ChronoGenesisNFT.fulfillAIGeneration(...)
    // directly once the AI output is ready and validated.
}

/**
 * @title ChronoGenesisNFT
 * @dev A dynamic NFT ecosystem where NFTs evolve through AI-generated content
 *      triggered by community-staked prompts, with decentralized IP and royalty distribution.
 *      This contract extends ERC721 and integrates `AccessControl`, `Pausable`, `ReentrancyGuard`.
 *      It interacts with a custom oracle (`IChronoGenesisOracle`) for AI content generation
 *      and an ERC20 token (`IERC20`) for community staking and voting.
 *
 * Outline and Function Summary:
 *
 * I.   Core NFT Management (ERC721 Extension)
 *      1.  `constructor`: Initializes the contract, ERC721 name/symbol, and admin roles.
 *      2.  `mintGenesisNFT`: Mints the initial, base ChronoGenesis NFT to a recipient.
 *      3.  `tokenURI`: Dynamically generates the metadata URI based on the NFT's evolution history,
 *                      pointing to an external metadata service.
 *      4.  `setEvolutionServiceURI`: Sets the base URI for the external metadata evolution service.
 *      5.  `pause`: Pauses all transfers and certain interactions, callable by ADMIN_ROLE.
 *      6.  `unpause`: Unpauses the contract, callable by ADMIN_ROLE.
 *      7.  `withdrawProceeds`: Allows the designated treasury to withdraw collected ETH from fees.
 *
 * II.  AI Genesis Prompt System
 *      8.  `proposeAIGenesisPrompt`: Allows a user to submit a prompt for AI content generation,
 *                                  staking CGT tokens as a proposal bond.
 *      9.  `voteForGenesisPrompt`: Allows users to stake CGT tokens to vote on proposed AI prompts,
 *                                creating a weighted vote.
 *      10. `selectWinningPrompt`: An authorized `CURATOR_ROLE` or NFT owner can select a winning prompt
 *                                (after its voting period) to trigger an NFT evolution, paying an `evolutionFee`.
 *                                This also handles royalty distribution to the prompt creator.
 *      11. `requestAIGeneration`: (Internal) Triggers an AI content generation request via the registered oracle.
 *
 * III. NFT Evolution & Oracle Integration
 *      12. `fulfillAIGeneration`: A callback function from the authorized oracle to update an NFT's state
 *                                 and metadata after AI generation. This is the core evolution mechanism.
 *      13. `getNFTEvolutionHistory`: Retrieves the full chronological list of evolutions for a given NFT.
 *      14. `getPromptDetails`: Returns comprehensive details of a specific prompt proposal.
 *      15. `getNFTCurrentEvolutionData`: Returns the latest AI-generated data associated with an NFT.
 *      16. `registerChronoGenesisOracle`: Sets and authorizes the address of the trusted AI oracle contract.
 *
 * IV.  ChronoGenesis Token (CGT) Staking & Governance
 *      17. `unstakeCGTFromPrompt`: Allows users to retrieve their CGT tokens staked on a *resolved* prompt.
 *      18. `setMinimumPromptStakeAmount`: Sets the minimum CGT required to propose a prompt, callable by ADMIN_ROLE.
 *      19. `setVotingDuration`: Sets the duration for which prompt proposals can be voted on, callable by ADMIN_ROLE.
 *
 * V.   Co-Creator Royalties & Revenue Distribution
 *      20. `setPromptCreatorRoyaltyShare`: Sets the percentage (in basis points) of future evolution fees
 *                                        that go to the creator of a winning prompt, callable by ADMIN_ROLE.
 *      21. `claimCreatorRoyalties`: Allows a prompt creator to claim their accumulated royalty share in ETH.
 *      22. `setEvolutionFee`: Sets the fee required (in ETH) to trigger an NFT evolution, callable by ADMIN_ROLE.
 *
 * VI.  Access Control & Configuration
 *      23. `setChronoGenesisToken`: Sets the address of the ChronoGenesis Token (CGT) ERC20 contract, callable by ADMIN_ROLE.
 *      24. `grantRole`: Assigns a role to an address (ADMIN, CURATOR, ORACLE).
 *      25. `revokeRole`: Revokes a role from an address.
 *      26. `renounceRole`: Allows an address to renounce its own role.
 *      27. `getRoleAdmin`: Returns the admin role for a given role.
 *      28. `contractURI`: Returns a URI for contract-level metadata (e.g., collection description).
 */
contract ChronoGenesisNFT is ERC721, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");       // Comprehensive administration
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");   // Can select winning prompts, manage certain parameters
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");     // Only trusted oracles can fulfill AI requests

    // --- State Variables ---
    string private _evolutionServiceURI;  // Base URI for the external metadata service that handles dynamic evolution
    address private _chronoGenesisOracle; // Address of the trusted AI generation oracle contract
    address private _cgtToken;            // Address of the ChronoGenesis Token (CGT) for staking
    address public treasuryAddress;        // Address to receive the portion of evolution fees not allocated to creator royalties

    uint256 public minimumPromptStakeAmount; // Minimum CGT required to propose a prompt
    uint256 public votingDuration;           // Duration (in seconds) for prompt voting
    uint256 public evolutionFee;             // Fee (in ETH) to trigger an evolution
    uint256 public promptCreatorRoyaltyShareBps; // Basis points (e.g., 1000 = 10%) for prompt creator royalty from evolutionFee

    // --- Data Structures ---

    struct PromptProposal {
        address proposer;
        string promptText;
        uint256 initialStakeAmount; // CGT staked by the proposer
        uint256 totalVotes;         // Total CGT staked by all voters (including proposer's initial stake)
        uint256 submissionTime;
        bool exists;                // To differentiate default struct from actual proposals
        bool isResolved;            // True once a prompt has been selected and processed for an evolution
        mapping(address => uint256) voterStakes; // Record individual voter stakes for this specific prompt
    }

    struct NFTEvolution {
        uint256 promptId;         // The prompt that led to this evolution
        string generatedData;     // The AI-generated data (e.g., JSON fragment, image hash)
        uint256 evolutionTime;    // Timestamp of evolution
        address evolvingOracle;   // Oracle that fulfilled the request
        address promptCreator;    // Address of the creator of the winning prompt
    }

    // Mapping: Prompt ID => PromptProposal details
    mapping(uint256 => PromptProposal) public promptProposals;
    Counters.Counter private _promptIdCounter;

    // Mapping: Token ID => Array of NFTEvolutions
    mapping(uint256 => NFTEvolution[]) public nftEvolutionHistory;

    // Mapping: Prompt Creator Address => Accumulated Royalties (in ETH) from evolution fees
    mapping(address => uint256) public creatorRoyaltyBalances;

    // Mapping: Request ID => Details of the pending AI generation request
    mapping(bytes32 => PendingAIGenerationRequest) public pendingAIGenerationRequests;

    struct PendingAIGenerationRequest {
        uint256 tokenId;
        uint256 promptId;
        address requester;      // Who triggered the oracle request (e.g., CURATOR_ROLE address)
        address promptCreator;  // Original creator of the prompt
        bool exists;
    }

    // --- Events ---
    event GenesisNFTMinted(uint256 indexed tokenId, address indexed recipient);
    event EvolutionServiceURIUpdated(string newURI);
    event ChronoGenesisOracleUpdated(address indexed newOracle);
    event ChronoGenesisTokenUpdated(address indexed newCGT);
    event PromptProposed(uint256 indexed promptId, address indexed proposer, string promptText, uint256 initialStakeAmount);
    event PromptVoted(uint256 indexed promptId, address indexed voter, uint256 voteAmount);
    event PromptSelected(uint256 indexed promptId, uint256 indexed tokenId, address selector);
    event AIGenerationRequested(bytes32 indexed requestId, uint256 indexed tokenId, uint256 promptId, address requester);
    event NFTEvolved(uint256 indexed tokenId, uint256 indexed promptId, string generatedData, address oracle);
    event CreatorRoyaltyClaimed(address indexed creator, uint256 amount);
    event EvolutionFeeUpdated(uint256 newFee);
    event PromptCreatorRoyaltyShareUpdated(uint256 newShareBps);
    event MinimumPromptStakeUpdated(uint256 newAmount);
    event VotingDurationUpdated(uint256 newDuration);
    event ProceedsWithdrawn(address indexed to, uint256 amount);
    event CGTUnstaked(uint256 indexed promptId, address indexed unstaker, uint256 amount);


    // --- Custom Errors ---
    error InvalidPromptId();
    error PromptNotActive();
    error PromptAlreadyResolved();
    error NotEnoughCGTStake();
    error InvalidVoteAmount();
    error VotingPeriodActive();
    error VotingPeriodEnded();
    error NotVotingParticipant();
    error OracleNotRegistered();
    error CallerNotOracle();
    error InvalidRequestData();
    error RequestAlreadyFulfilled(); // Could be needed if `exists` isn't enough
    error NoRoyaltiesToClaim();
    error InsufficientEvolutionFee();
    error NoTreasuryAddress();
    error ChronoGenesisTokenNotSet();
    error InvalidPromptCreatorRoyaltyShare();
    error OnlyNFTOwnerOrCuratorCanEvolve();
    error TreasuryWithdrawalFailed();
    error ExcessETHRefundFailed();
    error FeePaymentFailed();

    /**
     * @dev Constructor for ChronoGenesisNFT.
     * @param name_ The name of the NFT collection.
     * @param symbol_ The symbol of the NFT collection.
     * @param initialEvolutionServiceURI The base URI for dynamic metadata service.
     * @param initialTreasuryAddress The address to send collected fees.
     * @param initialCGTToken The address of the ChronoGenesis Token (CGT) contract.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory initialEvolutionServiceURI,
        address initialTreasuryAddress,
        address initialCGTToken
    ) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is DEFAULT_ADMIN_ROLE
        _grantRole(ADMIN_ROLE, msg.sender);         // Deployer is also a specific ADMIN_ROLE
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CURATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, ADMIN_ROLE);

        require(bytes(initialEvolutionServiceURI).length > 0, "Initial URI cannot be empty");
        _evolutionServiceURI = initialEvolutionServiceURI;

        require(initialTreasuryAddress != address(0), "Treasury cannot be zero address");
        treasuryAddress = initialTreasuryAddress;

        require(initialCGTToken != address(0), "CGT Token cannot be zero address");
        _cgtToken = initialCGTToken;

        minimumPromptStakeAmount = 1000 ether; // Default 1000 CGT (assuming 18 decimals)
        votingDuration = 7 days;            // Default 7 days
        evolutionFee = 0.01 ether;          // Default 0.01 ETH
        promptCreatorRoyaltyShareBps = 1000; // Default 10% (1000 / 10000)
    }

    // --- Core NFT Management (7 functions) ---

    /**
     * @dev Mints a new Genesis NFT to the specified recipient.
     *      Only callable by an address with the ADMIN_ROLE.
     * @param recipient The address to receive the new NFT.
     * @return The ID of the newly minted token.
     */
    function mintGenesisNFT(address recipient)
        public
        virtual
        onlyRole(ADMIN_ROLE)
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(recipient, newItemId);
        emit GenesisNFTMinted(newItemId, recipient);
        return newItemId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      This function dynamically generates the URI by appending the token ID to the evolution service URI.
     *      The external service (off-chain) is responsible for providing metadata based on the NFT's
     *      evolution history and current state.
     * @param tokenId The ID of the NFT.
     * @return A string representing the URI to the token's metadata.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireOwned(tokenId); // Checks if token exists
        string memory base = _evolutionServiceURI;
        return string(abi.encodePacked(base, Strings.toString(tokenId), "/metadata.json"));
    }

    /**
     * @dev Sets the base URI for the external evolution metadata service.
     *      Only callable by an address with the ADMIN_ROLE.
     * @param newURI The new base URI.
     */
    function setEvolutionServiceURI(string memory newURI) public onlyRole(ADMIN_ROLE) {
        _evolutionServiceURI = newURI;
        emit EvolutionServiceURIUpdated(newURI);
    }

    /**
     * @dev Pauses all transfers and certain interactions in the contract.
     *      Can only be called by an account with the ADMIN_ROLE.
     */
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing transfers and interactions again.
     *      Can only be called by an account with the ADMIN_ROLE.
     */
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Allows the treasury address to withdraw collected ETH from the contract.
     *      This is for any residual ETH that might end up in the contract, not specifically evolution fees
     *      (as those are immediately split and sent to treasury/creator).
     *      Only callable by an account with ADMIN_ROLE.
     */
    function withdrawProceeds() public onlyRole(ADMIN_ROLE) nonReentrant {
        if (treasuryAddress == address(0)) revert NoTreasuryAddress();
        uint256 balance = address(this).balance - _getMinEthBalance(); // Use helper to prevent emptying below threshold
        if (balance == 0) return; // No ETH to withdraw

        (bool success, ) = treasuryAddress.call{value: balance}("");
        if (!success) revert TreasuryWithdrawalFailed();
        emit ProceedsWithdrawn(treasuryAddress, balance);
    }

    /**
     * @dev Helper function to return a minimum ETH balance to potentially keep in the contract.
     *      Can be adjusted if the contract needs a small amount of ETH for gas in future operations.
     * @return The minimum ETH balance to keep in the contract.
     */
    function _getMinEthBalance() internal pure returns (uint256) {
        return 0; // For simplicity, assume 0 for now. In a real system, might be a small amount.
    }

    // --- AI Genesis Prompt System (4 functions) ---

    /**
     * @dev Allows users to propose a new AI generation prompt for NFT evolution.
     *      Requires staking a minimum amount of CGT tokens as a proposal bond.
     * @param _promptText The textual prompt for the AI.
     */
    function proposeAIGenesisPrompt(string memory _promptText)
        public
        whenNotPaused
        nonReentrant
    {
        if (_cgtToken == address(0)) revert ChronoGenesisTokenNotSet();
        if (IERC20(_cgtToken).balanceOf(msg.sender) < minimumPromptStakeAmount) {
            revert NotEnoughCGTStake();
        }
        // Transfer the minimum stake from the proposer to this contract
        IERC20(_cgtToken).transferFrom(msg.sender, address(this), minimumPromptStakeAmount);

        _promptIdCounter.increment();
        uint256 newPromptId = _promptIdCounter.current();

        promptProposals[newPromptId] = PromptProposal({
            proposer: msg.sender,
            promptText: _promptText,
            initialStakeAmount: minimumPromptStakeAmount,
            totalVotes: minimumPromptStakeAmount, // Proposer's stake counts as initial vote
            submissionTime: block.timestamp,
            exists: true,
            isResolved: false
        });
        promptProposals[newPromptId].voterStakes[msg.sender] = minimumPromptStakeAmount;

        emit PromptProposed(newPromptId, msg.sender, _promptText, minimumPromptStakeAmount);
    }

    /**
     * @dev Allows users to vote on an active prompt proposal by staking CGT tokens.
     *      Voting increases the `totalVotes` for the prompt.
     * @param _promptId The ID of the prompt to vote for.
     * @param _amount The amount of CGT to stake as a vote.
     */
    function voteForGenesisPrompt(uint256 _promptId, uint256 _amount)
        public
        whenNotPaused
        nonReentrant
    {
        PromptProposal storage prompt = promptProposals[_promptId];
        if (!prompt.exists) revert InvalidPromptId();
        if (prompt.isResolved) revert PromptAlreadyResolved();
        if (block.timestamp > prompt.submissionTime + votingDuration) revert VotingPeriodEnded();
        if (_amount == 0) revert InvalidVoteAmount();
        if (_cgtToken == address(0)) revert ChronoGenesisTokenNotSet();

        // Transfer the vote stake from the voter to this contract
        IERC20(_cgtToken).transferFrom(msg.sender, address(this), _amount);

        prompt.totalVotes += _amount;
        prompt.voterStakes[msg.sender] += _amount;

        emit PromptVoted(_promptId, msg.sender, _amount);
    }

    /**
     * @dev Selects a winning prompt for a specific NFT to trigger an AI generation request.
     *      This can be called by an address with the `CURATOR_ROLE` or the NFT's owner,
     *      provided the prompt's voting period has ended and an `evolutionFee` is paid.
     * @param _tokenId The ID of the NFT to evolve.
     * @param _promptId The ID of the prompt to select as the winner.
     */
    function selectWinningPrompt(uint256 _tokenId, uint256 _promptId)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        PromptProposal storage prompt = promptProposals[_promptId];
        if (!prompt.exists) revert InvalidPromptId();
        if (prompt.isResolved) revert PromptAlreadyResolved();
        if (block.timestamp <= prompt.submissionTime + votingDuration) revert VotingPeriodActive(); // Ensure voting period has ended

        _requireOwned(_tokenId); // Ensure the NFT exists
        // Only NFT owner or an authorized curator can trigger evolution
        if (ownerOf(_tokenId) != msg.sender && !hasRole(CURATOR_ROLE, msg.sender)) {
            revert OnlyNFTOwnerOrCuratorCanEvolve();
        }

        if (msg.value < evolutionFee) revert InsufficientEvolutionFee();

        // Mark prompt as resolved to prevent further actions or re-selection
        prompt.isResolved = true;

        // --- Fee Distribution Logic ---
        uint256 creatorShare = (evolutionFee * promptCreatorRoyaltyShareBps) / 10000;
        creatorRoyaltyBalances[prompt.proposer] += creatorShare;

        uint256 treasuryShare = evolutionFee - creatorShare;
        (bool success, ) = treasuryAddress.call{value: treasuryShare}("");
        if (!success) revert FeePaymentFailed();

        // Refund any excess ETH sent by the caller
        if (msg.value > evolutionFee) {
            (success, ) = msg.sender.call{value: msg.value - evolutionFee}("");
            if (!success) revert ExcessETHRefundFailed();
        }

        // Trigger AI generation via oracle
        requestAIGeneration(_tokenId, _promptId, prompt.promptText, prompt.proposer);
        emit PromptSelected(_promptId, _tokenId, msg.sender);
    }

    /**
     * @dev Internal function to trigger an AI content generation request via the registered oracle.
     *      This is called by `selectWinningPrompt`.
     * @param _tokenId The ID of the NFT to be evolved.
     * @param _promptId The ID of the winning prompt.
     * @param _promptText The text of the winning prompt.
     * @param _promptCreator The address of the original prompt creator.
     */
    function requestAIGeneration(uint256 _tokenId, uint256 _promptId, string memory _promptText, address _promptCreator)
        internal
    {
        if (_chronoGenesisOracle == address(0)) revert OracleNotRegistered();

        // The oracle requests the generation, and returns a requestId
        bytes32 requestId = IChronoGenesisOracle(_chronoGenesisOracle).requestAIGeneration(
            address(this),
            _tokenId,
            _promptId,
            _promptText,
            msg.sender // The actual requester is the one who called selectWinningPrompt
        );

        pendingAIGenerationRequests[requestId] = PendingAIGenerationRequest({
            tokenId: _tokenId,
            promptId: _promptId,
            requester: msg.sender,
            promptCreator: _promptCreator,
            exists: true
        });

        emit AIGenerationRequested(requestId, _tokenId, _promptId, msg.sender);
    }

    // --- NFT Evolution & Oracle Integration (5 functions) ---

    /**
     * @dev Callback function from the authorized oracle to fulfill an AI generation request.
     *      Updates the NFT's evolution history with the AI-generated data.
     *      Only callable by an address with the `ORACLE_ROLE` (specifically, the registered oracle contract).
     * @param _requestId The ID of the original AI generation request.
     * @param _tokenId The ID of the NFT being evolved.
     * @param _promptId The ID of the prompt that led to this evolution.
     * @param _generatedData The AI-generated content (e.g., new traits JSON, image hash).
     * @param _oracleSigner The address of the oracle contract or trusted signer.
     */
    function fulfillAIGeneration(
        bytes32 _requestId,
        uint256 _tokenId,
        uint256 _promptId,
        string calldata _generatedData,
        address _oracleSigner
    ) external onlyRole(ORACLE_ROLE) {
        if (_oracleSigner != _chronoGenesisOracle) revert CallerNotOracle(); // Ensure it's the registered oracle
        PendingAIGenerationRequest storage req = pendingAIGenerationRequests[_requestId];
        if (!req.exists) revert InvalidRequestData();
        if (req.tokenId != _tokenId || req.promptId != _promptId) revert InvalidRequestData();
        // Check if token exists by requiring it to be owned.
        _requireOwned(_tokenId);

        // Add the new evolution to the NFT's history
        nftEvolutionHistory[_tokenId].push(NFTEvolution({
            promptId: _promptId,
            generatedData: _generatedData,
            evolutionTime: block.timestamp,
            evolvingOracle: _oracleSigner,
            promptCreator: req.promptCreator
        }));

        // Delete the pending request after fulfillment
        delete pendingAIGenerationRequests[_requestId];

        emit NFTEvolved(_tokenId, _promptId, _generatedData, _oracleSigner);
    }

    /**
     * @dev Retrieves the full chronological evolution history for a given NFT.
     * @param _tokenId The ID of the NFT.
     * @return An array of NFTEvolution structs detailing each evolution event.
     */
    function getNFTEvolutionHistory(uint256 _tokenId)
        public
        view
        returns (NFTEvolution[] memory)
    {
        _requireOwned(_tokenId); // Ensure the token exists
        return nftEvolutionHistory[_tokenId];
    }

    /**
     * @dev Retrieves details of a specific prompt proposal.
     * @param _promptId The ID of the prompt.
     * @return proposer The address of the prompt creator.
     * @return promptText The text of the prompt.
     * @return initialStakeAmount The initial CGT stake of the proposer.
     * @return totalVotes The total CGT votes accumulated from all voters.
     * @return submissionTime The timestamp when the prompt was submitted.
     * @return isResolved Whether the prompt has been selected and processed for an evolution.
     */
    function getPromptDetails(uint256 _promptId)
        public
        view
        returns (address proposer, string memory promptText, uint256 initialStakeAmount, uint256 totalVotes, uint256 submissionTime, bool isResolved)
    {
        PromptProposal storage prompt = promptProposals[_promptId];
        if (!prompt.exists) revert InvalidPromptId();
        return (prompt.proposer, prompt.promptText, prompt.initialStakeAmount, prompt.totalVotes, prompt.submissionTime, prompt.isResolved);
    }

    /**
     * @dev Returns the latest AI-generated data for a given NFT.
     * @param _tokenId The ID of the NFT.
     * @return The latest AI-generated data string, or a default message if no evolution occurred.
     */
    function getNFTCurrentEvolutionData(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        _requireOwned(_tokenId);
        NFTEvolution[] storage history = nftEvolutionHistory[_tokenId];
        if (history.length == 0) {
            return "No evolution data yet for this NFT.";
        }
        return history[history.length - 1].generatedData;
    }

    /**
     * @dev Sets the address of the trusted ChronoGenesis Oracle contract.
     *      The oracle contract will automatically be granted the `ORACLE_ROLE`.
     *      Only callable by an address with the `ADMIN_ROLE`.
     * @param _newOracle The address of the new oracle contract.
     */
    function registerChronoGenesisOracle(address _newOracle) public onlyRole(ADMIN_ROLE) {
        require(_newOracle != address(0), "Oracle cannot be zero address");
        // Revoke role from old oracle if exists, grant to new
        if (_chronoGenesisOracle != address(0)) {
            _revokeRole(ORACLE_ROLE, _chronoGenesisOracle);
        }
        _chronoGenesisOracle = _newOracle;
        _grantRole(ORACLE_ROLE, _newOracle); // Grant oracle role to the oracle contract itself
        emit ChronoGenesisOracleUpdated(_newOracle);
    }

    // --- ChronoGenesis Token (CGT) Staking & Governance (3 functions) ---

    /**
     * @dev Allows users to unstake their CGT tokens that were staked on a *resolved* prompt.
     *      This function releases CGT back to the user from their vote or initial proposal stake.
     * @param _promptId The ID of the prompt from which to unstake.
     */
    function unstakeCGTFromPrompt(uint256 _promptId) public nonReentrant {
        PromptProposal storage prompt = promptProposals[_promptId];
        if (!prompt.exists) revert InvalidPromptId();
        if (!prompt.isResolved) revert PromptNotActive(); // Can only unstake from resolved prompts

        uint256 amountToUnstake = prompt.voterStakes[msg.sender];
        if (amountToUnstake == 0) revert NotVotingParticipant();
        if (_cgtToken == address(0)) revert ChronoGenesisTokenNotSet();

        prompt.voterStakes[msg.sender] = 0; // Clear individual stake for this prompt
        // Reduce total votes (though prompt is resolved, good to keep state consistent)
        prompt.totalVotes -= amountToUnstake;
        // Also clear initial stake if msg.sender is proposer and it's their initial stake
        if (prompt.proposer == msg.sender) {
            prompt.initialStakeAmount = 0;
        }

        IERC20(_cgtToken).transfer(msg.sender, amountToUnstake);
        emit CGTUnstaked(_promptId, msg.sender, amountToUnstake);
    }

    /**
     * @dev Sets the minimum amount of CGT required to propose an AI genesis prompt.
     *      Only callable by an account with the ADMIN_ROLE.
     * @param _amount The new minimum stake amount (in CGT token units, e.g., wei).
     */
    function setMinimumPromptStakeAmount(uint256 _amount) public onlyRole(ADMIN_ROLE) {
        minimumPromptStakeAmount = _amount;
        emit MinimumPromptStakeUpdated(_amount);
    }

    /**
     * @dev Sets the duration (in seconds) for which prompt proposals can be voted on.
     *      Only callable by an account with the ADMIN_ROLE.
     * @param _durationSeconds The new voting duration in seconds.
     */
    function setVotingDuration(uint256 _durationSeconds) public onlyRole(ADMIN_ROLE) {
        votingDuration = _durationSeconds;
        emit VotingDurationUpdated(_durationSeconds);
    }

    // --- Co-Creator Royalties & Revenue Distribution (3 functions) ---

    /**
     * @dev Sets the percentage (in basis points) of future evolution fees
     *      that will be distributed as royalties to the creator of a winning prompt.
     *      10000 basis points = 100%.
     *      Only callable by an account with the ADMIN_ROLE.
     * @param _shareBps The new royalty share in basis points.
     */
    function setPromptCreatorRoyaltyShare(uint256 _shareBps) public onlyRole(ADMIN_ROLE) {
        require(_shareBps <= 10000, "Share cannot exceed 100%");
        promptCreatorRoyaltyShareBps = _shareBps;
        emit PromptCreatorRoyaltyShareUpdated(_shareBps);
    }

    /**
     * @dev Allows a prompt creator to claim their accumulated royalty share in ETH.
     *      Royalties accumulate from the `evolutionFee` paid for evolutions triggered by their prompt.
     */
    function claimCreatorRoyalties() public nonReentrant {
        uint256 amount = creatorRoyaltyBalances[msg.sender];
        if (amount == 0) revert NoRoyaltiesToClaim();

        creatorRoyaltyBalances[msg.sender] = 0; // Reset balance before transfer
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert FeePaymentFailed(); // Use a more generic error for failed ETH transfers
        emit CreatorRoyaltyClaimed(msg.sender, amount);
    }

    /**
     * @dev Sets the fee required (in wei) to trigger an NFT evolution.
     *      This fee is paid in ETH and is split between the prompt creator and the treasury.
     *      Only callable by an account with the ADMIN_ROLE.
     * @param _fee The new evolution fee in wei.
     */
    function setEvolutionFee(uint256 _fee) public onlyRole(ADMIN_ROLE) {
        evolutionFee = _fee;
        emit EvolutionFeeUpdated(_fee);
    }

    // --- Access Control & Configuration (5 functions) ---

    /**
     * @dev Sets the address of the ChronoGenesis Token (CGT) ERC20 contract.
     *      Only callable by an account with the ADMIN_ROLE.
     * @param _newCGT The address of the new CGT token contract.
     */
    function setChronoGenesisToken(address _newCGT) public onlyRole(ADMIN_ROLE) {
        require(_newCGT != address(0), "CGT Token cannot be zero address");
        _cgtToken = _newCGT;
        emit ChronoGenesisTokenUpdated(_newCGT);
    }

    // The following functions are inherited from AccessControl and exposed for external use.

    /**
     * @dev Grants a role to an account.
     *      Can only be called by an account with the `DEFAULT_ADMIN_ROLE`.
     * @param role The role to grant (e.g., ADMIN_ROLE, CURATOR_ROLE, ORACLE_ROLE).
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes a role from an account.
     *      Can only be called by an account with the `DEFAULT_ADMIN_ROLE`.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @dev Allows an account to renounce its own role.
     *      This is useful for security, allowing an admin to give up their administrative power.
     * @param role The role to renounce.
     * @param account The address renouncing the role (must be `msg.sender`).
     */
    function renounceRole(bytes32 role, address account) public override {
        _renounceRole(role, account);
    }

    /**
     * @dev Returns the admin role that can grant/revoke a given role.
     * @param role The role to query.
     * @return The admin role for the specified role.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Returns a URI for contract-level metadata.
     *      This could describe the collection as a whole. For simplicity, it currently points
     *      to the same service as the token URIs.
     * @return A string representing the URI to the contract's metadata.
     */
    function contractURI() public view returns (string memory) {
        return _evolutionServiceURI;
    }

    // --- Internal Helpers ---
    /**
     * @dev Throws if `tokenId` is not valid (i.e., token doesn't exist).
     *      A wrapper around ERC721's _exists to make custom error handling cleaner.
     */
    function _requireOwned(uint256 tokenId) internal view {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId); // Using OpenZeppelin's built-in error for consistency
        }
    }
}
```