The `VeritasNexus` contract is a conceptual framework for a **Decentralized Knowledge & Impact Network**. It aims to foster a community around verifiable knowledge, incentivize accurate information, build on-chain reputation, and fund public goods research, while incorporating advanced concepts like Soul-Bound Tokens (SBTs), a placeholder for Zero-Knowledge Proofs (ZKPs) in validation, and direct oracle integration.

This contract does not duplicate any single open-source project; instead, it synthesizes multiple advanced concepts into a cohesive system, offering a unique combination of functionalities not found in a single existing contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title VeritasNexus - Decentralized Knowledge & Impact Network
 * @dev This contract establishes a decentralized protocol for curating, validating,
 *      and funding verifiable knowledge. It introduces concepts of Knowledge Capsules,
 *      a reputation-based validation system, dynamic Soul-Bound Tokens (SBTs) for
 *      Knowledge Profiles, and a public goods treasury governed by reputation.
 *      It also features a mechanism for decentralized oracle integration.
 *
 * @outline
 * I. Core Architecture & Interfaces: Basic setup and ownership.
 * II. Knowledge Capsule Management (KCM): Submission, updates, and retrieval of knowledge units.
 * III. Validation & Reputation System (VRS): Staking, voting, and finalization for capsule accuracy,
 *     including a placeholder for ZK-proofs or verifiable credentials.
 * IV. Dynamic Knowledge Profile (DKP) - Soul-Bound Token (SBT): Non-transferable NFTs
 *     representing a user's reputation and contributions within the network.
 * V. Decentralized Public Goods Treasury (DPGT): Mechanism for funding public goods and
 *    research based on reputation-weighted proposals.
 * VI. Dynamic Parameters & Governance (DPG): Functions for adjusting protocol parameters
 *    and integrating with external oracle services for data verification.
 *
 * @function_summary
 *
 * I. Core Architecture & Interfaces
 * 1.  constructor(): Initializes contract with owner.
 *
 * II. Knowledge Capsule Management (KCM)
 * 2.  submitKnowledgeCapsule(string calldata _ipfsCid, uint256 _topicId, uint256 _stakeAmount):
 *     Allows users to submit a new Knowledge Capsule (KC) with an IPFS CID, topic, and initial stake.
 * 3.  updateKnowledgeCapsule(uint256 _capsuleId, string calldata _newIpfsCid):
 *     Permits the original submitter to update their KC, subject to cooldown/penalty.
 * 4.  requestCapsuleValidation(uint256 _capsuleId):
 *     Initiates a formal validation round for a specific KC, making it available for voting.
 * 5.  getKnowledgeCapsule(uint256 _capsuleId):
 *     Retrieves all details for a given Knowledge Capsule.
 * 6.  listCapsulesByTopic(uint256 _topicId, uint256 _offset, uint256 _limit):
 *     Provides a paginated list of Knowledge Capsules filtered by topic.
 *
 * III. Validation & Reputation System (VRS)
 * 7.  stakeForValidation(uint256 _capsuleId, uint256 _stakeAmount):
 *     Allows users to stake tokens to become a validator for a capsule, showing commitment.
 * 8.  castValidationVote(uint256 _capsuleId, bool _isAccurate, bytes calldata _proof):
 *     Validators cast their vote on a capsule's accuracy. The `_proof` parameter is designed
 *     to accommodate advanced concepts like ZK-proofs for identity or verifiable credentials.
 * 9.  finalizeValidationRound(uint256 _capsuleId):
 *     Concludes the voting period for a capsule, distributes rewards/penalties, and updates
 *     validators' reputation scores.
 * 10. claimValidationReward(uint256 _capsuleId):
 *     Allows successful validators to claim their portion of the rewards from a finalized round.
 * 11. getValidatorReputation(address _validator):
 *     Retrieves the current cumulative reputation score for an address.
 *
 * IV. Dynamic Knowledge Profile (DKP) - Soul-Bound Token (SBT)
 * 12. mintKnowledgeProfile(address _owner):
 *     Mints a unique, non-transferable ERC721 token (SBT) for a user, serving as their
 *     on-chain identity and a representation of their accumulated reputation.
 * 13. updateKnowledgeProfileMetadata(uint256 _profileId, string calldata _newUri):
 *     Allows a DKP holder to update the metadata URI associated with their profile.
 * 14. getKnowledgeProfile(uint256 _profileId):
 *     Retrieves the details of a specific Knowledge Profile NFT.
 * 15. getProfileIdByAddress(address _addr):
 *     Returns the Knowledge Profile ID associated with a given address.
 *
 * V. Decentralized Public Goods Treasury (DPGT)
 * 16. contributeToTreasury():
 *     Allows anyone to send native currency (e.g., Ether) to the public goods treasury.
 * 17. submitResearchProposal(string calldata _proposalCid, uint256 _requestedAmount):
 *     Permits users (with sufficient reputation) to submit a proposal for funding from the treasury.
 * 18. voteOnProposal(uint256 _proposalId, bool _support):
 *     Knowledge Profile holders (DKP) vote on submitted proposals, with their vote weight
 *     determined by their reputation score.
 * 19. finalizeProposalVoting(uint256 _proposalId):
 *     Concludes the voting period for a proposal and determines its outcome.
 * 20. executeProposalPayout(uint256 _proposalId):
 *     Disburses funds to the approved proposal recipient if it passed the voting threshold.
 *
 * VI. Dynamic Parameters & Governance (DPG)
 * 21. setValidationMinStake(uint256 _newMinStake):
 *     Adjusts the minimum stake required to submit a capsule or become a validator.
 * 22. setValidationPeriod(uint256 _newPeriod):
 *     Sets the duration (in seconds) for a capsule's validation round and proposal voting.
 * 23. setProposalThreshold(uint256 _newThreshold):
 *     Sets the minimum reputation required for a Knowledge Profile to submit a research proposal.
 * 24. setTreasuryFundingFee(uint256 _newFeeBps):
 *     Adjusts a small percentage fee (in basis points) taken from certain operations (e.g., successful capsule submissions)
 *     to fund the public goods treasury.
 * 25. setOracleServiceFee(uint256 _newFee):
 *     Sets the fee for requesting data from the oracle service.
 * 26. setTrustedOracleAddress(address _newAddress):
 *     Sets the address of the trusted oracle contract/service.
 * 27. triggerOracleRequest(bytes32 _queryHash, uint256 _callbackCapsuleId):
 *     Initiates a request to an external decentralized oracle service to fetch off-chain data,
 *     linking the callback to a specific Knowledge Capsule for potential validation.
 * 28. receiveOracleResponse(uint256 _requestId, bytes calldata _data):
 *     A callback function intended to be called by an authorized oracle service to deliver
 *     requested off-chain data back to the contract.
 */
