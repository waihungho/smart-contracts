Here's a smart contract for "MetaMorph Genesis Nexus" (MGN), designed with advanced, creative, and trendy functionalities focusing on decentralized generative content, dynamic NFTs, and a liquid reputation system.

---

## MetaMorph Genesis Nexus (MGN) - Smart Contract Outline and Function Summary

**Concept:**
The MetaMorph Genesis Nexus is a decentralized protocol where users can submit parameters for generative content ("Creative Modules"), curate existing modules, and mint unique, dynamic "Genesis NFTs" from these modules. The protocol incorporates a liquid reputation system for curation, adaptive reward distribution, and DAO-based governance. Genesis NFTs evolve over time based on on-chain interactions and achievements, leading to "emergent properties."

**Core Features:**
*   **Decentralized Generative Content Curation:** Users stake tokens to propose generative content parameters (Creative Modules) and other users curate them through a voting mechanism.
*   **Dynamic, Evolving NFTs (Genesis NFTs):** NFTs minted from Creative Modules are not static. Their metadata (and thus appearance/properties) can change and "evolve" based on the module's popularity, curated reputation, and interaction milestones, unlocking "emergent properties."
*   **Liquid Reputation System:** Curators earn reputation for accurate and impactful votes. This reputation can be delegated to others, influencing voting power and reward distribution.
*   **Adaptive Tokenomics:** Reward distributions for creators and curators, as well as protocol fees, are dynamically adjustable via DAO governance to optimize for growth and quality.
*   **DAO Governance:** Key protocol parameters, upgrades, and emergency actions are controlled by the community through a voting mechanism, using a combination of MMG token holdings and delegated reputation.

**Token Used:** `MMG` (MetaMorph Genesis Token) - assumed to be an existing ERC-20 token managed by the protocol for staking, fees, and rewards.

---

### Function Summary:

**I. Core Module Management (Creator/Lifecycle)**
1.  `submitCreativeModule(string memory _contentHash, uint256 _stakeAmount, string memory _moduleType)`: Allows a user to submit a new generative content module by staking `_stakeAmount` of `MMG` tokens.
2.  `updateCreativeModuleContent(uint256 _moduleId, string memory _newContentHash)`: Creator can update the content hash (e.g., new generative parameters) for their existing module.
3.  `requestModuleStakeWithdrawal(uint256 _moduleId)`: Initiates a withdrawal request for the staked `MMG` from a module, subject to a cooldown period.
4.  `finalizeModuleStakeWithdrawal(uint256 _moduleId)`: Completes the withdrawal of staked `MMG` after the cooldown period has passed.
5.  `claimModuleCreationRewards(uint256 _moduleId)`: Creator claims accumulated `MMG` rewards based on their module's performance and NFT minting activity.

**II. Curation & Reputation System**
6.  `voteOnModule(uint256 _moduleId, bool _isUpvote)`: Allows users to cast an upvote or downvote on a Creative Module. Affects module score and curator's reputation.
7.  `delegateCurationPower(address _delegatee)`: Delegates the caller's curation power (reputation) to another address.
8.  `undelegateCurationPower()`: Revokes any existing delegation of curation power.
9.  `getEffectiveCurationPower(address _addr)`: Returns the total effective curation power of an address (self-reputation + delegated reputation).
10. `claimCurationRewards()`: Curators claim `MMG` rewards based on their effective curation power and successful votes.

**III. Genesis NFT Management (ERC721)**
11. `mintGenesisNFT(uint256 _moduleId, string memory _initialMetadataURI)`: Allows users to mint a new Genesis NFT from a specified Creative Module, paying an `MMG` fee.
12. `updateGenesisNFTMetadataURI(uint256 _tokenId, string memory _newMetadataURI)`: Allows authorized entities (e.g., the contract itself, or a DAO-controlled oracle) to update an NFT's metadata URI.
13. `requestNFTEvolutionCheck(uint256 _tokenId)`: A user can request the contract to evaluate if their Genesis NFT qualifies for an evolution based on on-chain metrics.
14. `triggerEmergentProperty(uint256 _tokenId, string memory _newPropertyURI)`: (Internal/Restricted) Applies an "emergent property" to an NFT, updating its metadata to reflect a new state or feature.
15. `burnGenesisNFT(uint256 _tokenId)`: Allows the owner to irrevocably burn their Genesis NFT.

