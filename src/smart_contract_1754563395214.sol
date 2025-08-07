This smart contract, `AeternaVaultsDAO`, pioneers a decentralized system for managing "Digital Immortality Vaults" (DIVs). It enables users to securely store and conditionally release sensitive digital legacy information (like encrypted keys or access instructions for off-chain data) upon predefined, multi-factor trigger events. The entire system is governed by a Decentralized Autonomous Organization (DAO), allowing for community consensus on parameters, dispute resolution, and future enhancements.

The contract itself *does not store sensitive data*. Instead, it manages the *release* of a `releaseHash` (representing an encrypted key or access instructions) and a `vaultURI` (pointing to the off-chain encrypted data) to designated heirs, based on a combination of on-chain activity monitoring, specific timestamps, multi-signature confirmations, and external oracle proofs (e.g., proof of death).

---

## AeternaVaultsDAO Contract Outline

This contract, `AeternaVaultsDAO`, is a decentralized autonomous organization designed to manage "Digital Immortality Vaults" (DIVs). It facilitates the secure, conditional release of critical personal information, memories, last wishes, and digital asset access instructions upon predefined trigger events, governed by the DAO and integrated with potential oracle services. The contract itself does not store sensitive data, but manages the release of encrypted keys or access pointers (represented by `releaseHash` and `vaultURI`).

**I. Core Vault Management:** Functions for creating, updating, and managing the lifecycle of a digital vault.
**II. Heir & Beneficiary Management:** Functions for defining and managing the recipients of a vault's contents.
**III. Trigger & Release Mechanisms:** Complex, multi-factor conditions for activating a vault's release.
**IV. Proof-of-Life & Inactivity:** Mechanisms for vault owners to prove liveness and for others to challenge it.
**V. DAO Governance & Treasury:** Comprehensive system for community proposals, voting, and treasury management.
**VI. Dispute Resolution:** Framework for addressing disagreements regarding vault status or heir claims.
**VII. External Integrations (Oracle Interface):** Interfaces for integrating with decentralized oracle networks for external data.
**VIII. Utilities & View Functions:** Helper functions to retrieve contract state and details.

---

## Function Summary

**I. Core Vault Management**
1.  `createVault(string _vaultURI, bytes32 _initialReleaseHash, uint256 _inactivityDuration)`: Initializes a new Digital Immortality Vault for the caller, requiring a minimum deposit.
2.  `updateVaultURI(uint256 _vaultId, string _newVaultURI)`: Allows the vault owner to update the URI pointing to their off-chain encrypted data.
3.  `updateReleaseHash(uint256 _vaultId, bytes32 _newReleaseHash)`: Allows the vault owner to update the encrypted access key or hash, providing flexibility for key rotation.
4.  `closeVault(uint256 _vaultId)`: Allows the owner to irrevocably deactivate their vault, clear its associated data, and reclaim any associated deposits.

**II. Heir & Beneficiary Management**
5.  `addHeir(uint256 _vaultId, address _heirAddress, uint256 _proportionalShare, string _heirName)`: Designates a beneficiary for a vault, specifying their address, proportional share, and an optional name.
6.  `removeHeir(uint256 _vaultId, address _heirAddress)`: Removes a previously designated beneficiary from a vault.
7.  `updateHeirShare(uint256 _vaultId, address _heirAddress, uint256 _newShare)`: Adjusts a beneficiary's proportional share of the vault's eventual release.
8.  `heirClaimVault(uint256 _vaultId)`: Allows a designated heir to claim the vault's `releaseHash` once the vault has been activated by its trigger conditions.

**III. Trigger & Release Mechanisms**
9.  `setTriggerCondition(uint256 _vaultId, TriggerType _type, uint256 _value, address _oracleAddress, bytes _specificData)`: Configures specific, customizable conditions (e.g., inactivity period, specific timestamp, oracle proof, multi-signature witnesses, DAO consensus) that must be met for vault activation.
10. `addWitnessToVault(uint256 _vaultId, address _witnessAddress)`: Designates an address as a required multi-signature witness, whose confirmation contributes to a `MULTI_SIG_WITNESSES` trigger condition.
11. `confirmWitnessTrigger(uint256 _vaultId)`: Allows a designated witness to provide their confirmation towards the `MULTI_SIG_WITNESSES` trigger for a specific vault.
12. `checkAndActivateVault(uint256 _vaultId)`: A publicly callable function that evaluates all set trigger conditions for a vault and, if all are met, activates the vault, making its contents claimable.

**IV. Proof-of-Life & Inactivity**
13. `sendHeartbeat(uint256 _vaultId)`: The vault owner sends a periodic signal to confirm their liveness, resetting the inactivity timer and clearing any active liveness challenges.
14. `challengeLiveness(uint256 _vaultId, string _reason)`: Initiates a formal challenge against a vault owner's last heartbeat if they have been inactive for too long, potentially leading to a dispute process.

**V. DAO Governance & Treasury**
15. `submitProposal(string _description, address _targetContract, bytes _calldata)`: Allows any member to submit a proposal for the DAO to vote on, detailing a proposed action or contract modification.
16. `voteOnProposal(uint256 _proposalId, bool _for)`: Casts a vote (for or against) on an active governance proposal.
17. `executeProposal(uint256 _proposalId)`: Executes a proposal that has successfully passed its voting period and met the quorum requirements.
18. `depositToTreasury()`: Allows anyone to deposit Ether into the DAO's treasury, which can then be managed by DAO proposals.
19. `withdrawFromTreasury(address _tokenAddress, address _recipient, uint256 _amount)`: An internal function callable only by the DAO (via a passed proposal) to distribute ETH or ERC20 tokens from the treasury.

