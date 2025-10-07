This smart contract, `SynergyNet`, is designed to be a cutting-edge protocol for on-chain identity, reputation, and collaborative governance. It introduces novel concepts to manage decentralized influence and foster active participation.

---

## SynergyNet Protocol: On-chain Adaptive Identity & Collaborative Intelligence Network

This contract establishes an advanced on-chain identity and collaborative intelligence network. It leverages "Soulbound Attributes" (SBAs) for persistent, attested skills/roles and "Synergy Points" (SPs) for active, decaying influence. The protocol enables dynamic, skill-based delegated governance and facilitates collaborative decision-making through specialized modules.

### Core Concepts:

1.  **Soulbound Attributes (SBAs):** Non-transferable, attestable, revocable, and potentially expiring tokens representing specific skills, certifications, or achievements. They form the basis of a user's on-chain persona and expertise.
2.  **Synergy Points (SPs):** A transferable utility token whose effective balance decays linearly over time if not actively used, encouraging continuous engagement and contribution. SPs are earned through participation and successful contributions to the network.
3.  **Adaptive Skill-based Governance:** Voting power is dynamically calculated based on a user's *effective* SP balance and the relevance of their held SBAs to a specific proposal's context. It supports granular delegation, allowing users to delegate influence for specific domains or generally.
4.  **Collaborative Intelligence Modules:** An extensible framework to integrate specialized applications (e.g., decentralized research, bug bounties, content curation) that leverage the core identity and influence system for decision-making, reward distribution, and spam prevention.

### Roles:

*   **`DEFAULT_ADMIN_ROLE`**: Protocol administrators, responsible for core configuration, contract upgrades (if proxied), and emergency functions.
*   **`ATTESTOR_ROLE`**: Entities approved to grant and revoke Soulbound Attributes, validating user claims or achievements.
*   **`MODULE_ROLE`**: Registered external smart contracts that can interact with SynergyNet for specific functions, such as minting Synergy Points for contributions within their module.

### Functions Summary (26 Functions):

**A. Core Protocol Administration (5 Functions)**
1.  `constructor`: Initializes the protocol with basic settings, the SP token address, and initial parameters.
2.  `updateSynergyPointDecayParams`: Adjusts the decay rate and unit time for Synergy Points (requires `DEFAULT_ADMIN_ROLE`).
3.  `addContextModule`: Registers a new specialized module with a unique `contextId` and grants it `MODULE_ROLE` (requires `DEFAULT_ADMIN_ROLE`).
4.  `removeContextModule`: Deregisters an existing module and revokes its `MODULE_ROLE` (requires `DEFAULT_ADMIN_ROLE`).
5.  `setFeeRecipient`: Sets the address that receives protocol-related fees (requires `DEFAULT_ADMIN_ROLE`).

**B. Soulbound Attributes (SBAs) Management (9 Functions)**
6.  `defineNewSBA`: Creates a new Soulbound Attribute type with specified metadata like name, description, influence weight, and expiry duration (requires `DEFAULT_ADMIN_ROLE`).
7.  `updateSBADefinition`: Modifies the metadata of an existing SBA type (requires `DEFAULT_ADMIN_ROLE`).
8.  `attestSBA`: An approved attestor grants a specific SBA to a user, potentially with attached data (requires `ATTESTOR_ROLE`).
9.  `revokeSBAAttestation`: An attestor revokes a previously granted SBA from a user (requires `ATTESTOR_ROLE`).
10. `requestSBAAttestation`: Allows a user to formally request an SBA attestation, signaling their interest to attestors.
11. `addAttestor`: Grants `ATTESTOR_ROLE` to a new address (requires `DEFAULT_ADMIN_ROLE`).
12. `removeAttestor`: Revokes `ATTESTOR_ROLE` from an address (requires `DEFAULT_ADMIN_ROLE`).
13. `getUserSBAHoldings`: Retrieves all active SBAs held by a specific user (view function).
14. `getSBADetails`: Retrieves the definition details (metadata) of a specific SBA type (view function).

