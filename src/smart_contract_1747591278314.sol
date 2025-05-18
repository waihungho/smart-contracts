Okay, let's design a smart contract that goes beyond basic NFTs, introducing concepts like dynamic state, resource management, interconnectedness, and lifecycle events.

We'll create "Quantum Entangled NFTs" (QENFTs). These NFTs aren't static JPEGs; they have dynamic states (`Dormant`, `Active`, `Critical`), a depletable `Quantum Energy` resource, an `Entanglement Level`, and can form bidirectional "entangled pairs" with other QENFTs. Actions on one token can affect its entangled partner. Tokens can be upgraded, refilled, fused into new tokens, and have complex state transitions based on their attributes.

This concept integrates dynamic state, resource management, conditional logic, and interconnectedness, going beyond typical static or simple dynamic NFTs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title QuantumEntangledNFTs
 * @dev An advanced ERC721 implementation featuring dynamic states, quantum energy,
 * entanglement mechanics between tokens, upgrades, fusion, and state transitions.
 *
 * Outline:
 * 1. Inherits ERC721Enumerable, ERC721Pausable, Ownable, ReentrancyGuard.
 * 2. Defines custom states (Dormant, Active, Critical).
 * 3. Tracks dynamic attributes per token: state, quantum energy, entanglement level, upgrade level.
 * 4. Manages bidirectional entanglement pairs between tokens.
 * 5. Implements functions for minting, querying attributes, managing energy,
 *    entangling/disentangling tokens, synchronizing entangled tokens, upgrading,
 *    fusing tokens (burning parents, minting new child), repairing, and handling burns.
 * 6. Includes owner-controlled parameters for costs and thresholds.
 * 7. Utilizes internal helper functions for state transitions and attribute updates.
 *
 * Function Summary:
 * --- Standard ERC721/Extensions ---
 * 1. constructor(string name, string symbol): Initializes ERC721, Pausable, Ownable.
 * 2. supportsInterface(bytes4 interfaceId): Standard ERC721/Enumerable/Pausable interface support.
 * 3. balanceOf(address owner): Standard ERC721 function.
 * 4. ownerOf(uint256 tokenId): Standard ERC721 function.
 * 5. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Standard ERC721 function (overridden for entanglement check).
 * 6. safeTransferFrom(address from, address to, uint256 tokenId): Standard ERC721 function (overridden for entanglement check).
 * 7. transferFrom(address from, address to, uint256 tokenId): Standard ERC721 function (overridden for entanglement check).
 * 8. approve(address to, uint256 tokenId): Standard ERC721 function.
 * 9. setApprovalForAll(address operator, bool approved): Standard ERC721 function.
 * 10. getApproved(uint256 tokenId): Standard ERC721 function.
 * 11. isApprovedForAll(address owner, address operator): Standard ERC721 function.
 * 12. totalSupply(): Standard ERC721Enumerable function.
 * 13. tokenByIndex(uint256 index): Standard ERC721Enumerable function.
 * 14. tokenOfOwnerByIndex(address owner, uint256 index): Standard ERC721Enumerable function.
 * 15. pause(): Pauses contract operations (Owner only).
 * 16. unpause(): Unpauses contract operations (Owner only).
 *
 * --- Custom Attributes & State ---
 * 17. TokenState enum: Defines the possible states of a QENFT.
 * 18. getTokenState(uint256 tokenId): Gets the current state of a token.
 * 19. getQuantumEnergy(uint256 tokenId): Gets the current quantum energy of a token.
 * 20. getEntanglementLevel(uint256 tokenId): Gets the current entanglement level of a token.
 * 21. getUpgradeLevel(uint256 tokenId): Gets the current upgrade level of a token.
 * 22. getEntangledToken(uint256 tokenId): Gets the ID of the token entangled with the given one, or 0 if not entangled.
 * 23. isEntangled(uint256 tokenId): Checks if a token is currently entangled.
 *
 * --- Minting & Lifecycle ---
 * 24. mintWithInitialState(address to): Mints a new token to an address with default initial state and attributes.
 * 25. fuseAndMintNew(uint256 tokenId1, uint256 tokenId2): Burns two tokens and mints a new one, potentially inheriting boosted attributes. Requires ownership of both, costs Ether.
 * 26. mutateStateIfConditionsMet(uint256 tokenId): Public function (potentially for keeper bots) to trigger state transitions based on current attributes.
 * 27. repairToken(uint256 tokenId): Allows owner to repair a Critical state token to Dormant state. Costs Ether.
 * 28. burnEntangled(uint256 tokenId): Allows owner to burn a token and negatively impact its entangled partner.
 * 29. disentangleAndBurnPair(uint256 tokenId): Allows owner to burn both tokens in an entangled pair.
 *
 * --- Energy Management ---
 * 30. refillQuantumEnergy(uint256 tokenId): Allows owner to refill a token's quantum energy. Costs Ether.
 *
 * --- Entanglement Mechanics ---
 * 31. entangleTokens(uint256 tokenId1, uint256 tokenId2): Entangles two tokens owned by the same address. Costs Ether.
 * 32. disentangleTokens(uint256 tokenId): Disentangles a token from its partner. Can be done by the owner of either token. Reduces entanglement.
 * 33. synchronizeEntangled(uint256 tokenId): Performs a synchronization action between entangled tokens, potentially boosting entanglement level but consuming energy from both. Requires token to be Active.
 *
 * --- Upgrades ---
 * 34. upgradeToken(uint256 tokenId): Allows owner to upgrade a token, increasing its upgrade level and potentially max attributes. Costs Ether, consumes energy.
 *
 * --- Owner & Parameter Settings ---
 * 35. setEntanglementCost(uint256 cost): Sets the Ether cost for entangling tokens.
 * 36. setEnergyRefillCost(uint256 cost): Sets the Ether cost for refilling energy.
 * 37. setUpgradeCost(uint256 cost): Sets the Ether cost for upgrading.
 * 38. setFuseCost(uint256 cost): Sets the Ether cost for fusing.
 * 39. setRepairCost(uint256 cost): Sets the Ether cost for repairing.
 * 40. setBurnImpactPercentage(uint256 impactPercent): Sets the percentage of attribute loss for the entangled partner when one token is burned.
 * 41. setStateTransitionThresholds(uint256 criticalEnergy, uint256 activeEnergy, uint256 activeEntanglement): Sets the thresholds for state changes.
 * 42. setMaxEnergy(uint256 max): Sets the global maximum quantum energy for tokens (can be modified per token by upgrades).
 * 43. setMaxEntanglementLevel(uint256 max): Sets the global maximum entanglement level.
 * 44. withdrawEther(): Allows owner to withdraw accumulated Ether from costs.
 *
 * --- Internal Helpers ---
 * 45. _updateTokenState(uint256 tokenId): Internal function to update a token's state based on its attributes and thresholds.
 * 46. _applyBurnImpact(uint256 tokenId): Internal function to apply the negative impact to a token's attributes.
 * 47. _burn(uint256 tokenId): Overrides the standard _burn to handle disentanglement and state updates before burning.
 * 48. _transfer(address from, address to, uint256 tokenId): Overrides standard _transfer to handle entanglement checks.
 */
