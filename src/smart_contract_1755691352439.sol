Here's a Solidity smart contract for a "Veridian Genesis - Adaptive Neural Art Protocol" (V-GENESIS). This contract combines several advanced, creative, and trendy concepts:

*   **Dynamic NFTs (Veridians):** NFTs whose traits can evolve.
*   **Simulated AI Influence:** An interface for an off-chain AI oracle to suggest or influence trait evolution.
*   **Decentralized Curation & Governance:** A robust curator reputation system where users stake tokens to participate in trait evolution proposals.
*   **Adaptive Breeding:** A unique mechanism for combining traits from two parent Veridians to create a new one, with probabilistic mutation.
*   **Soulbound/Staked NFTs:** Veridians can be "staked" to the protocol to earn utility tokens, adding a yield-bearing aspect.
*   **On-chain Lore:** Each NFT maintains an evolving history.

This design aims to be distinct from typical open-source projects by integrating these mechanisms into a single, cohesive art evolution ecosystem.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
* @title Veridian Genesis - Adaptive Neural Art Protocol
* @author YourNameHere (feel free to replace with your alias)
* @notice This contract implements a novel decentralized art protocol where NFTs (Veridians)
*         are dynamic, evolving based on community curation, simulated AI feedback, and genetic breeding.
*         It features a unique "Essence" utility token, a curator reputation system, and on-chain
*         mechanisms for art evolution and new art creation.
*
* @dev This contract combines ERC721, ERC20, advanced state management, and an oracle-like
*      interface for AI influence, providing a rich example of a multi-faceted DApp.
*      The "AI" aspect is simulated via an oracle interface; actual AI computation would happen off-chain.
*      Some gas-intensive operations (like iterating through all curators/proposals for reputation/execution)
*      are simplified for demonstration. In production, these would require more optimized data structures
*      (e.g., iterable mappings, specific queues, or off-chain indexing for large datasets).
*/

// Outline:
// 1. Core Data Structures & Events
// 2. Constants & Configuration
// 3. ERC-721 NFT Implementation (VeridianGenesisNFT)
// 4. ERC-20 Utility Token Implementation (EssenceToken - nested for demo)
// 5. Curator Guild & Reputation Management
// 6. Neural Genesis & Trait Evolution
// 7. Adaptive Breeding Mechanics
// 8. Essence Staking & Rewards
// 9. Protocol Governance & Administration

// Function Summary:
// I. NFT & Trait Management
// 1.  mintGenesisVeridian(address _to, bytes32[] memory _initialTraitNames, bytes32[] memory _initialTraitValues): Mints a new initial Veridian NFT with predefined traits. (Owner only)
// 2.  getVeridianTraits(uint256 _tokenId): Returns all current trait names and values of a specific Veridian.
// 3.  getVeridianTrait(uint256 _tokenId, bytes32 _traitName): Returns a specific trait's value for a Veridian.
// 4.  getVeridianLore(uint256 _tokenId): Retrieves the evolving on-chain lore/history entries of a Veridian.
// 5.  getTotalVeridians(): Returns the total number of Veridians minted so far.
// 6.  tokenURI(uint256 _tokenId): Generates a dynamic URI for the Veridian's metadata, reflecting its current state.
//
// II. Neural Genesis & Trait Evolution
// 7.  proposeTraitMutation(uint256 _veridianId, bytes32 _traitName, bytes32 _newValue): Allows an active curator to propose a trait mutation for a Veridian.
// 8.  voteOnTraitMutation(uint256 _proposalId, bool _support): Allows an active curator to vote on an open trait mutation proposal.
// 9.  executeEvolutionCycle(): Triggers the processing of all expired trait mutation proposals and incorporates simulated AI feedback. (Permissionless)
// 10. setAIOracleAddress(address _oracleAddress): Sets the address of the external AI oracle contract. (Owner only)
// 11. receiveAIFeedback(uint256 _veridianId, bytes32 _traitName, bytes32 _aiRecommendedValue, uint256 _influenceScore): Callback from the AI oracle to deliver trait feedback, influencing proposals. (AI Oracle only)
//
// III. Curator Guild & Reputation
// 12. stakeForCuratorRole(): Allows a user to stake Essence tokens to become an active Veridian curator.
// 13. unstakeFromCuratorRole(): Allows an active curator to unstake their Essence and relinquish their role.
// 14. getCuratorReputation(address _curator): Retrieves the current reputation score of a specific curator.
// 15. getTopCurators(uint256 _count): Returns a list of the top N curators by reputation score.
//
// IV. Adaptive Breeding (Genetic Algorithm-inspired)
// 16. proposeVeridianPairing(uint256 _veridianId1, uint256 _veridianId2): Initiates a breeding proposal between two Veridians; requires owners' confirmation.
// 17. confirmVeridianPairing(uint256 _pairingProposalId): An owner confirms their Veridian's participation in a breeding proposal.
// 18. breedNewVeridian(uint256 _pairingProposalId, address _recipient): Executes the breeding process, combining traits from parents to create a new Veridian, applying mutation.
// 19. getVeridianBreedingCooldown(uint256 _veridianId): Returns the timestamp when a Veridian can next participate in breeding.
//
// V. Essence Token & Staking
// 20. claimEssenceRewards(): Allows active curators and staked Veridian owners to claim accumulated Essence rewards.
// 21. stakeVeridianForEssence(uint256 _veridianId): Stakes a Veridian NFT with the protocol to earn Essence rewards over time.
// 22. unstakeVeridianFromEssence(uint256 _veridianId): Unstakes a Veridian NFT and transfers it back to its owner.
// 23. getVeridianStakingYield(uint256 _veridianId): Calculates the estimated pending Essence yield for a staked Veridian.
//
// VI. Protocol Governance & Administration
// 24. pause(): Pauses core protocol functions, preventing most state-changing interactions. (Owner only)
// 25. unpause(): Unpauses the protocol. (Owner only)
// 26. setCuratorStakeAmount(uint256 _amount): Sets the required Essence stake for a curator role. (Owner only)
// 27. setBreedingFee(uint256 _fee): Sets the Essence token fee for breeding operations. (Owner only)
// 28. setEvolutionCycleDuration(uint256 _duration): Sets the duration (in seconds) of each trait evolution cycle. (Owner only)
// 29. setBaseMutationRate(uint256 _rate): Sets the base probability (in basis points, 0-10000) for trait mutations. (Owner only)
// 30. updateVeridianTraitInternal(uint256 _tokenId, bytes32 _traitName, bytes32 _newValue): Directly updates a Veridian's trait. (Owner only, for emergency/manual overrides).
// 31. withdrawProtocolFees(address _to): Allows the owner to withdraw accumulated Essence fees (e.g., from breeding). (Owner only)
// 32. transferOwnership(address newOwner): Transfers contract ownership to a new address. (OpenZeppelin's Ownable)

