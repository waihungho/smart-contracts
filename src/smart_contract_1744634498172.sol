```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI Assistant
 * @version 1.0

 * @notice This smart contract implements a Decentralized Autonomous Art Collective (DAAC)
 * where artists can submit their artwork, community members can vote to curate the art,
 * and curated art can be minted as NFTs with revenue sharing and collective governance.
 * This contract introduces advanced concepts like decentralized curation, dynamic royalty splitting,
 * community governance through proposals, and interactive art experiences.

 * Function Summary:

 * **Core Art Curation & NFT Minting:**
 * 1. submitArtwork(string _metadataURI): Allows artists to submit their artwork for curation.
 * 2. getArtworkDetails(uint256 _artworkId): Retrieves details of a submitted artwork.
 * 3. voteOnArtwork(uint256 _artworkId, bool _approve): Allows community members to vote on artwork submissions.
 * 4. finalizeArtworkCuration(uint256 _artworkId): Finalizes curation for an artwork, minting NFT if approved.
 * 5. mintNFT(uint256 _artworkId): Mints an NFT for a curated artwork (internal function, triggered by finalization).
 * 6. getNFTDetails(uint256 _tokenId): Retrieves details of a minted NFT.
 * 7. transferNFT(uint256 _tokenId, address _to): Allows NFT owners to transfer their NFTs.

 * **Decentralized Governance & Proposals:**
 * 8. createProposal(string _description, ProposalType _proposalType, bytes _proposalData): Allows members to create governance proposals.
 * 9. getProposalDetails(uint256 _proposalId): Retrieves details of a governance proposal.
 * 10. voteOnProposal(uint256 _proposalId, bool _support): Allows members to vote on governance proposals.
 * 11. executeProposal(uint256 _proposalId): Executes a passed governance proposal.
 * 12. updateCollectiveRules(string _newRules): A proposal execution function to update collective rules.
 * 13. setRoyaltySplit(uint256 _artworkId, uint256 _artistPercentage, uint256 _collectivePercentage): A proposal execution function to set royalty splits for an artwork.

 * **Collective Treasury Management:**
 * 14. depositToTreasury(): Allows anyone to deposit ETH into the collective treasury.
 * 15. withdrawFromTreasury(uint256 _amount): Allows authorized roles to propose and execute treasury withdrawals.
 * 16. getTreasuryBalance(): Retrieves the current balance of the collective treasury.

 * **Community & Membership:**
 * 17. becomeMember(): Allows users to request membership in the collective. (Membership criteria can be added in future versions through governance)
 * 18. approveMembership(address _member): Allows admin/governance to approve membership requests.
 * 19. revokeMembership(address _member): Allows admin/governance to revoke membership.
 * 20. getMemberDetails(address _member): Retrieves details of a collective member.
 * 21. makeAnnouncement(string _announcement): Allows authorized roles to make collective announcements (e.g., about events, exhibitions).
 * 22. getContractVersion(): Returns the contract version.
 * 23. getCollectiveName(): Returns the name of the Art Collective.
 * 24. getRule(uint256 _ruleId): Retrieves specific collective rules.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public collectiveName = "Genesis DAAC";
    string public contractVersion = "1.0";

    // -------- Data Structures --------

    struct ArtworkSubmission {
        address artist;
        string metadataURI;
        uint256 submissionTimestamp;
        uint256 upvotes;
        uint256 downvotes;
        ArtworkStatus status;
        uint256 royaltyArtistPercentage;
        uint256 royaltyCollectivePercentage;
    }

    enum ArtworkStatus {
        Pending,
        Approved,
        Rejected,
        Minted
    }

    struct NFTMetadata {
        string name; // Derived from artwork metadata or defined in submission
        string description; // Derived from artwork metadata or defined in submission
        address artist;
        uint256 artworkId; // Link back to the original artwork submission
    }

    struct Proposal {
        address proposer;
        string description;
        ProposalType proposalType;
        bytes proposalData; // Encoded data specific to the proposal type
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 upvotes;
        uint256 downvotes;
        ProposalStatus status;
    }

    enum ProposalType {
        General,
        TreasuryWithdrawal,
        RuleChange,
        RoyaltyUpdate,
        MembershipAction // To handle membership actions through governance
    }

    enum ProposalStatus {
        Pending,
        Active,
        Passed,
        Rejected,
        Executed
    }

    struct Member {
        address memberAddress;
        uint256 joinTimestamp;
        bool isApproved;
        // Add more member details as needed (e.g., reputation score in future versions)
    }

    // -------- State Variables --------

    mapping(uint256 => ArtworkSubmission) public artworkSubmissions;
    Counters.Counter private _artworkSubmissionCounter;

    mapping(uint256 => NFTMetadata) public nftMetadata;
    Counters.Counter private _nftTokenCounter;

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalCounter;

    mapping(address => Member) public members;
    mapping(address => bool) public membershipRequests; // Track pending membership requests

    address payable public collectiveTreasury;
    string[] public collectiveRules;
    string[] public announcements;

    uint256 public artworkCurationDuration = 7 days; // Default curation duration
    uint256 public proposalVotingDuration = 7 days; // Default proposal voting duration
    uint256 public curationVoteThreshold = 5; // Minimum upvotes to approve artwork (can be changed via governance)
    uint256 public proposalVoteThresholdPercentage = 51; // Percentage of votes needed to pass a proposal (can be changed via governance)

    // -------- Events --------

    event ArtworkSubmitted(uint256 artworkId, address artist, string metadataURI);
    event ArtworkVoted(uint256 artworkId, address voter, bool approved);
    event ArtworkCurationFinalized(uint256 artworkId, ArtworkStatus status);
    event NFTMinted(uint256 tokenId, uint256 artworkId, address artist);
    event NFTTransferred(uint256 tokenId, address from, address to);

    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, ProposalStatus status);

    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);

    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawalRequested(uint256 proposalId, uint256 amount, address recipient); // Proposal ID links to withdrawal proposal
    event AnnouncementMade(uint256 announcementId, string announcement);

    // -------- Modifiers --------

    modifier onlyMembers() {
        require(members[msg.sender].isApproved, "Only approved members can perform this action.");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(msg.sender == owner() /* || isAdmin(msg.sender)  // Future: Implement admin roles via governance */, "Only admin or contract owner can perform this action.");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= _artworkSubmissionCounter.current(), "Invalid artwork ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalCounter.current(), "Invalid proposal ID.");
        _;
    }

    modifier validNFTTokenId(uint256 _tokenId) {
        require(_tokenId > 0 && _tokenId <= _nftTokenCounter.current(), "Invalid NFT token ID.");
        _;
    }

    modifier curationPeriodActive(uint256 _artworkId) {
        require(artworkSubmissions[_artworkId].status == ArtworkStatus.Pending, "Curation period is not active for this artwork.");
        require(block.timestamp < artworkSubmissions[_artworkId].submissionTimestamp + artworkCurationDuration, "Curation period has ended.");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Active, "Voting period is not active for this proposal.");
        require(block.timestamp >= proposals[_proposalId].votingStartTime && block.timestamp <= proposals[_proposalId].votingEndTime, "Voting period is not currently active.");
        _;
    }

    modifier proposalExecutable(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Passed, "Proposal is not passed and cannot be executed.");
        require(proposals[_proposalId].status != ProposalStatus.Executed, "Proposal already executed."); // Prevent re-execution
        _;
    }


    // -------- Constructor --------
    constructor() ERC721("DAAC Artwork", "DAACART") {
        collectiveTreasury = payable(address(this)); // Set treasury to contract address initially
        collectiveRules.push("Default rule: Be respectful and collaborative."); // Initial rules
    }

    // -------- Core Art Curation & NFT Minting Functions --------

    /// @notice Allows artists to submit their artwork for curation.
    /// @param _metadataURI URI pointing to the artwork's metadata (e.g., IPFS link).
    function submitArtwork(string memory _metadataURI) external onlyMembers {
        _artworkSubmissionCounter.increment();
        uint256 artworkId = _artworkSubmissionCounter.current();
        artworkSubmissions[artworkId] = ArtworkSubmission({
            artist: msg.sender,
            metadataURI: _metadataURI,
            submissionTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            status: ArtworkStatus.Pending,
            royaltyArtistPercentage: 70, // Default royalty split - can be changed via proposal
            royaltyCollectivePercentage: 30
        });
        emit ArtworkSubmitted(artworkId, msg.sender, _metadataURI);
    }

    /// @notice Retrieves details of a submitted artwork.
    /// @param _artworkId ID of the artwork submission.
    /// @return ArtworkSubmission struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) external view validArtworkId(_artworkId) returns (ArtworkSubmission memory) {
        return artworkSubmissions[_artworkId];
    }

    /// @notice Allows community members to vote on artwork submissions during the curation period.
    /// @param _artworkId ID of the artwork to vote on.
    /// @param _approve True to upvote, False to downvote.
    function voteOnArtwork(uint256 _artworkId, bool _approve) external onlyMembers validArtworkId(_artworkId) curationPeriodActive(_artworkId) {
        if (_approve) {
            artworkSubmissions[_artworkId].upvotes++;
        } else {
            artworkSubmissions[_artworkId].downvotes++;
        }
        emit ArtworkVoted(_artworkId, msg.sender, _approve);
    }

    /// @notice Finalizes the curation process for an artwork after the curation period.
    /// @param _artworkId ID of the artwork to finalize curation for.
    function finalizeArtworkCuration(uint256 _artworkId) external onlyAdminOrOwner validArtworkId(_artworkId) {
        require(artworkSubmissions[_artworkId].status == ArtworkStatus.Pending, "Curation already finalized for this artwork.");
        if (artworkSubmissions[_artworkId].upvotes >= curationVoteThreshold) {
            artworkSubmissions[_artworkId].status = ArtworkStatus.Approved;
            mintNFT(_artworkId); // Mint NFT if approved
            emit ArtworkCurationFinalized(_artworkId, ArtworkStatus.Approved);
        } else {
            artworkSubmissions[_artworkId].status = ArtworkStatus.Rejected;
            emit ArtworkCurationFinalized(_artworkId, ArtworkStatus.Rejected);
        }
    }

    /// @notice Mints an NFT for a curated artwork (internal function, triggered by finalization).
    /// @param _artworkId ID of the approved artwork.
    function mintNFT(uint256 _artworkId) internal validArtworkId(_artworkId) {
        require(artworkSubmissions[_artworkId].status == ArtworkStatus.Approved, "Artwork must be approved to mint NFT.");
        _nftTokenCounter.increment();
        uint256 tokenId = _nftTokenCounter.current();

        // In a real application, NFTMetadata would be richer and potentially fetched/constructed from _metadataURI
        nftMetadata[tokenId] = NFTMetadata({
            name: string(abi.encodePacked("DAAC Art #", tokenId.toString())), // Simple NFT name
            description: string(abi.encodePacked("A curated artwork from ", collectiveName, ". Artwork ID: ", _artworkId.toString())), // Simple description
            artist: artworkSubmissions[_artworkId].artist,
            artworkId: _artworkId
        });

        _safeMint(artworkSubmissions[_artworkId].artist, tokenId);
        artworkSubmissions[_artworkId].status = ArtworkStatus.Minted;
        emit NFTMinted(tokenId, _artworkId, artworkSubmissions[_artworkId].artist);
    }

    /// @notice Retrieves details of a minted NFT.
    /// @param _tokenId ID of the NFT.
    /// @return NFTMetadata struct containing NFT details.
    function getNFTDetails(uint256 _tokenId) external view validNFTTokenId(_tokenId) returns (NFTMetadata memory) {
        return nftMetadata[_tokenId];
    }

    /// @notice Allows NFT owners to transfer their NFTs.
    /// @param _tokenId ID of the NFT to transfer.
    /// @param _to Address to transfer the NFT to.
    function transferNFT(uint256 _tokenId, address _to) external validNFTTokenId(_tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved.");
        safeTransferFrom(msg.sender, _to, _tokenId);
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }


    // -------- Decentralized Governance & Proposal Functions --------

    /// @notice Allows members to create governance proposals.
    /// @param _description Description of the proposal.
    /// @param _proposalType Type of the proposal (e.g., General, TreasuryWithdrawal).
    /// @param _proposalData Encoded data specific to the proposal type (e.g., withdrawal amount, new rule).
    function createProposal(string memory _description, ProposalType _proposalType, bytes memory _proposalData) external onlyMembers {
        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: _description,
            proposalType: _proposalType,
            proposalData: _proposalData,
            votingStartTime: block.timestamp + 1 days, // Voting starts after 1 day delay
            votingEndTime: block.timestamp + 1 days + proposalVotingDuration,
            upvotes: 0,
            downvotes: 0,
            status: ProposalStatus.Pending
        });
        proposals[proposalId].status = ProposalStatus.Active; // Move to active after creation
        emit ProposalCreated(proposalId, _proposalType, msg.sender, _description);
    }

    /// @notice Retrieves details of a governance proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Allows members to vote on governance proposals during the voting period.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _support True to support, False to oppose.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMembers validProposalId(_proposalId) votingPeriodActive(_proposalId) {
        if (_support) {
            proposals[_proposalId].upvotes++;
        } else {
            proposals[_proposalId].downvotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed governance proposal after the voting period.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyAdminOrOwner validProposalId(_proposalId) proposalExecutable(_proposalId) {
        uint256 totalVotes = proposals[_proposalId].upvotes + proposals[_proposalId].downvotes;
        uint256 requiredVotes = (totalVotes * proposalVoteThresholdPercentage) / 100;

        if (proposals[_proposalId].upvotes >= requiredVotes) {
            proposals[_proposalId].status = ProposalStatus.Passed; // Already marked as passed by modifier, but just in case
            proposals[_proposalId].status = ProposalStatus.Executed;
            ProposalType proposalType = proposals[_proposalId].proposalType;
            bytes memory proposalData = proposals[_proposalId].proposalData;

            if (proposalType == ProposalType.TreasuryWithdrawal) {
                _executeTreasuryWithdrawal(proposalId, proposalData);
            } else if (proposalType == ProposalType.RuleChange) {
                _executeUpdateCollectiveRules(proposalId, proposalData);
            } else if (proposalType == ProposalType.RoyaltyUpdate) {
                _executeSetRoyaltySplit(proposalId, proposalData);
            } else if (proposalType == ProposalType.MembershipAction) {
                _executeMembershipAction(proposalId, proposalData);
            }
            // Add more proposal type executions here as needed
            emit ProposalExecuted(_proposalId, ProposalStatus.Executed);
        } else {
            proposals[_proposalId].status = ProposalStatus.Rejected;
            emit ProposalExecuted(_proposalId, ProposalStatus.Rejected); // Mark as rejected if not passed even if modifier was bypassed somehow
        }
    }

    /// @notice Internal function to execute treasury withdrawal proposals.
    /// @param _proposalId ID of the proposal.
    /// @param _proposalData Encoded data containing withdrawal amount and recipient.
    function _executeTreasuryWithdrawal(uint256 _proposalId, bytes memory _proposalData) internal {
        (uint256 amount, address recipient) = abi.decode(_proposalData, (uint256, address));
        require(address(collectiveTreasury) == address(this), "Treasury address is not contract itself. Security issue."); // Important check for treasury address
        require(address(this).balance >= amount, "Insufficient funds in treasury.");
        payable(recipient).transfer(amount);
        emit TreasuryWithdrawalRequested(_proposalId, amount, recipient);
    }

    /// @notice Internal function to execute rule change proposals.
    /// @param _proposalId ID of the proposal.
    /// @param _proposalData Encoded data containing the new collective rules.
    function _executeUpdateCollectiveRules(uint256 _proposalId, bytes memory _proposalData) internal {
        string memory newRule = abi.decode(_proposalData, (string));
        collectiveRules.push(newRule);
        updateCollectiveRules(newRule); // Call external function for event emission
    }

    /// @notice External function (called from _executeUpdateCollectiveRules) to update and emit rule change event.
    /// @param _newRule The new collective rule to add.
    function updateCollectiveRules(string memory _newRule) public onlyAdminOrOwner {
        // Rule update logic might be more complex, e.g., replacing specific rules in future versions
        // For now, just appending new rules.
        uint256 ruleId = collectiveRules.length -1 ; // Assuming index of last pushed rule is the ID
        // emit RuleUpdated(ruleId, _newRule); // Future event if rule update logic is more sophisticated
    }

    /// @notice Internal function to execute royalty split update proposals.
    /// @param _proposalId ID of the proposal.
    /// @param _proposalData Encoded data containing artwork ID, artist percentage, and collective percentage.
    function _executeSetRoyaltySplit(uint256 _proposalId, bytes memory _proposalData) internal {
        (uint256 artworkId, uint256 artistPercentage, uint256 collectivePercentage) = abi.decode(_proposalData, (uint256, uint256, uint256));
        require(artistPercentage + collectivePercentage == 100, "Royalty percentages must sum to 100.");
        artworkSubmissions[artworkId].royaltyArtistPercentage = artistPercentage;
        artworkSubmissions[artworkId].royaltyCollectivePercentage = collectivePercentage;
        // emit RoyaltySplitUpdated(artworkId, artistPercentage, collectivePercentage); // Future event
    }

    /// @notice Internal function to execute membership action proposals (approve/revoke).
    /// @param _proposalId ID of the proposal.
    /// @param _proposalData Encoded data containing membership action type and member address.
    function _executeMembershipAction(uint256 _proposalId, bytes memory _proposalData) internal {
        (uint8 actionType, address memberAddress) = abi.decode(_proposalData, (uint8, address));
        MembershipActionType membershipAction = MembershipActionType(actionType); // Cast back to enum

        if (membershipAction == MembershipActionType.Approve) {
            approveMembership(memberAddress);
        } else if (membershipAction == MembershipActionType.Revoke) {
            revokeMembership(memberAddress);
        }
    }

    enum MembershipActionType {
        Approve,
        Revoke
    }

    // -------- Collective Treasury Management Functions --------

    /// @notice Allows anyone to deposit ETH into the collective treasury.
    function depositToTreasury() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Allows authorized roles to propose and execute treasury withdrawals (via governance proposal).
    /// @param _amount Amount to withdraw in ETH.
    /// @param _recipient Address to send the withdrawn ETH to.
    // Withdrawal is now governed by proposals, see createProposal and executeProposal
    // function withdrawFromTreasury(uint256 _amount, address payable _recipient) external onlyAdminOrOwner {
    //     require(address(collectiveTreasury) == address(this), "Treasury address is not contract itself. Security issue."); // Important check
    //     require(address(this).balance >= _amount, "Insufficient funds in treasury.");
    //     _recipient.transfer(_amount);
    //     emit TreasuryWithdrawal(msg.sender, _amount, _recipient);
    // }

    /// @notice Retrieves the current balance of the collective treasury.
    /// @return Current ETH balance of the contract (treasury).
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // -------- Community & Membership Functions --------

    /// @notice Allows users to request membership in the collective.
    function becomeMember() external {
        require(!members[msg.sender].isApproved, "Already a member.");
        require(!membershipRequests[msg.sender], "Membership request already pending.");
        membershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Allows admin/governance to approve membership requests.
    /// @param _member Address of the member to approve.
    function approveMembership(address _member) public onlyAdminOrOwner {
        require(membershipRequests[_member], "No membership request pending for this address.");
        require(!members[_member].isApproved, "Address is already a member.");
        members[_member] = Member({
            memberAddress: _member,
            joinTimestamp: block.timestamp,
            isApproved: true
        });
        membershipRequests[_member] = false; // Clear request
        emit MembershipApproved(_member);
    }

    /// @notice Allows admin/governance to revoke membership.
    /// @param _member Address of the member to revoke.
    function revokeMembership(address _member) public onlyAdminOrOwner {
        require(members[_member].isApproved, "Address is not a member.");
        members[_member].isApproved = false;
        emit MembershipRevoked(_member);
    }

    /// @notice Retrieves details of a collective member.
    /// @param _member Address of the member.
    /// @return Member struct containing member details.
    function getMemberDetails(address _member) external view returns (Member memory) {
        return members[_member];
    }

    /// @notice Allows authorized roles to make collective announcements.
    /// @param _announcement The announcement message.
    function makeAnnouncement(string memory _announcement) external onlyAdminOrOwner {
        announcements.push(_announcement);
        emit AnnouncementMade(announcements.length - 1, _announcement);
    }

    /// @notice Retrieves a specific collective rule.
    /// @param _ruleId ID of the rule (index in the rules array).
    /// @return The collective rule string.
    function getRule(uint256 _ruleId) external view returns (string memory) {
        require(_ruleId < collectiveRules.length, "Invalid rule ID.");
        return collectiveRules[_ruleId];
    }

    /// @notice Returns the contract version.
    /// @return Contract version string.
    function getContractVersion() public view returns (string memory) {
        return contractVersion;
    }

    /// @notice Returns the name of the Art Collective.
    /// @return Collective name string.
    function getCollectiveName() public view returns (string memory) {
        return collectiveName;
    }

    // -------- Fallback and Receive functions --------
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value); // Allow direct ETH deposits to treasury
    }

    fallback() external {}
}
```