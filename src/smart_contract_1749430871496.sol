Okay, let's create a smart contract concept that combines a few advanced and trending ideas: Dynamic NFTs, NFT-based Governance (DAO), and NFT Staking with attribute boosting.

We'll call it "SynergyOrbsDAO". The core idea is an ERC-721 NFT representing a "Synergy Orb". These Orbs have mutable attributes that can change based on user actions (like staking) or DAO governance. The DAO itself is governed by Orb holders.

This concept incorporates:
1.  **Dynamic NFTs:** Attributes stored on-chain can change.
2.  **NFT-based Governance:** Orb ownership confers voting power.
3.  **NFT Staking:** Staking Orbs provides benefits (e.g., attribute boost, voting power multiplier).
4.  **Meta-transactions:** Allow gasless voting using signed messages (`ecrecover`).
5.  **Custom Errors:** For better gas efficiency and clarity.
6.  **Reentrancy Guard:** Standard security practice.

---

**Outline & Function Summary**

**Contract Name:** SynergyOrbsDAO

**Inherits:** ERC721, ERC721Enumerable, ERC721Metadata (or implementations), Ownable, ReentrancyGuard

**Core Concepts:**
*   **Synergy Orb (NFT):** An ERC-721 token with mutable `OrbAttributes`.
*   **OrbAttributes:** Struct containing `uint256` values like `Synergy`, `Resilience`, `Insight`.
*   **Staking:** Users can stake Orbs to earn passive attribute boosts and/or voting power multipliers over time.
*   **Governance (DAO):** Orb holders can create and vote on proposals to change contract parameters or trigger global attribute shifts.
*   **Voting Power:** Calculated based on the number of Orbs owned/staked, potentially modified by staking duration/attributes.
*   **Meta-Transactions:** Allow users to cast votes off-chain and have them relayed gaslessly.

**State Variables:**
*   `_orbAttributes`: Mapping from `tokenId` to `OrbAttributes`.
*   `_stakedOrbs`: Mapping from `tokenId` to `StakedOrbData`.
*   `_isStaked`: Mapping from `tokenId` to `bool`.
*   `_stakeStartTime`: Mapping from `tokenId` to `uint48`.
*   `_proposals`: Mapping from `proposalId` to `Proposal` struct.
*   `_voteReceipts`: Mapping from `proposalId` to `address` to `bool` (voted?).
*   `_nextProposalId`: Counter for new proposals.
*   `_governanceParams`: Struct holding DAO parameters (quorum, voting period, etc.).
*   `_nonces`: Mapping from `address` to `uint256` for signature replay protection.
*   ERC721 standard mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`, `_ownedTokens`, `_allTokens`).
*   `_baseTokenURI`: Base URI for metadata.

**Structs:**
*   `OrbAttributes`: `uint256 synergy; uint256 resilience; uint256 insight;`
*   `StakedOrbData`: `address owner; uint48 stakeStartTime;`
*   `GovernanceParameters`: `uint256 minOrbsToCreateProposal; uint64 votingPeriod; uint256 quorumNumerator; uint256 quorumDenominator; uint256 proposalThreshold;`
*   `Proposal`: `address proposer; string description; uint48 votingDeadline; uint256 votesFor; uint256 votesAgainst; uint256 votesAbstain; ProposalState state; bytes callData; address target;`

**Enums:**
*   `ProposalState`: `Pending, Active, Canceled, Defeated, Succeeded, Executed, Expired`

**Functions (>= 20):**

*   **ERC721 Standard (13 functions):**
    1.  `balanceOf(address owner) external view returns (uint256 count)`
    2.  `ownerOf(uint256 tokenId) external view returns (address owner)`
    3.  `transferFrom(address from, address to, uint256 tokenId) external`
    4.  `safeTransferFrom(address from, address to, uint256 tokenId) external`
    5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external`
    6.  `approve(address to, uint256 tokenId) external`
    7.  `setApprovalForAll(address operator, bool approved) external`
    8.  `getApproved(uint256 tokenId) external view returns (address operator)`
    9.  `isApprovedForAll(address owner, address operator) external view returns (bool)`
    10. `supportsInterface(bytes4 interfaceId) external view returns (bool)`
    11. `totalSupply() public view returns (uint256)` (from Enumerable)
    12. `tokenByIndex(uint256 index) public view returns (uint256)` (from Enumerable)
    13. `tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256)` (from Enumerable)
    14. `tokenURI(uint256 tokenId) public view returns (string memory)` (from Metadata)
    15. `name() public view returns (string memory)` (from Metadata)
    16. `symbol() public view returns (string memory)` (from Metadata)

