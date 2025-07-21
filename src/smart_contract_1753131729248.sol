Here's a Solidity smart contract that implements an "Aetherial Nexus Protocol," combining concepts of dynamic Soulbound NFTs, a simulated Adaptive Intelligence Core, a commit-reveal insight system, and a hybrid governance model. It aims for creativity, advanced concepts, and trending features without directly duplicating existing open-source projects in its specific combination of mechanics.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Aetherial Nexus Protocol (ANP)
 * @author AI Assistant
 * @notice A decentralized protocol designed to harness collective intelligence and foster a reputation-driven ecosystem.
 * Users contribute "insights" (predictions/data), which are validated against revealed truths.
 * The protocol features a simulated "Adaptive Intelligence Core" (AIC) that processes these insights,
 * updates user reputation, and dynamically adjusts protocol parameters. Participation is anchored by "AetherSpheres,"
 * unique Soulbound NFTs that evolve based on a user's accuracy and contributions.
 */

/*
--- Outline ---

I. Core Infrastructure & Tokenomics
    - Basic setup and linking of dependent contracts (ANP Token, AetherSphere NFT).
    - Treasury management for protocol fees.

II. AetherSphere (Dynamic Soulbound NFT) Management
    - Minting and retrieval of AetherSphere NFTs.
    - Functions to read and internally update AetherSphere attributes (level, accuracy).

III. Insight Contribution & Validation
    - Commit-reveal scheme for submitting user insights.
    - Mechanism for an oracle/governor to reveal the 'truth' for a topic.
    - Triggering the validation process for submitted insights.
    - Claiming rewards based on insight accuracy.

IV. Adaptive Intelligence Core (AIC) & Parameter Governance
    - The core logic for evaluating insights against truth, updating user metrics, and distributing rewards/penalties.
    - A decentralized governance module for proposing and voting on changes to AIC parameters, with votes weighted by AetherSphere level.

V. Reputation & Trust Metrics
    - Derived functions to query user-specific and NFT-specific accuracy and rank, reflecting their standing in the network.

*/

/*
--- Function Summary ---

I. Core Infrastructure & Tokenomics
1. `constructor(uint256 _anpInitialSupply, address _initialGovernor)`: Initializes the contract, deploying the ANP token and AetherSphere NFT, setting up initial parameters and the first governor.
2. `setAetherSphereNFTAddress(address _address)`: Admin function to link the deployed AetherSphere NFT contract (if deployed separately).
3. `tokenAddress()`: Returns the address of the ANP utility token.
4. `getProtocolTreasury()`: Returns the address designated for collecting protocol fees.
5. `withdrawProtocolFees(address _to, uint256 _amount)`: Allows authorized governors to withdraw accumulated protocol fees from the treasury to a specified address.

II. AetherSphere (Dynamic Soulbound NFT) Management
6. `mintAetherSphere()`: Mints a unique, non-transferable AetherSphere NFT for the calling user if they do not already possess one.
7. `getAetherSphereId(address _user)`: Retrieves the AetherSphere NFT ID associated with a given user address.
8. `getAetherSphereAttributes(uint256 _tokenId)`: Returns a tuple of dynamic attributes (e.g., current level, cumulative accuracy score, total insights contributed) for a specific AetherSphere NFT.
9. `updateAetherSphereAttributes(uint256 _tokenId, uint256 _newAccuracyScore, uint256 _newLevel, uint256 _newTotalInsights)`: Internal function, primarily called by `processInsightValidation`, to dynamically update an AetherSphere NFT's attributes based on user activity and performance.
10. `getAetherSphereLevel(uint256 _tokenId)`: Returns the current evolutionary level of a specific AetherSphere NFT.

III. Insight Contribution & Validation
11. `submitInsight(bytes32 _insightHash, uint256 _stakeAmount, uint256 _topicId)`: Allows users to commit a hashed version of their insight for a specific topic, along with a staked amount of ANP tokens. Requires the user to own an AetherSphere.
12. `revealInsight(uint256 _insightId, string calldata _insightData)`: Allows a user to reveal the plaintext content of their previously committed insight after a specified commitment period has passed.
13. `requestInsightValidation(uint256 _insightId)`: Anyone can call this function to trigger the validation process for a revealed insight, initiating the AIC's evaluation.
14. `submitTruthHash(uint256 _topicId, bytes32 _truthHash)`: An authorized oracle/governor submits a hash of the definitive "truth" for a specific topic, initiating a truth revelation period.
15. `revealTruth(uint256 _topicId, string calldata _truthData)`: An authorized oracle/governor reveals the actual plaintext "truth" data for a topic after its hash was committed and within the reveal period.
16. `claimInsightReward(uint256 _insightId)`: Allows a user to claim their staked tokens back, plus any earned rewards, if their insight was validated as accurate; penalizes for inaccuracy.

IV. Adaptive Intelligence Core (AIC) & Parameter Governance
17. `processInsightValidation(uint256 _insightId, string calldata _revealedTruth)`: The core internal function, executed when `requestInsightValidation` is called. It compares the revealed insight data with the revealed truth, calculates accuracy, updates the user's AetherSphere attributes, and handles reward/penalty distribution. This embodies the "AI" logic.
18. `getInsightAccuracyScore(uint256 _insightId)`: Retrieves the calculated accuracy score for a specific validated insight.
19. `getAICParameter(bytes32 _paramName)`: Allows viewing the current value of a specific configurable AIC parameter (e.g., `rewardMultiplier`, `levelUpThreshold`).
20. `proposeAICParameterChange(bytes32 _paramName, uint256 _newValue, uint256 _voteDuration)`: Initiates a governance proposal to modify a key parameter of the Adaptive Intelligence Core.
21. `voteOnAICParameterChange(uint256 _proposalId, bool _support)`: Allows AetherSphere holders to vote on active parameter change proposals. Voting power is weighted by their AetherSphere's current level.
22. `executeAICParameterChange(uint256 _proposalId)`: Executes a passed governance proposal, updating the AIC parameter.

V. Reputation & Trust Metrics
23. `getUserTotalAccuracyScore(address _user)`: Returns the cumulative accuracy score across all validated insights submitted by a user.
24. `getAetherSphereRank(uint256 _tokenId)`: Calculates a dynamic rank for an AetherSphere based on its level, accuracy score, and total insights, reflecting its standing in the network.

VI. Governance Utility Functions
25. `addGovernor(address _newGovernor)`: Allows the contract owner to add a new governor.
26. `removeGovernor(address _governorToRemove)`: Allows the contract owner to remove an existing governor.
27. `setProtocolTreasury(address _newTreasury)`: Allows the contract owner to change the address designated for collecting protocol fees.

*/

