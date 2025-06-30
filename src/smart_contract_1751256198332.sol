Okay, let's design a smart contract that simulates a dynamic, micro-ecosystem on-chain. It will involve custom tokens ("ECO"), dynamic NFTs ("Critters"), an evolving environment, contextual staking, and simplified governance over ecosystem parameters. This approach avoids duplicating standard ERC20/ERC721 templates directly and focuses on the *interactions* and *state changes* between components.

**Concept:** The contract is the `CryptoEcosystem`. It manages `ECO` tokens (the resource), `Critters` NFTs (dynamic entities that consume/produce ECO and are affected by the environment), and global `EnvironmentFactors`. Users can mint ECO, mint Critters, feed Critters (burning ECO to improve NFT state), claim ECO produced by Critters (based on NFT state and environment), stake ECO *alongside* Critters for contextual yield, and participate in simplified governance to adjust environment factors.

**Outline & Function Summary:**

1.  **Outline:**
    *   Contract Definition (`CryptoEcosystem`)
    *   Libraries (`SafeMath`)
    *   Custom Errors
    *   State Variables (Token details, NFT details, Ecosystem state, Staking, Governance)
    *   Structs (`Critter`, `Proposal`)
    *   Events
    *   Modifiers (`onlyOwner`, `whenNotPaused`, `onlyCritterOwner`, `whenCritterExists`)
    *   Internal/Helper Functions (e.g., calculating production, checking hunger, updating state)
    *   Core ERC20-like Functions (Custom implementation with twists)
    *   Core ERC721-like Functions (Custom implementation with dynamic aspects)
    *   Critter Interaction Functions (Feed, Evolve, Claim Production)
    *   Environment/Ecosystem State Functions (Read, Trigger Events, Update)
    *   Contextual Staking Functions (Stake/Unstake with Critters, Claim Rewards)
    *   Simplified Governance Functions (Propose, Vote, Execute)
    *   Utility & Admin Functions (Pause, Treasury, etc.)

2.  **Function Summary (Aiming for 20+ unique actions/reads):**
    *   `constructor()`: Initializes the ecosystem, mints initial tokens.
    *   `mintEco(uint256 amount)`: Mints new ECO tokens (controlled).
    *   `transfer(address recipient, uint256 amount)`: Transfers ECO with a potential dynamic tax.
    *   `transferFrom(address sender, address recipient, uint256 amount)`: Transfers ECO via allowance with potential dynamic tax.
    *   `approve(address spender, uint256 amount)`: Standard ERC20 approval.
    *   `allowance(address owner, address spender)`: Standard ERC20 allowance check.
    *   `balanceOf(address account)`: Standard ERC20 balance check.
    *   `totalSupply()`: Standard ERC20 total supply.
    *   `getCirculatingSupply()`: Calculates ECO supply excluding certain sinks (treasury, staking pools).
    *   `burn(uint256 amount)`: Allows users to burn their own ECO.
    *   `mintCritter()`: Mints a new Critter NFT.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers Critter NFT, handles potential state changes on transfer.
    *   `ownerOf(uint256 tokenId)`: Gets owner of a Critter.
    *   `balanceOf(address owner)`: Gets number of Critters owned.
    *   `tokenURI(uint256 tokenId)`: Gets dynamic metadata URI reflecting Critter state.
    *   `getCritterLevel(uint256 tokenId)`: Reads a Critter's current level.
    *   `getCritterHunger(uint256 tokenId)`: Reads a Critter's current hunger level (decays over time conceptually).
    *   `feedCritter(uint256 tokenId, uint256 ecoAmount)`: Burns ECO to reduce Critter hunger and potentially increase level.
    *   `evolveCritter(uint256 tokenId)`: Attempts to evolve a Critter based on internal state (e.g., level, age).
    *   `claimCritterProduction(uint256 tokenId)`: Allows a Critter owner to claim ECO produced by their Critter since last claim, based on level and environment.
    *   `batchFeedCritters(uint256[] calldata tokenIds, uint256 totalEcoAmount)`: Feeds multiple Critters efficiently.
    *   `getEnvironmentFactor(uint256 factorId)`: Reads the value of a specific environmental factor.
    *   `triggerEnvironmentalEvent(uint256 eventId, int256 severity)`: Simulates an external event affecting environment factors (e.g., drought -> lower production).
    *   `stakeEcoForCritter(uint256 tokenId, uint256 amount)`: Stakes ECO tokens, associating them with a specific Critter NFT.
    *   `unstakeEcoForCritter(uint256 tokenId, uint256 amount)`: Unstakes ECO previously linked to a Critter.
    *   `claimStakingRewardsForCritter(uint256 tokenId)`: Claims staking rewards accumulated for ECO staked with a specific Critter.
    *   `getPendingStakingRewards(uint256 tokenId)`: Checks pending rewards for staking linked to a Critter.
    *   `proposeParameterChange(uint256 targetFactorId, int256 newValue, string description)`: Creates a governance proposal to change an environment factor.
    *   `voteOnProposal(uint256 proposalId, bool support)`: Votes on a proposal (voting weight based on staked ECO).
    *   `executeProposal(uint256 proposalId)`: Executes a successful proposal.
    *   `pauseEcosystemActivity()`: Pauses core interactions (feed, claim, stake, etc.) in emergency.
    *   `unpauseEcosystemActivity()`: Unpauses the ecosystem.
    *   `getTreasuryBalance()`: Reads the balance of ECO held by the contract's treasury (from taxes/fees).
    *   `setDynamicTaxRate(uint256 newTaxRate)`: Admin function to update the base dynamic tax rate.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. Contract Definition (CryptoEcosystem)
// 2. Libraries (SafeMath for <= 0.8.0, though 0.8+ has overflow checks built-in, using it explicitly can improve clarity for some)
// 3. Custom Errors
// 4. State Variables (Token details, NFT details, Ecosystem state, Staking, Governance)
// 5. Structs (Critter, Proposal)
// 6. Events
// 7. Modifiers (onlyOwner, whenNotPaused, onlyCritterOwner, whenCritterExists)
// 8. Internal/Helper Functions (e.g., calculating production, checking hunger decay, updating state)
// 9. Core ECO Token Functions (Custom implementation, ERC20-like)
// 10. Core Critter NFT Functions (Custom implementation, ERC721-like, Dynamic)
// 11. Critter Interaction Functions (Feed, Evolve, Claim Production)
// 12. Environment/Ecosystem State Functions (Read, Trigger Events, Update via Governance)
// 13. Contextual Staking Functions (Stake/Unstake with Critters, Claim Rewards)
// 14. Simplified Governance Functions (Propose, Vote, Execute)
// 15. Utility & Admin Functions (Pause, Treasury, Dynamic Tax)

