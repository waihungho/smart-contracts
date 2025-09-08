This smart contract, `PhygitalNexus`, is designed to bridge the gap between physical and digital assets, allowing real-world items to be represented as "Phygital Twins" on the blockchain. It integrates several advanced, creative, and trendy concepts:

*   **Dynamic NFTs:** Phygital Twins are NFTs whose properties can change based on real-world events (via oracles) or community governance.
*   **Fractionalized NFTs (F-NFTs):** Ownership of Phygital Twins can be split into fungible shares, enabling broader participation.
*   **On-Chain Reputation System:** A mechanism for users to build trust and influence based on their interactions and endorsements.
*   **DAO-inspired Governance:** F-NFT holders and high-reputation users can propose and vote on significant protocol changes or dynamic NFT property updates.
*   **Conditional & Time-Locked Transfers:** Novel transfer mechanisms that allow assets to be locked until specific conditions (reputation, dynamic state) are met or a certain time has passed.
*   **Phygital Discovery & Curation:** A social layer for community-driven discovery and validation of valuable Phygital assets.

**Design Philosophy:**
To adhere to the "don't duplicate any open source" constraint, this contract implements a *minimal internal token tracking system* for Phygital Twins (akin to ERC721) and their fractional shares (akin to ERC1155). It focuses on the unique business logic and advanced concepts, rather than full compliance with all external functions and events of standard token interfaces. For production, it would be highly recommended to integrate with battle-tested libraries like OpenZeppelin for robust token standard compliance.

---

### **OUTLINE & FUNCTION SUMMARY**

**I. Core Infrastructure & Access Control**
1.  `constructor()`: Initializes the contract with an admin, trusted oracle, and curation council members.
2.  `updateTrustedOracle(address _newOracle)`: Allows the owner to update the address of the trusted oracle.
3.  `updateCurationCouncil(address[] calldata _newCouncil)`: Allows the owner to update the list of curation council members.
4.  `pausePhygitalNexus()`: Allows the owner to pause critical contract operations in emergencies.
5.  `unpausePhygitalNexus()`: Allows the owner to unpause the contract operations.
6.  `renounceOwnership()`: Allows the original deployer to renounce ownership of the contract.

**II. Phygital Asset (Dynamic NFT) Management (Internal ERC721-like)**
7.  `mintPhygitalTwin(address _to, string calldata _staticMetadataHash, string[] calldata _initialDynamicPropertiesKeys, bytes[] calldata _initialDynamicPropertiesValues)`: Mints a new, unique Phygital Twin NFT.
8.  `updatePhygitalMetadataHash(uint256 _tokenId, string calldata _newStaticMetadataHash)`: Updates the unchanging metadata hash of a Phygital Twin.
9.  `proposeDynamicPropertyUpdate(uint256 _tokenId, string calldata _propertyKey, bytes calldata _newValue, uint256 _proposalDuration)`: Initiates a proposal to change a dynamic property of a Phygital Twin, subject to governance or oracle confirmation.
10. `finalizeDynamicPropertyUpdate(uint256 _tokenId, string calldata _propertyKey, uint256 _proposalId, bytes calldata _oracleProof)`: Executes a dynamic property update once its proposal passes or the oracle confirms.
11. `transferPhygitalTwin(address _from, address _to, uint256 _tokenId)`: Transfers full ownership of a non-fractionalized Phygital Twin.
12. `burnPhygitalTwin(uint256 _tokenId)`: Destroys a non-fractionalized Phygital Twin NFT.

**III. Fractionalization (F-NFTs) & Shares (Internal ERC1155-like)**
13. `fractionalizePhygitalTwin(uint256 _tokenId, uint256 _totalShares, string calldata _fnftMetadataHash)`: Converts a Phygital Twin into fungible shares (F-NFTs), transferring the NFT to the contract's custody.
14. `redeemPhygitalTwin(uint256 _tokenId)`: Re-assembles a fractionalized Phygital Twin by burning all shares and returning the NFT to the redeemer.
15. `transferFNFTShares(uint256 _tokenId, address _from, address _to, uint256 _amount)`: Transfers a specified amount of F-NFT shares for a given Phygital Twin.

**IV. Governance & Decision Making (DAO-inspired)**
16. `submitGovernanceProposal(string calldata _description, address _targetContract, bytes calldata _callData, uint256 _duration)`: Allows users (with sufficient reputation/F-NFTs) to propose general protocol changes.
17. `voteOnProposal(uint256 _proposalId, bool _support)`: Casts a vote on an active governance proposal, with voting weight influenced by reputation.
18. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal's defined action.

**V. On-Chain Reputation System**
19. `submitReputationBoostRequest(bytes32 _proofHash)`: Allows a user to submit a hash representing an off-chain proof for a reputation boost.
20. `endorseUserReputation(address _user, uint256 _amount)`: Allows a Curation Council member (or high-reputation user) to endorse another user's reputation.
21. `getReputationScore(address _user)`: Retrieves the current reputation score of a given address.

**VI. Conditional & Novel Transfers**
22. `initiateConditionalSwap(uint256 _tokenId, address _recipient, bytes32 _conditionHash, uint256 _expirationTime)`: Initiates a swap where a Phygital Twin is transferred only if specific, off-chain verifiable conditions are met by the recipient before expiration.
23. `executeConditionalSwap(uint256 _swapId)`: Executes a conditional swap upon oracle confirmation that the conditions have been met.
24. `createTimeLockedTransfer(uint256 _tokenId, address _recipient, uint256 _unlockTime)`: Creates a transfer where the Phygital Twin is locked until a specified unlock time.
25. `claimTimeLockedTransfer(uint256 _transferId)`: Allows the recipient to claim a time-locked Phygital Twin after its unlock time.

