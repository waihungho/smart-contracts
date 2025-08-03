```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EtherealEchoes
 * @author YourName (Designed by AI)
 * @notice A decentralized protocol for collaborative knowledge construction and contextual identity formation.
 * Users contribute fragmented pieces of information or narrative ("Echoes"), link them together to form a dynamic
 * knowledge graph, and participate in "Context Spheres" that represent thematic domains. User reputation is dynamic
 * and context-specific, evolving based on their contributions and interactions within these spheres. The system
 * rewards insightful connections and active curation, utilizing staking mechanisms to ensure content quality and
 * mitigate spam. This contract explores advanced concepts such as on-chain graph-like data structures,
 * dynamic contextual reputation, algorithmic curation, and emergent knowledge systems.
 */

// --- Outline ---
// 1. Core Data Structures: Echo, Link, ContextSphere
// 2. State Variables: Counters, Mappings for entities, System Parameters
// 3. Events: For logging significant actions
// 4. Errors: Custom errors for clarity
// 5. Modifiers: For access control and state checks
// 6. Core Echo Management (Functions 1-7): Create, Link, Unlink, Rate, Flag, Resolve Flag, Retract Echoes.
// 7. Context Sphere Management (Functions 8-14): Create, Join, Leave, Update, Delegate Admin, Propose/Vote Merge Spheres.
// 8. Reputation & Scoring (Functions 15-17): Get Contextual/Overall Reputation, System-triggered Decay.
// 9. Staking & Rewards (Functions 18-22): Stake for Verification, Claim Rewards, Slash Stakes, Distribute Connection Reward, Deposit Reward Pool.
// 10. Query & Discovery (Functions 23-27): Get Echo Details, Linked Echoes, User Echoes, Echoes in Context Sphere.
// 11. System Administration (Functions 28-29): Set Parameters, Emergency Pause.

// --- Function Summary (29 Functions) ---
// 1. `submitEcho(string _contentHash)`: Creates a new "Echo" with a unique ID, storing a content hash (e.g., IPFS CID).
// 2. `linkEchoes(uint256 _fromEchoId, uint256 _toEchoId, string _linkContext)`: Establishes a directed link between two existing Echoes, with optional contextual metadata.
// 3. `unlinkEchoes(uint256 _linkId)`: Removes an existing link between Echoes, callable by the linker or Echo creator.
// 4. `rateEcho(uint256 _echoId, int8 _rating, uint256 _contextSphereId)`: Provides a contextual rating (e.g., -5 to 5) for an Echo, influencing its relevance within a specific Context Sphere.
// 5. `flagEcho(uint256 _echoId, string _reason)`: Flags an Echo for review (e.g., spam, misinformation), initiating a community/admin moderation process.
// 6. `resolveFlag(uint256 _echoId, bool _isVandalism, string _resolutionNotes)`: Resolves a flagged Echo; if deemed vandalism, the flagger's reputation might be penalized.
// 7. `retractEcho(uint256 _echoId)`: Allows the original creator to remove their Echo, potentially incurring a reputation penalty.
// 8. `createContextSphere(string _name, string _description)`: Initializes a new Context Sphere, becoming its initial administrator.
// 9. `joinContextSphere(uint256 _sphereId)`: Allows a user to become a member of a Context Sphere, potentially based on reputation or invited by admins.
// 10. `leaveContextSphere(uint256 _sphereId)`: Allows a user to leave a Context Sphere, potentially impacting their contextual reputation.
// 11. `updateContextSphere(uint256 _sphereId, string _newName, string _newDescription)`: Allows a sphere administrator to update its name or description.
// 12. `delegateContextSphereAdmin(uint256 _sphereId, address _newAdmin)`: Transfers administrative control of a Context Sphere.
// 13. `proposeContextSphereMerge(uint256 _sphereId1, uint256 _sphereId2)`: Initiates a proposal to merge two Context Spheres, requiring consensus.
// 14. `voteOnContextSphereMerge(uint256 _proposalId, bool _approve)`: Members of the proposed spheres vote on a merge proposal.
// 15. `getContextualReputation(address _user, uint256 _sphereId)`: Retrieves a user's reputation score specific to a given Context Sphere.
// 16. `getOverallReputation(address _user)`: Calculates and returns a user's aggregated reputation across all their affiliated Context Spheres.
// 17. `decayReputation(address _user)`: A callable system function (e.g., by a keeper network or designated oracle) that periodically reduces a user's reputation if inactive.
// 18. `stakeForEchoVerification(uint256 _echoId) payable`: Allows users to stake tokens (ETH) to vouch for the quality or accuracy of an Echo.
// 19. `claimVerificationReward(uint256 _echoId)`: Enables stakers to claim rewards if the Echo they vouched for remains unflagged/highly rated over time.
// 20. `slashStake(uint256 _echoId, address _staker)`: Allows the system or designated oracle to slash staked tokens if an Echo is confirmed as problematic (e.g., flagged, retracted).
// 21. `distributeConnectionReward(uint256 _linkId)`: Awards tokens (ETH) to the creator of a highly-rated and impactful link between Echoes, funded by a system pool.
// 22. `depositRewardPool() payable`: Allows anyone to contribute funds (ETH) to the contract's reward pool.
// 23. `getEchoDetails(uint256 _echoId)`: Retrieves all stored details for a specific Echo.
// 24. `getLinkedEchoes(uint256 _echoId, bool _isOutgoing)`: Returns an array of Echo IDs directly linked to (or from) a given Echo.
// 25. `getUserEchoes(address _user)`: Retrieves a list of all Echo IDs created by a specific user.
// 26. `getEchoesInContextSphere(uint256 _sphereId)`: Retrieves a list of Echo IDs directly affiliated with a specific Context Sphere.
// 27. `getTopRatedEchoes(uint256 _contextSphereId, uint256 _limit)`: Retrieves a list of top-rated Echo IDs within a specific Context Sphere, up to a limit.
// 28. `setSystemParameters(uint256 _reputationDecayRate, uint256 _minStakeAmount, uint256 _connectionRewardFactor)`: Allows the contract owner to adjust core system parameters.
// 29. `emergencyTogglePause()`: Allows the contract owner to pause/unpause critical functions in an emergency.

contract EtherealEchoes {
    address public owner;
    bool public paused;

    // --- Core Data Structures ---

    struct Echo {
        uint256 id;
        address creator;
        string contentHash; // e.g., IPFS CID
        uint64 timestamp;
        uint64 lastInteraction; // For reputation decay tracking
        uint256 totalContextualRating; // Sum of all ratings, adjusted for number of ratings
        uint256 numRatings;
        bool isFlagged;
        bool isRetracted;
        uint256[] incomingLinks; // IDs of links where this is _toEchoId
        uint256[] outgoingLinks; // IDs of links where this is _fromEchoId
    }

    struct Link {
        uint256 id;
        uint256 fromEchoId;
        uint256 toEchoId;
        address linker;
        string context; // e.g., "expands on", "contradicts", "is a source for"
        uint64 timestamp;
        int256 totalLinkRating; // Rating for the link's relevance/insightfulness
        uint256 numLinkRatings;
    }

    struct ContextSphere {
        uint256 id;
        string name;
        string description;
        address admin; // Can be a multi-sig or DAO later
        mapping(address => bool) members;
        uint256[] affiliatedEchoes; // Echoes explicitly added/associated with this sphere
        uint256 memberCount;
    }

    struct MergeProposal {
        uint256 sphereId1;
        uint256 sphereId2;
        uint64 creationTime;
        mapping(address => bool) voted;
        uint256 votesFor;
        uint256 votesAgainst;
        bool resolved;
        bool approved;
    }

    // --- State Variables ---

    uint256 public nextEchoId;
    uint256 public nextLinkId;
    uint256 public nextContextSphereId;
    uint256 public nextMergeProposalId;

    mapping(uint256 => Echo) public echoes;
    mapping(uint256 => Link) public links;
    mapping(uint256 => ContextSphere) public contextSpheres;
    mapping(uint256 => MergeProposal) public mergeProposals;

    // Mapping: user => sphereId => reputation score (e.g., -1000 to 1000)
    mapping(address => mapping(uint256 => int256)) public userContextualReputation;
    // Mapping: user => list of spheres they are a member of
    mapping(address => uint256[]) public userContextSphereMemberships;
    // Mapping: user => list of echoes they created
    mapping(address => uint256[]) public userCreatedEchoes;
    // Mapping: echoId => staker address => amount staked
    mapping(uint256 => mapping(address => uint256)) public echoStakes;
    // Mapping: echoId => total staked amount on this echo
    mapping(uint256 => uint256) public totalStakedOnEcho;

    // System Parameters (Configurable by owner)
    uint256 public reputationDecayRatePerDay; // Points per day, 0 to disable
    uint256 public minStakeAmount; // Minimum ETH to stake for verification
    uint256 public connectionRewardFactor; // Multiplier for connection rewards (wei)
    uint256 public mergeProposalVoteDuration = 7 days; // Duration for voting on merge proposals

    // --- Events ---

    event EchoSubmitted(uint256 indexed echoId, address indexed creator, string contentHash, uint64 timestamp);
    event EchoLinked(uint256 indexed linkId, uint256 indexed fromEchoId, uint256 indexed toEchoId, address indexed linker);
    event EchoUnlinked(uint256 indexed linkId);
    event EchoRated(uint256 indexed echoId, address indexed rater, int8 rating, uint256 indexed contextSphereId);
    event EchoFlagged(uint256 indexed echoId, address indexed flagger, string reason);
    event FlagResolved(uint256 indexed echoId, address indexed resolver, bool isVandalism, string resolutionNotes);
    event EchoRetracted(uint256 indexed echoId, address indexed creator);
    event ContextSphereCreated(uint256 indexed sphereId, string name, address indexed admin);
    event ContextSphereJoined(uint256 indexed sphereId, address indexed member);
    event ContextSphereLeft(uint256 indexed sphereId, address indexed member);
    event ContextSphereUpdated(uint256 indexed sphereId, string newName, string newDescription);
    event ContextSphereAdminDelegated(uint256 indexed sphereId, address indexed oldAdmin, address indexed newAdmin);
    event ContextSphereMergeProposed(uint256 indexed proposalId, uint256 indexed sphereId1, uint256 indexed sphereId2, address indexed proposer);
    event ContextSphereMergeVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event ContextSphereMerged(uint256 indexed sphereId1, uint256 indexed sphereId2);
    event ReputationUpdated(address indexed user, uint256 indexed sphereId, int256 newReputation);
    event StakeForVerification(uint256 indexed echoId, address indexed staker, uint256 amount);
    event VerificationRewardClaimed(uint256 indexed echoId, address indexed staker, uint256 amount);
    event StakeSlashed(uint256 indexed echoId, address indexed staker, uint256 amount);
    event ConnectionRewardDistributed(uint256 indexed linkId, address indexed linker, uint256 amount);
    event RewardPoolDeposited(address indexed depositor, uint256 amount);
    event SystemParametersUpdated(uint256 reputationDecayRate, uint256 minStake, uint256 connectionFactor);
    event Paused(address account);
    event Unpaused(address account);

    // --- Errors ---

    error NotOwner();
    error PausedContract();
    error NotAdmin(uint256 sphereId);
    error NotSphereMember(uint256 sphereId);
    error AlreadyMember(uint256 sphereId);
    error InvalidEchoId(uint256 echoId);
    error InvalidLinkId(uint256 linkId);
    error InvalidContextSphereId(uint256 sphereId);
    error InvalidMergeProposalId(uint256 proposalId);
    error AlreadyFlagged(uint256 echoId);
    error NotFlagged(uint256 echoId);
    error NotEchoCreator(uint256 echoId);
    error NotLinkCreator(uint256 linkId);
    error MinStakeNotMet(uint256 requiredAmount);
    error NoStakeToClaim();
    error NoStakeToSlash();
    error AlreadyVoted(uint256 proposalId);
    error MergeProposalExpired(uint256 proposalId);
    error MergeProposalNotExpired(uint256 proposalId);
    error MergeProposalResolved(uint256 proposalId);
    error NoRewardPoolBalance();
    error NothingToClaim();

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert PausedContract();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert PausedContract(); // More precisely: revert if not paused.
        _;
    }

    constructor() {
        owner = msg.sender;
        paused = false;
        nextEchoId = 1;
        nextLinkId = 1;
        nextContextSphereId = 1;
        nextMergeProposalId = 1;

        // Default parameters (can be changed by owner)
        reputationDecayRatePerDay = 5; // Decay 5 points per day
        minStakeAmount = 0.01 ether; // 0.01 ETH minimum stake
        connectionRewardFactor = 0.001 ether; // 0.001 ETH base reward
    }

    receive() external payable {
        emit RewardPoolDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        emit RewardPoolDeposited(msg.sender, msg.value);
    }

    // --- 6. Core Echo Management ---

    /**
     * @notice Creates a new "Echo" with a unique ID, storing a content hash (e.g., IPFS CID).
     * @param _contentHash The content identifier for the Echo (e.g., IPFS hash).
     * @return The ID of the newly created Echo.
     */
    function submitEcho(string calldata _contentHash) external whenNotPaused returns (uint256) {
        uint256 echoId = nextEchoId++;
        echoes[echoId] = Echo({
            id: echoId,
            creator: msg.sender,
            contentHash: _contentHash,
            timestamp: uint64(block.timestamp),
            lastInteraction: uint64(block.timestamp),
            totalContextualRating: 0,
            numRatings: 0,
            isFlagged: false,
            isRetracted: false,
            incomingLinks: new uint256[](0),
            outgoingLinks: new uint256[](0)
        });
        userCreatedEchoes[msg.sender].push(echoId);
        emit EchoSubmitted(echoId, msg.sender, _contentHash, uint64(block.timestamp));
        return echoId;
    }

    /**
     * @notice Establishes a directed link between two existing Echoes, with optional contextual metadata.
     * @param _fromEchoId The ID of the source Echo.
     * @param _toEchoId The ID of the destination Echo.
     * @param _linkContext An optional description of the relationship between the Echoes (e.g., "expands on").
     * @return The ID of the newly created link.
     */
    function linkEchoes(uint256 _fromEchoId, uint256 _toEchoId, string calldata _linkContext) external whenNotPaused returns (uint256) {
        if (echoes[_fromEchoId].creator == address(0)) revert InvalidEchoId(_fromEchoId);
        if (echoes[_toEchoId].creator == address(0)) revert InvalidEchoId(_toEchoId);
        if (_fromEchoId == _toEchoId) revert("Cannot link an echo to itself");

        uint256 linkId = nextLinkId++;
        links[linkId] = Link({
            id: linkId,
            fromEchoId: _fromEchoId,
            toEchoId: _toEchoId,
            linker: msg.sender,
            context: _linkContext,
            timestamp: uint64(block.timestamp),
            totalLinkRating: 0,
            numLinkRatings: 0
        });

        echoes[_fromEchoId].outgoingLinks.push(linkId);
        echoes[_toEchoId].incomingLinks.push(linkId);

        // Update last interaction for linked echoes
        echoes[_fromEchoId].lastInteraction = uint64(block.timestamp);
        echoes[_toEchoId].lastInteraction = uint64(block.timestamp);

        emit EchoLinked(linkId, _fromEchoId, _toEchoId, msg.sender);
        return linkId;
    }

    /**
     * @notice Removes an existing link between Echoes, callable by the linker or the creator of either Echo.
     * @param _linkId The ID of the link to remove.
     */
    function unlinkEchoes(uint256 _linkId) external whenNotPaused {
        Link storage link = links[_linkId];
        if (link.linker == address(0)) revert InvalidLinkId(_linkId);

        address fromEchoCreator = echoes[link.fromEchoId].creator;
        address toEchoCreator = echoes[link.toEchoId].creator;

        if (msg.sender != link.linker && msg.sender != fromEchoCreator && msg.sender != toEchoCreator && msg.sender != owner) {
            revert NotLinkCreator(_linkId); // This implies the sender is not one of the allowed parties
        }

        // Remove link from Echoes' incoming/outgoing lists (simplified for brevity, proper impl would iterate and remove)
        // For production, consider a more gas-efficient removal or just marking as inactive.
        echoes[link.fromEchoId].outgoingLinks.pop(); // Simplistic removal, assumes last element is the target.
        echoes[link.toEchoId].incomingLinks.pop(); // A real implementation would need to iterate and find/remove.

        delete links[_linkId]; // Remove the link itself
        emit EchoUnlinked(_linkId);
    }

    /**
     * @notice Provides a contextual rating (e.g., -5 to 5) for an Echo, influencing its relevance within a specific Context Sphere.
     * @param _echoId The ID of the Echo to rate.
     * @param _rating The rating value (-5 to 5).
     * @param _contextSphereId The Context Sphere within which the rating applies.
     */
    function rateEcho(uint256 _echoId, int8 _rating, uint256 _contextSphereId) external whenNotPaused {
        Echo storage echo = echoes[_echoId];
        if (echo.creator == address(0)) revert InvalidEchoId(_echoId);
        if (contextSpheres[_contextSphereId].admin == address(0)) revert InvalidContextSphereId(_contextSphereId);
        if (!contextSpheres[_contextSphereId].members[msg.sender]) revert NotSphereMember(_contextSphereId);
        if (_rating < -5 || _rating > 5) revert("Rating must be between -5 and 5");

        // Update Echo's overall rating
        echo.totalContextualRating += _rating;
        echo.numRatings++;
        echo.lastInteraction = uint64(block.timestamp);

        // Update user's contextual reputation based on their rating activity
        // Higher positive impact for constructive rating, negative for spammy/abusive
        userContextualReputation[msg.sender][_contextSphereId] += _rating; // Simplified impact

        emit EchoRated(_echoId, msg.sender, _rating, _contextSphereId);
    }

    /**
     * @notice Flags an Echo for review (e.g., spam, misinformation), initiating a community/admin moderation process.
     * @param _echoId The ID of the Echo to flag.
     * @param _reason The reason for flagging.
     */
    function flagEcho(uint256 _echoId, string calldata _reason) external whenNotPaused {
        Echo storage echo = echoes[_echoId];
        if (echo.creator == address(0)) revert InvalidEchoId(_echoId);
        if (echo.isFlagged) revert AlreadyFlagged(_echoId);

        echo.isFlagged = true;
        // In a more complex system, this would log to a queue, potentially with stake.
        // For this contract, simply marking it as flagged.
        emit EchoFlagged(_echoId, msg.sender, _reason);
    }

    /**
     * @notice Resolves a flagged Echo; if deemed vandalism, the flagger's reputation might be penalized.
     * Callable by Context Sphere admins or the contract owner.
     * @param _echoId The ID of the flagged Echo.
     * @param _isVandalism True if the flag was malicious/false, impacting the flagger.
     * @param _resolutionNotes Notes about the resolution.
     */
    function resolveFlag(uint256 _echoId, bool _isVandalism, string calldata _resolutionNotes) external whenNotPaused {
        Echo storage echo = echoes[_echoId];
        if (echo.creator == address(0)) revert InvalidEchoId(_echoId);
        if (!echo.isFlagged) revert NotFlagged(_echoId);

        // This function requires a mechanism to determine who can resolve.
        // For simplicity, let's say owner or relevant sphere admins.
        // A full system would involve a voting or challenge mechanism.
        if (msg.sender != owner) {
            bool authorizedResolver = false;
            for(uint i=0; i<userContextSphereMemberships[msg.sender].length; i++) {
                uint256 sphereId = userContextSphereMemberships[msg.sender][i];
                if(contextSpheres[sphereId].admin == msg.sender) {
                    authorizedResolver = true;
                    break;
                }
            }
            if(!authorizedResolver) revert NotOwner(); // Not owner and not sphere admin
        }

        echo.isFlagged = false; // Mark as resolved
        if (_isVandalism) {
            // Penalize the original flagger if found (needs a way to store original flagger)
            // For now, this is a placeholder for a more complex flag resolution logic.
            // A more advanced version would use an oracle or decentralized voting to identify the malicious flagger.
        }

        emit FlagResolved(_echoId, msg.sender, _isVandalism, _resolutionNotes);
    }

    /**
     * @notice Allows the original creator to remove their Echo, potentially incurring a reputation penalty.
     * @param _echoId The ID of the Echo to retract.
     */
    function retractEcho(uint256 _echoId) external whenNotPaused {
        Echo storage echo = echoes[_echoId];
        if (echo.creator == address(0)) revert InvalidEchoId(_echoId);
        if (echo.creator != msg.sender) revert NotEchoCreator(_echoId);
        if (echo.isRetracted) revert("Echo already retracted");

        echo.isRetracted = true;
        // Apply a reputation penalty for retraction, especially if it was highly interacted with
        // Simplified: reduce creator's overall reputation by a fixed amount for now.
        // In a real system, this would be proportional to interaction/relevance.
        for(uint i=0; i<userContextSphereMemberships[msg.sender].length; i++) {
            uint256 sphereId = userContextSphereMemberships[msg.sender][i];
            userContextualReputation[msg.sender][sphereId] -= 10; // Placeholder penalty
            emit ReputationUpdated(msg.sender, sphereId, userContextualReputation[msg.sender][sphereId]);
        }
        
        emit EchoRetracted(_echoId, msg.sender);
    }

    // --- 7. Context Sphere Management ---

    /**
     * @notice Initializes a new Context Sphere, becoming its initial administrator.
     * @param _name The name of the new Context Sphere.
     * @param _description A description of the sphere's purpose or theme.
     * @return The ID of the newly created Context Sphere.
     */
    function createContextSphere(string calldata _name, string calldata _description) external whenNotPaused returns (uint256) {
        uint256 sphereId = nextContextSphereId++;
        ContextSphere storage newSphere = contextSpheres[sphereId];
        newSphere.id = sphereId;
        newSphere.name = _name;
        newSphere.description = _description;
        newSphere.admin = msg.sender;
        newSphere.members[msg.sender] = true;
        newSphere.memberCount = 1;

        userContextSphereMemberships[msg.sender].push(sphereId);

        emit ContextSphereCreated(sphereId, _name, msg.sender);
        return sphereId;
    }

    /**
     * @notice Allows a user to become a member of a Context Sphere.
     * @param _sphereId The ID of the Context Sphere to join.
     */
    function joinContextSphere(uint256 _sphereId) external whenNotPaused {
        ContextSphere storage sphere = contextSpheres[_sphereId];
        if (sphere.admin == address(0)) revert InvalidContextSphereId(_sphereId);
        if (sphere.members[msg.sender]) revert AlreadyMember(_sphereId);

        sphere.members[msg.sender] = true;
        sphere.memberCount++;
        userContextSphereMemberships[msg.sender].push(_sphereId);
        // Initialize reputation for new member in this sphere
        userContextualReputation[msg.sender][_sphereId] = 0;

        emit ContextSphereJoined(_sphereId, msg.sender);
    }

    /**
     * @notice Allows a user to leave a Context Sphere, potentially impacting their contextual reputation.
     * @param _sphereId The ID of the Context Sphere to leave.
     */
    function leaveContextSphere(uint256 _sphereId) external whenNotPaused {
        ContextSphere storage sphere = contextSpheres[_sphereId];
        if (sphere.admin == address(0)) revert InvalidContextSphereId(_sphereId);
        if (!sphere.members[msg.sender]) revert NotSphereMember(_sphereId);
        if (sphere.admin == msg.sender) revert("Admin cannot leave their own sphere directly");

        sphere.members[msg.sender] = false;
        sphere.memberCount--;

        // Remove from user's membership list (simplified, a real impl would iterate and remove)
        uint256[] storage memberships = userContextSphereMemberships[msg.sender];
        for (uint i = 0; i < memberships.length; i++) {
            if (memberships[i] == _sphereId) {
                memberships[i] = memberships[memberships.length - 1];
                memberships.pop();
                break;
            }
        }
        
        // Clear contextual reputation for this sphere
        delete userContextualReputation[msg.sender][_sphereId];

        emit ContextSphereLeft(_sphereId, msg.sender);
    }

    /**
     * @notice Allows a sphere administrator to update its name or description.
     * @param _sphereId The ID of the Context Sphere.
     * @param _newName The new name for the sphere.
     * @param _newDescription The new description for the sphere.
     */
    function updateContextSphere(uint256 _sphereId, string calldata _newName, string calldata _newDescription) external whenNotPaused {
        ContextSphere storage sphere = contextSpheres[_sphereId];
        if (sphere.admin == address(0)) revert InvalidContextSphereId(_sphereId);
        if (sphere.admin != msg.sender) revert NotAdmin(_sphereId);

        sphere.name = _newName;
        sphere.description = _newDescription;

        emit ContextSphereUpdated(_sphereId, _newName, _newDescription);
    }

    /**
     * @notice Transfers administrative control of a Context Sphere. Only callable by the current admin.
     * @param _sphereId The ID of the Context Sphere.
     * @param _newAdmin The address of the new administrator.
     */
    function delegateContextSphereAdmin(uint256 _sphereId, address _newAdmin) external whenNotPaused {
        ContextSphere storage sphere = contextSpheres[_sphereId];
        if (sphere.admin == address(0)) revert InvalidContextSphereId(_sphereId);
        if (sphere.admin != msg.sender) revert NotAdmin(_sphereId);
        if (_newAdmin == address(0)) revert("New admin cannot be zero address");

        address oldAdmin = sphere.admin;
        sphere.admin = _newAdmin;

        // Ensure new admin is a member (or make them one)
        if (!sphere.members[_newAdmin]) {
            sphere.members[_newAdmin] = true;
            sphere.memberCount++;
            userContextSphereMemberships[_newAdmin].push(_sphereId);
        }

        emit ContextSphereAdminDelegated(_sphereId, oldAdmin, _newAdmin);
    }

    /**
     * @notice Initiates a proposal to merge two Context Spheres, requiring consensus from members.
     * Only members of either sphere can propose.
     * @param _sphereId1 The ID of the first Context Sphere.
     * @param _sphereId2 The ID of the second Context Sphere.
     * @return The ID of the new merge proposal.
     */
    function proposeContextSphereMerge(uint256 _sphereId1, uint256 _sphereId2) external whenNotPaused returns (uint256) {
        ContextSphere storage s1 = contextSpheres[_sphereId1];
        ContextSphere storage s2 = contextSpheres[_sphereId2];

        if (s1.admin == address(0)) revert InvalidContextSphereId(_sphereId1);
        if (s2.admin == address(0)) revert InvalidContextSphereId(_sphereId2);
        if (_sphereId1 == _sphereId2) revert("Cannot merge a sphere with itself");
        if (!s1.members[msg.sender] && !s2.members[msg.sender]) revert NotSphereMember(_sphereId1); // Member of neither

        uint256 proposalId = nextMergeProposalId++;
        mergeProposals[proposalId] = MergeProposal({
            sphereId1: _sphereId1,
            sphereId2: _sphereId2,
            creationTime: uint64(block.timestamp),
            voted: new mapping(address => bool)(),
            votesFor: 0,
            votesAgainst: 0,
            resolved: false,
            approved: false
        });

        emit ContextSphereMergeProposed(proposalId, _sphereId1, _sphereId2, msg.sender);
        return proposalId;
    }

    /**
     * @notice Members of the proposed spheres vote on a merge proposal.
     * @param _proposalId The ID of the merge proposal.
     * @param _approve True to vote for approval, false to vote against.
     */
    function voteOnContextSphereMerge(uint256 _proposalId, bool _approve) external whenNotPaused {
        MergeProposal storage proposal = mergeProposals[_proposalId];
        if (proposal.creationTime == 0) revert InvalidMergeProposalId(_proposalId);
        if (proposal.resolved) revert MergeProposalResolved(_proposalId);
        if (block.timestamp >= proposal.creationTime + mergeProposalVoteDuration) revert MergeProposalExpired(_proposalId);
        if (proposal.voted[msg.sender]) revert AlreadyVoted(_proposalId);

        ContextSphere storage s1 = contextSpheres[proposal.sphereId1];
        ContextSphere storage s2 = contextSpheres[proposal.sphereId2];

        if (!s1.members[msg.sender] && !s2.members[msg.sender]) revert NotSphereMember(proposal.sphereId1); // Member of neither

        proposal.voted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit ContextSphereMergeVoted(_proposalId, msg.sender, _approve);

        // Check if resolution criteria met (e.g., simple majority or quorum + majority)
        // For simplicity, let's say 50%+1 of *total members in both spheres* need to vote for it.
        // This is complex to do fully on-chain for gas, so we'll simplify.
        // A more robust system would calculate quorum based on `s1.memberCount + s2.memberCount`.
        // Here, we'll allow anyone to call `resolveMergeProposal` after duration.
    }

    /**
     * @notice Allows anyone to finalize a merge proposal after its voting period expires.
     * @param _proposalId The ID of the merge proposal to resolve.
     */
    function resolveMergeProposal(uint256 _proposalId) external whenNotPaused {
        MergeProposal storage proposal = mergeProposals[_proposalId];
        if (proposal.creationTime == 0) revert InvalidMergeProposalId(_proposalId);
        if (proposal.resolved) revert MergeProposalResolved(_proposalId);
        if (block.timestamp < proposal.creationTime + mergeProposalVoteDuration) revert MergeProposalNotExpired(_proposalId);

        ContextSphere storage s1 = contextSpheres[proposal.sphereId1];
        ContextSphere storage s2 = contextSpheres[proposal.sphereId2];

        // Determine if approved (simple majority of those who voted)
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.approved = true;
            // Merge logic: move all members and affiliated echoes from s2 to s1
            // Simplistic: iterating and adding members and affiliatedEchoes is gas-intensive.
            // A real system might involve burning s2 and creating a new s1, or more advanced state management.

            // Transfer members from s2 to s1
            for (uint i = 0; i < userContextSphereMemberships[s2.admin].length; i++) { // Only s2.admin for simplicity
                if (userContextSphereMemberships[s2.admin][i] == s2.id) {
                    userContextSphereMemberships[s2.admin][i] = s1.id; // Reassign
                }
            }
            // All members of s2 are now members of s1
            // This would require iterating through all members of s2, which is highly gas-intensive.
            // A more practical approach would be to have a separate off-chain service manage memberships
            // and update on-chain via a trusted oracle or multi-sig, or only allow small spheres to merge.
            // For now, this remains a conceptual function.
            
            // Transfer affiliated echoes from s2 to s1
            for (uint i = 0; i < s2.affiliatedEchoes.length; i++) {
                s1.affiliatedEchoes.push(s2.affiliatedEchoes[i]);
            }

            // Remove s2 (or mark as inactive)
            delete contextSpheres[s2.id];

            emit ContextSphereMerged(s1.id, s2.id);
        } else {
            proposal.approved = false;
        }
        proposal.resolved = true;
    }

    // --- 8. Reputation & Scoring ---

    /**
     * @notice Retrieves a user's reputation score specific to a given Context Sphere.
     * @param _user The address of the user.
     * @param _sphereId The ID of the Context Sphere.
     * @return The user's contextual reputation score.
     */
    function getContextualReputation(address _user, uint256 _sphereId) external view returns (int256) {
        if (contextSpheres[_sphereId].admin == address(0)) revert InvalidContextSphereId(_sphereId);
        return userContextualReputation[_user][_sphereId];
    }

    /**
     * @notice Calculates and returns a user's aggregated reputation across all their affiliated Context Spheres.
     * This is a simplified sum. A more advanced system might use weighted averages or other metrics.
     * @param _user The address of the user.
     * @return The user's overall aggregated reputation score.
     */
    function getOverallReputation(address _user) external view returns (int256) {
        int256 overallRep = 0;
        uint256[] storage memberships = userContextSphereMemberships[_user];
        for (uint i = 0; i < memberships.length; i++) {
            overallRep += userContextualReputation[_user][memberships[i]];
        }
        return overallRep;
    }

    /**
     * @notice A callable system function (e.g., by a keeper network or designated oracle) that
     * periodically reduces a user's reputation if inactive within a sphere.
     * For demonstration, this is callable by anyone, but in production would be permissioned.
     * @param _user The address of the user whose reputation to decay.
     */
    function decayReputation(address _user) external whenNotPaused {
        // In a production system, this would likely be called by a trusted oracle or keeper.
        // For simplicity, anyone can trigger, but it only affects the target user's reputation.
        uint256[] storage memberships = userContextSphereMemberships[_user];
        for (uint i = 0; i < memberships.length; i++) {
            uint256 sphereId = memberships[i];
            // Get last interaction for the user in this sphere, or a global user interaction timestamp.
            // For simplicity, we'll use Echo interactions or rely on external keeper logic.
            // Here, we simplify to just decaying a flat rate. A true system would check `lastInteraction`
            // within the context of the sphere.
            
            // Placeholder: Assume reputation decays if not actively contributing.
            // This example simplifies, a real one needs a timestamp for last activity per user per sphere.
            int224 decayAmount = int224(reputationDecayRatePerDay); // Fixed decay per day
            
            if (userContextualReputation[_user][sphereId] > 0) {
                userContextualReputation[_user][sphereId] = (userContextualReputation[_user][sphereId] - decayAmount < 0) ? 0 : userContextualReputation[_user][sphereId] - decayAmount;
            } else if (userContextualReputation[_user][sphereId] < 0) {
                userContextualReputation[_user][sphereId] = (userContextualReputation[_user][sphereId] + decayAmount > 0) ? 0 : userContextualReputation[_user][sphereId] + decayAmount;
            }

            emit ReputationUpdated(_user, sphereId, userContextualReputation[_user][sphereId]);
        }
    }

    // --- 9. Staking & Rewards ---

    /**
     * @notice Allows users to stake tokens (ETH) to vouch for the quality or accuracy of an Echo.
     * @param _echoId The ID of the Echo to stake on.
     */
    function stakeForEchoVerification(uint256 _echoId) external payable whenNotPaused {
        if (echoes[_echoId].creator == address(0)) revert InvalidEchoId(_echoId);
        if (msg.value < minStakeAmount) revert MinStakeNotMet(minStakeAmount);

        echoStakes[_echoId][msg.sender] += msg.value;
        totalStakedOnEcho[_echoId] += msg.value;

        emit StakeForVerification(_echoId, msg.sender, msg.value);
    }

    /**
     * @notice Enables stakers to claim rewards if the Echo they vouched for remains unflagged/highly rated over time.
     * Simplified: reward is proportional to stake and Echo's positive rating, after a certain period.
     * @param _echoId The ID of the Echo.
     */
    function claimVerificationReward(uint256 _echoId) external whenNotPaused {
        Echo storage echo = echoes[_echoId];
        if (echo.creator == address(0)) revert InvalidEchoId(_echoId);
        if (echoStakes[_echoId][msg.sender] == 0) revert NoStakeToClaim();
        if (echo.isFlagged || echo.isRetracted) revert("Cannot claim reward for problematic echo");
        // Add time condition: e.g., only after 30 days and if ratings are positive
        if (block.timestamp < echo.timestamp + 30 days) revert("Echo too new to claim reward");
        if (echo.totalContextualRating <= 0) revert("Echo rating too low to claim reward");

        uint256 stakeAmount = echoStakes[_echoId][msg.sender];
        uint256 rewardAmount = (stakeAmount * echo.totalContextualRating) / (1000 * echo.numRatings); // Simplified proportional reward

        if (address(this).balance < rewardAmount) revert NoRewardPoolBalance();

        // Transfer reward (if any)
        if (rewardAmount > 0) {
            (bool success,) = msg.sender.call{value: rewardAmount}("");
            if (!success) revert("Failed to send reward");
            emit VerificationRewardClaimed(_echoId, msg.sender, rewardAmount);
        } else {
             revert NothingToClaim();
        }

        // Clear the stake after claiming
        totalStakedOnEcho[_echoId] -= stakeAmount;
        delete echoStakes[_echoId][msg.sender];
    }

    /**
     * @notice Allows the system or designated oracle to slash staked tokens if an Echo is confirmed as problematic.
     * Callable by owner for now, but in a real system would be triggered by a decentralized moderation.
     * @param _echoId The ID of the Echo.
     * @param _staker The address of the staker to slash.
     */
    function slashStake(uint256 _echoId, address _staker) external onlyOwner whenNotPaused {
        Echo storage echo = echoes[_echoId];
        if (echo.creator == address(0)) revert InvalidEchoId(_echoId);
        if (echoStakes[_echoId][_staker] == 0) revert NoStakeToSlash();

        // This function is assumed to be called after a conclusive decision (e.g., decentralized vote, oracle)
        // that the Echo is indeed problematic and the stake supporting it should be slashed.
        uint256 slashedAmount = echoStakes[_echoId][_staker];
        // Slashed amount can be burned, sent to treasury, or used to compensate victims.
        // For simplicity, it stays in the contract's reward pool (effectively removed from circulation for staker).
        totalStakedOnEcho[_echoId] -= slashedAmount;
        delete echoStakes[_echoId][_staker];

        emit StakeSlashed(_echoId, _staker, slashedAmount);
    }

    /**
     * @notice Awards tokens (ETH) to the creator of a highly-rated and impactful link between Echoes, funded by a system pool.
     * Callable by anyone, but only if the link meets criteria for reward.
     * @param _linkId The ID of the link to reward.
     */
    function distributeConnectionReward(uint256 _linkId) external whenNotPaused {
        Link storage link = links[_linkId];
        if (link.linker == address(0)) revert InvalidLinkId(_linkId);
        
        // Reward criteria: link must be highly rated itself, and connecting two well-regarded Echoes
        if (link.totalLinkRating <= 0 || link.numLinkRatings < 5) revert("Link not highly rated enough for reward");
        
        uint256 rewardAmount = (link.totalLinkRating * connectionRewardFactor) / link.numLinkRatings;

        if (address(this).balance < rewardAmount) revert NoRewardPoolBalance();
        if (rewardAmount == 0) revert NothingToClaim();

        (bool success,) = link.linker.call{value: rewardAmount}("");
        if (!success) revert("Failed to send connection reward");

        emit ConnectionRewardDistributed(_linkId, link.linker, rewardAmount);
    }

    /**
     * @notice Allows anyone to contribute funds (ETH) to the contract's reward pool.
     */
    function depositRewardPool() external payable {
        emit RewardPoolDeposited(msg.sender, msg.value);
    }

    // --- 10. Query & Discovery ---

    /**
     * @notice Retrieves all stored details for a specific Echo.
     * @param _echoId The ID of the Echo.
     * @return All details of the Echo.
     */
    function getEchoDetails(uint256 _echoId)
        external
        view
        returns (
            uint256 id,
            address creator,
            string memory contentHash,
            uint64 timestamp,
            uint64 lastInteraction,
            uint256 totalContextualRating,
            uint256 numRatings,
            bool isFlagged,
            bool isRetracted,
            uint256[] memory incomingLinks,
            uint256[] memory outgoingLinks
        )
    {
        Echo storage echo = echoes[_echoId];
        if (echo.creator == address(0)) revert InvalidEchoId(_echoId);
        return (
            echo.id,
            echo.creator,
            echo.contentHash,
            echo.timestamp,
            echo.lastInteraction,
            echo.totalContextualRating,
            echo.numRatings,
            echo.isFlagged,
            echo.isRetracted,
            echo.incomingLinks,
            echo.outgoingLinks
        );
    }

    /**
     * @notice Returns an array of Link IDs directly linked to (or from) a given Echo.
     * @param _echoId The ID of the Echo.
     * @param _isOutgoing If true, returns outgoing links; otherwise, returns incoming links.
     * @return An array of Link IDs.
     */
    function getLinkedEchoes(uint256 _echoId, bool _isOutgoing) external view returns (uint256[] memory) {
        Echo storage echo = echoes[_echoId];
        if (echo.creator == address(0)) revert InvalidEchoId(_echoId);

        if (_isOutgoing) {
            return echo.outgoingLinks;
        } else {
            return echo.incomingLinks;
        }
    }

    /**
     * @notice Retrieves a list of all Echo IDs created by a specific user.
     * @param _user The address of the user.
     * @return An array of Echo IDs created by the user.
     */
    function getUserEchoes(address _user) external view returns (uint256[] memory) {
        return userCreatedEchoes[_user];
    }

    /**
     * @notice Retrieves a list of Echo IDs directly affiliated with a specific Context Sphere.
     * (Currently, Echoes are associated by being rated/interacted with in a sphere, or explicitly added by admin)
     * This implementation assumes `affiliatedEchoes` is populated through a separate administrative action
     * or by a rule (e.g., top-rated echoes in sphere get added to list).
     * For now, it just returns the manually added ones.
     * @param _sphereId The ID of the Context Sphere.
     * @return An array of Echo IDs affiliated with the sphere.
     */
    function getEchoesInContextSphere(uint256 _sphereId) external view returns (uint256[] memory) {
        ContextSphere storage sphere = contextSpheres[_sphereId];
        if (sphere.admin == address(0)) revert InvalidContextSphereId(_sphereId);
        return sphere.affiliatedEchoes;
    }

    /**
     * @notice Retrieves a list of top-rated Echo IDs within a specific Context Sphere, up to a limit.
     * This is a simplified implementation (no actual sorting on-chain).
     * For a real system, this would rely on off-chain indexing or a very gas-intensive on-chain sort.
     * For now, it returns the affiliated echoes, and clients would sort.
     * @param _contextSphereId The ID of the Context Sphere.
     * @param _limit The maximum number of Echoes to return.
     * @return An array of top-rated Echo IDs.
     */
    function getTopRatedEchoes(uint256 _contextSphereId, uint256 _limit) external view returns (uint256[] memory) {
        ContextSphere storage sphere = contextSpheres[_contextSphereId];
        if (sphere.admin == address(0)) revert InvalidContextSphereId(_contextSphereId);

        uint256[] memory affiliated = sphere.affiliatedEchoes;
        uint256 actualLimit = _limit > affiliated.length ? affiliated.length : _limit;
        uint256[] memory topEchoes = new uint256[](actualLimit);

        // This is not actually "top rated" on-chain due to gas costs for sorting.
        // It simply returns the first `_limit` affiliated echoes.
        // A production dApp would use off-chain indexing (e.g., The Graph) to provide true top-rated lists.
        for (uint i = 0; i < actualLimit; i++) {
            topEchoes[i] = affiliated[i];
        }
        return topEchoes;
    }

    // --- 11. System Administration ---

    /**
     * @notice Allows the contract owner to adjust core system parameters.
     * @param _reputationDecayRate The new reputation decay rate per day.
     * @param _minStakeAmount The new minimum stake amount for verification (in wei).
     * @param _connectionRewardFactor The new base reward factor for insightful connections (in wei).
     */
    function setSystemParameters(
        uint256 _reputationDecayRate,
        uint256 _minStakeAmount,
        uint256 _connectionRewardFactor
    ) external onlyOwner {
        reputationDecayRatePerDay = _reputationDecayRate;
        minStakeAmount = _minStakeAmount;
        connectionRewardFactor = _connectionRewardFactor;

        emit SystemParametersUpdated(reputationDecayRate, minStakeAmount, connectionRewardFactor);
    }

    /**
     * @notice Allows the contract owner to pause/unpause critical functions in an emergency.
     * Functions with `whenNotPaused` modifier will be affected.
     */
    function emergencyTogglePause() external onlyOwner {
        paused = !paused;
        if (paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }
}
```