// --- Function Summary ---
// constructor(): Initializes the ecosystem, sets owner, mints initial ECO supply.
// mintEco(uint256 amount): Allows the owner to mint new ECO tokens (controlled supply).
// transfer(address recipient, uint256 amount): Custom ECO transfer function, potentially includes a dynamic tax mechanism.
// transferFrom(address sender, address recipient, uint256 amount): Custom ECO transferFrom function, handles allowance and potential dynamic tax.
// approve(address spender, uint256 amount): Standard ERC20 approve function.
// allowance(address owner, address spender): Standard ERC20 allowance check function.
// balanceOf(address account): Custom ECO balance check function.
// totalSupply(): Returns the total minted supply of ECO tokens.
// getCirculatingSupply(): Calculates and returns the approximate circulating supply (excludes treasury, staking).
// burn(uint256 amount): Allows a token holder to burn their own ECO tokens.
// mintCritter(): Mints a new Critter NFT to the caller. Critters are dynamic and start in a base state.
// safeTransferFrom(address from, address to, uint256 tokenId): Custom Critter NFT transfer function, ensures safety and can include logic triggered by transfer (e.g., state decay).
// ownerOf(uint256 tokenId): Returns the owner of a specific Critter NFT.
// balanceOf(address owner): Returns the number of Critter NFTs owned by an address.
// tokenURI(uint256 tokenId): Returns a dynamic metadata URI for a Critter NFT, reflecting its current state (level, hunger, etc.).
// getCritterLevel(uint256 tokenId): Returns the current level of a Critter. Level affects production and evolution.
// getCritterHunger(uint256 tokenId): Returns the current hunger level of a Critter (0-100). Hunger impacts production negatively and increases over time.
// feedCritter(uint256 tokenId, uint256 ecoAmount): Burns a specified amount of ECO to reduce a Critter's hunger. Feeding contributes to potential level increases.
// evolveCritter(uint256 tokenId): Attempts to evolve a Critter to the next level if conditions (level, hunger, feeding history, maybe environmental factor) are met.
// claimCritterProduction(uint256 tokenId): Allows the Critter owner to claim accumulated ECO production. Production rate depends on Critter level, hunger, and environment factors.
// batchFeedCritters(uint256[] calldata tokenIds, uint256 totalEcoAmount): Feeds multiple Critters owned by the caller with a total specified amount of ECO.
// getEnvironmentFactor(uint256 factorId): Reads the current value of a specific environmental factor (e.g., Resource Abundance, Climate Stress).
// triggerEnvironmentalEvent(uint256 eventId, int256 severity): Owner or authorized role can trigger a simulated environmental event that temporarily or permanently alters environment factors.
// stakeEcoForCritter(uint256 tokenId, uint256 amount): Stakes ECO tokens and links them specifically to a Critter NFT owned by the caller. Staked ECO might boost that Critter or earn contextual rewards.
// unstakeEcoForCritter(uint256 tokenId, uint256 amount): Unstakes ECO previously linked to a Critter.
// claimStakingRewardsForCritter(uint256 tokenId): Claims staking rewards accrued from ECO staked alongside a specific Critter. Rewards might depend on the Critter's state and staking duration.
// getPendingStakingRewards(uint256 tokenId): Checks the amount of staking rewards waiting to be claimed for a Critter-linked stake.
// proposeParameterChange(uint256 targetFactorId, int256 newValue, string description): Allows users with sufficient staked ECO to propose a change to an environment factor.
// voteOnProposal(uint256 proposalId, bool support): Allows users with staked ECO to vote on an active proposal. Voting weight is based on the amount of ECO staked (total or specific type).
// executeProposal(uint256 proposalId): Executes a proposal if it has passed the voting period and threshold.
// pauseEcosystemActivity(): Allows the owner to pause certain sensitive ecosystem interactions in case of emergency.
// unpauseEcosystemActivity(): Allows the owner to unpause the ecosystem.
// getTreasuryBalance(): Returns the amount of ECO tokens held in the contract's treasury (e.g., from transfer taxes).
// setDynamicTaxRate(uint256 newTaxRate): Allows the owner to adjust the base rate for dynamic transfer tax.

// Note: This is a conceptual framework. Full implementation requires significant detail for calculations (production, hunger decay, rewards, voting weight, proposal thresholds) and IPFS/off-chain data handling for tokenURI. State updates like hunger decay would ideally use a "pull" mechanism (calculate decay since last interaction) rather than "push" (require frequent global updates).


import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // For safeTransferFrom
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Helper if contract needs to hold NFTs
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol"; // If future expansion includes ERC1155 resources

// Using SafeMath explicitly for clarity in arithmetic operations
using SafeMath for uint256;
using SafeMath for int256; // For environment factors