contract QuantumEntangledNFTs is ERC721Enumerable, ERC721Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Custom States ---
    enum TokenState {
        Dormant,
        Active,
        Critical,
        Fused // State for tokens that were created by fusion (optional, or could just start Dormant)
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => TokenState) private _tokenState;
    mapping(uint256 => uint256) private _tokenQuantumEnergy;
    mapping(uint256 => uint256) private _tokenEntanglementLevel;
    mapping(uint256 => uint256) private _tokenUpgradeLevel;
    mapping(uint256 => uint256) private _entangledPairs; // tokenId => entangledPartnerId (0 if not entangled)

    // --- Configuration Parameters (Owner controlled) ---
    uint256 public entanglementCost = 0.01 ether;
    uint256 public energyRefillCost = 0.005 ether;
    uint256 public upgradeCost = 0.02 ether;
    uint256 public fuseCost = 0.05 ether;
    uint256 public repairCost = 0.015 ether;

    uint256 public burnImpactPercentage = 50; // % attribute loss for entangled partner
    uint256 public entanglementGainPerSync = 5; // Amount of entanglement added per sync
    uint256 public energyConsumptionPerSync = 10; // Amount of energy consumed per sync (per token)
    uint256 public energyConsumptionPerUpgrade = 20; // Amount of energy consumed per upgrade

    // State transition thresholds
    uint256 public criticalEnergyThreshold = 20;
    uint256 public activeEnergyThreshold = 60;
    uint256 public activeEntanglementThreshold = 50;

    uint256 public maxQuantumEnergy = 100; // Base max energy
    uint256 public maxEntanglementLevel = 100; // Base max entanglement level

    // --- Events ---
    event TokenStateChanged(uint256 indexed tokenId, TokenState newState, TokenState oldState);
    event QuantumEnergyChanged(uint256 indexed tokenId, uint256 newEnergy, uint256 oldEnergy);
    event EntanglementLevelChanged(uint256 indexed tokenId, uint256 newLevel, uint256 oldLevel);
    event TokenUpgraded(uint256 indexed tokenId, uint256 newLevel);
    event TokensEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event TokensDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntangledSyncPerformed(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event TokensFused(uint256 indexed parentId1, uint256 indexed parentId2, uint256 indexed newChildId);
    event TokenRepaired(uint256 indexed tokenId);
    event TokenBurnImpactApplied(uint256 indexed tokenId, uint256 impactAmount);

    // --- Modifiers ---
    modifier onlyTokenOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "QENFT: Caller is not token owner or approved");
        _;
    }

    modifier onlyEntangledPair(uint256 tokenId1, uint256 tokenId2) {
        require(isEntangled(tokenId1) && _entangledPairs[tokenId1] == tokenId2 && _entangledPairs[tokenId2] == tokenId1, "QENFT: Tokens are not entangled with each other");
        _;
    }

    modifier notEntangled(uint256 tokenId) {
        require(!isEntangled(tokenId), "QENFT: Token is entangled");
        _;
    }

    modifier canBeEntangled(uint256 tokenId) {
        TokenState state = _tokenState[tokenId];
        require(state == TokenState.Dormant || state == TokenState.Active, "QENFT: Token state prevents entanglement");
        _;
    }

    modifier canPerformAction(uint256 tokenId) {
        TokenState state = _tokenState[tokenId];
        require(state == TokenState.Dormant || state == TokenState.Active, "QENFT: Token state prevents action");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        ERC721Pausable(address(this)) // Pausable controlled by contract owner
        Ownable(_msgSender()) // Owner is deployer
        ReentrancyGuard()
    {}

    // --- Standard ERC721/Extensions Overrides ---

    // Pausable overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Transfer overrides to handle entanglement
    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        // If token is entangled, disentangle it first on transfer
        uint256 entangledPartnerId = _entangledPairs[tokenId];
        if (entangledPartnerId != 0) {
             _disentangleTokens(tokenId, entangledPartnerId);
             // Note: Disentanglement reduces entanglement, state might change.
             // mutateStateIfConditionsMet will be called internally.
        }
        super._transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721, ERC721Enumerable) whenNotPaused {
        // _transfer handles the entanglement logic
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721, ERC721Enumerable) whenNotPaused {
        // _transfer handles the entanglement logic
        super.safeTransferFrom(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721, ERC721Enumerable) whenNotPaused {
        // _transfer handles the entanglement logic
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Burn override to handle disentanglement and partner impact
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        uint256 entangledPartnerId = _entangledPairs[tokenId];
        if (entangledPartnerId != 0) {
            // Disentangle before burning
             _disentangleTokens(tokenId, entangledPartnerId);
             // Apply negative impact to the partner
            _applyBurnImpact(entangledPartnerId);
        }
        super._burn(tokenId);
    }

    // --- Custom Getters ---

    function getTokenState(uint256 tokenId) public view returns (TokenState) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _tokenState[tokenId];
    }

    function getQuantumEnergy(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _tokenQuantumEnergy[tokenId];
    }

    function getEntanglementLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _tokenEntanglementLevel[tokenId];
    }

    function getUpgradeLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _tokenUpgradeLevel[tokenId];
    }

    function getEntangledToken(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _entangledPairs[tokenId];
    }

    function isEntangled(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _entangledPairs[tokenId] != 0;
    }

    // --- Minting & Lifecycle ---

    function mintWithInitialState(address to) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);

        _tokenState[newTokenId] = TokenState.Dormant;
        _tokenQuantumEnergy[newTokenId] = maxQuantumEnergy; // Start with full energy
        _tokenEntanglementLevel[newTokenId] = 0;
        _tokenUpgradeLevel[newTokenId] = 0;
        _entangledPairs[newTokenId] = 0; // Not entangled initially

        emit TokenStateChanged(newTokenId, TokenState.Dormant, TokenState.Dormant);
        emit QuantumEnergyChanged(newTokenId, maxQuantumEnergy, 0);
        emit EntanglementLevelChanged(newTokenId, 0, 0);
        emit TokenUpgraded(newTokenId, 0);

        return newTokenId;
    }

    function fuseAndMintNew(uint256 tokenId1, uint256 tokenId2)
        public payable
        nonReentrant
        whenNotPaused
        onlyTokenOwner(tokenId1) // Requires owner of token1...
    {
        // ...and owner of token2 must be the same address
        require(_isApprovedOrOwner(_msgSender(), tokenId2), "QENFT: Caller must own both tokens");
        require(tokenId1 != tokenId2, "QENFT: Cannot fuse a token with itself");
        require(!isEntangled(tokenId1), "QENFT: Token 1 is entangled");
        require(!isEntangled(tokenId2), "QENFT: Token 2 is entangled");
        require(_tokenState[tokenId1] != TokenState.Critical && _tokenState[tokenId1] != TokenState.Fused, "QENFT: Token 1 state prevents fusion");
        require(_tokenState[tokenId2] != TokenState.Critical && _tokenState[tokenId2] != TokenState.Fused, "QENFT: Token 2 state prevents fusion");

        require(msg.value >= fuseCost, "QENFT: Insufficient payment for fusion");

        uint256 currentTokenId1Energy = _tokenQuantumEnergy[tokenId1];
        uint256 currentTokenId2Energy = _tokenQuantumEnergy[tokenId2];
        uint256 currentTokenId1Upgrade = _tokenUpgradeLevel[tokenId1];
        uint256 currentTokenId2Upgrade = _tokenUpgradeLevel[tokenId2];

        // Burn parent tokens BEFORE minting new one
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint new token
        _tokenIdCounter.increment();
        uint256 newChildTokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), newChildTokenId);

        // Calculate attributes for the new token (example logic: average + bonus)
        uint256 newEnergy = (currentTokenId1Energy.add(currentTokenId2Energy)).div(2).add(maxQuantumEnergy.div(10)); // Average energy + 10% bonus
        uint256 newUpgradeLevel = (currentTokenId1Upgrade.add(currentTokenId2Upgrade)).div(2).add(1); // Average upgrade + 1 level

        _tokenState[newChildTokenId] = TokenState.Dormant; // New token starts Dormant
        _tokenQuantumEnergy[newChildTokenId] = newEnergy > maxQuantumEnergy ? maxQuantumEnergy : newEnergy; // Cap energy
        _tokenEntanglementLevel[newChildTokenId] = 0; // Not entangled initially
        _tokenUpgradeLevel[newChildTokenId] = newUpgradeLevel;
        _entangledPairs[newChildTokenId] = 0;

        emit TokensFused(tokenId1, tokenId2, newChildTokenId);
        emit TokenStateChanged(newChildTokenId, TokenState.Dormant, TokenState.Dormant);
        emit QuantumEnergyChanged(newChildTokenId, _tokenQuantumEnergy[newChildTokenId], 0);
        emit EntanglementLevelChanged(newChildTokenId, 0, 0);
        emit TokenUpgraded(newChildTokenId, newUpgradeLevel);

        // Refund any excess Ether
        if (msg.value > fuseCost) {
            payable(_msgSender()).transfer(msg.value - fuseCost);
        }
    }

    function mutateStateIfConditionsMet(uint256 tokenId) public whenNotPaused {
         require(_exists(tokenId), "QENFT: Token does not exist");
         _updateTokenState(tokenId);
    }

    function repairToken(uint256 tokenId)
        public payable
        nonReentrant
        whenNotPaused
        onlyTokenOwner(tokenId)
    {
        require(_tokenState[tokenId] == TokenState.Critical, "QENFT: Token is not in Critical state");
        require(msg.value >= repairCost, "QENFT: Insufficient payment for repair");

        // Refund any excess Ether
        if (msg.value > repairCost) {
            payable(_msgSender()).transfer(msg.value - repairCost);
        }

        // Repairing brings it back to Dormant
        _tokenState[tokenId] = TokenState.Dormant;
        emit TokenStateChanged(tokenId, TokenState.Dormant, TokenState.Critical);

         // After repair, state might change again if conditions are met (e.g., energy is still low)
        _updateTokenState(tokenId);
    }


    function burnEntangled(uint256 tokenId)
        public payable
        nonReentrant
        whenNotPaused
        onlyTokenOwner(tokenId)
    {
        require(isEntangled(tokenId), "QENFT: Token is not entangled");
        uint256 entangledPartnerId = _entangledPairs[tokenId];

        // Note: _burn is overridden to handle disentanglement and partner impact
        _burn(tokenId);

        // Partner impact and disentanglement already handled in _burn
        emit TokenBurnImpactApplied(entangledPartnerId, burnImpactPercentage);
    }

    function disentangleAndBurnPair(uint256 tokenId)
         public payable
        nonReentrant
        whenNotPaused
        onlyTokenOwner(tokenId)
    {
         require(isEntangled(tokenId), "QENFT: Token is not entangled");
         uint256 entangledPartnerId = _entangledPairs[tokenId];

         // Burn both tokens (disentanglement is handled by _burn override)
         _burn(tokenId);
         // Check partner still exists before burning (should, unless already burned by other means)
         if(_exists(entangledPartnerId)) {
             _burn(entangledPartnerId);
         }
    }


    // --- Energy Management ---

    function refillQuantumEnergy(uint256 tokenId)
        public payable
        nonReentrant
        whenNotPaused
        onlyTokenOwner(tokenId)
        canPerformAction(tokenId) // Cannot refill Critical or Fused (Fused don't exist)
    {
        require(msg.value >= energyRefillCost, "QENFT: Insufficient payment for energy refill");

        // Refund any excess Ether
        if (msg.value > energyRefillCost) {
            payable(_msgSender()).transfer(msg.value - energyRefillCost);
        }

        uint256 oldEnergy = _tokenQuantumEnergy[tokenId];
        _tokenQuantumEnergy[tokenId] = maxQuantumEnergy; // Refill to max

        emit QuantumEnergyChanged(tokenId, _tokenQuantumEnergy[tokenId], oldEnergy);

        // State might change after refilling energy
        _updateTokenState(tokenId);
    }

    // --- Entanglement Mechanics ---

    function entangleTokens(uint256 tokenId1, uint256 tokenId2)
        public payable
        nonReentrant
        whenNotPaused
        onlyTokenOwner(tokenId1) // Requires owner of token1...
    {
        // ...and owner of token2 must be the same address
        require(_isApprovedOrOwner(_msgSender(), tokenId2), "QENFT: Caller must own both tokens");
        require(tokenId1 != tokenId2, "QENFT: Cannot entangle a token with itself");
        require(!isEntangled(tokenId1), "QENFT: Token 1 is already entangled");
        require(!isEntangled(tokenId2), "QENFT: Token 2 is already entangled");
        require(canBeEntangled(tokenId1), "QENFT: Token 1 state prevents entanglement");
        require(canBeEntangled(tokenId2), "QENFT: Token 2 state prevents entanglement");

        require(msg.value >= entanglementCost, "QENFT: Insufficient payment for entanglement");

        // Refund any excess Ether
        if (msg.value > entanglementCost) {
            payable(_msgSender()).transfer(msg.value - entanglementCost);
        }

        _entangledPairs[tokenId1] = tokenId2;
        _entangledPairs[tokenId2] = tokenId1;

        // Initial entanglement level increase
        uint256 oldLevel1 = _tokenEntanglementLevel[tokenId1];
        uint256 oldLevel2 = _tokenEntanglementLevel[tokenId2];
        _tokenEntanglementLevel[tokenId1] = _tokenEntanglementLevel[tokenId1].add(entanglementGainPerSync);
        _tokenEntanglementLevel[tokenId2] = _tokenEntanglementLevel[tokenId2].add(entanglementGainPerSync);

         _tokenEntanglementLevel[tokenId1] = _tokenEntanglementLevel[tokenId1] > maxEntanglementLevel ? maxEntanglementLevel : _tokenEntanglementLevel[tokenId1];
         _tokenEntanglementLevel[tokenId2] = _tokenEntanglementLevel[tokenId2] > maxEntanglementLevel ? maxEntanglementLevel : _tokenEntanglementLevel[tokenId2];


        emit TokensEntangled(tokenId1, tokenId2);
        emit EntanglementLevelChanged(tokenId1, _tokenEntanglementLevel[tokenId1], oldLevel1);
        emit EntanglementLevelChanged(tokenId2, _tokenEntanglementLevel[tokenId2], oldLevel2);

        // State might change after entanglement
        _updateTokenState(tokenId1);
        _updateTokenState(tokenId2);
    }

    // Internal helper for disentanglement logic
    function _disentangleTokens(uint256 tokenId1, uint256 tokenId2) internal {
        _entangledPairs[tokenId1] = 0;
        _entangledPairs[tokenId2] = 0;

        // Entanglement level reduction on disentanglement (example: halve it)
        uint256 oldLevel1 = _tokenEntanglementLevel[tokenId1];
        uint256 oldLevel2 = _tokenEntanglementLevel[tokenId2];
        _tokenEntanglementLevel[tokenId1] = _tokenEntanglementLevel[tokenId1].div(2);
        _tokenEntanglementLevel[tokenId2] = _tokenEntanglementLevel[tokenId2].div(2);

        emit TokensDisentangled(tokenId1, tokenId2);
        emit EntanglementLevelChanged(tokenId1, _tokenEntanglementLevel[tokenId1], oldLevel1);
        emit EntanglementLevelChanged(tokenId2, _tokenEntanglementLevel[tokenId2], oldLevel2);

         // State might change after disentanglement
        _updateTokenState(tokenId1);
        _updateTokenState(tokenId2);
    }

    function disentangleTokens(uint256 tokenId)
        public
        whenNotPaused
        onlyTokenOwner(tokenId)
    {
         require(isEntangled(tokenId), "QENFT: Token is not entangled");
         uint256 entangledPartnerId = _entangledPairs[tokenId];
         _disentangleTokens(tokenId, entangledPartnerId);
    }


    function synchronizeEntangled(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        onlyTokenOwner(tokenId)
        canPerformAction(tokenId) // Cannot sync if Critical or Fused
    {
        require(isEntangled(tokenId), "QENFT: Token is not entangled");
        require(_tokenState[tokenId] == TokenState.Active, "QENFT: Token must be in Active state to synchronize");

        uint256 tokenId1 = tokenId;
        uint256 tokenId2 = _entangledPairs[tokenId1];

        require(_tokenState[tokenId2] == TokenState.Active, "QENFT: Entangled partner must also be in Active state to synchronize");

        uint256 energy1 = _tokenQuantumEnergy[tokenId1];
        uint256 energy2 = _tokenQuantumEnergy[tokenId2];

        // Require sufficient energy in *both* tokens
        require(energy1 >= energyConsumptionPerSync, "QENFT: Insufficient energy in Token 1");
        require(energy2 >= energyConsumptionPerSync, "QENFT: Insufficient energy in Token 2");

        // Consume energy from both
        uint256 oldEnergy1 = _tokenQuantumEnergy[tokenId1];
        uint256 oldEnergy2 = _tokenQuantumEnergy[tokenId2];
        _tokenQuantumEnergy[tokenId1] = energy1.sub(energyConsumptionPerSync);
        _tokenQuantumEnergy[tokenId2] = energy2.sub(energyConsumptionPerSync);

        emit QuantumEnergyChanged(tokenId1, _tokenQuantumEnergy[tokenId1], oldEnergy1);
        emit QuantumEnergyChanged(tokenId2, _tokenQuantumEnergy[tokenId2], oldEnergy2);

        // Increase entanglement level (capped at max)
        uint256 oldLevel1 = _tokenEntanglementLevel[tokenId1];
        uint256 oldLevel2 = _tokenEntanglementLevel[tokenId2];
        _tokenEntanglementLevel[tokenId1] = _tokenEntanglementLevel[tokenId1].add(entanglementGainPerSync);
        _tokenEntanglementLevel[tokenId2] = _tokenEntanglementLevel[tokenId2].add(entanglementGainPerSync);

        _tokenEntanglementLevel[tokenId1] = _tokenEntanglementLevel[tokenId1] > maxEntanglementLevel ? maxEntanglementLevel : _tokenEntanglementLevel[tokenId1];
        _tokenEntanglementLevel[tokenId2] = _tokenEntanglementLevel[tokenId2] > maxEntanglementLevel ? maxEntanglementLevel : _tokenEntanglementLevel[tokenId2];

        emit EntangledSyncPerformed(tokenId1, tokenId2);
        emit EntanglementLevelChanged(tokenId1, _tokenEntanglementLevel[tokenId1], oldLevel1);
        emit EntanglementLevelChanged(tokenId2, _tokenEntanglementLevel[tokenId2], oldLevel2);

        // States might change after consuming energy
        _updateTokenState(tokenId1);
        _updateTokenState(tokenId2);
    }

    // --- Upgrades ---

    function upgradeToken(uint256 tokenId)
        public payable
        nonReentrant
        whenNotPaused
        onlyTokenOwner(tokenId)
        canPerformAction(tokenId) // Cannot upgrade if Critical or Fused
    {
        require(_tokenQuantumEnergy[tokenId] >= energyConsumptionPerUpgrade, "QENFT: Insufficient energy for upgrade");
        require(msg.value >= upgradeCost, "QENFT: Insufficient payment for upgrade");

        // Refund any excess Ether
        if (msg.value > upgradeCost) {
            payable(_msgSender()).transfer(msg.value - upgradeCost);
        }

        // Consume energy
        uint256 oldEnergy = _tokenQuantumEnergy[tokenId];
        _tokenQuantumEnergy[tokenId] = oldEnergy.sub(energyConsumptionPerUpgrade);
        emit QuantumEnergyChanged(tokenId, _tokenQuantumEnergy[tokenId], oldEnergy);

        // Increase upgrade level
        uint256 oldUpgradeLevel = _tokenUpgradeLevel[tokenId];
        _tokenUpgradeLevel[tokenId] = oldUpgradeLevel.add(1);

        emit TokenUpgraded(tokenId, _tokenUpgradeLevel[tokenId]);

        // State might change after consuming energy
        _updateTokenState(tokenId);

        // Note: Upgrade logic could make token attributes better (e.g., higher max energy/entanglement)
        // This would require storing max attributes per token based on upgrade level,
        // which adds complexity. For this example, we just increase the level counter.
        // The logic to *use* the upgrade level (e.g., in state transitions or action effects)
        // would need to be added in relevant functions (_updateTokenState, synchronizeEntangled, etc.)
    }

    // --- Owner & Parameter Settings ---

    function setEntanglementCost(uint256 cost) public onlyOwner {
        entanglementCost = cost;
    }

    function setEnergyRefillCost(uint256 cost) public onlyOwner {
        energyRefillCost = cost;
    }

    function setUpgradeCost(uint256 cost) public onlyOwner {
        upgradeCost = cost;
    }

    function setFuseCost(uint256 cost) public onlyOwner {
        fuseCost = cost;
    }

    function setRepairCost(uint256 cost) public onlyOwner {
        repairCost = cost;
    }

    function setBurnImpactPercentage(uint256 impactPercent) public onlyOwner {
        require(impactPercent <= 100, "QENFT: Impact percentage cannot exceed 100");
        burnImpactPercentage = impactPercent;
    }

    function setStateTransitionThresholds(uint256 criticalEnergy, uint256 activeEnergy, uint256 activeEntanglement) public onlyOwner {
        criticalEnergyThreshold = criticalEnergy;
        activeEnergyThreshold = activeEnergy;
        activeEntanglementThreshold = activeEntanglement;
    }

    function setMaxEnergy(uint256 max) public onlyOwner {
        maxQuantumEnergy = max;
    }

    function setMaxEntanglementLevel(uint256 max) public onlyOwner {
        maxEntanglementLevel = max;
    }

    function withdrawEther() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "QENFT: No Ether to withdraw");
        payable(owner()).transfer(balance);
    }

    // --- Internal Helper Functions ---

    function _updateTokenState(uint256 tokenId) internal {
        require(_exists(tokenId), "QENFT: Token does not exist");

        TokenState currentState = _tokenState[tokenId];
        TokenState newState = currentState; // Assume no change initially

        uint256 currentEnergy = _tokenQuantumEnergy[tokenId];
        uint256 currentEntanglement = _tokenEntanglementLevel[tokenId];

        if (currentState == TokenState.Fused) {
            // Fused tokens have a final state and don't change
            return;
        }

        if (currentState == TokenState.Critical) {
            // Only way out of Critical is Repair or sufficient Refill
            if (currentEnergy >= criticalEnergyThreshold) {
                 // Move to Dormant if energy is sufficient (Repair also calls this)
                 newState = TokenState.Dormant;
            }
        } else { // Current state is Dormant or Active
            if (currentEnergy < criticalEnergyThreshold) {
                newState = TokenState.Critical;
            } else if (currentEnergy >= activeEnergyThreshold && currentEntanglement >= activeEntanglementThreshold) {
                 // Need to be entangled and have high energy/entanglement to be Active
                 if (isEntangled(tokenId)) {
                     newState = TokenState.Active;
                 } else {
                     // Can't be Active if not entangled, even with high stats
                     newState = TokenState.Dormant;
                 }
            } else {
                // Default to Dormant if not Critical and conditions for Active not met
                newState = TokenState.Dormant;
            }
        }

        if (newState != currentState) {
            _tokenState[tokenId] = newState;
            emit TokenStateChanged(tokenId, newState, currentState);
        }
    }

    function _applyBurnImpact(uint256 tokenId) internal {
        // This is called on the *partner* when one token in an entangled pair is burned.
        require(_exists(tokenId), "QENFT: Token does not exist");

        uint256 oldEnergy = _tokenQuantumEnergy[tokenId];
        uint256 oldEntanglement = _tokenEntanglementLevel[tokenId];

        // Calculate impact
        uint256 energyLoss = oldEnergy.mul(burnImpactPercentage).div(100);
        uint256 entanglementLoss = oldEntanglement.mul(burnImpactPercentage).div(100);

        // Apply impact
        _tokenQuantumEnergy[tokenId] = oldEnergy.sub(energyLoss);
        _tokenEntanglementLevel[tokenId] = oldEntanglement.sub(entanglementLoss);

        emit QuantumEnergyChanged(tokenId, _tokenQuantumEnergy[tokenId], oldEnergy);
        emit EntanglementLevelChanged(tokenId, _tokenEntanglementLevel[tokenId], oldEntanglement);

        // The state might change significantly after this impact
        _updateTokenState(tokenId);
    }

    // Override supportsInterface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721Pausable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ERC721Enumerable overrides
     function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.totalSupply();
    }

     function tokenByIndex(uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

     function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    // Pausable owner functions
    function pause() public onlyOwner override {
        super.pause();
    }

    function unpause() public onlyOwner override {
        super.unpause();
    }
}
```

---

**Explanation of Concepts and Functions:**

1.  **Dynamic State (`TokenState` Enum):**
    *   `Dormant`: Default, relatively inactive state.
    *   `Active`: High energy and entanglement. Required for some advanced actions like `synchronizeEntangled`.
    *   `Critical`: Low energy. Cannot perform most actions (upgrade, sync, entangle). Can only be `refillQuantumEnergy` or `repairToken`.
    *   `Fused`: A state (or rather, the nature) of a token created through the `fuseAndMintNew` process.

2.  **Quantum Energy (`_tokenQuantumEnergy`):**
    *   A depletable resource specific to each token.
    *   Consumed by actions like `synchronizeEntangled` and `upgradeToken`.
    *   Refilled using `refillQuantumEnergy` (costs Ether).
    *   Its level affects state transitions (`Critical` threshold, `Active` threshold).

3.  **Entanglement Level (`_tokenEntanglementLevel`):**
    *   Represents the strength of the bond between two entangled tokens.
    *   Increases slightly upon `entangleTokens` and significantly upon successful `synchronizeEntangled`.
    *   Decreases upon `disentangleTokens` or if the partner is burned (`_applyBurnImpact`).
    *   Its level affects state transitions (`Active` threshold).

4.  **Entanglement Pairs (`_entangledPairs`):**
    *   A mapping that links two token IDs together bidirectionally.
    *   Created by `entangleTokens`.
    *   Broken by `disentangleTokens` or if either token is burned (`_burn` override).
    *   Transferring an entangled token automatically triggers `_disentangleTokens`.

5.  **Lifecycle and Interactions:**
    *   **Minting:** `mintWithInitialState` creates new tokens with default attributes.
    *   **Fusion (`fuseAndMintNew`):** A complex process where two parent tokens are burned, and a *new* child token is minted. The child token can inherit or combine attributes from the parents, making it potentially more powerful. This creates a form of breeding or evolution.
    *   **Upgrading (`upgradeToken`):** Increases a token's `_tokenUpgradeLevel`. This could be used *off-chain* to unlock new visual traits or *on-chain* to affect max attribute caps or action effectiveness (though the provided code only tracks the level).
    *   **Synchronization (`synchronizeEntangled`):** A key action for `Active` entangled tokens. It consumes energy from *both* tokens to significantly boost their shared `Entanglement Level`.
    *   **Repair (`repairToken`):** Allows a `Critical` token to be brought back to a manageable state (`Dormant`).
    *   **Burn Impact (`burnEntangled`, `_applyBurnImpact`):** Burning one token in an entangled pair isn't consequence-free for the partner. The `_burn` override detects entanglement, calls `_disentangleTokens`, and then calls `_applyBurnImpact` on the partner, reducing its energy and entanglement level. This can potentially push the partner into a `Critical` state.
    *   **Burn Pair (`disentangleAndBurnPair`):** Allows burning both tokens in an entangled pair simultaneously.

6.  **State Transitions (`mutateStateIfConditionsMet`, `_updateTokenState`):**
    *   The `_updateTokenState` internal function checks a token's current `_tokenQuantumEnergy` and `_tokenEntanglementLevel` against defined thresholds to determine its new state.
    *   This function is called internally after actions that change energy or entanglement (sync, refill, disentangle, burn impact, upgrade).
    *   `mutateStateIfConditionsMet` provides a public entry point (potentially for an external bot or service) to ensure token states are up-to-date even if no owner action has recently occurred.

7.  **Resource Costs:**
    *   Most state-changing or beneficial actions (entangle, refill, upgrade, fuse, repair) require an Ether payment, which is collected by the contract and can be withdrawn by the owner (`withdrawEther`). This introduces an economic model.

8.  **Standard ERC721/Extensions:**
    *   Inherits `ERC721Enumerable` to allow iterating through all tokens.
    *   Inherits `ERC721Pausable` for emergency pausing (controlled by `Ownable`).
    *   Inherits `Ownable` for administrative functions.
    *   Overrides `_beforeTokenTransfer`, `_transfer`, and `_burn` to incorporate custom logic related to entanglement and state before standard ERC721 operations occur.
    *   Uses `ReentrancyGuard` on `payable` functions to prevent reentrancy attacks.

This contract provides a rich set of interactions and states for NFTs, making them dynamic assets rather than static collectibles. The entanglement mechanic, resource management, state transitions, and fusion add layers of complexity and potential for gaming, narrative, or unique collecting experiences.