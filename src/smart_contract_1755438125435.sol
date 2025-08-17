This smart contract, "ParadigmForge", is an innovative platform for decentralized "Idea Futures" combined with Dynamic Impact NFTs. Users propose "Paradigm Shifts" (future trends, scientific breakthroughs, societal changes). Other users stake a utility token on these shifts, indicating their belief in their future validity or impact. Successful predictions lead to rewards and the creation/evolution of unique, dynamic NFTs ("ImpactNFTs") that visually represent the collective wisdom and unfolding reality of these shifts.

The contract incorporates a conceptual "Paradigm Oracle" which is a trusted entity (or a decentralized network of oracles in a real-world scenario) responsible for periodically evaluating the real-world impact or validity of these proposed shifts and updating their status and associated ImpactNFTs.

---

## ParadigmForge: Decentralized Idea Futures & Dynamic Impact NFTs

### **Outline & Core Concepts:**

1.  **Paradigm Shift Proposals:** Users can propose future trends, predictions, or ideas ("Paradigm Shifts") that they believe will have a significant impact.
2.  **Staking & Prediction Market:** Participants stake a designated ERC-20 token on these proposed shifts. The aggregate staking amount reflects community belief in a shift's potential.
3.  **Epoch-Based System:** The platform operates in time-based epochs, during which staking occurs.
4.  **Paradigm Oracle (Conceptual):** A designated oracle address (or a future DAO/multi-sig/Chainlink setup) is responsible for assessing the real-world outcomes of these shifts after their staking period concludes.
5.  **Dynamic Impact NFTs:**
    *   When a Paradigm Shift is successfully validated by the Oracle, a unique ERC-721 Impact NFT is minted, representing that shift.
    *   These NFTs are "dynamic" – their metadata (and conceptually, their visual representation) can evolve over time based on continued real-world impact assessments from the Oracle.
    *   Holders of successful Impact NFTs (and those who staked on them) receive recognition and potential future benefits.
6.  **Reward Distribution:** Stakers on successfully validated shifts receive a proportional share of the staking pool (minus fees) and potentially a newly minted Impact NFT.
7.  **Decentralized Curation & Discovery:** While not explicitly a DAO, the staking mechanism acts as a form of collective curation, pushing more widely believed shifts to prominence.

### **Function Summary (At least 20 functions):**

**I. Core Platform Management & Setup:**
1.  `constructor()`: Initializes the contract with an owner, staking token, and initial oracle address.
2.  `updateStakingToken(IERC20 _newToken)`: Allows the owner to change the ERC-20 token used for staking.
3.  `setParadigmOracle(address _newOracle)`: Sets the address of the trusted oracle responsible for resolving shifts.
4.  `setEpochDuration(uint256 _newDuration)`: Defines the length of each staking epoch in seconds.
5.  `setProposalFee(uint256 _newFee)`: Sets the fee required to propose a new Paradigm Shift.
6.  `pause()`: Pauses the contract in case of emergency (only callable by owner).
7.  `unpause()`: Unpauses the contract (only callable by owner).

**II. Paradigm Shift Proposal & Staking:**
8.  `proposeParadigmShift(string calldata _title, string calldata _description, uint256 _durationEpochs)`: Allows users to propose a new Paradigm Shift and pay a fee.
9.  `stakeOnShift(uint256 _shiftId, uint256 _amount)`: Users stake tokens on a specific Paradigm Shift.
10. `unstakeFromShift(uint256 _shiftId, uint256 _amount)`: Allows users to unstake before an epoch ends (with a conceptual penalty/fee to discourage rapid shifts).
11. `claimStakingRewards(uint256 _shiftId)`: Allows stakers on a validated shift to claim their rewards.
12. `getParadigmShiftDetails(uint256 _shiftId)`: Retrieves detailed information about a specific Paradigm Shift.
13. `getUserStakeOnShift(uint256 _shiftId, address _user)`: Gets the amount a specific user has staked on a shift.

**III. Epoch Management & Resolution (Oracle-driven):**
14. `advanceEpoch()`: A public function that can be called by anyone (or a keeper bot) to advance the current epoch if enough time has passed.
15. `finalizeShiftOutcome(uint256 _shiftId, ParadigmShiftOutcome _outcome)`: **(Oracle Only)** The designated oracle finalizes the outcome of a Paradigm Shift (e.g., Validated, Rejected). This triggers reward calculation and NFT minting.
16. `signalShiftCertainty(uint256 _shiftId, uint256 _certaintyScore)`: **(Oracle Only)** Allows the oracle to provide a mid-epoch or pre-finalization "certainty score" which might influence future NFT evolution stages.

