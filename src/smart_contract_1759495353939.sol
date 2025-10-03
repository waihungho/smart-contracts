The smart contract below, `EpochalNexus`, introduces a unique and advanced concept for a dynamic NFT (dNFT) and gamified protocol governance system. It combines elements of state-driven evolution, on-chain challenges, and strategic token/NFT staking to create an adaptive and interactive decentralized application.

**Core Concept: EpochalNexus**

The `EpochalNexus` protocol manages two primary assets:
1.  **NexusTokens (NXT - ERC20):** The protocol's native utility and governance token.
2.  **EpochalShards (EPS - Dynamic ERC721 NFTs):** Unique digital assets that visually and functionally evolve based on global protocol "Epochs" and their participation in "Challenges."

**Key Advanced Concepts:**

*   **Dynamic NFTs (dNFTs):** EpochalShards possess mutable metadata and on-chain traits that change over time based on protocol state (Epochs) and their owners' actions (staking in Challenges, successful outcomes). The `tokenURI` dynamically points to metadata reflecting this evolution.
*   **Epoch-Driven Protocol State:** The protocol operates in distinct "Epochs," which are global state periods. Advancing an Epoch can trigger specific rules, challenge types, or NFT evolutions.
*   **Gamified Governance via Challenges:** Instead of simple voting, governance is gamified through "Challenges." NexusToken holders propose and vote on these challenges. Once active, EpochalShard owners can "stake" their NFTs into them.
*   **Strategic Staking & Evolution:** Staking an EpochalShard into a Challenge is a strategic decision. Successful challenge outcomes reward participants and influence the staked Shard's traits and history, contributing to its unique evolution. Failed challenges might incur penalties or stagnate shard evolution.
*   **Access Control with Roles:** Utilizes OpenZeppelin's `AccessControl` for granular permissions, going beyond a simple `onlyOwner` pattern to delegate specific responsibilities (e.g., `EPOCH_MANAGER`, `CHALLENGE_RESOLVER`).
*   **Pausable Functionality:** Implements `Pausable` for emergency stops on critical operations, enhancing security.
*   **Reentrancy Guard:** Protects against reentrancy attacks in functions involving external calls or token transfers.

---

**Outline & Function Summary**

**Contract Name:** `EpochalNexus`

This contract introduces a novel "EpochalNexus" protocol managing "NexusTokens" (ERC20) and "EpochalShards" (dynamic ERC721 NFTs). It features a gamified governance system centered around "Challenges" that evolve the protocol's global state ("Epochs") and the NFTs themselves.

**I. Core & Access Control**
1.  **constructor**: Initializes the contract with an admin, ERC20/ERC721 details, and initial epoch. Sets up roles for refined access control.
2.  **grantRole**: Grants a specific permission role to an address (e.g., `EPOCH_MANAGER_ROLE`).
3.  **revokeRole**: Revokes a specific permission role from an address.
4.  **hasRole**: Checks if an address has a role.
5.  **getRoleAdmin**: Returns the admin role for a given role.
6.  **pause**: Pauses critical contract operations (e.g., minting, challenge execution) in emergencies.
7.  **unpause**: Resumes paused contract operations.

**II. NexusToken (ERC20) Management**
8.  **mintNexusTokens**: Mints new NexusTokens, primarily used for rewards or initial distribution.
9.  **burnNexusTokens**: Allows users to burn their NexusTokens, acting as a supply sink.
10. **transfer**: Standard ERC20 function to transfer tokens.
11. **approve**: Standard ERC20 function to approve a spender.
12. **transferFrom**: Standard ERC20 function for approved transfers.
13. **balanceOf**: Standard ERC20 function to check balance.
14. **allowance**: Standard ERC20 function to check allowance.

