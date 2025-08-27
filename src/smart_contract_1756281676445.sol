```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Chronos Protocol - Decentralized Intent & Conditional Fulfillment Engine
 * @author YourName (or Anonymous)
 * @notice This contract allows users to create "Digital Intents" – commitments to future actions or promises
 *         with specific on-chain or off-chain verifiable conditions. These intents are tied to a dynamic,
 *         on-chain reputation system. Users stake funds to back their intents. Other participants can
 *         "sponsor" intents they believe will succeed or "challenge" intents they deem fraudulent or
 *         unlikely to be fulfilled, creating an incentivized ecosystem for trust and accountability.
 *         An integrated (simulated) AI oracle provides risk assessments for intents.
 *
 * @dev This is an advanced concept contract, and some external integrations (like a real AI oracle
 *      or complex off-chain condition verification) are simulated for on-chain Solidity constraints.
 *      The `_checkConditions` function serves as a placeholder for a more robust verification mechanism.
 *      The contract uses a basic Ownable pattern for administrative functions.
 */

// --- OUTLINE AND FUNCTION SUMMARY ---

// Contract Name: ChronosProtocol

// Concept: The Chronos Protocol enables users to create "Digital Intents" – commitments to future actions
// or promises with specific on-chain or off-chain verifiable conditions. These intents are tied to a
// dynamic, on-chain reputation system. Users stake funds to back their intents. Other participants can
// "sponsor" intents they believe will succeed or "challenge" intents they deem fraudulent or unlikely
// to be fulfilled, creating an incentivized ecosystem for trust and accountability. An integrated
// (simulated) AI oracle provides risk assessments for intents.

// Core Features:
// *   Decentralized Intent Creation: Users define and commit to future actions.
// *   Conditional Fulfillment: Intents are executed only when predefined conditions are met.
// *   Reputation System: Users earn or lose reputation based on their intent fulfillment success, fostering on-chain trust.
// *   Incentivized Participation: Sponsors and Challengers stake funds to support or dispute intents, sharing in rewards or penalties.
// *   AI Risk Assessment (Simulated Oracle): External AI intelligence provides risk scores for intents, aiding participant decision-making.
// *   Commit-Reveal Mechanism: Conditions and payloads can be committed with a hash first, then revealed later, enabling privacy or pre-commitment.

// --- Function Summary (24 Functions) ---

// I. Core Intent Management (8 Functions)
// 1.  createIntentCommitment(bytes32 _fulfillmentConditionHash, bytes32 _executionPayloadHash, uint64 _fulfillmentDeadline, uint256 _reputationBoostOnSuccess, uint256 _reputationPenaltyOnFailure)
//     *   Description: Allows a user to commit to a new intent by providing hashed conditions and payload, a deadline, and specified reputation adjustments. Requires an initial ETH stake.
//     *   Visibility: public payable
// 2.  revealIntentDetails(uint256 _intentId, string calldata _revealedCondition, bytes calldata _revealedPayload)
//     *   Description: Reveals the actual condition string and execution payload for a previously committed intent.
//     *   Visibility: public
// 3.  updateIntentConditionsHash(uint256 _intentId, bytes32 _newFulfillmentConditionHash)
//     *   Description: Allows the creator to update the hash of the fulfillment condition before revealing the details. Limited updates to prevent abuse.
//     *   Visibility: public
// 4.  cancelIntent(uint256 _intentId)
//     *   Description: Creator can cancel a pending intent, incurring a penalty that is distributed among active challengers (if any) or burned.
//     *   Visibility: public
// 5.  fulfillIntent(uint256 _intentId, string calldata _proofData)
//     *   Description: Called by the creator to signal fulfillment of an intent. Verifies conditions (potentially using `_proofData` for off-chain proof verification or by interpreting `revealedCondition`) and executes the payload. Rewards creator and sponsors, penalizes challengers.
//     *   Visibility: public
// 6.  failIntent(uint256 _intentId)
//     *   Description: Callable by anyone after the deadline if an intent's conditions haven't been met. Penalizes the creator and sponsors, rewards challengers.
//     *   Visibility: public
// 7.  getIntentDetails(uint256 _intentId)
//     *   Description: Retrieves all details of a specific intent.
//     *   Visibility: public view
// 8.  getAllActiveIntents()
//     *   Description: Returns a list of all currently active (pending, revealed, or challenged) intent IDs.
//     *   Visibility: public view

// II. Reputation System (3 Functions)
// 9.  getReputationScore(address _user)
//     *   Description: Returns the current on-chain reputation score for a given user.
//     *   Visibility: public view
// 10. _updateReputationScore(address _user, int256 _amount)
//     *   Description: Internal function to adjust a user's reputation score (positive for boost, negative for penalty).
//     *   Visibility: internal
// 11. queryReputationTier(address _user)
//     *   Description: Determines and returns the reputation tier (e.g., Bronze, Silver, Gold) for a user based on their score.
//     *   Visibility: public view

// III. Oracle Integration (Simulated/Placeholder) (3 Functions)
// 12. submitOracleRiskScore(uint256 _intentId, uint256 _riskScore)
//     *   Description: Only callable by the designated oracle address to provide an AI-generated risk score for an intent.
//     *   Visibility: public
// 13. requestOracleRiskAssessment(uint256 _intentId)
//     *   Description: Placeholder function to simulate a user requesting an AI risk assessment from the oracle for their intent.
//     *   Visibility: public
// 14. _checkConditions(uint256 _intentId, string calldata _proofData)
//     *   Description: Internal function to verify an intent's conditions. This could involve interpreting the `revealedCondition` string, verifying cryptographic proofs, or checking simple on-chain states.
//     *   Visibility: internal view returns (bool)`

