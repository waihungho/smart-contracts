The `AetherForge` protocol is a decentralized ecosystem for generative content creation, where users contribute "Creative Seeds" (NFTs), trigger AI-powered "Evolutions" to generate new "Evolved Creations" (NFTs), and build a "Reputation" (Soulbound Tokens - SBTs) based on their contributions and community interactions. The protocol incorporates staking, dynamic royalties, and a DAO-like governance structure for approval and parameter adjustments, driven by an off-chain AI oracle.

The contract is designed to be highly modular, using OpenZeppelin's battle-tested libraries for core ERC functionalities while implementing unique business logic for the AetherForge ecosystem. The sub-contracts (`AetherSeed`, `AetherCreation`, `AetherReputationBadge`) are deployed separately and managed by the main `AetherForge` contract.

---

**Outline:**

1.  **Core Assets & Identity**: Interfaces for the AetherSeed (ERC721), AetherCreation (ERC721 with ERC2981 royalties), and AetherReputationBadge (ERC1155 Soulbound Token) contracts.
2.  **AetherForge Main Contract**: The central hub managing interactions between users, NFTs, SBTs, staking, oracle, and governance.
3.  **Supporting Contracts**:
    *   `AetherSeed`: ERC721 for Creative Seeds, managed by AetherForge.
    *   `AetherCreation`: ERC721 for Evolved Creations, with ERC2981 royalties dynamically set based on the parent seed, managed by AetherForge.
    *   `AetherReputationBadge`: ERC1155 for Soulbound Reputation Badges, non-transferable and managed by AetherForge.

---

**Function Summary (AetherForge Main Contract):**

**I. Constructor & Setup**
1.  `constructor()`: Initializes the contract, sets the initial admin (`owner()`), references deployed NFT/SBT contracts, and sets the trusted oracle address. Sets the `owner()` as initial `governanceAddress`.
2.  `setGovernanceAddress(address _newGovernance)`: Allows the `owner()` to transfer governance responsibilities to a dedicated DAO or multi-sig contract.

**II. Creative Seed Management (ERC721 - `AetherSeed` Interface)**
3.  `submitCreativeSeed(string memory _tokenURI)`: Allows a user to mint a new `AetherSeed` NFT by providing its metadata URI. Requires a minimum ETH stake, which is locked for a period.
4.  `approveCreativeSeed(uint256 _seedId)`: **Governance Function**. Marks a submitted seed as "approved", making it available for evolution requests.
5.  `revokeCreativeSeed(uint256 _seedId)`: **Governance Function**. Marks an approved seed as "revoked" (e.g., for policy violation), preventing further evolutions.
6.  `getSeedDetails(uint256 _seedId)`: View function to retrieve all details (URI, fees, royalties, approval status, creator) associated with a specific `AetherSeed`.
7.  `setSeedEvolutionFee(uint256 _seedId, uint256 _fee)`: The owner of an approved seed (or Governance) can set the ETH fee required to evolve that specific seed.
8.  `setSeedRoyaltyPercentage(uint256 _seedId, uint96 _royaltyBasisPoints)`: The owner of an approved seed (or Governance) can set the royalty percentage (in basis points) for subsequent sales of creations derived from this seed, adhering to ERC2981.

**III. Evolved Creation & AI Integration (ERC721 - `AetherCreation` Interface & Oracle)**
9.  `requestSeedEvolution(uint256 _seedId, string memory _evolutionParams, uint256 _generationGasLimit)`: Users pay the `_seedEvolutionFee` to request an AI evolution based on an approved seed and specific parameters. Emits an event to be picked up by the off-chain oracle.
10. `fulfillEvolutionRequest(uint256 _requestId, address _requester, uint256 _seedId, string memory _generatedURI, bytes32 _creationHash, string memory _modelInfo)`: **Oracle-only function**. Called by the trusted oracle to mint a new `AetherCreation` NFT after the off-chain AI process completes, linking it to the original request and seed.
11. `getCreationDetails(uint256 _creationId)`: View function to retrieve all details associated with a specific `AetherCreation`.
12. `getPendingEvolutionRequest(uint256 _requestId)`: View function to retrieve details of a pending evolution request.

