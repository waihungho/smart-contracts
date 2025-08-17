Here's a Solidity smart contract named "EvolvoNFT" that aims to implement several advanced, creative, and trending concepts beyond typical open-source projects. It focuses on **dynamic generative art NFTs that evolve based on community interaction, algorithmic rules, and external data**.

---

## EvolvoNFT: Dynamic Generative Art & Patronage Network

**Purpose:**
The EvolvoNFT contract establishes a unique ecosystem for dynamic, evolving generative art. Unlike traditional NFTs that remain static post-mint, EvolvoNFTs possess "genes" (parameters) that can be influenced and changed over time. This evolution is driven by a unique interplay of artists, patrons, curators, and even external environmental factors, all orchestrated through on-chain mechanics and references to off-chain generative algorithms. The goal is to create living, responsive digital art that engages its community over its lifetime.

**Core Concepts:**
1.  **Dynamic Parameters:** Each EvolvoNFT stores a set of numerical parameters (genes) on-chain that dictate its visual representation. These parameters are designed to be inputs for an off-chain generative art algorithm, allowing the art to change its appearance.
2.  **Patron-Driven Evolution:** Patrons can "sponsor" mutations or evolutionary steps by paying a fee, directly influencing an NFT's parameters or triggering approved algorithmic evolutions. This empowers the community to participate in the art's creation.
3.  **Algorithmic Evolution Vault:** A registry of approved off-chain generative algorithms (identified by URIs and hashes) that can be applied to NFTs, causing their parameters to evolve in complex, pre-defined ways. This allows for diverse and sophisticated evolutionary paths.
4.  **Curator Reputation System:** A decentralized system where trusted curators review proposed algorithms and art pieces, maintaining quality and preventing abuse. Curators earn reputation for valuable contributions.
5.  **Influence Staking:** Patrons can stake tokens (ETH in this simplified example) on specific NFTs to gain higher voting power or influence over their evolution. This aligns incentives and provides a mechanism for prioritizing community input.
6.  **Environmental Influence:** EvolvoNFT parameters can be designed to react to external, real-world data (simulated via oracle feeds), introducing an element of organic, contextual evolution (e.g., an artwork changing based on real-time weather data or market sentiment).
7.  **Decentralized Governance:** Key contract parameters, algorithm approvals, and curator management are governed by a simplified decentralized autonomous organization (DAO) mechanism, ensuring community control and future adaptability.

**Key Features:**
*   Minting and ownership of EvolvoNFTs (ERC721 compliant).
*   On-chain storage and evolution of generative parameters.
*   Submission, approval, and execution of new algorithmic evolution methods.
*   Patronage system with fees, rewards, and influence staking.
*   Curator role with reputation management for quality control.
*   Integration point for external data feeds to influence art.
*   Royalty distribution for artists (ERC2981 compliant).
*   Basic DAO-like governance for core protocol parameters.

**Modules/Sections:**
*   ERC721 & Royalty (ERC2981) Implementation
*   EvolvoNFT Data Structures & State Management
*   Minting & Initial Parameter Setting
*   Evolution Mechanisms (Patron-driven & Algorithmic)
*   Algorithmic Evolution Vault Management
*   Patronage & Influence Staking
*   Curator & Reputation System
*   Environmental Factors Integration
*   Governance (Simplified DAO)
*   Fee Management & Withdrawals
*   View & Utility Functions

**Interfaces/Standards:**
*   ERC721 (Non-Fungible Token Standard)
*   ERC721URIStorage (for storing token metadata URI)
*   ERC2981 (NFT Royalty Standard)

---

### Function Summary:

**I. Core NFT & Evolution:**
1.  `mintEvolvoNFT(address _to, string memory _initialURI, uint256[] memory _initialParameters)`: Mints a new EvolvoNFT with initial metadata and generative parameters. The minter becomes the initial artist/owner.
2.  `updateEvolvoParameters(uint256 _tokenId, uint256[] memory _newParameters)`: Allows the artist (owner) to update an NFT's parameters directly for minor adjustments or initial setup.
3.  `evolveNFTByPatron(uint256 _tokenId, uint256 _paramIndex, int256 _delta, string memory _mutationReason)`: Allows a patron to pay a fee to directly mutate a specific parameter of an EvolvoNFT by a `delta` value.
4.  `proposeAlgorithmicEvolution(string memory _algorithmURI, bytes32 _algorithmHash, uint256[] memory _requiredParamIndices, uint256 _feeRequirement)`: An artist proposes a new off-chain algorithmic evolution method to the DAO for approval.
5.  `voteForAlgorithmicEvolution(bytes32 _algorithmHash, bool _approve)`: DAO members or approved curators vote on a proposed algorithmic evolution to approve or reject it.
6.  `executeAlgorithmicEvolution(uint256 _tokenId, bytes32 _algorithmHash, bytes memory _algInputData)`: Triggers the application of an approved algorithmic evolution to an EvolvoNFT. This function would typically be called by an off-chain executor/keeper after an oracle confirms the algorithm has processed new parameters.
7.  `getEvolvoParameters(uint256 _tokenId)`: Returns the current generative parameters (genes) of an EvolvoNFT.
8.  `getEvolvoHistory(uint256 _tokenId)`: Returns the full history of parameter changes for an EvolvoNFT, including evolution event hashes/IDs and timestamps.
9.  `tokenURI(uint256 tokenId)`: Returns the metadata URI for a given token ID, allowing off-chain services to reflect its current dynamic state. (Overrides ERC721URIStorage).
10. `royaltyInfo(uint256 _tokenId, uint256 _salePrice)`: Returns royalty information for secondary sales as per ERC2981, enabling fair compensation for artists.

**II. Patronage & Influence Staking:**
11. `stakeForInfluence(uint256 _tokenId)`: Allows a patron to stake ETH on an NFT to boost their voting power or influence over its evolution.
12. `unstakeInfluence(uint256 _tokenId, uint256 _amount)`: Allows a patron to unstake their previously staked ETH from an NFT.
13. `getPatronInfluence(uint256 _tokenId, address _patron)`: Returns the amount of influence (staked ETH) a specific patron has on a given NFT.
14. `claimPatronRewards(uint256 _tokenId)`: Allows patrons to claim their share of protocol fees, rewarding them for their engagement and staking on EvolvoNFTs. (Simplified reward calculation for demo).

