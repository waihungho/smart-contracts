This smart contract, `SynergyCanvas`, is a **Decentralized Adaptive Intellectual Property & Collaborative Innovation Hub**. It aims to facilitate the creation, evolution, and ownership of complex digital assets through structured, tokenized collaboration, focusing on dynamic intellectual property rights and adaptive licensing. It goes beyond simple NFT minting by embedding collaboration logic, contribution tracking, flexible royalty/licensing models, and even project evolution (forking/merging) directly into the smart contract.

The contract leverages a multi-tiered NFT system to represent different stages and components of creative work, implements dynamic royalty distribution based on contributor weights, and incorporates governance mechanisms for disputes and project evolution.

---

**Outline:**

*   **I. Core Platform Management & Fees:** Basic administrative functions for the platform, including setting fees and withdrawing collected revenue.
*   **II. IdeaSeed NFT Lifecycle:** Management of initial concept tokens. These NFTs represent the nascent ideas or blueprints that can later evolve into full creative projects.
*   **III. CreativeProject NFT & Collaboration:** The central hub for evolving ideas into projects. This section handles project creation from an IdeaSeed, managing contributors, their roles, and project-specific funds.
*   **IV. Component NFT & Modular Contribution:** Individual units of work (e.g., code snippets, art assets, written text) that make up a project. These are tokenized to enable granular IP tracking and potential reuse.
*   **V. Dynamic Royalty & Licensing:** Adaptive mechanisms for revenue sharing among contributors based on adjustable weights, and for defining the overarching licensing terms of a project.
*   **VI. Dispute Resolution & Governance:** Mechanisms for resolving conflicts over contributions or ownership, and for decision-making regarding project changes via a simplified voting system.
*   **VII. Project Evolution & Reputation:** Features for allowing projects to branch off (fork), proposing mergers between projects, and tracking the reputation of individual contributors.
*   **VIII. Funding:** Mechanism for external parties to fund active creative projects.

---

**Function Summary:**

1.  `constructor()`: Initializes the platform with an admin address and default platform fees.
2.  `updateAdmin(address newAdmin)`: Allows the current platform admin to transfer administrative control to a new address.
3.  `setPlatformFee(uint256 newFeeBps)`: Sets the platform's royalty percentage (in basis points) applied to project revenues.
4.  `withdrawPlatformFees()`: Enables the platform admin to withdraw accumulated fees collected by the platform.
5.  `mintIdeaSeed(string memory _title, string memory _description, string[] memory _initialTags)`: Mints a new `IdeaSeedNFT` to represent an initial concept or idea, owned by the minter.
6.  `updateIdeaSeedMetadata(uint256 _seedId, string memory _newTitle, string memory _newDescription)`: Allows the owner of an `IdeaSeedNFT` to update its title and description, provided it hasn't been locked into a project.
7.  `proposeIdeaSeedTag(uint256 _seedId, string memory _tag)`: Community members can propose new tags for an `IdeaSeedNFT` to enhance discoverability.
8.  `voteOnIdeaSeedTag(uint256 _seedId, string memory _tag, bool _approve)`: Casts a vote for or against a proposed tag for an `IdeaSeedNFT`. Approved tags (by a simple majority) are added to the seed.
9.  `createCreativeProjectFromSeed(uint256 _seedId, address[] memory _initialContributors, string[] memory _initialRoles, uint256[] memory _initialRoyaltyWeights, string memory _projectLicenseURI)`: Initializes a `CreativeProjectNFT` from an existing `IdeaSeedNFT`. This defines initial collaborators, their roles, dynamic royalty splits, and the project's initial licensing terms. The `IdeaSeedNFT` is locked upon project creation.
10. `addProjectContributor(uint256 _projectId, address _contributor, string memory _role, uint256 _initialRoyaltyWeight)`: Allows the project admin to add a new contributor to an active project with a specific role and an initial royalty weight.
11. `removeProjectContributor(uint256 _projectId, address _contributor)`: Enables the project admin to remove a contributor from a project, adjusting the total royalty weight accordingly.
12. `updateContributorRole(uint256 _projectId, address _contributor, string memory _newRole)`: Changes an existing contributor's role within a project.
13. `mintComponentNFT(uint256 _projectId, string memory _componentType, string memory _ipfsHash, string memory _metadataURI)`: A project contributor can mint a `ComponentNFT` (e.g., a code module, art asset, text block) and link it to their `CreativeProjectNFT`. This records granular contributions on-chain.
14. `updateComponentMetadata(uint256 _componentId, string memory _newMetadataURI)`: Allows the owner of a `ComponentNFT` to update its associated metadata URI.
15. `proposeDynamicRoyaltyWeightChange(uint256 _projectId, address _contributor, uint256 _newWeight)`: The project admin proposes an adjustment to a specific contributor's royalty weight for an active project.
16. `voteOnRoyaltyWeightChange(uint256 _proposalId, bool _approve)`: Project contributors vote on a proposed royalty weight change. If approved by a majority, the contributor's weight is updated.
17. `distributeProjectRoyalties(uint256 _projectId)`: Triggers the distribution of accumulated revenue for a project to all active contributors based on their current dynamic royalty weights, after deducting platform fees.
18. `updateProjectLicensingURI(uint256 _projectId, string memory _newLicenseURI)`: The project admin updates the URI pointing to the project's overall licensing terms, allowing for adaptive IP management.
19. `initiateProjectFork(uint256 _projectId, string memory _forkTitle, string memory _forkDescription, string memory _forkLicenseURI)`: Allows a project contributor to "fork" an existing project, creating a new, independent `CreativeProjectNFT` from its current state, useful for experimental branches or new directions.
20. `proposeProjectMerge(uint256 _projectIdA, uint256 _projectIdB, string memory _mergeRationale)`: Allows the admin of one project to propose merging it with another project, requiring consensus from both project communities.
21. `voteOnProjectMerge(uint256 _mergeProposalId, bool _approve)`: Contributors from both projects involved in a merge proposal can cast their votes.
22. `awardContributorReputation(address _contributor, uint256 _projectId, uint256 _points)`: (Platform admin or DAO-voted) awards reputation points to a contributor for successful project participation or outstanding work.
23. `penalizeContributorReputation(address _contributor, uint256 _projectId, uint256 _points)`: (Platform admin or DAO-voted) penalizes a contributor's reputation points for misconduct or failed contributions.
24. `disputeContribution(uint256 _projectId, uint256 _componentId, string memory _reason)`: Allows a project contributor to formally dispute aspects (e.g., ownership, value, quality) of a `ComponentNFT` or contribution within a project.
25. `resolveDispute(uint256 _disputeId, address _winner, uint256 _adjustedWeight, uint256 _componentIdToAdjust)`: (Platform admin or appointed arbitrator) resolves a dispute, potentially adjusting contributor royalty weights or transferring `ComponentNFT` ownership.
26. `fundProjectDevelopment(uint256 _projectId)`: Allows any external party or contributor to send native tokens (e.g., ETH) to a project's dedicated fund, which will be accumulated for future royalty distributions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For basic arithmetic operations with overflow/underflow checks
import "@openzeppelin/contracts/utils/Context.sol"; // Base for msg.sender, msg.value etc.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Prevents re-entrancy attacks

