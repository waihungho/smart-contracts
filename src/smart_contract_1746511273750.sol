Okay, here is a Solidity smart contract concept called "AethelForge" that incorporates several advanced, creative, and trendy concepts like dynamic NFTs, on-chain components, decentralized governance (DAO), staking with integrated reputation, and custom licensing.

This contract is designed as a conceptual framework. Implementing all features securely and efficiently for production would require significant auditing, gas optimization, and potentially integrating external services (like oracles for complex conditions, or IPFS for metadata).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
Outline and Function Summary:

Project Title: AethelForge - Decentralized Creative & Evolutionary Asset Platform

Concept:
AethalForge is a platform for forging, evolving, and governing unique digital assets (Items, represented as ERC721 NFTs) built from fundamental on-chain components (represented as ERC1155 tokens). The platform is governed by holders of a native ERC20 token, who can stake their tokens to gain voting power and earn rewards. A reputation system influences voting weight and access to certain features. Items can have custom on-chain licenses defined by their owners and approved by the community/governance.

Key Features:
1.  Dynamic NFTs (Items): NFTs (ERC721) whose properties (stored on-chain via components) can change.
2.  On-chain Components (Materials): Fungible/Semi-fungible tokens (ERC1155) required to forge and evolve Items.
3.  Decentralized Governance (DAO): Token-weighted voting on proposals to change parameters, mint components, reward users, etc.
4.  Staking Rewards: Users stake governance tokens to earn yield and voting power.
5.  Reputation System: An on-chain score influencing voting power and potentially future feature access. Reputation can be earned via participation (voting, staking, successful forging) or awarded by governance.
6.  Custom Licensing: Owners can propose and define on-chain usage licenses for their NFTs.

Outline:
1.  Interfaces (Assumed ERC20, ERC721, ERC1155)
2.  Error Definitions
3.  Struct Definitions (Item, ComponentType, Proposal, Stake, License)
4.  State Variables (Core mappings, counters, contract addresses, global params)
5.  Events
6.  Modifiers (e.g., onlyGovernance)
7.  Core AethelForge Logic (Forging, Evolving, Dismantling Items)
8.  Component Management
9.  Governance (Proposals, Voting, Execution)
10. Staking & Rewards
11. Reputation Management
12. Licensing
13. View Functions

Function Summary:

Core AethelForge Logic:
1.  `forgeItem(uint256[] calldata componentTypeIds, uint256[] calldata amounts)`: Creates a new ERC721 Item NFT by consuming specified ERC1155 Components.
2.  `evolveItem(uint256 itemId, uint256[] calldata componentTypeIds, uint256[] calldata amounts)`: Modifies an existing ERC721 Item NFT by consuming additional ERC1155 Components, altering its on-chain properties (simulated).
3.  `dismantleItem(uint256 itemId)`: Destroys an ERC721 Item NFT and returns a portion of the consumed ERC1155 Components to the owner.

Component Management:
4.  `mintComponents(uint256 componentTypeId, uint256 amount)`: Mints new ERC1155 Components of a specific type (only callable via governance).
5.  `burnComponents(uint256 componentTypeId, uint256 amount)`: Burns ERC1155 Components of a specific type (can be user or governance initiated).

Governance:
6.  `propose(string memory description, address target, bytes calldata callData)`: Creates a new governance proposal. Requires staked tokens.
7.  `vote(uint256 proposalId, bool support)`: Casts a vote on an active proposal. Voting power is based on staked tokens and reputation.
8.  `executeProposal(uint256 proposalId)`: Executes a passed governance proposal.
9.  `cancelProposal(uint256 proposalId)`: Allows the proposer to cancel their proposal if it hasn't started or failed.

Staking & Rewards:
10. `stake(uint256 amount)`: Stakes governance tokens to gain voting power and earn rewards.
11. `unstake(uint256 amount)`: Unstakes governance tokens. May have a time lock (simulated).
12. `claimRewards()`: Claims accumulated staking rewards. Reward logic is simplified for this example.

Reputation Management:
13. `getReputation(address user)`: Gets the reputation score of a user.
14. `awardReputation(address user, uint256 amount)`: Awards reputation points to a user (only callable via governance).
15. `deductReputation(address user, uint256 amount)`: Deducts reputation points from a user (only callable via governance).

