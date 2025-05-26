Okay, let's design a smart contract concept around a *Decentralized Self-Amending Constitution*.

The idea is that the core rules and parameters of the contract itself are stored as "Articles" on-chain, and these Articles can only be changed through a governance process defined *within* those very Articles. This creates a self-referential system where the DAO governs its own laws.

This contract will:
1.  Store a set of named "Articles" (key-value pairs essentially, but structured) that define parameters like voting periods, quorum percentage, threshold percentage, timelock delays, etc.
2.  Allow proposals to be created to add, remove, or modify these Articles, or to execute arbitrary external calls (standard DAO action).
3.  Implement a token-weighted voting system with delegation.
4.  Include standard DAO lifecycle: propose -> vote -> queue (with timelock) -> execute.
5.  Critically, the parameters governing propose/vote/queue/execute *are read directly from the stored Articles*, making the system dynamically configurable by its own governance.

**Outline:**

1.  **License and Pragma**
2.  **Imports** (e.g., for token interaction)
3.  **Enums** (Proposal State, Article Type, Action Type)
4.  **Structs** (Article, Action, Proposal)
5.  **State Variables** (Governance Token, Articles mapping, Proposals mapping, counters, delegation tracking)
6.  **Events** (Article related, Proposal related, Voting related, Delegation related)
7.  **Modifiers** (State checks, Access control - though most governance is permissionless via successful vote)
8.  **Constructor** (Initialize with mandatory core Articles)
9.  **Internal Helpers** (Get Article values, Calculate Votes, interpret bytes)
10. **Article Management Functions (Internal)** (Add, Change, Remove Article - only callable by successful governance execution)
11. **Article Reading Functions (Public)** (Get Article details, Get specific types, List Articles)
12. **Parameter Reading Functions (Public)** (Read core governance parameters from Articles)
13. **Delegation Functions (Public)**
14. **Voting Power Functions (Public)** (Get votes at snapshot)
15. **Proposal Creation Function (Public)**
16. **Voting Function (Public)**
17. **Proposal State Reading Function (Public)**
18. **Proposal Lifecycle Functions (Public)** (Queue, Execute, Cancel)
19. **Proposal Detail Reading Functions (Public)**
20. **Miscellaneous Getters (Public)** (Counters, etc.)

**Function Summary:**

1.  `constructor(address _govTokenAddress)`: Initializes the contract, sets the governance token, and creates initial core "Articles" defining the default governance rules.
2.  `delegate(address delegatee)`: Allows a token holder to delegate their voting power.
3.  `renounceDelegate()`: Allows a token holder to revoke their delegation.
4.  `getVotes(address voter, uint256 blockNumber)`: Gets the voting power of an address at a specific block number (relies on the GOV token supporting snapshots like ERC20Votes).
5.  `createProposal(Action[] memory actions, string memory description)`: Allows a token holder (meeting a minimum threshold read from Articles) to create a new proposal with one or more actions.
6.  `vote(uint256 proposalId, bool support)`: Allows a token holder (or their delegatee) to cast a vote on an active proposal.
7.  `queueProposal(uint256 proposalId)`: Moves a successful proposal to the queued state, starting the timelock.
8.  `executeProposal(uint256 proposalId)`: Executes the actions of a queued proposal after the timelock has passed. This function handles both external calls and internal Article modifications.
9.  `cancelProposal(uint256 proposalId)`: Allows the proposer to cancel a proposal before it becomes active.
10. `getProposalState(uint256 proposalId)`: Returns the current state of a proposal (Pending, Active, Succeeded, Failed, Queued, Executed, Expired).
11. `getProposalDetails(uint256 proposalId)`: Returns key details about a proposal (proposer, description, creation time, etc.).
12. `getProposalVotes(uint256 proposalId)`: Returns the current vote counts (for, against) for a proposal.
13. `getProposalActions(uint256 proposalId)`: Returns the list of actions associated with a proposal.
14. `getArticle(string memory name)`: Returns the full `Article` struct for a given name.
15. `getArticleValueUint(string memory name)`: Reads an Article's value and interprets it as a `uint256`.
16. `getArticleValueString(string memory name)`: Reads an Article's value and interprets it as a `string`.
17. `getArticleValueAddress(string memory name)`: Reads an Article's value and interprets it as an `address`.
18. `getArticleValueBool(string memory name)`: Reads an Article's value and interprets it as a `bool`.
19. `getAllArticleNames()`: Returns an array of all currently defined Article names.
20. `getVotingPeriodSeconds()`: Reads the current voting period from the relevant Article.
21. `getQuorumNumerator()`: Reads the current quorum numerator percentage from the relevant Article.
22. `getQuorumDenominator()`: Reads the current quorum denominator percentage from the relevant Article.
23. `getVoteThresholdNumerator()`: Reads the current vote threshold numerator percentage from the relevant Article.
24. `getVoteThresholdDenominator()`: Reads the current vote threshold denominator percentage from the relevant Article.
25. `getTimelockDelaySeconds()`: Reads the current timelock delay from the relevant Article.
26. `getProposalCount()`: Returns the total number of proposals created.
27. `getDelegates(address delegator)`: Returns the address the delegator has delegated their votes to.
28. `hasVoted(uint256 proposalId, address voter)`: Checks if a specific address has voted on a proposal.

