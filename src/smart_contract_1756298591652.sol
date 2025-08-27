The "VeriFact Nexus" is a cutting-edge smart contract designed to create a decentralized ecosystem for collective intelligence and truth validation. It aims to establish a trusted, community-driven knowledge base by incentivizing accurate claims, robust challenges, and objective verification using a combination of human consensus, oracle integration, and an innovative reputation system.

---

### @outline

1.  **Core Claim Management**: Functionality for users to submit, challenge, and resolve "claims" about real-world events or facts, including time-locked resolution and multi-stakeholder participation.
2.  **Reputation System (VeriScore - SBT)**: A non-transferable, soulbound token (SBT) based score that measures a participant's credibility and accuracy within the Nexus, influencing voting power and rewards.
3.  **Dynamic Insight NFTs**: Evolving NFTs awarded to high-performing claim submitters and challengers, which can change in appearance/metadata based on continued accuracy or impact, potentially unlocking special bonuses.
4.  **Oracle & AI Integration (Conceptual)**: A framework for incorporating external data or AI model outputs (via registered oracles) to assist in the verification process for claims, especially objective or complex ones.
5.  **DAO Governance**: A decentralized autonomous organization (DAO) module enabling VeriScore holders to propose and vote on changes to platform parameters, elect Verifiers, and shape the future of the Nexus.
6.  **Platform Fees & Rewards**: Economic mechanisms to sustain the platform and incentivize honest participation through staking, fee collection, and prize distribution.

---

### @function_summary

**I. Core Claim Management (8 functions):**
*   `submitClaim(string, uint256, uint256, bytes32[])`: Creates a new claim with a staked amount, a resolution timestamp, and associated tags.
*   `challengeClaim(uint256, uint256, string)`: Allows users to challenge an existing claim, placing a counter-stake and providing a reason.
*   `requestOracleVerification(uint256, address, bytes)`: Initiates an external oracle request for claim verification (can be called by verifiers or owner).
*   `recordOracleVerification(uint256, bool, bytes32)`: Callback function for a registered oracle to report the truthfulness of a claim.
*   `voteOnClaimResolution(uint256, bool)`: Enables approved Verifiers to vote on the truthfulness of a claim, with vote weight based on their VeriScore.
*   `finalizeClaimResolution(uint256)`: Concludes a claim's resolution, distributes staked funds based on outcome, and updates VeriScores.
*   `getClaimDetails(uint256)`: Retrieves comprehensive data for a specific claim.
*   `getClaimsByTag(bytes32)`: Returns a list of claim IDs associated with a particular tag.

**II. Reputation System (VeriScore - SBT) (2 public functions + internal helpers):**
*   `getVeriScore(address)`: Returns the current VeriScore (reputation score) for a given user.
*   `getVeriScoreSBTTokenId(address)`: Returns the Soulbound Token ID associated with a user's VeriScore.
    *(Internal functions like `_updateVeriScore`, `_mint`, `_burn` are handled by the `VeriScoreSBT` contract and called internally by VeriFactNexus).*

**III. Dynamic Insight NFTs (4 functions):**
*   `evolveInsightNFT(uint256, uint8, string)`: (Owner/Proxy-callable) Updates an Insight NFT's tier and metadata URI, signifying its evolution.
*   `getInsightNFTMetadata(uint256)`: Returns the current metadata URI of an Insight NFT.
*   `redeemInsightNFTBonus(uint256)`: Allows an Insight NFT holder to redeem a special bonus if their NFT has reached a qualifying tier.
*   `updateInsightNFTOracle(address)`: Allows the owner to update the designated oracle responsible for triggering NFT evolution.

**IV. Oracle & AI Integration (2 functions):**
*   `registerOracle(address, string)`: Registers an address as a trusted external oracle (e.g., for Chainlink, custom AI models).
    *(`requestOracleVerification` and `recordOracleVerification` from Core Claim Management also fall here).*

**V. DAO Governance & Platform Admin (6 functions):**
*   `proposeParameterChange(string, bytes32, uint256)`: Creates a proposal to modify a configurable platform parameter.
*   `voteOnProposal(uint256, bool)`: Allows VeriScore holders to cast their weighted vote on active proposals.
*   `executeProposal(uint256)`: Executes a passed proposal, applying the proposed parameter change.
*   `addApprovedTag(bytes32)`: (Owner/DAO-controlled) Adds a new allowable tag that claims can use.
*   `setPlatformFee(uint256)`: (Owner/DAO-controlled) Sets the percentage of stakes collected as platform fees.
*   `setVerifierStatus(address[], bool)`: (Owner/DAO-controlled) Elects or de-elects addresses as official Verifiers.

**VI. ERC20 Interactions (1 function):**
*   `setStakeToken(address)`: Sets the ERC20 token address that will be used for all staking activities on the platform.

