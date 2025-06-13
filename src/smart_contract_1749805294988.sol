Okay, let's design a smart contract incorporating several advanced, creative, and trendy concepts: Dynamic Soulbound NFTs, On-chain Staking Yields based on NFT attributes, a simple On-chain Governance mechanism tied to NFT ownership, a Fusion/Crafting system, and Oracle-influenced events. We'll call it the "Chronicle Weavers Guild".

The core idea is that users mint unique "Chronicles" (Soulbound NFTs) which have dynamic attributes. These attributes can be modified by "Weaving Events" (interactions), staking, or fusion. The Chronicles earn protocol tokens ("Ink" and "Narrative Fragments") through staking, and can participate in governance.

---

## Contract Outline & Function Summary

**Contract Name:** `ChronicleWeaversGuild`

**Concepts Implemented:**
1.  **Dynamic Soulbound NFTs:** NFTs with mutable attributes, reputation, and a soulbinding mechanic (non-transferable unless specific conditions are met).
2.  **Attribute-Based Staking Yield:** Staking rewards (Ink & Fragments) are influenced by the NFT's current attributes.
3.  **On-Chain Interaction/Weaving Events:** Functions that users call to interact with their NFTs, consuming resources and modifying attributes/reputation based on event type and potentially oracle data.
4.  **NFT Fusion/Crafting:** A mechanism to combine multiple NFTs and/or tokens to produce a new NFT or upgrade an existing one.
5.  **Simple On-Chain Governance:** NFT holders can propose and vote on changes to protocol parameters (e.g., staking rates, interaction costs).
6.  **Oracle Integration (Conceptual):** A designated Oracle can push data that influences the outcome or cost of certain events/interactions.
7.  **Role-Based Access Control:** Using OpenZeppelin's `AccessControl` for managing permissions (Admin, Oracle, etc.).
8.  **Pausable:** Emergency stop mechanism.
9.  **Reentrancy Guard:** Protecting against reentrancy attacks for critical functions.
10. **ERC721 & ERC20 Standards:** Implementing core token standards for compatibility.

**Function Summary (Total: 30+ functions)**

**I. Core NFT & State Management**
1.  `mintChronicle(address recipient)`: Mints a new soulbound Chronicle NFT for the recipient with initial attributes. (User/Protocol)
2.  `getChronicleState(uint256 tokenId)`: View function to retrieve all data for a specific Chronicle NFT. (View)
3.  `isSoulbound(uint256 tokenId)`: Checks if a Chronicle is currently soulbound. (View)
4.  `attemptChronicleTransfer(uint256 tokenId, address to)`: Attempts to transfer a Chronicle. Fails if soulbound and unbinding conditions aren't met. (User)
5.  `initiateSoulUnbinding(uint256 tokenId, uint8 method)`: Starts a specific process (e.g., time lock, burning tokens) to make a Chronicle transferable. (User)
6.  `finalizeSoulUnbinding(uint256 tokenId)`: Completes the unbinding process if conditions are met. (User)
7.  `tokenURI(uint256 tokenId)`: Returns the metadata URI for a Chronicle, potentially reflecting dynamic state. (View, ERC721 Standard)
8.  `setBaseURI(string memory baseURI)`: Admin function to set the base URI for metadata. (Admin)

**II. Interaction & Dynamic State (Weaving)**
9.  `performWeavingEvent(uint256 tokenId, uint8 eventType, bytes calldata eventData)`: Executes a specific Weaving Event on a Chronicle, consuming resources and modifying attributes/reputation. (User)
10. `getWeavingEventCost(uint8 eventType)`: View function for the cost of a specific event type. (View)
11. `simulateWeavingEffect(uint256 tokenId, uint8 eventType, bytes calldata eventData)`: Pure/View function to simulate the potential attribute/reputation change of an event without executing it. (Pure/View)
12. `getAvailableWeavingEvents()`: View function listing configured Weaving Event types. (View)
13. `setWeavingEventParameters(uint8 eventType, uint256 inkCost, uint256 fragmentCost, int16[] attributeChanges, int16 reputationChange, uint8 oracleInfluenceFactor)`: Admin function to configure weaving events. (Admin)

**III. Staking & Yield**
14. `stakeChronicle(uint256 tokenId)`: Stakes a Chronicle NFT, making it eligible for staking rewards. (User)
15. `unstakeChronicle(uint256 tokenId)`: Unstakes a Chronicle NFT. (User)
16. `claimStakingRewards(uint256 tokenId)`: Claims accumulated Ink and Fragment rewards for a staked Chronicle. (User)
17. `getStakingRewardEstimate(uint256 tokenId)`: View function to calculate the estimated pending rewards for a staked Chronicle. (View)
18. `setStakingParameters(uint256 inkRewardPerAttributePointPerSecond, uint256 fragmentRewardPerReputationPointPerSecond, uint256 stakingCooldownDuration)`: Admin function to set staking rates and cooldown. (Admin)

**IV. Fusion & Crafting**
19. `fuseChronicles(uint256[] calldata tokenIds, uint8 fusionType, uint256[] calldata ingredientTokenIds, uint256 inkCost, uint256 fragmentCost)`: Executes a fusion process, potentially burning ingredient NFTs/tokens and creating a new/upgraded NFT. (User)
20. `simulateFusionEffect(uint256[] calldata tokenIds, uint8 fusionType, uint256[] calldata ingredientTokenIds)`: Pure/View function to simulate the outcome of a fusion. (Pure/View)
21. `setFusionParameters(uint8 fusionType, uint256 baseInkCost, uint256 baseFragmentCost, uint256[] calldata requiredIngredients, uint8[] calldata resultAttributes)`: Admin function to configure fusion recipes. (Admin)

**V. Governance**
22. `proposeParameterChange(uint8 parameterId, bytes memory newValue, string memory description)`: Allows a Chronicle holder to propose changing a specific protocol parameter. (User w/ Chronicle)
23. `voteOnProposal(uint256 proposalId, bool support)`: Allows a Chronicle holder to vote on an active proposal. (User w/ Chronicle)
24. `executeProposal(uint256 proposalId)`: Executes a proposal that has met quorum and passed the voting period. (Anyone)
25. `getProposalState(uint256 proposalId)`: View function to get the current state and details of a proposal. (View)
26. `setGovernanceParameters(uint256 votingPeriod, uint256 proposalThreshold, uint256 quorumThreshold)`: Admin function to set governance rules. (Admin)

**VI. Oracle Integration**
27. `updateOracleData(bytes calldata data)`: Function callable *only* by the Oracle role to update relevant external data used by the contract. (Oracle Role)
28. `getOracleInfluence(uint8 eventType, bytes calldata eventData)`: View function showing how current oracle data might influence a specific event type. (View)

