Okay, let's design a smart contract concept around "Quantum Entanglement" applied to tokens. This isn't literal quantum computing, but uses the *idea* of linked states and probabilistic outcomes or conditional actions based on that state as inspiration for unique on-chain mechanics.

We'll create a system of tokens minted in "pairs". Each pair is logically linked (entangled) and can exist in different states (`Entangled` or `Disentangled`). The state affects what actions can be performed with or on the pair.

**Concept:** Quantum Entangled Tokens (QET)

*   Tokens are issued as **Pairs**, each represented by a unique `pairId`.
*   A Pair consists of two conceptual "sides": Alpha and Beta.
*   A Pair can be in one of two primary states: `Entangled` or `Disentangled`.
*   Operations on a Pair depend heavily on its current state.
*   Disentangling a Pair unlocks specific "split" actions for Alpha and Beta sides.
*   Entanglement can decay over time, requiring re-entanglement.
*   Re-entanglement might require specific conditions or "proofs" (simulated).
*   Some attributes of the Pair might change based on its state or time.

---

**Outline & Function Summary:**

**I. Contract Overview:**
*   Custom token system based on "Pairs".
*   Pairs have unique IDs and states (`Entangled`, `Disentangled`).
*   Ownership is per Pair.
*   Features state-dependent actions, time decay simulation, and hypothetical external data interaction.

**II. State Variables:**
*   `_pairOwner`: Mapping from `pairId` to owner address.
*   `_pairState`: Mapping from `pairId` to `PairState` enum.
*   `_pairApproval`: Mapping from `pairId` to approved address (like ERC-721).
*   `_operatorApprovals`: Mapping owner => operator => approved (like ERC-721).
*   `_lastEntanglementTime`: Mapping `pairId` to timestamp of last entanglement.
*   `_decayPreventionUntil`: Mapping `pairId` to timestamp preventing decay.
*   `_entanglementDuration`: Duration after which entanglement *can* decay.
*   `_alphaSplitClaimed`: Mapping `pairId` to bool indicating if Alpha split was claimed while disentangled.
*   `_betaSplitClaimed`: Mapping `pairId` to bool indicating if Beta split was claimed while disentangled.
*   `_quantumVolatility`: Mapping `pairId` to a dynamic attribute value.
*   `_totalMintedPairs`: Counter for total pairs ever minted.
*   `_totalEntangledPairs`: Counter for currently entangled pairs.
*   `_totalDisentangledPairs`: Counter for currently disentangled pairs.
*   `_baseURI`: Base URI for metadata.

**III. Events:**
*   `PairMinted`: New pair created.
*   `PairTransferred`: Pair ownership changed.
*   `PairStateChanged`: Pair state changed (Entangled/Disentangled).
*   `AlphaSplitClaimed`: Alpha side action performed.
*   `BetaSplitClaimed`: Beta side action performed.
*   `EntanglementDecayed`: Entanglement state automatically changed.
*   `EntanglementDecayPrevented`: Decay prevention applied.
*   `VolatilityUpdated`: Quantum Volatility attribute changed.
*   (Standard ERC-721 events like `Approval`, `ApprovalForAll` also implicitly needed for compatibility patterns).

**IV. Modifiers:**
*   `whenEntangled`: Requires pair state is `Entangled`.
*   `whenDisentangled`: Requires pair state is `Disentangled`.
*   `whenAlphaSplitNotClaimed`: Requires Alpha split hasn't been claimed in the current disentangled phase.
*   `whenBetaSplitNotClaimed`: Requires Beta split hasn't been claimed in the current disentangled phase.
*   `onlyPairOwnerOrApproved`: Requires caller is owner or approved.

**V. Core Functions (State Management & Transfers):**
1.  `mintPair(address recipient)`: Mints a new pair in the `Entangled` state to the recipient.
2.  `transferFrom(address from, address to, uint256 pairId)`: Transfers ownership of a specific pair (ERC-721 pattern).
3.  `safeTransferFrom(address from, address to, uint256 pairId)`: Safer transfer, checks if recipient can receive (ERC-721 pattern).
4.  `safeTransferFrom(address from, address to, uint256 pairId, bytes calldata data)`: Safe transfer with data (ERC-721 pattern).
5.  `approve(address to, uint256 pairId)`: Approves an address to transfer a specific pair (ERC-721 pattern).
6.  `setApprovalForAll(address operator, bool approved)`: Grants/revokes operator status (ERC-721 pattern).
7.  `disentanglePair(uint256 pairId)`: Changes pair state from `Entangled` to `Disentangled`. Resets split claim flags. Only owner/approved.
8.  `reEntanglePair(uint256 pairId)`: Changes pair state from `Disentangled` to `Entangled`. Resets decay prevention timer. Only owner/approved.

