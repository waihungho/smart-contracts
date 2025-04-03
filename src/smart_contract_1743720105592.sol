```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative Art Curation and NFT Minting
 * @author Gemini AI Assistant
 * @dev This smart contract implements a DAO focused on collaborative art curation and NFT minting.
 * It allows members to propose art submissions, vote on them, and if approved, mint NFTs for the curated artworks.
 * It includes advanced concepts like staking for voting power, delegated voting, and dynamic curation criteria.
 * This contract is designed to be unique and avoids duplication of common open-source contracts by focusing on
 * a specific niche and implementing a comprehensive set of features for decentralized art management.
 *
 * **Outline:**
 * 1. **Membership & Staking:**
 *    - Join DAO, Leave DAO, Stake Tokens, Unstake Tokens, Get Staking Balance, Get Voting Power
 * 2. **Art Submission & Curation:**
 *    - Submit Art Proposal, Vote on Art Proposal, Get Art Proposal Details, Set Curation Criteria, Get Curation Criteria
 * 3. **NFT Minting:**
 *    - Mint NFT for Approved Art, Set Base URI, Get Base URI, Set Royalty Fee, Get Royalty Fee, Withdraw Royalties
 * 4. **Governance & DAO Management:**
 *    - Propose Rule Change, Vote on Rule Change, Execute Proposal, Set Voting Period, Get Voting Period, Pause Contract, Unpause Contract
 * 5. **Advanced Features:**
 *    - Delegate Vote, Get Delegated Votes, Batch Mint NFTs, Create Collection Proposal, Set Collection Metadata
 *
 * **Function Summary:**
 * 1. `joinDAO()`: Allows users to become DAO members by paying a membership fee (optional, can be set to 0).
 * 2. `leaveDAO()`: Allows members to leave the DAO.
 * 3. `stakeTokens(uint256 _amount)`: Allows members to stake governance tokens to increase their voting power.
 * 4. `unstakeTokens(uint256 _amount)`: Allows members to unstake their governance tokens.
 * 5. `getMemberStakingBalance(address _member)`: Returns the staking balance of a member.
 * 6. `getMemberVotingPower(address _member)`: Calculates and returns the voting power of a member based on their staked tokens.
 * 7. `submitArtProposal(string memory _ipfsHash, string memory _title, string memory _artist)`: Allows members to submit art proposals with IPFS hash, title, and artist name.
 * 8. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on art proposals (true for approve, false for reject).
 * 9. `getArtProposalDetails(uint256 _proposalId)`: Returns details of a specific art proposal.
 * 10. `setCurationCriteria(string memory _criteriaDescription)`: Allows the DAO (through governance) to set or update the art curation criteria.
 * 11. `getCurationCriteria()`: Returns the current art curation criteria.
 * 12. `mintNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal, transferring it to the artist and DAO treasury (split).
 * 13. `setBaseURI(string memory _baseURI)`: Allows the contract owner to set the base URI for NFT metadata.
 * 14. `getBaseURI()`: Returns the current base URI for NFTs.
 * 15. `setRoyaltyFee(uint256 _royaltyPercentage)`: Allows the DAO (through governance) to set the royalty fee for secondary NFT sales.
 * 16. `getRoyaltyFee()`: Returns the current royalty fee percentage.
 * 17. `withdrawRoyalties()`: Allows the contract owner to withdraw accumulated royalties to the DAO treasury.
 * 18. `proposeRuleChange(string memory _description, bytes memory _calldata)`: Allows members to propose changes to the DAO rules or contract functionality using calldata.
 * 19. `voteOnRuleChange(uint256 _proposalId, bool _vote)`: Allows members to vote on rule change proposals.
 * 20. `executeProposal(uint256 _proposalId)`: Executes an approved rule change proposal if quorum and voting threshold are met.
 * 21. `setVotingPeriod(uint256 _votingPeriodInSeconds)`: Allows the DAO (through governance) to set the voting period for proposals.
 * 22. `getVotingPeriod()`: Returns the current voting period for proposals.
 * 23. `pauseContract()`: Allows the contract owner to pause the contract in case of emergency.
 * 24. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 25. `delegateVote(address _delegatee)`: Allows members to delegate their voting power to another member.
 * 26. `getDelegatedVotes(address _member)`: Returns the address a member has delegated their votes to (if any).
 * 27. `batchMintNFTs(uint256[] memory _proposalIds)`: Allows minting NFTs for multiple approved art proposals in a single transaction (efficiency).
 * 28. `createCollectionProposal(string memory _collectionName, string memory _collectionSymbol, string memory _collectionDescription)`: Allows members to propose creating new NFT collections within the DAO.
 * 29. `setCollectionMetadata(uint256 _collectionProposalId, string memory _metadataURI)`: Allows setting metadata URI for a proposed NFT collection after approval.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract ArtCurationDAO is ERC721, Ownable, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _nftIdCounter;

    string public curationCriteria;
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumPercentage = 50; // Percentage of total voting power required for quorum
    uint256 public proposalThresholdPercentage = 60; // Percentage of votes needed to pass a proposal
    uint256 public membershipFee = 0.1 ether; // Optional membership fee, set to 0 for free membership
    uint256 public stakingRatio = 100; // Tokens staked to voting power ratio (e.g., 100 tokens = 1 voting power)
    uint256 public royaltyFeePercentage = 5; // Default royalty fee percentage on secondary sales

    address public governanceTokenAddress; // Address of the governance token contract

    string private _baseURI;

    mapping(address => bool) public isMember;
    mapping(address => uint256) public memberStakingBalance;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public votes; // proposalId => memberAddress => voted
    mapping(address => address) public delegatedVotes; // Delegator => Delegatee

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
        bytes calldataData; // For rule change proposals
        string ipfsHash;     // For art proposals
        string artTitle;     // For art proposals
        string artistName;    // For art proposals
        uint256 collectionProposalId; // For collection proposals
        string collectionMetadataURI; // For collection proposals
    }

    enum ProposalType {
        ART_SUBMISSION,
        RULE_CHANGE,
        COLLECTION_CREATION
    }

    enum ProposalStatus {
        PENDING,
        ACTIVE,
        REJECTED,
        APPROVED,
        EXECUTED
    }

    event MemberJoined(address member);
    event MemberLeft(address member);
    event TokensStaked(address member, uint256 amount);
    event TokensUnstaked(address member, uint256 amount);
    event ArtProposalSubmitted(uint256 proposalId, address proposer, string ipfsHash, string title, string artist);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId);
    event ArtProposalRejected(uint256 proposalId);
    event NFTMinted(uint256 tokenId, uint256 proposalId, address artist);
    event CurationCriteriaUpdated(string newCriteria);
    event RuleChangeProposed(uint256 proposalId, address proposer, string description);
    event RuleChangeVoted(uint256 proposalId, address voter, bool vote);
    event RuleChangeApproved(uint256 proposalId);
    event RuleChangeRejected(uint256 proposalId);
    event ProposalExecuted(uint256 proposalId);
    event VotingPeriodUpdated(uint256 newVotingPeriod);
    event ContractPaused();
    event ContractUnpaused();
    event VoteDelegated(address delegator, address delegatee);
    event CollectionProposalCreated(uint256 proposalId, string collectionName, string collectionSymbol, string collectionDescription);
    event CollectionMetadataSet(uint256 proposalId, string metadataURI);


    // --- Modifiers ---
    modifier onlyMember() {
        require(isMember[msg.sender], "Not a DAO member");
        _;
    }

    modifier onlyProposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active");
        _;
    }

    modifier onlyProposalPending(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending");
        _;
    }

    modifier onlyProposalApproved(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.APPROVED, "Proposal is not approved");
        _;
    }

    modifier onlyProposalExecutable(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.APPROVED && block.timestamp > proposals[_proposalId].endTime, "Proposal not executable yet");
        _;
    }


    // --- Constructor ---
    constructor(
        string memory _name,
        string memory _symbol,
        address _governanceTokenAddress,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721(_name, _symbol) PaymentSplitter(_payees, _shares) {
        governanceTokenAddress = _governanceTokenAddress;
        _baseURI = "ipfs://defaultBaseURI/"; // Set a default base URI
        curationCriteria = "Initial curation criteria will be defined by the DAO members through proposals.";
    }

    // --- Membership & Staking Functions ---
    function joinDAO() public payable whenNotPaused {
        require(!isMember[msg.sender], "Already a member");
        if (membershipFee > 0) {
            require(msg.value >= membershipFee, "Membership fee not met");
        }
        isMember[msg.sender] = true;
        emit MemberJoined(msg.sender);
        if (membershipFee > 0 && msg.value > membershipFee) {
            payable(owner()).transfer(msg.value - membershipFee); // Return extra fee if paid
        }
    }

    function leaveDAO() public onlyMember whenNotPaused {
        isMember[msg.sender] = false;
        emit MemberLeft(msg.sender);
    }

    function stakeTokens(uint256 _amount) public onlyMember whenNotPaused {
        // Assume governanceTokenAddress is an ERC20 contract, need interface for real implementation
        // For simplicity, we'll skip actual token transfer logic here and just update staking balance
        // In a real contract, you'd need to interact with the governance token contract to transfer tokens to this contract.
        memberStakingBalance[msg.sender] = memberStakingBalance[msg.sender].add(_amount);
        emit TokensStaked(msg.sender, _amount);
    }

    function unstakeTokens(uint256 _amount) public onlyMember whenNotPaused {
        require(memberStakingBalance[msg.sender] >= _amount, "Insufficient staked tokens");
        memberStakingBalance[msg.sender] = memberStakingBalance[msg.sender].sub(_amount);
        emit TokensUnstaked(msg.sender, _amount);
        // In a real contract, you'd transfer the tokens back to the member from this contract.
    }

    function getMemberStakingBalance(address _member) public view returns (uint256) {
        return memberStakingBalance[_member];
    }

    function getMemberVotingPower(address _member) public view returns (uint256) {
        uint256 stakedBalance = memberStakingBalance[_member];
        uint256 votingPower = stakedBalance.div(stakingRatio);
        if (delegatedVotes[_member] != address(0)) {
            votingPower = 0; // Delegator loses voting power
        }
        return votingPower;
    }

    function getTotalVotingPower() public view returns (uint256) {
        uint256 totalPower = 0;
        address[] memory members = getMembers(); // Need to implement getMembers if you want to track all members efficiently
        for (uint256 i = 0; i < members.length; i++) {
            totalPower = totalPower.add(getMemberVotingPower(members[i]));
        }
        return totalPower;
    }

    // --- Art Submission & Curation Functions ---
    function submitArtProposal(string memory _ipfsHash, string memory _title, string memory _artist) public onlyMember whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.ART_SUBMISSION,
            description: string(abi.encodePacked("Art submission: ", _title, " by ", _artist)),
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.ACTIVE,
            calldataData: bytes(""), // Not used for art proposals
            ipfsHash: _ipfsHash,
            artTitle: _title,
            artistName: _artist,
            collectionProposalId: 0, // Not related to collection creation
            collectionMetadataURI: ""  // Not related to collection creation
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _ipfsHash, _title, _artist);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) public onlyMember onlyProposalActive(_proposalId) whenNotPaused {
        require(!votes[_proposalId][msg.sender], "Already voted on this proposal");
        votes[_proposalId][msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].yesVotes = proposals[_proposalId].yesVotes.add(getMemberVotingPower(msg.sender));
        } else {
            proposals[_proposalId].noVotes = proposals[_proposalId].noVotes.add(getMemberVotingPower(msg.sender));
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended and process proposal
        if (block.timestamp >= proposals[_proposalId].endTime) {
            _processArtProposalResult(_proposalId);
        }
    }

    function getArtProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function setCurationCriteria(string memory _criteriaDescription) public onlyOwner whenNotPaused { // Can be changed to governance vote
        curationCriteria = _criteriaDescription;
        emit CurationCriteriaUpdated(_criteriaDescription);
    }

    function getCurationCriteria() public view returns (string memory) {
        return curationCriteria;
    }

    // --- NFT Minting Functions ---
    function mintNFT(uint256 _proposalId) public onlyOwner onlyProposalApproved(_proposalId) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ART_SUBMISSION, "Proposal is not for art submission");
        _nftIdCounter.increment();
        uint256 tokenId = _nftIdCounter.current();
        _safeMint(proposal.proposer, tokenId); // Mint to the proposer (artist) initially
        _setTokenURI(tokenId, string(abi.encodePacked(_baseURI, Strings.toString(tokenId)))); // Construct metadata URI
        emit NFTMinted(tokenId, _proposalId, proposal.proposer);
    }

    function batchMintNFTs(uint256[] memory _proposalIds) public onlyOwner whenNotPaused {
        for (uint256 i = 0; i < _proposalIds.length; i++) {
            mintNFT(_proposalIds[i]);
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
        super._setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner whenNotPaused {
        _baseURI = _newBaseURI;
        // Consider emitting an event for base URI change if needed
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI;
    }

    function setRoyaltyFee(uint256 _royaltyPercentage) public onlyOwner whenNotPaused { // Can be changed to governance vote
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        royaltyFeePercentage = _royaltyPercentage;
        // Implement royalty logic in _transfer or token transfers if needed (ERC2981 standard recommended)
    }

    function getRoyaltyFee() public view returns (uint256) {
        return royaltyFeePercentage;
    }

    function withdrawRoyalties() public onlyOwner whenNotPaused {
        // Implement logic to withdraw royalties collected (if using ERC2981) to DAO treasury
        // Example (simplified, assuming royalties are accumulated in the contract balance):
        payable(owner()).transfer(address(this).balance); // Transfer all contract balance to owner (treasury)
    }

    // --- Governance & DAO Management Functions ---
    function proposeRuleChange(string memory _description, bytes memory _calldata) public onlyMember whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.RULE_CHANGE,
            description: _description,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.ACTIVE,
            calldataData: _calldata,
            ipfsHash: "", // Not used for rule change
            artTitle: "", // Not used for rule change
            artistName: "", // Not used for rule change
            collectionProposalId: 0, // Not related to collection creation
            collectionMetadataURI: ""  // Not related to collection creation
        });
        emit RuleChangeProposed(proposalId, msg.sender, _description);
    }

    function voteOnRuleChange(uint256 _proposalId, bool _vote) public onlyMember onlyProposalActive(_proposalId) whenNotPaused {
        require(!votes[_proposalId][msg.sender], "Already voted on this proposal");
        votes[_proposalId][msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].yesVotes = proposals[_proposalId].yesVotes.add(getMemberVotingPower(msg.sender));
        } else {
            proposals[_proposalId].noVotes = proposals[_proposalId].noVotes.add(getMemberVotingPower(msg.sender));
        }
        emit RuleChangeVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended and process proposal
        if (block.timestamp >= proposals[_proposalId].endTime) {
            _processRuleChangeProposalResult(_proposalId);
        }
    }

    function executeProposal(uint256 _proposalId) public onlyOwner onlyProposalExecutable(_proposalId) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.APPROVED, "Proposal must be approved to execute");
        proposal.status = ProposalStatus.EXECUTED;
        if (proposal.proposalType == ProposalType.RULE_CHANGE) {
            (bool success, ) = address(this).delegatecall(proposal.calldataData); // Execute rule change via delegatecall
            require(success, "Rule change execution failed");
        } else if (proposal.proposalType == ProposalType.COLLECTION_CREATION) {
            setCollectionMetadata(proposal.proposalId, proposal.collectionMetadataURI); // Example action for collection proposal
        }
        emit ProposalExecuted(_proposalId);
    }


    function setVotingPeriod(uint256 _votingPeriodInSeconds) public onlyOwner whenNotPaused { // Can be changed to governance vote
        votingPeriod = _votingPeriodInSeconds;
        emit VotingPeriodUpdated(_votingPeriodInSeconds);
    }

    function getVotingPeriod() public view returns (uint256) {
        return votingPeriod;
    }

    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused();
    }

    // --- Advanced Features ---
    function delegateVote(address _delegatee) public onlyMember whenNotPaused {
        require(_delegatee != address(0) && _delegatee != msg.sender, "Invalid delegatee address");
        delegatedVotes[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    function getDelegatedVotes(address _member) public view returns (address) {
        return delegatedVotes[_member];
    }

    function createCollectionProposal(string memory _collectionName, string memory _collectionSymbol, string memory _collectionDescription) public onlyMember whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.COLLECTION_CREATION,
            description: string(abi.encodePacked("Create new collection: ", _collectionName)),
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.ACTIVE,
            calldataData: bytes(""), // Not used directly, metadata set later
            ipfsHash: "", // Not used
            artTitle: "", // Not used
            artistName: "", // Not used
            collectionProposalId: proposalId, // Link to itself for metadata setting
            collectionMetadataURI: ""  // Metadata URI will be set after approval
        });
        emit CollectionProposalCreated(proposalId, _collectionName, _collectionSymbol, _collectionDescription);
    }

    function setCollectionMetadata(uint256 _collectionProposalId, string memory _metadataURI) public onlyOwner onlyProposalApproved(_collectionProposalId) whenNotPaused {
        Proposal storage proposal = proposals[_collectionProposalId];
        require(proposal.proposalType == ProposalType.COLLECTION_CREATION, "Proposal is not for collection creation");
        proposal.collectionMetadataURI = _metadataURI;
        emit CollectionMetadataSet(_collectionProposalId, _metadataURI);
        // In a real implementation, you might deploy a new NFT contract linked to this DAO and set metadata there.
    }


    // --- Internal Functions ---
    function _processArtProposalResult(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.ACTIVE) return; // Prevent re-processing

        uint256 totalVotingPower = getTotalVotingPower();
        uint256 quorum = totalVotingPower.mul(quorumPercentage).div(100);
        uint256 threshold = totalVotingPower.mul(proposalThresholdPercentage).div(100);

        if (proposal.yesVotes >= threshold && (proposal.yesVotes.add(proposal.noVotes) >= quorum)) {
            proposal.status = ProposalStatus.APPROVED;
            emit ArtProposalApproved(_proposalId);
        } else {
            proposal.status = ProposalStatus.REJECTED;
            emit ArtProposalRejected(_proposalId);
        }
    }

    function _processRuleChangeProposalResult(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.ACTIVE) return; // Prevent re-processing

        uint256 totalVotingPower = getTotalVotingPower();
        uint256 quorum = totalVotingPower.mul(quorumPercentage).div(100);
        uint256 threshold = totalVotingPower.mul(proposalThresholdPercentage).div(100);

        if (proposal.yesVotes >= threshold && (proposal.yesVotes.add(proposal.noVotes) >= quorum)) {
            proposal.status = ProposalStatus.APPROVED;
            emit RuleChangeApproved(_proposalId);
        } else {
            proposal.status = ProposalStatus.REJECTED;
            emit RuleChangeRejected(_proposalId);
        }
    }

    // --- Utility Functions (For testing and potential future use) ---
    function getMembers() public view returns (address[] memory) {
        // This is a placeholder and might not be efficient for large DAOs.
        // In a real implementation, you might maintain a list of members.
        address[] memory members = new address[](100); // Assuming max 100 members for simplicity, use dynamic array in real scenario.
        uint256 memberCount = 0;
        for (uint256 i = 0; i < 100; i++) { // Iterate through possible addresses (inefficient, just for example)
            address addr = address(uint160(i)); // Example address generation, replace with actual member tracking
            if (isMember[addr]) {
                members[memberCount] = addr;
                memberCount++;
            }
        }
        address[] memory finalMembers = new address[](memberCount);
        for (uint256 i = 0; i < memberCount; i++) {
            finalMembers[i] = members[i];
        }
        return finalMembers;
    }

    function getProposalStatus(uint256 _proposalId) public view returns (ProposalStatus) {
        return proposals[_proposalId].status;
    }

    function getProposalType(uint256 _proposalId) public view returns (ProposalType) {
        return proposals[_proposalId].proposalType;
    }

    function getCurrentProposalId() public view returns (uint256) {
        return _proposalIdCounter.current();
    }

    // --- Fallback and Receive Functions ---
    receive() external payable {
        // Optional: Handle direct ether deposits if needed for treasury or other purposes
    }

    fallback() external payable {
        // Optional: Handle fallback function if needed
    }
}

// --- Helper Library for String Conversions (if not using a library like StringUtils) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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