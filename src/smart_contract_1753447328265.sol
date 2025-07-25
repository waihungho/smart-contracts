The "Nexus Mind" smart contract represents a novel concept: a decentralized network of "Cognitive Assets" (represented as NFTs) that evolve, interact, and generate collective "insights" based on user prompts and a unique "alignment" feedback loop. It simulates the dynamics of AI training and collective intelligence through economic incentives and on-chain state changes, without performing actual AI computation on-chain.

### Contract Name: `NexusMind`

### Outline:

1.  **Core Contracts:**
    *   `NexusComputeToken.sol` (ERC20): The utility token for the network.
    *   `NexusMind.sol`: The main contract handling NFT logic, prompts, insights, and network economics.
2.  **Data Structures:**
    *   `CognitiveAsset`: Represents an NFT with evolving attributes (`alignmentScore`, `processingPower`, `genesisVectorURI`).
    *   `Prompt`: A task or question submitted by a user with a reward pool.
    *   `ProposedInsight`: A "solution" submitted by a Cognitive Asset for a prompt, subject to community voting.
3.  **Key Mechanisms:**
    *   **Dynamic NFTs:** Cognitive Assets are NFTs whose attributes change based on user interactions and network activity.
    *   **Decentralized Alignment/Fine-tuning:** Users can influence an asset's `alignmentScore` via fees, simulating a training feedback loop.
    *   **Resource Management:** A dedicated `NexusComputeToken` (NCT) is used for staking to boost asset `processingPower` and for rewards/fees.
    *   **Collective Insight Generation:** Users create prompts, assets get assigned, submit insights, and the community votes to determine the best ones, leading to reward distribution and asset attribute updates.
    *   **Time-based Decay:** Asset `processingPower` can decay over time, encouraging continuous engagement.
    *   **Modular Reward System:** Configurable reward distribution for insights.

### Function Summary:

**I. Deployment & Configuration (4 functions)**

1.  `constructor(address _nctAddress)`: Deploys the contract, setting the Nexus Compute Token address.
2.  `setNexusComputeTokenAddress(address _nctAddress)`: Admin function to set or update the address of the Nexus Compute Token.
3.  `setPromptCreationFee(uint256 _fee)`: Admin function to set the fee required to create a new prompt.
4.  `setTuningFee(uint256 _fee)`: Admin function to set the fee for aligning/fine-tuning a Cognitive Asset.

**II. Cognitive Asset (NFT) Management (ERC721 Extension) (7 functions)**

5.  `mintCognitiveAsset(string memory _genesisVectorURI)`: Mints a new unique Cognitive Asset NFT with an initial `genesisVectorURI` (e.g., IPFS hash of initial traits/concept).
6.  `alignCognitiveAsset(uint256 _tokenId, int256 _alignmentDelta)`: Allows a user to influence the `alignmentScore` of a Cognitive Asset by paying a fee. This simulates a "fine-tuning" operation.
7.  `stakeForProcessingPower(uint256 _tokenId, uint256 _amount)`: Users stake NCT tokens to a specific Cognitive Asset to increase its `processingPower`.
8.  `unstakeFromProcessingPower(uint256 _tokenId, uint256 _amount)`: Allows users to withdraw their staked NCT from a Cognitive Asset.
9.  `getAssetDetails(uint256 _tokenId)`: View function to retrieve comprehensive details of a Cognitive Asset (owner, scores, URI).
10. `getAssetStakedAmount(uint256 _tokenId)`: View function to get the total NCT staked to a particular Cognitive Asset.
11. `decayProcessingPower(uint256 _tokenId)`: Reduces an asset's `processingPower` based on time elapsed since last decay, encouraging re-staking.

**III. Prompt & Insight Generation (Core Logic) (9 functions)**

