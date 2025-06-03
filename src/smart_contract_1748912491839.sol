Okay, let's design an advanced, creative, and non-standard smart contract. How about something that combines elements of resource management, time-locked mechanics, dynamic NFTs with on-chain traits, and a user reputation system?

Let's call it the "Chrono-Synthesizer Protocol". Users lock a specific ERC-20 resource token ("Resonance Crystals") and wait for a duration to "Synthesize" unique ERC-721 artifacts ("Synthesized Artifacts"). The traits of the resulting artifact are determined dynamically based on factors like the amount of resources used, the exact time of completion, and the user's reputation. There's also a mechanism to refine or dismantle existing artifacts, influencing the user's reputation.

This incorporates:
1.  **Custom Tokenomics:** Using a specific ERC-20 resource.
2.  **Time-Locked Mechanics:** Requires waiting for synthesis.
3.  **Dynamic NFTs:** Traits calculated and stored on-chain, changing potentially (though refinement is the primary change mechanic here).
4.  **On-Chain Traits:** Storing NFT metadata properties directly in the contract state.
5.  **Reputation System:** A non-transferable score affecting outcomes.
6.  **Resource Sink/Faucet:** Burning resources for synthesis, potentially gaining some back from dismantling.
7.  **Protocol Parameters:** Configurable costs, durations, trait ranges by owner.

We will implement simplified ERC-20 and ERC-721 logic *within* this contract for the custom tokens, ensuring the overall contract logic is unique, even if standard interfaces are followed for token compatibility.

---

### Chrono-Synthesizer Protocol Contract Outline & Function Summary

**Contract Name:** `ChronoSynthesizerProtocol`

**Purpose:** A decentralized protocol allowing users to synthesize unique digital artifacts (NFTs) by committing resources (ERC-20 tokens) and waiting a specific duration. The resulting artifacts have dynamic, on-chain traits influenced by the process and user reputation. Includes resource management, artifact refinement/dismantling, and a user reputation system.

**Key Concepts:**
*   **Resonance Crystal (RC):** Custom ERC-20 token required for synthesis and refinement.
*   **Synthesized Artifact (SA):** Custom ERC-721 token representing unique digital artifacts with on-chain traits.
*   **Synthesis:** The process of locking RC tokens for a period to mint a new SA.
*   **Refinement:** Using RC tokens to modify/improve traits of an existing SA.
*   **Dismantling:** Burning an SA to recover a portion of RC tokens and affect reputation.
*   **Reputation:** A non-transferable score for users, influencing synthesis outcomes and unlockable actions.
*   **Dynamic Traits:** SA traits stored and potentially modified on-chain.

**Function Categories & Summary:**

1.  **Ownership & Control (Admin/Owner Functions):**
    *   `constructor`: Initializes contract owner and potentially mints initial RC supply.
    *   `setSynthParameters`: Sets the cost (RC amount) and duration (time) for synthesis.
    *   `setRefinementParameters`: Sets the cost (RC amount) and effect range for artifact refinement.
    *   `setTraitGenerationParams`: Sets parameters influencing how artifact traits are calculated during synthesis/refinement.
    *   `setReputationLevelThresholds`: Configures reputation score thresholds for different levels/benefits.
    *   `pauseSynthesis`: Pauses the `startSynthesis` function (prevents new synthesis).
    *   `unpauseSynthesis`: Unpauses synthesis.
    *   `emergencyOwnerWithdrawERC20`: Allows owner to withdraw accidentally sent ERC-20 tokens.
    *   `emergencyOwnerWithdrawETH`: Allows owner to withdraw accidentally sent ETH.

2.  **Resonance Crystal (RC) Token (Simplified ERC-20):**
    *   `nameRC`: Returns the name of the RC token.
    *   `symbolRC`: Returns the symbol of the RC token.
    *   `decimalsRC`: Returns the decimals of the RC token.
    *   `totalSupplyRC`: Returns the total supply of RC tokens.
    *   `balanceOfRC`: Returns the RC balance of an address.
    *   `transferRC`: Transfers RC tokens from sender to another address.
    *   `approveRC`: Approves an address to spend RC tokens on sender's behalf.
    *   `allowanceRC`: Returns the amount an address is approved to spend for another.
    *   `transferFromRC`: Transfers RC tokens using an allowance.
    *   `mintRC`: Mints new RC tokens (controlled logic, e.g., owner or specific game mechanics). *Implemented as internal `_mintRC`, exposed via controlled means if needed, or only in constructor.*
    *   `burnRC`: Burns RC tokens from sender's balance. *Implemented as internal `_burnRC`, exposed via `dismantleArtifact` etc.*

3.  **Synthesized Artifact (SA) Token (Simplified ERC-721):**
    *   `nameSA`: Returns the name of the SA token.
    *   `symbolSA`: Returns the symbol of the SA token.
    *   `balanceOfSA`: Returns the number of SAs owned by an address.
    *   `ownerOfSA`: Returns the owner of a specific SA token.
    *   `getApprovedSA`: Returns the approved address for a single SA token.
    *   `setApprovalForAllSA`: Sets approval for an operator for all of sender's SAs.
    *   `isApprovedForAllSA`: Checks if an operator is approved for all of owner's SAs.
    *   `approveSA`: Approves another address to transfer a specific SA.
    *   `transferFromSA`: Transfers an SA token.
    *   `safeTransferFromSA`: Safely transfers an SA token.
    *   `tokenURISSA`: Returns the metadata URI for an SA token (placeholder implementation).
    *   `_safeMintSA`: Mints a new SA token (internal helper).
    *   `_burnSA`: Burns an SA token (internal helper).

4.  **Core Synthesis Logic:**
    *   `startSynthesis`: Locks required RC tokens and initiates a synthesis process for the caller.
    *   `completeSynthesis`: Allows the caller to finalize a pending synthesis after the duration, minting an SA with calculated traits.
    *   `cancelSynthesis`: Allows the caller to cancel a pending synthesis before completion, potentially receiving a partial RC refund.

5.  **Artifact Interaction Logic:**
    *   `refineArtifact`: Allows an SA owner to use RC tokens to potentially modify/improve the traits of a specific SA.
    *   `dismantleArtifact`: Allows an SA owner to burn an SA token in exchange for a portion of RC tokens and an update to their reputation.

6.  **Reputation System:**
    *   `getUserReputation`: Returns the current reputation score for a user.
    *   `burnArtifactForReputation`: Allows burning an SA specifically for a significant reputation boost, without RC refund.
    *   `_updateReputation`: Internal function to modify a user's reputation score based on protocol actions.

