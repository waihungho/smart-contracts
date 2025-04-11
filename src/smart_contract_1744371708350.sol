```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (Example Smart Contract - Conceptual and for illustrative purposes)
 * @dev A smart contract for a Decentralized Autonomous Art Gallery, enabling artists to showcase,
 * curate, and manage digital art (represented as NFTs) in a community-governed manner.
 *
 * **Outline and Function Summary:**
 *
 * **I. Curator Management:**
 *   1. `nominateCurator(address _curator)`: Allows token holders to nominate addresses to become curators.
 *   2. `voteForCurator(address _curator)`: Token holders can vote for nominated curators.
 *   3. `revokeCuratorNomination(address _curator)`: Allows nominators to revoke their nomination.
 *   4. `removeCurator(address _curator)`:  Function to remove a curator (governance vote or admin).
 *   5. `getActiveCurators()`: Returns a list of currently active curators.
 *
 * **II. Art Submission and Management:**
 *   6. `submitArtwork(address _nftContract, uint256 _tokenId, string _metadataURI)`: Artists submit NFTs for gallery consideration.
 *   7. `approveArtwork(uint256 _submissionId)`: Curators vote to approve submitted artworks for exhibition.
 *   8. `rejectArtwork(uint256 _submissionId)`: Curators vote to reject submitted artworks.
 *   9. `getArtworkSubmissionDetails(uint256 _submissionId)`: Returns details of a specific artwork submission.
 *   10. `getAllApprovedArtworks()`: Returns a list of all approved artworks in the gallery.
 *   11. `withdrawArtwork(uint256 _submissionId)`: Artist can withdraw their submitted artwork if not yet approved.
 *
 * **III. Exhibition Management:**
 *   12. `createExhibition(string _exhibitionName, string _description, uint256 _startTime, uint256 _endTime)`: Curators can propose and create new exhibitions.
 *   13. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _submissionId)`: Curators add approved artworks to specific exhibitions.
 *   14. `removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _submissionId)`: Curators can remove artworks from exhibitions.
 *   15. `getExhibitionDetails(uint256 _exhibitionId)`: Returns details of a specific exhibition.
 *   16. `getActiveExhibitions()`: Returns a list of currently active exhibitions.
 *
 * **IV. Governance and Community Features:**
 *   17. `proposeGalleryParameterChange(string _parameterName, uint256 _newValue)`: Token holders can propose changes to gallery parameters (e.g., voting thresholds).
 *   18. `voteOnParameterChangeProposal(uint256 _proposalId, bool _vote)`: Token holders can vote on parameter change proposals.
 *   19. `executeParameterChange(uint256 _proposalId)`: Executes approved parameter change proposals.
 *   20. `donateToGallery()`: Allows anyone to donate ETH to the gallery's treasury.
 *   21. `getGalleryTreasuryBalance()`: Returns the current balance of the gallery's treasury.
 *   22. `requestTreasuryWithdrawal(uint256 _amount, address _recipient, string _reason)`: Curators can propose treasury withdrawals for gallery operations.
 *   23. `voteOnTreasuryWithdrawal(uint256 _withdrawalId, bool _vote)`: Token holders vote on treasury withdrawal requests.
 *   24. `executeTreasuryWithdrawal(uint256 _withdrawalId)`: Executes approved treasury withdrawal requests.
 *
 * **V. Utility Functions:**
 *   25. `setVotingDuration(uint256 _durationInBlocks)`: Admin function to set the default voting duration.
 *   26. `setQuorumPercentage(uint256 _percentage)`: Admin function to set the quorum percentage for votes.
 */

