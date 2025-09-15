This smart contract, named **ChronoForge**, introduces an innovative and advanced concept for dynamic, evolving NFTs driven by community governance, time-based epochs, and external data influences. It integrates elements of generative art, gamified decentralized autonomous organizations (DAOs), and digital asset evolution into a single, comprehensive protocol.

Unlike typical static NFTs or even simpler dynamic NFTs that react to single external conditions, ChronoForge NFTs (ChronoNFTs) evolve through a multi-faceted system:
1.  **Epochs:** Time-based phases that trigger global evolution events.
2.  **Evolutionary Directives:** Community-voted rules or themes that guide how NFTs should evolve (e.g., "enhance rarity," "shift color palette").
3.  **Generative Attribute Templates:** Community-submitted visual or trait components that ChronoNFTs can inherit or change into.
4.  **Catalysts:** Simulated external data feeds or specific on-chain events that can influence evolution paths, requiring oracular updates.
5.  **Temporal Shards:** Scarce, collectible ERC1155 tokens that can be fused with ChronoNFTs to unlock special, otherwise inaccessible evolutionary paths or attributes.

The contract itself manages its own ERC721 (ChronoNFTs), ERC20 (Evolutionary Essence for governance), and ERC1155 (Temporal Shards) implementations, making it a self-contained ecosystem.

---

### ChronoForge Smart Contract: Outline and Function Summary

**Contract Name:** `ChronoForge`
**Description:** A Protocol for Time-Evolving Dynamic NFTs, Gamified Governance, and Generative Digital Assets.

**I. Core Components & Standards:**
*   **ChronoNFT (ERC721Enumerable):** The core dynamic NFTs managed by this contract.
*   **EvolutionaryEssence (ERC20):** A utility and governance token for staking, voting, and interacting with the system.
*   **TemporalShards (ERC1155):** Collectible components that can be fused with ChronoNFTs.
*   **AccessControl:** For role-based permissions (admin, minter).
*   **Pausable:** For emergency contract pausing.
*   **ReentrancyGuard:** To prevent reentrancy attacks.

**II. Key Enums & Structs:**
*   `EvolutionState`: Tracks the current evolutionary phase of an NFT.
*   `ProposalStatus`: For tracking the lifecycle of governance proposals.
*   `AttributeTemplate`: Defines a generative art/trait component.
*   `EvolutionaryDirective`: Represents a governance-approved rule for NFT evolution.
*   `Catalyst`: Defines an external data influence or event trigger.
*   `NFTData`: Stores dynamic attributes and evolution history for each ChronoNFT.

**III. Outline of Functions (20+ unique functions beyond standard ERC implementations):**

**A. Contract Management & Core Infrastructure (AccessControlled):**
1.  `constructor()`: Initializes the contract, sets up roles, and defines initial parameters for ERC721, ERC20, and ERC1155.
2.  `setEpochAdvanceInterval(uint256 _intervalSeconds)`: Sets the duration for each epoch. (Admin/Governance)
3.  `pause()`: Pauses core contract functionalities in emergencies. (Admin)
4.  `unpause()`: Unpauses the contract. (Admin)
5.  `grantRole(bytes32 role, address account)`: Grants a specified role to an account. (Admin)

**B. Epoch & Evolution Engine:**
6.  `advanceEpoch()`: Progresses the system to the next epoch. This triggers the activation of pending directives/catalysts and marks a new phase for NFT evolution.
7.  `getEpochDetails()`: (View) Retrieves current epoch number, start time, and active proposals.
8.  `triggerNFTGlobalEvolution()`: Initiates a mass evolution for all eligible ChronoNFTs based on the current epoch's directives and active catalysts. Can be called by anyone, but frequency limited.

**C. Generative Attributes & Templates (NFT Trait Management):**
9.  `submitAttributeTemplate(string memory _name, string memory _uri, uint256 _rarityScore)`: Users propose new generative art/trait templates. Requires ESSENCE stake as a bond.
10. `voteOnAttributeTemplate(uint256 _templateId, bool _approve)`: ESSENCE stakers vote on proposed templates.
11. `finalizeAttributeTemplate(uint256 _templateId)`: Activates a template if it passes voting, making it available for NFT evolution.
12. `getAvailableAttributeTemplates()`: (View) Lists all currently active (approved) generative attribute templates.

**D. Evolutionary Directives (Governance for Evolution Rules):**
13. `proposeEvolutionaryDirective(string memory _name, string memory _description, bytes memory _data)`: Propose a new rule or theme that guides NFT evolution. Requires ESSENCE stake. The `_data` can encode complex parameters.
14. `voteOnEvolutionaryDirective(uint256 _directiveId, bool _approve)`: ESSENCE stakers cast their votes on directive proposals.
15. `finalizeEvolutionaryDirective(uint256 _directiveId)`: Activates a directive if it passes voting, influencing future evolutions.
16. `getActiveDirectives()`: (View) Retrieves a list of all currently active evolutionary directives.

**E. Catalysts & External Influences (Simulated Oracle Interaction):**
17. `submitCatalystProposal(string memory _name, string memory _dataFeedUrl, bytes memory _params)`: Propose an external data source or a specific interaction (Catalyst) that can influence evolution. Requires ESSENCE stake.
18. `voteOnCatalystProposal(uint256 _catalystId, bool _approve)`: ESSENCE stakers vote on Catalyst proposals.
19. `finalizeCatalyst(uint256 _catalystId)`: Activates a Catalyst if it passes voting.
20. `updateCatalystData(uint256 _catalystId, bytes memory _newData)`: A designated oracle or trusted relay updates the data for an active Catalyst, impacting NFT evolution. (Simulated external interaction)
21. `getActiveCatalysts()`: (View) Retrieves a list of all currently active catalysts.

