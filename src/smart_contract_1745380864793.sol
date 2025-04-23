Okay, let's design a smart contract for dynamic NFTs that evolve based on time and external data, incorporating staking mechanics and owner interaction. We'll call it "QuantumFlow NFTs".

The core concept is that each NFT represents a unique "quantum state" which changes over time and can be influenced by external "flux" data delivered via an oracle. Owners can also "re-align" their NFTs or stake them to affect their evolution.

This contract will integrate:
1.  Standard ERC721 functionality.
2.  Dynamic metadata using `tokenURI` that reflects the current calculated state.
3.  Time-based state evolution (decay/growth).
4.  External data integration via a mockable oracle pattern.
5.  Owner-initiated state manipulation.
6.  Staking mechanism for NFTs to influence state evolution or potentially earn yield (represented conceptually here).
7.  Admin controls for parameters and oracle.

We will use OpenZeppelin libraries for standard features like ERC721, Ownable, and Pausable, as building on these is standard practice and not considered "duplication" in the sense of creating a generic ERC721 from scratch. The novel logic for state management, flux, staking, and owner actions will be custom.

---

**Outline & Function Summary: QuantumFlowNFT**

**Contract:** `QuantumFlowNFT`
**Inherits:** ERC721URIStorage, Ownable, Pausable, ERC2981

**Concepts:**
*   **Dynamic State:** NFT properties stored on-chain change over time and based on external data.
*   **Quantum Parameters:** Numeric attributes defining the NFT's state (e.g., fluxIntensity, temporalEntropy).
*   **Time Evolution:** State changes gradually based on time elapsed since last update/action.
*   **External Flux:** An oracle provides data (`fluxValue`) that causes discrete shifts in Quantum Parameters.
*   **Owner Interaction:** Owners can trigger `realignNFT` to influence their NFT's state.
*   **Staking:** Owners can stake NFTs to potentially modify their evolution rate or state dynamics.
*   **Dynamic Metadata:** `tokenURI` computes the current state and provides metadata reflecting it.
*   **Royalties:** Supports EIP-2981 for standard NFT royalties.

**Function Summary:**

