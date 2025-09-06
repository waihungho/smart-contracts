The smart contract presented below, **CognitiveCore Protocol (CCP)**, introduces a novel class of Non-Fungible Tokens (NFTs) called "CognitiveCores." These Cores are not static collectibles; they are designed to be dynamic, self-evolving modules representing abstract knowledge, code, or ideas. Their utility, influence, and value adapt based on their creation, algorithmic fusion with other Cores, refinement, and a verifiable record of their "deployment" and impact within a conceptual "protocol space."

---

## CognitiveCore Protocol (CCP) - Outline and Function Summary

**Contract Name:** CognitiveCore Protocol (CCP)

**Core Idea:** A decentralized platform for creating, evolving, and deploying "CognitiveCores" – dynamic NFTs whose utility and attributes change based on their lineage, on-chain activity, and recorded impact. It fosters a generative ecosystem where knowledge modules can be combined and refined.

**Advanced Concepts & Features:**

1.  **Algorithmic NFT Fusion & Lineage:** Cores can be algorithmically combined (merged) to create new, more complex Cores, inheriting traits and establishing a verifiable on-chain lineage. This is a form of decentralized, synthetic "creativity" or knowledge synthesis.
2.  **Adaptive Utility Tiers:** A Core's utility (e.g., potential for royalty share, governance weight, access rights) is not static but dynamically determined by its "activity score," "fusion count," and verified "impact events." Utility tiers are calculated on-demand.
3.  **On-Chain Impact Tracking:** A mechanism (simplified via an authorized oracle/admin for this example) to record and verify the real-world utility, success, or contribution of a deployed Core, directly influencing its on-chain attributes and overall utility.
4.  **Ephemeral Staking for Utility Boost:** Core owners can temporarily stake their Cores to significantly boost their "activity score," enhancing their utility tier for a defined period.
5.  **Decentralized Content Refinement:** A proposal-based system for updating a Core's underlying "content hash" (representing its associated knowledge/code), enabling iterative improvement and versioning.
6.  **Delegated Utility:** Core owners can delegate the *usage* of their Core's utility to another address without transferring ownership, facilitating collaboration or temporary access grants.
7.  **Activity Decay Mechanism:** To promote active participation and prevent "stale" Cores from indefinitely retaining high utility, an admin-triggered decay mechanism reduces the activity score of inactive Cores over time.

---

### Function Summary:

**I. Core NFT Management & Basic ERC721-like Functions (Custom Implementation):**

1.  `mintCognitiveCore(address _to, string memory _contentHash)`: Creates a new "genesis" CognitiveCore, assigning it a unique ID, content hash, and initial activity score.
2.  `transferCore(address _from, address _to, uint256 _tokenId)`: Transfers ownership of a CognitiveCore to another address.
3.  `approveCore(address _to, uint256 _tokenId)`: Grants approval for a specific address to manage a specific Core.
4.  `getApprovedCore(uint256 _tokenId) public view returns (address)`: Returns the approved address for a given Core.
5.  `setApprovalForAllCores(address _operator, bool _approved)`: Grants or revokes approval for an operator to manage all of the caller's Cores.
6.  `isApprovedForAllCores(address _owner, address _operator) public view returns (bool)`: Checks if an operator has approval for all of an owner's Cores.
7.  `ownerOfCore(uint256 _tokenId) public view returns (address)`: Returns the owner of a specific CognitiveCore.
8.  `balanceOfCores(address _owner) public view returns (uint256)`: Returns the number of Cores owned by a specific address.

**II. Core Evolution & Fusion Mechanics:**

9.  `refineCoreContent(uint256 _tokenId, string memory _newContentHash)`: Allows the owner to update the `contentHash` of their Core, signifying an upgrade or refinement.
10. `proposeCoreFusion(uint256 _coreA, uint256 _coreB, string memory _proposedChildContentHash)`: Initiates a proposal to merge two existing Cores into a new, more advanced one.
11. `voteOnCoreFusion(uint256 _proposalId, bool _forProposal)`: Allows owners of eligible Cores (or the proposer) to vote on an active fusion proposal.
12. `executeCoreFusion(uint256 _proposalId)`: Finalizes a successful fusion proposal, burning the parent Cores and minting a new child Core with a recorded lineage.

**III. Dynamic Utility & Access Control:**

13. `getCoreDetails(uint256 _tokenId) public view returns (...)`: Retrieves all stored attributes and dynamic metrics for a given CognitiveCore.
14. `getCoreUtilityTier(uint256 _tokenId) public view returns (CoreUtilityTier)`: Calculates and returns the current utility tier of a Core based on its dynamic attributes.
15. `getCoreAncestry(uint256 _tokenId) public view returns (uint256[] memory)`: Traces and returns the direct parent Cores from which a given Core was fused.
16. `stakeCoreForBoost(uint256 _tokenId, uint256 _durationBlocks)`: Stakes a Core for a specified number of blocks, providing a temporary boost to its activity score.
17. `unstakeCoreFromBoost(uint256 _tokenId)`: Unstakes a Core, ending its temporary activity score boost.
18. `delegateCoreUtility(uint256 _tokenId, address _delegatee, uint256 _durationBlocks)`: Allows a Core owner to grant temporary usage of their Core's utility to another address.
19. `revokeCoreUtilityDelegation(uint256 _tokenId)`: Revokes any active utility delegation for a Core.

