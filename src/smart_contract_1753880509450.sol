Here's a Solidity smart contract named `SynergyNet` that embodies several advanced, creative, and trendy concepts, while striving to avoid direct duplication of existing open-source projects. It focuses on decentralized collective intelligence, AI-verified insights, dynamic soulbound NFTs, and a reputation system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For interface compatibility, not full ERC721
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For address.call

/**
 * @title SynergyNet - Decentralized AI-Driven Collective Intelligence Network
 * @author Your Name / AI Assistant
 * @notice SynergyNet is a decentralized platform designed to foster collective intelligence.
 *         Participants contribute insights (data, predictions, analyses) in various knowledge domains.
 *         These insights are verified by an off-chain AI oracle (or a network of them) and
 *         can be challenged by the community. Successful, validated contributions earn participants
 *         "Soulbound Auras" (SBAs) – dynamic, non-transferable NFTs that reflect their evolving
 *         reputation, expertise, and influence within specific domains. The system features a
 *         built-in reputation decay mechanism and a basic governance framework for parameter
 *         updates and future evolution.
 *
 * Advanced Concepts:
 * - AI Oracle Integration: Uses a designated oracle address for off-chain AI verdict submission.
 * - Dynamic Soulbound NFTs (SBA): Non-transferable NFTs whose metadata (via tokenURI) can evolve
 *   based on on-chain reputation and activity, representing a user's expertise.
 * - Reputation System with Decay: A multi-dimensional reputation system (per domain) that
 *   rewards positive contributions and decays over time to incentivize continuous engagement.
 * - Challenge Mechanism: Allows community to dispute oracle verdicts, introducing a layer of
 *   decentralized oversight.
 * - Simplified On-chain Governance: Enables reputation-weighted voting on proposals to manage
 *   contract parameters.
 * - Gas Optimization: Uses `bytes32` for hashes, `uint256` for large IDs/scores, and explicit
 *   error handling for efficiency.
 *
 * Note on AI Integration: True on-chain AI computation is highly gas-intensive and complex.
 * This contract assumes an off-chain AI service acts as a trusted oracle, whose verdicts are
 * then recorded on-chain. Future enhancements could involve ZK-proofs for verifiable computation
 * or optimistic rollup-style challenges for off-chain AI results.
 */

// --- Outline ---
// I. Configuration & Security
// II. Domain Management
// III. Insight Submission & Verification
// IV. Soulbound Auras (SBA) Management (Custom Non-Transferable ERC721-like)
// V. Reputation System
// VI. Governance (Simplified)
// VII. Read Functions & Utilities

// --- Function Summary ---

// I. Configuration & Security:
// 1.  constructor(): Initializes the contract with an owner and sets initial parameters.
// 2.  setOracleAddress(address _newOracle): Sets or updates the address of the trusted AI oracle.
// 3.  setChallengePeriod(uint256 _newPeriod): Sets the time window for challenging oracle verdicts.
// 4.  setReputationDecayRate(uint256 _newRate): Configures the rate at which user reputation naturally declines over time (basis points).
// 5.  setReputationDecayInterval(uint256 _newInterval): Sets the time interval for reputation decay calculation.
// 6.  setSBA_NFT_BaseURI(string memory _newURI): Sets the base URI for Soulbound Aura metadata, enabling dynamic NFT updates.
// 7.  setMinTotalReputationToPropose(uint256 _newMin): Sets minimum reputation required to submit a governance proposal.
// 8.  setProposalVotingPeriod(uint256 _newPeriod): Sets the duration for governance proposal voting.
// 9.  togglePause(): Emergency function to pause/unpause critical contract operations.
// 10. withdrawEth(address payable _to, uint256 _amount): Allows the owner to withdraw collected ETH (e.g., from challenge bonds).

// II. Domain Management:
// 11. createDomain(string memory _name, string memory _description, uint256 _minReputationForSBA): Creates a new knowledge domain.
// 12. updateDomainConfig(uint256 _domainId, uint256 _newMinRepForSBA, string memory _newDescription): Updates configuration for an existing domain.
// 13. getDomainInfo(uint256 _domainId): Retrieves details about a specific domain.

// III. Insight Submission & Verification:
// 14. submitInsight(uint256 _domainId, bytes32 _insightHash, string memory _metadataURI): Users submit a hash of their off-chain insight data.
// 15. recordOracleVerdict(uint256 _insightId, bool _isValid, bytes32 _oracleSignature): The designated AI oracle submits its verdict.
// 16. challengeOracleVerdict(uint256 _insightId): Allows any user to challenge an oracle's verdict, requiring a bond.
// 17. resolveChallenge(uint256 _challengeId, bool _oracleVerdictConfirmed): Owner/governance resolves an active challenge.
// 18. confirmInsightValidation(uint256 _insightId): Finalizes the validation process for an insight that has passed its challenge period or had its challenge resolved.