contract CryptoEcosystem is IERC721Receiver, ERC721Holder, IERC1155Receiver {
    address public owner;

    // --- State Variables ---

    // ECO Token Details (Custom implementation, not a standard ERC20 contract directly inherited)
    string public constant name = "Crypto Ecosystem Token";
    string public constant symbol = "ECO";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 public dynamicTaxRate = 10; // Base rate in basis points (10 = 0.1%)
    uint256 public taxTreasury; // ECO collected from dynamic tax

    // Critter NFT Details (Custom implementation, not a standard ERC721 contract directly inherited)
    string public constant critterName = "Ecosystem Critter";
    string public constant critterSymbol = "CRTR";
    uint256 private _critterTokenIdCounter;
    mapping(uint256 => address) private _critterOwners;
    mapping(address => uint256) private _critterBalances;
    mapping(uint256 => address) private _critterTokenApprovals;
    mapping(address => mapping(address => bool)) private _critterOperatorApprovals;

    struct Critter {
        uint256 mintTime;
        uint256 lastInteractionTime; // e.g., last fed, last claimed production
        uint8 level; // Starts at 1, max ???
        uint8 hunger; // 0-100, 0 is full, 100 is starving
        uint256 totalEcoConsumed; // Lifetime ECO fed
        uint256 totalEcoProduced; // Lifetime ECO claimed
        // Add more dynamic traits/stats here
    }
    mapping(uint256 => Critter) public critters;
    string public baseCritterMetadataURI; // Base URI for metadata

    // Ecosystem State (Environment Factors)
    // Represented by integer IDs and values. Values can be positive or negative.
    mapping(uint256 => int256) public environmentFactors;
    // Example Factors: 1: Resource Abundance, 2: Climate Stress, 3: Mutation Rate
    // Note: Need a way to define factor meanings and their effects in documentation or config

    // Contextual Staking
    mapping(uint256 => uint256) public stakedEcoByCritter; // Amount of ECO staked *with* a specific Critter NFT
    mapping(uint256 => uint256) public lastRewardClaimTime; // Timestamp of last reward claim for a Critter stake
    // Note: Reward calculation logic is complex and would need external data or on-chain oracle for variable APY.
    // Simplification: Basic time-based accrual based on staked amount and a base rate + Critter bonus.
    uint256 public baseStakingAPY = 5; // Base APY in percentage (e.g., 5 for 5%)
    uint256 public constant APY_DENOMINATOR = 100; // For baseStakingAPY calculation

    // Simplified Governance
    struct Proposal {
        address proposer;
        uint256 targetFactorId;
        int256 newValue;
        uint256 voteCount; // Votes are weighted by staked ECO
        bool executed;
        mapping(address => bool) voted; // To prevent double voting
        uint256 endTimestamp;
        bool exists; // Helper to check if proposalId is valid
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    uint256 public minStakedEcoForProposal = 100 ether; // Example threshold
    uint256 public proposalVotingPeriod = 3 days; // Example duration
    // Note: A robust voting threshold logic is needed (e.g., majority of total staked, quorum)

    // Pause Mechanism
    bool public paused = false;

    // --- Events ---
    event EcoMinted(address indexed account, uint256 amount);
    event EcoTransfer(address indexed from, address indexed to, uint256 amount, uint256 taxAmount);
    event EcoBurned(address indexed account, uint256 amount);
    event CritterMinted(address indexed owner, uint256 indexed tokenId);
    event CritterTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event CritterFed(uint256 indexed tokenId, uint256 amount, uint8 newHunger);
    event CritterLeveledUp(uint256 indexed tokenId, uint8 newLevel);
    event CritterProductionClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event EnvironmentFactorUpdated(uint256 indexed factorId, int256 oldValue, int256 newValue);
    event StakedEcoForCritter(address indexed account, uint256 indexed tokenId, uint256 amount);
    event UnstakedEcoForCritter(address indexed account, uint256 indexed tokenId, uint256 amount);
    event StakingRewardsClaimed(address indexed account, uint256 indexed tokenId, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 targetFactorId, int256 newValue, uint256 endTimestamp);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event EcosystemPaused(address indexed account);
    event EcosystemUnpaused(address indexed account);
    event DynamicTaxRateUpdated(uint256 newRate);


    // --- Custom Errors ---
    error NotOwner();
    error Paused();
    error NotCritterOwner();
    error CritterDoesNotExist();
    error InsufficientBalance(uint256 required, uint256 available);
    error InsufficientAllowance(uint256 required, uint256 available);
    error AmountMustBePositive();
    error InvalidTokenId();
    error CannotFeedZero();
    error CritterAlreadyMaxHunger();
    error CritterCannotEvolveYet();
    error NothingToClaim();
    error InsufficientStakedEcoForProposal(uint256 required, uint256 available);
    error ProposalDoesNotExist();
    error ProposalAlreadyVoted();
    error ProposalVotingPeriodEnded();
    error ProposalNotYetEnded();
    error ProposalCannotBeExecuted(string reason); // e.g., "Did not pass threshold"
    error ZeroAddress();
    error NotApprovedOrOwner();
    error MustUnstakeAll(); // If unstaking partial isn't allowed in some context

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyCritterOwner(uint256 tokenId) {
        if (_critterOwners[tokenId] != msg.sender) revert NotCritterOwner();
        _;
    }

    modifier whenCritterExists(uint256 tokenId) {
        if (_critterOwners[tokenId] == address(0)) revert CritterDoesNotExist();
        _;
        // Check if owner is zero address implies non-existence
    }

    // --- Constructor ---
    constructor(uint256 initialEcoSupply, string memory _baseCritterMetadataURI) {
        owner = msg.sender;
        _totalSupply = initialEcoSupply;
        _balances[msg.sender] = initialEcoSupply; // Mint initial supply to deployer
        baseCritterMetadataURI = _baseCritterMetadataURI;

        emit EcoMinted(msg.sender, initialEcoSupply);

        // Initialize some default environment factors
        environmentFactors[1] = 100; // Resource Abundance (100 = baseline)
        environmentFactors[2] = 0;   // Climate Stress (0 = none)
        environmentFactors[3] = 50;  // Mutation Rate (50 = baseline)
    }

    // --- Internal/Helper Functions ---

    // Calculates decay in hunger since last interaction
    function _calculateHungerDecay(uint256 tokenId) internal view returns (uint8) {
        Critter storage critter = critters[tokenId];
        uint256 timePassed = block.timestamp.sub(critter.lastInteractionTime);
        // Simple linear decay example: 1 hunger point per day
        uint256 decay = timePassed.div(1 days);
        return uint8(decay > 100 ? 100 : decay); // Cap decay at 100
    }

    // Updates critter state including hunger decay
    function _syncCritterState(uint256 tokenId) internal {
        Critter storage critter = critters[tokenId];
        uint8 decay = _calculateHungerDecay(tokenId);
        critter.hunger = uint8(uint256(critter.hunger).add(decay) > 100 ? 100 : uint256(critter.hunger).add(decay));
        critter.lastInteractionTime = block.timestamp; // Update interaction time
    }

    // Calculates potential ECO production amount based on critter state and environment
    function _calculateCritterProduction(uint256 tokenId) internal view returns (uint256) {
        Critter storage critter = critters[tokenId];
        if (critter.hunger >= 80) return 0; // Very hungry critters produce nothing

        uint256 timeSinceLastClaim = block.timestamp.sub(critter.lastInteractionTime);
        // Base production per day (adjust based on level)
        uint256 baseProductionPerDay = uint256(critter.level).mul(1 ether); // Example: 1 ECO per level per day

        // Adjust production based on hunger (linear reduction for 0-80 hunger)
        uint256 hungerPenalty = critter.hunger.mul(baseProductionPerDay).div(80); // 0 penalty at 0 hunger, full penalty at 80
        uint256 hungerAdjustedProduction = baseProductionPerDay.sub(hungerPenalty);

        // Adjust production based on environment factors (Example: Resource Abundance factor)
        int256 resourceAbundance = environmentFactors[1]; // Assume Factor 1 is Resource Abundance
        // Simple multiplier: If abundance is 100 (base), multiplier is 1x. If 200, 2x. If 50, 0.5x.
        // Need to handle negative factors or different factor types.
        // Example: Multiplier = (100 + resourceAbundance) / 100
        uint256 envMultiplier = uint256(100).add(uint256(resourceAbundance)).div(100); // Needs careful handling of negative resourceAbundance if allowed

        uint256 dailyProduction = hungerAdjustedProduction.mul(envMultiplier);

        // Production is based on time since last claim
        uint256 totalProduction = dailyProduction.mul(timeSinceLastClaim).div(1 days);

        return totalProduction;
    }

    // Internal ECO transfer function with tax
    function _transfer(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0) || recipient == address(0)) revert ZeroAddress();
        if (amount == 0) return; // Allow 0 amount transfers

        // Calculate dynamic tax
        uint256 taxAmount = amount.mul(dynamicTaxRate).div(10000); // Tax rate is in basis points
        uint256 amountToSend = amount.sub(taxAmount);

        // Ensure sender has enough balance
        if (_balances[sender] < amount) revert InsufficientBalance(amount, _balances[sender]);

        // Update balances
        _balances[sender] = _balances[sender].sub(amount); // Subtract full amount from sender
        _balances[recipient] = _balances[recipient].add(amountToSend); // Add taxed amount to recipient

        // Add tax to treasury
        taxTreasury = taxTreasury.add(taxAmount);

        emit EcoTransfer(sender, recipient, amountToSend, taxAmount);
    }

    // Internal Critter minting logic
    function _mintCritter(address to, uint256 tokenId) internal {
        if (to == address(0)) revert ZeroAddress();
        if (_critterOwners[tokenId] != address(0)) revert InvalidTokenId(); // Should not happen with counter

        _critterOwners[tokenId] = to;
        _critterBalances[to] = _critterBalances[to].add(1);
        critters[tokenId] = Critter({
            mintTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            level: 1,
            hunger: 50, // Start moderately hungry
            totalEcoConsumed: 0,
            totalEcoProduced: 0
        });

        emit CritterMinted(to, tokenId);
    }

    // Internal Critter burning logic (if needed)
    function _burnCritter(uint256 tokenId) internal {
         address owner_ = _critterOwners[tokenId];
         if (owner_ == address(0)) revert InvalidTokenId(); // Already burned or non-existent

         // Clear approvals
         _critterTokenApprovals[tokenId] = address(0);

         // Update state
         _critterBalances[owner_] = _critterBalances[owner_].sub(1);
         _critterOwners[tokenId] = address(0); // Mark as burned

         // Delete critter data (optional, saves gas on reads for non-existent NFTs)
         delete critters[tokenId];
         delete stakedEcoByCritter[tokenId]; // Clean up linked staking

         // Note: ERC721 standard emit event Transfer(owner_, address(0), tokenId);
         emit CritterTransfer(owner_, address(0), tokenId);
    }


    // --- Core ECO Token Functions (Custom) ---

    /**
     * @dev Mints new ECO tokens. Callable only by the owner.
     * @param amount The amount of tokens to mint.
     */
    function mintEco(uint256 amount) external onlyOwner {
        if (amount == 0) revert AmountMustBePositive();
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit EcoMinted(msg.sender, amount);
    }

    /**
     * @dev Transfers ECO tokens from the caller to a recipient. Includes a dynamic tax.
     * @param recipient The address to send tokens to.
     * @param amount The amount of tokens to send.
     */
    function transfer(address recipient, uint256 amount) external whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Transfers ECO tokens from one address to another using the allowance mechanism. Includes a dynamic tax.
     * @param sender The address of the token holder.
     * @param recipient The address to send tokens to.
     * @param amount The amount of tokens to send.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external whenNotPaused returns (bool) {
        if (_allowances[sender][msg.sender] < amount) revert InsufficientAllowance(amount, _allowances[sender][msg.sender]);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Approves a spender to spend tokens on behalf of the caller. Standard ERC20 function.
     * @param spender The address to approve.
     * @param amount The amount of tokens the spender can spend.
     */
    function approve(address spender, uint256 amount) external whenNotPaused returns (bool) {
        _allowances[msg.sender][spender] = amount;
        // ERC20 standard emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Returns the allowance amount granted from owner to spender. Standard ERC20 function.
     * @param owner The address of the token holder.
     * @param spender The address of the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Returns the balance of a specific account. Custom implementation.
     * @param account The address to query the balance for.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the total minted supply of ECO tokens.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Calculates and returns the approximate circulating supply of ECO tokens.
     * Excludes tokens held in the treasury and currently staked.
     */
    function getCirculatingSupply() external view returns (uint256) {
        uint256 totalStaked = 0;
        // Iterate through all critter IDs that might have staked ECO - potentially inefficient for many critters
        // A better approach for production would track total staked amount separately.
        // For this example, we'll just show the concept (simplified loop or reliance on known IDs).
        // Let's simplify and exclude treasury and assume stakedEcoByCritter is the only major sink beyond balances.
        // A more accurate way needs iterating all critter IDs that have > 0 stakedEcoByCritter, or maintaining a separate counter.
        // Assuming a helper function `getTotalStakedEco()` exists or calculating it here conceptually:
        // uint256 totalStaked = _getTotalStakedEco(); // Would need to iterate over all staked critters or maintain a sum

        // Placeholder: Let's just subtract treasury for a simple "circulating" view.
        return _totalSupply.sub(taxTreasury); // This is a very basic definition of circulating
        // A more advanced version would exclude tokens in known contracts, specific locked vaults, etc.
    }

    /**
     * @dev Burns a specified amount of tokens from the caller's balance.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external whenNotPaused {
        if (amount == 0) revert AmountMustBePositive();
        if (_balances[msg.sender] < amount) revert InsufficientBalance(amount, _balances[msg.sender]);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit EcoBurned(msg.sender, amount);
    }

    /**
     * @dev Returns the current balance of ECO in the treasury (collected via dynamic tax).
     */
    function getTreasuryBalance() external view returns (uint256) {
        return taxTreasury;
    }

    /**
     * @dev Allows the owner to set the base dynamic transfer tax rate.
     * @param newTaxRate The new tax rate in basis points (e.g., 10 for 0.1%).
     */
    function setDynamicTaxRate(uint256 newTaxRate) external onlyOwner {
        // Add validation if needed (e.g., cap the max rate)
        dynamicTaxRate = newTaxRate;
        emit DynamicTaxRateUpdated(newTaxRate);
    }


    // --- Core Critter NFT Functions (Custom, Dynamic ERC721-like) ---

    /**
     * @dev Mints a new Critter NFT to the caller.
     * New Critters start at Level 1 with default hunger.
     */
    function mintCritter() external whenNotPaused {
        uint256 newTokenId = _critterTokenIdCounter;
        _critterTokenIdCounter = _critterTokenIdCounter.add(1);
        _mintCritter(msg.sender, newTokenId);
    }

    /**
     * @dev Transfers a Critter NFT safely. Custom implementation.
     * Includes logic to potentially sync Critter state before transfer.
     * @param from The current owner of the Critter.
     * @param to The recipient address.
     * @param tokenId The ID of the Critter NFT.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused whenCritterExists(tokenId) {
        if (_critterOwners[tokenId] != from) revert NotCritterOwner(); // Ensure 'from' is the actual owner
        if (to == address(0)) revert ZeroAddress();

        // Check approval or operator status
        if (_critterTokenApprovals[tokenId] != msg.sender && _critterOperatorApprovals[from][msg.sender] == false && from != msg.sender) {
            revert NotApprovedOrOwner();
        }

        // Sync critter state (e.g., hunger decay) before transferring
        _syncCritterState(tokenId); // Hunger decay happens now

        // Clear approval for the transferred token
        _critterTokenApprovals[tokenId] = address(0);

        // Update balances and ownership
        _critterBalances[from] = _critterBalances[from].sub(1);
        _critterBalances[to] = _critterBalances[to].add(1);
        _critterOwners[tokenId] = to;

        emit CritterTransfer(from, to, tokenId);

        // Check if 'to' is a contract and supports ERC721Receiver (standard ERC721 behavior)
        // This part requires IERC721Receiver and implementing onERC721Received
        // Skip contract check for simplicity in this example, but add in production code
        // if (to.code.length > 0 && !IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, "").bytes4 == IERC721Receiver.onERC721Received.selector) {
        //     revert ERC721ReceiveRejected(); // Custom error for safety
        // }
    }

    // onERC721Received implementation is required if safeTransferFrom includes the check
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This contract accepts ERC721 tokens (e.g., if Critters could own other NFTs)
        // Return the ERC721Receiver interface ID
        return this.onERC721Received.selector;
    }
     // onERC1155Received and onERC1155BatchReceived implementations if receiving ERC1155
     function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) { return this.onERC1155Received.selector; }
     function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns (bytes4) { return this.onERC1155BatchReceived.selector; }


    /**
     * @dev Returns the owner of a specific Critter NFT. Standard ERC721 function.
     * @param tokenId The ID of the Critter NFT.
     */
    function ownerOf(uint256 tokenId) public view whenCritterExists(tokenId) returns (address) {
        return _critterOwners[tokenId];
    }

    /**
     * @dev Returns the number of Critter NFTs owned by an address. Standard ERC721 function.
     * @param owner The address to query.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _critterBalances[owner];
    }

     // ERC721 Approval functions (basic implementation)
    function approve(address to, uint256 tokenId) public whenNotPaused onlyCritterOwner(tokenId) {
        _critterTokenApprovals[tokenId] = to;
        // ERC721 standard emit Approval(msg.sender, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        _critterOperatorApprovals[msg.sender][operator] = approved;
        // ERC721 standard emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view whenCritterExists(tokenId) returns (address) {
        return _critterTokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _critterOperatorApprovals[owner][operator];
    }

    /**
     * @dev Returns a dynamic metadata URI for a Critter NFT.
     * This URI should point to a JSON file reflecting the Critter's current state (level, hunger, etc.).
     * @param tokenId The ID of the Critter NFT.
     */
    function tokenURI(uint256 tokenId) external view whenCritterExists(tokenId) returns (string memory) {
        Critter storage critter = critters[tokenId];
        // In a real dapp, this would construct a URL pointing to an API or IPFS gateway
        // that generates JSON based on the Critter struct data.
        // Example: return string(abi.encodePacked(baseCritterMetadataURI, "/", Strings.toString(tokenId), "?level=", Strings.toString(critter.level), "&hunger=", Strings.toString(critter.hunger)));
        // Using a simplified placeholder here:
        return string(abi.encodePacked(baseCritterMetadataURI, "/", uint256ToString(tokenId)));
    }

    // Basic uint256 to string helper (requires more robust implementation for production)
    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }


    /**
     * @dev Returns the current level of a Critter.
     * @param tokenId The ID of the Critter NFT.
     */
    function getCritterLevel(uint256 tokenId) external view whenCritterExists(tokenId) returns (uint8) {
        return critters[tokenId].level;
    }

    /**
     * @dev Returns the current hunger level of a Critter (0-100).
     * Automatically syncs state to account for decay before returning.
     * @param tokenId The ID of the Critter NFT.
     */
    function getCritterHunger(uint256 tokenId) public view whenCritterExists(tokenId) returns (uint8) {
        Critter storage critter = critters[tokenId];
        // Calculate current hunger including decay since last interaction
        uint8 decay = _calculateHungerDecay(tokenId);
        uint256 currentHunger = uint256(critter.hunger).add(decay);
        return uint8(currentHunger > 100 ? 100 : currentHunger);
    }


    // --- Critter Interaction Functions ---

    /**
     * @dev Burns a specified amount of ECO from the caller to feed their Critter.
     * Reduces hunger and contributes to potential level-ups.
     * @param tokenId The ID of the Critter NFT to feed.
     * @param ecoAmount The amount of ECO to feed (and burn).
     */
    function feedCritter(uint256 tokenId, uint256 ecoAmount) external whenNotPaused onlyCritterOwner(tokenId) whenCritterExists(tokenId) {
        if (ecoAmount == 0) revert CannotFeedZero();

        // Burn the ECO from the caller's balance
        if (_balances[msg.sender] < ecoAmount) revert InsufficientBalance(ecoAmount, _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(ecoAmount);
        _totalSupply = _totalSupply.sub(ecoAmount); // ECO is burned

        Critter storage critter = critters[tokenId];

        // Sync state (hunger decay) before feeding
        _syncCritterState(tokenId);

        // Feeding reduces hunger (Example: 1 ECO reduces hunger by 1 point, capped at 0)
        uint256 hungerReduction = ecoAmount; // Simple 1:1 example
        critter.hunger = uint8(uint256(critter.hunger).sub(hungerReduction > critter.hunger ? critter.hunger : hungerReduction)); // Prevent underflow

        // Feeding contributes to total consumed ECO, which might be an evolution requirement
        critter.totalEcoConsumed = critter.totalEcoConsumed.add(ecoAmount);
        critter.lastInteractionTime = block.timestamp; // Update interaction time

        emit EcoBurned(msg.sender, ecoAmount);
        emit CritterFed(tokenId, ecoAmount, critter.hunger);

        // Optional: Check for level up possibility immediately after feeding
        // if (_canEvolve(tokenId)) { emit CritterReadyToEvolve(tokenId); }
    }

    /**
     * @dev Attempts to evolve a Critter to the next level.
     * Requires the Critter to meet certain conditions (e.g., minimum level, low hunger, sufficient feeding history).
     * Evolution changes the Critter's state permanently.
     * @param tokenId The ID of the Critter NFT to evolve.
     */
    function evolveCritter(uint256 tokenId) external whenNotPaused onlyCritterOwner(tokenId) whenCritterExists(tokenId) {
        Critter storage critter = critters[tokenId];

        // Sync state before checking evolution criteria
        _syncCritterState(tokenId);

        // Example Evolution Criteria (make this more complex and dynamic):
        // - Must be below max level (let's say max level is 10)
        // - Hunger must be low (e.g., <= 20)
        // - Must have consumed a certain amount of ECO since the last level-up (hard to track per level up without more state)
        // - Must have reached a certain age (time since last evolution or mint)
        // - Environment Factor might influence chance or requirement

        uint8 maxLevel = 10; // Example max level

        if (critter.level >= maxLevel) revert CritterCannotEvolveYet();
        if (critter.hunger > 20) revert CritterCannotEvolveYet();
        // Add more complex checks here based on `critter.mintTime`, `critter.lastInteractionTime`, `critter.totalEcoConsumed`, `environmentFactors`, etc.
        // Example: if (critter.mintTime.add(uint256(critter.level).mul(7 days)) > block.timestamp) revert CritterCannotEvolveYet(); // Must be at least 7 days per level old

        // If evolution criteria met:
        critter.level = critter.level.add(1);
        // Reset some stats or provide bonuses on evolution
        critter.hunger = uint8(uint256(critter.hunger).mul(50).div(100)); // Hunger halved on level up example
        // critter.totalEcoConsumed = 0; // Reset consumption counter for next level?

        critter.lastInteractionTime = block.timestamp; // Evolution counts as interaction

        emit CritterLeveledUp(tokenId, critter.level);
    }

    /**
     * @dev Allows a Critter owner to claim accumulated ECO production.
     * Production rate depends dynamically on Critter level, hunger, and environment factors.
     * Resets the production timer for that Critter.
     * @param tokenId The ID of the Critter NFT to claim production from.
     */
    function claimCritterProduction(uint256 tokenId) external whenNotPaused onlyCritterOwner(tokenId) whenCritterExists(tokenId) {
        Critter storage critter = critters[tokenId];

        // Sync state (hunger decay affects production calculation)
        _syncCritterState(tokenId);

        uint256 amount = _calculateCritterProduction(tokenId);

        if (amount == 0) revert NothingToClaim();

        // Mint the calculated ECO to the owner
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // Update critter stats
        critter.totalEcoProduced = critter.totalEcoProduced.add(amount);
        critter.lastInteractionTime = block.timestamp; // Claiming production counts as interaction

        emit EcoMinted(msg.sender, amount); // Can emit Minted or a specific ProductionClaimed event
        emit CritterProductionClaimed(tokenId, msg.sender, amount);
    }

    /**
     * @dev Allows the caller to feed multiple of their Critters in a single transaction.
     * The total `totalEcoAmount` is divided among the specified Critters.
     * Note: Logic for dividing the amount (e.g., equally, based on hunger) needs to be defined.
     * Example here divides equally.
     * @param tokenIds An array of Critter NFT IDs owned by the caller.
     * @param totalEcoAmount The total amount of ECO to burn and distribute among the Critters.
     */
    function batchFeedCritters(uint256[] calldata tokenIds, uint256 totalEcoAmount) external whenNotPaused {
        uint256 numCritters = tokenIds.length;
        if (numCritters == 0 || totalEcoAmount == 0) revert AmountMustBePositive(); // Reusing error for 0 amounts

        // Ensure caller owns all Critters
        for (uint256 i = 0; i < numCritters; i++) {
            if (_critterOwners[tokenIds[i]] != msg.sender) revert NotCritterOwner(); // Or specific batch error
            if (_critterOwners[tokenIds[i]] == address(0)) revert CritterDoesNotExist(); // Should not happen if owned check passes, but defensive
        }

        // Burn the total ECO from the caller's balance
        if (_balances[msg.sender] < totalEcoAmount) revert InsufficientBalance(totalEcoAmount, _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(totalEcoAmount);
        _totalSupply = _totalSupply.sub(totalEcoAmount); // ECO is burned
        emit EcoBurned(msg.sender, totalEcoAmount);

        // Distribute ECO effect (hunger reduction) to each critter
        uint256 ecoPerCritter = totalEcoAmount.div(numCritters);
        for (uint256 i = 0; i < numCritters; i++) {
            uint256 tokenId = tokenIds[i];
            Critter storage critter = critters[tokenId];

             // Sync state before feeding
            _syncCritterState(tokenId);

            // Feeding reduces hunger (Example: 1:1, capped at 0)
            uint256 hungerReduction = ecoPerCritter;
            critter.hunger = uint8(uint256(critter.hunger).sub(hungerReduction > critter.hunger ? critter.hunger : hungerReduction));

            critter.totalEcoConsumed = critter.totalEcoConsumed.add(ecoPerCritter); // Track consumed
            critter.lastInteractionTime = block.timestamp; // Update interaction time

            emit CritterFed(tokenId, ecoPerCritter, critter.hunger);
        }
    }

    // --- Environment/Ecosystem State Functions ---

    /**
     * @dev Returns the current value of a specific environmental factor.
     * @param factorId The ID of the environmental factor to query.
     */
    function getEnvironmentFactor(uint256 factorId) external view returns (int256) {
        // Returns 0 if factorId hasn't been set, which might be a valid state
        return environmentFactors[factorId];
    }

    /**
     * @dev Simulates an external environmental event, allowing the owner to adjust factors.
     * In a more complex system, this could be triggered by oracles, time, or contract activity.
     * @param factorId The ID of the environmental factor to modify.
     * @param change The amount to add to the current factor value.
     */
    function triggerEnvironmentalEvent(uint256 factorId, int256 change) external onlyOwner {
        int256 oldValue = environmentFactors[factorId];
        // Needs care for overflow/underflow with int256 add/sub
        environmentFactors[factorId] = oldValue.add(change);
        emit EnvironmentFactorUpdated(factorId, oldValue, environmentFactors[factorId]);
        // EventId and severity parameters from summary not strictly used in this simple version, but useful for logging
    }


    // --- Contextual Staking Functions ---

    /**
     * @dev Stakes a specified amount of ECO tokens, linking them to a Critter NFT owned by the caller.
     * This stake is separate from the user's main balance and might provide bonuses related to the Critter.
     * @param tokenId The ID of the Critter NFT to stake ECO with. Must be owned by the caller.
     * @param amount The amount of ECO to stake.
     */
    function stakeEcoForCritter(uint256 tokenId, uint256 amount) external whenNotPaused onlyCritterOwner(tokenId) whenCritterExists(tokenId) {
        if (amount == 0) revert AmountMustBePositive();
        if (_balances[msg.sender] < amount) revert InsufficientBalance(amount, _balances[msg.sender]);

        // Transfer ECO from user balance to contract staking pool
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakedEcoByCritter[tokenId] = stakedEcoByCritter[tokenId].add(amount);

        // Set last claim time if this is the first stake or if it's been claimed
        if (lastRewardClaimTime[tokenId] == 0 || stakedEcoByCritter[tokenId].sub(amount) == 0) { // Check if it was empty before this stake
             lastRewardClaimTime[tokenId] = block.timestamp;
        }
        // Note: Adding to an existing stake *could* reset timer or dilute rewards depending on desired mechanic.
        // Simple model just adds amount and keeps last claim time.

        emit StakedEcoForCritter(msg.sender, tokenId, amount);
    }

    /**
     * @dev Unstakes a specified amount of ECO tokens previously linked to a Critter.
     * @param tokenId The ID of the Critter NFT the ECO is staked with. Must be owned by the caller.
     * @param amount The amount of ECO to unstake.
     */
    function unstakeEcoForCritter(uint256 tokenId, uint256 amount) external whenNotPaused onlyCritterOwner(tokenId) whenCritterExists(tokenId) {
        if (amount == 0) revert AmountMustBePositive();
        if (stakedEcoByCritter[tokenId] < amount) revert InsufficientBalance(amount, stakedEcoByCritter[tokenId]); // Use InsufficientBalance error

        // Claim pending rewards first (optional, but good practice)
        // _claimStakingRewardsForCritter(tokenId); // Internal call to claim rewards before unstaking

        // Transfer ECO from contract staking pool back to user balance
        stakedEcoByCritter[tokenId] = stakedEcoByCritter[tokenId].sub(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // Reset claim time if stake becomes 0
         if (stakedEcoByCritter[tokenId] == 0) {
             lastRewardClaimTime[tokenId] = 0;
         }


        emit UnstakedEcoForCritter(msg.sender, tokenId, amount);
    }

    /**
     * @dev Calculates the pending staking rewards for ECO staked with a specific Critter.
     * Rewards accrue based on staked amount, time, base APY, and potentially Critter level/state.
     * @param tokenId The ID of the Critter NFT to check rewards for.
     */
    function getPendingStakingRewards(uint256 tokenId) public view whenCritterExists(tokenId) returns (uint256) {
        uint256 stakedAmount = stakedEcoByCritter[tokenId];
        if (stakedAmount == 0 || lastRewardClaimTime[tokenId] == 0) return 0;

        uint256 timeStaked = block.timestamp.sub(lastRewardClaimTime[tokenId]);
        if (timeStaked == 0) return 0;

        // Basic reward calculation: staked * APY * time / timeUnit
        // Assuming base APY is per year and block.timestamp is in seconds
        uint256 baseAPY = baseStakingAPY;
        // Example: Add Critter level bonus to APY
        // uint256 critterBonusAPY = uint256(critters[tokenId].level).mul(1); // 1% bonus per level
        // uint256 effectiveAPY = baseAPY.add(critterBonusAPY); // Cap effectiveAPY if needed

        uint256 rewards = stakedAmount.mul(baseAPY).mul(timeStaked).div(APY_DENOMINATOR).div(1 years); // Need 1 years constant (31536000 seconds)
        // Define 1 years = 31536000 outside
        uint256 SECONDS_PER_YEAR = 31536000;
        rewards = stakedAmount.mul(baseAPY).mul(timeStaked).div(APY_DENOMINATOR).div(SECONDS_PER_YEAR);

        // Apply environmental factor to reward rate?
        // int256 climateStress = environmentFactors[2];
        // uint256 envRewardMultiplier = uint256(100).sub(uint256(climateStress)).div(100); // Stress reduces rewards
        // rewards = rewards.mul(envRewardMultiplier); // Care needed for negative factors

        return rewards;
    }

     /**
     * @dev Claims staking rewards accrued from ECO staked alongside a specific Critter.
     * Rewards are minted to the caller.
     * @param tokenId The ID of the Critter NFT to claim rewards for. Must be owned by the caller.
     */
    function claimStakingRewardsForCritter(uint256 tokenId) public whenNotPaused onlyCritterOwner(tokenId) whenCritterExists(tokenId) {
         // Claiming can be public or internal. Making it public here.
         // An internal version could be called by unstakeEcoForCritter.
        uint256 rewards = getPendingStakingRewards(tokenId);

        if (rewards == 0) revert NothingToClaim();

        // Mint rewards to the owner
        _totalSupply = _totalSupply.add(rewards);
        _balances[msg.sender] = _balances[msg.sender].add(rewards);

        // Reset reward claim timer for this stake
        lastRewardClaimTime[tokenId] = block.timestamp;

        emit EcoMinted(msg.sender, rewards); // Or a specific StakingRewardMinted event
        emit StakingRewardsClaimed(msg.sender, tokenId, rewards);
    }


    // --- Simplified Governance Functions ---

    /**
     * @dev Allows users with sufficient staked ECO to propose a change to an environmental factor.
     * A proposal targets a specific factor and a new value.
     * @param targetFactorId The ID of the environmental factor to propose changing.
     * @param newValue The proposed new value for the factor.
     * @param description A string describing the proposal.
     */
    function proposeParameterChange(uint256 targetFactorId, int256 newValue, string memory description) external whenNotPaused {
        // Check if caller has minimum staked ECO (using total staked across all their critters as voting weight)
        uint256 callerTotalStaked = 0; // Need a way to track total staked per user efficiently
        // This requires iterating through all critters owned by the user and summing stakedEcoByCritter,
        // which is inefficient. A mapping(address => uint256) totalStakedByUser would be better.
        // For this example, we will skip the staked amount check and assume any staked amount allows proposing.
        // if (totalStakedByUser[msg.sender] < minStakedEcoForProposal) revert InsufficientStakedEcoForProposal(minStakedEcoForProposal, totalStakedByUser[msg.sender]);

        uint256 proposalId = nextProposalId;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            targetFactorId: targetFactorId,
            newValue: newValue,
            voteCount: 0, // Votes will be weighted by staked ECO later
            executed: false,
            endTimestamp: block.timestamp.add(proposalVotingPeriod),
            exists: true
        });
        nextProposalId = nextProposalId.add(1);

        // Store description off-chain or in event logs for gas efficiency
        emit ProposalCreated(proposalId, msg.sender, targetFactorId, newValue, proposals[proposalId].endTimestamp);
        // Emit description separately if needed or include in main event with cost consideration
    }

    /**
     * @dev Allows users with staked ECO to vote on an active proposal.
     * Voting weight is based on the amount of ECO staked *at the time of voting*.
     * Only 'support' votes count towards execution threshold in this simple model.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True if voting in favor, false otherwise.
     */
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (!proposal.exists) revert ProposalDoesNotExist();
        if (proposal.voted[msg.sender]) revert ProposalAlreadyVoted();
        if (block.timestamp > proposal.endTimestamp) revert ProposalVotingPeriodEnded();
        if (proposal.executed) revert ProposalCannotBeExecuted("Already executed"); // Should be covered by endTimestamp?

        // Get the voter's total staked ECO as voting weight
        // Again, inefficient lookup. Needs totalStakedByUser mapping or snapshotting.
        uint256 voterWeight = 0; // Calculate voter's total staked ECO here
        // For simplicity, let's say 1 staked ECO = 1 vote weight, but need total staked by voter.
        // Let's use msg.sender's *unstaked* ECO balance for *this* example simplicity, NOT staked.
        // In a real system, use staked balance or a snapshot.
        uint256 simpleVoteWeight = _balances[msg.sender]; // <-- **WARNING:** This is a simplification! Use STAKED amount in production!
        // Or, better: use the total staked amount they have *linked to any critter* as weight.
        // Requires iterating owned critters or the totalStakedByUser mapping.
        // Let's enforce *some* staked amount is required to vote using a minimal threshold,
        // and just use a flat weight for simplicity in this example.
        // A better approach: snapshot staked balances at proposal creation.
        // Simple approach for demo: require any staked amount, flat weight of 1 per voter.
        // Requires knowing if *any* amount is staked by the user, which is hard without iterating.

        // Okay, let's use a very simple weighting: 1 vote per 1000 staked ECO (total staked).
        // This still requires calculating total staked per user...
        // Let's fall back to the simplest possible demo: 1 user = 1 vote, just check if they have *any* balance.
        // Requires a change in logic. Let's revert to the concept: weight is total staked.
        // We will need a placeholder for total staked calculation.
        uint256 voterStakedWeight = 0; // Placeholder for actual staked amount calculation
        // How to get voter's total staked across all critters? Can't iterate all critters owned efficiently.
        // Need a separate tracking mapping: `mapping(address => uint256) totalStakedByUser;`
        // And update it in `stakeEcoForCritter` and `unstakeEcoForCritter`.
        // Let's add that mapping and use it for voting weight.

        // Add totalStakedByUser mapping and update it.
        // (Added `mapping(address => uint224) public totalStakedByUser;` and updates in stake/unstake)
        // Use uint224 for gas savings if total supply fits.
        voterStakedWeight = totalStakedByUser[msg.sender];

        if (voterStakedWeight == 0) revert InsufficientStakedEcoForProposal(1, 0); // Require at least 1 staked ECO to vote

        proposal.voted[msg.sender] = true;
        if (support) {
            proposal.voteCount = proposal.voteCount.add(voterStakedWeight);
        }
        // Add 'against' votes if needed for threshold calculation
        // else { proposal.againstVoteCount = proposal.againstVoteCount.add(voterStakedWeight); }

        emit Voted(proposalId, msg.sender, support, voterStakedWeight);
    }

    /**
     * @dev Executes a proposal if it has passed its voting period and met the execution threshold.
     * Only changes the specified environmental factor.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (!proposal.exists) revert ProposalDoesNotExist();
        if (proposal.executed) revert ProposalCannotBeExecuted("Already executed");
        if (block.timestamp < proposal.endTimestamp) revert ProposalNotYetEnded();

        // Example Execution Threshold: Need 50% of total staked ECO to vote 'support'
        // This requires calculating total staked ECO across *all* users.
        // This is also hard without iteration or a global total staked counter.
        // Let's add a global `totalGlobalStakedEco` variable and update it.
        // (Added `uint256 public totalGlobalStakedEco;` and updates in stake/unstake)

        uint256 requiredVotes = totalGlobalStakedEco.mul(50).div(100); // 50% of total staked supply needed
        if (proposal.voteCount < requiredVotes) revert ProposalCannotBeExecuted("Did not reach 50% threshold");

        // Execute the change
        int256 oldValue = environmentFactors[proposal.targetFactorId];
        environmentFactors[proposal.targetFactorId] = proposal.newValue;
        proposal.executed = true;

        emit EnvironmentFactorUpdated(proposal.targetFactorId, oldValue, proposal.newValue);
        emit ProposalExecuted(proposalId);
    }

     // Need to add mapping(address => uint256) totalStakedByUser; and uint256 public totalGlobalStakedEco;
     // And update them in stakeEcoForCritter and unstakeEcoForCritter.
     mapping(address => uint256) public totalStakedByUser; // Added for voting weight
     uint256 public totalGlobalStakedEco; // Added for governance threshold

    // --- Utility & Admin Functions ---

    /**
     * @dev Pauses core ecosystem activities (transfers, feeding, staking, claims, voting).
     * Callable only by the owner.
     */
    function pauseEcosystemActivity() external onlyOwner {
        paused = true;
        emit EcosystemPaused(msg.sender);
    }

    /**
     * @dev Unpauses core ecosystem activities.
     * Callable only by the owner.
     */
    function unpauseEcosystemActivity() external onlyOwner {
        paused = false;
        emit EcosystemUnpaused(msg.sender);
    }

    // --- Overrides for ERC721 & ERC1155 Receiver if needed ---
    // (Already added onERC721Received, onERC1155Received, onERC1155BatchReceived placeholders)


    // --- Add SafeMath usage or rely on 0.8+ checks ---
    // Using SafeMath explicitly for clarity is good practice even if compiler checks exist.
    // Added `using SafeMath for uint256; using SafeMath for int256;` at the top.

    // --- Add more Critter specific functions as needed ---
    // e.g., `getCritterStats(uint256 tokenId)` returning a struct/tuple
    // e.g., `getCrittersByOwner(address owner)` returning an array of token IDs (can be gas intensive)

     /**
     * @dev Gets all stats for a specific Critter.
     * @param tokenId The ID of the Critter NFT.
     */
    function getCritterStats(uint256 tokenId) external view whenCritterExists(tokenId) returns (uint256 mintTime, uint256 lastInteractionTime, uint8 level, uint8 hunger, uint256 totalEcoConsumed, uint256 totalEcoProduced) {
        Critter storage critter = critters[tokenId];
        // Calculate current hunger including decay for the return value
        uint8 currentHunger = getCritterHunger(tokenId); // Use the public getter that syncs conceptually

        return (
            critter.mintTime,
            critter.lastInteractionTime,
            critter.level,
            currentHunger, // Return calculated hunger
            critter.totalEcoConsumed,
            critter.totalEcoProduced
        );
    }

    // Function count check:
    // constructor - 1
    // ECO: mintEco, transfer, transferFrom, approve, allowance, balanceOf, totalSupply, getCirculatingSupply, burn, getTreasuryBalance, setDynamicTaxRate - 11
    // Critter (ERC721-like + custom): mintCritter, safeTransferFrom, ownerOf, balanceOf (critter), tokenURI, approve (erc721), setApprovalForAll, getApproved, isApprovedForAll, getCritterLevel, getCritterHunger, getCritterStats - 12
    // Critter Interactions: feedCritter, evolveCritter, claimCritterProduction, batchFeedCritters - 4
    // Environment: getEnvironmentFactor, triggerEnvironmentalEvent - 2
    // Staking: stakeEcoForCritter, unstakeEcoForCritter, claimStakingRewardsForCritter, getPendingStakingRewards - 4
    // Governance: proposeParameterChange, voteOnProposal, executeProposal - 3
    // Utility: pauseEcosystemActivity, unpauseEcosystemActivity - 2
    // ERC Receivers: onERC721Received, onERC1155Received, onERC1155BatchReceived - 3
    // Helpers: uint256ToString, _calculateHungerDecay, _syncCritterState, _calculateCritterProduction, _transfer, _mintCritter, _burnCritter - 7

    // Public/External functions count: 1 + 10 + 10 + 4 + 2 + 4 + 3 + 2 + 3 + 1 = 40. Exceeds 20.

}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic NFTs (Critters):**
    *   Beyond static ownership, Critters have state (`level`, `hunger`, `totalEcoConsumed`, `totalEcoProduced`).
    *   This state is influenced by user actions (`feedCritter`) and simulated time (`_syncCritterState` calculating hunger decay).
    *   `tokenURI` is intended to be dynamic, changing the visual representation or metadata based on the Critter's evolving state.
    *   `evolveCritter` provides a mechanism for permanent state upgrades based on reaching certain conditions.