**VI. Conditional & State-Dependent Actions:**
9.  `splitAlpha(uint256 pairId)`: Performs an action associated with the Alpha side. **Requires** the pair is `Disentangled` and the Alpha split hasn't been claimed since last disentanglement. Marks Alpha split as claimed. (Simulated action).
10. `splitBeta(uint256 pairId)`: Performs an action associated with the Beta side. **Requires** the pair is `Disentangled` and the Beta split hasn't been claimed since last disentanglement. Marks Beta split as claimed. (Simulated action).
11. `decayEntanglement(uint256 pairId)`: Allows anyone to trigger a check; if enough time has passed since last entanglement and decay prevention is not active, the pair becomes `Disentangled`.
12. `preventDecay(uint256 pairId)`: Allows owner/approved to pay a fee (e.g., Ether) to extend the `_decayPreventionUntil` timestamp. (Simulated fee collection to owner).
13. `attemptReEntangle(uint256 pairId, bytes calldata complexProof)`: A more complex re-entanglement that might require off-chain data verification (simulated via `bytes` parameter). Potentially has different outcomes or requirements than `reEntanglePair`. Only owner/approved.
14. `updateVolatilityBasedOnState(uint256 pairId)`: Updates the `_quantumVolatility` attribute based on the current state (`Entangled` or `Disentangled`) and potentially other factors. Can be called by owner or via external trigger.

**VII. Batch Operations (Utility):**
15. `batchTransferPairs(address[] memory recipients, uint256[] memory pairIds)`: Transfers multiple pairs to corresponding recipients.
16. `batchDisentangle(uint256[] memory pairIds)`: Disentangles a list of pairs.
17. `batchReEntangle(uint256[] memory pairIds)`: Re-entangles a list of pairs.

**VIII. Query Functions (View/Pure):**
18. `ownerOf(uint256 pairId)`: Get owner of a pair (ERC-721 pattern).
19. `getApproved(uint256 pairId)`: Get approved address for a pair (ERC-721 pattern).
20. `isApprovedForAll(address owner, address operator)`: Check if operator is approved for all pairs of owner (ERC-721 pattern).
21. `getPairState(uint256 pairId)`: Get the state of a pair.
22. `isEntangled(uint256 pairId)`: Check if a pair is `Entangled`.
23. `isDisentangled(uint256 pairId)`: Check if a pair is `Disentangled`.
24. `getLastEntanglementTime(uint256 pairId)`: Get timestamp of last entanglement.
25. `getDecayPreventionUntil(uint256 pairId)`: Get timestamp until decay is prevented.
26. `getAlphaSplitClaimed(uint256 pairId)`: Check if Alpha split claimed in current disentangled phase.
27. `getBetaSplitClaimed(uint256 pairId)`: Check if Beta split claimed in current disentangled phase.
28. `getQuantumVolatility(uint256 pairId)`: Get the current volatility attribute.
29. `getTotalSupply()`: Get total pairs ever minted.
30. `getEntangledPairCount()`: Get count of currently entangled pairs.
31. `getDisentangledPairCount()`: Get count of currently disentangled pairs.
32. `tokenURI(uint256 pairId)`: Get metadata URI for a pair, potentially reflecting its state. (ERC-721 pattern adaptation).
33. `getBaseURI()`: Get the base metadata URI.
34. `getEntanglementDuration()`: Get the configured decay duration.
35. `getPairsOwnedBy(address owner)`: Retrieve a list of pair IDs owned by an address (can be gas-intensive for many tokens).

