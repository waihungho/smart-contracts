```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safe math

// --- INTERFACES ---
interface IAetherToken is IERC20 {
    // Custom functions for staking/governance might be here, but for basic interaction, IERC20 is enough.
}

interface IAIOracle {
    // A placeholder for an AI Oracle contract interface.
    // In a real scenario, this would likely be Chainlink Functions, Verifiable Random Function,
    // or a custom oracle network.
    // For this example, fulfillAIEnhancement is called directly by a whitelisted AI_ORACLE_ROLE.
    function requestEnhancement(uint256 paramId, bytes memory data) external returns (bytes32 requestId);
}

// --- OUTLINE ---
// Aetheria Nexus: The Decentralized Creative Commons & AI-Enhanced Generative Asset Protocol
// Purpose: A decentralized protocol for collaborative, AI-enhanced generative content creation and NFT issuance.
// Users submit "genesis parameters" (creative seeds), which can be refined by AI oracles and curated by elected community members.
// The resulting unique generative assets are minted as NFTs, with a dynamic royalty distribution system and a creator reputation mechanism.

// --- FUNCTION SUMMARY (28 functions) ---

// I. Core Generative Protocol (7 functions)
// 1.  submitGenesisParameters(string _parameterDataURI): Allows users to submit a new set of creative genesis parameters.
// 2.  getGenesisParameter(uint256 _paramId): Retrieves details for a specific genesis parameter set.
// 3.  voteOnGenesisParameterQuality(uint256 _paramId, bool _isUpvote): Allows users to upvote or downvote the quality of a genesis parameter set.
// 4.  requestAIEnhancement(uint256 _paramId, bytes _oracleData): Initiates a request to an AI Oracle to enhance or refine parameters.
// 5.  fulfillAIEnhancement(uint256 _paramId, string _refinedParameterURI, address _oracleAddress, bytes32 _requestId): Callback from AI Oracle for refined parameters.
// 6.  mintGenerativeAssetNFT(uint256 _paramId, string _tokenURI): Mints a new NFT from an approved and/or AI-enhanced genesis parameter set.
// 7.  updateGenerativeAssetNFTURI(uint256 _tokenId, string _newTokenURI): Allows an NFT's URI to be updated if its underlying genesis parameters are further refined.

// II. Reputation & Curator System (6 functions)
// 8.  registerCreatorProfile(): Creates a creator profile for the caller.
// 9.  getCreatorReputation(address _creator): Returns the current reputation score of a specific creator.
// 10. nominateCuratorCandidate(address _candidate): Allows any token holder to nominate a curator candidate.
// 11. voteForCuratorCandidate(address _candidate, uint256 _weight): Allows token holders to vote for a candidate with a specific weight.
// 12. electCurators(): Elects a new set of active curators based on the highest votes.
// 13. curatorApproveGenesisParameters(uint256 _paramId): Allows an active curator to officially "approve" a genesis parameter set.

// III. Staking & Engagement (3 functions)
// 14. stakeForParameterBoost(uint256 _paramId, uint256 _amount): Allows users to stake tokens on a genesis parameter set to boost its visibility and priority.
// 15. unstakeParameterBoost(uint256 _paramId, uint256 _amount): Allows users to unstake tokens from a boosted genesis parameter.
// 16. claimStakingRewards(): Allows stakers to claim their proportional share from the general staker reward pool.

// IV. Royalty & Revenue Distribution (4 functions)
// 17. setRoyaltyRates(uint256 _creatorShare, uint256 _aiOracleShare, uint256 _curatorShare, uint256 _protocolShare): (Governance) Sets the percentage distribution of NFT royalties.
// 18. distributeNFTProceeds(uint256 _tokenId, uint256 _totalSaleAmount): Triggers royalty distribution upon an NFT sale.
// 19. claimParticipantRevenue(address _participant): Allows creators, AI Oracles, or curators to claim their accumulated royalty shares.
// 20. claimProtocolTreasuryFunds(): Allows the protocol's treasury to claim its accumulated share of fees.

// V. Governance & Configuration (4 functions)
// 21. proposeProtocolParameterChange(bytes _callData, string _description): Allows token holders to propose changes to protocol-wide parameters.
// 22. voteOnProposal(uint256 _proposalId): Allows token holders to vote on an active governance proposal.
// 23. executeProposal(uint256 _proposalId): Executes a successfully voted-on governance proposal.
// 24. setAIOracleAddress(address _newOracle): Allows governance to manage whitelisted AI Oracle addresses.

// VI. Utility & Read Functions (4 functions)
// 25. getTotalGenesisParameterSets(): Returns the total number of genesis parameter sets submitted.
// 26. getTopNGenesisParameters(uint256 _n): Returns a list of the top N genesis parameter IDs based on a weighted score.
// 27. getCuratorList(): Returns an array of addresses of currently active curators.
// 28. getVotePower(address _voter): Returns the current voting power (AetherToken balance) of an address.

contract AetheriaNexus is ERC721, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- ROLES ---
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE"); // Role for whitelisted AI oracle addresses

    // --- STATE VARIABLES ---

    // Generative Parameters
    struct GenesisParameterSet {
        address creator;
        string parameterDataURI; // IPFS hash or similar for the base generative parameters
        string refinedParameterURI; // IPFS hash for AI-enhanced parameters (if applicable)
        uint256 upvotes;
        uint256 downvotes;
        bool isApprovedByCurator;
        bool isAIEnhanced;
        uint256 stakedBoostAmount; // AetherToken amount staked for visibility boost on this specific parameter
        uint256 createdAt;
        uint256 lastAIRequestAt; // Timestamp of the last AI enhancement request
        address lastAIOracle; // Address of the AI oracle that last enhanced this param set
        bytes32 currentAIRequestId; // ID of the pending AI request
        uint256 lastNFTMintedAt; // Timestamp of the last NFT minted from this param set
    }
    Counters.Counter private _genesisParamIds;
    mapping(uint255 => GenesisParameterSet) public genesisParameters;
    mapping(bytes32 => uint256) public aiRequestIdToParamId; // Map AI request ID to param ID

    // NFT Management
    mapping(uint256 => uint256) public nftToGenesisParamId; // Links an NFT tokenId back to its genesis param ID
    mapping(uint256 => address) public nftToCreator; // Stores the original creator of the NFT's genesis params
    mapping(uint256 => address) public nftToAIOracle; // Stores the AI oracle address that enhanced the param set for this NFT

    // Creator Reputation
    struct CreatorProfile {
        bool exists;
        int256 reputationScore; // Can be positive or negative
        uint256 totalSubmittedParams;
        uint256 totalNFTsMinted;
    }
    mapping(address => CreatorProfile) public creatorProfiles;

    // Curator System
    mapping(address => uint256) public curatorCandidateVotes; // Address => AetherToken amount
    mapping(address => bool) public isCuratorCandidate;
    address[] private _allCuratorCandidates; // Array to explicitly track all nominated candidates for iteration
    address[] public activeCurators;
    uint256 public curatorElectionPeriod = 7 days; // How often elections happen
    uint256 public lastCuratorElectionTimestamp;
    uint256 public constant MAX_CURATORS = 5; // Max number of active curators

    // Staking for Parameter Boost & Rewards
    IAetherToken public aetherToken; // The ERC20 token used for staking and governance
    mapping(address => mapping(uint256 => uint256)) public userStakedBoosts; // user => paramId => amount
    mapping(address => uint256) public userTotalStaked; // Total amount staked by a user across all parameters
    uint256 public totalStakedBoostAmount; // Sum of all GenesisParameterSet.stakedBoostAmount across all parameters
    uint256 public stakerRewardPool; // Accumulated AetherToken for stakers from protocol fees

    // Royalty & Revenue Distribution
    uint256 public creatorRoyaltyShare; // Basis points (e.g., 4000 for 40%)
    uint256 public aiOracleRoyaltyShare;
    uint256 public curatorRoyaltyShare;
    uint256 public protocolRoyaltyShare;
    uint256 public constant TOTAL_ROYALTY_BASIS_POINTS = 10000; // 100%

    mapping(address => uint256) public pendingParticipantRevenue; // For creators, oracles, active curators (direct share)
    uint256 public protocolTreasuryBalance; // Remaining protocol fees

    // Governance
    struct Proposal {
        uint256 id;
        string description;
        bytes callData; // Encoded function call to execute
        address target; // Address of the contract to call (e.g., AetheriaNexus itself)
        uint256 voteCount;
        mapping(address => bool) hasVoted; // User has voted on this proposal
        bool executed;
        uint256 creationBlock;
        uint256 deadlineBlock;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public minVotePowerForProposal; // Min AetherToken needed to create a proposal
    uint256 public votingPeriodBlocks; // How many blocks a proposal is open for voting

    // --- EVENTS ---
    event GenesisParametersSubmitted(uint256 indexed paramId, address indexed creator, string parameterDataURI);
    event GenesisParametersVoted(uint256 indexed paramId, address indexed voter, bool isUpvote, int256 newReputation);
    event AIEnhancementRequested(uint256 indexed paramId, bytes32 indexed requestId, address indexed oracleAddress);
    event AIEnhancementFulfilled(uint256 indexed paramId, string refinedParameterURI, address indexed oracleAddress);
    event GenerativeAssetMinted(uint256 indexed tokenId, uint256 indexed paramId, address indexed owner, string tokenURI);
    event GenerativeAssetURIUpdate(uint256 indexed tokenId, string newTokenURI);

    event CreatorProfileRegistered(address indexed creator);
    event CuratorCandidateNominated(address indexed candidate);
    event CuratorVoteCast(address indexed voter, address indexed candidate, uint256 weight);
    event CuratorsElected(address[] newCurators);
    event GenesisParametersApprovedByCurator(uint256 indexed paramId, address indexed curator);

    event ParameterBoostStaked(uint256 indexed paramId, address indexed staker, uint256 amount);
    event ParameterBoostUnstaked(uint256 indexed paramId, address indexed staker, uint256 amount);
    event StakingRewardsClaimed(address indexed staker, uint256 amount);

    event RoyaltyRatesUpdated(uint256 creatorShare, uint256 aiOracleShare, uint256 curatorShare, uint256 protocolShare);
    event NFTProceedsDistributed(uint256 indexed tokenId, uint256 totalSaleAmount);
    event ParticipantRevenueClaimed(address indexed participant, uint256 amount);
    event ProtocolTreasuryClaimed(uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);
    event AIOracleAddressSet(address indexed newOracle);


    // --- CONSTRUCTOR ---
    constructor(
        address _aetherTokenAddress,
        address _initialGovernance,
        address _initialAIOracle,
        uint256 _minVotePowerForProposal,
        uint256 _votingPeriodBlocks
    ) ERC721("AetheriaNexusGenerativeAsset", "ANGA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        _grantRole(GOVERNANCE_ROLE, _initialGovernance); // Initial governance
        _grantRole(AI_ORACLE_ROLE, _initialAIOracle); // Initial AI oracle

        aetherToken = IAetherToken(_aetherTokenAddress);
        minVotePowerForProposal = _minVotePowerForProposal;
        votingPeriodBlocks = _votingPeriodBlocks;

        // Default royalty rates (can be changed by governance)
        creatorRoyaltyShare = 4000; // 40%
        aiOracleRoyaltyShare = 1500; // 15%
        curatorRoyaltyShare = 1500; // 15%
        protocolRoyaltyShare = 3000; // 30%

        require(creatorRoyaltyShare.add(aiOracleRoyaltyShare).add(curatorRoyaltyShare).add(protocolRoyaltyShare) == TOTAL_ROYALTY_BASIS_POINTS, "Invalid initial royalty shares");
    }

    // --- MODIFIERS ---
    modifier onlyCurator() {
        require(hasRole(CURATOR_ROLE, _msgSender()), "AetheriaNexus: Caller is not a curator");
        _;
    }

    modifier onlyAIOracle() {
        require(hasRole(AI_ORACLE_ROLE, _msgSender()), "AetheriaNexus: Caller is not an AI oracle");
        _;
    }

    // --- I. Core Generative Protocol ---

    // 1. submitGenesisParameters
    function submitGenesisParameters(string memory _parameterDataURI) public {
        _genesisParamIds.increment();
        uint256 newId = _genesisParamIds.current();

        genesisParameters[newId] = GenesisParameterSet({
            creator: msg.sender,
            parameterDataURI: _parameterDataURI,
            refinedParameterURI: "",
            upvotes: 0,
            downvotes: 0,
            isApprovedByCurator: false,
            isAIEnhanced: false,
            stakedBoostAmount: 0,
            createdAt: block.timestamp,
            lastAIRequestAt: 0,
            lastAIOracle: address(0),
            currentAIRequestId: bytes32(0),
            lastNFTMintedAt: 0
        });

        // Ensure creator profile exists
        if (!creatorProfiles[msg.sender].exists) {
            _registerCreatorProfile(msg.sender);
        }
        creatorProfiles[msg.sender].totalSubmittedParams = creatorProfiles[msg.sender].totalSubmittedParams.add(1);

        emit GenesisParametersSubmitted(newId, msg.sender, _parameterDataURI);
    }

    // 2. getGenesisParameter
    function getGenesisParameter(uint256 _paramId) public view returns (GenesisParameterSet memory) {
        require(_paramId > 0 && _paramId <= _genesisParamIds.current(), "GenesisParameters: Invalid parameter ID");
        return genesisParameters[_paramId];
    }

    // 3. voteOnGenesisParameterQuality
    function voteOnGenesisParameterQuality(uint256 _paramId, bool _isUpvote) public {
        require(_paramId > 0 && _paramId <= _genesisParamIds.current(), "GenesisParameters: Invalid parameter ID");
        GenesisParameterSet storage param = genesisParameters[_paramId];
        require(param.creator != address(0), "GenesisParameters: Parameter does not exist");
        require(msg.sender != param.creator, "GenesisParameters: Creator cannot vote on their own parameters");

        // Ensure creator profile exists for potential impact on reputation
        if (!creatorProfiles[param.creator].exists) {
            _registerCreatorProfile(param.creator);
        }

        // Basic voting, could be enhanced with token-weighted voting or cooldowns
        if (_isUpvote) {
            param.upvotes = param.upvotes.add(1);
            creatorProfiles[param.creator].reputationScore = creatorProfiles[param.creator].reputationScore.add(1); // Increase creator reputation
        } else {
            param.downvotes = param.downvotes.add(1);
            creatorProfiles[param.creator].reputationScore = creatorProfiles[param.creator].reputationScore.sub(1); // Decrease creator reputation
        }
        
        emit GenesisParametersVoted(_paramId, msg.sender, _isUpvote, creatorProfiles[param.creator].reputationScore);
    }

    // 4. requestAIEnhancement
    function requestAIEnhancement(uint256 _paramId, bytes memory _oracleData) public {
        require(_paramId > 0 && _paramId <= _genesisParamIds.current(), "GenesisParameters: Invalid parameter ID");
        GenesisParameterSet storage param = genesisParameters[_paramId];
        require(param.creator != address(0), "GenesisParameters: Parameter does not exist");
        require(!param.isAIEnhanced || block.timestamp > param.lastAIRequestAt + 1 days, "GenesisParameters: Can only request AI enhancement once per day for an already enhanced set."); // Cooldown

        address oracleToUse = address(0); // Placeholder, a real system would select an active oracle from a list
        bytes32 requestId = keccak256(abi.encodePacked(_paramId, block.timestamp, _oracleData)); // Simulate a request ID

        // For this example, we'll assign a dummy oracle address.
        // In a real system, `IAIOracle(address).requestEnhancement(...)` would be called.
        // We'll require `AI_ORACLE_ROLE` to make this call to ensure it's from a legitimate oracle,
        // but for a user-initiated request, the oracle contract would be called directly.
        // Let's assume a default oracle for simplicity, or it's implicitly part of the role.
        
        // For demonstration, let's allow any whitelisted AI oracle to pick up the request or governance to set a primary one.
        // For now, `param.lastAIOracle` will be set to `address(0)` to signify pending, and `fulfillAIEnhancement` sets it.

        param.lastAIRequestAt = block.timestamp;
        param.currentAIRequestId = requestId;
        aiRequestIdToParamId[requestId] = _paramId;

        emit AIEnhancementRequested(_paramId, requestId, oracleToUse); // oracleToUse will be address(0) initially
    }

    // 5. fulfillAIEnhancement - Called by a whitelisted AI Oracle
    function fulfillAIEnhancement(uint256 _paramId, string memory _refinedParameterURI, address _oracleAddress, bytes32 _requestId) public onlyAIOracle {
        require(_paramId > 0 && _paramId <= _genesisParamIds.current(), "GenesisParameters: Invalid parameter ID");
        GenesisParameterSet storage param = genesisParameters[_paramId];
        require(param.creator != address(0), "GenesisParameters: Parameter does not exist");
        require(param.currentAIRequestId == _requestId, "AIEnhancement: Request ID mismatch or no pending request");
        require(bytes(_refinedParameterURI).length > 0, "AIEnhancement: Refined URI cannot be empty");

        param.refinedParameterURI = _refinedParameterURI;
        param.isAIEnhanced = true;
        param.lastAIOracle = _oracleAddress; // Confirm the oracle that fulfilled it
        param.currentAIRequestId = bytes32(0); // Clear request

        emit AIEnhancementFulfilled(_paramId, _refinedParameterURI, _oracleAddress);
    }

    // 6. mintGenerativeAssetNFT
    function mintGenerativeAssetNFT(uint256 _paramId, string memory _tokenURI) public nonReentrant {
        require(_paramId > 0 && _paramId <= _genesisParamIds.current(), "GenesisParameters: Invalid parameter ID");
        GenesisParameterSet storage param = genesisParameters[_paramId];
        require(param.creator != address(0), "GenesisParameters: Parameter does not exist");
        require(param.isApprovedByCurator || param.isAIEnhanced, "NFTMint: Parameter must be approved by curator OR AI-enhanced to mint an NFT.");
        require(bytes(_tokenURI).length > 0, "NFTMint: Token URI cannot be empty");

        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _mint(msg.sender, newId);
        _setTokenURI(newId, _tokenURI);

        nftToGenesisParamId[newId] = _paramId;
        nftToCreator[newId] = param.creator;
        if (param.isAIEnhanced) {
            nftToAIOracle[newId] = param.lastAIOracle;
        }

        param.lastNFTMintedAt = block.timestamp;

        // Update creator profile
        if (!creatorProfiles[param.creator].exists) {
            _registerCreatorProfile(param.creator);
        }
        creatorProfiles[param.creator].totalNFTsMinted = creatorProfiles[param.creator].totalNFTsMinted.add(1);

        emit GenerativeAssetMinted(newId, _paramId, msg.sender, _tokenURI);
    }

    // 7. updateGenerativeAssetNFTURI - Allows the NFT to evolve based on further parameter refinements
    function updateGenerativeAssetNFTURI(uint256 _tokenId, string memory _newTokenURI) public {
        require(_exists(_tokenId), "ERC721: token not minted");
        require(ownerOf(_tokenId) == msg.sender || hasRole(GOVERNANCE_ROLE, _msgSender()), "ERC721: caller is not owner or governance");
        require(bytes(_newTokenURI).length > 0, "NFTUpdate: New token URI cannot be empty");

        // Optional: Add logic to ensure the new URI is related to a further refined genesis param if desired
        // E.g., check if the paramId associated with _tokenId has a newer refinedParameterURI
        // For simplicity, we allow owner/governance to update for dynamic metadata possibilities.

        _setTokenURI(_tokenId, _newTokenURI);
        emit GenerativeAssetURIUpdate(_tokenId, _newTokenURI);
    }

    // --- II. Reputation & Curator System ---

    // Internal helper for creator profile registration
    function _registerCreatorProfile(address _creator) internal {
        require(!creatorProfiles[_creator].exists, "CreatorProfile: Profile already exists");
        creatorProfiles[_creator] = CreatorProfile({
            exists: true,
            reputationScore: 0,
            totalSubmittedParams: 0,
            totalNFTsMinted: 0
        });
        emit CreatorProfileRegistered(_creator);
    }

    // 8. registerCreatorProfile
    function registerCreatorProfile() public {
        _registerCreatorProfile(msg.sender);
    }

    // 9. getCreatorReputation
    function getCreatorReputation(address _creator) public view returns (int256) {
        return creatorProfiles[_creator].reputationScore;
    }

    // 10. nominateCuratorCandidate
    function nominateCuratorCandidate(address _candidate) public {
        require(_candidate != address(0), "Curator: Invalid candidate address");
        require(!isCuratorCandidate[_candidate], "Curator: Already a candidate");
        require(!hasRole(CURATOR_ROLE, _candidate), "Curator: Address is already an active curator");

        isCuratorCandidate[_candidate] = true;
        _allCuratorCandidates.push(_candidate); // Add to the array for iteration during election
        emit CuratorCandidateNominated(_candidate);
    }

    // 11. voteForCuratorCandidate - Token-weighted voting
    function voteForCuratorCandidate(address _candidate, uint256 _weight) public {
        require(isCuratorCandidate[_candidate], "Curator: Not a candidate");
        require(_weight > 0, "Curator: Vote weight must be positive");
        require(aetherToken.balanceOf(msg.sender) >= _weight, "Curator: Insufficient AetherToken balance");
        // For simplicity, we use current balance as vote weight here.
        // A more advanced system would use `delegate` pattern or snapshot voting (e.g., ERC20Votes).

        curatorCandidateVotes[_candidate] = curatorCandidateVotes[_candidate].add(_weight); // Accumulate votes based on token balance/power
        emit CuratorVoteCast(msg.sender, _candidate, _weight);
    }

    // 12. electCurators - Called by governance or periodically
    function electCurators() public hasRole(GOVERNANCE_ROLE, _msgSender()) {
        require(block.timestamp >= lastCuratorElectionTimestamp.add(curatorElectionPeriod), "Curator: Not yet time for a new election");

        // Revoke existing CURATOR_ROLE from active curators
        for (uint256 i = 0; i < activeCurators.length; i++) {
            _revokeRole(CURATOR_ROLE, activeCurators[i]);
        }
        activeCurators = new address[](0); // Clear active curators

        // Collect candidates who received votes in this period
        struct Candidate {
            address addr;
            uint256 votes;
        }
        Candidate[] memory currentElectionCandidates = new Candidate[](_allCuratorCandidates.length);
        uint256 actualCandidateCount = 0;

        for (uint i = 0; i < _allCuratorCandidates.length; i++) {
            address candidateAddr = _allCuratorCandidates[i];
            if (curatorCandidateVotes[candidateAddr] > 0) {
                currentElectionCandidates[actualCandidateCount] = Candidate({
                    addr: candidateAddr,
                    votes: curatorCandidateVotes[candidateAddr]
                });
                actualCandidateCount = actualCandidateCount.add(1);
            }
        }
        
        // Resize array to actual candidates
        Candidate[] memory finalCandidates = new Candidate[](actualCandidateCount);
        for(uint i=0; i < actualCandidateCount; i++) {
            finalCandidates[i] = currentElectionCandidates[i];
        }

        // Sort candidates by votes (descending) - Bubble sort for small arrays
        // Note: Bubble sort is O(N^2) and becomes very expensive for large N.
        // For a very large number of candidates, an off-chain sorting solution with Merkle proof,
        // or a more efficient on-chain algorithm (if gas allows) would be needed.
        for (uint i = 0; i < finalCandidates.length; i++) {
            for (uint j = i.add(1); j < finalCandidates.length; j++) {
                if (finalCandidates[i].votes < finalCandidates[j].votes) {
                    Candidate memory temp = finalCandidates[i];
                    finalCandidates[i] = finalCandidates[j];
                    finalCandidates[j] = temp;
                }
            }
        }

        // Elect top MAX_CURATORS
        for (uint i = 0; i < finalCandidates.length && i < MAX_CURATORS; i++) {
            _grantRole(CURATOR_ROLE, finalCandidates[i].addr);
            activeCurators.push(finalCandidates[i].addr);
        }

        lastCuratorElectionTimestamp = block.timestamp;
        
        // Clear candidate votes and status for next election
        for (uint i = 0; i < _allCuratorCandidates.length; i++) {
            address candidateAddr = _allCuratorCandidates[i];
            curatorCandidateVotes[candidateAddr] = 0;
            isCuratorCandidate[candidateAddr] = false;
        }
        _allCuratorCandidates = new address[](0); // Clear the list of all candidates

        emit CuratorsElected(activeCurators);
    }

    // 13. curatorApproveGenesisParameters
    function curatorApproveGenesisParameters(uint256 _paramId) public onlyCurator {
        require(_paramId > 0 && _paramId <= _genesisParamIds.current(), "GenesisParameters: Invalid parameter ID");
        GenesisParameterSet storage param = genesisParameters[_paramId];
        require(param.creator != address(0), "GenesisParameters: Parameter does not exist");
        require(!param.isApprovedByCurator, "GenesisParameters: Parameter already approved");

        param.isApprovedByCurator = true;
        // Optionally, increase curator's reputation or give a small reward
        emit GenesisParametersApprovedByCurator(_paramId, msg.sender);
    }

    // --- III. Staking & Engagement ---

    // 14. stakeForParameterBoost
    function stakeForParameterBoost(uint256 _paramId, uint256 _amount) public nonReentrant {
        require(_paramId > 0 && _paramId <= _genesisParamIds.current(), "GenesisParameters: Invalid parameter ID");
        require(_amount > 0, "Staking: Amount must be greater than zero");
        GenesisParameterSet storage param = genesisParameters[_paramId];
        require(param.creator != address(0), "GenesisParameters: Parameter does not exist");

        aetherToken.transferFrom(msg.sender, address(this), _amount);
        param.stakedBoostAmount = param.stakedBoostAmount.add(_amount);
        userStakedBoosts[msg.sender][_paramId] = userStakedBoosts[msg.sender][_paramId].add(_amount);
        userTotalStaked[msg.sender] = userTotalStaked[msg.sender].add(_amount);
        totalStakedBoostAmount = totalStakedBoostAmount.add(_amount);

        emit ParameterBoostStaked(_paramId, msg.sender, _amount);
    }

    // 15. unstakeParameterBoost
    function unstakeParameterBoost(uint256 _paramId, uint256 _amount) public nonReentrant {
        require(_paramId > 0 && _paramId <= _genesisParamIds.current(), "GenesisParameters: Invalid parameter ID");
        require(_amount > 0, "Staking: Amount must be greater than zero");
        GenesisParameterSet storage param = genesisParameters[_paramId];
        require(param.creator != address(0), "GenesisParameters: Parameter does not exist");
        require(userStakedBoosts[msg.sender][_paramId] >= _amount, "Staking: Insufficient staked amount for this parameter");

        param.stakedBoostAmount = param.stakedBoostAmount.sub(_amount);
        userStakedBoosts[msg.sender][_paramId] = userStakedBoosts[msg.sender][_paramId].sub(_amount);
        userTotalStaked[msg.sender] = userTotalStaked[msg.sender].sub(_amount);
        totalStakedBoostAmount = totalStakedBoostAmount.sub(_amount);
        aetherToken.transfer(msg.sender, _amount);

        emit ParameterBoostUnstaked(_paramId, msg.sender, _amount);
    }

    // 16. claimStakingRewards (Proportional claim from global pool based on current total stake)
    // Note: This model means early claimants might get a higher proportion if totalStakedBoostAmount increases significantly later.
    // For a more sophisticated model, epoch-based rewards or Merkle proofs are typically used.
    function claimStakingRewards() public nonReentrant {
        require(userTotalStaked[msg.sender] > 0, "Staking: No active stake found for this user.");
        require(stakerRewardPool > 0 && totalStakedBoostAmount > 0, "Staking: No rewards in the pool or no total staked amount.");

        uint256 claimableAmount = (stakerRewardPool.mul(userTotalStaked[msg.sender])).div(totalStakedBoostAmount);
        require(claimableAmount > 0, "Staking: No claimable rewards for this user at this moment.");
        
        stakerRewardPool = stakerRewardPool.sub(claimableAmount); // Reduce pool
        aetherToken.transfer(msg.sender, claimableAmount);
        emit StakingRewardsClaimed(msg.sender, claimableAmount);
    }

    // --- IV. Royalty & Revenue Distribution ---

    // 17. setRoyaltyRates
    function setRoyaltyRates(uint256 _creatorShare, uint256 _aiOracleShare, uint256 _curatorShare, uint256 _protocolShare) public hasRole(GOVERNANCE_ROLE, _msgSender()) {
        require(_creatorShare.add(_aiOracleShare).add(_curatorShare).add(_protocolShare) == TOTAL_ROYALTY_BASIS_POINTS, "Royalty: Shares must sum to 100%");
        creatorRoyaltyShare = _creatorShare;
        aiOracleRoyaltyShare = _aiOracleShare;
        curatorRoyaltyShare = _curatorShare;
        protocolRoyaltyShare = _protocolShare;
        emit RoyaltyRatesUpdated(_creatorShare, _aiOracleShare, _curatorShare, _protocolShare);
    }

    // 18. distributeNFTProceeds
    // Assumes an external marketplace calls this, or the contract itself if it handles sales.
    // _totalSaleAmount is the amount *before* distribution, often the full sale price.
    function distributeNFTProceeds(uint256 _tokenId, uint256 _totalSaleAmount) public nonReentrant {
        // Can be restricted to marketplaces or governance if desired. For now, public.
        require(_exists(_tokenId), "NFTProceeds: NFT does not exist");
        require(_totalSaleAmount > 0, "NFTProceeds: Sale amount must be positive");

        address originalCreator = nftToCreator[_tokenId];
        address aiOracle = nftToAIOracle[_tokenId]; // Will be address(0) if not AI-enhanced

        uint256 creatorAmount = _totalSaleAmount.mul(creatorRoyaltyShare).div(TOTAL_ROYALTY_BASIS_POINTS);
        uint256 aiOracleAmount = _totalSaleAmount.mul(aiOracleRoyaltyShare).div(TOTAL_ROYALTY_BASIS_POINTS);
        uint256 curatorAmount = _totalSaleAmount.mul(curatorRoyaltyShare).div(TOTAL_ROYALTY_BASIS_POINTS);
        uint256 protocolAmount = _totalSaleAmount.mul(protocolRoyaltyShare).div(TOTAL_ROYALTY_BASIS_POINTS);

        // Distribute to Creator
        if (creatorAmount > 0) {
            pendingParticipantRevenue[originalCreator] = pendingParticipantRevenue[originalCreator].add(creatorAmount);
        }

        // Distribute to AI Oracle (if applicable)
        if (aiOracleAmount > 0 && aiOracle != address(0)) {
            pendingParticipantRevenue[aiOracle] = pendingParticipantRevenue[aiOracle].add(aiOracleAmount);
        }

        // Distribute to Curators (share among active curators)
        if (curatorAmount > 0 && activeCurators.length > 0) {
            uint256 sharePerCurator = curatorAmount.div(activeCurators.length);
            for (uint256 i = 0; i < activeCurators.length; i++) {
                pendingParticipantRevenue[activeCurators[i]] = pendingParticipantRevenue[activeCurators[i]].add(sharePerCurator);
            }
        }
        
        // Split protocol amount between treasury and staker reward pool
        uint256 stakerShareFromProtocol = protocolAmount.mul(2500).div(TOTAL_ROYALTY_BASIS_POINTS); // 25% of protocol's share goes to staker pool
        stakerRewardPool = stakerRewardPool.add(stakerShareFromProtocol);
        protocolTreasuryBalance = protocolTreasuryBalance.add(protocolAmount).sub(stakerShareFromProtocol);

        emit NFTProceedsDistributed(_tokenId, _totalSaleAmount);
    }

    // 19. claimParticipantRevenue
    function claimParticipantRevenue(address _participant) public nonReentrant {
        require(_participant != address(0), "Claim: Invalid participant address");
        // Ensure participant has a recognized role (creator profile, AI oracle, or curator)
        require(creatorProfiles[_participant].exists || hasRole(AI_ORACLE_ROLE, _participant) || hasRole(CURATOR_ROLE, _participant), "Claim: Not a recognized revenue participant");

        uint256 amount = pendingParticipantRevenue[_participant];
        require(amount > 0, "Claim: No pending revenue for this participant");

        pendingParticipantRevenue[_participant] = 0;
        aetherToken.transfer(_participant, amount);
        
        emit ParticipantRevenueClaimed(_participant, amount);
    }
    
    // 20. claimProtocolTreasuryFunds
    function claimProtocolTreasuryFunds() public hasRole(GOVERNANCE_ROLE, _msgSender()) nonReentrant {
        uint256 amount = protocolTreasuryBalance;
        require(amount > 0, "Treasury: No funds to claim");

        protocolTreasuryBalance = 0;
        aetherToken.transfer(msg.sender, amount); // Transfers to the governance wallet
        
        emit ProtocolTreasuryClaimed(amount);
    }

    // --- V. Governance & Configuration ---

    // 21. proposeProtocolParameterChange
    function proposeProtocolParameterChange(bytes memory _callData, string memory _description) public {
        require(getVotePower(msg.sender) >= minVotePowerForProposal, "Governance: Insufficient vote power to propose");
        // A real system would use `aetherToken.getPastVotes(msg.sender, block.number - 1)` for snapshot voting.
        // For simplicity, current balance.

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            description: _description,
            callData: _callData,
            target: address(this), // Proposals target this contract itself
            voteCount: 0,
            executed: false,
            creationBlock: block.number,
            deadlineBlock: block.number.add(votingPeriodBlocks)
        });

        emit ProposalCreated(newProposalId, msg.sender, _description);
    }

    // 22. voteOnProposal
    function voteOnProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Governance: Proposal does not exist");
        require(!proposal.executed, "Governance: Proposal already executed");
        require(block.number <= proposal.deadlineBlock, "Governance: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Governance: Already voted on this proposal");

        uint256 votePower = getVotePower(msg.sender);
        require(votePower > 0, "Governance: No vote power");

        proposal.voteCount = proposal.voteCount.add(votePower);
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, votePower);
    }

    // 23. executeProposal
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Governance: Proposal does not exist");
        require(!proposal.executed, "Governance: Proposal already executed");
        require(block.number > proposal.deadlineBlock, "Governance: Voting period not ended");
        // Simple majority voting for now. Could be more complex (e.g., quorum, supermajority).
        require(proposal.voteCount > minVotePowerForProposal, "Governance: Proposal did not pass (insufficient votes)"); // Example threshold

        proposal.executed = true;

        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Governance: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    // 24. setAIOracleAddress - Allows governance to manage whitelisted AI Oracle addresses
    function setAIOracleAddress(address _newOracle) public hasRole(GOVERNANCE_ROLE, _msgSender()) {
        require(_newOracle != address(0), "AIOracle: Invalid address");
        _grantRole(AI_ORACLE_ROLE, _newOracle); // Grant the role
        // If specific oracle revocation is desired, implement _revokeRole for a specific old oracle.
        emit AIOracleAddressSet(_newOracle);
    }

    // --- VI. Utility & Read Functions ---

    // 25. getTotalGenesisParameterSets
    function getTotalGenesisParameterSets() public view returns (uint256) {
        return _genesisParamIds.current();
    }

    // 26. getTopNGenesisParameters (Simplified - real would need robust sorting logic)
    // Note: This is a computationally intensive task on-chain.
    // For a real contract with many parameters, this would typically be done off-chain by indexers.
    // For demonstration, we return a limited list based on a simple heuristic.
    function getTopNGenesisParameters(uint256 _n) public view returns (uint256[] memory) {
        uint256 totalParams = _genesisParamIds.current();
        if (totalParams == 0) {
            return new uint256[](0);
        }

        uint256[] memory topParamsIds = new uint256[](totalParams);
        for (uint256 i = 1; i <= totalParams; i = i.add(1)) {
            topParamsIds[i.sub(1)] = i;
        }

        // Simplistic bubble sort by a score: (upvotes - downvotes) + (isAIEnhanced ? 100 : 0) + (isApprovedByCurator ? 50 : 0) + (stakedBoostAmount / AetherToken.decimals)
        // This is highly inefficient for large `totalParams`. This function is illustrative.
        // For production, use off-chain indexing and filtering.
        uint256 aetherTokenDecimals = aetherToken.decimals();
        for (uint256 i = 0; i < totalParams; i = i.add(1)) {
            for (uint256 j = i.add(1); j < totalParams; j = j.add(1)) {
                GenesisParameterSet storage p1 = genesisParameters[topParamsIds[i]];
                GenesisParameterSet storage p2 = genesisParameters[topParamsIds[j]];

                int256 score1 = int256(p1.upvotes).sub(int256(p1.downvotes));
                if (p1.isAIEnhanced) score1 = score1.add(100);
                if (p1.isApprovedByCurator) score1 = score1.add(50);
                if (p1.stakedBoostAmount > 0) score1 = score1.add(int256(p1.stakedBoostAmount.div(10**aetherTokenDecimals))); // Add scaled boost

                int256 score2 = int256(p2.upvotes).sub(int256(p2.downvotes));
                if (p2.isAIEnhanced) score2 = score2.add(100);
                if (p2.isApprovedByCurator) score2 = score2.add(50);
                if (p2.stakedBoostAmount > 0) score2 = score2.add(int256(p2.stakedBoostAmount.div(10**aetherTokenDecimals))); // Add scaled boost

                if (score1 < score2) {
                    uint256 temp = topParamsIds[i];
                    topParamsIds[i] = topParamsIds[j];
                    topParamsIds[j] = temp;
                }
            }
        }

        uint256 returnSize = totalParams < _n ? totalParams : _n;
        uint256[] memory result = new uint256[](returnSize);
        for (uint256 i = 0; i < returnSize; i = i.add(1)) {
            result[i] = topParamsIds[i];
        }
        return result;
    }

    // 27. getCuratorList
    function getCuratorList() public view returns (address[] memory) {
        return activeCurators;
    }

    // 28. getVotePower
    function getVotePower(address _voter) public view returns (uint256) {
        return aetherToken.balanceOf(_voter); // Simplistic, for full governance use `getPastVotes` etc.
    }
}
```