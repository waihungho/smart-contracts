Here's a smart contract in Solidity called "Decentralized Sentient NFT Ecosystem (DSNE)". It introduces several advanced, creative, and trendy concepts:

**Core Concept:**
Imagine NFTs that are not static. These "Sentient NFTs" (SNFTs) possess dynamic attributes, evolve based on their owner's "training" inputs, react to external real-world data (via oracles), and contribute to a shared "collective wisdom." Each SNFT has an "Adaptability Score" that reflects its development and unlocks unique utilities, including participation in on-chain quests and influence in decentralized governance for ecosystem parameters.

**Key Advanced Concepts & Creativity:**

1.  **Dynamic On-chain Evolution & Metadata:** SNFTs change their internal state and attributes directly on-chain. Their `tokenURI` dynamically generates metadata reflecting these evolving characteristics (e.g., adaptability score, training data points, core attributes), allowing for truly living NFTs.
2.  **Owner-Driven "Training" & Validation:** Owners can "train" their SNFTs by submitting curated data. This data is then subject to verification by authorized oracles. Verified data contributes to the SNFT's development and rewards the owner.
3.  **Oracle-Integrated External Influences:** The ecosystem can react to global environmental factors (e.g., market sentiment, real-world events) updated by trusted oracles, influencing SNFT evolution and adaptability.
4.  **Collective Wisdom:** Verified training data from individual SNFTs aggregates into a shared "Collective Wisdom" pool. This global knowledge base subtly influences the adaptability and evolution of all SNFTs, simulating a decentralized learning network.
5.  **Adaptability Score:** A crucial, dynamically calculated metric for each SNFT, reflecting its holistic development from training, external influences, collective wisdom, and staked boosts. This score gatekeeps access to advanced abilities and quests.
6.  **Staking for Evolution Boost:** Owners can stake an ERC20 token to an SNFT to accelerate its evolution and increase its Adaptability Score, adding a DeFi-like utility layer.
7.  **Dynamic On-chain Quests:** The ecosystem supports multi-step quests that SNFTs can participate in, requiring certain adaptability scores and rewarding completion.
8.  **Decentralized Parameter Governance:** SNFT holders/stakers can propose and vote on changes to core ecosystem parameters (e.g., reward amounts, boost multipliers), giving the community control over the system's evolution. Voting power is tied to SNFT adaptability and staked tokens.
9.  **Fine-Grained Pausing:** An advanced administrative feature allowing the contract owner to selectively pause specific sensitive functions using a bitmask, instead of a blanket contract pause, providing more nuanced control during emergencies or maintenance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol"; // Note: Pausable base for full contract pause is included,
                                                    // but for this contract, we prioritize fine-grained pausing.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For staking token