*(Note: This already lists 28 functions, exceeding the minimum 20. The internal functions for adding/changing/removing articles are crucial but not exposed publicly as direct calls; they are executed *only* via successful governance proposals.)*

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For max/min

// --- Outline ---
// 1. License and Pragma
// 2. Imports (IERC20Votes, Math)
// 3. Enums (Proposal State, Article Type, Action Type)
// 4. Structs (Article, Action, Proposal)
// 5. State Variables (Governance Token, Articles mapping, Proposals mapping, counters, delegation tracking)
// 6. Events (Article related, Proposal related, Voting related, Delegation related)
// 7. Modifiers (State checks)
// 8. Constructor (Initialize with mandatory core Articles)
// 9. Internal Helpers (Get Article values, Calculate Votes, interpret bytes)
// 10. Article Management Functions (Internal) (Add, Change, Remove Article - only callable by successful governance execution)
// 11. Article Reading Functions (Public) (Get Article details, Get specific types, List Articles)
// 12. Parameter Reading Functions (Public) (Read core governance parameters from Articles)
// 13. Delegation Functions (Public)
// 14. Voting Power Functions (Public) (Get votes at snapshot)
// 15. Proposal Creation Function (Public)
// 16. Voting Function (Public)
// 17. Proposal State Reading Function (Public)
// 18. Proposal Lifecycle Functions (Public) (Queue, Execute, Cancel)
// 19. Proposal Detail Reading Functions (Public)
// 20. Miscellaneous Getters (Public) (Counters, etc.)

// --- Function Summary ---
// 1. constructor(address _govTokenAddress): Initializes the contract, sets the governance token, and creates initial core "Articles" defining the default governance rules.
// 2. delegate(address delegatee): Allows a token holder to delegate their voting power.
// 3. renounceDelegate(): Allows a token holder to revoke their delegation.
// 4. getVotes(address voter, uint256 blockNumber): Gets the voting power of an address at a specific block number (relies on the GOV token supporting snapshots like ERC20Votes).
// 5. createProposal(Action[] memory actions, string memory description): Allows a token holder (meeting a minimum threshold read from Articles) to create a new proposal with one or more actions.
// 6. vote(uint256 proposalId, bool support): Allows a token holder (or their delegatee) to cast a vote on an active proposal.
// 7. queueProposal(uint256 proposalId): Moves a successful proposal to the queued state, starting the timelock.
// 8. executeProposal(uint256 proposalId): Executes the actions of a queued proposal after the timelock has passed. Handles external calls and internal Article modifications.
// 9. cancelProposal(uint256 proposalId): Allows the proposer to cancel a proposal before it becomes active.
// 10. getProposalState(uint256 proposalId): Returns the current state of a proposal.
// 11. getProposalDetails(uint256 proposalId): Returns key details about a proposal.
// 12. getProposalVotes(uint256 proposalId): Returns the current vote counts for a proposal.
// 13. getProposalActions(uint256 proposalId): Returns the list of actions associated with a proposal.
// 14. getArticle(string memory name): Returns the full Article struct.
// 15. getArticleValueUint(string memory name): Reads an Article's value as uint256.
// 16. getArticleValueString(string memory name): Reads an Article's value as string.
// 17. getArticleValueAddress(string memory name): Reads an Article's value as address.
// 18. getArticleValueBool(string memory name): Reads an Article's value as bool.
// 19. getAllArticleNames(): Returns an array of all currently defined Article names.
// 20. getVotingPeriodSeconds(): Reads the current voting period from Article.
// 21. getQuorumNumerator(): Reads the current quorum numerator from Article.
// 22. getQuorumDenominator(): Reads the current quorum denominator from Article.
// 23. getVoteThresholdNumerator(): Reads the current vote threshold numerator from Article.
// 24. getVoteThresholdDenominator(): Reads the current vote threshold denominator from Article.
// 25. getTimelockDelaySeconds(): Reads the current timelock delay from Article.
// 26. getProposalCount(): Returns the total number of proposals created.
// 27. getDelegates(address delegator): Returns the address the delegator has delegated to.
// 28. hasVoted(uint256 proposalId, address voter): Checks if a voter has voted on a proposal.
// ... (Internal functions _addArticle, _changeArticle, _removeArticle are not in this public list)

