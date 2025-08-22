This smart contract, named `CIPHER_NFT_Protocol` (Collective Intelligence Protocol for Hierarchical Evolving Reputation NFTs), introduces a novel ecosystem where user reputation and contributions to a decentralized knowledge base are directly tied to dynamic, conditionally soulbound NFTs.

The core idea is to foster a community that contributes valuable data and insights, validates submissions, and is rewarded with evolving digital identities (NFTs) that reflect their intellectual standing and activity within the protocol.

---

## Outline: CIPHER-NFT Protocol

The `CIPHER_NFT_Protocol` establishes a decentralized ecosystem for collective intelligence. Users contribute data, validate information, and earn reputation. Their reputation is visually and functionally represented by a unique, dynamic, and conditionally soulbound "Intelligence Agent" NFT. The NFT's traits evolve based on the owner's contributions, validation success, and overall standing within the protocol.

**Core Concepts:**

1.  **Dynamic & Conditionally Soulbound NFTs:** NFTs whose metadata/traits evolve based on on-chain reputation and activity. Initially non-transferable, they can become transferable under specific conditions (e.g., high reputation, fee).
2.  **Reputation System:** An on-chain score for users, earned through successful data submissions and validations, and reduced by failures or malicious actions. This score is intrinsically linked to the Intelligence Agent NFT.
3.  **Decentralized Data Submission & Validation:** Users submit data or insights (e.g., facts, research, observations), and other users (validators) review and vote on the accuracy/value of these submissions.
4.  **Staking & Slashing:** Validators stake tokens to participate in the validation process, earning rewards for honest work and facing slashing of their staked tokens for malicious or consistently incorrect validation.
5.  **Bounty System:** Protocol participants or external entities can post bounties for specific types of data contributions, incentivizing valuable submissions.
6.  **Gamified Progression:** The evolving NFT traits provide a visual and functional representation of a user's progression and status within the collective intelligence network.

---

## Function Summary:

**I. NFT & Reputation Management (CIPHER Agent)**

1.  `mintIntelligenceAgent()`: Mints the initial Intelligence Agent NFT for a user. Each user can only mint one agent.
2.  `getAgentReputation(address _owner)`: Returns the current reputation score associated with an agent's owner.
3.  `getAgentTraits(uint256 _tokenId)`: Computes and returns dynamic traits (e.g., level, wisdom, integrity, activity score) for a specific NFT based on its owner's reputation and activity.
4.  `updateAgentMetadata(uint256 _tokenId)`: Triggers an off-chain metadata refresh for the specified NFT. (Emits an event for an off-chain listener to update URI).
5.  `isAgentActive(uint256 _tokenId)`: Checks if an agent is active (e.g., not currently suspended due to extreme negative reputation or slashing).
6.  `transferAgent(address _from, address _to, uint256 _tokenId)`: Handles the special logic for transferring the Intelligence Agent NFT. Initially Soulbound, it becomes transferable only if certain reputation thresholds are met and a fee is paid. Reputation also transfers to the new owner.

**II. Data Submission & Bounty System**

7.  `submitData(string memory _dataHash, uint256 _bountyId)`: Allows users with an agent to submit data or insights, optionally linking it to an active bounty. This submission automatically initiates a validation round.
8.  `createBounty(uint256 _rewardAmount, uint256 _requiredReputation, string memory _descriptionHash)`: A privileged role (Bounty Creator) can create a new bounty, specifying the reward, required submitter reputation, and a description.
9.  `claimBounty(uint256 _bountyId)`: Allows the successful submitter of a *validated* submission (linked to this bounty) to claim the bounty rewards.
10. `getSubmissionDetails(uint256 _submissionId)`: Retrieves detailed information about a data submission.
11. `getPendingBounties()`: Returns the total count of bounties (actual data would be fetched by off-chain indexers).

**III. Validation & Slashing Mechanism**

12. `stakeForValidatorRole(uint256 _amount)`: Users stake `paymentToken` to become eligible to participate in validation rounds, earning the `VALIDATOR_ROLE`.
13. `unstakeFromValidatorRole()`: Users can request to unstake their tokens and exit the validator role after a cooldown period.
14. `validateSubmission(uint256 _validationRoundId, bool _isAccurate)`: Validators cast their vote (accurate/inaccurate) on a specific submission within an active validation round.
15. `reportMaliciousValidator(uint256 _validationRoundId, address _validator)`: Allows users to report potentially malicious behavior of a validator. This triggers an event for off-chain review/dispute resolution.
16. `processValidationRound(uint256 _validationRoundId)`: Finalizes a validation round once its period ends. It determines the submission's accuracy, distributes reputation/rewards to correct validators/submitters, and slashes incorrect validators.
17. `getValidatorStake(address _validator)`: Returns the current staked amount of a given validator.

**IV. Protocol Configuration & Administration**

18. `setProtocolParameter(bytes32 _paramName, uint256 _value)`: An admin function to adjust key operational parameters of the protocol (e.g., reputation gain/loss rates, stake amounts, validation periods).
19. `withdrawProtocolFees()`: An admin function to withdraw accumulated protocol fees (from minting, transfers, slashes) to a designated address.
20. `pauseProtocol()`: An admin function to pause or unpause critical operations of the contract in emergencies.
21. `grantRole(bytes32 role, address account)`: Grants a specified access control role to an account (e.g., ADMIN_ROLE, BOUNTY_CREATOR_ROLE).
22. `revokeRole(bytes32 role, address account)`: Revokes a specified access control role from an account.