/*
 * @title Decentralized Sentient NFT Ecosystem (DSNE)
 * @author GPT-4
 * @notice This contract implements a novel ecosystem of "Sentient NFTs" (SNFTs) that exhibit dynamic evolution,
 *         owner-driven training, influence from external oracle data, and participation in a collective
 *         knowledge base. SNFTs possess an "Adaptability Score" which reflects their development and unlocks
 *         advanced utility within the ecosystem, including on-chain quests and participation in decentralized
 *         governance of ecosystem parameters. The system is designed to be highly dynamic, reactive, and community-governed.
 *         The functions are designed to avoid direct duplication of existing open-source contracts by combining
 *         multiple advanced concepts (dynamic NFTs, oracle-driven evolution, owner-driven training, collective
 *         wisdom, on-chain quests, and fine-grained governance) into a single, cohesive ecosystem.
 *
 * Outline:
 *   I. Core SNFT Management & Evolution
 *   II. Owner-Driven Training & Data Contribution
 *   III. Oracle Integration & External Influence
 *   IV. Collective Wisdom & Adaptability Score
 *   V. Staking for Influence & Utility
 *   VI. Dynamic Quests & Challenges
 *   VII. Decentralized Parameter Governance
 *   VIII. Administrative & Standard ERC721
 *
 * Function Summary:
 *
 *   I. Core SNFT Management & Evolution
 *   1.  mintSNFT(address to, string memory initialMetadataURI): Mints a new Sentient NFT to 'to' with an initial base URI.
 *   2.  evolveSNFT(uint256 tokenId): Triggers an SNFT's internal evolution, updating its state based on accumulated factors, training, and external influences.
 *   3.  getSNFTState(uint256 tokenId): Retrieves the current dynamic attributes (state) of a given SNFT.
 *   4.  tokenURI(uint256 tokenId): Overrides ERC721's tokenURI to generate dynamic metadata as a base64 encoded JSON string, reflecting the SNFT's current state and adaptability.
 *
 *   II. Owner-Driven Training & Data Contribution
 *   5.  submitTrainingData(uint256 tokenId, bytes32 dataHash, string memory dataContext): Allows an SNFT owner to submit curated data (represented by a hash) for their SNFT's training, providing a context string.
 *   6.  verifyTrainingData(uint256 tokenId, bytes32 dataHash): Callable by authorized oracles to mark submitted training data as verified. This verification is crucial for the data's impact and rewards.
 *   7.  claimTrainingReward(uint256 tokenId, bytes32 dataHash): Allows owners to claim rewards (native tokens) for a specific, successfully verified training data associated with their SNFT.
 *
 *   III. Oracle Integration & External Influence
 *   8.  updateExternalFactor(string memory factorName, int256 value): Callable by authorized oracles to update a named global environmental factor (e.g., "market_sentiment", "weather_impact") that can influence SNFT evolution.
 *   9.  requestExternalFactorUpdate(string memory factorName): Allows users to signal a need for an oracle update for a specific factor (placeholder for potential fee mechanism).
 *
 *   IV. Collective Wisdom & Adaptability Score
 *   10. contributeToCollectiveWisdom(bytes32 validatedDataHash): Incorporates a hash of verified training data into a global, aggregated "Collective Wisdom" pool, influencing all SNFTs. This is an internal function.
 *   11. getCollectiveWisdomHash(): Retrieves a cryptographic hash representing the current aggregated collective wisdom of the ecosystem.
 *   12. calculateAdaptabilityScore(uint256 tokenId): Recalculates and updates an SNFT's individual Adaptability Score, a key metric, based on its training history, external factors, and interaction with collective wisdom.
 *   13. getSNFTAdaptabilityScore(uint256 tokenId): Returns an SNFT's current Adaptability Score, indicating its level of development and utility.
 *
 *   V. Staking for Influence & Utility
 *   14. stakeForEvolutionBoost(uint256 tokenId, uint256 amount): Allows an owner to stake a specified ERC20 token to an SNFT, providing a boost to its evolution rate and Adaptability Score.
 *   15. unstakeEvolutionBoost(uint256 tokenId, uint256 amount): Allows an owner to unstake tokens from an SNFT. Implements a simple cooldown to prevent rapid manipulation.
 *   16. activateSNFTAbility(uint256 tokenId, uint256 abilityId): Enables an SNFT to use a special, predefined ability or execute a function, provided it meets a specific Adaptability Score or state prerequisite.
 *
 *   VI. Dynamic Quests & Challenges
 *   17. createQuest(string memory name, string memory description, uint256 requiredAdaptability, uint256 rewardAmount, uint256 totalSteps): Admin/governance function to set up new on-chain quests with specific requirements and multi-step progress.
 *   18. participateInQuest(uint256 tokenId, uint256 questId): Enters an SNFT into an active quest if it meets the quest's Adaptability requirements.
 *   19. completeQuestStep(uint256 tokenId, uint256 questId, uint256 stepIndex): Records progress for an SNFT within a multi-step quest. Can be called by owner or authorized entity based on quest type.
 *   20. claimQuestReward(uint256 tokenId, uint256 questId): Allows the SNFT owner to claim the quest reward upon successful completion of all steps.
 *
 *   VII. Decentralized Parameter Governance
 *   21. proposeEcosystemParameterChange(string memory parameterName, bytes memory newValue, string memory description): Allows eligible SNFT holders/stakers to propose changes to core ecosystem parameters (e.g., evolution multipliers, reward amounts, cooldowns).
 *   22. voteOnParameterProposal(uint256 proposalId, bool support): Allows eligible participants (SNFT holders, stakers) to cast their vote (for or against) on active proposals.
 *   23. executeParameterChange(uint256 proposalId): Implements a successfully voted-on parameter change, updating the ecosystem's configuration.
 *
 *   VIII. Administrative & Standard ERC721
 *   24. setAuthorizedOracle(address oracleAddress, bool authorized): Admin function to manage the list of authorized oracle addresses who can update external factors and verify data.
 *   25. pauseCertainFunctions(uint256 functionBitmask): Provides fine-grained pausing capabilities for specific, sensitive functions using a bitmask. This allows selective pausing without halting the entire contract.
 *   26. unpauseCertainFunctions(uint256 functionBitmask): Unpauses specific functions using a bitmask.
 *
 */

