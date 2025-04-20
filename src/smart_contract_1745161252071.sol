```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling community-driven art acquisition,
 * curation, exhibitions, and revenue sharing. This contract incorporates advanced concepts like proposal-based governance,
 * dynamic membership, tiered voting power, and innovative art utility mechanisms.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership Management:**
 *    - `joinCollective()`: Allows users to request membership by staking ETH or specific tokens.
 *    - `approveMembership(address _member)`: Only for DAO members, approves pending membership requests.
 *    - `revokeMembership(address _member)`: Only for DAO members, revokes existing membership.
 *    - `getMemberDetails(address _member)`: View function to retrieve details of a member (status, voting power, stake).
 *    - `getMembershipStatus(address _user)`: View function to check if an address is a member.
 *
 * **2. Art Proposal and Acquisition:**
 *    - `submitArtProposal(string memory _artTitle, string memory _artDescription, address _artistAddress, uint256 _estimatedCost, string memory _artMetadataURI)`: Members submit proposals for acquiring new artworks.
 *    - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members vote on pending art proposals. Voting power influences vote weight.
 *    - `fundArtProposal(uint256 _proposalId)`: Members contribute funds (ETH or tokens) towards approved art proposals.
 *    - `finalizeArtAcquisition(uint256 _proposalId)`: Once funding goal is reached, finalizes art acquisition (can mint NFT or handle other acquisition logic).
 *    - `cancelArtProposal(uint256 _proposalId)`: Allows proposal creator to cancel their proposal before voting starts.
 *    - `getArtProposalDetails(uint256 _proposalId)`: View function to retrieve details of a specific art proposal.
 *    - `getProposalStatus(uint256 _proposalId)`: View function to check the current status of an art proposal (pending, voting, funded, acquired, rejected, cancelled).
 *    - `getActiveArtProposals()`: View function to get a list of IDs of currently active art proposals.
 *
 * **3. Art Collection Management & Exhibition:**
 *    - `listArtForExhibition(uint256 _artId, string memory _exhibitionDetails)`: Members can propose to list an acquired artwork for exhibition (physical or digital).
 *    - `voteOnExhibitionListing(uint256 _listingId, bool _vote)`: Members vote on artwork exhibition listings.
 *    - `removeArtFromExhibition(uint256 _listingId)`:  Allows removing art from exhibition after a certain period or by vote.
 *    - `getExhibitionListingDetails(uint256 _listingId)`: View function to retrieve details of an exhibition listing.
 *    - `getCollectionArtIds()`: View function to get a list of IDs of artworks in the DAAC collection.
 *    - `getArtDetails(uint256 _artId)`: View function to retrieve details of a specific artwork in the collection.
 *
 * **4. Revenue and Treasury Management:**
 *    - `contributeToTreasury()`: Members can voluntarily contribute ETH or tokens to the DAAC treasury.
 *    - `requestTreasuryWithdrawal(uint256 _amount, address _recipient, string memory _reason)`: Members can propose treasury withdrawals for collective-related expenses.
 *    - `voteOnTreasuryWithdrawal(uint256 _withdrawalId, bool _vote)`: Members vote on proposed treasury withdrawals.
 *    - `distributeRevenue(uint256 _amount)`: Function to distribute revenue generated (e.g., from exhibitions, art sales) to members proportionally based on their stake/contribution (advanced concept).
 *    - `getTreasuryBalance()`: View function to check the current balance of the DAAC treasury.
 *
 * **5. Governance and Parameters:**
 *    - `setMembershipStakeAmount(uint256 _newStakeAmount)`: Owner function to change the required stake amount for membership.
 *    - `setVotingDuration(uint256 _newDuration)`: Owner function to change the default voting duration for proposals.
 *    - `setVotingThreshold(uint256 _newThreshold)`: Owner function to change the voting threshold (percentage of votes needed for approval).
 *    - `pauseContract()`: Owner function to pause the contract in emergency situations.
 *    - `unpauseContract()`: Owner function to unpause the contract.
 *    - `emergencyWithdraw(address _tokenAddress, address _recipient, uint256 _amount)`: Owner function for emergency withdrawal of tokens/ETH in case of critical vulnerabilities (use with extreme caution).
 */

contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    address public owner;
    uint256 public membershipStakeAmount = 1 ether; // Default stake amount for membership
    uint256 public votingDuration = 7 days; // Default voting duration for proposals
    uint256 public votingThresholdPercentage = 60; // Default voting threshold in percentage
    bool public paused = false;

    enum MembershipStatus { Pending, Active, Revoked }
    struct Member {
        MembershipStatus status;
        uint256 stakeAmount;
        uint256 votingPower; // Dynamic voting power based on stake, contribution, or other factors
        uint256 joinTimestamp;
    }
    mapping(address => Member) public members;
    address[] public memberList;

    enum ProposalStatus { Pending, Voting, Funded, Acquired, Rejected, Cancelled }
    struct ArtProposal {
        uint256 id;
        address proposer;
        string artTitle;
        string artDescription;
        address artistAddress;
        uint256 estimatedCost;
        string artMetadataURI;
        ProposalStatus status;
        uint256 fundingReceived;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 proposalTimestamp;
        mapping(address => bool) public votes; // Track votes per member per proposal
    }
    ArtProposal[] public artProposals;
    uint256 public proposalCounter = 0;

    struct ExhibitionListing {
        uint256 id;
        uint256 artId;
        string exhibitionDetails;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 listingTimestamp;
        mapping(address => bool) public votes; // Track votes per member per listing
    }
    ExhibitionListing[] public exhibitionListings;
    uint256 public listingCounter = 0;

    struct TreasuryWithdrawalRequest {
        uint256 id;
        address requester;
        uint256 amount;
        address recipient;
        string reason;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 requestTimestamp;
        mapping(address => bool) public votes; // Track votes per member per withdrawal request
    }
    TreasuryWithdrawalRequest[] public treasuryWithdrawalRequests;
    uint256 public withdrawalCounter = 0;

    mapping(uint256 => address) public collectionArtIds; // Mapping art IDs to their addresses (or metadata IDs if NFTs)
    uint256 public collectionSize = 0;
    mapping(uint256 => string) public artDetails; // Store basic art details like title, artist, etc. (consider IPFS for richer metadata)

    // --- Events ---
    event MembershipRequested(address indexed memberAddress);
    event MembershipApproved(address indexed memberAddress);
    event MembershipRevoked(address indexed memberAddress);
    event ArtProposalSubmitted(uint256 proposalId, address indexed proposer);
    event VoteCastOnArtProposal(uint256 proposalId, address indexed voter, bool vote);
    event ArtProposalFunded(uint256 proposalId, uint256 amount);
    event ArtAcquisitionFinalized(uint256 proposalId, uint256 artId);
    event ArtProposalCancelled(uint256 proposalId);
    event ArtListedForExhibition(uint256 listingId, uint256 artId);
    event VoteCastOnExhibitionListing(uint256 listingId, address indexed voter, bool vote);
    event ArtRemovedFromExhibition(uint256 listingId, uint256 artId);
    event TreasuryContribution(address indexed contributor, uint256 amount);
    event TreasuryWithdrawalRequested(uint256 withdrawalId, address indexed requester, uint256 amount, address recipient, string reason);
    event VoteCastOnTreasuryWithdrawal(uint256 withdrawalId, address indexed voter, bool vote);
    event TreasuryWithdrawalApproved(uint256 withdrawalId, uint256 amount, address recipient);
    event ContractPaused();
    event ContractUnpaused();
    event EmergencyWithdrawal(address tokenAddress, address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].status == MembershipStatus.Active, "Only active members can call this function.");
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

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < artProposals.length, "Invalid proposal ID.");
        _;
    }

    modifier validListingId(uint256 _listingId) {
        require(_listingId < exhibitionListings.length, "Invalid listing ID.");
        _;
    }

    modifier validWithdrawalId(uint256 _withdrawalId) {
        require(_withdrawalId < treasuryWithdrawalRequests.length, "Invalid withdrawal ID.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(artProposals[_proposalId].status == _status, "Proposal is not in the required status.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- 1. Membership Management Functions ---

    /// @notice Allows users to request membership by staking ETH.
    function joinCollective() external payable whenNotPaused {
        require(msg.value >= membershipStakeAmount, "Insufficient stake amount.");
        require(members[msg.sender].status == MembershipStatus.Revoked || members[msg.sender].status == MembershipStatus.Pending || members[msg.sender].status == MembershipStatus.Active || members[msg.sender].status == MembershipStatus(0), "Already a member or membership pending/active."); // Allow re-joining

        if (members[msg.sender].status == MembershipStatus(0) || members[msg.sender].status == MembershipStatus.Revoked) {
             members[msg.sender] = Member({
                status: MembershipStatus.Pending,
                stakeAmount: msg.value,
                votingPower: 1, // Base voting power, can be adjusted dynamically later
                joinTimestamp: block.timestamp
            });
            memberList.push(msg.sender);
        } else {
            members[msg.sender].status = MembershipStatus.Pending; // Re-request membership
            members[msg.sender].stakeAmount += msg.value; // Add to existing stake
        }

        emit MembershipRequested(msg.sender);
    }

    /// @notice Approves a pending membership request. Only callable by DAO members.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyMember whenNotPaused {
        require(members[_member].status == MembershipStatus.Pending, "Member is not in pending status.");
        members[_member].status = MembershipStatus.Active;
        emit MembershipApproved(_member);
    }

    /// @notice Revokes an existing membership. Only callable by DAO members.
    /// @param _member The address of the member to revoke.
    function revokeMembership(address _member) external onlyMember whenNotPaused {
        require(members[_member].status == MembershipStatus.Active, "Member is not active.");
        members[_member].status = MembershipStatus.Revoked;
        // Consider refunding stake (with governance or conditions) here in a real-world scenario
        emit MembershipRevoked(_member);
    }

    /// @notice Retrieves details of a member.
    /// @param _member The address of the member.
    /// @return status, stakeAmount, votingPower, joinTimestamp
    function getMemberDetails(address _member) external view returns (MembershipStatus status, uint256 stakeAmount, uint256 votingPower, uint256 joinTimestamp) {
        return (members[_member].status, members[_member].stakeAmount, members[_member].votingPower, members[_member].joinTimestamp);
    }

    /// @notice Checks if an address is an active member.
    /// @param _user The address to check.
    /// @return True if the address is an active member, false otherwise.
    function getMembershipStatus(address _user) external view returns (MembershipStatus) {
        return members[_user].status;
    }


    // --- 2. Art Proposal and Acquisition Functions ---

    /// @notice Submits a proposal for acquiring a new artwork. Only callable by members.
    /// @param _artTitle Title of the artwork.
    /// @param _artDescription Description of the artwork.
    /// @param _artistAddress Address of the artist.
    /// @param _estimatedCost Estimated cost of acquiring the artwork.
    /// @param _artMetadataURI URI pointing to the artwork's metadata (e.g., IPFS).
    function submitArtProposal(
        string memory _artTitle,
        string memory _artDescription,
        address _artistAddress,
        uint256 _estimatedCost,
        string memory _artMetadataURI
    ) external onlyMember whenNotPaused {
        proposalCounter++;
        artProposals.push(ArtProposal({
            id: proposalCounter,
            proposer: msg.sender,
            artTitle: _artTitle,
            artDescription: _artDescription,
            artistAddress: _artistAddress,
            estimatedCost: _estimatedCost,
            artMetadataURI: _artMetadataURI,
            status: ProposalStatus.Pending,
            fundingReceived: 0,
            voteCountYes: 0,
            voteCountNo: 0,
            proposalTimestamp: block.timestamp,
            votes: mapping(address => bool)()
        }));
        emit ArtProposalSubmitted(proposalCounter, msg.sender);
    }

    /// @notice Allows members to vote on a pending art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @param _vote True for yes, false for no.
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        require(!artProposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");
        require(block.timestamp < artProposals[_proposalId].proposalTimestamp + votingDuration, "Voting period has ended.");

        artProposals[_proposalId].votes[msg.sender] = true; // Record vote

        if (_vote) {
            artProposals[_proposalId].voteCountYes += members[msg.sender].votingPower; // Weighted voting based on votingPower
        } else {
            artProposals[_proposalId].voteCountNo += members[msg.sender].votingPower;
        }

        uint256 totalVotes = getTotalVotingPower();
        uint256 requiredVotes = (totalVotes * votingThresholdPercentage) / 100;

        if (artProposals[_proposalId].voteCountYes >= requiredVotes) {
            artProposals[_proposalId].status = ProposalStatus.Voting; // Transition to Voting status once threshold is reached (can be adjusted to Funded directly if desired)
        } else if (artProposals[_proposalId].voteCountNo > (totalVotes - requiredVotes)) {
            artProposals[_proposalId].status = ProposalStatus.Rejected;
        }

        emit VoteCastOnArtProposal(_proposalId, msg.sender, _vote);
    }


    /// @notice Allows members to contribute funds towards an approved art proposal.
    /// @param _proposalId ID of the art proposal.
    function fundArtProposal(uint256 _proposalId) external payable onlyMember whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Voting) {
        require(artProposals[_proposalId].fundingReceived < artProposals[_proposalId].estimatedCost, "Funding goal already reached.");

        uint256 contributionAmount = msg.value;
        uint256 remainingFundingNeeded = artProposals[_proposalId].estimatedCost - artProposals[_proposalId].fundingReceived;

        if (contributionAmount > remainingFundingNeeded) {
            contributionAmount = remainingFundingNeeded;
        }

        artProposals[_proposalId].fundingReceived += contributionAmount;
        payable(address(this)).transfer(contributionAmount); // Transfer funds to contract treasury (for simplicity - could be artist directly in advanced scenarios)

        emit ArtProposalFunded(_proposalId, contributionAmount);

        if (artProposals[_proposalId].fundingReceived >= artProposals[_proposalId].estimatedCost) {
            artProposals[_proposalId].status = ProposalStatus.Funded; // Move to Funded status
        }
    }

    /// @notice Finalizes the acquisition of an artwork once the funding goal is reached.
    /// @param _proposalId ID of the art proposal.
    function finalizeArtAcquisition(uint256 _proposalId) external onlyMember whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Funded) {
        // **Advanced Logic Here:**
        // - Mint an NFT representing the artwork (if applicable).
        // - Transfer funds to the artist (or handle acquisition process).
        // - Update collectionArtIds and artDetails mappings.

        collectionSize++;
        collectionArtIds[collectionSize] = artProposals[_proposalId].artistAddress; // Placeholder - replace with actual art identifier (NFT ID, address, etc.)
        artDetails[collectionSize] = artProposals[_proposalId].artTitle; // Placeholder - store basic details

        artProposals[_proposalId].status = ProposalStatus.Acquired;
        emit ArtAcquisitionFinalized(_proposalId, collectionSize);
    }

    /// @notice Allows the proposer to cancel their art proposal before voting starts.
    /// @param _proposalId ID of the art proposal.
    function cancelArtProposal(uint256 _proposalId) external validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        require(artProposals[_proposalId].proposer == msg.sender, "Only proposer can cancel.");
        artProposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ArtProposalCancelled(_proposalId);
    }

    /// @notice Retrieves details of a specific art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return proposal details
    function getArtProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId)
        returns (
            uint256 id,
            address proposer,
            string memory artTitle,
            string memory artDescription,
            address artistAddress,
            uint256 estimatedCost,
            string memory artMetadataURI,
            ProposalStatus status,
            uint256 fundingReceived,
            uint256 voteCountYes,
            uint256 voteCountNo,
            uint256 proposalTimestamp
        )
    {
        ArtProposal storage proposal = artProposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.artTitle,
            proposal.artDescription,
            proposal.artistAddress,
            proposal.estimatedCost,
            proposal.artMetadataURI,
            proposal.status,
            proposal.fundingReceived,
            proposal.voteCountYes,
            proposal.voteCountNo,
            proposal.proposalTimestamp
        );
    }

    /// @notice Gets the current status of an art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return The status of the proposal.
    function getProposalStatus(uint256 _proposalId) external view validProposalId(_proposalId) returns (ProposalStatus) {
        return artProposals[_proposalId].status;
    }

    /// @notice Gets a list of IDs of currently active art proposals (Pending and Voting).
    /// @return Array of active proposal IDs.
    function getActiveArtProposals() external view returns (uint256[] memory) {
        uint256[] memory activeProposals = new uint256[](artProposals.length);
        uint256 count = 0;
        for (uint256 i = 0; i < artProposals.length; i++) {
            if (artProposals[i].status == ProposalStatus.Pending || artProposals[i].status == ProposalStatus.Voting) {
                activeProposals[count] = artProposals[i].id;
                count++;
            }
        }
        assembly { // Efficiently resize the array to the actual number of active proposals
            mstore(activeProposals, count)
        }
        return activeProposals;
    }


    // --- 3. Art Collection Management & Exhibition Functions ---

    /// @notice Proposes to list an acquired artwork for exhibition. Only callable by members.
    /// @param _artId ID of the artwork in the collection.
    /// @param _exhibitionDetails Details about the proposed exhibition (location, dates, etc.).
    function listArtForExhibition(uint256 _artId, string memory _exhibitionDetails) external onlyMember whenNotPaused {
        listingCounter++;
        exhibitionListings.push(ExhibitionListing({
            id: listingCounter,
            artId: _artId,
            exhibitionDetails: _exhibitionDetails,
            voteCountYes: 0,
            voteCountNo: 0,
            listingTimestamp: block.timestamp,
            votes: mapping(address => bool)()
        }));
        emit ArtListedForExhibition(listingCounter, _artId);
    }

    /// @notice Allows members to vote on an artwork exhibition listing proposal.
    /// @param _listingId ID of the exhibition listing proposal.
    /// @param _vote True for yes, false for no.
    function voteOnExhibitionListing(uint256 _listingId, bool _vote) external onlyMember whenNotPaused validListingId(_listingId) {
        require(!exhibitionListings[_listingId].votes[msg.sender], "Already voted on this listing.");
        require(block.timestamp < exhibitionListings[_listingId].listingTimestamp + votingDuration, "Voting period has ended.");

        exhibitionListings[_listingId].votes[msg.sender] = true;

        if (_vote) {
            exhibitionListings[_listingId].voteCountYes += members[msg.sender].votingPower;
        } else {
            exhibitionListings[_listingId].voteCountNo += members[msg.sender].votingPower;
        }

        uint256 totalVotes = getTotalVotingPower();
        uint256 requiredVotes = (totalVotes * votingThresholdPercentage) / 100;

        // In a real scenario, you would handle the outcome (exhibition approved/rejected) based on votes
        // For this example, we just track votes and leave further action to external logic/governance.

        emit VoteCastOnExhibitionListing(_listingId, msg.sender, _vote);
    }

    /// @notice Allows removing art from exhibition (e.g., after exhibition ends or by vote - governance decision).
    /// @param _listingId ID of the exhibition listing to remove art from.
    function removeArtFromExhibition(uint256 _listingId) external onlyMember whenNotPaused validListingId(_listingId) {
        // **Advanced Logic:**
        // - Implement a voting mechanism to remove art from exhibition OR
        // - Allow automatic removal after a set exhibition duration.
        // - Update exhibition status or remove the listing.

        uint256 artIdToRemove = exhibitionListings[_listingId].artId;
        delete exhibitionListings[_listingId]; // For simplicity, just delete the listing. More robust approach: track listing status.
        emit ArtRemovedFromExhibition(_listingId, artIdToRemove);
    }

    /// @notice Retrieves details of a specific exhibition listing.
    /// @param _listingId ID of the exhibition listing.
    /// @return listing details
    function getExhibitionListingDetails(uint256 _listingId) external view validListingId(_listingId)
        returns (
            uint256 id,
            uint256 artId,
            string memory exhibitionDetails,
            uint256 voteCountYes,
            uint256 voteCountNo,
            uint256 listingTimestamp
        )
    {
        ExhibitionListing storage listing = exhibitionListings[_listingId];
        return (
            listing.id,
            listing.artId,
            listing.exhibitionDetails,
            listing.voteCountYes,
            listing.voteCountNo,
            listing.listingTimestamp
        );
    }

    /// @notice Gets a list of IDs of artworks currently in the DAAC collection.
    /// @return Array of art IDs in the collection.
    function getCollectionArtIds() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](collectionSize);
        for (uint256 i = 1; i <= collectionSize; i++) {
            ids[i - 1] = i;
        }
        return ids;
    }

    /// @notice Retrieves details of a specific artwork in the collection (basic details stored in the contract).
    /// @param _artId ID of the artwork in the collection.
    /// @return Basic art details (e.g., title - more metadata can be fetched from artMetadataURI).
    function getArtDetails(uint256 _artId) external view returns (string memory) {
        require(_artId > 0 && _artId <= collectionSize, "Invalid art ID.");
        return artDetails[_artId];
    }


    // --- 4. Revenue and Treasury Management Functions ---

    /// @notice Allows members to voluntarily contribute ETH to the DAAC treasury.
    function contributeToTreasury() external payable whenNotPaused {
        require(msg.value > 0, "Contribution amount must be greater than zero.");
        payable(address(this)).transfer(msg.value); // Transfer funds to contract treasury
        emit TreasuryContribution(msg.sender, msg.value);
    }

    /// @notice Allows members to request a withdrawal from the treasury for collective-related expenses.
    /// @param _amount Amount to withdraw.
    /// @param _recipient Address to receive the withdrawal.
    /// @param _reason Reason for the withdrawal request.
    function requestTreasuryWithdrawal(uint256 _amount, address _recipient, string memory _reason) external onlyMember whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(_recipient != address(0), "Invalid recipient address.");
        require(address(this).balance >= _amount, "Insufficient treasury balance.");

        withdrawalCounter++;
        treasuryWithdrawalRequests.push(TreasuryWithdrawalRequest({
            id: withdrawalCounter,
            requester: msg.sender,
            amount: _amount,
            recipient: _recipient,
            reason: _reason,
            voteCountYes: 0,
            voteCountNo: 0,
            requestTimestamp: block.timestamp,
            votes: mapping(address => bool)()
        }));
        emit TreasuryWithdrawalRequested(withdrawalCounter, msg.sender, _amount, _recipient, _reason);
    }

    /// @notice Allows members to vote on a treasury withdrawal request.
    /// @param _withdrawalId ID of the treasury withdrawal request.
    /// @param _vote True for yes, false for no.
    function voteOnTreasuryWithdrawal(uint256 _withdrawalId, bool _vote) external onlyMember whenNotPaused validWithdrawalId(_withdrawalId) {
        require(!treasuryWithdrawalRequests[_withdrawalId].votes[msg.sender], "Already voted on this withdrawal request.");
        require(block.timestamp < treasuryWithdrawalRequests[_withdrawalId].requestTimestamp + votingDuration, "Voting period has ended.");

        treasuryWithdrawalRequests[_withdrawalId].votes[msg.sender] = true;

        if (_vote) {
            treasuryWithdrawalRequests[_withdrawalId].voteCountYes += members[msg.sender].votingPower;
        } else {
            treasuryWithdrawalRequests[_withdrawalId].voteCountNo += members[msg.sender].votingPower;
        }

        uint256 totalVotes = getTotalVotingPower();
        uint256 requiredVotes = (totalVotes * votingThresholdPercentage) / 100;

        if (treasuryWithdrawalRequests[_withdrawalId].voteCountYes >= requiredVotes) {
            // Withdrawal approved - execute the transfer
            payable(treasuryWithdrawalRequests[_withdrawalId].recipient).transfer(treasuryWithdrawalRequests[_withdrawalId].amount);
            emit TreasuryWithdrawalApproved(_withdrawalId, treasuryWithdrawalRequests[_withdrawalId].amount, treasuryWithdrawalRequests[_withdrawalId].recipient);
            delete treasuryWithdrawalRequests[_withdrawalId]; // Remove request after approval (or mark as processed)
        } else if (treasuryWithdrawalRequests[_withdrawalId].voteCountNo > (totalVotes - requiredVotes)) {
            // Withdrawal rejected - handle rejection logic if needed (e.g., emit event)
            delete treasuryWithdrawalRequests[_withdrawalId]; // Remove rejected request for simplicity
        }

        emit VoteCastOnTreasuryWithdrawal(_withdrawalId, msg.sender, _vote);
    }

    /// @notice Distributes revenue generated by the DAAC to members (proportional to stake - advanced concept).
    /// @param _amount Total revenue amount to distribute.
    function distributeRevenue(uint256 _amount) external onlyOwner whenNotPaused {
        require(_amount > 0, "Revenue amount must be greater than zero.");
        require(address(this).balance >= _amount, "Insufficient treasury balance to distribute.");

        uint256 totalStake = getTotalStake();
        require(totalStake > 0, "No members with stake to distribute revenue to.");

        for (uint256 i = 0; i < memberList.length; i++) {
            address memberAddress = memberList[i];
            if (members[memberAddress].status == MembershipStatus.Active) {
                uint256 memberShare = (_amount * members[memberAddress].stakeAmount) / totalStake;
                if (memberShare > 0) {
                    payable(memberAddress).transfer(memberShare);
                    _amount -= memberShare; // Reduce remaining amount
                }
            }
        }
        // Any remaining amount due to rounding errors stays in the treasury.
    }

    /// @notice Gets the current balance of the DAAC treasury.
    /// @return The treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // --- 5. Governance and Parameter Functions ---

    /// @notice Sets the required stake amount for membership. Only callable by the contract owner.
    /// @param _newStakeAmount The new stake amount in wei.
    function setMembershipStakeAmount(uint256 _newStakeAmount) external onlyOwner whenNotPaused {
        membershipStakeAmount = _newStakeAmount;
    }

    /// @notice Sets the default voting duration for proposals. Only callable by the contract owner.
    /// @param _newDuration The new voting duration in seconds.
    function setVotingDuration(uint256 _newDuration) external onlyOwner whenNotPaused {
        votingDuration = _newDuration;
    }

    /// @notice Sets the voting threshold percentage required for proposal approval. Only callable by the contract owner.
    /// @param _newThreshold The new voting threshold percentage (e.g., 60 for 60%).
    function setVotingThreshold(uint256 _newThreshold) external onlyOwner whenNotPaused {
        require(_newThreshold <= 100, "Voting threshold cannot exceed 100%.");
        votingThresholdPercentage = _newThreshold;
    }

    /// @notice Pauses the contract, preventing most functions from being called. Only callable by the contract owner.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, allowing functions to be called again. Only callable by the contract owner.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Emergency withdrawal function for owner to recover tokens/ETH in critical situations. Use with extreme caution.
    /// @param _tokenAddress Address of the token to withdraw (address(0) for ETH).
    /// @param _recipient Address to receive the withdrawn tokens/ETH.
    /// @param _amount Amount to withdraw.
    function emergencyWithdraw(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner whenPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        if (_tokenAddress == address(0)) {
            payable(_recipient).transfer(_amount);
        } else {
            // **Advanced: Implement token withdrawal logic (ERC20 standard)**
            // For simplicity, assuming a generic token transfer function exists (replace with actual ERC20 call)
            // IERC20(_tokenAddress).transfer(_recipient, _amount); // Requires IERC20 interface import and contract to implement it or import
             (bool success, bytes memory data) = _tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount));
             require(success, "Token transfer failed");
        }
        emit EmergencyWithdrawal(_tokenAddress, _recipient, _amount);
    }

    // --- Helper/Utility Functions ---

    /// @notice Calculates the total voting power of all active members.
    /// @return Total voting power.
    function getTotalVotingPower() internal view returns (uint256) {
        uint256 totalPower = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (members[memberList[i]].status == MembershipStatus.Active) {
                totalPower += members[memberList[i]].votingPower;
            }
        }
        return totalPower;
    }

    /// @notice Calculates the total stake amount of all active members.
    /// @return Total stake amount.
    function getTotalStake() internal view returns (uint256) {
        uint256 totalStakeAmount = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (members[memberList[i]].status == MembershipStatus.Active) {
                totalStakeAmount += members[memberList[i]].stakeAmount;
            }
        }
        return totalStakeAmount;
    }

    receive() external payable {} // Allow contract to receive ETH
}
```