// IV. Soulbound Auras (SBA) Management (Custom Non-Transferable ERC721-like):
// 19. name(): Returns the name of the SBA token collection.
// 20. symbol(): Returns the symbol of the SBA token collection.
// 21. tokenURI(uint256 _tokenId): Returns the metadata URI for a given Soulbound Aura token ID, showing its dynamic properties.
// 22. balanceOf(address _owner): Returns the number of Soulbound Auras owned by an address.
// 23. ownerOf(uint256 _tokenId): Returns the owner of a given Soulbound Aura token ID.
// 24. getSBA_TokenId(address _owner, uint256 _domainId): Retrieves the token ID of a user's Soulbound Aura for a specific domain.

// V. Reputation System:
// 25. getDomainReputation(address _user, uint256 _domainId): Retrieves a user's current reputation score within a specific knowledge domain.
// 26. getTotalReputation(address _user): Retrieves a user's aggregated reputation score across all domains.
// 27. decayReputation(address _user): Allows anyone to trigger the reputation decay process for a user, based on the set decay rate and last decay timestamp.
// 28. revokeReputation(address _user, uint256 _domainId, uint256 _amount): Allows owner/governance to manually deduct reputation.

// VI. Governance (Simplified):
// 29. submitGovernanceProposal(string memory _description, bytes memory _calldata, address _targetContract): Allows users to propose changes.
// 30. voteOnProposal(uint256 _proposalId, bool _support): Enables eligible users to cast their reputation-weighted vote on active proposals.
// 31. executeProposal(uint256 _proposalId): Executes a passed governance proposal.

// VII. Read Functions & Utilities:
// 32. getInsightDetails(uint256 _insightId): Returns comprehensive details about a specific insight.
// 33. getChallengeDetails(uint256 _challengeId): Returns details about a specific challenge.
// 34. getProposalDetails(uint256 _proposalId): Returns details about a specific governance proposal.
// 35. getDomainIds(): Returns a list of all active domain IDs.
// 36. getPendingInsightsCount(): Returns the number of insights currently awaiting oracle verdict or challenge resolution.

