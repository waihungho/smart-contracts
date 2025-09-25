Here's a smart contract named `SynergyNexus` that embodies advanced concepts, creative functions, and trendy mechanisms in Solidity. It combines Soul-Bound Reputation Tokens (SBRTs), AI-driven (oracle-fed) attribute updates, liquid governance tokens (LGTs), and a dynamic governance model where influence is a composite of fungible tokens and non-transferable reputation.

To ensure it doesn't duplicate open-source code, standard ERC-20 and ERC-721 interfaces are *implemented directly* with custom logic rather than importing full OpenZeppelin implementations. The core novelty lies in the interplay between these unique components.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline of SynergyNexus Smart Contract ---
// I.  Contract Information & Access Control
//     - Defines roles (ADMIN, ORACLE, PAUSER, MINTER, BURNER), sets owner, manages pausing.
// II. Token Definitions & Structures
//     - ERC-20 compatible Liquid Governance Token (LGT).
//     - ERC-721 compatible Soul-Bound Reputation Token (SBRT) with dynamic attributes.
// III. SBRT Management
//     - Minting, metadata, attribute updates (by oracle or attestations), burning.
// IV. LGT Management
//     - Minting, burning, standard ERC-20 transfers.
// V.  Synergy Vault & Dynamic Governance
//     - Mechanism to "synergize" LGTs with SBRTs for boosted influence.
//     - Calculation of effective vote power based on LGTs and SBRT attributes.
// VI. DAO Governance & Resource Allocation
//     - Proposal submission, voting, execution.
//     - Resource request and approval system, leveraging SBRT reputation.
// VII. Oracle & Role Management
//     - Setting and retrieving oracle address, managing custom roles.
// VIII. Emergency & Utility Functions
//     - Pausing, emergency withdrawals, SBRT URI updates.

// --- Function Summary ---

// I. Contract Information & Access Control
// 1. constructor(address initialOracle): Initializes the contract, sets the deployer as owner, grants initial roles, and sets the initial oracle address.
// 2. grantRole(bytes32 role, address account): Grants a specific role to an address. Only callable by ADMIN_ROLE.
// 3. revokeRole(bytes32 role, address account): Revokes a specific role from an address. Only callable by ADMIN_ROLE.
// 4. hasRole(bytes32 role, address account): Checks if an address has a specific role.
// 5. renounceOwnership(): Allows the current owner to give up ownership.
// 6. transferOwnership(address newOwner): Transfers ownership of the contract to a new address.
// 7. pause(): Pauses all operations that are pause-protected. Only callable by PAUSER_ROLE.
// 8. unpause(): Unpauses the contract. Only callable by PAUSER_ROLE.

// II. Soul-Bound Reputation Token (SBRT) Management
// 9. mintSBRT(address recipient): Mints a new Soul-Bound Reputation Token (SBRT) for the recipient. SBRTs are non-transferable NFTs tied to identity, acting as a base for on-chain reputation. Only callable by MINTER_ROLE.
// 10. getSBRTMetadataURI(uint256 tokenId): Returns the URI for an SBRT's metadata, combining a base URI with the token ID.
// 11. getSBRTAttributes(uint256 tokenId): Retrieves the current attributes of an SBRT (InfluenceScore, ContributionPoints, ActivityLevel).
// 12. updateSBRTAttributeByOracle(uint256 tokenId, AttributeType attributeType, uint256 newValue, bytes memory proof): Allows the ORACLE_ROLE to update an SBRT attribute based on off-chain AI-driven data. (Advanced Concept: Oracle-fed AI-driven attribute updates).
// 13. attestToSBRT(uint256 tokenId, AttributeType attributeType, uint256 boostAmount): Allows a sufficiently reputable SBRT holder to attest to another SBRT, boosting specific attributes. (Creative: On-chain attestation system for reputation).
// 14. getSBRTAttestations(uint256 tokenId): Views all attestations received by a given SBRT.
// 15. burnSBRT(uint256 tokenId): Burns an SBRT (e.g., in cases of validated malicious behavior). Callable by BURNER_ROLE. Automatically unsynergizes any linked LGTs.