// Outline:
// I. Core Platform Management & Fees: Basic administrative functions for the platform.
// II. IdeaSeed NFT Lifecycle: Management of initial concept tokens.
// III. CreativeProject NFT & Collaboration: The central hub for evolving ideas, managing contributors, roles, and project funds.
// IV. Component NFT & Modular Contribution: Individual units of work that make up a project, enabling granular IP tracking.
// V. Dynamic Royalty & Licensing: Adaptive mechanisms for revenue sharing and intellectual property rights adjustments.
// VI. Dispute Resolution & Governance: Mechanisms for resolving conflicts and evolving project rules via voting.
// VII. Project Evolution & Reputation: Features for branching projects, proposing mergers, and tracking contributor performance.
// VIII. Funding: Mechanism for external parties to fund active creative projects.

// Function Summary:
// 1.  constructor(): Initializes the platform with an admin address and initial fees.
// 2.  updateAdmin(address newAdmin): Allows the current admin to transfer administrative control.
// 3.  setPlatformFee(uint256 newFeeBps): Sets the platform's royalty percentage (in basis points) on project revenues.
// 4.  withdrawPlatformFees(): Allows the platform admin to withdraw accumulated fees.
// 5.  mintIdeaSeed(string memory _title, string memory _description, string[] memory _initialTags): Mints a new IdeaSeedNFT representing a nascent concept.
// 6.  updateIdeaSeedMetadata(uint256 _seedId, string memory _newTitle, string memory _newDescription): Allows the IdeaSeed owner to refine its description.
// 7.  proposeIdeaSeedTag(uint256 _seedId, string memory _tag): Community members can suggest new tags for an IdeaSeed.
// 8.  voteOnIdeaSeedTag(uint256 _seedId, string memory _tag, bool _approve): Casts a vote for or against a proposed IdeaSeed tag.
// 9.  createCreativeProjectFromSeed(uint256 _seedId, address[] memory _initialContributors, string[] memory _initialRoles, uint256[] memory _initialRoyaltyWeights, string memory _projectLicenseURI): Initializes a CreativeProjectNFT from an IdeaSeed, defining initial collaborators, roles, royalty splits, and an initial license. Locks the IdeaSeed.
// 10. addProjectContributor(uint256 _projectId, address _contributor, string memory _role, uint256 _initialRoyaltyWeight): Adds a new contributor to an existing project with a specified role and initial royalty weight.
// 11. removeProjectContributor(uint256 _projectId, address _contributor): Removes a contributor from a project.
// 12. updateContributorRole(uint256 _projectId, address _contributor, string memory _newRole): Changes an existing contributor's role within a project.
// 13. mintComponentNFT(uint256 _projectId, string memory _componentType, string memory _ipfsHash, string memory _metadataURI): A contributor mints a ComponentNFT (e.g., code, art, text) and links it to a CreativeProjectNFT.
// 14. updateComponentMetadata(uint256 _componentId, string memory _newMetadataURI): Allows the owner of a ComponentNFT to update its associated metadata.
// 15. proposeDynamicRoyaltyWeightChange(uint256 _projectId, address _contributor, uint256 _newWeight): A project owner proposes an adjustment to a contributor's royalty weight.
// 16. voteOnRoyaltyWeightChange(uint256 _projectId, uint256 _proposalId, bool _approve): Project contributors vote on a proposed royalty weight change.
// 17. distributeProjectRoyalties(uint256 _projectId): Triggers the distribution of accumulated revenue for a project to contributors based on current weights and applies platform fees.
// 18. updateProjectLicensingURI(uint256 _projectId, string memory _newLicenseURI): Project admin updates the URI pointing to the project's overall licensing terms.
// 19. initiateProjectFork(uint256 _projectId, string memory _forkTitle, string memory _forkDescription, string memory _forkLicenseURI): Allows a portion of project contributors to "fork" a project, creating a new independent CreativeProjectNFT from the current state.
// 20. proposeProjectMerge(uint256 _projectIdA, uint256 _projectIdB, string memory _mergeRationale): Allows two CreativeProjectNFTs to propose a merger, requiring contributor consensus.
// 21. voteOnProjectMerge(uint256 _mergeProposalId, bool _approve): Contributors from both projects vote on a merge proposal.
// 22. awardContributorReputation(address _contributor, uint256 _projectId, uint256 _points): Project admins or a DAO vote to award reputation points for successful contributions.
// 23. penalizeContributorReputation(address _contributor, uint256 _projectId, uint256 _points): Project admins or a DAO vote to penalize reputation for misconduct.
// 24. disputeContribution(uint256 _projectId, uint256 _componentId, string memory _reason): Allows a contributor to formally dispute aspects of another component or contribution.
// 25. resolveDispute(uint256 _disputeId, address _winner, uint256 _adjustedWeight, uint256 _componentIdToAdjust): An appointed arbitrator or DAO resolves a dispute, potentially adjusting contribution weights or component ownership.
// 26. fundProjectDevelopment(uint256 _projectId): Allows external parties or contributors to send ETH/tokens to a project's dedicated fund.