contract DecentralizedAutonomousArtGallery {

    // -------- State Variables --------

    // Governance Token (Example - Replace with actual token contract)
    address public governanceToken; // Address of the governance token contract

    // Curators
    mapping(address => bool) public isCurator;
    address[] public activeCurators;
    mapping(address => uint256) public curatorNominations; // Nominations count per curator
    address[] public nominatedCurators;

    // Art Submissions
    struct ArtworkSubmission {
        address artist;
        address nftContract;
        uint256 tokenId;
        string metadataURI;
        uint256 submissionTime;
        bool approved;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        address[] approvingCurators;
        address[] rejectingCurators;
        bool withdrawn;
    }
    ArtworkSubmission[] public artworkSubmissions;
    uint256 public nextSubmissionId = 0;

    // Exhibitions
    struct Exhibition {
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256[] artworkSubmissionIds; // List of artwork submission IDs in this exhibition
        bool isActive;
    }
    Exhibition[] public exhibitions;
    uint256 public nextExhibitionId = 0;

    // Voting Parameters
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 50; // Quorum percentage for votes (e.g., 50 for 50%)

    // Parameter Change Proposals
    struct ParameterChangeProposal {
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    ParameterChangeProposal[] public parameterChangeProposals;
    uint256 public nextProposalId = 0;

    // Treasury Withdrawal Requests
    struct TreasuryWithdrawalRequest {
        uint256 amount;
        address recipient;
        string reason;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    TreasuryWithdrawalRequest[] public treasuryWithdrawalRequests;
    uint256 public nextWithdrawalId = 0;


    // -------- Events --------
    event CuratorNominated(address curator, address nominator);
    event CuratorVoted(address curator, address voter, bool vote);
    event CuratorRemoved(address curator, address removedBy);
    event ArtworkSubmitted(uint256 submissionId, address artist, address nftContract, uint256 tokenId);
    event ArtworkApproved(uint256 submissionId, address curator);
    event ArtworkRejected(uint256 submissionId, address curator);
    event ArtworkWithdrawn(uint256 submissionId, address artist);
    event ExhibitionCreated(uint256 exhibitionId, string name, address creator);
    event ArtworkAddedToExhibition(uint256 exhibitionId, uint256 submissionId, address curator);
    event ArtworkRemovedFromExhibition(uint256 exhibitionId, uint256 submissionId, address curator);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event DonationReceived(address donor, uint256 amount);
    event TreasuryWithdrawalRequested(uint256 withdrawalId, uint256 amount, address recipient, string reason, address requester);
    event TreasuryWithdrawalVoted(uint256 withdrawalId, address voter, bool vote);
    event TreasuryWithdrawalExecuted(uint256 withdrawalId, uint256 amount, address recipient);


    // -------- Modifiers --------
    modifier onlyGovernanceTokenHolder() {
        require(getGovernanceTokenBalance(msg.sender) > 0, "Not a governance token holder");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Not a curator");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId < artworkSubmissions.length, "Invalid Submission ID");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(_exhibitionId < exhibitions.length, "Invalid Exhibition ID");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < parameterChangeProposals.length, "Invalid Proposal ID");
        _;
    }

    modifier validWithdrawalId(uint256 _withdrawalId) {
        require(_withdrawalId < treasuryWithdrawalRequests.length, "Invalid Withdrawal ID");
        _;
    }

    modifier votingInProgress(uint256 _endTime) {
        require(block.number <= _endTime, "Voting has ended");
        _;
    }

    modifier votingHasEnded(uint256 _endTime) {
        require(block.number > _endTime, "Voting is still in progress");
        _;
    }

    modifier notWithdrawn(uint256 _submissionId) {
        require(!artworkSubmissions[_submissionId].withdrawn, "Artwork already withdrawn");
        _;
    }


    // -------- Constructor --------
    constructor(address _governanceTokenAddress) {
        governanceToken = _governanceTokenAddress;
        // Initially, the contract deployer could be set as the first curator or admin.
        // For simplicity, we start with no curators and rely on community nomination.
    }


    // -------- I. Curator Management --------

    /**
     * @dev Allows token holders to nominate an address to become a curator.
     * @param _curator The address to be nominated as a curator.
     */
    function nominateCurator(address _curator) external onlyGovernanceTokenHolder {
        require(_curator != address(0), "Invalid curator address");
        require(!isCurator[_curator], "Address is already a curator");
        require(curatorNominations[_curator] < 3, "Curator already nominated multiple times"); // Limit nominations to avoid spam

        curatorNominations[_curator]++;
        if (curatorNominations[_curator] == 1) {
            nominatedCurators.push(_curator);
        }
        emit CuratorNominated(_curator, msg.sender);
    }

    /**
     * @dev Allows token holders to vote for a nominated curator.
     * @param _curator The address of the nominated curator to vote for.
     */
    function voteForCurator(address _curator) external onlyGovernanceTokenHolder {
        require(curatorNominations[_curator] > 0, "Curator not nominated");
        // Implement voting logic here - e.g., based on governance token balance.
        // For simplicity, we can just increase a counter and check for a threshold.
        // In a real implementation, consider using a more robust voting mechanism.

        // Example: Simple majority based on token holders voting.
        // For demonstration, let's just assume a simple voting mechanism is implemented off-chain or through another contract.
        // In a real scenario, you'd track votes and determine if a curator is elected based on quorum and majority.

        // For this example, we'll just add the curator if enough nominations are received (e.g., 5).
        if (curatorNominations[_curator] >= 5 && !isCurator[_curator]) { // Example threshold - adjust as needed
            isCurator[_curator] = true;
            activeCurators.push(_curator);
            // Remove from nominated curators list
            for (uint256 i = 0; i < nominatedCurators.length; i++) {
                if (nominatedCurators[i] == _curator) {
                    nominatedCurators[i] = nominatedCurators[nominatedCurators.length - 1];
                    nominatedCurators.pop();
                    break;
                }
            }
            curatorNominations[_curator] = 0; // Reset nomination count
        }

        emit CuratorVoted(_curator, msg.sender, true); // Assuming vote is always 'for' in this simplified example.
    }

    /**
     * @dev Allows a nominator to revoke their nomination for a curator.
     * @param _curator The address of the nominated curator.
     */
    function revokeCuratorNomination(address _curator) external onlyGovernanceTokenHolder {
        require(curatorNominations[_curator] > 0, "Curator not nominated");
        curatorNominations[_curator]--;
        emit CuratorVoted(_curator, msg.sender, false); // Treat revocation as a negative vote.
        if (curatorNominations[_curator] == 0) {
             // Remove from nominated curators list if no nominations left
            for (uint256 i = 0; i < nominatedCurators.length; i++) {
                if (nominatedCurators[i] == _curator) {
                    nominatedCurators[i] = nominatedCurators[nominatedCurators.length - 1];
                    nominatedCurators.pop();
                    break;
                }
            }
        }
    }

    /**
     * @dev Function to remove a curator (governance vote or admin - for simplicity, only callable by existing curators in this example).
     * @param _curator The address of the curator to remove.
     */
    function removeCurator(address _curator) external onlyCurator {
        require(isCurator[_curator], "Address is not a curator");
        require(_curator != msg.sender, "Curator cannot remove themselves directly"); // Prevent accidental self-removal

        isCurator[_curator] = false;
        // Remove from active curators list
        for (uint256 i = 0; i < activeCurators.length; i++) {
            if (activeCurators[i] == _curator) {
                activeCurators[i] = activeCurators[activeCurators.length - 1];
                activeCurators.pop();
                break;
            }
        }
        emit CuratorRemoved(_curator, msg.sender);
    }

    /**
     * @dev Returns a list of currently active curators.
     * @return An array of curator addresses.
     */
    function getActiveCurators() external view returns (address[] memory) {
        return activeCurators;
    }


    // -------- II. Art Submission and Management --------

    /**
     * @dev Artists submit NFTs for gallery consideration.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The token ID of the NFT.
     * @param _metadataURI The URI for the NFT metadata.
     */
    function submitArtwork(address _nftContract, uint256 _tokenId, string memory _metadataURI) external {
        require(_nftContract != address(0), "Invalid NFT contract address");
        require(_tokenId > 0, "Invalid token ID");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty");

        artworkSubmissions.push(ArtworkSubmission({
            artist: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            metadataURI: _metadataURI,
            submissionTime: block.timestamp,
            approved: false,
            approvalVotes: 0,
            rejectionVotes: 0,
            approvingCurators: new address[](0),
            rejectingCurators: new address[](0),
            withdrawn: false
        }));
        emit ArtworkSubmitted(nextSubmissionId, msg.sender, _nftContract, _tokenId);
        nextSubmissionId++;
    }

    /**
     * @dev Curators vote to approve a submitted artwork for exhibition.
     * @param _submissionId The ID of the artwork submission.
     */
    function approveArtwork(uint256 _submissionId) external onlyCurator validSubmissionId(_submissionId) {
        ArtworkSubmission storage submission = artworkSubmissions[_submissionId];
        require(!submission.approved, "Artwork already approved");
        require(!submission.rejectingCuratorsContains(msg.sender), "Curator already rejected this artwork");
        require(!submission.approvingCuratorsContains(msg.sender), "Curator already voted to approve this artwork");

        submission.approvalVotes++;
        submission.approvingCurators.push(msg.sender);
        emit ArtworkApproved(_submissionId, msg.sender);

        // Example: Simple approval threshold (e.g., 2 curator approvals needed)
        if (submission.approvalVotes >= 2) {
            submission.approved = true;
        }
    }

    /**
     * @dev Curators vote to reject a submitted artwork.
     * @param _submissionId The ID of the artwork submission.
     */
    function rejectArtwork(uint256 _submissionId) external onlyCurator validSubmissionId(_submissionId) {
        ArtworkSubmission storage submission = artworkSubmissions[_submissionId];
        require(!submission.approved, "Artwork already approved");
        require(!submission.approvingCuratorsContains(msg.sender), "Curator already approved this artwork");
        require(!submission.rejectingCuratorsContains(msg.sender), "Curator already voted to reject this artwork");


        submission.rejectionVotes++;
        submission.rejectingCurators.push(msg.sender);
        emit ArtworkRejected(_submissionId, msg.sender);

        // Optionally, you could implement logic based on rejection votes as well.
        // For now, rejection is just recorded.
    }

    /**
     * @dev Returns details of a specific artwork submission.
     * @param _submissionId The ID of the artwork submission.
     * @return ArtworkSubmission struct containing submission details.
     */
    function getArtworkSubmissionDetails(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (ArtworkSubmission memory) {
        return artworkSubmissions[_submissionId];
    }

    /**
     * @dev Returns a list of submission IDs for all approved artworks in the gallery.
     * @return An array of submission IDs for approved artworks.
     */
    function getAllApprovedArtworks() external view returns (uint256[] memory) {
        uint256[] memory approvedArtworkIds = new uint256[](artworkSubmissions.length);
        uint256 count = 0;
        for (uint256 i = 0; i < artworkSubmissions.length; i++) {
            if (artworkSubmissions[i].approved && !artworkSubmissions[i].withdrawn) {
                approvedArtworkIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of approved artworks
        assembly {
            mstore(approvedArtworkIds, count)
        }
        return approvedArtworkIds;
    }

    /**
     * @dev Artist can withdraw their submitted artwork if it has not yet been approved.
     * @param _submissionId The ID of the artwork submission.
     */
    function withdrawArtwork(uint256 _submissionId) external validSubmissionId(_submissionId) notWithdrawn(_submissionId) {
        ArtworkSubmission storage submission = artworkSubmissions[_submissionId];
        require(submission.artist == msg.sender, "Only artist can withdraw artwork");
        require(!submission.approved, "Cannot withdraw approved artwork");

        submission.withdrawn = true;
        emit ArtworkWithdrawn(_submissionId, msg.sender);
    }


    // -------- III. Exhibition Management --------

    /**
     * @dev Curators can propose and create new exhibitions.
     * @param _exhibitionName The name of the exhibition.
     * @param _description A description of the exhibition.
     * @param _startTime The start time of the exhibition (timestamp).
     * @param _endTime The end time of the exhibition (timestamp).
     */
    function createExhibition(string memory _exhibitionName, string memory _description, uint256 _startTime, uint256 _endTime) external onlyCurator {
        require(bytes(_exhibitionName).length > 0, "Exhibition name cannot be empty");
        require(_startTime < _endTime, "Start time must be before end time");
        require(_startTime >= block.timestamp, "Start time must be in the future");

        exhibitions.push(Exhibition({
            name: _exhibitionName,
            description: _description,
            startTime: _startTime,
            endTime: _endTime,
            artworkSubmissionIds: new uint256[](0),
            isActive: true
        }));
        emit ExhibitionCreated(nextExhibitionId, _exhibitionName, msg.sender);
        nextExhibitionId++;
    }

    /**
     * @dev Curators add approved artworks to specific exhibitions.
     * @param _exhibitionId The ID of the exhibition.
     * @param _submissionId The ID of the artwork submission to add.
     */
    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _submissionId) external onlyCurator validExhibitionId(_exhibitionId) validSubmissionId(_submissionId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        ArtworkSubmission storage submission = artworkSubmissions[_submissionId];

        require(exhibition.isActive, "Exhibition is not active");
        require(submission.approved, "Artwork is not approved");
        require(!submission.withdrawn, "Artwork has been withdrawn");
        require(!exhibitionContainsArtwork(exhibition, _submissionId), "Artwork already in exhibition");

        exhibition.artworkSubmissionIds.push(_submissionId);
        emit ArtworkAddedToExhibition(_exhibitionId, _submissionId, msg.sender);
    }

    /**
     * @dev Curators can remove artworks from exhibitions.
     * @param _exhibitionId The ID of the exhibition.
     * @param _submissionId The ID of the artwork submission to remove.
     */
    function removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _submissionId) external onlyCurator validExhibitionId(_exhibitionId) validSubmissionId(_submissionId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.isActive, "Exhibition is not active");
        require(exhibitionContainsArtwork(exhibition, _submissionId), "Artwork not in exhibition");

        // Remove artwork from exhibition's artworkSubmissionIds array
        for (uint256 i = 0; i < exhibition.artworkSubmissionIds.length; i++) {
            if (exhibition.artworkSubmissionIds[i] == _submissionId) {
                exhibition.artworkSubmissionIds[i] = exhibition.artworkSubmissionIds[exhibition.artworkSubmissionIds.length - 1];
                exhibition.artworkSubmissionIds.pop();
                break;
            }
        }
        emit ArtworkRemovedFromExhibition(_exhibitionId, _submissionId, msg.sender);
    }

    /**
     * @dev Returns details of a specific exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @return Exhibition struct containing exhibition details.
     */
    function getExhibitionDetails(uint256 _exhibitionId) external view validExhibitionId(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /**
     * @dev Returns a list of IDs for currently active exhibitions.
     * @return An array of exhibition IDs for active exhibitions.
     */
    function getActiveExhibitions() external view returns (uint256[] memory) {
        uint256[] memory activeExhibitionIds = new uint256[](exhibitions.length);
        uint256 count = 0;
        for (uint256 i = 0; i < exhibitions.length; i++) {
            if (exhibitions[i].isActive && block.timestamp >= exhibitions[i].startTime && block.timestamp <= exhibitions[i].endTime) {
                activeExhibitionIds[count] = i;
                count++;
            }
        }
        // Resize the array
        assembly {
            mstore(activeExhibitionIds, count)
        }
        return activeExhibitionIds;
    }


    // -------- IV. Governance and Community Features --------

    /**
     * @dev Token holders can propose changes to gallery parameters (e.g., voting thresholds).
     * @param _parameterName The name of the parameter to change.
     * @param _newValue The new value for the parameter.
     */
    function proposeGalleryParameterChange(string memory _parameterName, uint256 _newValue) external onlyGovernanceTokenHolder {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty");
        require(_newValue > 0, "New value must be greater than 0"); // Example validation

        parameterChangeProposals.push(ParameterChangeProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        }));
        emit ParameterChangeProposed(nextProposalId, _parameterName, _newValue, msg.sender);
        nextProposalId++;
    }

    /**
     * @dev Token holders can vote on parameter change proposals.
     * @param _proposalId The ID of the parameter change proposal.
     * @param _vote True for yes, false for no.
     */
    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) external onlyGovernanceTokenHolder validProposalId(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.number <= proposal.endTime, "Voting has ended"); // Redundant check, but good to have.

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ParameterChangeVoted(_proposalId, msg.sender, _vote);

        // Check if quorum and majority are reached after each vote.
        if (block.number > proposal.endTime && !proposal.executed) {
            executeParameterChange(_proposalId); // Auto-execute after voting ends
        }
    }

    /**
     * @dev Executes approved parameter change proposals if quorum and majority are reached.
     * @param _proposalId The ID of the parameter change proposal.
     */
    function executeParameterChange(uint256 _proposalId) public validProposalId(_proposalId) votingHasEnded(parameterChangeProposals[_proposalId].endTime) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 quorum = (totalVotes * 100) / getCirculatingSupply(); // Example: Quorum based on token supply.
        uint256 yesPercentage = (proposal.yesVotes * 100) / totalVotes; // Calculate percentage

        if (quorum >= quorumPercentage && yesPercentage > 50) { // Example: 50% quorum and simple majority
            proposal.executed = true;
            if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("votingDurationBlocks"))) {
                votingDurationBlocks = proposal.newValue;
            } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("quorumPercentage"))) {
                quorumPercentage = proposal.newValue;
            }
            // Add more parameter name checks here as needed for other parameters you want to govern.
            emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.newValue);
        }
    }

    /**
     * @dev Allows anyone to donate ETH to the gallery's treasury.
     */
    function donateToGallery() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    /**
     * @dev Returns the current balance of the gallery's treasury.
     * @return The treasury balance in ETH.
     */
    function getGalleryTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Curators can propose treasury withdrawals for gallery operations.
     * @param _amount The amount of ETH to withdraw.
     * @param _recipient The address to receive the withdrawn ETH.
     * @param _reason A reason for the withdrawal.
     */
    function requestTreasuryWithdrawal(uint256 _amount, address _recipient, string memory _reason) external onlyCurator {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(_recipient != address(0), "Invalid recipient address");
        require(getGalleryTreasuryBalance() >= _amount, "Insufficient treasury balance");
        require(bytes(_reason).length > 0, "Withdrawal reason cannot be empty");

        treasuryWithdrawalRequests.push(TreasuryWithdrawalRequest({
            amount: _amount,
            recipient: _recipient,
            reason: _reason,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        }));
        emit TreasuryWithdrawalRequested(nextWithdrawalId, _amount, _recipient, _reason, msg.sender);
        nextWithdrawalId++;
    }

    /**
     * @dev Token holders vote on treasury withdrawal requests.
     * @param _withdrawalId The ID of the treasury withdrawal request.
     * @param _vote True for yes, false for no.
     */
    function voteOnTreasuryWithdrawal(uint256 _withdrawalId, bool _vote) external onlyGovernanceTokenHolder validWithdrawalId(_withdrawalId) {
        TreasuryWithdrawalRequest storage withdrawal = treasuryWithdrawalRequests[_withdrawalId];
        require(!withdrawal.executed, "Withdrawal already executed");
        require(block.number <= withdrawal.endTime, "Voting has ended");

        if (_vote) {
            withdrawal.yesVotes++;
        } else {
            withdrawal.noVotes++;
        }
        emit TreasuryWithdrawalVoted(_withdrawalId, msg.sender, _vote);

        // Check for auto-execution after voting ends
        if (block.number > withdrawal.endTime && !withdrawal.executed) {
            executeTreasuryWithdrawal(_withdrawalId);
        }
    }

    /**
     * @dev Executes approved treasury withdrawal requests if quorum and majority are reached.
     * @param _withdrawalId The ID of the treasury withdrawal request.
     */
    function executeTreasuryWithdrawal(uint256 _withdrawalId) public validWithdrawalId(_withdrawalId) votingHasEnded(treasuryWithdrawalRequests[_withdrawalId].endTime) {
        TreasuryWithdrawalRequest storage withdrawal = treasuryWithdrawalRequests[_withdrawalId];
        require(!withdrawal.executed, "Withdrawal already executed");

        uint256 totalVotes = withdrawal.yesVotes + withdrawal.noVotes;
        uint256 quorum = (totalVotes * 100) / getCirculatingSupply(); // Quorum based on token supply
        uint256 yesPercentage = (withdrawal.yesVotes * 100) / totalVotes;

        if (quorum >= quorumPercentage && yesPercentage > 50) { // 50% quorum and simple majority
            withdrawal.executed = true;
            payable(withdrawal.recipient).transfer(withdrawal.amount);
            emit TreasuryWithdrawalExecuted(_withdrawalId, withdrawal.amount, withdrawal.recipient);
        }
    }


    // -------- V. Utility Functions --------

    /**
     * @dev Admin function (for demonstration - in a real DAO, governance should handle this) to set the default voting duration.
     * @param _durationInBlocks The voting duration in blocks.
     */
    function setVotingDuration(uint256 _durationInBlocks) external onlyCurator { // Example: Only curators can set this for simplicity. Governance should ideally control this.
        votingDurationBlocks = _durationInBlocks;
    }

    /**
     * @dev Admin function (for demonstration - in a real DAO, governance should handle this) to set the quorum percentage for votes.
     * @param _percentage The quorum percentage (e.g., 50 for 50%).
     */
    function setQuorumPercentage(uint256 _percentage) external onlyCurator { // Example: Only curators can set this for simplicity. Governance should ideally control this.
        require(_percentage <= 100, "Quorum percentage cannot exceed 100");
        quorumPercentage = _percentage;
    }


    // -------- Internal Helper Functions --------

    /**
     * @dev Checks if an exhibition already contains a specific artwork submission.
     * @param _exhibition The Exhibition struct.
     * @param _submissionId The ID of the artwork submission.
     * @return True if the exhibition contains the artwork, false otherwise.
     */
    function exhibitionContainsArtwork(Exhibition storage _exhibition, uint256 _submissionId) internal view returns (bool) {
        for (uint256 i = 0; i < _exhibition.artworkSubmissionIds.length; i++) {
            if (_exhibition.artworkSubmissionIds[i] == _submissionId) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Checks if a curator list contains a specific curator address.
     * @param _curatorList The array of curator addresses.
     * @param _curatorAddress The address to check for.
     * @return True if the list contains the address, false otherwise.
     */
    function curatorsContains(address[] memory _curatorList, address _curatorAddress) internal pure returns (bool) {
        for (uint256 i = 0; i < _curatorList.length; i++) {
            if (_curatorList[i] == _curatorAddress) {
                return true;
            }
        }
        return false;
    }

     /**
     * @dev Checks if the approving curators list contains a specific curator address.
     * @param _submission The ArtworkSubmission struct.
     * @param _curatorAddress The address to check for.
     * @return True if the list contains the address, false otherwise.
     */
    function approvingCuratorsContains(ArtworkSubmission storage _submission, address _curatorAddress) internal view returns (bool) {
        return curatorsContains(_submission.approvingCurators, _curatorAddress);
    }

    /**
     * @dev Checks if the rejecting curators list contains a specific curator address.
     * @param _submission The ArtworkSubmission struct.
     * @param _curatorAddress The address to check for.
     * @return True if the list contains the address, false otherwise.
     */
    function rejectingCuratorsContains(ArtworkSubmission storage _submission, address _curatorAddress) internal view returns (bool) {
        return curatorsContains(_submission.rejectingCurators, _curatorAddress);
    }


    /**
     * @dev Example function to get the circulating supply of the governance token.
     *      Replace with actual logic to fetch supply from the token contract.
     * @return The circulating supply of governance tokens.
     */
    function getCirculatingSupply() public view returns (uint256) {
        // In a real implementation, you would interact with the governanceToken contract
        // (assuming it's an ERC20-like token) to get the totalSupply or circulating supply.
        // For this example, we return a fixed value for demonstration.
        return 100000; // Example circulating supply
    }

    /**
     * @dev Example function to get the governance token balance of an address.
     *      Replace with actual logic to fetch balance from the token contract.
     * @param _account The address to check the balance of.
     * @return The governance token balance of the account.
     */
    function getGovernanceTokenBalance(address _account) public view returns (uint256) {
        // In a real implementation, you would interact with the governanceToken contract
        // (assuming it's an ERC20-like token) to get the balance of _account.
        // For this example, we return a fixed value or simulate a balance check.
        // Example: Assume every address has at least 1 token for demonstration.
        return 1; // Example balance - replace with actual token balance check
    }
}
```