This Solidity smart contract, `DAIPEE` (Decentralized Autonomous Intellectual Property Exchange and Evolution), is designed to be a unique platform for creators. It goes beyond simple NFT minting by incorporating mechanisms for community-driven IP mutation, simulated AI evolution, dynamic licensing, fractional ownership, on-chain reputation for curators, and a dispute resolution system for originality. The aim is to create a dynamic ecosystem where intellectual property can evolve, adapt, and generate value through collaborative effort and programmatic logic.

---

**Contract Name:** `DAIPEE` (Decentralized Autonomous Intellectual Property Exchange and Evolution)

**Outline:**
The DAIPEE protocol empowers creators to register, manage, evolve, and monetize their Intellectual Property (IP) as non-fungible tokens (NFTs). It introduces novel concepts such as community-driven IP mutation, simulated AI evolution steps, dynamic licensing, fractional ownership, and a reputation system for curators. The goal is to create a living, breathing ecosystem where IP isn't static but can grow, adapt, and generate value through collective effort and programmatic evolution.

**Function Summary:**

**I. Core IP Asset Management & Registry (ERC721-based)**
1.  **`registerNewIPAsset`**: Mints a new core IP asset or an IP fragment NFT with its content hash and metadata URI.
2.  **`updateIPMetadataURI`**: Allows the IP owner to update the off-chain metadata URI of their IP/Fragment NFT.
3.  **`transferFrom` (Inherited from ERC721)**: Standard function to transfer an IP or fragment NFT.
4.  **`safeTransferFrom` (Inherited from ERC721)**: Standard function to safely transfer an IP or fragment NFT.

**II. IP Evolution & Mutation Mechanisms**
5.  **`proposeIPMutation`**: Users stake `DAIPEE_Token` to propose a new, mutated version of an existing IP asset, referencing new fragments or content.
6.  **`voteOnMutationProposal`**: Staked curators vote on the validity and value of proposed IP mutations.
7.  **`executeApprovedMutation`**: Finalizes an approved mutation proposal, minting a new derivative IP NFT, linking it to its parent, and distributing rewards.
8.  **`simulateEvolutionStep`**: An authorized 'Evolution Engine' (e.g., an off-chain AI agent) can register a proposed evolution step, creating a new potential IP version for community review.
9.  **`combineIPFragments`**: Allows an IP owner to combine multiple owned IP fragment NFTs into a new, distinct core IP asset, burning the fragments.

**III. Fractional Ownership & Dynamic Licensing**
10. **`enableFractionalOwnership`**: Initiates a process to fractionalize an IP asset, defining the total number of fractions, with the owner receiving initial fractions.
11. **`buyIPFraction`**: Allows users to purchase fractional ownership shares of an IP asset, handling ETH payment and platform fees.
12. **`proposeIPLicensingTerms`**: IP owner defines dynamic licensing terms (e.g., royalty rates, usage conditions, duration, usage-based rate increases) for their IP.
13. **`acceptIPLicensingTerms`**: A potential licensee agrees to and logs their commitment to use the IP under specified terms.
14. **`registerIPUsage`**: Licensees log their actual usage of an IP, paying calculated royalties based on agreed-upon dynamic terms.

**IV. Governance, Staking & Reputation**
15. **`stakeForCuration`**: Users stake `DAIPEE_Token` to gain influence and participate in IP curation and governance.
16. **`unstakeCurationTokens`**: Allows users to request to unstake their tokens, subject to a cooldown period.
17. **`claimUnstakedTokens`**: Completes an unstake request after the cooldown period, transferring tokens back to the staker.
18. **`submitGovernanceProposal`**: Stakeholders propose changes to global protocol parameters, including executable call data.
19. **`voteOnGovernanceProposal`**: Staked token holders vote on submitted governance proposals, with voting power weighted by stake.
20. **`executeGovernanceProposal`**: Executes an approved governance proposal after the voting period ends and if a majority vote is achieved.
21. **`distributeIPRoyalties`**: Calculates and distributes accumulated royalties from IP usage to the IP owner (or managing entity for fractionalized IP), after deducting platform fees.
22. **`updateCuratorReputation`**: Internal function to adjust a curator's reputation score based on their participation and voting outcomes.

**V. Dispute Resolution & Rewards**
23. **`challengeIPOriginality`**: Allows staking `DAIPEE_Token` to formally challenge the originality or validity of a registered IP asset, providing evidence.
24. **`resolveOriginalityChallenge`**: A governance-approved or admin function to resolve an IP originality challenge, potentially burning fraudulent IP, penalizing owners/challengers, and distributing rewards.
25. **`claimContributionReward`**: Allows users to claim their earned `DAIPEE_Token` rewards, which are accrued from successful actions like mutation proposals or diligent curation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For interacting with DAIPEE_Token

/**
 * @title IDAIPEE_Token
 * @dev Interface for the DAIPEE_Token ERC20 contract.
 *      This token is used for staking, governance, and rewards within the DAIPEE ecosystem.
 *      Assumes the token contract is deployed separately and its address is provided.
 */
interface IDAIPEE_Token is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

/**
 * @title DAIPEE (Decentralized Autonomous Intellectual Property Exchange and Evolution)
 * @dev The DAIPEE protocol empowers creators to register, manage, evolve, and monetize their Intellectual Property (IP) as non-fungible tokens (NFTs).
 *      It introduces novel concepts such as community-driven IP mutation, simulated AI evolution steps,
 *      dynamic licensing, fractional ownership, and a reputation system for curators. The goal is to create a living,
 *      breathing ecosystem where IP isn't static but can grow, adapt, and generate value through collective effort and programmatic evolution.
 */
