Okay, this is an exciting challenge! Let's craft a sophisticated and highly dynamic smart contract focusing on a concept I'll call the **"Cognitive Digital Identity (CDI) Protocol"**.

This protocol allows users to mint a non-fungible, evolving digital identity (CDI) that accumulates "Cognitive Points" (CP) based on validated on-chain and off-chain activities. These CPs determine the CDI's "Cognitive Level," unlocking advanced functionalities. The system integrates:

1.  **Dynamic NFTs:** CDI metadata can evolve.
2.  **Reputation System:** Cognitive Points and Levels.
3.  **Oracle-driven AI/Off-chain Computation:** CDIs can request and receive verified results from off-chain services.
4.  **Soulbound-like Mechanics:** CDIs are primarily non-transferable but allow for specific, governed transfer/merge scenarios.
5.  **Delegated Autonomy:** CDIs can delegate tasks and attest to properties.
6.  **Granular Privacy/Access Control:** Owners can control who views specific CDI attributes.
7.  **Decentralized Governance:** CDI holders vote on protocol parameters.
8.  **Internal Credentialing:** CDIs can issue verifiable, soulbound credentials.

---

## CDI Protocol: Outline and Function Summary

**Contract Name:** `CognitiveDigitalIdentity`

**Core Concept:** A protocol for creating, managing, and evolving dynamic, semi-autonomous "Cognitive Digital Identities" (CDIs) on the blockchain. CDIs are NFTs that accumulate "Cognitive Points" (CP), which define their "Cognitive Level" and unlock specific capabilities within the ecosystem.

### Outline:

1.  **ERC721 Standard Implementation:** For CDIs.
2.  **Access Control & Roles:** Owner, Trusted Oracles, Governors.
3.  **CDI Data Structures:** Stores details about each CDI.
4.  **Cognitive Point (CP) Logic:** How CP are earned, burned, and how they determine Cognitive Levels.
5.  **Cognitive Service Request Management:** For interacting with off-chain AI/computation via oracles.
6.  **Staking Mechanics:** For CDIs to contribute to network "Cognitive Power" and earn rewards.
7.  **Governance Module:** For protocol parameter changes (DAO-like).
8.  **Advanced CDI Interactions:** Delegation, Attestations, Merging, Conditional Transfer, Internal Credentialing.
9.  **Events:** To signal key state changes.

### Function Summary (23 Functions):

**I. CDI Management (ERC721 & Core Identity):**
1.  `createCDI(string memory _name, string memory _metadataURI)`: Mints a new Cognitive Digital Identity NFT for the caller.
2.  `updateCDIMetadata(uint256 _cdiId, string memory _newMetadataURI)`: Allows a CDI owner to update its associated metadata URI, reflecting its dynamic nature.
3.  `getCDICognitiveLevel(uint256 _cdiId)`: Calculates and returns the current Cognitive Level of a CDI based on its accumulated Cognitive Points.
4.  `transferCDI(uint256 _cdiId, address _newOwner, bytes32 _justificationHash)`: Allows for *conditional* and justified transfer of a CDI (e.g., inheritance, governance-approved transfer), maintaining its "soulbound-like" nature.

**II. Cognitive Points (CP) & Level System:**
5.  `mintCognitivePoints(address _recipient, uint256 _amount, bytes32 _proofHash)`: Trusted Oracles mint Cognitive Points to a CDI or address based on verified off-chain proofs of contribution.
6.  `burnCognitivePoints(uint256 _cdiId, uint256 _amount)`: A CDI owner can burn their own Cognitive Points for specific in-protocol actions or to signal commitment.

**III. Oracle & Off-chain Cognitive Service Integration:**
7.  `registerTrustedOracle(address _oracleAddress, string memory _name)`: The protocol owner registers a new trusted off-chain oracle, enabling them to submit verified data.
8.  `revokeTrustedOracle(address _oracleAddress)`: The protocol owner revokes a trusted oracle's privileges.
9.  `requestCognitiveService(uint256 _cdiId, bytes32 _serviceRequestHash, uint256 _rewardAmount)`: A CDI owner requests an off-chain cognitive service (e.g., AI analysis), providing a hash of the request and an attached CP reward.
10. `submitCognitiveServiceResult(uint256 _taskId, uint256 _cdiId, bytes32 _resultHash, bytes memory _verificationData)`: A trusted oracle submits the verified result of a cognitive service request, along with proof, triggering CP minting for the CDI.

**IV. CDI Staking for Network Power:**
11. `stakeCDIForPower(uint256 _cdiId)`: A CDI owner stakes their CDI to contribute to the network's "Cognitive Power" and earn future rewards.
12. `unstakeCDI(uint256 _cdiId)`: A CDI owner unstakes their CDI after a cool-down period.
13. `claimStakingRewards(uint256 _cdiId)`: Allows staked CDI owners to claim accrued Cognitive Point rewards.

**V. Decentralized Governance (DAO):**
14. `proposeProtocolParameter(bytes32 _parameterKey, uint256 _newValue, string memory _description)`: Any CDI above a certain Cognitive Level can propose changes to protocol parameters (e.g., CP thresholds, oracle rewards).
15. `voteOnProposal(uint256 _proposalId, bool _support)`: CDI owners vote on active proposals, with their vote weight potentially scaled by their Cognitive Points or Level.
16. `executeProposal(uint256 _proposalId)`: Once a proposal passes and the voting period ends, any CDI can trigger its execution.

**VI. Advanced CDI Interactions & Identity Features:**
17. `delegateCDITask(uint256 _delegatorCDI, uint256 _delegateeCDI, bytes32 _taskDetailsHash, uint256 _cpReward)`: A CDI delegates a specific task or responsibility to another CDI, along with a CP reward upon completion (verified by oracle or attestation).
18. `attestToCDIProperty(uint256 _cdiId, bytes32 _propertyHash, bool _value, bytes memory _attestationProof)`: A trusted entity (e.g., another CDI, an oracle, or a DAO) can attest to a specific verifiable property or characteristic of a CDI (e.g., "VerifiedHuman", "AIEnabled", "HighContributor").
19. `challengeAttestation(uint256 _attestationId, string memory _reason)`: Allows a CDI or a third party to formally challenge an existing attestation, potentially triggering a governance review.
20. `setCDIAttributeAccess(uint256 _cdiId, address _viewer, bytes32 _attributeHash, bool _canView)`: CDI owners can grant or revoke specific addresses permission to view sensitive, private attributes linked to their CDI.
21. `initiateCDIMergeRequest(uint256 _cdiId1, uint256 _cdiId2, bytes32 _mergeRationaleHash)`: Two CDI owners can initiate a request to merge their identities, combining their Cognitive Points and potentially creating a new enhanced CDI.
22. `approveCDIMerge(uint256 _mergeRequestId)`: The owners of the respective CDIs, and potentially governance, approve the merge request.
23. `mintSoulboundCredential(uint256 _cdiId, address _recipient, bytes32 _credentialHash, uint256 _expirationTimestamp)`: A CDI itself (if it reaches a certain level or is configured as an issuer) can mint non-transferable, soulbound credentials to other addresses or CDIs, signifying achievements, roles, or affiliations within the ecosystem.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


