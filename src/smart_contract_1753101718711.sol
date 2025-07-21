```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For totalSupply, tokenByIndex etc.
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Outline and Function Summary ---

// AetherForge: Autonomous Generative Art & Dynamic Narratives Protocol

// This contract orchestrates a novel ecosystem for creating, evolving, and curating dynamic on-chain generative art and narratives.
// It leverages an external AI oracle for content generation, incorporates a robust reputation-based curation system,
// and manages a utility token for economic incentives. The AetherBound NFTs are dynamic, evolving their traits and narratives
// based on user interactions and AI outputs, validated by community curation.

// I. Core Setup & Administration
// 1.  constructor(string memory _tokenName, string memory _tokenSymbol, address _initialOracleAddress, uint256 _initialForgePrice, uint256 _initialEvolutionPrice, uint256 _initialCurationStakeAmount, uint256 _initialAetherStoneSupply): Initializes the contract, deploys `AetherStone` ERC-20, and sets up initial parameters.
// 2.  setOracleAddress(address _oracleAddress): Sets the address of the trusted AI Oracle contract. Only callable by owner.
// 3.  setPricingParameters(uint256 _forgePrice, uint256 _evolutionPrice, uint256 _curationStakeAmount, uint256 _curationLockupDuration, uint256 _minVotesForCuration): Adjusts the AetherBound minting price, evolution price, curator staking requirement, lock-up, and minimum votes for curation. Only callable by owner.
// 4.  pauseContract(): Pauses core contract functionalities (e.g., forging, evolving, staking) in an emergency. Only callable by owner.
// 5.  unpauseContract(): Resumes core contract functionalities. Only callable by owner.
// 6.  withdrawProtocolFees(address _tokenAddress): Allows the owner to withdraw accumulated protocol fees (e.g., forge/evolution payments) from the contract.

// II. AetherBound NFT (ERC-721) Mechanics
// 7.  forgeAetherBound(string calldata _initialPrompt): Mints a new `AetherBound` NFT for the caller. Requires payment in `AetherStone`. Triggers an AI oracle request for initial generative traits and narrative.
// 8.  evolveAetherBound(uint256 _tokenId, string calldata _evolutionPrompt): Initiates the evolution of an existing `AetherBound` NFT. Requires `AetherStone` payment or sufficient curator reputation. Triggers a new AI oracle request for updated traits or narrative segments.
// 9.  getAetherBoundDetails(uint256 _tokenId): Retrieves comprehensive details about an `AetherBound` NFT, including its current traits, narrative segments, and evolution stage.
// 10. tokenURI(uint256 _tokenId): Standard ERC-721 function to return a URI pointing to the NFT's metadata JSON. This JSON is dynamically constructed using on-chain data and an off-chain resolver.
// 11. getAetherBoundTraitHashes(uint256 _tokenId): Returns an array of hashes representing the trait sets accumulated by the NFT.
// 12. getAetherBoundNarrativeHashes(uint256 _tokenId): Returns an array of hashes representing the narrative segments accumulated by the NFT.
// 13. getAetherBoundEvolutionStage(uint256 _tokenId): Returns the current evolution stage of a specific AetherBound NFT.

// III. Curation & Reputation System
// 14. stakeAetherStoneForCuration(uint256 _amount): Allows users to stake `AetherStone` to become active curators, earning curation rewards and reputation. Requires `_amount` to be at least `curationStakeAmount`.
// 15. unstakeAetherStoneFromCuration(): Allows curators to unstake their `AetherStone` after a lock-up period.
// 16. submitCurationVote(uint256 _submissionId, uint8 _score): Curators cast votes on AI-generated content (traits or narrative segments) identified by `_submissionId`. Scores influence the content's validity and the curator's reputation. (Score 0-100)
// 17. getCuratorReputation(address _user): Retrieves the reputation score of a specific curator.
// 18. claimCurationRewards(): Allows curators to claim their earned `AetherStone` rewards based on their accurate votes.
// 19. getPendingCurationSubmissions(): Returns a list of AI-generated content submissions that are currently awaiting curator votes.
// 20. finalizeCurationSubmission(uint256 _submissionId): Finalizes a curation submission, applies reputation changes, and integrates the AI content into the NFT if approved. Can only be called after sufficient votes.

// IV. AI Oracle Interaction & Data Management
// 21. fulfillForgeRequest(uint256 _requestId, uint256 _tokenId, bytes32 _initialTraitHash, bytes32 _initialNarrativeHash): Callback function, callable only by the trusted AI Oracle, to deliver the results of an `AetherBound` forging request.
// 22. fulfillEvolutionRequest(uint256 _requestId, uint256 _tokenId, bytes32 _newTraitHash, bytes32 _newNarrativeHash): Callback function, callable only by the trusted AI Oracle, to deliver the results of an `AetherBound` evolution request.
// 23. getOracleRequestIdForToken(uint256 _tokenId): Returns the last pending oracle request ID associated with a specific AetherBound NFT. (For monitoring).

// V. AetherStone Token (ERC-20) Integration
// 24. AetherStone(): Returns the address of the `AetherStone` ERC-20 token contract.
// 25. getForgePrice(): Returns the current price in `AetherStone` to forge a new `AetherBound` NFT.
// 26. getEvolutionPrice(): Returns the current price in `AetherStone` to evolve an `AetherBound` NFT.

// Additional Note: The "AI Oracle" here is conceptual. In a real-world scenario, it would be a Chainlink External Adapter or similar
// decentralized oracle network, fetching AI-generated content hashes from off-chain AI models (e.g., Stable Diffusion, GPT).
// The contract only stores the *hashes* of the generated content for on-chain verifiability and dynamic metadata generation.

// --- Contract Source Code ---

// Define the AetherStone ERC-20 token directly within the main contract for simplicity
contract AetherStone is ERC20 {
    constructor(uint256 initialSupply) ERC20("AetherStone", "AEST") {
        _mint(msg.sender, initialSupply);
    }
}

// Minimal interface for the conceptual AI Oracle
interface IAetherForgeOracle {
    // Functions for the main contract to call the oracle (request generation)
    function requestForge(uint256 _tokenId, string calldata _prompt) external;
    function requestEvolution(uint256 _tokenId, string calldata _prompt) external;

    // Callbacks for the oracle to fulfill requests (these are internal to AetherForge, the actual oracle would call AetherForge's fulfill functions directly)
    // function fulfillForge(uint256 _requestId, uint256 _tokenId, bytes32 _traitSetHash, bytes32 _narrativeHash) external;
    // function fulfillEvolution(uint256 _requestId, uint256 _tokenId, bytes32 _newTraitSetHash, bytes32 _newNarrativeHash) external;
}

contract AetherForge is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // NFT Core
    Counters.Counter private _tokenIdCounter;
    // tokenId => array of trait hashes (can grow as NFT evolves)
    mapping(uint256 => bytes32[]) public aetherBoundTraitHashes;
    // tokenId => array of narrative segment hashes
    mapping(uint256 => bytes32[]) public aetherBoundNarrativeHashes;
    // tokenId => evolution stage
    mapping(uint256 => uint256) public aetherBoundEvolutionStage;
    // tokenId => last oracle request ID (for tracking pending operations)
    mapping(uint256 => uint256) public tokenPendingRequest;

    // Economic Parameters
    uint256 public forgePrice; // Price to mint new AetherBound in AetherStone
    uint256 public evolutionPrice; // Price to evolve AetherBound in AetherStone

    // AI Oracle Integration
    address public trustedOracle; // Address of the AI Oracle contract
    Counters.Counter private _oracleRequestIdCounter; // Unique IDs for oracle requests
    // requestId => OracleRequest (details about the request)
    mapping(uint256 => OracleRequest) public oracleRequests;

    struct OracleRequest {
        uint256 tokenId;
        address requester;
        string prompt;
        bool fulfilled;
        RequestType requestType;
    }

    enum RequestType { Forge, Evolution }

    // Curation System
    AetherStone public aetherStone; // Instance of the AetherStone ERC-20 token
    uint256 public curationStakeAmount; // Minimum AetherStone to stake for curation
    uint256 public curationLockupDuration; // Duration tokens are locked for curation (in seconds)
    uint256 public minVotesForCuration; // Minimum votes required to finalize a curation submission

    // curator address => amount staked
    mapping(address => uint256) public stakedAetherStone;
    // curator address => timestamp when tokens can be unstaked
    mapping(address => uint256) public unstakeTimestamp;
    // curator address => reputation score
    mapping(address => int256) public curatorReputation; // int256 to allow negative reputation for penalties
    // curator address => earned but unclaimed rewards
    mapping(address => uint256) public curatorRewards;

    // Curation Submissions (for AI-generated content review)
    Counters.Counter private _submissionIdCounter;
    // submissionId => CurationSubmission details
    mapping(uint256 => CurationSubmission) public curationSubmissions;
    // submissionId => curator address => hasVoted (bool)
    mapping(uint256 => mapping(address => bool)) public hasVotedOnSubmission;
    // Array of submission IDs that are pending votes
    uint256[] public pendingCurationSubmissions;

    struct CurationSubmission {
        uint256 tokenId;
        uint256 oracleRequestId;
        bytes32 dataHash; // The hash of the AI-generated content (trait or narrative)
        uint8 dataType; // 0 for trait, 1 for narrative
        uint256 totalScore; // Sum of all votes
        uint256 voteCount;
        bool finalized;
        bool approved; // True if approved by community, false if rejected
    }

    // --- Events ---
    event AetherBoundForged(uint256 indexed tokenId, address indexed owner, string initialPrompt);
    event AetherBoundEvolutionInitiated(uint256 indexed tokenId, address indexed caller, string evolutionPrompt);
    event AetherBoundEvolved(uint256 indexed tokenId, uint256 newEvolutionStage, bytes32 newTraitHash, bytes32 newNarrativeHash);
    event OracleRequestSent(uint256 indexed requestId, uint256 indexed tokenId, RequestType requestType, string prompt);
    event OracleRequestFulfilled(uint256 indexed requestId, uint256 indexed tokenId, bytes32 dataHash);
    event AetherStoneStaked(address indexed curator, uint256 amount);
    event AetherStoneUnstaked(address indexed curator, uint224 amount); // Changed to uint224 to avoid clash with ERC20.transfer(uint256)
    event CurationVoteCast(uint256 indexed submissionId, address indexed curator, uint8 score);
    event CurationSubmissionFinalized(uint256 indexed submissionId, bool approved, int256 averageScore);
    event CuratorReputationUpdated(address indexed curator, int256 newReputation);
    event RewardsClaimed(address indexed curator, uint256 amount);
    event FeesWithdrawn(address indexed tokenAddress, uint256 amount);

    // --- Constructor ---
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _initialOracleAddress,
        uint256 _initialForgePrice,
        uint256 _initialEvolutionPrice,
        uint256 _initialCurationStakeAmount,
        uint256 _initialAetherStoneSupply
    ) ERC721(_tokenName, _tokenSymbol) Ownable(msg.sender) {
        require(_initialOracleAddress != address(0), "AetherForge: Invalid oracle address");

        aetherStone = new AetherStone(_initialAetherStoneSupply);
        trustedOracle = _initialOracleAddress;
        forgePrice = _initialForgePrice;
        evolutionPrice = _initialEvolutionPrice;
        curationStakeAmount = _initialCurationStakeAmount;
        curationLockupDuration = 30 days; // Example: 30 days lockup
        minVotesForCuration = 5; // Example: Minimum 5 votes to finalize a submission
    }

    // --- Modifiers ---
    modifier onlyTrustedOracle() {
        require(msg.sender == trustedOracle, "AetherForge: Not trusted oracle");
        _;
    }

    modifier onlyCurator() {
        require(stakedAetherStone[msg.sender] >= curationStakeAmount, "AetherForge: Not a registered curator or not enough staked");
        _;
    }

    // --- I. Core Setup & Administration ---

    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "AetherForge: Invalid oracle address");
        trustedOracle = _oracleAddress;
    }

    function setPricingParameters(
        uint256 _forgePrice,
        uint256 _evolutionPrice,
        uint256 _curationStakeAmount,
        uint256 _curationLockupDuration,
        uint256 _minVotesForCuration
    ) public onlyOwner {
        forgePrice = _forgePrice;
        evolutionPrice = _evolutionPrice;
        curationStakeAmount = _curationStakeAmount;
        curationLockupDuration = _curationLockupDuration;
        minVotesForCuration = _minVotesForCuration;
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    function withdrawProtocolFees(address _tokenAddress) public onlyOwner {
        uint256 balance;
        if (_tokenAddress == address(aetherStone)) {
            balance = aetherStone.balanceOf(address(this));
            require(aetherStone.transfer(owner(), balance), "AetherForge: AEST transfer failed");
        } else if (_tokenAddress == address(0)) { // ETH
            balance = address(this).balance;
            payable(owner()).transfer(balance);
        } else {
            revert("AetherForge: Unsupported token address");
        }
        emit FeesWithdrawn(_tokenAddress, balance);
    }

    // --- II. AetherBound NFT (ERC-721) Mechanics ---

    function forgeAetherBound(string calldata _initialPrompt) public payable whenNotPaused returns (uint256) {
        require(aetherStone.balanceOf(msg.sender) >= forgePrice, "AetherForge: Insufficient AetherStone for forging");
        require(aetherStone.transferFrom(msg.sender, address(this), forgePrice), "AetherForge: AEST payment failed");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        aetherBoundEvolutionStage[newTokenId] = 0; // Initial stage

        // Request initial traits and narrative from AI oracle
        uint256 requestId = _oracleRequestIdCounter.current();
        _oracleRequestIdCounter.increment();
        oracleRequests[requestId] = OracleRequest({
            tokenId: newTokenId,
            requester: msg.sender,
            prompt: _initialPrompt,
            fulfilled: false,
            requestType: RequestType.Forge
        });
        tokenPendingRequest[newTokenId] = requestId;

        IAetherForgeOracle(trustedOracle).requestForge(newTokenId, _initialPrompt);

        emit AetherBoundForged(newTokenId, msg.sender, _initialPrompt);
        emit OracleRequestSent(requestId, newTokenId, RequestType.Forge, _initialPrompt);

        return newTokenId;
    }

    function evolveAetherBound(uint256 _tokenId, string calldata _evolutionPrompt) public payable whenNotPaused {
        require(_exists(_tokenId), "AetherForge: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "AetherForge: Not token owner");
        require(tokenPendingRequest[_tokenId] == 0, "AetherForge: Token has a pending oracle request");

        // Option 1: Pay AetherStone
        if (aetherStone.balanceOf(msg.sender) >= evolutionPrice) {
            require(aetherStone.transferFrom(msg.sender, address(this), evolutionPrice), "AetherForge: AEST payment failed");
        }
        // Option 2: Use curator reputation (e.g., 1000 reputation points for a free evolution)
        else if (curatorReputation[msg.sender] >= 1000) {
            curatorReputation[msg.sender] -= 1000;
            emit CuratorReputationUpdated(msg.sender, curatorReputation[msg.sender]);
        } else {
            revert("AetherForge: Insufficient AetherStone or reputation for evolution");
        }

        uint256 requestId = _oracleRequestIdCounter.current();
        _oracleRequestIdCounter.increment();
        oracleRequests[requestId] = OracleRequest({
            tokenId: _tokenId,
            requester: msg.sender,
            prompt: _evolutionPrompt,
            fulfilled: false,
            requestType: RequestType.Evolution
        });
        tokenPendingRequest[_tokenId] = requestId;

        IAetherForgeOracle(trustedOracle).requestEvolution(_tokenId, _evolutionPrompt);

        emit AetherBoundEvolutionInitiated(_tokenId, msg.sender, _evolutionPrompt);
        emit OracleRequestSent(requestId, _tokenId, RequestType.Evolution, _evolutionPrompt);
    }

    function getAetherBoundDetails(uint256 _tokenId)
        public view
        returns (
            address owner,
            uint256 evolutionStage,
            bytes32[] memory traitHashes,
            bytes32[] memory narrativeHashes
        )
    {
        require(_exists(_tokenId), "AetherForge: Token does not exist");
        owner = ownerOf(_tokenId);
        evolutionStage = aetherBoundEvolutionStage[_tokenId];
        traitHashes = aetherBoundTraitHashes[_tokenId];
        narrativeHashes = aetherBoundNarrativeHashes[_tokenId];
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Construct a URI that points to an off-chain resolver.
        // The resolver will fetch the traitHashes and narrativeHashes from the contract,
        // then resolve them to actual trait data/narrative text from IPFS/Arweave
        // and generate the JSON metadata and image SVG dynamically.
        return string(abi.encodePacked("ipfs://aetherforge/", _tokenId, "/metadata"));
    }

    function getAetherBoundTraitHashes(uint256 _tokenId) public view returns (bytes32[] memory) {
        require(_exists(_tokenId), "AetherForge: Token does not exist");
        return aetherBoundTraitHashes[_tokenId];
    }

    function getAetherBoundNarrativeHashes(uint256 _tokenId) public view returns (bytes32[] memory) {
        require(_exists(_tokenId), "AetherForge: Token does not exist");
        return aetherBoundNarrativeHashes[_tokenId];
    }

    function getAetherBoundEvolutionStage(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "AetherForge: Token does not exist");
        return aetherBoundEvolutionStage[_tokenId];
    }

    // --- III. Curation & Reputation System ---

    function stakeAetherStoneForCuration(uint256 _amount) public whenNotPaused {
        require(_amount >= curationStakeAmount, "AetherForge: Must stake at least minimum curation amount");
        require(aetherStone.balanceOf(msg.sender) >= _amount, "AetherForge: Insufficient AetherStone balance");
        
        // Prevent double staking if already staked beyond the minimum
        if (stakedAetherStone[msg.sender] > 0) {
            revert("AetherForge: Already staked. Unstake first to change amount.");
        }

        aetherStone.transferFrom(msg.sender, address(this), _amount);
        stakedAetherStone[msg.sender] = _amount;
        unstakeTimestamp[msg.sender] = block.timestamp + curationLockupDuration;

        emit AetherStoneStaked(msg.sender, _amount);
    }

    function unstakeAetherStoneFromCuration() public {
        uint256 staked = stakedAetherStone[msg.sender];
        require(staked > 0, "AetherForge: No AetherStone staked for curation");
        require(block.timestamp >= unstakeTimestamp[msg.sender], "AetherForge: Staked tokens are still locked");

        stakedAetherStone[msg.sender] = 0;
        unstakeTimestamp[msg.sender] = 0;
        require(aetherStone.transfer(msg.sender, staked), "AetherForge: AEST unstake transfer failed");

        emit AetherStoneUnstaked(msg.sender, uint224(staked)); // Cast to uint224 for event
    }

    function submitCurationVote(uint256 _submissionId, uint8 _score) public onlyCurator {
        CurationSubmission storage submission = curationSubmissions[_submissionId];
        require(submission.dataHash != bytes32(0), "AetherForge: Submission does not exist");
        require(!submission.finalized, "AetherForge: Submission already finalized");
        require(!hasVotedOnSubmission[_submissionId][msg.sender], "AetherForge: Already voted on this submission");
        require(_score <= 100, "AetherForge: Score must be between 0 and 100");

        submission.totalScore += _score;
        submission.voteCount++;
        hasVotedOnSubmission[_submissionId][msg.sender] = true;

        // Simple reputation update: good votes increase, bad votes decrease
        // This logic can be much more complex (e.g., quadratic voting, reputation decay, etc.)
        // For simplicity, let's say a score >= 70 is 'good', <= 30 is 'bad'
        if (_score >= 70) {
            curatorReputation[msg.sender] += 10;
        } else if (_score <= 30) {
            curatorReputation[msg.sender] -= 5;
        }
        emit CuratorReputationUpdated(msg.sender, curatorReputation[msg.sender]);
        emit CurationVoteCast(_submissionId, msg.sender, _score);
    }

    function getCuratorReputation(address _user) public view returns (int256) {
        return curatorReputation[_user];
    }

    function claimCurationRewards() public {
        uint256 rewards = curatorRewards[msg.sender];
        require(rewards > 0, "AetherForge: No rewards to claim");
        curatorRewards[msg.sender] = 0;
        require(aetherStone.transfer(msg.sender, rewards), "AetherForge: AEST reward transfer failed");
        emit RewardsClaimed(msg.sender, rewards);
    }

    function getPendingCurationSubmissions() public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < pendingCurationSubmissions.length; i++) {
            if (!curationSubmissions[pendingCurationSubmissions[i]].finalized) {
                count++;
            }
        }

        uint256[] memory activeSubmissions = new uint256[](count);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < pendingCurationSubmissions.length; i++) {
            if (!curationSubmissions[pendingCurationSubmissions[i]].finalized) {
                activeSubmissions[currentIndex] = pendingCurationSubmissions[i];
                currentIndex++;
            }
        }
        return activeSubmissions;
    }

    function finalizeCurationSubmission(uint256 _submissionId) public {
        CurationSubmission storage submission = curationSubmissions[_submissionId];
        require(submission.dataHash != bytes32(0), "AetherForge: Submission does not exist");
        require(!submission.finalized, "AetherForge: Submission already finalized");
        require(submission.voteCount >= minVotesForCuration, "AetherForge: Not enough votes yet");

        int256 averageScore = int256(submission.totalScore) / int256(submission.voteCount);
        submission.approved = (averageScore >= 60); // Example threshold for approval

        if (submission.approved) {
            // Apply the new data to the AetherBound NFT
            if (submission.dataType == 0) { // Trait
                aetherBoundTraitHashes[submission.tokenId].push(submission.dataHash);
            } else { // Narrative
                aetherBoundNarrativeHashes[submission.tokenId].push(submission.dataHash);
                aetherBoundEvolutionStage[submission.tokenId]++; // Increment stage for narrative updates
            }
            // Reward curators who voted accurately
            _distributeCurationRewards(submission.tokenId); // Simplified: distribute to all active curators
        } else {
            // Penalize curators who voted for rejected content (or do nothing)
            // For simplicity, no specific penalty, just no reward for this one
        }

        submission.finalized = true;
        
        // Remove from pending list (conceptual, in practice might just mark as finalized)
        // This is inefficient for large arrays, but simple for example
        for (uint256 i = 0; i < pendingCurationSubmissions.length; i++) {
            if (pendingCurationSubmissions[i] == _submissionId) {
                pendingCurationSubmissions[i] = pendingCurationSubmissions[pendingCurationSubmissions.length - 1];
                pendingCurationSubmissions.pop();
                break;
            }
        }

        emit CurationSubmissionFinalized(_submissionId, submission.approved, averageScore);
        if(submission.approved) {
             emit AetherBoundEvolved(submission.tokenId, aetherBoundEvolutionStage[submission.tokenId], 
                                     submission.dataType == 0 ? submission.dataHash : bytes32(0),
                                     submission.dataType == 1 ? submission.dataHash : bytes32(0));
        }
    }

    function _distributeCurationRewards(uint256 _tokenId) internal {
        // This is a simplified reward distribution. In a real system:
        // - Rewards would come from a pool (e.g., a portion of forge/evolution fees).
        // - Distribution would be based on individual curator's accuracy/stake.
        // For now, let's just give a fixed small reward to active curators.
        uint256 rewardPerCurator = 10 * (10 ** aetherStone.decimals()); // Example: 10 AEST
        
        uint256 totalStaked = 0;
        for (uint256 i = 0; i < ERC721Enumerable.totalSupply(); i++) { // Iterate all token owners or get all curators
            address owner = ownerOf(tokenByIndex(i)); // This isn't efficient for getting all curators. Better to keep a list.
            if (stakedAetherStone[owner] >= curationStakeAmount) {
                curatorRewards[owner] += rewardPerCurator;
            }
        }
    }

    // --- IV. AI Oracle Interaction & Data Management ---

    // This is the callback from the trusted AI Oracle for a forge request
    function fulfillForgeRequest(
        uint256 _requestId,
        uint256 _tokenId,
        bytes32 _initialTraitHash,
        bytes32 _initialNarrativeHash
    ) public onlyTrustedOracle {
        OracleRequest storage req = oracleRequests[_requestId];
        require(!req.fulfilled, "AetherForge: Request already fulfilled");
        require(req.requestType == RequestType.Forge, "AetherForge: Not a forge request");
        require(req.tokenId == _tokenId, "AetherForge: Token ID mismatch");

        req.fulfilled = true;
        tokenPendingRequest[_tokenId] = 0; // Clear pending request

        aetherBoundTraitHashes[_tokenId].push(_initialTraitHash);
        aetherBoundNarrativeHashes[_tokenId].push(_initialNarrativeHash);

        // Register these outputs for community curation
        uint256 traitSubmissionId = _submissionIdCounter.current();
        _submissionIdCounter.increment();
        curationSubmissions[traitSubmissionId] = CurationSubmission({
            tokenId: _tokenId,
            oracleRequestId: _requestId,
            dataHash: _initialTraitHash,
            dataType: 0, // 0 for trait
            totalScore: 0,
            voteCount: 0,
            finalized: false,
            approved: false
        });
        pendingCurationSubmissions.push(traitSubmissionId);

        uint256 narrativeSubmissionId = _submissionIdCounter.current();
        _submissionIdCounter.increment();
        curationSubmissions[narrativeSubmissionId] = CurationSubmission({
            tokenId: _tokenId,
            oracleRequestId: _requestId,
            dataHash: _initialNarrativeHash,
            dataType: 1, // 1 for narrative
            totalScore: 0,
            voteCount: 0,
            finalized: false,
            approved: false
        });
        pendingCurationSubmissions.push(narrativeSubmissionId);

        emit OracleRequestFulfilled(_requestId, _tokenId, _initialTraitHash); // Emit for primary hash, others are also part of fulfillment
    }

    // This is the callback from the trusted AI Oracle for an evolution request
    function fulfillEvolutionRequest(
        uint256 _requestId,
        uint256 _tokenId,
        bytes32 _newTraitHash,
        bytes32 _newNarrativeHash
    ) public onlyTrustedOracle {
        OracleRequest storage req = oracleRequests[_requestId];
        require(!req.fulfilled, "AetherForge: Request already fulfilled");
        require(req.requestType == RequestType.Evolution, "AetherForge: Not an evolution request");
        require(req.tokenId == _tokenId, "AetherForge: Token ID mismatch");

        req.fulfilled = true;
        tokenPendingRequest[_tokenId] = 0; // Clear pending request

        // Add new traits/narrative segments for curation review
        uint256 traitSubmissionId = _submissionIdCounter.current();
        _submissionIdCounter.increment();
        curationSubmissions[traitSubmissionId] = CurationSubmission({
            tokenId: _tokenId,
            oracleRequestId: _requestId,
            dataHash: _newTraitHash,
            dataType: 0,
            totalScore: 0,
            voteCount: 0,
            finalized: false,
            approved: false
        });
        pendingCurationSubmissions.push(traitSubmissionId);

        uint256 narrativeSubmissionId = _submissionIdCounter.current();
        _submissionIdCounter.increment();
        curationSubmissions[narrativeSubmissionId] = CurationSubmission({
            tokenId: _tokenId,
            oracleRequestId: _requestId,
            dataHash: _newNarrativeHash,
            dataType: 1,
            totalScore: 0,
            voteCount: 0,
            finalized: false,
            approved: false
        });
        pendingCurationSubmissions.push(narrativeSubmissionId);

        emit OracleRequestFulfilled(_requestId, _tokenId, _newTraitHash);
    }

    function getOracleRequestIdForToken(uint256 _tokenId) public view returns (uint256) {
        return tokenPendingRequest[_tokenId];
    }
    
    // --- V. AetherStone Token (ERC-20) Integration ---

    function AetherStone() public view returns (address) {
        return address(aetherStone);
    }

    function getForgePrice() public view returns (uint256) {
        return forgePrice;
    }

    function getEvolutionPrice() public view returns (uint256) {
        return evolutionPrice;
    }
}
```