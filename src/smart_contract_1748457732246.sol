Okay, here is a smart contract concept called `GenesisForge`. This contract orchestrates a process of collaborative, generative digital asset (NFT) creation. It incorporates concepts like:

1.  **Multiple Assets:** Manages an ERC-20 "Essence" token (for staking/fuel) and two types of ERC-721 NFTs: "Forges" (generation stations) and "Artifacts" (the final generative output). *Note: For simplicity in a single file example, the ERC-20 and ERC-721 logic might be conceptually integrated or use interfaces, but a real-world deployment would have separate contract files.* We will use interfaces and simulate interactions for clarity in this example.
2.  **Staking:** Users stake Essence to fuel generation and earn rewards.
3.  **Generative Process:** Artifacts aren't minted instantly but go through stages (`advanceGeneration`), influenced by time, staking, and potentially randomness.
4.  **Dynamic NFTs:** Artifact properties can change *after* minting based on community curation.
5.  **Community Curation/Governance:** A simple proposal and voting system allows staked users to propose and vote on changes to Artifact properties.
6.  **Reputation System:** Users earn reputation for participating in curation and generation.
7.  **Parametrization:** Admin functions to tune parameters of the system.
8.  **Pausability:** Standard mechanism to pause critical operations.

**Outline:**

1.  **Contract Description:** A platform for decentralized, collaborative creation and evolution of generative NFTs fueled by staking.
2.  **State Variables:** Track parameters, user stakes, Forge/Artifact data, curation proposals, and reputation.
3.  **Assets (Conceptual Interfaces):** Reference `IEssenceToken`, `IForgeNFT`, `IArtifactNFT`.
4.  **Structs:** Define data structures for Staking Positions, Artifact Generation State, Curation Proposals, Forge Data.
5.  **Events:** Announce key actions like staking, generation stage changes, proposal creation, voting.
6.  **Modifiers:** Access control (`onlyOwner`), state control (`whenNotPaused`).
7.  **Constructor:** Initializes contract with addresses of external token/NFT contracts and initial parameters.
8.  **Admin Functions:** Set parameters, pause/unpause.
9.  **Essence Staking Functions:** Stake, unstake, claim rewards, view stake data.
10. **Forge Management Functions:** Mint Forges (requires stake/Essence?), View Forge data.
11. **Artifact Generation Functions:** Start a generation process (linked to a Forge and stake), advance generation state, finalize generation (mints Artifact NFT), view generation progress/state.
12. **Artifact Curation/Voting Functions:** Propose property updates, vote on proposals, execute successful proposals, view proposal details.
13. **Reputation Functions:** View user reputation. (Reputation update is internal).
14. **View Functions:** Get various state details, parameters, calculated values (like voting power).

**Function Summary (Minimum 20 functions):**