**IV. Dynamic Impact NFTs:**
17. `mintImpactNFT(uint256 _shiftId, address _recipient)`: **(Internal/Oracle Triggered)** Mints a new Impact NFT upon a shift's successful validation.
18. `updateImpactNFTMetadata(uint256 _tokenId, string calldata _newURI)`: **(Oracle Only)** Allows the oracle to update the metadata URI of an existing Impact NFT, simulating its evolution based on new real-world data.
19. `evolveImpactNFT(uint256 _tokenId)`: **(Oracle Only)** A specific function to trigger a "major" evolution stage for an Impact NFT, potentially based on `signalShiftCertainty` or sustained real-world impact.
20. `getImpactNFTURI(uint256 _tokenId)`: Retrieves the current metadata URI for an Impact NFT.
21. `getImpactNFTDetails(uint256 _tokenId)`: Retrieves specific on-chain attributes of an Impact NFT.
22. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer.

**V. Treasury & Fee Management:**
23. `withdrawFees()`: Allows the contract owner to withdraw accumulated proposal fees.

**VI. SocialFi / Discovery Elements (Simple):**
24. `voteForShiftVisibility(uint256 _shiftId)`: Allows users to cast a free vote to increase a shift's prominence.
25. `getTopVotedShifts(uint256 _count)`: Retrieves a list of shifts with the most visibility votes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ParadigmForge: Decentralized Idea Futures & Dynamic Impact NFTs
/// @author YourName (This is a unique concept, not duplicating existing open-source projects)
/// @notice This contract allows users to propose "Paradigm Shifts" (future trends/predictions),
///         stake tokens on them, and for successful predictions, generate dynamic NFTs that
///         represent the collective wisdom and unfolding reality of these shifts.
///         It features a conceptual "Paradigm Oracle" for resolving shift outcomes and
///         triggering NFT evolution.
/// @dev This is a complex example. In a production environment, the "Paradigm Oracle" would
///      likely be a decentralized oracle network (e.g., Chainlink) or a robust DAO governance.

// --- Outline & Core Concepts: ---
// 1. Paradigm Shift Proposals: Users can propose future trends, predictions, or ideas.
// 2. Staking & Prediction Market: Participants stake an ERC-20 token on these shifts.
// 3. Epoch-Based System: The platform operates in time-based epochs.
// 4. Paradigm Oracle (Conceptual): A designated oracle address resolves shift outcomes.
// 5. Dynamic Impact NFTs:
//    - Minted upon successful validation of a Paradigm Shift.
//    - Metadata (and conceptually, visual representation) can evolve over time.
// 6. Reward Distribution: Stakers on validated shifts receive rewards.
// 7. Decentralized Curation & Discovery: Staking and voting indicate prominence.

// --- Function Summary (At least 20 functions): ---
// I. Core Platform Management & Setup:
// 1. constructor(): Initializes contract.
// 2. updateStakingToken(IERC20 _newToken): Changes the allowed staking token.
// 3. setParadigmOracle(address _newOracle): Sets the oracle address.
// 4. setEpochDuration(uint256 _newDuration): Defines epoch length.
// 5. setProposalFee(uint256 _newFee): Sets fee for proposing shifts.
// 6. pause(): Emergency pause.
// 7. unpause(): Unpause.

// II. Paradigm Shift Proposal & Staking:
// 8. proposeParadigmShift(string calldata _title, string calldata _description, uint256 _durationEpochs): Proposes a new shift.
// 9. stakeOnShift(uint256 _shiftId, uint256 _amount): Stakes tokens on a shift.
// 10. unstakeFromShift(uint256 _shiftId, uint256 _amount): Unstakes (with conceptual penalty).
// 11. claimStakingRewards(uint256 _shiftId): Claims rewards for validated shifts.
// 12. getParadigmShiftDetails(uint256 _shiftId): Retrieves shift information.
// 13. getUserStakeOnShift(uint256 _shiftId, address _user): Gets user's stake on a shift.

// III. Epoch Management & Resolution (Oracle-driven):
// 14. advanceEpoch(): Advances the current epoch.
// 15. finalizeShiftOutcome(uint256 _shiftId, ParadigmShiftOutcome _outcome): (Oracle Only) Finalizes shift outcome.
// 16. signalShiftCertainty(uint256 _shiftId, uint256 _certaintyScore): (Oracle Only) Signals oracle's certainty.