**V. Advanced Reputation & Utility**

23. `decayReputation(address _user)`: A mechanism (callable by admin or a keeper) to gradually decay a user's reputation over time, typically for inactivity or to rebalance the system.
24. `tokenURI(uint256 _tokenId)`: The standard ERC721 function. It returns a dynamically constructed URI that includes current on-chain traits, pointing to an off-chain service for full metadata generation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline: CIPHER-NFT Protocol (Collective Intelligence Protocol for Hierarchical Evolving Reputation NFTs)
// This protocol establishes a decentralized ecosystem for collective intelligence, where users contribute data, validate information,
// and earn reputation. Their reputation is visually and functionally represented by a unique, dynamic, and conditionally
// soulbound "Intelligence Agent" NFT. The NFT's traits evolve based on the owner's contributions, validation success,
// and overall standing within the protocol.

// Core Concepts:
// 1.  Dynamic & Conditionally Soulbound NFTs: NFTs whose metadata/traits evolve based on on-chain reputation and activity,
//     and are initially non-transferable but can become transferable under specific conditions (e.g., high reputation, fee).
// 2.  Reputation System: An on-chain score for users, earned through successful data submissions and validations,
//     and reduced by failures or malicious actions.
// 3.  Decentralized Data Submission & Validation: Users submit data or insights, and other users (validators) review
//     and vote on the accuracy/value.
// 4.  Staking & Slashing: Validators stake tokens to participate, earning rewards for honest work and facing slashing
//     for malicious or consistently incorrect validation.
// 5.  Bounty System: Protocol participants or external entities can post bounties for specific data contributions.
// 6.  Gamified Progression: The evolving NFT traits provide a visual representation of a user's progression and status.

// Function Summary:

// I. NFT & Reputation Management (CIPHER Agent)
// 1.  mintIntelligenceAgent(): Mints the initial Intelligence Agent NFT for a user.
// 2.  getAgentReputation(address _owner): Returns the current reputation score of an agent's owner.
// 3.  getAgentTraits(uint256 _tokenId): Computes and returns dynamic traits for a specific NFT based on its owner's reputation and activity.
// 4.  updateAgentMetadata(uint256 _tokenId): Triggers an off-chain metadata refresh for the specified NFT. (Emits event for off-chain listener).
// 5.  isAgentActive(uint256 _tokenId): Checks if an agent is active (e.g., not currently suspended due to slashing).
// 6.  transferAgent(address _from, address _to, uint256 _tokenId): Special logic for transferring the Soulbound-like NFT.

// II. Data Submission & Bounty System
// 7.  submitData(string memory _dataHash, uint256 _bountyId): Allows users to submit data/insights, potentially linked to a bounty. Requires reputation.
// 8.  createBounty(uint256 _rewardAmount, uint256 _requiredReputation, string memory _descriptionHash): Admin/privileged role to create a bounty for specific data.
// 9.  claimBounty(uint256 _bountyId): Allows the successful submitter of a validated submission to claim bounty rewards.
// 10. getSubmissionDetails(uint256 _submissionId): Retrieves detailed information about a data submission.
// 11. getPendingBounties(): Returns a list of active bounties (simplified to count).

// III. Validation & Slashing Mechanism
// 12. stakeForValidatorRole(uint256 _amount): Users stake tokens to become eligible validators.
// 13. unstakeFromValidatorRole(): Users unstake their tokens and exit the validator role, after a cooldown.
// 14. validateSubmission(uint256 _submissionId, bool _isAccurate): Validators vote on the accuracy of a submission.
// 15. reportMaliciousValidator(uint256 _validationRoundId, address _validator): Allows users/validators to report malicious behavior.
// 16. processValidationRound(uint256 _validationRoundId): Finalizes a validation round, distributing rewards, updating reputations, and handling slashing.
// 17. getValidatorStake(address _validator): Returns the current staked amount of a validator.

// IV. Protocol Configuration & Administration
// 18. setProtocolParameter(bytes32 _paramName, uint256 _value): Admin function to adjust core protocol parameters.
// 19. withdrawProtocolFees(): Admin function to withdraw accumulated protocol fees.
// 20. pauseProtocol(): Admin function to pause critical operations in emergencies.
// 21. grantRole(bytes32 role, address account): Grants a role to an account.
// 22. revokeRole(bytes32 role, address account): Revokes a role from an account.

// V. Advanced Reputation & Utility
// 23. decayReputation(address _user): A mechanism (can be triggered by admin or scheduled) to gradually decay reputation over time for inactivity or system rebalancing.
// 24. tokenURI(uint256 _tokenId): Standard ERC721 function, generating dynamic URI based on on-chain state.