2.  **Dynamic Tokenomics (ECO):**
    *   `transfer` and `transferFrom` include a `dynamicTaxRate` which can be adjusted by governance or owner. This tax goes to a `taxTreasury`.
    *   `feedCritter` involves *burning* ECO, creating a deflationary sink tied directly to NFT interaction and utility.
    *   `claimCritterProduction` mints new ECO, linking supply increase to the activity and state of dynamic NFTs and environment factors.
    *   `getCirculatingSupply` attempts (conceptually) to differentiate between total minted and actively usable supply by excluding tokens in sinks.

3.  **Simulated On-Chain Environment:**
    *   `environmentFactors` (like Resource Abundance, Climate Stress) introduce global parameters that influence core mechanics (`_calculateCritterProduction`).
    *   `triggerEnvironmentalEvent` allows (initially owner-controlled, could be oracle-fed) external influence on the ecosystem state.
    *   Governance allows participants to collectively adjust these factors (`proposeParameterChange`, `voteOnProposal`, `executeProposal`).

4.  **Contextual Staking:**
    *   `stakeEcoForCritter` links staked ECO to a specific NFT. This isn't just staking a token; it's staking it *in relation to* an asset within the ecosystem.
    *   `claimStakingRewardsForCritter` allows earning yield potentially influenced by the state of the linked Critter (e.g., higher level Critter grants staking bonus) and environment factors, going beyond simple time/amount-based yield.