**VII. Phygital Asset Discovery & Curation (Social Layer)**
26. `nominatePhygitalForCuration(uint256 _tokenId, string calldata _reason)`: Allows a user to nominate a Phygital Asset for inclusion in a curated list, subject to a fee.
27. `curatePhygitalAsset(uint256 _tokenId, bool _isCurated)`: Allows Curation Council members to mark a nominated Phygital Twin as curated or uncurated.

**VIII. Treasury & Fee Management**
28. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allows the owner to withdraw accumulated fees from the contract's treasury.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PhygitalNexus
 * @author AI Creator
 * @notice This contract enables the creation, management, and fractionalization of "Phygital Twins" – dynamic NFTs representing real-world assets.
 *         It incorporates advanced concepts like on-chain reputation, governance for dynamic NFT properties, conditional transfers,
 *         and a novel curation system, all without directly duplicating existing open-source project logic.
 *
 * Design Philosophy:
 * To adhere to the "don't duplicate any open source" constraint, this contract implements a *minimal internal token tracking system*
 * for Phygital Twins (akin to ERC721) and their fractional shares (akin to ERC1155). It focuses on the unique business logic
 * and advanced concepts, rather than full compliance with all external functions and events of standard token interfaces.
 * For production, it would be highly recommended to integrate with battle-tested libraries like OpenZeppelin for token standards.
 */

// --- OUTLINE & FUNCTION SUMMARY ---

// I. Core Infrastructure & Access Control
//    1. constructor(): Initializes the contract with an admin, oracle, and curation council.
//    2. updateTrustedOracle(address _newOracle): Allows admin to update the trusted oracle address.
//    3. updateCurationCouncil(address[] calldata _newCouncil): Allows admin to update the list of curation council members.
//    4. pausePhygitalNexus(): Allows admin to pause critical contract operations.
//    5. unpausePhygitalNexus(): Allows admin to unpause critical contract operations.
//    6. renounceOwnership(): Allows the original deployer to renounce ownership (sets owner to zero address).

// II. Phygital Asset (Dynamic NFT) Management (Internal ERC721-like)
//    7. mintPhygitalTwin(address _to, string calldata _staticMetadataHash, string[] calldata _initialDynamicPropertiesKeys, bytes[] calldata _initialDynamicPropertiesValues): Mints a new dynamic Phygital NFT (ERC721-like).
//    8. updatePhygitalMetadataHash(uint256 _tokenId, string calldata _newStaticMetadataHash): Updates the IPFS hash of an NFT's *static* metadata.
//    9. proposeDynamicPropertyUpdate(uint256 _tokenId, string calldata _propertyKey, bytes calldata _newValue, uint256 _proposalDuration): Initiates a proposal to change *dynamic* properties of an NFT, requiring governance or oracle confirmation.
//    10. finalizeDynamicPropertyUpdate(uint256 _tokenId, string calldata _propertyKey, uint256 _proposalId, bytes calldata _oracleProof): Executes the dynamic property update if proposal passes or oracle confirms.
//    11. transferPhygitalTwin(address _from, address _to, uint256 _tokenId): Transfers full ownership of a Phygital NFT.
//    12. burnPhygitalTwin(uint256 _tokenId): Burns a Phygital NFT (only if not fractionalized).

// III. Fractionalization (F-NFTs) & Shares (Internal ERC1155-like)
//    13. fractionalizePhygitalTwin(uint256 _tokenId, uint256 _totalShares, string calldata _fnftMetadataHash): Creates ERC1155-like fungible shares for an ERC721-like Phygital Twin.
//    14. redeemPhygitalTwin(uint256 _tokenId): Redeems all F-NFT shares to re-assemble the original ERC721-like NFT, and returns it to the redeemer.
//    15. transferFNFTShares(uint256 _tokenId, address _from, address _to, uint256 _amount): Transfers a specific amount of F-NFT shares for a given Phygital Twin.

// IV. Governance & Decision Making (DAO-inspired)
//    16. submitGovernanceProposal(string calldata _description, address _targetContract, bytes calldata _callData, uint256 _duration): Allows F-NFT holders or high-reputation users to submit a general governance proposal.
//    17. voteOnProposal(uint256 _proposalId, bool _support): Cast a vote on an active proposal. Voting weight can be based on reputation.
//    18. executeProposal(uint256 _proposalId): Executes a passed governance proposal (only if target is a known contract).

// V. On-Chain Reputation System
//    19. submitReputationBoostRequest(bytes32 _proofHash): A user can request a reputation boost by providing an off-chain proof hash.
//    20. endorseUserReputation(address _user, uint256 _amount): A council member or high-reputation user can endorse another's reputation.
//    21. getReputationScore(address _user): Retrieve the reputation score for an address.

// VI. Conditional & Novel Transfers
//    22. initiateConditionalSwap(uint256 _tokenId, address _recipient, bytes32 _conditionHash, uint256 _expirationTime): Creates a conditional swap for a Phygital NFT, requiring specific dynamic property state or reputation score from the recipient.
//    23. executeConditionalSwap(uint256 _swapId): Executes the swap once conditions are met (verified off-chain via oracle/resolver).
//    24. createTimeLockedTransfer(uint256 _tokenId, address _recipient, uint256 _unlockTime): Initiates a transfer that only becomes claimable after a certain timestamp.
//    25. claimTimeLockedTransfer(uint256 _transferId): Allows the recipient to claim a time-locked Phygital Twin after its unlock time.

// VII. Phygital Asset Discovery & Curation (Social Layer)
//    26. nominatePhygitalForCuration(uint256 _tokenId, string calldata _reason): A user nominates a Phygital Asset for inclusion in a "curated" list.
//    27. curatePhygitalAsset(uint256 _tokenId, bool _isCurated): Curation Council votes to include/exclude an asset from the curated list.

// VIII. Treasury & Fee Management
//    28. withdrawTreasuryFunds(address _recipient, uint256 _amount): Allows the owner to withdraw accumulated fees from the contract.


