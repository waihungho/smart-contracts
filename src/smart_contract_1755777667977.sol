```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title SODAGarden (Self-Optimizing Decentralized Asset Garden)
 * @author YourNameHere (Simulated)
 * @notice A novel smart contract ecosystem managing dynamic NFTs ("Flora") that evolve based on
 *         "Environmental Conditions" and community governance. An AI Oracle provides "Growth Insights"
 *         for community voting, aiming to optimize collective "Garden Health."
 *
 * @dev This contract demonstrates advanced concepts like:
 *      - Dynamic NFTs (metadata, growth cycles, evolution based on external factors).
 *      - AI Oracle Integration (AI suggests actions, but cannot execute them directly, requiring governance).
 *      - On-chain Governance (proposals, voting, execution, delegation).
 *      - Gamified mechanics (planting, harvesting, cross-pollination, gardener roles).
 *      - Simulated External Data Feeds (via `IOracle` interface).
 */

// --- Interfaces ---

/// @dev Interface for a mock oracle providing environmental conditions.
interface IOracle {
    function getLatestValue(uint256 _conditionId) external view returns (int256 value, uint256 timestamp);
}

// --- SODAGarden Contract ---

contract SODAGarden is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _floraIdCounter;
    Counters.Counter private _insightIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Base URI for Flora NFT metadata (can be updated dynamically)
    string public baseTokenURI;

    // AI Oracle address - designated entity for submitting growth insights
    address public aiOracleAddress;

    // Core Garden Parameters
    uint256 public growthDecayRate; // Rate at which flora health decays if not maintained (e.g., 1 unit per cycle)
    uint256 public maxFloraSupply;  // Maximum number of Flora NFTs that can exist
    uint256 public growthFactor;    // Multiplier for growth based on positive environmental conditions
    uint256 public plantingFee;     // Fee to plant a new seed
    uint256 public harvestRewardAmount; // Reward for harvesting a mature flora

    // --- Data Structures ---

    struct Flora {
        uint256 growthScore;           // Health/maturity score (0-1000)
        uint256 resilience;            // Resistance to negative environmental conditions (0-100)
        uint256 maturity;              // Threshold to be considered mature for harvesting
        string speciesId;              // Unique identifier for the flora's species (e.g., "SolarBloom", "LunarVine")
        uint256 lastGrowthCycleTimestamp; // Timestamp of the last growth update
        address owner;                 // Current owner of the NFT (redundant but useful for quick lookups)
    }
    mapping(uint224 => Flora) public flora; // Mapping from tokenId to Flora struct

    struct EnvironmentalCondition {
        int256 value;      // Current value of the condition (e.g., -100 to 100 for sentiment)
        uint256 timestamp; // Last updated timestamp
        address oracleAddress; // Trusted oracle for this specific condition
    }
    mapping(uint256 => EnvironmentalCondition) public environmentalConditions; // conditionId => EnvironmentalCondition

    enum InsightStatus { PENDING, APPROVED, REJECTED, PROCESSED }
    struct GrowthInsight {
        uint256 insightId;
        address proposer;
        string description;
        bytes targetEncodedCallData; // Encoded call data for the target function to be executed if insight is approved
        InsightStatus status;
        uint256 submissionTime;
        uint256 proposalId; // Link to the governance proposal created from this insight
    }
    mapping(uint256 => GrowthInsight) public growthInsights;

    enum ProposalState { PENDING, ACTIVE, SUCCEEDED, DEFEATED, EXECUTED }
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        address target;              // Target contract for the call
        bytes callData;              // Encoded function call data
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 startBlock;
        uint256 endBlock;
        uint256 quorumRequired;      // Minimum votes needed to pass (e.g., percentage of total supply)
        ProposalState state;
        mapping(address => bool) hasVoted; // Check if an address has voted on this proposal
    }
    mapping(uint256 => Proposal) public proposals;

    // Gardener role management
    mapping(address => bool) public isGardener;
    mapping(address => uint256) public gardenerCommissions;

    // --- Events ---

    event FloraPlanted(uint256 indexed tokenId, address indexed owner, string speciesId);
    event FloraGrowthUpdated(uint256 indexed tokenId, uint256 newGrowthScore, uint256 newResilience);
    event FloraHarvested(uint256 indexed tokenId, address indexed harvester, uint256 rewardAmount);
    event FloraCrossPollinated(uint252 indexed parent1Id, uint252 indexed parent2Id, uint256 indexed childId, string newSpeciesId);

    event GardenParametersUpdated(uint256 newGrowthDecayRate, uint256 newMaxFloraSupply, uint256 newGrowthFactor);
    event AIOracleAddressUpdated(address indexed newAddress);
    event EnvironmentalConditionUpdated(uint256 indexed conditionId, int256 newValue, uint256 timestamp);

    event GrowthInsightSubmitted(uint256 indexed insightId, address indexed proposer, string description);
    event GrowthInsightProcessed(uint256 indexed insightId, InsightStatus newStatus);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event GardenerRegistered(address indexed gardener);
    event GardenerCommissionClaimed(address indexed gardener, uint224 amount);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "SODAGarden: Caller is not the AI Oracle");
        _;
    }

    modifier onlyRegisteredOracle(uint256 _conditionId) {
        require(environmentalConditions[_conditionId].oracleAddress != address(0), "SODAGarden: Condition not registered");
        require(msg.sender == environmentalConditions[_conditionId].oracleAddress, "SODAGarden: Not authorized oracle for this condition");
        _;
    }

    // --- Constructor ---

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _aiOracleAddress,
        uint256 _initialGrowthDecayRate,
        uint256 _initialMaxFloraSupply,
        uint256 _initialGrowthFactor,
        uint256 _plantingFee,
        uint256 _harvestRewardAmount
    ) ERC721(_name, _symbol) Ownable(msg.sender) Pausable() {
        baseTokenURI = _baseTokenURI;
        aiOracleAddress = _aiOracleAddress;
        growthDecayRate = _initialGrowthDecayRate;
        maxFloraSupply = _initialMaxFloraSupply;
        growthFactor = _initialGrowthFactor;
        plantingFee = _plantingFee;
        harvestRewardAmount = _harvestRewardAmount;
    }

    // --- I. Core Infrastructure & Configuration ---

    /**
     * @notice Allows the owner/DAO to adjust global growth and decay parameters for the Flora.
     * @param _newGrowthDecayRate New rate at which flora health decays.
     * @param _newMaxFloraSupply New maximum number of Flora NFTs.
     * @param _newGrowthFactor New multiplier for growth.
     */
    function setGardenParameters(
        uint256 _newGrowthDecayRate,
        uint256 _newMaxFloraSupply,
        uint256 _newGrowthFactor
    ) external onlyOwner whenNotPaused {
        require(_newMaxFloraSupply > totalSupply(), "SODAGarden: New max supply cannot be less than current supply.");
        growthDecayRate = _newGrowthDecayRate;
        maxFloraSupply = _newMaxFloraSupply;
        growthFactor = _newGrowthFactor;
        emit GardenParametersUpdated(_newGrowthDecayRate, _newMaxFloraSupply, _newGrowthFactor);
    }

    /**
     * @notice Updates the address of the trusted AI Oracle.
     * @param _newOracleAddress The new address for the AI Oracle.
     */
    function updateAIOracleAddress(address _newOracleAddress) external onlyOwner whenNotPaused {
        require(_newOracleAddress != address(0), "SODAGarden: AI Oracle address cannot be zero.");
        aiOracleAddress = _newOracleAddress;
        emit AIOracleAddressUpdated(_newOracleAddress);
    }

    /**
     * @notice Pauses the contract in case of emergency.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner/DAO to withdraw accumulated fees from the contract's treasury.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "SODAGarden: Cannot withdraw to zero address.");
        require(address(this).balance >= _amount, "SODAGarden: Insufficient balance.");
        (bool success,) = _to.call{value: _amount}("");
        require(success, "SODAGarden: Failed to withdraw fees.");
    }

    // --- II. Flora (Dynamic NFT) Management ---

    /**
     * @notice Mints a new "Flora" NFT (seed) for the caller.
     * @param _speciesId An initial species ID for the new Flora.
     */
    function plantSeed(string memory _speciesId) external payable whenNotPaused {
        require(msg.value >= plantingFee, "SODAGarden: Insufficient planting fee.");
        require(totalSupply() < maxFloraSupply, "SODAGarden: Garden has reached max flora capacity.");

        _floraIdCounter.increment();
        uint256 newFloraId = _floraIdCounter.current();

        flora[uint224(newFloraId)] = Flora({
            growthScore: 100, // Starting growth score
            resilience: 50,
            maturity: 500,    // Default maturity target
            speciesId: _speciesId,
            lastGrowthCycleTimestamp: block.timestamp,
            owner: msg.sender
        });

        _mint(msg.sender, newFloraId);
        emit FloraPlanted(newFloraId, msg.sender, _speciesId);
    }

    /**
     * @notice Calculates and returns the current growth score of a specific Flora NFT.
     * @param _tokenId The ID of the Flora NFT.
     * @return The calculated growth score.
     */
    function getFloraGrowthScore(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "SODAGarden: Flora does not exist.");
        Flora storage f = flora[uint224(_tokenId)];
        
        uint256 timeElapsed = block.timestamp - f.lastGrowthCycleTimestamp;
        // Simple approximation: Growth score decays over time.
        // Actual growth logic will be in `triggerGrowthCycle` considering environmental factors.
        uint256 potentialDecay = timeElapsed * growthDecayRate;
        if (f.growthScore > potentialDecay) {
            return f.growthScore - potentialDecay;
        } else {
            return 0;
        }
    }

    /**
     * @notice Initiates a growth/decay cycle for a specific Flora NFT.
     *         Updates its state based on current environmental conditions and time elapsed.
     *         Can be called by anyone, incentivized for Gardeners.
     * @param _tokenId The ID of the Flora NFT to update.
     */
    function triggerGrowthCycle(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "SODAGarden: Flora does not exist.");
        Flora storage f = flora[uint224(_tokenId)];

        uint256 timeElapsed = block.timestamp - f.lastGrowthCycleTimestamp;
        require(timeElapsed > 0, "SODAGarden: Not enough time has passed for a new cycle.");

        int256 overallEnvironmentalImpact = 0;
        // Example: Combine effects of multiple environmental conditions
        // In a real scenario, this would use Chainlink Data Feeds or VRF results.
        if (environmentalConditions[1].oracleAddress != address(0)) { // Assuming conditionId 1 for "MarketSentiment"
            (int256 marketSentiment, ) = IOracle(environmentalConditions[1].oracleAddress).getLatestValue(1);
            overallEnvironmentalImpact += marketSentiment / 10; // Scale down
        }
        if (environmentalConditions[2].oracleAddress != address(0)) { // Assuming conditionId 2 for "Weather"
            (int256 weatherImpact, ) = IOracle(environmentalConditions[2].oracleAddress).getLatestValue(2);
            overallEnvironmentalImpact += weatherImpact;
        }

        uint256 newScore = f.growthScore;
        uint256 newResilience = f.resilience;

        // Apply decay
        uint256 actualDecay = (timeElapsed * growthDecayRate) / 1000; // Scale to per-millisecond or similar
        if (newScore > actualDecay) {
            newScore -= actualDecay;
        } else {
            newScore = 0;
        }

        // Apply growth based on positive environmental impact, adjusted by resilience
        if (overallEnvironmentalImpact > 0) {
            uint256 potentialGrowth = (uint256(overallEnvironmentalImpact) * growthFactor * timeElapsed) / 10000;
            newScore = newScore + (potentialGrowth * (100 + newResilience)) / 200; // Resilience helps growth
            if (newScore > 1000) newScore = 1000; // Cap growth score
        } else if (overallEnvironmentalImpact < 0) {
            // Negative impact leads to more decay, but resilience mitigates it
            uint256 additionalDecay = (uint256(-overallEnvironmentalImpact) * (100 - newResilience)) / 100; // Resilience reduces additional decay
            if (newScore > additionalDecay) {
                newScore -= additionalDecay;
            } else {
                newScore = 0;
            }
        }

        f.growthScore = newScore;
        f.lastGrowthCycleTimestamp = block.timestamp;

        // Reward gardener for triggering if sender is a gardener
        if (isGardener[msg.sender]) {
            gardenerCommissions[msg.sender] += 100; // Example commission
        }

        emit FloraGrowthUpdated(_tokenId, f.growthScore, f.resilience);
    }

    /**
     * @notice Generates and returns a dynamic metadata URI for a Flora NFT.
     *         The URI will point to an off-chain service that generates JSON based on the Flora's state.
     * @param _tokenId The ID of the Flora NFT.
     * @return The dynamic metadata URI.
     */
    function getFloraMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "SODAGarden: Flora does not exist.");
        // This is a dynamic URI that would point to a service like IPFS + API gateway or a dedicated metadata server.
        // Example: "https://your-api.com/api/sodagarden/flora/{id}"
        return string(abi.encodePacked(baseTokenURI, _tokenId.toString()));
    }

    /**
     * @notice Allows the owner of a sufficiently mature Flora NFT to "harvest" it.
     *         Burns the NFT and potentially provides a reward.
     * @param _tokenId The ID of the Flora NFT to harvest.
     */
    function harvestFlora(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "SODAGarden: Flora does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "SODAGarden: Caller is not the owner of this flora.");
        require(flora[uint224(_tokenId)].growthScore >= flora[uint224(_tokenId)].maturity, "SODAGarden: Flora not mature enough to harvest.");

        _burn(_tokenId);
        // Reward mechanism: In a full system, this would transfer an ERC20 token or ETH.
        // For this example, we'll simulate it by reducing planting fee.
        if (address(this).balance >= harvestRewardAmount) {
            (bool success,) = msg.sender.call{value: harvestRewardAmount}("");
            require(success, "SODAGarden: Failed to send harvest reward.");
        }
        
        emit FloraHarvested(_tokenId, msg.sender, harvestRewardAmount);
    }

    /**
     * @notice Allows two mature Flora NFTs to be "cross-pollinated," burning them to mint a new Flora NFT
     *         with potentially hybrid traits.
     * @param _floraId1 The ID of the first Flora NFT.
     * @param _floraId2 The ID of the second Flora NFT.
     * @param _newSpeciesId The species ID for the newly generated Flora.
     */
    function crossPollinateFlora(uint256 _floraId1, uint256 _floraId2, string memory _newSpeciesId) external payable whenNotPaused {
        require(msg.value >= plantingFee, "SODAGarden: Insufficient cross-pollination fee.");
        require(ownerOf(_floraId1) == msg.sender, "SODAGarden: Caller is not owner of Flora 1.");
        require(ownerOf(_floraId2) == msg.sender, "SODAGarden: Caller is not owner of Flora 2.");
        require(_floraId1 != _floraId2, "SODAGarden: Cannot cross-pollinate a flora with itself.");
        require(flora[uint224(_floraId1)].growthScore >= flora[uint224(_floraId1)].maturity, "SODAGarden: Flora 1 not mature enough.");
        require(flora[uint224(_floraId2)].growthScore >= flora[uint224(_floraId2)].maturity, "SODAGarden: Flora 2 not mature enough.");
        require(totalSupply() < maxFloraSupply, "SODAGarden: Garden has reached max flora capacity.");

        // Simulate trait inheritance/hybridization:
        Flora storage f1 = flora[uint224(_floraId1)];
        Flora storage f2 = flora[uint224(_floraId2)];

        uint256 newGrowthScore = (f1.growthScore + f2.growthScore) / 2;
        uint256 newResilience = (f1.resilience + f2.resilience) / 2;
        uint256 newMaturity = (f1.maturity + f2.maturity) / 2;

        _burn(_floraId1);
        _burn(_floraId2);

        _floraIdCounter.increment();
        uint256 newChildId = _floraIdCounter.current();

        flora[uint224(newChildId)] = Flora({
            growthScore: newGrowthScore,
            resilience: newResilience,
            maturity: newMaturity,
            speciesId: _newSpeciesId,
            lastGrowthCycleTimestamp: block.timestamp,
            owner: msg.sender
        });

        _mint(msg.sender, newChildId);
        emit FloraCrossPollinated(_floraId1, _floraId2, newChildId, _newSpeciesId);
    }

    // --- III. Environmental Data & Oracles ---

    /**
     * @notice Registers a new environmental data feed, linking a `conditionId` to its trusted oracle address.
     * @param _conditionId A unique ID for the environmental condition (e.g., 1 for "MarketSentiment").
     * @param _oracleAddress The address of the trusted oracle contract for this condition.
     */
    function registerEnvironmentalFeed(uint256 _conditionId, address _oracleAddress) external onlyOwner whenNotPaused {
        require(_oracleAddress != address(0), "SODAGarden: Oracle address cannot be zero.");
        environmentalConditions[_conditionId].oracleAddress = _oracleAddress;
        // No event for update as it's just setting the oracle address for future updates.
    }

    /**
     * @notice A trusted oracle pushes an updated value for a specific environmental condition.
     *         Only the registered oracle for that condition ID can call this.
     * @param _conditionId The ID of the environmental condition.
     * @param _newValue The new value for the condition.
     */
    function updateEnvironmentalCondition(uint256 _conditionId, int256 _newValue) external onlyRegisteredOracle(_conditionId) whenNotPaused {
        environmentalConditions[_conditionId].value = _newValue;
        environmentalConditions[_conditionId].timestamp = block.timestamp;
        emit EnvironmentalConditionUpdated(_conditionId, _newValue, block.timestamp);
    }

    /**
     * @notice Retrieves the latest value and timestamp for a given environmental condition ID.
     * @param _conditionId The ID of the environmental condition.
     * @return value The latest value.
     * @return timestamp The timestamp when it was last updated.
     */
    function getEnvironmentalCondition(uint256 _conditionId) public view returns (int256 value, uint256 timestamp) {
        require(environmentalConditions[_conditionId].oracleAddress != address(0), "SODAGarden: Condition not registered.");
        return (environmentalConditions[_conditionId].value, environmentalConditions[_conditionId].timestamp);
    }

    // --- IV. AI Oracle Integration & Insights ---

    /**
     * @notice Allows the AI Oracle to submit a structured "Growth Insight" proposing a specific action
     *         (e.g., a parameter change or a specific function call) for community approval.
     * @param _description A human-readable description of the insight.
     * @param _targetEncodedCallData The ABI-encoded function call data for the action suggested by the AI.
     */
    function submitGrowthInsight(string memory _description, bytes memory _targetEncodedCallData) external onlyAIOracle whenNotPaused {
        _insightIdCounter.increment();
        uint256 newInsightId = _insightIdCounter.current();

        growthInsights[newInsightId] = GrowthInsight({
            insightId: newInsightId,
            proposer: msg.sender,
            description: _description,
            targetEncodedCallData: _targetEncodedCallData,
            status: InsightStatus.PENDING,
            submissionTime: block.timestamp,
            proposalId: 0 // Will be linked when a proposal is created from it
        });
        emit GrowthInsightSubmitted(newInsightId, msg.sender, _description);
    }

    /**
     * @notice Retrieves the full details of a submitted AI Growth Insight.
     * @param _insightId The ID of the insight.
     * @return The GrowthInsight struct.
     */
    function getGrowthInsightDetails(uint256 _insightId) public view returns (GrowthInsight memory) {
        require(_insightId <= _insightIdCounter.current() && _insightId > 0, "SODAGarden: Invalid Insight ID.");
        return growthInsights[_insightId];
    }

    /**
     * @notice Marks an AI insight as processed after its corresponding governance proposal has been successfully executed.
     *         This prevents the same insight from being proposed multiple times.
     * @param _insightId The ID of the insight to mark as processed.
     */
    function markInsightProcessed(uint256 _insightId) external onlyOwner { // Or callable by the executor of the proposal
        require(_insightId <= _insightIdCounter.current() && _insightId > 0, "SODAGarden: Invalid Insight ID.");
        require(growthInsights[_insightId].status != InsightStatus.PROCESSED, "SODAGarden: Insight already processed.");
        growthInsights[_insightId].status = InsightStatus.PROCESSED;
        emit GrowthInsightProcessed(_insightId, InsightStatus.PROCESSED);
    }

    // --- V. Governance & Adaptive Protocol ---

    /**
     * @dev Calculates voting power based on the number of Flora NFTs owned.
     * @param _voter The address whose voting power is to be calculated.
     * @return The voting power (number of Flora NFTs).
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        return balanceOf(_voter); // Simple: 1 Flora NFT = 1 vote
    }

    /**
     * @notice Allows users with sufficient voting power to propose a general governance action.
     * @param _description A description of the proposal.
     * @param _target The target contract address for the execution.
     * @param _calldata The ABI-encoded function call data for the action.
     * @return The ID of the created proposal.
     */
    function propose(string memory _description, address _target, bytes memory _calldata) external whenNotPaused returns (uint256) {
        require(getVotingPower(msg.sender) > 0, "SODAGarden: No voting power to propose."); // Simple check, could be a minimum threshold

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        // Example: Voting period of 10 blocks, quorum of 10% of total flora supply.
        uint256 votingPeriodBlocks = 10;
        uint256 calculatedQuorum = totalSupply() / 10; // 10% quorum

        proposals[newProposalId] = Proposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            description: _description,
            target: _target,
            callData: _calldata,
            voteCountYes: 0,
            voteCountNo: 0,
            startBlock: block.number,
            endBlock: block.number + votingPeriodBlocks,
            quorumRequired: calculatedQuorum,
            state: ProposalState.PENDING, // Will become ACTIVE immediately
            hasVoted: new mapping(address => bool) // Initialize empty
        });

        proposals[newProposalId].state = ProposalState.ACTIVE; // Mark active immediately after creation
        emit ProposalCreated(newProposalId, msg.sender, _description, block.number, block.number + votingPeriodBlocks);
        return newProposalId;
    }

    /**
     * @notice Casts a vote (yes/no) on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a "yes" vote, false for a "no" vote.
     */
    function vote(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.proposalId != 0, "SODAGarden: Proposal does not exist.");
        require(p.state == ProposalState.ACTIVE, "SODAGarden: Proposal is not active.");
        require(block.number >= p.startBlock && block.number <= p.endBlock, "SODAGarden: Voting period is closed.");
        require(!p.hasVoted[msg.sender], "SODAGarden: Already voted on this proposal.");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "SODAGarden: Caller has no voting power.");

        if (_support) {
            p.voteCountYes += voterPower;
        } else {
            p.voteCountNo += voterPower;
        }
        p.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @notice Delegates the caller's voting power to another address.
     *         Note: This simple implementation only considers immediate Flora ownership for voting power.
     *         A more complex system would require a separate delegation mechanism or using a governance token.
     *         For this contract, delegation would mean assigning specific Flora NFTs to the delegatee.
     *         This function acts as a placeholder or could be implemented with a separate token.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegate(address _delegatee) external pure {
        // This function is a placeholder. For true liquid democracy, you'd need a governance token
        // with ERC20Votes or similar implementation, or a complex NFT delegation system.
        // In this simple model, `getVotingPower` relies on direct ownership.
        revert("SODAGarden: Delegation not fully implemented in this version (requires ERC20Votes or custom NFT delegation logic).");
    }

    /**
     * @notice Revokes any existing voting power delegation. (Placeholder, see `delegate`)
     */
    function undelegate() external pure {
        revert("SODAGarden: Undelegation not fully implemented in this version (requires ERC20Votes or custom NFT delegation logic).");
    }

    /**
     * @notice Executes a proposal that has met its quorum and voting requirements and passed its voting period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.proposalId != 0, "SODAGarden: Proposal does not exist.");
        require(p.state != ProposalState.EXECUTED, "SODAGarden: Proposal already executed.");
        require(p.state != ProposalState.ACTIVE, "SODAGarden: Proposal still active."); // Should have passed endBlock
        require(block.number > p.endBlock, "SODAGarden: Voting period not ended yet.");

        // Check if proposal succeeded
        if (p.voteCountYes > p.voteCountNo && p.voteCountYes >= p.quorumRequired) {
            p.state = ProposalState.SUCCEEDED;
        } else {
            p.state = ProposalState.DEFEATED;
        }
        require(p.state == ProposalState.SUCCEEDED, "SODAGarden: Proposal did not pass.");

        // Execute the proposed action
        (bool success, ) = p.target.call(p.callData);
        require(success, "SODAGarden: Proposal execution failed.");

        p.state = ProposalState.EXECUTED;
        emit ProposalExecuted(_proposalId);

        // If this proposal was related to an AI insight, mark that insight as processed
        for (uint256 i = 1; i <= _insightIdCounter.current(); i++) {
            if (growthInsights[i].proposalId == _proposalId) {
                growthInsights[i].status = InsightStatus.PROCESSED;
                emit GrowthInsightProcessed(i, InsightStatus.PROCESSED);
                break;
            }
        }
    }

    // --- VI. Gardener Role & Rewards ---

    /**
     * @notice Allows a user to apply for and become a "Gardener" role.
     *         Gardeners may have specific permissions or receive commissions.
     */
    function registerGardener() external whenNotPaused {
        require(!isGardener[msg.sender], "SODAGarden: Caller is already a Gardener.");
        // Add any requirements here, e.g., staking tokens, or community vote
        isGardener[msg.sender] = true;
        emit GardenerRegistered(msg.sender);
    }

    /**
     * @notice Allows registered Gardeners to claim accumulated commissions.
     */
    function claimGardenerCommission() external whenNotPaused {
        require(isGardener[msg.sender], "SODAGarden: Caller is not a registered Gardener.");
        uint256 amount = gardenerCommissions[msg.sender];
        require(amount > 0, "SODAGarden: No commission to claim.");

        gardenerCommissions[msg.sender] = 0; // Reset
        // In a real scenario, this would transfer an ERC20 token or ETH
        if (address(this).balance >= amount) {
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "SODAGarden: Failed to send commission.");
        }
        
        emit GardenerCommissionClaimed(msg.sender, amount);
    }

    /**
     * @notice Callable by DAO/owner to distribute a portion of the protocol's treasury
     *         as rewards to active participants (e.g., voters, successful proposers).
     *         This would typically be part of a DAO's treasury management.
     */
    function distributeCommunityRewards() external onlyOwner whenNotPaused {
        // This function would implement logic to identify active participants
        // (e.g., voters in successful proposals, consistent gardeners) and distribute
        // a calculated share of fees. For demonstration, this is conceptual.
        revert("SODAGarden: Community reward distribution logic not implemented in this version.");
    }

    // --- Internal/Utility Functions (ERC721 overrides) ---

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev See {ERC721-tokenURI}.
     * Overrides the default tokenURI to provide dynamic metadata.
     * In a real application, this would point to a server/API that generates JSON based on flora state.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return getFloraMetadataURI(tokenId);
    }
}
```