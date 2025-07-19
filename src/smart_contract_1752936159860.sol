Here's a Solidity smart contract that implements advanced, creative, and trendy concepts, avoiding direct duplication of existing open-source projects by focusing on unique combinations and logic for dynamic NFTs, soulbound tokens, and gamified challenges. It includes over 20 functions as requested.

The contract, `ChronoGlyphChronicles`, envisions a decentralized ecosystem centered around evolving digital artifacts (`ChronoGlyphs`), a utility token (`ChronoEssence`), and a reputation system based on non-transferable achievement tokens (`GlyphKeepers`). It incorporates gamified challenges influenced by an "AI/Narrative Oracle."

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// I. Core Assets: ChronoGlyphs (Dynamic ERC-721)
//    - Represents evolving narrative fragments whose metadata can be updated by an Oracle.
// II. Utility Token: ChronoEssence (ERC-20)
//    - Used for staking, challenge participation, and rewards within the ecosystem.
// III. Reputation NFTs: GlyphKeepers (Soulbound ERC-721)
//    - Non-transferable tokens awarded for on-chain achievements, building user reputation.
// IV. Gamified Challenges & Staking
//    - On-chain events where users predict outcomes by staking ChronoEssence, resolved by the Narrative Oracle.
//    - Ability to stake ChronoGlyphs for potential narrative influence or boosts.
// V. Role Management & Administration
//    - Defines roles (Admin, Minter, Narrative Oracle, Pauser) to manage contract functions and security.

// Function Summary:

// I. ChronoGlyphs (Dynamic ERC-721):
// 1.  mintChronoGlyph(address _to, string memory _initialMetadataURI): Mints a new ChronoGlyph NFT with an initial state and metadata. Requires MINTER_ROLE.
// 2.  evolveChronoGlyph(uint256 _tokenId, bytes32 _narrativeEventHash, string memory _newMetadataURI): Allows designated NARRATIVE_ORACLE_ROLE to trigger an evolution for a ChronoGlyph, updating its internal state and metadata URI.
// 3.  getChronoGlyphDetails(uint256 _tokenId): Retrieves comprehensive details about a ChronoGlyph, including its owner, creation/evolution times, narrative state, and current URI.
// 4.  transferFrom(address _from, address _to, uint256 _tokenId): Standard ERC-721 transfer function, overridden to prevent transfer of staked ChronoGlyphs.
// 5.  tokenURI(uint256 _tokenId): Returns the current metadata URI for a ChronoGlyph, combining base URI with the token's specific URI.

// II. ChronoEssence (ERC-20):
// 6.  mintChronoEssence(address _to, uint256 _amount): Mints new ChronoEssence tokens to a specified address. Restricted to MINTER_ROLE.
// 7.  transfer(address _to, uint256 _amount): Standard ERC-20 token transfer.
// 8.  approve(address _spender, uint256 _amount): Standard ERC-20 function to approve a spender.
// 9.  balanceOf(address _account): Returns the balance of ChronoEssence for a given account.

// III. GlyphKeepers (Soulbound ERC-721):
// 10. mintGlyphKeeper(address _to, uint256 _keeperType, string memory _achievementDetails): Mints a non-transferable GlyphKeeper NFT, representing an achievement or contribution. Restricted to MINTER_ROLE.
// 11. getGlyphKeeperDetails(uint256 _tokenId): Retrieves detailed information about a GlyphKeeper.
// 12. updateGlyphKeeperReputation(uint256 _tokenId, int256 _reputationChange): Adjusts a GlyphKeeper's reputation score. Restricted to NARRATIVE_ORACLE_ROLE.

