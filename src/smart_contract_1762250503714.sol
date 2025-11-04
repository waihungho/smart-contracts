This smart contract, named `AuraForge`, introduces an advanced, creative, and trendy concept: a decentralized nexus for **Dynamic, Self-Evolving Digital Assets (Auras)**, underpinned by a **Gamified Reputation System (AuraMarks)**, and governed by an **Adaptive Protocol Governance** mechanism influenced by both token stakes and accumulated reputation.

**Core Concepts:**

1.  **Auras (eNFTs):** ERC721-compliant tokens that are not static. Their attributes and metadata can evolve over time based on user interactions, internal protocol sentiment, and defined "evolution paths."
2.  **Aura Infusion:** A key interaction where users "infuse" their Auras, contributing to their individual "sentiment score" and the overall "Global Sentiment Pool" of the protocol. This drives evolution.
3.  **AuraMarks (SoulBound Tokens - SBT-like):** Non-transferable tokens representing a user's reputation within the `AuraForge` ecosystem. They are awarded for constructive engagement (e.g., successful Aura infusions, positive governance participation) and influence governance weight.
4.  **Global Sentiment Pool:** A contract-wide aggregate score reflecting the collective positive and negative actions within the protocol. It acts as a decentralized, on-chain "oracle" for protocol health and can influence Aura evolution conditions.
5.  **Adaptive Governance:** Proposals are voted on, with voting power dynamically calculated based on a combination of staked governance tokens and a user's `AuraMarks`. Protocol parameters can be adjusted through this adaptive system.
6.  **Dynamic Rewards:** Users who actively participate in Aura evolution and governance, and maintain high `AuraMarks`, can accrue and claim rewards from a community treasury.

---

### **Outline & Function Summary**

**Contract Name:** `AuraForge`

**I. Core Aura Asset Management (Dynamic eNFTs)**
This section handles the creation, interaction, and evolution of the dynamic Aura NFTs.

1.  `constructor(address _governanceToken, string memory _baseMetadataURI)`: Initializes the contract with the governance token address and a base URI for Aura metadata.
2.  `mintAura(string memory _initialMetadataURI)`: Mints a new Aura NFT for the caller, assigning it an initial evolution path and metadata.
3.  `infuseAura(uint256 _tokenId, uint256 _infusionAmount)`: Allows an Aura owner to 'infuse' their Aura. This increases the Aura's internal sentiment, contributes to its level progression, and updates the global sentiment pool.
4.  `requestAuraEvolution(uint256 _tokenId)`: Initiates an evolution check for a specific Aura. If conditions (based on its sentiment, level, and global sentiment) are met, the Aura's attributes and metadata are updated.
5.  `getAuraDetails(uint256 _tokenId)`: Retrieves comprehensive details about a specific Aura, including its owner, level, sentiment, and current metadata URI.
6.  `getAuraDynamicUintAttribute(uint256 _tokenId, bytes32 _attributeKey)`: Returns the value of a specific dynamic `uint256` attribute of an Aura.
7.  `getAuraDynamicStringAttribute(uint256 _tokenId, bytes32 _attributeKey)`: Returns the value of a specific dynamic `string` attribute of an Aura.
8.  `setAuraEvolutionPath(uint256 _tokenId, EvolutionPath _path)`: Allows the Aura owner (or governance for initial setup) to define or change the evolution path of an Aura, influencing how it reacts to interactions.

**II. Sentient Layer & Reputation (AuraMarks)**
This module manages the protocol's aggregated sentiment and user reputation scores.

9.  `awardAuraMark(address _user, uint256 _amount, bytes32 _reason)`: Awards non-transferable `AuraMarks` to a user for positive contributions (callable by trusted roles or governance).
10. `burnAuraMark(address _user, uint256 _amount, bytes32 _reason)`: Reduces `AuraMarks` for a user, potentially due to negative or fraudulent activities (callable by governance).
11. `getAuraMarkBalance(address _user)`: Returns the current `AuraMark` balance for a given user.
12. `getGlobalSentimentScore()`: Returns the current aggregate sentiment score of the entire `AuraForge` protocol.

**III. Adaptive Governance**
This section defines the proposal and voting mechanism, where voting power is dynamic.