**VI. Dispute Resolution**
20. `raiseDispute(uint256 _vaultId, string _reason)`: Initiates a formal dispute process regarding a vault's status, claims, or a liveness challenge, requiring a small deposit.
21. `resolveDispute(uint256 _disputeId, bool _resolutionOutcome)`: An internal function callable by the DAO (via a passed proposal) to formally resolve an ongoing dispute, setting the final status of the disputed vault.
22. `submitOracleProof(uint256 _vaultId, bytes _proofData, bytes32 _requestId)`: Allows a pre-approved trusted oracle to submit definitive external data (e.g., proof of death) that fulfills an `ORACLE_PROOF_OF_DEATH` trigger condition for a vault.

**VII. External Integrations (Oracle Interface)**
23. `setTrustedOracle(address _oracleAddress, bool _isTrusted)`: An internal function callable by the DAO (via a passed proposal) to manage a whitelist of trusted oracle addresses authorized to submit proofs.
24. `receiveOracleData(uint256 _vaultId, bytes32 _requestId, bytes _response)`: A placeholder callback function for deeper oracle integrations (e.g., Chainlink's `fulfill` method), currently primarily handled via `submitOracleProof`.

**VIII. Utilities & View Functions**
25. `getVaultDetails(uint256 _vaultId)`: Retrieves all comprehensive details of a specific vault.
26. `getHeirs(uint256 _vaultId)`: Returns an array of all designated heir structs for a given vault.
27. `getTriggerConditions(uint256 _vaultId)`: Returns an array of all defined trigger conditions for a specific vault.
28. `getProposal(uint256 _proposalId)`: Retrieves all details about a specific governance proposal.
29. `getVaultsByOwner(address _owner)`: Returns an array of all vault IDs owned by a specific address.
30. `getChallengeDetails(uint256 _vaultId)`: Retrieves details about any active liveness challenge associated with a vault.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential stablecoin deposits
// ECDSA is imported but not strictly used in this version for simplicity,
// but would be vital for signature-based proofs or advanced identity.

/**
 * @title AeternaVaultsDAO
 * @dev A decentralized autonomous organization for managing "Digital Immortality Vaults" (DIVs).
 *      It allows users to define conditional release mechanisms for digital assets/information
 *      upon specific trigger events, governed by a community DAO.
 *      The contract does not store sensitive data, only release instructions (hashes/URIs).
 */
contract AeternaVaultsDAO is Ownable {
    // --- State Variables ---

    uint256 public nextVaultId;
    mapping(uint256 => Vault) public vaults;
    mapping(uint256 => Heir[]) public vaultHeirs; // vaultId => array of heirs
    mapping(uint256 => TriggerCondition[]) public vaultTriggerConditions; // vaultId => array of conditions
    mapping(uint256 => mapping(address => bool)) public vaultWitnesses; // vaultId => witnessAddress => isWitness
    mapping(uint256 => mapping(address => bool)) public witnessConfirmations; // vaultId => witnessAddress => hasConfirmed (for multi-sig)

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    // For simple 1 address = 1 vote. Could be enhanced with ERC20/ERC721 token-based voting.
    mapping(address => uint256) public daoMemberVotes; // Tracks how many votes an address has cast (for future voting power calc)

    mapping(address => bool) public trustedOracles; // Addresses authorized to submit oracle proofs
    mapping(uint256 => Challenge) public livenessChallenges; // vaultId => Challenge
    uint256 public nextDisputeId;
    mapping(uint256 => Dispute) public disputes;

    // DAO Configuration Parameters (set by owner initially, modifiable by DAO proposals)
    uint256 public minVaultDeposit = 0.01 ether; // Minimum ETH deposit for vault creation and dispute raising
    uint256 public proposalQuorumPercentage = 51; // Percentage of 'for' votes out of total votes needed for proposal to pass (e.g., 51 for 51%)
    uint256 public votingPeriodDuration = 3 days; // Duration for voting on proposals
    uint256 public heartbeatInterval = 30 days; // Max time between heartbeats before a vault is considered inactive/challengeable
    uint256 public challengeResponsePeriod = 7 days; // Time for an owner to respond to a liveness challenge

    // --- Data Structures ---

    enum VaultStatus { PENDING, ACTIVE, INACTIVE, RELEASED, DISPUTED }
    enum TriggerType {
        INACTIVITY_DURATION,       // Vault activates if owner is inactive for a set duration
        SPECIFIC_TIMESTAMP,        // Vault activates at a specific Unix timestamp
        ORACLE_PROOF_OF_DEATH,     // Vault activates upon proof of death from a trusted oracle
        MULTI_SIG_WITNESSES,       // Vault activates when a required number of designated witnesses confirm
        DAO_CONSENSUS              // Vault activates upon direct DAO vote/proposal execution
    }
    enum ChallengeStatus { NONE, CHALLENGED, RESPONDED, FAILED_RESPONSE, RESOLVED }
    enum DisputeStatus { OPEN, RESOLVED_FOR_CHALLENGER, RESOLVED_FOR_OWNER }

    struct Vault {
        address owner;
        uint256 creationTime;
        uint256 lastHeartbeatTime;
        uint256 inactivityDuration; // Default or configured inactivity trigger
        bool isActivated; // True if all conditions for release have been met
        VaultStatus status;
        string vaultURI; // IPFS/Arweave hash of encrypted data description/pointers
        bytes32 releaseHash; // Hash of the encrypted key or access instructions
        uint256 depositAmount; // ETH deposit for maintenance/security
        uint256 totalWitnessesRequired; // For MULTI_SIG_WITNESSES trigger, number of confirmations needed
        uint256 confirmedWitnesses; // Current count of witness confirmations
    }

    struct Heir {
        address heirAddress;
        uint256 proportionalShare; // e.g., 10000 for 100%, 5000 for 50%. Max sum of all shares = 10000.
        string heirName; // Optional, for context
        bool hasClaimed; // True if this heir has already claimed their portion
    }

    struct TriggerCondition {
        TriggerType triggerType;
        uint256 value; // e.g., timestamp, inactivity duration, number of witnesses
        address oracleAddress; // For ORACLE_PROOF_OF_DEATH, the specific trusted oracle address
        bytes specificData; // Additional data for complex triggers (e.g., hash of expected oracle response, or specific signature)
        bool isMet; // Tracks if this specific condition has been fulfilled
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        address targetContract; // Contract to call if proposal passes (e.g., AeternaVaultsDAO itself)
        bytes calldata; // Encoded function call for execution
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // Voter address => true if voted
        bool executed;
        bool passed;
        bool cancelled;
    }

    struct Challenge {
        address challenger;
        uint256 challengeTime;
        ChallengeStatus status;
        uint256 disputeId; // If escalated to a formal dispute
        string reason;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 vaultId;
        address initiatingParty;
        string reason;
        DisputeStatus status;
        uint256 proposalId; // If a DAO proposal is created for resolution of this dispute
    }

    // --- Events ---

    event VaultCreated(uint256 indexed vaultId, address indexed owner, string vaultURI, uint256 creationTime);
    event VaultURIUpdated(uint256 indexed vaultId, string newURI);
    event ReleaseHashUpdated(uint256 indexed vaultId, bytes32 newHash);
    event VaultClosed(uint256 indexed vaultId, address indexed owner, uint256 depositReturned);
    event HeirAdded(uint256 indexed vaultId, address indexed heirAddress, uint256 share);
    event HeirRemoved(uint256 indexed vaultId, address indexed heirAddress);
    event HeirShareUpdated(uint256 indexed vaultId, address indexed heirAddress, uint256 newShare);
    event VaultActivated(uint256 indexed vaultId, uint256 activationTime);
    event VaultClaimed(uint256 indexed vaultId, address indexed heirAddress, bytes32 releaseHash);
    event TriggerConditionSet(uint256 indexed vaultId, TriggerType _type, uint256 value, address oracleAddress);
    event WitnessAdded(uint256 indexed vaultId, address indexed witnessAddress);
    event WitnessConfirmed(uint256 indexed vaultId, address indexed witnessAddress, uint256 confirmedCount);
    event HeartbeatSent(uint256 indexed vaultId, address indexed owner, uint256 heartbeatTime);
    event LivenessChallenged(uint256 indexed vaultId, address indexed challenger, uint255 challengeTime);
    event LivenessChallengeResolved(uint256 indexed vaultId, ChallengeStatus status);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool _for);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalFailed(uint256 indexed proposalId, string reason);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed vaultId, address indexed initiatingParty);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status);
    event OracleProofSubmitted(uint256 indexed vaultId, address indexed oracleAddress, bytes32 requestId);
    event TrustedOracleSet(address indexed oracleAddress, bool isTrusted);

    // --- Modifiers ---

    modifier onlyVaultOwner(uint256 _vaultId) {
        require(vaults[_vaultId].owner == _msgSender(), "AVD: Not vault owner");
        _;
    }

    modifier onlyHeir(uint256 _vaultId) {
        bool isHeir = false;
        for (uint i = 0; i < vaultHeirs[_vaultId].length; i++) {
            if (vaultHeirs[_vaultId][i].heirAddress == _msgSender()) {
                isHeir = true;
                break;
            }
        }
        require(isHeir, "AVD: Not a designated heir for this vault");
        _;
    }

    modifier onlyWitness(uint256 _vaultId) {
        require(vaultWitnesses[_vaultId][_msgSender()], "AVD: Not a designated witness for this vault");
        _;
    }

    modifier onlyTrustedOracle(address _oracleAddress) {
        require(trustedOracles[_oracleAddress], "AVD: Caller is not a trusted oracle");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposer != address(0), "AVD: Proposal does not exist");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initial parameters are set here.
        // For a full DAO, ownership should be transferred to the contract itself
        // or a dedicated DAO governance module after deployment.
        // For example: transferOwnership(address(this));
    }

    // --- Fallback Function ---

    receive() external payable {
        emit FundsDeposited(_msgSender(), msg.value);
    }

    // --- I. Core Vault Management ---

    /// @notice Initializes a new Digital Immortality Vault for the caller.
    /// @param _vaultURI IPFS/Arweave hash or URL pointing to the encrypted data/instructions.
    /// @param _initialReleaseHash A hash representing the encrypted key or access instructions, released upon activation.
    /// @param _inactivityDuration The default duration in seconds after which vault is considered inactive if no heartbeat.
    /// @return vaultId The ID of the newly created vault.
    function createVault(string memory _vaultURI, bytes32 _initialReleaseHash, uint256 _inactivityDuration)
        external
        payable
        returns (uint256)
    {
        require(msg.value >= minVaultDeposit, "AVD: Insufficient deposit for vault creation");
        uint256 vaultId = nextVaultId++;
        vaults[vaultId] = Vault({
            owner: _msgSender(),
            creationTime: block.timestamp,
            lastHeartbeatTime: block.timestamp,
            inactivityDuration: _inactivityDuration,
            isActivated: false,
            status: VaultStatus.ACTIVE,
            vaultURI: _vaultURI,
            releaseHash: _initialReleaseHash,
            depositAmount: msg.value,
            totalWitnessesRequired: 0, // Default to 0, updated if MULTI_SIG_WITNESSES trigger is set
            confirmedWitnesses: 0
        });
        emit VaultCreated(vaultId, _msgSender(), _vaultURI, block.timestamp);
        return vaultId;
    }

    /// @notice Allows the vault owner to update the URI pointing to off-chain encrypted data.
    /// @param _vaultId The ID of the vault to update.
    /// @param _newVaultURI The new IPFS/Arweave hash or URL.
    function updateVaultURI(uint256 _vaultId, string memory _newVaultURI) external onlyVaultOwner(_vaultId) {
        require(vaults[_vaultId].status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(vaults[_vaultId].status != VaultStatus.DISPUTED, "AVD: Vault is in dispute.");
        vaults[_vaultId].vaultURI = _newVaultURI;
        emit VaultURIUpdated(_vaultId, _newVaultURI);
    }

    /// @notice Allows the vault owner to update the encrypted access key/hash.
    /// @param _vaultId The ID of the vault to update.
    /// @param _newReleaseHash The new hash of the encrypted key or access instructions.
    function updateReleaseHash(uint256 _vaultId, bytes32 _newReleaseHash) external onlyVaultOwner(_vaultId) {
        require(vaults[_vaultId].status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(vaults[_vaultId].status != VaultStatus.DISPUTED, "AVD: Vault is in dispute.");
        vaults[_vaultId].releaseHash = _newReleaseHash;
        emit ReleaseHashUpdated(_vaultId, _newReleaseHash);
    }

    /// @notice Allows the owner to deactivate their vault and reclaim any associated deposits.
    ///         This operation is irreversible and invalidates the vault.
    /// @param _vaultId The ID of the vault to close.
    function closeVault(uint256 _vaultId) external onlyVaultOwner(_vaultId) {
        require(vaults[_vaultId].status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(vaults[_vaultId].status != VaultStatus.DISPUTED, "AVD: Vault is in dispute.");

        uint256 deposit = vaults[_vaultId].depositAmount;
        vaults[_vaultId].status = VaultStatus.PENDING; // Mark as pending deletion (effectively deleted for active purposes)
        
        // Clear associated data to free up storage slots
        delete vaults[_vaultId];
        delete vaultHeirs[_vaultId];
        delete vaultTriggerConditions[_vaultId];
        delete vaultWitnesses[_vaultId];
        delete witnessConfirmations[_vaultId];
        delete livenessChallenges[_vaultId]; // Clear any challenges
        // Note: Disputes are separate and would need their own resolution if active

        payable(_msgSender()).transfer(deposit);
        emit VaultClosed(_vaultId, _msgSender(), deposit);
    }

    // --- II. Heir & Beneficiary Management ---

    /// @notice Designates a beneficiary for a vault. Limits to 10 heirs for gas efficiency.
    /// @param _vaultId The ID of the vault.
    /// @param _heirAddress The address of the heir.
    /// @param _proportionalShare The proportional share (out of 10000) for this heir (e.g., 2500 for 25%).
    /// @param _heirName Optional name for the heir.
    function addHeir(uint256 _vaultId, address _heirAddress, uint256 _proportionalShare, string memory _heirName)
        external
        onlyVaultOwner(_vaultId)
    {
        require(vaults[_vaultId].status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(vaults[_vaultId].status != VaultStatus.DISPUTED, "AVD: Vault is in dispute.");
        require(_proportionalShare > 0, "AVD: Share must be positive");
        require(vaultHeirs[_vaultId].length < 10, "AVD: Max 10 heirs per vault.");
        
        uint256 totalShares;
        for (uint i = 0; i < vaultHeirs[_vaultId].length; i++) {
            require(vaultHeirs[_vaultId][i].heirAddress != _heirAddress, "AVD: Heir already added.");
            totalShares += vaultHeirs[_vaultId][i].proportionalShare;
        }
        require(totalShares + _proportionalShare <= 10000, "AVD: Total shares exceed 10000 (100%).");

        vaultHeirs[_vaultId].push(Heir({
            heirAddress: _heirAddress,
            proportionalShare: _proportionalShare,
            heirName: _heirName,
            hasClaimed: false
        }));
        emit HeirAdded(_vaultId, _heirAddress, _proportionalShare);
    }

    /// @notice Removes a designated beneficiary.
    /// @param _vaultId The ID of the vault.
    /// @param _heirAddress The address of the heir to remove.
    function removeHeir(uint256 _vaultId, address _heirAddress) external onlyVaultOwner(_vaultId) {
        require(vaults[_vaultId].status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(vaults[_vaultId].status != VaultStatus.DISPUTED, "AVD: Vault is in dispute.");

        bool found = false;
        for (uint i = 0; i < vaultHeirs[_vaultId].length; i++) {
            if (vaultHeirs[_vaultId][i].heirAddress == _heirAddress) {
                // Replace the element to be removed with the last element and pop.
                vaultHeirs[_vaultId][i] = vaultHeirs[_vaultId][vaultHeirs[_vaultId].length - 1];
                vaultHeirs[_vaultId].pop();
                found = true;
                break;
            }
        }
        require(found, "AVD: Heir not found for this vault.");
        emit HeirRemoved(_vaultId, _heirAddress);
    }

    /// @notice Adjusts a beneficiary's proportional share of the vault.
    /// @param _vaultId The ID of the vault.
    /// @param _heirAddress The address of the heir whose share to update.
    /// @param _newShare The new proportional share (out of 10000).
    function updateHeirShare(uint256 _vaultId, address _heirAddress, uint256 _newShare)
        external
        onlyVaultOwner(_vaultId)
    {
        require(vaults[_vaultId].status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(vaults[_vaultId].status != VaultStatus.DISPUTED, "AVD: Vault is in dispute.");
        require(_newShare > 0, "AVD: Share must be positive.");

        uint256 totalShares = 0;
        bool found = false;
        for (uint i = 0; i < vaultHeirs[_vaultId].length; i++) {
            if (vaultHeirs[_vaultId][i].heirAddress == _heirAddress) {
                totalShares += _newShare;
                found = true;
            } else {
                totalShares += vaultHeirs[_vaultId][i].proportionalShare;
            }
        }
        require(found, "AVD: Heir not found for this vault.");
        require(totalShares <= 10000, "AVD: Total shares exceed 10000 (100%).");

        for (uint i = 0; i < vaultHeirs[_vaultId].length; i++) {
            if (vaultHeirs[_vaultId][i].heirAddress == _heirAddress) {
                vaultHeirs[_vaultId][i].proportionalShare = _newShare;
                break;
            }
        }
        emit HeirShareUpdated(_vaultId, _heirAddress, _newShare);
    }

    /// @notice Allows a designated heir to claim the vault contents (receive `releaseHash`) once activated.
    /// @param _vaultId The ID of the vault to claim.
    function heirClaimVault(uint256 _vaultId) external onlyHeir(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.status == VaultStatus.RELEASED, "AVD: Vault is not in a released state.");

        bool hasAlreadyClaimed = false;
        for (uint i = 0; i < vaultHeirs[_vaultId].length; i++) {
            if (vaultHeirs[_vaultId][i].heirAddress == _msgSender()) {
                require(!vaultHeirs[_vaultId][i].hasClaimed, "AVD: Heir has already claimed this vault.");
                vaultHeirs[_vaultId][i].hasClaimed = true;
                hasAlreadyClaimed = true;
                break;
            }
        }
        require(hasAlreadyClaimed, "AVD: Caller is not a designated heir for this vault.");

        // In a real scenario, this would trigger an off-chain mechanism to deliver the key/hash
        // or the heir retrieves it using the emitted hash.
        emit VaultClaimed(_vaultId, _msgSender(), vault.releaseHash);
    }

    // --- III. Trigger & Release Mechanisms ---

    /// @notice Configures a specific condition that must be met for vault activation.
    ///         Multiple conditions can be set, all of which must be met for activation.
    /// @param _vaultId The ID of the vault.
    /// @param _type The type of trigger condition (enum TriggerType).
    /// @param _value The value associated with the trigger (e.g., timestamp, duration, number of witnesses).
    /// @param _oracleAddress For ORACLE_PROOF_OF_DEATH, the trusted oracle address.
    /// @param _specificData Additional data for complex triggers (e.g., hash of expected oracle response, or specific signature data).
    function setTriggerCondition(
        uint256 _vaultId,
        TriggerType _type,
        uint256 _value,
        address _oracleAddress,
        bytes memory _specificData
    ) external onlyVaultOwner(_vaultId) {
        require(vaults[_vaultId].status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(vaults[_vaultId].status != VaultStatus.DISPUTED, "AVD: Vault is in dispute.");
        
        if (_type == TriggerType.ORACLE_PROOF_OF_DEATH) {
            require(trustedOracles[_oracleAddress], "AVD: Provided oracle is not trusted.");
        }
        if (_type == TriggerType.MULTI_SIG_WITNESSES) {
             require(_value > 0, "AVD: MULTI_SIG_WITNESSES value must be greater than 0.");
             vaults[_vaultId].totalWitnessesRequired = _value;
        }

        vaultTriggerConditions[_vaultId].push(TriggerCondition({
            triggerType: _type,
            value: _value,
            oracleAddress: _oracleAddress,
            specificData: _specificData,
            isMet: false
        }));
        emit TriggerConditionSet(_vaultId, _type, _value, _oracleAddress);
    }

    /// @notice Designates an address as a required multi-signature witness for vault activation.
    ///         Only relevant if a `MULTI_SIG_WITNESSES` trigger condition is set.
    /// @param _vaultId The ID of the vault.
    /// @param _witnessAddress The address to designate as a witness.
    function addWitnessToVault(uint256 _vaultId, address _witnessAddress) external onlyVaultOwner(_vaultId) {
        require(vaults[_vaultId].status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(vaults[_vaultId].status != VaultStatus.DISPUTED, "AVD: Vault is in dispute.");
        require(!vaultWitnesses[_vaultId][_witnessAddress], "AVD: Address is already a witness.");
        vaultWitnesses[_vaultId][_witnessAddress] = true;
        emit WitnessAdded(_vaultId, _witnessAddress);
    }

    /// @notice Allows a designated witness to confirm a trigger event for a specific vault.
    ///         This contributes to the `MULTI_SIG_WITNESSES` trigger condition.
    /// @param _vaultId The ID of the vault.
    function confirmWitnessTrigger(uint256 _vaultId) external onlyWitness(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(witnessConfirmations[_vaultId][_msgSender()] == false, "AVD: Witness already confirmed.");
        require(vault.confirmedWitnesses < vault.totalWitnessesRequired, "AVD: All required witnesses have already confirmed.");

        witnessConfirmations[_vaultId][_msgSender()] = true;
        vault.confirmedWitnesses++;
        emit WitnessConfirmed(_vaultId, _msgSender(), vault.confirmedWitnesses);
    }

    /// @notice Publicly callable function to evaluate all set trigger conditions for a vault and activate it if met.
    ///         This function can be called by anyone to prompt the activation check.
    /// @param _vaultId The ID of the vault to check and activate.
    function checkAndActivateVault(uint256 _vaultId) public { // Public, not external to allow internal calls (e.g., from submitOracleProof)
        Vault storage vault = vaults[_vaultId];
        require(vault.owner != address(0), "AVD: Vault does not exist."); // Ensure vault exists
        require(vault.status != VaultStatus.RELEASED, "AVD: Vault is already released.");
        require(vault.status != VaultStatus.DISPUTED, "AVD: Vault is in dispute.");
        require(!vault.isActivated, "AVD: Vault is already activated.");

        bool allConditionsMet = true;
        TriggerCondition[] storage conditions = vaultTriggerConditions[_vaultId];

        for (uint i = 0; i < conditions.length; i++) {
            if (conditions[i].isMet) continue; // Skip already met conditions

            bool currentConditionMet = false;
            if (conditions[i].triggerType == TriggerType.INACTIVITY_DURATION) {
                if (block.timestamp >= vault.lastHeartbeatTime + conditions[i].value) {
                    currentConditionMet = true;
                }
            } else if (conditions[i].triggerType == TriggerType.SPECIFIC_TIMESTAMP) {
                if (block.timestamp >= conditions[i].value) {
                    currentConditionMet = true;
                }
            } else if (conditions[i].triggerType == TriggerType.ORACLE_PROOF_OF_DEATH) {
                // This condition relies on an oracle calling submitOracleProof which sets isMet to true
                currentConditionMet = conditions[i].isMet;
            } else if (conditions[i].triggerType == TriggerType.MULTI_SIG_WITNESSES) {
                if (vault.totalWitnessesRequired > 0 && vault.confirmedWitnesses >= vault.totalWitnessesRequired) {
                    currentConditionMet = true;
                }
            } else if (conditions[i].triggerType == TriggerType.DAO_CONSENSUS) {
                // This condition must be met by a successful DAO proposal explicitly activating it.
                // A proposal execution function would set this specific condition's isMet to true.
                currentConditionMet = conditions[i].isMet;
            }

            conditions[i].isMet = currentConditionMet; // Update condition status (even if not met, for re-evaluation)
            if (!currentConditionMet) {
                allConditionsMet = false; // If any condition is not met, the vault isn't activated yet
                // No break here, continue to update all conditions, then check `allConditionsMet`
            }
        }

        if (allConditionsMet) {
            vault.isActivated = true;
            vault.status = VaultStatus.RELEASED;
            emit VaultActivated(_vaultId, block.timestamp);
        }
    }

    // --- IV. Proof-of-Life & Inactivity ---

    /// @notice The vault owner sends a periodic signal to confirm their liveness.
    /// @param _vaultId The ID of the vault.
    function sendHeartbeat(uint256 _vaultId) external onlyVaultOwner(_vaultId) {
        require(vaults[_vaultId].status == VaultStatus.ACTIVE || vaults[_vaultId].status == VaultStatus.INACTIVE, "AVD: Vault not in an active or inactive state.");
        vaults[_vaultId].lastHeartbeatTime = block.timestamp;
        livenessChallenges[_vaultId].status = ChallengeStatus.NONE; // Clear any existing challenges
        vaults[_vaultId].status = VaultStatus.ACTIVE; // Ensure status is active
        emit HeartbeatSent(_vaultId, _msgSender(), block.timestamp);
    }

    /// @notice Initiates a challenge against a vault owner's last heartbeat, potentially leading to a dispute.
    ///         Requires the owner's last heartbeat to be older than `heartbeatInterval`.
    /// @param _vaultId The ID of the vault to challenge.
    /// @param _reason A brief reason for the challenge.
    function challengeLiveness(uint256 _vaultId, string memory _reason) external {
        Vault storage vault = vaults[_vaultId];
        require(vault.owner != address(0), "AVD: Vault does not exist.");
        require(vault.status == VaultStatus.ACTIVE || vault.status == VaultStatus.INACTIVE, "AVD: Vault not in a challengeable state.");
        require(block.timestamp >= vault.lastHeartbeatTime + heartbeatInterval, "AVD: Heartbeat is still fresh.");
        require(livenessChallenges[_vaultId].status == ChallengeStatus.NONE ||
                (livenessChallenges[_vaultId].status == ChallengeStatus.CHALLENGED && block.timestamp > livenessChallenges[_vaultId].challengeTime + challengeResponsePeriod),
                "AVD: Challenge already active or previous challenge response period ongoing/failed.");

        livenessChallenges[_vaultId] = Challenge({
            challenger: _msgSender(),
            challengeTime: block.timestamp,
            status: ChallengeStatus.CHALLENGED,
            disputeId: 0, // No dispute yet, can be escalated via `raiseDispute`
            reason: _reason
        });
        vault.status = VaultStatus.INACTIVE; // Mark vault as inactive due to challenge
        emit LivenessChallenged(_vaultId, _msgSender(), block.timestamp);
    }

    // --- V. DAO Governance & Treasury ---

    /// @notice Allows members to propose changes or actions to the DAO.
    /// @param _description A description of the proposal.
    /// @param _targetContract The address of the contract the proposal intends to interact with.
    /// @param _calldata The encoded function call to be executed if the proposal passes.
    function submitProposal(string memory _description, address _targetContract, bytes memory _calldata) external {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            description: _description,
            targetContract: _targetContract,
            calldata: _calldata,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriodDuration,
            forVotes: 0,
            againstVotes: 0,
            hasVoted: new mapping(address => bool), // Initialize empty mapping
            executed: false,
            passed: false,
            cancelled: false
        });
        emit ProposalSubmitted(proposalId, _msgSender(), _description);
    }

    /// @notice Casts a vote for or against a specific proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _for True for a 'for' vote, false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _for) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.voteStartTime, "AVD: Voting has not started yet.");
        require(block.timestamp <= proposal.voteEndTime, "AVD: Voting period has ended.");
        require(!proposal.hasVoted[_msgSender()], "AVD: You have already voted on this proposal.");
        require(!proposal.executed, "AVD: Proposal has already been executed.");
        require(!proposal.cancelled, "AVD: Proposal has been cancelled.");

        proposal.hasVoted[_msgSender()] = true;
        if (_for) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
        daoMemberVotes[_msgSender()]++; // Simple 1 address 1 vote for now
        emit VoteCast(_proposalId, _msgSender(), _for);
    }

    /// @notice Executes a proposal that has passed the voting phase.
    ///         Anyone can call this function after the voting period ends and criteria are met.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.voteEndTime, "AVD: Voting period has not ended yet.");
        require(!proposal.executed, "AVD: Proposal has already been executed.");
        require(!proposal.cancelled, "AVD: Proposal has been cancelled.");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        require(totalVotes > 0, "AVD: No votes cast for this proposal."); // Ensure there's at least one vote to avoid division by zero

        // Simple quorum: minimum percentage of for votes out of total votes cast
        bool passed = (proposal.forVotes * 100) / totalVotes >= proposalQuorumPercentage;

        if (passed) {
            proposal.passed = true;
            proposal.executed = true;
            // Execute the proposed action using low-level call
            (bool success, ) = proposal.targetContract.call(proposal.calldata);
            require(success, "AVD: Proposal execution failed.");
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.passed = false;
            proposal.executed = true; // Mark as executed, but failed
            emit ProposalFailed(_proposalId, "Not enough votes or quorum not met.");
        }
    }

    /// @notice Allows anyone to deposit funds into the DAO's treasury.
    function depositToTreasury() external payable {
        require(msg.value > 0, "AVD: Deposit must be greater than zero.");
        // Funds are directly sent to the contract's address via the receive function.
        emit FundsDeposited(_msgSender(), msg.value);
    }

    /// @notice Allows the DAO (via proposal) to distribute funds from its treasury.
    ///         This function is callable only by the contract itself if `owner` is transferred to `address(this)`.
    /// @param _tokenAddress The address of the ERC20 token (address(0) for ETH).
    /// @param _recipient The recipient address.
    /// @param _amount The amount to withdraw.
    function withdrawFromTreasury(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner {
        require(_amount > 0, "AVD: Amount must be positive.");
        require(_recipient != address(0), "AVD: Invalid recipient address.");

        if (_tokenAddress == address(0)) {
            // Withdraw ETH
            require(address(this).balance >= _amount, "AVD: Insufficient ETH balance in treasury.");
            payable(_recipient).transfer(_amount);
        } else {
            // Withdraw ERC20 tokens
            IERC20 token = IERC20(_tokenAddress);
            require(token.balanceOf(address(this)) >= _amount, "AVD: Insufficient token balance in treasury.");
            require(token.transfer(_recipient, _amount), "AVD: Token transfer failed.");
        }
        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- VI. Dispute Resolution ---

    /// @notice Initiates a formal dispute process regarding a vault's status or claims.
    ///         Requires a small deposit to prevent spam.
    /// @param _vaultId The ID of the vault in dispute.
    /// @param _reason A detailed reason for the dispute.
    function raiseDispute(uint256 _vaultId, string memory _reason) external payable {
        require(msg.value >= minVaultDeposit, "AVD: Insufficient deposit to raise dispute.");
        Vault storage vault = vaults[_vaultId];
        require(vault.owner != address(0), "AVD: Vault does not exist.");
        require(vault.status != VaultStatus.DISPUTED, "AVD: Vault is already in dispute.");
        require(vault.status != VaultStatus.RELEASED, "AVD: Cannot dispute a released vault.");

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            disputeId: disputeId,
            vaultId: _vaultId,
            initiatingParty: _msgSender(),
            reason: _reason,
            status: DisputeStatus.OPEN,
            proposalId: 0 // Will be set if a DAO proposal is made to resolve it
        });
        vault.status = VaultStatus.DISPUTED; // Temporarily block vault actions
        emit DisputeRaised(disputeId, _vaultId, _msgSender());
    }

    /// @notice Allows a trusted oracle to submit definitive proof for a vault's trigger condition.
    ///         This would typically be a callback from an oracle network (e.g., Chainlink).
    /// @param _vaultId The ID of the vault.
    /// @param _proofData The raw proof data from the oracle.
    /// @param _requestId The request ID associated with the oracle query.
    function submitOracleProof(uint256 _vaultId, bytes memory _proofData, bytes32 _requestId)
        external
        onlyTrustedOracle(_msgSender())
    {
        // In a full Chainlink integration, this function would verify _requestId and the format of _proofData
        // against a specific oracle request made by the contract.
        // For demonstration, we simply find the relevant condition and mark it as met.
        TriggerCondition[] storage conditions = vaultTriggerConditions[_vaultId];
        bool foundCondition = false;
        for (uint i = 0; i < conditions.length; i++) {
            if (conditions[i].triggerType == TriggerType.ORACLE_PROOF_OF_DEATH &&
                conditions[i].oracleAddress == _msgSender() &&
                !conditions[i].isMet) // Only process if not already met
            {
                // In a real scenario, _proofData would be verified against conditions[i].specificData
                // and the outcome used to set isMet. For simplicity, assume valid proof means met.
                conditions[i].isMet = true;
                foundCondition = true;
                break;
            }
        }
        require(foundCondition, "AVD: No matching oracle trigger condition found for this vault/oracle.");
        emit OracleProofSubmitted(_vaultId, _msgSender(), _requestId);
        // Automatically check for vault activation after receiving proof
        checkAndActivateVault(_vaultId);
    }

    /// @notice Allows the DAO to vote on and resolve an ongoing dispute.
    ///         This function would be called via `executeProposal`.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _resolutionOutcome True if resolved in favor of the challenger (e.g., owner confirmed dead/inactive), false otherwise.
    function resolveDispute(uint256 _disputeId, bool _resolutionOutcome) external onlyOwner { // Callable by DAO via executeProposal
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "AVD: Dispute does not exist."); // Check if dispute exists
        require(dispute.status == DisputeStatus.OPEN, "AVD: Dispute is not open.");

        Vault storage vault = vaults[dispute.vaultId];

        if (_resolutionOutcome) { // Resolved in favor of challenger (e.g., owner confirmed dead/inactive)
            dispute.status = DisputeStatus.RESOLVED_FOR_CHALLENGER;
            vault.status = VaultStatus.INACTIVE; 
            // Depending on the dispute's nature, one might immediately try to activate the vault
            checkAndActivateVault(dispute.vaultId);
        } else { // Resolved in favor of original owner (e.g., owner proved liveness)
            dispute.status = DisputeStatus.RESOLVED_FOR_OWNER;
            vault.status = VaultStatus.ACTIVE;
            livenessChallenges[dispute.vaultId].status = ChallengeStatus.RESOLVED; // Clear any related challenges
        }
        emit DisputeResolved(_disputeId, dispute.status);
    }

    // --- VII. External Integrations (Oracle Interface) ---

    /// @notice Allows the DAO to manage a list of trusted oracle addresses.
    ///         This function is intended to be called via `executeProposal` (where `owner` is the DAO).
    /// @param _oracleAddress The address of the oracle.
    /// @param _isTrusted True to add as trusted, false to remove.
    function setTrustedOracle(address _oracleAddress, bool _isTrusted) external onlyOwner { // Callable by DAO (owner)
        require(_oracleAddress != address(0), "AVD: Invalid address.");
        trustedOracles[_oracleAddress] = _isTrusted;
        emit TrustedOracleSet(_oracleAddress, _isTrusted);
    }

    /// @notice Placeholder callback function for a trusted oracle to deliver data.
    ///         In a real integration (e.g., Chainlink), this would be a specific function
    ///         that Chainlink's `fulfill` method calls, secured by Chainlink's VRF or Oracle contracts.
    ///         Currently, `submitOracleProof` handles direct oracle data submission.
    /// @param _vaultId The vault ID this data pertains to.
    /// @param _requestId The Chainlink request ID (example).
    /// @param _response The raw bytes response from the oracle (example).
    function receiveOracleData(uint256 _vaultId, bytes32 _requestId, bytes memory _response) external {
        // This function would be secured by checking msg.sender against a Chainlink VRF Coordinator or similar.
        // For this example, `submitOracleProof` is the primary public oracle interface.
        revert("AVD: This function is a placeholder and intended for deeper, secure oracle integration.");
    }

    // --- VIII. Utilities & View Functions ---

    /// @notice Retrieves comprehensive details about a specific vault.
    /// @param _vaultId The ID of the vault.
    /// @return A Vault struct containing all its details.
    function getVaultDetails(uint256 _vaultId) external view returns (Vault memory) {
        require(vaults[_vaultId].owner != address(0), "AVD: Vault does not exist.");
        return vaults[_vaultId];
    }

    /// @notice Returns a list of all designated heirs for a vault.
    /// @param _vaultId The ID of the vault.
    /// @return An array of Heir structs.
    function getHeirs(uint256 _vaultId) external view returns (Heir[] memory) {
        require(vaults[_vaultId].owner != address(0), "AVD: Vault does not exist.");
        return vaultHeirs[_vaultId];
    }

    /// @notice Returns all set trigger conditions for a vault.
    /// @param _vaultId The ID of the vault.
    /// @return An array of TriggerCondition structs.
    function getTriggerConditions(uint256 _vaultId) external view returns (TriggerCondition[] memory) {
        require(vaults[_vaultId].owner != address(0), "AVD: Vault does not exist.");
        return vaultTriggerConditions[_vaultId];
    }

    /// @notice Retrieves details about a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A Proposal struct containing its details.
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        require(proposals[_proposalId].proposer != address(0), "AVD: Proposal does not exist.");
        return proposals[_proposalId];
    }

    /// @notice Returns an array of vault IDs owned by a specific address.
    ///         Note: This is an expensive operation for a very large number of vaults.
    ///         For production, consider off-chain indexing for this query.
    /// @param _owner The address of the vault owner.
    /// @return An array of vault IDs.
    function getVaultsByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] memory ownedVaults = new uint256[](nextVaultId); // Max possible size for pre-allocation
        uint256 count = 0;
        for (uint i = 0; i < nextVaultId; i++) {
            // Check if vault exists and is owned by _owner, and is not marked for deletion
            if (vaults[i].owner == _owner && vaults[i].status != VaultStatus.PENDING) {
                ownedVaults[count] = i;
                count++;
            }
        }
        // Create a new array of exact size
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = ownedVaults[i];
        }
        return result;
    }

    /// @notice Returns details about an active liveness challenge for a vault.
    /// @param _vaultId The ID of the vault.
    /// @return A Challenge struct containing the details.
    function getChallengeDetails(uint256 _vaultId) external view returns (Challenge memory) {
        require(vaults[_vaultId].owner != address(0), "AVD: Vault does not exist.");
        return livenessChallenges[_vaultId];
    }
}
```