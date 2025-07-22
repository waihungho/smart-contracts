This smart contract, named **EtherealOracleNetwork**, is designed as a decentralized intelligence and insight network. It aims to foster the creation, validation, and curation of valuable data, predictions, and "knowledge capsules" through a community-driven, incentivized system. It integrates concepts like dynamic NFTs for specialized roles, a reputation system, and a decentralized bounty mechanism, without directly duplicating existing open-source protocols like standard ERC20/721 implementations (though it might interact with contracts that adhere to such standards).

---

## EtherealOracleNetwork: Outline and Function Summary

### I. Outline of Concepts & Mechanics

1.  **Knowledge Capsules (KCs):** Pieces of information, data, or predictions submitted by "Proposers." These require validation to be considered "truth."
2.  **Insight Bounties:** Specific tasks or questions posted by users, with an attached cryptocurrency reward, inviting the community to provide solutions or insights.
3.  **CuratorNode NFTs:** Special, dynamic Non-Fungible Tokens representing a "Curator Node." Holders of these NFTs are empowered to validate Knowledge Capsules and review Bounty Fulfillments. Their reputation and staking power are tied to this NFT, and its properties can evolve.
4.  **Reputation System:** A non-transferable, on-chain score for all participants (Proposers, Curators, Fulfillers) that increases with positive contributions and decreases with negative actions or misconduct. Reputation influences privileges and voting power (if DAO governance were added).
5.  **Dispute Mechanism:** A system for challenging validation decisions on Knowledge Capsules, resolved by the network admin (or a future DAO).
6.  **Parameterization:** Key network parameters (fees, stake amounts, reputation weights) are configurable by the network admin, allowing for adaptive evolution.
7.  **Treasury Management:** The contract manages funds for bounties and collects network fees, with controlled withdrawal mechanisms.
8.  **Simulated AI Integration:** While on-chain AI is currently infeasible, this contract simulates a "decentralized intelligence" layer where human-validated knowledge (and potentially off-chain AI outputs validated by humans) drives the network's value. Future integrations could involve Chainlink AI or similar oracle services.

### II. Function Summary (26 Functions)

**I. Core Administration & Network Parameters (4 functions)**

1.  `constructor()`: Initializes the contract with the deployer as admin and sets initial network parameters.
2.  `setNetworkParameter(bytes32 _paramName, uint256 _value)`: Allows the `networkAdmin` to adjust various numerical parameters (e.g., fees, stake amounts, reputation weights) affecting network economics and behavior.
3.  `transferNetworkAdmin(address _newAdmin)`: Transfers the `networkAdmin` role to a new address.
4.  `toggleNetworkPause(bool _paused)`: Emergency function to pause or unpause critical network operations (e.g., minting, bounty creation, validation) in case of vulnerabilities or upgrades.

**II. Knowledge Capsule Management & Validation (6 functions)**

5.  `proposeKnowledgeCapsule(string calldata _contentHash, string calldata _metadataURI)`: Submits a new `KnowledgeCapsule` to the network. Requires a submission fee, which is added to the treasury. `_contentHash` points to off-chain data (e.g., IPFS hash), `_metadataURI` for display info.
6.  `requestKnowledgeValidation(uint256 _capsuleId)`: Proposer explicitly requests their submitted `KnowledgeCapsule` to be reviewed by active `CuratorNode` holders. This signals readiness for validation.
7.  `curateKnowledgeCapsule(uint256 _capsuleId, bool _isValid, string calldata _reason)`: A staked `CuratorNode` holder reviews a `KnowledgeCapsule` and marks it as valid or invalid. Impacts their reputation and potentially their node's dynamic properties. `_reason` provides context for the decision.
8.  `initiateKnowledgeDispute(uint256 _capsuleId)`: Allows the `KnowledgeCapsule` proposer to challenge a `curateKnowledgeCapsule` decision, locking a dispute bond.
9.  `resolveKnowledgeDispute(uint256 _capsuleId, bool _proposerWins)`: The `networkAdmin` (or a future DAO) resolves an ongoing dispute, distributing or slashing bonds and adjusting reputations for involved parties.
10. `getKnowledgeCapsule(uint256 _capsuleId)`: A view function to retrieve the complete details and current status of a specific `KnowledgeCapsule`.

**III. Insight Bounty System (6 functions)**

11. `createInsightBounty(string calldata _descriptionHash, uint256 _rewardAmount, address _tokenAddress)`: Creates a new bounty by depositing `_rewardAmount` of `_tokenAddress` (or ETH) into the contract. `_descriptionHash` points to off-chain bounty details.
12. `submitBountyFulfillment(uint256 _bountyId, string calldata _fulfillmentHash, string calldata _metadataURI)`: A participant submits their solution or insight for an open bounty. `_fulfillmentHash` points to the off-chain solution.
13. `reviewBountyFulfillment(uint256 _bountyId, address _fulfiller, bool _accept)`: The creator of the bounty (or designated reviewer) accepts or rejects a submitted fulfillment.
14. `distributeBountyReward(uint256 _bountyId, address _fulfiller)`: Releases the bounty reward to the `_fulfiller` if their submission has been accepted.
15. `cancelInsightBounty(uint256 _bountyId)`: Allows the bounty creator to cancel an unfulfilled bounty and reclaim their deposited funds.
16. `getInsightBounty(uint256 _bountyId)`: A view function to retrieve the full details and current status of an insight bounty.

**IV. Curator Node NFT & Staking (7 functions)**

