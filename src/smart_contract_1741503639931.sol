```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) that allows artists to submit artworks,
 * members to vote on submissions, manage a treasury, curate exhibitions, and implement dynamic royalty splits.
 *
 * **Outline:**
 * 1. **Art Submission and Review:**
 *    - `submitArtwork`: Artists submit artwork metadata and IPFS hash.
 *    - `voteOnArtwork`: Collective members vote to accept or reject submitted artwork.
 *    - `getArtworkDetails`: Retrieve details of a specific artwork.
 *    - `getArtworkStatus`: Check the current status of an artwork (pending, accepted, rejected).
 *
 * 2. **Collective Membership and Governance:**
 *    - `joinCollective`: Request to join the collective (requires approval).
 *    - `approveMembership`: Owner/existing members approve new membership requests.
 *    - `revokeMembership`: Owner can revoke membership.
 *    - `isCollectiveMember`: Check if an address is a member.
 *    - `proposeParameterChange`: Members propose changes to collective parameters (e.g., voting thresholds).
 *    - `voteOnParameterChange`: Collective members vote on parameter change proposals.
 *
 * 3. **Treasury Management and Funding:**
 *    - `depositFunds`: Deposit ETH into the collective treasury.
 *    - `requestFunding`: Members can request funding for art-related projects.
 *    - `voteOnFundingRequest`: Collective votes on funding requests.
 *    - `withdrawFunds`: Owner can execute approved funding withdrawals.
 *    - `getTreasuryBalance`: View the current treasury balance.
 *
 * 4. **Exhibition Curation and Management:**
 *    - `createExhibition`: Propose and create a new virtual exhibition.
 *    - `addArtworkToExhibition`: Add accepted artworks to an exhibition.
 *    - `voteOnExhibitionCurator`: Vote to select a curator for an exhibition.
 *    - `setExhibitionDates`: Curator sets the start and end dates of an exhibition.
 *    - `getExhibitionDetails`: Retrieve details of a specific exhibition.
 *
 * 5. **Dynamic Royalty and Revenue Sharing:**
 *    - `setArtworkRoyaltySplit`: Set a custom royalty split for an artwork (e.g., artist, collective, curator).
 *    - `distributeRoyalties`: Distribute royalties from artwork sales to designated recipients.
 *    - `setPlatformFee`: Set a platform fee percentage for artwork sales.
 *
 * 6. **Reputation and Contribution Tracking (Advanced):**
 *    - `recordContribution`: (Internal use) Record contributions of members (e.g., voting, curation).
 *    - `getMemberReputation`: View a member's reputation score (based on contributions).
 *
 * **Function Summary:**
 * 1. `submitArtwork(string _title, string _description, string _ipfsHash)`: Allows artists to submit their artwork proposal.
 * 2. `voteOnArtwork(uint256 _artworkId, bool _approve)`: Collective members vote to approve or reject an artwork submission.
 * 3. `getArtworkDetails(uint256 _artworkId)`: Retrieves detailed information about a specific artwork.
 * 4. `getArtworkStatus(uint256 _artworkId)`: Gets the current status of an artwork (Pending, Accepted, Rejected).
 * 5. `joinCollective()`: Allows an address to request membership to the collective.
 * 6. `approveMembership(address _newMember)`: Owner or existing members can approve pending membership requests.
 * 7. `revokeMembership(address _member)`: Owner can revoke membership from a collective member.
 * 8. `isCollectiveMember(address _address)`: Checks if an address is a member of the collective.
 * 9. `proposeParameterChange(string _parameterName, uint256 _newValue)`: Members can propose changes to collective parameters like voting thresholds.
 * 10. `voteOnParameterChange(uint256 _proposalId, bool _approve)`: Members vote on parameter change proposals.
 * 11. `depositFunds() payable`: Allows anyone to deposit ETH into the collective treasury.
 * 12. `requestFunding(string _projectName, string _projectDescription, uint256 _amount)`: Collective members can request funding for art-related projects.
 * 13. `voteOnFundingRequest(uint256 _requestId, bool _approve)`: Members vote on funding requests.
 * 14. `withdrawFunds(uint256 _requestId)`: Owner can execute approved funding withdrawals from the treasury.
 * 15. `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 * 16. `createExhibition(string _exhibitionName, string _exhibitionDescription)`: Allows members to propose and create new exhibitions.
 * 17. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Add accepted artworks to a specific exhibition.
 * 18. `voteOnExhibitionCurator(uint256 _exhibitionId, address _curator)`: Collective members vote to select a curator for an exhibition.
 * 19. `setExhibitionDates(uint256 _exhibitionId, uint256 _startDate, uint256 _endDate)`:  Curator sets the start and end dates for an exhibition.
 * 20. `getExhibitionDetails(uint256 _exhibitionId)`: Retrieves details of a specific exhibition.
 * 21. `setArtworkRoyaltySplit(uint256 _artworkId, address[] memory _recipients, uint256[] memory _percentages)`: Sets custom royalty splits for an artwork.
 * 22. `distributeRoyalties(uint256 _artworkId, uint256 _salePrice)`: Distributes royalties after an artwork sale.
 * 23. `setPlatformFee(uint256 _feePercentage)`: Owner can set the platform fee percentage for artwork sales.
 * 24. `getMemberReputation(address _member)`: Returns the reputation score of a member. (Example of an advanced/optional feature).
 */

