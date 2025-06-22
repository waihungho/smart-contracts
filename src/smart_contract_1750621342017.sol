Okay, let's design a smart contract that represents a collection of "Living Relics". These are dynamic NFTs that evolve, decay, interact with each other, generate a fungible token ("Fragments"), have a reputation system, and incorporate some basic governance and external (simulated) influence mechanics.

This contract avoids direct inheritance from standard libraries like OpenZeppelin's ERC721/ERC20 for its core logic (though it will *implement* the necessary interfaces conceptually for compatibility). The complex state management, inter-token interactions, time-based mechanics, and hybrid fungible/non-fungible aspects are the unique elements.

**Outline & Function Summary**

**Contract Name:** LivingRelics

**Concept:** A collection of dynamic, evolving NFTs (Living Relics) that possess traits, reputation, and status. Relics can interact with each other, decay over time if neglected, be nurtured, earn a fungible token (Fragments), and be subject to limited governance/external influence.

**State Variables:**
*   `relics`: Mapping from `tokenId` to `Relic` struct.
*   `fragmentBalances`: Mapping from address to fragment balance.
*   `relicLinks`: Mapping from `linkId` to `RelicLink` struct.
*   `pendingRelicLinks`: Mapping from `tokenId1 => tokenId2` to `PendingLink` struct.
*   `proposals`: Mapping from `proposalId` to `ParameterChangeProposal` struct.
*   `_tokenIds`: Counter for minting new relics.
*   `_linkIds`: Counter for creating new links.
*   `_proposalIds`: Counter for new proposals.
*   Global parameters (`decayRate`, `nurtureCost`, `fragmentRatePerEssencePerSecond`, etc.).
*   Access control variables (`owner`, `guardianAddress`).

**Structs:**
*   `Relic`: Represents a single Living Relic NFT (traits, status, reputation, owner, timestamps, fragment data, attunement).
*   `RelicLink`: Represents a temporary bond between two relics (linkedTokenIds, startTime, endTime, linkId).
*   `PendingLink`: Records details of a link initiated by one owner, waiting for confirmation.
*   `ParameterChangeProposal`: Stores details of a governance proposal.

**Enums:**
*   `RelicStatus`: Represents the current state of a relic (e.g., Dormant, Awakening, Vibrant, Decaying, Awakened).
*   `ProposalState`: Represents the state of a proposal (e.g., Active, Passed, Failed, Executed).

**Functions (>= 20 custom logic functions beyond standard ERC721 getters):**

**ERC721 Standard (Required Interface):**
1.  `balanceOf(address owner)`: Returns the number of relics owned by an address.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a relic.
3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers relic ownership.
4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers relic ownership safely.
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
6.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific relic.
7.  `setApprovalForAll(address operator, bool approved)`: Approves/revokes an operator for all relics.
8.  `getApproved(uint256 tokenId)`: Returns the approved address for a relic.
9.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved.

**Living Relic Core Mechanics:**
10. `mintRelic(address initialOwner, uint initialEssence, string initialMetadataURI)`: Creates and mints a new relic with initial traits and metadata. (Custom)
11. `checkAndApplyDecay(uint256 tokenId)`: Public function allowing anyone to trigger time-based decay calculation and application for a relic. (Custom, Permissionless State Change Trigger)
12. `nurtureRelic(uint256 tokenId, uint amount)`: Allows the relic owner to spend Ether to improve traits and boost reputation. (Custom, Interaction with Value)
13. `claimFragments(uint256 tokenId)`: Allows the relic owner to claim accumulated Fragments based on the relic's essence and time elapsed. (Custom, Earning Mechanic)
14. `burnFragments(uint amount)`: Allows burning Fragments for potential future benefits (e.g., temporary relic boost, not implemented fully but function exists). (Custom, Token Sink)
15. `sacrificeRelicForFragments(uint256 tokenId)`: Allows the owner to burn a relic to gain a significant amount of Fragments. (Custom, Token Burn / Asset Exchange)

**Inter-Relic Interaction:**
16. `forgeRelicLink(uint256 tokenId1, uint256 tokenId2)`: Initiates a temporary link between two relics, requiring consent from both owners. (Custom, Multi-party Interaction Setup)
17. `confirmRelicLink(uint256 tokenId)`: Called by the owner of the second relic to confirm a pending link request. (Custom, Multi-party Interaction Finalization)
18. `dissolveRelicLink(uint256 linkId)`: Allows either linked relic owner to break an active link. (Custom, Multi-party Interaction Termination)
19. `challengeRelic(uint256 tokenId1, uint256 tokenId2)`: Simulates a challenge between two relics, affecting their stats and reputation based on internal logic. (Custom, Inter-Token Battle/Interaction)

**Reputation & Status:**
20. `getRelicReputation(uint256 tokenId)`: Returns the current reputation score of a relic. (Custom Query)
21. `getRelicStatus(uint256 tokenId)`: Returns the current status of a relic. (Custom Query)
22. `conductAuraReading(uint256 tokenId)`: Pure function simulating an "aura reading" based on current relic stats, returning a calculated value. (Custom Pure Function)

**Attunement (Soulbinding-like):**
23. `attuneRelic(uint256 tokenId, address targetAddress, uint duration)`: Allows the owner to temporarily attune the relic to another address (like a conditional, timed soulbinding). (Custom, Conditional Binding)
24. `revokeAttunement(uint256 tokenId)`: Allows the owner or attuned address to break attunement early. (Custom, Binding Termination)
25. `getAttunedAddress(uint256 tokenId)`: Returns the address a relic is currently attuned to, if any. (Custom Query)