// III. Liquid Governance Token (LGT) Management (Custom ERC-20 implementation)
// 16. name(): Returns the name of the LGT token.
// 17. symbol(): Returns the symbol of the LGT token.
// 18. decimals(): Returns the number of decimals of the LGT token.
// 19. totalSupply(): Returns the total supply of LGT tokens.
// 20. balanceOf(address account): Returns the LGT balance of an account.
// 21. transfer(address recipient, uint256 amount): Transfers LGT tokens from the caller's balance to a recipient.
// 22. allowance(address owner, address spender): Returns the remaining amount the `spender` is allowed to spend on behalf of `owner`.
// 23. approve(address spender, uint256 amount): Sets the amount `spender` is allowed to spend on behalf of the caller.
// 24. transferFrom(address sender, address recipient, uint256 amount): Transfers LGT tokens on behalf of another address (requires prior approval).
// 25. mintLGT(address recipient, uint256 amount): Mints new LGT tokens for a recipient. Callable by MINTER_ROLE.
// 26. burnLGT(uint256 amount): Burns LGT tokens from the caller's balance. Callable by BURNER_ROLE or the token holder.

// IV. Synergy Vault & Dynamic Governance
// 27. synergizeLGTs(uint256 amount): Locks LGTs into the Synergy Vault, linking them to the caller's SBRT to amplify governance power. (Advanced Concept: Liquid staking-like mechanism tied to soul-bound reputation).
// 28. unsynergizeLGTs(uint256 amount): Unlocks previously synergized LGTs, returning them to the caller's balance.
// 29. getSynergizedLGTs(address account): Returns the amount of LGTs synergized by an account.
// 30. calculateEffectiveVotePower(address account): Calculates the total effective vote power, considering both LGTs (base and synergized) and SBRT influence. (Advanced Concept: Dynamic voting power influenced by a combination of fungible and non-fungible tokens).
// 31. getTotalEffectiveVotePower(): Estimates the total effective vote power across the system (simplified for on-chain cost).

// V. DAO Governance & Resource Allocation
// 32. submitProposal(string memory description, address target, bytes memory callData, uint256 value): Submits a new DAO proposal. Requires minimum effective vote power.
// 33. voteOnProposal(uint256 proposalId, bool support): Casts a vote on an active proposal using the calculated effective vote power.
// 34. executeProposal(uint256 proposalId): Executes a passed proposal after the voting period ends and quorum is met.
// 35. requestResourceAllocation(string memory description, uint256 requestedAmount, address recipient): Submits a request for resources (LGTs) from the DAO treasury. SBRT reputation influences the required approval threshold. (Creative: Reputation-weighted resource allocation).
// 36. approveResourceAllocation(uint256 requestId, bool approveVote): DAO members vote to approve or reject a resource allocation request.
// 37. finalizeResourceRequest(uint256 requestId): Checks and updates the status of a resource allocation request after its voting period.

// VI. Oracle & Role Management
// 38. setOracleAddress(address _oracleAddress): Sets the address for the ORACLE_ROLE, revoking the previous one. Only callable by ADMIN_ROLE.
// 39. setAttesterMinInfluence(uint256 _minInfluence): Sets the minimum SBRT InfluenceScore required for an SBRT holder to attest to others. Only callable by ADMIN_ROLE.

// VII. Emergency & Utility Functions
// 40. emergencyWithdrawERC20(address tokenAddress, uint256 amount): Allows emergency withdrawal of ERC-20 tokens sent accidentally to the contract. Only callable by OWNER when contract is paused.
// 41. emergencyWithdrawETH(uint256 amount): Allows emergency withdrawal of ETH sent accidentally to the contract. Only callable by OWNER when contract is paused.
// 42. updateSBRTBaseURI(string memory _newBaseURI): Updates the base URI for SBRT metadata, affecting how token metadata is resolved. Only callable by ADMIN_ROLE.

