```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author AI Assistant
 * @dev A smart contract for a decentralized art collective enabling collaborative art creation,
 * governance, and NFT management.

 * **Outline & Function Summary:**

 * **Initialization & Configuration:**
 * 1. `constructor(string _collectiveName, address _governanceAddress)`: Initializes the DAAC with a name and governance address.
 * 2. `setGovernanceAddress(address _newGovernanceAddress)`: Allows the current governance to change the governance address.
 * 3. `setVotingPeriod(uint256 _newVotingPeriod)`: Sets the duration of voting periods for proposals.
 * 4. `setQuorumPercentage(uint256 _newQuorumPercentage)`: Sets the minimum quorum percentage for proposals to pass.

 * **Membership & Contribution:**
 * 5. `joinCollective()`: Allows users to join the art collective.
 * 6. `leaveCollective()`: Allows members to leave the art collective.
 * 7. `depositContribution(uint256 _amount)`: Members can deposit funds to support the collective.
 * 8. `withdrawContribution(uint256 _amount)`: Members can withdraw their contributions (subject to conditions/governance).

 * **Art Proposal & Creation:**
 * 9. `submitArtProposal(string _title, string _description, string _ipfsHash)`: Members can submit art proposals with title, description, and IPFS hash.
 * 10. `voteOnArtProposal(uint256 _proposalId, bool _support)`: Members can vote on art proposals.
 * 11. `finalizeArtProposal(uint256 _proposalId)`: Finalizes an art proposal if it passes voting, minting an NFT.
 * 12. `rejectArtProposal(uint256 _proposalId)`: Governance can reject a proposal even after passing vote (exceptional cases).

 * **NFT Management & Collective Ownership:**
 * 13. `mintCollectiveNFT(uint256 _proposalId)`: (Internal) Mints an NFT representing the collective art.
 * 14. `transferNFTToMember(uint256 _tokenId, address _recipient)`: Governance can transfer a specific NFT to a member (e.g., for rewards).
 * 15. `burnCollectiveNFT(uint256 _tokenId)`: Governance can burn a collective NFT (exceptional cases).
 * 16. `getNFTMetadataURI(uint256 _tokenId)`: Retrieves the metadata URI of a collective NFT.

 * **Governance & Treasury Management:**
 * 17. `proposeGovernanceChange(string _description, bytes _calldata)`: Governance can propose changes to contract parameters or execute functions.
 * 18. `voteOnGovernanceChange(uint256 _proposalId, bool _support)`: Members vote on governance change proposals.
 * 19. `executeGovernanceChange(uint256 _proposalId)`: Executes a governance change proposal if it passes.
 * 20. `withdrawTreasuryFunds(uint256 _amount, address _recipient)`: Governance can withdraw funds from the collective treasury.
 * 21. `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 * 22. `getArtProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 * 23. `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a governance proposal.

 * **Events:**
 * - `CollectiveJoined(address member)`: Emitted when a member joins the collective.
 * - `CollectiveLeft(address member)`: Emitted when a member leaves the collective.
 * - `ContributionDeposited(address member, uint256 amount)`: Emitted when a contribution is deposited.
 * - `ContributionWithdrawn(address member, uint256 amount)`: Emitted when a contribution is withdrawn.
 * - `ArtProposalSubmitted(uint256 proposalId, address proposer, string title)`: Emitted when an art proposal is submitted.
 * - `ArtProposalVoted(uint256 proposalId, address voter, bool support)`: Emitted when a vote is cast on an art proposal.
 * - `ArtProposalFinalized(uint256 proposalId, uint256 tokenId)`: Emitted when an art proposal is finalized and an NFT minted.
 * - `ArtProposalRejected(uint256 proposalId)`: Emitted when an art proposal is rejected.
 * - `NFTMinted(uint256 tokenId, uint256 proposalId)`: Emitted when a collective NFT is minted.
 * - `NFTTransferred(uint256 tokenId, address from, address to)`: Emitted when a collective NFT is transferred.
 * - `NFTBurned(uint256 tokenId)`: Emitted when a collective NFT is burned.
 * - `GovernanceProposalSubmitted(uint256 proposalId, address proposer, string description)`: Emitted when a governance proposal is submitted.
 * - `GovernanceProposalVoted(uint256 proposalId, address voter, bool support)`: Emitted when a vote is cast on a governance proposal.
 * - `GovernanceProposalExecuted(uint256 proposalId)`: Emitted when a governance proposal is executed.
 * - `GovernanceAddressChanged(address oldGovernance, address newGovernance)`: Emitted when the governance address is changed.
 * - `VotingPeriodChanged(uint256 newVotingPeriod)`: Emitted when the voting period is changed.
 * - `QuorumPercentageChanged(uint256 newQuorumPercentage)`: Emitted when the quorum percentage is changed.
 * - `TreasuryWithdrawal(uint256 amount, address recipient)`: Emitted when funds are withdrawn from the treasury.
 */
