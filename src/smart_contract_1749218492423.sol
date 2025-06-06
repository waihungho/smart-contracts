Okay, this is an exciting challenge! Let's design a smart contract around a complex and creative concept that isn't a standard template.

**Concept:** A Decentralized Autonomous Creative Commons (DACC) platform where creators can mint NFTs representing their digital works and attach on-chain, programmable licenses. Users can acquire licenses for specific purposes (commercial, remix, etc.), potentially paying royalties directly to the creator through the contract. The platform itself is governed by token holders (a simple DAO).

**Advanced/Creative/Trendy Aspects:**
1.  **NFTs as Creative Works:** Standard, but integrating deep licensing is less common.
2.  **On-Chain Programmable Licenses:** Defining license terms (permissions, obligations) in code.
3.  **License Acquisition & Payment:** Users pay *through the contract* to obtain a time-bound or perpetual license recorded on-chain.
4.  **Creator Royalties:** Automatic distribution of license fees to the creator of the work.
5.  **Derivative Work Tracking:** Allowing registration of new works as derivatives of existing ones, creating a lineage.
6.  **Decentralized Governance:** DAO controlling platform parameters (approved license types, platform fees, etc.).
7.  **Time-Bound Licenses:** Licenses with expiry dates.
8.  **Multi-Token Payment:** Supporting different ERC20 tokens for license fees.

Let's outline the structure and functions.

---

## Smart Contract Outline: Decentralized Autonomous Creative Commons (DACC)

This contract implements a platform for creators to mint unique digital works as NFTs and manage programmable licenses associated with these works. It incorporates a decentralized governance mechanism for platform evolution.

**Inherits:** ERC721, ReentrancyGuard (from OpenZeppelin for safety)
**Uses:** IERC20 (for license payments)

**Key Components:**
1.  **Creative Works (NFTs):** ERC721 tokens representing unique digital creations. Each work stores creator information and initial metadata.
2.  **License Types:** Pre-defined or governance-approved templates for licenses (e.g., "Non-Commercial Use," "Commercial License," "Remix License"). Each type specifies permissions and potential fees.
3.  **Issued Licenses:** Specific instances of a License Type granted for a particular Creative Work to a specific Licensee, with start/end times and conditions.
4.  **Royalty/Fee Management:** Handles collection and distribution of license fees to creators and potential platform fees to a governance-controlled treasury.
5.  **Derivative Works:** Allows linking a new Creative Work NFT to a parent work, recording creative lineage.
6.  **Governance:** A simple proposal and voting system to approve new license types, update platform fees, and manage other core parameters.

**Data Structures:**
*   `CreativeWork`: Stores NFT metadata, creator, timestamp.
*   `LicenseType`: Defines license permissions, fee structure, duration options.
*   `IssuedLicense`: Tracks an active license grant, licensee, period, conditions.
*   `Proposal`: Stores details for governance proposals (target function, parameters, votes, state).

**Mappings & State Variables:**
*   Work tracking (`_tokenIds`, `idToWork`, ERC721 internal mappings).
*   License Type registry (`licenseTypes`).
*   Issued Licenses tracking (`issuedLicenses`, `issuedLicensesByWork`, `issuedLicensesByLicensee`).
*   Derivative links (`parentWork`, `derivativeWorks`).
*   Royalty/Fee balances (`workRoyalties`, `platformFeeBalances`).
*   Governance state (`proposals`, `voters`, `proposalCount`).
*   Approved fee tokens (`approvedFeeTokens`).
*   Platform fee settings (`platformFeeRecipient`, `platformFeePercentage`).

---

## Function Summary