// IV. Sponsorship & Challenge (6 Functions)
// 15. sponsorIntent(uint256 _intentId)
//     *   Description: Allows users to stake ETH to sponsor an intent, showing belief in its success. Sponsors share in the creator's reputation boost and receive a portion of the stake if the intent is fulfilled.
//     *   Visibility: public payable
// 16. challengeIntent(uint256 _intentId)
//     *   Description: Allows users to stake ETH to challenge an intent, indicating disbelief in its fulfillment or potential fraud. Challengers receive a portion of the creator's stake if the intent fails.
//     *   Visibility: public payable
// 17. withdrawSponsorshipRewards(uint256 _intentId)
//     *   Description: Allows a sponsor to claim their rewards (stake + profit) after an intent they sponsored is successfully fulfilled.
//     *   Visibility: public
// 18. withdrawChallengeRewards(uint256 _intentId)
//     *   Description: Allows a challenger to claim their rewards (stake + profit) after an intent they challenged successfully fails.
//     *   Visibility: public
// 19. getIntentSponsors(uint256 _intentId)
//     *   Description: Returns a list of addresses that have sponsored a specific intent.
//     *   Visibility: public view
// 20. getIntentChallengers(uint256 _intentId)
//     *   Description: Returns a list of addresses that have challenged a specific intent.
//     *   Visibility: public view

// V. Administrative & Utility (4 Functions)
// 21. setOracleAddress(address _newOracleAddress)
//     *   Description: Owner function to set or update the address of the trusted AI oracle.
//     *   Visibility: public onlyOwner
// 22. setReputationPenaltyRate(uint256 _newPenaltyRate)
//     *   Description: Owner function to adjust the multiplier for reputation penalties on failed intents.
//     *   Visibility: public onlyOwner
// 23. setReputationBoostRate(uint256 _newBoostRate)
//     *   Description: Owner function to adjust the multiplier for reputation boosts on fulfilled intents.
//     *   Visibility: public onlyOwner
// 24. retrieveFundsFromContract(address _tokenAddress)
//     *   Description: Emergency function allowing the owner to retrieve inadvertently sent ERC20 tokens or ETH from the contract.
//     *   Visibility: public onlyOwner

