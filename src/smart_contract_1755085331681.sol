This smart contract, "ChronoCaster Nexus," introduces a unique blend of time-gated content, dynamic NFTs, an on-chain reputation system for AI/Oracle agents, and a light DAO governance model. It's designed for a future where AI generates or predicts events, and these predictions, once fulfilled, trigger on-chain changes, particularly affecting evolving NFTs.

---

## ChronoCaster Nexus: Outline and Function Summary

**Concept:** ChronoCaster Nexus is a decentralized platform where AI agents or validated oracles (referred to as "Chronoscribes") submit "Whispers" – cryptographic commitments to future-predicted data or AI-generated narratives/assets. These Whispers are time-locked and, upon their `fulfillmentTimestamp`, can be verified. Successful fulfillment impacts the on-chain state, specifically evolving "ChronoSentinels" (Dynamic NFTs) and adjusting the reputation of Chronoscribes. A utility token, Aethershards, powers the ecosystem and provides governance.

**Core Innovation:**
1.  **Time-Gated Dynamic Content (Whispers):** On-chain commitments to off-chain data that become verifiable and trigger effects only after a specific future timestamp.
2.  **ChronoSentinels (Dynamic NFTs):** NFTs whose metadata (and thus visual representation) dynamically changes based on the fulfillment of specific Whispers they are "attuned" to.
3.  **Reputation for AI/Oracles:** Chronoscribes earn or lose reputation based on the accuracy and timely fulfillment of their submitted Whispers.
4.  **Decentralized Event Curation:** A community-driven mechanism (simplified DAO) to dispute or approve Whisper fulfillments and adjust contract parameters.

---

**Function Summary:**