1.  **`constructor`**: Initializes the contract name, symbol, base URI for metadata, initial owner, and sets initial global parameters.
2.  **`supportsInterface(bytes4 interfaceId)`**: ERC165 standard. Reports support for ERC721, ERC2981, and other interfaces.
3.  **`balanceOf(address owner)`**: ERC721 standard. Returns the number of NFTs owned by an address.
4.  **`ownerOf(uint256 tokenId)`**: ERC721 standard. Returns the owner of a specific NFT.
5.  **`safeTransferFrom(address from, address to, uint256 tokenId)`**: ERC721 standard. Transfers NFT safely (checks receiver).
6.  **`safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`**: ERC721 standard. Transfers NFT safely with extra data.
7.  **`transferFrom(address from, address to, uint256 tokenId)`**: ERC721 standard. Transfers NFT (without safety check).
8.  **`approve(address to, uint256 tokenId)`**: ERC721 standard. Approves another address to transfer a specific NFT.
9.  **`setApprovalForAll(address operator, bool approved)`**: ERC721 standard. Approves/disapproves an operator for all NFTs.
10. **`getApproved(uint256 tokenId)`**: ERC721 standard. Returns the approved address for a specific NFT.
11. **`isApprovedForAll(address owner, address operator)`**: ERC721 standard. Checks if an operator is approved for all NFTs of an owner.
12. **`tokenURI(uint256 tokenId)`**: ERC721URIStorage & Dynamic Metadata. Computes the *current* state of the NFT based on time and applies base URI. Returns a URI pointing to dynamic metadata reflecting the state.
13. **`royaltyInfo(uint256 tokenId, uint256 salePrice)`**: ERC2981 standard. Returns the royalty recipient and amount for a sale.
14. **`mint(address to, uint256 initialFluxIntensity, uint256 initialTemporalEntropy)`**: Mints a new QuantumFlow NFT, initializing its state parameters and setting the last updated timestamp. Restricted (e.g., to owner or minter role).
15. **`getQuantumState(uint256 tokenId)`**: View function. Returns the raw stored state struct for a specific NFT.
16. **`calculateCurrentState(uint256 tokenId)`**: Internal/View function. Calculates the *potential* state of an NFT based on time elapsed since its last update, applying time-based decay/growth rules. Does *not* store the result.
17. **`triggerFluxUpdate(uint256 tokenId, int256 fluxValue)`**: External function (callable by oracle/authorized). Incorporates an external `fluxValue` into the specified NFT's state parameters, updates the stored state, and records the last flux value.
18. **`realignNFT(uint256 tokenId)`**: Owner function. Allows the owner of an NFT to perform an action that modifies its state, perhaps resetting entropy or boosting certain parameters. May require a fee or cost gas.
19. **`stakeNFT(uint256 tokenId)`**: Owner function. Marks an NFT as staked, potentially pausing or altering its time-based evolution. May require NFT transfer to contract or lockup.
20. **`unstakeNFT(uint256 tokenId)`**: Owner function. Removes an NFT from the staked state, calculates any staking duration effects, updates state, and makes it transferrable again.
21. **`getStakingYield(uint256 tokenId)`**: View function. Calculates the theoretical staking yield accrued for a staked NFT based on duration or other factors (conceptual yield).
22. **`getTotalStaked()`**: View function. Returns the total count of NFTs currently staked in the contract.
23. **`setQuantumParameters(uint256 _decayRate, uint256 _growthRate, uint256 _baseEntropy)`**: Admin function. Sets global parameters that influence the time-based state evolution of all NFTs.
24. **`setFluxImpactFactor(int256 _fluxIntensityImpact, int256 _temporalEntropyImpact)`**: Admin function. Sets global factors determining how much the external `fluxValue` affects different state parameters during an update.
25. **`setOracleAddress(address _oracle)`**: Admin function. Sets the address authorized to call `triggerFluxUpdate`.
26. **`pause()`**: Admin function. Pauses certain contract operations (e.g., transfers, staking, minting).
27. **`unpause()`**: Admin function. Unpauses the contract.
28. **`withdrawStakingFunds()`**: Admin function. Allows withdrawal of any ETH or tokens sent to the contract for staking rewards or fees.
29. **`getLastFluxValue()`**: View function. Returns the last `fluxValue` reported by the oracle.
30. **`_beforeTokenTransfer(address from, address to, uint256 tokenId)`**: Internal hook. Executed before any token transfer. This is crucial to calculate and apply time-based state changes *just before* the transfer occurs, ensuring state is updated upon ownership change or staking status change.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline & Function Summary: QuantumFlowNFT
// Contract: `QuantumFlowNFT`
// Inherits: ERC721URIStorage, Ownable, Pausable, ERC2981
// Concepts: Dynamic State, Quantum Parameters, Time Evolution, External Flux, Owner Interaction, Staking, Dynamic Metadata, Royalties.
// (See detailed summary above the contract code)