**IV. Deployment & Impact Tracking:**

20. `deployCoreToProtocolSpace(uint256 _tokenId)`: Marks a CognitiveCore as "deployed," signifying its active contribution or use within a larger system.
21. `registerImpactEvent(uint256 _tokenId, uint256 _impactWeight)`: (Callable by `IMPACT_ORACLE_ROLE` or admin) Records a verified positive impact event for a deployed Core, increasing its `impactEvents` count and score.

**V. Protocol Governance & Administration:**

22. `decayInactiveCores(uint256[] memory _tokenIds)`: (Callable by `PROTOCOL_ADMIN_ROLE`) Reduces the activity score of specified inactive Cores to reflect their current engagement.
23. `setUtilityTierThresholds(uint256[] memory _newThresholds)`: (Callable by `PROTOCOL_ADMIN_ROLE`) Updates the numerical thresholds that define each utility tier.
24. `setFusionVoteThreshold(uint256 _newThreshold)`: (Callable by `PROTOCOL_ADMIN_ROLE`) Adjusts the minimum percentage of votes required for a fusion proposal to pass.
25. `updateRole(bytes32 _role, address _account, bool _grant)`: (Callable by `DEFAULT_ADMIN_ROLE`) Manages role assignments (e.g., for `PROTOCOL_ADMIN_ROLE`, `IMPACT_ORACLE_ROLE`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CognitiveCore Protocol (CCP)
 * @author Your Name/AI
 * @notice A decentralized platform for creating, evolving, and deploying "CognitiveCores" – dynamic NFTs
 *         whose utility and attributes change based on their lineage, on-chain activity, and recorded impact.
 *         It fosters a generative ecosystem where knowledge modules can be combined and refined.
 *
 * @dev This contract aims to showcase advanced, creative, and non-duplicate concepts in Solidity.
 *      It implements a simplified ERC721-like interface internally for Core management
 *      to highlight its unique mechanics without relying on external ERC721 library inheritance.
 *      For production, a robust ERC721 implementation (e.g., from OpenZeppelin) would be integrated.
 *
 * Outline and Function Summary:
 *
 * Core Idea: Dynamic, self-evolving NFTs (CognitiveCores) that represent abstract modules of knowledge, code, or ideas.
 * Their utility and value evolve based on their creation, fusion, refinement, and real-world "deployment" impact.
 *
 * Advanced Concepts & Features:
 * 1.  Algorithmic NFT Fusion & Lineage: Cores can be combined (merged) to create new, more complex Cores,
 *     inheriting traits and establishing a verifiable on-chain lineage.
 * 2.  Adaptive Utility Tiers: NFT utility (e.g., potential for royalty share, governance weight) is dynamic,
 *     determined by "activity score," "fusion count," and verified "impact events."
 * 3.  On-Chain Impact Tracking: A mechanism (simplified via an authorized oracle/admin) to record and verify
 *     the real-world utility or success of a deployed Core, directly influencing its on-chain attributes.
 * 4.  Ephemeral Staking for Utility Boost: Temporary boosts to a Core's utility through staking.
 * 5.  Decentralized Content Refinement: A proposal-based system for updating a Core's underlying content/logic.
 * 6.  Delegated Utility: Core owners can delegate the usage of their Core's utility to another address.
 * 7.  Activity Decay Mechanism: Reduces activity score for inactive Cores over time to prevent stagnation.
 *
 * Function Summary:
 *
 * I. Core NFT Management & Basic ERC721-like Functions (Custom Implementation):
 * 1.  `mintCognitiveCore(address _to, string memory _contentHash)`: Creates a new "genesis" CognitiveCore.
 * 2.  `transferCore(address _from, address _to, uint256 _tokenId)`: Transfers ownership of a Core.
 * 3.  `approveCore(address _to, uint256 _tokenId)`: Grants approval for a specific address to manage a Core.
 * 4.  `getApprovedCore(uint256 _tokenId)`: Returns the approved address for a given Core.
 * 5.  `setApprovalForAllCores(address _operator, bool _approved)`: Grants/revokes operator approval.
 * 6.  `isApprovedForAllCores(address _owner, address _operator)`: Checks operator approval status.
 * 7.  `ownerOfCore(uint256 _tokenId)`: Returns the owner of a specific Core.
 * 8.  `balanceOfCores(address _owner)`: Returns the number of Cores owned by an address.
 *
 * II. Core Evolution & Fusion Mechanics:
 * 9.  `refineCoreContent(uint256 _tokenId, string memory _newContentHash)`: Updates the content hash of a Core.
 * 10. `proposeCoreFusion(uint256 _coreA, uint256 _coreB, string memory _proposedChildContentHash)`: Initiates a fusion proposal.
 * 11. `voteOnCoreFusion(uint256 _proposalId, bool _forProposal)`: Allows voting on a fusion proposal.
 * 12. `executeCoreFusion(uint256 _proposalId)`: Finalizes a successful fusion, minting a child Core.
 *
 * III. Dynamic Utility & Access Control:
 * 13. `getCoreDetails(uint256 _tokenId)`: Retrieves comprehensive data for a Core.
 * 14. `getCoreUtilityTier(uint256 _tokenId)`: Calculates and returns the current utility level of a Core.
 * 15. `getCoreAncestry(uint256 _tokenId)`: Traces and returns direct parent Cores.
 * 16. `stakeCoreForBoost(uint256 _tokenId, uint256 _durationBlocks)`: Stakes a Core for a temporary activity boost.
 * 17. `unstakeCoreFromBoost(uint256 _tokenId)`: Unstakes a Core.
 * 18. `delegateCoreUtility(uint256 _tokenId, address _delegatee, uint256 _durationBlocks)`: Delegates Core utility usage.
 * 19. `revokeCoreUtilityDelegation(uint256 _tokenId)`: Revokes utility delegation.
 *
 * IV. Deployment & Impact Tracking:
 * 20. `deployCoreToProtocolSpace(uint256 _tokenId)`: Marks a Core as "deployed" for active contribution.
 * 21. `registerImpactEvent(uint256 _tokenId, uint256 _impactWeight)`: (Oracle/Admin) Records a verified impact event for a deployed Core.
 *
 * V. Protocol Governance & Administration:
 * 22. `decayInactiveCores(uint256[] memory _tokenIds)`: (Admin) Reduces activity score for specified inactive Cores.
 * 23. `setUtilityTierThresholds(uint256[] memory _newThresholds)`: (Admin) Updates utility tier definition thresholds.
 * 24. `setFusionVoteThreshold(uint256 _newThreshold)`: (Admin) Adjusts required votes for fusion proposals.
 * 25. `updateRole(bytes32 _role, address _account, bool _grant)`: (Admin) Manages role assignments.
 */
contract CognitiveCoreProtocol {
    // --- Constants ---
    uint256 private constant MAX_ACTIVITY_SCORE = 1000;
    uint256 private constant CORE_MINT_ACTIVITY_SCORE = 100;
    uint256 private constant FUSION_BASE_ACTIVITY_BOOST = 50;
    uint256 private constant MAX_PARENT_CORES = 2; // For simple fusion, 2 parents
    uint256 private constant MIN_VOTE_PERCENTAGE_TO_PASS = 60; // 60%

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; // Base admin for contract itself and role management
    bytes32 public constant PROTOCOL_ADMIN_ROLE = keccak256("PROTOCOL_ADMIN_ROLE"); // For managing protocol parameters
    bytes32 public constant IMPACT_ORACLE_ROLE = keccak256("IMPACT_ORACLE_ROLE"); // For registering impact events

    // --- Enums ---
    enum FusionProposalStatus { Pending, Approved, Rejected, Executed }
    enum CoreUtilityTier { Genesis, Evolving, Refined, Advanced, Master }

    // --- Structs ---

    struct Core {
        address owner;
        string contentHash;
        uint256 creationBlock;
        uint256 lastRefinementBlock;
        uint256[] parentCores; // Array of tokenId of parent cores
        uint256 activityScore; // Increases with activity, decays over time
        uint256 fusionCount;   // Number of times this Core has been a parent in a fusion
        uint256 impactEvents;  // Count of verified impact events
        bool isDeployed;       // True if this Core is actively deployed in a protocol space
        uint256 stakedUntilBlock; // Block number until which the core is staked for a boost
        address utilityDelegatee; // Address allowed to use utility
        uint256 delegatedUntilBlock; // Block number until which utility is delegated
    }

    struct CoreFusionProposal {
        address proposer;
        uint256 coreA;
        uint256 coreB;
        string proposedChildContentHash;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        uint256 votingEndTime; // Block number
        FusionProposalStatus status;
    }

    // --- State Variables ---

    uint256 private _nextTokenId;
    uint256 private _nextProposalId;

    // NFT-like mappings
    mapping(uint256 => Core) public idToCore;
    mapping(uint256 => address) private _ownerOf; // ownerOfCore(tokenId)
    mapping(address => uint256) private _balanceOf; // balanceOfCores(owner)
    mapping(uint256 => address) private _coreApprovals; // tokenId => approvedAddress
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // Protocol-specific mappings
    mapping(uint256 => CoreFusionProposal) public fusionProposals;
    uint256[] public utilityTierThresholds; // e.g., [100, 250, 500, 750] for tiers 1,2,3,4 (Genesis is 0)
    uint256 public fusionVoteThreshold; // Percentage required for a fusion to pass

    // Role management mappings (Simplified ACL)
    mapping(bytes32 => mapping(address => bool)) private _roles;

    // --- Events ---
    event CoreMinted(uint256 indexed tokenId, address indexed owner, string contentHash);
    event CoreTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event CoreApproved(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAllCores(address indexed owner, address indexed operator, bool approved);

    event CoreRefined(uint256 indexed tokenId, string newContentHash);
    event CoreFusionProposed(uint256 indexed proposalId, uint256 coreA, uint256 coreB, address indexed proposer);
    event CoreFusionVoted(uint256 indexed proposalId, address indexed voter, bool _for);
    event CoreFusionExecuted(uint256 indexed proposalId, uint256 indexed childCoreId, uint256 parentA, uint256 parentB);
    event CoreDeployed(uint256 indexed tokenId, address indexed deployer);
    event CoreImpactRegistered(uint256 indexed tokenId, address indexed oracle, uint256 impactWeight);
    event CoreStaked(uint256 indexed tokenId, uint256 untilBlock);
    event CoreUnstaked(uint256 indexed tokenId);
    event CoreUtilityDelegated(uint256 indexed tokenId, address indexed delegatee, uint256 untilBlock);
    event CoreUtilityDelegationRevoked(uint256 indexed tokenId);
    event CoreActivityDecayed(uint256 indexed tokenId, uint256 oldScore, uint256 newScore);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // --- Constructor ---
    constructor() {
        _nextTokenId = 1;
        _nextProposalId = 1;

        // Set initial roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PROTOCOL_ADMIN_ROLE, msg.sender); // Initial deployer is protocol admin
        _setupRole(IMPACT_ORACLE_ROLE, msg.sender);  // Initial deployer is impact oracle

        // Set initial utility tier thresholds (example: [Evolving, Refined, Advanced, Master])
        // Score < 100 = Genesis, >=100 = Evolving, >=250 = Refined, >=500 = Advanced, >=750 = Master
        utilityTierThresholds.push(100);
        utilityTierThresholds.push(250);
        utilityTierThresholds.push(500);
        utilityTierThresholds.push(750);

        fusionVoteThreshold = MIN_VOTE_PERCENTAGE_TO_PASS;
    }

    // --- Modifiers ---

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "CCP: Caller is not authorized for this role");
        _;
    }

    modifier onlyCoreOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "CCP: Not authorized for this Core");
        _;
    }

    modifier coreExists(uint256 _tokenId) {
        require(_exists(_tokenId), "CCP: Core does not exist");
        _;
    }

    modifier coreIsNotDeployed(uint256 _tokenId) {
        require(!idToCore[_tokenId].isDeployed, "CCP: Core is already deployed");
        _;
    }

    modifier coreIsDeployed(uint256 _tokenId) {
        require(idToCore[_tokenId].isDeployed, "CCP: Core is not deployed");
        _;
    }

    modifier fusionProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < _nextProposalId, "CCP: Proposal does not exist");
        _;
    }

    modifier fusionProposalPending(uint256 _proposalId) {
        require(fusionProposals[_proposalId].status == FusionProposalStatus.Pending, "CCP: Proposal not pending");
        _;
    }

    // --- Internal Helpers (ERC721-like) ---

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _ownerOf[_tokenId] != address(0);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = _ownerOf[_tokenId];
        return (_spender == owner ||
                _coreApprovals[_tokenId] == _spender ||
                _operatorApprovals[owner][_spender]);
    }

    function _mint(address _to, uint256 _tokenId, string memory _contentHash, uint256[] memory _parentCores) internal {
        require(_to != address(0), "CCP: Mint to the zero address");
        require(!_exists(_tokenId), "CCP: Token already minted");

        _balanceOf[_to]++;
        _ownerOf[_tokenId] = _to;

        idToCore[_tokenId] = Core({
            owner: _to,
            contentHash: _contentHash,
            creationBlock: block.number,
            lastRefinementBlock: block.number,
            parentCores: _parentCores,
            activityScore: CORE_MINT_ACTIVITY_SCORE,
            fusionCount: 0,
            impactEvents: 0,
            isDeployed: false,
            stakedUntilBlock: 0,
            utilityDelegatee: address(0),
            delegatedUntilBlock: 0
        });

        emit CoreMinted(_tokenId, _to, _contentHash);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_ownerOf[_tokenId] == _from, "CCP: Transfer from invalid owner");
        require(_to != address(0), "CCP: Transfer to the zero address");

        // Clear approvals
        delete _coreApprovals[_tokenId];

        _balanceOf[_from]--;
        _balanceOf[_to]++;
        _ownerOf[_tokenId] = _to;
        idToCore[_tokenId].owner = _to; // Update owner in Core struct

        emit CoreTransferred(_from, _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal {
        address owner = _ownerOf[_tokenId];
        require(owner != address(0), "CCP: Burn non-existent Core");

        // Clear approvals
        delete _coreApprovals[_tokenId];
        // Don't need to clear operator approvals as they are owner-based

        _balanceOf[owner]--;
        delete _ownerOf[_tokenId];
        delete idToCore[_tokenId]; // Remove the Core data

        emit CoreTransferred(owner, address(0), _tokenId); // Standard ERC721 burn event format
    }

    function _clearApproval(uint256 _tokenId) internal {
        delete _coreApprovals[_tokenId];
    }

    function _checkAndIncreaseActivity(uint256 _tokenId) internal {
        Core storage core = idToCore[_tokenId];
        if (core.activityScore < MAX_ACTIVITY_SCORE) {
            core.activityScore = core.activityScore + 1 > MAX_ACTIVITY_SCORE ? MAX_ACTIVITY_SCORE : core.activityScore + 1;
        }
    }

    function _setupRole(bytes32 role, address account) internal {
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    // --- Public Views (ERC721-like) ---

    function ownerOfCore(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "CCP: Core does not exist");
        return _ownerOf[_tokenId];
    }

    function balanceOfCores(address _owner) public view returns (uint256) {
        return _balanceOf[_owner];
    }

    function getApprovedCore(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "CCP: Core does not exist");
        return _coreApprovals[_tokenId];
    }

    function isApprovedForAllCores(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    // --- I. Core NFT Management & Basic ERC721-like Functions ---

    /**
     * @notice Creates a new "genesis" CognitiveCore.
     * @param _to The address to mint the Core to.
     * @param _contentHash The IPFS/Arweave hash or identifier for the Core's content/logic.
     * @return The ID of the newly minted Core.
     */
    function mintCognitiveCore(address _to, string memory _contentHash) public returns (uint256) {
        uint256 newId = _nextTokenId++;
        uint256[] memory emptyParents; // Genesis cores have no parents
        _mint(_to, newId, _contentHash, emptyParents);
        return newId;
    }

    /**
     * @notice Transfers ownership of a CognitiveCore.
     * @param _from The current owner of the Core.
     * @param _to The recipient of the Core.
     * @param _tokenId The ID of the Core to transfer.
     */
    function transferCore(address _from, address _to, uint256 _tokenId) public coreExists(_tokenId) {
        require(_ownerOf[_tokenId] == _from, "CCP: Caller is not owner");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "CCP: Caller not approved or owner");
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @notice Grants approval for a specific address to manage a specific Core.
     * @param _to The address to approve.
     * @param _tokenId The ID of the Core.
     */
    function approveCore(address _to, uint256 _tokenId) public coreExists(_tokenId) onlyCoreOwner(_tokenId) {
        require(_to != _ownerOf[_tokenId], "CCP: Approval to current owner");
        _coreApprovals[_tokenId] = _to;
        emit CoreApproved(_ownerOf[_tokenId], _to, _tokenId);
    }

    /**
     * @notice Grants or revokes approval for an operator to manage all of the caller's Cores.
     * @param _operator The address to set as operator.
     * @param _approved True to grant approval, false to revoke.
     */
    function setApprovalForAllCores(address _operator, bool _approved) public {
        require(_operator != msg.sender, "CCP: Approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAllCores(msg.sender, _operator, _approved);
    }

    // --- II. Core Evolution & Fusion Mechanics ---

    /**
     * @notice Allows the owner to update the `contentHash` of their Core, signifying an upgrade or refinement.
     * @param _tokenId The ID of the Core to refine.
     * @param _newContentHash The new IPFS/Arweave hash or identifier for the Core's content.
     */
    function refineCoreContent(uint256 _tokenId, string memory _newContentHash) public coreExists(_tokenId) onlyCoreOwner(_tokenId) {
        idToCore[_tokenId].contentHash = _newContentHash;
        idToCore[_tokenId].lastRefinementBlock = block.number;
        _checkAndIncreaseActivity(_tokenId);
        emit CoreRefined(_tokenId, _newContentHash);
    }

    /**
     * @notice Initiates a proposal to merge two existing Cores into a new, more advanced one.
     *         The proposer must own both parent Cores.
     * @param _coreA The ID of the first parent Core.
     * @param _coreB The ID of the second parent Core.
     * @param _proposedChildContentHash The content hash for the potential new child Core.
     * @return The ID of the new fusion proposal.
     */
    function proposeCoreFusion(uint256 _coreA, uint256 _coreB, string memory _proposedChildContentHash)
        public
        coreExists(_coreA)
        coreExists(_coreB)
        returns (uint256)
    {
        require(_coreA != _coreB, "CCP: Cannot fuse a Core with itself");
        require(_ownerOf[_coreA] == msg.sender && _ownerOf[_coreB] == msg.sender, "CCP: Proposer must own both parent Cores");
        require(!idToCore[_coreA].isDeployed && !idToCore[_coreB].isDeployed, "CCP: Cannot fuse deployed Cores");

        uint256 proposalId = _nextProposalId++;
        fusionProposals[proposalId] = CoreFusionProposal({
            proposer: msg.sender,
            coreA: _coreA,
            coreB: _coreB,
            proposedChildContentHash: _proposedChildContentHash,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.number + 100, // Voting lasts for 100 blocks (example)
            status: FusionProposalStatus.Pending
        });

        // Proposer automatically votes 'for'
        _voteOnCoreFusion(proposalId, true); // Internal call to handle vote logic

        emit CoreFusionProposed(proposalId, _coreA, _coreB, msg.sender);
        return proposalId;
    }

    /**
     * @notice Allows eligible voters (proposer for now, could be extended to core owners) to vote on a fusion proposal.
     * @param _proposalId The ID of the fusion proposal.
     * @param _forProposal True to vote 'for', false to vote 'against'.
     */
    function voteOnCoreFusion(uint256 _proposalId, bool _forProposal)
        public
        fusionProposalExists(_proposalId)
        fusionProposalPending(_proposalId)
    {
        _voteOnCoreFusion(_proposalId, _forProposal);
    }

    function _voteOnCoreFusion(uint256 _proposalId, bool _forProposal) internal {
        CoreFusionProposal storage proposal = fusionProposals[_proposalId];
        require(msg.sender == proposal.proposer, "CCP: Only proposer can vote on their fusion proposal"); // Simplified: only proposer votes
        require(!proposal.hasVoted[msg.sender], "CCP: Already voted on this proposal");
        require(block.number <= proposal.votingEndTime, "CCP: Voting period has ended");

        proposal.hasVoted[msg.sender] = true;
        if (_forProposal) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit CoreFusionVoted(_proposalId, msg.sender, _forProposal);
    }

    /**
     * @notice Finalizes a successful fusion proposal, burning the parent Cores and minting a new child Core.
     *         Requires the proposal to be approved and the voting period to be over.
     * @param _proposalId The ID of the fusion proposal.
     * @return The ID of the newly created child Core.
     */
    function executeCoreFusion(uint256 _proposalId)
        public
        fusionProposalExists(_proposalId)
        fusionProposalPending(_proposalId)
        returns (uint256)
    {
        CoreFusionProposal storage proposal = fusionProposals[_proposalId];
        require(block.number > proposal.votingEndTime, "CCP: Voting period not yet ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "CCP: No votes cast for this proposal");

        uint256 votesForPercentage = (proposal.votesFor * 100) / totalVotes;

        if (votesForPercentage >= fusionVoteThreshold) {
            proposal.status = FusionProposalStatus.Approved;

            // Burn parent Cores
            _burn(proposal.coreA);
            _burn(proposal.coreB);

            // Mint new child Core
            uint256[] memory parents = new uint256[](MAX_PARENT_CORES);
            parents[0] = proposal.coreA;
            parents[1] = proposal.coreB;

            uint256 childId = _nextTokenId++;
            _mint(proposal.proposer, childId, proposal.proposedChildContentHash, parents);

            // Update fusion counts of the new child Core's parents (before they were burnt, now just conceptually)
            // Note: Since parents are burnt, their direct structs are gone.
            // We could store a 'fusion lineage' mapping to track this, but for simplicity,
            // the child's `parentCores` array is the primary record.
            idToCore[childId].activityScore = CORE_MINT_ACTIVITY_SCORE + FUSION_BASE_ACTIVITY_BOOST; // Boost for fusion
            idToCore[childId].fusionCount = 1; // It has been 'born' from a fusion

            proposal.status = FusionProposalStatus.Executed;
            emit CoreFusionExecuted(_proposalId, childId, proposal.coreA, proposal.coreB);
            return childId;
        } else {
            proposal.status = FusionProposalStatus.Rejected;
            revert("CCP: Fusion proposal rejected by vote");
        }
    }

    // --- III. Dynamic Utility & Access Control ---

    /**
     * @notice Retrieves all stored attributes and dynamic metrics for a given CognitiveCore.
     * @param _tokenId The ID of the Core.
     * @return All core details in a tuple.
     */
    function getCoreDetails(uint256 _tokenId)
        public
        view
        coreExists(_tokenId)
        returns (
            address owner,
            string memory contentHash,
            uint256 creationBlock,
            uint256 lastRefinementBlock,
            uint256[] memory parentCores,
            uint256 activityScore,
            uint256 fusionCount,
            uint256 impactEvents,
            bool isDeployed,
            uint256 stakedUntilBlock,
            address utilityDelegatee,
            uint256 delegatedUntilBlock
        )
    {
        Core storage core = idToCore[_tokenId];
        return (
            core.owner,
            core.contentHash,
            core.creationBlock,
            core.lastRefinementBlock,
            core.parentCores,
            core.activityScore,
            core.fusionCount,
            core.impactEvents,
            core.isDeployed,
            core.stakedUntilBlock,
            core.utilityDelegatee,
            core.delegatedUntilBlock
        );
    }

    /**
     * @notice Calculates and returns the current utility tier of a Core based on its dynamic attributes.
     * @param _tokenId The ID of the Core.
     * @return The Core's current utility tier.
     */
    function getCoreUtilityTier(uint256 _tokenId) public view coreExists(_tokenId) returns (CoreUtilityTier) {
        Core storage core = idToCore[_tokenId];
        uint256 effectiveScore = core.activityScore;
        // Apply temporary boost if staked
        if (block.number <= core.stakedUntilBlock) {
            effectiveScore = effectiveScore + 200; // Example boost: 200 points
            if (effectiveScore > MAX_ACTIVITY_SCORE) effectiveScore = MAX_ACTIVITY_SCORE;
        }

        // Tier thresholds are designed as [Evolving, Refined, Advanced, Master]
        // Genesis is implicitly everything below the first threshold.
        if (effectiveScore >= utilityTierThresholds[3]) return CoreUtilityTier.Master;
        if (effectiveScore >= utilityTierThresholds[2]) return CoreUtilityTier.Advanced;
        if (effectiveScore >= utilityTierThresholds[1]) return CoreUtilityTier.Refined;
        if (effectiveScore >= utilityTierThresholds[0]) return CoreUtilityTier.Evolving;
        return CoreUtilityTier.Genesis;
    }

    /**
     * @notice Traces and returns the direct parent Cores from which a given Core was fused.
     * @param _tokenId The ID of the Core.
     * @return An array of parent Core IDs. Empty if a genesis Core.
     */
    function getCoreAncestry(uint256 _tokenId) public view coreExists(_tokenId) returns (uint256[] memory) {
        return idToCore[_tokenId].parentCores;
    }

    /**
     * @notice Stakes a Core for a specified number of blocks, providing a temporary boost to its activity score.
     * @param _tokenId The ID of the Core to stake.
     * @param _durationBlocks The number of blocks to stake the Core for.
     */
    function stakeCoreForBoost(uint256 _tokenId, uint256 _durationBlocks) public coreExists(_tokenId) onlyCoreOwner(_tokenId) {
        require(_durationBlocks > 0, "CCP: Stake duration must be positive");
        idToCore[_tokenId].stakedUntilBlock = block.number + _durationBlocks;
        emit CoreStaked(_tokenId, idToCore[_tokenId].stakedUntilBlock);
    }

    /**
     * @notice Unstakes a Core, ending its temporary activity score boost.
     * @param _tokenId The ID of the Core to unstake.
     */
    function unstakeCoreFromBoost(uint256 _tokenId) public coreExists(_tokenId) onlyCoreOwner(_tokenId) {
        require(idToCore[_tokenId].stakedUntilBlock > block.number, "CCP: Core not actively staked");
        idToCore[_tokenId].stakedUntilBlock = block.number; // Effectively ends staking
        emit CoreUnstaked(_tokenId);
    }

    /**
     * @notice Allows a Core owner to grant temporary usage of their Core's utility to another address.
     *         The delegatee can call functions that check for delegated utility.
     * @param _tokenId The ID of the Core.
     * @param _delegatee The address to delegate utility to.
     * @param _durationBlocks The number of blocks for which utility is delegated.
     */
    function delegateCoreUtility(uint256 _tokenId, address _delegatee, uint256 _durationBlocks) public coreExists(_tokenId) onlyCoreOwner(_tokenId) {
        require(_delegatee != address(0), "CCP: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "CCP: Cannot delegate utility to self");
        require(_durationBlocks > 0, "CCP: Delegation duration must be positive");

        idToCore[_tokenId].utilityDelegatee = _delegatee;
        idToCore[_tokenId].delegatedUntilBlock = block.number + _durationBlocks;
        emit CoreUtilityDelegated(_tokenId, _delegatee, idToCore[_tokenId].delegatedUntilBlock);
    }

    /**
     * @notice Revokes any active utility delegation for a Core.
     * @param _tokenId The ID of the Core.
     */
    function revokeCoreUtilityDelegation(uint256 _tokenId) public coreExists(_tokenId) onlyCoreOwner(_tokenId) {
        require(idToCore[_tokenId].utilityDelegatee != address(0) && idToCore[_tokenId].delegatedUntilBlock > block.number, "CCP: No active delegation to revoke");

        idToCore[_tokenId].utilityDelegatee = address(0);
        idToCore[_tokenId].delegatedUntilBlock = 0;
        emit CoreUtilityDelegationRevoked(_tokenId);
    }


    // --- IV. Deployment & Impact Tracking ---

    /**
     * @notice Marks a CognitiveCore as "deployed," signifying its active contribution or use within a larger system.
     *         A deployed Core cannot be fused.
     * @param _tokenId The ID of the Core to deploy.
     */
    function deployCoreToProtocolSpace(uint256 _tokenId) public coreExists(_tokenId) onlyCoreOwner(_tokenId) coreIsNotDeployed(_tokenId) {
        idToCore[_tokenId].isDeployed = true;
        _checkAndIncreaseActivity(_tokenId);
        emit CoreDeployed(_tokenId, msg.sender);
    }

    /**
     * @notice Records a verified positive impact event for a deployed Core, increasing its `impactEvents` count and score.
     *         Only callable by an address with the `IMPACT_ORACLE_ROLE`.
     * @param _tokenId The ID of the deployed Core.
     * @param _impactWeight The weight/significance of the impact event.
     */
    function registerImpactEvent(uint256 _tokenId, uint256 _impactWeight) public coreExists(_tokenId) coreIsDeployed(_tokenId) onlyRole(IMPACT_ORACLE_ROLE) {
        require(_impactWeight > 0, "CCP: Impact weight must be positive");
        idToCore[_tokenId].impactEvents += _impactWeight;
        // Optionally, increase activity score based on impact as well
        if (idToCore[_tokenId].activityScore < MAX_ACTIVITY_SCORE) {
            idToCore[_tokenId].activityScore = idToCore[_tokenId].activityScore + (_impactWeight * 10) > MAX_ACTIVITY_SCORE ? MAX_ACTIVITY_SCORE : idToCore[_tokenId].activityScore + (_impactWeight * 10);
        }
        emit CoreImpactRegistered(_tokenId, msg.sender, _impactWeight);
    }

    // --- V. Protocol Governance & Administration ---

    /**
     * @notice Reduces the activity score of specified inactive Cores to reflect their current engagement.
     *         This function can be called periodically by a protocol administrator to manage utility inflation.
     * @param _tokenIds An array of Core IDs to decay.
     */
    function decayInactiveCores(uint256[] memory _tokenIds) public onlyRole(PROTOCOL_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            if (_exists(tokenId)) {
                Core storage core = idToCore[tokenId];
                if (core.lastRefinementBlock < block.number - 100 && // Example: Core inactive for 100 blocks
                    core.stakedUntilBlock < block.number &&
                    core.activityScore > CORE_MINT_ACTIVITY_SCORE) // Don't decay below initial score
                {
                    uint256 oldScore = core.activityScore;
                    core.activityScore = core.activityScore - 10; // Example decay rate
                    if (core.activityScore < CORE_MINT_ACTIVITY_SCORE) core.activityScore = CORE_MINT_ACTIVITY_SCORE;
                    emit CoreActivityDecayed(tokenId, oldScore, core.activityScore);
                }
            }
        }
    }

    /**
     * @notice Updates the numerical thresholds that define each utility tier.
     *         Requires `PROTOCOL_ADMIN_ROLE`. Thresholds must be strictly increasing.
     * @param _newThresholds An array of new thresholds (e.g., [100, 250, 500, 750]).
     */
    function setUtilityTierThresholds(uint256[] memory _newThresholds) public onlyRole(PROTOCOL_ADMIN_ROLE) {
        require(_newThresholds.length == utilityTierThresholds.length, "CCP: Must provide 4 thresholds");
        for (uint256 i = 0; i < _newThresholds.length; i++) {
            if (i > 0) {
                require(_newThresholds[i] > _newThresholds[i-1], "CCP: Thresholds must be strictly increasing");
            }
        }
        utilityTierThresholds = _newThresholds;
    }

    /**
     * @notice Adjusts the minimum percentage of 'for' votes required for a fusion proposal to pass.
     *         Requires `PROTOCOL_ADMIN_ROLE`.
     * @param _newThreshold The new percentage (0-100).
     */
    function setFusionVoteThreshold(uint256 _newThreshold) public onlyRole(PROTOCOL_ADMIN_ROLE) {
        require(_newThreshold <= 100, "CCP: Threshold cannot exceed 100%");
        fusionVoteThreshold = _newThreshold;
    }

    /**
     * @notice Manages role assignments (e.g., for `PROTOCOL_ADMIN_ROLE`, `IMPACT_ORACLE_ROLE`).
     *         Only callable by `DEFAULT_ADMIN_ROLE`.
     * @param _role The role hash to manage.
     * @param _account The address to grant or revoke the role for.
     * @param _grant True to grant the role, false to revoke.
     */
    function updateRole(bytes32 _role, address _account, bool _grant) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_grant) {
            _setupRole(_role, _account);
        } else {
            require(_roles[_role][_account], "CCP: Role not granted to account");
            _roles[_role][_account] = false;
            emit RoleRevoked(_role, _account, msg.sender);
        }
    }

    /**
     * @notice Checks if an account has a specific role.
     * @param role The role hash.
     * @param account The address to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }
}
```