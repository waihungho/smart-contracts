Okay, here is a smart contract implementing a creative and somewhat advanced concept: a dynamic NFT collection called "Chronicle Keepers" where the NFTs evolve based on user interaction (staking, simulated "quests", external data triggers) and community governance. It integrates an associated utility token (`AetherToken` - though the contract itself references an external ERC20 address).

The contract combines elements of:

1.  **Dynamic NFTs:** Attributes of the NFTs change over time based on on-chain actions and potentially external data feeds (simulated).
2.  **Staking Mechanics:** Users can stake a utility token (`Aether`) into a general pool *or directly into specific NFTs* to influence their attributes.
3.  **On-Chain Quests/Events:** A simple mechanism to trigger attribute changes based on calling a function (representing completing a task or experiencing an event).
4.  **Simulated Oracle Interaction:** A function simulating receiving external data that affects NFT state.
5.  **Integrated Governance:** A basic governance system allowing token/NFT holders to propose and vote on changing certain contract parameters.
6.  **Attribute System:** NFTs have defined attributes that update. A calculated 'rarity score' reflects their current state.

This design aims for complexity and interactivity beyond standard static NFTs or simple token contracts, while combining multiple common DeFi/NFT patterns in a less standard way (especially staking *into* the NFT).

---

## Smart Contract Outline & Function Summary

**Contract Name:** `ChronicleKeepers`

**Core Concept:** Manages a collection of ERC721 NFTs ("Chronicles") whose attributes are dynamic. These attributes evolve based on Aether token staking (both general and directly into NFTs), simulated quests, simulated oracle data updates, and community governance.

**Key Features:**
*   ERC721 standard for Chronicles.
*   Uses an external ERC20 token (Aether) for staking and interaction.
*   Chronicles have dynamic attributes (`wisdom`, `fortitude`, `status`, `lastUpdatedBlock`, `stakedAether`).
*   Users can stake Aether tokens into their own Chronicle NFTs.
*   Users can stake Aether tokens into a general staking pool.
*   Quests/Events: Functions that trigger attribute changes or rewards based on NFT state.
*   Simulated Oracle: A function to simulate external data input affecting NFT attributes.
*   Calculated Rarity Score: A view function deriving rarity from current attributes.
*   Basic On-Chain Governance: Propose and vote on certain contract parameters (like staking rates, quest effects). Vote weight based on staked Aether and/or owned NFTs.

**Function Summary (Minimum 20 functions):**

1.  `constructor`: Deploys the contract, sets initial parameters and the Aether token address.
2.  `mintInitialChronicles`: Owner function to mint the first batch of Chronicles.
3.  `getChronicleAttributes`: View function to retrieve the full attribute struct for a given Chronicle.
4.  `calculateRarityScore`: View function calculating a rarity score based on current attributes.
5.  `stakeAether`: Stakes Aether tokens into the general staking pool.
6.  `unstakeAether`: Unstakes Aether tokens from the general staking pool.
7.  `claimStakingRewards`: Claims calculated staking rewards from the general pool (Reward logic simplified/placeholder).
8.  `getStakedAether`: View function to see a user's general staked amount.
9.  `stakeAetherIntoChronicle`: Stakes Aether tokens directly into a specific Chronicle NFT (must own the NFT).
10. `unstakeAetherFromChronicle`: Unstakes Aether tokens from a specific Chronicle NFT.
11. `getAetherStakedInChronicle`: View function to see amount of Aether staked in a specific Chronicle.
12. `performQuest`: Triggers a simulated quest/event for a Chronicle, potentially changing attributes based on random factor / current state.
13. `triggerOracleUpdate`: Simulates an external oracle update affecting a Chronicle's attributes based on provided data.
14. `upgradeChronicleAttribute`: Allows burning a specific amount of Aether to boost a chosen attribute (placeholder logic).
15. `setChronicleStatus`: Changes the status of a Chronicle based on meeting certain attribute thresholds (called internally or perhaps by governance).
16. `proposeParameterChange`: Allows eligible participants (based on vote weight) to propose changing a contract parameter.
17. `voteOnProposal`: Allows eligible participants to vote on an active proposal.
18. `executeProposal`: Executes a successful proposal after the voting period ends.
19. `getVoteWeight`: View function calculating an address's current governance vote weight.
20. `getProposalState`: View function returning the current state of a proposal (Pending, Active, Succeeded, Failed, Executed).
21. `getProposalDetails`: View function returning details about a specific proposal.
22. `setAetherTokenAddress`: Owner function to set the Aether ERC20 contract address (callable once).
23. `tokenURI`: Standard ERC721 metadata function (returns a placeholder or basic URI).
24. `baseAttributesForNewChronicle`: Internal helper to generate initial attributes.
25. `_updateChronicleAttributes`: Internal helper to encapsulate attribute update logic.
26. `_calculateStakingRewards`: Internal helper for reward calculation (simplified).
27. `_checkVoteEligibility`: Internal helper to check if an address can propose/vote.