13. `proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, string memory _description)`: Allows users with sufficient governance token and/or `AuraMarks` to propose changes to protocol parameters (e.g., evolution thresholds, reward rates).
14. `voteOnProposal(uint256 _proposalId, bool _support)`: Casts a vote on an active proposal. The weight of the vote is determined by the voter's combined governance token holdings and `AuraMark` balance.
15. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on proposal, applying the proposed parameter changes. This also influences the global sentiment pool.
16. `delegateAuraMarks(address _delegatee)`: Allows a user to delegate their `AuraMark` voting power to another address.
17. `getProposalDetails(uint256 _proposalId)`: Retrieves all details of a specific governance proposal.

**IV. Treasury & Rewards**
Manages the protocol's treasury and the distribution of rewards.

18. `claimRewards()`: Allows users to claim their accumulated rewards, which are calculated based on their positive interactions and `AuraMark` balance.
19. `distributeRewards(address[] memory _recipients, uint256[] memory _amounts)`: Initiates a distribution of rewards from the protocol treasury to specified recipients (callable by governance).
20. `depositToTreasury()`: Allows any user to deposit native currency (e.g., Ether) into the contract's treasury, increasing funds for rewards or protocol operations.

**V. Protocol Management & Standard ERC721 Functions**
Essential administrative and standard NFT functionalities.

