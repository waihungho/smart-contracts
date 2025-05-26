Okay, let's design a smart contract system focused on Dynamic NFTs ("Essences"), a utility token ("Spark"), Staking, and DAO Governance, tied together by the concept of cultivation and randomness influencing the NFTs. We'll call the main contract "The Forge".

It will integrate concepts like:
*   **Dynamic Metadata:** NFT traits can change based on on-chain actions or events.
*   **Utility Token Sink/Faucet:** Spark tokens are used for actions (cultivation) and earned via staking.
*   **Staking:** Both Spark tokens and Essences can be staked for rewards and benefits.
*   **DAO Governance:** Stakeholders can propose and vote on changes to contract parameters.
*   **Oracle Integration (Simulated):** Use external randomness or data to influence NFT traits or outcomes.
*   **Tiered Utility/Benefits:** Staking NFTs unlocks different reward pools or capabilities.
*   **Gas Efficiency Considerations:** Basic techniques where applicable.
*   **Access Control & Pausability:** Standard safety features.

**Disclaimer:** This is a complex system design. For a real-world implementation, each component (ERC20, ERC721, DAO Timelock, Oracle interaction) would typically use battle-tested libraries like OpenZeppelin and Chainlink, be thoroughly audited, and likely separated into multiple contracts for modularity and upgradeability. This example combines logic for illustration.

---

### Smart Contract Outline: `TheForge`

1.  **Interfaces:** Define interfaces for dependent ERC20 and ERC721 contracts.
2.  **Libraries:** Import necessary OpenZeppelin libraries (Ownable, Pausable, ReentrancyGuard).
3.  **Errors:** Custom error definitions.
4.  **State Variables:**
    *   Addresses for Spark (ERC20) and Essence (ERC721) contracts.
    *   Oracle address and related data.
    *   Staking pool data (Spark, Essence).
    *   DAO proposal data.
    *   Configuration parameters (cultivation cost, staking rates, DAO thresholds).
    *   Mapping for Essence traits and cultivation levels.
    *   Mapping for staked token/NFT data.
5.  **Structs:** Define structs for Proposals, Staking Positions, Essence Traits.
6.  **Enums:** Define enum for Proposal States.
7.  **Events:** Define events for key actions (Mint, Cultivate, Stake, Unstake, Claim, Proposal Submitted, Voted, Executed, Randomness).
8.  **Modifiers:** Define custom modifiers (e.g., `onlyOracle`).
9.  **Constructor:** Initialize contract, set initial owner, link dependent contracts.
10. **Admin Functions:**
    *   `setDependentContracts`: Link Spark and Essence contracts.
    *   `setOracleAddress`: Set oracle address.
    *   `setCultivationCost`: Update Spark cost for cultivation.
    *   `setStakingRates`: Update staking reward rates.
    *   `setGovernanceParameters`: Update DAO parameters.
    *   `pauseContract`: Pause core contract operations.
    *   `unpauseContract`: Unpause contract operations.
    *   `withdrawERC20Tokens`: Withdraw non-Spark ERC20s.
    *   `withdrawETH`: Withdraw ETH.
11. **Spark Token Interaction (Controlled Mint/Burn):**
    *   `mintSpark`: Mint Spark tokens (controlled, e.g., for rewards).
    *   `burnSpark`: Burn Spark tokens (user/system initiated).
12. **Essence NFT Interaction:**
    *   `mintEssence`: Mint a new Essence NFT.
    *   `cultivateEssence`: Spend Spark to improve Essence traits/level.
    *   `requestDynamicMetadataUpdate`: Request an update to an Essence's tokenURI based on its on-chain state.
13. **Staking Functions:**
    *   `stakeSpark`: Stake Spark tokens.
    *   `unstakeSpark`: Unstake Spark tokens.
    *   `claimSparkStakingRewards`: Claim Spark staking rewards.
    *   `stakeEssence`: Stake an Essence NFT.
    *   `unstakeEssence`: Unstake an Essence NFT.
    *   `claimEssenceStakingRewards`: Claim NFT staking rewards (could be Spark or other benefits).
14. **DAO Governance Functions:**
    *   `submitProposal`: Submit a new proposal (requires stake/NFT).
    *   `voteOnProposal`: Vote on an active proposal.
    *   `queueProposal`: Move successful proposal to execution queue (simulated timelock).
    *   `executeProposal`: Execute a proposal (after timelock/queue).
15. **Oracle Integration (Simulated):**
    *   `requestRandomness`: Request randomness from the oracle (emits event).
    *   `fulfillRandomness`: Oracle callback to provide randomness (updates state, potentially triggers trait changes).
16. **View Functions:**
    *   `getEssenceTraits`: View current traits of an Essence.
    *   `getEssenceCultivationLevel`: View cultivation level of an Essence.
    *   `getSparkStakingInfo`: View user's Spark staking details.
    *   `getEssenceStakingInfo`: View user's Essence staking details.
    *   `getSparkStakingAPY`: Calculate and view estimated Spark staking APY.
    *   `getEssenceStakingAPY`: Calculate and view estimated Essence staking APY.
    *   `getProposalDetails`: View details of a specific proposal.
    *   `getCurrentCultivationCost`: View current Spark cost to cultivate.
    *   `getTotalStakedSpark`: View total Spark staked in the contract.
    *   `getTotalStakedEssences`: View total Essences staked.
    *   `isPaused`: Check if the contract is paused.

### Function Summary

Here's a summary of over 20 functions implemented:

