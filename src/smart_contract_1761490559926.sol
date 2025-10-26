This smart contract, **CognitiveCanvas DAO**, introduces a novel decentralized application combining **AI Oracle integration**, **dynamic Non-Fungible Tokens (NFTs)**, and a **dual-weighted Decentralized Autonomous Organization (DAO) governance model**.

The core idea is to establish a community-driven protocol where participants contribute "cognitive fragments" (data snippets) on various topics. A trusted off-chain AI Oracle processes these fragments. The AI's insights, combined with community governance, then drive the creation and dynamic evolution of unique digital art pieces or "Cognitive Canvas NFTs."

The DAO's governance is sophisticated, leveraging both traditional token-based voting and a dynamic, on-chain reputation score earned through validated contributions.

---

## Outline: CognitiveCanvas DAO - AI-Driven Dynamic Generative Assets & Reputation System

This contract establishes a Decentralized Autonomous Organization (DAO) focused on curating and generating dynamic digital assets (Cognitive Canvas NFTs) driven by community-contributed "cognitive fragments" and insights from a trusted AI Oracle. It features a unique dual-voting system incorporating both token holdings and a dynamic reputation score, and provides a framework for AI-driven NFT attribute evolution.

## Function Summary:

*   **I. Core Setup & Administration (`AccessControl`, `Pausable`):**
    1.  `constructor()`: Initializes roles (Admin, AI Oracle), sets up ERC721, and registers initial token addresses.
    2.  `pause()`: Pauses core contract functionalities in emergencies, callable by an admin.
    3.  `unpause()`: Resumes paused functionalities, callable by an admin.
    4.  `setAIOracleAddress()`: Allows an admin to set or update the trusted AI Oracle address.
    5.  `setCanvasBaseURI()`: Sets the base URI for Cognitive Canvas NFT metadata, callable by an admin.
*   **II. Cognitive Fragment Submission & AI Processing:**
    6.  `submitCognitiveFragment()`: Users submit data fragments (e.g., IPFS hashes, contextual tags) for AI analysis, requiring a stake in governance tokens.
    7.  `reclaimFragmentSubmissionStake()`: Allows fragment submitters to reclaim their stake after their fragment has been validated or rejected.
    8.  `validateFragmentByOracle()`: Called by the AI Oracle to validate or reject a fragment, updating the contributor's reputation based on validity.
    9.  `requestAIAnalysisForCanvas()`: DAO members can propose a specific AI analysis task for a Cognitive Canvas NFT, signaling the off-chain oracle.
    10. `receiveAIAnalysisResultForCanvas()`: Called by the AI Oracle to update a Cognitive Canvas NFT's dynamic attributes based on AI analysis results.
*   **III. Reputation & Delegation Management:**
    11. `getReputation()`: Retrieves a user's current reputation score.
    12. `delegateReputationVotingPower()`: Allows users to delegate their reputation-based voting power to another address.
    13. `undelegateReputationVotingPower()`: Removes an active reputation delegation.
    14. `delegateTokenVotingPower()`: Allows users to delegate their token-based voting power to another address.
    15. `undelegateTokenVotingPower()`: Removes an active token delegation.
    16. `getVoterVotingPower()`: Calculates a voter's total combined voting power (token-based + reputation-based), considering delegations.
*   **IV. DAO Governance & Treasury:**
    17. `createProposal()`: Initiates a new governance proposal (e.g., mint NFT, fund distribution, parameter change).
    18. `voteOnProposal()`: Allows users to vote on proposals using their combined voting power (token + reputation).
    19. `executeProposal()`: Executes a proposal that has met quorum and passed its voting period.
    20. `getProposalDetails()`: Retrieves comprehensive details about a specific governance proposal.
    21. `depositIntoTreasury()`: Allows users to contribute governance tokens to the DAO treasury.
    22. `withdrawTreasuryFunds()`: Allows the DAO (via an executed proposal) to withdraw specified ERC20 tokens from the treasury.
    23. `distributeFragmentRewards()`: Allows the DAO (via an executed proposal) to distribute reward tokens to validated fragment submitters.
*   **V. Cognitive Canvas NFTs (ERC721 & Dynamic Attributes):**
    24. `mintCognitiveCanvasNFT()`: DAO-controlled function to mint a new Cognitive Canvas NFT, potentially with initial AI-generated attributes.
    25. `updateCognitiveCanvasAttributes()`: Updates specific dynamic attributes of a Cognitive Canvas NFT, typically driven by AI Oracle results or DAO proposals.
    26. `tokenURI()`: Overrides the standard ERC721 `tokenURI` to dynamically generate and serve Base64 encoded JSON metadata based on the NFT's current evolving attributes.
    27. `transferFrom()`: Standard ERC721 function to transfer NFT ownership.
    28. `safeTransferFrom()` (x2): Standard ERC721 functions for safer NFT transfers.
    29. `approve()`: Standard ERC721 function to approve an address to spend a specific NFT.
    30. `getApproved()`: Standard ERC721 function to query the approved address for an NFT.
    31. `setApprovalForAll()`: Standard ERC721 function to approve an operator for all of an owner's NFTs.
    32. `isApprovedForAll()`: Standard ERC721 function to query if an operator is approved for all NFTs.
    33. `balanceOf()`: Standard ERC721 function to query the number of NFTs owned by an address.
    34. `ownerOf()`: Standard ERC721 function to query the owner of a specific NFT.
    35. `name()`: Standard ERC721 metadata function for the NFT collection name.
    36. `symbol()`: Standard ERC721 metadata function for the NFT collection symbol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Define custom errors for better clarity and gas efficiency
