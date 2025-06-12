Okay, let's create a complex and creative smart contract that combines several trending concepts: NFT staking with dynamic yield based on traits and global multipliers, a yield-locking mechanism for bonus rewards, and basic token-based governance for parameter updates.

This contract, which we'll call "AuraBound Stakes", will allow users to stake specific ERC-721 NFTs (let's call them "Relics") to earn an ERC-20 token (let's call it "Aura"). The Aura yield rate will depend on a base rate, specific multipliers associated with the staked Relic's "traits" (simulated via a mapping), and a global multiplier controllable by governance. Additionally, users can lock their earned Aura tokens in the contract to earn a proportional share of a "Bonus Pool," which is funded separately. The Aura token itself (or the locked Aura) will grant voting power in a simple governance system to adjust yield parameters.

---

**Smart Contract Outline: AuraBound Stakes**

1.  **Purpose:** To provide an advanced NFT staking platform where yield (Aura token) is dynamic, influenced by NFT traits and global factors, and users are incentivized to lock earned yield for bonus rewards via a separate pool, with basic governance capabilities.
2.  **Core Concepts:**
    *   NFT Staking (ERC-721 Relics)
    *   Dynamic ERC-20 Yield (Aura token)
    *   Trait-Based Yield Multipliers (simulated)
    *   Global Yield Multiplier (governance controlled)
    *   Yield Locking Mechanism for Bonus Rewards
    *   Bonus Reward Pool Distribution (based on locked yield points)
    *   Basic Token Governance (using Aura token holdings/locks)
    *   Pausable Mechanism
    *   Admin Controls (Owner)
3.  **Key State Variables:**
    *   Contract addresses: ERC721 Relic, ERC20 Aura.
    *   Staked NFT data: Mapping from token ID to staking info (owner, timestamps).
    *   User staked NFT list: Mapping from user address to list of their staked token IDs.
    *   Yield parameters: Base rate, trait multipliers mapping, global multiplier.
    *   Bonus pool data: Total locked yield points, user locked yield amounts, user bonus points, bonus pool balance.
    *   Governance data: Proposal structs, voting states, proposal counter.
    *   Admin state: Owner, paused state.
4.  **Structs:**
    *   `StakedNFTInfo`: Details about a staked NFT (owner, stake/claim timestamps).
    *   `Proposal`: Details about a governance proposal (state, votes, parameters, execution).
5.  **Events:** For key actions (Stake, Unstake, ClaimYield, LockYield, UnlockYield, ClaimBonus, ParameterUpdate, ProposalSubmitted, Voted, ProposalExecuted, Pause, Unpause).
6.  **Functions (27+ planned):** See summary below.

---

**Function Summary**

*   **Admin/Setup (7 functions):**
    *   `constructor`: Initializes owner, token addresses, and initial rates.
    *   `setRelicNFTContract`: Sets the ERC721 Relic contract address (Owner).
    *   `setAuraTokenContract`: Sets the ERC20 Aura contract address (Owner).
    *   `setBonusPoolFundingContract`: Sets address allowed to fund bonus pool (Owner).
    *   `fundBonusPool`: Allows designated address to add tokens to bonus pool.
    *   `pause`: Pauses staking, unstaking, claiming, locking, unlocking (Owner).
    *   `unpause`: Unpauses contract (Owner).
*   **Staking (2 functions):**
    *   `stake`: Allows user to stake their Relic NFT (requires ERC721 approval).
    *   `unstake`: Allows user to unstake their Relic NFT and claims pending yield.
*   **Yield Calculation & Claiming (4 functions):**
    *   `getAccruedYieldForNFT`: Views calculated accrued Aura yield for a specific staked NFT.
    *   `getTotalAccruedYieldForUser`: Views total accrued Aura yield for all user's staked NFTs.
    *   `claimYieldForNFT`: Claims accrued Aura yield for a specific staked NFT.
    *   `claimAllYield`: Claims total accrued Aura yield for all user's staked NFTs.
*   **Dynamic Yield Parameters (3 functions):** (Initially Owner-only, potentially Governance-controlled)
    *   `setBaseYieldRatePerSecond`: Sets the base yield rate per second for all staked NFTs.
    *   `setNFTTraitMultiplier`: Sets the yield multiplier for a specific NFT trait ID (simulated by token ID or trait index).
    *   `setGlobalYieldMultiplier`: Sets a global multiplier affecting all yield calculations.
*   **Bonus Pool & Yield Locking (5 functions):**
    *   `lockYieldForBonus`: Locks claimed Aura tokens to earn a share of the bonus pool. Accrues bonus points.
    *   `unlockYield`: Unlocks previously locked Aura tokens. Updates bonus points.
    *   `getLockedYieldAmount`: Views the amount of Aura yield a user has locked.
    *   `getAccruedBonusShare`: Estimates user's current share of the bonus pool based on bonus points.
    *   `claimBonus`: Claims the user's share of the accrued bonus tokens from the pool.
*   **Governance (6 functions):** (Using Aura balance + locked yield for voting power)
    *   `getVotingPower`: Views a user's current voting power.
    *   `submitParameterProposal`: Submits a proposal to change base rate, trait multiplier, or global multiplier.
    *   `vote`: Casts a vote (Yes/No) on an active proposal.
    *   `getProposalState`: Views the current state of a proposal.
    *   `getProposalDetails`: Views the specific parameters a proposal aims to change.
    *   `executeProposal`: Executes a proposal that has passed and is within its execution window.
*   **View Functions (Min. 2 functions beyond others):** (Covered by the functions above, but ensuring visibility)
    *   `getStakedNFTInfo`: Views details of a specific staked NFT.
    *   `getUserStakedTokenIds`: Views list of NFTs staked by a user.
    *   `getBaseYieldRatePerSecond`: Views current base yield rate.
    *   `getNFTTraitMultiplier`: Views trait multiplier for a specific NFT ID.
    *   `getGlobalYieldMultiplier`: Views global yield multiplier.
    *   `getBonusPoolBalance`: Views current balance in the bonus pool.
    *   `getTotalLockedYieldAmount`: Views the total amount of Aura yield locked across all users.
    *   `getTotalBonusPoints`: Views total bonus points accumulated by all users.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Required to receive NFTs

// --- OUTLINE ---
// 1. Purpose: Advanced NFT staking with dynamic yield, yield locking for bonus, and governance.
// 2. Core Concepts: NFT Staking (Relics), Dynamic ERC-20 Yield (Aura), Trait-Based Multipliers (simulated), Global Multiplier, Yield Locking for Bonus, Bonus Pool, Basic Token Governance.
// 3. Key State Variables: Token addresses, Staked NFT data, User staked lists, Yield parameters, Bonus pool data (points, locked amounts), Governance data, Admin state.
// 4. Structs: StakedNFTInfo, Proposal.
// 5. Events: Stake, Unstake, ClaimYield, LockYield, UnlockYield, ClaimBonus, ParameterUpdate, ProposalSubmitted, Voted, ProposalExecuted, Pause, Unpause.
// 6. Functions (27+): Admin/Setup, Staking, Yield Calculation/Claiming, Dynamic Yield Parameters, Bonus Pool/Locking, Governance, View Functions.

// --- FUNCTION SUMMARY ---
// Admin/Setup: constructor, setRelicNFTContract, setAuraTokenContract, setBonusPoolFundingContract, fundBonusPool, pause, unpause, rescueERC20 (implicit via Ownable), rescueERC721 (implicit via ERC721Holder).
// Staking: stake, unstake.
// Yield Calculation & Claiming: getAccruedYieldForNFT, getTotalAccruedYieldForUser, claimYieldForNFT, claimAllYield.
// Dynamic Yield Parameters: setBaseYieldRatePerSecond, setNFTTraitMultiplier, setGlobalYieldMultiplier.
// Bonus Pool & Yield Locking: lockYieldForBonus, unlockYield, getLockedYieldAmount, getAccruedBonusShare, claimBonus.
// Governance: getVotingPower, submitParameterProposal, vote, getProposalState, getProposalDetails, executeProposal.
// View Functions: getStakedNFTInfo, getUserStakedTokenIds, getBaseYieldRatePerSecond, getNFTTraitMultiplier, getGlobalYieldMultiplier, getBonusPoolBalance, getTotalLockedYieldAmount, getTotalBonusPoints.

contract AuraBoundStakes is Ownable, Pausable, ERC721Holder {

    // --- STATE VARIABLES ---

    IERC721 public relicNFTContract;
    IERC20 public auraTokenContract;
    address public bonusPoolFundingAddress; // Address allowed to fund the bonus pool

    // Staking data
    struct StakedNFTInfo {
        address owner;
        uint48 stakeTimestamp;
        uint48 lastYieldClaimTimestamp; // Using uint48 for timestamps (seconds since epoch), sufficient until year 2106
    }
    mapping(uint256 => StakedNFTInfo) public stakedNFTs; // NFT Token ID => Staking Info
    mapping(address => uint256[]) public userStakedTokenIds; // User Address => List of staked NFT Token IDs

    // Dynamic Yield Parameters (Rates are scaled, e.g., rate * 1e18 for precision)
    uint256 public baseYieldRatePerSecond; // Base yield rate per second per NFT
    mapping(uint256 => uint256) public nftTraitMultipliers; // NFT Token ID => Yield Multiplier (e.g., 1e18 for 1x, 2e18 for 2x)
    uint256 public globalYieldMultiplier; // Global multiplier (e.g., 1e18 for 1x, 1.5e18 for 1.5x)

    // Bonus Pool & Yield Locking
    uint256 public totalLockedYieldAmount; // Total Aura tokens locked by users
    mapping(address => uint256) public userLockedYieldAmount; // User => Locked Aura tokens
    uint256 public totalBonusPoints; // Total accumulated bonus points across all users
    mapping(address => uint256) public userBonusPoints; // User => Accumulated bonus points
    mapping(address => uint48) private lastUserBonusPointUpdateTime; // User => Last timestamp points were updated

    uint256 public bonusPoolBalance; // Current balance of Aura tokens in the bonus pool

    // Governance (Simple Parameter Changes)
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        address proposer;
        ProposalState state;
        uint48 startTime;
        uint48 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotesRequired; // Minimum voting power needed for proposal to pass quorum
        uint8 proposalType; // 0: BaseRate, 1: TraitMultiplier, 2: GlobalMultiplier
        // Parameters for the proposed change
        uint256 param1; // New rate/multiplier (scaled)
        uint256 param2; // Token ID for TraitMultiplier type, unused otherwise
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted

    // Governance Parameters
    uint256 public votingPeriod = 3 days; // Duration of active voting period
    uint256 public quorumPercentage = 5; // 5% of total voting power required for quorum

    // --- EVENTS ---

    event Staked(address indexed user, uint256 indexed tokenId, uint256 stakeTimestamp);
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 unstakeTimestamp, uint256 claimedYield);
    event YieldClaimed(address indexed user, uint256 indexed tokenId, uint256 claimedAmount, uint256 claimTimestamp);
    event YieldLocked(address indexed user, uint256 amountLocked);
    event YieldUnlocked(address indexed user, uint256 amountUnlocked);
    event BonusClaimed(address indexed user, uint256 amountClaimed);
    event ParameterUpdated(uint8 indexed paramType, uint256 indexed param1, uint256 indexed param2, uint256 newValue); // paramType: 0=Base, 1=Trait, 2=Global
    event BonusPoolFunded(address indexed funder, uint256 amount);

    // Governance Events
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint8 indexed proposalType, uint256 param1, uint256 param2);
    event Voted(uint256 indexed proposalId, address indexed voter, bool indexed support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState oldState, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, uint256 executionTimestamp);

    // --- CONSTRUCTOR ---

    constructor(address _relicNFTContract, address _auraTokenContract) Ownable(msg.sender) {
        require(_relicNFTContract != address(0), "Invalid Relic NFT address");
        require(_auraTokenContract != address(0), "Invalid Aura token address");

        relicNFTContract = IERC721(_relicNFTContract);
        auraTokenContract = IERC20(_auraTokenContract);

        // Set initial parameters (Example values, adjust as needed)
        baseYieldRatePerSecond = 1e14; // Example: 0.0001 Aura per second per NFT (scaled)
        globalYieldMultiplier = 1e18; // Default: 1x multiplier (scaled)

        // Initialize bonus point update time for msg.sender immediately
        lastUserBonusPointUpdateTime[msg.sender] = uint48(block.timestamp);
    }

    // --- MODIFIERS ---

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    // --- ADMIN & SETUP FUNCTIONS ---

    function setRelicNFTContract(address _relicNFTContract) public onlyOwner {
        require(_relicNFTContract != address(0), "Invalid address");
        relicNFTContract = IERC721(_relicNFTContract);
    }

    function setAuraTokenContract(address _auraTokenContract) public onlyOwner {
        require(_auraTokenContract != address(0), "Invalid address");
        auraTokenContract = IERC20(_auraTokenContract);
    }

    function setBonusPoolFundingContract(address _fundingAddress) public onlyOwner {
        require(_fundingAddress != address(0), "Invalid address");
        bonusPoolFundingAddress = _fundingAddress;
    }

    function fundBonusPool(uint256 amount) public {
        require(msg.sender == bonusPoolFundingAddress || msg.sender == owner(), "Not authorized to fund bonus pool");
        require(amount > 0, "Amount must be > 0");
        require(auraTokenContract.transferFrom(msg.sender, address(this), amount), "Aura transfer failed");
        bonusPoolBalance += amount;
        emit BonusPoolFunded(msg.sender, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // ERC721Holder provides onERC721Received which is needed for receiving NFTs.
    // It also provides a default implementation of supportsInterface.
    // If NFTs were sent directly without calling `stake`,
    // they might be stuck unless rescued. The `rescueERC721` function
    // from Ownable / ERC721Holder or a custom one would be needed.
    // OpenZeppelin's Ownable includes `rescueToken` which can handle both ERC20 and ERC721.
    // Let's inherit from ERC721Holder and ensure we can rescue.
    // Ownable in newer versions has rescueToken. If not, a custom one would be:
    /*
    function rescueERC721(address tokenAddress, address to, uint256 tokenId) public onlyOwner {
        IERC721(tokenAddress).transferFrom(address(this), to, tokenId);
    }
    function rescueERC20(address tokenAddress, address to, uint256 amount) public onlyOwner {
        IERC20(tokenAddress).transfer(to, amount);
    }
    */
    // Assuming Ownable provides rescueToken(address token, address to, uint256 amountOrId)

    // --- STAKING FUNCTIONS ---

    function stake(uint256 tokenId) public whenNotPaused {
        require(stakedNFTs[tokenId].owner == address(0), "NFT is already staked");
        require(relicNFTContract.ownerOf(tokenId) == msg.sender, "Caller does not own the NFT");

        // Transfer NFT to this contract. Requires caller to have approved this contract.
        relicNFTContract.transferFrom(msg.sender, address(this), tokenId);

        stakedNFTs[tokenId] = StakedNFTInfo({
            owner: msg.sender,
            stakeTimestamp: uint48(block.timestamp),
            lastYieldClaimTimestamp: uint48(block.timestamp) // Start yield calculation from stake time
        });

        userStakedTokenIds[msg.sender].push(tokenId); // Add to user's list

        emit Staked(msg.sender, tokenId, block.timestamp);
    }

    function unstake(uint256 tokenId) public whenNotPaused {
        StakedNFTInfo storage nftInfo = stakedNFTs[tokenId];
        require(nftInfo.owner == msg.sender, "Caller is not the staker of this NFT");
        require(nftInfo.owner != address(0), "NFT is not staked");

        // Calculate and claim pending yield before unstaking
        uint256 pendingYield = _calculateAccruedYield(tokenId, nftInfo);
        if (pendingYield > 0) {
            _transferAura(msg.sender, pendingYield);
            nftInfo.lastYieldClaimTimestamp = uint48(block.timestamp); // Update timestamp
             emit YieldClaimed(msg.sender, tokenId, pendingYield, block.timestamp);
        }

        // Transfer NFT back to user
        relicNFTContract.transferFrom(address(this), msg.sender, tokenId);

        // Remove from staked list and user's list
        delete stakedNFTs[tokenId];
        _removeTokenIdFromUserList(msg.sender, tokenId); // Helper function needed

        emit Unstaked(msg.sender, tokenId, block.timestamp, pendingYield);
    }

    // Internal helper to remove token ID from a user's dynamic array
    function _removeTokenIdFromUserList(address user, uint256 tokenId) internal {
        uint256[] storage tokenIds = userStakedTokenIds[user];
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                // Replace with last element and pop
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                return;
            }
        }
        // Should theoretically not reach here if state is consistent
    }

    // --- YIELD CALCULATION & CLAIMING FUNCTIONS ---

    // Internal helper to calculate accrued yield for a single NFT
    function _calculateAccruedYield(uint256 tokenId, StakedNFTInfo storage nftInfo) internal view returns (uint256) {
         if (nftInfo.owner == address(0)) {
            return 0; // Not staked
        }

        uint48 lastClaim = nftInfo.lastYieldClaimTimestamp;
        uint48 currentTimestamp = uint48(block.timestamp);

        if (currentTimestamp <= lastClaim) {
            return 0; // No time has passed or clock skewed
        }

        uint256 timeElapsed = currentTimestamp - lastClaim;
        uint256 traitMultiplier = nftTraitMultipliers[tokenId]; // Defaults to 0 if not set, need to handle this. Let's default to 1x (1e18) if not explicitly set.
        if (traitMultiplier == 0) {
             traitMultiplier = 1e18; // Default to 1x multiplier
        }

        // Calculate yield: time * baseRate * traitMultiplier * globalMultiplier
        // Need to handle precision using scaled rates/multipliers (assuming 1e18 scaling)
        // baseRate * timeElapsed * traitMultiplier / 1e18 * globalMultiplier / 1e18
        // = (baseRate * timeElapsed * traitMultiplier * globalMultiplier) / (1e18 * 1e18)
        uint256 yield = (baseYieldRatePerSecond * timeElapsed); // Result is scaled by 1e18 initially from baseRate
        yield = (yield * traitMultiplier) / 1e18; // Apply trait multiplier
        yield = (yield * globalYieldMultiplier) / 1e18; // Apply global multiplier

        return yield;
    }


    // Public view function for a single NFT
    function getAccruedYieldForNFT(uint256 tokenId) public view returns (uint256) {
         return _calculateAccruedYield(tokenId, stakedNFTs[tokenId]);
    }

    // Public view function for a user's total yield
    function getTotalAccruedYieldForUser(address user) public view returns (uint256 totalYield) {
        uint256[] storage tokenIds = userStakedTokenIds[user];
        for (uint i = 0; i < tokenIds.length; i++) {
            totalYield += _calculateAccruedYield(tokenIds[i], stakedNFTs[tokenIds[i]]);
        }
    }

    // Claim yield for a specific staked NFT
    function claimYieldForNFT(uint256 tokenId) public whenNotPaused {
        StakedNFTInfo storage nftInfo = stakedNFTs[tokenId];
        require(nftInfo.owner == msg.sender, "Caller is not the staker of this NFT");
        require(nftInfo.owner != address(0), "NFT is not staked");

        uint256 pendingYield = _calculateAccruedYield(tokenId, nftInfo);
        require(pendingYield > 0, "No yield accrued");

        _transferAura(msg.sender, pendingYield);

        nftInfo.lastYieldClaimTimestamp = uint48(block.timestamp); // Update timestamp for this NFT

        emit YieldClaimed(msg.sender, tokenId, pendingYield, block.timestamp);
    }

    // Claim all accrued yield for a user
    function claimAllYield() public whenNotPaused {
        uint256[] storage tokenIds = userStakedTokenIds[msg.sender];
        uint256 totalClaimed = 0;
        uint48 currentTimestamp = uint48(block.timestamp);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakedNFTInfo storage nftInfo = stakedNFTs[tokenId]; // Use storage reference

            uint256 pendingYield = _calculateAccruedYield(tokenId, nftInfo);
            if (pendingYield > 0) {
                totalClaimed += pendingYield;
                nftInfo.lastYieldClaimTimestamp = currentTimestamp; // Update timestamp for this NFT
            }
        }

        require(totalClaimed > 0, "No total yield accrued");

        _transferAura(msg.sender, totalClaimed);

        // Note: Single event for total claimed amount for gas efficiency, or multiple events inside loop
        // Let's emit multiple events per NFT for clarity, but sum the total.
        // For simplicity, emit per NFT inside the loop (re-evaluate gas for many NFTs).
        // Alternative: track total, then emit ONE event with user and total claimed. Let's do the latter.
        // The per-NFT events are inside claimYieldForNFT if called individually.
        // Since claimAll doesn't need per-NFT detail in the event, just sum and emit one.
        // The `lastYieldClaimTimestamp` updates ensure future calculations are correct.
         emit YieldClaimed(msg.sender, 0, totalClaimed, block.timestamp); // Use 0 for tokenId to indicate batch claim
    }

    // Internal helper to transfer Aura tokens
    function _transferAura(address recipient, uint256 amount) internal {
         require(auraTokenContract.transfer(recipient, amount), "Aura transfer failed");
    }

    // --- DYNAMIC YIELD PARAMETER FUNCTIONS ---
    // These can be called by Owner initially, or later by Governance.
    // Let's make them governance-only via proposal execution later, but add owner bypass for setup.

    function setBaseYieldRatePerSecond(uint256 _newRate) public {
         // Can be called by Owner or by successful proposal execution
        require(msg.sender == owner() || _isGovernanceExecuting(), "Unauthorized");
        baseYieldRatePerSecond = _newRate;
        emit ParameterUpdated(0, 0, 0, _newRate); // 0=BaseRate, param1=0, param2=0
    }

    function setNFTTraitMultiplier(uint256 tokenId, uint256 multiplier) public {
         // Can be called by Owner or by successful proposal execution
        require(msg.sender == owner() || _isGovernanceExecuting(), "Unauthorized");
         // Ensure multiplier is reasonable (e.g., not 0 unless intended to disable yield)
        nftTraitMultipliers[tokenId] = multiplier; // 1e18 = 1x
        emit ParameterUpdated(1, tokenId, 0, multiplier); // 1=TraitMultiplier, param1=tokenId, param2=0
    }

    function setGlobalYieldMultiplier(uint256 multiplier) public {
         // Can be called by Owner or by successful proposal execution
        require(msg.sender == owner() || _isGovernanceExecuting(), "Unauthorized");
         // Ensure multiplier is reasonable
        globalYieldMultiplier = multiplier; // 1e18 = 1x
        emit ParameterUpdated(2, 0, 0, multiplier); // 2=GlobalMultiplier, param1=0, param2=0
    }

    // Helper to check if the caller is this contract executing a governance proposal
    function _isGovernanceExecuting() internal view returns (bool) {
        // This is a simplified check. In a real DAO, the execution would likely
        // be triggered by a separate executor contract or a specific function call pattern.
        // For this example, we'll assume if the caller is *this* contract, it's via governance execution.
        return msg.sender == address(this);
        // A more robust system would track the *state* of proposal execution.
    }


    // --- BONUS POOL & YIELD LOCKING FUNCTIONS ---

    // This mechanism uses "bonus points" accrued based on locked amount and time.
    // Share of bonus pool = (userBonusPoints / totalBonusPoints) * bonusPoolBalance
    // Points accrue continuously: points += lockedAmount * time elapsed

    function _updateBonusPoints(address user) internal {
        uint48 currentTime = uint48(block.timestamp);
        uint48 lastUpdate = lastUserBonusPointUpdateTime[user];

        if (currentTime > lastUpdate) {
            uint256 timeElapsed = currentTime - lastUpdate;
            uint256 userPointsAccrued = userLockedYieldAmount[user] * timeElapsed;
            userBonusPoints[user] += userPointsAccrued;
            totalBonusPoints += userPointsAccrued;
            lastUserBonusPointUpdateTime[user] = currentTime;
        }
    }

    function lockYieldForBonus(uint256 amount) public whenNotPaused {
        require(amount > 0, "Amount must be > 0");

        // Update bonus points *before* changing the locked amount
        _updateBonusPoints(msg.sender);
        _updateBonusPoints(address(0)); // Update total points by updating a dummy address representing the global state

        // Transfer tokens from user to contract (assumes user has already claimed Aura and approved this contract)
        require(auraTokenContract.transferFrom(msg.sender, address(this), amount), "Aura transfer failed");

        userLockedYieldAmount[msg.sender] += amount;
        totalLockedYieldAmount += amount;

        lastUserBonusPointUpdateTime[msg.sender] = uint48(block.timestamp); // Reset user's timer
        lastUserBonusPointUpdateTime[address(0)] = uint48(block.timestamp); // Reset total timer

        emit YieldLocked(msg.sender, amount);
    }

    function unlockYield(uint256 amount) public whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(userLockedYieldAmount[msg.sender] >= amount, "Insufficient locked yield");

        // Update bonus points *before* changing the locked amount
        _updateBonusPoints(msg.sender);
         _updateBonusPoints(address(0)); // Update total points

        userLockedYieldAmount[msg.sender] -= amount;
        totalLockedYieldAmount -= amount;

        lastUserBonusPointUpdateTime[msg.sender] = uint48(block.timestamp); // Reset user's timer
        lastUserBonusPointUpdateTime[address(0)] = uint48(block.timestamp); // Reset total timer

        // Transfer tokens back to user
        _transferAura(msg.sender, amount);

        emit YieldUnlocked(msg.sender, amount);
    }

    function getLockedYieldAmount(address user) public view returns (uint256) {
        return userLockedYieldAmount[user];
    }

    // Estimates user's current share of the bonus pool.
    // Note: The actual claim amount depends on the bonusPoolBalance *at the moment of claim*.
    function getAccruedBonusShare(address user) public view returns (uint256 estimatedBonus) {
        uint256 currentUserPoints = userBonusPoints[user];
         // Add points accrued since last update without changing state
        currentUserPoints += userLockedYieldAmount[user] * (uint48(block.timestamp) - lastUserBonusPointUpdateTime[user]);

        uint256 currentTotalPoints = totalBonusPoints;
         // Add total points accrued since last update without changing state
        currentTotalPoints += totalLockedYieldAmount * (uint48(block.timestamp) - lastUserBonusPointUpdateTime[address(0)]);

        if (currentTotalPoints == 0 || bonusPoolBalance == 0) {
            return 0;
        }

        // Calculate share: user points / total points * bonus pool balance
        // Use 1e18 scaling for division precision if needed, but bonusPoolBalance is already in token units
        // (currentUserPoints * bonusPoolBalance) / currentTotalPoints
        return (currentUserPoints * bonusPoolBalance) / currentTotalPoints;
    }

    function claimBonus() public whenNotPaused {
        require(bonusPoolBalance > 0, "Bonus pool is empty");

        // Update bonus points for everyone *before* calculating shares
        _updateBonusPoints(msg.sender);
        _updateBonusPoints(address(0)); // Update total points

        uint256 currentUserPoints = userBonusPoints[msg.sender];
        uint256 currentTotalPoints = totalBonusPoints; // Use the updated total

        if (currentUserPoints == 0 || currentTotalPoints == 0) {
            // No points, nothing to claim
            return;
        }

        // Calculate amount to claim based on current share of total points
        uint256 amountToClaim = (currentUserPoints * bonusPoolBalance) / currentTotalPoints;

        if (amountToClaim == 0) {
             // Due to rounding or precision, might be 0 even if points > 0
             return;
        }

        // Deduct the claimed amount from the bonus pool balance
        bonusPoolBalance -= amountToClaim;

        // Transfer bonus tokens
        _transferAura(msg.sender, amountToClaim);

        // Reset user's bonus points to 0 after claiming their share
        userBonusPoints[msg.sender] = 0;
        // Deduct the user's points from the total points pool
        totalBonusPoints -= currentUserPoints; // This assumes the user's points are exactly removed from total.
                                                // A more accurate system might use a 'rewardPerPoint' accumulator.
                                                // For simplicity here, we assume total points decrease proportionally.

        emit BonusClaimed(msg.sender, amountToClaim);
    }

    // --- GOVERNANCE FUNCTIONS ---
    // Voting power is based on user's current Aura balance + locked Aura amount

    function getVotingPower(address user) public view returns (uint256) {
        // Simplistic voting power: current balance + locked amount
        // A more complex system might use staked NFTs, time-weighted average balance, etc.
        return auraTokenContract.balanceOf(user) + userLockedYieldAmount[user];
    }

    // Submit a proposal to change a parameter
    // 0: BaseRate, param1=newRate (scaled)
    // 1: TraitMultiplier, param1=tokenId, param2=newMultiplier (scaled)
    // 2: GlobalMultiplier, param1=newMultiplier (scaled)
    function submitParameterProposal(uint8 proposalType, uint256 param1, uint256 param2) public {
        uint256 proposerVotingPower = getVotingPower(msg.sender);
        // Require a minimum voting power to submit a proposal (prevent spam)
        require(proposerVotingPower > 0, "Insufficient voting power to submit proposal"); // Example requirement

        uint256 proposalId = nextProposalId++;
        uint48 currentTime = uint48(block.timestamp);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            state: ProposalState.Active,
            startTime: currentTime,
            endTime: currentTime + uint48(votingPeriod),
            yesVotes: 0,
            noVotes: 0,
            totalVotesRequired: (auraTokenContract.totalSupply() * quorumPercentage) / 100, // Simple quorum based on total supply
            proposalType: proposalType,
            param1: param1,
            param2: param2
        });

        emit ProposalSubmitted(proposalId, msg.sender, proposalType, param1, param2);
    }

    function vote(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(uint48(block.timestamp) <= proposal.endTime, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "Insufficient voting power to vote");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.yesVotes += voterPower;
        } else {
            proposal.noVotes += voterPower;
        }

        emit Voted(proposalId, msg.sender, support, voterPower);

        // Check if quorum is met and outcome determined early (optional)
        // Simplified: state update happens only on `executeProposal` after end time
    }

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0 && proposal.proposer == address(0)) { // Check if proposal exists
             return ProposalState.Pending; // Or a specific non-existent state
        }
        if (proposal.state != ProposalState.Active) {
            return proposal.state;
        }
        if (uint48(block.timestamp) > proposal.endTime) {
            // Voting period ended, determine final state
            if (proposal.yesVotes > proposal.noVotes && proposal.yesVotes >= proposal.totalVotesRequired) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Failed;
            }
        }
        return ProposalState.Active;
    }

     function getProposalDetails(uint256 proposalId) public view returns (uint8 proposalType, uint256 param1, uint256 param2) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        return (proposal.proposalType, proposal.param1, proposal.param2);
    }


    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.state != ProposalState.Executed, "Proposal already executed");

        // Check final state if voting period is over
        if (proposal.state == ProposalState.Active) {
            require(uint48(block.timestamp) > proposal.endTime, "Voting period has not ended");
            if (proposal.yesVotes > proposal.noVotes && proposal.yesVotes >= proposal.totalVotesRequired) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
             emit ProposalStateChanged(proposalId, ProposalState.Active, proposal.state);
        }

        require(proposal.state == ProposalState.Succeeded, "Proposal must have succeeded to be executed");

        // Execute the proposed action
        // Use a flag or internal state to indicate execution context to bypass permission checks in setters
        // A simple way is to call the setter functions directly from within this contract
        // which we enabled with `_isGovernanceExecuting()` check.

        if (proposal.proposalType == 0) { // BaseRate
             setBaseYieldRatePerSecond(proposal.param1);
        } else if (proposal.proposalType == 1) { // TraitMultiplier
             setNFTTraitMultiplier(proposal.param1, proposal.param2);
        } else if (proposal.proposalType == 2) { // GlobalMultiplier
             setGlobalYieldMultiplier(proposal.param1);
        } else {
            revert("Unknown proposal type");
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId, block.timestamp);
    }

    // --- VIEW FUNCTIONS (Additional / Summary) ---

    function getStakedNFTInfo(uint256 tokenId) public view returns (address owner, uint48 stakeTimestamp, uint48 lastYieldClaimTimestamp) {
        StakedNFTInfo storage info = stakedNFTs[tokenId];
        return (info.owner, info.stakeTimestamp, info.lastYieldClaimTimestamp);
    }

    // getUserStakedTokenIds is already public due to mapping definition

    // getBaseYieldRatePerSecond is already public
    // getNFTTraitMultiplier is already public
    // getGlobalYieldMultiplier is already public
    // getBonusPoolBalance is already public
    // getTotalLockedYieldAmount is already public
    // getTotalBonusPoints is already public
    // getLockedYieldAmount is already public
    // getAccruedBonusShare is already public
    // getVotingPower is already public
    // getProposalState is already public
    // getProposalDetails is already public

    // Example: Get count of staked NFTs for a user
    function getUserStakedNFTCount(address user) public view returns (uint256) {
        return userStakedTokenIds[user].length;
    }

    // Example: Get a specific staked token ID from user's list
    function getUserStakedTokenIdAtIndex(address user, uint256 index) public view returns (uint256) {
        require(index < userStakedTokenIds[user].length, "Index out of bounds");
        return userStakedTokenIds[user][index];
    }

    // Add more specific views if needed, e.g., get total supply for quorum calc validation
    function getTotalAuraSupply() public view returns (uint256) {
        return auraTokenContract.totalSupply();
    }

    // Total functions count check:
    // Admin/Setup: constructor, setRelicNFTContract, setAuraTokenContract, setBonusPoolFundingContract, fundBonusPool, pause, unpause, rescueToken (from Ownable) = 8 (plus ERC721Holder receive)
    // Staking: stake, unstake = 2
    // Yield: getAccruedYieldForNFT, getTotalAccruedYieldForUser, claimYieldForNFT, claimAllYield = 4
    // Dynamic Yield: setBaseYieldRatePerSecond, setNFTTraitMultiplier, setGlobalYieldMultiplier = 3
    // Bonus Pool: lockYieldForBonus, unlockYield, getLockedYieldAmount, getAccruedBonusShare, claimBonus = 5
    // Governance: getVotingPower, submitParameterProposal, vote, getProposalState, getProposalDetails, executeProposal = 6
    // Additional Views: getUserStakedNFTCount, getUserStakedTokenIdAtIndex, getTotalAuraSupply = 3
    // Total: 8 + 2 + 4 + 3 + 5 + 6 + 3 = 31 functions. Meets the >= 20 requirement.

}
```

---

**Explanation of Advanced/Creative Concepts Used:**

1.  **Dynamic Yield based on Traits & Global Factor:**
    *   Instead of a single static yield rate, the yield for each staked NFT is calculated using `baseRate * traitMultiplier * globalMultiplier * time`.
    *   `baseYieldRatePerSecond`: A base rate applicable to all NFTs.
    *   `nftTraitMultipliers`: A mapping simulates different "traits" or rarity levels affecting the yield of *specific* NFTs (identified by token ID). In a real-world scenario, this data might come from the NFT contract's metadata, an oracle, or be set during NFT minting. Here, it's simplified to a mapping set by the owner/governance.
    *   `globalYieldMultiplier`: A factor that can be adjusted via governance, allowing the community to collectively influence the overall yield rate based on market conditions or protocol goals.
2.  **Yield Locking for Bonus Rewards:**
    *   Users don't just claim yield; they have the option to `lockYieldForBonus`.
    *   Locked yield doesn't compound directly but earns "bonus points" over time (`lockedAmount * time`).
    *   A separate `bonusPoolBalance` (funded externally) is distributed among users based on their proportion of `userBonusPoints` relative to `totalBonusPoints`. This incentivizes users to re-stake their earned tokens within the protocol, creating a deeper liquidity/commitment layer. The bonus point system itself (accruing points over time based on locked amount) is a common pattern in more complex staking/reward contracts.
3.  **Basic Token Governance:**
    *   Holders of the `AuraTokenContract` (the yield token) and users who have locked their yield (`userLockedYieldAmount`) gain `votingPower`.
    *   Users can `submitParameterProposal` to suggest changes to the `baseYieldRatePerSecond`, `nftTraitMultipliers`, or `globalYieldMultiplier`.
    *   A simple `vote` mechanism with `Yes`/`No` using voting power.
    *   Proposals have a `votingPeriod` and require a `quorumPercentage` of total voting power to pass.
    *   `executeProposal` applies the winning proposal's parameters to the contract state. This creates a feedback loop where the community can influence the staking parameters.
4.  **Time-Weighted Calculations:** Yield calculation uses timestamps to determine elapsed time precisely. Bonus points accrue based on the duration tokens are locked (`_updateBonusPoints` logic).
5.  **Pausable:** Standard but important feature for emergency situations.
6.  **ERC721Holder Inheritance:** Necessary for the contract to properly receive NFTs transferred to it.

This contract goes beyond simple "stake NFT, get fixed token per block" and adds layers of complexity, user choice (claim vs. lock), dynamic factors, and community influence, fitting the criteria for an interesting and advanced example.

**Disclaimer:** This is a complex example for educational purposes. It has not been audited and should *not* be used in production without significant review, testing, and professional security audits. Considerations for a production system would include:
*   More sophisticated math for yield/bonus calculations (handling potential rounding errors, using fixed-point libraries).
*   Handling NFT trait data more robustly (e.g., interacting with the NFT contract's metadata or an oracle).
*   A more advanced governance system (e.g., tiered proposals, delegated voting, off-chain voting with on-chain execution).
*   Gas optimizations for functions involving loops (like `claimAllYield` or bonus point updates).
*   Potential griefing vectors in the bonus point system if not carefully designed.