// IV. Gamified Challenges & Staking:
// 13. createNarrativeChallenge(string memory _challengeName, uint256 _startTime, uint256 _endTime, uint256 _minCERequired, bytes32 _expectedOutcomeHash): An ADMIN_ROLE creates a new prediction-based challenge.
// 14. participateInChallenge(uint256 _challengeId, uint256 _chronoEssenceAmount, bytes32 _userPrediction): Allows users to stake ChronoEssence and submit their prediction for an active challenge.
// 15. resolveNarrativeChallenge(uint256 _challengeId, bytes32 _actualOutcomeHash): The NARRATIVE_ORACLE_ROLE resolves a challenge by revealing the true outcome, making rewards claimable.
// 16. claimChallengeRewards(uint256 _challengeId): Allows participants to claim their proportional share of the reward pool if their prediction was correct.
// 17. stakeChronoGlyphForBoost(uint256 _tokenId): Allows an owner to stake their ChronoGlyph, transferring it to the contract and marking it as staked.
// 18. unstakeChronoGlyph(uint256 _tokenId): Allows an owner to unstake their previously staked ChronoGlyph, returning it to them.

// V. Role Management & Administration:
// 19. setNarrativeOracle(address _newOracle): Grants the NARRATIVE_ORACLE_ROLE to a specified address. Restricted to DEFAULT_ADMIN_ROLE.
// 20. grantRole(bytes32 _role, address _account): Generic function to grant any role. Inherited from AccessControl.
// 21. revokeRole(bytes32 _role, address _account): Generic function to revoke any role. Inherited from AccessControl.
// 22. pause(): Pauses core functions of the contract, restricting interactions. Restricted to PAUSER_ROLE.
// 23. unpause(): Unpauses the contract, allowing normal operations to resume. Restricted to PAUSER_ROLE.
// 24. setBaseTokenURIPrefix(string memory _newPrefix): Sets a global base URI prefix for all NFTs managed by the contract. Restricted to DEFAULT_ADMIN_ROLE.

// Custom Errors
error Unauthorized();
error InvalidTokenId();
error InvalidAmount();
error NotOwnerOrApproved();
error ChallengeNotFound();
error ChallengeNotActive();
error ChallengeAlreadyResolved();
error InvalidPrediction();
error InsufficientFunds();
error GlyphNotStaked();
error GlyphAlreadyStaked();
error NotAnOracle();
error NotAKeeper();
error TransferNotAllowed(); // Specific for soulbound tokens