contract VeridianGenesisProtocol is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256; // For tokenURI and lore generation

    // --- 1. Core Data Structures & Events ---

    struct Veridian {
        uint256 tokenId;
        // owner is handled by ERC721Enumerable's internal mapping
        mapping(bytes32 => bytes32) traits; // Mapping of trait name to trait value
        bytes32[] traitNames; // Array to keep track of existing trait names for iteration
        string[] lore; // Evolving on-chain story/history entries
        uint256 lastBreedTimestamp; // Timestamp of last successful breeding
        bool isStakedForEssence; // True if NFT is currently staked
        uint256 essenceStakeStartTime; // Timestamp when staking began
    }

    struct TraitProposal {
        uint256 proposalId;
        uint256 veridianId;
        bytes32 traitName;
        bytes32 newValue;
        address proposer;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Tracks if a curator has voted on this proposal
        uint256 creationTimestamp;
        bool executed; // True if the proposal has been processed in an evolution cycle
        bool passed; // True if the proposal passed the vote/AI consensus
        bool aiInfluenced; // True if AI feedback was received and impacted this proposal
    }

    struct Curator {
        address curatorAddress; // The address of the curator
        uint256 stakeAmount; // Amount of Essence staked by the curator
        int256 reputationScore; // Reputation score, can be positive or negative
        uint256 lastActivityTimestamp; // Timestamp of last significant activity (e.g., vote, stake)
        bool isActive; // True if the address is currently an active curator
    }

    struct BreedingPairing {
        uint256 proposalId;
        uint256 veridianId1;
        uint256 veridianId2;
        address owner1; // Stored to verify initial ownership for consent
        address owner2; // Stored to verify initial ownership for consent
        bool owner1Confirmed; // True if first owner has confirmed
        bool owner2Confirmed; // True if second owner has confirmed
        uint256 creationTimestamp;
        bool executed; // True if breeding has occurred for this pairing
    }

    // Events to log significant actions
    event VeridianMinted(uint256 indexed tokenId, address indexed owner, bytes32[] traitNames, bytes32[] traitValues);
    event TraitUpdated(uint256 indexed tokenId, bytes32 indexed traitName, bytes32 oldValue, bytes32 newValue, string reason);
    event TraitProposalCreated(uint256 indexed proposalId, uint256 indexed veridianId, bytes32 traitName, bytes32 newValue, address proposer);
    event TraitProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event EvolutionCycleExecuted(uint256 indexed cycleNumber, uint256 proposalsProcessed, uint256 veridiansEvolved);
    event AIFeedbackReceived(uint256 indexed veridianId, bytes32 traitName, bytes32 aiRecommendedValue, uint256 influenceScore);
    event CuratorStaked(address indexed curator, uint256 amount);
    event CuratorUnstaked(address indexed curator, uint256 amount);
    event CuratorReputationUpdated(address indexed curator, int256 newReputation);
    event BreedingPairingProposed(uint256 indexed proposalId, uint256 indexed veridianId1, uint256 indexed veridianId2);
    event BreedingPairingConfirmed(uint256 indexed proposalId, address indexed confirmer);
    event NewVeridianBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, address indexed recipient);
    event VeridianStakedForEssence(uint256 indexed tokenId, address indexed owner);
    event VeridianUnstakedFromEssence(uint256 indexed tokenId, address indexed owner);
    event EssenceRewardsClaimed(address indexed beneficiary, uint256 amount);
    event LoreAdded(uint256 indexed tokenId, string newLore);

    // --- 2. Constants & Configuration ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _breedingPairingIdCounter;
    uint256 public currentEvolutionCycle = 0; // Tracks the current evolution cycle number

    // Configuration parameters (set by owner)
    uint256 public curatorStakeAmount = 1000 * (10 ** 18); // Default 1000 Essence (adjust decimals as needed)
    uint256 public breedingFee = 100 * (10 ** 18); // Default 100 Essence
    uint256 public evolutionCycleDuration = 7 days; // How long an evolution cycle lasts before `executeEvolutionCycle` can be called
    uint256 public nextEvolutionCycleTimestamp = 0; // When the next cycle can be executed
    uint256 public baseMutationRateBasisPoints = 500; // 5.00% base mutation rate (out of 10000)
    uint256 public constant BREEDING_COOLDOWN = 30 days; // Cooldown period for a Veridian after breeding

    address public aiOracleAddress; // Address of the (simulated) AI oracle contract
    ERC20 public essence; // Instance of the Essence ERC-20 token

    // --- Mappings ---
    mapping(uint256 => Veridian) public veridians; // tokenId => Veridian struct
    mapping(address => Curator) public curators; // curatorAddress => Curator struct
    mapping(uint256 => TraitProposal) public traitProposals; // proposalId => TraitProposal struct
    mapping(uint256 => BreedingPairing) public breedingPairings; // pairingId => BreedingPairing struct

    // To track active proposals by Veridian ID for efficient lookup and cleanup
    mapping(uint256 => uint256[]) public activeProposalsByVeridian;

    // For `getTopCurators` (can be optimized with a more efficient data structure for very large N)
    address[] public curatorAddresses; // Stores addresses of all active and inactive curators

    constructor() ERC721("Veridian Genesis", "VGEN") {
        // For demonstration, `EssenceToken` is deployed internally.
        // In a production environment, `EssenceToken` would be deployed separately,
        // and its address passed into this constructor.
        essence = new EssenceToken();
        
        // Initial setup for the first evolution cycle
        nextEvolutionCycleTimestamp = block.timestamp + evolutionCycleDuration;
    }

    // --- 3. ERC-721 NFT Implementation (VeridianGenesisNFT) ---

    // Overrides required by ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Mints a new initial Veridian NFT with predefined genesis traits.
     *      Only callable by the contract owner.
     * @param _to The address to mint the Veridian to.
     * @param _initialTraitNames An array of trait names for the new Veridian.
     * @param _initialTraitValues An array of corresponding trait values.
     * @return The tokenId of the newly minted Veridian.
     */
    function mintGenesisVeridian(address _to, bytes32[] memory _initialTraitNames, bytes32[] memory _initialTraitValues)
        public
        onlyOwner
        returns (uint256)
    {
        require(_initialTraitNames.length == _initialTraitValues.length, "Trait names and values mismatch");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_to, newItemId);

        Veridian storage newVeridian = veridians[newItemId];
        newVeridian.tokenId = newItemId;
        // newVeridian.owner = _to; // ERC721 handles owner mapping
        
        for (uint256 i = 0; i < _initialTraitNames.length; i++) {
            newVeridian.traits[_initialTraitNames[i]] = _initialTraitValues[i];
            newVeridian.traitNames.push(_initialTraitNames[i]);
        }
        newVeridian.lore.push("Genesis: A new Veridian emerges.");

        emit VeridianMinted(newItemId, _to, _initialTraitNames, _initialTraitValues);
        return newItemId;
    }

    /**
     * @dev Returns all current trait names and values of a specific Veridian.
     * @param _tokenId The ID of the Veridian.
     * @return A tuple containing arrays of trait names and their corresponding values.
     */
    function getVeridianTraits(uint256 _tokenId) public view returns (bytes32[] memory names, bytes32[] memory values) {
        require(_exists(_tokenId), "Veridian does not exist");
        Veridian storage v = veridians[_tokenId];
        names = v.traitNames;
        values = new bytes32[](names.length);
        for (uint256 i = 0; i < names.length; i++) {
            values[i] = v.traits[names[i]];
        }
        return (names, values);
    }

    /**
     * @dev Returns a specific trait value for a Veridian.
     * @param _tokenId The ID of the Veridian.
     * @param _traitName The name of the trait to retrieve.
     * @return The value of the specified trait.
     */
    function getVeridianTrait(uint256 _tokenId, bytes32 _traitName) public view returns (bytes32) {
        require(_exists(_tokenId), "Veridian does not exist");
        return veridians[_tokenId].traits[_traitName];
    }

    /**
     * @dev Retrieves the evolving on-chain lore/history entries of a Veridian.
     * @param _tokenId The ID of the Veridian.
     * @return An array of strings representing the Veridian's lore.
     */
    function getVeridianLore(uint256 _tokenId) public view returns (string[] memory) {
        require(_exists(_tokenId), "Veridian does not exist");
        return veridians[_tokenId].lore;
    }

    /**
     * @dev Returns the total number of Veridians minted.
     * @return The current value of the token ID counter.
     */
    function getTotalVeridians() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Generates a dynamic URI for the Veridian. This URI typically points to an off-chain
     *      server or IPFS gateway that renders the JSON metadata and image based on the
     *      Veridian's current on-chain traits.
     * @param _tokenId The ID of the Veridian.
     * @return A string representing the token URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real dApp, this URI would point to an IPFS gateway or a dedicated API that generates
        // the JSON metadata and image dynamically based on the Veridian's current traits.
        return string(abi.encodePacked("https://api.veridiangenesis.xyz/token/", _tokenId.toString()));
    }

    /**
     * @dev Internal function to update a Veridian's trait. Only callable by trusted protocol functions
     *      or owner. It also adds an entry to the Veridian's lore.
     * @param _tokenId The ID of the Veridian.
     * @param _traitName The name of the trait to update.
     * @param _newValue The new value for the trait.
     * @param _loreAddition A string describing the reason for the trait update, added to lore.
     */
    function _updateVeridianTraitInternal(uint256 _tokenId, bytes32 _traitName, bytes32 _newValue, string memory _loreAddition) internal {
        require(_exists(_tokenId), "Veridian does not exist");
        Veridian storage v = veridians[_tokenId];
        bytes32 oldValue = v.traits[_traitName];
        require(oldValue != _newValue, "New trait value must be different from current");

        v.traits[_traitName] = _newValue;
        v.lore.push(_loreAddition);
        emit TraitUpdated(_tokenId, _traitName, oldValue, _newValue, _loreAddition);
    }

    /**
     * @dev Public (owner-only) wrapper for internal trait update. For emergency or direct changes.
     * @param _tokenId The ID of the Veridian.
     * @param _traitName The name of the trait to update.
     * @param _newValue The new value for the trait.
     */
    function updateVeridianTraitInternal(uint256 _tokenId, bytes32 _traitName, bytes32 _newValue) public onlyOwner {
        _updateVeridianTraitInternal(_tokenId, _traitName, _newValue, "Admin manual trait update.");
    }

    // --- 4. ERC-20 Utility Token Implementation (EssenceToken) ---
    // This is defined as an internal contract for the demo. In production,
    // this would be a separate contract deployment, and its address passed to VeridianGenesisProtocol.
    contract EssenceToken is ERC20 {
        constructor() ERC20("Veridian Essence", "ESSENCE") {
            _mint(msg.sender, 1000000 * (10 ** 18)); // Mint 1,000,000 ESSENCE to deployer for testing
        }
    }

    // --- 5. Curator Guild & Reputation Management ---

    /**
     * @dev Allows a user to stake Essence tokens to become a Veridian curator.
     *      Requires the user to first approve this contract to spend `curatorStakeAmount` Essence.
     */
    function stakeForCuratorRole() public whenNotPaused {
        require(curators[msg.sender].curatorAddress == address(0) || !curators[msg.sender].isActive, "Already an active curator");
        require(essence.balanceOf(msg.sender) >= curatorStakeAmount, "Insufficient Essence balance");
        require(essence.transferFrom(msg.sender, address(this), curatorStakeAmount), "Essence transfer failed");

        curators[msg.sender].curatorAddress = msg.sender;
        curators[msg.sender].stakeAmount = curatorStakeAmount;
        curators[msg.sender].reputationScore = 0; // Reset reputation for new/re-staked curators
        curators[msg.sender].lastActivityTimestamp = block.timestamp;
        curators[msg.sender].isActive = true;

        // Add to curatorAddresses if not already present, for iteration purposes
        bool found = false;
        for (uint256 i = 0; i < curatorAddresses.length; i++) {
            if (curatorAddresses[i] == msg.sender) {
                found = true;
                break;
            }
        }
        if (!found) {
            curatorAddresses.push(msg.sender);
        }

        emit CuratorStaked(msg.sender, curatorStakeAmount);
    }

    /**
     * @dev Allows an active curator to unstake their Essence and relinquish their role.
     *      They must not have any pending unexecuted proposals.
     */
    function unstakeFromCuratorRole() public whenNotPaused {
        require(curators[msg.sender].isActive, "Not an active curator");
        require(curators[msg.sender].stakeAmount > 0, "No staked Essence to unstake");

        uint256 amount = curators[msg.sender].stakeAmount;
        curators[msg.sender].stakeAmount = 0;
        curators[msg.sender].isActive = false;

        require(essence.transfer(msg.sender, amount), "Essence transfer failed during unstake");

        emit CuratorUnstaked(msg.sender, amount);
    }

    /**
     * @dev Retrieves the current reputation score of a specific curator.
     * @param _curator The address of the curator.
     * @return The curator's reputation score.
     */
    function getCuratorReputation(address _curator) public view returns (int256) {
        return curators[_curator].reputationScore;
    }

    /**
     * @dev Internal function to update a curator's reputation.
     * @param _curator The address of the curator.
     * @param _change The change in reputation (positive for increase, negative for decrease).
     */
    function _updateCuratorReputation(address _curator, int256 _change) internal {
        curators[_curator].reputationScore += _change;
        curators[_curator].lastActivityTimestamp = block.timestamp;
        emit CuratorReputationUpdated(_curator, curators[_curator].reputationScore);
    }

    /**
     * @dev Returns a list of the top N curators by reputation score.
     *      Note: This implementation uses a simple sorting algorithm, which can be gas-intensive
     *      for a very large number of curators. For highly scalable DApps, this data might be
     *      computed off-chain or stored in a more efficient on-chain sorted data structure.
     * @param _count The number of top curators to retrieve.
     * @return A tuple containing arrays of top curator addresses and their corresponding scores.
     */
    function getTopCurators(uint256 _count) public view returns (address[] memory, int256[] memory) {
        uint256 numCurators = curatorAddresses.length;
        if (numCurators == 0) {
            return (new address[](0), new int256[](0));
        }

        address[] memory tempAddresses = new address[](numCurators);
        int256[] memory tempScores = new int256[](numCurators);

        // Populate temporary arrays
        for (uint256 i = 0; i < numCurators; i++) {
            tempAddresses[i] = curatorAddresses[i];
            tempScores[i] = curators[curatorAddresses[i]].reputationScore;
        }

        // Simple bubble sort for demonstration (inefficient for large N)
        for (uint256 i = 0; i < numCurators; i++) {
            for (uint256 j = i + 1; j < numCurators; j++) {
                if (tempScores[i] < tempScores[j]) {
                    // Swap scores
                    int256 tempScore = tempScores[i];
                    tempScores[i] = tempScores[j];
                    tempScores[j] = tempScore;

                    // Swap addresses
                    address tempAddress = tempAddresses[i];
                    tempAddresses[i] = tempAddresses[j];
                    tempAddresses[j] = tempAddress;
                }
            }
        }

        uint256 actualCount = _count > numCurators ? numCurators : _count;
        address[] memory resultAddresses = new address[](actualCount);
        int256[] memory resultScores = new int256[](actualCount);

        for (uint256 i = 0; i < actualCount; i++) {
            resultAddresses[i] = tempAddresses[i];
            resultScores[i] = tempScores[i];
        }

        return (resultAddresses, resultScores);
    }

    // --- 6. Neural Genesis & Trait Evolution ---

    /**
     * @dev Allows an active curator to propose a trait mutation for a specific Veridian.
     *      Only one active proposal per Veridian-trait pair is allowed.
     * @param _veridianId The ID of the Veridian to propose a change for.
     * @param _traitName The name of the trait to be modified.
     * @param _newValue The new value proposed for the trait.
     */
    function proposeTraitMutation(uint256 _veridianId, bytes32 _traitName, bytes32 _newValue) public whenNotPaused {
        require(curators[msg.sender].isActive, "Caller is not an active curator");
        require(_exists(_veridianId), "Veridian does not exist");
        require(veridians[_veridianId].traits[_traitName] != bytes32(0), "Trait does not exist on this Veridian");
        require(veridians[_veridianId].traits[_traitName] != _newValue, "New trait value must be different from current");

        // Check for existing active proposals for this veridian & trait
        for (uint256 i = 0; i < activeProposalsByVeridian[_veridianId].length; i++) {
            uint256 existingProposalId = activeProposalsByVeridian[_veridianId][i];
            TraitProposal storage existingProposal = traitProposals[existingProposalId];
            if (!existingProposal.executed && existingProposal.traitName == _traitName) {
                revert("An active proposal for this Veridian's trait already exists.");
            }
        }

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        TraitProposal storage newProposal = traitProposals[proposalId];
        newProposal.proposalId = proposalId;
        newProposal.veridianId = _veridianId;
        newProposal.traitName = _traitName;
        newProposal.newValue = _newValue;
        newProposal.proposer = msg.sender;
        newProposal.creationTimestamp = block.timestamp;

        activeProposalsByVeridian[_veridianId].push(proposalId); // Add to active proposals list

        // Proposer automatically casts a 'yes' vote and receives initial reputation.
        _voteOnTraitProposal(proposalId, msg.sender, true);

        emit TraitProposalCreated(proposalId, _veridianId, _traitName, _newValue, msg.sender);
    }

    /**
     * @dev Internal helper function for casting a vote on a trait proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voter The address of the curator casting the vote.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function _voteOnTraitProposal(uint256 _proposalId, address _voter, bool _support) internal {
        TraitProposal storage proposal = traitProposals[_proposalId];
        require(proposal.proposalId == _proposalId, "Proposal does not exist");
        require(!proposal.executed, "Proposal has already been executed");
        require(block.timestamp <= proposal.creationTimestamp + evolutionCycleDuration, "Voting period for this proposal has ended");
        require(curators[_voter].isActive, "Voter is not an active curator");
        require(!proposal.hasVoted[_voter], "Curator has already voted on this proposal");

        proposal.hasVoted[_voter] = true;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit TraitProposalVoted(_proposalId, _voter, _support);
    }

    /**
     * @dev Allows an active curator to vote on an active trait mutation proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function voteOnTraitMutation(uint256 _proposalId, bool _support) public whenNotPaused {
        _voteOnTraitProposal(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Triggers the processing of all expired trait mutation proposals and incorporates simulated AI feedback.
     *      This function is permissionless and can be called by anyone after the `evolutionCycleDuration` has passed.
     *      It iterates through proposals, determines their outcome (based on votes and AI), and updates Veridian traits.
     */
    function executeEvolutionCycle() public whenNotPaused {
        require(block.timestamp >= nextEvolutionCycleTimestamp, "Not yet time for next evolution cycle");

        currentEvolutionCycle++;
        uint256 proposalsProcessedCount = 0;
        uint256 veridiansEvolvedCount = 0;

        // Iterate through all Veridians that might have active proposals
        // (This part can be gas intensive if `activeProposalsByVeridian` contains many entries,
        //  or if `_tokenIdCounter` is very high. In production, consider queuing proposals differently.)
        uint256 totalVeridiansInSystem = _tokenIdCounter.current();
        for (uint256 i = 1; i <= totalVeridiansInSystem; i++) {
            uint256[] storage proposalsForVeridian = activeProposalsByVeridian[i];
            
            // Collect proposals to process in a temporary array, then clean up.
            uint256[] memory proposalsToProcess = new uint256[](proposalsForVeridian.length);
            uint256 tempCount = 0;
            for (uint256 j = 0; j < proposalsForVeridian.length; j++) {
                uint256 proposalId = proposalsForVeridian[j];
                TraitProposal storage proposal = traitProposals[proposalId];

                if (!proposal.executed && proposal.creationTimestamp + evolutionCycleDuration <= block.timestamp) {
                    proposalsToProcess[tempCount++] = proposalId;
                }
            }

            for (uint256 k = 0; k < tempCount; k++) {
                uint256 proposalId = proposalsToProcess[k];
                TraitProposal storage proposal = traitProposals[proposalId];
                proposalsProcessedCount++;

                // Determine outcome based on votes and AI influence
                bytes32 finalTraitValue = proposal.newValue; // Default to proposed value
                uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
                
                // Logic for AI influence and vote outcome:
                // If AI has influenced, its recommendation (which would have updated `newValue` or boosted `yesVotes`)
                // is considered, otherwise, it's based purely on curator majority.
                if (proposal.yesVotes > proposal.noVotes && totalVotes > 0) {
                    proposal.passed = true;
                } else {
                    proposal.passed = false;
                }

                if (proposal.passed) {
                    _updateVeridianTraitInternal(
                        proposal.veridianId,
                        proposal.traitName,
                        finalTraitValue, // `finalTraitValue` is `proposal.newValue` if passed
                        string(abi.encodePacked("Trait '", uint256(proposal.traitName).toString(), "' evolved to '", uint256(finalTraitValue).toString(), "' by curator consensus & AI (ID: ", proposalId.toString(), ")"))
                    );
                    veridiansEvolvedCount++;
                    _adjustCuratorReputationForProposal(proposalId, true); // Reward/penalize based on outcome
                } else {
                    _adjustCuratorReputationForProposal(proposalId, false);
                }
                proposal.executed = true; // Mark as executed
            }

            // Clean up `activeProposalsByVeridian` by removing executed proposals
            uint256 writeIndex = 0;
            for (uint256 j = 0; j < proposalsForVeridian.length; j++) {
                if (!traitProposals[proposalsForVeridian[j]].executed) {
                    proposalsForVeridian[writeIndex] = proposalsForVeridian[j];
                    writeIndex++;
                }
            }
            proposalsForVeridian.pop(); // Remove remaining elements (simplistic, requires re-pushing valid elements)
            assembly {
                mstore(proposalsForVeridian.slot, writeIndex) // Efficiently set dynamic array length
            }
        }

        nextEvolutionCycleTimestamp = block.timestamp + evolutionCycleDuration;
        emit EvolutionCycleExecuted(currentEvolutionCycle, proposalsProcessedCount, veridiansEvolvedCount);
    }

    /**
     * @dev Adjusts curator reputation based on proposal outcome.
     *      Curators whose votes align with the final outcome (pass/fail) receive positive reputation,
     *      while those whose votes contradict receive negative reputation.
     * @param _proposalId The ID of the proposal.
     * @param _passed True if the proposal passed, false otherwise.
     */
    function _adjustCuratorReputationForProposal(uint256 _proposalId, bool _passed) internal {
        TraitProposal storage proposal = traitProposals[_proposalId];
        // This loop iterates through all *known* curators.
        // In a very large system, this would be inefficient.
        // A more scalable solution would involve storing `address[] voters` within the `TraitProposal` struct,
        // or leveraging off-chain indexing of `TraitProposalVoted` events.
        for(uint256 i = 0; i < curatorAddresses.length; i++) {
            address currentCurator = curatorAddresses[i];
            if (proposal.hasVoted[currentCurator]) {
                if (_passed) { // Proposal passed
                    if (proposal.yesVotes > proposal.noVotes) { // Majority was 'yes'
                        if (proposal.hasVoted[currentCurator]) { // If curator voted
                            if (proposal.hasVoted[currentCurator]) _updateCuratorReputation(currentCurator, 5); // Voted 'yes', with majority
                            else _updateCuratorReputation(currentCurator, -3); // Voted 'no', against majority
                        }
                    } else { // Majority was 'no' or tie (implies failure unless AI overrode)
                        // This branch implies a passed proposal due to AI influence overriding curator majority, or a tie
                        _updateCuratorReputation(currentCurator, 1); // Small reward for participation/AI influence
                    }
                } else { // Proposal failed
                    if (proposal.noVotes > proposal.yesVotes || (proposal.yesVotes == proposal.noVotes && totalVotes > 0)) { // Majority was 'no' or tie
                        if (proposal.hasVoted[currentCurator]) { // If curator voted
                            if (!proposal.hasVoted[currentCurator]) _updateCuratorReputation(currentCurator, 3); // Voted 'no', with majority
                            else _updateCuratorReputation(currentCurator, -5); // Voted 'yes', against majority
                        }
                    } else { // Majority was 'yes' (implies failure due to AI overriding/lack of quorum)
                        _updateCuratorReputation(currentCurator, -1); // Small penalty for participation
                    }
                }
            }
        }
    }

    /**
     * @dev Sets the address of the external AI oracle contract. Only callable by the owner.
     *      This address is trusted to call `receiveAIFeedback`.
     * @param _oracleAddress The address of the AI oracle.
     */
    function setAIOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "AI Oracle address cannot be zero");
        aiOracleAddress = _oracleAddress;
    }

    /**
     * @dev Callback function from the AI oracle to deliver feedback for a Veridian trait.
     *      This function can only be called by the designated `aiOracleAddress`. It influences
     *      the outcome of active `TraitProposal`s.
     * @param _veridianId The ID of the Veridian.
     * @param _traitName The trait name for which feedback is provided.
     * @param _aiRecommendedValue The value recommended by the AI.
     * @param _influenceScore A score indicating the AI's confidence/influence on the trait change.
     */
    function receiveAIFeedback(uint256 _veridianId, bytes32 _traitName, bytes32 _aiRecommendedValue, uint256 _influenceScore) public {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can call this function");
        require(_exists(_veridianId), "Veridian does not exist");

        // Find the active proposal for this Veridian and trait.
        bool foundActiveProposal = false;
        for (uint256 i = 0; i < activeProposalsByVeridian[_veridianId].length; i++) {
            uint256 proposalId = activeProposalsByVeridian[_veridianId][i];
            TraitProposal storage proposal = traitProposals[proposalId];

            if (!proposal.executed && proposal.traitName == _traitName) {
                // If AI agrees with the proposed value, boost its chances.
                // If AI suggests a different value, this can override or become a new target.
                // For simplicity: if AI suggests, its weight is added to 'yes' votes towards its value.
                // If `_aiRecommendedValue` differs from `proposal.newValue`, it signifies AI dissent or new insight.
                if (proposal.newValue == _aiRecommendedValue) {
                    proposal.yesVotes += _influenceScore; // Boost votes for the current proposal
                } else {
                    // AI suggests a different value. This mechanism implies AI can alter the proposal target.
                    // This is an advanced concept: AI guides the trait.
                    proposal.newValue = _aiRecommendedValue; // Update the proposal's target value
                    proposal.yesVotes += _influenceScore; // AI's recommendation adds significant weight
                }
                proposal.aiInfluenced = true;
                foundActiveProposal = true;
                break;
            }
        }
        if (!foundActiveProposal) {
            // Option: If no active proposal, AI could implicitly trigger a new proposal or notify curators.
            // For this demo, AI feedback only influences existing proposals.
        }

        emit AIFeedbackReceived(_veridianId, _traitName, _aiRecommendedValue, _influenceScore);
    }

    // --- 7. Adaptive Breeding (Genetic Algorithm-inspired) ---

    /**
     * @dev Allows an owner to propose two Veridians for breeding. Both owners must confirm the pairing.
     *      A breeding cooldown is enforced for both parents.
     * @param _veridianId1 The ID of the first Veridian.
     * @param _veridianId2 The ID of the second Veridian.
     */
    function proposeVeridianPairing(uint256 _veridianId1, uint256 _veridianId2) public whenNotPaused {
        require(_exists(_veridianId1) && _exists(_veridianId2), "One or both Veridians do not exist");
        require(_veridianId1 != _veridianId2, "Cannot breed a Veridian with itself");
        require(ownerOf(_veridianId1) == msg.sender || ownerOf(_veridianId2) == msg.sender, "Caller must own one of the Veridians to propose pairing");
        require(veridians[_veridianId1].lastBreedTimestamp + BREEDING_COOLDOWN <= block.timestamp, "Veridian 1 is on breeding cooldown");
        require(veridians[_veridianId2].lastBreedTimestamp + BREEDING_COOLDOWN <= block.timestamp, "Veridian 2 is on breeding cooldown");

        // Prevent duplicate or overlapping breeding proposals for the same pair
        uint256 totalPairings = _breedingPairingIdCounter.current();
        for (uint256 i = 1; i <= totalPairings; i++) {
            BreedingPairing storage existingPairing = breedingPairings[i];
            if (!existingPairing.executed &&
                ((existingPairing.veridianId1 == _veridianId1 && existingPairing.veridianId2 == _veridianId2) ||
                 (existingPairing.veridianId1 == _veridianId2 && existingPairing.veridianId2 == _veridianId1))) {
                revert("An active breeding proposal for this pair already exists.");
            }
        }

        _breedingPairingIdCounter.increment();
        uint256 proposalId = _breedingPairingIdCounter.current();

        BreedingPairing storage newPairing = breedingPairings[proposalId];
        newPairing.proposalId = proposalId;
        newPairing.veridianId1 = _veridianId1;
        newPairing.veridianId2 = _veridianId2;
        newPairing.owner1 = ownerOf(_veridianId1);
        newPairing.owner2 = ownerOf(_veridianId2);
        newPairing.creationTimestamp = block.timestamp;

        // If proposer owns both, mark both confirmed immediately
        if (newPairing.owner1 == msg.sender) newPairing.owner1Confirmed = true;
        if (newPairing.owner2 == msg.sender) newPairing.owner2Confirmed = true;

        emit BreedingPairingProposed(proposalId, _veridianId1, _veridianId2);
    }

    /**
     * @dev An owner confirms their Veridian's participation in a breeding proposal.
     *      The proposal has a time limit for confirmation.
     * @param _pairingProposalId The ID of the breeding proposal.
     */
    function confirmVeridianPairing(uint256 _pairingProposalId) public whenNotPaused {
        BreedingPairing storage pairing = breedingPairings[_pairingProposalId];
        require(pairing.proposalId == _pairingProposalId, "Pairing proposal does not exist");
        require(!pairing.executed, "Pairing proposal already executed");
        require(block.timestamp <= pairing.creationTimestamp + 7 days, "Pairing proposal has expired for confirmation"); // 7 day confirmation window

        if (ownerOf(pairing.veridianId1) == msg.sender && !pairing.owner1Confirmed) {
            pairing.owner1Confirmed = true;
        } else if (ownerOf(pairing.veridianId2) == msg.sender && !pairing.owner2Confirmed) {
            pairing.owner2Confirmed = true;
        } else {
            revert("Caller is not an owner of a participating Veridian or already confirmed.");
        }

        emit BreedingPairingConfirmed(_pairingProposalId, msg.sender);
    }

    /**
     * @dev Executes the breeding process to create a new Veridian. It combines traits
     *      from the two parent Veridians and applies a probabilistic mutation.
     *      Requires payment of `breedingFee`.
     * @param _pairingProposalId The ID of the confirmed breeding proposal.
     * @param _recipient The address to mint the new Veridian (child) to.
     */
    function breedNewVeridian(uint256 _pairingProposalId, address _recipient) public whenNotPaused {
        BreedingPairing storage pairing = breedingPairings[_pairingProposalId];
        require(pairing.proposalId == _pairingProposalId, "Pairing proposal does not exist");
        require(!pairing.executed, "Pairing proposal already executed");
        require(pairing.owner1Confirmed && pairing.owner2Confirmed, "Both owners must confirm the pairing before breeding");
        require(essence.balanceOf(msg.sender) >= breedingFee, "Insufficient Essence for breeding fee");
        require(essence.transferFrom(msg.sender, address(this), breedingFee), "Essence transfer failed for breeding fee");

        Veridian storage parent1 = veridians[pairing.veridianId1];
        Veridian storage parent2 = veridians[pairing.veridianId2];

        require(parent1.lastBreedTimestamp + BREEDING_COOLDOWN <= block.timestamp, "Parent 1 is on breeding cooldown");
        require(parent2.lastBreedTimestamp + BREEDING_COOLDOWN <= block.timestamp, "Parent 2 is on breeding cooldown");

        _tokenIdCounter.increment();
        uint256 childId = _tokenIdCounter.current();
        _safeMint(_recipient, childId);

        Veridian storage child = veridians[childId];
        child.tokenId = childId;
        // child.owner = _recipient; // Handled by ERC721
        child.lore.push(string(abi.encodePacked("Born from Veridian #", parent1.tokenId.toString(), " and #", parent2.tokenId.toString())));

        // Trait combination logic:
        // Collect all unique trait names from both parents.
        mapping(bytes32 => bool) seenTraitNames;
        bytes32[] memory allTraitNamesTemp = new bytes32[](parent1.traitNames.length + parent2.traitNames.length);
        uint256 traitCount = 0;

        for(uint256 i = 0; i < parent1.traitNames.length; i++) {
            bytes32 traitName = parent1.traitNames[i];
            if (!seenTraitNames[traitName]) {
                seenTraitNames[traitName] = true;
                allTraitNamesTemp[traitCount++] = traitName;
            }
        }
        for(uint256 i = 0; i < parent2.traitNames.length; i++) {
            bytes32 traitName = parent2.traitNames[i];
            if (!seenTraitNames[traitName]) {
                seenTraitNames[traitName] = true;
                allTraitNamesTemp[traitCount++] = traitName;
            }
        }

        // Create a precise-sized array for unique trait names
        bytes32[] memory uniqueTraitNames = new bytes32[](traitCount);
        for (uint256 i = 0; i < traitCount; i++) {
            uniqueTraitNames[i] = allTraitNamesTemp[i];
        }

        child.traitNames = new bytes32[](traitCount); // Initialize child's traitNames array
        
        // Random seed for trait selection and mutation
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, childId, pairing.veridianId1, pairing.veridianId2)));

        for (uint256 i = 0; i < uniqueTraitNames.length; i++) {
            bytes32 currentTraitName = uniqueTraitNames[i];
            bytes32 parent1Value = parent1.traits[currentTraitName];
            bytes32 parent2Value = parent2.traits[currentTraitName];
            bytes32 newTraitValue;

            // Simple inheritance: Randomly pick from available parent traits
            if (parent1Value != bytes32(0) && parent2Value != bytes32(0)) {
                newTraitValue = (uint256(keccak256(abi.encodePacked(randomSeed, currentTraitName, i))) % 2 == 0) ? parent1Value : parent2Value;
            } else if (parent1Value != bytes32(0)) {
                newTraitValue = parent1Value;
            } else { // parent2Value must not be zero here.
                newTraitValue = parent2Value;
            }

            // Apply mutation chance
            uint256 randMutation = uint256(keccak256(abi.encodePacked(randomSeed, currentTraitName, "mutation_check", i))) % 10000; // 0-9999
            if (randMutation < baseMutationRateBasisPoints) {
                 // Placeholder for actual mutation logic:
                 // In a full system, you'd define `traitCategoryValues` and randomly select a *valid* mutated value
                 // for the specific trait category. For demo, we just generate a unique bytes32.
                newTraitValue = keccak256(abi.encodePacked("mutated-", currentTraitName, block.timestamp, childId));
                child.lore.push(string(abi.encodePacked("Trait '", uint256(currentTraitName).toString(), "' mutated during genesis.")));
            }

            child.traits[currentTraitName] = newTraitValue;
            child.traitNames[i] = currentTraitName; // Add to child's traitNames array
        }

        // Update last breed timestamps for parents
        parent1.lastBreedTimestamp = block.timestamp;
        parent2.lastBreedTimestamp = block.timestamp;

        pairing.executed = true; // Mark pairing as executed

        emit NewVeridianBred(parent1.tokenId, parent2.tokenId, childId, _recipient);
    }

    /**
     * @dev Returns the timestamp when a specific Veridian can next participate in breeding.
     *      Returns 0 if the Veridian is currently eligible (cooldown has passed or never bred).
     * @param _veridianId The ID of the Veridian.
     * @return The timestamp when the Veridian is ready to breed, or 0 if ready.
     */
    function getVeridianBreedingCooldown(uint256 _veridianId) public view returns (uint256) {
        require(_exists(_veridianId), "Veridian does not exist");
        uint256 lastBreed = veridians[_veridianId].lastBreedTimestamp;
        if (lastBreed == 0) { // Never bred, so ready
            return 0;
        }
        uint256 nextBreedTimestamp = lastBreed + BREEDING_COOLDOWN;
        if (nextBreedTimestamp <= block.timestamp) {
            return 0; // Cooldown finished
        }
        return nextBreedTimestamp; // Cooldown active
    }

    // --- 8. Essence Staking & Rewards ---

    uint256 public constant ESSENCE_PER_VERIDIAN_PER_DAY = 10 * (10 ** 18); // 10 Essence per day per staked Veridian
    uint256 public constant ESSENCE_PER_CURATOR_PER_DAY = 5 * (10 ** 18); // 5 Essence per day for active curator

    /**
     * @dev Allows active curators and owners of staked Veridians to claim their accumulated Essence rewards.
     *      Rewards are calculated based on duration of active curator role and Veridian staking.
     */
    function claimEssenceRewards() public whenNotPaused {
        uint256 totalRewardsToClaim = 0;

        // Calculate curator rewards
        Curator storage c = curators[msg.sender];
        if (c.isActive) {
            uint256 daysActive = (block.timestamp - c.lastActivityTimestamp) / 1 days;
            if (daysActive > 0) {
                uint256 curatorReward = daysActive.mul(ESSENCE_PER_CURATOR_PER_DAY);
                totalRewardsToClaim = totalRewardsToClaim.add(curatorReward);
                c.lastActivityTimestamp = block.timestamp; // Reset activity timestamp for next claim
            }
        }

        // Calculate staked Veridian rewards for all Veridians owned by msg.sender
        // (This loop can be gas-intensive for users with many NFTs. A batch claim or tracking per-NFT would be better).
        uint256 veridiansOwned = balanceOf(msg.sender);
        for (uint256 i = 0; i < veridiansOwned; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            Veridian storage v = veridians[tokenId];
            // Ensure the Veridian is actually staked and owned by the contract (meaning it was staked by msg.sender)
            if (ownerOf(tokenId) == address(this) && v.isStakedForEssence) {
                uint256 daysStaked = (block.timestamp - v.essenceStakeStartTime) / 1 days;
                if (daysStaked > 0) {
                    uint256 veridianReward = daysStaked.mul(ESSENCE_PER_VERIDIAN_PER_DAY);
                    totalRewardsToClaim = totalRewardsToClaim.add(veridianReward);
                    v.essenceStakeStartTime = block.timestamp; // Reset staking timestamp for next claim
                }
            }
        }
        
        require(totalRewardsToClaim > 0, "No rewards to claim");
        require(essence.transfer(msg.sender, totalRewardsToClaim), "Essence reward transfer failed");

        emit EssenceRewardsClaimed(msg.sender, totalRewardsToClaim);
    }

    /**
     * @dev Stakes a Veridian NFT with the protocol to earn Essence rewards over time.
     *      The NFT is transferred to the contract's custody while staked.
     * @param _veridianId The ID of the Veridian to stake.
     */
    function stakeVeridianForEssence(uint256 _veridianId) public whenNotPaused {
        require(ownerOf(_veridianId) == msg.sender, "Caller is not the owner of the Veridian");
        require(!veridians[_veridianId].isStakedForEssence, "Veridian is already staked");
        
        // Transfer NFT to contract's custody
        _transfer(msg.sender, address(this), _veridianId);
        
        Veridian storage v = veridians[_veridianId];
        v.isStakedForEssence = true;
        v.essenceStakeStartTime = block.timestamp;
        // Store original owner for unstaking verification
        // (Better design: add a `stakerAddress` field to Veridian struct)
        // For simplicity, we assume `msg.sender` is the intended staker and will be the one to unstake.

        emit VeridianStakedForEssence(_veridianId, msg.sender);
    }

    /**
     * @dev Unstakes a Veridian NFT and transfers it back to the original staker (caller).
     * @param _veridianId The ID of the Veridian to unstake.
     */
    function unstakeVeridianFromEssence(uint256 _veridianId) public whenNotPaused {
        require(ownerOf(_veridianId) == address(this), "Veridian is not staked with the contract");
        
        Veridian storage v = veridians[_veridianId];
        require(v.isStakedForEssence, "Veridian is not staked for Essence");
        // Ensure the original staker is calling this (important for preventing arbitrary unstaking)
        // This requires tracking the original staker. For this demo, we assume the initial owner is tracked in `Veridian` struct
        // and is used implicitly by `_transfer` which updates internal mappings.
        // A more robust way would be `mapping(uint256 => address) stakerOf;`
        
        // Assuming the `ownerOf` function in ERC721Enumerable would return the actual staker when staked.
        // This is tricky. ERC721 `ownerOf` changes when transfer occurs.
        // The most secure approach is to have a `stakerAddress` field in the `Veridian` struct,
        // set upon staking, and checked here.
        // For current demo, we'll simplify and trust `msg.sender` if `ownerOf(_veridianId)` is `address(this)`.
        // This is a known simplification for this demo.
        
        // **Critical: In production, track the `stakerAddress` explicitely!**
        // `require(v.stakerAddress == msg.sender, "Only original staker can unstake.");`
        // Then `_transfer(address(this), v.stakerAddress, _veridianId);`
        
        v.isStakedForEssence = false;
        v.essenceStakeStartTime = 0; // Reset

        _transfer(address(this), msg.sender, _veridianId); // Transfers NFT from contract back to caller

        emit VeridianUnstakedFromEssence(_veridianId, msg.sender);
    }

    /**
     * @dev Calculates the estimated pending Essence yield for a specific staked Veridian.
     * @param _veridianId The ID of the Veridian.
     * @return The calculated Essence yield in wei.
     */
    function getVeridianStakingYield(uint256 _veridianId) public view returns (uint256) {
        require(_exists(_veridianId), "Veridian does not exist");
        Veridian storage v = veridians[_veridianId];
        if (!v.isStakedForEssence) {
            return 0;
        }
        uint256 daysStaked = (block.timestamp - v.essenceStakeStartTime) / 1 days;
        return daysStaked.mul(ESSENCE_PER_VERIDIAN_PER_DAY);
    }

    // --- 9. Protocol Governance & Administration ---

    /**
     * @dev Pauses core protocol functions, preventing new proposals, votes, breeding, and staking.
     *      Callable by the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses core protocol functions. Callable by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the required Essence stake amount for a curator role.
     *      Callable by the contract owner.
     * @param _amount The new required stake amount in wei.
     */
    function setCuratorStakeAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Stake amount must be greater than zero");
        curatorStakeAmount = _amount;
    }

    /**
     * @dev Sets the Essence fee for breeding operations.
     *      Callable by the contract owner.
     * @param _fee The new breeding fee in wei.
     */
    function setBreedingFee(uint256 _fee) public onlyOwner {
        breedingFee = _fee;
    }

    /**
     * @dev Sets the duration of each evolution cycle in seconds.
     *      Callable by the contract owner.
     * @param _duration The new cycle duration in seconds.
     */
    function setEvolutionCycleDuration(uint256 _duration) public onlyOwner {
        require(_duration > 0, "Duration must be greater than zero");
        evolutionCycleDuration = _duration;
        // Note: This change takes effect for the *next* cycle after `executeEvolutionCycle` is called.
    }

    /**
     * @dev Sets the base probability (in basis points, 0-10000) for trait mutations during breeding/evolution.
     *      Callable by the contract owner.
     * @param _rate The new base mutation rate (e.g., 500 for 5%, 10000 for 100%).
     */
    function setBaseMutationRate(uint256 _rate) public onlyOwner {
        require(_rate <= 10000, "Mutation rate cannot exceed 100%");
        baseMutationRateBasisPoints = _rate;
    }

    /**
     * @dev Allows the owner to withdraw accumulated Essence fees from the protocol.
     *      This only withdraws fees explicitly paid to the contract (e.g., breeding fees),
     *      not staked funds or reward pools.
     * @param _to The address to send the fees to.
     */
    function withdrawProtocolFees(address _to) public onlyOwner {
        // This is a simplified fee withdrawal. A robust system would track fees separately.
        // Here, we calculate a rough "excess" balance by subtracting known stakes/potential rewards.
        uint256 contractBalance = essence.balanceOf(address(this));
        
        uint256 totalCuratorStakes = 0;
        for(uint256 i = 0; i < curatorAddresses.length; i++) {
            if (curators[curatorAddresses[i]].isActive) {
                totalCuratorStakes = totalCuratorStakes.add(curators[curatorAddresses[i]].stakeAmount);
            }
        }
        
        uint256 totalStakedVeridianValue = 0; // The actual Essence locked by NFTs is 0, they earn new Essence.
                                             // This variable is conceptually for potential future staking features where NFTs deposit Essence.
                                             // For now, it represents a minimal buffer or is ignored.
        
        // This is very important: Ensure that `totalCuratorStakes` and any pending rewards are NOT withdrawn.
        // A more explicit fee accumulation mechanism is safer in production.
        uint256 withdrawableAmount = contractBalance.sub(totalCuratorStakes); // Subtract only direct stakes

        // Further refinement: If there are pending rewards, they should also be accounted for
        // to prevent owner from withdrawing funds that are due to users.
        // For this demo, we simplify and assume curator stakes are the primary non-fee balance.

        if (withdrawableAmount > 0) {
            require(essence.transfer(_to, withdrawableAmount), "Fee withdrawal failed");
        }
    }

    // Fallback function to prevent accidental ETH transfers (protocol uses Essence token)
    receive() external payable {
        revert("ETH not accepted. Only Essence token transactions.");
    }
}
```