contract SynergyNet is Ownable, IERC721, IERC721Metadata {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address; // For safe ETH transfer

    // --- State Variables ---

    // I. Configuration & Security
    address public oracleAddress;
    uint256 public challengePeriod; // Time in seconds for challenging an oracle verdict
    uint256 public reputationDecayRate; // Percentage decay per decay interval (e.g., 500 = 5%, 10000 = 100%)
    uint256 public reputationDecayInterval; // Time in seconds for reputation decay calculation
    string public sbaBaseURI; // Base URI for Soulbound Aura metadata (e.g., ipfs://...)
    bool public paused;
    uint256 public constant CHALLENGE_BOND_AMOUNT = 0.01 ether; // Example bond amount

    // II. Domain Management
    struct Domain {
        string name;
        string description;
        uint256 minReputationForSBA; // Minimum reputation needed to mint an SBA in this domain
        bool isActive;
        Counters.Counter totalInsights; // Insights count for the domain
    }
    mapping(uint256 => Domain) public domains;
    Counters.Counter private _domainIds;
    uint256[] public domainIdList; // To iterate over domains

    // III. Insight Submission & Verification
    enum InsightStatus { AwaitingOracle, OracleVerdict, Challenged, Resolved, Validated, Invalidated }
    struct Insight {
        uint256 id;
        uint256 domainId;
        address submitter;
        bytes32 insightHash; // Hash of the off-chain insight data
        string metadataURI; // URI pointing to public insight details (e.g., IPFS)
        uint256 submittedAt;
        InsightStatus status;
        bool oracleVerdict; // True if oracle deemed valid
        uint256 challengeId; // ID of the associated challenge, if any
    }
    mapping(uint256 => Insight) public insights;
    Counters.Counter private _insightIds;

    struct Challenge {
        uint256 id;
        uint256 insightId;
        address challenger;
        uint256 challengedAt;
        bool oracleVerdictConfirmed; // True if oracle's original verdict was confirmed
        bool resolved;
    }
    mapping(uint256 => Challenge) public challenges;
    Counters.Counter private _challengeIds;

    // IV. Soulbound Auras (SBA) Management (ERC721-like, non-transferable)
    // Token ID is composed of (Domain ID << 160) | (uint160(User Address))
    mapping(uint256 => address) private _sbaOwners; // tokenId => owner address
    mapping(address => mapping(uint256 => uint256)) private _sbaTokenIds; // owner => domainId => tokenId
    mapping(address => Counters.Counter) private _sbaBalances; // owner => count of SBAs
    uint256 private _sbaTotalSupply;

    // V. Reputation System
    mapping(address => mapping(uint256 => uint256)) public domainReputation; // user => domainId => reputation score
    mapping(address => uint256) public lastReputationDecay; // user => timestamp of last decay calculation

    // VI. Governance
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes calldataPayload; // calldata to execute if proposal passes
        address targetContract; // Contract to call (can be this contract)
        uint256 submittedAt;
        uint256 votingEndsAt;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 minTotalReputationRequired; // Min reputation to submit/vote on this proposal
        ProposalStatus status;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => hasVoted
    Counters.Counter private _proposalIds;
    uint256 public minTotalReputationToPropose; // Min overall reputation to submit a proposal
    uint256 public proposalVotingPeriod; // Time in seconds for voting

    // --- Events ---
    event OracleAddressSet(address indexed _newOracle);
    event ChallengePeriodSet(uint256 _newPeriod);
    event ReputationDecayRateSet(uint256 _newRate);
    event ReputationDecayIntervalSet(uint256 _newInterval);
    event SBA_NFT_BaseURISet(string _newURI);
    event MinTotalReputationToProposeSet(uint256 _newMin);
    event ProposalVotingPeriodSet(uint256 _newPeriod);
    event Paused(address account);
    event Unpaused(address account);
    event EthWithdrawn(address indexed _to, uint256 _amount);

    event DomainCreated(uint256 indexed _domainId, string _name, address indexed _creator);
    event DomainConfigUpdated(uint256 indexed _domainId, uint256 _newMinRepForSBA, string _newDescription);

    event InsightSubmitted(uint256 indexed _insightId, uint256 indexed _domainId, address indexed _submitter, bytes32 _insightHash);
    event OracleVerdictRecorded(uint256 indexed _insightId, bool _isValid);
    event ChallengeInitiated(uint256 indexed _challengeId, uint256 indexed _insightId, address indexed _challenger, uint256 _bondAmount);
    event ChallengeResolved(uint256 indexed _challengeId, uint256 indexed _insightId, bool _oracleVerdictConfirmed);
    event InsightValidated(uint256 indexed _insightId, address indexed _submitter, uint256 _domainId);
    event InsightInvalidated(uint256 indexed _insightId, address indexed _submitter, uint256 _domainId);

    event SoulboundAuraMinted(address indexed _owner, uint256 indexed _domainId, uint256 _tokenId);
    event SoulboundAuraUpdated(address indexed _owner, uint256 indexed _domainId, uint256 _tokenId);

    event ReputationUpdated(address indexed _user, uint256 indexed _domainId, uint256 _newReputation);
    event ReputationDecayed(address indexed _user, uint256 _oldReputation, uint256 _newReputation);
    event ReputationRevoked(address indexed _user, uint256 indexed _domainId, uint256 _amount);

    event ProposalSubmitted(uint256 indexed _proposalId, address indexed _proposer, string _description);
    event VoteCast(uint256 indexed _proposalId, address indexed _voter, bool _support);
    event ProposalExecuted(uint256 indexed _proposalId);

    // --- Custom Errors ---
    error PausedContract();
    error NotOracle();
    error OracleAlreadyVerdicted();
    error InsightNotAwaitingOracle();
    error InsightNotReadyForChallenge();
    error InsightNotInChallengedState();
    error ChallengePeriodNotOver();
    error ChallengePeriodActive();
    error InsufficientChallengeBond();
    error ChallengeAlreadyResolved();
    error ChallengeNotFound();
    error InvalidDomain();
    error SBAAlreadyExists();
    error SBANotFound();
    error ReputationCannotBeNegative();
    error AlreadyVoted();
    error ProposalNotFound();
    error ProposalNotActive();
    error ProposalVotingPeriodActive();
    error ProposalAlreadyExecuted();
    error InsufficientReputationToPropose(uint256 currentRep, uint256 requiredRep);
    error InsufficientReputationToVote(uint256 currentRep, uint256 requiredRep);
    error InvalidCalldataOrTarget();
    error RevertBecauseNonTransferable(); // Custom error for non-transferable ERC721 methods

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert PausedContract();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert NotOracle();
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracle) Ownable(msg.sender) {
        require(_initialOracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _initialOracle;
        challengePeriod = 2 days; // 2 days for challenging insights
        reputationDecayRate = 500; // 5% decay (500 basis points out of 10000)
        reputationDecayInterval = 30 days; // Decay every 30 days
        sbaBaseURI = "https://synergynet.io/sba_metadata/"; // Default base URI for metadata JSON
        minTotalReputationToPropose = 1000; // Example: 1000 reputation points to submit proposals
        proposalVotingPeriod = 7 days; // 7 days for governance voting

        emit OracleAddressSet(_initialOracle);
    }

    // --- I. Configuration & Security ---

    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    function setChallengePeriod(uint256 _newPeriod) public onlyOwner {
        challengePeriod = _newPeriod;
        emit ChallengePeriodSet(_newPeriod);
    }

    function setReputationDecayRate(uint256 _newRate) public onlyOwner {
        require(_newRate <= 10000, "Decay rate cannot exceed 100% (10000 basis points)"); // 10000 = 100%
        reputationDecayRate = _newRate;
        emit ReputationDecayRateSet(_newRate);
    }

    function setReputationDecayInterval(uint256 _newInterval) public onlyOwner {
        reputationDecayInterval = _newInterval;
        emit ReputationDecayIntervalSet(_newInterval);
    }

    function setSBA_NFT_BaseURI(string memory _newURI) public onlyOwner {
        sbaBaseURI = _newURI;
        emit SBA_NFT_BaseURISet(_newURI);
    }

    function setMinTotalReputationToPropose(uint256 _newMin) public onlyOwner {
        minTotalReputationToPropose = _newMin;
        emit MinTotalReputationToProposeSet(_newMin);
    }

    function setProposalVotingPeriod(uint256 _newPeriod) public onlyOwner {
        proposalVotingPeriod = _newPeriod;
        emit ProposalVotingPeriodSet(_newPeriod);
    }

    function togglePause() public onlyOwner {
        paused = !paused;
        if (paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    function withdrawEth(address payable _to, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        _to.sendValue(_amount);
        emit EthWithdrawn(_to, _amount);
    }

    // --- II. Domain Management ---

    function createDomain(
        string memory _name,
        string memory _description,
        uint256 _minReputationForSBA
    ) public onlyOwner whenNotPaused returns (uint256) {
        _domainIds.increment();
        uint256 newDomainId = _domainIds.current();
        domains[newDomainId] = Domain({
            name: _name,
            description: _description,
            minReputationForSBA: _minReputationForSBA,
            isActive: true,
            totalInsights: Counters.Counter(0)
        });
        domainIdList.push(newDomainId);
        emit DomainCreated(newDomainId, _name, msg.sender);
        return newDomainId;
    }

    function updateDomainConfig(
        uint256 _domainId,
        uint256 _newMinRepForSBA,
        string memory _newDescription
    ) public onlyOwner whenNotPaused {
        Domain storage domain = domains[_domainId];
        if (!domain.isActive) revert InvalidDomain();
        domain.minReputationForSBA = _newMinRepForSBA;
        domain.description = _newDescription;
        emit DomainConfigUpdated(_domainId, _newMinRepForSBA, _newDescription);
    }

    function getDomainInfo(
        uint256 _domainId
    ) public view returns (string memory name, string memory description, uint256 minReputationForSBA, bool isActive, uint256 totalInsights) {
        Domain storage domain = domains[_domainId];
        if (!domain.isActive) revert InvalidDomain();
        return (domain.name, domain.description, domain.minReputationForSBA, domain.isActive, domain.totalInsights.current());
    }

    // --- III. Insight Submission & Verification ---

    function submitInsight(
        uint256 _domainId,
        bytes32 _insightHash,
        string memory _metadataURI
    ) public whenNotPaused returns (uint256) {
        if (!domains[_domainId].isActive) revert InvalidDomain();

        _insightIds.increment();
        uint256 newInsightId = _insightIds.current();
        insights[newInsightId] = Insight({
            id: newInsightId,
            domainId: _domainId,
            submitter: msg.sender,
            insightHash: _insightHash,
            metadataURI: _metadataURI,
            submittedAt: block.timestamp,
            status: InsightStatus.AwaitingOracle,
            oracleVerdict: false, // Default to false
            challengeId: 0 // No challenge initially
        });
        emit InsightSubmitted(newInsightId, _domainId, msg.sender, _insightHash);
        return newInsightId;
    }

    function recordOracleVerdict(
        uint256 _insightId,
        bool _isValid,
        bytes32 _oracleSignature // Placeholder for actual signature verification (e.g., ECDSA.recover)
    ) public onlyOracle whenNotPaused {
        Insight storage insight = insights[_insightId];
        if (insight.id == 0) revert InsightNotFound(); // Assuming ID 0 is invalid
        if (insight.status != InsightStatus.AwaitingOracle) revert OracleAlreadyVerdicted(); // Or already challenged/resolved
        
        // In a real system, you'd verify _oracleSignature against a hash of insight details + verdict
        // Example: require(ECDSA.recover(keccak256(abi.encodePacked(insight.insightHash, _isValid, _insightId)), _oracleSignature) == oracleAddress, "Invalid oracle signature");

        insight.oracleVerdict = _isValid;
        insight.status = InsightStatus.OracleVerdict;
        emit OracleVerdictRecorded(_insightId, _isValid);
    }

    function challengeOracleVerdict(uint256 _insightId) public payable whenNotPaused {
        Insight storage insight = insights[_insightId];
        if (insight.id == 0) revert InsightNotFound();
        if (insight.status != InsightStatus.OracleVerdict) revert InsightNotReadyForChallenge();
        if (block.timestamp > insight.submittedAt + challengePeriod) revert ChallengePeriodNotOver();
        if (msg.value < CHALLENGE_BOND_AMOUNT) revert InsufficientChallengeBond();

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();
        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            insightId: _insightId,
            challenger: msg.sender,
            challengedAt: block.timestamp,
            oracleVerdictConfirmed: false, // Will be set upon resolution
            resolved: false
        });
        insight.status = InsightStatus.Challenged;
        insight.challengeId = newChallengeId;

        emit ChallengeInitiated(newChallengeId, _insightId, msg.sender, CHALLENGE_BOND_AMOUNT);
    }

    function resolveChallenge(uint256 _challengeId, bool _oracleVerdictConfirmed) public onlyOwner whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound();
        if (challenge.resolved) revert ChallengeAlreadyResolved();

        Insight storage insight = insights[challenge.insightId];
        if (insight.id == 0) revert InsightNotFound(); // Should not happen if challenge is valid
        if (insight.status != InsightStatus.Challenged) revert InsightNotInChallengedState();

        challenge.resolved = true;
        challenge.oracleVerdictConfirmed = _oracleVerdictConfirmed;

        // If challenger was right (oracle verdict overturned), refund their bond
        if (insight.oracleVerdict != _oracleVerdictConfirmed) { 
            payable(challenge.challenger).sendValue(CHALLENGE_BOND_AMOUNT);
        }
        // If _oracleVerdictConfirmed is true (challenger was wrong), the bond is kept by the contract

        // Update insight status and reputation based on resolution
        if (insight.oracleVerdict == _oracleVerdictConfirmed) { // Oracle's original verdict was confirmed
            insight.status = InsightStatus.Validated;
            _updateReputation(insight.submitter, insight.domainId, 100); // Reward submitter for valid insight
            _mintOrUpdateSoulboundAura(insight.submitter, insight.domainId);
            domains[insight.domainId].totalInsights.increment();
            emit InsightValidated(insight.id, insight.submitter, insight.domainId);
        } else { // Oracle's original verdict was overturned
            insight.status = InsightStatus.Invalidated;
            _updateReputation(insight.submitter, insight.domainId, -50); // Penalize submitter for invalid insight
            _updateReputation(challenge.challenger, insight.domainId, 25); // Reward challenger for successful challenge
            // Downgrade SBA if reputation drops below threshold
            if (isSoulboundAuraActive(insight.submitter, insight.domainId)) {
                _updateSoulboundAura(insight.submitter, insight.domainId);
            }
            emit InsightInvalidated(insight.id, insight.submitter, insight.domainId);
        }

        emit ChallengeResolved(_challengeId, challenge.insightId, _oracleVerdictConfirmed);
    }

    function confirmInsightValidation(uint256 _insightId) public whenNotPaused {
        Insight storage insight = insights[_insightId];
        if (insight.id == 0) revert InsightNotFound();

        // Only valid if in OracleVerdict state AND challenge period has passed
        if (insight.status == InsightStatus.OracleVerdict) {
            if (block.timestamp <= insight.submittedAt + challengePeriod) revert ChallengePeriodActive();
            insight.status = InsightStatus.Validated;
            _updateReputation(insight.submitter, insight.domainId, 100); // Reward submitter
            _mintOrUpdateSoulboundAura(insight.submitter, insight.domainId);
            domains[insight.domainId].totalInsights.increment();
            emit InsightValidated(insight.id, insight.submitter, insight.domainId);
        } else if (insight.status == InsightStatus.Challenged) {
             revert InsightNotInChallengedState(); // Still needs to be resolved by owner/governance
        } else if (insight.status == InsightStatus.Validated || insight.status == InsightStatus.Invalidated) {
            // Already finalized, nothing to do
        } else {
            revert InsightNotAwaitingOracle(); // Not in a state to be confirmed/validated
        }
    }


    // --- IV. Soulbound Auras (SBA) Management (Custom Non-Transferable ERC721-like) ---
    // ERC721 interface compliance (only read functions, no transfer)

    // ERC721Metadata
    function name() public pure override returns (string memory) { return "SynergyNet Soulbound Aura"; }
    function symbol() public pure override returns (string memory) { return "SNSBA"; }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (_sbaOwners[_tokenId] == address(0)) revert SBANotFound(); // Check if token exists
        // Extract owner and domainId from tokenId
        address ownerAddr = address(uint160(_tokenId & type(uint160).max)); // Mask to get the lower 160 bits (address)
        uint256 domainId = _tokenId >> 160;

        // In a real dApp, this would point to a service that generates JSON metadata
        // based on the owner's current reputation in that specific domain.
        // For simplicity, we construct a URL that a backend could parse:
        // {sbaBaseURI}/{domainId}/{ownerAddress} -> returns JSON with dynamic properties
        return string(abi.encodePacked(sbaBaseURI, domainId.toString(), "/", Strings.toHexString(uint256(uint160(ownerAddr)))));
    }

    // ERC721 (Non-transferable overrides)
    function balanceOf(address _owner) public view override returns (uint256) {
        return _sbaBalances[_owner].current();
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address owner = _sbaOwners[_tokenId];
        if (owner == address(0)) revert SBANotFound();
        return owner;
    }

    // Explicitly revert transfer functions for Soulbound Tokens
    function approve(address, uint256) public pure override { revert RevertBecauseNonTransferable(); }
    function getApproved(uint256) public pure override returns (address) { revert RevertBecauseNonTransferable(); }
    function setApprovalForAll(address, bool) public pure override { revert RevertBecauseNonTransferable(); }
    function isApprovedForAll(address, address) public pure override returns (bool) { revert RevertBecauseNonTransferable(); }
    function transferFrom(address, address, uint256) public pure override { revert RevertBecauseNonTransferable(); }
    function safeTransferFrom(address, address, uint256) public pure override { revert RevertBecauseNonTransferable(); }
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override { revert RevertBecauseNonTransferable(); }

    // Internal helper to mint a new SBA
    function _mintSoulboundAura(address _to, uint256 _domainId) internal {
        uint256 tokenId = ( _domainId << 160 ) | uint256(uint160(_to));

        if (_sbaOwners[tokenId] != address(0)) revert SBAAlreadyExists();

        _sbaOwners[tokenId] = _to;
        _sbaTokenIds[_to][_domainId] = tokenId;
        _sbaBalances[_to].increment();
        _sbaTotalSupply++;

        emit SoulboundAuraMinted(_to, _domainId, tokenId);
        // Emulate ERC721 Transfer event for compatibility with explorers
        emit Transfer(address(0), _to, tokenId);
    }

    // Internal helper to signal a change in SBA properties (for metadata update)
    function _updateSoulboundAura(address _owner, uint256 _domainId) internal {
        uint256 tokenId = getSBA_TokenId(_owner, _domainId); // Will revert if not found

        // This event signals to off-chain services (indexers, metadata servers)
        // that the metadata for this tokenId needs to be re-fetched/re-generated.
        emit SoulboundAuraUpdated(_owner, _domainId, tokenId);
    }

    function getSBA_TokenId(address _owner, uint256 _domainId) public view returns (uint256) {
        uint256 tokenId = _sbaTokenIds[_owner][_domainId];
        if (tokenId == 0) { // A tokenId of 0 means it doesn't exist for this user/domain
            revert SBANotFound();
        }
        return tokenId;
    }

    // --- V. Reputation System ---

    function _updateReputation(address _user, uint256 _domainId, int256 _amount) internal {
        uint256 currentRep = domainReputation[_user][_domainId];
        uint256 newRep;

        if (_amount > 0) {
            newRep = currentRep + uint256(_amount);
        } else {
            uint256 absAmount = uint256(-_amount);
            if (currentRep < absAmount) {
                newRep = 0; // Reputation cannot go below zero
            } else {
                newRep = currentRep - absAmount;
            }
        }
        domainReputation[_user][_domainId] = newRep;
        emit ReputationUpdated(_user, _domainId, newRep);
    }

    function getDomainReputation(address _user, uint256 _domainId) public view returns (uint256) {
        return domainReputation[_user][_domainId];
    }

    function getTotalReputation(address _user) public view returns (uint256) {
        uint256 total = 0;
        // NOTE: This loop can be gas-intensive if many domains exist.
        // For very large numbers of domains, consider an explicit totalReputation mapping
        // updated within _updateReputation, or use an off-chain calculation for totals.
        for (uint256 i = 0; i < domainIdList.length; i++) {
            total += domainReputation[_user][domainIdList[i]];
        }
        return total;
    }

    function decayReputation(address _user) public whenNotPaused {
        uint256 lastDecay = lastReputationDecay[_user];
        if (lastDecay == 0) { // First time user, initialize lastDecay
            lastReputationDecay[_user] = block.timestamp;
            return;
        }

        uint256 intervalsPassed = (block.timestamp - lastDecay) / reputationDecayInterval;
        if (intervalsPassed == 0) return; // Not enough time has passed for decay

        // Update last decay timestamp to account for passed intervals
        lastRepayReputationDecay[_user] = lastDecay + (intervalsPassed * reputationDecayInterval);

        for (uint256 i = 0; i < domainIdList.length; i++) {
            uint256 domainId = domainIdList[i];
            uint256 currentRep = domainReputation[_user][domainId];
            if (currentRep > 0) {
                uint256 newRep = currentRep;
                for (uint256 j = 0; j < intervalsPassed; j++) {
                    newRep = newRep * (10000 - reputationDecayRate) / 10000; // rate is in basis points
                }

                // Prevent dust reputation remaining (e.g., if newRep becomes 1, it might as well be 0)
                if (newRep < 10 && currentRep >= 10) newRep = 0;

                if (newRep != currentRep) {
                    domainReputation[_user][domainId] = newRep;
                    emit ReputationDecayed(_user, currentRep, newRep);
                    // If reputation drops below SBA threshold, signal metadata update
                    if (isSoulboundAuraActive(_user, domainId) && newRep < domains[domainId].minReputationForSBA) {
                         _updateSoulboundAura(_user, domainId);
                    }
                }
            }
        }
    }

    function revokeReputation(address _user, uint256 _domainId, uint256 _amount) public onlyOwner {
        if (_amount == 0) return;

        // Option to revoke from all domains or a specific one
        if (_domainId == 0) { // Revoke from all domains
            for (uint256 i = 0; i < domainIdList.length; i++) {
                uint256 domainIdIter = domainIdList[i];
                uint256 currentRep = domainReputation[_user][domainIdIter];
                uint256 newRep = currentRep > _amount ? currentRep - _amount : 0;
                domainReputation[_user][domainIdIter] = newRep;
                emit ReputationRevoked(_user, domainIdIter, _amount);
                if (isSoulboundAuraActive(_user, domainIdIter) && newRep < domains[domainIdIter].minReputationForSBA) {
                    _updateSoulboundAura(_user, domainIdIter);
                }
            }
        } else { // Revoke from specific domain
            if (!domains[_domainId].isActive) revert InvalidDomain();
            uint256 currentRep = domainReputation[_user][_domainId];
            uint256 newRep = currentRep > _amount ? currentRep - _amount : 0;
            domainReputation[_user][_domainId] = newRep;
            emit ReputationRevoked(_user, _domainId, _amount);
            if (isSoulboundAuraActive(_user, _domainId) && newRep < domains[_domainId].minReputationForSBA) {
                _updateSoulboundAura(_user, _domainId);
            }
        }
    }

    // Internal helper to mint or update SBA based on reputation threshold
    function _mintOrUpdateSoulboundAura(address _user, uint256 _domainId) internal {
        if (domainReputation[_user][_domainId] >= domains[_domainId].minReputationForSBA) {
            if (!isSoulboundAuraActive(_user, _domainId)) {
                _mintSoulboundAura(_user, _domainId);
            } else { // SBA exists, update its properties
                _updateSoulboundAura(_user, _domainId);
            }
        }
    }

    // --- VI. Governance (Simplified) ---

    function submitGovernanceProposal(
        string memory _description,
        bytes memory _calldata,
        address _targetContract
    ) public whenNotPaused returns (uint256) {
        if (getTotalReputation(msg.sender) < minTotalReputationToPropose) {
            revert InsufficientReputationToPropose(getTotalReputation(msg.sender), minTotalReputationToPropose);
        }
        if (_calldata.length == 0 || _targetContract == address(0)) revert InvalidCalldataOrTarget();

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();
        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            calldataPayload: _calldata,
            targetContract: _targetContract,
            submittedAt: block.timestamp,
            votingEndsAt: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            minTotalReputationRequired: minTotalReputationToPropose, // Snapshot the current min rep
            status: ProposalStatus.Active,
            executed: false
        });
        emit ProposalSubmitted(newProposalId, msg.sender, _description);
        return newProposalId;
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();
        if (block.timestamp > proposal.votingEndsAt) revert ProposalNotActive(); // Voting period ended
        if (proposalVotes[_proposalId][msg.sender]) revert AlreadyVoted();
        if (getTotalReputation(msg.sender) < proposal.minTotalReputationRequired) {
            revert InsufficientReputationToVote(getTotalReputation(msg.sender), proposal.minTotalReputationRequired);
        }

        proposalVotes[_proposalId][msg.sender] = true;
        if (_support) {
            proposal.votesFor += getTotalReputation(msg.sender); // Reputation-weighted vote
        } else {
            proposal.votesAgainst += getTotalReputation(msg.sender);
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp <= proposal.votingEndsAt) revert ProposalVotingPeriodActive();

        // Determine if proposal passed (e.g., simple majority of total reputation votes)
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Succeeded;
            // Execute the payload via low-level call
            (bool success, bytes memory returndata) = proposal.targetContract.call(proposal.calldataPayload);
            require(success, string(abi.encodePacked("Proposal execution failed: ", returndata)));
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    // --- VII. Read Functions & Utilities ---

    function getInsightDetails(
        uint256 _insightId
    ) public view returns (uint256 id, uint256 domainId, address submitter, bytes32 insightHash, string memory metadataURI, uint256 submittedAt, InsightStatus status, bool oracleVerdict, uint256 challengeId) {
        Insight storage insight = insights[_insightId];
        if (insight.id == 0) { // Return empty/default values if not found, rather than reverting for views
            return (0,0,address(0),0x0,"",0,InsightStatus.AwaitingOracle,false,0);
        }
        return (insight.id, insight.domainId, insight.submitter, insight.insightHash, insight.metadataURI, insight.submittedAt, insight.status, insight.oracleVerdict, insight.challengeId);
    }

    function getChallengeDetails(
        uint256 _challengeId
    ) public view returns (uint256 id, uint256 insightId, address challenger, uint256 challengedAt, bool oracleVerdictConfirmed, bool resolved) {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) {
            return (0,0,address(0),0,false,false);
        }
        return (challenge.id, challenge.insightId, challenge.challenger, challenge.challengedAt, challenge.oracleVerdictConfirmed, challenge.resolved);
    }

    function getProposalDetails(
        uint256 _proposalId
    ) public view returns (uint256 id, address proposer, string memory description, address targetContract, uint256 submittedAt, uint256 votingEndsAt, uint256 votesFor, uint256 votesAgainst, uint256 minReputationRequired, ProposalStatus status, bool executed) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) {
            return (0,address(0),"","",address(0),0,0,0,0,ProposalStatus.Pending,false);
        }
        return (proposal.id, proposal.proposer, proposal.description, proposal.targetContract, proposal.submittedAt, proposal.votingEndsAt, proposal.votesFor, proposal.votesAgainst, proposal.minTotalReputationRequired, proposal.status, proposal.executed);
    }

    function getDomainIds() public view returns (uint256[] memory) {
        return domainIdList;
    }

    function isSoulboundAuraActive(address _user, uint256 _domainId) public view returns (bool) {
        // Construct the potential tokenId. If _sbaOwners[tokenId] is not address(0), it exists.
        uint256 potentialTokenId = ( _domainId << 160 ) | uint256(uint160(_user));
        return _sbaOwners[potentialTokenId] != address(0);
    }

    function getPendingInsightsCount() public view returns (uint256) {
        uint256 count = 0;
        // This loop can be gas-intensive if _insightIds.current() is very large.
        // For very high-throughput systems, consider maintaining this count via a dedicated counter
        // updated during status changes, or use off-chain indexing.
        for (uint256 i = 1; i <= _insightIds.current(); i++) {
            if (insights[i].status == InsightStatus.AwaitingOracle || insights[i].status == InsightStatus.OracleVerdict || insights[i].status == InsightStatus.Challenged) {
                count++;
            }
        }
        return count;
    }
}
```