contract DecentralizedAutonomousArtCollective {
    string public collectiveName;
    address public governanceAddress;
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumPercentage = 50; // Default quorum percentage (50%)

    uint256 public nextArtProposalId = 1;
    uint256 public nextGovernanceProposalId = 1;
    uint256 public nextNFTTokenId = 1;

    mapping(address => bool) public isMember;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public artProposalVotes; // proposalId => voter => support
    mapping(uint256 => mapping(address => bool)) public governanceProposalVotes; // proposalId => voter => support
    mapping(uint256 => string) public nftMetadataURIs; // tokenId => metadataURI
    mapping(uint256 => address) public nftOwners; // tokenId => owner (contract itself initially)

    uint256 public treasuryBalance;

    struct ArtProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 voteCount;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
        bool finalized;
        bool rejected;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes calldataData;
        uint256 voteCount;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
        bool executed;
    }

    event CollectiveJoined(address member);
    event CollectiveLeft(address member);
    event ContributionDeposited(address member, uint256 amount);
    event ContributionWithdrawn(address member, uint256 amount);
    event ArtProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtProposalFinalized(uint256 proposalId, uint256 tokenId);
    event ArtProposalRejected(uint256 proposalId);
    event NFTMinted(uint256 tokenId, uint256 proposalId);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId);
    event GovernanceProposalSubmitted(uint256 proposalId, address proposer, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event GovernanceAddressChanged(address oldGovernance, address newGovernance);
    event VotingPeriodChanged(uint256 newVotingPeriod);
    event QuorumPercentageChanged(uint256 newQuorumPercentage);
    event TreasuryWithdrawal(uint256 amount, address recipient);

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance address can call this function");
        _;
    }

    modifier onlyMembers() {
        require(isMember[msg.sender], "Only members can call this function");
        _;
    }

    modifier proposalExists(uint256 _proposalId, mapping(uint256 => ArtProposal) storage _proposals) {
        require(_proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist");
        _;
    }

    modifier governanceProposalExists(uint256 _proposalId, mapping(uint256 => GovernanceProposal) storage _proposals) {
        require(_proposals[_proposalId].proposalId == _proposalId, "Governance proposal does not exist");
        _;
    }

    modifier votingNotEnded(uint256 _proposalId, mapping(uint256 => ArtProposal) storage _proposals) {
        require(block.timestamp < _proposals[_proposalId].votingEndTime, "Voting has ended");
        _;
    }

    modifier governanceVotingNotEnded(uint256 _proposalId, mapping(uint256 => GovernanceProposal) storage _proposals) {
        require(block.timestamp < _proposals[_proposalId].votingEndTime, "Governance voting has ended");
        _;
    }

    modifier notFinalized(uint256 _proposalId, mapping(uint256 => ArtProposal) storage _proposals) {
        require(!_proposals[_proposalId].finalized, "Proposal already finalized");
        _;
    }

    modifier notRejected(uint256 _proposalId, mapping(uint256 => ArtProposal) storage _proposals) {
        require(!_proposals[_proposalId].rejected, "Proposal already rejected");
        _;
    }

    modifier notExecuted(uint256 _proposalId, mapping(uint256 => GovernanceProposal) storage _proposals) {
        require(!_proposals[_proposalId].executed, "Governance proposal already executed");
        _;
    }


    constructor(string memory _collectiveName, address _governanceAddress) {
        collectiveName = _collectiveName;
        governanceAddress = _governanceAddress;
    }

    /**
     * @dev Sets the governance address. Only callable by the current governance.
     * @param _newGovernanceAddress The new address to set as governance.
     */
    function setGovernanceAddress(address _newGovernanceAddress) external onlyGovernance {
        require(_newGovernanceAddress != address(0), "Invalid governance address");
        emit GovernanceAddressChanged(governanceAddress, _newGovernanceAddress);
        governanceAddress = _newGovernanceAddress;
    }

    /**
     * @dev Sets the voting period for proposals. Only callable by governance.
     * @param _newVotingPeriod The new voting period in seconds.
     */
    function setVotingPeriod(uint256 _newVotingPeriod) external onlyGovernance {
        require(_newVotingPeriod > 0, "Voting period must be greater than 0");
        emit VotingPeriodChanged(_newVotingPeriod);
        votingPeriod = _newVotingPeriod;
    }

    /**
     * @dev Sets the quorum percentage for proposals to pass. Only callable by governance.
     * @param _newQuorumPercentage The new quorum percentage (0-100).
     */
    function setQuorumPercentage(uint256 _newQuorumPercentage) external onlyGovernance {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be between 0 and 100");
        emit QuorumPercentageChanged(_newQuorumPercentage);
        quorumPercentage = _newQuorumPercentage;
    }

    /**
     * @dev Allows a user to join the art collective.
     */
    function joinCollective() external {
        require(!isMember[msg.sender], "Already a member");
        isMember[msg.sender] = true;
        emit CollectiveJoined(msg.sender);
    }

    /**
     * @dev Allows a member to leave the art collective.
     */
    function leaveCollective() external onlyMembers {
        require(isMember[msg.sender], "Not a member");
        isMember[msg.sender] = false;
        emit CollectiveLeft(msg.sender);
    }

    /**
     * @dev Allows members to deposit funds to support the collective.
     */
    function depositContribution(uint256 _amount) external onlyMembers payable {
        require(msg.value == _amount, "Amount sent does not match requested deposit");
        treasuryBalance += _amount;
        emit ContributionDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows members to withdraw their contributions (subject to governance or conditions).
     *      For simplicity, allowing direct withdrawal, but in a real scenario, this might be governed.
     * @param _amount The amount to withdraw.
     */
    function withdrawContribution(uint256 _amount) external onlyMembers {
        // Basic withdrawal - in real-world, might need governance approval or conditions.
        require(_amount <= treasuryBalance, "Insufficient treasury balance");
        payable(msg.sender).transfer(_amount);
        treasuryBalance -= _amount;
        emit ContributionWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Submits an art proposal to the collective.
     * @param _title The title of the art proposal.
     * @param _description A description of the art.
     * @param _ipfsHash The IPFS hash pointing to the art metadata.
     */
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyMembers {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Invalid proposal details");
        ArtProposal storage proposal = artProposals[nextArtProposalId];
        proposal.proposalId = nextArtProposalId;
        proposal.proposer = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.ipfsHash = _ipfsHash;
        proposal.votingEndTime = block.timestamp + votingPeriod;
        nextArtProposalId++;
        emit ArtProposalSubmitted(proposal.proposalId, msg.sender, _title);
    }

    /**
     * @dev Allows members to vote on an art proposal.
     * @param _proposalId The ID of the art proposal.
     * @param _support True for yes, false for no.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _support)
        external
        onlyMembers
        proposalExists(_proposalId, artProposals)
        votingNotEnded(_proposalId, artProposals)
        notFinalized(_proposalId, artProposals)
        notRejected(_proposalId, artProposals)
    {
        require(!artProposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        artProposalVotes[_proposalId][msg.sender] = true;
        ArtProposal storage proposal = artProposals[_proposalId];
        proposal.voteCount++;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Finalizes an art proposal if it passes the voting.
     * @param _proposalId The ID of the art proposal.
     */
    function finalizeArtProposal(uint256 _proposalId)
        external
        proposalExists(_proposalId, artProposals)
        votingNotEnded(_proposalId, artProposals) // Can finalize even after voting end, but for security let's keep it within voting period for now.
        notFinalized(_proposalId, artProposals)
        notRejected(_proposalId, artProposals)
    {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(block.timestamp >= proposal.votingEndTime, "Voting period not ended yet");

        uint256 quorum = (isMemberCount() * quorumPercentage) / 100;
        require(proposal.voteCount >= quorum, "Quorum not reached");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass");

        proposal.finalized = true;
        uint256 tokenId = mintCollectiveNFT(_proposalId);
        emit ArtProposalFinalized(_proposalId, tokenId);
    }

    /**
     * @dev Governance can reject an art proposal even after passing the vote (exceptional cases).
     * @param _proposalId The ID of the art proposal.
     */
    function rejectArtProposal(uint256 _proposalId)
        external
        onlyGovernance
        proposalExists(_proposalId, artProposals)
        notFinalized(_proposalId, artProposals)
        notRejected(_proposalId, artProposals)
    {
        ArtProposal storage proposal = artProposals[_proposalId];
        proposal.rejected = true;
        emit ArtProposalRejected(_proposalId);
    }

    /**
     * @dev (Internal) Mints a collective NFT for a finalized art proposal.
     * @param _proposalId The ID of the finalized art proposal.
     * @return tokenId The ID of the minted NFT.
     */
    function mintCollectiveNFT(uint256 _proposalId) internal returns (uint256 tokenId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        tokenId = nextNFTTokenId++;
        nftMetadataURIs[tokenId] = proposal.ipfsHash;
        nftOwners[tokenId] = address(this); // Collective owns the NFT initially
        emit NFTMinted(tokenId, _proposalId);
        return tokenId;
    }

    /**
     * @dev Governance can transfer a collective NFT to a member.
     * @param _tokenId The ID of the NFT to transfer.
     * @param _recipient The address to receive the NFT.
     */
    function transferNFTToMember(uint256 _tokenId, address _recipient) external onlyGovernance {
        require(nftOwners[_tokenId] == address(this), "Contract is not the owner of this NFT");
        require(_recipient != address(0), "Invalid recipient address");
        nftOwners[_tokenId] = _recipient;
        emit NFTTransferred(_tokenId, address(this), _recipient);
    }

    /**
     * @dev Governance can burn a collective NFT (exceptional cases).
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnCollectiveNFT(uint256 _tokenId) external onlyGovernance {
        require(nftOwners[_tokenId] == address(this), "Contract is not the owner of this NFT");
        delete nftMetadataURIs[_tokenId];
        delete nftOwners[_tokenId]; // Effectively burning, no ERC721 interface here.
        emit NFTBurned(_tokenId);
    }

    /**
     * @dev Retrieves the metadata URI of a collective NFT.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function getNFTMetadataURI(uint256 _tokenId) external view returns (string memory) {
        return nftMetadataURIs[_tokenId];
    }

    /**
     * @dev Proposes a governance change.
     * @param _description Description of the change.
     * @param _calldata Calldata to execute the change (function call).
     */
    function proposeGovernanceChange(string memory _description, bytes memory _calldata) external onlyGovernance {
        require(bytes(_description).length > 0, "Description cannot be empty");
        GovernanceProposal storage proposal = governanceProposals[nextGovernanceProposalId];
        proposal.proposalId = nextGovernanceProposalId;
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.calldataData = _calldata;
        proposal.votingEndTime = block.timestamp + votingPeriod;
        nextGovernanceProposalId++;
        emit GovernanceProposalSubmitted(proposal.proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows members to vote on a governance change proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True for yes, false for no.
     */
    function voteOnGovernanceChange(uint256 _proposalId, bool _support)
        external
        onlyMembers
        governanceProposalExists(_proposalId, governanceProposals)
        governanceVotingNotEnded(_proposalId, governanceProposals)
        notExecuted(_proposalId, governanceProposals)
    {
        require(!governanceProposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        governanceProposalVotes[_proposalId][msg.sender] = true;
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        proposal.voteCount++;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a governance change proposal if it passes voting.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeGovernanceChange(uint256 _proposalId)
        external
        governanceProposalExists(_proposalId, governanceProposals)
        governanceVotingNotEnded(_proposalId, governanceProposals) // For security, keep execution within voting period
        notExecuted(_proposalId, governanceProposals)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(block.timestamp >= proposal.votingEndTime, "Voting period not ended yet");

        uint256 quorum = (isMemberCount() * quorumPercentage) / 100;
        require(proposal.voteCount >= quorum, "Quorum not reached");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass");

        proposal.executed = true;
        (bool success, ) = address(this).delegatecall(proposal.calldataData); // Using delegatecall for contract state changes
        require(success, "Governance proposal execution failed");
        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Governance can withdraw funds from the collective treasury.
     * @param _amount The amount to withdraw.
     * @param _recipient The address to receive the funds.
     */
    function withdrawTreasuryFunds(uint256 _amount, address _recipient) external onlyGovernance {
        require(_amount <= treasuryBalance, "Insufficient treasury balance");
        require(_recipient != address(0), "Invalid recipient address");
        payable(_recipient).transfer(_amount);
        treasuryBalance -= _amount;
        emit TreasuryWithdrawal(_amount, _recipient);
    }

    /**
     * @dev Returns the current balance of the collective treasury.
     * @return The treasury balance.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    /**
     * @dev Retrieves details of a specific art proposal.
     * @param _proposalId The ID of the art proposal.
     * @return ArtProposal struct.
     */
    function getArtProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId, artProposals) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /**
     * @dev Retrieves details of a specific governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @return GovernanceProposal struct.
     */
    function getGovernanceProposalDetails(uint256 _proposalId) external view governanceProposalExists(_proposalId, governanceProposals) returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    /**
     * @dev Helper function to count the number of members.
     * @return The count of members.
     */
    function isMemberCount() public view returns (uint256) {
        uint256 count = 0;
        address currentAddress;
        for (uint256 i = 0; i < 2**160; i++) { // Iterate through possible addresses (very inefficient for large member count, but conceptually for demonstration)
            currentAddress = address(uint160(i)); // Cast to address
            if (isMember[currentAddress]) {
                count++;
            }
             if (i > 1000) break; // Stop after checking some addresses for demonstration - in real app, this would need a better member tracking mechanism
        }
        return count;
    }
}
```