7.  **Query & Utility Functions (View/Pure):**
    *   `getSynthParameters`: Returns the current synthesis cost and duration.
    *   `getRefinementParameters`: Returns the current refinement cost and trait effect range.
    *   `getTraitGenerationParams`: Returns parameters used for trait calculation.
    *   `getReputationLevelThresholds`: Returns the configured reputation thresholds.
    *   `getArtifactTraits`: Returns the dynamic traits for a specific SA token.
    *   `getPendingSynthesis`: Returns the state (start time, resources, etc.) of a user's pending synthesis.
    *   `getTotalArtifactsMintedSA`: Returns the total number of SAs minted.
    *   `supportsInterface`: Standard ERC165 function to indicate supported interfaces.
    *   `getChronoSynthesizerProtocolVersion`: Returns a version identifier for the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Chrono-Synthesizer Protocol Outline & Function Summary ---
//
// Contract Name: ChronoSynthesizerProtocol
// Purpose: A decentralized protocol for synthesizing unique digital artifacts (NFTs)
//          by committing resources (ERC-20 tokens) and waiting a specific duration.
//          Features custom tokens (RC & SA), time-locked synthesis, dynamic on-chain
//          NFT traits, artifact refinement/dismantling, and a user reputation system.
//
// Key Concepts:
//   - Resonance Crystal (RC): Custom ERC-20 resource token.
//   - Synthesized Artifact (SA): Custom ERC-721 unique artifact token with on-chain traits.
//   - Synthesis: Process of locking RC for a duration to mint a new SA.
//   - Refinement: Using RC to modify traits of an existing SA.
//   - Dismantling: Burning an SA for RC recovery and reputation change.
//   - Reputation: Non-transferable score influencing outcomes.
//   - Dynamic Traits: SA traits stored and potentially modified on-chain.
//
// Function Categories & Summary:
// 1. Ownership & Control (Admin/Owner):
//    - constructor: Initialize owner, set initial params.
//    - setSynthParameters: Set synthesis cost & duration.
//    - setRefinementParameters: Set refinement cost & effect.
//    - setTraitGenerationParams: Set trait calculation parameters.
//    - setReputationLevelThresholds: Set reputation tier thresholds.
//    - pauseSynthesis: Prevent new synthesis starts.
//    - unpauseSynthesis: Resume synthesis starts.
//    - emergencyOwnerWithdrawERC20: Withdraw any ERC-20 sent here.
//    - emergencyOwnerWithdrawETH: Withdraw ETH sent here.
// 2. Resonance Crystal (RC) Token (Simplified ERC-20):
//    - nameRC, symbolRC, decimalsRC, totalSupplyRC, balanceOfRC, transferRC,
//      approveRC, allowanceRC, transferFromRC, burnRC. (Includes internal helpers).
// 3. Synthesized Artifact (SA) Token (Simplified ERC-721):
//    - nameSA, symbolSA, balanceOfSA, ownerOfSA, getApprovedSA, setApprovalForAllSA,
//      isApprovedForAllSA, approveSA, transferFromSA, safeTransferFromSA, tokenURISSA.
//      (Includes internal helpers).
// 4. Core Synthesis Logic:
//    - startSynthesis: Initiate a synthesis process.
//    - completeSynthesis: Finalize synthesis, mint SA.
//    - cancelSynthesis: Cancel synthesis, partial RC refund.
// 5. Artifact Interaction Logic:
//    - refineArtifact: Modify SA traits using RC.
//    - dismantleArtifact: Burn SA for RC and reputation change.
// 6. Reputation System:
//    - getUserReputation: Get user's reputation score.
//    - burnArtifactForReputation: Burn SA for reputation boost.
//    - _updateReputation: Internal helper to change reputation.
// 7. Query & Utility (View/Pure):
//    - getSynthParameters, getRefinementParameters, getTraitGenerationParams,
//      getReputationLevelThresholds, getArtifactTraits, getPendingSynthesis,
//      getTotalArtifactsMintedSA, supportsInterface, getChronoSynthesizerProtocolVersion.
//
// Note: This contract implements simplified token standards internally for demonstration.
//       Production use might integrate with separate, fully-featured ERC-20/ERC-721 contracts.

import "./IERC165.sol"; // Assuming IERC165 is available