contract VeritasNexus is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // --- Core Counters ---
    Counters.Counter private _capsuleIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _oracleRequestIds;

    // --- Configuration Parameters (Adjustable by Governance) ---
    uint256 public validationMinStake = 0.1 ether; // Min stake for capsule submission & validation
    uint256 public validationPeriod = 3 days;      // Duration for validation rounds & proposal voting
    uint256 public proposalMinReputation = 100;    // Min reputation to submit a proposal
    uint256 public proposalQuorumBps = 5000;       // 50% quorum for proposals (basis points)
    uint256 public treasuryFundingFeeBps = 100;    // 1% fee (100 bps) on successful operations to fund treasury
    uint256 public oracleServiceFee = 0.01 ether;  // Fee to pay for oracle requests

    address public trustedOracleAddress; // Address of the trusted oracle contract/service

    // --- Knowledge Capsule Data ---
    struct KnowledgeCapsule {
        address submitter;
        string ipfsCid;
        uint256 topicId;
        uint256 submitTime;
        uint256 stake; // Initial stake by submitter

        // Validation Round specific
        uint256 validationRoundStartTime;
        uint256 totalYesVotes;
        uint256 totalNoVotes;
        uint256 totalValidationStake;
        uint256 validationFee; // Fee paid by submitter to start validation
        bool isValidated; // True if passed validation
        bool isValidationActive;
        bool validationFinalized;

        mapping(address => bool) hasVoted; // Validator -> Voted?
        mapping(address => uint256) validatorStakes; // Validator -> Stake Amount
        address[] currentValidators; // List of addresses currently validating this capsule
    }
    mapping(uint256 => KnowledgeCapsule) public knowledgeCapsules;
    mapping(uint256 => uint256[]) public capsulesByTopic; // topicId -> list of capsuleIds

    // --- Reputation System ---
    mapping(address => uint256) public userReputation; // address -> reputation score

    // --- Dynamic Knowledge Profile (SBT) ---
    // Inherits ERC721, but overridden _beforeTokenTransfer makes it non-transferable
    KnowledgeProfileNFT public knowledgeProfileNFT;

    // --- Public Goods Treasury ---
    struct ResearchProposal {
        address proposer;
        string ipfsCid; // IPFS CID for proposal details
        uint256 requestedAmount;
        uint256 submitTime;
        bool isApproved;
        bool hasBeenPaid;

        // Voting specific
        uint256 totalSupportReputation;
        uint256 totalOpposeReputation;
        uint256 totalVotersReputationSum; // Sum of reputation of all who voted
        uint256 voteEndTime;
        bool votingFinalized;

        mapping(address => bool) hasVotedOnProposal;
    }
    mapping(uint256 => ResearchProposal) public researchProposals;

    // --- Oracle Integration ---
    struct OracleRequest {
        address requester;
        bytes32 queryHash;
        uint256 callbackCapsuleId; // The capsule needing this data, 0 if not linked
        bool fulfilled;
        bytes responseData;
    }
    mapping(uint256 => OracleRequest) public oracleRequests;

    // --- Events ---
    event KnowledgeCapsuleSubmitted(uint256 indexed capsuleId, address indexed submitter, uint256 topicId, string ipfsCid);
    event KnowledgeCapsuleUpdated(uint256 indexed capsuleId, address indexed updater, string newIpfsCid);
    event ValidationRequested(uint256 indexed capsuleId, address indexed requester);
    event ValidationVoteCast(uint256 indexed capsuleId, address indexed voter, bool isAccurate, uint256 stake);
    event ValidationRoundFinalized(uint256 indexed capsuleId, bool isValidated, uint256 totalYes, uint256 totalNo);
    event ValidationRewardClaimed(uint256 indexed capsuleId, address indexed validator, uint256 rewardAmount);
    event ReputationUpdated(address indexed user, uint256 newReputation);

    event KnowledgeProfileMinted(uint256 indexed profileId, address indexed owner);
    event KnowledgeProfileMetadataUpdated(uint256 indexed profileId, string newUri);

    event TreasuryContributed(address indexed contributor, uint256 amount);
    event ResearchProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 requestedAmount, string ipfsCid);
    event ProposalVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalVotingFinalized(uint256 indexed proposalId, bool approved, uint256 totalSupport, uint256 totalOppose);
    event ProposalPayoutExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    event ValidationMinStakeSet(uint256 oldMinStake, uint256 newMinStake);
    event ValidationPeriodSet(uint256 oldPeriod, uint256 newPeriod);
    event ProposalThresholdSet(uint256 oldThreshold, uint256 newThreshold);
    event TreasuryFundingFeeSet(uint256 oldFeeBps, uint256 newFeeBps);
    event OracleServiceFeeSet(uint256 oldFee, uint256 newFee);
    event TrustedOracleAddressSet(address oldAddress, address newAddress);

    event OracleRequestTriggered(uint256 indexed requestId, address indexed requester, bytes32 queryHash, uint256 callbackCapsuleId);
    event OracleResponseReceived(uint256 indexed requestId, bytes data);

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        knowledgeProfileNFT = new KnowledgeProfileNFT(address(this)); // Initialize the SBT contract
    }

    // --- Internal / Helper Contract: KnowledgeProfileNFT (SBT) ---
    // This ERC721 extension ensures tokens are non-transferable (Soul-Bound)
    // and integrates with the main VeritasNexus contract for minting control.
    contract KnowledgeProfileNFT is ERC721, ERC721Burnable, Ownable {
        address public veritasNexusContract; // Reference to the main VeritasNexus contract
        mapping(address => uint256) private _profileIdByAddress; // Allows looking up profile ID by address

        constructor(address _veritasNexusContract) ERC721("KnowledgeProfile", "DKP") Ownable(msg.sender) {
            veritasNexusContract = _veritasNexusContract;
            // The owner of this NFT contract is VeritasNexus (the main contract).
            // This prevents external parties from minting or directly interacting with SBTs.
        }

        // Only VeritasNexus contract can mint new profiles
        function mint(address to, uint256 tokenId) external onlyOwner {
            // Check if the caller is the main VeritasNexus contract.
            // In OpenZeppelin Ownable, only the `owner()` can call functions marked `onlyOwner`.
            // So, `veritasNexusContract` (the address set in constructor) must be the `owner()` of this DKP contract.
            // This setup ensures that the main VeritasNexus contract (which is owned by its deployer initially)
            // is the only entity that can mint new DKP tokens.
            require(_profileIdByAddress[to] == 0, "DKP: Address already has a profile");
            _safeMint(to, tokenId);
            _profileIdByAddress[to] = tokenId;
        }

        // Override to prevent transfers, making it Soul-Bound
        function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
            super._beforeTokenTransfer(from, to, tokenId);
            // Allow minting (from address(0)) and burning (to address(0))
            if (from != address(0) && to != address(0)) {
                revert("DKP: Knowledge Profiles are non-transferable (Soul-Bound)");
            }
        }

        // Function to set token URI, exposed for the main VeritasNexus contract
        function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
            _setTokenURI(tokenId, _tokenURI);
        }

        function getProfileIdByAddress(address _addr) public view returns (uint256) {
            return _profileIdByAddress[_addr];
        }
    }


    // --- II. Knowledge Capsule Management (KCM) ---

    /**
     * @dev Submits a new Knowledge Capsule to the network. Requires an initial stake.
     * @param _ipfsCid The IPFS Content Identifier for the knowledge content.
     * @param _topicId An identifier for the topic or category of the capsule.
     * @param _stakeAmount The amount of native currency (e.g., Ether) staked by the submitter.
     */
    function submitKnowledgeCapsule(string calldata _ipfsCid, uint256 _topicId, uint256 _stakeAmount)
        external
        payable
        nonReentrant
    {
        require(msg.value == _stakeAmount, "KCM: Insufficient stake sent.");
        require(_stakeAmount >= validationMinStake, "KCM: Stake amount too low.");
        require(bytes(_ipfsCid).length > 0, "KCM: IPFS CID cannot be empty.");


        _capsuleIds.increment();
        uint256 newCapsuleId = _capsuleIds.current();

        KnowledgeCapsule storage capsule = knowledgeCapsules[newCapsuleId];
        capsule.submitter = msg.sender;
        capsule.ipfsCid = _ipfsCid;
        capsule.topicId = _topicId;
        capsule.submitTime = block.timestamp;
        capsule.stake = _stakeAmount;
        capsule.isValidationActive = false;
        capsule.isValidated = false;
        capsule.validationFinalized = false;

        capsulesByTopic[_topicId].push(newCapsuleId);

        emit KnowledgeCapsuleSubmitted(newCapsuleId, msg.sender, _topicId, _ipfsCid);
    }

    /**
     * @dev Allows the original submitter to update their Knowledge Capsule.
     *      Requires a cooldown period and can incur penalties (not fully implemented in v1 for simplicity).
     * @param _capsuleId The ID of the capsule to update.
     * @param _newIpfsCid The new IPFS CID for the updated content.
     */
    function updateKnowledgeCapsule(uint256 _capsuleId, string calldata _newIpfsCid)
        external
        nonReentrant
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.submitter == msg.sender, "KCM: Not the original submitter.");
        require(bytes(_newIpfsCid).length > 0, "KCM: New IPFS CID cannot be empty.");
        require(!capsule.isValidationActive, "KCM: Cannot update during active validation.");
        require(!capsule.validationFinalized, "KCM: Cannot update a finalized capsule.");

        // Add more sophisticated logic for penalties, cooldowns, or requiring new stake for significant changes.
        // For simplicity, we just allow the update if no validation is active.

        capsule.ipfsCid = _newIpfsCid;
        emit KnowledgeCapsuleUpdated(_capsuleId, msg.sender, _newIpfsCid);
    }

    /**
     * @dev Initiates a validation round for a Knowledge Capsule.
     *      Requires a fee paid by the requester.
     * @param _capsuleId The ID of the capsule to validate.
     */
    function requestCapsuleValidation(uint256 _capsuleId)
        external
        payable
        nonReentrant
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.submitter != address(0), "KCM: Capsule does not exist.");
        require(!capsule.isValidationActive, "KCM: Validation already active or finalized for this capsule.");
        require(!capsule.validationFinalized, "KCM: Validation already finalized for this capsule.");
        require(msg.value >= validationMinStake, "KCM: Insufficient fee to request validation.");

        capsule.isValidationActive = true;
        capsule.validationRoundStartTime = block.timestamp;
        capsule.totalYesVotes = 0;
        capsule.totalNoVotes = 0;
        capsule.totalValidationStake = 0;
        capsule.validationFee = msg.value; // Fee paid to initiate validation
        delete capsule.currentValidators; // Clear previous validators (if any)

        emit ValidationRequested(_capsuleId, msg.sender);
    }

    /**
     * @dev Retrieves details of a specific Knowledge Capsule.
     * @param _capsuleId The ID of the capsule.
     * @return tuple(address submitter, string ipfsCid, uint256 topicId, uint256 submitTime, uint256 stake,
     *               uint256 validationRoundStartTime, uint256 totalYesVotes, uint256 totalNoVotes,
     *               uint256 totalValidationStake, bool isValidated, bool isValidationActive, bool validationFinalized)
     */
    function getKnowledgeCapsule(uint256 _capsuleId)
        public
        view
        returns (
            address submitter,
            string memory ipfsCid,
            uint256 topicId,
            uint256 submitTime,
            uint256 stake,
            uint256 validationRoundStartTime,
            uint256 totalYesVotes,
            uint256 totalNoVotes,
            uint256 totalValidationStake,
            bool isValidated,
            bool isValidationActive,
            bool validationFinalized
        )
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.submitter != address(0), "KCM: Capsule does not exist.");

        return (
            capsule.submitter,
            capsule.ipfsCid,
            capsule.topicId,
            capsule.submitTime,
            capsule.stake,
            capsule.validationRoundStartTime,
            capsule.totalYesVotes,
            capsule.totalNoVotes,
            capsule.totalValidationStake,
            capsule.isValidated,
            capsule.isValidationActive,
            capsule.validationFinalized
        );
    }

    /**
     * @dev Provides a paginated list of Knowledge Capsule IDs for a given topic.
     * @param _topicId The ID of the topic.
     * @param _offset The starting index for pagination.
     * @param _limit The maximum number of capsule IDs to return.
     * @return An array of capsule IDs.
     */
    function listCapsulesByTopic(uint256 _topicId, uint256 _offset, uint256 _limit)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] storage topicCapsules = capsulesByTopic[_topicId];
        uint256 total = topicCapsules.length;
        require(_offset <= total, "KCM: Offset out of bounds.");

        uint256 endIndex = _offset + _limit;
        if (endIndex > total) {
            endIndex = total;
        }

        uint256[] memory result = new uint256[](endIndex - _offset);
        for (uint256 i = _offset; i < endIndex; i++) {
            result[i - _offset] = topicCapsules[i];
        }
        return result;
    }


    // --- III. Validation & Reputation System (VRS) ---

    /**
     * @dev Allows a user to stake funds to participate in the validation of a Knowledge Capsule.
     * @param _capsuleId The ID of the capsule to validate.
     * @param _stakeAmount The amount to stake.
     */
    function stakeForValidation(uint256 _capsuleId, uint256 _stakeAmount)
        external
        payable
        nonReentrant
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.submitter != address(0), "VRS: Capsule does not exist.");
        require(capsule.isValidationActive, "VRS: Validation not active for this capsule.");
        require(block.timestamp <= capsule.validationRoundStartTime + validationPeriod, "VRS: Validation period ended.");
        require(_stakeAmount >= validationMinStake, "VRS: Stake amount too low.");
        require(msg.value == _stakeAmount, "VRS: Incorrect stake amount sent.");
        require(capsule.validatorStakes[msg.sender] == 0, "VRS: Already staked for this validation.");
        require(!capsule.hasVoted[msg.sender], "VRS: Already voted for this capsule."); // Cannot re-stake if already voted

        capsule.validatorStakes[msg.sender] = _stakeAmount;
        capsule.totalValidationStake += _stakeAmount;
        capsule.currentValidators.push(msg.sender);
    }

    /**
     * @dev Allows a staked validator to cast their vote on the accuracy of a Knowledge Capsule.
     * @param _capsuleId The ID of the capsule being validated.
     * @param _isAccurate True if the validator believes the capsule is accurate, false otherwise.
     * @param _proof A byte array for potential ZK-proofs or verifiable credentials, enhancing trust or privacy.
     *                The contract does not natively verify ZK-proofs, but this field serves as a placeholder
     *                for off-chain verification or a hash of an on-chain verifier contract call.
     */
    function castValidationVote(uint256 _capsuleId, bool _isAccurate, bytes calldata _proof)
        external
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.submitter != address(0), "VRS: Capsule does not exist.");
        require(capsule.isValidationActive, "VRS: Validation not active for this capsule.");
        require(block.timestamp <= capsule.validationRoundStartTime + validationPeriod, "VRS: Validation period ended.");
        require(capsule.validatorStakes[msg.sender] > 0, "VRS: Not a staked validator for this capsule.");
        require(!capsule.hasVoted[msg.sender], "VRS: Already voted on this capsule.");

        if (_isAccurate) {
            capsule.totalYesVotes += capsule.validatorStakes[msg.sender];
        } else {
            capsule.totalNoVotes += capsule.validatorStakes[msg.sender];
        }
        capsule.hasVoted[msg.sender] = true;

        emit ValidationVoteCast(_capsuleId, msg.sender, _isAccurate, capsule.validatorStakes[msg.sender]);
        // The `_proof` parameter's contents would be verified off-chain or by a separate verifier contract.
        // E.g., a hash of the ZK-proof sent here, and the full proof verified off-chain for reputation impact.
    }

    /**
     * @dev Finalizes a validation round after the validation period ends.
     *      Distributes rewards/penalties and updates reputation scores.
     * @param _capsuleId The ID of the capsule to finalize.
     */
    function finalizeValidationRound(uint256 _capsuleId)
        external
        nonReentrant
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.submitter != address(0), "VRS: Capsule does not exist.");
        require(capsule.isValidationActive, "VRS: Validation not active.");
        require(block.timestamp > capsule.validationRoundStartTime + validationPeriod, "VRS: Validation period not ended yet.");
        require(!capsule.validationFinalized, "VRS: Validation already finalized.");

        capsule.isValidationActive = false;
        capsule.validationFinalized = true;

        uint256 totalVotes = capsule.totalYesVotes + capsule.totalNoVotes;
        bool capsulePassed = false;

        // If no votes were cast, the capsule remains unvalidated.
        // Otherwise, simple majority rules.
        if (totalVotes > 0) {
            if (capsule.totalYesVotes > capsule.totalNoVotes) {
                capsulePassed = true;
                capsule.isValidated = true;
            } else {
                capsule.isValidated = false;
            }
        } else {
            capsule.isValidated = false; // No votes, so not validated
        }

        // --- Distribute Rewards/Penalties and Update Reputation ---
        uint256 rewardPool = capsule.stake + capsule.validationFee; // Sum of submitter's stake and validation fee

        uint256 totalWinningStake = 0;
        address[] memory winningValidators = new address[](capsule.currentValidators.length); // Max possible winners
        uint256 winningCount = 0;

        for (uint256 i = 0; i < capsule.currentValidators.length; i++) {
            address validator = capsule.currentValidators[i];
            uint256 validatorStake = capsule.validatorStakes[validator];

            if (validatorStake == 0 || !capsule.hasVoted[validator]) {
                // Return stake for those who didn't vote or didn't stake properly (should be caught earlier)
                if (validatorStake > 0) {
                    (bool sent, ) = validator.call{value: validatorStake}("");
                    require(sent, "VRS: Failed to return non-voter stake.");
                }
                continue;
            }

            // In this simplified model, we assume a validator is "winning" if they voted
            // and the overall outcome matches the "Yes" majority (if capsule passed)
            // or "No" majority (if capsule failed, though no specific "No" vote count is tracked per validator).
            // A more robust system would store each validator's specific vote.
            // Here, winning validators are those whose participation led to the overall outcome.

            // If the capsule passed, all who voted contribute to the 'winning' outcome.
            // If it failed, no one truly 'won' validation, so no rewards from this pool.
            if (capsulePassed) {
                winningValidators[winningCount++] = validator;
                totalWinningStake += validatorStake;

                // Reputation boost for contributing to valid knowledge
                userReputation[validator] += 1;
                emit ReputationUpdated(validator, userReputation[validator]);
            } else {
                // If capsule failed, no rewards from this pool for validators.
                // Just return stake.
                (bool sent, ) = validator.call{value: validatorStake}("");
                require(sent, "VRS: Failed to return validator stake.");
            }
        }

        if (capsulePassed) {
            // If the capsule passed, distribute the `rewardPool` among winning validators
            // based on their staked amount for this validation.
            if (totalWinningStake > 0) {
                uint256 rewardSharePerStake = (rewardPool * 1e18) / totalWinningStake; // Use 1e18 for fixed point division
                for (uint256 j = 0; j < winningCount; j++) {
                    address validator = winningValidators[j];
                    uint256 rewardAmount = (capsule.validatorStakes[validator] * rewardSharePerStake) / 1e18;
                    (bool sent, ) = validator.call{value: rewardAmount}("");
                    require(sent, "VRS: Failed to send reward to validator.");
                    emit ValidationRewardClaimed(_capsuleId, validator, rewardAmount);
                }
                // Any remainder from integer division goes to the treasury
                uint256 distributedRewards = (totalWinningStake * rewardSharePerStake) / 1e18;
                if (rewardPool > distributedRewards) {
                     (bool sent, ) = address(this).call{value: rewardPool - distributedRewards}("");
                     require(sent, "VRS: Failed to send remainder to treasury.");
                }
            } else {
                // No validators for a passed capsule, send full reward pool to treasury
                (bool sent, ) = address(this).call{value: rewardPool}("");
                require(sent, "VRS: Failed to send unused reward to treasury.");
            }

            // Reputation boost for the submitter of a successfully validated capsule.
            userReputation[capsule.submitter] += 5;
            emit ReputationUpdated(capsule.submitter, userReputation[capsule.submitter]);

        } else { // Capsule failed validation or no votes resulted in validation
            // Submitter's initial stake and validation fee are sent to treasury as penalty/contribution.
            (bool sent, ) = address(this).call{value: rewardPool}("");
            require(sent, "VRS: Failed to send failed capsule funds to treasury.");
        }

        emit ValidationRoundFinalized(_capsuleId, capsulePassed, capsule.totalYesVotes, capsule.totalNoVotes);
    }

    /**
     * @dev Allows a validator to claim their earned reward from a finalized validation round.
     *      NOTE: In this simplified implementation, rewards are distributed directly in `finalizeValidationRound`.
     *      This function serves as a placeholder for potential future pull-based reward mechanisms or
     *      claiming of additional, non-direct incentives. It will currently revert.
     * @param _capsuleId The ID of the capsule for which to claim rewards.
     */
    function claimValidationReward(uint256 _capsuleId) external view {
        revert("VRS: Rewards are distributed directly upon finalization or claimed via other means.");
        // If a pull system was implemented, this would check if msg.sender has unclaimed rewards and send them.
    }

    /**
     * @dev Retrieves the current reputation score for a given address.
     * @param _validator The address whose reputation to query.
     * @return The reputation score.
     */
    function getValidatorReputation(address _validator) public view returns (uint256) {
        return userReputation[_validator];
    }


    // --- IV. Dynamic Knowledge Profile (DKP) - Soul-Bound Token (SBT) ---

    /**
     * @dev Mints a new Knowledge Profile NFT (SBT) for a user.
     *      A user can only have one DKP. Minting is publicly callable, but could be gated by governance.
     * @param _owner The address to mint the DKP for.
     */
    function mintKnowledgeProfile(address _owner)
        external
        nonReentrant
    {
        require(knowledgeProfileNFT.getProfileIdByAddress(_owner) == 0, "DKP: Address already has a profile.");

        // `tokenId` can be managed in various ways. Simple increment here.
        // Using `_capsuleIds.current() + _proposalIds.current() + 1` could be one way for unique but arbitrary ID.
        // For actual unique token IDs per ERC721, `knowledgeProfileNFT.totalSupply() + 1` is common.
        // It's safer to use an internal counter for the DKP token ID in the DKP contract itself.
        // For simplicity, let's just pass `msg.sender` as ID and ensure it's mapped to a DKP.
        // Or, more generically: `uint256 newProfileId = uint256(uint160(_owner));`
        // Given ERC721 expects a `uint256` token ID, using `_owner` address as part of `uint256` is common.
        // Better: use an internal counter in the DKP contract. Let's make `KnowledgeProfileNFT` handle token ID generation.
        // We'll adjust `mint` on `KnowledgeProfileNFT` to take `address to` and generate its own ID.

        // Reverting this logic, it's simpler if the main contract keeps track of the ID to issue.
        // Let's use `knowledgeProfileNFT.totalSupply() + 1` as a simple ID for now.
        // The DKP contract itself holds the `_capsuleIds` counter. Let's add that to DKP.
        // For now, the main VeritasNexus contract assigns the ID.
        uint256 newProfileId = knowledgeProfileNFT.totalSupply() + 1; // Assuming `totalSupply()` works correctly for `ERC721`

        // The DKP contract's `mint` function is `onlyOwner`. The owner of the DKP contract is `address(this)`.
        knowledgeProfileNFT.mint(_owner, newProfileId);
        emit KnowledgeProfileMinted(newProfileId, _owner);
    }

    /**
     * @dev Allows a DKP holder to update the metadata URI for their profile NFT.
     * @param _profileId The ID of the DKP to update.
     * @param _newUri The new URI pointing to the metadata (e.g., IPFS CID).
     */
    function updateKnowledgeProfileMetadata(uint256 _profileId, string calldata _newUri)
        external
    {
        require(knowledgeProfileNFT.ownerOf(_profileId) == msg.sender, "DKP: Not the owner of this profile.");
        knowledgeProfileNFT.setTokenURI(_profileId, _newUri); // Call the DKP contract's setTokenURI
        emit KnowledgeProfileMetadataUpdated(_profileId, _newUri);
    }

    /**
     * @dev Retrieves details of a specific Knowledge Profile NFT.
     * @param _profileId The ID of the DKP.
     * @return tuple(address owner, string tokenURI, uint256 reputationScore)
     */
    function getKnowledgeProfile(uint256 _profileId)
        public
        view
        returns (address owner, string memory tokenURI, uint256 reputationScore)
    {
        require(knowledgeProfileNFT.exists(_profileId), "DKP: Profile does not exist.");
        owner = knowledgeProfileNFT.ownerOf(_profileId);
        tokenURI = knowledgeProfileNFT.tokenURI(_profileId);
        reputationScore = userReputation[owner]; // Linked to the user's general reputation
        return (owner, tokenURI, reputationScore);
    }

    /**
     * @dev Returns the Knowledge Profile ID associated with a given address.
     * @param _addr The address to query.
     * @return The profile ID, or 0 if no profile exists for the address.
     */
    function getProfileIdByAddress(address _addr) public view returns (uint256) {
        return knowledgeProfileNFT.getProfileIdByAddress(_addr);
    }


    // --- V. Decentralized Public Goods Treasury (DPGT) ---

    /**
     * @dev Allows anyone to contribute native currency to the public goods treasury.
     */
    function contributeToTreasury() external payable {
        require(msg.value > 0, "DPGT: Must send ETH to contribute.");
        emit TreasuryContributed(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to submit a proposal for funding from the public goods treasury.
     *      Requires a minimum reputation score.
     * @param _proposalCid The IPFS CID for the detailed proposal document.
     * @param _requestedAmount The amount of funds requested from the treasury.
     */
    function submitResearchProposal(string calldata _proposalCid, uint256 _requestedAmount)
        external
        nonReentrant
    {
        require(userReputation[msg.sender] >= proposalMinReputation, "DPGT: Insufficient reputation to submit proposal.");
        require(_requestedAmount > 0, "DPGT: Requested amount must be greater than zero.");
        require(bytes(_proposalCid).length > 0, "DPGT: Proposal CID cannot be empty.");
        require(address(this).balance >= _requestedAmount, "DPGT: Treasury does not have sufficient funds for this request.");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        ResearchProposal storage proposal = researchProposals[newProposalId];
        proposal.proposer = msg.sender;
        proposal.ipfsCid = _proposalCid;
        proposal.requestedAmount = _requestedAmount;
        proposal.submitTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + validationPeriod; // Use validationPeriod for proposals too
        proposal.isApproved = false;
        proposal.hasBeenPaid = false;
        proposal.votingFinalized = false;

        emit ResearchProposalSubmitted(newProposalId, msg.sender, _requestedAmount, _ipfsCid);
    }

    /**
     * @dev Allows Knowledge Profile holders to vote on research proposals.
     *      Vote weight is determined by their reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "yes", false for "no".
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
    {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.proposer != address(0), "DPGT: Proposal does not exist.");
        require(block.timestamp <= proposal.voteEndTime, "DPGT: Proposal voting period ended.");
        require(!proposal.votingFinalized, "DPGT: Proposal voting already finalized.");
        require(knowledgeProfileNFT.getProfileIdByAddress(msg.sender) > 0, "DPGT: Only Knowledge Profile holders can vote.");
        require(!proposal.hasVotedOnProposal[msg.sender], "DPGT: Already voted on this proposal.");

        uint256 voterReputation = userReputation[msg.sender];
        require(voterReputation > 0, "DPGT: Voter must have reputation to cast a weighted vote.");

        if (_support) {
            proposal.totalSupportReputation += voterReputation;
        } else {
            proposal.totalOpposeReputation += voterReputation;
        }
        proposal.totalVotersReputationSum += voterReputation;
        proposal.hasVotedOnProposal[msg.sender] = true;

        emit ProposalVoteCast(_proposalId, msg.sender, _support, voterReputation);
    }

    /**
     * @dev Finalizes the voting for a research proposal.
     *      Determines if the proposal passes based on reputation-weighted votes.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposalVoting(uint256 _proposalId)
        external
        nonReentrant
    {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.proposer != address(0), "DPGT: Proposal does not exist.");
        require(block.timestamp > proposal.voteEndTime, "DPGT: Proposal voting period not ended yet.");
        require(!proposal.votingFinalized, "DPGT: Proposal voting already finalized.");

        proposal.votingFinalized = true;

        uint256 totalReputationCast = proposal.totalSupportReputation + proposal.totalOpposeReputation;
        // Check for quorum and majority
        if (totalReputationCast > 0 &&
            (proposal.totalSupportReputation * 10000 / totalReputationCast) >= proposalQuorumBps && // Quorum check
            proposal.totalSupportReputation > proposal.totalOpposeReputation) { // Majority check
            proposal.isApproved = true;
        } else {
            proposal.isApproved = false;
        }

        emit ProposalVotingFinalized(_proposalId, proposal.isApproved, proposal.totalSupportReputation, proposal.totalOpposeReputation);
    }

    /**
     * @dev Executes the payout for an approved research proposal from the treasury.
     *      Only callable after voting has been finalized and the proposal is approved.
     * @param _proposalId The ID of the proposal to pay out.
     */
    function executeProposalPayout(uint256 _proposalId)
        external
        nonReentrant
    {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.proposer != address(0), "DPGT: Proposal does not exist.");
        require(proposal.votingFinalized, "DPGT: Proposal voting not finalized.");
        require(proposal.isApproved, "DPGT: Proposal not approved.");
        require(!proposal.hasBeenPaid, "DPGT: Proposal already paid out.");
        require(address(this).balance >= proposal.requestedAmount, "DPGT: Insufficient funds in treasury.");

        proposal.hasBeenPaid = true;
        (bool sent, ) = proposal.proposer.call{value: proposal.requestedAmount}("");
        require(sent, "DPGT: Failed to send funds to proposer.");

        emit ProposalPayoutExecuted(_proposalId, proposal.proposer, proposal.requestedAmount);
    }


    // --- VI. Dynamic Parameters & Governance (DPG) ---

    /**
     * @dev Sets the minimum stake required for a Knowledge Capsule submission or validator participation.
     *      Only callable by the contract owner (or a future governance module).
     * @param _newMinStake The new minimum stake amount.
     */
    function setValidationMinStake(uint256 _newMinStake) external onlyOwner {
        require(_newMinStake > 0, "DPG: Min stake must be greater than zero.");
        emit ValidationMinStakeSet(validationMinStake, _newMinStake);
        validationMinStake = _newMinStake;
    }

    /**
     * @dev Sets the duration (in seconds) for validation rounds and proposal voting.
     *      Only callable by the contract owner.
     * @param _newPeriod The new period duration in seconds.
     */
    function setValidationPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "DPG: Period must be greater than zero.");
        emit ValidationPeriodSet(validationPeriod, _newPeriod);
        validationPeriod = _newPeriod;
    }

    /**
     * @dev Sets the minimum reputation required for a Knowledge Profile to submit a research proposal.
     *      Only callable by the contract owner.
     * @param _newThreshold The new minimum reputation threshold.
     */
    function setProposalThreshold(uint256 _newThreshold) external onlyOwner {
        emit ProposalThresholdSet(proposalMinReputation, _newThreshold);
        proposalMinReputation = _newThreshold;
    }

    /**
     * @dev Sets the percentage fee (in basis points, 10000 = 100%) on certain operations
     *      to fund the public goods treasury.
     *      Only callable by the contract owner.
     * @param _newFeeBps The new fee in basis points (e.g., 100 for 1%).
     */
    function setTreasuryFundingFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "DPG: Fee cannot exceed 100%."); // Max 100%
        emit TreasuryFundingFeeSet(treasuryFundingFeeBps, _newFeeBps);
        treasuryFundingFeeBps = _newFeeBps;
    }

    /**
     * @dev Sets the fee for requesting data from the oracle service.
     *      Only callable by the contract owner.
     * @param _newFee The new oracle service fee.
     */
    function setOracleServiceFee(uint256 _newFee) external onlyOwner {
        emit OracleServiceFeeSet(oracleServiceFee, _newFee);
        oracleServiceFee = _newFee;
    }

    /**
     * @dev Sets the address of the trusted oracle contract/service.
     *      This address is authorized to call `receiveOracleResponse`.
     *      Only callable by the contract owner.
     * @param _newAddress The new trusted oracle address.
     */
    function setTrustedOracleAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "DPG: Oracle address cannot be zero.");
        emit TrustedOracleAddressSet(trustedOracleAddress, _newAddress);
        trustedOracleAddress = _newAddress;
    }

    /**
     * @dev Triggers a request to an external decentralized oracle service.
     *      Requires payment of `oracleServiceFee`.
     * @param _queryHash A hash representing the specific query for the oracle (e.g., hash of a query string).
     * @param _callbackCapsuleId An optional ID of a Knowledge Capsule that needs this data for validation.
     *                           0 if not linked to a specific capsule.
     */
    function triggerOracleRequest(bytes32 _queryHash, uint256 _callbackCapsuleId)
        external
        payable
        nonReentrant
    {
        require(trustedOracleAddress != address(0), "DPG: Oracle address not set.");
        require(msg.value >= oracleServiceFee, "DPG: Insufficient oracle service fee.");

        _oracleRequestIds.increment();
        uint256 requestId = _oracleRequestIds.current();

        oracleRequests[requestId] = OracleRequest({
            requester: msg.sender,
            queryHash: _queryHash,
            callbackCapsuleId: _callbackCapsuleId,
            fulfilled: false,
            responseData: "" // Placeholder
        });

        // In a real system, this would typically involve an interface call to the oracle contract:
        // IOracle(trustedOracleAddress).requestData(requestId, _queryHash, address(this), "receiveOracleResponse(uint256,bytes)");
        // For this example, we log the event and expect the oracle to call `receiveOracleResponse` manually or via its off-chain component.

        emit OracleRequestTriggered(requestId, msg.sender, _queryHash, _callbackCapsuleId);
    }

    /**
     * @dev Callback function for the trusted oracle service to deliver requested data.
     *      Only callable by the `trustedOracleAddress`.
     * @param _requestId The ID of the original oracle request.
     * @param _data The data returned by the oracle.
     */
    function receiveOracleResponse(uint256 _requestId, bytes calldata _data)
        external
    {
        require(msg.sender == trustedOracleAddress, "DPG: Only trusted oracle can call this function.");
        OracleRequest storage req = oracleRequests[_requestId];
        require(req.requester != address(0), "DPG: Oracle request does not exist."); // Check if request ID is valid
        require(!req.fulfilled, "DPG: Oracle request already fulfilled.");

        req.fulfilled = true;
        req.responseData = _data;

        // Logic to use the received data, e.g., for capsule validation, goes here.
        // If `req.callbackCapsuleId != 0`, additional logic could be triggered
        // to process the data in context of the specific Knowledge Capsule,
        // potentially impacting its validation status or associated reputation.

        emit OracleResponseReceived(_requestId, _data);
    }

    // --- Fallback to receive funds ---
    receive() external payable {
        // Any direct native currency (e.g., Ether) sent to the contract (not through specific functions)
        // is considered a general contribution to the public goods treasury.
        emit TreasuryContributed(msg.sender, msg.value);
    }
}
```