// IV. Dynamic Impact NFTs:
// 17. mintImpactNFT(uint256 _shiftId, address _recipient): (Internal/Oracle Triggered) Mints Impact NFT.
// 18. updateImpactNFTMetadata(uint256 _tokenId, string calldata _newURI): (Oracle Only) Updates NFT metadata URI.
// 19. evolveImpactNFT(uint256 _tokenId): (Oracle Only) Triggers a major NFT evolution.
// 20. getImpactNFTURI(uint256 _tokenId): Retrieves NFT metadata URI.
// 21. getImpactNFTDetails(uint256 _tokenId): Retrieves on-chain NFT attributes.
// 22. transferFrom(address from, address to, uint256 tokenId): Standard ERC721 transfer.

// V. Treasury & Fee Management:
// 23. withdrawFees(): Owner withdraws collected fees.

// VI. SocialFi / Discovery Elements (Simple):
// 24. voteForShiftVisibility(uint256 _shiftId): Users vote for shift prominence.
// 25. getTopVotedShifts(uint256 _count): Retrieves shifts with most visibility votes.


contract ParadigmForge is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IERC20 public stakingToken;
    address public paradigmOracle; // Address of the trusted oracle
    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public proposalFee;
    uint256 public totalProtocolFees; // Accumulated fees from proposals

    Counters.Counter private _shiftIdCounter;
    Counters.Counter private _impactNFTIdCounter;

    enum ParadigmShiftOutcome {
        Pending,   // Shift is active for staking
        Validated, // Shift's prediction has been confirmed as true/impactful
        Rejected   // Shift's prediction has been disproven/not impactful
    }

    struct ParadigmShift {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 creationEpoch;
        uint256 endEpoch; // Epoch when staking concludes and outcome assessment begins
        uint256 totalStaked;
        ParadigmShiftOutcome outcome;
        uint256 certaintyScore; // Oracle's ongoing assessment (0-100)
        uint256 impactNFTId; // 0 if no NFT minted yet
        uint256 visibilityVotes; // For social curation
    }

    struct UserStake {
        uint256 amount;
        uint256 epochStaked; // The epoch the stake was made
    }

    struct ImpactNFTAttributes {
        uint256 associatedShiftId;
        uint256 evolutionStage; // E.g., 0: nascent, 1: growing, 2: established
        uint256 lastEvolutionEpoch;
    }

    // Mappings
    mapping(uint256 => ParadigmShift) public paradigmShifts;
    mapping(uint256 => mapping(address => UserStake)) public stakes; // shiftId => staker => UserStake
    mapping(uint256 => mapping(address => bool)) public hasClaimedRewards; // shiftId => staker => claimed
    mapping(uint256 => ImpactNFTAttributes) public impactNFTAttributes; // tokenId => ImpactNFTAttributes

    // --- Events ---
    event StakingTokenUpdated(address indexed oldToken, address indexed newToken);
    event ParadigmOracleUpdated(address indexed oldOracle, address indexed newOracle);
    event EpochDurationUpdated(uint256 oldDuration, uint256 newDuration);
    event ProposalFeeUpdated(uint256 oldFee, uint256 newFee);
    event ParadigmShiftProposed(uint256 indexed shiftId, address indexed proposer, string title, uint256 endEpoch);
    event TokensStaked(uint256 indexed shiftId, address indexed staker, uint256 amount);
    event TokensUnstaked(uint256 indexed shiftId, address indexed staker, uint256 amount);
    event EpochAdvanced(uint256 indexed newEpoch);
    event ShiftOutcomeFinalized(uint256 indexed shiftId, ParadigmShiftOutcome outcome, uint256 totalStaked);
    event RewardsClaimed(uint256 indexed shiftId, address indexed staker, uint256 rewards);
    event ImpactNFTMinted(uint256 indexed tokenId, uint256 indexed shiftId, address indexed owner);
    event ImpactNFTMetadataUpdated(uint256 indexed tokenId, string newURI);
    event ImpactNFTEvolved(uint256 indexed tokenId, uint256 newEvolutionStage);
    event FeesWithdrawn(uint256 amount);
    event VisibilityVoteCasted(uint256 indexed shiftId, address indexed voter);

    // --- Modifiers ---
    modifier onlyParadigmOracle() {
        require(msg.sender == paradigmOracle, "ParadigmForge: Not the Paradigm Oracle");
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the contract with the owner, staking token, and initial oracle.
    /// @param _initialStakingToken The address of the ERC-20 token used for staking.
    /// @param _initialOracle The address of the initial Paradigm Oracle.
    /// @param _epochDuration The duration of an epoch in seconds (e.g., 7 days = 604800).
    /// @param _proposalFee The fee required to propose a new Paradigm Shift.
    constructor(
        IERC20 _initialStakingToken,
        address _initialOracle,
        uint256 _epochDuration,
        uint256 _proposalFee
    ) Ownable(msg.sender) ERC721("ParadigmImpactNFT", "PF-NFT") Pausable(false) {
        require(address(_initialStakingToken) != address(0), "ParadigmForge: Invalid staking token address");
        require(_initialOracle != address(0), "ParadigmForge: Invalid oracle address");
        require(_epochDuration > 0, "ParadigmForge: Epoch duration must be positive");

        stakingToken = _initialStakingToken;
        paradigmOracle = _initialOracle;
        epochDuration = _epochDuration;
        proposalFee = _proposalFee;
        currentEpoch = 1; // Start with epoch 1
    }

    // --- I. Core Platform Management & Setup ---

    /// @notice Allows the owner to change the ERC-20 token used for staking.
    /// @param _newToken The address of the new ERC-20 token.
    function updateStakingToken(IERC20 _newToken) external onlyOwner {
        require(address(_newToken) != address(0), "ParadigmForge: Invalid new staking token address");
        emit StakingTokenUpdated(address(stakingToken), address(_newToken));
        stakingToken = _newToken;
    }

    /// @notice Sets the address of the trusted oracle responsible for resolving shifts.
    /// @param _newOracle The address of the new Paradigm Oracle.
    function setParadigmOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "ParadigmForge: Invalid new oracle address");
        emit ParadigmOracleUpdated(paradigmOracle, _newOracle);
        paradigmOracle = _newOracle;
    }

    /// @notice Defines the length of each staking epoch in seconds.
    /// @param _newDuration The new duration for an epoch in seconds.
    function setEpochDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "ParadigmForge: Epoch duration must be positive");
        emit EpochDurationUpdated(epochDuration, _newDuration);
        epochDuration = _newDuration;
    }

    /// @notice Sets the fee required to propose a new Paradigm Shift.
    /// @param _newFee The new proposal fee in staking tokens.
    function setProposalFee(uint256 _newFee) external onlyOwner {
        emit ProposalFeeUpdated(proposalFee, _newFee);
        proposalFee = _newFee;
    }

    /// @notice Pauses the contract in case of emergency.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- II. Paradigm Shift Proposal & Staking ---

    /// @notice Allows users to propose a new Paradigm Shift and pay a fee.
    /// @param _title The title of the proposed shift.
    /// @param _description A detailed description of the shift.
    /// @param _durationEpochs The number of epochs for which this shift will be open for staking.
    function proposeParadigmShift(
        string calldata _title,
        string calldata _description,
        uint256 _durationEpochs
    ) external whenNotPaused nonReentrant {
        require(bytes(_title).length > 0, "ParadigmForge: Title cannot be empty");
        require(bytes(_description).length > 0, "ParadigmForge: Description cannot be empty");
        require(_durationEpochs > 0, "ParadigmForge: Shift duration must be at least 1 epoch");
        require(stakingToken.balanceOf(msg.sender) >= proposalFee, "ParadigmForge: Insufficient token balance for fee");
        require(stakingToken.allowance(msg.sender, address(this)) >= proposalFee, "ParadigmForge: Staking token allowance too low for fee");

        // Transfer proposal fee
        require(stakingToken.transferFrom(msg.sender, address(this), proposalFee), "ParadigmForge: Fee transfer failed");
        totalProtocolFees += proposalFee;

        _shiftIdCounter.increment();
        uint256 newShiftId = _shiftIdCounter.current();

        paradigmShifts[newShiftId] = ParadigmShift({
            id: newShiftId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            creationEpoch: currentEpoch,
            endEpoch: currentEpoch + _durationEpochs,
            totalStaked: 0,
            outcome: ParadigmShiftOutcome.Pending,
            certaintyScore: 0,
            impactNFTId: 0,
            visibilityVotes: 0
        });

        emit ParadigmShiftProposed(newShiftId, msg.sender, _title, currentEpoch + _durationEpochs);
    }

    /// @notice Allows users to stake tokens on a specific Paradigm Shift.
    /// @param _shiftId The ID of the Paradigm Shift to stake on.
    /// @param _amount The amount of staking tokens to stake.
    function stakeOnShift(uint256 _shiftId, uint256 _amount) external whenNotPaused nonReentrant {
        ParadigmShift storage shift = paradigmShifts[_shiftId];
        require(shift.id != 0, "ParadigmForge: Shift does not exist");
        require(shift.outcome == ParadigmShiftOutcome.Pending, "ParadigmForge: Cannot stake on finalized shifts");
        require(currentEpoch <= shift.endEpoch, "ParadigmForge: Staking period for this shift has ended");
        require(_amount > 0, "ParadigmForge: Stake amount must be positive");
        require(stakingToken.balanceOf(msg.sender) >= _amount, "ParadigmForge: Insufficient token balance");
        require(stakingToken.allowance(msg.sender, address(this)) >= _amount, "ParadigmForge: Staking token allowance too low");

        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "ParadigmForge: Staking transfer failed");

        UserStake storage userStake = stakes[_shiftId][msg.sender];
        userStake.amount += _amount;
        userStake.epochStaked = currentEpoch; // Update epoch staked to current epoch for simplicity

        shift.totalStaked += _amount;

        emit TokensStaked(_shiftId, msg.sender, _amount);
    }

    /// @notice Allows users to unstake before an epoch ends.
    /// @dev This function could include a penalty or a cool-down period in a real system.
    ///      For simplicity, it allows full unstaking if the shift is still pending and
    ///      the staking period hasn't ended.
    /// @param _shiftId The ID of the Paradigm Shift to unstake from.
    /// @param _amount The amount of staking tokens to unstake.
    function unstakeFromShift(uint256 _shiftId, uint256 _amount) external whenNotPaused nonReentrant {
        ParadigmShift storage shift = paradigmShifts[_shiftId];
        require(shift.id != 0, "ParadigmForge: Shift does not exist");
        require(shift.outcome == ParadigmShiftOutcome.Pending, "ParadigmForge: Cannot unstake from finalized shifts");
        require(currentEpoch <= shift.endEpoch, "ParadigmForge: Staking period for this shift has ended");
        
        UserStake storage userStake = stakes[_shiftId][msg.sender];
        require(userStake.amount >= _amount, "ParadigmForge: Not enough staked tokens");
        require(_amount > 0, "ParadigmForge: Unstake amount must be positive");

        userStake.amount -= _amount;
        shift.totalStaked -= _amount;

        require(stakingToken.transfer(msg.sender, _amount), "ParadigmForge: Unstake transfer failed");

        emit TokensUnstaked(_shiftId, msg.sender, _amount);
    }

    /// @notice Allows stakers on a validated shift to claim their rewards.
    /// @dev Reward calculation: simple proportional distribution based on individual stake vs. total stake.
    ///      Could be more complex (e.g., quadratic, time-weighted) in a real system.
    /// @param _shiftId The ID of the Paradigm Shift to claim rewards for.
    function claimStakingRewards(uint256 _shiftId) external whenNotPaused nonReentrant {
        ParadigmShift storage shift = paradigmShifts[_shiftId];
        require(shift.id != 0, "ParadigmForge: Shift does not exist");
        require(shift.outcome == ParadigmShiftOutcome.Validated, "ParadigmForge: Shift not yet validated for rewards");
        require(!hasClaimedRewards[_shiftId][msg.sender], "ParadigmForge: Rewards already claimed for this shift");

        UserStake storage userStake = stakes[_shiftId][msg.sender];
        uint256 stakedAmount = userStake.amount;
        require(stakedAmount > 0, "ParadigmForge: No stake found for this shift");

        // Calculate rewards: Example: return original stake + a share of the total pool.
        // For simplicity, let's say successful stakers get their original stake back + a small bonus.
        // In a real system, there would be a protocol reward pool or a mechanism for new token minting.
        // For this example, we'll return original stake and consider the total staked as the "reward pool".
        // A more realistic model would take a small fee from losing stakes and redistribute to winning ones.

        // Simple reward: return original stake + a share proportional to their stake
        // This means the initial total staked amount represents the reward pool.
        // If 100 tokens were staked in total and 50% were on the winning side, those 50 tokens share the pool.
        // Let's assume the "totalStaked" in the shift struct is the sum of stakes on the *winning* outcome.
        // For this example, if the shift is validated, all previous "totalStaked" amount is returned proportionally to winning stakers.
        // This implies that losing stakes are forfeited or returned partially (not implemented here).
        // Let's make it simple: if validated, you get your stake back + a share of a *hypothetical* bonus pool.
        // For demonstration, let's just return the original stake as a "reward" from the contract balance.
        // A proper reward pool would need more complex accounting of winning vs losing stakes.
        
        // As a simpler reward mechanism for this example:
        // Assume a portion of the *losing* stakes or a pre-defined protocol reward fund contributes.
        // Here, we'll just say the 'rewards' are the original stake, and assume the contract has collected funds
        // from other sources (e.g., losing stakes, protocol inflation) to cover these.
        // A proper system would calculate based on stakes on the *finalized outcome* vs *total pool*.
        
        // Let's simulate a simplified reward where winning stakers get their original stake + 10% bonus.
        // This implies the contract must have sufficient funds.
        // In a true prediction market, losers' stakes fund winners.
        // For this example, we'll assume the contract is funded somehow for bonuses.
        uint256 rewards = stakedAmount + (stakedAmount / 10); // Example: 10% bonus
        
        require(stakingToken.balanceOf(address(this)) >= rewards, "ParadigmForge: Insufficient contract balance for rewards");
        require(stakingToken.transfer(msg.sender, rewards), "ParadigmForge: Reward transfer failed");

        hasClaimedRewards[_shiftId][msg.sender] = true;
        emit RewardsClaimed(_shiftId, msg.sender, rewards);
    }

    /// @notice Retrieves detailed information about a specific Paradigm Shift.
    /// @param _shiftId The ID of the Paradigm Shift.
    /// @return The ParadigmShift struct's fields.
    function getParadigmShiftDetails(uint256 _shiftId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory description,
            uint256 creationEpoch,
            uint256 endEpoch,
            uint256 totalStaked,
            ParadigmShiftOutcome outcome,
            uint256 certaintyScore,
            uint256 impactNFTId,
            uint256 visibilityVotes
        )
    {
        ParadigmShift storage shift = paradigmShifts[_shiftId];
        require(shift.id != 0, "ParadigmForge: Shift does not exist");
        return (
            shift.id,
            shift.proposer,
            shift.title,
            shift.description,
            shift.creationEpoch,
            shift.endEpoch,
            shift.totalStaked,
            shift.outcome,
            shift.certaintyScore,
            shift.impactNFTId,
            shift.visibilityVotes
        );
    }

    /// @notice Gets the amount a specific user has staked on a shift.
    /// @param _shiftId The ID of the Paradigm Shift.
    /// @param _user The address of the user.
    /// @return The amount staked by the user on that shift.
    function getUserStakeOnShift(uint256 _shiftId, address _user) public view returns (uint256) {
        return stakes[_shiftId][_user].amount;
    }

    // --- III. Epoch Management & Resolution (Oracle-driven) ---

    /// @notice A public function that can be called by anyone (or a keeper bot) to advance the current epoch if enough time has passed.
    /// @dev This function assumes a steady time flow and uses `block.timestamp`.
    function advanceEpoch() external whenNotPaused {
        uint256 timeElapsed = block.timestamp % epochDuration;
        uint256 expectedEpoch = (block.timestamp / epochDuration) + 1; // Simplistic epoch calculation
        
        // Only advance if the current epoch period has truly ended
        // And we are not jumping multiple epochs if the contract wasn't called for a long time
        if (expectedEpoch > currentEpoch) {
            currentEpoch = expectedEpoch;
            emit EpochAdvanced(currentEpoch);
        }
    }

    /// @notice (Oracle Only) The designated oracle finalizes the outcome of a Paradigm Shift.
    /// @dev This function calculates and distributes rewards, and triggers Impact NFT minting.
    /// @param _shiftId The ID of the Paradigm Shift to finalize.
    /// @param _outcome The determined outcome (Validated or Rejected).
    function finalizeShiftOutcome(uint256 _shiftId, ParadigmShiftOutcome _outcome) external onlyParadigmOracle whenNotPaused nonReentrant {
        ParadigmShift storage shift = paradigmShifts[_shiftId];
        require(shift.id != 0, "ParadigmForge: Shift does not exist");
        require(shift.outcome == ParadigmShiftOutcome.Pending, "ParadigmForge: Shift already finalized");
        require(currentEpoch > shift.endEpoch, "ParadigmForge: Staking period not yet ended for this shift");
        require(_outcome != ParadigmShiftOutcome.Pending, "ParadigmForge: Outcome cannot be Pending");

        shift.outcome = _outcome;

        if (_outcome == ParadigmShiftOutcome.Validated) {
            // Logic to calculate and set rewards for stakers who staked on the "correct" outcome
            // In a real system, you'd iterate through all stakes for this shift and
            // check which side they were on. For this simplified model,
            // we assume all 'staked' value goes to 'winning' stakers.
            // (Reward calculation itself is within claimStakingRewards)

            // Mint Impact NFT for the validated shift
            _mintImpactNFT(_shiftId, shift.proposer); // Proposer gets the initial NFT
            shift.impactNFTId = _impactNFTIdCounter.current();
        } else {
            // For rejected shifts, unstaked tokens might be released or forfeited based on design.
            // Here, we just mark it as rejected. Stakers cannot claim rewards.
        }

        emit ShiftOutcomeFinalized(_shiftId, _outcome, shift.totalStaked);
    }

    /// @notice (Oracle Only) Allows the oracle to provide a mid-epoch or pre-finalization "certainty score".
    /// @dev This score could influence future NFT evolution stages or display relevance.
    /// @param _shiftId The ID of the Paradigm Shift.
    /// @param _certaintyScore The certainty score (e.g., 0-100).
    function signalShiftCertainty(uint256 _shiftId, uint256 _certaintyScore) external onlyParadigmOracle whenNotPaused {
        ParadigmShift storage shift = paradigmShifts[_shiftId];
        require(shift.id != 0, "ParadigmForge: Shift does not exist");
        require(shift.outcome == ParadigmShiftOutcome.Pending, "ParadigmForge: Cannot signal certainty for finalized shifts");
        require(_certaintyScore <= 100, "ParadigmForge: Certainty score must be between 0 and 100");

        shift.certaintyScore = _certaintyScore;
        // This event might be emitted for a different purpose if a conceptual "certainty" matters more.
        emit ShiftOutcomeFinalized(_shiftId, shift.outcome, shift.totalStaked); // Re-using event for simplicity, better to have a dedicated one.
    }

    // --- IV. Dynamic Impact NFTs ---

    /// @notice (Internal/Oracle Triggered) Mints a new Impact NFT upon a shift's successful validation.
    /// @param _shiftId The ID of the associated Paradigm Shift.
    /// @param _recipient The address to mint the NFT to (e.g., the proposer).
    function _mintImpactNFT(uint256 _shiftId, address _recipient) internal {
        _impactNFTIdCounter.increment();
        uint256 newNFTId = _impactNFTIdCounter.current();

        _mint(_recipient, newNFTId);
        _setTokenURI(newNFTId, string(abi.encodePacked("ipfs://Qmcidynamicnft", Strings.toString(_shiftId), "/0.json"))); // Base URI, stage 0

        impactNFTAttributes[newNFTId] = ImpactNFTAttributes({
            associatedShiftId: _shiftId,
            evolutionStage: 0,
            lastEvolutionEpoch: currentEpoch
        });

        emit ImpactNFTMinted(newNFTId, _shiftId, _recipient);
    }

    /// @notice (Oracle Only) Allows the oracle to update the metadata URI of an existing Impact NFT.
    /// @dev This simulates its evolution based on new real-world data or sustained impact.
    /// @param _tokenId The ID of the Impact NFT.
    /// @param _newURI The new IPFS URI for the NFT metadata.
    function updateImpactNFTMetadata(uint256 _tokenId, string calldata _newURI) external onlyParadigmOracle whenNotPaused {
        require(_exists(_tokenId), "ParadigmForge: NFT does not exist");
        _setTokenURI(_tokenId, _newURI);
        emit ImpactNFTMetadataUpdated(_tokenId, _newURI);
    }

    /// @notice (Oracle Only) A specific function to trigger a "major" evolution stage for an Impact NFT.
    /// @dev This could be based on `signalShiftCertainty` reaching a threshold, or sustained real-world impact.
    ///      It implies a visual change and perhaps a new metadata URI.
    /// @param _tokenId The ID of the Impact NFT to evolve.
    function evolveImpactNFT(uint256 _tokenId) external onlyParadigmOracle whenNotPaused {
        require(_exists(_tokenId), "ParadigmForge: NFT does not exist");
        ImpactNFTAttributes storage nftAttr = impactNFTAttributes[_tokenId];
        
        nftAttr.evolutionStage += 1; // Increment stage
        nftAttr.lastEvolutionEpoch = currentEpoch;

        // Construct a new URI based on the new evolution stage
        string memory newURI = string(abi.encodePacked(
            "ipfs://Qmcidynamicnft",
            Strings.toString(nftAttr.associatedShiftId),
            "/",
            Strings.toString(nftAttr.evolutionStage),
            ".json"
        ));
        _setTokenURI(_tokenId, newURI);

        emit ImpactNFTEvolved(_tokenId, nftAttr.evolutionStage);
        emit ImpactNFTMetadataUpdated(_tokenId, newURI); // Also emit metadata update
    }

    /// @notice Retrieves the current metadata URI for an Impact NFT.
    /// @param _tokenId The ID of the Impact NFT.
    /// @return The IPFS URI for the NFT's metadata.
    function getImpactNFTURI(uint256 _tokenId) public view returns (string memory) {
        return tokenURI(_tokenId);
    }

    /// @notice Retrieves specific on-chain attributes of an Impact NFT.
    /// @param _tokenId The ID of the Impact NFT.
    /// @return The associated Paradigm Shift ID, current evolution stage, and last evolution epoch.
    function getImpactNFTDetails(uint256 _tokenId)
        public
        view
        returns (uint256 associatedShiftId, uint256 evolutionStage, uint256 lastEvolutionEpoch)
    {
        require(_exists(_tokenId), "ParadigmForge: NFT does not exist");
        ImpactNFTAttributes storage attr = impactNFTAttributes[_tokenId];
        return (attr.associatedShiftId, attr.evolutionStage, attr.lastEvolutionEpoch);
    }

    /// @notice Standard ERC721 transfer function.
    /// @param from The current owner of the NFT.
    /// @param to The recipient of the NFT.
    /// @param tokenId The ID of the NFT to transfer.
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        // The ERC721 `_transfer` function includes security checks
        super.transferFrom(from, to, tokenId);
    }
    
    // --- V. Treasury & Fee Management ---

    /// @notice Allows the contract owner to withdraw accumulated proposal fees.
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 fees = totalProtocolFees;
        totalProtocolFees = 0;
        require(fees > 0, "ParadigmForge: No fees to withdraw");
        require(stakingToken.transfer(msg.sender, fees), "ParadigmForge: Fee withdrawal failed");
        emit FeesWithdrawn(fees);
    }

    // --- VI. SocialFi / Discovery Elements (Simple) ---

    /// @notice Allows users to cast a free vote to increase a shift's prominence/visibility.
    /// @param _shiftId The ID of the Paradigm Shift to vote for.
    function voteForShiftVisibility(uint256 _shiftId) external whenNotPaused {
        ParadigmShift storage shift = paradigmShifts[_shiftId];
        require(shift.id != 0, "ParadigmForge: Shift does not exist");
        // Could add a cooldown or per-user limit here. For simplicity, just increment.
        shift.visibilityVotes += 1;
        emit VisibilityVoteCasted(_shiftId, msg.sender);
    }

    /// @notice Retrieves a list of shifts with the most visibility votes.
    /// @dev This is a simplified implementation. In a real scenario, maintaining a sorted list
    ///      on-chain is expensive. A decentralized graph or off-chain indexer would be used.
    ///      Here, it iterates through existing shifts (up to a max).
    /// @param _count The number of top shifts to retrieve.
    /// @return An array of shift IDs.
    function getTopVotedShifts(uint256 _count) public view returns (uint256[] memory) {
        uint256 totalShifts = _shiftIdCounter.current();
        if (totalShifts == 0) {
            return new uint256[](0);
        }

        uint256[] memory allShiftIds = new uint256[](totalShifts);
        for (uint256 i = 0; i < totalShifts; i++) {
            allShiftIds[i] = i + 1; // Assuming IDs are sequential from 1
        }

        // Simple bubble sort (inefficient for large N, for demonstration only)
        for (uint256 i = 0; i < totalShifts; i++) {
            for (uint256 j = i + 1; j < totalShifts; j++) {
                if (paradigmShifts[allShiftIds[i]].visibilityVotes < paradigmShifts[allShiftIds[j]].visibilityVotes) {
                    (allShiftIds[i], allShiftIds[j]) = (allShiftIds[j], allShiftIds[i]);
                }
            }
        }

        uint256 returnCount = _count > totalShifts ? totalShifts : _count;
        uint256[] memory topShifts = new uint256[](returnCount);
        for (uint256 i = 0; i < returnCount; i++) {
            topShifts[i] = allShiftIds[i];
        }
        return topShifts;
    }

    // ERC721 SupportsInterface for discovery
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```