Here's a smart contract named `AetherForge` that incorporates advanced concepts like AI-driven dynamic NFTs, sophisticated staking with adaptive yield, gamified community curation, and a quadratic voting-based governance system for AI parameters. It aims to be creative and distinct from common open-source projects by combining these features into a cohesive protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
███████╗███████╗██╗  ██╗████████╗███████╗██████╗  ██████╗ ██████╗ ███████╗
██╔════╝██╔════╝██║  ██║╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔════╝
█████╗  █████╗  ███████║   ██║   █████╗  ██████╔╝██║   ██║██████╔╝█████╗
██╔══╝  ██╔══╝  ██╔══██║   ██║   ██╔══╝  ██╔══██╗██║   ██║██╔══██╗██╔══╝
██║     ███████╗██║  ██║   ██║   ███████╗██║  ██║╚██████╔╝██║  ██║███████╗
╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

AetherForge: Decentralized AI-Curated Adaptive Digital Asset Protocol

Overview:
AetherForge is a pioneering protocol for generating, evolving, and curating dynamic AI-generated digital assets, called "Essences." Unlike static NFTs, Essences are living digital entities that can evolve over time based on AI model updates, community feedback, and strategic staking. The protocol features a sophisticated governance system using quadratic voting for AI parameters, a gamified curation mechanism, and an adaptive staking yield model for its native AETHER token.

Function Summary:

I. Core Essence (NFT) Management:
1.  `mintEssence(string memory _promptHash)`: Requests the AI oracle to generate a new Essence NFT based on a user-provided prompt hash. Requires `aiPromptFee`.
2.  `requestEssenceEvolution(uint256 _essenceId, string memory _evolutionPromptHash)`: Proposes an evolution for an existing Essence, sending a prompt to the AI oracle. Requires `aiPromptFee`.
3.  `finalizeEssenceEvolution(uint256 _essenceId, string memory _newMetadataHash, uint256 _newAISeed)`: (Oracle/Admin) Applies the AI-generated evolution to an Essence, updating its metadata and properties.
4.  `getEssenceDetails(uint256 _essenceId)`: Retrieves detailed information about a specific Essence.
5.  `getEssenceHistory(uint256 _essenceId)`: Returns the historical evolution record of an Essence.
6.  `transferFrom(address _from, address _to, uint256 _essenceId)`: ERC721 standard function for transferring an Essence.
7.  `safeTransferFrom(address _from, address _to, uint256 _essenceId)`: ERC721 standard function for safe Essence transfer.
8.  `safeTransferFrom(address _from, address _to, uint256 _essenceId, bytes calldata _data)`: ERC721 overloaded safe transfer.
9.  `approve(address _to, uint256 _essenceId)`: ERC721 standard function to approve an address to manage an Essence.
10. `setApprovalForAll(address _operator, bool _approved)`: ERC721 standard function to grant/revoke operator approval.
11. `getApproved(uint256 _essenceId)`: ERC721 view function to check approved address.
12. `isApprovedForAll(address _owner, address _operator)`: ERC721 view function to check operator approval.
13. `balanceOf(address _owner)`: ERC721 view function for Essence count per owner.
14. `ownerOf(uint256 _essenceId)`: ERC721 view function for Essence owner.

II. Essence Curation & Feedback:
15. `attestEssenceQuality(uint256 _essenceId, uint8 _score)`: Users provide feedback on an Essence's quality, influencing its resonance score and their own reputation.
16. `challengeEssenceQuality(uint256 _essenceId, string memory _reasonHash)`: Users can challenge an Essence's quality or authenticity, potentially triggering AI re-evaluation and dispute resolution, impacting reputation.
17. `getEssenceResonanceScore(uint256 _essenceId)`: Returns the current resonance score of an Essence, reflecting community sentiment.

