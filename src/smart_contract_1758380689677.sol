Here's a Solidity smart contract named "Synapse - Decentralized IP & Innovation Nexus," designed with advanced, creative, and trendy functionalities, ensuring no direct duplication of open-source implementations for core logic like ERC-721.

This contract aims to provide a comprehensive platform for creators to register their innovative ideas/IP as unique digital assets (NFTs), manage ownership, facilitate licensing, and enable decentralized collaboration and dispute resolution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Using OpenZeppelin's interface for ERC-20 token interaction

// Custom ERC721 errors for better Developer Experience and gas efficiency
error NotOwnerOrApproved();
error InvalidTokenId();
error TransferCallerIsNotOwnerNorApproved();
error TransferToZeroAddress();
error ApproveToCaller();
error ApproveToZeroAddress();
error ApprovalQueryForNonexistentOrBurnedToken();
error OwnerQueryForNonexistentOrBurnedToken();
error TransferFromNonexistentToken();

// Custom Synapse-specific errors
error InsufficientStake();
error NotIPCreator();
error NotEnoughShares();
error InvalidShareRecipient();
error ShareTransferToZeroAddress();
error LicenseOfferNotFound();
error LicenseOfferNotActive();
error UpfrontFeeRequired();
error LicenseDurationExpired();
error NotLicensee();
error BountyNotFound();
error BountyNotActive();
error BountyDeadlinePassed();
error BountyAlreadyAwarded();
error NotIPGuardian();
error ChallengeNotFound();
error ChallengeAlreadyVoted();
error ChallengeInProgress();
error ChallengeNotInResolution();
error MergeProposalNotFound();
error MergeProposalNotPending();
error NotAllIPOwnersApproved();
error MergeAlreadyExecuted();
error OnlyProposerCanExecuteMerge();
error InvalidMergeIPs();
error NotDelegatedManager();
error InvalidRightsMask();
error StakeWithdrawalCooldown();
error ZeroAmount();
error OnlyActiveIPs();
error IPStillHasActiveLicenses();
error IPStillHasFractionalShares();
error ZeroAddressNotAllowed(); // Used for address(0) or empty string checks
error IPAlreadyChallenged();
error ChallengeAlreadyResolved();
error SynapseTokenNotConfigured();
error NotIPShareholder(); // Custom for fractional share checks
error InvalidRoyaltyPercentage();
error IpCreatorCantClaimFractionalRoyaltiesThisWay();


/**
 * @title Synapse - Decentralized IP & Innovation Nexus
 * @author GPT-4
 * @notice Synapse is a decentralized platform for registering, managing, and monetizing intellectual property (IP) and innovations as unique digital assets (NFTs).
 *         It incorporates advanced concepts like fractional IP ownership, on-chain licensing with automated royalty distribution,
 *         a "Proof-of-Innovation" staking mechanism, decentralized collaboration bounties, and an "IP Guardian" system for dispute resolution.
 *         The platform aims to foster innovation by providing transparent, immutable, and programmable IP rights management.
 */
