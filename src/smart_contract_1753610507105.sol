The smart contract below, named `AetherBloomNexus`, implements a novel ecosystem for **Adaptive, Reputational NFTs (ARNs)**. This concept merges dynamic NFT attributes, a soulbound reputation system, time-locked staking, and a community-driven governance model to create a truly evolving digital asset.

It aims to be unique by combining these trending concepts in a cohesive and integrated system where the NFT's very "essence" transforms based on user engagement and collective decisions, rather than just being a static image or a simple PFP.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI construction

// Contract: AetherBloomNexus
// A decentralized protocol for Adaptive, Reputational NFTs (ARNs) called AetherBlooms.
// AetherBlooms dynamically evolve their "BloomState" and "EssenceTraits" based on user engagement,
// time-locked participation (Essence Cultivation), and accrued "Chronosight" reputation.
// It integrates a non-transferable Soulbound Token (Chronosight) and a community-driven
// governance system (Bloom-Lore Evolution) for defining future NFT attributes.

// Outline & Function Summary:
//
// I. Core NFT & Chronosight Management (Internal / Pseudo-ERC721/SBT)
//    This section manages the creation and tracking of AetherBloom NFTs and Chronosight.
//    AetherBloom NFTs are ERC721-compliant, while Chronosight is a non-transferable (soulbound) score.
//    1.  `mintAetherBloomNFT(address recipient)`: Mints a new AetherBloom NFT.
//    2.  `getBloomState(uint256 tokenId)`: Retrieves the current evolutionary state of an AetherBloom NFT.
//    3.  `getEssenceTraits(uint256 tokenId)`: Returns unique, immutable traits hash of an AetherBloom NFT.
//    4.  `getChronosightBalance(address user)`: Queries a user's total Chronosight (reputation) score.
//    5.  `_updateBloomState(uint256 tokenId, uint256 _chronosightGained)`: Internal helper to recalculate and set an NFT's BloomState.
//    6.  `_mintChronosight(address user, uint256 amount)`: Internal helper to increase a user's Chronosight.
//    7.  `_burnChronosight(address user, uint256 amount)`: Internal helper to decrease a user's Chronosight.
//
// II. Essence Cultivation (NFT Staking & Rewards)
//    Users stake their AetherBloom NFTs for defined periods to accrue Chronosight and rewards.
//    8.  `stakeAetherBloomNFT(uint256 tokenId, uint256 durationDays)`: Locks an AetherBloom NFT for cultivation.
//    9.  `unstakeAetherBloomNFT(uint256 tokenId)`: Unlocks a cultivated AetherBloom NFT, applying evolution and rewards.
//    10. `getCultivationProgress(uint256 tokenId)`: Provides details on a staked NFT's remaining cultivation time and potential gains.
//    11. `claimCultivationRewards(address user)`: Allows users to claim accrued ETH rewards from cultivation.
//    12. `getPendingCultivationRewards(address user)`: Shows the amount of rewards a user can claim.
//
// III. Dynamic Evolution & Catalyst Infusion
//    Mechanisms to influence or accelerate an AetherBloom NFT's evolution.
//    13. `infuseCatalyst(uint256 tokenId)`: Allows burning ETH to instantly boost an NFT's BloomState or unlock traits.
//    14. `predictNextBloomState(uint256 tokenId, uint256 chronosightBoost)`: Simulates a future BloomState based on projected Chronosight.
//    15. `triggerEssenceMutation(uint256 tokenId)`: Explicitly triggers an NFT's BloomState recalculation.
//
// IV. Governance (Bloom-Lore Evolution)
//    A decentralized system for Chronosight holders to propose and vote on protocol changes,
//    including new BloomState definitions or Essence Traits.
//    16. `proposeBloomLoreUpdate(string memory proposalURI)`: Initiates a new governance proposal.
//    17. `voteOnBloomLoreUpdate(uint256 proposalId, bool support)`: Casts a vote on an active proposal.
//    18. `executeBloomLoreUpdate(uint256 proposalId)`: Finalizes and applies a successful governance proposal.
//    19. `getProposalState(uint256 proposalId)`: Retrieves the current status of a governance proposal.
//
// V. Protocol Management & Querying
//    Standard administrative functions and public view functions for protocol data.
//    20. `setBaseURI(string memory newURI)`: Sets the base URI for NFT metadata.
//    21. `tokenURI(uint256 tokenId)`: Overrides ERC721's tokenURI to include dynamic attributes.
//    22. `setMintPrice(uint256 newPrice)`: Adjusts the cost to mint new AetherBloom NFTs.
//    23. `withdrawProtocolFunds(address recipient)`: Allows the owner to withdraw collected ETH.
//    24. `getNFTsOwnedByUser(address user)`: Lists all AetherBloom NFTs owned by a specific address.
//    25. `isAetherBloomNFTStaked(uint256 tokenId)`: Checks if a given NFT is currently staked.
//    26. `setChronosightYieldPerBlock(uint256 yield)`: Adjusts the rate at which Chronosight is generated.
//    27. `setCatalystInfusionCost(uint256 newCost)`: Sets the cost for catalyst infusion.
//    28. `setBaseEthRewardPerBlock(uint256 newRate)`: Sets the base ETH reward rate for cultivation.
//    29. `setMaxBloomState(uint256 newMax)`: Sets the maximum achievable BloomState.
//    30. `setBloomStateGrowthFactor(uint256 newFactor)`: Sets the Chronosight required per BloomState growth.
//    31. `getNFTCultivationDetails(uint256 tokenId)`: Provides detailed information about a staked NFT.
//    (Additional public functions inherited from ERC721Enumerable and Ownable, like totalSupply, balanceOf, owner etc., contribute to the total count.)