12. `createPrompt(string memory _promptURI, uint256 _rewardPoolAmount)`: Users create a new prompt, locking `_rewardPoolAmount` in NCT, and providing a URI for the prompt's details (e.g., IPFS hash of a question/task).
13. `assignAssetToPrompt(uint256 _tokenId, uint256 _promptId)`: A Cognitive Asset owner assigns their asset to work on a specific active prompt. Requires a minimum `processingPower`.
14. `submitProposedInsight(uint256 _tokenId, uint256 _promptId, string memory _insightURI)`: An asset owner, having assigned their asset, submits their "solution" (`_insightURI`) for the prompt. This requires the asset to meet `processingPower` and `alignmentScore` criteria.
15. `voteOnInsightAlignment(uint256 _insightId, bool _isAligned)`: Users vote on a proposed insight's perceived alignment with the prompt (`_isAligned` = true for upvote, false for downvote). Voters may pay a small fee or be rewarded from the prompt pool for "correct" votes.
16. `finalizePrompt(uint256 _promptId)`: Callable by the prompt creator after a specific duration. This function determines the top-voted insights, distributes rewards from the prompt pool, and updates the `alignmentScore` of participating assets based on their insights' performance.
17. `getPromptDetails(uint256 _promptId)`: View function to retrieve information about a specific prompt.
18. `getProposedInsightDetails(uint256 _insightId)`: View function to get details of a submitted insight, including its votes.
19. `getTopInsightsForPrompt(uint256 _promptId, uint256 _count)`: View function to retrieve a list of the top `_count` insights for a given prompt, sorted by net votes.

**IV. Network & Treasury Management (5 functions)**

20. `withdrawRewardPool(uint256 _promptId)`: Allows the prompt creator to withdraw any remaining unspent NCT from their prompt's reward pool if the prompt is cancelled or not finalized.
21. `setMinProcessingPowerForAssignment(uint256 _minPower)`: Admin function to set the minimum `processingPower` an asset must have to be assigned to a prompt.
22. `setRewardDistributionStrategy(uint256[] memory _percentages)`: Admin function to configure how the `finalizePrompt` function distributes rewards among the top insights (e.g., `[50, 30, 20]` for top 3 insights).
23. `pause()`: Admin only, emergency function to pause all critical operations of the contract.
24. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Admin only, allows withdrawal of collected fees from the contract's treasury to a specified address.

---

### `NexusComputeToken.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NexusComputeToken
 * @dev An ERC20 token used within the NexusMind ecosystem for staking, fees, and rewards.
 */
contract NexusComputeToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Nexus Compute Token", "NCT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    // No advanced features for this simple token, its primary role is utility in NexusMind.
    // Minting and burning functionality could be added if needed by NexusMind.
}

```

### `NexusMind.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NexusMind
 * @dev A decentralized network for evolving Cognitive Assets (NFTs) that collaboratively generate insights.
 *      It simulates AI training and collective intelligence through economic incentives and on-chain state changes.
 */