**IV. Reputation System (ERC1155 - `AetherReputationBadge` - SBTs)**
13. `awardReputationBadge(address _recipient, uint256 _badgeTypeId, uint256 _amount, string memory _reasonURI)`: **Governance Function**. Mints non-transferable `AetherReputationBadge` SBTs to users based on contributions or activities.
14. `getReputationScore(address _user)`: Aggregates the value of all badges held by a user to provide an overall reputation score. (Assumes badge type 1 as primary score with values set in `AetherReputationBadge`).
15. `hasMinimumReputation(address _user, uint256 _minScore)`: Checks if a user's reputation score meets a specified minimum, useful for gated access to certain protocol functions (e.g., submitting proposals).
16. `revokeReputationBadge(address _recipient, uint256 _badgeTypeId, uint256 _amount)`: **Governance Function**. Allows burning specific reputation badges, typically for policy violations.

**V. Staking & Financials**
17. `stakeForContribution(uint256 _amount)`: Users stake native tokens (ETH) to gain access to protocol functions (e.g., submitting seeds, voting) and signal commitment.
18. `unstakeContribution(uint256 _amount)`: Allows users to unstake their ETH after a predefined lock-up period has passed.
19. `withdrawProtocolFees()`: **Governance Function**. Allows the `governanceAddress` to withdraw accumulated protocol fees (from evolution requests and royalty shares).
20. `distributeSeedRoyalties(uint256 _creationId, uint256 _salePrice)`: Facilitates the distribution of royalties from secondary sales of `AetherCreation` NFTs to the original `AetherSeed` creator and the protocol treasury, using ERC2981 standards.

**VI. Governance & Protocol Settings**
21. `submitGovernanceProposal(address _target, bytes memory _calldata, string memory _description)`: Allows users with sufficient staked tokens and reputation to propose changes to protocol parameters or actions.
22. `voteOnProposal(uint256 _proposalId, bool _support)`: Stakers cast their vote (for or against) on an active proposal. Voting power is proportional to their staked amount.
23. `executeProposal(uint256 _proposalId)`: Anyone can call this function to execute an approved proposal after its voting period ends and quorum is met.
24. `setOracleAddress(address _newOracle)`: **Governance Function**. Allows updating the trusted address of the AI oracle.
25. `setMinimumSeedStake(uint256 _newStake)`: **Governance Function**. Adjusts the minimum ETH stake required to submit a creative seed.
26. `setContributionLockupDuration(uint256 _duration)`: **Governance Function**. Sets the lock-up period for staked contributions (in seconds).

**VII. Admin & Emergency**
27. `pause()`: **Owner Function**. Pauses sensitive functions of the contract in emergencies.
28. `unpause()`: **Owner Function**. Unpauses the contract after an emergency.
29. `emergencyWithdrawERC20(address _token, address _to, uint256 _amount)`: **Owner Function**. Allows rescuing accidentally sent ERC20 tokens to the contract address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For emergencyWithdrawERC20
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Base for AetherSeed/Creation
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol"; // For AetherCreation's ERC2981
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol"; // Base for AetherReputationBadge
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Interfaces for Managed Contracts ---

// Interface for the AetherSeed NFT contract (ERC721)
interface IAetherSeed {
    function mint(address to, string memory tokenURI) external returns (uint256);
    function setSeedEvolutionFee(uint256 seedId, uint256 fee) external;
    function setSeedRoyaltyPercentage(uint256 seedId, uint96 royaltyBasisPoints) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function getSeedData(uint256 seedId) external view returns (string memory tokenURI, uint256 evolutionFee, uint96 royaltyBasisPoints, bool approved, address creator);
    function setSeedApproved(uint256 seedId, bool approved) external;
}

// Interface for the AetherCreation NFT contract (ERC721 with ERC2981)
interface IAetherCreation {
    function mint(address to, uint256 seedId, string memory tokenURI, bytes32 creationHash, string memory modelInfo) external returns (uint256);
    function getCreationData(uint256 creationId) external view returns (uint256 seedId, string memory tokenURI, bytes32 creationHash, string memory modelInfo, address creator);
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount); // ERC2981
}

// Interface for the AetherReputationBadge SBT contract (ERC1155 Soulbound)
interface IAetherReputationBadge {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function getBadgeValue(uint256 badgeId) external view returns (uint256);
    function setBadgeValue(uint256 badgeId, uint256 value) external;
}

// --- Main Contract: AetherForge ---

