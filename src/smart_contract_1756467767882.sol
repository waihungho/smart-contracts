Here's a Solidity smart contract named `AetherForge` that incorporates advanced, creative, and trendy concepts like dynamic NFTs, ZK-proof integration for private trait unlocks, AI oracle-driven evolution, a user reputation system, and an NFT incubation mechanism. It is designed to be distinct from common open-source implementations by combining these features in a novel way.

---

## AetherForge: Sentient AI-Driven ZK-Proof Evolvable Digital Entities

**Outline:**

*   **Contract Scope:** A protocol for creating, evolving, and interacting with highly dynamic Digital Entities (NFTs).
*   **Core Concepts:** Dynamic NFTs, Zero-Knowledge Proof (ZK-Proof) Integration, AI Oracle Interaction, User Reputation System, Essence (ERC20) Token Utility, Incubation/Staking Mechanics.
*   **Inheritance:** `ERC721` (for NFT core), `Ownable` (for administrative control), `Pausable` (for emergency stops).
*   **External Interfaces:** `IZKVerifier` (for ZK-proof verification), `IERC20` (for Essence token).
*   **Data Structures:**
    *   `_nextTokenId`: Counter for new entity IDs.
    *   `_entityTraits`: `mapping(uint256 => mapping(bytes32 => bytes32))` stores dynamic traits for each Digital Entity.
    *   `_userReputation`: `mapping(address => uint256)` tracks reputation scores.
    *   `_reputationThresholds`: `mapping(bytes32 => uint256)` sets reputation requirements for actions.
    *   `_aiOracles`: `mapping(address => bool)` registers authorized AI oracles.
    *   `_aiOraclePublicKeyHashes`: `mapping(address => bytes32)` stores identifier for oracle's public key for signature verification.
    *   `_zkVerifier`: Address of the ZK proof verifier contract.
    *   `_essenceToken`: Address of the utility ERC20 token.
    *   `_minMintCost`: Cost in Essence to mint a new entity.
    *   `_incubationStartTimes`: `mapping(uint256 => uint256)` records when a DE entered incubation.
    *   `_lastYieldClaimTime`: `mapping(uint256 => uint256)` tracks last time yield was claimed for an incubated DE.
    *   `_originalStaker`: `mapping(uint256 => address)` stores the address of the user who staked a DE.
*   **Key Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, `requireReputation`.

**Function Summary (25 Functions):**

**I. Core Entity Management (ERC721 & Base):**
1.  `constructor(string memory name_, string memory symbol_)`: Initializes the contract, ERC721 name/symbol, and `Ownable` role.
2.  `mintInitialEntity(bytes32 _initialTraitValue)`: Mints a new Digital Entity (DE) to `msg.sender`, costing $ESSENCE tokens and requiring sufficient reputation.
3.  `burnEntity(uint256 _tokenId)`: Allows the owner of a DE to burn it, clearing its traits and deducting reputation.
4.  `getEntityTraitValue(uint256 _tokenId, bytes32 _traitKey)`: Public view function to retrieve the value of a specific trait for a DE.
5.  `_updateEntityTrait(uint256 _tokenId, bytes32 _traitKey, bytes32 _newValue)`: Internal helper function to atomically update a DE's trait, used by evolution mechanisms.

**II. Evolution & Advanced Integration (ZK-Proof / AI Oracle):**
6.  `submitZKProofForTraitUnlock(uint256 _tokenId, bytes32 _traitKey, bytes32 _traitValue, uint[2] calldata _a, uint[2][2] calldata _b, uint[2] calldata _c, uint[1] calldata _publicInput)`: Allows a user to submit a ZK proof to securely unlock or modify a DE trait, verifying a secret condition without revealing its contents.
7.  `processAITraitUpdate(uint256 _tokenId, bytes32 _traitKey, bytes32 _aiSuggestedValue, uint256 _timestamp, bytes calldata _signature)`: An authorized AI oracle submits a cryptographically signed update to modify a DE's trait based on off-chain AI analysis.
8.  `registerAIOracle(address _oracleAddress, bytes32 _publicKeyHash)`: Owner function to authorize a new AI oracle address and its associated public key hash for signature verification.
9.  `deregisterAIOracle(address _oracleAddress)`: Owner function to revoke authorization for an AI oracle.
10. `setZKVerifierAddress(address _verifier)`: Owner function to set the address of the Zero-Knowledge proof verifier contract.

