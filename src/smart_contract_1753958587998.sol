I've designed a Solidity smart contract called **"AetherNexus - Decentralized AI Evolution Protocol"**.

This contract introduces a novel concept: a decentralized network for improving AI models and datasets through community-contributed "insights." It integrates a unique "Proof-of-Insight" mechanism, a reputation system, and dynamic NFTs ("AetherBots") that visually and functionally evolve based on validated contributions. The goal is to create a self-sustaining ecosystem where AI knowledge is collectively curated and improved on-chain.

**Key Advanced Concepts:**

1.  **Proof-of-Insight (PoI):** A novel consensus mechanism where users submit valuable AI-related data, labels, or model improvements (insights). These insights are then validated by a decentralized group of "Curators."
2.  **Dynamic NFTs (AetherBots):** NFTs that are not static. Their traits and potential visual representation (via metadataURI) dynamically update and "evolve" based on successful "insights" applied to them, reflecting the collective improvement of an underlying AI concept or model.
3.  **Reputation System:** Contributors and Curators earn and lose reputation based on the quality and impact of their contributions and voting decisions. Reputation directly influences curator eligibility and voting weight.
4.  **Decentralized Curation & Validation:** A DAO-like system where high-reputation "Curators" are responsible for proposing and voting on the validity of submitted insights, ensuring quality control in a decentralized manner.
5.  **Epoch-based Progression:** The protocol operates in distinct epochs, providing structured cycles for contributions, validations, and reward distributions.
6.  **On-chain Parameter Governance:** Key protocol parameters (like stake amounts, durations, reputation thresholds) can be changed through a decentralized voting process by Curators, allowing the protocol to adapt and evolve.

This design aims to be creative by applying DAO principles and dynamic NFTs to a domain like AI model improvement/curation, avoiding direct duplication of existing large open-source projects by combining these elements in a specific, integrated flow.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For AetherBot traits

// Interface for the AetherToken (ERC20)
interface IAetherToken is IERC20 {
    // Assuming a mint function exists on the AetherToken contract for rewards
    function mint(address _to, uint256 _amount) external; 
}

// Interface for the AetherBot NFT (ERC721)
interface IAetherBotNFT is IERC721, IERC721Metadata {
    // Structure defining the dynamic traits of an AetherBot
    struct AetherBotTraits {
        string name;                // Name of the AetherBot (e.g., "InsightfulBot-X")
        string modelType;           // e.g., "NLP", "CV", "Generative", "DataAnalysis"
        uint256 generation;         // AetherBot's generation (might increase with major upgrades)
        uint256 insightAppliedCount; // Number of validated insights successfully applied
        uint256 performanceFactor;  // Dynamic metric, increases with validated insights (reflects improvement)
        string currentEvolutionState; // e.g., "Seedling", "Juvenile", "Mature", "Specialized"
        string metadataURI;         // IPFS hash for visual/detailed metadata (JSON conforming to ERC721 metadata standard)
    }

    function mint(address _to) external returns (uint256); // Mints a new AetherBot to an address
    function updateTraits(uint256 _tokenId, AetherBotTraits memory _newTraits) external; // Updates an AetherBot's traits
    function getTraits(uint256 _tokenId) external view returns (AetherBotTraits memory); // Retrieves an AetherBot's traits
}

/**
 * @title AetherNexus - Decentralized AI Evolution Protocol
 * @dev This contract facilitates a decentralized network for curating, validating, and evolving AI models
 *      and datasets through community-contributed "insights." It introduces a Proof-of-Insight mechanism,
 *      a reputation system, and dynamic NFTs ("AetherBots") that evolve based on validated contributions.
 */
