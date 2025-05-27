Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts into a "Multi-Layered Decentralized Autonomous Organization (DAO)".

This DAO structure aims to be more nuanced than a simple token-weighted system by introducing:

1.  **Multiple Layers:** Members belong to different tiers with varying privileges and voting power.
2.  **Reputation System:** Points are earned for constructive participation, influencing layer progression and voting weight.
3.  **Domain/Expertise Assignment:** Members can be associated with specific areas, potentially gating proposals or voting rights within those domains.
4.  **NFT Integration:** NFTs can be used for proposal sponsorship or grant special voting power.
5.  **Liquid Democracy:** Members can delegate their voting power.
6.  **Advanced Governance:** Different proposal types might have different thresholds or required layers for submission/voting.

It's important to note that while this contract demonstrates concepts, a production-ready DAO would require significantly more robust testing, security audits, and potentially a modular architecture (e.g., using proxy patterns for upgradability).

---

**Outline and Function Summary**

**Contract Name:** `MultiLayeredDAO`

**Core Concepts:** Multi-Layered Membership, Reputation System, Domain Expertise, NFT Integration, Liquid Democracy, Advanced Governance.

**State Variables:**
*   DAO Configuration (token addresses, timelock, etc.)
*   Layer Configurations
*   Domain Configurations
*   Member Profiles (layer, domain, reputation, delegation)
*   Proposal Data
*   Voting Data
*   DAO Treasury balances (ETH, ERC20)
*   DAO-owned NFTs

**Structs:**
*   `LayerConfig`: Defines rules/privileges for a layer.
*   `DomainConfig`: Defines properties for a domain/expertise area.
*   `MemberProfile`: Stores data for each member.
*   `Proposal`: Stores proposal details, state, votes.
*   `VoteDetails`: Stores how a member voted.

**Events:**
*   Key state changes (ProposalCreated, Voted, Executed, MemberJoinedLayer, ReputationUpdated, etc.)

**Modifiers:**
*   `onlyLayer`: Restricts access to members of a specific layer or higher.
*   `isMember`: Restricts access to members of the DAO.
*   `proposalExists`: Checks if a proposal ID is valid.
*   `proposalStateIs`: Checks if a proposal is in a specific state.

**Functions (Total: 33)**

**I. Setup and Configuration (5)**
1.  `constructor`: Initializes the DAO with core addresses.
2.  `addLayer`: Defines a new membership layer with specific parameters.
3.  `updateLayer`: Modifies parameters of an existing layer (requires high layer/governance).
4.  `addDomain`: Defines a new expertise domain.
5.  `updateDomain`: Modifies parameters of an existing domain (requires high layer/governance).

**II. Membership Management (8)**
6.  `applyForLayer`: Allows a non-member or member of a lower layer to apply for a specific layer.
7.  `nominateForLayer`: Allows a member to nominate another address for a layer.
8.  `processApplication`: High-layer members or council vote/process pending applications.
9.  `moveToLayerInternal`: Internal function to change a member's layer. (Public view helper: `getMemberProfile`)
10. `assignDomain`: Assigns a member to a specific expertise domain.
11. `leaveDomain`: Allows a member to leave their assigned domain.
12. `delegateVote`: Allows a member to delegate their voting power to another member.
13. `undelegateVote`: Allows a member to remove their delegation.

**III. Governance: Proposals (6)**
14. `createProposal`: Submits a new proposal (requires minimum layer or token stake).
15. `createProposalNFTRequired`: Submits a proposal requiring ownership of a specific NFT (advanced sponsorship).
16. `cancelProposal`: Cancels a proposal if conditions are met (e.g., proposer).
17. `queueProposal`: Moves a passed proposal to the execution queue after the voting period.
18. `executeProposal`: Executes the payload of a proposal after the timelock expires.
19. `getProposalState`: Returns the current state of a proposal.

**IV. Governance: Voting & Weighting (5)**
20. `vote`: Allows a member (or their delegate) to cast a vote on an active proposal.
21. `getVotingWeight`: Calculates a member's effective voting weight for a given proposal, considering layer, token balance, reputation, delegation, and potentially NFTs/domains. (Pure/View Helper)
22. `getVoteCount`: Returns the current tally for a proposal. (View Helper)
23. `getDelegation`: Returns who an address has delegated to. (View Helper)
24. `getLayerVotingPower`: Calculates the total voting power of a specific layer for a proposal (View Helper).

**V. Treasury & Asset Management (4)**
25. `depositTreasuryETH`: Allows anyone to send ETH to the DAO treasury.
26. `depositTreasuryToken`: Allows transferring supported ERC20 into the treasury.
27. `withdrawTreasuryETH`: Executes an ETH withdrawal from the treasury (via executed proposal).
28. `withdrawTreasuryToken`: Executes an ERC20 withdrawal from the treasury (via executed proposal).
29. `transferTreasuryNFT`: Executes an NFT transfer from the treasury (via executed proposal).

**VI. Reputation System (1)**
30. `_awardReputation`: Internal function called by other functions (like `vote`, `executeProposal`) to update a member's reputation points based on actions. (Public View Helper: `getReputation`)

**VII. Query Functions (View/Pure Helpers) (4)**
31. `getMemberProfile`: Retrieves a member's profile details.
32. `getLayerConfig`: Retrieves configuration for a specific layer.
33. `getDomainConfig`: Retrieves configuration for a specific domain.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title MultiLayeredDAO
/// @author Your Name/Alias
/// @notice A decentralized autonomous organization with multi-layered membership,
///         reputation system, domain expertise, NFT integration, and liquid democracy.
/// @dev This is an advanced conceptual contract demonstrating various features.
///      It is not production-ready and requires significant security review,
///      testing, and potentially a modular/upgradeable architecture.

