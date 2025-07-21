This smart contract, **ChronoSculpt**, introduces a novel concept of dynamic, evolving, and composable NFTs. It reimagines digital assets not as static images, but as living entities that can change, decay, and be "sculpted" by their owners and the passage of time.

It combines elements of ERC-721 (for unique "Sculpts"), ERC-1155 (for "Fragments" that compose Sculpt), and ERC-20 (for a utility token "Catalyst" that fuels interactions).

---

## ChronoSculpt: Dynamic NFT Ecosystem

### Outline

1.  **Core Concepts**
    *   **Sculpts (ERC-721):** Unique, evolving NFTs.
    *   **Fragments (ERC-1155):** Modular components attached to Sculpt, each with properties.
    *   **Essence:** A dynamic, time-decaying property within Fragments, influencing Sculpt state.
    *   **Catalyst (ERC-20):** Utility token for minting, refinement, staking, and governance.
    *   **Evolution/Decay:** Sculpts and Fragments change based on time and interaction.
    *   **Composability:** Fragments can be attached/detached from Sculpts.
    *   **Governance:** Community-driven parameter adjustments.

2.  **Architecture**
    *   Multiple contract interfaces (ERC-721, ERC-1155, ERC-20).
    *   `AccessControl` for roles (Minter, Admin, Curator).
    *   Structs for `SculptDetails`, `FragmentDetails`, `Proposal`.
    *   State variables to manage all assets, their properties, and governance.

3.  **Key Features & Functions (20+ Functions)**

    *   **I. Core Asset Management & Minting**
    *   **II. Fragment & Essence Mechanics**
    *   **III. Sculpt Evolution & State**
    *   **IV. Catalyst (ERC-20) Utility & Economy**
    *   **V. Composability & Modularity**
    *   **VI. Governance & Parameter Control**
    *   **VII. Utility & Querying**
    *   **VIII. Admin & System Functions**

---

### Function Summary

**I. Core Asset Management & Minting**
1.  `mintSculpt(address _to, string memory _tokenURI)`: Mints a new unique Sculpt (ERC-721) to a recipient.
2.  `mintFragmentBatch(uint256[] memory _fragmentTypeIds, uint256[] memory _amounts, bytes memory _data)`: Mints a batch of specific Fragment types (ERC-1155) to the caller.
3.  `bulkMintFragmentsToAddress(address _to, uint256[] memory _fragmentTypeIds, uint256[] memory _amounts)`: Admin/Minter function to mint fragments to a specific address.
4.  `burnSculpt(uint256 _sculptId)`: Allows the owner to burn their Sculpt.
5.  `burnFragment(uint256 _fragmentTypeId, uint256 _amount)`: Allows an owner to burn their Fragments.

**II. Fragment & Essence Mechanics**
6.  `refineFragmentEssence(uint256 _fragmentTypeId, uint256 _sculptId, uint256 _amount)`: Owner refines the "Essence" of a Fragment attached to a Sculpt, consuming Catalyst. Improves or recharges its properties.
7.  `decayFragmentEssence(uint256 _fragmentTypeId, uint256 _sculptId)`: Public function to trigger essence decay for a specific fragment. Can reward the caller for contributing to network upkeep.
8.  `extractEssenceToCatalyst(uint256 _fragmentTypeId, uint256 _sculptId, uint256 _essenceAmount)`: Allows the owner to convert a portion of a Fragment's Essence into Catalyst tokens, effectively "de-refining" it.

**III. Sculpt Evolution & State**
9.  `triggerSculptEvolution(uint256 _sculptId)`: Initiates a Sculpt's evolution based on aggregated Fragment essence, age, and other conditions. Changes its `EvolutionStage` and potentially `SculptState`.
10. `lockSculptEvolution(uint256 _sculptId, uint256 _durationInDays)`: Prevents a Sculpt from decaying or evolving for a set duration, costing Catalyst.
11. `updateSculptMetadataURI(uint256 _sculptId, string memory _newURI)`: Allows the Sculpt owner to update its metadata URI, potentially requiring Catalyst or certain conditions met.

**IV. Catalyst (ERC-20) Utility & Economy**
12. `stakeCatalystForPrivilege(uint256 _amount, uint256 _durationInDays)`: Allows users to stake Catalyst to gain benefits (e.g., reduced essence decay, higher refinement rates, governance weight).
13. `claimCatalystStakingReward()`: Allows stakers to claim their accrued Catalyst rewards.
14. `listFragmentForSale(uint256 _fragmentTypeId, uint256 _amount, uint256 _pricePerUnit)`: Allows a user to list their Fragments for sale directly through the contract, payable in Catalyst.
15. `buyFragmentListed(uint256 _fragmentTypeId, uint256 _amount, address _seller)`: Allows a user to buy listed Fragments from another user, paying in Catalyst.

**V. Composability & Modularity**
16. `assignFragmentToSculpt(uint256 _sculptId, uint256 _fragmentTypeId, uint256 _amount)`: Attaches a specified number of Fragments to a Sculpt, owned by the same user.
17. `detachFragmentFromSculpt(uint256 _sculptId, uint256 _fragmentTypeId, uint256 _amount)`: Detaches Fragments from a Sculpt, returning them to the owner's general Fragment inventory.

**VI. Governance & Parameter Control**
18. `proposeParameterChange(string memory _paramName, uint256 _newValue, string memory _description)`: Allows users with sufficient staked Catalyst to propose changes to contract parameters (e.g., decay rate, minting fees).
19. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows stakers to vote on active proposals.
20. `executeProposal(uint256 _proposalId)`: Anyone can call this to execute a proposal once it passes and its voting period ends.

**VII. Utility & Querying**
21. `getSculptDetails(uint256 _sculptId) view returns (SculptDetails memory)`: Returns all current details of a specific Sculpt.
22. `getFragmentDetails(uint256 _fragmentTypeId) view returns (FragmentDetails memory)`: Returns immutable details of a specific Fragment type.
23. `getSculptFragments(uint256 _sculptId) view returns (uint256[] memory fragmentTypeIds, uint256[] memory amounts)`: Returns all fragments currently attached to a Sculpt.
24. `getPendingCatalystRewards(address _staker) view returns (uint256)`: Returns the amount of Catalyst rewards a staker can claim.

