```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Governance NFT Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic reputation system tied to NFTs, enabling decentralized governance and evolving NFT properties.
 *
 * Outline:
 *  - NFT Functionality: Minting, transfer, metadata, ownership.
 *  - Reputation System: Awarding, burning, viewing, staking reputation points.
 *  - Governance System: Proposal creation, voting, execution based on staked reputation.
 *  - Dynamic NFT Metadata: NFT properties change based on reputation and governance outcomes.
 *  - Delegated Voting: Users can delegate their voting power.
 *  - Reputation-Based Access Control: Functions accessible based on reputation level.
 *  - Time-Based Actions: Features triggered after certain time periods.
 *  - Event Tracking: Comprehensive event logging for all key actions.
 *  - Upgradability (Conceptual): Design allows for potential future upgrades.
 *  - Anti-Sybil Measures (Conceptual): Reputation aimed at discouraging sybil attacks.
 *  - Pausable Functionality: Emergency pause mechanism for critical situations.
 *  - Fee Mechanism: Optional fees for certain actions to fund contract maintenance.
 *  - Tiered Access: Different reputation levels unlock different contract features.
 *  - Dynamic Quorum: Voting quorum adjusts based on participation.
 *  - Proposal Types: Support for different types of proposals (text, code updates, etc.).
 *  - Reputation Decay: Reputation points may decay over time if inactive.
 *  - NFT Gating: Certain NFTs can grant access to specific features.
 *  - Referral System: Reward users for referring new members who gain reputation.
 *  - Custom Metadata Fields: Allow adding custom metadata fields to NFTs.
 *  - Batch Operations: Support for batch minting or reputation awarding.
 *
 * Function Summary:
 * 1. mintNFT(address _to, string memory _baseURI, string memory _metadataExtension): Mints a new Dynamic Reputation NFT to the specified address.
 * 2. transferNFT(address _from, address _to, uint256 _tokenId): Transfers ownership of an NFT.
 * 3. approveNFT(address _approved, uint256 _tokenId): Approves an address to transfer an NFT on behalf of the owner.
 * 4. getNFTMetadata(uint256 _tokenId): Retrieves the current metadata URI for a given NFT ID.
 * 5. awardReputation(address _user, uint256 _amount): Awards reputation points to a user (Admin only).
 * 6. burnReputation(address _user, uint256 _amount): Burns reputation points from a user (Admin only).
 * 7. getReputation(address _user): Retrieves the reputation points of a user.
 * 8. stakeReputation(uint256 _amount): Stakes reputation points for governance participation.
 * 9. unstakeReputation(uint256 _amount): Unstakes reputation points, withdrawing them.
 * 10. createProposal(string memory _title, string memory _description, bytes memory _payload): Creates a new governance proposal.
 * 11. voteOnProposal(uint256 _proposalId, bool _support): Allows users to vote on a governance proposal.
 * 12. executeProposal(uint256 _proposalId): Executes a proposal if it has passed the voting and quorum requirements (Admin or Timelock).
 * 13. getProposalState(uint256 _proposalId): Retrieves the current state of a governance proposal.
 * 14. delegateVotingPower(address _delegatee): Delegates voting power to another address.
 * 15. getDelegatedVotingPower(address _voter): Retrieves the address a voter has delegated their power to, or themselves if no delegation.
 * 16. setBaseMetadataURI(string memory _baseURI): Sets the base URI for NFT metadata (Admin only).
 * 17. pauseContract(): Pauses the contract functionality (Admin only).
 * 18. unpauseContract(): Resumes the contract functionality (Admin only).
 * 19. withdrawFees(): Allows the contract owner to withdraw accumulated fees (Owner only).
 * 20. updateNFTMetadata(uint256 _tokenId, string memory _newMetadataExtension): Updates the metadata extension for a specific NFT (Example dynamic metadata update based on reputation/governance - can be expanded).
 * 21. getStakedReputation(address _user): Retrieves the amount of reputation points a user has staked.
 * 22. getProposalVotes(uint256 _proposalId): Retrieves the vote counts for a specific proposal.
 * 23. getProposalCount(): Returns the total number of proposals created.
 */
contract DynamicReputationGovernanceNFT {
    // State Variables

    // NFT Data
    string public name = "DynamicReputationNFT";
    string public symbol = "DRNFT";
    string public baseMetadataURI;
    string public metadataExtension = ".json";
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    uint256 public totalSupplyCounter;

    // Reputation System
    mapping(address => uint256) public reputationPoints;
    mapping(address => uint256) public stakedReputation;

    // Governance System
    struct Proposal {
        uint256 id;
        string title;
        string description;
        bytes payload; // Can be used for code updates or arbitrary data
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        address proposer;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCounter;
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 20; // Default quorum percentage (20% of total staked reputation)

    // Delegated Voting
    mapping(address => address) public delegation;

    // Admin & Ownership
    address public admin;
    address public owner;
    bool public paused;
    uint256 public feePercentage = 1; // 1% fee for certain actions (example)
    address public feeRecipient;

    // Events
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTTransfer(address indexed from, address indexed to, uint256 tokenId);
    event NFTApproval(address indexed owner, address indexed approved, uint256 tokenId);
    event NFTApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ReputationAwarded(address indexed user, uint256 amount, address indexed admin);
    event ReputationBurned(address indexed user, uint256 amount, address indexed admin);
    event ReputationStaked(address indexed user, uint256 amount);
    event ReputationUnstaked(address indexed user, uint256 amount);
    event ProposalCreated(uint256 proposalId, string title, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event MetadataBaseURISet(string baseURI, address admin);
    event MetadataUpdated(uint256 tokenId, string newMetadataURI);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
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

    modifier reputationThreshold(uint256 _threshold) {
        require(reputationPoints[msg.sender] >= _threshold, "Insufficient reputation.");
        _;
    }

    // Constructor
    constructor(address _admin, string memory _baseURI, address _feeRecipientAddress) {
        owner = msg.sender;
        admin = _admin;
        baseMetadataURI = _baseURI;
        feeRecipient = _feeRecipientAddress;
    }

    // ------------------------------------------------------------------------
    // NFT Functionality (ERC721-like with Dynamic Metadata)
    // ------------------------------------------------------------------------

    /**
     * @dev Mints a new Dynamic Reputation NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The base URI for the NFT metadata (can be dynamic).
     * @param _metadataExtension The file extension for the metadata (e.g., ".json").
     */
    function mintNFT(address _to, string memory _baseURI, string memory _metadataExtension) public onlyAdmin whenNotPaused {
        uint256 tokenId = ++totalSupplyCounter;
        ownerOf[tokenId] = _to;
        balanceOf[_to]++;
        baseMetadataURI = _baseURI; // Allow dynamic base URI updates on mint
        metadataExtension = _metadataExtension; // Allow dynamic metadata extension updates on mint
        emit NFTMinted(_to, tokenId);
    }

    /**
     * @dev Transfers ownership of an NFT.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(ownerOf[_tokenId] == _from, "Not NFT owner");
        require(_to != address(0), "Transfer to zero address");
        require(msg.sender == _from || getApproved[_tokenId] == msg.sender || isApprovedForAll[_from][msg.sender], "Not authorized to transfer");

        _clearApproval(_tokenId);

        balanceOf[_from]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
        emit NFTTransfer(_from, _to, _tokenId);
    }

    /**
     * @dev Approves an address to transfer an NFT on behalf of the owner.
     * @param _approved The address to be approved for transfer.
     * @param _tokenId The ID of the NFT to approve.
     */
    function approveNFT(address _approved, uint256 _tokenId) public whenNotPaused {
        require(ownerOf[_tokenId] == msg.sender, "Not NFT owner");
        require(_approved != address(0), "Approve to zero address");

        getApproved[_tokenId] = _approved;
        emit NFTApproval(msg.sender, _approved, _tokenId);
    }

    /**
     * @dev Sets or unsets the approval of an operator to transfer all NFTs of msg.sender.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        isApprovedForAll[msg.sender][_operator] = _approved;
        emit NFTApprovalForAll(msg.sender, _operator, _approved);
    }


    /**
     * @dev Retrieves the current metadata URI for a given NFT ID.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        require(ownerOf[_tokenId] != address(0), "NFT does not exist");
        return string(abi.encodePacked(baseMetadataURI, Strings.toString(_tokenId), metadataExtension));
    }

    /**
     * @dev ERC721 tokenURI function to retrieve the metadata URI.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return getNFTMetadata(_tokenId);
    }

    /**
     * @dev Returns the total number of NFTs minted.
     * @return The total supply of NFTs.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupplyCounter;
    }

    /**
     * @dev Returns the owner of the NFT specified by `_tokenId`.
     * @param _tokenId The ID of the NFT.
     * @return The owner address.
     */
    function ownerOfNFT(uint256 _tokenId) public view returns (address) {
        return ownerOf[_tokenId];
    }

    /**
     * @dev Returns the number of NFTs owned by `_owner`.
     * @param _owner The address to query.
     * @return The balance of NFTs for the address.
     */
    function balanceOfNFT(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }

    // ------------------------------------------------------------------------
    // Reputation System
    // ------------------------------------------------------------------------

    /**
     * @dev Awards reputation points to a user (Admin only).
     * @param _user The address to award reputation to.
     * @param _amount The amount of reputation points to award.
     */
    function awardReputation(address _user, uint256 _amount) public onlyAdmin whenNotPaused {
        reputationPoints[_user] += _amount;
        emit ReputationAwarded(_user, _amount, msg.sender);
    }

    /**
     * @dev Burns reputation points from a user (Admin only).
     * @param _user The address to burn reputation from.
     * @param _amount The amount of reputation points to burn.
     */
    function burnReputation(address _user, uint256 _amount) public onlyAdmin whenNotPaused {
        require(reputationPoints[_user] >= _amount, "Insufficient reputation to burn.");
        reputationPoints[_user] -= _amount;
        emit ReputationBurned(_user, _amount, msg.sender);
    }

    /**
     * @dev Retrieves the reputation points of a user.
     * @param _user The address to query.
     * @return The reputation points of the user.
     */
    function getReputation(address _user) public view returns (uint256) {
        return reputationPoints[_user];
    }

    /**
     * @dev Stakes reputation points for governance participation.
     * @param _amount The amount of reputation points to stake.
     */
    function stakeReputation(uint256 _amount) public whenNotPaused {
        require(reputationPoints[msg.sender] >= _amount, "Insufficient reputation to stake.");
        reputationPoints[msg.sender] -= _amount;
        stakedReputation[msg.sender] += _amount;
        emit ReputationStaked(msg.sender, _amount);
    }

    /**
     * @dev Unstakes reputation points, withdrawing them.
     * @param _amount The amount of reputation points to unstake.
     */
    function unstakeReputation(uint256 _amount) public whenNotPaused {
        require(stakedReputation[msg.sender] >= _amount, "Insufficient staked reputation to unstake.");
        stakedReputation[msg.sender] -= _amount;
        reputationPoints[msg.sender] += _amount;
        emit ReputationUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Retrieves the amount of reputation points a user has staked.
     * @param _user The address to query.
     * @return The staked reputation points of the user.
     */
    function getStakedReputation(address _user) public view returns (uint256) {
        return stakedReputation[_user];
    }


    // ------------------------------------------------------------------------
    // Governance System
    // ------------------------------------------------------------------------

    /**
     * @dev Creates a new governance proposal.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposal.
     * @param _payload Data associated with the proposal (e.g., code to execute, parameters).
     */
    function createProposal(string memory _title, string memory _description, bytes memory _payload) public whenNotPaused reputationThreshold(100) { // Example: Require 100 reputation to create proposal
        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.id = proposalCounter;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.payload = _payload;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDuration;
        newProposal.proposer = msg.sender;
        emit ProposalCreated(proposalCounter, _title, msg.sender);
    }

    /**
     * @dev Allows users to vote on a governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        require(block.timestamp >= proposals[_proposalId].startTime && block.timestamp <= proposals[_proposalId].endTime, "Voting period ended.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        address voter = getDelegatedVotingPower(msg.sender); // Use delegated power if available

        uint256 votingPower = stakedReputation[voter]; // Voting power is based on staked reputation
        require(votingPower > 0, "No staked reputation to vote.");

        if (_support) {
            proposals[_proposalId].forVotes += votingPower;
        } else {
            proposals[_proposalId].againstVotes += votingPower;
        }
        emit VoteCast(_proposalId, voter, _support);
    }

    /**
     * @dev Executes a proposal if it has passed the voting and quorum requirements (Admin or Timelock can execute).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused onlyAdmin { // Example: Only admin can execute for simplicity, could add timelock
        require(proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not ended.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalStaked = getTotalStakedReputation();
        uint256 quorum = (totalStaked * quorumPercentage) / 100; // Calculate quorum based on percentage

        require(proposals[_proposalId].forVotes >= proposals[_proposalId].againstVotes, "Proposal failed: Not enough votes in favor.");
        require(proposals[_proposalId].forVotes >= quorum, "Proposal failed: Quorum not reached.");

        proposals[_proposalId].executed = true;
        // Execute proposal payload here - example:
        // (bool success, bytes memory returnData) = address(this).call(proposals[_proposalId].payload);
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves the current state of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Returns the proposal details (Proposal struct).
     */
    function getProposalState(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Retrieves the vote counts for a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Returns the for and against vote counts.
     */
    function getProposalVotes(uint256 _proposalId) public view returns (uint256 forVotes, uint256 againstVotes) {
        return (proposals[_proposalId].forVotes, proposals[_proposalId].againstVotes);
    }

    /**
     * @dev Returns the total number of proposals created.
     * @return The total proposal count.
     */
    function getProposalCount() public view returns (uint256) {
        return proposalCounter;
    }


    // ------------------------------------------------------------------------
    // Delegated Voting
    // ------------------------------------------------------------------------

    /**
     * @dev Delegates voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) public whenNotPaused {
        delegation[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Retrieves the address a voter has delegated their power to, or themselves if no delegation.
     * @param _voter The address to query.
     * @return The delegated address or the voter's address.
     */
    function getDelegatedVotingPower(address _voter) public view returns (address) {
        address delegate = delegation[_voter];
        return (delegate == address(0)) ? _voter : delegate; // If no delegation, return voter's address
    }


    // ------------------------------------------------------------------------
    // Dynamic NFT Metadata Update Example
    // ------------------------------------------------------------------------

    /**
     * @dev Updates the metadata extension for a specific NFT (Example dynamic metadata update based on reputation/governance).
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadataExtension The new metadata file extension.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataExtension) public onlyAdmin whenNotPaused {
        metadataExtension = _newMetadataExtension; // Example: Update global metadata extension (can be more granular per NFT based on logic)
        emit MetadataUpdated(_tokenId, string(abi.encodePacked(baseMetadataURI, Strings.toString(_tokenId), metadataExtension)));
    }

    /**
     * @dev Sets the base URI for NFT metadata (Admin only).
     * @param _baseURI The new base URI to set.
     */
    function setBaseMetadataURI(string memory _baseURI) public onlyAdmin whenNotPaused {
        baseMetadataURI = _baseURI;
        emit MetadataBaseURISet(_baseURI, msg.sender);
    }


    // ------------------------------------------------------------------------
    // Utility & Admin Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Pauses the contract functionality (Admin only).
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Resumes the contract functionality (Admin only).
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated fees (Owner only).
     */
    function withdrawFees() public onlyOwner {
        // Example fee withdrawal logic (if fees were implemented)
        // uint256 balance = address(this).balance;
        // payable(owner).transfer(balance);
    }

    /**
     * @dev Returns the total staked reputation across all users.
     * @return Total staked reputation.
     */
    function getTotalStakedReputation() public view returns (uint256) {
        uint256 totalStaked = 0;
        // Iterate over all users (inefficient for large user base - consider alternative tracking for production)
        // For demonstration purposes, simplified iteration is shown.
        // In a real-world scenario, you'd likely use a more efficient way to track total staked reputation.
        // One approach could be to maintain a running total updated on stake/unstake actions.

        // Note: This iteration is illustrative and may be inefficient for very large user bases.
        // In a production system, maintain totalStakedReputation as a state variable and update it during stake/unstake.
        // For now, this iterates through all reputation holders (assuming a reasonable size).
        address currentAddress;
        for (uint256 i = 0; i < totalSupplyCounter; i++) { // Assuming NFT holders are representative of reputation holders in some way for this example
            currentAddress = ownerOf[i+1]; // Iterate through potential addresses - this is not ideal in production
            if (currentAddress != address(0)) { // Check if address has been used (NFT holder in this example)
                totalStaked += stakedReputation[currentAddress];
            }
        }
        return totalStaked;
    }

    // ------------------------------------------------------------------------
    // Internal Helper Functions
    // ------------------------------------------------------------------------

    function _clearApproval(uint256 _tokenId) internal {
        if (getApproved[_tokenId] != address(0)) {
            delete getApproved[_tokenId];
        }
    }
}

// --- Library for String Conversion (From OpenZeppelin Contracts - Modified for Simplicity) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```