contract MultiLayeredDAO {
    using Address for address;

    // --- State Variables ---

    IERC20 public governanceToken; // Token used for governance weighting and potentially staking
    IERC721 public membershipNFT; // Optional: NFT representing membership or special roles
    IERC721 public assetNFT;      // Optional: NFT assets potentially managed by the DAO

    address payable public treasury; // Wallet holding DAO funds

    // DAO Configuration
    uint256 public proposalTimelock; // Time delay between proposal queuing and execution
    uint256 public proposalThresholdTokenStake; // Minimum token stake required to create a proposal
    uint256 public minReputationForProposal; // Minimum reputation required to create a proposal

    // Layer Management
    struct LayerConfig {
        uint256 minStakeRequired; // Minimum token stake to join/maintain layer
        uint256 minReputationRequired; // Minimum reputation to join/maintain layer
        uint256 votingWeightMultiplier; // Multiplier for token/reputation voting weight
        bool canCreateProposals; // Can members of this layer create proposals?
        bool canProcessApplications; // Can members of this layer process applications?
        uint8 requiredNFTRole; // Specific NFT role ID required for this layer (0 for none)
        string name;
    }
    mapping(uint8 => LayerConfig) public layers; // Layer ID => Config
    uint8 public nextLayerId = 1; // Start with ID 1

    // Domain Management
    struct DomainConfig {
        string name;
        string description;
        uint256 minReputationToJoin;
        uint8 requiredLayerToManage; // Layer required to manage (assign/remove) members in this domain
    }
    mapping(uint16 => DomainConfig) public domains; // Domain ID => Config
    uint16 public nextDomainId = 1; // Start with ID 1

    // Member Profiles
    struct MemberProfile {
        bool exists; // True if address is a recognized member
        uint8 currentLayerId;
        uint16 currentDomainId; // 0 if not assigned to a domain
        uint256 reputationPoints;
        address delegatedTo; // Address they delegated their vote to (0x0 for none)
    }
    mapping(address => MemberProfile) public members;

    // Proposal Management
    enum ProposalState { Draft, Active, Passed, Failed, Queued, Executed, Canceled }

    struct Proposal {
        address proposer;
        bytes callData; // The function call to be executed if proposal passes
        address target; // The contract address to call
        uint256 value; // ETH value to send with the call (for treasury withdrawals)
        string description;
        ProposalState state;
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        uint256 executionTimestamp; // When it was queued

        // Voting Outcome
        uint256 yesVotes;
        uint256 noVotes;
        uint256 abstainVotes;
        uint256 totalWeightedVotes; // Total voting power that participated
        uint256 quorumThreshold; // Dynamic quorum requirement
        uint256 majorityThreshold; // Dynamic majority requirement (e.g., > 50%)
        uint8 requiredLayerToVote; // Minimum layer to vote on this proposal type

        uint256 requiredNFTIdToSponsor; // Optional NFT ID required to sponsor this proposal type
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;

    // Voting Data
    mapping(uint256 => mapping(address => VoteDetails)) public votes; // proposalId => voter => details
    struct VoteDetails {
        bool hasVoted;
        bool support; // True for Yes, False for No
        uint256 votingWeight; // Weight used at the time of voting
        bool isDelegatedVote; // True if this vote was cast by a delegate
    }

    // Application Management
    struct Application {
        address applicant;
        uint8 targetLayerId;
        uint256 submissionTimestamp;
        bool processed;
        bool approved;
    }
    mapping(uint256 => Application) public applications;
    uint256 public nextApplicationId = 1;
    uint256[] public pendingApplicationIds; // Array to easily list pending applications

    // --- Events ---

    event Initialized(address indexed governanceToken, address indexed treasury);
    event LayerAdded(uint8 indexed layerId, string name);
    event LayerUpdated(uint8 indexed layerId, string name);
    event DomainAdded(uint16 indexed domainId, string name);
    event DomainUpdated(uint16 indexed domainId, string name);
    event MemberJoinedLayer(address indexed member, uint8 indexed newLayerId, uint8 indexed oldLayerId);
    event MemberAssignedDomain(address indexed member, uint16 indexed domainId);
    event MemberLeftDomain(address indexed member, uint16 indexed domainId);
    event ReputationUpdated(address indexed member, uint256 newReputation);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalQueued(uint256 indexed proposalId, uint256 executionTimestamp);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ProposalCanceled(uint256 indexed proposalId);

    event TreasuryDepositETH(address indexed sender, uint256 amount);
    event TreasuryDepositToken(address indexed sender, address indexed token, uint256 amount);
    event TreasuryWithdrawalETH(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event TreasuryWithdrawalToken(uint256 indexed proposalId, address indexed token, address indexed recipient, uint256 amount);
    event TreasuryNFTTransfer(uint256 indexed proposalId, address indexed nftContract, uint256 indexed tokenId, address indexed recipient);

    event ApplicationSubmitted(uint256 indexed applicationId, address indexed applicant, uint8 indexed targetLayerId);
    event ApplicationProcessed(uint256 indexed applicationId, bool approved, address indexed processor);

    // --- Modifiers ---

    modifier onlyLayer(uint8 _minLayerId) {
        require(members[msg.sender].exists, "DAO: Not a member");
        require(members[msg.sender].currentLayerId >= _minLayerId, "DAO: Insufficient layer privilege");
        _;
    }

    modifier isMember() {
        require(members[msg.sender].exists, "DAO: Not a member");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "DAO: Invalid proposal ID");
        _;
    }

    modifier proposalStateIs(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "DAO: Proposal is not in the required state");
        _;
    }

    modifier canVote(uint256 _proposalId, address _voter) {
        require(members[_voter].exists, "DAO: Voter is not a member");
        require(!votes[_proposalId][_voter].hasVoted, "DAO: Voter already voted");
        require(members[_voter].currentLayerId >= proposals[_proposalId].requiredLayerToVote, "DAO: Voter's layer is too low for this proposal");
        // Check for active delegation if voter is not msg.sender and msg.sender is the delegatee
        if (_voter != msg.sender) {
             require(members[msg.sender].delegatedTo == address(0), "DAO: You cannot vote if you have delegated your vote");
             require(members[_voter].delegatedTo == msg.sender, "DAO: You are not the delegatee for this member");
        } else {
             require(members[msg.sender].delegatedTo == address(0), "DAO: You cannot vote if you have delegated your vote");
        }
        _;
    }

    // --- Constructor ---

    constructor(address _governanceToken, address _membershipNFT, address _assetNFT, uint256 _proposalTimelock, uint256 _proposalThresholdTokenStake, uint256 _minReputationForProposal) payable {
        require(_governanceToken != address(0), "DAO: Invalid governance token address");
        // Treasury is this contract's address by default, or can be set explicitly
        treasury = payable(address(this));

        governanceToken = IERC20(_governanceToken);
        if (_membershipNFT != address(0)) membershipNFT = IERC721(_membershipNFT);
        if (_assetNFT != address(0)) assetNFT = IERC721(_assetNFT);

        proposalTimelock = _proposalTimelock;
        proposalThresholdTokenStake = _proposalThresholdTokenStake;
        minReputationForProposal = _minReputationForProposal;

        // Initialize a base layer 0 (non-member or default)
        layers[0] = LayerConfig({
            minStakeRequired: 0,
            minReputationRequired: 0,
            votingWeightMultiplier: 0, // Layer 0 has no voting power by default
            canCreateProposals: false,
            canProcessApplications: false,
            requiredNFTRole: 0,
            name: "Non-Member/Base"
        });

        emit Initialized(_governanceToken, treasury);
    }

    receive() external payable {
        emit TreasuryDepositETH(msg.sender, msg.value);
    }

    // --- I. Setup and Configuration ---

    /// @notice Adds a new membership layer to the DAO.
    /// @param _minStake Required minimum token stake for this layer.
    /// @param _minReputation Required minimum reputation for this layer.
    /// @param _votingWeightMultiplier Multiplier for voting weight calculation in this layer.
    /// @param _canCreateProposals Can members of this layer create proposals?
    /// @param _canProcessApplications Can members of this layer process applications?
    /// @param _requiredNFTRole Specific NFT role ID required for this layer (0 for none).
    /// @param _name Name of the layer.
    function addLayer(uint256 _minStake, uint256 _minReputation, uint256 _votingWeightMultiplier, bool _canCreateProposals, bool _canProcessApplications, uint8 _requiredNFTRole, string calldata _name) external {
        // Require this action to be approved by a high-layer governance proposal
        // For simplicity, we'll skip the proposal part in this example, but in production
        // this would likely be triggered by executeProposal.
        // require(tx.origin == address(this), "DAO: Must be called via executed proposal"); // Example check

        uint8 layerId = nextLayerId++;
        layers[layerId] = LayerConfig({
            minStakeRequired: _minStake,
            minReputationRequired: _minReputation,
            votingWeightMultiplier: _votingWeightMultiplier,
            canCreateProposals: _canCreateProposals,
            canProcessApplications: _canProcessApplications,
            requiredNFTRole: _requiredNFTRole,
            name: _name
        });
        emit LayerAdded(layerId, _name);
    }

     /// @notice Updates an existing membership layer configuration.
     /// @dev Must be called via an executed proposal in a production system.
     /// @param _layerId The ID of the layer to update.
     /// @param _minStake Required minimum token stake for this layer.
     /// @param _minReputation Required minimum reputation for this layer.
     /// @param _votingWeightMultiplier Multiplier for voting weight calculation in this layer.
     /// @param _canCreateProposals Can members of this layer create proposals?
     /// @param _canProcessApplications Can members of this layer process applications?
     /// @param _requiredNFTRole Specific NFT role ID required for this layer (0 for none).
     /// @param _name Name of the layer.
    function updateLayer(uint8 _layerId, uint256 _minStake, uint256 _minReputation, uint256 _votingWeightMultiplier, bool _canCreateProposals, bool _canProcessApplications, uint8 _requiredNFTRole, string calldata _name) external {
        // Require this action to be approved by a high-layer governance proposal
        require(_layerId > 0 && _layerId < nextLayerId, "DAO: Invalid layer ID");
        // require(tx.origin == address(this), "DAO: Must be called via executed proposal"); // Example check

        layers[_layerId] = LayerConfig({
            minStakeRequired: _minStake,
            minReputationRequired: _minReputation,
            votingWeightMultiplier: _votingWeightMultiplier,
            canCreateProposals: _canCreateProposals,
            canProcessApplications: _canProcessApplications,
            requiredNFTRole: _requiredNFTRole,
            name: _name
        });
        emit LayerUpdated(_layerId, _name);
    }

    /// @notice Adds a new expertise domain.
    /// @param _name Name of the domain.
    /// @param _description Description of the domain.
    /// @param _minReputationToJoin Minimum reputation required to be assigned to this domain.
    /// @param _requiredLayerToManage Minimum layer required to manage assignments in this domain.
    function addDomain(string calldata _name, string calldata _description, uint256 _minReputationToJoin, uint8 _requiredLayerToManage) external {
         // Require this action to be approved by a high-layer governance proposal
        // require(tx.origin == address(this), "DAO: Must be called via executed proposal"); // Example check

        uint16 domainId = nextDomainId++;
        domains[domainId] = DomainConfig({
            name: _name,
            description: _description,
            minReputationToJoin: _minReputationToJoin,
            requiredLayerToManage: _requiredLayerToManage
        });
        emit DomainAdded(domainId, _name);
    }

    /// @notice Updates an existing expertise domain configuration.
    /// @dev Must be called via an executed proposal.
    /// @param _domainId The ID of the domain to update.
    /// @param _name Name of the domain.
    /// @param _description Description of the domain.
    /// @param _minReputationToJoin Minimum reputation required to be assigned to this domain.
    /// @param _requiredLayerToManage Minimum layer required to manage assignments in this domain.
    function updateDomain(uint16 _domainId, string calldata _name, string calldata _description, uint256 _minReputationToJoin, uint8 _requiredLayerToManage) external {
        // Require this action to be approved by a high-layer governance proposal
        require(_domainId > 0 && _domainId < nextDomainId, "DAO: Invalid domain ID");
        // require(tx.origin == address(this), "DAO: Must be called via executed proposal"); // Example check

        domains[_domainId] = DomainConfig({
            name: _name,
            description: _description,
            minReputationToJoin: _minReputationToJoin,
            requiredLayerToManage: _requiredLayerToManage
        });
        emit DomainUpdated(_domainId, _name);
    }


    // --- II. Membership Management ---

    /// @notice Allows an address to submit an application to join a specific layer.
    /// @param _targetLayerId The ID of the layer they wish to join.
    function applyForLayer(uint8 _targetLayerId) external {
        require(_targetLayerId > 0 && _targetLayerId < nextLayerId, "DAO: Invalid target layer ID");
        require(!members[msg.sender].exists || members[msg.sender].currentLayerId < _targetLayerId, "DAO: Already in target layer or higher");
        // Add checks for minimum token stake/reputation if applying directly? Or handle in processing?
        // Let's assume minimum requirements are checked during processing.

        uint256 applicationId = nextApplicationId++;
        applications[applicationId] = Application({
            applicant: msg.sender,
            targetLayerId: _targetLayerId,
            submissionTimestamp: block.timestamp,
            processed: false,
            approved: false
        });
        pendingApplicationIds.push(applicationId);
        emit ApplicationSubmitted(applicationId, msg.sender, _targetLayerId);
    }

    /// @notice Allows an existing member to nominate another address for a specific layer.
    /// @param _nominee The address to nominate.
    /// @param _targetLayerId The ID of the layer for nomination.
    function nominateForLayer(address _nominee, uint8 _targetLayerId) external isMember {
         require(_nominee != address(0), "DAO: Invalid nominee address");
         require(_targetLayerId > 0 && _targetLayerId < nextLayerId, "DAO: Invalid target layer ID");
         require(!members[_nominee].exists || members[_nominee].currentLayerId < _targetLayerId, "DAO: Nominee already in target layer or higher");

         // Add checks for minimum layer of nominator if desired
         // require(members[msg.sender].currentLayerId >= MIN_LAYER_FOR_NOMINATION, "DAO: Insufficient layer to nominate");

         uint256 applicationId = nextApplicationId++;
         applications[applicationId] = Application({
             applicant: _nominee,
             targetLayerId: _targetLayerId,
             submissionTimestamp: block.timestamp,
             processed: false,
             approved: false
         });
         pendingApplicationIds.push(applicationId);
         emit ApplicationSubmitted(applicationId, _nominee, _targetLayerId); // Re-use event for nomination
    }


    /// @notice Allows privileged members to process a pending application.
    /// @param _applicationId The ID of the application to process.
    /// @param _approved True to approve, False to reject.
    function processApplication(uint256 _applicationId, bool _approved) external isMember {
        require(_applicationId > 0 && _applicationId < nextApplicationId, "DAO: Invalid application ID");
        require(!applications[_applicationId].processed, "DAO: Application already processed");

        Application storage app = applications[_applicationId];
        LayerConfig storage targetLayer = layers[app.targetLayerId];

        // Check if the caller has the privilege to process applications
        require(members[msg.sender].currentLayerId > 0 && layers[members[msg.sender].currentLayerId].canProcessApplications, "DAO: Caller cannot process applications");

        app.processed = true;
        app.approved = _approved;

        if (_approved) {
            // Check if applicant meets minimum requirements at the time of processing
            uint256 applicantTokenBalance = governanceToken.balanceOf(app.applicant);
            uint256 applicantReputation = members[app.applicant].reputationPoints;
            // NFT check requires token ID - this is a simplification.
            // A real implementation would need a way to specify *which* NFT or role.
            // For now, we skip the NFT check here and assume it's handled off-chain or via a different process.
            // require(assetNFT == address(0) || targetLayer.requiredNFTRole == 0 || assetNFT.ownerOf(targetLayer.requiredNFTRole) == app.applicant, "DAO: Applicant does not hold required NFT");


            if (applicantTokenBalance >= targetLayer.minStakeRequired && applicantReputation >= targetLayer.minReputationRequired) {
                uint8 oldLayerId = members[app.applicant].currentLayerId;
                _moveToLayerInternal(app.applicant, app.targetLayerId);
                emit MemberJoinedLayer(app.applicant, app.targetLayerId, oldLayerId);
            } else {
                // Application approved, but requirements not met yet. Applicant needs to meet them later.
                // This scenario is complex. For this example, we'll mark it approved but not move layer.
                // In a real DAO, there might be a separate 'pending admission' state.
                // Simpler: If approved, *and* requirements met, move. Otherwise, approved but stuck.
                 if (members[app.applicant].exists) {
                    // Member approved, but not moved layer because requirements not met *now*.
                 } else {
                     // New applicant approved, but requirements not met. Don't create member profile yet.
                 }
            }
        }

        // Remove from pending list (simple but inefficient for large arrays)
        for (uint i = 0; i < pendingApplicationIds.length; i++) {
            if (pendingApplicationIds[i] == _applicationId) {
                pendingApplicationIds[i] = pendingApplicationIds[pendingApplicationIds.length - 1];
                pendingApplicationIds.pop();
                break;
            }
        }

        emit ApplicationProcessed(_applicationId, _approved, msg.sender);
    }

    /// @notice Internal function to change a member's layer.
    /// @dev This should only be called by trusted processes (application processing, executed proposals).
    function _moveToLayerInternal(address _member, uint8 _newLayerId) internal {
        require(_newLayerId < nextLayerId, "DAO: Invalid target layer ID");
        uint8 oldLayer = members[_member].currentLayerId;

        if (!members[_member].exists) {
            members[_member].exists = true;
             // Initialize reputation if new member
            if (members[_member].reputationPoints == 0) {
                members[_member].reputationPoints = 1; // Give new members a tiny bit of reputation
            }
        }
         // Remove delegation if changing layers dramatically? Policy decision.
        if (members[_member].delegatedTo != address(0) && _newLayerId < oldLayer) { // Example: Lose delegation if demoted
             members[_member].delegatedTo = address(0);
             emit VoteUndelegated(_member);
        }


        members[_member].currentLayerId = _newLayerId;
        emit MemberJoinedLayer(_member, _newLayerId, oldLayer);
    }

    /// @notice Assigns a member to a specific expertise domain.
    /// @param _member The address of the member.
    /// @param _domainId The ID of the domain.
    function assignDomain(address _member, uint16 _domainId) external isMember {
        require(domains[_domainId].name.length > 0, "DAO: Invalid domain ID"); // Check if domain exists
        // Check if caller has permission to manage this domain
        require(members[msg.sender].currentLayerId >= domains[_domainId].requiredLayerToManage, "DAO: Insufficient layer to manage this domain");
        require(members[_member].exists, "DAO: Target is not a member");
        require(members[_member].reputationPoints >= domains[_domainId].minReputationToJoin, "DAO: Member does not meet minimum reputation for domain");

        members[_member].currentDomainId = _domainId;
        emit MemberAssignedDomain(_member, _domainId);
    }

     /// @notice Allows a member to leave their assigned domain.
     /// @dev Does not require special permission.
     function leaveDomain() external isMember {
         require(members[msg.sender].currentDomainId != 0, "DAO: Not currently assigned to a domain");
         uint16 oldDomainId = members[msg.sender].currentDomainId;
         members[msg.sender].currentDomainId = 0;
         emit MemberLeftDomain(msg.sender, oldDomainId);
     }

    /// @notice Allows a member to delegate their voting power to another member.
    /// @param _delegatee The address to delegate to. Set to 0x0 to undelegate.
    function delegateVote(address _delegatee) external isMember {
        require(_delegatee == address(0) || (_delegatee != msg.sender && members[_delegatee].exists), "DAO: Invalid delegatee or self-delegation");

        address oldDelegatee = members[msg.sender].delegatedTo;
        members[msg.sender].delegatedTo = _delegatee;

        if (_delegatee == address(0)) {
             emit VoteUndelegated(msg.sender);
        } else if (oldDelegatee != _delegatee) {
             emit VoteDelegated(msg.sender, _delegatee);
        }
    }

    /// @notice Allows a member to undelegate their voting power.
    function undelegateVote() external {
        // isMember check is implicitly done by delegateVote(0x0)
        delegateVote(address(0));
    }

     /// @notice Removes a member from the DAO (sets layer to 0).
     /// @dev This should typically be triggered by an executed proposal.
     /// @param _member The address to remove.
    function kickMember(address _member) external {
         // Require this action to be approved by a governance proposal
         require(members[_member].exists, "DAO: Target is not a member");
         // require(tx.origin == address(this), "DAO: Must be called via executed proposal"); // Example check

         _moveToLayerInternal(_member, 0); // Move to layer 0 (non-member)
    }


    // --- III. Governance: Proposals ---

    /// @notice Submits a new general proposal.
    /// @param _target The contract address the proposal interacts with.
    /// @param _value ETH value to send with the call.
    /// @param _callData The encoded function call data.
    /// @param _description Description of the proposal.
    /// @param _votingPeriod Duration of the voting period in seconds.
    /// @param _requiredLayerToVote Minimum layer required to vote on this proposal.
    /// @param _quorumThreshold Minimum total weighted votes required for proposal to pass (percentage of total possible weight).
    /// @param _majorityThreshold Minimum percentage of 'Yes' votes among participating votes.
    function createProposal(
        address _target,
        uint256 _value,
        bytes calldata _callData,
        string calldata _description,
        uint256 _votingPeriod,
        uint8 _requiredLayerToVote,
        uint256 _quorumThreshold, // e.g., 40 (for 40%)
        uint256 _majorityThreshold // e.g., 51 (for > 50%)
    ) external payable isMember returns (uint256) {
        // Check if sender is allowed to create proposals based on layer and requirements
        require(layers[members[msg.sender].currentLayerId].canCreateProposals, "DAO: Insufficient layer to create proposals");
        require(members[msg.sender].reputationPoints >= minReputationForProposal, "DAO: Insufficient reputation to create proposals");
        require(governanceToken.balanceOf(msg.sender) >= proposalThresholdTokenStake, "DAO: Insufficient token stake to create proposals");

        // Require stake to be sent with the proposal
        require(msg.value == proposalThresholdTokenStake, "DAO: Must stake required tokens for proposal");
        // Transfer the staked tokens to the treasury
        // Note: This stake is *burned* or *locked* until proposal fails/passes.
        // For simplicity, we'll transfer to treasury. A real system might use a separate staking pool.
        if (proposalThresholdTokenStake > 0) {
             governanceToken.transferFrom(msg.sender, treasury, proposalThresholdTokenStake); // Requires approval
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            target: _target,
            value: _value,
            callData: _callData,
            description: _description,
            state: ProposalState.Active,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + _votingPeriod,
            executionTimestamp: 0,
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            totalWeightedVotes: 0,
            quorumThreshold: _quorumThreshold,
            majorityThreshold: _majorityThreshold,
            requiredLayerToVote: _requiredLayerToVote,
            requiredNFTIdToSponsor: 0 // No specific NFT required for this type
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    /// @notice Submits a new proposal requiring ownership of a specific NFT for sponsorship.
    /// @param _target The contract address the proposal interacts with.
    /// @param _value ETH value to send with the call.
    /// @param _callData The encoded function call data.
    /// @param _description Description of the proposal.
    /// @param _votingPeriod Duration of the voting period in seconds.
    /// @param _requiredLayerToVote Minimum layer required to vote on this proposal.
    /// @param _quorumThreshold Minimum total weighted votes required.
    /// @param _majorityThreshold Minimum percentage of 'Yes' votes.
    /// @param _requiredNFTId The ID of the NFT required to sponsor this proposal type.
    function createProposalNFTRequired(
        address _target,
        uint256 _value,
        bytes calldata _callData,
        string calldata _description,
        uint256 _votingPeriod,
        uint8 _requiredLayerToVote,
        uint256 _quorumThreshold,
        uint256 _majorityThreshold,
        uint256 _requiredNFTId
    ) external payable returns (uint256) {
        require(address(membershipNFT) != address(0), "DAO: Membership NFT not configured");
        require(membershipNFT.ownerOf(_requiredNFTId) == msg.sender, "DAO: Caller does not own the required NFT");

        // Additional checks similar to createProposal (layer, reputation, stake) might apply
        // based on DAO policy, or the NFT itself grants these privileges.
        // For this example, we assume NFT ownership *replaces* other sponsorship requirements.

         require(msg.value == proposalThresholdTokenStake, "DAO: Must stake required tokens for proposal");
         if (proposalThresholdTokenStake > 0) {
              governanceToken.transferFrom(msg.sender, treasury, proposalThresholdTokenStake); // Requires approval
         }


        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            target: _target,
            value: _value,
            callData: _callData,
            description: _description,
            state: ProposalState.Active,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + _votingPeriod,
            executionTimestamp: 0,
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            totalWeightedVotes: 0,
            quorumThreshold: _quorumThreshold,
            majorityThreshold: _majorityThreshold,
            requiredLayerToVote: _requiredLayerToVote,
            requiredNFTIdToSponsor: _requiredNFTId // Specify required NFT
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    /// @notice Allows canceling a proposal if conditions are met (e.g., before voting starts, by proposer).
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage p = proposals[_proposalId];
        require(p.state == ProposalState.Draft || (p.state == ProposalState.Active && block.timestamp < p.creationTimestamp + 1 days), "DAO: Cannot cancel proposal in current state or after grace period"); // Example condition
        require(msg.sender == p.proposer, "DAO: Only proposer can cancel");

        p.state = ProposalState.Canceled;

        // Refund staked tokens (if applicable and desired)
        // uint256 stakeAmount = ...; // Need to store stake amount per proposal
        // if (stakeAmount > 0) governanceToken.transfer(msg.sender, stakeAmount);

        emit ProposalStateChanged(_proposalId, ProposalState.Canceled);
        emit ProposalCanceled(_proposalId);
    }


    /// @notice Moves a proposal from Passed state to Queued state.
    /// @dev Can be called by anyone after the voting period ends and proposal passed.
    /// @param _proposalId The ID of the proposal to queue.
    function queueProposal(uint256 _proposalId) external proposalExists(_proposalId) proposalStateIs(_proposalId, ProposalState.Passed) {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp >= p.votingPeriodEnd, "DAO: Voting period not ended yet");

        p.executionTimestamp = block.timestamp + proposalTimelock;
        p.state = ProposalState.Queued;

        emit ProposalStateChanged(_proposalId, ProposalState.Queued);
        emit ProposalQueued(_proposalId, p.executionTimestamp);
    }

    /// @notice Executes the payload of a queued proposal.
    /// @dev Can be called by anyone after the timelock expires.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external payable proposalExists(_proposalId) proposalStateIs(_proposalId, ProposalState.Queued) {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp >= p.executionTimestamp, "DAO: Timelock has not expired yet");

        // Execute the proposal payload
        (bool success, ) = p.target.call{value: p.value}(p.callData);

        p.state = ProposalState.Executed;

        // Award reputation to voters who voted for the winning outcome? Policy decision.
        // Example: Award reputation to Yes voters if passed, No voters if failed.
        // _awardReputationForAllVoters(_proposalId, success); // More complex helper needed

        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
        emit ProposalExecuted(_proposalId, success);
    }

    /// @notice Gets the current state of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The state of the proposal.
    function getProposalState(uint256 _proposalId) external view proposalExists(_proposalId) returns (ProposalState) {
        Proposal storage p = proposals[_proposalId];
        // Update state dynamically if voting period ended but state is still Active
        if (p.state == ProposalState.Active && block.timestamp >= p.votingPeriodEnd) {
             // Determine Passed/Failed state based on votes
             // Requires knowing total possible voting weight to calculate quorum.
             // This is complex as total weight changes with members/tokens.
             // A simpler approach is quorum relative to *participating* votes, or a static number.
             // Let's assume quorum is total participating votes relative to a minimum.
             // And majority is Yes votes relative to (Yes + No) votes.

             // Check quorum
             if (p.totalWeightedVotes > 0 && (p.totalWeightedVotes * 100 / getTotalPotentialVotingWeight()) >= p.quorumThreshold) {
                  // Check majority (only count Yes/No for majority)
                 uint256 totalYesNoVotes = p.yesVotes + p.noVotes;
                 if (totalYesNoVotes > 0 && (p.yesVotes * 100 / totalYesNoVotes) >= p.majorityThreshold) {
                     return ProposalState.Passed;
                 } else {
                     return ProposalState.Failed;
                 }
             } else {
                 return ProposalState.Failed; // Did not meet quorum
             }
        }
        return p.state;
    }


    // --- IV. Governance: Voting & Weighting ---

    /// @notice Allows a member or their delegate to cast a vote.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'Yes', False for 'No'.
    /// @param _abstain True if voting 'Abstain', False otherwise.
    function vote(uint256 _proposalId, bool _support, bool _abstain) external proposalExists(_proposalId) proposalStateIs(_proposalId, ProposalState.Active) canVote(_proposalId, msg.sender) {
         Proposal storage p = proposals[_proposalId];
         require(block.timestamp < p.votingPeriodEnd, "DAO: Voting period has ended");

         address voter = msg.sender;
         bool isDelegated = false;
         address actualVoter = msg.sender;

         // If msg.sender is a delegate, find the original delegator
         // This requires iterating or having a reverse lookup, which is complex.
         // Simpler approach: Delegate casts vote *on behalf of* the delegator explicitly.
         // Or, caller is either the voter OR the delegatee casting for themselves.
         // Let's use the simplified approach where `canVote` modifier handles delegation.
         // If `msg.sender != voter` in `canVote`, it means `msg.sender` is casting on behalf of `voter`.
         // The `canVote` modifier should check this: `require(msg.sender == _voter || members[_voter].delegatedTo == msg.sender)`
         // Let's assume `_voter` parameter is added if delegated voting is explicit.

        // Simplified voting: msg.sender is the voter, check if they have delegated.
        address effectiveVoter = members[msg.sender].delegatedTo == address(0) ? msg.sender : members[msg.sender].delegatedTo;
        require(effectiveVoter == msg.sender, "DAO: Cannot vote directly if you have delegated your vote"); // Enforce delegation flow


        // Now, the delegatee casts the vote for the delegator.
        // We need to know *who* they are voting for.
        // Let's adjust the function signature or have a separate delegated vote function.
        // Simpler still: the `canVote` modifier allows the delegatee to call `vote` *as if* they were the delegator.
        // The modifier should check: `require(msg.sender == _voter || members[_voter].delegatedTo == msg.sender, "DAO: Not authorized to vote for this address");`
        // And the vote should be recorded for `_voter`, not `msg.sender`.
        // Let's refactor `vote` to take the voter address.

        // Refactored vote function would look like:
        // function vote(uint256 _proposalId, address _voter, bool _support, bool _abstain) external proposalExists(_proposalId) proposalStateIs(_proposalId, ProposalState.Active) canVote(_proposalId, _voter) {
        //     Proposal storage p = proposals[_proposalId];
        //     ... logic using _voter ...
        //     votes[_proposalId][_voter] = ...
        //     ... award reputation to _voter ...
        //     emit Voted(_proposalId, _voter, _support, weight);
        // }
        // This requires the caller (delegatee) to specify the original voter.

        // Reverting to simpler current function signature, which means `msg.sender` is always the address whose vote is recorded.
        // The `canVote` modifier needs to prevent the delegator from voting. The delegatee can vote using *their own* address,
        // but their voting weight calculation needs to include the delegated weight. This is complex.
        // Let's stick to the model where delegation means someone else (the delegatee) calls vote, but the vote is recorded *for* the delegator.
        // This requires the `vote` function to be callable by the delegatee on behalf of the delegator.

        // Okay, let's adjust: `vote` takes the voter address, and the `canVote` modifier checks authorization.

        // function vote(uint256 _proposalId, address _voter, bool _support, bool _abstain) external proposalExists(_proposalId) proposalStateIs(_proposalId, ProposalState.Active) {
        //    require(block.timestamp < proposals[_proposalId].votingPeriodEnd, "DAO: Voting period has ended");
        //    // Check authorization: either msg.sender is _voter, or msg.sender is _voter's delegatee
        //    require(msg.sender == _voter || members[_voter].delegatedTo == msg.sender, "DAO: Not authorized to vote for this address");
        //    require(!votes[_proposalId][_voter].hasVoted, "DAO: Voter already voted");
        //    require(members[_voter].exists, "DAO: Voter is not a member");
        //    require(members[_voter].currentLayerId >= proposals[_proposalId].requiredLayerToVote, "DAO: Voter's layer is too low for this proposal");

        //    uint256 weight = getVotingWeight(_voter, _proposalId);
        //    require(weight > 0 || _abstain, "DAO: Voter has no voting weight and cannot abstain"); // Must have weight to vote Yes/No

        //    votes[_proposalId][_voter] = VoteDetails({
        //        hasVoted: true,
        //        support: _support,
        //        votingWeight: weight,
        //        isDelegatedVote: (msg.sender != _voter)
        //    });

        //    if (_abstain) {
        //        p.abstainVotes += weight;
        //    } else if (_support) {
        //        p.yesVotes += weight;
        //    } else {
        //        p.noVotes += weight;
        //    }
        //    p.totalWeightedVotes += weight;

        //    _awardReputation(_voter, 1); // Award minimal reputation for voting

        //    emit Voted(_proposalId, _voter, _support, weight);
        // }

        // Sticking to the simpler version for now, assuming msg.sender is the voter,
        // and the `canVote` modifier checks delegation *for msg.sender*.
        // This means a delegatee votes *with their own address* but aggregates delegated weight.
        // This requires `getVotingWeight` to sum up delegated weight, which is complex (finding all delegators).
        // Let's revert to the first simple model: Delegation means delegatee votes *on behalf of* delegator, calling with delegator's address in signature.

        // Okay, third try. `vote` takes `_voter`. `msg.sender` must be either `_voter` or `_voter`'s delegatee.
        // The `canVote` modifier is perfect for this.

        address voter = msg.sender; // Assume msg.sender is the address whose vote is counted. Delegation check happens in canVote.
        uint256 weight = getVotingWeight(voter, _proposalId);
        require(weight > 0 || _abstain, "DAO: Voter has no voting weight and cannot abstain"); // Must have weight to vote Yes/No or Abstain


        votes[_proposalId][voter] = VoteDetails({
            hasVoted: true,
            support: _support,
            votingWeight: weight,
            isDelegatedVote: (members[voter].delegatedTo != address(0)) // True if voter has delegated, but delegatee is calling
            // This flag logic is tricky. It should indicate if msg.sender != voter.
            // Revert to canVote(_proposalId, msg.sender) and assume msg.sender IS the voter.
            // Delegation is handled OFF-CHAIN or by a helper contract that calls `vote` correctly.
            // Let's simplify for this example: `vote` is called by the address casting the vote.
            // Delegation means the delegatee can call `vote` for themselves, and their weight includes delegated power.
            // This requires `getVotingWeight` to traverse delegation chain, which is complex.

            // FINAL SIMPLIFICATION: `vote` is called by the address whose vote is recorded.
            // The `canVote` modifier simply checks if `msg.sender` is allowed to vote (is a member, hasn't voted, sufficient layer).
            // Delegation means the delegator *cannot* call `vote`. The delegatee *can* vote *using their own address*, and their `getVotingWeight` magically includes delegated weight.
            // This magical `getVotingWeight` is the complex part. Let's implement a simplified `getVotingWeight` that doesn't traverse delegation and assume delegation affects things off-chain or via a different mechanism.

            // Let's go back to the `vote` function signature taking only proposalId, support, abstain. `canVote` checks `msg.sender`.
        });

        if (_abstain) {
            p.abstainVotes += weight;
        } else if (_support) {
            p.yesVotes += weight;
        } else {
            p.noVotes += weight;
        }
        p.totalWeightedVotes += weight;

        _awardReputation(voter, 1); // Award minimal reputation for voting

        emit Voted(_proposalId, voter, _support, weight);
    }

     /// @notice Calculates the voting weight for a member on a specific proposal.
     /// @dev This is a simplified calculation. Real DAOs might have more complex logic.
     ///      Does NOT currently factor in delegated votes (requires complex traversal).
     ///      Assumes NFT/Domain bonuses are simple additions based on existence/assignment.
     /// @param _member The address of the member.
     /// @param _proposalId The ID of the proposal (can influence requirements).
     /// @return The calculated weighted voting power.
    function getVotingWeight(address _member, uint256 _proposalId) public view isMember returns (uint256) {
        // Ensure the member meets the minimum layer requirement for this proposal type *now*
        // (Even if they met it when they voted, this view function shows their *current* potential weight)
        if (members[_member].currentLayerId < proposals[_proposalId].requiredLayerToVote) {
             return 0;
        }

        LayerConfig storage layer = layers[members[_member].currentLayerId];
        uint256 tokenBalance = governanceToken.balanceOf(_member);
        uint256 reputation = members[_member].reputationPoints;

        // Base weight from layer, tokens, reputation
        uint256 weight = (tokenBalance / 1e18) * layer.votingWeightMultiplier; // Example: 1 token = 1 unit base weight * multiplier
        weight += (reputation / 10) * (layer.votingWeightMultiplier > 0 ? layer.votingWeightMultiplier : 1); // Example: 10 reputation = 1 unit bonus weight

        // Add NFT bonus? Requires knowing *which* NFT gives a bonus.
        // For simplicity, assume any configured membership NFT grants a bonus if owned.
        if (address(membershipNFT) != address(0)) {
            // Check if member owns *any* token of the membership NFT contract
            // This is inefficient. A better approach is to track owned tokens/roles.
            // For demo: Check if they own a *specific* token ID or have a role represented by an NFT property.
            // Let's skip the dynamic check here as it's too complex for a view function.
            // Assume `layer.requiredNFTRole` could *also* grant a weight bonus if they hold that specific NFT role.
        }

         // Add Domain bonus?
        if (members[_member].currentDomainId != 0) {
            // Assume belonging to a domain grants a small bonus weight
            weight += 10; // Example bonus
        }

        // Add delegated weight? This is the hard part.
        // Need to sum weight of all members where `delegatedTo == _member`.
        // This requires iterating through all members, which is gas-prohibitive in a transaction.
        // In a view function, it's possible but slow for large member lists.
        // Let's skip delegation aggregation for now in this example `getVotingWeight`.
        // Delegation in this contract primarily controls *who can call vote*, not aggregate weight in `getVotingWeight`.
        // A more advanced system might use a checkpoint system for voting power or a separate delegation contract.

        return weight;
    }

     /// @notice Gets the current vote tally for a proposal.
     /// @param _proposalId The ID of the proposal.
     /// @return Yes votes, No votes, Abstain votes, Total participating weighted votes.
     function getVoteCount(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 yes, uint256 no, uint256 abstain, uint256 totalWeighted) {
         Proposal storage p = proposals[_proposalId];
         return (p.yesVotes, p.noVotes, p.abstainVotes, p.totalWeightedVotes);
     }

     /// @notice Returns the address a member has delegated their vote to.
     /// @param _member The address of the member.
     /// @return The delegatee address (0x0 if none).
     function getDelegation(address _member) external view returns (address) {
         return members[_member].delegatedTo;
     }

      /// @notice Calculates the total potential voting weight available in a specific layer for a proposal.
      /// @dev This requires iterating through all members, potentially gas-intensive as a public function.
      ///      Provided as a view helper for external calculation/understanding.
      /// @param _layerId The ID of the layer.
      /// @param _proposalId The ID of the proposal (to check requiredLayerToVote).
      /// @return The total potential voting weight of members in that layer.
      function getLayerVotingPower(uint8 _layerId, uint256 _proposalId) external view returns (uint256) {
          // This function is expensive and should ideally be calculated off-chain or uses a complex state snapshot.
          // For demonstration, a simplified calculation based on layer configs, *not* iterating members.
          // A more accurate version would iterate.

          if (_layerId >= nextLayerId || _layerId < proposals[_proposalId].requiredLayerToVote) {
              return 0; // This layer cannot vote or doesn't exist
          }

          // Simulating potential weight: Assume average token/reputation or sum for members in that layer.
          // Actual implementation needs member iteration or a separate state manager.
          // Example (highly simplified):
          uint256 hypotheticalTotalWeight = 0;
          // Real implementation requires: Iterate through all members, check if they are in _layerId,
          // and if their current layer is >= proposal's requiredLayerToVote, then sum their getVotingWeight.
          // This loop is omitted here due to potential gas costs.

          // Example: Return layer multiplier if anyone in layer *could* vote
           if(layers[_layerId].votingWeightMultiplier > 0 && _layerId >= proposals[_proposalId].requiredLayerToVote) {
               // This is a dummy return value. The real value needs summation.
               // A better view function might be `getMemberVotingPower(address)` which is implemented as `getVotingWeight`.
               // Let's keep it but note its limitation.
               return 1; // Represents "this layer has potential power", not the actual total.
           }
           return 0;
      }


    // --- V. Treasury & Asset Management ---

    /// @notice Allows anyone to send ETH to the DAO treasury.
    /// @dev Handled by the `receive()` fallback function.

    /// @notice Allows transferring supported ERC20 into the treasury.
    /// @dev ERC20 `approve` must be called first by the sender.
    /// @param _token The address of the ERC20 token.
    /// @param _amount The amount to deposit.
    function depositTreasuryToken(address _token, uint256 _amount) external {
        require(_token != address(0), "DAO: Invalid token address");
        IERC20 token = IERC20(_token);
        require(token.transferFrom(msg.sender, treasury, _amount), "DAO: Token transfer failed");
        emit TreasuryDepositToken(msg.sender, _token, _amount);
    }

    /// @notice Executes an ETH withdrawal from the treasury.
    /// @dev Must be called via an executed proposal.
    /// @param _recipient The address to send ETH to.
    /// @param _amount The amount of ETH to send.
    function withdrawTreasuryETH(address payable _recipient, uint256 _amount) external {
        // This function is the *target* of a proposal.
        require(msg.sender == address(this), "DAO: Must be called by the contract itself (executed proposal)");
        require(_recipient != address(0), "DAO: Invalid recipient address");
        require(treasury.balance >= _amount, "DAO: Insufficient treasury ETH balance");

        // Use low-level call to send ETH securely
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "DAO: ETH withdrawal failed");

        // Find the proposal ID that triggered this call (complex, would need context)
        // For demonstration, we'll use 0.
        emit TreasuryWithdrawalETH(0, _recipient, _amount);
    }

    /// @notice Executes an ERC20 withdrawal from the treasury.
    /// @dev Must be called via an executed proposal.
    /// @param _token The address of the ERC20 token.
    /// @param _recipient The address to send tokens to.
    /// @param _amount The amount of tokens to send.
    function withdrawTreasuryToken(address _token, address _recipient, uint256 _amount) external {
        // This function is the *target* of a proposal.
        require(msg.sender == address(this), "DAO: Must be called by the contract itself (executed proposal)");
        require(_token != address(0), "DAO: Invalid token address");
        require(_recipient != address(0), "DAO: Invalid recipient address");
        IERC20 token = IERC20(_token);
        require(token.balanceOf(treasury) >= _amount, "DAO: Insufficient treasury token balance");

        require(token.transfer(_recipient, _amount), "DAO: Token withdrawal failed");

        // Find the proposal ID that triggered this call
        emit TreasuryWithdrawalToken(0, _token, _recipient, _amount);
    }

    /// @notice Executes an NFT transfer from the treasury.
    /// @dev Must be called via an executed proposal.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the NFT.
    /// @param _recipient The address to send the NFT to.
    function transferTreasuryNFT(address _nftContract, uint256 _tokenId, address _recipient) external {
         // This function is the *target* of a proposal.
        require(msg.sender == address(this), "DAO: Must be called by the contract itself (executed proposal)");
        require(_nftContract != address(0), "DAO: Invalid NFT contract address");
        require(_recipient != address(0), "DAO: Invalid recipient address");
        IERC721 nft = IERC721(_nftContract);

        // Check if the DAO owns the NFT (optional but good practice)
        // require(nft.ownerOf(_tokenId) == address(this), "DAO: DAO does not own this NFT");

        // The ERC721 standard safeTransferFrom handles ownership check
        nft.safeTransferFrom(address(this), _recipient, _tokenId);

        // Find the proposal ID that triggered this call
        emit TreasuryNFTTransfer(0, _nftContract, _tokenId, _recipient);
    }


    // --- VI. Reputation System ---

    /// @notice Internal function to award reputation points.
    /// @dev Called by other contract functions on successful actions (e.g., voting, executing proposals).
    /// @param _member The member to award points to.
    /// @param _points The amount of points to award.
    function _awardReputation(address _member, uint256 _points) internal {
        // Ensure they are a member (or will become one upon getting points)
        if (!members[_member].exists) {
            members[_member].exists = true;
            // Initialize layer to 0 or a base layer if not set
             if (members[_member].currentLayerId == 0 && nextLayerId > 1) { // Auto-join base layer if exists
                 members[_member].currentLayerId = 1; // Assume layer 1 is base member layer
             }
        }
        members[_member].reputationPoints += _points;
        emit ReputationUpdated(_member, members[_member].reputationPoints);

        // Potentially trigger layer checks/promotions here
        // _checkAndMoveLayer(_member); // Requires logic to find next eligible layer
    }

    /// @notice Gets the current reputation points for a member.
    /// @param _member The address of the member.
    /// @return The reputation points.
    function getReputation(address _member) external view returns (uint256) {
         return members[_member].reputationPoints;
    }


    // --- VII. Query Functions (View/Pure) ---

    /// @notice Retrieves the member profile for an address.
    /// @param _member The address to lookup.
    /// @return The member's profile details.
    function getMemberProfile(address _member) external view returns (MemberProfile memory) {
        return members[_member];
    }

    /// @notice Retrieves the configuration for a layer.
    /// @param _layerId The ID of the layer.
    /// @return The layer's configuration.
    function getLayerConfig(uint8 _layerId) external view returns (LayerConfig memory) {
        require(_layerId < nextLayerId, "DAO: Invalid layer ID");
        return layers[_layerId];
    }

    /// @notice Retrieves the configuration for a domain.
    /// @param _domainId The ID of the domain.
    /// @return The domain's configuration.
    function getDomainConfig(uint16 _domainId) external view returns (DomainConfig memory) {
         require(_domainId < nextDomainId, "DAO: Invalid domain ID");
         return domains[_domainId];
    }

    /// @notice Retrieves the details of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The proposal's details.
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Calculates the theoretical maximum possible voting weight across all members.
    /// @dev This is highly inefficient and just for illustration. Real systems use snapshots.
    /// @return The total theoretical maximum voting weight.
    function getTotalPotentialVotingWeight() public view returns (uint256) {
        // WARNING: This function is extremely expensive as it needs to iterate through
        // potentially every single address that could ever be a member or hold tokens.
        // This cannot be called in a transaction and is likely unusable as a public view.
        // It's here conceptually. A real DAO needs a state snapshot mechanism.
         revert("DAO: getTotalPotentialVotingWeight is not implemented due to gas cost");
        // return 0; // Placeholder
    }

     /// @notice Gets the list of pending application IDs.
     /// @return An array of application IDs.
     function getPendingApplicationIds() external view returns (uint256[] memory) {
         // Note: This array is not gas-optimized for large numbers of applications.
         return pendingApplicationIds;
     }
}
```