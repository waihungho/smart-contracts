```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Utility NFT Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT that evolves based on user reputation and unlocks utility.
 *
 * **Contract Outline & Function Summary:**
 *
 * **Core NFT Functionality:**
 * 1. `mint(address _to, string memory _baseURI)`: Mints a new Reputation NFT to the specified address with an initial base URI. (Admin only)
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT, restricted by reputation level.
 * 3. `tokenURI(uint256 _tokenId)`: Returns the dynamic URI for a given token ID, based on reputation.
 * 4. `approve(address _approved, uint256 _tokenId)`: Approves an address to operate on a single NFT. (Standard ERC721)
 * 5. `setApprovalForAll(address _operator, bool _approved)`: Enables or disables approval for a third party to manage all of msg.sender's assets. (Standard ERC721)
 * 6. `getApproved(uint256 _tokenId)`: Gets the approved address for a single NFT. (Standard ERC721)
 * 7. `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved for all tokens of an owner. (Standard ERC721)
 *
 * **Reputation System:**
 * 8. `increaseReputation(address _user, uint256 _amount)`: Increases the reputation of a user. (Admin/Oracle/External Contract Callable)
 * 9. `decreaseReputation(address _user, uint256 _amount)`: Decreases the reputation of a user. (Admin/Oracle/External Contract Callable)
 * 10. `getReputation(address _user)`: Returns the reputation score of a user.
 * 11. `setReputationThreshold(uint256 _level, uint256 _threshold)`: Sets the reputation threshold for a specific level. (Admin only)
 * 12. `getReputationLevel(address _user)`: Returns the reputation level of a user based on their score and thresholds.
 *
 * **Dynamic NFT Logic & Utility:**
 * 13. `updateNFTMetadata(uint256 _tokenId)`: Updates the metadata URI of an NFT based on the owner's current reputation level. (Internal trigger after reputation change)
 * 14. `setBaseURI(string memory _newBaseURI)`: Sets the base URI prefix for all NFTs. (Admin only)
 * 15. `setContractMetadataURI(string memory _uri)`: Sets the URI for the contract metadata. (Admin only)
 * 16. `unlockUtility(uint256 _tokenId)`: Allows NFT holders above a certain reputation level to access a specific utility/feature. (Example - can be extended)
 * 17. `burnNFT(uint256 _tokenId)`: Burns an NFT, only allowed if the owner's reputation is below a certain threshold. (Reputation-based NFT destruction)
 *
 * **Governance & Community Features (Simplified):**
 * 18. `proposeReputationChange(address _targetUser, int256 _changeAmount, string memory _reason)`: Allows NFT holders with sufficient reputation to propose reputation changes for others. (Basic Proposal System)
 * 19. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows NFT holders with sufficient reputation to vote on reputation change proposals. (Basic Voting System)
 *
 * **Admin & Management:**
 * 20. `setAdmin(address _newAdmin)`: Changes the contract admin. (Admin only)
 * 21. `pauseContract()`: Pauses the contract, restricting certain functionalities. (Admin only)
 * 22. `unpauseContract()`: Unpauses the contract, restoring functionalities. (Admin only)
 */
