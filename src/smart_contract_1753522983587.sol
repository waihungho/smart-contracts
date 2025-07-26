This smart contract, named **VOCAIP (Verifiable On-Chain Collective Intelligence & Adaptive Prediction Market)**, is designed to be an advanced, unique, and creative protocol. It combines concepts of decentralized knowledge bases, prediction markets, soulbound reputation (Wisdom Score), and dynamic NFTs.

It aims to incentivize accurate data contribution and forecasting by building an on-chain reputation system. Agents stake ETH to participate, submit "fact claims" with evidence, or make predictions on events. Their "Wisdom Score" (a non-transferable value akin to an SBT) increases or decreases based on the accuracy of their contributions and predictions. This score is visually represented by a dynamic NFT that changes its appearance and attributes as the agent's reputation evolves.

---

## Contract Outline

**I. Core Protocol Management & Access**
    *   `constructor`: Initializes the contract, sets initial parameters, and deploys the associated `VOCAIPAgentNFT` contract.
    *   `pause()`: Pauses contract functionality, callable only by the owner.
    *   `unpause()`: Unpauses contract functionality, callable only by the owner.
    *   `transferOwnership(address newOwner)`: Transfers contract ownership to a new address (inherited from `Ownable`).

**II. Agent Management & Staking**
    *   `registerAgent()`: Allows a user to become a `VOCAIP` Agent by staking the required minimum amount, minting them a unique dynamic AgentProfile NFT.
    *   `deregisterAgent()`: Initiates the deregistration process for an agent, locking their stake for a cooldown period and preventing further contributions.
    *   `withdrawAgentStake()`: Allows a deregistered agent to withdraw their stake after the cooldown period has elapsed.
    *   `setAgentMinStake(uint256 _newMinStake)`: Owner function to adjust the minimum stake required for agent registration.

**III. Knowledge Base: Fact Claiming & Curation**
    *   `submitFactClaim(string memory _evidenceURI, string memory _claimHash)`: Agents submit a new "Fact Claim" to the knowledge base, linking to off-chain evidence and a content hash.
    *   `supportFactClaim(uint256 _claimId)`: Agents can show support for an existing fact claim, enhancing its perceived credibility.
    *   `challengeFactClaim(uint256 _claimId, string memory _reasonURI)`: Agents can formally challenge a fact claim, initiating a dispute and providing reasons/evidence.
    *   `resolveFactChallenge(uint256 _claimId, bool _challengerWins)`: Owner/Oracle resolves a fact claim dispute, updating its status and adjusting the reputations of the submitter and challenger.
    *   `getFactClaimDetails(uint256 _claimId)`: Retrieves comprehensive details about a specific fact claim.
    *   `getFactClaimsByStatus(FactStatus _status)`: Retrieves a list of fact claim IDs filtered by their current status. (Note: inefficient for large datasets)

**IV. Prediction Market: Events & Forecasting**
    *   `createPredictionEvent(string memory _question, uint256 _resolutionTime)`: Any user can propose a new prediction market event with a clear question and a future resolution deadline.
    *   `submitPrediction(uint256 _eventId, bool _prediction)`: Registered agents submit their boolean prediction (true/false) for an active event, requiring a small stake.
    *   `endorsePrediction(uint256 _eventId, address _agentAddress)`: Agents can endorse another agent's prediction for a specific event, adding reputational weight.
    *   `resolvePredictionEventOutcome(uint256 _eventId, bool _outcome)`: Owner/Oracle determines and sets the final outcome of a prediction event, triggering reputation updates for all participating agents based on accuracy. (Note: iterating all agents for rewards is inefficient for large scale)
    *   `getPredictionEventDetails(uint256 _eventId)`: Retrieves all details of a specific prediction event.
    *   `getAgentPredictionForEvent(uint256 _eventId, address _agentAddress)`: Retrieves an agent's submitted prediction for a given event.

**V. Reputation & Dynamic NFTs**
    *   `getAgentWisdomScore(address _agentAddress)`: Returns the current non-transferable Wisdom Score of a specific agent.
    *   `getAgentProfileNFTTokenId(address _agentAddress)`: Returns the unique token ID of an agent's dynamic profile NFT.
    *   `getTokenURI(uint256 _tokenId)`: Public function to get the metadata URI for a given NFT token ID (part of ERC721 metadata).
    *   `_updateAgentWisdomScore(address _agent, int252 _delta)`: Internal function to adjust an agent's Wisdom Score.
    *   `_updateAgentProfileNFT(address _agent, uint256 _newScore)`: Internal function to update the metadata URI of an agent's dynamic NFT based on their new Wisdom Score, dynamically generating Base64 encoded JSON metadata.

**VI. Utility & Admin**
    *   `withdrawProtocolFees()`: Owner can withdraw accumulated protocol fees. (Conceptual, as exact fee collection is simplified in this version).

---

## Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title VOCAIPAgentNFT
 * @dev ERC721 contract for dynamic agent profile NFTs.
 *      The metadata URI for each token can be updated by the VOCAIP core contract.
 *      This allows the NFT's visual representation to evolve with the agent's Wisdom Score.
 */