/**
 * @title CognitiveDigitalIdentity (CDI) Protocol
 * @dev A protocol for creating, managing, and evolving dynamic, semi-autonomous "Cognitive Digital Identities" (CDIs) on the blockchain.
 *      CDIs are NFTs that accumulate "Cognitive Points" (CP), which define their "Cognitive Level" and unlock specific capabilities within the ecosystem.
 *
 * Outline:
 * 1.  ERC721 Standard Implementation: For CDIs.
 * 2.  Access Control & Roles: Owner, Trusted Oracles, Governors.
 * 3.  CDI Data Structures: Stores details about each CDI.
 * 4.  Cognitive Point (CP) Logic: How CP are earned, burned, and how they determine Cognitive Levels.
 * 5.  Cognitive Service Request Management: For interacting with off-chain AI/computation via oracles.
 * 6.  Staking Mechanics: For CDIs to contribute to network "Cognitive Power" and earn rewards.
 * 7.  Governance Module: For protocol parameter changes (DAO-like).
 * 8.  Advanced CDI Interactions: Delegation, Attestations, Merging, Conditional Transfer, Internal Credentialing.
 * 9.  Events: To signal key state changes.
 *
 * Function Summary (23 Functions):
 *
 * I. CDI Management (ERC721 & Core Identity):
 * 1.  `createCDI(string memory _name, string memory _metadataURI)`: Mints a new Cognitive Digital Identity NFT for the caller.
 * 2.  `updateCDIMetadata(uint256 _cdiId, string memory _newMetadataURI)`: Allows a CDI owner to update its associated metadata URI, reflecting its dynamic nature.
 * 3.  `getCDICognitiveLevel(uint256 _cdiId)`: Calculates and returns the current Cognitive Level of a CDI based on its accumulated Cognitive Points.
 * 4.  `transferCDI(uint256 _cdiId, address _newOwner, bytes32 _justificationHash)`: Allows for *conditional* and justified transfer of a CDI (e.g., inheritance, governance-approved transfer), maintaining its "soulbound-like" nature.
 *
 * II. Cognitive Points (CP) & Level System:
 * 5.  `mintCognitivePoints(address _recipient, uint256 _amount, bytes32 _proofHash)`: Trusted Oracles mint Cognitive Points to a CDI or address based on verified off-chain proofs of contribution.
 * 6.  `burnCognitivePoints(uint256 _cdiId, uint256 _amount)`: A CDI owner can burn their own Cognitive Points for specific in-protocol actions or to signal commitment.
 *
 * III. Oracle & Off-chain Cognitive Service Integration:
 * 7.  `registerTrustedOracle(address _oracleAddress, string memory _name)`: The protocol owner registers a new trusted off-chain oracle, enabling them to submit verified data.
 * 8.  `revokeTrustedOracle(address _oracleAddress)`: The protocol owner revokes a trusted oracle's privileges.
 * 9.  `requestCognitiveService(uint256 _cdiId, bytes32 _serviceRequestHash, uint256 _rewardAmount)`: A CDI owner requests an off-chain cognitive service (e.g., AI analysis), providing a hash of the request and an attached CP reward.
 * 10. `submitCognitiveServiceResult(uint256 _taskId, uint256 _cdiId, bytes32 _resultHash, bytes memory _verificationData)`: A trusted oracle submits the verified result of a cognitive service request, along with proof, triggering CP minting for the CDI.
 *
 * IV. CDI Staking for Network Power:
 * 11. `stakeCDIForPower(uint256 _cdiId)`: A CDI owner stakes their CDI to contribute to the network's "Cognitive Power" and earn future rewards.
 * 12. `unstakeCDI(uint256 _cdiId)`: A CDI owner unstakes their CDI after a cool-down period.
 * 13. `claimStakingRewards(uint256 _cdiId)`: Allows staked CDI owners to claim accrued Cognitive Point rewards.
 *
 * V. Decentralized Governance (DAO):
 * 14. `proposeProtocolParameter(bytes32 _parameterKey, uint256 _newValue, string memory _description)`: Any CDI above a certain Cognitive Level can propose changes to protocol parameters (e.g., CP thresholds, oracle rewards).
 * 15. `voteOnProposal(uint256 _proposalId, bool _support)`: CDI owners vote on active proposals, with their vote weight potentially scaled by their Cognitive Points or Level.
 * 16. `executeProposal(uint256 _proposalId)`: Once a proposal passes and the voting period ends, any CDI can trigger its execution.
 *
 * VI. Advanced CDI Interactions & Identity Features:
 * 17. `delegateCDITask(uint256 _delegatorCDI, uint256 _delegateeCDI, bytes32 _taskDetailsHash, uint256 _cpReward)`: A CDI delegates a specific task or responsibility to another CDI, along with a CP reward upon completion (verified by oracle or attestation).
 * 18. `attestToCDIProperty(uint256 _cdiId, bytes32 _propertyHash, bool _value, bytes memory _attestationProof)`: A trusted entity (e.g., another CDI, an oracle, or a DAO) can attest to a specific verifiable property or characteristic of a CDI (e.g., "VerifiedHuman", "AIEnabled", "HighContributor").
 * 19. `challengeAttestation(uint256 _attestationId, string memory _reason)`: Allows a CDI or a third party to formally challenge an existing attestation, potentially triggering a governance review.
 * 20. `setCDIAttributeAccess(uint256 _cdiId, address _viewer, bytes32 _attributeHash, bool _canView)`: CDI owners can grant or revoke specific addresses permission to view sensitive, private attributes linked to their CDI.
 * 21. `initiateCDIMergeRequest(uint256 _cdiId1, uint256 _cdiId2, bytes32 _mergeRationaleHash)`: Two CDI owners can initiate a request to merge their identities, combining their Cognitive Points and potentially creating a new enhanced CDI.
 * 22. `approveCDIMerge(uint256 _mergeRequestId)`: The owners of the respective CDIs, and potentially governance, approve the merge request.
 * 23. `mintSoulboundCredential(uint256 _cdiId, address _recipient, bytes32 _credentialHash, uint256 _expirationTimestamp)`: A CDI itself (if it reaches a certain level or is configured as an issuer) can mint non-transferable, soulbound credentials to other addresses or CDIs, signifying achievements, roles, or affiliations within the ecosystem.
 */
