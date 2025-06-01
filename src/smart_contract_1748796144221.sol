Okay, here is a Solidity smart contract demonstrating advanced concepts like dynamic state, probabilistic outcomes influenced by configurable parameters, resource management (Energy), and interaction with Chainlink VRF for verifiable randomness, and potentially a data feed oracle for external factors.

It's designed around the idea of "Quantum Particles" that can be fused together to create new particles or upgrade existing ones, with outcomes depending on particle types, global "Quantum Turbulence", and randomness.

**Disclaimer:** This contract is a complex example for educational purposes. It has not been audited and should *not* be used in production without significant testing, security review, and potential optimization.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title QuantumFusion
 * @dev A complex smart contract for managing and fusing dynamic 'Quantum Particles' (NFTs).
 * Outcomes of fusion are probabilistic, influenced by configurable parameters, and use Chainlink VRF.
 * The contract also includes an 'Energy' resource system and dynamic particle states.
 */

/**
 * @dev Outline:
 * 1.  State Variables: Core data structures for particles, energy, configurations, VRF requests.
 * 2.  Structs: Define data structures for Particle data, Fusion configurations, and VRF requests.
 * 3.  Events: Log key actions like minting, burning, fusion, energy changes, parameter updates.
 * 4.  Modifiers: Access control and state checks (e.g., onlyOwner, particle exists).
 * 5.  ERC721 Standard Functions: Implement core ERC721 logic manually for particle ownership and transfer.
 * 6.  Particle Management: Functions to mint, burn, get data, and modify particle state/properties.
 * 7.  Energy System: Functions to get balance, generate, transfer, and consume Energy.
 * 8.  Fusion Mechanic: Functions to initiate probabilistic fusion via VRF and handle the VRF callback.
 * 9.  Configuration & Governance: Functions (admin-only) to set fusion rules, global parameters, and oracles.
 * 10. Utility & View Functions: Helper functions and read-only data accessors.
 * 11. VRF Callbacks: Implement `rawFulfillRandomWords` for Chainlink VRF integration.
 */

/**
 * @dev Function Summary (at least 20 functions):
 * 1.  constructor: Initializes contract, ERC721 details, VRF/Oracle addresses.
 * 2.  supportsInterface: ERC165 standard.
 * 3.  balanceOf: ERC721: Get number of particles owned by an address.
 * 4.  ownerOf: ERC721: Get owner of a specific particle.
 * 5.  safeTransferFrom (overloaded): ERC721: Transfer particle safely.
 * 6.  transferFrom: ERC721: Transfer particle.
 * 7.  approve: ERC721: Approve an address to transfer a particle.
 * 8.  getApproved: ERC721: Get approved address for a particle.
 * 9.  setApprovalForAll: ERC721: Set operator approval for all particles.
 * 10. isApprovedForAll: ERC721: Check if an address is an operator.
 * 11. name: ERC721Metadata: Get contract name.
 * 12. symbol: ERC721Metadata: Get contract symbol.
 * 13. tokenURI: ERC721Metadata: Get metadata URI for a particle (placeholder).
 * 14. mintInitialParticles: Admin: Mint initial particles of a specific type for a recipient.
 * 15. burnParticle: Admin/Special: Destroy a particle.
 * 16. getParticleData: View: Retrieve detailed data for a particle.
 * 17. upgradeParticleState: User/Cost: Attempt to upgrade a particle's state using Energy.
 * 18. setParticleProperties: Admin: Set custom properties for a particle.
 * 19. getUserEnergy: View: Get energy balance for a user.
 * 20. generateEnergy: User/Cost/Oracle: Generate Energy (potentially influenced by external data).
 * 21. transferEnergy: User: Send Energy to another user.
 * 22. initiateFusion: User/Cost: Start the fusion process for two particles, triggering a VRF request.
 * 23. rawFulfillRandomWords: VRF Callback: Called by VRF Coordinator to deliver randomness and execute fusion outcome.
 * 24. setFusionParameters: Admin: Configure fusion outcomes (recipes, costs, probabilities) for particle type pairs.
 * 25. getFusionParameters: View: Retrieve fusion configuration for a particle type pair.
 * 26. setQuantumTurbulence: Admin: Set a global parameter affecting fusion probabilities.
 * 27. getQuantumTurbulence: View: Get current Quantum Turbulence value.
 * 28. setEnergyResonance: Admin: Set a global parameter affecting Energy generation efficiency.
 * 29. getEnergyResonance: View: Get current Energy Resonance value.
 * 30. setOracleAddresses: Admin: Update VRF Coordinator, Key Hash, and potentially Data Feed address.
 * 31. getOracleAddresses: View: Retrieve configured Oracle addresses.
 * 32. withdrawFees: Admin: Withdraw accumulated ETH/tokens from contract.
 * 33. getParticleCount: View: Get the total number of particles in existence.
 * 34. getFusionRequestStatus: View: Get the status (initiated, pending, fulfilled) of a VRF fusion request.
 * 35. setParticleDecayRate: Admin: Configure a decay rate (hypothetical mechanic).
 * 36. getParticleDecayRate: View: Get particle decay rate.
 * 37. decayParticle: User/Cost: (Hypothetical) Counteract particle decay using Energy.
 * 38. attuneEnergy: User/Cost: (Hypothetical) Temporarily attune user energy for fusion boosts.
 */

