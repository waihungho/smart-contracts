Okay, let's design a smart contract that goes beyond standard patterns like ERC-20 or simple DAOs. We'll create a contract for a "Decentralized Trust & Reputation Layer" combined with a dynamic Proposal/Flag system, where a user's influence and abilities are directly tied to their on-chain "Trust Score". This involves dynamic state changes, weighted voting, time-based logic, and multiple interconnected components.

**Concept:** Decentralized Trust & Collaboration Engine

**Outline:**

1.  **Introduction:** Purpose and core concepts (Trust Score, Proposals, Flags).
2.  **State Variables:** Storage for users, trust scores, proposals, flags, parameters, owner, pause status.
3.  **Structs & Enums:** Data structures for User Profiles, Proposals, Flags, and their states.
4.  **Events:** Notifications for key actions and state changes.
5.  **Modifiers:** Access control (`onlyOwner`, `whenNotPaused`) and custom checks (`isRegistered`, `hasMinTrustForProposal`).
6.  **User Management:** Registration, profile updates, viewing user data.
7.  **Trust & Reputation:** Core logic for calculating and updating Trust Scores based on interactions (vouching, proposal outcomes, flag outcomes).
8.  **Proposal System:** Creation, voting (weighted by Trust Score), finalization, result submission.
9.  **Flag System:** Reporting users, voting on flags (weighted), finalization.
10. **Parameter Management:** Admin functions to set system constants (minimum trust, voting periods, score changes).
11. **Utility/View Functions:** Getters for various states and data.
12. **Administrative Functions:** Owner-only actions like pausing, withdrawing fees.

**Function Summary (At least 20 functions):**

1.  `constructor()`: Initializes the contract, sets owner and initial parameters.
2.  `registerUser(string calldata _name, string calldata _profileURI)`: Allows a user to register and create a profile, paying a fee.
3.  `updateUserProfile(string calldata _name, string calldata _profileURI)`: Allows a registered user to update their profile details.
4.  `getUserProfile(address _user)`: Views the profile details of a user.
5.  `getTrustScore(address _user)`: Views the current Trust Score of a user.
6.  `vouchForUser(address _user)`: Allows a registered user to vouch for another user, increasing their Trust Score based on the vouchee's current score and parameters.
7.  `proposeProject(string calldata _title, string calldata _descriptionURI, uint256 _durationBlocks)`: Allows a user with sufficient Trust Score to create a new project proposal.
8.  `voteOnProposal(uint256 _proposalId, bool _support)`: Allows a registered user to cast a weighted vote on a proposal. Weight is their current Trust Score.
9.  `finalizeProposal(uint256 _proposalId)`: Finalizes a proposal after its voting period ends, determining outcome based on total weighted votes.
10. `submitProposalResult(uint256 _proposalId, bool _success)`: Allows the original proposer (or designated agent) to report the outcome of a completed project proposal (simulated), affecting their score.
11. `getProposalDetails(uint256 _proposalId)`: Views details of a specific proposal.
12. `reportUser(address _user, string calldata _reasonURI)`: Allows a registered user to flag another user for review, creating a new flag object.
13. `voteOnFlag(uint256 _flagId, bool _support)`: Allows a registered user to cast a weighted vote on whether a flag is valid.
14. `finalizeFlagVote(uint256 _flagId)`: Finalizes a flag vote after its period ends, adjusting scores of the reported user and reporter based on the outcome.
15. `getFlagDetails(uint256 _flagId)`: Views details of a specific flag.
16. `getUserState(address _user)`: Views the current state of a user (e.g., Registered, Flagged, Frozen).
17. `getTotalRegisteredUsers()`: Views the total number of registered users.
18. `getTotalProposals()`: Views the total number of proposals created.
19. `getTotalFlags()`: Views the total number of flags created.
20. `setMinimumTrustForProposal(uint256 _score)`: Admin function to set the minimum Trust Score required to create a proposal.
21. `setVotingPeriodBlocks(uint256 _blocks)`: Admin function to set the duration (in blocks) for proposal and flag voting.
22. `setInitialTrustScore(uint256 _score)`: Admin function to set the initial Trust Score granted upon registration.
23. `setTrustGainOnVouch(uint256 _gainBasisPoints)`: Admin function to set the percentage (in basis points) increase in vouchee's score based on vouches.
24. `setTrustChangeOnProposalResult(uint256 _successGainBasisPoints, uint256 _failureLossBasisPoints)`: Admin function to set score changes for proposers based on project outcome.
25. `setTrustChangeOnFlagVote(uint256 _flaggedLossBasisPoints, uint256 _reporterGainOnValidBasisPoints, uint256 _reporterLossOnInvalidBasisPoints)`: Admin function to set score changes based on flag vote outcomes.
26. `setRegistrationFee(uint256 _fee)`: Admin function to set the fee required for user registration.
27. `withdrawAdminFees()`: Admin function to withdraw accumulated registration fees.
28. `pauseContract()`: Admin function to pause certain contract operations in an emergency.
29. `unpauseContract()`: Admin function to unpause the contract.
30. `getUserProposals(address _user)`: View function to get a list of proposal IDs submitted by a user.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedTrustAndCollaborationEngine
 * @dev A smart contract implementing a decentralized trust, reputation,
 *      and collaboration system with dynamic user states, weighted voting,
 *      and integrated proposal and flagging mechanisms.
 *      Influence (voting weight, proposal ability) is tied to on-chain
 *      Trust Score, which is dynamically updated based on user interactions
 *      and outcomes within the system. Avoids direct copying of common
 *      ERC standards or basic DAO patterns by integrating these concepts
 *      in a novel way focused on reputation.
 */