**C. Synergy Points (SPs) Management & Interaction (4 Functions)**
15. `mintSynergyPoints`: Mints new SPs to a user, typically called by a registered module to reward contributions within its context (requires `MODULE_ROLE`). A small fee is collected.
16. `getSynergyPointsBalance`: Calculates a user's *effective*, time-decayed, and unstaked SP balance (view function).
17. `stakeSynergyPoints`: Allows a user to stake SPs for purposes like creating a proposal or interacting with a module.
18. `unstakeSynergyPoints`: Allows a user to unstake previously staked SPs.

**D. Adaptive Governance & Delegation (7 Functions)**
19. `createProposal`: Initiates a new governance proposal, requiring an SP stake and defining its relevant context (user function).
20. `voteOnProposal`: Allows users to cast their vote on a proposal, with dynamic voting power calculated based on their SPs and relevant SBAs.
21. `delegateInfluence`: Delegates specific SBA-derived influence or general SP influence to another user for a particular context (user function).
22. `revokeDelegation`: Revokes a previously made delegation of influence (user function).
23. `getVotingPower`: Calculates a user's dynamic voting power for a given proposal/context, considering their SPs, SBAs, and delegations (view function).
24. `resolveProposal`: Finalizes a governance proposal after the voting period ends, determining its outcome (requires `DEFAULT_ADMIN_ROLE`).
25. `getProposalDetails`: Retrieves all details of a specific governance proposal (view function).

