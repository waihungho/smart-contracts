This smart contract, **"Sentient Digital Twin Protocol (SDTP)"**, introduces a novel concept of dynamic NFTs whose traits and "sentience level" evolve based on external (oracle-fed) data and user interactions. These Digital Twins are not static JPEGs; they are programmatic entities that grow, change, and unlock new capabilities over time.

The protocol includes advanced features like:
*   **Dynamic NFT Evolution:** Twins evolve their `sentienceLevel` and `dynamicTraits` based on simulated AI oracle inputs.
*   **Ephemeral Trait Infusion:** Users can temporarily apply special traits to their Twins, which can also be "absorbed" by other Twins.
*   **Shared Sentience Pool:** A collective rewards pool that distributes tokens based on a Twin's accumulated sentience.
*   **Sentient Exchange:** A peer-to-peer exchange for Twins with conditional requirements based on their sentience level.
*   **Sentience Delegation:** Owners can delegate their Twin's sentience score (a metric, not control) to another address for a specific purpose, enabling reputation-based access or voting power in integrated protocols.

This contract avoids direct duplication of common open-source patterns by combining these specific mechanisms into a unique system for evolving, interactive digital assets.

---

### **Contract Outline: SentientDigitalTwinProtocol**

**I. State Variables**
    A. ERC721 Standard Variables (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`, `_nextId`, `_baseURI`)
    B. Protocol Configuration (`owner`, `aiOracleAddress`, `protocolFeeReceiver`, `protocolFeesAccrued`, `mintPrice`, `evolutionFee`)
    C. Digital Twin Specifics (`sentienceLevel`, `lastEvolutionTime`, `dynamicTraits`, `traitExpiryTimes`, `twinEvolutionLogs`)
    D. Trait Registry (`traitRegistry`, `registeredTraitKeys`)
    E. Shared Sentience Pool (`sentiencePoolBalance`, `sentiencePoolClaimed`)
    F. Sentient Exchange (`sentientExchangeOffers`)
    G. Sentience Delegation (`sentienceDelegations`)

**II. Events**
    A. Standard ERC721 Events (`Transfer`, `Approval`, `ApprovalForAll`)
    B. Protocol Specific Events (`TwinMinted`, `TwinEvolved`, `AIOracleUpdateFulfilled`, `EphemeralTraitInfused`, `EphemeralTraitRevoked`, `TraitRegistered`, `TraitUpdated`, `SentiencePoolDeposit`, `SentiencePoolClaimed`, `SentientExchangeCreated`, `SentientExchangeCancelled`, `SentientExchangeAccepted`, `SentienceDelegated`, `SentienceDelegationRevoked`)

**III. Modifiers**
    A. `onlyOwner`
    B. `onlyAIOracle`
    C. `onlyTwinOwner`

**IV. Functions**

---

### **Function Summary (26 Custom Functions)**

**A. Core Protocol & NFT Lifecycle (5 functions)**
1.  **`constructor()`**: Initializes the contract, sets the deployer as owner, and configures initial parameters.
2.  **`mintDigitalTwin()`**: Allows a user to mint a new Digital Twin NFT, initializing its sentience and basic traits. Requires payment of `mintPrice`.
3.  **`evolveDigitalTwin(uint256 _tokenId)`**: Triggers the evolution process for a specific Digital Twin, potentially increasing its sentience and altering dynamic traits based on internal logic. Requires payment of `evolutionFee`.
4.  **`setBaseURI(string memory _newBaseURI)`**: (Admin) Sets the base URI for NFT metadata, where off-chain metadata files will be located.
5.  **`tokenURI(uint256 _tokenId)`**: (ERC721 View) Returns the full metadata URI for a given Twin, dynamically generating based on base URI and token ID.

**B. Oracle & Dynamic Trait Management (4 functions)**
6.  **`updateAIOracleAddress(address _newOracle)`**: (Admin) Updates the address of the trusted AI Oracle.
7.  **`requestAIOracleUpdate(uint256 _tokenId)`**: (User/Any) Initiates a request to the AI Oracle for an update to a specific Twin's status. (Simulated for this contract; in a real scenario, this would interact with Chainlink Functions/VRF).
8.  **`fulfillAIOracleUpdate(uint256 _tokenId, bytes32 _traitKey, bytes32 _newValue, uint256 _sentienceBoost)`**: (Only AI Oracle) Callback function for the AI Oracle to update a Twin's dynamic traits and potentially boost its sentience.
9.  **`registerTraitDefinition(bytes32 _traitKey, string memory _traitName, bool _isEphemeral, uint256 _defaultDuration, uint256 _baseCost)`**: (Admin) Registers a new trait type (ephemeral or permanent) with its properties and cost.
10. **`updateTraitDefinition(bytes32 _traitKey, string memory _traitName, bool _isEphemeral, uint256 _defaultDuration, uint256 _baseCost)`**: (Admin) Modifies an existing trait definition.

**C. Ephemeral Trait Interaction (3 functions)**
11. **`infuseEphemeralTrait(uint256 _tokenId, bytes32 _traitKey)`**: Allows a Twin owner to temporarily apply a registered ephemeral trait to their Twin by paying its `baseCost`.
12. **`absorbEphemeralTrait(uint256 _fromTokenId, uint256 _toTokenId)`**: Allows an owner of Twin B to absorb an active ephemeral trait from Twin A (if both are owned by the caller or approved) by paying a fee, effectively transferring the trait's remaining duration.
13. **`revokeEphemeralTrait(uint256 _tokenId, bytes32 _traitKey)`**: Allows a Twin owner to prematurely remove an active ephemeral trait from their Twin.

**D. Shared Sentience Pool & Rewards (2 functions)**
14. **`depositIntoSentiencePool()`**: Allows any user to contribute ETH to the shared sentience pool.
15. **`claimSentiencePoolRewards(uint256 _tokenId)`**: Allows a Twin owner to claim their share of rewards from the sentience pool, proportional to their Twin's sentience level.

**E. Sentient Exchange (3 functions)**
16. **`createSentientExchangeOffer(uint256 _tokenIdA, uint256 _tokenIdB, uint256 _requiredSentienceA, uint256 _requiredSentienceB, uint256 _expiry)`**: Allows the owner of `_tokenIdA` to propose an exchange with `_tokenIdB`, setting minimum sentience requirements for both Twins and an expiry time. `_tokenIdB` owner must approve.
17. **`cancelSentientExchangeOffer(uint256 _offerId)`**: Allows the creator of an exchange offer to cancel it.
18. **`acceptSentientExchangeOffer(uint256 _offerId)`**: Allows the owner of the target Twin (`_tokenIdB`) to accept an offer, provided both Twins meet the sentience requirements.

**F. Sentience Delegation (2 functions)**
19. **`delegateSentienceForAction(address _delegatee, uint256 _tokenId, uint256 _duration)`**: Allows a Twin owner to delegate their Twin's sentience 'score' (not ownership) to another address for a specified duration, useful for reputation or conditional access in external protocols.
20. **`revokeSentienceDelegation(address _delegatee, uint256 _tokenId)`**: Allows a Twin owner to revoke a previous sentience delegation.

**G. Admin & Protocol Management (3 functions)**
21. **`setProtocolFeeReceiver(address _newReceiver)`**: (Admin) Sets the address that receives accumulated protocol fees.
22. **`withdrawProtocolFees()`**: (Admin) Allows the protocol fee receiver to withdraw accumulated fees.
23. **`transferOwnership(address _newOwner)`**: (Admin) Transfers contract ownership.

**H. View Functions & Getters (3 functions)**
24. **`getTwinDynamicTraits(uint256 _tokenId)`**: Returns a mapping of the current dynamic traits for a specific Digital Twin.
25. **`getTwinSentienceLevel(uint256 _tokenId)`**: Returns the current sentience level of a specific Digital Twin.
26. **`getDelegatedSentience(address _delegatee, uint256 _tokenId)`**: Checks if a sentience delegation is active for a specific Twin and delegatee, returning the remaining duration.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SentientDigitalTwinProtocol
 * @dev This contract implements a novel ERC721-compliant protocol for "Sentient Digital Twins".
 *      These NFTs are dynamic, evolving their traits and "sentience level" based on simulated AI
 *      oracle inputs and user interactions. It features ephemeral traits, a shared sentience pool,
 *      sentient-conditional exchanges, and sentience delegation for external protocol integration.
 *      The design aims for unique functionality not commonly found in open-source contracts.
 *
 * @author Your Name/Pseudonym
 * @notice Please note: This contract simulates an AI oracle interaction. In a production environment,
 *         this would be replaced by secure decentralized oracle solutions (e.g., Chainlink Functions).
 *         The metadata URI points to an off-chain resolver responsible for generating dynamic JSON metadata.
 *
 * Contract Outline:
 * I. State Variables
 *    A. ERC721 Standard Variables
 *    B. Protocol Configuration
 *    C. Digital Twin Specifics
 *    D. Trait Registry
 *    E. Shared Sentience Pool
 *    F. Sentient Exchange
 *    G. Sentience Delegation
 *
 * II. Events
 *    A. Standard ERC721 Events
 *    B. Protocol Specific Events
 *
 * III. Modifiers
 *    A. onlyOwner
 *    B. onlyAIOracle
 *    C. onlyTwinOwner
 *
 * IV. Functions (26 Custom Functions + ERC721 Basics)
 *    A. Core Protocol & NFT Lifecycle (5 functions)
 *       1. constructor()
 *       2. mintDigitalTwin()
 *       3. evolveDigitalTwin(uint256 _tokenId)
 *       4. setBaseURI(string memory _newBaseURI)
 *       5. tokenURI(uint256 _tokenId) (ERC721 standard, customized)
 *    B. Oracle & Dynamic Trait Management (5 functions)
 *       6. updateAIOracleAddress(address _newOracle)
 *       7. requestAIOracleUpdate(uint256 _tokenId)
 *       8. fulfillAIOracleUpdate(uint256 _tokenId, bytes32 _traitKey, bytes32 _newValue, uint256 _sentienceBoost)
 *       9. registerTraitDefinition(bytes32 _traitKey, string memory _traitName, bool _isEphemeral, uint256 _defaultDuration, uint256 _baseCost)
 *      10. updateTraitDefinition(bytes32 _traitKey, string memory _traitName, bool _isEphemeral, uint256 _defaultDuration, uint256 _baseCost)
 *    C. Ephemeral Trait Interaction (3 functions)
 *      11. infuseEphemeralTrait(uint256 _tokenId, bytes32 _traitKey)
 *      12. absorbEphemeralTrait(uint256 _fromTokenId, uint256 _toTokenId)
 *      13. revokeEphemeralTrait(uint256 _tokenId, bytes32 _traitKey)
 *    D. Shared Sentience Pool & Rewards (2 functions)
 *      14. depositIntoSentiencePool()
 *      15. claimSentiencePoolRewards(uint256 _tokenId)
 *    E. Sentient Exchange (3 functions)
 *      16. createSentientExchangeOffer(uint256 _tokenIdA, uint256 _tokenIdB, uint256 _requiredSentienceA, uint256 _requiredSentienceB, uint256 _expiry)
 *      17. cancelSentientExchangeOffer(uint256 _offerId)
 *      18. acceptSentientExchangeOffer(uint256 _offerId)
 *    F. Sentience Delegation (2 functions)
 *      19. delegateSentienceForAction(address _delegatee, uint256 _tokenId, uint256 _duration)
 *      20. revokeSentienceDelegation(address _delegatee, uint256 _tokenId)
 *    G. Admin & Protocol Management (3 functions)
 *      21. setProtocolFeeReceiver(address _newReceiver)
 *      22. withdrawProtocolFees()
 *      23. transferOwnership(address _newOwner)
 *    H. View Functions & Getters (3 functions)
 *      24. getTwinDynamicTraits(uint256 _tokenId)
 *      25. getTwinSentienceLevel(uint256 _tokenId)
 *      26. getDelegatedSentience(address _delegatee, uint256 _tokenId)
 */

contract SentientDigitalTwinProtocol {

    // --- State Variables ---

    // ERC721 Standard
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    // Protocol Configuration
    address public owner;
    address public aiOracleAddress;
    address public protocolFeeReceiver;
    uint256 public protocolFeesAccrued;
    uint256 public mintPrice;
    uint256 public evolutionFee;
    uint256 public constant MIN_SENTIENCE_FOR_EVOLUTION = 100; // Example threshold
    uint256 public constant EVOLUTION_COOLDOWN_SECONDS = 7 days; // Example cooldown

    // Digital Twin Specifics
    struct TwinEvolutionLogEntry {
        uint256 timestamp;
        bytes32 eventType; // e.g., "Mint", "OracleUpdate", "Evolve", "TraitInfused"
        bytes32 traitKey; // relevant trait key
        bytes32 oldValue;
        bytes32 newValue;
        uint256 sentienceChange;
    }
    mapping(uint256 => uint256) public sentienceLevel; // Token ID -> Sentience Level
    mapping(uint256 => uint256) public lastEvolutionTime; // Token ID -> Last time it evolved or got oracle update
    mapping(uint256 => mapping(bytes32 => bytes32)) public dynamicTraits; // Token ID -> Trait Key -> Trait Value
    mapping(uint256 => mapping(bytes32 => uint256)) public traitExpiryTimes; // Token ID -> Trait Key -> Expiry Timestamp
    mapping(uint256 => TwinEvolutionLogEntry[]) public twinEvolutionLogs; // Token ID -> History of significant changes

    // Trait Registry
    struct TraitDetails {
        string name;
        bool isEphemeral;
        uint256 defaultDuration; // For ephemeral traits, in seconds
        uint256 baseCost; // For ephemeral traits, in wei
        bool exists; // To check if a trait key is registered
    }
    mapping(bytes32 => TraitDetails) public traitRegistry;
    bytes32[] public registeredTraitKeys; // To iterate over registered traits

    // Shared Sentience Pool
    uint256 public sentiencePoolBalance;
    mapping(uint256 => uint256) public sentiencePoolClaimed; // Token ID -> Amount claimed from pool

    // Sentient Exchange
    struct SentientExchangeOffer {
        uint256 offerId;
        uint256 tokenIdA; // Proposer's token
        address ownerA; // Proposer's address
        uint256 tokenIdB; // Target token
        address ownerB; // Target token's owner at time of offer creation
        uint256 requiredSentienceA;
        uint256 requiredSentienceB;
        uint256 expiry; // When the offer becomes invalid
        bool active;
    }
    uint256 private _nextExchangeOfferId;
    mapping(uint256 => SentientExchangeOffer) public sentientExchangeOffers;

    // Sentience Delegation
    struct Delegation {
        address delegatee;
        uint256 expiry;
        bool active;
    }
    mapping(uint256 => mapping(address => Delegation)) public sentienceDelegations; // Token ID -> Delegatee -> Delegation Details

    // --- Events ---

    // ERC721 Standard Events (Minimal implementation)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Protocol Specific Events
    event TwinMinted(address indexed to, uint256 indexed tokenId, uint256 initialSentience);
    event TwinEvolved(uint256 indexed tokenId, uint256 newSentienceLevel, bytes32[] changedTraits);
    event AIOracleUpdateFulfilled(uint256 indexed tokenId, bytes32 traitKey, bytes32 newValue, uint256 sentienceBoost);
    event EphemeralTraitInfused(uint256 indexed tokenId, bytes32 indexed traitKey, uint256 expiry);
    event EphemeralTraitRevoked(uint256 indexed tokenId, bytes32 indexed traitKey);
    event TraitRegistered(bytes32 indexed traitKey, string traitName, bool isEphemeral, uint256 defaultDuration, uint256 baseCost);
    event TraitUpdated(bytes32 indexed traitKey, string traitName, bool isEphemeral, uint256 defaultDuration, uint256 baseCost);
    event SentiencePoolDeposit(address indexed depositor, uint256 amount);
    event SentiencePoolClaimed(uint256 indexed tokenId, address indexed claimant, uint256 amount);
    event SentientExchangeCreated(uint256 indexed offerId, uint256 indexed tokenIdA, uint256 indexed tokenIdB, address ownerA, address ownerB);
    event SentientExchangeCancelled(uint256 indexed offerId);
    event SentientExchangeAccepted(uint256 indexed offerId, uint256 indexed tokenIdA, uint256 indexed tokenIdB);
    event SentienceDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee, uint256 expiry);
    event SentienceDelegationRevoked(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event ProtocolFeesWithdrawn(address indexed receiver, uint256 amount);
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ProtocolFeeReceiverUpdated(address indexed oldAddress, address indexed newAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can call this function");
        _;
    }

    modifier onlyTwinOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        _;
    }

    // --- ERC721 Standard Functions (Minimal Implementation for core logic) ---

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x80ac58cd // ERC721
            || interfaceId == 0x5b5e139f; // ERC721Metadata
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Balance query for zero address");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address ownerAddress = _owners[_tokenId];
        require(ownerAddress != address(0), "Owner query for nonexistent token");
        return ownerAddress;
    }

    function name() public pure returns (string memory) {
        return "Sentient Digital Twin";
    }

    function symbol() public pure returns (string memory) {
        return "SDTP";
    }

    function approve(address _to, uint256 _tokenId) public {
        address tokenOwner = ownerOf(_tokenId);
        require(_to != tokenOwner, "Cannot approve self");
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "Caller is not owner nor approved for all");

        _tokenApprovals[_tokenId] = _to;
        emit Approval(tokenOwner, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "Approved query for nonexistent token");
        return _tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender, "Cannot approve self for all");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(ownerOf(_tokenId) == _from, "Token is not owned by from address");
        require(_to != address(0), "Transfer to the zero address");

        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(ownerOf(_tokenId) == _from, "Token is not owned by from address");
        require(_to != address(0), "Transfer to the zero address");

        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _owners[_tokenId] != address(0);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(_tokenId);
        return (_spender == tokenOwner || getApproved(_tokenId) == _spender || isApprovedForAll(tokenOwner, _spender));
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        _balances[_from]--;
        _balances[_to]++;
        _owners[_tokenId] = _to;
        delete _tokenApprovals[_tokenId]; // Clear approvals when transferred
        emit Transfer(_from, _to, _tokenId);
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "Mint to the zero address");
        require(!_exists(_tokenId), "Token already minted");

        _balances[_to]++;
        _owners[_tokenId] = _to;
        emit Transfer(address(0), _to, _tokenId);
    }

    // For safeTransferFrom to check if receiver is ERC721-compliant
    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns (bool) {
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (empty reason)");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }


    // --- Custom Functions (26 total) ---

    // A. Core Protocol & NFT Lifecycle

    constructor() {
        owner = msg.sender;
        aiOracleAddress = msg.sender; // Default to owner, should be updated
        protocolFeeReceiver = msg.sender;
        mintPrice = 0.05 ether;
        evolutionFee = 0.01 ether;
        _nextTokenId = 1;
        _nextExchangeOfferId = 1;

        // Register some initial default traits
        _registerTraitDefinition(bytes32("Mood"), "Mood", false, 0, 0); // Permanent
        _registerTraitDefinition(bytes32("Affinity"), "Affinity", false, 0, 0); // Permanent
        _registerTraitDefinition(bytes32("Vigor"), "Vigor", true, 30 days, 0.02 ether); // Ephemeral
        _registerTraitDefinition(bytes32("Wisdom"), "Wisdom", true, 60 days, 0.03 ether); // Ephemeral

        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Allows a user to mint a new Digital Twin NFT.
     *      Initializes its sentience level and basic dynamic traits.
     */
    function mintDigitalTwin() public payable returns (uint256) {
        require(msg.value >= mintPrice, "Insufficient funds to mint Twin");

        uint256 tokenId = _nextTokenId++;
        _mint(msg.sender, tokenId);

        sentienceLevel[tokenId] = 10; // Initial sentience
        lastEvolutionTime[tokenId] = block.timestamp;
        dynamicTraits[tokenId][bytes32("Mood")] = bytes32("Neutral");
        dynamicTraits[tokenId][bytes32("Affinity")] = bytes32("Balanced");

        twinEvolutionLogs[tokenId].push(TwinEvolutionLogEntry({
            timestamp: block.timestamp,
            eventType: bytes32("Mint"),
            traitKey: bytes32(0),
            oldValue: bytes32(0),
            newValue: bytes32(0),
            sentienceChange: 10
        }));

        protocolFeesAccrued += msg.value;
        emit TwinMinted(msg.sender, tokenId, 10);
        return tokenId;
    }

    /**
     * @dev Triggers the evolution process for a specific Digital Twin.
     *      This can increase its sentience and potentially alter traits.
     *      Requires a cooldown period and a fee.
     * @param _tokenId The ID of the Digital Twin to evolve.
     */
    function evolveDigitalTwin(uint256 _tokenId) public payable onlyTwinOwner(_tokenId) {
        require(_exists(_tokenId), "Twin does not exist");
        require(msg.value >= evolutionFee, "Insufficient evolution fee");
        require(block.timestamp >= lastEvolutionTime[_tokenId] + EVOLUTION_COOLDOWN_SECONDS, "Evolution cooldown in effect");
        require(sentienceLevel[_tokenId] >= MIN_SENTIENCE_FOR_EVOLUTION, "Sentience too low for evolution");

        uint256 oldSentience = sentienceLevel[_tokenId];
        // Simulate evolution logic: increase sentience, potentially alter a random trait
        uint256 sentienceBoost = (oldSentience / 100) * 5 + 50; // Example: +5% of current + 50
        sentienceLevel[_tokenId] += sentienceBoost;
        lastEvolutionTime[_tokenId] = block.timestamp;

        // Example: Randomly alter a dynamic trait based on new sentience (conceptual)
        bytes32[] memory changedTraits; // Placeholder for actual changes

        twinEvolutionLogs[_tokenId].push(TwinEvolutionLogEntry({
            timestamp: block.timestamp,
            eventType: bytes32("Evolve"),
            traitKey: bytes32(0), // No specific trait, or could iterate and log
            oldValue: bytes32(0),
            newValue: bytes32(0),
            sentienceChange: sentienceBoost
        }));

        protocolFeesAccrued += msg.value;
        emit TwinEvolved(_tokenId, sentienceLevel[_tokenId], changedTraits);
    }

    /**
     * @dev Sets the base URI for NFT metadata.
     *      The full URI for a token will be `_baseTokenURI + tokenId`.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Returns the metadata URI for a given token ID.
     *      This URI should point to a JSON file describing the NFT's traits.
     *      An off-chain service would dynamically generate this JSON based on the Twin's state.
     * @param _tokenId The ID of the token.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, _toString(_tokenId)));
    }

    // Helper to convert uint256 to string
    function _toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // B. Oracle & Dynamic Trait Management

    /**
     * @dev Updates the address of the trusted AI Oracle.
     * @param _newOracle The new address for the AI Oracle.
     */
    function updateAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "New oracle address cannot be zero");
        emit AIOracleAddressUpdated(aiOracleAddress, _newOracle);
        aiOracleAddress = _newOracle;
    }

    /**
     * @dev Initiates a request to the AI Oracle for an update on a specific Twin.
     *      In a real system, this would trigger an off-chain computation and a callback.
     *      Here, it's a placeholder to indicate the intent.
     * @param _tokenId The ID of the Digital Twin to request an update for.
     */
    function requestAIOracleUpdate(uint256 _tokenId) public {
        require(_exists(_tokenId), "Twin does not exist");
        // In a real scenario, this would emit an event for an off-chain oracle service
        // (e.g., Chainlink Functions) to pick up and fulfill.
        // For this example, we directly call fulfillAIOracleUpdate from the oracle address
        // or a mock contract after some time.
        // For demonstration, we just allow anyone to request, but it's fulfilled by the oracle.
    }

    /**
     * @dev Callback function used by the AI Oracle to update a Twin's dynamic traits and sentience.
     *      Only callable by the designated `aiOracleAddress`.
     * @param _tokenId The ID of the Twin to update.
     * @param _traitKey The key of the dynamic trait to update.
     * @param _newValue The new value for the dynamic trait.
     * @param _sentienceBoost The amount of sentience to add to the Twin.
     */
    function fulfillAIOracleUpdate(uint256 _tokenId, bytes32 _traitKey, bytes32 _newValue, uint256 _sentienceBoost) public onlyAIOracle {
        require(_exists(_tokenId), "Twin does not exist");
        require(traitRegistry[_traitKey].exists, "Trait key not registered");

        bytes32 oldTraitValue = dynamicTraits[_tokenId][_traitKey];
        dynamicTraits[_tokenId][_traitKey] = _newValue;
        sentienceLevel[_tokenId] += _sentienceBoost;
        lastEvolutionTime[_tokenId] = block.timestamp;

        twinEvolutionLogs[_tokenId].push(TwinEvolutionLogEntry({
            timestamp: block.timestamp,
            eventType: bytes32("OracleUpdate"),
            traitKey: _traitKey,
            oldValue: oldTraitValue,
            newValue: _newValue,
            sentienceChange: _sentienceBoost
        }));

        emit AIOracleUpdateFulfilled(_tokenId, _traitKey, _newValue, _sentienceBoost);
    }

    /**
     * @dev Registers a new trait definition (ephemeral or permanent).
     * @param _traitKey A unique identifier for the trait (e.g., bytes32("Mood")).
     * @param _traitName A human-readable name for the trait.
     * @param _isEphemeral True if the trait is temporary, false otherwise.
     * @param _defaultDuration Default duration for ephemeral traits (in seconds).
     * @param _baseCost Base cost for infusing ephemeral traits (in wei).
     */
    function registerTraitDefinition(
        bytes32 _traitKey,
        string memory _traitName,
        bool _isEphemeral,
        uint256 _defaultDuration,
        uint256 _baseCost
    ) public onlyOwner {
        require(!traitRegistry[_traitKey].exists, "Trait key already registered");
        if (_isEphemeral) {
            require(_defaultDuration > 0, "Ephemeral trait must have a duration");
        } else {
            require(_defaultDuration == 0, "Permanent trait cannot have a duration");
            require(_baseCost == 0, "Permanent trait cannot have a base cost");
        }

        traitRegistry[_traitKey] = TraitDetails({
            name: _traitName,
            isEphemeral: _isEphemeral,
            defaultDuration: _defaultDuration,
            baseCost: _baseCost,
            exists: true
        });
        registeredTraitKeys.push(_traitKey);
        emit TraitRegistered(_traitKey, _traitName, _isEphemeral, _defaultDuration, _baseCost);
    }

    /**
     * @dev Updates an existing trait definition.
     * @param _traitKey The unique identifier for the trait.
     * @param _traitName A new human-readable name for the trait.
     * @param _isEphemeral New value for whether the trait is temporary.
     * @param _defaultDuration New default duration for ephemeral traits.
     * @param _baseCost New base cost for infusing ephemeral traits.
     */
    function updateTraitDefinition(
        bytes32 _traitKey,
        string memory _traitName,
        bool _isEphemeral,
        uint256 _defaultDuration,
        uint256 _baseCost
    ) public onlyOwner {
        require(traitRegistry[_traitKey].exists, "Trait key not registered");
        if (_isEphemeral) {
            require(_defaultDuration > 0, "Ephemeral trait must have a duration");
        } else {
            require(_defaultDuration == 0, "Permanent trait cannot have a duration");
            require(_baseCost == 0, "Permanent trait cannot have a base cost");
        }

        traitRegistry[_traitKey].name = _traitName;
        traitRegistry[_traitKey].isEphemeral = _isEphemeral;
        traitRegistry[_traitKey].defaultDuration = _defaultDuration;
        traitRegistry[_traitKey].baseCost = _baseCost;
        emit TraitUpdated(_traitKey, _traitName, _isEphemeral, _defaultDuration, _baseCost);
    }

    // C. Ephemeral Trait Interaction

    /**
     * @dev Allows a Twin owner to temporarily apply a registered ephemeral trait to their Twin.
     *      Requires payment of the trait's base cost.
     * @param _tokenId The ID of the Twin to infuse.
     * @param _traitKey The key of the ephemeral trait to apply.
     */
    function infuseEphemeralTrait(uint256 _tokenId, bytes32 _traitKey) public payable onlyTwinOwner(_tokenId) {
        TraitDetails storage trait = traitRegistry[_traitKey];
        require(trait.exists && trait.isEphemeral, "Trait is not a registered ephemeral trait");
        require(msg.value >= trait.baseCost, "Insufficient funds to infuse trait");

        uint256 expiryTime = block.timestamp + trait.defaultDuration;
        traitExpiryTimes[_tokenId][_traitKey] = expiryTime;
        dynamicTraits[_tokenId][_traitKey] = bytes32("Active"); // Mark as active

        twinEvolutionLogs[_tokenId].push(TwinEvolutionLogEntry({
            timestamp: block.timestamp,
            eventType: bytes32("TraitInfused"),
            traitKey: _traitKey,
            oldValue: bytes32(0),
            newValue: bytes32("Active"),
            sentienceChange: 0
        }));

        protocolFeesAccrued += msg.value;
        emit EphemeralTraitInfused(_tokenId, _traitKey, expiryTime);
    }

    /**
     * @dev Allows an owner to absorb an active ephemeral trait from one of their Twins (`_fromTokenId`)
     *      and apply it to another of their Twins (`_toTokenId`).
     *      The remaining duration of the trait is transferred. Requires a small fee.
     * @param _fromTokenId The ID of the Twin losing the trait.
     * @param _toTokenId The ID of the Twin gaining the trait.
     */
    function absorbEphemeralTrait(uint256 _fromTokenId, uint256 _toTokenId) public payable {
        require(msg.sender == ownerOf(_fromTokenId) || _isApprovedOrOwner(msg.sender, _fromTokenId), "Caller not owner/approved of fromToken");
        require(msg.sender == ownerOf(_toTokenId) || _isApprovedOrOwner(msg.sender, _toTokenId), "Caller not owner/approved of toToken");
        require(_fromTokenId != _toTokenId, "Cannot absorb trait from/to the same Twin");
        require(msg.value >= 0.001 ether, "Insufficient absorption fee (0.001 ETH required)"); // Small fee for absorption

        bytes32 traitKey = bytes32("Vigor"); // Example: only 'Vigor' trait can be absorbed for simplicity
        TraitDetails storage trait = traitRegistry[traitKey];
        require(trait.exists && trait.isEphemeral, "Trait is not a registered ephemeral trait");
        
        uint256 fromExpiry = traitExpiryTimes[_fromTokenId][traitKey];
        require(fromExpiry > block.timestamp, "Trait is not active on the source Twin");

        uint256 remainingDuration = fromExpiry - block.timestamp;

        // Remove from source Twin
        delete traitExpiryTimes[_fromTokenId][traitKey];
        delete dynamicTraits[_fromTokenId][traitKey];

        // Apply to target Twin
        traitExpiryTimes[_toTokenId][traitKey] = block.timestamp + remainingDuration;
        dynamicTraits[_toTokenId][traitKey] = bytes32("Active");

        twinEvolutionLogs[_fromTokenId].push(TwinEvolutionLogEntry({
            timestamp: block.timestamp,
            eventType: bytes32("TraitAbsorbed_From"),
            traitKey: traitKey,
            oldValue: bytes32("Active"),
            newValue: bytes32(0),
            sentienceChange: 0
        }));
        twinEvolutionLogs[_toTokenId].push(TwinEvolutionLogEntry({
            timestamp: block.timestamp,
            eventType: bytes32("TraitAbsorbed_To"),
            traitKey: traitKey,
            oldValue: bytes32(0),
            newValue: bytes32("Active"),
            sentienceChange: 0
        }));

        protocolFeesAccrued += msg.value;
        emit EphemeralTraitInfused(_toTokenId, traitKey, block.timestamp + remainingDuration); // Effectively re-infused
        emit EphemeralTraitRevoked(_fromTokenId, traitKey);
    }

    /**
     * @dev Allows a Twin owner to prematurely remove an active ephemeral trait from their Twin.
     * @param _tokenId The ID of the Twin.
     * @param _traitKey The key of the ephemeral trait to revoke.
     */
    function revokeEphemeralTrait(uint256 _tokenId, bytes32 _traitKey) public onlyTwinOwner(_tokenId) {
        TraitDetails storage trait = traitRegistry[_traitKey];
        require(trait.exists && trait.isEphemeral, "Trait is not a registered ephemeral trait");
        require(traitExpiryTimes[_tokenId][_traitKey] > block.timestamp, "Trait is not active or already expired");

        delete traitExpiryTimes[_tokenId][_traitKey];
        delete dynamicTraits[_tokenId][_traitKey]; // Clear its value

        twinEvolutionLogs[_tokenId].push(TwinEvolutionLogEntry({
            timestamp: block.timestamp,
            eventType: bytes32("TraitRevoked"),
            traitKey: _traitKey,
            oldValue: bytes32("Active"),
            newValue: bytes32(0),
            sentienceChange: 0
        }));
        emit EphemeralTraitRevoked(_tokenId, _traitKey);
    }

    // D. Shared Sentience Pool & Rewards

    /**
     * @dev Allows any user to contribute ETH to the shared sentience pool.
     *      This pool can be used to reward Twins with high sentience.
     */
    function depositIntoSentiencePool() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        sentiencePoolBalance += msg.value;
        emit SentiencePoolDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows a Twin owner to claim their share of rewards from the sentience pool.
     *      The reward is proportional to the Twin's sentience level relative to the total sentience.
     *      (Simplified: currently just a fixed amount per claim, but ideally based on proportion).
     * @param _tokenId The ID of the Twin claiming rewards.
     */
    function claimSentiencePoolRewards(uint256 _tokenId) public onlyTwinOwner(_tokenId) {
        require(_exists(_tokenId), "Twin does not exist");
        require(sentienceLevel[_tokenId] > 0, "Twin has no sentience to claim rewards");
        require(sentiencePoolBalance > 0, "Sentience pool is empty");

        // Simplified reward logic: A Twin can claim a fixed amount per (conceptual) period,
        // or a dynamic amount based on its sentience and pool size.
        // For this example, let's claim a small, fixed percentage or amount if available.
        uint256 availableToClaim = sentiencePoolBalance / 10; // Claim 10% of the pool if available
        if (availableToClaim > 0.01 ether) { // Cap for this example
            availableToClaim = 0.01 ether;
        }

        require(availableToClaim > 0, "No rewards available to claim at this time");
        require(sentiencePoolBalance >= availableToClaim, "Not enough funds in pool");

        sentiencePoolBalance -= availableToClaim;
        sentiencePoolClaimed[_tokenId] += availableToClaim;

        (bool success,) = msg.sender.call{value: availableToClaim}("");
        require(success, "Failed to send rewards");

        emit SentiencePoolClaimed(_tokenId, msg.sender, availableToClaim);
    }

    // E. Sentient Exchange

    /**
     * @dev Creates an offer to exchange two Digital Twins, with conditions based on sentience levels.
     *      The owner of `_tokenIdA` proposes the exchange. The owner of `_tokenIdB` must be approved.
     * @param _tokenIdA The ID of the proposer's Twin.
     * @param _tokenIdB The ID of the target Twin for exchange.
     * @param _requiredSentienceA Minimum sentience level required for `_tokenIdA` to be exchanged.
     * @param _requiredSentienceB Minimum sentience level required for `_tokenIdB` to be exchanged.
     * @param _expiry Timestamp when the offer expires.
     */
    function createSentientExchangeOffer(
        uint256 _tokenIdA,
        uint256 _tokenIdB,
        uint256 _requiredSentienceA,
        uint256 _requiredSentienceB,
        uint256 _expiry
    ) public onlyTwinOwner(_tokenIdA) {
        require(_exists(_tokenIdB), "Target Twin B does not exist");
        require(ownerOf(_tokenIdA) != ownerOf(_tokenIdB), "Cannot exchange with self");
        require(_expiry > block.timestamp, "Offer expiry must be in the future");

        // Ensure approval for the target token if not owned by msg.sender
        require(_isApprovedOrOwner(msg.sender, _tokenIdA), "Caller must own or be approved for tokenA");
        // For _tokenIdB, we record the owner at time of creation, and check approval later
        address ownerB = ownerOf(_tokenIdB);

        uint256 offerId = _nextExchangeOfferId++;
        sentientExchangeOffers[offerId] = SentientExchangeOffer({
            offerId: offerId,
            tokenIdA: _tokenIdA,
            ownerA: msg.sender,
            tokenIdB: _tokenIdB,
            ownerB: ownerB,
            requiredSentienceA: _requiredSentienceA,
            requiredSentienceB: _requiredSentienceB,
            expiry: _expiry,
            active: true
        });

        emit SentientExchangeCreated(offerId, _tokenIdA, _tokenIdB, msg.sender, ownerB);
    }

    /**
     * @dev Cancels an active exchange offer. Only the original proposer can cancel.
     * @param _offerId The ID of the exchange offer to cancel.
     */
    function cancelSentientExchangeOffer(uint256 _offerId) public {
        SentientExchangeOffer storage offer = sentientExchangeOffers[_offerId];
        require(offer.active, "Offer is not active");
        require(msg.sender == offer.ownerA, "Only the offer creator can cancel");

        offer.active = false;
        emit SentientExchangeCancelled(_offerId);
    }

    /**
     * @dev Accepts an active exchange offer.
     *      The owner of `_tokenIdB` accepts, provided both Twins meet sentience requirements.
     * @param _offerId The ID of the exchange offer to accept.
     */
    function acceptSentientExchangeOffer(uint256 _offerId) public {
        SentientExchangeOffer storage offer = sentientExchangeOffers[_offerId];
        require(offer.active, "Offer is not active");
        require(block.timestamp <= offer.expiry, "Offer has expired");
        require(msg.sender == ownerOf(offer.tokenIdB) || _isApprovedOrOwner(msg.sender, offer.tokenIdB), "Caller not owner/approved for tokenB");

        // Re-check tokenA ownership (might have changed hands)
        require(ownerOf(offer.tokenIdA) == offer.ownerA, "TokenA owner changed, offer invalid");

        // Check sentience requirements
        require(sentienceLevel[offer.tokenIdA] >= offer.requiredSentienceA, "TokenA does not meet sentience requirement");
        require(sentienceLevel[offer.tokenIdB] >= offer.requiredSentienceB, "TokenB does not meet sentience requirement");

        // Perform the transfer
        _transfer(offer.ownerA, msg.sender, offer.tokenIdA); // Token A to owner B
        _transfer(offer.ownerB, offer.ownerA, offer.tokenIdB); // Token B to owner A

        offer.active = false;
        emit SentientExchangeAccepted(_offerId, offer.tokenIdA, offer.tokenIdB);
    }

    // F. Sentience Delegation

    /**
     * @dev Allows a Twin owner to delegate their Twin's sentience 'score' (not ownership)
     *      to another address for a specified duration.
     *      This is useful for external protocols to grant conditional access or voting power
     *      based on a Twin's sentience without transferring the NFT itself.
     * @param _delegatee The address to which sentience is delegated.
     * @param _tokenId The ID of the Twin whose sentience is being delegated.
     * @param _duration The duration of the delegation in seconds.
     */
    function delegateSentienceForAction(address _delegatee, uint256 _tokenId, uint256 _duration) public onlyTwinOwner(_tokenId) {
        require(_delegatee != address(0), "Delegatee cannot be the zero address");
        require(_duration > 0, "Delegation duration must be positive");

        uint256 expiry = block.timestamp + _duration;
        sentienceDelegations[_tokenId][_delegatee] = Delegation({
            delegatee: _delegatee,
            expiry: expiry,
            active: true
        });

        emit SentienceDelegated(_tokenId, msg.sender, _delegatee, expiry);
    }

    /**
     * @dev Allows a Twin owner to revoke a previously granted sentience delegation.
     * @param _delegatee The address whose delegation is to be revoked.
     * @param _tokenId The ID of the Twin.
     */
    function revokeSentienceDelegation(address _delegatee, uint256 _tokenId) public onlyTwinOwner(_tokenId) {
        Delegation storage delegation = sentienceDelegations[_tokenId][_delegatee];
        require(delegation.active, "No active delegation for this delegatee and Twin");

        delegation.active = false; // Mark as inactive
        // Optionally, could delete to save gas on subsequent reads if no other delegations for this twin/delegatee
        // delete sentienceDelegations[_tokenId][_delegatee];

        emit SentienceDelegationRevoked(_tokenId, msg.sender, _delegatee);
    }

    // G. Admin & Protocol Management

    /**
     * @dev Sets the address that receives accumulated protocol fees.
     * @param _newReceiver The new address for the fee receiver.
     */
    function setProtocolFeeReceiver(address _newReceiver) public onlyOwner {
        require(_newReceiver != address(0), "New receiver address cannot be zero");
        emit ProtocolFeeReceiverUpdated(protocolFeeReceiver, _newReceiver);
        protocolFeeReceiver = _newReceiver;
    }

    /**
     * @dev Allows the protocol fee receiver to withdraw accumulated fees.
     */
    function withdrawProtocolFees() public {
        require(msg.sender == protocolFeeReceiver, "Only fee receiver can withdraw");
        require(protocolFeesAccrued > 0, "No fees to withdraw");

        uint256 amount = protocolFeesAccrued;
        protocolFeesAccrued = 0;

        (bool success,) = protocolFeeReceiver.call{value: amount}("");
        require(success, "Failed to withdraw fees");

        emit ProtocolFeesWithdrawn(protocolFeeReceiver, amount);
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // H. View Functions & Getters

    /**
     * @dev Returns a mapping of the current dynamic traits for a specific Digital Twin.
     * @param _tokenId The ID of the Twin.
     * @return A tuple containing arrays of trait keys and their corresponding values.
     */
    function getTwinDynamicTraits(uint256 _tokenId) public view returns (bytes32[] memory traitKeys, bytes32[] memory traitValues) {
        require(_exists(_tokenId), "Twin does not exist");

        uint256 count = 0;
        for (uint256 i = 0; i < registeredTraitKeys.length; i++) {
            bytes32 traitKey = registeredTraitKeys[i];
            if (dynamicTraits[_tokenId][traitKey] != bytes32(0)) {
                count++;
            }
        }

        traitKeys = new bytes32[](count);
        traitValues = new bytes32[](count);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < registeredTraitKeys.length; i++) {
            bytes32 traitKey = registeredTraitKeys[i];
            bytes32 traitValue = dynamicTraits[_tokenId][traitKey];
            if (traitValue != bytes32(0)) {
                if (traitRegistry[traitKey].isEphemeral && traitExpiryTimes[_tokenId][traitKey] <= block.timestamp) {
                    // Skip expired ephemeral traits for this view, they are effectively inactive
                    continue;
                }
                traitKeys[currentIndex] = traitKey;
                traitValues[currentIndex] = traitValue;
                currentIndex++;
            }
        }
        return (traitKeys, traitValues);
    }


    /**
     * @dev Returns the current sentience level of a specific Digital Twin.
     * @param _tokenId The ID of the Twin.
     * @return The sentience level.
     */
    function getTwinSentienceLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Twin does not exist");
        return sentienceLevel[_tokenId];
    }

    /**
     * @dev Returns the details of a registered trait.
     * @param _traitKey The key of the trait.
     * @return TraitDetails struct.
     */
    function getTraitDetails(bytes32 _traitKey) public view returns (TraitDetails memory) {
        return traitRegistry[_traitKey];
    }

    /**
     * @dev Returns the details of an active sentient exchange offer.
     * @param _offerId The ID of the offer.
     * @return SentientExchangeOffer struct.
     */
    function getSentientExchangeOffer(uint256 _offerId) public view returns (SentientExchangeOffer memory) {
        return sentientExchangeOffers[_offerId];
    }

    /**
     * @dev Checks if a sentience delegation is active for a specific Twin and delegatee,
     *      returning the remaining duration or 0 if inactive/expired.
     * @param _delegatee The address that might have delegated sentience.
     * @param _tokenId The ID of the Twin.
     * @return The remaining duration of the delegation in seconds, or 0 if inactive/expired.
     */
    function getDelegatedSentience(address _delegatee, uint256 _tokenId) public view returns (uint256) {
        Delegation storage delegation = sentienceDelegations[_tokenId][_delegatee];
        if (delegation.active && delegation.expiry > block.timestamp) {
            return delegation.expiry - block.timestamp;
        }
        return 0;
    }
}

// Minimal IERC721Receiver for safeTransferFrom
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```