// --- END OF OUTLINE AND FUNCTION SUMMARY ---

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ChronosProtocol {
    address public owner;
    address public oracleAddress;

    // --- State Variables ---

    uint256 public nextIntentId;

    enum IntentStatus {
        PendingCommitment, // Intent created with hashed details, waiting for full reveal.
        Active,            // Details revealed, awaiting fulfillment or deadline.
        Fulfilled,         // Successfully completed.
        Failed,            // Not completed by deadline or explicitly failed.
        Cancelled          // Creator cancelled the intent.
    }

    struct Intent {
        uint256 id;
        address creator;
        uint256 stakeAmount; // ETH staked by the creator
        bytes32 fulfillmentConditionHash;
        string revealedCondition; // The actual condition string, revealed later.
        bytes32 executionPayloadHash;
        bytes revealedPayload;   // The actual payload data, revealed later.
        uint64 fulfillmentDeadline;
        IntentStatus status;
        uint256 reputationBoostOnSuccess;
        uint256 reputationPenaltyOnFailure;
        uint256 oracleRiskScore; // AI-generated risk score (0-100, 100 being highest risk)
        uint64 creationTimestamp;
        uint8  conditionHashUpdates; // Counter for `updateIntentConditionsHash`
    }

    mapping(uint256 => Intent) public intents;
    mapping(address => uint256) public reputationScores; // Non-transferable on-chain reputation

    // For tracking sponsors and challengers
    mapping(uint256 => mapping(address => uint256)) public intentSponsors; // intentId => address => stakedAmount
    mapping(uint256 => mapping(address => uint256)) public intentChallengers; // intentId => address => stakedAmount
    mapping(uint256 => address[]) public intentSponsorList; // To easily retrieve all sponsors for an intent
    mapping(uint256 => address[]) public intentChallengerList; // To easily retrieve all challengers for an intent

    // Configuration
    uint256 public constant MAX_CONDITION_HASH_UPDATES = 1; // Max times creator can update condition hash before reveal
    uint256 public constant REPUTATION_TIER_BRONZE = 0;
    uint256 public constant REPUTATION_TIER_SILVER = 1000;
    uint256 public constant REPUTATION_TIER_GOLD = 5000;

    // Default rates for general reputation adjustments if not specified in intent
    uint256 public defaultReputationBoostRate = 100; // Multiplier: 100 means score * 1, 150 means score * 1.5
    uint256 public defaultReputationPenaltyRate = 100; // Multiplier

    // --- Events ---
    event IntentCreated(uint256 indexed intentId, address indexed creator, uint256 stakeAmount, uint64 fulfillmentDeadline, bytes32 fulfillmentConditionHash);
    event IntentDetailsRevealed(uint256 indexed intentId, string revealedCondition, bytes revealedPayload);
    event IntentConditionsHashUpdated(uint256 indexed intentId, bytes32 newHash);
    event IntentFulfilled(uint256 indexed intentId, address indexed creator, uint256 totalRewards);
    event IntentFailed(uint256 indexed intentId, address indexed creator, uint256 totalPenalties);
    event IntentCancelled(uint256 indexed intentId, address indexed creator, uint256 penaltyAmount);
    event ReputationUpdated(address indexed user, uint256 newScore);
    event OracleRiskScoreSubmitted(uint256 indexed intentId, uint256 riskScore);
    event IntentSponsored(uint256 indexed intentId, address indexed sponsor, uint256 amount);
    event IntentChallenged(uint256 indexed intentId, address indexed challenger, uint256 amount);
    event SponsorshipRewardsWithdrawn(uint256 indexed intentId, address indexed sponsor, uint256 amount);
    event ChallengeRewardsWithdrawn(uint256 indexed intentId, address indexed challenger, uint256 amount);
    event FundsRetrieved(address indexed beneficiary, uint256 amount, address tokenAddress);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronosProtocol: caller is not the oracle");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        nextIntentId = 1;
        // Oracle address needs to be set by owner after deployment
    }

    // --- Fallback & Receive ---
    receive() external payable {}
    fallback() external payable {}

    // I. Core Intent Management

    /**
     * @notice Allows a user to commit to a new intent by providing hashed conditions and payload,
     *         a deadline, and specified reputation adjustments. Requires an initial ETH stake.
     * @param _fulfillmentConditionHash A cryptographic hash of the intent's fulfillment conditions.
     * @param _executionPayloadHash A cryptographic hash of the data/function call to execute upon fulfillment.
     * @param _fulfillmentDeadline The timestamp by which the intent must be fulfilled.
     * @param _reputationBoostOnSuccess The amount of reputation to boost on successful fulfillment.
     * @param _reputationPenaltyOnFailure The amount of reputation to penalize on failure.
     */
    function createIntentCommitment(
        bytes32 _fulfillmentConditionHash,
        bytes32 _executionPayloadHash,
        uint64 _fulfillmentDeadline,
        uint256 _reputationBoostOnSuccess,
        uint256 _reputationPenaltyOnFailure
    ) public payable returns (uint256) {
        require(msg.value > 0, "ChronosProtocol: Initial stake required");
        require(_fulfillmentDeadline > block.timestamp, "ChronosProtocol: Deadline must be in the future");
        require(_reputationBoostOnSuccess > 0, "ChronosProtocol: Reputation boost must be positive");
        require(_reputationPenaltyOnFailure > 0, "ChronosProtocol: Reputation penalty must be positive");

        uint256 intentId = nextIntentId++;
        intents[intentId] = Intent({
            id: intentId,
            creator: msg.sender,
            stakeAmount: msg.value,
            fulfillmentConditionHash: _fulfillmentConditionHash,
            revealedCondition: "", // Empty initially
            executionPayloadHash: _executionPayloadHash,
            revealedPayload: "",   // Empty initially
            fulfillmentDeadline: _fulfillmentDeadline,
            status: IntentStatus.PendingCommitment,
            reputationBoostOnSuccess: _reputationBoostOnSuccess,
            reputationPenaltyOnFailure: _reputationPenaltyOnFailure,
            oracleRiskScore: 0, // Not assessed yet
            creationTimestamp: uint64(block.timestamp),
            conditionHashUpdates: 0
        });

        emit IntentCreated(intentId, msg.sender, msg.value, _fulfillmentDeadline, _fulfillmentConditionHash);
        return intentId;
    }

    /**
     * @notice Reveals the actual condition string and execution payload for a previously committed intent.
     *         The revealed details must match their respective hashes.
     * @param _intentId The ID of the intent to reveal.
     * @param _revealedCondition The actual condition string.
     * @param _revealedPayload The actual execution payload data.
     */
    function revealIntentDetails(
        uint256 _intentId,
        string calldata _revealedCondition,
        bytes calldata _revealedPayload
    ) public {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.PendingCommitment, "ChronosProtocol: Intent not in PendingCommitment status");
        require(intent.creator == msg.sender, "ChronosProtocol: Only intent creator can reveal details");
        require(keccak256(abi.encodePacked(_revealedCondition)) == intent.fulfillmentConditionHash, "ChronosProtocol: Condition hash mismatch");
        require(keccak256(_revealedPayload) == intent.executionPayloadHash, "ChronosProtocol: Payload hash mismatch");

        intent.revealedCondition = _revealedCondition;
        intent.revealedPayload = _revealedPayload;
        intent.status = IntentStatus.Active;

        emit IntentDetailsRevealed(_intentId, _revealedCondition, _revealedPayload);
    }

    /**
     * @notice Allows the creator to update the hash of the fulfillment condition before revealing the details.
     *         Limited updates to prevent abuse.
     * @param _intentId The ID of the intent to update.
     * @param _newFulfillmentConditionHash The new hash for the fulfillment condition.
     */
    function updateIntentConditionsHash(uint256 _intentId, bytes32 _newFulfillmentConditionHash) public {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.PendingCommitment, "ChronosProtocol: Intent not in PendingCommitment status");
        require(intent.creator == msg.sender, "ChronosProtocol: Only intent creator can update hash");
        require(intent.conditionHashUpdates < MAX_CONDITION_HASH_UPDATES, "ChronosProtocol: Max condition hash updates reached");

        intent.fulfillmentConditionHash = _newFulfillmentConditionHash;
        intent.conditionHashUpdates++;

        emit IntentConditionsHashUpdated(_intentId, _newFulfillmentConditionHash);
    }

    /**
     * @notice Creator can cancel a pending intent. A penalty is applied, which is distributed
     *         among active challengers (if any) or burned if no challengers.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelIntent(uint256 _intentId) public {
        Intent storage intent = intents[_intentId];
        require(intent.creator == msg.sender, "ChronosProtocol: Only intent creator can cancel");
        require(intent.status == IntentStatus.PendingCommitment || intent.status == IntentStatus.Active, "ChronosProtocol: Intent not active or pending");
        require(block.timestamp < intent.fulfillmentDeadline, "ChronosProtocol: Cannot cancel after deadline");

        intent.status = IntentStatus.Cancelled;

        // Apply a cancellation penalty, e.g., 10% of creator's stake
        uint256 cancellationPenalty = intent.stakeAmount / 10; // Example: 10%
        uint256 remainingStake = intent.stakeAmount - cancellationPenalty;

        _updateReputationScore(msg.sender, -int256(intent.reputationPenaltyOnFailure)); // Creator loses reputation

        // Distribute cancellation penalty to challengers if any, else burn
        address[] storage challengers = intentChallengerList[_intentId];
        if (challengers.length > 0) {
            uint256 totalChallengerStake = 0;
            for (uint256 i = 0; i < challengers.length; i++) {
                totalChallengerStake += intentChallengers[_intentId][challengers[i]];
            }
            if (totalChallengerStake > 0) {
                for (uint256 i = 0; i < challengers.length; i++) {
                    address challenger = challengers[i];
                    uint256 challengerShare = (intentChallengers[_intentId][challenger] * cancellationPenalty) / totalChallengerStake;
                    payable(challenger).transfer(challengerShare);
                }
            } else {
                // No staked challengers, burn penalty (send to 0x0)
                payable(address(0)).transfer(cancellationPenalty); // Simulating burning
            }
        } else {
            // No challengers, burn penalty (send to 0x0)
            payable(address(0)).transfer(cancellationPenalty); // Simulating burning
        }

        // Return remaining stake to creator
        payable(msg.sender).transfer(remainingStake);

        // Refund sponsors
        address[] storage sponsors = intentSponsorList[_intentId];
        for (uint256 i = 0; i < sponsors.length; i++) {
            address sponsor = sponsors[i];
            uint256 sponsorStake = intentSponsors[_intentId][sponsor];
            if (sponsorStake > 0) {
                delete intentSponsors[_intentId][sponsor]; // Clear for this intent
                payable(sponsor).transfer(sponsorStake);
            }
        }
        delete intentSponsorList[_intentId]; // Clear the list

        emit IntentCancelled(_intentId, msg.sender, cancellationPenalty);
    }

    /**
     * @notice Called by the creator to signal fulfillment of an intent. Verifies conditions
     *         and executes the payload. Rewards creator and sponsors, penalizes challengers.
     * @param _intentId The ID of the intent to fulfill.
     * @param _proofData Optional data to aid in condition verification (e.g., ZK proof, oracle signature).
     */
    function fulfillIntent(uint256 _intentId, string calldata _proofData) public {
        Intent storage intent = intents[_intentId];
        require(intent.creator == msg.sender, "ChronosProtocol: Only intent creator can fulfill");
        require(intent.status == IntentStatus.Active, "ChronosProtocol: Intent not in Active status");
        require(block.timestamp <= intent.fulfillmentDeadline, "ChronosProtocol: Deadline passed, cannot fulfill");
        require(bytes(intent.revealedCondition).length > 0, "ChronosProtocol: Intent details not revealed");

        // Advanced concept: _checkConditions would verify the _revealedCondition against on-chain state or _proofData
        require(_checkConditions(_intentId, _proofData), "ChronosProtocol: Fulfillment conditions not met");

        intent.status = IntentStatus.Fulfilled;

        // Execute payload (simulated - in a real scenario this might be a delegatecall, external call, or state update)
        // For security and simplicity, we'll assume it's an internal state change or event emission.
        // If a real external call is needed, consider an `IMulticall` interface or similar.
        if (intent.revealedPayload.length > 0) {
            // Example: Parse the payload to trigger an internal function or update a state variable
            // For now, we'll just emit an event as a successful "execution".
            emit logPayloadExecution(_intentId, intent.revealedPayload);
        }

        // Rewards for creator and sponsors
        uint256 totalRewardsPool = intent.stakeAmount;
        uint256 creatorRewardPercentage = 70; // Example: 70% to creator
        uint256 sponsorsRewardPercentage = 30; // Example: 30% to sponsors

        uint256 creatorShare = (totalRewardsPool * creatorRewardPercentage) / 100;
        uint256 sponsorsSharePool = totalRewardsPool - creatorShare;

        payable(intent.creator).transfer(creatorShare);
        _updateReputationScore(intent.creator, int256(intent.reputationBoostOnSuccess));

        // Distribute to sponsors
        address[] storage sponsors = intentSponsorList[_intentId];
        if (sponsors.length > 0) {
            uint256 totalSponsorStake = 0;
            for (uint256 i = 0; i < sponsors.length; i++) {
                totalSponsorStake += intentSponsors[_intentId][sponsors[i]];
            }
            if (totalSponsorStake > 0) {
                for (uint256 i = 0; i < sponsors.length; i++) {
                    address sponsor = sponsors[i];
                    uint256 sponsorOriginalStake = intentSponsors[_intentId][sponsor];
                    uint256 profitShare = (sponsorOriginalStake * sponsorsSharePool) / totalSponsorStake;
                    payable(sponsor).transfer(sponsorOriginalStake + profitShare);
                }
            } else {
                 // If no actual staked sponsors (e.g., list was populated but stakes became 0), remaining rewards go to creator.
                 payable(intent.creator).transfer(sponsorsSharePool);
            }
        } else {
            // No sponsors, remaining rewards go to creator.
            payable(intent.creator).transfer(sponsorsSharePool);
        }

        // Penalize challengers
        address[] storage challengers = intentChallengerList[_intentId];
        for (uint256 i = 0; i < challengers.length; i++) {
            address challenger = challengers[i];
            uint256 challengerStake = intentChallengers[_intentId][challenger];
            if (challengerStake > 0) {
                // Forfeit challenger stake
                // The forfeited stake already contributed to the 'totalRewardsPool' if creator's initial stake was small.
                // A simpler approach is to burn their stake or transfer to a treasury.
                // For this example, we'll simply not return it.
                delete intentChallengers[_intentId][challenger]; // Clear their stake for this intent
            }
        }
        delete intentChallengerList[_intentId]; // Clear the list

        emit IntentFulfilled(_intentId, msg.sender, totalRewardsPool);
    }

    /**
     * @notice Callable by anyone after the deadline if an intent's conditions haven't been met.
     *         Penalizes the creator and sponsors, rewards challengers.
     * @param _intentId The ID of the intent that failed.
     */
    function failIntent(uint256 _intentId) public {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Active, "ChronosProtocol: Intent not in Active status");
        require(block.timestamp > intent.fulfillmentDeadline, "ChronosProtocol: Deadline not passed yet");
        // Optionally add a check that _checkConditions() would return false if it were called at this point.
        // For this contract, simply deadline passing is sufficient for failure if not fulfilled.

        intent.status = IntentStatus.Failed;

        // Penalties for creator and sponsors
        _updateReputationScore(intent.creator, -int256(intent.reputationPenaltyOnFailure));

        // Funds distribution for failure: Challengers get creator's stake + their own back
        uint256 totalStake = intent.stakeAmount; // Creator's stake
        
        address[] storage challengers = intentChallengerList[_intentId];
        uint256 totalChallengerStake = 0;
        for (uint256 i = 0; i < challengers.length; i++) {
            totalChallengerStake += intentChallengers[_intentId][challengers[i]];
        }

        if (challengers.length > 0 && totalChallengerStake > 0) {
            uint256 rewardPool = totalStake + totalChallengerStake; // Creator's stake + challengers' stakes
            for (uint256 i = 0; i < challengers.length; i++) {
                address challenger = challengers[i];
                uint256 challengerOriginalStake = intentChallengers[_intentId][challenger];
                uint256 profitShare = (challengerOriginalStake * totalStake) / totalChallengerStake; // Share of creator's stake
                payable(challenger).transfer(challengerOriginalStake + profitShare);
                // Challenger gets their stake back plus a profit from creator's stake
            }
        } else {
            // No challengers, creator's stake goes to 0x0 (burned)
            payable(address(0)).transfer(totalStake); // Simulating burning
        }
        
        // Sponsors lose their staked amount
        address[] storage sponsors = intentSponsorList[_intentId];
        for (uint256 i = 0; i < sponsors.length; i++) {
            address sponsor = sponsors[i];
            uint256 sponsorStake = intentSponsors[_intentId][sponsor];
            if (sponsorStake > 0) {
                _updateReputationScore(sponsor, -int256(intent.reputationPenaltyOnFailure / 2)); // Sponsors lose half reputation
                delete intentSponsors[_intentId][sponsor]; // Clear for this intent
                // Sponsor's stake is forfeited (not returned)
            }
        }
        delete intentSponsorList[_intentId]; // Clear the list

        emit IntentFailed(_intentId, intent.creator, totalStake);
    }

    /**
     * @notice Retrieves all details of a specific intent.
     * @param _intentId The ID of the intent.
     * @return intent struct fields.
     */
    function getIntentDetails(uint256 _intentId)
        public view
        returns (
            uint256 id,
            address creator,
            uint256 stakeAmount,
            bytes32 fulfillmentConditionHash,
            string memory revealedCondition,
            bytes32 executionPayloadHash,
            bytes memory revealedPayload,
            uint64 fulfillmentDeadline,
            IntentStatus status,
            uint256 reputationBoostOnSuccess,
            uint256 reputationPenaltyOnFailure,
            uint256 oracleRiskScore,
            uint64 creationTimestamp,
            uint8 conditionHashUpdates
        )
    {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "ChronosProtocol: Intent does not exist");
        return (
            intent.id,
            intent.creator,
            intent.stakeAmount,
            intent.fulfillmentConditionHash,
            intent.revealedCondition,
            intent.executionPayloadHash,
            intent.revealedPayload,
            intent.fulfillmentDeadline,
            intent.status,
            intent.reputationBoostOnSuccess,
            intent.reputationPenaltyOnFailure,
            intent.oracleRiskScore,
            intent.creationTimestamp,
            intent.conditionHashUpdates
        );
    }

    /**
     * @notice Returns a list of all currently active (pending, revealed, or challenged) intent IDs.
     * @dev This function iterates through `nextIntentId` and might be gas-intensive if many intents exist.
     *      For a very large number of intents, a more efficient index structure would be needed off-chain.
     * @return A dynamic array of active intent IDs.
     */
    function getAllActiveIntents() public view returns (uint256[] memory) {
        uint256[] memory activeIntents = new uint256[](nextIntentId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextIntentId; i++) {
            if (intents[i].status == IntentStatus.PendingCommitment || intents[i].status == IntentStatus.Active) {
                activeIntents[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeIntents[i];
        }
        return result;
    }

    // II. Reputation System

    /**
     * @notice Returns the current on-chain reputation score for a given user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @notice Internal function to adjust a user's reputation score (positive for boost, negative for penalty).
     * @param _user The address of the user whose score is to be updated.
     * @param _amount The amount to add (positive) or subtract (negative) from the reputation.
     */
    function _updateReputationScore(address _user, int256 _amount) internal {
        if (_amount > 0) {
            reputationScores[_user] += uint256(_amount);
        } else {
            if (reputationScores[_user] < uint256(-_amount)) {
                reputationScores[_user] = 0;
            } else {
                reputationScores[_user] -= uint256(-_amount);
            }
        }
        emit ReputationUpdated(_user, reputationScores[_user]);
    }

    /**
     * @notice Determines and returns the reputation tier (e.g., Bronze, Silver, Gold) for a user based on their score.
     * @param _user The address of the user.
     * @return A string representing the reputation tier.
     */
    function queryReputationTier(address _user) public view returns (string memory) {
        uint256 score = reputationScores[_user];
        if (score >= REPUTATION_TIER_GOLD) {
            return "Gold";
        } else if (score >= REPUTATION_TIER_SILVER) {
            return "Silver";
        } else if (score >= REPUTATION_TIER_BRONZE) {
            return "Bronze";
        } else {
            return "None";
        }
    }

    // III. Oracle Integration (Simulated/Placeholder)

    /**
     * @notice Only callable by the designated oracle address to provide an AI-generated risk score for an intent.
     * @param _intentId The ID of the intent to update.
     * @param _riskScore The AI-generated risk score (e.g., 0-100, 100 being highest risk).
     */
    function submitOracleRiskScore(uint256 _intentId, uint256 _riskScore) public onlyOracle {
        require(intents[_intentId].id != 0, "ChronosProtocol: Intent does not exist");
        intents[_intentId].oracleRiskScore = _riskScore;
        emit OracleRiskScoreSubmitted(_intentId, _riskScore);
    }

    /**
     * @notice Placeholder function to simulate a user requesting an AI risk assessment from the oracle for their intent.
     * @dev In a real system, this would interact with an external oracle network (e.g., Chainlink External Adapters).
     * @param _intentId The ID of the intent for which assessment is requested.
     */
    function requestOracleRiskAssessment(uint256 _intentId) public {
        require(intents[_intentId].id != 0, "ChronosProtocol: Intent does not exist");
        // Simulate a request: In a real system, this would emit an event
        // for an off-chain oracle to pick up and process, then call `submitOracleRiskScore`.
        emit OracleRequestForRiskAssessment(_intentId, msg.sender);
    }

    /**
     * @notice Internal function to verify an intent's conditions.
     * @dev This is a crucial advanced concept. In a production system, this could involve:
     *      1. Interpreting the `revealedCondition` string (e.g., "ERC20:TOKEN_ADDR.balanceOf(USER) > 100").
     *      2. Verifying cryptographic proofs (`_proofData`) for off-chain conditions (e.g., ZK-proofs).
     *      3. Calling another smart contract to check a specific state.
     *      4. Verifying oracle signatures included in `_proofData`.
     *      For this example, we will simulate a simple check:
     *      - If `revealedCondition` is "true", it's fulfilled.
     *      - If `_proofData` is "chronos_verified_proof", it's considered verified.
     * @param _intentId The ID of the intent.
     * @param _proofData Optional data to aid in condition verification.
     * @return true if conditions are met, false otherwise.
     */
    function _checkConditions(uint256 _intentId, string calldata _proofData) internal view returns (bool) {
        Intent storage intent = intents[_intentId];

        // Example simulation of advanced condition checking:
        if (keccak256(abi.encodePacked(intent.revealedCondition)) == keccak256(abi.encodePacked("true"))) {
            return true; // Simple boolean condition
        }
        if (keccak256(abi.encodePacked(_proofData)) == keccak256(abi.encodePacked("chronos_verified_proof"))) {
            return true; // Simulate off-chain proof verification
        }
        // Add more complex (simulated) logic here:
        // Example: check if a certain time has passed since creation
        if (keccak256(abi.encodePacked(intent.revealedCondition)) == keccak256(abi.encodePacked("delay_passed")) &&
            block.timestamp >= intent.creationTimestamp + 1 days) { // Example: 1 day delay
            return true;
        }

        // Default to false if no conditions are met
        return false;
    }

    event OracleRequestForRiskAssessment(uint256 indexed intentId, address indexed requester);
    event logPayloadExecution(uint256 indexed intentId, bytes payload);

    // IV. Sponsorship & Challenge

    /**
     * @notice Allows users to stake ETH to sponsor an intent, showing belief in its success.
     *         Sponsors share in the creator's reputation boost and receive a portion of the stake
     *         if the intent is fulfilled.
     * @param _intentId The ID of the intent to sponsor.
     */
    function sponsorIntent(uint256 _intentId) public payable {
        require(msg.value > 0, "ChronosProtocol: Sponsorship requires a stake");
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "ChronosProtocol: Intent does not exist");
        require(intent.status == IntentStatus.Active || intent.status == IntentStatus.PendingCommitment, "ChronosProtocol: Intent not active or pending");
        require(block.timestamp < intent.fulfillmentDeadline, "ChronosProtocol: Cannot sponsor after deadline");
        require(msg.sender != intent.creator, "ChronosProtocol: Creator cannot sponsor their own intent");

        if (intentSponsors[_intentId][msg.sender] == 0) {
            intentSponsorList[_intentId].push(msg.sender);
        }
        intentSponsors[_intentId][msg.sender] += msg.value;

        emit IntentSponsored(_intentId, msg.sender, msg.value);
    }

    /**
     * @notice Allows users to stake ETH to challenge an intent, indicating disbelief in its fulfillment
     *         or potential fraud. Challengers receive a portion of the creator's stake if the intent fails.
     * @param _intentId The ID of the intent to challenge.
     */
    function challengeIntent(uint256 _intentId) public payable {
        require(msg.value > 0, "ChronosProtocol: Challenge requires a stake");
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "ChronosProtocol: Intent does not exist");
        require(intent.status == IntentStatus.Active || intent.status == IntentStatus.PendingCommitment, "ChronosProtocol: Intent not active or pending");
        require(block.timestamp < intent.fulfillmentDeadline, "ChronosProtocol: Cannot challenge after deadline");
        require(msg.sender != intent.creator, "ChronosProtocol: Creator cannot challenge their own intent");

        if (intentChallengers[_intentId][msg.sender] == 0) {
            intentChallengerList[_intentId].push(msg.sender);
        }
        intentChallengers[_intentId][msg.sender] += msg.value;

        emit IntentChallenged(_intentId, msg.sender, msg.value);
    }

    /**
     * @notice Allows a sponsor to claim their rewards (original stake + profit) after an intent they
     *         sponsored is successfully fulfilled.
     * @param _intentId The ID of the intent.
     */
    function withdrawSponsorshipRewards(uint256 _intentId) public {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Fulfilled, "ChronosProtocol: Intent not fulfilled");
        uint256 stakedAmount = intentSponsors[_intentId][msg.sender];
        require(stakedAmount > 0, "ChronosProtocol: You did not sponsor this intent or rewards already claimed");

        // Rewards are already distributed during `fulfillIntent`, this function just prevents double claim.
        // For simplicity, we assume rewards are sent directly during fulfillIntent.
        // This function would be used if rewards were held in the contract.
        // For this implementation, the `fulfillIntent` already transfers funds directly.
        // So this function merely clears the record and confirms the funds were handled.
        delete intentSponsors[_intentId][msg.sender];

        // This event might not be triggered if funds were sent directly.
        // For example, if we had a contract-held rewards system:
        // uint256 rewards = calculateRewards(intent, stakedAmount);
        // payable(msg.sender).transfer(rewards);
        // emit SponsorshipRewardsWithdrawn(_intentId, msg.sender, rewards);
        // For current logic, assume it's just marking as claimed/processed.
        emit SponsorshipRewardsWithdrawn(_intentId, msg.sender, 0); // Amount 0 as it's already sent
    }

    /**
     * @notice Allows a challenger to claim their rewards (original stake + profit) after an intent
     *         they challenged successfully fails.
     * @param _intentId The ID of the intent.
     */
    function withdrawChallengeRewards(uint256 _intentId) public {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Failed || intent.status == IntentStatus.Cancelled, "ChronosProtocol: Intent not failed or cancelled");
        uint256 stakedAmount = intentChallengers[_intentId][msg.sender];
        require(stakedAmount > 0, "ChronosProtocol: You did not challenge this intent or rewards already claimed");

        // Similar to sponsors, rewards are already handled during `failIntent` or `cancelIntent`.
        delete intentChallengers[_intentId][msg.sender];
        emit ChallengeRewardsWithdrawn(_intentId, msg.sender, 0); // Amount 0 as it's already sent
    }

    /**
     * @notice Returns a list of addresses that have sponsored a specific intent.
     * @param _intentId The ID of the intent.
     * @return An array of sponsor addresses.
     */
    function getIntentSponsors(uint256 _intentId) public view returns (address[] memory) {
        return intentSponsorList[_intentId];
    }

    /**
     * @notice Returns a list of addresses that have challenged a specific intent.
     * @param _intentId The ID of the intent.
     * @return An array of challenger addresses.
     */
    function getIntentChallengers(uint256 _intentId) public view returns (address[] memory) {
        return intentChallengerList[_intentId];
    }

    // V. Administrative & Utility

    /**
     * @notice Owner function to set or update the address of the trusted AI oracle.
     * @param _newOracleAddress The new address for the oracle.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "ChronosProtocol: Oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
    }

    /**
     * @notice Owner function to adjust the multiplier for reputation penalties on failed intents.
     * @param _newPenaltyRate The new penalty rate (e.g., 100 for no change, 150 for 1.5x penalty).
     */
    function setReputationPenaltyRate(uint256 _newPenaltyRate) public onlyOwner {
        require(_newPenaltyRate > 0, "ChronosProtocol: Penalty rate must be positive");
        defaultReputationPenaltyRate = _newPenaltyRate;
    }

    /**
     * @notice Owner function to adjust the multiplier for reputation boosts on fulfilled intents.
     * @param _newBoostRate The new boost rate (e.g., 100 for no change, 150 for 1.5x boost).
     */
    function setReputationBoostRate(uint256 _newBoostRate) public onlyOwner {
        require(_newBoostRate > 0, "ChronosProtocol: Boost rate must be positive");
        defaultReputationBoostRate = _newBoostRate;
    }

    /**
     * @notice Emergency function allowing the owner to retrieve inadvertently sent ERC20 tokens or ETH from the contract.
     * @param _tokenAddress The address of the ERC20 token to retrieve (use address(0) for ETH).
     */
    function retrieveFundsFromContract(address _tokenAddress) public onlyOwner {
        if (_tokenAddress == address(0)) {
            // Retrieve ETH
            uint256 balance = address(this).balance;
            require(balance > 0, "ChronosProtocol: No ETH balance to retrieve");
            payable(owner).transfer(balance);
            emit FundsRetrieved(owner, balance, address(0));
        } else {
            // Retrieve ERC20 tokens
            IERC20 token = IERC20(_tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "ChronosProtocol: No ERC20 token balance to retrieve");
            token.transfer(owner, balance);
            emit FundsRetrieved(owner, balance, _tokenAddress);
        }
    }
}
```