**VII. Admin & Utility**
29. `pauseProtocol()`: Pauses sensitive operations. (Admin)
30. `unpauseProtocol()`: Unpauses the protocol. (Admin)
31. `withdrawProtocolFees(address tokenAddress, address recipient)`: Admin function to withdraw accumulated protocol fees. (Admin)
32. `setTokenAddresses(address inkToken, address fragmentToken)`: Admin function to set the addresses of the required ERC20 tokens. (Admin)
33. `grantRole(bytes32 role, address account)`: Standard AccessControl function. (Admin)
34. `revokeRole(bytes32 role, address account)`: Standard AccessControl function. (Admin)
35. `hasRole(bytes32 role, address account)`: Standard AccessControl function. (View)
36. `getRoleAdmin(bytes32 role)`: Standard AccessControl function. (View)
37. `supportsInterface(bytes4 interfaceId)`: Standard ERC165/ERC721/AccessControl function. (View)
38. `ownerOf(uint256 tokenId)`: Standard ERC721 function. (View)
39. `balanceOf(address owner)`: Standard ERC721 function. (View)
40. `getApproved(uint256 tokenId)`: Standard ERC721 function. (View)
41. `isApprovedForAll(address owner, address operator)`: Standard ERC721 function. (View)
42. `approve(address to, uint256 tokenId)`: Standard ERC721 function (overridden to check soulbound). (User)
43. `setApprovalForAll(address operator, bool approved)`: Standard ERC721 function (overridden to check soulbound). (User)