**III. EpochalShard (Dynamic ERC721 NFT) Management**
15. **mintEpochalShard**: Mints a new EpochalShard NFT to a recipient, assigning initial intrinsic traits.
16. **tokenURI**: Provides a dynamic URI for the NFT's metadata, reflecting its current state and evolution.
17. **evolveShardMetadata**: Triggers the internal logic to update a specific EpochalShard's metadata/traits based on its history and current epoch conditions.
18. **getShardTraits**: Retrieves the current dynamic traits and attributes of an EpochalShard.
19. **getShardHistory**: Returns a record of challenges and epochs an EpochalShard has participated in, influencing its future evolution.
20. **transferFrom**: Standard ERC721 function to transfer ownership.
21. **safeTransferFrom**: Standard ERC721 function for safe transfer.
22. **approve**: Standard ERC721 function to approve an address for transfer.
23. **getApproved**: Standard ERC721 function to get approved address.
24. **setApprovalForAll**: Standard ERC721 function to set approval for all tokens by an operator.
25. **isApprovedForAll**: Standard ERC721 function to check operator approval.
26. **ownerOf**: Standard ERC721 function to get the owner of a token.
27. **balanceOf**: Standard ERC721 function to check token count of an owner.

**IV. Epoch & Protocol State Management**
28. **advanceEpoch**: A permissioned function that transitions the protocol to the next global Epoch, potentially triggering cascading effects on challenges and NFTs.
29. **getCurrentEpoch**: Returns detailed information about the protocol's current Epoch.
30. **setEpochTransitionConditions**: Configures the criteria (e.g., time, challenge success rate) required to advance to a new Epoch.

**V. Gamified Governance & Challenges**
31. **proposeChallenge**: Allows NexusToken holders to propose a new protocol Challenge, requiring a token stake.
32. **voteOnChallengeProposal**: Enables NexusToken holders to vote on proposed Challenges, influencing which ones proceed.
33. **executeChallenge**: A permissioned function to officially start an approved Challenge.
34. **stakeShardForChallenge**: Allows EpochalShard owners to stake their NFTs into an active Challenge, influencing its outcome and potentially earning rewards.
35. **unstakeShardFromChallenge**: Permits owners to unstake their EpochalShards from a Challenge once it's resolved or under specific conditions.
36. **resolveChallenge**: A permissioned function to finalize a Challenge, determining its outcome, distributing rewards/penalties, and updating staked Shards.
37. **claimChallengeRewards**: Allows participants to claim their earned NexusTokens or other rewards from a successfully resolved Challenge.
38. **getChallengeDetails**: Provides comprehensive information about any specific Challenge.
39. **getUserStakedChallenges**: Lists challenges a user has staked shards in.