21. `pause()`: Pauses core contract functionalities in case of an emergency (callable by owner).
22. `unpause()`: Unpauses the contract (callable by owner).
23. `setBaseAuraMetadataURI(string memory _newURI)`: Sets a new base URI for Aura metadata (callable by owner).
24. `name()`: (ERC721) Returns the NFT collection name.
25. `symbol()`: (ERC721) Returns the NFT collection symbol.
26. `balanceOf(address owner)`: (ERC721) Returns the number of NFTs owned by an address.
27. `ownerOf(uint256 tokenId)`: (ERC721) Returns the owner of a specific NFT.
28. `tokenURI(uint256 tokenId)`: (ERC721) Returns the metadata URI for a specific NFT, reflecting its current evolved state.
29. `approve(address to, uint256 tokenId)`: (ERC721) Approves an address to transfer a specific NFT.
30. `getApproved(uint256 tokenId)`: (ERC721) Returns the approved address for a specific NFT.
31. `setApprovalForAll(address operator, bool approved)`: (ERC721) Sets or revokes an operator's approval for all NFTs.
32. `isApprovedForAll(address owner, address operator)`: (ERC721) Checks if an operator is approved for all NFTs of an owner.
33. `transferFrom(address from, address to, uint256 tokenId)`: (ERC721) Transfers an NFT.
34. `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC721) Safely transfers an NFT.
35. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: (ERC721) Safely transfers an NFT with additional data.

This comprehensive set of functions covers the complex interactions required for dynamic NFTs, reputation, and adaptive governance, offering a truly unique and engaging on-chain experience.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom Errors for better readability and gas efficiency
error AuraForge__Unauthorized();
error AuraForge__InvalidTokenId();
error AuraForge__AuraAlreadyEvolving();
error AuraForge__AuraEvolutionNotReady();
error AuraForge__InsufficientInfusionAmount();
error AuraForge__NoAuraMarksToDelegate();
error AuraForge__AlreadyDelegated();
error AuraForge__SelfDelegationNotAllowed();
error AuraForge__ProposalNotFound();
error AuraForge__ProposalNotActive();
error AuraForge__ProposalAlreadyVoted();
error AuraForge__ProposalVotePeriodEnded();
error AuraForge__ProposalNotApproved();
error AuraForge__ProposalAlreadyExecuted();
error AuraForge__InvalidParameterKey();
error AuraForge__ZeroAddress();
error AuraForge__NoRewardsToClaim();
error AuraForge__InsufficientTreasuryBalance();

/**
 * @title AuraForge
 * @dev A decentralized nexus for Dynamic, Self-Evolving Digital Assets (Auras),
 *      powered by a Gamified Reputation System (AuraMarks), and governed by an
 *      Adaptive Protocol Governance mechanism influenced by both token stakes and accumulated reputation.
 */
contract AuraForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Interfaces ---
    // Minimal interface for a governance token
    interface IGovernanceToken {
        function balanceOf(address account) external view returns (uint256);
        // Add transferFrom if staking is required for voting, for this example balanceOf is enough for weight calculation.
    }

    // --- Enums ---
    enum EvolutionPath {
        Growth,    // Evolves primarily with positive sentiment / infusions
        Decay,     // Evolves (or devolves) with negative sentiment / inactivity
        Balanced   // Requires a balance of specific attributes/interactions
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    // --- Structs ---
    struct Aura {
        uint256 tokenId;
        address owner;
        uint256 creationTime;
        uint256 lastInteractionTime;
        uint256 currentLevel;
        int256 sentimentScore; // Individual Aura's sentiment
        EvolutionPath evolutionPath;
        string currentMetadataURI; // Dynamically updated URI for off-chain metadata
        mapping(bytes32 => uint256) dynamicAttributesUints;
        mapping(bytes32 => string) dynamicAttributesStrings;
        bool isEvolving; // Flag to prevent re-entrancy or multiple simultaneous evolutions
    }

    struct Proposal {
        uint256 id;
        bytes32 parameterKey;
        uint256 newValue;
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        address proposer;
        ProposalState state;
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---
    Counters.Counter private _auraIds;
    Counters.Counter private _proposalIds;

    mapping(uint256 => Aura) public auraDetails;
    mapping(address => uint256) public auraMarkBalances; // Non-transferable reputation tokens
    mapping(address => address) public auraMarkDelegates; // Delegation for AuraMarks voting power
    mapping(address => uint256) public accruedRewards; // Rewards accumulated per user

    int256 public globalSentimentPool; // Aggregate sentiment of the protocol
    string private _baseMetadataURI;  // Base URI for initial Aura metadata

    IGovernanceToken public immutable governanceToken;

    // Protocol Parameters (governance configurable)
    uint256 public minAuraInfusionAmount = 1 ether; // Minimum amount to infuse an Aura
    uint256 public auraMarkAwardRate = 10;          // AuraMarks awarded per successful action
    uint256 public globalSentimentDecayRate = 1;    // Decay rate for global sentiment
    uint256 public proposalVotingPeriod = 3 days;   // How long a proposal is active for voting
    uint256 public governanceTokenWeight = 1;       // Multiplier for governance token vote weight
    uint256 public auraMarkWeight = 1;              // Multiplier for AuraMark vote weight
    uint256 public minAuraMarksForProposal = 1000;  // Minimum AuraMarks to create a proposal
    uint256 public minGovTokenForProposal = 10 ether; // Minimum Gov tokens to create a proposal
    uint256 public auraEvolutionThreshold = 500;    // Threshold for Aura sentiment to evolve

    // --- Events ---
    event AuraMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event AuraInfused(uint256 indexed tokenId, address indexed infuser, uint256 amount, int256 newAuraSentiment);
    event AuraEvolutionRequested(uint256 indexed tokenId, address indexed requester);
    event AuraEvolved(uint256 indexed tokenId, uint256 newLevel, int256 newSentiment, string newMetadataURI);
    event AuraMarkAwarded(address indexed user, uint256 amount, bytes32 reason);
    event AuraMarkBurned(address indexed user, uint256 amount, bytes32 reason);
    event GlobalSentimentUpdated(int256 newGlobalSentiment);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 parameterKey, uint256 newValue, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event RewardsClaimed(address indexed claimant, uint256 amount);
    event RewardsDistributed(address[] recipients, uint256[] amounts);
    event DepositToTreasury(address indexed depositor, uint256 amount);
    event ProtocolParameterUpdated(bytes32 indexed parameterKey, uint256 newValue);
    event AuraEvolutionPathSet(uint256 indexed tokenId, EvolutionPath path);

    // --- Constructor ---
    constructor(address _governanceToken, string memory _baseMetadataURI_ )
        ERC721("AuraForge Aura", "AURA")
        Ownable(msg.sender)
    {
        if (_governanceToken == address(0)) revert AuraForge__ZeroAddress();
        governanceToken = IGovernanceToken(_governanceToken);
        _baseMetadataURI = _baseMetadataURI_;
    }

    // --- Receive and Fallback ---
    receive() external payable {
        emit DepositToTreasury(msg.sender, msg.value);
    }

    fallback() external payable {
        emit DepositToTreasury(msg.sender, msg.value);
    }

    // --- Modifiers ---
    modifier onlyAuraOwner(uint256 _tokenId) {
        if (auraDetails[_tokenId].owner != msg.sender) revert AuraForge__Unauthorized();
        _;
    }

    // --- I. Core Aura Asset Management (Dynamic eNFTs) ---

    /**
     * @dev Mints a new Aura NFT for the caller.
     * @param _initialMetadataURI The initial URI for the Aura's metadata.
     */
    function mintAura(string memory _initialMetadataURI)
        public
        whenNotPaused
        returns (uint256)
    {
        _auraIds.increment();
        uint256 newTokenId = _auraIds.current();

        _safeMint(msg.sender, newTokenId);

        Aura storage newAura = auraDetails[newTokenId];
        newAura.tokenId = newTokenId;
        newAura.owner = msg.sender;
        newAura.creationTime = block.timestamp;
        newAura.lastInteractionTime = block.timestamp;
        newAura.currentLevel = 1;
        newAura.sentimentScore = 0;
        newAura.evolutionPath = EvolutionPath.Growth; // Default path
        newAura.currentMetadataURI = _initialMetadataURI;
        newAura.isEvolving = false;

        emit AuraMinted(newTokenId, msg.sender, _initialMetadataURI);
        return newTokenId;
    }

    /**
     * @dev Allows an Aura owner to 'infuse' their Aura.
     *      This increases the Aura's individual sentiment, contributes to its level progression,
     *      and updates the global sentiment pool. Infusion requires sending native currency.
     * @param _tokenId The ID of the Aura to infuse.
     * @param _infusionAmount The amount of native currency sent to infuse.
     */
    function infuseAura(uint256 _tokenId, uint256 _infusionAmount)
        public
        payable
        whenNotPaused
        onlyAuraOwner(_tokenId)
    {
        if (!ERC721.exists(_tokenId)) revert AuraForge__InvalidTokenId();
        if (msg.value < _infusionAmount) revert AuraForge__InsufficientInfusionAmount(); // Ensure enough ETH is sent

        Aura storage aura = auraDetails[_tokenId];
        
        // Update Aura's individual sentiment and level
        aura.sentimentScore = aura.sentimentScore.add(int256(_infusionAmount));
        aura.currentLevel = aura.currentLevel.add(1); // Simple level up for example

        aura.lastInteractionTime = block.timestamp;
        
        // Update global sentiment
        _updateGlobalSentiment(int256(_infusionAmount));

        // Award AuraMarks for positive interaction
        _awardAuraMark(msg.sender, auraMarkAwardRate, "AuraInfusion");

        emit AuraInfused(_tokenId, msg.sender, _infusionAmount, aura.sentimentScore);
        emit DepositToTreasury(msg.sender, msg.value); // Funds go to treasury
    }

    /**
     * @dev Initiates an evolution check for a specific Aura.
     *      If conditions are met (based on its sentiment, level, and global sentiment),
     *      the Aura's attributes and metadata are updated.
     *      This function can be called by anyone, but it only triggers evolution if conditions are met.
     * @param _tokenId The ID of the Aura to check for evolution.
     */
    function requestAuraEvolution(uint256 _tokenId)
        public
        whenNotPaused
    {
        if (!ERC721.exists(_tokenId)) revert AuraForge__InvalidTokenId();

        Aura storage aura = auraDetails[_tokenId];
        if (aura.isEvolving) revert AuraForge__AuraAlreadyEvolving();

        aura.isEvolving = true; // Set flag to prevent re-entrancy
        
        // Check evolution conditions based on path, sentiment, and global sentiment
        bool canEvolve = false;
        string memory newMetadataFragment = "";
        uint256 newLevel = aura.currentLevel;

        if (aura.evolutionPath == EvolutionPath.Growth && aura.sentimentScore >= int256(auraEvolutionThreshold)) {
            newLevel = aura.currentLevel.add(1);
            newMetadataFragment = "evolved-growth-"; // Placeholder for dynamic metadata logic
            canEvolve = true;
        } else if (aura.evolutionPath == EvolutionPath.Decay && aura.sentimentScore < -int256(auraEvolutionThreshold)) {
            newLevel = aura.currentLevel > 1 ? aura.currentLevel.sub(1) : 1; // Devolve, but not below level 1
            newMetadataFragment = "devolved-decay-"; // Placeholder
            canEvolve = true;
        } else if (aura.evolutionPath == EvolutionPath.Balanced && 
                   aura.sentimentScore >= int256(auraEvolutionThreshold / 2) && 
                   globalSentimentPool >= int256(auraEvolutionThreshold / 2)) {
            newLevel = aura.currentLevel.add(1);
            newMetadataFragment = "evolved-balanced-"; // Placeholder
            canEvolve = true;
        }

        if (!canEvolve) {
            aura.isEvolving = false;
            revert AuraForge__AuraEvolutionNotReady();
        }

        // Perform Evolution
        aura.currentLevel = newLevel;
        // Reset individual sentiment after evolution (or reduce it)
        aura.sentimentScore = 0; 
        
        // Update dynamic attributes (example)
        aura.dynamicAttributesUints[keccak256("strength")] = aura.dynamicAttributesUints[keccak256("strength")].add(5);
        aura.dynamicAttributesStrings[keccak256("description")] = string(abi.encodePacked("An aura of level ", Strings.toString(aura.currentLevel), ". ", newMetadataFragment, "state."));

        // Update metadata URI (requires off-chain metadata to be hosted, this is a placeholder)
        aura.currentMetadataURI = string(abi.encodePacked(_baseMetadataURI, newMetadataFragment, Strings.toString(newLevel), ".json"));
        
        aura.isEvolving = false; // Reset flag

        emit AuraEvolved(_tokenId, aura.currentLevel, aura.sentimentScore, aura.currentMetadataURI);
    }

    /**
     * @dev Retrieves comprehensive details about a specific Aura.
     * @param _tokenId The ID of the Aura.
     * @return Aura struct details.
     */
    function getAuraDetails(uint256 _tokenId)
        public
        view
        returns (uint256, address, uint256, uint256, uint256, int256, EvolutionPath, string memory, bool)
    {
        if (!ERC721.exists(_tokenId)) revert AuraForge__InvalidTokenId();
        Aura storage aura = auraDetails[_tokenId];
        return (
            aura.tokenId,
            aura.owner,
            aura.creationTime,
            aura.lastInteractionTime,
            aura.currentLevel,
            aura.sentimentScore,
            aura.evolutionPath,
            aura.currentMetadataURI,
            aura.isEvolving
        );
    }

    /**
     * @dev Returns the value of a specific dynamic uint256 attribute of an Aura.
     * @param _tokenId The ID of the Aura.
     * @param _attributeKey The key of the attribute (e.g., keccak256("strength")).
     * @return The uint256 value of the attribute.
     */
    function getAuraDynamicUintAttribute(uint256 _tokenId, bytes32 _attributeKey)
        public
        view
        returns (uint256)
    {
        if (!ERC721.exists(_tokenId)) revert AuraForge__InvalidTokenId();
        return auraDetails[_tokenId].dynamicAttributesUints[_attributeKey];
    }

    /**
     * @dev Returns the value of a specific dynamic string attribute of an Aura.
     * @param _tokenId The ID of the Aura.
     * @param _attributeKey The key of the attribute (e.g., keccak256("description")).
     * @return The string value of the attribute.
     */
    function getAuraDynamicStringAttribute(uint256 _tokenId, bytes32 _attributeKey)
        public
        view
        returns (string memory)
    {
        if (!ERC721.exists(_tokenId)) revert AuraForge__InvalidTokenId();
        return auraDetails[_tokenId].dynamicAttributesStrings[_attributeKey];
    }

    /**
     * @dev Allows the Aura owner (or governance for initial setup) to define or change the evolution path of an Aura.
     * @param _tokenId The ID of the Aura.
     * @param _path The new evolution path.
     */
    function setAuraEvolutionPath(uint256 _tokenId, EvolutionPath _path)
        public
        whenNotPaused
        onlyAuraOwner(_tokenId)
    {
        if (!ERC721.exists(_tokenId)) revert AuraForge__InvalidTokenId();
        auraDetails[_tokenId].evolutionPath = _path;
        emit AuraEvolutionPathSet(_tokenId, _path);
    }

    // --- II. Sentient Layer & Reputation (AuraMarks) ---

    /**
     * @dev Awards non-transferable AuraMarks to a user for positive contributions.
     *      Callable by trusted roles (e.g., governance, or a designated "validator" contract).
     * @param _user The address to award AuraMarks to.
     * @param _amount The amount of AuraMarks to award.
     * @param _reason A bytes32 reason for the award.
     */
    function awardAuraMark(address _user, uint256 _amount, bytes32 _reason)
        public
        onlyOwner // For simplicity, only owner can award. In a real DAO, this would be governance-controlled.
        whenNotPaused
    {
        if (_user == address(0)) revert AuraForge__ZeroAddress();
        auraMarkBalances[_user] = auraMarkBalances[_user].add(_amount);
        emit AuraMarkAwarded(_user, _amount, _reason);
    }

    /**
     * @dev Reduces AuraMarks for a user, potentially due to negative or fraudulent activities.
     *      Callable by governance.
     * @param _user The address to burn AuraMarks from.
     * @param _amount The amount of AuraMarks to burn.
     * @param _reason A bytes32 reason for the burn.
     */
    function burnAuraMark(address _user, uint256 _amount, bytes32 _reason)
        public
        onlyOwner // For simplicity, only owner can burn. In a real DAO, this would be governance-controlled.
        whenNotPaused
    {
        if (_user == address(0)) revert AuraForge__ZeroAddress();
        uint256 currentBalance = auraMarkBalances[_user];
        if (currentBalance < _amount) {
            auraMarkBalances[_user] = 0; // Or revert, depends on desired behavior for insufficient balance
        } else {
            auraMarkBalances[_user] = currentBalance.sub(_amount);
        }
        _updateGlobalSentiment(-int256(_amount)); // Burning AuraMarks negatively impacts global sentiment
        emit AuraMarkBurned(_user, _amount, _reason);
    }

    /**
     * @dev Returns the current AuraMark balance for a given user.
     * @param _user The address to query.
     * @return The current AuraMark balance.
     */
    function getAuraMarkBalance(address _user)
        public
        view
        returns (uint256)
    {
        return auraMarkBalances[_user];
    }

    /**
     * @dev Returns the current aggregate sentiment score of the entire AuraForge protocol.
     */
    function getGlobalSentimentScore()
        public
        view
        returns (int256)
    {
        return globalSentimentPool;
    }

    /**
     * @dev Internal helper to update the global sentiment pool.
     * @param _delta The change in sentiment.
     */
    function _updateGlobalSentiment(int256 _delta) internal {
        globalSentimentPool = globalSentimentPool.add(_delta);
        // Optionally, apply decay over time for globalSentimentPool
        // globalSentimentPool = globalSentimentPool.sub(globalSentimentDecayRate);
        emit GlobalSentimentUpdated(globalSentimentPool);
    }

    // --- III. Adaptive Governance ---
    mapping(uint256 => Proposal) public proposals;

    /**
     * @dev Allows users with sufficient governance token and/or AuraMarks to propose changes to protocol parameters.
     * @param _parameterKey The bytes32 key of the parameter to change (e.g., keccak256("minAuraInfusionAmount")).
     * @param _newValue The new uint256 value for the parameter.
     * @param _description A description of the proposal.
     */
    function proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, string memory _description)
        public
        whenNotPaused
        returns (uint256)
    {
        uint256 proposerAuraMarks = auraMarkBalances[msg.sender];
        uint256 proposerGovTokens = governanceToken.balanceOf(msg.sender);

        if (proposerAuraMarks < minAuraMarksForProposal && proposerGovTokens < minGovTokenForProposal) {
            revert AuraForge__Unauthorized(); // Not enough reputation/tokens to propose
        }

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            parameterKey: _parameterKey,
            newValue: _newValue,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            forVotes: 0,
            againstVotes: 0,
            proposer: msg.sender,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit ProposalCreated(proposalId, msg.sender, _parameterKey, _newValue, _description);
        return proposalId;
    }

    /**
     * @dev Casts a vote on an active proposal. The weight of the vote is determined by
     *      the voter's combined governance token holdings and AuraMark balance.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        public
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert AuraForge__ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert AuraForge__ProposalNotActive();
        if (block.timestamp > proposal.voteEndTime) revert AuraForge__ProposalVotePeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert AuraForge__ProposalAlreadyVoted();

        uint256 voteWeight = _getEffectiveVoteWeight(msg.sender);
        if (voteWeight == 0) revert AuraForge__Unauthorized(); // No voting power

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(voteWeight);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voteWeight);
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @dev Executes a successfully voted-on proposal, applying the proposed parameter changes.
     *      This also influences the global sentiment pool.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId)
        public
        whenNotPaused
        onlyOwner // For simplicity, only owner can execute. In a real DAO, this would be anyone after proposal passes.
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert AuraForge__ProposalNotFound();
        if (proposal.state == ProposalState.Executed) revert AuraForge__ProposalAlreadyExecuted();
        if (block.timestamp <= proposal.voteEndTime) revert AuraForge__ProposalVotePeriodEnded(); // Voting must have ended

        // Determine final state
        if (proposal.forVotes > proposal.againstVotes) {
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Failed;
        }

        if (proposal.state != ProposalState.Succeeded) revert AuraForge__ProposalNotApproved();

        // Apply parameter change
        _setProtocolParameter(proposal.parameterKey, proposal.newValue);
        proposal.state = ProposalState.Executed;

        _updateGlobalSentiment(int224(proposal.forVotes)); // Successful execution boosts global sentiment

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows a user to delegate their AuraMark voting power to another address.
     * @param _delegatee The address to delegate AuraMarks to.
     */
    function delegateAuraMarks(address _delegatee) public whenNotPaused {
        if (_delegatee == address(0)) revert AuraForge__ZeroAddress();
        if (_delegatee == msg.sender) revert AuraForge__SelfDelegationNotAllowed();
        if (auraMarkDelegates[msg.sender] == _delegatee) revert AuraForge__AlreadyDelegated();
        // Check if there are AuraMarks to delegate (optional)
        if (auraMarkBalances[msg.sender] == 0) revert AuraForge__NoAuraMarksToDelegate();

        auraMarkDelegates[msg.sender] = _delegatee;
    }

    /**
     * @dev Retrieves all details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct details.
     */
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (uint256, bytes32, uint256, string memory, uint256, uint256, uint256, uint256, address, ProposalState)
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert AuraForge__ProposalNotFound();
        return (
            proposal.id,
            proposal.parameterKey,
            proposal.newValue,
            proposal.description,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.proposer,
            proposal.state
        );
    }

    /**
     * @dev Internal function to calculate a voter's effective vote weight, considering
     *      governance tokens and AuraMarks (and delegation).
     * @param _voter The address of the voter.
     * @return The calculated effective vote weight.
     */
    function _getEffectiveVoteWeight(address _voter) internal view returns (uint256) {
        address voterOrDelegate = auraMarkDelegates[_voter] == address(0) ? _voter : auraMarkDelegates[_voter];

        uint256 govTokenPower = governanceToken.balanceOf(voterOrDelegate).mul(governanceTokenWeight);
        uint256 auraMarkPower = auraMarkBalances[voterOrDelegate].mul(auraMarkWeight);

        return govTokenPower.add(auraMarkPower);
    }

    /**
     * @dev Internal function to apply a parameter change.
     * @param _parameterKey The key of the parameter.
     * @param _newValue The new value.
     */
    function _setProtocolParameter(bytes32 _parameterKey, uint256 _newValue) internal {
        if (_parameterKey == keccak256("minAuraInfusionAmount")) {
            minAuraInfusionAmount = _newValue;
        } else if (_parameterKey == keccak256("auraMarkAwardRate")) {
            auraMarkAwardRate = _newValue;
        } else if (_parameterKey == keccak256("globalSentimentDecayRate")) {
            globalSentimentDecayRate = _newValue;
        } else if (_parameterKey == keccak256("proposalVotingPeriod")) {
            proposalVotingPeriod = _newValue;
        } else if (_parameterKey == keccak256("governanceTokenWeight")) {
            governanceTokenWeight = _newValue;
        } else if (_parameterKey == keccak256("auraMarkWeight")) {
            auraMarkWeight = _newValue;
        } else if (_parameterKey == keccak256("minAuraMarksForProposal")) {
            minAuraMarksForProposal = _newValue;
        } else if (_parameterKey == keccak256("minGovTokenForProposal")) {
            minGovTokenForProposal = _newValue;
        } else if (_parameterKey == keccak256("auraEvolutionThreshold")) {
            auraEvolutionThreshold = _newValue;
        } else {
            revert AuraForge__InvalidParameterKey();
        }
        emit ProtocolParameterUpdated(_parameterKey, _newValue);
    }


    // --- IV. Treasury & Rewards ---

    /**
     * @dev Allows users to claim their accumulated rewards.
     */
    function claimRewards() public whenNotPaused {
        uint256 rewards = accruedRewards[msg.sender];
        if (rewards == 0) revert AuraForge__NoRewardsToClaim();
        if (address(this).balance < rewards) revert AuraForge__InsufficientTreasuryBalance();

        accruedRewards[msg.sender] = 0; // Reset claimed rewards
        payable(msg.sender).transfer(rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Initiates a distribution of rewards from the protocol treasury to specified recipients.
     *      Callable by governance.
     * @param _recipients Array of addresses to receive rewards.
     * @param _amounts Array of amounts corresponding to each recipient.
     */
    function distributeRewards(address[] memory _recipients, uint256[] memory _amounts)
        public
        onlyOwner // For simplicity, only owner can distribute. In a real DAO, this would be governance-controlled.
        whenNotPaused
    {
        if (_recipients.length != _amounts.length) revert AuraForge__InvalidParameterKey(); // Using this error for mismatch
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount = totalAmount.add(_amounts[i]);
        }
        if (address(this).balance < totalAmount) revert AuraForge__InsufficientTreasuryBalance();

        for (uint256 i = 0; i < _recipients.length; i++) {
            accruedRewards[_recipients[i]] = accruedRewards[_recipients[i]].add(_amounts[i]);
        }
        emit RewardsDistributed(_recipients, _amounts);
    }

    /**
     * @dev Allows any user to deposit native currency (e.g., Ether) into the contract's treasury,
     *      increasing funds for rewards or protocol operations.
     */
    function depositToTreasury() public payable whenNotPaused {
        if (msg.value == 0) revert AuraForge__InsufficientInfusionAmount(); // Using for zero value
        emit DepositToTreasury(msg.sender, msg.value);
    }

    // --- V. Protocol Management & Standard ERC721 Functions ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (!ERC721.exists(tokenId)) revert AuraForge__InvalidTokenId();
        return auraDetails[tokenId].currentMetadataURI;
    }

    /**
     * @dev Sets a new base URI for Aura metadata. Callable by owner.
     * @param _newURI The new base URI.
     */
    function setBaseAuraMetadataURI(string memory _newURI) public onlyOwner {
        _baseMetadataURI = _newURI;
    }

    /**
     * @dev Pauses core contract functionalities in case of an emergency.
     *      Callable only by the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, restoring functionalities.
     *      Callable only by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- ERC721 Overrides (to integrate with custom Aura struct) ---
    // The default ERC721 functions (ownerOf, balanceOf, approve, transferFrom, etc.)
    // will work with our internal _owner and _balances mappings, which are handled
    // by the OpenZeppelin ERC721 implementation.
    // The only one we explicitly override is tokenURI to point to our dynamic metadata.

    // Remaining standard ERC721 functions are inherited directly:
    // name(), symbol(), balanceOf(address owner), ownerOf(uint256 tokenId),
    // approve(address to, uint256 tokenId), getApproved(uint256 tokenId),
    // setApprovalForAll(address operator, bool approved), isApprovedForAll(address owner, address operator),
    // transferFrom(address from, address to, uint256 tokenId),
    // safeTransferFrom(address from, address to, uint256 tokenId),
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
}
```