This smart contract, **ImpulseForge**, is designed to be a decentralized platform for collaborative generative AI art creation and dynamic licensing. It combines concepts of staking, DAO-like governance, and NFT minting with a unique focus on community-curated AI outputs and flexible revenue sharing.

**Core Concept:**
Users submit "creative impulses" (prompts/style guides) by staking `ImpulseToken`s (an ERC20 token). The community votes on these impulses. Once approved and sufficiently staked, an off-chain AI oracle is requested to generate a unique art piece. This art piece is then minted as an `ArtPieceNFT` (ERC721). The community, or the art piece owner, can then propose dynamic licensing terms for these NFTs, which are again voted on. Revenue generated from these licenses is automatically distributed to the original impulse stakers, the art piece owner, the AI oracle, and the platform.

---

### **Outline**

1.  **Contract Setup & Administration:** Core configurations, ownership, pausing, and emergency functions.
2.  **Impulse Token (ERC20):** A separate, integrated contract for staking and voting.
3.  **Impulse Management & Staking:** Users submit creative prompts, stake tokens, and manage their contributions.
4.  **AI Art Generation & Minting:** Orchestrates the off-chain AI to generate art and mint it as NFTs.
5.  **Community Curation & Voting:** Decentralized governance for approving impulses and licensing terms.
6.  **Dynamic Licensing & Revenue Distribution:** Mechanisms for acquiring and managing art licenses, distributing revenue shares.
7.  **Advanced Features & Utilities:** Voting delegation, and comprehensive data retrieval view functions.

---

### **Function Summary (Total: 26 Functions)**

**I. Contract Setup & Administration**
1.  `constructor(address _impulseTokenAddress)`: Initializes the `ImpulseForge` contract, linking it to the `ImpulseToken` and setting initial owner.
2.  `setAIOracleAddress(address _oracle)`: Owner-only. Sets the trusted address for the AI generation oracle.
3.  `setMinimumImpulseStake(uint256 _amount)`: Owner-only. Defines the minimum `ImpulseToken` stake required for a new creative impulse.
4.  `setGlobalFeeRecipient(address _recipient)`: Owner-only. Specifies the address to receive platform fees.
5.  `pauseContract()`: Owner-only. Emergency function to halt critical contract operations (e.g., staking, licensing).
6.  `unpauseContract()`: Owner-only. Resumes critical contract operations.
7.  `emergencyWithdrawFunds(address _tokenAddress)`: Owner-only. Allows the owner to rescue accidentally sent ERC20 tokens.
8.  `setRevenueDistributionPercentages(uint256 _platformFee, uint256 _oracleFee, uint256 _impulseStakerShare, uint256 _ownerShare)`: Owner-only. Configures how revenue from licenses is split (percentages sum to 100%).

**II. Impulse Management & Staking**
9.  `submitCreativeImpulse(string memory _promptURI)`: Allows users to submit a creative prompt (e.g., IPFS hash of a text prompt, style guide) by staking `minimumImpulseStake` `ImpulseToken`s.
10. `increaseImpulseStake(uint256 _impulseId, uint256 _amount)`: Enables users to add more `ImpulseToken`s to their existing impulse.
11. `withdrawImpulseStake(uint256 _impulseId)`: Allows users to withdraw their stake from an impulse if it's rejected, fails to get approved, or after a cool-down period.

**III. AI Art Generation & Minting**
12. `requestArtGeneration(uint256 _impulseId)`: Oracle-only. Initiates an off-chain AI art generation request for an approved and sufficiently staked impulse.
13. `fulfillArtGeneration(uint256 _impulseId, string memory _tokenURI)`: Oracle-only. Mints a new `ArtPieceNFT` with associated metadata (e.g., IPFS hash of the generated image) after the AI successfully generates the art.
14. `updateArtMetadata(uint256 _artPieceId, string memory _newTokenURI)`: `ArtPieceNFT` owner-only. Allows updating non-critical metadata (e.g., IPFS hash to a higher-res image, description).

**IV. Community Curation & Voting**
15. `voteOnImpulseApproval(uint256 _impulseId, bool _approve)`: `ImpulseToken` holders can cast a stake-weighted vote to approve or reject a creative impulse.
16. `proposeArtLicenseTerms(uint256 _artPieceId, uint256 _price, uint256 _duration, string memory _termsURI)`: `ArtPieceNFT` owner or impulse stakers can propose specific licensing terms for an art piece.
17. `voteOnLicenseProposal(uint256 _artPieceId, bool _approve)`: `ImpulseToken` holders can cast a stake-weighted vote on proposed licensing terms.