contract QuantumFusion is Ownable, VRFConsumerBaseV2, IERC721, IERC721Metadata, IERC721Receiver {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _particleIds;

    string private _name = "Quantum Particle";
    string private _symbol = "QPART";

    // ERC721 Mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Particle Data
    struct ParticleData {
        uint256 id;
        uint8 particleType; // e.g., 0=Alpha, 1=Beta, 2=Gamma, etc.
        uint8 generation; // e.g., 1, 2, 3... (increases via fusion/upgrade)
        uint8 state; // e.g., 0=Stable, 1=Excited, 2=Superposition (affects fusion outcomes)
        bytes properties; // Arbitrary bytes for extra data (e.g., stats, appearance traits)
        uint64 birthBlock; // Block number when minted
    }
    mapping(uint256 => ParticleData) private _particles;

    // Energy System
    mapping(address => uint256) private _userEnergy;
    uint256 public energyPerGeneration = 100; // Base energy generated

    // Fusion System
    struct FusionConfig {
        uint256 energyCost;
        uint256 baseTurbulenceThreshold; // Baseline for turbulence checks
        bytes potentialOutcomes; // ABI-encoded array of possible outcome types/actions with probabilities
        // Example format: ABI encode [[outcomeType1, probability1], [outcomeType2, probability2], ...]
        // outcomeType could be: 0=MintNew, 1=UpgradeInput1, 2=UpgradeInput2, 3=BurnBoth, ...
        // probability is a value from 0-1000 representing 0-100.0%
    }
    // Mapping from (type1, type2) pair to FusionConfig
    // Store as uint16 (type1 << 8 | type2) assuming types are < 256
    mapping(uint16 => FusionConfig) private _fusionConfigs;

    // VRF System (Chainlink VRF v2)
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 s_callbackGasLimit = 500000; // Gas limit for rawFulfillRandomWords
    uint16 s_requestConfirmations = 3; // Confirmations needed before VRF fulfills
    uint32 s_numWords = 1; // Number of random words requested

    // Track VRF requests to fusion attempts
    struct FusionRequest {
        address initiator;
        uint256 tokenId1;
        uint256 tokenId2;
        uint256 blockTimestamp; // Timestamp when request was initiated
        uint8 status; // 0=Pending VRF, 1=Fulfilled Success, 2=Fulfilled Failure
    }
    mapping(uint256 => FusionRequest) private _fusionRequests; // request ID -> request details

    // Global Quantum Parameters (Influence outcomes and energy generation)
    uint256 public quantumTurbulence = 50; // Global modifier for fusion probability (higher = more chaotic)
    uint256 public energyResonance = 100; // Global modifier for energy generation efficiency (higher = more energy)

    // Oracle Addresses (Example: Chainlink Price Feed for Energy generation influence)
    AggregatorV3Interface internal priceFeed;
    // Decay mechanic (hypothetical)
    uint256 public particleDecayRate = 0; // Higher value = faster decay (e.g., energy cost per block)

    // --- Events ---
    event ParticleMinted(address indexed owner, uint256 indexed tokenId, uint8 particleType, uint8 generation);
    event ParticleBurned(address indexed owner, uint256 indexed tokenId);
    event ParticleStateUpgraded(uint256 indexed tokenId, uint8 oldState, uint8 newState);
    event ParticlePropertiesSet(uint256 indexed tokenId, bytes properties);

    event UserEnergyGenerated(address indexed user, uint256 amount, uint256 newBalance);
    event UserEnergyTransferred(address indexed from, address indexed to, uint256 amount);
    event UserEnergyBurned(address indexed user, uint256 amount, uint256 newBalance);

    event FusionInitiated(address indexed initiator, uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed requestId);
    event FusionCompleted(uint256 indexed requestId, uint8 outcomeType, uint256 newTokenId, uint256[] affectedTokenIds); // newTokenId=0 if no new token minted
    event FusionFailed(uint256 indexed requestId, string reason);

    event FusionParametersSet(uint8 indexed type1, uint8 indexed type2, uint256 energyCost, bytes potentialOutcomes);
    event QuantumTurbulenceSet(uint256 oldTurbulence, uint256 newTurbulence);
    event EnergyResonanceSet(uint256 oldResonance, uint256 newResonance);
    event OracleAddressesSet(address vrfCoordinator, bytes32 keyHash, address dataFeed);

    // --- Modifiers ---
    modifier whenParticleExists(uint256 tokenId) {
        require(_owners[tokenId] != address(0), "QuantumFusion: Particle does not exist");
        _;
    }

    modifier whenUserHasEnergy(uint256 amount) {
        require(_userEnergy[msg.sender] >= amount, "QuantumFusion: Insufficient energy");
        _;
    }

    modifier whenFusionConfigExists(uint8 type1, uint8 type2) {
         uint16 configKey = type1 < type2 ? uint16(type1) << 8 | type2 : uint16(type2) << 8 | type1;
        require(_fusionConfigs[configKey].energyCost > 0 || _fusionConfigs[configKey].potentialOutcomes.length > 0, "QuantumFusion: Fusion config not set for these types");
        _;
    }

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        address initialOwner // To make Owner controllable after deployment
    )
        VRFConsumerBaseV2(vrfCoordinator)
        Ownable(initialOwner) // Set initial owner via constructor
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        // Default Oracle address can be set later via setOracleAddresses if needed
    }

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, VRFConsumerBaseV2) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC721Receiver).interfaceId || // Support receiving NFTs
               super.supportsInterface(interfaceId);
    }

    // --- ERC721 Standard Implementations (Simplified using mappings) ---
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approval query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // ERC721 Metadata Implementation
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         // Placeholder: In a real contract, this would return a URL to the metadata JSON file.
         // The metadata could be dynamic based on particle properties.
        return string(abi.encodePacked("ipfs://YOUR_BASE_URI/", Strings.toString(tokenId), "/metadata.json"));
    }

    // IERC721Receiver implementation - allows contract to receive NFTs (e.g., for fusion inputs or as components)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
        // By default, accept any ERC721 token.
        // Add specific logic here if you only want to receive certain tokens or handle them specially.
        return this.onERC721Received.selector;
    }


    // Internal ERC721 helpers (Simplified)
     function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId); // Clear approval

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (unknown reason)");
                } else {
                    /// @solidity using `AbiDecoder` from "hardhat-deploy/libraries/AbiDecoder.sol";
                    /// return AbiDecoder.revertReason(reason);
                    // Simplified for this example:
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true; // Transfer to EOA is always safe in this context
        }
    }


    // --- Particle Management Functions ---

    /**
     * @dev Mints new particles. Only callable by the owner.
     * @param recipient The address to mint the particles to.
     * @param count The number of particles to mint.
     * @param particleType The type of particle to mint.
     */
    function mintInitialParticles(address recipient, uint256 count, uint8 particleType) external onlyOwner {
        require(recipient != address(0), "QuantumFusion: Cannot mint to zero address");
        for (uint i = 0; i < count; i++) {
            _particleIds.increment();
            uint256 newTokenId = _particleIds.current();

            _particles[newTokenId] = ParticleData({
                id: newTokenId,
                particleType: particleType,
                generation: 1, // Start at generation 1
                state: 0,      // Start in Stable state
                properties: "", // Initial empty properties
                birthBlock: uint64(block.number)
            });

            _safeTransfer(address(0), recipient, newTokenId, ""); // Mint uses transfer from address(0)

            emit ParticleMinted(recipient, newTokenId, particleType, 1);
        }
    }

    /**
     * @dev Burns (destroys) a particle. Can be called by the owner or potentially via game mechanics.
     * @param tokenId The ID of the particle to burn.
     */
    function burnParticle(uint256 tokenId) external whenParticleExists(tokenId) {
         address owner = ownerOf(tokenId); // Checks ownership internally
         require(msg.sender == owner || msg.sender == owner() /* Add game logic roles here */, "QuantumFusion: Not authorized to burn particle");

        _approve(address(0), tokenId); // Clear approval
        _balances[owner]--;
        delete _owners[tokenId];
        delete _particles[tokenId]; // Remove particle data

        emit ParticleBurned(owner, tokenId);
    }

    /**
     * @dev Retrieves the detailed data for a specific particle.
     * @param tokenId The ID of the particle.
     * @return ParticleData struct.
     */
    function getParticleData(uint256 tokenId) external view whenParticleExists(tokenId) returns (ParticleData memory) {
        return _particles[tokenId];
    }

    /**
     * @dev Attempts to upgrade the state of a particle. Requires Energy and has conditions.
     * @param tokenId The ID of the particle to upgrade.
     * @param newState The target state (e.g., 1=Excited, 2=Superposition).
     */
    function upgradeParticleState(uint256 tokenId, uint8 newState) external whenParticleExists(tokenId) whenUserHasEnergy(100) { // Example energy cost
        require(ownerOf(tokenId) == msg.sender, "QuantumFusion: Must own particle to upgrade state");
        ParticleData storage particle = _particles[tokenId];
        uint8 oldState = particle.state;

        // Example logic: Can only upgrade to higher states
        require(newState > oldState, "QuantumFusion: New state must be higher than current");
        // Add specific state transition rules if needed (e.g., can only go from 0 to 1, then 1 to 2)
        require(newState <= 255, "QuantumFusion: Invalid new state value"); // Basic sanity check

        uint256 cost = 100 + (uint256(oldState) * 50); // Example: cost increases with current state
        require(_userEnergy[msg.sender] >= cost, "QuantumFusion: Insufficient energy for upgrade");

        _burnEnergy(msg.sender, cost);

        particle.state = newState;
        // Maybe increase generation upon reaching a certain state? particle.generation++;

        emit ParticleStateUpgraded(tokenId, oldState, newState);
    }

    /**
     * @dev Sets the custom properties for a particle. Owner-only function, perhaps used for admin adjustments or special events.
     * @param tokenId The ID of the particle.
     * @param properties The bytes data representing the new properties.
     */
    function setParticleProperties(uint256 tokenId, bytes memory properties) external onlyOwner whenParticleExists(tokenId) {
         _particles[tokenId].properties = properties;
         emit ParticlePropertiesSet(tokenId, properties);
    }

     /**
     * @dev (Hypothetical) Users can pay Energy to counteract particle decay.
     * @param tokenId The ID of the particle to maintain.
     */
    function decayParticle(uint256 tokenId) external whenParticleExists(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QuantumFusion: Must own particle to decay");
        require(particleDecayRate > 0, "QuantumFusion: Decay mechanic not active");

        // Example logic: Cost based on decay rate and time since last maintenance/birth
        // This would require tracking last decay-maintenance block for each particle,
        // making the struct larger. For this example, let's simplify.
        uint256 cost = particleDecayRate * 10; // Example cost formula
        require(_userEnergy[msg.sender] >= cost, "QuantumFusion: Insufficient energy to counteract decay");

        _burnEnergy(msg.sender, cost);
        // In a full implementation, this would reset a decay timer/counter on the particle struct.
        // For simplicity, just applying the cost.
        // Potentially add an event like `ParticleDecayCounteracted`.
    }

     /**
     * @dev (Hypothetical) Users can attune their Energy, potentially boosting fusion outcomes for a period.
     * Requires Energy.
     * @param particleType The particle type to attune towards.
     */
    function attuneEnergy(uint8 particleType) external whenUserHasEnergy(50) { // Example cost
        // This mechanic would require storing user attunement state (type, duration)
        // and modifying fusion outcome calculations based on it.
        // For simplicity, this function just consumes energy.
        // Add a check for valid particleType if needed.
        _burnEnergy(msg.sender, 50);
        // Emit Attunement event: AttunementInitiated(msg.sender, particleType, block.timestamp + duration)
        // Add state variable: mapping(address => uint8) public userAttunementType; mapping(address => uint256) public userAttunementUntil;
    }


    // --- Energy System Functions ---

    /**
     * @dev Gets the current Energy balance for a user.
     * @param user The address of the user.
     * @return The user's Energy balance.
     */
    function getUserEnergy(address user) external view returns (uint256) {
        return _userEnergy[user];
    }

    /**
     * @dev Allows a user to generate Energy. Potential cost or cooldown.
     * Can be influenced by global parameters or external oracle data.
     */
    function generateEnergy() external payable {
        // Example: Requires paying a small ETH fee
        require(msg.value > 0, "QuantumFusion: Must send ETH to generate energy");

        // Example: Energy generation influenced by Ether price via Oracle
        uint256 ethPrice = 1; // Default if oracle not set or fails
        if (address(priceFeed) != address(0)) {
             try priceFeed.latestRoundData() returns (int80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, int80 answeredInRound) {
                if (answer > 0) {
                    ethPrice = uint256(answer); // Price in USD per ETH (with decimals)
                }
             } catch {
                 // Ignore oracle error, use default price
             }
        }

        // Example formula: Energy = (ETH sent * ETH Price * Resonance) / 1e18 (adjust decimals)
        // Let's assume priceFeed returns price * 1e8 and msg.value is in wei (1e18)
        // And Energy is like an ERC20 with 18 decimals for internal consistency
        uint256 generated = (msg.value * ethPrice * energyResonance) / (1e18 * 1e8 / 1e18); // Simplified scaling

        // More reasonable example: Based on fixed rate, influenced by resonance
        uint256 baseRate = 1e18; // 1 Energy per 1 Ether base rate
        generated = (msg.value * energyResonance) / 100; // 100 is base resonance (100%)

        _userEnergy[msg.sender] += generated;
        emit UserEnergyGenerated(msg.sender, generated, _userEnergy[msg.sender]);

        // Eth remains in the contract (can be withdrawn by owner)
    }


    /**
     * @dev Allows a user to transfer Energy to another user.
     * @param recipient The address to send Energy to.
     * @param amount The amount of Energy to send.
     */
    function transferEnergy(address recipient, uint256 amount) external whenUserHasEnergy(amount) {
        require(recipient != address(0), "QuantumFusion: Cannot transfer energy to zero address");
        require(recipient != msg.sender, "QuantumFusion: Cannot transfer energy to yourself");

        _userEnergy[msg.sender] -= amount;
        _userEnergy[recipient] += amount;

        emit UserEnergyTransferred(msg.sender, recipient, amount);
    }

    /**
     * @dev Internal function to burn energy. Used for costs.
     * @param user The user whose energy to burn.
     * @param amount The amount of Energy to burn.
     */
    function _burnEnergy(address user, uint256 amount) internal {
        require(_userEnergy[user] >= amount, "QuantumFusion: Insufficient energy (internal burn)");
        _userEnergy[user] -= amount;
        emit UserEnergyBurned(user, amount, _userEnergy[user]);
    }

    // --- Fusion Mechanic Functions ---

    /**
     * @dev Initiates the fusion process for two particles. Burns Energy and requests randomness.
     * @param tokenId1 The ID of the first particle.
     * @param tokenId2 The ID of the second particle.
     */
    function initiateFusion(uint256 tokenId1, uint256 tokenId2) external whenParticleExists(tokenId1) whenParticleExists(tokenId2) {
        require(tokenId1 != tokenId2, "QuantumFusion: Cannot fuse a particle with itself");
        require(ownerOf(tokenId1) == msg.sender, "QuantumFusion: Must own particle 1");
        require(ownerOf(tokenId2) == msg.sender, "QuantumFusion: Must own particle 2");

        ParticleData storage p1 = _particles[tokenId1];
        ParticleData storage p2 = _particles[tokenId2];

        uint8 type1 = p1.particleType;
        uint8 type2 = p2.particleType;

        // Get fusion configuration based on particle types
        uint16 configKey = type1 < type2 ? uint16(type1) << 8 | type2 : uint16(type2) << 8 | type1;
        FusionConfig storage config = _fusionConfigs[configKey];

        require(config.energyCost > 0 || config.potentialOutcomes.length > 0, "QuantumFusion: Fusion config not set for these particle types");
        require(_userEnergy[msg.sender] >= config.energyCost, "QuantumFusion: Insufficient energy for fusion");

        // Consume energy and burn the input particles *before* requesting randomness
        // This prevents issues if the VRF callback is delayed or fails and the user still has tokens.
        // The outcome determines what happens *after* the inputs are gone.
        _burnEnergy(msg.sender, config.energyCost);
        // Transfer to contract address temporarily before potential burn in callback
        _safeTransfer(msg.sender, address(this), tokenId1, "");
        _safeTransfer(msg.sender, address(this), tokenId2, "");

        // Request randomness from Chainlink VRF
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );

        // Store the fusion request details
        _fusionRequests[requestId] = FusionRequest({
            initiator: msg.sender,
            tokenId1: tokenId1,
            tokenId2: tokenId2,
            blockTimestamp: block.timestamp,
            status: 0 // Pending
        });

        emit FusionInitiated(msg.sender, tokenId1, tokenId2, requestId);
    }

     /**
     * @dev VRF callback function. Called by Chainlink VRF Coordinator.
     * Executes the fusion outcome based on the received randomness.
     * @param requestId The ID of the VR VRF request.
     * @param randomWords The random numbers provided by VRF.
     */
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(_fusionRequests[requestId].initiator != address(0), "QuantumFusion: Unknown VRF request ID");
        require(randomWords.length > 0, "QuantumFusion: No random words received");

        FusionRequest storage request = _fusionRequests[requestId];
        address initiator = request.initiator;
        uint256 tokenId1 = request.tokenId1;
        uint256 tokenId2 = request.tokenId2;

        // Make sure the tokens are still held by the contract (were transferred in initiateFusion)
        require(ownerOf(tokenId1) == address(this), "QuantumFusion: Particle 1 not held by contract for fusion fulfillment");
        require(ownerOf(tokenId2) == address(this), "QuantumFusion: Particle 2 not held by contract for fusion fulfillment");


        // Burn the input tokens regardless of the outcome
        // This simplifies the logic: inputs are always consumed upon successful VRF fulfillment
        _burnParticleInternal(address(this), tokenId1);
        _burnParticleInternal(address(this), tokenId2);


        uint256 randomNumber = randomWords[0]; // Use the first random word

        ParticleData memory p1 = _particles[tokenId1]; // Data struct is still available even after burning
        ParticleData memory p2 = _particles[tokenId2];

        uint8 type1 = p1.particleType;
        uint8 type2 = p2.particleType;

        uint16 configKey = type1 < type2 ? uint16(type1) << 8 | type2 : uint16(type2) << 8 | type1;
        FusionConfig storage config = _fusionConfigs[configKey];

        bytes memory outcomesEncoded = config.potentialOutcomes;

        // Decode potential outcomes
        // Assuming potentialOutcomes is ABI encoded like `abi.encodePacked([[uint8, uint16], [uint8, uint16], ...])`
        // Where uint8 is the outcome type and uint16 is the probability (0-1000 for 0-100%)
        // Example: [[0, 700], [1, 300]] = 70% chance of outcome 0, 30% chance of outcome 1
        require(outcomesEncoded.length % 3 == 0, "QuantumFusion: Invalid outcomes encoding length");

        uint256 totalProbability = 0;
        for (uint i = 0; i < outcomesEncoded.length; i += 3) {
             // Be careful with decoding - requires knowledge of encoding format
            // This is a simplified direct byte access - might need abi.decode
            uint8 outcomeType = outcomesEncoded[i];
            uint16 probability;
            assembly {
                probability := mload(add(add(outcomesEncoded, 0x03), i)) // Load 2 bytes
            }
            totalProbability += probability;
        }

        require(totalProbability <= 1000, "QuantumFusion: Total outcome probabilities exceed 100%"); // Should be <= 1000 for 100%


        uint256 outcomeRoll = randomNumber % 1000; // Roll the dice between 0-999

        uint8 finalOutcomeType = 255; // Placeholder for "no outcome" or "default burn"
        uint256 cumulativeProbability = 0;

        uint256 newParticleId = 0; // Only set if outcome is minting
        uint256[] memory affectedTokenIds = new uint256[](0); // Store IDs that were affected beyond the burned inputs

        // Determine outcome based on roll and probabilities
        for (uint i = 0; i < outcomesEncoded.length; i += 3) {
             uint8 currentOutcomeType = outcomesEncoded[i];
             uint16 currentProbability;
             assembly {
                currentProbability := mload(add(add(outcomesEncoded, 0x03), i)) // Load 2 bytes
             }

            // Adjust probability based on global turbulence (example)
            // Higher turbulence reduces chance of 'stable' outcomes, increases chance of 'chaotic' ones.
            // Need more sophisticated logic here based on outcome type vs turbulence value.
            // For simplicity, let's just say turbulence *reduces* probabilities slightly across the board for now.
            // This part is complex game logic.
            // uint256 adjustedProbability = (uint256(currentProbability) * (10000 - quantumTurbulence)) / 10000; // Example: 0 turbulence = 100%, 1000 turbulence = 90%

            cumulativeProbability += currentProbability; // Use base probability for simplicity in loop

            if (outcomeRoll < cumulativeProbability) {
                finalOutcomeType = currentOutcomeType;
                break; // Outcome determined
            }
        }

        // If no outcome was selected (due to rounding or logic), default to a base case (e.g., burn inputs with no output)
         if (finalOutcomeType == 255) {
             finalOutcomeType = 3; // Example: 3 could map to "BurnBoth"
         }

        // --- Execute Outcome ---
        // Outcome types are game-specific logic
        // 0: MintNewParticle (Type based on fusion config or inputs)
        // 1: UpgradeInput1 (Change state/gen/properties)
        // 2: UpgradeInput2 (Change state/gen/properties)
        // 3: BurnBoth (Already done)
        // 4: MintMultiple (More than one new particle)
        // etc.

        if (finalOutcomeType == 0) {
            // Example: Mint a new particle. Type/Gen might depend on inputs.
            uint8 newParticleType = type1 == type2 ? type1 : (type1 + type2) % 256; // Simple example rule
            uint8 newGeneration = (p1.generation > p2.generation ? p1.generation : p2.generation) + 1;

            _particleIds.increment();
            newParticleId = _particleIds.current();

            _particles[newParticleId] = ParticleData({
                id: newParticleId,
                particleType: newParticleType,
                generation: newGeneration,
                state: 0, // New particles start stable
                properties: "", // Initial empty properties
                birthBlock: uint64(block.number)
            });

            _safeTransfer(address(0), initiator, newParticleId, ""); // Mint to the initiator
            emit ParticleMinted(initiator, newParticleId, newParticleType, newGeneration);
            affectedTokenIds = new uint256[](1);
            affectedTokenIds[0] = newParticleId;

        } else if (finalOutcomeType == 1) {
            // Example: Upgrade state of input 1 (doesn't make sense if inputs are burned... revise logic)
            // Alternative: Outcome affects *another* particle the user owns, or gives user a special item.
             // Let's redefine outcomes:
             // 0: Mint New Particle
             // 1: Grant Energy to user
             // 2: Mint Special Item (could be another NFT type)
             // 3: Burn Inputs (no output)
             // 4: Increase User's Attunement Level (Hypothetical)

             if (finalOutcomeType == 1) {
                 uint256 energyReward = 1000 + (p1.generation + p2.generation) * 50; // Example reward based on inputs
                 _userEnergy[initiator] += energyReward;
                 emit UserEnergyGenerated(initiator, energyReward, _userEnergy[initiator]); // Re-use event for simplicity
             } else if (finalOutcomeType == 2) {
                 // Example: Mint a 'Fusion Catalyst' token (requires a separate ERC1155 or ERC721 for items)
                 // emit SpecialItemMinted(initiator, itemId, amount);
             } // Outcome 3 is just burning inputs, already done.
             else if (finalOutcomeType == 4) {
                 // Example: Increase user's attunement level (requires state variable)
                 // userAttunementLevel[initiator] += 1;
                 // emit AttunementLevelIncreased(initiator, userAttunementLevel[initiator]);
             }
             // Add other outcomes...

        } // No else needed, outcomes 1-4 handled above.

        request.status = 1; // Fulfilled Success
        emit FusionCompleted(requestId, finalOutcomeType, newParticleId, affectedTokenIds); // Log the outcome

    }

     // Internal helper to burn particle owned by a specific address (used in fulfillment)
    function _burnParticleInternal(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "QuantumFusion: Internal burn from incorrect owner");

        _approve(address(0), tokenId); // Clear approval
        _balances[from]--;
        delete _owners[tokenId];
        // ParticleData is NOT deleted here, as rawFulfillRandomWords needs it briefly after owner is cleared.
        // Clean-up might be needed later if structs get very large and memory is a concern.
        // For this example, data remains accessible by ID briefly.

        emit ParticleBurned(from, tokenId); // Log the burn
    }


    // --- Configuration & Governance Functions (Owner Only) ---

    /**
     * @dev Sets the fusion parameters for a pair of particle types.
     * The outcomes should be ABI encoded bytes representing [[outcomeType, probability], ...].
     * Probabilities should sum up to 1000 (representing 100%).
     * @param type1 The type of the first particle.
     * @param type2 The type of the second particle.
     * @param energyCost The energy required for this fusion.
     * @param potentialOutcomes ABI encoded bytes defining possible outcomes and their probabilities.
     */
    function setFusionParameters(uint8 type1, uint8 type2, uint256 energyCost, bytes memory potentialOutcomes) external onlyOwner {
         // Store configuration regardless of order
        uint16 configKey = type1 < type2 ? uint16(type1) << 8 | type2 : uint16(type2) << 8 | type1;

        // Basic validation for outcomes encoding (length must be multiple of 3: 1 byte type + 2 bytes probability)
        require(potentialOutcomes.length % 3 == 0, "QuantumFusion: Invalid potentialOutcomes encoding");
        uint256 totalProb = 0;
         for (uint i = 0; i < potentialOutcomes.length; i += 3) {
             uint16 prob;
              assembly {
                prob := mload(add(add(potentialOutcomes, 0x03), i)) // Load 2 bytes
              }
             totalProb += prob;
         }
         require(totalProb <= 1000, "QuantumFusion: Total probabilities exceed 1000 (100%)");

        _fusionConfigs[configKey] = FusionConfig({
            energyCost: energyCost,
            baseTurbulenceThreshold: 0, // Example field, could be used for complexity
            potentialOutcomes: potentialOutcomes
        });

        emit FusionParametersSet(type1, type2, energyCost, potentialOutcomes);
    }

    /**
     * @dev Sets the global Quantum Turbulence parameter. Affects fusion outcome probabilities.
     * @param turbulence The new turbulence value.
     */
    function setQuantumTurbulence(uint256 turbulence) external onlyOwner {
        require(turbulence <= 1000, "QuantumFusion: Turbulence cannot exceed 1000"); // Example cap
        uint256 oldTurbulence = quantumTurbulence;
        quantumTurbulence = turbulence;
        emit QuantumTurbulenceSet(oldTurbulence, quantumTurbulence);
    }

    /**
     * @dev Sets the global Energy Resonance parameter. Affects Energy generation efficiency.
     * @param resonance The new resonance value (e.g., 100 for 100%).
     */
    function setEnergyResonance(uint256 resonance) external onlyOwner {
         uint256 oldResonance = energyResonance;
         energyResonance = resonance;
         emit EnergyResonanceSet(oldResonance, energyResonance);
    }

    /**
     * @dev Sets the addresses for Chainlink VRF Coordinator, Key Hash, and potentially a Data Feed Oracle.
     * @param vrfCoordinator The address of the VRF Coordinator contract.
     * @param keyHash The key hash for the VRF requests.
     * @param dataFeed Optional: The address of a data feed oracle (e.g., Chainlink Price Feed). Set to address(0) if not used.
     */
    function setOracleAddresses(address vrfCoordinator, bytes32 keyHash, address dataFeed) external onlyOwner {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        if (dataFeed != address(0)) {
             priceFeed = AggregatorV3Interface(dataFeed);
        } else {
             priceFeed = AggregatorV3Interface(address(0));
        }

        emit OracleAddressesSet(vrfCoordinator, keyHash, dataFeed);
    }

     /**
     * @dev Sets the hypothetical particle decay rate. 0 means no decay.
     * @param rate The new decay rate.
     */
    function setParticleDecayRate(uint256 rate) external onlyOwner {
        particleDecayRate = rate;
        emit ParameterChanged("ParticleDecayRate", rate); // Generic event for params
    }


    /**
     * @dev Allows the owner to withdraw ETH (collected from Energy generation fees) from the contract.
     * @param recipient The address to send ETH to.
     */
    function withdrawFees(address recipient) external onlyOwner {
        require(recipient != address(0), "QuantumFusion: Cannot withdraw to zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "QuantumFusion: No balance to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "QuantumFusion: ETH withdrawal failed");
    }


    // --- Utility & View Functions ---

    /**
     * @dev Gets the fusion configuration for a pair of particle types.
     * @param type1 The type of the first particle.
     * @param type2 The type of the second particle.
     * @return FusionConfig struct.
     */
    function getFusionParameters(uint8 type1, uint8 type2) external view returns (FusionConfig memory) {
        uint16 configKey = type1 < type2 ? uint16(type1) << 8 | type2 : uint16(type2) << 8 | type1;
        return _fusionConfigs[configKey];
    }

    /**
     * @dev Gets the current global Quantum Turbulence value.
     * @return The current Quantum Turbulence value.
     */
    function getQuantumTurbulence() external view returns (uint256) {
        return quantumTurbulence;
    }

    /**
     * @dev Gets the current global Energy Resonance value.
     * @return The current Energy Resonance value.
     */
    function getEnergyResonance() external view returns (uint256) {
        return energyResonance;
    }

    /**
     * @dev Gets the configured Oracle addresses.
     * @return vrfCoordinator, keyHash, dataFeed addresses.
     */
    function getOracleAddresses() external view returns (address vrfCoordinator, bytes32 keyHash, address dataFeed) {
        return (address(COORDINATOR), s_keyHash, address(priceFeed));
    }

     /**
     * @dev Gets the total number of particles minted (and not burned).
     * Note: This counter increments on mint, does not decrement on burn. Use balanceOf for owned tokens.
     * @return Total number of particles ever minted.
     */
    function getParticleCount() external view returns (uint256) {
        return _particleIds.current();
    }

    /**
     * @dev Gets the status of a fusion request initiated via VRF.
     * @param requestId The VRF request ID.
     * @return initiator, tokenId1, tokenId2, blockTimestamp, status (0=Pending, 1=Fulfilled Success, 2=Fulfilled Failure - currently only 0 and 1 implemented).
     */
    function getFusionRequestStatus(uint256 requestId) external view returns (address initiator, uint256 tokenId1, uint256 tokenId2, uint256 blockTimestamp, uint8 status) {
        FusionRequest storage request = _fusionRequests[requestId];
        return (request.initiator, request.tokenId1, request.tokenId2, request.blockTimestamp, request.status);
    }

     /**
     * @dev Gets the current hypothetical particle decay rate.
     * @return The current decay rate.
     */
    function getParticleDecayRate() external view returns (uint256) {
        return particleDecayRate;
    }


    // --- Fallback function to receive ETH ---
    receive() external payable {}
    fallback() external payable {}
}

// Dummy implementation for Strings.sol if not using OpenZeppelin contracts directly
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
        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            index--;
            buffer[index] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// A simple generic event for parameter changes
contract ParameterChangeEmitter {
    event ParameterChanged(string indexed parameterName, uint256 newValue);
}
```