**I. ERC721 Standard Functions (Overridden/Implemented):** (Inherited from OpenZeppelin, included for completeness and count)
1.  `balanceOf(address owner) view returns (uint256)`
2.  `ownerOf(uint256 tokenId) view returns (address)`
3.  `approve(address to, uint256 tokenId)`
4.  `getApproved(uint256 tokenId) view returns (address)`
5.  `setApprovalForAll(address operator, bool approved)`
6.  `isApprovedForAll(address owner, address operator) view returns (bool)`
7.  `transferFrom(address from, address to, uint256 tokenId)`
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`
10. `supportsInterface(bytes4 interfaceId) view returns (bool)`

**II. Creative Work & Metadata:**
11. `mintWork(string calldata tokenURI_) returns (uint256)`: Mints a new Creative Work NFT, assigns creator, and stores metadata. Only callable by designated creators (initially deployer, potentially governance controlled).
12. `tokenURI(uint256 tokenId) view returns (string memory)`: Returns the metadata URI for a work (ERC721 Metadata Standard).
13. `getWorkDetails(uint256 workId) view returns (CreativeWork memory)`: Retrieves details of a specific Creative Work.
14. `getCreator(uint256 workId) view returns (address)`: Gets the original creator of a work (stored separately from current NFT owner).
15. `getWorkCount() view returns (uint256)`: Gets the total number of minted works.

**III. License Type Management (Governable):**
16. `defineLicenseType(string memory name, string memory description, LicensePermissions permissions, uint256 feeAmount, address feeToken, uint256 duration)`: Propose or execute (via governance) defining a new standard license type.
17. `getLicenseTypeDetails(uint256 licenseTypeId) view returns (LicenseType memory)`: Retrieves details of a standard license type.
18. `getLicenseTypeCount() view returns (uint256)`: Gets the total number of defined license types.
19. `approveFeeToken(address tokenAddress)`: Propose or execute (via governance) approving an ERC20 token for use in license fees.
20. `isFeeTokenApproved(address tokenAddress) view returns (bool)`: Checks if a token is approved for fees.
21. `getApprovedFeeTokens() view returns (address[] memory)`: Lists all approved fee tokens.

**IV. Issued License Management:**
22. `issueLicense(uint256 workId, uint256 licenseTypeId, address licensee)`: Allows a user to acquire a license for a work. Handles potential fee collection. Requires approval if fee token is ERC20.
23. `isLicenseValid(uint256 issuedLicenseId) view returns (bool)`: Checks if a specific issued license exists and is still active (not expired, not revoked).
24. `revokeLicense(uint256 issuedLicenseId, string memory reason)`: Allows the original creator of the work or governance to revoke an issued license (e.g., for breach of terms).
25. `burnIssuedLicense(uint256 issuedLicenseId)`: Allows the licensee to burn their own issued license.
26. `transferIssuedLicense(uint256 issuedLicenseId, address newLicensee)`: Allows the current licensee to transfer the license, if the license type permits.
27. `getIssuedLicenseDetails(uint256 issuedLicenseId) view returns (IssuedLicense memory)`: Retrieves details of a specific issued license.
28. `getIssuedLicenseCount() view returns (uint256)`: Gets the total number of issued licenses.
29. `getIssuedLicensesForWork(uint256 workId) view returns (uint256[] memory)`: Lists all issued license IDs for a specific work.
30. `getIssuedLicensesForUser(address licensee) view returns (uint256[] memory)`: Lists all issued license IDs held by a specific address.

**V. Royalty & Fee Management:**
31. `claimRoyalties(uint256 workId, address tokenAddress)`: Allows the original creator of a work to claim collected license fees in a specific token.
32. `getTotalRoyaltiesCollected(uint256 workId, address tokenAddress) view returns (uint256)`: Gets the total collectible royalties for a work in a token.
33. `withdrawPlatformFees(address tokenAddress)`: Allows the platform fee recipient (set by governance) to withdraw collected platform fees.
34. `getTotalPlatformFeesCollected(address tokenAddress) view returns (uint256)`: Gets the total collected platform fees in a token.
35. `updatePlatformFeeRecipient(address newRecipient)`: Propose or execute (via governance) updating the address receiving platform fees.
36. `updatePlatformFeePercentage(uint256 newPercentage)`: Propose or execute (via governance) updating the percentage of license fees taken by the platform.

**VI. Derivative Work Tracking:**
37. `registerDerivativeWork(uint256 derivativeWorkId, uint256 parentWorkId)`: Allows the creator of `derivativeWorkId` to register it as a derivative of `parentWorkId`.
38. `getParentWork(uint256 derivativeWorkId) view returns (uint256)`: Gets the parent work ID for a given derivative work ID (returns 0 if none registered).
39. `getDerivativeWorks(uint256 parentWorkId) view returns (uint256[] memory)`: Lists all registered derivative work IDs for a given parent work.

**VII. Decentralized Governance:**
40. `proposeGovernanceAction(uint256 actionType, bytes memory data)`: Allows designated proposers to create a new governance proposal. `actionType` maps to specific governable functions (e.g., define license, update fee). `data` contains encoded arguments for that function.
41. `voteOnProposal(uint256 proposalId, bool support)`: Allows designated voters to vote on an active proposal.
42. `executeProposal(uint256 proposalId)`: Executes a proposal if it has passed the voting period and met the required support threshold.
43. `getProposalCount() view returns (uint256)`: Gets the total number of governance proposals.
44. `getProposalDetails(uint256 proposalId) view returns (Proposal memory)`: Retrieves details of a specific governance proposal.

---

Okay, that's well over 20 functions covering the core concept and governance. Now, let's write the Solidity code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Outline:
// I. ERC721 Standard (Inherited)
// II. Creative Work & Metadata
// III. License Type Management (Governable)
// IV. Issued License Management
// V. Royalty & Fee Management
// VI. Derivative Work Tracking
// VII. Decentralized Governance

// Function Summary:
// I. ERC721 Standard Functions (Implemented via inheritance):
//    1. balanceOf(address owner) view returns (uint256)
//    2. ownerOf(uint256 tokenId) view returns (address)
//    3. approve(address to, uint256 tokenId)
//    4. getApproved(uint256 tokenId) view returns (address)
//    5. setApprovalForAll(address operator, bool approved)
//    6. isApprovedForAll(address owner, address operator) view returns (bool)
//    7. transferFrom(address from, address to, uint256 tokenId)
//    8. safeTransferFrom(address from, address to, uint256 tokenId)
//    9. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
//    10. supportsInterface(bytes4 interfaceId) view returns (bool)

// II. Creative Work & Metadata:
//    11. mintWork(string calldata tokenURI_) returns (uint256)
//    12. tokenURI(uint256 tokenId) view returns (string memory) - Override
//    13. getWorkDetails(uint256 workId) view returns (CreativeWork memory)
//    14. getCreator(uint256 workId) view returns (address)
//    15. getWorkCount() view returns (uint256)

// III. License Type Management (Governable):
//    16. defineLicenseType(string memory name, string memory description, LicensePermissions permissions, uint256 feeAmount, address feeToken, uint256 duration) - Executed by Governance
//    17. getLicenseTypeDetails(uint256 licenseTypeId) view returns (LicenseType memory)
//    18. getLicenseTypeCount() view returns (uint256)
//    19. approveFeeToken(address tokenAddress) - Executed by Governance
//    20. isFeeTokenApproved(address tokenAddress) view returns (bool)
//    21. getApprovedFeeTokens() view returns (address[] memory)

// IV. Issued License Management:
//    22. issueLicense(uint256 workId, uint256 licenseTypeId, address licensee)
//    23. isLicenseValid(uint256 issuedLicenseId) view returns (bool)
//    24. revokeLicense(uint256 issuedLicenseId, string memory reason)
//    25. burnIssuedLicense(uint256 issuedLicenseId)
//    26. transferIssuedLicense(uint256 issuedLicenseId, address newLicensee)
//    27. getIssuedLicenseDetails(uint256 issuedLicenseId) view returns (IssuedLicense memory)
//    28. getIssuedLicenseCount() view returns (uint256)
//    29. getIssuedLicensesForWork(uint256 workId) view returns (uint256[] memory)
//    30. getIssuedLicensesForUser(address licensee) view returns (uint256[] memory)

// V. Royalty & Fee Management:
//    31. claimRoyalties(uint256 workId, address tokenAddress)
//    32. getTotalRoyaltiesCollected(uint256 workId, address tokenAddress) view returns (uint256)
//    33. withdrawPlatformFees(address tokenAddress)
//    34. getTotalPlatformFeesCollected(address tokenAddress) view returns (uint256)
//    35. updatePlatformFeeRecipient(address newRecipient) - Executed by Governance
//    36. updatePlatformFeePercentage(uint256 newPercentage) - Executed by Governance

// VI. Derivative Work Tracking:
//    37. registerDerivativeWork(uint256 derivativeWorkId, uint256 parentWorkId)
//    38. getParentWork(uint256 derivativeWorkId) view returns (uint256)
//    39. getDerivativeWorks(uint256 parentWorkId) view returns (uint256[] memory)

// VII. Decentralized Governance:
//    40. proposeGovernanceAction(uint256 actionType, bytes memory data)
//    41. voteOnProposal(uint256 proposalId, bool support)
//    42. executeProposal(uint256 proposalId)
//    43. getProposalCount() view returns (uint256)
//    44. getProposalDetails(uint256 proposalId) view returns (Proposal memory)

// VIII. Internal Governance Execution Helpers:
//    executeGovernanceAction(uint256 actionType, bytes memory data) internal

contract DecentralizedAutonomousCreativeCommons is ERC721, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;

    // --- Errors ---
    error DACC__OnlyCreatorCanMint(address minter);
    error DACC__WorkDoesNotExist(uint256 workId);
    error DACC__LicenseTypeDoesNotExist(uint256 licenseTypeId);
    error DACC__IssuedLicenseDoesNotExist(uint256 issuedLicenseId);
    error DACC__LicenseAlreadyExpired(uint256 issuedLicenseId);
    error DACC__LicenseRevoked(uint256 issuedLicenseId);
    error DACC__NotLicensee(address caller, address licensee);
    error DACC__LicenseNotTransferable(uint256 licenseTypeId);
    error DACC__FeeTokenNotApproved(address tokenAddress);
    error DACC__InsufficientFeePaid(uint256 required, uint256 paid);
    error DACC__OnlyWorkCreatorCanClaimRoyalties(address caller, address creator);
    error DACC__NoRoyaltiesToClaim();
    error DACC__OnlyPlatformRecipientCanWithdrawFees(address caller, address recipient);
    error DACC__NoPlatformFeesToWithdraw();
    error DACC__DerivativeWorkMustExist(uint256 workId);
    error DACC__OnlyDerivativeCreatorCanRegister(address caller, uint256 derivativeId, address creator);
    error DACC__CannotRegisterSelfAsDerivative(uint256 workId);
    error DACC__CannotRegisterExistingParent(uint256 derivativeId);
    error DACC__WorkIsAlreadyDerivative(uint256 derivativeId);
    error DACC__OnlyProposer(address caller);
    error DACC__OnlyVoter(address caller);
    error DACC__ProposalDoesNotExist(uint256 proposalId);
    error DACC__VoteAlreadyCast(uint256 proposalId, address voter);
    error DACC__VotingNotActive(uint256 proposalId);
    error DACC__VotingPeriodNotEnded(uint256 proposalId);
    error DACC__ProposalNotApproved(uint256 proposalId);
    error DACC__ExecutionFailed();
    error DACC__InvalidGovernanceActionType(uint256 actionType);
    error DACC__InvalidUpdateFeePercentage(uint256 percentage);
    error DACC__CallerNotWorkCreatorOrGovernance(address caller, address creator);


    // --- State Variables ---

    Counters.Counter private _workIds;
    Counters.Counter private _licenseTypeIds;
    Counters.Counter private _issuedLicenseIds;
    Counters.Counter private _proposalIds;

    struct CreativeWork {
        address creator;
        uint64 creationTimestamp;
        string tokenURI; // Stored directly, or could be an IPFS hash etc.
        // Additional optional fields could be added here
    }

    // Permissions flags for a license type
    struct LicensePermissions {
        bool canRemix;
        bool requiresAttribution;
        bool canUseCommercially;
        bool isTransferable; // Can the issued license itself be transferred?
        // Add more permissions as needed (e.g., canDistribute, canModify, etc.)
    }

    struct LicenseType {
        string name;
        string description;
        LicensePermissions permissions;
        uint256 feeAmount; // Amount required for issuing this license
        address feeToken; // Address of the ERC20 token for the fee (address(0) for ETH/native)
        uint256 duration; // Duration in seconds (0 for perpetual)
        bool isActive; // Can this type be issued? (Governance can deactivate)
        // Additional conditions could be added here, perhaps requiring off-chain verification
    }

    struct IssuedLicense {
        uint256 workId;
        uint256 licenseTypeId;
        address licensee;
        uint64 issueTimestamp;
        uint64 expiryTimestamp; // 0 for perpetual
        bool revoked; // Has this license been revoked by creator/governance?
        string conditions; // Optional string for human-readable conditions/context
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // Enum mapping to specific governable functions
    enum GovernanceActionType {
        DefineLicenseType,
        ApproveFeeToken,
        UpdatePlatformFeeRecipient,
        UpdatePlatformFeePercentage
        // Add more governable actions here
    }

    struct Proposal {
        address proposer;
        uint256 actionType; // Corresponds to GovernanceActionType enum
        bytes data; // Encoded function call data for execution
        uint64 startTimestamp;
        uint64 endTimestamp;
        uint256 supportVotes; // Votes in favor
        uint256 againstVotes; // Votes against
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalState state;
    }

    // --- Mappings ---
    mapping(uint256 => CreativeWork) private idToWork;
    mapping(uint256 => address) private workIdToCreator; // Store creator explicitly

    mapping(uint256 => LicenseType) private licenseTypes; // licenseTypeId => LicenseType
    mapping(uint256 => IssuedLicense) private issuedLicenses; // issuedLicenseId => IssuedLicense

    // Helper mappings to find licenses
    mapping(uint256 => uint256[]) private issuedLicensesByWork; // workId => list of issuedLicenseIds
    mapping(address => uint256[]) private issuedLicensesByLicensee; // licensee => list of issuedLicenseIds

    // Fee/Royalty tracking
    // workId => tokenAddress => accumulated royalties
    mapping(uint256 => mapping(address => uint256)) private workRoyalties;
    // tokenAddress => accumulated platform fees
    mapping(address => uint256) private platformFeeBalances;

    // Derivative tracking
    mapping(uint256 => uint256) private parentWork; // derivativeWorkId => parentWorkId (0 if no parent)
    mapping(uint256 => uint256[]) private derivativeWorks; // parentWorkId => list of derivativeWorkIds

    // Governance
    mapping(uint256 => Proposal) private proposals;
    mapping(address => bool) private governanceProposers; // Addresses allowed to create proposals
    mapping(address => bool) private governanceVoters;   // Addresses allowed to vote (could be token holders in a real DAO)
    uint256 public votingPeriodDuration = 7 days; // Default voting period
    uint256 public proposalThreshold = 1; // Minimum votes required to pass (simple majority in this example)
    uint256 public governanceQuorum = 1; // Minimum total votes required (simple quorum in this example)

    // Approved fee tokens
    mapping(address => bool) private approvedFeeTokens;
    address[] private approvedFeeTokenList; // Keep a list for retrieval

    // Platform fees
    address public platformFeeRecipient;
    uint256 public platformFeePercentage = 5; // 5% (value is percentage * 100), e.g., 500 for 5%

    // --- Events ---
    event WorkMinted(uint256 indexed workId, address indexed creator, string tokenURI);
    event LicenseTypeDefined(uint256 indexed licenseTypeId, string name, uint256 feeAmount, address feeToken, uint256 duration);
    event LicenseIssued(uint256 indexed issuedLicenseId, uint256 indexed workId, uint256 indexed licenseTypeId, address licensee, uint64 expiryTimestamp);
    event LicenseRevoked(uint256 indexed issuedLicenseId, address indexed revoker, string reason);
    event LicenseBurned(uint256 indexed issuedLicenseId, address indexed burner);
    event LicenseTransferred(uint256 indexed issuedLicenseId, address indexed from, address indexed to);
    event RoyaltiesClaimed(uint256 indexed workId, address indexed creator, address indexed token, uint256 amount);
    event PlatformFeesClaimed(address indexed recipient, address indexed token, uint256 amount);
    event DerivativeRegistered(uint256 indexed derivativeWorkId, uint256 indexed parentWorkId, address indexed creator);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 actionType, uint64 startTimestamp, uint64 endTimestamp);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event FeeTokenApproved(address indexed tokenAddress);
    event PlatformFeeRecipientUpdated(address indexed newRecipient);
    event PlatformFeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);


    // --- Constructor ---
    constructor(address initialProposer, address initialVoter) ERC721("Decentralized Creative Commons", "DACC") {
        // Initial setup for governance roles
        governanceProposers[msg.sender] = true; // Deployer is a proposer
        governanceVoters[msg.sender] = true;   // Deployer is a voter
        governanceProposers[initialProposer] = true;
        governanceVoters[initialVoter] = true;

        platformFeeRecipient = msg.sender; // Deployer is initial fee recipient

        // Example: Define a basic non-commercial license type initially
        LicensePermissions memory initialPermissions = LicensePermissions({
            canRemix: false,
            requiresAttribution: true,
            canUseCommercially: false,
            isTransferable: false
        });
        // This initial license type definition is NOT done via governance for contract bootstrap
        _defineLicenseTypeInternal("Non-Commercial Attribution", "Free for non-commercial use with attribution", initialPermissions, 0, address(0), 0); // Perpetual, no fee

        // Example: Define a basic commercial license type initially
        LicensePermissions memory commercialPermissions = LicensePermissions({
            canRemix: true,
            requiresAttribution: true,
            canUseCommercially: true,
            isTransferable: false
        });
         _defineLicenseTypeInternal("Commercial Attribution", "Requires fee for commercial use with attribution, remix allowed", commercialPermissions, 1 ether, address(0), 365 days * 10); // Example: 10 year duration, 1 ETH fee
    }


    // --- Modifiers ---
    modifier onlyGovernanceProposer() {
        if (!governanceProposers[msg.sender]) revert DACC__OnlyProposer(msg.sender);
        _;
    }

    modifier onlyGovernanceVoter() {
        if (!governanceVoters[msg.sender]) revert DACC__OnlyVoter(msg.sender);
        _;
    }

    modifier onlyWorkCreatorOrGovernance(uint256 _workId) {
         if (!idToWork[_workId].creator.isValid()) revert DACC__WorkDoesNotExist(_workId); // Ensure work exists first
         if (msg.sender != idToWork[_workId].creator && !governanceProposers[msg.sender]) { // Simple check: is sender creator OR proposer (as proxy for governance)
            revert DACC__CallerNotWorkCreatorOrGovernance(msg.sender, idToWork[_workId].creator);
        }
        _;
    }

    // --- Helper Functions (Internal/View) ---

    // Checks if a work ID is valid
    function _requireValidWorkId(uint256 _workId) internal view {
        if (!idToWork[_workId].creator.isValid()) { // Check if creator address was set (indicates existence)
             revert DACC__WorkDoesNotExist(_workId);
        }
    }

    // Checks if a license type ID is valid and active
    function _requireValidLicenseType(uint256 _licenseTypeId) internal view {
        if (!licenseTypes[_licenseTypeId].isActive) { // Check isActive flag
            revert DACC__LicenseTypeDoesNotExist(_licenseTypeId);
        }
    }

     // Checks if an issued license ID is valid and not revoked
    function _requireValidIssuedLicense(uint256 _issuedLicenseId) internal view {
        if (issuedLicenses[_issuedLicenseId].workId == 0) { // Check if workId is zero (indicates existence)
             revert DACC__IssuedLicenseDoesNotExist(_issuedLicenseId);
        }
         if (issuedLicenses[_issuedLicenseId].revoked) {
            revert DACC__LicenseRevoked(_issuedLicenseId);
        }
    }

    // Internal function for governance execution
    function executeGovernanceAction(uint256 actionType, bytes memory data) internal {
        // This internal function is called by executeProposal
        // Decode data based on actionType and call the relevant internal function
        if (actionType == uint256(GovernanceActionType.DefineLicenseType)) {
            (string memory name, string memory description, LicensePermissions memory permissions, uint256 feeAmount, address feeToken, uint256 duration) = abi.decode(data, (string, string, LicensePermissions, uint256, address, uint256));
             _defineLicenseTypeInternal(name, description, permissions, feeAmount, feeToken, duration);
        } else if (actionType == uint256(GovernanceActionType.ApproveFeeToken)) {
            (address tokenAddress) = abi.decode(data, (address));
             _approveFeeTokenInternal(tokenAddress);
        } else if (actionType == uint256(GovernanceActionType.UpdatePlatformFeeRecipient)) {
            (address newRecipient) = abi.decode(data, (address));
             _updatePlatformFeeRecipientInternal(newRecipient);
        } else if (actionType == uint256(GovernanceActionType.UpdatePlatformFeePercentage)) {
             (uint256 newPercentage) = abi.decode(data, (uint256));
             _updatePlatformFeePercentageInternal(newPercentage);
        } else {
            revert DACC__InvalidGovernanceActionType(actionType);
        }
    }

    // Internal functions for governance execution targets
    function _defineLicenseTypeInternal(string memory name, string memory description, LicensePermissions memory permissions, uint256 feeAmount, address feeToken, uint256 duration) internal {
         _licenseTypeIds.increment();
        uint256 newLicenseTypeId = _licenseTypeIds.current();
        licenseTypes[newLicenseTypeId] = LicenseType({
            name: name,
            description: description,
            permissions: permissions,
            feeAmount: feeAmount,
            feeToken: feeToken,
            duration: duration,
            isActive: true // Newly defined types are active by default
        });
        emit LicenseTypeDefined(newLicenseTypeId, name, feeAmount, feeToken, duration);
    }

     function _approveFeeTokenInternal(address tokenAddress) internal {
        require(tokenAddress != address(0), "Zero address not allowed");
        if (!approvedFeeTokens[tokenAddress]) {
            approvedFeeTokens[tokenAddress] = true;
            approvedFeeTokenList.push(tokenAddress);
            emit FeeTokenApproved(tokenAddress);
        }
    }

    function _updatePlatformFeeRecipientInternal(address newRecipient) internal {
        require(newRecipient != address(0), "Zero address not allowed");
        platformFeeRecipient = newRecipient;
        emit PlatformFeeRecipientUpdated(newRecipient);
    }

    function _updatePlatformFeePercentageInternal(uint256 newPercentage) internal {
        if (newPercentage > 10000) revert DACC__InvalidUpdateFeePercentage(newPercentage); // 10000 represents 100%
        uint256 oldPercentage = platformFeePercentage;
        platformFeePercentage = newPercentage;
        emit PlatformFeePercentageUpdated(oldPercentage, newPercentage);
    }


    // --- I. ERC721 Standard Functions (Overridden/Implemented) ---
    // ERC721 functions like transferFrom, ownerOf, etc., are provided by the inherited contract.
    // We only override tokenURI to pull from our CreativeWork struct.

    /// @dev See {ERC721-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireValidWorkId(tokenId); // Use our check
        return idToWork[tokenId].tokenURI;
    }


    // --- II. Creative Work & Metadata ---

    /// @notice Mints a new Creative Work NFT. Only designated creators (proposers in this example DAO) can mint.
    /// @param tokenURI_ The URI pointing to the work's metadata.
    /// @return The ID of the newly minted work.
    function mintWork(string calldata tokenURI_) public onlyGovernanceProposer nonReentrant returns (uint256) {
        _workIds.increment();
        uint256 newItemId = _workIds.current();
        address creator = msg.sender; // The minter is the creator in this model

        idToWork[newItemId] = CreativeWork({
            creator: creator,
            creationTimestamp: uint64(block.timestamp),
            tokenURI: tokenURI_
        });
        workIdToCreator[newItemId] = creator; // Store separately for royalty logic

        _safeMint(creator, newItemId); // Mint the NFT to the creator

        emit WorkMinted(newItemId, creator, tokenURI_);
        return newItemId;
    }

    /// @notice Retrieves the details of a specific Creative Work.
    /// @param workId The ID of the work.
    /// @return CreativeWork struct containing the work's details.
    function getWorkDetails(uint256 workId) public view returns (CreativeWork memory) {
        _requireValidWorkId(workId);
        return idToWork[workId];
    }

     /// @notice Gets the original creator of a work.
     /// @param workId The ID of the work.
     /// @return The address of the original creator.
    function getCreator(uint256 workId) public view returns (address) {
        _requireValidWorkId(workId);
        return workIdToCreator[workId];
    }


    /// @notice Gets the total count of minted Creative Works.
    /// @return The total number of works.
    function getWorkCount() public view returns (uint256) {
        return _workIds.current();
    }


    // --- III. License Type Management (Governable) ---
    // Note: The actual definition happens internally via `_defineLicenseTypeInternal`
    // The external function `defineLicenseType` is just a placeholder for governance execution.

    /// @notice Retrieves the details of a standard license type.
    /// @param licenseTypeId The ID of the license type.
    /// @return LicenseType struct containing the license type's details.
    function getLicenseTypeDetails(uint256 licenseTypeId) public view returns (LicenseType memory) {
        _requireValidLicenseType(licenseTypeId); // Checks existence and activity
        return licenseTypes[licenseTypeId];
    }

     /// @notice Gets the total count of defined license types.
    /// @return The total number of license types.
    function getLicenseTypeCount() public view returns (uint256) {
        return _licenseTypeIds.current();
    }

     /// @notice Checks if a token is approved for use in license fees.
     /// @param tokenAddress The address of the token.
     /// @return True if approved, false otherwise.
    function isFeeTokenApproved(address tokenAddress) public view returns (bool) {
        return approvedFeeTokens[tokenAddress];
    }

    /// @notice Lists all approved fee tokens.
    /// @return An array of approved token addresses.
    function getApprovedFeeTokens() public view returns (address[] memory) {
        return approvedFeeTokenList;
    }


    // --- IV. Issued License Management ---

    /// @notice Allows a user to acquire a license for a work.
    /// @param workId The ID of the work.
    /// @param licenseTypeId The ID of the license type.
    /// @param licensee The address acquiring the license.
    function issueLicense(uint256 workId, uint256 licenseTypeId, address licensee) public nonReentrant {
        _requireValidWorkId(workId);
        _requireValidLicenseType(licenseTypeId); // Checks existence and activity
        require(licensee != address(0), "Licensee cannot be the zero address");
        // Optional: Prevent creator from licensing to themselves if desired

        LicenseType storage lType = licenseTypes[licenseTypeId];

        uint256 totalFee = lType.feeAmount;
        address feeToken = lType.feeToken;

        // Handle fee payment
        if (totalFee > 0) {
             uint256 platformFee = totalFee.mul(platformFeePercentage).div(10000); // Percentage is basis points / 100
             uint256 creatorRoyalty = totalFee.sub(platformFee);

            if (feeToken == address(0)) {
                // Native token (ETH) payment
                require(msg.value >= totalFee, "Insufficient native token sent");
                if (platformFee > 0) {
                     (bool successPlatform, ) = payable(platformFeeRecipient).call{value: platformFee}("");
                    require(successPlatform, "Platform ETH transfer failed");
                }
                 if (creatorRoyalty > 0) {
                     (bool successCreator, ) = payable(workIdToCreator[workId]).call{value: creatorRoyalty}("");
                    require(successCreator, "Creator ETH transfer failed");
                }
                 if (msg.value > totalFee) {
                     // Refund excess native token
                    (bool successRefund, ) = payable(msg.sender).call{value: msg.value.sub(totalFee)}("");
                    require(successRefund, "Refund failed");
                }

            } else {
                // ERC20 token payment
                if (!approvedFeeTokens[feeToken]) revert DACC__FeeTokenNotApproved(feeToken);
                // User must approve contract to spend tokens before calling this function
                IERC20 token = IERC20(feeToken);
                require(token.transferFrom(msg.sender, address(this), totalFee), "ERC20 transferFrom failed");

                // Record royalties/fees in contract balance mappings
                if (platformFee > 0) {
                    platformFeeBalances[feeToken] = platformFeeBalances[feeToken].add(platformFee);
                }
                if (creatorRoyalty > 0) {
                    workRoyalties[workId][feeToken] = workRoyalties[workId][feeToken].add(creatorRoyalty);
                }
            }
        } else {
             // If fee is 0, ensure no native token is sent
             require(msg.value == 0, "Native token sent for free license");
        }


        _issuedLicenseIds.increment();
        uint256 newIssuedLicenseId = _issuedLicenseIds.current();
        uint64 issueTime = uint64(block.timestamp);
        uint64 expiryTime = (lType.duration == 0) ? 0 : issueTime + uint64(lType.duration); // 0 duration means perpetual

        issuedLicenses[newIssuedLicenseId] = IssuedLicense({
            workId: workId,
            licenseTypeId: licenseTypeId,
            licensee: licensee,
            issueTimestamp: issueTime,
            expiryTimestamp: expiryTime,
            revoked: false,
            conditions: "" // Optional: could pass conditions here
        });

        issuedLicensesByWork[workId].push(newIssuedLicenseId);
        issuedLicensesByLicensee[licensee].push(newIssuedLicenseId);

        emit LicenseIssued(newIssuedLicenseId, workId, licenseTypeId, licensee, expiryTime);
    }

     /// @notice Checks if a specific issued license exists, is active, and not expired.
     /// @param issuedLicenseId The ID of the issued license.
     /// @return True if the license is currently valid, false otherwise.
    function isLicenseValid(uint256 issuedLicenseId) public view returns (bool) {
        // This helper combines checks for existence, not revoked, and not expired
        if (issuedLicenses[issuedLicenseId].workId == 0 || issuedLicenses[issuedLicenseId].revoked) {
             return false;
        }
        // Check expiry (0 means perpetual)
        uint64 expiry = issuedLicenses[issuedLicenseId].expiryTimestamp;
        if (expiry != 0 && block.timestamp > expiry) {
             return false;
        }
        return true;
    }

     /// @notice Allows the work creator or governance to revoke an issued license.
     /// @param issuedLicenseId The ID of the issued license to revoke.
     /// @param reason An optional reason for the revocation.
    function revokeLicense(uint256 issuedLicenseId, string memory reason) public nonReentrant {
        _requireValidIssuedLicense(issuedLicenseId);
        uint256 workId = issuedLicenses[issuedLicenseId].workId;
        _requireValidWorkId(workId); // Ensure the linked work exists

        // Only the original creator of the work or governance can revoke
        address creator = workIdToCreator[workId];
        if (msg.sender != creator && !governanceProposers[msg.sender]) { // Using proposer status as simple governance check
            revert DACC__CallerNotWorkCreatorOrGovernance(msg.sender, creator);
        }

        issuedLicenses[issuedLicenseId].revoked = true;
        // Note: We don't remove from arrays for gas efficiency; `isLicenseValid` checks `revoked` flag.

        emit LicenseRevoked(issuedLicenseId, msg.sender, reason);
    }

     /// @notice Allows the licensee to burn (invalidate) their own issued license.
     /// @param issuedLicenseId The ID of the issued license to burn.
    function burnIssuedLicense(uint256 issuedLicenseId) public nonReentrant {
        _requireValidIssuedLicense(issuedLicenseId);
        if (msg.sender != issuedLicenses[issuedLicenseId].licensee) {
            revert DACC__NotLicensee(msg.sender, issuedLicenses[issuedLicenseId].licensee);
        }

        issuedLicenses[issuedLicenseId].revoked = true; // Mark as revoked (effectively burned)
        // Note: We don't remove from arrays for gas efficiency.

        emit LicenseBurned(issuedLicenseId, msg.sender);
    }

    /// @notice Allows a licensee to transfer an issued license to another address, if permitted by the license type.
    /// @param issuedLicenseId The ID of the issued license to transfer.
    /// @param newLicensee The address to transfer the license to.
    function transferIssuedLicense(uint256 issuedLicenseId, address newLicensee) public nonReentrant {
         _requireValidIssuedLicense(issuedLicenseId);
         require(newLicensee != address(0), "New licensee cannot be the zero address");

        IssuedLicense storage iLicense = issuedLicenses[issuedLicenseId];
        LicenseType storage lType = licenseTypes[iLicense.licenseTypeId];

        // Check if the license type allows transfer
        if (!lType.permissions.isTransferable) {
            revert DACC__LicenseNotTransferable(iLicense.licenseTypeId);
        }

        // Only the current licensee can initiate the transfer
        if (msg.sender != iLicense.licensee) {
            revert DACC__NotLicensee(msg.sender, iLicense.licensee);
        }

        address oldLicensee = iLicense.licensee;
        iLicense.licensee = newLicensee;

        // Update index arrays (less gas efficient, consider alternatives for large numbers of licenses)
        // For simplicity in this example, we assume arrays are traversable
        // A more efficient approach would use linked lists or skip array removal on transfer/burn/revoke
        uint256[] storage oldLicenseeLicenses = issuedLicensesByLicensee[oldLicensee];
        for (uint i = 0; i < oldLicenseeLicenses.length; i++) {
            if (oldLicenseeLicenses[i] == issuedLicenseId) {
                oldLicenseeLicenses[i] = oldLicenseeLicenses[oldLicenseeLicenses.length - 1];
                oldLicenseeLicenses.pop();
                break; // Assuming unique IDs in the array
            }
        }
         issuedLicensesByLicensee[newLicensee].push(issuedLicenseId);


        emit LicenseTransferred(issuedLicenseId, oldLicensee, newLicensee);
    }


    /// @notice Retrieves the details of a specific issued license.
    /// @param issuedLicenseId The ID of the issued license.
    /// @return IssuedLicense struct containing the license details.
    function getIssuedLicenseDetails(uint256 issuedLicenseId) public view returns (IssuedLicense memory) {
        _requireValidIssuedLicense(issuedLicenseId); // Checks existence and not revoked
        return issuedLicenses[issuedLicenseId];
    }

    /// @notice Gets the total count of issued licenses (including revoked/burned).
    /// @return The total number of issued licenses.
    function getIssuedLicenseCount() public view returns (uint256) {
        return _issuedLicenseIds.current();
    }

    /// @notice Lists all issued license IDs for a specific work.
    /// @param workId The ID of the work.
    /// @return An array of issued license IDs.
    function getIssuedLicensesForWork(uint256 workId) public view returns (uint256[] memory) {
        _requireValidWorkId(workId);
        return issuedLicensesByWork[workId];
    }

    /// @notice Lists all issued license IDs held by a specific address.
    /// @param licensee The address of the licensee.
    /// @return An array of issued license IDs.
    function getIssuedLicensesForUser(address licensee) public view returns (uint256[] memory) {
        require(licensee != address(0), "Licensee address cannot be zero");
        return issuedLicensesByLicensee[licensee];
    }


    // --- V. Royalty & Fee Management ---

    /// @notice Allows the original creator of a work to claim collected license fees.
    /// @param workId The ID of the work.
    /// @param tokenAddress The address of the fee token (address(0) for native ETH).
    function claimRoyalties(uint256 workId, address tokenAddress) public nonReentrant {
        _requireValidWorkId(workId);
        if (msg.sender != workIdToCreator[workId]) {
            revert DACC__OnlyWorkCreatorCanClaimRoyalties(msg.sender, workIdToCreator[workId]);
        }

        uint256 amount = workRoyalties[workId][tokenAddress];
        if (amount == 0) revert DACC__NoRoyaltiesToClaim();

        workRoyalties[workId][tokenAddress] = 0; // Reset balance before transfer

        if (tokenAddress == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(msg.sender, amount), "ERC20 transfer failed");
        }

        emit RoyaltiesClaimed(workId, msg.sender, tokenAddress, amount);
    }

     /// @notice Gets the total collectible royalties for a work in a specific token.
     /// @param workId The ID of the work.
     /// @param tokenAddress The address of the fee token.
     /// @return The total accumulated royalties.
    function getTotalRoyaltiesCollected(uint256 workId, address tokenAddress) public view returns (uint256) {
        _requireValidWorkId(workId);
        return workRoyalties[workId][tokenAddress];
    }

     /// @notice Allows the platform fee recipient to withdraw collected platform fees.
     /// @param tokenAddress The address of the fee token (address(0) for native ETH).
    function withdrawPlatformFees(address tokenAddress) public nonReentrant {
        if (msg.sender != platformFeeRecipient) {
            revert DACC__OnlyPlatformRecipientCanWithdrawFees(msg.sender, platformFeeRecipient);
        }

        uint256 amount = platformFeeBalances[tokenAddress];
        if (amount == 0) revert DACC__NoPlatformFeesToWithdraw();

        platformFeeBalances[tokenAddress] = 0; // Reset balance before transfer

        if (tokenAddress == address(0)) {
             (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "Platform ETH transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(msg.sender, amount), "Platform ERC20 transfer failed");
        }

        emit PlatformFeesClaimed(msg.sender, tokenAddress, amount);
    }

     /// @notice Gets the total collected platform fees in a specific token.
     /// @param tokenAddress The address of the fee token.
     /// @return The total accumulated platform fees.
    function getTotalPlatformFeesCollected(address tokenAddress) public view returns (uint256) {
        return platformFeeBalances[tokenAddress];
    }


    // --- VI. Derivative Work Tracking ---

    /// @notice Allows the creator of a derivative work to register it as derived from a parent work.
    /// @param derivativeWorkId The ID of the new derivative work.
    /// @param parentWorkId The ID of the parent work.
    function registerDerivativeWork(uint256 derivativeWorkId, uint256 parentWorkId) public nonReentrant {
         _requireValidWorkId(derivativeWorkId);
         _requireValidWorkId(parentWorkId);

        // The caller must be the creator of the derivative work
        if (msg.sender != workIdToCreator[derivativeWorkId]) {
            revert DACC__OnlyDerivativeCreatorCanRegister(msg.sender, derivativeWorkId, workIdToCreator[derivativeWorkId]);
        }

        // Cannot register a work as a derivative of itself
        if (derivativeWorkId == parentWorkId) {
            revert DACC__CannotRegisterSelfAsDerivative(derivativeWorkId);
        }

        // Cannot register a work that already has a parent
        if (parentWork[derivativeWorkId] != 0) {
             revert DACC__WorkIsAlreadyDerivative(derivativeWorkId);
        }

        // Cannot register if the parent relationship already exists (shouldn't happen with previous check, but double-check)
        if (parentWork[derivativeWorkId] == parentWorkId) {
            revert DACC__CannotRegisterExistingParent(derivativeWorkId);
        }


        parentWork[derivativeWorkId] = parentWorkId;
        derivativeWorks[parentWorkId].push(derivativeWorkId);

        emit DerivativeRegistered(derivativeWorkId, parentWorkId, msg.sender);
    }

    /// @notice Gets the parent work ID for a given derivative work ID.
    /// @param derivativeWorkId The ID of the derivative work.
    /// @return The parent work ID (0 if no parent).
    function getParentWork(uint256 derivativeWorkId) public view returns (uint256) {
        // No need to _requireValidWorkId here, just return 0 if not found
        return parentWork[derivativeWorkId];
    }

    /// @notice Lists all registered derivative work IDs for a given parent work.
    /// @param parentWorkId The ID of the parent work.
    /// @return An array of derivative work IDs.
    function getDerivativeWorks(uint256 parentWorkId) public view returns (uint256[] memory) {
        _requireValidWorkId(parentWorkId);
        return derivativeWorks[parentWorkId];
    }


    // --- VII. Decentralized Governance ---

    /// @notice Allows designated proposers to create a new governance proposal.
    /// @param actionType The type of action the proposal intends to execute (enum GovernanceActionType).
    /// @param data The encoded data for the target function call.
    /// @return The ID of the newly created proposal.
    function proposeGovernanceAction(uint256 actionType, bytes memory data) public onlyGovernanceProposer returns (uint256) {
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = startTime + uint64(votingPeriodDuration);

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            actionType: actionType,
            data: data,
            startTimestamp: startTime,
            endTimestamp: endTime,
            supportVotes: 0,
            againstVotes: 0,
            hasVoted: new mapping(address => bool), // Initialize nested mapping
            state: ProposalState.Active
        });

        emit ProposalCreated(newProposalId, msg.sender, actionType, startTime, endTime);
        return newProposalId;
    }

     /// @notice Allows designated voters to cast a vote on an active proposal.
     /// @param proposalId The ID of the proposal.
     /// @param support True to vote in favor, false to vote against.
    function voteOnProposal(uint256 proposalId, bool support) public onlyGovernanceVoter nonReentrant {
        if (proposalId == 0 || proposalId > _proposalIds.current()) revert DACC__ProposalDoesNotExist(proposalId);
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state != ProposalState.Active) revert DACC__VotingNotActive(proposalId);
        if (block.timestamp > proposal.endTimestamp) revert DACC__VotingPeriodNotEnded(proposalId);
        if (proposal.hasVoted[msg.sender]) revert DACC__VoteAlreadyCast(proposalId, msg.sender);

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.supportVotes = proposal.supportVotes.add(1);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(1);
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    /// @notice Executes a proposal if the voting period has ended and it has passed.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) public nonReentrant {
        if (proposalId == 0 || proposalId > _proposalIds.current()) revert DACC__ProposalDoesNotExist(proposalId);
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state != ProposalState.Active) {
            if (proposal.state == ProposalState.Executed) revert("Proposal already executed");
            if (proposal.state == ProposalState.Succeeded) revert("Proposal already succeeded, needs execution");
            revert("Proposal not active");
        }

        if (block.timestamp <= proposal.endTimestamp) revert DACC__VotingPeriodNotEnded(proposalId);

        // Check if proposal passed
        uint256 totalVotes = proposal.supportVotes.add(proposal.againstVotes);
        if (totalVotes < governanceQuorum || proposal.supportVotes.mul(100) <= proposal.againstVotes.mul(100)) { // Simple majority check
             proposal.state = ProposalState.Failed;
             revert DACC__ProposalNotApproved(proposalId);
        }

        proposal.state = ProposalState.Succeeded; // Mark as succeeded before execution attempt

        // Execute the proposed action
        // Use internal helper to execute specific governance functions
        executeGovernanceAction(proposal.actionType, proposal.data);


        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    /// @notice Gets the total count of governance proposals.
    /// @return The total number of proposals.
    function getProposalCount() public view returns (uint256) {
        return _proposalIds.current();
    }

     /// @notice Retrieves the details of a specific governance proposal.
     /// @param proposalId The ID of the proposal.
     /// @return Proposal struct containing the proposal details.
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        if (proposalId == 0 || proposalId > _proposalIds.current()) revert DACC__ProposalDoesNotExist(proposalId);
        Proposal storage proposal = proposals[proposalId];
         // Need to return a memory struct to avoid issues with mapping inside struct
        return Proposal({
            proposer: proposal.proposer,
            actionType: proposal.actionType,
            data: proposal.data,
            startTimestamp: proposal.startTimestamp,
            endTimestamp: proposal.endTimestamp,
            supportVotes: proposal.supportVotes,
            againstVotes: proposal.againstVotes,
            hasVoted: new mapping(address => bool), // Cannot return mapping, return empty
            state: proposal.state
        });
    }

    // --- Functions for managing Governance Roles (Example - could be governance controlled themselves) ---
    // For simplicity, let's add basic admin-like functions for managing proposers/voters
    // In a real DAO, these would likely be governance actions themselves

    function addGovernanceProposer(address newProposer) public onlyGovernanceProposer { // Only existing proposers can add
        require(newProposer != address(0), "Zero address not allowed");
        governanceProposers[newProposer] = true;
    }

    function removeGovernanceProposer(address proposerToRemove) public onlyGovernanceProposer {
        require(proposerToRemove != msg.sender, "Cannot remove yourself");
        governanceProposers[proposerToRemove] = false;
    }

    function addGovernanceVoter(address newVoter) public onlyGovernanceProposer { // Proposers manage voters
        require(newVoter != address(0), "Zero address not allowed");
        governanceVoters[newVoter] = true;
    }

    function removeGovernanceVoter(address voterToRemove) public onlyGovernanceProposer {
        governanceVoters[voterToRemove] = false;
    }

     function isGovernanceProposer(address potentialProposer) public view returns (bool) {
        return governanceProposers[potentialProposer];
    }

     function isGovernanceVoter(address potentialVoter) public view returns (bool) {
        return governanceVoters[potentialVoter];
    }
}
```