**I. Core Infrastructure & Access Control:**
1.  `constructor()`: Initializes the contract, sets up the Aethershards token, and assigns admin roles.
2.  `setChronoScribeRole(address _account)`: Grants an address the `CHRONOSCRIBE_ROLE`, allowing them to submit Whispers.
3.  `removeChronoScribeRole(address _account)`: Revokes the `CHRONOSCRIBE_ROLE`.
4.  `pause()`: Pauses core functionalities for maintenance or emergency.
5.  `unpause()`: Unpauses the contract.
6.  `withdrawEth()`: Allows the contract owner to withdraw accumulated ETH (e.g., from fees).
7.  `getRoleAdmin(bytes32 role)`: Returns the admin role for a given role (OpenZeppelin's AccessControl).

**II. Aethershards (ERC-20 Token) Management:**
8.  `mintAetherShards(address _to, uint256 _amount)`: Mints new Aethershards, primarily for initial distribution or specific rewards.
9.  `burnAetherShards(uint256 _amount)`: Allows users to burn their own Aethershards.
10. `stakeAetherShards(uint256 _amount)`: Users stake Aethershards to gain voting power or specific benefits (e.g., higher Sentinel attunement limits).
11. `unstakeAetherShards(uint256 _amount)`: Allows users to withdraw staked Aethershards.

**III. Whisper (Time-Gated Data/Prediction) Management:**
12. `submitWhisper(string calldata _category, uint256 _predictionTimestamp, string calldata _dataHash, uint256 _submissionFee)`: Chronoscribes submit a new Whisper, committing to future data/events. Requires Aethershard fee.
13. `fulfillWhisper(uint256 _whisperId, string calldata _actualDataHash)`: A Chronoscribe attempts to mark a Whisper as fulfilled after its `predictionTimestamp`. Requires `_actualDataHash` verification (off-chain, but its hash is compared on-chain if a challenge arises). Triggers Sentinel updates and reputation changes.
14. `challengeWhisperFulfillment(uint256 _whisperId, string calldata _proposedActualDataHash)`: Allows any user to challenge the fulfillment of a Whisper, disputing its accuracy. Initiates a community vote.
15. `resolveWhisperChallenge(uint256 _challengeId, bool _isFulfilledCorrectly)`: The DAO admin or a passed vote finalizes a Whisper challenge, impacting reputation and Sentinel states.
16. `getWhisperDetails(uint256 _whisperId)`: View function to retrieve all details of a specific Whisper.
17. `getWhisperCount()`: View function to get the total number of submitted Whispers.
18. `getWhispersByChronoScribe(address _scribe)`: View function to retrieve all Whispers submitted by a specific Chronoscribe.

**IV. ChronoSentinel (Dynamic NFT) Management:**
19. `mintChronoSentinel(string calldata _initialMetadataURI)`: Mints a new ChronoSentinel NFT.
20. `attuneSentinelToWhisperCategory(uint256 _tokenId, string calldata _category)`: Owners can attune their Sentinel to a specific Whisper category, making it eligible for metadata updates when Whispers in that category are fulfilled.
21. `updateSentinelBaseURI(string calldata _newURI)`: Admin function to update the base URI for all ChronoSentinels (e.g., for general metadata upgrades).
22. `getSentinelDetails(uint256 _tokenId)`: View function to get all details of a ChronoSentinel.
23. `getSentinelOwner(uint256 _tokenId)`: View function to get the owner of a ChronoSentinel.
24. `getTokenURI(uint256 _tokenId)`: Returns the current metadata URI for a ChronoSentinel, reflecting its dynamic state. (Inherited from ERC721URIStorage, but overridden for dynamism).

**V. Reputation System:**
25. `getChronoScribeReputation(address _scribe)`: View function to get the current reputation score of a Chronoscribe.
26. `getSentinelAttunementBonus(uint256 _tokenId)`: View function to calculate potential bonuses for a Sentinel based on its attunements and fulfilled Whispers.

**VI. DAO Governance (Simplified):**
27. `proposeParameterChange(string calldata _description, bytes calldata _callData)`: Users can propose changes to contract parameters (e.g., fee amounts, challenge periods).
28. `voteOnProposal(uint256 _proposalId, bool _support)`: Staked Aethershards holders vote on open proposals.
29. `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes the vote.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ChronoCaster Nexus
 * @dev A smart contract for time-gated dynamic content, evolving NFTs,
 *      AI/Oracle reputation, and simplified DAO governance.
 *
 * Outline:
 * I. Core Infrastructure & Access Control
 * II. Aethershards (ERC-20 Token) Management
 * III. Whisper (Time-Gated Data/Prediction) Management
 * IV. ChronoSentinel (Dynamic NFT) Management
 * V. Reputation System
 * VI. DAO Governance (Simplified)
 */
contract ChronoCasterNexus is ERC20, ERC721URIStorage, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- I. Core Infrastructure & Access Control ---

    bytes32 public constant CHRONOSCRIBE_ROLE = keccak256("CHRONOSCRIBE_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE"); // For DAO actions

    // --- Errors ---
    error InvalidTimestamp();
    error WhisperNotFulfilled();
    error WhisperAlreadyFulfilled();
    error NotChronoScribe();
    error UnauthorizedCaller();
    error InsufficientFee();
    error InvalidTokenId();
    error AlreadyAttuned();
    error NotEnoughStakedForProposal();
    error ProposalNotFound();
    error ProposalNotOpen();
    error AlreadyVoted();
    error ProposalNotApproved();
    error InvalidChallenge();
    error ChallengeNotResolved();

    // --- State Variables ---

    // Aethershards Token (inherited from ERC20)
    uint256 public constant INITIAL_MINT_SUPPLY = 100_000_000 * (10 ** 18); // 100M tokens

    // ChronoSentinel NFTs
    Counters.Counter private _sentinelIds;
    string private _baseSentinelURI; // Base URI for ChronoSentinel metadata

    // Whisper Data
    struct Whisper {
        uint256 id;
        string category; // E.g., "AI_Narrative_V1", "Economic_Prediction", "Scientific_Breakthrough"
        address chronoScribe;
        uint256 submissionTimestamp;
        uint256 predictionTimestamp; // The future timestamp when this Whisper is expected to be fulfilled
        string dataHash; // IPFS hash of the predicted data
        string fulfilledDataHash; // IPFS hash of the actual data upon fulfillment
        bool isFulfilled;
        bool isChallenged;
        uint256 challengeId; // If challenged, points to the challenge ID
    }
    mapping(uint256 => Whisper) public whispers;
    Counters.Counter private _whisperIds;
    mapping(address => uint256[]) public chronoScribeWhispers; // ChronoScribe to list of their submitted whisper IDs

    // Whisper Parameters
    uint256 public whisperSubmissionFee; // Aethershards required to submit a Whisper
    uint256 public fulfillmentRewardPool; // Aethershards set aside for fulfillment rewards
    uint256 public challengeDeposit; // Aethershards required to challenge a Whisper fulfillment

    // ChronoSentinel Dynamic Metadata
    // For dynamic NFT logic: tokenId => array of categories it's attuned to
    mapping(uint256 => string[]) public sentinelAttunements;
    // tokenId => mapping of category => last fulfilled whisper ID for that category
    mapping(uint256 => mapping(string => uint256)) public sentinelLastFulfilledWhisper;

    // Reputation System
    mapping(address => int256) public chronoScribeReputation; // int256 allows for negative reputation
    uint256 public constant REPUTATION_BONUS_FULFILL = 100;
    uint256 public constant REPUTATION_PENALTY_CHALLENGE_LOSS = 50;
    uint256 public constant REPUTATION_BONUS_CHALLENGE_WIN = 20;

    // --- DAO Governance (Simplified) ---
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call to be executed
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;
    uint256 public proposalVotePeriod; // Duration for voting on a proposal
    uint256 public minStakeForProposal; // Minimum staked Aethershards to create a proposal
    uint256 public minVotePowerForProposal; // Minimum total votes to pass a proposal

    // Whisper Challenges (specific to a Whisper)
    struct WhisperChallenge {
        uint256 id;
        uint256 whisperId;
        address challenger;
        string proposedActualDataHash; // The hash challenger believes is correct
        uint256 challengeTime;
        uint256 resolveTime; // When the challenge was resolved
        bool resolved;
        bool challengerWon; // True if challenger's claim was validated by DAO
    }
    mapping(uint256 => WhisperChallenge) public whisperChallenges;
    Counters.Counter private _challengeIds;

    // --- Events ---
    event ChronoCasterPaused(address indexed account);
    event ChronoCasterUnpaused(address indexed account);
    event ChronoScribeRoleGranted(address indexed account);
    event ChronoScribeRoleRevoked(address indexed account);
    event WhisperSubmitted(uint256 indexed whisperId, string category, address indexed chronoScribe, uint256 predictionTimestamp, string dataHash);
    event WhisperFulfilled(uint256 indexed whisperId, address indexed fulfiller, string fulfilledDataHash, uint256 timestamp);
    event ChronoSentinelMinted(uint256 indexed tokenId, address indexed owner, string initialURI);
    event ChronoSentinelAttuned(uint256 indexed tokenId, string category);
    event ChronoSentinelMetadataUpdated(uint256 indexed tokenId, string newURI);
    event ChronoScribeReputationUpdated(address indexed chronoScribe, int256 newReputation, int256 change);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);
    event WhisperChallengeCreated(uint256 indexed challengeId, uint256 indexed whisperId, address indexed challenger);
    event WhisperChallengeResolved(uint256 indexed challengeId, uint256 indexed whisperId, bool challengerWon);

    /**
     * @dev Initializes the ChronoCaster Nexus contract.
     * Sets the Aethershards token name and symbol.
     * Mints initial supply to the deployer.
     * Grants DEFAULT_ADMIN_ROLE to the deployer.
     * Sets initial parameters for fees and governance.
     */
    constructor() ERC20("Aethershards", "ASH") ERC721("ChronoSentinel", "CNS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender); // Initially, admin is also the governance role

        _mint(msg.sender, INITIAL_MINT_SUPPLY); // Mint initial Aethershards to deployer

        whisperSubmissionFee = 10 * (10 ** 18); // 10 ASH
        fulfillmentRewardPool = 100 * (10 ** 18); // 100 ASH
        challengeDeposit = 5 * (10 ** 18); // 5 ASH

        _baseSentinelURI = "ipfs://QmbnK6cQvM5X2jP9X7yT1wG8H0Z4V5S6L7R8I9J0K1L/"; // Example IPFS base URI
        proposalVotePeriod = 3 days;
        minStakeForProposal = 50 * (10 ** 18); // 50 ASH
        minVotePowerForProposal = 100 * (10 ** 18); // 100 ASH total votes to pass
    }

    // --- I. Core Infrastructure & Access Control (continued) ---

    /**
     * @dev Grants the CHRONOSCRIBE_ROLE to an account. Only callable by an admin.
     * @param _account The address to grant the role to.
     */
    function setChronoScribeRole(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CHRONOSCRIBE_ROLE, _account);
        emit ChronoScribeRoleGranted(_account);
    }

    /**
     * @dev Revokes the CHRONOSCRIBE_ROLE from an account. Only callable by an admin.
     * @param _account The address to revoke the role from.
     */
    function removeChronoScribeRole(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(CHRONOSCRIBE_ROLE, _account);
        emit ChronoScribeRoleRevoked(_account);
    }

    /**
     * @dev Pauses the contract. Only callable by an admin.
     * Prevents core operations like submitting/fulfilling whispers, and staking.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
        emit ChronoCasterPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only callable by an admin.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
        emit ChronoCasterUnpaused(msg.sender);
    }

    /**
     * @dev Allows the contract admin to withdraw any accumulated ETH.
     */
    function withdrawEth() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to withdraw Ether");
    }

    // --- II. Aethershards (ERC-20 Token) Management ---

    /**
     * @dev Mints new Aethershards and assigns them to an address.
     * Primarily for initial distribution or specific reward mechanisms managed by admin.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function mintAetherShards(address _to, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(_to, _amount);
    }

    /**
     * @dev Allows users to burn their own Aethershards.
     * @param _amount The amount of tokens to burn.
     */
    function burnAetherShards(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    // Staked Aethershards for voting power / benefits
    mapping(address => uint256) public stakedBalances;

    /**
     * @dev Allows a user to stake Aethershards to gain voting power or other benefits.
     * @param _amount The amount of Aethershards to stake.
     */
    function stakeAetherShards(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "Stake amount must be positive");
        require(balanceOf(msg.sender) >= _amount, "Insufficient ASH balance to stake");

        _transfer(msg.sender, address(this), _amount); // Transfer to contract
        stakedBalances[msg.sender] += _amount;
    }

    /**
     * @dev Allows a user to unstake Aethershards.
     * @param _amount The amount of Aethershards to unstake.
     */
    function unstakeAetherShards(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "Unstake amount must be positive");
        require(stakedBalances[msg.sender] >= _amount, "Insufficient staked ASH balance");

        stakedBalances[msg.sender] -= _amount;
        _transfer(address(this), msg.sender, _amount); // Transfer back from contract
    }

    // --- III. Whisper (Time-Gated Data/Prediction) Management ---

    /**
     * @dev Allows a Chronoscribe to submit a new Whisper.
     * Requires a fee in Aethershards.
     * @param _category A string defining the category of the Whisper (e.g., "AI_Narrative", "Market_Event").
     * @param _predictionTimestamp The Unix timestamp when this Whisper's predicted data should become relevant.
     * @param _dataHash The IPFS hash of the predicted data/content.
     * @param _submissionFee The Aethershards fee for submission. Must match `whisperSubmissionFee`.
     */
    function submitWhisper(
        string calldata _category,
        uint256 _predictionTimestamp,
        string calldata _dataHash,
        uint256 _submissionFee
    ) public whenNotPaused nonReentrant onlyRole(CHRONOSCRIBE_ROLE) {
        require(_predictionTimestamp > block.timestamp, "Prediction timestamp must be in the future");
        require(_submissionFee == whisperSubmissionFee, "Incorrect submission fee");
        
        // Transfer submission fee to the contract
        require(ERC20(address(this)).transferFrom(msg.sender, address(this), _submissionFee), "Token transfer failed for fee");

        _whisperIds.increment();
        uint256 newId = _whisperIds.current();

        whispers[newId] = Whisper({
            id: newId,
            category: _category,
            chronoScribe: msg.sender,
            submissionTimestamp: block.timestamp,
            predictionTimestamp: _predictionTimestamp,
            dataHash: _dataHash,
            fulfilledDataHash: "",
            isFulfilled: false,
            isChallenged: false,
            challengeId: 0
        });

        chronoScribeWhispers[msg.sender].push(newId);

        emit WhisperSubmitted(newId, _category, msg.sender, _predictionTimestamp, _dataHash);
    }

    /**
     * @dev Allows the Chronoscribe who submitted a Whisper to mark it as fulfilled.
     * Can only be called after `predictionTimestamp`.
     * If successful, updates ChronoSentinels attuned to this category and adjusts reputation.
     * @param _whisperId The ID of the Whisper to fulfill.
     * @param _actualDataHash The IPFS hash of the actual data, to be compared with the predicted data.
     */
    function fulfillWhisper(uint256 _whisperId, string calldata _actualDataHash) public whenNotPaused nonReentrant onlyRole(CHRONOSCRIBE_ROLE) {
        Whisper storage whisper = whispers[_whisperId];
        require(whisper.chronoScribe == msg.sender, "Only the original Chronoscribe can fulfill");
        require(whisper.predictionTimestamp <= block.timestamp, "Whisper cannot be fulfilled yet");
        require(!whisper.isFulfilled, "Whisper already fulfilled");
        require(!whisper.isChallenged, "Whisper is currently challenged");

        whisper.isFulfilled = true;
        whisper.fulfilledDataHash = _actualDataHash;

        // Distribute reward to fulfiller (from reward pool)
        // In a more complex system, this might involve more checks or a vote
        require(ERC20(address(this)).transfer(msg.sender, fulfillmentRewardPool), "Failed to transfer fulfillment reward");

        // Update ChronoScribe reputation
        chronoScribeReputation[msg.sender] += int256(REPUTATION_BONUS_FULFILL);
        emit ChronoScribeReputationUpdated(msg.sender, chronoScribeReputation[msg.sender], int256(REPUTATION_BONUS_FULFILL));

        // Trigger ChronoSentinel metadata updates for attuned Sentinels
        _updateAttunedSentinelsMetadata(_whisperId, whisper.category, whisper.fulfilledDataHash);

        emit WhisperFulfilled(_whisperId, msg.sender, _actualDataHash, block.timestamp);
    }

    /**
     * @dev Allows any user to challenge the fulfillment of a Whisper.
     * Requires a `challengeDeposit` in Aethershards.
     * Initiates a DAO vote to resolve the challenge.
     * @param _whisperId The ID of the Whisper being challenged.
     * @param _proposedActualDataHash The IPFS hash that the challenger believes is the correct actual data.
     */
    function challengeWhisperFulfillment(uint256 _whisperId, string calldata _proposedActualDataHash) public whenNotPaused nonReentrant {
        Whisper storage whisper = whispers[_whisperId];
        require(whisper.isFulfilled, "Only fulfilled Whispers can be challenged");
        require(!whisper.isChallenged, "Whisper is already under challenge");
        require(_proposedActualDataHash.length > 0, "Proposed actual data hash cannot be empty");

        // Take challenge deposit
        require(ERC20(address(this)).transferFrom(msg.sender, address(this), challengeDeposit), "Failed to transfer challenge deposit");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        whisperChallenges[newChallengeId] = WhisperChallenge({
            id: newChallengeId,
            whisperId: _whisperId,
            challenger: msg.sender,
            proposedActualDataHash: _proposedActualDataHash,
            challengeTime: block.timestamp,
            resolveTime: 0,
            resolved: false,
            challengerWon: false
        });

        whisper.isChallenged = true;
        whisper.challengeId = newChallengeId;

        // Automatically create a DAO proposal for this challenge
        // In a real DAO, this would be more complex, involving encoding the resolveWhisperChallenge call
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();
        
        // Example of simple callData for resolution, actual implementation would need careful encoding
        // For simplicity here, the governance role will directly call resolveWhisperChallenge
        // based on the DAO vote outcome.
        bytes memory callData = abi.encodeWithSelector(
            this.resolveWhisperChallenge.selector,
            newChallengeId,
            true // Placeholder, actual resolution is by DAO
        );

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: address(this), // The contract itself creates this proposal
            description: string(abi.encodePacked("Resolve Whisper Challenge #", newChallengeId.toString(), " for Whisper #", _whisperId.toString())),
            callData: callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotePeriod,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(),
            executed: false,
            passed: false
        });

        emit WhisperChallengeCreated(newChallengeId, _whisperId, msg.sender);
        emit ProposalCreated(newProposalId, address(this), proposals[newProposalId].description);
    }


    /**
     * @dev Resolves a Whisper challenge. Callable by GOVERNANCE_ROLE after a vote (simplified).
     * Impacts Chronoscribe and challenger reputation.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _isFulfilledCorrectly True if the original fulfillment was correct, false if the challenge was valid.
     */
    function resolveWhisperChallenge(uint256 _challengeId, bool _isFulfilledCorrectly) public onlyRole(GOVERNANCE_ROLE) nonReentrant {
        WhisperChallenge storage challenge = whisperChallenges[_challengeId];
        require(!challenge.resolved, "Challenge already resolved");

        Whisper storage whisper = whispers[challenge.whisperId];
        require(whisper.isChallenged && whisper.challengeId == _challengeId, "Whisper not associated with this challenge or not challenged");

        challenge.resolved = true;
        challenge.resolveTime = block.timestamp;
        challenge.challengerWon = !_isFulfilledCorrectly; // If original was incorrect, challenger won

        // Reputation adjustments
        if (challenge.challengerWon) {
            // Challenger wins: Challenger gets deposit back + bonus, Original Chronoscribe loses reputation
            require(ERC20(address(this)).transfer(challenge.challenger, challengeDeposit), "Failed to refund challenger deposit");
            chronoScribeReputation[challenge.challenger] += int256(REPUTATION_BONUS_CHALLENGE_WIN);
            emit ChronoScribeReputationUpdated(challenge.challenger, chronoScribeReputation[challenge.challenger], int256(REPUTATION_BONUS_CHALLENGE_WIN));

            chronoScribeReputation[whisper.chronoScribe] -= int256(REPUTATION_PENALTY_CHALLENGE_LOSS);
            emit ChronoScribeReputationUpdated(whisper.chronoScribe, chronoScribeReputation[whisper.chronoScribe], -int256(REPUTATION_PENALTY_CHALLENGE_LOSS));

            // If challenge won, the original fulfillment was incorrect, reset and potentially re-do
            whisper.isFulfilled = false; // Mark as unfulfilled so it can be fulfilled correctly
            whisper.fulfilledDataHash = "";
            // In a real system, this would also trigger a reset of Sentinel metadata that changed based on this incorrect fulfillment.
            // For simplicity, we just mark the whisper as unfulfilled.
        } else {
            // Challenger loses: Challenger's deposit is absorbed into the contract (e.g., burned or added to reward pool)
            // No direct reputation change for original chronoscribe from this
            // We'll consider the deposit "burned" for simplicity.
        }

        whisper.isChallenged = false; // Clear challenge status
        whisper.challengeId = 0; // Reset challenge ID

        emit WhisperChallengeResolved(_challengeId, challenge.whisperId, challenge.challengerWon);
    }

    /**
     * @dev Retrieves details of a specific Whisper.
     * @param _whisperId The ID of the Whisper.
     * @return A tuple containing all Whisper details.
     */
    function getWhisperDetails(uint256 _whisperId) public view returns (
        uint256 id,
        string memory category,
        address chronoScribe,
        uint256 submissionTimestamp,
        uint256 predictionTimestamp,
        string memory dataHash,
        string memory fulfilledDataHash,
        bool isFulfilled,
        bool isChallenged,
        uint256 challengeId
    ) {
        Whisper storage w = whispers[_whisperId];
        return (
            w.id,
            w.category,
            w.chronoScribe,
            w.submissionTimestamp,
            w.predictionTimestamp,
            w.dataHash,
            w.fulfilledDataHash,
            w.isFulfilled,
            w.isChallenged,
            w.challengeId
        );
    }

    /**
     * @dev Returns the total number of Whispers submitted.
     * @return The total Whisper count.
     */
    function getWhisperCount() public view returns (uint256) {
        return _whisperIds.current();
    }

    /**
     * @dev Returns an array of Whisper IDs submitted by a specific Chronoscribe.
     * @param _scribe The address of the Chronoscribe.
     * @return An array of Whisper IDs.
     */
    function getWhispersByChronoScribe(address _scribe) public view returns (uint256[] memory) {
        return chronoScribeWhispers[_scribe];
    }

    // --- IV. ChronoSentinel (Dynamic NFT) Management ---

    /**
     * @dev Mints a new ChronoSentinel NFT to the caller.
     * @param _initialMetadataURI The initial metadata URI for the NFT.
     */
    function mintChronoSentinel(string calldata _initialMetadataURI) public whenNotPaused {
        _sentinelIds.increment();
        uint256 newTokenId = _sentinelIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _initialMetadataURI);
        emit ChronoSentinelMinted(newTokenId, msg.sender, _initialMetadataURI);
    }

    /**
     * @dev Allows an owner to attune their ChronoSentinel to a specific Whisper category.
     * Attuned Sentinels will have their metadata updated when a relevant Whisper is fulfilled.
     * @param _tokenId The ID of the ChronoSentinel NFT.
     * @param _category The Whisper category to attune to.
     */
    function attuneSentinelToWhisperCategory(uint256 _tokenId, string calldata _category) public whenNotPaused {
        require(_exists(_tokenId), "ChronoSentinel does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Must own the ChronoSentinel");

        // Check if already attuned to this category
        for (uint256 i = 0; i < sentinelAttunements[_tokenId].length; i++) {
            if (keccak256(abi.encodePacked(sentinelAttunements[_tokenId][i])) == keccak256(abi.encodePacked(_category))) {
                revert AlreadyAttuned();
            }
        }
        sentinelAttunements[_tokenId].push(_category);
        emit ChronoSentinelAttuned(_tokenId, _category);
    }

    /**
     * @dev Internal function to update the metadata URI of ChronoSentinels attuned to a specific category
     * when a Whisper in that category is fulfilled.
     * This is the core dynamic NFT logic.
     * @param _whisperId The ID of the fulfilled Whisper.
     * @param _category The category of the fulfilled Whisper.
     * @param _fulfilledDataHash The data hash of the fulfilled Whisper.
     */
    function _updateAttunedSentinelsMetadata(uint256 _whisperId, string memory _category, string memory _fulfilledDataHash) internal {
        // Iterate through all existing Sentinels (inefficient for many NFTs,
        // a more advanced solution would use a separate mapping for categories to token IDs)
        // For demonstration, we'll iterate through a small assumed range or use a known list.
        // A better approach would be to have Sentinel owners 'pull' updates or subscribe.
        // For simplicity, we'll loop through all minted tokens.
        uint256 totalSentinels = _sentinelIds.current();
        for (uint256 i = 1; i <= totalSentinels; i++) {
            for (uint256 j = 0; j < sentinelAttunements[i].length; j++) {
                if (keccak256(abi.encodePacked(sentinelAttunements[i][j])) == keccak256(abi.encodePacked(_category))) {
                    // This sentinel is attuned to the fulfilled category
                    // Update its last fulfilled whisper for this category
                    sentinelLastFulfilledWhisper[i][_category] = _whisperId;

                    // Construct new metadata URI dynamically
                    // Example: base_uri/token_id/category_fulfilled_hash.json
                    // Or, more complex: metadata service queries on-chain state to generate URI
                    string memory newURI = string(abi.encodePacked(
                        _baseSentinelURI,
                        i.toString(),
                        "/",
                        _category,
                        "-",
                        _fulfilledDataHash, // Incorporate the data hash to reflect the change
                        ".json"
                    ));
                    _setTokenURI(i, newURI);
                    emit ChronoSentinelMetadataUpdated(i, newURI);
                    break; // Move to next sentinel after finding a match for this one
                }
            }
        }
    }

    /**
     * @dev Admin function to update the base URI for all ChronoSentinels.
     * @param _newURI The new base URI.
     */
    function updateSentinelBaseURI(string calldata _newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseSentinelURI = _newURI;
    }

    /**
     * @dev Gets the details of a ChronoSentinel.
     * @param _tokenId The ID of the ChronoSentinel.
     * @return A tuple containing the owner, initial URI, and attuned categories.
     */
    function getSentinelDetails(uint256 _tokenId) public view returns (address owner, string memory currentURI, string[] memory attunedCategories) {
        require(_exists(_tokenId), "ChronoSentinel does not exist");
        return (ownerOf(_tokenId), tokenURI(_tokenId), sentinelAttunements[_tokenId]);
    }

    /**
     * @dev Returns the owner of a ChronoSentinel. (Overrides ERC721's ownerOf to include require for existence).
     * @param _tokenId The ID of the ChronoSentinel.
     */
    function getSentinelOwner(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "ChronoSentinel does not exist");
        return ownerOf(_tokenId);
    }

    /**
     * @dev Overrides ERC721URIStorage's tokenURI to provide dynamic URI generation.
     * The actual URI might be more complex, involving off-chain services interpreting the on-chain state.
     * For simplicity, this returns the last set URI directly.
     * @param _tokenId The ID of the ChronoSentinel.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[_tokenId];
        // If _tokenURI is empty, potentially fallback to a default construction or _baseSentinelURI + tokenId
        if (bytes(_tokenURI).length == 0) {
            return string(abi.encodePacked(_baseSentinelURI, _tokenId.toString(), ".json"));
        }
        return _tokenURI;
    }

    // --- V. Reputation System ---

    /**
     * @dev Returns the current reputation score of a Chronoscribe.
     * @param _scribe The address of the Chronoscribe.
     * @return The reputation score.
     */
    function getChronoScribeReputation(address _scribe) public view returns (int256) {
        return chronoScribeReputation[_scribe];
    }

    /**
     * @dev Calculates a potential bonus for a Sentinel based on its attunements and successfully fulfilled Whispers.
     * This could influence staking rewards, future features, or visual rarity.
     * @param _tokenId The ID of the ChronoSentinel.
     * @return The calculated bonus score.
     */
    function getSentinelAttunementBonus(uint256 _tokenId) public view returns (uint256) {
        uint256 bonus = 0;
        for (uint256 i = 0; i < sentinelAttunements[_tokenId].length; i++) {
            string memory category = sentinelAttunements[_tokenId][i];
            uint256 lastWhisperId = sentinelLastFulfilledWhisper[_tokenId][category];
            if (lastWhisperId > 0 && whispers[lastWhisperId].isFulfilled) {
                // Example: 10 bonus points per successfully fulfilled attuned whisper
                bonus += 10;
                // Could be more complex: influence by chronoscribe reputation, difficulty of prediction, etc.
            }
        }
        return bonus;
    }

    // --- VI. DAO Governance (Simplified) ---

    /**
     * @dev Allows users with sufficient staked Aethershards to propose a parameter change.
     * @param _description A description of the proposal.
     * @param _callData The encoded function call to execute if the proposal passes.
     * (E.g., `abi.encodeWithSelector(this.setWhisperSubmissionFee.selector, newFeeAmount)`)
     */
    function proposeParameterChange(string calldata _description, bytes calldata _callData) public whenNotPaused {
        require(stakedBalances[msg.sender] >= minStakeForProposal, "Insufficient staked Aethershards for proposal");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotePeriod,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(), // Initialize mapping
            executed: false,
            passed: false
        });

        emit ProposalCreated(newProposalId, msg.sender, _description);
    }

    /**
     * @dev Allows users to vote on an open proposal using their staked Aethershards.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period is not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(stakedBalances[msg.sender] > 0, "No Aethershards staked to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += stakedBalances[msg.sender];
        } else {
            proposal.votesAgainst += stakedBalances[msg.sender];
        }
        emit VoteCast(_proposalId, msg.sender, _support, stakedBalances[msg.sender]);
    }

    /**
     * @dev Executes a proposal if it has passed its voting period and received enough 'for' votes.
     * Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant onlyRole(GOVERNANCE_ROLE) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.voteEndTime, "Voting period not ended");

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= minVotePowerForProposal) {
            proposal.passed = true;
            (bool success,) = address(this).call(proposal.callData);
            require(success, "Proposal execution failed");
        } else {
            proposal.passed = false;
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // --- Helper Functions (Could be parameters adjustable by DAO) ---
    function setWhisperSubmissionFee(uint256 _newFee) public onlyRole(GOVERNANCE_ROLE) {
        whisperSubmissionFee = _newFee;
    }

    function setFulfillmentRewardPool(uint256 _newReward) public onlyRole(GOVERNANCE_ROLE) {
        fulfillmentRewardPool = _newReward;
    }

    function setChallengeDeposit(uint256 _newDeposit) public onlyRole(GOVERNANCE_ROLE) {
        challengeDeposit = _newDeposit;
    }

    function setProposalVotePeriod(uint256 _newPeriod) public onlyRole(GOVERNANCE_ROLE) {
        proposalVotePeriod = _newPeriod;
    }

    function setMinStakeForProposal(uint256 _newMinStake) public onlyRole(GOVERNANCE_ROLE) {
        minStakeForProposal = _newMinStake;
    }

    function setMinVotePowerForProposal(uint256 _newMinVotePower) public onlyRole(GOVERNANCE_ROLE) {
        minVotePowerForProposal = _newMinVotePower;
    }

    // --- Access Control overrides for ERC721, ERC20, Pausable ---
    // The following functions ensure that OpenZeppelin's internal functions
    // correctly interact with this contract's AccessControl.
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ERC20/ERC721 _beforeTokenTransfer for pausing mechanism
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC721) {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "Pausable: token transfer paused");
    }

    function _update(address to, uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) returns (address) {
        return super._update(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```