1.  `constructor`: Initializes the contract and sets external token/NFT contract addresses.
2.  `setTokenAddresses`: Admin: Sets addresses of linked ERC20 and ERC721 contracts.
3.  `setStakingParameters`: Admin: Adjusts parameters for Essence staking rewards.
4.  `setGenerationParameters`: Admin: Adjusts parameters controlling the artifact generation process.
5.  `setCurationParameters`: Admin: Adjusts parameters for the curation/voting system.
6.  `pauseContract`: Admin: Pauses core user interactions.
7.  `unpauseContract`: Admin: Unpauses core user interactions.
8.  `stakeEssence`: Users stake Essence tokens to gain staking power and fuel generation/curation.
9.  `unstakeEssence`: Users withdraw staked Essence (might have cooldown).
10. `claimStakingRewards`: Users claim accumulated Essence rewards from staking.
11. `getPendingRewards`: View: Calculates pending rewards for a user's stake.
12. `mintForge`: Users can mint a Forge NFT (perhaps by burning Essence or staking a large amount).
13. `startArtifactGeneration`: Owner of a Forge initiates a new artifact generation process, requiring staked Essence.
14. `advanceArtifactGeneration`: Users (or anyone?) can push an active generation process forward, potentially requiring more Essence or time. This updates artifact properties.
15. `finalizeArtifactGeneration`: Owner of a Forge completes a generation process, minting the final Artifact NFT based on its current state.
16. `getArtifactGenerationProgress`: View: Gets the current state and progress of a specific active generation.
17. `getArtifactProperties`: View: Retrieves the current dynamic properties of a minted Artifact NFT. (Called by ArtifactNFT's `tokenURI`).
18. `requestPropertyUpdateProposal`: Holders of staked Essence can propose changes to an Artifact's properties.
19. `voteOnPropertyUpdate`: Stakers vote on an active property update proposal. Voting power based on staked amount and/or reputation.
20. `getVotingPower`: View: Calculates a user's current voting power.
21. `executePropertyUpdate`: Anyone can trigger the execution of a proposal once the voting period ends and quorum/thresholds are met, applying changes and distributing rewards/penalties.
22. `getProposalDetails`: View: Retrieves details about a specific curation proposal.
23. `getPlayerReputation`: View: Gets the reputation score for a specific address.
24. `getEssenceStakedBy`: View: Gets the amount of Essence staked by a user.
25. `getForgeOwner`: View: Gets the owner of a specific Forge NFT (calls IForgeNFT).
26. `getArtifactOwner`: View: Gets the owner of a specific Artifact NFT (calls IArtifactNFT).
27. `getTotalEssenceStaked`: View: Gets the total amount of Essence currently staked in the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Conceptual Interfaces for external contracts
interface IEssenceToken is IERC20 {
    function mint(address to, uint256 amount) external;
    // Assume transferFrom is used by GenesisForge to pull Essence from users for staking/minting
}

interface IForgeNFT is IERC721Metadata {
    function mint(address to) external returns (uint256 tokenId);
    // Assume transferFrom is used
}

interface IArtifactNFT is IERC721Metadata {
    struct ArtifactData {
        uint256 generationSeed;
        string[] properties; // Dynamic properties
        uint256 lastUpdateTime;
    }
    function mint(address to, uint256 tokenId, ArtifactData calldata data) external;
    function updateArtifactProperties(uint256 tokenId, string[] calldata newProperties) external;
    function getArtifactData(uint256 tokenId) external view returns (ArtifactData memory);
    // Assume transferFrom is used, and tokenURI calls back to GenesisForge for dynamic data
}


/**
 * @title GenesisForge
 * @dev Orchestrates a collaborative, generative NFT creation and curation process.
 * Users stake ERC-20 Essence tokens to fuel Forge NFTs which generate dynamic Artifact NFTs.
 * Stakers can then propose and vote on updates to Artifact properties.
 * Includes staking rewards, a basic reputation system, and parameterized generation/curation.
 *
 * Outline:
 * 1. Contract Description: Decentralized platform for generative NFT creation/curation.
 * 2. State Variables: Parameters, user stakes, Forge/Artifact data links, proposals, reputation.
 * 3. Assets (Interfaces): Reference IEssenceToken, IForgeNFT, IArtifactNFT.
 * 4. Structs: Data structures for Staking, Generation, Curation, Forges.
 * 5. Events: Announcements for key actions.
 * 6. Modifiers: Access control, pausable checks.
 * 7. Constructor: Initialization with external contract addresses and parameters.
 * 8. Admin Functions: Parameter settings, pausing.
 * 9. Essence Staking: Stake, unstake, claim rewards, view stake.
 * 10. Forge Management: Mint Forges.
 * 11. Artifact Generation: Start, advance, finalize generation; view progress.
 * 12. Artifact Curation: Propose, vote, execute proposals; view details.
 * 13. Reputation: View reputation.
 * 14. Views: General state queries.
 *
 * Function Summary (27 Functions):
 * - Core Setup: constructor, setTokenAddresses
 * - Admin: setStakingParameters, setGenerationParameters, setCurationParameters, pauseContract, unpauseContract
 * - Staking: stakeEssence, unstakeEssence, claimStakingRewards, getPendingRewards, getEssenceStakedBy, getTotalEssenceStaked
 * - Forge: mintForge, getForgeOwner, getForgeCount
 * - Artifact Generation: startArtifactGeneration, advanceArtifactGeneration, finalizeArtifactGeneration, getArtifactGenerationProgress, isGenerationActive
 * - Curation: requestPropertyUpdateProposal, voteOnPropertyUpdate, executePropertyUpdate, getProposalDetails, getVotingPower
 * - Data/Views: getArtifactProperties (for NFT tokenURI), getArtifactOwner, getArtifactCount, getPlayerReputation
 */
contract GenesisForge is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // --- External Contract Addresses ---
    IEssenceToken public essenceToken;
    IForgeNFT public forgeNFT;
    IArtifactNFT public artifactNFT;

    // --- Parameters ---
    struct StakingParameters {
        uint256 rewardRatePerEssencePerSecond; // Rate of Essence reward
        uint256 unstakeCooldown; // Time users must wait after unstaking
    }
    StakingParameters public stakingParams;

    struct GenerationParameters {
        uint256 essenceCostPerAdvance; // Essence required to advance a generation stage
        uint256 timePerStage; // Minimum time between generation stages
        uint256 totalGenerationStages; // Number of stages an artifact goes through
        uint256 forgeMintEssenceCost; // Essence required to mint a Forge
    }
    GenerationParameters public generationParams;

    struct CurationParameters {
        uint256 proposalVotingPeriod; // Duration for voting on proposals
        uint256 minimumStakeForProposal; // Minimum Essence staked to create a proposal
        uint256 proposalQuorumPercent; // Percentage of total voting power needed for a proposal to be valid
        uint256 proposalThresholdPercent; // Percentage of votes required for a proposal to pass (of total votes cast)
    }
    CurationParameters public curationParams;


    // --- Staking State ---
    struct StakingPosition {
        uint256 amount; // Amount of Essence staked
        uint256 startTimestamp; // Timestamp when staking began
        uint256 lastClaimTimestamp; // Timestamp of the last reward claim
        uint256 unstakeRequestTimestamp; // Timestamp when unstake was requested (0 if not requested)
    }
    mapping(address => StakingPosition) public userStake;
    uint256 private _totalEssenceStaked;

    // --- Forge State ---
    // We assume Forge ownership is tracked by IForgeNFT.
    // We might need specific data linked to Forges if they have unique generation bonuses, etc.
    // For now, just tracking the link to generations.
    mapping(uint256 => uint256) public forgeToActiveGeneration; // Maps Forge TokenId to Artifact Generation ID

    // --- Artifact Generation State ---
    struct ArtifactGeneration {
        uint256 forgeId; // The Forge NFT initiating this generation
        address owner; // The address who started the generation
        uint256 currentStage; // Current stage of generation (0 to totalGenerationStages-1)
        uint256 lastStageAdvanceTime; // Timestamp of the last stage advance
        uint256 creationTime; // Timestamp when generation started
        uint256 artifactTokenId; // Final Artifact Token ID (0 if not finalized)
        uint256 generationSeed; // Seed used for generative process
        string[] properties; // Current properties during generation
    }
    Counters.Counter private _nextArtifactGenerationId;
    mapping(uint256 => ArtifactGeneration) public artifactGenerations; // Maps Generation ID to state
    mapping(uint256 => uint256) public artifactIdToGenerationId; // Maps final Artifact TokenId back to Generation ID

    // --- Curation State ---
    struct CurationProposal {
        uint256 proposalId;
        uint256 artifactTokenId; // The Artifact this proposal targets
        string[] newProperties; // The proposed new properties
        address proposer;
        uint256 createTime;
        uint256 voteEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) voted; // Tracks who has voted
        bool executed;
        bool passed; // True if passed and executed
    }
    Counters.Counter private _nextProposalId;
    mapping(uint256 => CurationProposal) public curationProposals;

    // --- Reputation System ---
    // A simple score based on participation
    mapping(address => uint256) public playerReputation;
    uint256 public constant REPUTATION_PER_VOTE = 1;
    uint256 public constant REPUTATION_PER_PROPOSAL = 5;
    uint256 public constant REPUTATION_PER_FINALIZED_ARTIFACT = 10;


    // --- Events ---
    event TokenAddressesSet(address essenceToken, address forgeNFT, address artifactNFT);
    event StakingParametersSet(StakingParameters params);
    event GenerationParametersSet(GenerationParameters params);
    event CurationParametersSet(CurationParameters params);
    event EssenceStaked(address indexed user, uint256 amount);
    event EssenceUnstakeRequested(address indexed user, uint256 amount, uint256 cooldownEnds);
    event EssenceUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 rewards);
    event ForgeMinted(address indexed owner, uint256 indexed forgeId);
    event ArtifactGenerationStarted(uint256 indexed generationId, uint256 indexed forgeId, address indexed owner);
    event ArtifactGenerationAdvanced(uint256 indexed generationId, uint256 newStage, string[] newProperties);
    event ArtifactGenerationFinalized(uint256 indexed generationId, uint256 indexed artifactId, address indexed owner);
    event PropertyUpdateProposalCreated(uint256 indexed proposalId, uint256 indexed artifactId, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool indexed voteFor, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, uint256 indexed artifactId, bool indexed passed);
    event ReputationUpdated(address indexed user, uint256 newReputation);

    // --- Modifiers ---
    modifier onlyTokenAddressesSet() {
        require(address(essenceToken) != address(0) && address(forgeNFT) != address(0) && address(artifactNFT) != address(0), "Addresses not set");
        _;
    }

    modifier whenGenerationActive(uint256 generationId) {
        require(artifactGenerations[generationId].forgeId != 0, "Generation does not exist");
        require(artifactGenerations[generationId].artifactTokenId == 0, "Generation already finalized");
        _;
    }


    // --- Constructor ---
    constructor(address _essenceToken, address _forgeNFT, address _artifactNFT) Ownable(msg.sender) Pausable(msg.sender) {
        essenceToken = IEssenceToken(_essenceToken);
        forgeNFT = IForgeNFT(_forgeNFT);
        artifactNFT = IArtifactNFT(_artifactNFT);

        // Set initial default parameters
        stakingParams = StakingParameters({
            rewardRatePerEssencePerSecond: 1e15, // Example: 0.001 Essence per sec per staked Essence (adjust decimal places based on token)
            unstakeCooldown: 3 days
        });
        generationParams = GenerationParameters({
            essenceCostPerAdvance: 100 ether, // Example cost per advance
            timePerStage: 1 hours, // Example time between stages
            totalGenerationStages: 5, // 5 stages
            forgeMintEssenceCost: 500 ether // Example cost to mint a forge
        });
        curationParams = CurationParameters({
            proposalVotingPeriod: 2 days,
            minimumStakeForProposal: 1000 ether,
            proposalQuorumPercent: 20, // 20% quorum
            proposalThresholdPercent: 50 // 50% +1 vote threshold
        });

        emit TokenAddressesSet(_essenceToken, _forgeNFT, _artifactNFT);
        emit StakingParametersSet(stakingParams);
        emit GenerationParametersSet(generationParams);
        emit CurationParametersSet(curationParams);
    }

    // --- Admin Functions ---

    /**
     * @dev Allows owner to set the addresses of the external token and NFT contracts.
     * Can only be called once after deployment.
     */
    function setTokenAddresses(address _essenceToken, address _forgeNFT, address _artifactNFT) external onlyOwner {
        require(address(essenceToken) == address(0) || address(forgeNFT) == address(0) || address(artifactNFT) == address(0), "Token addresses already set");
        essenceToken = IEssenceToken(_essenceToken);
        forgeNFT = IForgeNFT(_forgeNFT);
        artifactNFT = IArtifactNFT(_artifactNFT);
        emit TokenAddressesSet(_essenceToken, _forgeNFT, _artifactNFT);
    }

    /**
     * @dev Allows owner to adjust staking parameters.
     */
    function setStakingParameters(uint256 _rewardRatePerEssencePerSecond, uint256 _unstakeCooldown) external onlyOwner whenNotPaused {
        stakingParams = StakingParameters({
            rewardRatePerEssencePerSecond: _rewardRatePerEssencePerSecond,
            unstakeCooldown: _unstakeCooldown
        });
        emit StakingParametersSet(stakingParams);
    }

    /**
     * @dev Allows owner to adjust generation parameters.
     */
    function setGenerationParameters(uint256 _essenceCostPerAdvance, uint256 _timePerStage, uint256 _totalGenerationStages, uint256 _forgeMintEssenceCost) external onlyOwner whenNotPaused {
        generationParams = GenerationParameters({
            essenceCostPerAdvance: _essenceCostPerAdvance,
            timePerStage: _timePerStage,
            totalGenerationStages: _totalGenerationStages,
            forgeMintEssenceCost: _forgeMintEssenceCost
        });
        emit GenerationParametersSet(generationParams);
    }

    /**
     * @dev Allows owner to adjust curation parameters.
     */
    function setCurationParameters(uint256 _proposalVotingPeriod, uint256 _minimumStakeForProposal, uint256 _proposalQuorumPercent, uint256 _proposalThresholdPercent) external onlyOwner whenNotPaused {
         require(_proposalQuorumPercent <= 100 && _proposalThresholdPercent <= 100, "Percentages invalid");
        curationParams = CurationParameters({
            proposalVotingPeriod: _proposalVotingPeriod,
            minimumStakeForProposal: _minimumStakeForProposal,
            proposalQuorumPercent: _proposalQuorumPercent,
            proposalThresholdPercent: _proposalThresholdPercent
        });
        emit CurationParametersSet(curationParams);
    }

    /**
     * @dev Pauses core user interactions.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses core user interactions.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }


    // --- Essence Staking Functions ---

    /**
     * @dev Stakes Essence tokens. Requires user to approve GenesisForge to spend tokens.
     */
    function stakeEssence(uint256 amount) external whenNotPaused onlyTokenAddressesSet {
        require(amount > 0, "Stake amount must be > 0");

        // Claim pending rewards before updating stake
        _claimRewards(msg.sender);

        uint256 currentStake = userStake[msg.sender].amount;

        // Transfer Essence from user to this contract
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "Essence transfer failed");

        userStake[msg.sender].amount = currentStake + amount;
        userStake[msg.sender].startTimestamp = block.timestamp; // Reset timer? Or average? Simple: reset.
        userStake[msg.sender].lastClaimTimestamp = block.timestamp;
        userStake[msg.sender].unstakeRequestTimestamp = 0; // Cancel pending unstake

        _totalEssenceStaked += amount;

        emit EssenceStaked(msg.sender, amount);
    }

    /**
     * @dev Initiates the unstaking process. Amount becomes unavailable and starts cooldown.
     */
    function unstakeEssence(uint256 amount) external whenNotPaused onlyTokenAddressesSet {
         require(amount > 0, "Unstake amount must be > 0");
         require(userStake[msg.sender].amount >= amount, "Insufficient staked amount");
         require(userStake[msg.sender].unstakeRequestTimestamp == 0, "Unstake already pending");

        // Claim pending rewards before updating stake
        _claimRewards(msg.sender);

        userStake[msg.sender].amount -= amount;
        userStake[msg.sender].unstakeRequestTimestamp = block.timestamp; // Start cooldown

        // Note: The amount is still counted in _totalEssenceStaked until cooldown finishes and is claimed.
        // A more complex system might move this to a 'cooldown' mapping. For simplicity, we'll check cooldown on claim.

        emit EssenceUnstakeRequested(msg.sender, amount, block.timestamp + stakingParams.unstakeCooldown);
    }

    /**
     * @dev Claims accumulated staking rewards. Also handles unstake finalization after cooldown.
     */
    function claimStakingRewards() external whenNotPaused onlyTokenAddressesSet {
        _claimRewards(msg.sender);
    }

    /**
     * @dev Internal function to calculate and transfer rewards.
     */
    function _claimRewards(address user) internal {
        uint256 pendingRewards = getPendingRewards(user);
        uint256 stakedAmount = userStake[user].amount;
        uint256 unstakeReqTime = userStake[user].unstakeRequestTimestamp;

        // Update last claim time BEFORE transferring to prevent re-entry issues
        userStake[user].lastClaimTimestamp = block.timestamp;

        if (pendingRewards > 0) {
             require(essenceToken.transfer(user, pendingRewards), "Reward transfer failed");
             emit StakingRewardsClaimed(user, pendingRewards);
        }

        // Handle unstake finalization if cooldown is over
        if (unstakeReqTime > 0 && block.timestamp >= unstakeReqTime + stakingParams.unstakeCooldown) {
            uint256 amountToUnstake = stakedAmount; // Amount remaining after unstake request
            userStake[user].amount = 0; // Clear remaining stake
            userStake[user].unstakeRequestTimestamp = 0; // Clear request

            _totalEssenceStaked -= amountToUnstake; // Reduce total staked

            require(essenceToken.transfer(user, amountToUnstake), "Unstake transfer failed");
            emit EssenceUnstaked(user, amountToUnstake);
        }
    }

    /**
     * @dev View function to calculate pending staking rewards for a user.
     */
    function getPendingRewards(address user) public view onlyTokenAddressesSet returns (uint256) {
        uint256 stakedAmount = userStake[user].amount;
        if (stakedAmount == 0) {
            return 0;
        }
        uint256 lastClaim = userStake[user].lastClaimTimestamp;
        uint256 timeElapsed = block.timestamp - lastClaim;

        // Rewards = stakedAmount * rewardRate * timeElapsed
        // Use a multiplier/divisor based on token decimals and rate decimal places if needed
        return (stakedAmount * stakingParams.rewardRatePerEssencePerSecond * timeElapsed) / (10**essenceToken.decimals());
    }

    /**
     * @dev View function to get staked amount for a user.
     */
    function getEssenceStakedBy(address user) external view returns (uint256) {
        return userStake[user].amount;
    }

     /**
     * @dev View function to get total Essence staked in the contract.
     */
    function getTotalEssenceStaked() external view returns (uint256) {
        return _totalEssenceStaked;
    }


    // --- Forge Management Functions ---

    /**
     * @dev Mints a new Forge NFT. Requires burning Essence.
     */
    function mintForge() external whenNotPaused onlyTokenAddressesSet {
        require(essenceToken.transferFrom(msg.sender, address(this), generationParams.forgeMintEssenceCost), "Essence payment for Forge failed");
        uint256 newForgeId = forgeNFT.mint(msg.sender);
        emit ForgeMinted(msg.sender, newForgeId);
    }

    /**
     * @dev View function to get the owner of a Forge NFT.
     */
    function getForgeOwner(uint256 forgeId) external view onlyTokenAddressesSet returns (address) {
        return forgeNFT.ownerOf(forgeId);
    }

     /**
     * @dev View function to get the total count of Forge NFTs.
     */
    function getForgeCount() external view onlyTokenAddressesSet returns (uint256) {
        return forgeNFT.totalSupply();
    }


    // --- Artifact Generation Functions ---

    /**
     * @dev Starts a new artifact generation process using a specific Forge.
     * Requires ownership of the Forge and a minimum staked amount.
     * Forge becomes busy during generation.
     */
    function startArtifactGeneration(uint256 forgeId) external whenNotPaused onlyTokenAddressesSet {
        require(forgeNFT.ownerOf(forgeId) == msg.sender, "Must own the forge to start generation");
        require(forgeToActiveGeneration[forgeId] == 0, "Forge is already busy");
        require(userStake[msg.sender].amount >= generationParams.essenceCostPerAdvance, "Insufficient staked Essence to start generation"); // Requires at least cost of 1 advance

        _nextArtifactGenerationId.increment();
        uint256 generationId = _nextArtifactGenerationId.current();

        // Use a simple on-chain randomness source (NOT secure for high value): block hash, timestamp, nonce
        // For production, use Chainlink VRF or similar.
        uint256 generationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, generationId, _nextArtifactGenerationId.current())));

        artifactGenerations[generationId] = ArtifactGeneration({
            forgeId: forgeId,
            owner: msg.sender,
            currentStage: 0,
            lastStageAdvanceTime: block.timestamp,
            creationTime: block.timestamp,
            artifactTokenId: 0, // Not yet minted
            generationSeed: generationSeed,
            properties: _generateInitialProperties(generationSeed) // Generate initial properties
        });

        forgeToActiveGeneration[forgeId] = generationId;

        emit ArtifactGenerationStarted(generationId, forgeId, msg.sender);
    }

    /**
     * @dev Advances an active artifact generation process to the next stage.
     * Can be called by the owner, requires time elapsed and Essence cost.
     */
    function advanceArtifactGeneration(uint256 generationId) external whenNotPaused onlyTokenAddressesSet whenGenerationActive(generationId) {
        ArtifactGeneration storage gen = artifactGenerations[generationId];
        require(gen.owner == msg.sender, "Must be the generation owner to advance");
        require(gen.currentStage < generationParams.totalGenerationStages - 1, "Generation is already at the final stage");
        require(block.timestamp >= gen.lastStageAdvanceTime + generationParams.timePerStage, "Time minimum between stages not met");
        require(essenceToken.transferFrom(msg.sender, address(this), generationParams.essenceCostPerAdvance), "Essence payment for advance failed");

        gen.currentStage++;
        gen.lastStageAdvanceTime = block.timestamp;
        _updateArtifactProperties(gen); // Update properties based on the new stage and seed

        emit ArtifactGenerationAdvanced(generationId, gen.currentStage, gen.properties);
    }

    /**
     * @dev Finalizes the artifact generation process and mints the Artifact NFT.
     * Can only be called by the owner once all stages are complete.
     */
    function finalizeArtifactGeneration(uint256 generationId) external whenNotPaused onlyTokenAddressesSet whenGenerationActive(generationId) {
        ArtifactGeneration storage gen = artifactGenerations[generationId];
        require(gen.owner == msg.sender, "Must be the generation owner to finalize");
        require(gen.currentStage == generationParams.totalGenerationStages - 1, "Generation is not yet at the final stage");

        // Mint the Artifact NFT
        // We use the generationId as the artifactTokenId for simplicity, assuming 1:1 map
        // In a real system, artifactTokenId would be tracked separately by the ArtifactNFT contract
        uint256 artifactId = generationId; // Use generation ID as token ID for this example
        gen.artifactTokenId = artifactId; // Link generation state to the minted token

        // Prepare data for the NFT
        IArtifactNFT.ArtifactData memory artifactData = IArtifactNFT.ArtifactData({
            generationSeed: gen.generationSeed,
            properties: gen.properties,
            lastUpdateTime: block.timestamp // Initial update time
        });

        artifactNFT.mint(msg.sender, artifactId, artifactData);

        // Unlink forge from generation
        forgeToActiveGeneration[gen.forgeId] = 0;
        artifactIdToGenerationId[artifactId] = generationId;

        // Update reputation for finalizing
        _updateReputation(msg.sender, REPUTATION_PER_FINALIZED_ARTIFACT);

        emit ArtifactGenerationFinalized(generationId, artifactId, msg.sender);
    }

    /**
     * @dev Internal function to generate/update artifact properties based on seed and stage.
     * This is where the "generative" logic would live (simplified here).
     */
    function _generateInitialProperties(uint256 seed) internal pure returns (string[] memory) {
        // Simple example: Initial properties might be based on the seed
        string[] memory props = new string[](2);
        props[0] = string(abi.encodePacked("Color:", uint256(keccak256(abi.encodePacked(seed, "color"))) % 2 == 0 ? "Blue" : "Red"));
        props[1] = string(abi.encodePacked("Shape:", uint256(keccak256(abi.encodePacked(seed, "shape"))) % 2 == 0 ? "Circle" : "Square"));
        return props;
    }

     /**
     * @dev Internal function to advance artifact properties based on stage and seed.
     * This should make properties evolve through stages (simplified here).
     */
    function _updateArtifactProperties(ArtifactGeneration storage gen) internal pure {
        // Example: At stage 1, add Size; at stage 2, modify Color based on time+seed etc.
        // Real generative art would be much more complex, potentially deterministic from seed/stage
        // For this example, we'll just append the stage number to show evolution
        string[] memory currentProps = gen.properties;
        string[] memory newProps = new string[](currentProps.length + 1);
        for(uint i = 0; i < currentProps.length; i++) {
            newProps[i] = currentProps[i];
        }
         newProps[currentProps.length] = string(abi.encodePacked("Stage-", uint256(gen.currentStage), ": AddedFeature", uint256(keccak256(abi.encodePacked(gen.generationSeed, gen.currentStage))) % 100)); // Deterministic based on seed+stage
        gen.properties = newProps;
    }


     /**
     * @dev View function to get the current progress of an active generation.
     */
    function getArtifactGenerationProgress(uint255 generationId) external view whenGenerationActive(generationId) returns (uint256 currentStage, uint256 totalStages, uint256 timeElapsedInStage, uint256 timeRequiredForStage) {
        ArtifactGeneration storage gen = artifactGenerations[generationId];
        return (
            gen.currentStage,
            generationParams.totalGenerationStages,
            block.timestamp - gen.lastStageAdvanceTime,
            generationParams.timePerStage
        );
    }

    /**
     * @dev View function to check if a specific generation ID is currently active (not finalized).
     */
    function isGenerationActive(uint256 generationId) external view returns (bool) {
        return artifactGenerations[generationId].forgeId != 0 && artifactGenerations[generationId].artifactTokenId == 0;
    }

     /**
     * @dev View function to get the owner of an Artifact NFT.
     */
    function getArtifactOwner(uint256 artifactId) external view onlyTokenAddressesSet returns (address) {
        return artifactNFT.ownerOf(artifactId);
    }

    /**
     * @dev View function to get the total count of Artifact NFTs.
     */
    function getArtifactCount() external view onlyTokenAddressesSet returns (uint256) {
        return artifactNFT.totalSupply();
    }


    // --- Artifact Curation/Voting Functions ---

    /**
     * @dev Allows a user with sufficient stake to propose changes to an Artifact's properties.
     */
    function requestPropertyUpdateProposal(uint256 artifactId, string[] calldata newProperties) external whenNotPaused onlyTokenAddressesSet {
        require(userStake[msg.sender].amount >= curationParams.minimumStakeForProposal, "Insufficient stake to create proposal");
        require(artifactNFT.ownerOf(artifactId) != address(0), "Artifact does not exist"); // Check if artifact is minted

        _nextProposalId.increment();
        uint256 proposalId = _nextProposalId.current();

        curationProposals[proposalId] = CurationProposal({
            proposalId: proposalId,
            artifactTokenId: artifactId,
            newProperties: newProperties, // Store the proposed changes
            proposer: msg.sender,
            createTime: block.timestamp,
            voteEndTime: block.timestamp + curationParams.proposalVotingPeriod,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            passed: false
        });
        // Mapping 'voted' is initialized empty

        _updateReputation(msg.sender, REPUTATION_PER_PROPOSAL);

        emit PropertyUpdateProposalCreated(proposalId, artifactId, msg.sender);
    }

    /**
     * @dev Allows a staked user to vote on an active property update proposal.
     * Voting power is based on their current staked amount + reputation (simplified).
     */
    function voteOnPropertyUpdate(uint256 proposalId, bool voteFor) external whenNotPaused onlyTokenAddressesSet {
        CurationProposal storage proposal = curationProposals[proposalId];
        require(proposal.artifactTokenId != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp <= proposal.voteEndTime, "Voting period has ended");
        require(!proposal.voted[msg.sender], "Already voted on this proposal");

        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");

        proposal.voted[msg.sender] = true;

        if (voteFor) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }

        _updateReputation(msg.sender, REPUTATION_PER_VOTE);

        emit VoteCast(proposalId, msg.sender, voteFor, votingPower);
    }

    /**
     * @dev Calculates a user's voting power. Based on stake and reputation.
     */
    function getVotingPower(address user) public view returns (uint256) {
        // Simple calculation: Staked Amount + Reputation * Multiplier
        // Adjust multiplier based on desired impact of reputation vs stake
        uint256 stakePower = userStake[user].amount;
        uint256 reputationPower = playerReputation[user]; // Use 1:1 for simplicity
        return stakePower + reputationPower;
    }

    /**
     * @dev Allows anyone to execute a proposal if the voting period is over and thresholds are met.
     * If passed, updates the Artifact's properties.
     */
    function executePropertyUpdate(uint256 proposalId) external whenNotPaused onlyTokenAddressesSet {
        CurationProposal storage proposal = curationProposals[proposalId];
        require(proposal.artifactTokenId != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.voteEndTime, "Voting period is not over");

        uint256 totalVotesCast = proposal.totalVotesFor + proposal.totalVotesAgainst;

        // Calculate total potential voting power (sum of all current stakers + their reputation)
        // This is hard to calculate accurately on-chain efficiently.
        // A simpler model for quorum is percentage of *cast* votes relative to minimum stake, or rely on off-chain tally.
        // Let's simplify: Quorum is a percentage of a theoretical max power or just rely on threshold of votes *cast*.
        // We'll use a simplified Quorum: total votes cast must be >= QuorumPercent of (TotalEssenceStaked * 1 + TotalReputation * 1) - this is still complex
        // Let's redefine Quorum: total votes cast must be >= QuorumPercent of (MinimumStakeForProposal * Number of Stakers Above Minimum Stake) - still complex
        // Simplest Quorum: Total votes cast must exceed a fixed minimum value OR QuorumPercent of TotalEssenceStaked
        // Let's use: total votes cast must be >= QuorumPercent of Total Essence Staked + Total Reputation Power.
        // Total reputation power calculation is also complex.
        // Okay, simplest Quorum that's sort of meaningful: Total votes cast >= QuorumPercent of the *initial* voting power of all who *could have* voted (i.e., had stake > 0 at start of vote?). Still complex.
        // Let's use a Quorum % of the *current* total voting power (TotalEssenceStaked + sum of all reputation). Calculating sum of all reputation is expensive.
        // Alternative simple Quorum: Total votes cast must be a minimum number (e.g., 1000) AND Total votes cast must be at least X% of Total Staked Essence.
        // Let's use: `totalVotesCast >= (curationParams.proposalQuorumPercent * _totalEssenceStaked / 100)` as a simple proxy, ignoring reputation for quorum. This is still imperfect as reputation adds voting power not Essence.
        // Realistic simple Quorum: Total votes cast must be >= a fixed minimum amount OR Total votes cast must be >= X% of TotalEssenceStaked.
        // Let's use: Total votes cast must be >= X% of Total *Current* Staked Essence. Still ignores reputation for quorum.
        // Final attempt at simple Quorum: Total votes cast must be >= X% of the total amount *staked* at the *time of proposal creation* (snapshot). Requires snapshot logic.
        // Simplest Quorum for this example: Total votes cast must be >= some minimum number (e.g., MIN_VOTES_FOR_QUORUM). Let's add a new param.
        // Revisit: Let's make Quorum simpler. Total Votes Cast >= Quorum Percent * Total Essence Staked. This incentivizes staking.

        uint256 requiredQuorumVotes = (_totalEssenceStaked * curationParams.proposalQuorumPercent) / 100;
        require(totalVotesCast >= requiredQuorumVotes, "Quorum not met");

        // Check if threshold is met
        bool passed = (proposal.totalVotesFor * 100) > (totalVotesCast * curationParams.proposalThresholdPercent);

        proposal.executed = true;
        proposal.passed = passed;

        if (passed) {
            // Update the artifact properties via the ArtifactNFT contract
            artifactNFT.updateArtifactProperties(proposal.artifactTokenId, proposal.newProperties);
        }

        // Rewards/penalties for voters/proposer could go here (e.g., reward stakers who voted on the winning side)

        emit ProposalExecuted(proposalId, proposal.artifactTokenId, passed);
    }

    /**
     * @dev View function to get details of a curation proposal.
     */
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        uint256 artifactId,
        string[] memory proposedProperties,
        address proposer,
        uint256 createTime,
        uint256 voteEndTime,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool passed
    ) {
        CurationProposal storage proposal = curationProposals[proposalId];
        require(proposal.artifactTokenId != 0, "Proposal does not exist");

        return (
            proposal.proposalId,
            proposal.artifactTokenId,
            proposal.newProperties,
            proposal.proposer,
            proposal.createTime,
            proposal.voteEndTime,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.executed,
            proposal.passed
        );
    }


    // --- Reputation Functions ---

    /**
     * @dev View function to get the reputation score for a user.
     */
    function getPlayerReputation(address user) external view returns (uint256) {
        return playerReputation[user];
    }

    /**
     * @dev Internal function to update user reputation.
     */
    function _updateReputation(address user, uint256 amount) internal {
        playerReputation[user] += amount;
        emit ReputationUpdated(user, playerReputation[user]);
    }


    // --- Data / View Functions (Helper for NFT metadata, etc.) ---

    /**
     * @dev Returns the current dynamic properties of a minted artifact.
     * Intended to be called by the IArtifactNFT contract's tokenURI function.
     */
    function getArtifactProperties(uint256 artifactId) external view onlyTokenAddressesSet returns (string[] memory) {
        // Check if artifact exists (by checking if it maps to a generation)
        uint256 generationId = artifactIdToGenerationId[artifactId];
        require(generationId != 0, "Artifact does not exist in this contract's record");

        // Get the artifact data from the ArtifactNFT contract itself (source of truth for minted properties)
        // This requires the IArtifactNFT interface to have a getter for data
        IArtifactNFT.ArtifactData memory data = artifactNFT.getArtifactData(artifactId);
        return data.properties;

        // Alternative (if ArtifactNFT doesn't store properties, GenesisForge does after mint):
        // require(artifactGenerations[generationId].artifactTokenId == artifactId, "Artifact ID mismatch"); // Ensure it's finalized
        // return artifactGenerations[generationId].properties; // If GenesisForge was storing post-mint state
    }
    // NOTE: A real implementation would likely have the ArtifactNFT contract's tokenURI
    // call *this* contract's `getArtifactProperties` view function to fetch the dynamic data
    // and format it into a JSON metadata URI.


    // --- Internal / Helper Functions ---

    /**
     * @dev Simple internal randomness generation. UNSAFE for high-value use cases.
     * Relies on block data + a nonce. Prone to miner manipulation.
     * Use Chainlink VRF or similar in production.
     */
    function _generateRandomness(uint256 extraSeed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, extraSeed, block.number)));
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Orchestration of Multiple Assets:** The `GenesisForge` contract acts as a central hub managing the lifecycle and interactions between distinct ERC-20 (Essence) and ERC-721 (Forges, Artifacts) contracts. This is more complex than a single contract ERC-721 or ERC-20 and models a more realistic DApp architecture.
2.  **Staking for Utility & Rewards:** Essence staking isn't just for passive income; it's the *fuel* for the system. Staked Essence grants voting power and is required to initiate/advance generation. Rewards (`rewardRatePerEssencePerSecond`) incentivize participation.
3.  **Phased Generative Process:** Artifacts aren't minted at once. The `startArtifactGeneration`, `advanceArtifactGeneration`, and `finalizeArtifactGeneration` functions model a process over time (`timePerStage`) and cost (`essenceCostPerAdvance`), where properties evolve deterministically or semi-deterministically based on a seed and the current stage (`_updateArtifactProperties`).
4.  **Dynamic NFTs via External Data:** The `ArtifactNFT` contract's `tokenURI` function (conceptually, not explicitly written here for the NFT contract itself) would call back to the `GenesisForge` contract's `getArtifactProperties` function to fetch the *current* state of the artifact's properties. This makes the NFT metadata dynamic and controlled by the logic within `GenesisForge` and its community.
5.  **Community-Driven Dynamic Property Curation:** The `requestPropertyUpdateProposal`, `voteOnPropertyUpdate`, and `executePropertyUpdate` functions implement a mini-governance system specifically for *modifying* already-minted Artifact properties. Staked Essence holders (with voting power) can influence the evolution of the NFTs post-minting. This adds a unique layer of post-mint interactivity and community influence.
6.  **Voting Power Mechanism:** `getVotingPower` combines staked amount and a simple reputation score, making the voting system slightly more nuanced than just pure token weight.
7.  **Basic Reputation System:** The `playerReputation` mapping and internal `_updateReputation` function track user contributions (proposing, voting, finalizing generation), providing a simple, on-chain measure of participation.
8.  **Parameterized System:** Key parameters like staking rates, generation costs/times, and curation thresholds are stored in state variables and adjustable by the owner (`setStakingParameters`, etc.). This allows for tuning the system's economics and mechanics after deployment.

This contract is a simplified *model* demonstrating the concepts. A full implementation would require separate, more detailed ERC-20 and ERC-721 contracts (handling minting, transfers, approvals, tokenURI), robust error handling, gas optimizations, and potentially a more secure randomness source. The dynamic property updates would need careful design in the actual `IArtifactNFT` contract, likely involving emitting events for off-chain indexers to pick up and update metadata, or having the `tokenURI` directly query `GenesisForge`.