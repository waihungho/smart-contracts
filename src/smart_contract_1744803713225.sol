```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A creative and advanced smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *      This contract allows artists to submit artwork, community members to curate and vote on art,
 *      mint NFTs representing the artwork, manage a treasury, and govern the collective's direction
 *      through decentralized proposals and voting. It incorporates advanced concepts like dynamic royalties,
 *      tiered membership, on-chain reputation, and collaborative art features.
 *
 * Function Summary:
 *
 * **Membership & Reputation:**
 * 1. joinCollective(string _artistStatement): Allows artists to request membership in the collective.
 * 2. approveArtistMembership(address _artist):  Governance function to approve pending artist membership.
 * 3. rejectArtistMembership(address _artist): Governance function to reject pending artist membership.
 * 4. leaveCollective(): Allows members to leave the collective.
 * 5. getMemberReputation(address _member): Returns the reputation score of a member.
 * 6. contributeToReputation(address _member, uint256 _amount): Allows members to contribute to another member's reputation.
 * 7. setMembershipTierThreshold(uint256 _tier, uint256 _threshold): Governance function to set reputation threshold for membership tiers.
 * 8. getMembershipTier(address _member): Returns the membership tier of a member based on reputation.
 *
 * **Art Submission & Curation:**
 * 9. submitArtwork(string _artworkTitle, string _artworkURI): Allows members to submit artwork for curation.
 * 10. voteOnArtwork(uint256 _submissionId, bool _approve): Allows members to vote on submitted artwork.
 * 11. finalizeArtworkCuration(uint256 _submissionId): Governance function to finalize artwork curation after voting period.
 * 12. getArtworkSubmissionStatus(uint256 _submissionId): Returns the status of an artwork submission.
 * 13. getApprovedArtworkCount(): Returns the total count of approved artworks.
 * 14. getRandomApprovedArtworkId(): Returns a random ID of an approved artwork.
 *
 * **NFT Minting & Sales:**
 * 15. mintArtworkNFT(uint256 _submissionId): Mints an NFT for an approved artwork (governance or auto-mint based on votes).
 * 16. setNFTSalePrice(uint256 _artworkId, uint256 _price): Governance function to set the sale price for an artwork NFT.
 * 17. purchaseNFT(uint256 _artworkId): Allows users to purchase an artwork NFT.
 * 18. getNFTArtistRoyalty(uint256 _artworkId): Returns the artist's royalty percentage for an NFT.
 * 19. setDynamicArtistRoyalty(uint256 _artworkId, uint256 _baseRoyalty, uint256 _reputationMultiplier): Governance function to set dynamic royalties based on reputation.
 *
 * **Treasury & Governance:**
 * 20. depositToTreasury(): Allows anyone to deposit funds into the collective treasury.
 * 21. proposeTreasurySpending(address _recipient, uint256 _amount, string _proposalDescription): Allows members to propose spending from the treasury.
 * 22. voteOnTreasuryProposal(uint256 _proposalId, bool _approve): Allows members to vote on treasury spending proposals.
 * 23. finalizeTreasuryProposal(uint256 _proposalId): Governance function to finalize treasury proposals after voting period.
 * 24. getTreasuryBalance(): Returns the current balance of the collective treasury.
 * 25. setVotingDuration(uint256 _durationInBlocks): Governance function to set the voting duration for proposals.
 * 26. setQuorumPercentage(uint256 _percentage): Governance function to set the quorum percentage for proposals.
 * 27. withdrawGovernanceFees(uint256 _amount): Governance function to withdraw fees collected by the contract (e.g., from NFT sales).
 * 28. getGovernanceFeePercentage(): Returns the current governance fee percentage.
 * 29. setGovernanceFeePercentage(uint256 _percentage): Governance function to set the governance fee percentage on NFT sales.
 */

contract DecentralizedAutonomousArtCollective {

    // **********************
    // *     Data Structures   *
    // **********************

    enum MembershipStatus { Pending, Approved, Rejected, Member }
    enum ArtworkStatus { Submitted, CurationInProgress, Approved, Rejected, Minted }
    enum ProposalStatus { Active, Passed, Rejected, Finalized }

    struct ArtistMembershipRequest {
        address artistAddress;
        string artistStatement;
        MembershipStatus status;
    }

    struct ArtworkSubmission {
        uint256 id;
        address artist;
        string title;
        string artworkURI;
        ArtworkStatus status;
        uint256 upvotes;
        uint256 downvotes;
    }

    struct NFTArtwork {
        uint256 id;
        uint256 submissionId;
        address artist;
        string artworkURI;
        uint256 salePrice;
        uint256 artistRoyaltyPercentage; // Base royalty
        uint256 reputationMultiplier;   // For dynamic royalties
        bool forSale;
    }

    struct TreasuryProposal {
        uint256 id;
        address proposer;
        address recipient;
        uint256 amount;
        string description;
        ProposalStatus status;
        uint256 upvotes;
        uint256 downvotes;
    }

    struct MembershipTier {
        uint256 threshold;
        string tierName;
    }


    // **********************
    // *      State Variables    *
    // **********************

    address public governanceAddress;
    uint256 public nextSubmissionId = 1;
    uint256 public nextNFTArtworkId = 1;
    uint256 public nextProposalId = 1;
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 50;      // Default quorum percentage for proposals
    uint256 public governanceFeePercentage = 5; // Percentage of NFT sales for governance

    mapping(address => ArtistMembershipRequest) public membershipRequests;
    mapping(address => bool) public isMember;
    mapping(address => uint256) public memberReputation;
    MembershipTier[] public membershipTiers; // Array of membership tiers and their reputation thresholds

    mapping(uint256 => ArtworkSubmission) public artworkSubmissions;
    mapping(uint256 => NFTArtwork) public nftArtworks;
    mapping(uint256 => TreasuryProposal) public treasuryProposals;
    mapping(uint256 => address[]) public artworkVotes; //submissionId => voters array
    mapping(uint256 => address[]) public proposalVotes; //proposalId => voters array
    mapping(uint256 => bool) public artworkNFTMinted; // To track if NFT is minted for a submission

    address[] public membersList;
    uint256[] public approvedArtworkIds; // Array to store IDs of approved artworks for random selection

    // **********************
    // *        Events         *
    // **********************

    event MembershipRequested(address artist, string statement);
    event MembershipApproved(address artist);
    event MembershipRejected(address artist);
    event MembershipLeft(address member);
    event ReputationContributed(address contributor, address member, uint256 amount);

    event ArtworkSubmitted(uint256 submissionId, address artist, string title);
    event ArtworkVoted(uint256 submissionId, address voter, bool approve);
    event ArtworkCurationFinalized(uint256 submissionId, ArtworkStatus status);
    event ArtworkNFTMinted(uint256 nftId, uint256 submissionId, address artist);
    event NFTPurchase(uint256 nftId, address buyer, uint256 price);
    event NFTSalePriceSet(uint256 nftId, uint256 price);
    event DynamicRoyaltySet(uint256 nftId, uint256 baseRoyalty, uint256 multiplier);

    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasuryProposalCreated(uint256 proposalId, address proposer, address recipient, uint256 amount, string description);
    event TreasuryProposalVoted(uint256 proposalId, address voter, bool approve);
    event TreasuryProposalFinalized(uint256 proposalId, ProposalStatus status);
    event GovernanceFeesWithdrawn(address governance, uint256 amount);
    event GovernanceFeePercentageSet(uint256 percentage);
    event VotingDurationSet(uint256 durationBlocks);
    event QuorumPercentageSet(uint256 percentage);
    event MembershipTierThresholdSet(uint256 tierIndex, uint256 threshold);


    // **********************
    // *    Modifiers         *
    // **********************

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance can call this function");
        _;
    }

    modifier onlyMembers() {
        require(isMember[msg.sender], "Only members can call this function");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId < nextSubmissionId, "Invalid submission ID");
        _;
    }

    modifier validNFTArtworkId(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId < nextNFTArtworkId, "Invalid NFT artwork ID");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID");
        _;
    }

    modifier submissionInStatus(uint256 _submissionId, ArtworkStatus _status) {
        require(artworkSubmissions[_submissionId].status == _status, "Submission not in required status");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(treasuryProposals[_proposalId].status == _status, "Proposal not in required status");
        _;
    }

    modifier notVotedOnArtwork(uint256 _submissionId) {
        for (uint256 i = 0; i < artworkVotes[_submissionId].length; i++) {
            require(artworkVotes[_submissionId][i] != msg.sender, "Already voted on this artwork");
        }
        _;
    }

    modifier notVotedOnProposal(uint256 _proposalId) {
        for (uint256 i = 0; i < proposalVotes[_proposalId].length; i++) {
            require(proposalVotes[_proposalId][i] != msg.sender, "Already voted on this proposal");
        }
        _;
    }


    // **********************
    // *    Constructor       *
    // **********************

    constructor() {
        governanceAddress = msg.sender;
        // Initialize default membership tiers (example)
        membershipTiers.push(MembershipTier({threshold: 0, tierName: "Initiate"}));
        membershipTiers.push(MembershipTier({threshold: 100, tierName: "Apprentice"}));
        membershipTiers.push(MembershipTier({threshold: 500, tierName: "Artisan"}));
        membershipTiers.push(MembershipTier({threshold: 1000, tierName: "Master"}));
    }


    // ********************************************************
    // *              Membership & Reputation Functions       *
    // ********************************************************

    /// @notice Allows artists to request membership in the collective.
    /// @param _artistStatement A statement from the artist about their work and interest in the collective.
    function joinCollective(string memory _artistStatement) public {
        require(!isMember[msg.sender], "Already a member");
        require(membershipRequests[msg.sender].status != MembershipStatus.Pending, "Membership request already pending");

        membershipRequests[msg.sender] = ArtistMembershipRequest({
            artistAddress: msg.sender,
            artistStatement: _artistStatement,
            status: MembershipStatus.Pending
        });
        emit MembershipRequested(msg.sender, _artistStatement);
    }

    /// @notice Governance function to approve pending artist membership.
    /// @param _artist Address of the artist to approve.
    function approveArtistMembership(address _artist) public onlyGovernance {
        require(membershipRequests[_artist].status == MembershipStatus.Pending, "No pending membership request");
        membershipRequests[_artist].status = MembershipStatus.Approved;
        isMember[_artist] = true;
        membersList.push(_artist);
        emit MembershipApproved(_artist);
    }

    /// @notice Governance function to reject pending artist membership.
    /// @param _artist Address of the artist to reject.
    function rejectArtistMembership(address _artist) public onlyGovernance {
        require(membershipRequests[_artist].status == MembershipStatus.Pending, "No pending membership request");
        membershipRequests[_artist].status = MembershipStatus.Rejected;
        emit MembershipRejected(_artist);
    }

    /// @notice Allows members to leave the collective.
    function leaveCollective() public onlyMembers {
        isMember[msg.sender] = false;
        // Remove from membersList (optional, for gas optimization in large lists, consider alternative list implementation)
        for (uint256 i = 0; i < membersList.length; i++) {
            if (membersList[i] == msg.sender) {
                membersList[i] = membersList[membersList.length - 1];
                membersList.pop();
                break;
            }
        }
        emit MembershipLeft(msg.sender);
    }

    /// @notice Returns the reputation score of a member.
    /// @param _member Address of the member.
    /// @return uint256 Reputation score.
    function getMemberReputation(address _member) public view returns (uint256) {
        return memberReputation[_member];
    }

    /// @notice Allows members to contribute to another member's reputation.
    /// @param _member Address of the member to contribute to.
    /// @param _amount Amount of reputation to contribute.
    function contributeToReputation(address _member, uint256 _amount) public onlyMembers {
        require(_member != msg.sender, "Cannot contribute to own reputation");
        memberReputation[_member] += _amount;
        emit ReputationContributed(msg.sender, _member, _amount);
    }

    /// @notice Governance function to set reputation threshold for membership tiers.
    /// @param _tier Index of the membership tier to modify.
    /// @param _threshold New reputation threshold for the tier.
    function setMembershipTierThreshold(uint256 _tier, uint256 _threshold) public onlyGovernance {
        require(_tier < membershipTiers.length, "Invalid tier index");
        membershipTiers[_tier].threshold = _threshold;
        emit MembershipTierThresholdSet(_tier, _threshold);
    }

    /// @notice Returns the membership tier of a member based on reputation.
    /// @param _member Address of the member.
    /// @return string Membership tier name.
    function getMembershipTier(address _member) public view returns (string memory) {
        uint256 reputation = memberReputation[_member];
        for (uint256 i = membershipTiers.length - 1; i >= 0; i--) {
            if (reputation >= membershipTiers[i].threshold) {
                return membershipTiers[i].tierName;
            }
        }
        return "Non-Tiered"; // Should not reach here if tiers are set up correctly
    }


    // ********************************************************
    // *             Art Submission & Curation Functions      *
    // ********************************************************

    /// @notice Allows members to submit artwork for curation.
    /// @param _artworkTitle Title of the artwork.
    /// @param _artworkURI URI pointing to the artwork (e.g., IPFS).
    function submitArtwork(string memory _artworkTitle, string memory _artworkURI) public onlyMembers {
        artworkSubmissions[nextSubmissionId] = ArtworkSubmission({
            id: nextSubmissionId,
            artist: msg.sender,
            title: _artworkTitle,
            artworkURI: _artworkURI,
            status: ArtworkStatus.Submitted,
            upvotes: 0,
            downvotes: 0
        });
        emit ArtworkSubmitted(nextSubmissionId, msg.sender, _artworkTitle);
        nextSubmissionId++;
    }

    /// @notice Allows members to vote on submitted artwork.
    /// @param _submissionId ID of the artwork submission.
    /// @param _approve True for upvote, false for downvote.
    function voteOnArtwork(uint256 _submissionId, bool _approve)
        public
        onlyMembers
        validSubmissionId(_submissionId)
        submissionInStatus(_submissionId, ArtworkStatus.Submitted)
        notVotedOnArtwork(_submissionId)
    {
        artworkVotes[_submissionId].push(msg.sender);
        if (_approve) {
            artworkSubmissions[_submissionId].upvotes++;
        } else {
            artworkSubmissions[_submissionId].downvotes++;
        }
        emit ArtworkVoted(_submissionId, msg.sender, _approve);
    }

    /// @notice Governance function to finalize artwork curation after voting period.
    ///         Could also be automated based on time/block number in a more advanced version.
    /// @param _submissionId ID of the artwork submission.
    function finalizeArtworkCuration(uint256 _submissionId)
        public
        onlyGovernance
        validSubmissionId(_submissionId)
        submissionInStatus(_submissionId, ArtworkStatus.Submitted)
    {
        uint256 totalVotes = artworkSubmissions[_submissionId].upvotes + artworkSubmissions[_submissionId].downvotes;
        if (totalVotes > 0 && (artworkSubmissions[_submissionId].upvotes * 100) / totalVotes >= quorumPercentage) {
            artworkSubmissions[_submissionId].status = ArtworkStatus.Approved;
            approvedArtworkIds.push(_submissionId); // Add to approved artwork list
        } else {
            artworkSubmissions[_submissionId].status = ArtworkStatus.Rejected;
        }
        emit ArtworkCurationFinalized(_submissionId, artworkSubmissions[_submissionId].status);
    }

    /// @notice Returns the status of an artwork submission.
    /// @param _submissionId ID of the artwork submission.
    /// @return ArtworkStatus Status of the submission.
    function getArtworkSubmissionStatus(uint256 _submissionId) public view validSubmissionId(_submissionId) returns (ArtworkStatus) {
        return artworkSubmissions[_submissionId].status;
    }

    /// @notice Returns the total count of approved artworks.
    /// @return uint256 Count of approved artworks.
    function getApprovedArtworkCount() public view returns (uint256) {
        return approvedArtworkIds.length;
    }

    /// @notice Returns a random ID of an approved artwork.
    ///         Uses blockhash for pseudo-randomness (consider Chainlink VRF for production).
    /// @return uint256 Random artwork ID, or 0 if no approved artworks.
    function getRandomApprovedArtworkId() public view returns (uint256) {
        if (approvedArtworkIds.length == 0) {
            return 0;
        }
        uint256 randomIndex = uint256(blockhash(block.number - 1)) % approvedArtworkIds.length;
        return approvedArtworkIds[randomIndex];
    }


    // ********************************************************
    // *                  NFT Minting & Sales Functions       *
    // ********************************************************

    /// @notice Mints an NFT for an approved artwork (governance function).
    ///         Could be automated in the finalizeArtworkCuration function for more decentralized approach.
    /// @param _submissionId ID of the approved artwork submission.
    function mintArtworkNFT(uint256 _submissionId)
        public
        onlyGovernance
        validSubmissionId(_submissionId)
        submissionInStatus(_submissionId, ArtworkStatus.Approved)
    {
        require(!artworkNFTMinted[_submissionId], "NFT already minted for this artwork");

        NFTArtwork memory newNFT = NFTArtwork({
            id: nextNFTArtworkId,
            submissionId: _submissionId,
            artist: artworkSubmissions[_submissionId].artist,
            artworkURI: artworkSubmissions[_submissionId].artworkURI,
            salePrice: 0, // Set initial sale price to 0, governance sets later
            artistRoyaltyPercentage: 10, // Default artist royalty 10%
            reputationMultiplier: 1,     // Default multiplier
            forSale: false
        });
        nftArtworks[nextNFTArtworkId] = newNFT;
        artworkNFTMinted[_submissionId] = true;
        artworkSubmissions[_submissionId].status = ArtworkStatus.Minted;

        emit ArtworkNFTMinted(nextNFTArtworkId, _submissionId, artworkSubmissions[_submissionId].artist);
        nextNFTArtworkId++;
    }

    /// @notice Governance function to set the sale price for an artwork NFT.
    /// @param _artworkId ID of the NFT artwork.
    /// @param _price Sale price in wei.
    function setNFTSalePrice(uint256 _artworkId, uint256 _price)
        public
        onlyGovernance
        validNFTArtworkId(_artworkId)
    {
        nftArtworks[_artworkId].salePrice = _price;
        nftArtworks[_artworkId].forSale = true;
        emit NFTSalePriceSet(_artworkId, _price);
    }

    /// @notice Allows users to purchase an artwork NFT.
    /// @param _artworkId ID of the NFT artwork to purchase.
    function purchaseNFT(uint256 _artworkId)
        public
        payable
        validNFTArtworkId(_artworkId)
    {
        require(nftArtworks[_artworkId].forSale, "NFT is not for sale");
        require(msg.value >= nftArtworks[_artworkId].salePrice, "Insufficient payment");

        uint256 salePrice = nftArtworks[_artworkId].salePrice;

        // Calculate governance fee
        uint256 governanceFee = (salePrice * governanceFeePercentage) / 100;

        // Calculate artist royalty (using dynamic royalty if set)
        uint256 artistRoyaltyPercentage = getNFTArtistRoyalty(_artworkId);
        uint256 artistRoyalty = (salePrice * artistRoyaltyPercentage) / 100;

        // Calculate artist payout (after governance fee)
        uint256 artistPayout = salePrice - governanceFee - artistRoyalty;

        // Transfer funds
        payable(nftArtworks[_artworkId].artist).transfer(artistPayout);
        payable(governanceAddress).transfer(governanceFee);
        payable(address(this)).transfer(artistRoyalty); // Hold royalty in contract to be withdrawn later, or distribute immediately based on requirements

        nftArtworks[_artworkId].forSale = false; // Mark as sold (or update ownership logic if needed for NFT standards)

        emit NFTPurchase(_artworkId, msg.sender, salePrice);

        // Return any excess payment
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }
    }

    /// @notice Returns the artist's royalty percentage for an NFT, considering dynamic royalties.
    /// @param _artworkId ID of the NFT artwork.
    /// @return uint256 Artist royalty percentage.
    function getNFTArtistRoyalty(uint256 _artworkId) public view validNFTArtworkId(_artworkId) returns (uint256) {
        uint256 baseRoyalty = nftArtworks[_artworkId].artistRoyaltyPercentage;
        uint256 reputationMultiplier = nftArtworks[_artworkId].reputationMultiplier;
        uint256 artistReputation = memberReputation[nftArtworks[_artworkId].artist];

        // Example dynamic royalty calculation: Royalty increases with reputation
        uint256 dynamicRoyalty = baseRoyalty + (artistReputation / 100) * reputationMultiplier; // Example formula
        return dynamicRoyalty <= 100 ? dynamicRoyalty : 100; // Cap at 100%
    }

    /// @notice Governance function to set dynamic royalties for an NFT based on base royalty and reputation multiplier.
    /// @param _artworkId ID of the NFT artwork.
    /// @param _baseRoyalty Base artist royalty percentage.
    /// @param _reputationMultiplier Multiplier factor for reputation influence on royalty.
    function setDynamicArtistRoyalty(uint256 _artworkId, uint256 _baseRoyalty, uint256 _reputationMultiplier)
        public
        onlyGovernance
        validNFTArtworkId(_artworkId)
    {
        nftArtworks[_artworkId].artistRoyaltyPercentage = _baseRoyalty;
        nftArtworks[_artworkId].reputationMultiplier = _reputationMultiplier;
        emit DynamicRoyaltySet(_artworkId, _baseRoyalty, _reputationMultiplier);
    }


    // ********************************************************
    // *                Treasury & Governance Functions        *
    // ********************************************************

    /// @notice Allows anyone to deposit funds into the collective treasury.
    function depositToTreasury() public payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Allows members to propose spending from the treasury.
    /// @param _recipient Address to receive the funds.
    /// @param _amount Amount to spend in wei.
    /// @param _proposalDescription Description of the spending proposal.
    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _proposalDescription) public onlyMembers {
        require(_recipient != address(0) && _recipient != address(this), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient treasury balance for proposal");

        treasuryProposals[nextProposalId] = TreasuryProposal({
            id: nextProposalId,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            description: _proposalDescription,
            status: ProposalStatus.Active,
            upvotes: 0,
            downvotes: 0
        });
        emit TreasuryProposalCreated(nextProposalId, msg.sender, _recipient, _amount, _proposalDescription);
        nextProposalId++;
    }

    /// @notice Allows members to vote on treasury spending proposals.
    /// @param _proposalId ID of the treasury proposal.
    /// @param _approve True for upvote, false for downvote.
    function voteOnTreasuryProposal(uint256 _proposalId, bool _approve)
        public
        onlyMembers
        validProposalId(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Active)
        notVotedOnProposal(_proposalId)
    {
        proposalVotes[_proposalId].push(msg.sender);
        if (_approve) {
            treasuryProposals[_proposalId].upvotes++;
        } else {
            treasuryProposals[_proposalId].downvotes++;
        }
        emit TreasuryProposalVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Governance function to finalize treasury proposals after voting period.
    /// @param _proposalId ID of the treasury proposal.
    function finalizeTreasuryProposal(uint256 _proposalId)
        public
        onlyGovernance
        validProposalId(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Active)
    {
        uint256 totalVotes = treasuryProposals[_proposalId].upvotes + treasuryProposals[_proposalId].downvotes;
        if (totalVotes > 0 && (treasuryProposals[_proposalId].upvotes * 100) / totalVotes >= quorumPercentage) {
            treasuryProposals[_proposalId].status = ProposalStatus.Passed;
            // Transfer funds if proposal passed
            payable(treasuryProposals[_proposalId].recipient).transfer(treasuryProposals[_proposalId].amount);
        } else {
            treasuryProposals[_proposalId].status = ProposalStatus.Rejected;
        }
        treasuryProposals[_proposalId].status = ProposalStatus.Finalized; // Mark as finalized regardless of outcome
        emit TreasuryProposalFinalized(_proposalId, treasuryProposals[_proposalId].status);
    }

    /// @notice Returns the current balance of the collective treasury.
    /// @return uint256 Treasury balance in wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Governance function to set the voting duration for proposals.
    /// @param _durationInBlocks Voting duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) public onlyGovernance {
        votingDurationBlocks = _durationInBlocks;
        emit VotingDurationSet(_durationInBlocks);
    }

    /// @notice Governance function to set the quorum percentage for proposals.
    /// @param _percentage Quorum percentage (e.g., 50 for 50%).
    function setQuorumPercentage(uint256 _percentage) public onlyGovernance {
        require(_percentage <= 100, "Quorum percentage must be between 0 and 100");
        quorumPercentage = _percentage;
        emit QuorumPercentageSet(_percentage);
    }

    /// @notice Governance function to withdraw fees collected by the contract (e.g., from NFT sales).
    /// @param _amount Amount to withdraw in wei.
    function withdrawGovernanceFees(uint256 _amount) public onlyGovernance {
        require(address(this).balance >= _amount, "Insufficient contract balance for withdrawal");
        payable(governanceAddress).transfer(_amount);
        emit GovernanceFeesWithdrawn(governanceAddress, _amount);
    }

    /// @notice Returns the current governance fee percentage.
    /// @return uint256 Governance fee percentage.
    function getGovernanceFeePercentage() public view returns (uint256) {
        return governanceFeePercentage;
    }

    /// @notice Governance function to set the governance fee percentage on NFT sales.
    /// @param _percentage Governance fee percentage (e.g., 5 for 5%).
    function setGovernanceFeePercentage(uint256 _percentage) public onlyGovernance {
        require(_percentage <= 100, "Governance fee percentage must be between 0 and 100");
        governanceFeePercentage = _percentage;
        emit GovernanceFeePercentageSet(_percentage);
    }
}
```