**E. Utility & Verification (1 Function)**
26. `checkSBAStatus`: Verifies if a user currently holds an active, non-expired instance of a specific SBA (view function).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Custom SafeMath for clarity and to potentially extend with more complex math if needed
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract SynergyNet is AccessControl {
    using SafeMath for uint256;

    // --- State Variables ---

    // Roles
    bytes32 public constant ATTESTOR_ROLE = keccak256("ATTESTOR_ROLE");
    bytes32 public constant MODULE_ROLE = keccak256("MODULE_ROLE");

    // Synergy Points (SP)
    IERC20 public synergyPointsToken;
    uint256 public spDecayRateBps;       // Decay rate in basis points (e.g., 100 for 1%)
    uint256 public spDecayUnitTime;      // Time unit in seconds for decay (e.g., 1 week = 604800)

    struct SynergyPointAccount {
        uint256 balance;                 // Actual current balance (after last decay application)
        uint64 lastActivityTimestamp;    // Timestamp of last balance update or activity for decay calculation
        uint256 stakedBalance;           // SPs currently staked in proposals/modules
    }
    mapping(address => SynergyPointAccount) private _synergyPointAccounts;

    // Soulbound Attributes (SBA)
    uint256 public nextSBAId;
    struct SBADefinition {
        string name;
        string description;
        uint256 baseInfluenceWeight;     // Base influence weight this SBA contributes to governance
        uint64 expiryDuration;           // 0 for no expiry, otherwise duration in seconds
        bytes32[] relevantContexts;      // Contexts where this SBA provides enhanced influence (e.g., bytes32("ResearchDAO"))
        bool isActive;                   // Can this SBA still be attested?
    }
    mapping(uint256 => SBADefinition) public sbaDefinitions;

    struct UserSBAAttestation {
        uint256 sbaId;                   // ID of the SBA definition
        address attestor;                // Who attested this SBA
        uint64 attestedAt;               // Timestamp of attestation
        uint64 expiresAt;                // Timestamp of expiry (0 if no expiry)
        bytes32 attestationDataHash;     // Hash of any off-chain proofs/data (e.g., IPFS URI of credential)
        bool active;                     // Is this specific attestation currently active? (can be revoked)
    }
    // user => sbaId => array of attestations (a user might have multiple attestations of the same SBA from different attestors)
    mapping(address => mapping(uint256 => UserSBAAttestation[])) public userSBAHoldings;

    // Context Modules (for specialized collaborative intelligence)
    // contextId => module address
    mapping(bytes32 => address) public contextModules;

    // Governance
    uint256 public nextProposalId;
    uint256 public minProposalStake;     // Minimum SPs required to create a proposal
    uint64 public proposalVotingPeriod;   // Default voting duration in seconds

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        uint256 stakedAmount;
        uint64 startTimestamp;
        uint64 endTimestamp;
        bytes32 proposalDataHash;        // Hash of IPFS URI or proposal details
        bytes32 contextId;               // Links to a specific module/domain for contextual voting power
        mapping(address => uint256) votesCast; // Stores raw vote weight cast by each voter
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        bool executed;
        bool passed;
        bool active;                     // Is the proposal still open for voting or resolution?
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Delegation of Influence
    // delegator => contextId (bytes32(0) for general SP influence) => delegate address
    mapping(address => mapping(bytes32 => address)) public delegations;

    // Fee Recipient
    address public feeRecipient;

    // --- Events ---
    event SynergyPointsMinted(address indexed recipient, uint256 amount, bytes32 indexed contextId);
    event SynergyPointsStaked(address indexed staker, uint256 amount, uint256 indexed entityId); // entityId could be proposalId or module-specific
    event SynergyPointsUnstaked(address indexed staker, uint256 amount, uint256 indexed entityId);
    event SBADefined(uint256 indexed sbaId, string name, address indexed creator);
    event SBAAttested(address indexed recipient, uint256 indexed sbaId, address indexed attestor, uint64 expiresAt);
    event SBARevoked(address indexed recipient, uint256 indexed sbaId, address indexed attestor);
    event SBAAttestationRequested(address indexed requester, uint256 indexed sbaId, bytes32 attestationDataHash);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 indexed contextId, uint256 stake);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 voteWeight, bool support);
    event InfluenceDelegated(address indexed delegator, address indexed delegate, bytes32 indexed contextId);
    event InfluenceRevoked(address indexed delegator, address indexed delegate, bytes32 indexed contextId);
    event ContextModuleAdded(bytes32 indexed contextId, address indexed moduleAddress);
    event ProposalResolved(uint256 indexed proposalId, bool passed);

    // --- Constructor ---
    // 1. constructor: Initializes the protocol with basic settings and the SP token address.
    constructor(
        address _spTokenAddress,
        uint256 _initialSPDecayRateBps,
        uint256 _initialSPDecayUnitTime,
        uint256 _minProposalStake,
        uint64 _proposalVotingPeriod,
        address _feeRecipient
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        synergyPointsToken = IERC20(_spTokenAddress);
        spDecayRateBps = _initialSPDecayRateBps;
        spDecayUnitTime = _initialSPDecayUnitTime;
        minProposalStake = _minProposalStake;
        proposalVotingPeriod = _proposalVotingPeriod;
        feeRecipient = _feeRecipient;
        nextSBAId = 1;
        nextProposalId = 1;
    }

    // --- Internal Utility Functions ---

    // Internal function to update a user's Synergy Point account, applying linear decay
    // This function is called before any operation that reads or modifies the raw balance.
    function _updateSynergyPointsAccount(address user) internal {
        SynergyPointAccount storage account = _synergyPointAccounts[user];
        uint64 currentTime = uint64(block.timestamp);

        if (account.lastActivityTimestamp == 0) { // First interaction for this account, initialize timestamp
            account.lastActivityTimestamp = currentTime;
            return;
        }

        uint256 timeElapsed = currentTime.sub(account.lastActivityTimestamp);

        // Apply linear decay approximation (capped at current balance)
        // decayAmount = currentBalance * decayRateBps * timeElapsed / (10000 * decayUnitTime)
        if (timeElapsed > 0 && account.balance > 0 && spDecayRateBps > 0 && spDecayUnitTime > 0) {
            uint256 decayAmount = account.balance
                .mul(spDecayRateBps)
                .mul(timeElapsed)
                .div(10000)
                .div(spDecayUnitTime);

            account.balance = account.balance.sub(decayAmount > account.balance ? account.balance : decayAmount);
        }
        account.lastActivityTimestamp = currentTime; // Reset last activity timestamp
    }

    // --- A. Core Protocol Administration ---

    // 2. updateSynergyPointDecayParams: Adjusts the decay rate and unit time for Synergy Points (DEFAULT_ADMIN_ROLE).
    function updateSynergyPointDecayParams(uint256 _newDecayRateBps, uint256 _newDecayUnitTime)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newDecayRateBps <= 10000, "Decay rate cannot exceed 10000 bps (100%)");
        require(_newDecayUnitTime > 0, "Decay unit time must be positive");
        spDecayRateBps = _newDecayRateBps;
        spDecayUnitTime = _newDecayUnitTime;
    }

    // 3. addContextModule: Registers a new specialized module with a unique context ID (DEFAULT_ADMIN_ROLE).
    function addContextModule(bytes32 _contextId, address _moduleAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_moduleAddress != address(0), "Module address cannot be zero");
        require(contextModules[_contextId] == address(0), "Context ID already registered");
        contextModules[_contextId] = _moduleAddress;
        _grantRole(MODULE_ROLE, _moduleAddress); // Grant MODULE_ROLE to the new module for SP minting etc.
        emit ContextModuleAdded(_contextId, _moduleAddress);
    }

    // 4. removeContextModule: Deregisters an existing module (DEFAULT_ADMIN_ROLE).
    function removeContextModule(bytes32 _contextId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address moduleAddr = contextModules[_contextId];
        require(moduleAddr != address(0), "Context ID not registered");
        delete contextModules[_contextId];
        _revokeRole(MODULE_ROLE, moduleAddr); // Revoke MODULE_ROLE
    }

    // 5. setFeeRecipient: Sets the address for protocol fees (DEFAULT_ADMIN_ROLE).
    function setFeeRecipient(address _newFeeRecipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newFeeRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = _newFeeRecipient;
    }

    // --- B. Soulbound Attributes (SBAs) Management ---

    // 6. defineNewSBA: Creates a new Soulbound Attribute type with specified metadata (DEFAULT_ADMIN_ROLE).
    function defineNewSBA(
        string calldata _name,
        string calldata _description,
        uint256 _baseInfluenceWeight,
        uint64 _expiryDuration,
        bytes32[] calldata _relevantContexts
    ) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 sbaId) {
        sbaId = nextSBAId++;
        sbaDefinitions[sbaId] = SBADefinition({
            name: _name,
            description: _description,
            baseInfluenceWeight: _baseInfluenceWeight,
            expiryDuration: _expiryDuration,
            relevantContexts: _relevantContexts,
            isActive: true
        });
        emit SBADefined(sbaId, _name, _msgSender());
    }

    // 7. updateSBADefinition: Modifies the metadata of an existing SBA type (DEFAULT_ADMIN_ROLE).
    function updateSBADefinition(
        uint256 _sbaId,
        string calldata _name,
        string calldata _description,
        uint256 _baseInfluenceWeight,
        uint64 _expiryDuration,
        bytes32[] calldata _relevantContexts,
        bool _isActive
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(sbaDefinitions[_sbaId].baseInfluenceWeight > 0 || sbaDefinitions[_sbaId].isActive == false, "SBA not defined or already removed");
        sbaDefinitions[_sbaId].name = _name;
        sbaDefinitions[_sbaId].description = _description;
        sbaDefinitions[_sbaId].baseInfluenceWeight = _baseInfluenceWeight;
        sbaDefinitions[_sbaId].expiryDuration = _expiryDuration;
        sbaDefinitions[_sbaId].relevantContexts = _relevantContexts;
        sbaDefinitions[_sbaId].isActive = _isActive;
    }

    // 8. attestSBA: An approved attestor grants a specific SBA to a user (ATTESTOR_ROLE).
    function attestSBA(
        address _recipient,
        uint256 _sbaId,
        bytes32 _attestationDataHash
    ) public onlyRole(ATTESTOR_ROLE) {
        SBADefinition storage sbaDef = sbaDefinitions[_sbaId];
        require(sbaDef.isActive, "SBA is not active for attestation");
        require(_recipient != address(0), "Recipient cannot be zero address");

        uint64 attestedAt = uint64(block.timestamp);
        uint64 expiresAt = sbaDef.expiryDuration > 0 ? attestedAt.add(sbaDef.expiryDuration) : 0;

        // Prevent an attestor from giving the same active SBA to the same recipient more than once
        for(uint i=0; i < userSBAHoldings[_recipient][_sbaId].length; i++) {
            UserSBAAttestation storage existingAttestation = userSBAHoldings[_recipient][_sbaId][i];
            if (existingAttestation.attestor == _msgSender() && existingAttestation.active && (existingAttestation.expiresAt == 0 || existingAttestation.expiresAt > block.timestamp)) {
                revert("Recipient already has an active attestation for this SBA from this attestor.");
            }
        }

        userSBAHoldings[_recipient][_sbaId].push(UserSBAAttestation({
            sbaId: _sbaId,
            attestor: _msgSender(),
            attestedAt: attestedAt,
            expiresAt: expiresAt,
            attestationDataHash: _attestationDataHash,
            active: true
        }));

        emit SBAAttested(_recipient, _sbaId, _msgSender(), expiresAt);
    }

    // 9. revokeSBAAttestation: An attestor revokes a previously granted SBA (ATTESTOR_ROLE).
    function revokeSBAAttestation(address _recipient, uint256 _sbaId) public onlyRole(ATTESTOR_ROLE) {
        bool revoked = false;
        UserSBAAttestation[] storage attestations = userSBAHoldings[_recipient][_sbaId];
        for (uint i = 0; i < attestations.length; i++) {
            if (attestations[i].attestor == _msgSender() && attestations[i].active) {
                attestations[i].active = false; // Mark as inactive
                revoked = true;
                break; // Assuming one active attestation per attestor per SBA is sufficient to revoke
            }
        }
        require(revoked, "No active attestation found for this SBA by this attestor for the recipient.");
        emit SBARevoked(_recipient, _sbaId, _msgSender());
    }

    // 10. requestSBAAttestation: A user can formally request an SBA attestation (user function).
    // This function doesn't grant the SBA directly but logs a request for an attestor to review.
    // An external UI/system would monitor these requests and allow attestors to act.
    function requestSBAAttestation(uint256 _sbaId, bytes32 _attestationDataHash) public {
        require(sbaDefinitions[_sbaId].isActive, "SBA is not active for requests");
        // Further logic could involve staking tokens or more complex request workflows
        emit SBAAttestationRequested(_msgSender(), _sbaId, _attestationDataHash);
    }

    // 11. addAttestor: Grants ATTESTOR_ROLE to a new address (DEFAULT_ADMIN_ROLE).
    function addAttestor(address _attestorAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ATTESTOR_ROLE, _attestorAddress);
    }

    // 12. removeAttestor: Revokes ATTESTOR_ROLE from an address (DEFAULT_ADMIN_ROLE).
    function removeAttestor(address _attestorAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ATTESTOR_ROLE, _attestorAddress);
    }

    // 13. getUserSBAHoldings: Retrieves all active SBAs held by a specific user (view).
    // Returns a simplified view to avoid returning large dynamic arrays directly in Solidity.
    function getUserSBAHoldings(address _user)
        public
        view
        returns (uint256[] memory activeSBAIds, uint64[] memory activeExpiresAt)
    {
        uint256[] memory tempSBAIds = new uint256[](nextSBAId); // Max possible SBAs, temporary storage
        uint64[] memory tempExpiresAt = new uint64[](nextSBAId);
        uint256 count = 0;

        for (uint256 i = 1; i < nextSBAId; i++) {
            UserSBAAttestation[] storage attestations = userSBAHoldings[_user][i];
            for (uint j = 0; j < attestations.length; j++) {
                if (attestations[j].active && (attestations[j].expiresAt == 0 || attestations[j].expiresAt > block.timestamp)) {
                    tempSBAIds[count] = attestations[j].sbaId;
                    tempExpiresAt[count] = attestations[j].expiresAt;
                    count++;
                    break; // Only need one active attestation per SBA type to count as held
                }
            }
        }

        activeSBAIds = new uint256[](count);
        activeExpiresAt = new uint64[](count);
        for (uint i = 0; i < count; i++) {
            activeSBAIds[i] = tempSBAIds[i];
            activeExpiresAt[i] = tempExpiresAt[i];
        }
        return (activeSBAIds, activeExpiresAt);
    }

    // 14. getSBADetails: Retrieves the definition details of a specific SBA type (view).
    function getSBADetails(uint256 _sbaId)
        public
        view
        returns (
            string memory name,
            string memory description,
            uint256 baseInfluenceWeight,
            uint64 expiryDuration,
            bytes32[] memory relevantContexts,
            bool isActive
        )
    {
        SBADefinition storage sbaDef = sbaDefinitions[_sbaId];
        // Ensure the SBA exists (e.g. by checking if baseInfluenceWeight is 0 for an undefined SBA)
        require(sbaDef.baseInfluenceWeight > 0 || sbaDef.isActive == false, "SBA not defined"); // If isActive is false, it might exist but is just inactive.
        return (
            sbaDef.name,
    sbaDef.description,
            sbaDef.baseInfluenceWeight,
            sbaDef.expiryDuration,
            sbaDef.relevantContexts,
            sbaDef.isActive
        );
    }

    // --- C. Synergy Points (SPs) Management & Interaction ---

    // 15. mintSynergyPoints: Mints new SPs to a user, typically called by a registered module for contributions (MODULE_ROLE).
    function mintSynergyPoints(address _recipient, uint256 _amount, bytes32 _contextId)
        public
        onlyRole(MODULE_ROLE)
    {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_amount > 0, "Mint amount must be positive");
        require(contextModules[_contextId] == _msgSender(), "Only registered module can mint for its own context");

        _updateSynergyPointsAccount(_recipient); // Apply decay to recipient's existing balance before minting
        _synergyPointAccounts[_recipient].balance = _synergyPointAccounts[_recipient].balance.add(_amount);

        // A small percentage of minted SPs could go to the feeRecipient as protocol revenue
        uint256 fee = _amount.div(100); // 1% fee example
        uint256 netAmount = _amount.sub(fee);

        require(synergyPointsToken.transfer(feeRecipient, fee), "Failed to transfer fees.");
        require(synergyPointsToken.transfer(_recipient, netAmount), "Failed to transfer SPs.");
        emit SynergyPointsMinted(_recipient, _amount, _contextId);
    }

    // 16. getSynergyPointsBalance: Calculates a user's effective, time-decayed SP balance (view).
    function getSynergyPointsBalance(address _user) public view returns (uint256) {
        SynergyPointAccount storage account = _synergyPointAccounts[_user];
        uint64 currentTime = uint64(block.timestamp);

        if (account.lastActivityTimestamp == 0 || account.balance == 0) {
            return 0; // No activity or empty balance, effective balance is 0
        }

        uint256 timeElapsed = currentTime.sub(account.lastActivityTimestamp);

        if (timeElapsed == 0) { // No time elapsed since last update
            return account.balance.sub(account.stakedBalance);
        }

        // Apply linear decay approximation (capped at current balance)
        uint256 currentCalculatedBalance = account.balance;
        if (spDecayRateBps > 0 && spDecayUnitTime > 0) {
            uint256 decayAmount = currentCalculatedBalance
                .mul(spDecayRateBps)
                .mul(timeElapsed)
                .div(10000)
                .div(spDecayUnitTime);
            currentCalculatedBalance = currentCalculatedBalance.sub(decayAmount > currentCalculatedBalance ? currentCalculatedBalance : decayAmount);
        }
        // Return spendable balance (total balance minus staked)
        return currentCalculatedBalance.sub(account.stakedBalance > currentCalculatedBalance ? currentCalculatedBalance : account.stakedBalance);
    }

    // 17. stakeSynergyPoints: User stakes SPs for a proposal or module interaction (user function).
    function stakeSynergyPoints(uint256 _amount, uint256 _entityId) public {
        require(_amount > 0, "Stake amount must be positive");

        _updateSynergyPointsAccount(_msgSender()); // Apply decay before staking
        SynergyPointAccount storage account = _synergyPointAccounts[_msgSender()];
        require(account.balance.sub(account.stakedBalance) >= _amount, "Insufficient spendable SPs to stake");

        account.stakedBalance = account.stakedBalance.add(_amount);
        emit SynergyPointsStaked(_msgSender(), _amount, _entityId);
    }

    // 18. unstakeSynergyPoints: User unstakes previously staked SPs (user function).
    function unstakeSynergyPoints(uint256 _amount, uint256 _entityId) public {
        require(_amount > 0, "Unstake amount must be positive");

        // No decay application here, as unstaking doesn't count as "activity" for resetting decay.
        // The effective balance will reflect the new unstaked amount next time it's calculated by `getSynergyPointsBalance`.
        SynergyPointAccount storage account = _synergyPointAccounts[_msgSender()];
        require(account.stakedBalance >= _amount, "Not enough staked SPs to unstake");

        account.stakedBalance = account.stakedBalance.sub(_amount);
        emit SynergyPointsUnstaked(_msgSender(), _amount, _entityId);
    }

    // --- D. Adaptive Governance & Delegation ---

    // 19. createProposal: Initiates a new governance proposal, requiring SP stake and defining context (user function).
    function createProposal(
        bytes32 _proposalDataHash,
        bytes32 _contextId,
        uint64 _votingPeriodExtension // additional time for voting beyond default proposalVotingPeriod
    ) public {
        require(getSynergyPointsBalance(_msgSender()) >= minProposalStake, "Insufficient SPs to stake for proposal");
        if (_contextId != bytes32(0)) { // If a specific context is defined
            require(contextModules[_contextId] != address(0), "Context ID not registered for a module");
        }

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            stakedAmount: minProposalStake,
            startTimestamp: uint64(block.timestamp),
            endTimestamp: uint64(block.timestamp).add(proposalVotingPeriod).add(_votingPeriodExtension),
            proposalDataHash: _proposalDataHash,
            contextId: _contextId,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            passed: false,
            active: true
        });

        // Stake SPs automatically when creating a proposal
        stakeSynergyPoints(minProposalStake, proposalId);
        emit ProposalCreated(proposalId, _msgSender(), _contextId, minProposalStake);
    }

    // 20. voteOnProposal: Allows users to vote, with dynamic power based on SPs + relevant SBAs (user function).
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.active, "Proposal is not active");
        require(block.timestamp >= proposal.startTimestamp, "Voting has not started");
        require(block.timestamp <= proposal.endTimestamp, "Voting has ended");
        require(proposal.votesCast[_msgSender()] == 0, "Already voted on this proposal");

        address voter = _msgSender();
        // Resolve delegation: first context-specific, then general
        address effectiveVoter = delegations[voter][proposal.contextId] != address(0) ? delegations[voter][proposal.contextId] : voter;
        if (effectiveVoter == voter) { // If no context-specific delegation, check for general delegation
            effectiveVoter = delegations[voter][bytes32(0)] != address(0) ? delegations[voter][bytes32(0)] : voter;
        }

        uint256 votingPower = getVotingPower(effectiveVoter, proposal.contextId);
        require(votingPower > 0, "Voter has no voting power for this proposal context");

        proposal.votesCast[_msgSender()] = votingPower; // Record actual voter's power
        if (_support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(votingPower);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(votingPower);
        }
        emit VoteCast(_proposalId, _msgSender(), votingPower, _support);
    }

    // 21. delegateInfluence: Delegates specific SBA-derived or general SP influence for a context (user function).
    // Use `_contextId = bytes32(0)` for general SP influence delegation.
    function delegateInfluence(address _delegate, bytes32 _contextId) public {
        require(_delegate != address(0), "Delegate cannot be zero address");
        require(_delegate != _msgSender(), "Cannot delegate to yourself");
        require(delegations[_msgSender()][_contextId] == address(0), "Already delegated this context");
        delegations[_msgSender()][_contextId] = _delegate;
        emit InfluenceDelegated(_msgSender(), _delegate, _contextId);
    }

    // 22. revokeDelegation: Revokes a previous delegation (user function).
    function revokeDelegation(bytes32 _contextId) public {
        require(delegations[_msgSender()][_contextId] != address(0), "No active delegation found for this context");
        address revokedDelegate = delegations[_msgSender()][_contextId];
        delete delegations[_msgSender()][_contextId];
        emit InfluenceRevoked(_msgSender(), revokedDelegate, _contextId);
    }

    // 23. getVotingPower: Calculates a user's dynamic voting power for a given proposal/context (view).
    function getVotingPower(address _user, bytes32 _contextId) public view returns (uint256) {
        // Apply decay to get current SP balance (spendable)
        uint256 effectiveSP = getSynergyPointsBalance(_user); // This already reflects current balance minus staked

        uint256 sbaInfluenceWeight = 0;
        (uint256[] memory activeSBAIds, ) = getUserSBAHoldings(_user);

        for (uint i = 0; i < activeSBAIds.length; i++) {
            uint256 sbaId = activeSBAIds[i];
            SBADefinition storage sbaDef = sbaDefinitions[sbaId];

            bool isRelevantContext = false;
            // Check if SBA is generally relevant (contextId 0) or specific to the proposal context
            for (uint j = 0; j < sbaDef.relevantContexts.length; j++) {
                if (sbaDef.relevantContexts[j] == _contextId || sbaDef.relevantContexts[j] == bytes32(0)) {
                    isRelevantContext = true;
                    break;
                }
            }

            if (isRelevantContext) {
                sbaInfluenceWeight = sbaInfluenceWeight.add(sbaDef.baseInfluenceWeight);
            }
        }

        // Return combined power. This could be weighted differently (e.g., SPs * 1, SBAs * X)
        return effectiveSP.add(sbaInfluenceWeight);
    }

    // 24. resolveProposal: Finalizes a proposal, distributing rewards/penalties (DEFAULT_ADMIN_ROLE or MODULE_ROLE).
    function resolveProposal(uint252 _proposalId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Can be extended to allow MODULE_ROLE to resolve proposals specific to its context.
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.active, "Proposal is not active");
        require(block.timestamp > proposal.endTimestamp, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.active = false; // Mark proposal as no longer active for voting/resolution
        proposal.executed = true;

        // Example: Simple majority rule
        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            proposal.passed = true;
            // Return staked SPs to the proposer upon success
            unstakeSynergyPoints(proposal.stakedAmount, _proposalId);
        } else {
            proposal.passed = false;
            // Optionally: burn staked SPs or transfer to feeRecipient as a penalty for failed proposals
            // For now, if a proposal fails, the stake remains "staked" in the contract, effectively locking it.
        }
        emit ProposalResolved(_proposalId, proposal.passed);
    }

    // 25. getProposalDetails: Retrieves details of a specific governance proposal (view).
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            uint256 proposalId,
            address proposer,
            uint256 stakedAmount,
            uint64 startTimestamp,
            uint64 endTimestamp,
            bytes32 proposalDataHash,
            bytes32 contextId,
            uint256 totalVotesFor,
            uint256 totalVotesAgainst,
            bool executed,
            bool passed,
            bool active
        )
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposalId == _proposalId && proposal.proposer != address(0), "Proposal does not exist");
        return (
            proposal.proposalId,
            proposal.proposer,
            proposal.stakedAmount,
            proposal.startTimestamp,
            proposal.endTimestamp,
            proposal.proposalDataHash,
            proposal.contextId,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.executed,
            proposal.passed,
            proposal.active
        );
    }

    // --- E. Utility & Verification ---

    // 26. checkSBAStatus: Verifies if a user holds a specific, active SBA (view).
    function checkSBAStatus(address _user, uint256 _sbaId) public view returns (bool isActive) {
        // Ensure the SBA definition exists
        require(sbaDefinitions[_sbaId].baseInfluenceWeight > 0 || sbaDefinitions[_sbaId].isActive == false, "SBA definition does not exist");

        UserSBAAttestation[] storage attestations = userSBAHoldings[_user][_sbaId];
        for (uint i = 0; i < attestations.length; i++) {
            if (attestations[i].active && (attestations[i].expiresAt == 0 || attestations[i].expiresAt > block.timestamp)) {
                return true; // Found at least one active, non-expired attestation
            }
        }
        return false;
    }
}
```