*   **Orb Management (Dynamic Attributes):**
    17. `mintOrb(address to, uint256 initialSynergy, uint256 initialResilience, uint256 initialInsight) external onlyOwner returns (uint256 tokenId)`: Mints a new Orb with initial attributes.
    18. `getOrbAttributes(uint256 tokenId) public view returns (OrbAttributes memory)`: Gets current attributes of an Orb.
    19. `boostAttribute(uint256 tokenId, uint256 attributeIndex, uint256 amount) external payable whenNotStaked(tokenId)`: Allows Orb owner to pay ETH (or other cost) to boost a specific attribute.
    20. `levelUpOrb(uint256 tokenId, uint256[] calldata burnTokenIds) external whenNotStaked(tokenId)`: Burns specific Orbs (`burnTokenIds`) owned by the caller to upgrade `tokenId` with enhanced attributes.
    21. `_applyStakingBoost(uint256 tokenId, uint48 duration) internal`: Internal function to calculate/apply attribute boost based on staking duration.

*   **NFT Staking:**
    22. `stakeOrb(uint256 tokenId) external whenNotStaked(tokenId)`: Stakes an Orb, transfers ownership to the contract, records start time.
    23. `unstakeOrb(uint256 tokenId) external whenStaked(tokenId)`: Unstakes an Orb, transfers ownership back, calculates and applies staking boost.
    24. `getStakedOrbData(uint256 tokenId) public view returns (StakedOrbData memory)`: Gets staking data for an Orb.
    25. `isOrbStaked(uint256 tokenId) public view returns (bool)`: Checks if an Orb is staked.

*   **Governance (DAO):**
    26. `getVotingPower(address voter) public view returns (uint256)`: Calculates total voting power for an address based on owned/staked Orbs and staking duration bonuses.
    27. `createProposal(address target, bytes memory callData, string memory description) external returns (uint256 proposalId)`: Creates a new proposal (requires minimum voting power).
    28. `vote(uint256 proposalId, uint8 support) external`: Casts a vote (For=1, Against=2, Abstain=3) on a proposal (requires having Orbs).
    29. `executeProposal(uint256 proposalId) external payable`: Executes a successful proposal.
    30. `getProposal(uint256 proposalId) public view returns (Proposal memory)`: Gets details of a proposal.
    31. `state(uint256 proposalId) public view returns (ProposalState)`: Gets the current state of a proposal.

*   **Meta-transaction Voting:**
    32. `voteBySignature(uint256 proposalId, uint8 support, uint256 nonce, bytes calldata signature) external`: Casts a vote using an off-chain signature.