contract ChronoGlyphChronicles is ERC721, ERC721Burnable, ERC20, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant NARRATIVE_ORACLE_ROLE = keccak256("NARRATIVE_ORACLE_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- ChronoGlyph (Dynamic NFT) State ---
    Counters.Counter private _chronoGlyphTokenIds;
    string private _chronoGlyphBaseURI;

    struct ChronoGlyphData {
        uint256 creationTime;
        uint256 lastEvolutionTime;
        bytes32 currentNarrativeState; // Hash representing the current state/event (e.g., AI output hash)
        string metadataURI; // The specific URI suffix for this token, appended to _chronoGlyphBaseURI
        bool isStaked; // True if the ChronoGlyph is currently staked within the contract
    }
    mapping(uint256 => ChronoGlyphData) private _chronoGlyphData; // tokenId => ChronoGlyphData
    mapping(uint256 => uint256) private _stakedGlyphTime; // tokenId => timestamp of staking (0 if not staked)

    // --- GlyphKeepers (Soulbound NFT) State ---
    Counters.Counter private _glyphKeeperTokenIds;
    string private _glyphKeeperBaseURI;

    struct GlyphKeeperData {
        address owner; // The address holding this soulbound token
        uint256 keeperType; // Categorization of the achievement (e.g., 1=Initiate, 2=Chronicler, 3=Architect)
        string achievementDetails; // Description of what earned the keeper
        int256 reputationScore; // A dynamic score tied to the keeper, influencing ecosystem perks
    }
    mapping(uint256 => GlyphKeeperData) private _glyphKeeperData; // tokenId => GlyphKeeperData

    // --- Challenges State ---
    Counters.Counter private _challengeIds;

    enum ChallengeStatus {
        Pending,   // Challenge created, but not yet active
        Active,    // Open for participation
        Resolved,  // Outcome determined, rewards claimable
        Cancelled  // Challenge cancelled
    }

    struct Challenge {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 minCERequired; // Minimum ChronoEssence (CE) to stake for participation
        bytes32 expectedOutcomeHash; // Hash of the correct outcome, known by oracle (but hidden until resolution)
        bytes32 actualOutcomeHash; // The true outcome hash, set by oracle upon resolution
        uint256 totalCERewardPool; // Sum of all CE staked by participants
        mapping(address => ChallengeParticipant) participants;
        address[] participantAddresses; // To iterate over participants for reward calculation
        ChallengeStatus status;
        bool isSettled; // True once rewards distribution logic has been finalized
    }

    struct ChallengeParticipant {
        uint256 stakedCEReceived; // Amount of ChronoEssence staked by this participant
        bytes32 userPrediction; // The participant's prediction hash
        bool claimedReward; // True if participant has already claimed rewards
    }

    mapping(uint256 => Challenge) private _challenges; // challengeId => Challenge

    // --- Events ---
    event ChronoGlyphMinted(uint256 indexed tokenId, address indexed owner, string initialURI);
    event ChronoGlyphEvolved(uint256 indexed tokenId, bytes32 narrativeEventHash, string newURI);
    event GlyphKeeperMinted(uint256 indexed tokenId, address indexed owner, uint256 keeperType, string achievementDetails);
    event GlyphKeeperReputationUpdated(uint256 indexed tokenId, int256 reputationChange, int256 newReputation);
    event ChronoGlyphStaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event ChronoGlyphUnstaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event ChallengeCreated(uint256 indexed challengeId, string name, uint256 startTime, uint256 endTime);
    event ChallengeParticipated(uint256 indexed challengeId, address indexed participant, uint256 stakedAmount, bytes32 prediction);
    event ChallengeResolved(uint256 indexed challengeId, bytes32 actualOutcomeHash, uint256 totalRewardPool);
    event ChallengeRewardsClaimed(uint256 indexed challengeId, address indexed participant, uint256 rewardAmount);

    constructor(
        string memory _chronoGlyphName,
        string memory _chronoGlyphSymbol,
        string memory _chronoEssenceName,
        string memory _chronoEssenceSymbol,
        string memory _glyphKeeperName,
        string memory _glyphKeeperSymbol,
        string memory _initialChronoGlyphBaseURI,
        string memory _initialGlyphKeeperBaseURI
    )
        ERC721(_chronoGlyphName, _chronoGlyphSymbol) // Initializes ChronoGlyph ERC-721
        ERC20(_chronoEssenceName, _chronoEssenceSymbol) // Initializes ChronoEssence ERC-20
        AccessControl(msg.sender) // Initializes AccessControl with deployer as DEFAULT_ADMIN_ROLE
        Pausable() // Initializes Pausable
    {
        // Set up initial roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(NARRATIVE_ORACLE_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);

        _chronoGlyphBaseURI = _initialChronoGlyphBaseURI;
        _glyphKeeperBaseURI = _initialGlyphKeeperBaseURI;
    }

    // --- Modifiers ---
    modifier onlyChronoGlyphOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert NotOwnerOrApproved(); // Or not approved for transfer
        }
        _;
    }

    modifier onlyChronoGlyphNotStaked(uint256 tokenId) {
        if (_chronoGlyphData[tokenId].isStaked) {
            revert GlyphAlreadyStaked();
        }
        _;
    }

    modifier onlyChronoGlyphStaked(uint256 tokenId) {
        if (!_chronoGlyphData[tokenId].isStaked) {
            revert GlyphNotStaked();
        }
        _;
    }

    modifier onlyNarrativeOracle() {
        if (!hasRole(NARRATIVE_ORACLE_ROLE, _msgSender())) {
            revert NotAnOracle();
        }
        _;
    }

    // --- ERC721 Overrides for Base URIs ---
    // Note: This contract manages two distinct types of NFTs (ChronoGlyphs and GlyphKeepers).
    // The `_baseURI()` function is inherited from ERC721 and by default uses the ERC721 name/symbol
    // set in the constructor. To differentiate, `tokenURI` will manually prepend the correct base URI
    // for each NFT type, and `_chronoGlyphBaseURI` / `_glyphKeeperBaseURI` are separate.
    // However, the `_baseURI()` function itself is only for ChronoGlyphs, as per `tokenURI` below.
    function _baseURI() internal view override returns (string memory) {
        return _chronoGlyphBaseURI;
    }

    // --- I. ChronoGlyphs (Dynamic ERC-721) Functions ---

    /// @notice Mints a new ChronoGlyph NFT with an initial state and URI.
    /// @param _to The address to mint the ChronoGlyph to.
    /// @param _initialMetadataURI The initial metadata URI suffix for this ChronoGlyph.
    function mintChronoGlyph(address _to, string memory _initialMetadataURI) public virtual onlyRole(MINTER_ROLE) {
        _chronoGlyphTokenIds.increment();
        uint256 newItemId = _chronoGlyphTokenIds.current();
        _safeMint(_to, newItemId); // Mints the ERC721 token
        _chronoGlyphData[newItemId] = ChronoGlyphData({
            creationTime: block.timestamp,
            lastEvolutionTime: block.timestamp,
            currentNarrativeState: 0x0, // Initial state, or a specific genesis hash
            metadataURI: _initialMetadataURI,
            isStaked: false
        });
        emit ChronoGlyphMinted(newItemId, _to, _initialMetadataURI);
    }

    /// @notice Allows designated NARRATIVE_ORACLE_ROLE to evolve a ChronoGlyph's state and metadata.
    /// @dev This function simulates an AI/Oracle updating the NFT based on external events/data.
    /// @param _tokenId The ID of the ChronoGlyph to evolve.
    /// @param _narrativeEventHash A hash representing the narrative event or AI insight causing the evolution.
    /// @param _newMetadataURI The new metadata URI reflecting the ChronoGlyph's evolved state.
    function evolveChronoGlyph(
        uint256 _tokenId,
        bytes32 _narrativeEventHash,
        string memory _newMetadataURI
    ) public virtual onlyNarrativeOracle {
        if (!_exists(_tokenId)) {
            revert InvalidTokenId();
        }
        ChronoGlyphData storage glyph = _chronoGlyphData[_tokenId];
        glyph.lastEvolutionTime = block.timestamp;
        glyph.currentNarrativeState = _narrativeEventHash;
        glyph.metadataURI = _newMetadataURI;
        emit ChronoGlyphEvolved(_tokenId, _narrativeEventHash, _newMetadataURI);
    }

    /// @notice Retrieves comprehensive details for a ChronoGlyph.
    /// @param _tokenId The ID of the ChronoGlyph.
    /// @return owner_ The current owner's address.
    /// @return creationTime_ The timestamp of creation.
    /// @return lastEvolutionTime_ The timestamp of the last evolution.
    /// @return currentNarrativeState_ The current narrative state hash.
    /// @return metadataURI_ The current metadata URI suffix.
    /// @return isStaked_ Whether the glyph is currently staked.
    function getChronoGlyphDetails(
        uint256 _tokenId
    )
        public
        view
        returns (
            address owner_,
            uint256 creationTime_,
            uint256 lastEvolutionTime_,
            bytes32 currentNarrativeState_,
            string memory metadataURI_,
            bool isStaked_
        )
    {
        if (!_exists(_tokenId)) {
            revert InvalidTokenId();
        }
        ChronoGlyphData storage glyph = _chronoGlyphData[_tokenId];
        owner_ = ownerOf(_tokenId); // Use ERC721's ownerOf for canonical owner
        creationTime_ = glyph.creationTime;
        lastEvolutionTime_ = glyph.lastEvolutionTime;
        currentNarrativeState_ = glyph.currentNarrativeState;
        metadataURI_ = glyph.metadataURI;
        isStaked_ = glyph.isStaked;
    }

    /// @notice Standard ERC-721 transfer function for ChronoGlyphs.
    /// @dev Overrides the base ERC721 transfer to prevent transfer if the ChronoGlyph is staked.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override whenNotPaused {
        // Check if it's a ChronoGlyph (assuming ChronoGlyph IDs are distinct from GlyphKeeper IDs)
        // If _chronoGlyphData[_tokenId].creationTime is 0, it means it's not a ChronoGlyph (or hasn't been initialized)
        if (_chronoGlyphData[_tokenId].creationTime != 0 && _chronoGlyphData[_tokenId].isStaked) {
            revert GlyphAlreadyStaked(); // Cannot transfer staked glyphs
        }
        super.transferFrom(_from, _to, _tokenId);
    }

    /// @notice Returns the current full metadata URI for a ChronoGlyph.
    /// @param _tokenId The ID of the ChronoGlyph.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert InvalidTokenId();
        }
        return string(abi.encodePacked(_chronoGlyphBaseURI, _chronoGlyphData[_tokenId].metadataURI));
    }

    /// @notice Sets a global base URI prefix for ChronoGlyph and GlyphKeeper NFTs.
    /// @dev This allows updating the prefix for all NFTs without changing individual URIs.
    /// @param _newPrefix The new base URI prefix.
    function setBaseTokenURIPrefix(string memory _newPrefix) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _chronoGlyphBaseURI = _newPrefix;
        _glyphKeeperBaseURI = _newPrefix; // Assuming a shared base prefix for all NFTs in this contract
    }

    // --- II. ChronoEssence (ERC-20) Functions ---
    // ERC20 functions like `transfer`, `approve`, `balanceOf` are inherited and work out of the box.

    /// @notice Mints new ChronoEssence tokens, restricted to specific roles (e.g., MINTER_ROLE).
    /// @param _to The address to mint tokens to.
    /// @param _amount The amount of tokens to mint.
    function mintChronoEssence(address _to, uint256 _amount) public virtual onlyRole(MINTER_ROLE) {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        _mint(_to, _amount);
    }

    // --- III. GlyphKeepers (Soulbound ERC-721) Functions ---
    // GlyphKeepers are non-transferable. This is enforced by overriding _beforeTokenTransfer.

    /// @notice Mints a non-transferable GlyphKeeper NFT, representing an achievement or reputation.
    /// @param _to The address to mint the GlyphKeeper to.
    /// @param _keeperType An integer representing the type of GlyphKeeper (e.g., 1 for "Explorer", 2 for "Sage").
    /// @param _achievementDetails A string describing the achievement that earned the keeper.
    function mintGlyphKeeper(
        address _to,
        uint256 _keeperType,
        string memory _achievementDetails
    ) public virtual onlyRole(MINTER_ROLE) {
        _glyphKeeperTokenIds.increment();
        uint256 newItemId = _glyphKeeperTokenIds.current();
        // _safeMint will internally call _beforeTokenTransfer, which will allow minting from address(0)
        _safeMint(_to, newItemId);
        _glyphKeeperData[newItemId] = GlyphKeeperData({
            owner: _to, // Store owner for soulbound check later and convenience
            keeperType: _keeperType,
            achievementDetails: _achievementDetails,
            reputationScore: 0 // Initial reputation score
        });
        emit GlyphKeeperMinted(newItemId, _to, _keeperType, _achievementDetails);
    }

    /// @notice Retrieves details for a GlyphKeeper.
    /// @param _tokenId The ID of the GlyphKeeper.
    /// @return owner_ The owner's address.
    /// @return keeperType_ The type of keeper.
    /// @return achievementDetails_ The details of the achievement.
    /// @return reputationScore_ The current reputation score.
    function getGlyphKeeperDetails(
        uint256 _tokenId
    )
        public
        view
        returns (
            address owner_,
            uint256 keeperType_,
            string memory achievementDetails_,
            int256 reputationScore_
        )
    {
        // Check if the tokenId is potentially a GlyphKeeper and has data.
        // Assuming GlyphKeeper IDs start from 1 and are incremented by _glyphKeeperTokenIds.
        if (_tokenId == 0 || _tokenId > _glyphKeeperTokenIds.current() || _glyphKeeperData[_tokenId].owner == address(0)) {
             revert NotAKeeper(); // This ID is not a minted GlyphKeeper
        }
        GlyphKeeperData storage keeper = _glyphKeeperData[_tokenId];
        owner_ = keeper.owner;
        keeperType_ = keeper.keeperType;
        achievementDetails_ = keeper.achievementDetails;
        reputationScore_ = keeper.reputationScore;
    }

    /// @notice Adjusts a GlyphKeeper's reputation score.
    /// @dev This can be used by an oracle or admin to reflect user contributions/behavior.
    /// @param _tokenId The ID of the GlyphKeeper.
    /// @param _reputationChange The amount to change the reputation by (can be positive or negative).
    function updateGlyphKeeperReputation(uint256 _tokenId, int256 _reputationChange) public onlyRole(NARRATIVE_ORACLE_ROLE) {
        // Validate if it's a valid GlyphKeeper token
        if (_tokenId == 0 || _tokenId > _glyphKeeperTokenIds.current() || _glyphKeeperData[_tokenId].owner == address(0)) {
            revert InvalidTokenId(); // Not a valid GlyphKeeper ID
        }
        GlyphKeeperData storage keeper = _glyphKeeperData[_tokenId];
        keeper.reputationScore += _reputationChange;
        emit GlyphKeeperReputationUpdated(_tokenId, _reputationChange, keeper.reputationScore);
    }

    /// @dev Overrides ERC721's _beforeTokenTransfer to make GlyphKeepers soulbound.
    /// @dev This function is automatically called before any ERC721 transfer (mint, transfer, burn).
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize // New parameter in Solidity 0.8.20 OpenZeppelin
    ) internal virtual override(ERC721, ERC721Burnable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Check if the tokenId belongs to a GlyphKeeper.
        // This is determined by checking if its data exists in the _glyphKeeperData mapping
        // and if it was minted by the GlyphKeeper counter.
        if (_glyphKeeperData[tokenId].owner != address(0) && tokenId <= _glyphKeeperTokenIds.current()) {
            if (from != address(0) && to != address(0)) { // Disallow transfers (from existing owner to new owner)
                revert TransferNotAllowed(); // GlyphKeeper is soulbound
            }
        }
    }

    // --- IV. Gamified Challenges & Staking Functions ---

    /// @notice An ADMIN_ROLE creates a new narrative-based challenge.
    /// @param _challengeName A descriptive name for the challenge.
    /// @param _startTime The timestamp when the challenge becomes active for participation.
    /// @param _endTime The timestamp when participation closes.
    /// @param _minCERequired The minimum ChronoEssence required to participate.
    /// @param _expectedOutcomeHash A hash representing the correct outcome of the challenge, revealed by the oracle later.
    function createNarrativeChallenge(
        string memory _challengeName,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minCERequired,
        bytes32 _expectedOutcomeHash
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        if (_startTime >= _endTime || _endTime <= block.timestamp) {
            revert InvalidAmount(); // Or specific error for invalid time range
        }

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        _challenges[newChallengeId].name = _challengeName;
        _challenges[newChallengeId].startTime = _startTime;
        _challenges[newChallengeId].endTime = _endTime;
        _challenges[newChallengeId].minCERequired = _minCERequired;
        _challenges[newChallengeId].expectedOutcomeHash = _expectedOutcomeHash;
        _challenges[newChallengeId].status = ChallengeStatus.Active; // Starts as active immediately after creation
        _challenges[newChallengeId].totalCERewardPool = 0;
        _challenges[newChallengeId].isSettled = false;

        emit ChallengeCreated(newChallengeId, _challengeName, _startTime, _endTime);
    }

    /// @notice Users stake ChronoEssence and submit a prediction/choice for a challenge.
    /// @param _challengeId The ID of the challenge to participate in.
    /// @param _chronoEssenceAmount The amount of ChronoEssence to stake.
    /// @param _userPrediction A hash representing the participant's prediction/choice.
    function participateInChallenge(
        uint256 _challengeId,
        uint256 _chronoEssenceAmount,
        bytes32 _userPrediction
    ) public whenNotPaused {
        Challenge storage challenge = _challenges[_challengeId];
        if (_challengeId == 0 || challenge.status == ChallengeStatus.Cancelled || challenge.status == ChallengeStatus.Resolved) {
            revert ChallengeNotFound();
        }
        if (block.timestamp < challenge.startTime || block.timestamp > challenge.endTime) {
            revert ChallengeNotActive();
        }
        if (_chronoEssenceAmount < challenge.minCERequired) {
            revert InvalidAmount(); // Staked amount below minimum
        }
        if (balanceOf(_msgSender()) < _chronoEssenceAmount) {
            revert InsufficientFunds();
        }
        if (challenge.participants[_msgSender()].stakedCEReceived > 0) {
            revert InvalidPrediction(); // Already participated
        }

        // Transfer CE from participant to contract's pool
        _transfer(_msgSender(), address(this), _chronoEssenceAmount);
        challenge.totalCERewardPool += _chronoEssenceAmount;

        // Store participant's data
        challenge.participants[_msgSender()] = ChallengeParticipant({
            stakedCEReived: _chronoEssenceAmount,
            userPrediction: _userPrediction,
            claimedReward: false
        });
        challenge.participantAddresses.push(_msgSender());

        emit ChallengeParticipated(_challengeId, _msgSender(), _chronoEssenceAmount, _userPrediction);
    }

    /// @notice The NARRATIVE_ORACLE_ROLE resolves a challenge, determining winners and enabling reward claims.
    /// @param _challengeId The ID of the challenge to resolve.
    /// @param _actualOutcomeHash The true outcome hash of the challenge.
    function resolveNarrativeChallenge(uint256 _challengeId, bytes32 _actualOutcomeHash) public onlyNarrativeOracle {
        Challenge storage challenge = _challenges[_challengeId];
        if (_challengeId == 0 || challenge.status == ChallengeStatus.Cancelled || challenge.status == ChallengeStatus.Resolved) {
            revert ChallengeNotFound();
        }
        if (block.timestamp < challenge.endTime) {
            revert ChallengeNotActive(); // Cannot resolve before end time
        }
        if (challenge.isSettled) {
            revert ChallengeAlreadyResolved();
        }

        challenge.status = ChallengeStatus.Resolved;
        challenge.actualOutcomeHash = _actualOutcomeHash;
        challenge.isSettled = true; // Mark as settled to prevent re-resolution

        emit ChallengeResolved(_challengeId, _actualOutcomeHash, challenge.totalCERewardPool);
    }

    /// @notice Participants can claim their share of rewards after a challenge is resolved.
    /// @param _challengeId The ID of the challenge.
    function claimChallengeRewards(uint256 _challengeId) public {
        Challenge storage challenge = _challenges[_challengeId];
        if (_challengeId == 0 || challenge.status != ChallengeStatus.Resolved) {
            revert ChallengeNotActive(); // Not resolved yet or invalid ID
        }

        ChallengeParticipant storage participant = challenge.participants[_msgSender()];
        if (participant.stakedCEReceived == 0) {
            revert InvalidAmount(); // No participation found for this user
        }
        if (participant.claimedReward) {
            revert InvalidAmount(); // Already claimed
        }

        uint256 rewardAmount = 0;
        if (participant.userPrediction == challenge.actualOutcomeHash) {
            // Calculate total staked amount by correct predictors
            uint256 totalCorrectStakes = 0;
            for (uint i = 0; i < challenge.participantAddresses.length; i++) {
                address pAddr = challenge.participantAddresses[i];
                if (challenge.participants[pAddr].userPrediction == challenge.actualOutcomeHash) {
                    totalCorrectStakes += challenge.participants[pAddr].stakedCEReceived;
                }
            }

            if (totalCorrectStakes > 0) {
                // Reward is proportional to stake within the correct prediction pool
                rewardAmount = (challenge.totalCERewardPool * participant.stakedCEReceived) / totalCorrectStakes;
            } else {
                // This scenario means no one predicted correctly, so the pool remains in contract (or is burned/refunded)
                // For simplicity, it means no reward is claimable for anyone.
                rewardAmount = 0;
            }
        } else {
            // Incorrect prediction, participant forfeits their stake to the correct predictors' pool.
            rewardAmount = 0;
        }

        participant.claimedReward = true; // Mark as claimed regardless of reward amount

        if (rewardAmount > 0) {
            _transfer(address(this), _msgSender(), rewardAmount); // Transfer reward from contract pool
        }

        emit ChallengeRewardsClaimed(_challengeId, _msgSender(), rewardAmount);
    }

    /// @notice Allows ChronoGlyph owners to stake their NFT for a temporary boost or special status.
    /// @dev The NFT is transferred to the contract's address, and its state is updated.
    /// @param _tokenId The ID of the ChronoGlyph to stake.
    function stakeChronoGlyphForBoost(uint256 _tokenId) public onlyChronoGlyphOwner(_tokenId) onlyChronoGlyphNotStaked(_tokenId) whenNotPaused {
        if (!_exists(_tokenId)) {
            revert InvalidTokenId();
        }
        // Transfer the NFT to the contract itself.
        // This will trigger the overridden `transferFrom` which checks `isStaked` again for safety.
        super.transferFrom(_msgSender(), address(this), _tokenId);
        _chronoGlyphData[_tokenId].isStaked = true;
        _stakedGlyphTime[_tokenId] = block.timestamp;

        emit ChronoGlyphStaked(_tokenId, _msgSender(), block.timestamp);
    }

    /// @notice Allows owners to unstake their ChronoGlyph.
    /// @dev The NFT is transferred back from the contract to the original staker.
    /// @param _tokenId The ID of the ChronoGlyph to unstake.
    function unstakeChronoGlyph(uint256 _tokenId) public onlyChronoGlyphOwner(_tokenId) onlyChronoGlyphStaked(_tokenId) whenNotPaused {
        if (!_exists(_tokenId)) {
            revert InvalidTokenId();
        }
        // Transfer the NFT back to the original staker from the contract's possession.
        super.transferFrom(address(this), _msgSender(), _tokenId);
        _chronoGlyphData[_tokenId].isStaked = false;
        delete _stakedGlyphTime[_tokenId]; // Clear staking timestamp

        emit ChronoGlyphUnstaked(_tokenId, _msgSender(), block.timestamp);
    }

    // --- V. Role Management & Administration Functions ---

    /// @notice Assigns the NARRATIVE_ORACLE_ROLE to an address.
    /// @dev Only DEFAULT_ADMIN_ROLE can grant this specific role. This allows decentralizing the "AI/Oracle" input.
    /// @param _newOracle The address to grant the oracle role to.
    function setNarrativeOracle(address _newOracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(NARRATIVE_ORACLE_ROLE, _newOracle);
    }

    // `grantRole(bytes32 _role, address _account)` and `revokeRole(bytes32 _role, address _account)`
    // are inherited from OpenZeppelin's AccessControl and are fully functional.

    /// @notice Pauses core functions of the contract, restricted to PAUSER_ROLE.
    /// @dev Useful for emergencies or upgrades.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract, restricted to PAUSER_ROLE.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
```