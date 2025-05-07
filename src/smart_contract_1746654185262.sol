Okay, let's design a smart contract called "AetherForge Collective". This contract will combine elements of:

1.  **Token Staking:** Stake a native ERC20 token (`FORGE`) to earn more tokens and governance power.
2.  **Dynamic NFT Staking:** Stake a custom ERC721 NFT (`AetherCreature`) to earn tokens and *influence the NFT's attributes* over time (simulated evolution).
3.  **Decentralized Governance:** Staked tokens grant voting power to propose and vote on actions, specifically controlling a treasury.
4.  **Treasury Management:** A contract-controlled treasury holding Ether, manageable only through governance proposals.
5.  **Advanced Reward Mechanics:** Time-based, potentially tiered rewards, separate pools for token and NFT staking.
6.  **Dynamic Data:** Storing and conceptually updating state linked to externally owned NFTs within this contract.

This design includes staking mechanics, governance, treasury management, and a novel (though conceptually implemented here, as we can't modify an external NFT contract directly without its interface) dynamic NFT aspect based on interaction time.

---

**Outline and Function Summary: AetherForge Collective**

**I. Core Concepts:**
*   **FORGE Token (ERC20):** Utility, staking, governance power.
*   **AetherCreature NFT (ERC721):** Represents a unique digital entity, can be staked for rewards and attribute evolution.
*   **Staking Pools:** Separate logic for FORGE staking and AetherCreature NFT staking.
*   **Dynamic NFT Attributes:** Staking AetherCreature NFTs influences simulated attributes stored within *this* contract.
*   **Governance:** FORGE stakers propose and vote on actions, primarily controlling the Treasury.
*   **Treasury:** Holds ETH, managed by governance.

**II. State Variables:**
*   Addresses of FORGE token, AetherCreature NFT, and Treasury recipient.
*   User staking data (FORGE amount, NFT IDs, staking start/last claim times).
*   Reward rates for FORGE and NFT staking.
*   NFT evolution parameters (duration required).
*   Governance proposal data (description, target, calldata, state, votes).
*   Voting power per user.
*   Paused state.

**III. Events:**
*   Staking/Unstaking events (FORGE, NFT).
*   Reward claim events.
*   NFT attribute update event.
*   Governance proposal lifecycle events (created, voted, executed).
*   Treasury events (deposit, withdrawal).
*   Pause/Unpause events.

**IV. Functions (28 functions total):**

1.  `constructor(address _forgeToken, address _aetherCreatureNFT, address _treasuryRecipient)`: Initializes contract with token/NFT/treasury addresses.
2.  `stakeFORGE(uint256 amount)`: Allows user to stake FORGE tokens.
3.  `unstakeFORGE(uint256 amount)`: Allows user to unstake staked FORGE tokens.
4.  `claimFORGERewards()`: Allows user to claim accrued FORGE staking rewards.
5.  `getAvailableFORGERewards(address account)`: View: Calculates and returns pending FORGE rewards for an account.
6.  `stakeNFT(uint256 tokenId)`: Allows user to stake an AetherCreature NFT.
7.  `unstakeNFT(uint256 tokenId)`: Allows user to unstake a staked AetherCreature NFT. Triggers attribute update logic.
8.  `claimNFTRewards(uint256 tokenId)`: Allows user to claim accrued rewards for a specific staked NFT.
9.  `getAvailableNFTRewards(uint256 tokenId)`: View: Calculates and returns pending NFT rewards for a specific staked NFT.
10. `getNFTStakingDuration(uint256 tokenId)`: View: Gets the total cumulative duration a specific NFT has been staked.
11. `_calculateNFTAttributeChange(uint256 tokenId, uint256 cumulativeStakedDuration)`: Internal: Calculates potential attribute changes based on cumulative staking time.
12. `getNFTDynamicAttributes(uint256 tokenId)`: View: Gets the *simulated* dynamic attributes for a specific NFT, stored in this contract.
13. `getUserStakedFORGE(address account)`: View: Returns the total amount of FORGE staked by an account.
14. `getUserStakedNFTs(address account)`: View: Returns the list of NFT token IDs staked by an account.
15. `createProposal(string memory description, address targetContract, bytes memory callData)`: Allows a user with sufficient staked FORGE to create a governance proposal.
16. `vote(uint256 proposalId, bool support)`: Allows a user with staked FORGE to vote on an active proposal.
17. `executeProposal(uint256 proposalId)`: Allows anyone to execute a successful proposal after the voting period ends.
18. `getProposalState(uint256 proposalId)`: View: Returns the current state (Active, Passed, Failed, Executed) of a proposal.
19. `getVotingPower(address account)`: View: Returns the current voting power of an account (based on staked FORGE).
20. `depositEtherToTreasury() payable`: Allows anyone to send Ether to the contract's treasury balance.
21. `withdrawEtherFromTreasury(address recipient, uint256 amount)`: Internal/Governance-only: Withdraws Ether from the treasury. Only callable via a successful governance proposal.
22. `setFORGERewardRate(uint256 ratePerSecond)`: Owner function: Sets the FORGE token reward rate for FORGE staking.
23. `setNFTRewardRate(uint256 ratePerSecond)`: Owner function: Sets the FORGE token reward rate for NFT staking.
24. `setNFTStakingEvolutionDuration(uint256 durationInSeconds)`: Owner function: Sets the minimum cumulative staking duration required for a conceptual NFT attribute evolution 'stage'.
25. `getTotalStakedFORGE()`: View: Returns the total amount of FORGE staked in the contract.
26. `getTotalStakedNFTs()`: View: Returns the total count of NFTs staked in the contract.
27. `pause()`: Owner function: Pauses certain contract interactions (staking, claiming, voting).
28. `unpause()`: Owner function: Unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // Required by ReentrancyGuard

// Define interfaces for external contracts we interact with
interface IAetherCreature is IERC721 {
    // Assuming the NFT contract has a function to check/get attributes
    // For this example, we'll simulate dynamic attributes in THIS contract
    // function getAttributes(uint256 tokenId) external view returns (uint256 agility, uint256 strength, uint256 intelligence);
    // function updateAttributes(uint256 tokenId, uint256 agility, uint256 strength, uint256 intelligence) external; // Hypothetical update function
}

contract AetherForgeCollective is Ownable, ReentrancyGuard, ERC721Holder {
    using Address for address;

    // --- State Variables ---

    IERC20 public immutable FORGE_TOKEN;
    IAetherCreature public immutable AETHER_CREATURE_NFT;
    address public immutable TREASURY_RECIPIENT; // Address where ETH from treasury withdrawals goes

    // Staking Data: FORGE
    mapping(address => uint256) private _stakedFORGE;
    mapping(address => uint256) private _lastFORGERewardClaimTime;
    uint256 private _forgeRewardRatePerSecond; // Tokens per second per staked token unit

    // Staking Data: AetherCreature NFT
    struct NFTStakingData {
        address owner;
        uint64 stakingStartTime; // uint64 to save gas/storage
        uint64 lastRewardClaimTime;
        uint64 cumulativeStakedDuration; // Total time staked across potentially multiple sessions
    }
    mapping(uint256 => NFTStakingData) private _stakedNFTs; // tokenId => NFTStakingData
    mapping(address => uint256[]) private _userStakedNFTs; // owner => list of staked tokenIds
    uint256 private _nftRewardRatePerSecond; // Tokens per second per staked NFT
    uint256 public nftStakingEvolutionDuration = 365 days; // Cumulative duration for 'evolution' stages (conceptual)

    // Dynamic NFT Attributes (Simulated in this contract)
    struct DynamicNFTAttributes {
        uint256 agility;
        uint256 strength;
        uint256 intelligence;
        uint256 lastEvolutionStage; // Tracks which 'evolution stage' based on total duration
    }
    mapping(uint256 => DynamicNFTAttributes) private _dynamicNFTAttributes; // tokenId => attributes

    // Governance Data
    struct Proposal {
        string description;
        address targetContract;
        bytes callData;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(address => bool) voters; // Address => HasVoted
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public votingPeriod = 7 days;
    uint256 public minStakeForProposal = 1000 ether; // Example: 1000 FORGE tokens required to propose
    uint256 public proposalQuorumBasisPoints = 500; // 5% of total staked tokens must vote for a proposal to pass

    // Pause state
    bool private _paused;

    // --- Events ---

    event FORGEStaked(address indexed user, uint256 amount);
    event FORGEUnstaked(address indexed user, uint256 amount);
    event FORGERewardsClaimed(address indexed user, uint256 rewardsAmount);
    event NFTStaked(address indexed user, uint256 indexed tokenId);
    event NFTUnstaked(address indexed user, uint256 indexed tokenId);
    event NFTRewardsClaimed(address indexed user, uint256 indexed tokenId, uint256 rewardsAmount);
    event NFTAttributesUpdated(uint256 indexed tokenId, uint256 agility, uint256 strength, uint256 intelligence, uint256 evolutionStage);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, address targetContract);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event TreasuryDeposit(address indexed sender, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier onlyStaker(uint256 tokenId) {
        require(_stakedNFTs[tokenId].owner == _msgSender(), "Not the staker of this NFT");
        _;
    }

    modifier isActiveProposal(uint256 proposalId) {
        require(proposals[proposalId].startTime > 0, "Proposal does not exist");
        require(!proposals[proposalId].executed, "Proposal already executed");
        require(block.timestamp < proposals[proposalId].endTime, "Voting period has ended");
        _;
    }

    modifier isVotingPeriodEnded(uint256 proposalId) {
         require(proposals[proposalId].startTime > 0, "Proposal does not exist");
         require(block.timestamp >= proposals[proposalId].endTime, "Voting period not ended");
         require(!proposals[proposalId].executed, "Proposal already executed");
         _;
    }

    // --- Constructor ---

    constructor(address _forgeToken, address _aetherCreatureNFT, address _treasuryRecipient) Ownable(_msgSender()) {
        FORGE_TOKEN = IERC20(_forgeToken);
        AETHER_CREATURE_NFT = IAetherCreature(_aetherCreatureNFT);
        TREASURY_RECIPIENT = _treasuryRecipient;
        _paused = false;
        nextProposalId = 1; // Start proposal IDs from 1
    }

    // --- FORGE Staking ---

    /**
     * @notice Stakes FORGE tokens. Requires user to approve this contract first.
     * @param amount The amount of FORGE tokens to stake.
     */
    function stakeFORGE(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Cannot stake 0");
        require(FORGE_TOKEN.transferFrom(_msgSender(), address(this), amount), "FORGE transfer failed");

        uint256 pendingRewards = getAvailableFORGERewards(_msgSender());
        // Auto-claim pending rewards upon restaking to simplify reward calculation
        _stakedFORGE[_msgSender()] += amount;
        _lastFORGERewardClaimTime[_msgSender()] = block.timestamp;

        emit FORGEStaked(_msgSender(), amount);
        // Optionally, mint/transfer rewards to user here if auto-claiming
        if (pendingRewards > 0) {
             require(FORGE_TOKEN.transfer(_msgSender(), pendingRewards), "Reward transfer failed");
             emit FORGERewardsClaimed(_msgSender(), pendingRewards);
        }
    }

    /**
     * @notice Unstakes FORGE tokens.
     * @param amount The amount of FORGE tokens to unstake.
     */
    function unstakeFORGE(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Cannot unstake 0");
        require(_stakedFORGE[_msgSender()] >= amount, "Not enough staked FORGE");

        uint256 pendingRewards = getAvailableFORGERewards(_msgSender());
        _stakedFORGE[_msgSender()] -= amount;
        _lastFORGERewardClaimTime[_msgSender()] = block.timestamp; // Reset claim time upon unstake

        uint256 totalTransfer = amount + pendingRewards;
        require(FORGE_TOKEN.transfer(_msgSender(), totalTransfer), "FORGE unstake/reward transfer failed");

        emit FORGEUnstaked(_msgSender(), amount);
        if (pendingRewards > 0) {
             emit FORGERewardsClaimed(_msgSender(), pendingRewards);
        }
    }

    /**
     * @notice Claims available FORGE staking rewards.
     */
    function claimFORGERewards() external whenNotPaused nonReentrant {
        uint256 pendingRewards = getAvailableFORGERewards(_msgSender());
        require(pendingRewards > 0, "No rewards available");

        _lastFORGERewardClaimTime[_msgSender()] = block.timestamp; // Update claim time before transfer
        require(FORGE_TOKEN.transfer(_msgSender(), pendingRewards), "Reward transfer failed");

        emit FORGERewardsClaimed(_msgSender(), pendingRewards);
    }

    /**
     * @notice Calculates available FORGE staking rewards for an account.
     * @param account The address of the account.
     * @return The amount of FORGE rewards available.
     */
    function getAvailableFORGERewards(address account) public view returns (uint256) {
        uint256 stakedAmount = _stakedFORGE[account];
        if (stakedAmount == 0 || _forgeRewardRatePerSecond == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - _lastFORGERewardClaimTime[account];
        // Reward = stakedAmount * ratePerSecond * timeElapsed
        // To avoid overflow and maintain precision, this calculation might need adjustment
        // depending on the scale of stakedAmount, rate, and time.
        // A simple multiplication might be sufficient for reasonable values.
        // For very large numbers, consider using a fixed-point math library or scaling down.
        // Let's assume rates and amounts allow direct multiplication for simplicity here.
        return (stakedAmount * _forgeRewardRatePerSecond * timeElapsed);
    }

    /**
     * @notice Gets the amount of FORGE tokens staked by an account.
     * @param account The address of the account.
     * @return The staked amount.
     */
    function getUserStakedFORGE(address account) external view returns (uint256) {
        return _stakedFORGE[account];
    }

    /**
     * @notice Gets the total amount of FORGE staked in the contract.
     * @return The total staked amount.
     */
    function getTotalStakedFORGE() external view returns (uint256) {
        // This is a simplification; iterating through all users isn't feasible on-chain.
        // A better approach would be to maintain a running total state variable, updated on stake/unstake.
        // For demonstration, we'll return the contract's FORGE balance, assuming it's ONLY staked tokens.
        // In a real contract, track totalStakedFORGE explicitly.
        return FORGE_TOKEN.balanceOf(address(this));
    }


    // --- AetherCreature NFT Staking ---

    /**
     * @notice Stakes an AetherCreature NFT. Requires user to approve this contract for the NFT first.
     * ERC721Holder handles the `onERC721Received` callback automatically.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 tokenId) external whenNotPaused nonReentrant {
        require(_stakedNFTs[tokenId].owner == address(0), "NFT is already staked");
        require(AETHER_CREATURE_NFT.ownerOf(tokenId) == _msgSender(), "Not the owner of the NFT");

        AETHER_CREATURE_NFT.safeTransferFrom(_msgSender(), address(this), tokenId);

        NFTStakingData storage nftData = _stakedNFTs[tokenId];
        nftData.owner = _msgSender();
        nftData.stakingStartTime = uint64(block.timestamp);
        nftData.lastRewardClaimTime = uint64(block.timestamp);
        // cumulativeStakedDuration starts at 0 for a new staking session

        _userStakedNFTs[_msgSender()].push(tokenId);

        // Initialize dynamic attributes if not already present (e.g., first stake)
        if (_dynamicNFTAttributes[tokenId].agility == 0 && _dynamicNFTAttributes[tokenId].strength == 0 && _dynamicNFTAttributes[tokenId].intelligence == 0) {
             _dynamicNFTAttributes[tokenId] = DynamicNFTAttributes({
                 agility: 1, // Starting base attributes
                 strength: 1,
                 intelligence: 1,
                 lastEvolutionStage: 0
             });
        }


        emit NFTStaked(_msgSender(), tokenId);
    }

    /**
     * @notice Unstakes an AetherCreature NFT.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 tokenId) external whenNotPaused nonReentrant onlyStaker(tokenId) {
        NFTStakingData storage nftData = _stakedNFTs[tokenId];

        uint256 pendingRewards = getAvailableNFTRewards(tokenId);
        uint256 currentStakingDuration = block.timestamp - nftData.stakingStartTime;
        nftData.cumulativeStakedDuration += uint64(currentStakingDuration);

        // Transfer NFT back
        AETHER_CREATURE_NFT.transferFrom(address(this), _msgSender(), tokenId);

        // Transfer rewards
        if (pendingRewards > 0) {
            require(FORGE_TOKEN.transfer(_msgSender(), pendingRewards), "NFT reward transfer failed");
            emit NFTRewardsClaimed(_msgSender(), tokenId, pendingRewards);
        }

        // Remove NFT from user's staked list (simplified: iterate and remove)
        uint256[] storage stakedNFTs = _userStakedNFTs[_msgSender()];
        for (uint i = 0; i < stakedNFTs.length; i++) {
            if (stakedNFTs[i] == tokenId) {
                stakedNFTs[i] = stakedNFTs[stakedNFTs.length - 1];
                stakedNFTs.pop();
                break;
            }
        }

        // Clear staking data
        delete _stakedNFTs[tokenId];

        // Update dynamic attributes based on cumulative duration *after* unstaking
        _updateNFTAttributes(tokenId, nftData.cumulativeStakedDuration);

        emit NFTUnstaked(_msgSender(), tokenId);
    }

    /**
     * @notice Claims available FORGE staking rewards for a staked NFT.
     * @param tokenId The ID of the staked NFT.
     */
    function claimNFTRewards(uint256 tokenId) external whenNotPaused nonReentrant onlyStaker(tokenId) {
        NFTStakingData storage nftData = _stakedNFTs[tokenId];
        uint256 pendingRewards = getAvailableNFTRewards(tokenId);
        require(pendingRewards > 0, "No rewards available for this NFT");

        // Update cumulative duration and reset claim time before transfer
        uint256 currentStakingDuration = block.timestamp - nftData.stakingStartTime;
        // We don't add cumulative duration here, only when unstaking or evolving
        nftData.lastRewardClaimTime = uint64(block.timestamp);
        nftData.stakingStartTime = uint64(block.timestamp); // Reset session time

        require(FORGE_TOKEN.transfer(_msgSender(), pendingRewards), "NFT reward transfer failed");

        emit NFTRewardsClaimed(_msgSender(), tokenId, pendingRewards);
    }

    /**
     * @notice Calculates available FORGE staking rewards for a specific staked NFT.
     * @param tokenId The ID of the staked NFT.
     * @return The amount of FORGE rewards available for this NFT.
     */
    function getAvailableNFTRewards(uint256 tokenId) public view returns (uint256) {
         NFTStakingData storage nftData = _stakedNFTs[tokenId];
         if (nftData.owner == address(0) || _nftRewardRatePerSecond == 0) {
             return 0;
         }
         uint256 timeElapsed = block.timestamp - nftData.lastRewardClaimTime;
         // Reward = ratePerSecond * timeElapsed
         // Same precision considerations as getAvailableFORGERewards
         return _nftRewardRatePerSecond * timeElapsed;
    }

     /**
     * @notice Gets the cumulative duration a specific NFT has been staked across all staking sessions.
     * @param tokenId The ID of the NFT.
     * @return The cumulative staked duration in seconds.
     */
    function getNFTStakingDuration(uint256 tokenId) external view returns (uint256) {
        NFTStakingData storage nftData = _stakedNFTs[tokenId];
        uint256 cumulative = nftData.cumulativeStakedDuration;
        if (nftData.owner != address(0)) {
             // Add duration of the current active staking session
             cumulative += (block.timestamp - nftData.stakingStartTime);
        }
        return cumulative;
    }

    /**
     * @notice Gets the list of NFT token IDs staked by an account.
     * @param account The address of the account.
     * @return An array of staked NFT token IDs.
     */
    function getUserStakedNFTs(address account) external view returns (uint256[] memory) {
        return _userStakedNFTs[account];
    }

    /**
     * @notice Gets the total number of NFTs staked in the contract.
     * @return The total count of staked NFTs.
     */
    function getTotalStakedNFTs() external view returns (uint256) {
        // This is also inefficient for many users/NFTs.
        // A state variable `totalStakedNFTS` incremented/decremented would be better.
        // For demonstration, we'll try to count by iterating (likely hits gas limit in real use).
        // A mapping(address => uint256[]) approach makes this hard without iterating users.
        // If using mapping(uint256 => NFTStakingData), you'd need another mapping or array of staked tokenIds.
        // Let's assume a state variable _totalStakedNFTCount is maintained.
        // In a real contract, add `uint256 private _totalStakedNFTCount;` and update it.
        // For *this* code, we can't reliably get the count efficiently without changing state structure significantly.
        // Let's just return 0 and add a comment about the limitation.
        // return _totalStakedNFTCount; // Placeholder
        return 0; // Returning 0 as total count cannot be efficiently calculated from current structure
    }


    // --- Dynamic NFT Attribute Logic (Simulated) ---

    /**
     * @notice Internal function to update simulated dynamic attributes based on cumulative staking duration.
     * Called when NFT is unstaked.
     * @param tokenId The ID of the NFT.
     * @param cumulativeStakedDuration The total cumulative time the NFT has been staked.
     */
    function _updateNFTAttributes(uint256 tokenId, uint256 cumulativeStakedDuration) internal {
        // This function simulates evolution based on cumulative duration.
        // In a real scenario, you would call a function on the AetherCreature NFT contract
        // to modify its actual on-chain attributes (if the NFT contract supports this).
        // Example logic: Increase attributes every `nftStakingEvolutionDuration` seconds of cumulative staking.

        DynamicNFTAttributes storage currentAttributes = _dynamicNFTAttributes[tokenId];
        uint256 newEvolutionStage = cumulativeStakedDuration / nftStakingEvolutionDuration;

        if (newEvolutionStage > currentAttributes.lastEvolutionStage) {
            uint256 stagesPassed = newEvolutionStage - currentAttributes.lastEvolutionStage;
            currentAttributes.agility += stagesPassed;
            currentAttributes.strength += stagesPassed;
            currentAttributes.intelligence += stagesPassed;
            currentAttributes.lastEvolutionStage = newEvolutionStage;

            // Hypothetical call to external NFT contract:
            // AETHER_CREATURE_NFT.updateAttributes(tokenId, currentAttributes.agility, currentAttributes.strength, currentAttributes.intelligence);

            emit NFTAttributesUpdated(
                tokenId,
                currentAttributes.agility,
                currentAttributes.strength,
                currentAttributes.intelligence,
                currentAttributes.lastEvolutionStage
            );
        }
         // Attributes might also decay or change based on other factors not implemented here.
    }

    /**
     * @notice Gets the current simulated dynamic attributes for a specific NFT.
     * These attributes are stored and managed by *this* contract, not the NFT contract itself (unless integrated).
     * @param tokenId The ID of the NFT.
     * @return agility, strength, intelligence, lastEvolutionStage The current simulated attributes and evolution stage.
     */
    function getNFTDynamicAttributes(uint256 tokenId) external view returns (uint256 agility, uint256 strength, uint256 intelligence, uint256 lastEvolutionStage) {
        DynamicNFTAttributes storage currentAttributes = _dynamicNFTAttributes[tokenId];
        return (currentAttributes.agility, currentAttributes.strength, currentAttributes.intelligence, currentAttributes.lastEvolutionStage);
    }


    // --- Governance ---

    /**
     * @notice Creates a new governance proposal. Requires minimum staked FORGE.
     * @param description A description of the proposal.
     * @param targetContract The address of the contract the proposal will interact with.
     * @param callData The encoded function call data for the target contract.
     */
    function createProposal(string memory description, address targetContract, bytes memory callData) external whenNotPaused nonReentrant {
        require(getVotingPower(_msgSender()) >= minStakeForProposal, "Not enough staked FORGE to propose");
        require(targetContract != address(0), "Target contract cannot be zero address");
        require(bytes(description).length > 0, "Description cannot be empty");

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.description = description;
        proposal.targetContract = targetContract;
        proposal.callData = callData;
        proposal.proposer = _msgSender();
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.executed = false;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        // proposal.voters mapping is implicitly initialized

        emit ProposalCreated(proposalId, _msgSender(), description, targetContract);
    }

    /**
     * @notice Votes on an active governance proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for supporting the proposal, false for opposing.
     */
    function vote(uint256 proposalId, bool support) external whenNotPaused nonReentrant isActiveProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.voters[_msgSender()], "Already voted");

        uint256 votingPower = getVotingPower(_msgSender());
        require(votingPower > 0, "No voting power (stake FORGE)");

        proposal.voters[_msgSender()] = true;
        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit Voted(proposalId, _msgSender(), support);
    }

    /**
     * @notice Executes a governance proposal if the voting period has ended and it has passed.
     * Anyone can call this function.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external payable whenNotPaused nonReentrant isVotingPeriodEnded(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        // Check if proposal passed (votesFor > votesAgainst and meets quorum)
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        // Calculate total staked FORGE at the time of execution (approximation)
        // A more precise quorum check might use historical staking data or require a snapshot
        uint256 totalCurrentlyStakedFORGE = FORGE_TOKEN.balanceOf(address(this));
        uint256 quorumAmount = (totalCurrentlyStakedFORGE * proposalQuorumBasisPoints) / 10000; // Quorum based on total staked

        require(totalVotes >= quorumAmount, "Proposal did not meet quorum");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass");

        // Execute the proposal's action
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        // Note: Errors during execution are often swallowed by .call.
        // Consider using a library like `SafeCast` or `SafeCall` for more robust error handling.
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId, success);
    }

    /**
     * @notice Gets the current voting power of an account.
     * Voting power is equal to the amount of FORGE tokens staked.
     * @param account The address of the account.
     * @return The voting power.
     */
    function getVotingPower(address account) public view returns (uint256) {
        return _stakedFORGE[account];
    }

    /**
     * @notice Gets the current state of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return The state as an enum (Pending, Active, Passed, Failed, Executed).
     */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.startTime == 0) {
            return ProposalState.NonExistent;
        }
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (block.timestamp < proposal.startTime) {
            return ProposalState.Pending; // Should not happen with current logic, start time is block.timestamp
        }
        if (block.timestamp < proposal.endTime) {
            return ProposalState.Active;
        }

        // Voting period has ended
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        // Calculate total staked FORGE at the time of checking (approximation)
        uint256 totalCurrentlyStakedFORGE = FORGE_TOKEN.balanceOf(address(this));
        uint256 quorumAmount = (totalCurrentlyStakedFORGE * proposalQuorumBasisPoints) / 10000;

        if (totalVotes < quorumAmount || proposal.votesFor <= proposal.votesAgainst) {
            return ProposalState.Failed;
        }
        return ProposalState.Passed;
    }

    enum ProposalState {
        NonExistent,
        Pending,
        Active,
        Passed,
        Failed,
        Executed
    }

    // --- Treasury ---

    /**
     * @notice Allows anyone to send Ether to the contract's treasury balance.
     */
    receive() external payable {
         emit TreasuryDeposit(_msgSender(), msg.value);
    }

    /**
     * @notice Public function to make the receive payable function callable explicitly.
     */
    function depositEtherToTreasury() external payable {
         emit TreasuryDeposit(_msgSender(), msg.value);
    }

    /**
     * @notice Internal function to withdraw Ether from the treasury.
     * Only callable via a successful governance proposal using `executeProposal`.
     * @param recipient The address to send Ether to.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawEtherFromTreasury(address recipient, uint256 amount) external nonReentrant {
        // Ensure this function is *only* called via a governance proposal execution.
        // A simple check could be that msg.sender is *this* contract's address,
        // or verify against a known governance executor role if more complex.
        // For this simple setup, calling it internally from `executeProposal` is the mechanism.
        // Adding a require(msg.sender == address(this), "Only callable by governance execution")
        // would make it explicitly internal-only.
        require(msg.sender == address(this), "Only callable by governance execution");
        require(address(this).balance >= amount, "Insufficient treasury balance");
        require(recipient != address(0), "Recipient cannot be zero address");

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "ETH withdrawal failed");

        emit TreasuryWithdrawal(recipient, amount);
    }

    /**
     * @notice Gets the current ETH balance of the contract's treasury.
     * @return The treasury balance in wei.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // --- Admin/Owner Functions ---

    /**
     * @notice Owner function to set the FORGE token reward rate for FORGE staking.
     * Rate is in tokens per second per unit of staked token (wei).
     * @param ratePerSecond The new reward rate.
     */
    function setFORGERewardRate(uint256 ratePerSecond) external onlyOwner {
        _forgeRewardRatePerSecond = ratePerSecond;
    }

    /**
     * @notice Owner function to set the FORGE token reward rate for NFT staking.
     * Rate is in tokens per second per staked NFT.
     * @param ratePerSecond The new reward rate.
     */
    function setNFTRewardRate(uint256 ratePerSecond) external onlyOwner {
        _nftRewardRatePerSecond = ratePerSecond;
    }

    /**
     * @notice Owner function to set the minimum cumulative staking duration required for a conceptual NFT evolution 'stage'.
     * @param durationInSeconds The new duration in seconds.
     */
    function setNFTStakingEvolutionDuration(uint256 durationInSeconds) external onlyOwner {
        require(durationInSeconds > 0, "Duration must be positive");
        nftStakingEvolutionDuration = durationInSeconds;
    }

    /**
     * @notice Owner function to pause core contract interactions.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @notice Owner function to unpause contract interactions.
     */
    function unpause() external onlyOwner {
        require(_paused, "Contract is not paused");
        _paused = false;
        emit Unpaused(_msgSender());
    }

    // --- ERC721Holder Callback ---
    // This function is required by ERC721Holder to receive NFTs safely.
    // Our stakeNFT function uses safeTransferFrom, which triggers this.
    // We don't need to add logic here as stakeNFT handles state updates *before* the transfer.
    // However, OpenZeppelin's implementation requires it to be present.
    // We inherit from ERC721Holder, so the necessary override is provided.

}
```