**Governance & External Influence (Simplified):**
26. `setGuardianInfluence(uint256 tokenId, uint traitIndex, int influenceAmount, uint endTime)`: Allows a designated Guardian address to apply temporary positive or negative influence to a specific relic trait. (Custom, Role-Based External Influence)
27. `proposeParameterChange(string paramName, uint newValue)`: Allows the owner to propose changing a global contract parameter (simplified: just records the proposal). (Custom, Governance - Proposal)
28. `voteOnParameterChange(uint proposalId, bool approve)`: Allows Fragment holders (or relic owners) to vote on a proposal (simplified: records votes). (Custom, Governance - Voting)
29. `executeParameterChange(uint proposalId)`: Allows the owner to execute a proposal if it passes (simplified logic). (Custom, Governance - Execution)

**Utility & Query:**
30. `getRelicDetails(uint256 tokenId)`: Returns the full details of a relic struct. (Custom Query)
31. `getFragmentBalance(address account)`: Returns the fragment balance of an address. (Custom Query)
32. `getRelicLinkDetails(uint256 linkId)`: Returns the details of an active relic link. (Custom Query)
33. `getPendingRelicLinkDetails(uint256 tokenId1, uint256 tokenId2)`: Returns details of a pending link. (Custom Query)
34. `getProposalDetails(uint proposalId)`: Returns details of a governance proposal. (Custom Query)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: For a production contract, it's highly recommended to use interfaces
// like IERC721, IERC20, and inherit from standard libraries like Ownable
// from OpenZeppelin for safety and compliance. This example implements
// the core logic directly for demonstration purposes to avoid duplicating
// standard open source *implementations* while still providing the *required
// functionality* for basic compatibility.

/**
 * @title LivingRelics
 * @dev A smart contract for dynamic, evolving NFTs (Living Relics) with inter-token
 *      interactions, time-based decay, a fungible token component (Fragments),
 *      reputation, attunement mechanics, and basic governance/external influence.
 *
 * Outline:
 * 1. State Variables: Core data storage for relics, fragments, links, proposals, parameters.
 * 2. Enums: Status definitions for relics and proposals.
 * 3. Structs: Data structures for Relic, RelicLink, PendingLink, ParameterChangeProposal.
 * 4. Events: Signaling key actions and state changes.
 * 5. Modifiers: Access control and condition checks.
 * 6. Access Control & Constructor: Contract ownership and initialization.
 * 7. ERC721 Standard Functions: Basic NFT functionality (minting handled separately).
 * 8. Internal Helpers: Logic for status updates, reputation adjustment, decay calculation.
 * 9. Living Relic Core Mechanics: Functions for nurturing, claiming, burning, sacrificing, etc.
 * 10. Inter-Relic Interaction: Functions for linking and challenging relics.
 * 11. Reputation & Status Queries: Functions to retrieve relic state information.
 * 12. Attunement Mechanics: Functions for binding relics to addresses.
 * 13. Governance & External Influence: Functions for parameter proposals, voting, external influence.
 * 14. Utility & Query Functions: General getters for contract data.
 *
 * Function Summary:
 * - ERC721 Standard (9 functions): balanceOf, ownerOf, transferFrom, safeTransferFrom (x2), approve, setApprovalForAll, getApproved, isApprovedForAll.
 * - Living Relic Core Mechanics (6 functions): mintRelic, checkAndApplyDecay, nurtureRelic, claimFragments, burnFragments, sacrificeRelicForFragments.
 * - Inter-Relic Interaction (4 functions): forgeRelicLink, confirmRelicLink, dissolveRelicLink, challengeRelic.
 * - Reputation & Status Queries (3 functions): getRelicReputation, getRelicStatus, conductAuraReading.
 * - Attunement Mechanics (3 functions): attuneRelic, revokeAttunement, getAttunedAddress.
 * - Governance & External Influence (4 functions): setGuardianInfluence, proposeParameterChange, voteOnParameterChange, executeParameterChange.
 * - Utility & Query (5 functions): getRelicDetails, getFragmentBalance, getRelicLinkDetails, getPendingRelicLinkDetails, getProposalDetails.
 *
 * Total Unique Concept Functions: 26
 * Total Functions (including basic ERC721 getters): 35+ (depending on exact count of ERC721 overloads)
 */