**VII. Owner/Admin Functions (1 function):**
*   `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.

**VIII. View Helpers (1 function):**
*   `getMinVeriScoreForVerifier()`: Returns the minimum VeriScore required to become an approved Verifier.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For clarity, though 0.8.0+ has default overflow protection.


// Interface for a hypothetical Oracle Service (e.g., Chainlink-like)
interface IOracleService {
    // A simplified request data function. Real-world would have jobId, payment, etc.
    function requestData(uint256 _claimId, bytes calldata _queryData) external returns (bytes32 _queryId);
    // The oracle would then call back a function on VeriFactNexus to fulfill.
}


/**
 * @title VeriScoreSBT
 * @dev A Soulbound Token (SBT) implementation used for non-transferable reputation.
 *      Minted and burned by the VeriFactNexus contract.
 */
contract VeriScoreSBT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(address => uint256) private _addressToTokenId;
    mapping(uint256 => address) private _tokenIdToAddress;

    constructor(address initialOwner) ERC721("VeriFact VeriScore", "VFSBT") Ownable(initialOwner) {}

    // Base URI for SBT metadata
    function _baseURI() internal pure override returns (string memory) {
        return "https://verifactnexus.xyz/sbt/metadata/";
    }

    // Internal function for VeriFactNexus to mint new SBTs
    function _mint(address to) internal returns (uint256) {
        require(_addressToTokenId[to] == 0, "VFSBT: Address already has an SBT.");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _addressToTokenId[to] = newTokenId;
        _tokenIdToAddress[newTokenId] = to;
        return newTokenId;
    }

    // Internal function for VeriFactNexus to burn SBTs (e.g., for severe penalties)
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        require(owner != address(0), "VFSBT: Token not found.");
        ERC721._burn(tokenId); // Call OpenZeppelin's internal burn
        delete _addressToTokenId[owner];
        delete _tokenIdToAddress[tokenId];
    }

    // Override transfer functions to make it non-transferable (Soulbound)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        // Allow minting (from address(0)) and burning (to address(0))
        require(from == address(0) || to == address(0), "VFSBT: Soulbound tokens are non-transferable.");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Public view functions for VeriFactNexus to query SBT info
    function getTokenIdByAddress(address _owner) public view returns (uint256) {
        return _addressToTokenId[_owner];
    }

    function getAddressByTokenId(uint256 _tokenId) public view returns (address) {
        return _tokenIdToAddress[_tokenId];
    }
}


/**
 * @title InsightNFT
 * @dev A Dynamic NFT implementation for rewarding impactful contributions.
 *      NFTs can evolve (change metadata/tier) based on criteria defined by an evolution oracle.
 */
contract InsightNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct InsightMetadata {
        uint8 tier; // e.g., 1=Bronze, 2=Silver, 3=Gold
        string customURI; // Specific URI for this NFT's current state (IPFS CID for metadata)
        uint256 associatedClaimId;
        bool bonusRedeemed;
    }

    mapping(uint256 => InsightMetadata) public insightData;
    mapping(uint256 => string[]) public evolutionHistory; // Stores past URIs for transparency

    address public evolutionOracle; // The address authorized to trigger NFT evolution (e.g., an AI oracle)
    uint256 public constant BONUS_TIER_THRESHOLD = 3; // Example: Bonus unlocked when NFT reaches Tier 3

    event InsightNFTEvolved(uint256 indexed tokenId, string oldURI, string newURI, uint8 newTier);
    event InsightNFTBonusRedeemed(uint256 indexed tokenId, address indexed redeemer); // Amount would be handled by VeriFactNexus

    constructor(address initialOwner) ERC721("VeriFact Insight NFT", "VFINFT") Ownable(initialOwner) {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://verifactnexus.xyz/insightnft/base/"; // Base URI, but `tokenURI` will return `customURI`
    }

    // Overrides ERC721's tokenURI to return the dynamic customURI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return insightData[tokenId].customURI;
    }

    // Internal function for VeriFactNexus to mint new Insight NFTs
    function _mint(address to, uint8 tier, uint256 claimId, string memory initialURI) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        insightData[newTokenId] = InsightMetadata({
            tier: tier,
            customURI: initialURI,
            associatedClaimId: claimId,
            bonusRedeemed: false
        });
        evolutionHistory[newTokenId].push(initialURI);
        return newTokenId;
    }

    // Allows the contract owner to set/update the evolution oracle
    function updateEvolutionOracle(address _newOracle) external onlyOwner {
        evolutionOracle = _newOracle;
    }

    // Allows the designated evolution oracle to evolve the NFT's metadata and tier
    function evolve(uint256 tokenId, uint8 newTier, string calldata newURI) external {
        require(msg.sender == evolutionOracle, "InsightNFT: Only evolution oracle can evolve.");
        require(_exists(tokenId), "InsightNFT: Token does not exist.");
        require(newTier > insightData[tokenId].tier, "InsightNFT: New tier must be higher than current.");

        string memory oldURI = insightData[tokenId].customURI;
        insightData[tokenId].tier = newTier;
        insightData[tokenId].customURI = newURI;
        evolutionHistory[tokenId].push(newURI);

        emit InsightNFTEvolved(tokenId, oldURI, newURI, newTier);
    }

    // Allows the NFT holder to redeem a bonus (e.g., token reward from VeriFactNexus)
    function redeemBonus(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "InsightNFT: Not the owner.");
        require(_exists(tokenId), "InsightNFT: Token does not exist.");
        require(insightData[tokenId].tier >= BONUS_TIER_THRESHOLD, "InsightNFT: Tier not high enough for bonus.");
        require(!insightData[tokenId].bonusRedeemed, "InsightNFT: Bonus already redeemed.");

        insightData[tokenId].bonusRedeemed = true;
        emit InsightNFTBonusRedeemed(tokenId, msg.sender);
        // The actual bonus transfer logic (e.g., tokens) would be handled by VeriFactNexus
        // This function primarily signals that a bonus is due.
    }

    // Provides all relevant Insight NFT data
    function getInsightData(uint256 tokenId) public view returns (uint8 tier, string memory uri, uint256 claimId, bool bonusRedeemed) {
        InsightMetadata storage data = insightData[tokenId];
        return (data.tier, data.customURI, data.associatedClaimId, data.bonusRedeemed);
    }
}


/**
 * @title VeriFactNexus
 * @dev The main smart contract for the VeriFact Nexus platform.
 *      Manages claims, challenges, resolution, reputation, NFTs, and governance.
 */
contract VeriFactNexus is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _claimIdCounter;
    Counters.Counter private _proposalIdCounter;

    VeriScoreSBT public veriScoreSBT;
    InsightNFT public insightNFT;
    IERC20 public stakeToken; // ERC20 token used for all staking

    // --- Structs ---
    enum ClaimStatus { Active, Challenged, Voting, ResolvedTrue, ResolvedFalse, Escalated }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    struct Claim {
        uint256 id;
        address submitter;
        string claimText;
        uint256 stake; // Submitter's stake
        uint256 resolutionTimestamp; // When the claim is scheduled to be resolved
        ClaimStatus status;
        address[] challengers;
        mapping(address => uint256) challengeStakes; // Stake per challenger
        uint256 totalChallengeStake;
        mapping(address => bool) verifierVoted; // Tracks if a verifier has voted
        uint256 trueVotes; // Weighted sum of VeriScores for 'true' votes
        uint256 falseVotes; // Weighted sum of VeriScores for 'false' votes
        bool oracleVerifiedTruth; // Oracle's determination (true for claim is true, false otherwise)
        bool oracleResolutionAttempted; // True if oracle verification was requested
        bytes32[] tags;
        uint256 finalResolutionTime; // When the claim was actually resolved
        bool resolvedTruth; // Final outcome: true if claim was deemed true, false otherwise
        bool stakesDistributed; // True if stakes have been distributed
    }
    mapping(uint256 => Claim) public claims;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes32 paramName; // e.g., "PLATFORM_FEE_PERCENT", "MIN_STAKE_AMOUNT"
        uint256 newValue;
        ProposalStatus status;
        mapping(address => bool) voted; // Tracks if a VeriScore holder has voted
        uint256 votesFor; // Weighted sum of VeriScores for 'for' votes
        uint256 votesAgainst; // Weighted sum of VeriScores for 'against' votes
        uint256 creationTime;
        uint256 votingEndTime;
    }
    mapping(uint256 => Proposal) public proposals;

    // --- Configuration Parameters ---
    uint256 public challengePeriodDuration = 3 days; // Time during which claims can be challenged
    uint256 public votingPeriodDuration = 2 days;    // Time verifiers have to vote
    uint256 public minClaimStake = 1 ether;          // Minimum stake for submitting a claim
    uint256 public minChallengeStake = 1 ether;       // Minimum stake for challenging a claim
    uint256 public proposalVotingPeriod = 7 days;    // Duration for DAO proposals to be voted on
    uint256 public platformFeePercentage = 5;         // 5% (e.g., 5 means 5%)
    uint256 public constant MAX_PLATFORM_FEE_PERCENTAGE = 10; // Max allowed fee percentage
    uint256 public MIN_VERI_SCORE_FOR_VERIFIER = 100; // Minimum score required to be an official Verifier

    mapping(bytes32 => bool) public approvedTags; // Whitelist of tags for claims
    mapping(address => bool) public isVerifier; // Addresses of currently elected Verifiers
    mapping(address => string) public registeredOracles; // address => oracle type string
    mapping(bytes32 => uint256[]) public tagToClaimIds; // Efficient lookup for claims by tag

    uint256 public totalFeesCollected; // Accumulated platform fees ready for withdrawal by owner

    // --- Internal VeriScore Storage ---
    mapping(address => uint252) private _veriscores; // Using uint252 to save a tiny bit of gas, enough for scores.

    // --- Events ---
    event ClaimSubmitted(uint256 indexed claimId, address indexed submitter, string claimText, uint256 stake, uint256 resolutionTimestamp);
    event ClaimChallenged(uint256 indexed claimId, address indexed challenger, uint256 stake);
    event OracleVerificationRequested(uint256 indexed claimId, address indexed oracle, bytes32 queryId);
    event OracleVerificationReceived(uint256 indexed claimId, bool result, uint256 timestamp);
    event ClaimVoteRecorded(uint256 indexed claimId, address indexed verifier, bool vote);
    event ClaimResolved(uint256 indexed claimId, ClaimStatus newStatus, bool resolvedTruth, uint256 totalPayout);
    event FundsDistributed(uint256 indexed claimId, address indexed party, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, bytes32 paramName, uint256 newValue);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);
    event VerifierStatusUpdated(address indexed verifier, bool isElected);
    event PlatformFeeUpdated(uint256 newFee);

    // --- Modifiers ---
    modifier onlyVerifiers() {
        require(isVerifier[msg.sender], "VeriFactNexus: Caller is not an approved verifier.");
        _;
    }

    modifier onlyRegisteredOracle(address _oracleAddress) {
        require(bytes(registeredOracles[_oracleAddress]).length > 0, "VeriFactNexus: Not a registered oracle.");
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner, address _stakeTokenAddress, address _insightNFTAddress) Ownable(initialOwner) {
        veriScoreSBT = new VeriScoreSBT(address(this)); // VeriFactNexus owns the SBT to mint/burn
        stakeToken = IERC20(_stakeTokenAddress);
        insightNFT = InsightNFT(_insightNFTAddress);
        // Transfer ownership of InsightNFT to VeriFactNexus for controlled calls
        insightNFT.transferOwnership(address(this));

        // Initialize some default approved tags
        approvedTags[keccak256(abi.encodePacked("Tech"))] = true;
        approvedTags[keccak256(abi.encodePacked("Science"))] = true;
        approvedTags[keccak256(abi.encodePacked("Politics"))] = true;
        approvedTags[keccak256(abi.encodePacked("Finance"))] = true;
        approvedTags[keccak256(abi.encodePacked("Future"))] = true;
    }

    // --- Internal VeriScore Management ---

    // @dev Updates a user's VeriScore and manages their SBT minting if needed.
    // @param _user The address of the user.
    // @param _scoreChange The amount to change the score by (positive for increase, negative for decrease).
    function _updateVeriScore(address _user, int256 _scoreChange) internal {
        uint256 currentScore = _veriscores[_user];
        uint256 newScore;

        if (_scoreChange > 0) {
            newScore = currentScore.add(uint256(_scoreChange));
        } else { // _scoreChange is 0 or negative
            uint256 scoreDecrease = uint256(-_scoreChange);
            newScore = currentScore < scoreDecrease ? 0 : currentScore.sub(scoreDecrease);
        }
        _veriscores[_user] = newScore;

        // Mint SBT if new user gets a positive score and doesn't have one
        if (veriScoreSBT.getTokenIdByAddress(_user) == 0 && newScore > 0) {
            veriScoreSBT._mint(_user);
        }
        // Potentially burn SBT if score drops to zero and no other criteria met (e.g., if governance decides)
        // This logic is more complex and would likely be a DAO action.
    }

    // --- II. Reputation System (VeriScore - SBT) ---

    // @function getVeriScore
    // @dev Returns the current VeriScore (reputation) for a given user.
    // @param _user The address of the user.
    // @return The VeriScore of the user.
    function getVeriScore(address _user) public view returns (uint256) {
        return _veriscores[_user];
    }

    // @function getVeriScoreSBTTokenId
    // @dev Returns the Soulbound Token ID associated with a user's VeriScore.
    // @param _user The address of the user.
    // @return The Token ID of the SBT owned by the user, or 0 if none.
    function getVeriScoreSBTTokenId(address _user) public view returns (uint256) {
        return veriScoreSBT.getTokenIdByAddress(_user);
    }

    // --- I. Core Claim Management ---

    // @function submitClaim
    // @dev Allows a user to submit a new claim to the VeriFact Nexus.
    // @param _claimText The full text of the claim being made.
    // @param _stakeAmount The amount of `stakeToken` to stake on the claim's truthfulness.
    // @param _resolutionTimestamp The Unix timestamp at which the claim is scheduled for resolution.
    // @param _tags An array of predefined tags to categorize the claim.
    // @return The unique ID of the newly submitted claim.
    function submitClaim(
        string calldata _claimText,
        uint256 _stakeAmount,
        uint256 _resolutionTimestamp,
        bytes32[] calldata _tags
    ) external returns (uint256) {
        require(_stakeAmount >= minClaimStake, "VeriFactNexus: Stake amount too low.");
        require(_resolutionTimestamp > block.timestamp.add(challengePeriodDuration).add(votingPeriodDuration),
            "VeriFactNexus: Resolution time too soon (must allow for challenge and voting periods).");
        require(bytes(_claimText).length > 0, "VeriFactNexus: Claim text cannot be empty.");
        require(_tags.length > 0, "VeriFactNexus: At least one tag required.");
        for (uint i = 0; i < _tags.length; i++) {
            require(approvedTags[_tags[i]], "VeriFactNexus: Tag not approved.");
        }

        stakeToken.transferFrom(msg.sender, address(this), _stakeAmount);

        _claimIdCounter.increment();
        uint256 newClaimId = _claimIdCounter.current();

        Claim storage newClaim = claims[newClaimId];
        newClaim.id = newClaimId;
        newClaim.submitter = msg.sender;
        newClaim.claimText = _claimText;
        newClaim.stake = _stakeAmount;
        newClaim.resolutionTimestamp = _resolutionTimestamp;
        newClaim.status = ClaimStatus.Active;
        newClaim.tags = _tags;

        for (uint i = 0; i < _tags.length; i++) {
            tagToClaimIds[_tags[i]].push(newClaimId);
        }

        _updateVeriScore(msg.sender, 5); // Small bonus for actively contributing
        emit ClaimSubmitted(newClaimId, msg.sender, _claimText, _stakeAmount, _resolutionTimestamp);
        return newClaimId;
    }

    // @function challengeClaim
    // @dev Allows a user to challenge an existing claim by placing a stake.
    // @param _claimId The ID of the claim to challenge.
    // @param _stakeAmount The amount of `stakeToken` to stake against the claim.
    // @param _challengeReason A brief string explaining the reason for the challenge.
    function challengeClaim(uint256 _claimId, uint256 _stakeAmount, string calldata _challengeReason) external {
        Claim storage claim = claims[_claimId];
        require(claim.id != 0, "VeriFactNexus: Claim does not exist.");
        require(claim.status == ClaimStatus.Active || claim.status == ClaimStatus.Challenged, "VeriFactNexus: Claim not in a challengeable state.");
        require(msg.sender != claim.submitter, "VeriFactNexus: Cannot challenge your own claim.");
        require(_stakeAmount >= minChallengeStake, "VeriFactNexus: Challenge stake amount too low.");
        require(block.timestamp <= claim.resolutionTimestamp.sub(votingPeriodDuration), "VeriFactNexus: Challenge period has ended.");

        // Check if user has already challenged this claim
        for (uint i = 0; i < claim.challengers.length; i++) {
            require(claim.challengers[i] != msg.sender, "VeriFactNexus: Already challenged this claim.");
        }

        stakeToken.transferFrom(msg.sender, address(this), _stakeAmount);

        claim.challengers.push(msg.sender);
        claim.challengeStakes[msg.sender] = _stakeAmount;
        claim.totalChallengeStake = claim.totalChallengeStake.add(_stakeAmount);
        claim.status = ClaimStatus.Challenged;

        _updateVeriScore(msg.sender, 2); // Small bonus for challenging
        emit ClaimChallenged(_claimId, msg.sender, _stakeAmount);
    }

    // @function requestOracleVerification
    // @dev Requests an external oracle to provide verification for a claim.
    // Only approved verifiers or the contract owner can request.
    // @param _claimId The ID of the claim to verify.
    // @param _oracleAddress The address of the registered oracle.
    // @param _queryData Data specific to the oracle's query (e.g., URL, API parameters).
    function requestOracleVerification(uint256 _claimId, address _oracleAddress, bytes calldata _queryData) external {
        require(isVerifier[msg.sender] || msg.sender == owner(), "VeriFactNexus: Only verifiers or owner can request oracle verification.");
        Claim storage claim = claims[_claimId];
        require(claim.id != 0, "VeriFactNexus: Claim does not exist.");
        require(claim.status == ClaimStatus.Challenged || claim.status == ClaimStatus.Active, "VeriFactNexus: Claim not in a state for oracle verification.");
        require(block.timestamp <= claim.resolutionTimestamp.sub(votingPeriodDuration), "VeriFactNexus: Too late for oracle verification.");
        require(bytes(registeredOracles[_oracleAddress]).length > 0, "VeriFactNexus: Oracle not registered.");
        require(!claim.oracleResolutionAttempted, "VeriFactNexus: Oracle verification already attempted for this claim.");

        claim.oracleResolutionAttempted = true;
        // In a real scenario, this would call an external Chainlink-like oracle contract:
        // bytes32 queryId = IOracleService(_oracleAddress).requestData(_claimId, _queryData);
        // For this example, we simulate the queryId. The oracle itself would then call `recordOracleVerification`.
        bytes32 queryId = keccak256(abi.encodePacked(_claimId, _oracleAddress, block.timestamp));
        emit OracleVerificationRequested(_claimId, _oracleAddress, queryId);
    }

    // @function recordOracleVerification
    // @dev Callback function used by registered oracles to report the result of a claim verification.
    // @param _claimId The ID of the claim being verified.
    // @param _result The boolean outcome of the oracle's verification (true for claim is true, false for claim is false).
    // @param _queryId The unique ID of the original oracle query. (Not fully used in this simplified example for matching).
    function recordOracleVerification(uint256 _claimId, bool _result, bytes32 _queryId) external onlyRegisteredOracle(msg.sender) {
        Claim storage claim = claims[_claimId];
        require(claim.id != 0, "VeriFactNexus: Claim does not exist.");
        require(claim.oracleResolutionAttempted, "VeriFactNexus: Oracle verification not requested for this claim.");
        require(claim.status == ClaimStatus.Challenged || claim.status == ClaimStatus.Active, "VeriFactNexus: Claim already resolved or in voting.");

        claim.oracleVerifiedTruth = _result;
        claim.status = ClaimStatus.Voting; // Move to voting stage after oracle input (or direct resolution if no verifiers needed)
        emit OracleVerificationReceived(_claimId, _result, block.timestamp);
    }

    // @function voteOnClaimResolution
    // @dev Allows an approved verifier to cast a weighted vote on a claim's truthfulness.
    // @param _claimId The ID of the claim to vote on.
    // @param _isTrue True if the verifier believes the claim is true, false otherwise.
    function voteOnClaimResolution(uint256 _claimId, bool _isTrue) external onlyVerifiers {
        Claim storage claim = claims[_claimId];
        require(claim.id != 0, "VeriFactNexus: Claim does not exist.");
        require(claim.status == ClaimStatus.Challenged || claim.status == ClaimStatus.Voting, "VeriFactNexus: Claim not in a voting state.");
        require(block.timestamp > claim.resolutionTimestamp.sub(votingPeriodDuration), "VeriFactNexus: Voting has not started yet.");
        require(block.timestamp < claim.resolutionTimestamp, "VeriFactNexus: Voting period has ended.");
        require(!claim.verifierVoted[msg.sender], "VeriFactNexus: Already voted on this claim.");

        claim.verifierVoted[msg.sender] = true;
        uint256 voterScore = getVeriScore(msg.sender); // Vote weight is based on VeriScore
        if (_isTrue) {
            claim.trueVotes = claim.trueVotes.add(voterScore);
        } else {
            claim.falseVotes = claim.falseVotes.add(voterScore);
        }
        claim.status = ClaimStatus.Voting; // Ensure status is set to Voting after first vote

        emit ClaimVoteRecorded(_claimId, msg.sender, _isTrue);
    }

    // @function finalizeClaimResolution
    // @dev Finalizes the resolution of a claim, distributing stakes and updating VeriScores.
    // Can be called by anyone after the resolution timestamp has passed.
    // @param _claimId The ID of the claim to finalize.
    function finalizeClaimResolution(uint256 _claimId) external {
        Claim storage claim = claims[_claimId];
        require(claim.id != 0, "VeriFactNexus: Claim does not exist.");
        require(claim.status != ClaimStatus.ResolvedTrue && claim.status != ClaimStatus.ResolvedFalse, "VeriFactNexus: Claim already resolved.");
        require(block.timestamp >= claim.resolutionTimestamp, "VeriFactNexus: Resolution period not yet reached.");
        require(!claim.stakesDistributed, "VeriFactNexus: Stakes already distributed.");

        bool finalOutcome; // true if claim is deemed true, false otherwise
        ClaimStatus newStatus;

        // Resolution hierarchy: Oracle > Verifiers > Default (true if unchallenged, false if challenged without clear consensus)
        if (claim.oracleResolutionAttempted) {
            finalOutcome = claim.oracleVerifiedTruth; // Oracle's determination takes precedence
        } else if (claim.trueVotes > 0 || claim.falseVotes > 0) {
            finalOutcome = (claim.trueVotes >= claim.falseVotes); // Majority of weighted verifier votes
        } else if (claim.challengers.length == 0) {
            finalOutcome = true; // No challenges, implicitly true (submitter wins)
        } else {
            finalOutcome = false; // Challenged, no verifier consensus/oracle, default to false (challengers win)
        }

        claim.resolvedTruth = finalOutcome;
        newStatus = finalOutcome ? ClaimStatus.ResolvedTrue : ClaimStatus.ResolvedFalse;
        claim.status = newStatus;
        claim.finalResolutionTime = block.timestamp;

        // Calculate and distribute stakes
        uint256 totalStaked = claim.stake.add(claim.totalChallengeStake);
        uint256 platformFee = totalStaked.mul(platformFeePercentage).div(100);
        uint256 payoutPool = totalStaked.sub(platformFee);
        totalFeesCollected = totalFeesCollected.add(platformFee); // Accumulate fees

        uint256 totalWinningStake = 0;
        address[] memory winningParties;
        uint256[] memory winningStakes; // Store individual winning stakes

        if (finalOutcome) { // Claim resolved as TRUE (Submitter wins)
            totalWinningStake = claim.stake;
            winningParties = new address[](1);
            winningParties[0] = claim.submitter;
            winningStakes = new uint256[](1);
            winningStakes[0] = claim.stake;
        } else { // Claim resolved as FALSE (Challengers win)
            totalWinningStake = claim.totalChallengeStake;
            winningParties = claim.challengers;
            winningStakes = new uint256[](claim.challengers.length);
            for(uint i=0; i < claim.challengers.length; i++) {
                winningStakes[i] = claim.challengeStakes[claim.challengers[i]];
            }
        }

        // Payout winning stakes proportionally from the payout pool
        if (totalWinningStake > 0) {
            for (uint i = 0; i < winningParties.length; i++) {
                address winner = winningParties[i];
                uint256 winnerShare = winningStakes[i].mul(payoutPool).div(totalWinningStake);
                stakeToken.transfer(winner, winnerShare);
                emit FundsDistributed(_claimId, winner, winnerShare);

                // Update VeriScore for winners
                _updateVeriScore(winner, finalOutcome ? 10 : 7); // Higher reward for submitter if correct
            }
        }

        // Update VeriScore for losing parties
        if (finalOutcome) { // Claim True, challengers lose
            for (uint i = 0; i < claim.challengers.length; i++) {
                _updateVeriScore(claim.challengers[i], -5);
            }
        } else { // Claim False, submitter loses
            _updateVeriScore(claim.submitter, -10);
        }

        // Award InsightNFTs for exceptional accuracy (simplified logic for demo)
        if (finalOutcome && claim.stake.mul(100).div(totalStaked) > 75) { // High confidence win for submitter
            insightNFT._mint(claim.submitter, 1, _claimId, "ipfs://tier1-accurate-claim.json");
        } else if (!finalOutcome && claim.totalChallengeStake.mul(100).div(totalStaked) > 75) { // High confidence win for challengers
            if (claim.challengers.length > 0) {
                // Award to the challenger with the largest stake, or simply the first one for simplicity
                insightNFT._mint(claim.challengers[0], 1, _claimId, "ipfs://tier1-prescient-challenge.json");
            }
        }

        claim.stakesDistributed = true;
        emit ClaimResolved(_claimId, newStatus, finalOutcome, payoutPool);
    }

    // @function getClaimDetails
    // @dev Returns comprehensive details of a specific claim.
    // @param _claimId The ID of the claim.
    // @return All relevant data for the claim.
    function getClaimDetails(uint256 _claimId) public view returns (
        uint256 id,
        address submitter,
        string memory claimText,
        uint256 stake,
        uint256 resolutionTimestamp,
        ClaimStatus status,
        address[] memory challengers,
        uint256 totalChallengeStake,
        uint256 trueVotes,
        uint256 falseVotes,
        bool oracleVerifiedTruth,
        bool oracleResolutionAttempted,
        bytes32[] memory tags,
        uint256 finalResolutionTime,
        bool resolvedTruth,
        bool stakesDistributed
    ) {
        Claim storage claim = claims[_claimId];
        require(claim.id != 0, "VeriFactNexus: Claim does not exist.");
        return (
            claim.id,
            claim.submitter,
            claim.claimText,
            claim.stake,
            claim.resolutionTimestamp,
            claim.status,
            claim.challengers,
            claim.totalChallengeStake,
            claim.trueVotes,
            claim.falseVotes,
            claim.oracleVerifiedTruth,
            claim.oracleResolutionAttempted,
            claim.tags,
            claim.finalResolutionTime,
            claim.resolvedTruth,
            claim.stakesDistributed
        );
    }

    // @function getClaimsByTag
    // @dev Retrieves a list of claim IDs that have a specific tag.
    // @param _tag The tag to filter claims by.
    // @return An array of claim IDs matching the tag.
    function getClaimsByTag(bytes32 _tag) public view returns (uint256[] memory) {
        require(approvedTags[_tag], "VeriFactNexus: Tag not approved.");
        return tagToClaimIds[_tag];
    }

    // --- III. Dynamic Insight NFTs ---

    // @function evolveInsightNFT
    // @dev Proxy function to allow the InsightNFT's designated oracle to evolve a specific NFT.
    // This function can only be called by the VeriFactNexus contract owner, acting on behalf of the DAO.
    // @param _tokenId The ID of the Insight NFT to evolve.
    // @param _newTier The new tier level for the NFT.
    // @param _newURI The new metadata URI for the NFT.
    function evolveInsightNFT(uint256 _tokenId, uint8 _newTier, string calldata _newURI) external onlyOwner {
        // This function is called by the owner of VeriFactNexus, who acts as the owner of InsightNFT.
        // The actual `evolutionOracle` of InsightNFT might be an external AI service.
        insightNFT.evolve(_tokenId, _newTier, _newURI);
    }

    // @function getInsightNFTMetadata
    // @dev Returns the current metadata URI for a given Insight NFT.
    // @param _tokenId The ID of the Insight NFT.
    // @return The metadata URI of the NFT.
    function getInsightNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        return insightNFT.tokenURI(_tokenId);
    }

    // @function redeemInsightNFTBonus
    // @dev Allows an Insight NFT holder to redeem a bonus associated with a high-tier NFT.
    // @param _tokenId The ID of the Insight NFT.
    function redeemInsightNFTBonus(uint256 _tokenId) external {
        // InsightNFT contract handles the logic and emits an event.
        // Based on the InsightNFTBonusRedeemed event, VeriFactNexus would then transfer rewards.
        insightNFT.redeemBonus(_tokenId);
        // Additional logic here to transfer stakeToken rewards to msg.sender
        // This requires tracking pending bonuses. For simplicity, we just signal through the event.
    }

    // @function updateInsightNFTOracle
    // @dev Allows the owner to update the evolution oracle address in the InsightNFT contract.
    // @param _newOracle The new address for the evolution oracle.
    function updateInsightNFTOracle(address _newOracle) external onlyOwner {
        insightNFT.updateEvolutionOracle(_newOracle);
    }

    // --- IV. Oracle & AI Integration ---

    // @function registerOracle
    // @dev Registers an address as a trusted oracle with a specific type (e.g., "Chainlink", "OpenAI_API").
    // Only the contract owner can register oracles.
    // @param _oracleAddress The address of the oracle.
    // @param _oracleType A string describing the type or service of the oracle.
    function registerOracle(address _oracleAddress, string calldata _oracleType) external onlyOwner {
        require(_oracleAddress != address(0), "VeriFactNexus: Invalid oracle address.");
        require(bytes(_oracleType).length > 0, "VeriFactNexus: Oracle type cannot be empty.");
        registeredOracles[_oracleAddress] = _oracleType;
    }

    // --- V. DAO Governance & Platform Admin ---

    // @function proposeParameterChange
    // @dev Creates a proposal to change a system parameter.
    // Requires a minimum VeriScore or a minimum staked amount to propose.
    // @param _description A detailed description of the proposal.
    // @param _paramName The name of the parameter to change (e.g., "minClaimStake", "platformFeePercentage").
    // @param _newValue The new value for the parameter.
    // @return The ID of the newly created proposal.
    function proposeParameterChange(string calldata _description, bytes32 _paramName, uint256 _newValue) external returns (uint256) {
        require(getVeriScore(msg.sender) >= MIN_VERI_SCORE_FOR_VERIFIER || stakeToken.balanceOf(msg.sender) >= minClaimStake.mul(2),
                "VeriFactNexus: Not enough VeriScore or stake to propose.");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            paramName: _paramName,
            newValue: _newValue,
            status: ProposalStatus.Pending,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(proposalVotingPeriod),
            voted: new mapping(address => bool) // Initialize the nested mapping
        });

        emit ProposalCreated(newProposalId, msg.sender, _description, _paramName, _newValue);
        return newProposalId;
    }

    // @function voteOnProposal
    // @dev Allows participants with VeriScore to vote on an active proposal.
    // Their vote weight is proportional to their current VeriScore.
    // @param _proposalId The ID of the proposal to vote on.
    // @param _support True for 'yes' vote, false for 'no' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "VeriFactNexus: Proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "VeriFactNexus: Proposal not active or already resolved.");
        require(block.timestamp < proposal.votingEndTime, "VeriFactNexus: Voting period has ended.");
        require(getVeriScore(msg.sender) > 0, "VeriFactNexus: Must have VeriScore to vote.");
        require(!proposal.voted[msg.sender], "VeriFactNexus: Already voted on this proposal.");

        uint256 voterScore = getVeriScore(msg.sender);
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterScore);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterScore);
        }
        proposal.voted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    // @function executeProposal
    // @dev Executes a proposal if it has passed the voting period and threshold.
    // Anyone can call this function after the voting period ends, if the proposal passed.
    // @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "VeriFactNexus: Proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "VeriFactNexus: Proposal not pending.");
        require(block.timestamp >= proposal.votingEndTime, "VeriFactNexus: Voting period not ended.");
        require(proposal.votesFor > proposal.votesAgainst, "VeriFactNexus: Proposal did not pass.");

        // Apply the parameter change based on paramName
        bytes32 param = proposal.paramName;
        uint256 val = proposal.newValue;

        if (param == keccak256(abi.encodePacked("challengePeriodDuration"))) {
            challengePeriodDuration = val;
        } else if (param == keccak256(abi.encodePacked("votingPeriodDuration"))) {
            votingPeriodDuration = val;
        } else if (param == keccak256(abi.encodePacked("minClaimStake"))) {
            minClaimStake = val;
        } else if (param == keccak256(abi.encodePacked("minChallengeStake"))) {
            minChallengeStake = val;
        } else if (param == keccak256(abi.encodePacked("proposalVotingPeriod"))) {
            proposalVotingPeriod = val;
        } else if (param == keccak256(abi.encodePacked("platformFeePercentage"))) {
            require(val <= MAX_PLATFORM_FEE_PERCENTAGE, "VeriFactNexus: Fee exceeds max allowed.");
            platformFeePercentage = val;
        } else if (param == keccak256(abi.encodePacked("MIN_VERI_SCORE_FOR_VERIFIER"))) {
            MIN_VERI_SCORE_FOR_VERIFIER = val;
        } else {
            revert("VeriFactNexus: Unknown parameter for proposal.");
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, param, val);
    }

    // @function addApprovedTag
    // @dev Allows the owner (or DAO) to add a new approved tag for claims.
    // @param _tag The new tag to approve (e.g., keccak256(abi.encodePacked("Health"))).
    function addApprovedTag(bytes32 _tag) external onlyOwner { // In a full DAO, this would be via proposal
        require(!approvedTags[_tag], "VeriFactNexus: Tag already approved.");
        approvedTags[_tag] = true;
    }

    // @function setPlatformFee
    // @dev Sets the platform fee percentage. Owner (or DAO) only.
    // @param _newFee The new fee percentage (e.g., 5 for 5%).
    function setPlatformFee(uint256 _newFee) external onlyOwner { // In a full DAO, this would be via proposal
        require(_newFee <= MAX_PLATFORM_FEE_PERCENTAGE, "VeriFactNexus: Fee exceeds maximum allowed.");
        platformFeePercentage = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    // @function setVerifierStatus
    // @dev Elects or de-elects addresses as official Verifiers.
    // This is a governance function, likely triggered by a DAO proposal.
    // For simplicity, it's currently owner-controlled.
    // @param _candidates An array of addresses to be considered for verifier status.
    // @param _status True to set as verifier, false to remove.
    function setVerifierStatus(address[] calldata _candidates, bool _status) external onlyOwner {
        for (uint i = 0; i < _candidates.length; i++) {
            require(getVeriScore(_candidates[i]) >= MIN_VERI_SCORE_FOR_VERIFIER, "VeriFactNexus: Candidate does not meet min VeriScore.");
            isVerifier[_candidates[i]] = _status;
            emit VerifierStatusUpdated(_candidates[i], _status);
        }
    }

    // --- VI. ERC20 Interactions ---

    // @function setStakeToken
    // @dev Sets the ERC20 token address used for staking. Can only be set once.
    // @param _stakeTokenAddress The address of the ERC20 token.
    function setStakeToken(address _stakeTokenAddress) external onlyOwner {
        require(address(stakeToken) == address(0), "VeriFactNexus: Stake token already set.");
        stakeToken = IERC20(_stakeTokenAddress);
    }

    // --- VII. Owner/Admin Functions ---

    // @function withdrawPlatformFees
    // @dev Allows the owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        uint256 feesToWithdraw = totalFeesCollected;
        require(feesToWithdraw > 0, "VeriFactNexus: No fees to withdraw.");
        totalFeesCollected = 0; // Reset accumulated fees
        stakeToken.transfer(msg.sender, feesToWithdraw);
    }

    // --- VIII. View Helpers ---

    // @function getMinVeriScoreForVerifier
    // @dev Returns the minimum VeriScore required to become an official Verifier.
    function getMinVeriScoreForVerifier() public view returns (uint256) {
        return MIN_VERI_SCORE_FOR_VERIFIER;
    }
}
```