/**
 * @notice Outline:
 * 1. Introduction: Purpose and core concepts.
 * 2. State Variables: Storage for users, trust scores, proposals, flags, parameters, owner, pause status.
 * 3. Structs & Enums: Data structures for User Profiles, Proposals, Flags, and their states.
 * 4. Events: Notifications for key actions and state changes.
 * 5. Modifiers: Access control and custom checks.
 * 6. User Management: Registration, profile updates, viewing user data.
 * 7. Trust & Reputation: Core logic for calculating and updating Trust Scores.
 * 8. Proposal System: Creation, weighted voting, finalization, result submission.
 * 9. Flag System: Reporting users, weighted voting on flags, finalization.
 * 10. Parameter Management: Admin functions to set system constants.
 * 11. Utility/View Functions: Getters for various states and data.
 * 12. Administrative Functions: Owner-only actions.
 */

/**
 * @notice Function Summary:
 * 1.  `constructor()`: Initializes the contract, sets owner and initial parameters.
 * 2.  `registerUser(string calldata _name, string calldata _profileURI)`: Registers a user with a profile and initial trust score.
 * 3.  `updateUserProfile(string calldata _name, string calldata _profileURI)`: Updates a user's profile details.
 * 4.  `getUserProfile(address _user)`: Views a user's profile.
 * 5.  `getTrustScore(address _user)`: Views a user's trust score.
 * 6.  `vouchForUser(address _user)`: Increases target user's score based on vouchee's score.
 * 7.  `proposeProject(string calldata _title, string calldata _descriptionURI, uint256 _durationBlocks)`: Creates a project proposal (requires min trust).
 * 8.  `voteOnProposal(uint256 _proposalId, bool _support)`: Casts a weighted vote on a proposal.
 * 9.  `finalizeProposal(uint256 _proposalId)`: Finalizes proposal outcome based on weighted votes.
 * 10. `submitProposalResult(uint256 _proposalId, bool _success)`: Reports proposal outcome, affecting proposer's score.
 * 11. `getProposalDetails(uint256 _proposalId)`: Views proposal details.
 * 12. `reportUser(address _user, string calldata _reasonURI)`: Flags a user for review.
 * 13. `voteOnFlag(uint256 _flagId, bool _support)`: Casts a weighted vote on a flag's validity.
 * 14. `finalizeFlagVote(uint256 _flagId)`: Finalizes flag outcome, affecting reporter/reported scores.
 * 15. `getFlagDetails(uint256 _flagId)`: Views flag details.
 * 16. `getUserState(address _user)`: Views a user's state.
 * 17. `getTotalRegisteredUsers()`: Views total registered users count.
 * 18. `getTotalProposals()`: Views total proposals count.
 * 19. `getTotalFlags()`: Views total flags count.
 * 20. `setMinimumTrustForProposal(uint256 _score)`: Admin: Sets minimum trust for proposals.
 * 21. `setVotingPeriodBlocks(uint256 _blocks)`: Admin: Sets proposal/flag voting duration.
 * 22. `setInitialTrustScore(uint256 _score)`: Admin: Sets initial registration trust score.
 * 23. `setTrustGainOnVouch(uint256 _gainBasisPoints)`: Admin: Sets vouch gain percentage.
 * 24. `setTrustChangeOnProposalResult(uint256 _successGainBasisPoints, uint256 _failureLossBasisPoints)`: Admin: Sets proposal outcome score changes.
 * 25. `setTrustChangeOnFlagVote(uint256 _flaggedLossBasisPoints, uint256 _reporterGainOnValidBasisPoints, uint256 _reporterLossOnInvalidBasisPoints)`: Admin: Sets flag outcome score changes.
 * 26. `setRegistrationFee(uint256 _fee)`: Admin: Sets registration fee.
 * 27. `withdrawAdminFees()`: Admin: Withdraws collected fees.
 * 28. `pauseContract()`: Admin: Pauses critical functions.
 * 29. `unpauseContract()`: Admin: Unpauses contract.
 * 30. `getUserProposals(address _user)`: Views proposal IDs by a user.
 */