**IX. Admin/Configuration Functions (Ownable):**
36. `setBaseURI(string memory newBaseURI)`: Sets the base URI for metadata.
37. `setEntanglementDuration(uint256 duration)`: Sets the duration after which entanglement can decay.
38. `withdrawFees()`: Allows owner to withdraw collected Ether (from `preventDecay`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Note: This contract uses concepts inspired by quantum mechanics (entanglement, state dependency, decay)
// to create unique token dynamics. It is not a literal implementation of quantum computing.
// It adapts some ERC-721 patterns for pair ownership but is not a standard ERC-721 contract.

/**
 * @title QuantumEntangledTokens
 * @dev A novel token standard based on pairs with distinct states (Entangled/Disentangled).
 * The state dictates available actions and token properties.
 */
contract QuantumEntangledTokens is Ownable {

    // --- Outline & Function Summary ---
    //
    // I. Contract Overview:
    //    - Custom token system based on "Pairs".
    //    - Pairs have unique IDs and states (Entangled, Disentangled).
    //    - Ownership is per Pair, adapting ERC-721 patterns.
    //    - Features state-dependent actions, time decay simulation, and hypothetical external data interaction.
    //
    // II. State Variables:
    //    - _pairOwner: Mapping from pairId to owner address.
    //    - _pairState: Mapping from pairId to PairState enum.
    //    - _pairApproval: Mapping from pairId to approved address (like ERC-721).
    //    - _operatorApprovals: Mapping owner => operator => approved (like ERC-721).
    //    - _lastEntanglementTime: Mapping pairId to timestamp of last entanglement.
    //    - _decayPreventionUntil: Mapping pairId to timestamp preventing decay.
    //    - _entanglementDuration: Duration after which entanglement *can* decay.
    //    - _alphaSplitClaimed: Mapping pairId to bool indicating if Alpha split was claimed while disentangled.
    //    - _betaSplitClaimed: Mapping pairId to bool indicating if Beta split was claimed while disentangled.
    //    - _quantumVolatility: Mapping pairId to a dynamic attribute value.
    //    - _totalMintedPairs: Counter for total pairs ever minted.
    //    - _totalEntangledPairs: Counter for currently entangled pairs.
    //    - _totalDisentangledPairs: Counter for currently disentangled pairs.
    //    - _baseURI: Base URI for metadata.
    //
    // III. Events:
    //    - PairMinted: New pair created.
    //    - PairTransferred: Pair ownership changed.
    //    - PairStateChanged: Pair state changed (Entangled/Disentangled).
    //    - AlphaSplitClaimed: Alpha side action performed.
    //    - BetaSplitClaimed: Beta side action performed.
    //    - EntanglementDecayed: Entanglement state automatically changed.
    //    - EntanglementDecayPrevented: Decay prevention applied.
    //    - VolatilityUpdated: Quantum Volatility attribute changed.
    //    - Approval, ApprovalForAll (ERC-721 standard events).
    //
    // IV. Modifiers:
    //    - whenEntangled: Requires pair state is Entangled.
    //    - whenDisentangled: Requires pair state is Disentangled.
    //    - whenAlphaSplitNotClaimed: Requires Alpha split hasn't been claimed in the current disentangled phase.
    //    - whenBetaSplitNotClaimed: Requires Beta split hasn't been claimed in the current disentangled phase.
    //    - onlyPairOwnerOrApproved: Requires caller is owner or approved for the pair.
    //
    // V. Core Functions (State Management & Transfers):
    // 1.  mintPair(address recipient): Mints a new pair in Entangled state. (Owner only)
    // 2.  transferFrom(address from, address to, uint256 pairId): Transfers ownership.
    // 3.  safeTransferFrom(address from, address to, uint256 pairId): Safer transfer.
    // 4.  safeTransferFrom(address from, address to, uint256 pairId, bytes calldata data): Safe transfer with data.
    // 5.  approve(address to, uint256 pairId): Approves address for a pair.
    // 6.  setApprovalForAll(address operator, bool approved): Grants/revokes operator status.
    // 7.  disentanglePair(uint256 pairId): Changes state Entangled -> Disentangled. Resets split claims.
    // 8.  reEntanglePair(uint256 pairId): Changes state Disentangled -> Entangled. Resets decay timer/prevention.
    //
    // VI. Conditional & State-Dependent Actions:
    // 9.  splitAlpha(uint256 pairId): Performs Alpha action. Requires Disentangled & Alpha split not claimed.
    // 10. splitBeta(uint256 pairId): Performs Beta action. Requires Disentangled & Beta split not claimed.
    // 11. decayEntanglement(uint256 pairId): Triggers decay check based on time and prevention.
    // 12. preventDecay(uint256 pairId): Pays fee to extend decay prevention time. (Payable)
    // 13. attemptReEntangle(uint256 pairId, bytes calldata complexProof): Re-entangle with simulated external proof.
    // 14. updateVolatilityBasedOnState(uint256 pairId): Updates volatility based on state and potentially other factors. (Owner/Admin or external trigger)
    //
    // VII. Batch Operations (Utility):
    // 15. batchTransferPairs(address[] memory recipients, uint256[] memory pairIds): Transfers multiple pairs.
    // 16. batchDisentangle(uint256[] memory pairIds): Disentangles multiple pairs.
    // 17. batchReEntangle(uint256[] memory pairIds): Re-entangles multiple pairs.
    //
    // VIII. Query Functions (View/Pure):
    // 18. ownerOf(uint256 pairId): Get owner.
    // 19. getApproved(uint256 pairId): Get approved address.
    // 20. isApprovedForAll(address owner, address operator): Check operator status.
    // 21. getPairState(uint256 pairId): Get state enum.
    // 22. isEntangled(uint256 pairId): Check if Entangled.
    // 23. isDisentangled(uint256 pairId): Check if Disentangled.
    // 24. getLastEntanglementTime(uint256 pairId): Get last entanglement time.
    // 25. getDecayPreventionUntil(uint256 pairId): Get decay prevention time.
    // 26. getAlphaSplitClaimed(uint256 pairId): Check Alpha split claimed status.
    // 27. getBetaSplitClaimed(uint256 pairId): Check Beta split claimed status.
    // 28. getQuantumVolatility(uint256 pairId): Get volatility.
    // 29. getTotalSupply(): Get total minted count.
    // 30. getEntangledPairCount(): Get entangled count.
    // 31. getDisentangledPairCount(): Get disentangled count.
    // 32. tokenURI(uint256 pairId): Get metadata URI (state-dependent).
    // 33. getBaseURI(): Get base URI.
    // 34. getEntanglementDuration(): Get decay duration setting.
    // 35. getPairsOwnedBy(address owner): Get list of owned pair IDs.
    //
    // IX. Admin/Configuration Functions (Ownable):
    // 36. setBaseURI(string memory newBaseURI): Set base URI.
    // 37. setEntanglementDuration(uint256 duration): Set decay duration.
    // 38. withdrawFees(): Withdraw collected Ether.
    //
    // --- End Outline & Function Summary ---

    enum PairState { Entangled, Disentangled }

    // --- State Variables ---

    mapping(uint256 => address) private _pairOwner;
    mapping(uint256 => PairState) private _pairState;
    mapping(uint256 => address) private _pairApproval;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => uint256) private _lastEntanglementTime;
    mapping(uint256 => uint256) private _decayPreventionUntil;
    uint256 public _entanglementDuration; // Duration in seconds for potential decay

    mapping(uint256 => bool) private _alphaSplitClaimed; // Claimed during *current* disentangled phase
    mapping(uint256 => bool) private _betaSplitClaimed; // Claimed during *current* disentangled phase

    mapping(uint256 => uint256) private _quantumVolatility; // A hypothetical attribute that changes

    uint256 private _totalMintedPairs;
    uint256 private _totalEntangledPairs;
    uint256 private _totalDisentangledPairs;

    string private _baseURI;

    address[] private _allPairs; // Simple list for iteration (gas warning)
    mapping(address => uint256[]) private _ownedPairs; // List per owner (gas warning)

    // --- Events ---

    event PairMinted(uint256 indexed pairId, address indexed recipient);
    event PairTransferred(address indexed from, address indexed to, uint256 indexed pairId);
    event PairStateChanged(uint256 indexed pairId, PairState oldState, PairState newState);
    event AlphaSplitClaimed(uint256 indexed pairId, address indexed owner);
    event BetaSplitClaimed(uint256 indexed pairId, address indexed owner);
    event EntanglementDecayed(uint256 indexed pairId, address indexed owner);
    event EntanglementDecayPrevented(uint256 indexed pairId, address indexed owner, uint256 durationAdded);
    event VolatilityUpdated(uint256 indexed pairId, uint256 newVolatility);

    // Standard ERC-721 like events
    event Approval(address indexed owner, address indexed approved, uint256 indexed pairId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Modifiers ---

    modifier whenEntangled(uint256 pairId) {
        require(_pairState[pairId] == PairState.Entangled, "QET: Pair not entangled");
        _;
    }

    modifier whenDisentangled(uint256 pairId) {
        require(_pairState[pairId] == PairState.Disentangled, "QET: Pair not disentangled");
        _;
    }

    modifier whenAlphaSplitNotClaimed(uint256 pairId) {
        require(!_alphaSplitClaimed[pairId], "QET: Alpha split already claimed");
        _;
    }

     modifier whenBetaSplitNotClaimed(uint256 pairId) {
        require(!_betaSplitClaimed[pairId], "QET: Beta split already claimed");
        _;
    }

    modifier onlyPairOwnerOrApproved(uint256 pairId) {
        require(_isApprovedOrOwner(_msgSender(), pairId), "QET: Not owner or approved");
        _;
    }

    // --- Constructor ---

    constructor(uint256 initialEntanglementDuration) Ownable(msg.sender) {
        _entanglementDuration = initialEntanglementDuration;
    }

    // --- Core Functions (State Management & Transfers) ---

    /**
     * @dev Mints a new Quantum Pair in the Entangled state.
     * @param recipient The address to receive the new pair.
     */
    function mintPair(address recipient) external onlyOwner {
        uint256 newPairId = ++_totalMintedPairs;
        require(recipient != address(0), "QET: mint to the zero address");

        _safeMint(recipient, newPairId);
        _updatePairState(newPairId, PairState.Entangled);
        _lastEntanglementTime[newPairId] = block.timestamp;
        _decayPreventionUntil[newPairId] = 0; // No prevention initially
        _alphaSplitClaimed[newPairId] = false;
        _betaSplitClaimed[newPairId] = false;
        _quantumVolatility[newPairId] = 100; // Initial volatility example

        _allPairs.push(newPairId); // Potentially gas heavy for large number of tokens
        _ownedPairs[recipient].push(newPairId); // Potentially gas heavy

        emit PairMinted(newPairId, recipient);
    }

    /**
     * @dev Transfers ownership of a specific pair from one address to another.
     * Follows ERC-721 transferFrom pattern.
     * @param from The address currently owning the pair.
     * @param to The address to transfer the pair to.
     * @param pairId The ID of the pair to transfer.
     */
    function transferFrom(address from, address to, uint256 pairId) public onlyPairOwnerOrApproved(pairId) {
        require(_pairOwner[pairId] == from, "QET: transfer from incorrect owner");
        require(to != address(0), "QET: transfer to the zero address");

        _transfer(from, to, pairId);
    }

    /**
     * @dev Safely transfers ownership of a specific pair from one address to another.
     * Follows ERC-721 safeTransferFrom pattern, checking recipient's ability to receive.
     * @param from The address currently owning the pair.
     * @param to The address to transfer the pair to.
     * @param pairId The ID of the pair to transfer.
     */
    function safeTransferFrom(address from, address to, uint256 pairId) public onlyPairOwnerOrApproved(pairId) {
        require(_pairOwner[pairId] == from, "QET: transfer from incorrect owner");
        require(to != address(0), "QET: transfer to the zero address");

        _safeTransfer(from, to, pairId, "");
    }

    /**
     * @dev Safely transfers ownership of a specific pair from one address to another, with data.
     * Follows ERC-721 safeTransferFrom pattern with data.
     * @param from The address currently owning the pair.
     * @param to The address to transfer the pair to.
     * @param pairId The ID of the pair to transfer.
     * @param data Additional data to send.
     */
    function safeTransferFrom(address from, address to, uint256 pairId, bytes calldata data) public onlyPairOwnerOrApproved(pairId) {
         require(_pairOwner[pairId] == from, "QET: transfer from incorrect owner");
        require(to != address(0), "QET: transfer to the zero address");

        _safeTransfer(from, to, pairId, data);
    }

    /**
     * @dev Approves another address to manage a specific pair.
     * Follows ERC-721 approve pattern.
     * @param to The address to approve.
     * @param pairId The ID of the pair to approve.
     */
    function approve(address to, uint256 pairId) public onlyPairOwnerOrApproved(pairId) {
        _pairApproval[pairId] = to;
        emit Approval(_pairOwner[pairId], to, pairId);
    }

    /**
     * @dev Sets or unsets approval for a third party to manage all pairs owned by _msgSender().
     * Follows ERC-721 setApprovalForAll pattern.
     * @param operator The address to approve or revoke.
     * @param approved True to approve, false to revoke.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != _msgSender(), "QET: Approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Changes the state of a pair from Entangled to Disentangled.
     * Resets the alpha/beta split claimed flags.
     * @param pairId The ID of the pair to disentangle.
     */
    function disentanglePair(uint256 pairId) public onlyPairOwnerOrApproved(pairId) whenEntangled(pairId) {
        _updatePairState(pairId, PairState.Disentangled);
        _alphaSplitClaimed[pairId] = false; // Reset split claims upon disentanglement
        _betaSplitClaimed[pairId] = false;
        // Decay prevention expires upon disentanglement
        _decayPreventionUntil[pairId] = 0;
    }

    /**
     * @dev Changes the state of a pair from Disentangled to Entangled.
     * Records the timestamp of re-entanglement for potential future decay.
     * @param pairId The ID of the pair to re-entangle.
     */
    function reEntanglePair(uint256 pairId) public onlyPairOwnerOrApproved(pairId) whenDisentangled(pairId) {
        _updatePairState(pairId, PairState.Entangled);
        _lastEntanglementTime[pairId] = block.timestamp;
        _decayPreventionUntil[pairId] = 0; // Prevention ends on re-entanglement
    }

    // --- Conditional & State-Dependent Actions ---

    /**
     * @dev Performs an action associated with the Alpha side of a pair.
     * Only possible when the pair is Disentangled and the Alpha split hasn't been claimed
     * in the current disentangled phase.
     * @param pairId The ID of the pair.
     */
    function splitAlpha(uint256 pairId) public onlyPairOwnerOrApproved(pairId) whenDisentangled(pairId) whenAlphaSplitNotClaimed(pairId) {
        _alphaSplitClaimed[pairId] = true;
        // ### Insert Alpha-specific logic here ###
        // This could involve:
        // - Minting a separate ERC-20/ERC-1155 token
        // - Triggering interaction with another contract
        // - Unlocking specific data associated with this pair
        // - Adjusting internal state/attributes
        // - etc.
        // For this example, we just emit an event and mark as claimed.
        emit AlphaSplitClaimed(pairId, _pairOwner[pairId]);
        updateVolatilityBasedOnState(pairId); // Example: splitting changes volatility
    }

     /**
     * @dev Performs an action associated with the Beta side of a pair.
     * Only possible when the pair is Disentangled and the Beta split hasn't been claimed
     * in the current disentangled phase.
     * @param pairId The ID of the pair.
     */
    function splitBeta(uint256 pairId) public onlyPairOwnerOrApproved(pairId) whenDisentangled(pairId) whenBetaSplitNotClaimed(pairId) {
        _betaSplitClaimed[pairId] = true;
        // ### Insert Beta-specific logic here ###
        // Similar possibilities as splitAlpha, but representing the Beta side.
        // Could be a different token, different contract interaction, etc.
        emit BetaSplitClaimed(pairId, _pairOwner[pairId]);
         updateVolatilityBasedOnState(pairId); // Example: splitting changes volatility
    }

    /**
     * @dev Allows anyone to trigger a check for entanglement decay.
     * If enough time has passed since the last entanglement and decay prevention
     * is not active, the pair's state is changed to Disentangled.
     * @param pairId The ID of the pair to check.
     */
    function decayEntanglement(uint256 pairId) public {
        require(_pairOwner[pairId] != address(0), "QET: Pair does not exist");
        if (_pairState[pairId] == PairState.Entangled &&
            block.timestamp >= _lastEntanglementTime[pairId] + _entanglementDuration &&
            block.timestamp > _decayPreventionUntil[pairId]) {
            // Decay occurs
            _updatePairState(pairId, PairState.Disentangled);
            _alphaSplitClaimed[pairId] = false; // Reset split claims upon decay
            _betaSplitClaimed[pairId] = false;
            emit EntanglementDecayed(pairId, _pairOwner[pairId]);
            updateVolatilityBasedOnState(pairId); // Example: decay changes volatility
        }
    }

    /**
     * @dev Allows the owner or approved address to prevent entanglement decay
     * for a period by paying a fee.
     * @param pairId The ID of the pair to prevent decay for.
     * @param durationToPrevent Additional time in seconds to prevent decay.
     */
    function preventDecay(uint256 pairId, uint256 durationToPrevent) public payable onlyPairOwnerOrApproved(pairId) {
        // ### Fee Logic Example ###
        // This is a simple example where ETH is sent to the contract owner.
        // More complex fee structures (e.g., ERC-20, burning) could be implemented.
        uint256 requiredFee = durationToPrevent * 1 wei; // Example: 1 wei per second of prevention
        require(msg.value >= requiredFee, "QET: Insufficient fee to prevent decay");

        // Extend prevention time from *current* prevention end or now, whichever is later
        uint256 currentPreventionEnd = _decayPreventionUntil[pairId];
        if (currentPreventionEnd < block.timestamp) {
            currentPreventionEnd = block.timestamp;
        }
        _decayPreventionUntil[pairId] = currentPreventionEnd + durationToPrevent;

        // Send collected fee to the owner
        if (msg.value > 0) {
             (bool success,) = payable(owner()).call{value: msg.value}("");
             require(success, "QET: Fee withdrawal failed");
        }

        emit EntanglementDecayPrevented(pairId, _pairOwner[pairId], durationToPrevent);
    }

     /**
     * @dev Attempts to re-entangle a pair, potentially requiring off-chain validation or proof.
     * This function simulates a scenario where re-entanglement is not simply a button click,
     * but might depend on external factors or complex calculations/proofs.
     * @param pairId The ID of the pair.
     * @param complexProof A placeholder for off-chain data/proof needed for re-entanglement.
     * (Real implementation would involve oracle checks, zero-knowledge proofs, etc.)
     */
    function attemptReEntangle(uint256 pairId, bytes calldata complexProof) public onlyPairOwnerOrApproved(pairId) whenDisentangled(pairId) {
        // ### Simulate Complex Re-Entanglement Logic ###
        // This could involve:
        // - Verifying 'complexProof' against on-chain state or a known root hash.
        // - Requiring specific conditions based on time, other pair states, or global contract state.
        // - Interaction with an oracle contract to fetch external data.
        // - A probabilistic chance of success based on proof complexity or state.
        // For this example, we'll just check if the proof isn't empty as a minimal condition.
        require(complexProof.length > 0, "QET: Complex proof is required");

        // If proof is valid (simulated), proceed with re-entanglement
        _updatePairState(pairId, PairState.Entangled);
        _lastEntanglementTime[pairId] = block.timestamp;
        _decayPreventionUntil[pairId] = 0; // Prevention ends on re-entanglement

        // Example: Re-entangling based on proof might affect volatility differently
        _quantumVolatility[pairId] = _quantumVolatility[pairId] * 2 / 3; // Example: Reduce volatility
        emit VolatilityUpdated(pairId, _quantumVolatility[pairId]);
    }

    /**
     * @dev Updates the _quantumVolatility attribute based on the pair's state.
     * This is an example function showing state-dependent attributes.
     * Can be called by the owner or triggered by other functions (e.g., state changes).
     * @param pairId The ID of the pair.
     */
    function updateVolatilityBasedOnState(uint256 pairId) public onlyPairOwnerOrApproved(pairId) {
        uint256 currentVolatility = _quantumVolatility[pairId];
        uint256 newVolatility;

        if (_pairState[pairId] == PairState.Entangled) {
            // Volatility decreases when entangled (stable state)
            newVolatility = currentVolatility * 9 / 10;
        } else {
            // Volatility increases when disentangled (unstable state)
             newVolatility = currentVolatility * 11 / 10;
        }

        // Prevent volatility from going too low or too high (example bounds)
        if (newVolatility < 10) newVolatility = 10;
        if (newVolatility > 500) newVolatility = 500;

        if (newVolatility != currentVolatility) {
             _quantumVolatility[pairId] = newVolatility;
             emit VolatilityUpdated(pairId, newVolatility);
        }
    }


    // --- Batch Operations (Utility) ---

    /**
     * @dev Transfers multiple pairs to corresponding recipients.
     * Requires caller is owner or approved for each pair.
     * @param recipients Array of recipient addresses.
     * @param pairIds Array of pair IDs to transfer.
     */
    function batchTransferPairs(address[] memory recipients, uint256[] memory pairIds) public {
        require(recipients.length == pairIds.length, "QET: Mismatched array lengths");
        for (uint i = 0; i < pairIds.length; i++) {
            // Use safeTransferFrom for best practice
            safeTransferFrom(_msgSender(), recipients[i], pairIds[i]);
        }
    }

     /**
     * @dev Disentangles multiple pairs.
     * Requires caller is owner or approved for each pair.
     * @param pairIds Array of pair IDs to disentangle.
     */
    function batchDisentangle(uint256[] memory pairIds) public {
        for (uint i = 0; i < pairIds.length; i++) {
            disentanglePair(pairIds[i]);
        }
    }

     /**
     * @dev Re-entangles multiple pairs.
     * Requires caller is owner or approved for each pair.
     * @param pairIds Array of pair IDs to re-entangle.
     */
    function batchReEntangle(uint256[] memory pairIds) public {
        for (uint i = 0; i < pairIds.length; i++) {
            reEntanglePair(pairIds[i]);
        }
    }


    // --- Query Functions (View/Pure) ---

    /**
     * @dev Returns the owner of the pair.
     * @param pairId The ID of the pair.
     */
    function ownerOf(uint256 pairId) public view returns (address) {
        address owner = _pairOwner[pairId];
        require(owner != address(0), "QET: owner query for nonexistent pair");
        return owner;
    }

    /**
     * @dev Returns the approved address for a single pair.
     * @param pairId The ID of the pair.
     */
    function getApproved(uint256 pairId) public view returns (address) {
        require(_pairOwner[pairId] != address(0), "QET: approved query for nonexistent pair");
        return _pairApproval[pairId];
    }

    /**
     * @dev Returns true if the operator is approved for all pairs owned by owner.
     * @param owner The address of the owner.
     * @param operator The address of the operator.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns the current state of a pair.
     * @param pairId The ID of the pair.
     */
    function getPairState(uint256 pairId) public view returns (PairState) {
         require(_pairOwner[pairId] != address(0), "QET: state query for nonexistent pair");
        return _pairState[pairId];
    }

    /**
     * @dev Checks if a pair is currently Entangled.
     * @param pairId The ID of the pair.
     */
    function isEntangled(uint256 pairId) public view returns (bool) {
         require(_pairOwner[pairId] != address(0), "QET: exists query for nonexistent pair");
        return _pairState[pairId] == PairState.Entangled;
    }

    /**
     * @dev Checks if a pair is currently Disentangled.
     * @param pairId The ID of the pair.
     */
    function isDisentangled(uint256 pairId) public view returns (bool) {
         require(_pairOwner[pairId] != address(0), "QET: exists query for nonexistent pair");
        return _pairState[pairId] == PairState.Disentangled;
    }

     /**
     * @dev Returns the timestamp of the pair's last entanglement.
     * @param pairId The ID of the pair.
     */
    function getLastEntanglementTime(uint256 pairId) public view returns (uint256) {
         require(_pairOwner[pairId] != address(0), "QET: query for nonexistent pair");
        return _lastEntanglementTime[pairId];
    }

     /**
     * @dev Returns the timestamp until which entanglement decay is prevented for the pair.
     * @param pairId The ID of the pair.
     */
    function getDecayPreventionUntil(uint256 pairId) public view returns (uint256) {
         require(_pairOwner[pairId] != address(0), "QET: query for nonexistent pair");
        return _decayPreventionUntil[pairId];
    }

    /**
     * @dev Checks if the Alpha split action has been claimed in the current disentangled phase.
     * @param pairId The ID of the pair.
     */
    function getAlphaSplitClaimed(uint256 pairId) public view returns (bool) {
         require(_pairOwner[pairId] != address(0), "QET: query for nonexistent pair");
        return _alphaSplitClaimed[pairId];
    }

     /**
     * @dev Checks if the Beta split action has been claimed in the current disentangled phase.
     * @param pairId The ID of the pair.
     */
    function getBetaSplitClaimed(uint256 pairId) public view returns (bool) {
         require(_pairOwner[pairId] != address(0), "QET: query for nonexistent pair");
        return _betaSplitClaimed[pairId];
    }

    /**
     * @dev Returns the current quantum volatility attribute value for a pair.
     * @param pairId The ID of the pair.
     */
    function getQuantumVolatility(uint256 pairId) public view returns (uint256) {
         require(_pairOwner[pairId] != address(0), "QET: query for nonexistent pair");
        return _quantumVolatility[pairId];
    }


    /**
     * @dev Returns the total number of pairs ever minted.
     */
    function getTotalSupply() public view returns (uint256) {
        return _totalMintedPairs;
    }

     /**
     * @dev Returns the total number of pairs currently in the Entangled state.
     */
    function getEntangledPairCount() public view returns (uint256) {
        return _totalEntangledPairs;
    }

     /**
     * @dev Returns the total number of pairs currently in the Disentangled state.
     */
    function getDisentangledPairCount() public view returns (uint256) {
        return _totalDisentangledPairs;
    }

    /**
     * @dev Returns the metadata URI for a given pair ID.
     * Appends state information to the base URI.
     * @param pairId The ID of the pair.
     */
    function tokenURI(uint256 pairId) public view returns (string memory) {
         require(_pairOwner[pairId] != address(0), "QET: URI query for nonexistent pair");

        string memory stateAppendix;
        if (_pairState[pairId] == PairState.Entangled) {
            stateAppendix = "entangled.json";
        } else {
            stateAppendix = "disentangled.json";
        }

        if (bytes(_baseURI).length == 0) {
            return stateAppendix;
        }
        // Using abi.encodePacked is gas-efficient for string concatenation
        return string(abi.encodePacked(_baseURI, stateAppendix));
    }

    /**
     * @dev Returns the base URI for token metadata.
     */
    function getBaseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Returns the configured duration after which entanglement can decay.
     */
    function getEntanglementDuration() public view returns (uint256) {
        return _entanglementDuration;
    }

    /**
     * @dev Retrieves the list of pair IDs owned by a specific address.
     * NOTE: This function can be gas-intensive if an address owns many pairs.
     * @param owner The address to query.
     * @return An array of pair IDs owned by the address.
     */
    function getPairsOwnedBy(address owner) public view returns (uint256[] memory) {
        // A more efficient implementation for large numbers would be needed in production,
        // potentially involving pagination or external indexing.
        return _ownedPairs[owner];
    }

    // --- Admin/Configuration Functions (Ownable) ---

    /**
     * @dev Sets the base URI for token metadata.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
    }

     /**
     * @dev Sets the duration after which entanglement can potentially decay.
     * @param duration The new duration in seconds.
     */
    function setEntanglementDuration(uint256 duration) public onlyOwner {
        _entanglementDuration = duration;
    }

     /**
     * @dev Allows the contract owner to withdraw any Ether collected from fees (e.g., from preventDecay).
     */
    function withdrawFees() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "QET: Ether withdrawal failed");
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Checks if `spender` is owner or approved for `pairId`.
     */
    function _isApprovedOrOwner(address spender, uint256 pairId) internal view returns (bool) {
        address owner = ownerOf(pairId);
        return (spender == owner ||
                getApproved(pairId) == spender ||
                isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal mint function.
     */
    function _safeMint(address to, uint256 pairId) internal {
        require(_pairOwner[pairId] == address(0), "QET: pair already minted");
        _pairOwner[pairId] = to;
         // State and time are set in mintPair caller

        // ERC721Receiver check skipped for brevity but would be needed for full compatibility
    }

    /**
     * @dev Internal transfer function.
     */
    function _transfer(address from, address to, uint256 pairId) internal {
        require(_pairOwner[pairId] == from, "QET: transfer of pair not owned by from");
        require(to != address(0), "QET: transfer to the zero address");

        // Clear approvals for the transferring pair
        _pairApproval[pairId] = address(0);

        // Update owner mapping
        _pairOwner[pairId] = to;

        // Update ownedPairs array (simple append/remove, inefficient for large numbers)
        _removePairFromOwnedList(from, pairId);
        _ownedPairs[to].push(pairId);


        emit PairTransferred(from, to, pairId);

        // Note: State (Entangled/Disentangled) persists across transfers.
        // Time-based decay continues from the original lastEntanglementTime.
    }

    /**
     * @dev Internal safe transfer function with ERC-721Receiver check.
     */
    function _safeTransfer(address from, address to, uint256 pairId, bytes memory data) internal {
        _transfer(from, to, pairId);
        require(_checkOnERC721Received(from, to, pairId, data), "QET: ERC721Receiver rejected transfer");
    }

     /**
      * @dev Internal helper to call onERC721Received on a recipient address.
      * Based on OpenZeppelin's implementation logic.
      */
    function _checkOnERC721Received(address from, address to, uint256 pairId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, pairId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                 if (reason.length > 0) {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                } else {
                    revert("QET: Transfer to non ERC721Receiver implementer");
                }
            }
        } else {
            return true; // Transfer to EOA is always safe
        }
    }


    /**
     * @dev Internal function to update pair state and associated counters.
     */
    function _updatePairState(uint256 pairId, PairState newState) internal {
         require(_pairOwner[pairId] != address(0), "QET: state change for nonexistent pair");

        PairState oldState = _pairState[pairId];
        if (oldState != newState) {
            _pairState[pairId] = newState;

            // Update counters
            if (newState == PairState.Entangled) {
                _totalEntangledPairs++;
                if (oldState == PairState.Disentangled) {
                    _totalDisentangledPairs--;
                }
            } else { // newState == PairState.Disentangled
                _totalDisentangledPairs++;
                 if (oldState == PairState.Entangled) {
                    _totalEntangledPairs--;
                }
            }

            emit PairStateChanged(pairId, oldState, newState);
        }
    }

    /**
     * @dev Helper to remove a pair ID from an address's owned list.
     * NOTE: This is potentially gas-intensive as it involves shifting array elements.
     */
    function _removePairFromOwnedList(address owner, uint256 pairId) internal {
        uint256[] storage owned = _ownedPairs[owner];
        for (uint256 i = 0; i < owned.length; i++) {
            if (owned[i] == pairId) {
                // Replace the element to remove with the last element
                owned[i] = owned[owned.length - 1];
                // Pop the last element
                owned.pop();
                return;
            }
        }
         // Should not happen if pairId is actually owned by the address
    }


    // --- Receive/Fallback (Optional but good practice if expecting ETH) ---
    receive() external payable {}
    fallback() external payable {}
}
```