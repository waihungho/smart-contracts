Okay, let's create a smart contract concept that combines several interesting and relatively advanced ideas:

1.  **Dynamic NFTs:** NFTs whose properties (metadata) can change over time or based on actions/conditions.
2.  **Staked Governance/Utility Token:** An ERC-20 like token used for staking to gain benefits *on* the NFTs and for governance.
3.  **On-chain State Evolution:** The NFT properties evolve based on time, staked tokens, and global parameters set by governance.
4.  **Integrated Governance:** A simple token-weighted voting mechanism built into the contract to control key parameters and actions.

We will build this as a single contract managing both the ERC-721 NFTs and an ERC-20-like utility token internally for simplicity and integration, rather than two separate contracts. This contract will be called `ChronoForge`.

**Outline:**

1.  **License and Pragma**
2.  **Imports:** OpenZeppelin libraries for standard functionalities (ERC721, Context, Ownable, ReentrancyGuard). We'll handle the ERC20-like logic manually internally.
3.  **Errors:** Custom errors for clarity and gas efficiency.
4.  **Structs:**
    *   `ChronoNFTData`: Stores dynamic properties of each NFT and staking info.
    *   `Proposal`: Stores governance proposal details.
5.  **Enums:** `ProposalState` for governance lifecycle.
6.  **State Variables:**
    *   NFT data mapping.
    *   TIME token balances mapping (internal ERC20-like).
    *   Staked TIME per NFT mapping.
    *   Total staked TIME per user mapping.
    *   NFT properties parameters (evolution rate, staking multiplier).
    *   Governance state (proposals mapping, proposal counter, voting parameters).
    *   Counters, total supplies.
7.  **Events:** To log key actions (Mint, Burn, Stake, Unstake, StateUpdate, ProposalCreated, Voted, ProposalExecuted).
8.  **Modifiers:** For access control (`onlyOwner`, `onlyGovernor`, `onlyGovExecution`). `onlyGovernor` will be the contract itself via governance execution.
9.  **Constructor:** Initialize base contract, set initial owner and parameters.
10. **NFT (ERC-721 based) Functions:**
    *   Minting, Burning.
    *   Standard ERC721 views (ownerOf, balanceOf, getApproved, isApprovedForAll).
    *   Standard ERC721 transfers (transferFrom, safeTransferFrom) - *Modified to potentially trigger state updates.*
11. **TIME (ERC-20-like internal) Functions:**
    *   Balance views.
    *   Transfer functions (internal, only via staking/unstaking initially, potentially governance mint/burn).
    *   Total supply view.
12. **Chrono-NFT State & Evolution Functions:**
    *   `getNFTData`: View function to retrieve current dynamic properties.
    *   `calculateEvolutionPoints`: View function to preview potential evolution based on current state/time.
    *   `updateNFTState`: Core function to trigger property evolution based on time and staking.
    *   `applyEvolution`: Internal function applying calculated evolution points.
13. **Staking Functions:**
    *   `stakeTimeTokensToNFT`: Stake TIME tokens to a specific NFT.
    *   `unstakeTimeTokensFromNFT`: Unstake TIME tokens from an NFT.
    *   `getStakedTimeTokensForNFT`: View staked amount for an NFT.
14. **Governance Functions:**
    *   `submitProposal`: Create a new governance proposal.
    *   `voteOnProposal`: Cast a vote on a proposal.
    *   `executeProposal`: Execute a successful proposal.
    *   `cancelProposal`: Cancel a proposal (if allowed).
    *   `getProposalState`: View proposal status.
    *   `getVotingPower`: View voter's power (based on total staked TIME).
    *   `getProposalDetails`: View full proposal data.
    *   `getCurrentProposals`: View list of active/votable proposals.
15. **Governance Target Functions:** Functions designed to be called *only* via governance execution to modify contract parameters or perform privileged actions.
    *   `gov_setEvolutionRate`: Set global evolution rate.
    *   `gov_setStakingMultiplier`: Set multiplier for staked TIME influence.
    *   `gov_setVotingPeriod`: Set proposal voting duration.
    *   `gov_setQuorumPercentage`: Set required percentage of total voting power for quorum.
    *   `gov_setProposalThreshold`: Set required staked TIME to submit a proposal.
    *   `gov_mintTimeTokens`: Mint new TIME tokens (controlled inflation).
    *   `gov_burnTimeTokens`: Burn TIME tokens.
16. **Utility/Emergency Functions:**
    *   `withdrawStuckETH`: Rescue stuck ETH (owner/governance).
    *   `withdrawStuckTokens`: Rescue stuck ERC20 tokens (owner/governance).

---

**Function Summary (Highlighting the 20+ custom/interesting ones):**

