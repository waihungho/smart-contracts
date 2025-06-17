Okay, here is a Solidity smart contract demonstrating a system for "Evolving Digital Companions" (EDCs). This concept involves dynamic NFTs whose traits and state change based on on-chain interactions, time staked, and a simulated interaction with an "AI Oracle" for trait evolution.

It incorporates:
1.  **Dynamic NFTs:** Metadata changes based on on-chain state.
2.  **State-Based Evolution:** Companions gain "Energy" from interactions (feeding) and can undergo "Upgrades".
3.  **Time-Based Mechanics:** Staking and Missions that affect the companion's state and potential rewards.
4.  **Simulated Oracle Interaction:** A mechanism to request and fulfill trait changes based on external data (simulated here via an authorized address).
5.  **Internal Resource Management:** Tracking "Energy" or "XP".
6.  **Pausability and Ownership:** Standard access control patterns.

This goes beyond a simple static NFT or basic token.

---

### Smart Contract Outline & Function Summary

**Contract Name:** EvolvingCompanions

**Description:** A smart contract for dynamic NFTs ("Digital Companions") that evolve based on user interaction, time-based mechanics (staking, missions), and simulated oracle influence. Traits and metadata are intended to be dynamic.

**Core Concepts:**
*   **Dynamic NFT (ERC721):** Token URI changes based on on-chain state.
*   **Companion State:** Tracks energy/XP, staking status, mission status.
*   **Companion Traits:** Stores various attributes that can change.
*   **Energy/XP:** Gained through interactions, consumed for upgrades or evolution requests.
*   **Staking:** Lock NFT for time-based benefits (potentially passive energy gain).
*   **Missions:** Lock NFT for a duration to earn rewards (simulated) and influence state.
*   **AI Oracle (Simulated):** An authorized address that can fulfill trait evolution requests.

**Functions Summary:**