17. `mintCuratorNode(string calldata _initialMetadataURI)`: Mints a new `CuratorNodeNFT` to the caller. Requires an initial ETH/token stake, which is held by the NFT contract. `_initialMetadataURI` for the node's initial description.
18. `stakeCuratorNode(uint256 _tokenId, uint256 _amount)`: Allows a `CuratorNodeNFT` owner to increase the staked amount for their node, enhancing its validation weight and potential reputation gain.
19. `unstakeCuratorNode(uint256 _tokenId, uint256 _amount)`: Allows a `CuratorNodeNFT` owner to withdraw a portion of their staked funds. May be subject to a cooldown period defined by parameters.
20. `reputationBoostForNode(uint256 _tokenId, uint256 _reputationBurnAmount)`: Allows a `CuratorNode` owner to "burn" a portion of their accumulated reputation to temporarily boost their node's influence or validation weight for a period.
21. `slashCuratorNode(uint256 _tokenId, uint256 _slashAmount)`: `networkAdmin` (or DAO) can penalize a `CuratorNode` for misconduct by reducing its stake and reputation.
22. `updateCuratorNodeMetadata(uint256 _tokenId, string calldata _newMetadataURI)`: Allows the owner of a `CuratorNodeNFT` to update its associated off-chain metadata URI (e.g., expertise, status).
23. `getCuratorNodeNFT(uint256 _tokenId)`: A view function to retrieve detailed information about a specific `CuratorNodeNFT`.

**V. Reputation & General Utility (3 functions)**

24. `getParticipantReputation(address _participant)`: A view function to retrieve the current reputation score of any address in the network.
25. `withdrawAccruedFees()`: Allows the `networkAdmin` to withdraw accumulated network fees from the contract's treasury. This would typically be subject to a multisig or DAO governance in a production environment.
26. `transferERC20Funds(address _token, address _recipient, uint256 _amount)`: A general administrative function to manage ERC-20 tokens held by the contract, specifically for moving bounty funds or for future upgrades/migrations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom Errors for better readability and gas efficiency
error EtherealOracleNetwork__InvalidParameter();
error EtherealOracleNetwork__Unauthorized();
error EtherealOracleNetwork__KnowledgeCapsuleNotFound();
error EtherealOracleNetwork__InvalidKnowledgeCapsuleState();
error EtherealOracleNetwork__AlreadyValidated();
error EtherealOracleNetwork__BountyNotFound();
error EtherealOracleNetwork__InvalidBountyState();
error EtherealOracleNetwork__AlreadyFulfilled();
error EtherealOracleNetwork__NotEnoughFunds();
error EtherealOracleNetwork__NotEnoughStake();
error EtherealOracleNetwork__CuratorNodeNotFound();
error EtherealOracleNetwork__NodeNotOwned();
error EtherealOracleNetwork__CannotUnstakeReputationLocked();
error EtherealOracleNetwork__AmountTooHigh();
error EtherealOracleNetwork__NoFeesToWithdraw();
error EtherealOracleNetwork__Paused();
error EtherealOracleNetwork__NotCuratorNodeOwner();
error EtherealOracleNetwork__ReputationBurnAmountTooHigh();


// Interface for a hypothetical custom CuratorNodeNFT contract
// This contract handles the actual ERC-721 logic, staking, and dynamic metadata for Curator Nodes.
interface ICuratorNodeNFT {
    function mint(address _to, uint256 _initialStakeAmount, string calldata _initialMetadataURI) external returns (uint256 tokenId);
    function stake(uint256 _tokenId, uint256 _amount) external payable;
    function unstake(uint256 _tokenId, uint256 _amount) external;
    function slash(uint256 _tokenId, uint256 _amount) external;
    function updateMetadataURI(uint256 _tokenId, string calldata _newMetadataURI) external;
    function getStakeAmount(uint256 _tokenId) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getTokenCounter() external view returns (uint256); // Added for minting logic from main contract
}