**F. User Interaction & NFT Lifecycle:**
22. `mintChronoNFT(uint256 _initialTemplateId)`: Mints a new ChronoNFT using an approved initial generative attribute template. May require ESSENCE payment or ETH.
23. `initiateNFTEvolution(uint256 _tokenId)`: Allows an NFT owner to manually trigger their specific NFT's evolution, based on current directives and catalysts, for a fee or staking ESSENCE.
24. `fuseTemporalShardToNFT(uint256 _tokenId, uint256 _shardId, uint256 _shardAmount)`: Fuses a specific quantity of Temporal Shards with a ChronoNFT, unlocking hidden evolutionary paths or special attributes.
25. `getNFTCurrentAttributes(uint256 _tokenId)`: (View) Returns a structured view of the ChronoNFT's current, dynamic attributes.
26. `getNFTMetadataURI(uint256 _tokenId)`: (View) Returns the dynamic metadata URI for a ChronoNFT, reflecting its current state.
27. `getNFTEvolutionTimeline(uint256 _tokenId)`: (View) Provides a history of a ChronoNFT's past evolutions and changes.

**G. Governance & Economic Mechanisms (Related to ESSENCE & General):**
28. `claimVotingRewards()`: Allows ESSENCE stakers to claim rewards for successfully voting on proposals.
29. `withdrawStakedEssence(uint256 _proposalType, uint256 _proposalId)`: Allows users to withdraw their staked ESSENCE from a finalized or failed proposal.
30. `mintEssence(address _to, uint256 _amount)`: Mints `EvolutionaryEssence` tokens to a recipient (controlled by `MINTER_ROLE`).
31. `burnEssence(uint256 _amount)`: Allows burning of `EvolutionaryEssence` tokens.
32. `mintTemporalShard(uint256 _shardId, uint256 _amount, bytes memory _data)`: Mints new `TemporalShard` tokens (controlled by `MINTER_ROLE`).
33. `burnTemporalShard(address _from, uint256 _shardId, uint256 _amount)`: Burns `TemporalShard` tokens from an address.

This detailed structure provides a robust framework for a dynamic, community-governed NFT ecosystem.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// ChronoForge Smart Contract: Outline and Function Summary

// Contract Name: ChronoForge
// Description: A Protocol for Time-Evolving Dynamic NFTs, Gamified Governance, and Generative Digital Assets.
// It integrates ERC721 (ChronoNFTs), ERC20 (Evolutionary Essence), and ERC1155 (Temporal Shards) directly within
// a single contract, orchestrated by Epochs, community-voted Directives, Generative Attribute Templates,
// and external data Catalysts.

// I. Core Components & Standards:
//    - ChronoNFT (ERC721Enumerable): The core dynamic NFTs managed by this contract.
//    - EvolutionaryEssence (ERC20): A utility and governance token for staking, voting, and interacting with the system.
//    - TemporalShards (ERC1155): Collectible components that can be fused with ChronoNFTs.
//    - AccessControl: For role-based permissions (admin, minter).
//    - Pausable: For emergency contract pausing.
//    - ReentrancyGuard: To prevent reentrancy attacks.

// II. Key Enums & Structs:
//    - EvolutionState: Tracks the current evolutionary phase of an NFT.
//    - ProposalStatus: For tracking the lifecycle of governance proposals.
//    - AttributeTemplate: Defines a generative art/trait component.
//    - EvolutionaryDirective: Represents a governance-approved rule for NFT evolution.
//    - Catalyst: Defines an external data influence or event trigger.
//    - NFTData: Stores dynamic attributes and evolution history for each ChronoNFT.

// III. Outline of Functions (20+ unique functions beyond standard ERC implementations):

// A. Contract Management & Core Infrastructure (AccessControlled):
//    1. constructor(): Initializes the contract, sets up roles, and defines initial parameters for ERC721, ERC20, and ERC1155.
//    2. setEpochAdvanceInterval(uint256 _intervalSeconds): Sets the duration for each epoch. (Admin/Governance)
//    3. pause(): Pauses core contract functionalities in emergencies. (Admin)
//    4. unpause(): Unpauses the contract. (Admin)
//    5. grantRole(bytes32 role, address account): Grants a specified role to an account. (Admin)

// B. Epoch & Evolution Engine:
//    6. advanceEpoch(): Progresses the system to the next epoch. This triggers the activation of pending directives/catalysts and marks a new phase for NFT evolution.
//    7. getEpochDetails(): (View) Retrieves current epoch number, start time, and active proposals.
//    8. triggerNFTGlobalEvolution(): Initiates a mass evolution for all eligible ChronoNFTs based on the current epoch's directives and active catalysts. Can be called by anyone, but frequency limited.

// C. Generative Attributes & Templates (NFT Trait Management):
//    9. submitAttributeTemplate(string memory _name, string memory _uri, uint256 _rarityScore): Users propose new generative art/trait templates. Requires ESSENCE stake as a bond.
//    10. voteOnAttributeTemplate(uint256 _templateId, bool _approve): ESSENCE stakers vote on proposed templates.
//    11. finalizeAttributeTemplate(uint256 _templateId): Activates a template if it passes voting, making it available for NFT evolution.
//    12. getAvailableAttributeTemplates(): (View) Lists all currently active (approved) generative attribute templates.

// D. Evolutionary Directives (Governance for Evolution Rules):
//    13. proposeEvolutionaryDirective(string memory _name, string memory _description, bytes memory _data): Propose a new rule or theme that guides NFT evolution. Requires ESSENCE stake. The _data can encode complex parameters.
//    14. voteOnEvolutionaryDirective(uint256 _directiveId, bool _approve): ESSENCE stakers cast their votes on directive proposals.
//    15. finalizeEvolutionaryDirective(uint256 _directiveId): Activates a directive if it passes voting, influencing future evolutions.
//    16. getActiveDirectives(): (View) Retrieves a list of all currently active evolutionary directives.