*(Note: Standard ERC721 functions like `balanceOf`, `ownerOf`, `transferFrom`, `approve`, etc., and `Ownable` functions like `owner`, `transferOwnership` are inherited and count towards the total, easily pushing the count past 20. The functions listed above are the custom or overridden logic.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Smart Contract Outline & Function Summary ---
// Contract Name: ChronicleKeepers
// Core Concept: Manages dynamic ERC721 NFTs (Chronicles) evolving via staking (general & per-NFT),
//               simulated quests/oracle, and governance using an associated Aether ERC20 token.
// Key Features:
// - Dynamic ERC721 attributes.
// - Staking Aether into general pool and individual NFTs.
// - On-chain Quests/Events triggering attribute changes.
// - Simulated external data/oracle updates affecting attributes.
// - Calculated Rarity Score based on current state.
// - Basic on-chain governance for parameter changes.
//
// Function Summary (>= 20 functions):
// 1. constructor: Initialize contract, set Aether token, initial params.
// 2. mintInitialChronicles: Owner mints initial supply.
// 3. getChronicleAttributes: View Chronicle's current attributes.
// 4. calculateRarityScore: View calculated rarity score.
// 5. stakeAether: Stake Aether in general pool.
// 6. unstakeAether: Unstake Aether from general pool.
// 7. claimStakingRewards: Claim general staking rewards (placeholder logic).
// 8. getStakedAether: View user's general staked amount.
// 9. stakeAetherIntoChronicle: Stake Aether into a specific NFT.
// 10. unstakeAetherFromChronicle: Unstake Aether from a specific NFT.
// 11. getAetherStakedInChronicle: View Aether staked in an NFT.
// 12. performQuest: Trigger simulated quest/event for NFT.
// 13. triggerOracleUpdate: Simulate external data affecting NFT.
// 14. upgradeChronicleAttribute: Burn Aether to boost attribute (placeholder logic).
// 15. setChronicleStatus: Update NFT status based on attributes.
// 16. proposeParameterChange: Create a governance proposal.
// 17. voteOnProposal: Vote on a proposal.
// 18. executeProposal: Execute a successful proposal.
// 19. getVoteWeight: View address's governance weight.
// 20. getProposalState: View proposal's state.
// 21. getProposalDetails: View proposal details.
// 22. setAetherTokenAddress: Owner sets Aether ERC20 address.
// 23. tokenURI: Standard ERC721 URI.
// 24. baseAttributesForNewChronicle: Internal helper for new NFT attributes.
// 25. _updateChronicleAttributes: Internal helper for attribute changes.
// 26. _calculateStakingRewards: Internal helper for rewards (simplified).
// 27. _checkVoteEligibility: Internal helper for governance checks.
// Plus inherited ERC721, ERC165, Ownable functions (e.g., balanceOf, ownerOf, transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll, owner, transferOwnership).

// --- End Outline & Summary ---

contract ChronicleKeepers is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    IERC20 public aetherToken;

    struct Chronicle {
        uint256 tokenId;
        uint256 wisdom;
        uint256 fortitude;
        uint256 agility;
        uint256 grace;
        uint8 status; // 0: Dormant, 1: Awakened, 2: Ascended
        uint256 lastUpdatedBlock;
        uint256 stakedAether; // Aether staked directly into this NFT
        string metadataURI; // Could be dynamic based on attributes
    }

    // Attribute indices for governance/upgrade
    enum AttributeIndex { Wisdom, Fortitude, Agility, Grace }

    mapping(uint256 => Chronicle) public chronicles;
    mapping(address => uint256) public generalStakedAether; // Aether staked in the general pool
    mapping(address => uint256) public lastRewardClaimBlock; // For staking reward calculation

    // Governance Parameters
    struct GovernanceParameters {
        uint256 proposalThresholdAether; // Min Aether staked to propose
        uint256 votingPeriodBlocks;      // How long voting is open
        uint256 requiredVoteWeight;      // Min total weight needed to pass (absolute number, not %)
        uint256 voteWeightPerAether;     // Weight per Aether staked (e.g., 1)
        uint256 voteWeightPerChronicle;  // Weight per Chronicle owned (e.g., 100)
    }
    GovernanceParameters public govParams;

    // Governance Proposals
    struct Proposal {
        uint256 id;
        string description;
        uint256 parameterIndex; // Index representing the parameter to change (e.g., 0 for proposalThresholdAether, 1 for votingPeriodBlocks)
        uint256 newValue;       // The value to change the parameter to
        uint256 voteCountSupport;
        uint256 voteCountOppose;
        mapping(address => bool) hasVoted;
        uint256 proposalBlock; // Block when proposal was created
        uint256 votingEndsBlock; // Block when voting ends
        ProposalState state;
    }

    enum ProposalState { Pending, Active, Canceled, Succeeded, Failed, Executed }
    Counters.Counter public proposalCounter;
    mapping(uint256 => Proposal) public proposals;

    // Event declarations
    event ChronicleMinted(uint256 indexed tokenId, address indexed owner);
    event AttributesUpdated(uint256 indexed tokenId, uint8 indexed status, uint256 wisdom, uint256 fortitude, uint256 agility, uint256 grace);
    event GeneralAetherStaked(address indexed staker, uint256 amount);
    event GeneralAetherUnstaked(address indexed staker, uint256 amount);
    event StakingRewardsClaimed(address indexed staker, uint256 amount);
    event AetherStakedIntoChronicle(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event AetherUnstakedFromChronicle(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event QuestCompleted(uint256 indexed tokenId, string outcome);
    event OracleUpdateTriggered(uint256 indexed tokenId, bytes dataHash);
    event AttributeUpgraded(uint256 indexed tokenId, uint8 indexed attributeIndex, uint256 newAttributeValue);
    event ChronicleStatusChanged(uint256 indexed tokenId, uint8 oldStatus, uint8 newStatus);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 parameterIndex, uint256 newValue, uint256 votingEndsBlock);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, uint256 parameterIndex, uint256 newValue);

    // Error declarations
    error ZeroAddressNotAllowed();
    error AmountMustBePositive();
    error NotEnoughAetherStaked();
    error NotEnoughAetherBalance();
    error AetherTokenNotSet();
    error NotChronicleOwnerOrApproved();
    error StakedAmountExceedsStaked();
    error InvalidAttributeIndex();
    error CannotUpgradeAttribute();
    error NotEligibleToPropose();
    error ProposalNotFound();
    error VotingPeriodNotActive();
    error AlreadyVoted();
    error CannotExecuteProposal();
    error ProposalNotSucceeded();
    error ProposalNotYetRunnable();
    error InvalidParameterIndex();
    error AetherTokenAlreadySet();
    error InvalidVotingWeightCalculation();


    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Initial governance parameters - can be changed later via governance
        govParams = GovernanceParameters({
            proposalThresholdAether: 100 * 10**18, // 100 Aether (assuming 18 decimals)
            votingPeriodBlocks: 1000,            // Approx 4-5 hours (if 12-15 sec blocks)
            requiredVoteWeight: 500,             // Needs 500 cumulative weight to pass
            voteWeightPerAether: 1,              // 1 Aether = 1 vote weight
            voteWeightPerChronicle: 10           // 1 Chronicle = 10 vote weight
        });
    }

    // --- ERC721 Overrides ---
    // Standard functions like balanceOf, ownerOf, transferFrom, approve, getApproved,
    // setApprovalForAll, isApprovedForAll are inherited from OpenZeppelin

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        Chronicle storage chronicle = chronicles[tokenId];
        // In a real application, this would point to a JSON file with attributes
        // You could dynamically generate part of the URI based on chronicle.metadataURI or attributes
        return string(abi.encodePacked("ipfs://Qmdynamicchroniclemetadata/", chronicle.metadataURI));
    }

    // --- Initial Setup ---

    /// @notice Sets the address of the Aether ERC20 token contract.
    /// @dev Can only be called once by the owner.
    /// @param tokenAddress The address of the deployed Aether ERC20 token.
    function setAetherTokenAddress(address tokenAddress) public onlyOwner {
        if (address(aetherToken) != address(0)) revert AetherTokenAlreadySet();
        if (tokenAddress == address(0)) revert ZeroAddressNotAllowed();
        aetherToken = IERC20(tokenAddress);
    }

    /// @notice Mints the initial batch of Chronicle NFTs.
    /// @dev Callable only by the contract owner.
    /// @param to Addresses to mint to.
    /// @param quantities Number of chronicles to mint for each address. Must match length of `to`.
    function mintInitialChronicles(address[] calldata to, uint256[] calldata quantities) public onlyOwner nonReentrant {
        require(to.length == quantities.length, "Arrays must be same length");
        require(address(aetherToken) != address(0), "Aether token address must be set first");

        for (uint i = 0; i < to.length; i++) {
            require(to[i] != address(0), "Cannot mint to zero address");
            for (uint j = 0; j < quantities[i]; j++) {
                _tokenIdCounter.increment();
                uint256 newTokenId = _tokenIdCounter.current();
                _safeMint(to[i], newTokenId);
                chronicles[newTokenId] = baseAttributesForNewChronicle(newTokenId);
                chronicles[newTokenId].lastUpdatedBlock = block.number; // Initialize update block

                emit ChronicleMinted(newTokenId, to[i]);
                emit AttributesUpdated(
                    newTokenId,
                    chronicles[newTokenId].status,
                    chronicles[newTokenId].wisdom,
                    chronicles[newTokenId].fortitude,
                    chronicles[newTokenId].agility,
                    chronicles[newTokenId].grace
                );
            }
        }
    }

    // --- Chronicle Interaction & Dynamic Attributes ---

    /// @notice Gets the attributes of a specific Chronicle NFT.
    /// @param tokenId The ID of the Chronicle.
    /// @return A struct containing the Chronicle's attributes.
    function getChronicleAttributes(uint256 tokenId) public view returns (Chronicle memory) {
         // No need to check ownership for viewing
        require(_exists(tokenId), "Chronicle does not exist");
        return chronicles[tokenId];
    }

    /// @notice Calculates a rarity score for a Chronicle based on its current attributes.
    /// @param tokenId The ID of the Chronicle.
    /// @return A rarity score (simplified calculation). Higher is potentially rarer.
    function calculateRarityScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[tokenId];

        // Simple linear calculation. Could be more complex (e.g., exponential, weighted)
        uint256 score = chronicle.wisdom + chronicle.fortitude + chronicle.agility + chronicle.grace;

        // Add bonus based on status
        if (chronicle.status == 1) score += 50; // Awakened bonus
        if (chronicle.status == 2) score += 200; // Ascended bonus

        // Could also factor in stakedAether, time since creation, etc.
        return score;
    }

    /// @notice Allows staking Aether tokens into the general staking pool.
    /// @dev Requires user to have approved this contract to spend the Aether.
    /// @param amount The amount of Aether to stake.
    function stakeAether(uint256 amount) public nonReentrant {
        if (amount == 0) revert AmountMustBePositive();
        if (address(aetherToken) == address(0)) revert AetherTokenNotSet();
        // Add reward calculation logic here if rewards were complex (e.g., accrual)
        generalStakedAether[msg.sender] += amount;
        aetherToken.transferFrom(msg.sender, address(this), amount);
        emit GeneralAetherStaked(msg.sender, amount);
    }

    /// @notice Allows unstaking Aether tokens from the general staking pool.
    /// @param amount The amount of Aether to unstake.
    function unstakeAether(uint256 amount) public nonReentrant {
        if (amount == 0) revert AmountMustBePositive();
        if (generalStakedAether[msg.sender] < amount) revert NotEnoughAetherStaked();
        if (address(aetherToken) == address(0)) revert AetherTokenNotSet();

        // Add reward distribution logic here before reducing stake
        // For simplicity, claimRewards() is separate

        generalStakedAether[msg.sender] -= amount;
        aetherToken.transfer(msg.sender, amount);
        emit GeneralAetherUnstaked(msg.sender, amount);
    }

    /// @notice Allows claiming staking rewards from the general pool.
    /// @dev Placeholder: Reward logic needs implementation. Assumes a simple distribution model.
    function claimStakingRewards() public nonReentrant {
        // --- Placeholder Reward Calculation Logic ---
        // A real implementation would calculate rewards based on:
        // - Time staked since last claim/stake
        // - Amount staked
        // - Total pool size / emission rate
        // - Could involve distributing Aether minted by the contract or collected from fees

        uint256 rewardsToClaim = _calculateStakingRewards(msg.sender); // Call internal helper

        // Reset timer/state for reward calculation
        lastRewardClaimBlock[msg.sender] = block.number; // Simple block-based tracking

        if (rewardsToClaim > 0) {
             if (address(aetherToken) == address(0)) revert AetherTokenNotSet();
             // In a real scenario, contract would need enough Aether, maybe through minting or deposits
             // This placeholder assumes the contract *has* the Aether to send
             aetherToken.transfer(msg.sender, rewardsToClaim);
             emit StakingRewardsClaimed(msg.sender, rewardsToClaim);
        }
         // No explicit revert if rewardsToClaim is 0, just no transfer happens.
    }

     /// @notice View function to get the amount of Aether a user has staked in the general pool.
     /// @param staker The address of the staker.
     /// @return The amount of Aether staked.
    function getStakedAether(address staker) public view returns (uint256) {
        return generalStakedAether[staker];
    }

    /// @notice Stakes Aether tokens directly into a specific Chronicle NFT.
    /// @dev The caller must be the owner or approved for the tokenId.
    /// @param tokenId The ID of the Chronicle.
    /// @param amount The amount of Aether to stake into the Chronicle.
    function stakeAetherIntoChronicle(uint256 tokenId, uint256 amount) public nonReentrant {
        if (amount == 0) revert AmountMustBePositive();
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        if (address(aetherToken) == address(0)) revert AetherTokenNotSet();

        Chronicle storage chronicle = chronicles[tokenId];
        chronicle.stakedAether += amount;

        aetherToken.transferFrom(msg.sender, address(this), amount);

        // --- Attribute Change Logic Based on Staked Aether (Example) ---
        // This could trigger attribute boosts, status changes, etc.
        // For simplicity, we just update the staked amount and maybe a status if threshold hit.
        // A more complex system would analyze the *change* in staked amount or the new total.
        setChronicleStatus(tokenId, _deriveStatusFromAttributes(tokenId)); // Check if status changes based on *total* attributes incl. staked Aether influence

        _updateChronicleAttributes(tokenId); // Update last updated block

        emit AetherStakedIntoChronicle(tokenId, msg.sender, amount);
        emit AttributesUpdated(
            tokenId,
            chronicle.status,
            chronicle.wisdom,
            chronicle.fortitude,
            chronicle.agility,
            chronicle.grace
        );
    }

    /// @notice Unstakes Aether tokens from a specific Chronicle NFT.
    /// @dev The caller must be the owner or approved for the tokenId.
    /// @param tokenId The ID of the Chronicle.
    /// @param amount The amount of Aether to unstake from the Chronicle.
    function unstakeAetherFromChronicle(uint256 tokenId, uint256 amount) public nonReentrant {
        if (amount == 0) revert AmountMustBePositive();
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        if (chronicles[tokenId].stakedAether < amount) revert StakedAmountExceedsStaked();
        if (address(aetherToken) == address(0)) revert AetherTokenNotSet();

        Chronicle storage chronicle = chronicles[tokenId];
        chronicle.stakedAether -= amount;

        aetherToken.transfer(msg.sender, amount);

        // --- Attribute Change Logic Based on Unstaked Aether (Example) ---
        // Could trigger attribute reduction or status change.
        setChronicleStatus(tokenId, _deriveStatusFromAttributes(tokenId)); // Check if status changes based on *total* attributes

        _updateChronicleAttributes(tokenId); // Update last updated block

        emit AetherUnstakedFromChronicle(tokenId, msg.sender, amount);
         emit AttributesUpdated(
            tokenId,
            chronicle.status,
            chronicle.wisdom,
            chronicle.fortitude,
            chronicle.agility,
            chronicle.grace
        );
    }

     /// @notice View function to get the amount of Aether staked directly into a specific Chronicle.
     /// @param tokenId The ID of the Chronicle.
     /// @return The amount of Aether staked in the Chronicle.
    function getAetherStakedInChronicle(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Chronicle does not exist");
         return chronicles[tokenId].stakedAether;
    }


    /// @notice Simulates performing a quest or event for a Chronicle.
    /// @dev The caller must be the owner or approved for the tokenId. Logic for attribute change is example.
    /// @param tokenId The ID of the Chronicle.
    function performQuest(uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
         require(_exists(tokenId), "Chronicle does not exist");

        Chronicle storage chronicle = chronicles[tokenId];

        // --- Simulated Quest Outcome Logic (Example) ---
        // Use blockhash for a simple pseudo-random element (not secure for high-value outcomes)
        bytes32 blockHash = blockhash(block.number - 1);
        uint256 randomFactor = uint256(blockHash);

        string memory outcomeDescription = "Minor event occurred.";

        if (randomFactor % 100 < 30) { // 30% chance of attribute boost
            uint8 attributeToBoost = uint8(randomFactor % 4); // Randomly pick an attribute
            uint256 boostAmount = (randomFactor % 10) + 1; // Boost by 1-10
            if (attributeToBoost == uint8(AttributeIndex.Wisdom)) chronicle.wisdom += boostAmount;
            else if (attributeToBoost == uint8(AttributeIndex.Fortitude)) chronicle.fortitude += boostAmount;
            else if (attributeToBoost == uint8(AttributeIndex.Agility)) chronicle.agility += boostAmount;
            else if (attributeToBoost == uint8(AttributeIndex.Grace)) chronicle.grace += boostAmount;
            outcomeDescription = string(abi.encodePacked("Quest successful! Boosted attribute index ", uint2str(attributeToBoost), " by ", uint2str(boostAmount), "."));
        } else if (randomFactor % 100 < 35) { // 5% chance of attribute decrease
             uint8 attributeToDegrade = uint8(randomFactor % 4);
             uint256 degradeAmount = (randomFactor % 5) + 1; // Degrade by 1-5
             if (attributeToDegrade == uint8(AttributeIndex.Wisdom)) chronicle.wisdom = chronicle.wisdom > degradeAmount ? chronicle.wisdom - degradeAmount : 0;
             else if (attributeToDegrade == uint8(AttributeIndex.Fortitude)) chronicle.fortitude = chronicle.fortitude > degradeAmount ? chronicle.fortitude - degradeAmount : 0;
             else if (attributeToDegrade == uint8(AttributeIndex.Agility)) chronicle.agility = chronicle.agility > degradeAmount ? chronicle.agility - degradeAmount : 0;
             else if (attributeToDegrade == uint8(AttributeIndex.Grace)) chronicle.grace = chronicle.grace > degradeAmount ? chronicle.grace - degradeAmount : 0;
             outcomeDescription = string(abi.encodePacked("Quest failed. Degraded attribute index ", uint2str(attributeToDegrade), " by ", uint2str(degradeAmount), "."));
        }

        // --- Update status based on new attributes ---
        setChronicleStatus(tokenId, _deriveStatusFromAttributes(tokenId));

        _updateChronicleAttributes(tokenId); // Update last updated block

        emit QuestCompleted(tokenId, outcomeDescription);
        emit AttributesUpdated(
            tokenId,
            chronicle.status,
            chronicle.wisdom,
            chronicle.fortitude,
            chronicle.agility,
            chronicle.grace
        );
    }

     /// @notice Simulates triggering an update based on external oracle data.
     /// @dev Requires a trusted caller (e.g., another contract or owner in this simplified example).
     ///      In a real dApp, this would be called by a Chainlink oracle callback or similar.
     /// @param tokenId The ID of the Chronicle.
     /// @param data Simulated oracle data (e.g., could be bytes representing a price, weather, event).
    function triggerOracleUpdate(uint256 tokenId, bytes memory data) public onlyOwner nonReentrant {
         // In a real dApp, this would likely be restricted to a specific oracle contract address
         // require(msg.sender == oracleAddress, "Not called by oracle");

         require(_exists(tokenId), "Chronicle does not exist");
         Chronicle storage chronicle = chronicles[tokenId];

         // --- Simulate Attribute Change Based on Oracle Data (Example) ---
         // This is a highly simplified example. Real logic would parse the 'data' bytes.
         uint256 dataInfluence = uint256(keccak256(data)) % 20; // Derive a number from data

         if (dataInfluence < 5) { // Low influence
             chronicle.wisdom += 1;
         } else if (dataInfluence < 10) { // Medium influence
             chronicle.fortitude += 2;
         } else if (dataInfluence < 15) { // Higher influence
             chronicle.agility += 3;
         } else { // Highest influence
             chronicle.grace += 4;
         }

        // --- Update status based on new attributes ---
        setChronicleStatus(tokenId, _deriveStatusFromAttributes(tokenId));

        _updateChronicleAttributes(tokenId); // Update last updated block

        emit OracleUpdateTriggered(tokenId, keccak256(data)); // Log hash of data
         emit AttributesUpdated(
            tokenId,
            chronicle.status,
            chronicle.wisdom,
            chronicle.fortitude,
            chronicle.agility,
            chronicle.grace
        );
    }

    /// @notice Allows burning Aether to directly upgrade a specific attribute of a Chronicle.
    /// @dev The caller must be the owner or approved. Burn rate and max level are placeholder.
    /// @param tokenId The ID of the Chronicle.
    /// @param attributeIndex The index of the attribute to upgrade (0:Wisdom, 1:Fortitude, 2:Agility, 3:Grace).
    function upgradeChronicleAttribute(uint256 tokenId, uint8 attributeIndex) public nonReentrant {
         require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
         require(_exists(tokenId), "Chronicle does not exist");
         if (attributeIndex > uint8(AttributeIndex.Grace)) revert InvalidAttributeIndex();
         if (address(aetherToken) == address(0)) revert AetherTokenNotSet();

         Chronicle storage chronicle = chronicles[tokenId];

         // --- Upgrade Cost and Logic (Example) ---
         uint256 burnCost = 10 * 10**18; // Example: 10 Aether per upgrade
         uint256 boostAmount = 5; // Example: Each upgrade adds 5 points

         // Add checks for max attribute levels if desired
         // if (attributeIndex == uint8(AttributeIndex.Wisdom) && chronicle.wisdom >= MAX_WISDOM) revert CannotUpgradeAttribute();

         aetherToken.transferFrom(msg.sender, address(this), burnCost);
         // In a real scenario, you might burn tokens instead of sending to contract: aetherToken.burn(burnCost);

         if (attributeIndex == uint8(AttributeIndex.Wisdom)) chronicle.wisdom += boostAmount;
         else if (attributeIndex == uint8(AttributeIndex.Fortitude)) chronicle.fortitude += boostAmount;
         else if (attributeIndex == uint8(AttributeIndex.Agility)) chronicle.agility += boostAmount;
         else if (attributeIndex == uint8(AttributeIndex.Grace)) chronicle.grace += boostAmount;

        // --- Update status based on new attributes ---
        setChronicleStatus(tokenId, _deriveStatusFromAttributes(tokenId));

        _updateChronicleAttributes(tokenId); // Update last updated block

         emit AttributeUpgraded(tokenId, attributeIndex, (attributeIndex == uint8(AttributeIndex.Wisdom) ? chronicle.wisdom :
                                                         (attributeIndex == uint8(AttributeIndex.Fortitude) ? chronicle.fortitude :
                                                         (attributeIndex == uint8(AttributeIndex.Agility) ? chronicle.agility : chronicle.grace))));
         emit AttributesUpdated(
            tokenId,
            chronicle.status,
            chronicle.wisdom,
            chronicle.fortitude,
            chronicle.agility,
            chronicle.grace
        );
    }

    /// @notice Updates the status of a Chronicle based on its current attributes.
    /// @dev This is typically called internally after attributes change, but exposed for potential external triggers or governance.
    /// @param tokenId The ID of the Chronicle.
    /// @param newStatus The calculated new status based on attributes.
    function setChronicleStatus(uint256 tokenId, uint8 newStatus) public {
         // Add owner/governance/self-call restriction if needed.
         // For this example, it's called internally after attribute changes,
         // but allowing external call could be governance decided.
         // require(msg.sender == address(this) || _checkVoteEligibility(msg.sender), "Only contract or governance can call"); // Example restriction

         require(_exists(tokenId), "Chronicle does not exist");
         Chronicle storage chronicle = chronicles[tokenId];
         if (chronicle.status == newStatus) return; // No change needed

         uint8 oldStatus = chronicle.status;
         chronicle.status = newStatus;

        _updateChronicleAttributes(tokenId); // Update last updated block

         emit ChronicleStatusChanged(tokenId, oldStatus, newStatus);
         // AttributesUpdated event might also be emitted by the function that calls this.
    }


    // --- Governance ---

    /// @notice Calculates the governance vote weight for an address.
    /// @dev Weight is based on general staked Aether and owned Chronicles.
    /// @param voter The address to calculate weight for.
    /// @return The calculated vote weight.
    function getVoteWeight(address voter) public view returns (uint256) {
        if (address(aetherToken) == address(0)) revert AetherTokenNotSet();
        uint256 aetherWeight = generalStakedAether[voter] / (10**18) * govParams.voteWeightPerAether; // Assuming 18 decimals, convert to whole Aether
        uint256 chronicleCount = balanceOf(voter);
        uint256 chronicleWeight = chronicleCount * govParams.voteWeightPerChronicle;
        return aetherWeight + chronicleWeight;
    }

    /// @notice Allows proposing a change to a contract governance parameter.
    /// @dev Requires the proposer to meet the proposal threshold.
    /// @param parameterIndex The index of the governance parameter to change (e.g., 0 for proposalThresholdAether).
    /// @param newValue The new value for the parameter.
    /// @param description A description of the proposal.
    function proposeParameterChange(uint256 parameterIndex, uint256 newValue, string memory description) public nonReentrant {
        if (!_checkVoteEligibility(msg.sender)) revert NotEligibleToPropose();
         if (getVoteWeight(msg.sender) < govParams.proposalThresholdAether / (10**18)) revert NotEligibleToPropose(); // Using whole Aether for threshold check

        // Validate parameter index
        if (parameterIndex > 2) revert InvalidParameterIndex(); // Example: 0=thresh, 1=votingPeriod, 2=requiredWeight. Add more as needed.

        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            parameterIndex: parameterIndex,
            newValue: newValue,
            voteCountSupport: 0,
            voteCountOppose: 0,
            hasVoted: new mapping(address => bool)(),
            proposalBlock: block.number,
            votingEndsBlock: block.number + govParams.votingPeriodBlocks,
            state: ProposalState.Active
        });

        emit ProposalCreated(
            proposalId,
            msg.sender,
            description,
            parameterIndex,
            newValue,
            proposals[proposalId].votingEndsBlock
        );
    }

    /// @notice Allows voting on an active proposal.
    /// @dev Requires the voter to have vote weight and not have voted already.
    /// @param proposalId The ID of the proposal.
    /// @param support True for supporting the proposal, false for opposing.
    function voteOnProposal(uint256 proposalId, bool support) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound(); // Check if proposal exists

        if (block.number > proposal.votingEndsBlock) revert VotingPeriodNotActive();
        if (proposal.state != ProposalState.Active) revert VotingPeriodNotActive();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 voteWeight = getVoteWeight(msg.sender);
        if (voteWeight == 0) revert InvalidVotingWeightCalculation(); // Or specific "NoVoteWeight" error

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.voteCountSupport += voteWeight;
        } else {
            proposal.voteCountOppose += voteWeight;
        }

        emit Voted(proposalId, msg.sender, support, voteWeight);
    }

    /// @notice Executes a proposal that has succeeded and whose voting period has ended.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public nonReentrant {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.id == 0) revert ProposalNotFound(); // Check if proposal exists

         if (proposal.state == ProposalState.Executed) revert CannotExecuteProposal(); // Already executed
         if (block.number <= proposal.votingEndsBlock) revert ProposalNotYetRunnable(); // Voting not over

         // Determine outcome if not already set
         if (proposal.state == ProposalState.Active) {
             if (proposal.voteCountSupport >= govParams.requiredVoteWeight) {
                 proposal.state = ProposalState.Succeeded;
             } else {
                 proposal.state = ProposalState.Failed;
             }
         }

         if (proposal.state != ProposalState.Succeeded) revert ProposalNotSucceeded();

         // --- Execute the parameter change ---
         if (proposal.parameterIndex == 0) {
             govParams.proposalThresholdAether = proposal.newValue;
         } else if (proposal.parameterIndex == 1) {
             govParams.votingPeriodBlocks = proposal.newValue;
         } else if (proposal.parameterIndex == 2) {
             govParams.requiredVoteWeight = proposal.newValue;
         }
         // Add more parameter index mappings here as needed

         proposal.state = ProposalState.Executed;

         emit ProposalExecuted(proposalId, proposal.parameterIndex, proposal.newValue);
    }

     /// @notice Gets the current state of a proposal.
     /// @param proposalId The ID of the proposal.
     /// @return The ProposalState enum value.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.id == 0) return ProposalState.Canceled; // Represents non-existent or effectively canceled if ID 0 is used

         // If voting is over but state is still active, determine final state
         if (proposal.state == ProposalState.Active && block.number > proposal.votingEndsBlock) {
             if (proposal.voteCountSupport >= govParams.requiredVoteWeight) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Failed;
             }
         }
         return proposal.state;
     }

     /// @notice Gets details about a specific proposal.
     /// @param proposalId The ID of the proposal.
     /// @return A tuple containing proposal details.
    function getProposalDetails(uint256 proposalId) public view returns (
         uint256 id,
         string memory description,
         uint256 parameterIndex,
         uint256 newValue,
         uint256 voteCountSupport,
         uint256 voteCountOppose,
         uint256 proposalBlock,
         uint256 votingEndsBlock,
         ProposalState state
     ) {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.id == 0) revert ProposalNotFound(); // Or return zeroed struct

         return (
             proposal.id,
             proposal.description,
             proposal.parameterIndex,
             proposal.newValue,
             proposal.voteCountSupport,
             proposal.voteCountOppose,
             proposal.proposalBlock,
             proposal.votingEndsBlock,
             getProposalState(proposalId) // Call helper to get current state
         );
     }


    // --- Internal Helpers ---

    /// @dev Internal function to set base attributes for a new Chronicle.
    /// @param tokenId The ID of the new Chronicle.
    /// @return The initialized Chronicle struct.
    function baseAttributesForNewChronicle(uint256 tokenId) internal pure returns (Chronicle memory) {
        // Basic starting attributes. Could be more complex, e.g., based on block properties, minter address, etc.
        return Chronicle({
            tokenId: tokenId,
            wisdom: 1,
            fortitude: 1,
            agility: 1,
            grace: 1,
            status: 0, // Dormant
            lastUpdatedBlock: 0, // Will be set after mint/first update
            stakedAether: 0,
            metadataURI: string(abi.encodePacked("initial/", uint2str(tokenId), ".json")) // Example initial URI
        });
    }

    /// @dev Internal helper to update Chronicle attributes and state after an action.
    /// @param tokenId The ID of the Chronicle.
    function _updateChronicleAttributes(uint256 tokenId) internal {
         // Any common logic after attributes change can go here.
         // E.g., checking status changes, logging the update block.
         chronicles[tokenId].lastUpdatedBlock = block.number;
         // The setChronicleStatus call happens in the calling function currently.
    }

    /// @dev Internal helper to calculate simulated staking rewards. Placeholder.
    /// @param staker The address of the staker.
    /// @return The amount of Aether rewards to claim.
    function _calculateStakingRewards(address staker) internal view returns (uint256) {
        // --- SIMPLIFIED PLACEHOLDER ---
        // A real system would use more complex logic involving:
        // - Time elapsed since last claim/stake (`block.number - lastRewardClaimBlock[staker]`)
        // - The amount `generalStakedAether[staker]`
        // - A global reward rate or pool size
        // This example gives a tiny fixed reward per block *since last claim* per staked Aether unit (scaled down).
        // WARNING: This simple logic can be exploitable or inefficient in a real scenario.

        if (generalStakedAether[staker] == 0) return 0;

        uint256 blocksStaked = block.number - lastRewardClaimBlock[staker];
        if (lastRewardClaimBlock[staker] == 0) blocksStaked = block.number; // Handle first claim/stake

        // Example: 1 Aether staked gains 1 wei per block (very low rate)
        uint256 rewardPerAetherPerBlock = 1; // wei per block
        // Scale Aether amount down assuming 18 decimals
        uint256 stakedAetherWhole = generalStakedAether[staker] / (10**18);

        uint256 potentialRewards = stakedAetherWhole * blocksStaked * rewardPerAetherPerBlock;

        // Further complexity could cap rewards, use a global pool, etc.
        return potentialRewards; // Returns a small amount for demonstration
    }


    /// @dev Internal helper to derive Chronicle status based on attributes.
    /// @param tokenId The ID of the Chronicle.
    /// @return The derived status (0, 1, or 2).
    function _deriveStatusFromAttributes(uint256 tokenId) internal view returns (uint8) {
         Chronicle storage chronicle = chronicles[tokenId];

         // Example thresholds - these could also be governance parameters
         uint256 totalCoreAttributes = chronicle.wisdom + chronicle.fortitude + chronicle.agility + chronicle.grace;

         if (totalCoreAttributes >= 100 && chronicle.stakedAether >= 50 * 10**18) { // Example: 100 total core points AND 50 Aether staked
             return 2; // Ascended
         } else if (totalCoreAttributes >= 50 || chronicle.stakedAether >= 10 * 10**18) { // Example: 50 total core points OR 10 Aether staked
             return 1; // Awakened
         } else {
             return 0; // Dormant
         }
         // Note: The status is just a derived property in this example, not an attribute *to* increase directly.
         // The setChronicleStatus function simply updates the state variable after this is called.
    }

    /// @dev Internal helper to check if an address meets eligibility criteria for proposing/voting.
    /// @param participant The address to check.
    /// @return True if eligible, false otherwise.
    function _checkVoteEligibility(address participant) internal view returns (bool) {
        // Currently, eligibility is having *any* vote weight.
        // Could add requirements like minimum time holding tokens/NFTs, specific NFT type, etc.
        return getVoteWeight(participant) > 0;
    }

    // --- Utility Function (Simple uint to string for events/metadata) ---
    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    // Modified slightly for internal use if needed in dynamic URI or events
    function uint2str(uint256 value) internal pure returns (string memory) {
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
}

```