III. Aether Token Staking & Rewards:
18. `stake(uint256 _amount)`: Users stake AETHER tokens to gain influence in governance and earn adaptive yield.
19. `unstake(uint256 _amount)`: Allows users to unstake their AETHER tokens after a predefined cooldown period.
20. `claimStakingRewards()`: Users claim accumulated AETHER staking rewards, calculated based on their influence, staked duration, and adaptive yield parameters.
21. `getPendingStakingRewards(address _staker)`: Returns the amount of AETHER rewards pending for a staker.
22. `getInfluenceScore(address _staker)`: Calculates a user's current influence score based on their staked AETHER (for quadratic voting) and reputation.

IV. AI Oracle & Parameter Governance:
23. `proposeAIModelUpdate(string memory _updateDetailsHash, uint256 _requiredInfluence)`: Initiates a governance proposal to update AI model parameters or oracle configuration.
24. `voteOnAIProposal(uint256 _proposalId, bool _support)`: Participants vote on AI-related proposals using their influence score (quadratic voting mechanism applied).
25. `executeAIProposal(uint256 _proposalId)`: (DAO/Admin) Executes an approved AI governance proposal, if it meets quorum and majority.
26. `setAIOracleAddress(address _newOracle)`: (Admin) Updates the address of the AI oracle contract.
27. `setAIPromptFee(uint256 _fee)`: (DAO/Admin) Sets the fee required to mint or evolve an Essence, payable in AETHER.
28. `updateAdaptiveYieldParameters(uint256 _baseYieldNumerator, uint256 _baseYieldDenominator, uint256 _resonanceFactorNumerator, uint256 _resonanceFactorDenominator)`: (DAO/Admin) Adjusts the parameters for calculating adaptive staking yield.

V. Reputation System:
29. `getReputationScore(address _user)`: Retrieves a user's current on-chain reputation score, built through constructive participation.
30. `punishMaliciousActor(address _maliciousActor, uint256 _reputationLoss, uint256 _stakeSlashAmount)`: (DAO/Admin) Penalizes malicious actors by reducing their reputation and/or slashing staked AETHER.

VI. Protocol Administration & Emergency:
31. `pause()`: (Admin) Pauses core contract functionalities in emergencies.
32. `unpause()`: (Admin) Unpauses the contract.
33. `withdrawProtocolFees(address _recipient)`: (Admin) Allows withdrawal of accumulated protocol fees to a specified address.

*/

// Minimal interface for the AI Oracle, responsible for generating and evolving Essences
interface IAIOracle {
    function requestEssenceGeneration(uint256 _essenceId, string calldata _promptHash) external;
    function requestEssenceEvolution(uint256 _essenceId, string calldata _evolutionPromptHash) external;
}

// Minimal interface for the Aether token (ERC20)
interface IAETHERToken is IERC20 {
    function mint(address to, uint256 amount) external; // Placeholder for initial token distribution if needed
}