// E. Catalysts & External Influences (Simulated Oracle Interaction):
//    17. submitCatalystProposal(string memory _name, string memory _dataFeedUrl, bytes memory _params): Propose an external data source or a specific interaction (Catalyst) that can influence evolution. Requires ESSENCE stake.
//    18. voteOnCatalystProposal(uint256 _catalystId, bool _approve): ESSENCE stakers vote on Catalyst proposals.
//    19. finalizeCatalyst(uint256 _catalystId): Activates a Catalyst if it passes voting.
//    20. updateCatalystData(uint256 _catalystId, bytes memory _newData): A designated oracle or trusted relay updates the data for an active Catalyst, impacting NFT evolution. (Simulated external interaction)
//    21. getActiveCatalysts(): (View) Retrieves a list of all currently active catalysts.

// F. User Interaction & NFT Lifecycle:
//    22. mintChronoNFT(uint256 _initialTemplateId): Mints a new ChronoNFT using an approved initial generative attribute template. May require ESSENCE payment or ETH.
//    23. initiateNFTEvolution(uint256 _tokenId): Allows an NFT owner to manually trigger their specific NFT's evolution, based on current directives and catalysts, for a fee or staking ESSENCE.
//    24. fuseTemporalShardToNFT(uint256 _tokenId, uint256 _shardId, uint256 _shardAmount): Fuses a specific quantity of Temporal Shards with a ChronoNFT, unlocking hidden evolutionary paths or special attributes.
//    25. getNFTCurrentAttributes(uint256 _tokenId): (View) Returns a structured view of the ChronoNFT's current, dynamic attributes.
//    26. getNFTMetadataURI(uint256 _tokenId): (View) Returns the dynamic metadata URI for a ChronoNFT, reflecting its current state.
//    27. getNFTEvolutionTimeline(uint256 _tokenId): (View) Provides a history of a ChronoNFT's past evolutions and changes.

// G. Governance & Economic Mechanisms (Related to ESSENCE & General):
//    28. claimVotingRewards(): Allows ESSENCE stakers to claim rewards for successfully voting on proposals.
//    29. withdrawStakedEssence(uint256 _proposalType, uint256 _proposalId): Allows users to withdraw their staked ESSENCE from a finalized or failed proposal.
//    30. mintEssence(address _to, uint256 _amount): Mints EvolutionaryEssence tokens to a recipient (controlled by MINTER_ROLE).
//    31. burnEssence(uint256 _amount): Allows burning of EvolutionaryEssence tokens.
//    32. mintTemporalShard(uint256 _shardId, uint256 _amount, bytes memory _data): Mints new TemporalShard tokens (controlled by MINTER_ROLE).
//    33. burnTemporalShard(address _from, uint256 _shardId, uint256 _amount): Burns TemporalShard tokens from an address.