1.  `constructor()`: Initializes the contract, sets the owner, and links dependent Spark and Essence contracts.
2.  `setDependentContracts(address _sparkToken, address _essenceNFT)`: Owner function to set the addresses of the linked Spark ERC20 and Essence ERC721 contracts.
3.  `setOracleAddress(address _oracle)`: Owner function to set the address of the trusted oracle contract.
4.  `setCultivationCost(uint256 _cost)`: Owner function to update the Spark cost required to cultivate an Essence.
5.  `setSparkStakingRate(uint256 _rate)`: Owner function to set the annual percentage rate (APR) for Spark staking rewards.
6.  `setEssenceStakingRate(uint256 _rate)`: Owner function to set the APR for Essence NFT staking rewards.
7.  `setGovernanceParameters(uint256 _proposalThreshold, uint256 _votingPeriodBlocks, uint256 _quorumThreshold, uint256 _executionDelayBlocks)`: Owner function to configure DAO parameters.
8.  `pauseContract()`: Owner function to pause core contract functionalities (staking, minting, cultivation, voting).
9.  `unpauseContract()`: Owner function to unpause the contract.
10. `withdrawERC20Tokens(address _tokenAddress, address _to)`: Owner function to withdraw accidental non-Spark ERC20 transfers.
11. `withdrawETH(address _to)`: Owner function to withdraw accidental ETH transfers.
12. `mintSpark(address _to, uint256 _amount)`: Controlled function (e.g., callable by owner or staking reward logic) to mint Spark tokens.
13. `burnSpark(uint256 _amount)`: Allows a user to burn their own Spark tokens.
14. `mintEssence()`: Mints a new Essence NFT to the caller, potentially consuming Spark or ETH (example keeps it simple). Initializes base traits.
15. `cultivateEssence(uint256 _tokenId)`: Allows the owner of an Essence NFT to spend Spark to increase its cultivation level and potentially upgrade traits.
16. `requestDynamicMetadataUpdate(uint256 _tokenId)`: Triggers an event or internal flag indicating the off-chain metadata for this token should be refreshed to reflect its current on-chain traits.
17. `stakeSpark(uint256 _amount)`: Locks a user's Spark tokens in the contract's staking pool. Requires prior approval.
18. `unstakeSpark(uint256 _amount)`: Allows a user to withdraw staked Spark tokens after an optional unlock period (not implemented for simplicity, but crucial in practice).
19. `claimSparkStakingRewards()`: Calculates and sends accumulated Spark staking rewards to the caller.
20. `stakeEssence(uint256 _tokenId)`: Locks an Essence NFT in the contract's staking pool. Requires prior approval (`approve` ERC721).
21. `unstakeEssence(uint256 _tokenId)`: Allows a user to withdraw a staked Essence NFT.
22. `claimEssenceStakingRewards(uint256 _tokenId)`: Calculates and sends accumulated rewards/benefits for staking a specific Essence NFT.
23. `submitProposal(string memory _description, address[] memory _targetContracts, bytes[] memory _calldatas)`: Allows stakers/NFT owners to submit a governance proposal to change parameters or execute actions.
24. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows stakers/NFT owners to vote on an active proposal. Voting power proportional to stake/NFTs held.
25. `executeProposal(uint256 _proposalId)`: Executes a successful proposal after the voting period and simulated timelock have passed.
26. `requestRandomness()`: Sends a request for random data to the configured oracle address (simulated via event). Used internally, e.g., for trait evolution or reward distribution.
27. `fulfillRandomness(bytes32 _requestId, uint256 _randomWords)`: Callback function, callable *only* by the oracle address, to receive random data. Processes the random data to influence contract state (e.g., update NFT traits).
28. `getEssenceTraits(uint256 _tokenId)`: View function to retrieve the current traits of a specific Essence NFT.
29. `getSparkStakingInfo(address _user)`: View function to retrieve details about a user's current Spark staking position.
30. `getProposalDetails(uint256 _proposalId)`: View function to retrieve the state, votes, and details of a specific governance proposal.

---

### Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Example - could be custom Spark token
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Example - could be custom Essence NFT
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// --- Interfaces ---
interface ISparkToken is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}

interface IEssenceNFT is IERC721 {
    function mint(address to) external;
    // Note: Setting tokenURI typically requires specific implementation in the NFT contract
    // and calling it from the Forge contract via a function like `setTokenURI(uint256 tokenId, string memory uri)`
    // For simplicity, this example assumes an event triggers off-chain metadata updates.
}

// --- Errors ---
error TheForge__ZeroAddress();
error TheForge__AlreadyLinked();
error TheForge__NotLinked();
error TheForge__TransferFailed();
error TheForge__InvalidAmount();
error TheForge__StakingNotAllowed();
error TheForge__NotStaked();
error TheForge__NFTNotStaked();
error TheForge__NotTokenOwner();
error TheForge__InsufficientSpark();
error TheForge__EssenceNotFound();
error TheForge__NotOracle();
error TheForge__RandomnessRequestFailed();
error TheForge__ProposalDoesNotExist();
error TheForge__ProposalNotActive();
error TheForge__ProposalAlreadyVoted();
error TheForge__ProposalExecutionNotReady();
error TheForge__ProposalExecutionFailed();
error TheForge__UnauthorizedWithdrawal();