contract DecentralizedSelfAmendingConstitution {

    IERC20Votes public immutable govToken;

    enum ProposalState {
        Pending,     // Created but voting hasn't started
        Active,      // Voting is open
        Canceled,    // Proposer canceled before Active
        Defeated,    // Voting ended, did not pass threshold or quorum
        Succeeded,   // Voting ended, passed threshold and quorum
        Queued,      // Succeeded and moved to timelock
        Expired,     // Succeeded but not queued/executed in time
        Executed     // Queued and actions performed
    }

    // Types of data an Article can hold
    enum ArticleType {
        Uint256,
        String,
        Address,
        Bool,
        Bytes
    }

    // Types of actions a proposal can perform
    enum ActionType {
        ExternalCall,     // Call an external contract/address
        ArticleChange,    // Change an existing Article
        ArticleAdd,       // Add a new Article
        ArticleRemove     // Remove an Article
    }

    struct Article {
        string name;          // e.g., "votingPeriodSeconds"
        string description;   // Explanation of the article
        ArticleType articleType; // Type of data stored in 'value'
        bytes value;          // The actual value (encoded)
    }

    struct Action {
        ActionType actionType; // What kind of action is this?
        address target;        // Target address for ExternalCall (0x0 for Article actions)
        uint256 value;         // ETH value for ExternalCall (0 for Article actions)
        bytes callData;        // Calldata for ExternalCall (encoded Article data for Article actions)
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        Action[] actions;
        uint256 creationBlock;
        uint256 startBlock;      // Block when voting becomes active
        uint256 endBlock;        // Block when voting ends
        uint256 quorumSnapshotBlock; // Block at which quorum is calculated (e.g., end block)
        uint256 voteSnapshotBlock;   // Block at which voting power is snapshotted (e.g., start block - 1)
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingSupplySnapshot; // Total token supply at snapshot block
        mapping(address => bool) hasVoted; // Track voters
        ProposalState state;
        uint256 queueTime;       // Timestamp when queued
        uint256 executionTime;   // Timestamp when executed
    }

    mapping(string => Article) internal articles; // Store the constitution's articles
    string[] internal articleNames; // Maintain order/list of article names

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Required Articles (names used as keys)
    string constant ARTICLE_VOTING_PERIOD_SECONDS = "votingPeriodSeconds";
    string constant ARTICLE_QUORUM_NUMERATOR = "quorumNumerator";
    string constant ARTICLE_QUORUM_DENOMINATOR = "quorumDenominator";
    string constant ARTICLE_VOTE_THRESHOLD_NUMERATOR = "voteThresholdNumerator";
    string constant ARTICLE_VOTE_THRESHOLD_DENOMINATOR = "voteThresholdDenominator";
    string constant ARTICLE_TIMELOCK_DELAY_SECONDS = "timelockDelaySeconds";
    string constant ARTICLE_PROPOSAL_THRESHOLD = "proposalCreationThreshold"; // Minimum token balance to create a proposal

    // Events
    event ArticleAdded(string indexed name, ArticleType articleType, bytes value);
    event ArticleChanged(string indexed name, ArticleType oldType, bytes oldValue, ArticleType newType, bytes newValue);
    event ArticleRemoved(string indexed name);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 creationBlock, uint256 startBlock, uint256 endBlock);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalQueued(uint256 indexed proposalId, uint256 queueTime);
    event ProposalExecuted(uint256 indexed proposalId, uint256 executionTime);
    event ProposalCanceled(uint256 indexed proposalId);
    event DelegationSet(address indexed delegator, address indexed delegatee);


    constructor(address _govTokenAddress) {
        require(_govTokenAddress != address(0), "Invalid token address");
        govToken = IERC20Votes(_govTokenAddress);

        // Initialize core articles with default values
        // These are the *initial* rules, they can be changed later by governance
        _addArticle(ARTICLE_VOTING_PERIOD_SECONDS, "Duration of the voting period in seconds", ArticleType.Uint256, abi.encode(uint256(72 * 3600))); // 3 days
        _addArticle(ARTICLE_QUORUM_NUMERATOR, "Numerator for calculating the quorum percentage (e.g., 4 for 4%)", ArticleType.Uint256, abi.encode(uint256(4))); // 4%
        _addArticle(ARTICLE_QUORUM_DENOMINATOR, "Denominator for calculating the quorum percentage (e.g., 100 for %)", ArticleType.Uint256, abi.encode(uint256(100))); // 100%
        _addArticle(ARTICLE_VOTE_THRESHOLD_NUMERATOR, "Numerator for calculating the vote threshold percentage (e.g., 50 for 50%)", ArticleType.Uint256, abi.encode(uint256(50))); // 50%
        _addArticle(ARTICLE_VOTE_THRESHOLD_DENOMINATOR, "Denominator for calculating the vote threshold percentage (e.g., 100 for %)", ArticleType.Uint256, abi.encode(uint256(100))); // 100%
        _addArticle(ARTICLE_TIMELOCK_DELAY_SECONDS, "Delay period before a queued proposal can be executed", ArticleType.Uint256, abi.encode(uint256(2 * 24 * 3600))); // 2 days
        _addArticle(ARTICLE_PROPOSAL_THRESHOLD, "Minimum token balance required to create a proposal", ArticleType.Uint256, abi.encode(uint256(100e18))); // 100 tokens (assuming 18 decimals)
    }

    // --- Internal Article Management (Only callable via executed proposals) ---

    /// @dev Adds a new Article. Internal function, only called by executeProposal.
    function _addArticle(string memory name, string memory description, ArticleType articleType, bytes memory value) internal {
        require(articles[name].articleType == ArticleType.Bytes && articles[name].value.length == 0, "Article already exists");
        articles[name] = Article(name, description, articleType, value);
        articleNames.push(name);
        emit ArticleAdded(name, articleType, value);
    }

    /// @dev Changes an existing Article. Internal function, only called by executeProposal.
    function _changeArticle(string memory name, string memory description, ArticleType articleType, bytes memory value) internal {
        require(articles[name].articleType != ArticleType.Bytes || articles[name].value.length != 0, "Article does not exist");
        Article storage oldArticle = articles[name];
        ArticleType oldType = oldArticle.articleType;
        bytes memory oldValue = oldArticle.value;
        oldArticle.description = description;
        oldArticle.articleType = articleType;
        oldArticle.value = value;
        emit ArticleChanged(name, oldType, oldValue, articleType, value);
    }

    /// @dev Removes an Article. Internal function, only called by executeProposal.
    function _removeArticle(string memory name) internal {
         require(articles[name].articleType != ArticleType.Bytes || articles[name].value.length != 0, "Article does not exist");
         // Prevent removing core articles needed for governance
         require(
             keccak256(abi.encodePacked(name)) != keccak256(abi.encodePacked(ARTICLE_VOTING_PERIOD_SECONDS)) &&
             keccak256(abi.encodePacked(name)) != keccak256(abi.encodePacked(ARTICLE_QUORUM_NUMERATOR)) &&
             keccak256(abi.encodePacked(name)) != keccak256(abi.encodePacked(ARTICLE_QUORUM_DENOMINATOR)) &&
             keccak256(abi.encodePacked(name)) != keccak256(abi.encodePacked(ARTICLE_VOTE_THRESHOLD_NUMERATOR)) &&
             keccak256(abi.encodePacked(name)) != keccak256(abi.encodePacked(ARTICLE_VOTE_THRESHOLD_DENOMINATOR)) &&
             keccak256(abi.encodePacked(name)) != keccak256(abi.encodePacked(ARTICLE_TIMELOCK_DELAY_SECONDS)) &&
             keccak256(abi.encodePacked(name)) != keccak256(abi.encodePacked(ARTICLE_PROPOSAL_THRESHOLD)),
             "Cannot remove core governance article"
         );

        delete articles[name];
        // Remove from articleNames array (inefficient for large numbers, but simpler)
        for (uint i = 0; i < articleNames.length; i++) {
            if (keccak256(abi.encodePacked(articleNames[i])) == keccak256(abi.encodePacked(name))) {
                articleNames[i] = articleNames[articleNames.length - 1];
                articleNames.pop();
                break;
            }
        }
        emit ArticleRemoved(name);
    }

    // --- Internal Helpers ---

    /// @dev Gets an Article struct by name.
    function _getArticle(string memory name) internal view returns (Article storage) {
        require(articles[name].articleType != ArticleType.Bytes || articles[name].value.length != 0, "Article not found");
        return articles[name];
    }

    /// @dev Reads an Article's value and interprets it as uint256.
    function _getArticleValueUint(string memory name) internal view returns (uint256) {
        Article storage article = _getArticle(name);
        require(article.articleType == ArticleType.Uint256, "Article is not Uint256 type");
        return abi.decode(article.value, (uint256));
    }

     /// @dev Reads an Article's value and interprets it as string.
    function _getArticleValueString(string memory name) internal view returns (string memory) {
        Article storage article = _getArticle(name);
        require(article.articleType == ArticleType.String, "Article is not String type");
        return abi.decode(article.value, (string));
    }

    /// @dev Reads an Article's value and interprets it as address.
    function _getArticleValueAddress(string memory name) internal view returns (address) {
        Article storage article = _getArticle(name);
        require(article.articleType == ArticleType.Address, "Article is not Address type");
        return abi.decode(article.value, (address));
    }

     /// @dev Reads an Article's value and interprets it as bool.
    function _getArticleValueBool(string memory name) internal view returns (bool) {
        Article storage article = _getArticle(name);
        require(article.articleType == ArticleType.Bool, "Article is not Bool type");
        return abi.decode(article.value, (bool));
    }

     /// @dev Reads an Article's value and interprets it as bytes.
    function _getArticleValueBytes(string memory name) internal view returns (bytes memory) {
        Article storage article = _getArticle(name);
        require(article.articleType == ArticleType.Bytes, "Article is not Bytes type");
        return article.value; // Already bytes
    }

    // --- Public Article Reading Functions ---

    /// @notice Gets the full Article struct for a given name.
    function getArticle(string memory name) public view returns (Article memory) {
        Article storage article = _getArticle(name);
        return article;
    }

    /// @notice Reads an Article's value and interprets it as uint256.
    function getArticleValueUint(string memory name) public view returns (uint256) {
       return _getArticleValueUint(name);
    }

    /// @notice Reads an Article's value and interprets it as string.
    function getArticleValueString(string memory name) public view returns (string memory) {
       return _getArticleValueString(name);
    }

    /// @notice Reads an Article's value and interprets it as address.
    function getArticleValueAddress(string memory name) public view returns (address) {
       return _getArticleValueAddress(name);
    }

    /// @notice Reads an Article's value and interprets it as bool.
    function getArticleValueBool(string memory name) public view returns (bool) {
       return _getArticleValueBool(name);
    }

    /// @notice Reads an Article's value and interprets it as bytes.
    function getArticleValueBytes(string memory name) public view returns (bytes memory) {
       return _getArticleValueBytes(name);
    }


    /// @notice Returns a list of all currently defined Article names.
    function getAllArticleNames() public view returns (string[] memory) {
        return articleNames;
    }

    /// @notice Returns the total number of articles.
    function getArticleCount() public view returns (uint256) {
        return articleNames.length;
    }

    // --- Public Parameter Reading Functions (Read from Articles) ---

    /// @notice Reads the current voting period from the relevant Article in seconds.
    function getVotingPeriodSeconds() public view returns (uint256) {
        return _getArticleValueUint(ARTICLE_VOTING_PERIOD_SECONDS);
    }

    /// @notice Reads the current quorum numerator percentage from the relevant Article.
    function getQuorumNumerator() public view returns (uint256) {
        return _getArticleValueUint(ARTICLE_QUORUM_NUMERATOR);
    }

    /// @notice Reads the current quorum denominator percentage from the relevant Article.
    function getQuorumDenominator() public view returns (uint256) {
        return _getArticleValueUint(ARTICLE_QUORUM_DENOMINATOR);
    }

    /// @notice Reads the current vote threshold numerator percentage from the relevant Article.
    function getVoteThresholdNumerator() public view returns (uint256) {
        return _getArticleValueUint(ARTICLE_VOTE_THRESHOLD_NUMERATOR);
    }

    /// @notice Reads the current vote threshold denominator percentage from the relevant Article.
    function getVoteThresholdDenominator() public view returns (uint256) {
        return _getArticleValueUint(ARTICLE_VOTE_THRESHOLD_DENOMINATOR);
    }

    /// @notice Reads the current timelock delay from the relevant Article in seconds.
    function getTimelockDelaySeconds() public view returns (uint256) {
        return _getArticleValueUint(ARTICLE_TIMELOCK_DELAY_SECONDS);
    }

    /// @notice Reads the minimum token balance required to create a proposal from the relevant Article.
    function getProposalCreationThreshold() public view returns (uint256) {
        return _getArticleValueUint(ARTICLE_PROPOSAL_THRESHOLD);
    }

    // --- Delegation ---

    /// @notice Allows a token holder to delegate their voting power.
    function delegate(address delegatee) public {
        govToken.delegate(delegatee);
        emit DelegationSet(msg.sender, delegatee);
    }

    /// @notice Allows a token holder to revoke their delegation.
    function renounceDelegate() public {
        govToken.delegate(address(0));
        emit DelegationSet(msg.sender, address(0));
    }

    /// @notice Returns the address the delegator has delegated their votes to.
    function getDelegates(address delegator) public view returns (address) {
        return govToken.delegates(delegator);
    }

    // --- Voting Power ---

    /// @notice Gets the voting power of an address at a specific block number.
    /// @dev Relies on the GOV token implementing ERC20Votes.getVotes(address, blockNumber).
    function getVotes(address voter, uint256 blockNumber) public view returns (uint256) {
        return govToken.getVotes(voter, blockNumber);
    }

    // --- Proposal Management ---

    /// @notice Creates a new proposal with a set of actions.
    /// @param actions The list of actions to be performed if the proposal passes.
    /// @param description A descriptive string for the proposal.
    function createProposal(Action[] memory actions, string memory description) public returns (uint256) {
        require(govToken.getVotes(msg.sender, block.number) >= getProposalCreationThreshold(), "Insufficient voting power to create proposal");
        require(actions.length > 0, "Proposal must contain at least one action");

        uint256 proposalId = proposalCount++;
        uint256 votingPeriod = getVotingPeriodSeconds(); // Read dynamically
        uint256 startBlock = block.number + 1; // Voting starts in the next block
        uint256 endBlock = startBlock + votingPeriod / block.chainid.blocktime; // Estimate end block based on average blocktime

        // Store actions by copying from memory
        Action[] memory proposalActions = new Action[](actions.length);
        for(uint i = 0; i < actions.length; i++) {
            proposalActions[i] = actions[i];
        }

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            actions: proposalActions,
            creationBlock: block.number,
            startBlock: startBlock,
            endBlock: endBlock,
            quorumSnapshotBlock: endBlock, // Quorum checked at the end of the voting period
            voteSnapshotBlock: block.number, // Voting power snapshotted at proposal creation block
            votesFor: 0,
            votesAgainst: 0,
            totalVotingSupplySnapshot: govToken.getPastTotalSupply(block.number), // Total supply at snapshot
            hasVoted: new mapping(address => bool),
            state: ProposalState.Pending, // Starts as Pending
            queueTime: 0,
            executionTime: 0
        });

        // Move to Active state in the next block
        // This is a simplification; ideally state transition is handled by a view function based on block.number
        proposals[proposalId].state = ProposalState.Active; // Transition immediately for simplicity, or use a check in getProposalState

        emit ProposalCreated(proposalId, msg.sender, description, block.number, startBlock, endBlock);

        return proposalId;
    }


    /// @notice Casts a vote on an active proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for', false for 'against'.
    function vote(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(getProposalState(proposalId) == ProposalState.Active, "Proposal not active");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint256 voterVotes = getVotes(msg.sender, proposal.voteSnapshotBlock);
        require(voterVotes > 0, "Voter has no voting power");

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor += voterVotes;
        } else {
            proposal.votesAgainst += voterVotes;
        }

        emit Voted(proposalId, msg.sender, support, voterVotes);
    }

    /// @notice Moves a successful proposal to the queued state.
    /// @dev Can only be called if the proposal state is Succeeded and hasn't expired.
    function queueProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Proposal must be in Succeeded state");

        proposal.state = ProposalState.Queued;
        proposal.queueTime = block.timestamp;

        emit ProposalQueued(proposalId, block.timestamp);
        emit ProposalStateChanged(proposalId, ProposalState.Queued);
    }

    /// @notice Executes the actions of a queued proposal.
    /// @dev Can only be called if the proposal state is Queued and the timelock has passed.
    function executeProposal(uint256 proposalId) public payable {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(getProposalState(proposalId) == ProposalState.Queued, "Proposal must be in Queued state");
        require(block.timestamp >= proposal.queueTime + getTimelockDelaySeconds(), "Timelock has not passed");

        proposal.state = ProposalState.Executed;
        proposal.executionTime = block.timestamp;

        // Execute actions
        for (uint i = 0; i < proposal.actions.length; i++) {
            Action storage action = proposal.actions[i];

            if (action.actionType == ActionType.ExternalCall) {
                (bool success, bytes memory returndata) = action.target.call{value: action.value}(action.callData);
                require(success, string(abi.encodePacked("External call failed for action ", Strings.toString(i), ": ", returndata)));
                 // TODO: Could emit an ActionExecuted event here including success/returndata
            } else if (action.actionType == ActionType.ArticleChange) {
                (string memory name, string memory description, ArticleType articleType, bytes memory value) = abi.decode(action.callData, (string, string, ArticleType, bytes));
                _changeArticle(name, description, articleType, value);
            } else if (action.actionType == ActionType.ArticleAdd) {
                 (string memory name, string memory description, ArticleType articleType, bytes memory value) = abi.decode(action.callData, (string, string, ArticleType, bytes));
                _addArticle(name, description, articleType, value);
            } else if (action.actionType == ActionType.ArticleRemove) {
                 (string memory name) = abi.decode(action.callData, (string));
                 _removeArticle(name);
            } else {
                revert("Unknown action type");
            }
        }

        emit ProposalExecuted(proposalId, block.timestamp);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    /// @notice Allows the proposer to cancel a proposal.
    /// @dev Can only be called if the proposal is in the Pending state.
    function cancelProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(proposal.proposer == msg.sender, "Only proposer can cancel");
        require(getProposalState(proposalId) == ProposalState.Pending, "Proposal not in Pending state");

        proposal.state = ProposalState.Canceled;

        emit ProposalCanceled(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Canceled);
    }


    // --- Proposal State and Details ---

    /// @notice Gets the current state of a proposal.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        // Require the proposal to exist
        if (proposal.id != proposalId && proposalId != 0) {
             // Handle non-existent IDs gracefully, maybe return a specific state or revert
             // For now, let's assume valid IDs are checked by calling functions.
             // The mapping default value check `proposal.id != proposalId` might be ambiguous for ID 0
             // A safer check would be to rely on a separate mapping `proposalExists[proposalId]` or similar if ID 0 is possible.
             // Assuming proposalCount starts from 0 and proposalId is incremented, ID 0 is the first proposal.
             // Let's just check against the default struct value for simplicity, assuming ID 0 is valid.
             if (proposal.creationBlock == 0 && proposal.id != 0) return ProposalState.Pending; // Sentinel for non-existent
        }


        // Handle states that don't change
        if (proposal.state == ProposalState.Canceled) return ProposalState.Canceled;
        if (proposal.state == ProposalState.Executed) return ProposalState.Executed;

        // Evaluate current state based on time/block and votes
        if (block.number < proposal.startBlock) return ProposalState.Pending;
        if (block.number < proposal.endBlock) return ProposalState.Active;

        // Voting period has ended, determine outcome or check timelock states
        if (proposal.state == ProposalState.Queued) {
             if (block.timestamp >= proposal.queueTime + getTimelockDelaySeconds()) return ProposalState.Queued; // Still in Queued state
             // If we wanted an Expired state *after* queuing (e.g. if not executed promptly), add check here
             return ProposalState.Queued; // Timelock not yet passed
        }


        // Voting period is over, determine Succeeded or Defeated
        // Calculate total votes cast by voters with > 0 voting power at snapshot
        // This is complex to do accurately and efficiently on-chain for *all* possible voters.
        // A simpler model: Quorum is calculated based on total supply *at the snapshot*.
        // Total votes cast should meet quorum %. Votes For must meet threshold %.
        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumNumerator = getQuorumNumerator();
        uint256 quorumDenominator = getQuorumDenominator();
        uint256 voteThresholdNumerator = getVoteThresholdNumerator();
        uint256 voteThresholdDenominator = getVoteThresholdDenominator();

        // Quorum Check: total votes cast >= (total supply snapshot * quorum_numerator / quorum_denominator)
        uint256 requiredQuorum = (proposal.totalVotingSupplySnapshot * quorumNumerator) / quorumDenominator;
        bool meetsQuorum = totalVotesCast >= requiredQuorum;

        // Threshold Check: votesFor > votesAgainst *AND* votesFor >= (total votes cast * threshold_numerator / threshold_denominator)
        bool meetsThreshold = proposal.votesFor > proposal.votesAgainst &&
                              (proposal.votesFor * voteThresholdDenominator) >= (totalVotesCast * voteThresholdNumerator); // Avoid division before multiplication

        if (meetsQuorum && meetsThreshold) {
             if (proposal.state == ProposalState.Succeeded) {
                 // If it was already marked Succeeded, check for expiration
                 // Let's add a maximum queue time based on an Article (e.g., 30 days)
                 uint256 maxQueueDelay = _getArticleValueUint("maxQueueDelaySeconds"); // Need to add this Article
                 if (proposal.queueTime != 0 && block.timestamp >= proposal.queueTime + maxQueueDelay) {
                    return ProposalState.Expired; // Succeeded but expired from queue
                 }
                 // If not expired, it's still Succeeded or Queued/Executed (handled above)
                 return ProposalState.Succeeded;
             }
             return ProposalState.Succeeded; // Just finished voting period, succeeded
        } else {
             if (proposal.state == ProposalState.Succeeded) {
                  // If it was Succeeded but timelock expired without queuing/executing
                 uint256 maxQueueDelay = _getArticleValueUint("maxQueueDelaySeconds"); // Need to add this Article
                  if (proposal.queueTime == 0 && block.timestamp >= proposal.endBlock + maxQueueDelay) {
                     return ProposalState.Expired; // Succeeded but expired before queuing
                  }
             }
             return ProposalState.Defeated; // Did not meet quorum or threshold
        }
    }


    /// @notice Returns key details about a proposal.
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 creationBlock,
        uint256 startBlock,
        uint256 endBlock,
        uint256 voteSnapshotBlock,
        uint256 quorumSnapshotBlock,
        uint256 totalVotingSupplySnapshot,
        ProposalState state,
        uint256 queueTime,
        uint256 executionTime
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId || proposalId == 0 && proposal.creationBlock != 0, "Proposal does not exist"); // Handle ID 0 edge case if needed

        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.creationBlock,
            proposal.startBlock,
            proposal.endBlock,
            proposal.voteSnapshotBlock,
            proposal.quorumSnapshotBlock,
            proposal.totalVotingSupplySnapshot,
            getProposalState(proposalId), // Calculate current state
            proposal.queueTime,
            proposal.executionTime
        );
    }

    /// @notice Returns the current vote counts (for, against) for a proposal.
    function getProposalVotes(uint256 proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId || proposalId == 0 && proposal.creationBlock != 0, "Proposal does not exist");
        return (proposal.votesFor, proposal.votesAgainst);
    }

    /// @notice Returns the list of actions associated with a proposal.
    function getProposalActions(uint256 proposalId) public view returns (Action[] memory) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id == proposalId || proposalId == 0 && proposal.creationBlock != 0, "Proposal does not exist");
         return proposal.actions;
    }

    /// @notice Checks if a specific address has voted on a proposal.
    function hasVoted(uint256 proposalId, address voter) public view returns (bool) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id == proposalId || proposalId == 0 && proposal.creationBlock != 0, "Proposal does not exist");
         return proposal.hasVoted[voter];
    }


    // --- Miscellaneous Getters ---

    /// @notice Returns the total number of proposals created.
    function getProposalCount() public view returns (uint256) {
        return proposalCount;
    }

    // Fallback function to receive ETH for proposals with value
    receive() external payable {}
    fallback() external payable {}
}
```