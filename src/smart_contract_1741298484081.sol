```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling artists to submit artwork,
 *      community members to curate and vote on art, and manage a shared art collection and treasury.
 *
 * **Outline:**
 *
 * **1. Core Data Structures:**
 *    - `ArtProposal`: Struct to hold art submission details (artist, description, IPFS hash, submission timestamp, status, votes).
 *    - `Exhibition`: Struct to represent an art exhibition (name, curator, start/end dates, list of art IDs, status).
 *    - `ArtistProfile`: Struct to store artist-specific data (name, description, portfolio link).
 *    - `UserProfile`: Struct for community members (reputation score, staked amount).
 *
 * **2. State Variables:**
 *    - `owner`: Contract owner address.
 *    - `artProposals`: Mapping of proposal ID to `ArtProposal`.
 *    - `exhibitions`: Mapping of exhibition ID to `Exhibition`.
 *    - `artists`: Mapping of artist address to `ArtistProfile`.
 *    - `users`: Mapping of user address to `UserProfile`.
 *    - `treasuryBalance`: Contract's ETH balance (managed internally).
 *    - `proposalCounter`: Incremental counter for art proposals.
 *    - `exhibitionCounter`: Incremental counter for exhibitions.
 *    - `minStakeForVoting`: Minimum stake required to vote.
 *    - `votingDuration`: Default voting duration for proposals.
 *    - `curationThreshold`: Percentage of votes needed to approve an art proposal.
 *    - `exhibitionVoteThreshold`: Percentage of votes needed to approve art for an exhibition.
 *    - `feedbackVoteThreshold`: Percentage of votes needed to approve community feedback.
 *    - `artistRewardPercentage`: Percentage of sales revenue to artist.
 *    - `collectiveRewardPercentage`: Percentage of sales revenue to collective treasury.
 *    - `platformFeePercentage`: Percentage of sales revenue as platform fee.
 *    - `paused`: Boolean to pause/unpause contract functionalities.
 *
 * **3. Modifiers:**
 *    - `onlyOwner`: Restricts function access to the contract owner.
 *    - `whenNotPaused`: Ensures function execution only when the contract is not paused.
 *    - `whenPaused`: Ensures function execution only when the contract is paused.
 *    - `minStakeRequired`: Ensures caller has minimum stake.
 *
 * **4. Events:**
 *    - `ArtProposalSubmitted`: Emitted when a new art proposal is submitted.
 *    - `ArtProposalVoted`: Emitted when a vote is cast on an art proposal.
 *    - `ArtProposalApproved`: Emitted when an art proposal is approved.
 *    - `ArtProposalRejected`: Emitted when an art proposal is rejected.
 *    - `ExhibitionCreated`: Emitted when a new exhibition is created.
 *    - `ArtAddedToExhibition`: Emitted when art is added to an exhibition.
 *    - `ExhibitionStarted`: Emitted when an exhibition starts.
 *    - `ExhibitionEnded`: Emitted when an exhibition ends.
 *    - `ArtistProfileCreated`: Emitted when an artist profile is created.
 *    - `ArtistProfileUpdated`: Emitted when an artist profile is updated.
 *    - `StakeDeposited`: Emitted when a user deposits stake.
 *    - `StakeWithdrawn`: Emitted when a user withdraws stake.
 *    - `FeedbackProvided`: Emitted when community feedback is provided.
 *    - `FeedbackApproved`: Emitted when community feedback is approved.
 *    - `ParameterChanged`: Emitted when a contract parameter is changed by the owner.
 *    - `ContractPaused`: Emitted when the contract is paused.
 *    - `ContractUnpaused`: Emitted when the contract is unpaused.
 *    - `FundsWithdrawn`: Emitted when funds are withdrawn from the treasury.
 *    - `ArtistRewarded`: Emitted when an artist receives a reward.
 *    - `TreasuryFunded`: Emitted when the treasury receives funds.
 *
 * **5. Functions (Summary):**
 *
 *    **a) Core Functionality (Art Submission & Curation):**
 *       - `submitArtProposal(string memory _description, string memory _ipfsHash)`: Artists submit art proposals.
 *       - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Community members vote on art proposals.
 *       - `getArtProposalDetails(uint256 _proposalId)`: View function to retrieve art proposal details.
 *       - `approveArtProposal(uint256 _proposalId)`: Owner function to manually approve (in case of tie or emergency).
 *       - `rejectArtProposal(uint256 _proposalId)`: Owner function to manually reject (in case of malicious content).
 *
 *    **b) Exhibition Management:**
 *       - `createExhibition(string memory _name, address _curator, uint256 _startDate, uint256 _endDate)`: Create a new art exhibition.
 *       - `addArtToExhibition(uint256 _exhibitionId, uint256 _artProposalId)`: Add approved art to an exhibition (curator or owner).
 *       - `startExhibition(uint256 _exhibitionId)`: Start an exhibition (curator or owner).
 *       - `endExhibition(uint256 _exhibitionId)`: End an exhibition (curator or owner).
 *       - `getExhibitionDetails(uint256 _exhibitionId)`: View function to retrieve exhibition details.
 *
 *    **c) Artist & Community Profiles:**
 *       - `createArtistProfile(string memory _name, string memory _description, string memory _portfolioLink)`: Artists create their profiles.
 *       - `updateArtistProfile(string memory _name, string memory _description, string memory _portfolioLink)`: Artists update their profiles.
 *       - `getArtistProfile(address _artistAddress)`: View function to retrieve artist profile.
 *       - `stakeForReputation()`: Community members stake ETH to gain reputation and voting power.
 *       - `withdrawStake(uint256 _amount)`: Community members withdraw their staked ETH.
 *       - `getUserProfile(address _userAddress)`: View function to retrieve user profile (stake, reputation).
 *
 *    **d) Community Feedback & Governance:**
 *       - `provideArtFeedback(uint256 _artProposalId, string memory _feedbackText)`: Community members provide feedback on art proposals.
 *       - `voteOnFeedback(uint256 _feedbackId, bool _vote)`: Community votes on feedback (optional, for feedback curation).
 *       - `proposeParameterChange(string memory _parameterName, uint256 _newValue)`: Owner function to propose changes to contract parameters (e.g., voting duration).
 *
 *    **e) Treasury & Revenue Management (Conceptual -  Sales logic would be external/NFT integration):**
 *       - `depositFunds()`: Allow external entities to deposit funds into the treasury (e.g., from NFT sales - conceptual).
 *       - `withdrawFunds(uint256 _amount)`: Owner function to withdraw funds from the treasury (for platform maintenance, artist rewards, etc.).
 *       - `distributeArtistReward(uint256 _artistRewardAmount, address _artistAddress)`: Owner function to manually distribute rewards to artists from treasury.
 *
 *    **f) Utility & Admin Functions:**
 *       - `pauseContract()`: Owner function to pause the contract.
 *       - `unpauseContract()`: Owner function to unpause the contract.
 *       - `setVotingDuration(uint256 _duration)`: Owner function to set the voting duration.
 *       - `setCurationThreshold(uint256 _threshold)`: Owner function to set the curation threshold.
 *       - `setMinStakeForVoting(uint256 _minStake)`: Owner function to set the minimum stake for voting.
 *       - `getContractBalance()`: View function to get the contract's ETH balance.
 */
pragma solidity ^0.8.0;

contract DecentralizedAutonomousArtCollective {
    // --- Data Structures ---
    struct ArtProposal {
        address artist;
        string description;
        string ipfsHash;
        uint256 submissionTimestamp;
        ProposalStatus status;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) votes; // Track who voted and their vote
        string[] feedbackTexts; // Array to store feedback texts
        uint256 feedbackCounter; // Counter for feedback
        mapping(uint256 => Feedback) feedbackMap; // Map feedback ID to Feedback struct
    }

    struct Feedback {
        address sender;
        string text;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) feedbackVotes;
    }

    struct Exhibition {
        string name;
        address curator;
        uint256 startDate;
        uint256 endDate;
        uint256[] artProposalIds; // Array of approved art proposal IDs in the exhibition
        ExhibitionStatus status;
    }

    struct ArtistProfile {
        string name;
        string description;
        string portfolioLink;
        bool exists; // Flag to check if profile exists
    }

    struct UserProfile {
        uint256 stakedAmount;
        uint256 reputationScore; // Conceptual reputation score based on staking and participation
        bool exists; // Flag to check if profile exists
    }

    enum ProposalStatus { Pending, Approved, Rejected }
    enum ExhibitionStatus { Created, Active, Ended }

    // --- State Variables ---
    address public owner;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(address => ArtistProfile) public artists;
    mapping(address => UserProfile) public users;
    uint256 public treasuryBalance; // Managed internally, actual ETH balance of contract
    uint256 public proposalCounter;
    uint256 public exhibitionCounter;
    uint256 public minStakeForVoting = 1 ether; // Minimum stake to participate in voting
    uint256 public votingDuration = 7 days; // Default voting duration for proposals
    uint256 public curationThreshold = 60; // Percentage of votes needed for approval (60%)
    uint256 public exhibitionVoteThreshold = 70; // Percentage for exhibition art selection
    uint256 public feedbackVoteThreshold = 50; // Percentage for feedback approval
    uint256 public artistRewardPercentage = 70; // Percentage for artist from sales
    uint256 public collectiveRewardPercentage = 20; // Percentage for collective from sales
    uint256 public platformFeePercentage = 10; // Platform fee percentage
    bool public paused = false;

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier minStakeRequired() {
        require(users[msg.sender].stakedAmount >= minStakeForVoting, "Minimum stake required to perform this action.");
        _;
    }

    // --- Events ---
    event ArtProposalSubmitted(uint256 proposalId, address artist, string description, string ipfsHash);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId, address approver);
    event ArtProposalRejected(uint256 proposalId, address rejector);
    event ExhibitionCreated(uint256 exhibitionId, string name, address curator, uint256 startDate, uint256 endDate);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artProposalId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event ArtistProfileCreated(address artistAddress, string name);
    event ArtistProfileUpdated(address artistAddress, string name);
    event StakeDeposited(address user, uint256 amount);
    event StakeWithdrawn(address user, uint256 amount);
    event FeedbackProvided(uint256 proposalId, uint256 feedbackId, address sender, string text);
    event FeedbackApproved(uint256 proposalId, uint256 feedbackId);
    event ParameterChanged(string parameterName, uint256 newValue);
    event ContractPaused();
    event ContractUnpaused();
    event FundsWithdrawn(address recipient, uint256 amount);
    event ArtistRewarded(address artist, uint256 amount, uint256 proposalId);
    event TreasuryFunded(uint256 amount);

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        treasuryBalance = address(this).balance; // Initialize with contract's initial balance
    }

    // --- a) Core Functionality (Art Submission & Curation) ---
    /// @notice Artists submit their art proposals to the collective.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork's digital file.
    function submitArtProposal(string memory _description, string memory _ipfsHash) external whenNotPaused {
        require(artists[msg.sender].exists, "Artist profile required to submit art.");
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            artist: msg.sender,
            description: _description,
            ipfsHash: _ipfsHash,
            submissionTimestamp: block.timestamp,
            status: ProposalStatus.Pending,
            upvotes: 0,
            downvotes: 0,
            feedbackCounter: 0
        });
        emit ArtProposalSubmitted(proposalCounter, msg.sender, _description, _ipfsHash);
    }

    /// @notice Community members vote on pending art proposals.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _vote Boolean value representing the vote (true for upvote, false for downvote).
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external whenNotPaused minStakeRequired {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(!artProposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");

        artProposals[_proposalId].votes[msg.sender] = true; // Record voter

        if (_vote) {
            artProposals[_proposalId].upvotes++;
        } else {
            artProposals[_proposalId].downvotes++;
        }

        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting duration is over and threshold is reached (can be triggered by any vote after duration)
        if (block.timestamp >= artProposals[_proposalId].submissionTimestamp + votingDuration) {
            _checkAndFinalizeProposal(_proposalId);
        }
    }

    /// @dev Internal function to check proposal votes and finalize status.
    /// @param _proposalId ID of the art proposal.
    function _checkAndFinalizeProposal(uint256 _proposalId) internal {
        if (artProposals[_proposalId].status == ProposalStatus.Pending) {
            uint256 totalVotes = artProposals[_proposalId].upvotes + artProposals[_proposalId].downvotes;
            if (totalVotes > 0) {
                uint256 approvalPercentage = (artProposals[_proposalId].upvotes * 100) / totalVotes;
                if (approvalPercentage >= curationThreshold) {
                    artProposals[_proposalId].status = ProposalStatus.Approved;
                    emit ArtProposalApproved(_proposalId, address(this)); // Contract approves based on community vote
                } else {
                    artProposals[_proposalId].status = ProposalStatus.Rejected;
                    emit ArtProposalRejected(_proposalId, address(this)); // Contract rejects based on community vote
                }
            } else {
                // If no votes after duration, default to rejected (or can be configured to pending longer)
                artProposals[_proposalId].status = ProposalStatus.Rejected; // Default to rejected if no votes
                emit ArtProposalRejected(_proposalId, address(this));
            }
        }
    }


    /// @notice View function to retrieve details of a specific art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice Owner can manually approve an art proposal (e.g., in case of a tie or special circumstances).
    /// @param _proposalId ID of the art proposal to approve.
    function approveArtProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        artProposals[_proposalId].status = ProposalStatus.Approved;
        emit ArtProposalApproved(_proposalId, msg.sender);
    }

    /// @notice Owner can manually reject an art proposal (e.g., for policy violations or malicious content).
    /// @param _proposalId ID of the art proposal to reject.
    function rejectArtProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        artProposals[_proposalId].status = ProposalStatus.Rejected;
        emit ArtProposalRejected(_proposalId, msg.sender);
    }

    // --- b) Exhibition Management ---
    /// @notice Creates a new art exhibition.
    /// @param _name Name of the exhibition.
    /// @param _curator Address of the exhibition curator.
    /// @param _startDate Unix timestamp for exhibition start date.
    /// @param _endDate Unix timestamp for exhibition end date.
    function createExhibition(
        string memory _name,
        address _curator,
        uint256 _startDate,
        uint256 _endDate
    ) external whenNotPaused onlyOwner { // Only owner can create exhibitions initially, can delegate to curators later
        require(_startDate < _endDate, "Start date must be before end date.");
        exhibitionCounter++;
        exhibitions[exhibitionCounter] = Exhibition({
            name: _name,
            curator: _curator,
            startDate: _startDate,
            endDate: _endDate,
            artProposalIds: new uint256[](0), // Initialize with empty array of art proposal IDs
            status: ExhibitionStatus.Created
        });
        emit ExhibitionCreated(exhibitionCounter, _name, _curator, _startDate, _endDate);
    }

    /// @notice Add approved art proposals to an exhibition. Can be called by curator or owner.
    /// @param _exhibitionId ID of the exhibition.
    /// @param _artProposalId ID of the approved art proposal to add.
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artProposalId) external whenNotPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.Created, "Exhibition must be in 'Created' status.");
        require(artProposals[_artProposalId].status == ProposalStatus.Approved, "Art proposal must be approved.");
        require(msg.sender == exhibitions[_exhibitionId].curator || msg.sender == owner, "Only curator or owner can add art.");

        // Check if art is already in the exhibition
        bool alreadyAdded = false;
        for (uint256 i = 0; i < exhibitions[_exhibitionId].artProposalIds.length; i++) {
            if (exhibitions[_exhibitionId].artProposalIds[i] == _artProposalId) {
                alreadyAdded = true;
                break;
            }
        }
        require(!alreadyAdded, "Art proposal already added to this exhibition.");

        exhibitions[_exhibitionId].artProposalIds.push(_artProposalId);
        emit ArtAddedToExhibition(_exhibitionId, _artProposalId);
    }

    /// @notice Start an exhibition, changing its status to 'Active'.
    /// @param _exhibitionId ID of the exhibition to start.
    function startExhibition(uint256 _exhibitionId) external whenNotPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.Created, "Exhibition must be in 'Created' status.");
        require(msg.sender == exhibitions[_exhibitionId].curator || msg.sender == owner, "Only curator or owner can start exhibition.");
        exhibitions[_exhibitionId].status = ExhibitionStatus.Active;
        emit ExhibitionStarted(_exhibitionId);
    }

    /// @notice End an exhibition, changing its status to 'Ended'.
    /// @param _exhibitionId ID of the exhibition to end.
    function endExhibition(uint256 _exhibitionId) external whenNotPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.Active, "Exhibition must be in 'Active' status.");
        require(block.timestamp >= exhibitions[_exhibitionId].endDate, "Exhibition end date not reached yet.");
        require(msg.sender == exhibitions[_exhibitionId].curator || msg.sender == owner, "Only curator or owner can end exhibition.");
        exhibitions[_exhibitionId].status = ExhibitionStatus.Ended;
        emit ExhibitionEnded(_exhibitionId);
    }

    /// @notice View function to retrieve details of a specific exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @return Exhibition struct containing exhibition details.
    function getExhibitionDetails(uint256 _exhibitionId) external view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    // --- c) Artist & Community Profiles ---
    /// @notice Artists create their profiles to participate in the collective.
    /// @param _name Artist's name or pseudonym.
    /// @param _description Short description about the artist.
    /// @param _portfolioLink Link to the artist's online portfolio.
    function createArtistProfile(string memory _name, string memory _description, string memory _portfolioLink) external whenNotPaused {
        require(!artists[msg.sender].exists, "Artist profile already exists.");
        artists[msg.sender] = ArtistProfile({
            name: _name,
            description: _description,
            portfolioLink: _portfolioLink,
            exists: true
        });
        emit ArtistProfileCreated(msg.sender, _name);
    }

    /// @notice Artists update their profiles.
    /// @param _name New artist name (optional update).
    /// @param _description New artist description (optional update).
    /// @param _portfolioLink New portfolio link (optional update).
    function updateArtistProfile(string memory _name, string memory _description, string memory _portfolioLink) external whenNotPaused {
        require(artists[msg.sender].exists, "Artist profile does not exist.");
        artists[msg.sender].name = _name;
        artists[msg.sender].description = _description;
        artists[msg.sender].portfolioLink = _portfolioLink;
        emit ArtistProfileUpdated(msg.sender, _name);
    }

    /// @notice View function to retrieve an artist's profile.
    /// @param _artistAddress Address of the artist.
    /// @return ArtistProfile struct containing artist profile details.
    function getArtistProfile(address _artistAddress) external view returns (ArtistProfile memory) {
        return artists[_artistAddress];
    }

    /// @notice Community members stake ETH to gain reputation and voting power.
    function stakeForReputation() external payable whenNotPaused {
        require(msg.value > 0, "Stake amount must be greater than zero.");
        users[msg.sender].stakedAmount += msg.value;
        users[msg.sender].exists = true; // Mark user as existing if they stake
        treasuryBalance += msg.value; // Update internal treasury balance
        emit StakeDeposited(msg.sender, msg.value);
    }

    /// @notice Community members withdraw their staked ETH.
    /// @param _amount Amount of ETH to withdraw.
    function withdrawStake(uint256 _amount) external whenNotPaused {
        require(users[msg.sender].stakedAmount >= _amount, "Insufficient staked amount.");
        require(_amount > 0, "Withdraw amount must be greater than zero.");
        users[msg.sender].stakedAmount -= _amount;
        payable(msg.sender).transfer(_amount);
        treasuryBalance -= _amount; // Update internal treasury balance
        emit StakeWithdrawn(msg.sender, _amount);
    }

    /// @notice View function to get a user's profile (stake and reputation).
    /// @param _userAddress Address of the user.
    /// @return UserProfile struct containing user profile details.
    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        return users[_userAddress];
    }

    // --- d) Community Feedback & Governance ---
    /// @notice Community members provide feedback on art proposals.
    /// @param _artProposalId ID of the art proposal to provide feedback on.
    /// @param _feedbackText Textual feedback on the artwork.
    function provideArtFeedback(uint256 _artProposalId, string memory _feedbackText) external whenNotPaused minStakeRequired {
        require(artProposals[_artProposalId].status == ProposalStatus.Pending || artProposals[_artProposalId].status == ProposalStatus.Approved, "Feedback only allowed on pending or approved proposals.");
        uint256 feedbackId = artProposals[_artProposalId].feedbackCounter++;
        artProposals[_artProposalId].feedbackMap[feedbackId] = Feedback({
            sender: msg.sender,
            text: _feedbackText,
            upvotes: 0,
            downvotes: 0
        });
        emit FeedbackProvided(_artProposalId, feedbackId, msg.sender, _feedbackText);
    }


    /// @notice Community members vote on feedback (optional feature for feedback curation).
    /// @param _proposalId ID of the art proposal the feedback belongs to.
    /// @param _feedbackId ID of the feedback to vote on.
    /// @param _vote Boolean vote (true for upvote, false for downvote).
    function voteOnFeedback(uint256 _proposalId, uint256 _feedbackId, bool _vote) external whenNotPaused minStakeRequired {
        require(artProposals[_proposalId].feedbackMap[_feedbackId].sender != address(0), "Feedback does not exist.");
        require(!artProposals[_proposalId].feedbackMap[_feedbackId].feedbackVotes[msg.sender], "Already voted on this feedback.");

        artProposals[_proposalId].feedbackMap[_feedbackId].feedbackVotes[msg.sender] = true;

        if (_vote) {
            artProposals[_proposalId].feedbackMap[_feedbackId].upvotes++;
        } else {
            artProposals[_proposalId].feedbackMap[_feedbackId].downvotes++;
        }

        uint256 totalFeedbackVotes = artProposals[_proposalId].feedbackMap[_feedbackId].upvotes + artProposals[_proposalId].feedbackMap[_feedbackId].downvotes;
        if (totalFeedbackVotes > 0) {
            uint256 feedbackApprovalPercentage = (artProposals[_proposalId].feedbackMap[_feedbackId].upvotes * 100) / totalFeedbackVotes;
            if (feedbackApprovalPercentage >= feedbackVoteThreshold) {
                emit FeedbackApproved(_proposalId, _feedbackId); // Example: Can trigger actions based on approved feedback
            }
        }
    }


    /// @notice Owner can propose changes to contract parameters.
    /// @param _parameterName Name of the parameter to change (e.g., "votingDuration", "curationThreshold").
    /// @param _newValue New value for the parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyOwner whenNotPaused {
        if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("votingDuration"))) {
            votingDuration = _newValue;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("curationThreshold"))) {
            curationThreshold = _newValue;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("minStakeForVoting"))) {
            minStakeForVoting = _newValue * 1 ether; // Assuming input is in ETH units
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("exhibitionVoteThreshold"))) {
            exhibitionVoteThreshold = _newValue;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("feedbackVoteThreshold"))) {
            feedbackVoteThreshold = _newValue;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("artistRewardPercentage"))) {
            artistRewardPercentage = _newValue;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("collectiveRewardPercentage"))) {
            collectiveRewardPercentage = _newValue;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("platformFeePercentage"))) {
            platformFeePercentage = _newValue;
        } else {
            revert("Invalid parameter name.");
        }
        emit ParameterChanged(_parameterName, _newValue);
    }

    // --- e) Treasury & Revenue Management (Conceptual) ---
    /// @notice Allows external entities (e.g., NFT marketplace contract) to deposit funds into the treasury.
    function depositFunds() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        treasuryBalance += msg.value;
        emit TreasuryFunded(msg.value);
    }

    /// @notice Owner can withdraw funds from the treasury for platform operations or artist rewards.
    /// @param _amount Amount to withdraw.
    function withdrawFunds(uint256 _amount) external onlyOwner whenNotPaused {
        require(treasuryBalance >= _amount, "Insufficient treasury balance.");
        require(_amount > 0, "Withdraw amount must be greater than zero.");
        treasuryBalance -= _amount;
        payable(owner).transfer(_amount);
        emit FundsWithdrawn(owner, _amount);
    }

    /// @notice Owner function to manually distribute rewards to artists from the treasury.
    /// @param _artistRewardAmount Amount to reward the artist.
    /// @param _artistAddress Address of the artist to reward.
    /// @param _proposalId ID of the art proposal related to the reward (for tracking).
    function distributeArtistReward(uint256 _artistRewardAmount, address _artistAddress, uint256 _proposalId) external onlyOwner whenNotPaused {
        require(treasuryBalance >= _artistRewardAmount, "Insufficient treasury balance for artist reward.");
        require(_artistRewardAmount > 0, "Reward amount must be greater than zero.");
        treasuryBalance -= _artistRewardAmount;
        payable(_artistAddress).transfer(_artistRewardAmount);
        emit ArtistRewarded(_artistAddress, _artistRewardAmount, _proposalId);
    }


    // --- f) Utility & Admin Functions ---
    /// @notice Owner can pause the contract, halting critical functionalities.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Owner can unpause the contract, resuming functionalities.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Owner can set the voting duration for art proposals.
    /// @param _duration New voting duration in seconds.
    function setVotingDuration(uint256 _duration) external onlyOwner whenNotPaused {
        votingDuration = _duration;
        emit ParameterChanged("votingDuration", _duration);
    }

    /// @notice Owner can set the curation threshold for art proposal approval (percentage).
    /// @param _threshold New curation threshold percentage (e.g., 60 for 60%).
    function setCurationThreshold(uint256 _threshold) external onlyOwner whenNotPaused {
        require(_threshold <= 100, "Curation threshold must be between 0 and 100.");
        curationThreshold = _threshold;
        emit ParameterChanged("curationThreshold", _threshold);
    }

    /// @notice Owner can set the minimum stake required for voting.
    /// @param _minStake Minimum stake amount in ETH.
    function setMinStakeForVoting(uint256 _minStake) external onlyOwner whenNotPaused {
        minStakeForVoting = _minStake * 1 ether;
        emit ParameterChanged("minStakeForVoting", _minStake);
    }

    /// @notice View function to get the contract's ETH balance.
    /// @return Contract's ETH balance.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Fallback function to accept ETH deposits to the contract treasury.
    receive() external payable {
        if (msg.value > 0) {
            treasuryBalance += msg.value;
            emit TreasuryFunded(msg.value);
        }
    }
}
```