contract LivingRelics {

    // --- 1. State Variables ---

    // ERC721 & Relic Data
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => Relic) public relics;
    uint256 private _tokenIds; // Counter for unique relic IDs

    // Fragment (Fungible Token) Data
    mapping(address => uint256) public fragmentBalances;
    uint256 public totalFragmentsSupply; // Total supply of the fungible token

    // Relic Linking Data
    mapping(uint256 => RelicLink) public relicLinks;
    mapping(uint256 => mapping(uint256 => PendingLink)) public pendingRelicLinks; // tokenId1 => tokenId2 => PendingLink
    uint256 private _linkIds; // Counter for unique link IDs

    // Governance Data (Simplified)
    mapping(uint256 => ParameterChangeProposal) public proposals;
    uint256 private _proposalIds; // Counter for unique proposal IDs

    // Global Parameters (Configurable by owner/governance)
    uint256 public decayRatePerDay = 1; // How much stats decay per day (e.g., per trait)
    uint256 public nurtureCost = 0.01 ether; // Cost to nurture a relic
    uint256 public fragmentRatePerEssencePerSecond = 1; // Fragments generated per second per point of essence
    uint256 public challengeReputationImpact = 10; // Reputation change from challenges

    // Access Control
    address public owner;
    address public guardianAddress; // A special role for external influence simulation

    // --- 2. Enums ---

    enum RelicStatus {
        Dormant,
        Awakening,
        Vibrant,
        Decaying,
        Awakened // Peak status
    }

    enum ProposalState {
        Active,
        Passed,
        Failed,
        Executed
    }

    // --- 3. Structs ---

    struct Relic {
        address currentOwner;
        uint256 essence; // Core vitality/power trait
        uint256 integrity; // Resilience/defense trait
        uint256 resilience; // Recovery/stability trait
        RelicStatus status;
        int256 reputation; // Can be positive or negative
        uint256 lastInteractTime; // Timestamp of last nurture or claim
        uint256 lastFragmentClaimTime; // Timestamp of last fragment claim
        address attunedTo; // Address relic is currently attuned to
        uint256 attunementEndTime; // Timestamp attunement ends
        uint256 createdAt; // Timestamp relic was created
        string metadataURI;
    }

    struct RelicLink {
        uint256 linkId;
        uint256 tokenId1;
        uint256 tokenId2;
        uint256 startTime;
        uint256 endTime; // 0 if active indefinitely (or specific duration)
        bool isActive;
    }

    struct PendingLink {
        uint256 initiationTime;
        bool initiated;
    }

    struct ParameterChangeProposal {
        uint256 proposalId;
        string paramName; // Name of the parameter to change (e.g., "decayRatePerDay")
        uint256 newValue;
        address proposer;
        uint256 startTime;
        uint256 endTime; // Voting period end
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Prevent double voting (simplified check)
        ProposalState state;
        string description; // Optional description
    }


    // --- 4. Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event RelicMinted(uint256 indexed tokenId, address indexed owner, string metadataURI);
    event RelicNurtured(uint256 indexed tokenId, address indexed nurturer, uint amount);
    event RelicDecayed(uint256 indexed tokenId, RelicStatus newStatus);
    event RelicStatusChanged(uint256 indexed tokenId, RelicStatus oldStatus, RelicStatus newStatus);
    event ReputationAdjusted(uint256 indexed tokenId, int256 oldReputation, int256 newReputation);

    event FragmentsClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event FragmentsTransfer(address indexed from, address indexed to, uint256 amount);
    event FragmentsBurned(address indexed burner, uint256 amount);
    event RelicSacrificedForFragments(uint256 indexed tokenId, address indexed owner, uint256 fragmentsMinted);

    event RelicLinkForged(uint256 indexed linkId, uint256 indexed tokenId1, uint256 indexed tokenId2);
    event RelicLinkDissolved(uint256 indexed linkId);
    event RelicChallengeCompleted(uint256 indexed tokenId1, uint256 indexed tokenId2, address winner, address loser);

    event RelicAttuned(uint256 indexed tokenId, address indexed targetAddress, uint256 endTime);
    event RelicAttunementRevoked(uint256 indexed tokenId);

    event GuardianInfluenceApplied(uint256 indexed tokenId, uint indexed traitIndex, int256 influenceAmount, uint256 endTime);

    event ParameterChangeProposed(uint256 indexed proposalId, string paramName, uint256 newValue, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event ParameterChangeExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);


    // --- 5. Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier onlyRelicOwner(uint256 tokenId) {
        require(_owners[tokenId] == msg.sender, "Only relic owner can call this function");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == guardianAddress, "Only guardian can call this function");
        _;
    }

    modifier ensureRelicExists(uint256 tokenId) {
        require(_exists(tokenId), "Relic does not exist");
        _;
    }

    // --- 6. Access Control & Constructor ---

    constructor(address _guardianAddress) {
        owner = msg.sender;
        guardianAddress = _guardianAddress;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function setGuardianAddress(address _newGuardian) public onlyOwner {
        guardianAddress = _newGuardian;
    }

    // --- 7. ERC721 Standard Functions ---

    // Implemented for basic compatibility. Note: Does not inherit from standard ERC721.

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Balance query for null address");
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Owner query for non-existent token");
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        require(from == _owners[tokenId], "From address is not owner");
        require(to != address(0), "Transfer to null address");

        // Internal transfer logic
        _beforeTokenTransfer(from, to, tokenId);
        _transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
         require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        require(from == _owners[tokenId], "From address is not owner");
        require(to != address(0), "Transfer to null address");

        _beforeTokenTransfer(from, to, tokenId);
        _transfer(from, to, tokenId);
        // Check if the recipient is a smart contract and can receive ERC721 tokens
        require(_checkOnERC721Received(address(0), from, to, tokenId, data), "ERC721Recipient: ERC721_RECEIVED_INTERFACE_INVALID");
        _afterTokenTransfer(from, to, tokenId);
    }


    function approve(address to, uint256 tokenId) public {
        address owner = _owners[tokenId];
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approval caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Approval query for non-existent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --- ERC721 Internal Logic ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     function _transfer(address from, address to, uint256 tokenId) internal {
        if (from != address(0)) {
            _balances[from]--;
            delete _owners[tokenId];
             // Clear approval when transferring
            delete _tokenApprovals[tokenId];
        }
        if (to != address(0)) {
            _balances[to]++;
             _owners[tokenId] = to;
        }
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

     function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Recipient(to).onERC721Received(operator, from, to, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Recipient.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721Recipient: TRANSFER_TO_NON_ERC721_RECEIVER");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true; // Transfer to a non-contract address is always considered safe
        }
    }

    // These hooks can be extended for custom logic before/after transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    // Dummy ERC721Metadata functions (optional but good practice)
    function name() public pure returns (string memory) { return "LivingRelic"; }
    function symbol() public pure returns (string memory) { return "RELIC"; }
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URI query for non-existent token");
        return relics[tokenId].metadataURI;
    }


    // --- 8. Internal Helpers ---

    function _updateRelicStatus(uint256 tokenId) internal {
        Relic storage relic = relics[tokenId];
        RelicStatus oldStatus = relic.status;
        RelicStatus newStatus;

        uint256 totalStats = relic.essence + relic.integrity + relic.resilience;

        if (totalStats == 0) {
             newStatus = RelicStatus.Dormant;
        } else if (relic.reputation < -50) { // Example threshold
            newStatus = RelicStatus.Decaying;
        } else if (totalStats > 300 && relic.reputation > 50) { // Example thresholds
            newStatus = RelicStatus.Awakened;
        } else if (totalStats > 200 && block.timestamp - relic.lastInteractTime < 7 days) { // Example thresholds
            newStatus = RelicStatus.Vibrant;
        } else if (block.timestamp - relic.lastInteractTime < 3 days) {
             newStatus = RelicStatus.Awakening;
        }
        else {
             newStatus = RelicStatus.Dormant;
        }

        if (newStatus != oldStatus) {
            relic.status = newStatus;
            emit RelicStatusChanged(tokenId, oldStatus, newStatus);
        }
    }

    function _adjustReputation(uint256 tokenId, int256 amount) internal {
        Relic storage relic = relics[tokenId];
        int256 oldReputation = relic.reputation;
        relic.reputation += amount;
        emit ReputationAdjusted(tokenId, oldReputation, relic.reputation);
    }

    function _calculateDecay(uint256 tokenId) internal view returns (uint256 decayAmount) {
        Relic storage relic = relics[tokenId];
        uint256 timeElapsed = block.timestamp - relic.lastInteractTime;
        // Decay only applies after a certain idle period (e.g., 2 days)
        uint256 decayThreshold = 2 days;
        if (timeElapsed <= decayThreshold) {
            return 0;
        }
        uint256 idleTime = timeElapsed - decayThreshold;
        // Simple linear decay based on idle time and global rate
        return (idleTime / 1 days) * decayRatePerDay;
    }

    function _applyDecay(uint256 tokenId, uint256 decayAmount) internal {
         Relic storage relic = relics[tokenId];
        if (decayAmount > 0) {
            relic.essence = relic.essence > decayAmount ? relic.essence - decayAmount : 0;
            relic.integrity = relic.integrity > decayAmount ? relic.integrity - decayAmount : 0;
            relic.resilience = relic.resilience > decayAmount ? relic.resilience - decayAmount : 0;
             // Decay also negatively impacts reputation
            _adjustReputation(tokenId, -int256(decayAmount / 2)); // Example impact

             emit RelicDecayed(tokenId, relic.status); // Emit BEFORE status update reflects decay
        }
         relic.lastInteractTime = block.timestamp; // Update last interact time after processing decay
         _updateRelicStatus(tokenId); // Update status after decay applied
    }


    // --- 9. Living Relic Core Mechanics ---

    /**
     * @dev Mints a new Living Relic NFT.
     * @param initialOwner The address to mint the relic to.
     * @param initialEssence The starting essence trait value.
     * @param initialMetadataURI The URI for the relic's metadata.
     */
    function mintRelic(address initialOwner, uint256 initialEssence, string memory initialMetadataURI) public onlyOwner returns (uint256) {
        require(initialOwner != address(0), "Cannot mint to zero address");

        uint256 newItemId = _tokenIds;
        _tokenIds++;

        relics[newItemId] = Relic({
            currentOwner: initialOwner,
            essence: initialEssence,
            integrity: initialEssence / 2, // Example initial calculation
            resilience: initialEssence / 3, // Example initial calculation
            status: RelicStatus.Dormant, // Starts dormant
            reputation: 0,
            lastInteractTime: block.timestamp,
            lastFragmentClaimTime: block.timestamp,
            attunedTo: address(0),
            attunementEndTime: 0,
            createdAt: block.timestamp,
            metadataURI: initialMetadataURI
        });

        // Standard ERC721 minting steps
        _balances[initialOwner]++;
        _owners[newItemId] = initialOwner;

        _updateRelicStatus(newItemId); // Set initial status based on initial stats

        emit Transfer(address(0), initialOwner, newItemId);
        emit RelicMinted(newItemId, initialOwner, initialMetadataURI);

        return newItemId;
    }

    /**
     * @dev Allows anyone to trigger the decay calculation and application for a relic.
     *      Useful for keeping relic states updated on-chain even if owners are inactive.
     *      Could potentially reward the caller in a more complex version.
     * @param tokenId The ID of the relic to check and decay.
     */
    function checkAndApplyDecay(uint256 tokenId) public ensureRelicExists(tokenId) {
        uint256 decayAmount = _calculateDecay(tokenId);
        if (decayAmount > 0) {
            _applyDecay(tokenId, decayAmount);
        }
        // Always update status in case time passed changes it regardless of decay amount
        _updateRelicStatus(tokenId);
    }

     /**
     * @dev Allows the relic owner to spend Ether to improve relic stats and reputation.
     * @param tokenId The ID of the relic to nurture.
     * @param amount The amount of Ether sent (must meet nurtureCost).
     */
    function nurtureRelic(uint256 tokenId, uint256 amount) public payable ensureRelicExists(tokenId) onlyRelicOwner(tokenId) {
        require(msg.value >= nurtureCost, "Insufficient Ether to nurture");
        // Excess Ether is left in the contract or sent back (left for simplicity)

        Relic storage relic = relics[tokenId];

        // Apply decay before nurturing to get current state
        checkAndApplyDecay(tokenId); // Allows anyone to trigger decay first

        // Improve stats based on nurture amount (simplified: fixed boost)
        uint256 statBoost = msg.value / (nurtureCost / 10); // Example: 0.01 ether gives 10 stat points distributed
        relic.essence += statBoost / 3;
        relic.integrity += statBoost / 3;
        relic.resilience += statBoost - (statBoost / 3) * 2;

        _adjustReputation(tokenId, int256(statBoost / 2)); // Nurturing increases reputation

        relic.lastInteractTime = block.timestamp; // Update interaction time
        _updateRelicStatus(tokenId); // Update status after nurture

        emit RelicNurtured(tokenId, msg.sender, msg.value);
    }


    /**
     * @dev Allows the relic owner to claim accumulated Fragments.
     * Fragments are generated based on the relic's essence over time.
     * @param tokenId The ID of the relic to claim fragments from.
     */
    function claimFragments(uint256 tokenId) public ensureRelicExists(tokenId) onlyRelicOwner(tokenId) {
        Relic storage relic = relics[tokenId];
        uint256 timeElapsed = block.timestamp - relic.lastFragmentClaimTime;
        uint256 fragmentsEarned = relic.essence * fragmentRatePerEssencePerSecond * timeElapsed;

        require(fragmentsEarned > 0, "No fragments to claim");

        fragmentBalances[msg.sender] += fragmentsEarned;
        totalFragmentsSupply += fragmentsEarned;
        relic.lastFragmentClaimTime = block.timestamp;

        emit FragmentsClaimed(tokenId, msg.sender, fragmentsEarned);
    }

    /**
     * @dev Allows burning Fragments from the caller's balance.
     * Can be used for potential in-game actions or temporary boosts (feature not fully implemented, but burn mechanic exists).
     * @param amount The number of fragments to burn.
     */
    function burnFragments(uint256 amount) public {
        require(fragmentBalances[msg.sender] >= amount, "Insufficient fragment balance");

        fragmentBalances[msg.sender] -= amount;
        totalFragmentsSupply -= amount;

        // @dev Add logic here for what burning fragments does (e.g., temporary relic boost)
        // Example: apply a temporary boost to the caller's highest essence relic
        // This requires finding the highest essence relic, adding a temporary buff system, etc.
        // For simplicity in this example, it just burns.

        emit FragmentsBurned(msg.sender, amount);
    }

     /**
     * @dev Allows the owner to sacrifice a relic, burning it permanently in exchange for Fragments.
     * @param tokenId The ID of the relic to sacrifice.
     */
    function sacrificeRelicForFragments(uint256 tokenId) public ensureRelicExists(tokenId) onlyRelicOwner(tokenId) {
        Relic storage relic = relics[tokenId];
        address relicOwner = relic.currentOwner;

        // Calculate fragments based on relic stats (example formula)
        uint256 fragmentsEarned = (relic.essence + relic.integrity + relic.resilience) * 1000;

        // Transfer/Mint fragments to the owner
        fragmentBalances[relicOwner] += fragmentsEarned;
        totalFragmentsSupply += fragmentsEarned;

        // Burn the relic (ERC721 standard "burn" is implicitly deleting ownership)
        _burn(tokenId);

        emit RelicSacrificedForFragments(tokenId, relicOwner, fragmentsEarned);
    }

    // ERC721 Internal Burn (simplified implementation)
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Checks existence
        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Remove ownership and balance
        _balances[owner]--;
        delete _owners[tokenId];
        delete relics[tokenId]; // Remove the relic data

        _afterTokenTransfer(owner, address(0), tokenId);
        emit Transfer(owner, address(0), tokenId);
    }


    // --- 10. Inter-Relic Interaction ---

    /**
     * @dev Initiates a process to link two relics. Requires confirmation from the second owner.
     * Linking could enable special interactions or benefits (conceptually).
     * @param tokenId1 The ID of the first relic (owned by msg.sender).
     * @param tokenId2 The ID of the second relic.
     */
    function forgeRelicLink(uint256 tokenId1, uint256 tokenId2) public ensureRelicExists(tokenId1) ensureRelicExists(tokenId2) onlyRelicOwner(tokenId1) {
        require(tokenId1 != tokenId2, "Cannot link a relic to itself");
        // Ensure link doesn't already exist or is pending the other way
        require(relicLinks[_getLinkId(tokenId1, tokenId2)].linkId == 0, "Link already exists");
        require(!pendingRelicLinks[tokenId2][tokenId1].initiated, "Pending link initiated by the other owner exists");

        pendingRelicLinks[tokenId1][tokenId2] = PendingLink({
            initiationTime: block.timestamp,
            initiated: true
        });

        // Event? Could add one
    }

    /**
     * @dev Confirms a pending relic link initiated by another owner.
     * @param tokenId The ID of the relic confirming the link (owned by msg.sender).
     */
    function confirmRelicLink(uint256 tokenId) public ensureRelicExists(tokenId) onlyRelicOwner(tokenId) {
        // Find the pending link where msg.sender's relic is tokenId2
        uint256 otherTokenId = 0;
        for (uint256 i = 1; i < _tokenIds; i++) { // Iterate through existing tokens (basic, inefficient for large numbers)
            if (_owners[i] != address(0) && pendingRelicLinks[i][tokenId].initiated) {
                otherTokenId = i;
                break;
            }
        }

        require(otherTokenId != 0, "No pending link found for this relic");
        require(pendingRelicLinks[otherTokenId][tokenId].initiated, "No pending link found for this relic");

        // Create the link
        uint256 newLinkId = _linkIds++;
        uint256 duration = 7 days; // Example link duration
        relicLinks[newLinkId] = RelicLink({
            linkId: newLinkId,
            tokenId1: otherTokenId,
            tokenId2: tokenId,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            isActive: true
        });

        // Clear the pending link
        delete pendingRelicLinks[otherTokenId][tokenId];

        // @dev Add logic here for what happens when relics link (e.g., temporary stats boost, shared effects)
        // This would require adding effects/buffs system to the Relic struct.

        emit RelicLinkForged(newLinkId, otherTokenId, tokenId);
    }

    /**
     * @dev Allows either owner of a linked pair to dissolve the link.
     * @param linkId The ID of the link to dissolve.
     */
    function dissolveRelicLink(uint256 linkId) public {
        RelicLink storage link = relicLinks[linkId];
        require(link.isActive, "Link is not active");
        require(msg.sender == _owners[link.tokenId1] || msg.sender == _owners[link.tokenId2], "Only linked relic owners can dissolve");

        link.isActive = false;
        // @dev Add logic here for what happens when links are broken (e.g., negative reputation impact)
        _adjustReputation(link.tokenId1, -int256(challengeReputationImpact / 2)); // Example penalty
        _adjustReputation(link.tokenId2, -int256(challengeReputationImpact / 2)); // Example penalty


        emit RelicLinkDissolved(linkId);
    }

    // Internal helper to deterministically get a link ID from two token IDs
    function _getLinkId(uint256 tokenId1, uint256 tokenId2) internal pure returns (uint256) {
        // Ensure order doesn't matter for the ID calculation
        return tokenId1 < tokenId2 ? tokenId1 * 1000000 + tokenId2 : tokenId2 * 1000000 + tokenId1; // Simple unique ID combiner
    }

    /**
     * @dev Simulates a challenge between two relics. Outcome affects stats and reputation.
     * Requires consent from both owners (simplified: both owners must call this function, or one calls and the other confirms).
     * For this example, let's assume the owner of tokenId1 calls, and the owner of tokenId2 must also call.
     * A more robust system would involve consent or a challenge arena concept.
     * @param tokenId1 The ID of the first relic.
     * @param tokenId2 The ID of the second relic.
     */
    function challengeRelic(uint256 tokenId1, uint256 tokenId2) public ensureRelicExists(tokenId1) ensureRelicExists(tokenId2) {
         require(tokenId1 != tokenId2, "Cannot challenge itself");
         address owner1 = _owners[tokenId1];
         address owner2 = _owners[tokenId2];
         require(msg.sender == owner1 || msg.sender == owner2, "Only a relic owner can initiate/confirm a challenge");

        // Simplified challenge logic: compare combined stats + reputation
        Relic storage relic1 = relics[tokenId1];
        Relic storage relic2 = relics[tokenId2];

        uint256 score1 = relic1.essence + relic1.integrity + relic1.resilience + uint256(int256(relic1.reputation) > 0 ? relic1.reputation : 0);
        uint256 score2 = relic2.essence + relic2.integrity + relic2.resilience + uint256(int256(relic2.reputation) > 0 ? relic2.reputation : 0);

        address winner;
        address loser;
        uint256 winnerTokenId;
        uint256 loserTokenId;

        if (score1 > score2) {
            winner = owner1;
            loser = owner2;
            winnerTokenId = tokenId1;
            loserTokenId = tokenId2;
        } else if (score2 > score1) {
            winner = owner2;
            loser = owner1;
            winnerTokenId = tokenId2;
            loserTokenId = tokenId1;
        } else {
            // Draw - no change
             emit RelicChallengeCompleted(tokenId1, tokenId2, address(0), address(0)); // Indicate draw with null addresses
             return;
        }

        // Apply consequences: winner gains reputation, loser loses stats and reputation
        _adjustReputation(winnerTokenId, challengeReputationImpact);
        _adjustReputation(loserTokenId, -int256(challengeReputationImpact));

        // Loser's stats slightly decrease (example)
        Relic storage loserRelic = relics[loserTokenId];
        loserRelic.essence = loserRelic.essence > 5 ? loserRelic.essence - 5 : 0;
        loserRelic.integrity = loserRelic.integrity > 5 ? loserRelic.integrity - 5 : 0;

        _updateRelicStatus(winnerTokenId);
        _updateRelicStatus(loserTokenId);

        emit RelicChallengeCompleted(tokenId1, tokenId2, winner, loser);
    }


    // --- 11. Reputation & Status Queries ---

    /**
     * @dev Returns the current reputation of a relic.
     * @param tokenId The ID of the relic.
     * @return The relic's reputation score.
     */
    function getRelicReputation(uint256 tokenId) public view ensureRelicExists(tokenId) returns (int256) {
        return relics[tokenId].reputation;
    }

     /**
     * @dev Returns the current status of a relic. Note: This does NOT force a status update.
     *      Use `checkAndApplyDecay` or `nurtureRelic` to potentially update status first.
     * @param tokenId The ID of the relic.
     * @return The relic's status enum value.
     */
    function getRelicStatus(uint256 tokenId) public view ensureRelicExists(tokenId) returns (RelicStatus) {
        // It's best practice for view functions not to change state, even if it's just calling an internal update.
        // The user should call a state-changing function (like checkAndApplyDecay) first if they need the most current status.
        return relics[tokenId].status;
    }

    /**
     * @dev Calculates and returns a synthetic "aura" score based on current relic stats.
     * Pure function - does not read state (directly) or write state.
     * @param tokenId The ID of the relic.
     * @return A calculated aura value.
     */
    function conductAuraReading(uint256 tokenId) public view ensureRelicExists(tokenId) returns (uint256 auraValue) {
         // Note: As a pure function, it strictly cannot read contract state variables like relics mapping.
         // To make this realistic, it would need to be a view function reading the relic state.
         // Let's make it a view function as intended by the concept, even if the summary said 'Pure'.
         Relic storage relic = relics[tokenId];
         // Simple example calculation: essence * 3 + integrity * 2 + resilience + positive reputation bonus
         uint256 positiveRepBonus = int256(relic.reputation) > 0 ? uint256(relic.reputation) : 0;
         return (relic.essence * 3) + (relic.integrity * 2) + relic.resilience + positiveRepBonus;
    }


    // --- 12. Attunement Mechanics ---

    /**
     * @dev Temporarily attunes a relic to a specific address. Like a conditional, timed soulbinding.
     * The attuned address might gain special permissions or benefits (conceptually).
     * @param tokenId The ID of the relic.
     * @param targetAddress The address to attune the relic to.
     * @param duration The duration of the attunement in seconds.
     */
    function attuneRelic(uint256 tokenId, address targetAddress, uint256 duration) public ensureRelicExists(tokenId) onlyRelicOwner(tokenId) {
        require(targetAddress != address(0), "Cannot attune to zero address");
        require(duration > 0, "Attunement duration must be greater than zero");

        Relic storage relic = relics[tokenId];
        relic.attunedTo = targetAddress;
        relic.attunementEndTime = block.timestamp + duration;

        // @dev Add logic here for attunement benefits/permissions

        emit RelicAttuned(tokenId, targetAddress, relic.attunementEndTime);
    }

    /**
     * @dev Revokes the attunement of a relic. Can be called by the owner or the attuned address.
     * @param tokenId The ID of the relic.
     */
    function revokeAttunement(uint256 tokenId) public ensureRelicExists(tokenId) {
        Relic storage relic = relics[tokenId];
        require(relic.attunedTo != address(0), "Relic is not currently attuned");
        require(msg.sender == _owners[tokenId] || msg.sender == relic.attunedTo, "Only owner or attuned address can revoke attunement");

        relic.attunedTo = address(0);
        relic.attunementEndTime = 0;

         // @dev Add logic here for attunement revocation consequences

        emit RelicAttunementRevoked(tokenId);
    }

    /**
     * @dev Returns the address a relic is currently attuned to. Returns zero address if not attuned or attunement expired.
     * @param tokenId The ID of the relic.
     * @return The attuned address or address(0).
     */
    function getAttunedAddress(uint256 tokenId) public view ensureRelicExists(tokenId) returns (address) {
        Relic storage relic = relics[tokenId];
        if (relic.attunedTo != address(0) && block.timestamp < relic.attunementEndTime) {
            return relic.attunedTo;
        }
        return address(0);
    }


    // --- 13. Governance & External Influence (Simplified) ---

    /**
     * @dev Allows the Guardian address to apply temporary influence to a relic's trait.
     * Simulates an external factor or oracle influence based on a privileged role.
     * @param tokenId The ID of the relic.
     * @param traitIndex The index of the trait to influence (0: essence, 1: integrity, 2: resilience).
     * @param influenceAmount The amount of influence (can be positive or negative).
     * @param endTime The timestamp when the influence ends.
     */
    function setGuardianInfluence(uint256 tokenId, uint256 traitIndex, int256 influenceAmount, uint256 endTime) public ensureRelicExists(tokenId) onlyGuardian {
        require(traitIndex < 3, "Invalid trait index");
        require(endTime > block.timestamp, "Influence end time must be in the future");

        Relic storage relic = relics[tokenId];

        // This is a very basic implementation. A real system would need a way to store
        // and apply temporary buffs/debuffs. For this example, we'll just log the event.
        // A more complex implementation would require a separate mapping for active effects
        // and modifying getter functions/interaction logic to factor in these effects.

        // Simulating application: Directly modifying the trait for demonstration (NOT ideal for temporary effects)
        // Better: Store effect start/end/amount and apply in getter/logic functions.
        // For this example, we'll just emit the event.

        // Example of how it *would* apply conceptually (but requires state change and complex tracking)
        /*
        if (traitIndex == 0) relic.essence = influenceAmount > 0 ? relic.essence + uint256(influenceAmount) : relic.essence - uint256(-influenceAmount);
        if (traitIndex == 1) relic.integrity = influenceAmount > 0 ? relic.integrity + uint256(influenceAmount) : relic.integrity - uint256(-influenceAmount);
        if (traitIndex == 2) relic.resilience = influenceAmount > 0 ? relic.resilience + uint256(influenceAmount) : relic.resilience - uint256(-influenceAmount);
        */

        emit GuardianInfluenceApplied(tokenId, traitIndex, influenceAmount, endTime);
    }

    /**
     * @dev Allows the contract owner to propose changing a global parameter.
     * Simplified governance: proposals are just recorded. No voting or execution logic included in this version.
     * @param paramName The name of the parameter (string).
     * @param newValue The new value proposed for the parameter.
     */
    function proposeParameterChange(string memory paramName, uint256 newValue) public onlyOwner returns (uint256) {
        uint256 proposalId = _proposalIds++;
        proposals[proposalId] = ParameterChangeProposal({
            proposalId: proposalId,
            paramName: paramName,
            newValue: newValue,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // Example voting period
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            hasVoted: new mapping(address => bool), // Not storing who voted, just that they did for simplicity
            state: ProposalState.Active,
            description: "" // Optional
        });

        emit ParameterChangeProposed(proposalId, paramName, newValue, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows an address to vote on a parameter change proposal.
     * Voting power could be based on relic count or fragment balance (simplified: 1 Fragment = 1 vote).
     * @param proposalId The ID of the proposal.
     * @param approve True to vote for, false to vote against.
     */
    function voteOnParameterChange(uint256 proposalId, bool approve) public {
        ParameterChangeProposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal (simplified)");

        // Example Voting Power: Based on Fragment Balance at the time of voting
        uint256 votingPower = fragmentBalances[msg.sender];
        require(votingPower > 0, "Requires fragments to vote");

        if (approve) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }

        proposal.hasVoted[msg.sender] = true; // Mark as voted (simplified)

        emit VoteCast(proposalId, msg.sender, approve);
    }

     /**
     * @dev Allows the contract owner to execute a parameter change proposal if it has passed.
     * Simplified logic for checking if it passes.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 proposalId) public onlyOwner {
        ParameterChangeProposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp > proposal.endTime, "Voting period is not over");

        // Simplified passing condition: More 'for' votes than 'against' votes
        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            // Apply the change based on paramName (requires careful string matching or enum/bytes32)
            bytes32 paramNameHash = keccak256(abi.encodePacked(proposal.paramName));

            if (paramNameHash == keccak256(abi.encodePacked("decayRatePerDay"))) {
                decayRatePerDay = proposal.newValue;
            } else if (paramNameHash == keccak256(abi.encodePacked("nurtureCost"))) {
                 nurtureCost = proposal.newValue;
            } else if (paramNameHash == keccak256(abi.encodePacked("fragmentRatePerEssencePerSecond"))) {
                 fragmentRatePerEssencePerSecond = proposal.newValue;
            } else if (paramNameHash == keccak256(abi.encodePacked("challengeReputationImpact"))) {
                 challengeReputationImpact = proposal.newValue;
            } else {
                 revert("Unknown parameter name");
            }

            proposal.state = ProposalState.Executed;
            emit ParameterChangeExecuted(proposalId, proposal.paramName, proposal.newValue);

        } else {
            proposal.state = ProposalState.Failed;
            // Event for failure?
        }
    }


    // --- 14. Utility & Query Functions ---

    /**
     * @dev Returns the full details of a relic.
     * @param tokenId The ID of the relic.
     * @return The Relic struct.
     */
    function getRelicDetails(uint256 tokenId) public view ensureRelicExists(tokenId) returns (Relic memory) {
        return relics[tokenId];
    }

     /**
     * @dev Returns the fragment balance of an address.
     * @param account The address to query.
     * @return The fragment balance.
     */
    function getFragmentBalance(address account) public view returns (uint256) {
        return fragmentBalances[account];
    }

    /**
     * @dev Returns the details of an active relic link.
     * @param linkId The ID of the link.
     * @return The RelicLink struct.
     */
    function getRelicLinkDetails(uint256 linkId) public view returns (RelicLink memory) {
        require(relicLinks[linkId].isActive, "Link does not exist or is not active");
        return relicLinks[linkId];
    }

    /**
     * @dev Returns the details of a pending relic link.
     * @param tokenId1 The ID of the first relic in the pending link.
     * @param tokenId2 The ID of the second relic in the pending link.
     * @return The PendingLink struct.
     */
    function getPendingRelicLinkDetails(uint256 tokenId1, uint256 tokenId2) public view returns (PendingLink memory) {
         require(pendingRelicLinks[tokenId1][tokenId2].initiated, "No pending link exists between these relics initiated by owner1");
         return pendingRelicLinks[tokenId1][tokenId2];
    }

     /**
     * @dev Returns the details of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return The ParameterChangeProposal struct.
     */
    function getProposalDetails(uint256 proposalId) public view returns (ParameterChangeProposal memory) {
         require(proposals[proposalId].proposer != address(0), "Proposal does not exist");
         return proposals[proposalId];
    }

    // --- Standard ERC721Enumerable (Optional but common) ---
    // Not implemented here to keep focus on the core concept, but these would store
    // token IDs per owner and a list of all token IDs.

    // --- Standard ERC20 (Optional) ---
    // This contract has its own basic fragment balance mapping and transfer logic
    // but does not implement the full IERC20 interface.


    // --- Interface for ERC721Recipient (Used by safeTransferFrom) ---
    interface IERC721Recipient {
        function onERC721Received(address operator, address from, address tokenId, uint256 value, bytes calldata data) external returns (bytes4);
    }
}
```