contract AetherNexus is Ownable, Pausable {

    // --- Outline: AetherNexus - Decentralized AI Evolution Protocol ---

    // I. Core Protocol Setup & Control
    //    General contract management, pausing, and treasury operations.
    // II. Token & NFT Interaction
    //    Handles interactions with the native AetherToken (ATR) and AetherBot NFTs.
    // III. Contributor & Insight Management (Proof-of-Insight)
    //    Mechanism for users to submit AI-related insights and track their contributions.
    // IV. Validation & Curation System
    //    The decentralized process for evaluating and validating submitted insights, powered by "Curators."
    // V. AetherBot Dynamic NFT Evolution
    //    How AetherBot NFTs acquire new traits and evolve based on validated insights.
    // VI. Epoch Management & Reward Distribution
    //    Structured system for progressing the protocol state and distributing rewards.
    // VII. Governance & Parameter Configuration
    //    Decentralized decision-making process for protocol evolution.
    // VIII. Utility & Query Functions
    //    Read-only functions for querying contract state.

    // --- Function Summary ---

    // I. Core Protocol Setup & Control
    // 1. constructor(address _initialAetherTokenAddress, address _initialAetherBotNFTAddress): Initializes the contract with deployer as owner, sets up AetherToken and AetherBot contracts.
    // 2. pause(): Allows the owner to pause critical contract functions (e.g., insight submission, validation) in emergencies.
    // 3. unpause(): Allows the owner to unpause the contract.
    // 4. withdrawTreasuryFunds(address _tokenAddress, uint256 _amount): Allows the owner to withdraw funds from the contract's treasury, typically to a multisig.

    // II. Token & NFT Interaction
    // 5. setAetherTokenAddress(address _tokenAddress): Owner sets the address of the AetherToken contract.
    // 6. setAetherBotNFTAddress(address _nftAddress): Owner sets the address of the AetherBot NFT contract.
    // 7. getAetherBotNFTBalance(address _owner): Retrieves the number of AetherBot NFTs owned by an address. (Read-only utility).

    // III. Contributor & Insight Management (Proof-of-Insight)
    // 8. submitInsight(string memory _ipfsHash, uint256 _targetAetherBotId, bytes32[] memory _tags): Allows a user to submit an AI-related insight (referenced by IPFS hash), targeting a specific AetherBot, and providing relevant tags. Requires staking AetherTokens.
    // 9. getInsightDetails(uint256 _insightId): Retrieves comprehensive details about a specific insight.
    // 10. getContributorProfile(address _contributor): Fetches a contributor's reputation, total insights, and validated insights.
    // 11. updateContributorBio(string memory _ipfsHashToBio): Allows contributors to link an IPFS hash to their public profile bio.

    // IV. Validation & Curation System
    // 12. becomeCurator(): Allows a user to become a curator by staking the required amount of AetherTokens and meeting reputation criteria.
    // 13. resignCurator(): Allows an active curator to resign and unstake their tokens after a cooldown period.
    // 14. proposeInsightValidation(uint256 _insightId): A curator proposes a specific insight for validation voting.
    // 15. castValidationVote(uint256 _voteId, bool _approve): Active curators cast their vote (approve/reject) on a proposed insight validation.
    // 16. tallyInsightValidation(uint256 _voteId): Triggers the tallying of votes for a specific insight. If approved, reputation is updated, contributor is rewarded, and AetherBot traits may evolve.

    // V. AetherBot Dynamic NFT Evolution
    // 17. mintAetherBot(): Allows users to mint a new AetherBot NFT, potentially requiring AetherTokens.
    // 18. getAetherBotTraits(uint256 _aetherBotId): Retrieves the current dynamic traits of an AetherBot NFT.
    // 19. requestAetherBotUpgrade(uint256 _aetherBotId, uint256 _insightId): An AetherBot owner requests an upgrade using a previously validated insight.

    // VI. Epoch Management & Reward Distribution
    // 20. endCurrentEpoch(): Admin/privileged function to advance the protocol to the next epoch, calculating and distributing epoch-based rewards.
    // 21. claimEpochRewards(uint256 _epoch): Allows contributors to claim their AetherToken rewards for a specific past epoch.
    // 22. getCurrentEpoch(): Returns the current active epoch number. (Read-only utility).

    // VII. Governance & Parameter Configuration
    // 23. proposeParameterChange(bytes32 _parameterName, uint256 _newValue): Curators or high-reputation users can propose changes to contract parameters (e.g., insight stake amount, curator stake).
    // 24. voteOnParameterChange(uint256 _proposalId, bool _approve): Curators vote on a proposed parameter change.
    // 25. executeParameterChange(uint256 _proposalId): Executes a successfully voted parameter change.

    // VIII. Utility & Query Functions
    // 26. getContractParameters(): Returns a struct containing all current configurable parameters of the contract.
    // 27. getPendingValidationVotes(): Returns a list of insights currently undergoing validation voting.
    // 28. isCurator(address _addr): Checks if an address is an active curator.
    // 29. getCuratorStakeAmount(): Returns the required stake to become a curator. (Read-only utility).
    // 30. getInsightStakeAmount(): Returns the required stake to submit an insight. (Read-only utility).
    // 31. unstakeCuratorTokens(): Allows a curator to unstake their locked tokens after the cooldown period.

    // --- State Variables ---

    IAetherToken public aetherToken; // Address of the AetherToken (ERC20) contract
    IAetherBotNFT public aetherBotNFT; // Address of the AetherBot (ERC721) NFT contract

    uint256 public nextInsightId; // Counter for unique insight IDs
    uint256 public nextValidationVoteId; // Counter for unique validation vote IDs
    uint256 public nextParameterProposalId; // Counter for unique parameter proposal IDs
    uint256 public currentEpoch; // Current epoch number
    uint256 public lastEpochEndTime; // Timestamp when the current epoch began

    // Configurable Parameters struct, allowing governance to adjust protocol mechanics
    struct ProtocolParameters {
        uint256 insightSubmissionStake; // AetherTokens required to submit an insight
        uint256 insightRewardAmount;    // AetherTokens awarded for a successfully validated insight
        uint256 curatorStakeAmount;     // AetherTokens required to become a curator
        uint256 minReputationForCurator; // Minimum reputation points needed to become a curator
        uint256 insightValidationDuration; // Duration (in seconds) for which insight votes are open
        uint256 epochDuration;          // Duration (in seconds) of each epoch
        uint256 curatorResignCooldown;  // Cooldown period (in seconds) after a curator resigns before stake can be unstaked
        uint256 minCuratorVotesForValidation; // Minimum total reputation-weighted votes required for an insight validation to pass/fail decisively
        uint256 reputationGainOnValidation; // Reputation points gained by an insight contributor upon successful validation
        uint256 reputationLossOnInvalidation; // Reputation points lost by an insight contributor if their insight is rejected
        uint256 reputationLossOnMisvote; // Reputation points lost by a curator for voting on the losing side of a proposal (simplified)
    }
    ProtocolParameters public params; // Instance of the ProtocolParameters struct

    // --- Data Structures ---

    enum InsightStatus { Submitted, InValidation, Validated, Rejected }

    // Represents a community-contributed piece of AI-related knowledge or data
    struct Insight {
        uint256 id;                 // Unique ID of the insight
        address contributor;        // Address of the user who submitted the insight
        string ipfsHash;            // IPFS hash pointing to the actual insight data/description
        uint256 targetAetherBotId;  // The ID of the AetherBot NFT this insight aims to improve (0 if general)
        bytes32[] tags;             // Categorization or keywords for the insight (e.g., "NLP", "DataQuality")
        uint256 submittedAt;        // Timestamp of submission
        InsightStatus status;       // Current status of the insight (Submitted, InValidation, Validated, Rejected)
        uint256 validationVoteId;   // ID of the validation vote if currently in validation
    }
    mapping(uint256 => Insight) public insights; // Mapping from insight ID to Insight struct
    mapping(address => uint256[]) public contributorInsights; // Contributor address to list of insight IDs they submitted

    // Represents a contributor's profile within the AetherNexus
    struct ContributorProfile {
        uint256 reputation;             // Reputation points of the contributor
        uint256 totalInsightsSubmitted; // Count of insights submitted by this contributor
        uint256 totalInsightsValidated; // Count of insights validated for this contributor
        string ipfsHashToBio;           // IPFS hash for a richer, off-chain contributor profile bio
        uint256 lastEpochClaimed;       // Last epoch for which this contributor claimed rewards
        uint256 curatorStakeLockUntil;  // Timestamp until which curator stake is locked (for resignation cooldown or active status)
    }
    mapping(address => ContributorProfile) public contributorProfiles; // Mapping from address to ContributorProfile

    // Represents a vote to validate or reject an insight
    struct InsightValidationVote {
        uint256 id;                 // Unique ID of the vote
        uint256 insightId;          // ID of the insight being voted on
        address proposer;           // Address of the curator who proposed the vote
        uint256 proposedAt;         // Timestamp when the vote was proposed
        uint256 endsAt;             // Timestamp when the voting period ends
        uint256 yesVotes;           // Sum of reputation-weighted 'yes' votes
        uint256 noVotes;            // Sum of reputation-weighted 'no' votes
        mapping(address => bool) hasVoted; // Mapping from curator address to true if they have voted
        bool tallied;               // True if the vote has been tallied
        bool approved;              // True if the insight was approved (validated)
        uint256 totalCuratorWeight; // Sum of reputation of all curators at the time of proposal, used for quorum/threshold calculations
    }
    mapping(uint256 => InsightValidationVote) public validationVotes; // Mapping from vote ID to InsightValidationVote
    uint256[] public activeValidationVotes; // List of vote IDs currently active and not yet tallied

    // Represents a proposal to change a protocol parameter via governance
    struct ParameterProposal {
        uint256 id;                 // Unique ID of the proposal
        bytes32 parameterName;      // Name of the parameter to change (e.g., "insightSubmissionStake")
        uint256 newValue;           // The proposed new value for the parameter
        address proposer;           // Address of the curator who proposed the change
        uint256 proposedAt;         // Timestamp when the proposal was made
        uint256 endsAt;             // Timestamp when the voting period ends
        uint256 yesVotes;           // Sum of reputation-weighted 'yes' votes
        uint256 noVotes;            // Sum of reputation-weighted 'no' votes
        mapping(address => bool) hasVoted; // Mapping from curator address to true if they have voted
        bool tallied;               // True if the proposal has been tallied
        bool approved;              // True if the proposal was approved
        bool executed;              // True if the parameter change has been applied
        uint256 totalCuratorWeight; // Sum of reputation of all curators at the time of proposal
    }
    mapping(uint256 => ParameterProposal) public parameterProposals; // Mapping from proposal ID to ParameterProposal
    uint256[] public activeParameterProposals; // List of proposal IDs currently active

    mapping(address => bool) public isCuratorActive; // True if address is an active curator
    address[] public activeCuratorList; // List of active curator addresses (for iteration/querying)

    // Epoch-based rewards tracking
    mapping(uint256 => mapping(address => uint256)) public epochContributorRewards; // epoch => contributor => accumulated rewards for that epoch
    mapping(uint256 => uint256) public epochTotalRewardPool; // Total rewards distributed in a specific epoch

    // --- Events ---
    event AetherTokenAddressSet(address indexed _tokenAddress);
    event AetherBotNFTAddressSet(address indexed _nftAddress);
    event InsightSubmitted(uint256 indexed _insightId, address indexed _contributor, uint256 _targetAetherBotId, string _ipfsHash);
    event InsightValidated(uint256 indexed _insightId, address indexed _contributor, uint256 _rewardAmount);
    event InsightRejected(uint256 indexed _insightId);
    event ContributorReputationUpdated(address indexed _contributor, uint256 _newReputation);
    event CuratorJoined(address indexed _curator);
    event CuratorResigned(address indexed _curator);
    event InsightValidationProposed(uint256 indexed _voteId, uint256 indexed _insightId, address indexed _proposer);
    event VoteCast(uint256 indexed _voteId, address indexed _voter, bool _approved);
    event InsightValidationTallyDone(uint256 indexed _voteId, bool _result);
    event AetherBotMinted(uint256 indexed _tokenId, address indexed _owner);
    event AetherBotUpgradeRequested(uint256 indexed _tokenId, uint256 indexed _insightId);
    event AetherBotUpgraded(uint256 indexed _tokenId, uint256 indexed _insightId, string _newState);
    event EpochEnded(uint256 indexed _epoch, uint256 _totalRewardsDistributed);
    event RewardsClaimed(uint256 indexed _epoch, address indexed _contributor, uint256 _amount);
    event ParameterChangeProposed(uint256 indexed _proposalId, bytes32 _parameterName, uint256 _newValue);
    event ParameterChangeExecuted(uint256 indexed _proposalId, bytes32 _parameterName, uint256 _newValue);
    event ContributorBioUpdated(address indexed _contributor, string _ipfsHash);
    event CuratorTokensUnstaked(address indexed _curator, uint256 _amount);

    // --- Modifiers ---
    modifier onlyCurator() {
        require(isCuratorActive[msg.sender], "AetherNexus: Caller is not an active curator.");
        // Ensure curator's stake is not in cooldown (meaning they are actively serving)
        require(contributorProfiles[msg.sender].curatorStakeLockUntil == type(uint256).max, "AetherNexus: Curator's stake is in cooldown.");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the contract with deployer as owner, sets up initial token and NFT contract addresses,
     *      and sets default protocol parameters.
     * @param _initialAetherTokenAddress The address of the AetherToken (ERC20) contract.
     * @param _initialAetherBotNFTAddress The address of the AetherBot (ERC721) NFT contract.
     */
    constructor(address _initialAetherTokenAddress, address _initialAetherBotNFTAddress) Ownable(msg.sender) {
        // Initialize parameters with reasonable defaults. These can be changed via governance.
        params = ProtocolParameters({
            insightSubmissionStake: 100 * (10 ** 18), // 100 AetherTokens (assuming 18 decimals)
            insightRewardAmount: 500 * (10 ** 18),   // 500 AetherTokens
            curatorStakeAmount: 10000 * (10 ** 18),  // 10,000 AetherTokens
            minReputationForCurator: 500,            // Minimum reputation points to qualify as a curator
            insightValidationDuration: 3 days,       // 3 days for insight voting
            epochDuration: 7 days,                   // 7 days per epoch
            curatorResignCooldown: 30 days,          // 30-day cooldown for curator stake release
            minCuratorVotesForValidation: 3,         // Minimum number of reputation-weighted votes required for a decisive validation outcome
            reputationGainOnValidation: 100,         // Reputation gain for validated insight
            reputationLossOnInvalidation: 200,       // Reputation loss for rejected insight
            reputationLossOnMisvote: 25              // Reputation loss for a curator on the losing side of a vote
        });

        nextInsightId = 1;
        nextValidationVoteId = 1;
        nextParameterProposalId = 1;
        currentEpoch = 1;
        lastEpochEndTime = block.timestamp; // Epoch 1 starts at deployment

        setAetherTokenAddress(_initialAetherTokenAddress);
        setAetherBotNFTAddress(_initialAetherBotNFTAddress);
    }

    // --- I. Core Protocol Setup & Control ---

    /**
     * @dev Pauses the contract. Only callable by the owner.
     * Functions marked as `whenNotPaused` will not be executable.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw a specified amount of a token from the contract's balance (treasury).
     * This is typically for managing protocol-owned liquidity or treasury funds.
     * @param _tokenAddress The address of the token to withdraw (use address(0) for native Ether).
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawTreasuryFunds(address _tokenAddress, uint256 _amount) public onlyOwner {
        if (_tokenAddress == address(0)) {
            payable(owner()).transfer(_amount); // Withdraw Ether
        } else {
            IERC20(_tokenAddress).transfer(owner(), _amount); // Withdraw ERC20 tokens
        }
    }

    // --- II. Token & NFT Interaction ---

    /**
     * @dev Sets the address of the AetherToken contract. Only callable by the owner.
     * This is a critical setup function and should be called carefully.
     * @param _tokenAddress The address of the AetherToken (ERC20) contract.
     */
    function setAetherTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "AetherNexus: Invalid token address");
        aetherToken = IAetherToken(_tokenAddress);
        emit AetherTokenAddressSet(_tokenAddress);
    }

    /**
     * @dev Sets the address of the AetherBot NFT contract. Only callable by the owner.
     * This is a critical setup function and should be called carefully.
     * @param _nftAddress The address of the AetherBot (ERC721) contract.
     */
    function setAetherBotNFTAddress(address _nftAddress) public onlyOwner {
        require(_nftAddress != address(0), "AetherNexus: Invalid NFT address");
        aetherBotNFT = IAetherBotNFT(_nftAddress);
        emit AetherBotNFTAddressSet(_nftAddress);
    }

    /**
     * @dev Retrieves the number of AetherBot NFTs owned by a specific address.
     * @param _owner The address of the NFT owner.
     * @return The number of AetherBot NFTs owned.
     */
    function getAetherBotNFTBalance(address _owner) public view returns (uint256) {
        return aetherBotNFT.balanceOf(_owner);
    }

    // --- III. Contributor & Insight Management (Proof-of-Insight) ---

    /**
     * @dev Allows a user to submit an AI-related insight.
     * Requires staking `insightSubmissionStake` AetherTokens, which are held by the contract.
     * These tokens are returned upon successful validation or forfeited if the insight is rejected.
     * @param _ipfsHash IPFS hash referencing the detailed insight data (e.g., dataset link, model code, research paper).
     * @param _targetAetherBotId The ID of the AetherBot NFT this insight aims to improve (0 if general, i.e., not targeting a specific bot).
     * @param _tags An array of bytes32 tags for categorization (e.g., "NLP", "DataQuality", "Optimization").
     */
    function submitInsight(
        string memory _ipfsHash,
        uint256 _targetAetherBotId,
        bytes32[] memory _tags
    ) public whenNotPaused {
        require(address(aetherToken) != address(0), "AetherNexus: AetherToken contract not set.");
        require(aetherToken.balanceOf(msg.sender) >= params.insightSubmissionStake, "AetherNexus: Insufficient AT for stake.");
        require(aetherToken.transferFrom(msg.sender, address(this), params.insightSubmissionStake), "AetherNexus: Token transfer failed. Check allowance.");

        insights[nextInsightId] = Insight({
            id: nextInsightId,
            contributor: msg.sender,
            ipfsHash: _ipfsHash,
            targetAetherBotId: _targetAetherBotId,
            tags: _tags,
            submittedAt: block.timestamp,
            status: InsightStatus.Submitted,
            validationVoteId: 0 // Will be set when a curator proposes validation
        });

        contributorInsights[msg.sender].push(nextInsightId);
        contributorProfiles[msg.sender].totalInsightsSubmitted++;

        emit InsightSubmitted(nextInsightId, msg.sender, _targetAetherBotId, _ipfsHash);
        nextInsightId++;
    }

    /**
     * @dev Retrieves comprehensive details about a specific insight.
     * @param _insightId The ID of the insight to query.
     * @return A tuple containing insight details.
     */
    function getInsightDetails(uint256 _insightId)
        public view
        returns (
            uint256 id,
            address contributor,
            string memory ipfsHash,
            uint256 targetAetherBotId,
            bytes32[] memory tags,
            uint256 submittedAt,
            InsightStatus status,
            uint256 validationVoteId
        )
    {
        Insight storage insight = insights[_insightId];
        require(insight.id != 0, "AetherNexus: Insight does not exist."); // Check if insight exists
        return (
            insight.id,
            insight.contributor,
            insight.ipfsHash,
            insight.targetAetherBotId,
            insight.tags,
            insight.submittedAt,
            insight.status,
            insight.validationVoteId
        );
    }

    /**
     * @dev Fetches a contributor's reputation, total insights submitted, total validated insights, and their bio IPFS hash.
     * @param _contributor The address of the contributor.
     * @return A tuple containing contributor profile details.
     */
    function getContributorProfile(address _contributor)
        public view
        returns (uint256 reputation, uint256 totalInsightsSubmitted, uint256 totalInsightsValidated, string memory ipfsHashToBio)
    {
        ContributorProfile storage profile = contributorProfiles[_contributor];
        return (profile.reputation, profile.totalInsightsSubmitted, profile.totalInsightsValidated, profile.ipfsHashToBio);
    }

    /**
     * @dev Allows contributors to link an IPFS hash to their public profile bio.
     * This enables richer, off-chain profiles to be associated with an on-chain address.
     * @param _ipfsHashToBio The IPFS hash pointing to the contributor's bio/profile data.
     */
    function updateContributorBio(string memory _ipfsHashToBio) public {
        contributorProfiles[msg.sender].ipfsHashToBio = _ipfsHashToBio;
        emit ContributorBioUpdated(msg.sender, _ipfsHashToBio);
    }

    // --- IV. Validation & Curation System ---

    /**
     * @dev Allows a user to become a curator.
     * Requires staking `curatorStakeAmount` AetherTokens and meeting `minReputationForCurator`.
     * The stake is locked indefinitely until the curator resigns and the cooldown period passes.
     */
    function becomeCurator() public whenNotPaused {
        require(address(aetherToken) != address(0), "AetherNexus: AetherToken contract not set.");
        require(!isCuratorActive[msg.sender], "AetherNexus: Caller is already an active curator.");
        require(contributorProfiles[msg.sender].reputation >= params.minReputationForCurator, "AetherNexus: Not enough reputation to become a curator.");
        require(aetherToken.balanceOf(msg.sender) >= params.curatorStakeAmount, "AetherNexus: Insufficient AT for curator stake.");
        require(aetherToken.transferFrom(msg.sender, address(this), params.curatorStakeAmount), "AetherNexus: Token transfer failed. Check allowance.");

        isCuratorActive[msg.sender] = true;
        activeCuratorList.push(msg.sender);
        contributorProfiles[msg.sender].curatorStakeLockUntil = type(uint256).max; // Lock indefinitely
        emit CuratorJoined(msg.sender);
    }

    /**
     * @dev Allows an active curator to resign.
     * This sets their status to inactive and starts a cooldown period (`curatorResignCooldown`)
     * during which their staked tokens remain locked. After cooldown, they can call `unstakeCuratorTokens`.
     */
    function resignCurator() public whenNotPaused onlyCurator {
        // Mark as inactive
        isCuratorActive[msg.sender] = false;
        
        // Remove from activeCuratorList (simple but O(N) for large lists;
        // for very large activeCuratorList, a more complex data structure would be needed)
        for (uint i = 0; i < activeCuratorList.length; i++) {
            if (activeCuratorList[i] == msg.sender) {
                activeCuratorList[i] = activeCuratorList[activeCuratorList.length - 1];
                activeCuratorList.pop();
                break;
            }
        }
        
        // Set cooldown timestamp for stake release
        contributorProfiles[msg.sender].curatorStakeLockUntil = block.timestamp + params.curatorResignCooldown;
        emit CuratorResigned(msg.sender);
    }

    /**
     * @dev A curator proposes a specific insight for validation voting.
     * The insight must be in 'Submitted' status and cannot be proposed by its contributor.
     * This creates a new vote with a set duration.
     * @param _insightId The ID of the insight to be validated.
     */
    function proposeInsightValidation(uint256 _insightId) public whenNotPaused onlyCurator {
        Insight storage insight = insights[_insightId];
        require(insight.id != 0, "AetherNexus: Insight does not exist.");
        require(insight.status == InsightStatus.Submitted, "AetherNexus: Insight not in 'Submitted' status.");
        require(insight.contributor != msg.sender, "AetherNexus: Curator cannot propose their own insight for validation.");

        // Calculate total reputation weight of all active curators at the time of proposal
        // This is important for determining the necessary quorum for voting.
        uint256 totalCuratorReputation = 0;
        for(uint i = 0; i < activeCuratorList.length; i++) {
            totalCuratorReputation += contributorProfiles[activeCuratorList[i]].reputation;
        }
        require(totalCuratorReputation > 0, "AetherNexus: No active curators or total curator reputation is zero.");

        validationVotes[nextValidationVoteId] = InsightValidationVote({
            id: nextValidationVoteId,
            insightId: _insightId,
            proposer: msg.sender,
            proposedAt: block.timestamp,
            endsAt: block.timestamp + params.insightValidationDuration,
            yesVotes: 0,
            noVotes: 0,
            totalCuratorWeight: totalCuratorReputation,
            tallied: false,
            approved: false,
            hasVoted: new mapping(address => bool) // Initialize mapping for voters
        });

        insight.status = InsightStatus.InValidation;
        insight.validationVoteId = nextValidationVoteId;
        activeValidationVotes.push(nextValidationVoteId);

        emit InsightValidationProposed(nextValidationVoteId, _insightId, msg.sender);
        nextValidationVoteId++;
    }

    /**
     * @dev Active curators cast their vote (approve/reject) on a proposed insight validation.
     * Each vote's weight is determined by the curator's current reputation.
     * @param _voteId The ID of the validation vote.
     * @param _approve True for 'yes' (approve the insight), false for 'no' (reject the insight).
     */
    function castValidationVote(uint256 _voteId, bool _approve) public whenNotPaused onlyCurator {
        InsightValidationVote storage vote = validationVotes[_voteId];
        require(vote.id != 0, "AetherNexus: Validation vote does not exist.");
        require(block.timestamp < vote.endsAt, "AetherNexus: Voting period has ended.");
        require(!vote.tallied, "AetherNexus: Vote has already been tallied.");
        require(!vote.hasVoted[msg.sender], "AetherNexus: Caller has already voted.");

        vote.hasVoted[msg.sender] = true;
        uint256 voterReputation = contributorProfiles[msg.sender].reputation;
        if (_approve) {
            vote.yesVotes += voterReputation; // Add reputation to 'yes' votes
        } else {
            vote.noVotes += voterReputation; // Add reputation to 'no' votes
        }
        emit VoteCast(_voteId, msg.sender, _approve);
    }

    /**
     * @dev Triggers the tallying of votes for a specific insight.
     * This function can be called by anyone after the voting period has ended.
     * If the insight is approved, the contributor receives their stake back plus a reward,
     * their reputation increases, and the targeted AetherBot (if any) can evolve.
     * If rejected, the contributor forfeits their stake and their reputation is penalized.
     * @param _voteId The ID of the validation vote to tally.
     */
    function tallyInsightValidation(uint256 _voteId) public whenNotPaused {
        InsightValidationVote storage vote = validationVotes[_voteId];
        require(vote.id != 0, "AetherNexus: Validation vote does not exist.");
        require(block.timestamp >= vote.endsAt, "AetherNexus: Voting period not ended yet.");
        require(!vote.tallied, "AetherNexus: Vote has already been tallied.");
        // Ensure a minimum number of reputation-weighted votes have been cast for a decisive outcome
        require(vote.yesVotes + vote.noVotes >= params.minCuratorVotesForValidation, "AetherNexus: Not enough votes to tally.");

        vote.tallied = true;
        Insight storage insight = insights[vote.insightId];
        address insightContributor = insight.contributor;

        // Determine outcome based on reputation-weighted votes
        bool passed = vote.yesVotes > vote.noVotes;
        vote.approved = passed;

        // Apply consequences for the insight contributor
        if (passed) {
            insight.status = InsightStatus.Validated;
            contributorProfiles[insightContributor].reputation += params.reputationGainOnValidation;
            contributorProfiles[insightContributor].totalInsightsValidated++;

            // Return stake and reward contributor
            aetherToken.transfer(insightContributor, params.insightSubmissionStake + params.insightRewardAmount);
            epochContributorRewards[currentEpoch][insightContributor] += params.insightRewardAmount; // Track for epoch rewards
            epochTotalRewardPool[currentEpoch] += params.insightRewardAmount; // Aggregate total rewards for the epoch

            emit InsightValidated(insight.id, insightContributor, params.insightRewardAmount);
        } else {
            insight.status = InsightStatus.Rejected;
            // Penalize reputation, ensuring it doesn't go below zero
            contributorProfiles[insightContributor].reputation = contributorProfiles[insightContributor].reputation > params.reputationLossOnInvalidation
                ? contributorProfiles[insightContributor].reputation - params.reputationLossOnInvalidation
                : 0;
            // Insight submission stake is NOT returned (forfeited)
            emit InsightRejected(insight.id);
        }

        emit ContributorReputationUpdated(insightContributor, contributorProfiles[insightContributor].reputation);
        emit InsightValidationTallyDone(_voteId, passed);

        // Remove from activeValidationVotes list (similar O(N) approach as in resignCurator)
        for (uint i = 0; i < activeValidationVotes.length; i++) {
            if (activeValidationVotes[i] == _voteId) {
                activeValidationVotes[i] = activeValidationVotes[activeValidationVotes.length - 1];
                activeValidationVotes.pop();
                break;
            }
        }
    }

    // --- V. AetherBot Dynamic NFT Evolution ---

    /**
     * @dev Allows users to mint a new AetherBot NFT.
     * Currently implemented as free to mint, but could be extended to require AetherTokens or reputation.
     * @return The ID of the newly minted AetherBot.
     */
    function mintAetherBot() public whenNotPaused returns (uint256) {
        require(address(aetherBotNFT) != address(0), "AetherNexus: AetherBot NFT contract not set.");
        uint256 newTokenId = aetherBotNFT.mint(msg.sender);
        emit AetherBotMinted(newTokenId, msg.sender);
        return newTokenId;
    }

    /**
     * @dev Retrieves the current dynamic traits of an AetherBot NFT.
     * Uses the `IAetherBotNFT` interface to query the NFT contract directly.
     * @param _aetherBotId The ID of the AetherBot to query.
     * @return A struct containing the AetherBot's traits.
     */
    function getAetherBotTraits(uint256 _aetherBotId) public view returns (IAetherBotNFT.AetherBotTraits memory) {
        require(address(aetherBotNFT) != address(0), "AetherNexus: AetherBot NFT contract not set.");
        return aetherBotNFT.getTraits(_aetherBotId);
    }

    /**
     * @dev An AetherBot owner requests an upgrade for their AetherBot using a previously validated insight.
     * The insight must be in 'Validated' status and optionally targeted at an AetherBot.
     * This function checks conditions and then calls an internal function to apply the trait update.
     * @param _aetherBotId The ID of the AetherBot to upgrade.
     * @param _insightId The ID of the validated insight to apply.
     */
    function requestAetherBotUpgrade(uint256 _aetherBotId, uint256 _insightId) public whenNotPaused {
        require(address(aetherBotNFT) != address(0), "AetherNexus: AetherBot NFT contract not set.");
        require(aetherBotNFT.ownerOf(_aetherBotId) == msg.sender, "AetherNexus: Caller is not the owner of this AetherBot.");
        Insight storage insight = insights[_insightId];
        require(insight.id != 0, "AetherNexus: Insight does not exist.");
        require(insight.status == InsightStatus.Validated, "AetherNexus: Insight must be validated to be applied.");
        // Optional: Add logic to ensure the insight is relevant to the AetherBot (e.g., matching tags or target ID)
        // require(insight.targetAetherBotId == 0 || insight.targetAetherBotId == _aetherBotId, "AetherNexus: Insight not targeted for this AetherBot.");

        _applyAetherBotUpgrade(_aetherBotId, _insightId);
        emit AetherBotUpgradeRequested(_aetherBotId, _insightId);
    }

    /**
     * @dev Internal function to apply the traits update to an AetherBot NFT.
     * This is called after a successful insight validation (implicitly via `tallyInsightValidation`
     * if an upgrade is requested) or an explicit `requestAetherBotUpgrade`.
     * The logic for how traits evolve can be complex and depends on the game mechanics.
     * @param _aetherBotId The ID of the AetherBot.
     * @param _insightId The ID of the insight that led to the upgrade.
     */
    function _applyAetherBotUpgrade(uint256 _aetherBotId, uint256 _insightId) internal {
        // Fetch current traits from the AetherBot NFT contract
        IAetherBotNFT.AetherBotTraits memory currentTraits = aetherBotNFT.getTraits(_aetherBotId);

        // --- Dynamic Trait Evolution Logic ---
        // This is a simplified example of how traits change. In a real system:
        // - `performanceFactor` could increase based on the type/quality of insight.
        // - `currentEvolutionState` could change based on `insightAppliedCount` or `performanceFactor` thresholds.
        // - `generation` might increment for major, transformative insights.
        // - `metadataURI` would ideally be updated to point to new IPFS metadata reflecting visual changes.

        currentTraits.insightAppliedCount++;
        currentTraits.performanceFactor = currentTraits.performanceFactor + 10; // Simple increment for demonstration
        
        // Example: Change evolution state based on applied insights
        if (currentTraits.insightAppliedCount >= 10 && keccak256(abi.encodePacked(currentTraits.currentEvolutionState)) != keccak256(abi.encodePacked("Mature"))) {
            currentTraits.currentEvolutionState = "Mature";
            currentTraits.generation++; // Major evolution
        } else if (currentTraits.insightAppliedCount >= 3 && keccak256(abi.encodePacked(currentTraits.currentEvolutionState)) != keccak256(abi.encodePacked("Juvenile"))) {
            currentTraits.currentEvolutionState = "Juvenile";
        } else if (keccak256(abi.encodePacked(currentTraits.currentEvolutionState)) == keccak256(abi.encodePacked(""))) {
            currentTraits.currentEvolutionState = "Seedling"; // Initial state if not set
        }

        // Placeholder for updating metadataURI - this would typically involve an off-chain service
        // that generates new metadata JSON and uploads to IPFS, then provides the hash here.
        // currentTraits.metadataURI = "ipfs://new_hash_for_updated_metadata_json";

        // Update the traits on the AetherBot NFT contract
        aetherBotNFT.updateTraits(_aetherBotId, currentTraits);
        emit AetherBotUpgraded(_aetherBotId, _insightId, currentTraits.currentEvolutionState);
    }

    // --- VI. Epoch Management & Reward Distribution ---

    /**
     * @dev Advances the protocol to the next epoch.
     * This function should be called periodically (e.g., by an automated service or the owner)
     * after the `epochDuration` has passed. It primarily signals the end of an epoch,
     * making accumulated rewards claimable and resetting for the next period.
     * In a full DAO, this would be triggered by a decentralized keeper network or time-based execution.
     */
    function endCurrentEpoch() public whenNotPaused onlyOwner { // Simplified to onlyOwner for now
        require(block.timestamp >= lastEpochEndTime + params.epochDuration, "AetherNexus: Epoch has not ended yet.");

        uint256 prevEpoch = currentEpoch;
        currentEpoch++;
        lastEpochEndTime = block.timestamp;

        // Note: Rewards are primarily distributed (and accumulated in `epochContributorRewards`)
        // at the time of insight validation. This function simply marks the end of the epoch,
        // making those accumulated rewards claimable for the concluded epoch.
        // Additional epoch-wide rewards (e.g., from a community pool) could be calculated here.

        emit EpochEnded(prevEpoch, epochTotalRewardPool[prevEpoch]); // Emitting total rewards that were processed for the previous epoch
    }

    /**
     * @dev Allows contributors to claim their AetherToken rewards for a specific past epoch.
     * Rewards are accumulated during the epoch (e.g., from validated insights) and can be claimed after it ends.
     * @param _epoch The epoch number for which to claim rewards.
     */
    function claimEpochRewards(uint256 _epoch) public whenNotPaused {
        require(_epoch < currentEpoch, "AetherNexus: Cannot claim for current or future epochs.");
        require(contributorProfiles[msg.sender].lastEpochClaimed < _epoch, "AetherNexus: Rewards for this epoch already claimed.");

        uint256 amount = epochContributorRewards[_epoch][msg.sender];
        require(amount > 0, "AetherNexus: No rewards available for this epoch.");

        epochContributorRewards[_epoch][msg.sender] = 0; // Set to zero to prevent double claim
        contributorProfiles[msg.sender].lastEpochClaimed = _epoch; // Mark this epoch as claimed
        
        aetherToken.transfer(msg.sender, amount); // Transfer the AetherTokens to the claimant
        emit RewardsClaimed(_epoch, msg.sender, amount);
    }

    /**
     * @dev Returns the current active epoch number.
     * @return The current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    // --- VII. Governance & Parameter Configuration ---

    /**
     * @dev Curators or high-reputation users can propose changes to core contract parameters.
     * This initiates a voting process among active curators.
     * @param _parameterName The name of the parameter to change (e.g., "insightSubmissionStake").
     * @param _newValue The new proposed value for the parameter.
     */
    function proposeParameterChange(bytes32 _parameterName, uint256 _newValue) public whenNotPaused onlyCurator {
        // Strict allowlist for changeable parameters to prevent arbitrary modifications
        bool isValidParam = false;
        if (_parameterName == "insightSubmissionStake" ||
            _parameterName == "insightRewardAmount" ||
            _parameterName == "curatorStakeAmount" ||
            _parameterName == "minReputationForCurator" ||
            _parameterName == "insightValidationDuration" ||
            _parameterName == "epochDuration" ||
            _parameterName == "curatorResignCooldown" ||
            _parameterName == "minCuratorVotesForValidation" ||
            _parameterName == "reputationGainOnValidation" ||
            _parameterName == "reputationLossOnInvalidation" ||
            _parameterName == "reputationLossOnMisvote") {
            isValidParam = true;
        }
        require(isValidParam, "AetherNexus: Invalid parameter name.");

        uint256 totalCuratorReputation = 0;
        for(uint i = 0; i < activeCuratorList.length; i++) {
            totalCuratorReputation += contributorProfiles[activeCuratorList[i]].reputation;
        }
        require(totalCuratorReputation > 0, "AetherNexus: No active curators or total curator reputation is zero.");

        parameterProposals[nextParameterProposalId] = ParameterProposal({
            id: nextParameterProposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            proposer: msg.sender,
            proposedAt: block.timestamp,
            endsAt: block.timestamp + params.insightValidationDuration, // Reusing insight validation duration for parameter proposals
            yesVotes: 0,
            noVotes: 0,
            totalCuratorWeight: totalCuratorReputation,
            tallied: false,
            approved: false,
            executed: false,
            hasVoted: new mapping(address => bool)
        });

        activeParameterProposals.push(nextParameterProposalId);
        emit ParameterChangeProposed(nextParameterProposalId, _parameterName, _newValue);
        nextParameterProposalId++;
    }

    /**
     * @dev Curators vote on a proposed parameter change.
     * Their vote weight is based on their current reputation.
     * @param _proposalId The ID of the parameter change proposal.
     * @param _approve True for 'yes' (approve the change), false for 'no' (reject the change).
     */
    function voteOnParameterChange(uint256 _proposalId, bool _approve) public whenNotPaused onlyCurator {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.id != 0, "AetherNexus: Parameter proposal does not exist.");
        require(block.timestamp < proposal.endsAt, "AetherNexus: Voting period has ended.");
        require(!proposal.tallied, "AetherNexus: Proposal has already been tallied.");
        require(!proposal.hasVoted[msg.sender], "AetherNexus: Caller has already voted.");

        proposal.hasVoted[msg.sender] = true;
        uint256 voterReputation = contributorProfiles[msg.sender].reputation;
        if (_approve) {
            proposal.yesVotes += voterReputation;
        } else {
            proposal.noVotes += voterReputation;
        }
        emit VoteCast(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes a successfully voted parameter change.
     * This function can be called by anyone after the voting period ends and if the proposal was approved.
     * It applies the new value to the corresponding protocol parameter.
     * @param _proposalId The ID of the parameter change proposal.
     */
    function executeParameterChange(uint256 _proposalId) public whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.id != 0, "AetherNexus: Parameter proposal does not exist.");
        require(block.timestamp >= proposal.endsAt, "AetherNexus: Voting period not ended yet.");
        require(!proposal.executed, "AetherNexus: Proposal already executed.");

        // Tally if not already tallied
        if (!proposal.tallied) {
            proposal.tallied = true;
            // A simple majority vote based on reputation weight
            proposal.approved = proposal.yesVotes > proposal.noVotes;
            // Could add a minimum quorum check here as well: && (proposal.yesVotes + proposal.noVotes) >= requiredQuorum
        }

        require(proposal.approved, "AetherNexus: Proposal was not approved or did not meet quorum.");

        // Apply the parameter change based on its name
        if (proposal.parameterName == "insightSubmissionStake") {
            params.insightSubmissionStake = proposal.newValue;
        } else if (proposal.parameterName == "insightRewardAmount") {
            params.insightRewardAmount = proposal.newValue;
        } else if (proposal.parameterName == "curatorStakeAmount") {
            params.curatorStakeAmount = proposal.newValue;
        } else if (proposal.parameterName == "minReputationForCurator") {
            params.minReputationForCurator = proposal.newValue;
        } else if (proposal.parameterName == "insightValidationDuration") {
            params.insightValidationDuration = proposal.newValue;
        } else if (proposal.parameterName == "epochDuration") {
            params.epochDuration = proposal.newValue;
        } else if (proposal.parameterName == "curatorResignCooldown") {
            params.curatorResignCooldown = proposal.newValue;
        } else if (proposal.parameterName == "minCuratorVotesForValidation") {
            params.minCuratorVotesForValidation = proposal.newValue;
        } else if (proposal.parameterName == "reputationGainOnValidation") {
            params.reputationGainOnValidation = proposal.newValue;
        } else if (proposal.parameterName == "reputationLossOnInvalidation") {
            params.reputationLossOnInvalidation = proposal.newValue;
        } else if (proposal.parameterName == "reputationLossOnMisvote") {
            params.reputationLossOnMisvote = proposal.newValue;
        } else {
            revert("AetherNexus: Unknown parameter for execution."); // Should not happen if proposer checks are good
        }

        proposal.executed = true;
        emit ParameterChangeExecuted(proposal.id, proposal.parameterName, proposal.newValue);

        // Remove from activeParameterProposals list
        for (uint i = 0; i < activeParameterProposals.length; i++) {
            if (activeParameterProposals[i] == _proposalId) {
                activeParameterProposals[i] = activeParameterProposals[activeParameterProposals.length - 1];
                activeParameterProposals.pop();
                break;
            }
        }
    }

    // --- VIII. Utility & Query Functions ---

    /**
     * @dev Returns a struct containing all current configurable parameters of the contract.
     * Useful for DApps to display current protocol settings.
     * @return A ProtocolParameters struct.
     */
    function getContractParameters() public view returns (ProtocolParameters memory) {
        return params;
    }

    /**
     * @dev Returns a list of insight IDs that are currently undergoing validation voting.
     * @return An array of active validation vote IDs.
     */
    function getPendingValidationVotes() public view returns (uint256[] memory) {
        return activeValidationVotes;
    }

    /**
     * @dev Checks if an address is an active curator.
     * An address is considered an active curator if `isCuratorActive` is true AND
     * their `curatorStakeLockUntil` is `type(uint256).max` (meaning their stake is locked and they are active).
     * @param _addr The address to check.
     * @return True if the address is an active curator, false otherwise.
     */
    function isCurator(address _addr) public view returns (bool) {
        return isCuratorActive[_addr] && contributorProfiles[_addr].curatorStakeLockUntil == type(uint256).max;
    }

    /**
     * @dev Returns the required stake amount (in AetherTokens) to become a curator.
     * @return The curator stake amount in AetherTokens (wei).
     */
    function getCuratorStakeAmount() public view returns (uint256) {
        return params.curatorStakeAmount;
    }

    /**
     * @dev Returns the required stake amount (in AetherTokens) to submit an insight.
     * @return The insight submission stake amount in AetherTokens (wei).
     */
    function getInsightStakeAmount() public view returns (uint256) {
        return params.insightSubmissionStake;
    }

    /**
     * @dev Allows a former curator to unstake their locked tokens after the `curatorResignCooldown` period has passed.
     * This function is separate from `resignCurator` to enforce the cooldown.
     */
    function unstakeCuratorTokens() public whenNotPaused {
        require(!isCuratorActive[msg.sender], "AetherNexus: Cannot unstake while active curator.");
        require(contributorProfiles[msg.sender].curatorStakeLockUntil != 0, "AetherNexus: No pending unstake or already unstaked.");
        require(contributorProfiles[msg.sender].curatorStakeLockUntil != type(uint256).max, "AetherNexus: Curator is still active (stake not in cooldown).");
        require(block.timestamp >= contributorProfiles[msg.sender].curatorStakeLockUntil, "AetherNexus: Cooldown period not over yet.");

        contributorProfiles[msg.sender].curatorStakeLockUntil = 0; // Reset the lock
        aetherToken.transfer(msg.sender, params.curatorStakeAmount); // Return the staked tokens
        emit CuratorTokensUnstaked(msg.sender, params.curatorStakeAmount);
    }
}
```