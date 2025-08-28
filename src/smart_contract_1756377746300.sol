This smart contract, `AetheriaGenesis`, orchestrates a decentralized ecosystem around "Aetherial Artifacts" – dynamic NFTs that evolve based on community interaction and external AI-driven sentiment analysis (simulated via an oracle). It features a robust, reputation-based DAO governance system and gamified "Discovery Challenges" to foster community engagement and content generation.

The core idea is to create a living, evolving collection of digital assets where their characteristics are not static but are influenced by a blend of collective human insight and computational intelligence.

---

## Contract: `AetheriaGenesis`

### Outline:

1.  **Core Artifact Management (Aetherial Artifacts - Dynamic ERC721 NFTs)**
    *   Defines the structure and properties of Aetherial Artifacts.
    *   Functions for minting, requesting evolution (via oracle), fulfilling evolution, and tracking interactions.
    *   Inherits `ERC721` for standard NFT functionality, overriding `tokenURI` for dynamic metadata.
2.  **Insight Points (Reputation System)**
    *   A non-transferable point system representing a user's reputation and influence within the ecosystem.
    *   Supports delegation of voting power, akin to a simplified liquid democracy.
3.  **DAO Governance**
    *   Enables the community (weighted by Insight Points) to propose, vote on, and execute changes to the protocol or new initiatives.
    *   Proposals can include awarding Insight Points, setting oracle addresses, or pausing the contract.
4.  **Discovery Challenges & Curation**
    *   A gamified mechanism for users to propose new Aetherial Artifact concepts or curate existing ones.
    *   Features submission periods, voting, and rewards for winning entries, fostering creative contribution.
5.  **Oracle Interface (Simulated)**
    *   A dedicated interface for a (simulated) external AI oracle service to push sentiment analysis results back to the contract, triggering artifact evolution.
    *   Includes a development function to manually simulate oracle calls for testing purposes.
6.  **Access Control & Utility**
    *   `Ownable` (initially, with DAO expected to take over ownership for key functions).
    *   `Pausable` for emergency control.
    *   Functions for setting base URI and withdrawing funds.

### Function Summary:

**I. Core Artifact Management (Dynamic ERC721 NFTs)**

1.  `mintInitialArtifact(string memory _initialURI, uint256 _initialSentiment)`: Mints a new Aetherial Artifact NFT with an initial metadata URI and sentiment score.
2.  `requestArtifactEvolution(uint256 _artifactId)`: Initiates a request to the external AI oracle for the specified artifact's evolution. Logs an event for off-chain listeners.
3.  `fulfillArtifactEvolution(uint256 _artifactId, uint256 _newSentimentScore, string memory _newMetadataURI)`: Oracle-only callback function to update an artifact's sentiment score, metadata URI, and evolution stage.
4.  `getArtifactDetails(uint256 _artifactId)`: Returns a structured view of all current details for a given Aetherial Artifact.
5.  `signalArtifactInteraction(uint256 _artifactId)`: Allows a user to register an interaction with an artifact, incrementing its total interaction count.
6.  `tokenURI(uint256 _tokenId)`: Overrides the standard ERC721 `tokenURI` to dynamically fetch the latest metadata URI from the artifact's state.

**II. Insight Points (Reputation System)**

7.  `awardInsightPoints(address _recipient, uint256 _amount)`: Grants a specified amount of Insight Points to an address. Only callable by the DAO/owner.
8.  `deductInsightPoints(address _recipient, uint256 _amount)`: Deducts a specified amount of Insight Points from an address. Only callable by the DAO/owner.
9.  `getInsightPoints(address _user)`: Returns the direct Insight Points held by a user (excluding delegated points).
10. `delegateInsightPoints(address _delegatee, uint256 _amount)`: Allows a user to delegate a portion of their Insight Points to another address for governance purposes.
11. `undelegateInsightPoints(uint256 _amount)`: Allows a user to recall previously delegated Insight Points.
12. `getEffectiveInsightPoints(address _user)`: Returns the total effective Insight Points for a user, comprising their own points plus any points delegated to them. This is used for voting power.

**III. DAO Governance**