contract VOCAIPAgentNFT is ERC721URIStorage {
    address public vocaipCoreContract;

    modifier onlyVOCAIPCore() {
        require(msg.sender == vocaipCoreContract, "VOCAIPAgentNFT: Only VOCAIP core contract can call this function");
        _;
    }

    constructor(address _vocaipCoreContract) ERC721("VOCAIP Agent Profile", "VOCAIPNFT") {
        require(_vocaipCoreContract != address(0), "VOCAIPAgentNFT: VOCAIP core contract address cannot be zero");
        vocaipCoreContract = _vocaipCoreContract;
    }

    /**
     * @dev Mints a new NFT for a specific agent. Callable only by the VOCAIP core contract.
     * @param _to The address of the agent to mint the NFT for.
     * @param _tokenId The unique token ID for the new NFT.
     * @param _tokenURI The initial metadata URI for the NFT.
     */
    function mint(address _to, uint256 _tokenId, string memory _tokenURI) external onlyVOCAIPCore {
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @dev Updates the metadata URI for an existing NFT. Callable only by the VOCAIP core contract.
     *      This is the key to making the NFT "dynamic" on-chain, as its metadata (and thus appearance)
     *      can be changed post-mint based on logic in the VOCAIP core contract.
     * @param _tokenId The ID of the NFT to update.
     * @param _newTokenURI The new metadata URI for the NFT.
     */
    function updateTokenURI(uint256 _tokenId, string memory _newTokenURI) external onlyVOCAIPCore {
        _setTokenURI(_tokenId, _newTokenURI);
    }

    // The tokenURI function is inherited from ERC721URIStorage and will return the set URI.
}


/**
 * @title VOCAIP (Verifiable On-Chain Collective Intelligence & Adaptive Prediction Market)
 * @dev A decentralized protocol where participants contribute data, make predictions,
 *      and collectively build a verifiable on-chain knowledge base. The system evaluates
 *      accuracy, assigns reputation (Soulbound Wisdom Scores), and incentivizes truthful
 *      contributions, enabling a resilient and adaptive prediction market.
 *      It also features dynamic NFTs that visually represent an agent's on-chain
 *      reputation and influence.
 */
contract VOCAIP is Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Outline ---
    // I. Core Protocol Management & Access
    // II. Agent Management & Staking
    // III. Knowledge Base: Fact Claiming & Curation
    // IV. Prediction Market: Events & Forecasting
    // V. Reputation & Dynamic NFTs
    // VI. Utility & Admin

    // --- Function Summary ---

    // I. Core Protocol Management & Access
    // 1. constructor(): Initializes the contract, sets initial parameters, and deploys VOCAIPAgentNFT.
    // 2. pause(): Pauses contract functionality, callable only by the owner.
    // 3. unpause(): Unpauses contract functionality, callable only by the owner.
    // 4. transferOwnership(address newOwner): Transfers contract ownership to a new address. (Inherited)

    // II. Agent Management & Staking
    // 5. registerAgent(): Allows a user to become a VOCAIP Agent by staking the required minimum amount,
    //    minting them a unique dynamic AgentProfile NFT.
    // 6. deregisterAgent(): Initiates the deregistration process for an agent, locking their stake for a cooldown period.
    // 7. withdrawAgentStake(): Allows a deregistered agent to withdraw their stake after the cooldown period.
    // 8. setAgentMinStake(uint256 _newMinStake): Owner function to adjust the minimum stake required for agent registration.

    // III. Knowledge Base: Fact Claiming & Curation
    // 9. submitFactClaim(string memory _evidenceURI, string memory _claimHash): Agents submit a new "Fact Claim".
    // 10. supportFactClaim(uint256 _claimId): Agents can show support for an existing fact claim.
    // 11. challengeFactClaim(uint256 _claimId, string memory _reasonURI): Agents can formally challenge a fact claim.
    // 12. resolveFactChallenge(uint256 _claimId, bool _challengerWins): Owner/Oracle resolves a fact claim dispute.
    // 13. getFactClaimDetails(uint256 _claimId): Retrieves comprehensive details about a specific fact claim.
    // 14. getFactClaimsByStatus(FactStatus _status): Retrieves a list of fact claim IDs filtered by their current status.

    // IV. Prediction Market: Events & Forecasting
    // 15. createPredictionEvent(string memory _question, uint256 _resolutionTime): Any user can propose a new prediction market event.
    // 16. submitPrediction(uint256 _eventId, bool _prediction): Registered agents submit their boolean prediction.
    // 17. endorsePrediction(uint256 _eventId, address _agentAddress): Agents can endorse another agent's prediction.
    // 18. resolvePredictionEventOutcome(uint256 _eventId, bool _outcome): Owner/Oracle determines and sets the final outcome of a prediction event.
    // 19. getPredictionEventDetails(uint256 _eventId): Retrieves all details of a specific prediction event.
    // 20. getAgentPredictionForEvent(uint256 _eventId, address _agentAddress): Retrieves an agent's submitted prediction for a given event.

    // V. Reputation & Dynamic NFTs
    // 21. getAgentWisdomScore(address _agentAddress): Returns the current non-transferable Wisdom Score of a specific agent.
    // 22. getAgentProfileNFTTokenId(address _agentAddress): Returns the unique token ID of an agent's dynamic profile NFT.
    // 23. getTokenURI(uint256 _tokenId): Public function to get the metadata URI for a given NFT token ID.
    // 24. _updateAgentWisdomScore(address _agent, int256 _delta): Internal function to adjust an agent's Wisdom Score.
    // 25. _updateAgentProfileNFT(address _agent, uint256 _newScore): Internal function to update the metadata URI of an agent's dynamic NFT.

    // VI. Utility & Admin
    // 26. withdrawProtocolFees(): Owner can withdraw accumulated protocol fees. (Conceptual, no explicit fees collected in this version).

    // --- Constants & Configuration ---
    uint256 public constant DEREGISTRATION_COOLDOWN_PERIOD = 30 days;
    uint256 public constant PREDICTION_STAKE_AMOUNT = 0.001 ether; // Small stake for predictions

    // --- State Variables ---
    VOCAIPAgentNFT public vocaipAgentNFT;
    uint256 public agentMinStake;

    // Agent Profiles
    struct AgentProfile {
        bool isRegistered;
        uint256 stakeAmount;
        uint256 deregistrationTime; // 0 if not deregistering, indicates when cooldown ends
        uint256 wisdomScore; // Soulbound reputation score
        uint256 nftTokenId; // Unique token ID for their dynamic NFT
        bool hasMintedNFT; // To ensure only one NFT per agent
    }
    mapping(address => AgentProfile) public agents;
    Counters.Counter private _nextAgentNFTId; // Counter for unique NFT IDs

    // Fact Claims
    enum FactStatus { PENDING, VERIFIED, DISPUTED }
    struct FactClaim {
        address submitter;
        string evidenceURI; // URI to off-chain evidence (e.g., IPFS hash)
        string claimHash;   // Cryptographic hash of the claim content itself
        uint256 timestamp;
        FactStatus status;
        uint256 supportCount; // Number of agents supporting this claim
        uint256 challengeCount; // Number of agents challenging this claim
        mapping(address => bool) hasSupported; // Track unique supporters
        mapping(address => bool) hasChallenged; // Track unique challengers
    }
    mapping(uint256 => FactClaim) public factClaims;
    Counters.Counter private _nextFactClaimId;

    // Prediction Events
    enum Outcome { UNDETERMINED, TRUE, FALSE }
    struct PredictionEvent {
        address proposer;
        string question;
        uint256 resolutionTime;
        Outcome outcome;
        bool isResolved;
        uint256 totalStakedForEvent; // Sum of stakes from all predictions for this event
        mapping(address => AgentPrediction) predictions; // Agent address => their prediction
    }
    struct AgentPrediction {
        bool prediction; // True or False
        uint256 stake;   // Stake submitted with this prediction
        uint256 timestamp;
        address endorsedAgent; // Optional: which agent's prediction this agent endorsed
    }
    mapping(uint256 => PredictionEvent) public predictionEvents;
    Counters.Counter private _nextPredictionEventId;

    // --- Events ---
    event AgentRegistered(address indexed agent, uint256 stakeAmount, uint256 nftTokenId);
    event AgentDeregistrationInitiated(address indexed agent, uint256 cooldownEnds);
    event AgentStakeWithdrawn(address indexed agent, uint256 amount);
    event AgentMinStakeUpdated(uint256 newMinStake);

    event FactClaimSubmitted(uint256 indexed claimId, address indexed submitter, string claimHash);
    event FactClaimSupported(uint256 indexed claimId, address indexed supporter);
    event FactClaimChallenged(uint256 indexed claimId, address indexed challenger, string reasonURI);
    event FactChallengeResolved(uint256 indexed claimId, bool challengerWins, FactStatus newStatus);

    event PredictionEventCreated(uint256 indexed eventId, address indexed proposer, string question, uint256 resolutionTime);
    event PredictionSubmitted(uint256 indexed eventId, address indexed agent, bool prediction);
    event PredictionEndorsed(uint256 indexed eventId, address indexed endorser, address indexed endorsedAgent);
    event PredictionEventResolved(uint256 indexed eventId, Outcome outcome);

    event WisdomScoreUpdated(address indexed agent, uint256 newScore, int256 delta);
    event AgentProfileNFTUpdated(uint256 indexed tokenId, address indexed agent, string newUri);

    // --- I. Core Protocol Management & Access ---

    /**
     * @dev Initializes the contract, sets initial parameters, and deploys the associated VOCAIPAgentNFT contract.
     * @param _initialMinStake The minimum ETH required to register as an agent.
     */
    constructor(uint256 _initialMinStake) Ownable(msg.sender) Pausable() {
        require(_initialMinStake > 0, "VOCAIP: Initial min stake must be greater than zero");
        agentMinStake = _initialMinStake;
        vocaipAgentNFT = new VOCAIPAgentNFT(address(this)); // Deploy the NFT contract and set this contract as its core
    }

    /**
     * @dev Pauses contract functionality, callable only by the owner.
     *      Inherited from OpenZeppelin Pausable.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract functionality, callable only by the owner.
     *      Inherited from OpenZeppelin Pausable.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // `transferOwnership` is inherited from OpenZeppelin `Ownable`.

    // --- II. Agent Management & Staking ---

    /**
     * @dev Allows a user to become a VOCAIP Agent by staking the required minimum amount.
     *      Mints a unique dynamic AgentProfile NFT for the new agent.
     *      Initial wisdom score is 100.
     */
    function registerAgent() public payable whenNotPaused {
        require(!agents[msg.sender].hasMintedNFT, "VOCAIP: Address already has an agent profile NFT");
        require(msg.value >= agentMinStake, "VOCAIP: Insufficient stake amount");

        agents[msg.sender].isRegistered = true;
        agents[msg.sender].stakeAmount = msg.value;
        agents[msg.sender].wisdomScore = 100; // Initial wisdom score

        // Mint a new dynamic NFT for the agent
        uint256 newNftId = _nextAgentNFTId.current();
        agents[msg.sender].nftTokenId = newNftId;
        agents[msg.sender].hasMintedNFT = true; // Mark that an NFT has been minted for this address
        
        // Initial NFT URI can be a base URI or a placeholder.
        // The _updateAgentProfileNFT will set the dynamic URI later based on wisdom score.
        vocaipAgentNFT.mint(msg.sender, newNftId, ""); 
        _updateAgentProfileNFT(msg.sender, agents[msg.sender].wisdomScore); // Set initial dynamic URI

        _nextAgentNFTId.increment();

        emit AgentRegistered(msg.sender, msg.value, newNftId);
        emit WisdomScoreUpdated(msg.sender, agents[msg.sender].wisdomScore, 100);
    }

    /**
     * @dev Initiates the deregistration process for an agent.
     *      Their stake is locked for a cooldown period, and they can no longer participate in new actions.
     */
    function deregisterAgent() public whenNotPaused {
        require(agents[msg.sender].isRegistered, "VOCAIP: Not a registered agent or deregistration already in progress");
        require(agents[msg.sender].deregistrationTime == 0, "VOCAIP: Deregistration already in progress");

        agents[msg.sender].isRegistered = false; // Mark as not active for new contributions
        agents[msg.sender].deregistrationTime = block.timestamp + DEREGISTRATION_COOLDOWN_PERIOD;

        emit AgentDeregistrationInitiated(msg.sender, agents[msg.sender].deregistrationTime);
    }

    /**
     * @dev Allows a deregistered agent to withdraw their stake after the cooldown period has elapsed.
     *      Their NFT remains as a Soulbound Token, preserving their reputation history.
     */
    function withdrawAgentStake() public whenNotPaused {
        require(agents[msg.sender].hasMintedNFT, "VOCAIP: Agent profile not found");
        require(!agents[msg.sender].isRegistered, "VOCAIP: Agent is still active. Deregister first.");
        require(agents[msg.sender].deregistrationTime > 0, "VOCAIP: Deregistration not initiated");
        require(block.timestamp >= agents[msg.sender].deregistrationTime, "VOCAIP: Cooldown period not over");
        require(agents[msg.sender].stakeAmount > 0, "VOCAIP: No stake to withdraw");

        uint256 amount = agents[msg.sender].stakeAmount;
        agents[msg.sender].stakeAmount = 0; // Clear stake
        agents[msg.sender].deregistrationTime = 0; // Reset deregistration state

        payable(msg.sender).transfer(amount);
        emit AgentStakeWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Owner function to adjust the minimum stake required for agent registration.
     * @param _newMinStake The new minimum stake amount in wei.
     */
    function setAgentMinStake(uint256 _newMinStake) public onlyOwner whenNotPaused {
        require(_newMinStake > 0, "VOCAIP: Minimum stake must be greater than zero");
        agentMinStake = _newMinStake;
        emit AgentMinStakeUpdated(_newMinStake);
    }

    // --- III. Knowledge Base: Fact Claiming & Curation ---

    /**
     * @dev Agents submit a new "Fact Claim" to the knowledge base.
     *      `_evidenceURI` links to off-chain evidence (e.g., IPFS hash of a document, URL).
     *      `_claimHash` is a cryptographic hash of the claim's content itself, allowing for verifiability.
     * @param _evidenceURI URI pointing to supporting evidence.
     * @param _claimHash Hash of the claim content.
     */
    function submitFactClaim(string memory _evidenceURI, string memory _claimHash) public whenNotPaused {
        require(agents[msg.sender].isRegistered, "VOCAIP: Only registered agents can submit claims");
        require(bytes(_evidenceURI).length > 0, "VOCAIP: Evidence URI cannot be empty");
        require(bytes(_claimHash).length > 0, "VOCAIP: Claim hash cannot be empty");

        _nextFactClaimId.increment();
        uint256 newClaimId = _nextFactClaimId.current();

        FactClaim storage newClaim = factClaims[newClaimId];
        newClaim.submitter = msg.sender;
        newClaim.evidenceURI = _evidenceURI;
        newClaim.claimHash = _claimHash;
        newClaim.timestamp = block.timestamp;
        newClaim.status = FactStatus.PENDING;
        newClaim.supportCount = 0;
        newClaim.challengeCount = 0;

        emit FactClaimSubmitted(newClaimId, msg.sender, _claimHash);
    }

    /**
     * @dev Agents can show support for an existing fact claim, enhancing its perceived credibility.
     * @param _claimId The ID of the fact claim to support.
     */
    function supportFactClaim(uint256 _claimId) public whenNotPaused {
        require(agents[msg.sender].isRegistered, "VOCAIP: Only registered agents can support claims");
        FactClaim storage claim = factClaims[_claimId];
        require(claim.submitter != address(0), "VOCAIP: Claim does not exist");
        require(claim.status == FactStatus.PENDING, "VOCAIP: Cannot support a non-pending claim");
        require(claim.submitter != msg.sender, "VOCAIP: Cannot support your own claim");
        require(!claim.hasSupported[msg.sender], "VOCAIP: Already supported this claim");
        require(!claim.hasChallenged[msg.sender], "VOCAIP: Cannot support a claim you've challenged");

        claim.hasSupported[msg.sender] = true;
        claim.supportCount++;

        emit FactClaimSupported(_claimId, msg.sender);
    }

    /**
     * @dev Agents can formally challenge a fact claim, initiating a dispute.
     *      The claim automatically transitions to `DISPUTED` status.
     * @param _claimId The ID of the fact claim to challenge.
     * @param _reasonURI URI pointing to evidence/reasons for the challenge.
     */
    function challengeFactClaim(uint256 _claimId, string memory _reasonURI) public whenNotPaused {
        require(agents[msg.sender].isRegistered, "VOCAIP: Only registered agents can challenge claims");
        FactClaim storage claim = factClaims[_claimId];
        require(claim.submitter != address(0), "VOCAIP: Claim does not exist");
        require(claim.status == FactStatus.PENDING, "VOCAIP: Cannot challenge a non-pending claim");
        require(claim.submitter != msg.sender, "VOCAIP: Cannot challenge your own claim");
        require(!claim.hasChallenged[msg.sender], "VOCAIP: Already challenged this claim");
        require(!claim.hasSupported[msg.sender], "VOCAIP: Cannot challenge a claim you've supported");
        require(bytes(_reasonURI).length > 0, "VOCAIP: Reason URI cannot be empty");

        claim.hasChallenged[msg.sender] = true;
        claim.challengeCount++;
        claim.status = FactStatus.DISPUTED; 

        emit FactClaimChallenged(_claimId, msg.sender, _reasonURI);
    }

    /**
     * @dev Owner/Oracle resolves a fact claim dispute, updating its status and adjusting reputations.
     *      If `_challengerWins` is true, the original claim was deemed invalid; otherwise, it was valid.
     * @param _claimId The ID of the fact claim to resolve.
     * @param _challengerWins True if the challenger's argument is accepted, false if the original claim stands.
     */
    function resolveFactChallenge(uint256 _claimId, bool _challengerWins) public onlyOwner whenNotPaused {
        FactClaim storage claim = factClaims[_claimId];
        require(claim.submitter != address(0), "VOCAIP: Claim does not exist");
        require(claim.status == FactStatus.DISPUTED, "VOCAIP: Claim is not currently disputed");

        if (_challengerWins) {
            claim.status = FactStatus.PENDING; // Set to PENDING or INVALID based on desired flow
            _updateAgentWisdomScore(claim.submitter, -50); // Example penalty for original submitter
            // In a real system, logic for rewarding challengers based on their 'hasChallenged' list
            // would be here, possibly proportional to their stake or score.
        } else {
            claim.status = FactStatus.VERIFIED;
            _updateAgentWisdomScore(claim.submitter, 50); // Example reward for original submitter
            // Logic for penalizing incorrect challengers.
        }

        emit FactChallengeResolved(_claimId, _challengerWins, claim.status);
    }

    /**
     * @dev Retrieves comprehensive details about a specific fact claim.
     * @param _claimId The ID of the fact claim.
     * @return submitter Address of the claim submitter.
     * @return evidenceURI URI to off-chain evidence.
     * @return claimHash Hash of the claim content.
     * @return timestamp When the claim was submitted.
     * @return status Current status of the claim.
     * @return supportCount Number of agents who supported this claim.
     * @return challengeCount Number of agents who challenged this claim.
     */
    function getFactClaimDetails(uint256 _claimId) public view returns (
        address submitter, string memory evidenceURI, string memory claimHash,
        uint256 timestamp, FactStatus status, uint256 supportCount, uint256 challengeCount
    ) {
        FactClaim storage claim = factClaims[_claimId];
        require(claim.submitter != address(0), "VOCAIP: Claim does not exist");
        return (
            claim.submitter,
            claim.evidenceURI,
            claim.claimHash,
            claim.timestamp,
            claim.status,
            claim.supportCount,
            claim.challengeCount
        );
    }

    /**
     * @dev Retrieves a list of fact claim IDs filtered by their current status.
     *      NOTE: This is an expensive operation for contracts with many claims.
     *      For large-scale applications, external indexing services (e.g., The Graph)
     *      or a more complex on-chain data structure (like linked lists or paginated results)
     *      would be required for efficient querying. This implementation serves for demonstration.
     * @param _status The status to filter by.
     * @return claimIds An array of fact claim IDs matching the status.
     */
    function getFactClaimsByStatus(FactStatus _status) public view returns (uint256[] memory) {
        uint256 totalClaims = _nextFactClaimId.current();
        uint256[] memory matchingClaimIds = new uint256[](totalClaims); // Max possible size
        uint256 count = 0;

        for (uint256 i = 1; i <= totalClaims; i++) { // Assuming IDs start from 1
            if (factClaims[i].submitter != address(0) && factClaims[i].status == _status) {
                matchingClaimIds[count] = i;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingClaimIds[i];
        }
        return result;
    }

    // --- IV. Prediction Market: Events & Forecasting ---

    /**
     * @dev Any user can propose a new prediction market event with a clear question and a future resolution deadline.
     * @param _question The question for the prediction market (e.g., "Will ETH price exceed $3000 by 2024-01-01?").
     * @param _resolutionTime Unix timestamp when the event should be resolved.
     */
    function createPredictionEvent(string memory _question, uint256 _resolutionTime) public whenNotPaused {
        require(bytes(_question).length > 0, "VOCAIP: Question cannot be empty");
        require(_resolutionTime > block.timestamp, "VOCAIP: Resolution time must be in the future");

        _nextPredictionEventId.increment();
        uint256 newEventId = _nextPredictionEventId.current();

        PredictionEvent storage newEvent = predictionEvents[newEventId];
        newEvent.proposer = msg.sender;
        newEvent.question = _question;
        newEvent.resolutionTime = _resolutionTime;
        newEvent.outcome = Outcome.UNDETERMINED;
        newEvent.isResolved = false;
        newEvent.totalStakedForEvent = 0;

        emit PredictionEventCreated(newEventId, msg.sender, _question, _resolutionTime);
    }

    /**
     * @dev Registered agents submit their boolean prediction (true/false) for an active event.
     *      Requires a small stake per prediction, which is conceptually returned or redistributed based on accuracy.
     * @param _eventId The ID of the prediction event.
     * @param _prediction The agent's prediction (true or false).
     */
    function submitPrediction(uint256 _eventId, bool _prediction) public payable whenNotPaused {
        require(agents[msg.sender].isRegistered, "VOCAIP: Only registered agents can submit predictions");
        PredictionEvent storage event_ = predictionEvents[_eventId];
        require(event_.proposer != address(0), "VOCAIP: Prediction event does not exist");
        require(event_.resolutionTime > block.timestamp, "VOCAIP: Prediction event has passed its resolution time");
        require(!event_.isResolved, "VOCAIP: Prediction event is already resolved");
        require(msg.value == PREDICTION_STAKE_AMOUNT, "VOCAIP: Incorrect prediction stake amount");
        require(event_.predictions[msg.sender].stake == 0, "VOCAIP: Already submitted a prediction for this event");

        event_.predictions[msg.sender] = AgentPrediction({
            prediction: _prediction,
            stake: msg.value,
            timestamp: block.timestamp,
            endorsedAgent: address(0) // No endorsement initially
        });
        event_.totalStakedForEvent += msg.value;

        emit PredictionSubmitted(_eventId, msg.sender, _prediction);
    }

    /**
     * @dev Agents can endorse another agent's prediction for a specific event, adding reputational weight to it.
     *      This does not transfer stake, but influences future wisdom score changes for the endorser
     *      if the endorsed prediction is accurate.
     * @param _eventId The ID of the prediction event.
     * @param _agentAddress The address of the agent whose prediction is being endorsed.
     */
    function endorsePrediction(uint256 _eventId, address _agentAddress) public whenNotPaused {
        require(agents[msg.sender].isRegistered, "VOCAIP: Only registered agents can endorse predictions");
        PredictionEvent storage event_ = predictionEvents[_eventId];
        require(event_.proposer != address(0), "VOCAIP: Prediction event does not exist");
        require(event_.resolutionTime > block.timestamp, "VOCAIP: Prediction event has passed its resolution time");
        require(!event_.isResolved, "VOCAIP: Prediction event is already resolved");
        require(msg.sender != _agentAddress, "VOCAIP: Cannot endorse your own prediction");
        require(event_.predictions[_agentAddress].stake > 0, "VOCAIP: Endorsed agent has no prediction for this event");
        require(event_.predictions[msg.sender].stake > 0, "VOCAIP: You must submit a prediction before endorsing");
        require(event_.predictions[msg.sender].endorsedAgent == address(0), "VOCAIP: Already endorsed a prediction for this event");
        
        event_.predictions[msg.sender].endorsedAgent = _agentAddress;

        emit PredictionEndorsed(_eventId, msg.sender, _agentAddress);
    }

    /**
     * @dev Owner/Oracle determines and sets the final outcome of a prediction event.
     *      Triggers reputation updates for all participating agents based on accuracy.
     *      NOTE: Iterating through all potential agents to update scores for a prediction event
     *      is highly inefficient and can lead to gas limit issues for large numbers of participants.
     *      In a production environment, this would be handled via a pull-based reward system where
     *      each participant claims their reward/score update, or through off-chain computation
     *      with cryptographic proofs. This implementation serves for demonstration.
     * @param _eventId The ID of the prediction event.
     * @param _outcome The determined outcome (TRUE or FALSE).
     */
    function resolvePredictionEventOutcome(uint256 _eventId, bool _outcome) public onlyOwner whenNotPaused {
        PredictionEvent storage event_ = predictionEvents[_eventId];
        require(event_.proposer != address(0), "VOCAIP: Prediction event does not exist");
        require(!event_.isResolved, "VOCAIP: Prediction event is already resolved");
        require(block.timestamp >= event_.resolutionTime, "VOCAIP: Resolution time has not yet passed");

        event_.outcome = _outcome ? Outcome.TRUE : Outcome.FALSE;
        event_.isResolved = true;

        // Simplified logic for wisdom score updates.
        // Assumes _nextAgentNFTId.current() can represent max agents (inefficient)
        // In reality, you'd iterate over specific prediction `keys` or use a different data model.
        for (uint256 i = 0; i < _nextAgentNFTId.current(); i++) {
            // This loop attempts to get owner by tokenId, which is not efficient for general iteration.
            // A more suitable approach would be to track all participants of an event in a dynamic array
            // or allow individuals to claim rewards/score updates post-resolution.
            address currentAgentAddress = vocaipAgentNFT.ownerOf(i); // This itself is costly and only for minted NFTs.

            AgentPrediction storage agentPred = event_.predictions[currentAgentAddress];
            if (agentPred.stake > 0) { // Check if this agent actually made a prediction for this event
                if ((agentPred.prediction && _outcome) || (!agentPred.prediction && !_outcome)) {
                    _updateAgentWisdomScore(currentAgentAddress, 10); // Reward for correct prediction
                } else {
                    _updateAgentWisdomScore(currentAgentAddress, -5); // Penalty for incorrect prediction
                }

                if (agentPred.endorsedAgent != address(0)) {
                    // Check if the endorsed prediction was correct
                    AgentPrediction storage endorsedPred = event_.predictions[agentPred.endorsedAgent];
                    if (endorsedPred.stake > 0 && ((endorsedPred.prediction && _outcome) || (!endorsedPred.prediction && !_outcome))) {
                         _updateAgentWisdomScore(currentAgentAddress, 2); // Small bonus for endorsing correctly
                    } else {
                         _updateAgentWisdomScore(currentAgentAddress, -1); // Small penalty for endorsing incorrectly
                    }
                }
            }
        }

        emit PredictionEventResolved(_eventId, event_.outcome);
    }

    /**
     * @dev Retrieves all details of a specific prediction event.
     * @param _eventId The ID of the prediction event.
     * @return proposer The address who proposed the event.
     * @return question The question asked for the prediction.
     * @return resolutionTime The timestamp when the event should be resolved.
     * @return outcome The resolved outcome (UNDETERMINED, TRUE, or FALSE).
     * @return isResolved True if the event has been resolved, false otherwise.
     * @return totalStakedForEvent The total ETH staked in predictions for this event.
     */
    function getPredictionEventDetails(uint256 _eventId) public view returns (
        address proposer, string memory question, uint256 resolutionTime,
        Outcome outcome, bool isResolved, uint256 totalStakedForEvent
    ) {
        PredictionEvent storage event_ = predictionEvents[_eventId];
        require(event_.proposer != address(0), "VOCAIP: Prediction event does not exist");
        return (
            event_.proposer,
            event_.question,
            event_.resolutionTime,
            event_.outcome,
            event_.isResolved,
            event_.totalStakedForEvent
        );
    }

    /**
     * @dev Retrieves an agent's submitted prediction for a given event.
     * @param _eventId The ID of the prediction event.
     * @param _agentAddress The address of the agent.
     * @return prediction The agent's prediction (true/false).
     * @return stake The stake submitted with the prediction.
     * @return timestamp When the prediction was submitted.
     * @return endorsedAgent The address of the agent whose prediction was endorsed (address(0) if none).
     */
    function getAgentPredictionForEvent(uint256 _eventId, address _agentAddress) public view returns (
        bool prediction, uint256 stake, uint256 timestamp, address endorsedAgent
    ) {
        PredictionEvent storage event_ = predictionEvents[_eventId];
        require(event_.proposer != address(0), "VOCAIP: Prediction event does not exist");
        require(event_.predictions[_agentAddress].stake > 0, "VOCAIP: Agent has no prediction for this event");

        AgentPrediction storage agentPred = event_.predictions[_agentAddress];
        return (
            agentPred.prediction,
            agentPred.stake,
            agentPred.timestamp,
            agentPred.endorsedAgent
        );
    }

    // --- V. Reputation & Dynamic NFTs ---

    /**
     * @dev Returns the current non-transferable Wisdom Score of a specific agent.
     * @param _agentAddress The address of the agent.
     * @return The agent's Wisdom Score.
     */
    function getAgentWisdomScore(address _agentAddress) public view returns (uint256) {
        require(agents[_agentAddress].hasMintedNFT, "VOCAIP: Agent not found or has no NFT");
        return agents[_agentAddress].wisdomScore;
    }

    /**
     * @dev Returns the unique token ID of an agent's dynamic profile NFT.
     * @param _agentAddress The address of the agent.
     * @return The NFT token ID.
     */
    function getAgentProfileNFTTokenId(address _agentAddress) public view returns (uint256) {
        require(agents[_agentAddress].hasMintedNFT, "VOCAIP: Agent not found or has no NFT");
        return agents[_agentAddress].nftTokenId;
    }

    /**
     * @dev Public function to get the metadata URI for a given NFT token ID.
     *      This function is part of the ERC721 metadata standard, delegated to the VOCAIPAgentNFT contract.
     * @param _tokenId The ID of the NFT token.
     * @return The URI pointing to the metadata JSON.
     */
    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
        return vocaipAgentNFT.tokenURI(_tokenId);
    }

    /**
     * @dev Internal function to adjust an agent's Wisdom Score and trigger NFT metadata updates.
     * @param _agent The address of the agent whose score is being updated.
     * @param _delta The amount to add or subtract from the score (can be negative).
     */
    function _updateAgentWisdomScore(address _agent, int256 _delta) internal {
        if (!agents[_agent].hasMintedNFT) {
            // Should ideally not happen if logic is followed, but as a safeguard.
            return; 
        }

        uint256 currentScore = agents[_agent].wisdomScore;
        uint256 newScore;

        if (_delta >= 0) {
            newScore = currentScore + uint256(_delta);
        } else {
            // Prevent score from going below 0. Or a defined minimum (e.g., 10 for active agents).
            newScore = currentScore > uint256(-_delta) ? currentScore - uint256(-_delta) : 0;
        }

        agents[_agent].wisdomScore = newScore;
        emit WisdomScoreUpdated(_agent, newScore, _delta);

        _updateAgentProfileNFT(_agent, newScore); // Update NFT appearance based on new score
    }

    /**
     * @dev Internal function to update the metadata URI of an agent's dynamic NFT based on their new Wisdom Score.
     *      This generates a base64 encoded JSON string directly on-chain, representing the NFT's metadata.
     *      For more complex dynamic NFTs with images, this would typically involve an off-chain API
     *      or IPFS hashes to dynamic images that are updated by a backend service.
     * @param _agent The address of the agent whose NFT is being updated.
     * @param _newScore The agent's new Wisdom Score.
     */
    function _updateAgentProfileNFT(address _agent, uint256 _newScore) internal {
        uint256 tokenId = agents[_agent].nftTokenId;

        // Determine a 'tier' or visual representation based on score
        string memory tier;
        string memory description;
        if (_newScore < 50) {
            tier = "Novice Analyst";
            description = "An agent just starting their journey in collective intelligence.";
        } else if (_newScore < 200) {
            tier = "Emerging Contributor";
            description = "A promising agent gaining traction and making valuable inputs.";
        } else if (_newScore < 500) {
            tier = "Seasoned Forecaster";
            description = "An experienced agent with a proven track record of accurate insights.";
        } else {
            tier = "VOCAIP Luminary";
            description = "A highly respected and influential agent, a pillar of the network's intelligence.";
        }

        // Generate dynamic JSON metadata directly in Solidity
        // The `image` field would ideally point to a dynamically generated image hosted on IPFS or a CDN.
        // For this example, it's a placeholder.
        string memory json = string(abi.encodePacked(
            '{"name": "VOCAIP Agent #', tokenId.toString(),
            '", "description": "', description,
            '", "image": "ipfs://QmbQ4M2N...YourDynamicImageBaseForWisdomScore', // Placeholder
            '", "attributes": [',
                '{"trait_type": "Wisdom Score", "value": ', _newScore.toString(), '},',
                '{"trait_type": "Agent Tier", "value": "', tier, '"}',
            ']}'
        ));

        // Encode JSON to Base64 for data URI
        string memory base64Json = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        vocaipAgentNFT.updateTokenURI(tokenId, base64Json); // Call NFT contract to update URI
        emit AgentProfileNFTUpdated(tokenId, _agent, base64Json);
    }

    // --- VI. Utility & Admin ---

    /**
     * @dev Owner can withdraw accumulated protocol fees.
     *      (Note: In this conceptual version, specific fees are not explicitly tracked
     *      or collected in a dedicated variable. Prediction stakes are either returned
     *      to correct predictors or conceptually 'lost' to the protocol if wrong.
     *      This function would withdraw any ETH balance in the contract that is not
     *      currently held as an active agent stake or prediction stake.)
     *      Due to mapping iteration limitations, we cannot precisely calculate liquid fees.
     *      This function is simplified to transfer full balance to owner, assuming careful management.
     */
    function withdrawProtocolFees() public onlyOwner {
        // In a more complex system, `totalStakedAmount` and `totalPredictionStakedAmount`
        // would be tracked to ensure only true "fees" are withdrawn.
        // For simplicity and to avoid inefficient loops over mappings, this function
        // withdraws the contract's entire balance. Deployers must ensure this is safe.
        uint256 balance = address(this).balance;
        require(balance > 0, "VOCAIP: No withdrawable fees or balance");
        payable(owner()).transfer(balance);
    }
}

// Helper library for Base64 encoding. Provided by OpenZeppelin Contracts.
// Used for encoding NFT metadata JSON into a data URI.
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length required
        // data length -> base64 length
        // 0 -> 0
        // 1 -> 4
        // 2 -> 4
        // 3 -> 4
        // 4 -> 8
        // 5 -> 8
        // 6 -> 8
        // ...
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // allocate output
        bytes memory result = new bytes(encodedLen);

        // set pointers
        uint256 dataPtr = 0;
        uint256 resultPtr = 0;

        // encode 3 bytes at a time into 4 output bytes
        for (; dataPtr < data.length - 2; dataPtr += 3) {
            result[resultPtr++] = bytes1(table[uint8(data[dataPtr] >> 2)]);
            result[resultPtr++] = bytes1(table[uint8(((data[dataPtr] & 0x03) << 4) | (data[dataPtr + 1] >> 4))]);
            result[resultPtr++] = bytes1(table[uint8(((data[dataPtr + 1] & 0x0f) << 2) | (data[dataPtr + 2] >> 6))]);
            result[resultPtr++] = bytes1(table[uint8(data[dataPtr + 2] & 0x3f)]);
        }

        // handle padding
        if (dataPtr == data.length - 2) {
            result[resultPtr++] = bytes1(table[uint8(data[dataPtr] >> 2)]);
            result[resultPtr++] = bytes1(table[uint8(((data[dataPtr] & 0x03) << 4) | (data[dataPtr + 1] >> 4))]);
            result[resultPtr++] = bytes1(table[uint8((data[dataPtr + 1] & 0x0f) << 2)]);
            result[resultPtr++] = bytes1(0x3d); // '='
        } else if (dataPtr == data.length - 1) {
            result[resultPtr++] = bytes1(table[uint8(data[dataPtr] >> 2)]);
            result[resultPtr++] = bytes1(table[uint8((data[dataPtr] & 0x03) << 4)]);
            result[resultPtr++] = bytes1(0x3d); // '='
            result[resultPtr++] = bytes1(0x3d); // '='
        }

        return string(result);
    }
}
```