Okay, let's create a smart contract based on the concept of "Symbiotic Digital Organisms" (SDOs). This concept combines elements of dynamic NFTs, simulated biological processes (evolution, decay, reproduction), resource management (feeding), and a simple form of on-chain environmental governance affecting the organisms.

It avoids directly copying standard ERC-20/721 logic by implementing its own ownership and transfer mechanisms tailored to the SDO lifecycle, and the core logic around traits, genes, and environmental interaction is unique.

---

**Outline & Function Summary: Symbiotic Digital Organisms (SDO) Contract**

This contract manages a collection of dynamic digital assets called Symbiotic Digital Organisms (SDOs). Each SDO is a unique token with immutable 'Genes' and mutable 'Traits'. Their traits change over time, through owner interaction ('feeding', 'stimulating'), and based on global 'Environmental Factors' that can be influenced by SDO owners via a simple governance mechanism.

**I. Core SDO Management (NFT-like)**
*   `mintSDO`: Creates a new genesis SDO.
*   `getSDO`: Retrieves the full data structure for a specific SDO.
*   `ownerOf`: Returns the current owner of an SDO (ERC-721 standard function).
*   `transferFrom`: Transfers ownership of an SDO (ERC-721 standard function).
*   `approve`: Grants approval for another address to transfer a specific SDO (ERC-721 standard function).
*   `setApprovalForAll`: Grants or revokes approval for an operator to manage all of the caller's SDOs (ERC-721 standard function).
*   `balanceOf`: Returns the number of SDOs owned by an address (ERC-721 standard function).
*   `tokenURI`: Returns a URI for fetching metadata for a specific SDO. This metadata should be dynamic, reflecting the SDO's current state.

**II. SDO Lifecycle & Interaction**
*   `feedSDO`: Allows feeding an SDO with a specified ERC-20 token, increasing its vitality and potentially triggering state changes.
*   `stimulateSDO`: A different type of interaction that provides a minor vitality boost or temporary trait modification.
*   `decaySDO`: Simulates decay; reduces vitality based on time since last interaction. Called internally or externally by anyone to update state.
*   `checkEvolutionReadiness`: Pure function to check if an SDO meets the criteria for evolution based on its traits and environmental factors.
*   `evolveSDO`: Triggers evolution if `checkEvolutionReadiness` is true. Changes SDO traits significantly based on genes and environment.
*   `reproduceSDO`: Creates a new SDO child from one or two parent SDOs, mixing genes and consuming parent vitality/maturity. Requires specific reproduction conditions.
*   `checkReproductionReadiness`: Pure function to check if an SDO (or pair) meets the criteria for reproduction.

**III. SDO State & Query**
*   `getSDOStateDescription`: Returns a human-readable string summarizing the SDO's current state (e.g., "Larva, Healthy, Needs Feeding").
*   `queryTraitValue`: Retrieves the value of a specific, named trait for an SDO.
*   `queryGeneValue`: Retrieves the value of a specific, named gene for an SDO.
*   `getEnvironmentalFactors`: Returns the current global environmental parameters.

**IV. Environmental Governance (Simplified)**
*   `proposeEnvironmentalChange`: Allows SDO owners to propose changes to global environmental factors by staking tokens.
*   `voteOnEnvironmentalChange`: Allows SDO owners to vote on active proposals (weighted by number of owned SDOs or staked tokens).
*   `executeEnvironmentalChange`: Executes a proposal if it has passed the voting threshold and cooldown.
*   `cancelEnvironmentalProposal`: Allows the proposer to cancel an active proposal.

**V. Contract Administration & Configuration**
*   `setBaseTokenURI`: Sets the base URL for SDO metadata.
*   `setEvolutionParams`: Owner-only function to configure evolution thresholds and effects.
*   `setReproductionParams`: Owner-only function to configure reproduction requirements and gene mixing rules.
*   `setEnvironmentalVoteParams`: Owner-only function to configure governance parameters (thresholds, voting period).
*   `withdrawFees`: Owner-only function to withdraw accumulated feeding tokens or reproduction fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Added for reentrancy protection on transfers/withdrawals

// Basic interface for potential future cross-SDO interaction
interface ISDO {
    struct Gene {
        uint64 geneType;        // e.g., 1=Strength, 2=Resilience, 3=Speed, 4=ColorSeed
        uint64 geneStrength;    // 1-100, immutable influence
    }

    struct Trait {
        uint64 vitality;        // Health/Energy, decreases over time, increases with feeding/stimulation
        uint64 maturityLevel;   // Represents growth stage
        uint64 stateFlags;      // Bitmask for various states (e.g., 1=Hibernating, 2=Diseased, 4=Fertile)
        uint256 lastInteractionTime; // Timestamp of last feed/stimulate
        uint256 lastDecayTime;     // Timestamp of last decay calculation
        // Add more dynamic traits here
        uint64 environmentalAdaptation; // Trait influenced by env factors
    }

    struct SDOData {
        uint256 tokenId;
        address owner;
        Gene[] genes;
        Trait traits;
        uint256 birthTime;
        uint256 parent1Id; // 0 for genesis
        uint256 parent2Id; // 0 for asexual, parent1Id for sexual with self, >0 for sexual with another
    }

