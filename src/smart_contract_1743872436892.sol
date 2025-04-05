```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Content NFT Marketplace with On-Chain Governance and Evolving Traits
 * @author Gemini AI (Example - Not for Production)
 * @dev This contract implements a dynamic content NFT marketplace where NFTs can evolve based on creator updates,
 *      community interaction, and on-chain governance. It includes features for dynamic traits, content unlocking,
 *      staking, governance proposals, and a reputation system.
 *
 * **Outline and Function Summary:**
 *
 * **Core NFT Functions:**
 * 1. `mintNFT(address _to, string memory _baseMetadataURI, string memory _initialContentHash)`: Mints a new Dynamic Content NFT.
 * 2. `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 * 3. `approve(address _approved, uint256 _tokenId)`: Approves an address to operate on a single NFT.
 * 4. `getApproved(uint256 _tokenId)`: Gets the approved address for a single NFT.
 * 5. `setApprovalForAll(address _operator, bool _approved)`: Sets approval for an operator to manage all of the sender's NFTs.
 * 6. `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved for all NFTs of an owner.
 * 7. `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a given NFT, dynamically generated.
 * 8. `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT.
 * 9. `balanceOf(address _owner)`: Returns the balance of NFTs owned by an address.
 * 10. `totalSupply()`: Returns the total supply of NFTs.
 *
 * **Dynamic Content & Trait Evolution Functions:**
 * 11. `updateBaseMetadataURI(uint256 _tokenId, string memory _newBaseMetadataURI)`: Allows the NFT creator to update the base metadata URI.
 * 12. `setDynamicTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue)`: Allows the NFT creator to set or update a dynamic trait of an NFT.
 * 13. `getContentHash(uint256 _tokenId)`: Returns the current content hash of an NFT.
 * 14. `updateContentHash(uint256 _tokenId, string memory _newContentHash)`: Allows the NFT creator to update the content hash of an NFT.
 *
 * **On-Chain Governance & Community Functions:**
 * 15. `submitGovernanceProposal(string memory _proposalDescription, bytes memory _calldata)`: Allows NFT holders to submit governance proposals.
 * 16. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on governance proposals.
 * 17. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal.
 * 18. `getStakeAmount(address _user)`: Returns the amount of NFTs staked by a user.
 * 19. `stakeNFTs(uint256[] memory _tokenIds)`: Allows NFT holders to stake their NFTs for governance power and potential rewards.
 * 20. `unstakeNFTs(uint256[] memory _tokenIds)`: Allows NFT holders to unstake their NFTs.
 * 21. `getReputationScore(address _user)`: Returns the reputation score of a user based on participation and governance.
 * 22. `contributeToReputation(address _user, uint256 _amount)`: Allows the contract owner to manually contribute to a user's reputation score (e.g., for early contributors).
 *
 * **Admin & Utility Functions:**
 * 23. `setGovernanceThreshold(uint256 _newThreshold)`: Allows the contract owner to change the governance proposal threshold.
 * 24. `setStakingEnabled(bool _enabled)`: Allows the contract owner to enable or disable staking.
 * 25. `pauseContract()`: Pauses certain contract functionalities in case of emergency.
 * 26. `unpauseContract()`: Unpauses the contract.
 * 27. `withdrawContractBalance()`: Allows the contract owner to withdraw any ETH balance in the contract.
 */
contract DynamicContentNFTMarketplace {
    // State variables
    string public name = "DynamicContentNFT";
    string public symbol = "DCNFT";
    uint256 public totalSupplyCounter;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public ownerTokenCount;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(uint256 => string) public tokenBaseMetadataURIs; // Base URI for metadata, creator can update
    mapping(uint256 => string) public tokenContentHashes;     // Hash of the actual content, creator can update
    mapping(uint256 => mapping(string => string)) public dynamicTraits; // Dynamic traits for NFTs
    mapping(address => uint256) public reputationScores; // Reputation scores for users
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public proposalCounter;
    uint256 public governanceThreshold = 10; // Minimum reputation to submit a proposal
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Track votes for each proposal
    mapping(address => uint256) public stakedNFTCount;
    bool public stakingEnabled = true;
    bool public paused = false;

    address public owner;

    // Structs
    struct GovernanceProposal {
        uint256 id;
        string description;
        address proposer;
        bytes calldataData;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 executionTimestamp;
    }

    // Events
    event NFTMinted(uint256 tokenId, address to, string baseMetadataURI, string contentHash);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event MetadataUR updatedMetadataURI(uint256 tokenId, string newBaseMetadataURI);
    event DynamicTraitSet(uint256 tokenId, string traitName, string traitValue);
    event ContentHashUpdated(uint256 tokenId, string newContentHash);
    event GovernanceProposalSubmitted(uint256 proposalId, address proposer, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event NFTsStaked(address user, uint256[] tokenIds);
    event NFTsUnstaked(address user, uint256[] tokenIds);
    event ReputationContributed(address user, uint256 amount, address contributor);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenStakingEnabled() {
        require(stakingEnabled, "Staking is currently disabled.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "Not token owner.");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner.");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // ------------------------------------------------------------------------
    // Core NFT Functions (ERC721-like)
    // ------------------------------------------------------------------------

    /**
     * @dev Mints a new Dynamic Content NFT.
     * @param _to The address to mint the NFT to.
     * @param _baseMetadataURI The base URI for the NFT's metadata.
     * @param _initialContentHash The initial content hash for the NFT.
     */
    function mintNFT(address _to, string memory _baseMetadataURI, string memory _initialContentHash) public whenNotPaused {
        require(_to != address(0), "Mint to the zero address");
        uint256 newTokenId = ++totalSupplyCounter;
        tokenOwner[newTokenId] = _to;
        ownerTokenCount[_to]++;
        tokenBaseMetadataURIs[newTokenId] = _baseMetadataURI;
        tokenContentHashes[newTokenId] = _initialContentHash;
        emit NFTMinted(newTokenId, _to, _baseMetadataURI, _initialContentHash);
    }

    /**
     * @dev Transfers ownership of an NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) public virtual whenNotPaused validTokenId(_tokenId) onlyApprovedOrOwner(_tokenId) {
        require(_to != address(0), "Transfer to the zero address");
        address from = tokenOwner[_tokenId];
        _transfer(from, _to, _tokenId);
    }

    /**
     * @dev Approve another address to operate on the specified NFT.
     * @param _approved The address to be approved.
     * @param _tokenId The ID of the NFT to be approved.
     */
    function approve(address _approved, uint256 _tokenId) public virtual whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    /**
     * @dev Get the approved address for a single NFT.
     * @param _tokenId The ID of the NFT to get approval for.
     * @return The approved address, or address(0) if there is none.
     */
    function getApproved(uint256 _tokenId) public view virtual validTokenId(_tokenId) returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
     * @dev Approve or unapprove an operator to manage all of sender's assets.
     * @param _operator The address which will be approved or unapproved.
     * @param _approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved) public virtual whenNotPaused {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Check if an operator is approved to manage all assets of an owner.
     * @param _owner The address of the owner.
     * @param _operator The address of the operator.
     * @return True if the operator is approved for the owner, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) public view virtual returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for a token.
     *      This URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
     * @param _tokenId The ID of the NFT.
     * @return The URI string.
     */
    function tokenURI(uint256 _tokenId) public view virtual validTokenId(_tokenId) returns (string memory) {
        // Example: Dynamically generate URI based on base URI and tokenId.
        // In a real application, you might fetch traits and construct a more complex URI.
        return string(abi.encodePacked(tokenBaseMetadataURIs[_tokenId], "/", Strings.toString(_tokenId)));
    }

    /**
     * @dev Returns the owner of the NFT specified by `_tokenId`.
     * @param _tokenId The ID of the NFT to query.
     * @return address The owner of the NFT.
     */
    function ownerOf(uint256 _tokenId) public view virtual validTokenId(_tokenId) returns (address) {
        return tokenOwner[_tokenId];
    }

    /**
     * @dev Returns the number of NFTs owned by `_owner`.
     * @param _owner Address to be queried.
     * @return uint256 Number of NFTs owned by `_owner`.
     */
    function balanceOf(address _owner) public view virtual returns (uint256) {
        require(_owner != address(0), "Balance query for the zero address");
        return ownerTokenCount[_owner];
    }

    /**
     * @dev Returns the total number of NFTs in existence.
     * @return uint256 Total number of NFTs.
     */
    function totalSupply() public view virtual returns (uint256) {
        return totalSupplyCounter;
    }

    // ------------------------------------------------------------------------
    // Dynamic Content & Trait Evolution Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows the NFT creator to update the base metadata URI.
     * @param _tokenId The ID of the NFT to update.
     * @param _newBaseMetadataURI The new base metadata URI.
     */
    function updateBaseMetadataURI(uint256 _tokenId, string memory _newBaseMetadataURI) public validTokenId(_tokenId) onlyTokenOwner(_tokenId) whenNotPaused {
        tokenBaseMetadataURIs[_tokenId] = _newBaseMetadataURI;
        emit MetadataUR updatedMetadataURI(_tokenId, _newBaseMetadataURI);
    }

    /**
     * @dev Allows the NFT creator to set or update a dynamic trait of an NFT.
     * @param _tokenId The ID of the NFT to update.
     * @param _traitName The name of the dynamic trait.
     * @param _traitValue The value of the dynamic trait.
     */
    function setDynamicTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) public validTokenId(_tokenId) onlyTokenOwner(_tokenId) whenNotPaused {
        dynamicTraits[_tokenId][_traitName] = _traitValue;
        emit DynamicTraitSet(_tokenId, _traitName, _traitValue);
    }

    /**
     * @dev Returns the current content hash of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The content hash string.
     */
    function getContentHash(uint256 _tokenId) public view validTokenId(_tokenId) returns (string memory) {
        return tokenContentHashes[_tokenId];
    }

    /**
     * @dev Allows the NFT creator to update the content hash of an NFT.
     * @param _tokenId The ID of the NFT to update.
     * @param _newContentHash The new content hash.
     */
    function updateContentHash(uint256 _tokenId, string memory _newContentHash) public validTokenId(_tokenId) onlyTokenOwner(_tokenId) whenNotPaused {
        tokenContentHashes[_tokenId] = _newContentHash;
        emit ContentHashUpdated(_tokenId, _newContentHash);
    }

    // ------------------------------------------------------------------------
    // On-Chain Governance & Community Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows NFT holders to submit governance proposals.
     * @param _proposalDescription A description of the proposal.
     * @param _calldata The calldata to execute if the proposal passes.
     */
    function submitGovernanceProposal(string memory _proposalDescription, bytes memory _calldata) public whenNotPaused {
        require(reputationScores[msg.sender] >= governanceThreshold, "Insufficient reputation to submit proposal.");
        uint256 proposalId = ++proposalCounter;
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            description: _proposalDescription,
            proposer: msg.sender,
            calldataData: _calldata,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            executionTimestamp: 0
        });
        emit GovernanceProposalSubmitted(proposalId, msg.sender, _proposalDescription);
    }

    /**
     * @dev Allows NFT holders to vote on governance proposals.
     *      Voting power is determined by the number of staked NFTs.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(governanceProposals[_proposalId].proposer != address(0), "Proposal does not exist.");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        require(stakedNFTCount[msg.sender] > 0, "Must stake NFTs to vote."); // Voting power based on staked NFTs

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            governanceProposals[_proposalId].votesFor += stakedNFTCount[msg.sender]; // Vote power is stake count
        } else {
            governanceProposals[_proposalId].votesAgainst += stakedNFTCount[msg.sender];
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a passed governance proposal if votesFor > votesAgainst and proposal not yet executed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused onlyOwner { // Only owner can execute for security, could be DAO later
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist.");
        require(!proposal.executed, "Proposal already executed.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass.");

        (bool success, ) = address(this).call(proposal.calldataData); // Execute the calldata
        require(success, "Proposal execution failed.");

        proposal.executed = true;
        proposal.executionTimestamp = block.timestamp;
        emit GovernanceProposalExecuted(_proposalId);
    }


    /**
     * @dev Returns the amount of NFTs staked by a user.
     * @param _user The address of the user.
     * @return The number of NFTs staked.
     */
    function getStakeAmount(address _user) public view whenStakingEnabled returns (uint256) {
        return stakedNFTCount[_user];
    }

    /**
     * @dev Allows NFT holders to stake their NFTs for governance power.
     * @param _tokenIds Array of token IDs to stake.
     */
    function stakeNFTs(uint256[] memory _tokenIds) public whenNotPaused whenStakingEnabled {
        require(_tokenIds.length > 0, "Must stake at least one NFT.");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(tokenOwner[tokenId] == msg.sender, "Not owner of NFT to stake.");
            // In a real implementation, you would track staked tokens more formally, perhaps in a mapping.
            stakedNFTCount[msg.sender]++; // Simple staking by just counting staked NFTs
        }
        emit NFTsStaked(msg.sender, _tokenIds);
    }

    /**
     * @dev Allows NFT holders to unstake their NFTs.
     * @param _tokenIds Array of token IDs to unstake.
     */
    function unstakeNFTs(uint256[] memory _tokenIds) public whenNotPaused whenStakingEnabled {
        require(_tokenIds.length > 0, "Must unstake at least one NFT.");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(tokenOwner[tokenId] == msg.sender, "Not owner of NFT to unstake.");
            require(stakedNFTCount[msg.sender] > 0, "No NFTs staked to unstake."); // Basic check, improve in real impl.
            stakedNFTCount[msg.sender]--; // Simple unstaking by decrementing count.
        }
        emit NFTsUnstaked(msg.sender, _tokenIds);
    }

    /**
     * @dev Returns the reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev Allows the contract owner to manually contribute to a user's reputation score.
     *      This could be used for rewarding early contributors or community members.
     * @param _user The address of the user to contribute to.
     * @param _amount The amount to contribute.
     */
    function contributeToReputation(address _user, uint256 _amount) public onlyOwner whenNotPaused {
        reputationScores[_user] += _amount;
        emit ReputationContributed(_user, _amount, msg.sender);
    }


    // ------------------------------------------------------------------------
    // Admin & Utility Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows the contract owner to change the governance proposal threshold.
     * @param _newThreshold The new minimum reputation required to submit a proposal.
     */
    function setGovernanceThreshold(uint256 _newThreshold) public onlyOwner whenNotPaused {
        governanceThreshold = _newThreshold;
    }

    /**
     * @dev Allows the contract owner to enable or disable staking.
     * @param _enabled True to enable staking, false to disable.
     */
    function setStakingEnabled(bool _enabled) public onlyOwner whenNotPaused {
        stakingEnabled = _enabled;
    }

    /**
     * @dev Pauses the contract, preventing certain functionalities.
     *      Only the owner can pause.
     */
    function pauseContract() public onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring functionalities.
     *      Only the owner can unpause.
     */
    function unpauseContract() public onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw any ETH balance in the contract.
     *      Useful for withdrawing fees or accidental ETH sent to the contract.
     */
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    // ------------------------------------------------------------------------
    // Internal helper functions
    // ------------------------------------------------------------------------

    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual {
        require(tokenOwner[_tokenId] == _from, "From address is not the owner");
        require(_to != address(0), "Transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _tokenId);

        _clearApproval(_tokenId);

        ownerTokenCount[_from]--;
        ownerTokenCount[_to]++;
        tokenOwner[_tokenId] = _to;

        emit NFTTransferred(_tokenId, _from, _to);

        _afterTokenTransfer(_from, _to, _tokenId);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view virtual returns (bool) {
        require(tokenOwner[_tokenId] != address(0), "Token ID does not exist");
        address owner_ = tokenOwner[_tokenId];
        return (_spender == owner_ || getApproved(_tokenId) == _spender || isApprovedForAll(owner_, _spender));
    }

    function _clearApproval(uint256 _tokenId) internal virtual {
        if (tokenApprovals[_tokenId] != address(0)) {
            delete tokenApprovals[_tokenId];
        }
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual {}

    function _afterTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual {}
}

// Library for converting uint to string
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toAddressString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 + _ADDRESS_LENGTH * 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        uint256 addrUint = uint256(uint160(addr));
        for (uint256 i = 0; i < _ADDRESS_LENGTH; i++) {
            buffer[2 + _ADDRESS_LENGTH * 2 - 1 - i * 2] = _HEX_SYMBOLS[(addrUint & 0xf)];
            buffer[2 + _ADDRESS_LENGTH * 2 - 2 - i * 2] = _HEX_SYMBOLS[(addrUint >> 4) & 0xf];
            addrUint >>= 8;
        }
        return string(buffer);
    }
}
```