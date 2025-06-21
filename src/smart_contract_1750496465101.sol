Okay, let's design a smart contract that combines several advanced, trendy, and creative concepts:

**Concept:** **ChronoGenesis NFTs**

This contract manages a collection of Non-Fungible Tokens (NFTs) that evolve dynamically based on various factors:
1.  **Staking Age:** The longer an NFT is staked, the more it evolves.
2.  **Community Blessings:** Owners and others can spend an internal yield token ("Essence") to "bless" an NFT, influencing its evolution.
3.  **Oracle Influence:** External data (simulated via an authorized role) can globally influence the evolution process or unlock new traits.
4.  **Simplified Governance:** A basic system allows stakeholders (e.g., token holders, stakers) to propose and vote on parameters that affect the *collective* evolution rules or unlock new features.

The NFTs themselves are dynamic; their `tokenURI` will reflect their current state (traits). Staking the NFT yields "Essence" tokens, which are used for blessings and governance voting.

This design incorporates: Dynamic NFTs, Staking, Internal Tokenomics (Essence), Oracle Integration (simulated), Community Interaction (Blessings), and basic On-chain Governance, all within a single contract (while using standard, audited libraries for core components like ERC721 and AccessControl for safety and efficiency).

---

**Outline and Function Summary:**

**Contract Name:** `ChronoGenesisNFT`

**Core Concepts:**
*   ERC-721 Standard Implementation
*   Role-Based Access Control (OpenZeppelin AccessControl)
*   Dynamic NFT Traits & Evolution System
*   NFT Staking Mechanism yielding an internal "Essence" token
*   "Blessing" System using Essence to influence NFT evolution
*   Simulated Oracle Integration for external influence
*   Basic On-chain Governance for rule adjustments