contract ChronoForge is ERC721Enumerable, ERC20, ERC1155, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Access Control Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // For updating Catalyst data

    // --- Epoch & Time-Based Evolution ---
    struct EpochData {
        uint256 epochNumber;
        uint256 startTime;
        uint256 lastGlobalEvolutionTime; // To rate limit triggerNFTGlobalEvolution
        uint256[] activeDirectives;
        uint256[] activeCatalysts;
    }
    EpochData public currentEpoch;
    uint256 public epochAdvanceInterval; // Time in seconds between epochs

    // --- NFT Evolution State & Data ---
    enum EvolutionState {
        Seed,       // Initial state
        Evolving,   // Currently undergoing evolution
        Stagnant,   // Ready for evolution but not yet triggered
        Mastered    // Achieved final or specific state
    }

    struct NFTAttribute {
        string traitType;
        string value;
    }

    struct EvolutionRecord {
        uint256 epoch;
        string changes; // JSON string or descriptive text
        uint256 timestamp;
    }

    struct NFTData {
        uint256 templateId; // Initial template ID
        EvolutionState state;
        NFTAttribute[] attributes; // Dynamic attributes
        uint256 lastEvolutionEpoch;
        EvolutionRecord[] evolutionHistory;
        mapping(uint256 => uint256) fusedShards; // shardId => amount
    }
    mapping(uint256 => NFTData) private _chronoNFTsData;
    Counters.Counter private _tokenIdCounter;

    // --- Governance & Proposals ---
    enum ProposalType {
        AttributeTemplate,
        EvolutionaryDirective,
        Catalyst
    }

    enum ProposalStatus {
        Pending,
        ActiveVoting,
        Approved,
        Rejected,
        Finalized
    }

    struct Proposal {
        ProposalType propType;
        uint256 id;
        string name;
        address proposer;
        uint256 stakeRequired;
        uint256 stakedAmount;
        mapping(address => bool) hasVoted;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 submissionTime;
        uint256 votingEndTime;
        ProposalStatus status;
        bytes data; // Generic data for directives/catalysts/templates (e.g., URI, parameters)
    }

    // --- Attribute Templates ---
    struct AttributeTemplate {
        string name;
        string uri; // Base URI for the generative component
        uint256 rarityScore; // For selection bias
        bool isActive;
        bool isBurnable; // Can be removed
    }
    mapping(uint256 => AttributeTemplate) public attributeTemplates;
    mapping(uint256 => Proposal) public attributeTemplateProposals;
    Counters.Counter private _templateIdCounter;
    Counters.Counter private _templateProposalIdCounter;

    // --- Evolutionary Directives ---
    struct EvolutionaryDirective {
        string name;
        string description;
        bytes data; // Encoded instructions for evolution logic
        bool isActive;
    }
    mapping(uint256 => EvolutionaryDirective) public evolutionaryDirectives;
    mapping(uint256 => Proposal) public directiveProposals;
    Counters.Counter private _directiveIdCounter;
    Counters.Counter private _directiveProposalIdCounter;

    // --- Catalysts (Simulated Oracles) ---
    struct Catalyst {
        string name;
        string dataFeedUrl; // For off-chain reference
        bytes currentData; // The actual on-chain data from oracle
        bytes params; // Parameters for how the catalyst influences
        bool isActive;
    }
    mapping(uint256 => Catalyst) public catalysts;
    mapping(uint256 => Proposal) public catalystProposals;
    Counters.Counter private _catalystIdCounter;
    Counters.Counter private _catalystProposalIdCounter;

    // --- Economic Parameters ---
    uint256 public proposalStakeAmount;
    uint256 public votingDurationSeconds;
    uint256 public mintNFTCostEssence;
    uint256 public mintNFTCostETH;
    uint256 public manualEvolutionCostEssence;
    uint256 public votingRewardPercentage; // e.g., 500 for 5% of staked tokens distributed

    // --- Events ---
    event EpochAdvanced(uint256 indexed epochNumber, uint256 timestamp);
    event ChronoNFTMinted(uint256 indexed tokenId, address indexed owner, uint256 initialTemplateId);
    event ChronoNFTEvolved(uint256 indexed tokenId, uint256 indexed epoch, string changes);
    event TemporalShardFused(uint256 indexed tokenId, uint256 indexed shardId, uint256 amount);
    event ProposalSubmitted(ProposalType indexed propType, uint256 indexed proposalId, address indexed proposer, uint256 stake);
    event ProposalVoted(ProposalType indexed propType, uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalFinalized(ProposalType indexed propType, uint256 indexed proposalId, ProposalStatus status);
    event CatalystDataUpdated(uint256 indexed catalystId, bytes newData);
    event RewardsClaimed(address indexed receiver, uint256 amount);

    constructor(
        string memory _nftName,
        string memory _nftSymbol,
        string memory _essenceName,
        string memory _essenceSymbol,
        uint256 _initialEssenceSupply,
        string memory _shardsURI
    )
        ERC721Enumerable(_nftName, _nftSymbol)
        ERC20(_essenceName, _essenceSymbol)
        ERC1155(_shardsURI) // Base URI for Temporal Shards
        ReentrancyGuard()
    {
        // Set initial admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);

        // Initial ChronoForge parameters
        epochAdvanceInterval = 7 days; // Default to 7 days
        currentEpoch.epochNumber = 0;
        currentEpoch.startTime = block.timestamp;
        currentEpoch.lastGlobalEvolutionTime = block.timestamp;

        // ERC20 Essence parameters
        _mint(msg.sender, _initialEssenceSupply * (10 ** decimals())); // Mint initial supply to deployer
        proposalStakeAmount = 100 * (10 ** decimals()); // 100 ESSENCE
        votingDurationSeconds = 3 days;
        mintNFTCostEssence = 50 * (10 ** decimals()); // 50 ESSENCE
        mintNFTCostETH = 0.01 ether; // 0.01 ETH
        manualEvolutionCostEssence = 25 * (10 ** decimals()); // 25 ESSENCE
        votingRewardPercentage = 500; // 5%

        _tokenIdCounter.increment(); // Start token IDs from 1
        _templateIdCounter.increment();
        _templateProposalIdCounter.increment();
        _directiveIdCounter.increment();
        _directiveProposalIdCounter.increment();
        _catalystIdCounter.increment();
        _catalystProposalIdCounter.increment();
    }

    // --- A. Contract Management & Core Infrastructure ---

    function setEpochAdvanceInterval(uint256 _intervalSeconds) public onlyRole(ADMIN_ROLE) {
        require(_intervalSeconds > 0, "Interval must be positive");
        epochAdvanceInterval = _intervalSeconds;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable, ERC1155) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Add specific logic if needed before transfer, e.g., restrict transfer during evolution
    }

    // --- B. Epoch & Evolution Engine ---

    function advanceEpoch() public nonReentrant whenNotPaused {
        require(block.timestamp >= currentEpoch.startTime + epochAdvanceInterval, "Not enough time has passed since last epoch");

        currentEpoch.epochNumber++;
        currentEpoch.startTime = block.timestamp;
        currentEpoch.lastGlobalEvolutionTime = block.timestamp; // Reset global evolution trigger

        // Finalize pending proposals from previous epoch
        _finalizeAllProposals();

        // Clear active directives/catalysts for new epoch (or migrate them based on logic)
        // For simplicity, let's reset and allow new ones to be finalized in this epoch
        delete currentEpoch.activeDirectives;
        delete currentEpoch.activeCatalysts;

        emit EpochAdvanced(currentEpoch.epochNumber, block.timestamp);
    }

    function getEpochDetails() public view returns (uint256 epochNumber, uint256 startTime, uint256 lastGlobalEvolutionTime, uint256[] memory activeDirectives, uint256[] memory activeCatalysts) {
        return (currentEpoch.epochNumber, currentEpoch.startTime, currentEpoch.lastGlobalEvolutionTime, currentEpoch.activeDirectives, currentEpoch.activeCatalysts);
    }

    function triggerNFTGlobalEvolution() public nonReentrant whenNotPaused {
        require(block.timestamp >= currentEpoch.lastGlobalEvolutionTime + (epochAdvanceInterval / 2), "Global evolution can only be triggered once per half epoch");
        currentEpoch.lastGlobalEvolutionTime = block.timestamp;

        uint256 totalNFTs = totalSupply();
        for (uint256 i = 0; i < totalNFTs; i++) {
            uint256 tokenId = tokenByIndex(i);
            _evolveNFT(tokenId, false); // Pass false for manual trigger, true for global
        }
    }

    // --- C. Generative Attributes & Templates ---

    function submitAttributeTemplate(string memory _name, string memory _uri, uint256 _rarityScore) public nonReentrant whenNotPaused {
        require(balanceOf(msg.sender) >= proposalStakeAmount, "Insufficient ESSENCE to stake for proposal");

        _approve(msg.sender, address(this), proposalStakeAmount);
        _transfer(msg.sender, address(this), proposalStakeAmount); // Stake ESSENCE

        uint256 proposalId = _templateProposalIdCounter.current();
        _templateProposalIdCounter.increment();

        attributeTemplateProposals[proposalId] = Proposal({
            propType: ProposalType.AttributeTemplate,
            id: proposalId,
            name: _name,
            proposer: msg.sender,
            stakeRequired: proposalStakeAmount,
            stakedAmount: proposalStakeAmount,
            votesFor: 0,
            votesAgainst: 0,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + votingDurationSeconds,
            status: ProposalStatus.ActiveVoting,
            data: abi.encode(_uri, _rarityScore)
        });

        emit ProposalSubmitted(ProposalType.AttributeTemplate, proposalId, msg.sender, proposalStakeAmount);
    }

    function voteOnAttributeTemplate(uint256 _templateProposalId, bool _approveVote) public nonReentrant whenNotPaused {
        Proposal storage proposal = attributeTemplateProposals[_templateProposalId];
        require(proposal.status == ProposalStatus.ActiveVoting, "Proposal not in active voting state");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended");
        require(balanceOf(msg.sender) > 0, "Voter must hold ESSENCE");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        uint256 voterEssenceBalance = balanceOf(msg.sender);

        if (_approveVote) {
            proposal.votesFor += voterEssenceBalance;
        } else {
            proposal.votesAgainst += voterEssenceBalance;
        }

        emit ProposalVoted(ProposalType.AttributeTemplate, _templateProposalId, msg.sender, _approveVote);
    }

    function finalizeAttributeTemplate(uint256 _templateProposalId) public nonReentrant whenNotPaused {
        Proposal storage proposal = attributeTemplateProposals[_templateProposalId];
        require(proposal.status == ProposalStatus.ActiveVoting, "Proposal not in active voting state");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended yet");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Approved;
            uint256 templateId = _templateIdCounter.current();
            _templateIdCounter.increment();

            (string memory uri, uint256 rarityScore) = abi.decode(proposal.data, (string, uint256));
            attributeTemplates[templateId] = AttributeTemplate({
                name: proposal.name,
                uri: uri,
                rarityScore: rarityScore,
                isActive: true,
                isBurnable: true
            });
            // Distribute rewards to voters
            _distributeVotingRewards(proposal.id, ProposalType.AttributeTemplate, true);
        } else {
            proposal.status = ProposalStatus.Rejected;
            // Return staked amount to proposer
            _transfer(address(this), proposal.proposer, proposal.stakedAmount);
            // No rewards for voters on rejected proposals
        }
        emit ProposalFinalized(ProposalType.AttributeTemplate, _templateProposalId, proposal.status);
    }

    function getAvailableAttributeTemplates() public view returns (uint256[] memory activeTemplateIds) {
        uint256[] memory allTemplates = new uint256[](_templateIdCounter.current() -1); // Assuming IDs start from 1
        uint256 count = 0;
        for (uint256 i = 1; i < _templateIdCounter.current(); i++) {
            if (attributeTemplates[i].isActive) {
                allTemplates[count] = i;
                count++;
            }
        }
        assembly {
            mstore(allTemplates, count)
        }
        return allTemplates;
    }

    // --- D. Evolutionary Directives (Governance for Evolution Rules) ---

    function proposeEvolutionaryDirective(string memory _name, string memory _description, bytes memory _data) public nonReentrant whenNotPaused {
        require(balanceOf(msg.sender) >= proposalStakeAmount, "Insufficient ESSENCE to stake for proposal");

        _approve(msg.sender, address(this), proposalStakeAmount);
        _transfer(msg.sender, address(this), proposalStakeAmount);

        uint256 proposalId = _directiveProposalIdCounter.current();
        _directiveProposalIdCounter.increment();

        directiveProposals[proposalId] = Proposal({
            propType: ProposalType.EvolutionaryDirective,
            id: proposalId,
            name: _name,
            proposer: msg.sender,
            stakeRequired: proposalStakeAmount,
            stakedAmount: proposalStakeAmount,
            votesFor: 0,
            votesAgainst: 0,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + votingDurationSeconds,
            status: ProposalStatus.ActiveVoting,
            data: abi.encode(_description, _data) // Store description and actual directive data
        });

        emit ProposalSubmitted(ProposalType.EvolutionaryDirective, proposalId, msg.sender, proposalStakeAmount);
    }

    function voteOnEvolutionaryDirective(uint256 _directiveProposalId, bool _approveVote) public nonReentrant whenNotPaused {
        Proposal storage proposal = directiveProposals[_directiveProposalId];
        require(proposal.status == ProposalStatus.ActiveVoting, "Proposal not in active voting state");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended");
        require(balanceOf(msg.sender) > 0, "Voter must hold ESSENCE");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        uint256 voterEssenceBalance = balanceOf(msg.sender);

        if (_approveVote) {
            proposal.votesFor += voterEssenceBalance;
        } else {
            proposal.votesAgainst += voterEssenceBalance;
        }

        emit ProposalVoted(ProposalType.EvolutionaryDirective, _directiveProposalId, msg.sender, _approveVote);
    }

    function finalizeEvolutionaryDirective(uint256 _directiveProposalId) public nonReentrant whenNotPaused {
        Proposal storage proposal = directiveProposals[_directiveProposalId];
        require(proposal.status == ProposalStatus.ActiveVoting, "Proposal not in active voting state");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended yet");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Approved;
            uint256 directiveId = _directiveIdCounter.current();
            _directiveIdCounter.increment();

            (string memory description, bytes memory data) = abi.decode(proposal.data, (string, bytes));
            evolutionaryDirectives[directiveId] = EvolutionaryDirective({
                name: proposal.name,
                description: description,
                data: data,
                isActive: true
            });
            currentEpoch.activeDirectives.push(directiveId); // Add to active directives for current epoch
            _distributeVotingRewards(proposal.id, ProposalType.EvolutionaryDirective, true);
        } else {
            proposal.status = ProposalStatus.Rejected;
            _transfer(address(this), proposal.proposer, proposal.stakedAmount);
        }
        emit ProposalFinalized(ProposalType.EvolutionaryDirective, _directiveProposalId, proposal.status);
    }

    function getActiveDirectives() public view returns (uint256[] memory) {
        return currentEpoch.activeDirectives;
    }

    // --- E. Catalysts & External Influences (Simulated Oracle Interaction) ---

    function submitCatalystProposal(string memory _name, string memory _dataFeedUrl, bytes memory _params) public nonReentrant whenNotPaused {
        require(balanceOf(msg.sender) >= proposalStakeAmount, "Insufficient ESSENCE to stake for proposal");

        _approve(msg.sender, address(this), proposalStakeAmount);
        _transfer(msg.sender, address(this), proposalStakeAmount);

        uint256 proposalId = _catalystProposalIdCounter.current();
        _catalystProposalIdCounter.increment();

        catalystProposals[proposalId] = Proposal({
            propType: ProposalType.Catalyst,
            id: proposalId,
            name: _name,
            proposer: msg.sender,
            stakeRequired: proposalStakeAmount,
            stakedAmount: proposalStakeAmount,
            votesFor: 0,
            votesAgainst: 0,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + votingDurationSeconds,
            status: ProposalStatus.ActiveVoting,
            data: abi.encode(_dataFeedUrl, _params) // Store URL and params
        });

        emit ProposalSubmitted(ProposalType.Catalyst, proposalId, msg.sender, proposalStakeAmount);
    }

    function voteOnCatalystProposal(uint256 _catalystProposalId, bool _approveVote) public nonReentrant whenNotPaused {
        Proposal storage proposal = catalystProposals[_catalystProposalId];
        require(proposal.status == ProposalStatus.ActiveVoting, "Proposal not in active voting state");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended");
        require(balanceOf(msg.sender) > 0, "Voter must hold ESSENCE");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        uint256 voterEssenceBalance = balanceOf(msg.sender);

        if (_approveVote) {
            proposal.votesFor += voterEssenceBalance;
        } else {
            proposal.votesAgainst += voterEssenceBalance;
        }

        emit ProposalVoted(ProposalType.Catalyst, _catalystProposalId, msg.sender, _approveVote);
    }

    function finalizeCatalyst(uint256 _catalystProposalId) public nonReentrant whenNotPaused {
        Proposal storage proposal = catalystProposals[_catalystProposalId];
        require(proposal.status == ProposalStatus.ActiveVoting, "Proposal not in active voting state");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended yet");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Approved;
            uint256 catalystId = _catalystIdCounter.current();
            _catalystIdCounter.increment();

            (string memory dataFeedUrl, bytes memory params) = abi.decode(proposal.data, (string, bytes));
            catalysts[catalystId] = Catalyst({
                name: proposal.name,
                dataFeedUrl: dataFeedUrl,
                currentData: "", // Initial data is empty, requires oracle update
                params: params,
                isActive: true
            });
            currentEpoch.activeCatalysts.push(catalystId); // Add to active catalysts for current epoch
            _distributeVotingRewards(proposal.id, ProposalType.Catalyst, true);
        } else {
            proposal.status = ProposalStatus.Rejected;
            _transfer(address(this), proposal.proposer, proposal.stakedAmount);
        }
        emit ProposalFinalized(ProposalType.Catalyst, _catalystProposalId, proposal.status);
    }

    function updateCatalystData(uint256 _catalystId, bytes memory _newData) public onlyRole(ORACLE_ROLE) nonReentrant whenNotPaused {
        Catalyst storage catalyst = catalysts[_catalystId];
        require(catalyst.isActive, "Catalyst is not active");
        catalyst.currentData = _newData;
        emit CatalystDataUpdated(_catalystId, _newData);
    }

    function getActiveCatalysts() public view returns (uint256[] memory) {
        return currentEpoch.activeCatalysts;
    }

    // --- F. User Interaction & NFT Lifecycle ---

    function mintChronoNFT(uint256 _initialTemplateId) public payable nonReentrant whenNotPaused {
        require(attributeTemplates[_initialTemplateId].isActive, "Initial template not active or found");
        require(msg.value >= mintNFTCostETH || balanceOf(msg.sender) >= mintNFTCostEssence, "Insufficient ETH or ESSENCE for minting");

        if (msg.value < mintNFTCostETH) {
            _approve(msg.sender, address(this), mintNFTCostEssence);
            _transfer(msg.sender, address(this), mintNFTCostEssence);
        } else {
            // Refund excess ETH if any
            if (msg.value > mintNFTCostETH) {
                payable(msg.sender).transfer(msg.value - mintNFTCostETH);
            }
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        _chronoNFTsData[tokenId].templateId = _initialTemplateId;
        _chronoNFTsData[tokenId].state = EvolutionState.Seed;
        _chronoNFTsData[tokenId].lastEvolutionEpoch = currentEpoch.epochNumber;
        _chronoNFTsData[tokenId].attributes.push(NFTAttribute("Base Template", attributeTemplates[_initialTemplateId].name));
        _chronoNFTsData[tokenId].evolutionHistory.push(EvolutionRecord({
            epoch: currentEpoch.epochNumber,
            changes: "Minted with initial template",
            timestamp: block.timestamp
        }));

        emit ChronoNFTMinted(tokenId, msg.sender, _initialTemplateId);
    }

    function initiateNFTEvolution(uint256 _tokenId) public nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(balanceOf(msg.sender) >= manualEvolutionCostEssence, "Insufficient ESSENCE for manual evolution");

        _approve(msg.sender, address(this), manualEvolutionCostEssence);
        _transfer(msg.sender, address(this), manualEvolutionCostEssence); // Burn or send to treasury

        _evolveNFT(_tokenId, true); // Pass true for manual trigger
    }

    function _evolveNFT(uint256 _tokenId, bool isManualTrigger) internal {
        NFTData storage nft = _chronoNFTsData[_tokenId];
        require(nft.state != EvolutionState.Mastered, "NFT has reached mastered state");
        require(isManualTrigger || nft.lastEvolutionEpoch < currentEpoch.epochNumber, "NFT already evolved this epoch or manually triggered");

        // --- Complex Evolution Logic Placeholder ---
        // This is where the magic happens, combining directives, catalysts, and templates.
        // For demonstration, we'll simulate a simple change.

        string memory changesDescription = "";
        uint256 newTemplateId = nft.templateId; // Default to current template

        // 1. Influence from Active Directives
        for (uint256 i = 0; i < currentEpoch.activeDirectives.length; i++) {
            EvolutionaryDirective storage directive = evolutionaryDirectives[currentEpoch.activeDirectives[i]];
            // Example: If a directive's data implies a 'color_shift'
            if (keccak256(directive.data) == keccak256(abi.encodePacked("color_shift_green"))) {
                nft.attributes.push(NFTAttribute("Color Shift", "Green Tint"));
                changesDescription = string(abi.encodePacked(changesDescription, "Color shifted to green. "));
            }
            // Add more complex directive interpretation here
        }

        // 2. Influence from Active Catalysts
        for (uint256 i = 0; i < currentEpoch.activeCatalysts.length; i++) {
            Catalyst storage catalyst = catalysts[currentEpoch.activeCatalysts[i]];
            if (catalyst.currentData.length > 0) {
                // Example: if catalyst data represents a number and it's even
                if (bytesToUint(catalyst.currentData) % 2 == 0) {
                    nft.attributes.push(NFTAttribute("Catalyst Effect", "Even Number"));
                    changesDescription = string(abi.encodePacked(changesDescription, "Catalyst triggered an 'even' effect. "));
                }
                // Add more complex catalyst data interpretation here
            }
        }

        // 3. Apply Generative Attribute Templates (e.g., random selection from active templates)
        uint256[] memory availableTemplates = getAvailableAttributeTemplates();
        if (availableTemplates.length > 0) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, block.difficulty))) % availableTemplates.length;
            newTemplateId = availableTemplates[randomIndex];
            if (newTemplateId != nft.templateId) {
                nft.attributes.push(NFTAttribute("New Form", attributeTemplates[newTemplateId].name));
                changesDescription = string(abi.encodePacked(changesDescription, "Evolved to new form: ", attributeTemplates[newTemplateId].name, ". "));
                nft.templateId = newTemplateId;
            }
        }

        // 4. Temporal Shard Effects
        // Check for specific shards fused and apply effects (e.g., permanent buff, unique trait)
        if (nft.fusedShards[1] > 0) { // Example: Shard 1 grants a 'Mythic' trait
            nft.attributes.push(NFTAttribute("Shard Effect", "Mythic Aura"));
            changesDescription = string(abi.encodePacked(changesDescription, "Mythic Aura from Shard 1. "));
        }

        if (keccak256(abi.encodePacked(changesDescription)) == keccak256(abi.encodePacked(""))) {
             changesDescription = "No significant changes this evolution cycle.";
        }

        nft.state = EvolutionState.Stagnant; // Ready for next evolution
        nft.lastEvolutionEpoch = currentEpoch.epochNumber;
        nft.evolutionHistory.push(EvolutionRecord({
            epoch: currentEpoch.epochNumber,
            changes: changesDescription,
            timestamp: block.timestamp
        }));

        emit ChronoNFTEvolved(_tokenId, currentEpoch.epochNumber, changesDescription);
    }

    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        for (uint256 i = 0; i < b.length; i++) {
            number = number + uint8(b[i]) * (2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function fuseTemporalShardToNFT(uint256 _tokenId, uint256 _shardId, uint256 _shardAmount) public nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved of NFT");
        require(balanceOf(msg.sender, _shardId) >= _shardAmount, "Insufficient shards");

        _burn(msg.sender, _shardId, _shardAmount); // Burn shards from owner
        _chronoNFTsData[_tokenId].fusedShards[_shardId] += _shardAmount;

        // Apply immediate effects or flag for next evolution
        _chronoNFTsData[_tokenId].evolutionHistory.push(EvolutionRecord({
            epoch: currentEpoch.epochNumber,
            changes: string(abi.encodePacked("Fused ", _shardAmount.toString(), "x Shard ", _shardId.toString())),
            timestamp: block.timestamp
        }));

        emit TemporalShardFused(_tokenId, _shardId, _shardAmount);
    }

    function getNFTCurrentAttributes(uint256 _tokenId) public view returns (NFTAttribute[] memory) {
        return _chronoNFTsData[_tokenId].attributes;
    }

    function getNFTEvolutionTimeline(uint256 _tokenId) public view returns (EvolutionRecord[] memory) {
        return _chronoNFTsData[_tokenId].evolutionHistory;
    }

    // Overriding ERC721's tokenURI for dynamic metadata generation
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        NFTData storage nft = _chronoNFTsData[tokenId];
        AttributeTemplate storage currentTemplate = attributeTemplates[nft.templateId];

        bytes memory attributesJson = "[";
        for (uint256 i = 0; i < nft.attributes.length; i++) {
            attributesJson = abi.encodePacked(
                attributesJson,
                '{"trait_type":"', nft.attributes[i].traitType, '","value":"', nft.attributes[i].value, '"}',
                (i == nft.attributes.length - 1 ? "" : ",")
            );
        }
        attributesJson = abi.encodePacked(attributesJson, "]");

        string memory json = string(abi.encodePacked(
            '{"name":"', name(), ' #', tokenId.toString(),
            '","description":"A ChronoForge NFT, evolving through epochs and community directives. Current state: ', _stateToString(nft.state),
            '","image":"', currentTemplate.uri, // Base image from template
            '","attributes":', attributesJson,
            '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function _stateToString(EvolutionState state) internal pure returns (string memory) {
        if (state == EvolutionState.Seed) return "Seed";
        if (state == EvolutionState.Evolving) return "Evolving";
        if (state == EvolutionState.Stagnant) return "Stagnant";
        if (state == EvolutionState.Mastered) return "Mastered";
        return "Unknown";
    }

    // --- G. Governance & Economic Mechanisms ---

    function _distributeVotingRewards(uint256 _proposalId, ProposalType _propType, bool _isApproved) internal {
        // Only distribute rewards for approved proposals
        if (!_isApproved) {
            return;
        }

        Proposal storage proposal;
        if (_propType == ProposalType.AttributeTemplate) {
            proposal = attributeTemplateProposals[_proposalId];
        } else if (_propType == ProposalType.EvolutionaryDirective) {
            proposal = directiveProposals[_proposalId];
        } else if (_propType == ProposalType.Catalyst) {
            proposal = catalystProposals[_proposalId];
        } else {
            revert("Invalid proposal type");
        }

        // Return initial stake to proposer
        _transfer(address(this), proposal.proposer, proposal.stakedAmount);

        // Distribute a percentage of the *total* ESSENCE staked for the proposal (including proposer's stake)
        // This is a simple example; a more complex system might pull from a treasury or newly minted tokens.
        uint256 totalStaked = proposal.stakedAmount; // Only considering proposer's stake for now, not voters.
                                                    // A more complex system would track individual voter stakes.

        if (totalStaked == 0) return; // No rewards if nothing was staked
        
        uint256 rewardPool = (totalStaked * votingRewardPercentage) / 10000; // 10000 for 100%
        // This 'rewardPool' should ideally come from a treasury or newly minted tokens,
        // not from the proposer's stake, unless the proposer *pays* for rewards.
        // For simplicity, let's assume `rewardPool` is just a symbolic value for now.
        // Actual reward distribution would require tracking all voters and their stake.
        // This function will simply emit an event indicating rewards could be claimed.

        // In a real scenario, you'd iterate through voters and distribute rewards based on their vote weight.
        // For this example, we'll simplify and make it a general claimable reward.
        // For now, this acts as a placeholder for a more complex reward distribution system.
    }


    function claimVotingRewards() public nonReentrant whenNotPaused {
        // This is a placeholder for a complex reward distribution logic.
        // In a real system, you'd track individual user's voting power and successful votes
        // and calculate their specific rewards from a pool.
        // For this contract, it simply represents the *intent* of claiming.
        // For demonstration purposes, we will not actually transfer tokens here.
        // A full implementation would require a `rewards` mapping.
        // emit RewardsClaimed(msg.sender, 0); // No actual transfer, just event.
        revert("Reward claiming is a placeholder and not fully implemented yet.");
    }

    function withdrawStakedEssence(ProposalType _propType, uint256 _proposalId) public nonReentrant whenNotPaused {
        Proposal storage proposal;
        if (_propType == ProposalType.AttributeTemplate) {
            proposal = attributeTemplateProposals[_proposalId];
        } else if (_propType == ProposalType.EvolutionaryDirective) {
            proposal = directiveProposals[_proposalId];
        } else if (_propType == ProposalType.Catalyst) {
            proposal = catalystProposals[_proposalId];
        } else {
            revert("Invalid proposal type");
        }

        require(proposal.proposer == msg.sender, "Only proposer can withdraw stake");
        require(proposal.status == ProposalStatus.Rejected || proposal.status == ProposalStatus.Finalized, "Proposal not finalized or rejected");
        require(proposal.stakedAmount > 0, "No stake to withdraw");

        uint256 amountToReturn = proposal.stakedAmount;
        proposal.stakedAmount = 0; // Prevent double withdrawal
        _transfer(address(this), msg.sender, amountToReturn);
    }

    // Minter role for Essence
    function mintEssence(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) nonReentrant whenNotPaused {
        _mint(_to, _amount);
    }

    function burnEssence(uint256 _amount) public nonReentrant whenNotPaused {
        _burn(msg.sender, _amount);
    }

    // Minter role for Temporal Shards
    function mintTemporalShard(uint256 _shardId, uint256 _amount, bytes memory _data) public onlyRole(MINTER_ROLE) nonReentrant whenNotPaused {
        _mint(msg.sender, _shardId, _amount, _data);
    }

    function burnTemporalShard(address _from, uint256 _shardId, uint256 _amount) public nonReentrant whenNotPaused {
        require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "Caller is not owner nor approved for all");
        _burn(_from, _shardId, _amount);
    }

    // --- Internal Helpers ---
    function _finalizeAllProposals() internal {
        // Iterate through all proposals and finalize any that have passed their voting period
        // For simplicity, this iteration is simplified. In a large system, this might be
        // a more targeted or batched operation to save gas.

        // Attribute Templates
        for (uint256 i = 1; i < _templateProposalIdCounter.current(); i++) {
            if (attributeTemplateProposals[i].status == ProposalStatus.ActiveVoting &&
                block.timestamp >= attributeTemplateProposals[i].votingEndTime) {
                finalizeAttributeTemplate(i);
            }
        }

        // Evolutionary Directives
        for (uint256 i = 1; i < _directiveProposalIdCounter.current(); i++) {
            if (directiveProposals[i].status == ProposalStatus.ActiveVoting &&
                block.timestamp >= directiveProposals[i].votingEndTime) {
                finalizeEvolutionaryDirective(i);
            }
        }

        // Catalysts
        for (uint256 i = 1; i < _catalystProposalIdCounter.current(); i++) {
            if (catalystProposals[i].status == ProposalStatus.ActiveVoting &&
                block.timestamp >= catalystProposals[i].votingEndTime) {
                finalizeCatalyst(i);
            }
        }
    }

    // --- ERC165 Supports Interface (Required for OpenZeppelin) ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```