Licensing:
16. `proposeItemLicense(uint256 itemId, string memory licenseUri)`: Proposes a new license URI for an Item (requires Item ownership). This proposal needs to be voted on via governance.
17. `setItemLicense(uint256 itemId, string memory licenseUri)`: Sets the license URI for an Item (only callable via governance after license proposal passes).
18. `getItemLicense(uint256 itemId)`: Gets the current license URI for an Item.

View Functions:
19. `getProposalState(uint256 proposalId)`: Gets the current state of a governance proposal.
20. `getVotingPower(address user)`: Calculates and returns the current voting power of a user (based on stake and reputation).
21. `getItemComponents(uint256 itemId)`: Returns the Component types and amounts embedded in an Item.
22. `getComponentBalance(address user, uint256 componentTypeId)`: Gets a user's balance of a specific Component type (wraps ERC1155 balance).
23. `getStakeBalance(address user)`: Gets a user's staked amount.
24. `getTotalStaked()`: Gets the total amount of tokens staked in the contract.
25. `getGlobalParameters()`: Returns the current global governance/platform parameters.
26. `getNextItemId()`: Returns the ID that will be assigned to the next forged Item.
27. `getNextComponentTypeId()`: Returns the ID that will be assigned to the next registered Component type.
28. `getComponentTypeDetails(uint256 componentTypeId)`: Returns details about a specific Component type.
29. `getItemDetails(uint256 itemId)`: Returns key details about an Item (owner, components, license).

Note: This contract provides the structure and function signatures with basic logic. Real-world implementation requires robust error handling, gas optimizations, security checks, and integration with actual ERC interfaces/libraries. The reward calculation, governance execution (`call`), and detailed reputation logic are simplified.
*/

// Assume interfaces for ERC20, ERC721, ERC1155 are available globally or imported
// interface IERC20 { ... }
// interface IERC721 { ... }
// interface IERC1155 { ... }