13. `createProposal(string memory _description, bytes memory _calldata, address _target, uint256 _value, uint256 _duration)`: Creates a new governance proposal that can include execution logic for the contract. Requires sufficient Insight Points.
14. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to cast a vote (for or against) on an active proposal using their effective Insight Points.
15. `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed its voting period and met the necessary approval thresholds.
16. `getProposalDetails(uint256 _proposalId)`: Retrieves all pertinent information about a specific governance proposal.

**IV. Discovery Challenges & Curation**

17. `createDiscoveryChallenge(string memory _topic, uint256 _submissionPeriod, uint256 _votingPeriod, uint256 _rewardAmount, address _rewardToken)`: Initiates a new community challenge with specified periods and a reward. Callable by the DAO/owner.
18. `submitChallengeEntry(uint256 _challengeId, string memory _entryURI)`: Allows users to submit an entry (e.g., a new artifact concept's metadata URI) to an active challenge.
19. `voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId)`: Enables users to vote on a submitted challenge entry using their effective Insight Points.
20. `determineChallengeWinner(uint256 _challengeId)`: Callable by the DAO/owner to finalize a challenge, identify the winning entry based on votes, and record the winner.
21. `claimChallengeReward(uint256 _challengeId)`: Allows the determined winner of a challenge to claim their reward token.

**V. Oracle Interface (Managed & Simulated)**

22. `setOracleAddress(address _newOracle)`: Sets the address of the trusted AI oracle contract. Only callable by the DAO/owner.
23. `simulateOracleCall(uint256 _artifactId, uint256 _simulatedSentiment, string memory _simulatedURI)`: (Development/testing function) Allows the owner to directly simulate an oracle callback, updating an artifact's state without an actual external oracle request.

**VI. Access Control & Utility**

24. `setBaseURI(string memory _newBaseURI)`: Sets a new base URI for the Aetherial Artifacts, affecting how `tokenURI` resolves metadata. Only callable by the DAO/owner.
25. `pause()`: Pauses certain contract functionalities (e.g., minting, proposal creation) in case of emergencies. Callable by the DAO/owner.
26. `unpause()`: Unpauses the contract, restoring full functionality. Callable by the DAO/owner.
27. `withdrawFunds(address _tokenAddress, address _recipient, uint256 _amount)`: Allows the DAO/owner to withdraw ERC20 tokens or native currency (if `_tokenAddress` is `address(0)`) accidentally sent to the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/CallSolidity.sol";


/**
 * @title AetheriaGenesis
 * @dev A smart contract that manages dynamic Aetherial Artifact NFTs, a reputation-based DAO governance,
 *      and gamified discovery challenges, with simulated AI oracle integration for artifact evolution.
 *
 * Outline:
 * 1. Core Artifact Management (Aetherial Artifacts - Dynamic ERC721 NFTs)
 *    - Defines the structure and properties of Aetherial Artifacts.
 *    - Functions for minting, requesting evolution (via oracle), fulfilling evolution, and tracking interactions.
 *    - Inherits `ERC721` for standard NFT functionality, overriding `tokenURI` for dynamic metadata.
 * 2. Insight Points (Reputation System)
 *    - A non-transferable point system representing a user's reputation and influence within the ecosystem.
 *    - Supports delegation of voting power, akin to a simplified liquid democracy.
 * 3. DAO Governance
 *    - Enables the community (weighted by Insight Points) to propose, vote on, and execute changes to the protocol or new initiatives.
 *    - Proposals can include awarding Insight Points, setting oracle addresses, or pausing the contract.
 * 4. Discovery Challenges & Curation
 *    - A gamified mechanism for users to propose new Aetherial Artifact concepts or curate existing ones.
 *    - Features submission periods, voting, and rewards for winning entries, fostering creative contribution.
 * 5. Oracle Interface (Simulated)
 *    - A dedicated interface for a (simulated) external AI oracle service to push sentiment analysis results back to the contract, triggering artifact evolution.
 *    - Includes a development function to manually simulate oracle calls for testing purposes.
 * 6. Access Control & Utility
 *    - `Ownable` (initially, with DAO expected to take over ownership for key functions).
 *    - `Pausable` for emergency control.
 *    - Functions for setting base URI and withdrawing funds.
 *
 * Function Summary:
 * I. Core Artifact Management (Dynamic ERC721 NFTs)
 * 1. mintInitialArtifact(string memory _initialURI, uint256 _initialSentiment): Mints a new dynamic NFT (Aetherial Artifact).
 * 2. requestArtifactEvolution(uint256 _artifactId): Initiates an external oracle call to evolve an artifact.
 * 3. fulfillArtifactEvolution(uint256 _artifactId, uint256 _newSentimentScore, string memory _newMetadataURI): Callback from oracle to update artifact's state.
 * 4. getArtifactDetails(uint256 _artifactId): Retrieves all current details of an Aetherial Artifact.
 * 5. signalArtifactInteraction(uint256 _artifactId): Records user interaction with an artifact, potentially influencing its evolution.
 * 6. tokenURI(uint256 _tokenId): Overridden ERC721 function to dynamically return the artifact's current metadata URI.
 *
 * II. Insight Points (Reputation System)
 * 7. awardInsightPoints(address _recipient, uint256 _amount): Grants insight points to a user (DAO/admin only).
 * 8. deductInsightPoints(address _recipient, uint256 _amount): Deducts insight points from a user (DAO/admin only).
 * 9. getInsightPoints(address _user): Returns the total insight points held by a user (direct, non-delegated).
 * 10. delegateInsightPoints(address _delegatee, uint256 _amount): Delegates insight points to another address for governance.
 * 11. undelegateInsightPoints(uint256 _amount): Recalls delegated insight points.
 * 12. getEffectiveInsightPoints(address _user): Returns the total insight points a user has for voting (own + received delegation).
 *
 * III. DAO Governance
 * 13. createProposal(string memory _description, bytes memory _calldata, address _target, uint256 _value, uint256 _duration): Creates a new governance proposal for DAO members to vote on.
 * 14. voteOnProposal(uint256 _proposalId, bool _support): Casts a vote on an active proposal using effective insight points.
 * 15. executeProposal(uint256 _proposalId): Executes a proposal that has passed its voting period and met thresholds.
 * 16. getProposalDetails(uint256 _proposalId): Fetches the current state and details of a specific proposal.
 *
 * IV. Discovery Challenges & Curation
 * 17. createDiscoveryChallenge(string memory _topic, uint256 _submissionPeriod, uint256 _votingPeriod, uint256 _rewardAmount, address _rewardToken): Initiates a new community challenge.
 * 18. submitChallengeEntry(uint256 _challengeId, string memory _entryURI): Allows users to submit their entry to an active challenge.
 * 19. voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId): Votes on a submitted challenge entry using effective insight points.
 * 20. determineChallengeWinner(uint256 _challengeId): Identifies and logs the winner of a completed challenge (DAO/admin only).
 * 21. claimChallengeReward(uint256 _challengeId): Allows the winner of a challenge to claim their reward.
 *
 * V. Oracle Interface (Managed & Simulated)
 * 22. setOracleAddress(address _newOracle): Sets the trusted address for the AI sentiment oracle (DAO-governed).
 * 23. simulateOracleCall(uint256 _artifactId, uint256 _simulatedSentiment, string memory _simulatedURI): (For dev/testing) Directly simulates an oracle callback for artifact evolution.
 *
 * VI. Access Control & Utility
 * 24. setBaseURI(string memory _newBaseURI): Updates the base URI for Aetherial Artifact metadata (DAO-governed).
 * 25. pause(): Pauses core contract functionalities (DAO/admin only).
 * 26. unpause(): Unpauses core contract functionalities (DAO/admin only).
 * 27. withdrawFunds(address _tokenAddress, address _recipient, uint256 _amount): Allows DAO to withdraw incidental funds from the contract.
 */
contract AetheriaGenesis is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using CallSolidity for address;

    // --- Events ---
    event ArtifactMinted(uint256 indexed artifactId, address indexed owner, string initialURI, uint256 initialSentiment);
    event ArtifactEvolutionRequested(uint256 indexed artifactId, uint256 timestamp);
    event ArtifactEvolved(uint256 indexed artifactId, uint256 newSentiment, string newURI, uint256 newEvolutionStage);
    event ArtifactInteraction(uint256 indexed artifactId, address indexed user);
    event InsightPointsAwarded(address indexed recipient, uint256 amount);
    event InsightPointsDeducted(address indexed recipient, uint256 amount);
    event InsightPointsDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event InsightPointsUndelegated(address indexed delegator, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 insightPointsUsed);
    event ProposalExecuted(uint256 indexed proposalId);
    event ChallengeCreated(uint256 indexed challengeId, string topic, uint256 submissionEnd, uint256 votingEnd, uint256 rewardAmount, address rewardToken);
    event ChallengeEntrySubmitted(uint256 indexed challengeId, uint256 indexed entryId, address indexed submitter, string entryURI);
    event ChallengeEntryVoteCast(uint256 indexed challengeId, uint256 indexed entryId, address indexed voter, uint256 insightPointsUsed);
    event ChallengeWinnerDetermined(uint256 indexed challengeId, uint252 indexed winnerEntryId, address indexed winnerAddress);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed winner, uint256 amount, address rewardToken);
    event OracleAddressUpdated(address indexed newOracleAddress);


    // --- Structs ---

    struct AetherialArtifact {
        uint256 id;
        uint256 evolutionStage;
        uint256 currentSentimentScore; // e.g., 0-100, AI-driven
        string metadataURI;
        uint256 lastEvolutionTimestamp;
        uint256 totalInteractions; // Tracks community engagement
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address target; // Target contract for execution
        uint256 value; // Ether to send with call
        bytes calldata; // Encoded function call
        uint256 creationTime;
        uint256 endTime;
        bool executed;
        uint256 votesFor; // Total effective Insight Points for
        uint256 votesAgainst; // Total effective Insight Points against
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }

    struct ChallengeEntry {
        uint256 id;
        address submitter;
        string entryURI; // e.g., IPFS hash of a proposed artifact design
        uint256 votes; // Total effective Insight Points for this entry
    }

    struct DiscoveryChallenge {
        uint256 id;
        string topic;
        uint256 submissionPeriodEnd;
        uint256 votingPeriodEnd;
        uint256 rewardAmount;
        address rewardToken; // ERC20 token address, or address(0) for native ETH
        uint256 winnerEntryId;
        address winnerAddress;
        bool challengeFinalized;
        Counters.Counter entryCounter;
        mapping(uint256 => ChallengeEntry) entries;
        mapping(address => bool) hasSubmitted; // For unique submissions per user
        mapping(address => bool) hasVoted; // For unique votes per user
    }

    // --- State Variables ---

    Counters.Counter private _artifactIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _challengeIds;

    mapping(uint256 => AetherialArtifact) public aetherialArtifacts;
    string private _baseTokenURI;

    mapping(address => uint256) private _insightPoints; // Direct insight points owned by a user
    mapping(address => address) private _delegates; // Who a user has delegated their points to
    mapping(address => uint256) private _delegatedAmounts; // How many points a user has delegated out
    mapping(address => uint256) private _receivedDelegations; // How many points a user has received

    mapping(uint256 => Proposal) public proposals;
    uint256 public constant MIN_INSIGHT_POINTS_TO_PROPOSE = 100; // Minimum points to create a proposal
    uint256 public constant PROPOSAL_VOTING_THRESHOLD_PERCENT = 51; // 51% 'For' votes needed to pass

    mapping(uint256 => DiscoveryChallenge) public discoveryChallenges;

    address public oracleAddress; // Address of the trusted AI oracle


    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetheriaGenesis: Not the authorized oracle");
        _;
    }

    modifier onlyDaoOrOwner() {
        // In a full DAO, ownership would be renounced to a Governance contract.
        // For this example, we assume owner can act as DAO for critical functions.
        require(msg.sender == owner() /* || daoContract.isGovernanceModule(msg.sender) */, "AetheriaGenesis: Caller not DAO or owner");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address _initialOracleAddress) ERC721(name, symbol) Ownable(msg.sender) {
        require(_initialOracleAddress != address(0), "AetheriaGenesis: Oracle address cannot be zero");
        oracleAddress = _initialOracleAddress;
        _baseTokenURI = "ipfs://"; // Default base URI, can be changed by DAO
    }


    // --- I. Core Artifact Management (Dynamic ERC721 NFTs) ---

    /**
     * @dev Mints a new Aetherial Artifact NFT.
     * @param _initialURI The initial metadata URI for the artifact.
     * @param _initialSentiment The initial sentiment score (e.g., 0-100) for the artifact.
     * @return The ID of the newly minted artifact.
     */
    function mintInitialArtifact(string memory _initialURI, uint256 _initialSentiment)
        public
        whenNotPaused
        returns (uint256)
    {
        _artifactIds.increment();
        uint256 newTokenId = _artifactIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _initialURI); // ERC721's _setTokenURI

        aetherialArtifacts[newTokenId] = AetherialArtifact({
            id: newTokenId,
            evolutionStage: 1,
            currentSentimentScore: _initialSentiment,
            metadataURI: _initialURI,
            lastEvolutionTimestamp: block.timestamp,
            totalInteractions: 0
        });

        emit ArtifactMinted(newTokenId, msg.sender, _initialURI, _initialSentiment);
        return newTokenId;
    }

    /**
     * @dev Requests an external AI oracle to analyze and potentially evolve an artifact.
     *      This function primarily logs an event for off-chain oracle listeners.
     * @param _artifactId The ID of the artifact to evolve.
     */
    function requestArtifactEvolution(uint256 _artifactId) public whenNotPaused {
        require(_exists(_artifactId), "AetheriaGenesis: Artifact does not exist");
        // In a real system, this would trigger an actual Chainlink VRF, Chainlink Functions, or similar
        // verifiable off-chain computation request. For this contract, we emit an event.
        emit ArtifactEvolutionRequested(_artifactId, block.timestamp);
    }

    /**
     * @dev Callback function to fulfill an artifact's evolution request from the authorized oracle.
     *      Updates the artifact's sentiment, metadata, and increments its evolution stage.
     * @param _artifactId The ID of the artifact to update.
     * @param _newSentimentScore The new AI-driven sentiment score.
     * @param _newMetadataURI The new metadata URI after evolution.
     */
    function fulfillArtifactEvolution(uint256 _artifactId, uint256 _newSentimentScore, string memory _newMetadataURI)
        public
        onlyOracle
        whenNotPaused
    {
        require(_exists(_artifactId), "AetheriaGenesis: Artifact does not exist");
        AetherialArtifact storage artifact = aetherialArtifacts[_artifactId];

        artifact.currentSentimentScore = _newSentimentScore;
        artifact.metadataURI = _newMetadataURI;
        artifact.evolutionStage++;
        artifact.lastEvolutionTimestamp = block.timestamp;

        _setTokenURI(_artifactId, _newMetadataURI); // Update ERC721 tokenURI
        emit ArtifactEvolved(_artifactId, _newSentimentScore, _newMetadataURI, artifact.evolutionStage);
    }

    /**
     * @dev Retrieves all current details for a specific Aetherial Artifact.
     * @param _artifactId The ID of the artifact.
     * @return A tuple containing all artifact properties.
     */
    function getArtifactDetails(uint256 _artifactId)
        public
        view
        returns (
            uint256 id,
            address owner,
            uint256 evolutionStage,
            uint256 currentSentimentScore,
            string memory metadataURI,
            uint256 lastEvolutionTimestamp,
            uint256 totalInteractions
        )
    {
        require(_exists(_artifactId), "AetheriaGenesis: Artifact does not exist");
        AetherialArtifact storage artifact = aetherialArtifacts[_artifactId];
        return (
            artifact.id,
            ownerOf(_artifactId),
            artifact.evolutionStage,
            artifact.currentSentimentScore,
            artifact.metadataURI,
            artifact.lastEvolutionTimestamp,
            artifact.totalInteractions
        );
    }

    /**
     * @dev Allows any user to signal interaction with an Aetherial Artifact.
     *      This could be used internally as a metric for future evolution or to award Insight Points.
     * @param _artifactId The ID of the artifact being interacted with.
     */
    function signalArtifactInteraction(uint256 _artifactId) public whenNotPaused {
        require(_exists(_artifactId), "AetheriaGenesis: Artifact does not exist");
        aetherialArtifacts[_artifactId].totalInteractions++;
        emit ArtifactInteraction(_artifactId, msg.sender);
    }

    /**
     * @dev Overrides ERC721's tokenURI to return the dynamic metadata URI stored in the artifact's struct.
     * @param _tokenId The ID of the NFT.
     * @return The current metadata URI for the artifact.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return aetherialArtifacts[_tokenId].metadataURI;
    }

    // --- II. Insight Points (Reputation System) ---

    /**
     * @dev Awards Insight Points to a recipient. Only callable by the DAO/owner.
     * @param _recipient The address to award points to.
     * @param _amount The amount of Insight Points to award.
     */
    function awardInsightPoints(address _recipient, uint256 _amount) public onlyDaoOrOwner {
        require(_recipient != address(0), "AetheriaGenesis: Cannot award to zero address");
        _insightPoints[_recipient] += _amount;
        emit InsightPointsAwarded(_recipient, _amount);
    }

    /**
     * @dev Deducts Insight Points from a recipient. Only callable by the DAO/owner.
     * @param _recipient The address to deduct points from.
     * @param _amount The amount of Insight Points to deduct.
     */
    function deductInsightPoints(address _recipient, uint256 _amount) public onlyDaoOrOwner {
        require(_insightPoints[_recipient] >= _amount, "AetheriaGenesis: Insufficient insight points to deduct");
        _insightPoints[_recipient] -= _amount;
        emit InsightPointsDeducted(_recipient, _amount);
    }

    /**
     * @dev Returns the direct Insight Points held by a user (excluding delegated points).
     * @param _user The address of the user.
     * @return The amount of direct Insight Points.
     */
    function getInsightPoints(address _user) public view returns (uint256) {
        return _insightPoints[_user];
    }

    /**
     * @dev Delegates a portion of a user's Insight Points to another address.
     *      This allows a user to empower another address to vote on their behalf.
     * @param _delegatee The address to delegate points to.
     * @param _amount The amount of Insight Points to delegate.
     */
    function delegateInsightPoints(address _delegatee, uint256 _amount) public whenNotPaused {
        require(_delegatee != address(0), "AetheriaGenesis: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "AetheriaGenesis: Cannot delegate to self");
        require(_insightPoints[msg.sender] >= _amount, "AetheriaGenesis: Insufficient insight points to delegate");

        // If previously delegated to someone else, undelegate first
        if (_delegates[msg.sender] != address(0) && _delegates[msg.sender] != _delegatee) {
            uint256 previousDelegatedAmount = _delegatedAmounts[msg.sender];
            _receivedDelegations[_delegates[msg.sender]] -= previousDelegatedAmount;
            _delegatedAmounts[msg.sender] = 0; // Clear previous delegation
        }

        _delegates[msg.sender] = _delegatee;
        _delegatedAmounts[msg.sender] = _amount;
        _receivedDelegations[_delegatee] += _amount;

        emit InsightPointsDelegated(msg.sender, _delegatee, _amount);
    }

    /**
     * @dev Recalls previously delegated Insight Points.
     *      If a specific amount is passed, it only recalls that amount, otherwise, it recalls all.
     * @param _amount The amount to undelegate. Pass 0 to undelegate all.
     */
    function undelegateInsightPoints(uint256 _amount) public whenNotPaused {
        address delegatee = _delegates[msg.sender];
        require(delegatee != address(0), "AetheriaGenesis: No points delegated by this user");

        uint256 delegatedAmount = _delegatedAmounts[msg.sender];
        uint256 amountToUndelegate = _amount == 0 ? delegatedAmount : _amount;

        require(delegatedAmount >= amountToUndelegate, "AetheriaGenesis: Cannot undelegate more than delegated amount");

        _receivedDelegations[delegatee] -= amountToUndelegate;
        _delegatedAmounts[msg.sender] -= amountToUndelegate;

        if (_delegatedAmounts[msg.sender] == 0) {
            _delegates[msg.sender] = address(0); // Clear delegatee if all points undelegated
        }

        emit InsightPointsUndelegated(msg.sender, amountToUndelegate);
    }

    /**
     * @dev Returns the total effective Insight Points for a user, used for voting.
     *      This includes their own direct points plus any points delegated to them.
     * @param _user The address of the user.
     * @return The effective Insight Points.
     */
    function getEffectiveInsightPoints(address _user) public view returns (uint256) {
        return _insightPoints[_user] + _receivedDelegations[_user];
    }

    // --- III. DAO Governance ---

    /**
     * @dev Creates a new governance proposal.
     * @param _description A description of the proposal.
     * @param _calldata Encoded function call to execute if proposal passes.
     * @param _target The target contract for the execution (this contract itself, or another).
     * @param _value ETH to send with the execution call.
     * @param _duration The duration in seconds for which the proposal will be open for voting.
     * @return The ID of the newly created proposal.
     */
    function createProposal(
        string memory _description,
        bytes memory _calldata,
        address _target,
        uint256 _value,
        uint256 _duration
    ) public whenNotPaused returns (uint256) {
        require(getInsightPoints(msg.sender) >= MIN_INSIGHT_POINTS_TO_PROPOSE, "AetheriaGenesis: Insufficient insight points to propose");
        require(_target != address(0), "AetheriaGenesis: Target address cannot be zero");
        require(_duration > 0, "AetheriaGenesis: Proposal duration must be greater than zero");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId].id = proposalId;
        proposals[proposalId].proposer = msg.sender;
        proposals[proposalId].description = _description;
        proposals[proposalId].target = _target;
        proposals[proposalId].value = _value;
        proposals[proposalId].calldata = _calldata;
        proposals[proposalId].creationTime = block.timestamp;
        proposals[proposalId].endTime = block.timestamp + _duration;
        proposals[proposalId].executed = false;
        proposals[proposalId].votesFor = 0;
        proposals[proposalId].votesAgainst = 0;

        emit ProposalCreated(proposalId, msg.sender, _description, proposals[proposalId].endTime);
        return proposalId;
    }

    /**
     * @dev Casts a vote (for or against) on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetheriaGenesis: Proposal does not exist");
        require(block.timestamp <= proposal.endTime, "AetheriaGenesis: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetheriaGenesis: Already voted on this proposal");

        uint256 voterEffectiveInsightPoints = getEffectiveInsightPoints(msg.sender);
        require(voterEffectiveInsightPoints > 0, "AetheriaGenesis: Voter has no effective insight points");

        if (_support) {
            proposal.votesFor += voterEffectiveInsightPoints;
        } else {
            proposal.votesAgainst += voterEffectiveInsightPoints;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterEffectiveInsightPoints);
    }

    /**
     * @dev Executes a proposal that has passed its voting period and met thresholds.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetheriaGenesis: Proposal does not exist");
        require(block.timestamp > proposal.endTime, "AetheriaGenesis: Voting period not ended yet");
        require(!proposal.executed, "AetheriaGenesis: Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "AetheriaGenesis: No votes cast for this proposal");

        uint256 votesForPercentage = (proposal.votesFor * 100) / totalVotes;
        require(votesForPercentage >= PROPOSAL_VOTING_THRESHOLD_PERCENT, "AetheriaGenesis: Proposal did not meet vote threshold");

        proposal.executed = true;

        // Execute the call
        // Using CallSolidity from OpenZeppelin utils for safer call management
        (bool success, ) = proposal.target.callSolidity(proposal.value, proposal.calldata);
        require(success, "AetheriaGenesis: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves detailed information about a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all proposal properties.
     */
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            address target,
            uint256 value,
            bytes memory calldata,
            uint256 creationTime,
            uint256 endTime,
            bool executed,
            uint256 votesFor,
            uint256 votesAgainst
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetheriaGenesis: Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.target,
            proposal.value,
            proposal.calldata,
            proposal.creationTime,
            proposal.endTime,
            proposal.executed,
            proposal.votesFor,
            proposal.votesAgainst
        );
    }


    // --- IV. Discovery Challenges & Curation ---

    /**
     * @dev Initiates a new community Discovery Challenge. Only callable by the DAO/owner.
     *      Reward tokens must be approved and transferred to the contract BEFORE calling this function.
     * @param _topic The topic or theme of the challenge.
     * @param _submissionPeriod Duration in seconds for submissions.
     * @param _votingPeriod Duration in seconds for voting after submissions close.
     * @param _rewardAmount The amount of reward for the winner.
     * @param _rewardToken The ERC20 token address for the reward, or address(0) for native ETH.
     * @return The ID of the newly created challenge.
     */
    function createDiscoveryChallenge(
        string memory _topic,
        uint256 _submissionPeriod,
        uint256 _votingPeriod,
        uint256 _rewardAmount,
        address _rewardToken
    ) public payable onlyDaoOrOwner whenNotPaused returns (uint256) {
        require(_submissionPeriod > 0, "AetheriaGenesis: Submission period must be positive");
        require(_votingPeriod > 0, "AetheriaGenesis: Voting period must be positive");
        require(_rewardAmount > 0, "AetheriaGenesis: Reward amount must be positive");

        if (_rewardToken == address(0)) {
            require(msg.value == _rewardAmount, "AetheriaGenesis: Insufficient ETH sent for reward");
        } else {
            require(msg.value == 0, "AetheriaGenesis: ETH should not be sent for ERC20 rewards");
            // Assume ERC20 reward is already transferred and approved to this contract
            // or will be handled by a separate DAO transfer
        }

        _challengeIds.increment();
        uint256 challengeId = _challengeIds.current();

        DiscoveryChallenge storage challenge = discoveryChallenges[challengeId];
        challenge.id = challengeId;
        challenge.topic = _topic;
        challenge.submissionPeriodEnd = block.timestamp + _submissionPeriod;
        challenge.votingPeriodEnd = challenge.submissionPeriodEnd + _votingPeriod;
        challenge.rewardAmount = _rewardAmount;
        challenge.rewardToken = _rewardToken;
        challenge.winnerEntryId = 0; // Default
        challenge.winnerAddress = address(0); // Default
        challenge.challengeFinalized = false;

        emit ChallengeCreated(challengeId, _topic, challenge.submissionPeriodEnd, challenge.votingPeriodEnd, _rewardAmount, _rewardToken);
        return challengeId;
    }

    /**
     * @dev Allows users to submit an entry to an active challenge.
     * @param _challengeId The ID of the challenge.
     * @param _entryURI The URI (e.g., IPFS hash) of the challenge entry.
     */
    function submitChallengeEntry(uint256 _challengeId, string memory _entryURI) public whenNotPaused {
        DiscoveryChallenge storage challenge = discoveryChallenges[_challengeId];
        require(challenge.id != 0, "AetheriaGenesis: Challenge does not exist");
        require(block.timestamp <= challenge.submissionPeriodEnd, "AetheriaGenesis: Submission period has ended");
        require(!challenge.hasSubmitted[msg.sender], "AetheriaGenesis: Already submitted an entry to this challenge");

        challenge.entryCounter.increment();
        uint256 entryId = challenge.entryCounter.current();

        challenge.entries[entryId] = ChallengeEntry({
            id: entryId,
            submitter: msg.sender,
            entryURI: _entryURI,
            votes: 0
        });
        challenge.hasSubmitted[msg.sender] = true;

        emit ChallengeEntrySubmitted(_challengeId, entryId, msg.sender, _entryURI);
    }

    /**
     * @dev Votes on a submitted challenge entry.
     * @param _challengeId The ID of the challenge.
     * @param _entryId The ID of the entry to vote on.
     */
    function voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId) public whenNotPaused {
        DiscoveryChallenge storage challenge = discoveryChallenges[_challengeId];
        require(challenge.id != 0, "AetheriaGenesis: Challenge does not exist");
        require(block.timestamp > challenge.submissionPeriodEnd, "AetheriaGenesis: Submission period not ended yet");
        require(block.timestamp <= challenge.votingPeriodEnd, "AetheriaGenesis: Voting period has ended");
        require(challenge.entries[_entryId].id != 0, "AetheriaGenesis: Challenge entry does not exist");
        require(!challenge.hasVoted[msg.sender], "AetheriaGenesis: Already voted in this challenge");

        uint256 voterEffectiveInsightPoints = getEffectiveInsightPoints(msg.sender);
        require(voterEffectiveInsightPoints > 0, "AetheriaGenesis: Voter has no effective insight points");

        challenge.entries[_entryId].votes += voterEffectiveInsightPoints;
        challenge.hasVoted[msg.sender] = true;

        emit ChallengeEntryVoteCast(_challengeId, _entryId, msg.sender, voterEffectiveInsightPoints);
    }

    /**
     * @dev Determines the winner of a completed discovery challenge. Only callable by the DAO/owner.
     *      The winner is the entry with the most votes.
     * @param _challengeId The ID of the challenge to finalize.
     */
    function determineChallengeWinner(uint256 _challengeId) public onlyDaoOrOwner whenNotPaused {
        DiscoveryChallenge storage challenge = discoveryChallenges[_challengeId];
        require(challenge.id != 0, "AetheriaGenesis: Challenge does not exist");
        require(block.timestamp > challenge.votingPeriodEnd, "AetheriaGenesis: Voting period not ended yet");
        require(!challenge.challengeFinalized, "AetheriaGenesis: Challenge already finalized");

        uint256 winningVotes = 0;
        uint256 winnerEntryId = 0;
        address winnerAddress = address(0);

        for (uint256 i = 1; i <= challenge.entryCounter.current(); i++) {
            if (challenge.entries[i].id != 0 && challenge.entries[i].votes > winningVotes) {
                winningVotes = challenge.entries[i].votes;
                winnerEntryId = challenge.entries[i].id;
                winnerAddress = challenge.entries[i].submitter;
            }
        }

        require(winnerAddress != address(0), "AetheriaGenesis: No valid winner found for this challenge");

        challenge.winnerEntryId = winnerEntryId;
        challenge.winnerAddress = winnerAddress;
        challenge.challengeFinalized = true;

        emit ChallengeWinnerDetermined(_challengeId, winnerEntryId, winnerAddress);
    }

    /**
     * @dev Allows the determined winner of a challenge to claim their reward.
     * @param _challengeId The ID of the challenge.
     */
    function claimChallengeReward(uint256 _challengeId) public whenNotPaused {
        DiscoveryChallenge storage challenge = discoveryChallenges[_challengeId];
        require(challenge.id != 0, "AetheriaGenesis: Challenge does not exist");
        require(challenge.challengeFinalized, "AetheriaGenesis: Challenge not yet finalized");
        require(msg.sender == challenge.winnerAddress, "AetheriaGenesis: Only the winner can claim the reward");
        require(challenge.rewardAmount > 0, "AetheriaGenesis: Reward already claimed or no reward set");

        uint256 reward = challenge.rewardAmount;
        challenge.rewardAmount = 0; // Prevent double claiming

        if (challenge.rewardToken == address(0)) {
            (bool success, ) = msg.sender.call{value: reward}("");
            require(success, "AetheriaGenesis: Failed to send ETH reward");
        } else {
            IERC20(challenge.rewardToken).transfer(msg.sender, reward);
        }

        emit ChallengeRewardClaimed(_challengeId, msg.sender, reward, challenge.rewardToken);
    }


    // --- V. Oracle Interface (Managed & Simulated) ---

    /**
     * @dev Sets the address of the trusted AI oracle contract. Only callable by the DAO/owner.
     * @param _newOracle The new address for the oracle.
     */
    function setOracleAddress(address _newOracle) public onlyDaoOrOwner {
        require(_newOracle != address(0), "AetheriaGenesis: Oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @dev Development/testing function to directly simulate an oracle callback.
     *      Allows the owner to update an artifact's state as if an oracle fulfilled a request.
     *      In a production environment, this function would likely be removed or restricted.
     * @param _artifactId The ID of the artifact to update.
     * @param _simulatedSentiment The simulated new sentiment score.
     * @param _simulatedURI The simulated new metadata URI.
     */
    function simulateOracleCall(uint256 _artifactId, uint256 _simulatedSentiment, string memory _simulatedURI) public onlyOwner {
        fulfillArtifactEvolution(_artifactId, _simulatedSentiment, _simulatedURI);
    }


    // --- VI. Access Control & Utility ---

    /**
     * @dev Updates the base URI for all Aetherial Artifacts. Only callable by the DAO/owner.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyDaoOrOwner {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Returns the base URI for token metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Pauses core contract functionalities. Only callable by the DAO/owner.
     */
    function pause() public onlyDaoOrOwner {
        _pause();
    }

    /**
     * @dev Unpauses core contract functionalities. Only callable by the DAO/owner.
     */
    function unpause() public onlyDaoOrOwner {
        _unpause();
    }

    /**
     * @dev Allows the DAO/owner to withdraw incidental funds (ETH or ERC20) from the contract.
     *      Crucial for managing reward pools and any accidental transfers.
     * @param _tokenAddress The address of the token to withdraw (address(0) for native ETH).
     * @param _recipient The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawFunds(address _tokenAddress, address _recipient, uint256 _amount) public onlyDaoOrOwner {
        require(_recipient != address(0), "AetheriaGenesis: Recipient cannot be zero address");
        require(_amount > 0, "AetheriaGenesis: Amount must be greater than zero");

        if (_tokenAddress == address(0)) {
            // Withdraw native ETH
            require(address(this).balance >= _amount, "AetheriaGenesis: Insufficient ETH balance");
            (bool success, ) = _recipient.call{value: _amount}("");
            require(success, "AetheriaGenesis: ETH transfer failed");
        } else {
            // Withdraw ERC20 tokens
            IERC20 token = IERC20(_tokenAddress);
            require(token.balanceOf(address(this)) >= _amount, "AetheriaGenesis: Insufficient token balance");
            token.transfer(_recipient, _amount);
        }
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```