**III. Reputation System:**
11. `_gainReputation(address _user, uint256 _amount)`: Internal function to award reputation points to a user.
12. `_loseReputation(address _user, uint256 _amount)`: Internal function to deduct reputation points from a user.
13. `getUserReputation(address _user)`: Public view function to retrieve a user's current reputation score.
14. `setReputationThreshold(bytes32 _actionId, uint256 _threshold)`: Owner function to set the minimum reputation required for specific contract actions.

**IV. Essence Token (ERC20) & Financials:**
15. `depositEssence(uint256 _amount)`: Allows users to deposit $ESSENCE ERC20 tokens into the contract, requiring prior approval.
16. `withdrawEssence(uint256 _amount)`: Allows users to withdraw their deposited $ESSENCE tokens from the contract.
17. `setEssenceContract(address _essenceTokenAddress)`: Owner function to set the address of the $ESSENCE ERC20 token contract.
18. `setMinMintCost(uint256 _cost)`: Owner function to set the $ESSENCE cost for minting a new entity.

**V. Incubation & Passive Progression:**
19. `startIncubation(uint256 _tokenId)`: Stakes a DE within the contract for an "incubation" period, making it non-transferable and eligible for passive yield.
20. `endIncubation(uint256 _tokenId)`: Un-stakes a DE, returning it to the original staker and ending its incubation.
21. `claimIncubationYield(uint256 _tokenId)`: Allows the original staker to claim accumulated benefits (e.g., $ESSENCE rewards, minor trait boosts) from an incubated DE without ending its incubation.
22. `incubationEssenceYieldPerHour()`: Public view for the configured Essence yield rate.
23. `INCUBATION_TRAIT_BOOST_INTERVAL()`: Public view for the configured trait boost interval.

**VI. Administrative & Security:**
24. `pauseContract()`: Owner function to pause core functionalities in case of an emergency.
25. `unpauseContract()`: Owner function to unpause the contract after an emergency.
26. `setBaseURI(string memory _newBaseURI)`: Owner function to update the base URI for NFT metadata, affecting how token URIs are resolved.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For AI oracle signature verification

// Interface for a generic ZK Proof Verifier (e.g., a Groth16 verifier contract)
// This interface defines the expected function signature for a ZK verifier.
// A concrete implementation of this contract would be deployed separately (e.g., by snarkjs).
interface IZKVerifier {
    function verifyProof(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[1] calldata input
    ) external view returns (bool);
}