error NotAIOracle();
error FragmentAlreadyValidatedOrRejected();
error FragmentStakeNotReclaimable();
error NoActiveProposal();
error ProposalAlreadyVoted();
error InsufficientVotingPower();
error ProposalNotExecutable();
error ProposalStillActive();
error ZeroAddressNotAllowed();
error Unauthorized();
error InsufficientBalance();
error CannotMintZeroTokens();
error CannotUpdateNonExistentToken();
error InvalidArgument(); // General error for invalid input, more specific than InvalidAttributeUpdate
error FragmentStakeRequired();
error DuplicateFragmentSubmission();
error InvalidProposalState();
error MinimumReputationNotMet();

/**
 * @title CognitiveCanvas DAO - AI-Driven Dynamic Generative Assets & Reputation System
 * @author Anon
 * @notice This contract establishes a Decentralized Autonomous Organization (DAO) focused on curating and generating
 *         dynamic digital assets (Cognitive Canvas NFTs) driven by community-contributed "cognitive fragments" and
 *         insights from a trusted AI Oracle. It features a unique dual-voting system incorporating both token holdings
 *         and a dynamic reputation score, and provides a framework for AI-driven NFT attribute evolution.
 *
 * @dev The contract uses OpenZeppelin's AccessControl for role-based permissions, Pausable for emergency halts,
 *      ReentrancyGuard for security, and ERC721 for the dynamic NFTs.
 *      The AI Oracle is an off-chain entity expected to call specific functions after performing computations.
 *      The metadata for Cognitive Canvas NFTs is generated dynamically on-chain using Base64 encoding.
 *      Reputation is a core mechanism that rewards genuine contributions and influences governance.
 */