contract DecentralizedArtCollective {

    // --- Structs and Enums ---

    enum ArtworkStatus { Pending, Accepted, Rejected }
    enum ProposalStatus { Pending, Approved, Rejected }

    struct Artwork {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        ArtworkStatus status;
        uint256 submissionTimestamp;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct MembershipRequest {
        address requester;
        uint256 requestTimestamp;
    }

    struct ParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        ProposalStatus status;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct FundingRequest {
        uint256 id;
        string projectName;
        string projectDescription;
        uint256 amount;
        address requester;
        ProposalStatus status;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct Exhibition {
        uint256 id;
        string name;
        string description;
        address curator;
        uint256 startDate;
        uint256 endDate;
        uint256 creationTimestamp;
        uint256[] artworkIds; // Array of artwork IDs in the exhibition
    }

    struct RoyaltySplit {
        address[] recipients;
        uint256[] percentages; // Percentages should sum to 10000 (representing 100%)
    }

    struct MemberContribution {
        uint256 votesCast;
        uint256 proposalsCreated;
        uint256 curationActions;
        // ... more contribution types can be added
    }


    // --- State Variables ---

    address public owner;
    uint256 public artworkCounter;
    uint256 public proposalCounter;
    uint256 public fundingRequestCounter;
    uint256 public exhibitionCounter;
    uint256 public platformFeePercentage = 500; // Default 5% platform fee (500/10000)

    mapping(uint256 => Artwork) public artworks;
    mapping(address => bool) public collectiveMembers;
    mapping(address => MembershipRequest) public membershipRequests;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => FundingRequest) public fundingRequests;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => RoyaltySplit) public artworkRoyaltySplits;
    mapping(address => MemberContribution) public memberContributions; // Track member contributions

    uint256 public artworkApprovalThresholdPercentage = 50; // Default 50% for artwork approval
    uint256 public parameterProposalThresholdPercentage = 60; // Default 60% for parameter proposal approval
    uint256 public fundingRequestThresholdPercentage = 70; // Default 70% for funding request approval
    uint256 public membershipApprovalThresholdPercentage = 50; // Default 50% for membership approval

    // --- Events ---

    event ArtworkSubmitted(uint256 artworkId, address artist, string title);
    event ArtworkVotedOn(uint256 artworkId, address voter, bool approve);
    event ArtworkStatusUpdated(uint256 artworkId, ArtworkStatus status);
    event MembershipRequested(address requester);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterProposalVotedOn(uint256 proposalId, address voter, bool approve);
    event ParameterProposalStatusUpdated(uint256 proposalId, ProposalStatus status);
    event FundsDeposited(address depositor, uint256 amount);
    event FundingRequestCreated(uint256 requestId, address requester, uint256 amount);
    event FundingRequestVotedOn(uint256 requestId, address voter, bool approve);
    event FundingRequestStatusUpdated(uint256 requestId, ProposalStatus status);
    event FundsWithdrawn(uint256 requestId, address recipient, uint256 amount);
    event ExhibitionCreated(uint256 exhibitionId, string name, address creator);
    event ArtworkAddedToExhibition(uint256 exhibitionId, uint256 artworkId);
    event ExhibitionCuratorVoted(uint256 exhibitionId, address voter, address curator);
    event ExhibitionCuratorSet(uint256 exhibitionId, address curator);
    event ExhibitionDatesSet(uint256 exhibitionId, uint256 startDate, uint256 endDate);
    event RoyaltySplitSet(uint256 artworkId);
    event RoyaltiesDistributed(uint256 artworkId, uint256 salePrice);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event ContributionRecorded(address member, string actionType);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCollectiveMembers() {
        require(collectiveMembers[msg.sender], "Only collective members can call this function.");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkCounter, "Invalid artwork ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validFundingRequestId(uint256 _requestId) {
        require(_requestId > 0 && _requestId <= fundingRequestCounter, "Invalid funding request ID.");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId <= exhibitionCounter, "Invalid exhibition ID.");
        _;
    }

    modifier artworkInPendingStatus(uint256 _artworkId) {
        require(artworks[_artworkId].status == ArtworkStatus.Pending, "Artwork is not in pending status.");
        _;
    }

    modifier proposalInPendingStatus(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not in pending status.");
        _;
    }

    modifier fundingRequestInPendingStatus(uint256 _requestId) {
        require(fundingRequests[_requestId].status == ProposalStatus.Pending, "Funding request is not in pending status.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        artworkCounter = 0;
        proposalCounter = 0;
        fundingRequestCounter = 0;
        exhibitionCounter = 0;
    }


    // --- 1. Art Submission and Review ---

    function submitArtwork(string memory _title, string memory _description, string memory _ipfsHash) public {
        artworkCounter++;
        artworks[artworkCounter] = Artwork({
            id: artworkCounter,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: msg.sender,
            status: ArtworkStatus.Pending,
            submissionTimestamp: block.timestamp,
            upVotes: 0,
            downVotes: 0
        });
        emit ArtworkSubmitted(artworkCounter, msg.sender, _title);
    }

    function voteOnArtwork(uint256 _artworkId, bool _approve)
        public
        onlyCollectiveMembers()
        validArtworkId(_artworkId)
        artworkInPendingStatus(_artworkId)
    {
        require(artworks[_artworkId].artist != msg.sender, "Artist cannot vote on their own artwork.");
        if (_approve) {
            artworks[_artworkId].upVotes++;
        } else {
            artworks[_artworkId].downVotes++;
        }
        emit ArtworkVotedOn(_artworkId, msg.sender, _approve);
        recordContribution(msg.sender, "artwork_vote"); // Record contribution

        _updateArtworkStatus(_artworkId);
    }

    function _updateArtworkStatus(uint256 _artworkId) private {
        uint256 totalVotes = artworks[_artworkId].upVotes + artworks[_artworkId].downVotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (artworks[_artworkId].upVotes * 100) / totalVotes;
            if (approvalPercentage >= artworkApprovalThresholdPercentage) {
                artworks[_artworkId].status = ArtworkStatus.Accepted;
                emit ArtworkStatusUpdated(_artworkId, ArtworkStatus.Accepted);
            } else if (approvalPercentage < (100 - artworkApprovalThresholdPercentage) ) { // To reject if downvotes are significant
                artworks[_artworkId].status = ArtworkStatus.Rejected;
                emit ArtworkStatusUpdated(_artworkId, ArtworkStatus.Rejected);
            }
        }
    }


    function getArtworkDetails(uint256 _artworkId) public view validArtworkId(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getArtworkStatus(uint256 _artworkId) public view validArtworkId(_artworkId) returns (ArtworkStatus) {
        return artworks[_artworkId].status;
    }


    // --- 2. Collective Membership and Governance ---

    function joinCollective() public {
        require(!collectiveMembers[msg.sender], "Already a member or membership requested.");
        membershipRequests[msg.sender] = MembershipRequest({
            requester: msg.sender,
            requestTimestamp: block.timestamp
        });
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _newMember) public onlyCollectiveMembers() {
        require(membershipRequests[_newMember].requester == _newMember, "No membership request found for this address.");
        delete membershipRequests[_newMember]; // Remove request
        collectiveMembers[_newMember] = true;
        emit MembershipApproved(_newMember);
        recordContribution(_newMember, "membership_granted"); // Record contribution for new member
    }

    function revokeMembership(address _member) public onlyOwner() {
        require(collectiveMembers[_member], "Address is not a collective member.");
        delete collectiveMembers[_member];
        emit MembershipRevoked(_member);
    }

    function isCollectiveMember(address _address) public view returns (bool) {
        return collectiveMembers[_address];
    }

    function proposeParameterChange(string memory _parameterName, uint256 _newValue) public onlyCollectiveMembers() {
        proposalCounter++;
        parameterChangeProposals[proposalCounter] = ParameterChangeProposal({
            id: proposalCounter,
            parameterName: _parameterName,
            newValue: _newValue,
            status: ProposalStatus.Pending,
            upVotes: 0,
            downVotes: 0
        });
        emit ParameterProposalCreated(proposalCounter, _parameterName, _newValue);
        recordContribution(msg.sender, "parameter_proposal"); // Record contribution
    }

    function voteOnParameterChange(uint256 _proposalId, bool _approve)
        public
        onlyCollectiveMembers()
        validProposalId(_proposalId)
        proposalInPendingStatus(_proposalId)
    {
        if (_approve) {
            parameterChangeProposals[_proposalId].upVotes++;
        } else {
            parameterChangeProposals[_proposalId].downVotes++;
        }
        emit ParameterProposalVotedOn(_proposalId, msg.sender, _approve);
        recordContribution(msg.sender, "parameter_vote"); // Record contribution

        _updateParameterProposalStatus(_proposalId);
    }

    function _updateParameterProposalStatus(uint256 _proposalId) private {
        uint256 totalVotes = parameterChangeProposals[_proposalId].upVotes + parameterChangeProposals[_proposalId].downVotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (parameterChangeProposals[_proposalId].upVotes * 100) / totalVotes;
            if (approvalPercentage >= parameterProposalThresholdPercentage) {
                parameterChangeProposals[_proposalId].status = ProposalStatus.Approved;
                emit ParameterProposalStatusUpdated(_proposalId, ProposalStatus.Approved);
                _applyParameterChange(_proposalId); // Apply the change if approved
            } else {
                parameterChangeProposals[_proposalId].status = ProposalStatus.Rejected;
                emit ParameterProposalStatusUpdated(_proposalId, ProposalStatus.Rejected);
            }
        }
    }

    function _applyParameterChange(uint256 _proposalId) private {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("artworkApprovalThresholdPercentage"))) {
            artworkApprovalThresholdPercentage = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("parameterProposalThresholdPercentage"))) {
            parameterProposalThresholdPercentage = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("fundingRequestThresholdPercentage"))) {
            fundingRequestThresholdPercentage = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("membershipApprovalThresholdPercentage"))) {
            membershipApprovalThresholdPercentage = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("platformFeePercentage"))) {
            setPlatformFee(proposal.newValue); // Use the setPlatformFee function for validation and event
        } else {
            revert("Unknown parameter to change."); // Handle unknown parameters
        }
    }


    // --- 3. Treasury Management and Funding ---

    function depositFunds() public payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function requestFunding(string memory _projectName, string memory _projectDescription, uint256 _amount) public onlyCollectiveMembers() {
        require(_amount > 0, "Funding amount must be positive.");
        fundingRequestCounter++;
        fundingRequests[fundingRequestCounter] = FundingRequest({
            id: fundingRequestCounter,
            projectName: _projectName,
            projectDescription: _projectDescription,
            amount: _amount,
            requester: msg.sender,
            status: ProposalStatus.Pending,
            upVotes: 0,
            downVotes: 0
        });
        emit FundingRequestCreated(fundingRequestCounter, msg.sender, _amount);
        recordContribution(msg.sender, "funding_request"); // Record contribution
    }

    function voteOnFundingRequest(uint256 _requestId, bool _approve)
        public
        onlyCollectiveMembers()
        validFundingRequestId(_requestId)
        fundingRequestInPendingStatus(_requestId)
    {
        if (_approve) {
            fundingRequests[_requestId].upVotes++;
        } else {
            fundingRequests[_requestId].downVotes++;
        }
        emit FundingRequestVotedOn(_requestId, msg.sender, _approve);
        recordContribution(msg.sender, "funding_vote"); // Record contribution

        _updateFundingRequestStatus(_requestId);
    }

    function _updateFundingRequestStatus(uint256 _requestId) private {
        uint256 totalVotes = fundingRequests[_requestId].upVotes + fundingRequests[_requestId].downVotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (fundingRequests[_requestId].upVotes * 100) / totalVotes;
            if (approvalPercentage >= fundingRequestThresholdPercentage) {
                fundingRequests[_requestId].status = ProposalStatus.Approved;
                emit FundingRequestStatusUpdated(_requestId, ProposalStatus.Approved);
            } else {
                fundingRequests[_requestId].status = ProposalStatus.Rejected;
                emit FundingRequestStatusUpdated(_requestId, ProposalStatus.Rejected);
            }
        }
    }

    function withdrawFunds(uint256 _requestId) public onlyOwner() validFundingRequestId(_requestId) {
        require(fundingRequests[_requestId].status == ProposalStatus.Approved, "Funding request is not approved.");
        FundingRequest storage request = fundingRequests[_requestId];
        uint256 amountToWithdraw = request.amount;
        require(address(this).balance >= amountToWithdraw, "Insufficient treasury balance.");

        request.status = ProposalStatus.Rejected; // Prevent double withdrawal, mark as completed/rejected after withdrawal
        (bool success, ) = payable(request.requester).call{value: amountToWithdraw}("");
        require(success, "Transfer failed.");
        emit FundsWithdrawn(_requestId, request.requester, amountToWithdraw);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- 4. Exhibition Curation and Management ---

    function createExhibition(string memory _exhibitionName, string memory _exhibitionDescription) public onlyCollectiveMembers() {
        exhibitionCounter++;
        exhibitions[exhibitionCounter] = Exhibition({
            id: exhibitionCounter,
            name: _exhibitionName,
            description: _exhibitionDescription,
            curator: address(0), // Curator initially not set
            startDate: 0,
            endDate: 0,
            creationTimestamp: block.timestamp,
            artworkIds: new uint256[](0) // Initialize with empty artwork array
        });
        emit ExhibitionCreated(exhibitionCounter, _exhibitionName, msg.sender);
        recordContribution(msg.sender, "exhibition_creation"); // Record contribution
    }

    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)
        public
        onlyCollectiveMembers()
        validExhibitionId(_exhibitionId)
        validArtworkId(_artworkId)
    {
        require(artworks[_artworkId].status == ArtworkStatus.Accepted, "Artwork must be accepted to be added to exhibition.");
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.curator == msg.sender || exhibition.curator == address(0), "Only curator can add artworks or curator not yet set."); // Allow curator or initial adding before curator set.
        // Check if artwork is already in the exhibition (optional, to prevent duplicates)
        for (uint256 i = 0; i < exhibition.artworkIds.length; i++) {
            require(exhibition.artworkIds[i] != _artworkId, "Artwork already in this exhibition.");
        }
        exhibitions[_exhibitionId].artworkIds.push(_artworkId);
        emit ArtworkAddedToExhibition(_exhibitionId, _artworkId);
        recordContribution(msg.sender, "artwork_exhibition_add"); // Record contribution
    }

    function voteOnExhibitionCurator(uint256 _exhibitionId, address _curator)
        public
        onlyCollectiveMembers()
        validExhibitionId(_exhibitionId)
    {
        require(_curator != address(0), "Invalid curator address.");
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.curator == address(0), "Curator already set for this exhibition."); // Prevent re-voting on curator
        exhibition.curator = _curator; // For simplicity, directly set curator upon first vote. Can be made into a voting process if needed.
        emit ExhibitionCuratorVoted(_exhibitionId, msg.sender, _curator);
        emit ExhibitionCuratorSet(_exhibitionId, _curator);
        recordContribution(msg.sender, "curator_vote"); // Record contribution
    }

    function setExhibitionDates(uint256 _exhibitionId, uint256 _startDate, uint256 _endDate)
        public
        onlyCollectiveMembers()
        validExhibitionId(_exhibitionId)
    {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.curator == msg.sender, "Only the curator can set exhibition dates.");
        require(_startDate < _endDate, "Start date must be before end date.");
        exhibition.startDate = _startDate;
        exhibition.endDate = _endDate;
        emit ExhibitionDatesSet(_exhibitionId, _startDate, _endDate);
        recordContribution(msg.sender, "exhibition_dates_set"); // Record contribution
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view validExhibitionId(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }


    // --- 5. Dynamic Royalty and Revenue Sharing ---

    function setArtworkRoyaltySplit(uint256 _artworkId, address[] memory _recipients, uint256[] memory _percentages)
        public
        onlyCollectiveMembers()
        validArtworkId(_artworkId)
    {
        require(_recipients.length == _percentages.length, "Recipients and percentages arrays must have the same length.");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _percentages.length; i++) {
            totalPercentage += _percentages[i];
        }
        require(totalPercentage == 10000, "Total royalty percentages must equal 100%."); // Check if sums to 100% (10000/100 = 100%)

        artworkRoyaltySplits[_artworkId] = RoyaltySplit({
            recipients: _recipients,
            percentages: _percentages
        });
        emit RoyaltySplitSet(_artworkId);
        recordContribution(msg.sender, "royalty_split_set"); // Record contribution
    }

    function distributeRoyalties(uint256 _artworkId, uint256 _salePrice) public validArtworkId(_artworkId) {
        require(artworkRoyaltySplits[_artworkId].recipients.length > 0, "Royalty split not set for this artwork.");
        RoyaltySplit memory split = artworkRoyaltySplits[_artworkId];
        uint256 platformFee = (_salePrice * platformFeePercentage) / 10000; // Calculate platform fee
        uint256 netSalePrice = _salePrice - platformFee;

        for (uint256 i = 0; i < split.recipients.length; i++) {
            uint256 royaltyAmount = (netSalePrice * split.percentages[i]) / 10000;
            (bool success, ) = payable(split.recipients[i]).call{value: royaltyAmount}("");
            require(success, "Royalty transfer failed.");
        }

        // Transfer platform fee to the contract (owner can withdraw later if needed or use for collective expenses).
        (bool platformFeeSuccess, ) = payable(owner).call{value: platformFee}(""); // Owner receives platform fee. Adjust recipient if needed.
        require(platformFeeSuccess, "Platform fee transfer failed.");


        emit RoyaltiesDistributed(_artworkId, _salePrice);
    }

    function setPlatformFee(uint256 _feePercentage) public onlyOwner() {
        require(_feePercentage <= 10000, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }


    // --- 6. Reputation and Contribution Tracking (Advanced) ---

    function recordContribution(address _member, string memory _actionType) private {
        if (!collectiveMembers[_member]) return; // Only record for members.

        MemberContribution storage contribution = memberContributions[_member];
        if (keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("artwork_vote")) ||
            keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("parameter_vote")) ||
            keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("funding_vote"))
        ) {
            contribution.votesCast++;
        } else if (keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("parameter_proposal")) ||
                   keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("funding_request")) ||
                   keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("exhibition_creation"))
        ) {
            contribution.proposalsCreated++;
        } else if (keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("artwork_exhibition_add")) ||
                   keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("curator_vote")) ||
                   keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("exhibition_dates_set"))
        ) {
            contribution.curationActions++;
        } else if (keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("membership_granted"))) {
            // Example for membership granted, can add specific points for different actions
            // For now, treat it as a general contribution
        }
        emit ContributionRecorded(_member, _actionType);
    }

    function getMemberReputation(address _member) public view onlyCollectiveMembers() returns (uint256 reputationScore) {
        MemberContribution memory contribution = memberContributions[_member];
        // Example reputation calculation - can be customized based on desired weighting.
        reputationScore = (contribution.votesCast * 1) + (contribution.proposalsCreated * 3) + (contribution.curationActions * 2); // Example weights
        return reputationScore;
    }

    // --- Fallback and Receive (Optional for ETH deposits if not using depositFunds explicitly) ---
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value); // Allow direct ETH sending to contract
    }

    fallback() external payable {
        emit FundsDeposited(msg.sender, msg.value); // Allow direct ETH sending to contract
    }
}
```