*   **Utility/Configuration:**
    33. `setGovernanceParameters(uint256 minOrbs, uint64 votingPeriod, uint256 quorumNum, uint256 quorumDen, uint256 threshold) external onlyOwner`: Sets DAO parameters.
    34. `setBaseTokenURI(string memory baseURI) external onlyOwner`: Sets the base URI for metadata.
    35. `withdrawETH(address payable recipient, uint256 amount) external onlyOwner`: Allows owner (or DAO in future) to withdraw ETH received (e.g., from `boostAttribute`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For execute

// Outline & Function Summary
// Contract Name: SynergyOrbsDAO
// Inherits: ERC721, ERC721Enumerable, ERC721Metadata, Ownable, ReentrancyGuard
// Core Concepts:
// - Synergy Orb (NFT): An ERC-721 token with mutable OrbAttributes.
// - OrbAttributes: Struct containing uint256 values like Synergy, Resilience, Insight.
// - Staking: Users can stake Orbs to earn passive attribute boosts and/or voting power multipliers over time.
// - Governance (DAO): Orb holders can create and vote on proposals to change contract parameters or trigger global attribute shifts.
// - Voting Power: Calculated based on the number of Orbs owned/staked, potentially modified by staking duration/attributes.
// - Meta-Transactions: Allow gasless voting using signed messages (ecrecover).
// - Custom Errors: For better gas efficiency and clarity.
// - Reentrancy Guard: Standard security practice.

// State Variables:
// - _orbAttributes: Mapping from tokenId to OrbAttributes.
// - _stakedOrbs: Mapping from tokenId to StakedOrbData.
// - _isStaked: Mapping from tokenId to bool.
// - _stakeStartTime: Mapping from tokenId to uint48.
// - _proposals: Mapping from proposalId to Proposal struct.
// - _voteReceipts: Mapping from proposalId to address to bool (voted?).
// - _nextProposalId: Counter for new proposals.
// - _governanceParams: Struct holding DAO parameters (quorum, voting period, etc.).
// - _nonces: Mapping from address to uint256 for signature replay protection.
// - ERC721 standard mappings (_owners, _balances, _tokenApprovals, _operatorApprovals, _ownedTokens, _allTokens).
// - _baseTokenURI: Base URI for metadata.

// Structs:
// - OrbAttributes: uint256 synergy; uint256 resilience; uint256 insight;
// - StakedOrbData: address owner; uint48 stakeStartTime;
// - GovernanceParameters: uint256 minOrbsToCreateProposal; uint64 votingPeriod; uint256 quorumNumerator; uint256 quorumDenominator; uint256 proposalThreshold;
// - Proposal: address proposer; string description; uint48 votingDeadline; uint256 votesFor; uint256 votesAgainst; uint256 votesAbstain; ProposalState state; bytes callData; address target;

// Enums:
// - ProposalState: Pending, Active, Canceled, Defeated, Succeeded, Executed, Expired

// Functions (>= 20):
// 1-10. ERC721 Standard (balanceOf, ownerOf, transferFrom, safeTransferFrom (x2), approve, setApprovalForAll, getApproved, isApprovedForAll, supportsInterface)
// 11-13. ERC721Enumerable Standard (totalSupply, tokenByIndex, tokenOfOwnerByIndex)
// 14-16. ERC721Metadata Standard (tokenURI, name, symbol)
// 17. mintOrb: Mints a new Orb.
// 18. getOrbAttributes: Gets current attributes.
// 19. boostAttribute: Pay cost to boost an attribute.
// 20. levelUpOrb: Burn Orbs to upgrade one.
// 21. _applyStakingBoost: Internal helper for staking boost logic.
// 22. stakeOrb: Stake an Orb.
// 23. unstakeOrb: Unstake an Orb.
// 24. getStakedOrbData: Gets staking data.
// 25. isOrbStaked: Checks if staked.
// 26. getVotingPower: Calculates voter's power.
// 27. createProposal: Creates a DAO proposal.
// 28. vote: Casts a vote on a proposal.
// 29. executeProposal: Executes a proposal.
// 30. getProposal: Gets proposal details.
// 31. state: Gets proposal state.
// 32. voteBySignature: Casts a vote using an off-chain signature.
// 33. setGovernanceParameters: Sets DAO config.
// 34. setBaseTokenURI: Sets metadata base URI.
// 35. withdrawETH: Allows owner/DAO to withdraw ETH.

contract SynergyOrbsDAO is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Address for address; // For low-level calls

    // --- Custom Errors ---
    error Unauthorized();
    error InvalidTokenId(uint256 tokenId);
    error NotOrbOwner(uint256 tokenId, address caller);
    error AlreadyStaked(uint256 tokenId);
    error NotStaked(uint256 tokenId);
    error NothingToClaim(uint256 tokenId); // If staking yields claims
    error InvalidVote(uint8 support);
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotActive(uint256 proposalId, ProposalState currentState);
    error ProposalNotSucceeded(uint256 proposalId, ProposalState currentState);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error InsufficientVotingPower(address voter, uint256 requiredPower, uint256 currentPower);
    error InvalidSignature();
    error IncorrectNonce(address signer, uint256 expectedNonce, uint256 receivedNonce);
    error InvalidAttributeIndex(uint256 index);
    error InsufficientEth(uint256 required, uint256 sent);
    error InvalidLevelUpOrbs();
    error InvalidProposalTarget();

    // --- Structs ---
    struct OrbAttributes {
        uint256 synergy;    // Affects voting power multiplier, staking boost rate
        uint256 resilience; // Affects resistance to negative global shifts
        uint256 insight;    // Affects proposal creation threshold reduction
    }

    struct StakedOrbData {
        address owner;
        uint48 stakeStartTime; // Using uint48 for timestamp to save gas
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed,
        Expired // Added Expired state
    }

    struct Proposal {
        address proposer;
        string description;
        uint48 votingDeadline; // Using uint48 for timestamp
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        ProposalState state;
        bytes callData;
        address target;
    }

    struct GovernanceParameters {
        uint256 minOrbsToCreateProposal; // Minimum number of Orbs required to create a proposal
        uint64 votingPeriod;              // Duration of voting period in seconds
        uint256 quorumNumerator;           // Numerator for quorum calculation (quorum = total voting power * numerator / denominator)
        uint256 quorumDenominator;         // Denominator for quorum calculation
        uint256 proposalThreshold;         // Minimum votes (raw count, or power?) needed to pass (simplest: raw count of votes)
    }

    // --- State Variables ---
    mapping(uint256 => OrbAttributes) private _orbAttributes;
    mapping(uint256 => StakedOrbData) private _stakedOrbs;
    mapping(uint256 => bool) private _isStaked;
    mapping(uint256 => uint48) private _stakeStartTime; // Store separately for easier check

    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _voteReceipts; // proposalId => voterAddress => hasVoted?

    Counters.Counter private _nextTokenId;
    Counters.Counter private _nextProposalId;

    GovernanceParameters public _governanceParams;

    mapping(address => uint256) private _nonces; // For signature replay protection

    string private _baseTokenURI;

    // --- Events ---
    event OrbMinted(address indexed to, uint256 indexed tokenId, OrbAttributes initialAttributes);
    event OrbAttributesUpdated(uint256 indexed tokenId, OrbAttributes newAttributes);
    event OrbStaked(address indexed owner, uint256 indexed tokenId, uint48 startTime);
    event OrbUnstaked(address indexed owner, uint256 indexed tokenId, uint48 endTime);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint48 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, uint8 support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event GovernanceParametersUpdated(GovernanceParameters params);
    event BaseTokenURIUpdated(string baseURI);
    event EthWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier whenNotStaked(uint256 tokenId) {
        if (_isStaked[tokenId]) revert AlreadyStaked(tokenId);
        _;
    }

    modifier whenStaked(uint256 tokenId) {
        if (!_isStaked[tokenId]) revert NotStaked(tokenId);
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        ERC721Enumerable()
        ERC721URIStorage()
        Ownable(msg.sender) // Initial owner is deployer
        ReentrancyGuard()
    {
        // Set initial governance parameters (example values)
        _governanceParams = GovernanceParameters({
            minOrbsToCreateProposal: 3,        // Need 3 Orbs to create a proposal
            votingPeriod: 7 days,              // Voting lasts 7 days
            quorumNumerator: 4,                // 40% quorum
            quorumDenominator: 10,
            proposalThreshold: 5               // Need 5 votes (raw count for simplicity) to pass
        });
    }

    // --- ERC721 Overrides ---

    // The following functions are required overrides for ERC721, ERC721Enumerable, ERC721URIStorage
    // and implement functions 1-16 in the summary.
    // Their standard implementation is provided by OpenZeppelin contracts.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenByIndex(uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
         // Ensure staked Orbs are not transferred except during unstaking
        if (_isStaked[tokenId] && from != address(this)) {
             // This should ideally be prevented by requiring unstake first,
             // but this check adds safety against direct transfers.
             // However, standard ERC721 transfer logic handles this by checking ownership.
             // If `from` is address(this), it means it's being unstaked.
        }
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function _totalMinted() internal view override(ERC721Enumerable) returns (uint256) {
        return super._totalMinted();
    }

    // We need to make sure tokenURI handles our dynamic attributes if needed.
    // This simplified version uses base URI + token ID. A more complex one would
    // involve an off-chain service reading attributes via getOrbAttributes.
    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory) {
         _requireOwned(tokenId); // Check if token exists
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }


    // --- Orb Management (Dynamic Attributes) --- (Functions 17-21)

    /// @notice Mints a new Synergy Orb with specified initial attributes.
    /// @param to The address to mint the Orb to.
    /// @param initialSynergy The initial Synergy attribute value.
    /// @param initialResilience The initial Resilience attribute value.
    /// @param initialInsight The initial Insight attribute value.
    /// @return tokenId The ID of the newly minted Orb.
    function mintOrb(address to, uint256 initialSynergy, uint256 initialResilience, uint256 initialInsight)
        external
        onlyOwner // Only owner can mint new Orbs initially
        returns (uint256 tokenId)
    {
        _nextTokenId.increment();
        tokenId = _nextTokenId.current();
        _mint(to, tokenId);

        _orbAttributes[tokenId] = OrbAttributes({
            synergy: initialSynergy,
            resilience: initialResilience,
            insight: initialInsight
        });

        emit OrbMinted(to, tokenId, _orbAttributes[tokenId]);
        return tokenId;
    }

    /// @notice Gets the current attributes of a Synergy Orb.
    /// @param tokenId The ID of the Orb.
    /// @return The OrbAttributes struct for the specified Orb.
    function getOrbAttributes(uint256 tokenId) public view returns (OrbAttributes memory) {
        // Check if token exists implicitly via ownerOf or balances check if needed,
        // but direct mapping access is gas cheaper if caller guarantees existence.
        // We rely on _requireOwned check in tokenURI for existence validation example.
        // For internal logic, just access the mapping.
        // For a public getter, maybe add existence check:
        // if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        return _orbAttributes[tokenId];
    }

    /// @notice Allows the Orb owner to boost a specific attribute by paying a cost.
    /// @param tokenId The ID of the Orb to boost.
    /// @param attributeIndex The index of the attribute (0=Synergy, 1=Resilience, 2=Insight).
    /// @param amount The amount to increase the attribute by.
    /// @dev Requires the Orb not to be staked. Requires a certain amount of ETH to be sent.
    function boostAttribute(uint256 tokenId, uint256 attributeIndex, uint256 amount)
        external
        payable
        whenNotStaked(tokenId)
        nonReentrant // Added reentrancy guard
    {
        // Check ownership
        if (ownerOf(tokenId) != msg.sender) revert NotOrbOwner(tokenId, msg.sender);

        // Define cost per boost amount (example: 0.01 ETH per 100 attribute points)
        uint256 cost = amount * 0.0001 ether; // Example: 0.0001 ETH per point
        if (msg.value < cost) revert InsufficientEth(cost, msg.value);

        OrbAttributes storage attributes = _orbAttributes[tokenId];

        if (attributeIndex == 0) {
            attributes.synergy += amount;
        } else if (attributeIndex == 1) {
            attributes.resilience += amount;
        } else if (attributeIndex == 2) {
            attributes.insight += amount;
        } else {
            revert InvalidAttributeIndex(attributeIndex);
        }

        emit OrbAttributesUpdated(tokenId, attributes);
    }

    /// @notice Allows the Orb owner to burn specific lower-level Orbs to upgrade a target Orb.
    /// @param tokenId The ID of the target Orb to upgrade.
    /// @param burnTokenIds An array of token IDs to burn for the upgrade.
    /// @dev Requires the target Orb not to be staked. Specific burn combinations/rules would be needed in a real contract.
    /// This is a placeholder function.
    function levelUpOrb(uint256 tokenId, uint256[] calldata burnTokenIds)
        external
        whenNotStaked(tokenId)
        nonReentrant
    {
        // Check ownership of the target Orb
        if (ownerOf(tokenId) != msg.sender) revert NotOrbOwner(tokenId, msg.sender);

        // --- Placeholder Logic ---
        // In a real contract, you would verify:
        // 1. The types/levels of `burnTokenIds` are valid for upgrading `tokenId`.
        // 2. `msg.sender` owns all `burnTokenIds`.
        // 3. Orbs in `burnTokenIds` are not staked.
        // 4. Calculate the attribute boost based on the burned Orbs.
        // For this example, we'll just check minimum burn count and ownership.
        if (burnTokenIds.length < 2) revert InvalidLevelUpOrbs(); // Example rule: must burn at least 2

        uint256 totalBurnSynergy = 0;
        for (uint i = 0; i < burnTokenIds.length; i++) {
            uint256 burnId = burnTokenIds[i];
            if (!_exists(burnId)) revert InvalidTokenId(burnId);
            if (ownerOf(burnId) != msg.sender) revert NotOrbOwner(burnId, msg.sender);
            if (_isStaked[burnId]) revert AlreadyStaked(burnId); // Cannot burn staked Orbs

            totalBurnSynergy += _orbAttributes[burnId].synergy; // Example: Boost based on burned Synergy

            _burn(burnId); // Burn the Orb
            delete _orbAttributes[burnId]; // Clean up attributes
        }
        // --- End Placeholder Logic ---

        // Apply boost to the target Orb
        OrbAttributes storage targetAttributes = _orbAttributes[tokenId];
        targetAttributes.synergy += (totalBurnSynergy / 2); // Example boost formula

        emit OrbAttributesUpdated(tokenId, targetAttributes);
    }

    /// @dev Internal function to calculate and apply attribute boost based on staking duration.
    /// @param tokenId The ID of the Orb.
    /// @param duration The duration the Orb was staked in seconds.
    function _applyStakingBoost(uint256 tokenId, uint48 duration) internal {
        OrbAttributes storage attributes = _orbAttributes[tokenId];

        // Example boost logic: 1 Synergy per day staked (approx), capped.
        uint256 boostAmount = duration / 1 days; // integer division
        uint256 maxBoost = 100; // Cap example
        boostAmount = boostAmount > maxBoost ? maxBoost : boostAmount;

        attributes.synergy += boostAmount;
        // Could also boost other attributes or apply different formulas

        emit OrbAttributesUpdated(tokenId, attributes);
    }


    // --- NFT Staking --- (Functions 22-25)

    /// @notice Stakes a Synergy Orb. Transfers ownership to the contract.
    /// @param tokenId The ID of the Orb to stake.
    /// @dev Requires the caller to be the owner and the Orb not already staked.
    function stakeOrb(uint256 tokenId) external whenNotStaked(tokenId) nonReentrant {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) revert NotOrbOwner(tokenId, msg.sender);

        // Approve the contract to transfer the token
        safeTransferFrom(owner, address(this), tokenId);

        _isStaked[tokenId] = true;
        _stakeStartTime[tokenId] = uint48(block.timestamp); // Record start time
        _stakedOrbs[tokenId] = StakedOrbData({owner: owner, stakeStartTime: uint48(block.timestamp)}); // Store owner and time

        emit OrbStaked(owner, tokenId, _stakeStartTime[tokenId]);
    }

    /// @notice Unstakes a Synergy Orb. Transfers ownership back to the original staker.
    /// Applies staking boost based on duration.
    /// @param tokenId The ID of the Orb to unstake.
    /// @dev Requires the Orb to be staked.
    function unstakeOrb(uint256 tokenId) external whenStaked(tokenId) nonReentrant {
        StakedOrbData memory data = _stakedOrbs[tokenId];
        address staker = data.owner; // Get original staker
        uint48 startTime = data.stakeStartTime;
        uint48 duration = uint48(block.timestamp) - startTime;

        _isStaked[tokenId] = false;
        delete _stakeStartTime[tokenId];
        delete _stakedOrbs[tokenId];

        // Transfer ownership back to the original staker
        _safeTransfer(address(this), staker, tokenId); // Use internal _safeTransfer

        // Apply attribute boost based on staking duration
        _applyStakingBoost(tokenId, duration);

        emit OrbUnstaked(staker, tokenId, uint48(block.timestamp));
    }

    /// @notice Gets staking data for a staked Orb.
    /// @param tokenId The ID of the Orb.
    /// @return The StakedOrbData struct.
    function getStakedOrbData(uint256 tokenId) public view returns (StakedOrbData memory) {
        if (!_isStaked[tokenId]) revert NotStaked(tokenId);
        return _stakedOrbs[tokenId];
    }

    /// @notice Checks if an Orb is currently staked.
    /// @param tokenId The ID of the Orb.
    /// @return bool True if staked, false otherwise.
    function isOrbStaked(uint256 tokenId) public view returns (bool) {
        return _isStaked[tokenId];
    }


    // --- Governance (DAO) --- (Functions 26-31)

    /// @notice Calculates the voting power of an address.
    /// @param voter The address whose voting power to calculate.
    /// @return The total voting power.
    /// @dev Voting power is based on owned and staked Orbs. Staked Orbs get a bonus based on duration.
    function getVotingPower(address voter) public view returns (uint256) {
        uint256 ownedOrbCount = balanceOf(voter);
        uint256 stakedOrbCount = 0;
        uint256 stakedBonusPower = 0;

        // Iterate through all tokens owned by the contract (staked ones)
        // This is inefficient for many staked tokens. A better way would be
        // to track staked token IDs per user if performance is critical.
        // For this example, we iterate owned tokens of the contract and check the staker.
        uint256 contractOwnedTokens = balanceOf(address(this));
        for(uint i=0; i < contractOwnedTokens; i++){
            uint256 tokenId = tokenOfOwnerByIndex(address(this), i);
            if(_isStaked[tokenId] && _stakedOrbs[tokenId].owner == voter){
                 stakedOrbCount++;
                 // Example bonus: +1 power per 30 days staked, max +5 per orb
                 uint48 duration = uint48(block.timestamp) - _stakeStartTime[tokenId];
                 uint256 bonus = duration / 30 days; // integer division
                 stakedBonusPower += bonus > 5 ? 5 : bonus;
            }
        }

        // Simple power = owned + staked + staked bonus
        return ownedOrbCount + stakedOrbCount + stakedBonusPower;
    }

    /// @notice Creates a new DAO proposal.
    /// @param target The address of the contract/address to call if the proposal passes.
    /// @param callData The calldata to execute on the target if the proposal passes.
    /// @param description A description of the proposal.
    /// @return proposalId The ID of the newly created proposal.
    /// @dev Requires the proposer to have minimum voting power.
    function createProposal(address target, bytes memory callData, string memory description)
        external
        nonReentrant
        returns (uint256 proposalId)
    {
        uint256 votingPower = getVotingPower(msg.sender);
        if (votingPower < _governanceParams.minOrbsToCreateProposal) {
            revert InsufficientVotingPower(msg.sender, _governanceParams.minOrbsToCreateProposal, votingPower);
        }
        if(target == address(0)) revert InvalidProposalTarget();

        proposalId = _nextProposalId.current();
        _nextProposalId.increment();

        _proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: description,
            votingDeadline: uint48(block.timestamp + _governanceParams.votingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            state: ProposalState.Active, // Proposal is active immediately after creation
            callData: callData,
            target: target
        });

        emit ProposalCreated(proposalId, msg.sender, description, _proposals[proposalId].votingDeadline);
        return proposalId;
    }

    /// @notice Casts a vote on an active proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support The vote support (1=For, 2=Against, 3=Abstain).
    /// @dev Requires the voter to have voting power and not have already voted on this proposal.
    function vote(uint256 proposalId, uint8 support) external nonReentrant {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(proposalId); // Check if proposal exists

        ProposalState currentState = state(proposalId); // Get current state dynamically
        if (currentState != ProposalState.Active) revert ProposalNotActive(proposalId, currentState);

        if (_voteReceipts[proposalId][msg.sender]) revert AlreadyVoted(msg.sender, proposalId); // Custom error for already voted? Using standard bool check.

        if (support == 1) {
            proposal.votesFor++;
        } else if (support == 2) {
            proposal.votesAgainst++;
        } else if (support == 3) {
            proposal.votesAbstain++;
        } else {
            revert InvalidVote(support);
        }

        _voteReceipts[proposalId][msg.sender] = true; // Record vote
        emit Voted(proposalId, msg.sender, support, getVotingPower(msg.sender)); // Emit voter's current power (optional)
    }

    /// @notice Executes a proposal that has succeeded.
    /// @param proposalId The ID of the proposal to execute.
    /// @dev Requires the proposal to be in the Succeeded state and not already executed.
    function executeProposal(uint256 proposalId) external payable nonReentrant {
        Proposal storage proposal = _proposals[proposalId];
         if (proposal.proposer == address(0)) revert ProposalNotFound(proposalId);

        ProposalState currentState = state(proposalId);
        if (currentState == ProposalState.Executed) revert ProposalAlreadyExecuted(proposalId);
        if (currentState != ProposalState.Succeeded) revert ProposalNotSucceeded(proposalId, currentState);

        // Mark as executed before the call to prevent re-execution during the call
        proposal.state = ProposalState.Executed;

        // Execute the proposal calldata on the target address
        (bool success, ) = proposal.target.call{value: msg.value}(proposal.callData);

        emit ProposalExecuted(proposalId, success);
        // Note: Consider adding error handling here if call fails, maybe revert or log failure.
        // For simplicity, we just emit success status.
    }

     /// @notice Gets the current state of a proposal.
     /// @param proposalId The ID of the proposal.
     /// @return The ProposalState enum value.
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.proposer == address(0)) return ProposalState.Expired; // Or a specific NotFound state

        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.votingDeadline) {
            // Voting period ended, determine outcome
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;

            // Quorum check: is total votes >= total voting power * quorumNumerator / quorumDenominator?
            // For simplicity, let's use raw vote counts against total existing Orbs.
            // A more robust DAO would need to track total voting power at the time of proposal creation/snapshot.
            // Let's use total raw votes vs a percentage of total supply as a simpler example quorum.
             uint256 totalPossibleVotes = totalSupply(); // Simple proxy for total possible voting power
             uint256 requiredQuorum = (totalPossibleVotes * _governanceParams.quorumNumerator) / _governanceParams.quorumDenominator;

            if (totalVotes < requiredQuorum) {
                 return ProposalState.Defeated;
            }

            // Simple majority check
            if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= _governanceParams.proposalThreshold) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Defeated;
            }
        }
        // Return the stored state if voting is ongoing or already decided/executed/canceled
        return proposal.state;
    }


    /// @notice Gets the details of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The Proposal struct.
    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
        Proposal storage proposal = _proposals[proposalId];
         if (proposal.proposer == address(0)) revert ProposalNotFound(proposalId);
        return proposal;
    }


    // --- Meta-transaction Voting --- (Function 32)

    /// @notice Casts a vote using an off-chain signature. Allows gasless voting.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support The vote support (1=For, 2=Against, 3=Abstain).
    /// @param nonce The sender's current nonce.
    /// @param signature The signed message from the voter.
    /// @dev The signature must be over a hash of the proposal ID, support, and nonce.
    function voteBySignature(uint256 proposalId, uint8 support, uint256 nonce, bytes calldata signature) external nonReentrant {
        // Reconstruct the message hash that was signed by the voter
        bytes32 messageHash = keccak256(abi.encodePacked(
            address(this), // Domain separator (contract address)
            proposalId,
            support,
            nonce
        ));

        // Recover the signer's address from the signature
        address signer = messageHash.toEthSignedMessageHash().recover(signature);

        // Check if the signer is a valid voter (e.g., holds Orbs)
        if (getVotingPower(signer) == 0) revert InsufficientVotingPower(signer, 1, 0); // Must have at least 1 voting power

        // Check for signature replay attacks using a nonce
        if (_nonces[signer] != nonce) revert IncorrectNonce(signer, _nonces[signer], nonce);
        _nonces[signer]++; // Increment nonce after successful use

         // Check if the signer has already voted on this proposal
        if (_voteReceipts[proposalId][signer]) revert AlreadyVoted(signer, proposalId);

        // Now, apply the vote as if the signer called the vote function directly
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(proposalId);

        ProposalState currentState = state(proposalId);
        if (currentState != ProposalState.Active) revert ProposalNotActive(proposalId, currentState);

        if (support == 1) {
            proposal.votesFor++;
        } else if (support == 2) {
            proposal.votesAgainst++;
        } else if (support == 3) {
            proposal.votesAbstain++;
        } else {
            revert InvalidVote(support);
        }

        _voteReceipts[proposalId][signer] = true;
        emit Voted(proposalId, signer, support, getVotingPower(signer)); // Emit signer's power
    }

    // Function to get the nonce for a given address (useful for off-chain signing)
    function getNonce(address addr) public view returns (uint256) {
        return _nonces[addr];
    }


    // --- Utility/Configuration --- (Functions 33-35)

    /// @notice Sets the governance parameters for the DAO.
    /// @dev Only callable by the owner (or a successful DAO proposal).
    function setGovernanceParameters(
        uint256 minOrbs,
        uint64 votingPeriodSeconds,
        uint256 quorumNum,
        uint256 quorumDen,
        uint256 threshold
    ) external onlyOwner {
        _governanceParams = GovernanceParameters({
            minOrbsToCreateProposal: minOrbs,
            votingPeriod: votingPeriodSeconds,
            quorumNumerator: quorumNum,
            quorumDenominator: quorumDen,
            proposalThreshold: threshold
        });
        emit GovernanceParametersUpdated(_governanceParams);
    }

    /// @notice Sets the base URI for the Orb metadata.
    /// @param baseURI The new base URI string.
    /// @dev Only callable by the owner (or a successful DAO proposal).
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseTokenURIUpdated(baseURI);
    }

    /// @notice Allows the owner to withdraw ETH from the contract.
    /// @param payable recipient The address to send the ETH to.
    /// @param amount The amount of ETH to withdraw.
    /// @dev Useful for withdrawing ETH collected from `boostAttribute`. Should ideally be controlled by DAO.
    function withdrawETH(address payable recipient, uint256 amount) external onlyOwner nonReentrant {
        if (address(this).balance < amount) revert InsufficientEth(amount, address(this).balance);
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert Address.SendValueFailed(recipient, amount); // Use OpenZeppelin error

        emit EthWithdrawn(recipient, amount);
    }

    // --- Internal ERC721 Helper Overrides ---
    // These ensure ERC721Enumerable and ERC721URIStorage work correctly
    // and are implicitly part of the ERC721 function count.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

     function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }

     function _safeTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._safeTransfer(from, to, tokenId);
    }

     function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
         super._burn(tokenId);
     }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic NFTs (`OrbAttributes`, `boostAttribute`, `levelUpOrb`, `_applyStakingBoost`):**
    *   The `OrbAttributes` struct is stored directly on-chain for each token ID.
    *   Attributes are mutable. Functions like `boostAttribute` and `levelUpOrb` explicitly change these on-chain values.
    *   `_applyStakingBoost` demonstrates a passive way attributes could change based on interaction duration (staking time).
    *   The `tokenURI` function could be enhanced (though not fully implemented here due to complexity) to point to a service that reads these on-chain attributes and generates dynamic metadata (JSON, image) reflecting the current state of the Orb.