contract AethelForge {

    // --- 2. Error Definitions ---
    error NotItemOwner();
    error InvalidComponentAmounts();
    error InsufficientComponents();
    error ItemAlreadyEvolved(); // Example for dynamic evolution constraints
    error ProposalNotFound();
    error ProposalNotInVotingPeriod();
    error ProposalAlreadyVoted();
    error ProposalNotExecutable();
    error ProposalNotCancellable();
    error InsufficientStake();
    error ZeroAmount();
    error Unauthorized(); // For governance protected functions
    error NoRewardsToClaim();
    error ItemNotFound();
    error ComponentTypeNotFound();
    error LicenseNotProposed(); // If trying to set license directly

    // --- 3. Struct Definitions ---

    struct Item {
        address creator;
        mapping(uint256 componentTypeId => uint256 amount) components; // On-chain components embedded in the item
        string licenseUri; // URI pointing to the license details
        bool evolved; // Example of a dynamic state flag
        // Add other dynamic properties here
    }

    struct ComponentType {
        string name;
        string uri; // URI for metadata/image
        uint256 forgeCostMultiplier; // How much this component affects forge cost (simulated)
        uint256 dismantleReturnPercentage; // What % of this component is returned on dismantle (simulated)
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    struct Proposal {
        address proposer;
        string description;
        address target; // Contract address for execution
        bytes callData; // Calldata for execution
        uint256 voteStart; // Timestamp
        uint256 voteEnd;   // Timestamp
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address voter => bool hasVoted) voters;
        ProposalState state;
        string licenseUri; // Used specifically for license proposals
        uint256 itemId; // Used specifically for license proposals
    }

    struct Stake {
        uint256 amount;
        uint256 lastClaimTimestamp;
        // Potentially add reward tracking fields (e.g., uint256 rewardDebt)
    }

    struct GlobalParameters {
        uint256 minStakeToPropose;
        uint256 votingPeriodDuration; // in seconds
        uint256 executionDelay; // in seconds after proposal succeeds
        uint256 baseReputationVotingBoost; // Flat reputation boost
        uint256 reputationStakeMultiplier; // Reputation multiplier for voting power
        uint256 dismantlePenaltyPercentage; // Global penalty on component return
        address governanceTokenAddress;
        address componentTokenAddress; // Assuming ERC1155 contract address
        address itemTokenAddress; // Assuming ERC721 contract address
        uint256 stakingRewardRate; // Simplified: rewards per staked token per second (conceptual)
    }

    // --- 4. State Variables ---

    // Core Storage
    mapping(uint256 => Item) private items;
    mapping(uint256 => ComponentType) private componentTypes;
    mapping(address => Stake) private userStakes;
    mapping(uint256 => Proposal) private proposals;
    mapping(address => uint256) private userReputation;

    // Counters
    uint256 private nextItemId = 1;
    uint256 private nextComponentTypeId = 1;
    uint256 private nextProposalId = 1;

    // Global State
    GlobalParameters public globalParams;
    uint256 private totalStakedAmount = 0;

    // --- 5. Events ---

    event ItemForged(uint256 indexed itemId, address indexed creator, uint256[] componentTypeIds, uint256[] amounts);
    event ItemEvolved(uint256 indexed itemId, address indexed owner, uint256[] componentTypeIds, uint256[] amounts);
    event ItemDismantled(uint256 indexed itemId, address indexed owner);
    event ComponentsMinted(uint256 indexed componentTypeId, uint256 amount);
    event ComponentsBurned(uint256 indexed componentTypeId, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    event ReputationAwarded(address indexed user, uint256 amount);
    event ReputationDeducted(address indexed user, uint256 amount);

    event LicenseProposed(uint256 indexed itemId, uint256 indexed proposalId, string licenseUri);
    event LicenseSet(uint256 indexed itemId, string licenseUri);

    // --- 6. Modifiers ---

    modifier onlyGovernance() {
        // In a real DAO, this would check if the call originates from a passed proposal's execution
        // For this example, we'll use a simplified check or assume it's only called internally via executeProposal
        // A more robust check would involve verifying msg.sender against a governance executor address
        // or checking a specific flag set during execution.
        // For now, we'll leave this as a placeholder or make functions internal that are only called by executeProposal.
        _;
    }

    modifier isItemOwner(uint256 itemId) {
        // Assumes ERC721 contract allows checking owner.
        // IERC721 itemToken = IERC721(globalParams.itemTokenAddress);
        // require(itemToken.ownerOf(itemId) == msg.sender, "Not item owner");
        // Placeholder: assume owner check passes
        _;
    }

    // Constructor - Sets initial parameters and token addresses
    constructor(
        uint256 _minStakeToPropose,
        uint256 _votingPeriodDuration,
        uint256 _executionDelay,
        uint256 _baseReputationVotingBoost,
        uint256 _reputationStakeMultiplier,
        uint256 _dismantlePenaltyPercentage,
        address _governanceTokenAddress,
        address _componentTokenAddress,
        address _itemTokenAddress, // Address of the ERC721 contract
        uint256 _stakingRewardRate
    ) {
        globalParams = GlobalParameters({
            minStakeToPropose: _minStakeToPropose,
            votingPeriodDuration: _votingPeriodDuration,
            executionDelay: _executionDelay,
            baseReputationVotingBoost: _baseReputationVotingBoost,
            reputationStakeMultiplier: _reputationStakeMultiplier,
            dismantlePenaltyPercentage: _dismantlePenaltyPercentage,
            governanceTokenAddress: _governanceTokenAddress,
            componentTokenAddress: _componentTokenAddress,
            itemTokenAddress: _itemTokenAddress,
            stakingRewardRate: _stakingRewardRate
        });

        // In a real scenario, you'd likely want to call functions on the token addresses
        // to ensure they are valid contracts or set approvals.
    }

    // --- 7. Core AethelForge Logic ---

    // 1. forgeItem: Create a new Item NFT by consuming Components
    function forgeItem(uint256[] calldata componentTypeIds, uint256[] calldata amounts) external {
        if (componentTypeIds.length == 0 || componentTypeIds.length != amounts.length) {
            revert InvalidComponentAmounts();
        }

        // Check if user has enough components and burn them (ERC1155 standard call)
        // IERC1155 componentToken = IERC1155(globalParams.componentTokenAddress);
        // componentToken.safeBatchTransferFrom(msg.sender, address(this), componentTypeIds, amounts, "");
        // Placeholder: simulate burn
         for(uint i=0; i < componentTypeIds.length; i++) {
             // require(componentToken.balanceOf(msg.sender, componentTypeIds[i]) >= amounts[i], InsufficientComponents());
             // componentToken.burn(msg.sender, componentTypeIds[i], amounts[i]); // Or safeTransferFrom to address(0)
         }


        uint256 newItemId = nextItemId++;
        items[newItemId].creator = msg.sender;
        items[newItemId].evolved = false; // Initial state

        // Store components used on-chain (simplified, real dynamic logic is complex)
        for (uint i = 0; i < componentTypeIds.length; i++) {
            items[newItemId].components[componentTypeIds[i]] += amounts[i];
            // Potentially calculate forge cost/complexity based on components
            // uint256 componentCost = componentTypes[componentTypeIds[i]].forgeCostMultiplier * amounts[i];
            // Total forge cost...
        }

        // Mint the ERC721 Item (standard call)
        // IERC721 itemToken = IERC721(globalParams.itemTokenAddress);
        // itemToken.safeMint(msg.sender, newItemId); // Assuming a mint function exists

        emit ItemForged(newItemId, msg.sender, componentTypeIds, amounts);

        // Reward creator reputation (simplified)
        userReputation[msg.sender] += 10; // Example reputation gain
    }

    // 2. evolveItem: Modify an existing Item NFT by consuming more Components
    function evolveItem(uint256 itemId, uint256[] calldata componentTypeIds, uint256[] calldata amounts)
        external
        isItemOwner(itemId) // Check ownership via modifier (conceptual)
    {
        if (componentTypeIds.length == 0 || componentTypeIds.length != amounts.length) {
            revert InvalidComponentAmounts();
        }
        // Example: Prevent multiple evolutions
        // if (items[itemId].evolved) {
        //     revert ItemAlreadyEvolved();
        // }

        // Check if user has enough components and burn them (ERC1155 standard call)
        // IERC1155 componentToken = IERC1155(globalParams.componentTokenAddress);
        // componentToken.safeBatchTransferFrom(msg.sender, address(this), componentTypeIds, amounts, "");
         for(uint i=0; i < componentTypeIds.length; i++) {
             // require(componentToken.balanceOf(msg.sender, componentTypeIds[i]) >= amounts[i], InsufficientComponents());
             // componentToken.burn(msg.sender, componentTypeIds[i], amounts[i]); // Or safeTransferFrom to address(0)
         }


        // Update on-chain components embedded in the item
        for (uint i = 0; i < componentTypeIds.length; i++) {
            items[itemId].components[componentTypeIds[i]] += amounts[i];
            // Logic to update item's dynamic properties based on new components
        }

        items[itemId].evolved = true; // Update dynamic state

        // Update Item URI (if metadata changes based on components - off-chain or on-chain generation needed)
        // Requires a mechanism to update the ERC721 tokenURI. Could be via ERC721Metadata or a custom function.

        emit ItemEvolved(itemId, msg.sender, componentTypeIds, amounts);

        // Reward owner reputation (simplified)
        userReputation[msg.sender] += 5; // Example reputation gain
    }

    // 3. dismantleItem: Destroy an Item NFT and return some Components
    function dismantleItem(uint256 itemId) external isItemOwner(itemId) {
        // Check if item exists (isItemOwner implies it's valid and owned by msg.sender)
        // If not using isItemOwner: require(items[itemId].creator != address(0), ItemNotFound());
        // require(IERC721(globalParams.itemTokenAddress).ownerOf(itemId) == msg.sender, NotItemOwner());

        // Calculate components to return
        uint256[] memory returnComponentTypeIds;
        uint256[] memory returnAmounts;
        uint256 returnCount = 0;

        // Determine how many unique component types are in the item
        for (uint256 typeId = 1; typeId < nextComponentTypeId; typeId++) {
            if (items[itemId].components[typeId] > 0) {
                 returnCount++;
            }
        }

        returnComponentTypeIds = new uint256[](returnCount);
        returnAmounts = new uint256[](returnCount);
        uint256 currentIndex = 0;

        for (uint256 typeId = 1; typeId < nextComponentTypeId; typeId++) {
             uint256 embeddedAmount = items[itemId].components[typeId];
             if (embeddedAmount > 0) {
                uint256 returnAmount = (embeddedAmount * componentTypes[typeId].dismantleReturnPercentage * (100 - globalParams.dismantlePenaltyPercentage)) / 10000; // % of %
                returnComponentTypeIds[currentIndex] = typeId;
                returnAmounts[currentIndex] = returnAmount;
                currentIndex++;
             }
        }

        // Burn the ERC721 Item (standard call)
        // IERC721 itemToken = IERC721(globalParams.itemTokenAddress);
        // itemToken.burn(itemId); // Assuming a burn function exists

        // Transfer components back to the owner (ERC1155 standard call)
        if (returnCount > 0) {
            // IERC1155 componentToken = IERC1155(globalParams.componentTokenAddress);
            // componentToken.safeBatchTransferFrom(address(this), msg.sender, returnComponentTypeIds, returnAmounts, "");
            // Placeholder: simulate transfer back
        }

        // Clear item state (important for preventing re-dismantle)
        // Note: clearing mappings is gas expensive. A better approach might be to mark as dismantled.
        delete items[itemId]; // This is okay if it's the last state change

        emit ItemDismantled(itemId, msg.sender);
    }

    // --- 8. Component Management ---

    // 4. mintComponents: Mint new Components (only via Governance execution)
    function mintComponents(uint256 componentTypeId, uint256 amount) external onlyGovernance {
        if (amount == 0) revert ZeroAmount();
        if (componentTypes[componentTypeId].forgeCostMultiplier == 0) revert ComponentTypeNotFound(); // Check if type exists

        // Perform ERC1155 mint (standard call)
        // IERC1155 componentToken = IERC1155(globalParams.componentTokenAddress);
        // componentToken.mint(address(this), componentTypeId, amount, ""); // Mint to contract or a distribution pool? Let's mint to contract then governance can distribute.

        emit ComponentsMinted(componentTypeId, amount);
    }

    // 5. burnComponents: Burn Components (can be user or via Governance)
    function burnComponents(uint256 componentTypeId, uint256 amount) external {
         if (amount == 0) revert ZeroAmount();
         if (componentTypes[componentTypeId].forgeCostMultiplier == 0) revert ComponentTypeNotFound();

         // Perform ERC1155 burn (standard call)
         // IERC1155 componentToken = IERC1155(globalParams.componentTokenAddress);
         // componentToken.burn(msg.sender, componentTypeId, amount); // User initiated burn

         emit ComponentsBurned(componentTypeId, amount);
    }

    // --- 9. Governance ---

    // 6. propose: Create a new governance proposal
    function propose(string memory description, address target, bytes calldata callData) external {
        if (userStakes[msg.sender].amount < globalParams.minStakeToPropose) {
            revert InsufficientStake();
        }

        uint256 proposalId = nextProposalId++;
        uint256 currentTime = block.timestamp;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: description,
            target: target,
            callData: callData,
            voteStart: currentTime,
            voteEnd: currentTime + globalParams.votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            voters: new mapping(address => bool), // This initializes the mapping
            state: ProposalState.Active,
            licenseUri: "", // Not a license proposal
            itemId: 0 // Not a license proposal
        });

        emit ProposalCreated(proposalId, msg.sender, description);

        // Award reputation for proposing
        userReputation[msg.sender] += 2;
    }

    // 7. vote: Cast a vote on an active proposal
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ProposalNotInVotingPeriod();
        if (proposal.voters[msg.sender]) revert ProposalAlreadyVoted();
        if (block.timestamp > proposal.voteEnd) revert ProposalNotInVotingPeriod();

        uint256 votingPower = getVotingPower(msg.sender);
        if (votingPower == 0) revert InsufficientStake(); // Or maybe a specific error like NoVotingPower()

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.voters[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, votingPower);

        // Award reputation for voting
        userReputation[msg.sender] += 1; // Example: flat reward per vote
    }

    // 8. executeProposal: Execute a passed governance proposal
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.state != ProposalState.Succeeded) revert ProposalNotExecutable();
        if (block.timestamp < proposal.voteEnd + globalParams.executionDelay) {
             // Allow execution only after delay IF it succeeded
             // If state was set to Succeeded immediately after vote end, this check is needed.
             // Or the state transition to Succeeded happens only after the delay. Let's assume state transition happens after vote end.
             // Re-check state based on current time if needed.
             if (block.timestamp < proposal.voteEnd || proposal.votesFor <= proposal.votesAgainst) {
                  revert ProposalNotExecutable(); // State was set prematurely or conditions changed
             }
        }


        proposal.state = ProposalState.Executing; // Mark as executing

        // --- Execution Logic ---
        bool success;
        // If the proposal was a license proposal, set the license directly
        if (proposal.itemId != 0 && bytes(proposal.licenseUri).length > 0) {
             // Ensure this was triggered by the correct governance proposal
             // Call the internal set function
             _setItemLicense(proposal.itemId, proposal.licenseUri);
             success = true;
        } else {
             // Execute generic target/callData proposal
             (success, ) = proposal.target.call(proposal.callData);
        }


        if (success) {
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(proposalId);
            // Maybe award reputation to proposer/voters?
        } else {
            // Handle execution failure - set state to failed/vetoed?
            // For simplicity, let's revert if execution fails in this example.
             // Reverting inside `call` will cause this `executeProposal` transaction to revert.
             // A more complex DAO might catch the revert and mark the proposal state as failed execution.
            revert("Proposal execution failed");
        }
    }

     // Internal function called by executeProposal for license setting
    function _setItemLicense(uint256 itemId, string memory licenseUri) internal onlyGovernance {
        // This internal function assumes the 'onlyGovernance' modifier is effective
        // and the call originated from a valid, passed proposal execution.
        if (items[itemId].creator == address(0)) revert ItemNotFound(); // Ensure item exists

        items[itemId].licenseUri = licenseUri;
        emit LicenseSet(itemId, licenseUri);
    }


    // 9. cancelProposal: Allow proposer to cancel before voting starts or if failed
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.proposer != msg.sender) revert Unauthorized();
        // Only allow cancellation if pending, or maybe if active but no votes yet, or if already failed/defeated
        if (proposal.state != ProposalState.Pending && proposal.state != ProposalState.Defeated) {
             revert ProposalNotCancellable();
        }
         // Further check: if state is Active, check if votesFor + votesAgainst == 0
         if (proposal.state == ProposalState.Active && (proposal.votesFor > 0 || proposal.votesAgainst > 0)) {
             revert ProposalNotCancellable(); // Already received votes
         }

        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(proposalId);
    }


    // --- 10. Staking & Rewards ---

    // 10. stake: Stake governance tokens
    function stake(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        // Transfer tokens from user to contract (ERC20 standard call)
        // IERC20 governanceToken = IERC20(globalParams.governanceTokenAddress);
        // require(governanceToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        // Placeholder: simulate transfer
        // require(governanceToken.balanceOf(msg.sender) >= amount, InsufficientStake());
        // governanceToken.transferFrom(msg.sender, address(this), amount);


        // Claim pending rewards before updating stake
        _claimRewards(msg.sender);

        userStakes[msg.sender].amount += amount;
        userStakes[msg.sender].lastClaimTimestamp = block.timestamp; // Reset timestamp for new stake
        totalStakedAmount += amount;

        emit Staked(msg.sender, amount);
    }

    // 11. unstake: Unstake governance tokens (conceptual time lock)
    function unstake(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (userStakes[msg.sender].amount < amount) revert InsufficientStake();

        // Claim pending rewards before unstaking
        _claimRewards(msg.sender);

        userStakes[msg.sender].amount -= amount;
        totalStakedAmount -= amount;

        // --- Conceptual Time Lock ---
        // In a real system, unstaking might initiate a withdrawal request that
        // can only be completed after a delay (e.g., 7 days).
        // This would require a separate struct and mapping for pending withdrawals.
        // For this example, we'll just transfer immediately.
        // -------------------------

        // Transfer tokens from contract back to user (ERC20 standard call)
        // IERC20 governanceToken = IERC20(globalParams.governanceTokenAddress);
        // require(governanceToken.transfer(msg.sender, amount), "Token transfer failed");
        // Placeholder: simulate transfer back

        emit Unstaked(msg.sender, amount);
    }

    // Internal helper for reward calculation and claiming
    function _claimRewards(address user) internal {
        uint256 currentStake = userStakes[user].amount;
        uint256 lastClaim = userStakes[user].lastClaimTimestamp;
        uint256 rewards = 0;

        if (currentStake > 0 && totalStakedAmount > 0 && block.timestamp > lastClaim) {
            // Simplified linear reward calculation based on time and stake
            // This is highly simplified. Real systems use complex reward per token/share logic.
            uint256 duration = block.timestamp - lastClaim;
            rewards = (currentStake * globalParams.stakingRewardRate * duration) / 1e18; // Assuming rate is per second per token

             // Ensure contract has enough tokens to pay rewards
             // IERC20 governanceToken = IERC20(globalParams.governanceTokenAddress);
             // uint256 contractBalance = governanceToken.balanceOf(address(this));
             // rewards = (rewards > contractBalance) ? contractBalance : rewards;
        }

        if (rewards > 0) {
            userStakes[user].lastClaimTimestamp = block.timestamp;
            // Transfer reward tokens to user (ERC20 standard call)
            // IERC20 governanceToken = IERC20(globalParams.governanceTokenAddress);
            // require(governanceToken.transfer(user, rewards), "Reward transfer failed");
            // Placeholder: simulate transfer

            emit RewardsClaimed(user, rewards);
        } else if (userStakes[user].amount > 0 && block.timestamp > lastClaim) {
             // If no rewards calculated despite stake/time, maybe due to rate=0 or insufficient balance
             // Still update timestamp to prevent claiming past period rewards if rate changes later
             userStakes[user].lastClaimTimestamp = block.timestamp;
             // Or revert NoRewardsToClaim if you only want to update timestamp on actual claim
        } else {
             revert NoRewardsToClaim(); // No stake or no time passed since last claim
        }
    }


    // 12. claimRewards: Claim accumulated staking rewards
    function claimRewards() external {
        _claimRewards(msg.sender);
    }

    // --- 11. Reputation Management ---

    // 13. getReputation: Get user reputation score
    function getReputation(address user) public view returns (uint256) {
        return userReputation[user];
    }

    // 14. awardReputation: Award reputation points (only via Governance)
    function awardReputation(address user, uint256 amount) external onlyGovernance {
        userReputation[user] += amount;
        emit ReputationAwarded(user, amount);
    }

    // 15. deductReputation: Deduct reputation points (only via Governance)
    function deductReputation(address user, uint256 amount) external onlyGovernance {
        if (userReputation[user] < amount) {
            userReputation[user] = 0;
        } else {
            userReputation[user] -= amount;
        }
        emit ReputationDeducted(user, amount);
    }

    // --- 12. Licensing ---

    // 16. proposeItemLicense: Propose a new license for an Item (requires ownership)
    function proposeItemLicense(uint256 itemId, string memory licenseUri) external isItemOwner(itemId) {
        // Check if item exists (isItemOwner implies existence and ownership)
        // require(items[itemId].creator != address(0), ItemNotFound());

        uint256 proposalId = nextProposalId++;
        uint256 currentTime = block.timestamp;

        // Description indicates this is a license proposal
        string memory description = string(abi.encodePacked("Propose License for Item #", Strings.toString(itemId), ": ", licenseUri));


        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: description,
            target: address(this), // Target is this contract
            callData: abi.encodeWithSelector(this._setItemLicense.selector, itemId, licenseUri), // Call the internal set function
            voteStart: currentTime,
            voteEnd: currentTime + globalParams.votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            voters: new mapping(address => bool),
            state: ProposalState.Active,
            licenseUri: licenseUri, // Store license URI in proposal for view functions
            itemId: itemId // Store itemId in proposal
        });

        emit LicenseProposed(itemId, proposalId, licenseUri);
    }

    // 17. setItemLicense: Set the license URI for an Item (only via Governance execution)
    // This function is called internally by executeProposal when a license proposal passes.
    // The external function `proposeItemLicense` creates the governance proposal that,
    // if passed, will call this internal function via `executeProposal`.
    // The `onlyGovernance` modifier on the internal function ensures it can only be called in this way.
    // The external function is removed as it should not be called directly by users.

    // 18. getItemLicense: Get the current license URI for an Item
    function getItemLicense(uint256 itemId) external view returns (string memory) {
        if (items[itemId].creator == address(0)) revert ItemNotFound(); // Check if item exists
        return items[itemId].licenseUri;
    }

    // --- 13. View Functions ---

    // 19. getProposalState: Get the current state of a governance proposal
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();

        // Re-evaluate state based on time if needed
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEnd) {
            if (proposal.votesFor > proposal.votesAgainst) {
                 // Simple majority check
                 return ProposalState.Succeeded;
            } else {
                 return ProposalState.Defeated;
            }
        }
        // If state is Pending/Canceled/Executed/Succeeded (and not yet executed but time is past end), return stored state
        return proposal.state;
    }

    // 20. getVotingPower: Calculate current voting power
    function getVotingPower(address user) public view returns (uint256) {
        uint256 stake = userStakes[user].amount;
        uint256 reputation = userReputation[user];

        // Simple linear formula: stake + (reputation * multiplier) + base boost
        // More complex logic could involve decay, thresholds, quadratic scaling etc.
        return stake + (reputation * globalParams.reputationStakeMultiplier) + globalParams.baseReputationVotingBoost;
    }

    // 21. getItemComponents: Returns the Component types and amounts embedded in an Item.
    // Note: This is a mapping, iterating mappings in Solidity view functions can be complex/gas-limited.
    // A better approach for many components might be to store components in an array in the struct.
    // For this example, we'll return known component types within the item's mapping.
    function getItemComponents(uint256 itemId) external view returns (uint256[] memory componentTypeIds, uint256[] memory amounts) {
        if (items[itemId].creator == address(0)) revert ItemNotFound(); // Check if item exists

        uint256 count = 0;
        // First pass to count components
        for (uint256 typeId = 1; typeId < nextComponentTypeId; typeId++) {
             if (items[itemId].components[typeId] > 0) {
                 count++;
             }
        }

        componentTypeIds = new uint256[](count);
        amounts = new uint256[](count);
        uint256 currentIndex = 0;

        // Second pass to populate arrays
        for (uint256 typeId = 1; type2d < nextComponentTypeId; typeId++) {
            uint256 amount = items[itemId].components[typeId];
            if (amount > 0) {
                componentTypeIds[currentIndex] = typeId;
                amounts[currentIndex] = amount;
                currentIndex++;
            }
        }
        return (componentTypeIds, amounts);
    }

    // 22. getComponentBalance: Gets a user's balance of a specific Component type (wraps ERC1155).
    function getComponentBalance(address user, uint256 componentTypeId) external view returns (uint256) {
        // Check if component type exists (optional but good practice)
        if (componentTypes[componentTypeId].forgeCostMultiplier == 0 && componentTypeId != 0) revert ComponentTypeNotFound(); // Allow checking balance for type 0 if needed

        // Call ERC1155 balance function (standard call)
        // IERC1155 componentToken = IERC1155(globalParams.componentTokenAddress);
        // return componentToken.balanceOf(user, componentTypeId);
        // Placeholder: return dummy value
        return 100; // Simulate having 100 of each component type
    }

    // 23. getStakeBalance: Gets a user's staked amount.
    function getStakeBalance(address user) external view returns (uint256) {
        return userStakes[user].amount;
    }

    // 24. getTotalStaked: Gets the total amount of tokens staked in the contract.
    function getTotalStaked() external view returns (uint256) {
        return totalStakedAmount;
    }

    // 25. getGlobalParameters: Returns the current global governance/platform parameters.
    function getGlobalParameters() external view returns (GlobalParameters memory) {
        return globalParams;
    }

    // 26. getNextItemId: Returns the ID that will be assigned to the next forged Item.
    function getNextItemId() external view returns (uint256) {
        return nextItemId;
    }

    // 27. getNextComponentTypeId: Returns the ID that will be assigned to the next registered Component type.
    function getNextComponentTypeId() external view returns (uint256) {
         return nextComponentTypeId;
    }

    // Internal function to register a new component type (called via governance)
    function _registerComponentType(string memory name, string memory uri, uint256 forgeCostMultiplier, uint256 dismantleReturnPercentage) internal onlyGovernance {
        uint256 typeId = nextComponentTypeId++;
        componentTypes[typeId] = ComponentType({
            name: name,
            uri: uri,
            forgeCostMultiplier: forgeCostMultiplier,
            dismantleReturnPercentage: dismantleReturnPercentage
        });
        // Emit event? ComponentTypeRegistered(typeId, name);
    }

    // 28. getComponentTypeDetails: Returns details about a specific Component type.
    function getComponentTypeDetails(uint256 componentTypeId) external view returns (ComponentType memory) {
        if (componentTypes[componentTypeId].forgeCostMultiplier == 0 && componentTypeId != 0) revert ComponentTypeNotFound();
        return componentTypes[componentTypeId];
    }

     // 29. getItemDetails: Returns key details about an Item.
    function getItemDetails(uint256 itemId) external view returns (address creator, string memory licenseUri, uint256[] memory componentTypeIds, uint256[] memory amounts) {
         if (items[itemId].creator == address(0)) revert ItemNotFound(); // Check if item exists

         creator = items[itemId].creator;
         licenseUri = items[itemId].licenseUri;
         (componentTypeIds, amounts) = getItemComponents(itemId); // Reuse existing function

         return (creator, licenseUri, componentTypeIds, amounts);
    }

    // Fallback/Receive functions for handling incoming ETH if needed (not explicitly part of the concept, but good practice)
    // receive() external payable {}
    // fallback() external payable {}
}

// Helper library for uint256 to string conversion (e.g., from OpenZeppelin)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```