contract DecentralizedSentientNFTs is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // ERC20 token used for staking (address passed in constructor)
    IERC20 public immutable stakingToken;

    // Counter for SNFTs
    Counters.Counter private _tokenIdTracker;

    // Mapping from tokenId to SNFT data
    struct SNFT {
        uint256 id;
        uint256 adaptabilityScore; // Key metric for SNFT development
        uint256 lastEvolved;
        uint256 trainingDataCount; // Count of verified training data
        uint256 evolutionBoostAmount; // Amount of stakingToken staked for this SNFT
        uint256 coreAttribute1; // Example dynamic attribute
        uint256 coreAttribute2; // Example dynamic attribute
    }
    mapping(uint256 => SNFT) public snfts;

    // Mapping from tokenId => dataHash => TrainingData
    struct TrainingData {
        bytes32 dataHash;
        string dataContext;
        bool verified;
        address submitter;
        uint256 submissionTime;
        uint256 verificationTime;
        bool rewarded;
    }
    mapping(uint256 => mapping(bytes32 => TrainingData)) public snftTrainingData;

    // External Factors updated by oracles
    mapping(string => int256) public externalFactors;
    mapping(string => uint256) public lastExternalFactorUpdate;

    // Collective Wisdom (simple hash for demonstration)
    bytes32 public collectiveWisdomHash;

    // Quests
    Counters.Counter private _questIdTracker;
    struct Quest {
        uint256 id;
        string name;
        string description;
        uint256 requiredAdaptability;
        uint256 rewardAmount; // Amount of native token (ether)
        uint256 totalSteps;
        bool active;
    }
    mapping(uint256 => Quest) public quests;
    // tokenId => questId => currentStep (1-based, 0 means not participating)
    mapping(uint256 => mapping(uint256 => uint256)) public snftQuestProgress;
    // tokenId => questId => claimedReward
    mapping(uint256 => mapping(uint256 => bool)) public snftQuestRewardClaimed;

    // Governance
    Counters.Counter private _proposalIdTracker;
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        address proposer;
        string parameterName;
        bytes newValue; // Generic byte representation for new value
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        mapping(address => bool) hasVoted; // Voter address => voted status
        mapping(address => uint256) votesByAddress; // Address => total voting power (sum of SNFTs)
    }
    mapping(uint256 => Proposal) public proposals;

    // Authorized Oracles
    mapping(address => bool) public isAuthorizedOracle;

    // Fine-grained pausing bitmask (using a single uint256 for multiple pause states)
    uint256 public pausedFunctionsBitmask;

    // --- Configuration Parameters (can be changed via governance) ---
    uint256 public constant EVOLUTION_COOLDOWN = 1 days; // Can be changed in a more advanced system
    uint256 public TRAINING_REWARD_AMOUNT = 0.01 ether; // Example native token reward per verified training
    uint256 public ADAPTABILITY_BOOST_PER_STAKE = 10; // Adaptability points per 1 unit of staked ERC20 token
    uint224 public ADAPTABILITY_BOOST_PER_TRAINING = 50; // Adaptability points per verified training
    uint256 public ADAPTABILITY_BOOST_PER_COLLECTIVE_WISDOM = 20; // Adaptability points when collective wisdom influences
    uint256 public STAKING_COOLDOWN_PERIOD = 3 days; // For unstaking tokens

    // Paused function bit definitions (can be expanded)
    uint256 public constant PAUSE_MINT = 1 << 0;
    uint256 public constant PAUSE_EVOLVE = 1 << 1;
    uint256 public constant PAUSE_TRAINING_SUBMIT = 1 << 2;
    uint256 public constant PAUSE_QUEST_PARTICIPATION = 1 << 3;
    uint256 public constant PAUSE_GOVERNANCE_PROPOSAL = 1 << 4;
    uint256 public constant PAUSE_ABILITY_ACTIVATION = 1 << 5;
    // Add more as needed: e.g., PAUSE_STAKING = 1 << 6, PAUSE_UNSTAKING = 1 << 7

    // --- Events ---
    event SNFTMinted(uint256 indexed tokenId, address indexed owner, string initialURI);
    event SNFTEvolved(uint256 indexed tokenId, uint256 newAdaptabilityScore);
    event TrainingDataSubmitted(uint256 indexed tokenId, bytes32 indexed dataHash, address indexed submitter);
    event TrainingDataVerified(uint256 indexed tokenId, bytes32 indexed dataHash, address indexed verifier);
    event TrainingRewardClaimed(uint256 indexed tokenId, bytes32 indexed dataHash, address indexed receiver, uint256 amount);
    event ExternalFactorUpdated(string indexed factorName, int256 value, uint256 timestamp);
    event RequestForExternalFactorUpdate(string indexed factorName, address indexed requester);
    event CollectiveWisdomUpdated(bytes32 indexed newHash);
    event AdaptabilityScoreUpdated(uint256 indexed tokenId, uint256 newScore);
    event EvolutionBoostStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event EvolutionBoostUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event SNFTAbilityActivated(uint256 indexed tokenId, uint256 indexed abilityId);
    event QuestCreated(uint256 indexed questId, string name, uint256 rewardAmount);
    event QuestParticipated(uint256 indexed tokenId, uint256 indexed questId);
    event QuestStepCompleted(uint256 indexed tokenId, uint256 indexed questId, uint256 stepIndex);
    event QuestRewardClaimed(uint256 indexed tokenId, uint256 indexed questId, address indexed receiver, uint256 amount);
    event ParameterChangeProposed(uint256 indexed proposalId, string parameterName, bytes newValue, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event OracleAuthorizationChanged(address indexed oracleAddress, bool authorized);
    event FunctionsPaused(uint256 indexed bitmask);
    event FunctionsUnpaused(uint256 indexed bitmask);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(isAuthorizedOracle[msg.sender], "DSNE: Caller is not an authorized oracle");
        _;
    }

    modifier notPaused(uint256 functionBit) {
        require((pausedFunctionsBitmask & functionBit) == 0, "DSNE: Function is paused");
        _;
    }

    modifier onlySNFTOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "DSNE: Caller is not SNFT owner or approved");
        _;
    }

    constructor(address _stakingTokenAddress)
        ERC721("SentientNFT", "SNFT")
        Ownable(msg.sender) // Owner is the deployer
    {
        stakingToken = IERC20(_stakingTokenAddress);
        collectiveWisdomHash = keccak256(abi.encodePacked("initial_wisdom_seed")); // Initial collective wisdom
    }

    // --- I. Core SNFT Management & Evolution ---

    /**
     * @notice Mints a new Sentient NFT to the specified address.
     * @param to The address to mint the SNFT to.
     * @param initialMetadataURI A base URI for initial metadata (will be dynamically updated).
     */
    function mintSNFT(address to, string memory initialMetadataURI) public onlyOwner notPaused(PAUSE_MINT) {
        _tokenIdTracker.increment();
        uint256 newTokenId = _tokenIdTracker.current();

        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, initialMetadataURI);

        snfts[newTokenId] = SNFT({
            id: newTokenId,
            adaptabilityScore: 100, // Initial base score
            lastEvolved: block.timestamp,
            trainingDataCount: 0,
            evolutionBoostAmount: 0,
            coreAttribute1: 0,
            coreAttribute2: 0
        });

        emit SNFTMinted(newTokenId, to, initialMetadataURI);
    }

    /**
     * @notice Triggers an SNFT's internal evolution. Can be called by the owner.
     *         Updates various internal states and automatically recalculates the Adaptability Score.
     * @param tokenId The ID of the SNFT to evolve.
     */
    function evolveSNFT(uint256 tokenId) public onlySNFTOwner(tokenId) notPaused(PAUSE_EVOLVE) {
        SNFT storage snft = snfts[tokenId];
        require(snft.id != 0, "SNFT: Does not exist");
        require(block.timestamp >= snft.lastEvolved + EVOLUTION_COOLDOWN, "SNFT: Evolution cooldown active");

        // Simulate evolution logic based on various factors
        snft.coreAttribute1 += 1 + (snft.evolutionBoostAmount / 1e18) / 100; // Example: boost from staked tokens
        snft.coreAttribute2 += (snft.trainingDataCount * 2); // Example: boost from training

        calculateAdaptabilityScore(tokenId); // Update adaptability score based on new state
        snft.lastEvolved = block.timestamp;
        emit SNFTEvolved(tokenId, snft.adaptabilityScore);
    }

    /**
     * @notice Retrieves the current dynamic attributes (state) of a given SNFT.
     * @param tokenId The ID of the SNFT.
     * @return A tuple containing the SNFT's ID, adaptability score, last evolved timestamp,
     *         training data count, staked boost amount, and core attributes.
     */
    function getSNFTState(uint256 tokenId)
        public
        view
        returns (
            uint256 id,
            uint256 adaptabilityScore,
            uint256 lastEvolved,
            uint256 trainingDataCount,
            uint256 evolutionBoostAmount,
            uint256 coreAttribute1,
            uint256 coreAttribute2
        )
    {
        SNFT storage snft = snfts[tokenId];
        require(snft.id != 0, "SNFT: Does not exist");

        return (
            snft.id,
            snft.adaptabilityScore,
            snft.lastEvolved,
            snft.trainingDataCount,
            snft.evolutionBoostAmount,
            snft.coreAttribute1,
            snft.coreAttribute2
        );
    }

    /**
     * @notice Overrides ERC721's tokenURI to generate dynamic metadata.
     *         The URI is a base64 encoded JSON string reflecting the SNFT's current state.
     * @param tokenId The ID of the SNFT.
     * @return The dynamic token URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        SNFT storage snft = snfts[tokenId];

        // Simulate dynamic properties influencing metadata
        string memory name = string(abi.encodePacked("Sentient SNFT #", tokenId.toString()));
        string memory description = string(
            abi.encodePacked(
                "A dynamic Sentient NFT. Adaptability: ",
                snft.adaptabilityScore.toString(),
                ". Trained data points: ",
                snft.trainingDataCount.toString(),
                ". Core Attribute 1: ",
                snft.coreAttribute1.toString(),
                ". Core Attribute 2: ",
                snft.coreAttribute2.toString()
            )
        );
        string memory image = "ipfs://QmYh6xQG5j1zQ6c7k7v3r2w8m9x1y7z2c3d4e5f6g7"; // Placeholder image - replace with actual image generation or storage logic

        string memory json = string(
            abi.encodePacked(
                '{"name": "',
                name,
                '", "description": "',
                description,
                '", "image": "',
                image,
                '", "attributes": [',
                '{"trait_type": "Adaptability Score", "value": ',
                snft.adaptabilityScore.toString(),
                '},',
                '{"trait_type": "Training Data Points", "value": ',
                snft.trainingDataCount.toString(),
                '},',
                '{"trait_type": "Core Attribute 1", "value": ',
                snft.coreAttribute1.toString(),
                '},',
                '{"trait_type": "Core Attribute 2", "value": ',
                snft.coreAttribute2.toString(),
                '},',
                '{"trait_type": "Last Evolved", "value": "',
                snft.lastEvolved.toString(),
                '"},',
                '{"trait_type": "Evolution Boost Staked", "value": ',
                (snft.evolutionBoostAmount / (10**uint256(stakingToken.decimals()))).toString(), // Display in human-readable units
                '}',
                ']}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- II. Owner-Driven Training & Data Contribution ---

    /**
     * @notice Allows an SNFT owner to submit curated data (represented by a hash) for their SNFT's training.
     *         This data needs to be verified by an oracle later to have an effect.
     * @param tokenId The ID of the SNFT.
     * @param dataHash A cryptographic hash representing the submitted data.
     * @param dataContext A string providing context or description of the training data.
     */
    function submitTrainingData(uint256 tokenId, bytes32 dataHash, string memory dataContext)
        public
        onlySNFTOwner(tokenId)
        notPaused(PAUSE_TRAINING_SUBMIT)
    {
        require(snfts[tokenId].id != 0, "SNFT: Does not exist");
        require(snftTrainingData[tokenId][dataHash].submissionTime == 0, "SNFT: Data hash already submitted for this SNFT");

        snftTrainingData[tokenId][dataHash] = TrainingData({
            dataHash: dataHash,
            dataContext: dataContext,
            verified: false,
            submitter: msg.sender,
            submissionTime: block.timestamp,
            verificationTime: 0,
            rewarded: false
        });

        emit TrainingDataSubmitted(tokenId, dataHash, msg.sender);
    }

    /**
     * @notice Callable by authorized oracles to mark submitted training data as verified.
     *         Verified data contributes to the SNFT's adaptability and collective wisdom.
     * @param tokenId The ID of the SNFT.
     * @param dataHash The hash of the training data to verify.
     */
    function verifyTrainingData(uint256 tokenId, bytes32 dataHash) public onlyOracle {
        TrainingData storage data = snftTrainingData[tokenId][dataHash];
        require(data.submissionTime != 0, "DSNE: Training data not submitted");
        require(!data.verified, "DSNE: Training data already verified");

        data.verified = true;
        data.verificationTime = block.timestamp;
        snfts[tokenId].trainingDataCount++; // Increment verified data count
        contributeToCollectiveWisdom(dataHash); // Contribute to global wisdom
        calculateAdaptabilityScore(tokenId); // Recalculate adaptability for this SNFT

        emit TrainingDataVerified(tokenId, dataHash, msg.sender);
    }

    /**
     * @notice Allows owners to claim rewards for a specific, successfully verified training data associated with their SNFT.
     * @param tokenId The ID of the SNFT.
     * @param dataHash The specific hash of the verified training data for which to claim the reward.
     */
    function claimTrainingReward(uint256 tokenId, bytes32 dataHash) public onlySNFTOwner(tokenId) {
        TrainingData storage data = snftTrainingData[tokenId][dataHash];
        require(data.submissionTime != 0, "DSNE: Training data not submitted");
        require(data.verified, "DSNE: Training data not yet verified");
        require(!data.rewarded, "DSNE: Training data reward already claimed");
        require(TRAINING_REWARD_AMOUNT > 0, "DSNE: Training reward amount is zero");
        
        data.rewarded = true; // Mark as rewarded

        // Transfer native tokens as reward
        (bool success, ) = msg.sender.call{value: TRAINING_REWARD_AMOUNT}("");
        require(success, "DSNE: Reward transfer failed");

        emit TrainingRewardClaimed(tokenId, dataHash, msg.sender, TRAINING_REWARD_AMOUNT);
    }

    // --- III. Oracle Integration & External Influence ---

    /**
     * @notice Callable by authorized oracles to update a global environmental factor impacting SNFTs.
     * @param factorName The name of the external factor (e.g., "market_sentiment", "weather_impact").
     * @param value The new integer value for the factor.
     */
    function updateExternalFactor(string memory factorName, int256 value) public onlyOracle {
        externalFactors[factorName] = value;
        lastExternalFactorUpdate[factorName] = block.timestamp;
        emit ExternalFactorUpdated(factorName, value, block.timestamp);
    }

    /**
     * @notice Allows users to signal a need for an oracle update for a specific factor.
     *         (Placeholder for fee mechanism - in a real system, this would involve paying an oracle service).
     * @param factorName The name of the external factor to request an update for.
     */
    function requestExternalFactorUpdate(string memory factorName) public {
        // In a real system, this would interact with an oracle network (e.g., Chainlink)
        // and potentially involve a fee paid by the caller.
        // For now, it's a signaling mechanism.
        emit RequestForExternalFactorUpdate(factorName, msg.sender);
    }

    // --- IV. Collective Wisdom & Adaptability Score ---

    /**
     * @notice Incorporates a hash of verified training data into a global, aggregated "Collective Wisdom" pool.
     *         This acts as a shared knowledge base that influences all SNFTs.
     *         This function is typically called internally, e.g., by `verifyTrainingData`.
     * @param validatedDataHash The hash of the newly validated data.
     */
    function contributeToCollectiveWisdom(bytes32 validatedDataHash) internal {
        // Simple aggregation: XORing the new hash with the current collective wisdom hash.
        // In a more complex system, this could be a Merkle tree root of all contributions.
        collectiveWisdomHash = keccak256(abi.encodePacked(collectiveWisdomHash, validatedDataHash, block.timestamp));
        emit CollectiveWisdomUpdated(collectiveWisdomHash);

        // Note: For gas efficiency, this does not immediately trigger recalculation for ALL SNFTs.
        // SNFTs will pick up changes when they evolve or when their score is explicitly recalculated.
    }

    /**
     * @notice Retrieves a cryptographic hash representing the current aggregated collective wisdom of the ecosystem.
     * @return The current collective wisdom hash.
     */
    function getCollectiveWisdomHash() public view returns (bytes32) {
        return collectiveWisdomHash;
    }

    /**
     * @notice Recalculates and updates an SNFT's individual Adaptability Score.
     *         This score is a key metric, reflecting its development and utility.
     *         Factors include: verified training data, staked boost, external factors, and collective wisdom.
     * @param tokenId The ID of the SNFT.
     */
    function calculateAdaptabilityScore(uint256 tokenId) public onlySNFTOwner(tokenId) {
        SNFT storage snft = snfts[tokenId];
        require(snft.id != 0, "SNFT: Does not exist");

        uint256 newScore = 100; // Base score

        // Boost from verified training data
        newScore += snft.trainingDataCount * ADAPTABILITY_BOOST_PER_TRAINING;

        // Boost from staked tokens (assuming staking token has 18 decimals, adjust if different)
        newScore += (snft.evolutionBoostAmount / 1e18) * ADAPTABILITY_BOOST_PER_STAKE;

        // Influence from collective wisdom (unique per SNFT by incorporating tokenId)
        newScore += (uint256(keccak256(abi.encodePacked(collectiveWisdomHash, tokenId))) % 100) * (ADAPTABILITY_BOOST_PER_COLLECTIVE_WISDOM / 10);

        // Incorporate external factors (example: "market_sentiment" factor)
        // Note: int256 needs careful handling for negative values.
        int256 marketSentiment = externalFactors["market_sentiment"];
        if (marketSentiment > 0) {
            newScore += uint256(marketSentiment);
        } else if (marketSentiment < 0) {
            // Apply a penalty for negative sentiment
            newScore = newScore > uint256(-marketSentiment) ? newScore - uint256(-marketSentiment) : 0;
        }

        snft.adaptabilityScore = newScore;
        emit AdaptabilityScoreUpdated(tokenId, newScore);
    }

    /**
     * @notice Returns an SNFT's current Adaptability Score.
     * @param tokenId The ID of the SNFT.
     * @return The current Adaptability Score.
     */
    function getSNFTAdaptabilityScore(uint256 tokenId) public view returns (uint256) {
        require(snfts[tokenId].id != 0, "SNFT: Does not exist");
        return snfts[tokenId].adaptabilityScore;
    }

    // --- V. Staking for Influence & Utility ---

    /**
     * @notice Allows an owner to stake a specified ERC20 token to an SNFT, providing a boost to its evolution rate and Adaptability Score.
     * @param tokenId The ID of the SNFT to stake for.
     * @param amount The amount of staking tokens to stake (in smallest units, e.g., wei).
     */
    function stakeForEvolutionBoost(uint256 tokenId, uint256 amount) public onlySNFTOwner(tokenId) {
        require(snfts[tokenId].id != 0, "SNFT: Does not exist");
        require(amount > 0, "DSNE: Stake amount must be greater than 0");

        // Transfer tokens from staker to contract
        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            "DSNE: Staking token transfer failed"
        );

        snfts[tokenId].evolutionBoostAmount += amount;
        calculateAdaptabilityScore(tokenId); // Update score immediately

        emit EvolutionBoostStaked(tokenId, msg.sender, amount);
    }

    /**
     * @notice Allows an owner to unstake tokens from an SNFT. Implements a simple cooldown to prevent rapid manipulation.
     * @param tokenId The ID of the SNFT to unstake from.
     * @param amount The amount of staking tokens to unstake (in smallest units, e.g., wei).
     */
    function unstakeEvolutionBoost(uint256 tokenId, uint256 amount) public onlySNFTOwner(tokenId) {
        SNFT storage snft = snfts[tokenId];
        require(snft.id != 0, "SNFT: Does not exist");
        require(amount > 0, "DSNE: Unstake amount must be greater than 0");
        require(snft.evolutionBoostAmount >= amount, "DSNE: Not enough staked tokens");
        // Using lastEvolved as a proxy for cooldown. A dedicated `lastStakingActivity` per SNFT would be more precise.
        require(block.timestamp >= snft.lastEvolved + STAKING_COOLDOWN_PERIOD, "DSNE: Staking cooldown active, cannot unstake yet");

        snft.evolutionBoostAmount -= amount;
        calculateAdaptabilityScore(tokenId); // Update score immediately

        // Transfer tokens from contract back to staker
        require(stakingToken.transfer(msg.sender, amount), "DSNE: Unstaking token transfer failed");

        emit EvolutionBoostUnstaked(tokenId, msg.sender, amount);
    }

    /**
     * @notice Enables an SNFT to use a special, predefined ability or execute a function,
     *         provided it meets a specific Adaptability Score or state prerequisite.
     * @param tokenId The ID of the SNFT activating the ability.
     * @param abilityId The ID of the ability to activate.
     */
    function activateSNFTAbility(uint256 tokenId, uint256 abilityId) public onlySNFTOwner(tokenId) notPaused(PAUSE_ABILITY_ACTIVATION) {
        SNFT storage snft = snfts[tokenId];
        require(snft.id != 0, "SNFT: Does not exist");

        // Example ability logic:
        if (abilityId == 1) { // Ability 1: Boost core attribute, requires high adaptability
            require(snft.adaptabilityScore >= 200, "DSNE: SNFT does not meet adaptability requirement for ability 1");
            snft.coreAttribute1 += 25;
            // Additional effects or interactions could go here
        } else if (abilityId == 2) { // Ability 2: Reset core attribute with a cost, requires certain core attribute levels
            require(snft.coreAttribute1 >= 10 && snft.coreAttribute2 >= 10, "DSNE: SNFT does not meet attribute requirements for ability 2");
            // Placeholder for a cost, e.g., burning some staked tokens or paying ETH
            // require(stakingToken.transfer(address(0), 1e18), "DSNE: Cost for ability 2 not met");
            snft.coreAttribute1 = 0; // Example effect: reset attribute
        } else {
            revert("DSNE: Invalid ability ID");
        }

        // Recalculate adaptability if ability changes SNFT state significantly
        calculateAdaptabilityScore(tokenId);
        emit SNFTAbilityActivated(tokenId, abilityId);
    }

    // --- VI. Dynamic Quests & Challenges ---

    /**
     * @notice Admin/governance function to set up new on-chain quests with specific requirements and multi-step progress.
     * @param name The name of the quest.
     * @param description A description of the quest.
     * @param requiredAdaptability The minimum Adaptability Score required to participate.
     * @param rewardAmount The amount of native token (ether) rewarded upon completion.
     * @param totalSteps The total number of steps to complete the quest (must be at least 1).
     */
    function createQuest(
        string memory name,
        string memory description,
        uint256 requiredAdaptability,
        uint256 rewardAmount,
        uint256 totalSteps
    ) public onlyOwner {
        require(totalSteps > 0, "DSNE: Quest must have at least one step");
        _questIdTracker.increment();
        uint256 newQuestId = _questIdTracker.current();

        quests[newQuestId] = Quest({
            id: newQuestId,
            name: name,
            description: description,
            requiredAdaptability: requiredAdaptability,
            rewardAmount: rewardAmount,
            totalSteps: totalSteps,
            active: true
        });

        emit QuestCreated(newQuestId, name, rewardAmount);
    }

    /**
     * @notice Enters an SNFT into an active quest if it meets the quest's Adaptability requirements.
     * @param tokenId The ID of the SNFT.
     * @param questId The ID of the quest to participate in.
     */
    function participateInQuest(uint256 tokenId, uint256 questId) public onlySNFTOwner(tokenId) notPaused(PAUSE_QUEST_PARTICIPATION) {
        SNFT storage snft = snfts[tokenId];
        Quest storage quest = quests[questId];

        require(snft.id != 0, "SNFT: Does not exist");
        require(quest.id != 0 && quest.active, "DSNE: Quest does not exist or is not active");
        require(snft.adaptabilityScore >= quest.requiredAdaptability, "DSNE: SNFT does not meet adaptability requirements for quest");
        require(snftQuestProgress[tokenId][questId] == 0, "DSNE: SNFT already participating or completed this quest");
        require(!snftQuestRewardClaimed[tokenId][questId], "DSNE: Quest reward already claimed for this SNFT");

        snftQuestProgress[tokenId][questId] = 1; // Start at step 1
        emit QuestParticipated(tokenId, questId);
    }

    /**
     * @notice Records progress for an SNFT within a multi-step quest.
     *         Can be called by owner or authorized entity based on quest type (currently only owner).
     * @param tokenId The ID of the SNFT.
     * @param questId The ID of the quest.
     * @param stepIndex The index of the step being completed (should be currentStep).
     */
    function completeQuestStep(uint256 tokenId, uint256 questId, uint256 stepIndex) public onlySNFTOwner(tokenId) {
        Quest storage quest = quests[questId];
        require(quest.id != 0 && quest.active, "DSNE: Quest does not exist or is not active");
        require(snftQuestProgress[tokenId][questId] > 0, "DSNE: SNFT not participating in this quest");
        require(snftQuestProgress[tokenId][questId] == stepIndex, "DSNE: Incorrect quest step sequence or step already completed");
        require(stepIndex < quest.totalSteps, "DSNE: This is the last step, claim reward instead");

        snftQuestProgress[tokenId][questId]++;
        emit QuestStepCompleted(tokenId, questId, stepIndex);
    }

    /**
     * @notice Allows the SNFT owner to claim the quest reward upon successful completion of all steps.
     * @param tokenId The ID of the SNFT.
     * @param questId The ID of the quest.
     */
    function claimQuestReward(uint256 tokenId, uint256 questId) public onlySNFTOwner(tokenId) {
        Quest storage quest = quests[questId];
        require(quest.id != 0 && quest.active, "DSNE: Quest does not exist or is not active");
        require(snftQuestProgress[tokenId][questId] > 0, "DSNE: SNFT not participating in this quest");
        require(snftQuestProgress[tokenId][questId] == quest.totalSteps, "DSNE: Quest not fully completed");
        require(!snftQuestRewardClaimed[tokenId][questId], "DSNE: Quest reward already claimed");
        require(quest.rewardAmount > 0, "DSNE: Quest reward amount is zero");

        snftQuestRewardClaimed[tokenId][questId] = true;

        // Transfer native token reward
        (bool success, ) = msg.sender.call{value: quest.rewardAmount}("");
        require(success, "DSNE: Quest reward transfer failed");

        emit QuestRewardClaimed(tokenId, questId, msg.sender, quest.rewardAmount);
    }

    // --- VII. Decentralized Parameter Governance ---

    /**
     * @notice Allows eligible SNFT holders/stakers to propose changes to core ecosystem parameters.
     *         Eligibility requires owning at least one SNFT with an Adaptability Score > 150.
     * @param parameterName The name of the parameter to change (e.g., "TRAINING_REWARD_AMOUNT").
     * @param newValue The new value for the parameter, encoded as bytes.
     * @param description A description of the proposed change.
     */
    function proposeEcosystemParameterChange(
        string memory parameterName,
        bytes memory newValue,
        string memory description
    ) public notPaused(PAUSE_GOVERNANCE_PROPOSAL) {
        // Eligibility check: require minimum Adaptability Score on any owned SNFT
        bool eligibleProposer = false;
        for (uint256 i = 1; i <= _tokenIdTracker.current(); i++) {
            if (_isApprovedOrOwner(msg.sender, i) && snfts[i].adaptabilityScore > 150) { // Example threshold
                eligibleProposer = true;
                break;
            }
        }
        require(eligibleProposer, "DSNE: Not eligible to propose parameter change (requires SNFT with >150 Adaptability)");

        _proposalIdTracker.increment();
        uint256 newProposalId = _proposalIdTracker.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            parameterName: parameterName,
            newValue: newValue,
            description: description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + 3 days, // 3-day voting period
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool),
            votesByAddress: new mapping(address => uint256)
        });

        emit ParameterChangeProposed(newProposalId, parameterName, newValue, msg.sender);
    }

    /**
     * @notice Allows eligible participants (SNFT holders, stakers) to cast their vote (for or against) on active proposals.
     *         Voting power is derived from owned SNFT Adaptability Score and staked tokens.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for', false for 'against'.
     */
    function voteOnParameterProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "DSNE: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "DSNE: Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime, "DSNE: Voting has not started");
        require(block.timestamp <= proposal.voteEndTime, "DSNE: Voting has ended");
        require(!proposal.hasVoted[msg.sender], "DSNE: Already voted on this proposal");

        // Calculate voting power: sum of adaptability scores of owned SNFTs + staked tokens
        uint256 votingPower = 0;
        for (uint256 i = 1; i <= _tokenIdTracker.current(); i++) {
            if (_isApprovedOrOwner(msg.sender, i)) { // Checks if msg.sender owns or is approved for this SNFT
                SNFT storage snft = snfts[i];
                votingPower += snft.adaptabilityScore; // Each point of adaptability is a vote
                votingPower += (snft.evolutionBoostAmount / 1e18); // 1 vote per 1 unit of staked token (assuming 18 decimals)
            }
        }
        require(votingPower > 0, "DSNE: No voting power detected (requires owned SNFTs or staked tokens)");

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;
        proposal.votesByAddress[msg.sender] = votingPower; // Store total power for this voter

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @notice Implements a successfully voted-on parameter change, updating the ecosystem's configuration.
     *         Can be called by anyone after the voting period ends and criteria are met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "DSNE: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "DSNE: Proposal is not active");
        require(block.timestamp > proposal.voteEndTime, "DSNE: Voting period not ended");

        // Basic majority vote, could add quorum requirements (e.g., min total votes)
        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor > (proposal.votesFor + proposal.votesAgainst) / 2) {
            proposal.state = ProposalState.Succeeded;

            // Apply the parameter change based on parameterName
            bytes32 paramNameHash = keccak256(abi.encodePacked(proposal.parameterName));
            if (paramNameHash == keccak256(abi.encodePacked("TRAINING_REWARD_AMOUNT"))) {
                TRAINING_REWARD_AMOUNT = abi.decode(proposal.newValue, (uint256));
            } else if (paramNameHash == keccak256(abi.encodePacked("ADAPTABILITY_BOOST_PER_STAKE"))) {
                ADAPTABILITY_BOOST_PER_STAKE = abi.decode(proposal.newValue, (uint256));
            } else if (paramNameHash == keccak256(abi.encodePacked("ADAPTABILITY_BOOST_PER_TRAINING"))) {
                ADAPTABILITY_BOOST_PER_TRAINING = abi.decode(proposal.newValue, (uint256));
            } else if (paramNameHash == keccak256(abi.encodePacked("ADAPTABILITY_BOOST_PER_COLLECTIVE_WISDOM"))) {
                ADAPTABILITY_BOOST_PER_COLLECTIVE_WISDOM = abi.decode(proposal.newValue, (uint256));
            } else if (paramNameHash == keccak256(abi.encodePacked("STAKING_COOLDOWN_PERIOD"))) {
                STAKING_COOLDOWN_PERIOD = abi.decode(proposal.newValue, (uint256));
            }
            else {
                revert("DSNE: Unknown or unchangeable parameter for governance.");
            }
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(proposalId, true);
        } else {
            proposal.state = ProposalState.Failed;
            emit ProposalExecuted(proposalId, false);
        }
    }

    // --- VIII. Administrative & Standard ERC721 ---

    /**
     * @notice Admin function to manage the list of authorized oracle addresses.
     * @param oracleAddress The address to set or unset as an oracle.
     * @param authorized True to authorize, false to deauthorize.
     */
    function setAuthorizedOracle(address oracleAddress, bool authorized) public onlyOwner {
        require(oracleAddress != address(0), "DSNE: Invalid address");
        isAuthorizedOracle[oracleAddress] = authorized;
        emit OracleAuthorizationChanged(oracleAddress, authorized);
    }

    /**
     * @notice Provides fine-grained pausing capabilities for specific, sensitive functions using a bitmask.
     *         This allows selective pausing without halting the entire contract.
     * @param functionBitmask A bitmask where each bit corresponds to a specific function to pause.
     *         e.g., PAUSE_MINT | PAUSE_EVOLVE to pause both minting and evolving.
     */
    function pauseCertainFunctions(uint256 functionBitmask) public onlyOwner {
        pausedFunctionsBitmask |= functionBitmask;
        emit FunctionsPaused(functionBitmask);
    }

    /**
     * @notice Unpauses specific functions using a bitmask.
     * @param functionBitmask A bitmask where each bit corresponds to a specific function to unpause.
     */
    function unpauseCertainFunctions(uint256 functionBitmask) public onlyOwner {
        pausedFunctionsBitmask &= ~functionBitmask;
        emit FunctionsUnpaused(functionBitmask);
    }

    // Standard ERC721 overrides for baseURI (handled directly in tokenURI)
    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,"; // Prefix is included directly in `tokenURI`
    }

    // Fallback and Receive for Ether (for quest rewards and potential future uses)
    receive() external payable {}
    fallback() external payable {}
}