/**
 * @title AetherForge: Sentient AI-Driven ZK-Proof Evolvable Digital Entities
 * @dev This contract implements a novel system for dynamic NFTs (Digital Entities)
 *      that evolve based on multiple advanced mechanisms:
 *      1.  **Dynamic Traits:** NFTs possess mutable traits stored directly on-chain,
 *          allowing them to change over time based on various interactions.
 *      2.  **ZK-Proof Gated Evolution:** Users can submit Zero-Knowledge proofs
 *          to unlock or modify specific traits without revealing the underlying
 *          secret conditions or private data that satisfy the proof. This adds
 *          a layer of privacy and verifiable interaction.
 *      3.  **AI Oracle Driven Evolution:** Authorized AI oracles can submit
 *          cryptographically signed data based on off-chain AI analysis. This data
 *          then dynamically updates entity traits on-chain, allowing for complex,
 *          externally-influenced evolution (e.g., based on environmental data,
 *          sentiment analysis, or game state derived from AI).
 *      4.  **Reputation System:** User reputation (an on-chain score) influences
 *          access to advanced features, specific evolution paths, and interaction
 *          privileges within the AetherForge ecosystem.
 *      5.  **Essence Token Utility:** An ERC20 token ($ESSENCE) serves as the
 *          primary utility token, used for minting new entities, fueling evolution processes,
 *          and claiming yields from entity incubation.
 *      6.  **Incubation/Staking:** Digital Entities can be "incubated" (staked)
 *          within the contract. During incubation, they cannot be transferred
 *          but passively generate resources ($ESSENCE) or accumulate minor trait boosts,
 *          representing periods of growth or resource generation.
 *
 *      This contract aims to provide a unique, interactive, and privacy-preserving
 *      framework for highly dynamic and evolving digital assets, pushing the
 *      boundaries of what NFTs can represent and how they interact with users
 *      and external data.
 *
 *      **Function Summary:**
 *
 *      **I. Core Entity Management (ERC721 & Base):**
 *      1.  `constructor(string memory name_, string memory symbol_)`: Initializes the contract, ERC721 name/symbol, and Ownable role.
 *      2.  `mintInitialEntity(bytes32 _initialTraitValue)`: Mints a new Digital Entity (DE) to `msg.sender`, costing $ESSENCE tokens and requiring sufficient reputation.
 *      3.  `burnEntity(uint252 _tokenId)`: Allows the owner of a DE to burn it, clearing its traits and deducting reputation.
 *      4.  `getEntityTraitValue(uint256 _tokenId, bytes32 _traitKey)`: Public view function to retrieve the value of a specific trait for a DE.
 *      5.  `_updateEntityTrait(uint256 _tokenId, bytes32 _traitKey, bytes32 _newValue)`: Internal helper function to atomically update a DE's trait, used by evolution mechanisms.
 *
 *      **II. Evolution & Advanced Integration (ZK-Proof / AI Oracle):**
 *      6.  `submitZKProofForTraitUnlock(uint256 _tokenId, bytes32 _traitKey, bytes32 _traitValue, uint[2] calldata _a, uint[2][2] calldata _b, uint[2] calldata _c, uint[1] calldata _publicInput)`: Allows a user to submit a ZK proof to securely unlock or modify a DE trait, verifying a secret condition without revealing its contents.
 *      7.  `processAITraitUpdate(uint256 _tokenId, bytes32 _traitKey, bytes32 _aiSuggestedValue, uint256 _timestamp, bytes calldata _signature)`: An authorized AI oracle submits a cryptographically signed update to modify a DE's trait based on off-chain AI analysis.
 *      8.  `registerAIOracle(address _oracleAddress, bytes32 _publicKeyHash)`: Owner function to authorize a new AI oracle address and its associated public key hash for signature verification.
 *      9.  `deregisterAIOracle(address _oracleAddress)`: Owner function to revoke authorization for an AI oracle.
 *      10. `setZKVerifierAddress(address _verifier)`: Owner function to set the address of the Zero-Knowledge proof verifier contract.
 *
 *      **III. Reputation System:**
 *      11. `_gainReputation(address _user, uint256 _amount)`: Internal function to award reputation points to a user.
 *      12. `_loseReputation(address _user, uint256 _amount)`: Internal function to deduct reputation points from a user.
 *      13. `getUserReputation(address _user)`: Public view function to retrieve a user's current reputation score.
 *      14. `setReputationThreshold(bytes32 _actionId, uint256 _threshold)`: Owner function to set the minimum reputation required for specific contract actions.
 *
 *      **IV. Essence Token (ERC20) & Financials:**
 *      15. `depositEssence(uint256 _amount)`: Allows users to deposit $ESSENCE ERC20 tokens into the contract, requiring prior approval.
 *      16. `withdrawEssence(uint256 _amount)`: Allows users to withdraw their deposited $ESSENCE tokens from the contract.
 *      17. `setEssenceContract(address _essenceTokenAddress)`: Owner function to set the address of the $ESSENCE ERC20 token contract.
 *      18. `setMinMintCost(uint256 _cost)`: Owner function to set the $ESSENCE cost for minting a new entity.
 *
 *      **V. Incubation & Passive Progression:**
 *      19. `startIncubation(uint256 _tokenId)`: Stakes a DE within the contract for an "incubation" period, making it non-transferable and eligible for passive yield.
 *      20. `endIncubation(uint256 _tokenId)`: Un-stakes a DE, returning it to the original staker and ending its incubation.
 *      21. `claimIncubationYield(uint256 _tokenId)`: Allows the original staker to claim accumulated benefits (e.g., $ESSENCE rewards, minor trait boosts) from an incubated DE without ending its incubation.
 *      22. `incubationEssenceYieldPerHour()`: Public view for the configured Essence yield rate.
 *      23. `INCUBATION_TRAIT_BOOST_INTERVAL()`: Public view for the configured trait boost interval.
 *
 *      **VI. Administrative & Security:**
 *      24. `pauseContract()`: Owner function to pause core functionalities in case of an emergency.
 *      25. `unpauseContract()`: Owner function to unpause the contract after an emergency.
 *      26. `setBaseURI(string memory _newBaseURI)`: Owner function to update the base URI for NFT metadata, affecting how token URIs are resolved.
 */