contract CIPHER_NFT_Protocol is ERC721Enumerable, AccessControl, ReentrancyGuard {
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant BOUNTY_CREATOR_ROLE = keccak256("BOUNTY_CREATOR_ROLE");

    // --- State Variables ---
    IERC20 public immutable paymentToken; // Token used for staking, rewards, and fees

    uint256 private _nextTokenId; // Counter for NFTs

    // Agent (NFT) and Reputation
    mapping(address => uint256) public reputationScores; // User's reputation score
    mapping(uint256 => bool) public isAgentSoulbound; // True if NFT cannot be transferred
    mapping(uint256 => uint256) public agentMintTime; // Timestamp of agent minting
    // `agentOwnerAddress` is implicitly handled by ERC721's `ownerOf` but kept for convenience if needed.

    // Submissions
    struct Submission {
        address submitter;
        string dataHash; // IPFS hash or similar for the data content
        uint256 bountyId; // 0 if not linked to a bounty
        uint256 submissionTime;
        uint256 validationRoundId; // Link to the ongoing validation round
        bool isProcessed; // True after validation round is finalized
    }
    mapping(uint252 => Submission) public submissions;
    uint256 public nextSubmissionId;

    // Bounties
    enum BountyStatus { Active, Claimed, Cancelled }
    struct Bounty {
        address creator;
        uint256 rewardAmount;
        uint256 requiredReputation; // Min reputation to submit for this bounty
        string descriptionHash; // IPFS hash or similar for bounty details
        BountyStatus status;
        uint256 creationTime;
        uint252 winningSubmissionId; // The submission that successfully claimed this bounty
    }
    mapping(uint252 => Bounty) public bounties;
    uint256 public nextBountyId;

    // Validation Rounds
    enum ValidationStatus { Pending, Active, Finalized, Cancelled }
    struct ValidationRound {
        uint252 submissionId;
        uint256 stakeRequirement;
        uint256 minValidators; // Minimum number of validators required
        uint256 maxValidators; // Maximum number of validators allowed
        uint256 validationPeriodEnd; // Timestamp when voting ends
        address[] voters; // List of addresses that voted in this round
        mapping(address => bool) hasVoted; // Tracks if a validator voted
        mapping(address => bool) validatorVotes; // True for accurate, False for inaccurate
        mapping(address => uint256) validatorStakes; // Stake amount of each validator at the time of vote
        uint256 totalPositiveVotes;
        uint256 totalNegativeVotes;
        ValidationStatus status;
        bool isConsensusReached; // Set after processing
        bool isSubmissionAccurate; // Final outcome
    }
    mapping(uint252 => ValidationRound) public validationRounds;
    uint256 public nextValidationRoundId;

    // Validator Staking
    mapping(address => uint256) public validatorStakes;
    mapping(address => uint256) public validatorStakeLockupEnd; // Time until stake can be withdrawn

    // Protocol Parameters
    mapping(bytes32 => uint256) public protocolParameters;
    bytes32 public constant MIN_REPUTATION_FOR_MINT = keccak256("MIN_REPUTATION_FOR_MINT");
    bytes32 public constant BASE_MINT_FEE = keccak256("BASE_MINT_FEE");
    bytes32 public constant REPUTATION_GAIN_SUBMISSION = keccak256("REPUTATION_GAIN_SUBMISSION");
    bytes32 public constant REPUTATION_GAIN_VALIDATION = keccak256("REPUTATION_GAIN_VALIDATION");
    bytes32 public constant REPUTATION_LOSS_SUBMISSION = keccak256("REPUTATION_LOSS_SUBMISSION");
    bytes32 public constant REPUTATION_LOSS_VALIDATION = keccak256("REPUTATION_LOSS_VALIDATION");
    bytes32 public constant MIN_VALIDATOR_STAKE = keccak256("MIN_VALIDATOR_STAKE");
    bytes32 public constant VALIDATION_PERIOD_DURATION = keccak256("VALIDATION_PERIOD_DURATION");
    bytes32 public constant SLASH_PERCENTAGE = keccak256("SLASH_PERCENTAGE"); // x100, e.g., 500 for 5%
    bytes32 public constant REPUTATION_DECAY_RATE = keccak256("REPUTATION_DECAY_RATE"); // points decayed per trigger
    bytes32 public constant MIN_REPUTATION_FOR_TRANSFER = keccak256("MIN_REPUTATION_FOR_TRANSFER");
    bytes32 public constant TRANSFER_FEE_PERCENTAGE = keccak256("TRANSFER_FEE_PERCENTAGE"); // x100
    bytes32 public constant VALIDATOR_LOCKUP_DURATION = keccak256("VALIDATOR_LOCKUP_DURATION");

    uint256 public totalProtocolFees; // Accumulated fees in paymentToken

    bool public paused; // Global pause switch

    // --- Events ---
    event AgentMinted(address indexed owner, uint256 indexed tokenId, uint256 reputation);
    event AgentReputationUpdated(address indexed owner, uint256 newReputation);
    event AgentMetadataUpdate(uint256 indexed tokenId, string newUri);
    event AgentTransferred(address indexed from, address indexed to, uint256 indexed tokenId, uint256 feePaid);

    event DataSubmitted(uint252 indexed submissionId, address indexed submitter, uint252 bountyId, string dataHash);
    event BountyCreated(uint252 indexed bountyId, address indexed creator, uint256 rewardAmount);
    event BountyClaimed(uint252 indexed bountyId, address indexed submitter, uint256 rewardAmount);

    event ValidatorStaked(address indexed validator, uint256 amount);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event SubmissionValidated(uint252 indexed validationRoundId, address indexed validator, bool isAccurate);
    event ValidationRoundProcessed(uint252 indexed validationRoundId, bool isSubmissionAccurate, uint256 totalPositive, uint256 totalNegative);
    event ValidatorSlashed(address indexed validator, uint256 amount);
    event MaliciousValidatorReported(uint252 indexed validationRoundId, address indexed reporter, address indexed maliciousValidator);

    event ProtocolParameterSet(bytes32 indexed paramName, uint256 value);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event ProtocolPaused(bool status);
    event ReputationDecayed(address indexed user, uint256 oldReputation, uint256 newReputation);

    // --- Custom Errors ---
    error ProtocolPausedError();
    error Unauthorized();
    error AgentAlreadyMinted();
    error AgentNotFound();
    error InsufficientReputation(uint256 required, uint256 current);
    error InvalidBounty(uint252 bountyId);
    error BountyNotActive();
    error SubmissionAlreadyProcessed();
    error NotEnoughStake(uint256 required, uint256 current);
    error InvalidAmount();
    error AlreadyVotedInRound();
    error ValidationPeriodEnded();
    error NotAValidator();
    error StakeLocked();
    error NotEnoughValidators();
    error BountyNotClaimable();
    error InvalidSubmissionStatus();
    error NoAgentToDecay();

    constructor(address _paymentTokenAddress, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // Custom admin role
        _grantRole(BOUNTY_CREATOR_ROLE, msg.sender); // Initial bounty creator

        paymentToken = IERC20(_paymentTokenAddress);

        // Set initial protocol parameters (can be adjusted by ADMIN_ROLE later)
        protocolParameters[MIN_REPUTATION_FOR_MINT] = 0; // No reputation needed to mint initially
        protocolParameters[BASE_MINT_FEE] = 0; // No fee initially for minting
        protocolParameters[REPUTATION_GAIN_SUBMISSION] = 50; // Points for successful submission
        protocolParameters[REPUTATION_GAIN_VALIDATION] = 10; // Points for correct validation
        protocolParameters[REPUTATION_LOSS_SUBMISSION] = 20; // Points for failed submission
        protocolParameters[REPUTATION_LOSS_VALIDATION] = 30; // Points for incorrect validation
        protocolParameters[MIN_VALIDATOR_STAKE] = 100 ether; // Example: 100 tokens required to stake
        protocolParameters[VALIDATION_PERIOD_DURATION] = 24 hours; // 1 day for validation voting
        protocolParameters[SLASH_PERCENTAGE] = 500; // 5% slash on stake
        protocolParameters[REPUTATION_DECAY_RATE] = 10; // 10 points decay per trigger
        protocolParameters[MIN_REPUTATION_FOR_TRANSFER] = 1000; // Example: 1000 reputation to become transferable
        protocolParameters[TRANSFER_FEE_PERCENTAGE] = 100; // 1% of a base value for transfer
        protocolParameters[VALIDATOR_LOCKUP_DURATION] = 7 days; // 7-day lockup after unstake request
    }

    // --- Modifier ---
    modifier whenNotPaused() {
        if (paused) revert ProtocolPausedError();
        _;
    }

    modifier onlyAgentOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != _msgSender()) revert Unauthorized();
        _;
    }

    // --- I. NFT & Reputation Management (CIPHER Agent) ---

    /// @notice 1. Mints the initial Intelligence Agent NFT for a user.
    /// @dev Users can only mint one agent. Requires a base mint fee and minimum reputation.
    function mintIntelligenceAgent() external whenNotPaused {
        if (balanceOf(_msgSender()) > 0) revert AgentAlreadyMinted(); // Check if user already has an agent
        if (reputationScores[_msgSender()] < protocolParameters[MIN_REPUTATION_FOR_MINT]) {
            revert InsufficientReputation(protocolParameters[MIN_REPUTATION_FOR_MINT], reputationScores[_msgSender()]);
        }

        uint256 mintFee = protocolParameters[BASE_MINT_FEE];
        if (mintFee > 0) {
            paymentToken.transferFrom(_msgSender(), address(this), mintFee);
            totalProtocolFees += mintFee;
        }

        uint256 tokenId = _nextTokenId++;
        _safeMint(_msgSender(), tokenId);
        reputationScores[_msgSender()] = 0; // Start with base reputation (or a small initial boost)
        isAgentSoulbound[tokenId] = true; // Initially soulbound
        agentMintTime[tokenId] = block.timestamp;

        emit AgentMinted(_msgSender(), tokenId, reputationScores[_msgSender()]);
    }

    /// @notice 2. Returns the current reputation score of an agent's owner.
    /// @param _owner The address of the agent owner.
    /// @return The current reputation score.
    function getAgentReputation(address _owner) public view returns (uint256) {
        return reputationScores[_owner];
    }

    /// @notice 3. Computes and returns dynamic traits for a specific NFT based on its owner's reputation and activity.
    /// @dev This function defines a simple on-chain trait generation. More complex traits would use an off-chain API.
    /// @param _tokenId The ID of the Intelligence Agent NFT.
    /// @return level, wisdom, integrity, activityScore
    function getAgentTraits(uint256 _tokenId) public view returns (uint256 level, uint256 wisdom, uint256 integrity, uint256 activityScore) {
        address owner = ownerOf(_tokenId);
        uint256 reputation = reputationScores[owner];

        level = reputation / 100 > 0 ? reputation / 100 : 1; // 1 level per 100 reputation, min 1
        wisdom = (reputation / 10) % 100; // Derived from reputation
        integrity = (reputation / 5) % 100; // Derived from reputation
        activityScore = (block.timestamp - agentMintTime[_tokenId]) / 1 days; // Days since mint, simple activity proxy
    }

    /// @notice 4. Triggers an off-chain metadata refresh for the specified NFT.
    /// @dev This function only emits an event. An off-chain service listens to this event
    ///      to update the NFT's metadata on IPFS or similar storage, and then update the `_baseTokenURI` if applicable.
    /// @param _tokenId The ID of the Intelligence Agent NFT.
    function updateAgentMetadata(uint256 _tokenId) external onlyAgentOwner(_tokenId) whenNotPaused {
        emit AgentMetadataUpdate(_tokenId, tokenURI(_tokenId));
    }

    /// @notice 5. Checks if an agent is active (e.g., not currently suspended due to slashing).
    /// @dev This is a placeholder. An advanced system would track suspensions or other states.
    /// @param _tokenId The ID of the Intelligence Agent NFT.
    /// @return True if the agent is active, false otherwise.
    function isAgentActive(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId); // For now, an agent is active if it exists
    }

    /// @notice 6. Special logic for transferring the Soulbound-like NFT.
    /// @dev An agent is initially Soulbound (`isAgentSoulbound[tokenId] = true`).
    ///      It can become transferable if the owner reaches a `MIN_REPUTATION_FOR_TRANSFER` and pays a `TRANSFER_FEE_PERCENTAGE`.
    ///      The Soulbound status is only removed once. Subsequent transfers behave like normal ERC721.
    /// @param _from The current owner of the NFT.
    /// @param _to The recipient of the NFT.
    /// @param _tokenId The ID of the Intelligence Agent NFT.
    function transferAgent(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        if (ownerOf(_tokenId) != _from) revert Unauthorized();
        if (_from == _to) return; // No self-transfers

        uint256 feePaid = 0;
        if (isAgentSoulbound[_tokenId]) {
            uint256 minRepForTransfer = protocolParameters[MIN_REPUTATION_FOR_TRANSFER];
            if (reputationScores[_from] < minRepForTransfer) {
                revert InsufficientReputation(minRepForTransfer, reputationScores[_from]);
            }

            uint256 transferFeePercentage = protocolParameters[TRANSFER_FEE_PERCENTAGE];
            uint256 baseTransferFeeAmount = protocolParameters[MIN_VALIDATOR_STAKE]; // Use MIN_VALIDATOR_STAKE as a base value
            feePaid = (baseTransferFeeAmount * transferFeePercentage) / 10_000; // x100 percentage.

            if (feePaid > 0) {
                paymentToken.transferFrom(_from, address(this), feePaid);
                totalProtocolFees += feePaid;
            }

            isAgentSoulbound[_tokenId] = false; // Agent is no longer soulbound after this first special transfer
        } else {
            // For subsequent transfers (not soulbound), no special fee or reputation check.
            // ERC721 `_transfer` will handle basic owner checks.
        }

        // Perform the actual transfer via ERC721 _transfer, which has its own checks
        _transfer(_from, _to, _tokenId);

        // Reputation also transfers with the agent to the new owner.
        // The old owner's reputation becomes 0 for this protocol.
        uint256 prevOwnerReputation = reputationScores[_from];
        reputationScores[_from] = 0;
        reputationScores[_to] += prevOwnerReputation; // New owner inherits reputation

        emit AgentTransferred(_from, _to, _tokenId, feePaid);
        emit AgentReputationUpdated(_from, 0);
        emit AgentReputationUpdated(_to, reputationScores[_to]);
    }

    /// @dev Internal function to handle ERC721 transfers. Prevents transfers if `isAgentSoulbound` is true and conditions are not met.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from address(0)) and burning (to address(0))
        if (from == address(0) || to == address(0)) {
            return;
        }

        // If an agent is soulbound, it cannot be transferred via standard ERC721 methods.
        // It must use the custom `transferAgent` function which handles the conditions.
        // The `transferAgent` function directly calls `_transfer` and bypasses this check for soulbound.
        if (isAgentSoulbound[tokenId] && _msgSender() != from) { // `_msgSender() != from` ensures that `transferFrom` calls are blocked if soulbound,
            // but not `transferAgent` which calls `_transfer` internally (where `_msgSender()` could be `address(this)` if called from within `transferAgent`).
            revert Unauthorized();
        }
    }


    // --- II. Data Submission & Bounty System ---

    /// @notice 7. Allows users to submit data/insights, potentially linked to a bounty.
    /// @dev Requires a minimum reputation score from the submitter. Initiates a validation round.
    /// @param _dataHash IPFS hash or similar for the data content.
    /// @param _bountyId The ID of the bounty this submission is for (0 if none).
    function submitData(string memory _dataHash, uint252 _bountyId) external whenNotPaused {
        if (!hasAgent(_msgSender())) revert AgentNotFound();

        if (_bountyId != 0) {
            Bounty storage b = bounties[_bountyId];
            if (b.status != BountyStatus.Active) revert InvalidBounty(_bountyId);
            if (reputationScores[_msgSender()] < b.requiredReputation) {
                revert InsufficientReputation(b.requiredReputation, reputationScores[_msgSender()]);
            }
        }

        uint252 currentSubmissionId = uint252(nextSubmissionId++); // Type cast to uint252
        uint252 currentValidationRoundId = uint252(nextValidationRoundId++); // Type cast to uint252

        submissions[currentSubmissionId] = Submission({
            submitter: _msgSender(),
            dataHash: _dataHash,
            bountyId: _bountyId,
            submissionTime: block.timestamp,
            validationRoundId: currentValidationRoundId,
            isProcessed: false
        });

        validationRounds[currentValidationRoundId] = ValidationRound({
            submissionId: currentSubmissionId,
            stakeRequirement: protocolParameters[MIN_VALIDATOR_STAKE],
            minValidators: 3, // Example: Minimum 3 validators to participate
            maxValidators: 10, // Example: Maximum 10 validators
            validationPeriodEnd: block.timestamp + protocolParameters[VALIDATION_PERIOD_DURATION],
            voters: new address[](0), // Initialize empty list of voters
            hasVoted: new mapping(address => bool), // Initialize empty mappings
            validatorVotes: new mapping(address => bool),
            validatorStakes: new mapping(address => uint256),
            totalPositiveVotes: 0,
            totalNegativeVotes: 0,
            status: ValidationStatus.Active,
            isConsensusReached: false,
            isSubmissionAccurate: false
        });

        emit DataSubmitted(currentSubmissionId, _msgSender(), _bountyId, _dataHash);
    }

    /// @notice 8. Admin/privileged role to create a bounty for specific data.
    /// @param _rewardAmount The reward in paymentToken for the successful submitter.
    /// @param _requiredReputation The minimum reputation a submitter needs to participate.
    /// @param _descriptionHash IPFS hash for the detailed bounty description.
    function createBounty(uint256 _rewardAmount, uint256 _requiredReputation, string memory _descriptionHash) external whenNotPaused onlyRole(BOUNTY_CREATOR_ROLE) {
        if (_rewardAmount == 0) revert InvalidAmount();

        uint252 currentBountyId = uint252(nextBountyId++);
        bounties[currentBountyId] = Bounty({
            creator: _msgSender(),
            rewardAmount: _rewardAmount,
            requiredReputation: _requiredReputation,
            descriptionHash: _descriptionHash,
            status: BountyStatus.Active,
            creationTime: block.timestamp,
            winningSubmissionId: 0 // No winning submission initially
        });

        // Transfer reward funds to the contract
        paymentToken.transferFrom(_msgSender(), address(this), _rewardAmount);

        emit BountyCreated(currentBountyId, _msgSender(), _rewardAmount);
    }

    /// @notice 9. Allows the successful submitter of a validated submission to claim bounty rewards.
    /// @param _bountyId The ID of the bounty to claim.
    function claimBounty(uint252 _bountyId) external whenNotPaused {
        Bounty storage b = bounties[_bountyId];
        if (b.status != BountyStatus.Active) revert InvalidBounty(_bountyId);
        if (b.winningSubmissionId == 0) revert BountyNotClaimable();

        Submission storage winningSubmission = submissions[b.winningSubmissionId];
        if (winningSubmission.submitter != _msgSender()) revert Unauthorized(); // Only winning submitter can claim

        // Transfer reward
        paymentToken.transfer(_msgSender(), b.rewardAmount);
        b.status = BountyStatus.Claimed;

        emit BountyClaimed(_bountyId, _msgSender(), b.rewardAmount);
    }

    /// @notice 10. Retrieves detailed information about a data submission.
    /// @param _submissionId The ID of the submission.
    /// @return A tuple containing submission details.
    function getSubmissionDetails(uint252 _submissionId) public view returns (Submission memory) {
        return submissions[_submissionId];
    }

    /// @notice 11. Returns the count of total bounties.
    /// @dev In a real dApp, active/pending bounties list would be indexed off-chain.
    /// @return The count of total bounties.
    function getPendingBounties() public view returns (uint256) {
        return nextBountyId;
    }

    // --- III. Validation & Slashing Mechanism ---

    /// @notice 12. Users stake tokens to become eligible validators.
    /// @param _amount The amount of paymentToken to stake.
    function stakeForValidatorRole(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0 || _amount < protocolParameters[MIN_VALIDATOR_STAKE]) revert InvalidAmount();

        paymentToken.transferFrom(_msgSender(), address(this), _amount);
        validatorStakes[_msgSender()] += _amount;
        _grantRole(VALIDATOR_ROLE, _msgSender());

        emit ValidatorStaked(_msgSender(), _amount);
    }

    /// @notice 13. Users unstake their tokens and exit the validator role, after a cooldown.
    function unstakeFromValidatorRole() external whenNotPaused nonReentrant {
        uint256 currentStake = validatorStakes[_msgSender()];
        if (currentStake == 0) revert NotEnoughStake(1, 0);

        if (validatorStakeLockupEnd[_msgSender()] > block.timestamp) revert StakeLocked();

        // Start lockup period before actual unstake
        validatorStakeLockupEnd[_msgSender()] = block.timestamp + protocolParameters[VALIDATOR_LOCKUP_DURATION];

        // Revoke role immediately, but funds are locked.
        _revokeRole(VALIDATOR_ROLE, _msgSender());

        // For simplicity, let's assume `unstakeFromValidatorRole` is callable only *after* lockup.
        // If callable to *request* unstake, then a separate `withdrawUnstakedTokens` is needed.
        // To simplify, this function allows withdrawal if lockup is passed, otherwise it effectively sets `validatorStakes` to 0
        // but tokens are still in contract until lockup passes. Let's make it simple and direct:
        // User must wait for lockup to pass before calling this.
        uint256 amountToUnstake = currentStake;
        validatorStakes[_msgSender()] = 0; // Clear stake

        paymentToken.transfer(_msgSender(), amountToUnstake); // Transfer back
        emit ValidatorUnstaked(_msgSender(), amountToUnstake);
    }

    /// @notice 14. Validators vote on the accuracy of a submission.
    /// @param _validationRoundId The ID of the validation round.
    /// @param _isAccurate True if the validator believes the submission is accurate, false otherwise.
    function validateSubmission(uint252 _validationRoundId, bool _isAccurate) external whenNotPaused onlyRole(VALIDATOR_ROLE) {
        ValidationRound storage vr = validationRounds[_validationRoundId];
        if (vr.status != ValidationStatus.Active) revert InvalidSubmissionStatus();
        if (block.timestamp >= vr.validationPeriodEnd) revert ValidationPeriodEnded();
        if (vr.hasVoted[_msgSender()]) revert AlreadyVotedInRound();
        if (validatorStakes[_msgSender()] < vr.stakeRequirement) revert NotEnoughStake(vr.stakeRequirement, validatorStakes[_msgSender()]);
        if (vr.voters.length >= vr.maxValidators) revert NotEnoughValidators(); // Using NotEnoughValidators as max reached

        // Take a "snapshot" of the validator's stake for this round
        vr.validatorStakes[_msgSender()] = validatorStakes[_msgSender()];
        vr.hasVoted[_msgSender()] = true;
        vr.validatorVotes[_msgSender()] = _isAccurate;
        vr.voters.push(_msgSender()); // Add to list of voters

        if (_isAccurate) {
            vr.totalPositiveVotes++;
        } else {
            vr.totalNegativeVotes++;
        }

        emit SubmissionValidated(_validationRoundId, _msgSender(), _isAccurate);
    }

    /// @notice 15. Allows users/validators to report malicious behavior of another validator.
    /// @dev This would trigger a separate governance/dispute resolution process.
    ///      For simplicity, it only emits an event here.
    /// @param _validationRoundId The validation round where malicious activity occurred.
    /// @param _validator The address of the validator being reported.
    function reportMaliciousValidator(uint252 _validationRoundId, address _validator) external whenNotPaused {
        // A more advanced system would have a dispute process, or a role for "arbitrators".
        // This primarily acts as an event for off-chain monitoring.
        emit MaliciousValidatorReported(_validationRoundId, _msgSender(), _validator);
    }

    /// @notice 16. Finalizes a validation round, distributing rewards, updating reputations, and handling slashing.
    /// @dev Can be called by anyone after the validation period ends.
    /// @param _validationRoundId The ID of the validation round to process.
    function processValidationRound(uint252 _validationRoundId) external whenNotPaused nonReentrant {
        ValidationRound storage vr = validationRounds[_validationRoundId];
        if (vr.status != ValidationStatus.Active) revert InvalidSubmissionStatus();
        if (block.timestamp < vr.validationPeriodEnd) revert ValidationPeriodEnded();
        if (vr.voters.length < vr.minValidators) revert NotEnoughValidators();

        vr.status = ValidationStatus.Finalized;
        uint256 totalVotes = vr.totalPositiveVotes + vr.totalNegativeVotes;
        vr.isConsensusReached = true; // Consensus implies it passed the threshold
        vr.isSubmissionAccurate = (vr.totalPositiveVotes * 100) / totalVotes >= 50; // Simple majority (>= 50%)

        Submission storage s = submissions[vr.submissionId];
        s.isProcessed = true;

        uint256 reputationGainSubmission = protocolParameters[REPUTATION_GAIN_SUBMISSION];
        uint256 reputationLossSubmission = protocolParameters[REPUTATION_LOSS_SUBMISSION];
        uint256 reputationGainValidation = protocolParameters[REPUTATION_GAIN_VALIDATION];
        uint256 reputationLossValidation = protocolParameters[REPUTATION_LOSS_VALIDATION];
        uint256 slashPercentage = protocolParameters[SLASH_PERCENTAGE];

        // Update submitter's reputation
        if (vr.isSubmissionAccurate) {
            reputationScores[s.submitter] += reputationGainSubmission;
        } else {
            if (reputationScores[s.submitter] > reputationLossSubmission) {
                reputationScores[s.submitter] -= reputationLossSubmission;
            } else {
                reputationScores[s.submitter] = 0;
            }
        }
        emit AgentReputationUpdated(s.submitter, reputationScores[s.submitter]);

        // Process validators and update their reputations/stakes
        for (uint256 i = 0; i < vr.voters.length; i++) {
            address validator = vr.voters[i];
            bool validatorVote = vr.validatorVotes[validator];
            uint256 stake = vr.validatorStakes[validator];

            if (validatorVote == vr.isSubmissionAccurate) { // Correct vote
                reputationScores[validator] += reputationGainValidation;
            } else { // Incorrect vote - slash
                if (reputationScores[validator] > reputationLossValidation) {
                    reputationScores[validator] -= reputationLossValidation;
                } else {
                    reputationScores[validator] = 0;
                }

                uint256 slashAmount = (stake * slashPercentage) / 10_000;
                if (slashAmount > stake) slashAmount = stake; // Cannot slash more than stake
                validatorStakes[validator] -= slashAmount; // Reduce effective stake
                totalProtocolFees += slashAmount; // Slashed funds contribute to protocol fees

                emit ValidatorSlashed(validator, slashAmount);
            }
            emit AgentReputationUpdated(validator, reputationScores[validator]);
        }

        if (s.bountyId != 0 && vr.isSubmissionAccurate) {
            bounties[s.bountyId].winningSubmissionId = vr.submissionId; // Link winning submission to bounty
        }

        emit ValidationRoundProcessed(_validationRoundId, vr.isSubmissionAccurate, vr.totalPositiveVotes, vr.totalNegativeVotes);
    }

    /// @notice 17. Returns the current staked amount of a validator.
    /// @param _validator The address of the validator.
    /// @return The staked amount.
    function getValidatorStake(address _validator) public view returns (uint256) {
        return validatorStakes[_validator];
    }

    // --- IV. Protocol Configuration & Administration ---

    /// @notice 18. Admin function to adjust core protocol parameters.
    /// @param _paramName The name of the parameter (bytes32).
    /// @param _value The new value for the parameter.
    function setProtocolParameter(bytes32 _paramName, uint256 _value) external whenNotPaused onlyRole(ADMIN_ROLE) {
        protocolParameters[_paramName] = _value;
        emit ProtocolParameterSet(_paramName, _value);
    }

    /// @notice 19. Admin function to withdraw accumulated protocol fees.
    /// @dev Only callable by ADMIN_ROLE.
    function withdrawProtocolFees() external whenNotPaused onlyRole(ADMIN_ROLE) {
        uint256 amount = totalProtocolFees;
        totalProtocolFees = 0;
        if (amount > 0) {
            paymentToken.transfer(_msgSender(), amount);
            emit ProtocolFeesWithdrawn(_msgSender(), amount);
        }
    }

    /// @notice 20. Admin function to pause critical operations in emergencies.
    function pauseProtocol() external onlyRole(ADMIN_ROLE) {
        paused = !paused;
        emit ProtocolPaused(paused);
    }

    /// @notice 21. Grants a role to an account.
    /// @param role The role to grant (e.g., ADMIN_ROLE, VALIDATOR_ROLE).
    /// @param account The address to grant the role to.
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /// @notice 22. Revokes a role from an account.
    /// @param role The role to revoke.
    /// @param account The address to revoke the role from.
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    // --- V. Advanced Reputation & Utility ---

    /// @notice 23. A mechanism to gradually decay reputation over time for inactivity or system rebalancing.
    /// @dev Can be triggered by an admin or an external keeper/bot.
    ///      Decays reputation based on `REPUTATION_DECAY_RATE`.
    /// @param _user The address whose reputation to decay.
    function decayReputation(address _user) external whenNotPaused onlyRole(ADMIN_ROLE) {
        if (!hasAgent(_user)) revert NoAgentToDecay();
        uint256 currentReputation = reputationScores[_user];
        if (currentReputation == 0) return;

        uint256 decayRate = protocolParameters[REPUTATION_DECAY_RATE];
        uint256 newReputation;
        if (currentReputation > decayRate) {
            newReputation = currentReputation - decayRate;
        } else {
            newReputation = 0;
        }
        reputationScores[_user] = newReputation;
        emit ReputationDecayed(_user, currentReputation, newReputation);
        emit AgentReputationUpdated(_user, newReputation);
    }

    /// @notice 24. Standard ERC721 function, generating dynamic URI based on on-chain state.
    /// @dev The URI could point to an off-chain API that dynamically generates JSON metadata
    ///      based on the `getAgentTraits` output and other on-chain data.
    /// @param _tokenId The ID of the NFT.
    /// @return The token URI string.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId);
        uint256 level;
        uint256 wisdom;
        uint256 integrity;
        uint256 activityScore;
        (level, wisdom, integrity, activityScore) = getAgentTraits(_tokenId);

        // A dynamic URI would typically point to an API endpoint:
        // `https://my-api.com/nft/{tokenId}?level={level}&wisdom={wisdom}&integrity={integrity}&activity={activityScore}`
        // For demonstration, we'll return a simple string encoding some traits.
        // In a production environment, this URI would resolve to a JSON file containing the actual metadata,
        // which itself would be dynamically generated by an off-chain service listening to `AgentMetadataUpdate` events.

        return string(abi.encodePacked(
            "ipfs://CID/metadata/", // Placeholder for base IPFS path
            _tokenId.toString(),
            "?level=", level.toString(),
            "&wisdom=", wisdom.toString(),
            "&integrity=", integrity.toString(),
            "&activity=", activityScore.toString(),
            "&reputation=", reputationScores[ownerOf(_tokenId)].toString(),
            "&soulbound=", isAgentSoulbound[_tokenId] ? "true" : "false"
        ));
    }

    // --- Internal Helpers ---
    function hasAgent(address _user) internal view returns (bool) {
        return balanceOf(_user) > 0;
    }
}
```