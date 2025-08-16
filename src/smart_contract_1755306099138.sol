Here's a Solidity smart contract named `AetherPlex` that implements an advanced, creative, and trending concept: a **Decentralized Adaptive Reputation & Skill Network**. This contract focuses on building verifiable on-chain reputation for users based on their demonstrated skills, community attestations, and participation in challenges, with a unique dynamic reputation decay mechanism. It specifically avoids duplicating common open-source patterns by implementing custom reputation logic rather than relying on standard ERC tokens for reputation itself.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string conversion in tokenURI

/**
 * @title AetherPlex
 * @dev A Decentralized Adaptive Reputation & Skill Network.
 *      AetherPlex allows users to define, attest to, and demonstrate skills, earning
 *      reputation that dynamically decays over time, encouraging continuous engagement.
 *      Skills are represented as unique ERC721 NFTs.
 */

// Outline & Function Summary:
//
// The AetherPlex contract establishes a framework for on-chain skill validation and reputation management.
// It uses ERC721 NFTs to represent abstract "Skill Nodes" (e.g., "Solidity Development," "AI Ethics"),
// and a custom reputation system where users gain points for successful attestations and challenge completions.
// A unique feature is the dynamic decay of reputation, requiring continuous engagement or demonstration of skills.
//
// I. Contract & Global Management:
//    - `constructor()`: Initializes the contract with an owner, initial fees, and reputation decay rate.
//    - `setProtocolFeeRecipient(address _newRecipient)`: Sets the address designated to receive protocol fees.
//    - `setAttestationFee(uint256 _newFee)`: Adjusts the fee required for one user to attest to another's skill.
//    - `setChallengeCreationFee(uint256 _newFee)`: Sets the fee required to propose a new skill-demonstration challenge.
//    - `setReputationDecayRate(uint256 _ratePerSecond)`: Defines the rate at which reputation points decay per second.
//    - `pauseContract()`: Allows the owner to pause certain critical contract operations (e.g., attestations, challenges).
//    - `unpauseContract()`: Unpauses the contract, restoring functionality.
//    - `withdrawProtocolFees(address _tokenAddress)`: Enables the owner to withdraw accumulated fees (currently only ETH).
//
// II. Skill Node (ERC721 NFT) Management:
//    - `createSkillNode(string calldata _name, string calldata _description, uint256 _initialReputationCap)`:
//      Mints a new ERC721 token, which serves as a unique identifier and category for a specific skill (e.g., "Web3 Security").
//      The skill node itself is owned by the contract, representing a canonical skill definition.
//    - `updateSkillNodeMetadata(uint256 _skillNodeId, string calldata _newDescription)`:
//      Modifies the descriptive metadata associated with an existing skill node NFT.
//    - `getSkillNodeDetails(uint256 _skillNodeId)`: Retrieves the name, description, and maximum reputation cap for a given skill node.
//    - `getAllSkillNodeIds()`: Provides a list of all existing skill node NFTs.
//
// III. Reputation & Attestation System:
//    - `attestSkill(address _user, uint256 _skillNodeId, uint256 _attestationStrength)`:
//      Allows `msg.sender` to vouch for another user's proficiency in a specific skill. Includes a fee and a `strength` parameter (1-100)
//      to indicate the level of confidence, which directly impacts the reputation gain.
//    - `revokeAttestation(address _user, uint256 _skillNodeId)`:
//      Enables an attestor to rescind a previously made attestation, leading to a corresponding reputation loss for the attested user.
//    - `getUserSkillReputation(address _user, uint256 _skillNodeId)`:
//      Calculates and returns a user's current effective reputation score for a specific skill, factoring in
//      the time-based decay. This function automatically updates the on-chain stored reputation before returning.
//    - `getAttestationsReceived(address _user, uint256 _skillNodeId)`:
//      Retrieves a detailed list of all attestations received by a user for a particular skill, including attestor addresses, strengths, and timestamps.
//
// IV. Challenge & Proof System (Gamified Skill Demonstration):
//    - `proposeSkillChallenge(uint256 _skillNodeId, string calldata _challengeDetailsURI, uint256 _reputationReward, uint256 _requiredAttestationsForCompletion)`:
//      Initiates a new challenge for a specific skill. Challengers pay a fee, define a reputation reward for completion,
//      and set the number of valid attestations required to verify a submitted proof.
//    - `submitChallengeProof(uint256 _challengeId, string calldata _proofURI)`:
//      A user submits a URI (e.g., IPFS link) pointing to off-chain evidence demonstrating their completion of a challenge.
//    - `attestChallengeProof(uint256 _challengeId, address _participant, bool _isProofValid)`:
//      Allows community members (or designated validators) to review a submitted proof and attest to its validity.
//      Once a proof gathers the `requiredAttestationsForCompletion`, the challenge is marked as `Completed`.
//    - `claimChallengeReward(uint256 _challengeId)`:
//      Allows the participant to claim their reputation reward once their proof for a challenge has been successfully validated
//      by the required number of attestations.
//
// V. Dynamic Reputation Mechanism & Utilities:
//    - `updateMyReputation(uint256 _skillNodeId)`:
//      A convenience function for users to explicitly trigger the on-chain recalculation and update of their reputation
//      for a specific skill, applying any accumulated decay or growth.
//    - `calculateEffectiveReputation(address _user, uint256 _skillNodeId)`:
//      An internal helper function that computes and updates a user's reputation by applying the set decay rate
//      based on the time elapsed since the last update.
//    - `getProposedChallenges()`: Returns a list of IDs for all challenges currently in `Proposed`, `Active`, or `ProofSubmitted` states.
//    - `getChallengeStatus(uint256 _challengeId)`:
//      Provides a comprehensive overview of a challenge's current state, including its status, valid attestations count,
//      participant, proof URI, and associated skill/reward details.