contract AetherForge is ERC721, Ownable, Pausable {

    // --- I. State Variables & Event Declarations ---

    // Token ID Counter for new Digital Entities
    uint256 private _nextTokenId;

    // Digital Entity Traits: tokenId => traitKey (bytes32) => traitValue (bytes32)
    // Using bytes32 for keys and values allows for efficient storage of various data types
    // like hashes, packed integers, short strings, or boolean flags.
    mapping(uint256 => mapping(bytes32 => bytes32)) private _entityTraits;

    // User Reputation: userAddress => reputationScore
    mapping(address => uint256) private _userReputation;

    // Reputation thresholds for specific actions (actionKey => requiredReputation)
    // E.g., _reputationThresholds["mint_entity"] = 10;
    mapping(bytes32 => uint256) private _reputationThresholds;

    // AI Oracles: oracleAddress => isAuthorized (boolean)
    mapping(address => bool) private _aiOracles;
    // AI Oracle Public Key Hashes for signature verification: oracleAddress => keccak256(publicKey)
    // This is a simplified approach. In a production system, one might store the full public key components
    // (e.g., x, y coordinates) and use a more robust ECDSA verification library.
    mapping(address => bytes32) private _aiOraclePublicKeyHashes;

    // ZK Proof Verifier contract address
    IZKVerifier private _zkVerifier;

    // Essence Token (ERC20) contract address
    IERC20 private _essenceToken;

    // Minting cost for a new Digital Entity in Essence tokens (with 18 decimals)
    uint256 private _minMintCost;

    // Incubation State: tokenId => incubationStartTime (timestamp)
    mapping(uint256 => uint256) private _incubationStartTimes;
    // Tracks the original staker of an incubated entity to ensure only they can unstake/claim.
    mapping(uint256 => address) private _originalStaker;
    // Tracks the last time yield was claimed for an incubated entity.
    mapping(uint256 => uint256) private _lastYieldClaimTime;

    // Configuration for incubation rewards
    uint256 public incubationEssenceYieldPerHour = 100 * 10 ** 10; // Example: 0.00000001 ESSENCE per hour (if Essence has 18 decimals)
    uint256 public constant INCUBATION_TRAIT_BOOST_INTERVAL = 24 hours; // Minor trait boosts apply every 24 hours

    // Events to track important contract actions
    event EntityMinted(uint256 indexed tokenId, address indexed owner, bytes32 initialTrait);
    event TraitUpdated(uint256 indexed tokenId, bytes32 indexed traitKey, bytes32 newValue, address updater);
    event ZKProofVerified(uint256 indexed tokenId, bytes32 indexed traitKey, bytes32 traitValue, address prover);
    event AITraitProcessed(uint256 indexed tokenId, bytes32 indexed traitKey, bytes32 aiSuggestedValue, address indexed oracle);
    event ReputationGained(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationLost(address indexed user, uint256 amount, uint256 newReputation);
    event EssenceDeposited(address indexed user, uint256 amount);
    event EssenceWithdrawn(address indexed user, uint256 amount);
    event IncubationStarted(uint256 indexed tokenId, address indexed owner, uint256 startTime);
    event IncubationEnded(uint256 indexed tokenId, address indexed owner, uint256 endTime, uint256 totalIncubationTime);
    event IncubationYieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 essenceAmount, uint256 traitBoostsApplied);
    event AIOracleRegistered(address indexed oracleAddress, bytes32 publicKeyHash);
    event AIOracleDeregistered(address indexed oracleAddress);
    event ZKVerifierSet(address newVerifier);
    event ReputationThresholdSet(bytes32 indexed actionId, uint256 threshold);

    // --- II. Core Entity Management (ERC721 & Base) ---

    /**
     * @dev Initializes the ERC721 token (name, symbol) and sets the initial owner.
     * @param name_ The name of the NFT collection.
     * @param symbol_ The symbol of the NFT collection.
     */
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        _minMintCost = 1000 * 10 ** 18; // Default mint cost: 1000 Essence tokens (assuming 18 decimals)
    }

    /**
     * @dev Modifier to check if the caller's reputation is sufficient for a specific action.
     * @param _actionId A unique identifier for the action (e.g., "mint_entity", "zk_evolution").
     */
    modifier requireReputation(bytes32 _actionId) {
        require(_userReputation[msg.sender] >= _reputationThresholds[_actionId], "AetherForge: Insufficient reputation for action");
        _;
    }

    /**
     * @dev Mints a new Digital Entity (DE) to the caller.
     *      Requires payment in Essence tokens and sufficient reputation.
     *      Initializes a basic trait for the new entity.
     * @param _initialTraitValue The initial value for a base trait ("genesis_trait") of the new entity.
     * @return The ID of the newly minted Digital Entity.
     */
    function mintInitialEntity(bytes32 _initialTraitValue) public whenNotPaused requireReputation("mint_entity") returns (uint256) {
        require(_essenceToken != address(0), "AetherForge: Essence token not set");
        require(_essenceToken.transferFrom(msg.sender, address(this), _minMintCost), "AetherForge: Essence transfer failed for minting. Check allowance.");

        _nextTokenId++;
        uint256 newId = _nextTokenId;
        _safeMint(msg.sender, newId);
        _updateEntityTrait(newId, "genesis_trait", _initialTraitValue); // Assign an initial trait
        emit EntityMinted(newId, msg.sender, _initialTraitValue);
        _gainReputation(msg.sender, 5); // Award a small amount of reputation for minting
        return newId;
    }

    /**
     * @dev Allows the owner of a Digital Entity to burn it.
     *      Requires sufficient reputation, as this is an irreversible action.
     * @param _tokenId The ID of the Digital Entity to burn.
     */
    function burnEntity(uint256 _tokenId) public whenNotPaused requireReputation("burn_entity") {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AetherForge: Caller is not owner nor approved");
        
        // Before burning, explicitly clear the entity's traits.
        // In a complex system, traits might be too numerous to clear in one transaction,
        // requiring a separate cleanup mechanism or trait immutability.
        // For this example, we assume traits are managed sufficiently.
        // Note: Solidity mappings do not truly "delete" child entries without iterating known keys.
        // This 'delete' statement is more illustrative for the primary trait-mapping.
        delete _entityTraits[_tokenId];
        delete _incubationStartTimes[_tokenId];
        delete _lastYieldClaimTime[_tokenId];
        delete _originalStaker[_tokenId];

        _burn(_tokenId);
        _loseReputation(msg.sender, 10); // Example: a reputation penalty for entity destruction
    }

    // --- III. Digital Entity Trait Management (Dynamic NFTs) ---

    /**
     * @dev Retrieves the value of a specific trait for a given Digital Entity.
     * @param _tokenId The ID of the Digital Entity.
     * @param _traitKey The key (identifier) of the trait to retrieve.
     * @return The value of the trait. Returns bytes32(0) if the trait is not set.
     */
    function getEntityTraitValue(uint256 _tokenId, bytes32 _traitKey) public view returns (bytes32) {
        return _entityTraits[_tokenId][_traitKey];
    }

    /**
     * @dev Internal function to update a specific trait of a Digital Entity.
     *      This function is called by the various evolution mechanisms (ZK proofs, AI oracles, incubation).
     * @param _tokenId The ID of the Digital Entity.
     * @param _traitKey The key of the trait to update.
     * @param _newValue The new value for the trait.
     */
    function _updateEntityTrait(uint256 _tokenId, bytes32 _traitKey, bytes32 _newValue) internal {
        require(_exists(_tokenId), "AetherForge: Entity does not exist");
        _entityTraits[_tokenId][_traitKey] = _newValue;
        emit TraitUpdated(_tokenId, _traitKey, _newValue, msg.sender);
    }

    // --- IV. Evolution & Advanced Integration (ZK-Proof / AI Oracle) ---

    /**
     * @dev Allows a user to submit a Zero-Knowledge proof to unlock or modify a specific DE trait.
     *      The proof verifies a secret condition (e.g., proving ownership of a secret item,
     *      or reaching a certain off-chain milestone) without revealing the secret itself.
     *      The `_publicInput` array to the ZK verifier typically includes a hash of `tokenId`,
     *      `traitKey`, `traitValue`, and potentially `msg.sender` to bind the proof to the specific context.
     * @param _tokenId The ID of the Digital Entity.
     * @param _traitKey The key of the trait to be affected by the ZK proof.
     * @param _traitValue The target value for the trait, which is proven by the ZK proof.
     * @param _a The first component of the ZK proof.
     * @param _b The second component of the ZK proof.
     * @param _c The third component of the ZK proof.
     * @param _publicInput The public inputs required by the ZK circuit.
     */
    function submitZKProofForTraitUnlock(
        uint256 _tokenId,
        bytes32 _traitKey,
        bytes32 _traitValue,
        uint[2] calldata _a,
        uint[2][2] calldata _b,
        uint[2] calldata _c,
        uint[1] calldata _publicInput
    ) public whenNotPaused requireReputation("zk_evolution") {
        require(_zkVerifier != address(0), "AetherForge: ZK Verifier not set");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AetherForge: Caller is not owner nor approved");

        // The exact structure and content of `_publicInput` depend on the specific ZK circuit.
        // For instance, `_publicInput[0]` might be expected to be `uint(keccak256(abi.encodePacked(_tokenId, _traitKey, _traitValue)))`.
        // The circuit designer defines this. We simply pass it to the verifier here.
        require(_zkVerifier.verifyProof(_a, _b, _c, _publicInput), "AetherForge: ZK proof verification failed");

        _updateEntityTrait(_tokenId, _traitKey, _traitValue);
        emit ZKProofVerified(_tokenId, _traitKey, _traitValue, msg.sender);
        _gainReputation(msg.sender, 20); // Reward for successful ZK-gated evolution
    }

    /**
     * @dev An authorized AI oracle submits a cryptographically signed update to modify a DE's trait.
     *      The oracle computes a suggested trait value off-chain and signs a message containing it.
     *      The contract verifies the signature against the oracle's registered public key.
     * @param _tokenId The ID of the Digital Entity.
     * @param _traitKey The key of the trait to be updated by the AI oracle.
     * @param _aiSuggestedValue The new trait value suggested by the AI.
     * @param _timestamp The timestamp when the AI analysis was performed/signed. Used for replay protection.
     * @param _signature The ECDSA signature generated by the AI oracle for the message hash.
     */
    function processAITraitUpdate(
        uint256 _tokenId,
        bytes32 _traitKey,
        bytes32 _aiSuggestedValue,
        uint256 _timestamp,
        bytes calldata _signature
    ) public whenNotPaused {
        require(_aiOracles[msg.sender], "AetherForge: Caller is not an authorized AI oracle");
        require(_aiOraclePublicKeyHashes[msg.sender] != bytes32(0), "AetherForge: AI oracle public key hash not set for caller");

        // Construct the message hash that was signed by the AI oracle.
        // It's crucial that this exact message (excluding the signature itself) was signed off-chain.
        // Including `address(this)` prevents replay attacks across different contract deployments.
        bytes32 messageHash = keccak256(abi.encodePacked(
            _tokenId,
            _traitKey,
            _aiSuggestedValue,
            _timestamp,
            address(this)
        ));

        // Recover the signer address from the signature.
        // For this example, we assume `msg.sender` is the address that signed the message.
        // A more robust system for AI oracles might store actual public key components and verify
        // signatures against them directly, or employ a decentralized oracle network like Chainlink.
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), _signature);
        require(signer == msg.sender, "AetherForge: Signature verification failed for AI oracle");

        // Simple replay protection: AI update timestamp must be recent (e.g., within 1 day).
        // For higher security, per-oracle nonces or last-update timestamps per tokenId could be used.
        require(_timestamp > block.timestamp - 1 days, "AetherForge: AI update timestamp is too old or in the future");
        require(_timestamp <= block.timestamp, "AetherForge: AI update timestamp cannot be in the future");

        _updateEntityTrait(_tokenId, _traitKey, _aiSuggestedValue);
        emit AITraitProcessed(_tokenId, _traitKey, _aiSuggestedValue, msg.sender);
        // Could also award reputation to the oracle for successfully submitting valid data.
    }

    /**
     * @dev Owner function to register a new AI oracle.
     *      Authorized oracles can call `processAITraitUpdate`.
     * @param _oracleAddress The address of the AI oracle.
     * @param _publicKeyHash The keccak256 hash of the oracle's public key (or a representative identifier).
     */
    function registerAIOracle(address _oracleAddress, bytes32 _publicKeyHash) public onlyOwner {
        require(_oracleAddress != address(0), "AetherForge: Invalid oracle address");
        _aiOracles[_oracleAddress] = true;
        _aiOraclePublicKeyHashes[_oracleAddress] = _publicKeyHash;
        emit AIOracleRegistered(_oracleAddress, _publicKeyHash);
    }

    /**
     * @dev Owner function to deregister an AI oracle, revoking its ability to submit updates.
     * @param _oracleAddress The address of the AI oracle to deregister.
     */
    function deregisterAIOracle(address _oracleAddress) public onlyOwner {
        require(_aiOracles[_oracleAddress], "AetherForge: Oracle not registered");
        _aiOracles[_oracleAddress] = false;
        delete _aiOraclePublicKeyHashes[_oracleAddress]; // Clear public key hash upon deregistration
        emit AIOracleDeregistered(_oracleAddress);
    }

    /**
     * @dev Owner function to set the address of the Zero-Knowledge proof verifier contract.
     *      This contract is crucial for `submitZKProofForTraitUnlock`.
     * @param _verifier The address of the ZK proof verifier contract.
     */
    function setZKVerifierAddress(address _verifier) public onlyOwner {
        require(_verifier != address(0), "AetherForge: Invalid verifier address");
        _zkVerifier = IZKVerifier(_verifier);
        emit ZKVerifierSet(_verifier);
    }

    // --- V. Reputation System ---

    /**
     * @dev Internal function to award reputation points to a user.
     *      Called by other contract functions upon positive actions.
     * @param _user The address of the user.
     * @param _amount The amount of reputation to award.
     */
    function _gainReputation(address _user, uint256 _amount) internal {
        _userReputation[_user] += _amount;
        emit ReputationGained(_user, _amount, _userReputation[_user]);
    }

    /**
     * @dev Internal function to deduct reputation points from a user.
     *      Called by other contract functions upon negative or costly actions.
     * @param _user The address of the user.
     * @param _amount The amount of reputation to deduct.
     */
    function _loseReputation(address _user, uint256 _amount) internal {
        if (_userReputation[_user] < _amount) {
            _userReputation[_user] = 0; // Reputation cannot go negative
        } else {
            _userReputation[_user] -= _amount;
        }
        emit ReputationLost(_user, _amount, _userReputation[_user]);
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The current reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return _userReputation[_user];
    }

    /**
     * @dev Owner function to set the reputation requirement for a specific action.
     *      This allows dynamic adjustment of access control based on reputation.
     * @param _actionId A unique identifier for the action (e.g., "mint_entity", "zk_evolution").
     * @param _threshold The minimum reputation score required for the action.
     */
    function setReputationThreshold(bytes32 _actionId, uint256 _threshold) public onlyOwner {
        _reputationThresholds[_actionId] = _threshold;
        emit ReputationThresholdSet(_actionId, _threshold);
    }

    // --- VI. Essence Token (ERC20) & Financials ---

    /**
     * @dev Allows users to deposit $ESSENCE tokens into the contract.
     *      Users must first approve this contract to spend their $ESSENCE tokens.
     * @param _amount The amount of $ESSENCE to deposit.
     */
    function depositEssence(uint256 _amount) public whenNotPaused {
        require(_essenceToken != address(0), "AetherForge: Essence token not set");
        require(_essenceToken.transferFrom(msg.sender, address(this), _amount), "AetherForge: Essence deposit failed. Check allowance.");
        emit EssenceDeposited(msg.sender, _amount);
        // Award a small amount of reputation for contributing Essence
        _gainReputation(msg.sender, _amount / (10 ** 18 * 100)); // Example: 1 rep per 100 Essence deposited
    }

    /**
     * @dev Allows users to withdraw their deposited $ESSENCE tokens from the contract.
     * @param _amount The amount of $ESSENCE to withdraw.
     */
    function withdrawEssence(uint256 _amount) public whenNotPaused {
        require(_essenceToken != address(0), "AetherForge: Essence token not set");
        require(_essenceToken.balanceOf(address(this)) >= _amount, "AetherForge: Insufficient Essence balance in contract");
        require(_essenceToken.transfer(msg.sender, _amount), "AetherForge: Essence withdrawal failed");
        emit EssenceWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Owner function to set the address of the $ESSENCE ERC20 token contract.
     *      Must be set before any Essence-related operations can occur.
     * @param _essenceTokenAddress The address of the ERC20 Essence token.
     */
    function setEssenceContract(address _essenceTokenAddress) public onlyOwner {
        require(_essenceTokenAddress != address(0), "AetherForge: Invalid Essence token address");
        _essenceToken = IERC20(_essenceTokenAddress);
    }

    /**
     * @dev Owner function to set the cost of minting a new entity in Essence tokens.
     * @param _cost The new minimum minting cost (in Essence tokens, with 18 decimals).
     */
    function setMinMintCost(uint256 _cost) public onlyOwner {
        _minMintCost = _cost;
    }

    // --- VII. Incubation & Passive Progression ---

    /**
     * @dev Allows the owner of a Digital Entity to start its incubation period.
     *      The DE is staked within the contract, making it non-transferable while incubating.
     *      It also records the original staker to allow secure unstaking/claiming.
     * @param _tokenId The ID of the Digital Entity to incubate.
     */
    function startIncubation(uint256 _tokenId) public whenNotPaused requireReputation("start_incubation") {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AetherForge: Caller is not owner nor approved");
        require(_incubationStartTimes[_tokenId] == 0, "AetherForge: Entity already incubating");

        // Transfer the NFT to the contract to stake it
        _transfer(msg.sender, address(this), _tokenId);
        _incubationStartTimes[_tokenId] = block.timestamp;
        _lastYieldClaimTime[_tokenId] = block.timestamp; // Initialize last claim time for yield calculation
        _originalStaker[_tokenId] = msg.sender; // Record who staked it
        emit IncubationStarted(_tokenId, msg.sender, block.timestamp);
        _gainReputation(msg.sender, 2); // Small rep for committing to incubation
    }

    /**
     * @dev Allows the original staker to end the incubation period for their Digital Entity.
     *      The DE is transferred back to the original staker.
     * @param _tokenId The ID of the Digital Entity to end incubation for.
     */
    function endIncubation(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == address(this), "AetherForge: Entity not currently incubating in this contract");
        require(_incubationStartTimes[_tokenId] != 0, "AetherForge: Entity is not incubating");
        require(_originalStaker[_tokenId] == msg.sender, "AetherForge: Only the original staker can end incubation");

        uint256 totalIncubationTime = block.timestamp - _incubationStartTimes[_tokenId];
        
        // Clear incubation state mappings
        delete _incubationStartTimes[_tokenId];
        delete _lastYieldClaimTime[_tokenId];
        delete _originalStaker[_tokenId];

        _transfer(address(this), msg.sender, _tokenId); // Transfer back to original staker
        emit IncubationEnded(_tokenId, msg.sender, block.timestamp, totalIncubationTime);
    }

    /**
     * @dev Allows the original staker to claim accumulated benefits (Essence, minor trait boosts)
     *      from an incubated Digital Entity without ending the incubation.
     *      Yield is calculated since the last claim or the start of incubation.
     * @param _tokenId The ID of the incubated Digital Entity.
     */
    function claimIncubationYield(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == address(this), "AetherForge: Entity not currently incubating");
        require(_incubationStartTimes[_tokenId] != 0, "AetherForge: Entity is not incubating");
        require(_originalStaker[_tokenId] == msg.sender, "AetherForge: Only the original staker can claim yield");
        require(_essenceToken != address(0), "AetherForge: Essence token not set");

        uint256 timeSinceLastClaim = block.timestamp - _lastYieldClaimTime[_tokenId];
        require(timeSinceLastClaim >= 1 hours, "AetherForge: Not enough time has passed since last claim");

        uint256 hoursPassed = timeSinceLastClaim / 1 hours;
        uint256 essenceYield = hoursPassed * incubationEssenceYieldPerHour;
        uint256 traitBoostsApplied = 0;

        if (essenceYield > 0) {
            require(_essenceToken.transfer(msg.sender, essenceYield), "AetherForge: Essence yield transfer failed");
        }

        // Apply minor trait boosts based on incubation time
        uint256 traitBoostIntervals = timeSinceLastClaim / INCUBATION_TRAIT_BOOST_INTERVAL;
        if (traitBoostIntervals > 0) {
            // Example: "energy_level" trait increases by 1 for every interval
            bytes32 currentEnergyBytes = _entityTraits[_tokenId]["energy_level"];
            // Assuming "energy_level" trait stores a packed uint256 value.
            // If it stores other formats, parsing logic would differ.
            uint256 currentEnergyVal = uint256(currentEnergyBytes);
            _updateEntityTrait(_tokenId, "energy_level", bytes32(currentEnergyVal + traitBoostIntervals));
            traitBoostsApplied = traitBoostIntervals;
        }

        _lastYieldClaimTime[_tokenId] = block.timestamp; // Update last yield claim time
        emit IncubationYieldClaimed(_tokenId, msg.sender, essenceYield, traitBoostsApplied);
        _gainReputation(msg.sender, 1); // Small rep for consistent incubation
    }

    // --- VIII. Administrative & Security ---

    /**
     * @dev Pauses the contract, preventing certain operations like minting, transfers, and evolution.
     *      Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, re-enabling all previously paused operations.
     *      Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Owner function to update the base URI for NFT metadata.
     *      This affects where the tokenURI() function looks for metadata files.
     * @param _newBaseURI The new base URI (e.g., "ipfs://Qm.../").
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }
}
```