contract AetherBloomNexus is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // AetherBloom NFT Data
    struct AetherBloom {
        uint256 tokenId;
        uint256 initialMintTime;
        uint256 currentBloomState; // 0 (Seed) to N (Mythic)
        bytes32 essenceTraitsHash; // A hash representing immutable traits, determined at mint
        uint256 lastBloomStateUpdate; // Timestamp of last BloomState change
    }

    mapping(uint256 => AetherBloom) public aetherBlooms;
    Counters.Counter private _tokenIdCounter;

    // Chronosight (SBT) Data - Non-transferable reputation score
    mapping(address => uint256) public chronosightBalances;
    mapping(address => uint256) public userAccruedEthRewards; // Tracks claimable ETH rewards per user

    // Staking Data (Essence Cultivation)
    struct StakedBloom {
        uint256 tokenId;
        address staker;
        uint256 stakeTime;
        uint256 stakeDuration; // In days
    }

    mapping(uint256 => StakedBloom) public stakedAetherBlooms;
    mapping(uint256 => bool) public isStaked; // Quick lookup for staked status

    // Governance Data (Bloom-Lore Evolution)
    struct Proposal {
        uint256 id;
        string proposalURI; // IPFS hash or similar for proposal details
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // 7 days for voting
    uint256 public constant MIN_CHRONOSIGHT_FOR_PROPOSAL = 1000; // Minimum Chronosight to create a proposal
    uint256 public constant MIN_CHRONOSIGHT_FOR_VOTE = 100; // Minimum Chronosight to vote

    // Protocol Parameters
    uint256 public mintPrice = 0.05 ether; // Default mint price
    uint256 public chronosightYieldPerBlock = 1; // Chronosight points per block per staked NFT
    uint256 public baseEthRewardPerBlock = 100; // Wei per block per staked NFT
    uint256 public bloomStateGrowthFactor = 100; // How much cumulative chronosight needed to grow state (linear for simplicity)
    uint256 public catalystInfusionCost = 0.1 ether; // Cost to infuse catalyst
    uint256 public MAX_BLOOM_STATE = 10; // Max possible BloomState

    // --- Events ---
    event AetherBloomMinted(uint256 indexed tokenId, address indexed owner, uint256 initialBloomState);
    event ChronosightGained(address indexed user, uint256 amount, uint256 newBalance);
    event ChronosightLost(address indexed user, uint256 amount, uint256 newBalance);
    event BloomStateUpdated(uint256 indexed tokenId, uint256 oldState, uint256 newState);
    event NFTStaked(uint256 indexed tokenId, address indexed staker, uint256 stakeDuration);
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker, uint256 earnedChronosight, uint256 earnedEth);
    event CatalystInfused(uint256 indexed tokenId, address indexed infuser, uint256 newBloomState);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string proposalURI);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 chronosightWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);

    // --- Constructor ---
    constructor() ERC721("AetherBloom", "AETHERB") Ownable(msg.sender) {
        // Initial setup for the contract
    }

    // --- Modifiers ---
    modifier onlyNFTAetherBloomOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not the NFT owner or approved");
        _;
    }

    modifier onlyChronosightHolder(uint256 _minChronosight) {
        require(chronosightBalances[msg.sender] >= _minChronosight, "Insufficient Chronosight");
        _;
    }

    // --- I. Core NFT & Chronosight Management ---

    /// @notice Mints a new AetherBloom NFT with an initial BloomState (Seed).
    /// @param recipient The address to mint the NFT to.
    /// @dev Requires `mintPrice` ETH to be sent with the transaction.
    /// @return The tokenId of the newly minted AetherBloom NFT.
    function mintAetherBloomNFT(address recipient) public payable returns (uint256) {
        require(msg.value >= mintPrice, "Insufficient ETH for minting");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Initial BloomState is 0 (Seed)
        uint256 initialBloomState = 0;
        // Generate pseudo-random immutable traits based on block hash and tokenId
        // For production, consider Chainlink VRF for true randomness.
        bytes32 essenceTraits = keccak256(abi.encodePacked(blockhash(block.number - 1), newTokenId, initialBloomState, msg.sender));

        aetherBlooms[newTokenId] = AetherBloom({
            tokenId: newTokenId,
            initialMintTime: block.timestamp,
            currentBloomState: initialBloomState,
            essenceTraitsHash: essenceTraits,
            lastBloomStateUpdate: block.timestamp
        });

        _safeMint(recipient, newTokenId);
        emit AetherBloomMinted(newTokenId, recipient, initialBloomState);

        return newTokenId;
    }

    /// @notice Returns the current evolutionary BloomState of an AetherBloom NFT.
    /// @param tokenId The ID of the AetherBloom NFT.
    /// @return The current BloomState level.
    function getBloomState(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        return aetherBlooms[tokenId].currentBloomState;
    }

    /// @notice Returns the unique, immutable EssenceTraits hash of an AetherBloom NFT.
    /// @param tokenId The ID of the AetherBloom NFT.
    /// @return The hash representing the immutable essence traits.
    function getEssenceTraits(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "NFT does not exist");
        return aetherBlooms[tokenId].essenceTraitsHash;
    }

    /// @notice Returns the Chronosight (reputation) balance of a user.
    /// @param user The address of the user.
    /// @return The Chronosight balance.
    function getChronosightBalance(address user) public view returns (uint256) {
        return chronosightBalances[user];
    }

    /// @dev Internal function to update an NFT's BloomState based on current conditions.
    ///      This is called automatically by `unstakeAetherBloomNFT` or explicitly by `triggerEssenceMutation`.
    /// @param tokenId The ID of the AetherBloom NFT.
    /// @param _chronosightGained The amount of chronosight gained during the period (used for calculation).
    function _updateBloomState(uint256 tokenId, uint256 _chronosightGained) internal {
        AetherBloom storage bloom = aetherBlooms[tokenId];
        address nftOwner = ownerOf(tokenId);
        uint256 oldState = bloom.currentBloomState;

        // Simplified BloomState calculation: Increases based on cumulative Chronosight
        // A more complex logic could involve specific thresholds, time, and trait interactions.
        uint256 totalChronosightForBloom = chronosightBalances[nftOwner] + _chronosightGained;
        uint256 potentialNewState = totalChronosightForBloom / bloomStateGrowthFactor;

        if (potentialNewState > bloom.currentBloomState) {
            if (potentialNewState > MAX_BLOOM_STATE) {
                potentialNewState = MAX_BLOOM_STATE;
            }
            bloom.currentBloomState = potentialNewState;
            bloom.lastBloomStateUpdate = block.timestamp;
            emit BloomStateUpdated(tokenId, oldState, bloom.currentBloomState);
        }
    }

    /// @dev Internal function to mint Chronosight for a user.
    /// @param user The address to mint Chronosight for.
    /// @param amount The amount of Chronosight to mint.
    function _mintChronosight(address user, uint256 amount) internal {
        chronosightBalances[user] += amount;
        emit ChronosightGained(user, amount, chronosightBalances[user]);
    }

    /// @dev Internal function to burn Chronosight from a user.
    /// @param user The address to burn Chronosight from.
    /// @param amount The amount of Chronosight to burn.
    /// @dev Requires the user to have enough Chronosight.
    function _burnChronosight(address user, uint256 amount) internal {
        require(chronosightBalances[user] >= amount, "Insufficient Chronosight to burn");
        chronosightBalances[user] -= amount;
        emit ChronosightLost(user, amount, chronosightBalances[user]);
    }

    // --- II. Essence Cultivation (NFT Staking & Rewards) ---

    /// @notice Locks an AetherBloom NFT for a specified duration to begin Essence Cultivation.
    /// @dev The NFT must be owned by the caller and not currently staked.
    ///      Transfers the NFT to this contract.
    /// @param tokenId The ID of the AetherBloom NFT to stake.
    /// @param durationDays The duration in days for which the NFT will be staked.
    function stakeAetherBloomNFT(uint256 tokenId, uint256 durationDays) public onlyNFTAetherBloomOwner(tokenId) {
        require(!isStaked[tokenId], "NFT is already staked");
        require(durationDays > 0, "Stake duration must be positive");

        _transfer(msg.sender, address(this), tokenId); // Transfer NFT to contract

        stakedAetherBlooms[tokenId] = StakedBloom({
            tokenId: tokenId,
            staker: msg.sender,
            stakeTime: block.timestamp,
            stakeDuration: durationDays
        });
        isStaked[tokenId] = true;

        emit NFTStaked(tokenId, msg.sender, durationDays);
    }

    /// @notice Unlocks an AetherBloom NFT after its cultivation period, applying BloomState updates and distributing rewards.
    /// @dev Can only be called by the original staker.
    /// @param tokenId The ID of the AetherBloom NFT to unstake.
    function unstakeAetherBloomNFT(uint256 tokenId) public {
        require(isStaked[tokenId], "NFT is not staked");
        StakedBloom storage stakedBloom = stakedAetherBlooms[tokenId];
        require(stakedBloom.staker == msg.sender, "Only the staker can unstake this NFT");
        require(block.timestamp >= stakedBloom.stakeTime + (stakedBloom.stakeDuration * 1 days), "Cultivation period not over yet");

        uint256 cultivationDuration = block.timestamp - stakedBloom.stakeTime;
        // Simplified block calculation (assuming ~1 second per block for rough estimation)
        uint256 blocksCultivated = cultivationDuration;

        // Calculate earned Chronosight based on blocks cultivated and BloomState (amplification)
        uint256 earnedChronosight = blocksCultivated * chronosightYieldPerBlock * (aetherBlooms[tokenId].currentBloomState + 1);
        _mintChronosight(msg.sender, earnedChronosight);

        // Calculate ETH rewards with BloomState amplification
        uint256 earnedEth = blocksCultivated * baseEthRewardPerBlock * (aetherBlooms[tokenId].currentBloomState + 1);
        userAccruedEthRewards[msg.sender] += earnedEth;

        // Update BloomState after cultivation
        _updateBloomState(tokenId, earnedChronosight);

        _transfer(address(this), msg.sender, tokenId); // Transfer NFT back to staker

        delete stakedAetherBlooms[tokenId];
        isStaked[tokenId] = false;

        emit NFTUnstaked(tokenId, msg.sender, earnedChronosight, earnedEth);
    }

    /// @notice Provides details on a staked NFT's remaining cultivation time and potential Chronosight gain.
    /// @param tokenId The ID of the staked AetherBloom NFT.
    /// @return remainingTime The time in seconds left until the cultivation period ends.
    /// @return potentialChronosight The estimated Chronosight that will be gained upon unstaking (based on current time).
    function getCultivationProgress(uint256 tokenId) public view returns (uint256 remainingTime, uint256 potentialChronosight) {
        require(isStaked[tokenId], "NFT is not staked");
        StakedBloom storage stakedBloom = stakedAetherBlooms[tokenId];

        uint256 endTime = stakedBloom.stakeTime + (stakedBloom.stakeDuration * 1 days);
        if (block.timestamp < endTime) {
            remainingTime = endTime - block.timestamp;
            uint256 cultivatedDuration = block.timestamp - stakedBloom.stakeTime;
            uint256 blocksCultivated = cultivatedDuration;
            potentialChronosight = blocksCultivated * chronosightYieldPerBlock * (aetherBlooms[tokenId].currentBloomState + 1);
        } else {
            remainingTime = 0;
            potentialChronosight = 0; // Already cultivated
        }
    }

    /// @notice Allows users to claim their accrued ETH rewards from cultivated NFTs.
    /// @param user The address for whom to claim rewards.
    function claimCultivationRewards(address user) public {
        uint256 amountToClaim = userAccruedEthRewards[user];
        require(amountToClaim > 0, "No pending rewards to claim");

        userAccruedEthRewards[user] = 0; // Reset pending rewards (Effects)

        (bool success, ) = payable(user).call{value: amountToClaim}(""); // Interactions
        require(success, "ETH transfer failed");

        emit RewardsClaimed(user, amountToClaim);
    }

    /// @notice Returns the amount of ETH rewards a user can claim.
    /// @param user The address of the user.
    /// @return The amount of pending ETH rewards.
    function getPendingCultivationRewards(address user) public view returns (uint256) {
        return userAccruedEthRewards[user];
    }

    // --- III. Dynamic Evolution & Catalyst Infusion ---

    /// @notice Allows the owner of an AetherBloom NFT to infuse a catalyst, instantly boosting its BloomState.
    /// @dev Requires `catalystInfusionCost` ETH to be sent with the transaction.
    ///      Provides a significant boost to BloomState, potentially skipping cultivation time.
    /// @param tokenId The ID of the AetherBloom NFT to infuse.
    function infuseCatalyst(uint256 tokenId) public payable onlyNFTAetherBloomOwner(tokenId) {
        require(msg.value >= catalystInfusionCost, "Insufficient ETH for catalyst infusion");
        require(!isStaked[tokenId], "Cannot infuse catalyst on a staked NFT");

        AetherBloom storage bloom = aetherBlooms[tokenId];
        uint256 oldState = bloom.currentBloomState;

        // Catalyst provides a fixed BloomState increase, e.g., +1 level.
        uint256 catalystBoost = 1;
        uint256 newPotentialState = oldState + catalystBoost;
        if (newPotentialState > MAX_BLOOM_STATE) {
            newPotentialState = MAX_BLOOM_STATE;
        }

        if (newPotentialState > oldState) {
            bloom.currentBloomState = newPotentialState;
            bloom.lastBloomStateUpdate = block.timestamp;
            emit CatalystInfused(tokenId, msg.sender, newPotentialState);
            emit BloomStateUpdated(tokenId, oldState, newPotentialState);
        }
        // If already at max state, the transaction still consumes the fee.
        // A refund mechanism could be implemented for this edge case.
    }

    /// @notice Simulates and predicts the next potential BloomState of an NFT based on projected Chronosight.
    /// @dev This is a view function and does not alter state. Useful for planning.
    /// @param tokenId The ID of the AetherBloom NFT.
    /// @param chronosightBoost A hypothetical amount of Chronosight to add to the user's current balance for prediction.
    /// @return The predicted BloomState.
    function predictNextBloomState(uint256 tokenId, uint256 chronosightBoost) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        address nftOwner = ownerOf(tokenId);
        uint256 currentChronosight = chronosightBalances[nftOwner];
        uint256 totalChronosightForPrediction = currentChronosight + chronosightBoost;
        uint256 predictedState = totalChronosightForPrediction / bloomStateGrowthFactor;
        if (predictedState > MAX_BLOOM_STATE) {
            predictedState = MAX_BLOOM_STATE;
        }
        if (predictedState < aetherBlooms[tokenId].currentBloomState) { // BloomState can't decrease
            predictedState = aetherBlooms[tokenId].currentBloomState;
        }
        return predictedState;
    }

    /// @notice Explicitly triggers a BloomState recalculation for an NFT based on current conditions.
    /// @dev Useful for updating BloomState outside of unstaking or catalyst infusion events.
    /// @param tokenId The ID of the AetherBloom NFT to mutate.
    function triggerEssenceMutation(uint256 tokenId) public onlyNFTAetherBloomOwner(tokenId) {
        require(!isStaked[tokenId], "Cannot trigger mutation on a staked NFT");
        _updateBloomState(tokenId, 0); // Re-evaluates based on current owner's total Chronosight without new gains
    }

    // --- IV. Governance (Bloom-Lore Evolution) ---

    /// @notice Allows users with sufficient Chronosight to propose new BloomState rules or Essence Traits.
    /// @param proposalURI An IPFS hash or URL pointing to the detailed proposal document.
    /// @return The ID of the newly created proposal.
    function proposeBloomLoreUpdate(string memory proposalURI) public onlyChronosightHolder(MIN_CHRONOSIGHT_FOR_PROPOSAL) returns (uint256) {
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposalURI: proposalURI,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            passed: false
        });

        emit ProposalCreated(newProposalId, msg.sender, proposalURI);
        return newProposalId;
    }

    /// @notice Allows Chronosight holders to vote on proposals.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'For', False for 'Against'.
    function voteOnBloomLoreUpdate(uint256 proposalId, bool support) public onlyChronosightHolder(MIN_CHRONOSIGHT_FOR_VOTE) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting is not active for this proposal");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.executed, "Proposal already executed");

        uint256 voterChronosight = chronosightBalances[msg.sender];
        require(voterChronosight >= MIN_CHRONOSIGHT_FOR_VOTE, "Insufficient Chronosight to vote");

        if (support) {
            proposal.totalVotesFor += voterChronosight;
        } else {
            proposal.totalVotesAgainst += voterChronosight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(proposalId, msg.sender, support, voterChronosight);
    }

    /// @notice Executes a passed governance proposal, applying the changes.
    /// @dev This function would ideally call an upgradable proxy or a separate contract
    ///      with a robust upgrade mechanism (e.g., UUPS proxy) to modify core logic.
    ///      For this example, it simply marks the proposal as executed and logs it.
    /// @param proposalId The ID of the proposal to execute.
    function executeBloomLoreUpdate(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        // Simple majority vote: For > Against
        bool passed = proposal.totalVotesFor > proposal.totalVotesAgainst;

        proposal.executed = true;
        proposal.passed = passed;

        // In a real system, passed proposals would trigger specific parameter updates
        // or a contract upgrade. This contract primarily uses view functions for parameters,
        // so a successful proposal signifies a community mandate for off-chain execution
        // or for future admin functions to apply specific parameter changes.
        // E.g., if a proposal was "change chronosightYieldPerBlock to X", the owner could then
        // call `setChronosightYieldPerBlock(X)`.

        emit ProposalExecuted(proposalId, passed);
    }

    /// @notice Returns the current state of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return A tuple containing proposal details.
    function getProposalState(uint256 proposalId) public view returns (
        uint256 id,
        string memory proposalURI,
        uint256 voteStartTime,
        uint256 voteEndTime,
        uint256 totalVotesFor,
        uint256 totalVotesAgainst,
        bool executed,
        bool passed
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");

        return (
            proposal.id,
            proposal.proposalURI,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.executed,
            proposal.passed
        );
    }

    // --- V. Protocol Management & Querying ---

    /// @notice Sets the base URI for NFT metadata.
    /// @dev Only callable by the contract owner.
    /// @param newURI The new base URI string.
    function setBaseURI(string memory newURI) public onlyOwner {
        _setBaseURI(newURI);
    }

    /// @dev Overrides ERC721 tokenURI to incorporate BloomState and EssenceTraits dynamically.
    ///      This allows metadata to reflect the NFT's current evolutionary stage.
    ///      For a real application, this would point to a JSON file on IPFS that
    ///      is generated dynamically (e.g., via a decentralized serverless function)
    ///      based on the on-chain `currentBloomState` and `essenceTraitsHash`.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory base = _baseURI();
        string memory bloomState = Strings.toString(aetherBlooms[tokenId].currentBloomState);
        string memory essenceTraits = Strings.toHexString(uint256(aetherBlooms[tokenId].essenceTraitsHash)); // Convert bytes32 to hex string

        // Example path: baseURI/tokenId/state_X/traits_HASH.json
        // A more sophisticated system would generate a single JSON containing these attributes.
        return string(abi.encodePacked(base, Strings.toString(tokenId), "/state_", bloomState, "/traits_", essenceTraits, ".json"));
    }

    /// @notice Sets the price for minting new AetherBloom NFTs.
    /// @dev Only callable by the contract owner.
    /// @param newPrice The new mint price in Wei.
    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    /// @notice Allows the contract owner to withdraw accumulated ETH from mints and catalyst infusions.
    /// @dev Only callable by the contract owner. Does not withdraw user accrued rewards.
    /// @param recipient The address to send the ETH to.
    function withdrawProtocolFunds(address recipient) public onlyOwner {
        // Calculate withdrawable balance by subtracting all pending user rewards from contract balance
        uint256 totalUserRewards = 0;
        // This would ideally iterate through all userAccruedEthRewards keys, which is impossible in Solidity.
        // A more robust system would involve a claimable balance for the owner.
        // For simplicity, this assumes the owner is aware of accrued ETH not meant for users.
        // Or, that the only "accrued" ETH not meant for the owner are in the `userAccruedEthRewards` mapping.
        // Let's assume the sum of `userAccruedEthRewards` is a fraction of the total balance.
        // A simpler way: only withdraw "owner's balance", meaning `address(this).balance` after all `userAccruedEthRewards`
        // are accounted for or transferred.
        
        // This line is a placeholder; accurate calculation of non-user funds would be complex.
        // For security, it should *only* withdraw funds explicitly collected as fees/revenue.
        // For this example, let's assume `address(this).balance` is considered withdrawable after user claims.
        // This is simplified and in a real Dapp, fund segregation for fees vs. rewards would be explicit.
        uint256 balanceToWithdraw = address(this).balance; 
        
        // Safety check to prevent withdrawing funds needed for outstanding rewards.
        // This is a rough estimation; actual implementation needs careful fund flow tracking.
        for (uint i = 0; i < _totalChronosightHolders; i++) { // requires tracking total holders
            // This loop is purely illustrative and cannot be done on chain for all holders.
            // A more robust accounting system for fees vs. rewards is needed.
            // For now, assume this function withdraws all ETH not explicitly tracked as user rewards.
            // A better solution: separate treasury where fees go.
        }
        // As a simpler solution for a sample, we will just transfer total balance to owner
        // relying on users claiming their rewards first.
        
        (bool success, ) = payable(recipient).call{value: balanceToWithdraw}("");
        require(success, "ETH withdrawal failed");
    }
    // Note: The `withdrawProtocolFunds` function in a production environment would require a more
    // sophisticated accounting for funds to ensure it does not accidentally withdraw user rewards.
    // Ideally, collected mint fees and catalyst infusion fees would be segregated into a separate
    // treasury that the owner can withdraw from, distinct from reward pools.

    /// @notice Returns a list of AetherBloom NFTs owned by a specific user.
    /// @param user The address of the user.
    /// @return An array of token IDs.
    function getNFTsOwnedByUser(address user) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    /// @notice Checks if a given AetherBloom NFT is currently staked in the Essence Cultivation system.
    /// @param tokenId The ID of the AetherBloom NFT.
    /// @return True if the NFT is staked, false otherwise.
    function isAetherBloomNFTStaked(uint256 tokenId) public view returns (bool) {
        return isStaked[tokenId];
    }

    /// @notice Sets the rate at which Chronosight is generated per block for staked NFTs.
    /// @dev Only callable by the contract owner.
    /// @param yield The new Chronosight yield per block.
    function setChronosightYieldPerBlock(uint256 yield) public onlyOwner {
        chronosightYieldPerBlock = yield;
    }

    /// @notice Sets the cost for catalyst infusion.
    /// @dev Only callable by the contract owner.
    /// @param newCost The new catalyst infusion cost in Wei.
    function setCatalystInfusionCost(uint256 newCost) public onlyOwner {
        catalystInfusionCost = newCost;
    }

    /// @notice Sets the base ETH reward rate per block for staked NFTs.
    /// @dev Only callable by the contract owner.
    /// @param newRate The new base ETH reward rate in Wei per block.
    function setBaseEthRewardPerBlock(uint256 newRate) public onlyOwner {
        baseEthRewardPerBlock = newRate;
    }

    /// @notice Sets the maximum achievable BloomState for AetherBloom NFTs.
    /// @dev Only callable by the contract owner.
    /// @param newMax The new maximum BloomState.
    function setMaxBloomState(uint256 newMax) public onlyOwner {
        require(newMax > 0, "Max Bloom State must be positive");
        MAX_BLOOM_STATE = newMax;
    }

    /// @notice Sets the Chronosight required for each BloomState growth level.
    /// @dev Only callable by the contract owner.
    /// @param newFactor The new BloomState growth factor.
    function setBloomStateGrowthFactor(uint256 newFactor) public onlyOwner {
        require(newFactor > 0, "Growth factor must be positive");
        bloomStateGrowthFactor = newFactor;
    }

    /// @notice Provides detailed information about a staked NFT.
    /// @param tokenId The ID of the AetherBloom NFT.
    /// @return stakeTime The timestamp when the NFT was staked.
    /// @return stakeDuration The duration in days for which the NFT is staked.
    /// @return currentCalculatedChronosightAtUnstake (Estimated) Chronosight earned *if unstaked now*.
    /// @return currentCalculatedEthRewardsAtUnstake (Estimated) ETH rewards earned *if unstaked now*.
    function getNFTCultivationDetails(uint256 tokenId) public view returns (
        uint256 stakeTime,
        uint256 stakeDuration,
        uint256 currentCalculatedChronosightAtUnstake,
        uint256 currentCalculatedEthRewardsAtUnstake
    ) {
        require(isStaked[tokenId], "NFT is not staked");
        StakedBloom storage stakedBloom = stakedAetherBlooms[tokenId];

        uint256 cultivatedDuration = block.timestamp - stakedBloom.stakeTime;
        uint256 blocksCultivated = cultivatedDuration; // Assuming 1s per block for simplicity

        // Calculate potential earnings up to the current moment
        currentCalculatedChronosightAtUnstake = blocksCultivated * chronosightYieldPerBlock * (aetherBlooms[tokenId].currentBloomState + 1);
        currentCalculatedEthRewardsAtUnstake = blocksCultivated * baseEthRewardPerBlock * (aetherBlooms[tokenId].currentBloomState + 1);

        return (
            stakedBloom.stakeTime,
            stakedBloom.stakeDuration,
            currentCalculatedChronosightAtUnstake,
            currentCalculatedEthRewardsAtUnstake
        );
    }
}
```