1.  `mintChronoNFT(address to, string memory uri)`: Creates a new Chrono-NFT for `to`, initializes its dynamic state, and assigns metadata URI. (Custom NFT creation)
2.  `burnChronoNFT(uint256 tokenId)`: Destroys a Chrono-NFT. Can only be called by the owner/approved. Clears staked tokens. (Custom NFT destruction)
3.  `getNFTData(uint256 tokenId) public view returns (...)`: Retrieves the *current* dynamic properties (level, aura, etc.), creation time, last update time, and staked tokens for a specific NFT. (Dynamic state view)
4.  `calculateEvolutionPoints(uint256 tokenId) public view returns (uint256 timePoints, uint256 stakedPoints)`: Calculates how many evolution points an NFT *would* gain based on time elapsed since last update and staked TIME tokens, using current global parameters. (Predictive view)
5.  `updateNFTState(uint256 tokenId) public`: Triggers the evolution process for a specific NFT. It calculates evolution points gained since the `lastUpdateTime` and applies them to the NFT's dynamic properties (level, aura, etc.). Can be called by anyone, but gas costs fall on the caller. (Core dynamic state mechanic)
6.  `stakeTimeTokensToNFT(uint256 tokenId, uint256 amount) public`: Allows the caller (NFT owner or approved) to stake `amount` of their internal `TIME` tokens to the specified NFT. Transfers `TIME` internally and updates the NFT's staked balance, potentially triggering a state update. (NFT-linked staking)
7.  `unstakeTimeTokensFromNFT(uint256 tokenId, uint256 amount) public`: Allows the caller (NFT owner or approved) to unstake `amount` of `TIME` tokens previously staked to the NFT. Transfers `TIME` internally back to the user and updates the NFT's staked balance, potentially triggering a state update. (NFT-linked unstaking)
8.  `getStakedTimeTokensForNFT(uint256 tokenId) public view returns (uint256)`: Returns the current amount of `TIME` tokens staked to a specific NFT. (Staking view)
9.  `timeTotalSupply() public view returns (uint256)`: Returns the total supply of the internal `TIME` token. (Internal token view)
10. `timeBalanceOf(address account) public view returns (uint256)`: Returns the internal `TIME` token balance of an account. (Internal token view)
11. `getVotingPower(address voter) public view returns (uint256)`: Returns the current voting power of an address, based on their *total* amount of `TIME` tokens staked across *all* their owned NFTs. (Staked governance power view)
12. `submitProposal(string memory description, address targetContract, bytes memory executionCallData, uint256 votingPeriodDuration) public returns (uint256 proposalId)`: Creates a new governance proposal. Requires the caller to have a minimum staked `TIME` threshold (`proposalThreshold`). Defines the target contract and function call (`executionCallData`) if the proposal passes. (On-chain governance proposal creation)
13. `voteOnProposal(uint256 proposalId, bool support) public`: Allows an address to cast a vote (for/against) on an active proposal. Voting power is based on `getVotingPower()` at the time of voting. Each address can only vote once per proposal. (On-chain voting)
14. `executeProposal(uint256 proposalId) public`: Attempts to execute a proposal that has ended, met quorum, and has more 'for' votes than 'against'. Calls the target contract with the specified data. (On-chain governance execution)
15. `cancelProposal(uint256 proposalId) public`: Allows the original proposer or a privileged address/governance action to cancel a proposal before it ends. (Governance proposal management)
16. `getProposalState(uint256 proposalId) public view returns (ProposalState)`: Returns the current state of a proposal (Pending, Active, Succeeded, Failed, Executed, Cancelled). (Governance state view)
17. `getProposalDetails(uint256 proposalId) public view returns (...)`: Retrieves full details about a proposal, including votes, state, and execution data. (Governance details view)
18. `getCurrentProposals() public view returns (uint256[] memory)`: Returns a list of proposal IDs that are currently in the 'Pending' or 'Active' state. (Active governance view)
19. `gov_setEvolutionRate(uint256 rate) public onlyGovExecution`: Sets the global parameter controlling the base speed of NFT evolution due to time passing. Callable only by successful governance proposal execution. (Governance-controlled parameter)
20. `gov_setStakingMultiplier(uint256 multiplier) public onlyGovExecution`: Sets the global parameter controlling how much staked `TIME` influences NFT evolution speed. Callable only by successful governance proposal execution. (Governance-controlled parameter)
21. `gov_setVotingPeriod(uint256 duration) public onlyGovExecution`: Sets the duration for which proposals are open for voting. Callable only by successful governance proposal execution. (Governance-controlled parameter)
22. `gov_setQuorumPercentage(uint256 percentage) public onlyGovExecution`: Sets the percentage of total voting power required to participate in a vote for it to be valid (quorum). Callable only by successful governance proposal execution. (Governance-controlled parameter)
23. `gov_setProposalThreshold(uint256 threshold) public onlyGovExecution`: Sets the minimum total staked `TIME` required for an address to submit a new proposal. Callable only by successful governance proposal execution. (Governance-controlled parameter)
24. `gov_mintTimeTokens(address to, uint256 amount) public onlyGovExecution`: Mints new `TIME` tokens and assigns them to an address. A mechanism for controlled inflation or rewards, only callable by successful governance proposal execution. (Governance-controlled tokenomics)
25. `gov_burnTimeTokens(address from, uint256 amount) public onlyGovExecution`: Burns `TIME` tokens from an address's balance. Can be used for deflation or penalty mechanisms, only callable by successful governance proposal execution. (Governance-controlled tokenomics)
26. `withdrawStuckETH() public onlyOwner`: Emergency function to withdraw accidentally sent ETH to the contract. (Safety)
27. `withdrawStuckTokens(address tokenAddress) public onlyOwner`: Emergency function to withdraw accidentally sent ERC20 tokens (other than TIME or ChronoNFTs if they were ERC20 - which they aren't) to the contract. (Safety)

*Note: Standard ERC721/ERC20 interface functions like `approve`, `setApprovalForAll`, `allowance`, `transfer`, `transferFrom` for the NFT part are implicitly included by inheriting/implementing the standard but are not listed above as they are not "creative" or "advanced" beyond the standard. The `TIME` token is handled internally without fully implementing the ERC20 interface externally for simplicity in a single contract, but its core balance/transfer logic is present via staking/unstaking and governance mint/burn.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// 1. License and Pragma
// 2. Imports
// 3. Errors
// 4. Structs (ChronoNFTData, Proposal)
// 5. Enums (ProposalState)
// 6. State Variables (NFT data, TIME balances, staked TIME, governance)
// 7. Events
// 8. Modifiers
// 9. Constructor
// 10. NFT (ERC-721) Functions (Mint, Burn, standard interface)
// 11. TIME (Internal ERC-20-like) Views
// 12. Chrono-NFT State & Evolution Functions
// 13. Staking Functions (TIME staked to NFT)
// 14. Governance Functions (Submit, Vote, Execute, Cancel, Views)
// 15. Governance Target Functions (Callable only by gov execution)
// 16. Utility/Emergency Functions

// Function Summary:
// 1.  mintChronoNFT(address to, string memory uri): Mints a new dynamic Chrono-NFT.
// 2.  burnChronoNFT(uint256 tokenId): Burns a Chrono-NFT, clearing staked tokens.
// 3.  getNFTData(uint256 tokenId): View current dynamic properties and staking info of an NFT.
// 4.  calculateEvolutionPoints(uint256 tokenId): View potential evolution points based on time/staking.
// 5.  updateNFTState(uint256 tokenId): Trigger NFT property evolution based on time and staked TIME.
// 6.  stakeTimeTokensToNFT(uint256 tokenId, uint256 amount): Stake internal TIME tokens to an NFT.
// 7.  unstakeTimeTokensFromNFT(uint256 tokenId, uint256 amount): Unstake internal TIME tokens from an NFT.
// 8.  getStakedTimeTokensForNFT(uint256 tokenId): View staked amount for an NFT.
// 9.  timeTotalSupply(): View total supply of internal TIME token.
// 10. timeBalanceOf(address account): View internal TIME token balance of an account.
// 11. getVotingPower(address voter): View voting power based on total staked TIME.
// 12. submitProposal(string memory description, address targetContract, bytes memory executionCallData, uint256 votingPeriodDuration): Create a governance proposal.
// 13. voteOnProposal(uint256 proposalId, bool support): Vote on an active proposal using staked power.
// 14. executeProposal(uint256 proposalId): Execute a successful governance proposal.
// 15. cancelProposal(uint256 proposalId): Cancel a proposal.
// 16. getProposalState(uint256 proposalId): View status of a proposal.
// 17. getProposalDetails(uint256 proposalId): View full details of a proposal.
// 18. getCurrentProposals(): View list of pending/active proposals.
// 19. gov_setEvolutionRate(uint256 rate): Set base NFT evolution rate (Gov Only).
// 20. gov_setStakingMultiplier(uint256 multiplier): Set TIME staking influence on evolution (Gov Only).
// 21. gov_setVotingPeriod(uint256 duration): Set proposal voting period (Gov Only).
// 22. gov_setQuorumPercentage(uint256 percentage): Set voting quorum percentage (Gov Only).
// 23. gov_setProposalThreshold(uint256 threshold): Set min staked TIME to submit proposal (Gov Only).
// 24. gov_mintTimeTokens(address to, uint256 amount): Mint TIME tokens (Gov Only).
// 25. gov_burnTimeTokens(address from, uint256 amount): Burn TIME tokens (Gov Only).
// 26. withdrawStuckETH(): Withdraw stuck ETH (Owner/Gov).
// 27. withdrawStuckTokens(address tokenAddress): Withdraw stuck ERC20 tokens (Owner/Gov).

contract ChronoForge is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Errors ---
    error NotTokenOwnerOrApproved();
    error InvalidAmount();
    error NotEnoughTimeBalance();
    error NotEnoughStakedTimeForNFT();
    error NFTDoesNotExist();
    error ProposalDoesNotExist();
    error ProposalNotActive();
    error ProposalAlreadyVoted();
    error ProposalThresholdNotMet();
    error ProposalStillActive();
    error ProposalNotSucceeded();
    error ProposalExecutionFailed();
    error ProposalAlreadyExecutedOrCancelled();
    error InvalidQuorumPercentage();
    error InvalidEvolutionRate();
    error InvalidStakingMultiplier();
    error InvalidVotingPeriod();
    error InvalidProposalThreshold();
    error OnlyGovernanceExecutionAllowed();
    error CannotWithdrawOwnTokens();

    // --- Structs ---
    struct ChronoNFTData {
        uint64 creationTime;      // Block timestamp of creation
        uint64 lastUpdateTime;    // Block timestamp of last state update
        uint128 stakedTimeTokens; // Amount of internal TIME tokens staked to this NFT
        // Dynamic Properties (Example)
        uint32 level;
        uint32 aura;
        uint32 temporalDistortion;
        // Add more dynamic properties as needed
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Cancelled }

    struct Proposal {
        address proposer;
        string description;
        address targetContract;
        bytes executionCallData;
        uint64 creationTime;
        uint64 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voted; // Who has voted
        bool executed;
        bool cancelled;
    }

    // --- State Variables ---

    // ERC721-like state managed by OpenZeppelin
    // ERC20-like internal TIME token state
    mapping(address => uint256) private _timeBalances;
    uint256 private _timeTotalSupply;

    // Chrono-NFT Specific Data
    mapping(uint256 => ChronoNFTData) private _chronoNFTData;
    mapping(address => uint256) private _totalStakedTimeByAddress; // Total TIME staked by a user across all their NFTs

    // Evolution Parameters (Governance controlled)
    uint256 public evolutionRate = 1; // Base points per second from time
    uint256 public stakingMultiplier = 100; // Multiplier for points per staked TIME token per second (e.g., /10000 for decimals)

    // Governance State
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => address[]) private _votersForProposal; // Store voters for each proposal for 'voted' mapping access
    uint256 public votingPeriod = 7 days; // Default voting duration
    uint256 public quorumPercentage = 4; // 4% of total voting power needed for quorum (e.g., 400 for 4%)
    uint256 public proposalThreshold = 100 ether; // Minimum total staked TIME to submit a proposal

    // --- Events ---
    event ChronoNFTMinted(address indexed owner, uint256 indexed tokenId, string uri);
    event ChronoNFTBurned(uint256 indexed tokenId);
    event NFTStateUpdated(uint256 indexed tokenId, uint32 newLevel, uint32 newAura, uint32 newTemporalDistortion);
    event TimeTokensStaked(uint256 indexed tokenId, address indexed staker, uint256 amount, uint256 newStakedBalance);
    event TimeTokensUnstaked(uint256 indexed tokenId, address indexed unstaker, uint256 amount, uint256 newStakedBalance);
    event TimeTokensMinted(address indexed to, uint256 amount);
    event TimeTokensBurned(address indexed from, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ProposalCancelled(uint256 indexed proposalId);
    event ParametersUpdated(string indexed parameterName, uint256 newValue);

    // --- Modifiers ---
    modifier onlyGovExecution() {
        // This modifier ensures the function is called internally by the executeProposal function
        // The sender check prevents external calls while allowing internal calls via 'call'
        require(msg.sender == address(this), OnlyGovernanceExecutionAllowed());
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) ReentrancyGuard() {
        // Initial parameters are set via state variables, can be changed by governance later
    }

    // --- ERC721 Overrides (Adding state update logic) ---

    // Override _update to potentially trigger state updates on transfer
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721URIStorage) returns (address) {
         if (_exists(tokenId)) {
             // Before transfer, update state for the current owner
             if (ownerOf(tokenId) != address(0)) {
                 updateNFTState(tokenId); // Update state based on time spent with current owner
             }
         }
         address oldOwner = super._update(to, tokenId, auth);
         if (to != address(0)) {
             // After transfer, update state for the new owner (resets lastUpdateTime)
             _chronoNFTData[tokenId].lastUpdateTime = uint64(block.timestamp);
         }
         return oldOwner;
    }

    // Standard ERC721 functions are inherited/handled by OpenZeppelin.
    // We only need to override if we add specific pre/post logic.
    // The _update override handles state updates on transfer.
    // approve, setApprovalForAll don't need state updates.

    // Standard view functions like ownerOf, balanceOf, getApproved, isApprovedForAll, supportsInterface
    // are inherited from ERC721 and ERC721URIStorage.

    // Standard transfer functions (transferFrom, safeTransferFrom) call _update internally.

    // Override tokenURI to allow dynamic metadata based on state (conceptual)
    // In a real dapp, a metadata server would read the on-chain state
    // via getNFTData and serve a dynamic JSON. This override is a placeholder.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

         // Get dynamic data
         ChronoNFTData storage data = _chronoNFTData[tokenId];
         uint265 currentLevel = data.level; // Use dynamic state

         // You would typically fetch base URI and construct the final URI pointing to a dynamic metadata server
         // Example (simplified placeholder):
         string memory base = super.tokenURI(tokenId); // Get base URI from ERC721URIStorage

         // Append level or other data to the URI (example only, metadata servers handle this)
         // This part is complex and often off-chain. For a realistic implementation,
         // the metadata server would simply call getNFTData.
         // return string(abi.encodePacked(base, "?level=", Strings.toString(currentLevel)));

         // Returning base URI from storage as a practical approach for demonstration
         return base;
     }


    // --- Chrono-NFT Specific Functions ---

    function mintChronoNFT(address to, string memory uri) public onlyOwner nonReentrant returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _mint(to, newItemId);
        _setTokenURI(newItemId, uri);

        uint64 currentTime = uint64(block.timestamp);
        _chronoNFTData[newItemId] = ChronoNFTData({
            creationTime: currentTime,
            lastUpdateTime: currentTime,
            stakedTimeTokens: 0,
            level: 1, // Initial state
            aura: 0,
            temporalDistortion: 0
        });

        emit ChronoNFTMinted(to, newItemId, uri);
        return newItemId;
    }

    function burnChronoNFT(uint256 tokenId) public nonReentrant {
        address owner = ownerOf(tokenId); // Checks existence internally
        require(_isApprovedOrOwner(_msgSender(), tokenId), NotTokenOwnerOrApproved());

        // Refund any staked TIME tokens before burning
        uint256 staked = _chronoNFTData[tokenId].stakedTimeTokens;
        if (staked > 0) {
            _timeBalances[owner] += staked;
            _totalStakedTimeByAddress[owner] -= staked;
            _chronoNFTData[tokenId].stakedTimeTokens = 0; // Reset staked tokens for this NFT
            emit TimeTokensUnstaked(tokenId, owner, staked, 0); // Log the refund as an unstake event
        }

        _burn(tokenId); // Handles ERC721 burning
        delete _chronoNFTData[tokenId]; // Clear NFT data
        emit ChronoNFTBurned(tokenId);
    }

    function getNFTData(uint256 tokenId) public view returns (
        uint64 creationTime,
        uint64 lastUpdateTime,
        uint128 stakedTimeTokens,
        uint32 level,
        uint32 aura,
        uint32 temporalDistortion
    ) {
        if (!_exists(tokenId)) revert NFTDoesNotExist();
        ChronoNFTData storage data = _chronoNFTData[tokenId];
        return (
            data.creationTime,
            data.lastUpdateTime,
            data.stakedTimeTokens,
            data.level,
            data.aura,
            data.temporalDistortion
        );
    }

    function calculateEvolutionPoints(uint256 tokenId) public view returns (uint256 timePoints, uint256 stakedPoints) {
         if (!_exists(tokenId)) revert NFTDoesNotExist();
         ChronoNFTData storage data = _chronoNFTData[tokenId];
         uint256 timeElapsed = block.timestamp - data.lastUpdateTime;

         // Time points calculation: time elapsed * evolution rate
         timePoints = timeElapsed * evolutionRate;

         // Staked points calculation: staked amount * staking multiplier * time elapsed
         // Use WAD (1e18) for staked tokens, multiplier could be scaled too (e.g., 10000 for 1x)
         // Example: staked (WAD) * multiplier / 1e4 * timeElapsed / 1e4 -> simplification depends on desired scaling
         // Let's assume multiplier is scaled such that stakingMultiplier/1e4 is the rate per staked TIME
         // Example: Staked (in units) * (stakingMultiplier / 1e4) * timeElapsed
         // Note: Direct multiplication can overflow. Use fixed point math or scale carefully.
         // Simple linear example:
         uint256 staked = data.stakedTimeTokens;
         // Points per unit staked per second = stakingMultiplier / 1e4 (assuming multiplier is scaled by 1e4)
         // total staked points = staked * (stakingMultiplier / 1e4) * timeElapsed
         // To avoid float, use large integer math: (staked * stakingMultiplier * timeElapsed) / 1e4
         // Let's assume stakingMultiplier is points per TIME per second directly for simplicity in this example.
         // A more robust system would use higher precision math.
         stakedPoints = staked * stakingMultiplier * timeElapsed;

         // Prevent overflow if timeElapsed is very large
         // Add checks or use safemath if not on 0.8+ or for very large multiplications.
         // For demonstration, simple multiplication is shown.
    }


    function updateNFTState(uint256 tokenId) public nonReentrant {
        if (!_exists(tokenId)) revert NFTDoesNotExist();
        // Anyone can call to push state update, but pays gas
        // Contract logic guarantees correct state update based on time & staking
        _applyEvolution(tokenId);
    }

    // Internal function to apply evolution based on time since last update and staked tokens
    function _applyEvolution(uint256 tokenId) internal {
        ChronoNFTData storage data = _chronoNFTData[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        if (currentTime <= data.lastUpdateTime) {
            // No time has passed since last update
            return;
        }

        uint256 timeElapsed = currentTime - data.lastUpdateTime;

        // Calculate points gained from time and staking
        uint256 timePoints = timeElapsed * evolutionRate;
        uint256 staked = data.stakedTimeTokens; // Staked amount in TIME units (e.g., 1e18)
        // Calculate staked points (simplified linear example)
        // A better model would use more sophisticated fixed point math or curves
        uint256 stakedPoints = (staked * stakingMultiplier * timeElapsed) / (1 ether); // Assuming stakingMultiplier is points per TIME unit (1e18) per second

        uint256 totalPointsGained = timePoints + stakedPoints;

        // Apply points to update properties (Example logic)
        // This logic determines how points translate to level, aura, etc.
        // Can be complex, potentially tiered or non-linear.
        // Simple linear example:
        uint256 pointsPerLevel = 1000; // Example: 1000 points to gain a level

        uint256 pointsRemainder = totalPointsGained;
        while (pointsRemainder >= pointsPerLevel && data.level < type(uint32).max) {
             data.level += 1;
             pointsRemainder -= pointsPerLevel;
             // Points needed for next level could increase
             // pointsPerLevel = pointsPerLevel * 110 / 100; // Example: 10% increase per level
        }

        // Distribute remaining points to other properties (example)
        data.aura = uint32(uint256(data.aura) + (pointsRemainder / 10)); // 10 points = 1 aura
        data.temporalDistortion = uint32(uint256(data.temporalDistortion) + (pointsRemainder % 10)); // Remaining points affect distortion

        // Clamp values if they exceed uint32 limits
        if (data.aura > type(uint32).max) data.aura = type(uint32).max;
        if (data.temporalDistortion > type(uint32).max) data.temporalDistortion = type(uint32).max;


        data.lastUpdateTime = currentTime; // Update last update time

        emit NFTStateUpdated(tokenId, data.level, data.aura, data.temporalDistortion);
    }

    function getEvolutionParameters() public view returns (uint256 currentEvolutionRate, uint256 currentStakingMultiplier) {
        return (evolutionRate, stakingMultiplier);
    }


    // --- TIME Token Staking Functions ---

    // Note: Internal TIME token transfers happen within this contract's mappings.
    // Users must first have TIME tokens (e.g., minted via governance or other means).

    function stakeTimeTokensToNFT(uint256 tokenId, uint256 amount) public nonReentrant {
        address owner = ownerOf(tokenId); // Checks existence internally
        require(_isApprovedOrOwner(_msgSender(), tokenId), NotTokenOwnerOrApproved());
        if (amount == 0) revert InvalidAmount();
        if (_timeBalances[_msgSender()] < amount) revert NotEnoughTimeBalance();

        // Update NFT state before staking to ensure points are calculated up to now
        _applyEvolution(tokenId);

        // Perform internal transfer
        _timeBalances[_msgSender()] -= amount;
        _chronoNFTData[tokenId].stakedTimeTokens += uint128(amount); // Use uint128 for potentially large staked amounts
        _totalStakedTimeByAddress[_msgSender()] += amount;

        emit TimeTokensStaked(tokenId, _msgSender(), amount, _chronoNFTData[tokenId].stakedTimeTokens);
    }

    function unstakeTimeTokensFromNFT(uint256 tokenId, uint256 amount) public nonReentrant {
        address owner = ownerOf(tokenId); // Checks existence internally
        require(_isApprovedOrOwner(_msgSender(), tokenId), NotTokenOwnerOrApproved());
        if (amount == 0) revert InvalidAmount();
        if (_chronoNFTData[tokenId].stakedTimeTokens < amount) revert NotEnoughStakedTimeForNFT();

        // Update NFT state before unstaking
         _applyEvolution(tokenId);

        // Perform internal transfer
        _chronoNFTData[tokenId].stakedTimeTokens -= uint128(amount);
        _timeBalances[_msgSender()] += amount;
        _totalStakedTimeByAddress[_msgSender()] -= amount;

        emit TimeTokensUnstaked(tokenId, _msgSender(), amount, _chronoNFTData[tokenId].stakedTimeTokens);
    }

     function getStakedTimeTokensForNFT(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert NFTDoesNotExist();
         return _chronoNFTData[tokenId].stakedTimeTokens;
     }


    // --- Governance Functions ---

    function getVotingPower(address voter) public view returns (uint256) {
        // Voting power is based on the total TIME tokens staked by the voter across all their NFTs
        return _totalStakedTimeByAddress[voter];
    }

    function submitProposal(string memory description, address targetContract, bytes memory executionCallData, uint256 votingPeriodDuration) public nonReentrant returns (uint256 proposalId) {
        if (getVotingPower(_msgSender()) < proposalThreshold) revert ProposalThresholdNotMet();
        if (votingPeriodDuration == 0) revert InvalidVotingPeriod(); // Use votingPeriod state var or parameter? Let's use parameter for flexibility.

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();
        uint64 currentTime = uint64(block.timestamp);

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.proposer = _msgSender();
        newProposal.description = description;
        newProposal.targetContract = targetContract;
        newProposal.executionCallData = executionCallData;
        newProposal.creationTime = currentTime;
        newProposal.endTime = currentTime + uint64(votingPeriodDuration); // Use provided duration
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;
        newProposal.cancelled = false;
        // The 'voted' mapping is nested and managed directly

        emit ProposalCreated(newProposalId, _msgSender(), description, newProposal.endTime);
        return newProposalId;
    }

    function voteOnProposal(uint256 proposalId, bool support) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist();
        if (proposal.endTime < block.timestamp || proposal.executed || proposal.cancelled) revert ProposalNotActive(); // Includes Pending state implicitly
        if (proposal.voted[_msgSender()]) revert ProposalAlreadyVoted();

        uint256 voterPower = getVotingPower(_msgSender());
        if (voterPower == 0) {
             // Optionally require minimum voting power to vote
             // revert InvalidAmount(); // Or another specific error
             // For now, allow 0 power voters to mark participation but add no weight
        }

        proposal.voted[_msgSender()] = true;
        _votersForProposal[proposalId].push(_msgSender()); // Keep track of voters for iterating 'voted' mapping

        if (support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }

        emit Voted(proposalId, _msgSender(), support, voterPower);
    }

    // Helper to calculate proposal state
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) return ProposalState.Pending; // Represents non-existent or initial state

        if (proposal.executed) return ProposalState.Executed;
        if (proposal.cancelled) return ProposalState.Cancelled;
        if (proposal.creationTime == 0 || proposal.endTime == 0) return ProposalState.Pending; // Not fully initialized/submitted

        if (proposal.endTime > block.timestamp) return ProposalState.Active;

        // Voting period has ended, determine outcome
        uint256 totalVotingPower = _timeTotalSupply; // Or total TIME staked across all users? Let's use total supply for simplicity in this example.
                                                     // A better approach uses _totalStakedTimeByAddress across all holders.
                                                     // For simplicity here, total supply. Real DAO needs careful power calc.
                                                     // Let's use total staked as calculated by sum of _totalStakedTimeByAddress values if we had an easy way to sum them...
                                                     // Using total supply as a proxy for now. Quorum will be relative to this.
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

        // Check Quorum: Total votes must be >= quorumPercentage of total voting power
        // (totalVotes * 100) >= (totalVotingPower * quorumPercentage)
        // Use 1e2 to represent percentage points (e.g., 400 for 4%)
        // (totalVotes * 1e4) >= (totalVotingPower * quorumPercentage)
        if (totalVotes * 100 < _timeTotalSupply * quorumPercentage / 100 ) { // Simple percentage calculation
             return ProposalState.Failed; // Did not meet quorum
        }


        if (proposal.votesFor > proposal.votesAgainst) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Failed;
        }
    }

     function executeProposal(uint256 proposalId) public nonReentrant {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.proposer == address(0)) revert ProposalDoesNotExist();
         if (getProposalState(proposalId) != ProposalState.Succeeded) revert ProposalNotSucceeded();
         if (proposal.executed || proposal.cancelled) revert ProposalAlreadyExecutedOrCancelled();

         proposal.executed = true; // Mark executed before the call to prevent re-execution
         bool success;
         // Execute the function call specified in the proposal
         (success, ) = proposal.targetContract.call(proposal.executionCallData);

         if (!success) {
             // Revert execution and mark as failed if the call fails
             proposal.executed = false; // Revert the executed flag
             // Optionally set state to Failed or add a new state like ExecutionFailed
             // For simplicity, let's just emit failure and let getProposalState remain Succeeded
             // It's important external systems check the event/state.
             emit ProposalExecuted(proposalId, false);
             revert ProposalExecutionFailed(); // Indicate failure explicitly
         }

         emit ProposalExecuted(proposalId, true);
     }

     function cancelProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist();
        if (proposal.endTime <= block.timestamp) revert ProposalStillActive(); // Can only cancel before voting ends
        if (proposal.executed || proposal.cancelled) revert ProposalAlreadyExecutedOrCancelled();

        // Only proposer or maybe a designated admin/owner can cancel (add checks here)
        // For this example, let's allow only the proposer
        require(_msgSender() == proposal.proposer, "Only proposer can cancel");

        proposal.cancelled = true;
        emit ProposalCancelled(proposalId);
     }

    function getProposalDetails(uint256 proposalId) public view returns (
        address proposer,
        string memory description,
        address targetContract,
        bytes memory executionCallData,
        uint64 creationTime,
        uint64 endTime,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state
    ) {
        Proposal storage proposal = proposals[proposalId];
        state = getProposalState(proposalId); // Get calculated state

        return (
            proposal.proposer,
            proposal.description,
            proposal.targetContract,
            proposal.executionCallData,
            proposal.creationTime,
            proposal.endTime,
            proposal.votesFor,
            proposal.votesAgainst,
            state
        );
    }

     // Note: Getting *all* proposals or current active ones can be gas-intensive if there are many.
     // A more scalable approach uses external indexing services.
     // This is a simple implementation for demonstration.
     function getCurrentProposals() public view returns (uint256[] memory) {
         uint256[] memory active;
         uint256 count = 0;
         // First pass to count active/pending proposals
         for(uint256 i = 1; i <= _proposalIdCounter.current(); i++) {
             ProposalState state = getProposalState(i);
             if (state == ProposalState.Pending || state == ProposalState.Active) {
                 count++;
             }
         }

         active = new uint256[](count);
         uint256 currentIndex = 0;
          // Second pass to populate the array
         for(uint256 i = 1; i <= _proposalIdCounter.current(); i++) {
             ProposalState state = getProposalState(i);
              if (state == ProposalState.Pending || state == ProposalState.Active) {
                 active[currentIndex] = i;
                 currentIndex++;
             }
         }
         return active;
     }

     // Note: The 'voted' mapping within the Proposal struct is public, but iterating it directly
     // is not possible in Solidity. getProposalDetails gives vote counts.
     // To get the list of voters, you'd need to rely on past events or store them separately,
     // as done with _votersForProposal array (though iterating this array to check votes is also gas intensive).
     // For a real system, querying events off-chain is standard.

     // --- Governance Target Functions (Callable only by executeProposal) ---

    function gov_setEvolutionRate(uint256 rate) public onlyGovExecution {
        if (rate == 0) revert InvalidEvolutionRate();
        evolutionRate = rate;
        emit ParametersUpdated("evolutionRate", rate);
    }

    function gov_setStakingMultiplier(uint256 multiplier) public onlyGovExecution {
         // Allow 0 multiplier if staking shouldn't affect evolution
         stakingMultiplier = multiplier;
         emit ParametersUpdated("stakingMultiplier", multiplier);
     }

    function gov_setVotingPeriod(uint256 duration) public onlyGovExecution {
        if (duration == 0) revert InvalidVotingPeriod();
        votingPeriod = duration;
        emit ParametersUpdated("votingPeriod", duration);
    }

    function gov_setQuorumPercentage(uint256 percentage) public onlyGovExecution {
        // Quorum is percentage * 100 (e.g., 400 for 4%)
        // Max 10000 for 100%
        if (percentage > 10000) revert InvalidQuorumPercentage();
        quorumPercentage = percentage;
        emit ParametersUpdated("quorumPercentage", percentage);
    }

    function gov_setProposalThreshold(uint256 threshold) public onlyGovExecution {
        proposalThreshold = threshold; // Allow 0 threshold
        emit ParametersUpdated("proposalThreshold", threshold);
    }

    function gov_mintTimeTokens(address to, uint256 amount) public onlyGovExecution {
        if (amount == 0) revert InvalidAmount();
        // Minting internal TIME tokens
        _timeBalances[to] += amount;
        _timeTotalSupply += amount;
        emit TimeTokensMinted(to, amount);
    }

     function gov_burnTimeTokens(address from, uint256 amount) public onlyGovExecution {
         if (amount == 0) revert InvalidAmount();
         if (_timeBalances[from] < amount) revert NotEnoughTimeBalance();
         // Burning internal TIME tokens
         _timeBalances[from] -= amount;
         _timeTotalSupply -= amount;
         emit TimeTokensBurned(from, amount);
     }


    // --- Utility/Emergency Functions ---

    function withdrawStuckETH() public onlyOwner {
        // Owner can withdraw ETH accidentally sent to the contract
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

     function withdrawStuckTokens(address tokenAddress) public onlyOwner {
         // Owner can withdraw other ERC20 tokens accidentally sent to the contract
         // Prevents withdrawing ChronoNFTs or internal TIME (as TIME isn't a standard ERC20 external)
         require(tokenAddress != address(this), CannotWithdrawOwnTokens()); // Prevents infinite loop if this contract deployed as ERC20

         IERC20 token = IERC20(tokenAddress);
         uint256 balance = token.balanceOf(address(this));
         if (balance > 0) {
             token.transfer(owner(), balance);
         }
     }

     // --- Internal ERC20-like Logic for TIME Token ---
     // These functions are internal and called by staking/unstaking/governance mint/burn
     // They are not part of the external function count requested, but are necessary helpers.
     // _transferTime(address from, address to, uint256 amount) internal; // Not needed with direct mapping access


}

// Basic IERC20 interface for withdrawStuckTokens
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    // Add other necessary ERC20 functions if needed by utility function
}
```