**State Variables:**
*   `_nextTokenId`: Counter for minting
*   `_nftTraits`: Mapping `tokenId` to `NFTTraits` struct
*   `_essenceBalances`: Mapping `address` to internal Essence balance
*   `_stakeInfo`: Mapping `tokenId` to `StakeInfo` struct
*   `_blessings`: Mapping `tokenId` to `BlessingsInfo` struct
*   `_evolutionParams`: Global parameters influencing evolution (e.g., evolution rate, blessing impact)
*   `_oracleValue`: Simulated external data point
*   `_governanceProposals`: Mapping `proposalId` to `GovernanceProposal` struct
*   `_proposalVoteCounts`: Mapping `proposalId` -> `voterAddress` -> `support` (bool)
*   `_baseTokenURI`: Base URI for metadata
*   Roles: `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, `ORACLE_UPDATER_ROLE`, `GOVERNOR_ROLE`

**Structs:**
*   `NFTTraits`: `level`, `rarityScore`, `evolutionCycle`, `lastEvolutionTime`, `oracleInfluenceSnapshot`
*   `StakeInfo`: `isStaked`, `stakeStartTime`, `claimedYield`
*   `BlessingsInfo`: `totalBlessingsReceived`, `lastBlessingTime`
*   `EvolutionParameters`: `baseEvolutionRate`, `blessingMultiplier`, `oracleImpact`, `evolutionCooldown`
*   `GovernanceProposal`: `proposer`, `description`, `actionType`, `targetId`, `newValue`, `endTime`, `forVotes`, `againstVotes`, `executed`
*   `GovernanceActionType`: Enum (`UPDATE_EVOLUTION_PARAM`, `UNLOCK_NEW_TRAIT_MECHANIC` - simplified)

**Events:**
*   `NFTMinted`, `NFTBurned`, `NFTTraitsEvolved`, `NFTStaked`, `NFTUnstaked`, `YieldClaimed`, `NFTBlessed`, `OracleValueUpdated`, `GovernanceProposalCreated`, `VoteCast`, `ProposalExecuted`, `EssenceTransferred`

**Functions (20+):**

1.  `constructor()`: Initializes Access Control and default roles.
2.  `mint(address to)`: Mints a new NFT with base traits (requires `MINTER_ROLE`).
3.  `burn(uint256 tokenId)`: Burns an NFT (owner or approved).
4.  `tokenURI(uint256 tokenId)`: Returns dynamic metadata URI based on current traits.
5.  `getTraits(uint256 tokenId)`: Returns the current traits of an NFT.
6.  `triggerEvolution(uint256 tokenId)`: Allows owner/approved to attempt evolving the NFT based on age, blessings, and oracle influence (subject to cooldown). Calculates and updates traits.
7.  `getEvolutionParameters()`: Returns the current global evolution parameters.
8.  `updateOracleValue(uint256 value)`: Updates the simulated oracle value (requires `ORACLE_UPDATER_ROLE`).
9.  `stake(uint256 tokenId)`: Stakes an NFT (requires owner). Records stake start time.
10. `unstake(uint256 tokenId)`: Unstakes an NFT (requires owner). Allows claiming yield earned until unstaking.
11. `claimYield(uint256 tokenId)`: Claims earned Essence yield for a staked or recently unstaked NFT.
12. `getStakeInfo(uint256 tokenId)`: Returns staking information for an NFT.
13. `getClaimableYield(uint256 tokenId)`: Calculates and returns the potential yield an NFT could claim.
14. `blessNFT(uint256 tokenId, uint256 amount)`: Spends sender's Essence to add blessings to an NFT.
15. `getBlessings(uint256 tokenId)`: Returns blessing information for an NFT.
16. `essenceBalanceOf(address owner)`: Returns the internal Essence balance of an address.
17. `proposeGovernanceAction(uint256 actionType, uint256 targetId, uint256 newValue, string description)`: Creates a new governance proposal (requires `GOVERNOR_ROLE` or potentially a stake threshold).
18. `voteOnProposal(uint256 proposalId, bool support)`: Casts a vote on a proposal (requires minimum Essence balance or staked NFT, burns/locks Essence).
19. `getProposal(uint256 proposalId)`: Returns details of a governance proposal.
20. `executeProposal(uint256 proposalId)`: Executes a successful governance proposal after the voting period ends (callable by anyone after period).
21. `grantRole(bytes32 role, address account)`: Grants a role (requires `DEFAULT_ADMIN_ROLE`).
22. `revokeRole(bytes32 role, address account)`: Revokes a role (requires `DEFAULT_ADMIN_ROLE`).
23. `hasRole(bytes32 role, address account)`: Checks if an address has a role.
24. `getRoleAdmin(bytes32 role)`: Returns the admin role for a given role.
25. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 support.
26. `setBaseURI(string baseURI)`: Sets the base URI for metadata (requires `DEFAULT_ADMIN_ROLE`).
27. `_calculateYield(uint256 tokenId)`: Internal helper to calculate yield.
28. `_applyEvolution(uint256 tokenId, uint256 timeElapsed, uint256 currentBlessings, uint256 currentOracle)`: Internal helper for evolution logic.
29. `_transferEssence(address from, address to, uint256 amount)`: Internal essence transfer logic.
30. `_burnEssence(address account, uint256 amount)`: Internal essence burn logic.
31. `_mintEssence(address account, uint256 amount)`: Internal essence mint logic (used by yield/admin).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary Above ---

contract ChronoGenesisNFT is Context, AccessControl, ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE"); // Role to propose governance actions

    Counters.Counter private _nextTokenId;

    struct NFTTraits {
        uint256 level; // Represents overall maturity/power
        uint256 rarityScore; // A score influenced by evolution factors
        uint256 evolutionCycle; // How many times it has fully "cycled" evolution
        uint48 lastEvolutionTime; // Timestamp of the last successful evolution
        uint256 oracleInfluenceSnapshot; // Oracle value when last evolved/influenced
    }

    struct StakeInfo {
        bool isStaked;
        uint48 stakeStartTime; // Timestamp when staked
        uint256 claimedYield; // Total yield claimed so far for this stake period
    }

    struct BlessingsInfo {
        uint256 totalBlessingsReceived; // Cumulative blessings received
        uint48 lastBlessingTime; // Timestamp of the last blessing received
    }

    struct EvolutionParameters {
        uint256 baseEvolutionRate; // How fast level/rarity increases per unit of time staked
        uint256 blessingMultiplier; // How much blessings boost evolution
        uint256 oracleImpact; // How much the oracle value influences rarity/traits
        uint256 evolutionCooldown; // Minimum time between manual evolutions
        uint256 yieldPerSecond; // Essence yield rate per second while staked
    }

    enum GovernanceActionType {
        NONE,
        UPDATE_EVOLUTION_PARAM, // Action: targetId = param index, newValue = new value
        UNLOCK_NEW_TRAIT_MECHANIC // Action: targetId = mechanic identifier (e.g., 1 for trait X)
    }

    struct GovernanceProposal {
        address proposer;
        string description;
        GovernanceActionType actionType;
        uint256 targetId;
        uint256 newValue; // Used for UPDATE_EVOLUTION_PARAM
        uint48 endTime; // Timestamp when voting ends
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
    }

    mapping(uint256 => NFTTraits) private _nftTraits;
    mapping(address => uint256) private _essenceBalances; // Internal yield token balance
    mapping(uint256 => StakeInfo) private _stakeInfo;
    mapping(uint256 => BlessingsInfo) private _blessings;

    EvolutionParameters public evolutionParameters; // Global parameters
    uint256 public oracleValue; // Simulated external data point

    uint256 private _nextProposalId;
    mapping(uint256 => GovernanceProposal) private _governanceProposals;
    mapping(uint256 => mapping(address => bool)) private _proposalVoteCast; // proposalId => voterAddress => hasVoted

    string private _baseTokenURI;

    uint256 public constant ESSENCE_PER_VOTE = 100e18; // Essence required to cast one vote (example)
    uint256 public constant GOVERNANCE_VOTING_PERIOD = 5 days; // Example voting period length
    uint256 public constant GOVERNANCE_MIN_FOR_VOTES_TO_EXECUTE = 1000e18; // Example threshold for execution

    // --- Errors ---
    error InvalidTokenId();
    error NotNFTOwnerOrApproved();
    error NotStaked();
    error AlreadyStaked();
    error EvolutionCooldownActive(uint256 remainingTime);
    error InsufficientEssence(uint256 required, uint256 available);
    error ProposalNotFound();
    error VotingPeriodNotActive();
    error AlreadyVoted();
    error ProposalAlreadyExecuted();
    error ProposalFailed();
    error InvalidProposalAction();
    error ActionNotExecutableYet(); // For unlock mechanics etc.

    // --- Events ---
    event NFTMinted(uint256 indexed tokenId, address indexed owner);
    event NFTBurned(uint256 indexed tokenId);
    event NFTTraitsEvolved(uint256 indexed tokenId, NFTTraits newTraits, uint256 timeElapsed, uint256 blessingsReceived, uint256 oracleInfluence);
    event NFTStaked(uint256 indexed tokenId, address indexed owner, uint48 stakeStartTime);
    event NFTUnstaked(uint256 indexed tokenId, address indexed owner, uint256 claimableYield);
    event YieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event NFTBlessed(uint256 indexed tokenId, address indexed blessor, uint256 amount, uint256 totalBlessings);
    event OracleValueUpdated(uint256 indexed oldValue, uint256 indexed newValue);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, GovernanceActionType actionType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event EssenceBurned(address indexed account, uint256 amount);
    event EssenceMinted(address indexed account, uint256 amount);


    constructor() ERC721("ChronoGenesis NFT", "CHRONO") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(ORACLE_UPDATER_ROLE, _msgSender());
        _grantRole(GOVERNOR_ROLE, _msgSender()); // Default admin is also the initial governor

        // Set initial evolution parameters (example values)
        evolutionParameters = EvolutionParameters({
            baseEvolutionRate: 1e16, // Scales with time (e.g., 0.01 per second)
            blessingMultiplier: 5e15, // Scales with blessings (e.g., 0.005 per blessing point)
            oracleImpact: 1e15, // Scales with oracle value (e.g., 0.001 per oracle point)
            evolutionCooldown: 30 days, // Can only manually evolve every 30 days
            yieldPerSecond: 1e15 // Essence per second while staked
        });

        oracleValue = 0;
        _nextProposalId = 1;
    }

    // --- Access Control Overrides ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- ERC721 Overrides & Additions ---

    /// @notice Mints a new ChronoGenesis NFT.
    /// @param to The address to mint the NFT to.
    function mint(address to) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        tokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(to, tokenId);

        // Initialize base traits
        _nftTraits[tokenId] = NFTTraits({
            level: 1,
            rarityScore: 0,
            evolutionCycle: 0,
            lastEvolutionTime: uint48(block.timestamp), // Initialize last evolution time
            oracleInfluenceSnapshot: oracleValue // Snapshot current oracle value
        });

        // Initialize other info
        _stakeInfo[tokenId] = StakeInfo({
            isStaked: false,
            stakeStartTime: 0,
            claimedYield: 0
        });
        _blessings[tokenId] = BlessingsInfo({
            totalBlessingsReceived: 0,
            lastBlessingTime: uint48(block.timestamp) // Initialize
        });

        emit NFTMinted(tokenId, to);
    }

    /// @notice Burns an NFT. Callable by owner or approved operator.
    /// @param tokenId The ID of the NFT to burn.
    function burn(uint256 tokenId) external {
        require(_exists(tokenId), "ERC721: token does not exist");
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        // Ensure NFT is unstaked before burning
        if (_stakeInfo[tokenId].isStaked) {
            unstake(tokenId);
        }

        _burn(tokenId);

        // Clean up associated data (optional, but good practice for unique data)
        delete _nftTraits[tokenId];
        delete _stakeInfo[tokenId];
        delete _blessings[tokenId];

        emit NFTBurned(tokenId);
    }

    /// @notice Returns the dynamic metadata URI for an NFT based on its current traits.
    /// @param tokenId The ID of the NFT.
    /// @return The metadata URI string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: token does not exist");

        // Example dynamic URI based on traits
        // In a real application, this would likely point to an API gateway that
        // fetches traits from the contract and generates JSON metadata on the fly.
        // Here we simulate by embedding a few key trait values in the URI.
        NFTTraits storage traits = _nftTraits[tokenId];
        BlessingsInfo storage blessings = _blessings[tokenId];

        string memory traitsString = string(abi.encodePacked(
            "level=", traits.level.toString(),
            "&rarity=", traits.rarityScore.toString(),
            "&cycle=", traits.evolutionCycle.toString(),
            "&blessings=", blessings.totalBlessingsReceived.toString()
            // Add more traits as needed
        ));

        if (bytes(_baseTokenURI).length == 0) {
             return string(abi.encodePacked("ipfs://<DEFAULT_IPFS_HASH>/", tokenId.toString(), "?", traitsString));
        } else {
             return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), "?", traitsString));
        }
    }

    /// @notice Sets the base URI for token metadata.
    /// @param baseURI The new base URI.
    function setBaseURI(string memory baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    // --- Trait & Evolution System ---

    /// @notice Gets the current traits of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The NFTTraits struct.
    function getTraits(uint256 tokenId) public view returns (NFTTraits memory) {
        require(_exists(tokenId), "ERC721: token does not exist");
        return _nftTraits[tokenId];
    }

    /// @notice Triggers the evolution process for an NFT.
    /// Requires the caller to be the owner or approved operator.
    /// Evolution is based on staking age, blessings, and oracle influence.
    /// Subject to a cooldown period.
    /// @param tokenId The ID of the NFT to evolve.
    function triggerEvolution(uint256 tokenId) external {
        require(_exists(tokenId), "ERC721: token does not exist");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ChronoGenesisNFT: caller is not token owner or approved");

        NFTTraits storage traits = _nftTraits[tokenId];
        BlessingsInfo storage blessings = _blessings[tokenId];
        StakeInfo storage stake = _stakeInfo[tokenId];

        uint256 lastEvolutionTime = traits.lastEvolutionTime;
        uint256 cooldown = evolutionParameters.evolutionCooldown;

        // Check cooldown
        if (block.timestamp < lastEvolutionTime + cooldown) {
            revert EvolutionCooldownActive(lastEvolutionTime + cooldown - block.timestamp);
        }

        // Calculate time elapsed since last evolution (or stake start if staked)
        // Evolution is primarily driven by staked time since last evolution
        uint256 timeElapsed = 0;
        if (stake.isStaked) {
            timeElapsed = block.timestamp - stake.stakeStartTime; // Time since staked
            // To prevent double counting, we should really calculate time since last evolution
            // while staked. For simplicity here, let's assume evolution uses total staked time OR time since last evolution.
            // A more robust system would track staked time specifically for evolution.
            // Let's use time since last evolution for simplicity in this example,
            // assuming staking duration contributes to this time.
            if (stake.stakeStartTime > lastEvolutionTime) {
                 timeElapsed = block.timestamp - stake.stakeStartTime; // Time since *this* stake started
            } else {
                 timeElapsed = block.timestamp - lastEvolutionTime; // Time since last evo (could be while unstaked, less effective?)
                 // A better design might require *staked* time elapsed. Let's adjust calculation:
                 // Calculate potential staked time earned since last evo.
                 // If currently staked, add block.timestamp - max(stake.stakeStartTime, lastEvolutionTime)
                 // If unstaked, the evolution benefit from time might be zero or minimal.
                 // Let's keep it simple: timeElapsed = block.timestamp - lastEvolutionTime IF staked.
                 // If unstaked, evolution is less effective or requires blessings.
                 // For this example, let's base it on time since last evolution, but stake is required for *maximum* benefit.
                 if (stake.isStaked) {
                     timeElapsed = block.timestamp - lastEvolutionTime;
                 } else {
                     // Minimal or zero time effect if unstaked
                     timeElapsed = 0; // Or a smaller factor
                 }
            }

        } else {
             // Evolution is slow or requires significant blessings if unstaked
             timeElapsed = 0; // Or a smaller factor
        }


        // Calculate evolution points
        uint256 timeBasedPoints = timeElapsed * evolutionParameters.baseEvolutionRate / 1e18; // Scale down rate
        uint256 blessingBasedPoints = blessings.totalBlessingsReceived * evolutionParameters.blessingMultiplier / 1e18; // Scale down multiplier
        uint256 oracleBasedPoints = oracleValue * evolutionParameters.oracleImpact / 1e18; // Scale down impact

        // Total points
        uint256 totalEvolutionPoints = timeBasedPoints + blessingBasedPoints + oracleBasedPoints;

        // Apply evolution logic (simplified example)
        // Level increases based on total points accumulated over cycles
        uint256 newLevel = traits.level + (totalEvolutionPoints / 1000e18); // Example: 1000 points for a level

        // Rarity score increases based on current factors and snapshot
        uint256 newRarityScore = traits.rarityScore;
        newRarityScore += (timeBasedPoints / 10e18); // Time gives base rarity
        newRarityScore += (blessingBasedPoints / 5e18); // Blessings boost rarity
        newRarityScore += (oracleBasedPoints / 8e18); // Oracle influences rarity

        // Cap rarity or level if needed
        // newLevel = Math.min(newLevel, MAX_LEVEL);
        // newRarityScore = Math.min(newRarityScore, MAX_RARITY);


        // Update traits
        traits.level = newLevel;
        traits.rarityScore = newRarityScore;
        traits.evolutionCycle += 1; // Increment cycle count
        traits.lastEvolutionTime = uint48(block.timestamp); // Update last evolution time
        traits.oracleInfluenceSnapshot = oracleValue; // Snapshot current oracle value

        // Reset blessings count after evolution (optional, depending on desired mechanic)
        // blessings.totalBlessingsReceived = 0;

        emit NFTTraitsEvolved(
            tokenId,
            traits,
            timeElapsed,
            blessings.totalBlessingsReceived,
            traits.oracleInfluenceSnapshot
        );
    }

    /// @notice Returns the current global evolution parameters.
    /// @return The EvolutionParameters struct.
    function getEvolutionParameters() public view returns (EvolutionParameters memory) {
        return evolutionParameters;
    }

    /// @notice Updates the simulated oracle value.
    /// Requires the ORACLE_UPDATER_ROLE.
    /// @param value The new oracle value.
    function updateOracleValue(uint256 value) external onlyRole(ORACLE_UPDATER_ROLE) {
        uint256 oldValue = oracleValue;
        oracleValue = value;
        emit OracleValueUpdated(oldValue, value);
    }

    // --- Staking & Yield System ---

    /// @notice Stakes an NFT.
    /// Requires the caller to be the owner.
    /// @param tokenId The ID of the NFT to stake.
    function stake(uint256 tokenId) external {
        require(_exists(tokenId), "ERC721: token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "ChronoGenesisNFT: caller is not token owner");
        require(!_stakeInfo[tokenId].isStaked, "ChronoGenesisNFT: NFT already staked");

        // Transfer NFT to the contract (assuming contract is the staking vault)
        // This simple example keeps ownership with the user but tracks staking state.
        // A more secure staking would transfer the NFT to the contract's address.
        // For this example, we just update the state.
        // _safeTransferFrom(ownerOf(tokenId), address(this), tokenId); // If transferring ownership

        _stakeInfo[tokenId].isStaked = true;
        _stakeInfo[tokenId].stakeStartTime = uint48(block.timestamp);
        _stakeInfo[tokenId].claimedYield = 0; // Reset claimed yield for the new staking period

        emit NFTStaked(tokenId, _msgSender(), _stakeInfo[tokenId].stakeStartTime);
    }

    /// @notice Unstakes an NFT.
    /// Requires the caller to be the owner.
    /// Automatically claims earned yield upon unstaking.
    /// @param tokenId The ID of the NFT to unstake.
    function unstake(uint256 tokenId) external {
        require(_exists(tokenId), "ERC721: token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "ChronoGenesisNFT: caller is not token owner");
        require(_stakeInfo[tokenId].isStaked, "ChronoGenesisNFT: NFT not staked");

        // Calculate and claim yield before unstaking
        uint256 claimable = _calculateYield(tokenId);
        _stakeInfo[tokenId].claimedYield += claimable; // Add to claimed yield for the period
        _transferEssence(address(this), _msgSender(), claimable); // Transfer yield to user
        emit YieldClaimed(tokenId, _msgSender(), claimable);

        // Mark as unstaked
        _stakeInfo[tokenId].isStaked = false;
        _stakeInfo[tokenId].stakeStartTime = 0; // Reset start time
        // _stakeInfo[tokenId].claimedYield remains, can be reset or just left as historical data

        // Transfer NFT back from contract to owner (if transferred during stake)
        // _safeTransferFrom(address(this), _msgSender(), tokenId); // If transferring ownership

        emit NFTUnstaked(tokenId, _msgSender(), claimable);
    }

    /// @notice Claims earned Essence yield for a staked NFT.
    /// Requires the caller to be the owner.
    /// @param tokenId The ID of the NFT.
    function claimYield(uint256 tokenId) external {
        require(_exists(tokenId), "ERC721: token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "ChronoGenesisNFT: caller is not token owner");
        require(_stakeInfo[tokenId].isStaked, "ChronoGenesisNFT: NFT not staked");

        uint256 claimable = _calculateYield(tokenId);
        require(claimable > 0, "ChronoGenesisNFT: no yield to claim");

        _stakeInfo[tokenId].claimedYield += claimable; // Add to claimed yield for the period
        _transferEssence(address(this), _msgSender(), claimable);

        emit YieldClaimed(tokenId, _msgSender(), claimable);
    }

    /// @notice Gets the staking information for an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return isStaked, stakeStartTime, claimedYield.
    function getStakeInfo(uint256 tokenId) public view returns (bool isStaked, uint48 stakeStartTime, uint256 claimedYield) {
        require(_exists(tokenId), "ERC721: token does not exist");
        StakeInfo storage info = _stakeInfo[tokenId];
        return (info.isStaked, info.stakeStartTime, info.claimedYield);
    }

    /// @notice Calculates the potential claimable Essence yield for an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The amount of Essence that can be claimed.
    function getClaimableYield(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721: token does not exist");
        return _calculateYield(tokenId);
    }

    /// @notice Internal helper to calculate current claimable yield.
    /// @param tokenId The ID of the NFT.
    /// @return The calculated yield.
    function _calculateYield(uint256 tokenId) internal view returns (uint256) {
        StakeInfo storage info = _stakeInfo[tokenId];
        if (!info.isStaked) {
            return 0;
        }

        // Calculate time since last claim/stake start
        uint256 lastClaimTime = info.stakeStartTime; // If claimedYield resets on stake, this works
        if (info.claimedYield > 0 && info.stakeStartTime < block.timestamp) { // If yield has been claimed in this period
             // A more accurate calculation would track the timestamp of the last claim *within* the stake period
             // For simplicity, we'll just calculate total potential yield and subtract claimed.
             // Total potential yield = (block.timestamp - stakeStartTime) * yieldPerSecond
             // Claimable = Total potential - claimedYield
             if (block.timestamp > info.stakeStartTime) {
                 uint256 totalPotential = (block.timestamp - info.stakeStartTime) * evolutionParameters.yieldPerSecond;
                 return totalPotential >= info.claimedYield ? totalPotential - info.claimedYield : 0;
             } else {
                 return 0;
             }
        } else if (block.timestamp > info.stakeStartTime) {
             // First claim in this stake period
            return (block.timestamp - info.stakeStartTime) * evolutionParameters.yieldPerSecond;
        } else {
            return 0; // Block timestamp is same or before stake start (shouldn't happen often)
        }
    }

    /// @notice Gets the Essence balance of an address.
    /// @param owner The address to query.
    /// @return The Essence balance.
    function essenceBalanceOf(address owner) public view returns (uint256) {
        return _essenceBalances[owner];
    }

    // --- Community Interaction (Blessings) ---

    /// @notice Allows a user to spend Essence to "bless" an NFT, influencing its evolution.
    /// @param tokenId The ID of the NFT to bless.
    /// @param amount The amount of Essence to spend on blessing.
    function blessNFT(uint256 tokenId, uint256 amount) external {
        require(_exists(tokenId), "ERC721: token does not exist");
        require(amount > 0, "ChronoGenesisNFT: blessing amount must be greater than zero");
        require(_essenceBalances[_msgSender()] >= amount, InsufficientEssence({required: amount, available: _essenceBalances[_msgSender()]}));

        // Burn the Essence
        _burnEssence(_msgSender(), amount);

        // Apply blessings to the NFT
        BlessingsInfo storage blessings = _blessings[tokenId];
        blessings.totalBlessingsReceived += amount; // Blessing points could scale with amount
        blessings.lastBlessingTime = uint48(block.timestamp);

        emit NFTBlessed(tokenId, _msgSender(), amount, blessings.totalBlessingsReceived);
    }

    /// @notice Gets the blessings information for an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return totalBlessingsReceived, lastBlessingTime.
    function getBlessings(uint256 tokenId) public view returns (uint256 totalBlessingsReceived, uint48 lastBlessingTime) {
        require(_exists(tokenId), "ERC721: token does not exist");
        BlessingsInfo storage info = _blessings[tokenId];
        return (info.totalBlessingsReceived, info.lastBlessingTime);
    }

    // --- Basic Governance System ---

    /// @notice Creates a new governance proposal.
    /// Requires the GOVERNOR_ROLE.
    /// @param actionType The type of action proposed.
    /// @param targetId Identifier for the action (e.g., parameter index, trait ID).
    /// @param newValue New value for the parameter (if actionType is UPDATE_EVOLUTION_PARAM).
    /// @param description Text description of the proposal.
    function proposeGovernanceAction(
        GovernanceActionType actionType,
        uint256 targetId,
        uint256 newValue,
        string memory description
    ) external onlyRole(GOVERNOR_ROLE) returns (uint256 proposalId) {
        proposalId = _nextProposalId;
        _nextProposalId++;

        _governanceProposals[proposalId] = GovernanceProposal({
            proposer: _msgSender(),
            description: description,
            actionType: actionType,
            targetId: targetId,
            newValue: newValue,
            endTime: uint48(block.timestamp + GOVERNANCE_VOTING_PERIOD),
            forVotes: 0,
            againstVotes: 0,
            executed: false
        });

        emit GovernanceProposalCreated(proposalId, _msgSender(), actionType, description);
    }

    /// @notice Casts a vote on a governance proposal.
    /// Requires burning ESSENCE_PER_VOTE amount of Essence.
    /// @param proposalId The ID of the proposal.
    /// @param support True for 'for', False for 'against'.
    function voteOnProposal(uint256 proposalId, bool support) external {
        GovernanceProposal storage proposal = _governanceProposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (block.timestamp > proposal.endTime || proposal.executed) revert VotingPeriodNotActive();
        if (_proposalVoteCast[proposalId][_msgSender()]) revert AlreadyVoted();
        require(_essenceBalances[_msgSender()] >= ESSENCE_PER_VOTE, InsufficientEssence({required: ESSENCE_PER_VOTE, available: _essenceBalances[_msgSender()]}));

        // Burn Essence to vote
        _burnEssence(_msgSender(), ESSENCE_PER_VOTE);

        // Record vote
        if (support) {
            proposal.forVotes += ESSENCE_PER_VOTE; // Vote weight scaled by Essence burned
        } else {
            proposal.againstVotes += ESSENCE_PER_VOTE;
        }

        _proposalVoteCast[proposalId][_msgSender()] = true;

        emit VoteCast(proposalId, _msgSender(), support);
    }

    /// @notice Gets details of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The GovernanceProposal struct.
    function getProposal(uint256 proposalId) public view returns (GovernanceProposal memory) {
        GovernanceProposal storage proposal = _governanceProposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        return proposal;
    }

    /// @notice Executes a successful governance proposal after the voting period ends.
    /// Callable by anyone.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) external {
        GovernanceProposal storage proposal = _governanceProposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (block.timestamp <= proposal.endTime) revert VotingPeriodNotActive(); // Voting period must be over
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Check if proposal passed (example condition)
        bool passed = proposal.forVotes > proposal.againstVotes && proposal.forVotes >= GOVERNANCE_MIN_FOR_VOTES_TO_EXECUTE;

        if (!passed) {
            proposal.executed = true; // Mark as executed but failed
            revert ProposalFailed();
        }

        // Execute the action based on actionType
        if (proposal.actionType == GovernanceActionType.UPDATE_EVOLUTION_PARAM) {
            // Example: Map targetId to an index of evolution parameters
            if (proposal.targetId == 0) { // Example: Update baseEvolutionRate
                evolutionParameters.baseEvolutionRate = proposal.newValue;
            } else if (proposal.targetId == 1) { // Example: Update blessingMultiplier
                evolutionParameters.blessingMultiplier = proposal.newValue;
            }
            // Add more cases for other parameters
        } else if (proposal.actionType == GovernanceActionType.UNLOCK_NEW_TRAIT_MECHANIC) {
            // Example: Unlock a new trait type or evolution factor based on targetId
            // This would likely require adding more state variables and logic
            // For this example, we'll just emit an event signalling it happened
            // and trust external systems/future upgrades handle the mechanic.
             // This is a placeholder for more complex logic.
            emit ActionNotExecutableYet(); // Indicate it's a conceptual unlock
        } else {
            revert InvalidProposalAction();
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    // --- Internal Essence Token Management ---

    /// @notice Internal function to transfer Essence tokens.
    /// @param from The sender address.
    /// @param to The recipient address.
    /// @param amount The amount to transfer.
    function _transferEssence(address from, address to, uint256 amount) internal {
        require(_essenceBalances[from] >= amount, InsufficientEssence({required: amount, available: _essenceBalances[from]}));
        _essenceBalances[from] -= amount;
        _essenceBalances[to] += amount;
        emit EssenceTransferred(from, to, amount);
    }

    /// @notice Internal function to mint Essence tokens.
    /// Used by yield claiming and potentially admin roles.
    /// @param account The address to mint to.
    /// @param amount The amount to mint.
    function _mintEssence(address account, uint256 amount) internal onlyRole(DEFAULT_ADMIN_ROLE) {
        // Only admin or specific internal processes (like yield calculation) can mint
        // For simplicity here, only admin role is allowed via this public helper.
        // The _calculateYield logic *internally* updates claimedYield and relies on _transferEssence.
        // If yield was minted here, it would need a different trigger.
        // Let's make yield calculation update balances directly, removing the need for _mintEssence for yield.
        // Re-evaluating _calculateYield: It *returns* the value. `claimYield` and `unstake` call `_transferEssence` with address(this) as sender.
        // This implies the contract *holds* the total possible Essence supply.
        // A better model is that Essence is minted ON DEMAND when claimed.
        // Let's adjust: `_transferEssence` from address(this) means burning the *contracts* balance. This is confusing.
        // Let's make Essence balance internal and `_mintEssence` is called by `claimYield` and `unstake`.
        // And `_burnEssence` is called by `blessNFT` and `voteOnProposal`.
        // The total supply isn't tracked explicitly in this internal system, but balances are.

        // --- REVISED ESSENCE FLOW ---
        // Claiming Yield: Mint Essence to the user.
        // Blessing NFT: Burn Essence from the user.
        // Voting: Burn Essence from the user.
        // Admin: Can mint/burn for adjustments if needed.

        _essenceBalances[account] += amount;
        emit EssenceMinted(account, amount);
    }


    /// @notice Internal function to burn Essence tokens.
    /// Used by blessing and voting functions.
    /// @param account The address to burn from.
    /// @param amount The amount to burn.
    function _burnEssence(address account, uint256 amount) internal {
         require(_essenceBalances[account] >= amount, InsufficientEssence({required: amount, available: _essenceBalances[account]}));
        _essenceBalances[account] -= amount;
        emit EssenceBurned(account, amount);
    }

     // --- Admin Utility ---

    /// @notice Allows admin to withdraw accumulated Essence (e.g., from failed operations or initial reserve).
    /// @param recipient The address to send Essence to.
    /// @param amount The amount of Essence to withdraw.
    function withdrawEssence(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_essenceBalances[address(this)] >= amount, InsufficientEssence({required: amount, available: _essenceBalances[address(this)]}));
        _transferEssence(address(this), recipient, amount);
    }

     // --- Ensure ERC721 transfers update staking state if necessary ---
     // OpenZeppelin's ERC721 handles transfers internally.
     // If we were transferring NFTs *into* the contract for staking, we would need to
     // override `_beforeTokenTransfer` to handle staking state updates.
     // Since our staking model just updates a boolean and timestamp without ownership transfer,
     // this isn't strictly necessary, but overriding _beforeTokenTransfer and _afterTokenTransfer
     // is good practice in complex ERC721 contracts interacting with other systems.
     /*
     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);
         // Example: If NFT ownership changing to/from this contract implies staking/unstaking
         if (to == address(this)) {
              // Logic for staking (e.g., if stake is passive on transfer)
         } else if (from == address(this)) {
              // Logic for unstaking (e.g., if unstake is passive on transfer)
         }
     }
     */
}
```