**Core NFT (ERC721 Standard & Extensions):**
1.  `constructor()`: Initializes contract, sets base URI, owner.
2.  `mintCompanion(address to)`: Mints a new ERC721 token (Companion) to an address with initial state/traits.
3.  `balanceOf(address owner) view`: Returns the number of tokens owned by an address. (ERC721)
4.  `ownerOf(uint256 tokenId) view`: Returns the owner of a specific token. (ERC721)
5.  `getApproved(uint256 tokenId) view`: Returns the approved address for a token. (ERC721)
6.  `isApprovedForAll(address owner, address operator) view`: Checks if an operator is approved for all tokens of an owner. (ERC721)
7.  `approve(address to, uint256 tokenId)`: Approves an address to spend a token. (ERC721)
8.  `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all tokens. (ERC721)
9.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership. (ERC721)
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers token ownership. (ERC721)
11. `supportsInterface(bytes4 interfaceId) view`: Checks if the contract supports an interface. (ERC165/ERC721)
12. `tokenURI(uint256 tokenId) view`: Returns the dynamic metadata URI for a token. (ERC721 Metadata)

**Companion State & Interaction:**
13. `getCompanionState(uint256 tokenId) view`: Retrieves the current state of a companion (energy, staking, mission status, timestamps).
14. `getCompanionTraits(uint256 tokenId) view`: Retrieves the current traits of a companion.
15. `getCompanionEnergy(uint256 tokenId) view`: Gets the current energy level of a companion.
16. `getCompanionMissionStatus(uint256 tokenId) view`: Gets detailed status of a companion's current mission.
17. `stakeCompanion(uint256 tokenId)`: Locks a companion for staking (prevents transfer).
18. `unstakeCompanion(uint256 tokenId)`: Unlocks a staked companion.
19. `feedCompanion(uint256 tokenId)`: Interacts with a companion, adding energy/XP.
20. `sendOnMission(uint256 tokenId, uint256 missionDuration)`: Sends a companion on a mission (locks, sets duration).
21. `completeMission(uint256 tokenId)`: Completes a mission, potentially awarding energy/rewards, and unlocks.
22. `upgradeCompanion(uint256 tokenId)`: Attempts to upgrade companion stats/traits, consuming energy/cost.

**Evolution & Oracle Interaction:**
23. `requestTraitEvolution(uint256 tokenId)`: Initiates a request for the AI Oracle to evolve traits, consuming energy/cost.
24. `fulfillTraitEvolution(uint256 tokenId, bytes memory newTraitData, bytes memory signature)`: (Simulated Oracle Callback) Called by the oracle address to update traits based on off-chain logic/data. Includes signature for basic authentication (simulated).

**Admin & Parameter Configuration:**
25. `setOracleAddress(address _oracleAddress)`: Sets the authorized address for fulfilling evolution requests. (Owner)
26. `setMissionParameters(uint256 minDuration, uint256 maxDuration, uint256 baseEnergyReward)`: Configures mission parameters. (Owner)
27. `setFeedParameters(uint256 energyGainPerFeed, uint256 feedCooldown)`: Configures feeding parameters. (Owner)
28. `setEvolutionCost(uint256 energyCost, uint256 ethCost)`: Configures costs for requesting evolution. (Owner)
29. `setUpgradeCost(uint256 energyCost, uint256 ethCost)`: Configures costs for upgrades. (Owner)
30. `setBaseTokenURI(string memory _baseURI)`: Sets the base URI for metadata. (Owner)
31. `pause()`: Pauses core interactions. (Owner)
32. `unpause()`: Unpauses core interactions. (Owner)
33. `withdrawEth(address payable recipient)`: Withdraws ETH from the contract. (Owner)
34. `withdrawToken(address tokenAddress, address recipient)`: Withdraws specific tokens from the contract. (Owner)

**Note:** The "AI Oracle" and dynamic metadata server are assumed off-chain components. The contract provides the on-chain logic to interact with them. Signature validation in `fulfillTraitEvolution` is a simplified simulation; a real oracle might use more robust methods (e.g., Chainlink, custom signature schemes). Dynamic metadata requires an off-chain server listening to contract events or reading state to generate JSON.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For tokenOfOwnerByIndex if needed, removed for conciseness to keep function count focused on core logic
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // Base for dynamic URI
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice, though not strictly needed for current functions
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For withdrawing other tokens

// Custom Errors for clarity
error NotCompanionOwner();
error CompanionNotStaked();
error CompanionAlreadyStaked();
error CompanionOnMission();
error CompanionNotOnMission();
error MissionNotComplete();
error CompanionNotReadyForFeed();
error InsufficientEnergy();
error InsufficientFunds();
error TraitEvolutionRequestPending();
error NoTraitEvolutionRequestPending();
error InvalidOracleSignature(); // Simulated signature validation error
error UnauthorizedOracle();
error InvalidMissionDuration();

contract EvolvingCompanions is ERC721URIStorage, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // Structs defining the companion's state and traits
    struct CompanionState {
        uint256 energy;             // Current energy/XP level
        bool isStaked;              // Whether the companion is staked
        bool isOnMission;           // Whether the companion is on a mission
        uint64 missionEndTime;      // Unix timestamp when mission ends
        uint64 lastFeedTime;        // Unix timestamp of last feeding
        bool evolutionRequested;    // True if evolution request is pending oracle callback
    }

    struct CompanionTraits {
        uint8 vitality;             // Example trait
        uint8 intelligence;         // Example trait
        uint8 strength;             // Example trait
        uint8 agility;              // Example trait
        // Potentially many more traits
        bytes dynamicData;          // Placeholder for more complex or raw trait data
    }

    struct MissionParameters {
        uint256 minDuration;        // Minimum mission duration in seconds
        uint256 maxDuration;        // Maximum mission duration in seconds
        uint256 baseEnergyReward;   // Base energy awarded upon mission completion
        // Potentially add variable rewards based on duration/traits
    }

    mapping(uint256 => CompanionState) private _companionStates;
    mapping(uint256 => CompanionTraits) private _companionTraits;

    address private _oracleAddress; // Address authorized to fulfill evolution requests

    // Configuration parameters
    MissionParameters public missionParams;
    uint256 public energyGainPerFeed;
    uint256 public feedCooldown;        // Cooldown in seconds
    uint256 public traitEvolutionEnergyCost;
    uint256 public traitEvolutionEthCost;
    uint256 public upgradeEnergyCost;
    uint256 public upgradeEthCost;

    // --- Events ---

    event CompanionMinted(address indexed owner, uint256 indexed tokenId);
    event CompanionStaked(uint256 indexed tokenId);
    event CompanionUnstaked(uint256 indexed tokenId);
    event CompanionFed(uint256 indexed tokenId, uint256 newEnergy);
    event MissionStarted(uint256 indexed tokenId, uint64 missionEndTime);
    event MissionCompleted(uint256 indexed tokenId, uint256 energyRewarded);
    event TraitEvolutionRequested(uint256 indexed tokenId);
    event TraitEvolutionFulfilled(uint256 indexed tokenId, bytes newTraitData);
    event CompanionUpgraded(uint256 indexed tokenId, uint256 energyConsumed);
    event OracleAddressUpdated(address indexed newOracleAddress);
    event BaseTokenURIUpdated(string newURI);

    // --- Modifiers ---

    modifier onlyCompanionOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert NotCompanionOwner();
        }
        _;
    }

    modifier notStakedOrOnMission(uint256 tokenId) {
        CompanionState storage state = _companionStates[tokenId];
        if (state.isStaked) {
            revert CompanionAlreadyStaked();
        }
        if (state.isOnMission) {
            revert CompanionOnMission();
        }
        _;
    }

    modifier staked(uint256 tokenId) {
        if (!_companionStates[tokenId].isStaked) {
            revert CompanionNotStaked();
        }
        _;
    }

    modifier onMission(uint256 tokenId) {
        if (!_companionStates[tokenId].isOnMission) {
            revert CompanionNotOnMission();
        }
        _;
    }

    modifier missionComplete(uint256 tokenId) {
        if (_companionStates[tokenId].missionEndTime > block.timestamp) {
            revert MissionNotComplete();
        }
        _;
    }

    modifier onlyOracle() {
        if (_msgSender() != _oracleAddress) {
            revert UnauthorizedOracle();
        }
        _;
    }

    modifier evolutionRequestPending(uint256 tokenId) {
         if (!_companionStates[tokenId].evolutionRequested) {
            revert NoTraitEvolutionRequestPending();
        }
        _;
    }

     modifier noEvolutionRequestPending(uint256 tokenId) {
         if (_companionStates[tokenId].evolutionRequested) {
            revert TraitEvolutionRequestPending();
        }
        _;
    }


    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        address initialOracleAddress,
        MissionParameters memory _missionParams,
        uint256 _energyGainPerFeed,
        uint256 _feedCooldown,
        uint256 _traitEvolutionEnergyCost,
        uint256 _traitEvolutionEthCost,
        uint256 _upgradeEnergyCost,
        uint256 _upgradeEthCost
    ) ERC721(name, symbol) ERC721URIStorage(baseTokenURI_) Ownable(_msgSender()) {
        _oracleAddress = initialOracleAddress;
        missionParams = _missionParams;
        energyGainPerFeed = _energyGainPerFeed;
        feedCooldown = _feedCooldown;
        traitEvolutionEnergyCost = _traitEvolutionEnergyCost;
        traitEvolutionEthCost = _traitEvolutionEthCost;
        upgradeEnergyCost = _upgradeEnergyCost;
        upgradeEthCost = _upgradeEthCost;
    }

    // --- Core NFT Functions (Standard & Extended) ---

    // Function 2: Mint a new companion
    function mintCompanion(address to)
        public
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Assign initial default or random-ish traits and state
        _companionTraits[newItemId] = CompanionTraits({
            vitality: uint8(10),
            intelligence: uint8(10),
            strength: uint8(10),
            agility: uint8(10),
            dynamicData: "" // Placeholder
        });

        _companionStates[newItemId] = CompanionState({
            energy: 0,
            isStaked: false,
            isOnMission: false,
            missionEndTime: 0,
            lastFeedTime: 0,
            evolutionRequested: false
        });

        _safeMint(to, newItemId);
        emit CompanionMinted(to, newItemId);

        return newItemId;
    }

    // Functions 3-11: Standard ERC721 functions are inherited/implemented by OpenZeppelin
    // For completeness, listing the publicly exposed ones:
    // 3: balanceOf(address owner) view
    // 4: ownerOf(uint256 tokenId) view
    // 5: getApproved(uint256 tokenId) view
    // 6: isApprovedForAll(address owner, address operator) view
    // 7: approve(address to, uint256 tokenId)
    // 8: setApprovalForAll(address operator, bool approved)
    // 9: transferFrom(address from, address to, uint256 tokenId)
    // 10: safeTransferFrom(address from, address to, uint256 tokenId)
    // 11: supportsInterface(bytes4 interfaceId) view // Overridden to support ERC721URIStorage

    // Function 12: Dynamic Token URI (Overrides ERC721URIStorage)
    // This function relies on an off-chain service to serve the metadata JSON
    // The server should read the on-chain state/traits of the token and generate the JSON dynamically.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage) // Explicit override for clarity
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        string memory base = _baseURI();
        string memory companionId = Strings.toString(tokenId);

        // Append query parameters or path segments based on state/traits
        // Example: appending state info to help the metadata server
        CompanionState storage state = _companionStates[tokenId];
        string memory dynamicPart = string.concat(
            "?state=", Strings.toString(uint256(state.isStaked)),
            "&mission=", Strings.toString(uint256(state.isOnMission)),
            "&energy=", Strings.toString(state.energy),
            "&vitality=", Strings.toString(_companionTraits[tokenId].vitality) // Example trait
            // ... add other relevant state/trait parameters ...
        );

        return string.concat(base, companionId, dynamicPart);
    }

    // --- Companion State & Interaction Functions ---

    // Function 13: Get Companion State
    function getCompanionState(uint256 tokenId)
        public
        view
        returns (CompanionState memory)
    {
        _requireOwned(tokenId); // Ensure token exists and sender could potentially own it (or view)
        return _companionStates[tokenId];
    }

    // Function 14: Get Companion Traits
     function getCompanionTraits(uint256 tokenId)
        public
        view
        returns (CompanionTraits memory)
    {
         _requireOwned(tokenId); // Ensure token exists
        return _companionTraits[tokenId];
    }

    // Function 15: Get Companion Energy
     function getCompanionEnergy(uint256 tokenId)
        public
        view
        returns (uint256)
    {
         _requireOwned(tokenId); // Ensure token exists
        return _companionStates[tokenId].energy;
    }

    // Function 16: Get Companion Mission Status
     function getCompanionMissionStatus(uint256 tokenId)
        public
        view
        returns (uint64 missionEndTime, bool isOnMission)
    {
         _requireOwned(tokenId); // Ensure token exists
         CompanionState storage state = _companionStates[tokenId];
        return (state.missionEndTime, state.isOnMission);
    }


    // Function 17: Stake Companion
    function stakeCompanion(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        onlyCompanionOwner(tokenId)
        notStakedOrOnMission(tokenId)
    {
        _companionStates[tokenId].isStaked = true;
        // Note: Staked companions might passively gain energy over time (off-chain calculation or on-chain with checkpoints)
        // For simplicity, we don't add passive gain in this version, but the state change is recorded.
        emit CompanionStaked(tokenId);
    }

    // Function 18: Unstake Companion
    function unstakeCompanion(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        onlyCompanionOwner(tokenId)
        staked(tokenId)
    {
        _companionStates[tokenId].isStaked = false;
        emit CompanionUnstaked(tokenId);
    }

    // Function 19: Feed Companion
    function feedCompanion(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        onlyCompanionOwner(tokenId)
        notStakedOrOnMission(tokenId) // Cannot feed while on mission/staked (example logic)
    {
        CompanionState storage state = _companionStates[tokenId];
        if (state.lastFeedTime + feedCooldown > block.timestamp) {
            revert CompanionNotReadyForFeed();
        }

        state.energy += energyGainPerFeed;
        state.lastFeedTime = uint64(block.timestamp);

        emit CompanionFed(tokenId, state.energy);
    }

    // Function 20: Send On Mission
    function sendOnMission(uint256 tokenId, uint256 missionDuration)
        public
        nonReentrant
        whenNotPaused
        onlyCompanionOwner(tokenId)
        notStakedOrOnMission(tokenId) // Cannot send on mission if staked/already on mission
    {
        if (missionDuration < missionParams.minDuration || missionDuration > missionParams.maxDuration) {
            revert InvalidMissionDuration();
        }

        CompanionState storage state = _companionStates[tokenId];
        state.isOnMission = true;
        state.missionEndTime = uint64(block.timestamp + missionDuration);

        // Revoke approvals while on mission (optional, adds security)
        _approve(address(0), tokenId);

        emit MissionStarted(tokenId, state.missionEndTime);
    }

    // Function 21: Complete Mission
    function completeMission(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        onlyCompanionOwner(tokenId)
        onMission(tokenId)
        missionComplete(tokenId)
    {
        CompanionState storage state = _companionStates[tokenId];

        // Calculate potential rewards (simple example: base reward)
        uint256 rewardEnergy = missionParams.baseEnergyReward;
        // More complex logic could involve mission duration, companion traits, etc.

        state.isOnMission = false;
        state.missionEndTime = 0; // Reset mission end time
        state.energy += rewardEnergy; // Add rewards

        emit MissionCompleted(tokenId, rewardEnergy);
    }

    // Function 22: Upgrade Companion (Consumes Energy/Cost)
    function upgradeCompanion(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        payable // May require ETH
        onlyCompanionOwner(tokenId)
        notStakedOrOnMission(tokenId)
        noEvolutionRequestPending(tokenId) // Cannot upgrade while evolution is pending
    {
        CompanionState storage state = _companionStates[tokenId];
        if (state.energy < upgradeEnergyCost) {
            revert InsufficientEnergy();
        }
         if (msg.value < upgradeEthCost) {
            revert InsufficientFunds();
        }

        // Consume resources
        state.energy -= upgradeEnergyCost;

        // Apply upgrade logic (example: boost traits)
        CompanionTraits storage traits = _companionTraits[tokenId];
        traits.vitality++;
        traits.intelligence++;
        traits.strength++;
        traits.agility++;
        // More complex upgrades could involve dynamicData, specific trait boosts, etc.

        emit CompanionUpgraded(tokenId, upgradeEnergyCost);

        // Return any excess ETH
        if (msg.value > upgradeEthCost) {
             payable(_msgSender()).transfer(msg.value - upgradeEthCost);
        }
    }


    // --- Evolution & Oracle Interaction Functions ---

    // Function 23: Request Trait Evolution (Initiates Oracle Call)
    function requestTraitEvolution(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        payable // May require ETH
        onlyCompanionOwner(tokenId)
        notStakedOrOnMission(tokenId) // Cannot evolve while on mission/staked
        noEvolutionRequestPending(tokenId) // Only one request at a time per companion
    {
        CompanionState storage state = _companionStates[tokenId];
         if (state.energy < traitEvolutionEnergyCost) {
            revert InsufficientEnergy();
        }
         if (msg.value < traitEvolutionEthCost) {
            revert InsufficientFunds();
        }

        // Consume resources
        state.energy -= traitEvolutionEnergyCost;
        state.evolutionRequested = true;

        emit TraitEvolutionRequested(tokenId);

        // Return any excess ETH
        if (msg.value > traitEvolutionEthCost) {
             payable(_msgSender()).transfer(msg.value - traitEvolutionEthCost);
        }

        // In a real system, this would trigger an off-chain process
        // watching for the TraitEvolutionRequested event.
        // The off-chain process (the oracle) would compute new traits and call fulfillTraitEvolution.
    }

    // Function 24: Fulfill Trait Evolution (Oracle Callback - Simulated)
    // This function is called by the off-chain oracle process.
    // Signature validation is a simple way to ensure the call is from the authorized oracle.
    // A real system might use Chainlink VRF/External Adapters or more complex verifiable computation.
    function fulfillTraitEvolution(uint256 tokenId, bytes memory newTraitData, bytes memory signature)
        external // Called externally by the oracle
        onlyOracle // Only the designated oracle address can call this
        nonReentrant
        whenNotPaused
        evolutionRequestPending(tokenId) // Only fulfill if a request is pending
    {
        // --- Simplified/Simulated Signature Verification ---
        // In a real system, you'd verify the signature against a message hash
        // involving tokenId, newTraitData, and possibly block.timestamp or a nonce.
        // For this example, we just check if the signature isn't empty as a placeholder.
        // DO NOT use this simplified check in production.
        if (signature.length == 0) { // Placeholder check
             revert InvalidOracleSignature();
        }
        // A real check might look like:
        // bytes32 messageHash = keccak256(abi.encodePacked(tokenId, newTraitData, block.timestamp));
        // require(SignatureChecker.isValidSignature(_oracleAddress, messageHash, signature), "Invalid signature");
        // --- End Simulation ---

        CompanionState storage state = _companionStates[tokenId];
        CompanionTraits storage traits = _companionTraits[tokenId];

        // Apply the new trait data provided by the oracle
        // This example assumes newTraitData is a simple byte array that replaces dynamicData
        // In practice, you might decode it to update specific traits
        traits.dynamicData = newTraitData;
        // Example: Decode newTraitData if it encoded specific trait values
        // (e.g., if newTraitData was abi.encode(newVitality, newIntelligence, ...))
        // (uint8 newVitality, uint8 newIntelligence) = abi.decode(newTraitData, (uint8, uint8));
        // traits.vitality = newVitality;
        // traits.intelligence = newIntelligence;

        state.evolutionRequested = false; // Reset pending request

        emit TraitEvolutionFulfilled(tokenId, newTraitData);
    }

    // --- Admin & Parameter Configuration Functions ---

    // Function 25: Set Oracle Address
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "Zero address");
        _oracleAddress = _oracleAddress;
        emit OracleAddressUpdated(_oracleAddress);
    }

    // Function 26: Set Mission Parameters
    function setMissionParameters(uint256 minDuration, uint256 maxDuration, uint256 baseEnergyReward) public onlyOwner {
        require(minDuration > 0 && maxDuration >= minDuration, "Invalid mission durations");
        missionParams = MissionParameters(minDuration, maxDuration, baseEnergyReward);
    }

    // Function 27: Set Feed Parameters
    function setFeedParameters(uint256 _energyGainPerFeed, uint256 _feedCooldown) public onlyOwner {
        require(_feedCooldown > 0, "Cooldown must be positive");
        energyGainPerFeed = _energyGainPerFeed;
        feedCooldown = _feedCooldown;
    }

    // Function 28: Set Evolution Cost
    function setEvolutionCost(uint256 energyCost, uint256 ethCost) public onlyOwner {
        traitEvolutionEnergyCost = energyCost;
        traitEvolutionEthCost = ethCost;
    }

    // Function 29: Set Upgrade Cost
    function setUpgradeCost(uint256 energyCost, uint256 ethCost) public onlyOwner {
        upgradeEnergyCost = energyCost;
        upgradeEthCost = ethCost;
    }

     // Function 30: Set Base Token URI
    function setBaseTokenURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
        emit BaseTokenURIUpdated(_baseURI);
    }

    // Function 31: Pause Contract
    function pause() public onlyOwner {
        _pause();
    }

    // Function 32: Unpause Contract
    function unpause() public onlyOwner {
        _unpause();
    }

    // Function 33: Withdraw ETH
    function withdrawEth(address payable recipient) public onlyOwner nonReentrant {
        require(recipient != address(0), "Zero address");
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

     // Function 34: Withdraw Token
    function withdrawToken(address tokenAddress, address recipient) public onlyOwner nonReentrant {
        require(tokenAddress != address(0), "Zero token address");
        require(recipient != address(0), "Zero recipient address");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(recipient, balance), "Token withdrawal failed");
    }

    // --- Internal/Helper Functions ---

    // Override ERC721 transfers to add checks for staked/on-mission
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721URIStorage)
        whenNotPaused
        returns (address)
    {
        CompanionState storage state = _companionStates[tokenId];
        if (state.isStaked || state.isOnMission) {
            // Revert if trying to transfer a locked companion, unless owner is transferring to self (e.g., via marketplace logic)
            // Or add specific allowance for marketplace contracts if needed
            // For simplicity, just revert if locked.
            if (auth != address(this)) { // Allow internal contract logic to move (e.g., future features)
                 revert("Companion is locked (staked or on mission)");
            }
        }
        return super._update(to, tokenId, auth);
    }

    // Override _requireOwned to make it viewable
    function _requireOwned(uint256 tokenId) internal view override {
         ERC721._requireOwned(tokenId);
    }

    // --- View Functions (Included in the count for clarity, though some are standard getters) ---

    // Function 35 (Implicit): totalSupply() - Inherited from ERC721Enumerable if used, or can be _tokenIdCounter.current()
    // Added as a separate getter for clarity if not using Enumerable
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Note: Standard ERC721 getters (balanceOf, ownerOf, getApproved, isApprovedForAll) are already counted (3-6).
    // ERC165 supportsInterface (11) is also counted.
    // The total custom/extended functions are well over 20 when combined with standard mandatory ones.
}
```