**VIII. Admin & System Functions**
25. `setBaseDecayRate(uint256 _newRate)`: Admin function to set the global essence decay rate.
26. `grantMinterRole(address _account)`: Admin function to grant minter privileges.

---
**Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom errors for better readability and gas efficiency
error InvalidAmount();
error NotSculptOwner();
error NotFragmentOwner();
error FragmentAlreadyAttached();
error FragmentNotAttached();
error InsufficientEssence();
error InvalidSculptState();
error InsufficientCatalyst();
error NotEnoughStakedCatalyst();
error ProposalNotFound();
error ProposalAlreadyVoted();
error ProposalVotingPeriodActive();
error ProposalAlreadyExecuted();
error ProposalFailed();
error Unauthorized();
error InsufficientFragments();

/**
 * @title ChronoSculpt
 * @dev An advanced, dynamic, and composable NFT ecosystem.
 *      It features evolving ERC-721 "Sculpts" made of ERC-1155 "Fragments,"
 *      each with time-decaying "Essence." A utility ERC-20 "Catalyst" token
 *      fuels interactions, refinement, staking, and governance.
 */
contract ChronoSculpt is ERC721Enumerable, ERC1155, ERC20, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Controls global parameters, grants/revokes other roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Allowed to mint new Sculpt and Fragment types

    // --- Counters ---
    Counters.Counter private _sculptIdCounter; // For unique ERC-721 Sculpts
    Counters.Counter private _fragmentTypeIdCounter; // For unique ERC-1155 Fragment types
    Counters.Counter private _proposalIdCounter; // For governance proposals

    // --- Enums ---
    enum SculptState {
        STATIC,      // Initial state, no active decay or evolution
        ACTIVE,      // Actively decaying and evolving
        HIBERNATING, // Temporarily paused decay/evolution (cost Catalyst)
        DECAYED      // Reached a final, decayed state
    }

    enum EvolutionStage {
        NOVICE,      // Newly minted
        APPRENTICE,  // Evolved once
        MASTER,      // Evolved multiple times
        ANCIENT,     // Very old, highly refined, or highly decayed
        RUINED       // Irreparably decayed
    }

    // --- Structs ---

    struct FragmentDetails {
        uint256 fragmentTypeId;     // Unique ID for the fragment type (ERC1155 tokenId)
        string name;                // Name of the fragment type (e.g., "Crystal Shard", "Arcane Core")
        string uri;                 // Metadata URI for the fragment type
        uint256 baseEssenceCapacity;// Max essence this fragment type can hold
        uint256 baseRefinementCost; // Base Catalyst cost to refine 1 unit of essence
    }

    struct SculptDetails {
        address owner;                  // Owner of the Sculpt
        string tokenURI;                // Current metadata URI for the Sculpt (can change)
        SculptState currentState;       // Current state (STATIC, ACTIVE, HIBERNATING, DECAYED)
        EvolutionStage evolutionStage;  // Current evolution stage
        uint256 lastEvolutionTimestamp; // Timestamp of the last evolution or state change
        uint256 lockUntilTimestamp;     // Timestamp until which evolution/decay is locked (0 if not locked)
        mapping(uint256 => uint256) attachedFragments; // fragmentTypeId => amount
        mapping(uint256 => uint256) fragmentEssence;   // fragmentTypeId => current essence for this specific sculpt-fragment pair
        mapping(uint256 => uint256) fragmentLastRefined; // fragmentTypeId => last timestamp of essence refinement
    }

    struct Proposal {
        address proposer;
        string paramName;           // Name of the parameter to change
        uint256 newValue;           // New value for the parameter
        string description;         // Description of the proposal
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Voter address => true if voted
    }

    // --- State Variables ---

    // Sculpt data: sculptId => SculptDetails
    mapping(uint256 => SculptDetails) public sculpts;
    // Fragment type data: fragmentTypeId => FragmentDetails
    mapping(uint256 => FragmentDetails) public fragmentTypes;

    // Catalyst staking: staker address => staked amount
    mapping(address => uint256) public stakedCatalyst;
    // Catalyst staking: staker address => last claim timestamp
    mapping(address => uint256) public lastCatalystClaim;
    // Catalyst staking: staker address => last stake timestamp
    mapping(address => uint256) public lastStakedTime;

    // Fragment listings for internal marketplace: fragmentTypeId => seller => pricePerUnit
    mapping(uint256 => mapping(address => uint256)) public listedFragmentPrices;
    // Fragment listings for internal marketplace: fragmentTypeId => seller => amount
    mapping(uint256 => mapping(address => uint256)) public listedFragmentAmounts;

    // Governance proposals: proposalId => Proposal
    mapping(uint256 => Proposal) public proposals;

    // --- Configurable Parameters (set by Admin or Governance) ---
    uint256 public essenceDecayRatePerDay = 100; // units per day per essence unit (e.g., 100 units = 1%)
    uint256 public minCatalystForRefinement = 1e18; // 1 Catalyst token base cost
    uint256 public essenceToCatalystConversionRate = 1e18; // 1 Essence unit = 1 Catalyst token
    uint256 public catalystStakingAPY = 500; // APY in basis points (e.g., 500 = 5%)
    uint256 public proposalQuorumPercentage = 50; // Percentage of total staked Catalyst needed for quorum
    uint256 public proposalVotingPeriodDays = 7; // Days for a proposal to be active
    uint256 public minCatalystToPropose = 1000e18; // Minimum Catalyst staked to propose

    // --- Events ---
    event SculptMinted(uint256 indexed sculptId, address indexed owner, string tokenURI);
    event FragmentTypeRegistered(uint256 indexed fragmentTypeId, string name, string uri);
    event FragmentsMinted(uint256 indexed fragmentTypeId, address indexed to, uint256 amount);
    event FragmentAttached(uint256 indexed sculptId, uint256 indexed fragmentTypeId, uint256 amount);
    event FragmentDetached(uint256 indexed sculptId, uint256 indexed fragmentTypeId, uint256 amount);
    event EssenceRefined(uint256 indexed sculptId, uint256 indexed fragmentTypeId, uint256 refinedAmount, uint256 catalystSpent);
    event EssenceDecayed(uint256 indexed sculptId, uint256 indexed fragmentTypeId, uint256 decayedAmount);
    event EssenceExtracted(uint256 indexed sculptId, uint256 indexed fragmentTypeId, uint256 extractedAmount, uint256 catalystReceived);
    event SculptEvolved(uint256 indexed sculptId, EvolutionStage newStage, SculptState newState);
    event SculptEvolutionLocked(uint256 indexed sculptId, uint256 lockUntilTimestamp, uint256 catalystSpent);
    event SculptMetadataURIUpdated(uint256 indexed sculptId, string newURI);
    event CatalystStaked(address indexed staker, uint256 amount, uint256 durationInDays);
    event CatalystRewardClaimed(address indexed staker, uint256 amount);
    event FragmentsListedForSale(uint256 indexed fragmentTypeId, address indexed seller, uint256 amount, uint256 pricePerUnit);
    event FragmentsSold(uint256 indexed fragmentTypeId, address indexed buyer, address indexed seller, uint256 amount, uint256 totalPrice);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string paramName, uint256 newValue, uint256 voteEndTime);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event ParameterChanged(string paramName, uint256 oldValue, uint256 newValue);

    // --- Constructor ---
    constructor(
        string memory _sculptName,
        string memory _sculptSymbol,
        string memory _fragmentURI,
        string memory _catalystName,
        string memory _catalystSymbol
    ) ERC721(_sculptName, _sculptSymbol) ERC1155(_fragmentURI) ERC20(_catalystName, _catalystSymbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // The deployer is also an admin
        _grantRole(MINTER_ROLE, msg.sender); // The deployer is also a minter
    }

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, _msgSender())) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyMinter() {
        if (!hasRole(MINTER_ROLE, _msgSender())) {
            revert Unauthorized();
        }
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates the decayed essence for a fragment since its last refinement.
     * @param _fragmentTypeId The ID of the fragment type.
     * @param _sculptId The ID of the sculpt the fragment is attached to.
     * @return The amount of essence that has decayed.
     */
    function _calculateEssenceDecay(uint256 _fragmentTypeId, uint256 _sculptId) internal view returns (uint256) {
        SculptDetails storage sculpt = sculpts[_sculptId];
        if (sculpt.currentState == SculptState.HIBERNATING || sculpt.lockUntilTimestamp > block.timestamp) {
            return 0; // No decay if hibernating or locked
        }

        uint256 lastRefined = sculpt.fragmentLastRefined[_fragmentTypeId];
        if (lastRefined == 0) lastRefined = sculpt.lastEvolutionTimestamp; // If never refined, use sculpt creation/evolution time

        uint256 timeElapsed = block.timestamp.sub(lastRefined);
        uint256 daysElapsed = timeElapsed.div(1 days);

        uint256 currentEssence = sculpt.fragmentEssence[_fragmentTypeId];
        uint256 decayAmount = currentEssence.mul(essenceDecayRatePerDay).mul(daysElapsed).div(10_000); // 10000 for basis points

        return decayAmount;
    }

    /**
     * @dev Internal function to update a sculpt's state based on its aggregated essence.
     *      This is a simplified example; a real-world scenario might have more complex
     *      logic involving all attached fragments, their individual essence, age, etc.
     * @param _sculptId The ID of the sculpt to update.
     */
    function _triggerSculptStateUpdate(uint256 _sculptId) internal {
        SculptDetails storage sculpt = sculpts[_sculptId];
        uint256 totalEssence = 0;
        uint256 totalFragments = 0;

        // Iterate through attached fragments to sum up essence
        // Note: For a very large number of fragments, this loop can be gas-intensive.
        // A more complex system might store an aggregate essence directly on the sculpt.
        for (uint256 i = 0; i < _fragmentTypeIdCounter.current(); i++) { // Iterate through all known fragment types
            if (sculpt.attachedFragments[i] > 0) {
                totalEssence = totalEssence.add(sculpt.fragmentEssence[i]);
                totalFragments = totalFragments.add(sculpt.attachedFragments[i]);
            }
        }

        EvolutionStage oldStage = sculpt.evolutionStage;
        SculptState oldState = sculpt.currentState;

        // Example logic for evolution based on total essence and age
        if (totalFragments == 0 && sculpt.currentState != SculptState.DECAYED) {
            sculpt.currentState = SculptState.DECAYED;
            sculpt.evolutionStage = EvolutionStage.RUINED;
        } else if (totalEssence > (totalFragments.mul(fragmentTypes[0].baseEssenceCapacity).div(2)) && block.timestamp.sub(sculpt.lastEvolutionTimestamp) > 30 days) {
            // If total essence is high and sculpt is old enough, it evolves
            if (sculpt.evolutionStage == EvolutionStage.NOVICE) {
                sculpt.evolutionStage = EvolutionStage.APPRENTICE;
            } else if (sculpt.evolutionStage == EvolutionStage.APPRENTICE) {
                sculpt.evolutionStage = EvolutionStage.MASTER;
            } else if (sculpt.evolutionStage == EvolutionStage.MASTER) {
                sculpt.evolutionStage = EvolutionStage.ANCIENT;
            }
            sculpt.currentState = SculptState.ACTIVE;
        } else if (totalEssence < (totalFragments.mul(fragmentTypes[0].baseEssenceCapacity).div(4)) && sculpt.currentState != SculptState.DECAYED) {
            // If essence is very low, it decays
            if (sculpt.evolutionStage == EvolutionStage.ANCIENT) {
                sculpt.evolutionStage = EvolutionStage.RUINED;
            } else if (sculpt.evolutionStage == EvolutionStage.MASTER) {
                sculpt.evolutionStage = EvolutionStage.APPRENTICE; // Degrade
            }
            sculpt.currentState = SculptState.DECAYED;
        }

        if (oldStage != sculpt.evolutionStage || oldState != sculpt.currentState) {
            sculpt.lastEvolutionTimestamp = block.timestamp;
            emit SculptEvolved(_sculptId, sculpt.evolutionStage, sculpt.currentState);
        }
    }

    /**
     * @dev Internal function to update a fragment's essence, applying decay.
     * @param _fragmentTypeId The ID of the fragment type.
     * @param _sculptId The ID of the sculpt the fragment is attached to.
     */
    function _applyFragmentEssenceDecay(uint256 _fragmentTypeId, uint256 _sculptId) internal {
        SculptDetails storage sculpt = sculpts[_sculptId];
        uint256 decayedAmount = _calculateEssenceDecay(_fragmentTypeId, _sculptId);
        if (decayedAmount > 0) {
            sculpt.fragmentEssence[_fragmentTypeId] = sculpt.fragmentEssence[_fragmentTypeId].sub(decayedAmount);
            if (sculpt.fragmentEssence[_fragmentTypeId] < 0) sculpt.fragmentEssence[_fragmentTypeId] = 0; // Cap at 0
            sculpt.fragmentLastRefined[_fragmentTypeId] = block.timestamp; // Update last refined for next decay calculation
            emit EssenceDecayed(_sculptId, _fragmentTypeId, decayedAmount);
        }
    }

    // --- I. Core Asset Management & Minting ---

    /**
     * @dev Mints a new unique Sculpt (ERC-721) to a recipient.
     *      Only callable by addresses with the MINTER_ROLE.
     * @param _to The recipient address.
     * @param _tokenURI The metadata URI for the new Sculpt.
     */
    function mintSculpt(address _to, string memory _tokenURI) external onlyMinter {
        _sculptIdCounter.increment();
        uint256 newSculptId = _sculptIdCounter.current();
        _safeMint(_to, newSculptId);
        sculpts[newSculptId].owner = _to;
        sculpts[newSculptId].tokenURI = _tokenURI;
        sculpts[newSculptId].currentState = SculptState.STATIC;
        sculpts[newSculptId].evolutionStage = EvolutionStage.NOVICE;
        sculpts[newSculptId].lastEvolutionTimestamp = block.timestamp;

        emit SculptMinted(newSculptId, _to, _tokenURI);
    }

    /**
     * @dev Registers a new Fragment type and mints an initial batch of it.
     *      Only callable by addresses with the MINTER_ROLE.
     * @param _name The name of the new fragment type.
     * @param _uri The metadata URI for the fragment type.
     * @param _baseEssenceCapacity The max essence this type can hold.
     * @param _baseRefinementCost The base Catalyst cost to refine 1 unit.
     * @param _initialSupply Initial amount of this fragment type to mint to caller.
     */
    function registerFragmentTypeAndMint(
        string memory _name,
        string memory _uri,
        uint256 _baseEssenceCapacity,
        uint256 _baseRefinementCost,
        uint256 _initialSupply
    ) external onlyMinter {
        _fragmentTypeIdCounter.increment();
        uint256 newFragmentTypeId = _fragmentTypeIdCounter.current();

        fragmentTypes[newFragmentTypeId] = FragmentDetails(
            newFragmentTypeId,
            _name,
            _uri,
            _baseEssenceCapacity,
            _baseRefinementCost
        );

        _mint(msg.sender, newFragmentTypeId, _initialSupply, ""); // Mint initial supply to the minter
        emit FragmentTypeRegistered(newFragmentTypeId, _name, _uri);
        emit FragmentsMinted(newFragmentTypeId, msg.sender, _initialSupply);
    }

    /**
     * @dev Mints a batch of specific Fragment types (ERC-1155) to the caller.
     *      Only callable by addresses with the MINTER_ROLE.
     * @param _fragmentTypeIds Array of fragment type IDs to mint.
     * @param _amounts Array of amounts corresponding to each fragment type ID.
     * @param _data Additional data (unused, for ERC1155 compatibility).
     */
    function mintFragmentBatch(uint256[] memory _fragmentTypeIds, uint256[] memory _amounts, bytes memory _data) external onlyMinter {
        if (_fragmentTypeIds.length != _amounts.length) revert InvalidAmount();
        _mintBatch(msg.sender, _fragmentTypeIds, _amounts, _data);
        for (uint256 i = 0; i < _fragmentTypeIds.length; i++) {
            emit FragmentsMinted(_fragmentTypeIds[i], msg.sender, _amounts[i]);
        }
    }

    /**
     * @dev Admin/Minter function to mint fragments to a specific address.
     *      Only callable by addresses with the MINTER_ROLE.
     * @param _to The recipient address.
     * @param _fragmentTypeIds Array of fragment type IDs to mint.
     * @param _amounts Array of amounts corresponding to each fragment type ID.
     */
    function bulkMintFragmentsToAddress(address _to, uint256[] memory _fragmentTypeIds, uint256[] memory _amounts) external onlyMinter {
        if (_fragmentTypeIds.length != _amounts.length) revert InvalidAmount();
        _mintBatch(_to, _fragmentTypeIds, _amounts, "");
        for (uint256 i = 0; i < _fragmentTypeIds.length; i++) {
            emit FragmentsMinted(_fragmentTypeIds[i], _to, _amounts[i]);
        }
    }

    /**
     * @dev Allows the owner to burn their Sculpt.
     * @param _sculptId The ID of the Sculpt to burn.
     */
    function burnSculpt(uint256 _sculptId) external {
        if (ownerOf(_sculptId) != msg.sender) revert NotSculptOwner();
        // Detach all fragments first to return them to owner's inventory or burn them
        // For simplicity, this implementation burns them. For more advanced, allow detachment first.
        SculptDetails storage sculpt = sculpts[_sculptId];
        for (uint256 i = 0; i < _fragmentTypeIdCounter.current(); i++) {
            if (sculpt.attachedFragments[i] > 0) {
                // ERC1155 does not have a public _burn function that takes from a specific address other than msg.sender without approval.
                // Assuming fragments are 'consumed' with the sculpt. Or, they must be detached first.
                // For this example, if attached, they are gone with the sculpt.
                // To allow retaining, an explicit detach function must be called beforehand by the user.
                delete sculpt.attachedFragments[i];
                delete sculpt.fragmentEssence[i];
                delete sculpt.fragmentLastRefined[i];
            }
        }
        _burn(_sculptId);
        delete sculpts[_sculptId];
    }

    /**
     * @dev Allows an owner to burn their Fragments.
     * @param _fragmentTypeId The ID of the fragment type to burn.
     * @param _amount The amount of fragments to burn.
     */
    function burnFragment(uint256 _fragmentTypeId, uint256 _amount) external {
        if (balanceOf(msg.sender, _fragmentTypeId) < _amount) revert InsufficientFragments();
        _burn(msg.sender, _fragmentTypeId, _amount);
    }

    // --- II. Fragment & Essence Mechanics ---

    /**
     * @dev Owner refines the "Essence" of a Fragment attached to a Sculpt, consuming Catalyst.
     *      Improves or recharges its properties.
     * @param _fragmentTypeId The ID of the fragment type to refine.
     * @param _sculptId The ID of the sculpt the fragment is attached to.
     * @param _amount The amount of essence units to add.
     */
    function refineFragmentEssence(uint256 _fragmentTypeId, uint256 _sculptId, uint256 _amount) external {
        if (ownerOf(_sculptId) != msg.sender) revert NotSculptOwner();
        if (sculpts[_sculptId].attachedFragments[_fragmentTypeId] == 0) revert FragmentNotAttached();
        if (_amount == 0) revert InvalidAmount();

        _applyFragmentEssenceDecay(_fragmentTypeId, _sculptId); // Apply any pending decay first

        SculptDetails storage sculpt = sculpts[_sculptId];
        FragmentDetails storage fragmentDetail = fragmentTypes[_fragmentTypeId];

        uint256 currentEssence = sculpt.fragmentEssence[_fragmentTypeId];
        uint256 maxEssence = fragmentDetail.baseEssenceCapacity.mul(sculpt.attachedFragments[_fragmentTypeId]);
        uint256 actualRefineAmount = (currentEssence.add(_amount) > maxEssence) ? maxEssence.sub(currentEssence) : _amount;

        if (actualRefineAmount == 0) return; // Already at max capacity or no refinement possible

        uint256 cost = fragmentDetail.baseRefinementCost.mul(actualRefineAmount).div(1e18); // Cost per unit of essence added
        cost = cost.add(minCatalystForRefinement); // Add a minimum transaction cost

        if (balanceOf(msg.sender) < cost) revert InsufficientCatalyst();

        _transfer(_msgSender(), address(this), cost); // Transfer Catalyst to contract treasury

        sculpt.fragmentEssence[_fragmentTypeId] = sculpt.fragmentEssence[_fragmentTypeId].add(actualRefineAmount);
        sculpt.fragmentLastRefined[_fragmentTypeId] = block.timestamp;

        emit EssenceRefined(_sculptId, _fragmentTypeId, actualRefineAmount, cost);
        _triggerSculptStateUpdate(_sculptId);
    }

    /**
     * @dev Public function to trigger essence decay for a specific fragment on a sculpt.
     *      Anyone can call this, and the caller is rewarded with a small amount of Catalyst
     *      for maintaining the network state (a form of "gas refund" or "bounty").
     * @param _fragmentTypeId The ID of the fragment type.
     * @param _sculptId The ID of the sculpt the fragment is attached to.
     */
    function decayFragmentEssence(uint256 _fragmentTypeId, uint256 _sculptId) external {
        SculptDetails storage sculpt = sculpts[_sculptId];
        if (sculpt.attachedFragments[_fragmentTypeId] == 0) revert FragmentNotAttached();

        uint256 decayedAmount = _calculateEssenceDecay(_fragmentTypeId, _sculptId);
        if (decayedAmount == 0) return; // No decay to apply

        sculpt.fragmentEssence[_fragmentTypeId] = sculpt.fragmentEssence[_fragmentTypeId].sub(decayedAmount);
        if (sculpt.fragmentEssence[_fragmentTypeId] < 0) sculpt.fragmentEssence[_fragmentTypeId] = 0; // Cap at 0
        sculpt.fragmentLastRefined[_fragmentTypeId] = block.timestamp; // Update last refined for next decay calculation

        emit EssenceDecayed(_sculptId, _fragmentTypeId, decayedAmount);
        _triggerSculptStateUpdate(_sculptId);

        // Reward the caller for triggering decay (e.g., 1% of decayed essence converted to Catalyst)
        uint256 reward = decayedAmount.mul(essenceToCatalystConversionRate).div(100);
        if (reward > 0) {
            _mint(msg.sender, reward); // Mint new Catalyst to the caller
        }
    }

    /**
     * @dev Allows the owner to convert a portion of a Fragment's Essence into Catalyst tokens.
     *      This effectively "de-refines" the fragment.
     * @param _fragmentTypeId The ID of the fragment type.
     * @param _sculptId The ID of the sculpt the fragment is attached to.
     * @param _essenceAmount The amount of essence units to extract.
     */
    function extractEssenceToCatalyst(uint256 _fragmentTypeId, uint256 _sculptId, uint256 _essenceAmount) external {
        if (ownerOf(_sculptId) != msg.sender) revert NotSculptOwner();
        if (sculpts[_sculptId].attachedFragments[_fragmentTypeId] == 0) revert FragmentNotAttached();
        if (_essenceAmount == 0) revert InvalidAmount();

        _applyFragmentEssenceDecay(_fragmentTypeId, _sculptId); // Apply pending decay first

        SculptDetails storage sculpt = sculpts[_sculptId];
        uint256 currentEssence = sculpt.fragmentEssence[_fragmentTypeId];

        if (currentEssence < _essenceAmount) revert InsufficientEssence();

        sculpt.fragmentEssence[_fragmentTypeId] = currentEssence.sub(_essenceAmount);
        uint256 catalystReceived = _essenceAmount.mul(essenceToCatalystConversionRate).div(1e18); // Convert essence units to Catalyst
        _mint(msg.sender, catalystReceived);

        emit EssenceExtracted(_sculptId, _fragmentTypeId, _essenceAmount, catalystReceived);
        _triggerSculptStateUpdate(_sculptId);
    }

    // --- III. Sculpt Evolution & State ---

    /**
     * @dev Initiates a Sculpt's evolution based on aggregated Fragment essence, age, and other conditions.
     *      Changes its `EvolutionStage` and potentially `SculptState`.
     *      Can be called by anyone, incentivized by potential state changes and metadata updates.
     * @param _sculptId The ID of the Sculpt to evolve.
     */
    function triggerSculptEvolution(uint256 _sculptId) external {
        // Sculpt owner doesn't need to be msg.sender for this. Anyone can trigger state updates.
        // This public function helps ensure the state is updated on-chain.
        // Could add a small Catalyst reward for caller if useful.
        _applyFragmentEssenceDecay(0, _sculptId); // Apply decay to all fragments before evaluation (simplified, iterate real fragments for production)
        _triggerSculptStateUpdate(_sculptId);
    }

    /**
     * @dev Prevents a Sculpt from decaying or evolving for a set duration, costing Catalyst.
     * @param _sculptId The ID of the Sculpt to lock.
     * @param _durationInDays The duration in days to lock the sculpt.
     */
    function lockSculptEvolution(uint256 _sculptId, uint256 _durationInDays) external {
        if (ownerOf(_sculptId) != msg.sender) revert NotSculptOwner();
        if (_durationInDays == 0) revert InvalidAmount();

        uint256 cost = _durationInDays.mul(minCatalystForRefinement); // Example cost calculation
        if (balanceOf(msg.sender) < cost) revert InsufficientCatalyst();

        _transfer(_msgSender(), address(this), cost); // Transfer Catalyst to contract treasury

        SculptDetails storage sculpt = sculpts[_sculptId];
        sculpt.lockUntilTimestamp = block.timestamp.add(_durationInDays.mul(1 days));
        sculpt.currentState = SculptState.HIBERNATING;

        emit SculptEvolutionLocked(_sculptId, sculpt.lockUntilTimestamp, cost);
    }

    /**
     * @dev Allows the Sculpt owner to update its metadata URI.
     *      Might require Catalyst or certain conditions met (e.g., specific evolution stage).
     * @param _sculptId The ID of the Sculpt.
     * @param _newURI The new metadata URI.
     */
    function updateSculptMetadataURI(uint256 _sculptId, string memory _newURI) external {
        if (ownerOf(_sculptId) != msg.sender) revert NotSculptOwner();

        // Example: Only allow updating URI if the sculpt is not in a 'DECAYED' state
        if (sculpts[_sculptId].currentState == SculptState.DECAYED) revert InvalidSculptState();

        // Optionally, require Catalyst to update URI
        uint256 updateCost = 10e18; // 10 Catalyst tokens
        if (balanceOf(msg.sender) < updateCost) revert InsufficientCatalyst();
        _transfer(_msgSender(), address(this), updateCost);

        sculpts[_sculptId].tokenURI = _newURI;
        emit SculptMetadataURIUpdated(_sculptId, _newURI);
    }

    // --- IV. Catalyst (ERC-20) Utility & Economy ---

    /**
     * @dev Allows users to stake Catalyst to gain benefits.
     * @param _amount The amount of Catalyst to stake.
     * @param _durationInDays The duration in days for staking.
     */
    function stakeCatalystForPrivilege(uint256 _amount, uint256 _durationInDays) external {
        if (_amount == 0 || _durationInDays == 0) revert InvalidAmount();
        if (balanceOf(msg.sender) < _amount) revert InsufficientCatalyst();

        // Ensure transfer is approved beforehand by the user
        _transfer(_msgSender(), address(this), _amount);

        stakedCatalyst[msg.sender] = stakedCatalyst[msg.sender].add(_amount);
        lastCatalystClaim[msg.sender] = block.timestamp; // Reset claim time on new stake
        lastStakedTime[msg.sender] = block.timestamp; // Track when staking started for rewards

        emit CatalystStaked(msg.sender, _amount, _durationInDays);
    }

    /**
     * @dev Allows stakers to claim their accrued Catalyst rewards.
     */
    function claimCatalystStakingReward() external {
        uint256 pendingRewards = getPendingCatalystRewards(msg.sender);
        if (pendingRewards == 0) return;

        _mint(msg.sender, pendingRewards);
        lastCatalystClaim[msg.sender] = block.timestamp;

        emit CatalystRewardClaimed(msg.sender, pendingRewards);
    }

    /**
     * @dev Allows a user to list their Fragments for sale directly through the contract, payable in Catalyst.
     * @param _fragmentTypeId The ID of the fragment type to list.
     * @param _amount The amount of fragments to list.
     * @param _pricePerUnit The price per single fragment in Catalyst.
     */
    function listFragmentForSale(uint256 _fragmentTypeId, uint256 _amount, uint256 _pricePerUnit) external {
        if (_amount == 0 || _pricePerUnit == 0) revert InvalidAmount();
        if (balanceOf(msg.sender, _fragmentTypeId) < _amount) revert InsufficientFragments();

        // Transfer fragments from seller to contract's custody
        _safeTransferFrom(msg.sender, address(this), _fragmentTypeId, _amount, "");

        listedFragmentPrices[_fragmentTypeId][msg.sender] = _pricePerUnit;
        listedFragmentAmounts[_fragmentTypeId][msg.sender] = listedFragmentAmounts[_fragmentTypeId][msg.sender].add(_amount);

        emit FragmentsListedForSale(_fragmentTypeId, msg.sender, _amount, _pricePerUnit);
    }

    /**
     * @dev Allows a user to buy listed Fragments from another user, paying in Catalyst.
     * @param _fragmentTypeId The ID of the fragment type to buy.
     * @param _amount The amount of fragments to buy.
     * @param _seller The address of the seller.
     */
    function buyFragmentListed(uint256 _fragmentTypeId, uint256 _amount, address _seller) external {
        if (_amount == 0) revert InvalidAmount();
        if (listedFragmentAmounts[_fragmentTypeId][_seller] < _amount) revert InsufficientFragments();

        uint256 pricePerUnit = listedFragmentPrices[_fragmentTypeId][_seller];
        uint256 totalPrice = pricePerUnit.mul(_amount);

        if (balanceOf(msg.sender) < totalPrice) revert InsufficientCatalyst();

        // Transfer Catalyst from buyer to seller
        _transfer(_msgSender(), _seller, totalPrice);

        // Transfer fragments from contract's custody to buyer
        _safeTransferFrom(address(this), msg.sender, _fragmentTypeId, _amount, "");
        listedFragmentAmounts[_fragmentTypeId][_seller] = listedFragmentAmounts[_fragmentTypeId][_seller].sub(_amount);

        // If seller's remaining listed amount is 0, reset their price
        if (listedFragmentAmounts[_fragmentTypeId][_seller] == 0) {
            delete listedFragmentPrices[_fragmentTypeId][_seller];
        }

        emit FragmentsSold(_fragmentTypeId, msg.sender, _seller, _amount, totalPrice);
    }

    // --- V. Composability & Modularity ---

    /**
     * @dev Attaches a specified number of Fragments to a Sculpt, owned by the same user.
     *      Fragments are transferred from the owner's inventory to the Sculpt's "internal inventory".
     * @param _sculptId The ID of the Sculpt to attach fragments to.
     * @param _fragmentTypeId The ID of the fragment type to attach.
     * @param _amount The amount of fragments to attach.
     */
    function assignFragmentToSculpt(uint256 _sculptId, uint256 _fragmentTypeId, uint256 _amount) external {
        if (ownerOf(_sculptId) != msg.sender) revert NotSculptOwner();
        if (balanceOf(msg.sender, _fragmentTypeId) < _amount) revert InsufficientFragments();
        if (_amount == 0) revert InvalidAmount();

        _safeTransferFrom(msg.sender, address(this), _fragmentTypeId, _amount, ""); // Transfer to contract custody

        SculptDetails storage sculpt = sculpts[_sculptId];
        sculpt.attachedFragments[_fragmentTypeId] = sculpt.attachedFragments[_fragmentTypeId].add(_amount);
        sculpt.fragmentLastRefined[_fragmentTypeId] = block.timestamp; // Initialize or reset refinement time

        emit FragmentAttached(_sculptId, _fragmentTypeId, _amount);
        _triggerSculptStateUpdate(_sculptId);
    }

    /**
     * @dev Detaches Fragments from a Sculpt, returning them to the owner's general Fragment inventory.
     * @param _sculptId The ID of the Sculpt to detach fragments from.
     * @param _fragmentTypeId The ID of the fragment type to detach.
     * @param _amount The amount of fragments to detach.
     */
    function detachFragmentFromSculpt(uint256 _sculptId, uint256 _fragmentTypeId, uint256 _amount) external {
        if (ownerOf(_sculptId) != msg.sender) revert NotSculptOwner();
        if (_amount == 0) revert InvalidAmount();

        SculptDetails storage sculpt = sculpts[_sculptId];
        if (sculpt.attachedFragments[_fragmentTypeId] < _amount) revert InsufficientFragments();

        _safeTransferFrom(address(this), msg.sender, _fragmentTypeId, _amount, ""); // Transfer from contract custody back to owner

        sculpt.attachedFragments[_fragmentTypeId] = sculpt.attachedFragments[_fragmentTypeId].sub(_amount);
        if (sculpt.attachedFragments[_fragmentTypeId] == 0) {
            delete sculpt.fragmentEssence[_fragmentTypeId];
            delete sculpt.fragmentLastRefined[_fragmentTypeId];
        }

        emit FragmentDetached(_sculptId, _fragmentTypeId, _amount);
        _triggerSculptStateUpdate(_sculptId);
    }

    // --- VI. Governance & Parameter Control ---

    /**
     * @dev Allows users with sufficient staked Catalyst to propose changes to contract parameters.
     * @param _paramName The name of the parameter to change (e.g., "essenceDecayRatePerDay").
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposal.
     */
    function proposeParameterChange(string memory _paramName, uint256 _newValue, string memory _description) external {
        if (stakedCatalyst[msg.sender] < minCatalystToPropose) revert NotEnoughStakedCatalyst();

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(proposalVotingPeriodDays.mul(1 days)),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        emit ProposalCreated(proposalId, msg.sender, _paramName, _newValue, proposals[proposalId].voteEndTime);
    }

    /**
     * @dev Allows stakers to vote on active proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (block.timestamp < proposal.voteStartTime || block.timestamp > proposal.voteEndTime) revert ProposalVotingPeriodActive();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();
        if (stakedCatalyst[msg.sender] == 0) revert NotEnoughStakedCatalyst();

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(stakedCatalyst[msg.sender]);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(stakedCatalyst[msg.sender]);
        }

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Anyone can call this to execute a proposal once it passes and its voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (block.timestamp < proposal.voteEndTime) revert ProposalVotingPeriodActive();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        uint256 totalStaked = totalStakedCatalyst(); // Get current total staked
        uint256 quorumThreshold = totalStaked.mul(proposalQuorumPercentage).div(100);

        if (proposal.votesFor.add(proposal.votesAgainst) < quorumThreshold) {
            proposal.passed = false; // Failed to meet quorum
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, false);
            revert ProposalFailed();
        }

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;
            // Execute parameter change
            if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("essenceDecayRatePerDay"))) {
                uint256 oldValue = essenceDecayRatePerDay;
                essenceDecayRatePerDay = proposal.newValue;
                emit ParameterChanged("essenceDecayRatePerDay", oldValue, essenceDecayRatePerDay);
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("minCatalystForRefinement"))) {
                uint256 oldValue = minCatalystForRefinement;
                minCatalystForRefinement = proposal.newValue;
                emit ParameterChanged("minCatalystForRefinement", oldValue, minCatalystForRefinement);
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("essenceToCatalystConversionRate"))) {
                uint256 oldValue = essenceToCatalystConversionRate;
                essenceToCatalystConversionRate = proposal.newValue;
                emit ParameterChanged("essenceToCatalystConversionRate", oldValue, essenceToCatalystConversionRate);
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("catalystStakingAPY"))) {
                uint256 oldValue = catalystStakingAPY;
                catalystStakingAPY = proposal.newValue;
                emit ParameterChanged("catalystStakingAPY", oldValue, catalystStakingAPY);
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("proposalQuorumPercentage"))) {
                uint256 oldValue = proposalQuorumPercentage;
                proposalQuorumPercentage = proposal.newValue;
                emit ParameterChanged("proposalQuorumPercentage", oldValue, proposalQuorumPercentage);
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("proposalVotingPeriodDays"))) {
                uint256 oldValue = proposalVotingPeriodDays;
                proposalVotingPeriodDays = proposal.newValue;
                emit ParameterChanged("proposalVotingPeriodDays", oldValue, proposalVotingPeriodDays);
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("minCatalystToPropose"))) {
                uint256 oldValue = minCatalystToPropose;
                minCatalystToPropose = proposal.newValue;
                emit ParameterChanged("minCatalystToPropose", oldValue, minCatalystToPropose);
            }
            // Add more parameters as needed
        } else {
            proposal.passed = false; // Did not pass
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    // --- VII. Utility & Querying ---

    /**
     * @dev Returns all current details of a specific Sculpt.
     * @param _sculptId The ID of the Sculpt.
     */
    function getSculptDetails(uint256 _sculptId) external view returns (SculptDetails memory) {
        // Need to return a copy of the struct, not reference storage directly if it contains mappings.
        // For simplicity, this returns the struct. If `attachedFragments` or `fragmentEssence` were not internal,
        // a custom getter for them would be needed.
        return sculpts[_sculptId];
    }

    /**
     * @dev Returns immutable details of a specific Fragment type.
     * @param _fragmentTypeId The ID of the fragment type.
     */
    function getFragmentDetails(uint256 _fragmentTypeId) external view returns (FragmentDetails memory) {
        return fragmentTypes[_fragmentTypeId];
    }

    /**
     * @dev Returns all fragments currently attached to a Sculpt and their amounts.
     * @param _sculptId The ID of the Sculpt.
     * @return fragmentTypeIds Array of attached fragment type IDs.
     * @return amounts Array of amounts for each attached fragment type.
     */
    function getSculptFragments(uint256 _sculptId) external view returns (uint256[] memory fragmentTypeIds, uint256[] memory amounts) {
        uint256 count = 0;
        for (uint256 i = 0; i < _fragmentTypeIdCounter.current(); i++) {
            if (sculpts[_sculptId].attachedFragments[i] > 0) {
                count++;
            }
        }

        fragmentTypeIds = new uint256[](count);
        amounts = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < _fragmentTypeIdCounter.current(); i++) {
            if (sculpts[_sculptId].attachedFragments[i] > 0) {
                fragmentTypeIds[index] = i;
                amounts[index] = sculpts[_sculptId].attachedFragments[i];
                index++;
            }
        }
        return (fragmentTypeIds, amounts);
    }

    /**
     * @dev Returns the current essence level for a specific fragment on a sculpt.
     * @param _sculptId The ID of the sculpt.
     * @param _fragmentTypeId The ID of the fragment type.
     * @return The current essence level.
     */
    function getFragmentCurrentEssence(uint256 _sculptId, uint256 _fragmentTypeId) external view returns (uint256) {
        // Apply decay virtually for the view function without altering state
        SculptDetails storage sculpt = sculpts[_sculptId];
        uint256 currentEssence = sculpt.fragmentEssence[_fragmentTypeId];
        uint256 decayedAmount = _calculateEssenceDecay(_fragmentTypeId, _sculptId);
        return currentEssence.sub(decayedAmount); // Return calculated current essence
    }


    /**
     * @dev Returns the amount of Catalyst rewards a staker can claim.
     * @param _staker The address of the staker.
     * @return The pending Catalyst rewards.
     */
    function getPendingCatalystRewards(address _staker) public view returns (uint256) {
        uint256 stakedAmt = stakedCatalyst[_staker];
        if (stakedAmt == 0) return 0;

        uint256 timeStaked = block.timestamp.sub(lastCatalystClaim[_staker]);
        uint256 secondsInYear = 365 days; // Approximation for simplicity

        // APY calculation: stakedAmt * (APY / 10000) * (timeStaked / secondsInYear)
        uint256 rewards = stakedAmt.mul(catalystStakingAPY).div(10_000).mul(timeStaked).div(secondsInYear);
        return rewards;
    }

    /**
     * @dev Returns the total amount of Catalyst currently staked in the contract.
     */
    function totalStakedCatalyst() public view returns (uint256) {
        return balanceOf(address(this)); // Assuming all Catalyst held by this contract is staked Catalyst
                                          // In a more complex scenario, explicit accounting for staked vs. treasury is needed
    }

    /**
     * @dev Returns details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return The Proposal struct.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    // --- VIII. Admin & System Functions ---

    /**
     * @dev Admin function to set the global essence decay rate.
     * @param _newRate The new decay rate per day (in basis points, e.g., 100 for 1%).
     */
    function setBaseDecayRate(uint256 _newRate) external onlyAdmin {
        uint256 oldValue = essenceDecayRatePerDay;
        essenceDecayRatePerDay = _newRate;
        emit ParameterChanged("essenceDecayRatePerDay", oldValue, _newRate);
    }

    /**
     * @dev Admin function to grant the MINTER_ROLE to an account.
     * @param _account The address to grant the role to.
     */
    function grantMinterRole(address _account) external onlyAdmin {
        _grantRole(MINTER_ROLE, _account);
    }

    /**
     * @dev Admin function to revoke the MINTER_ROLE from an account.
     * @param _account The address to revoke the role from.
     */
    function revokeMinterRole(address _account) external onlyAdmin {
        _revokeRole(MINTER_ROLE, _account);
    }

    /**
     * @dev Required for ERC1155 to receive NFTs.
     * @param operator The address which initiated the call (could be zero).
     * @param from The address which previously owned the token.
     * @param id The ID of the token being transferred.
     * @param value The amount of tokens being transferred.
     * @param data Additional data with no specified format.
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if successful.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Required for ERC1155 to receive batch NFTs.
     * @param operator The address which initiated the call (could be zero).
     * @param from The address which previously owned the token.
     * @param ids An array of IDs of the tokens being transferred.
     * @param values An array of amounts of tokens being transferred.
     * @param data Additional data with no specified format.
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if successful.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // --- Overrides for ERC721 and ERC1155 Metadata URIs ---
    function _baseURI() internal pure override(ERC721) returns (string memory) {
        return "ipfs://CHRONOSCULPT_SCULPT_BASE_URI/";
    }

    function uri(uint256 _fragmentTypeId) public view override(ERC1155) returns (string memory) {
        FragmentDetails storage fragment = fragmentTypes[_fragmentTypeId];
        require(bytes(fragment.uri).length > 0, "Fragment type does not exist");
        return fragment.uri;
    }

    // --- Override for ERC721Enumerable ---
    // ERC721Enumerable needs `_beforeTokenTransfer` and `_afterTokenTransfer` hooks if you customize transfer logic.
    // Basic implementation relies on OpenZeppelin's internal _transfer, _safeMint, _burn.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```