**(Note: Some standard ERC721 functions like `transferFrom` and `safeTransferFrom` are implicitly handled by overriding `_beforeTokenTransfer` which checks soulbinding, or can be explicitly overridden to route through `attemptChronicleTransfer`. We'll override `_beforeTokenTransfer` for a cleaner ERC721 compliance with the soulbound logic.)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ChronicleWeaversGuild
 * @dev A sophisticated protocol for managing dynamic, soulbound NFTs ("Chronicles")
 *      with features including attribute-based staking, interactive "Weaving Events",
 *      NFT fusion, on-chain governance, and conceptual oracle integration.
 */
contract ChronicleWeaversGuild is ERC721, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant WEAVER_ROLE = keccak256("WEAVER_ROLE"); // Role for users who can perform weaving events (can be same as NFT owner)

    // --- Errors ---
    error InvalidTokenId();
    error NotSoulbound();
    error AlreadySoulbound();
    error SoulUnbindingInProgress();
    error NotSoulboundToCaller();
    error SoulUnbindingNotInitiated();
    error SoulUnbindingConditionsNotMet();
    error NotEnoughTokens(address token, uint256 required, uint256 current);
    error NotEnoughFragments(uint256 required, uint256 current);
    error NotEnoughInk(uint256 required, uint256 current);
    error InvalidWeavingEvent();
    error ChronicleNotStaked();
    error ChronicleAlreadyStaked();
    error StakingCooldownActive();
    error NoRewardsClaimable();
    error InvalidFusionType();
    error FusionIngredientMismatch();
    error FusionConditionsNotMet();
    error InvalidProposalId();
    error ProposalNotActive();
    error ProposalNotExecutable();
    error AlreadyVoted();
    error CallerNotChronicleOwner();
    error OracleDataMismatch();
    error SoulbindingPreventedTransfer();

    // --- Enums & Constants ---
    enum SoulUnbindingMethod { NONE, TIMELOCK, TOKEN_BURN, GOVERNANCE_VOTE }
    enum ProposalState { PENDING, ACTIVE, SUCCEEDED, DEFEATED, EXECUTED, CANCELED }
    enum ProposalParameter { STAKING_INK_RATE, STAKING_FRAGMENT_RATE, STAKING_COOLDOWN, GOV_VOTING_PERIOD, GOV_QUORUM, GOV_PROPOSAL_THRESHOLD, WEAVING_INK_COST, WEAVING_FRAGMENT_COST } // Add more as needed

    uint8 public constant ATTRIBUTE_CREATIVITY = 0;
    uint8 public constant ATTRIBUTE_INSIGHT = 1;
    uint8 public constant ATTRIBUTE_RESILIENCE = 2;
    // Add more attributes as needed

    // --- Structs ---
    struct Chronicle {
        address owner; // Current owner (can change if not soulbound)
        address soulboundTo; // The address this Chronicle is bound to (permanent reference)
        uint64 mintTimestamp;
        int16[3] attributes; // e.g., [creativity, insight, resilience]
        int32 reputationScore;
        bool isStaked;
        uint64 lastStakedTimestamp; // Timestamp when staking started/last claimed
        bool isSoulbound;
        SoulUnbindingMethod unbindingMethod;
        uint64 unbindingInitiatedTimestamp; // For TIMELOCK
        uint256 unbindingTokenBurnAmount; // For TOKEN_BURN
    }

    struct Proposal {
        uint256 id;
        uint8 parameterId; // Which parameter to change
        bytes newValue;      // The new value (encoded)
        string description;
        uint64 voteStartTimestamp;
        uint64 voteEndTimestamp;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Requires voter to own a Chronicle at time of vote
        ProposalState state;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    uint256 private _proposalIdCounter;

    mapping(uint256 => Chronicle) private _chronicles;
    mapping(address => uint256) private _soulboundTokenId; // Optional: quick lookup for the 1 soulbound token per address

    // Token Addresses
    IERC20 public inkToken;
    IERC20 public narrativeFragmentToken;

    // Protocol Fees
    mapping(address => uint256) public protocolFees;

    // Parameters (Governable)
    uint256 public inkRewardPerAttributePointPerSecond = 1e14; // Example: 0.0001 Ink per point per second (adjust decimals)
    uint256 public fragmentRewardPerReputationPointPerSecond = 1e14; // Example: 0.0001 Fragments per point per second
    uint256 public stakingCooldownDuration = 1 days; // Time after unstaking before can stake again (example)

    // Weaving Event Parameters: eventType => {inkCost, fragmentCost, attributeChanges, reputationChange, oracleInfluenceFactor}
    mapping(uint8 => uint256) public weavingEventInkCost;
    mapping(uint8 => uint256) public weavingEventFragmentCost;
    // Note: Attribute/Reputation changes and Oracle influence for weaving events
    // are too complex for simple mappings. They will be hardcoded or handled
    // within the `_processWeavingEffect` internal function for different event types.
    // Governance proposals can still change *costs* via parameterId.

    // Fusion Parameters: fusionType => {baseInkCost, baseFragmentCost, requiredIngredients[], resultAttributes[]}
    // Similar to weaving, actual logic is complex and handled internally.
    // Governance proposals can change *costs* via parameterId.

    // Governance Parameters
    uint256 public votingPeriod = 3 days;
    uint256 public proposalThreshold = 1; // Minimum number of Chronicles voter must own to propose
    uint256 public quorumThreshold = 5; // Minimum number of votes required for a proposal to pass (example, could be percentage of total tokens)
    mapping(uint256 => Proposal) public proposals;

    // Oracle
    address public oracleAddress; // Address allowed to call updateOracleData
    bytes public currentOracleData; // Data pushed by the oracle

    // --- Events ---
    event ChronicleMinted(uint256 indexed tokenId, address indexed owner, address indexed soulboundTo, int16[3] attributes);
    event ChronicleAttributesUpdated(uint256 indexed tokenId, int16[3] newAttributes);
    event ChronicleReputationUpdated(uint256 indexed tokenId, int32 newReputation);
    event WeavingEventPerformed(uint256 indexed tokenId, uint8 eventType, address indexed weaver, uint256 inkSpent, uint256 fragmentsSpent);
    event ChronicleStaked(uint256 indexed tokenId, address indexed owner);
    event ChronicleUnstaked(uint256 indexed tokenId, address indexed owner);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 inkAmount, uint256 fragmentAmount);
    event ChronicleFusion(uint8 indexed fusionType, uint256[] indexed ingredientTokenIds, uint256 resultTokenId, address indexed owner);
    event SoulUnbindingInitiated(uint256 indexed tokenId, address indexed owner, SoulUnbindingMethod method, uint64 timestamp);
    event SoulUnbindingFinalized(uint256 indexed tokenId, address indexed owner, SoulUnbindingMethod method);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint8 parameterId, bytes newValue, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 totalVotesFor, uint256 totalVotesAgainst);
    event ProposalExecuted(uint256 indexed proposalId);
    event OracleDataUpdated(bytes data);

    // --- Constructor ---
    constructor(
        address defaultAdmin,
        address _inkToken,
        address _fragmentToken
    ) ERC721("ChronicleWeaversGuild", "CWG") {
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _setupRole(ORACLE_ROLE, defaultAdmin); // Admin is initially Oracle
        _setupRole(WEAVER_ROLE, defaultAdmin); // Admin is initially Weaver

        require(_inkToken != address(0), "Invalid Ink Token Address");
        require(_fragmentToken != address(0), "Invalid Fragment Token Address");
        inkToken = IERC20(_inkToken);
        narrativeFragmentToken = IERC20(_fragmentToken);

        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(WEAVER_ROLE, DEFAULT_ADMIN_ROLE);

        // Initial weaving event parameters (example)
        weavingEventInkCost[1] = 1e18; // Event 1 costs 1 Ink
        weavingEventFragmentCost[1] = 0;
        weavingEventInkCost[2] = 0;
        weavingEventFragmentCost[2] = 100e18; // Event 2 costs 100 Fragments

        // Initial fusion parameters (example)
        // Fusion logic (required ingredients, results) defined in _processFusion

        // Initial governance parameters set above as state variables
    }

    // --- Access Control & Pausable ---
    function pauseProtocol() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseProtocol() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function withdrawProtocolFees(address tokenAddress, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant whenNotPaused {
        uint256 amount = protocolFees[tokenAddress];
        if (amount > 0) {
            protocolFees[tokenAddress] = 0;
            IERC20(tokenAddress).safeTransfer(recipient, amount);
        }
    }

    // --- ERC721 & Soulbound Overrides ---
    // Ensure transfers are restricted when soulbound
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (_exists(tokenId) && _chronicles[tokenId].isSoulbound && from != address(0)) {
             if (_chronicles[tokenId].unbindingMethod == SoulUnbindingMethod.NONE) {
                 // Standard transfer is blocked if soulbound and no unbinding is initiated
                 revert SoulbindingPreventedTransfer();
             }
             // Transfers are allowed *only* during the brief window between finalizeSoulUnbinding and a potential re-binding
             // Or specifically via the `attemptChronicleTransfer` which routes here but has checks.
             // For simplicity, we'll ensure only `attemptChronicleTransfer` can succeed if unbinding is initiated.
             // If `to == address(0)`, it's a burn, which might be allowed depending on the protocol design.
             // Let's assume burning a soulbound token is generally not intended unless part of fusion/unbinding.
             if (to != address(0) && tx.origin != address(this)) {
                 // Prevent transfers initiated outside this contract if soulbinding is active
                 revert SoulbindingPreventedTransfer();
             }
        }
    }

    // Override standard transfer functions to route through `attemptChronicleTransfer` or add checks
    // This is a simplification; true ERC721 compliance with soulbinding is tricky.
    // A common pattern is to make the NFT non-transferable initially and change a flag.
    // Our `isSoulbound` flag and `_beforeTokenTransfer` hook handle this.
    // Explicitly allowing `approve` and `setApprovalForAll` but they are useless for a soulbound token.
    function approve(address to, uint256 tokenId) public override {
         // Allow setting approvals, but they won't work while soulbound.
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        // Allow setting operator approvals, but they won't work while soulbound.
        require(msg.sender == ERC721.ownerOf(ERC721.tokenByIndex(0)), "ERC721: approve caller is not owner"); // Example check, should be any owner
        _setApprovalForAll(msg.sender, operator, approved);
    }

    // Custom transfer logic handling soulbinding
    function attemptChronicleTransfer(uint256 tokenId, address to) public whenNotPaused {
        address currentOwner = ownerOf(tokenId);
        require(msg.sender == currentOwner, CallerNotChronicleOwner());

        if (_chronicles[tokenId].isSoulbound) {
             // Only allow transfer if unbinding was initiated AND conditions met
            if (_chronicles[tokenId].unbindingMethod == SoulUnbindingMethod.NONE) {
                 revert SoulbindingPreventedTransfer();
            }
            _checkUnbindingConditions(tokenId); // Will revert if conditions not met
             // Temporarily mark as not soulbound *just* for the transfer hook
            _chronicles[tokenId].isSoulbound = false;
            _transfer(msg.sender, to, tokenId);
             // Re-bind to the new owner? Or leave unbound? Let's leave unbound until explicitly bound.
            _chronicles[tokenId].soulboundTo = address(0); // No longer bound
        } else {
             // Standard transfer if not soulbound
            _transfer(msg.sender, to, tokenId);
        }
    }

    // ERC721 Standard Implementation details
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IAccessControl).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Implement logic to generate dynamic URI based on _chronicles[tokenId].attributes etc.
        // For this example, returning a placeholder.
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId))) : "";
    }

    function setBaseURI(string memory baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(baseURI);
    }


    // --- Core Logic: Minting ---
    function mintChronicle(address recipient) public onlyRole(WEAVER_ROLE) whenNotPaused {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        require(recipient != address(0), "ERC721: mint to the zero address");
        // Optional: Check if recipient already has a soulbound token
        // require(_soulboundTokenId[recipient] == 0, "Recipient already has a soulbound token");

        int16[3] memory initialAttributes = [int16(10), int16(10), int16(10)]; // Example initial attributes
        int32 initialReputation = 0;

        _chronicles[newTokenId] = Chronicle({
            owner: recipient,
            soulboundTo: recipient,
            mintTimestamp: uint64(block.timestamp),
            attributes: initialAttributes,
            reputationScore: initialReputation,
            isStaked: false,
            lastStakedTimestamp: 0,
            isSoulbound: true, // Minted soulbound by default
            unbindingMethod: SoulUnbindingMethod.NONE,
            unbindingInitiatedTimestamp: 0,
            unbindingTokenBurnAmount: 0
        });

        _safeMint(recipient, newTokenId); // Mints via ERC721, calls _beforeTokenTransfer hook
        // _soulboundTokenId[recipient] = newTokenId; // Update soulbound mapping

        emit ChronicleMinted(newTokenId, recipient, recipient, initialAttributes);
    }

    // --- Core Logic: Soulbound Management ---
    function isSoulbound(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), InvalidTokenId());
        return _chronicles[tokenId].isSoulbound;
    }

    function initiateSoulUnbinding(uint256 tokenId, uint8 method) public whenNotPaused nonReentrant {
        address currentOwner = ownerOf(tokenId);
        require(msg.sender == currentOwner, CallerNotChronicleOwner());
        require(_chronicles[tokenId].isSoulbound, NotSoulbound());
        require(_chronicles[tokenId].unbindingMethod == SoulUnbindingMethod.NONE, SoulUnbindingInProgress());
        require(method != uint8(SoulUnbindingMethod.NONE), "Invalid unbinding method");

        SoulUnbindingMethod unbindingMethod = SoulUnbindingMethod(method);
        _chronicles[tokenId].unbindingMethod = unbindingMethod;
        _chronicles[tokenId].unbindingInitiatedTimestamp = uint64(block.timestamp);

        if (unbindingMethod == SoulUnbindingMethod.TOKEN_BURN) {
            // Example: Requires burning tokens
            uint256 burnAmount = 1000e18; // Example burn cost
            _chronicles[tokenId].unbindingTokenBurnAmount = burnAmount;
            require(narrativeFragmentToken.balanceOf(msg.sender) >= burnAmount, NotEnoughFragments(burnAmount, narrativeFragmentToken.balanceOf(msg.sender)));
            narrativeFragmentToken.safeTransferFrom(msg.sender, address(this), burnAmount);
            protocolFees[address(narrativeFragmentToken)] += burnAmount;
        } else if (unbindingMethod == SoulUnbindingMethod.GOVERNANCE_VOTE) {
             // Example: Requires a governance proposal to pass (more complex, outline the flow)
             // In a real implementation, initiating this method could create a special proposal type.
             // For simplicity here, it's just a method placeholder. The check in finalize would be complex.
             revert("Governance vote unbinding not fully implemented");
        }

        emit SoulUnbindingInitiated(tokenId, msg.sender, unbindingMethod, block.timestamp);
    }

    function finalizeSoulUnbinding(uint256 tokenId) public whenNotPaused nonReentrant {
        address currentOwner = ownerOf(tokenId);
        require(msg.sender == currentOwner, CallerNotChronicleOwner());
        require(_chronicles[tokenId].isSoulbound, NotSoulbound()); // Must still be soulbound
        require(_chronicles[tokenId].unbindingMethod != SoulUnbindingMethod.NONE, SoulUnbindingNotInitiated());

        _checkUnbindingConditions(tokenId); // Checks if conditions for the chosen method are met

        _chronicles[tokenId].isSoulbound = false; // Make it transferable
        _chronicles[tokenId].unbindingMethod = SoulUnbindingMethod.NONE; // Reset state
        _chronicles[tokenId].unbindingInitiatedTimestamp = 0;
        _chronicles[tokenId].unbindingTokenBurnAmount = 0;
        // _soulboundTokenId[currentOwner] = 0; // Clear soulbound mapping if used

        emit SoulUnbindingFinalized(tokenId, msg.sender, _chronicles[tokenId].unbindingMethod);
    }

    function _checkUnbindingConditions(uint256 tokenId) internal view {
        Chronicle storage chronicle = _chronicles[tokenId];
        if (chronicle.unbindingMethod == SoulUnbindingMethod.TIMELOCK) {
            uint256 timelockDuration = 7 days; // Example: 7 days required
            require(block.timestamp >= chronicle.unbindingInitiatedTimestamp + timelockDuration, "Timelock not expired");
        } else if (chronicle.unbindingMethod == SoulUnbindingMethod.TOKEN_BURN) {
             // Tokens are burned on initiate, so this condition is already met if initiate succeeded.
             // Add any other checks here if needed.
        } else if (chronicle.unbindingMethod == SoulUnbindingMethod.GOVERNANCE_VOTE) {
            // Example: Requires a specific governance proposal related to this tokenId to have SUCCEEDED
            // This requires a more complex mapping/tracking of governance proposals by tokenId.
            revert("Governance vote unbinding check not implemented");
        } else {
            revert("Unknown unbinding method");
        }
    }

    // --- Interaction: Weaving Events ---
    function performWeavingEvent(uint256 tokenId, uint8 eventType, bytes calldata eventData) external nonReentrant whenNotPaused onlyRole(WEAVER_ROLE) {
        address currentOwner = ownerOf(tokenId);
        require(msg.sender == currentOwner, CallerNotChronicleOwner());
        require(_exists(tokenId), InvalidTokenId());
        require(weavingEventInkCost[eventType] > 0 || weavingEventFragmentCost[eventType] > 0, InvalidWeavingEvent()); // Must be a configured event

        uint256 inkCost = weavingEventInkCost[eventType];
        uint256 fragmentCost = weavingEventFragmentCost[eventType];

        if (inkCost > 0) {
            require(inkToken.balanceOf(msg.sender) >= inkCost, NotEnoughInk(inkCost, inkToken.balanceOf(msg.sender)));
            inkToken.safeTransferFrom(msg.sender, address(this), inkCost);
            protocolFees[address(inkToken)] += inkCost;
        }
        if (fragmentCost > 0) {
            require(narrativeFragmentToken.balanceOf(msg.sender) >= fragmentCost, NotEnoughFragments(fragmentCost, narrativeFragmentToken.balanceOf(msg.sender)));
            narrativeFragmentToken.safeTransferFrom(msg.sender, address(this), fragmentCost);
            protocolFees[address(narrativeFragmentToken)] += fragmentCost;
        }

        _processWeavingEffect(tokenId, eventType, eventData); // Apply attribute/reputation changes

        emit WeavingEventPerformed(tokenId, eventType, msg.sender, inkCost, fragmentCost);
    }

    function _processWeavingEffect(uint256 tokenId, uint8 eventType, bytes calldata eventData) internal {
        Chronicle storage chronicle = _chronicles[tokenId];

        // Example Logic:
        // Event 1: Boost Creativity, cost Ink
        if (eventType == 1) {
            chronicle.attributes[ATTRIBUTE_CREATIVITY] = Math.max(0, chronicle.attributes[ATTRIBUTE_CREATIVITY] + 5); // Example: +5 Creativity
            chronicle.reputationScore += 1; // Example: +1 Rep
        }
        // Event 2: Boost Resilience, cost Fragments, influenced by Oracle data
        else if (eventType == 2) {
            int16 resilienceChange = 3; // Base change
            // Incorporate oracle influence (example: oracle data is a byte indicating a multiplier)
            if (currentOracleData.length > 0) {
                uint8 oracleMultiplier = uint8(currentOracleData[0]);
                resilienceChange = int16(resilienceChange * oracleMultiplier / 10); // Example: Oracle multiplier / 10
            }
            chronicle.attributes[ATTRIBUTE_RESILIENCE] = Math.max(0, chronicle.attributes[ATTRIBUTE_RESILIENCE] + resilienceChange);
            chronicle.reputationScore += 2; // Example: +2 Rep
        }
        // Add more event types and their effects
        // Example: Event 3 could decrease an attribute for another increase, based on eventData

        emit ChronicleAttributesUpdated(tokenId, chronicle.attributes);
        emit ChronicleReputationUpdated(tokenId, chronicle.reputationScore);
    }

    function getWeavingEventCost(uint8 eventType) public view returns (uint256 inkCost, uint256 fragmentCost) {
        return (weavingEventInkCost[eventType], weavingEventFragmentCost[eventType]);
    }

    function simulateWeavingEffect(uint256 tokenId, uint8 eventType, bytes calldata eventData) public view returns (int16[3] memory potentialAttributes, int32 potentialReputation) {
        require(_exists(tokenId), InvalidTokenId());
        // This is a simplified simulation. A real simulation might involve a lot of re-implemented logic.
        // Here, we just return the *current* state + a hypothetical change based on a simple rule.
        Chronicle storage chronicle = _chronicles[tokenId];
        potentialAttributes = chronicle.attributes;
        potentialReputation = chronicle.reputationScore;

        // Example Simulation Logic (must match _processWeavingEffect rules)
        if (eventType == 1) {
            potentialAttributes[ATTRIBUTE_CREATIVITY] = Math.max(0, potentialAttributes[ATTRIBUTE_CREATIVITY] + 5);
            potentialReputation += 1;
        } else if (eventType == 2) {
            int16 resilienceChange = 3;
            if (currentOracleData.length > 0) {
                 uint8 oracleMultiplier = uint8(currentOracleData[0]);
                 resilienceChange = int16(resilienceChange * oracleMultiplier / 10);
            }
            potentialAttributes[ATTRIBUTE_RESILIENCE] = Math.max(0, potentialAttributes[ATTRIBUTE_RESILIENCE] + resilienceChange);
            potentialReputation += 2;
        }
        // ... add simulation for other event types ...
    }

    function getAvailableWeavingEvents() public pure returns (uint8[] memory) {
         // In a real contract, this might read from a dynamic list or mapping.
         // For this example, hardcode known types.
        uint8[] memory eventTypes = new uint8[](2);
        eventTypes[0] = 1;
        eventTypes[1] = 2;
        return eventTypes;
    }


    // --- Staking ---
    function stakeChronicle(uint256 tokenId) public whenNotPaused nonReentrant {
        address currentOwner = ownerOf(tokenId);
        require(msg.sender == currentOwner, CallerNotChronicleOwner());
        require(_exists(tokenId), InvalidTokenId());
        require(!_chronicles[tokenId].isStaked, ChronicleAlreadyStaked());
        require(block.timestamp >= _chronicles[tokenId].lastStakedTimestamp + stakingCooldownDuration, StakingCooldownActive());

        // Claim pending rewards before staking again if any (edge case after unstaking)
        _claimStakingRewards(tokenId, msg.sender);

        _chronicles[tokenId].isStaked = true;
        _chronicles[tokenId].lastStakedTimestamp = uint64(block.timestamp);

        emit ChronicleStaked(tokenId, msg.sender);
    }

    function unstakeChronicle(uint256 tokenId) public whenNotPaused nonReentrant {
        address currentOwner = ownerOf(tokenId);
        require(msg.sender == currentOwner, CallerNotChronicleOwner());
        require(_exists(tokenId), InvalidTokenId());
        require(_chronicles[tokenId].isStaked, ChronicleNotStaked());

        _claimStakingRewards(tokenId, msg.sender); // Claim rewards upon unstaking

        _chronicles[tokenId].isStaked = false;
        // lastStakedTimestamp remains the last time rewards were claimed/staking started,
        // used for cooldown calculation.

        emit ChronicleUnstaked(tokenId, msg.sender);
    }

    function claimStakingRewards(uint256 tokenId) public whenNotPaused nonReentrant {
        address currentOwner = ownerOf(tokenId);
        require(msg.sender == currentOwner, CallerNotChronicleOwner());
        require(_exists(tokenId), InvalidTokenId());
        require(_chronicles[tokenId].isStaked, ChronicleNotStaked());

        _claimStakingRewards(tokenId, msg.sender);
    }

    function _claimStakingRewards(uint256 tokenId, address recipient) internal {
        uint256 timeStaked = block.timestamp - _chronicles[tokenId].lastStakedTimestamp;
        if (timeStaked == 0) {
             // No time elapsed since last claim/stake
             return;
        }

        int16[3] memory attributes = _chronicles[tokenId].attributes;
        int32 reputation = _chronicles[tokenId].reputationScore;

        // Calculate reward based on time and attributes/reputation
        uint256 inkReward = (uint256(attributes[ATTRIBUTE_CREATIVITY]) + uint256(attributes[ATTRIBUTE_INSIGHT]) + uint256(attributes[ATTRIBUTE_RESILIENCE]))
                            .mul(inkRewardPerAttributePointPerSecond).mul(timeStaked);
        uint256 fragmentReward = uint256(Math.max(0, reputation)) // Only positive reputation gives fragments
                                .mul(fragmentRewardPerReputationPointPerSecond).mul(timeStaked);

        if (inkReward == 0 && fragmentReward == 0) {
             revert NoRewardsClaimable();
        }

        _chronicles[tokenId].lastStakedTimestamp = uint64(block.timestamp); // Reset timer

        if (inkReward > 0) {
            inkToken.safeTransfer(recipient, inkReward);
        }
        if (fragmentReward > 0) {
            narrativeFragmentToken.safeTransfer(recipient, fragmentReward);
        }

        emit StakingRewardsClaimed(tokenId, recipient, inkReward, fragmentReward);
    }

    function getStakingRewardEstimate(uint256 tokenId) public view returns (uint256 inkEstimate, uint256 fragmentEstimate) {
        require(_exists(tokenId), InvalidTokenId());
        require(_chronicles[tokenId].isStaked, ChronicleNotStaked());

        uint256 timeElapsed = block.timestamp - _chronicles[tokenId].lastStakedTimestamp;
        int16[3] memory attributes = _chronicles[tokenId].attributes;
        int32 reputation = _chronicles[tokenId].reputationScore;

        inkEstimate = (uint256(attributes[ATTRIBUTE_CREATIVITY]) + uint256(attributes[ATTRIBUTE_INSIGHT]) + uint256(attributes[ATTRIBUTE_RESILIENCE]))
                      .mul(inkRewardPerAttributePointPerSecond).mul(timeElapsed);
        fragmentEstimate = uint256(Math.max(0, reputation))
                           .mul(fragmentRewardPerReputationPointPerSecond).mul(timeElapsed);
    }

    // --- Fusion ---
    function fuseChronicles(uint256[] calldata tokenIds, uint8 fusionType, uint256[] calldata ingredientTokenIds, uint256 inkCost, uint256 fragmentCost) external nonReentrant whenNotPaused {
        // Requires approval for ingredient tokens/NFTs if they are not msg.sender's or need burning
        // This is a complex function. Outline assumes msg.sender owns all input NFTs and approves token costs.
        address currentOwner = msg.sender; // Assume owner initiates fusion

        // Validate input tokenIds (must own and exist)
        for (uint i = 0; i < tokenIds.length; i++) {
             require(ownerOf(tokenIds[i]) == currentOwner, "Must own all base Chronicles");
             require(!_chronicles[tokenIds[i]].isStaked, "Cannot fuse staked Chronicles"); // Cannot fuse staked NFTs
        }
        // Validate ingredientTokenIds (must own if NFTs)
        for (uint i = 0; i < ingredientTokenIds.length; i++) {
             // Assuming ingredientTokenIds could also be CWG tokens
             require(_exists(ingredientTokenIds[i]), "Ingredient token does not exist");
             require(ownerOf(ingredientTokenIds[i]) == currentOwner, "Must own all ingredient Chronicles");
             require(!_chronicles[ingredientTokenIds[i]].isStaked, "Cannot fuse staked ingredient Chronicles"); // Cannot fuse staked NFTs
        }

        // Pay token costs
        if (inkCost > 0) {
            require(inkToken.balanceOf(msg.sender) >= inkCost, NotEnoughInk(inkCost, inkToken.balanceOf(msg.sender)));
            inkToken.safeTransferFrom(msg.sender, address(this), inkCost);
            protocolFees[address(inkToken)] += inkCost;
        }
        if (fragmentCost > 0) {
            require(narrativeFragmentToken.balanceOf(msg.sender) >= fragmentCost, NotEnoughFragments(fragmentCost, narrativeFragmentToken.balanceOf(msg.sender)));
            narrativeFragmentToken.safeTransferFrom(msg.sender, address(this), fragmentCost);
            protocolFees[address(narrativeFragmentToken)] += fragmentCost;
        }

        // Burn ingredient NFTs
        for (uint i = 0; i < ingredientTokenIds.length; i++) {
             _burn(ingredientTokenIds[i]); // ERC721 burn
        }
        // Decide effect based on fusionType - this is where the core logic lives
        _processFusion(tokenIds, fusionType);

        emit ChronicleFusion(fusionType, ingredientTokenIds, tokenIds.length > 0 ? tokenIds[0] : 0, currentOwner); // Example: event refers to first token as result
    }

    function _processFusion(uint256[] calldata baseTokenIds, uint8 fusionType) internal {
        // This is highly complex and depends entirely on fusion recipes.
        // Example: FusionType 1 - combine 3 base Chronicles into 1 new powerful one, burning the 3.
        if (fusionType == 1) {
             require(baseTokenIds.length == 3, FusionIngredientMismatch());
             // Burn the base tokens
             for (uint i = 0; i < baseTokenIds.length; i++) {
                 _burn(baseTokenIds[i]);
             }
             // Mint a new, stronger token
             _tokenIdCounter.increment();
             uint256 newChronicleId = _tokenIdCounter.current();
             address owner = msg.sender; // Assuming owner is the caller

             int16[3] memory combinedAttributes = [int16(0), int16(0), int16(0)];
             int32 combinedReputation = 0;
             // Example: Sum attributes and reputation (with scaling/decay)
             for (uint i = 0; i < baseTokenIds.length; i++) {
                 Chronicle storage oldChronicle = _chronicles[baseTokenIds[i]]; // Accessing struct is fine even after burn
                 combinedAttributes[ATTRIBUTE_CREATIVITY] += oldChronicle.attributes[ATTRIBUTE_CREATIVITY];
                 combinedAttributes[ATTRIBUTE_INSIGHT] += oldChronicle.attributes[ATTRIBUTE_INSIGHT];
                 combinedAttributes[ATTRIBUTE_RESILIENCE] += oldChronicle.attributes[ATTRIBUTE_RESILIENCE];
                 combinedReputation += oldChronicle.reputationScore;
             }
             // Apply fusion bonus/decay
             combinedAttributes[ATTRIBUTE_CREATIVITY] = Math.max(0, int16(combinedAttributes[ATTRIBUTE_CREATIVITY] * 8 / 10 + 50)); // 80% + 50 base
             combinedAttributes[ATTRIBUTE_INSIGHT] = Math.max(0, int16(combinedAttributes[ATTRIBUTE_INSIGHT] * 8 / 10 + 50));
             combinedAttributes[ATTRIBUTE_RESILIENCE] = Math.max(0, int16(combinedAttributes[ATTRIBUTE_RESILIENCE] * 8 / 10 + 50));
             combinedReputation = combinedReputation * 9 / 10; // 90% reputation carries over

             _chronicles[newChronicleId] = Chronicle({
                 owner: owner,
                 soulboundTo: owner, // New one is soulbound by default
                 mintTimestamp: uint64(block.timestamp),
                 attributes: combinedAttributes,
                 reputationScore: combinedReputation,
                 isStaked: false,
                 lastStakedTimestamp: 0,
                 isSoulbound: true,
                 unbindingMethod: SoulUnbindingMethod.NONE,
                 unbindingInitiatedTimestamp: 0,
                 unbindingTokenBurnAmount: 0
             });
             _safeMint(owner, newChronicleId);
             // _soulboundTokenId[owner] = newChronicleId;
             emit ChronicleMinted(newChronicleId, owner, owner, combinedAttributes); // Use minted event for clarity

        }
        // Example: FusionType 2 - Upgrade a single Chronicle using Fragments and another ingredient NFT.
        // This type would not burn the baseTokenId[0].
        else if (fusionType == 2) {
            require(baseTokenIds.length == 1, FusionIngredientMismatch());
            require(ingredientTokenIds.length > 0, FusionIngredientMismatch()); // Requires at least one ingredient
            uint256 baseTokenId = baseTokenIds[0];
            Chronicle storage chronicle = _chronicles[baseTokenId];

            // Apply upgrade effect based on ingredients/fusion type
            // ... complex logic here ...
            chronicle.attributes[ATTRIBUTE_CREATIVITY] = Math.max(0, chronicle.attributes[ATTRIBUTE_CREATIVITY] + 10);
            chronicle.reputationScore += 5;

            emit ChronicleAttributesUpdated(baseTokenId, chronicle.attributes);
            emit ChronicleReputationUpdated(baseTokenId, chronicle.reputationScore);
        }
        else {
            revert InvalidFusionType();
        }
    }

    function simulateFusionEffect(uint256[] calldata tokenIds, uint8 fusionType, uint256[] calldata ingredientTokenIds) public view returns (int16[3] memory potentialAttributes, int32 potentialReputation) {
         // Similar to weaving simulation, this is complex and would re-implement logic.
         // Return placeholder or simplified simulation.
        if (fusionType == 1) {
            // Simulate combining 3 into 1
            require(tokenIds.length == 3, FusionIngredientMismatch());
            int16[3] memory combinedAttributes = [int16(0), int16(0), int16(0)];
            int32 combinedReputation = 0;
            // Example: Sum attributes and reputation (with scaling/decay) - same logic as _processFusion simulation
             for (uint i = 0; i < tokenIds.length; i++) {
                 // Cannot access storage of burned tokens in simulation directly, need to pass their state or get current state
                 // For a view function, you can only access *current* state of non-burned tokens.
                 // This makes simulating FusionType 1 where tokens are BURNED difficult in a pure/view function.
                 // A realistic simulation would need to take *state* of tokens as input parameters.
                 // Let's simulate FusionType 2 instead as it modifies an existing token.
                 revert("Simulation of FusionType 1 (Burn) requires token state inputs not available in view");
             }
        } else if (fusionType == 2) {
            // Simulate upgrading a single token
            require(tokenIds.length == 1, FusionIngredientMismatch());
            require(ingredientTokenIds.length > 0, FusionIngredientMismatch());
            uint256 baseTokenId = tokenIds[0];
            require(_exists(baseTokenId), InvalidTokenId());
            Chronicle storage chronicle = _chronicles[baseTokenId]; // Access current state

            potentialAttributes = chronicle.attributes;
            potentialReputation = chronicle.reputationScore;

            // Apply upgrade effect based on ingredients/fusion type (example matching _processFusion)
            potentialAttributes[ATTRIBUTE_CREATIVITY] = Math.max(0, potentialAttributes[ATTRIBUTE_CREATIVITY] + 10);
            potentialReputation += 5;

        } else {
            revert InvalidFusionType();
        }
    }

    // --- Governance ---
    function proposeParameterChange(uint8 parameterId, bytes memory newValue, string memory description) external whenNotPaused {
        // Requires caller to own at least `proposalThreshold` Chronicles
        require(balanceOf(msg.sender) >= proposalThreshold, "Not enough Chronicles to propose");

        _proposalIdCounter++;
        uint256 newProposalId = _proposalIdCounter;

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            parameterId: parameterId,
            newValue: newValue,
            description: description,
            voteStartTimestamp: uint64(block.timestamp),
            voteEndTimestamp: uint64(block.timestamp + votingPeriod),
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            state: ProposalState.ACTIVE
        });
        // Note: The `hasVoted` mapping is inside the struct storage mapping.

        emit ProposalCreated(newProposalId, msg.sender, parameterId, newValue, description);
    }

    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, InvalidProposalId()); // Check if proposal exists
        require(proposal.state == ProposalState.ACTIVE, ProposalNotActive());
        require(block.timestamp <= proposal.voteEndTimestamp, ProposalNotActive()); // Within voting period

        address voter = msg.sender;
        require(balanceOf(voter) > 0, "Must own at least one Chronicle to vote"); // Must own at least 1 Chronicle
        require(!proposal.hasVoted[voter], AlreadyVoted());

        proposal.hasVoted[voter] = true;

        uint256 voterChronicleCount = balanceOf(voter); // Vote weight based on number of Chronicles
        if (support) {
            proposal.totalVotesFor += voterChronicleCount;
        } else {
            proposal.totalVotesAgainst += voterChronicleCount;
        }

        emit VoteCast(proposalId, voter, support, proposal.totalVotesFor, proposal.totalVotesAgainst);

        // Check if quorum/voting period ends, update state (can be done off-chain or in execute)
        // For simplicity, state updates mainly happen in execute or getProposalState view.
    }

    function executeProposal(uint256 proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, InvalidProposalId());
        require(proposal.state == ProposalState.ACTIVE || proposal.state == ProposalState.SUCCEEDED, "Proposal not in correct state for execution");
        require(block.timestamp > proposal.voteEndTimestamp, "Voting period has not ended");

        // Determine final state if still ACTIVE
        if (proposal.state == ProposalState.ACTIVE) {
             uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
             if (totalVotes < quorumThreshold || proposal.totalVotesFor <= proposal.totalVotesAgainst) {
                 proposal.state = ProposalState.DEFEATED;
             } else {
                 proposal.state = ProposalState.SUCCEEDED;
             }
        }

        require(proposal.state == ProposalState.SUCCEEDED, ProposalNotExecutable());

        // Execute the parameter change
        _executeParameterChange(proposal.parameterId, proposal.newValue);

        proposal.state = ProposalState.EXECUTED;

        emit ProposalExecuted(proposalId);
    }

    function _executeParameterChange(uint8 parameterId, bytes memory newValue) internal {
        // This requires careful encoding/decoding of `newValue` based on `parameterId`
        // Example:
        if (parameterId == uint8(ProposalParameter.STAKING_INK_RATE)) {
            inkRewardPerAttributePointPerSecond = abi.decode(newValue, (uint256));
        } else if (parameterId == uint8(ProposalParameter.STAKING_FRAGMENT_RATE)) {
            fragmentRewardPerReputationPointPerSecond = abi.decode(newValue, (uint256));
        } else if (parameterId == uint8(ProposalParameter.STAKING_COOLDOWN)) {
            stakingCooldownDuration = abi.decode(newValue, (uint256));
        } else if (parameterId == uint8(ProposalParameter.GOV_VOTING_PERIOD)) {
            votingPeriod = abi.decode(newValue, (uint256));
        } else if (parameterId == uint8(ProposalParameter.GOV_QUORUM)) {
            quorumThreshold = abi.decode(newValue, (uint256));
        } else if (parameterId == uint8(ProposalParameter.GOV_PROPOSAL_THRESHOLD)) {
            proposalThreshold = abi.decode(newValue, (uint256));
        }
        // Note: Changing costs for weaving/fusion via governance would require mapping parameterId to event/fusion types and decoding struct/multiple values.
        // This example only handles simple uint256 parameters.
        // Add more cases for other governable parameters.
        else {
             revert("Unknown or unimplemented parameter change");
        }
    }


    function getProposalState(uint256 proposalId) public view returns (ProposalState, uint256 totalVotesFor, uint256 totalVotesAgainst, uint64 voteEndTimestamp) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, InvalidProposalId());

        ProposalState currentState = proposal.state;
        if (currentState == ProposalState.ACTIVE && block.timestamp > proposal.voteEndTimestamp) {
             // Voting period ended, determine outcome if not already decided
             uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
             if (totalVotes < quorumThreshold || proposal.totalVotesFor <= proposal.totalVotesAgainst) {
                 currentState = ProposalState.DEFEATED;
             } else {
                 currentState = ProposalState.SUCCEEDED;
             }
        }

        return (currentState, proposal.totalVotesFor, proposal.totalVotesAgainst, proposal.voteEndTimestamp);
    }

    // --- Oracle Integration ---
    function updateOracleData(bytes calldata data) external onlyRole(ORACLE_ROLE) whenNotPaused {
        currentOracleData = data;
        emit OracleDataUpdated(data);
    }

    function getOracleInfluence(uint8 eventType, bytes calldata eventData) public view returns (int16[] memory attributeInfluence, int32 reputationInfluence) {
        // This function simulates how oracle data *would* influence an event *if* that event type
        // is configured to use oracle data. The actual influence logic lives in _processWeavingEffect.
        // This view function needs to replicate that logic for simulation.

        // Example Simulation Logic based on _processWeavingEffect for eventType 2:
        if (eventType == 2) {
             int16 resilienceChange = 3; // Base change from _processWeavingEffect
             if (currentOracleData.length > 0) {
                 uint8 oracleMultiplier = uint8(currentOracleData[0]);
                 resilienceChange = int16(resilienceChange * oracleMultiplier / 10);
             }
             attributeInfluence = new int16[](3);
             attributeInfluence[ATTRIBUTE_RESILIENCE] = resilienceChange - 3; // Show the *influence*, not the base change
             reputationInfluence = 2; // Oracle doesn't influence rep change in the example
        } else {
             // Other event types not influenced by Oracle in this example
             attributeInfluence = new int16[](0);
             reputationInfluence = 0;
        }
         // Note: A robust implementation would require a way to query the influence logic per event type.
         // This simple example directly replicates a specific event's logic.
    }

    // --- View Functions ---
    function getChronicleState(uint256 tokenId) public view returns (
        address owner,
        address soulboundTo,
        uint64 mintTimestamp,
        int16[3] memory attributes,
        int32 reputationScore,
        bool isStaked,
        uint64 lastStakedTimestamp,
        bool isSoulbound,
        SoulUnbindingMethod unbindingMethod,
        uint64 unbindingInitiatedTimestamp,
        uint256 unbindingTokenBurnAmount
    ) {
        require(_exists(tokenId), InvalidTokenId());
        Chronicle storage chronicle = _chronicles[tokenId];
        return (
            chronicle.owner,
            chronicle.soulboundTo,
            chronicle.mintTimestamp,
            chronicle.attributes,
            chronicle.reputationScore,
            chronicle.isStaked,
            chronicle.lastStakedTimestamp,
            chronicle.isSoulbound,
            chronicle.unbindingMethod,
            chronicle.unbindingInitiatedTimestamp,
            chronicle.unbindingTokenBurnAmount
        );
    }

    // Admin/Parameter Setters (callable by admin role)
    function setStakingParameters(uint256 _inkRewardPerAttributePointPerSecond, uint256 _fragmentRewardPerReputationPointPerSecond, uint256 _stakingCooldownDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        inkRewardPerAttributePointPerSecond = _inkRewardPerAttributePointPerSecond;
        fragmentRewardPerReputationPointPerSecond = _fragmentRewardPerReputationPointPerSecond;
        stakingCooldownDuration = _stakingCooldownDuration;
    }

     function setWeavingEventParameters(uint8 eventType, uint256 inkCost, uint256 fragmentCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
         // Simplified setter, doesn't set attribute/rep effects as they are internal
         weavingEventInkCost[eventType] = inkCost;
         weavingEventFragmentCost[eventType] = fragmentCost;
     }

     function setFusionParameters(uint8 fusionType, uint256 baseInkCost, uint256 baseFragmentCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
         // Simplified setter for costs only, fusion logic is internal
         // Need to add ways to configure ingredients/results if truly dynamic
         // This is just an example setter for costs.
         revert("setFusionParameters not fully implemented, fusion logic is hardcoded");
     }


    function setGovernanceParameters(uint256 _votingPeriod, uint256 _proposalThreshold, uint256 _quorumThreshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        quorumThreshold = _quorumThreshold;
    }

    function setOracleAddress(address _oracleAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_oracleAddress != address(0), "Invalid Oracle Address");
        oracleAddress = _oracleAddress;
        grantRole(ORACLE_ROLE, _oracleAddress); // Grant the role to the new oracle
        // Optional: Revoke role from old oracle if applicable
    }

     function setTokenAddresses(address _inkToken, address _fragmentToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
         require(_inkToken != address(0), "Invalid Ink Token Address");
         require(_fragmentToken != address(0), "Invalid Fragment Token Address");
         inkToken = IERC20(_inkToken);
         narrativeFragmentToken = IERC20(_fragmentToken);
     }

    // --- Internal Helpers ---
    // Add more internal helpers as needed for complex logic.
}
```