// Utility library for Base64 encoding.
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.x/contracts/utils/Base64.sol
// Used for dynamically generating base64 encoded JSON for tokenURI.
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = _TABLE;

        // calculate output length, saving a modulo operation
        uint256 tablePtr;
        uint256 lastElement;
        uint256 dataLength = data.length;
        uint256 resultLength = 4 * ((dataLength + 2) / 3);

        // allocate output
        bytes memory result = new bytes(resultLength);

        assembly {
            // find the table in memory
            tablePtr := add(table, 1)

            // find the start of the output
            let resultPtr := add(result, 32)

            // set result length in memory
            mstore(result, resultLength)

            // store the last element to prevent it from being overwritten later
            lastElement := add(resultPtr, resultLength)
        }

        // encode data in batches of 3 bytes
        for (uint256 i = 0; i < dataLength; i += 3) {
            assembly {
                // load 3 bytes from data
                let chunk := mload(add(data, add(0x20, i)))

                // encode to 4 characters from the table
                mstore(resultPtr, shl(24, mload(add(tablePtr, and(shr(18, chunk), 0x3F)))))
                mstore(add(resultPtr, 1), shl(24, mload(add(tablePtr, and(shr(12, chunk), 0x3F)))))
                mstore(add(resultPtr, 2), shl(24, mload(add(tablePtr, and(shr(6, chunk), 0x3F)))))
                mstore(add(resultPtr, 3), shl(24, mload(add(tablePtr, and(chunk, 0x3F)))))

                // increment resultPtr
                resultPtr := add(resultPtr, 4)
            }
        }

        // handle padding
        if (dataLength % 3 == 1) {
            assembly {
                mstore(sub(lastElement, 1), 0x3d) // '='
                mstore(sub(lastElement, 2), 0x3d) // '='
            }
        } else if (dataLength % 3 == 2) {
            assembly {
                mstore(sub(lastElement, 1), 0x3d) // '='
            }
        }

        return string(result);
    }
}
```