contract SynergyCanvas is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Events ---
    event AdminUpdated(address indexed newAdmin);
    event PlatformFeeSet(uint256 newFeeBps);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);

    event IdeaSeedMinted(uint256 indexed seedId, address indexed owner, string title);
    event IdeaSeedMetadataUpdated(uint256 indexed seedId, string newTitle, string newDescription);
    event IdeaSeedTagProposed(uint256 indexed seedId, address indexed proposer, string tag);
    event IdeaSeedTagVoted(uint256 indexed seedId, address indexed voter, string tag, bool approved);

    event CreativeProjectMinted(uint256 indexed projectId, uint256 indexed seedId, address indexed creator, string title);
    event ContributorAdded(uint256 indexed projectId, address indexed contributor, string role);
    event ContributorRemoved(uint256 indexed projectId, address indexed contributor);
    event ContributorRoleUpdated(uint256 indexed projectId, address indexed contributor, string newRole);

    event ComponentMinted(uint256 indexed componentId, uint256 indexed projectId, address indexed contributor, string componentType, string ipfsHash);
    event ComponentMetadataUpdated(uint256 indexed componentId, string newMetadataURI);

    event RoyaltyWeightChangeProposed(uint256 indexed projectId, uint256 indexed proposalId, address indexed contributor, uint256 newWeight);
    event RoyaltyWeightChangeVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event RoyaltyWeightsUpdated(uint256 indexed projectId);
    event ProjectRoyaltiesDistributed(uint256 indexed projectId, uint256 totalAmount, uint256 platformFeeAmount);

    event ProjectLicensingURIUpdated(uint256 indexed projectId, string newLicenseURI);
    event ProjectForked(uint256 indexed originalProjectId, uint256 indexed newProjectId, address indexed forker);
    event ProjectMergeProposed(uint256 indexed mergeProposalId, uint256 indexed projectIdA, uint256 indexed projectIdB, address indexed proposer);
    event ProjectMergeVoted(uint256 indexed mergeProposalId, address indexed voter, bool approved);
    event ProjectMerged(uint256 indexed mergeProposalId, uint256 indexed finalProjectId);

    event ContributorReputationAwarded(address indexed contributor, uint256 indexed projectId, uint256 points);
    event ContributorReputationPenalized(address indexed contributor, uint256 indexed projectId, uint256 points);

    event ContributionDisputed(uint256 indexed disputeId, uint256 indexed projectId, uint256 indexed componentId, address indexed disputer);
    event DisputeResolved(uint256 indexed disputeId, address indexed resolver, address indexed winner, uint256 adjustedWeight);

    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);

    // --- State Variables ---
    address public platformAdmin;
    uint256 public platformFeeBps; // Basis points (e.g., 100 for 1%)
    uint256 public constant MAX_PLATFORM_FEE_BPS = 1000; // Max 10%
    uint256 public platformCollectedFees;

    // NFT Counters
    Counters.Counter private m_ideaSeedIdCounter;
    Counters.Counter private m_creativeProjectIdCounter;
    Counters.Counter private m_componentIdCounter;
    Counters.Counter private m_royaltyProposalIdCounter;
    Counters.Counter private m_mergeProposalIdCounter;
    Counters.Counter private m_disputeIdCounter;

    // --- Structs ---
    struct IdeaSeed {
        address owner;
        string title;
        string description;
        mapping(string => uint256) tagVotes; // tag => vote count
        mapping(address => mapping(string => bool)) hasVotedOnTag; // voter => tag => bool
        string[] tags; // Officially approved tags
        bool isLocked; // Locked when converted to a CreativeProject
    }

    struct Contributor {
        string role;
        uint256 royaltyWeight; // In basis points (e.g., 1000 for 10%)
        mapping(uint256 => bool) hasVotedOnRoyaltyProposal; // proposalId => bool
        mapping(uint256 => bool) hasVotedOnMergeProposal; // mergeProposalId => bool
    }

    struct RoyaltyWeightProposal {
        address contributor;
        uint256 newWeight;
        uint256 projectId;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    struct CreativeProject {
        address owner; // The primary owner/admin of the project (can be changed by vote)
        string title;
        string description;
        string licenseURI; // URI to the project's licensing terms
        uint256 ideaSeedId; // The IdeaSeed it originated from
        mapping(address => Contributor) contributors;
        address[] contributorAddresses; // To iterate contributors
        uint256 totalRoyaltyWeight; // Sum of all active contributor weights for distribution
        uint256 accumulatedFunds; // ETH / native token
        bool active; // Can be marked inactive if abandoned or merged
    }

    struct Component {
        uint256 projectId;
        address owner; // The contributor who minted it
        string componentType; // e.g., "code", "art", "text", "design"
        string ipfsHash; // Hash of the actual component data
        string metadataURI; // URI to additional metadata (e.g., version, detailed description)
        bool disputable; // If true, can be disputed (e.g. ownership, value)
    }

    struct MergeProposal {
        uint256 projectIdA;
        uint256 projectIdB;
        address proposer;
        string rationale;
        uint256 votesForA; // Votes from ProjectA contributors
        uint256 votesForB; // Votes from ProjectB contributors
        uint256 votesAgainstA;
        uint256 votesAgainstB;
        bool executed;
    }

    struct Dispute {
        uint256 projectId;
        uint256 componentId;
        address disputer;
        address resolver; // Admin or appointed arbitrator
        string reason;
        address winner; // Address of the party whose claim was validated
        uint256 adjustedWeight; // If a royalty weight was adjusted
        bool resolved;
    }

    // --- Mappings ---
    mapping(uint256 => IdeaSeed) public s_ideaSeeds;
    mapping(uint256 => CreativeProject) public s_creativeProjects;
    mapping(uint256 => Component) public s_components;
    mapping(uint256 => RoyaltyWeightProposal) public s_royaltyProposals;
    mapping(uint256 => MergeProposal) public s_mergeProposals;
    mapping(uint256 => Dispute) public s_disputes;
    mapping(address => mapping(uint256 => uint256)) public s_contributorReputation; // contributor => projectId => score

    // --- NFT Contracts (internal, no direct ERC721 interface exposed beyond token ownership) ---
    // These are simple ERC721 contracts for tokenizing each layer of IP.
    // In a production environment, they might have more advanced features (e.g., tokenURI, approval system).
    ERC721 private m_ideaSeedNFT;
    ERC721 private m_creativeProjectNFT;
    ERC721 private m_componentNFT;

    // --- Modifiers ---
    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "SynergyCanvas: Only platform admin can call this function");
        _;
    }

    modifier onlyProjectAdmin(uint256 _projectId) {
        require(s_creativeProjects[_projectId].owner == msg.sender, "SynergyCanvas: Only project admin can call this function");
        _;
    }

    modifier onlyProjectContributor(uint256 _projectId) {
        require(s_creativeProjects[_projectId].contributors[msg.sender].royaltyWeight > 0, "SynergyCanvas: Only project contributor can call this function");
        _;
    }

    constructor() Ownable(msg.sender) {
        platformAdmin = msg.sender;
        platformFeeBps = 200; // 2% initial fee (200 out of 10000 basis points)
        platformCollectedFees = 0;

        m_ideaSeedNFT = new ERC721("SynergyCanvas IdeaSeed", "SCSEED");
        m_creativeProjectNFT = new ERC721("SynergyCanvas CreativeProject", "SCCP");
        m_componentNFT = new ERC721("SynergyCanvas Component", "SCCOMP");
    }

    // I. Core Platform Management & Fees
    function updateAdmin(address _newAdmin) external onlyPlatformAdmin {
        require(_newAdmin != address(0), "SynergyCanvas: New admin cannot be zero address");
        platformAdmin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    function setPlatformFee(uint256 _newFeeBps) external onlyPlatformAdmin {
        require(_newFeeBps <= MAX_PLATFORM_FEE_BPS, "SynergyCanvas: Fee exceeds maximum limit (10%)");
        platformFeeBps = _newFeeBps;
        emit PlatformFeeSet(_newFeeBps);
    }

    function withdrawPlatformFees() external onlyPlatformAdmin nonReentrant {
        uint256 amount = platformCollectedFees;
        require(amount > 0, "SynergyCanvas: No fees to withdraw");
        platformCollectedFees = 0;
        (bool success, ) = payable(platformAdmin).call{value: amount}("");
        require(success, "SynergyCanvas: Failed to withdraw platform fees");
        emit PlatformFeesWithdrawn(platformAdmin, amount);
    }

    // II. IdeaSeed NFT Lifecycle
    function mintIdeaSeed(string memory _title, string memory _description, string[] memory _initialTags) external nonReentrant {
        m_ideaSeedIdCounter.increment();
        uint256 seedId = m_ideaSeedIdCounter.current();

        s_ideaSeeds[seedId].owner = msg.sender;
        s_ideaSeeds[seedId].title = _title;
        s_ideaSeeds[seedId].description = _description;
        s_ideaSeeds[seedId].tags = _initialTags;
        s_ideaSeeds[seedId].isLocked = false;

        m_ideaSeedNFT.safeMint(msg.sender, seedId);
        emit IdeaSeedMinted(seedId, msg.sender, _title);
    }

    function updateIdeaSeedMetadata(uint256 _seedId, string memory _newTitle, string memory _newDescription) external {
        require(m_ideaSeedNFT.ownerOf(_seedId) == msg.sender, "SynergyCanvas: Not the owner of this IdeaSeed");
        require(!s_ideaSeeds[_seedId].isLocked, "SynergyCanvas: IdeaSeed is locked as it's part of a project");

        s_ideaSeeds[_seedId].title = _newTitle;
        s_ideaSeeds[_seedId].description = _newDescription;
        emit IdeaSeedMetadataUpdated(_seedId, _newTitle, _newDescription);
    }

    function proposeIdeaSeedTag(uint256 _seedId, string memory _tag) external {
        require(m_ideaSeedIdCounter.current() >= _seedId && _seedId > 0, "SynergyCanvas: Invalid IdeaSeed ID");
        require(bytes(_tag).length > 0, "SynergyCanvas: Tag cannot be empty");

        // Simple check to prevent duplicate tag proposal for brevity
        // In a real system, you might want to track this more robustly, possibly with an array of proposed tags
        s_ideaSeeds[_seedId].tagVotes[_tag] = s_ideaSeeds[_seedId].tagVotes[_tag].add(1);
        emit IdeaSeedTagProposed(_seedId, msg.sender, _tag);
    }

    function voteOnIdeaSeedTag(uint256 _seedId, string memory _tag, bool _approve) external {
        require(m_ideaSeedIdCounter.current() >= _seedId && _seedId > 0, "SynergyCanvas: Invalid IdeaSeed ID");
        require(bytes(_tag).length > 0, "SynergyCanvas: Tag cannot be empty");
        require(!s_ideaSeeds[_seedId].hasVotedOnTag[msg.sender][_tag], "SynergyCanvas: Already voted on this tag");

        s_ideaSeeds[_seedId].hasVotedOnTag[msg.sender][_tag] = true;

        if (_approve) {
            s_ideaSeeds[_seedId].tagVotes[_tag] = s_ideaSeeds[_seedId].tagVotes[_tag].add(1);
            // Simple logic: if a tag gets 3 votes, it's added. Can be more complex.
            if (s_ideaSeeds[_seedId].tagVotes[_tag] >= 3) {
                bool found = false;
                for(uint i = 0; i < s_ideaSeeds[_seedId].tags.length; i++) {
                    if (keccak256(abi.encodePacked(s_ideaSeeds[_seedId].tags[i])) == keccak256(abi.encodePacked(_tag))) {
                        found = true;
                        break;
                    }
                }
                if (!found) { // Only add if not already an official tag
                    s_ideaSeeds[_seedId].tags.push(_tag);
                }
            }
        } else {
            // Negative votes are recorded but don't actively decrease the count in this simple model.
            // A more complex system might allow negative votes to reduce a tag's score.
        }
        emit IdeaSeedTagVoted(_seedId, msg.sender, _tag, _approve);
    }

    // III. CreativeProject NFT & Collaboration
    function createCreativeProjectFromSeed(
        uint256 _seedId,
        address[] memory _initialContributors,
        string[] memory _initialRoles,
        uint256[] memory _initialRoyaltyWeights,
        string memory _projectLicenseURI
    ) external nonReentrant {
        require(m_ideaSeedNFT.ownerOf(_seedId) == msg.sender, "SynergyCanvas: Not the owner of the IdeaSeed");
        require(!s_ideaSeeds[_seedId].isLocked, "SynergyCanvas: IdeaSeed is already locked or used");
        require(_initialContributors.length == _initialRoles.length && _initialContributors.length == _initialRoyaltyWeights.length, "SynergyCanvas: Mismatched array lengths for contributors");
        require(_initialContributors.length > 0, "SynergyCanvas: Must have at least one initial contributor");

        m_creativeProjectIdCounter.increment();
        uint256 projectId = m_creativeProjectIdCounter.current();

        CreativeProject storage project = s_creativeProjects[projectId];
        project.owner = msg.sender; // Initial project admin is the creator
        project.title = s_ideaSeeds[_seedId].title;
        project.description = s_ideaSeeds[_seedId].description;
        project.licenseURI = _projectLicenseURI;
        project.ideaSeedId = _seedId;
        project.active = true;

        uint256 totalWeightSum = 0;
        for (uint i = 0; i < _initialContributors.length; i++) {
            require(_initialContributors[i] != address(0), "SynergyCanvas: Contributor cannot be zero address");
            require(project.contributors[_initialContributors[i]].royaltyWeight == 0, "SynergyCanvas: Duplicate initial contributor detected");

            project.contributors[_initialContributors[i]].role = _initialRoles[i];
            project.contributors[_initialContributors[i]].royaltyWeight = _initialRoyaltyWeights[i];
            project.contributorAddresses.push(_initialContributors[i]);
            totalWeightSum = totalWeightSum.add(_initialRoyaltyWeights[i]);
        }
        project.totalRoyaltyWeight = totalWeightSum;
        require(project.totalRoyaltyWeight > 0, "SynergyCanvas: Total royalty weight must be greater than zero");

        s_ideaSeeds[_seedId].isLocked = true; // Mark IdeaSeed as used/locked
        m_creativeProjectNFT.safeMint(msg.sender, projectId);
        // IdeaSeed NFT ownership could be transferred to the project's contract address for official "locking" or burned.
        // For simplicity, we just mark it as locked.

        emit CreativeProjectMinted(projectId, _seedId, msg.sender, project.title);
        for (uint i = 0; i < _initialContributors.length; i++) {
             emit ContributorAdded(projectId, _initialContributors[i], _initialRoles[i]);
        }
    }

    function addProjectContributor(uint256 _projectId, address _contributor, string memory _role, uint256 _initialRoyaltyWeight) external onlyProjectAdmin(_projectId) {
        CreativeProject storage project = s_creativeProjects[_projectId];
        require(project.active, "SynergyCanvas: Project is inactive");
        require(_contributor != address(0), "SynergyCanvas: Contributor cannot be zero address");
        require(project.contributors[_contributor].royaltyWeight == 0, "SynergyCanvas: Contributor already exists in this project");
        require(_initialRoyaltyWeight > 0, "SynergyCanvas: Initial royalty weight must be positive");

        project.contributors[_contributor].role = _role;
        project.contributors[_contributor].royaltyWeight = _initialRoyaltyWeight;
        project.contributorAddresses.push(_contributor);
        project.totalRoyaltyWeight = project.totalRoyaltyWeight.add(_initialRoyaltyWeight);

        emit ContributorAdded(_projectId, _contributor, _role);
    }

    function removeProjectContributor(uint256 _projectId, address _contributor) external onlyProjectAdmin(_projectId) {
        CreativeProject storage project = s_creativeProjects[_projectId];
        require(project.active, "SynergyCanvas: Project is inactive");
        require(project.contributors[_contributor].royaltyWeight > 0, "SynergyCanvas: Contributor does not exist in this project");
        require(_contributor != project.owner, "SynergyCanvas: Cannot remove project owner directly, transfer ownership first.");

        project.totalRoyaltyWeight = project.totalRoyaltyWeight.sub(project.contributors[_contributor].royaltyWeight);
        delete project.contributors[_contributor];

        // Remove from dynamic array (inefficient for large arrays but simple for example)
        for (uint i = 0; i < project.contributorAddresses.length; i++) {
            if (project.contributorAddresses[i] == _contributor) {
                project.contributorAddresses[i] = project.contributorAddresses[project.contributorAddresses.length - 1];
                project.contributorAddresses.pop();
                break;
            }
        }
        emit ContributorRemoved(_projectId, _contributor);
    }

    function updateContributorRole(uint256 _projectId, address _contributor, string memory _newRole) external onlyProjectAdmin(_projectId) {
        CreativeProject storage project = s_creativeProjects[_projectId];
        require(project.active, "SynergyCanvas: Project is inactive");
        require(project.contributors[_contributor].royaltyWeight > 0, "SynergyCanvas: Contributor does not exist in this project");

        project.contributors[_contributor].role = _newRole;
        emit ContributorRoleUpdated(_projectId, _contributor, _newRole);
    }

    // IV. Component NFT & Modular Contribution
    function mintComponentNFT(uint256 _projectId, string memory _componentType, string memory _ipfsHash, string memory _metadataURI) external onlyProjectContributor(_projectId) nonReentrant {
        CreativeProject storage project = s_creativeProjects[_projectId];
        require(project.active, "SynergyCanvas: Project is inactive");

        m_componentIdCounter.increment();
        uint256 componentId = m_componentIdCounter.current();

        Component storage component = s_components[componentId];
        component.projectId = _projectId;
        component.owner = msg.sender;
        component.componentType = _componentType;
        component.ipfsHash = _ipfsHash;
        component.metadataURI = _metadataURI;
        component.disputable = true; // Components are disputable by default

        m_componentNFT.safeMint(msg.sender, componentId);
        emit ComponentMinted(componentId, _projectId, msg.sender, _componentType, _ipfsHash);
    }

    function updateComponentMetadata(uint256 _componentId, string memory _newMetadataURI) external {
        require(m_componentNFT.ownerOf(_componentId) == msg.sender, "SynergyCanvas: Not the owner of this Component NFT");
        s_components[_componentId].metadataURI = _newMetadataURI;
        emit ComponentMetadataUpdated(_componentId, _newMetadataURI);
    }

    // V. Dynamic Royalty & Licensing
    function proposeDynamicRoyaltyWeightChange(uint256 _projectId, address _contributor, uint256 _newWeight) external onlyProjectAdmin(_projectId) {
        CreativeProject storage project = s_creativeProjects[_projectId];
        require(project.active, "SynergyCanvas: Project is inactive");
        require(project.contributors[_contributor].royaltyWeight > 0, "SynergyCanvas: Contributor does not exist in this project");

        m_royaltyProposalIdCounter.increment();
        uint256 proposalId = m_royaltyProposalIdCounter.current();

        s_royaltyProposals[proposalId] = RoyaltyWeightProposal({
            contributor: _contributor,
            newWeight: _newWeight,
            projectId: _projectId,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        emit RoyaltyWeightChangeProposed(_projectId, proposalId, _contributor, _newWeight);
    }

    function voteOnRoyaltyWeightChange(uint256 _proposalId, bool _approve) external onlyProjectContributor(s_royaltyProposals[_proposalId].projectId) {
        RoyaltyWeightProposal storage proposal = s_royaltyProposals[_proposalId];
        require(!proposal.executed, "SynergyCanvas: Proposal already executed");
        require(s_creativeProjects[proposal.projectId].active, "SynergyCanvas: Project is inactive");
        require(!s_creativeProjects[proposal.projectId].contributors[msg.sender].hasVotedOnRoyaltyProposal[_proposalId], "SynergyCanvas: Already voted on this proposal");

        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        s_creativeProjects[proposal.projectId].contributors[msg.sender].hasVotedOnRoyaltyProposal[_proposalId] = true;
        emit RoyaltyWeightChangeVoted(_proposalId, msg.sender, _approve);

        // Simple majority vote for execution (e.g., 50% + 1 of current project contributors)
        // For production, consider a more robust voting system (e.g., quorum, voting power based on existing weight)
        uint256 totalContributors = s_creativeProjects[proposal.projectId].contributorAddresses.length;
        if (totalContributors == 0) return; // No contributors to vote

        if (proposal.votesFor > (totalContributors / 2) && totalContributors > 1) { // Requires at least 2 contributors to vote
            s_creativeProjects[proposal.projectId].totalRoyaltyWeight = s_creativeProjects[proposal.projectId].totalRoyaltyWeight
                .sub(s_creativeProjects[proposal.projectId].contributors[proposal.contributor].royaltyWeight)
                .add(proposal.newWeight);
            s_creativeProjects[proposal.projectId].contributors[proposal.contributor].royaltyWeight = proposal.newWeight;
            proposal.executed = true;
            emit RoyaltyWeightsUpdated(proposal.projectId);
        } else if (proposal.votesAgainst >= (totalContributors / 2) && totalContributors > 1) { // Simple majority against
            proposal.executed = true; // Mark as executed but not approved
        }
    }

    function distributeProjectRoyalties(uint256 _projectId) external nonReentrant {
        CreativeProject storage project = s_creativeProjects[_projectId];
        require(project.active, "SynergyCanvas: Project is inactive");
        require(project.accumulatedFunds > 0, "SynergyCanvas: No accumulated funds for this project");
        require(project.totalRoyaltyWeight > 0, "SynergyCanvas: Project has no active contributors to distribute to");

        uint256 totalAmount = project.accumulatedFunds;
        uint256 feeAmount = totalAmount.mul(platformFeeBps).div(10000); // 10000 for basis points conversion
        uint256 distributableAmount = totalAmount.sub(feeAmount);

        project.accumulatedFunds = 0;
        platformCollectedFees = platformCollectedFees.add(feeAmount);

        for (uint i = 0; i < project.contributorAddresses.length; i++) {
            address contributorAddress = project.contributorAddresses[i];
            uint256 contributorWeight = project.contributors[contributorAddress].royaltyWeight;
            if (contributorWeight > 0) {
                uint256 share = distributableAmount.mul(contributorWeight).div(project.totalRoyaltyWeight);
                if (share > 0) {
                    (bool success, ) = payable(contributorAddress).call{value: share}("");
                    require(success, "SynergyCanvas: Failed to send royalty to contributor"); // Should not revert entire tx
                    // Potentially track failed transfers to allow manual retry or refund
                }
            }
        }
        emit ProjectRoyaltiesDistributed(_projectId, totalAmount, feeAmount);
    }

    function updateProjectLicensingURI(uint256 _projectId, string memory _newLicenseURI) external onlyProjectAdmin(_projectId) {
        CreativeProject storage project = s_creativeProjects[_projectId];
        require(project.active, "SynergyCanvas: Project is inactive");
        project.licenseURI = _newLicenseURI;
        emit ProjectLicensingURIUpdated(_projectId, _newLicenseURI);
    }

    // VI. Dispute Resolution & Governance
    function disputeContribution(uint256 _projectId, uint256 _componentId, string memory _reason) external onlyProjectContributor(_projectId) {
        require(s_creativeProjects[_projectId].active, "SynergyCanvas: Project is inactive");
        require(s_components[_componentId].projectId == _projectId, "SynergyCanvas: Component does not belong to this project");
        require(s_components[_componentId].disputable, "SynergyCanvas: Component is not disputable");
        require(bytes(_reason).length > 0, "SynergyCanvas: Dispute reason cannot be empty");

        m_disputeIdCounter.increment();
        uint256 disputeId = m_disputeIdCounter.current();

        s_disputes[disputeId] = Dispute({
            projectId: _projectId,
            componentId: _componentId,
            disputer: msg.sender,
            resolver: address(0), // To be assigned or voted on in a more complex system
            reason: _reason,
            winner: address(0),
            adjustedWeight: 0,
            resolved: false
        });
        emit ContributionDisputed(disputeId, _projectId, _componentId, msg.sender);
    }

    function resolveDispute(uint256 _disputeId, address _winner, uint256 _adjustedWeight, uint256 _componentIdToAdjust) external onlyPlatformAdmin {
        // In a real system, this would involve complex arbitration logic or DAO voting.
        // For simplicity, platform admin resolves disputes directly here.
        Dispute storage dispute = s_disputes[_disputeId];
        require(!dispute.resolved, "SynergyCanvas: Dispute already resolved");
        require(_winner != address(0), "SynergyCanvas: Winner cannot be zero address");

        dispute.resolver = msg.sender;
        dispute.winner = _winner;
        dispute.resolved = true;
        dispute.adjustedWeight = _adjustedWeight;

        // Example action: if dispute involves adjusting royalty weight of a contributor
        if (_adjustedWeight > 0 && s_creativeProjects[dispute.projectId].contributors[_winner].royaltyWeight > 0) {
             s_creativeProjects[dispute.projectId].totalRoyaltyWeight = s_creativeProjects[dispute.projectId].totalRoyaltyWeight
                .sub(s_creativeProjects[dispute.projectId].contributors[_winner].royaltyWeight)
                .add(_adjustedWeight);
            s_creativeProjects[dispute.projectId].contributors[_winner].royaltyWeight = _adjustedWeight;
            emit RoyaltyWeightsUpdated(dispute.projectId);
        }
        // Example action: if dispute involves component ownership transfer
        if (_componentIdToAdjust > 0 && m_componentNFT.ownerOf(_componentIdToAdjust) != _winner) {
            // Additional checks might be needed to ensure _winner is a valid project contributor, etc.
            m_componentNFT.transferFrom(m_componentNFT.ownerOf(_componentIdToAdjust), _winner, _componentIdToAdjust);
        }

        emit DisputeResolved(_disputeId, msg.sender, _winner, _adjustedWeight);
    }

    // VII. Project Evolution & Reputation
    function initiateProjectFork(uint256 _projectId, string memory _forkTitle, string memory _forkDescription, string memory _forkLicenseURI) external onlyProjectContributor(_projectId) nonReentrant {
        CreativeProject storage originalProject = s_creativeProjects[_projectId];
        require(originalProject.active, "SynergyCanvas: Original project is inactive");

        m_creativeProjectIdCounter.increment();
        uint256 newProjectId = m_creativeProjectIdCounter.current();

        CreativeProject storage newProject = s_creativeProjects[newProjectId];
        newProject.owner = msg.sender; // The forker becomes the new project owner/admin
        newProject.title = _forkTitle;
        newProject.description = _forkDescription;
        newProject.licenseURI = _forkLicenseURI;
        newProject.ideaSeedId = originalProject.ideaSeedId; // Forks retain the original IdeaSeed reference
        newProject.active = true;

        // Copy initial contributor from forker with their existing weight (or a default, depending on fork rules)
        newProject.contributors[msg.sender].role = originalProject.contributors[msg.sender].role;
        newProject.contributors[msg.sender].royaltyWeight = originalProject.contributors[msg.sender].royaltyWeight;
        newProject.contributorAddresses.push(msg.sender);
        newProject.totalRoyaltyWeight = newProject.contributors[msg.sender].royaltyWeight;

        m_creativeProjectNFT.safeMint(msg.sender, newProjectId);
        emit ProjectForked(_projectId, newProjectId, msg.sender);
    }

    function proposeProjectMerge(uint256 _projectIdA, uint256 _projectIdB, string memory _mergeRationale) external onlyProjectAdmin(_projectIdA) nonReentrant {
        require(s_creativeProjects[_projectIdA].active, "SynergyCanvas: Project A is inactive");
        require(s_creativeProjects[_projectIdB].active, "SynergyCanvas: Project B is inactive");
        require(_projectIdA != _projectIdB, "SynergyCanvas: Cannot merge a project with itself");

        m_mergeProposalIdCounter.increment();
        uint256 proposalId = m_mergeProposalIdCounter.current();

        s_mergeProposals[proposalId] = MergeProposal({
            projectIdA: _projectIdA,
            projectIdB: _projectIdB,
            proposer: msg.sender,
            rationale: _mergeRationale,
            votesForA: 0,
            votesForB: 0,
            votesAgainstA: 0,
            votesAgainstB: 0,
            executed: false
        });

        emit ProjectMergeProposed(proposalId, _projectIdA, _projectIdB, msg.sender);
    }

    function voteOnProjectMerge(uint256 _mergeProposalId, bool _approve) external nonReentrant {
        MergeProposal storage proposal = s_mergeProposals[_mergeProposalId];
        require(!proposal.executed, "SynergyCanvas: Merge proposal already executed");
        require(s_creativeProjects[proposal.projectIdA].active, "SynergyCanvas: Project A is inactive");
        require(s_creativeProjects[proposal.projectIdB].active, "SynergyCanvas: Project B is inactive");

        bool isContributorA = s_creativeProjects[proposal.projectIdA].contributors[msg.sender].royaltyWeight > 0;
        bool isContributorB = s_creativeProjects[proposal.projectIdB].contributors[msg.sender].royaltyWeight > 0;
        require(isContributorA || isContributorB, "SynergyCanvas: Not a contributor to either project in proposal");

        if (isContributorA) {
            require(!s_creativeProjects[proposal.projectIdA].contributors[msg.sender].hasVotedOnMergeProposal[_mergeProposalId], "SynergyCanvas: Already voted on this merge proposal for Project A");
            s_creativeProjects[proposal.projectIdA].contributors[msg.sender].hasVotedOnMergeProposal[_mergeProposalId] = true;
            if (_approve) {
                proposal.votesForA = proposal.votesForA.add(1);
            } else {
                proposal.votesAgainstA = proposal.votesAgainstA.add(1);
            }
        }
        // If a contributor is in BOTH projects and votes, it counts as one vote for A and one vote for B.
        // This allows them to express distinct sentiment for each project's involvement.
        if (isContributorB) {
            require(!s_creativeProjects[proposal.projectIdB].contributors[msg.sender].hasVotedOnMergeProposal[_mergeProposalId], "SynergyCanvas: Already voted on this merge proposal for Project B");
            s_creativeProjects[proposal.projectIdB].contributors[msg.sender].hasVotedOnMergeProposal[_mergeProposalId] = true;
            if (_approve) {
                proposal.votesForB = proposal.votesForB.add(1);
            } else {
                proposal.votesAgainstB = proposal.votesAgainstB.add(1);
            }
        }
        
        emit ProjectMergeVoted(_mergeProposalId, msg.sender, _approve);

        // Simple merge logic: if both projects get majority FOR votes. Actual merging of IP is off-chain.
        uint256 totalContributorsA = s_creativeProjects[proposal.projectIdA].contributorAddresses.length;
        uint256 totalContributorsB = s_creativeProjects[proposal.projectIdB].contributorAddresses.length;

        bool majorityForA = (proposal.votesForA * 2 > totalContributorsA) && (totalContributorsA > 0);
        bool majorityForB = (proposal.votesForB * 2 > totalContributorsB) && (totalContributorsB > 0);

        if (majorityForA && majorityForB) {
            // Mark the merged-into project as inactive and transfer its funds to the main project.
            // Complex IP merging logic (e.g., code repositories, art assets) occurs off-chain.
            s_creativeProjects[proposal.projectIdB].active = false;
            // Funds from B are transferred to A's accumulated funds.
            s_creativeProjects[proposal.projectIdA].accumulatedFunds = s_creativeProjects[proposal.projectIdA].accumulatedFunds.add(s_creativeProjects[proposal.projectIdB].accumulatedFunds);
            s_creativeProjects[proposal.projectIdB].accumulatedFunds = 0;

            // Transfer ProjectB NFT ownership to ProjectA owner (or burn ProjectB NFT) to signify the merge.
            m_creativeProjectNFT.transferFrom(s_creativeProjects[proposal.projectIdB].owner, s_creativeProjects[proposal.projectIdA].owner, proposal.projectIdB);

            // Merge contributors (simplified: add B's contributors to A, handle existing contributors by combining weights)
            for (uint i = 0; i < s_creativeProjects[proposal.projectIdB].contributorAddresses.length; i++) {
                address contributorB = s_creativeProjects[proposal.projectIdB].contributorAddresses[i];
                if (s_creativeProjects[proposal.projectIdA].contributors[contributorB].royaltyWeight == 0) {
                    // If not already a contributor in A, add them
                    s_creativeProjects[proposal.projectIdA].contributors[contributorB] = s_creativeProjects[proposal.projectIdB].contributors[contributorB];
                    s_creativeProjects[proposal.projectIdA].contributorAddresses.push(contributorB);
                    s_creativeProjects[proposal.projectIdA].totalRoyaltyWeight = s_creativeProjects[proposal.projectIdA].totalRoyaltyWeight.add(s_creativeProjects[proposal.projectIdB].contributors[contributorB].royaltyWeight);
                } else {
                    // If already a contributor, combine weights (this specific rule can be customized for conflicts)
                    s_creativeProjects[proposal.projectIdA].contributors[contributorB].royaltyWeight = s_creativeProjects[proposal.projectIdA].contributors[contributorB].royaltyWeight.add(s_creativeProjects[proposal.projectIdB].contributors[contributorB].royaltyWeight);
                    s_creativeProjects[proposal.projectIdA].totalRoyaltyWeight = s_creativeProjects[proposal.projectIdA].totalRoyaltyWeight.add(s_creativeProjects[proposal.projectIdB].contributors[contributorB].royaltyWeight);
                }
            }

            proposal.executed = true;
            emit ProjectMerged(_mergeProposalId, proposal.projectIdA);
        }
    }

    function awardContributorReputation(address _contributor, uint256 _projectId, uint256 _points) external onlyPlatformAdmin {
        // This function would ideally be driven by a more decentralized governance mechanism (e.g., project DAO vote).
        // For this example, the platform admin acts as the authority.
        require(_contributor != address(0), "SynergyCanvas: Contributor cannot be zero address");
        require(s_creativeProjects[_projectId].active, "SynergyCanvas: Project is inactive");
        require(_points > 0, "SynergyCanvas: Points must be positive");

        s_contributorReputation[_contributor][_projectId] = s_contributorReputation[_contributor][_projectId].add(_points);
        emit ContributorReputationAwarded(_contributor, _projectId, _points);
    }

    function penalizeContributorReputation(address _contributor, uint256 _projectId, uint256 _points) external onlyPlatformAdmin {
        // Similar to awarding, this would ideally be a decentralized decision.
        require(_contributor != address(0), "SynergyCanvas: Contributor cannot be zero address");
        require(s_creativeProjects[_projectId].active, "SynergyCanvas: Project is inactive");
        require(_points > 0, "SynergyCanvas: Points must be positive");

        s_contributorReputation[_contributor][_projectId] = s_contributorReputation[_contributor][_projectId].sub(_points); // SafeMath handles underflow to 0 if points exceed current score
        emit ContributorReputationPenalized(_contributor, _projectId, _points);
    }

    // VIII. Funding
    function fundProjectDevelopment(uint256 _projectId) external payable nonReentrant {
        CreativeProject storage project = s_creativeProjects[_projectId];
        require(project.active, "SynergyCanvas: Project is inactive");
        require(msg.value > 0, "SynergyCanvas: Funding amount must be greater than zero");

        project.accumulatedFunds = project.accumulatedFunds.add(msg.value);
        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    // --- Helper functions to query data (view functions) ---
    function getIdeaSeedTags(uint256 _seedId) external view returns (string[] memory) {
        return s_ideaSeeds[_seedId].tags;
    }

    function getProjectContributors(uint256 _projectId) external view returns (address[] memory) {
        return s_creativeProjects[_projectId].contributorAddresses;
    }

    function getContributorDetails(uint256 _projectId, address _contributor) external view returns (string memory role, uint256 royaltyWeight) {
        Contributor storage c = s_creativeProjects[_projectId].contributors[_contributor];
        return (c.role, c.royaltyWeight);
    }

    function getComponentDetails(uint256 _componentId) external view returns (uint256 projectId, address owner, string memory componentType, string memory ipfsHash, string memory metadataURI) {
        Component storage c = s_components[_componentId];
        return (c.projectId, c.owner, c.componentType, c.ipfsHash, c.metadataURI);
    }

    function getRoyaltyProposalDetails(uint256 _proposalId) external view returns (address contributor, uint256 newWeight, uint256 projectId, uint256 votesFor, uint256 votesAgainst, bool executed) {
        RoyaltyWeightProposal storage p = s_royaltyProposals[_proposalId];
        return (p.contributor, p.newWeight, p.projectId, p.votesFor, p.votesAgainst, p.executed);
    }

    function getMergeProposalDetails(uint256 _mergeProposalId) external view returns (uint256 projectIdA, uint256 projectIdB, address proposer, string memory rationale, uint256 votesForA, uint256 votesForB, uint256 votesAgainstA, uint256 votesAgainstB, bool executed) {
        MergeProposal storage p = s_mergeProposals[_mergeProposalId];
        return (p.projectIdA, p.projectIdB, p.proposer, p.rationale, p.votesForA, p.votesForB, p.votesAgainstA, p.votesAgainstB, p.executed);
    }

    function getDisputeDetails(uint256 _disputeId) external view returns (uint256 projectId, uint256 componentId, address disputer, address resolver, string memory reason, address winner, uint256 adjustedWeight, bool resolved) {
        Dispute storage d = s_disputes[_disputeId];
        return (d.projectId, d.componentId, d.disputer, d.resolver, d.reason, d.winner, d.adjustedWeight, d.resolved);
    }

    // --- External NFT Contract Addresses for interaction ---
    function ideaSeedNFTAddress() external view returns (address) {
        return address(m_ideaSeedNFT);
    }

    function creativeProjectNFTAddress() external view returns (address) {
        return address(m_creativeProjectNFT);
    }

    function componentNFTAddress() external view returns (address) {
        return address(m_componentNFT);
    }
}

```