// --- Dependent Contracts (Simplified for Self-Containment) ---

/**
 * @dev Simple ANP ERC20 Token.
 * This is a basic implementation for demonstration purposes.
 */
contract ANPToken is ERC20, Ownable {
    constructor(uint256 initialSupply, address owner) ERC20("Aether Nexus Token", "ANP") Ownable(owner) {
        _mint(owner, initialSupply);
    }

    /**
     * @dev Mints new tokens to a specified address. Only callable by the owner (AetherialNexusProtocol).
     * In a real system, minting might be tied to specific protocol functions like staking rewards.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from a specified address. Only callable by the owner (AetherialNexusProtocol).
     * Used for penalties or controlled supply reduction.
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}

/**
 * @dev AetherSphere NFT: A Soulbound Token (SBT) representing a user's identity and reputation.
 * Its attributes dynamically evolve based on user's contributions in the Aetherial Nexus Protocol.
 */
contract AetherSphereNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Struct to hold dynamic attributes for each AetherSphere NFT
    struct AetherSphereAttributes {
        uint256 level;              // Evolution level of the AetherSphere
        uint256 accuracyScore;      // Cumulative accuracy score from insights (e.g., 0-10000)
        uint256 totalInsights;      // Total insights contributed
        uint256 lastUpdated;        // Timestamp of last attribute update
    }

    // Mapping from tokenId to its dynamic attributes
    mapping(uint256 => AetherSphereAttributes) public sphereAttributes;
    // Mapping from user address to their AetherSphere tokenId (Soulbound property)
    mapping(address => uint256) public userAetherSphere;
    // Mapping to track if a user has an AetherSphere for quick lookup
    mapping(address => bool) public hasAetherSphere;

    event AetherSphereMinted(address indexed owner, uint256 indexed tokenId);
    event AetherSphereAttributesUpdated(uint256 indexed tokenId, uint256 newAccuracyScore, uint256 newLevel, uint256 newTotalInsights);

    constructor(address owner) ERC721("AetherSphere", "ASPHR") Ownable(owner) {}

    /**
     * @dev Mints a new AetherSphere NFT for the specified address.
     * Only callable by the AetherialNexusProtocol contract (its owner).
     * This is a Soulbound Token, meaning it cannot be transferred after minting.
     * @param _to The address to mint the AetherSphere for.
     * @return The tokenId of the newly minted AetherSphere.
     */
    function mintSphere(address _to) public onlyOwner returns (uint256) {
        require(!hasAetherSphere[_to], "AetherSphereNFT: User already has an AetherSphere");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(_to, newTokenId);

        // Initialize default attributes for a new AetherSphere
        sphereAttributes[newTokenId] = AetherSphereAttributes({
            level: 1,               // Starts at level 1
            accuracyScore: 0,
            totalInsights: 0,
            lastUpdated: block.timestamp
        });
        userAetherSphere[_to] = newTokenId;
        hasAetherSphere[_to] = true;

        emit AetherSphereMinted(_to, newTokenId);
        return newTokenId;
    }

    /**
     * @dev Updates the dynamic attributes of an AetherSphere.
     * Only callable by the AetherialNexusProtocol contract (its owner).
     * @param _tokenId The ID of the AetherSphere NFT to update.
     * @param _newAccuracyScore The new cumulative accuracy score.
     * @param _newLevel The new evolution level.
     * @param _newTotalInsights The new total insights count.
     */
    function updateAttributes(uint256 _tokenId, uint256 _newAccuracyScore, uint256 _newLevel, uint256 _newTotalInsights) public onlyOwner {
        require(_exists(_tokenId), "AetherSphereNFT: Token does not exist");
        AetherSphereAttributes storage attrs = sphereAttributes[_tokenId];
        attrs.accuracyScore = _newAccuracyScore;
        attrs.level = _newLevel;
        attrs.totalInsights = _newTotalInsights;
        attrs.lastUpdated = block.timestamp;

        emit AetherSphereAttributesUpdated(_tokenId, _newAccuracyScore, _newLevel, _newTotalInsights);
    }

    /**
     * @dev Prevents AetherSphere NFTs from being transferred (Soulbound property).
     * This override function ensures that no token transfers occur after the initial minting.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        // Allow initial minting (from address(0)) but prevent all other transfers
        if (from != address(0) && to != address(0)) {
            revert("AetherSphereNFT: Soulbound tokens are non-transferable");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}


// --- Main Protocol Contract ---
contract AetherialNexusProtocol is Ownable {
    ANPToken public anpToken;
    AetherSphereNFT public aetherSphereNFT;

    address public protocolTreasury; // Address where protocol fees are collected
    address[] public governors; // Addresses authorized to reveal truth and manage certain parameters

    // --- Configuration Parameters (AIC Parameters) ---
    // These parameters can be adjusted via governance to adapt the protocol's behavior.
    mapping(bytes32 => uint256) public aicParameters; // e.g., keccak256("INSIGHT_REWARD_MULTIPLIER"), keccak256("ACCURACY_THRESHOLD_FOR_LEVELUP")

    // Default parameters (can be overridden by governance)
    uint256 public constant DEFAULT_COMMIT_PERIOD = 1 days; // Time for users to commit insight hash
    uint256 public constant DEFAULT_REVEAL_PERIOD = 3 days; // Time for users to reveal insight data & for governor to reveal truth
    uint256 public constant DEFAULT_VALIDATION_GRACE_PERIOD = 7 days; // Time to request validation after truth reveal
    uint256 public constant DEFAULT_MIN_STAKE_AMOUNT = 100 * 10**18; // Minimum 100 ANP to stake (assuming 18 decimals)
    uint256 public constant DEFAULT_REWARD_MULTIPLIER = 120; // 120% of stake back for correct insight (100% stake + 20% reward)
    uint256 public constant DEFAULT_PENALTY_MULTIPLIER = 50; // 50% penalty for incorrect insight (50% of stake returned)
    uint256 public constant DEFAULT_ACCURACY_SCORE_INCREMENT = 100; // Points added to accuracy for a correct insight
    uint256 public constant DEFAULT_ACCURACY_SCORE_DECREMENT = 50;  // Points deducted for an incorrect insight
    uint256 public constant DEFAULT_LEVEL_UP_ACCURACY_THRESHOLD = 500; // Cumulative accuracy score needed to level up AetherSphere
    uint256 public constant DEFAULT_PROTOCOL_FEE_BPS = 500; // 5% (500 basis points) of rewards goes to treasury

    // --- Insight Management ---
    using Counters for Counters.Counter;
    Counters.Counter private _insightIdCounter;

    // Enum to track the lifecycle of an insight
    enum InsightStatus {
        Committed,          // Insight hash submitted
        Revealed,           // Insight data revealed by user
        TruthHashSubmitted, // Truth hash submitted by governor
        TruthRevealed,      // Truth data revealed by governor
        Validated,          // Insight evaluated against truth
        Claimed,            // Rewards/penalties claimed
        Expired             // Insight expired without being revealed/validated
    }

    // Struct to store details of each submitted insight
    struct Insight {
        uint256 id;
        address contributor;
        uint256 topicId;
        bytes32 insightHash;
        string insightData; // Revealed data
        uint256 stakeAmount;
        uint256 commitTimestamp;
        uint256 revealDeadline;
        uint256 validationDeadline; // Deadline by which validation must be requested
        InsightStatus status;
        bool isAccurate; // Result of validation
        int256 accuracyScoreObtained; // Change in accuracy score from this insight (-ve for incorrect)
    }

    mapping(uint256 => Insight) public insights;
    mapping(address => uint256[]) public userInsights; // List of insight IDs per user
    mapping(uint256 => uint256) public topicTruthHashSubmitTime; // Tracks when truth hash was submitted for a topic
    mapping(uint256 => bytes32) public topicTruthHashes; // Hashed truth for topics
    mapping(uint256 => string) public topicTruthData;   // Revealed truth for topics

    // --- Governance ---
    using Counters for Counters.Counter;
    Counters.Counter private _proposalIdCounter;

    // Enum to track the status of governance proposals
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    // Struct to store details of each governance proposal
    struct GovernanceProposal {
        uint256 id;
        bytes32 paramName;      // Hashed name of the parameter to change
        uint256 newValue;       // New value proposed
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this specific proposal
    }

    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Events ---
    event AetherSphereNFTAddressSet(address indexed _address);
    event ProtocolTreasurySet(address indexed _address);
    event GovernorAdded(address indexed governor);
    event GovernorRemoved(address indexed governor);
    event InsightSubmitted(uint256 indexed insightId, address indexed contributor, uint256 topicId, uint256 stakeAmount);
    event InsightRevealed(uint256 indexed insightId, string insightData);
    event TruthHashSubmitted(uint256 indexed topicId, bytes32 truthHash);
    event TruthRevealed(uint256 indexed topicId, string truthData);
    event InsightValidated(uint256 indexed insightId, bool isAccurate, int256 accuracyScoreObtained);
    event InsightClaimed(uint256 indexed insightId, address indexed claimant, uint256 claimedAmount);
    event AICParameterProposed(uint256 indexed proposalId, bytes32 paramName, uint256 newValue, uint256 voteEndTime);
    event AICParameterVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event AICParameterExecuted(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);

    // --- Modifiers ---
    /**
     * @dev Throws if the caller does not own an AetherSphere NFT.
     */
    modifier onlyAetherSphereOwner(address _user) {
        require(aetherSphereNFT.hasAetherSphere(_user), "ANP: Caller must own an AetherSphere NFT");
        _;
    }

    /**
     * @dev Throws if the caller is not a registered governor or the contract owner.
     */
    modifier onlyGovernor() {
        bool isGovernor = false;
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _msgSender()) {
                isGovernor = true;
                break;
            }
        }
        require(isGovernor || owner() == _msgSender(), "ANP: Caller is not a governor or contract owner");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the Aetherial Nexus Protocol, deploys its ERC20 token and Soulbound NFT,
     * and sets initial configurable parameters.
     * @param _anpInitialSupply The initial total supply for the ANP utility token.
     * @param _initialGovernor The address of the first authorized governor for truth revelation and proposals.
     */
    constructor(uint256 _anpInitialSupply, address _initialGovernor) Ownable(_msgSender()) {
        // Deploy ANPToken and AetherSphereNFT internally for a self-contained example
        anpToken = new ANPToken(_anpInitialSupply, address(this)); // ANPToken's owner is this contract
        aetherSphereNFT = new AetherSphereNFT(address(this)); // AetherSphereNFT's owner is this contract

        protocolTreasury = address(this); // Default treasury to this contract, can be changed.

        // Initialize default Adaptive Intelligence Core (AIC) parameters
        aicParameters[keccak256("COMMIT_PERIOD")] = DEFAULT_COMMIT_PERIOD;
        aicParameters[keccak256("REVEAL_PERIOD")] = DEFAULT_REVEAL_PERIOD;
        aicParameters[keccak256("VALIDATION_GRACE_PERIOD")] = DEFAULT_VALIDATION_GRACE_PERIOD;
        aicParameters[keccak256("MIN_STAKE_AMOUNT")] = DEFAULT_MIN_STAKE_AMOUNT;
        aicParameters[keccak256("REWARD_MULTIPLIER")] = DEFAULT_REWARD_MULTIPLIER;
    
        // Penalty is calculated as a fraction of initial stake that is returned. (100-penalty_multiplier)% is taken away
        aicParameters[keccak256("PENALTY_MULTIPLIER")] = DEFAULT_PENALTY_MULTIPLIER; 

        aicParameters[keccak256("ACCURACY_SCORE_INCREMENT")] = DEFAULT_ACCURACY_SCORE_INCREMENT;
        aicParameters[keccak256("ACCURACY_SCORE_DECREMENT")] = DEFAULT_ACCURACY_SCORE_DECREMENT;
        aicParameters[keccak256("LEVEL_UP_ACCURACY_THRESHOLD")] = DEFAULT_LEVEL_UP_ACCURACY_THRESHOLD;
        aicParameters[keccak256("PROTOCOL_FEE_BPS")] = DEFAULT_PROTOCOL_FEE_BPS;

        // Add initial governor
        require(_initialGovernor != address(0), "ANP: Initial governor cannot be zero address");
        governors.push(_initialGovernor);
        emit GovernorAdded(_initialGovernor);
    }

    // I. Core Infrastructure & Tokenomics

    /**
     * @notice Admin function to link the deployed AetherSphere NFT contract.
     * This is useful if the NFT contract is deployed separately or needs to be swapped.
     * @param _address The address of the AetherSphere NFT contract.
     */
    function setAetherSphereNFTAddress(address _address) external onlyOwner {
        require(_address != address(0), "ANP: Zero address not allowed for AetherSphere NFT");
        aetherSphereNFT = AetherSphereNFT(_address);
        // Transfer ownership of the NFT contract to this protocol, if not already done
        if (aetherSphereNFT.owner() != address(this)) {
            aetherSphereNFT.transferOwnership(address(this));
        }
        emit AetherSphereNFTAddressSet(_address);
    }

    /**
     * @notice Returns the address of the ANP utility token used by the protocol.
     */
    function tokenAddress() external view returns (address) {
        return address(anpToken);
    }

    /**
     * @notice Returns the address designated for collecting protocol fees.
     */
    function getProtocolTreasury() external view returns (address) {
        return protocolTreasury;
    }

    /**
     * @notice Allows authorized governors to withdraw accumulated protocol fees from the treasury.
     * @param _to The address to send the withdrawn fees.
     * @param _amount The amount of ANP tokens to withdraw.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) external onlyGovernor {
        require(_to != address(0), "ANP: Cannot withdraw to zero address");
        require(_amount > 0, "ANP: Withdraw amount must be positive");
        require(anpToken.balanceOf(address(this)) >= _amount, "ANP: Insufficient balance in treasury");
        anpToken.transfer(_to, _amount);
    }

    // II. AetherSphere (Dynamic Soulbound NFT) Management

    /**
     * @notice Mints a unique, non-transferable AetherSphere NFT for the calling user if they do not already possess one.
     * This is the entry point for users to participate in the protocol's reputation system.
     */
    function mintAetherSphere() external {
        aetherSphereNFT.mintSphere(_msgSender());
    }

    /**
     * @notice Retrieves the AetherSphere NFT ID associated with a given user address.
     * @param _user The address of the user.
     * @return The tokenId of the user's AetherSphere. Returns 0 if no AetherSphere is found for the user.
     */
    function getAetherSphereId(address _user) external view returns (uint256) {
        return aetherSphereNFT.userAetherSphere(_user);
    }

    /**
     * @notice Returns a tuple of dynamic attributes (level, cumulative accuracy score, total insights contributed)
     * for a specific AetherSphere NFT.
     * @param _tokenId The ID of the AetherSphere NFT.
     * @return level Current evolution level.
     * @return accuracyScore Cumulative accuracy score.
     * @return totalInsights Total insights contributed.
     */
    function getAetherSphereAttributes(uint256 _tokenId) external view returns (uint256 level, uint256 accuracyScore, uint256 totalInsights) {
        AetherSphereNFT.AetherSphereAttributes memory attrs = aetherSphereNFT.sphereAttributes(_tokenId);
        return (attrs.level, attrs.accuracyScore, attrs.totalInsights);
    }

    /**
     * @notice Internal function to dynamically update an AetherSphere NFT's attributes.
     * This function is primarily called by `processInsightValidation` to reflect a user's performance.
     * It's external in the AetherSphereNFT contract but called by this contract (its owner).
     * @param _tokenId The ID of the AetherSphere NFT to update.
     * @param _newAccuracyScore The new cumulative accuracy score.
     * @param _newLevel The new evolution level.
     * @param _newTotalInsights The new total insights count.
     */
    function updateAetherSphereAttributes(uint256 _tokenId, uint256 _newAccuracyScore, uint256 _newLevel, uint256 _newTotalInsights) internal {
        aetherSphereNFT.updateAttributes(_tokenId, _newAccuracyScore, _newLevel, _newTotalInsights);
    }

    /**
     * @notice Returns the current evolutionary level of a specific AetherSphere NFT.
     * @param _tokenId The ID of the AetherSphere NFT.
     * @return The level of the AetherSphere.
     */
    function getAetherSphereLevel(uint256 _tokenId) public view returns (uint256) {
        return aetherSphereNFT.sphereAttributes(_tokenId).level;
    }

    // III. Insight Contribution & Validation

    /**
     * @notice Allows users to commit a hashed version of their insight for a specific topic,
     * along with a staked amount of ANP tokens. Requires the user to own an AetherSphere.
     * Uses a commit-reveal scheme to prevent front-running of insights.
     * @param _insightHash The keccak256 hash of the user's insight data.
     * @param _stakeAmount The amount of ANP tokens to stake.
     * @param _topicId An identifier for the topic of the insight (e.g., a hash of the question).
     */
    function submitInsight(bytes32 _insightHash, uint256 _stakeAmount, uint256 _topicId) external onlyAetherSphereOwner(_msgSender()) {
        require(_stakeAmount >= aicParameters[keccak256("MIN_STAKE_AMOUNT")], "ANP: Stake amount too low");
        anpToken.transferFrom(_msgSender(), address(this), _stakeAmount); // Pull tokens from user to contract

        _insightIdCounter.increment();
        uint256 newInsightId = _insightIdCounter.current();

        insights[newInsightId] = Insight({
            id: newInsightId,
            contributor: _msgSender(),
            topicId: _topicId,
            insightHash: _insightHash,
            insightData: "", // To be filled on reveal
            stakeAmount: _stakeAmount,
            commitTimestamp: block.timestamp,
            revealDeadline: block.timestamp + aicParameters[keccak256("REVEAL_PERIOD")], // User reveals within this time
            validationDeadline: 0, // Set after truth revealed
            status: InsightStatus.Committed,
            isAccurate: false, // Default
            accuracyScoreObtained: 0 // Default
        });

        userInsights[_msgSender()].push(newInsightId);
        emit InsightSubmitted(newInsightId, _msgSender(), _topicId, _stakeAmount);
    }

    /**
     * @notice Allows a user to reveal the plaintext content of their previously committed insight
     * after a specified commitment period has passed but before the reveal deadline.
     * @param _insightId The ID of the insight to reveal.
     * @param _insightData The plaintext data of the insight.
     */
    function revealInsight(uint256 _insightId, string calldata _insightData) external {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.Committed, "ANP: Insight not in committed state");
        require(insight.contributor == _msgSender(), "ANP: Not the insight contributor");
        require(block.timestamp >= insight.commitTimestamp + aicParameters[keccak256("COMMIT_PERIOD")], "ANP: Commit period not over yet");
        require(block.timestamp <= insight.revealDeadline, "ANP: Reveal deadline passed");
        require(keccak256(abi.encodePacked(_insightData)) == insight.insightHash, "ANP: Insight data hash mismatch");

        insight.insightData = _insightData;
        insight.status = InsightStatus.Revealed;
        emit InsightRevealed(_insightId, _insightData);
    }

    /**
     * @notice Anyone can call this function to trigger the validation process for a revealed insight,
     * initiating the AIC's evaluation.
     * @param _insightId The ID of the insight to validate.
     */
    function requestInsightValidation(uint256 _insightId) external {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.Revealed, "ANP: Insight not revealed or already validated");
        require(topicTruthData[insight.topicId].length > 0, "ANP: Truth not yet revealed for this topic");
        require(insight.validationDeadline > 0, "ANP: Validation deadline not set (truth not revealed for this insight)");
        require(block.timestamp <= insight.validationDeadline, "ANP: Validation grace period expired");

        processInsightValidation(_insightId, topicTruthData[insight.topicId]);
    }

    /**
     * @notice An authorized oracle/governor submits a hash of the definitive "truth" for a specific topic,
     * initiating a truth revelation period. This is the first step of the truth commit-reveal process.
     * @param _topicId The ID of the topic.
     * @param _truthHash The keccak256 hash of the truth data.
     */
    function submitTruthHash(uint256 _topicId, bytes32 _truthHash) external onlyGovernor {
        // Allow re-submission only after previous reveal period ends
        require(topicTruthHashSubmitTime[_topicId] == 0 || block.timestamp > topicTruthHashSubmitTime[_topicId] + aicParameters[keccak256("REVEAL_PERIOD")], "ANP: Truth already committed or reveal period active for this topic");
        topicTruthHashes[_topicId] = _truthHash;
        topicTruthHashSubmitTime[_topicId] = block.timestamp;
        emit TruthHashSubmitted(_topicId, _truthHash);
    }

    /**
     * @notice An authorized oracle/governor reveals the actual plaintext "truth" data for a topic
     * after its hash was committed and within the reveal period.
     * @param _topicId The ID of the topic.
     * @param _truthData The plaintext truth data.
     */
    function revealTruth(uint256 _topicId, string calldata _truthData) external onlyGovernor {
        require(topicTruthHashSubmitTime[_topicId] != 0, "ANP: Truth hash not submitted for this topic");
        require(keccak256(abi.encodePacked(_truthData)) == topicTruthHashes[_topicId], "ANP: Truth data hash mismatch");
        require(block.timestamp >= topicTruthHashSubmitTime[_topicId], "ANP: Truth reveal period has not started");
        require(block.timestamp <= topicTruthHashSubmitTime[_topicId] + aicParameters[keccak256("REVEAL_PERIOD")], "ANP: Truth reveal period expired");

        topicTruthData[_topicId] = _truthData;

        // Set validation deadlines for all insights related to this topic that are in 'Revealed' status
        for (uint256 i = 1; i <= _insightIdCounter.current(); i++) {
            if (insights[i].topicId == _topicId && insights[i].status == InsightStatus.Revealed) {
                insights[i].validationDeadline = block.timestamp + aicParameters[keccak256("VALIDATION_GRACE_PERIOD")];
            }
        }

        emit TruthRevealed(_topicId, _truthData);
    }

    /**
     * @notice Allows a user to claim their staked tokens back, plus any earned rewards,
     * if their insight was validated as accurate; penalizes for inaccuracy.
     * @param _insightId The ID of the insight to claim rewards for.
     */
    function claimInsightReward(uint256 _insightId) external {
        Insight storage insight = insights[_insightId];
        require(insight.contributor == _msgSender(), "ANP: Not the insight contributor");
        require(insight.status == InsightStatus.Validated, "ANP: Insight not yet validated");
        require(block.timestamp <= insight.validationDeadline + 1 days, "ANP: Claim period expired (1 day grace after validation deadline)"); // Additional grace for claiming

        uint256 returnAmount = 0;
        if (insight.isAccurate) {
            returnAmount = (insight.stakeAmount * aicParameters[keccak256("REWARD_MULTIPLIER")]) / 100;
            // Deduct protocol fee from the reward portion (profit), not from the initial stake
            uint256 rewardPart = returnAmount - insight.stakeAmount;
            uint256 protocolFee = (rewardPart * aicParameters[keccak256("PROTOCOL_FEE_BPS")]) / 10000; // 10000 for basis points
            returnAmount -= protocolFee;
            anpToken.transfer(protocolTreasury, protocolFee);
        } else {
            returnAmount = (insight.stakeAmount * aicParameters[keccak256("PENALTY_MULTIPLIER")]) / 100;
            // The forfeited portion (100% - PENALTY_MULTIPLIER)% of the stake goes to the treasury
            uint256 penaltyAmount = insight.stakeAmount - returnAmount;
            anpToken.transfer(protocolTreasury, penaltyAmount);
        }

        anpToken.transfer(_msgSender(), returnAmount);
        insight.status = InsightStatus.Claimed;
        emit InsightClaimed(_insightId, _msgSender(), returnAmount);
    }

    // IV. Adaptive Intelligence Core (AIC) & Parameter Governance

    /**
     * @notice The core internal function that embodies the "AI" logic.
     * It compares the revealed insight data with the revealed truth, calculates accuracy,
     * updates the user's AetherSphere attributes, and sets the outcome for reward/penalty distribution.
     * This function is triggered by `requestInsightValidation`.
     * @param _insightId The ID of the insight to process.
     * @param _revealedTruth The plaintext truth data.
     */
    function processInsightValidation(uint256 _insightId, string calldata _revealedTruth) internal {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.Revealed, "ANP: Insight is not in revealed status.");
        require(keccak256(abi.encodePacked(_revealedTruth)) == topicTruthHashes[insight.topicId], "ANP: Provided truth data does not match committed hash.");
        require(block.timestamp <= insight.validationDeadline, "ANP: Validation deadline expired.");

        // Simple string hash comparison for accuracy. More complex logic could be here for numbers, etc.
        bool isAccurate = (keccak256(abi.encodePacked(insight.insightData)) == keccak256(abi.encodePacked(_revealedTruth)));
        insight.isAccurate = isAccurate;

        uint256 contributorTokenId = aetherSphereNFT.userAetherSphere(insight.contributor);
        AetherSphereNFT.AetherSphereAttributes storage contributorAttrs = aetherSphereNFT.sphereAttributes(contributorTokenId);

        uint256 newAccuracyScore = contributorAttrs.accuracyScore;
        uint256 newLevel = contributorAttrs.level;
        uint256 totalInsights = contributorAttrs.totalInsights + 1;

        // Adjust accuracy score based on correctness
        if (isAccurate) {
            newAccuracyScore += aicParameters[keccak256("ACCURACY_SCORE_INCREMENT")];
            insight.accuracyScoreObtained = int256(aicParameters[keccak256("ACCURACY_SCORE_INCREMENT")]);
        } else {
            if (newAccuracyScore >= aicParameters[keccak256("ACCURACY_SCORE_DECREMENT")]) {
                newAccuracyScore -= aicParameters[keccak256("ACCURACY_SCORE_DECREMENT")];
            } else {
                newAccuracyScore = 0; // Cannot go below zero
            }
            insight.accuracyScoreObtained = -int256(aicParameters[keccak256("ACCURACY_SCORE_DECREMENT")]);
        }

        // Adaptive Leveling Logic: AetherSphere levels up when cumulative accuracy reaches certain thresholds.
        // The threshold is dynamic, based on the current level and a global parameter.
        uint256 nextLevelThreshold = newLevel * aicParameters[keccak256("LEVEL_UP_ACCURACY_THRESHOLD")];
        if (newAccuracyScore >= nextLevelThreshold && newLevel < 100) { // Cap level for practical limits
            newLevel++;
        }

        updateAetherSphereAttributes(contributorTokenId, newAccuracyScore, newLevel, totalInsights);

        insight.status = InsightStatus.Validated;
        emit InsightValidated(_insightId, isAccurate, insight.accuracyScoreObtained);
    }

    /**
     * @notice Retrieves the calculated accuracy score (change) for a specific validated insight.
     * @param _insightId The ID of the insight.
     * @return The accuracy score obtained (or deducted) from this specific insight validation.
     */
    function getInsightAccuracyScore(uint256 _insightId) external view returns (int256) {
        return insights[_insightId].accuracyScoreObtained;
    }

    /**
     * @notice Allows viewing the current value of a specific configurable AIC parameter.
     * These parameters control the protocol's core behaviors and can be adjusted by governance.
     * @param _paramName The keccak256 hash of the parameter name (e.g., keccak256("REWARD_MULTIPLIER")).
     * @return The current value of the parameter.
     */
    function getAICParameter(bytes32 _paramName) external view returns (uint256) {
        return aicParameters[_paramName];
    }

    /**
     * @notice Initiates a governance proposal to modify a key parameter of the Adaptive Intelligence Core.
     * Only callable by governors or the contract owner.
     * @param _paramName The keccak256 hash of the parameter name to change.
     * @param _newValue The new value proposed for the parameter.
     * @param _voteDuration The duration in seconds for which the vote will be active.
     */
    function proposeAICParameterChange(bytes32 _paramName, uint256 _newValue, uint256 _voteDuration) external onlyGovernor {
        require(_voteDuration > 0, "ANP: Vote duration must be positive");
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            paramName: _paramName,
            newValue: _newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + _voteDuration,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool) // Initialize the nested mapping
        });

        emit AICParameterProposed(newProposalId, _paramName, _newValue, block.timestamp + _voteDuration);
    }

    /**
     * @notice Allows AetherSphere holders to vote on active parameter change proposals.
     * Voting power is weighted by their AetherSphere's current level. Higher levels grant more voting power.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnAICParameterChange(uint256 _proposalId, bool _support) external onlyAetherSphereOwner(_msgSender()) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "ANP: Proposal not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "ANP: Voting period is not active");
        require(!proposal.hasVoted[_msgSender()], "ANP: Already voted on this proposal");

        uint256 voterTokenId = aetherSphereNFT.userAetherSphere(_msgSender());
        uint256 voteWeight = aetherSphereNFT.getAetherSphereAttributes(voterTokenId).level; // Voting power directly from AetherSphere level
        require(voteWeight > 0, "ANP: AetherSphere must have a level > 0 to vote");

        if (_support) {
            proposal.totalVotesFor += voteWeight;
        } else {
            proposal.totalVotesAgainst += voteWeight;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit AICParameterVoted(_proposalId, _msgSender(), _support, voteWeight);
    }

    /**
     * @notice Executes a passed governance proposal, updating the AIC parameter.
     * Can be called by anyone after the voting period ends, if the proposal has enough 'for' votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeAICParameterChange(uint256 _proposalId) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "ANP: Proposal not active");
        require(block.timestamp > proposal.voteEndTime, "ANP: Voting period not over yet");

        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            aicParameters[proposal.paramName] = proposal.newValue;
            proposal.status = ProposalStatus.Executed;
            emit AICParameterExecuted(proposal.id, proposal.paramName, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    // V. Reputation & Trust Metrics

    /**
     * @notice Returns the cumulative accuracy score across all validated insights submitted by a user.
     * This score contributes to the evolution of their AetherSphere.
     * @param _user The address of the user.
     * @return The total accuracy score. Returns 0 if the user does not have an AetherSphere.
     */
    function getUserTotalAccuracyScore(address _user) external view returns (uint256) {
        uint256 tokenId = aetherSphereNFT.userAetherSphere(_user);
        if (tokenId == 0) return 0; // User does not have an AetherSphere
        return aetherSphereNFT.sphereAttributes(tokenId).accuracyScore;
    }

    /**
     * @notice Calculates a dynamic rank for an AetherSphere based on its level, accuracy score,
     * and total insights, reflecting its standing in the network.
     * @dev This is a simplified ranking function. Real-world systems might use more complex algorithms
     * or off-chain computation for more robust ranking.
     * @param _tokenId The ID of the AetherSphere NFT.
     * @return A calculated rank score. Higher is generally better. Returns 0 for non-existent or uninitialized AetherSpheres.
     */
    function getAetherSphereRank(uint256 _tokenId) external view returns (uint256) {
        AetherSphereNFT.AetherSphereAttributes memory attrs = aetherSphereNFT.sphereAttributes(_tokenId);
        if (attrs.level == 0) return 0; // AetherSphere not initialized or non-existent

        // Example rank formula: Level * (Accuracy Score + 1) / (Total Insights + 1)
        // Adding 1 to avoid division by zero and give initial value to new participants.
        // Multiplied by 100 to make the rank more discernible.
        return (attrs.level * (attrs.accuracyScore + 1) * 100) / (attrs.totalInsights + 1);
    }

    // VI. Governance Utility Functions

    /**
     * @notice Allows the contract owner to add a new governor. Governors are authorized to submit truth hashes,
     * reveal truth data, and propose AIC parameter changes.
     * @param _newGovernor The address of the new governor to add.
     */
    function addGovernor(address _newGovernor) external onlyOwner {
        require(_newGovernor != address(0), "ANP: Cannot add zero address as governor");
        for (uint256 i = 0; i < governors.length; i++) {
            require(governors[i] != _newGovernor, "ANP: Governor already exists");
        }
        governors.push(_newGovernor);
        emit GovernorAdded(_newGovernor);
    }

    /**
     * @notice Allows the contract owner to remove an existing governor.
     * @param _governorToRemove The address of the governor to remove.
     */
    function removeGovernor(address _governorToRemove) external onlyOwner {
        require(_governorToRemove != address(0), "ANP: Cannot remove zero address as governor");
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _governorToRemove) {
                governors[i] = governors[governors.length - 1]; // Swap with last element
                governors.pop(); // Remove last element
                emit GovernorRemoved(_governorToRemove);
                return;
            }
        }
        revert("ANP: Governor not found");
    }

    /**
     * @notice Allows the contract owner to change the address designated for collecting protocol fees.
     * @param _newTreasury The new address for the protocol treasury.
     */
    function setProtocolTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "ANP: Treasury cannot be zero address");
        protocolTreasury = _newTreasury;
        emit ProtocolTreasurySet(_newTreasury);
    }
}
```