// Basic Ownable implementation
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Basic Pausable implementation
contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function pauseSynthesis() public onlyOwner whenNotPaused virtual {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseSynthesis() public onlyOwner whenPaused virtual {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


contract ChronoSynthesizerProtocol is Ownable, Pausable, IERC165 {

    // --- Custom Errors ---
    error NotEnoughResonanceCrystals(uint256 required, uint256 has);
    error SynthesisAlreadyInProgress();
    error NoSynthesisInProgress();
    error SynthesisNotCompleteYet(uint256 completeTime);
    error ArtifactDoesNotExist(uint256 tokenId);
    error NotArtifactOwner(uint256 tokenId);
    error NotApprovedOrOwner(uint256 tokenId, address spender);
    error RefinementNotPossible(uint256 tokenId); // e.g., already max traits
    error InvalidTraitValue(uint8 traitIndex, int256 value);
    error InvalidParameters();
    error NothingToWithdraw();
    error NoETHReceived();


    // --- Events ---
    event ResonanceCrystalMinted(address indexed account, uint256 amount);
    event ResonanceCrystalBurnt(address indexed account, uint256 amount);
    event SynthesisStarted(address indexed user, uint256 requiredCrystals, uint256 completeTime);
    event SynthesisCompleted(address indexed user, uint256 newTokenId, uint256 crystalsUsed);
    event SynthesisCancelled(address indexed user, uint256 refundedCrystals);
    event ArtifactMinted(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
    event ArtifactTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event ArtifactBurnt(address indexed owner, uint256 indexed tokenId);
    event ArtifactRefined(uint256 indexed tokenId, uint256 crystalsUsed, int256[] traitChanges);
    event ArtifactDismantled(uint256 indexed tokenId, uint256 refundedCrystals, address indexed user);
    event UserReputationUpdated(address indexed user, uint256 newReputation);
    event SynthParametersUpdated(uint256 newCostRC, uint256 newDurationSeconds);
    event RefinementParametersUpdated(uint256 newCostRC, int256 minEffect, int256 maxEffect);
    event TraitGenerationParametersUpdated(uint8 baseValue, uint8 timeInfluence, uint8 resourceInfluence, uint8 reputationInfluence);

    // --- State Variables ---

    // RC Token State (Simplified ERC-20)
    string public constant nameRC = "Resonance Crystal";
    string public constant symbolRC = "RC";
    uint8 public constant decimalsRC = 18;
    uint256 private _totalSupplyRC;
    mapping(address => uint256) private _balancesRC;
    mapping(address => mapping(address => uint256)) private _allowancesRC;

    // SA Token State (Simplified ERC-721)
    string public constant nameSA = "Synthesized Artifact";
    string public constant symbolSA = "SA";
    uint256 private _nextTokenIdSA;
    mapping(uint256 => address) private _ownersSA;
    mapping(address => uint256) private _balancesSA;
    mapping(uint256 => address) private _tokenApprovalsSA;
    mapping(address => mapping(address => bool)) private _operatorApprovalsSA;

    // Artifact Traits & Data
    struct ArtifactTraits {
        // Example traits (can be expanded)
        int256 harmony;   // affects how well it refines
        int256 stability; // affects dismantling refund
        int256 vitality;  // affects reputation gain from burning
        uint8 traitCount; // number of traits
    }
    mapping(uint256 => ArtifactTraits) public artifactTraits;

    // Synthesis State
    struct PendingSynthesis {
        uint256 startTime;
        uint256 crystalsLocked;
        bool active; // Is there an active synthesis?
    }
    mapping(address => PendingSynthesis) public pendingSyntheses;

    // User Reputation
    mapping(address => uint256) public userReputation; // Starts at 0

    // Protocol Parameters
    uint256 public synthesisCostRC;
    uint256 public synthesisDurationSeconds;
    uint256 public refinementCostRC;
    int256 public refinementMinTraitEffect; // Min/Max change per trait during refinement
    int256 public refinementMaxTraitEffect;

    // Trait Generation Parameters (Influence of factors on initial traits)
    struct TraitGenParams {
        uint8 baseValue; // Base value for traits (e.g., 50/100)
        uint8 timeInfluence; // % influence of duration waited vs min duration
        uint8 resourceInfluence; // % influence of resource amount vs min cost
        uint8 reputationInfluence; // % influence of user reputation
        // Total influence should ideally be 100%
    }
    TraitGenParams public traitGenerationParams;

    // Reputation Level Thresholds (Optional: for unlocking features/bonuses)
    // Example: reputation >= thresholds[i] means level i
    uint256[] public reputationLevelThresholds;

    // ERC165 Interface IDs
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd; // Subset supported


    // --- Constructor ---
    constructor(uint256 initialSupplyRC) Ownable() Pausable() {
        // Initialize ERC-20 RC
        _mintRC(msg.sender, initialSupplyRC);

        // Initialize ERC-721 SA
        _nextTokenIdSA = 1; // Token IDs start from 1

        // Set initial parameters (example values)
        synthesisCostRC = 100 * (10**uint256(decimalsRC)); // 100 RC
        synthesisDurationSeconds = 1 days; // 1 day
        refinementCostRC = 50 * (10**uint256(decimalsRC)); // 50 RC
        refinementMinTraitEffect = -10;
        refinementMaxTraitEffect = 20;

        traitGenerationParams = TraitGenParams({
            baseValue: 40,
            timeInfluence: 20, // 20% from time waited / duration
            resourceInfluence: 30, // 30% from resource amount / cost
            reputationInfluence: 10 // 10% from reputation / max_rep
        });

        // Example reputation thresholds
        reputationLevelThresholds = [0, 100, 500, 2000]; // Levels 0, 1, 2, 3+

        // Check initial parameters for sanity
        require(synthesisCostRC > 0 && synthesisDurationSeconds > 0, InvalidParameters());
        require(refinementCostRC > 0, InvalidParameters());
        require(traitGenerationParams.baseValue + traitGenerationParams.timeInfluence +
                traitGenerationParams.resourceInfluence + traitGenerationParams.reputationInfluence <= 100, InvalidParameters()); // Ensure influence sums reasonably
    }

    // --- RC Token Functions (Simplified ERC-20 subset) ---

    function totalSupplyRC() external view returns (uint256) {
        return _totalSupplyRC;
    }

    function balanceOfRC(address account) external view returns (uint256) {
        return _balancesRC[account];
    }

    function transferRC(address to, uint256 amount) external returns (bool) {
        _transferRC(msg.sender, to, amount);
        return true;
    }

    function approveRC(address spender, uint256 amount) external returns (bool) {
        _approveRC(msg.sender, spender, amount);
        return true;
    }

    function allowanceRC(address owner, address spender) external view returns (uint256) {
        return _allowancesRC[owner][spender];
    }

    function transferFromRC(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowancesRC[from][msg.sender];
        require(currentAllowance >= amount, NotEnoughResonanceCrystals(amount, currentAllowance));
        _transferRC(from, to, amount);
        _approveRC(from, msg.sender, currentAllowance - amount);
        return true;
    }

    function burnRC(uint256 amount) external {
        _burnRC(msg.sender, amount);
    }

    // Internal RC helpers
    function _transferRC(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balancesRC[from];
        require(fromBalance >= amount, NotEnoughResonanceCrystals(amount, fromBalance));
        unchecked {
            _balancesRC[from] = fromBalance - amount;
        }
        _balancesRC[to] += amount;
        emit transfer(from, to, amount); // ERC20 standard event
    }

    function _mintRC(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupplyRC += amount;
        _balancesRC[account] += amount;
        emit transfer(address(0), account, amount); // ERC20 standard mint event
        emit ResonanceCrystalMinted(account, amount);
    }

    function _burnRC(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balancesRC[account];
        require(accountBalance >= amount, NotEnoughResonanceCrystals(amount, accountBalance));
        unchecked {
            _balancesRC[account] = accountBalance - amount;
        }
        _totalSupplyRC -= amount;
        emit transfer(account, address(0), amount); // ERC20 standard burn event
        emit ResonanceCrystalBurnt(account, amount);
    }

    function _approveRC(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowancesRC[owner][spender] = amount;
        emit approval(owner, spender, amount); // ERC20 standard event
    }

    // Required ERC20 events (standard)
    event transfer(address indexed from, address indexed to, uint256 value);
    event approval(address indexed owner, address indexed spender, uint256 value);


    // --- SA Token Functions (Simplified ERC-721 subset) ---

    function nameSA() external view returns (string memory) {
        return nameSA;
    }

    function symbolSA() external view returns (string memory) {
        return symbolSA;
    }

    function balanceOfSA(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balancesSA[owner];
    }

    function ownerOfSA(uint256 tokenId) public view returns (address) {
        address owner = _ownersSA[tokenId];
        require(owner != address(0), ArtifactDoesNotExist(tokenId));
        return owner;
    }

    function getApprovedSA(uint256 tokenId) public view returns (address) {
        require(_existsSA(tokenId), ArtifactDoesNotExist(tokenId));
        return _tokenApprovalsSA[tokenId];
    }

    function setApprovalForAllSA(address operator, bool approved) external {
        _setApprovalForAllSA(msg.sender, operator, approved);
    }

    function isApprovedForAllSA(address owner, address operator) public view returns (bool) {
        return _operatorApprovalsSA[owner][operator];
    }

    function approveSA(address to, uint256 tokenId) external {
        address owner = ownerOfSA(tokenId);
        require(msg.sender == owner || isApprovedForAllSA(owner, msg.sender), NotApprovedOrOwner(tokenId, msg.sender));
        _approveSA(to, tokenId);
    }

    function transferFromSA(address from, address to, uint256 tokenId) external {
        //solidity-coverage next-line next-line
        require(_isApprovedOrOwnerSA(msg.sender, tokenId), NotApprovedOrOwner(tokenId, msg.sender));
        _transferSA(from, to, tokenId);
    }

    function safeTransferFromSA(address from, address to, uint256 tokenId) external {
        safeTransferFromSA(from, to, tokenId, "");
    }

    function safeTransferFromSA(address from, address to, uint256 tokenId, bytes memory data) public {
         require(_isApprovedOrOwnerSA(msg.sender, tokenId), NotApprovedOrOwner(tokenId, msg.sender));
         _safeTransferSA(from, to, tokenId, data);
    }

    function tokenURISSA(uint256 tokenId) public view virtual returns (string memory) {
        require(_existsSA(tokenId), ArtifactDoesNotExist(tokenId));
        // In a real app, this would return a URL pointing to off-chain metadata,
        // or construct a data URI with on-chain traits.
        // For this example, returning a placeholder or minimal data.
        // Example returning basic info:
        return string(abi.encodePacked("data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"', nameSA, ' #', Strings.toString(tokenId), '",',
                '"description":"A synthesized artifact.",',
                '"attributes":[',
                    '{"trait_type":"Harmony","value":', Strings.toString(artifactTraits[tokenId].harmony), '},',
                    '{"trait_type":"Stability","value":', Strings.toString(artifactTraits[tokenId].stability), '},',
                    '{"trait_type":"Vitality","value":', Strings.toString(artifactTraits[tokenId].vitality), '}',
                ']',
                '}'
            )))));
    }

    // Internal SA helpers
    function _existsSA(uint256 tokenId) internal view returns (bool) {
        return _ownersSA[tokenId] != address(0);
    }

    function _isApprovedOrOwnerSA(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOfSA(tokenId); // Will revert if token doesn't exist
        return (spender == owner || getApprovedSA(tokenId) == spender || isApprovedForAllSA(owner, spender));
    }

    function _approveSA(address to, uint256 tokenId) internal {
        _tokenApprovalsSA[tokenId] = to;
        emit Approval(ownerOfSA(tokenId), to, tokenId); // ERC721 standard event
    }

    function _setApprovalForAllSA(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovalsSA[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved); // ERC721 standard event
    }

    function _transferSA(address from, address to, uint256 tokenId) internal {
        require(ownerOfSA(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approveSA(address(0), tokenId); // Clear approval
        _balancesSA[from] -= 1;
        _balancesSA[to] += 1;
        _ownersSA[tokenId] = to;

        emit Transfer(from, to, tokenId); // ERC721 standard event
        emit ArtifactTransferred(from, to, tokenId);
    }

    function _safeTransferSA(address from, address to, uint256 tokenId, bytes memory data) internal {
         _transferSA(from, to, tokenId);
        require(
            _checkOnERC721Received(address(0), from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _safeMintSA(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_existsSA(tokenId), "ERC721: token already minted"); // Should not happen with _nextTokenIdSA

        _balancesSA[to] += 1;
        _ownersSA[tokenId] = to;

        emit Transfer(address(0), to, tokenId); // ERC721 standard mint event
        emit ArtifactMinted(to, tokenId, block.timestamp);
    }

    function _burnSA(uint256 tokenId) internal {
        address owner = ownerOfSA(tokenId); // Will revert if not exists

        _approveSA(address(0), tokenId); // Clear approval
        _balancesSA[owner] -= 1;
        delete _ownersSA[tokenId]; // Important to clear owner mapping

        // Delete traits to save gas for future lookups on burnt tokens
        delete artifactTraits[tokenId];

        emit Transfer(owner, address(0), tokenId); // ERC721 standard burn event
        emit ArtifactBurnt(owner, tokenId);
    }

    // Check receiver interface for safeTransfer
    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true; // EOA can receive
        }
    }

    // Required ERC721 events (standard)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // --- Core Synthesis Logic ---

    /**
     * @notice Initiates a synthesis process for the caller. Locks required RC tokens.
     * @dev Requires the caller to have sufficient RC balance and approve the contract.
     *      Only one synthesis can be active per user at a time.
     */
    function startSynthesis() external whenNotPaused {
        require(!pendingSyntheses[msg.sender].active, SynthesisAlreadyInProgress());
        require(_balancesRC[msg.sender] >= synthesisCostRC, NotEnoughResonanceCrystals(synthesisCostRC, _balancesRC[msg.sender]));
        // Assumes user has already called approve(address(this), synthesisCostRC) on this contract (if it were a separate RC token)
        // Since RC is internal, we just check balance and burn directly.
        // If RC was external, we would use transferFrom:
        // require(_allowancesRC[msg.sender][address(this)] >= synthesisCostRC, NotEnoughResonanceCrystals(synthesisCostRC, _allowancesRC[msg.sender][address(this)]));
        // _transferFromRC(msg.sender, address(this), synthesisCostRC); // Lock via transfer to contract

        // Burn the RC tokens immediately for this internal version
        _burnRC(msg.sender, synthesisCostRC);

        pendingSyntheses[msg.sender] = PendingSynthesis({
            startTime: block.timestamp,
            crystalsLocked: synthesisCostRC, // Keep track of amount used
            active: true
        });

        emit SynthesisStarted(msg.sender, synthesisCostRC, block.timestamp + synthesisDurationSeconds);
    }

    /**
     * @notice Completes a pending synthesis after the required duration has passed. Mints a new SA.
     * @dev Calculates dynamic traits based on factors like time elapsed, resources used, and reputation.
     */
    function completeSynthesis() external {
        PendingSynthesis storage pending = pendingSyntheses[msg.sender];
        require(pending.active, NoSynthesisInProgress());
        uint256 completeTime = pending.startTime + synthesisDurationSeconds;
        require(block.timestamp >= completeTime, SynthesisNotCompleteYet(completeTime));

        // --- Dynamic Trait Calculation ---
        // This is a simplified example. A more advanced version could use Chainlink VRF
        // for randomness, incorporate more complex algorithms, or external data.

        uint256 tokenId = _nextTokenIdSA++;

        // Basic pseudo-randomness based on block data and user address (predictable!)
        // For production, use Chainlink VRF or similar.
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, pending.crystalsLocked)));

        // Normalize input factors (simple linear example)
        // Time factor: How much longer than required duration was waited? (Clamped)
        uint256 timeWaited = block.timestamp - pending.startTime;
        uint256 clampedTimeFactor = timeWaited > synthesisDurationSeconds ? 100 : (timeWaited * 100) / synthesisDurationSeconds;

        // Resource factor: How many resources were locked vs base cost? (Clamped)
        // If only base cost is allowed, this factor is always 100.
        // If variable cost allowed: uint256 clampedResourceFactor = pending.crystalsLocked > synthesisCostRC ? 100 : (pending.crystalsLocked * 100) / synthesisCostRC;
        // For now, fixed cost:
        uint256 clampedResourceFactor = 100;


        // Reputation factor: Normalize reputation to a 0-100 scale (example: max rep assumed 1000)
        uint256 maxReputationAssumption = 1000; // Define a plausible max reputation scale
        uint256 clampedReputationFactor = userReputation[msg.sender] > maxReputationAssumption ? 100 : (userReputation[msg.sender] * 100) / maxReputationAssumption;

        // Calculate weighted influences (ensure sum is <= 100)
        uint256 timeInfluence = (clampedTimeFactor * traitGenerationParams.timeInfluence) / 100;
        uint256 resourceInfluence = (clampedResourceFactor * traitGenerationParams.resourceInfluence) / 100;
        uint256 reputationInfluence = (clampedReputationFactor * traitGenerationParams.reputationInfluence) / 100;
        uint256 baseInfluence = traitGenerationParams.baseValue;

        // Total weighted influence (capped at 100)
        uint256 totalInfluence = baseInfluence + timeInfluence + resourceInfluence + reputationInfluence;
        if (totalInfluence > 100) totalInfluence = 100; // Cap at 100

        // Generate initial trait values based on random seed and weighted influence
        // Traits are int256 for refinement flexibility
        ArtifactTraits memory newTraits;
        newTraits.traitCount = 3; // Fixed for this example

        // Simple PRNG based on randSeed
        function pseudoRandom(uint256 seed) pure returns (uint256) {
             return uint256(keccak256(abi.encodePacked(seed, block.timestamp, msg.sender)));
        }

        // Trait 1: Harmony (Influenced by Time + Reputation)
        uint256 harmonyRaw = (pseudoRandom(randSeed) % 101); // 0-100
        newTraits.harmony = int256((harmonyRaw * (timeInfluence + reputationInfluence)) / (traitGenerationParams.timeInfluence + traitGenerationParams.reputationInfluence + 1)) + traitGenerationParams.baseValue / 3; // Simple weighted average + base chunk

        // Trait 2: Stability (Influenced by Resource + Time)
        uint256 stabilityRaw = (pseudoRandom(randSeed + 1) % 101); // 0-100
        newTraits.stability = int256((stabilityRaw * (resourceInfluence + timeInfluence)) / (traitGenerationParams.resourceInfluence + traitGenerationParams.timeInfluence + 1)) + traitGenerationParams.baseValue / 3;

        // Trait 3: Vitality (Influenced by Reputation + Resource)
        uint256 vitalityRaw = (pseudoRandom(randSeed + 2) % 101); // 0-100
        newTraits.vitality = int256((vitalityRaw * (reputationInfluence + resourceInfluence)) / (traitGenerationParams.reputationInfluence + traitGenerationParams.resourceInfluence + 1)) + traitGenerationParams.baseValue / 3;

        // Apply overall influence factor and clamp traits
        newTraits.harmony = (newTraits.harmony * int256(totalInfluence)) / 100;
        newTraits.stability = (newTraits.stability * int256(totalInfluence)) / 100;
        newTraits.vitality = (newTraits.vitality * int256(totalInfluence)) / 100;

        // Ensure traits are within a reasonable range (e.g., 0-100 initially, but int256 allows negative/higher after refinement)
        newTraits.harmony = newTraits.harmony < 0 ? 0 : (newTraits.harmony > 100 ? 100 : newTraits.harmony);
        newTraits.stability = newTraits.stability < 0 ? 0 : (newTraits.stability > 100 ? 100 : newTraits.stability);
        newTraits.vitality = newTraits.vitality < 0 ? 0 : (newTraits.vitality > 100 ? 100 : newTraits.vitality);


        // Store traits
        artifactTraits[tokenId] = newTraits;

        // Mint the artifact
        _safeMintSA(msg.sender, tokenId);

        // Update reputation (e.g., slight boost for successful synthesis)
        _updateReputation(msg.sender, userReputation[msg.sender] + 10); // Example: +10 rep

        // Clear pending synthesis state
        delete pendingSyntheses[msg.sender];

        emit SynthesisCompleted(msg.sender, tokenId, pending.crystalsLocked);
    }

    /**
     * @notice Allows a user to cancel a pending synthesis before it is complete.
     * @dev Refunds a portion of the locked RC tokens. Reputation might be affected negatively.
     */
    function cancelSynthesis() external {
        PendingSynthesis storage pending = pendingSyntheses[msg.sender];
        require(pending.active, NoSynthesisInProgress());
        uint256 completeTime = pending.startTime + synthesisDurationSeconds;
        require(block.timestamp < completeTime, "Synthesis: Already complete, cannot cancel");

        // Calculate refund amount (e.g., 50% refund)
        uint256 refundAmount = pending.crystalsLocked / 2;

        // Refund RC tokens
        // Since RC is internal, mint them back to the user
        _mintRC(msg.sender, refundAmount);

        // Update reputation (e.g., slight penalty for cancelling)
        uint256 currentRep = userReputation[msg.sender];
        _updateReputation(msg.sender, currentRep >= 5 ? currentRep - 5 : 0); // Example: -5 rep, min 0

        // Clear pending synthesis state
        delete pendingSyntheses[msg.sender];

        emit SynthesisCancelled(msg.sender, refundAmount);
    }

    // --- Artifact Interaction Logic ---

    /**
     * @notice Allows the owner of an artifact to attempt to refine its traits.
     * @dev Costs RC tokens. Randomly adjusts traits within a defined range.
     *      Outcome might be influenced by trait values or user reputation.
     * @param tokenId The ID of the SA token to refine.
     */
    function refineArtifact(uint256 tokenId) external {
        require(_existsSA(tokenId), ArtifactDoesNotExist(tokenId));
        require(ownerOfSA(tokenId) == msg.sender, NotArtifactOwner(tokenId));
        require(_balancesRC[msg.sender] >= refinementCostRC, NotEnoughResonanceCrystals(refinementCostRC, _balancesRC[msg.sender]));
        // Check if refinement is actually possible/meaningful (e.g., traits not maxed out)
        // require(artifactTraits[tokenId].harmony < 200 || artifactTraits[tokenId].stability < 200 || artifactTraits[tokenId].vitality < 200, RefinementNotPossible(tokenId)); // Example check

        // Burn RC tokens for refinement
        _burnRC(msg.sender, refinementCostRC);

        // --- Refinement Trait Adjustment ---
        // Basic pseudo-random adjustment within the min/max effect range
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, refinementCostRC)));
        function pseudoRandomRange(uint256 seed, int256 minVal, int256 maxVal) pure returns (int256) {
             require(maxVal >= minVal, "Invalid range");
             uint256 range = uint256(maxVal - minVal + 1);
             return minVal + int256(uint256(keccak256(abi.encodePacked(seed, block.timestamp))) % range);
        }

        ArtifactTraits storage currentTraits = artifactTraits[tokenId];
        int256[] memory traitChanges = new int256[](currentTraits.traitCount); // Array to log changes

        // Apply random changes to each trait
        traitChanges[0] = pseudoRandomRange(randSeed, refinementMinTraitEffect, refinementMaxTraitEffect);
        traitChanges[1] = pseudoRandomRange(randSeed + 1, refinementMinTraitEffect, refinementMaxTraitEffect);
        traitChanges[2] = pseudoRandomRange(randSeed + 2, refinementMinTraitEffect, refinementMaxTraitEffect);

        // Apply changes
        currentTraits.harmony += traitChanges[0];
        currentTraits.stability += traitChanges[1];
        currentTraits.vitality += traitChanges[2];

        // Optional: Clamp traits to a max value after refinement (e.g., 200)
        int256 maxPossibleTrait = 200;
        currentTraits.harmony = currentTraits.harmony > maxPossibleTrait ? maxPossibleTrait : currentTraits.harmony;
        currentTraits.stability = currentTraits.stability > maxPossibleTrait ? maxPossibleTrait : currentTraits.stability;
        currentTraits.vitality = currentTraits.vitality > maxPossibleTrait ? maxPossibleTrait : currentTraits.vitality;

        // Update reputation (e.g., small boost for engaging)
        _updateReputation(msg.sender, userReputation[msg.sender] + 2); // Example: +2 rep

        emit ArtifactRefined(tokenId, refinementCostRC, traitChanges);
    }

    /**
     * @notice Allows the owner of an artifact to burn it in exchange for RC tokens.
     * @dev The amount of RC refunded can depend on the artifact's traits (e.g., Stability).
     *      User reputation is affected by dismantling.
     * @param tokenId The ID of the SA token to dismantle.
     */
    function dismantleArtifact(uint256 tokenId) external {
        require(_existsSA(tokenId), ArtifactDoesNotExist(tokenId));
        require(ownerOfSA(tokenId) == msg.sender, NotArtifactOwner(tokenId));

        // Calculate refund amount based on trait (e.g., Stability) and initial cost
        // Max refund is initial synthesisCostRC * some factor (e.g., 80%)
        // Trait influence: 0 stability = 0% of max refund, 100 stability = 100% of max refund
        ArtifactTraits storage currentTraits = artifactTraits[tokenId];
        uint256 maxRefundFactor = 80; // Max 80% of original cost
        uint256 traitInfluenceFactor = currentTraits.stability < 0 ? 0 : (currentTraits.stability > 100 ? 100 : uint256(currentTraits.stability)); // Clamp stability to 0-100 for influence
        uint256 refundAmount = (synthesisCostRC * maxRefundFactor / 100) * traitInfluenceFactor / 100;


        // Burn the artifact
        _burnSA(tokenId);

        // Mint RC refund to the user
        if (refundAmount > 0) {
            _mintRC(msg.sender, refundAmount);
        }

        // Update reputation (e.g., negative impact for destroying?)
        uint256 currentRep = userReputation[msg.sender];
        _updateReputation(msg.sender, currentRep >= 10 ? currentRep - 10 : 0); // Example: -10 rep, min 0

        emit ArtifactDismantled(tokenId, refundAmount, msg.sender);
    }

    // --- Reputation System ---

    /**
     * @notice Gets the current reputation score for a specific user.
     * @param user The address of the user.
     * @return The user's current reputation score.
     */
    function getUserReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    /**
     * @notice Allows a user to burn an artifact for a significant boost to their reputation.
     * @dev No RC refund is given when burning for reputation.
     *      The reputation boost might depend on the artifact's traits (e.g., Vitality).
     * @param tokenId The ID of the SA token to burn for reputation.
     */
    function burnArtifactForReputation(uint256 tokenId) external {
        require(_existsSA(tokenId), ArtifactDoesNotExist(tokenId));
        require(ownerOfSA(tokenId) == msg.sender, NotArtifactOwner(tokenId));

        // Calculate reputation gain based on trait (e.g., Vitality)
        // Max gain based on a factor * initial synthesis cost
        // Trait influence: 0 vitality = min gain, 100 vitality = max gain
        ArtifactTraits storage currentTraits = artifactTraits[tokenId];
        uint256 repGainFactorPerVitality = 5; // Example: Gain 5 rep per vitality point (clamped 0-100)
        uint256 traitInfluenceFactor = currentTraits.vitality < 0 ? 0 : (currentTraits.vitality > 100 ? 100 : uint256(currentTraits.vitality)); // Clamp vitality to 0-100 for influence
        uint256 reputationGain = traitInfluenceFactor * repGainFactorPerVitality;


        // Burn the artifact (no RC refund)
        _burnSA(tokenId);

        // Update reputation
        _updateReputation(msg.sender, userReputation[msg.sender] + reputationGain);

        // Emit a specific event for this action if desired, or rely on ArtifactBurnt and UserReputationUpdated.
    }

    /**
     * @dev Internal helper to update a user's reputation score and emit event.
     * @param user The address of the user.
     * @param newReputation The new reputation score.
     */
    function _updateReputation(address user, uint256 newReputation) internal {
        uint256 oldReputation = userReputation[user];
        if (oldReputation != newReputation) {
             userReputation[user] = newReputation;
             emit UserReputationUpdated(user, newReputation);
        }
    }

    // --- Ownership & Control (Admin/Owner Functions) ---

    /**
     * @notice Sets the parameters for initiating synthesis.
     * @dev Only callable by the owner. Requires positive cost and duration.
     * @param _synthesisCostRC The amount of RC tokens required per synthesis.
     * @param _synthesisDurationSeconds The minimum time duration for synthesis.
     */
    function setSynthParameters(uint256 _synthesisCostRC, uint256 _synthesisDurationSeconds) external onlyOwner {
        require(_synthesisCostRC > 0 && _synthesisDurationSeconds > 0, InvalidParameters());
        synthesisCostRC = _synthesisCostRC;
        synthesisDurationSeconds = _synthesisDurationSeconds;
        emit SynthParametersUpdated(_synthesisCostRC, _synthesisDurationSeconds);
    }

    /**
     * @notice Sets the parameters for artifact refinement.
     * @dev Only callable by the owner. Requires positive cost.
     * @param _refinementCostRC The amount of RC tokens required for refinement.
     * @param _refinementMinTraitEffect The minimum possible change to a trait during refinement.
     * @param _refinementMaxTraitEffect The maximum possible change to a trait during refinement.
     */
    function setRefinementParameters(uint256 _refinementCostRC, int256 _refinementMinTraitEffect, int256 _refinementMaxTraitEffect) external onlyOwner {
        require(_refinementCostRC > 0, InvalidParameters());
        require(_refinementMaxTraitEffect >= _refinementMinTraitEffect, "Invalid effect range");
        refinementCostRC = _refinementCostRC;
        refinementMinTraitEffect = _refinementMinTraitEffect;
        refinementMaxTraitEffect = _refinementMaxTraitEffect;
        emit RefinementParametersUpdated(_refinementCostRC, _refinementMinTraitEffect, _refinementMaxTraitEffect);
    }

    /**
     * @notice Sets the parameters influencing initial trait generation during synthesis.
     * @dev Only callable by the owner. Sum of influence percentages should be reasonable (e.g., <= 100).
     * @param _baseValue Base value for traits.
     * @param _timeInfluence % influence of time waited.
     * @param _resourceInfluence % influence of resources used.
     * @param _reputationInfluence % influence of user reputation.
     */
    function setTraitGenerationParams(uint8 _baseValue, uint8 _timeInfluence, uint8 _resourceInfluence, uint8 _reputationInfluence) external onlyOwner {
        require(_baseValue + _timeInfluence + _resourceInfluence + _reputationInfluence <= 100, InvalidParameters()); // Example sanity check
        traitGenerationParams = TraitGenParams({
            baseValue: _baseValue,
            timeInfluence: _timeInfluence,
            resourceInfluence: _resourceInfluence,
            reputationInfluence: _reputationInfluence
        });
        emit TraitGenerationParametersUpdated(_baseValue, _timeInfluence, _resourceInfluence, _reputationInfluence);
    }

     /**
      * @notice Sets the reputation score thresholds for defining different levels or tiers.
      * @dev Only callable by the owner. Thresholds should be non-decreasing.
      * @param _reputationLevelThresholds Array of threshold scores. A user with score >= thresholds[i] is at least level i.
      */
    function setReputationLevelThresholds(uint256[] calldata _reputationLevelThresholds) external onlyOwner {
        for (uint i = 0; i < _reputationLevelThresholds.length - 1; i++) {
            require(_reputationLevelThresholds[i] <= _reputationLevelThresholds[i+1], "Thresholds must be non-decreasing");
        }
        reputationLevelThresholds = _reputationLevelThresholds;
        // No specific event for this, rely on emitted UserReputationUpdated to react off-chain
    }

    /**
     * @notice Allows the owner to withdraw any ERC-20 tokens (other than RC) accidentally sent to the contract.
     * @dev Use with caution. Only withdraws from this specific contract's balance.
     * @param tokenAddress The address of the ERC-20 token to withdraw.
     * @param amount The amount to withdraw.
     * @param to The address to send the tokens to.
     */
    function emergencyOwnerWithdrawERC20(address tokenAddress, uint256 amount, address to) external onlyOwner {
        require(tokenAddress != address(this), "Cannot withdraw this contract's own address as token");
        require(tokenAddress != address(0), "Cannot withdraw from zero address");
        // Check if the token is *not* the internal RC token (by name/symbol assumption or direct address check if RC was external)
        // Since RC is internal, its 'address' is address(this), which is excluded above.

        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, NotEnoughResonanceCrystals(amount, balance));
        require(to != address(0), "Withdraw to zero address not allowed");

        bool success = token.transfer(to, amount);
        require(success, "ERC20 transfer failed");
        // Consider adding an event for this emergency withdrawal
    }

    /**
     * @notice Allows the owner to withdraw any ETH accidentally sent to the contract.
     * @dev Use with caution.
     * @param amount The amount of ETH to withdraw.
     * @param to The address to send the ETH to.
     */
    function emergencyOwnerWithdrawETH(uint256 amount, address to) external onlyOwner {
        require(amount > 0, NothingToWithdraw());
        require(address(this).balance >= amount, NothingToWithdraw());
        require(to != address(0), "Withdraw to zero address not allowed");

        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "ETH transfer failed");
        // Consider adding an event for this emergency withdrawal
    }

    // Fallback function to receive ETH (can be useful for owner withdrawal)
    receive() external payable {
        // Optional: Add checks or emit event if expected behavior
    }


    // --- Query & Utility Functions (View/Pure) ---

    /**
     * @notice Returns the current parameters for initiating synthesis.
     * @return synthesisCostRC_ The amount of RC tokens required per synthesis.
     * @return synthesisDurationSeconds_ The minimum time duration for synthesis.
     */
    function getSynthParameters() external view returns (uint256 synthesisCostRC_, uint256 synthesisDurationSeconds_) {
        return (synthesisCostRC, synthesisDurationSeconds);
    }

    /**
     * @notice Returns the current parameters for artifact refinement.
     * @return refinementCostRC_ The amount of RC tokens required for refinement.
     * @return refinementMinTraitEffect_ The minimum possible change to a trait.
     * @return refinementMaxTraitEffect_ The maximum possible change to a trait.
     */
    function getRefinementParameters() external view returns (uint256 refinementCostRC_, int256 refinementMinTraitEffect_, int256 refinementMaxTraitEffect_) {
        return (refinementCostRC, refinementMinTraitEffect, refinementMaxTraitEffect);
    }

    /**
     * @notice Returns the parameters used for trait generation during synthesis.
     * @return baseValue_ Base value for traits.
     * @return timeInfluence_ % influence of time waited.
     * @return resourceInfluence_ % influence of resources used.
     * @return reputationInfluence_ % influence of user reputation.
     */
    function getTraitGenerationParams() external view returns (uint8 baseValue_, uint8 timeInfluence_, uint8 resourceInfluence_, uint8 reputationInfluence_) {
        return (traitGenerationParams.baseValue, traitGenerationParams.timeInfluence, traitGenerationParams.resourceInfluence, traitGenerationParams.reputationInfluence);
    }


    /**
     * @notice Returns the dynamic traits for a specific Synthesized Artifact token.
     * @param tokenId The ID of the SA token.
     * @return traits The ArtifactTraits struct containing harmony, stability, and vitality.
     */
    function getArtifactTraits(uint256 tokenId) external view returns (ArtifactTraits memory traits) {
        require(_existsSA(tokenId), ArtifactDoesNotExist(tokenId));
        return artifactTraits[tokenId];
    }

    /**
     * @notice Returns the state of a user's pending synthesis.
     * @param user The address of the user.
     * @return startTime The timestamp when synthesis started (0 if inactive).
     * @return crystalsLocked The amount of RC tokens locked for this synthesis (0 if inactive).
     * @return active Whether a synthesis is currently active for the user.
     */
    function getPendingSynthesis(address user) external view returns (uint256 startTime, uint256 crystalsLocked, bool active) {
        PendingSynthesis storage pending = pendingSyntheses[user];
        return (pending.startTime, pending.crystalsLocked, pending.active);
    }

    /**
     * @notice Returns the total number of Synthesized Artifacts minted.
     * @return The total count of SA tokens minted so far.
     */
    function getTotalArtifactsMintedSA() external view returns (uint256) {
        // token IDs start from 1, so count is _nextTokenIdSA - 1
        return _nextTokenIdSA - 1;
    }

     /**
      * @notice Returns the configured reputation level thresholds.
      * @return An array of scores defining reputation tiers.
      */
    function getReputationLevelThresholds() external view returns (uint256[] memory) {
        return reputationLevelThresholds;
    }

    /**
     * @notice Returns a version identifier for the contract.
     * @return A simple string indicating the contract version.
     */
    function getChronoSynthesizerProtocolVersion() external pure returns (string memory) {
        return "ChronoSynthesizerProtocol v1.0";
    }


    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165 || interfaceId == _INTERFACE_ID_ERC721;
    }
}