contract QuantumFlowNFT is ERC721URIStorage, Ownable, Pausable, ERC2981 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    // --- State Structure ---
    struct QuantumState {
        uint256 lastUpdatedTime; // Timestamp of the last state update
        uint256 fluxIntensity;   // Parameter 1: Affects visual vibrancy/energy
        uint256 temporalEntropy; // Parameter 2: Affects visual chaos/stability
        uint256 resonanceFrequency; // Parameter 3: Affects visual pattern/form
        bool isStaked;           // Is the NFT currently staked?
        uint256 stakedStartTime; // Timestamp when staking began (if staked)
    }

    // Mapping from token ID to its Quantum State
    mapping(uint256 => QuantumState) private _quantumStates;

    // --- Global State Parameters (Tunable by Admin) ---
    uint256 private _decayRate; // Rate at which temporalEntropy increases over time (higher = faster chaos)
    uint256 private _growthRate; // Rate at which fluxIntensity increases over time (higher = faster energy)
    uint256 private _baseEntropy; // Minimum temporalEntropy

    // --- External Flux Parameters ---
    address private _oracleAddress; // Address authorized to report external flux
    int256 private _lastFluxValue; // Last reported flux value
    // How much external flux impacts state parameters
    int256 private _fluxIntensityImpactFactor;
    int256 private _temporalEntropyImpactFactor;

    // --- Staking Parameters ---
    uint256 private _stakingBaseYield; // Base yield per second (conceptual, scaled)
    uint256 private _stakedTokenCount; // Counter for staked NFTs

    // --- Royalties Parameters ---
    address private _royaltyRecipient;
    uint96 private _royaltyFeeNumerator; // Represents percentage * 100 (e.g., 500 for 5%)

    // --- Events ---
    event QuantumStateUpdated(uint256 indexed tokenId, uint256 newFluxIntensity, uint256 newTemporalEntropy, uint256 newResonanceFrequency, uint256 updateTime);
    event FluxApplied(uint256 indexed tokenId, int256 fluxValue, uint256 newFluxIntensity, uint256 newTemporalEntropy);
    event NFTStaked(uint256 indexed tokenId, address indexed owner, uint256 stakeTime);
    event NFTUnstaked(uint256 indexed tokenId, address indexed owner, uint256 unstakeTime, uint256 yieldAmount);
    event QuantumParametersSet(uint256 decayRate, uint256 growthRate, uint256 baseEntropy);
    event FluxImpactFactorsSet(int256 fluxIntensityImpact, int256 temporalEntropyImpact);
    event OracleAddressSet(address indexed oracleAddress);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == _oracleAddress, "Only oracle can call this function");
        _;
    }

    // --- Constructor ---
    // 1. constructor
    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        address royaltyRecipient,
        uint96 royaltyFeeNumerator,
        uint256 initialDecayRate,
        uint256 initialGrowthRate,
        uint256 initialBaseEntropy,
        int256 initialFluxIntensityImpact,
        int256 initialTemporalEntropyImpact,
        uint256 stakingBaseYieldPerSecond
    ) ERC721(name, symbol)
      ERC721URIStorage()
      Ownable(initialOwner)
      ERC2981() // Initialize ERC2981
      Pausable() {

        _royaltyRecipient = royaltyRecipient;
        _royaltyFeeNumerator = royaltyFeeNumerator;

        _decayRate = initialDecayRate;
        _growthRate = initialGrowthRate;
        _baseEntropy = initialBaseEntropy;

        _fluxIntensityImpactFactor = initialFluxIntensityImpact;
        _temporalEntropyImpactFactor = initialTemporalEntropyImpact;

        _stakingBaseYield = stakingBaseYieldPerSecond;
    }

    // --- Standard ERC721/ERC165 Functions ---

    // 2. supportsInterface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // 3. balanceOf
    // 4. ownerOf
    // 5. safeTransferFrom (address,address,uint256)
    // 6. safeTransferFrom (address,address,uint256,bytes)
    // 7. transferFrom
    // 8. approve
    // 9. setApprovalForAll
    // 10. getApproved
    // 11. isApprovedForAll
    // (These are standard ERC721 implementations from OpenZeppelin)

    // 12. tokenURI - Dynamic Metadata Implementation
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        // Calculate the *current* state based on time passed
        // This calculation happens on the fly for metadata, not storing state
        (uint256 currentFluxIntensity, uint256 currentTemporalEntropy, uint256 currentResonanceFrequency) = _calculateCurrentState(tokenId);

        // Example: Constructing a simple data URI or path
        // In a real dApp, this would often point to an API endpoint like:
        // "https://api.quantumflownfts.io/metadata/{tokenId}"
        // The API would then query the on-chain state using getQuantumState
        // and format the JSON metadata including the calculated current parameters.
        // For this example, we'll return a placeholder pointing to such a service.
        // A more complex on-chain example could involve base64 encoding JSON here,
        // but that's gas-intensive and limits complexity.

        // Using a placeholder base URI + token ID
         string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return super.tokenURI(tokenId); // Fallback or error if no base URI
        }

        // Append token ID to base URI. An off-chain service would read this.
        return string(abi.encodePacked(base, Strings.toString(tokenId)));

        // Note: The off-chain service processing this URI would need to call
        // getQuantumState(tokenId) and potentially _calculateCurrentState(tokenId)
        // to determine the *actual* current visual/metadata properties.
    }

    // 13. royaltyInfo - ERC2981 Implementation
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override(ERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        // Royalty applies based on the contract's default settings, regardless of token ID specifics
        return (_royaltyRecipient, salePrice.mul(_royaltyFeeNumerator) / 10000); // 10000 is 100% with 2 decimals for numerator
    }

    // --- Core QuantumFlow Logic ---

    // 14. mint
    function mint(address to, uint256 initialFluxIntensity, uint256 initialTemporalEntropy)
        public
        onlyOwner // Simple access control, could be more complex like a whitelist/public sale
        whenNotPaused
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Initialize state for the new NFT
        _quantumStates[newTokenId] = QuantumState({
            lastUpdatedTime: block.timestamp,
            fluxIntensity: initialFluxIntensity,
            temporalEntropy: initialTemporalEntropy,
            resonanceFrequency: uint256(keccak256(abi.encodePacked(newTokenId, block.timestamp, initialFluxIntensity, initialTemporalEntropy))) % 1000, // Simple initial resonance
            isStaked: false,
            stakedStartTime: 0
        });

        _mint(to, newTokenId);

        emit QuantumStateUpdated(newTokenId, initialFluxIntensity, initialTemporalEntropy, _quantumStates[newTokenId].resonanceFrequency, block.timestamp);
        return newTokenId;
    }

    // 15. getQuantumState
    function getQuantumState(uint256 tokenId) public view returns (QuantumState memory) {
        require(_exists(tokenId), "QuantumFlow: Token does not exist");
        return _quantumStates[tokenId];
    }

    // 16. calculateCurrentState (Internal/View Helper)
    // Calculates the state after applying time-based evolution since last update.
    function _calculateCurrentState(uint256 tokenId) internal view returns (uint256 fluxIntensity, uint256 temporalEntropy, uint256 resonanceFrequency) {
        QuantumState memory state = _quantumStates[tokenId];
        uint256 timeElapsed = block.timestamp - state.lastUpdatedTime;

        // If staked, time evolution might be paused or different
        if (state.isStaked) {
             // Example: Staking might boost flux intensity and stabilize entropy
             fluxIntensity = state.fluxIntensity.add(timeElapsed.mul(_growthRate / 2)); // Slower growth
             temporalEntropy = state.temporalEntropy > _baseEntropy ? state.temporalEntropy.sub(timeElapsed.mul(_decayRate / 2)) : state.temporalEntropy; // Slower decay towards base
             if (temporalEntropy < _baseEntropy) temporalEntropy = _baseEntropy; // Don't go below base
        } else {
             // Apply time-based decay and growth
             // Entropy increases (decay), Flux increases (growth)
             temporalEntropy = state.temporalEntropy.add(timeElapsed.mul(_decayRate));
             fluxIntensity = state.fluxIntensity.add(timeElapsed.mul(_growthRate));
        }

        // Resonance Frequency could also evolve, perhaps based on a combination or just time
        // Let's keep it simple for now and only update when flux is applied or realigned.
        resonanceFrequency = state.resonanceFrequency;

        return (fluxIntensity, temporalEntropy, resonanceFrequency);
    }

    // 33. _updateQuantumState (Internal Helper)
    // Applies calculated state values to the stored state and updates timestamp.
    function _updateQuantumState(uint256 tokenId, uint256 newFluxIntensity, uint256 newTemporalEntropy, uint256 newResonanceFrequency) internal {
        QuantumState storage state = _quantumStates[tokenId];
        state.fluxIntensity = newFluxIntensity;
        state.temporalEntropy = newTemporalEntropy;
        state.resonanceFrequency = newResonanceFrequency;
        state.lastUpdatedTime = block.timestamp;

        emit QuantumStateUpdated(tokenId, newFluxIntensity, newTemporalEntropy, newResonanceFrequency, block.timestamp);
    }


    // 17. triggerFluxUpdate
    // Applies external flux data to the NFT's state.
    function triggerFluxUpdate(uint256 tokenId, int256 fluxValue)
        public
        onlyOracle // Only the designated oracle can trigger this
        whenNotPaused
    {
        require(_exists(tokenId), "QuantumFlow: Token does not exist");

        // First, calculate state based on time elapsed since last update
        (uint256 timeFlux, uint256 timeEntropy, uint256 timeResonance) = _calculateCurrentState(tokenId);

        // Now apply the impact of the new flux value to these calculated values
        int256 fluxIntensityDelta = fluxValue.mul(_fluxIntensityImpactFactor) / 1000; // Scale impact
        int256 temporalEntropyDelta = fluxValue.mul(_temporalEntropyImpactFactor) / 1000;

        // Ensure results are non-negative where applicable
        uint256 newFluxIntensity = timeFlux;
        if (fluxIntensityDelta >= 0) {
            newFluxIntensity = newFluxIntensity.add(uint256(fluxIntensityDelta));
        } else {
            newFluxIntensity = newFluxIntensity > uint256(-fluxIntensityDelta) ? newFluxIntensity.sub(uint256(-fluxIntensityDelta)) : 0;
        }

        uint256 newTemporalEntropy = timeEntropy;
         if (temporalEntropyDelta >= 0) {
            newTemporalEntropy = newTemporalEntropy.add(uint256(temporalEntropyDelta));
        } else {
            newTemporalEntropy = newTemporalEntropy > uint256(-temporalEntropyDelta) ? newTemporalEntropy.sub(uint256(-temporalEntropyDelta)) : _baseEntropy; // Entropy doesn't go below base
            if (newTemporalEntropy < _baseEntropy) newTemporalEntropy = _baseEntropy;
        }

        // Flux could also influence resonance frequency in a more complex way,
        // maybe tied to the absolute value or sign of fluxValue.
        // For simplicity, let's update resonance based on the latest flux value hash
        uint256 newResonanceFrequency = uint256(keccak256(abi.encodePacked(fluxValue, block.timestamp))) % 1000;


        // Update the stored state
        _updateQuantumState(tokenId, newFluxIntensity, newTemporalEntropy, newResonanceFrequency);
        _lastFluxValue = fluxValue; // Record the latest flux value

        emit FluxApplied(tokenId, fluxValue, newFluxIntensity, newTemporalEntropy);
    }

    // 18. realignNFT
    // Allows the owner to reset temporal entropy towards the base or boost flux.
    function realignNFT(uint256 tokenId)
        public
        whenNotPaused
    {
        require(_exists(tokenId), "QuantumFlow: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QuantumFlow: Not token owner");
        require(!_quantumStates[tokenId].isStaked, "QuantumFlow: Cannot realign staked NFT");

        // First, update state based on time elapsed
        (uint256 timeFlux, uint256 timeEntropy, uint256 timeResonance) = _calculateCurrentState(tokenId);

        // Apply the realign effect: reset entropy towards base, maybe add a flux boost
        uint256 realignedEntropy = (timeEntropy + _baseEntropy) / 2; // Average towards base
        uint256 boostedFlux = timeFlux.add(timeFlux.div(10)); // 10% boost example

        // Resonance frequency could also be 'smoothed' or re-randomized
        uint256 newResonanceFrequency = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, "realign"))) % 1000;


        // Update the stored state
        _updateQuantumState(tokenId, boostedFlux, realignedEntropy, newResonanceFrequency);

        // Could add a gas cost/fee requirement here
        // payable { require(msg.value >= realignFee, "Insufficient fee"); }
    }

    // 19. stakeNFT
    // Owner stakes their NFT.
    function stakeNFT(uint256 tokenId)
        public
        whenNotPaused
    {
        require(_exists(tokenId), "QuantumFlow: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QuantumFlow: Not token owner");
        require(!_quantumStates[tokenId].isStaked, "QuantumFlow: NFT already staked");

        // Before staking, apply any pending time-based state changes
        (uint256 currentFlux, uint256 currentEntropy, uint256 currentResonance) = _calculateCurrentState(tokenId);
        _updateQuantumState(tokenId, currentFlux, currentEntropy, currentResonance);

        // Mark as staked and record start time
        QuantumState storage state = _quantumStates[tokenId];
        state.isStaked = true;
        state.stakedStartTime = block.timestamp;
        _stakedTokenCount = _stakedTokenCount.add(1);

        // Note: A real staking system might involve transferring the NFT to the contract
        // or a staking pool contract. Here we just use a flag.
        // If transferring, you'd call _transfer or _safeTransfer.

        emit NFTStaked(tokenId, msg.sender, block.timestamp);
    }

    // 20. unstakeNFT
    // Owner unstakes their NFT.
    function unstakeNFT(uint256 tokenId)
        public
        whenNotPaused
    {
        require(_exists(tokenId), "QuantumFlow: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QuantumFlow: Not token owner"); // Assumes NFT stays with owner while staked
        require(_quantumStates[tokenId].isStaked, "QuantumFlow: NFT is not staked");

        // Calculate yield/effects based on staking duration
        uint256 stakingDuration = block.timestamp - _quantumStates[tokenId].stakedStartTime;
        uint256 yieldAmount = getStakingYield(tokenId); // Calculate yield conceptually

        // Unmark as staked
        QuantumState storage state = _quantumStates[tokenId];
        state.isStaked = false;
        state.stakedStartTime = 0; // Reset staking time
        _stakedTokenCount = _stakedTokenCount.sub(1);

        // Apply any pending state changes due to staking rules and time elapsed
        // _calculateCurrentState will use the *updated* isStaked=false and the *new* lastUpdatedTime
        (uint256 currentFlux, uint256 currentEntropy, uint256 currentResonance) = _calculateCurrentState(tokenId);
        _updateQuantumState(tokenId, currentFlux, currentEntropy, currentResonance);


        // Distribute yield (conceptual - would require a yield token or ETH)
        // Example: require(IERC20(yieldTokenAddress).transfer(msg.sender, yieldAmount), "Yield transfer failed");

        emit NFTUnstaked(tokenId, msg.sender, block.timestamp, yieldAmount);
    }

    // 21. getStakingYield
    // View function to see potential yield for a staked NFT.
    function getStakingYield(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QuantumFlow: Token does not exist");
        QuantumState memory state = _quantumStates[tokenId];
        require(state.isStaked, "QuantumFlow: NFT is not staked");

        uint256 stakingDuration = block.timestamp - state.stakedStartTime;

        // Conceptual yield calculation: duration * base yield rate
        // Could be more complex, e.g., dependent on NFT parameters, total staked, etc.
        return stakingDuration.mul(_stakingBaseYield);
    }

    // 22. getTotalStaked
    function getTotalStaked() public view returns (uint256) {
        return _stakedTokenCount;
    }

    // --- Admin Functions ---

    // 23. setQuantumParameters
    function setQuantumParameters(uint256 decayRate, uint256 growthRate, uint256 baseEntropy) public onlyOwner {
        _decayRate = decayRate;
        _growthRate = growthRate;
        _baseEntropy = baseEntropy;
        emit QuantumParametersSet(decayRate, growthRate, baseEntropy);
    }

    // 24. setFluxImpactFactor
    function setFluxImpactFactor(int256 fluxIntensityImpact, int256 temporalEntropyImpact) public onlyOwner {
        _fluxIntensityImpactFactor = fluxIntensityImpact;
        _temporalEntropyImpactFactor = temporalEntropyImpact;
        emit FluxImpactFactorsSet(fluxIntensityImpact, temporalEntropyImpact);
    }

    // 25. setOracleAddress
    function setOracleAddress(address oracle) public onlyOwner {
        _oracleAddress = oracle;
        emit OracleAddressSet(oracle);
    }

    // 26. pause
    function pause() public onlyOwner {
        _pause();
    }

    // 27. unpause
    function unpause() public onlyOwner {
        _unpause();
    }

    // 28. withdrawStakingFunds
    // Allows owner to withdraw any ETH sent to the contract (e.g., for staking rewards or fees)
    function withdrawStakingFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    // 29. getLastFluxValue
    function getLastFluxValue() public view returns (int256) {
        return _lastFluxValue;
    }

    // --- Internal Overrides & Hooks ---

    // 30. _beforeTokenTransfer
    // ERC721 hook - crucial for dynamic state.
    // Updates the state based on time elapsed *before* any transfer happens.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721URIStorage) // Override both as per OZ docs if using URIStorage
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Only update state if the token exists and isn't being burned (to is address(0))
        // or if it's not already handled by stake/unstake which call _updateQuantumState
        if (to != address(0) && from != address(0) && !_quantumStates[tokenId].isStaked) {
             // If the NFT is being transferred while *not* staked,
             // calculate and apply the state evolution since last update.
             (uint256 currentFlux, uint256 currentEntropy, uint256 currentResonance) = _calculateCurrentState(tokenId);
             _updateQuantumState(tokenId, currentFlux, currentEntropy, currentResonance);
             // Note: If transferring *into* staking (to == address(this) or staking contract)
             // or *out of* staking, the stake/unstake functions handle the state update.
             // This hook handles standard P2P transfers.
        }
         // When burning (to == address(0)), state is irrelevant.
         // When minting (from == address(0)), state is initialized in `mint`.
    }

    // 31. _baseURI
    // Internal helper for ERC721URIStorage base URI.
    function _baseURI() internal pure override(ERC721URIStorage) returns (string memory) {
         // Return a hardcoded or stored base URI
         // This could be set in the constructor or via an admin function
         return "https://api.quantumflownfts.io/metadata/"; // Example dynamic endpoint
    }

    // 32. _burn
    // Internal function to handle token burning.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        // Optionally delete state data to save gas on subsequent reads
        delete _quantumStates[tokenId];
    }

    // 34. _mint (Internal)
    // Used by public `mint` function. Overridden by URIStorage extension.
    // We don't need a separate implementation here as it's handled by ERC721URIStorage.
}
```

---

**Explanation of Advanced Concepts:**

1.  **Dynamic Metadata (`tokenURI` & `_calculateCurrentState`):** Instead of returning a static JSON file URI, `tokenURI` calculates the NFT's state based on time elapsed since the last update *every time it's called*. This allows the NFT's metadata (which would be served by an off-chain API reading this state) to change constantly without needing expensive on-chain state updates triggered externally. The off-chain service requesting the URI would then query `getQuantumState` and potentially recalculate based on `_calculateCurrentState` logic to render the current visual.
2.  **Time-Based Evolution (`_calculateCurrentState`):** The state parameters (`fluxIntensity`, `temporalEntropy`) change automatically based on time elapsed since the last `lastUpdatedTime`. This creates natural decay or growth effects for the NFT's visual representation or utility.
3.  **External Data Integration (`triggerFluxUpdate`, `onlyOracle`, `_lastFluxValue`):** The contract is designed to receive data from a trusted oracle. This data (`fluxValue`) impacts the NFT's state parameters via defined `_fluxImpactFactor`s. This allows the NFT's evolution to be influenced by real-world events or other on-chain data sources without trusting arbitrary external input.
4.  **Owner-Initiated State Modification (`realignNFT`):** Provides a specific function allowing the owner to actively interfere with the natural or flux-driven evolution, adding a layer of player/owner agency.
5.  **Staking and State Interaction (`stakeNFT`, `unstakeNFT`, `getStakingYield`, `isStaked`):** The staking mechanism is not just for yield; it *changes the rules* of the NFT's state evolution (`_calculateCurrentState` checks `isStaked`). Staking might pause decay, accelerate growth, or introduce different dynamics. This links NFT ownership/utility to active participation.
6.  **State Update on Transfer (`_beforeTokenTransfer` hook):** This is a crucial, slightly advanced ERC721 pattern for dynamic NFTs. By overriding `_beforeTokenTransfer`, we ensure that the NFT's state is *always* updated to its current value based on time elapsed just before it's transferred or its staking status changes. This prevents state changes from being skipped if an NFT is transferred multiple times without being explicitly updated.
7.  **Parameterized Evolution:** Global parameters (`_decayRate`, `_growthRate`, `_fluxImpactFactor` etc.) are stored on-chain and controlled by the admin, allowing for tuning and balancing the entire collection's evolutionary dynamics post-deployment.

This contract provides a framework for NFTs that are not static JPEGs but living, evolving digital assets influenced by multiple factors.