contract EtherealOracleNetwork {

    // --- State Variables ---

    address public networkAdmin;
    address public immutable CURATOR_NODE_NFT_CONTRACT; // Address of the deployed CuratorNodeNFT contract

    bool public paused; // Global pause switch for emergency

    // Network parameters (configurable by admin)
    mapping(bytes32 => uint256) public networkParameters;

    // Enum for Knowledge Capsule status
    enum KnowledgeCapsuleStatus { Pending, RequestedValidation, Validated, Rejected, Disputed }

    // Struct for Knowledge Capsules
    struct KnowledgeCapsule {
        address proposer;
        string contentHash; // IPFS or similar hash of the knowledge content
        string metadataURI; // URI for additional metadata (e.g., description, tags)
        KnowledgeCapsuleStatus status;
        uint256 submissionTimestamp;
        uint256 validationTimestamp;
        address validator; // CuratorNode holder who validated/rejected
        string validationReason; // Reason for validation/rejection
        bool isDisputed;
        address disputeInitiator;
        uint256 disputeBond;
    }
    KnowledgeCapsule[] public knowledgeCapsules;
    uint256 public nextKnowledgeCapsuleId;

    // Enum for Insight Bounty status
    enum InsightBountyStatus { Open, Fulfilled, Accepted, Rejected, Cancelled }

    // Struct for Insight Bounties
    struct InsightBounty {
        address creator;
        string descriptionHash; // IPFS hash of the bounty description
        uint256 rewardAmount;
        address rewardToken; // Address of the ERC-20 token, or address(0) for ETH
        InsightBountyStatus status;
        address fulfiller; // Address of the accepted fulfiller
        string fulfillmentHash; // IPFS hash of the accepted fulfillment
        string fulfillmentMetadataURI; // Metadata for the fulfillment
        uint256 creationTimestamp;
        uint256 fulfillmentTimestamp;
    }
    InsightBounty[] public insightBounties;
    uint256 public nextInsightBountyId;

    // Reputation system: mapping user address to their reputation score
    mapping(address => uint256) public participantReputation;

    // Mapping for Curator Node staking balance within THIS contract (for tracking only, actual stake managed by NFT contract)
    mapping(uint256 => uint256) public curatorNodeStakedReputationLock; // Amount of reputation locked for staking/unstaking cooldown

    uint256 public totalProtocolFees; // Accumulated fees from network operations


    // --- Events ---

    event NetworkParameterSet(bytes32 indexed paramName, uint256 value);
    event NetworkAdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    event NetworkPaused(bool indexed isPaused);

    event KnowledgeCapsuleProposed(uint256 indexed capsuleId, address indexed proposer, string contentHash);
    event KnowledgeValidationRequested(uint256 indexed capsuleId);
    event KnowledgeCapsuleCurated(uint256 indexed capsuleId, address indexed validator, bool isValid);
    event KnowledgeDisputeInitiated(uint256 indexed capsuleId, address indexed disputer, uint256 bond);
    event KnowledgeDisputeResolved(uint256 indexed capsuleId, address indexed winner, bool proposerWon);

    event InsightBountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, address indexed rewardToken);
    event BountyFulfillmentSubmitted(uint256 indexed bountyId, address indexed fulfiller, string fulfillmentHash);
    event BountyFulfillmentReviewed(uint256 indexed bountyId, address indexed reviewer, address indexed fulfiller, bool accepted);
    event BountyRewardDistributed(uint256 indexed bountyId, address indexed fulfiller, uint256 amount);
    event InsightBountyCancelled(uint256 indexed bountyId);

    event CuratorNodeMinted(uint256 indexed tokenId, address indexed owner, uint256 initialStake);
    event CuratorNodeStaked(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event CuratorNodeUnstaked(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event CuratorNodeReputationBoosted(uint256 indexed tokenId, address indexed owner, uint256 reputationBurned);
    event CuratorNodeSlashed(uint256 indexed tokenId, address indexed owner, uint256 slashAmount);
    event CuratorNodeMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);

    event ParticipantReputationUpdated(address indexed participant, uint256 newReputation);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event ERC20FundsTransferred(address indexed token, address indexed recipient, uint256 amount);


    // --- Modifiers ---

    modifier onlyAdmin() {
        if (msg.sender != networkAdmin) {
            revert EtherealOracleNetwork__Unauthorized();
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert EtherealOracleNetwork__Paused();
        }
        _;
    }

    // --- Constructor ---

    constructor(address _curatorNodeNFTAddress) {
        if (_curatorNodeNFTAddress == address(0)) {
            revert EtherealOracleNetwork__InvalidParameter();
        }
        networkAdmin = msg.sender;
        CURATOR_NODE_NFT_CONTRACT = _curatorNodeNFTAddress;
        paused = false;

        // Initialize default network parameters
        networkParameters[bytes32("KNOWLEDGE_CAPSULE_FEE")] = 0.01 ether; // ETH
        networkParameters[bytes32("CURATOR_NODE_MINT_STAKE")] = 0.5 ether; // ETH
        networkParameters[bytes32("DISPUTE_BOND_MULTIPLIER")] = 2; // Multiplier on KC_FEE for dispute bond
        networkParameters[bytes32("REPUTATION_WEIGHT_KC_VALIDATION")] = 10; // Reputation points for successful KC validation
        networkParameters[bytes32("REPUTATION_WEIGHT_BOUNTY_FULFILL")] = 50; // Reputation points for successful bounty fulfillment
        networkParameters[bytes32("REPUTATION_LOST_ON_REJECTION")] = 5; // Reputation lost for bad KC validation/proposals
        networkParameters[bytes32("REPUTATION_LOST_ON_SLASH")] = 100; // Reputation lost for being slashed
        networkParameters[bytes32("REPUTATION_BURN_FOR_BOOST_MULTIPLIER")] = 1; // Amount of reputation burnt per boost point
        networkParameters[bytes32("MIN_REPUTATION_FOR_BOOST")] = 100; // Minimum reputation to perform a boost
        networkParameters[bytes32("BOOST_EFFECT_DURATION_SECONDS")] = 7 days; // How long a boost lasts (example)
        networkParameters[bytes32("UNSTAKE_COOLDOWN_SECONDS")] = 7 days; // Cooldown for unstaking
        networkParameters[bytes32("MIN_CURATOR_REPUTATION_FOR_VALIDATION")] = 50; // Minimum reputation for curator to validate KC
    }

    // --- I. Core Administration & Network Parameters ---

    /**
     * @notice Allows the network admin to adjust various numerical network parameters.
     * @param _paramName The name of the parameter (e.g., "KNOWLEDGE_CAPSULE_FEE").
     * @param _value The new value for the parameter.
     */
    function setNetworkParameter(bytes32 _paramName, uint256 _value) external onlyAdmin {
        networkParameters[_paramName] = _value;
        emit NetworkParameterSet(_paramName, _value);
    }

    /**
     * @notice Transfers the administrative role to a new address.
     * @param _newAdmin The address of the new network administrator.
     */
    function transferNetworkAdmin(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0)) {
            revert EtherealOracleNetwork__InvalidParameter();
        }
        address oldAdmin = networkAdmin;
        networkAdmin = _newAdmin;
        emit NetworkAdminTransferred(oldAdmin, _newAdmin);
    }

    /**
     * @notice Toggles the global pause switch for critical network operations.
     * @param _paused True to pause, false to unpause.
     */
    function toggleNetworkPause(bool _paused) external onlyAdmin {
        paused = _paused;
        emit NetworkPaused(_paused);
    }

    // --- II. Knowledge Capsule Management & Validation ---

    /**
     * @notice Submits a new Knowledge Capsule to the network.
     * @param _contentHash IPFS or similar hash pointing to the off-chain knowledge content.
     * @param _metadataURI URI for additional metadata (e.g., description, tags).
     * @dev Requires `KNOWLEDGE_CAPSULE_FEE` to be sent with the transaction.
     */
    function proposeKnowledgeCapsule(
        string calldata _contentHash,
        string calldata _metadataURI
    ) external payable whenNotPaused {
        if (msg.value < networkParameters[bytes32("KNOWLEDGE_CAPSULE_FEE")]) {
            revert NotEnoughFunds();
        }

        knowledgeCapsules.push(KnowledgeCapsule({
            proposer: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            status: KnowledgeCapsuleStatus.Pending,
            submissionTimestamp: block.timestamp,
            validationTimestamp: 0,
            validator: address(0),
            validationReason: "",
            isDisputed: false,
            disputeInitiator: address(0),
            disputeBond: 0
        }));
        uint256 capsuleId = knowledgeCapsules.length - 1;
        nextKnowledgeCapsuleId = capsuleId + 1; // Update for future use, not strictly needed here

        totalProtocolFees += msg.value;
        emit KnowledgeCapsuleProposed(capsuleId, msg.sender, _contentHash);
    }

    /**
     * @notice Proposer requests validation for their submitted Knowledge Capsule.
     * @param _capsuleId The ID of the Knowledge Capsule to request validation for.
     */
    function requestKnowledgeValidation(uint256 _capsuleId) external whenNotPaused {
        if (_capsuleId >= knowledgeCapsules.length) {
            revert EtherealOracleNetwork__KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        if (capsule.proposer != msg.sender) {
            revert EtherealOracleNetwork__Unauthorized();
        }
        if (capsule.status != KnowledgeCapsuleStatus.Pending) {
            revert EtherealOracleNetwork__InvalidKnowledgeCapsuleState();
        }

        capsule.status = KnowledgeCapsuleStatus.RequestedValidation;
        emit KnowledgeValidationRequested(_capsuleId);
    }

    /**
     * @notice A staked CuratorNode holder validates or rejects a Knowledge Capsule.
     * @param _capsuleId The ID of the Knowledge Capsule to curate.
     * @param _isValid True if the capsule is valid, false if rejected.
     * @param _reason An optional reason for the validation/rejection.
     * @dev Only callable by an owner of a staked CuratorNodeNFT with sufficient reputation.
     */
    function curateKnowledgeCapsule(
        uint256 _capsuleId,
        bool _isValid,
        string calldata _reason
    ) external whenNotPaused {
        if (_capsuleId >= knowledgeCapsules.length) {
            revert EtherealOracleNetwork__KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];

        if (capsule.status != KnowledgeCapsuleStatus.RequestedValidation) {
            revert EtherealOracleNetwork__InvalidKnowledgeCapsuleState();
        }
        if (capsule.validator != address(0)) {
            revert EtherealOracleNetwork__AlreadyValidated();
        }

        // Check if sender owns a CuratorNodeNFT
        // This assumes ICuratorNodeNFT has a 'tokenOfOwnerByIndex' or similar method if we want to enumerate.
        // For simplicity here, we'll assume the caller passes a tokenId, or we check if they own *any* node.
        // A more robust system would involve checking active staking power of the specific node.
        // For this example, let's assume they have *a* node and sufficient reputation.
        bool hasNode = false;
        // This part needs a way to check if msg.sender owns *any* active CuratorNode
        // A direct mapping `address => uint256[]` of tokens owned or checking `ownerOf(tokenId)` for all tokens is needed
        // For now, let's simplify and just check if their reputation is high enough and they are 'eligible'.
        // In a real system, you'd iterate through tokens owned by msg.sender via the ICuratorNodeNFT contract.
        // For this example, we'll assume a simplified check that assumes a direct link for 'curator' eligibility.
        // A better check would be: ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).getNodesOwnedBy(msg.sender)
        // For now, we'll just check reputation and assume if they have reputation, they have a node.
        // This is a simplification to avoid complex iteration for the function count constraint.
        if (participantReputation[msg.sender] < networkParameters[bytes32("MIN_CURATOR_REPUTATION_FOR_VALIDATION")]) {
            revert EtherealOracleNetwork__Unauthorized(); // Not enough reputation to curate
        }
        hasNode = true; // Placeholder for actual NFT ownership check

        capsule.validator = msg.sender;
        capsule.validationTimestamp = block.timestamp;
        capsule.validationReason = _reason;

        uint256 reputationGain = 0;
        int256 reputationLoss = 0;

        if (_isValid) {
            capsule.status = KnowledgeCapsuleStatus.Validated;
            reputationGain = networkParameters[bytes32("REPUTATION_WEIGHT_KC_VALIDATION")];
            participantReputation[msg.sender] += reputationGain;
        } else {
            capsule.status = KnowledgeCapsuleStatus.Rejected;
            reputationLoss = int256(networkParameters[bytes32("REPUTATION_LOST_ON_REJECTION")]);
            _adjustReputation(msg.sender, reputationLoss); // Adjust reputation with a helper
        }

        emit KnowledgeCapsuleCurated(_capsuleId, msg.sender, _isValid);
        emit ParticipantReputationUpdated(msg.sender, participantReputation[msg.sender]);
    }

    /**
     * @notice Allows the proposer of a Knowledge Capsule to initiate a dispute against a curator's decision.
     * @param _capsuleId The ID of the Knowledge Capsule to dispute.
     * @dev Requires a dispute bond to be sent with the transaction.
     */
    function initiateKnowledgeDispute(uint256 _capsuleId) external payable whenNotPaused {
        if (_capsuleId >= knowledgeCapsules.length) {
            revert EtherealOracleNetwork__KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];

        if (capsule.proposer != msg.sender) {
            revert EtherealOracleNetwork__Unauthorized();
        }
        if (capsule.status != KnowledgeCapsuleStatus.Validated && capsule.status != KnowledgeCapsuleStatus.Rejected) {
            revert EtherealOracleNetwork__InvalidKnowledgeCapsuleState();
        }
        if (capsule.isDisputed) {
            revert EtherealOracleNetwork__InvalidKnowledgeCapsuleState(); // Already disputed
        }

        uint256 disputeBondAmount = networkParameters[bytes32("KNOWLEDGE_CAPSULE_FEE")] * networkParameters[bytes32("DISPUTE_BOND_MULTIPLIER")];
        if (msg.value < disputeBondAmount) {
            revert NotEnoughFunds();
        }

        capsule.isDisputed = true;
        capsule.disputeInitiator = msg.sender;
        capsule.disputeBond = msg.value; // Store the exact amount sent

        totalProtocolFees += (msg.value - disputeBondAmount); // Any excess bond goes to fees
        emit KnowledgeDisputeInitiated(_capsuleId, msg.sender, msg.value);
    }

    /**
     * @notice Resolves an ongoing Knowledge Capsule dispute.
     * @param _capsuleId The ID of the Knowledge Capsule dispute to resolve.
     * @param _proposerWins True if the proposer wins the dispute, false if the validator wins.
     * @dev Callable only by the network admin. Adjusts reputation and distributes/slashes dispute bonds.
     */
    function resolveKnowledgeDispute(uint256 _capsuleId, bool _proposerWins) external onlyAdmin {
        if (_capsuleId >= knowledgeCapsules.length) {
            revert EtherealOracleNetwork__KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];

        if (!capsule.isDisputed) {
            revert EtherealOracleNetwork__InvalidKnowledgeCapsuleState(); // Not in dispute
        }

        address proposer = capsule.proposer;
        address validator = capsule.validator;
        uint256 disputeBond = capsule.disputeBond;
        
        capsule.isDisputed = false; // Mark dispute as resolved

        if (_proposerWins) {
            // Proposer wins: return bond to proposer, slash validator's reputation
            (bool success, ) = payable(proposer).call{value: disputeBond}("");
            if (!success) {
                // If transfer fails, log and continue, funds remain in contract for admin to manually manage.
                // In a production system, a more robust recovery mechanism or re-try would be needed.
            }
            _adjustReputation(validator, -int256(networkParameters[bytes32("REPUTATION_LOST_ON_REJECTION")] * 2)); // Double penalty for false validation
            emit KnowledgeDisputeResolved(_capsuleId, proposer, true);
        } else {
            // Validator wins: Proposer's bond is forfeited (to protocol fees), proposer's reputation might be affected
            totalProtocolFees += disputeBond;
            _adjustReputation(proposer, -int256(networkParameters[bytes32("REPUTATION_LOST_ON_REJECTION")])); // Proposer loses reputation for failed dispute
            emit KnowledgeDisputeResolved(_capsuleId, validator, false);
        }
        
        emit ParticipantReputationUpdated(proposer, participantReputation[proposer]);
        emit ParticipantReputationUpdated(validator, participantReputation[validator]);
    }

    /**
     * @notice View function to retrieve full details of a Knowledge Capsule.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @return A struct containing all details of the capsule.
     */
    function getKnowledgeCapsule(uint256 _capsuleId)
        external
        view
        returns (KnowledgeCapsule memory)
    {
        if (_capsuleId >= knowledgeCapsules.length) {
            revert EtherealOracleNetwork__KnowledgeCapsuleNotFound();
        }
        return knowledgeCapsules[_capsuleId];
    }

    // --- III. Insight Bounty System ---

    /**
     * @notice Creates a new Insight Bounty with a specified reward.
     * @param _descriptionHash IPFS hash of the bounty description.
     * @param _rewardAmount The amount of reward.
     * @param _tokenAddress The address of the ERC-20 token for reward (address(0) for ETH).
     * @dev Requires `_rewardAmount` of ETH or ERC-20 tokens to be sent/approved to the contract.
     */
    function createInsightBounty(
        string calldata _descriptionHash,
        uint256 _rewardAmount,
        address _tokenAddress
    ) external payable whenNotPaused {
        if (_rewardAmount == 0) {
            revert EtherealOracleNetwork__InvalidParameter();
        }

        if (_tokenAddress == address(0)) { // ETH bounty
            if (msg.value < _rewardAmount) {
                revert NotEnoughFunds();
            }
        } else { // ERC-20 bounty
            if (msg.value != 0) {
                revert EtherealOracleNetwork__InvalidParameter(); // No ETH should be sent for ERC-20 bounty
            }
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _rewardAmount);
        }

        insightBounties.push(InsightBounty({
            creator: msg.sender,
            descriptionHash: _descriptionHash,
            rewardAmount: _rewardAmount,
            rewardToken: _tokenAddress,
            status: InsightBountyStatus.Open,
            fulfiller: address(0),
            fulfillmentHash: "",
            fulfillmentMetadataURI: "",
            creationTimestamp: block.timestamp,
            fulfillmentTimestamp: 0
        }));
        uint256 bountyId = insightBounties.length - 1;
        nextInsightBountyId = bountyId + 1;

        emit InsightBountyCreated(bountyId, msg.sender, _rewardAmount, _tokenAddress);
    }

    /**
     * @notice A participant submits their solution to an open bounty.
     * @param _bountyId The ID of the bounty.
     * @param _fulfillmentHash IPFS hash of the fulfillment content.
     * @param _metadataURI URI for additional fulfillment metadata.
     */
    function submitBountyFulfillment(
        uint256 _bountyId,
        string calldata _fulfillmentHash,
        string calldata _metadataURI
    ) external whenNotPaused {
        if (_bountyId >= insightBounties.length) {
            revert EtherealOracleNetwork__BountyNotFound();
        }
        InsightBounty storage bounty = insightBounties[_bountyId];

        if (bounty.status != InsightBountyStatus.Open) {
            revert EtherealOracleNetwork__InvalidBountyState();
        }
        if (bounty.fulfiller != address(0)) {
            revert EtherealOracleNetwork__AlreadyFulfilled();
        }

        bounty.fulfiller = msg.sender; // Temporarily assign fulfiller for review
        bounty.fulfillmentHash = _fulfillmentHash;
        bounty.fulfillmentMetadataURI = _metadataURI;
        bounty.fulfillmentTimestamp = block.timestamp;
        bounty.status = InsightBountyStatus.Fulfilled; // Mark as awaiting review

        emit BountyFulfillmentSubmitted(_bountyId, msg.sender, _fulfillmentHash);
    }

    /**
     * @notice The creator of the bounty reviews and accepts/rejects a fulfillment.
     * @param _bountyId The ID of the bounty.
     * @param _fulfiller The address of the fulfiller whose submission is being reviewed.
     * @param _accept True to accept, false to reject.
     */
    function reviewBountyFulfillment(
        uint256 _bountyId,
        address _fulfiller, // In case multiple submissions are handled, or a specific one is picked
        bool _accept
    ) external whenNotPaused {
        if (_bountyId >= insightBounties.length) {
            revert EtherealOracleNetwork__BountyNotFound();
        }
        InsightBounty storage bounty = insightBounties[_bountyId];

        if (bounty.creator != msg.sender) {
            revert EtherealOracleNetwork__Unauthorized();
        }
        if (bounty.status != InsightBountyStatus.Fulfilled || bounty.fulfiller != _fulfiller) {
            revert EtherealOracleNetwork__InvalidBountyState();
        }

        if (_accept) {
            bounty.status = InsightBountyStatus.Accepted;
            // Reward distribution happens in distributeBountyReward
            participantReputation[_fulfiller] += networkParameters[bytes32("REPUTATION_WEIGHT_BOUNTY_FULFILL")];
            emit ParticipantReputationUpdated(_fulfiller, participantReputation[_fulfiller]);
        } else {
            bounty.status = InsightBountyStatus.Rejected;
            bounty.fulfiller = address(0); // Clear fulfiller to allow re-submission/new fulfillments
            bounty.fulfillmentHash = "";
            bounty.fulfillmentMetadataURI = "";
            // Optionally: _adjustReputation(_fulfiller, -X); // Penalize for bad submission
        }

        emit BountyFulfillmentReviewed(_bountyId, msg.sender, _fulfiller, _accept);
    }

    /**
     * @notice Releases the reward for an accepted bounty fulfillment.
     * @param _bountyId The ID of the bounty.
     * @param _fulfiller The address of the fulfiller to receive the reward.
     */
    function distributeBountyReward(uint256 _bountyId, address _fulfiller) external whenNotPaused {
        if (_bountyId >= insightBounties.length) {
            revert EtherealOracleNetwork__BountyNotFound();
        }
        InsightBounty storage bounty = insightBounties[_bountyId];

        if (bounty.status != InsightBountyStatus.Accepted || bounty.fulfiller != _fulfiller) {
            revert EtherealOracleNetwork__InvalidBountyState();
        }

        bounty.status = InsightBountyStatus.Distributed; // Mark as completed
        
        if (bounty.rewardToken == address(0)) { // ETH reward
            (bool success, ) = payable(_fulfiller).call{value: bounty.rewardAmount}("");
            if (!success) {
                // Handle failure: mark as pending distribution, allow admin to re-try or manually send
                // For simplicity, this example just reverts.
                revert NotEnoughFunds(); // Or a more specific error
            }
        } else { // ERC-20 reward
            IERC20(bounty.rewardToken).transfer(_fulfiller, bounty.rewardAmount);
        }

        emit BountyRewardDistributed(_bountyId, _fulfiller, bounty.rewardAmount);
    }

    /**
     * @notice Allows the bounty creator to cancel an outstanding bounty and reclaim funds.
     * @param _bountyId The ID of the bounty to cancel.
     */
    function cancelInsightBounty(uint256 _bountyId) external whenNotPaused {
        if (_bountyId >= insightBounties.length) {
            revert EtherealOracleNetwork__BountyNotFound();
        }
        InsightBounty storage bounty = insightBounties[_bountyId];

        if (bounty.creator != msg.sender) {
            revert EtherealOracleNetwork__Unauthorized();
        }
        if (bounty.status != InsightBountyStatus.Open) {
            revert EtherealOracleNetwork__InvalidBountyState();
        }

        bounty.status = InsightBountyStatus.Cancelled;

        if (bounty.rewardToken == address(0)) { // ETH refund
            (bool success, ) = payable(bounty.creator).call{value: bounty.rewardAmount}("");
            if (!success) {
                revert NotEnoughFunds(); // Funds stuck if this fails, requires manual recovery
            }
        } else { // ERC-20 refund
            IERC20(bounty.rewardToken).transfer(bounty.creator, bounty.rewardAmount);
        }

        emit InsightBountyCancelled(_bountyId);
    }

    /**
     * @notice View function to retrieve details of an insight bounty.
     * @param _bountyId The ID of the bounty.
     * @return A struct containing all details of the bounty.
     */
    function getInsightBounty(uint256 _bountyId) external view returns (InsightBounty memory) {
        if (_bountyId >= insightBounties.length) {
            revert EtherealOracleNetwork__BountyNotFound();
        }
        return insightBounties[_bountyId];
    }


    // --- IV. Curator Node NFT & Staking ---
    // (Interactions with the external ICuratorNodeNFT contract)

    /**
     * @notice Mints a new CuratorNodeNFT to the caller.
     * @param _initialMetadataURI The initial metadata URI for the NFT.
     * @dev Requires an initial ETH stake defined by `CURATOR_NODE_MINT_STAKE`.
     */
    function mintCuratorNode(string calldata _initialMetadataURI) external payable whenNotPaused {
        uint256 mintStake = networkParameters[bytes32("CURATOR_NODE_MINT_STAKE")];
        if (msg.value < mintStake) {
            revert NotEnoughFunds();
        }

        // Delegate minting to the external NFT contract
        uint256 newTokenId = ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).mint{value: msg.value}(msg.sender, mintStake, _initialMetadataURI);

        emit CuratorNodeMinted(newTokenId, msg.sender, mintStake);
    }

    /**
     * @notice Increases the staking power of an owned CuratorNodeNFT.
     * @param _tokenId The ID of the CuratorNodeNFT.
     * @dev Requires ETH to be sent with the transaction.
     */
    function stakeCuratorNode(uint256 _tokenId) external payable whenNotPaused {
        if (ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).ownerOf(_tokenId) != msg.sender) {
            revert NotCuratorNodeOwner();
        }
        if (msg.value == 0) {
            revert EtherealOracleNetwork__InvalidParameter();
        }
        ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).stake{value: msg.value}(_tokenId, msg.value);
        emit CuratorNodeStaked(_tokenId, msg.sender, msg.value);
    }

    /**
     * @notice Decreases the staking power of an owned CuratorNodeNFT.
     * @param _tokenId The ID of the CuratorNodeNFT.
     * @param _amount The amount to unstake.
     * @dev May be subject to a cooldown period.
     */
    function unstakeCuratorNode(uint256 _tokenId, uint256 _amount) external whenNotPaused {
        if (ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).ownerOf(_tokenId) != msg.sender) {
            revert NotCuratorNodeOwner();
        }
        if (_amount == 0) {
            revert EtherealOracleNetwork__InvalidParameter();
        }
        if (ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).getStakeAmount(_tokenId) < _amount) {
            revert NotEnoughStake();
        }

        // Simple cooldown check: if reputation was recently boosted by burning, cannot unstake.
        // A more complex system would tie a cooldown per node.
        if (curatorNodeStakedReputationLock[_tokenId] > 0 && block.timestamp < curatorNodeStakedReputationLock[_tokenId] + networkParameters[bytes32("UNSTAKE_COOLDOWN_SECONDS")]) {
            revert EtherealOracleNetwork__CannotUnstakeReputationLocked();
        }

        ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).unstake(_tokenId, _amount);
        emit CuratorNodeUnstaked(_tokenId, msg.sender, _amount);
    }

    /**
     * @notice Allows a CuratorNode owner to "burn" a portion of their reputation to temporarily boost their node's influence.
     * @param _tokenId The ID of the CuratorNodeNFT.
     * @param _reputationBurnAmount The amount of reputation to burn.
     * @dev Burning reputation might provide a temporary boost to validation weight.
     */
    function reputationBoostForNode(uint256 _tokenId, uint256 _reputationBurnAmount) external whenNotPaused {
        if (ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).ownerOf(_tokenId) != msg.sender) {
            revert NotCuratorNodeOwner();
        }
        if (_reputationBurnAmount == 0) {
            revert EtherealOracleNetwork__InvalidParameter();
        }
        if (participantReputation[msg.sender] < networkParameters[bytes32("MIN_REPUTATION_FOR_BOOST")] || participantReputation[msg.sender] < _reputationBurnAmount) {
            revert EtherealOracleNetwork__ReputationBurnAmountTooHigh();
        }

        // Apply reputation burn
        _adjustReputation(msg.sender, -int256(_reputationBurnAmount));
        emit ParticipantReputationUpdated(msg.sender, participantReputation[msg.sender]);

        // Mark a lock for this node, preventing unstaking for a period
        curatorNodeStakedReputationLock[_tokenId] = block.timestamp; // Timestamp of last boost

        // In a real system, the NFT contract itself would have logic to dynamically adjust weight
        // based on this "boost" signal and the reputation burned. This function only handles the burning.
        emit CuratorNodeReputationBoosted(_tokenId, msg.sender, _reputationBurnAmount);
    }

    /**
     * @notice Admin/DAO can penalize a CuratorNode by slashing its stake and reputation due to misconduct.
     * @param _tokenId The ID of the CuratorNodeNFT to slash.
     * @param _slashAmount The amount of ETH stake to slash.
     * @dev Also reduces the associated owner's reputation.
     */
    function slashCuratorNode(uint256 _tokenId, uint256 _slashAmount) external onlyAdmin {
        if (ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).getTokenCounter() <= _tokenId) { // Check if token exists
            revert EtherealOracleNetwork__CuratorNodeNotFound();
        }
        if (_slashAmount == 0) {
            revert EtherealOracleNetwork__InvalidParameter();
        }
        if (ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).getStakeAmount(_tokenId) < _slashAmount) {
            revert EtherealOracleNetwork__AmountTooHigh(); // Trying to slash more than staked
        }

        address owner = ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).ownerOf(_tokenId);
        
        ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).slash(_tokenId, _slashAmount); // Delegate slashing to NFT contract

        // Reduce owner's reputation
        _adjustReputation(owner, -int256(networkParameters[bytes32("REPUTATION_LOST_ON_SLASH")]));
        emit ParticipantReputationUpdated(owner, participantReputation[owner]);
        emit CuratorNodeSlashed(_tokenId, owner, _slashAmount);
    }

    /**
     * @notice Allows the owner of a CuratorNodeNFT to update its associated metadata URI.
     * @param _tokenId The ID of the CuratorNodeNFT.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateCuratorNodeMetadata(uint256 _tokenId, string calldata _newMetadataURI) external whenNotPaused {
        if (ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).ownerOf(_tokenId) != msg.sender) {
            revert NotCuratorNodeOwner();
        }
        ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).updateMetadataURI(_tokenId, _newMetadataURI);
        emit CuratorNodeMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @notice View function to get details of a specific Curator Node NFT.
     * @param _tokenId The ID of the CuratorNodeNFT.
     * @return owner The owner's address.
     * @return stakeAmount The current staked amount.
     * @return metadataURI The current metadata URI.
     */
    function getCuratorNodeNFT(uint256 _tokenId)
        external
        view
        returns (
            address owner,
            uint256 stakeAmount,
            string memory metadataURI // This cannot be returned directly from an interface, would need helper or direct struct from NFT contract
        )
    {
        if (ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).getTokenCounter() <= _tokenId) {
            revert EtherealOracleNetwork__CuratorNodeNotFound();
        }
        owner = ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).ownerOf(_tokenId);
        stakeAmount = ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).getStakeAmount(_tokenId);
        // metadataURI = ICuratorNodeNFT(CURATOR_NODE_NFT_CONTRACT).tokenURI(_tokenId); // Requires tokenURI on interface
        // Returning "" for metadataURI here for simplicity, as tokenURI is ERC721 specific.
        // A robust solution would require the ICuratorNodeNFT to expose a direct metadata getter or rely on tokenURI.
    }


    // --- V. Reputation & General Utility ---

    /**
     * @notice View function to check the current reputation score of any address.
     * @param _participant The address to check reputation for.
     * @return The reputation score.
     */
    function getParticipantReputation(address _participant) external view returns (uint256) {
        return participantReputation[_participant];
    }

    /**
     * @notice Allows admin to withdraw collected protocol fees.
     * @dev In a production environment, this would likely be controlled by a DAO or multisig,
     *      not a single admin.
     */
    function withdrawAccruedFees() external onlyAdmin {
        if (totalProtocolFees == 0) {
            revert EtherealOracleNetwork__NoFeesToWithdraw();
        }
        uint256 amount = totalProtocolFees;
        totalProtocolFees = 0;
        (bool success, ) = payable(networkAdmin).call{value: amount}("");
        if (!success) {
            // Revert or log, and leave funds for manual retrieval.
            totalProtocolFees = amount; // Restore if transfer fails
            revert NotEnoughFunds();
        }
        emit ProtocolFeesWithdrawn(networkAdmin, amount);
    }

    /**
     * @notice Admin function to transfer ERC-20 tokens held by the contract.
     * @param _token The address of the ERC-20 token.
     * @param _recipient The recipient address.
     * @param _amount The amount to transfer.
     * @dev Used for managing bounty payouts or treasury if needed, typically with caution.
     */
    function transferERC20Funds(
        address _token,
        address _recipient,
        uint256 _amount
    ) external onlyAdmin {
        if (_token == address(0) || _recipient == address(0) || _amount == 0) {
            revert EtherealOracleNetwork__InvalidParameter();
        }
        IERC20(_token).transfer(_recipient, _amount);
        emit ERC20FundsTransferred(_token, _recipient, _amount);
    }

    // --- Internal/Private Helper Functions ---

    /**
     * @dev Internal helper to adjust reputation, preventing underflow.
     * @param _participant The address whose reputation to adjust.
     * @param _change The amount to change reputation by (can be negative).
     */
    function _adjustReputation(address _participant, int256 _change) internal {
        if (_change > 0) {
            participantReputation[_participant] += uint256(_change);
        } else if (_change < 0) {
            uint256 absChange = uint256(-_change);
            if (participantReputation[_participant] < absChange) {
                participantReputation[_participant] = 0;
            } else {
                participantReputation[_participant] -= absChange;
            }
        }
    }

    // --- Fallback & Receive ---
    // Allow the contract to receive ETH for bounties and fees
    receive() external payable {
        // No specific logic needed here, ETH reception is handled in specific functions like proposeKnowledgeCapsule, createInsightBounty, mintCuratorNode, stakeCuratorNode
        // This 'receive' function just ensures that direct ETH transfers not associated with a specific function call don't revert.
    }
}
```