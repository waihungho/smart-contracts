```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to submit, curate, and monetize their digital art.
 *
 * Function Summary:
 * -----------------
 * **Core Art Submission & Curation:**
 * 1. submitArt(string _title, string _ipfsHash, string _description): Allows members to submit their artwork for curation.
 * 2. voteOnArt(uint256 _submissionId, bool _approve): Members can vote on submitted artwork to decide if it gets accepted into the collective.
 * 3. finalizeArtSubmission(uint256 _submissionId): Automatically finalizes art submission after voting period, minting NFT if approved.
 * 4. getArtSubmission(uint256 _submissionId): View function to retrieve details of a specific art submission.
 * 5. getAllPendingSubmissions(): View function to get a list of IDs of pending art submissions.
 * 6. getApprovedArtworks(): View function to get a list of IDs of approved and minted artworks.
 * 7. rejectArtSubmission(uint256 _submissionId): Admin function to manually reject an art submission before voting ends (in exceptional cases).
 *
 * **NFT Minting & Management:**
 * 8. mintArtNFT(uint256 _submissionId): Mints an NFT for an approved artwork submission (internal function, called by finalizeArtSubmission).
 * 9. setNFTMetadataBaseURI(string _baseURI): Admin function to set the base URI for NFT metadata.
 * 10. tokenURI(uint256 _tokenId): Public view function to get the URI for a specific artwork NFT.
 * 11. burnArtNFT(uint256 _tokenId): Admin function to burn a specific artwork NFT (in case of issues like copyright infringement).
 *
 * **Collective Membership & Governance:**
 * 12. joinCollective(): Allows users to request membership in the art collective.
 * 13. approveMembership(address _member): Admin function to approve a pending membership request.
 * 14. revokeMembership(address _member): Admin function to revoke membership from an address.
 * 15. proposeGovernanceChange(string _proposalDescription, bytes memory _calldata): Members can propose changes to the contract parameters or logic.
 * 16. voteOnGovernanceProposal(uint256 _proposalId, bool _support): Members can vote on governance proposals.
 * 17. executeGovernanceProposal(uint256 _proposalId): Admin function to execute an approved governance proposal.
 * 18. getMemberDetails(address _member): View function to get details of a collective member (e.g., join date, reputation - if implemented).
 * 19. getPendingMembershipRequests(): Admin view function to get a list of addresses requesting membership.
 *
 * **Utility & Admin Functions:**
 * 20. pauseContract(): Admin function to pause core contract functionalities in case of emergency.
 * 21. unpauseContract(): Admin function to resume contract functionalities.
 * 22. setVotingPeriod(uint256 _newVotingPeriod): Admin function to change the voting period for art submissions and governance proposals.
 * 23. setApprovalThreshold(uint256 _newThresholdPercentage): Admin function to change the approval threshold for art submissions.
 * 24. withdrawContractBalance(): Admin function to withdraw funds from the contract balance (e.g., accumulated royalties).
 * 25. setAdmin(address _newAdmin): Admin function to change the contract admin address.
 */
contract DecentralizedArtCollective {
    // -------- State Variables --------

    address public admin;
    bool public paused;
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public approvalThresholdPercentage = 60; // Percentage of votes needed for approval
    string public nftMetadataBaseURI;
    uint256 public submissionCounter = 0;
    uint256 public proposalCounter = 0;

    // Struct to represent an art submission
    struct ArtSubmission {
        uint256 id;
        address artist;
        string title;
        string ipfsHash; // IPFS hash of the artwork data
        string description;
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        mapping(address => bool) hasVoted; // Track who has voted
        SubmissionStatus status;
    }

    enum SubmissionStatus {
        Pending,
        Approved,
        Rejected,
        Minted
    }

    // Struct for governance proposals
    struct GovernanceProposal {
        uint256 id;
        string description;
        bytes calldataData; // Calldata to execute if proposal passes
        uint256 votingEndTime;
        uint256 supportVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted;
        ProposalStatus status;
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected,
        Executed
    }

    mapping(uint256 => ArtSubmission) public artSubmissions;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => bool) public members;
    mapping(address => bool) public pendingMembershipRequests;
    mapping(uint256 => address) public artworkTokenToArtist; // Mapping tokenId to artist address
    mapping(uint256 => uint256) public artworkTokenToSubmissionId; // Mapping tokenId to submissionId
    uint256 public nextArtworkTokenId = 1;

    // -------- Events --------

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event VotingPeriodChanged(uint256 newVotingPeriod);
    event ApprovalThresholdChanged(uint256 newThresholdPercentage);
    event NFTMetadataBaseURISet(string baseURI);
    event ArtSubmitted(uint256 submissionId, address artist, string title);
    event VoteCastOnArt(uint256 submissionId, address voter, bool approve);
    event ArtSubmissionFinalized(uint256 submissionId, SubmissionStatus status);
    event ArtNFTMinted(uint256 tokenId, uint256 submissionId, address artist);
    event ArtNFTBurned(uint256 tokenId);
    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event VoteCastOnGovernanceProposal(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId, ProposalStatus status);
    event FundsWithdrawn(address admin, uint256 amount);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        emit AdminChanged(address(0), admin);
    }

    // -------- Core Art Submission & Curation Functions --------

    /// @notice Allows members to submit their artwork for curation.
    /// @param _title Title of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork data.
    /// @param _description Description of the artwork.
    function submitArt(string memory _title, string memory _ipfsHash, string memory _description)
        public
        onlyMember
        whenNotPaused
    {
        submissionCounter++;
        ArtSubmission storage submission = artSubmissions[submissionCounter];
        submission.id = submissionCounter;
        submission.artist = msg.sender;
        submission.title = _title;
        submission.ipfsHash = _ipfsHash;
        submission.description = _description;
        submission.submissionTime = block.timestamp;
        submission.votingEndTime = block.timestamp + votingPeriod;
        submission.status = SubmissionStatus.Pending;

        emit ArtSubmitted(submissionCounter, msg.sender, _title);
    }

    /// @notice Allows members to vote on submitted artwork.
    /// @param _submissionId ID of the art submission to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnArt(uint256 _submissionId, bool _approve)
        public
        onlyMember
        whenNotPaused
    {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Pending, "Submission is not pending");
        require(submission.votingEndTime > block.timestamp, "Voting period has ended");
        require(!submission.hasVoted[msg.sender], "Already voted on this submission");

        submission.hasVoted[msg.sender] = true;
        if (_approve) {
            submission.approvalVotes++;
        } else {
            submission.rejectionVotes++;
        }

        emit VoteCastOnArt(_submissionId, msg.sender, _approve);

        // Automatically finalize if voting period ends or quorum is reached (optional quorum logic could be added)
        if (block.timestamp >= submission.votingEndTime) {
            finalizeArtSubmission(_submissionId);
        }
    }

    /// @notice Finalizes art submission after voting period, minting NFT if approved.
    /// @param _submissionId ID of the art submission to finalize.
    function finalizeArtSubmission(uint256 _submissionId)
        public
        whenNotPaused
    {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Pending, "Submission is not pending");
        require(block.timestamp >= submission.votingEndTime, "Voting period has not ended");

        uint256 totalVotes = submission.approvalVotes + submission.rejectionVotes;
        uint256 approvalPercentage = (totalVotes == 0) ? 0 : (submission.approvalVotes * 100) / totalVotes;

        if (approvalPercentage >= approvalThresholdPercentage) {
            submission.status = SubmissionStatus.Approved;
            mintArtNFT(_submissionId);
        } else {
            submission.status = SubmissionStatus.Rejected;
        }

        emit ArtSubmissionFinalized(_submissionId, submission.status);
    }

    /// @notice View function to retrieve details of a specific art submission.
    /// @param _submissionId ID of the art submission.
    /// @return ArtSubmission struct containing submission details.
    function getArtSubmission(uint256 _submissionId)
        public
        view
        returns (ArtSubmission memory)
    {
        return artSubmissions[_submissionId];
    }

    /// @notice View function to get a list of IDs of pending art submissions.
    /// @return Array of submission IDs that are in pending status.
    function getAllPendingSubmissions()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory pendingSubmissions = new uint256[](submissionCounter); // Max size, might be less
        uint256 count = 0;
        for (uint256 i = 1; i <= submissionCounter; i++) {
            if (artSubmissions[i].status == SubmissionStatus.Pending) {
                pendingSubmissions[count] = i;
                count++;
            }
        }
        // Resize array to actual number of pending submissions
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pendingSubmissions[i];
        }
        return result;
    }

    /// @notice View function to get a list of IDs of approved and minted artworks.
    /// @return Array of token IDs of approved artworks.
    function getApprovedArtworks()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory approvedArtworks = new uint256[](submissionCounter); // Max size, might be less
        uint256 count = 0;
        for (uint256 i = 1; i <= submissionCounter; i++) {
            if (artSubmissions[i].status == SubmissionStatus.Minted) {
                // Find the tokenId associated with this submissionId
                for (uint256 tokenId = 1; tokenId < nextArtworkTokenId; tokenId++) {
                    if (artworkTokenToSubmissionId[tokenId] == i) {
                        approvedArtworks[count] = tokenId;
                        count++;
                        break; // Move to next submission after finding tokenId
                    }
                }
            }
        }
        // Resize array to actual number of approved artworks
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = approvedArtworks[i];
        }
        return result;
    }

    /// @notice Admin function to manually reject an art submission before voting ends.
    /// @param _submissionId ID of the art submission to reject.
    function rejectArtSubmission(uint256 _submissionId)
        public
        onlyAdmin
        whenNotPaused
    {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Pending, "Submission is not pending");
        submission.status = SubmissionStatus.Rejected;
        emit ArtSubmissionFinalized(_submissionId, SubmissionStatus.Rejected);
    }


    // -------- NFT Minting & Management Functions --------

    /// @notice Mints an NFT for an approved artwork submission (internal function).
    /// @param _submissionId ID of the art submission to mint NFT for.
    function mintArtNFT(uint256 _submissionId)
        internal
    {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Approved, "Submission is not approved");

        uint256 tokenId = nextArtworkTokenId++;
        _safeMint(submission.artist, tokenId); // Mint the NFT to the artist
        artworkTokenToArtist[tokenId] = submission.artist;
        artworkTokenToSubmissionId[tokenId] = _submissionId;

        submission.status = SubmissionStatus.Minted;
        emit ArtNFTMinted(tokenId, _submissionId, submission.artist);
    }

    /// @notice Sets the base URI for NFT metadata.
    /// @param _baseURI Base URI string (e.g., "ipfs://your-metadata-folder/").
    function setNFTMetadataBaseURI(string memory _baseURI)
        public
        onlyAdmin
        whenNotPaused
    {
        nftMetadataBaseURI = _baseURI;
        emit NFTMetadataBaseURISet(_baseURI);
    }

    /// @notice Returns the URI for a given artwork NFT token ID.
    /// @param _tokenId Token ID of the artwork NFT.
    /// @return URI string pointing to the NFT metadata.
    function tokenURI(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        require(artworkTokenToArtist[_tokenId] != address(0), "Token URI query for nonexistent token");
        return string(abi.encodePacked(nftMetadataBaseURI, _tokenId, ".json")); // Example: ipfs://your-metadata-folder/1.json
    }

    /// @notice Admin function to burn a specific artwork NFT.
    /// @param _tokenId Token ID of the NFT to burn.
    function burnArtNFT(uint256 _tokenId)
        public
        onlyAdmin
        whenNotPaused
    {
        require(artworkTokenToArtist[_tokenId] != address(0), "Token does not exist");
        _burn(_tokenId);
        delete artworkTokenToArtist[_tokenId];
        emit ArtNFTBurned(_tokenId);
    }


    // -------- Collective Membership & Governance Functions --------

    /// @notice Allows users to request membership in the art collective.
    function joinCollective()
        public
        whenNotPaused
    {
        require(!members[msg.sender], "Already a member");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending");
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Admin function to approve a pending membership request.
    /// @param _member Address of the user to approve membership for.
    function approveMembership(address _member)
        public
        onlyAdmin
        whenNotPaused
    {
        require(pendingMembershipRequests[_member], "No pending membership request for this address");
        members[_member] = true;
        pendingMembershipRequests[_member] = false;
        emit MembershipApproved(_member);
    }

    /// @notice Admin function to revoke membership from an address.
    /// @param _member Address of the member to revoke membership from.
    function revokeMembership(address _member)
        public
        onlyAdmin
        whenNotPaused
    {
        require(members[_member], "Address is not a member");
        members[_member] = false;
        emit MembershipRevoked(_member);
    }

    /// @notice Allows members to propose changes to the contract parameters or logic.
    /// @param _proposalDescription Description of the governance proposal.
    /// @param _calldata Calldata to execute if proposal passes.
    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata)
        public
        onlyMember
        whenNotPaused
    {
        proposalCounter++;
        GovernanceProposal storage proposal = governanceProposals[proposalCounter];
        proposal.id = proposalCounter;
        proposal.description = _proposalDescription;
        proposal.calldataData = _calldata;
        proposal.votingEndTime = block.timestamp + votingPeriod;
        proposal.status = ProposalStatus.Pending;

        emit GovernanceProposalCreated(proposalCounter, msg.sender, _proposalDescription);
    }

    /// @notice Allows members to vote on governance proposals.
    /// @param _proposalId ID of the governance proposal to vote on.
    /// @param _support True to support, false to oppose.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support)
        public
        onlyMember
        whenNotPaused
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
        require(proposal.votingEndTime > block.timestamp, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.supportVotes++;
        } else {
            proposal.againstVotes++;
        }

        emit VoteCastOnGovernanceProposal(_proposalId, msg.sender, _support);

        // Automatically finalize if voting period ends
        if (block.timestamp >= proposal.votingEndTime) {
            executeGovernanceProposal(_proposalId);
        }
    }

    /// @notice Admin function to execute an approved governance proposal.
    /// @param _proposalId ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId)
        public
        onlyAdmin
        whenNotPaused
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended");

        uint256 totalVotes = proposal.supportVotes + proposal.againstVotes;
        uint256 supportPercentage = (totalVotes == 0) ? 0 : (proposal.supportVotes * 100) / totalVotes;

        if (supportPercentage >= approvalThresholdPercentage) {
            proposal.status = ProposalStatus.Approved;
            // Execute the calldata (careful with security implications!)
            (bool success, ) = address(this).call(proposal.calldataData);
            if (success) {
                proposal.status = ProposalStatus.Executed;
            } else {
                proposal.status = ProposalStatus.Rejected; // Execution failed, mark as rejected
            }
        } else {
            proposal.status = ProposalStatus.Rejected;
        }

        emit GovernanceProposalExecuted(_proposalId, proposal.status);
    }

    /// @notice View function to get details of a collective member.
    /// @param _member Address of the member.
    /// @return True if member, false otherwise. (Can be extended to return more member details).
    function getMemberDetails(address _member)
        public
        view
        returns (bool)
    {
        return members[_member];
    }

    /// @notice Admin view function to get a list of addresses requesting membership.
    /// @return Array of addresses that have requested membership.
    function getPendingMembershipRequests()
        public
        view
        onlyAdmin
        returns (address[] memory)
    {
        address[] memory pendingRequests = new address[](address(this).balance); // Max size, might be less. Inefficient but avoids looping all addresses.
        uint256 count = 0;
        for (uint256 i = 0; i < pendingRequests.length; i++) { // Iterate through potential request slots (not ideal in production)
            if (pendingMembershipRequests[pendingRequests[i]]) { // Check if the address at this slot has a pending request
                pendingRequests[count] = pendingRequests[i];
                count++;
            }
        }
        // Resize array to actual number of requests
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pendingRequests[i];
        }
        return result;
    }


    // -------- Utility & Admin Functions --------

    /// @notice Pauses core contract functionalities.
    function pauseContract()
        public
        onlyAdmin
        whenNotPaused
    {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Resumes contract functionalities.
    function unpauseContract()
        public
        onlyAdmin
        whenPaused
    {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Sets the voting period for art submissions and governance proposals.
    /// @param _newVotingPeriod New voting period in seconds.
    function setVotingPeriod(uint256 _newVotingPeriod)
        public
        onlyAdmin
        whenNotPaused
    {
        votingPeriod = _newVotingPeriod;
        emit VotingPeriodChanged(_newVotingPeriod);
    }

    /// @notice Sets the approval threshold percentage for art submissions and governance proposals.
    /// @param _newThresholdPercentage New approval threshold percentage (e.g., 60 for 60%).
    function setApprovalThreshold(uint256 _newThresholdPercentage)
        public
        onlyAdmin
        whenNotPaused
    {
        require(_newThresholdPercentage <= 100, "Approval threshold must be <= 100");
        approvalThresholdPercentage = _newThresholdPercentage;
        emit ApprovalThresholdChanged(_newThresholdPercentage);
    }

    /// @notice Allows admin to withdraw funds from the contract balance.
    function withdrawContractBalance()
        public
        onlyAdmin
        whenNotPaused
    {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
        emit FundsWithdrawn(admin, balance);
    }

    /// @notice Sets a new admin address.
    /// @param _newAdmin Address of the new admin.
    function setAdmin(address _newAdmin)
        public
        onlyAdmin
        whenNotPaused
    {
        require(_newAdmin != address(0), "New admin cannot be the zero address");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }


    // -------- Internal ERC721-like Mint/Burn Functions (Simplified, for demonstration) --------
    //  Note: For a production NFT contract, use a proper ERC721 implementation library like OpenZeppelin.

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function _safeMint(address _to, uint256 _tokenId) internal {
        _mint(_to, _tokenId);
        // Add safe transfer checks if needed in a real ERC721
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(_ownerOf[_tokenId] == address(0), "ERC721: token already minted");

        _balanceOf[_to] += 1;
        _ownerOf[_tokenId] = _to;
        // Emit Transfer event if needed in a real ERC721
    }

    function _burn(uint256 _tokenId) internal virtual {
        address owner = ownerOf(_tokenId);
        require(owner != address(0), "ERC721: burn of nonexistent token");

        _clearApproval(_tokenId);

        _balanceOf[owner] -= 1;
        delete _ownerOf[_tokenId];

        // Emit Transfer event if needed in a real ERC721
    }

    function ownerOf(uint256 _tokenId) public view virtual returns (address) {
        return _ownerOf[_tokenId];
    }

    // Basic balanceOf - more complete ERC721 would have more functions.
    function balanceOf(address _owner) public view virtual returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balanceOf[_owner];
    }

    function _clearApproval(uint256 _tokenId) private {
        if (_tokenApprovals[_tokenId] != address(0)) {
            delete _tokenApprovals[_tokenId];
        }
    }
}
```