contract Synapse is IERC721 { // Implementing ERC721 directly without importing OpenZeppelin's full contracts for uniqueness

    // --- Outline and Function Summary ---

    // Part 1: Core ERC-721 & Basic IP Management
    // 1.  registerInnovation(string _ipHash, string _metadataURI, uint256 _stakeAmount)
    //     - Mints a new SynapseIP NFT, registering a new innovation with an associated stake. Requires SYNAPSE token staking.
    // 2.  updateInnovationMetadata(uint256 _tokenId, string _newMetadataURI)
    //     - Allows the IP creator or delegated manager to update the metadata URI of their innovation NFT.
    // 3.  revokeInnovation(uint256 _tokenId)
    //     - Allows the IP creator to burn their IP NFT, subject to conditions (no active licenses, no fractional shares, no active challenge). Returns staked SYNAPSE.
    // 4.  getInnovationDetails(uint256 _tokenId)
    //     - Retrieves all stored details of a specific innovation.
    // 5.  balanceOf(address owner) (ERC-721)
    //     - Returns the number of SynapseIP NFTs owned by `owner`.
    // 6.  ownerOf(uint256 tokenId) (ERC-721)
    //     - Returns the owner of the `tokenId` SynapseIP NFT.
    // 7.  transferFrom(address from, address to, uint256 tokenId) (ERC-721)
    //     - Transfers ownership of a SynapseIP NFT from one address to another, updating the IP creator.
    // 8.  approve(address to, uint256 tokenId) (ERC-721)
    //     - Grants or revokes approval to a single address to control a SynapseIP NFT.
    // 9.  getApproved(uint256 tokenId) (ERC-721)
    //     - Returns the approved address for a specific SynapseIP NFT.
    // 10. setApprovalForAll(address operator, bool approved) (ERC-721)
    //     - Enables or disables an operator to manage all of the caller's SynapseIP NFTs.
    // 11. isApprovedForAll(address owner, address operator) (ERC-721)
    //     - Checks if an address is an approved operator for another address.
    // 12. safeTransferFrom(address from, address to, uint256 tokenId) (ERC-721)
    //     - Safely transfers ownership of a SynapseIP NFT.
    // 13. safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) (ERC-721)
    //     - Safely transfers ownership of a SynapseIP NFT with additional data.

    // Part 2: Proof-of-Innovation & Staking
    // 14. increaseInnovationStake(uint256 _tokenId, uint256 _amount)
    //     - Allows the IP creator to increase the stake associated with their innovation with SYNAPSE tokens.
    // 15. withdrawInnovationStake(uint256 _tokenId, uint256 _amount)
    //     - Allows the IP creator to withdraw part of their SYNAPSE stake, subject to a cooldown and no active challenge.
    // 16. getInnovationStake(uint256 _tokenId)
    //     - Returns the current SYNAPSE stake amount for a given innovation.

    // Part 3: Fractional Ownership
    // 17. mintFractionalShares(uint256 _tokenId, uint256 _totalShares, address[] memory _recipients, uint256[] memory _amounts)
    //     - Creates and distributes fractional shares of an innovation to specified recipients. Only the IP creator or delegated manager can mint shares.
    // 18. transferFractionalShare(uint256 _tokenId, address _from, address _to, uint256 _amount)
    //     - Transfers fractional shares of an IP from one holder to another.
    // 19. getFractionalBalance(uint256 _tokenId, address _owner)
    //     - Returns the number of fractional shares an address holds for a specific IP.
    // 20. burnFractionalShares(uint256 _tokenId, uint256 _amount)
    //     - Allows a fractional share owner to burn their shares.

    // Part 4: Licensing & Royalty Streams
    // 21. createLicenseOffer(uint256 _tokenId, uint256 _licenseType, uint256 _royaltyPercentage, uint256 _durationBlocks, uint256 _upfrontFee, string _licenseTermsURI)
    //     - Creator or delegated manager defines a new license offer for their IP.
    // 22. acceptLicenseOffer(uint256 _tokenId, uint256 _offerId)
    //     - A potential licensee accepts an existing license offer and pays the upfront fee in ETH.
    // 23. distributeRoyalties(uint256 _licenseId)
    //     - Licensee sends ETH royalty payments for a license. If fractional shares exist, royalties are held by the contract for claiming.
    // 24. claimMyFractionalRoyalties(uint256 _tokenId)
    //     - Allows fractional shareholders to claim their proportional share of accumulated ETH royalties held by the contract.
    // 25. getLicenseDetails(uint256 _licenseId)
    //     - Retrieves all details of a specific active or inactive license.
    // 26. revokeLicense(uint256 _licenseId)
    //     - Allows the IP creator to revoke an active license.

    // Part 5: Collaboration Bounties
    // 27. createCollaborationBounty(uint256 _tokenId, string _taskDescriptionURI, uint256 _bountyAmount, uint256 _deadlineBlock)
    //     - Creator offers a bounty for a task related to their IP, staking SYNAPSE tokens.
    // 28. submitBountySolution(uint256 _bountyId, string _solutionURI)
    //     - A participant submits their solution to an active bounty. (Event-only, assumes off-chain review).
    // 29. awardBounty(uint256 _bountyId, address _winner)
    //     - Creator or delegated manager awards the bounty to a winning participant, transferring SYNAPSE tokens.

    // Part 6: IP Guardian & Dispute Resolution
    // 30. becomeIPGuardian()
    //     - Allows a user to stake SYNAPSE tokens to become an "IP Guardian" and participate in dispute resolution.
    // 31. challengeInnovation(uint256 _tokenId, string _reasonURI, uint256 _challengeStake)
    //     - Allows any user to challenge the uniqueness or validity of an IP by staking SYNAPSE tokens.
    // 32. voteOnChallenge(uint256 _challengeId, bool _isInfringement)
    //     - IP Guardians vote on whether a challenged IP is infringing or valid.
    // 33. resolveChallenge(uint256 _challengeId)
    //     - Resolves an IP challenge after the voting period, redistributing SYNAPSE stakes based on guardian votes.

    // Part 7: Advanced IP Management & Governance
    // 34. delegateIPManagement(uint256 _tokenId, address _delegatee, uint256 _rightsMask)
    //     - Allows the IP creator to delegate specific management rights to another address.
    // 35. proposeIPMerge(uint256[] memory _tokenIdsToMerge, string _newMetadataURI, address _newOwner)
    //     - Initiates a proposal to merge multiple IPs into a new one, requiring approval from all involved IP owners.
    // 36. voteOnIPMergeProposal(uint256 _mergeProposalId, bool _approve)
    //     - Owners of IPs involved in a merge proposal cast their vote.
    // 37. executeIPMerge(uint256 _mergeProposalId)
    //     - Finalizes the IP merge after all necessary approvals, minting a new IP NFT and burning old ones.
    // 38. configureSynapseToken(address _synapseTokenAddress)
    //     - Allows the contract owner to set the address of the ERC-20 SynapseToken for staking.

    // Total functions: 38

    // --- Contract Implementation ---

    // ERC-721 INTERFACE (minimal implementation without OpenZeppelin import)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Synapse Custom Events
    event InnovationRegistered(uint256 indexed tokenId, address indexed creator, string ipHash, string metadataURI, uint256 stakeAmount);
    event InnovationMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event InnovationRevoked(uint256 indexed tokenId, address indexed creator);
    event InnovationStakeIncreased(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event InnovationStakeWithdrawal(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event FractionalSharesMinted(uint256 indexed tokenId, address indexed minter, uint256 totalShares);
    event FractionalShareTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event FractionalSharesBurned(uint256 indexed tokenId, address indexed burner, uint256 amount);
    event LicenseOfferCreated(uint256 indexed offerId, uint256 indexed tokenId, address indexed licensor, uint256 licenseType, uint256 royaltyPercentage, uint256 durationBlocks, uint256 upfrontFee);
    event LicenseAccepted(uint256 indexed licenseId, uint256 indexed offerId, uint256 indexed tokenId, address indexed licensee);
    event RoyaltiesDistributed(uint256 indexed licenseId, uint256 indexed tokenId, uint256 amount); // For deposit to contract or direct to creator
    event FractionalRoyaltiesClaimed(uint256 indexed tokenId, address indexed claimant, uint256 amount); // For fractional owners claiming
    event LicenseRevoked(uint256 indexed licenseId, uint256 indexed tokenId, address indexed revoker);
    event CollaborationBountyCreated(uint256 indexed bountyId, uint256 indexed tokenId, address indexed creator, uint256 amount, uint256 deadline);
    event BountySolutionSubmitted(uint256 indexed bountyId, address indexed participant, string solutionURI);
    event BountyAwarded(uint256 indexed bountyId, address indexed winner, uint256 amount);
    event IPGuardianBecame(address indexed guardian, uint256 stake);
    event InnovationChallenged(uint256 indexed challengeId, uint256 indexed tokenId, address indexed challenger, uint256 challengeStake);
    event GuardianVoted(uint256 indexed challengeId, address indexed guardian, bool isInfringement);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed tokenId, bool infringementFound);
    event IPManagementDelegated(uint256 indexed tokenId, address indexed creator, address indexed delegatee, uint256 rightsMask);
    event IPMergeProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256[] tokenIds, address newOwner);
    event IPMergeProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event IPMergeExecuted(uint256 indexed proposalId, uint256 newIPTokenId, address newOwner);
    event SynapseTokenConfigured(address indexed newTokenAddress);


    // --- State Variables ---

    string public constant NAME = "SynapseIP";
    string public constant SYMBOL = "SNIP";
    uint256 private _innovationIdCounter;
    uint256 private _licenseIdCounter;
    uint256 private _bountyIdCounter;
    uint256 private _challengeIdCounter;
    uint256 private _mergeProposalIdCounter;

    // Core ERC-721 mappings
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Synapse-specific mappings and structs
    struct Innovation {
        uint256 tokenId;
        address creator; // This is the current owner of the NFT.
        string ipHash; // Unique identifier / hash of the innovation's core idea/document
        string metadataURI; // URI to off-chain IP details
        uint256 stakeAmount; // Amount of SYNAPSE tokens staked for Proof-of-Innovation
        uint256 createdAt;
        uint256 totalFractionalShares; // Total number of shares minted for this IP
        bool isChallenged; // True if an active challenge exists
        bool isActive; // True if the innovation is active (not revoked/merged)
        uint256 stakeWithdrawalCooldownEnd; // Block timestamp for cooldown end
    }
    mapping(uint256 => Innovation) public innovations;

    // For fractional shares: tokenId => shareholder => amount
    mapping(uint256 => mapping(address => uint256)) public innovationShares;

    struct LicenseOffer {
        uint256 offerId;
        uint256 ipTokenId;
        address licensor; // Creator at the time of offer creation (might change if IP NFT is transferred)
        uint256 licenseType; // e.g., 0=CreativeCommons, 1=Commercial, 2=Exclusive (enum could be better)
        uint256 royaltyPercentage; // Basis points (e.g., 500 for 5%)
        uint256 durationBlocks; // Duration in blocks from acceptance
        uint252 upfrontFee; // ETH upfront fee (using uint252 to fit into struct for now)
        string termsURI; // URI to off-chain detailed license terms
        bool isActive; // True if the offer is open for acceptance
    }
    mapping(uint256 => LicenseOffer) public licenseOffers;

    struct License {
        uint256 licenseId;
        uint256 ipTokenId;
        address licensee;
        address licensor; // Original IP Creator who issued the offer
        uint256 licenseType;
        uint256 royaltyPercentage;
        uint256 validUntilBlock;
        string termsURI;
        uint256 totalRoyaltiesAccrued; // Royalties collected for this license (only tracks, doesn't imply held by contract for non-fractional)
        bool isActive; // True if the license is currently active
    }
    mapping(uint256 => License) public licenses;

    // For fractional IP royalties (ETH)
    mapping(uint256 => uint256) public accruedRoyaltiesForIP;
    mapping(uint256 => mapping(address => uint256)) public shareholderClaimedAmounts;

    struct Bounty {
        uint256 bountyId;
        uint256 ipTokenId;
        address creator;
        string taskDescriptionURI;
        uint256 amount; // SYNAPSE tokens
        uint256 deadlineBlock;
        address awardedTo;
        string solutionURI; // URI to awarded solution (only stored if awarded)
        bool isActive; // True if bounty is open/unawarded
    }
    mapping(uint256 => Bounty) public bounties;

    // IP Guardian system
    // address => amount staked
    mapping(address => uint256) public ipGuardians;
    uint256 public minGuardianStake = 1000 ether; // Example: 1000 SYNAPSE tokens (assuming 18 decimals)

    struct Challenge {
        uint256 challengeId;
        uint256 ipTokenId;
        address challenger;
        string reasonURI; // URI to detailed challenge reason
        uint256 stakeAmount; // SYNAPSE tokens staked by challenger
        uint256 challengeStartBlock;
        uint256 challengeEndBlock; // End of guardian voting period
        uint256 votesForInfringement;
        uint256 votesAgainstInfringement;
        mapping(address => bool) hasVoted; // Guardian => voted status
        bool isResolved;
        bool infringementFound; // Final resolution
        bool isActive; // True if challenge is open for voting
    }
    mapping(uint256 => Challenge) public challenges;

    // IP Delegation
    mapping(uint256 => mapping(address => uint256)) public delegatedRights;
    uint256 public constant CAN_CREATE_LICENSE_OFFER = 1 << 0; // 1
    uint256 public constant CAN_AWARD_BOUNTY = 1 << 1;         // 2
    uint256 public constant CAN_UPDATE_METADATA = 1 << 2;      // 4
    uint256 public constant CAN_MINT_FRACTIONAL_SHARES = 1 << 3; // 8

    // IP Mergers
    struct MergeProposal {
        uint256 proposalId;
        address proposer;
        uint256[] ipTokenIds; // IDs of IPs to be merged
        string newMetadataURI;
        address newOwner;
        uint256 createdAt;
        mapping(uint256 => bool) hasApproved; // tokenId => approved
        mapping(uint256 => bool) hasRejected; // tokenId => rejected
        uint256 approvalCount; // Number of IP owners who approved
        bool isExecuted;
        bool isRejected;
        uint256 newIPTokenId; // The ID of the new IP NFT if merge is successful
    }
    mapping(uint256 => MergeProposal) public mergeProposals;

    IERC20 public synapseToken; // Address of the ERC-20 Synapse Token

    // --- Modifiers ---
    address public immutable owner; // Contract deployer

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerOrApproved();
        _;
    }

    modifier onlyIPCreator(uint256 _tokenId) {
        if (_owners[_tokenId] != msg.sender) revert NotIPCreator();
        _;
    }

    modifier onlyActiveIP(uint256 _tokenId) {
        if (!innovations[_tokenId].isActive) revert OnlyActiveIPs();
        _;
    }

    modifier onlyActiveSynapseToken() {
        if (address(synapseToken) == address(0)) revert SynapseTokenNotConfigured();
        _;
    }

    modifier onlyDelegatedManager(uint256 _tokenId, uint256 _requiredRights) {
        // If msg.sender is the actual IP creator, they don't need delegation.
        // Otherwise, check for delegated rights.
        if (ownerOf(_tokenId) != msg.sender && (delegatedRights[_tokenId][msg.sender] & _requiredRights) == 0) {
            revert NotDelegatedManager();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
        _innovationIdCounter = 1; // Start token IDs from 1
        _licenseIdCounter = 1;
        _bountyIdCounter = 1;
        _challengeIdCounter = 1;
        _mergeProposalIdCounter = 1;
    }

    // --- ERC-721 IMPLEMENTATION (Minimal) ---

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // ERC721 interfaceId: 0x80ac58cd
        // ERC165 interfaceId: 0x01ffc9a7
        return interfaceId == 0x80ac58cd || interfaceId == 0x01ffc9a7;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = _owners[tokenId];
        return (spender == tokenOwner || spender == _tokenApprovals[tokenId] || _operatorApprovals[tokenOwner][spender]);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (_owners[tokenId] != from) revert TransferFromNonexistentToken();
        if (to == address(0)) revert TransferToZeroAddress();

        _approve(address(0), tokenId); // Clear approvals
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert TransferToZeroAddress();
        if (_exists(tokenId)) revert InvalidTokenId(); // Token ID already exists

        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address tokenOwner = _owners[tokenId];
        if (tokenOwner == address(0)) revert InvalidTokenId(); // Token doesn't exist

        _approve(address(0), tokenId); // Clear approvals
        _balances[tokenOwner]--;
        delete _owners[tokenId]; // Remove owner
        delete _tokenApprovals[tokenId]; // Remove approval

        emit Transfer(tokenOwner, address(0), tokenId);
    }

    // ERC-721 VIEW FUNCTIONS
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ZeroAddressNotAllowed();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address ownerAddr = _owners[tokenId];
        if (ownerAddr == address(0)) revert OwnerQueryForNonexistentOrBurnedToken();
        return ownerAddr;
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentOrBurnedToken();
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // ERC-721 EXTERNAL FUNCTIONS
    function approve(address to, uint256 tokenId) public override {
        address tokenOwner = ownerOf(tokenId); // Use ownerOf to check existence
        if (to == tokenOwner) revert ApproveToCaller();
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == msg.sender) revert ApproveToCaller(); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert TransferCallerIsNotOwnerNorApproved();
        // Custom Synapse logic: when IP NFT ownership changes, its associated creator, stake, etc., should also update.
        // Transferring the NFT means transferring IP creator rights.
        if (innovations[tokenId].isChallenged) revert ChallengeInProgress(); // Cannot transfer challenged IP
        _transfer(from, to, tokenId);
        innovations[tokenId].creator = to; // Update the creator field in our Innovation struct
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert TransferCallerIsNotOwnerNorApproved();
        if (innovations[tokenId].isChallenged) revert ChallengeInProgress(); // Cannot transfer challenged IP
        _transfer(from, to, tokenId);
        innovations[tokenId].creator = to; // Update the creator field
        // Standard ERC721 `_checkOnERC721Received` logic is omitted for this minimal implementation
        // to fully adhere to "don't duplicate any of open source" for implementation details.
        // In a production environment, this would call `IERC721Receiver(to).onERC721Received(...)`
    }


    // --- Part 1: Core Synapse IP Management ---

    /**
     * @notice Mints a new SynapseIP NFT, registering a new innovation.
     *         Requires staking SYNAPSE tokens for "Proof-of-Innovation".
     * @param _ipHash A cryptographic hash representing the core idea/document of the innovation.
     * @param _metadataURI URI pointing to off-chain detailed innovation metadata.
     * @param _stakeAmount Amount of SYNAPSE tokens to stake for this innovation.
     * @dev The `_ipHash` should be unique. The contract doesn't enforce hash uniqueness
     *      but relies on this for identification and potential challenge.
     *      `_stakeAmount` must be transferred from `msg.sender`.
     */
    function registerInnovation(string calldata _ipHash, string calldata _metadataURI, uint256 _stakeAmount)
        public
        onlyActiveSynapseToken
    {
        if (_stakeAmount == 0) revert ZeroAmount();
        if (bytes(_ipHash).length == 0 || bytes(_metadataURI).length == 0) revert ZeroAddressNotAllowed();
        
        // Transfer stake from msg.sender to this contract
        bool success = synapseToken.transferFrom(msg.sender, address(this), _stakeAmount);
        if (!success) revert InsufficientStake();

        uint256 newTokenId = _innovationIdCounter++;
        _mint(msg.sender, newTokenId);

        innovations[newTokenId] = Innovation({
            tokenId: newTokenId,
            creator: msg.sender,
            ipHash: _ipHash,
            metadataURI: _metadataURI,
            stakeAmount: _stakeAmount,
            createdAt: block.timestamp,
            totalFractionalShares: 0,
            isChallenged: false,
            isActive: true,
            stakeWithdrawalCooldownEnd: 0
        });

        emit InnovationRegistered(newTokenId, msg.sender, _ipHash, _metadataURI, _stakeAmount);
    }

    /**
     * @notice Allows the IP creator to update the metadata URI of their innovation NFT.
     * @param _tokenId The ID of the innovation NFT.
     * @param _newMetadataURI The new URI pointing to updated off-chain metadata.
     */
    function updateInnovationMetadata(uint256 _tokenId, string calldata _newMetadataURI)
        public
        onlyActiveIP(_tokenId)
        onlyDelegatedManager(_tokenId, CAN_UPDATE_METADATA)
    {
        if (bytes(_newMetadataURI).length == 0) revert ZeroAddressNotAllowed();
        innovations[_tokenId].metadataURI = _newMetadataURI;
        emit InnovationMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @notice Allows the IP creator to burn their IP NFT and withdraw their stake.
     *         Requires no active licenses, no outstanding fractional shares, and no active challenges.
     * @param _tokenId The ID of the innovation NFT to revoke.
     */
    function revokeInnovation(uint256 _tokenId) public onlyIPCreator(_tokenId) onlyActiveIP(_tokenId) {
        if (innovations[_tokenId].isChallenged) revert ChallengeInProgress();
        if (innovations[_tokenId].totalFractionalShares > 0) revert IPStillHasFractionalShares();
        
        // Check if there are any active licenses for this IP
        for (uint256 i = 1; i < _licenseIdCounter; i++) {
            if (licenses[i].ipTokenId == _tokenId && licenses[i].isActive) {
                revert IPStillHasActiveLicenses();
            }
        }

        uint256 stakeToReturn = innovations[_tokenId].stakeAmount;
        innovations[_tokenId].isActive = false; // Mark as inactive before burning

        _burn(_tokenId);

        // Return the staked SYNAPSE tokens to the creator
        // Checks-Effects-Interactions pattern for token transfer
        innovations[_tokenId].stakeAmount = 0; // Clear stake after transfer

        bool success = synapseToken.transfer(msg.sender, stakeToReturn);
        if (!success) {
            // Funds are stuck here. A recovery mechanism (e.g., manual withdrawal by contract owner)
            // or a more robust `safeTransfer` pattern would be needed in production.
            revert InsufficientStake();
        }

        emit InnovationRevoked(_tokenId, msg.sender);
    }

    /**
     * @notice Retrieves all stored details of a specific innovation.
     * @param _tokenId The ID of the innovation NFT.
     * @return Innovation struct containing all relevant details.
     */
    function getInnovationDetails(uint256 _tokenId) public view returns (Innovation memory) {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        return innovations[_tokenId];
    }

    // --- Part 2: Proof-of-Innovation & Staking ---

    /**
     * @notice Allows the IP creator to increase the stake associated with their innovation.
     * @param _tokenId The ID of the innovation NFT.
     * @param _amount Amount of SYNAPSE tokens to add to the stake.
     */
    function increaseInnovationStake(uint256 _tokenId, uint256 _amount)
        public
        onlyIPCreator(_tokenId)
        onlyActiveIP(_tokenId)
        onlyActiveSynapseToken
    {
        if (_amount == 0) revert ZeroAmount();

        bool success = synapseToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert InsufficientStake();

        innovations[_tokenId].stakeAmount += _amount;
        emit InnovationStakeIncreased(_tokenId, msg.sender, _amount);
    }

    /**
     * @notice Allows the IP creator to withdraw part of their stake.
     *         Subject to a cooldown period after any withdrawal to prevent rapid stake manipulation.
     *         Withdrawal is not allowed if there is an active challenge.
     * @param _tokenId The ID of the innovation NFT.
     * @param _amount Amount of SYNAPSE tokens to withdraw.
     */
    function withdrawInnovationStake(uint256 _tokenId, uint256 _amount)
        public
        onlyIPCreator(_tokenId)
        onlyActiveIP(_tokenId)
        onlyActiveSynapseToken
    {
        if (innovations[_tokenId].isChallenged) revert ChallengeInProgress();
        if (_amount == 0) revert ZeroAmount();
        if (innovations[_tokenId].stakeAmount < _amount) revert InsufficientStake();
        if (innovations[_tokenId].stakeWithdrawalCooldownEnd > block.timestamp) revert StakeWithdrawalCooldown();

        innovations[_tokenId].stakeAmount -= _amount;
        innovations[_tokenId].stakeWithdrawalCooldownEnd = block.timestamp + 1 days; // 1-day cooldown

        bool success = synapseToken.transfer(msg.sender, _amount);
        if (!success) {
            // Revert the stake deduction if token transfer fails
            innovations[_tokenId].stakeAmount += _amount;
            revert InsufficientStake();
        }

        emit InnovationStakeWithdrawal(_tokenId, msg.sender, _amount);
    }

    /**
     * @notice Returns the current stake amount for a given innovation.
     * @param _tokenId The ID of the innovation NFT.
     * @return The total SYNAPSE tokens staked for this innovation.
     */
    function getInnovationStake(uint256 _tokenId) public view returns (uint256) {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        return innovations[_tokenId].stakeAmount;
    }

    // --- Part 3: Fractional Ownership ---

    /**
     * @notice Creates and distributes fractional shares of an innovation to specified recipients.
     *         Only the IP creator or delegated manager can mint shares.
     * @param _tokenId The ID of the innovation NFT.
     * @param _totalShares The total number of shares to represent this IP.
     * @param _recipients Array of addresses to receive shares.
     * @param _amounts Array of amounts corresponding to each recipient.
     */
    function mintFractionalShares(uint256 _tokenId, uint256 _totalShares, address[] memory _recipients, uint256[] memory _amounts)
        public
        onlyActiveIP(_tokenId)
        onlyDelegatedManager(_tokenId, CAN_MINT_FRACTIONAL_SHARES)
    {
        if (_totalShares == 0) revert ZeroAmount();
        if (_recipients.length != _amounts.length) revert InvalidShareRecipient();

        uint256 sumAmounts = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] == address(0)) revert ZeroAddressNotAllowed();
            if (_amounts[i] == 0) revert ZeroAmount();
            sumAmounts += _amounts[i];
        }
        if (sumAmounts > _totalShares) revert NotEnoughShares();

        // If shares were already minted, _totalShares must match.
        // This prevents changing the total supply of fractional shares for an IP.
        if (innovations[_tokenId].totalFractionalShares == 0) {
            innovations[_tokenId].totalFractionalShares = _totalShares;
        } else if (innovations[_tokenId].totalFractionalShares != _totalShares) {
            revert InvalidShareRecipient(); // Cannot change total shares after initial mint
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            innovationShares[_tokenId][_recipients[i]] += _amounts[i];
        }

        emit FractionalSharesMinted(_tokenId, msg.sender, _totalShares);
    }

    /**
     * @notice Transfers fractional shares of an IP from one holder to another.
     * @param _tokenId The ID of the innovation NFT.
     * @param _from The address from which shares are transferred.
     * @param _to The address to which shares are transferred.
     * @param _amount The number of shares to transfer.
     */
    function transferFractionalShare(uint256 _tokenId, address _from, address _to, uint256 _amount) public {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        if (_from == address(0) || _to == address(0)) revert ShareTransferToZeroAddress();
        if (_amount == 0) revert ZeroAmount();
        if (_from != msg.sender) revert NotIPShareholder(); // Only owner of shares can transfer

        if (innovationShares[_tokenId][_from] < _amount) revert NotEnoughShares();

        unchecked {
            innovationShares[_tokenId][_from] -= _amount;
            innovationShares[_tokenId][_to] += _amount;
        }

        emit FractionalShareTransferred(_tokenId, _from, _to, _amount);
    }

    /**
     * @notice Returns the number of fractional shares an address holds for a specific IP.
     * @param _tokenId The ID of the innovation NFT.
     * @param _owner The address to query the balance for.
     * @return The fractional share balance.
     */
    function getFractionalBalance(uint256 _tokenId, address _owner) public view returns (uint256) {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        return innovationShares[_tokenId][_owner];
    }

    /**
     * @notice Allows a fractional share owner to burn their shares.
     * @param _tokenId The ID of the innovation NFT.
     * @param _amount The number of shares to burn.
     */
    function burnFractionalShares(uint256 _tokenId, uint256 _amount) public {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        if (_amount == 0) revert ZeroAmount();
        if (innovationShares[_tokenId][msg.sender] < _amount) revert NotEnoughShares();

        unchecked {
            innovationShares[_tokenId][msg.sender] -= _amount;
            innovations[_tokenId].totalFractionalShares -= _amount; // Reduce total minted shares
        }

        emit FractionalSharesBurned(_tokenId, msg.sender, _amount);
    }

    // --- Part 4: Licensing & Royalty Streams ---

    /**
     * @notice Creator defines a new license offer for their IP.
     * @param _tokenId The ID of the innovation NFT.
     * @param _licenseType The type of license (e.g., 0=CreativeCommons, 1=Commercial, 2=Exclusive).
     * @param _royaltyPercentage The royalty percentage in basis points (e.g., 500 for 5%). Max 10000.
     * @param _durationBlocks The duration of the license in Ethereum blocks.
     * @param _upfrontFee The upfront fee in ETH for accepting this license.
     * @param _licenseTermsURI URI pointing to off-chain detailed license terms.
     */
    function createLicenseOffer(uint256 _tokenId, uint256 _licenseType, uint256 _royaltyPercentage, uint256 _durationBlocks, uint256 _upfrontFee, string calldata _licenseTermsURI)
        public
        onlyActiveIP(_tokenId)
        onlyDelegatedManager(_tokenId, CAN_CREATE_LICENSE_OFFER)
    {
        if (_royaltyPercentage > 10000) revert InvalidRoyaltyPercentage();
        if (_durationBlocks == 0) revert ZeroAmount();
        if (bytes(_licenseTermsURI).length == 0) revert ZeroAddressNotAllowed();

        uint256 newOfferId = _licenseIdCounter++;
        licenseOffers[newOfferId] = LicenseOffer({
            offerId: newOfferId,
            ipTokenId: _tokenId,
            licensor: ownerOf(_tokenId), // Store current IP owner as licensor
            licenseType: _licenseType,
            royaltyPercentage: _royaltyPercentage,
            durationBlocks: _durationBlocks,
            upfrontFee: uint252(_upfrontFee), // Cast to uint252
            termsURI: _licenseTermsURI,
            isActive: true
        });

        emit LicenseOfferCreated(newOfferId, _tokenId, ownerOf(_tokenId), _licenseType, _royaltyPercentage, _durationBlocks, _upfrontFee);
    }

    /**
     * @notice A potential licensee accepts an existing license offer and pays the upfront fee in ETH.
     * @param _tokenId The ID of the innovation NFT.
     * @param _offerId The ID of the license offer to accept.
     */
    function acceptLicenseOffer(uint256 _tokenId, uint256 _offerId) public payable onlyActiveIP(_tokenId) {
        LicenseOffer storage offer = licenseOffers[_offerId];
        if (!offer.isActive || offer.ipTokenId != _tokenId) revert LicenseOfferNotFound();
        if (msg.value < offer.upfrontFee) revert UpfrontFeeRequired();

        offer.isActive = false; // Offer is no longer active after acceptance

        // Transfer upfront fee to the IP creator (current owner of the NFT)
        // Checks-Effects-Interactions pattern
        uint256 feeToTransfer = offer.upfrontFee;
        address currentIPCreator = ownerOf(_tokenId);
        (bool success, ) = currentIPCreator.call{value: feeToTransfer}("");
        if (!success) {
            // Revert if payment fails. Funds sent by msg.value are returned by tx revert.
            // Also, reactivate offer. This implies the funds should not be stuck.
            offer.isActive = true; // Re-activate offer if transfer fails to allow retry
            revert UpfrontFeeRequired();
        }

        uint256 newLicenseId = newOfferId; // Use the same _offerId as licenseId for simplicity, incrementing _licenseIdCounter only once.
        licenses[newLicenseId] = License({
            licenseId: newLicenseId,
            ipTokenId: _tokenId,
            licensee: msg.sender,
            licensor: currentIPCreator, // Store current IP creator as the licensor for this license instance
            licenseType: offer.licenseType,
            royaltyPercentage: offer.royaltyPercentage,
            validUntilBlock: block.number + offer.durationBlocks,
            termsURI: offer.termsURI,
            totalRoyaltiesAccrued: 0,
            isActive: true
        });

        emit LicenseAccepted(newLicenseId, _offerId, _tokenId, msg.sender);
    }

    /**
     * @notice Licensee sends ETH royalty payments for a license.
     *         If the IP has fractional shares, royalties are held by the contract for claiming by fractional owners.
     *         Otherwise, they are sent directly to the IP creator.
     * @param _licenseId The ID of the active license.
     */
    function distributeRoyalties(uint256 _licenseId) public payable onlyLicensee(_licenseId) {
        License storage license = licenses[_licenseId];
        if (!license.isActive) revert LicenseDurationExpired();
        if (block.number > license.validUntilBlock) revert LicenseDurationExpired();
        if (msg.value == 0) revert ZeroAmount();

        uint256 totalRoyalty = msg.value;
        license.totalRoyaltiesAccrued += totalRoyalty;

        Innovation storage innovation = innovations[license.ipTokenId];
        if (innovation.totalFractionalShares == 0) {
            // No fractional shares, send all to current IP creator
            (bool success, ) = ownerOf(license.ipTokenId).call{value: totalRoyalty}("");
            if (!success) {
                // Funds are stuck here.
                revert UpfrontFeeRequired(); // Reusing error
            }
        } else {
            // Fractional shares exist: royalties are accumulated in the contract, to be claimed later.
            accruedRoyaltiesForIP[license.ipTokenId] += totalRoyalty;
        }
        
        emit RoyaltiesDistributed(_licenseId, license.ipTokenId, totalRoyalty);
    }

    /**
     * @notice Allows fractional shareholders of an IP to claim their proportional share of accumulated ETH royalties held by the contract.
     * @param _tokenId The ID of the innovation NFT.
     */
    function claimMyFractionalRoyalties(uint256 _tokenId) public onlyActiveIP(_tokenId) {
        Innovation storage innovation = innovations[_tokenId];
        if (innovation.totalFractionalShares == 0) revert IpCreatorCantClaimFractionalRoyaltiesThisWay(); // This function is for fractional owners
        
        uint256 myShares = innovationShares[_tokenId][msg.sender];
        if (myShares == 0) revert NotIPShareholder();

        uint256 totalAccrued = accruedRoyaltiesForIP[_tokenId];
        uint256 alreadyClaimed = shareholderClaimedAmounts[_tokenId][msg.sender];
        
        uint256 myTotalPotentialEarnings = (totalAccrued * myShares) / innovation.totalFractionalShares;
        uint256 amountToClaim = myTotalPotentialEarnings - alreadyClaimed;

        if (amountToClaim == 0) revert ZeroAmount();

        shareholderClaimedAmounts[_tokenId][msg.sender] += amountToClaim; // Effect

        (bool success, ) = msg.sender.call{value: amountToClaim}(""); // Interaction
        if (!success) {
            // If ETH transfer fails, revert the claim
            shareholderClaimedAmounts[_tokenId][msg.sender] -= amountToClaim;
            revert InsufficientStake(); // Reusing error for ETH transfer failure
        }
        
        emit FractionalRoyaltiesClaimed(_tokenId, msg.sender, amountToClaim);
    }

    /**
     * @notice Retrieves all details of a specific active or inactive license.
     * @param _licenseId The ID of the license.
     * @return License struct containing all relevant details.
     */
    function getLicenseDetails(uint256 _licenseId) public view returns (License memory) {
        if (_licenseId == 0 || _licenseId >= _licenseIdCounter) revert LicenseOfferNotFound();
        return licenses[_licenseId];
    }

    /**
     * @notice Allows the IP creator to revoke an active license.
     *         May incur penalties or conditions (not explicitly implemented here, but could be).
     * @param _licenseId The ID of the license to revoke.
     */
    function revokeLicense(uint256 _licenseId) public {
        License storage license = licenses[_licenseId];
        if (license.licenseId == 0) revert LicenseOfferNotFound();
        if (ownerOf(license.ipTokenId) != msg.sender) revert NotIPCreator(); // Only current IP creator can revoke

        if (!license.isActive) revert LicenseDurationExpired();

        license.isActive = false;
        // Optionally, add logic for penalties, refunds, etc.

        emit LicenseRevoked(_licenseId, license.ipTokenId, msg.sender);
    }

    // --- Part 5: Collaboration Bounties ---

    /**
     * @notice Creator offers a bounty for a specific development or creative task related to their IP.
     *         Requires SYNAPSE tokens to be staked as the bounty amount.
     * @param _tokenId The ID of the innovation NFT.
     * @param _taskDescriptionURI URI pointing to detailed task description.
     * @param _bountyAmount Amount of SYNAPSE tokens for the bounty.
     * @param _deadlineBlock The block number by which solutions must be submitted.
     */
    function createCollaborationBounty(uint256 _tokenId, string calldata _taskDescriptionURI, uint256 _bountyAmount, uint256 _deadlineBlock)
        public
        onlyIPCreator(_tokenId)
        onlyActiveIP(_tokenId)
        onlyActiveSynapseToken
    {
        if (_bountyAmount == 0) revert ZeroAmount();
        if (block.number >= _deadlineBlock) revert BountyDeadlinePassed();
        if (bytes(_taskDescriptionURI).length == 0) revert ZeroAddressNotAllowed();

        bool success = synapseToken.transferFrom(msg.sender, address(this), _bountyAmount);
        if (!success) revert InsufficientStake();

        uint256 newBountyId = _bountyIdCounter++;
        bounties[newBountyId] = Bounty({
            bountyId: newBountyId,
            ipTokenId: _tokenId,
            creator: msg.sender,
            taskDescriptionURI: _taskDescriptionURI,
            amount: _bountyAmount,
            deadlineBlock: _deadlineBlock,
            awardedTo: address(0),
            solutionURI: "", // Solution URI is set only when awarded
            isActive: true
        });

        emit CollaborationBountyCreated(newBountyId, _tokenId, msg.sender, _bountyAmount, _deadlineBlock);
    }

    /**
     * @notice A participant submits their solution to an active bounty.
     * @param _bountyId The ID of the bounty.
     * @param _solutionURI URI pointing to the submitted solution.
     * @dev This function only emits an event. The actual review and award process is off-chain.
     *      Multiple solutions can be submitted. The creator decides the winner.
     */
    function submitBountySolution(uint256 _bountyId, string calldata _solutionURI) public {
        Bounty storage bounty = bounties[_bountyId];
        if (bounty.bountyId == 0) revert BountyNotFound();
        if (!bounty.isActive) revert BountyNotActive();
        if (block.number > bounty.deadlineBlock) revert BountyDeadlinePassed();
        if (bytes(_solutionURI).length == 0) revert ZeroAddressNotAllowed();

        emit BountySolutionSubmitted(_bountyId, msg.sender, _solutionURI);
    }

    /**
     * @notice Creator or delegated manager awards the bounty to a winning participant, transferring the bounty amount.
     * @param _bountyId The ID of the bounty.
     * @param _winner The address of the winning participant.
     */
    function awardBounty(uint256 _bountyId, address _winner)
        public
        onlyDelegatedManager(bounties[_bountyId].ipTokenId, CAN_AWARD_BOUNTY)
        onlyActiveSynapseToken
    {
        Bounty storage bounty = bounties[_bountyId];
        if (bounty.bountyId == 0) revert BountyNotFound();
        if (!bounty.isActive) revert BountyNotActive();
        if (bounty.awardedTo != address(0)) revert BountyAlreadyAwarded();
        if (_winner == address(0)) revert ZeroAddressNotAllowed();

        bounty.awardedTo = _winner;
        bounty.isActive = false; // Bounty is now closed
        // bounty.solutionURI is not stored here, as submitBountySolution is event-only.
        // If a specific solution URI should be stored, it would need to be passed here.

        // Checks-Effects-Interactions pattern
        uint256 amountToTransfer = bounty.amount;
        bounty.amount = 0; // Clear bounty amount after transfer attempt

        bool success = synapseToken.transfer(_winner, amountToTransfer);
        if (!success) {
            // Revert if token transfer fails
            bounty.awardedTo = address(0);
            bounty.isActive = true;
            bounty.amount = amountToTransfer; // Restore amount
            revert InsufficientStake();
        }

        emit BountyAwarded(_bountyId, _winner, amountToTransfer);
    }

    // --- Part 6: IP Guardian & Dispute Resolution ---

    /**
     * @notice Allows a user to stake SYNAPSE tokens to become an "IP Guardian" and participate in dispute resolution.
     * @dev Requires staking at least `minGuardianStake` SYNAPSE tokens.
     *      Funds are transferred from msg.sender to the contract.
     */
    function becomeIPGuardian() public onlyActiveSynapseToken {
        uint256 currentStake = ipGuardians[msg.sender];
        if (currentStake >= minGuardianStake) {
            // Already a guardian with sufficient stake. Can optionally allow increasing stake.
            // For now, let's just allow maintaining min stake.
            return;
        }

        uint256 amountToStake = minGuardianStake - currentStake;
        if (synapseToken.balanceOf(msg.sender) < amountToStake) revert InsufficientStake();
        
        bool success = synapseToken.transferFrom(msg.sender, address(this), amountToStake);
        if (!success) revert InsufficientStake();
        ipGuardians[msg.sender] += amountToStake;
        
        emit IPGuardianBecame(msg.sender, ipGuardians[msg.sender]);
    }

    /**
     * @notice Allows any user to challenge the uniqueness or validity of an IP by staking SYNAPSE tokens.
     * @param _tokenId The ID of the innovation NFT being challenged.
     * @param _reasonURI URI pointing to detailed reasons and evidence for the challenge.
     * @param _challengeStake Amount of SYNAPSE tokens to stake for this challenge.
     * @dev The challenge stake serves as a bond. If the challenge is frivolous, the stake is lost.
     */
    function challengeInnovation(uint256 _tokenId, string calldata _reasonURI, uint256 _challengeStake) public onlyActiveSynapseToken {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        if (innovations[_tokenId].isChallenged) revert IPAlreadyChallenged();
        if (_challengeStake == 0) revert ZeroAmount();
        if (bytes(_reasonURI).length == 0) revert ZeroAddressNotAllowed();

        // Challenger transfers stake to this contract
        bool success = synapseToken.transferFrom(msg.sender, address(this), _challengeStake);
        if (!success) revert InsufficientStake();

        uint256 newChallengeId = _challengeIdCounter++;
        challenges[newChallengeId] = Challenge({
            challengeId: newChallengeId,
            ipTokenId: _tokenId,
            challenger: msg.sender,
            reasonURI: _reasonURI,
            stakeAmount: _challengeStake,
            challengeStartBlock: block.number,
            challengeEndBlock: block.number + 7200, // Example: 7200 blocks (~24 hours at 12s/block) for voting
            votesForInfringement: 0,
            votesAgainstInfringement: 0,
            hasVoted: new mapping(address => bool), // Initialize new mapping
            isResolved: false,
            infringementFound: false,
            isActive: true
        });

        innovations[_tokenId].isChallenged = true;
        emit InnovationChallenged(newChallengeId, _tokenId, msg.sender, _challengeStake);
    }

    /**
     * @notice IP Guardians vote on whether a challenged IP is infringing or valid.
     * @param _challengeId The ID of the ongoing challenge.
     * @param _isInfringement True if the guardian believes the IP is infringing, false otherwise.
     */
    function voteOnChallenge(uint256 _challengeId, bool _isInfringement) public onlyIPGuardian {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challengeId == 0) revert ChallengeNotFound();
        if (!challenge.isActive) revert ChallengeNotFound(); // Challenge might be resolved or inactive
        if (block.number > challenge.challengeEndBlock) revert BountyDeadlinePassed(); // Voting period expired
        if (challenge.hasVoted[msg.sender]) revert ChallengeAlreadyVoted();

        challenge.hasVoted[msg.sender] = true;
        // No need to store guardianVoteResult per guardian, just count the votes
        if (_isInfringement) {
            challenge.votesForInfringement++;
        } else {
            challenge.votesAgainstInfringement++;
        }
        emit GuardianVoted(_challengeId, msg.sender, _isInfringement);
    }

    /**
     * @notice Resolves an IP challenge after the voting period, redistributing SYNAPSE stakes based on guardian votes.
     *         Callable by anyone after the voting period ends.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveChallenge(uint256 _challengeId) public onlyActiveSynapseToken {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challengeId == 0) revert ChallengeNotFound();
        if (!challenge.isActive) revert ChallengeNotFound();
        if (block.number <= challenge.challengeEndBlock) revert ChallengeNotInResolution();
        if (challenge.isResolved) revert ChallengeAlreadyResolved();

        challenge.isResolved = true;
        challenge.isActive = false; // Deactivate challenge

        Innovation storage innovation = innovations[challenge.ipTokenId];
        innovations[challenge.ipTokenId].isChallenged = false; // Mark IP as no longer challenged

        uint256 totalGuardianVotes = challenge.votesForInfringement + challenge.votesAgainstInfringement;
        
        bool challengerWins = false;
        // If there are more votes for infringement, or if there are no votes and challenger stake is high (optional rule)
        // For simplicity, challenger wins if votesFor > votesAgainst, assuming guardians participate.
        if (totalGuardianVotes > 0 && challenge.votesForInfringement > challenge.votesAgainstInfringement) {
            challengerWins = true;
        }

        if (challengerWins) {
            // Challenger wins: innovation is deemed infringing/invalid.
            innovation.isActive = false; // IP is now invalid/inactive
            challenge.infringementFound = true;

            uint256 challengerRewardPercentage = 10; // 10% of IP creator's stake as reward
            uint256 creatorSlashPercentage = 15; // Creator loses 15% of stake

            uint256 rewardFromCreatorStake = (innovation.stakeAmount * challengerRewardPercentage) / 100;
            if (rewardFromCreatorStake > innovation.stakeAmount) rewardFromCreatorStake = innovation.stakeAmount; // Cap at available stake

            uint256 creatorSlashedAmount = (innovation.stakeAmount * creatorSlashPercentage) / 100;
            if (creatorSlashedAmount > innovation.stakeAmount) creatorSlashedAmount = innovation.stakeAmount;

            // Return challenger's initial stake
            bool success1 = synapseToken.transfer(challenge.challenger, challenge.stakeAmount);
            if (!success1) { /* log or emergency path */ }

            // Reward challenger from creator's stake
            if (rewardFromCreatorStake > 0) {
                bool success2 = synapseToken.transfer(challenge.challenger, rewardFromCreatorStake);
                if (success2) {
                    innovations[challenge.ipTokenId].stakeAmount -= rewardFromCreatorStake;
                }
            }

            // Slash creator's stake and burn it (or redistribute to guardians, which is complex)
            uint256 remainingSlashAmount = creatorSlashedAmount;
            if (innovations[challenge.ipTokenId].stakeAmount < remainingSlashAmount) {
                remainingSlashAmount = innovations[challenge.ipTokenId].stakeAmount;
            }
            innovations[challenge.ipTokenId].stakeAmount -= remainingSlashAmount;
            if (remainingSlashAmount > 0) {
                bool success3 = synapseToken.transfer(address(0xdead), remainingSlashAmount); // Burn to dead address
                if (!success3) { /* log */ }
            }

        } else {
            // IP creator wins: challenge is rejected.
            challenge.infringementFound = false;

            uint256 creatorRewardPercentage = 50; // 50% of challenger's stake as reward
            uint256 challengerLostStake = challenge.stakeAmount; // Challenger loses all their stake

            uint256 creatorRewardFromChallengerStake = (challengerLostStake * creatorRewardPercentage) / 100;
            if (creatorRewardFromChallengerStake > challengerLostStake) creatorRewardFromChallengerStake = challengerLostStake;

            // Reward IP creator from challenger's stake
            if (creatorRewardFromChallengerStake > 0) {
                bool success1 = synapseToken.transfer(innovation.creator, creatorRewardFromChallengerStake);
                if (success1) {
                     // Challenger's stake (the portion not given to creator) is effectively burned.
                     uint256 remainingChallengerStake = challengerLostStake - creatorRewardFromChallengerStake;
                     if (remainingChallengerStake > 0) {
                        bool success2 = synapseToken.transfer(address(0xdead), remainingChallengerStake); // Burn
                        if (!success2) { /* log */ }
                     }
                }
            } else { // No reward to creator, burn all challenger stake
                if (challengerLostStake > 0) {
                    bool success3 = synapseToken.transfer(address(0xdead), challengerLostStake); // Burn
                    if (!success3) { /* log */ }
                }
            }
        }
        
        emit ChallengeResolved(_challengeId, challenge.ipTokenId, challenge.infringementFound);
    }

    // --- Part 7: Advanced IP Management & Governance ---

    /**
     * @notice Allows the IP creator to delegate specific management rights to another address.
     * @param _tokenId The ID of the innovation NFT.
     * @param _delegatee The address to delegate rights to.
     * @param _rightsMask A bitmask representing the rights to delegate (e.g., CAN_CREATE_LICENSE_OFFER).
     */
    function delegateIPManagement(uint256 _tokenId, address _delegatee, uint256 _rightsMask) public onlyIPCreator(_tokenId) onlyActiveIP(_tokenId) {
        if (_delegatee == address(0)) revert ZeroAddressNotAllowed();
        // Allow _rightsMask to be 0 to revoke all delegated rights
        delegatedRights[_tokenId][_delegatee] = _rightsMask;
        emit IPManagementDelegated(_tokenId, msg.sender, _delegatee, _rightsMask);
    }

    /**
     * @notice Initiates a proposal to merge multiple IPs into a new one.
     *         Requires agreement from all involved IP owners.
     * @param _tokenIdsToMerge An array of IP token IDs to be merged.
     * @param _newMetadataURI URI for the metadata of the new merged IP.
     * @param _newOwner The address that will own the new merged IP NFT.
     */
    function proposeIPMerge(uint256[] memory _tokenIdsToMerge, string calldata _newMetadataURI, address _newOwner) public {
        if (_tokenIdsToMerge.length < 2) revert InvalidMergeIPs();
        if (_newOwner == address(0)) revert ZeroAddressNotAllowed();
        if (bytes(_newMetadataURI).length == 0) revert ZeroAddressNotAllowed();

        uint256 newProposalId = _mergeProposalIdCounter++;
        MergeProposal storage proposal = mergeProposals[newProposalId];
        proposal.proposalId = newProposalId;
        proposal.proposer = msg.sender;
        proposal.ipTokenIds = _tokenIdsToMerge;
        proposal.newMetadataURI = _newMetadataURI;
        proposal.newOwner = _newOwner;
        proposal.createdAt = block.timestamp;

        // Ensure all IPs are active and msg.sender is one of the owners, and records initial approval
        bool senderIsOwnerOfAny = false;
        for (uint256 i = 0; i < _tokenIdsToMerge.length; i++) {
            uint256 tokenId = _tokenIdsToMerge[i];
            if (!_exists(tokenId) || !innovations[tokenId].isActive) revert InvalidMergeIPs();
            if (ownerOf(tokenId) == msg.sender) {
                proposal.hasApproved[tokenId] = true;
                proposal.approvalCount++;
                senderIsOwnerOfAny = true;
            } else {
                // Ensure caller doesn't try to merge IPs they don't own if they aren't the primary owner
                // This logic is for multi-owner proposals, the proposer must own at least one.
            }
        }
        if (!senderIsOwnerOfAny) revert NotIPCreator(); // Proposer must be an owner of at least one IP

        emit IPMergeProposalCreated(newProposalId, msg.sender, _tokenIdsToMerge, _newOwner);
    }

    /**
     * @notice Owners of IPs involved in a merge proposal cast their vote.
     * @param _mergeProposalId The ID of the merge proposal.
     * @param _approve True to approve the merge, false to reject.
     */
    function voteOnIPMergeProposal(uint256 _mergeProposalId, bool _approve) public {
        MergeProposal storage proposal = mergeProposals[_mergeProposalId];
        if (proposal.proposalId == 0) revert MergeProposalNotFound();
        if (proposal.isExecuted || proposal.isRejected) revert MergeProposalNotPending();

        bool isOwnerOfParticipatingIP = false;
        for (uint256 i = 0; i < proposal.ipTokenIds.length; i++) {
            if (ownerOf(proposal.ipTokenIds[i]) == msg.sender) {
                isOwnerOfParticipatingIP = true;
                if (proposal.hasApproved[proposal.ipTokenIds[i]] || proposal.hasRejected[proposal.ipTokenIds[i]]) {
                    revert ChallengeAlreadyVoted(); // Reusing error for already voted
                }
                if (_approve) {
                    proposal.hasApproved[proposal.ipTokenIds[i]] = true;
                    proposal.approvalCount++;
                } else {
                    proposal.hasRejected[proposal.ipTokenIds[i]] = true;
                    proposal.isRejected = true; // Any single rejection rejects the whole proposal
                }
                break; // An owner only votes once per IP, assuming 1 IP per owner for simplicity
                       // If an owner holds multiple IPs in the proposal, they must cast separate votes.
                       // For simplicity, we assume an owner casts one vote for *all* their IPs in the proposal.
                       // A more robust system would require voting per (owner, tokenId) pair.
            }
        }
        if (!isOwnerOfParticipatingIP) revert NotIPCreator();

        emit IPMergeProposalVoted(_mergeProposalId, msg.sender, _approve);
    }

    /**
     * @notice Finalizes the IP merge after all necessary approvals.
     *         Mints a new IP NFT and burns the old ones. Only callable by the proposer after all approvals.
     * @param _mergeProposalId The ID of the merge proposal.
     */
    function executeIPMerge(uint256 _mergeProposalId) public onlyActiveSynapseToken {
        MergeProposal storage proposal = mergeProposals[_mergeProposalId];
        if (proposal.proposalId == 0) revert MergeProposalNotFound();
        if (proposal.proposer != msg.sender) revert OnlyProposerCanExecuteMerge();
        if (proposal.isExecuted) revert MergeAlreadyExecuted();
        if (proposal.isRejected) revert MergeProposalNotPending();

        // Check if all IP owners (who are part of the proposal) have approved
        // This implicitly assumes only one owner per tokenId in the proposal for `ownerOf(tokenId) == msg.sender`.
        // The `approvalCount` should match the number of *distinct IPs* in the proposal that had an owner.
        // A more complex check would iterate all distinct owners of `proposal.ipTokenIds` and check their vote.
        // For simplicity: `approvalCount` must equal `ipTokenIds.length` implies all IPs have been approved by their respective owners.
        if (proposal.approvalCount != proposal.ipTokenIds.length) revert NotAllIPOwnersApproved();

        // All owners approved, execute the merge
        // Mint a new IP NFT representing the merged innovation
        uint256 newMergedTokenId = _innovationIdCounter++;
        _mint(proposal.newOwner, newMergedTokenId);

        // Aggregate stake from all merged IPs
        uint256 aggregatedStake = 0;
        for (uint256 i = 0; i < proposal.ipTokenIds.length; i++) {
            uint256 oldTokenId = proposal.ipTokenIds[i];
            if (innovations[oldTokenId].isChallenged) revert ChallengeInProgress(); // Cannot merge challenged IP
            
            aggregatedStake += innovations[oldTokenId].stakeAmount;
            
            // Burn old IPs
            innovations[oldTokenId].isActive = false; // Mark old IPs as inactive
            _burn(oldTokenId);
        }

        // Create the new merged innovation
        innovations[newMergedTokenId] = Innovation({
            tokenId: newMergedTokenId,
            creator: proposal.newOwner,
            ipHash: "merged_ip_hash", // Placeholder. In a real system, generate a new hash of combined IP content.
            metadataURI: proposal.newMetadataURI,
            stakeAmount: aggregatedStake,
            createdAt: block.timestamp,
            totalFractionalShares: 0, // Merged IP starts without fractional shares unless specifically re-minted
            isChallenged: false,
            isActive: true,
            stakeWithdrawalCooldownEnd: 0
        });

        proposal.isExecuted = true;
        proposal.newIPTokenId = newMergedTokenId;

        emit IPMergeExecuted(_mergeProposalId, newMergedTokenId, proposal.newOwner);
    }

    /**
     * @notice Allows the contract owner to set the address of the ERC-20 SynapseToken for staking.
     * @param _synapseTokenAddress The address of the deployed SynapseToken contract.
     */
    function configureSynapseToken(address _synapseTokenAddress) public onlyOwner {
        if (_synapseTokenAddress == address(0)) revert ZeroAddressNotAllowed();
        synapseToken = IERC20(_synapseTokenAddress);
        emit SynapseTokenConfigured(_synapseTokenAddress);
    }
}

// Minimal ERC721 interface for direct implementation (from ERC-721 standard)
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```