contract TheForge is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---
    ISparkToken public sparkToken;
    IEssenceNFT public essenceNFT;
    address public oracleAddress; // Trusted address for randomness/external data

    // Essence NFT Traits & Cultivation
    struct EssenceTraits {
        uint8 level; // Cultivation level
        uint8 strength;
        uint8 agility;
        uint8 intelligence;
        uint256 lastCultivatedBlock; // Block number when last cultivated
        uint256 lastRandomnessEffectBlock; // Block number when randomness last affected traits
    }
    mapping(uint256 => EssenceTraits) public essenceData;
    uint256 public cultivationCost = 1000e18; // Default cost in Spark

    // Spark Staking
    struct SparkStake {
        uint256 amount;
        uint256 startBlock;
        uint256 rewardDebt; // Amount of rewards already accounted for
    }
    mapping(address => SparkStake) public sparkStakes;
    uint256 public totalStakedSpark;
    uint256 public sparkRewardsPerBlock; // Calculated based on total staked and rate

    // Essence NFT Staking
    struct EssenceStake {
        uint256 startBlock;
        uint256 rewardDebt; // Amount of rewards already accounted for
        // Add fields for specific NFT staking benefits if needed
    }
    mapping(uint256 => EssenceStake) public essenceStakes; // tokenId => stake data
    mapping(address => uint256[]) public stakedEssencesByOwner; // owner => list of staked tokenIds
    uint256 public totalStakedEssences;
    uint256 public essenceRewardsPerBlock; // Calculated based on total staked and rate

    // DAO Governance
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }
    struct Proposal {
        uint256 id;
        string description;
        address[] targetContracts; // Contracts to interact with
        bytes[] calldatas; // Calldata for target interactions
        uint256 startBlock;
        uint256 endBlock;
        uint256 quorumThreshold;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        ProposalState state;
        uint256 executionBlock; // Block when proposal is available for execution after queue
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalThresholdSpark = 10000e18; // Spark needed to submit proposal
    uint256 public votingPeriodBlocks = 100; // Blocks for voting
    uint256 public quorumThresholdBPS = 4000; // 40% quorum, in basis points
    uint256 public executionDelayBlocks = 50; // Blocks delay after success before executable (simulated timelock)

    // Oracle Randomness Request State
    mapping(bytes32 => bool) public randomnessRequestStatus; // request ID => fulfilled?

    // --- Events ---
    event ContractsLinked(address indexed sparkToken, address indexed essenceNFT);
    event CultivationCostUpdated(uint256 newCost);
    event SparkStakingRateUpdated(uint256 newRate);
    event EssenceStakingRateUpdated(uint256 newRate);
    event GovernanceParametersUpdated(uint256 proposalThreshold, uint256 votingPeriod, uint256 quorumThreshold, uint256 executionDelay);
    event SparkMinted(address indexed account, uint256 amount);
    event SparkBurned(address indexed account, uint256 amount);
    event EssenceMinted(address indexed owner, uint256 indexed tokenId);
    event EssenceCultivated(uint256 indexed tokenId, address indexed cultivator, uint8 newLevel);
    event DynamicMetadataUpdateRequested(uint256 indexed tokenId);
    event SparkStaked(address indexed account, uint256 amount);
    event SparkUnstaked(address indexed account, uint256 amount);
    event SparkRewardsClaimed(address indexed account, uint256 amount);
    event EssenceStaked(address indexed owner, uint256 indexed tokenId);
    event EssenceUnstaked(address indexed owner, uint256 indexed tokenId);
    event EssenceRewardsClaimed(address indexed owner, uint256 indexed tokenId, uint256 rewardAmount); // Reward type might vary
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event RandomnessRequested(bytes32 indexed requestId, address indexed consumer, uint256 seed);
    event RandomnessFulfilled(bytes32 indexed requestId, uint256 randomNumber);
    event EssenceTraitsUpdatedByRandomness(uint256 indexed tokenId, uint256 randomNumber);


    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert TheForge__NotOracle();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _sparkToken, address _essenceNFT) Ownable(msg.sender) Pausable(false) {
        if (_sparkToken == address(0) || _essenceNFT == address(0)) {
            revert TheForge__ZeroAddress();
        }
        sparkToken = ISparkToken(_sparkToken);
        essenceNFT = IEssenceNFT(_essenceNFT);
        emit ContractsLinked(_sparkToken, _essenceNFT);

        // Initialize reward rates (example values)
        setSparkStakingRate(500); // 5% APR (scaled by blocks per year)
        setEssenceStakingRate(1000); // 10% APR (scaled)
    }

    // --- Admin Functions ---
    function setDependentContracts(address _sparkToken, address _essenceNFT) external onlyOwner {
        if (address(sparkToken) != address(0) || address(essenceNFT) != address(0)) {
             revert TheForge__AlreadyLinked();
        }
        if (_sparkToken == address(0) || _essenceNFT == address(0)) {
            revert TheForge__ZeroAddress();
        }
        sparkToken = ISparkToken(_sparkToken);
        essenceNFT = IEssenceNFT(_essenceNFT);
        emit ContractsLinked(_sparkToken, _essenceNFT);
    }

    function setOracleAddress(address _oracle) external onlyOwner {
        if (_oracle == address(0)) {
            revert TheForge__ZeroAddress();
        }
        oracleAddress = _oracle;
    }

    function setCultivationCost(uint256 _cost) external onlyOwner {
        cultivationCost = _cost;
        emit CultivationCostUpdated(_cost);
    }

    function setSparkStakingRate(uint256 _rate) public onlyOwner {
        // Calculate rewards per block assuming a constant rate
        // This simplified model assumes a constant reward pool size and doesn't account for variable total staked
        // A more robust model would adjust rewards per block based on totalStakedSpark
        uint256 blocksPerYear = 7200 * 365; // Approx based on 12s blocks
        sparkRewardsPerBlock = (sparkToken.totalSupply() * _rate) / 10000 / blocksPerYear;
        emit SparkStakingRateUpdated(_rate);
    }

    function setEssenceStakingRate(uint256 _rate) public onlyOwner {
        // Simplified: Assumes a fixed reward pool distributed based on total staked NFTs
        uint256 blocksPerYear = 7200 * 365; // Approx based on 12s blocks
         // This needs refinement based on reward mechanism (e.g., fixed Spark per NFT per block)
         // For simplicity, let's assume fixed Spark rewards per NFT per block.
         // A more realistic approach involves a pool distributed proportionally.
         // Here we'll calculate a base reward per NFT per block.
         // Example: Assuming 1 Spark per Essence per day -> 1e18 / 7200 per block
        essenceRewardsPerBlock = (1e18 * _rate) / 10000 / blocksPerYear / 365; // Approx daily rate per NFT

        emit EssenceStakingRateUpdated(_rate);
    }

    function setGovernanceParameters(uint256 _proposalThreshold, uint256 _votingPeriodBlocks, uint256 _quorumThresholdBPS, uint256 _executionDelayBlocks) external onlyOwner {
        proposalThresholdSpark = _proposalThreshold;
        votingPeriodBlocks = _votingPeriodBlocks;
        quorumThresholdBPS = _quorumThresholdBPS;
        executionDelayBlocks = _executionDelayBlocks;
        emit GovernanceParametersUpdated(_proposalThreshold, _votingPeriodBlocks, _quorumThresholdBPS, _executionDelayBlocks);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function withdrawERC20Tokens(address _tokenAddress, address _to) external onlyOwner nonReentrant {
        if (_to == address(0)) revert TheForge__ZeroAddress();
        if (_tokenAddress == address(sparkToken)) revert TheForge__UnauthorizedWithdrawal(); // Don't allow withdrawing main token

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }

    function withdrawETH(address _to) external onlyOwner nonReentrant {
         if (_to == address(0)) revert TheForge__ZeroAddress();
         (bool success, ) = payable(_to).call{value: address(this).balance}("");
         require(success, "ETH withdrawal failed");
    }

    // --- Spark Token Interaction (Controlled) ---
    // In a real system, Spark token has its own mint/burn logic.
    // These functions are examples of how Forge could trigger them IF Spark contract allows Forge to mint/burn.
    function mintSpark(address _to, uint256 _amount) external onlyOwner {
        if (address(sparkToken) == address(0)) revert TheForge__NotLinked();
        if (_to == address(0)) revert TheForge__ZeroAddress();
        if (_amount == 0) revert TheForge__InvalidAmount();
        sparkToken.mint(_to, _amount);
        emit SparkMinted(_to, _amount);
    }

    function burnSpark(uint256 _amount) external whenNotPaused nonReentrant {
         if (address(sparkToken) == address(0)) revert TheForge__NotLinked();
         if (_amount == 0) revert TheForge__InvalidAmount();
         sparkToken.burn(_amount);
         emit SparkBurned(msg.sender, _amount);
    }


    // --- Essence NFT Interaction ---
    function mintEssence() external whenNotPaused nonReentrant {
        if (address(essenceNFT) == address(0)) revert TheForge__NotLinked();

        uint256 tokenId = essenceNFT.totalSupply() + 1; // Simple ID generation

        // Mint the NFT (requires TheForge to have minter role on EssenceNFT)
        essenceNFT.mint(msg.sender); // Assuming mints next token ID

        // Initialize traits - simple base values
        essenceData[tokenId] = EssenceTraits({
            level: 1,
            strength: 1,
            agility: 1,
            intelligence: 1,
            lastCultivatedBlock: block.number,
            lastRandomnessEffectBlock: block.number
        });

        emit EssenceMinted(msg.sender, tokenId);
    }

    function cultivateEssence(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (address(essenceNFT) == address(0)) revert TheForge__NotLinked();
        if (essenceNFT.ownerOf(_tokenId) != msg.sender) revert TheForge__NotTokenOwner();
        if (sparkToken.balanceOf(msg.sender) < cultivationCost) revert TheForge__InsufficientSpark();

        // Transfer Spark from user to contract
        sparkToken.safeTransferFrom(msg.sender, address(this), cultivationCost);

        EssenceTraits storage traits = essenceData[_tokenId];
        traits.level++;
        // Simple trait improvement logic (can be more complex, e.g., based on randomness)
        traits.strength++;
        traits.agility++;
        traits.intelligence++;
        traits.lastCultivatedBlock = block.number;

        // Optionally trigger a randomness request for further trait influence
        requestRandomness(); // Internal call

        emit EssenceCultivated(_tokenId, msg.sender, traits.level);
        // Trigger metadata update event
        emit DynamicMetadataUpdateRequested(_tokenId);
    }

    function requestDynamicMetadataUpdate(uint256 _tokenId) external nonReentrant {
         if (essenceNFT.ownerOf(_tokenId) != msg.sender && essenceNFT.getApproved(_tokenId) != msg.sender && essenceNFT.isApprovedForAll(msg.sender, address(this)) == false) {
             revert TheForge__NotTokenOwner(); // Only owner or approved can request
         }
         // This event signals an off-chain service to fetch new metadata for this token ID
         emit DynamicMetadataUpdateRequested(_tokenId);
    }

    // --- Staking Functions ---

    function _updateSparkRewards(address _user) internal {
        SparkStake storage stake = sparkStakes[_user];
        if (stake.amount > 0) {
            uint256 blocksPassed = block.number - stake.startBlock;
            uint256 pendingRewards = (stake.amount * sparkRewardsPerBlock * blocksPassed) / 1e18; // Scaled by amount and rate
            stake.rewardDebt += pendingRewards; // Add to accumulated debt
            stake.startBlock = block.number; // Reset start block for next calculation
        }
    }

     function _updateEssenceRewards(uint256 _tokenId) internal {
        EssenceStake storage stake = essenceStakes[_tokenId];
        // Note: This simple model gives fixed rewards per block per NFT regardless of traits/level.
        // A more advanced model would adjust `essenceRewardsPerBlock` calculation per NFT based on its traits.
        uint256 blocksPassed = block.number - stake.startBlock;
        uint256 pendingRewards = (essenceRewardsPerBlock * blocksPassed); // Direct addition of reward per block
        stake.rewardDebt += pendingRewards;
        stake.startBlock = block.number;
     }

    function stakeSpark(uint256 _amount) external whenNotPaused nonReentrant {
        if (address(sparkToken) == address(0)) revert TheForge__NotLinked();
        if (_amount == 0) revert TheForge__InvalidAmount();

        _updateSparkRewards(msg.sender); // Claim pending rewards before restaking/adding

        sparkToken.safeTransferFrom(msg.sender, address(this), _amount);

        sparkStakes[msg.sender].amount += _amount;
        sparkStakes[msg.sender].startBlock = block.number; // Reset start block for the new total stake
        totalStakedSpark += _amount;

        emit SparkStaked(msg.sender, _amount);
    }

    function unstakeSpark(uint256 _amount) external whenNotPaused nonReentrant {
        SparkStake storage stake = sparkStakes[msg.sender];
        if (stake.amount < _amount) revert TheForge__InvalidAmount();

        _updateSparkRewards(msg.sender); // Finalize rewards before unstaking

        stake.amount -= _amount;
        totalStakedSpark -= _amount;

        // Transfer Spark back to user
        sparkToken.safeTransfer(msg.sender, _amount);

        // If remaining amount is zero, reset startBlock (optional, but clean)
        if (stake.amount == 0) {
             stake.startBlock = block.number;
        } else {
             stake.startBlock = block.number; // Reset start block for the remaining stake
        }

        emit SparkUnstaked(msg.sender, _amount);
    }

    function claimSparkStakingRewards() external whenNotPaused nonReentrant {
        _updateSparkRewards(msg.sender); // Calculate final pending rewards

        SparkStake storage stake = sparkStakes[msg.sender];
        uint256 rewardsToClaim = stake.rewardDebt;
        if (rewardsToClaim == 0) return; // No rewards to claim

        stake.rewardDebt = 0; // Reset reward debt

        // Mint or Transfer rewards (assuming Spark is minted by Forge or already in Forge)
        // If Spark is minted by Forge:
        // mintSpark(msg.sender, rewardsToClaim);
        // If Spark is transferred from contract balance:
        if (sparkToken.balanceOf(address(this)) < rewardsToClaim) {
             // Handle case where contract doesn't have enough Spark (e.g., need to mint or replenish)
             // For this example, we'll assume minting is possible or balance is sufficient
             sparkToken.mint(msg.sender, rewardsToClaim); // Example using minting
        } else {
             sparkToken.safeTransfer(msg.sender, rewardsToClaim); // Example using transfer from balance
        }


        emit SparkRewardsClaimed(msg.sender, rewardsToClaim);
    }

    function stakeEssence(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (address(essenceNFT) == address(0)) revert TheForge__NotLinked();
        if (essenceNFT.ownerOf(_tokenId) != msg.sender) revert TheForge__NotTokenOwner();
        if (essenceStakes[_tokenId].startBlock > 0) revert TheForge__AlreadyStaked(); // Check if already staked

        // Transfer NFT to the contract
        essenceNFT.safeTransferFrom(msg.sender, address(this), _tokenId);

        essenceStakes[_tokenId] = EssenceStake({
            startBlock: block.number,
            rewardDebt: 0
        });

        // Add token ID to user's staked list
        stakedEssencesByOwner[msg.sender].push(_tokenId);
        totalStakedEssences++;

        emit EssenceStaked(msg.sender, _tokenId);
    }

     function unstakeEssence(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (address(essenceNFT) == address(0)) revert TheForge__NotLinked();
        // Check if the caller *was* the staker and if the NFT is staked by this contract
        // A more robust check would verify the original staker address.
        if (essenceNFT.ownerOf(_tokenId) != address(this)) revert TheForge__NotStaked(); // Not held by Forge
        if (essenceStakes[_tokenId].startBlock == 0) revert TheForge__NotStaked(); // Not marked as staked internally

        address originalStaker = msg.sender; // This is naive, need to track staker in struct
        // In a real system, you'd need a mapping like `tokenId => originalStakerAddress`

        // For this example, we assume msg.sender is the original staker asking to unstake
        _updateEssenceRewards(_tokenId); // Finalize rewards

        // Remove NFT from user's staked list (inefficient for large lists, consider linked list or mapping)
        uint256[] storage stakedList = stakedEssencesByOwner[originalStaker];
        bool found = false;
        for (uint i = 0; i < stakedList.length; i++) {
            if (stakedList[i] == _tokenId) {
                stakedList[i] = stakedList[stakedList.length - 1];
                stakedList.pop();
                found = true;
                break;
            }
        }
        if (!found) revert TheForge__NotStaked(); // Should not happen if checks above pass

        delete essenceStakes[_tokenId]; // Remove stake data
        totalStakedEssences--;

        // Transfer NFT back to user
        essenceNFT.safeTransferFrom(address(this), originalStaker, _tokenId);

        emit EssenceUnstaked(originalStaker, _tokenId);
    }

    function claimEssenceStakingRewards(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (essenceStakes[_tokenId].startBlock == 0) revert TheForge__NFTNotStaked();
        // Check if caller is the staker (requires tracking staker in struct)
        // For simplicity, assuming caller owns the NFT, implying they unstaked it first,
        // or this function is called *before* unstaking and checks original staker.
        // Let's assume it's called *before* unstaking and check owner of staked NFT is *this* contract.
         if (essenceNFT.ownerOf(_tokenId) != address(this)) revert TheForge__NFTNotStaked();


        _updateEssenceRewards(_tokenId); // Calculate final pending rewards

        EssenceStake storage stake = essenceStakes[_tokenId];
        uint256 rewardsToClaim = stake.rewardDebt;
        if (rewardsToClaim == 0) return;

        stake.rewardDebt = 0; // Reset reward debt

        // Reward type for Essence staking (example: Spark)
        if (sparkToken.balanceOf(address(this)) < rewardsToClaim) {
             sparkToken.mint(msg.sender, rewardsToClaim); // Example using minting
        } else {
             sparkToken.safeTransfer(msg.sender, rewardsToClaim); // Example using transfer from balance
        }

        // Note: A real system would track the original staker of _tokenId to send rewards correctly.
        emit EssenceRewardsClaimed(msg.sender, _tokenId, rewardsToClaim);
    }


    // --- DAO Governance Functions ---

    // Helper to get voting power (e.g., based on Spark stake)
    function _getVotingPower(address _voter) internal view returns (uint256) {
        // Example: Voting power is equal to staked Spark amount
        return sparkStakes[_voter].amount;
        // Could also include staked Essences, or a combination
        // uint256 essencePower = stakedEssencesByOwner[_voter].length * 1000e18; // Example: Each staked NFT gives 1000 Spark equivalent power
        // return sparkStakes[_voter].amount + essencePower;
    }


    function submitProposal(string memory _description, address[] memory _targetContracts, bytes[] memory _calldatas) external whenNotPaused nonReentrant {
        if (_getVotingPower(msg.sender) < proposalThresholdSpark) {
            revert TheForge__InsufficientSpark(); // Or require staked Essence etc.
        }
        if (_targetContracts.length != _calldatas.length) {
             revert TheForge__InvalidAmount(); // Mismatch
        }

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.description = _description;
        proposal.targetContracts = _targetContracts;
        proposal.calldatas = _calldatas;
        proposal.startBlock = block.number;
        proposal.endBlock = block.number + votingPeriodBlocks;
        proposal.quorumThreshold = (totalStakedSpark * quorumThresholdBPS) / 10000; // Quorum based on total staked Spark
        proposal.state = ProposalState.Active;

        emit ProposalSubmitted(proposalId, msg.sender, _description);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert TheForge__ProposalDoesNotExist();
        if (proposal.state != ProposalState.Active) revert TheForge__ProposalNotActive();
        if (proposal.hasVoted[msg.sender]) revert TheForge__ProposalAlreadyVoted();
        if (block.number > proposal.endBlock) {
             // Voting period ended, transition state
             _processProposalState(_proposalId);
             revert TheForge__ProposalNotActive(); // Now it's not active
        }

        uint256 votingPower = _getVotingPower(msg.sender);
        if (votingPower == 0) revert TheForge__StakingNotAllowed(); // Only stakers/holders can vote

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit Voted(_proposalId, msg.sender, _support);
    }

    // Internal function to check and transition proposal state
    function _processProposalState(uint256 _proposalId) internal {
         Proposal storage proposal = proposals[_proposalId];

         if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
              // Voting period ended
              uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
              if (totalVotes < proposal.quorumThreshold || proposal.votesFor <= proposal.votesAgainst) {
                   proposal.state = ProposalState.Defeated;
                   emit ProposalStateChanged(_proposalId, ProposalState.Defeated);
              } else {
                   proposal.state = ProposalState.Succeeded;
                   proposal.executionBlock = block.number + executionDelayBlocks; // Set execution unlock time
                   emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);
              }
         } else if (proposal.state == ProposalState.Succeeded && block.number >= proposal.executionBlock) {
              proposal.state = ProposalState.Queued; // Ready for execution (simulated queue)
              emit ProposalStateChanged(_proposalId, ProposalState.Queued);
         } else if (proposal.state == ProposalState.Queued && block.number >= proposal.executionBlock + 1000) { // Add an expiry safety net
             proposal.state = ProposalState.Expired;
             emit ProposalStateChanged(_proposalId, ProposalState.Expired);
         }
    }

    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert TheForge__ProposalDoesNotExist();

        _processProposalState(_proposalId); // Ensure state is up-to-date

        if (proposal.state != ProposalState.Queued) revert TheForge__ProposalExecutionNotReady();

        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);

        // Execute actions
        for (uint i = 0; i < proposal.targetContracts.length; i++) {
            (bool success, ) = proposal.targetContracts[i].call(proposal.calldatas[i]);
            if (!success) {
                // Handle execution failure - could revert or log and continue
                // Reverting is safer if actions are interdependent
                revert TheForge__ProposalExecutionFailed();
            }
        }
    }


    // --- Oracle Integration (Simulated) ---

    function requestRandomness() internal returns (bytes32 requestId) {
        if (oracleAddress == address(0)) {
             // Handle case where oracle isn't set (e.g., use blockhash, but less secure)
             // For this example, we'll just emit an event assuming an oracle is expected
             revert TheForge__RandomnessRequestFailed();
        }
        // In a real Chainlink VRF system, you'd call `requestRandomWords`.
        // This is a simulation. Generate a unique ID and emit an event.
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number));
        requestId = keccak256(abi.encodePacked(address(this), seed));
        randomnessRequestStatus[requestId] = false; // Mark as pending
        emit RandomnessRequested(requestId, msg.sender, uint256(seed));
        return requestId;
    }

    // This function is called by the oracle contract after requesting randomness
    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) external onlyOracle nonReentrant {
        if (randomnessRequestStatus[_requestId] == true) return; // Already fulfilled

        randomnessRequestStatus[_requestId] = true; // Mark as fulfilled
        emit RandomnessFulfilled(_requestId, _randomNumber);

        // --- Apply Randomness Effect ---
        // Example: Find an Essence recently cultivated or affected by a previous request
        // and apply a random trait boost based on the number.
        // This requires a more sophisticated way to link randomness requests to specific NFTs.
        // For simplicity, let's just show *how* randomness could be used.

        uint256 affectedTokenId = (_randomNumber % totalStakedEssences) + 1; // Simplistic random pick among *staked* NFTs

        // Find the token ID at the random index (very inefficient for large numbers of staked NFTs)
        // A better approach involves mapping request IDs to actions/tokenIds.
        // Or having the fulfillment callback receive the target tokenId.
        // Let's assume the callback receives the target tokenId for this example's simplicity.
        // function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber, uint256 _targetTokenId) ...
        // We'll stick to the simpler `fulfillRandomness(_requestId, _randomNumber)` and apply it generally or find a target.
        // Let's apply it to the *last* cultivated Essence by the *requester* (if requestRandomness was public)
        // Since requestRandomness is internal, let's assume randomness affects the most recently cultivated NFT globally (still inefficient)
        // Or, better, have the cultivation function store a mapping `requestId => tokenId`.

        // Simulating a targeted effect: Assume the request was made *during* cultivation of tokenId X
        // This requires `cultivateEssence` to store `mapping(bytes32 => uint256) randomnessTargetTokenId;`
        // and `fulfillRandomness` to look it up.
        // Let's implement that mapping briefly.
        // Mapping to track which token ID a randomness request was for
        // mapping(bytes32 => uint256) private randomnessTargetTokenId; // Add to state vars

        // In cultivateEssence:
        // bytes32 reqId = requestRandomness();
        // randomnessTargetTokenId[reqId] = _tokenId;

        // In fulfillRandomness:
        uint256 targetTokenId = randomnessTargetTokenId[_requestId]; // Lookup target
        if (targetTokenId == 0) return; // No associated token or already processed

        EssenceTraits storage traits = essenceData[targetTokenId];

        // Apply random boost based on the number
        uint256 boostAmount = (_randomNumber % 3) + 1; // Boost 1-3 points
        uint256 statToBoost = _randomNumber / 3 % 3; // 0:Str, 1:Agi, 2:Int

        if (statToBoost == 0) traits.strength += uint8(boostAmount);
        else if (statToBoost == 1) traits.agility += uint8(boostAmount);
        else traits.intelligence += uint8(boostAmount);

        traits.lastRandomnessEffectBlock = block.number;

        // Clear the target mapping entry after processing (optional, helps save gas)
        delete randomnessTargetTokenId[_requestId];

        emit EssenceTraitsUpdatedByRandomness(targetTokenId, _randomNumber);
        // Trigger metadata update event
        emit DynamicMetadataUpdateRequested(targetTokenId);
    }

    // Note: The `randomnessTargetTokenId` mapping needs to be added to the state variables.
    mapping(bytes32 => uint256) private randomnessTargetTokenId; // Add this state variable


    // --- View Functions ---

    function getEssenceTraits(uint256 _tokenId) external view returns (uint8 level, uint8 strength, uint8 agility, uint8 intelligence, uint256 lastCultivated, uint256 lastRandomnessEffect) {
        EssenceTraits storage traits = essenceData[_tokenId];
        // Check if token exists/has data
        if (traits.level == 0 && traits.strength == 0 && traits.agility == 0 && traits.intelligence == 0) {
             revert TheForge__EssenceNotFound();
        }
        return (
            traits.level,
            traits.strength,
            traits.agility,
            traits.intelligence,
            traits.lastCultivatedBlock,
            traits.lastRandomnessEffectBlock
        );
    }

     function getEssenceCultivationLevel(uint256 _tokenId) external view returns (uint8) {
        EssenceTraits storage traits = essenceData[_tokenId];
         if (traits.level == 0 && traits.strength == 0 && traits.agility == 0 && traits.intelligence == 0) {
             revert TheForge__EssenceNotFound();
         }
        return traits.level;
    }


    function getSparkStakingInfo(address _user) external view returns (uint256 amount, uint256 startBlock, uint256 pendingRewards) {
        SparkStake storage stake = sparkStakes[_user];
        uint256 currentPending = 0;
        if (stake.amount > 0) {
            uint256 blocksPassed = block.number - stake.startBlock;
             currentPending = (stake.amount * sparkRewardsPerBlock * blocksPassed) / 1e18;
        }
        return (stake.amount, stake.startBlock, stake.rewardDebt + currentPending);
    }

    function getEssenceStakingInfo(uint256 _tokenId) external view returns (uint256 startBlock, uint256 pendingRewards, address currentStaker) {
         EssenceStake storage stake = essenceStakes[_tokenId];
         // Need to track staker in the struct or another mapping: mapping(uint256 => address) public essenceStaker;
         // Let's add essenceStaker mapping for this view function.
         // mapping(uint256 => address) public essenceStaker; // Add to state vars

         uint256 currentPending = 0;
         if (stake.startBlock > 0) {
             uint256 blocksPassed = block.number - stake.startBlock;
             currentPending = (essenceRewardsPerBlock * blocksPassed); // Direct addition
         }
         return (stake.startBlock, stake.rewardDebt + currentPending, essenceStaker[_tokenId]);
    }
     mapping(uint256 => address) public essenceStaker; // Add this state variable

    // Update stakeEssence and unstakeEssence to set/delete essenceStaker
    // stakeEssence: essenceStaker[_tokenId] = msg.sender;
    // unstakeEssence: delete essenceStaker[_tokenId];

    function getSparkStakingAPY() external view returns (uint256) {
        if (totalStakedSpark == 0) return 0;
        // Estimate blocks per year
        uint256 blocksPerYear = 7200 * 365; // Approx based on 12s block time
        // Calculate approximate annual rewards from 1 Spark staked
        uint256 annualRewardPerSpark = (1e18 * sparkRewardsPerBlock * blocksPerYear) / 1e18; // Scaled Spark rewards per year for 1 Spark
        // APY = (Annual Rewards / Initial Stake) * 10000 BPS
        return (annualRewardPerSpark * 10000) / 1e18; // Result in Basis Points
    }

     function getEssenceStakingAPY() external view returns (uint256) {
         if (totalStakedEssences == 0) return 0;
          uint256 blocksPerYear = 7200 * 365; // Approx based on 12s block time
         // Calculate approximate annual rewards from 1 Essence staked
         uint256 annualRewardPerEssence = (essenceRewardsPerBlock * blocksPerYear); // Total Spark rewards per year for 1 Essence
          // APY = (Annual Reward Value in Spark / Value of Essence in Spark) * 10000 BPS
          // This requires knowing the value of an Essence. Let's assume a base value for calculation.
          // Example: Assume Essence is worth 10000 Spark for calculation purposes
          uint256 assumedEssenceValueInSpark = 10000e18; // 10000 Spark
         return (annualRewardPerEssence * 10000) / assumedEssenceValueInSpark; // Result in Basis Points
     }

    function getProposalDetails(uint256 _proposalId) external view returns (uint256 id, string memory description, address[] memory targetContracts, bytes[] memory calldatas, uint256 startBlock, uint256 endBlock, uint256 quorumThreshold, uint256 votesFor, uint256 votesAgainst, ProposalState state, uint256 executionBlock) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert TheForge__ProposalDoesNotExist();
         return (
             proposal.id,
             proposal.description,
             proposal.targetContracts,
             proposal.calldatas,
             proposal.startBlock,
             proposal.endBlock,
             proposal.quorumThreshold,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.state,
             proposal.executionBlock
         );
    }

    function getCurrentCultivationCost() external view returns (uint256) {
        return cultivationCost;
    }

    function getTotalStakedSpark() external view returns (uint256) {
        return totalStakedSpark;
    }

    function getTotalStakedEssences() external view returns (uint256) {
        return totalStakedEssences;
    }

    function isPaused() external view returns (bool) {
        return paused();
    }

    // Need to override Pausable _before enter/ _after leave if needed, or use whenNotPaused/whenPaused modifiers

    // Add missing helper mapping updates in staking functions
    // stakeSpark: No user-specific list needed for Spark
    // unstakeSpark: No user-specific list needed for Spark
    // stakeEssence:essenceStaker[_tokenId] = msg.sender; stakedEssencesByOwner[msg.sender].push(_tokenId);
    // unstakeEssence: Remove from stakedEssencesByOwner[originalStaker], delete essenceStaker[_tokenId], delete essenceStakes[_tokenId]


    // Let's refine stake/unstakeEssence and add the essenceStaker mapping logic

    // --- Refined Stake/Unstake Essence ---

    function stakeEssence(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (address(essenceNFT) == address(0)) revert TheForge__NotLinked();
        if (essenceNFT.ownerOf(_tokenId) != msg.sender) revert TheForge__NotTokenOwner();
        if (essenceStakes[_tokenId].startBlock > 0) revert TheForge__AlreadyStaked(); // Check if already staked

        // Transfer NFT to the contract
        essenceNFT.safeTransferFrom(msg.sender, address(this), _tokenId);

        essenceStakes[_tokenId] = EssenceStake({
            startBlock: block.number,
            rewardDebt: 0
        });
        essenceStaker[_tokenId] = msg.sender; // Store the staker address

        // Add token ID to user's staked list
        stakedEssencesByOwner[msg.sender].push(_tokenId);
        totalStakedEssences++;

        emit EssenceStaked(msg.sender, _tokenId);
    }

    function unstakeEssence(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (address(essenceNFT) == address(0)) revert TheForge__NotLinked();
        if (essenceNFT.ownerOf(_tokenId) != address(this)) revert TheForge__NFTNotStaked(); // Must be staked in this contract
        address originalStaker = essenceStaker[_tokenId];
        if (originalStaker == address(0) || originalStaker != msg.sender) revert TheForge__NFTNotStaked(); // Must be original staker

        _updateEssenceRewards(_tokenId); // Finalize rewards

        // Remove NFT from user's staked list (inefficient for large lists, consider linked list or mapping)
        uint256[] storage stakedList = stakedEssencesByOwner[originalStaker];
        bool found = false;
        for (uint i = 0; i < stakedList.length; i++) {
            if (stakedList[i] == _tokenId) {
                stakedList[i] = stakedList[stakedList.length - 1];
                stakedList.pop();
                found = true;
                break;
            }
        }
        if (!found) revert TheForge__NFTNotStaked(); // Should always be found here

        delete essenceStakes[_tokenId]; // Remove stake data
        delete essenceStaker[_tokenId]; // Remove staker mapping
        totalStakedEssences--;

        // Transfer NFT back to user
        essenceNFT.safeTransferFrom(address(this), originalStaker, _tokenId);

        emit EssenceUnstaked(originalStaker, _tokenId);
    }

    // Refine claimEssenceStakingRewards to use essenceStaker mapping
    function claimEssenceStakingRewards(uint256 _tokenId) external whenNotPaused nonReentrant {
         if (essenceStakes[_tokenId].startBlock == 0) revert TheForge__NFTNotStaked();
         address originalStaker = essenceStaker[_tokenId];
         if (originalStaker == address(0) || originalStaker != msg.sender) revert TheForge__NFTNotStaked(); // Must be original staker


         _updateEssenceRewards(_tokenId); // Calculate final pending rewards

         EssenceStake storage stake = essenceStakes[_tokenId];
         uint256 rewardsToClaim = stake.rewardDebt;
         if (rewardsToClaim == 0) return;

         stake.rewardDebt = 0; // Reset reward debt

         // Reward type for Essence staking (example: Spark)
         if (sparkToken.balanceOf(address(this)) < rewardsToClaim) {
              sparkToken.mint(msg.sender, rewardsToClaim); // Example using minting
         } else {
              sparkToken.safeTransfer(msg.sender, rewardsToClaim); // Example using transfer from balance
         }

         emit EssenceRewardsClaimed(msg.sender, _tokenId, rewardsToClaim);
     }
}
```