**III. Curator & Reputation System:**
15. `applyAsCurator(string memory _metadataURI)`: A user applies to become a curator, providing a metadata URI for their profile/credentials. Their application requires DAO approval.
16. `voteOnCuratorApplication(address _applicant, bool _approve)`: DAO members and existing curators vote on a curator application.
17. `submitCuratorReview(uint256 _tokenId, string memory _reviewUri, uint256 _rating)`: Active curators submit reviews/ratings for EvolvoNFTs or algorithms, which can impact their reputation score.
18. `getCuratorReputation(address _curator)`: Returns the current reputation score of a curator.
19. `penalizeCurator(address _curator, uint256 _penaltyAmount)`: A DAO action to penalize a curator for misconduct, reducing their reputation and potentially deactivating them.

**IV. Environmental Factors Integration:**
20. `updateEnvironmentalFactor(string memory _factorName, uint256 _value)`: An authorized entity (simulated as DAO in this example, but typically an oracle) updates an external environmental factor (e.g., weather, market data) that can influence NFT evolution.
21. `getEnvironmentalFactor(string memory _factorName)`: Returns the current value of a specific environmental factor.

**V. Governance & System Management (Simplified DAO):**
22. `proposeGovernanceAction(bytes memory _callData, string memory _description)`: Allows a DAO member to propose a general governance action (e.g., changing fees, updating roles), encoded as call data.
23. `voteOnGovernanceAction(uint256 _proposalId, bool _support)`: DAO members vote on an active governance proposal.
24. `executeGovernanceAction(uint256 _proposalId)`: Executes a governance proposal that has received sufficient "for" votes.
25. `setBaseEvolutionFee(uint256 _newFee)`: Sets the base fee (in wei) required for a patron to trigger an NFT evolution. This function is callable only via a successful governance proposal.
26. `setInfluenceStakeAmount(uint256 _amount)`: Sets the minimum amount of ETH required to stake for influence. This function is callable only via a successful governance proposal.

**VI. Utilities & Funds Management:**
27. `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the DAO to withdraw accumulated protocol fees from the contract.
28. `getTotalEvolvoNFTs()`: Returns the total number of EvolvoNFTs that have been minted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For potential string conversions (e.g., to create dynamic URIs)

/*
Outline: The EvolvoNFT - Dynamic Generative Art & Patronage Network

Purpose:
The EvolvoNFT contract facilitates a novel ecosystem for dynamic, evolving generative art. Unlike traditional NFTs that are static post-mint, EvolvoNFTs possess "genes" and "parameters" that can be influenced and changed over time. This evolution is driven by a unique interplay of artists, patrons, curators, and even external environmental factors, all orchestrated through on-chain mechanics and references to off-chain generative algorithms.

Core Concepts:
1.  Dynamic Parameters: Each EvolvoNFT stores a set of numerical parameters (genes) on-chain that dictate its visual representation. These parameters are designed to be inputs for an off-chain generative art algorithm.
2.  Patron-Driven Evolution: Patrons can "sponsor" mutations or evolutionary steps by paying a fee, directly influencing the NFT's parameters or triggering approved algorithmic evolutions.
3.  Algorithmic Evolution Vault: A registry of approved off-chain generative algorithms (identified by URIs and hashes) that can be applied to NFTs, causing their parameters to evolve in complex ways.
4.  Curator Reputation System: A decentralized system where trusted curators review proposed algorithms and art pieces, maintaining quality and preventing abuse.
5.  Influence Staking: Patrons can stake tokens (ETH in this simplified example) on specific NFTs to gain higher voting power or influence over their evolution.
6.  Environmental Influence: EvolvoNFT parameters can be designed to react to external, real-world data (simulated via oracle feeds), introducing an element of organic, contextual evolution.
7.  Decentralized Governance: Key contract parameters, algorithm approvals, and curator management are governed by a decentralized autonomous organization (DAO) or a multi-sig.

Key Features:
-   Minting and ownership of EvolvoNFTs (ERC721 compliant).
-   On-chain storage and evolution of generative parameters.
-   Submission, approval, and execution of new algorithmic evolution methods.
-   Patronage system with fees, rewards, and influence staking.
-   Curator role with reputation management for quality control.
-   Integration point for external data feeds to influence art.
-   Royalty distribution for artists (ERC2981 compliant).
-   Basic DAO-like governance for core protocol parameters.

Modules/Sections:
-   ERC721 & Royalty (ERC2981) Implementation
-   EvolvoNFT Data Structures & State Management
-   Minting & Initial Parameter Setting
-   Evolution Mechanisms (Patron-driven & Algorithmic)
-   Algorithmic Evolution Vault Management
-   Patronage & Influence Staking
-   Curator & Reputation System
-   Environmental Factors Integration
-   Governance (Simplified DAO)
-   Fee Management & Withdrawals
-   View & Utility Functions

Interfaces/Standards:
-   ERC721
-   ERC721URIStorage
-   ERC2981 (NFT Royalties)

Function Summary:

I. Core NFT & Evolution:
1.  `mintEvolvoNFT(address _to, string memory _initialURI, uint256[] memory _initialParameters)`: Mints a new EvolvoNFT with initial metadata and generative parameters.
2.  `updateEvolvoParameters(uint256 _tokenId, uint256[] memory _newParameters)`: Allows the artist (or approved entity) to update an NFT's parameters.
3.  `evolveNFTByPatron(uint256 _tokenId, uint256 _paramIndex, int256 _delta, string memory _mutationReason)`: Allows a patron to pay a fee to directly mutate a specific parameter of an EvolvoNFT.
4.  `proposeAlgorithmicEvolution(string memory _algorithmURI, bytes32 _algorithmHash, uint256[] memory _requiredParamIndices, uint256 _feeRequirement)`: Artist proposes a new off-chain algorithmic evolution method to the DAO for approval.
5.  `voteForAlgorithmicEvolution(bytes32 _algorithmHash, bool _approve)`: DAO/Curators vote on a proposed algorithmic evolution.
6.  `executeAlgorithmicEvolution(uint256 _tokenId, bytes32 _algorithmHash, bytes memory _algInputData)`: Triggers the application of an approved algorithmic evolution to an EvolvoNFT. This function would typically be called by an off-chain executor or keeper service after an oracle confirms algorithm readiness.
7.  `getEvolvoParameters(uint256 _tokenId)`: Returns the current generative parameters of an EvolvoNFT.
8.  `getEvolvoHistory(uint256 _tokenId)`: Returns the full history of parameter changes for an EvolvoNFT.
9.  `tokenURI(uint256 tokenId)`: Returns the metadata URI for a given token ID, reflecting its current state. Overridden from ERC721URIStorage.
10. `royaltyInfo(uint256 _tokenId, uint256 _salePrice)`: Returns royalty information as per ERC2981.

II. Patronage & Influence Staking:
11. `stakeForInfluence(uint256 _tokenId)`: Allows a patron to stake their influence token (or ETH) on an NFT to boost their voting power for its evolution.
12. `unstakeInfluence(uint256 _tokenId, uint256 _amount)`: Allows a patron to unstake their influence tokens.
13. `getPatronInfluence(uint256 _tokenId, address _patron)`: Returns the influence score (staked amount) of a patron on a specific NFT.
14. `claimPatronRewards(uint256 _tokenId)`: Allows patrons to claim their share of fees collected from evolutions they influenced or staked on.

III. Curator & Reputation System:
15. `applyAsCurator(string memory _metadataURI)`: A user applies to become a curator.
16. `voteOnCuratorApplication(address _applicant, bool _approve)`: DAO/existing curators vote on a curator application.
17. `submitCuratorReview(uint256 _tokenId, string memory _reviewUri, uint256 _rating)`: Curators submit reviews/ratings for EvolvoNFTs, impacting their discoverability or the curator's reputation.
18. `getCuratorReputation(address _curator)`: Returns the current reputation score of a curator.
19. `penalizeCurator(address _curator, uint256 _penaltyAmount)`: DAO action to penalize a curator for misconduct, reducing their reputation.

IV. Environmental Factors Integration:
20. `updateEnvironmentalFactor(string memory _factorName, uint256 _value)`: An authorized oracle (or DAO) updates an external environmental factor that can influence NFT evolution.
21. `getEnvironmentalFactor(string memory _factorName)`: Returns the current value of an environmental factor.

V. Governance & System Management (Simplified DAO):
22. `proposeGovernanceAction(bytes memory _callData, string memory _description)`: Allows a DAO member to propose a general governance action (e.g., changing fees, updating roles).
23. `voteOnGovernanceAction(uint256 _proposalId, bool _support)`: DAO members vote on a governance proposal.
24. `executeGovernanceAction(uint256 _proposalId)`: Executes an approved governance proposal.
25. `setBaseEvolutionFee(uint256 _newFee)`: Sets the base fee required for a patron to trigger an NFT evolution.
26. `setInfluenceStakeAmount(uint256 _amount)`: Sets the minimum amount of stake tokens required for influence.

VI. Utilities & Funds Management:
27. `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the DAO/owner to withdraw accumulated protocol fees.
28. `getTotalEvolvoNFTs()`: Returns the total number of EvolvoNFTs minted.
*/