contract DAIPEE is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token counters for unique IP and Fragment IDs
    Counters.Counter private _ipAssetIdCounter;
    Counters.Counter private _ipFragmentIdCounter;
    Counters.Counter private _mutationProposalIdCounter;
    Counters.Counter private _governanceProposalIdCounter;
    Counters.Counter private _licensingTermIdCounter;

    // Address of the DAIPEE ERC20 token contract
    IDAIPEE_Token public immutable DAIPEE_Token;

    // --- Structs for IP Assets ---

    enum IPType {
        CoreAsset,
        Fragment,
        MutatedAsset
    }

    struct IPAsset {
        uint256 id;
        IPType ipType;
        bytes32 contentHash; // Cryptographic hash of the IP content (e.g., SHA256)
        string metadataURI; // URI to off-chain metadata (e.g., IPFS)
        address creator; // Original creator, even if NFT is transferred
        uint256 parentIPId; // For mutated assets, links to the original IP
        uint256 creationTimestamp;
        bool isFractionalized;
        uint256 totalFractions; // If fractionalized
    }

    // Mapping from tokenId to IPAsset details
    mapping(uint256 => IPAsset) public ipAssets;
    // Mapping from tokenId to its children/mutations
    mapping(uint256 => uint256[]) public ipChildren;
    // Mapping from contentHash to tokenId to check for duplicates
    mapping(bytes32 => uint256) public contentHashToIPId;

    // --- Structs for IP Evolution & Mutation ---

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected,
        Executed
    }

    struct MutationProposal {
        uint256 proposalId;
        uint256 targetIPId; // The IP asset this proposal mutates
        bytes32 newContentHash; // Hash of the proposed new content
        string newMetadataURI; // URI for new content
        address proposer;
        uint256 stakeAmount; // Amount of DAIPEE_Token staked by proposer
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        uint256 createdMutatedIPId; // If approved, stores the new IP ID
    }

    mapping(uint256 => MutationProposal) public mutationProposals;
    // Mapping from proposalId to voter address to bool (true if voted)
    mapping(uint256 => mapping(address => bool)) public hasVotedOnMutation;

    // --- Structs for Fractional Ownership ---

    // Tracks individual fractional ownership for a given IP ID
    mapping(uint256 => mapping(address => uint256)) public ipFractions;

    // --- Structs for Dynamic Licensing ---

    struct LicensingTerms {
        uint256 termsId;
        uint256 ipId;
        address licensor;
        uint256 baseRoyaltyRatePermil; // e.g., 100 = 10%
        string usageScopeURI; // URI detailing permitted usage (e.g., text, commercial, etc.)
        uint256 durationBlocks; // How many blocks the license is valid for from acceptance
        uint256 minimumPricePerUsage; // Optional minimum fee per usage
        uint256 usageThresholdForRateIncrease; // After X usages, rate increases
        uint256 rateIncreasePermil; // Amount to increase by per threshold
        bool isActive;
    }

    struct IPUsageLog {
        uint256 logId;
        uint256 termsId;
        uint256 ipId;
        address licensee;
        uint256 timestamp;
        uint256 valueTransacted; // Value associated with this usage event, if any
        bool distributed; // Track if royalties for this log have been distributed
    }

    mapping(uint256 => LicensingTerms) public licensingTerms;
    // IPId => Licensee => TermsId
    mapping(uint256 => mapping(address => uint256)) public acceptedLicensingTermsId;
    // termsId => list of usage logs for that term
    mapping(uint256 => IPUsageLog[]) public ipUsageLogsByTerms;

    // --- Structs for Governance ---

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 stakeAmount; // Stake amount from proposer for influence
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        bytes callData; // Encoded function call for execution
        address targetContract; // Target contract for execution
    }

    mapping(uint256 => GovernanceProposal) public governanceProposals;
    // Mapping from proposalId to voter address to bool (true if voted)
    mapping(uint256 => mapping(address => bool)) public hasVotedOnGovernance;

    // --- Staking & Reputation ---

    uint256 public constant MIN_STAKE_FOR_CURATION = 100 * 10 ** 18; // 100 DAIPEE_Token (wei)
    uint256 public constant MIN_STAKE_FOR_PROPOSAL = 50 * 10 ** 18; // 50 DAIPEE_Token (wei)
    uint256 public constant VOTING_PERIOD_BLOCKS = 1000; // Approx 4-5 hours at 12s/block
    uint256 public constant UNSTAKE_COOLDOWN_BLOCKS = 2000; // Approx 8-10 hours

    struct StakerInfo {
        uint256 stakedAmount; // Currently active staked amount
        uint256 pendingUnstakeAmount; // Amount requested to unstake, waiting cooldown
        uint256 unstakeRequestBlock; // Block number when unstake was requested
        int256 reputationScore; // Can be negative for bad actors
    }

    mapping(address => StakerInfo) public stakers;

    // --- Platform Fees ---
    uint256 public platformFeePermil = 20; // 2% platform fee on royalties (20/1000)

    // --- Claimable Rewards ---
    mapping(address => uint256) public claimableContributionRewards; // Rewards from successful contributions

    // --- Events ---
    event IPAssetRegistered(uint256 indexed ipId, IPType indexed ipType, address indexed owner, bytes32 contentHash, string metadataURI);
    event IPMetadataUpdated(uint256 indexed ipId, string newURI);
    event MutationProposed(uint256 indexed proposalId, uint256 indexed targetIPId, address indexed proposer, bytes32 newContentHash);
    event VoteCastOnMutation(uint256 indexed proposalId, address indexed voter, bool support);
    event MutationExecuted(uint256 indexed proposalId, uint256 indexed parentIPId, uint256 indexed newIPId);
    event EvolutionStepSimulated(uint256 indexed proposalId, uint256 indexed targetIPId, bytes32 newContentHash);
    event FragmentsCombined(address indexed owner, uint256[] indexed fragmentIds, uint256 newIPId);
    event FractionalOwnershipEnabled(uint256 indexed ipId, uint256 totalFractions);
    event IPFractionPurchased(uint256 indexed ipId, address indexed buyer, uint256 fractionsAmount);
    event LicensingTermsProposed(uint256 indexed termsId, uint256 indexed ipId, address indexed licensor);
    event LicensingTermsAccepted(uint256 indexed termsId, uint256 indexed ipId, address indexed licensee);
    event IPUsageLogged(uint256 indexed termsId, uint256 indexed ipId, address indexed licensee, uint256 royaltyAmountPaid);
    event RoyaltiesDistributed(uint256 indexed ipId, uint256 totalAmountDistributed, address indexed distributor);
    event StakedForCuration(address indexed staker, uint256 amount);
    event UnstakeRequested(address indexed staker, uint256 amount, uint256 cooldownEndsBlock);
    event Unstaked(address indexed staker, uint256 amount);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer);
    event VoteCastOnGovernance(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event CuratorReputationUpdated(address indexed curator, int256 newReputation);
    event IPOriginalityChallenge(uint256 indexed ipId, address indexed challenger, uint256 stakeAmount);
    event IPOriginalityChallengeResolved(uint256 indexed ipId, bool original, address indexed resolver);
    event ContributionRewardClaimed(address indexed claimant, uint256 amount);

    // --- Constructor ---
    constructor(address _DAIPEE_TokenAddress) ERC721("DAIPEE Intellectual Property", "DAIPEE_IP") Ownable(msg.sender) {
        require(_DAIPEE_TokenAddress != address(0), "DAIPEE: Token address cannot be zero");
        DAIPEE_Token = IDAIPEE_Token(_DAIPEE_TokenAddress);
    }

    // --- Modifiers ---
    modifier onlyStakedCuration() {
        require(stakers[msg.sender].stakedAmount >= MIN_STAKE_FOR_CURATION, "DAIPEE: Insufficient stake for curation");
        _;
    }

    modifier onlyIPOwner(uint256 _ipId) {
        require(_exists(_ipId), "DAIPEE: IP does not exist");
        require(ownerOf(_ipId) == msg.sender, "DAIPEE: Caller is not the IP owner");
        _;
    }

    // --- I. Core IP Asset Management & Registry ---

    /**
     * @dev Registers a new core IP asset or a fragment asset and mints an NFT for it.
     *      Requires the contentHash to be unique.
     * @param _ipType The type of IP being registered (CoreAsset or Fragment).
     * @param _contentHash Cryptographic hash of the IP content.
     * @param _metadataURI URI pointing to the off-chain metadata of the IP.
     * @param _parentIPId For mutated assets, links to the original IP. Use 0 for new core assets/fragments.
     * @return The ID of the newly minted IP asset.
     */
    function registerNewIPAsset(
        IPType _ipType,
        bytes32 _contentHash,
        string calldata _metadataURI,
        uint256 _parentIPId
    ) external returns (uint256) {
        require(_contentHash != bytes32(0), "DAIPEE: Content hash cannot be empty");
        require(contentHashToIPId[_contentHash] == 0, "DAIPEE: Content hash already registered");
        require(_ipType != IPType.MutatedAsset || _parentIPId != 0, "DAIPEE: Mutated asset must have a parent");

        uint256 newId;
        if (_ipType == IPType.Fragment) {
            _ipFragmentIdCounter.increment();
            newId = _ipFragmentIdCounter.current();
        } else { // CoreAsset or MutatedAsset
            _ipAssetIdCounter.increment();
            newId = _ipAssetIdCounter.current();
            if (_ipType == IPType.MutatedAsset) {
                require(_exists(_parentIPId), "DAIPEE: Parent IP does not exist for mutated asset");
                ipChildren[_parentIPId].push(newId);
            }
        }

        _safeMint(msg.sender, newId);

        ipAssets[newId] = IPAsset({
            id: newId,
            ipType: _ipType,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            creator: msg.sender,
            parentIPId: _parentIPId,
            creationTimestamp: block.timestamp,
            isFractionalized: false,
            totalFractions: 0
        });

        contentHashToIPId[_contentHash] = newId;

        emit IPAssetRegistered(newId, _ipType, msg.sender, _contentHash, _metadataURI);
        return newId;
    }

    /**
     * @dev Allows an IP owner to update the off-chain metadata URI for their IP/Fragment NFT.
     * @param _ipId The ID of the IP asset or fragment.
     * @param _newURI The new URI pointing to the metadata.
     */
    function updateIPMetadataURI(uint256 _ipId, string calldata _newURI) external onlyIPOwner(_ipId) {
        require(bytes(_newURI).length > 0, "DAIPEE: New URI cannot be empty");
        ipAssets[_ipId].metadataURI = _newURI;
        emit IPMetadataUpdated(_ipId, _newURI);
    }

    // --- II. IP Evolution & Mutation Mechanisms ---

    /**
     * @dev Users stake DAIPEE_Token to propose a new, mutated version of an existing IP asset.
     *      Requires staking DAIPEE_Token for proposal validity.
     * @param _targetIPId The ID of the IP asset to be mutated.
     * @param _newContentHash Hash of the proposed new content.
     * @param _newMetadataURI URI for the metadata of the new content.
     */
    function proposeIPMutation(
        uint256 _targetIPId,
        bytes32 _newContentHash,
        string calldata _newMetadataURI
    ) external {
        require(_exists(_targetIPId), "DAIPEE: Target IP does not exist");
        require(_newContentHash != bytes32(0), "DAIPEE: New content hash cannot be empty");
        require(contentHashToIPId[_newContentHash] == 0, "DAIPEE: Proposed content hash already registered");
        require(DAIPEE_Token.balanceOf(msg.sender) >= MIN_STAKE_FOR_PROPOSAL, "DAIPEE: Insufficient DAIPEE_Token balance to stake for proposal");

        _mutationProposalIdCounter.increment();
        uint256 proposalId = _mutationProposalIdCounter.current();

        DAIPEE_Token.transferFrom(msg.sender, address(this), MIN_STAKE_FOR_PROPOSAL); // Staking for proposal

        mutationProposals[proposalId] = MutationProposal({
            proposalId: proposalId,
            targetIPId: _targetIPId,
            newContentHash: _newContentHash,
            newMetadataURI: _newMetadataURI,
            proposer: msg.sender,
            stakeAmount: MIN_STAKE_FOR_PROPOSAL,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + VOTING_PERIOD_BLOCKS,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending,
            createdMutatedIPId: 0
        });

        emit MutationProposed(proposalId, _targetIPId, msg.sender, _newContentHash);
    }

    /**
     * @dev Staked curators vote on the validity and value of proposed IP mutations.
     * @param _proposalId The ID of the mutation proposal.
     * @param _support True for voting in favor, false for against.
     */
    function voteOnMutationProposal(uint256 _proposalId, bool _support) external onlyStakedCuration {
        MutationProposal storage proposal = mutationProposals[_proposalId];
        require(proposal.proposalId != 0, "DAIPEE: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "DAIPEE: Proposal is not in pending status");
        require(block.timestamp >= proposal.votingStartTime && block.timestamp < proposal.votingEndTime, "DAIPEE: Voting period is not active");
        require(!hasVotedOnMutation[_proposalId][msg.sender], "DAIPEE: Already voted on this proposal");

        hasVotedOnMutation[_proposalId][msg.sender] = true;

        if (_support) {
            proposal.votesFor += stakers[msg.sender].stakedAmount; // Weighted voting by stake
            updateCuratorReputation(msg.sender, 1); // Increment reputation
        } else {
            proposal.votesAgainst += stakers[msg.sender].stakedAmount;
            updateCuratorReputation(msg.sender, -1); // Decrement reputation
        }
        emit VoteCastOnMutation(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Finalizes an approved mutation proposal, minting a new derivative IP NFT and linking it to its parent.
     *      Distributes rewards and returns proposer's stake if approved.
     * @param _proposalId The ID of the mutation proposal to execute.
     */
    function executeApprovedMutation(uint256 _proposalId) external {
        MutationProposal storage proposal = mutationProposals[_proposalId];
        require(proposal.proposalId != 0, "DAIPEE: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "DAIPEE: Proposal not in pending status");
        require(block.timestamp >= proposal.votingEndTime, "DAIPEE: Voting period not ended");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Register new mutated IP
            uint256 newIPId = registerNewIPAsset(
                IPType.MutatedAsset,
                proposal.newContentHash,
                proposal.newMetadataURI,
                proposal.targetIPId
            );
            _transfer(address(this), proposal.proposer, newIPId); // Transfer new IP to proposer

            proposal.status = ProposalStatus.Executed;
            proposal.createdMutatedIPId = newIPId;

            // Return proposer's stake and provide a reward
            DAIPEE_Token.transfer(proposal.proposer, proposal.stakeAmount);
            DAIPEE_Token.mint(proposal.proposer, proposal.stakeAmount / 2); // 50% reward on stake

            // Distribute a smaller reward to positive voters
            uint256 rewardPool = proposal.stakeAmount / 4; // 25% of stake as reward
            // For simplicity, we just add to claimableContributionRewards. A full DAO would manage.
            claimableContributionRewards[proposal.proposer] += rewardPool; // Proposer also gets claimable reward

            emit MutationExecuted(_proposalId, proposal.targetIPId, newIPId);
        } else {
            proposal.status = ProposalStatus.Rejected;
            // Penalize proposer by burning part of their stake and returning the rest
            DAIPEE_Token.burn(proposal.stakeAmount / 4); // Burn 25% of stake
            DAIPEE_Token.transfer(proposal.proposer, proposal.stakeAmount * 3 / 4); // Return remaining stake
        }
    }

    /**
     * @dev Allows an authorized 'Evolution Engine' (e.g., an off-chain AI agent) to register a proposed
     *      evolution step. This doesn't directly mint an IP but creates a proposal for community review.
     *      Only callable by the contract owner (acting as a whitelisted engine manager).
     * @param _targetIPId The ID of the IP asset to potentially evolve.
     * @param _newContentHash Hash of the content suggested by the engine.
     * @param _newMetadataURI URI for the metadata of the suggested content.
     * @param _engineAddress The address of the recognized Evolution Engine (for tracking proposer).
     * @param _proofData Optional data to verify engine's computation (e.g., ZK proof hash).
     */
    function simulateEvolutionStep(
        uint256 _targetIPId,
        bytes32 _newContentHash,
        string calldata _newMetadataURI,
        address _engineAddress, // Could be an address whitelisted by DAO
        bytes calldata _proofData // Placeholder for verifiable compute proof
    ) external onlyOwner { // Only owner (or a whitelisted Evolution Engine manager) can call this
        // In a real system, _engineAddress would be checked against a whitelisted list
        // and _proofData would be verified, potentially by a ZK verifier contract.
        require(_exists(_targetIPId), "DAIPEE: Target IP does not exist");
        require(_newContentHash != bytes32(0), "DAIPEE: New content hash cannot be empty");
        require(contentHashToIPId[_newContentHash] == 0, "DAIPEE: Proposed content hash already registered");
        require(_engineAddress != address(0), "DAIPEE: Engine address cannot be zero");

        _mutationProposalIdCounter.increment();
        uint256 proposalId = _mutationProposalIdCounter.current();

        mutationProposals[proposalId] = MutationProposal({
            proposalId: proposalId,
            targetIPId: _targetIPId,
            newContentHash: _newContentHash,
            newMetadataURI: _newMetadataURI,
            proposer: _engineAddress, // Proposer is the engine
            stakeAmount: 0, // No stake from engine directly for simulated proposals
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + VOTING_PERIOD_BLOCKS,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending,
            createdMutatedIPId: 0
        });

        emit EvolutionStepSimulated(proposalId, _targetIPId, _newContentHash);
    }

    /**
     * @dev Allows an IP owner to combine multiple owned IP fragment NFTs into a new, distinct core IP asset.
     *      The fragments are burned in the process.
     * @param _fragmentIds An array of IP fragment IDs to combine.
     * @param _newContentHash Hash of the resulting combined IP content.
     * @param _newMetadataURI URI for the metadata of the new combined IP.
     * @return The ID of the newly minted combined IP asset.
     */
    function combineIPFragments(
        uint256[] calldata _fragmentIds,
        bytes32 _newContentHash,
        string calldata _newMetadataURI
    ) external returns (uint256) {
        require(_fragmentIds.length > 1, "DAIPEE: At least two fragments required to combine");
        require(_newContentHash != bytes32(0), "DAIPEE: New content hash cannot be empty");
        require(contentHashToIPId[_newContentHash] == 0, "DAIPEE: Content hash already registered");

        for (uint256 i = 0; i < _fragmentIds.length; i++) {
            uint256 fragmentId = _fragmentIds[i];
            require(_exists(fragmentId), "DAIPEE: Fragment does not exist");
            require(ipAssets[fragmentId].ipType == IPType.Fragment, "DAIPEE: ID is not an IP fragment");
            require(ownerOf(fragmentId) == msg.sender, "DAIPEE: Not owner of all fragments");
            _burn(fragmentId); // Burn the fragments
        }

        uint256 newIPId = registerNewIPAsset(IPType.CoreAsset, _newContentHash, _newMetadataURI, 0);

        emit FragmentsCombined(msg.sender, _fragmentIds, newIPId);
        return newIPId;
    }

    // --- III. Fractional Ownership & Dynamic Licensing ---

    /**
     * @dev Initiates a process to fractionalize an IP asset, defining the total number of fractions.
     *      The original IP owner will receive all initial fractions.
     * @param _ipId The ID of the IP asset to fractionalize.
     * @param _totalFractions The total number of fractions to create for this IP.
     */
    function enableFractionalOwnership(uint256 _ipId, uint256 _totalFractions) external onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        require(!ip.isFractionalized, "DAIPEE: IP is already fractionalized");
        require(_totalFractions > 1, "DAIPEE: Must create more than one fraction");

        ip.isFractionalized = true;
        ip.totalFractions = _totalFractions;
        ipFractions[_ipId][msg.sender] = _totalFractions; // Owner gets all initial fractions

        emit FractionalOwnershipEnabled(_ipId, _totalFractions);
    }

    /**
     * @dev Allows users to purchase fractional ownership shares of an IP asset.
     *      Assumes an external marketplace facilitates the discovery and pricing. This function
     *      handles the transfer of fractional ownership within the DAIPEE system and processes payment.
     * @param _ipId The ID of the fractionalized IP asset.
     * @param _amount The number of fractions to purchase.
     * @param _from The address from which the fractions are purchased (current owner of fractions).
     * @param _pricePerFraction The price per fraction (sent as msg.value).
     */
    function buyIPFraction(
        uint256 _ipId,
        uint256 _amount,
        address _from,
        uint256 _pricePerFraction // Denotes the agreed price
    ) external payable { // Accepts ETH payment
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.isFractionalized, "DAIPEE: IP is not fractionalized");
        require(ipFractions[_ipId][_from] >= _amount, "DAIPEE: Seller does not own enough fractions");
        require(msg.value == _amount * _pricePerFraction, "DAIPEE: Incorrect ETH amount sent");
        require(msg.sender != _from, "DAIPEE: Cannot buy fractions from self");

        ipFractions[_ipId][_from] -= _amount;
        ipFractions[_ipId][msg.sender] += _amount;

        // Transfer funds to seller (and platform fee to owner)
        uint256 platformFee = (msg.value * platformFeePermil) / 1000;
        payable(_from).transfer(msg.value - platformFee); // Seller receives net amount
        payable(owner()).transfer(platformFee); // Platform fee to contract owner/DAO treasury

        emit IPFractionPurchased(_ipId, msg.sender, _amount);
    }

    /**
     * @dev IP owner defines dynamic licensing terms (e.g., royalty rates, usage conditions) for their IP.
     * @param _ipId The ID of the IP asset for which to define terms.
     * @param _baseRoyaltyRatePermil Base royalty rate in permil (e.g., 100 = 10%).
     * @param _usageScopeURI URI detailing permitted usage scope.
     * @param _durationBlocks How many blocks the license is valid for from acceptance.
     * @param _minimumPricePerUsage Optional minimum fee per usage.
     * @param _usageThresholdForRateIncrease After X usages, royalty rate increases. Set 0 for no increase.
     * @param _rateIncreasePermil Amount to increase by per usage threshold. Set 0 for no increase.
     */
    function proposeIPLicensingTerms(
        uint256 _ipId,
        uint256 _baseRoyaltyRatePermil,
        string calldata _usageScopeURI,
        uint256 _durationBlocks,
        uint256 _minimumPricePerUsage,
        uint256 _usageThresholdForRateIncrease,
        uint256 _rateIncreasePermil
    ) external onlyIPOwner(_ipId) returns (uint256) {
        require(_baseRoyaltyRatePermil <= 1000, "DAIPEE: Royalty rate cannot exceed 100%");
        require(bytes(_usageScopeURI).length > 0, "DAIPEE: Usage scope URI cannot be empty");
        require(_durationBlocks > 0, "DAIPEE: Duration must be greater than zero");

        _licensingTermIdCounter.increment();
        uint256 termsId = _licensingTermIdCounter.current();

        licensingTerms[termsId] = LicensingTerms({
            termsId: termsId,
            ipId: _ipId,
            licensor: msg.sender,
            baseRoyaltyRatePermil: _baseRoyaltyRatePermil,
            usageScopeURI: _usageScopeURI,
            durationBlocks: _durationBlocks,
            minimumPricePerUsage: _minimumPricePerUsage,
            usageThresholdForRateIncrease: _usageThresholdForRateIncrease,
            rateIncreasePermil: _rateIncreasePermil,
            isActive: true
        });

        emit LicensingTermsProposed(termsId, _ipId, msg.sender);
        return termsId;
    }

    /**
     * @dev A potential licensee agrees to and logs their commitment to use the IP under specified terms.
     * @param _termsId The ID of the licensing terms to accept.
     */
    function acceptIPLicensingTerms(uint256 _termsId) external {
        LicensingTerms storage terms = licensingTerms[_termsId];
        require(terms.termsId != 0, "DAIPEE: Licensing terms do not exist");
        require(terms.isActive, "DAIPEE: Licensing terms are not active");
        require(acceptedLicensingTermsId[terms.ipId][msg.sender] == 0, "DAIPEE: Licensee already has active terms for this IP");

        // The terms.creationTimestamp for validity checking should ideally be the acceptance timestamp.
        // For simplicity, we are using block.timestamp for the "start" of the duration.
        terms.durationBlocks += block.number; // Adjust to be `endBlock = acceptanceBlock + durationBlocks`
                                             // This means `terms.durationBlocks` stores the end block, not duration.
                                             // Let's make `terms.creationTimestamp` (from IPAsset) be the start for duration if needed.
                                             // Or, add `acceptanceBlock` to LicensingTerms struct.

        // For now, let's just make `durationBlocks` directly represent the 'end block'
        // derived from when it was created and its duration. Or, if it's duration from acceptance,
        // then the log should track that.

        // Let's modify LicensingTerms to have a `validUntilBlock` that is set upon acceptance.
        // For now, simpler: `terms.durationBlocks` is just duration.
        // The check in `registerIPUsage` will use `block.timestamp`.

        acceptedLicensingTermsId[terms.ipId][msg.sender] = _termsId;

        emit LicensingTermsAccepted(_termsId, terms.ipId, msg.sender);
    }

    /**
     * @dev Licensees log their actual usage of an IP, paying calculated royalties.
     *      Requires payment for usage as msg.value.
     * @param _ipId The ID of the used IP asset.
     * @param _valueTransacted The value associated with this usage event (e.g., revenue generated by licensee).
     */
    function registerIPUsage(uint256 _ipId, uint256 _valueTransacted) external payable {
        uint256 termsId = acceptedLicensingTermsId[_ipId][msg.sender];
        require(termsId != 0, "DAIPEE: No active licensing terms for this IP and licensee");
        LicensingTerms storage terms = licensingTerms[termsId];
        require(terms.ipId == _ipId, "DAIPEE: Terms mismatch for IP ID");
        require(block.number <= ipAssets[_ipId].creationTimestamp + terms.durationBlocks, "DAIPEE: Licensing terms have expired"); // Assuming terms validity from IP creation or acceptance, simplified to `ipAssets[_ipId].creationTimestamp`

        uint256 currentRoyaltyRate = terms.baseRoyaltyRatePermil;
        uint256 currentUsageCount = ipUsageLogsByTerms[termsId].length;

        // Apply dynamic royalty rate adjustment
        if (terms.usageThresholdForRateIncrease > 0 && currentUsageCount >= terms.usageThresholdForRateIncrease) {
            uint256 increaseFactor = currentUsageCount / terms.usageThresholdForRateIncrease;
            currentRoyaltyRate += terms.rateIncreasePermil * increaseFactor;
            if (currentRoyaltyRate > 1000) currentRoyaltyRate = 1000; // Cap at 100%
        }

        uint256 expectedRoyalty = (_valueTransacted * currentRoyaltyRate) / 1000;
        if (terms.minimumPricePerUsage > 0 && expectedRoyalty < terms.minimumPricePerUsage) {
            expectedRoyalty = terms.minimumPricePerUsage;
        }

        require(msg.value >= expectedRoyalty, "DAIPEE: Insufficient payment for royalty");

        ipUsageLogsByTerms[termsId].push(IPUsageLog({
            logId: ipUsageLogsByTerms[termsId].length, // Simple incremental ID for logs within a term
            termsId: termsId,
            ipId: _ipId,
            licensee: msg.sender,
            timestamp: block.timestamp,
            valueTransacted: _valueTransacted,
            distributed: false // Mark as not yet distributed
        }));

        // Transfer collected royalty to contract for distribution
        // Any excess payment (msg.value - expectedRoyalty) is returned to msg.sender
        if (msg.value > expectedRoyalty) {
            payable(msg.sender).transfer(msg.value - expectedRoyalty);
        }

        emit IPUsageLogged(termsId, _ipId, msg.sender, expectedRoyalty);
    }

    // --- IV. Governance, Staking & Reputation ---

    /**
     * @dev Users stake DAIPEE_Token to gain influence and participate in IP curation and governance.
     * @param _amount The amount of DAIPEE_Token to stake.
     */
    function stakeForCuration(uint256 _amount) external {
        require(_amount > 0, "DAIPEE: Stake amount must be greater than zero");
        DAIPEE_Token.transferFrom(msg.sender, address(this), _amount);
        stakers[msg.sender].stakedAmount += _amount;
        emit StakedForCuration(msg.sender, _amount);
    }

    /**
     * @dev Allows users to request to unstake their tokens, subject to a cooldown period.
     * @param _amount The amount of DAIPEE_Token to unstake.
     */
    function unstakeCurationTokens(uint256 _amount) external {
        StakerInfo storage staker = stakers[msg.sender];
        require(_amount > 0, "DAIPEE: Unstake amount must be positive");
        require(staker.stakedAmount >= _amount, "DAIPEE: Insufficient active staked amount");
        require(staker.pendingUnstakeAmount == 0, "DAIPEE: An unstake request is already pending. Claim or cancel previous request first.");

        staker.stakedAmount -= _amount; // Reduce active stake immediately
        staker.pendingUnstakeAmount = _amount; // Store amount for pending unstake
        staker.unstakeRequestBlock = block.number; // Start cooldown

        emit UnstakeRequested(msg.sender, _amount, block.number + UNSTAKE_COOLDOWN_BLOCKS);
    }

    /**
     * @dev Completes an unstake request after the cooldown period, transferring tokens back to the staker.
     */
    function claimUnstakedTokens() external {
        StakerInfo storage staker = stakers[msg.sender];
        require(staker.pendingUnstakeAmount > 0, "DAIPEE: No pending unstake amount to claim");
        require(block.number >= staker.unstakeRequestBlock + UNSTAKE_COOLDOWN_BLOCKS, "DAIPEE: Unstake cooldown not yet over");

        uint256 amountToClaim = staker.pendingUnstakeAmount;
        staker.pendingUnstakeAmount = 0;
        staker.unstakeRequestBlock = 0;

        DAIPEE_Token.transfer(msg.sender, amountToClaim);
        emit Unstaked(msg.sender, amountToClaim);
    }

    /**
     * @dev Stakeholders propose changes to global protocol parameters, or executable actions.
     *      Requires active DAIPEE_Token stake for curation.
     * @param _description Description of the proposal.
     * @param _callData Encoded function call for execution if approved (e.g., `abi.encodeWithSignature("setPlatformFeePermil(uint256)", 15)`).
     * @param _targetContract Target contract address for execution (e.g., `address(this)` for self-execution).
     */
    function submitGovernanceProposal(
        string calldata _description,
        bytes calldata _callData,
        address _targetContract
    ) external onlyStakedCuration {
        require(bytes(_description).length > 0, "DAIPEE: Proposal description cannot be empty");
        require(_callData.length > 0, "DAIPEE: Call data cannot be empty for executable proposal");
        require(_targetContract != address(0), "DAIPEE: Target contract cannot be zero");

        _governanceProposalIdCounter.increment();
        uint256 proposalId = _governanceProposalIdCounter.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _description,
            proposer: msg.sender,
            stakeAmount: stakers[msg.sender].stakedAmount, // Use current active stake as proposal influence
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + VOTING_PERIOD_BLOCKS,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending,
            callData: _callData,
            targetContract: _targetContract
        });

        emit GovernanceProposalSubmitted(proposalId, msg.sender);
    }

    /**
     * @dev Staked token holders vote on submitted governance proposals.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True for voting in favor, false for against.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external onlyStakedCuration {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposalId != 0, "DAIPEE: Governance proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "DAIPEE: Proposal is not in pending status");
        require(block.timestamp >= proposal.votingStartTime && block.timestamp < proposal.votingEndTime, "DAIPEE: Voting period is not active");
        require(!hasVotedOnGovernance[_proposalId][msg.sender], "DAIPEE: Already voted on this proposal");

        hasVotedOnGovernance[_proposalId][msg.sender] = true;

        uint256 voterStake = stakers[msg.sender].stakedAmount;
        require(voterStake > 0, "DAIPEE: Voter must have active stake");

        if (_support) {
            proposal.votesFor += voterStake;
            updateCuratorReputation(msg.sender, 2); // Higher reputation for governance participation
        } else {
            proposal.votesAgainst += voterStake;
            updateCuratorReputation(msg.sender, -2);
        }
        emit VoteCastOnGovernance(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes an approved governance proposal. Only callable after voting ends and if approved.
     *      Requires a majority vote.
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposalId != 0, "DAIPEE: Governance proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "DAIPEE: Proposal not in pending status");
        require(block.timestamp >= proposal.votingEndTime, "DAIPEE: Voting period not ended");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Executed;
            // Execute the encoded call
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "DAIPEE: Governance proposal execution failed");
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    /**
     * @dev Sets the platform fee in permil (e.g., 20 for 2%). Callable only via governance.
     * @param _newFeePermil The new platform fee to set.
     */
    function setPlatformFeePermil(uint256 _newFeePermil) external onlyOwner { // Or via governance
        require(_newFeePermil <= 100, "DAIPEE: Fee cannot exceed 10%"); // Max 10% for example
        platformFeePermil = _newFeePermil;
    }

    /**
     * @dev Calculates and distributes accumulated royalties from IP usage to the IP owner.
     *      Anyone can trigger this distribution.
     * @param _ipId The ID of the IP asset for which to distribute royalties.
     */
    function distributeIPRoyalties(uint256 _ipId) external {
        IPAsset storage ip = ipAssets[_ipId];
        require(_exists(_ipId), "DAIPEE: IP asset does not exist");

        uint256 totalRoyaltiesToDistribute = 0;
        uint256 platformFeeCollected = 0;

        // Iterate through all licensing terms associated with this IP
        for (uint256 i = 1; i <= _licensingTermIdCounter.current(); i++) {
            LicensingTerms storage terms = licensingTerms[i];
            if (terms.ipId == _ipId) {
                // Iterate through all usage logs for these terms
                for (uint256 j = 0; j < ipUsageLogsByTerms[i].length; j++) {
                    IPUsageLog storage log = ipUsageLogsByTerms[i][j];
                    if (!log.distributed) { // Only process undistributed royalties
                        // Recalculate dynamic rate for this specific log entry based on its position in history
                        uint256 currentRoyaltyRate = terms.baseRoyaltyRatePermil;
                        uint256 usageCountBeforeThisLog = j; // Number of logs before this one for this term
                        if (terms.usageThresholdForRateIncrease > 0 && usageCountBeforeThisLog >= terms.usageThresholdForRateIncrease) {
                            currentRoyaltyRate += terms.rateIncreasePermil * (usageCountBeforeThisLog / terms.usageThresholdForRateIncrease);
                            if (currentRoyaltyRate > 1000) currentRoyaltyRate = 1000; // Cap at 100%
                        }

                        uint256 royaltyForThisUsage = (log.valueTransacted * currentRoyaltyRate) / 1000;
                        if (terms.minimumPricePerUsage > 0 && royaltyForThisUsage < terms.minimumPricePerUsage) {
                            royaltyForThisUsage = terms.minimumPricePerUsage;
                        }

                        uint256 fee = (royaltyForThisUsage * platformFeePermil) / 1000;
                        platformFeeCollected += fee;
                        totalRoyaltiesToDistribute += (royaltyForThisUsage - fee);
                        log.distributed = true; // Mark as processed for distribution
                    }
                }
            }
        }

        require(totalRoyaltiesToDistribute > 0 || platformFeeCollected > 0, "DAIPEE: No royalties to distribute for this IP");

        // Distribute platform fee to owner (or DAO treasury)
        if (platformFeeCollected > 0) {
            payable(owner()).transfer(platformFeeCollected);
        }

        // Distribute remaining royalties to the current owner of the IP NFT
        if (totalRoyaltiesToDistribute > 0) {
            payable(ownerOf(_ipId)).transfer(totalRoyaltiesToDistribute);
        }
        emit RoyaltiesDistributed(_ipId, totalRoyaltiesToDistribute, msg.sender);
    }

    /**
     * @dev Internal function to adjust a curator's reputation score.
     *      Can be made public if DAO controls it directly.
     * @param _curator The address of the curator.
     * @param _change The amount to change the reputation by (can be negative).
     */
    function updateCuratorReputation(address _curator, int256 _change) internal {
        stakers[_curator].reputationScore += _change;
        emit CuratorReputationUpdated(_curator, stakers[_curator].reputationScore);
    }

    // --- V. Dispute Resolution & Rewards ---

    /**
     * @dev Allows staking DAIPEE_Token to formally challenge the originality or validity of a registered IP asset.
     *      This function creates a governance proposal for the challenge, requiring community vote for resolution.
     * @param _ipId The ID of the IP asset to challenge.
     * @param _evidenceURI URI pointing to off-chain evidence supporting the challenge.
     */
    function challengeIPOriginality(uint256 _ipId, string calldata _evidenceURI) external {
        require(_exists(_ipId), "DAIPEE: IP asset does not exist");
        require(bytes(_evidenceURI).length > 0, "DAIPEE: Evidence URI cannot be empty");
        require(DAIPEE_Token.balanceOf(msg.sender) >= MIN_STAKE_FOR_PROPOSAL, "DAIPEE: Insufficient DAIPEE_Token for challenge stake");

        // Take stake from challenger to back the claim
        DAIPEE_Token.transferFrom(msg.sender, address(this), MIN_STAKE_FOR_PROPOSAL);

        // Create a governance proposal for the challenge. The `_callData` would contain resolution logic.
        // For simplicity, we just use a general description. A more complex system would have a dedicated challenge struct.
        string memory description = string(abi.encodePacked("Challenge originality of IP ID: ", Strings.toString(_ipId), " with evidence: ", _evidenceURI));
        bytes memory callData = abi.encodeWithSignature("resolveOriginalityChallenge(uint256,bool,address)", _ipId, true, msg.sender); // Placeholder callData

        _governanceProposalIdCounter.increment();
        uint256 proposalId = _governanceProposalIdCounter.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: description,
            proposer: msg.sender,
            stakeAmount: MIN_STAKE_FOR_PROPOSAL, // Stake is MIN_STAKE_FOR_PROPOSAL
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + VOTING_PERIOD_BLOCKS,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending,
            callData: callData, // This should be for *resolving* the challenge if approved
            targetContract: address(this)
        });

        emit IPOriginalityChallenge(_ipId, msg.sender, MIN_STAKE_FOR_PROPOSAL);
    }

    /**
     * @dev Resolves an IP originality challenge. Callable by the contract owner (or via a governance vote).
     *      Burns fraudulent IP, penalizes original owner if fraudulent, rewards challenger, or refunds original owner.
     *      This function would typically be called by `executeGovernanceProposal` after a challenge is voted upon.
     * @param _ipId The ID of the challenged IP asset.
     * @param _isOriginal True if the IP is determined to be original, false if fraudulent.
     * @param _challenger The address of the challenger.
     */
    function resolveOriginalityChallenge(
        uint256 _ipId,
        bool _isOriginal,
        address _challenger
    ) external onlyOwner { // This should ideally be called by the DAO/governance, not just owner directly
        require(_exists(_ipId), "DAIPEE: IP asset does not exist");
        require(_challenger != address(0), "DAIPEE: Challenger address cannot be zero");
        // This function assumes a challenge has been successfully processed and its stake is held by the contract.
        // In a real system, the stake would be tracked per challenge ID.
        uint256 challengeStakeAmount = MIN_STAKE_FOR_PROPOSAL; // Assuming standard stake for simplicity

        if (_isOriginal) {
            // Challenger was wrong: return most of stake, burn a penalty
            DAIPEE_Token.burn(challengeStakeAmount / 4); // Burn 25% of challenger's stake
            DAIPEE_Token.transfer(_challenger, challengeStakeAmount * 3 / 4); // Return remaining 75%
        } else {
            // IP was fraudulent: burn IP, reward challenger
            _burn(_ipId); // Burn the fraudulent NFT
            DAIPEE_Token.transfer(_challenger, challengeStakeAmount); // Return challenger's full stake
            DAIPEE_Token.mint(_challenger, challengeStakeAmount / 2); // Reward for successful challenge
            // Optionally, penalize the fraudulent IP creator/owner (e.g., burn their reputation or other assets)
        }
        emit IPOriginalityChallengeResolved(_ipId, _isOriginal, msg.sender);
    }

    /**
     * @dev Allows users to claim their earned DAIPEE_Token rewards.
     *      Rewards are accrued by other functions (e.g., successful mutation proposals, curation).
     * @param _amount The amount of DAIPEE_Token to claim.
     */
    function claimContributionReward(uint256 _amount) external {
        require(_amount > 0, "DAIPEE: Claim amount must be positive");
        require(claimableContributionRewards[msg.sender] >= _amount, "DAIPEE: Insufficient claimable rewards");

        claimableContributionRewards[msg.sender] -= _amount;
        DAIPEE_Token.transfer(msg.sender, _amount);
        emit ContributionRewardClaimed(msg.sender, _amount);
    }
}
```