contract CognitiveCanvasDAO is AccessControl, Pausable, ReentrancyGuard, ERC721, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _canvasTokenIds;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Custom admin role for contract-specific admin tasks
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE"); // Role for the trusted AI oracle

    // --- Core Parameters ---
    uint256 public constant MIN_REPUTATION_FOR_DELEGATION = 100; // Minimum reputation needed to delegate voting power
    uint256 public constant FRAGMENT_SUBMISSION_STAKE_AMOUNT = 1e18; // 1 token (assuming 18 decimals) of governance token per fragment
    uint256 public constant REPUTATION_PER_VALID_FRAGMENT = 10; // Reputation points gained per valid fragment
    uint256 public constant PROPOSAL_VOTE_DURATION_BLOCKS = 7 * 24 * 60 * 60 / 12; // Approximately 7 days in blocks (12 sec/block)
    uint256 public constant PROPOSAL_MIN_QUORUM_PERCENTAGE = 5; // 5% of total voting power (token + reputation)
    uint256 public constant PROPOSAL_PASS_THRESHOLD_PERCENTAGE = 50; // 50% + 1 vote to pass (strictly >50%)

    // --- Token Addresses ---
    IERC20 public immutable governanceToken; // ERC20 token used for voting power and fragment staking
    IERC20 public immutable rewardToken; // ERC20 token used to reward contributors and oracle

    // --- State Variables ---
    mapping(address => uint256) public reputation; // User reputation scores
    mapping(address => address) public reputationDelegates; // Address delegated reputation voting power to
    mapping(address => address) public tokenDelegates; // Address delegated token voting power to

    // Cognitive Fragments
    struct CognitiveFragment {
        string fragmentURI; // e.g., IPFS hash pointing to off-chain data
        string topic;       // Categorization/context for the fragment
        address submitter;
        uint64 timestamp;
        bool validated;
        bool rejected;
    }
    mapping(uint256 => CognitiveFragment) public cognitiveFragments;
    Counters.Counter private _fragmentIds;
    mapping(bytes32 => bool) public submittedFragmentHashes; // To prevent duplicate fragmentURI submissions (by hash of URI + topic)

    // Proposals
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        string description;
        address target;           // Address to call if proposal passes
        bytes callData;           // Data to call on target
        uint64 startBlock;        // Block number when voting starts
        uint64 endBlock;          // Block number when voting ends
        uint256 forVotes;         // Total "for" votes (weighted)
        uint256 againstVotes;     // Total "against" votes (weighted)
        uint256 abstainVotes;     // Total "abstain" votes (weighted)
        mapping(address => bool) hasVoted; // Check if an address has voted (only for direct voters, not delegates)
        address proposer;         // The address of the proposal creator
        ProposalState state;
        string proposalURI;       // External URI for detailed proposal information
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;

    // Cognitive Canvas NFT Attributes (Dynamic)
    struct CanvasAttributes {
        string name;
        string description;
        string imageUrl; // Base image URL (could be a generated image on IPFS)
        mapping(string => string) dynamicProperties; // Key-value pairs for dynamic attributes
        string[] dynamicPropertyKeys; // To allow iteration for tokenURI generation
        uint64 lastUpdated; // Timestamp of last attribute update
        uint256 generationIteration; // How many times its attributes have been significantly updated
    }
    mapping(uint256 => CanvasAttributes) public canvasAttributes; // tokenId => attributes

    // --- Events ---
    event AIOracleAddressSet(address indexed newAddress);
    event CognitiveFragmentSubmitted(uint256 indexed fragmentId, address indexed submitter, string fragmentURI, string topic);
    event CognitiveFragmentValidated(uint256 indexed fragmentId, address indexed validator, address indexed submitter, uint256 newReputation);
    event CognitiveFragmentRejected(uint256 indexed fragmentId, address indexed validator, address indexed submitter);
    event FragmentStakeReclaimed(uint256 indexed fragmentId, address indexed submitter, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator, address indexed previousDelegatee);
    event TokenDelegated(address indexed delegator, address indexed delegatee);
    event TokenUndelegated(address indexed delegator, address indexed previousDelegatee);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint64 startBlock, uint64 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint8 support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event CanvasNFTMinted(uint256 indexed tokenId, address indexed minter, address indexed owner);
    event CanvasAttributesUpdated(uint256 indexed tokenId, string attributeKey, string attributeValue, uint256 generationIteration);
    event AIAnalysisRequested(uint256 indexed signalId, uint256 indexed tokenId, string analysisRequest);
    event AIAnalysisResultReceived(uint256 indexed tokenId, string resultKey, string resultValue, string newImageUrl);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event FragmentRewardsDistributed(uint256 indexed proposalId, uint256 indexed fragmentId, address indexed recipient, uint256 amount);


    // --- Constructor ---
    constructor(
        address initialAdmin,
        address initialAIOracle,
        address _governanceTokenAddress,
        address _rewardTokenAddress,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        if (initialAdmin == address(0) || initialAIOracle == address(0) || _governanceTokenAddress == address(0) || _rewardTokenAddress == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin); // OpenZeppelin's default role for Pausable, etc.
        _grantRole(ADMIN_ROLE, initialAdmin); // Custom admin role for DAO-specific admin tasks
        _grantRole(AI_ORACLE_ROLE, initialAIOracle);

        governanceToken = IERC20(_governanceTokenAddress);
        rewardToken = IERC20(_rewardTokenAddress);
    }

    // --- I. Core Setup & Administration ---

    /**
     * @notice Pauses core contract functionalities in emergencies.
     * @dev Only callable by an account with the PAUSER_ROLE (which is DEFAULT_ADMIN_ROLE by default).
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @notice Resumes paused functionalities.
     * @dev Only callable by an account with the PAUSER_ROLE (which is DEFAULT_ADMIN_ROLE by default).
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        _unpause();
    }

    /**
     * @notice Sets or updates the trusted AI Oracle address.
     * @dev Only callable by an account with the ADMIN_ROLE. Multiple oracles can be granted this role.
     * @param _newAIOracleAddress The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newAIOracleAddress) public onlyRole(ADMIN_ROLE) {
        if (_newAIOracleAddress == address(0)) revert ZeroAddressNotAllowed();
        _grantRole(AI_ORACLE_ROLE, _newAIOracleAddress);
        emit AIOracleAddressSet(_newAIOracleAddress);
    }

    /**
     * @notice Sets the base URI for Cognitive Canvas NFT metadata.
     * @dev This base URI is prepended to the token ID for metadata retrieval, unless `tokenURI` is overridden.
     *      Only callable by an account with the ADMIN_ROLE.
     * @param _newBaseURI The new base URI.
     */
    function setCanvasBaseURI(string memory _newBaseURI) public onlyRole(ADMIN_ROLE) {
        _setBaseURI(_newBaseURI); // ERC721 internal function
    }

    // --- II. Cognitive Fragment Submission & AI Processing ---

    /**
     * @notice Allows users to submit data fragments (e.g., IPFS hashes, contextual tags) for AI analysis.
     *         Requires staking `FRAGMENT_SUBMISSION_STAKE_AMOUNT` of governance tokens.
     * @param _fragmentURI A URI pointing to the off-chain cognitive data (e.g., IPFS hash).
     * @param _topic A descriptive topic or category for the fragment.
     */
    function submitCognitiveFragment(string memory _fragmentURI, string memory _topic) public whenNotPaused nonReentrant {
        if (bytes(_fragmentURI).length == 0 || bytes(_topic).length == 0) revert InvalidArgument();
        
        // Prevent duplicate fragment URI + topic submissions by hashing
        bytes32 fragmentHash = keccak256(abi.encodePacked(_fragmentURI, _topic));
        if (submittedFragmentHashes[fragmentHash]) revert DuplicateFragmentSubmission();

        // Require staking of governance tokens
        if (governanceToken.balanceOf(msg.sender) < FRAGMENT_SUBMISSION_STAKE_AMOUNT) revert InsufficientBalance();
        // Transfer governance tokens from sender to this contract
        if (!governanceToken.transferFrom(msg.sender, address(this), FRAGMENT_SUBMISSION_STAKE_AMOUNT)) revert FragmentStakeRequired();

        _fragmentIds.increment();
        uint256 id = _fragmentIds.current();
        cognitiveFragments[id] = CognitiveFragment({
            fragmentURI: _fragmentURI,
            topic: _topic,
            submitter: msg.sender,
            timestamp: uint64(block.timestamp),
            validated: false,
            rejected: false
        });
        submittedFragmentHashes[fragmentHash] = true;
        emit CognitiveFragmentSubmitted(id, msg.sender, _fragmentURI, _topic);
    }

    /**
     * @notice Called by the AI Oracle to validate or reject a fragment, updating contributor reputation.
     * @dev Only callable by an account with the AI_ORACLE_ROLE.
     * @param _fragmentId The ID of the fragment to validate.
     * @param _isValid True if the fragment is valid, false if rejected.
     * @param _reason A reason for rejection, or general notes for validation (optional).
     */
    function validateFragmentByOracle(uint256 _fragmentId, bool _isValid, string memory _reason) public onlyRole(AI_ORACLE_ROLE) whenNotPaused {
        CognitiveFragment storage fragment = cognitiveFragments[_fragmentId];
        if (fragment.submitter == address(0)) revert FragmentAlreadyValidatedOrRejected(); // Fragment doesn't exist or stake reclaimed
        if (fragment.validated || fragment.rejected) revert FragmentAlreadyValidatedOrRejected();

        if (_isValid) {
            fragment.validated = true;
            _updateReputation(fragment.submitter, REPUTATION_PER_VALID_FRAGMENT);
            emit CognitiveFragmentValidated(_fragmentId, msg.sender, fragment.submitter, reputation[fragment.submitter]);
            // The stake for validated fragments remains in the DAO treasury by default,
            // unless the DAO decides to return it via a separate proposal/function.
        } else {
            fragment.rejected = true;
            // For rejected fragments, the stake is kept by the DAO, but the submitter can reclaim it.
            emit CognitiveFragmentRejected(_fragmentId, msg.sender, fragment.submitter);
        }
    }

    /**
     * @notice Allows fragment submitters to reclaim their stake after validation or rejection.
     * @dev Reclaims `FRAGMENT_SUBMISSION_STAKE_AMOUNT` of governance tokens. The fragment record remains.
     * @param _fragmentId The ID of the fragment for which to reclaim stake.
     */
    function reclaimFragmentSubmissionStake(uint256 _fragmentId) public whenNotPaused nonReentrant {
        CognitiveFragment storage fragment = cognitiveFragments[_fragmentId];
        if (fragment.submitter == address(0) || fragment.submitter != msg.sender) revert Unauthorized();
        if (!(fragment.validated || fragment.rejected)) revert FragmentStakeNotReclaimable(); // Only after being processed

        // Only allow reclaiming if the stake is still implicitly held by the contract for this fragment
        // We use `fragment.submitter == msg.sender` to ensure it hasn't been reclaimed already.
        // Once reclaimed, fragment.submitter is set to address(0).
        if (governanceToken.balanceOf(address(this)) < FRAGMENT_SUBMISSION_STAKE_AMOUNT) revert InsufficientBalance();
        if (!governanceToken.transfer(msg.sender, FRAGMENT_SUBMISSION_STAKE_AMOUNT)) revert InsufficientBalance();

        // Mark stake as reclaimed by clearing the submitter, preventing double-reclaiming
        fragment.submitter = address(0);
        emit FragmentStakeReclaimed(_fragmentId, msg.sender, FRAGMENT_SUBMISSION_STAKE_AMOUNT);
    }


    /**
     * @notice DAO members propose a specific AI analysis task for a Cognitive Canvas NFT.
     * @dev This function merely records the request as a signaling proposal; the AI Oracle is expected to pick it up and respond.
     *      It doesn't directly trigger AI, but serves as an on-chain record and signal.
     * @param _tokenId The ID of the Cognitive Canvas NFT to analyze.
     * @param _analysisRequest A string describing the type of analysis requested.
     */
    function requestAIAnalysisForCanvas(uint256 _tokenId, string memory _analysisRequest) public whenNotPaused {
        if (ownerOf(_tokenId) == address(0)) revert CannotUpdateNonExistentToken(); // Check if NFT exists
        if (bytes(_analysisRequest).length == 0) revert InvalidArgument();

        // Generate a signal ID (similar to a proposal ID, but for AI request tracking)
        _proposalIds.increment(); // Re-using proposal counter for a unique ID
        uint256 signalId = _proposalIds.current();

        // A placeholder "proposal" to signal the AI Oracle. In a full DAO, this would be an executed proposal.
        proposals[signalId] = Proposal({
            description: string(abi.encodePacked("AI Analysis Request for Canvas #", Strings.toString(_tokenId), ": ", _analysisRequest)),
            target: address(0), // No direct on-chain target for this type of signaling
            callData: "",
            startBlock: uint64(block.number),
            endBlock: uint64(block.number), // Ends immediately as it's a signal, not a vote
            forVotes: 0, againstVotes: 0, abstainVotes: 0,
            hasVoted: new mapping(address => bool), // Empty mapping, no voting for signals
            proposer: msg.sender,
            state: ProposalState.Executed, // Marked executed as it's a signaling function
            proposalURI: ""
        });
        emit AIAnalysisRequested(signalId, _tokenId, _analysisRequest);
    }

    /**
     * @notice Called by the AI Oracle to update a Cognitive Canvas NFT's attributes based on analysis results.
     * @dev Only callable by an account with the AI_ORACLE_ROLE. Updates dynamic properties and optionally the image.
     * @param _tokenId The ID of the Cognitive Canvas NFT to update.
     * @param _attributeKey The key of the dynamic attribute to update or add.
     * @param _attributeValue The new value for the dynamic attribute.
     * @param _newImageUrl An optional new image URL for the NFT, based on AI generation. If empty, image is not updated.
     */
    function receiveAIAnalysisResultForCanvas(
        uint256 _tokenId,
        string memory _attributeKey,
        string memory _attributeValue,
        string memory _newImageUrl
    ) public onlyRole(AI_ORACLE_ROLE) whenNotPaused nonReentrant {
        if (ownerOf(_tokenId) == address(0)) revert CannotUpdateNonExistentToken();
        if (bytes(_attributeKey).length == 0) revert InvalidArgument();

        CanvasAttributes storage attrs = canvasAttributes[_tokenId];
        
        // Add key to dynamicPropertyKeys array if it's new
        bool keyExists = false;
        for (uint i = 0; i < attrs.dynamicPropertyKeys.length; i++) {
            if (keccak256(abi.encodePacked(attrs.dynamicPropertyKeys[i])) == keccak256(abi.encodePacked(_attributeKey))) {
                keyExists = true;
                break;
            }
        }
        if (!keyExists) {
            attrs.dynamicPropertyKeys.push(_attributeKey);
        }

        attrs.dynamicProperties[_attributeKey] = _attributeValue;
        if (bytes(_newImageUrl).length > 0) {
            attrs.imageUrl = _newImageUrl;
        }
        attrs.lastUpdated = uint64(block.timestamp);
        attrs.generationIteration++;

        emit CanvasAttributesUpdated(_tokenId, _attributeKey, _attributeValue, attrs.generationIteration);
        emit AIAnalysisResultReceived(_tokenId, _attributeKey, _attributeValue, _newImageUrl);
    }

    // --- III. Reputation & Delegation Management ---

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address whose reputation to update.
     * @param _amount The amount of reputation points to add.
     */
    function _updateReputation(address _user, uint256 _amount) internal {
        reputation[_user] += _amount;
        emit ReputationUpdated(_user, reputation[_user]);
    }

    /**
     * @notice Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputation(address _user) public view returns (uint256) {
        return reputation[_user];
    }

    /**
     * @notice Allows users to delegate their reputation-based voting power to another address.
     * @dev Requires a minimum reputation score.
     * @param _delegatee The address to delegate reputation voting power to.
     */
    function delegateReputationVotingPower(address _delegatee) public whenNotPaused {
        if (_delegatee == address(0)) revert ZeroAddressNotAllowed();
        if (reputation[msg.sender] < MIN_REPUTATION_FOR_DELEGATION) revert MinimumReputationNotMet();
        if (reputationDelegates[msg.sender] == _delegatee) return; // No change
        reputationDelegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Removes reputation delegation.
     */
    function undelegateReputationVotingPower() public whenNotPaused {
        address previousDelegatee = reputationDelegates[msg.sender];
        if (previousDelegatee == address(0)) revert Unauthorized(); // No active delegation
        delete reputationDelegates[msg.sender];
        emit ReputationUndelegated(msg.sender, previousDelegatee);
    }

    /**
     * @notice Allows users to delegate their token-based voting power to another address.
     * @dev This is separate from reputation delegation.
     * @param _delegatee The address to delegate token voting power to.
     */
    function delegateTokenVotingPower(address _delegatee) public whenNotPaused {
        if (_delegatee == address(0)) revert ZeroAddressNotAllowed();
        if (tokenDelegates[msg.sender] == _delegatee) return; // No change
        tokenDelegates[msg.sender] = _delegatee;
        emit TokenDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Removes token delegation.
     */
    function undelegateTokenVotingPower() public whenNotPaused {
        address previousDelegatee = tokenDelegates[msg.sender];
        if (previousDelegatee == address(0)) revert Unauthorized(); // No active delegation
        delete tokenDelegates[msg.sender];
        emit TokenUndelegated(msg.sender, previousDelegatee);
    }

    /**
     * @notice Calculates a voter's total effective voting power for a proposal (token + reputation).
     * @dev This function queries the effective voting power, considering delegations.
     * @param _voter The address whose voting power to query.
     * @return The total combined voting power.
     */
    function getVoterVotingPower(address _voter) public view returns (uint256) {
        // Resolve delegation for reputation
        address effectiveReputationHolder = reputationDelegates[_voter] == address(0) ? _voter : reputationDelegates[_voter];
        // Resolve delegation for tokens
        address effectiveTokenHolder = tokenDelegates[_voter] == address(0) ? _voter : tokenDelegates[_voter];

        uint256 reputationPower = reputation[effectiveReputationHolder];
        uint256 tokenPower = governanceToken.balanceOf(effectiveTokenHolder); // Assumes 1 token = 1 voting power unit

        // Simple aggregation. Could be weighted differently (e.g., tokenPower * 2 + reputationPower).
        return tokenPower + reputationPower;
    }

    // --- IV. DAO Governance & Treasury ---

    /**
     * @notice Initiates a new governance proposal.
     * @dev Any user with sufficient voting power can create a proposal.
     * @param _description A brief description of the proposal.
     * @param _target The address of the contract to call if the proposal passes (can be `address(this)`).
     * @param _callData The encoded function call to be executed on the target contract.
     * @param _proposalURI An external URI for more detailed proposal information.
     * @return The ID of the newly created proposal.
     */
    function createProposal(
        string memory _description,
        address _target,
        bytes memory _callData,
        string memory _proposalURI
    ) public whenNotPaused nonReentrant returns (uint256) {
        // A minimum voting power to create a proposal could be enforced here.
        // E.g., `require(getVoterVotingPower(msg.sender) > MIN_PROPOSER_POWER, "Insufficient power to propose");`

        _proposalIds.increment();
        uint256 id = _proposalIds.current();
        proposals[id] = Proposal({
            description: _description,
            target: _target,
            callData: _callData,
            startBlock: uint64(block.number),
            endBlock: uint64(block.number + PROPOSAL_VOTE_DURATION_BLOCKS),
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            hasVoted: new mapping(address => bool), // Initialize mapping for voters
            proposer: msg.sender,
            state: ProposalState.Active,
            proposalURI: _proposalURI
        });
        emit ProposalCreated(id, msg.sender, _description, proposals[id].startBlock, proposals[id].endBlock);
        return id;
    }

    /**
     * @notice Allows users to vote on proposals using a combination of token-based and reputation-based voting power.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support 0 for "against", 1 for "for", 2 for "abstain".
     */
    function voteOnProposal(uint256 _proposalId, uint8 _support) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (block.number <= proposal.startBlock) revert ProposalStillActive(); // Voting hasn't started
        if (block.number > proposal.endBlock) revert ProposalStillActive(); // Voting period has ended
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        uint256 votingPower = getVoterVotingPower(msg.sender);
        if (votingPower == 0) revert InsufficientVotingPower();

        proposal.hasVoted[msg.sender] = true;
        if (_support == 0) { // Against
            proposal.againstVotes += votingPower;
        } else if (_support == 1) { // For
            proposal.forVotes += votingPower;
        } else if (_support == 2) { // Abstain
            proposal.abstainVotes += votingPower;
        } else {
            revert InvalidArgument();
        }
        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a proposal that has met quorum and passed its voting period.
     * @dev Can be called by anyone once a proposal has passed its voting period and conditions.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (block.number <= proposal.endBlock) revert ProposalStillActive();

        uint256 totalVotesCast = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        
        // This is a placeholder for `_getTotalSystemVotingPower()`.
        // In a real system, tracking total token supply + total reputation incrementally
        // would be necessary for accurate quorum calculation, as iterating mappings is impossible.
        // For demonstration, let's use a simplified approximation or mock value.
        uint256 totalPossibleVotingPower = governanceToken.totalSupply() + 1_000_000; // Mock 1M total reputation

        // Check quorum: total votes cast must meet a minimum percentage of total possible voting power
        if (totalVotesCast * 100 < totalPossibleVotingPower * PROPOSAL_MIN_QUORUM_PERCENTAGE) {
            proposal.state = ProposalState.Failed;
            revert ProposalNotExecutable(); // Failed quorum
        }

        // Check pass threshold: 'for' votes must exceed `PROPOSAL_PASS_THRESHOLD_PERCENTAGE` of 'for' + 'against' votes.
        if (proposal.forVotes * 100 <= (proposal.forVotes + proposal.againstVotes) * PROPOSAL_PASS_THRESHOLD_PERCENTAGE) {
            proposal.state = ProposalState.Failed;
            revert ProposalNotExecutable(); // Did not pass threshold
        }

        // Execute the proposal
        proposal.state = ProposalState.Succeeded;
        if (proposal.target != address(0) && proposal.callData.length > 0) {
            (bool success, ) = proposal.target.call(proposal.callData);
            require(success, "Execution failed");
        }
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId, msg.sender);
    }

    /**
     * @notice Retrieves comprehensive details about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        string memory description,
        address target,
        bytes memory callData,
        uint64 startBlock,
        uint64 endBlock,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes,
        address proposer,
        ProposalState state,
        string memory proposalURI
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.description,
            proposal.target,
            proposal.callData,
            proposal.startBlock,
            proposal.endBlock,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.abstainVotes,
            proposal.proposer,
            proposal.state,
            proposal.proposalURI
        );
    }

    /**
     * @notice Allows users to contribute ERC20 tokens to the DAO treasury.
     * @dev The governanceToken itself, or any other approved ERC20 token.
     * @param _token The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function depositIntoTreasury(IERC20 _token, uint256 _amount) public whenNotPaused nonReentrant {
        if (_amount == 0) revert InvalidArgument();
        if (!_token.transferFrom(msg.sender, address(this), _amount)) revert InsufficientBalance();
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @notice Allows the DAO (via proposal) to withdraw funds from the treasury.
     * @dev This function would typically be called by the `executeProposal` function.
     *      For simplicity in this example, it's gated by ADMIN_ROLE, implying an admin
     *      executes it *after* a successful DAO proposal, or the DAO proposal directly calls it.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawTreasuryFunds(IERC20 _token, address _recipient, uint256 _amount) public onlyRole(ADMIN_ROLE) whenNotPaused nonReentrant {
        if (_recipient == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert InvalidArgument();
        if (_token.balanceOf(address(this)) < _amount) revert InsufficientBalance();
        if (!_token.transfer(_recipient, _amount)) revert InsufficientBalance();
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @notice Allows the DAO (via proposal) to reward validated fragment submitters.
     * @dev This function would typically be called by the `executeProposal` function.
     *      For simplicity, it's gated by ADMIN_ROLE.
     * @param _fragmentId The ID of the fragment to reward.
     * @param _recipient The address of the fragment submitter (or chosen recipient).
     * @param _amount The amount of reward tokens to distribute.
     */
    function distributeFragmentRewards(uint256 _fragmentId, address _recipient, uint256 _amount) public onlyRole(ADMIN_ROLE) whenNotPaused nonReentrant {
        if (_recipient == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert InvalidArgument();
        
        // Ensure fragment is validated before rewarding
        if (!cognitiveFragments[_fragmentId].validated) revert FragmentStakeNotReclaimable(); 

        if (rewardToken.balanceOf(address(this)) < _amount) revert InsufficientBalance();
        if (!rewardToken.transfer(_recipient, _amount)) revert InsufficientBalance();
        // Emits an event with the ID of the proposal that likely triggered this action.
        // Assuming the last created proposal (or specific one) triggered this.
        emit FragmentRewardsDistributed(_proposalIds.current(), _fragmentId, _recipient, _amount);
    }


    // --- V. Cognitive Canvas NFTs (ERC721 & Dynamic Attributes) ---

    /**
     * @notice DAO-controlled function to mint a new Cognitive Canvas NFT.
     * @dev Only callable by an account with the ADMIN_ROLE (acting on behalf of a DAO proposal).
     * @param _to The address to mint the NFT to.
     * @param _initialName The initial name of the Canvas NFT.
     * @param _initialDescription The initial description.
     * @param _initialImageUrl The initial image URL (e.g., placeholder or AI-generated).
     * @param _initialDynamicPropertiesKeys Keys for initial dynamic properties.
     * @param _initialDynamicPropertiesValues Values for initial dynamic properties.
     * @return The ID of the newly minted NFT.
     */
    function mintCognitiveCanvasNFT(
        address _to,
        string memory _initialName,
        string memory _initialDescription,
        string memory _initialImageUrl,
        string[] memory _initialDynamicPropertiesKeys,
        string[] memory _initialDynamicPropertiesValues
    ) public onlyRole(ADMIN_ROLE) whenNotPaused nonReentrant returns (uint256) {
        if (_to == address(0)) revert ZeroAddressNotAllowed();
        if (bytes(_initialName).length == 0 || bytes(_initialDescription).length == 0) revert InvalidArgument();
        if (_initialDynamicPropertiesKeys.length != _initialDynamicPropertiesValues.length) revert InvalidArgument();

        _canvasTokenIds.increment();
        uint256 newId = _canvasTokenIds.current();

        _safeMint(_to, newId);

        CanvasAttributes storage attrs = canvasAttributes[newId];
        attrs.name = _initialName;
        attrs.description = _initialDescription;
        attrs.imageUrl = _initialImageUrl;
        attrs.lastUpdated = uint64(block.timestamp);
        attrs.generationIteration = 1; // First generation

        for (uint i = 0; i < _initialDynamicPropertiesKeys.length; i++) {
            string memory key = _initialDynamicPropertiesKeys[i];
            attrs.dynamicProperties[key] = _initialDynamicPropertiesValues[i];
            attrs.dynamicPropertyKeys.push(key); // Store keys for iteration
        }

        emit CanvasNFTMinted(newId, msg.sender, _to);
        return newId;
    }

    /**
     * @notice Updates specific attributes of a Cognitive Canvas NFT.
     * @dev Only callable by an account with the AI_ORACLE_ROLE or ADMIN_ROLE (via DAO proposal).
     * @param _tokenId The ID of the Cognitive Canvas NFT to update.
     * @param _attributeKey The key of the dynamic attribute to update or add.
     * @param _attributeValue The new value for the dynamic attribute.
     */
    function updateCognitiveCanvasAttributes(
        uint256 _tokenId,
        string memory _attributeKey,
        string memory _attributeValue
    ) public onlyRole(AI_ORACLE_ROLE) whenNotPaused { // Can also be called by ADMIN_ROLE (representing a DAO vote)
        if (ownerOf(_tokenId) == address(0)) revert CannotUpdateNonExistentToken();
        if (bytes(_attributeKey).length == 0) revert InvalidArgument();

        CanvasAttributes storage attrs = canvasAttributes[_tokenId];
        
        // Add key to dynamicPropertyKeys array if it's new
        bool keyExists = false;
        for (uint i = 0; i < attrs.dynamicPropertyKeys.length; i++) {
            if (keccak256(abi.encodePacked(attrs.dynamicPropertyKeys[i])) == keccak256(abi.encodePacked(_attributeKey))) {
                keyExists = true;
                break;
            }
        }
        if (!keyExists) {
            attrs.dynamicPropertyKeys.push(_attributeKey);
        }

        attrs.dynamicProperties[_attributeKey] = _attributeValue;
        attrs.lastUpdated = uint64(block.timestamp);
        attrs.generationIteration++;
        emit CanvasAttributesUpdated(_tokenId, _attributeKey, _attributeValue, attrs.generationIteration);
    }

    /**
     * @notice Retrieves the full attributes of a Cognitive Canvas NFT.
     * @param _tokenId The ID of the Canvas NFT.
     * @return name, description, imageUrl, dynamicPropertyKeys, dynamicPropertyValues, lastUpdated, generationIteration.
     */
    function getCognitiveCanvasAttributes(uint256 _tokenId) public view returns (
        string memory name,
        string memory description,
        string memory imageUrl,
        string[] memory dynamicPropertyKeys,
        string[] memory dynamicPropertyValues,
        uint64 lastUpdated,
        uint256 generationIteration
    ) {
        CanvasAttributes storage attrs = canvasAttributes[_tokenId];
        if (bytes(attrs.name).length == 0 && !_exists(_tokenId)) revert CannotUpdateNonExistentToken(); // NFT doesn't exist or not initialized

        string[] memory keys = attrs.dynamicPropertyKeys;
        string[] memory values = new string[](keys.length);
        for (uint i = 0; i < keys.length; i++) {
            values[i] = attrs.dynamicProperties[keys[i]];
        }

        return (
            attrs.name,
            attrs.description,
            attrs.imageUrl,
            keys,
            values,
            attrs.lastUpdated,
            attrs.generationIteration
        );
    }

    /**
     * @notice Overrides the standard ERC721 `tokenURI` to generate dynamic metadata.
     * @dev Generates on-chain JSON metadata as a Base64 encoded data URI, reflecting the NFT's evolving attributes.
     * @param _tokenId The ID of the Cognitive Canvas NFT.
     * @return A data URI containing the Base64 encoded JSON metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);

        CanvasAttributes storage attrs = canvasAttributes[_tokenId];
        address owner = ownerOf(_tokenId);

        string memory json = string(abi.encodePacked(
            '{"name": "', attrs.name, ' #', Strings.toString(_tokenId),
            '", "description": "', attrs.description,
            '", "image": "', attrs.imageUrl,
            '", "owner": "', Strings.toHexString(uint160(owner), 20),
            '", "attributes": ['
        ));

        // Iterate through stored dynamic property keys
        bool firstAttribute = true;
        for (uint i = 0; i < attrs.dynamicPropertyKeys.length; i++) {
            string memory key = attrs.dynamicPropertyKeys[i];
            string memory value = attrs.dynamicProperties[key];
            if (bytes(value).length > 0) { // Only add if value exists
                if (!firstAttribute) {
                    json = string(abi.encodePacked(json, ','));
                }
                json = string(abi.encodePacked(
                    json, '{"trait_type": "', key, '", "value": "', value, '"}'
                ));
                firstAttribute = false;
            }
        }

        // Add standard attributes
        if (!firstAttribute) {
             json = string(abi.encodePacked(json, ','));
        }
        json = string(abi.encodePacked(
            json, '{"trait_type": "Generation Iteration", "value": ', Strings.toString(attrs.generationIteration), '},',
            '{"trait_type": "Last Updated", "display_type": "date", "value": ', Strings.toString(attrs.lastUpdated), '}'
        ));

        json = string(abi.encodePacked(json, ']}'));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- Standard ERC721 Overrides (included in the function count) ---

    // The following standard ERC721 functions are included in the 20+ count
    // and rely on OpenZeppelin's ERC721 implementation.
    // They are listed here for clarity but their implementation is inherited.

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
        return super.getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override(ERC721, IERC721) returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override(ERC721, IERC721) returns (uint256) {
        return super.balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override(ERC721, IERC721Metadata) returns (string memory) {
        return super.name();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override(ERC721, IERC721Metadata) returns (string memory) {
        return super.symbol();
    }
}
```