contract EvolvoNFT is ERC721URIStorage, ERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---

    /**
     * @dev Represents the evolving state of an EvolvoNFT.
     * `currentParameters`: The on-chain numerical inputs for the off-chain generative art algorithm.
     * `creationTimestamp`: When the NFT was minted.
     * `artist`: The original artist address.
     * `evolutionHistoryHashes`: A log of algorithm hashes or mutation IDs that caused parameter changes.
     * `evolutionTimestamps`: Timestamps for each evolution event.
     * `patronStakes`: Mapping of patron address to their staked ETH amount on this specific NFT.
     * `totalStakedInfluence`: Sum of all staked ETH on this NFT, used for calculating influence weight.
     */
    struct EvolvoState {
        uint256[] currentParameters;
        uint256 creationTimestamp;
        address artist;
        bytes32[] evolutionHistoryHashes;
        uint256[] evolutionTimestamps;
        mapping(address => uint256) patronStakes;
        uint256 totalStakedInfluence;
    }

    /**
     * @dev Defines an off-chain generative evolution algorithm.
     * `uri`: URI pointing to the algorithm description/code (off-chain).
     * `proposer`: Address that proposed this algorithm.
     * `proposedTimestamp`: When the algorithm was proposed.
     * `approved`: True if the DAO/Curators have approved this algorithm.
     * `approvalVotes`: Count of 'for' votes for this algorithm.
     * `rejectionVotes`: Count of 'against' votes for this algorithm.
     * `requiredParamIndices`: Indices of parameters this algorithm is designed to operate on.
     * `feeRequirement`: The specific ETH fee required to trigger this algorithm.
     * `executed`: Flag indicating if this specific proposal has been "executed" (used if proposals are single-use).
     */
    struct EvolutionAlgorithm {
        string uri;
        address proposer;
        uint256 proposedTimestamp;
        bool approved;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256[] requiredParamIndices;
        uint256 feeRequirement;
        bool executed;
    }

    /**
     * @dev Represents a curator's profile and reputation within the network.
     * `metadataURI`: URI to curator's off-chain profile data/credentials.
     * `reputationScore`: Numerical score reflecting the curator's trustworthiness and contribution.
     * `isActive`: True if the curator has been approved by the DAO and maintains sufficient reputation.
     * `applicationTimestamp`: When the curator applied.
     * `approvalVotes`: Votes received during their application process.
     * `rejectionVotes`: Votes against during their application process.
     */
    struct CuratorProfile {
        string metadataURI;
        uint256 reputationScore;
        bool isActive;
        uint256 applicationTimestamp;
        uint256 approvalVotes;
        uint256 rejectionVotes;
    }

    /**
     * @dev Represents a general governance proposal.
     * `callData`: The encoded function call to execute if the proposal passes.
     * `description`: A human-readable description of the proposal.
     * `executed`: True if the proposal has been successfully executed.
     * `votesFor`: Count of 'for' votes.
     * `votesAgainst`: Count of 'against' votes.
     * `submissionTimestamp`: When the proposal was created.
     * `proposer`: Address that created the proposal.
     */
    struct GovernanceProposal {
        bytes callData;
        string description;
        bool executed;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 submissionTimestamp;
        address proposer;
    }

    // --- State Variables ---

    mapping(uint256 => EvolvoState) private _evolvoStates; // tokenId => EvolvoState
    mapping(bytes32 => EvolutionAlgorithm) public evolutionAlgorithms; // algorithmHash => EvolutionAlgorithm
    mapping(address => bool) public isDAOAddress; // Addresses designated as DAO members (for simplified voting)
    mapping(address => CuratorProfile) public curators; // curatorAddress => CuratorProfile
    mapping(string => uint256) public environmentalFactors; // factorName (e.g., "temperature") => value (simulated oracle feed)

    uint256 public baseEvolutionFee; // Base fee (in wei) for patron-driven direct parameter evolution
    uint256 public influenceStakeAmount; // Minimum stake amount (in wei) required to gain influence on an NFT
    uint224 public protocolFeesCollected; // Accumulator for all fees collected by the protocol (using uint224 to save gas, max 2^224-1 wei)
    address public immutable royaltyRecipient; // Address to receive default artist royalties (fixed for all NFTs)

    uint256 public minDAOVotesForApproval; // Minimum votes required for DAO actions (e.g., proposal execution, curator approval)
    uint256 public minCuratorReputationForVote; // Minimum reputation score for curators to vote on algorithms/curators

    // Governance
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => GovernanceProposal) public governanceProposals; // proposalId => GovernanceProposal
    mapping(uint256 => mapping(address => bool)) private _hasVotedProposal; // proposalId => voterAddress => hasVoted (prevents double voting)

    // --- Events ---

    event EvolvoMinted(uint256 indexed tokenId, address indexed to, address indexed artist, string initialURI, uint256[] initialParameters);
    event ParametersUpdated(uint256 indexed tokenId, address indexed by, uint256[] newParameters);
    event PatronEvolvedNFT(uint256 indexed tokenId, address indexed patron, uint256 paramIndex, int256 delta, string mutationReason);
    event AlgorithmicEvolutionProposed(bytes32 indexed algorithmHash, string algorithmURI, address indexed proposer);
    event AlgorithmicEvolutionVoted(bytes32 indexed algorithmHash, address indexed voter, bool approved);
    event AlgorithmicEvolutionExecuted(uint256 indexed tokenId, bytes32 indexed algorithmHash, bytes algInputData);
    event CuratorApplied(address indexed applicant, string metadataURI);
    event CuratorVoted(address indexed voter, address indexed applicant, bool approved);
    event CuratorReputationUpdated(address indexed curator, uint256 newReputationScore);
    event EnvironmentalFactorUpdated(string indexed factorName, uint256 value);
    event InfluenceStaked(uint256 indexed tokenId, address indexed patron, uint256 amount);
    event InfluenceUnstaked(uint256 indexed tokenId, address indexed patron, uint256 amount);
    event PatronRewardsClaimed(uint256 indexed tokenId, address indexed patron, uint256 amount); // Amount here is simulated/calculated
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---

    /**
     * @dev Restricts access to functions to addresses designated as DAO members.
     * In a real system, this would be a more robust token-weighted voting system.
     */
    modifier onlyDAO() {
        require(isDAOAddress[msg.sender], "EvolvoNFT: Caller is not a DAO member");
        _;
    }

    /**
     * @dev Restricts access to functions to the current owner (artist) of the specified NFT.
     */
    modifier onlyArtist(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "EvolvoNFT: Not the artist (owner)");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Constructor to initialize the EvolvoNFT contract.
     * @param name_ The name of the NFT collection.
     * @param symbol_ The symbol of the NFT collection.
     * @param _royaltyRecipient The address to receive default royalties from NFT sales.
     * @param _defaultRoyaltyPercentage The default royalty percentage (e.g., 500 for 5%).
     * @param _initialBaseEvolutionFee The initial fee in wei for a patron to manually evolve an NFT.
     * @param _initialInfluenceStakeAmount The initial minimum ETH amount required to stake for influence.
     * @param _minDAOVotes The minimum number of votes required for DAO actions to pass.
     * @param _minCuratorRep The minimum reputation score required for a curator to vote on proposals.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address _royaltyRecipient,
        uint96 _defaultRoyaltyPercentage,
        uint256 _initialBaseEvolutionFee,
        uint256 _initialInfluenceStakeAmount,
        uint256 _minDAOVotes,
        uint256 _minCuratorRep
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        require(_royaltyRecipient != address(0), "EvolvoNFT: Invalid royalty recipient");
        royaltyRecipient = _royaltyRecipient;
        _setDefaultRoyalty(_royaltyRecipient, _defaultRoyaltyPercentage); // Set default for all future NFTs

        baseEvolutionFee = _initialBaseEvolutionFee;
        influenceStakeAmount = _initialInfluenceStakeAmount;
        minDAOVotesForApproval = _minDAOVotes;
        minCuratorReputationForVote = _minCuratorRep;

        // Make deployer a DAO member initially for setup and governance
        isDAOAddress[msg.sender] = true;
    }

    // --- I. Core NFT & Evolution ---

    /**
     * @dev Mints a new EvolvoNFT with initial metadata and generative parameters.
     * The minter becomes the initial artist/owner of this EvolvoNFT.
     * @param _to The address to mint the NFT to.
     * @param _initialURI The initial metadata URI for the NFT. This URI should ideally point to a service
     *                    that can dynamically generate metadata based on the `currentParameters`.
     * @param _initialParameters The initial set of numerical parameters (genes) for the generative art.
     */
    function mintEvolvoNFT(address _to, string memory _initialURI, uint256[] memory _initialParameters)
        public
        nonReentrant // Protects against reentrancy attacks, especially if fees were involved
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_to, newTokenId);
        _setTokenURI(newTokenId, _initialURI);

        EvolvoState storage evolvo = _evolvoStates[newTokenId];
        evolvo.currentParameters = _initialParameters;
        evolvo.creationTimestamp = block.timestamp;
        evolvo.artist = _to; // Artist is initially the minter/owner

        emit EvolvoMinted(newTokenId, _to, _to, _initialURI, _initialParameters);
    }

    /**
     * @dev Allows the artist (current owner) to update an NFT's parameters directly.
     * This function is intended for minor adjustments, fine-tuning, or initial setup by the artist,
     * distinct from patron-driven or algorithmic evolutions. No fee is applied here.
     * @param _tokenId The ID of the EvolvoNFT.
     * @param _newParameters The new set of generative parameters.
     */
    function updateEvolvoParameters(uint256 _tokenId, uint256[] memory _newParameters)
        public
        onlyArtist(_tokenId)
    {
        require(_exists(_tokenId), "EvolvoNFT: Token does not exist");
        require(_newParameters.length > 0, "EvolvoNFT: Parameters cannot be empty");
        _evolvoStates[_tokenId].currentParameters = _newParameters;

        emit ParametersUpdated(_tokenId, msg.sender, _newParameters);
    }

    /**
     * @dev Allows a patron to pay a fee to directly mutate a specific parameter of an EvolvoNFT.
     * This represents a direct, small-scale influence by a community member. The `_delta` can be positive or negative.
     * @param _tokenId The ID of the EvolvoNFT.
     * @param _paramIndex The index of the parameter within the `currentParameters` array to mutate.
     * @param _delta The change to apply to the parameter (can be negative, handled by casting to int256).
     * @param _mutationReason A short string explaining the reason for this mutation, stored in history.
     */
    function evolveNFTByPatron(uint256 _tokenId, uint256 _paramIndex, int256 _delta, string memory _mutationReason)
        public
        payable
        nonReentrant
    {
        require(_exists(_tokenId), "EvolvoNFT: Token does not exist");
        require(msg.value >= baseEvolutionFee, "EvolvoNFT: Insufficient evolution fee");
        require(_paramIndex < _evolvoStates[_tokenId].currentParameters.length, "EvolvoNFT: Invalid parameter index");

        // Apply the delta to the parameter, ensuring no underflow/overflow if not using SafeMath.
        // For uint256, direct arithmetic can be risky with negative `_delta`.
        // A safer approach might involve explicit bounds checking or using a library.
        // For simplicity and demonstration of concept, direct cast is used.
        _evolvoStates[_tokenId].currentParameters[_paramIndex] =
            uint256(int256(_evolvoStates[_tokenId].currentParameters[_paramIndex]) + _delta);

        _evolvoStates[_tokenId].evolutionHistoryHashes.push(keccak256(abi.encodePacked("PatronMutation", _mutationReason, block.timestamp)));
        _evolvoStates[_tokenId].evolutionTimestamps.push(block.timestamp);

        protocolFeesCollected += uint224(msg.value); // Collect fee for the protocol

        emit PatronEvolvedNFT(_tokenId, msg.sender, _paramIndex, _delta, _mutationReason);
        emit ParametersUpdated(_tokenId, msg.sender, _evolvoStates[_tokenId].currentParameters);
    }

    /**
     * @dev An artist or approved proposer submits a new off-chain algorithmic evolution method to the DAO for approval.
     * The actual algorithm logic lives off-chain, but its identifier, requirements, and fee are registered here.
     * @param _algorithmURI URI pointing to the algorithm description, code, or specification.
     * @param _algorithmHash Unique hash of the algorithm content (e.g., IPFS hash) for integrity and uniqueness.
     * @param _requiredParamIndices Indices of parameters this algorithm expects to operate on.
     * @param _feeRequirement The specific ETH fee required to trigger this particular algorithm.
     */
    function proposeAlgorithmicEvolution(
        string memory _algorithmURI,
        bytes32 _algorithmHash,
        uint256[] memory _requiredParamIndices,
        uint256 _feeRequirement
    ) public {
        require(evolutionAlgorithms[_algorithmHash].proposer == address(0), "EvolvoNFT: Algorithm already proposed");

        evolutionAlgorithms[_algorithmHash] = EvolutionAlgorithm({
            uri: _algorithmURI,
            proposer: msg.sender,
            proposedTimestamp: block.timestamp,
            approved: false,
            approvalVotes: 0,
            rejectionVotes: 0,
            requiredParamIndices: _requiredParamIndices,
            feeRequirement: _feeRequirement,
            executed: false // This flag can be used if algorithms are one-time use per proposal.
        });

        emit AlgorithmicEvolutionProposed(_algorithmHash, _algorithmURI, msg.sender);
    }

    /**
     * @dev Allows DAO members and active curators with sufficient reputation to vote on a proposed algorithmic evolution.
     * Simplified voting: if total approval votes meet `minDAOVotesForApproval`, the algorithm is approved.
     * @param _algorithmHash The hash of the algorithm being voted on.
     * @param _approve True to cast an 'approve' vote, false to cast a 'reject' vote.
     */
    function voteForAlgorithmicEvolution(bytes32 _algorithmHash, bool _approve) public {
        EvolutionAlgorithm storage alg = evolutionAlgorithms[_algorithmHash];
        require(alg.proposer != address(0), "EvolvoNFT: Algorithm not proposed");
        require(!alg.approved && !alg.executed, "EvolvoNFT: Algorithm already processed (approved or rejected)");
        require(isDAOAddress[msg.sender] || (curators[msg.sender].isActive && curators[msg.sender].reputationScore >= minCuratorReputationForVote),
            "EvolvoNFT: Caller is not an active DAO member or a curator with sufficient reputation");

        // A more robust system would implement a per-voter tracking to prevent double voting.
        // For simplicity in this demo, it's omitted but crucial for production.

        if (_approve) {
            alg.approvalVotes++;
        } else {
            alg.rejectionVotes++;
        }

        // Auto-approve if threshold is met. Rejection logic could also be added.
        if (alg.approvalVotes >= minDAOVotesForApproval && !alg.approved) {
            alg.approved = true;
        }

        emit AlgorithmicEvolutionVoted(_algorithmHash, msg.sender, _approve);
    }

    /**
     * @dev Triggers the application of an approved algorithmic evolution to an EvolvoNFT.
     * This function is designed to be called by an off-chain executor or keeper service after
     * an oracle confirms that the actual off-chain algorithm has processed the NFT's current parameters
     * and generated new ones. It requires the specific fee for that algorithm.
     * @param _tokenId The ID of the EvolvoNFT to evolve.
     * @param _algorithmHash The hash of the approved algorithm to apply.
     * @param _algInputData Encoded data (e.g., `abi.encode(newParameters)`) representing the result
     *                      of the off-chain algorithm's computation. An oracle would typically provide this.
     */
    function executeAlgorithmicEvolution(uint256 _tokenId, bytes32 _algorithmHash, bytes memory _algInputData)
        public
        payable
        nonReentrant
    {
        require(_exists(_tokenId), "EvolvoNFT: Token does not exist");
        EvolutionAlgorithm storage alg = evolutionAlgorithms[_algorithmHash];
        require(alg.approved, "EvolvoNFT: Algorithm not approved or does not exist");
        // Remove `!alg.executed` check if algorithms are reusable for new proposals, keep if each proposal is one-time use.
        require(!alg.executed, "EvolvoNFT: This algorithm proposal has already been executed");
        require(msg.value >= alg.feeRequirement, "EvolvoNFT: Insufficient algorithm execution fee");

        // Simulate the off-chain algorithm result: `_algInputData` is expected to contain the new parameters.
        // In a production environment, this would be secured by a trusted oracle.
        (uint256[] memory _newParameters) = abi.decode(_algInputData, (uint256[]));
        require(_newParameters.length == _evolvoStates[_tokenId].currentParameters.length, "EvolvoNFT: New parameters mismatch length of current parameters");

        _evolvoStates[_tokenId].currentParameters = _newParameters;
        _evolvoStates[_tokenId].evolutionHistoryHashes.push(_algorithmHash);
        _evolvoStates[_tokenId].evolutionTimestamps.push(block.timestamp);

        protocolFeesCollected += uint224(msg.value); // Collect fee for the protocol
        alg.executed = true; // Mark this specific algorithm proposal as executed.

        emit AlgorithmicEvolutionExecuted(_tokenId, _algorithmHash, _algInputData);
        emit ParametersUpdated(_tokenId, address(this), _newParameters); // Emitted by contract itself
    }

    /**
     * @dev Returns the current generative parameters (genes) of a given EvolvoNFT.
     * @param _tokenId The ID of the EvolvoNFT.
     * @return An array of uint256 representing the current parameters.
     */
    function getEvolvoParameters(uint256 _tokenId) public view returns (uint256[] memory) {
        require(_exists(_tokenId), "EvolvoNFT: Token does not exist");
        return _evolvoStates[_tokenId].currentParameters;
    }

    /**
     * @dev Returns the full history of parameter changes for an EvolvoNFT.
     * Useful for visualizing the art's evolution over time.
     * @param _tokenId The ID of the EvolvoNFT.
     * @return evolutionHistoryHashes An array of bytes32 representing the unique identifiers of each evolution event (mutation reason hash or algorithm hash).
     * @return evolutionTimestamps An array of uint256 representing the timestamp of each corresponding evolution event.
     */
    function getEvolvoHistory(uint256 _tokenId) public view returns (bytes32[] memory, uint256[] memory) {
        require(_exists(_tokenId), "EvolvoNFT: Token does not exist");
        return (_evolvoStates[_tokenId].evolutionHistoryHashes, _evolvoStates[_tokenId].evolutionTimestamps);
    }

    /**
     * @dev Overrides ERC721URIStorage tokenURI to potentially include dynamic parameter info in metadata.
     * While this function returns a static URI here, in a real application, the `baseURI` would point
     * to a gateway service (e.g., API) that dynamically generates the NFT's metadata JSON based on
     * its current on-chain parameters and environmental factors.
     * @param tokenId The ID of the token.
     * @return The URI for the token's metadata.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory baseURI = super.tokenURI(tokenId);
        // Example of how you might append dynamic parameters to the URI:
        // if (bytes(baseURI).length > 0) {
        //     return string(abi.encodePacked(baseURI, "?param0=", Strings.toString(_evolvoStates[tokenId].currentParameters[0])));
        // }
        return baseURI; // For simplicity, returning the base URI. Off-chain service handles dynamic content.
    }

    /**
     * @dev See {ERC2981-royaltyInfo}. This implementation uses a default royalty set in the constructor.
     * It could be extended to allow per-NFT royalty settings if `_setTokenRoyalty` was used.
     * @param _tokenId The ID of the EvolvoNFT.
     * @param _salePrice The sale price for which royalties are calculated.
     * @return The royalty recipient and royalty amount.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        override(ERC2981)
        returns (address, uint256)
    {
        // For simplicity, using the default royalty set in constructor for all NFTs.
        return super.royaltyInfo(_tokenId, _salePrice);
    }


    // --- II. Patronage & Influence Staking ---

    /**
     * @dev Allows a patron to stake ETH on a specific EvolvoNFT. This staked amount contributes to their
     * influence score for that NFT, potentially giving them more weight in future evolution decisions
     * (e.g., through an off-chain voting system or integrated on-chain governance).
     * @param _tokenId The ID of the EvolvoNFT.
     */
    function stakeForInfluence(uint256 _tokenId) public payable nonReentrant {
        require(_exists(_tokenId), "EvolvoNFT: Token does not exist");
        require(msg.value >= influenceStakeAmount, "EvolvoNFT: Insufficient stake amount (must be >= influenceStakeAmount)");

        _evolvoStates[_tokenId].patronStakes[msg.sender] += msg.value;
        _evolvoStates[_tokenId].totalStakedInfluence += msg.value;
        protocolFeesCollected += uint224(msg.value / 10); // A small portion of stake goes to protocol fees

        emit InfluenceStaked(_tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Allows a patron to unstake their previously staked ETH from an EvolvoNFT.
     * @param _tokenId The ID of the EvolvoNFT.
     * @param _amount The amount of ETH to unstake.
     */
    function unstakeInfluence(uint256 _tokenId, uint256 _amount) public nonReentrant {
        require(_exists(_tokenId), "EvolvoNFT: Token does not exist");
        require(_evolvoStates[_tokenId].patronStakes[msg.sender] >= _amount, "EvolvoNFT: Insufficient staked amount to unstake");
        require(_amount > 0, "EvolvoNFT: Amount must be greater than 0");

        _evolvoStates[_tokenId].patronStakes[msg.sender] -= _amount;
        _evolvoStates[_tokenId].totalStakedInfluence -= _amount;

        payable(msg.sender).transfer(_amount); // Return staked ETH to the patron

        emit InfluenceUnstaked(_tokenId, msg.sender, _amount);
    }

    /**
     * @dev Returns the influence score (amount of staked ETH) of a patron on a specific EvolvoNFT.
     * @param _tokenId The ID of the EvolvoNFT.
     * @param _patron The address of the patron.
     * @return The amount of ETH staked by the patron on this NFT.
     */
    function getPatronInfluence(uint256 _tokenId, address _patron) public view returns (uint256) {
        require(_exists(_tokenId), "EvolvoNFT: Token does not exist");
        return _evolvoStates[_tokenId].patronStakes[_patron];
    }

    /**
     * @dev Allows patrons to claim their share of fees collected from evolutions they influenced or staked on.
     * This is a simplified reward calculation for demonstration purposes. In a real system, a more
     * sophisticated tokenomics model (e.g., ve-token model, precise fee distribution per evolution event)
     * would be needed to track and distribute accrued rewards accurately. Here, it simply simulates a claim.
     * @param _tokenId The ID of the EvolvoNFT (used as context, but rewards are global in this simplified version).
     */
    function claimPatronRewards(uint256 _tokenId) public {
        require(_exists(_tokenId), "EvolvoNFT: Token does not exist"); // Ensure token exists even if reward calc is global
        uint256 patronStake = _evolvoStates[_tokenId].patronStakes[msg.sender];
        require(patronStake > 0, "EvolvoNFT: No stake on this NFT to claim rewards from");

        // Example simplified reward calculation: A small percentage of overall protocol fees
        // proportional to their stake on THIS NFT. This assumes `protocolFeesCollected`
        // accumulates all fees and needs to be carefully managed to prevent double claims.
        // A dedicated reward pool and claim tracking (e.g., lastClaimedTimestamp, rewardRate)
        // would be essential for a production system.
        uint256 rewards = (protocolFeesCollected * patronStake) / (_evolvoStates[_tokenId].totalStakedInfluence > 0 ? _evolvoStates[_tokenId].totalStakedInfluence : 1) / 1000; // Example: 0.1% of fees proportional to stake

        require(rewards > 0, "EvolvoNFT: No rewards to claim or rewards are too small");

        // In a real system: transfer `rewards` ETH or specific reward tokens to msg.sender,
        // and reduce the available reward pool. This demo just emits an event.
        emit PatronRewardsClaimed(_tokenId, msg.sender, rewards);
    }

    // --- III. Curator & Reputation System ---

    /**
     * @dev A user applies to become a curator within the EvolvoNFT ecosystem.
     * Their application needs to be voted on and approved by existing DAO members/curators.
     * @param _metadataURI URI pointing to the curator's off-chain profile data, credentials, or portfolio.
     */
    function applyAsCurator(string memory _metadataURI) public {
        require(!curators[msg.sender].isActive, "EvolvoNFT: Already an active curator");
        require(curators[msg.sender].applicationTimestamp == 0, "EvolvoNFT: Application already pending for this address");

        curators[msg.sender] = CuratorProfile({
            metadataURI: _metadataURI,
            reputationScore: 0, // Starts at 0, builds up with approval and good actions
            isActive: false,
            applicationTimestamp: block.timestamp,
            approvalVotes: 0,
            rejectionVotes: 0
        });

        emit CuratorApplied(msg.sender, _metadataURI);
    }

    /**
     * @dev Allows DAO members and existing active curators to vote on a curator application.
     * Applicants are approved if they meet the `minDAOVotesForApproval`.
     * @param _applicant The address of the curator applicant.
     * @param _approve True to cast an 'approve' vote, false to cast a 'reject' vote.
     */
    function voteOnCuratorApplication(address _applicant, bool _approve) public {
        CuratorProfile storage profile = curators[_applicant];
        require(profile.applicationTimestamp != 0 && !profile.isActive, "EvolvoNFT: Applicant not pending or already active");
        require(isDAOAddress[msg.sender] || (curators[msg.sender].isActive && curators[msg.sender].reputationScore >= minCuratorReputationForVote),
            "EvolvoNFT: Caller is not an active DAO member or a curator with sufficient reputation to vote");

        // A real system would track per-voter voting to prevent double voting.
        // For simplicity in this demo, it's omitted.

        if (_approve) {
            profile.approvalVotes++;
        } else {
            profile.rejectionVotes++;
        }

        if (profile.approvalVotes >= minDAOVotesForApproval && !profile.isActive) {
            profile.isActive = true;
            profile.reputationScore = 100; // Initial reputation score for newly approved curators
            emit CuratorReputationUpdated(_applicant, profile.reputationScore);
        }

        emit CuratorVoted(msg.sender, _applicant, _approve);
    }

    /**
     * @dev Active curators can submit reviews or ratings for EvolvoNFTs or proposed algorithms.
     * This action contributes to their reputation score. The quality of the review could be
     * assessed off-chain, and then reported via another function or by DAO. For demo, it's simplified.
     * @param _tokenId The ID of the EvolvoNFT being reviewed (use 0 for general algorithm reviews if applicable).
     * @param _reviewUri URI to the detailed review content (e.g., on IPFS).
     * @param _rating A numerical rating (e.g., 1-5 stars) reflecting the curator's assessment.
     */
    function submitCuratorReview(uint256 _tokenId, string memory _reviewUri, uint256 _rating) public {
        require(curators[msg.sender].isActive, "EvolvoNFT: Caller is not an active curator");
        require(_rating >= 1 && _rating <= 5, "EvolvoNFT: Rating must be between 1 and 5");
        // For demo: simple reputation increase. A real system would be more nuanced,
        // potentially evaluating the consensus of ratings or the quality of the review itself.
        curators[msg.sender].reputationScore += _rating;
        emit CuratorReputationUpdated(msg.sender, curators[msg.sender].reputationScore);
        // An event could also be emitted for review submission itself (e.g., `ReviewSubmitted(tokenId, msg.sender, _reviewUri, _rating);`)
    }

    /**
     * @dev Returns the current reputation score of a specified curator.
     * @param _curator The address of the curator.
     * @return The current reputation score of the curator.
     */
    function getCuratorReputation(address _curator) public view returns (uint256) {
        return curators[_curator].reputationScore;
    }

    /**
     * @dev Allows the DAO to penalize a curator for misconduct, reducing their reputation.
     * If the reputation drops to zero, the curator's `isActive` status is revoked.
     * This function should be invoked via a successful governance proposal.
     * @param _curator The address of the curator to penalize.
     * @param _penaltyAmount The amount to reduce their reputation by.
     */
    function penalizeCurator(address _curator, uint256 _penaltyAmount) public onlyDAO {
        require(curators[_curator].isActive, "EvolvoNFT: Curator not active or does not exist");
        // Ensure reputation doesn't go below zero
        curators[_curator].reputationScore = curators[_curator].reputationScore > _penaltyAmount ? curators[_curator].reputationScore - _penaltyAmount : 0;
        if (curators[_curator].reputationScore == 0) {
            curators[_curator].isActive = false; // Deactivate if reputation drops to 0
        }
        emit CuratorReputationUpdated(_curator, curators[_curator].reputationScore);
    }

    // --- IV. Environmental Factors Integration ---

    /**
     * @dev An authorized oracle (or DAO in this simplified example) updates an external environmental factor.
     * These factors can be consumed by off-chain generative algorithms to dynamically influence NFT evolution,
     * allowing art to react to real-world conditions (e.g., current crypto prices, weather data, time of day).
     * @param _factorName The name of the environmental factor (e.g., "temperature", "marketVolatility", "pollutionIndex").
     * @param _value The new numerical value of the factor.
     */
    function updateEnvironmentalFactor(string memory _factorName, uint256 _value) public onlyDAO {
        // In a real decentralized application, this function would likely be called by a trusted oracle network
        // (e.g., Chainlink) rather than the general DAO directly, or through a more specific oracle governance module.
        environmentalFactors[_factorName] = _value;
        emit EnvironmentalFactorUpdated(_factorName, _value);
    }

    /**
     * @dev Returns the current value of a specified environmental factor.
     * Off-chain generative art algorithms would query these values to influence their output.
     * @param _factorName The name of the environmental factor.
     * @return The current value of the environmental factor.
     */
    function getEnvironmentalFactor(string memory _factorName) public view returns (uint256) {
        return environmentalFactors[_factorName];
    }

    // --- V. Governance & System Management (Simplified DAO) ---

    /**
     * @dev Allows a DAO member to propose a general governance action that can modify contract parameters or invoke other functions.
     * The proposed action is represented by encoded call data for the target function.
     * @param _callData The encoded call data for the function to be executed if the proposal passes.
     * @param _description A human-readable description of the proposal.
     */
    function proposeGovernanceAction(bytes memory _callData, string memory _description) public onlyDAO {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        governanceProposals[proposalId] = GovernanceProposal({
            callData: _callData,
            description: _description,
            executed: false,
            votesFor: 0,
            votesAgainst: 0,
            submissionTimestamp: block.timestamp,
            proposer: msg.sender
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows DAO members to vote on a governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnGovernanceAction(uint256 _proposalId, bool _support) public onlyDAO {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "EvolvoNFT: Proposal does not exist");
        require(!proposal.executed, "EvolvoNFT: Proposal already executed");
        require(!_hasVotedProposal[_proposalId][msg.sender], "EvolvoNFT: Already voted on this proposal");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        _hasVotedProposal[_proposalId][msg.sender] = true;

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes an approved governance proposal.
     * Requires the proposal to have gathered at least `minDAOVotesForApproval` 'for' votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceAction(uint256 _proposalId) public onlyDAO {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "EvolvoNFT: Proposal does not exist");
        require(!proposal.executed, "EvolvoNFT: Proposal already executed");
        require(proposal.votesFor >= minDAOVotesForApproval, "EvolvoNFT: Not enough votes for approval");
        // A more sophisticated DAO would also include a voting period and a timelock for execution.

        proposal.executed = true;

        // Execute the proposed action by making an internal call to the contract itself
        (bool success, ) = address(this).call(proposal.callData);
        require(success, "EvolvoNFT: Proposal execution failed");

        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Sets the base fee required for a patron to trigger an NFT evolution.
     * This function is intended to be called only through a successful governance proposal.
     * @param _newFee The new base evolution fee in wei.
     */
    function setBaseEvolutionFee(uint256 _newFee) public onlyDAO {
        baseEvolutionFee = _newFee;
    }

    /**
     * @dev Sets the minimum amount of stake tokens (ETH) required for a patron to gain influence on an NFT.
     * This function is intended to be called only through a successful governance proposal.
     * @param _amount The new minimum stake amount in wei.
     */
    function setInfluenceStakeAmount(uint256 _amount) public onlyDAO {
        influenceStakeAmount = _amount;
    }

    // --- VI. Utilities & Funds Management ---

    /**
     * @dev Allows the DAO to withdraw accumulated protocol fees from the contract's balance.
     * This ensures the operational sustainability of the EvolvoNFT ecosystem.
     * @param _to The address to send the withdrawn fees to.
     * @param _amount The amount of fees (in wei) to withdraw.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) public onlyDAO nonReentrant {
        require(_amount > 0, "EvolvoNFT: Amount must be greater than 0");
        require(protocolFeesCollected >= _amount, "EvolvoNFT: Insufficient fees collected in protocol balance");
        require(address(this).balance >= _amount, "EvolvoNFT: Insufficient contract ETH balance");

        protocolFeesCollected -= uint224(_amount);
        payable(_to).transfer(_amount);

        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    /**
     * @dev Returns the total number of EvolvoNFTs minted so far.
     * @return The current token ID counter value, representing total supply.
     */
    function getTotalEvolvoNFTs() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // --- Internal/Utility Functions for OpenZeppelin overrides ---

    /**
     * @dev Overrides the _baseURI function from ERC721. Not used directly since `tokenURI` is overridden.
     */
    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return "";
    }

    // --- Fallback and Receive Functions ---

    /**
     * @dev Fallback function to allow the contract to receive ETH.
     * Any ETH sent without calling a specific function will be handled here.
     */
    receive() external payable {}

    /**
     * @dev Fallback function for calls to non-existent functions.
     * Allows the contract to receive ETH even if `receive()` is not explicitly called.
     */
    fallback() external payable {}
}
```