    // Environmental Factors influencing all SDOs
    struct EnvironmentalFactors {
        uint64 baseDecayRatePerDay; // How fast vitality decays
        uint64 evolutionMaturityThreshold; // Min maturity needed for evolution
        uint64 evolutionVitalityThreshold; // Min vitality needed for evolution
        uint64 reproductionMaturityThreshold; // Min maturity for reproduction
        uint64 reproductionVitalityCost; // Vitality consumed by reproduction
        uint256 feedingVitalityBoost; // How much vitality feeding adds
        uint256 stimulationVitalityBoost; // How much vitality stimulation adds
        uint256 minFeedingAmount; // Minimum ERC20 required to feed
        // Add more factors influencing SDO traits/lifecycle
        uint64 environmentalAdaptationRate; // How fast SDOs adapt to environment
    }

    // Governance Proposal for Environmental Changes
    struct EnvironmentalProposal {
        uint256 proposalId;
        address proposer;
        bytes data; // Encoded data representing the proposed EnvironmentalFactors change
        uint256 voteStartTime;
        uint224 voteEndTime;
        uint224 executionTime; // Time after which proposal can be executed if passed
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool cancelled;
    }
}


contract SymbioticDigitalOrganisms is Ownable, ReentrancyGuard, ISDO {

    using Strings for uint256;

    // --- State Variables ---

    // SDO Data
    uint256 private _nextTokenId;
    mapping(uint256 => SDOData) private _sdoData;
    mapping(address => uint256[]) private _ownerSdos; // Simple list per owner, needs care on transfers
    mapping(uint256 => address) private _tokenApprovals; // ERC-721 approval
    mapping(address => mapping(address => bool)) private _operatorApprovals; // ERC-721 operator approval

    // Environmental Factors (Current Global State)
    EnvironmentalFactors public currentEnvironmentalFactors;

    // Governance
    uint256 private _nextProposalId;
    mapping(uint256 => EnvironmentalProposal) public environmentalProposals;
    mapping(uint256 => mapping(address => bool)) private _proposalVotes; // proposalId => voter => hasVoted
    uint256 public environmentalVotingPeriod = 7 days;
    uint256 public environmentalExecutionDelay = 1 days; // Time after voting ends before execution is possible
    uint256 public environmentalQuorumThreshold = 1; // Minimum votes needed (e.g., based on # of SDOs owned) - Simplified
    uint256 public environmentalMajorityThreshold = 51; // Percentage (51 for 51%)

    // Configuration & Fees
    IERC20 public immutable feedingToken;
    address payable public feeRecipient; // Address to receive tokens from feeding/reproduction
    uint256 public reproductionFee = 0; // ERC20 cost to reproduce
    string private _baseTokenURI;

    // --- Events ---

    event SDOTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event SDOApproved(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event SDOFed(uint256 indexed tokenId, address indexed feeder, uint256 amount);
    event SDOStimulated(uint256 indexed tokenId, address indexed stimulator);
    event SDODecayed(uint256 indexed tokenId, uint64 oldVitality, uint64 newVitality);
    event SDOEvolutionChecked(uint256 indexed tokenId, bool isReady);
    event SDOEvolutionOccurred(uint256 indexed tokenId, uint64 newMaturityLevel);
    event SDOReproductionChecked(uint256 indexed parent1Id, uint256 indexed parent2Id, bool isReady);
    event SDOReproductionOccurred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);

    event EnvironmentalFactorsUpdated(EnvironmentalFactors newFactors);
    event EnvironmentalProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes data);
    event EnvironmentalVoteCast(uint256 indexed proposalId, address indexed voter, bool vote); // true for yes, false for no
    event EnvironmentalProposalExecuted(uint256 indexed proposalId);
    event EnvironmentalProposalCancelled(uint256 indexed proposalId);

    // --- Constructor ---

    constructor(address _feedingTokenAddress, address payable _feeRecipient)
        Ownable(msg.sender)
        ReentrancyGuard() // Initialize ReentrancyGuard
    {
        require(_feedingTokenAddress != address(0), "Invalid feeding token address");
        require(_feeRecipient != address(0), "Invalid fee recipient address");

        feedingToken = IERC20(_feedingTokenAddress);
        feeRecipient = _feeRecipient;

        _nextTokenId = 1; // Start token IDs from 1
        _nextProposalId = 1;

        // Set initial environmental factors (can be tuned later)
        currentEnvironmentalFactors = EnvironmentalFactors({
            baseDecayRatePerDay: 10, // Vitality points lost per day
            evolutionMaturityThreshold: 50,
            evolutionVitalityThreshold: 80,
            reproductionMaturityThreshold: 70,
            reproductionVitalityCost: 30,
            feedingVitalityBoost: 25,
            stimulationVitalityBoost: 5,
            minFeedingAmount: 1e18, // 1 token (assuming 18 decimals)
            environmentalAdaptationRate: 5 // How much env factors influence traits
        });

        _baseTokenURI = "ipfs://QmTBDynamicSDOMetadata/"; // Placeholder, needs off-chain service
    }

    // --- Internal Helpers (ERC-721 style) ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _sdoData[tokenId].owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }

    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "TransferFrom: caller is not owner nor approved");
        require(to != address(0), "TransferTo: invalid recipient");

        // ERC721 logic: clear approvals, update owner, etc.
        _tokenApprovals[tokenId] = address(0); // Clear approval for this token

        // Update owner in SDOData struct
        _sdoData[tokenId].owner = to;

        // Simple list updates (INEFFICIENT for large numbers of tokens/transfers, better implementations use linked lists or omit this)
        // For demonstration, we'll keep a basic list but acknowledge its limitations.
        // Finding and removing from _ownerSdos[from]
        uint256 len = _ownerSdos[from].length;
        for (uint i = 0; i < len; i++) {
            if (_ownerSdos[from][i] == tokenId) {
                // Swap with last element and pop
                _ownerSdos[from][i] = _ownerSdos[from][len - 1];
                _ownerSdos[from].pop();
                break;
            }
        }
        // Add to _ownerSdos[to]
        _ownerSdos[to].push(tokenId);


        emit SDOTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
         address sdoOwner = ownerOf(tokenId);
         require(sdoOwner != address(0), "Burn: SDO does not exist");

         _tokenApprovals[tokenId] = address(0); // Clear approvals

         // Remove from owner's list (same inefficient method as _safeTransfer)
         uint256 len = _ownerSdos[sdoOwner].length;
         for (uint i = 0; i < len; i++) {
            if (_ownerSdos[sdoOwner][i] == tokenId) {
                _ownerSdos[sdoOwner][i] = _ownerSdos[sdoOwner][len - 1];
                _ownerSdos[sdoOwner].pop();
                break;
            }
        }

         // Delete SDO data
         delete _sdoData[tokenId];

         // No specific ERC721 burn event, but Transfer(owner, address(0), tokenId) is conventional
         emit SDOTransfer(sdoOwner, address(0), tokenId);
    }


    // --- Core SDO Management (NFT-like) ---

    /// @notice Mints a new genesis SDO. Only callable by the owner.
    /// @param initialOwner The address to receive the new SDO.
    /// @return The ID of the newly minted SDO.
    function mintSDO(address initialOwner) public onlyOwner returns (uint256) {
        require(initialOwner != address(0), "Mint: invalid recipient");

        uint256 tokenId = _nextTokenId++;

        // Generate initial genes (simplified: random-ish based on block/timestamp/tokenid)
        // In a real system, this would use verifiable randomness (Chainlink VRF)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, _nextTokenId)));

        Gene[] memory initialGenes = new Gene[](4); // e.g., 4 genes per SDO
        initialGenes[0] = Gene({geneType: 1, geneStrength: uint64((seed % 100) + 1)}); // Strength
        seed = uint256(keccak256(abi.encodePacked(seed, tokenId)));
        initialGenes[1] = Gene({geneType: 2, geneStrength: uint64((seed % 100) + 1)}); // Resilience
        seed = uint256(keccak256(abi.encodePacked(seed, tokenId)));
        initialGenes[2] = Gene({geneType: 3, geneStrength: uint64((seed % 100) + 1)}); // Speed
        seed = uint256(keccak256(abi.encodePacked(seed, tokenId)));
        initialGenes[3] = Gene({geneType: 4, geneStrength: uint64((seed % 256))});    // ColorSeed (0-255)

        // Set initial traits
        Trait memory initialTraits = Trait({
            vitality: 100, // Start with full vitality
            maturityLevel: 0, // Start as 'Larva'
            stateFlags: 0,
            lastInteractionTime: block.timestamp,
            lastDecayTime: block.timestamp,
            environmentalAdaptation: 0
        });

        _sdoData[tokenId] = SDOData({
            tokenId: tokenId,
            owner: initialOwner,
            genes: initialGenes,
            traits: initialTraits,
            birthTime: block.timestamp,
            parent1Id: 0, // Genesis
            parent2Id: 0
        });

        _ownerSdos[initialOwner].push(tokenId);

        emit SDOTransfer(address(0), initialOwner, tokenId); // ERC-721 mint event convention

        return tokenId;
    }

    /// @notice Gets the full data structure for a specific SDO.
    /// @param tokenId The ID of the SDO to retrieve.
    /// @return The SDOData struct.
    function getSDO(uint256 tokenId) public view returns (SDOData memory) {
        require(_exists(tokenId), "SDO does not exist");
        return _sdoData[tokenId];
    }

    /// @notice Returns the number of SDOs owned by `owner`.
    /// @dev ERC-721 standard function. Note: this requires iterating through a potentially long array, can be gas-intensive.
    /// @param owner Address for whom to query the balance.
    /// @return The number of SDOs owned by `owner`.
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "BalanceOf: zero address is not a valid owner");
        // Return the length of the owner's token list.
        return _ownerSdos[owner].length;
    }

    /// @notice Returns the owner of the `tokenId`.
    /// @dev ERC-721 standard function.
    /// @param tokenId The identifier for an SDO.
    /// @return The address of the owner.
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _sdoData[tokenId].owner;
        require(owner != address(0), "OwnerOf: SDO does not exist");
        return owner;
    }

    /// @notice Transfers ownership of an SDO.
    /// @dev ERC-721 standard function. Requires caller to be owner or approved.
    /// @param from The current owner of the SDO.
    /// @param to The new owner.
    /// @param tokenId The SDO to transfer.
    function transferFrom(address from, address to, uint256 tokenId) public payable nonReentrant {
        // Use _isApprovedOrOwner check
        require(_isApprovedOrOwner(msg.sender, tokenId), "TransferFrom: caller is not owner nor approved");
        require(from == ownerOf(tokenId), "TransferFrom: from address is not the owner");
        require(to != address(0), "TransferFrom: invalid recipient");

        _safeTransfer(from, to, tokenId);
    }

    /// @notice Grants approval for a single SDO.
    /// @dev ERC-721 standard function.
    /// @param approved The address to be approved.
    /// @param tokenId The SDO ID to approve.
    function approve(address approved, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "Approve: caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = approved;
        emit SDOApproved(tokenOwner, approved, tokenId);
    }

    /// @notice Sets approval for an operator to manage all of msg.sender's SDOs.
    /// @dev ERC-721 standard function.
    /// @param operator The address to approve.
    /// @param approved Whether to approve or revoke approval.
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ApproveForAll: operator cannot be the caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Gets the approved address for a single SDO.
    /// @dev ERC-721 standard function.
    /// @param tokenId The SDO ID.
    /// @return The approved address.
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "GetApproved: SDO does not exist");
        return _tokenApprovals[tokenId];
    }

    /// @notice Checks if an operator is approved for all of an owner's SDOs.
    /// @dev ERC-721 standard function.
    /// @param owner The owner of the SDOs.
    /// @param operator The address to check.
    /// @return True if the operator is approved for all SDOs owned by `owner`.
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Returns a URI for fetching metadata for an SDO.
    /// @dev This is the standard way to link off-chain metadata. The actual metadata service
    ///      needs to exist off-chain and return JSON based on the URI, reflecting the
    ///      SDO's current traits and state.
    /// @param tokenId The SDO ID.
    /// @return The metadata URI.
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "TokenURI: SDO does not exist");
        // Simple implementation: base URI + token ID.
        // A real dynamic system would point to a service that reads contract state.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }


    // --- SDO Lifecycle & Interaction ---

    /// @notice Feeds an SDO, increasing its vitality. Requires sending `feedingToken`.
    /// @param tokenId The ID of the SDO to feed.
    /// @param amount The amount of feedingToken to use (must be >= minFeedingAmount).
    function feedSDO(uint256 tokenId, uint256 amount) public nonReentrant {
        SDOData storage sdo = _sdoData[tokenId];
        require(_exists(tokenId), "FeedSDO: SDO does not exist");
        require(msg.sender == sdo.owner, "FeedSDO: caller is not owner");
        require(amount >= currentEnvironmentalFactors.minFeedingAmount, "FeedSDO: insufficient feeding amount");
        require(sdo.traits.vitality < type(uint64).max, "FeedSDO: vitality is already max");

        // Transfer tokens to the contract first
        require(feedingToken.transferFrom(msg.sender, address(this), amount), "FeedSDO: token transfer failed");

        // Decay vitality based on time since last interaction *before* feeding
        _decaySDOInternal(tokenId); // Update vitality based on decay

        // Increase vitality (cap at max uint64)
        uint256 potentialVitality = uint256(sdo.traits.vitality) + currentEnvironmentalFactors.feedingVitalityBoost;
        sdo.traits.vitality = uint64(potentialVitality > type(uint64).max ? type(uint64).max : potentialVitality);

        sdo.traits.lastInteractionTime = block.timestamp;
        sdo.traits.lastDecayTime = block.timestamp; // Reset decay timer

        emit SDOFed(tokenId, msg.sender, amount);
    }

    /// @notice Stimulates an SDO, providing a small vitality boost or other temporary effect.
    /// @param tokenId The ID of the SDO to stimulate.
    function stimulateSDO(uint256 tokenId) public nonReentrant {
        SDOData storage sdo = _sdoData[tokenId];
        require(_exists(tokenId), "StimulateSDO: SDO does not exist");
        require(msg.sender == sdo.owner, "StimulateSDO: caller is not owner");
        require(sdo.traits.vitality < type(uint64).max, "StimulateSDO: vitality is already max");

        // Decay vitality first
        _decaySDOInternal(tokenId);

        // Increase vitality (cap at max uint64)
        uint256 potentialVitality = uint256(sdo.traits.vitality) + currentEnvironmentalFactors.stimulationVitalityBoost;
        sdo.traits.vitality = uint64(potentialVitality > type(uint64).max ? type(uint64).max : potentialVitality);

        // Could add temporary stateFlags here
        // sdo.traits.stateFlags |= 0x8000; // Example: set a 'stimulated' flag

        sdo.traits.lastInteractionTime = block.timestamp;
        sdo.traits.lastDecayTime = block.timestamp; // Reset decay timer

        emit SDOStimulated(tokenId, msg.sender);
    }


    /// @notice Internal function to calculate and apply vitality decay. Can be called externally by anyone
    ///         to trigger decay for an SDO, making decay calculation gas-efficient for owners.
    /// @param tokenId The ID of the SDO to decay.
    function decaySDO(uint256 tokenId) public {
        _decaySDOInternal(tokenId);
    }

    /// @dev Internal helper for decay logic.
    function _decaySDOInternal(uint256 tokenId) internal {
         SDOData storage sdo = _sdoData[tokenId];
         // No owner check needed here, anyone can trigger decay to update public state

         uint256 lastDecayTime = sdo.traits.lastDecayTime;
         if (lastDecayTime >= block.timestamp) {
             // Decay already calculated for this block, or time hasn't passed
             return;
         }

         uint256 timeElapsedInDays = (block.timestamp - lastDecayTime) / 1 days;
         if (timeElapsedInDays == 0) {
             return; // Less than a day has passed since last decay
         }

         uint64 vitalityLost = uint64(timeElapsedInDays * currentEnvironmentalFactors.baseDecayRatePerDay);
         uint64 oldVitality = sdo.traits.vitality;

         if (vitalityLost > sdo.traits.vitality) {
             sdo.traits.vitality = 0; // Cannot go below 0
         } else {
             sdo.traits.vitality -= vitalityLost;
         }

         sdo.traits.lastDecayTime = block.timestamp;

         if (oldVitality != sdo.traits.vitality) {
            emit SDODecayed(tokenId, oldVitality, sdo.traits.vitality);
         }
    }


    /// @notice Checks if an SDO is ready to evolve based on its traits and environment.
    /// @param tokenId The ID of the SDO to check.
    /// @return True if the SDO can evolve, false otherwise.
    function checkEvolutionReadiness(uint256 tokenId) public view returns (bool) {
        SDOData memory sdo = _sdoData[tokenId];
        require(_exists(tokenId), "CheckEvolutionReadiness: SDO does not exist");

        // Decay isn't calculated in view function, so result is based on last decay time
        // In a UI, you'd call decaySDO first, then checkEvolutionReadiness

        bool ready = sdo.traits.maturityLevel < 100 && // Cannot evolve past max maturity
                     sdo.traits.maturityLevel >= currentEnvironmentalFactors.evolutionMaturityThreshold &&
                     sdo.traits.vitality >= currentEnvironmentalFactors.evolutionVitalityThreshold;

        return ready;
    }

    /// @notice Triggers the evolution process for an SDO if it is ready.
    /// @param tokenId The ID of the SDO to evolve.
    function evolveSDO(uint256 tokenId) public {
        SDOData storage sdo = _sdoData[tokenId];
        require(_exists(tokenId), "EvolveSDO: SDO does not exist");
        require(msg.sender == sdo.owner, "EvolveSDO: caller is not owner");

        // Decay vitality first
        _decaySDOInternal(tokenId);

        require(checkEvolutionReadiness(tokenId), "EvolveSDO: SDO not ready to evolve");

        uint64 oldMaturity = sdo.traits.maturityLevel;

        // Simulate evolution: increase maturity, potentially alter traits slightly based on genes/environment
        sdo.traits.maturityLevel += (currentEnvironmentalFactors.environmentalAdaptationRate / 2) + (sdo.genes[0].geneStrength / 20); // Example formula
        if (sdo.traits.maturityLevel > 100) sdo.traits.maturityLevel = 100; // Cap maturity

        // Apply environmental adaptation effect (example: boosts vitality slightly or affects a state flag)
        sdo.traits.vitality += currentEnvironmentalFactors.environmentalAdaptationRate;
        if (sdo.traits.vitality > type(uint64).max) sdo.traits.vitality = type(uint64).max;


        sdo.traits.lastInteractionTime = block.timestamp;
        sdo.traits.lastDecayTime = block.timestamp;

        emit SDOEvolutionOccurred(tokenId, sdo.traits.maturityLevel);
    }

    /// @notice Checks if an SDO (or pair) is ready to reproduce.
    /// @param parent1Id The ID of the potential parent SDO.
    /// @param parent2Id Optional: The ID of a second potential parent (0 for asexual).
    /// @return True if reproduction is possible, false otherwise.
    function checkReproductionReadiness(uint256 parent1Id, uint256 parent2Id) public view returns (bool) {
        SDOData memory parent1 = _sdoData[parent1Id];
        require(_exists(parent1Id), "CheckReproductionReadiness: Parent1 does not exist");

        // Decay isn't calculated in view function

        bool parent1Ready = parent1.traits.maturityLevel >= currentEnvironmentalFactors.reproductionMaturityThreshold &&
                            parent1.traits.vitality >= currentEnvironmentalFactors.reproductionVitalityCost;

        if (parent2Id != 0) {
             // Sexual reproduction requires a second parent
            SDOData memory parent2 = _sdoData[parent2Id];
            require(_exists(parent2Id), "CheckReproductionReadiness: Parent2 does not exist");
            require(parent1.owner == parent2.owner, "CheckReproductionReadiness: Parents must have same owner");

            bool parent2Ready = parent2.traits.maturityLevel >= currentEnvironmentalFactors.reproductionMaturityThreshold &&
                                parent2.traits.vitality >= currentEnvironmentalFactors.reproductionVitalityCost;
            return parent1Ready && parent2Ready;
        } else {
            // Asexual reproduction
            return parent1Ready;
        }
    }

    /// @notice Triggers reproduction if ready, creating a new child SDO.
    /// @param parent1Id The ID of the parent SDO.
    /// @param parent2Id Optional: The ID of a second parent (0 for asexual).
    function reproduceSDO(uint256 parent1Id, uint256 parent2Id) public payable nonReentrant {
        SDOData storage parent1 = _sdoData[parent1Id];
        require(_exists(parent1Id), "Reproduction: Parent1 does not exist");
        require(msg.sender == parent1.owner, "Reproduction: caller is not parent1 owner");

        // Decay vitality first for parent(s)
        _decaySDOInternal(parent1Id);
         if (parent2Id != 0) {
             _decaySDOInternal(parent2Id);
         }

        require(checkReproductionReadiness(parent1Id, parent2Id), "Reproduction: Parent(s) not ready");
        require(feedingToken.transferFrom(msg.sender, feeRecipient, reproductionFee), "Reproduction: Fee transfer failed");

        SDOData storage parent2; // Declare storage reference for parent2 if needed

        if (parent2Id != 0) {
             parent2 = _sdoData[parent2Id];
             // checkReproductionReadiness already validated same owner and existence
        }

        // Consume vitality from parent(s)
        parent1.traits.vitality -= currentEnvironmentalFactors.reproductionVitalityCost;
        if (parent2Id != 0) {
            parent2.traits.vitality -= currentEnvironmentalFactors.reproductionVitalityCost;
        }

        // --- Generate Child SDO ---
        uint256 childTokenId = _nextTokenId++;

        // Gene mixing (simplified example)
        Gene[] memory childGenes = new Gene[](parent1.genes.length);
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, childTokenId, parent1Id, parent2Id)));

        for(uint i = 0; i < parent1.genes.length; i++) {
            // Simple mixing: 50/50 chance to inherit from parent1 or parent2 (if exists), plus slight mutation
            uint64 inheritedStrength;
            if (parent2Id != 0) {
                 // Sexual reproduction: inherit from parent1 or parent2
                if (seed % 2 == 0) {
                    inheritedStrength = parent1.genes[i].geneStrength;
                } else {
                    inheritedStrength = parent2.genes[i].geneStrength;
                }
                seed = uint256(keccak256(abi.encodePacked(seed, childTokenId, i))); // Reseed
            } else {
                // Asexual reproduction: inherit from parent1
                 inheritedStrength = parent1.genes[i].geneStrength;
            }

            // Apply slight mutation (e.g., +/- 1-3)
            uint64 mutation = uint64(seed % 7) - 3; // Gives values from -3 to +3
            int64 mutatedStrength = int64(inheritedStrength) + int64(mutation);

            // Clamp strength between 1 and 100
            if (mutatedStrength < 1) mutatedStrength = 1;
            if (mutatedStrength > 100) mutatedStrength = 100;

            childGenes[i] = Gene({
                geneType: parent1.genes[i].geneType, // Assume same gene types
                geneStrength: uint64(mutatedStrength)
            });
             seed = uint256(keccak256(abi.encodePacked(seed, i))); // Reseed
        }

         // Set initial traits for child
        Trait memory childTraits = Trait({
            vitality: 100, // Child starts healthy
            maturityLevel: 0, // Start as 'Larva'
            stateFlags: 0,
            lastInteractionTime: block.timestamp,
            lastDecayTime: block.timestamp,
            environmentalAdaptation: 0 // Child inherits base adaptation
        });


        _sdoData[childTokenId] = SDOData({
            tokenId: childTokenId,
            owner: msg.sender, // Child goes to the reproducer's owner
            genes: childGenes,
            traits: childTraits,
            birthTime: block.timestamp,
            parent1Id: parent1Id,
            parent2Id: parent2Id
        });

        _ownerSdos[msg.sender].push(childTokenId); // Add child to owner's list

        parent1.traits.lastInteractionTime = block.timestamp; // Reset interaction time for parent(s)
        parent1.traits.lastDecayTime = block.timestamp;
        if (parent2Id != 0) {
            parent2.traits.lastInteractionTime = block.timestamp;
            parent2.traits.lastDecayTime = block.timestamp;
        }


        emit SDOReproductionOccurred(parent1Id, parent2Id, childTokenId);
        emit SDOTransfer(address(0), msg.sender, childTokenId); // Mint event for child
    }


    // --- SDO State & Query ---

    /// @notice Gets a human-readable description of the SDO's current state.
    /// @dev This is a simplified example. More complex states would require more logic.
    /// @param tokenId The SDO ID.
    /// @return A string describing the state.
    function getSDOStateDescription(uint256 tokenId) public view returns (string memory) {
        SDOData memory sdo = _sdoData[tokenId];
        require(_exists(tokenId), "GetSDOStateDescription: SDO does not exist");

        // Note: Vitality might be slightly stale if decaySDO hasn't been called recently

        string memory vitalityState;
        if (sdo.traits.vitality == 0) {
            vitalityState = "Decayed";
        } else if (sdo.traits.vitality < 30) {
            vitalityState = "Low Vitality";
        } else if (sdo.traits.vitality < 70) {
             vitalityState = "Healthy";
        } else {
             vitalityState = "Vigorous";
        }

        string memory maturityState;
        if (sdo.traits.maturityLevel == 0) {
            maturityState = "Larva";
        } else if (sdo.traits.maturityLevel < currentEnvironmentalFactors.evolutionMaturityThreshold) {
             maturityState = "Juvenile";
        } else if (sdo.traits.maturityLevel < 100) {
            maturityState = "Adult (Evolvable)";
        } else {
             maturityState = "Mature";
        }

        string memory stateDesc = string(abi.encodePacked(maturityState, ", ", vitalityState));

        // Add state flags if any
        if (sdo.traits.stateFlags & 1 > 0) {
             stateDesc = string(abi.encodePacked(stateDesc, ", Hibernating"));
        }
        if (sdo.traits.stateFlags & 2 > 0) {
             stateDesc = string(abi.encodePacked(stateDesc, ", Diseased"));
        }
         if (sdo.traits.stateFlags & 4 > 0) {
             stateDesc = string(abi.encodePacked(stateDesc, ", Fertile")); // Ready for reproduction
        }


        return stateDesc;
    }

    /// @notice Queries the value of a specific named trait for an SDO.
    /// @dev This function is simplified; in practice, traits might be complex or stored differently.
    ///      Mapping trait names to struct fields requires care or an enum.
    /// @param tokenId The SDO ID.
    /// @param traitName The name of the trait (e.g., "vitality", "maturity"). Case-sensitive.
    /// @return The value of the trait as uint64. Returns 0 if trait not found or invalid name.
    function queryTraitValue(uint256 tokenId, string memory traitName) public view returns (uint64) {
        SDOData memory sdo = _sdoData[tokenId];
        require(_exists(tokenId), "QueryTraitValue: SDO does not exist");

        if (keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked("vitality"))) {
            // Note: Vitality might be stale
            return sdo.traits.vitality;
        } else if (keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked("maturityLevel"))) {
            return sdo.traits.maturityLevel;
        } else if (keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked("environmentalAdaptation"))) {
             return sdo.traits.environmentalAdaptation;
        }
        // Add more traits here
        return 0; // Trait not found
    }

     /// @notice Queries the value of a specific gene type for an SDO.
    /// @param tokenId The SDO ID.
    /// @param geneType The type of gene (e.g., 1=Strength, 2=Resilience).
    /// @return The strength of the specified gene type. Returns 0 if gene type not found.
    function queryGeneValue(uint256 tokenId, uint64 geneType) public view returns (uint64) {
        SDOData memory sdo = _sdoData[tokenId];
        require(_exists(tokenId), "QueryGeneValue: SDO does not exist");

        for(uint i = 0; i < sdo.genes.length; i++) {
            if (sdo.genes[i].geneType == geneType) {
                return sdo.genes[i].geneStrength;
            }
        }
        return 0; // Gene type not found
    }


    /// @notice Returns the current global environmental parameters.
    /// @return The EnvironmentalFactors struct.
    function getEnvironmentalFactors() public view returns (EnvironmentalFactors memory) {
        return currentEnvironmentalFactors;
    }


    // --- Environmental Governance (Simplified) ---

    /// @notice Allows SDO owners to propose a change to global environmental factors.
    /// @dev Requires msg.sender to own at least one SDO. The proposed change is encoded in `data`.
    ///      A more robust system would use a structured proposal type instead of raw bytes.
    /// @param proposedFactors The proposed EnvironmentalFactors struct.
    function proposeEnvironmentalChange(EnvironmentalFactors calldata proposedFactors) public {
         require(balanceOf(msg.sender) > 0, "ProposeEnvChange: Must own at least one SDO");

         uint256 proposalId = _nextProposalId++;
         environmentalProposals[proposalId] = EnvironmentalProposal({
             proposalId: proposalId,
             proposer: msg.sender,
             data: abi.encode(proposedFactors), // Encode the full struct
             voteStartTime: block.timestamp,
             voteEndTime: block.timestamp + environmentalVotingPeriod,
             executionTime: block.timestamp + environmentalVotingPeriod + environmentalExecutionDelay,
             yesVotes: 0,
             noVotes: 0,
             executed: false,
             cancelled: false
         });

         emit EnvironmentalProposalCreated(proposalId, msg.sender, environmentalProposals[proposalId].data);
    }

    /// @notice Allows SDO owners to vote on an active environmental proposal.
    /// @dev Voting weight is simplified to 1 vote per SDO owned.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param vote True for Yes, False for No.
    function voteOnEnvironmentalChange(uint256 proposalId, bool vote) public {
         EnvironmentalProposal storage proposal = environmentalProposals[proposalId];
         require(proposal.voteStartTime > 0 && !proposal.executed && !proposal.cancelled, "VoteEnvChange: Proposal not active");
         require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "VoteEnvChange: Voting is not open");
         require(balanceOf(msg.sender) > 0, "VoteEnvChange: Must own at least one SDO to vote");
         require(!_proposalVotes[proposalId][msg.sender], "VoteEnvChange: Already voted");

         // Simple voting weight: 1 SDO = 1 Vote
         uint256 weight = balanceOf(msg.sender);

         if (vote) {
             proposal.yesVotes += weight;
         } else {
             proposal.noVotes += weight;
         }

         _proposalVotes[proposalId][msg.sender] = true;

         emit EnvironmentalVoteCast(proposalId, msg.sender, vote);
    }

    /// @notice Executes a passed environmental proposal. Callable by anyone after the execution delay.
    /// @param proposalId The ID of the proposal to execute.
    function executeEnvironmentalChange(uint256 proposalId) public {
         EnvironmentalProposal storage proposal = environmentalProposals[proposalId];
         require(proposal.voteStartTime > 0 && !proposal.executed && !proposal.cancelled, "ExecuteEnvChange: Proposal not active or already processed");
         require(block.timestamp > proposal.voteEndTime, "ExecuteEnvChange: Voting not ended yet");
         require(block.timestamp >= proposal.executionTime, "ExecuteEnvChange: Execution delay not passed");

         // Check if proposal passed (simplified: majority and quorum based on total votes)
         uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
         // Using owner's SDO count as a proxy for quorum; a real system would need total SDO count or staked weight
         require(totalVotes >= environmentalQuorumThreshold, "ExecuteEnvChange: Quorum not met");

         uint256 yesPercentage = (proposal.yesVotes * 100) / totalVotes; // Be careful with division by zero, handled by quorum check
         require(yesPercentage >= environmentalMajorityThreshold, "ExecuteEnvChange: Majority not met");

         // Decode and apply the proposed changes
         EnvironmentalFactors memory newFactors = abi.decode(proposal.data, (EnvironmentalFactors));
         currentEnvironmentalFactors = newFactors;

         proposal.executed = true;

         emit EnvironmentalFactorsUpdated(newFactors);
         emit EnvironmentalProposalExecuted(proposalId);
    }

     /// @notice Allows the proposer to cancel their own environmental proposal before voting ends.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelEnvironmentalProposal(uint256 proposalId) public {
        EnvironmentalProposal storage proposal = environmentalProposals[proposalId];
        require(proposal.proposer == msg.sender, "CancelEnvProposal: Caller is not the proposer");
        require(proposal.voteStartTime > 0 && !proposal.executed && !proposal.cancelled, "CancelEnvProposal: Proposal not active or already processed");
        require(block.timestamp <= proposal.voteEndTime, "CancelEnvProposal: Voting has already ended");

        proposal.cancelled = true;

        // In a system with staked tokens for proposal, tokens would be returned here.

        emit EnvironmentalProposalCancelled(proposalId);
    }


    // --- Contract Administration & Configuration ---

    /// @notice Sets the base URI for SDO metadata.
    /// @param baseURI The new base URI.
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @notice Sets the parameters controlling evolution.
    /// @param baseDecayRatePerDay_ How fast vitality decays per day.
    /// @param evolutionMaturityThreshold_ Min maturity for evolution.
    /// @param evolutionVitalityThreshold_ Min vitality for evolution.
    /// @param environmentalAdaptationRate_ How much environment influences adaptation.
    function setEvolutionParams(
        uint64 baseDecayRatePerDay_,
        uint64 evolutionMaturityThreshold_,
        uint64 evolutionVitalityThreshold_,
        uint64 environmentalAdaptationRate_
        ) public onlyOwner {
            currentEnvironmentalFactors.baseDecayRatePerDay = baseDecayRatePerDay_;
            currentEnvironmentalFactors.evolutionMaturityThreshold = evolutionMaturityThreshold_;
            currentEnvironmentalFactors.evolutionVitalityThreshold = evolutionVitalityThreshold_;
            currentEnvironmentalFactors.environmentalAdaptationRate = environmentalAdaptationRate_;
            // Note: Emit a generic EnvironmentalFactorsUpdated event or specific one
            emit EnvironmentalFactorsUpdated(currentEnvironmentalFactors); // Or a specific admin event
        }

    /// @notice Sets the parameters controlling reproduction.
    /// @param reproductionMaturityThreshold_ Min maturity for reproduction.
    /// @param reproductionVitalityCost_ Vitality consumed by reproduction.
    /// @param minFeedingAmount_ Minimum ERC20 needed per feed.
    /// @param reproductionFee_ ERC20 fee for reproduction.
    function setReproductionParams(
         uint64 reproductionMaturityThreshold_,
         uint64 reproductionVitalityCost_,
         uint256 minFeedingAmount_,
         uint256 reproductionFee_
        ) public onlyOwner {
            currentEnvironmentalFactors.reproductionMaturityThreshold = reproductionMaturityThreshold_;
            currentEnvironmentalFactors.reproductionVitalityCost = reproductionVitalityCost_;
            currentEnvironmentalFactors.minFeedingAmount = minFeedingAmount_;
            reproductionFee = reproductionFee_;
             emit EnvironmentalFactorsUpdated(currentEnvironmentalFactors); // Or a specific admin event
        }

    /// @notice Sets the parameters for environmental governance voting.
    /// @param votingPeriod_ Voting period in seconds.
    /// @param executionDelay_ Execution delay in seconds.
    /// @param quorumThreshold_ Minimum total votes needed (simplified).
    /// @param majorityThreshold_ Percentage of yes votes needed to pass.
    function setEnvironmentalVoteParams(
        uint256 votingPeriod_,
        uint256 executionDelay_,
        uint256 quorumThreshold_,
        uint256 majorityThreshold_
        ) public onlyOwner {
            environmentalVotingPeriod = votingPeriod_;
            environmentalExecutionDelay = executionDelay_;
            environmentalQuorumThreshold = quorumThreshold_;
            environmentalMajorityThreshold = majorityThreshold_; // e.g., 51 for 51%
        }


    /// @notice Allows the owner to withdraw accumulated feeding tokens or reproduction fees.
    /// @param amount The amount of feedingToken to withdraw.
    function withdrawFees(uint256 amount) public onlyOwner nonReentrant {
         require(feedingToken.transfer(feeRecipient, amount), "WithdrawFees: Token transfer failed");
    }

    // --- ERC-165 Support (Optional but good practice for discoverability) ---
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

     function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC721 || super.supportsInterface(interfaceId);
    }
}
```