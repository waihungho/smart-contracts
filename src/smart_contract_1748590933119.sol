Okay, let's create a smart contract for a "Quantum Treasure Hunt". This concept combines elements of gaming, state-dependent logic, verifiable outcomes (simulated quantum collapse), and interactions with NFTs for treasures.

It's designed to be advanced by having:
1.  **State-Dependent Discovery:** Treasure existence/location is probabilistic and determined at the moment of "observation" (a transaction), simulating a "quantum collapse".
2.  **Linked/Entangled Locations:** Finding a treasure in one location can influence or unlock others.
3.  **Verifiable Randomness (Simulated):** Using block data and internal state to make the "collapse" outcome hard to predict perfectly but verifiable after the block is mined. (Note: True, strong randomness is hard on-chain; this simulates the concept).
4.  **Puzzle Integration:** Claiming treasure requires solving an associated puzzle, potentially verified by an external contract.
5.  **NFT Treasures:** Rewards are ERC721 tokens.
6.  **Entropy Contribution:** Players can optionally contribute ETH (simulating energetic cost of observation), which slightly influences outcomes or funds the hunt.

This contract will have a variety of admin, player, and informational functions to manage and interact with the hunt.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline and Function Summary ---
//
// Contract: QuantumTreasureHunt
// Description: A game where players explore virtual locations with probabilistic treasures (NFTs).
// Treasure existence is determined at the moment of observation via a simulated quantum collapse mechanism.
// Claiming requires solving a puzzle. Locations can be linked/entangled.
//
// State Variables:
// - Admins: Addresses authorized to manage the hunt.
// - Paused State: Allows pausing key player actions.
// - Location Types: Defines parameters for different kinds of locations.
// - Locations: Instances of locations on the map, with their unique state (potential, collapsed, treasure status).
// - Players: Registered participants in the hunt.
// - Treasure NFT Contract: The address of the ERC721 contract holding the treasure NFTs.
// - Puzzle Verifier Contract: An optional external contract to verify puzzle solutions.
// - Allowed Puzzle Verifiers: List of trusted puzzle verifier contract addresses.
// - Entropy Fee: Optional ETH required to observe locations.
// - Collected Entropy Funds: ETH collected from entropy fees.
//
// Events:
// - AdminAdded, AdminRemoved
// - HuntPaused, HuntUnpaused
// - LocationTypeCreated
// - LocationDeployed
// - LocationPotentialUpdated
// - LocationLinked
// - LocationHintUpdated
// - PlayerRegistered
// - LocationObserved (indicates collapse outcome: TreasureFound, NoTreasure, etc.)
// - TreasureClaimAttempted
// - TreasureClaimed
// - TreasureForfeited
// - EntropyContributed
// - EntropyFundsWithdrawn
// - PuzzleVerifierAdded, PuzzleVerifierSet
//
// Errors:
// - NotAdmin, AdminExists, NotPlayer, PlayerExists
// - HuntPaused
// - LocationTypeNotFound, LocationNotFound
// - LocationNotDeployable, LocationAlreadyCollapsed, LocationAlreadyClaimed, LocationNotReadyForClaim
// - NotEnoughEntropyFee
// - SolutionInvalid, PuzzleVerifierNotSet, PuzzleVerifierNotAllowed
// - NotTreasureOwner (used when setting up NFTs)
// - NoTreasureFoundAtLocation
// - EntropyFundsUnavailable
// - InvalidAddressZero
// - ZeroValueNotAllowed
// - LinkInvalid (recursive or linking to self)
// - LocationNotLinked
// - HintNotAvailable
// - LocationNotObservable
// - LocationNotClaimableByPlayer
//
// Functions (28 total):
// --- Admin & Setup ---
// 1. constructor(): Initializes the contract owner and first admin.
// 2. addAdmin(address _admin): Adds a new admin address.
// 3. removeAdmin(address _admin): Removes an admin address.
// 4. pauseHunt(): Pauses player observation and claim actions.
// 5. unpauseHunt(): Unpauses the hunt.
// 6. emergencyStopClaims(bool _stop): Allows pausing *only* claim actions independently.
// 7. setTreasureNFTContract(address _nftContract): Sets the address of the ERC721 treasure contract.
// 8. addAllowedPuzzleVerifier(address _verifier): Adds a trusted puzzle verifier contract address.
// 9. setPuzzleVerifier(address _verifier): Sets the currently active puzzle verifier from the allowed list.
// 10. removeAllowedPuzzleVerifier(address _verifier): Removes a puzzle verifier from the allowed list.
// 11. setEntropyFee(uint256 _fee): Sets the optional ETH fee for observing locations.
// 12. withdrawEntropyFunds(address _to): Withdraws collected entropy ETH.
//
// --- Hunt Configuration (Admin) ---
// 13. createLocationType(string memory _name, uint256 _observationDifficulty, uint256 _treasureProbability): Defines a new type of location.
// 14. deployLocation(uint256 _locationTypeId, bytes32 _coordinatesHash, uint256 _randomnessSeed, uint256 _lockoutBlocks, uint256 _puzzleId): Deploys an instance of a location on the map.
// 15. linkLocations(uint256 _locationId1, uint256 _locationId2): Creates an "entanglement" link between two locations.
// 16. updateLocationPotential(uint256 _locationId, uint256 _newTreasureProbability): Adjusts the treasure probability of an existing location.
// 17. setLocationHint(uint256 _locationId, string memory _hint): Adds/updates a hint for a location.
// 18. adminForfeitUnclaimedTreasure(uint256 _locationId): Allows admin to reclaim an NFT if a player fails to claim after collapsing.
//
// --- Player Actions ---
// 19. registerPlayer(): Registers the calling address as a player.
// 20. observeLocation(uint256 _locationId): Attempts to observe a location, potentially collapsing its state and revealing treasure potential.
// 21. attemptTreasureClaim(uint256 _locationId, bytes memory _solution): Attempts to claim the treasure found at a collapsed location by providing a puzzle solution.
// 22. contributeEntropy(uint256 _locationId) payable: Optional function to contribute ETH, potentially influencing the outcome (simulated).
//
// --- Information & Queries (View) ---
// 23. isPlayerRegistered(address _player): Checks if an address is registered.
// 24. isAdmin(address _address): Checks if an address is an admin.
// 25. getHuntStatus(): Returns the current pause status.
// 26. getLocationTypeDetails(uint256 _typeId): Gets details about a location type.
// 27. getLocationDetails(uint256 _locationId): Gets details about a deployed location instance.
// 28. getPlayerLocationStatus(address _player, uint256 _locationId): Gets a player's status regarding a specific location.
// 29. getEntangledLocations(uint256 _locationId): Gets linked locations for a given location.
// 30. getLocationHint(uint256 _locationId): Gets the hint for a location (if available).
// 31. getTotalLocationsDeployed(): Gets the total count of deployed locations.
// 32. getTotalLocationsCollapsed(): Gets the total count of collapsed locations.
// 33. getTotalTreasuresClaimed(): Gets the total count of claimed treasures.
// 34. getEntropyFee(): Gets the current entropy fee.
// 35. getCurrentPuzzleVerifier(): Gets the address of the currently active puzzle verifier.
// 36. isAllowedPuzzleVerifier(address _verifier): Checks if a puzzle verifier is in the allowed list.