// Simple helper for Base64 encoding (needed for data URI)
// from OpenZeppelin/openzeppelin-contracts (simplified)
library Base64 {
    string internal constant ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Load the alphabet and bits per group
        string memory alphabet = ALPHABET;
        uint256 bitsPerGroup = 6;
        uint256 groupSize = 3; // Bytes per group

        // Calculate output length: 4 characters per 3 bytes, rounded up.
        uint256 dataLength = data.length;
        uint256 encodedLength = ((dataLength + groupSize - 1) / groupSize) * 4;
        bytes memory result = new bytes(encodedLength);

        // Encode
        uint256 dataPtr = 0;
        uint256 resultPtr = 0;
        for (uint256 i = 0; i < dataLength / groupSize; i++) {
            uint256 group = (uint256(uint8(data[dataPtr++])) << 16) | (uint256(uint8(data[dataPtr++])) << 8) | uint256(uint8(data[dataPtr++]));
            result[resultPtr++] = bytes1(alphabet[group >> 18]);
            result[resultPtr++] = bytes1(alphabet[(group >> 12) & 0x3F]);
            result[resultPtr++] = bytes1(alphabet[(group >> 6) & 0x3F]);
            result[resultPtr++] = bytes1(alphabet[group & 0x3F]);
        }

        // Handle padding
        uint256 remaining = dataLength - dataPtr;
        if (remaining == 1) {
            uint256 group = uint256(uint8(data[dataPtr]));
            result[resultPtr++] = bytes1(alphabet[group >> 2]);
            result[resultPtr++] = bytes1(alphabet[(group << 4) & 0x3F]);
            result[resultPtr++] = "=";
            result[resultPtr++] = "=";
        } else if (remaining == 2) {
            uint256 group = (uint256(uint8(data[dataPtr++])) << 8) | uint256(uint8(data[dataPtr]));
            result[resultPtr++] = bytes1(alphabet[group >> 10]);
            result[resultPtr++] = bytes1(alphabet[(group >> 4) & 0x3F]);
            result[resultPtr++] = bytes1(alphabet[(group << 2) & 0x3F]);
            result[resultPtr++] = "=";
        }

        return string(result);
    }
}

// Simple helper for uint to string conversion (needed for data URI)
// from OpenZeppelin/openzeppelin-contracts (simplified)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }

    function toString(int256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        bool negative = value < 0;
        if (negative) {
            value = -value;
        }
        uint256 temp = uint256(value);
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer;
        if (negative) {
            buffer = new bytes(digits + 1);
            buffer[0] = '-';
        } else {
            buffer = new bytes(digits);
        }
        while (value != 0) {
            digits--;
             buffer[negative ? digits + 1 : digits] = bytes1(uint8(48 + uint256(value) % 10));
             value /= 10;
        }
        return string(buffer);
    }
}

// Basic IERC165 and IERC721Receiver interfaces (simplified for this example)
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
```