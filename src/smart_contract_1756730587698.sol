Here is a sophisticated Solidity smart contract, `EvolvingArtProtocol`, designed around dynamic NFTs (called "Evos"), fractional ownership, AI-driven evolution, and community governance. It introduces novel concepts like "Trait Infusion" and a "Discovery Pool" for rewarding curation. This contract aims to avoid direct duplication of existing open-source projects by combining these advanced features in a unique protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For easier management of proposals etc.
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender() if needed

/**
 * @title EvolvingArtProtocol (EAP)
 * @author [Your Name/Alias]
 * @notice A sophisticated protocol for dynamic, evolving, and fractionalized NFTs ("Evos")
 *         with integrated AI oracle interactions, community governance, IP monetization,
 *         a discovery pool, and unique "Trait Infusion" mechanics.
 *
 * @dev This contract combines ERC721 for core Evo NFTs, ERC1155 for fractional shares,
 *      and advanced custom logic for evolution, governance, and interaction.
 *      It leverages OpenZeppelin standards for security and best practices.
 */
contract EvolvingArtProtocol is ERC721, ERC1155, Ownable, Pausable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;

    // --- Outline and Function Summary ---
    //
    // This protocol introduces "Evos" – dynamic NFTs that can evolve, be fractionalized,
    // and are governed by their owners/community. It integrates AI for evolution
    // and includes mechanisms for IP monetization, community grants, and trait
    // manipulation.
    //
    // I. Core State & Data Structures:
    //    - Evo (ERC721 NFT): Represents a unique, dynamic digital asset. Its traits and metadata can change.
    //    - EvoShare (ERC1155 Token): Fractional ownership of an Evo, granting voting power and revenue share.
    //    - Proposals: Mechanism for community governance over Evo evolution, IP deals, and grants.
    //    - Discovery Pool: A fund to incentivize curation and reward valuable Evos.
    //
    // II. Access Control & Configuration:
    //    1.  `constructor()`: Initializes the contract, sets the deployer as owner, and defines initial parameters.
    //    2.  `setAIOracleAddress(address _aiOracle)`: Sets the address of the trusted AI oracle contract. (Admin Only)
    //    3.  `pause()`: Pauses core contract operations (transfers, evolutions, etc.). (Admin Only)
    //    4.  `unpause()`: Unpauses core contract operations. (Admin Only)
    //
    // III. Evo (Dynamic NFT) Management (ERC721):
    //    5.  `mintEvo(string memory _initialMetadataURI, bytes memory _initialTraitData)`: Mints a new Evo with initial metadata and traits.
    //    6.  `requestEvoEvolution(uint256 _evoId, bytes memory _evolutionContext)`: Triggers an evolution request for a specific Evo, interacting with the AI oracle.
    //    7.  `fulfillEvoEvolution(uint256 _evoId, bytes memory _newTraitData, string memory _newMetadataURI)`: Callback from the AI oracle to update an Evo's traits and metadata. (AI Oracle Only)
    //    8.  `getEvoTraits(uint256 _evoId)`: Returns the current dynamic traits of an Evo (e.g., a JSON bytes string).
    //    9.  `tokenURI(uint256 _tokenId)`: Overrides ERC721's `tokenURI` to provide a dynamic metadata endpoint reflecting current traits.
    //
    // IV. Fractionalization & Shares (ERC1155):
    //    10. `fractionalizeEvo(uint256 _evoId, uint256 _shareSupply)`: Converts an Evo into fractional ERC1155 shares. The Evo becomes non-transferable until shares are merged.
    //    11. `mergeFractions(uint256 _evoId)`: Allows the owner of all fractional shares to burn them and regain full control of the original Evo NFT.
    //    12. `uri(uint256 _tokenId)`: Overrides ERC1155's `uri` for fractional share metadata.
    //
    // V. IP Monetization & Revenue Distribution:
    //    13. `recordIPRevenue(uint256 _evoId)`: Allows external parties to pay licensing fees or royalties directly into an Evo's associated treasury. (Payable)
    //    14. `claimFractionalRevenue(uint256 _evoId)`: Allows holders of fractional shares to claim their pro-rata portion of accumulated IP revenue for a specific Evo.
    //
    // VI. Governance & DAO Mechanics:
    //    15. `createEvolutionProposal(uint256 _evoId, bytes memory _proposedNewTraits, string memory _proposedNewMetadataURI, uint256 _voteDuration)`: Initiates a DAO proposal to manually evolve an Evo's traits and metadata.
    //    16. `createDiscoveryGrantProposal(uint256 _evoId, uint256 _amount, address _recipient, string memory _reason, uint256 _voteDuration)`: Proposes a grant from the Discovery Pool to a specific Evo or its community.
    //    17. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows Evo owners (or fractional shareholders) to vote on an active proposal. Voting power is proportional to ownership.
    //    18. `executeProposal(uint256 _proposalId)`: Executes a proposal if it has passed and its voting duration has ended.
    //
    // VII. Synergy & Discovery Mechanisms:
    //    19. `depositDiscoveryPool()`: Allows anyone to contribute funds to the EAP's Discovery Pool. (Payable)
    //    20. `curateEvo(uint256 _evoId)`: Allows a user to "curate" an Evo by staking a small amount. Curators provide social proof and can later be rewarded from the Discovery Pool. (Payable)
    //    21. `distributeCuratorReward(uint256 _evoId, address _curator, uint256 _amount)`: (Admin/DAO) Distributes a specific reward amount from the Discovery Pool to a named curator.
    //    22. `infuseTrait(uint256 _sourceEvoId, uint256 _targetEvoId, string memory _traitName)`: A unique mechanism where a named trait from one Evo (source) can be "infused" (copied) into another Evo (target). The source Evo enters a cooldown period.
    //    23. `removeTrait(uint256 _evoId, string memory _traitName)`: Allows the Evo owner/DAO to explicitly remove a specific trait from an Evo.
    //    24. `setEvoStatus(uint256 _evoId, EvoStatus _status)`: Sets a lifecycle status for an Evo (e.g., Active, Depleted, Archived). (Admin Only/DAO)

    // --- Constants & Configuration ---
    uint256 public constant EVO_SHARE_TOKEN_TYPE = 1; // ERC1155 ID for fractional shares

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "EAP: Not AI Oracle");
        _;
    }

    modifier onlyEvoOwnerOrShareholder(uint256 _evoId) {
        address evoOwner = ownerOf(_evoId);
        if (evoOwner == msg.sender) {
            _;
            return;
        }

        // If fractionalized, check if msg.sender holds shares
        require(evos[_evoId].isFractionalized, "EAP: Evo not owned or fractionalized");
        require(balanceOf(msg.sender, _evoId) > 0, "EAP: No shares held for this Evo");
        _;
    }

    // --- Interfaces ---
    interface IAIOracle {
        function requestEvolution(
            uint256 _evoId,
            address _callbackContract,
            bytes calldata _evolutionContext
        ) external;
    }

    // --- Enums ---
    enum EvoStatus {
        Active,          // Normal operational status
        InfusionCooling, // Evo has recently infused a trait and is on cooldown
        TraitDepleted,   // Evo has used all its infusion charges
        Archived         // Evo is no longer actively evolving or participating
    }

    enum ProposalType {
        Evolution,
        LicensingDeal,   // Future expansion: for negotiating external IP deals
        DiscoveryGrant
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    // --- Structs ---
    struct Evo {
        string metadataURI;
        mapping(string => bytes) traitMatrix; // Stores trait names => trait data (e.g., JSON bytes)
        uint256 evolutionEpochs;
        bool isFractionalized;
        uint256 shareSupply; // Only relevant if isFractionalized is true
        address fractionalShareDeployer; // The address that fractionalized this Evo
        EvoStatus status;
        uint256 lastInfusionTime; // Timestamp of last trait infusion
        uint256 infusionCooldownDuration; // Duration until Evo can infuse again
        uint256 infusionCharges; // Number of times this Evo can infuse traits
    }

    struct Proposal {
        uint256 evoId; // The Evo this proposal concerns (0 for general protocol proposals)
        ProposalType proposalType;
        bytes proposedNewTraits; // For Evolution proposals
        string proposedNewMetadataURI; // For Evolution proposals
        uint256 grantAmount; // For DiscoveryGrant proposals
        address grantRecipient; // For DiscoveryGrant proposals
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- State Variables ---
    Counters.Counter private _evoIds;      // For ERC721 token IDs
    Counters.Counter private _proposalIds; // For unique proposal IDs

    address public aiOracleAddress;
    uint256 public curationStakeAmount;      // Required ETH amount to curate an Evo
    uint256 public infusionCooldownDefault;  // Default cooldown for trait infusion (e.g., 7 days)
    uint256 public defaultInfusionCharges;   // Default charges for new Evos

    mapping(uint256 => Evo) public evos;                     // Evo ID => Evo details
    mapping(uint256 => uint256) public evoIpRevenueBalance;  // Evo ID => accumulated IP revenue (total pool)
    mapping(uint256 => mapping(address => uint256)) public evoClaimedRevenue; // Evo ID => claimant => claimed amount

    mapping(uint256 => Proposal) public proposals; // Proposal ID => Proposal details
    EnumerableSet.UintSet private activeProposals; // Set of currently active proposal IDs

    mapping(uint256 => mapping(address => uint256)) public curatorStakes; // Evo ID => curator address => staked amount

    // --- Events ---
    event EvoMinted(uint256 indexed evoId, address indexed owner, string initialMetadataURI);
    event EvoEvolutionRequested(uint256 indexed evoId, bytes evolutionContext);
    event EvoEvolved(uint256 indexed evoId, string newMetadataURI, bytes newTraitData);
    event EvoFractionalized(uint256 indexed evoId, address indexed fractionalizer, uint256 shareSupply);
    event EvoFractionsMerged(uint256 indexed evoId, address indexed redeemer);
    event IPRevenueRecorded(uint256 indexed evoId, address indexed payer, uint256 amount);
    event IPRevenueClaimed(uint256 indexed evoId, address indexed claimant, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed evoId, ProposalType proposalType, address proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus status);
    event DiscoveryPoolDeposited(address indexed depositor, uint256 amount);
    event EvoCurated(uint256 indexed evoId, address indexed curator, uint256 stakedAmount);
    event CuratorRewardDistributed(uint256 indexed evoId, address indexed curator, uint256 amount);
    event TraitInfused(uint256 indexed sourceEvoId, uint256 indexed targetEvoId, string traitName, address indexed infuser);
    event TraitRemoved(uint256 indexed evoId, string traitName, address indexed remover);
    event EvoStatusUpdated(uint256 indexed evoId, EvoStatus oldStatus, EvoStatus newStatus);

    /**
     * @dev Constructor initializes the ERC721 and ERC1155 contracts, sets the owner,
     *      and defines initial protocol parameters.
     * @param _name Name of the ERC721 token (e.g., "Evolving Art Protocol Evo").
     * @param _symbol Symbol of the ERC721 token (e.g., "EAP").
     * @param _initialEvoShareUri Base URI for ERC1155 fractional shares.
     * @param _curationStakeAmount Required ETH amount to curate an Evo.
     * @param _infusionCooldownDefault Default cooldown duration (in seconds) for trait infusion.
     * @param _defaultInfusionCharges Default number of infusion charges for a new Evo.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initialEvoShareUri,
        uint256 _curationStakeAmount,
        uint256 _infusionCooldownDefault,
        uint256 _defaultInfusionCharges
    ) ERC721(_name, _symbol) ERC1155(_initialEvoShareUri) {
        aiOracleAddress = address(0); // Must be set by owner
        curationStakeAmount = _curationStakeAmount;
        infusionCooldownDefault = _infusionCooldownDefault;
        defaultInfusionCharges = _defaultInfusionCharges;
    }

    // --- II. Access Control & Configuration ---

    /**
     * @dev Sets the address of the trusted AI oracle contract.
     * @param _aiOracle The address of the AI oracle.
     */
    function setAIOracleAddress(address _aiOracle) public onlyOwner {
        require(_aiOracle != address(0), "EAP: AI Oracle cannot be zero address");
        aiOracleAddress = _aiOracle;
    }

    /**
     * @dev Pauses core contract operations. Only callable by the owner.
     *      Inherited from OpenZeppelin Pausable.
     */
    function pause() public onlyOwner pausable {
        _pause();
    }

    /**
     * @dev Unpauses core contract operations. Only callable by the owner.
     *      Inherited from OpenZeppelin Pausable.
     */
    function unpause() public onlyOwner pausable {
        _unpause();
    }

    // --- III. Evo (Dynamic NFT) Management (ERC721) ---

    /**
     * @dev Mints a new "Evo" (ERC721 NFT) with initial metadata and traits.
     *      The `_initialTraitData` is expected to be a structured representation (e.g., JSON string encoded as bytes)
     *      that defines the initial traits of the Evo.
     * @param _initialMetadataURI Base URI for the Evo's metadata.
     * @param _initialTraitData Initial trait data (e.g., JSON bytes).
     * @return The ID of the newly minted Evo.
     */
    function mintEvo(string memory _initialMetadataURI, bytes memory _initialTraitData)
        public
        whenNotPaused
        returns (uint256)
    {
        _evoIds.increment();
        uint256 newEvoId = _evoIds.current();

        _safeMint(msg.sender, newEvoId);

        Evo storage newEvo = evos[newEvoId];
        newEvo.metadataURI = _initialMetadataURI;
        newEvo.traitMatrix["initial_traits"] = _initialTraitData; // Stores the initial traits
        newEvo.traitMatrix["current_traits"] = _initialTraitData; // Current traits start as initial
        newEvo.evolutionEpochs = 0;
        newEvo.isFractionalized = false;
        newEvo.status = EvoStatus.Active;
        newEvo.infusionCooldownDuration = infusionCooldownDefault;
        newEvo.infusionCharges = defaultInfusionCharges;

        emit EvoMinted(newEvoId, msg.sender, _initialMetadataURI);
        return newEvoId;
    }

    /**
     * @dev Triggers an evolution request for a specific Evo.
     *      This function sends a request to the configured AI oracle for new trait data.
     *      Only callable by the Evo's owner or a fractional shareholder.
     * @param _evoId The ID of the Evo to evolve.
     * @param _evolutionContext Contextual data for the AI oracle (e.g., user preferences, current environment data).
     */
    function requestEvoEvolution(uint256 _evoId, bytes memory _evolutionContext)
        public
        whenNotPaused
        onlyEvoOwnerOrShareholder(_evoId)
    {
        require(aiOracleAddress != address(0), "EAP: AI Oracle not set");
        require(evos[_evoId].status == EvoStatus.Active, "EAP: Evo not in active status for evolution");
        
        IAIOracle(aiOracleAddress).requestEvolution(_evoId, address(this), _evolutionContext);
        emit EvoEvolutionRequested(_evoId, _evolutionContext);
    }

    /**
     * @dev Callback function from the AI oracle to update an Evo's traits and metadata after an evolution.
     *      This function can only be called by the `aiOracleAddress`.
     * @param _evoId The ID of the Evo that evolved.
     * @param _newTraitData New trait data (e.g., JSON bytes representing updated traits).
     * @param _newMetadataURI New base URI for the Evo's metadata.
     */
    function fulfillEvoEvolution(uint256 _evoId, bytes memory _newTraitData, string memory _newMetadataURI)
        public
        whenNotPaused
        onlyAIOracle
    {
        Evo storage evo = evos[_evoId];
        // The Evo must be active to fulfill an AI-driven evolution.
        require(evo.status == EvoStatus.Active, "EAP: Evo not in active status for evolution fulfillment");
        
        evo.metadataURI = _newMetadataURI;
        evo.traitMatrix["current_traits"] = _newTraitData; // Overwrite "current_traits" with new data
        evo.evolutionEpochs++;

        emit EvoEvolved(_evoId, _newMetadataURI, _newTraitData);
    }

    /**
     * @dev Returns the current dynamic traits of an Evo.
     * @param _evoId The ID of the Evo.
     * @return The bytes representation of the current traits.
     */
    function getEvoTraits(uint256 _evoId) public view returns (bytes memory) {
        return evos[_evoId].traitMatrix["current_traits"];
    }

    /**
     * @dev Overrides ERC721's `tokenURI` to provide a dynamic metadata endpoint.
     *      The returned URI should point to a service that can dynamically generate
     *      the Evo's metadata JSON based on its current on-chain traits.
     * @param _tokenId The ID of the Evo NFT.
     * @return The URI for the Evo's metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = evos[_tokenId].metadataURI;
        // The frontend dApp would fetch this baseURI, then query `getEvoTraits` using the Evo ID
        // to construct the full metadata JSON (e.g., baseURI/123/dynamic.json).
        return string(abi.encodePacked(baseURI, _tokenId.toString(), "/dynamic.json"));
    }

    // --- IV. Fractionalization & Shares (ERC1155) ---

    /**
     * @dev Converts an Evo into a specified number of fractional ERC1155 shares.
     *      The original Evo NFT is transferred to this contract (locked) and becomes
     *      non-transferable until shares are merged back.
     * @param _evoId The ID of the Evo to fractionalize.
     * @param _shareSupply The total supply of fractional shares to mint.
     */
    function fractionalizeEvo(uint256 _evoId, uint256 _shareSupply) public whenNotPaused {
        require(_shareSupply > 0, "EAP: Share supply must be greater than zero");
        require(ownerOf(_evoId) == msg.sender, "EAP: Not Evo owner");
        require(!evos[_evoId].isFractionalized, "EAP: Evo already fractionalized");

        // Transfer Evo from current owner to this contract (locking it)
        _transfer(msg.sender, address(this), _evoId);

        // Mint ERC1155 shares to the msg.sender, using Evo ID as the ERC1155 token ID
        _mint(msg.sender, _evoId, _shareSupply, "");

        evos[_evoId].isFractionalized = true;
        evos[_evoId].shareSupply = _shareSupply;
        evos[_evoId].fractionalShareDeployer = msg.sender; // Record who initiated fractionalization

        emit EvoFractionalized(_evoId, msg.sender, _shareSupply);
    }

    /**
     * @dev Allows the owner of all fractional shares to burn them and regain full control of the original Evo NFT.
     *      The Evo must have been previously fractionalized.
     * @param _evoId The ID of the Evo to merge fractions for.
     */
    function mergeFractions(uint256 _evoId) public whenNotPaused {
        require(evos[_evoId].isFractionalized, "EAP: Evo not fractionalized");
        require(
            balanceOf(msg.sender, _evoId) == evos[_evoId].shareSupply,
            "EAP: Must own all fractional shares to merge"
        );

        // Burn all ERC1155 shares held by msg.sender
        _burn(msg.sender, _evoId, evos[_evoId].shareSupply);

        // Transfer Evo back from this contract to msg.sender
        _transfer(address(this), msg.sender, _evoId);

        evos[_evoId].isFractionalized = false;
        evos[_evoId].shareSupply = 0;
        evos[_evoId].fractionalShareDeployer = address(0);

        emit EvoFractionsMerged(_evoId, msg.sender);
    }

    /**
     * @dev Overrides ERC1155's `uri` for fractional share metadata.
     *      This allows fractional shares to have their own metadata or point to the parent Evo's.
     * @param _tokenId The ID of the fractional share (which is the Evo ID).
     * @return The URI for the fractional share's metadata.
     */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        // This can be adapted to return specific metadata for shares,
        // or link back to the Evo's metadata + denote it's a share.
        // For simplicity, it returns a generic share URI combining the base URI with the token ID.
        return string(abi.encodePacked(ERC1155._ERC1155_URI(), _tokenId.toString(), ".json"));
    }

    // --- V. IP Monetization & Revenue Distribution ---

    /**
     * @dev Allows external parties to pay licensing fees or royalties directly into an Evo's associated treasury.
     *      These funds are then distributable to fractional share owners or the Evo owner.
     * @param _evoId The ID of the Evo for which revenue is being paid.
     */
    function recordIPRevenue(uint256 _evoId) public payable whenNotPaused {
        require(_exists(_evoId), "EAP: Evo does not exist");
        require(msg.value > 0, "EAP: Must send ETH to record revenue");

        evoIpRevenueBalance[_evoId] += msg.value;
        emit IPRevenueRecorded(_evoId, msg.sender, msg.value);
    }

    /**
     * @dev Allows holders of fractional shares (or the Evo owner if not fractionalized)
     *      to claim their pro-rata portion of accumulated IP revenue for a specific Evo.
     * @param _evoId The ID of the Evo to claim revenue from.
     */
    function claimFractionalRevenue(uint256 _evoId) public whenNotPaused {
        require(_exists(_evoId), "EAP: Evo does not exist");

        uint256 totalRevenueInPool = evoIpRevenueBalance[_evoId];
        require(totalRevenueInPool > 0, "EAP: No revenue in pool for this Evo");

        uint256 totalSharesOrUnits; // Total units for proportional distribution
        uint256 claimantSharesOrUnits; // Units held by the claimant

        if (evos[_evoId].isFractionalized) {
            totalSharesOrUnits = evos[_evoId].shareSupply;
            claimantSharesOrUnits = balanceOf(msg.sender, _evoId);
            require(claimantSharesOrUnits > 0, "EAP: Caller does not own shares for this Evo");
        } else {
            // If not fractionalized, only the Evo owner can claim the full amount
            require(ownerOf(_evoId) == msg.sender, "EAP: Not Evo owner to claim revenue");
            totalSharesOrUnits = 1; // Treat as 1 unit for proportional calculation
            claimantSharesOrUnits = 1;
        }
        require(totalSharesOrUnits > 0, "EAP: Invalid total units for revenue distribution");
        
        // Calculate total potential claimable amount for this user based on their proportion
        uint256 totalClaimableForUser = (totalRevenueInPool * claimantSharesOrUnits) / totalSharesOrUnits;
        uint256 alreadyClaimedByUser = evoClaimedRevenue[_evoId][msg.sender];
        
        // Determine the amount to transfer now
        uint256 toTransfer = totalClaimableForUser - alreadyClaimedByUser;
        require(toTransfer > 0, "EAP: No new claimable revenue for this user");

        evoClaimedRevenue[_evoId][msg.sender] += toTransfer;
        payable(msg.sender).transfer(toTransfer);

        emit IPRevenueClaimed(_evoId, msg.sender, toTransfer);
    }

    // --- VI. Governance & DAO Mechanics ---

    /**
     * @dev Creates a DAO proposal for manually evolving an Evo's traits and metadata.
     *      Only callable by the Evo's owner or a fractional shareholder.
     * @param _evoId The ID of the Evo to propose evolution for.
     * @param _proposedNewTraits New trait data (e.g., JSON bytes).
     * @param _proposedNewMetadataURI New base URI for the Evo's metadata.
     * @param _voteDuration Duration (in seconds) for which the proposal will be open for voting.
     * @return The ID of the created proposal.
     */
    function createEvolutionProposal(
        uint256 _evoId,
        bytes memory _proposedNewTraits,
        string memory _proposedNewMetadataURI,
        uint256 _voteDuration
    ) public whenNotPaused onlyEvoOwnerOrShareholder(_evoId) returns (uint256) {
        require(_voteDuration > 0, "EAP: Vote duration must be positive");
        
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.evoId = _evoId;
        newProposal.proposalType = ProposalType.Evolution;
        newProposal.proposedNewTraits = _proposedNewTraits;
        newProposal.proposedNewMetadataURI = _proposedNewMetadataURI;
        newProposal.voteStartTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp + _voteDuration;
        newProposal.status = ProposalStatus.Active;
        newProposal.description = "Propose new traits for Evo " + _evoId.toString();

        activeProposals.add(proposalId);
        emit ProposalCreated(proposalId, _evoId, ProposalType.Evolution, msg.sender);
        return proposalId;
    }

    /**
     * @dev Creates a DAO proposal for allocating a grant from the Discovery Pool.
     *      Only callable by the Evo's owner or a fractional shareholder.
     * @param _evoId The ID of the Evo related to the grant (can be 0 if general protocol grant).
     * @param _amount The amount of ETH to be granted.
     * @param _recipient The address to receive the grant.
     * @param _reason A description for the grant.
     * @param _voteDuration Duration (in seconds) for which the proposal will be open for voting.
     * @return The ID of the created proposal.
     */
    function createDiscoveryGrantProposal(
        uint256 _evoId,
        uint256 _amount,
        address _recipient,
        string memory _reason,
        uint256 _voteDuration
    ) public whenNotPaused onlyEvoOwnerOrShareholder(_evoId) returns (uint256) {
        require(_amount > 0, "EAP: Grant amount must be positive");
        require(_recipient != address(0), "EAP: Recipient cannot be zero address");
        require(_voteDuration > 0, "EAP: Vote duration must be positive");
        
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.evoId = _evoId;
        newProposal.proposalType = ProposalType.DiscoveryGrant;
        newProposal.grantAmount = _amount;
        newProposal.grantRecipient = _recipient;
        newProposal.description = _reason;
        newProposal.voteStartTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp + _voteDuration;
        newProposal.status = ProposalStatus.Active;

        activeProposals.add(proposalId);
        emit ProposalCreated(proposalId, _evoId, ProposalType.DiscoveryGrant, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows Evo owners (or fractional shareholders) to vote on an active proposal.
     *      Voting power is proportional to the number of shares held for the Evo in question.
     *      If the Evo is not fractionalized, only the owner can vote (1 vote).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for" vote, false for "against" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "EAP: Proposal not active");
        require(block.timestamp <= proposal.voteEndTime, "EAP: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "EAP: Already voted on this proposal");

        uint256 evoId = proposal.evoId;
        uint256 votingPower;

        if (evos[evoId].isFractionalized) {
            votingPower = balanceOf(msg.sender, evoId);
            require(votingPower > 0, "EAP: No shares held for this Evo to vote");
        } else {
            // If not fractionalized, only the owner can vote with 1 power unit
            require(ownerOf(evoId) == msg.sender, "EAP: Not Evo owner to vote");
            votingPower = 1;
        }

        if (_support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @dev Executes a proposal if it has passed its voting period and met quorum/majority requirements.
     *      Anyone can call this function once the voting period has ended.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "EAP: Proposal not active");
        require(block.timestamp > proposal.voteEndTime, "EAP: Voting period not ended");
        require(!proposal.executed, "EAP: Proposal already executed");

        // Simple majority rule: For > Against. More complex DAOs would include quorum.
        if (proposal.forVotes > proposal.againstVotes) {
            proposal.status = ProposalStatus.Succeeded;
            proposal.executed = true;

            // Apply proposal effects
            if (proposal.proposalType == ProposalType.Evolution) {
                Evo storage evo = evos[proposal.evoId];
                evo.metadataURI = proposal.proposedNewMetadataURI;
                evo.traitMatrix["current_traits"] = proposal.proposedNewTraits;
                evo.evolutionEpochs++;
                emit EvoEvolved(proposal.evoId, proposal.proposedNewMetadataURI, proposal.proposedNewTraits);
            } else if (proposal.proposalType == ProposalType.DiscoveryGrant) {
                require(address(this).balance >= proposal.grantAmount, "EAP: Insufficient funds in Discovery Pool");
                payable(proposal.grantRecipient).transfer(proposal.grantAmount);
            }
            // Future: LicensingDeal type would trigger specific logic here
        } else {
            proposal.status = ProposalStatus.Failed;
        }
        activeProposals.remove(_proposalId);
        emit ProposalExecuted(_proposalId, proposal.status);
    }

    // --- VII. Synergy & Discovery Mechanisms ---

    /**
     * @dev Allows anyone to contribute funds to the EAP's Discovery Pool.
     *      These funds can be used for grants to support promising Evos or reward curators.
     */
    function depositDiscoveryPool() public payable whenNotPaused {
        require(msg.value > 0, "EAP: Must send ETH to deposit to Discovery Pool");
        // Funds are added to the contract's balance
        emit DiscoveryPoolDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to "curate" an Evo by staking a small amount.
     *      Curators provide social proof and can later be rewarded from the Discovery Pool
     *      if the Evo gains prominence or meets certain criteria.
     * @param _evoId The ID of the Evo to curate.
     */
    function curateEvo(uint256 _evoId) public payable whenNotPaused {
        require(_exists(_evoId), "EAP: Evo does not exist");
        require(msg.value >= curationStakeAmount, "EAP: Insufficient curation stake");
        
        curatorStakes[_evoId][msg.sender] += msg.value;
        emit EvoCurated(_evoId, msg.sender, msg.value);
    }

    /**
     * @dev Distributes a specific reward amount from the Discovery Pool to a named curator of an Evo.
     *      This function is callable by the contract owner, or via a successful DAO proposal.
     * @param _evoId The ID of the Evo the curator is associated with.
     * @param _curator The address of the curator to reward.
     * @param _amount The amount of ETH to reward.
     */
    function distributeCuratorReward(uint256 _evoId, address _curator, uint256 _amount) public onlyOwner whenNotPaused {
        require(_amount > 0, "EAP: Reward amount must be positive");
        require(_curator != address(0), "EAP: Curator address cannot be zero");
        require(curatorStakes[_evoId][_curator] > 0, "EAP: Recipient is not a curator for this Evo"); // Must have staked to be a curator
        require(address(this).balance >= _amount, "EAP: Insufficient funds in Discovery Pool");

        payable(_curator).transfer(_amount);
        emit CuratorRewardDistributed(_evoId, _curator, _amount);
    }

    /**
     * @dev A unique mechanism where a named trait from one Evo (source) can be "infused" (copied)
     *      into another Evo (target). The source Evo must be owned by the caller and has available
     *      infusion charges. After infusion, the source Evo enters a cooldown period.
     * @param _sourceEvoId The ID of the Evo from which to take a trait.
     * @param _targetEvoId The ID of the Evo to which the trait will be added.
     * @param _traitName The specific trait name to infuse (e.g., "color", "aura", "pattern").
     */
    function infuseTrait(uint256 _sourceEvoId, uint256 _targetEvoId, string memory _traitName)
        public
        whenNotPaused
    {
        // Require caller owns both source and target Evos for this simplified version.
        // A more complex system might allow infusion with approvals or different ownership.
        require(ownerOf(_sourceEvoId) == msg.sender, "EAP: Caller must own the source Evo");
        require(ownerOf(_targetEvoId) == msg.sender, "EAP: Caller must own the target Evo"); 

        Evo storage sourceEvo = evos[_sourceEvoId];
        Evo storage targetEvo = evos[_targetEvoId];

        require(_sourceEvoId != _targetEvoId, "EAP: Cannot infuse trait into itself");
        require(sourceEvo.infusionCharges > 0, "EAP: Source Evo has no infusion charges left");
        require(block.timestamp >= sourceEvo.lastInfusionTime + sourceEvo.infusionCooldownDuration, 
                "EAP: Source Evo is on infusion cooldown");
        
        bytes memory traitData = sourceEvo.traitMatrix[_traitName];
        require(traitData.length > 0, "EAP: Trait does not exist on source Evo");

        // Infuse trait into target Evo by copying the trait data
        targetEvo.traitMatrix[_traitName] = traitData;

        // Update source Evo's state
        sourceEvo.infusionCharges--;
        sourceEvo.lastInfusionTime = block.timestamp; // Reset cooldown

        if (sourceEvo.infusionCharges == 0) {
            _setEvoStatus(_sourceEvoId, EvoStatus.TraitDepleted); // Depleted after last charge
        } else {
            _setEvoStatus(_sourceEvoId, EvoStatus.InfusionCooling); // Enter cooldown
        }
        
        emit TraitInfused(_sourceEvoId, _targetEvoId, _traitName, msg.sender);
    }
    
    /**
     * @dev Allows the Evo owner or DAO to explicitly remove a specific trait from an Evo.
     * @param _evoId The ID of the Evo from which to remove the trait.
     * @param _traitName The specific trait name to remove.
     */
    function removeTrait(uint256 _evoId, string memory _traitName) public whenNotPaused onlyEvoOwnerOrShareholder(_evoId) {
        bytes memory currentTraitData = evos[_evoId].traitMatrix[_traitName];
        require(currentTraitData.length > 0, "EAP: Trait does not exist on this Evo");
        require(keccak256(abi.encodePacked(_traitName)) != keccak256(abi.encodePacked("initial_traits")), "EAP: Cannot remove initial_traits");
        require(keccak256(abi.encodePacked(_traitName)) != keccak256(abi.encodePacked("current_traits")), "EAP: Cannot remove current_traits directly");

        // Deleting from mapping sets bytes to empty (length 0)
        delete evos[_evoId].traitMatrix[_traitName];

        emit TraitRemoved(_evoId, _traitName, msg.sender);
    }

    /**
     * @dev Internal helper function to set a lifecycle status for an Evo.
     * @param _evoId The ID of the Evo to update.
     * @param _newStatus The new status for the Evo.
     */
    function _setEvoStatus(uint256 _evoId, EvoStatus _newStatus) internal {
        Evo storage evo = evos[_evoId];
        EvoStatus oldStatus = evo.status;
        if (oldStatus != _newStatus) {
            evo.status = _newStatus;
            emit EvoStatusUpdated(_evoId, oldStatus, _newStatus);
        }
    }

    /**
     * @dev Sets a lifecycle status for an Evo. Callable by contract owner, or via DAO proposal.
     * @param _evoId The ID of the Evo to update.
     * @param _newStatus The new status for the Evo.
     */
    function setEvoStatus(uint256 _evoId, EvoStatus _newStatus) public onlyOwner whenNotPaused {
        _setEvoStatus(_evoId, _newStatus);
    }

    // --- ERC721 Overrides (to prevent transfers when fractionalized) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        // Prevent direct transfer of a fractionalized Evo to anyone but this contract itself
        // (which happens only during fractionalization and merge operations).
        if (evos[tokenId].isFractionalized && from != address(this) && to != address(this)) {
            revert("EAP: Fractionalized Evo cannot be transferred directly");
        }
    }

    // --- ERC1155 Required Overrides ---
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        // No specific checks needed for fractional shares for now, but could add logic
        // to prevent transfers if Evo is in a certain status, etc.
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Ensure the contract can receive ETH (e.g., for Discovery Pool deposits)
    // Direct ETH transfers to the contract are considered deposits into the Discovery Pool.
    receive() external payable {
        emit DiscoveryPoolDeposited(msg.sender, msg.value); 
    }
}
```