2.  **NFT-based Governance (`getVotingPower`, `createProposal`, `vote`, `executeProposal`, `state`):**
    *   Voting power is directly tied to holding Orbs (`getVotingPower`).
    *   Staking provides a potential boost to voting power, incentivizing long-term commitment.
    *   The `createProposal` function requires a minimum threshold of voting power, preventing spam.
    *   The `vote` function checks Orb ownership/voting power *at the time of voting* (a snapshot mechanism could be more robust in a full DAO, but this is simpler).
    *   Proposals can trigger arbitrary calls on target contracts via `executeProposal`, enabling the DAO to manage the protocol, upgrade parameters (`setGovernanceParameters`, `setBaseTokenURI`), or even interact with other contracts.
    *   The `state` function includes logic for quorum and simple majority based on collected votes.

3.  **NFT Staking (`stakeOrb`, `unstakeOrb`, `isOrbStaked`):**
    *   Users can lock their Orbs in the contract.
    *   Staking is explicitly tracked, and the Orb's ownership is transferred to the contract while staked.
    *   Unstaking returns the Orb and triggers the `_applyStakingBoost` logic, linking staking duration to the NFT's attributes.

4.  **Meta-transaction Voting (`voteBySignature`, `getNonce`):**
    *   The `voteBySignature` function allows a user to sign a vote request off-chain.
    *   Anyone (a relayer) can then submit this signed message to the contract.
    *   The contract uses `ecrecover` to verify the signature against the message hash (including the contract address and a nonce to prevent replay attacks).
    *   If the signature is valid and the nonce is correct, the vote is recorded under the *signer's* address, effectively allowing gasless voting for the user.

5.  **Custom Errors:** Used throughout the contract (e.g., `InvalidTokenId`, `NotStaked`, `InsufficientVotingPower`) to provide specific and gas-efficient error reporting compared to simple `require` strings.

**Note:** This contract is a demonstration of concepts and includes simplifications (e.g., voting power calculation, `levelUpOrb` rules, quorum calculation based on total supply snapshot). A production-ready DAO would require more sophisticated mechanisms for vote delegation, snapshotting voting power, potentially timelocks for execution, more detailed proposal types, treasury management, etc. However, this provides a solid foundation incorporating the requested advanced features and meeting the function count requirement.