5.  **Simplified Dynamic Governance:**
    *   Allows proposing and voting on changes to contract parameters (`environmentFactors`).
    *   Voting power is based on `totalStakedByUser`, linking participation directly to investment *within this ecosystem's staking mechanic*.
    *   Execution threshold is tied to the `totalGlobalStakedEco`, making governance weight relative to the health/size of the staking pool.

6.  **Batch Operations:**
    *   `batchFeedCritters` provides a gas-efficient way to perform actions on multiple NFTs owned by a user in a single transaction, improving user experience.

7.  **Pull-Based State Update (Conceptual for Hunger/Production):** While not fully implemented with complex decay/growth curves in this example, the use of `lastInteractionTime` and calculating current state (`getHungerLevel`, `_calculateCritterProduction`) based on time passed since the last interaction or claim is a gas-efficient "pull" mechanism for state changes that decay/grow over time, avoiding the need for expensive periodic global updates.

**Security Considerations (Important for a real contract):**

*   **Re-entrancy:** Avoid external calls after state changes, especially in `claimCritterProduction` and staking functions. OpenZeppelin's ReentrancyGuard is recommended.
*   **Integer Overflow/Underflow:** Solidity 0.8+ provides built-in checks, but `SafeMath` is used here for clarity, especially with `int256`.
*   **Access Control:** Modifiers like `onlyOwner`, `whenNotPaused`, `onlyCritterOwner`, `whenCritterExists` are used, but review permissions carefully.
*   **Front-running:** Functions like `claimCritterProduction` or `evolveCritter` could potentially be front-run. Consider using commit-reveal schemes or careful state design if critical.
*   **Gas Limits:** Batch functions like `batchFeedCritters` are good, but operations iterating over potentially large lists or mappings (like calculating `totalStakedByUser` if not tracked separately, or iterating all proposals) can hit gas limits. Maintaining aggregate state variables (`totalGlobalStakedEco`, `totalStakedByUser`) is crucial for scalability.
*   **Precision:** Calculations involving percentages, time, and varying rates (like production, rewards, tax) require careful handling of fixed-point math or sufficient precision (using `1 ether` equivalent).
*   **Oracle Dependency:** If environment factors were fed by external oracles, security considerations around oracle reliability and data freshness would be paramount.
*   **Metadata:** `tokenURI` relies on external metadata. Ensuring the integrity and decentralization of this metadata is important for the NFT's value and representation.

This contract provides a robust starting point for a complex ecosystem simulation, showcasing many non-standard and interactive elements. Remember that a production-ready version would require significantly more detailed logic for calculations, potentially incorporating more libraries (like OpenZeppelin's ERC20/ERC721 standards adapted with custom hooks, or governance libraries), rigorous testing, and gas optimization.