contract AetherPlex is Ownable, Pausable, ERC721 {
    using Strings for uint256;

    // --- Events ---
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event AttestationFeeUpdated(uint256 newFee);
    event ChallengeCreationFeeUpdated(uint256 newFee);
    event ReputationDecayRateUpdated(uint256 newRatePerSecond);
    event SkillNodeCreated(uint256 indexed skillNodeId, string name, string description, uint256 reputationCap);
    event SkillNodeMetadataUpdated(uint256 indexed skillNodeId, string newDescription);
    event SkillAttested(address indexed attestor, address indexed user, uint256 indexed skillNodeId, uint256 strength);
    event AttestationRevoked(address indexed attestor, address indexed user, uint256 indexed skillNodeId);
    event SkillReputationUpdated(address indexed user, uint256 indexed skillNodeId, uint256 newReputation, uint256 timestamp);
    event ChallengeProposed(uint256 indexed challengeId, uint256 indexed skillNodeId, uint256 reputationReward);
    event ChallengeProofSubmitted(uint256 indexed challengeId, address indexed participant, string proofURI);
    event ChallengeProofAttested(uint256 indexed challengeId, address indexed participant, address indexed attester, bool isValid);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed participant, uint256 reputationEarned);
    event ProtocolFeesWithdrawn(address indexed tokenAddress, uint256 amount);

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for SkillNode NFTs
    uint256 private _nextChallengeId; // Counter for Challenges

    // Contract Fees
    address public protocolFeeRecipient;
    uint256 public attestationFee;
    uint256 public challengeCreationFee;
    mapping(address => mapping(address => uint256)) public protocolFeesCollected; // tokenAddress => recipient => amount

    // Reputation Decay
    uint256 public reputationDecayRatePerSecond; // Points per second reputation decays

    // Skill Node Details (ERC721 Metadata stored on-chain)
    struct SkillNode {
        string name;
        string description;
        uint256 reputationCap; // Max reputation a user can achieve for this skill
    }
    mapping(uint256 => SkillNode) public skillNodes;
    uint256[] public allSkillNodeIds; // To retrieve all skill nodes

    // User Skill Reputation
    struct UserSkillReputation {
        uint256 score;
        uint256 lastUpdated; // Timestamp of last score update
    }
    mapping(address => mapping(uint256 => UserSkillReputation)) public userSkillReputations; // user => skillNodeId => reputation

    // Attestations Made (by an attestor to a user for a skill)
    mapping(address => mapping(address => mapping(uint256 => uint256))) public attestationsMade; // attestor => user => skillNodeId => strength (0 if none)

    // Attestations Received (by a user for a skill)
    struct ReceivedAttestation {
        address attestor;
        uint256 strength;
        uint256 timestamp;
    }
    mapping(address => mapping(uint256 => ReceivedAttestation[])) public attestationsReceived; // user => skillNodeId => array of received attestations

    // Challenges
    enum ChallengeStatus { Proposed, ProofSubmitted, Completed, Cancelled }
    struct Challenge {
        uint256 skillNodeId;
        address proposer;
        string detailsURI;
        uint256 reputationReward;
        uint256 requiredAttestationsForCompletion;
        ChallengeStatus status;
        address participant; // Who submitted the proof
        string proofURI;
        uint256 proofSubmissionTime;
        mapping(address => bool) attesterVotedValid;   // attester => true if voted valid
        mapping(address => bool) attesterVotedInvalid; // attester => true if voted invalid
        uint256 validAttestationsCount;
        uint256 invalidAttestationsCount;
        bool rewardClaimed;
    }
    mapping(uint256 => Challenge) public challenges;
    uint256[] public proposedChallenges; // List of challenge IDs that are in Proposed/ProofSubmitted state

    // --- Constructor ---
    constructor(
        address _protocolFeeRecipient,
        uint256 _initialAttestationFee,
        uint256 _initialChallengeCreationFee,
        uint256 _initialReputationDecayRatePerSecond
    ) Ownable(msg.sender) ERC721("AetherPlexSkillNode", "APSN") {
        require(_protocolFeeRecipient != address(0), "Invalid fee recipient");
        protocolFeeRecipient = _protocolFeeRecipient;
        attestationFee = _initialAttestationFee;
        challengeCreationFee = _initialChallengeCreationFee;
        reputationDecayRatePerSecond = _initialReputationDecayRatePerSecond;
        _nextTokenId = 0;
        _nextChallengeId = 0;

        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
        emit AttestationFeeUpdated(_initialAttestationFee);
        emit ChallengeCreationFeeUpdated(_initialChallengeCreationFee);
        emit ReputationDecayRateUpdated(_initialReputationDecayRatePerSecond);
    }

    // --- Modifiers ---
    modifier onlyProtocolFeeRecipient() {
        require(msg.sender == protocolFeeRecipient, "Not protocol fee recipient");
        _;
    }

    // --- I. Contract & Global Management (8 functions) ---

    /**
     * @dev Sets the address to receive protocol fees. Only callable by the owner.
     * @param _newRecipient The new address for fee collection.
     */
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid address");
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }

    /**
     * @dev Sets the fee required to attest to a skill. Only callable by the owner.
     * @param _newFee The new attestation fee in wei.
     */
    function setAttestationFee(uint256 _newFee) external onlyOwner {
        attestationFee = _newFee;
        emit AttestationFeeUpdated(_newFee);
    }

    /**
     * @dev Sets the fee required to propose a new skill challenge. Only callable by the owner.
     * @param _newFee The new challenge creation fee in wei.
     */
    function setChallengeCreationFee(uint256 _newFee) external onlyOwner {
        challengeCreationFee = _newFee;
        emit ChallengeCreationFeeUpdated(_newFee);
    }

    /**
     * @dev Sets the rate at which reputation decays per second. Only callable by the owner.
     * @param _ratePerSecond The new decay rate (e.g., 1 means 1 point per second).
     */
    function setReputationDecayRate(uint256 _ratePerSecond) external onlyOwner {
        reputationDecayRatePerSecond = _ratePerSecond;
        emit ReputationDecayRateUpdated(_ratePerSecond);
    }

    /**
     * @dev Pauses certain contract operations (attestations, challenges). Only callable by the owner.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract operations. Only callable by the owner.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     * Currently supports only ETH withdrawal. For ERC20, an `IERC20` interface would be needed.
     * @param _tokenAddress The address of the token to withdraw (use address(0) for ETH).
     */
    function withdrawProtocolFees(address _tokenAddress) external onlyOwner {
        uint256 amount = protocolFeesCollected[_tokenAddress][protocolFeeRecipient];
        require(amount > 0, "No fees to withdraw");

        protocolFeesCollected[_tokenAddress][protocolFeeRecipient] = 0;

        if (_tokenAddress == address(0)) {
            payable(protocolFeeRecipient).transfer(amount);
        } else {
            // Placeholder: In a real system, you'd interact with IERC20 for token transfers.
            // IERC20(_tokenAddress).transfer(protocolFeeRecipient, amount);
            revert("ERC20 withdrawal not fully implemented for this example. Only ETH supported for now.");
        }
        emit ProtocolFeesWithdrawn(_tokenAddress, amount);
    }

    // --- II. Skill Node (ERC721 NFT) Management (4 functions) ---

    /**
     * @dev Creates a new unique skill category, represented by an ERC721 NFT.
     * Only callable by the contract owner.
     * @param _name The name of the skill (e.g., "Decentralized Finance").
     * @param _description A detailed description of the skill.
     * @param _initialReputationCap The maximum reputation a user can achieve for this skill.
     * @return The ID of the newly created skill node.
     */
    function createSkillNode(
        string calldata _name,
        string calldata _description,
        uint256 _initialReputationCap
    ) external onlyOwner returns (uint256) {
        uint256 newSkillNodeId = _nextTokenId++;
        skillNodes[newSkillNodeId] = SkillNode({
            name: _name,
            description: _description,
            reputationCap: _initialReputationCap
        });
        _safeMint(address(this), newSkillNodeId); // Mint the skill node NFT to the contract itself
        allSkillNodeIds.push(newSkillNodeId);

        // A `tokenURI` will conceptually point to off-chain metadata for this NFT.
        // For simplicity, it's a basic string, but could point to an IPFS hash.
        _setTokenURI(newSkillNodeId, string(abi.encodePacked("aetherplex.skillnode/", newSkillNodeId.toString())));

        emit SkillNodeCreated(newSkillNodeId, _name, _description, _initialReputationCap);
        return newSkillNodeId;
    }

    /**
     * @dev Updates the metadata (specifically description) for an existing skill node NFT.
     * Only callable by the contract owner.
     * @param _skillNodeId The ID of the skill node to update.
     * @param _newDescription The new description for the skill.
     */
    function updateSkillNodeMetadata(uint256 _skillNodeId, string calldata _newDescription) external onlyOwner {
        require(bytes(skillNodes[_skillNodeId].name).length > 0, "Skill node does not exist");
        skillNodes[_skillNodeId].description = _newDescription;
        emit SkillNodeMetadataUpdated(_skillNodeId, _newDescription);
    }

    /**
     * @dev Retrieves the details of a specific skill node.
     * @param _skillNodeId The ID of the skill node.
     * @return name The name of the skill.
     * @return description The description of the skill.
     * @return reputationCap The maximum reputation for this skill.
     */
    function getSkillNodeDetails(uint256 _skillNodeId)
        external
        view
        returns (string memory name, string memory description, uint256 reputationCap)
    {
        SkillNode storage node = skillNodes[_skillNodeId];
        require(bytes(node.name).length > 0, "Skill node does not exist");
        return (node.name, node.description, node.reputationCap);
    }

    /**
     * @dev Returns an array of all created skill node IDs.
     * @return An array of all skill node IDs.
     */
    function getAllSkillNodeIds() external view returns (uint256[] memory) {
        return allSkillNodeIds;
    }

    // --- III. Reputation & Attestation System (4 functions) ---

    /**
     * @dev Allows a user to attest to another user's skill.
     * Requires `attestationFee` to be paid with the transaction.
     * An attestor can only attest once per user per skill.
     * Attestation strength scales the reputation gain for the attested user.
     * @param _user The address of the user whose skill is being attested.
     * @param _skillNodeId The ID of the skill being attested.
     * @param _attestationStrength A value (1-100) indicating the strength/confidence of the attestation.
     */
    function attestSkill(address _user, uint256 _skillNodeId, uint256 _attestationStrength)
        external
        payable
        whenNotPaused
    {
        require(msg.sender != _user, "Cannot attest to your own skill");
        require(bytes(skillNodes[_skillNodeId].name).length > 0, "Skill node does not exist");
        require(_attestationStrength > 0 && _attestationStrength <= 100, "Attestation strength must be between 1-100");
        require(attestationsMade[msg.sender][_user][_skillNodeId] == 0, "Already attested to this user's skill");
        require(msg.value >= attestationFee, "Insufficient attestation fee");

        // Record fee
        if (msg.value > 0) {
            protocolFeesCollected[address(0)][protocolFeeRecipient] += msg.value; // Collect ETH fees
        }

        attestationsMade[msg.sender][_user][_skillNodeId] = _attestationStrength;
        attestationsReceived[_user][_skillNodeId].push(ReceivedAttestation({
            attestor: msg.sender,
            strength: _attestationStrength,
            timestamp: block.timestamp
        }));

        // Update target user's reputation immediately (decay applied implicitly by calculateEffectiveReputation)
        uint256 currentReputation = calculateEffectiveReputation(_user, _skillNodeId);
        uint256 newReputation = currentReputation + (_attestationStrength * 10); // Example: 10 points per strength unit
        if (newReputation > skillNodes[_skillNodeId].reputationCap) {
            newReputation = skillNodes[_skillNodeId].reputationCap;
        }
        userSkillReputations[_user][_skillNodeId] = UserSkillReputation({score: newReputation, lastUpdated: block.timestamp});

        emit SkillAttested(msg.sender, _user, _skillNodeId, _attestationStrength);
        emit SkillReputationUpdated(_user, _skillNodeId, newReputation, block.timestamp);
    }

    /**
     * @dev Allows an attestor to revoke a previously made attestation.
     * This will reduce the attested user's reputation accordingly.
     * @param _user The address of the user whose skill was attested.
     * @param _skillNodeId The ID of the skill.
     */
    function revokeAttestation(address _user, uint256 _skillNodeId) external whenNotPaused {
        uint256 strength = attestationsMade[msg.sender][_user][_skillNodeId];
        require(strength > 0, "No active attestation to revoke from this user for this skill");

        attestationsMade[msg.sender][_user][_skillNodeId] = 0; // Clear attestation
        
        // Remove the attestation from the received list (Note: array operations can be gas-intensive for large lists)
        ReceivedAttestation[] storage receivedList = attestationsReceived[_user][_skillNodeId];
        for (uint i = 0; i < receivedList.length; i++) {
            if (receivedList[i].attestor == msg.sender) {
                receivedList[i] = receivedList[receivedList.length - 1]; // Move last element to current position
                receivedList.pop(); // Remove last element
                break;
            }
        }

        // Update target user's reputation
        uint256 currentReputation = calculateEffectiveReputation(_user, _skillNodeId);
        uint256 reputationLoss = strength * 10;
        uint256 newReputation = currentReputation > reputationLoss ? currentReputation - reputationLoss : 0;
        userSkillReputations[_user][_skillNodeId] = UserSkillReputation({score: newReputation, lastUpdated: block.timestamp});

        emit AttestationRevoked(msg.sender, _user, _skillNodeId);
        emit SkillReputationUpdated(_user, _skillNodeId, newReputation, block.timestamp);
    }

    /**
     * @dev Calculates and returns a user's current effective reputation for a specific skill.
     * This function also triggers an on-chain update if the reputation is outdated, applying any accumulated decay.
     * @param _user The address of the user.
     * @param _skillNodeId The ID of the skill.
     * @return currentRep The user's effective reputation score.
     * @return lastUpdated The timestamp of the last reputation score update.
     */
    function getUserSkillReputation(address _user, uint256 _skillNodeId)
        public
        returns (uint256 currentRep, uint256 lastUpdated)
    {
        calculateEffectiveReputation(_user, _skillNodeId); // Ensure reputation is current before returning
        UserSkillReputation storage userRep = userSkillReputations[_user][_skillNodeId];
        return (userRep.score, userRep.lastUpdated);
    }

    /**
     * @dev Returns all attestations received by a specific user for a given skill.
     * @param _user The address of the user.
     * @param _skillNodeId The ID of the skill.
     * @return attestors An array of addresses of attestors.
     * @return strengths An array of strengths of corresponding attestations.
     * @return timestamps An array of timestamps when attestations were made.
     */
    function getAttestationsReceived(address _user, uint256 _skillNodeId)
        external
        view
        returns (address[] memory attestors, uint256[] memory strengths, uint256[] memory timestamps)
    {
        ReceivedAttestation[] storage receivedList = attestationsReceived[_user][_skillNodeId];
        attestors = new address[](receivedList.length);
        strengths = new uint256[](receivedList.length);
        timestamps = new uint256[](receivedList.length);

        for (uint i = 0; i < receivedList.length; i++) {
            attestors[i] = receivedList[i].attestor;
            strengths[i] = receivedList[i].strength;
            timestamps[i] = receivedList[i].timestamp;
        }
        return (attestors, strengths, timestamps);
    }

    // --- IV. Challenge & Proof System (4 functions) ---

    /**
     * @dev Proposes a new skill challenge. Requires `challengeCreationFee` to be paid.
     * @param _skillNodeId The ID of the skill this challenge relates to.
     * @param _challengeDetailsURI A URI pointing to off-chain details of the challenge (e.g., IPFS).
     * @param _reputationReward The reputation points awarded upon successful completion.
     * @param _requiredAttestationsForCompletion The number of valid attestations needed for proof completion.
     * @return The ID of the newly created challenge.
     */
    function proposeSkillChallenge(
        uint256 _skillNodeId,
        string calldata _challengeDetailsURI,
        uint256 _reputationReward,
        uint256 _requiredAttestationsForCompletion
    ) external payable whenNotPaused returns (uint256) {
        require(bytes(skillNodes[_skillNodeId].name).length > 0, "Skill node does not exist");
        require(_reputationReward > 0, "Reputation reward must be positive");
        require(_requiredAttestationsForCompletion > 0, "At least one attestation is required");
        require(msg.value >= challengeCreationFee, "Insufficient challenge creation fee");

        if (msg.value > 0) {
            protocolFeesCollected[address(0)][protocolFeeRecipient] += msg.value; // Collect ETH fees
        }

        uint256 newChallengeId = _nextChallengeId++;
        challenges[newChallengeId] = Challenge({
            skillNodeId: _skillNodeId,
            proposer: msg.sender,
            detailsURI: _challengeDetailsURI,
            reputationReward: _reputationReward,
            requiredAttestationsForCompletion: _requiredAttestationsForCompletion,
            status: ChallengeStatus.Proposed,
            participant: address(0), // No participant yet
            proofURI: "",
            proofSubmissionTime: 0,
            validAttestationsCount: 0,
            invalidAttestationsCount: 0,
            rewardClaimed: false
        });
        proposedChallenges.push(newChallengeId);

        emit ChallengeProposed(newChallengeId, _skillNodeId, _reputationReward);
        return newChallengeId;
    }

    /**
     * @dev Allows a user to submit a proof for a proposed skill challenge.
     * A challenge can only have one participant and one proof submission.
     * @param _challengeId The ID of the challenge.
     * @param _proofURI A URI pointing to the off-chain proof (e.g., IPFS link to a video, code, document).
     */
    function submitChallengeProof(uint256 _challengeId, string calldata _proofURI) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Proposed, "Challenge is not in proposed state");
        require(bytes(_proofURI).length > 0, "Proof URI cannot be empty");

        challenge.participant = msg.sender;
        challenge.proofURI = _proofURI;
        challenge.proofSubmissionTime = block.timestamp;
        challenge.status = ChallengeStatus.ProofSubmitted;

        emit ChallengeProofSubmitted(_challengeId, msg.sender, _proofURI);
    }

    /**
     * @dev Allows a community member (or a designated validator) to attest to a submitted proof.
     * Multiple attestations are required to validate a proof, mimicking a decentralized verification.
     * Note: In a production system, attestors might be whitelisted, or require a stake/reputation themselves.
     * @param _challengeId The ID of the challenge.
     * @param _participant The address of the user who submitted the proof.
     * @param _isProofValid True if the attester deems the proof valid, false otherwise.
     */
    function attestChallengeProof(uint256 _challengeId, address _participant, bool _isProofValid) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.ProofSubmitted, "Challenge proof is not awaiting attestation");
        require(challenge.participant == _participant, "Participant mismatch");
        require(msg.sender != _participant, "Cannot attest to your own proof");

        if (_isProofValid) {
            require(!challenge.attesterVotedValid[msg.sender], "Attester already voted valid");
            challenge.attesterVotedValid[msg.sender] = true;
            challenge.validAttestationsCount++;
        } else {
            require(!challenge.attesterVotedInvalid[msg.sender], "Attester already voted invalid");
            challenge.attesterVotedInvalid[msg.sender] = true;
            challenge.invalidAttestationsCount++;
        }

        emit ChallengeProofAttested(_challengeId, _participant, msg.sender, _isProofValid);

        // If enough valid attestations, mark as completed
        if (challenge.validAttestationsCount >= challenge.requiredAttestationsForCompletion) {
            challenge.status = ChallengeStatus.Completed;
            // The participant can now claim their reward via claimChallengeReward()
        }
        // An additional condition could be added for too many invalid attestations to cancel the challenge.
    }

    /**
     * @dev Allows the participant of a completed challenge to claim their reputation reward.
     * @param _challengeId The ID of the challenge.
     */
    function claimChallengeReward(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.participant == msg.sender, "Only the participant can claim this reward");
        require(challenge.status == ChallengeStatus.Completed, "Challenge is not completed");
        require(!challenge.rewardClaimed, "Reward already claimed");

        challenge.rewardClaimed = true;

        // Update participant's reputation (decay applied implicitly by calculateEffectiveReputation)
        uint256 currentReputation = calculateEffectiveReputation(msg.sender, challenge.skillNodeId);
        uint256 newReputation = currentReputation + challenge.reputationReward;
        if (newReputation > skillNodes[challenge.skillNodeId].reputationCap) {
            newReputation = skillNodes[challenge.skillNodeId].reputationCap;
        }
        userSkillReputations[msg.sender][challenge.skillNodeId] = UserSkillReputation({score: newReputation, lastUpdated: block.timestamp});

        emit ChallengeRewardClaimed(_challengeId, msg.sender, challenge.reputationReward);
        emit SkillReputationUpdated(msg.sender, challenge.skillNodeId, newReputation, block.timestamp);
    }

    // --- V. Dynamic Reputation Mechanism & Utilities (4 functions) ---

    /**
     * @dev Allows a user to trigger an on-chain calculation to update their stored reputation for a skill.
     * This function applies any accumulated decay or growth from recent activities.
     * It's a "pull" mechanism to avoid high gas costs of continuous updates for all users.
     * Calling `getUserSkillReputation` also implicitly calls this, ensuring fresh data.
     * @param _skillNodeId The ID of the skill for which to update reputation.
     */
    function updateMyReputation(uint256 _skillNodeId) public {
        calculateEffectiveReputation(msg.sender, _skillNodeId);
        // The internal function calculates and updates the state. Emit for clarity.
        emit SkillReputationUpdated(
            msg.sender,
            _skillNodeId,
            userSkillReputations[msg.sender][_skillNodeId].score,
            userSkillReputations[msg.sender][_skillNodeId].lastUpdated
        );
    }

    /**
     * @dev Internal helper function to compute a user's current reputation with decay applied.
     * This function also updates the stored reputation and lastUpdated timestamp.
     * @param _user The address of the user.
     * @param _skillNodeId The ID of the skill.
     * @return effectiveReputation The user's current reputation after applying decay.
     */
    function calculateEffectiveReputation(address _user, uint256 _skillNodeId) internal returns (uint256 effectiveReputation) {
        UserSkillReputation storage userRep = userSkillReputations[_user][_skillNodeId];
        uint256 currentTime = block.timestamp;
        
        // Calculate decay only if there's a score and time has passed
        if (userRep.score > 0 && currentTime > userRep.lastUpdated) {
            uint256 elapsed = currentTime - userRep.lastUpdated;
            uint256 decayedAmount = elapsed * reputationDecayRatePerSecond;

            if (userRep.score > decayedAmount) {
                userRep.score -= decayedAmount;
            } else {
                userRep.score = 0; // Reputation cannot go below zero
            }
        }
        userRep.lastUpdated = currentTime; // Update timestamp
        return userRep.score;
    }

    /**
     * @dev Returns a list of all currently proposed or active challenges.
     * Note: This returns the raw list of IDs. A more advanced system might filter by status.
     * @return An array of challenge IDs.
     */
    function getProposedChallenges() external view returns (uint256[] memory) {
        return proposedChallenges;
    }

    /**
     * @dev Retrieves the current status of a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return status The current status enum.
     * @return currentValidAttestations The number of valid attestations received for the proof.
     * @return requiredValidAttestations The number of valid attestations required for completion.
     * @return participant The address of the participant who submitted the proof.
     * @return proofURI The URI of the submitted proof.
     * @return skillNodeId The ID of the skill node associated with the challenge.
     * @return reputationReward The reputation reward for this challenge.
     */
    function getChallengeStatus(uint256 _challengeId)
        external
        view
        returns (
            ChallengeStatus status,
            uint256 currentValidAttestations,
            uint256 requiredValidAttestations,
            address participant,
            string memory proofURI,
            uint256 skillNodeId,
            uint256 reputationReward
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.skillNodeId > 0 || _challengeId == 0, "Challenge does not exist"); // Basic check for existence

        return (
            challenge.status,
            challenge.validAttestationsCount,
            challenge.requiredAttestationsForCompletion,
            challenge.participant,
            challenge.proofURI,
            challenge.skillNodeId,
            challenge.reputationReward
        );
    }

    // --- ERC721 Overrides for SkillNode NFTs ---
    // The SkillNode NFTs are minted to the contract itself to represent categories,
    // and are not intended to be transferable by external users.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, Ownable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Override tokenURI to return skill node details as metadata (conceptual)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        // In a real application, this would construct a JSON URI pointing to off-chain metadata (e.g., "ipfs://{hash}")
        // containing the skill name, description, and reputation cap.
        return string(abi.encodePacked("aetherplex.skillnode/", tokenId.toString()));
    }

    // Add receive and fallback to handle ETH for fees
    receive() external payable {
        // This makes the contract able to receive ETH. Fees are typically handled explicitly in functions.
    }
    fallback() external payable {
        // Fallback for unexpected calls, can also receive ETH.
    }
}

```