contract DecentralizedTrustAndCollaborationEngine {

    address public owner;
    bool public paused;

    // --- State Variables ---

    enum UserState { Unregistered, Registered, Flagged, Frozen } // Frozen could be for extremely low trust
    enum ProposalState { ActiveVoting, FinalizedAccepted, FinalizedRejected, CompletedSuccess, CompletedFailed, Expired }
    enum FlagState { ActiveVoting, FinalizedValid, FinalizedInvalid, Expired }

    struct UserProfile {
        string name;
        string profileURI; // URI to off-chain metadata/profile
        UserState state;
        uint256 registrationBlock;
    }

    struct Proposal {
        address proposer;
        string title;
        string descriptionURI; // URI to off-chain proposal details
        ProposalState state;
        uint256 creationBlock;
        uint256 votingEndBlock;
        uint256 yesWeightedVotes;
        uint256 noWeightedVotes;
        mapping(address => bool) hasVoted; // Record if a user has voted
        uint256 durationBlocks; // Duration of the project if accepted
    }

    struct Flag {
        address reporter;
        address reportedUser;
        string reasonURI; // URI to off-chain details about the report
        FlagState state;
        uint256 creationBlock;
        uint256 votingEndBlock;
        uint256 yesWeightedVotes; // Votes for the flag being valid
        uint256 noWeightedVotes;  // Votes against the flag being valid
        mapping(address => bool) hasVoted; // Record if a user has voted
    }

    mapping(address => UserProfile) public users;
    mapping(address => uint256) public trustScores;
    mapping(address => bool) private _isRegistered; // Efficient check

    mapping(uint256 => Proposal) public proposals;
    uint256 public totalProposals;

    mapping(uint256 => Flag) public flags;
    uint256 public totalFlags;

    uint256 public totalRegisteredUsers;

    // Parameters (Admin adjustable)
    uint256 public minTrustForProposal;
    uint256 public votingPeriodBlocks;
    uint256 public initialTrustScore;
    uint256 public trustGainOnVouchBasisPoints; // 10000 basis points = 100%
    uint256 public trustChangeOnProposalSuccessBasisPoints;
    uint256 public trustChangeOnProposalFailureBasisPoints;
    uint256 public trustChangeOnFlaggedLossBasisPoints;
    uint256 public trustChangeOnReporterGainOnValidBasisPoints;
    uint256 public trustChangeOnReporterLossOnInvalidBasisPoints;
    uint256 public registrationFee;

    uint256 private constant BASIS_POINTS_DIVISOR = 10000;

    // Collected fees (if any)
    uint256 public collectedFees;

    // --- Events ---

    event UserRegistered(address indexed user, string name, uint256 initialScore);
    event UserProfileUpdated(address indexed user, string name, string profileURI);
    event TrustScoreUpdated(address indexed user, uint256 newScore, string reason);
    event UserStateChanged(address indexed user, UserState newState, string reason);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 votingEndBlock);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, uint256 weightedVote, bool support);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState finalState, uint256 yesVotes, uint256 noVotes);
    event ProposalResultSubmitted(uint256 indexed proposalId, address indexed submitter, bool success, uint256 scoreChange);

    event UserReported(uint256 indexed flagId, address indexed reporter, address indexed reportedUser, uint256 votingEndBlock);
    event VotedOnFlag(uint256 indexed flagId, address indexed voter, uint256 weightedVote, bool support);
    event FlagFinalized(uint256 indexed flagId, FlagState finalState, uint256 yesVotes, uint256 noVotes, uint256 reportedUserScoreChange, uint256 reporterScoreChange);

    event ParametersUpdated(string paramName, uint256 newValue);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event FeesWithdrawn(address indexed recipient, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier isRegistered(address _user) {
        require(_isRegistered[_user], "User is not registered");
        _;
    }

    modifier hasMinTrustForProposal() {
        require(trustScores[msg.sender] >= minTrustForProposal, "Insufficient trust score to propose");
        _;
    }

    // --- Constructor ---

    constructor(
        uint256 _initialTrustScore,
        uint256 _minTrustForProposal,
        uint256 _votingPeriodBlocks,
        uint256 _trustGainOnVouchBasisPoints,
        uint256 _trustChangeOnProposalSuccessBasisPoints,
        uint256 _trustChangeOnProposalFailureBasisPoints,
        uint256 _trustChangeOnFlaggedLossBasisPoints,
        uint256 _trustChangeOnReporterGainOnValidBasisPoints,
        uint256 _trustChangeOnReporterLossOnInvalidBasisPoints,
        uint256 _registrationFee
    ) {
        owner = msg.sender;
        paused = false;

        initialTrustScore = _initialTrustScore;
        minTrustForProposal = _minTrustForProposal;
        votingPeriodBlocks = _votingPeriodBlocks;
        trustGainOnVouchBasisPoints = _trustGainOnVouchBasisPoints;
        trustChangeOnProposalSuccessBasisPoints = _trustChangeOnProposalSuccessBasisPoints;
        trustChangeOnProposalFailureBasisPoints = _trustChangeOnProposalFailureBasisPoints;
        trustChangeOnFlaggedLossBasisPoints = _trustChangeOnFlaggedLossBasisPoints;
        trustChangeOnReporterGainOnValidBasisPoints = _trustChangeOnReporterGainOnValidBasisPoints;
        trustChangeOnReporterLossOnInvalidBasisPoints = _trustChangeOnReporterLossOnInvalidBasisPoints;
        registrationFee = _registrationFee;

        totalProposals = 0;
        totalFlags = 0;
        totalRegisteredUsers = 0;
        collectedFees = 0;
    }

    // --- User Management (Functions 2-5, 16, 17) ---

    /**
     * @notice Registers a new user in the system. Requires a registration fee.
     * @param _name The user's chosen name.
     * @param _profileURI URI pointing to off-chain profile metadata.
     */
    function registerUser(string calldata _name, string calldata _profileURI) external payable whenNotPaused {
        require(!_isRegistered[msg.sender], "User is already registered");
        require(msg.value >= registrationFee, "Insufficient registration fee");

        if (msg.value > registrationFee) {
            // Refund excess ETH
            (bool success, ) = msg.sender.call{value: msg.value - registrationFee}("");
            require(success, "Failed to refund excess fee");
        }

        collectedFees += registrationFee; // Collect the exact fee

        users[msg.sender] = UserProfile({
            name: _name,
            profileURI: _profileURI,
            state: UserState.Registered,
            registrationBlock: block.number
        });
        trustScores[msg.sender] = initialTrustScore;
        _isRegistered[msg.sender] = true;
        totalRegisteredUsers++;

        emit UserRegistered(msg.sender, _name, initialTrustScore);
        emit TrustScoreUpdated(msg.sender, initialTrustScore, "Initial registration");
    }

    /**
     * @notice Updates the profile details of the registered user.
     * @param _name The new name.
     * @param _profileURI The new profile URI.
     */
    function updateUserProfile(string calldata _name, string calldata _profileURI) external whenNotPaused isRegistered(msg.sender) {
        UserProfile storage user = users[msg.sender];
        user.name = _name;
        user.profileURI = _profileURI;
        emit UserProfileUpdated(msg.sender, _name, _profileURI);
    }

    /**
     * @notice Gets the profile details for a user.
     * @param _user The address of the user.
     * @return name, profileURI, state, registrationBlock
     */
    function getUserProfile(address _user) external view isRegistered(_user) returns (string memory name, string memory profileURI, UserState state, uint256 registrationBlock) {
        UserProfile storage user = users[_user];
        return (user.name, user.profileURI, user.state, user.registrationBlock);
    }

    /**
     * @notice Gets the trust score for a user.
     * @param _user The address of the user.
     * @return The trust score. Returns 0 if unregistered.
     */
    function getTrustScore(address _user) external view returns (uint256) {
        return trustScores[_user]; // Returns 0 for unregistered, which is fine
    }

     /**
     * @notice Gets the current state of a user.
     * @param _user The address of the user.
     * @return The UserState. Returns Unregistered if not found.
     */
    function getUserState(address _user) external view returns (UserState) {
         if (!_isRegistered[_user]) {
             return UserState.Unregistered;
         }
         return users[_user].state;
    }

     /**
     * @notice Gets the total number of registered users.
     * @return The total count.
     */
    function getTotalRegisteredUsers() external view returns (uint256) {
        return totalRegisteredUsers;
    }


    // --- Trust & Reputation (Function 6) ---

    /**
     * @notice Allows a registered user to vouch for another registered user.
     *         Increases the vouchee's trust score based on the vouchee's current score.
     *         Vouching is a positive signal in the network.
     * @param _user The address of the user being vouched for.
     */
    function vouchForUser(address _user) external whenNotPaused isRegistered(msg.sender) isRegistered(_user) {
        require(msg.sender != _user, "Cannot vouch for yourself");
        // A simple trust gain: add a percentage of the _user's current score.
        // This encourages vouching for established users, adding more weight.
        // Could add logic to prevent multiple vouches from the same person,
        // but keeping it simple for function count.
        uint256 currentScore = trustScores[_user];
        uint256 gain = (currentScore * trustGainOnVouchBasisPoints) / BASIS_POINTS_DIVISOR;
        // Ensure minimum gain even if score is low
        if (gain == 0 && trustGainOnVouchBasisPoints > 0) {
            gain = 1; // Minimum gain of 1 point
        }
        trustScores[_user] += gain;
        emit TrustScoreUpdated(_user, trustScores[_user], "Vouched for by " + users[msg.sender].name);
    }


    // --- Proposal System (Functions 7-11, 18, 30) ---

    /**
     * @notice Creates a new project proposal. Requires minimum trust score.
     * @param _title The title of the proposal.
     * @param _descriptionURI URI pointing to off-chain proposal details.
     * @param _durationBlocks The intended duration of the project if accepted.
     */
    function proposeProject(string calldata _title, string calldata _descriptionURI, uint256 _durationBlocks)
        external whenNotPaused isRegistered(msg.sender) hasMinTrustForProposal
    {
        totalProposals++;
        uint256 proposalId = totalProposals;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            title: _title,
            descriptionURI: _descriptionURI,
            state: ProposalState.ActiveVoting,
            creationBlock: block.number,
            votingEndBlock: block.number + votingPeriodBlocks,
            yesWeightedVotes: 0,
            noWeightedVotes: 0,
            hasVoted: new mapping(address => bool), // Initialize new mapping instance
            durationBlocks: _durationBlocks
        });

        emit ProposalCreated(proposalId, msg.sender, _title, proposals[proposalId].votingEndBlock);
    }

    /**
     * @notice Allows a registered user to cast a weighted vote on an active proposal.
     *         Weight is the voter's current Trust Score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'Yes', False for 'No'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused isRegistered(msg.sender) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.ActiveVoting, "Proposal is not in active voting state");
        require(block.number <= proposal.votingEndBlock, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "User has already voted on this proposal");

        uint256 voterTrustScore = trustScores[msg.sender];
        require(voterTrustScore > 0, "Voter must have a positive trust score");

        if (_support) {
            proposal.yesWeightedVotes += voterTrustScore;
        } else {
            proposal.noWeightedVotes += voterTrustScore;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, voterTrustScore, _support);
    }

    /**
     * @notice Finalizes a proposal after its voting period ends.
     *         Determines the outcome based on total weighted votes (Yes vs No).
     *         Updates the proposal state.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.ActiveVoting, "Proposal is not in active voting state");
        require(block.number > proposal.votingEndBlock, "Voting period has not ended yet");

        ProposalState finalState;
        if (proposal.yesWeightedVotes > proposal.noWeightedVotes) {
            finalState = ProposalState.FinalizedAccepted;
        } else if (proposal.yesWeightedVotes < proposal.noWeightedVotes) {
             finalState = ProposalState.FinalizedRejected;
        } else {
             // Tie or zero votes. Let's make ties reject.
            finalState = ProposalState.FinalizedRejected;
        }

        proposal.state = finalState;

        emit ProposalFinalized(_proposalId, finalState, proposal.yesWeightedVotes, proposal.noWeightedVotes);
    }

    /**
     * @notice Allows the original proposer (or system) to submit the simulated outcome
     *         of a project that was previously accepted. This impacts the proposer's
     *         trust score based on success or failure.
     * @param _proposalId The ID of the completed proposal.
     * @param _success True if the project was completed successfully, False otherwise.
     */
    function submitProposalResult(uint256 _proposalId, bool _success) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.FinalizedAccepted, "Proposal is not in FinalizedAccepted state");
        // Add time check? e.g., require(block.number > proposal.votingEndBlock + proposal.durationBlocks)
        // For simplicity, let's allow submission any time after acceptance for this example.
        require(msg.sender == proposal.proposer, "Only the proposer can submit the result");
        isRegistered(msg.sender); // Ensure proposer is still registered

        uint256 scoreChange = 0;
        string memory reason;
        if (_success) {
            proposal.state = ProposalState.CompletedSuccess;
            scoreChange = (trustScores[msg.sender] * trustChangeOnProposalSuccessBasisPoints) / BASIS_POINTS_DIVISOR;
            trustScores[msg.sender] += scoreChange;
            reason = "Completed proposal successfully";
        } else {
            proposal.state = ProposalState.CompletedFailed;
            scoreChange = (trustScores[msg.sender] * trustChangeOnProposalFailureBasisPoints) / BASIS_POINTS_DIVISOR;
            // Prevent score going below 0 (or a minimum threshold)
            trustScores[msg.sender] = trustScores[msg.sender] > scoreChange ? trustScores[msg.sender] - scoreChange : 0;
            reason = "Proposal completion failed";
        }

        emit ProposalResultSubmitted(_proposalId, msg.sender, _success, scoreChange);
        emit TrustScoreUpdated(msg.sender, trustScores[msg.sender], reason);
    }


    /**
     * @notice Gets the details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposer, title, descriptionURI, state, creationBlock, votingEndBlock, yesWeightedVotes, noWeightedVotes, durationBlocks
     */
    function getProposalDetails(uint256 _proposalId) external view returns (address proposer, string memory title, string memory descriptionURI, ProposalState state, uint256 creationBlock, uint256 votingEndBlock, uint256 yesWeightedVotes, uint256 noWeightedVotes, uint256 durationBlocks) {
         Proposal storage proposal = proposals[_proposalId];
         require(proposal.proposer != address(0), "Proposal does not exist");
         return (proposal.proposer, proposal.title, proposal.descriptionURI, proposal.state, proposal.creationBlock, proposal.votingEndBlock, proposal.yesWeightedVotes, proposal.noWeightedVotes, proposal.durationBlocks);
    }

    /**
     * @notice Gets the total number of proposals created.
     * @return The total count.
     */
    function getTotalProposals() external view returns (uint256) {
        return totalProposals;
    }

    /**
     * @notice Gets a list of proposal IDs submitted by a user.
     * @dev This requires iterating through all proposals, which can be gas intensive
     *      for a large number of proposals. In a production system, a mapping
     *      `mapping(address => uint256[]) userProposals` might be maintained.
     *      Keeping it simple iteration here to fulfill the function count.
     * @param _user The address of the user.
     * @return An array of proposal IDs.
     */
    function getUserProposals(address _user) external view returns (uint256[] memory) {
        uint256[] memory userProposalsList = new uint256[](totalProposals);
        uint256 count = 0;
        for (uint256 i = 1; i <= totalProposals; i++) {
            if (proposals[i].proposer == _user) {
                userProposalsList[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of proposals found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userProposalsList[i];
        }
        return result;
    }


    // --- Flag System (Functions 12-15, 19) ---

    /**
     * @notice Allows a registered user to report another registered user.
     *         Creates a flag that the community can vote on.
     * @param _user The address of the user being reported.
     * @param _reasonURI URI pointing to off-chain details about the report.
     */
    function reportUser(address _user, string calldata _reasonURI) external whenNotPaused isRegistered(msg.sender) isRegistered(_user) {
        require(msg.sender != _user, "Cannot report yourself");
        // Could add checks for cooldowns, min trust to report, etc.
        // Could also change reported user's state to Flagged immediately or after vote.
        // Let's change state only after flag is finalized.

        totalFlags++;
        uint256 flagId = totalFlags;

        flags[flagId] = Flag({
            reporter: msg.sender,
            reportedUser: _user,
            reasonURI: _reasonURI,
            state: FlagState.ActiveVoting,
            creationBlock: block.number,
            votingEndBlock: block.number + votingPeriodBlocks,
            yesWeightedVotes: 0,
            noWeightedVotes: 0,
            hasVoted: new mapping(address => bool) // Initialize new mapping instance
        });

        emit UserReported(flagId, msg.sender, _user, flags[flagId].votingEndBlock);
    }

    /**
     * @notice Allows a registered user to cast a weighted vote on an active flag.
     *         Vote 'Yes' if the flag/report is considered valid, 'No' if invalid.
     *         Weight is the voter's current Trust Score.
     * @param _flagId The ID of the flag to vote on.
     * @param _support True for 'Valid', False for 'Invalid'.
     */
    function voteOnFlag(uint256 _flagId, bool _support) external whenNotPaused isRegistered(msg.sender) {
        Flag storage flag = flags[_flagId];
        require(flag.reporter != address(0), "Flag does not exist");
        require(flag.state == FlagState.ActiveVoting, "Flag is not in active voting state");
        require(block.number <= flag.votingEndBlock, "Voting period has ended");
        require(!flag.hasVoted[msg.sender], "User has already voted on this flag");
        require(msg.sender != flag.reporter, "Reporter cannot vote on their own flag"); // Optional, but good practice
        require(msg.sender != flag.reportedUser, "Reported user cannot vote on their own flag"); // Optional

        uint256 voterTrustScore = trustScores[msg.sender];
        require(voterTrustScore > 0, "Voter must have a positive trust score");

        if (_support) {
            flag.yesWeightedVotes += voterTrustScore; // Voting that the flag IS valid
        } else {
            flag.noWeightedVotes += voterTrustScore;  // Voting that the flag IS NOT valid
        }
        flag.hasVoted[msg.sender] = true;

        emit VotedOnFlag(_flagId, msg.sender, voterTrustScore, _support);
    }

    /**
     * @notice Finalizes a flag after its voting period ends.
     *         Determines if the flag is valid or invalid based on weighted votes.
     *         Adjusts trust scores of the reported user and reporter accordingly.
     * @param _flagId The ID of the flag to finalize.
     */
    function finalizeFlagVote(uint256 _flagId) external whenNotPaused {
        Flag storage flag = flags[_flagId];
        require(flag.reporter != address(0), "Flag does not exist");
        require(flag.state == FlagState.ActiveVoting, "Flag is not in active voting state");
        require(block.number > flag.votingEndBlock, "Voting period has not ended yet");

        FlagState finalState;
        uint256 reportedUserScoreChange = 0;
        uint256 reporterScoreChange = 0;
        string memory reportedUserReason;
        string memory reporterReason;

        if (flag.yesWeightedVotes > flag.noWeightedVotes) {
            // Flag is considered Valid
            finalState = FlagState.FinalizedValid;
            // Reported user loses score
            reportedUserScoreChange = (trustScores[flag.reportedUser] * trustChangeOnFlaggedLossBasisPoints) / BASIS_POINTS_DIVISOR;
            trustScores[flag.reportedUser] = trustScores[flag.reportedUser] > reportedUserScoreChange ? trustScores[flag.reportedUser] - reportedUserScoreChange : 0;
            reportedUserReason = "Flagged as valid by community vote";
            users[flag.reportedUser].state = UserState.Flagged; // Change state

            // Reporter might gain score for a valid flag
            reporterScoreChange = (trustScores[flag.reporter] * trustChangeOnReporterGainOnValidBasisPoints) / BASIS_POINTS_DIVISOR;
             trustScores[flag.reporter] += reporterScoreChange;
            reporterReason = "Report confirmed as valid by community vote";

        } else {
            // Flag is considered Invalid (or tie)
            finalState = FlagState.FinalizedInvalid;
            // Reporter loses score for invalid flag
            reporterScoreChange = (trustScores[flag.reporter] * trustChangeOnReporterLossOnInvalidBasisPoints) / BASIS_POINTS_DIVISOR;
            trustScores[flag.reporter] = trustScores[flag.reporter] > reporterScoreChange ? trustScores[flag.reporter] - reporterScoreChange : 0;
            reporterReason = "Report deemed invalid by community vote";
            // Reported user state remains unchanged or could reset if it was Flagged pre-vote
            // For now, let's leave reported user state as is if it wasn't Flagged during vote.
            // If it was Flagged temporarily, we'd need more complex state management.
            // Simple: State only changes to Flagged on VALID finalization.
        }

        flag.state = finalState;

        emit FlagFinalized(_flagId, finalState, flag.yesWeightedVotes, flag.noWeightedVotes, reportedUserScoreChange, reporterScoreChange);
        if (reportedUserScoreChange > 0) {
             emit TrustScoreUpdated(flag.reportedUser, trustScores[flag.reportedUser], reportedUserReason);
             emit UserStateChanged(flag.reportedUser, users[flag.reportedUser].state, reportedUserReason);
        }
        if (reporterScoreChange > 0) {
             emit TrustScoreUpdated(flag.reporter, trustScores[flag.reporter], reporterReason);
        }
    }

    /**
     * @notice Gets the details of a specific flag.
     * @param _flagId The ID of the flag.
     * @return reporter, reportedUser, reasonURI, state, creationBlock, votingEndBlock, yesWeightedVotes, noWeightedVotes
     */
    function getFlagDetails(uint256 _flagId) external view returns (address reporter, address reportedUser, string memory reasonURI, FlagState state, uint256 creationBlock, uint256 votingEndBlock, uint256 yesWeightedVotes, uint256 noWeightedVotes) {
         Flag storage flag = flags[_flagId];
         require(flag.reporter != address(0), "Flag does not exist");
         return (flag.reporter, flag.reportedUser, flag.reasonURI, flag.state, flag.creationBlock, flag.votingEndBlock, flag.yesWeightedVotes, flag.noWeightedVotes);
    }

     /**
     * @notice Gets the total number of flags created.
     * @return The total count.
     */
    function getTotalFlags() external view returns (uint256) {
        return totalFlags;
    }

    // --- Parameter Management (Functions 20-26) ---

    /**
     * @notice Sets the minimum trust score required to create a proposal.
     * @param _score The new minimum trust score.
     */
    function setMinimumTrustForProposal(uint256 _score) external onlyOwner {
        minTrustForProposal = _score;
        emit ParametersUpdated("minTrustForProposal", _score);
    }

    /**
     * @notice Sets the duration (in blocks) for proposal and flag voting periods.
     * @param _blocks The new voting period in blocks.
     */
    function setVotingPeriodBlocks(uint256 _blocks) external onlyOwner {
        votingPeriodBlocks = _blocks;
        emit ParametersUpdated("votingPeriodBlocks", _blocks);
    }

    /**
     * @notice Sets the initial trust score assigned to new registered users.
     * @param _score The new initial trust score.
     */
    function setInitialTrustScore(uint256 _score) external onlyOwner {
        initialTrustScore = _score;
        emit ParametersUpdated("initialTrustScore", _score);
    }

    /**
     * @notice Sets the percentage gain (in basis points) for a vouchee's score when vouched for.
     * @param _gainBasisPoints The new percentage gain (e.g., 100 for 1%).
     */
    function setTrustGainOnVouch(uint256 _gainBasisPoints) external onlyOwner {
        trustGainOnVouchBasisPoints = _gainBasisPoints;
        emit ParametersUpdated("trustGainOnVouchBasisPoints", _gainBasisPoints);
    }

    /**
     * @notice Sets the percentage score changes (in basis points) for proposers based on project outcome.
     * @param _successGainBasisPoints Gain for success.
     * @param _failureLossBasisPoints Loss for failure.
     */
    function setTrustChangeOnProposalResult(uint256 _successGainBasisPoints, uint256 _failureLossBasisPoints) external onlyOwner {
        trustChangeOnProposalSuccessBasisPoints = _successGainBasisPoints;
        trustChangeOnProposalFailureBasisPoints = _failureLossBasisPoints;
        emit ParametersUpdated("trustChangeOnProposalSuccessBasisPoints", _successGainBasisPoints);
        emit ParametersUpdated("trustChangeOnProposalFailureBasisPoints", _failureLossBasisPoints);
    }

    /**
     * @notice Sets the percentage score changes (in basis points) based on flag vote outcomes.
     * @param _flaggedLossBasisPoints Loss for reported user if flag is valid.
     * @param _reporterGainOnValidBasisPoints Gain for reporter if flag is valid.
     * @param _reporterLossOnInvalidBasisPoints Loss for reporter if flag is invalid.
     */
    function setTrustChangeOnFlagVote(uint256 _flaggedLossBasisPoints, uint256 _reporterGainOnValidBasisPoints, uint256 _reporterLossOnInvalidBasisPoints) external onlyOwner {
        trustChangeOnFlaggedLossBasisPoints = _flaggedLossBasisPoints;
        trustChangeOnReporterGainOnValidBasisPoints = _reporterGainOnValidBasisPoints;
        trustChangeOnReporterLossOnInvalidBasisPoints = _reporterLossOnInvalidBasisPoints;
        emit ParametersUpdated("trustChangeOnFlaggedLossBasisPoints", _flaggedLossBasisPoints);
        emit ParametersUpdated("trustChangeOnReporterGainOnValidBasisPoints", _reporterGainOnValidBasisPoints);
        emit ParametersUpdated("trustChangeOnReporterLossOnInvalidBasisPoints", _reporterLossOnInvalidBasisPoints);
    }

     /**
     * @notice Sets the fee required for user registration.
     * @param _fee The new registration fee in wei.
     */
    function setRegistrationFee(uint256 _fee) external onlyOwner {
        registrationFee = _fee;
        emit ParametersUpdated("registrationFee", _fee);
    }

    // --- Administrative Functions (Functions 27-29) ---

    /**
     * @notice Allows the owner to withdraw accumulated registration fees.
     */
    function withdrawAdminFees() external onlyOwner {
        require(collectedFees > 0, "No fees collected");
        uint256 amount = collectedFees;
        collectedFees = 0;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner, amount);
    }

    /**
     * @notice Pauses the contract, preventing most state-changing operations.
     */
    function pauseContract() external onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing operations again.
     */
    function unpauseContract() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }
}
```