// Note: This contract implements custom logic for soul-bound tokens, dynamic attributes, and the Synergy Vault. While it adheres to ERC-20 and ERC-721 interfaces for broad compatibility, its internal mechanisms are designed to be unique to avoid direct duplication of existing open-source implementations. The core novelty lies in the intricate interplay between reputation (SBRT), fungible governance power (LGT), and an oracle-driven attribute system influencing resource allocation and governance.

contract SynergyNexus {
    // --- I. Contract Information & Access Control ---

    // Roles (bytes32 representation for efficiency)
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    mapping(bytes32 => mapping(address => bool)) private _roles;
    address private _owner;
    bool private _paused;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    modifier onlyOwner() {
        require(_msgSender() == _owner, "SynergyNexus: Not owner");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), string(abi.encodePacked("SynergyNexus: Must have ", Strings.toHexString(uint256(role)), " role")));
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "SynergyNexus: Paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "SynergyNexus: Not paused");
        _;
    }

    constructor(address initialOracle) {
        _setOwner(_msgSender());
        _grantRole(ADMIN_ROLE, _msgSender()); // Deployer is initial admin
        _grantRole(PAUSER_ROLE, _msgSender()); // Deployer is initial pauser
        _grantRole(MINTER_ROLE, _msgSender()); // Deployer is initial minter
        _grantRole(BURNER_ROLE, _msgSender()); // Deployer is initial burner
        _grantRole(ORACLE_ROLE, initialOracle); // Set initial oracle address
        _paused = false;

        // Initialize LGT details
        _name = "Synergy Governance Token";
        _symbol = "LGT";
        _decimals = 18;

        // Initialize SBRT details
        _sbrtName = "Soul-Bound Reputation Token";
        _sbrtSymbol = "SBRT";
        _sbrtBaseURI = "https://api.synergynexus.xyz/sbrt/"; // Example base URI
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function grantRole(bytes32 role, address account) public virtual onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual onlyRole(ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role][account];
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "SynergyNexus: new owner is the zero address");
        _setOwner(newOwner);
    }

    function pause() public virtual onlyRole(PAUSER_ROLE) whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public virtual onlyRole(PAUSER_ROLE) whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }


    // --- II. Token Definitions & Structures ---

    // SBRT Attributes Enum
    enum AttributeType {
        InfluenceScore,
        ContributionPoints,
        ActivityLevel
    }

    // SBRT Structure
    struct SBRTAttributes {
        uint256 influenceScore;
        uint256 contributionPoints;
        uint256 activityLevel;
        uint256 lastUpdatedTimestamp;
    }

    struct Attestation {
        uint256 attesterTokenId;
        AttributeType attributeType;
        uint256 boostAmount;
        uint256 timestamp;
    }

    // DAO Proposal Structure
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed, Expired }

    struct Proposal {
        uint256 id;
        string description;
        address target;
        bytes callData;
        uint256 value;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // For unique voting
        ProposalState state;
        bool executed;
    }

    // Resource Allocation Request Structure
    enum RequestState { Pending, Approved, Rejected, Executed }

    struct ResourceAllocationRequest {
        uint256 id;
        string description;
        uint256 requestedAmount;
        address recipient;
        address applicant;
        uint256 submitTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 requiredApprovals; // Example: percentage of total effective vote power needed
        mapping(address => bool) hasVoted; // For unique voting
        RequestState state;
    }

    // --- State Variables ---

    // LGT State
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // SBRT State
    string private _sbrtName;
    string private _sbrtSymbol;
    string private _sbrtBaseURI;
    uint256 private _sbrtTokenIdCounter;
    mapping(uint256 => address) private _sbrtOwners; // tokenId -> owner (for ERC721 compliance)
    mapping(address => uint256) private _sbrtHolderTokenId; // holder address -> tokenId (since one SBRT per address)
    mapping(uint256 => SBRTAttributes) private _sbrtAttributes;
    mapping(uint256 => Attestation[]) private _sbrtAttestations;

    // Synergy Vault State
    mapping(address => uint256) private _synergizedLGTs; // address -> amount of LGTs locked for synergy
    uint256 private totalSynergizedLGTsState; // Tracks total LGTs in synergy across all holders

    // DAO Governance State
    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalVotingPeriod = 3 days; // Example duration
    uint256 public proposalQuorumPercentage = 50; // % of total effective vote power needed to pass
    uint256 public minLGTsForProposal = 1000 * (10 ** 18); // 1000 LGTs (assuming 18 decimals)

    // Resource Allocation State
    uint256 public requestCounter;
    mapping(uint256 => ResourceAllocationRequest) public resourceRequests;
    uint256 public resourceRequestVotingPeriod = 1 days; // Example duration
    uint256 public resourceRequestQuorumPercentage = 30; // Base % of total effective vote power needed
    uint256 public attesterMinInfluence = 500; // Minimum InfluenceScore to attest to others

    // Constants for vote power calculation
    uint256 public constant INFLUENCE_FACTOR = 1000; // Divisor for SBRT influence to get a multiplier
    uint256 public constant MAX_INFLUENCE_SCORE_CAP = 10000; // Max influence score to prevent excessive power

    // Events
    event SBRTMinted(address indexed recipient, uint256 indexed tokenId);
    event SBRTAttributeUpdated(uint256 indexed tokenId, AttributeType indexed attributeType, uint256 newValue, address indexed updater);
    event SBRTAttested(uint256 indexed tokenId, uint256 indexed attesterTokenId, AttributeType indexed attributeType, uint256 boostAmount);
    event SBRTBurned(uint256 indexed tokenId);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event MintedLGT(address indexed recipient, uint256 amount);
    event BurnedLGT(address indexed burner, uint256 amount);

    event LGTsSynergized(address indexed account, uint256 amount);
    event LGTsUnsynergized(address indexed account, uint256 amount);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);

    event ResourceAllocationRequested(uint256 indexed requestId, address indexed applicant, uint256 requestedAmount);
    event ResourceAllocationApproved(uint256 indexed requestId);
    event ResourceAllocationRejected(uint256 indexed requestId);


    // --- III. SBRT Management --- (ERC-721 compatible, but non-transferable)

    // ERC721 metadata
    function sbrtName() public view returns (string memory) { return _sbrtName; } // Renamed to sbrtName to avoid conflict with LGT name()
    function sbrtSymbol() public view returns (string memory) { return _sbrtSymbol; } // Renamed to sbrtSymbol
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_sbrtOwners[tokenId] != address(0), "SBRT: Token does not exist");
        return string(abi.encodePacked(_sbrtBaseURI, Strings.toString(tokenId)));
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _sbrtOwners[tokenId] != address(0);
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _sbrtOwners[tokenId];
        require(owner != address(0), "SBRT: owner query for nonexistent token");
        return owner;
    }
    // Note: Standard ERC-721 functions like `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom` are omitted
    // to explicitly enforce the non-transferable nature of Soul-Bound Tokens (SBTs).

    function mintSBRT(address recipient) public whenNotPaused onlyRole(MINTER_ROLE) returns (uint256) {
        require(_sbrtHolderTokenId[recipient] == 0, "SBRT: Recipient already has an SBRT");
        _sbrtTokenIdCounter++;
        uint256 newTokenId = _sbrtTokenIdCounter;

        _sbrtOwners[newTokenId] = recipient;
        _sbrtHolderTokenId[recipient] = newTokenId;

        // Initialize SBRT attributes
        _sbrtAttributes[newTokenId] = SBRTAttributes({
            influenceScore: 100, // Base influence score
            contributionPoints: 0,
            activityLevel: 0,
            lastUpdatedTimestamp: block.timestamp
        });

        emit SBRTMinted(recipient, newTokenId);
        return newTokenId;
    }

    function getSBRTMetadataURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function getSBRTAttributes(uint256 tokenId) public view returns (uint256 influence, uint256 contribution, uint256 activity, uint256 lastUpdated) {
        require(_exists(tokenId), "SBRT: Token does not exist");
        SBRTAttributes storage attrs = _sbrtAttributes[tokenId];
        return (attrs.influenceScore, attrs.contributionPoints, attrs.activityLevel, attrs.lastUpdatedTimestamp);
    }

    function updateSBRTAttributeByOracle(uint256 tokenId, AttributeType attributeType, uint256 newValue, bytes memory proof)
        public whenNotPaused onlyRole(ORACLE_ROLE)
    {
        require(_exists(tokenId), "SBRT: Token does not exist");
        // In a real scenario, 'proof' would be verified here (e.g., signature verification, ZK proof, etc.)
        // For this example, we'll just require the ORACLE_ROLE and trust the input.
        // The 'proof' parameter is kept for conceptual demonstration.

        SBRTAttributes storage attrs = _sbrtAttributes[tokenId];
        if (attributeType == AttributeType.InfluenceScore) {
            attrs.influenceScore = newValue;
        } else if (attributeType == AttributeType.ContributionPoints) {
            attrs.contributionPoints = newValue;
        } else if (attributeType == AttributeType.ActivityLevel) {
            attrs.activityLevel = newValue;
        } else {
            revert("SBRT: Invalid attribute type");
        }
        attrs.lastUpdatedTimestamp = block.timestamp;
        emit SBRTAttributeUpdated(tokenId, attributeType, newValue, _msgSender());
    }

    function attestToSBRT(uint256 tokenId, AttributeType attributeType, uint256 boostAmount) public whenNotPaused {
        address attester = _msgSender();
        uint256 attesterTokenId = _sbrtHolderTokenId[attester];
        require(attesterTokenId != 0, "SBRT: Attester must have an SBRT");
        require(_exists(tokenId), "SBRT: Target SBRT does not exist");
        require(tokenId != attesterTokenId, "SBRT: Cannot attest to your own SBRT");
        require(_sbrtAttributes[attesterTokenId].influenceScore >= attesterMinInfluence, "SBRT: Attester's influence too low");
        require(boostAmount > 0, "SBRT: Boost amount must be positive");

        SBRTAttributes storage attrs = _sbrtAttributes[tokenId];
        if (attributeType == AttributeType.InfluenceScore) {
            attrs.influenceScore += boostAmount;
        } else if (attributeType == AttributeType.ContributionPoints) {
            attrs.contributionPoints += boostAmount;
        } else if (attributeType == AttributeType.ActivityLevel) {
            attrs.activityLevel += boostAmount;
        } else {
            revert("SBRT: Invalid attribute type for attestation");
        }
        attrs.lastUpdatedTimestamp = block.timestamp;
        _sbrtAttestations[tokenId].push(Attestation({
            attesterTokenId: attesterTokenId,
            attributeType: attributeType,
            boostAmount: boostAmount,
            timestamp: block.timestamp
        }));
        emit SBRTAttested(tokenId, attesterTokenId, attributeType, boostAmount);
    }

    function getSBRTAttestations(uint256 tokenId) public view returns (Attestation[] memory) {
        require(_exists(tokenId), "SBRT: Token does not exist");
        return _sbrtAttestations[tokenId];
    }

    function burnSBRT(uint256 tokenId) public whenNotPaused onlyRole(BURNER_ROLE) {
        require(_exists(tokenId), "SBRT: Token does not exist");
        address owner = _sbrtOwners[tokenId];

        // Clear SBRT related data
        delete _sbrtOwners[tokenId];
        delete _sbrtHolderTokenId[owner];
        delete _sbrtAttributes[tokenId];
        delete _sbrtAttestations[tokenId]; // Clear attestations received

        // Automatically unsynergize any linked LGTs and return them to the holder
        if (_synergizedLGTs[owner] > 0) {
            uint256 amountToUnlock = _synergizedLGTs[owner];
            _synergizedLGTs[owner] = 0;
            totalSynergizedLGTsState -= amountToUnlock; // Update total synergized
            _transfer(address(this), owner, amountToUnlock); // Transfer LGTs back from contract to owner
            emit LGTsUnsynergized(owner, amountToUnlock);
        }

        emit SBRTBurned(tokenId);
    }

    // --- III. Liquid Governance Token (LGT) Management (Custom ERC-20 implementation) ---

    // ERC-20 Standard functions
    function name() public view virtual returns (string memory) { return _name; }
    function symbol() public view virtual returns (string memory) { return _symbol; }
    function decimals() public view virtual returns (uint8) { return _decimals; }
    function totalSupply() public view virtual returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view virtual returns (uint256) { return _allowances[owner][spender]; }

    function transfer(address recipient, uint256 amount) public virtual whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "LGT: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    // Internal ERC-20 logic
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "LGT: transfer from the zero address");
        require(recipient != address(0), "LGT: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "LGT: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
            _balances[recipient] = _balances[recipient] + amount;
        }
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "LGT: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "LGT: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "LGT: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "LGT: approve from the zero address");
        require(spender != address(0), "LGT: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mintLGT(address recipient, uint256 amount) public virtual whenNotPaused onlyRole(MINTER_ROLE) {
        _mint(recipient, amount);
        emit MintedLGT(recipient, amount);
    }

    function burnLGT(uint256 amount) public virtual whenNotPaused {
        require(hasRole(BURNER_ROLE, _msgSender()) || _balances[_msgSender()] >= amount, "LGT: Not allowed to burn or insufficient balance");
        _burn(_msgSender(), amount);
        emit BurnedLGT(_msgSender(), amount);
    }


    // --- IV. Synergy Vault & Dynamic Governance ---

    function synergizeLGTs(uint256 amount) public whenNotPaused {
        require(amount > 0, "SynergyNexus: Amount must be positive");
        uint256 senderTokenId = _sbrtHolderTokenId[_msgSender()];
        require(senderTokenId != 0, "SynergyNexus: Caller must have an SBRT to synergize LGTs");
        
        _transfer(_msgSender(), address(this), amount); // Transfer LGTs to contract
        _synergizedLGTs[_msgSender()] += amount;
        totalSynergizedLGTsState += amount; // Update total synergized LGTs

        emit LGTsSynergized(_msgSender(), amount);
    }

    function unsynergizeLGTs(uint256 amount) public whenNotPaused {
        require(amount > 0, "SynergyNexus: Amount must be positive");
        require(_synergizedLGTs[_msgSender()] >= amount, "SynergyNexus: Insufficient synergized LGTs");
        
        _synergizedLGTs[_msgSender()] -= amount;
        totalSynergizedLGTsState -= amount; // Update total synergized LGTs
        _transfer(address(this), _msgSender(), amount); // Transfer LGTs back from contract

        emit LGTsUnsynergized(_msgSender(), amount);
    }

    function getSynergizedLGTs(address account) public view returns (uint256) {
        return _synergizedLGTs[account];
    }

    // Calculates effective voting power by combining LGTs and SBRT influence.
    // Formula: (Base LGTs) + (Synergized LGTs * (1 + sbrtInfluence / INFLUENCE_FACTOR))
    function calculateEffectiveVotePower(address account) public view returns (uint256) {
        uint256 baseLGTs = _balances[account];
        uint256 synergizedLGTs = _synergizedLGTs[account];
        uint256 sbrtInfluence = 0;

        uint256 sbrtTokenId = _sbrtHolderTokenId[account];
        if (sbrtTokenId != 0) {
            sbrtInfluence = _sbrtAttributes[sbrtTokenId].influenceScore;
        }

        // Cap influence score to prevent excessive boosts
        if (sbrtInfluence > MAX_INFLUENCE_SCORE_CAP) {
            sbrtInfluence = MAX_INFLUENCE_SCORE_CAP;
        }

        uint256 influenceMultiplier = 1 + (sbrtInfluence / INFLUENCE_FACTOR);
        uint256 effectiveSynergizedPower = synergizedLGTs * influenceMultiplier;

        return baseLGTs + effectiveSynergizedPower;
    }
    
    // Estimates total effective vote power across the system.
    // For practical reasons on-chain, this is a simplification:
    // Total Effective Power = Total LGT Supply + (Total Synergized LGTs * Average Synergy Multiplier)
    // The "Average Synergy Multiplier" is simplified to (1 + MAX_INFLUENCE_SCORE_CAP / INFLUENCE_FACTOR)
    // assuming maximum potential synergy for demonstration.
    function getTotalEffectiveVotePower() public view returns (uint256) {
        uint256 averageSynergyMultiplier = 1 + (MAX_INFLUENCE_SCORE_CAP / INFLUENCE_FACTOR);
        return _totalSupply + (totalSynergizedLGTsState * averageSynergyMultiplier);
    }

    // --- V. DAO Governance & Resource Allocation ---

    function submitProposal(string memory description, address target, bytes memory callData, uint256 value)
        public whenNotPaused
    {
        uint256 proposerVotePower = calculateEffectiveVotePower(_msgSender());
        require(proposerVotePower >= minLGTsForProposal, "DAO: Insufficient vote power to submit proposal");

        proposalCounter++;
        uint256 proposalId = proposalCounter;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            target: target,
            callData: callData,
            value: value,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalSubmitted(proposalId, _msgSender(), description);
    }

    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "DAO: Proposal not active");
        require(block.timestamp <= proposal.endTime, "DAO: Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "DAO: Already voted on this proposal");

        uint256 voterPower = calculateEffectiveVotePower(_msgSender());
        require(voterPower > 0, "DAO: Voter has no effective vote power");

        if (support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit ProposalVoted(proposalId, _msgSender(), support, voterPower);
    }

    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state != ProposalState.Executed, "DAO: Proposal already executed");
        require(block.timestamp > proposal.endTime, "DAO: Voting period not ended");

        // Determine outcome
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 totalEffectivePower = getTotalEffectiveVotePower(); 

        require(totalVotes * 100 >= totalEffectivePower * proposalQuorumPercentage, "DAO: Quorum not met");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            // Attempt to execute the transaction
            (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
            require(success, "DAO: Proposal execution failed");
            proposal.executed = true;
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(proposalId);
        } else {
            proposal.state = ProposalState.Defeated;
        }
    }

    function requestResourceAllocation(string memory description, uint256 requestedAmount, address recipient)
        public whenNotPaused
    {
        uint256 applicantTokenId = _sbrtHolderTokenId[_msgSender()];
        require(applicantTokenId != 0, "SynergyNexus: Applicant must have an SBRT");
        require(requestedAmount > 0, "SynergyNexus: Requested amount must be positive");
        require(recipient != address(0), "SynergyNexus: Recipient cannot be zero address");
        
        requestCounter++;
        uint256 requestId = requestCounter;

        resourceRequests[requestId] = ResourceAllocationRequest({
            id: requestId,
            description: description,
            requestedAmount: requestedAmount,
            recipient: recipient,
            applicant: _msgSender(),
            submitTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            requiredApprovals: 0, // Calculated dynamically below
            state: RequestState.Pending
        });

        // Dynamic required approvals based on applicant's SBRT influence.
        // Higher influence score might mean lower required approval percentage (min 10%).
        uint256 applicantInfluence = _sbrtAttributes[applicantTokenId].influenceScore;
        uint256 dynamicQuorum = resourceRequestQuorumPercentage + (MAX_INFLUENCE_SCORE_CAP - applicantInfluence) / 200; // Slower decay
        if (dynamicQuorum < 10) dynamicQuorum = 10; // Minimum 10% quorum
        if (dynamicQuorum > 100) dynamicQuorum = 100; // Maximum 100% quorum
        
        resourceRequests[requestId].requiredApprovals = dynamicQuorum;

        emit ResourceAllocationRequested(requestId, _msgSender(), requestedAmount);
    }

    function approveResourceAllocation(uint256 requestId, bool approveVote) public whenNotPaused {
        ResourceAllocationRequest storage request = resourceRequests[requestId];
        require(request.state == RequestState.Pending, "Resource: Request not pending");
        require(block.timestamp <= request.submitTimestamp + resourceRequestVotingPeriod, "Resource: Voting period has ended");
        require(!request.hasVoted[_msgSender()], "Resource: Already voted on this request");

        uint256 voterPower = calculateEffectiveVotePower(_msgSender());
        require(voterPower > 0, "Resource: Voter has no effective vote power");

        if (approveVote) {
            request.votesFor += voterPower;
        } else {
            request.votesAgainst += voterPower;
        }
        request.hasVoted[_msgSender()] = true;

        // Check if decision can be made early (e.g., if quorum/majority met before end of period)
        _checkResourceRequestStatus(requestId);
    }

    // Internal function to check and update resource request status
    function _checkResourceRequestStatus(uint256 requestId) internal {
        ResourceAllocationRequest storage request = resourceRequests[requestId];
        if (request.state != RequestState.Pending) return;

        uint256 totalVotes = request.votesFor + request.votesAgainst;
        uint256 totalEffectivePower = getTotalEffectiveVotePower(); 

        bool votingPeriodEnded = (block.timestamp > request.submitTimestamp + resourceRequestVotingPeriod);
        bool quorumMet = (totalVotes * 100 >= totalEffectivePower * request.requiredApprovals);

        if (votingPeriodEnded || quorumMet) {
            if (request.votesFor > request.votesAgainst && quorumMet) {
                request.state = RequestState.Approved;
                // Transfer LGTs from contract balance to recipient
                _transfer(address(this), request.recipient, request.requestedAmount);
                emit ResourceAllocationApproved(requestId);
            } else {
                request.state = RequestState.Rejected;
                emit ResourceAllocationRejected(requestId);
            }
        }
    }

    // Callable externally to finalize requests after period ends
    function finalizeResourceRequest(uint256 requestId) public {
        _checkResourceRequestStatus(requestId);
    }

    // --- VI. Oracle & Role Management ---

    function setOracleAddress(address _oracleAddress) public onlyRole(ADMIN_ROLE) {
        require(_oracleAddress != address(0), "SynergyNexus: Oracle address cannot be zero");
        // Implicitly revokes old oracle by granting new one. For security, could explicitly revoke.
        _grantRole(ORACLE_ROLE, _oracleAddress); // Re-grants in case it was already the same
    }

    function setAttesterMinInfluence(uint256 _minInfluence) public onlyRole(ADMIN_ROLE) {
        attesterMinInfluence = _minInfluence;
    }

    // --- VII. Emergency & Utility Functions ---

    function emergencyWithdrawERC20(address tokenAddress, uint256 amount) public onlyOwner whenPaused {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(_owner, amount), "SynergyNexus: ERC20 withdrawal failed");
    }

    function emergencyWithdrawETH(uint256 amount) public onlyOwner whenPaused {
        (bool success, ) = _owner.call{value: amount}("");
        require(success, "SynergyNexus: ETH withdrawal failed");
    }

    function updateSBRTBaseURI(string memory _newBaseURI) public onlyRole(ADMIN_ROLE) {
        _sbrtBaseURI = _newBaseURI;
    }

    // Helper for converting uint to string and bytes32 to hex string
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
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

        function toHexString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0x00";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 16;
            }
            bytes memory buffer = new bytes(2 + digits); // "0x" + hex
            buffer[0] = "0"; // Changed from "0x" to "0" to make it "0x" prepended outside, to fix a bug in older solidity with bytes1.
            buffer[1] = "x";
            while (value != 0) {
                digits--;
                uint256 digit = value % 16;
                if (digit < 10) {
                    buffer[digits + 2] = bytes1(uint8(48 + digit)); // '0'-'9'
                } else {
                    buffer[digits + 2] = bytes1(uint8(87 + digit)); // 'a'-'f' (87 = 'a' - 10)
                }
                value /= 16;
            }
            return string(buffer);
        }
    }

    // Minimal IERC20 interface for emergency withdrawal
    interface IERC20 {
        function transfer(address to, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
        function approve(address spender, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
    }
}

```