**VI. Economic & Fee Management**
40. **setProtocolFeeRecipient**: Sets the address for protocol fees.
41. **withdrawProtocolFees**: Allows the fee recipient to withdraw accumulated fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EpochalNexus is Context, ERC20, ERC721, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Role Definitions ---
    bytes32 public constant EPOCH_MANAGER_ROLE = keccak256("EPOCH_MANAGER_ROLE");
    bytes32 public constant CHALLENGE_RESOLVER_ROLE = keccak256("CHALLENGE_RESOLVER_ROLE");

    // --- ERC20: NexusToken (NXT) ---
    // Inherited from ERC20: name(), symbol(), decimals(), totalSupply(), balanceOf(), transfer(), approve(), transferFrom(), allowance()

    // --- ERC721: EpochalShard (EPS) ---
    Counters.Counter private _epochalShardIds;
    string private _baseTokenURI;
    // Inherited from ERC721: name(), symbol(), ownerOf(), balanceOf(), approve(), getApproved(), setApprovalForAll(), isApprovedForAll(), transferFrom(), safeTransferFrom()

    // --- Epoch Management ---
    struct Epoch {
        uint256 id;
        uint256 startTime;
        uint256 endTime; // 0 if active
        string description;
        uint256 minChallengesResolved; // Condition for next epoch
        uint256 minParticipationRate; // % (0-100) of shards staked for challenges for next epoch
        uint255 protocolFeesAccrued;
    }
    uint256 public currentEpochId;
    mapping(uint256 => Epoch) public epochs;
    uint256 public nextEpochStartTime; // Timestamp when next epoch can potentially start

    // --- EpochalShard Dynamic Traits ---
    enum ShardAffinity { COSMIC, TERRESTRIAL, ASTRAL, VOID }
    enum ShardModifier { NEUTRAL, ENHANCED, CORRUPTED, STABLE }

    struct ShardTraits {
        ShardAffinity intrinsicAffinity; // Immutable upon mint
        ShardModifier currentModifier;   // Dynamic, evolves based on history
        uint256 epochParticipationCount; // Number of epochs shard was active
        uint256 challengeSuccessCount;   // Number of challenges shard contributed to successfully
        uint256 lastEvolutionEpoch;      // Last epoch ID when traits were evolved
    }
    mapping(uint256 => ShardTraits) public epochalShardTraits; // tokenId => ShardTraits

    struct ShardChallengeHistory {
        uint256 challengeId;
        bool success;
        uint256 timestamp;
    }
    mapping(uint256 => ShardChallengeHistory[]) public epochalShardHistories; // tokenId => array of histories

    // --- Gamified Governance & Challenges ---
    enum ChallengeStatus { PROPOSED, VOTING, ACTIVE, RESOLVED_SUCCESS, RESOLVED_FAILURE, CANCELLED }

    struct ChallengeProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 nexusStakeRequired; // NXT required to propose
        uint256 voteThreshold;      // Minimum NXT votes required to pass
        uint256 startTime;          // When proposal was made
        uint256 votingEndTime;      // When voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 challengeDuration;  // Duration if challenge goes active (in seconds)
        uint256 rewardPool;         // NXT reward for successful completion
        ChallengeStatus status;
        // Specifics for challenge success/failure conditions (can be complex, simplified here)
        uint256 minShardsStaked;
    }
    Counters.Counter private _challengeProposalIds;
    mapping(uint256 => ChallengeProposal) public challengeProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnChallenge; // challengeId => voter => voted

    struct ActiveChallenge {
        uint256 id;
        uint256 proposalId;
        uint256 startTime;
        uint256 endTime;
        mapping(uint256 => bool) stakedShards; // tokenId => isStaked
        uint256 totalStakedShards;
        address[] participants; // List of addresses that staked shards
        mapping(address => uint256[]) userStakedShards; // user => list of tokenIds
        ChallengeStatus status;
        uint256 rewardPool;
    }
    mapping(uint256 => ActiveChallenge) public activeChallenges; // challengeId (from proposalId) => ActiveChallenge
    uint256[] public activeChallengeIds; // To iterate over active challenges

    // --- Protocol Economics ---
    uint256 public protocolFeesNXT; // Accumulates NXT fees
    address public protocolFeeRecipient; // Address to receive protocol fees

    // --- Events ---
    event NexusTokensMinted(address indexed to, uint256 amount);
    event NexusTokensBurned(address indexed from, uint256 amount);
    event EpochalShardMinted(address indexed to, uint256 tokenId, ShardAffinity initialAffinity);
    event ShardMetadataEvolved(uint256 indexed tokenId, ShardModifier newModifier, uint256 epochId);
    event EpochAdvanced(uint256 indexed newEpochId, uint256 timestamp);
    event ChallengeProposed(uint256 indexed challengeId, address indexed proposer, string title, uint256 nexusStakeRequired);
    event ChallengeVoted(uint256 indexed challengeId, address indexed voter, bool support, uint256 voteWeight);
    event ChallengeExecuted(uint256 indexed challengeId, uint256 startTime, uint256 endTime);
    event ShardStakedForChallenge(uint256 indexed challengeId, uint256 indexed tokenId, address indexed owner);
    event ShardUnstakedFromChallenge(uint256 indexed challengeId, uint256 indexed tokenId, address indexed owner);
    event ChallengeResolved(uint256 indexed challengeId, ChallengeStatus status, uint256 totalRewards);
    event ChallengeRewardsClaimed(uint256 indexed challengeId, address indexed participant, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    constructor(address initialAdmin) ERC20("NexusToken", "NXT") ERC721("EpochalShard", "EPS") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(EPOCH_MANAGER_ROLE, initialAdmin);
        _grantRole(CHALLENGE_RESOLVER_ROLE, initialAdmin);

        currentEpochId = 1;
        epochs[currentEpochId] = Epoch(
            currentEpochId,
            block.timestamp,
            0, // Active
            "The Genesis Epoch: Protocol Initialization",
            1, // Min 1 challenge resolved to advance
            50 // Min 50% shard participation
        );
        nextEpochStartTime = block.timestamp + 7 days; // Initial epoch lasts 7 days

        protocolFeeRecipient = initialAdmin;
    }

    // --- I. Core & Access Control ---

    // 1. constructor: (Implemented above)
    // 2. grantRole: (Inherited from AccessControl.sol)
    // 3. revokeRole: (Inherited from AccessControl.sol)
    // 4. hasRole: (Inherited from AccessControl.sol)
    // 5. getRoleAdmin: (Inherited from AccessControl.sol)
    // 6. pause: (Inherited from Pausable.sol)
    // 7. unpause: (Inherited from Pausable.sol)

    // Overrides for AccessControl to ensure `_authorizeUpgrade` works if needed
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC20)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC20, ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // --- II. NexusToken (ERC20) Management ---

    // 8. mintNexusTokens: Mints new NexusTokens. Admin/privileged role.
    function mintNexusTokens(address to, uint256 amount) public virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant whenNotPaused {
        _mint(to, amount);
        emit NexusTokensMinted(to, amount);
    }

    // 9. burnNexusTokens: Allows users to burn their own NexusTokens.
    function burnNexusTokens(uint256 amount) public virtual nonReentrant {
        _burn(_msgSender(), amount);
        emit NexusTokensBurned(_msgSender(), amount);
    }

    // 10. transfer: Standard ERC20 transfer (inherited)
    // 11. approve: Standard ERC20 approve (inherited)
    // 12. transferFrom: Standard ERC20 transferFrom (inherited)
    // 13. balanceOf: Standard ERC20 balanceOf (inherited)
    // 14. allowance: Standard ERC20 allowance (inherited)

    // --- III. EpochalShard (Dynamic ERC721 NFT) Management ---

    // 15. mintEpochalShard: Mints a new EpochalShard NFT with initial traits.
    function mintEpochalShard(address to, ShardAffinity initialAffinity) public virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant whenNotPaused returns (uint256) {
        _epochalShardIds.increment();
        uint256 newItemId = _epochalShardIds.current();
        _safeMint(to, newItemId);

        epochalShardTraits[newItemId] = ShardTraits({
            intrinsicAffinity: initialAffinity,
            currentModifier: ShardModifier.NEUTRAL,
            epochParticipationCount: 1,
            challengeSuccessCount: 0,
            lastEvolutionEpoch: currentEpochId
        });

        emit EpochalShardMinted(to, newItemId, initialAffinity);
        return newItemId;
    }

    // 16. tokenURI: Provides a dynamic URI for the NFT's metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        // The metadata server (off-chain) will use this on-chain data to generate the actual JSON and image.
        // E.g., a server at baseTokenURI/tokenId will query this contract for shard traits and history.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    // 17. evolveShardMetadata: Triggers a specific shard's metadata evolution.
    // This function can be called by the shard owner to "refresh" its traits,
    // or implicitly by other protocol functions (e.g., challenge resolution).
    function evolveShardMetadata(uint256 tokenId) public nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        require(epochalShardTraits[tokenId].lastEvolutionEpoch < currentEpochId, "Shard already evolved in current epoch.");

        ShardTraits storage traits = epochalShardTraits[tokenId];

        // Example dynamic evolution logic:
        // - More successful challenges could lead to 'ENHANCED'
        // - Low participation or failed challenges could lead to 'CORRUPTED'
        // - Consistent participation could lead to 'STABLE'

        ShardModifier oldModifier = traits.currentModifier;

        if (traits.challengeSuccessCount >= 5 && traits.epochParticipationCount >= currentEpochId / 2) {
            traits.currentModifier = ShardModifier.ENHANCED;
        } else if (traits.challengeSuccessCount < 2 && traits.epochParticipationCount > 0 && traits.epochParticipationCount < currentEpochId / 2) {
            traits.currentModifier = ShardModifier.CORRUPTED;
        } else {
            traits.currentModifier = ShardModifier.STABLE;
        }

        traits.lastEvolutionEpoch = currentEpochId;
        traits.epochParticipationCount = currentEpochId; // Update participation count based on current epoch

        if (oldModifier != traits.currentModifier) {
            emit ShardMetadataEvolved(tokenId, traits.currentModifier, currentEpochId);
        }
    }

    // 18. getShardTraits: Retrieves the current dynamic traits of an EpochalShard.
    function getShardTraits(uint256 tokenId) public view returns (ShardAffinity, ShardModifier, uint256, uint256, uint256) {
        ShardTraits storage traits = epochalShardTraits[tokenId];
        return (
            traits.intrinsicAffinity,
            traits.currentModifier,
            traits.epochParticipationCount,
            traits.challengeSuccessCount,
            traits.lastEvolutionEpoch
        );
    }

    // 19. getShardHistory: Returns a record of challenges and epochs a shard has participated in.
    function getShardHistory(uint256 tokenId) public view returns (ShardChallengeHistory[] memory) {
        return epochalShardHistories[tokenId];
    }

    // 20. transferFrom: Standard ERC721 transferFrom (inherited)
    // 21. safeTransferFrom: Standard ERC721 safeTransferFrom (inherited)
    // 22. approve: Standard ERC721 approve (inherited)
    // 23. getApproved: Standard ERC721 getApproved (inherited)
    // 24. setApprovalForAll: Standard ERC721 setApprovalForAll (inherited)
    // 25. isApprovedForAll: Standard ERC721 isApprovedForAll (inherited)
    // 26. ownerOf: Standard ERC721 ownerOf (inherited)
    // 27. balanceOf: Standard ERC721 balanceOf (inherited for NFTs)

    function _setBaseTokenURI(string memory baseURI) internal {
        _baseTokenURI = baseURI;
    }

    function setBaseTokenURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseTokenURI(baseURI);
    }

    // --- IV. Epoch & Protocol State Management ---

    // 28. advanceEpoch: Advances the global protocol Epoch.
    function advanceEpoch() public onlyRole(EPOCH_MANAGER_ROLE) nonReentrant whenNotPaused {
        require(block.timestamp >= nextEpochStartTime, "Epoch cannot be advanced yet. Time not elapsed.");

        Epoch storage current = epochs[currentEpochId];
        current.endTime = block.timestamp; // Mark current epoch as ended

        // Check epoch transition conditions
        // Simplified: Check if enough challenges were resolved in the *previous* epoch (the current one now ending)
        // In a real system, you'd aggregate data for the current ending epoch.
        // For this example, we'll simplify and just check time.
        // A more complex system would check `minChallengesResolved` and `minParticipationRate` from the *previous* epoch.
        // e.g. `totalChallengesResolvedInCurrentEpoch >= current.minChallengesResolved`

        currentEpochId++;
        epochs[currentEpochId] = Epoch(
            currentEpochId,
            block.timestamp,
            0, // Active
            string(abi.encodePacked("Epoch ", Strings.toString(currentEpochId), ": The New Dawn")),
            current.minChallengesResolved + 1, // Increase challenge requirement for next epoch
            current.minParticipationRate // Maintain participation rate
        );

        nextEpochStartTime = block.timestamp + 7 days; // Next epoch lasts 7 days by default

        emit EpochAdvanced(currentEpochId, block.timestamp);
    }

    // 29. getCurrentEpoch: Returns detailed information about the protocol's current Epoch.
    function getCurrentEpoch() public view returns (uint256, uint256, uint256, string memory, uint256, uint256, uint256) {
        Epoch storage current = epochs[currentEpochId];
        return (
            current.id,
            current.startTime,
            current.endTime,
            current.description,
            current.minChallengesResolved,
            current.minParticipationRate,
            current.protocolFeesAccrued
        );
    }

    // 30. setEpochTransitionConditions: Configures criteria for epoch advancement.
    function setEpochTransitionConditions(uint256 epochId, uint256 minChallenges, uint256 minRate) public onlyRole(EPOCH_MANAGER_ROLE) {
        require(epochId > 0 && epochId <= currentEpochId, "Invalid epoch ID.");
        require(minRate <= 100, "Min participation rate cannot exceed 100.");
        epochs[epochId].minChallengesResolved = minChallenges;
        epochs[epochId].minParticipationRate = minRate;
    }

    // --- V. Gamified Governance & Challenges ---

    // 31. proposeChallenge: Allows NexusToken holders to propose a new protocol Challenge.
    function proposeChallenge(
        string memory title,
        string memory description,
        uint256 nexusStakeRequired,
        uint256 voteThreshold,
        uint256 votingDuration, // in seconds
        uint256 challengeDuration, // in seconds
        uint256 rewardPool, // NXT for winners
        uint256 minShards
    ) public nonReentrant whenNotPaused {
        require(balanceOf(_msgSender()) >= nexusStakeRequired, "Proposer needs more NXT for stake.");
        require(challengeDuration > 0, "Challenge duration must be positive.");
        require(votingDuration > 0, "Voting duration must be positive.");
        require(voteThreshold > 0, "Vote threshold must be positive.");
        require(rewardPool > 0, "Reward pool must be positive.");
        require(minShards > 0, "Minimum shards staked must be positive.");

        _transfer(_msgSender(), address(this), nexusStakeRequired); // Proposer stakes NXT

        _challengeProposalIds.increment();
        uint256 proposalId = _challengeProposalIds.current();

        challengeProposals[proposalId] = ChallengeProposal({
            id: proposalId,
            proposer: _msgSender(),
            title: title,
            description: description,
            nexusStakeRequired: nexusStakeRequired,
            voteThreshold: voteThreshold,
            startTime: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            challengeDuration: challengeDuration,
            rewardPool: rewardPool,
            status: ChallengeStatus.PROPOSED,
            minShardsStaked: minShards
        });

        emit ChallengeProposed(proposalId, _msgSender(), title, nexusStakeRequired);
    }

    // 32. voteOnChallengeProposal: Users vote on proposed Challenges.
    function voteOnChallengeProposal(uint256 proposalId, bool support) public nonReentrant whenNotPaused {
        ChallengeProposal storage proposal = challengeProposals[proposalId];
        require(proposal.status == ChallengeStatus.PROPOSED, "Challenge not in voting phase.");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended.");
        require(!hasVotedOnChallenge[proposalId][_msgSender()], "Already voted on this proposal.");
        require(balanceOf(_msgSender()) > 0, "Voter needs NXT to vote."); // Simple weight by token count

        hasVotedOnChallenge[proposalId][_msgSender()] = true;
        uint256 voteWeight = balanceOf(_msgSender()); // Use token balance as vote weight

        if (support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }

        emit ChallengeVoted(proposalId, _msgSender(), support, voteWeight);
    }

    // 33. executeChallenge: Admin/role-based function to start an approved challenge.
    function executeChallenge(uint256 proposalId) public onlyRole(CHALLENGE_RESOLVER_ROLE) nonReentrant whenNotPaused {
        ChallengeProposal storage proposal = challengeProposals[proposalId];
        require(proposal.status == ChallengeStatus.PROPOSED, "Challenge is not in proposed state.");
        require(block.timestamp > proposal.votingEndTime, "Voting period not ended yet.");
        require(proposal.votesFor >= proposal.voteThreshold, "Proposal did not meet vote threshold.");

        proposal.status = ChallengeStatus.ACTIVE;
        activeChallenges[proposalId] = ActiveChallenge({
            id: proposalId,
            proposalId: proposalId,
            startTime: block.timestamp,
            endTime: block.timestamp + proposal.challengeDuration,
            totalStakedShards: 0,
            status: ChallengeStatus.ACTIVE,
            rewardPool: proposal.rewardPool,
            participants: new address[](0) // Initialize empty
        });
        activeChallengeIds.push(proposalId);

        // Transfer reward pool from proposer's stake if it covers it, or mint new
        // For simplicity, we'll assume the reward pool comes from a general fund or new mint.
        // In a real system, the proposer's initial stake could contribute, or a DAO treasury.
        _mint(address(this), proposal.rewardPool); // Mint rewards into contract for distribution

        emit ChallengeExecuted(proposalId, activeChallenges[proposalId].startTime, activeChallenges[proposalId].endTime);
    }

    // 34. stakeShardForChallenge: Allows EpochalShard owners to stake their NFTs.
    function stakeShardForChallenge(uint256 challengeId, uint256 tokenId) public nonReentrant whenNotPaused {
        ActiveChallenge storage active = activeChallenges[challengeId];
        require(active.status == ChallengeStatus.ACTIVE, "Challenge is not active.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved.");
        require(ownerOf(tokenId) == _msgSender(), "Only token owner can stake.");
        require(!active.stakedShards[tokenId], "Shard already staked in this challenge.");

        // Transfer NFT to this contract to lock it
        _transfer(_msgSender(), address(this), tokenId);
        
        active.stakedShards[tokenId] = true;
        active.totalStakedShards++;
        
        // Add participant if not already present, and link shard
        bool participantExists = false;
        for (uint i = 0; i < active.participants.length; i++) {
            if (active.participants[i] == _msgSender()) {
                participantExists = true;
                break;
            }
        }
        if (!participantExists) {
            active.participants.push(_msgSender());
        }
        active.userStakedShards[_msgSender()].push(tokenId);

        emit ShardStakedForChallenge(challengeId, tokenId, _msgSender());
    }

    // 35. unstakeShardFromChallenge: Permits owners to unstake their EpochalShards.
    function unstakeShardFromChallenge(uint256 challengeId, uint256 tokenId) public nonReentrant whenNotPaused {
        ActiveChallenge storage active = activeChallenges[challengeId];
        require(active.status != ChallengeStatus.ACTIVE, "Cannot unstake from active challenge.");
        require(active.stakedShards[tokenId], "Shard not staked in this challenge.");
        require(ownerOf(tokenId) == address(this), "Shard not held by contract (error state)."); // Ensure it's locked

        address originalOwner;
        // Find the original owner for this staked shard (simpler than tracking per-shard owner)
        // In a real system, `_owners` mapping in ERC721 would be updated to this contract
        // so we'd need to explicitly track the 'original' owner or pass it.
        // For this example, we'll assume the owner is the _msgSender() who staked it,
        // and they are unstaking their own.
        // A more robust system would store `mapping(uint256 => address) stakedShardOriginalOwner;`
        originalOwner = _msgSender(); // Simplification: assumes original staker is unstaker

        // Transfer NFT back to original owner
        _transfer(address(this), originalOwner, tokenId);

        delete active.stakedShards[tokenId];
        active.totalStakedShards--;

        // Remove from userStakedShards - simplified by not removing, but tracking if needed
        // For a full implementation, you'd iterate and remove.

        emit ShardUnstakedFromChallenge(challengeId, tokenId, originalOwner);
    }

    // 36. resolveChallenge: Permissioned function to finalize a Challenge.
    function resolveChallenge(uint256 challengeId, bool success) public onlyRole(CHALLENGE_RESOLVER_ROLE) nonReentrant whenNotPaused {
        ActiveChallenge storage active = activeChallenges[challengeId];
        require(active.status == ChallengeStatus.ACTIVE, "Challenge is not active.");
        require(block.timestamp >= active.endTime, "Challenge period not ended yet.");
        require(active.totalStakedShards >= challengeProposals[challengeId].minShardsStaked, "Not enough shards staked to resolve challenge.");

        uint256 totalRewardPool = active.rewardPool;
        ChallengeStatus newStatus = success ? ChallengeStatus.RESOLVED_SUCCESS : ChallengeStatus.RESOLVED_FAILURE;
        active.status = newStatus;
        challengeProposals[challengeId].status = newStatus;

        if (success) {
            uint256 rewardPerShard = totalRewardPool / active.totalStakedShards;
            for (uint i = 0; i < active.participants.length; i++) {
                address participant = active.participants[i];
                uint256[] memory stakedTokens = active.userStakedShards[participant];
                for (uint j = 0; j < stakedTokens.length; j++) {
                    uint256 tokenId = stakedTokens[j];
                    if (active.stakedShards[tokenId]) { // Check if still staked, as it might have been unstaked if allowed
                        // Update shard history and traits
                        epochalShardHistories[tokenId].push(ShardChallengeHistory(challengeId, true, block.timestamp));
                        epochalShardTraits[tokenId].challengeSuccessCount++;
                        // The `evolveShardMetadata` will be called by owner later or by an explicit trigger.
                    }
                }
                // Funds are kept in the contract until claimed
            }
            epochs[currentEpochId].protocolFeesAccrued += totalRewardPool; // Accumulate fees (rewards in this case add to fee pool)
        } else {
            // Penalties or no rewards for failure.
            // Shards are still updated with a failure record.
            for (uint i = 0; i < active.participants.length; i++) {
                address participant = active.participants[i];
                uint256[] memory stakedTokens = active.userStakedShards[participant];
                for (uint j = 0; j < stakedTokens.length; j++) {
                    uint256 tokenId = stakedTokens[j];
                     if (active.stakedShards[tokenId]) {
                        epochalShardHistories[tokenId].push(ShardChallengeHistory(challengeId, false, block.timestamp));
                     }
                }
            }
            // Proposer's stake might be burned or partially returned in case of failure (not implemented here)
            // For simplicity, rewards are just held by contract if no success.
        }

        // Return proposer's stake if challenge failed or was cancelled
        if (newStatus == ChallengeStatus.RESOLVED_FAILURE || newStatus == ChallengeStatus.CANCELLED) {
            _transfer(address(this), challengeProposals[challengeId].proposer, challengeProposals[challengeId].nexusStakeRequired);
        }
        
        emit ChallengeResolved(challengeId, newStatus, success ? totalRewardPool : 0);
    }

    // 37. claimChallengeRewards: Allows participants to claim their earned NexusTokens.
    function claimChallengeRewards(uint256 challengeId) public nonReentrant {
        ActiveChallenge storage active = activeChallenges[challengeId];
        require(active.status == ChallengeStatus.RESOLVED_SUCCESS, "Challenge not resolved successfully.");

        address claimant = _msgSender();
        uint256[] storage stakedTokens = active.userStakedShards[claimant];
        require(stakedTokens.length > 0, "No shards staked by claimant in this challenge.");

        uint256 rewardsDue = 0;
        // Calculate rewards for successful stakers
        if (active.totalStakedShards > 0) { // Avoid division by zero
            uint256 rewardPerShard = active.rewardPool / active.totalStakedShards;
            rewardsDue = stakedTokens.length * rewardPerShard;
        }
        
        // This is a simplified rewards distribution. In a more complex system,
        // individual rewards might vary based on shard traits, time staked, etc.
        require(rewardsDue > 0, "No rewards to claim.");
        
        // Clear this user's claimable status for this challenge
        delete active.userStakedShards[claimant]; // Mark rewards as claimed (simple approach)

        _transfer(address(this), claimant, rewardsDue); // Transfer NXT rewards
        emit ChallengeRewardsClaimed(challengeId, claimant, rewardsDue);
    }

    // 38. getChallengeDetails: Provides comprehensive information about any specific Challenge.
    function getChallengeDetails(uint256 challengeId) public view returns (ChallengeProposal memory, ActiveChallenge memory) {
        return (challengeProposals[challengeId], activeChallenges[challengeId]);
    }

    // 39. getUserStakedChallenges: Lists challenges a user has staked shards in.
    function getUserStakedChallenges(address user) public view returns (uint256[] memory) {
        uint256[] memory stakedIds = new uint256[](activeChallengeIds.length);
        uint256 count = 0;
        for (uint i = 0; i < activeChallengeIds.length; i++) {
            uint256 challengeId = activeChallengeIds[i];
            // Check if the user has any shards staked in this challenge
            if (activeChallenges[challengeId].userStakedShards[user].length > 0) {
                stakedIds[count] = challengeId;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = stakedIds[i];
        }
        return result;
    }

    // --- VI. Economic & Fee Management ---

    // 40. setProtocolFeeRecipient: Sets the address for protocol fees.
    function setProtocolFeeRecipient(address recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), "Recipient cannot be zero address.");
        protocolFeeRecipient = recipient;
    }

    // 41. withdrawProtocolFees: Allows the fee recipient to withdraw accumulated fees.
    function withdrawProtocolFees() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 fees = epochs[currentEpochId].protocolFeesAccrued;
        require(fees > 0, "No fees to withdraw.");
        
        epochs[currentEpochId].protocolFeesAccrued = 0; // Reset for current epoch
        _transfer(address(this), protocolFeeRecipient, fees);
        
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, fees);
    }
}
```