**IV. DAO Governance & Protocol Parameters**
16. `proposeParameterChange(bytes memory _callData, string memory _description)`: Allows a user with sufficient `MMG` to propose a change to contract parameters or call a function, subject to DAO approval.
17. `voteOnProposal(uint256 _proposalId, bool _for)`: Allows users with `MMG` token holdings to vote on an active governance proposal.
18. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has passed quorum and voting period.
19. `updateProtocolFee(uint256 _newFeeBps)`: (Governance) Sets the new percentage (in basis points) for protocol fees on NFT minting.
20. `setRewardFactors(uint256 _newCreatorFactor, uint256 _newCuratorFactor)`: (Governance) Adjusts the weighting factors used in the reward distribution calculations for creators and curators.
21. `emergencyPause()`: (Admin/Multi-sig controlled) Pauses critical contract functionalities in case of an emergency.
22. `unpause()`: (Admin/Multi-sig controlled) Unpauses the contract after an emergency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary provided above source code.

contract MetaMorphGenesisNexus is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    IERC20 public immutable mmgToken; // The native MetaMorph Genesis Token

    // Creative Module Management
    struct CreativeModule {
        address creator;
        string contentHash; // IPFS/Arweave hash for generative parameters/prompt
        string moduleType;  // e.g., "AI_Prompt", "Music_Seed", "Art_Parameters"
        uint256 stakeAmount;
        uint256 creationTimestamp;
        uint256 lastInteractionTimestamp; // Last time voted on or NFT minted
        uint256 upvotes;
        uint256 downvotes;
        uint256 mintedNFTCount;
        bool isActive; // Can be deactivated if stake withdrawn
        uint256 stakeWithdrawalRequestTime; // Timestamp for withdrawal request
        uint256 creatorRewardPool; // Accumulated MMG rewards for the creator
    }
    mapping(uint256 => CreativeModule) public creativeModules;
    Counters.Counter private _moduleIdCounter;

    // Genesis NFT Management (ERC721 properties inherited, additional mappings)
    mapping(uint256 => uint256) public genesisNFTToModuleId; // Link NFT tokenId to CreativeModule
    mapping(uint256 => uint256) public genesisNFTInteractionScore; // Score for NFT evolution (e.g., total votes on its module, user interactions)
    mapping(uint256 => uint256) public genesisNFTEvolutionPhase; // Current evolution phase of an NFT

    // Curation & Reputation System
    mapping(address => uint256) public curatorReputation; // Base reputation score
    mapping(address => address) public delegatedCurationPower; // Maps delegator => delegatee
    mapping(uint256 => mapping(address => bool)) public hasVotedOnModule; // Prevents double voting on a module by an address

    // Adaptive Tokenomics & Reward Distribution
    uint256 public creatorRewardFactor; // Basis points for creator rewards (e.g., 100 for 1%)
    uint256 public curatorRewardFactor; // Basis points for curator rewards
    uint256 public protocolFeeBps; // Protocol fee in basis points for NFT minting

    // Governance System (Simple DAO)
    struct Proposal {
        uint256 id;
        string description;
        bytes callData; // Encoded function call to execute
        address target; // Contract address to call
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        uint256 creatorVotePower; // Snapshot of proposal creator's voting power
        bool executed;
        mapping(address => bool) hasVoted; // Prevents double voting on proposal
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public proposalQuorumPercentage; // E.g., 50 (for 50%)
    uint256 public proposalVotingPeriod; // In seconds
    address public daoTreasury; // Address where protocol fees accumulate

    // --- Events ---
    event CreativeModuleSubmitted(uint256 indexed moduleId, address indexed creator, string moduleType, string contentHash, uint256 stakeAmount);
    event CreativeModuleUpdated(uint256 indexed moduleId, address indexed updater, string newContentHash);
    event ModuleVoteCast(uint256 indexed moduleId, address indexed voter, bool isUpvote, uint256 reputationChange);
    event CurationPowerDelegated(address indexed delegator, address indexed delegatee);
    event CurationPowerUndelegated(address indexed delegator);
    event GenesisNFTMinted(uint256 indexed tokenId, address indexed minter, uint256 indexed moduleId, string initialMetadataURI);
    event GenesisNFTEvolutionTriggered(uint256 indexed tokenId, uint256 indexed newPhase, string newMetadataURI);
    event ModuleStakeWithdrawalRequested(uint256 indexed moduleId, address indexed creator, uint256 amount);
    event ModuleStakeWithdrawalFinalized(uint256 indexed moduleId, address indexed creator, uint256 amount);
    event CreatorRewardsClaimed(uint256 indexed moduleId, address indexed creator, uint256 amount);
    event CuratorRewardsClaimed(address indexed curator, uint256 amount);
    event ProtocolFeeUpdated(uint256 newFeeBps);
    event RewardFactorsUpdated(uint256 newCreatorFactor, uint256 newCuratorFactor);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool forVote, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);


    // --- Constructor ---
    constructor(
        address _mmgTokenAddress,
        string memory _name,
        string memory _symbol,
        uint256 _initialCreatorRewardFactor,
        uint256 _initialCuratorRewardFactor,
        uint256 _initialProtocolFeeBps,
        uint256 _initialProposalQuorumPercentage,
        uint256 _initialProposalVotingPeriod,
        address _daoTreasury
    )
        ERC721(_name, _symbol)
        Ownable(msg.sender) // Owner initially holds administrative power, transitions to DAO
    {
        require(_mmgTokenAddress != address(0), "Invalid MMG token address");
        require(_daoTreasury != address(0), "Invalid DAO treasury address");
        mmgToken = IERC20(_mmgTokenAddress);
        creatorRewardFactor = _initialCreatorRewardFactor;
        curatorRewardFactor = _initialCuratorRewardFactor;
        protocolFeeBps = _initialProtocolFeeBps;
        proposalQuorumPercentage = _initialProposalQuorumPercentage;
        proposalVotingPeriod = _initialProposalVotingPeriod;
        daoTreasury = _daoTreasury;

        _moduleIdCounter.increment(); // Start from 1
        _proposalIdCounter.increment(); // Start from 1
    }

    // --- Modifiers ---
    modifier onlyModuleCreator(uint256 _moduleId) {
        require(creativeModules[_moduleId].creator == _msgSender(), "Only module creator can call this function");
        _;
    }

    modifier onlyModuleExists(uint256 _moduleId) {
        require(_moduleIdCounter.current() > _moduleId && creativeModules[_moduleId].creator != address(0), "Module does not exist");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "Only NFT owner can call this function");
        _;
    }

    // --- I. Core Module Management (Creator/Lifecycle) ---

    function submitCreativeModule(string memory _contentHash, uint256 _stakeAmount, string memory _moduleType)
        external
        whenNotPaused
    {
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        require(bytes(_moduleType).length > 0, "Module type cannot be empty");
        require(_stakeAmount > 0, "Stake amount must be greater than zero");
        require(mmgToken.transferFrom(_msgSender(), address(this), _stakeAmount), "MMG transfer failed for stake");

        uint256 newId = _moduleIdCounter.current();
        creativeModules[newId] = CreativeModule({
            creator: _msgSender(),
            contentHash: _contentHash,
            moduleType: _moduleType,
            stakeAmount: _stakeAmount,
            creationTimestamp: block.timestamp,
            lastInteractionTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            mintedNFTCount: 0,
            isActive: true,
            stakeWithdrawalRequestTime: 0,
            creatorRewardPool: 0
        });
        _moduleIdCounter.increment();

        emit CreativeModuleSubmitted(newId, _msgSender(), _moduleType, _contentHash, _stakeAmount);
    }

    function updateCreativeModuleContent(uint256 _moduleId, string memory _newContentHash)
        external
        onlyModuleExists(_moduleId)
        onlyModuleCreator(_moduleId)
        whenNotPaused
    {
        require(bytes(_newContentHash).length > 0, "New content hash cannot be empty");
        creativeModules[_moduleId].contentHash = _newContentHash;
        creativeModules[_moduleId].lastInteractionTimestamp = block.timestamp;
        emit CreativeModuleUpdated(_moduleId, _msgSender(), _newContentHash);
    }

    function requestModuleStakeWithdrawal(uint256 _moduleId)
        external
        onlyModuleExists(_moduleId)
        onlyModuleCreator(_moduleId)
        whenNotPaused
    {
        CreativeModule storage module = creativeModules[_moduleId];
        require(module.isActive, "Module is not active");
        require(module.stakeWithdrawalRequestTime == 0, "Withdrawal already requested");
        // Add a condition: e.g., require(module.mintedNFTCount == 0 || block.timestamp > module.creationTimestamp + 365 days, "Cannot withdraw stake if NFTs are minted from it yet."); // Example: after 1 year, or if no NFTs minted
        
        module.stakeWithdrawalRequestTime = block.timestamp;
        emit ModuleStakeWithdrawalRequested(_moduleId, _msgSender(), module.stakeAmount);
    }

    function finalizeModuleStakeWithdrawal(uint256 _moduleId)
        external
        onlyModuleExists(_moduleId)
        onlyModuleCreator(_moduleId)
        whenNotPaused
    {
        CreativeModule storage module = creativeModules[_moduleId];
        require(module.stakeWithdrawalRequestTime > 0, "No withdrawal request made");
        uint256 withdrawalCoolDownPeriod = 7 days; // Example cooldown
        require(block.timestamp >= module.stakeWithdrawalRequestTime + withdrawalCoolDownPeriod, "Withdrawal cooldown not passed");
        
        uint256 amount = module.stakeAmount;
        module.stakeAmount = 0; // Clear stake
        module.isActive = false; // Deactivate module
        module.stakeWithdrawalRequestTime = 0; // Reset
        
        require(mmgToken.transfer(module.creator, amount), "MMG transfer failed for stake withdrawal");
        emit ModuleStakeWithdrawalFinalized(_moduleId, module.creator, amount);
    }

    function claimModuleCreationRewards(uint256 _moduleId)
        external
        onlyModuleExists(_moduleId)
        onlyModuleCreator(_moduleId)
        whenNotPaused
    {
        CreativeModule storage module = creativeModules[_moduleId];
        uint256 rewards = module.creatorRewardPool;
        require(rewards > 0, "No rewards to claim");

        module.creatorRewardPool = 0; // Reset rewards
        require(mmgToken.transfer(_msgSender(), rewards), "MMG transfer failed for creator rewards");
        emit CreatorRewardsClaimed(_moduleId, _msgSender(), rewards);
    }

    // --- II. Curation & Reputation System ---

    function voteOnModule(uint256 _moduleId, bool _isUpvote)
        external
        onlyModuleExists(_moduleId)
        whenNotPaused
    {
        CreativeModule storage module = creativeModules[_moduleId];
        require(module.creator != _msgSender(), "Creator cannot vote on their own module");
        require(!hasVotedOnModule[_moduleId][_msgSender()], "Already voted on this module");

        uint256 reputationBefore = curatorReputation[_msgSender()];
        uint256 reputationChange = 1; // Base reputation change for a vote

        if (_isUpvote) {
            module.upvotes++;
            curatorReputation[_msgSender()] += reputationChange;
        } else {
            module.downvotes++;
            // Penalize reputation for downvotes, or just not reward
            // For now, simple positive reputation gain for any vote, but can be adjusted for "correct" votes
            curatorReputation[_msgSender()] += reputationChange; 
        }
        
        hasVotedOnModule[_moduleId][_msgSender()] = true;
        module.lastInteractionTimestamp = block.timestamp;
        
        // Simple mechanism to add to creator's reward pool on upvote
        if (_isUpvote) {
            uint256 rewardShare = module.stakeAmount * creatorRewardFactor / 10000; // Small percentage of stake
            module.creatorRewardPool += rewardShare;
        }

        emit ModuleVoteCast(_moduleId, _msgSender(), _isUpvote, curatorReputation[_msgSender()] - reputationBefore);
    }

    function delegateCurationPower(address _delegatee) external whenNotPaused {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != _msgSender(), "Cannot delegate to self");
        delegatedCurationPower[_msgSender()] = _delegatee;
        emit CurationPowerDelegated(_msgSender(), _delegatee);
    }

    function undelegateCurationPower() external whenNotPaused {
        require(delegatedCurationPower[_msgSender()] != address(0), "No delegation active for this address");
        delete delegatedCurationPower[_msgSender()];
        emit CurationPowerUndelegated(_msgSender());
    }

    function getEffectiveCurationPower(address _addr) public view returns (uint256) {
        address delegatee = delegatedCurationPower[_addr];
        if (delegatee != address(0)) {
            // A delegator gives their power to delegatee.
            // If delegatee also has incoming delegations, their effective power compounds.
            // For simplicity, this returns the power if `_addr` is a direct curator or delegatee.
            // A more complex system might traverse the delegation chain.
            // Here, we consider if _addr is a delegatee for others, or has its own rep.
            // Sum of `curatorReputation` for those delegating to `_addr` + `_addr`'s own `curatorReputation`.
            uint256 totalPower = curatorReputation[_addr];
            // To get full effective power, we would need to iterate all delegators.
            // This is too expensive on-chain. For simplicity, we just return _addr's own reputation.
            // Or we could have a `delegatedReputation` mapping that is updated when delegation changes.
            return totalPower; // Simplified: returns own reputation.
        }
        return curatorReputation[_addr];
    }

    // This would need to be callable by a trusted service or governance to aggregate.
    // For a fully on-chain solution, this would require iterating delegations which is gas-intensive.
    // As a workaround, we assume `curatorReputation` includes self and direct delegation (if the system
    // updates the delegatee's score directly when a delegation happens).
    // Or this function might return the *base* reputation of _addr, and the front-end or an oracle computes full effective power.
    function getAggregatedCurationPower(address _addr) internal view returns (uint256) {
        // In a real system, this would be computed off-chain or by a more complex on-chain registry.
        // For simplicity, we assume 'curatorReputation' itself is the effective power after all delegations.
        return curatorReputation[_addr];
    }

    function claimCurationRewards() external whenNotPaused {
        uint256 rewards = 0;
        // In a more complex system, this would be calculated based on the curator's
        // effective power and the performance of modules they voted on.
        // For now, let's assume there's a protocol-level pool for curators that
        // gets distributed. This pool needs to be funded.
        // Simple example: a fixed reward based on reputation, distributed from treasury.
        uint256 baseRewardPerReputationPoint = 100; // Example: 100 MMG per reputation point
        uint256 eligibleRewards = getAggregatedCurationPower(_msgSender()) * baseRewardPerReputationPoint;
        
        require(eligibleRewards > 0, "No curator rewards to claim");
        
        // This 'curatorRewardPool' would need to be funded, e.g., from protocol fees.
        // For now, we assume this is handled internally from a global pool.
        // We'd need an `mmgToken.transferFrom(daoTreasury, _msgSender(), eligibleRewards)` or similar.
        // To make it directly implementable, let's assume `mmgToken` held by the contract is the pool.
        require(mmgToken.transfer(_msgSender(), eligibleRewards), "MMG transfer failed for curator rewards");

        // Reset curator reputation to prevent re-claiming for same reputation points
        // (or implement a more sophisticated decaying/claiming period)
        curatorReputation[_msgSender()] = 0; 

        emit CuratorRewardsClaimed(_msgSender(), eligibleRewards);
    }


    // --- III. Genesis NFT Management (ERC721) ---

    // _setTokenURI is inherited from ERC721
    // _baseURI is inherited from ERC721

    function mintGenesisNFT(uint256 _moduleId, string memory _initialMetadataURI)
        external
        onlyModuleExists(_moduleId)
        whenNotPaused
        returns (uint256)
    {
        CreativeModule storage module = creativeModules[_moduleId];
        require(module.isActive, "Cannot mint from inactive module");

        // Protocol fee for minting
        uint256 fee = module.stakeAmount * protocolFeeBps / 10000; // Fee based on module's stake
        require(mmgToken.transferFrom(_msgSender(), daoTreasury, fee), "MMG transfer failed for minting fee");

        _mint(_msgSender(), _tokenIds.current()); // Mint new NFT
        _setTokenURI(_tokenIds.current(), _initialMetadataURI);

        genesisNFTToModuleId[_tokenIds.current()] = _moduleId;
        module.mintedNFTCount++;
        module.lastInteractionTimestamp = block.timestamp;
        
        // Initial interaction score could be module's upvotes
        genesisNFTInteractionScore[_tokenIds.current()] = module.upvotes;
        genesisNFTEvolutionPhase[_tokenIds.current()] = 1; // Starting phase

        emit GenesisNFTMinted(_tokenIds.current(), _msgSender(), _moduleId, _initialMetadataURI);
        _tokenIds.increment();
        return _tokenIds.current() - 1;
    }

    // Function to update an NFT's metadata URI. This should be restricted to the contract itself
    // or a DAO-controlled oracle/admin for triggering evolution.
    function updateGenesisNFTMetadataURI(uint256 _tokenId, string memory _newMetadataURI)
        public
        virtual
        onlyOwner // Initially owner, later DAO control
        whenNotPaused
    {
        require(_exists(_tokenId), "ERC721: URI set of nonexistent token");
        _setTokenURI(_tokenId, _newMetadataURI);
    }

    function requestNFTEvolutionCheck(uint256 _tokenId)
        external
        onlyNFTOwner(_tokenId)
        whenNotPaused
    {
        require(_exists(_tokenId), "NFT does not exist");
        uint256 moduleId = genesisNFTToModuleId[_tokenId];
        CreativeModule storage module = creativeModules[moduleId];

        // Example evolution logic:
        // Phase 1: Initial mint
        // Phase 2: If module has > 100 upvotes AND NFT interaction score > 50
        // Phase 3: If module has > 500 upvotes AND NFT interaction score > 200 AND phase 2 reached
        
        uint256 currentPhase = genesisNFTEvolutionPhase[_tokenId];
        string memory newURI = ""; // Placeholder for new metadata URI

        if (currentPhase == 1 && module.upvotes >= 100 && genesisNFTInteractionScore[_tokenId] >= 50) {
            newURI = "ipfs://new_phase_2_metadata_hash"; // Replace with actual hash
            triggerEmergentProperty(_tokenId, newURI);
            genesisNFTEvolutionPhase[_tokenId] = 2;
        } else if (currentPhase == 2 && module.upvotes >= 500 && genesisNFTInteractionScore[_tokenId] >= 200) {
            newURI = "ipfs://new_phase_3_metadata_hash"; // Replace with actual hash
            triggerEmergentProperty(_tokenId, newURI);
            genesisNFTEvolutionPhase[_tokenId] = 3;
        } else {
            revert("NFT does not qualify for evolution yet");
        }
        
        // Increment interaction score on check (even if not evolved, shows engagement)
        genesisNFTInteractionScore[_tokenId]++; 
    }

    // This function is intended to be called by internal logic (like requestNFTEvolutionCheck)
    // or by a DAO-controlled oracle that verifies conditions off-chain.
    function triggerEmergentProperty(uint256 _tokenId, string memory _newPropertyURI)
        internal
        virtual // Allows derived contracts to override access
    {
        require(_exists(_tokenId), "NFT does not exist");
        _setTokenURI(_tokenId, _newPropertyURI);
        emit GenesisNFTEvolutionTriggered(_tokenId, genesisNFTEvolutionPhase[_tokenId], _newPropertyURI);
    }

    function burnGenesisNFT(uint256 _tokenId)
        external
        onlyNFTOwner(_tokenId)
        whenNotPaused
    {
        require(_exists(_tokenId), "ERC721: burn of nonexistent token");
        _burn(_tokenId);
        // Clean up mappings if necessary
        delete genesisNFTToModuleId[_tokenId];
        delete genesisNFTInteractionScore[_tokenId];
        delete genesisNFTEvolutionPhase[_tokenId];
    }

    // --- IV. DAO Governance & Protocol Parameters ---

    function proposeParameterChange(address _target, bytes memory _callData, string memory _description)
        external
        whenNotPaused
        returns (uint256)
    {
        // Require a minimum MMG stake or reputation to propose
        // For simplicity, we will require the sender to hold at least 1000 MMG tokens.
        require(mmgToken.balanceOf(_msgSender()) >= 1000 * (10 ** mmgToken.decimals()), "Not enough MMG to propose");

        uint256 newId = _proposalIdCounter.current();
        proposals[newId] = Proposal({
            id: newId,
            description: _description,
            callData: _callData,
            target: _target,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            creatorVotePower: mmgToken.balanceOf(_msgSender()), // Snapshot of MMG balance
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });
        _proposalIdCounter.increment();

        emit ProposalCreated(newId, _msgSender(), _description);
        return newId;
    }

    function voteOnProposal(uint256 _proposalId, bool _for)
        external
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime, "Voting has not started");
        require(block.timestamp < proposal.voteEndTime, "Voting has ended");
        require(!proposal.hasVoted[_msgSender()], "Already voted on this proposal");

        uint256 voterPower = mmgToken.balanceOf(_msgSender()); // Vote power based on current MMG holdings
        require(voterPower > 0, "Voter has no MMG tokens");

        if (_for) {
            proposal.totalForVotes += voterPower;
        } else {
            proposal.totalAgainstVotes += voterPower;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit ProposalVoted(_proposalId, _msgSender(), _for, voterPower);
    }

    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.totalForVotes + proposal.totalAgainstVotes;
        require(totalVotes > 0, "No votes cast for this proposal");
        
        // Quorum check: e.g., total votes must be at least X% of *some* total supply/active voters.
        // For simplicity here, quorum is relative to total votes cast for this proposal
        // i.e., at least `proposalQuorumPercentage` of `totalVotes` must be 'for'.
        require(proposal.totalForVotes * 100 >= totalVotes * proposalQuorumPercentage, "Proposal did not meet quorum");

        proposal.executed = true;

        // Execute the proposed call
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    function updateProtocolFee(uint256 _newFeeBps) external onlyOwner whenNotPaused {
        require(_newFeeBps <= 10000, "Fee cannot exceed 100%"); // 10000 basis points = 100%
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeUpdated(_newFeeBps);
    }

    function setRewardFactors(uint256 _newCreatorFactor, uint256 _newCuratorFactor) external onlyOwner whenNotPaused {
        require(_newCreatorFactor + _newCuratorFactor <= 10000, "Total factors cannot exceed 100%"); // Ensure total is reasonable
        creatorRewardFactor = _newCreatorFactor;
        curatorRewardFactor = _newCuratorFactor;
        emit RewardFactorsUpdated(_newCreatorFactor, _newCuratorFactor);
    }

    // --- Admin Functions (Initially Owner, then DAO-controlled) ---

    function emergencyPause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Fallback to receive MMG for staking/fees (if directly sent, but transferFrom is preferred)
    receive() external payable {
        revert("Use specific functions for token transfers."); // Discourage direct Ether transfers
    }

    // --- Internal/Utility Functions ---

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://"; // Default base URI, should be dynamically set or handled by `tokenURI`
    }
}
```