contract AetherForge is Ownable2Step, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Managed NFT/SBT contract instances
    IAetherSeed public aetherSeedNFT;
    IAetherCreation public aetherCreationNFT;
    IAetherReputationBadge public aetherReputationBadgeSBT;

    // External addresses
    address public oracleAddress; // Address of the trusted AI oracle
    address public governanceAddress; // Address of the DAO or governance entity

    // Staking configuration
    uint256 public minSeedStake = 1 ether; // Minimum ETH to stake for submitting a creative seed
    uint256 public contributionLockupDuration = 7 days; // Lock-up period for staked ETH
    mapping(address => uint256) public userStakes; // Amount of ETH staked by each user
    mapping(address => uint256) public stakeUnlockTime; // Timestamp when a user's stake can be unlocked

    // Evolution request tracking
    struct EvolutionRequest {
        address requester;
        uint256 seedId;
        string evolutionParams;
        uint256 creationId; // 0 if not yet fulfilled
        bool fulfilled;
        uint256 generationGasLimit; // Max gas the oracle commits to for generation
    }
    Counters.Counter private _evolutionRequestIds;
    mapping(uint256 => EvolutionRequest) public evolutionRequests;

    // Protocol Fees
    uint96 public protocolFeeBasisPoints = 500; // 5% (500 basis points out of 10,000)
    uint256 public totalProtocolFeesCollected; // Accumulated fees in ETH

    // Governance Proposals
    struct Proposal {
        address target; // Target contract for the proposal's execution
        bytes calldataPayload; // Encoded function call for execution
        string description; // Description of the proposal
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes; // Total staked tokens voting 'for'
        uint256 againstVotes; // Total staked tokens voting 'against'
        bool executed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        uint256[49] _gap; // Storage gap to prevent collisions with `hasVoted` mapping
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingPeriodDuration = 3 days; // Duration for voting on a proposal
    uint256 public minProposalStake = 10 ether; // Minimum stake to submit a proposal
    uint256 public proposalQuorumPercentage = 20; // % of total staked tokens needed for quorum

    // --- Events ---
    event CreativeSeedSubmitted(uint256 indexed seedId, address indexed creator, string tokenURI, uint256 stakeAmount);
    event CreativeSeedApproved(uint256 indexed seedId, address indexed approver);
    event CreativeSeedRevoked(uint256 indexed seedId, address indexed revoker);
    event SeedEvolutionRequested(uint256 indexed requestId, address indexed requester, uint256 indexed seedId, string evolutionParams, uint256 feePaid, uint256 generationGasLimit);
    event EvolutionFulfilled(uint256 indexed requestId, uint256 indexed creationId, address indexed requester, uint256 seedId, string generatedURI, bytes32 creationHash, string modelInfo);
    event ReputationBadgeAwarded(address indexed recipient, uint256 indexed badgeTypeId, uint256 amount, string reasonURI);
    event ReputationBadgeRevoked(address indexed recipient, uint256 indexed badgeTypeId, uint256 amount);
    event TokensStaked(address indexed user, uint256 amount, uint256 unlockTime);
    event TokensUnstaked(address indexed user, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event SeedRoyaltiesDistributed(uint256 indexed creationId, address indexed seedCreator, uint256 seedCreatorRoyalty, address indexed protocolTreasury, uint256 protocolRoyalty);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event MinimumSeedStakeUpdated(uint256 oldStake, uint256 newStake);
    event ContributionLockupDurationUpdated(uint256 oldDuration, uint256 newDuration);
    event GovernanceAddressUpdated(address indexed oldGovernance, address indexed newGovernance);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetherForge: Only oracle can call this function");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "AetherForge: Only governance can call this function");
        _;
    }

    // --- I. Constructor & Setup ---

    constructor(
        address _aetherSeedNFT,
        address _aetherCreationNFT,
        address _aetherReputationBadgeSBT,
        address _oracleAddress
    ) Ownable2Step(msg.sender) {
        require(_aetherSeedNFT != address(0), "AetherForge: Invalid AetherSeed NFT address");
        require(_aetherCreationNFT != address(0), "AetherForge: Invalid AetherCreation NFT address");
        require(_aetherReputationBadgeSBT != address(0), "AetherForge: Invalid AetherReputationBadge SBT address");
        require(_oracleAddress != address(0), "AetherForge: Invalid Oracle address");

        aetherSeedNFT = IAetherSeed(_aetherSeedNFT);
        aetherCreationNFT = IAetherCreation(_aetherCreationNFT);
        aetherReputationBadgeSBT = IAetherReputationBadge(_aetherReputationBadgeSBT);
        oracleAddress = _oracleAddress;
        governanceAddress = msg.sender; // Initially set owner as governance, can be changed later
    }

    // 2. setGovernanceAddress
    function setGovernanceAddress(address _newGovernance) external onlyOwner {
        require(_newGovernance != address(0), "AetherForge: New governance address cannot be zero");
        emit GovernanceAddressUpdated(governanceAddress, _newGovernance);
        governanceAddress = _newGovernance;
    }

    // --- II. Creative Seed Management (ERC721 - AetherSeed) ---

    // 3. submitCreativeSeed
    function submitCreativeSeed(string memory _tokenURI) external payable whenNotPaused nonReentrant returns (uint256) {
        require(msg.value >= minSeedStake, "AetherForge: Insufficient stake for seed submission");
        
        uint256 newSeedId = aetherSeedNFT.mint(msg.sender, _tokenURI);

        userStakes[msg.sender] = userStakes[msg.sender].add(msg.value);
        stakeUnlockTime[msg.sender] = block.timestamp.add(contributionLockupDuration);

        emit CreativeSeedSubmitted(newSeedId, msg.sender, _tokenURI, msg.value);
        return newSeedId;
    }

    // 4. approveCreativeSeed
    function approveCreativeSeed(uint256 _seedId) external onlyGovernance {
        (,,,,, bool approvedStatus,) = aetherSeedNFT.getSeedDetails(_seedId);
        require(!approvedStatus, "AetherForge: Seed is already approved");
        aetherSeedNFT.setSeedApproved(_seedId, true);
        emit CreativeSeedApproved(_seedId, msg.sender);
    }

    // 5. revokeCreativeSeed
    function revokeCreativeSeed(uint256 _seedId) external onlyGovernance {
        (,,,,, bool approvedStatus,) = aetherSeedNFT.getSeedDetails(_seedId);
        require(approvedStatus, "AetherForge: Seed is not currently approved");
        aetherSeedNFT.setSeedApproved(_seedId, false);
        emit CreativeSeedRevoked(_seedId, msg.sender);
    }

    // 6. getSeedDetails
    function getSeedDetails(uint256 _seedId) external view returns (string memory tokenURI, uint256 evolutionFee, uint96 royaltyBasisPoints, bool approved, address creator) {
        return aetherSeedNFT.getSeedData(_seedId);
    }

    // 7. setSeedEvolutionFee
    function setSeedEvolutionFee(uint256 _seedId, uint256 _fee) external whenNotPaused {
        address seedOwner = aetherSeedNFT.ownerOf(_seedId);
        // Allows both the seed owner and governance to set the fee
        require(msg.sender == seedOwner || msg.sender == governanceAddress, "AetherForge: Only seed owner or governance can set evolution fee");
        aetherSeedNFT.setSeedEvolutionFee(_seedId, _fee);
    }

    // 8. setSeedRoyaltyPercentage
    function setSeedRoyaltyPercentage(uint256 _seedId, uint96 _royaltyBasisPoints) external whenNotPaused {
        require(_royaltyBasisPoints <= 10000, "AetherForge: Royalty cannot exceed 100%");
        address seedOwner = aetherSeedNFT.ownerOf(_seedId);
        // Allows both the seed owner and governance to set the royalty
        require(msg.sender == seedOwner || msg.sender == governanceAddress, "AetherForge: Only seed owner or governance can set royalty");
        aetherSeedNFT.setSeedRoyaltyPercentage(_seedId, _royaltyBasisPoints);
    }

    // --- III. Evolved Creation & AI Integration (ERC721 - AetherCreation & Oracle) ---

    // 9. requestSeedEvolution
    function requestSeedEvolution(uint256 _seedId, string memory _evolutionParams, uint256 _generationGasLimit) external payable whenNotPaused nonReentrant returns (uint256) {
        (,,,,, bool approvedStatus,) = aetherSeedNFT.getSeedDetails(_seedId);
        require(approvedStatus, "AetherForge: Seed is not approved for evolution");

        (, uint256 evolutionFee,,,,) = aetherSeedNFT.getSeedDetails(_seedId);
        require(msg.value >= evolutionFee, "AetherForge: Insufficient payment for evolution fee");

        // Collect protocol fee from the total value sent
        uint256 protocolShare = evolutionFee.mul(protocolFeeBasisPoints).div(10000);
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(protocolShare);
        
        // The remaining `msg.value - protocolShare` is implicitly held by this contract
        // until distributed or withdrawn by governance.

        uint256 requestId = _evolutionRequestIds.current();
        _evolutionRequestIds.increment();

        evolutionRequests[requestId] = EvolutionRequest({
            requester: msg.sender,
            seedId: _seedId,
            evolutionParams: _evolutionParams,
            creationId: 0,
            fulfilled: false,
            generationGasLimit: _generationGasLimit
        });

        emit SeedEvolutionRequested(requestId, msg.sender, _seedId, _evolutionParams, msg.value, _generationGasLimit);
        return requestId;
    }

    // 10. fulfillEvolutionRequest
    function fulfillEvolutionRequest(
        uint256 _requestId,
        address _requester,
        uint256 _seedId,
        string memory _generatedURI,
        bytes32 _creationHash,
        string memory _modelInfo
    ) external onlyOracle whenNotPaused nonReentrant {
        EvolutionRequest storage req = evolutionRequests[_requestId];
        require(req.requester == _requester, "AetherForge: Requester mismatch");
        require(req.seedId == _seedId, "AetherForge: Seed ID mismatch");
        require(!req.fulfilled, "AetherForge: Evolution request already fulfilled");

        uint256 newCreationId = aetherCreationNFT.mint(_requester, _seedId, _generatedURI, _creationHash, _modelInfo);

        req.creationId = newCreationId;
        req.fulfilled = true;

        emit EvolutionFulfilled(_requestId, newCreationId, _requester, _seedId, _generatedURI, _creationHash, _modelInfo);
    }

    // 11. getCreationDetails
    function getCreationDetails(uint256 _creationId) external view returns (uint256 seedId, string memory tokenURI, bytes32 creationHash, string memory modelInfo, address creator) {
        return aetherCreationNFT.getCreationData(_creationId);
    }

    // 12. getPendingEvolutionRequest
    function getPendingEvolutionRequest(uint256 _requestId) external view returns (EvolutionRequest memory) {
        require(_requestId < _evolutionRequestIds.current(), "AetherForge: Invalid request ID");
        return evolutionRequests[_requestId];
    }

    // --- IV. Reputation System (ERC1155 - AetherReputationBadge - SBTs) ---

    // 13. awardReputationBadge
    function awardReputationBadge(address _recipient, uint256 _badgeTypeId, uint256 _amount, string memory _reasonURI) external onlyGovernance whenNotPaused {
        require(_recipient != address(0), "AetherForge: Cannot award to zero address");
        require(_amount > 0, "AetherForge: Amount must be greater than zero");
        aetherReputationBadgeSBT.mint(_recipient, _badgeTypeId, _amount, abi.encodePacked(_reasonURI));
        emit ReputationBadgeAwarded(_recipient, _badgeTypeId, _amount, _reasonURI);
    }

    // 14. getReputationScore
    function getReputationScore(address _user) public view returns (uint256) {
        // For simplicity, reputation score is based on a primary "Contributor" badge (ID 1)
        // weighted by its assigned value. A real system might aggregate multiple badge types.
        uint256 badgeAmount = aetherReputationBadgeSBT.balanceOf(_user, 1);
        uint256 badgeValue = aetherReputationBadgeSBT.getBadgeValue(1);
        return badgeAmount.mul(badgeValue);
    }

    // 15. hasMinimumReputation
    function hasMinimumReputation(address _user, uint256 _minScore) public view returns (bool) {
        return getReputationScore(_user) >= _minScore;
    }

    // 16. revokeReputationBadge
    function revokeReputationBadge(address _recipient, uint256 _badgeTypeId, uint256 _amount) external onlyGovernance whenNotPaused {
        require(_recipient != address(0), "AetherForge: Cannot burn from zero address");
        require(_amount > 0, "AetherForge: Amount must be greater than zero");
        aetherReputationBadgeSBT.burn(_recipient, _badgeTypeId, _amount);
        emit ReputationBadgeRevoked(_recipient, _badgeTypeId, _amount);
    }

    // --- V. Staking & Financials ---

    // 17. stakeForContribution
    function stakeForContribution(uint256 _amount) public payable whenNotPaused nonReentrant {
        require(msg.value == _amount, "AetherForge: Sent ETH must match stake amount");
        require(_amount > 0, "AetherForge: Stake amount must be greater than zero");

        userStakes[msg.sender] = userStakes[msg.sender].add(_amount);
        stakeUnlockTime[msg.sender] = block.timestamp.add(contributionLockupDuration);
        emit TokensStaked(msg.sender, _amount, stakeUnlockTime[msg.sender]);
    }

    // 18. unstakeContribution
    function unstakeContribution(uint256 _amount) external whenNotPaused nonReentrant {
        require(userStakes[msg.sender] >= _amount, "AetherForge: Insufficient staked amount");
        require(block.timestamp >= stakeUnlockTime[msg.sender], "AetherForge: Stake is still locked");
        require(_amount > 0, "AetherForge: Unstake amount must be greater than zero");

        userStakes[msg.sender] = userStakes[msg.sender].sub(_amount);
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "AetherForge: ETH transfer failed");
        emit TokensUnstaked(msg.sender, _amount);
    }

    // 19. withdrawProtocolFees
    function withdrawProtocolFees() external onlyGovernance whenNotPaused nonReentrant {
        require(totalProtocolFeesCollected > 0, "AetherForge: No fees to withdraw");
        uint256 fees = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;

        (bool success,) = governanceAddress.call{value: fees}("");
        require(success, "AetherForge: Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(governanceAddress, fees);
    }

    // 20. distributeSeedRoyalties
    function distributeSeedRoyalties(uint256 _creationId, uint256 _salePrice) external whenNotPaused nonReentrant {
        require(_salePrice > 0, "AetherForge: Sale price must be positive");

        (address royaltyRecipient, uint252 royaltyAmount) = aetherCreationNFT.royaltyInfo(_creationId, _salePrice);
        
        require(royaltyRecipient != address(0) && royaltyAmount > 0, "AetherForge: No royalties or invalid recipient");

        // The royaltyRecipient returned by ERC2981 `royaltyInfo` is the seed owner.
        // We then apply the protocol's cut from this royalty.
        uint256 protocolRoyaltyShare = royaltyAmount.mul(protocolFeeBasisPoints).div(10000);
        uint256 seedCreatorShare = royaltyAmount.sub(protocolRoyaltyShare);

        totalProtocolFeesCollected = totalProtocolFeesCollected.add(protocolRoyaltyShare);

        if (seedCreatorShare > 0) {
            (bool successCreator,) = royaltyRecipient.call{value: seedCreatorShare}("");
            require(successCreator, "AetherForge: Seed creator royalty transfer failed");
        }
        
        emit SeedRoyaltiesDistributed(_creationId, royaltyRecipient, seedCreatorShare, address(this), protocolRoyaltyShare);
    }

    // --- VI. Governance & Protocol Settings ---

    // 21. submitGovernanceProposal
    function submitGovernanceProposal(address _target, bytes memory _calldata, string memory _description) external payable whenNotPaused {
        require(userStakes[msg.sender] >= minProposalStake, "AetherForge: Insufficient stake to submit proposal");
        require(hasMinimumReputation(msg.sender, 100), "AetherForge: Insufficient reputation to submit proposal (min 100 score)"); // Example: min 100 rep score

        uint256 proposalId = _proposalIds.current();
        _proposalIds.increment();

        proposals[proposalId] = Proposal({
            target: _target,
            calldataPayload: _calldata,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(votingPeriodDuration),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            _gap: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] // _gap for storage layout
        });

        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description);
    }

    // 22. voteOnProposal
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStartTime != 0, "AetherForge: Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime, "AetherForge: Voting has not started");
        require(block.timestamp < proposal.voteEndTime, "AetherForge: Voting has ended");
        require(userStakes[msg.sender] > 0, "AetherForge: Must have staked tokens to vote");
        require(!proposal.hasVoted[msg.sender], "AetherForge: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.forVotes = proposal.forVotes.add(userStakes[msg.sender]);
        } else {
            proposal.againstVotes = proposal.againstVotes.sub(userStakes[msg.sender]); // Subtract from against if voting against
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    // 23. executeProposal
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStartTime != 0, "AetherForge: Proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "AetherForge: Voting period not ended");
        require(!proposal.executed, "AetherForge: Proposal already executed");

        uint256 totalStakedTokens = address(this).balance; // Simplified: Using contract balance as proxy for total staked
        // A more robust DAO would track total voting power using a dedicated token's totalSupply or iterating userStakes (off-chain)
        
        uint256 totalVotesCast = proposal.forVotes.add(proposal.againstVotes);
        require(totalVotesCast.mul(100).div(totalStakedTokens) >= proposalQuorumPercentage, "AetherForge: Quorum not met");
        require(proposal.forVotes > proposal.againstVotes, "AetherForge: Proposal not approved");

        proposal.executed = true;

        (bool success, ) = proposal.target.call(proposal.calldataPayload);
        require(success, "AetherForge: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    // 24. setOracleAddress
    function setOracleAddress(address _newOracle) external onlyGovernance whenNotPaused {
        require(_newOracle != address(0), "AetherForge: New oracle address cannot be zero");
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    // 25. setMinimumSeedStake
    function setMinimumSeedStake(uint256 _newStake) external onlyGovernance whenNotPaused {
        require(_newStake > 0, "AetherForge: Minimum stake must be greater than zero");
        emit MinimumSeedStakeUpdated(minSeedStake, _newStake);
        minSeedStake = _newStake;
    }

    // 26. setContributionLockupDuration
    function setContributionLockupDuration(uint256 _duration) external onlyGovernance whenNotPaused {
        emit ContributionLockupDurationUpdated(contributionLockupDuration, _duration);
        contributionLockupDuration = _duration;
    }

    // --- VII. Admin & Emergency ---

    // 27. pause
    function pause() public onlyOwner {
        _pause();
    }

    // 28. unpause
    function unpause() public onlyOwner {
        _unpause();
    }
    
    // 29. emergencyWithdrawERC20
    function emergencyWithdrawERC20(address _token, address _to, uint256 _amount) external onlyOwner {
        require(_token != address(0), "AetherForge: Invalid token address");
        require(_to != address(0), "AetherForge: Invalid recipient address");
        require(_token != address(aetherSeedNFT) && _token != address(aetherCreationNFT) && _token != address(aetherReputationBadgeSBT), "AetherForge: Cannot withdraw internal NFT contracts");
        
        IERC20(_token).transfer(_to, _amount);
    }

    // Fallback function to receive ETH
    receive() external payable {
        // Any direct ETH transfers to the contract are added to its balance, potentially for fees or staking.
        // It's good practice to emit an event if this is expected to happen from external sources.
    }
}


// --- Supporting Contract: AetherSeed ERC721 ---
// This contract would ideally be in its own file: `AetherSeed.sol`

contract AetherSeed is ERC721, Ownable2Step {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct SeedData {
        string tokenURI;
        uint256 evolutionFee; // Fee for evolving this specific seed
        uint96 royaltyBasisPoints; // Royalty for creations derived from this seed
        bool approved; // Whether this seed is approved by governance for evolution
        address creator; // The original creator of the seed
    }

    mapping(uint256 => SeedData) public seedData;

    constructor() ERC721("AetherSeed", "ASEED") Ownable2Step(msg.sender) {}

    function mint(address to, string memory _tokenURI) external onlyOwner returns (uint256) {
        // Only the AetherForge contract (set as owner) can mint AetherSeed NFTs
        require(msg.sender == owner(), "AetherSeed: Only AetherForge can mint seeds");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        
        seedData[newItemId] = SeedData({
            tokenURI: _tokenURI,
            evolutionFee: 0, // Default fee, can be set later by creator/governance
            royaltyBasisPoints: 0, // Default royalty, can be set later by creator/governance
            approved: false, // Must be approved by governance
            creator: to
        });
        return newItemId;
    }

    function setSeedEvolutionFee(uint256 _seedId, uint256 _fee) external onlyOwner {
        // Only the AetherForge contract can set evolution fee (delegated from seed owner or governance)
        require(_exists(_seedId), "AetherSeed: Seed does not exist");
        require(msg.sender == owner(), "AetherSeed: Only AetherForge can set evolution fee");
        seedData[_seedId].evolutionFee = _fee;
    }

    function setSeedRoyaltyPercentage(uint256 _seedId, uint96 _royaltyBasisPoints) external onlyOwner {
        // Only the AetherForge contract can set royalty (delegated from seed owner or governance)
        require(_exists(_seedId), "AetherSeed: Seed does not exist");
        require(msg.sender == owner(), "AetherSeed: Only AetherForge can set royalty percentage");
        require(_royaltyBasisPoints <= 10000, "AetherSeed: Royalty cannot exceed 100%");
        seedData[_seedId].royaltyBasisPoints = _royaltyBasisPoints;
    }

    function getSeedData(uint256 _seedId) external view returns (string memory tokenURI, uint256 evolutionFee, uint96 royaltyBasisPoints, bool approved, address creator) {
        require(_exists(_seedId), "AetherSeed: Seed does not exist");
        SeedData storage data = seedData[_seedId];
        return (data.tokenURI, data.evolutionFee, data.royaltyBasisPoints, data.approved, data.creator);
    }

    function setSeedApproved(uint256 _seedId, bool _approved) external onlyOwner {
        // Only the AetherForge contract (acting as governance) can approve/revoke seeds
        require(_exists(_seedId), "AetherSeed: Seed does not exist");
        require(msg.sender == owner(), "AetherSeed: Only AetherForge can approve/revoke seeds");
        seedData[_seedId].approved = _approved;
    }
}

// --- Supporting Contract: AetherCreation ERC721 (with ERC2981 for royalties) ---
// This contract would ideally be in its own file: `AetherCreation.sol`

contract AetherCreation is ERC721Royalty, Ownable2Step {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct CreationData {
        uint256 seedId; // The AetherSeed this creation was derived from
        string tokenURI;
        bytes32 creationHash; // Hash of the actual generated content
        string modelInfo; // Information about the AI model used
        address creator; // The address that requested the evolution
    }

    mapping(uint256 => CreationData) public creationData;
    address public aetherForgeAddress; // Reference to the main AetherForge contract
    IAetherSeed public aetherSeedNFT; // Reference to the AetherSeed contract

    constructor(address _aetherForgeAddress, address _aetherSeedNFT) ERC721("AetherCreation", "ACREA") Ownable2Step(msg.sender) {
        require(_aetherForgeAddress != address(0), "AetherCreation: Invalid AetherForge address");
        require(_aetherSeedNFT != address(0), "AetherCreation: Invalid AetherSeed NFT address");
        aetherForgeAddress = _aetherForgeAddress;
        aetherSeedNFT = IAetherSeed(_aetherSeedNFT);
    }

    function mint(address to, uint256 _seedId, string memory _tokenURI, bytes32 _creationHash, string memory _modelInfo) external onlyOwner returns (uint256) {
        // Only the AetherForge contract (set as owner) can mint AetherCreation NFTs
        require(msg.sender == aetherForgeAddress, "AetherCreation: Only AetherForge can mint creations");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        
        creationData[newItemId] = CreationData({
            seedId: _seedId,
            tokenURI: _tokenURI,
            creationHash: _creationHash,
            modelInfo: _modelInfo,
            creator: to
        });

        return newItemId;
    }

    function getCreationData(uint256 _creationId) external view returns (uint256 seedId, string memory tokenURI, bytes32 creationHash, string memory modelInfo, address creator) {
        require(_exists(_creationId), "AetherCreation: Creation does not exist");
        CreationData storage data = creationData[_creationId];
        return (data.seedId, data.tokenURI, data.creationHash, data.modelInfo, data.creator);
    }
    
    // Override ERC2981's royaltyInfo to dynamically fetch royalty receiver and basis points
    // from the parent AetherSeed NFT.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "ERC721Royalty: invalid token ID");
        
        uint256 seedId = creationData[_tokenId].seedId;
        (,, uint96 royaltyBasisPoints,,) = aetherSeedNFT.getSeedData(seedId);
        address seedOwner = aetherSeedNFT.ownerOf(seedId); // Get current owner of the parent AetherSeed

        if (seedOwner == address(0) || royaltyBasisPoints == 0) {
            return (address(0), 0); // No royalties if no owner or 0% royalty
        }

        royaltyAmount = _salePrice.mul(royaltyBasisPoints).div(10000);
        return (seedOwner, royaltyAmount);
    }
}

// --- Supporting Contract: AetherReputationBadge ERC1155 (Soulbound) ---
// This contract would ideally be in its own file: `AetherReputationBadge.sol`

contract AetherReputationBadge is ERC1155, Ownable2Step {
    constructor() ERC1155("https://aetherforge.com/reputation/{id}.json") Ownable2Step(msg.sender) {}

    // Badge Type Values (for reputation score calculation)
    mapping(uint256 => uint256) public badgeValues; // Maps badgeTypeId to its score value (e.g., 1 -> 10 points)

    // Custom URI setter for specific badge types (optional, to override base URI for types)
    mapping(uint256 => string) private _uris;

    function uri(uint256 _id) public view override returns (string memory) {
        // Returns custom URI if set, otherwise falls back to base URI
        return bytes(_uris[_id]).length > 0 ? _uris[_id] : super.uri(_id);
    }

    function _setURI(uint256 _id, string memory newURI) internal {
        _uris[_id] = newURI;
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        // Only the AetherForge contract (set as owner) can mint Reputation Badges
        require(msg.sender == owner(), "AetherReputationBadge: Only AetherForge can mint badges");
        _mint(to, id, amount, data);
        // Data can optionally contain a specific URI for this badge type
        if (data.length > 0) {
            _setURI(id, string(data));
        }
    }

    function burn(address from, uint256 id, uint256 amount) external onlyOwner {
        // Only the AetherForge contract (set as owner) can burn Reputation Badges
        require(msg.sender == owner(), "AetherReputationBadge: Only AetherForge can burn badges");
        _burn(from, id, amount);
    }

    // --- Soulbound Logic ---
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal pure override {
        // Prevent any transfers other than minting (from == address(0)) or burning (to == address(0))
        require(from == address(0) || to == address(0), "AetherReputationBadge: Soulbound tokens cannot be transferred");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    // --- End Soulbound Logic ---

    function setBadgeValue(uint256 _badgeId, uint256 _value) external onlyOwner {
        // Only AetherForge contract can set badge values
        require(msg.sender == owner(), "AetherReputationBadge: Only AetherForge can set badge values");
        badgeValues[_badgeId] = _value;
    }

    function getBadgeValue(uint256 _badgeId) external view returns (uint256) {
        return badgeValues[_badgeId];
    }
}
```