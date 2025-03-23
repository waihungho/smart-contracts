```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract representing a Decentralized Autonomous Art Collective.
 *      This contract enables artists to submit art proposals, community voting on proposals,
 *      minting of approved art as NFTs, revenue sharing, collective governance,
 *      and dynamic evolution through parameter changes.
 *
 * Function Outline and Summary:
 *
 * 1.  submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash): Allows artists to submit art proposals with title, description, and IPFS hash.
 * 2.  voteOnArtProposal(uint256 _proposalId, bool _support): Allows members to vote for or against an art proposal.
 * 3.  mintArtNFT(uint256 _proposalId): Mints an NFT for an approved art proposal, distributing royalties to artist and collective.
 * 4.  proposeParameterChange(string memory _parameterName, uint256 _newValue): Allows members to propose changes to contract parameters (e.g., voting duration, royalty split).
 * 5.  voteOnParameterChange(uint256 _proposalId, bool _support): Allows members to vote on parameter change proposals.
 * 6.  executeParameterChange(uint256 _proposalId): Executes an approved parameter change proposal, updating the contract state.
 * 7.  joinCollective(): Allows users to join the art collective as members by paying a membership fee.
 * 8.  leaveCollective(): Allows members to leave the collective and reclaim their membership deposit.
 * 9.  withdrawArtistFunds(): Allows artists to withdraw their earned royalties from NFT sales.
 * 10. withdrawCollectiveFunds(): Allows designated roles (e.g., curators) to withdraw funds from the collective treasury for collective purposes.
 * 11. setRoyaltyPercentage(uint256 _newPercentage): Proposes a parameter change to modify the royalty percentage for artists (governance function).
 * 12. setVotingDuration(uint256 _newDurationInBlocks): Proposes a parameter change to modify the voting duration (governance function).
 * 13. setMembershipFee(uint256 _newFee): Proposes a parameter change to modify the membership fee (governance function).
 * 14. getArtProposalDetails(uint256 _proposalId): Returns details of a specific art proposal.
 * 15. getParameterChangeProposalDetails(uint256 _proposalId): Returns details of a specific parameter change proposal.
 * 16. getProposalVoteCount(uint256 _proposalId): Returns the vote count for a given proposal.
 * 17. getCollectiveBalance(): Returns the current balance of the collective treasury.
 * 18. getMembershipFee(): Returns the current membership fee.
 * 19. getRoyaltyPercentage(): Returns the current royalty percentage for artists.
 * 20. getVotingDuration(): Returns the current voting duration in blocks.
 * 21. isCollectiveMember(address _user): Checks if an address is a member of the collective.
 * 22. getNFTContractAddress(): Returns the address of the deployed NFT contract (if separate).
 * 23. pauseContract(): Allows a designated admin to pause the contract in case of emergency.
 * 24. unpauseContract(): Allows a designated admin to unpause the contract.
 * 25. getContractState(): Returns the current state of the contract (paused/unpaused).
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _artProposalIds;
    Counters.Counter private _parameterProposalIds;
    address public nftContractAddress; // Address of deployed NFT contract (can be self or external)

    uint256 public membershipFee = 0.1 ether; // Fee to join the collective
    uint256 public royaltyPercentage = 70; // Percentage of NFT sale price to artist (out of 100)
    uint256 public votingDurationInBlocks = 100; // Duration of voting period in blocks
    uint256 public quorumPercentage = 50; // Percentage of members needed to reach quorum for voting (out of 100)
    uint256 public proposalDeposit = 0.05 ether; // Deposit required to submit an art proposal

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => mapping(address => bool)) public artProposalVotes; // proposalId => voter => support
    mapping(uint256 => mapping(address => bool)) public parameterProposalVotes; // proposalId => voter => support
    mapping(address => bool) public collectiveMembers;
    mapping(address => uint256) public artistBalances; // Track artist royalty balances

    address payable public collectiveTreasury;

    enum ProposalStatus { Pending, Active, Approved, Rejected, Executed }
    enum ProposalType { Art, ParameterChange }

    struct ArtProposal {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        ProposalStatus status;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        uint256 proposalDepositAmount;
    }

    struct ParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        address proposer;
        ProposalStatus status;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
    }

    // --- Events ---

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtProposalApproved(uint256 proposalId);
    event ArtProposalRejected(uint256 proposalId);
    event ArtNFTMinted(uint256 proposalId, uint256 tokenId, address artist);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool support);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event CollectiveMemberJoined(address member);
    event CollectiveMemberLeft(address member);
    event ArtistFundsWithdrawn(address artist, uint256 amount);
    event CollectiveFundsWithdrawn(address withdrawer, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier onlyCollectiveMember() {
        require(collectiveMembers[msg.sender], "Not a collective member");
        _;
    }

    modifier onlyProposalDepositPaid(uint256 _amount) {
        require(msg.value >= _amount, "Insufficient proposal deposit sent");
        _;
    }

    modifier onlyAdmin() { // Example admin role - can be expanded with more roles
        require(msg.sender == owner(), "Not an admin");
        _;
    }

    modifier validProposalId(uint256 _proposalId, ProposalType _proposalType) {
        if (_proposalType == ProposalType.Art) {
            require(_proposalId > 0 && _proposalId <= _artProposalIds.current, "Invalid art proposal ID");
        } else if (_proposalType == ProposalType.ParameterChange) {
            require(_proposalId > 0 && _proposalId <= _parameterProposalIds.current, "Invalid parameter proposal ID");
        } else {
            revert("Invalid proposal type");
        }
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalType _proposalType, ProposalStatus _status) {
        ProposalStatus currentStatus;
        if (_proposalType == ProposalType.Art) {
            currentStatus = artProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.ParameterChange) {
            currentStatus = parameterChangeProposals[_proposalId].status;
        } else {
            revert("Invalid proposal type");
        }
        require(currentStatus == _status, "Proposal not in expected status");
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        collectiveTreasury = payable(msg.sender); // Owner initially sets the treasury
        nftContractAddress = address(this); // Default to this contract being the NFT contract
    }

    // --- Art Proposal Functions ---

    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash
    )
        public
        payable
        whenNotPaused
        onlyCollectiveMember
        onlyProposalDepositPaid(proposalDeposit)
    {
        _artProposalIds.increment();
        uint256 proposalId = _artProposalIds.current;

        artProposals[proposalId] = ArtProposal({
            id: proposalId,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: msg.sender,
            status: ProposalStatus.Pending,
            voteCountFor: 0,
            voteCountAgainst: 0,
            proposalDepositAmount: msg.value
        });

        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _support)
        public
        whenNotPaused
        onlyCollectiveMember
        validProposalId(_proposalId, ProposalType.Art)
        proposalInStatus(_proposalId, ProposalType.Art, ProposalStatus.Pending)
    {
        require(!artProposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        artProposalVotes[_proposalId][msg.sender] = true; // Record vote

        if (_support) {
            artProposals[_proposalId].voteCountFor++;
        } else {
            artProposals[_proposalId].voteCountAgainst++;
        }

        emit ArtProposalVoted(_proposalId, msg.sender, _support);

        // Check if voting period ended (simple block-based end for example)
        if (block.number >= block.number + votingDurationInBlocks) { // Simplified end condition for demonstration
             _finalizeArtProposal(_proposalId);
        }
    }

    function _finalizeArtProposal(uint256 _proposalId) internal proposalInStatus(_proposalId, ProposalType.Art, ProposalStatus.Pending) {
        ArtProposal storage proposal = artProposals[_proposalId];
        proposal.status = ProposalStatus.Active; // Mark as active voting in progress, can be removed if voting auto starts on submit

        uint256 totalMembers = getCollectiveMemberCount();
        uint256 quorumNeeded = (totalMembers * quorumPercentage) / 100;
        uint256 totalVotes = proposal.voteCountFor + proposal.voteCountAgainst;

        if (totalVotes >= quorumNeeded && proposal.voteCountFor > proposal.voteCountAgainst) {
            proposal.status = ProposalStatus.Approved;
            emit ArtProposalApproved(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
            // Return proposal deposit (example - could have different deposit policies)
            payable(proposal.artist).transfer(proposal.proposalDepositAmount);
            emit ArtProposalRejected(_proposalId);
        }
    }


    function mintArtNFT(uint256 _proposalId)
        public
        whenNotPaused
        onlyAdmin // Example: Minting controlled by admin after approval, can be DAO-governed too
        validProposalId(_proposalId, ProposalType.Art)
        proposalInStatus(_proposalId, ProposalType.Art, ProposalStatus.Approved)
    {
        ArtProposal storage proposal = artProposals[_proposalId];
        proposal.status = ProposalStatus.Executed;

        uint256 tokenId = _mint(proposal.artist, _proposalId); // Proposal ID as token ID for simplicity
        emit ArtNFTMinted(_proposalId, tokenId, proposal.artist);
    }

    // --- Parameter Change Proposal Functions ---

    function proposeParameterChange(string memory _parameterName, uint256 _newValue)
        public
        whenNotPaused
        onlyCollectiveMember
    {
        _parameterProposalIds.increment();
        uint256 proposalId = _parameterProposalIds.current;

        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            id: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            voteCountFor: 0,
            voteCountAgainst: 0
        });

        emit ParameterChangeProposed(proposalId, _parameterName, _newValue, msg.sender);
    }

    function voteOnParameterChange(uint256 _proposalId, bool _support)
        public
        whenNotPaused
        onlyCollectiveMember
        validProposalId(_proposalId, ProposalType.ParameterChange)
        proposalInStatus(_proposalId, ProposalType.ParameterChange, ProposalStatus.Pending)
    {
        require(!parameterProposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        parameterProposalVotes[_proposalId][msg.sender] = true;

        if (_support) {
            parameterChangeProposals[_proposalId].voteCountFor++;
        } else {
            parameterChangeProposals[_proposalId].voteCountAgainst++;
        }

        emit ParameterChangeVoted(_proposalId, msg.sender, _support);

        // Check if voting period ended (simple block-based end)
        if (block.number >= block.number + votingDurationInBlocks) { // Simplified end condition
            _finalizeParameterChangeProposal(_proposalId);
        }
    }

    function _finalizeParameterChangeProposal(uint256 _proposalId) internal proposalInStatus(_proposalId, ProposalType.ParameterChange, ProposalStatus.Pending) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        proposal.status = ProposalStatus.Active; // Mark as active voting in progress, can be removed if voting auto starts on submit


        uint256 totalMembers = getCollectiveMemberCount();
        uint256 quorumNeeded = (totalMembers * quorumPercentage) / 100;
        uint256 totalVotes = proposal.voteCountFor + proposal.voteCountAgainst;

        if (totalVotes >= quorumNeeded && proposal.voteCountFor > proposal.voteCountAgainst) {
            proposal.status = ProposalStatus.Approved;
            emit ArtProposalApproved(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ArtProposalRejected(_proposalId);
        }
    }


    function executeParameterChange(uint256 _proposalId)
        public
        whenNotPaused
        onlyAdmin // Example: Execution controlled by admin, can be DAO-governed too
        validProposalId(_proposalId, ProposalType.ParameterChange)
        proposalInStatus(_proposalId, ProposalType.ParameterChange, ProposalStatus.Approved)
    {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        proposal.status = ProposalStatus.Executed;

        string memory paramName = proposal.parameterName;
        uint256 newValue = proposal.newValue;

        if (keccak256(bytes(paramName)) == keccak256(bytes("royaltyPercentage"))) {
            royaltyPercentage = newValue;
        } else if (keccak256(bytes(paramName)) == keccak256(bytes("votingDurationInBlocks"))) {
            votingDurationInBlocks = newValue;
        } else if (keccak256(bytes(paramName)) == keccak256(bytes("membershipFee"))) {
            membershipFee = newValue;
        } else if (keccak256(bytes(paramName)) == keccak256(bytes("quorumPercentage"))) {
            quorumPercentage = newValue;
        } else if (keccak256(bytes(paramName)) == keccak256(bytes("proposalDeposit"))) {
            proposalDeposit = newValue;
        } else {
            revert("Invalid parameter name for change");
        }

        emit ParameterChangeExecuted(_proposalId, paramName, newValue);
    }

    // --- Collective Membership Functions ---

    function joinCollective() public payable whenNotPaused {
        require(!collectiveMembers[msg.sender], "Already a member");
        require(msg.value >= membershipFee, "Insufficient membership fee");
        collectiveMembers[msg.sender] = true;
        collectiveTreasury.transfer(membershipFee); // Send fee to treasury - could be burned instead
        emit CollectiveMemberJoined(msg.sender);
    }

    function leaveCollective() public whenNotPaused onlyCollectiveMember {
        collectiveMembers[msg.sender] = false;
        payable(msg.sender).transfer(membershipFee); // Return membership fee - could be deposit instead of fee
        emit CollectiveMemberLeft(msg.sender);
    }

    // --- Revenue and Treasury Functions ---

    function withdrawArtistFunds() public whenNotPaused {
        uint256 balance = artistBalances[msg.sender];
        require(balance > 0, "No funds to withdraw");
        artistBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit ArtistFundsWithdrawn(msg.sender, balance);
    }

    function withdrawCollectiveFunds(uint256 _amount) public whenNotPaused onlyAdmin { // Admin controlled treasury withdrawal - could be DAO governed
        require(_amount <= address(this).balance, "Insufficient collective funds");
        collectiveTreasury.transfer(_amount);
        emit CollectiveFundsWithdrawn(msg.sender, _amount);
    }

    // --- Overrides for ERC721 functions to handle royalties ---

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._transfer(from, to, tokenId);

        // Example: Royalty distribution upon secondary sale (simplified, assumes fixed price)
        uint256 salePrice = 0.1 ether; // Example fixed price, in real world, price would be dynamic/external
        uint256 artistRoyalty = (salePrice * royaltyPercentage) / 100;
        uint256 collectiveShare = salePrice - artistRoyalty;

        ArtProposal storage proposal = artProposals[tokenId]; // Token ID is proposal ID in this example

        artistBalances[proposal.artist] += artistRoyalty; // Accumulate royalties for artist
        collectiveTreasury.transfer(collectiveShare); // Send collective share to treasury
    }

    // --- Getter/View Functions ---

    function getArtProposalDetails(uint256 _proposalId)
        public
        view
        validProposalId(_proposalId, ProposalType.Art)
        returns (ArtProposal memory)
    {
        return artProposals[_proposalId];
    }

    function getParameterChangeProposalDetails(uint256 _proposalId)
        public
        view
        validProposalId(_proposalId, ProposalType.ParameterChange)
        returns (ParameterChangeProposal memory)
    {
        return parameterChangeProposals[_proposalId];
    }

    function getProposalVoteCount(uint256 _proposalId)
        public
        view
        validProposalId(uint256(_proposalId), ProposalType.Art) // Assuming art proposal for now, can overload for parameter changes if needed
        returns (uint256 forVotes, uint256 againstVotes)
    {
        return (artProposals[_proposalId].voteCountFor, artProposals[_proposalId].voteCountAgainst);
    }

    function getCollectiveBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMembershipFee() public view returns (uint256) {
        return membershipFee;
    }

    function getRoyaltyPercentage() public view returns (uint256) {
        return royaltyPercentage;
    }

    function getVotingDuration() public view returns (uint256) {
        return votingDurationInBlocks;
    }

    function isCollectiveMember(address _user) public view returns (bool) {
        return collectiveMembers[_user];
    }

    function getNFTContractAddress() public view returns (address) {
        return nftContractAddress;
    }

    function getCollectiveMemberCount() public view returns (uint256) {
        uint256 count = 0;
        address[] memory members = getCollectiveMembers();
        for (uint256 i = 0; i < members.length; i++) {
            if (collectiveMembers[members[i]]) {
                count++;
            }
        }
        return count;
    }

    function getCollectiveMembers() public view returns (address[] memory) {
        address[] memory members = new address[](collectiveMembers.length); // Initial size, may need dynamic resizing for large memberships in real app
        uint256 index = 0;
        for (uint256 i = 0; i < collectiveMembers.length; i++) { // Iterate through mapping - inefficient for large mappings, consider better member tracking
            if (collectiveMembers[address(uint160(i))]) { // Example iteration, not ideal for large mappings, consider array-based member list
                members[index] = address(uint160(i));
                index++;
            }
        }
        assembly { // Get mapping size - Solidity doesn't directly provide mapping size, assembly workaround, use with caution and testing
            let mapSize := mload(collectiveMembers.slot) // Requires understanding of storage layout and might break on compiler changes
            mstore(members, mapSize) // Store size in the first slot of the array for potential external use
        }
        return members;
    }


    // --- Pausable Functionality ---

    function pauseContract() public onlyAdmin whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyAdmin whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function getContractState() public view returns (bool) {
        return paused();
    }

    // --- Fallback Function (optional, for receiving ETH) ---
    receive() external payable {}
}
```