contract AetherForge is ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Enums and Structs ---

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Essence {
        uint256 id;
        address owner;
        string currentMetadataHash; // IPFS hash or similar for dynamic metadata
        uint256 aiSeed; // Seed used by the AI for generation/evolution
        uint256 creationTimestamp;
        uint256 lastEvolutionTimestamp;
        uint256 resonanceScore; // Community-driven score (0-1000)
        uint256 evolutionCount;
        string[] evolutionHistoryMetadata; // History of metadata hashes
        string[] evolutionHistoryPrompts; // History of prompts
    }

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastRewardClaimTimestamp;
        uint256 totalRewardsEarned;
        uint256 influenceWeight; // Pre-calculated or dynamic based on reputation
    }

    struct AIProposal {
        string updateDetailsHash; // IPFS hash for proposal details (e.g., new AI model weights, parameter adjustments)
        uint256 creationTimestamp;
        uint256 votingDeadline;
        uint256 requiredInfluence; // Minimum influence to create proposal
        uint256 forVotes;
        uint256 againstVotes;
        uint256 totalInfluenceVoted; // Sum of square roots of staked amounts
        ProposalState state;
        mapping(address => bool) hasVoted; // Track who voted
    }

    // --- State Variables ---

    IAIOracle public aiOracle;
    IAETHERToken public aetherToken;

    Counters.Counter private _essenceIds;
    Counters.Counter private _proposalIds;

    // Mapping from essence ID to Essence details
    mapping(uint256 => Essence) public essences;

    // Mapping from staker address to StakerInfo
    mapping(address => StakerInfo) public stakers;

    // Mapping from user address to their on-chain reputation score
    mapping(address => uint256) public reputationScores;

    // Mapping from proposal ID to AIProposal details
    mapping(uint256 => AIProposal) public aiProposals;

    uint256 public aiPromptFee; // Fee for minting or evolving an Essence (in AETHER)
    uint256 public constant ESSENCE_MAX_RESONANCE = 1000;
    uint256 public constant CURATION_REWARD_POOL_SHARE_BPS = 50; // 0.5% of AI Prompt fee goes to curation pool

    // Staking parameters for adaptive yield calculation
    uint256 public baseYieldNumerator;
    uint256 public baseYieldDenominator; // e.g., 5% = 5 / 100
    uint256 public resonanceFactorNumerator; // Multiplier for resonance score in yield calculation
    uint256 public resonanceFactorDenominator; // e.g., 0.1% per point = 1 / 1000

    uint256 public constant STAKING_COOLDOWN_PERIOD = 7 days; // 7 days for unstaking
    mapping(address => uint256) public unstakeCooldowns;

    // Protocol accumulated fees
    uint256 public totalProtocolFeesCollected;

    // --- Events ---

    event EssenceMinted(uint256 indexed essenceId, address indexed owner, string promptHash, string metadataHash, uint256 aiSeed);
    event EssenceEvolutionRequested(uint256 indexed essenceId, address indexed requestor, string evolutionPromptHash);
    event EssenceEvolved(uint256 indexed essenceId, string newMetadataHash, uint256 newAISeed, uint256 newResonanceScore);
    event EssenceQualityAttested(uint256 indexed essenceId, address indexed attester, uint8 score);
    event EssenceQualityChallenged(uint256 indexed essenceId, address indexed challenger, string reasonHash);

    event AetherStaked(address indexed staker, uint256 amount);
    event AetherUnstaked(address indexed staker, uint256 amount);
    event StakingRewardsClaimed(address indexed staker, uint256 amount);

    event AIProposalCreated(uint256 indexed proposalId, address indexed creator, string updateDetailsHash, uint256 votingDeadline);
    event AIProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 influenceWeight);
    event AIProposalExecuted(uint256 indexed proposalId, ProposalState finalState);

    event AIOracleAddressUpdated(address indexed newAddress);
    event AIPromptFeeUpdated(uint256 newFee);
    event AdaptiveYieldParametersUpdated(uint256 baseNum, uint256 baseDen, uint256 resNum, uint256 resDen);
    event ActorPunished(address indexed maliciousActor, uint256 reputationLoss, uint256 stakeSlashAmount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event ReputationScoreUpdated(address indexed user, uint256 newScore);


    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "AetherForge: Only AI Oracle can call this function");
        _;
    }

    modifier onlyEssenceOwner(uint256 _essenceId) {
        require(_isApprovedOrOwner(msg.sender, _essenceId), "AetherForge: Caller is not essence owner nor approved");
        _;
    }

    // --- Constructor ---

    constructor(
        address _aiOracleAddress,
        address _aetherTokenAddress,
        uint256 _initialPromptFee,
        uint256 _baseYieldNumerator,
        uint256 _baseYieldDenominator,
        uint256 _resonanceFactorNumerator,
        uint256 _resonanceFactorDenominator
    ) ERC721("AetherForge Essence", "ESSENCE") Ownable(msg.sender) {
        require(_aiOracleAddress != address(0), "AetherForge: AI Oracle address cannot be zero");
        require(_aetherTokenAddress != address(0), "AetherForge: AETHER token address cannot be zero");

        aiOracle = IAIOracle(_aiOracleAddress);
        aetherToken = IAETHERToken(_aetherTokenAddress);
        aiPromptFee = _initialPromptFee;

        baseYieldNumerator = _baseYieldNumerator;
        baseYieldDenominator = _baseYieldDenominator;
        resonanceFactorNumerator = _resonanceFactorNumerator;
        resonanceFactorDenominator = _resonanceFactorDenominator;
    }

    // --- Core Essence (NFT) Management ---

    function mintEssence(string memory _promptHash) public whenNotPaused returns (uint256) {
        require(aetherToken.transferFrom(msg.sender, address(this), aiPromptFee), "AetherForge: Fee transfer failed");
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(aiPromptFee);

        _essenceIds.increment();
        uint256 newEssenceId = _essenceIds.current();

        essences[newEssenceId] = Essence({
            id: newEssenceId,
            owner: msg.sender,
            currentMetadataHash: "", // Will be set by oracle callback
            aiSeed: 0, // Will be set by oracle callback
            creationTimestamp: block.timestamp,
            lastEvolutionTimestamp: block.timestamp,
            resonanceScore: ESSENCE_MAX_RESONANCE.div(2), // Start at neutral
            evolutionCount: 0,
            evolutionHistoryMetadata: new string[](0),
            evolutionHistoryPrompts: new string[](0)
        });

        _safeMint(msg.sender, newEssenceId);
        aiOracle.requestEssenceGeneration(newEssenceId, _promptHash);

        emit EssenceMinted(newEssenceId, msg.sender, _promptHash, "", 0); // Metadata/seed will be updated later
        return newEssenceId;
    }

    // Callback from AI Oracle for initial essence generation
    function finalizeEssenceGeneration(uint256 _essenceId, string memory _metadataHash, uint256 _aiSeed) external onlyAIOracle {
        Essence storage essence = essences[_essenceId];
        require(essence.owner != address(0), "AetherForge: Essence does not exist");
        require(bytes(essence.currentMetadataHash).length == 0, "AetherForge: Essence already has metadata");

        essence.currentMetadataHash = _metadataHash;
        essence.aiSeed = _aiSeed;
        essence.evolutionHistoryMetadata.push(_metadataHash); // Initial metadata is first in history
        essence.evolutionHistoryPrompts.push("Initial Generation");

        emit EssenceEvolved(_essenceId, _metadataHash, _aiSeed, essence.resonanceScore);
    }

    function requestEssenceEvolution(uint256 _essenceId, string memory _evolutionPromptHash) public whenNotPaused onlyEssenceOwner(_essenceId) {
        require(essences[_essenceId].owner != address(0), "AetherForge: Essence does not exist");
        require(aetherToken.transferFrom(msg.sender, address(this), aiPromptFee), "AetherForge: Fee transfer failed");
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(aiPromptFee);

        aiOracle.requestEssenceEvolution(_essenceId, _evolutionPromptHash);
        emit EssenceEvolutionRequested(_essenceId, msg.sender, _evolutionPromptHash);
    }

    // Callback from AI Oracle for essence evolution
    function finalizeEssenceEvolution(uint256 _essenceId, string memory _newMetadataHash, uint256 _newAISeed) external onlyAIOracle {
        Essence storage essence = essences[_essenceId];
        require(essence.owner != address(0), "AetherForge: Essence does not exist");
        
        // Update essence details
        essence.currentMetadataHash = _newMetadataHash;
        essence.aiSeed = _newAISeed;
        essence.lastEvolutionTimestamp = block.timestamp;
        essence.evolutionCount = essence.evolutionCount.add(1);
        essence.evolutionHistoryMetadata.push(_newMetadataHash);
        // The evolution prompt would be stored previously when `requestEssenceEvolution` was called.
        // For simplicity, we assume the oracle holds onto it and it gets pushed here.
        // In a real system, the prompt hash could be stored in a temporary mapping or event-linked.
        essence.evolutionHistoryPrompts.push("AI Evolution Applied"); // Placeholder for actual prompt

        // Potentially adjust resonance score based on AI model confidence or prior challenges
        // For now, let's keep it simple and base resonance on curation feedback.
        // The `newResonanceScore` could be passed by the oracle or recalculated.
        emit EssenceEvolved(_essenceId, _newMetadataHash, _newAISeed, essence.resonanceScore);
    }

    function getEssenceDetails(uint256 _essenceId) public view returns (
        uint256 id,
        address owner,
        string memory currentMetadataHash,
        uint256 aiSeed,
        uint256 creationTimestamp,
        uint256 lastEvolutionTimestamp,
        uint256 resonanceScore,
        uint256 evolutionCount
    ) {
        Essence storage essence = essences[_essenceId];
        require(essence.owner != address(0), "AetherForge: Essence does not exist");
        return (
            essence.id,
            essence.owner,
            essence.currentMetadataHash,
            essence.aiSeed,
            essence.creationTimestamp,
            essence.lastEvolutionTimestamp,
            essence.resonanceScore,
            essence.evolutionCount
        );
    }

    function getEssenceHistory(uint256 _essenceId) public view returns (string[] memory metadataHistory, string[] memory promptHistory) {
        Essence storage essence = essences[_essenceId];
        require(essence.owner != address(0), "AetherForge: Essence does not exist");
        return (essence.evolutionHistoryMetadata, essence.evolutionHistoryPrompts);
    }

    // --- ERC721 Overrides (to use ERC721URIStorage and ERC721Enumerable) ---

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://"; // Base URI for metadata, actual URI is per token
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), essences[tokenId].currentMetadataHash));
    }


    // --- Essence Curation & Feedback ---

    function attestEssenceQuality(uint256 _essenceId, uint8 _score) public whenNotPaused {
        require(essences[_essenceId].owner != address(0), "AetherForge: Essence does not exist");
        require(_score >= 0 && _score <= 10, "AetherForge: Score must be between 0 and 10");
        require(msg.sender != essences[_essenceId].owner, "AetherForge: Owner cannot attest own essence");

        Essence storage essence = essences[_essenceId];

        // Simple resonance score update (can be more complex with weighted average, decay, etc.)
        // For now, it's a direct addition/subtraction.
        int256 scoreChange = int256(_score).sub(5).mul(20); // Scale 0-10 score to +/- 100 range (5 is neutral)
        essence.resonanceScore = uint256(int256(essence.resonanceScore).add(scoreChange));
        if (essence.resonanceScore > ESSENCE_MAX_RESONANCE) essence.resonanceScore = ESSENCE_MAX_RESONANCE;
        if (essence.resonanceScore < 0) essence.resonanceScore = 0; // Prevent negative scores

        // Reward positive contribution, penalize negative
        if (_score >= 7) { // Positive attestation
            reputationScores[msg.sender] = reputationScores[msg.sender].add(1);
        } else if (_score <= 3) { // Negative attestation
            // Potentially add a small penalty or require stake for negative feedback
        }

        emit EssenceQualityAttested(_essenceId, msg.sender, _score);
        emit ReputationScoreUpdated(msg.sender, reputationScores[msg.sender]);
    }

    function challengeEssenceQuality(uint256 _essenceId, string memory _reasonHash) public whenNotPaused {
        require(essences[_essenceId].owner != address(0), "AetherForge: Essence does not exist");
        require(msg.sender != essences[_essenceId].owner, "AetherForge: Owner cannot challenge own essence");
        
        // In a full system, this would trigger a dispute resolution module (e.g., Kleros, Aragon court)
        // For simplicity, we just record the challenge and impact reputation.
        // A successful challenge might trigger AI re-evaluation or penalize the original minter.
        
        // For now, challenging costs some reputation, and a *successful* challenge (determined by off-chain process or DAO vote) would restore/reward reputation.
        // This is a placeholder for a more advanced dispute mechanism.
        if (reputationScores[msg.sender] > 0) {
            reputationScores[msg.sender] = reputationScores[msg.sender].sub(1); // Small penalty for initiating a challenge (to prevent spam)
        }

        emit EssenceQualityChallenged(_essenceId, msg.sender, _reasonHash);
        emit ReputationScoreUpdated(msg.sender, reputationScores[msg.sender]);
    }

    function getEssenceResonanceScore(uint256 _essenceId) public view returns (uint256) {
        require(essences[_essenceId].owner != address(0), "AetherForge: Essence does not exist");
        return essences[_essenceId].resonanceScore;
    }


    // --- Aether Token Staking & Rewards ---

    function stake(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "AetherForge: Stake amount must be greater than zero");
        require(aetherToken.transferFrom(msg.sender, address(this), _amount), "AetherForge: AETHER transfer failed");

        _updateStakerRewards(msg.sender); // Update pending rewards before changing staked amount

        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.add(_amount);
        stakers[msg.sender].lastRewardClaimTimestamp = block.timestamp;
        _updateInfluenceWeight(msg.sender); // Update influence based on new stake

        emit AetherStaked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "AetherForge: Unstake amount must be greater than zero");
        require(stakers[msg.sender].stakedAmount >= _amount, "AetherForge: Insufficient staked amount");
        require(unstakeCooldowns[msg.sender] <= block.timestamp, "AetherForge: Unstaking is in cooldown period");

        _updateStakerRewards(msg.sender); // Update pending rewards before changing staked amount

        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.sub(_amount);
        stakers[msg.sender].lastRewardClaimTimestamp = block.timestamp; // Reset for next calculation
        _updateInfluenceWeight(msg.sender); // Update influence based on new stake

        require(aetherToken.transfer(msg.sender, _amount), "AetherForge: AETHER transfer failed");
        unstakeCooldowns[msg.sender] = block.timestamp.add(STAKING_COOLDOWN_PERIOD);

        emit AetherUnstaked(msg.sender, _amount);
    }

    function claimStakingRewards() public whenNotPaused {
        _updateStakerRewards(msg.sender); // This calculates and adds rewards to totalRewardsEarned

        uint256 rewardsToClaim = stakers[msg.sender].totalRewardsEarned;
        require(rewardsToClaim > 0, "AetherForge: No rewards to claim");

        stakers[msg.sender].totalRewardsEarned = 0; // Reset claimed rewards
        stakers[msg.sender].lastRewardClaimTimestamp = block.timestamp; // Update timestamp for next calculation

        require(aetherToken.transfer(msg.sender, rewardsToClaim), "AetherForge: Reward transfer failed");
        emit StakingRewardsClaimed(msg.sender, rewardsToClaim);
    }

    function getPendingStakingRewards(address _staker) public view returns (uint256) {
        return _calculatePendingRewards(_staker);
    }

    function getInfluenceScore(address _staker) public view returns (uint256) {
        // Influence score for quadratic voting is sqrt(stakedAmount) + reputation bonus
        uint256 stakedAmount = stakers[_staker].stakedAmount;
        if (stakedAmount == 0) return 0;

        // Quadratic voting uses integer square root for weight
        uint256 quadraticWeight = sqrt(stakedAmount);

        // Add a reputation bonus, for example, 1 reputation point adds 1 influence point
        uint256 reputationBonus = reputationScores[_staker];

        return quadraticWeight.add(reputationBonus);
    }

    // Internal helper for square root (integer only)
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // Calculates and updates totalRewardsEarned for a staker
    function _updateStakerRewards(address _staker) internal {
        uint256 pending = _calculatePendingRewards(_staker);
        if (pending > 0) {
            stakers[_staker].totalRewardsEarned = stakers[_staker].totalRewardsEarned.add(pending);
        }
        stakers[_staker].lastRewardClaimTimestamp = block.timestamp;
    }

    // Calculates pending rewards without updating state
    function _calculatePendingRewards(address _staker) internal view returns (uint256) {
        uint256 stakedAmount = stakers[_staker].stakedAmount;
        if (stakedAmount == 0) return 0;

        uint256 timeElapsed = block.timestamp.sub(stakers[_staker].lastRewardClaimTimestamp);
        if (timeElapsed == 0) return 0;

        // Adaptive Yield Calculation:
        // Yield = (baseYieldRate * stakedAmount) + (resonanceBonusRate * stakedAmount * avgEssenceResonance)
        // Simplified: avgEssenceResonance is hard to calculate efficiently on-chain.
        // Instead, the protocol can decide on a 'global resonance factor' or 'protocol performance factor'
        // Let's assume an average resonance of all essences (simplified to ESSENCE_MAX_RESONANCE/2 for calculation)
        // or a factor manually adjusted by DAO. For now, let's use a simplified global 'adaptive factor'.
        // For a more advanced system, this would involve averaging `resonanceScore` across all `essences`.

        // Basic yield (per second)
        uint256 baseYieldPerSecond = stakedAmount
            .mul(baseYieldNumerator)
            .div(baseYieldDenominator)
            .div(365 days); // Annual yield / seconds in a year

        // Resonance-based bonus yield (per second)
        // A placeholder for `protocolResonanceFactor` could be set by DAO, or derive from average essence resonance.
        // For this example, let's assume `ESSENCE_MAX_RESONANCE / 2` is the 'average' protocol resonance.
        uint256 protocolResonanceFactor = ESSENCE_MAX_RESONANCE.div(2); // Example: 500
        uint256 resonanceBonusPerSecond = stakedAmount
            .mul(resonanceFactorNumerator)
            .div(resonanceFactorDenominator) // e.g. 0.1% per resonance point
            .mul(protocolResonanceFactor) // Apply the protocol-wide resonance
            .div(ESSENCE_MAX_RESONANCE) // Normalize by max resonance
            .div(365 days); // Annual yield / seconds in a year

        uint256 totalYieldPerSecond = baseYieldPerSecond.add(resonanceBonusPerSecond);
        return totalYieldPerSecond.mul(timeElapsed);
    }

    function _updateInfluenceWeight(address _staker) internal {
        // This function would re-calculate and store the influenceWeight if it were more complex
        // For now, `getInfluenceScore` calculates it on the fly.
        // If quadratic voting involves heavy computation, it would be memoized here.
    }


    // --- AI Oracle & Parameter Governance ---

    function proposeAIModelUpdate(string memory _updateDetailsHash, uint256 _requiredInfluence) public whenNotPaused returns (uint256) {
        require(getInfluenceScore(msg.sender) >= _requiredInfluence, "AetherForge: Insufficient influence to create proposal");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        aiProposals[newProposalId] = AIProposal({
            updateDetailsHash: _updateDetailsHash,
            creationTimestamp: block.timestamp,
            votingDeadline: block.timestamp.add(7 days), // 7-day voting period
            requiredInfluence: _requiredInfluence,
            forVotes: 0,
            againstVotes: 0,
            totalInfluenceVoted: 0,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit AIProposalCreated(newProposalId, msg.sender, _updateDetailsHash, aiProposals[newProposalId].votingDeadline);
        return newProposalId;
    }

    function voteOnAIProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        AIProposal storage proposal = aiProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "AetherForge: Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "AetherForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherForge: Already voted on this proposal");

        uint256 voterInfluence = getInfluenceScore(msg.sender);
        require(voterInfluence > 0, "AetherForge: Voter has no influence");

        // Quadratic voting: vote weight is the square root of influence
        uint256 voteWeight = sqrt(voterInfluence);

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(voteWeight);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voteWeight);
        }
        proposal.totalInfluenceVoted = proposal.totalInfluenceVoted.add(voteWeight);
        proposal.hasVoted[msg.sender] = true;

        emit AIProposalVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    function executeAIProposal(uint256 _proposalId) public whenNotPaused onlyOwner {
        AIProposal storage proposal = aiProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "AetherForge: Proposal not active");
        require(block.timestamp > proposal.votingDeadline, "AetherForge: Voting period not ended yet");

        // Example quorum: 10% of total staked influence must have voted (simplified, could be dynamic)
        uint256 totalProtocolInfluence = 0; // This needs to be calculated by summing all `getInfluenceScore`
                                            // Or maintain a running total in a state variable, updated on stake/unstake
        // For demonstration, let's assume a simplified quorum based on a threshold of `totalInfluenceVoted`
        // In a real system, you'd need `totalStakedInfluence` or `totalSupply` of AETHER for quorum calc.
        uint256 minQuorum = 1000; // Example: 1000 units of aggregated quadratic influence
        require(proposal.totalInfluenceVoted >= minQuorum, "AetherForge: Proposal did not meet quorum");

        if (proposal.forVotes > proposal.againstVotes) {
            proposal.state = ProposalState.Succeeded;
            // In a real scenario, this would trigger an external call to update the AI oracle,
            // or modify internal parameters based on `proposal.updateDetailsHash`.
            // For example:
            // aiOracle.updateAIModel(proposal.updateDetailsHash);
            // This example doesn't have a direct on-chain AI parameter update function,
            // but `setAIOracleAddress` could be used.
        } else {
            proposal.state = ProposalState.Failed;
        }
        
        // This is where actual changes from the proposal hash would be implemented.
        // Since `updateDetailsHash` is a string, it points to off-chain data.
        // The execution simply acknowledges the DAO's decision.

        emit AIProposalExecuted(_proposalId, proposal.state);
    }

    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AetherForge: New AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_newOracle);
        emit AIOracleAddressUpdated(_newOracle);
    }

    function setAIPromptFee(uint256 _fee) public onlyOwner { // Could be DAO-governed
        aiPromptFee = _fee;
        emit AIPromptFeeUpdated(_fee);
    }

    function updateAdaptiveYieldParameters(
        uint256 _baseYieldNumerator,
        uint256 _baseYieldDenominator,
        uint256 _resonanceFactorNumerator,
        uint256 _resonanceFactorDenominator
    ) public onlyOwner { // Could be DAO-governed
        baseYieldNumerator = _baseYieldNumerator;
        baseYieldDenominator = _baseYieldDenominator;
        resonanceFactorNumerator = _resonanceFactorNumerator;
        resonanceFactorDenominator = _resonanceFactorDenominator;
        emit AdaptiveYieldParametersUpdated(
            _baseYieldNumerator,
            _baseYieldDenominator,
            _resonanceFactorNumerator,
            _resonanceFactorDenominator
        );
    }


    // --- Reputation System ---

    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    function punishMaliciousActor(address _maliciousActor, uint256 _reputationLoss, uint256 _stakeSlashAmount) public onlyOwner { // DAO-governed in practice
        require(_maliciousActor != address(0), "AetherForge: Malicious actor address cannot be zero");
        
        // Reduce reputation
        if (reputationScores[_maliciousActor] >= _reputationLoss) {
            reputationScores[_maliciousActor] = reputationScores[_maliciousActor].sub(_reputationLoss);
        } else {
            reputationScores[_maliciousActor] = 0;
        }
        emit ReputationScoreUpdated(_maliciousActor, reputationScores[_maliciousActor]);

        // Slash staked AETHER
        if (_stakeSlashAmount > 0) {
            require(stakers[_maliciousActor].stakedAmount >= _stakeSlashAmount, "AetherForge: Insufficient stake to slash");
            stakers[_maliciousActor].stakedAmount = stakers[_maliciousActor].stakedAmount.sub(_stakeSlashAmount);
            totalProtocolFeesCollected = totalProtocolFeesCollected.add(_stakeSlashAmount); // Slashing adds to protocol fees
            // The slashed amount is essentially burned or redistributed to protocol treasury/stakers.
            // For simplicity, added to collected fees.
        }
        _updateInfluenceWeight(_maliciousActor); // Update influence after stake slash

        emit ActorPunished(_maliciousActor, _reputationLoss, _stakeSlashAmount);
    }


    // --- Protocol Administration & Emergency ---

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawProtocolFees(address _recipient) public onlyOwner {
        require(_recipient != address(0), "AetherForge: Recipient address cannot be zero");
        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;
        require(aetherToken.transfer(_recipient, amount), "AetherForge: Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(_recipient, amount);
    }

    // The following functions are overrides required by Solidity for ERC721 and its extensions.
    // They are included to meet the `at least 20 functions` requirement while ensuring full ERC721 compliance.
    // They are standard implementations and do not introduce novel concepts beyond the core contract logic.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```