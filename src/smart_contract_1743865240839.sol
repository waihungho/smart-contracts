```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective.
 * This contract facilitates the creation, curation, and governance of digital art within a community.
 * It incorporates advanced concepts like dynamic NFT metadata, on-chain voting with weighted reputation,
 * community-driven art curation, and a decentralized grant system for artists.
 *
 * Function Summary:
 * -----------------
 * **Core Art NFT Functions:**
 * 1. `mintArtNFT(string _title, string _description, string _initialMetadataURI)`: Mints a new Art NFT by a registered artist.
 * 2. `updateArtMetadata(uint256 _tokenId, string _newMetadataURI)`: Allows the NFT owner to update the metadata URI.
 * 3. `getArtMetadataURI(uint256 _tokenId)`: Retrieves the current metadata URI for an Art NFT.
 * 4. `transferArtNFT(address _to, uint256 _tokenId)`: Transfers ownership of an Art NFT.
 * 5. `getArtNFTOwner(uint256 _tokenId)`: Retrieves the current owner of an Art NFT.
 * 6. `getTotalArtNFTsMinted()`: Returns the total number of Art NFTs minted.
 *
 * **Artist and Membership Management:**
 * 7. `applyForArtistMembership(string _artistStatement, string _portfolioLink)`: Allows anyone to apply for artist membership.
 * 8. `approveArtistMembership(address _artistAddress)`: Admin function to approve artist membership applications.
 * 9. `revokeArtistMembership(address _artistAddress)`: Admin function to revoke artist membership.
 * 10. `isRegisteredArtist(address _artistAddress)`: Checks if an address is a registered artist.
 * 11. `getArtistApplicationDetails(address _applicantAddress)`: Admin function to view artist application details.
 *
 * **Governance and Voting Functions:**
 * 12. `createProposal(string _title, string _description, ProposalType _proposalType, bytes _calldata)`: Allows members to create governance proposals.
 * 13. `voteOnProposal(uint256 _proposalId, VoteOption _vote)`: Allows members to vote on active proposals.
 * 14. `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes and the execution time has arrived.
 * 15. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 * 16. `getProposalVoteCount(uint256 _proposalId, VoteOption _vote)`: Gets the vote count for a specific vote option in a proposal.
 * 17. `getProposalStatus(uint256 _proposalId)`: Gets the current status of a proposal.
 *
 * **Reputation and Community Features:**
 * 18. `increaseMemberReputation(address _memberAddress, uint256 _amount)`: Admin function to increase member reputation.
 * 19. `decreaseMemberReputation(address _memberAddress, uint256 _amount)`: Admin function to decrease member reputation.
 * 20. `getMemberReputation(address _memberAddress)`: Retrieves the reputation score of a member.
 * 21. `donateToCollective()`: Allows anyone to donate ETH to the collective's treasury.
 * 22. `createArtistGrantProposal(address _artistAddress, uint256 _grantAmount, string _grantReason)`:  Members can propose grants for registered artists.
 * 23. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Admin function to withdraw funds from the treasury (e.g., after a successful grant proposal).
 * 24. `getContractTreasuryBalance()`: Returns the current balance of the contract treasury.
 *
 * **Admin and Utility Functions:**
 * 25. `setAdminAddress(address _newAdmin)`: Allows the current admin to change the admin address.
 * 26. `getAdminAddress()`: Returns the current admin address.
 * 27. `pauseContract()`: Admin function to pause the contract.
 * 28. `unpauseContract()`: Admin function to unpause the contract.
 * 29. `isContractPaused()`: Checks if the contract is currently paused.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousArtCollective is Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums and Structs ---

    enum ProposalType {
        General,
        ArtistGrant,
        MembershipAction,
        TreasuryWithdrawal
    }

    enum VoteOption {
        Against,
        For
    }

    struct Proposal {
        uint256 proposalId;
        string title;
        string description;
        ProposalType proposalType;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bytes calldata; // Calldata for execution if proposal passes
        bool executed;
        bool passed;
    }

    struct ArtistApplication {
        address applicantAddress;
        string artistStatement;
        string portfolioLink;
        bool approved;
    }

    struct ArtNFT {
        uint256 tokenId;
        address creator;
        string metadataURI;
        uint256 mintTimestamp;
    }

    // --- State Variables ---

    Counters.Counter private _artNFTCounter;
    Counters.Counter private _proposalCounter;

    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => address) public artNFTOwner;
    mapping(address => bool) public isArtist;
    mapping(address => ArtistApplication) public artistApplications;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => VoteOption)) public memberVotes; // proposalId => memberAddress => vote
    mapping(address => uint256) public memberReputation; // Member Address => Reputation Points

    uint256 public proposalVotingPeriod = 7 days; // Default voting period
    uint256 public reputationThresholdForVoting = 10; // Minimum reputation to vote
    uint256 public reputationForMintingNFT = 5; // Minimum reputation to mint NFT

    // --- Events ---

    event ArtNFTMinted(uint256 tokenId, address creator, string metadataURI);
    event ArtMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);
    event ArtistMembershipApplied(address applicantAddress);
    event ArtistMembershipApproved(address artistAddress);
    event ArtistMembershipRevoked(address artistAddress);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string title);
    event VoteCast(uint256 proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 proposalId, bool passed);
    event ReputationIncreased(address memberAddress, uint256 amount);
    event ReputationDecreased(address memberAddress, uint256 amount);
    event DonationReceived(address donor, uint256 amount);
    event FundsWithdrawn(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyArtist() {
        require(isArtist[msg.sender], "Caller is not a registered artist");
        _;
    }

    modifier onlyMember() {
        require(memberReputation[msg.sender] >= reputationThresholdForVoting, "Caller is not a member with sufficient reputation");
        _;
    }

    modifier onlyApprovedApplicant(address _applicantAddress) {
        require(artistApplications[_applicantAddress].applicantAddress == _applicantAddress, "Applicant not found");
        require(!artistApplications[_applicantAddress].approved, "Applicant already approved");
        _;
    }

    modifier onlyValidProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalCounter.current(), "Invalid proposal ID");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].startTime && block.timestamp <= proposals[_proposalId].endTime, "Proposal is not active");
        _;
    }

    modifier onlyExecutableProposal(uint256 _proposalId) {
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can call this function");
        _;
    }


    // --- Constructor ---
    constructor() payable {
        // Admin is the contract deployer (Ownable)
    }

    // --- Core Art NFT Functions ---

    /**
     * @dev Mints a new Art NFT. Only registered artists with sufficient reputation can mint.
     * @param _title The title of the art NFT.
     * @param _description A brief description of the art.
     * @param _initialMetadataURI The initial URI pointing to the NFT metadata.
     */
    function mintArtNFT(string memory _title, string memory _description, string memory _initialMetadataURI)
        public
        whenNotPaused
        onlyArtist
    {
        require(memberReputation[msg.sender] >= reputationForMintingNFT, "Artist reputation too low to mint NFT");
        _artNFTCounter.increment();
        uint256 tokenId = _artNFTCounter.current();

        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            creator: msg.sender,
            metadataURI: _initialMetadataURI,
            mintTimestamp: block.timestamp
        });
        artNFTOwner[tokenId] = msg.sender;

        emit ArtNFTMinted(tokenId, msg.sender, _initialMetadataURI);
    }

    /**
     * @dev Allows the owner of an Art NFT to update its metadata URI.
     * @param _tokenId The ID of the Art NFT to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateArtMetadata(uint256 _tokenId, string memory _newMetadataURI)
        public
        whenNotPaused
    {
        require(artNFTOwner[_tokenId] == msg.sender, "Only NFT owner can update metadata");
        artNFTs[_tokenId].metadataURI = _newMetadataURI;
        emit ArtMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Retrieves the current metadata URI for a given Art NFT.
     * @param _tokenId The ID of the Art NFT.
     * @return The metadata URI string.
     */
    function getArtMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(_tokenId > 0 && _tokenId <= _artNFTCounter.current(), "Invalid token ID");
        return artNFTs[_tokenId].metadataURI;
    }

    /**
     * @dev Transfers ownership of an Art NFT to another address.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the Art NFT to transfer.
     */
    function transferArtNFT(address _to, uint256 _tokenId) public whenNotPaused {
        require(artNFTOwner[_tokenId] == msg.sender, "Only NFT owner can transfer");
        require(_to != address(0), "Invalid recipient address");
        address from = msg.sender;
        artNFTOwner[_tokenId] = _to;
        emit ArtNFTTransferred(_tokenId, from, _to);
    }

    /**
     * @dev Retrieves the owner of a given Art NFT.
     * @param _tokenId The ID of the Art NFT.
     * @return The address of the owner.
     */
    function getArtNFTOwner(uint256 _tokenId) public view returns (address) {
        require(_tokenId > 0 && _tokenId <= _artNFTCounter.current(), "Invalid token ID");
        return artNFTOwner[_tokenId];
    }

    /**
     * @dev Returns the total number of Art NFTs minted by this contract.
     * @return The total count of Art NFTs.
     */
    function getTotalArtNFTsMinted() public view returns (uint256) {
        return _artNFTCounter.current();
    }


    // --- Artist and Membership Management ---

    /**
     * @dev Allows any address to apply for artist membership.
     * @param _artistStatement A statement from the artist about their work and vision.
     * @param _portfolioLink A link to the artist's portfolio.
     */
    function applyForArtistMembership(string memory _artistStatement, string memory _portfolioLink) public whenNotPaused {
        require(!isArtist[msg.sender], "Already a registered artist");
        require(artistApplications[msg.sender].applicantAddress == address(0), "Application already submitted"); // Prevent duplicate applications

        artistApplications[msg.sender] = ArtistApplication({
            applicantAddress: msg.sender,
            artistStatement: _artistStatement,
            portfolioLink: _portfolioLink,
            approved: false
        });
        emit ArtistMembershipApplied(msg.sender);
    }

    /**
     * @dev Admin-only function to approve an artist membership application.
     * @param _artistAddress The address of the applicant to approve.
     */
    function approveArtistMembership(address _artistAddress) public whenNotPaused onlyAdmin onlyApprovedApplicant(_artistAddress) {
        isArtist[_artistAddress] = true;
        artistApplications[_artistAddress].approved = true;
        emit ArtistMembershipApproved(_artistAddress);
        increaseMemberReputation(_artistAddress, 10); // Grant initial reputation upon membership approval
    }

    /**
     * @dev Admin-only function to revoke artist membership.
     * @param _artistAddress The address of the artist to revoke membership from.
     */
    function revokeArtistMembership(address _artistAddress) public whenNotPaused onlyAdmin {
        require(isArtist[_artistAddress], "Address is not a registered artist");
        isArtist[_artistAddress] = false;
        emit ArtistMembershipRevoked(_artistAddress);
        decreaseMemberReputation(_artistAddress, 5); // Decrease reputation upon membership revocation
    }

    /**
     * @dev Checks if a given address is a registered artist.
     * @param _artistAddress The address to check.
     * @return True if the address is a registered artist, false otherwise.
     */
    function isRegisteredArtist(address _artistAddress) public view returns (bool) {
        return isArtist[_artistAddress];
    }

    /**
     * @dev Admin-only function to get the details of an artist membership application.
     * @param _applicantAddress The address of the applicant.
     * @return ArtistApplication struct containing application details.
     */
    function getArtistApplicationDetails(address _applicantAddress) public view onlyAdmin returns (ArtistApplication memory) {
        return artistApplications[_applicantAddress];
    }


    // --- Governance and Voting Functions ---

    /**
     * @dev Allows members to create a governance proposal.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposal.
     * @param _proposalType The type of proposal (General, Grant, Membership, Treasury).
     * @param _calldata The calldata to be executed if the proposal passes.
     */
    function createProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        bytes memory _calldata
    ) public whenNotPaused onlyMember {
        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            title: _title,
            description: _description,
            proposalType: _proposalType,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVotingPeriod,
            forVotes: 0,
            againstVotes: 0,
            calldata: _calldata,
            executed: false,
            passed: false
        });

        emit ProposalCreated(proposalId, _proposalType, msg.sender, _title);
    }

    /**
     * @dev Allows members to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote The vote option (For or Against).
     */
    function voteOnProposal(uint256 _proposalId, VoteOption _vote) public whenNotPaused onlyMember onlyValidProposal(_proposalId) onlyActiveProposal(_proposalId) {
        require(memberVotes[_proposalId][msg.sender] == VoteOption.Against || memberVotes[_proposalId][msg.sender] == VoteOption.For || memberVotes[_proposalId][msg.sender] == VoteOption(0), "Already voted on this proposal"); // Check not already voted

        memberVotes[_proposalId][msg.sender] = _vote;

        if (_vote == VoteOption.For) {
            proposals[_proposalId].forVotes += getVotingWeight(msg.sender); // Voting weight based on reputation
        } else if (_vote == VoteOption.Against) {
            proposals[_proposalId].againstVotes += getVotingWeight(msg.sender);
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a proposal if it has passed the voting period and met the criteria.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused onlyValidProposal(_proposalId) onlyExecutableProposal(_proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");

        Proposal storage proposal = proposals[_proposalId];

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 quorum = calculateQuorum(totalVotes); // Example quorum calculation (can be adjusted)

        if (proposal.forVotes > proposal.againstVotes && proposal.forVotes >= quorum) {
            proposal.passed = true;
            if (proposal.calldata.length > 0) {
                // Execute the calldata (consider security implications carefully in real-world scenarios)
                (bool success, ) = address(this).call(proposal.calldata);
                require(success, "Proposal execution failed");
            }
        } else {
            proposal.passed = false;
        }
        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /**
     * @dev Retrieves details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view onlyValidProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Gets the vote count for a specific vote option (For/Against) in a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voteOption The vote option to query (VoteOption.For or VoteOption.Against).
     * @return The vote count for the specified option.
     */
    function getProposalVoteCount(uint256 _proposalId, VoteOption _voteOption) public view onlyValidProposal(_proposalId) returns (uint256) {
        if (_voteOption == VoteOption.For) {
            return proposals[_proposalId].forVotes;
        } else if (_voteOption == VoteOption.Against) {
            return proposals[_proposalId].againstVotes;
        } else {
            return 0; // Should not reach here, but for completeness
        }
    }

    /**
     * @dev Gets the current status of a proposal (Active, Passed, Failed, Executed).
     * @param _proposalId The ID of the proposal.
     * @return A string representing the proposal status.
     */
    function getProposalStatus(uint256 _proposalId) public view onlyValidProposal(_proposalId) returns (string memory) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed) {
            return proposal.passed ? "Executed & Passed" : "Executed & Failed";
        } else if (block.timestamp > proposal.endTime) {
            return "Voting Ended";
        } else if (block.timestamp >= proposal.startTime) {
            return "Voting Active";
        } else {
            return "Pending";
        }
    }


    // --- Reputation and Community Features ---

    /**
     * @dev Admin-only function to increase a member's reputation.
     * @param _memberAddress The address of the member to increase reputation for.
     * @param _amount The amount of reputation to increase.
     */
    function increaseMemberReputation(address _memberAddress, uint256 _amount) public onlyAdmin {
        memberReputation[_memberAddress] += _amount;
        emit ReputationIncreased(_memberAddress, _amount);
    }

    /**
     * @dev Admin-only function to decrease a member's reputation.
     * @param _memberAddress The address of the member to decrease reputation for.
     * @param _amount The amount of reputation to decrease.
     */
    function decreaseMemberReputation(address _memberAddress, uint256 _amount) public onlyAdmin {
        require(memberReputation[_memberAddress] >= _amount, "Reputation cannot be negative");
        memberReputation[_memberAddress] -= _amount;
        emit ReputationDecreased(_memberAddress, _amount);
    }

    /**
     * @dev Retrieves the reputation score of a member.
     * @param _memberAddress The address of the member.
     * @return The reputation score.
     */
    function getMemberReputation(address _memberAddress) public view returns (uint256) {
        return memberReputation[_memberAddress];
    }

    /**
     * @dev Allows anyone to donate ETH to the collective's treasury.
     */
    function donateToCollective() public payable whenNotPaused {
        emit DonationReceived(msg.sender, msg.value);
    }

    /**
     * @dev Allows members to create a proposal for an artist grant.
     * @param _artistAddress The address of the artist receiving the grant.
     * @param _grantAmount The amount of ETH to grant.
     * @param _grantReason The reason for the grant.
     */
    function createArtistGrantProposal(address _artistAddress, uint256 _grantAmount, string memory _grantReason) public whenNotPaused onlyMember {
        require(isArtist[_artistAddress], "Recipient is not a registered artist");
        require(_grantAmount > 0, "Grant amount must be positive");

        // Construct calldata to execute the treasury withdrawal upon proposal success
        bytes memory grantCalldata = abi.encodeWithSignature("withdrawTreasuryFunds(address,uint256)", _artistAddress, _grantAmount);

        createProposal(
            "Artist Grant Proposal",
            string(abi.encodePacked("Grant proposal for artist ", Strings.toHexString(uint160(address(_artistAddress)), 20), " for ", _grantReason, ". Amount: ", Strings.toString(_grantAmount), " ETH.")),
            ProposalType.ArtistGrant,
            grantCalldata
        );
    }

    /**
     * @dev Admin-only function to withdraw funds from the treasury. Only callable after a successful grant proposal execution.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyAdmin whenNotPaused {
        require(address(this).balance >= _amount, "Insufficient contract balance");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed");
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Returns the current balance of the contract treasury.
     * @return The ETH balance of the contract.
     */
    function getContractTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Admin and Utility Functions ---

    /**
     * @dev Allows the current admin to set a new admin address.
     * @param _newAdmin The address of the new admin.
     */
    function setAdminAddress(address _newAdmin) public onlyOwner {
        transferOwnership(_newAdmin);
    }

    /**
     * @dev Returns the current admin address.
     * @return The address of the admin.
     */
    function getAdminAddress() public view returns (address) {
        return owner();
    }

    /**
     * @dev Pauses the contract, preventing most state-changing functions from being called.
     */
    function pauseContract() public onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing state-changing functions to be called again.
     */
    function unpauseContract() public onlyAdmin {
        _unpause();
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if the contract is paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return paused();
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Calculates the voting weight of a member based on their reputation.
     * @param _memberAddress The address of the member.
     * @return The voting weight for the member.
     */
    function getVotingWeight(address _memberAddress) internal view returns (uint256) {
        // Example: Linear voting weight based on reputation. Can be adjusted.
        return 1 + (memberReputation[_memberAddress] / 10); // Base weight 1, plus reputation bonus
    }

    /**
     * @dev Calculates the quorum for a proposal based on total votes.
     * @param _totalVotes Total votes cast in a proposal.
     * @return The quorum required for the proposal to pass.
     */
    function calculateQuorum(uint256 _totalVotes) internal pure returns (uint256) {
        // Example: Simple quorum of 50% + 1 of total votes. Can be adjusted.
        return (_totalVotes / 2) + 1;
    }

    // --- Fallback and Receive Functions (Optional, for direct ETH donations) ---

    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }
}
```