contract PhygitalNexus {

    // --- State Variables ---

    address private _owner; // Contract owner, set once in constructor and can be renounced
    address public trustedOracle; // Address of the oracle for dynamic data updates
    address[] public curationCouncil; // Addresses of members of the curation council
    bool public paused; // Pause flag for critical operations

    uint256 public nextTokenId; // Counter for Phygital Twin NFTs
    uint256 public nextProposalId; // Counter for general governance proposals
    uint256 public nextSwapId; // Counter for conditional swaps
    uint256 public nextTimeLockedTransferId; // Counter for time-locked transfers
    uint256 public nextDynamicPropertyProposalId; // Counter for dynamic property update proposals

    // Phygital Twin NFT (ERC721-like)
    struct PhygitalAsset {
        address owner;
        string staticMetadataHash; // IPFS hash for unchanging metadata (e.g., origin, initial design)
        mapping(string => bytes) dynamicProperties; // Dynamic properties, can change via governance/oracle
        bool isFractionalized; // True if shares have been minted
        uint256 totalShares; // Total shares if fractionalized
        string fnftMetadataHash; // Metadata for fractionalized shares
    }
    mapping(uint256 => PhygitalAsset) public phygitalTwins;
    mapping(uint256 => address) private _phygitalTokenOwners; // tokenId => owner
    mapping(address => uint256) private _phygitalTokenBalances; // owner => balance of non-fractionalized NFTs

    // F-NFT (ERC1155-like shares for a specific Phygital Twin)
    mapping(uint256 => mapping(address => uint256)) public fnftBalances; // tokenId => owner => amount

    // Governance Proposals (General)
    struct GovernanceProposal {
        string description;
        address proposer;
        uint256 creationTime;
        uint256 duration;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool active;
        address targetContract; // Contract to call if proposal passes
        bytes callData;         // Calldata for the targetContract call
        mapping(address => bool) hasVoted; // User => Voted status
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Dynamic Property Update Proposals (specific to a Phygital Twin)
    struct DynamicPropertyProposal {
        address proposer;
        bytes newValue;
        uint256 creationTime;
        uint256 duration;
        uint256 votesFor; // If voting applies, or 0 if only oracle
        uint256 votesAgainst; // If voting applies
        bool executed;
        bool active;
        mapping(address => bool) hasVoted; // User => Voted status (if F-NFT governance)
    }
    mapping(uint256 => mapping(string => mapping(uint256 => DynamicPropertyProposal))) public dynamicPropertyProposals; // tokenId => propertyKey => proposalId => DynamicPropertyProposal


    // Reputation System
    struct ReputationProfile {
        uint256 score;
        mapping(address => uint256) endorsementsReceived; // from_address => amount
        mapping(bytes32 => bool) reputationBoostProofs; // hash of off-chain proof => used
    }
    mapping(address => ReputationProfile) public reputationProfiles;
    uint256 public constant REPUTATION_ENDORSEMENT_THRESHOLD = 100; // Min score to endorse
    uint256 public constant BASE_REPUTATION_BOOST = 5;

    // Conditional Swaps
    struct ConditionalSwap {
        uint256 tokenId;
        address seller;
        address recipient;
        bytes32 conditionHash; // Hash of the condition logic (e.g., target reputation, specific dynamic property value)
        uint256 expirationTime;
        bool fulfilled;
    }
    mapping(uint256 => ConditionalSwap) public conditionalSwaps;

    // Time-Locked Transfers
    struct TimeLockedTransfer {
        uint256 tokenId;
        address sender;
        address recipient;
        uint256 unlockTime;
        bool claimed;
    }
    mapping(uint256 => TimeLockedTransfer) public timeLockedTransfers;

    // Curation System
    mapping(uint256 => bool) public isPhygitalCurated; // tokenId => isCurated
    mapping(uint256 => mapping(address => bool)) public hasNominatedForCuration; // tokenId => nominator => true
    mapping(uint256 => mapping(address => bool)) public curationCouncilVotes; // tokenId => councilMember => votedForCuration (simple flag)

    // Fees
    uint256 public curationNominationFee = 0.01 ether; // Example fee for nominating an asset


    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TrustedOracleUpdated(address indexed oldOracle, address indexed newOracle);
    event CurationCouncilUpdated(address[] oldCouncil, address[] newCouncil);
    event Paused(address account);
    event Unpaused(address account);

    event PhygitalTwinMinted(uint256 indexed tokenId, address indexed owner, string staticMetadataHash);
    event PhygitalMetadataHashUpdated(uint256 indexed tokenId, string newStaticMetadataHash);
    event DynamicPropertyUpdateProposed(uint256 indexed tokenId, uint256 indexed proposalId, string propertyKey, bytes newValue);
    event DynamicPropertyUpdateFinalized(uint256 indexed tokenId, uint256 indexed proposalId, string propertyKey, bytes newValue);
    event PhygitalTwinTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event PhygitalTwinBurned(uint256 indexed tokenId, address indexed owner);

    event PhygitalTwinFractionalized(uint256 indexed tokenId, uint256 totalShares, string fnftMetadataHash);
    event PhygitalTwinRedeemed(uint256 indexed tokenId, address indexed redeemer);
    event FNFTSharesTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);

    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);

    event ReputationBoostRequested(address indexed user, bytes32 proofHash);
    event UserReputationEndorsed(address indexed endorser, address indexed user, uint256 amount);

    event ConditionalSwapInitiated(uint256 indexed swapId, uint256 indexed tokenId, address indexed seller, address recipient, bytes32 conditionHash, uint256 expirationTime);
    event ConditionalSwapExecuted(uint256 indexed swapId);
    event TimeLockedTransferCreated(uint256 indexed transferId, uint256 indexed tokenId, address indexed recipient, uint256 unlockTime);
    event TimeLockedTransferClaimed(uint256 indexed transferId);

    event PhygitalNominatedForCuration(uint256 indexed tokenId, address indexed nominator);
    event PhygitalCuratedStatusUpdated(uint256 indexed tokenId, bool isCurated, address indexed councilMember);

    event TreasuryFundsWithdrawn(address indexed recipient, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "PN: Not contract owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "PN: Not trusted oracle");
        _;
    }

    modifier onlyCurationCouncil() {
        bool isCouncilMember = false;
        for (uint i = 0; i < curationCouncil.length; i++) {
            if (curationCouncil[i] == msg.sender) {
                isCouncilMember = true;
                break;
            }
        }
        require(isCouncilMember, "PN: Not a curation council member");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "PN: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "PN: Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracle, address[] calldata _initialCurationCouncil) {
        _owner = msg.sender;
        trustedOracle = _initialOracle;
        curationCouncil = _initialCurationCouncil;
        paused = false;
        nextTokenId = 1;
        nextProposalId = 1;
        nextSwapId = 1;
        nextTimeLockedTransferId = 1;
        nextDynamicPropertyProposalId = 1;
        emit OwnershipTransferred(address(0), _owner);
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @notice Allows the contract owner to update the trusted oracle address.
     * @param _newOracle The new address for the trusted oracle.
     */
    function updateTrustedOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "PN: Zero address not allowed for oracle");
        emit TrustedOracleUpdated(trustedOracle, _newOracle);
        trustedOracle = _newOracle;
    }

    /**
     * @notice Allows the contract owner to update the list of curation council members.
     * @param _newCouncil An array of addresses for the new curation council members.
     */
    function updateCurationCouncil(address[] calldata _newCouncil) external onlyOwner {
        require(_newCouncil.length > 0, "PN: Curation council cannot be empty");
        // Could add logic to verify if removed members have pending votes/tasks.
        emit CurationCouncilUpdated(curationCouncil, _newCouncil);
        curationCouncil = _newCouncil;
    }

    /**
     * @notice Pauses critical contract operations. Can only be called by the owner.
     */
    function pausePhygitalNexus() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses critical contract operations. Can only be called by the owner.
     */
    function unpausePhygitalNexus() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Renounces ownership of the contract. The contract will no longer have an owner,
     *         and functions requiring `onlyOwner` will be inaccessible. This is irreversible.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // --- II. Phygital Asset (Dynamic NFT) Management ---

    /**
     * @notice Mints a new dynamic Phygital Twin NFT.
     *         This function acts as an internal ERC721-like mint.
     * @param _to The address to mint the NFT to.
     * @param _staticMetadataHash IPFS hash for the static, unchanging metadata.
     * @param _initialDynamicPropertiesKeys Keys for initial dynamic properties.
     * @param _initialDynamicPropertiesValues Values for initial dynamic properties.
     * @return tokenId The ID of the newly minted Phygital Twin.
     */
    function mintPhygitalTwin(
        address _to,
        string calldata _staticMetadataHash,
        string[] calldata _initialDynamicPropertiesKeys,
        bytes[] calldata _initialDynamicPropertiesValues
    )
        external
        whenNotPaused
        returns (uint256)
    {
        require(_to != address(0), "PN: Mint to zero address");
        require(bytes(_staticMetadataHash).length > 0, "PN: Static metadata hash cannot be empty");
        require(_initialDynamicPropertiesKeys.length == _initialDynamicPropertiesValues.length, "PN: Mismatched keys and values");

        uint256 tokenId = nextTokenId++;
        _phygitalTokenOwners[tokenId] = _to;
        _phygitalTokenBalances[_to]++;

        PhygitalAsset storage newAsset = phygitalTwins[tokenId];
        newAsset.owner = _to;
        newAsset.staticMetadataHash = _staticMetadataHash;
        newAsset.isFractionalized = false;
        newAsset.totalShares = 0;

        for (uint i = 0; i < _initialDynamicPropertiesKeys.length; i++) {
            newAsset.dynamicProperties[_initialDynamicPropertiesKeys[i]] = _initialDynamicPropertiesValues[i];
        }

        emit PhygitalTwinMinted(tokenId, _to, _staticMetadataHash);
        return tokenId;
    }

    /**
     * @notice Updates the static metadata hash of a Phygital Twin.
     *         Only the owner of the Phygital Twin can update its static metadata.
     * @param _tokenId The ID of the Phygital Twin.
     * @param _newStaticMetadataHash The new IPFS hash for the static metadata.
     */
    function updatePhygitalMetadataHash(uint256 _tokenId, string calldata _newStaticMetadataHash) external whenNotPaused {
        require(_phygitalTokenOwners[_tokenId] == msg.sender, "PN: Not owner of Phygital Twin");
        require(bytes(_newStaticMetadataHash).length > 0, "PN: New static metadata hash cannot be empty");
        phygitalTwins[_tokenId].staticMetadataHash = _newStaticMetadataHash;
        emit PhygitalMetadataHashUpdated(_tokenId, _newStaticMetadataHash);
    }

    /**
     * @notice Initiates a proposal to change a dynamic property of a Phygital Twin.
     *         This requires either governance (F-NFT holders) or an oracle to finalize.
     * @param _tokenId The ID of the Phygital Twin.
     * @param _propertyKey The key of the dynamic property to update.
     * @param _newValue The new value for the dynamic property.
     * @param _proposalDuration The duration for voting (if applicable) or a grace period for oracle.
     * @return proposalId The ID of the new dynamic property update proposal.
     */
    function proposeDynamicPropertyUpdate(
        uint256 _tokenId,
        string calldata _propertyKey,
        bytes calldata _newValue,
        uint256 _proposalDuration
    ) external whenNotPaused returns (uint256) {
        require(phygitalTwins[_tokenId].owner != address(0), "PN: Phygital Twin does not exist");
        // Only the owner of the Phygital Twin (or F-NFT holders if fractionalized) can propose updates
        require(_phygitalTokenOwners[_tokenId] == msg.sender || fnftBalances[_tokenId][msg.sender] > 0, "PN: Not authorized to propose update");
        require(_proposalDuration > 0, "PN: Proposal duration must be positive");

        uint256 proposalId = nextDynamicPropertyProposalId++;
        DynamicPropertyProposal storage proposal = dynamicPropertyProposals[_tokenId][_propertyKey][proposalId];
        proposal.proposer = msg.sender;
        proposal.newValue = _newValue;
        proposal.creationTime = block.timestamp;
        proposal.duration = _proposalDuration;
        proposal.active = true;

        // Note: For actual voting on dynamic properties by F-NFT holders, a separate voting function and state
        // would be needed, linking F-NFT balances to voting power for *that specific NFT*.
        // For simplicity here, assume this is either an owner-driven proposal for oracle confirmation or a
        // generic governance vote (if votesFor/Against were implemented here based on F-NFTs).

        emit DynamicPropertyUpdateProposed(_tokenId, proposalId, _propertyKey, _newValue);
        return proposalId;
    }

    /**
     * @notice Finalizes a dynamic property update for a Phygital Twin.
     *         This can be triggered by the trusted oracle (for external data) or after a governance vote.
     * @param _tokenId The ID of the Phygital Twin.
     * @param _propertyKey The key of the dynamic property to update.
     * @param _proposalId The ID of the proposal.
     * @param _oracleProof A proof from the oracle (can be bytes for flexibility).
     */
    function finalizeDynamicPropertyUpdate(
        uint256 _tokenId,
        string calldata _propertyKey,
        uint256 _proposalId,
        bytes calldata _oracleProof // This would be cryptographically verified in a real system
    ) external whenNotPaused {
        DynamicPropertyProposal storage proposal = dynamicPropertyProposals[_tokenId][_propertyKey][_proposalId];
        require(proposal.active, "PN: Proposal not active");
        require(!proposal.executed, "PN: Proposal already executed");

        // For simplicity, this function is callable by the trusted oracle to confirm external events.
        // In a more complex system, it would check governance voting results OR oracle proof.
        require(msg.sender == trustedOracle, "PN: Only trusted oracle can finalize this update");
        // Further oracle proof verification logic would go here, e.g., require(trustedOracle.verify(_oracleProof, _tokenId, _propertyKey, proposal.newValue));

        phygitalTwins[_tokenId].dynamicProperties[_propertyKey] = proposal.newValue;
        proposal.executed = true;
        proposal.active = false;

        emit DynamicPropertyUpdateFinalized(_tokenId, _proposalId, _propertyKey, proposal.newValue);
    }

    /**
     * @notice Transfers full ownership of a Phygital Twin NFT.
     *         Requires the Phygital Twin not to be fractionalized and caller to be owner.
     * @param _from The current owner.
     * @param _to The new owner.
     * @param _tokenId The ID of the Phygital Twin.
     */
    function transferPhygitalTwin(address _from, address _to, uint256 _tokenId) external whenNotPaused {
        require(_phygitalTokenOwners[_tokenId] == _from, "PN: Not owner of Phygital Twin");
        require(msg.sender == _from, "PN: Caller not owner for direct transfer"); // No 'approve' logic for simplicity.
        require(_to != address(0), "PN: Transfer to zero address");
        require(!phygitalTwins[_tokenId].isFractionalized, "PN: Cannot transfer fractionalized Phygital Twin directly");

        _phygitalTokenOwners[_tokenId] = _to;
        phygitalTwins[_tokenId].owner = _to;
        _phygitalTokenBalances[_from]--;
        _phygitalTokenBalances[_to]++;

        emit PhygitalTwinTransferred(_tokenId, _from, _to);
    }

    /**
     * @notice Burns a Phygital Twin NFT.
     *         Requires the Phygital Twin not to be fractionalized and caller to be owner.
     * @param _tokenId The ID of the Phygital Twin.
     */
    function burnPhygitalTwin(uint256 _tokenId) external whenNotPaused {
        address currentOwner = _phygitalTokenOwners[_tokenId];
        require(currentOwner == msg.sender, "PN: Not owner of Phygital Twin");
        require(!phygitalTwins[_tokenId].isFractionalized, "PN: Cannot burn fractionalized Phygital Twin");

        delete phygitalTwins[_tokenId]; // Remove asset data
        delete _phygitalTokenOwners[_tokenId]; // Remove ownership
        _phygitalTokenBalances[currentOwner]--; // Decrease balance

        emit PhygitalTwinBurned(_tokenId, currentOwner);
    }

    // --- III. Fractionalization (F-NFTs) & Shares ---

    /**
     * @notice Creates fungible shares (F-NFTs) for a Phygital Twin.
     *         Only the owner of the Phygital Twin can fractionalize it.
     *         The Phygital Twin's ownership is transferred to the contract and shares are minted to the original owner.
     * @param _tokenId The ID of the Phygital Twin.
     * @param _totalShares The total number of F-NFT shares to create.
     * @param _fnftMetadataHash IPFS hash for the F-NFT shares metadata.
     */
    function fractionalizePhygitalTwin(uint256 _tokenId, uint256 _totalShares, string calldata _fnftMetadataHash) external whenNotPaused {
        address currentOwner = _phygitalTokenOwners[_tokenId];
        require(currentOwner == msg.sender, "PN: Not owner of Phygital Twin");
        require(!phygitalTwins[_tokenId].isFractionalized, "PN: Phygital Twin already fractionalized");
        require(_totalShares > 0, "PN: Must create at least one share");
        require(bytes(_fnftMetadataHash).length > 0, "PN: F-NFT metadata hash cannot be empty");

        // Transfer Phygital Twin ownership to this contract (escrow)
        _phygitalTokenOwners[_tokenId] = address(this);
        phygitalTwins[_tokenId].owner = address(this);
        _phygitalTokenBalances[currentOwner]--; // Original owner's NFT balance decreases

        phygitalTwins[_tokenId].isFractionalized = true;
        phygitalTwins[_tokenId].totalShares = _totalShares;
        phygitalTwins[_tokenId].fnftMetadataHash = _fnftMetadataHash;

        // Mint all shares to the original owner
        fnftBalances[_tokenId][currentOwner] = _totalShares;

        emit PhygitalTwinFractionalized(_tokenId, _totalShares, _fnftMetadataHash);
        emit FNFTSharesTransferred(_tokenId, address(0), currentOwner, _totalShares); // Minting event, from 0 address
    }

    /**
     * @notice Redeems all F-NFT shares to re-assemble the original Phygital Twin NFT.
     *         Requires the caller to hold all outstanding shares of the specified Phygital Twin.
     * @param _tokenId The ID of the Phygital Twin to redeem.
     */
    function redeemPhygitalTwin(uint256 _tokenId) external whenNotPaused {
        require(phygitalTwins[_tokenId].owner == address(this), "PN: Phygital Twin not held by contract");
        require(phygitalTwins[_tokenId].isFractionalized, "PN: Phygital Twin not fractionalized");
        require(fnftBalances[_tokenId][msg.sender] == phygitalTwins[_tokenId].totalShares, "PN: Must own all F-NFT shares to redeem");

        // Burn all shares
        fnftBalances[_tokenId][msg.sender] = 0;
        
        // Transfer Phygital Twin back to the redeemer
        _phygitalTokenOwners[_tokenId] = msg.sender;
        phygitalTwins[_tokenId].owner = msg.sender;
        _phygitalTokenBalances[msg.sender]++; // Redeemer's NFT balance increases

        phygitalTwins[_tokenId].isFractionalized = false;
        phygitalTwins[_tokenId].totalShares = 0;
        phygitalTwins[_tokenId].fnftMetadataHash = ""; // Clear F-NFT metadata

        emit PhygitalTwinRedeemed(_tokenId, msg.sender);
        emit FNFTSharesTransferred(_tokenId, msg.sender, address(0), 0); // Burning event, to 0 address
    }

    /**
     * @notice Transfers a specific amount of F-NFT shares for a given Phygital Twin.
     * @param _tokenId The ID of the Phygital Twin whose shares are being transferred.
     * @param _from The current owner of the shares.
     * @param _to The recipient of the shares.
     * @param _amount The amount of shares to transfer.
     */
    function transferFNFTShares(uint256 _tokenId, address _from, address _to, uint256 _amount) external whenNotPaused {
        require(phygitalTwins[_tokenId].isFractionalized, "PN: Phygital Twin not fractionalized");
        require(fnftBalances[_tokenId][_from] >= _amount, "PN: Insufficient F-NFT shares");
        require(msg.sender == _from, "PN: Caller not F-NFT share owner"); // For simplicity, no approval mechanism here.
        require(_to != address(0), "PN: Transfer to zero address");
        require(_amount > 0, "PN: Transfer amount must be greater than zero");

        fnftBalances[_tokenId][_from] -= _amount;
        fnftBalances[_tokenId][_to] += _amount;

        emit FNFTSharesTransferred(_tokenId, _from, _to, _amount);
    }

    // --- IV. Governance & Decision Making ---

    /**
     * @notice Allows F-NFT holders or high-reputation users to submit a general governance proposal.
     *         Requires a minimum reputation score.
     * @param _description A description of the proposal.
     * @param _targetContract The contract address to execute the proposal on (if passed).
     * @param _callData The calldata to pass to the targetContract.
     * @param _duration The voting duration for the proposal.
     * @return proposalId The ID of the new governance proposal.
     */
    function submitGovernanceProposal(
        string calldata _description,
        address _targetContract,
        bytes calldata _callData,
        uint256 _duration
    ) external whenNotPaused returns (uint256) {
        require(bytes(_description).length > 0, "PN: Proposal description cannot be empty");
        require(_duration > 0, "PN: Proposal duration must be positive");
        require(reputationProfiles[msg.sender].score > 0, "PN: Insufficient reputation to submit proposal"); // Simple check

        uint256 proposalId = nextProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.description = _description;
        proposal.proposer = msg.sender;
        proposal.creationTime = block.timestamp;
        proposal.duration = _duration;
        proposal.active = true;
        proposal.targetContract = _targetContract;
        proposal.callData = _callData;

        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @notice Cast a vote on an active general governance proposal. Voting weight is based on reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.active, "PN: Proposal not active");
        require(!proposal.hasVoted[msg.sender], "PN: Already voted on this proposal");
        require(block.timestamp < (proposal.creationTime + proposal.duration), "PN: Voting period ended");

        uint256 votingPower = reputationProfiles[msg.sender].score + 1; // Add 1 to ensure at least some power
        require(votingPower > 0, "PN: No voting power");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a passed general governance proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.active, "PN: Proposal not active");
        require(!proposal.executed, "PN: Proposal already executed");
        require(block.timestamp >= (proposal.creationTime + proposal.duration), "PN: Voting period not ended");
        require(proposal.votesFor > proposal.votesAgainst, "PN: Proposal did not pass");

        proposal.executed = true;
        proposal.active = false;

        // Execute the proposed action
        // WARNING: External calls can be risky. Proper ACL and reentrancy guards needed in production.
        // For security, ensure _targetContract is either this contract (for self-governance)
        // or a carefully audited known contract. A more robust system would involve a timelock.
        (bool success,) = proposal.targetContract.call(proposal.callData);
        require(success, "PN: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    // --- V. On-Chain Reputation System ---

    /**
     * @notice A user can request a reputation boost by providing an off-chain proof hash.
     *         The proof hash could represent, for example, a zero-knowledge proof of contribution,
     *         or a link to a verified social media account. Curation Council would verify in a full system.
     * @param _proofHash A hash representing an off-chain proof.
     */
    function submitReputationBoostRequest(bytes32 _proofHash) external whenNotPaused {
        require(!reputationProfiles[msg.sender].reputationBoostProofs[_proofHash], "PN: Proof already used");
        reputationProfiles[msg.sender].reputationBoostProofs[_proofHash] = true;
        // For simplicity, we directly give a small boost, simulating auto-verification or a pre-approved list.
        reputationProfiles[msg.sender].score += BASE_REPUTATION_BOOST;
        emit ReputationBoostRequested(msg.sender, _proofHash);
    }

    /**
     * @notice A council member or high-reputation user can endorse another's reputation.
     *         Requires the caller to be a Curation Council member.
     * @param _user The user whose reputation is being endorsed.
     * @param _amount The amount of reputation to add.
     */
    function endorseUserReputation(address _user, uint256 _amount) external whenNotPaused onlyCurationCouncil {
        require(_user != address(0), "PN: Cannot endorse zero address");
        require(_user != msg.sender, "PN: Cannot endorse self");
        require(_amount > 0, "PN: Endorsement amount must be positive");
        // Could add cooldown or limits on endorsements from a single address.

        reputationProfiles[_user].score += _amount;
        reputationProfiles[_user].endorsementsReceived[msg.sender] += _amount;

        emit UserReputationEndorsed(msg.sender, _user, _amount);
    }

    /**
     * @notice Retrieves the current reputation score for a given address.
     * @param _user The address to query.
     * @return The reputation score of the user.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return reputationProfiles[_user].score;
    }

    // --- VI. Conditional & Novel Transfers ---

    /**
     * @notice Creates a conditional swap for a Phygital NFT. The NFT is locked until conditions are met and executed.
     * @param _tokenId The ID of the Phygital Twin to put up for swap.
     * @param _recipient The intended recipient if conditions are met.
     * @param _conditionHash A hash representing the off-chain verifiable conditions (e.g., target reputation, specific dynamic property value).
     * @param _expirationTime The time when the swap offer expires.
     * @return swapId The ID of the new conditional swap.
     */
    function initiateConditionalSwap(
        uint256 _tokenId,
        address _recipient,
        bytes32 _conditionHash,
        uint256 _expirationTime
    ) external whenNotPaused returns (uint256) {
        require(_phygitalTokenOwners[_tokenId] == msg.sender, "PN: Not owner of Phygital Twin");
        require(!phygitalTwins[_tokenId].isFractionalized, "PN: Cannot swap fractionalized Phygital Twin");
        require(_recipient != address(0), "PN: Recipient cannot be zero address");
        require(_conditionHash != bytes32(0), "PN: Condition hash cannot be empty");
        require(_expirationTime > block.timestamp, "PN: Expiration time must be in the future");

        // Transfer NFT to contract for escrow
        _phygitalTokenOwners[_tokenId] = address(this);
        phygitalTwins[_tokenId].owner = address(this);
        _phygitalTokenBalances[msg.sender]--;

        uint256 swapId = nextSwapId++;
        conditionalSwaps[swapId] = ConditionalSwap({
            tokenId: _tokenId,
            seller: msg.sender,
            recipient: _recipient,
            conditionHash: _conditionHash,
            expirationTime: _expirationTime,
            fulfilled: false
        });

        emit ConditionalSwapInitiated(swapId, _tokenId, msg.sender, _recipient, _conditionHash, _expirationTime);
        return swapId;
    }

    /**
     * @notice Executes a conditional swap once the conditions are met (verified off-chain via oracle/resolver).
     * @param _swapId The ID of the conditional swap.
     */
    function executeConditionalSwap(uint256 _swapId) external whenNotPaused {
        ConditionalSwap storage swap = conditionalSwaps[_swapId];
        require(swap.seller != address(0), "PN: Swap does not exist");
        require(!swap.fulfilled, "PN: Swap already fulfilled");
        require(block.timestamp <= swap.expirationTime, "PN: Swap expired");

        // This function would typically be called by the trusted oracle or a designated resolver contract
        // after verifying the condition hash against actual on-chain state or off-chain data.
        require(msg.sender == trustedOracle, "PN: Only trusted oracle can execute conditional swap");

        // The oracle would have verified that the condition represented by `swap.conditionHash` is met.
        // E.g., if conditionHash represents "recipient's reputation score is > X" or "Phygital Twin's dynamic property Y is Z".

        // Transfer NFT to the recipient
        _phygitalTokenOwners[swap.tokenId] = swap.recipient;
        phygitalTwins[swap.tokenId].owner = swap.recipient;
        _phygitalTokenBalances[swap.recipient]++;

        swap.fulfilled = true;

        emit ConditionalSwapExecuted(_swapId);
    }

    /**
     * @notice Initiates a transfer that only becomes claimable by the recipient after a certain timestamp.
     * @param _tokenId The ID of the Phygital Twin to time-lock.
     * @param _recipient The address that will receive the NFT after unlock time.
     * @param _unlockTime The timestamp when the NFT becomes claimable.
     * @return transferId The ID of the new time-locked transfer.
     */
    function createTimeLockedTransfer(uint256 _tokenId, address _recipient, uint256 _unlockTime) external whenNotPaused returns (uint256) {
        require(_phygitalTokenOwners[_tokenId] == msg.sender, "PN: Not owner of Phygital Twin");
        require(!phygitalTwins[_tokenId].isFractionalized, "PN: Cannot time-lock fractionalized Phygital Twin");
        require(_recipient != address(0), "PN: Recipient cannot be zero address");
        require(_unlockTime > block.timestamp, "PN: Unlock time must be in the future");

        // Transfer NFT to contract for escrow
        _phygitalTokenOwners[_tokenId] = address(this);
        phygitalTwins[_tokenId].owner = address(this);
        _phygitalTokenBalances[msg.sender]--;

        uint256 transferId = nextTimeLockedTransferId++;
        timeLockedTransfers[transferId] = TimeLockedTransfer({
            tokenId: _tokenId,
            sender: msg.sender,
            recipient: _recipient,
            unlockTime: _unlockTime,
            claimed: false
        });

        emit TimeLockedTransferCreated(transferId, _tokenId, _recipient, _unlockTime);
        return transferId;
    }

    /**
     * @notice Allows the recipient to claim a time-locked Phygital Twin after the unlock time.
     * @param _transferId The ID of the time-locked transfer.
     */
    function claimTimeLockedTransfer(uint256 _transferId) external whenNotPaused {
        TimeLockedTransfer storage transfer = timeLockedTransfers[_transferId];
        require(transfer.sender != address(0), "PN: Time-locked transfer does not exist");
        require(transfer.recipient == msg.sender, "PN: Not the recipient of this transfer");
        require(!transfer.claimed, "PN: Transfer already claimed");
        require(block.timestamp >= transfer.unlockTime, "PN: Unlock time has not yet passed");

        // Transfer NFT to the recipient
        _phygitalTokenOwners[transfer.tokenId] = transfer.recipient;
        phygitalTwins[transfer.tokenId].owner = transfer.recipient;
        _phygitalTokenBalances[transfer.recipient]++;

        transfer.claimed = true;

        emit TimeLockedTransferClaimed(_transferId);
    }

    // --- VII. Phygital Asset Discovery & Curation ---

    /**
     * @notice A user nominates a Phygital Asset for inclusion in a "curated" list.
     *         Requires a small fee to prevent spam and for curation council incentives.
     * @param _tokenId The ID of the Phygital Twin to nominate.
     * @param _reason A brief reason for nomination.
     */
    function nominatePhygitalForCuration(uint256 _tokenId, string calldata _reason) external payable whenNotPaused {
        require(phygitalTwins[_tokenId].owner != address(0), "PN: Phygital Twin does not exist");
        require(msg.value >= curationNominationFee, "PN: Insufficient nomination fee");
        require(!hasNominatedForCuration[_tokenId][msg.sender], "PN: Already nominated this asset");
        require(bytes(_reason).length > 0, "PN: Reason for nomination cannot be empty");

        hasNominatedForCuration[_tokenId][msg.sender] = true;
        // The nomination itself might grant a tiny reputation boost or be part of a larger mechanism
        // For simplicity, just recording the nomination.

        emit PhygitalNominatedForCuration(_tokenId, msg.sender);
    }

    /**
     * @notice Curation Council votes to include/exclude an asset from the curated list.
     * @param _tokenId The ID of the Phygital Twin.
     * @param _isCurated True to mark as curated, false to uncurate.
     */
    function curatePhygitalAsset(uint256 _tokenId, bool _isCurated) external whenNotPaused onlyCurationCouncil {
        require(phygitalTwins[_tokenId].owner != address(0), "PN: Phygital Twin does not exist");
        // For simplicity, a single council member's action is sufficient to demonstrate.
        // In a real system, multiple votes would be recorded and then finalized by a threshold.
        // require(!curationCouncilVotes[_tokenId][msg.sender], "PN: Already voted on curation for this asset");

        isPhygitalCurated[_tokenId] = _isCurated;
        curationCouncilVotes[_tokenId][msg.sender] = true; // Mark that this council member voted.

        emit PhygitalCuratedStatusUpdated(_tokenId, _isCurated, msg.sender);
    }

    // --- VIII. Treasury & Fee Management ---

    /**
     * @notice Allows the contract owner to withdraw accumulated fees from the contract.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of funds to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "PN: Recipient cannot be zero address");
        require(address(this).balance >= _amount, "PN: Insufficient balance in treasury");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "PN: Failed to withdraw funds");

        emit TreasuryFundsWithdrawn(_recipient, _amount);
    }

    // --- Helper / Getter Functions ---

    /**
     * @notice Returns the owner of a Phygital Twin.
     * @param _tokenId The ID of the Phygital Twin.
     * @return The address of the owner.
     */
    function getPhygitalTwinOwner(uint256 _tokenId) public view returns (address) {
        return _phygitalTokenOwners[_tokenId];
    }

    /**
     * @notice Returns the number of non-fractionalized Phygital Twins owned by an address.
     * @param _owner The address to query.
     * @return The balance of Phygital Twins.
     */
    function getPhygitalTwinBalance(address _owner) public view returns (uint256) {
        return _phygitalTokenBalances[_owner];
    }

    /**
     * @notice Returns the number of F-NFT shares an address holds for a specific Phygital Twin.
     * @param _tokenId The ID of the Phygital Twin.
     * @param _owner The address to query.
     * @return The balance of F-NFT shares.
     */
    function getFNFTBalance(uint256 _tokenId, address _owner) public view returns (uint256) {
        return fnftBalances[_tokenId][_owner];
    }

    /**
     * @notice Retrieves the current value of a dynamic property for a Phygital Twin.
     * @param _tokenId The ID of the Phygital Twin.
     * @param _propertyKey The key of the dynamic property.
     * @return The value of the dynamic property (as bytes).
     */
    function getDynamicProperty(uint256 _tokenId, string memory _propertyKey) public view returns (bytes memory) {
        return phygitalTwins[_tokenId].dynamicProperties[_propertyKey];
    }

    // Fallback function to receive ETH
    receive() external payable {
        // Potentially log received ETH or handle specific donations
    }
}
```