contract CognitiveDigitalIdentity is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _cdiIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _attestationIds;
    Counters.Counter private _mergeRequestIds;
    Counters.Counter private _credentialIds;

    // CDI Struct: Represents a unique Cognitive Digital Identity
    struct CDI {
        address owner;
        string name;
        string metadataURI;
        uint256 cognitivePoints;
        uint256 lastStakedTimestamp; // 0 if not staked
        uint256 stakedAmount; // Represents the CP staked, if CDI is staked
        bool isMerged; // True if this CDI has been merged into another
    }
    mapping(uint256 => CDI) public cdis;
    mapping(address => uint256[]) public ownerCDIs; // Map owner address to their owned CDI IDs

    // Cognitive Levels and their thresholds (CP required for each level)
    uint256[] public cognitiveLevelThresholds; // e.g., [0, 100, 500, 2000] for Level 0, 1, 2, 3

    // Trusted Oracles
    mapping(address => bool) public isTrustedOracle;
    mapping(address => string) public trustedOracleNames;

    // Cognitive Service Requests
    struct CognitiveServiceTask {
        uint256 requesterCDIId;
        bytes32 serviceRequestHash; // Hash of the detailed request (e.g., IPFS CID)
        uint256 rewardAmount; // CP reward for successful execution
        bytes32 resultHash; // Hash of the verified result
        bytes verificationData; // Data used by the oracle to verify result
        address oracleAddress; // Oracle that submitted the result
        bool completed;
        uint256 submittedTimestamp;
    }
    mapping(uint256 => CognitiveServiceTask) public cognitiveServiceTasks;

    // Staking parameters
    uint256 public constant CDI_STAKING_COOLDOWN = 7 days; // Cooldown period for unstaking
    uint256 public stakingRewardPerBlock; // CP reward per block for staked CDIs

    // Governance
    struct Proposal {
        uint256 proposerCDIId;
        bytes32 parameterKey; // e.g., keccak256("stakingRewardPerBlock")
        uint256 newValue;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(uint256 => bool) hasVoted; // CDI ID => voted
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingPeriodBlocks; // Number of blocks a proposal is active
    uint256 public proposalMinCPLimit; // Minimum CP required for a CDI to propose

    // Attestations
    struct Attestation {
        address attester; // Can be an oracle, a CDI owner, or governance
        uint256 targetCDIId;
        bytes32 propertyHash; // e.g., keccak256("VerifiedHuman")
        bool value; // True or False for the property
        bytes attestationProof; // Cryptographic proof or identifier
        uint256 timestamp;
        bool challenged; // True if attestation is under challenge
    }
    mapping(uint256 => Attestation) public attestations;

    // CDI Attribute Access Control
    mapping(uint256 => mapping(address => mapping(bytes32 => bool))) public cdiAttributeAccess;
    // cdiId => viewerAddress => attributeHash => canView

    // CDI Merge Requests
    struct CDIMergeRequest {
        uint256 cdi1Id;
        uint256 cdi2Id;
        bytes32 mergeRationaleHash; // Hash explaining the reason for merge
        uint256 proposedTimestamp;
        bool approvedBy1;
        bool approvedBy2;
        bool merged;
    }
    mapping(uint256 => CDIMergeRequest) public cdiMergeRequests;

    // Soulbound Credentials
    struct SoulboundCredential {
        uint256 issuerCDIId;
        address recipient;
        bytes32 credentialHash; // Hash of credential details (e.g., IPFS CID)
        uint256 expirationTimestamp;
        uint256 mintedTimestamp;
    }
    mapping(uint256 => SoulboundCredential) public soulboundCredentials;


    // --- Events ---

    event CDICreated(uint256 indexed cdiId, address indexed owner, string name, string metadataURI);
    event CDIMetadataUpdated(uint256 indexed cdiId, string newMetadataURI);
    event CognitivePointsMinted(address indexed recipient, uint256 amount, bytes32 proofHash);
    event CognitivePointsBurned(uint256 indexed cdiId, uint256 amount);
    event OracleRegistered(address indexed oracleAddress, string name);
    event OracleRevoked(address indexed oracleAddress);
    event CognitiveServiceRequested(uint256 indexed taskId, uint256 indexed requesterCDIId, bytes32 serviceRequestHash, uint256 rewardAmount);
    event CognitiveServiceResultSubmitted(uint256 indexed taskId, uint256 indexed cdiId, bytes32 resultHash, address oracleAddress);
    event CDIStaked(uint256 indexed cdiId, address indexed owner);
    event CDIUnstaked(uint256 indexed cdiId, address indexed owner);
    event RewardsClaimed(uint256 indexed cdiId, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed proposerCDIId, bytes32 parameterKey, uint256 newValue, string description);
    event VotedOnProposal(uint256 indexed proposalId, uint256 indexed voterCDIId, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event CDITaskDelegated(uint256 indexed delegatorCDI, uint256 indexed delegateeCDI, bytes32 taskDetailsHash, uint256 cpReward);
    event CDIAttested(uint256 indexed attestationId, address indexed attester, uint256 indexed targetCDIId, bytes32 propertyHash, bool value);
    event AttestationChallenged(uint256 indexed attestationId, uint256 indexed challengerCDI, string reason);
    event CDIAttributeAccessSet(uint256 indexed cdiId, address indexed viewer, bytes32 attributeHash, bool canView);
    event CDIMergeRequested(uint256 indexed mergeRequestId, uint256 indexed cdi1Id, uint256 indexed cdi2Id, bytes32 rationaleHash);
    event CDIMergeApproved(uint256 indexed mergeRequestId, uint256 indexed cdiId);
    event CDIMerged(uint256 indexed mergeRequestId, uint256 mergedCDIId, uint256 removedCDIId);
    event CDITransferred(uint256 indexed cdiId, address indexed from, address indexed to, bytes32 justificationHash);
    event SoulboundCredentialMinted(uint256 indexed credentialId, uint256 indexed issuerCDIId, address indexed recipient, bytes32 credentialHash, uint256 expirationTimestamp);

    // --- Modifiers ---

    modifier onlyCDIOwner(uint256 _cdiId) {
        require(cdis[_cdiId].owner == _msgSender(), "CDIProtocol: Not CDI owner");
        _;
    }

    modifier onlyTrustedOracle() {
        require(isTrustedOracle[_msgSender()], "CDIProtocol: Not a trusted oracle");
        _;
    }

    modifier onlyActiveCDI(uint256 _cdiId) {
        require(cdis[_cdiId].owner != address(0), "CDIProtocol: CDI does not exist");
        require(!cdis[_cdiId].isMerged, "CDIProtocol: CDI has been merged");
        _;
    }

    modifier onlyCallableByGovernanceOrCDIOwner(uint256 _cdiId) {
        require(_msgSender() == owner() || cdis[_cdiId].owner == _msgSender(), "CDIProtocol: Only callable by owner or CDI owner");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("CognitiveDigitalIdentity", "CDI") Ownable(_msgSender()) {
        // Set initial Cognitive Level Thresholds (e.g., Level 0, 1, 2, 3)
        // Level 0: 0-99 CP
        // Level 1: 100-499 CP
        // Level 2: 500-1999 CP
        // Level 3: 2000+ CP
        cognitiveLevelThresholds.push(0);    // Level 0 (min CP)
        cognitiveLevelThresholds.push(100);  // Level 1
        cognitiveLevelThresholds.push(500);  // Level 2
        cognitiveLevelThresholds.push(2000); // Level 3

        stakingRewardPerBlock = 10; // Initial reward of 10 CP per block for staked CDIs
        votingPeriodBlocks = 1000;  // Approx 4 hours with 14s block time
        proposalMinCPLimit = 100;   // CDIs need at least 100 CP to propose
    }

    // --- CDI Management (ERC721 & Core Identity) ---

    /**
     * @dev Mints a new Cognitive Digital Identity NFT for the caller.
     * @param _name The human-readable name for the CDI.
     * @param _metadataURI The URI pointing to the CDI's initial metadata (e.g., IPFS).
     */
    function createCDI(string memory _name, string memory _metadataURI) public {
        _cdiIds.increment();
        uint256 newCdiId = _cdiIds.current();

        cdis[newCdiId] = CDI({
            owner: _msgSender(),
            name: _name,
            metadataURI: _metadataURI,
            cognitivePoints: 0,
            lastStakedTimestamp: 0,
            stakedAmount: 0,
            isMerged: false
        });

        _safeMint(_msgSender(), newCdiId); // ERC721 mint
        ownerCDIs[_msgSender()].push(newCdiId);

        emit CDICreated(newCdiId, _msgSender(), _name, _metadataURI);
    }

    /**
     * @dev Allows a CDI owner to update its associated metadata URI.
     * This reflects the dynamic nature of CDIs, where their representation can evolve.
     * @param _cdiId The ID of the CDI to update.
     * @param _newMetadataURI The new URI for the CDI's metadata.
     */
    function updateCDIMetadata(uint256 _cdiId, string memory _newMetadataURI) public onlyCDIOwner(_cdiId) onlyActiveCDI(_cdiId) {
        cdis[_cdiId].metadataURI = _newMetadataURI;
        emit CDIMetadataUpdated(_cdiId, _newMetadataURI);
    }

    /**
     * @dev Calculates and returns the current Cognitive Level of a CDI based on its accumulated Cognitive Points.
     * Levels are determined by `cognitiveLevelThresholds`.
     * @param _cdiId The ID of the CDI.
     * @return The Cognitive Level (0-indexed).
     */
    function getCDICognitiveLevel(uint256 _cdiId) public view onlyActiveCDI(_cdiId) returns (uint256) {
        uint256 currentCP = cdis[_cdiId].cognitivePoints;
        for (uint256 i = cognitiveLevelThresholds.length; i > 0; --i) {
            if (currentCP >= cognitiveLevelThresholds[i - 1]) {
                return i - 1;
            }
        }
        return 0; // Default to Level 0
    }

    /**
     * @dev Allows for *conditional* and justified transfer of a CDI.
     * Unlike standard ERC721, this requires a `_justificationHash` to signify why the transfer is happening.
     * This enforces a "soulbound-like" quality, where general trading is discouraged, but
     * specific, auditable transfers (e.g., inheritance, governance-approved custodian change) are possible.
     * @param _cdiId The ID of the CDI to transfer.
     * @param _newOwner The address of the new owner.
     * @param _justificationHash A hash representing the reason/documentation for the transfer (e.g., IPFS CID).
     */
    function transferCDI(uint256 _cdiId, address _newOwner, bytes32 _justificationHash) public onlyCDIOwner(_cdiId) onlyActiveCDI(_cdiId) {
        address currentOwner = ownerOf(_cdiId);
        require(currentOwner != _newOwner, "CDIProtocol: Cannot transfer to self");
        require(_newOwner != address(0), "CDIProtocol: New owner cannot be zero address");

        // Remove from old owner's list
        uint256[] storage oldOwnerCDIs = ownerCDIs[currentOwner];
        for (uint256 i = 0; i < oldOwnerCDIs.length; i++) {
            if (oldOwnerCDIs[i] == _cdiId) {
                oldOwnerCDIs[i] = oldOwnerCDIs[oldOwnerCDIs.length - 1];
                oldOwnerCDIs.pop();
                break;
            }
        }

        cdis[_cdiId].owner = _newOwner; // Update owner in our CDI struct
        _transfer(currentOwner, _newOwner, _cdiId); // Standard ERC721 transfer logic

        ownerCDIs[_newOwner].push(_cdiId); // Add to new owner's list

        emit CDITransferred(_cdiId, currentOwner, _newOwner, _justificationHash);
    }

    // --- Cognitive Points (CP) & Level System ---

    /**
     * @dev Trusted Oracles mint Cognitive Points to a CDI or address based on verified off-chain proofs of contribution.
     * This is the primary way CDIs gain reputation.
     * @param _recipient The address or CDI owner to receive CP.
     * @param _amount The amount of Cognitive Points to mint.
     * @param _proofHash A hash representing the verifiable proof for this CP issuance (e.g., transaction ID, report CID).
     */
    function mintCognitivePoints(address _recipient, uint256 _amount, bytes32 _proofHash) public onlyTrustedOracle {
        require(_recipient != address(0), "CDIProtocol: Cannot mint to zero address");
        // For simplicity, we assume _recipient is the CDI owner.
        // In a more complex system, _recipient could be mapped to a CDI ID.
        // For now, if _recipient owns a CDI, it adds to its first found CDI.
        if (ownerCDIs[_recipient].length > 0) {
            uint256 targetCDIId = ownerCDIs[_recipient][0]; // Target the first CDI owned by recipient
            cdis[targetCDIId].cognitivePoints = cdis[targetCDIId].cognitivePoints.add(_amount);
        } else {
             // If recipient has no CDI, mint points to them, implicitly creating a 'virtual' CP balance.
             // This needs more thought for a full system if CP isn't an ERC20 itself.
             // For now, we'll assume CP always accrue to a CDI.
             revert("CDIProtocol: Recipient does not own a CDI to mint points to.");
        }
        emit CognitivePointsMinted(_recipient, _amount, _proofHash);
    }

    /**
     * @dev A CDI owner can burn their own Cognitive Points for specific in-protocol actions or to signal commitment.
     * @param _cdiId The ID of the CDI from which to burn CP.
     * @param _amount The amount of Cognitive Points to burn.
     */
    function burnCognitivePoints(uint256 _cdiId, uint256 _amount) public onlyCDIOwner(_cdiId) onlyActiveCDI(_cdiId) {
        require(cdis[_cdiId].cognitivePoints >= _amount, "CDIProtocol: Insufficient Cognitive Points");
        cdis[_cdiId].cognitivePoints = cdis[_cdiId].cognitivePoints.sub(_amount);
        emit CognitivePointsBurned(_cdiId, _amount);
    }

    // --- Oracle & Off-chain Cognitive Service Integration ---

    /**
     * @dev The protocol owner registers a new trusted off-chain oracle.
     * Trusted oracles are authorized to submit verified results for cognitive services and mint CP.
     * @param _oracleAddress The address of the new oracle.
     * @param _name A human-readable name for the oracle.
     */
    function registerTrustedOracle(address _oracleAddress, string memory _name) public onlyOwner {
        require(_oracleAddress != address(0), "CDIProtocol: Oracle address cannot be zero");
        require(!isTrustedOracle[_oracleAddress], "CDIProtocol: Oracle already registered");
        isTrustedOracle[_oracleAddress] = true;
        trustedOracleNames[_oracleAddress] = _name;
        emit OracleRegistered(_oracleAddress, _name);
    }

    /**
     * @dev The protocol owner revokes a trusted oracle's privileges.
     * @param _oracleAddress The address of the oracle to revoke.
     */
    function revokeTrustedOracle(address _oracleAddress) public onlyOwner {
        require(isTrustedOracle[_oracleAddress], "CDIProtocol: Oracle not registered");
        isTrustedOracle[_oracleAddress] = false;
        delete trustedOracleNames[_oracleAddress];
        emit OracleRevoked(_oracleAddress);
    }

    /**
     * @dev A CDI owner requests an off-chain cognitive service (e.g., AI analysis or data computation).
     * The `_serviceRequestHash` points to the full request details off-chain (e.g., IPFS CID).
     * @param _cdiId The ID of the CDI making the request.
     * @param _serviceRequestHash Hash of the detailed service request.
     * @param _rewardAmount The amount of Cognitive Points to reward the oracle upon successful completion.
     *                      These points are reserved from the CDI's balance.
     */
    function requestCognitiveService(uint256 _cdiId, bytes32 _serviceRequestHash, uint256 _rewardAmount) public onlyCDIOwner(_cdiId) onlyActiveCDI(_cdiId) {
        require(cdis[_cdiId].cognitivePoints >= _rewardAmount, "CDIProtocol: Insufficient CP to fund service reward");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        cognitiveServiceTasks[newTaskId] = CognitiveServiceTask({
            requesterCDIId: _cdiId,
            serviceRequestHash: _serviceRequestHash,
            rewardAmount: _rewardAmount,
            resultHash: bytes32(0),
            verificationData: "",
            oracleAddress: address(0),
            completed: false,
            submittedTimestamp: 0
        });

        // Temporarily reduce CP from CDI to reserve for reward
        cdis[_cdiId].cognitivePoints = cdis[_cdiId].cognitivePoints.sub(_rewardAmount);

        emit CognitiveServiceRequested(newTaskId, _cdiId, _serviceRequestHash, _rewardAmount);
    }

    /**
     * @dev A trusted oracle submits the verified result of a cognitive service request.
     * Upon successful submission, the oracle is rewarded, and the CDI receives potential benefits (e.g., CP).
     * @param _taskId The ID of the cognitive service task.
     * @param _cdiId The ID of the CDI that requested the service.
     * @param _resultHash A hash of the verified result data.
     * @param _verificationData Data used to cryptographically verify the result (e.g., ZK-proof, signature).
     */
    function submitCognitiveServiceResult(uint256 _taskId, uint256 _cdiId, bytes32 _resultHash, bytes memory _verificationData) public onlyTrustedOracle onlyActiveCDI(_cdiId) {
        CognitiveServiceTask storage task = cognitiveServiceTasks[_taskId];
        require(task.requesterCDIId == _cdiId, "CDIProtocol: Task not associated with this CDI");
        require(!task.completed, "CDIProtocol: Task already completed");
        require(task.rewardAmount > 0, "CDIProtocol: Task has no reward specified");

        // In a real scenario, _verificationData would be used to verify the _resultHash cryptographically.
        // For this example, we assume the oracle's trustworthiness.
        // For a full implementation, consider integrating a ZK-proof verifier or specific signature scheme.

        task.resultHash = _resultHash;
        task.verificationData = _verificationData;
        task.oracleAddress = _msgSender();
        task.completed = true;
        task.submittedTimestamp = block.timestamp;

        // Reward the CDI for completion by giving back the reserved CP and maybe more for successful outcome
        // For simplicity, we just return the reserved CP. In advanced, the result itself could lead to *more* CP.
        cdis[_cdiId].cognitivePoints = cdis[_cdiId].cognitivePoints.add(task.rewardAmount); // Return reserved CP to CDI

        // Optionally, reward the oracle (e.g., with a separate utility token or a percentage of the rewardAmount)
        // For simplicity here, the oracle's reward is abstract, based on trust.

        emit CognitiveServiceResultSubmitted(_taskId, _cdiId, _resultHash, _msgSender());
    }

    // --- CDI Staking for Network Power ---

    /**
     * @dev A CDI owner stakes their CDI to contribute to the network's "Cognitive Power"
     * and become eligible for staking rewards.
     * Requires the CDI to exist and not be already staked.
     * @param _cdiId The ID of the CDI to stake.
     */
    function stakeCDIForPower(uint256 _cdiId) public onlyCDIOwner(_cdiId) onlyActiveCDI(_cdiId) {
        require(cdis[_cdiId].lastStakedTimestamp == 0, "CDIProtocol: CDI is already staked");
        require(cdis[_cdiId].cognitivePoints > 0, "CDIProtocol: Cannot stake CDI with 0 cognitive points");

        cdis[_cdiId].lastStakedTimestamp = block.timestamp;
        cdis[_cdiId].stakedAmount = cdis[_cdiId].cognitivePoints; // Staking amount is initial CP
        // In a more complex system, 'stakedAmount' might be a separate resource or influence.
        // For simplicity, we just mark it as staked and use its CP for rewards calculations.

        emit CDIStaked(_cdiId, _msgSender());
    }

    /**
     * @dev A CDI owner unstakes their CDI after a cool-down period.
     * @param _cdiId The ID of the CDI to unstake.
     */
    function unstakeCDI(uint256 _cdiId) public onlyCDIOwner(_cdiId) onlyActiveCDI(_cdiId) {
        require(cdis[_cdiId].lastStakedTimestamp != 0, "CDIProtocol: CDI is not staked");
        require(block.timestamp >= cdis[_cdiId].lastStakedTimestamp + CDI_STAKING_COOLDOWN, "CDIProtocol: Staking cooldown period not over");

        // Claim any pending rewards before unstaking
        _claimRewards(_cdiId);

        cdis[_cdiId].lastStakedTimestamp = 0;
        cdis[_cdiId].stakedAmount = 0;

        emit CDIUnstaked(_cdiId, _msgSender());
    }

    /**
     * @dev Internal function to calculate and distribute staking rewards.
     * @param _cdiId The ID of the CDI to claim rewards for.
     */
    function _claimRewards(uint256 _cdiId) internal {
        if (cdis[_cdiId].lastStakedTimestamp == 0) return; // Not staked
        if (cdis[_cdiId].stakedAmount == 0) return; // No CP to earn rewards

        uint256 blocksStaked = block.number - (cdis[_cdiId].lastStakedTimestamp / 1 seconds); // Approximation
        // For more precision, we should track block.number directly or use a Chainlink Keepers-like system.
        // Here, we use timestamp/1s as block number approximation for simplicity.
        
        uint256 reward = blocksStaked.mul(stakingRewardPerBlock);

        if (reward > 0) {
            cdis[_cdiId].cognitivePoints = cdis[_cdiId].cognitivePoints.add(reward);
            cdis[_cdiId].lastStakedTimestamp = block.timestamp; // Reset timestamp for future rewards
            emit RewardsClaimed(_cdiId, reward);
        }
    }

    /**
     * @dev Allows staked CDI owners to claim accrued Cognitive Point rewards.
     * This will call the internal _claimRewards function.
     * @param _cdiId The ID of the CDI to claim rewards for.
     */
    function claimStakingRewards(uint256 _cdiId) public onlyCDIOwner(_cdiId) onlyActiveCDI(_cdiId) {
        _claimRewards(_cdiId);
    }

    // --- Decentralized Governance (DAO) ---

    /**
     * @dev Any CDI above a certain Cognitive Level can propose changes to protocol parameters.
     * This forms the basis of the protocol's decentralized governance.
     * @param _parameterKey A keccak256 hash representing the parameter to change (e.g., `keccak256("stakingRewardPerBlock")`).
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposal.
     */
    function proposeProtocolParameter(bytes32 _parameterKey, uint256 _newValue, string memory _description) public {
        // Find a CDI owned by msg.sender to act as proposer
        require(ownerCDIs[_msgSender()].length > 0, "CDIProtocol: Caller does not own a CDI to propose");
        uint256 proposerCDIId = ownerCDIs[_msgSender()][0]; // Use the first CDI found
        require(getCDICognitiveLevel(proposerCDIId) >= proposalMinCPLimit, "CDIProtocol: CDI's cognitive level too low to propose");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            proposerCDIId: proposerCDIId,
            parameterKey: _parameterKey,
            newValue: _newValue,
            description: _description,
            startBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(uint256 => bool)(),
            executed: false
        });

        emit ProposalCreated(newProposalId, proposerCDIId, _parameterKey, _newValue, _description);
    }

    /**
     * @dev CDI owners vote on active proposals. Vote weight is proportional to their CDI's Cognitive Points.
     * A CDI can only vote once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for" vote, false for "against" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposerCDIId != 0, "CDIProtocol: Proposal does not exist");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "CDIProtocol: Voting period not active");

        // Find a CDI owned by msg.sender to act as voter
        require(ownerCDIs[_msgSender()].length > 0, "CDIProtocol: Caller does not own a CDI to vote");
        uint256 voterCDIId = ownerCDIs[_msgSender()][0]; // Use the first CDI found
        require(!proposal.hasVoted[voterCDIId], "CDIProtocol: CDI has already voted on this proposal");
        require(getCDICognitiveLevel(voterCDIId) > 0, "CDIProtocol: CDI must have a cognitive level > 0 to vote");

        proposal.hasVoted[voterCDIId] = true;
        uint256 voteWeight = cdis[voterCDIId].cognitivePoints; // Vote weight based on CP

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voteWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voteWeight);
        }

        emit VotedOnProposal(_proposalId, voterCDIId, _support);
    }

    /**
     * @dev Executes a passed proposal. Anyone can call this after the voting period ends and if the proposal passes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposerCDIId != 0, "CDIProtocol: Proposal does not exist");
        require(block.number > proposal.endBlock, "CDIProtocol: Voting period not ended");
        require(!proposal.executed, "CDIProtocol: Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "CDIProtocol: Proposal did not pass");

        proposal.executed = true;

        // Apply parameter change based on _parameterKey
        if (proposal.parameterKey == keccak256("stakingRewardPerBlock")) {
            stakingRewardPerBlock = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("votingPeriodBlocks")) {
            votingPeriodBlocks = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("proposalMinCPLimit")) {
            proposalMinCPLimit = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("addCognitiveLevelThreshold")) {
            // Special handling: adds a new threshold, assuming `newValue` is the new CP for the next level
            cognitiveLevelThresholds.push(proposal.newValue);
        } else {
            revert("CDIProtocol: Unknown parameter key for execution");
        }

        emit ProposalExecuted(_proposalId);
    }

    // --- Advanced CDI Interactions & Identity Features ---

    /**
     * @dev A CDI delegates a specific task or responsibility to another CDI.
     * This enables on-chain collaboration and specialized roles.
     * Requires the delegator to pay a CP reward upon (future) completion.
     * @param _delegatorCDI The ID of the CDI delegating the task.
     * @param _delegateeCDI The ID of the CDI receiving the delegation.
     * @param _taskDetailsHash A hash pointing to the details of the task (e.g., IPFS CID).
     * @param _cpReward The Cognitive Points to be rewarded to the delegatee upon verified completion.
     */
    function delegateCDITask(uint256 _delegatorCDI, uint256 _delegateeCDI, bytes32 _taskDetailsHash, uint256 _cpReward) public onlyCDIOwner(_delegatorCDI) onlyActiveCDI(_delegatorCDI) onlyActiveCDI(_delegateeCDI) {
        require(_delegatorCDI != _delegateeCDI, "CDIProtocol: Cannot delegate to self");
        require(cdis[_delegatorCDI].cognitivePoints >= _cpReward, "CDIProtocol: Insufficient CP to fund delegation reward");

        // Here, a task ID can be generated and managed, similar to CognitiveServiceTask.
        // For simplicity, we just log the delegation. Verification of completion and reward transfer
        // would typically happen via another oracle submission or an attestation.

        cdis[_delegatorCDI].cognitivePoints = cdis[_delegatorCDI].cognitivePoints.sub(_cpReward); // Escrow reward

        emit CDITaskDelegated(_delegatorCDI, _delegateeCDI, _taskDetailsHash, _cpReward);
        // A follow-up function (e.g., `completeDelegatedTask` by _delegateeCDI, verified by oracle/attestation)
        // would be needed to release `_cpReward` to _delegateeCDI.
    }

    /**
     * @dev A trusted entity (e.g., another CDI, an oracle, or governance) can attest to a specific
     * verifiable property or characteristic of a CDI. This builds reputation and verifiable credentials.
     * @param _cdiId The ID of the CDI being attested to.
     * @param _propertyHash A hash representing the property (e.g., `keccak256("VerifiedHuman")`, `keccak256("AI_Enabled")`).
     * @param _value The boolean value of the property.
     * @param _attestationProof Cryptographic proof or identifier for the attestation.
     */
    function attestToCDIProperty(uint256 _cdiId, bytes32 _propertyHash, bool _value, bytes memory _attestationProof) public onlyActiveCDI(_cdiId) {
        // Only trusted entities can attest (e.g., Owner, Oracles, or specific CDIs with high CP/level)
        // For simplicity, let's allow Owner, any Trusted Oracle, or a CDI with Level 3+ to attest.
        bool isAuthorizedAttester = (_msgSender() == owner() || isTrustedOracle[_msgSender()]);
        
        // Check if _msgSender() owns a CDI and if that CDI has a high level
        if (!isAuthorizedAttester && ownerCDIs[_msgSender()].length > 0) {
            uint256 attesterCDIId = ownerCDIs[_msgSender()][0];
            if (getCDICognitiveLevel(attesterCDIId) >= (cognitiveLevelThresholds.length -1) ) { // Check for highest level
                isAuthorizedAttester = true;
            }
        }
        require(isAuthorizedAttester, "CDIProtocol: Caller not authorized to attest");

        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();

        attestations[newAttestationId] = Attestation({
            attester: _msgSender(),
            targetCDIId: _cdiId,
            propertyHash: _propertyHash,
            value: _value,
            attestationProof: _attestationProof,
            timestamp: block.timestamp,
            challenged: false
        });

        emit CDIAttested(newAttestationId, _msgSender(), _cdiId, _propertyHash, _value);
    }

    /**
     * @dev Allows a CDI or a third party to formally challenge an existing attestation.
     * This can trigger a governance review process (not fully implemented here, but implied).
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reason A string explaining the reason for the challenge.
     */
    function challengeAttestation(uint256 _attestationId, string memory _reason) public {
        Attestation storage attestation = attestations[_attestationId];
        require(attestation.targetCDIId != 0, "CDIProtocol: Attestation does not exist");
        require(!attestation.challenged, "CDIProtocol: Attestation already challenged");
        
        // Only CDI owners or trusted parties can challenge
        bool isAuthorizedChallenger = (ownerOf(attestation.targetCDIId) == _msgSender() || isTrustedOracle[_msgSender()] || _msgSender() == owner());
        if (!isAuthorizedChallenger && ownerCDIs[_msgSender()].length > 0) {
            uint256 challengerCDIId = ownerCDIs[_msgSender()][0];
             // Require some level to challenge to prevent spam
            require(getCDICognitiveLevel(challengerCDIId) >= 1, "CDIProtocol: Challenger CDI level too low"); 
            isAuthorizedChallenger = true;
        }
        require(isAuthorizedChallenger, "CDIProtocol: Not authorized to challenge this attestation");

        attestation.challenged = true;
        
        // In a full implementation, this would trigger a governance proposal for review.
        // For simplicity, we just mark it as challenged.
        emit AttestationChallenged(_attestationId, ownerCDIs[_msgSender()].length > 0 ? ownerCDIs[_msgSender()][0] : 0, _reason);
    }


    /**
     * @dev CDI owners can grant or revoke specific addresses permission to view sensitive, private attributes
     * linked to their CDI. This enables granular privacy control.
     * @param _cdiId The ID of the CDI.
     * @param _viewer The address to grant/revoke access to.
     * @param _attributeHash A hash identifying the specific attribute (e.g., `keccak256("verifiedName")`).
     * @param _canView True to grant access, false to revoke.
     */
    function setCDIAttributeAccess(uint256 _cdiId, address _viewer, bytes32 _attributeHash, bool _canView) public onlyCDIOwner(_cdiId) onlyActiveCDI(_cdiId) {
        require(_viewer != address(0), "CDIProtocol: Viewer address cannot be zero");
        cdiAttributeAccess[_cdiId][_viewer][_attributeHash] = _canView;
        emit CDIAttributeAccessSet(_cdiId, _viewer, _attributeHash, _canView);
    }

    /**
     * @dev Initiates a request for two CDIs to merge their identities.
     * This is an advanced concept allowing for identity evolution and consolidation.
     * Both CDI owners must approve the merge.
     * @param _cdiId1 The ID of the first CDI.
     * @param _cdiId2 The ID of the second CDI.
     * @param _mergeRationaleHash A hash explaining the reason/documentation for the merge.
     */
    function initiateCDIMergeRequest(uint256 _cdiId1, uint256 _cdiId2, bytes32 _mergeRationaleHash) public onlyActiveCDI(_cdiId1) onlyActiveCDI(_cdiId2) {
        require(_cdiId1 != _cdiId2, "CDIProtocol: Cannot merge a CDI with itself");
        require(ownerOf(_cdiId1) == _msgSender() || ownerOf(_cdiId2) == _msgSender(), "CDIProtocol: Caller must own one of the CDIs to initiate merge");

        _mergeRequestIds.increment();
        uint256 newMergeRequestId = _mergeRequestIds.current();

        cdiMergeRequests[newMergeRequestId] = CDIMergeRequest({
            cdi1Id: _cdiId1,
            cdi2Id: _cdiId2,
            mergeRationaleHash: _mergeRationaleHash,
            proposedTimestamp: block.timestamp,
            approvedBy1: ownerOf(_cdiId1) == _msgSender(), // If caller owns CDI1, approve it
            approvedBy2: ownerOf(_cdiId2) == _msgSender(), // If caller owns CDI2, approve it
            merged: false
        });

        emit CDIMergeRequested(newMergeRequestId, _cdiId1, _cdiId2, _mergeRationaleHash);
    }

    /**
     * @dev The owners of the respective CDIs approve a merge request.
     * Once both owners approve, the merge can be executed.
     * @param _mergeRequestId The ID of the merge request.
     */
    function approveCDIMerge(uint256 _mergeRequestId) public {
        CDIMergeRequest storage mergeRequest = cdiMergeRequests[_mergeRequestId];
        require(mergeRequest.cdi1Id != 0, "CDIProtocol: Merge request does not exist");
        require(!mergeRequest.merged, "CDIProtocol: Merge already completed");

        require(ownerOf(mergeRequest.cdi1Id) == _msgSender() || ownerOf(mergeRequest.cdi2Id) == _msgSender(), "CDIProtocol: Caller must own one of the CDIs to approve");

        if (ownerOf(mergeRequest.cdi1Id) == _msgSender()) {
            mergeRequest.approvedBy1 = true;
        }
        if (ownerOf(mergeRequest.cdi2Id) == _msgSender()) {
            mergeRequest.approvedBy2 = true;
        }

        emit CDIMergeApproved(_mergeRequestId, ownerCDIs[_msgSender()].length > 0 ? ownerCDIs[_msgSender()][0] : 0); // Emit which CDI approved

        if (mergeRequest.approvedBy1 && mergeRequest.approvedBy2) {
            // Execute merge logic
            _executeCDIMerge(_mergeRequestId);
        }
    }

    /**
     * @dev Internal function to execute the actual merging of two CDIs.
     * Combines Cognitive Points and marks one CDI as merged, effectively removing it.
     * @param _mergeRequestId The ID of the merge request.
     */
    function _executeCDIMerge(uint256 _mergeRequestId) internal {
        CDIMergeRequest storage mergeRequest = cdiMergeRequests[_mergeRequestId];
        require(mergeRequest.approvedBy1 && mergeRequest.approvedBy2, "CDIProtocol: Both parties must approve merge");
        require(!mergeRequest.merged, "CDIProtocol: Merge already executed");

        // Decide which CDI is the "primary" one to receive points and remain active.
        // For simplicity, let's say cdi1Id remains active, and cdi2Id is absorbed.
        uint256 primaryCDIId = mergeRequest.cdi1Id;
        uint256 secondaryCDIId = mergeRequest.cdi2Id;

        // Combine cognitive points
        cdis[primaryCDIId].cognitivePoints = cdis[primaryCDIId].cognitivePoints.add(cdis[secondaryCDIId].cognitivePoints);

        // Mark secondary CDI as merged and burn its NFT token
        cdis[secondaryCDIId].isMerged = true;
        _burn(secondaryCDIId); // Burns the ERC721 token

        // Clear owner association for the merged CDI
        address secondaryOwner = cdis[secondaryCDIId].owner;
        uint256[] storage secondaryOwnerCDIs = ownerCDIs[secondaryOwner];
        for (uint256 i = 0; i < secondaryOwnerCDIs.length; i++) {
            if (secondaryOwnerCDIs[i] == secondaryCDIId) {
                secondaryOwnerCDIs[i] = secondaryOwnerCDIs[secondaryOwnerCDIs.length - 1];
                secondaryOwnerCDIs.pop();
                break;
            }
        }
        
        // Reset secondary CDI's data (except for `isMerged`) to save space
        delete cdis[secondaryCDIId].name;
        delete cdis[secondaryCDIId].metadataURI;
        delete cdis[secondaryCDIId].owner; // This will effectively make ownerOf(secondaryCDIId) return address(0)

        mergeRequest.merged = true;

        emit CDIMerged(_mergeRequestId, primaryCDIId, secondaryCDIId);
    }

    /**
     * @dev A CDI itself (if it reaches a certain level or is configured as an issuer) can mint
     * non-transferable, soulbound credentials to other addresses or CDIs, signifying achievements, roles, or affiliations.
     * @param _issuerCDIId The ID of the CDI issuing the credential.
     * @param _recipient The address or CDI owner receiving the credential.
     * @param _credentialHash A hash of the credential details (e.g., IPFS CID).
     * @param _expirationTimestamp The timestamp when the credential expires (0 for never).
     */
    function mintSoulboundCredential(uint256 _issuerCDIId, address _recipient, bytes32 _credentialHash, uint256 _expirationTimestamp) public onlyCDIOwner(_issuerCDIId) onlyActiveCDI(_issuerCDIId) {
        // Require issuer CDI to be of a certain level to issue credentials
        require(getCDICognitiveLevel(_issuerCDIId) >= 2, "CDIProtocol: Issuer CDI level too low to mint credentials");
        require(_recipient != address(0), "CDIProtocol: Recipient cannot be zero address");
        require(_credentialHash != bytes32(0), "CDIProtocol: Credential hash cannot be empty");

        _credentialIds.increment();
        uint256 newCredentialId = _credentialIds.current();

        soulboundCredentials[newCredentialId] = SoulboundCredential({
            issuerCDIId: _issuerCDIId,
            recipient: _recipient,
            credentialHash: _credentialHash,
            expirationTimestamp: _expirationTimestamp,
            mintedTimestamp: block.timestamp
        });

        emit SoulboundCredentialMinted(newCredentialId, _issuerCDIId, _recipient, _credentialHash, _expirationTimestamp);
    }

    // --- View Functions (ERC721 Overrides and Helpers) ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Prevent accidental transfers via ERC721 methods not explicitly handled by `transferCDI`
        // Allows minting (from address(0)) and transfers via `transferCDI` function.
        // It strictly prevents transfers by approved or operator.
        // This makes CDIs "soulbound" unless `transferCDI` is used.
        if (from != address(0) && to != address(0) && _msgSender() != ownerOf(tokenId)) {
            // Allow transfers initiated by the contract owner for maintenance if needed,
            // otherwise, only specific `transferCDI` or `_executeCDIMerge` should transfer.
            require(false, "CDIProtocol: Transfers are restricted. Use 'transferCDI' for justified transfers.");
        }
    }

    function _approve(address to, uint256 tokenId) internal override {
        // Explicitly disallow approvals to enforce soulbound-like nature.
        // CDI tokens should not be transferable via generic `transferFrom` or `safeTransferFrom` by approved parties.
        revert("CDIProtocol: Approvals are not allowed for CDI tokens.");
    }

    function approve(address to, uint256 tokenId) public view override {
        revert("CDIProtocol: Approvals are not allowed for CDI tokens.");
    }

    function setApprovalForAll(address operator, bool approved) public view override {
        revert("CDIProtocol: Operators are not allowed for CDI tokens.");
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return address(0); // No approvals are granted
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return false; // No operators are approved
    }
}

```