**V. Dynamic Licensing & Revenue Distribution**
18. `acquireArtLicense(uint256 _artPieceId)`: Enables users to purchase a license for an `ArtPieceNFT` based on the currently approved terms. Handles native token payment and revenue distribution.
19. `releaseArtLicense(uint256 _artPieceId)`: Allows a licensee to terminate/release their acquired license if it's active.
20. `registerLicenseEvent(uint256 _artPieceId, address _licensee, string memory _eventType)`: Oracle-only. Records external licensing milestones or events (e.g., successful commercial use detected).
21. `claimImpulseRewards(uint256 _impulseId)`: Allows stakers of an impulse to claim their prorated share of licensing revenues generated by the associated art piece.
22. `claimArtPieceCreatorRevenue(uint256 _artPieceId)`: Allows the original `ArtPieceNFT` creator (or current owner) to claim their share of licensing revenue.

**VI. Advanced Features & Utilities**
23. `delegateVotingPower(address _delegatee)`: Allows users to delegate their `ImpulseToken` voting rights to another address.
24. `getImpulseDetails(uint256 _impulseId)`: View function. Retrieves comprehensive details about a creative impulse.
25. `getArtPieceDetails(uint256 _artPieceId)`: View function. Retrieves comprehensive details about an `ArtPieceNFT` (including associated impulse ID and revenue).
26. `getLicenseDetails(uint256 _artPieceId, address _licensee)`: View function. Retrieves details about an active license for a specific `ArtPieceNFT` and licensee.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

// --- Custom Errors for Clarity and Gas Efficiency ---
error Unauthorized();
error InsufficientStake(uint256 required, uint256 provided);
error ImpulseNotFound();
error ArtPieceNotFound();
error AlreadyVotedOnImpulse();
error AlreadyVotedOnLicense();
error VotingPeriodNotActive();
error VotingPeriodNotEnded();
error NoActiveLicense(uint256 artPieceId, address licensee);
error CannotClaimZeroRevenue();
error InvalidImpulseState();
error ArtPieceAlreadyGenerated();
error NotYetGenerated();
error InvalidProposalState(); // Used for general invalid proposal conditions
error ImpulseNotApprovedForGeneration();
error NoPendingLicenseProposal();
error LicenseTermsNotApproved();
error StakingLocked(); // Cannot withdraw stake at this time
error InvalidRevenuePercentageSum(); // Sum of revenue percentages exceeds 100%
error ZeroAddressNotAllowed();

// --- I. Impulse Token (ERC20 for Staking and Voting) ---
// This contract is defined within the same file and intended to be deployed by ImpulseForge.
contract ImpulseToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    constructor(address initialOwner) ERC20("Impulse Token", "IMP") Ownable(initialOwner) {
        // Mint initial supply to the owner or a designated address for distribution
        _mint(initialOwner, 1_000_000_000 * 10 ** 18); // Example: 1 Billion tokens
    }

    // Allows the ImpulseForge (owner) to mint new tokens if needed (e.g., for rewards)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Owner can pause/unpause token transfers if necessary (e.g., during upgrades or attacks)
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Override internal _update function for Pausable functionality
    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, amount);
    }
}