contract DynamicReputationNFT {
    string public name = "DynamicReputationNFT";
    string public symbol = "DRNFT";
    string public contractMetadataURI;
    string public baseURI;

    address public admin;
    bool public paused;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public reputation;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(uint256 => uint256) public tokenReputationLevel; // Store the reputation level at the time of last metadata update.

    uint256 public totalSupply;

    // Reputation Level Thresholds (Example: Level 1: 100, Level 2: 500, Level 3: 1000, etc.)
    mapping(uint256 => uint256) public reputationThresholds;
    uint256 public constant MAX_REPUTATION_LEVEL = 5;

    // Utility Unlock Threshold (Example: Level 2 and above can unlock utility)
    uint256 public utilityUnlockLevel = 2;

    // Reputation Change Proposals
    struct ReputationProposal {
        address proposer;
        address targetUser;
        int256 changeAmount;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool active;
        uint256 proposalEndTime;
    }
    mapping(uint256 => ReputationProposal) public reputationProposals;
    uint256 public proposalCounter;
    uint256 public proposalVoteDuration = 7 days; // Example duration

    // Minimum Reputation Level to propose/vote
    uint256 public proposalVoteMinReputationLevel = 1;

    // Minimum Reputation Level to transfer NFTs
    uint256 public transferMinReputationLevel = 0; // Example: Level 0 can transfer

    // Reputation level below which NFT can be burned.
    uint256 public burnReputationThreshold = 0; // Example: Level 0 and below can be burned

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Mint(address indexed to, uint256 tokenId);
    event ReputationIncreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address indexed user, uint256 amount, uint256 newReputation);
    event NFTMetadataUpdated(uint256 indexed tokenId, uint256 reputationLevel);
    event UtilityUnlocked(uint256 indexed tokenId);
    event NFTBurned(uint256 indexed tokenId, address indexed owner);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ReputationProposalCreated(uint256 proposalId, address proposer, address targetUser, int256 changeAmount, string reason);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, bool success);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
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

    constructor(string memory _baseURI, string memory _contractMetadataURI) {
        admin = msg.sender;
        baseURI = _baseURI;
        contractMetadataURI = _contractMetadataURI;

        // Initialize Reputation Thresholds (Example Levels)
        reputationThresholds[1] = 100;
        reputationThresholds[2] = 500;
        reputationThresholds[3] = 1000;
        reputationThresholds[4] = 2500;
        reputationThresholds[5] = 5000;
    }

    /**
     * @dev Mints a new Reputation NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The initial base URI for this NFT.
     */
    function mint(address _to, string memory _baseURI) public onlyAdmin {
        require(_to != address(0), "Mint to the zero address");
        totalSupply++;
        uint256 tokenId = totalSupply;
        ownerOf[tokenId] = _to;
        baseURI = _baseURI; // Consider if baseURI should be unique per token or contract-wide
        emit Transfer(address(0), _to, tokenId);
        emit Mint(_to, tokenId);
        _updateNFTMetadata(tokenId); // Initial metadata update on mint
    }

    /**
     * @dev Transfers ownership of an NFT from one address to another.
     * @param _from The current owner address.
     * @param _to The address to transfer to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_to != address(0), "Transfer to the zero address");
        require(ownerOf[_tokenId] == _from, "Not the owner");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner");
        require(getReputationLevel(_from) >= transferMinReputationLevel, "Sender reputation too low to transfer");

        _clearApproval(_tokenId);
        ownerOf[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
        _updateNFTMetadata(_tokenId); // Update metadata for the new owner
    }

    /**
     * @dev Gets the URI of the metadata for a token.
     * @param _tokenId The ID of the NFT.
     * @return The URI string.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token URI query for nonexistent token");
        uint256 currentLevel = tokenReputationLevel[_tokenId]; // Use the stored level for consistency
        return string(abi.encodePacked(baseURI, "/", currentLevel, "/", _tokenId, ".json"));
    }

    /**
     * @dev Updates the NFT metadata URI based on the owner's current reputation level.
     * @param _tokenId The ID of the NFT.
     */
    function _updateNFTMetadata(uint256 _tokenId) internal {
        if (!_exists(_tokenId)) return; // Safety check
        uint256 currentLevel = getReputationLevel(ownerOf[_tokenId]);
        tokenReputationLevel[_tokenId] = currentLevel; // Store the level at update time
        emit NFTMetadataUpdated(_tokenId, currentLevel);
    }

    /**
     * @dev Increases the reputation of a user. Callable by admin or designated oracle/contract.
     * @param _user The address of the user to increase reputation for.
     * @param _amount The amount to increase reputation by.
     */
    function increaseReputation(address _user, uint256 _amount) public onlyAdmin { // Or make it callable by a trusted oracle contract
        reputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount, reputation[_user]);
        // Update metadata for all NFTs owned by this user (potentially gas intensive, consider batch updates or on-demand updates)
        _updateAllNFTMetadataOfUser(_user);
    }

    /**
     * @dev Decreases the reputation of a user. Callable by admin or designated oracle/contract.
     * @param _user The address of the user to decrease reputation for.
     * @param _amount The amount to decrease reputation by.
     */
    function decreaseReputation(address _user, uint256 _amount) public onlyAdmin { // Or make it callable by a trusted oracle contract
        if (reputation[_user] >= _amount) {
            reputation[_user] -= _amount;
        } else {
            reputation[_user] = 0; // Prevent negative reputation
        }
        emit ReputationDecreased(_user, _amount, reputation[_user]);
        // Update metadata for all NFTs owned by this user
        _updateAllNFTMetadataOfUser(_user);
    }

    /**
     * @dev Gets the reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputation(address _user) public view returns (uint256) {
        return reputation[_user];
    }

    /**
     * @dev Sets the reputation threshold for a specific level.
     * @param _level The reputation level to set the threshold for.
     * @param _threshold The reputation score threshold.
     */
    function setReputationThreshold(uint256 _level, uint256 _threshold) public onlyAdmin {
        require(_level > 0 && _level <= MAX_REPUTATION_LEVEL, "Invalid reputation level");
        reputationThresholds[_level] = _threshold;
    }

    /**
     * @dev Gets the reputation level of a user based on their score and thresholds.
     * @param _user The address of the user.
     * @return The reputation level (0 if below level 1).
     */
    function getReputationLevel(address _user) public view returns (uint256) {
        uint256 score = reputation[_user];
        for (uint256 level = MAX_REPUTATION_LEVEL; level >= 1; level--) {
            if (score >= reputationThresholds[level]) {
                return level;
            }
        }
        return 0; // Level 0 for below level 1 threshold
    }

    /**
     * @dev Sets the base URI for all NFTs.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyAdmin {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Sets the contract metadata URI.
     * @param _uri The new contract metadata URI.
     */
    function setContractMetadataURI(string memory _uri) public onlyAdmin {
        contractMetadataURI = _uri;
    }

    /**
     * @dev Allows NFT holders above a certain reputation level to unlock a utility feature.
     * @param _tokenId The ID of the NFT.
     */
    function unlockUtility(uint256 _tokenId) public whenNotPaused {
        require(ownerOf[_tokenId] == msg.sender, "Not the owner");
        require(getReputationLevel(msg.sender) >= utilityUnlockLevel, "Reputation level too low to unlock utility");
        emit UtilityUnlocked(_tokenId);
        // Implement actual utility unlock logic here - e.g., call another contract, set a flag, etc.
        // For this example, it's just an event.
    }

    /**
     * @dev Burns an NFT if the owner's reputation is below a certain threshold.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public whenNotPaused {
        require(ownerOf[_tokenId] == msg.sender, "Not the owner");
        require(getReputationLevel(msg.sender) <= burnReputationThreshold, "Reputation level too high to burn NFT");
        _burn(_tokenId);
    }

    /**
     * @dev Allows NFT holders with sufficient reputation to propose reputation changes for others.
     * @param _targetUser The user whose reputation is proposed to be changed.
     * @param _changeAmount The amount of reputation change (positive or negative).
     * @param _reason The reason for the proposed change.
     */
    function proposeReputationChange(address _targetUser, int256 _changeAmount, string memory _reason) public whenNotPaused {
        require(getReputationLevel(msg.sender) >= proposalVoteMinReputationLevel, "Reputation level too low to propose");
        require(msg.sender != _targetUser, "Cannot propose reputation change for yourself");

        proposalCounter++;
        reputationProposals[proposalCounter] = ReputationProposal({
            proposer: msg.sender,
            targetUser: _targetUser,
            changeAmount: _changeAmount,
            reason: _reason,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            active: true,
            proposalEndTime: block.timestamp + proposalVoteDuration
        });
        emit ReputationProposalCreated(proposalCounter, msg.sender, _targetUser, _changeAmount, _reason);
    }

    /**
     * @dev Allows NFT holders with sufficient reputation to vote on reputation change proposals.
     * @param _proposalId The ID of the reputation change proposal.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(getReputationLevel(msg.sender) >= proposalVoteMinReputationLevel, "Reputation level too low to vote");
        require(reputationProposals[_proposalId].active, "Proposal is not active");
        require(block.timestamp <= reputationProposals[_proposalId].proposalEndTime, "Voting time expired");

        // Basic voting - in a real system, track individual votes to prevent double voting per user.
        if (_support) {
            reputationProposals[_proposalId].votesFor++;
        } else {
            reputationProposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a reputation change proposal if voting time is over and it passes (e.g., more 'for' votes than 'against').
     * @param _proposalId The ID of the reputation change proposal.
     */
    function executeReputationProposal(uint256 _proposalId) public whenNotPaused {
        require(reputationProposals[_proposalId].active, "Proposal is not active");
        require(block.timestamp > reputationProposals[_proposalId].proposalEndTime, "Voting time not expired yet");
        require(!reputationProposals[_proposalId].executed, "Proposal already executed");

        ReputationProposal storage proposal = reputationProposals[_proposalId];
        proposal.active = false;
        proposal.executed = true;

        bool success = false;
        if (proposal.votesFor > proposal.votesAgainst) { // Simple majority example
            if (proposal.changeAmount > 0) {
                increaseReputation(proposal.targetUser, uint256(proposal.changeAmount));
            } else if (proposal.changeAmount < 0) {
                decreaseReputation(proposal.targetUser, uint256(uint256(-proposal.changeAmount))); // Convert to uint256 for decrease
            }
            success = true;
        }
        emit ProposalExecuted(_proposalId, success);
    }

    /**
     * @dev Sets a new admin address.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Admin address cannot be zero address");
        admin = _newAdmin;
    }

    /**
     * @dev Pauses the contract, restricting certain functionalities.
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /**
     * @dev Unpauses the contract, restoring functionalities.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    // -------------------- ERC721 Standard Functions (Simplified) --------------------

    function balanceOf(address _owner) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (ownerOf[i] == _owner) {
                count++;
            }
        }
        return count;
    }

    function ownerOfToken(uint256 _tokenId) public view returns (address) { // Renamed to avoid conflict
        return ownerOf[_tokenId];
    }

    function approve(address _approved, uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        require(ownerOf[_tokenId] == msg.sender, "ERC721: approve caller is not owner nor approved for all");

        tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        require(_exists(_tokenId), "ERC721: approved or owner query for nonexistent token");
        address owner = ownerOf[_tokenId];
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    function _clearApproval(uint256 _tokenId) internal {
        if (tokenApprovals[_tokenId] != address(0)) {
            delete tokenApprovals[_tokenId];
        }
    }

    function _burn(uint256 _tokenId) internal {
        require(_exists(_tokenId), "ERC721: burn query for nonexistent token");
        address owner = ownerOf[_tokenId];

        _clearApproval(_tokenId);
        delete ownerOf[_tokenId];
        delete tokenReputationLevel[_tokenId];

        totalSupply--;
        emit Transfer(owner, address(0), _tokenId);
        emit NFTBurned(_tokenId, owner);
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return ownerOf[_tokenId] != address(0);
    }

    // Helper function to update metadata for all NFTs owned by a user.
    function _updateAllNFTMetadataOfUser(address _user) internal {
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (ownerOf[i] == _user) {
                _updateNFTMetadata(i);
            }
        }
    }
}
```