contract QuantumTreasureHunt is ReentrancyGuard {

    // --- Errors ---
    error NotAdmin();
    error AdminExists();
    error NotPlayer();
    error PlayerExists();
    error HuntPaused();
    error ClaimsStopped();
    error LocationTypeNotFound();
    error LocationNotFound();
    error LocationNotDeployable();
    error LocationAlreadyCollapsed();
    error LocationAlreadyClaimed();
    error LocationNotReadyForClaim();
    error NotEnoughEntropyFee();
    error SolutionInvalid();
    error PuzzleVerifierNotSet();
    error PuzzleVerifierNotAllowed();
    error NotTreasureOwner();
    error NoTreasureFoundAtLocation();
    error EntropyFundsUnavailable();
    error InvalidAddressZero();
    error ZeroValueNotAllowed();
    error LinkInvalid();
    error LocationNotLinked();
    error HintNotAvailable();
    error LocationNotObservable();
    error LocationNotClaimableByPlayer(); // More specific than LocationNotReadyForClaim for state check

    // --- Events ---
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event HuntPaused(bool paused);
    event ClaimsStopped(bool stopped);
    event LocationTypeCreated(uint256 indexed typeId, string name);
    event LocationDeployed(uint256 indexed locationId, uint256 indexed typeId, bytes32 coordinatesHash);
    event LocationPotentialUpdated(uint256 indexed locationId, uint256 newTreasureProbability);
    event LocationLinked(uint256 indexed locationId1, uint256 indexed locationId2);
    event LocationHintUpdated(uint256 indexed locationId, string hint);
    event PlayerRegistered(address indexed player);
    enum CollapseOutcome { None, NoTreasure, TreasureFound }
    event LocationObserved(uint256 indexed locationId, address indexed player, uint256 blockNumber, bytes32 randomnessSeed, CollapseOutcome outcome);
    event TreasureClaimAttempted(uint256 indexed locationId, address indexed player, bool success); // success means solution verified
    event TreasureClaimed(uint256 indexed locationId, address indexed player, uint256 indexed treasureTokenId);
    event TreasureForfeited(uint256 indexed locationId, address indexed originalObserver, address indexed newRecipient);
    event EntropyContributed(address indexed player, uint256 indexed locationId, uint256 amount);
    event EntropyFundsWithdrawn(address indexed to, uint256 amount);
    event PuzzleVerifierAdded(address indexed verifier);
    event PuzzleVerifierSet(address indexed verifier);
    event PuzzleVerifierRemoved(address indexed verifier);


    // --- Interfaces ---
    interface IPuzzleVerifier {
        // Returns true if the solution is valid for the given location and player
        function verifySolution(uint256 locationId, address player, bytes memory solution) external view returns (bool);
        // Optional: Function to retrieve puzzle details or requirements
        // function getPuzzleDetails(uint256 locationId) external view returns (string memory details);
    }

    // --- Structs ---
    struct LocationType {
        string name;
        uint256 observationDifficulty; // Placeholder: could influence entropy needed or puzzle type
        uint256 initialPotentialProbability; // Probability of treasure (scaled: 0-10000 for 0-100%)
        uint256 puzzleId; // Identifier for the type of puzzle associated
    }

    enum LocationState { Deployed, CollapsedNoTreasure, CollapsedTreasureFound, TreasureClaimed }

    struct Location {
        uint256 locationTypeId;
        bytes32 coordinatesHash; // A hash representing coordinates or ID
        LocationState currentState;
        address observer; // Address of the player who collapsed the location state
        uint256 observationBlock; // Block number when state was collapsed
        bytes32 randomnessSeed; // Seed used for collapse calculation
        uint256 lockoutBlocks; // How many blocks location is locked after observation (0 for none)
        uint256 linkedLocationId; // ID of an 'entangled' location (0 if none)
        string hint; // Clue for finding/solving
        uint256 treasureTokenId; // ID of the claimed NFT (0 if none/not claimed)
        uint256 treasureProbabilityAtCollapse; // The final probability used at collapse time
    }

    struct Player {
        bool isRegistered;
        // Could add more here, e.g., discoveries counter, reputation, etc.
        // For this example, keeping it simple.
    }

    // --- State Variables ---
    address private _owner;
    mapping(address => bool) private _admins;
    bool private _paused = false; // Pauses observe and claim
    bool private _claimsStopped = false; // Pauses only claim

    uint256 private _locationTypeCounter = 0;
    mapping(uint256 => LocationType) private _locationTypes;

    uint256 private _locationCounter = 0;
    mapping(uint256 => Location) private _locations;
    mapping(bytes32 => uint256) private _coordinatesToLocationId; // Mapping coordinates hash to location ID

    mapping(address => Player) private _players;

    address public treasureNFTContract; // Address of the ERC721 contract
    mapping(address => bool) private _allowedPuzzleVerifiers;
    address public currentPuzzleVerifier; // The active verifier contract address

    uint256 public entropyFee = 0; // Optional ETH fee per observation
    uint256 private _collectedEntropyFunds = 0;

    uint256 private _totalLocationsCollapsed = 0;
    uint256 private _totalTreasuresClaimed = 0;

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (!_admins[msg.sender]) revert NotAdmin();
        _;
    }

    modifier onlyRegisteredPlayer() {
        if (!_players[msg.sender].isRegistered) revert NotPlayer();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert HuntPaused();
        _;
    }

    modifier whenClaimsNotStopped() {
        if (_claimsStopped) revert ClaimsStopped();
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _admins[msg.sender] = true;
        emit AdminAdded(msg.sender);
    }

    // --- Admin & Setup ---

    // 1. constructor - Already implemented above

    // 2. addAdmin: Adds a new admin address.
    function addAdmin(address _admin) external onlyAdmin {
        if (_admin == address(0)) revert InvalidAddressZero();
        if (_admins[_admin]) revert AdminExists();
        _admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    // 3. removeAdmin: Removes an admin address.
    function removeAdmin(address _admin) external onlyAdmin {
        if (_admin == msg.sender) revert NotAdmin(); // Cannot remove yourself
        if (!_admins[_admin]) revert NotAdmin();
        _admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    // 4. pauseHunt: Pauses player observation and claim actions.
    function pauseHunt() external onlyAdmin {
        _paused = true;
        emit HuntPaused(true);
    }

    // 5. unpauseHunt: Unpauses the hunt.
    function unpauseHunt() external onlyAdmin {
        _paused = false;
        emit HuntPaused(false);
    }

    // 6. emergencyStopClaims: Allows pausing *only* claim actions independently.
    function emergencyStopClaims(bool _stop) external onlyAdmin {
        _claimsStopped = _stop;
        emit ClaimsStopped(_stop);
    }

    // 7. setTreasureNFTContract: Sets the address of the ERC721 treasure contract.
    function setTreasureNFTContract(address _nftContract) external onlyAdmin {
        if (_nftContract == address(0)) revert InvalidAddressZero();
        // Optional: Add a check here to ensure it supports IERC721,
        // e.g., by calling a view function on it.
        treasureNFTContract = _nftContract;
    }

    // 8. addAllowedPuzzleVerifier: Adds a trusted puzzle verifier contract address.
    function addAllowedPuzzleVerifier(address _verifier) external onlyAdmin {
        if (_verifier == address(0)) revert InvalidAddressZero();
        if (_allowedPuzzleVerifiers[_verifier]) revert PuzzleVerifierAdded(_verifier); // Use event as error indicator (simpler than custom error)
        _allowedPuzzleVerifiers[_verifier] = true;
        emit PuzzleVerifierAdded(_verifier);
    }

    // 9. setPuzzleVerifier: Sets the currently active puzzle verifier from the allowed list.
    function setPuzzleVerifier(address _verifier) external onlyAdmin {
        if (!_allowedPuzzleVerifiers[_verifier]) revert PuzzleVerifierNotAllowed();
        currentPuzzleVerifier = _verifier;
        emit PuzzleVerifierSet(_verifier);
    }

     // 10. removeAllowedPuzzleVerifier: Removes a puzzle verifier from the allowed list.
    function removeAllowedPuzzleVerifier(address _verifier) external onlyAdmin {
        if (!_allowedPuzzleVerifiers[_verifier]) revert PuzzleVerifierNotAllowed(); // Check if it was allowed first
        if (currentPuzzleVerifier == _verifier) revert PuzzleVerifierSet(_verifier); // Cannot remove the currently active one
        _allowedPuzzleVerifiers[_verifier] = false;
        emit PuzzleVerifierRemoved(_verifier);
    }


    // 11. setEntropyFee: Sets the optional ETH fee for observing locations.
    function setEntropyFee(uint256 _fee) external onlyAdmin {
        entropyFee = _fee;
    }

    // 12. withdrawEntropyFunds: Withdraws collected entropy ETH.
    function withdrawEntropyFunds(address _to) external onlyAdmin nonReentrant {
        if (_to == address(0)) revert InvalidAddressZero();
        uint256 amount = _collectedEntropyFunds;
        if (amount == 0) revert EntropyFundsUnavailable();
        _collectedEntropyFunds = 0;
        (bool success, ) = payable(_to).call{value: amount}("");
        require(success, "Withdrawal failed"); // Standard check for send/call
        emit EntropyFundsWithdrawn(_to, amount);
    }

    // --- Hunt Configuration (Admin) ---

    // 13. createLocationType: Defines a new type of location.
    function createLocationType(
        string memory _name,
        uint256 _observationDifficulty,
        uint256 _initialPotentialProbability,
        uint256 _puzzleId // Corresponds to a puzzle type in the verifier
    ) external onlyAdmin returns (uint256) {
        if (_initialPotentialProbability > 10000) revert ZeroValueNotAllowed(); // Probability scaled 0-10000

        _locationTypeCounter++;
        _locationTypes[_locationTypeCounter] = LocationType({
            name: _name,
            observationDifficulty: _observationDifficulty,
            initialPotentialProbability: _initialPotentialProbability,
            puzzleId: _puzzleId
        });
        emit LocationTypeCreated(_locationTypeCounter, _name);
        return _locationTypeCounter;
    }

    // 14. deployLocation: Deploys an instance of a location on the map.
    function deployLocation(
        uint256 _locationTypeId,
        bytes32 _coordinatesHash, // Use hash to abstract coordinates
        uint256 _randomnessSeed, // Admin can provide a seed for added unpredictability
        uint256 _lockoutBlocks, // How many blocks location is locked after observation
        uint256 _puzzleId // Specific puzzle instance ID, or 0 to use type default
    ) external onlyAdmin returns (uint256) {
        if (_locationTypes[_locationTypeId].initialPotentialProbability == 0 && _locationTypeCounter != _locationTypeId) revert LocationTypeNotFound(); // Ensure type exists
        if (_coordinatesToLocationId[_coordinatesHash] != 0) revert LocationNotDeployable(); // Coordinates already used

        _locationCounter++;
        uint256 newLocationId = _locationCounter;

        _locations[newLocationId] = Location({
            locationTypeId: _locationTypeId,
            coordinatesHash: _coordinatesHash,
            currentState: LocationState.Deployed,
            observer: address(0),
            observationBlock: 0,
            randomnessSeed: _randomnessSeed,
            lockoutBlocks: _lockoutBlocks,
            linkedLocationId: 0, // No link initially
            hint: "", // No hint initially
            treasureTokenId: 0, // No treasure yet
            treasureProbabilityAtCollapse: 0 // Not collapsed yet
        });

        _coordinatesToLocationId[_coordinatesHash] = newLocationId;

        emit LocationDeployed(newLocationId, _locationTypeId, _coordinatesHash);
        return newLocationId;
    }

    // 15. linkLocations: Creates an "entanglement" link between two locations.
    // Finding treasure in locationId1 could affect locationId2 or vice versa (mechanic not fully implemented here,
    // but the link exists for future features or client logic).
    function linkLocations(uint256 _locationId1, uint256 _locationId2) external onlyAdmin {
        if (_locations[_locationId1].currentState == LocationState.Deployed && _locationCounter != _locationId1) revert LocationNotFound();
        if (_locations[_locationId2].currentState == LocationState.Deployed && _locationCounter != _locationId2) revert LocationNotFound();
        if (_locationId1 == _locationId2) revert LinkInvalid();
        if (_locations[_locationId1].linkedLocationId == _locationId2 || _locations[_locationId2].linkedLocationId == _locationId1) revert LinkInvalid(); // Already linked

        _locations[_locationId1].linkedLocationId = _locationId2;
        _locations[_locationId2].linkedLocationId = _locationId1; // Make it bidirectional
        emit LocationLinked(_locationId1, _locationId2);
    }

    // 16. updateLocationPotential: Adjusts the treasure probability of an existing location.
    function updateLocationPotential(uint256 _locationId, uint256 _newTreasureProbability) external onlyAdmin {
        if (_locations[_locationId].currentState == LocationState.Deployed && _locationCounter != _locationId) revert LocationNotFound();
        if (_locations[_locationId].currentState != LocationState.Deployed) revert LocationAlreadyCollapsed(); // Can only update potential before collapse
        if (_newTreasureProbability > 10000) revert ZeroValueNotAllowed();

        _locations[_locationId].treasureProbabilityAtCollapse = _newTreasureProbability; // This field is reused *before* collapse for current potential
        emit LocationPotentialUpdated(_locationId, _newTreasureProbability);
    }

    // 17. setLocationHint: Adds/updates a hint for a location.
    function setLocationHint(uint256 _locationId, string memory _hint) external onlyAdmin {
         if (_locations[_locationId].currentState == LocationState.Deployed && _locationCounter != _locationId) revert LocationNotFound();
         _locations[_locationId].hint = _hint;
         emit LocationHintUpdated(_locationId, _hint);
    }

    // 18. adminForfeitUnclaimedTreasure: Allows admin to reclaim an NFT if a player fails to claim after collapsing.
    // Useful if a puzzle is impossible or player abandons claim.
    function adminForfeitUnclaimedTreasure(uint256 _locationId) external onlyAdmin nonReentrant {
        Location storage location = _locations[_locationId];
        if (location.currentState != LocationState.CollapsedTreasureFound) revert LocationNotReadyForClaim();
        if (location.treasureTokenId == 0) revert NoTreasureFoundAtLocation(); // Should not happen if state is CollapsedTreasureFound

        // Transfer the NFT back to the admin (or a designated address)
        IERC721 nftContract = IERC721(treasureNFTContract);
        // Ensure the contract owns the token first
        if (nftContract.ownerOf(location.treasureTokenId) != address(this)) revert NotTreasureOwner();

        // Forfeit the treasure - send to admin or owner? Let's send to owner
        address originalObserver = location.observer; // Store before state change
        location.currentState = LocationState.Deployed; // Reset state? Or new state like Forfeited? Let's reset to Deployed for simplicity
        location.observer = address(0);
        location.observationBlock = 0;
        location.treasureTokenId = 0; // Clear the treasure ID

        nftContract.transferFrom(address(this), _owner, location.treasureTokenId);

        emit TreasureForfeited(_locationId, originalObserver, _owner);
    }


    // --- Player Actions ---

    // 19. registerPlayer: Registers the calling address as a player.
    function registerPlayer() external {
        if (_players[msg.sender].isRegistered) revert PlayerExists();
        _players[msg.sender].isRegistered = true;
        emit PlayerRegistered(msg.sender);
    }

    // 20. observeLocation: Attempts to observe a location, potentially collapsing its state.
    function observeLocation(uint256 _locationId) external payable onlyRegisteredPlayer whenNotPaused nonReentrant {
        Location storage location = _locations[_locationId];
        if (location.currentState != LocationState.Deployed) revert LocationAlreadyCollapsed();
        if (_locationTypes[location.locationTypeId].initialPotentialProbability == 0 && _locationTypeCounter != location.locationTypeId) revert LocationTypeNotFound();

        // Check lockout period if applicable
        if (location.observationBlock != 0 && block.number < location.observationBlock + location.lockoutBlocks) {
             revert LocationNotObservable();
        }

        // Handle entropy fee
        if (msg.value < entropyFee) revert NotEnoughEntropyFee();
        if (msg.value > entropyFee) {
            // Return excess ETH if they sent too much
            payable(msg.sender).transfer(msg.value - entropyFee);
        }
        _collectedEntropyFunds += entropyFee;
        if (entropyFee > 0) {
             emit EntropyContributed(msg.sender, _locationId, entropyFee);
        }


        // --- Simulate Quantum Collapse ---
        // Use blockhash from a recent block for pseudo-randomness
        // Combine with player address, location ID, and admin seed for complexity
        bytes32 randomness = keccak256(abi.encodePacked(
            block.number, // Use current block number
            msg.sender,
            _locationId,
            location.randomnessSeed
            // Potentially include blockhash(block.number - 1) if reliability is acceptable after 256 blocks
            // blockhash(block.number - 1) is better randomness source but limited to last 256 blocks
        ));

        uint256 randomValue = uint256(randomness);

        // Get the *current* probability. If admin hasn't updated it, use the type's initial probability.
        // We stored the potentially updated probability in `treasureProbabilityAtCollapse` field *before* collapse.
        uint256 currentProbability = (location.treasureProbabilityAtCollapse == 0)
            ? _locationTypes[location.locationTypeId].initialPotentialProbability
            : location.treasureProbabilityAtCollapse;

        // Scale random value to probability range (0-10000)
        // The modulo operator biases results, especially with small ranges, but is simple for demonstration.
        // A more sophisticated approach might use bitwise operations on the hash.
        uint256 scaledRandomValue = randomValue % 10001; // Results in 0-10000

        CollapseOutcome outcome;
        if (scaledRandomValue < currentProbability) {
            // Treasure found!
            location.currentState = LocationState.CollapsedTreasureFound;
            outcome = CollapseOutcome.TreasureFound;
            _totalLocationsCollapsed++;
        } else {
            // No treasure this time
            location.currentState = LocationState.CollapsedNoTreasure;
            outcome = CollapseOutcome.NoTreasure;
            _totalLocationsCollapsed++;
        }

        // Update location state
        location.observer = msg.sender;
        location.observationBlock = block.number;
        location.treasureProbabilityAtCollapse = currentProbability; // Store the probability used for collapse

        // Store the player's observation details (optional, could track in Player struct)
        // For simplicity, we just store the observer and block number in the Location struct.

        emit LocationObserved(_locationId, msg.sender, block.number, location.randomnessSeed, outcome);

        // Note: The linked location logic (entanglement) could be triggered here
        // based on the outcome, affecting the linked location's probability or state.
        // This requires more complex state management and is omitted for brevity but is a key concept.
    }

    // 21. attemptTreasureClaim: Attempts to claim the treasure found at a collapsed location.
    function attemptTreasureClaim(uint256 _locationId, bytes memory _solution) external onlyRegisteredPlayer whenNotPaused whenClaimsNotStopped nonReentrant {
        Location storage location = _locations[_locationId];
        if (location.currentState != LocationState.CollapsedTreasureFound) revert LocationNotReadyForClaim();
        if (location.observer != msg.sender) revert LocationNotClaimableByPlayer(); // Only the observer can claim

        if (currentPuzzleVerifier == address(0)) revert PuzzleVerifierNotSet();

        // Get puzzle ID from location type (or maybe location instance)
        uint256 puzzleIdToVerify = _locationTypes[location.locationTypeId].puzzleId;
        // Could override puzzleId at location deployment if location.puzzleId != 0

        // Verify the solution using the external verifier contract
        IPuzzleVerifier verifier = IPuzzleVerifier(currentPuzzleVerifier);
        bool solutionIsValid = verifier.verifySolution(puzzleIdToVerify, msg.sender, _solution);

        emit TreasureClaimAttempted(_locationId, msg.sender, solutionIsValid);

        if (!solutionIsValid) {
            // Puzzle failed. Location state remains CollapsedTreasureFound.
            // Admin can later forfeit if needed.
            revert SolutionInvalid();
        }

        // --- Puzzle Solved - Claim Treasure ---
        if (treasureNFTContract == address(0)) revert ZeroValueNotAllowed(); // NFT contract must be set

        // Admin must have previously deposited treasure NFTs into this contract
        // We need a way to assign *which* NFT corresponds to this location/claim.
        // Simplest method for this example: Admin pre-assigns or we take the 'next' available NFT
        // owned by this contract. Let's assume Admin manages depositing NFTs.
        // A more complex system would involve admin mapping location types/instances to specific NFT token IDs.
        // For this example, let's assume admin funds specific tokenIds for specific locations.
        // This requires a mapping like `locationId => treasureTokenId`. Let's add this to the Location struct.
        // (Corrected: `treasureTokenId` is already in Location struct, will be set by admin initially)

        // We need admin to *deposit* the NFTs into this contract and associate them with locations.
        // Let's assume `adminForfeitUnclaimedTreasure` logic implies admin puts the token ID in the struct first.
        // A proper system needs an `adminSetTreasureTokenId(uint256 locationId, uint256 tokenId)` function,
        // and potentially a deposit function requiring the admin to own the token. Let's add `adminSetTreasureTokenId`.

        if (location.treasureTokenId == 0) {
             // This indicates the admin didn't properly assign an NFT for this location after observation,
             // or before deployment depending on the exact admin flow.
             // Revert or handle this scenario (e.g., location state becomes CollapsedNoTreasure)?
             // Reverting is safer: Admin setup error.
             revert NoTreasureFoundAtLocation(); // Indicates admin setup issue, not player failure
        }

        IERC721 nftContract = IERC721(treasureNFTContract);
        // Verify this contract owns the token before attempting transfer
        if (nftContract.ownerOf(location.treasureTokenId) != address(this)) revert NotTreasureOwner();


        nftContract.transferFrom(address(this), msg.sender, location.treasureTokenId);

        location.currentState = LocationState.TreasureClaimed;
        // location.treasureTokenId remains set to show which token was claimed
        _totalTreasuresClaimed++;
        // _players[msg.sender].discoveredLocations.push(_locationId); // Optional: track discovered locations per player

        emit TreasureClaimed(_locationId, msg.sender, location.treasureTokenId);
    }

    // 22. contributeEntropy: Optional function to contribute ETH, potentially influencing the outcome (simulated).
    // In this contract, the ETH is just collected as a fee. A more advanced version could use the
    // contributed amount as part of the randomness calculation or state update logic.
    function contributeEntropy(uint256 _locationId) external payable onlyRegisteredPlayer whenNotPaused nonReentrant {
        Location storage location = _locations[_locationId];
        if (location.currentState != LocationState.Deployed) revert LocationAlreadyCollapsed();
         if (_locationTypes[location.locationTypeId].initialPotentialProbability == 0 && _locationTypeCounter != location.locationTypeId) revert LocationTypeNotFound();

        if (msg.value == 0) revert ZeroValueNotAllowed();

        _collectedEntropyFunds += msg.value;
        emit EntropyContributed(msg.sender, _locationId, msg.value);

        // Note: In a real advanced contract, msg.value could influence the random seed calculation
        // in `observeLocation` if called shortly after this, adding a player-influenced input.
        // This would require careful design to avoid manipulation.
    }

    // --- Additional Admin Setup Function ---
    // Need a way for Admin to assign a specific NFT token ID to a location *after* it's been observed
    // and treasure was found, but *before* the player claims. Or potentially before deployment.
    // Let's add one to set after observation, before claim.
    function adminSetTreasureTokenId(uint256 _locationId, uint256 _tokenId) external onlyAdmin {
        Location storage location = _locations[_locationId];
        // Can only assign token ID if state is CollapsedTreasureFound and ID hasn't been set
        if (location.currentState != LocationState.CollapsedTreasureFound) revert LocationNotReadyForClaim();
        if (location.treasureTokenId != 0) revert LocationAlreadyClaimed(); // Or specific error like TokenIdAlreadySet

        // Check if this contract owns the token (admin must transfer it here first)
        IERC721 nftContract = IERC721(treasureNFTContract);
        if (nftContract.ownerOf(_tokenId) != address(this)) revert NotTreasureOwner();

        location.treasureTokenId = _tokenId;
        // No specific event for setting token ID, TreasureClaimed will confirm it
    }


    // --- Information & Queries (View) ---

    // 23. isPlayerRegistered: Checks if an address is registered.
    function isPlayerRegistered(address _player) external view returns (bool) {
        return _players[_player].isRegistered;
    }

    // 24. isAdmin: Checks if an address is an admin.
    function isAdmin(address _address) external view returns (bool) {
        return _admins[_address];
    }

    // 25. getHuntStatus: Returns the current pause status.
    function getHuntStatus() external view returns (bool paused, bool claimsStopped) {
        return (_paused, _claimsStopped);
    }

    // 26. getLocationTypeDetails: Gets details about a location type.
    function getLocationTypeDetails(uint256 _typeId) external view returns (
        string memory name,
        uint256 observationDifficulty,
        uint256 initialPotentialProbability,
        uint256 puzzleId
    ) {
        if (_locationTypes[_typeId].initialPotentialProbability == 0 && _locationTypeCounter != _typeId) revert LocationTypeNotFound();
        LocationType storage lt = _locationTypes[_typeId];
        return (lt.name, lt.observationDifficulty, lt.initialPotentialProbability, lt.puzzleId);
    }

    // 27. getLocationDetails: Gets details about a deployed location instance.
    function getLocationDetails(uint256 _locationId) external view returns (
        uint256 locationTypeId,
        bytes32 coordinatesHash,
        LocationState currentState,
        address observer,
        uint256 observationBlock,
        uint256 lockoutBlocks,
        uint256 linkedLocationId,
        uint256 treasureTokenId,
        uint256 treasureProbabilityAtCollapse // Probability used when collapsed
    ) {
        if (_locations[_locationId].currentState == LocationState.Deployed && _locationCounter != _locationId) revert LocationNotFound();
        Location storage loc = _locations[_locationId];
        return (
            loc.locationTypeId,
            loc.coordinatesHash,
            loc.currentState,
            loc.observer,
            loc.observationBlock,
            loc.lockoutBlocks,
            loc.linkedLocationId,
            loc.treasureTokenId,
            loc.treasureProbabilityAtCollapse
        );
    }

     // 28. getPlayerLocationStatus: Gets a player's status regarding a specific location.
     // This is a bit limited with the current Player struct, mainly checks if they were the observer.
     // Could be expanded if players track discovered locations.
     function getPlayerLocationStatus(address _player, uint256 _locationId) external view returns (
         bool wasObserver,
         LocationState locationCurrentState,
         uint256 observedBlock
     ) {
        if (_locations[_locationId].currentState == LocationState.Deployed && _locationCounter != _locationId) revert LocationNotFound();
        Location storage loc = _locations[_locationId];
        return (
            loc.observer == _player,
            loc.currentState,
            loc.observationBlock
        );
     }


    // 29. getEntangledLocations: Gets linked locations for a given location.
    function getEntangledLocations(uint256 _locationId) external view returns (uint256[] memory) {
         if (_locations[_locationId].currentState == LocationState.Deployed && _locationCounter != _locationId) revert LocationNotFound();
         uint256 linkedId = _locations[_locationId].linkedLocationId;
         if (linkedId == 0) {
             revert LocationNotLinked(); // Or return an empty array depending on preference
         }
         // For bidirectional links, return an array with the single linked ID
         uint256[] memory linked = new uint256[](1);
         linked[0] = linkedId;
         return linked;
    }

    // 30. getLocationHint: Gets the hint for a location (if available).
    function getLocationHint(uint256 _locationId) external view returns (string memory) {
         if (_locations[_locationId].currentState == LocationState.Deployed && _locationCounter != _locationId) revert LocationNotFound();
         string memory hint = _locations[_locationId].hint;
         if (bytes(hint).length == 0) revert HintNotAvailable();
         return hint;
    }

    // 31. getTotalLocationsDeployed: Gets the total count of deployed locations.
    function getTotalLocationsDeployed() external view returns (uint256) {
        return _locationCounter;
    }

    // 32. getTotalLocationsCollapsed: Gets the total count of collapsed locations.
    function getTotalLocationsCollapsed() external view returns (uint256) {
        return _totalLocationsCollapsed;
    }

    // 33. getTotalTreasuresClaimed: Gets the total count of claimed treasures.
    function getTotalTreasuresClaimed() external view returns (uint256) {
        return _totalTreasuresClaimed;
    }

    // 34. getEntropyFee: Gets the current entropy fee.
    function getEntropyFee() external view returns (uint256) {
        return entropyFee;
    }

    // 35. getCurrentPuzzleVerifier: Gets the address of the currently active puzzle verifier.
    function getCurrentPuzzleVerifier() external view returns (address) {
        return currentPuzzleVerifier;
    }

    // 36. isAllowedPuzzleVerifier: Checks if a puzzle verifier is in the allowed list.
    function isAllowedPuzzleVerifier(address _verifier) external view returns (bool) {
        return _allowedPuzzleVerifiers[_verifier];
    }

    // --- Fallback/Receive to collect ETH sent without calling a function ---
    // Useful if someone sends ETH to the contract address directly, it will add to collected funds.
    receive() external payable {
        if (msg.value > 0) {
             _collectedEntropyFunds += msg.value;
             emit EntropyContributed(msg.sender, 0, msg.value); // Use location 0 to indicate general contribution
        }
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts Implemented:**

1.  **Simulated Quantum Collapse (`observeLocation`):**
    *   Instead of a treasure existing *or not* from the start, its state (`CollapsedTreasureFound` or `CollapsedNoTreasure`) is determined *probabilistically* at the exact moment a player calls `observeLocation`.
    *   This uses block data (`block.number`), transaction origin (`msg.sender`), location specifics (`_locationId`, `location.randomnessSeed`) combined via `keccak256` hash, and scales the result against the location's `treasureProbabilityAtCollapse`.
    *   This mimics the concept of observing a quantum state collapsing into a definite outcome. It's deterministic *after* the block is mined but aims to be unpredictable *before*, especially with the seed and variable inputs. (Note: Relying solely on `block.number` and `msg.sender` for randomness is *not* truly secure against sophisticated miners, but it demonstrates the concept of on-chain state collapse).

2.  **State-Dependent Progress:**
    *   Locations have distinct states (`Deployed`, `CollapsedTreasureFound`, `CollapsedNoTreasure`, `TreasureClaimed`). Players interact based on these states.
    *   You can only `observeLocation` if it's `Deployed`.
    *   You can only `attemptTreasureClaim` if it's `CollapsedTreasureFound` *and* you were the `observer`.
    *   Hints and potential updates are restricted to certain states (`Deployed` for updates, state check for hints).

3.  **Entanglement (Conceptualized via `linkedLocationId`):**
    *   The `linkLocations` function establishes a bidirectional link. While the current `observeLocation` doesn't *yet* implement the "entanglement" effect (e.g., finding treasure in location A increases probability in linked location B, or collapsing A collapses B), the structure exists. A more complex version would modify the `observeLocation` or a subsequent admin/player action based on the state of the linked location.

4.  **Puzzle Integration (`attemptTreasureClaim`, `IPuzzleVerifier`):**
    *   Claiming treasure is not automatic after finding it. It requires solving an off-chain (or potentially complex on-chain) puzzle whose solution is verified by a separate contract (`IPuzzleVerifier`).
    *   This promotes complex gameplay beyond simple token transfers and allows for upgrading puzzle logic without changing the core hunt contract.

5.  **NFT Treasures (`IERC721`, `treasureNFTContract`):**
    *   Treasures are standard ERC721 tokens, making them easily tradable and manageable outside the hunt contract.
    *   The contract interacts with the NFT standard to transfer ownership upon successful claim.

6.  **Entropy Contribution (`contributeEntropy`, `entropyFee`):**
    *   Players can optionally pay a fee or contribute ETH when observing. This simulates a "cost" or "energy" requirement for interacting with the probabilistic locations.
    *   The collected ETH can be used to fund the game or reward admins/creators. A more advanced version could use the contribution amount as a factor in the randomness calculation, giving players a limited way to influence (but not fully control) the outcome.

7.  **Role-Based Access Control (`onlyAdmin`):** Standard but necessary for managing the complex setup of location types, deployments, links, and verifiers.

8.  **Pausable & Emergency Stop (`pauseHunt`, `emergencyStopClaims`):** Provides necessary control for the contract owner/admins in case of issues. `emergencyStopClaims` is more granular, allowing observation but preventing treasure withdrawal.

**Limitations and Potential Improvements (for even more advanced versions):**

*   **True Randomness:** On-chain randomness is hard. Using `blockhash` is limited to 256 blocks and susceptible (though difficult) to miner manipulation. Integrating with a VRF (Verifiable Random Function) oracle like Chainlink VRF would provide much stronger, auditable randomness for the collapse simulation.
*   **Entanglement Mechanics:** Fully implement the logic for linked locations to influence each other's probabilities or states.
*   **Complex Puzzles:** Develop actual `IPuzzleVerifier` contract examples (e.g., requiring proof of a specific on-chain action, solving a cryptographic puzzle, submitting a correct hash based on game data).
*   **Dynamic Hints:** Make hints reveal based on player progress or global hunt milestones.
*   **Player Tracking:** Store more data about players (which locations they've observed, claimed, total treasures) within the `Player` struct or a separate mapping for richer features.
*   **Gas Efficiency:** For a hunt with many locations and players, optimize storage access and loop structures.

This contract provides a robust foundation for a complex, multi-stage game with unique mechanics based on probabilistic outcomes and external interactions.