contract NexusMind is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    IERC20 public nexusComputeToken; // The ERC20 token used for staking, fees, and rewards

    uint256 public promptCreationFee; // Fee to create a prompt, in NCT
    uint256 public tuningFee;         // Fee to align/fine-tune a Cognitive Asset, in NCT
    uint256 public minProcessingPowerForAssignment; // Minimum processing power for an asset to be assigned to a prompt

    // Defines how rewards are distributed among top insights (e.g., [50, 30, 20] for top 3)
    // Sum of percentages should typically be 100.
    uint256[] public rewardDistributionStrategy;

    // --- Counters for unique IDs ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _promptIdCounter;
    Counters.Counter private _insightIdCounter;

    // --- Structs ---

    /**
     * @dev Represents a Cognitive Asset NFT.
     * @param genesisVectorURI IPFS hash or URL pointing to the asset's initial, immutable characteristics.
     * @param alignmentScore A score reflecting how well the asset aligns with user feedback/intent. Influenced by tuning and insight performance.
     * @param processingPower The asset's capacity to participate in insight generation, boosted by NCT staking.
     * @param lastProcessingPowerDecayBlock The block number when processingPower was last decayed.
     */
    struct CognitiveAsset {
        string genesisVectorURI;
        int256 alignmentScore; // Can be negative or positive
        uint256 processingPower;
        uint256 lastProcessingPowerDecayBlock;
    }

    /**
     * @dev Represents a prompt (a question or task) submitted by a user.
     * @param creator The address of the prompt creator.
     * @param promptURI IPFS hash or URL pointing to the prompt's details/description.
     * @param rewardPool The total NCT locked for this prompt, to be distributed to insights.
     * @param submissionDeadline Block number after which no more insights can be submitted.
     * @param votingDeadline Block number after which no more votes can be cast.
     * @param finalized True if the prompt has been finalized and rewards distributed.
     * @param assignedAssets Mapping of tokenId => true if asset is assigned to this prompt.
     */
    struct Prompt {
        address creator;
        string promptURI;
        uint256 rewardPool;
        uint256 submissionDeadline;
        uint256 votingDeadline;
        bool finalized;
        mapping(uint256 => bool) assignedAssets; // Track assets working on this prompt
    }

    /**
     * @dev Represents an insight proposed by a Cognitive Asset for a specific prompt.
     * @param tokenId The ID of the Cognitive Asset that proposed this insight.
     * @param promptId The ID of the prompt this insight addresses.
     * @param insightURI IPFS hash or URL pointing to the insight's details/solution.
     * @param submittedBlock The block number when this insight was submitted.
     * @param upvotes Count of upvotes received.
     * @param downvotes Count of downvotes received.
     * @param voters Mapping of voter address => true to prevent duplicate votes.
     */
    struct ProposedInsight {
        uint256 tokenId;
        uint256 promptId;
        string insightURI;
        uint256 submittedBlock;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) voters;
    }

    // --- Mappings ---
    mapping(uint256 => CognitiveAsset) public cognitiveAssets;
    mapping(uint256 => uint256) public assetStakedNCT; // tokenId => amount of NCT staked
    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => ProposedInsight) public insights;

    // --- Events ---
    event CognitiveAssetMinted(uint256 indexed tokenId, address indexed owner, string genesisVectorURI);
    event AssetAlignmentUpdated(uint256 indexed tokenId, int256 newAlignmentScore, int256 delta);
    event ProcessingPowerStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event ProcessingPowerUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event PromptCreated(uint256 indexed promptId, address indexed creator, string promptURI, uint256 rewardPool);
    event AssetAssignedToPrompt(uint256 indexed tokenId, uint256 indexed promptId);
    event InsightSubmitted(uint256 indexed insightId, uint256 indexed tokenId, uint256 indexed promptId, string insightURI);
    event InsightVoted(uint256 indexed insightId, address indexed voter, bool isAligned);
    event PromptFinalized(uint256 indexed promptId, uint256 distributedRewards);
    event TreasuryFundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---

    /**
     * @dev Constructor for the NexusMind contract.
     * @param _nctAddress The address of the NexusComputeToken ERC20 contract.
     */
    constructor(address _nctAddress) ERC721("Cognitive Asset", "CAN") Ownable(msg.sender) {
        require(_nctAddress != address(0), "NCT address cannot be zero");
        nexusComputeToken = IERC20(_nctAddress);

        // Initial default parameters
        promptCreationFee = 100 * (10 ** 18); // 100 NCT
        tuningFee = 10 * (10 ** 18);         // 10 NCT
        minProcessingPowerForAssignment = 100; // Example: 100 processing power
        rewardDistributionStrategy = [50, 30, 20]; // 50% to #1, 30% to #2, 20% to #3
    }

    // --- I. Deployment & Configuration ---

    /**
     * @dev Admin function to set or update the address of the NexusComputeToken.
     * @param _nctAddress The new address for the NexusComputeToken.
     */
    function setNexusComputeTokenAddress(address _nctAddress) external onlyOwner {
        require(_nctAddress != address(0), "NCT address cannot be zero");
        nexusComputeToken = IERC20(_nctAddress);
    }

    /**
     * @dev Admin function to set the fee for creating a new prompt.
     * @param _fee The new prompt creation fee in NCT.
     */
    function setPromptCreationFee(uint256 _fee) external onlyOwner {
        promptCreationFee = _fee;
    }

    /**
     * @dev Admin function to set the fee for aligning/fine-tuning a Cognitive Asset.
     * @param _fee The new tuning fee in NCT.
     */
    function setTuningFee(uint256 _fee) external onlyOwner {
        tuningFee = _fee;
    }

    // --- II. Cognitive Asset (NFT) Management ---

    /**
     * @dev Mints a new Cognitive Asset NFT.
     * @param _genesisVectorURI The URI (e.g., IPFS hash) describing the asset's initial traits.
     * @return The ID of the newly minted asset.
     */
    function mintCognitiveAsset(string memory _genesisVectorURI) external whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();

        // Initial asset attributes
        cognitiveAssets[newId] = CognitiveAsset({
            genesisVectorURI: _genesisVectorURI,
            alignmentScore: 0, // Starts neutral
            processingPower: 0,
            lastProcessingPowerDecayBlock: block.number
        });

        _mint(msg.sender, newId);
        emit CognitiveAssetMinted(newId, msg.sender, _genesisVectorURI);
        return newId;
    }

    /**
     * @dev Allows a user to influence the `alignmentScore` of a Cognitive Asset.
     *      Requires a fee in NCT. Simulates fine-tuning or feedback.
     * @param _tokenId The ID of the Cognitive Asset to align.
     * @param _alignmentDelta The amount to change the alignment score (can be positive or negative).
     */
    function alignCognitiveAsset(uint256 _tokenId, int256 _alignmentDelta) external whenNotPaused nonReentrant {
        require(_exists(_tokenId), "Asset does not exist");
        require(nexusComputeToken.transferFrom(msg.sender, address(this), tuningFee), "NCT transfer failed for tuning fee");

        int256 currentScore = cognitiveAssets[_tokenId].alignmentScore;
        cognitiveAssets[_tokenId].alignmentScore = currentScore + _alignmentDelta;

        emit AssetAlignmentUpdated(_tokenId, cognitiveAssets[_tokenId].alignmentScore, _alignmentDelta);
    }

    /**
     * @dev Stakes NCT tokens to a Cognitive Asset to increase its `processingPower`.
     *      This power is crucial for participating in prompts.
     * @param _tokenId The ID of the Cognitive Asset to stake for.
     * @param _amount The amount of NCT to stake.
     */
    function stakeForProcessingPower(uint256 _tokenId, uint256 _amount) external whenNotPaused nonReentrant {
        require(_exists(_tokenId), "Asset does not exist");
        require(_amount > 0, "Amount must be greater than zero");

        // Decay power before staking to get accurate base
        _decayProcessingPower(_tokenId);

        require(nexusComputeToken.transferFrom(msg.sender, address(this), _amount), "NCT transfer failed for staking");
        assetStakedNCT[_tokenId] += _amount;
        // Simple linear relation: 1 NCT = 1 processing power
        cognitiveAssets[_tokenId].processingPower += _amount;
        cognitiveAssets[_tokenId].lastProcessingPowerDecayBlock = block.number; // Reset decay timer

        emit ProcessingPowerStaked(_tokenId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake NCT from a Cognitive Asset.
     * @param _tokenId The ID of the Cognitive Asset to unstake from.
     * @param _amount The amount of NCT to unstake.
     */
    function unstakeFromProcessingPower(uint256 _tokenId, uint256 _amount) external whenNotPaused nonReentrant {
        require(_exists(_tokenId), "Asset does not exist");
        require(assetStakedNCT[_tokenId] >= _amount, "Insufficient staked amount");
        require(_amount > 0, "Amount must be greater than zero");

        // Decay power before unstaking
        _decayProcessingPower(_tokenId);

        assetStakedNCT[_tokenId] -= _amount;
        // Simple linear relation: 1 NCT = 1 processing power
        cognitiveAssets[_tokenId].processingPower -= _amount;
        cognitiveAssets[_tokenId].lastProcessingPowerDecayBlock = block.number; // Reset decay timer after change

        require(nexusComputeToken.transfer(msg.sender, _amount), "NCT transfer failed for unstaking");
        emit ProcessingPowerUnstaked(_tokenId, msg.sender, _amount);
    }

    /**
     * @dev View function to get comprehensive details of a Cognitive Asset.
     * @param _tokenId The ID of the Cognitive Asset.
     * @return owner The current owner of the NFT.
     * @return genesisVectorURI The URI describing initial traits.
     * @return alignmentScore The current alignment score.
     * @return processingPower The current processing power.
     * @return lastProcessingPowerDecayBlock The last block processing power was decayed.
     */
    function getAssetDetails(uint256 _tokenId)
        external
        view
        returns (address owner, string memory genesisVectorURI, int256 alignmentScore, uint256 processingPower, uint256 lastProcessingPowerDecayBlock)
    {
        require(_exists(_tokenId), "Asset does not exist");
        CognitiveAsset storage asset = cognitiveAssets[_tokenId];
        return (
            ownerOf(_tokenId),
            asset.genesisVectorURI,
            asset.alignmentScore,
            asset.processingPower,
            asset.lastProcessingPowerDecayBlock
        );
    }

    /**
     * @dev View function to get the total NCT staked to a particular Cognitive Asset.
     * @param _tokenId The ID of the Cognitive Asset.
     * @return The total NCT amount staked.
     */
    function getAssetStakedAmount(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "Asset does not exist");
        return assetStakedNCT[_tokenId];
    }

    /**
     * @dev Reduces an asset's processing power over time.
     *      Can be called by anyone (to incentivize keeping assets up-to-date) or automatically by other functions.
     *      Decay rate example: 1 power per 100 blocks.
     * @param _tokenId The ID of the Cognitive Asset.
     */
    function decayProcessingPower(uint256 _tokenId) public {
        require(_exists(_tokenId), "Asset does not exist");
        _decayProcessingPower(_tokenId);
    }

    /**
     * @dev Internal helper function to decay processing power.
     *      Makes the `processingPower` dependent on recent staking activity.
     */
    function _decayProcessingPower(uint256 _tokenId) internal {
        CognitiveAsset storage asset = cognitiveAssets[_tokenId];
        uint256 blocksSinceLastDecay = block.number - asset.lastProcessingPowerDecayBlock;
        if (blocksSinceLastDecay > 0) {
            uint256 decayAmount = blocksSinceLastDecay / 100; // Example: 1 power per 100 blocks
            if (asset.processingPower > decayAmount) {
                asset.processingPower -= decayAmount;
            } else {
                asset.processingPower = 0;
            }
            asset.lastProcessingPowerDecayBlock = block.number; // Update decay timestamp
        }
    }


    // --- III. Prompt & Insight Generation (Core Logic) ---

    /**
     * @dev Creates a new prompt for Cognitive Assets to work on.
     *      Requires a fee and locks an NCT reward pool.
     * @param _promptURI The URI (e.g., IPFS hash) describing the prompt.
     * @param _rewardPoolAmount The amount of NCT to lock as reward for this prompt.
     * @return The ID of the newly created prompt.
     */
    function createPrompt(string memory _promptURI, uint256 _rewardPoolAmount) external whenNotPaused nonReentrant returns (uint256) {
        require(nexusComputeToken.transferFrom(msg.sender, address(this), promptCreationFee), "NCT transfer failed for prompt fee");
        require(nexusComputeToken.transferFrom(msg.sender, address(this), _rewardPoolAmount), "NCT transfer failed for reward pool");
        
        _promptIdCounter.increment();
        uint256 newPromptId = _promptIdCounter.current();

        // Example deadlines: submit for 1000 blocks, vote for 500 blocks after that
        uint256 submissionDeadline = block.number + 1000;
        uint256 votingDeadline = submissionDeadline + 500;

        prompts[newPromptId] = Prompt({
            creator: msg.sender,
            promptURI: _promptURI,
            rewardPool: _rewardPoolAmount,
            submissionDeadline: submissionDeadline,
            votingDeadline: votingDeadline,
            finalized: false
        });

        emit PromptCreated(newPromptId, msg.sender, _promptURI, _rewardPoolAmount);
        return newPromptId;
    }

    /**
     * @dev Assigns a Cognitive Asset to work on a specific prompt.
     *      Only callable by the asset owner.
     * @param _tokenId The ID of the Cognitive Asset.
     * @param _promptId The ID of the prompt to assign the asset to.
     */
    function assignAssetToPrompt(uint256 _tokenId, uint256 _promptId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner or approved");
        require(_exists(_tokenId), "Asset does not exist");
        require(prompts[_promptId].creator != address(0), "Prompt does not exist");
        require(prompts[_promptId].submissionDeadline > block.number, "Prompt submission period has ended");
        
        _decayProcessingPower(_tokenId); // Decay power before checking requirements
        require(cognitiveAssets[_tokenId].processingPower >= minProcessingPowerForAssignment, "Asset lacks sufficient processing power");

        prompts[_promptId].assignedAssets[_tokenId] = true;
        emit AssetAssignedToPrompt(_tokenId, _promptId);
    }

    /**
     * @dev Submits a proposed insight for a given prompt from an assigned Cognitive Asset.
     *      Requires the asset to be assigned and meet power/alignment criteria.
     * @param _tokenId The ID of the Cognitive Asset submitting the insight.
     * @param _promptId The ID of the prompt the insight is for.
     * @param _insightURI The URI (e.g., IPFS hash) describing the proposed solution.
     * @return The ID of the newly submitted insight.
     */
    function submitProposedInsight(uint256 _tokenId, uint256 _promptId, string memory _insightURI) external whenNotPaused returns (uint256) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner or approved");
        require(_exists(_tokenId), "Asset does not exist");
        require(prompts[_promptId].creator != address(0), "Prompt does not exist");
        require(prompts[_promptId].submissionDeadline > block.number, "Prompt submission period has ended");
        require(prompts[_promptId].assignedAssets[_tokenId], "Asset not assigned to this prompt");

        _decayProcessingPower(_tokenId); // Decay power before checking requirements
        require(cognitiveAssets[_tokenId].processingPower >= minProcessingPowerForAssignment, "Asset lacks sufficient processing power to submit");
        // Additional requirement: a minimum alignment score
        require(cognitiveAssets[_tokenId].alignmentScore >= -50, "Asset's alignment score too low for submission");

        _insightIdCounter.increment();
        uint256 newInsightId = _insightIdCounter.current();

        insights[newInsightId] = ProposedInsight({
            tokenId: _tokenId,
            promptId: _promptId,
            insightURI: _insightURI,
            submittedBlock: block.number,
            upvotes: 0,
            downvotes: 0,
            voters: new mapping(address => bool) // Initialize the mapping
        });

        emit InsightSubmitted(newInsightId, _tokenId, _promptId, _insightURI);
        return newInsightId;
    }

    /**
     * @dev Allows users to vote on the alignment/quality of a proposed insight.
     * @param _insightId The ID of the insight to vote on.
     * @param _isAligned True for an upvote, false for a downvote.
     */
    function voteOnInsightAlignment(uint256 _insightId, bool _isAligned) external whenNotPaused {
        require(insights[_insightId].tokenId != 0, "Insight does not exist");
        Prompt storage currentPrompt = prompts[insights[_insightId].promptId];
        require(currentPrompt.creator != address(0), "Associated prompt does not exist");
        require(currentPrompt.votingDeadline > block.number, "Voting period has ended");
        require(!insights[_insightId].voters[msg.sender], "Already voted on this insight");

        insights[_insightId].voters[msg.sender] = true;

        if (_isAligned) {
            insights[_insightId].upvotes++;
        } else {
            insights[_insightId].downvotes++;
        }

        emit InsightVoted(_insightId, msg.sender, _isAligned);
    }

    /**
     * @dev Finalizes a prompt, distributes rewards to top-voted insights, and updates asset alignment scores.
     *      Callable by the prompt creator after the voting deadline.
     *      Rewards are distributed according to `rewardDistributionStrategy`.
     * @param _promptId The ID of the prompt to finalize.
     */
    function finalizePrompt(uint256 _promptId) external whenNotPaused nonReentrant {
        Prompt storage currentPrompt = prompts[_promptId];
        require(currentPrompt.creator == msg.sender, "Only prompt creator can finalize");
        require(currentPrompt.creator != address(0), "Prompt does not exist");
        require(currentPrompt.votingDeadline <= block.number, "Voting period has not ended yet");
        require(!currentPrompt.finalized, "Prompt already finalized");

        currentPrompt.finalized = true;
        uint256 totalRewardPool = currentPrompt.rewardPool;
        uint256 distributedAmount = 0;

        // Collect all insights for this prompt
        uint256[] memory insightIds;
        uint256 insightCount = _insightIdCounter.current();
        uint256 tempCount = 0;
        for (uint256 i = 1; i <= insightCount; i++) {
            if (insights[i].promptId == _promptId) {
                tempCount++;
            }
        }
        insightIds = new uint256[](tempCount);
        uint256 currentIdx = 0;
        for (uint256 i = 1; i <= insightCount; i++) {
            if (insights[i].promptId == _promptId) {
                insightIds[currentIdx] = i;
                currentIdx++;
            }
        }

        // Sort insights by net votes (upvotes - downvotes) in descending order
        // This is a simple bubble sort for demonstration, for many insights,
        // an off-chain sorter or more gas-efficient on-chain sorter would be needed.
        for (uint256 i = 0; i < insightIds.length; i++) {
            for (uint256 j = i + 1; j < insightIds.length; j++) {
                int256 netVotesI = int256(insights[insightIds[i]].upvotes) - int256(insights[insightIds[i]].downvotes);
                int256 netVotesJ = int256(insights[insightIds[j]].upvotes) - int256(insights[insightIds[j]].downvotes);
                if (netVotesJ > netVotesI) {
                    uint256 temp = insightIds[i];
                    insightIds[i] = insightIds[j];
                    insightIds[j] = temp;
                }
            }
        }

        // Distribute rewards and update alignment scores based on `rewardDistributionStrategy`
        for (uint256 i = 0; i < rewardDistributionStrategy.length && i < insightIds.length; i++) {
            uint256 insightId = insightIds[i];
            ProposedInsight storage winningInsight = insights[insightId];
            CognitiveAsset storage winningAsset = cognitiveAssets[winningInsight.tokenId];

            uint256 rewardPercentage = rewardDistributionStrategy[i];
            uint256 reward = (totalRewardPool * rewardPercentage) / 100;
            
            require(nexusComputeToken.transfer(ownerOf(winningInsight.tokenId), reward), "Reward transfer failed");
            distributedAmount += reward;

            // Update alignment score: higher for better insights
            int256 netVotes = int256(winningInsight.upvotes) - int256(winningInsight.downvotes);
            // Example: +1 alignment for every 10 net upvotes, capped at 100 per prompt
            int256 alignmentChange = (netVotes / 10);
            if (alignmentChange > 100) alignmentChange = 100; // Cap positive change
            if (alignmentChange < -100) alignmentChange = -100; // Cap negative change

            winningAsset.alignmentScore += alignmentChange;
            emit AssetAlignmentUpdated(winningInsight.tokenId, winningAsset.alignmentScore, alignmentChange);
        }

        // Return any remaining funds to the prompt creator if less than 100% was distributed (e.g., fewer than 3 insights)
        if (totalRewardPool > distributedAmount) {
            uint256 remainder = totalRewardPool - distributedAmount;
            require(nexusComputeToken.transfer(currentPrompt.creator, remainder), "Remainder transfer failed");
            distributedAmount += remainder; // Include remainder in distributedAmount for event log
        }
        
        emit PromptFinalized(_promptId, distributedAmount);
    }

    /**
     * @dev View function to get details of a specific prompt.
     * @param _promptId The ID of the prompt.
     * @return creator The address of the prompt creator.
     * @return promptURI The URI describing the prompt.
     * @return rewardPool The total NCT locked for this prompt.
     * @return submissionDeadline Block number for submission deadline.
     * @return votingDeadline Block number for voting deadline.
     * @return finalized True if the prompt has been finalized.
     */
    function getPromptDetails(uint256 _promptId)
        external
        view
        returns (address creator, string memory promptURI, uint256 rewardPool, uint256 submissionDeadline, uint256 votingDeadline, bool finalized)
    {
        Prompt storage p = prompts[_promptId];
        require(p.creator != address(0), "Prompt does not exist");
        return (p.creator, p.promptURI, p.rewardPool, p.submissionDeadline, p.votingDeadline, p.finalized);
    }

    /**
     * @dev View function to get details of a specific proposed insight.
     * @param _insightId The ID of the insight.
     * @return tokenId The ID of the asset that submitted it.
     * @return promptId The ID of the prompt it belongs to.
     * @return insightURI The URI describing the insight.
     * @return submittedBlock The block it was submitted.
     * @return upvotes The number of upvotes.
     * @return downvotes The number of downvotes.
     */
    function getProposedInsightDetails(uint256 _insightId)
        external
        view
        returns (uint256 tokenId, uint256 promptId, string memory insightURI, uint256 submittedBlock, uint256 upvotes, uint256 downvotes)
    {
        require(insights[_insightId].tokenId != 0, "Insight does not exist");
        ProposedInsight storage i = insights[_insightId];
        return (i.tokenId, i.promptId, i.insightURI, i.submittedBlock, i.upvotes, i.downvotes);
    }

    /**
     * @dev View function to get the top insights for a given prompt, sorted by net votes.
     *      Returns a limited number of insight IDs.
     * @param _promptId The ID of the prompt.
     * @param _count The maximum number of top insights to return.
     * @return An array of insight IDs, sorted from highest to lowest net votes.
     */
    function getTopInsightsForPrompt(uint256 _promptId, uint256 _count) external view returns (uint256[] memory) {
        require(prompts[_promptId].creator != address(0), "Prompt does not exist");

        // Collect all insights for this prompt
        uint256[] memory allInsightIds;
        uint256 insightCount = _insightIdCounter.current();
        uint256 tempCount = 0;
        for (uint256 i = 1; i <= insightCount; i++) {
            if (insights[i].promptId == _promptId) {
                tempCount++;
            }
        }
        allInsightIds = new uint256[](tempCount);
        uint256 currentIdx = 0;
        for (uint256 i = 1; i <= insightCount; i++) {
            if (insights[i].promptId == _promptId) {
                allInsightIds[currentIdx] = i;
                currentIdx++;
            }
        }

        // Sort insights by net votes (upvotes - downvotes) in descending order
        // This is a simple bubble sort for demonstration, for many insights,
        // an off-chain sorter or more gas-efficient on-chain sorter would be needed.
        for (uint256 i = 0; i < allInsightIds.length; i++) {
            for (uint256 j = i + 1; j < allInsightIds.length; j++) {
                int256 netVotesI = int256(insights[allInsightIds[i]].upvotes) - int256(insights[allInsightIds[i]].downvotes);
                int256 netVotesJ = int256(insights[allInsightIds[j]].upvotes) - int256(insights[allInsightIds[j]].downvotes);
                if (netVotesJ > netVotesI) {
                    uint256 temp = allInsightIds[i];
                    allInsightIds[i] = allInsightIds[j];
                    allInsightIds[j] = temp;
                }
            }
        }

        // Return top _count insights
        uint256 returnCount = _count > allInsightIds.length ? allInsightIds.length : _count;
        uint256[] memory topInsightIds = new uint256[](returnCount);
        for (uint256 i = 0; i < returnCount; i++) {
            topInsightIds[i] = allInsightIds[i];
        }
        return topInsightIds;
    }

    // --- IV. Network & Treasury Management ---

    /**
     * @dev Allows the prompt creator to withdraw any unspent NCT from their prompt's reward pool.
     *      This can be used if a prompt is cancelled or if rewards were not fully distributed.
     * @param _promptId The ID of the prompt.
     */
    function withdrawRewardPool(uint256 _promptId) external whenNotPaused nonReentrant {
        Prompt storage currentPrompt = prompts[_promptId];
        require(currentPrompt.creator == msg.sender, "Only prompt creator can withdraw");
        require(currentPrompt.creator != address(0), "Prompt does not exist");
        require(currentPrompt.finalized || currentPrompt.votingDeadline <= block.number, "Prompt must be finalized or past voting deadline to withdraw");

        uint256 balance = currentPrompt.rewardPool;
        currentPrompt.rewardPool = 0; // Clear the pool for this prompt

        require(nexusComputeToken.transfer(msg.sender, balance), "NCT transfer failed for withdrawal");
    }

    /**
     * @dev Admin function to set the minimum `processingPower` required for an asset to be assigned to a prompt.
     * @param _minPower The new minimum processing power.
     */
    function setMinProcessingPowerForAssignment(uint256 _minPower) external onlyOwner {
        minProcessingPowerForAssignment = _minPower;
    }

    /**
     * @dev Admin function to configure how rewards are distributed among the top insights.
     *      Example: `[50, 30, 20]` means 50% to #1, 30% to #2, 20% to #3.
     *      Sum of percentages should ideally be 100 or less.
     * @param _percentages An array of percentages for reward distribution.
     */
    function setRewardDistributionStrategy(uint256[] memory _percentages) external onlyOwner {
        // Optional: Add a check to ensure sum of percentages <= 100 if strict distribution is desired
        // uint256 total = 0;
        // for (uint256 i = 0; i < _percentages.length; i++) {
        //     total += _percentages[i];
        // }
        // require(total <= 100, "Total percentages must be 100 or less");
        rewardDistributionStrategy = _percentages;
    }

    /**
     * @dev Pauses all critical operations of the contract.
     *      Emergency function, callable only by owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     *      Emergency function, callable only by owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw collected fees from the contract's treasury.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of NCT to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_amount > 0, "Amount must be greater than zero");
        require(nexusComputeToken.balanceOf(address(this)) >= _amount, "Insufficient funds in contract treasury");

        require(nexusComputeToken.transfer(_recipient, _amount), "Treasury withdrawal failed");
        emit TreasuryFundsWithdrawn(_recipient, _amount);
    }

    // The following functions are standard ERC721 overrides.
    // They are explicitly defined to make it clear they exist, even if simple.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ERC721 `tokenURI` implementation (optional, but good practice for dNFTs)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Combine a base URI with the genesisVectorURI or a dynamically generated URI
        // For this example, we'll just return the genesisVectorURI
        // In a real dNFT, you might have a metadata server generate a URI based on the asset's current state.
        return cognitiveAssets[tokenId].genesisVectorURI;
    }
}

```