// --- Main Contract: ImpulseForge ---
// Manages ArtPiece NFTs (ERC721), ImpulseToken staking, and governance logic.
contract ImpulseForge is ERC721Burnable, Pausable, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Addresses
    ImpulseToken public impulseToken; // Instance of the deployed ImpulseToken contract
    address public aiOracleAddress;     // Trusted oracle address for AI generation
    address public globalFeeRecipient;  // Address for platform fees

    // Configuration
    uint256 public minimumImpulseStake; // Minimum IMP tokens required to submit an impulse
    uint256 public impulseApprovalVotingDuration; // Duration for impulse approval voting
    uint256 public licenseProposalVotingDuration; // Duration for license proposal voting
    uint256 public impulseWithdrawCoolDown; // Cool-down period before stake withdrawal after rejection
    
    // Revenue Distribution Percentages (total must be <= 10000 for 100%)
    uint256 public platformFeePercentage; // e.g., 500 for 5%
    uint256 public oracleFeePercentage;   // e.g., 200 for 2%
    uint256 public impulseStakerSharePercentage; // e.g., 3000 for 30%
    uint256 public ownerSharePercentage;  // e.g., 6300 for 63%

    // Counters for unique IDs
    Counters.Counter private _impulseIdCounter;
    Counters.Counter private _artPieceIdCounter;

    // Data Structures
    enum ImpulseState { PendingApproval, Approved, Rejected, ArtGenerated, Withdrawn }

    struct CreativeImpulse {
        address submitter;
        string promptURI; // IPFS hash or URL for the creative prompt/data
        uint256 totalStake;
        ImpulseState state;
        uint256 submissionTime;
        uint256 artPieceId; // 0 if no art generated yet
        mapping(address => uint256) stakers; // Individual stakes by address
        mapping(address => bool) hasVotedForApproval; // Track approval votes per address
        uint256 approvalVoteYes; // Total voting power for approval
        uint256 approvalVoteNo;  // Total voting power against approval
        uint256 approvalVotingEndTime; // Timestamp when voting for this impulse ends
        uint256 claimedRevenue; // Total revenue claimed by impulse stakers for this impulse
    }
    mapping(uint256 => CreativeImpulse) public impulses;

    enum LicenseState { Proposed, Approved, Rejected, Active, Expired, Terminated }

    struct ArtPieceLicense {
        address licensee;
        uint256 price; // Price in ETH/native token for the license
        uint256 duration; // Duration in seconds (0 for perpetual)
        string termsURI; // IPFS hash or URL for detailed license terms
        LicenseState state;
        uint256 proposalTime;
        uint256 activationTime;
        uint256 expirationTime;
        uint256 totalPaid; // Total amount paid for this specific license instance
        mapping(address => bool) hasVotedForLicense; // Track license votes per address
        uint256 licenseVoteYes; // Total voting power for license approval
        uint256 licenseVoteNo;  // Total voting power against license approval
        uint256 licenseVotingEndTime; // Timestamp when voting for this license proposal ends
    }
    // Stores the current *proposal* for an art piece's license terms
    mapping(uint256 => ArtPieceLicense) public currentLicenseProposal;
    // Stores *active/past* licenses for an art piece, mapped by licensee address
    mapping(uint256 => mapping(address => ArtPieceLicense)) public activeLicenses;

    // Voting delegation for ImpulseToken holders
    mapping(address => address) public votingDelegates;

    // Track total revenue for each art piece and amount claimed by owner
    mapping(uint256 => uint256) private _artPieceTotalRevenue; // Total gross revenue received for an ArtPiece
    mapping(uint256 => uint256) public artPieceClaimedOwnerRevenue; // Total revenue claimed by the ArtPiece owner

    // --- Events ---
    event ImpulseSubmitted(uint256 indexed impulseId, address indexed submitter, string promptURI, uint256 stakeAmount);
    event ImpulseStakeIncreased(uint256 indexed impulseId, address indexed staker, uint256 amount);
    event ImpulseStakeWithdrawn(uint256 indexed impulseId, address indexed staker, uint256 amount);
    event ImpulseApprovalVoted(uint256 indexed impulseId, address indexed voter, bool approved, uint256 votingPower);
    event ImpulseApproved(uint256 indexed impulseId);
    event ImpulseRejected(uint256 indexed impulseId);
    event ArtGenerationRequested(uint256 indexed impulseId, address indexed oracle);
    event ArtPieceMinted(uint256 indexed artPieceId, uint256 indexed impulseId, address indexed owner, string tokenURI);
    event ArtMetadataUpdated(uint256 indexed artPieceId, string newTokenURI);
    event LicenseProposed(uint256 indexed artPieceId, address indexed proposer, uint256 price, uint256 duration, string termsURI);
    event LicenseProposalVoted(uint256 indexed artPieceId, address indexed voter, bool approved, uint256 votingPower);
    event LicenseApproved(uint256 indexed artPieceId);
    event LicenseRejected(uint256 indexed artPieceId);
    event ArtLicenseAcquired(uint256 indexed artPieceId, address indexed licensee, uint256 pricePaid, uint256 duration);
    event ArtLicenseReleased(uint256 indexed artPieceId, address indexed licensee);
    event LicenseEventRegistered(uint256 indexed artPieceId, address indexed licensee, string eventType);
    event ImpulseRewardsClaimed(uint256 indexed impulseId, address indexed staker, uint256 amount);
    event CreatorRevenueClaimed(uint256 indexed artPieceId, address indexed owner, uint256 amount);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event FundsWithdrawn(address indexed recipient, uint256 amount); // For owner withdrawals (fees, emergency)
    event RevenueDistributionPercentagesUpdated(uint256 platformFee, uint256 oracleFee, uint256 impulseStakerShare, uint256 ownerShare);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyArtPieceOwner(uint256 _artPieceId) {
        if (ownerOf(_artPieceId) != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    modifier whenImpulseState(uint256 _impulseId, ImpulseState _expectedState) {
        if (impulses[_impulseId].state != _expectedState) {
            revert InvalidImpulseState();
        }
        _;
    }

    modifier validImpulse(uint256 _impulseId) {
        if (_impulseId == 0 || impulses[_impulseId].submitter == address(0)) { // 0 is invalid ID, submitter address(0) means uninitialized
            revert ImpulseNotFound();
        }
        _;
    }

    modifier validArtPiece(uint256 _artPieceId) {
        if (_artPieceId == 0 || ownerOf(_artPieceId) == address(0)) { // ownerOf will revert for non-existent token, but 0 is easier to check
            revert ArtPieceNotFound();
        }
        _;
    }

    modifier notGenerated(uint256 _impulseId) {
        if (impulses[_impulseId].artPieceId != 0) {
            revert ArtPieceAlreadyGenerated();
        }
        _;
    }

    modifier generated(uint256 _impulseId) {
        if (impulses[_impulseId].artPieceId == 0) {
            revert NotYetGenerated();
        }
        _;
    }

    // --- I. Constructor & Setup (8 functions) ---

    // 1. constructor
    constructor(address _impulseTokenAddress) ERC721("ArtPiece NFT", "ART") Ownable(msg.sender) Pausable() {
        if (_impulseTokenAddress == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        impulseToken = ImpulseToken(_impulseTokenAddress); // Link to the deployed ImpulseToken contract
        
        aiOracleAddress = address(0); // Must be set by owner later
        globalFeeRecipient = msg.sender; // Default to owner, can be changed

        // Default configurations
        minimumImpulseStake = 100 * (10 ** 18); // Example: 100 tokens (assuming 18 decimals)
        impulseApprovalVotingDuration = 3 days;
        licenseProposalVotingDuration = 2 days;
        impulseWithdrawCoolDown = 7 days;

        // Default revenue distribution: 5% platform, 2% oracle, 30% stakers, 63% owner
        platformFeePercentage = 500; // 5%
        oracleFeePercentage = 200;   // 2%
        impulseStakerSharePercentage = 3000; // 30%
        ownerSharePercentage = 6300; // 63%
        if (platformFeePercentage + oracleFeePercentage + impulseStakerSharePercentage + ownerSharePercentage > 10000) {
            revert InvalidRevenuePercentageSum();
        }
    }

    // 2. setAIOracleAddress
    function setAIOracleAddress(address _oracle) public onlyOwner {
        if (_oracle == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        aiOracleAddress = _oracle;
    }

    // 3. setMinimumImpulseStake
    function setMinimumImpulseStake(uint256 _amount) public onlyOwner {
        minimumImpulseStake = _amount;
    }

    // 4. setGlobalFeeRecipient
    function setGlobalFeeRecipient(address _recipient) public onlyOwner {
        if (_recipient == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        globalFeeRecipient = _recipient;
    }

    // 5. pauseContract
    function pauseContract() public onlyOwner {
        _pause();
        impulseToken.pause(); // Also pause the associated token
    }

    // 6. unpauseContract
    function unpauseContract() public onlyOwner {
        _unpause();
        impulseToken.unpause(); // Also unpause the associated token
    }

    // 7. emergencyWithdrawFunds (for accidentally sent ERC20 tokens)
    function emergencyWithdrawFunds(address _tokenAddress) public onlyOwner {
        if (_tokenAddress == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        ERC20 token = ERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
        emit FundsWithdrawn(owner(), balance);
    }

    // 8. setRevenueDistributionPercentages
    function setRevenueDistributionPercentages(
        uint256 _platformFee,
        uint256 _oracleFee,
        uint256 _impulseStakerShare,
        uint256 _ownerShare
    ) public onlyOwner {
        if (_platformFee + _oracleFee + _impulseStakerShare + _ownerShare > 10000) {
            revert InvalidRevenuePercentageSum();
        }
        platformFeePercentage = _platformFee;
        oracleFeePercentage = _oracleFee;
        impulseStakerSharePercentage = _impulseStakerShare;
        ownerSharePercentage = _ownerShare;
        emit RevenueDistributionPercentagesUpdated(_platformFee, _oracleFee, _impulseStakerShare, _ownerShare);
    }

    // --- II. Impulse Management & Staking (3 functions) ---

    // 9. submitCreativeImpulse
    function submitCreativeImpulse(string memory _promptURI) public payable whenNotPaused returns (uint256) {
        if (impulseToken.balanceOf(msg.sender) < minimumImpulseStake) {
            revert InsufficientStake(minimumImpulseStake, impulseToken.balanceOf(msg.sender));
        }
        if (impulseToken.allowance(msg.sender, address(this)) < minimumImpulseStake) {
            revert Unauthorized(); // User needs to approve tokens first
        }

        impulseToken.transferFrom(msg.sender, address(this), minimumImpulseStake);

        _impulseIdCounter.increment();
        uint256 newImpulseId = _impulseIdCounter.current();

        CreativeImpulse storage impulse = impulses[newImpulseId];
        impulse.submitter = msg.sender;
        impulse.promptURI = _promptURI;
        impulse.totalStake = minimumImpulseStake;
        impulse.state = ImpulseState.PendingApproval;
        impulse.submissionTime = block.timestamp;
        impulse.stakers[msg.sender] = minimumImpulseStake;
        impulse.approvalVotingEndTime = block.timestamp + impulseApprovalVotingDuration;

        emit ImpulseSubmitted(newImpulseId, msg.sender, _promptURI, minimumImpulseStake);
        return newImpulseId;
    }

    // 10. increaseImpulseStake
    function increaseImpulseStake(uint256 _impulseId, uint256 _amount) public whenNotPaused validImpulse(_impulseId) returns (uint256) {
        if (_amount == 0) return impulses[_impulseId].stakers[msg.sender];
        if (impulseToken.allowance(msg.sender, address(this)) < _amount) {
            revert Unauthorized(); // User needs to approve tokens first
        }
        // Cannot increase stake if impulse is already rejected, generated, or explicitly withdrawn
        if (impulses[_impulseId].state == ImpulseState.Rejected || 
            impulses[_impulseId].state == ImpulseState.ArtGenerated || 
            impulses[_impulseId].state == ImpulseState.Withdrawn) {
            revert InvalidImpulseState();
        }

        impulseToken.transferFrom(msg.sender, address(this), _amount);

        impulses[_impulseId].totalStake += _amount;
        impulses[_impulseId].stakers[msg.sender] += _amount;

        emit ImpulseStakeIncreased(_impulseId, msg.sender, _amount);
        return impulses[_impulseId].stakers[msg.sender];
    }

    // 11. withdrawImpulseStake
    function withdrawImpulseStake(uint256 _impulseId) public whenNotPaused validImpulse(_impulseId) {
        CreativeImpulse storage impulse = impulses[_impulseId];
        uint256 userStake = impulse.stakers[msg.sender];

        if (userStake == 0) {
            revert InsufficientStake(1, 0); // User has no stake to withdraw
        }

        bool canWithdraw = false;
        if (impulse.state == ImpulseState.Rejected && block.timestamp >= impulse.submissionTime + impulseWithdrawCoolDown) {
            canWithdraw = true; // Impulse rejected and cool-down passed
        } else if (impulse.state == ImpulseState.PendingApproval && block.timestamp >= impulse.approvalVotingEndTime) {
            // If voting ended, and it wasn't approved (implicit if not explicitly approved state)
            if (impulse.approvalVoteYes <= impulse.approvalVoteNo) {
                canWithdraw = true;
            }
        } else if (impulse.state == ImpulseState.Withdrawn) {
            canWithdraw = true; // Impulse manually withdrawn by submitter (if not approved)
        }
        
        if (!canWithdraw) {
            revert StakingLocked(); // Cannot withdraw at this time
        }

        impulse.totalStake -= userStake;
        impulse.stakers[msg.sender] = 0; // Clear user's stake

        impulseToken.transfer(msg.sender, userStake);
        emit ImpulseStakeWithdrawn(_impulseId, msg.sender, userStake);
    }

    // --- III. AI Art Generation & Minting (3 functions) ---

    // 12. requestArtGeneration
    function requestArtGeneration(uint256 _impulseId) public onlyAIOracle whenNotPaused validImpulse(_impulseId) notGenerated(_impulseId) {
        CreativeImpulse storage impulse = impulses[_impulseId];
        if (impulse.state != ImpulseState.Approved) {
            revert ImpulseNotApprovedForGeneration();
        }

        // Event for off-chain AI to pick up and generate art based on promptURI
        emit ArtGenerationRequested(_impulseId, aiOracleAddress);
    }

    // 13. fulfillArtGeneration
    function fulfillArtGeneration(uint256 _impulseId, string memory _tokenURI) public onlyAIOracle whenNotPaused validImpulse(_impulseId) notGenerated(_impulseId) {
        CreativeImpulse storage impulse = impulses[_impulseId];
        if (impulse.state != ImpulseState.Approved) {
            revert ImpulseNotApprovedForGeneration();
        }

        _artPieceIdCounter.increment();
        uint256 newArtPieceId = _artPieceIdCounter.current();

        _safeMint(impulse.submitter, newArtPieceId); // Mint NFT to the impulse submitter
        _setTokenURI(newArtPieceId, _tokenURI);

        impulse.artPieceId = newArtPieceId;
        impulse.state = ImpulseState.ArtGenerated;

        emit ArtPieceMinted(newArtPieceId, _impulseId, impulse.submitter, _tokenURI);
    }

    // 14. updateArtMetadata
    function updateArtMetadata(uint256 _artPieceId, string memory _newTokenURI) public whenNotPaused validArtPiece(_artPieceId) onlyArtPieceOwner(_artPieceId) {
        _setTokenURI(_artPieceId, _newTokenURI);
        emit ArtMetadataUpdated(_artPieceId, _newTokenURI);
    }

    // --- IV. Community Curation & Voting (3 functions) ---

    // 15. voteOnImpulseApproval
    function voteOnImpulseApproval(uint256 _impulseId, bool _approve) public whenNotPaused validImpulse(_impulseId) {
        CreativeImpulse storage impulse = impulses[_impulseId];
        if (impulse.state != ImpulseState.PendingApproval) {
            revert InvalidImpulseState();
        }
        if (block.timestamp >= impulse.approvalVotingEndTime) {
            // If voting ended, automatically conclude and then revert if already concluded
            _concludeImpulseApprovalVoting(_impulseId);
            revert VotingPeriodNotActive(); // Voting already concluded
        }
        if (impulse.hasVotedForApproval[msg.sender]) {
            revert AlreadyVotedOnImpulse();
        }

        address voter = votingDelegates[msg.sender] != address(0) ? votingDelegates[msg.sender] : msg.sender;
        uint256 votingPower = impulseToken.balanceOf(voter); // Use current IMP balance for voting power

        if (_approve) {
            impulse.approvalVoteYes += votingPower;
        } else {
            impulse.approvalVoteNo += votingPower;
        }
        impulse.hasVotedForApproval[msg.sender] = true;

        emit ImpulseApprovalVoted(_impulseId, msg.sender, _approve, votingPower);
    }

    // Internal function to conclude impulse voting (can be called by anyone after voting ends)
    function _concludeImpulseApprovalVoting(uint256 _impulseId) internal {
        CreativeImpulse storage impulse = impulses[_impulseId];
        if (impulse.state != ImpulseState.PendingApproval) {
            return; // Already concluded or invalid state
        }
        if (block.timestamp < impulse.approvalVotingEndTime) {
            revert VotingPeriodNotEnded();
        }

        if (impulse.approvalVoteYes > impulse.approvalVoteNo) {
            impulse.state = ImpulseState.Approved;
            emit ImpulseApproved(_impulseId);
        } else {
            impulse.state = ImpulseState.Rejected;
            emit ImpulseRejected(_impulseId);
        }
    }

    // 16. proposeArtLicenseTerms
    function proposeArtLicenseTerms(uint256 _artPieceId, uint256 _price, uint256 _duration, string memory _termsURI) public whenNotPaused validArtPiece(_artPieceId) {
        // Only art piece owner or stakers of the impulse can propose
        bool isOwner = ownerOf(_artPieceId) == msg.sender;
        uint256 impulseId = _getImpulseIdForArtPiece(_artPieceId);
        bool isStaker = impulseId != 0 && impulses[impulseId].stakers[msg.sender] > 0;
        if (!isOwner && !isStaker) {
            revert Unauthorized();
        }

        // Ensure there's no active proposal, or the active one has expired/rejected
        if (currentLicenseProposal[_artPieceId].proposalTime != 0 && 
            currentLicenseProposal[_artPieceId].state == LicenseState.Proposed &&
            block.timestamp < currentLicenseProposal[_artPieceId].licenseVotingEndTime) {
            revert InvalidProposalState(); // An active, unexpired proposal already exists
        }

        ArtPieceLicense storage proposal = currentLicenseProposal[_artPieceId];
        proposal.licensee = address(0); // No specific licensee for a general proposal
        proposal.price = _price;
        proposal.duration = _duration;
        proposal.termsURI = _termsURI;
        proposal.state = LicenseState.Proposed;
        proposal.proposalTime = block.timestamp;
        proposal.activationTime = 0;
        proposal.expirationTime = 0;
        proposal.totalPaid = 0;
        
        // Reset votes for new proposal
        proposal.licenseVoteYes = 0;
        proposal.licenseVoteNo = 0;
        proposal.licenseVotingEndTime = block.timestamp + licenseProposalVotingDuration;
        // Clear previous voters to allow re-voting on new proposals
        delete proposal.hasVotedForLicense;

        emit LicenseProposed(_artPieceId, msg.sender, _price, _duration, _termsURI);
    }

    // 17. voteOnLicenseProposal
    function voteOnLicenseProposal(uint256 _artPieceId, bool _approve) public whenNotPaused validArtPiece(_artPieceId) {
        ArtPieceLicense storage proposal = currentLicenseProposal[_artPieceId];
        if (proposal.state != LicenseState.Proposed) {
            revert NoPendingLicenseProposal();
        }
        if (block.timestamp >= proposal.licenseVotingEndTime) {
            // Conclude if voting ended, then revert if already concluded
            _concludeLicenseProposalVoting(_artPieceId);
            revert VotingPeriodNotActive(); // Voting already concluded
        }
        if (proposal.hasVotedForLicense[msg.sender]) {
            revert AlreadyVotedOnLicense();
        }

        address voter = votingDelegates[msg.sender] != address(0) ? votingDelegates[msg.sender] : msg.sender;
        uint256 votingPower = impulseToken.balanceOf(voter);

        if (_approve) {
            proposal.licenseVoteYes += votingPower;
        } else {
            proposal.licenseVoteNo += votingPower;
        }
        proposal.hasVotedForLicense[msg.sender] = true;

        emit LicenseProposalVoted(_artPieceId, msg.sender, _approve, votingPower);
    }

    // Internal function to conclude license proposal voting (can be called by anyone after voting ends)
    function _concludeLicenseProposalVoting(uint256 _artPieceId) internal {
        ArtPieceLicense storage proposal = currentLicenseProposal[_artPieceId];
        if (proposal.state != LicenseState.Proposed) {
            return; // Already concluded or invalid state
        }
        if (block.timestamp < proposal.licenseVotingEndTime) {
            revert VotingPeriodNotEnded();
        }

        if (proposal.licenseVoteYes > proposal.licenseVoteNo) {
            proposal.state = LicenseState.Approved;
            emit LicenseApproved(_artPieceId);
        } else {
            proposal.state = LicenseState.Rejected;
            emit LicenseRejected(_artPieceId);
            // Clear the proposal after rejection
            delete currentLicenseProposal[_artPieceId];
        }
    }

    // --- V. Dynamic Licensing & Revenue Distribution (5 functions) ---

    // 18. acquireArtLicense
    function acquireArtLicense(uint256 _artPieceId) public payable whenNotPaused validArtPiece(_artPieceId) {
        ArtPieceLicense storage proposal = currentLicenseProposal[_artPieceId];
        if (proposal.state != LicenseState.Approved) {
            revert LicenseTermsNotApproved();
        }
        if (msg.value < proposal.price) {
            revert InsufficientStake(proposal.price, msg.value); // Reusing error for insufficient ETH
        }

        // Check if there's an existing active license for this user (only one active license per user per art piece)
        if (activeLicenses[_artPieceId][msg.sender].state == LicenseState.Active) {
            revert NoActiveLicense(_artPieceId, msg.sender);
        }

        uint256 price = proposal.price;
        uint256 platformFee = (price * platformFeePercentage) / 10000;
        uint256 oracleFee = (price * oracleFeePercentage) / 10000;
        
        // Distribute fees directly
        if (platformFee > 0) payable(globalFeeRecipient).transfer(platformFee);
        if (oracleFee > 0) payable(aiOracleAddress).transfer(oracleFee);
        
        // Accumulate total revenue for later claim by stakers/owner
        _artPieceTotalRevenue[_artPieceId] += price;

        // Transfer excess ETH back if any
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        // Copy approved proposal to active licenses for the specific licensee
        activeLicenses[_artPieceId][msg.sender] = proposal;
        activeLicenses[_artPieceId][msg.sender].licensee = msg.sender;
        activeLicenses[_artPieceId][msg.sender].state = LicenseState.Active;
        activeLicenses[_artPieceId][msg.sender].activationTime = block.timestamp;
        activeLicenses[_artPieceId][msg.sender].expirationTime = proposal.duration == 0 ? 0 : block.timestamp + proposal.duration;
        activeLicenses[_artPieceId][msg.sender].totalPaid += price;

        // Clear the current proposal after a license is acquired from it
        delete currentLicenseProposal[_artPieceId];

        emit ArtLicenseAcquired(_artPieceId, msg.sender, price, proposal.duration);
    }

    // 19. releaseArtLicense
    function releaseArtLicense(uint256 _artPieceId) public whenNotPaused validArtPiece(_artPieceId) {
        ArtPieceLicense storage license = activeLicenses[_artPieceId][msg.sender];
        if (license.state != LicenseState.Active) {
            revert NoActiveLicense(_artPieceId, msg.sender);
        }

        license.state = LicenseState.Terminated; // Mark as terminated
        emit ArtLicenseReleased(_artPieceId, msg.sender);
    }

    // 20. registerLicenseEvent (e.g., commercial use, milestone detected by oracle)
    function registerLicenseEvent(uint256 _artPieceId, address _licensee, string memory _eventType) public onlyAIOracle whenNotPaused validArtPiece(_artPieceId) {
        // This function is for the oracle to register external events related to a license
        // Could trigger further actions or revenue calculations depending on the eventType
        if (activeLicenses[_artPieceId][_licensee].state != LicenseState.Active) {
            revert NoActiveLicense(_artPieceId, _licensee);
        }
        emit LicenseEventRegistered(_artPieceId, _licensee, _eventType);
    }

    // 21. claimImpulseRewards
    function claimImpulseRewards(uint256 _impulseId) public whenNotPaused validImpulse(_impulseId) {
        CreativeImpulse storage impulse = impulses[_impulseId];
        uint256 artPieceId = impulse.artPieceId;
        if (artPieceId == 0) {
            revert NotYetGenerated(); // No art, no potential revenue
        }

        uint256 userStake = impulse.stakers[msg.sender];
        if (userStake == 0) {
            revert Unauthorized(); // Not an impulse staker
        }

        uint256 totalArtRevenue = _artPieceTotalRevenue[artPieceId];
        uint256 totalImpulseStakerShare = (totalArtRevenue * impulseStakerSharePercentage) / 10000;
        uint256 unclaimedImpulseShare = totalImpulseStakerShare > impulse.claimedRevenue ? totalImpulseStakerShare - impulse.claimedRevenue : 0;

        if (unclaimedImpulseShare == 0) {
            revert CannotClaimZeroRevenue();
        }

        uint256 userClaimableShare = (unclaimedImpulseShare * userStake) / impulse.totalStake;
        if (userClaimableShare == 0) {
            revert CannotClaimZeroRevenue();
        }

        impulse.claimedRevenue += userClaimableShare;
        payable(msg.sender).transfer(userClaimableShare);
        emit ImpulseRewardsClaimed(_impulseId, msg.sender, userClaimableShare);
    }

    // 22. claimArtPieceCreatorRevenue
    function claimArtPieceCreatorRevenue(uint256 _artPieceId) public whenNotPaused validArtPiece(_artPieceId) onlyArtPieceOwner(_artPieceId) {
        uint256 totalArtRevenue = _artPieceTotalRevenue[_artPieceId];
        uint256 totalOwnerShare = (totalArtRevenue * ownerSharePercentage) / 10000;
        uint256 unclaimedOwnerShare = totalOwnerShare > artPieceClaimedOwnerRevenue[_artPieceId] ? totalOwnerShare - artPieceClaimedOwnerRevenue[_artPieceId] : 0;

        if (unclaimedOwnerShare == 0) {
            revert CannotClaimZeroRevenue();
        }

        artPieceClaimedOwnerRevenue[_artPieceId] += unclaimedOwnerShare;
        payable(msg.sender).transfer(unclaimedOwnerShare);
        emit CreatorRevenueClaimed(_artPieceId, msg.sender, unclaimedOwnerShare);
    }

    // --- VI. Advanced Features & Utilities (4 functions) ---

    // 23. delegateVotingPower
    function delegateVotingPower(address _delegatee) public whenNotPaused {
        if (_delegatee == msg.sender) {
            _delegatee = address(0); // Undelegate if delegating to self
        }
        votingDelegates[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    // Internal helper to get impulse ID from art piece ID
    function _getImpulseIdForArtPiece(uint256 _artPieceId) internal view returns (uint256) {
        // This is inefficient for many impulses. In a real scenario, a mapping `artPieceId => impulseId` would be used.
        // For this example, and assuming a reasonable number of impulses, it's acceptable.
        for (uint256 i = 1; i <= _impulseIdCounter.current(); i++) {
            if (impulses[i].artPieceId == _artPieceId) {
                return i;
            }
        }
        return 0; // Not found
    }

    // 24. getImpulseDetails
    function getImpulseDetails(uint256 _impulseId) public view validImpulse(_impulseId) returns (
        address submitter,
        string memory promptURI,
        uint256 totalStake,
        ImpulseState state,
        uint256 submissionTime,
        uint256 artPieceId,
        uint256 approvalVoteYes,
        uint256 approvalVoteNo,
        uint256 approvalVotingEndTime,
        uint256 claimedRevenue,
        uint256 stakerStake // For the caller
    ) {
        CreativeImpulse storage impulse = impulses[_impulseId];
        return (
            impulse.submitter,
            impulse.promptURI,
            impulse.totalStake,
            impulse.state,
            impulse.submissionTime,
            impulse.artPieceId,
            impulse.approvalVoteYes,
            impulse.approvalVoteNo,
            impulse.approvalVotingEndTime,
            impulse.claimedRevenue,
            impulse.stakers[msg.sender]
        );
    }

    // 25. getArtPieceDetails
    function getArtPieceDetails(uint256 _artPieceId) public view validArtPiece(_artPieceId) returns (
        uint256 impulseId,
        address owner,
        string memory tokenURI,
        uint256 totalRevenue,
        uint256 claimedOwnerRevenue
    ) {
        impulseId = _getImpulseIdForArtPiece(_artPieceId);
        owner = ownerOf(_artPieceId);
        tokenURI = tokenURI(_artPieceId);
        totalRevenue = _artPieceTotalRevenue[_artPieceId];
        claimedOwnerRevenue = artPieceClaimedOwnerRevenue[_artPieceId];
    }

    // 26. getLicenseDetails (for active or past licenses for a specific licensee)
    function getLicenseDetails(uint256 _artPieceId, address _licensee) public view validArtPiece(_artPieceId) returns (
        address licensee,
        uint256 price,
        uint256 duration,
        string memory termsURI,
        LicenseState state,
        uint256 proposalTime,
        uint256 activationTime,
        uint256 expirationTime,
        uint256 totalPaid
    ) {
        ArtPieceLicense storage license = activeLicenses[_artPieceId][_licensee];
        return (
            license.licensee,
            license.price,
            license.duration,
            license.termsURI,
            license.state,
            license.proposalTime,
            license.activationTime,
            license.expirationTime,
            license.totalPaid
        );
    }

    // Public view for current license proposal details
    function getCurrentLicenseProposalDetails(uint256 _artPieceId) public view validArtPiece(_artPieceId) returns (
        uint256 price,
        uint256 duration,
        string memory termsURI,
        LicenseState state,
        uint256 proposalTime,
        uint256 licenseVoteYes,
        uint256 licenseVoteNo,
        uint256 licenseVotingEndTime
    ) {
        ArtPieceLicense storage proposal = currentLicenseProposal[_artPieceId];
        return (
            proposal.price,
            proposal.duration,
            proposal.termsURI,
            proposal.state,
            proposal.proposalTime,
            proposal.licenseVoteYes,
            proposal.licenseVoteNo,
            proposal.licenseVotingEndTime
        );
    }
}
```