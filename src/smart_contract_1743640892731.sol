```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 * This contract facilitates community-driven art creation, curation, and funding.
 * It incorporates advanced concepts like dynamic NFT metadata, fractional ownership,
 * reputation-based governance, and decentralized collaboration tools.
 *
 * **Outline & Function Summary:**
 *
 * **1. Membership & Reputation:**
 *   - `joinCollective()`: Allows users to request membership in the collective.
 *   - `approveMembership(address _member)`: Admin function to approve pending membership requests.
 *   - `rejectMembership(address _member)`: Admin function to reject pending membership requests.
 *   - `isMember(address _user)`: Checks if an address is a member of the collective.
 *   - `getMemberReputation(address _member)`: Returns the reputation score of a member.
 *   - `increaseReputation(address _member, uint256 _amount)`: Admin function to manually increase member reputation.
 *   - `decreaseReputation(address _member, uint256 _amount)`: Admin function to manually decrease member reputation.
 *
 * **2. Art Proposal & Creation:**
 *   - `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Members can submit art proposals with title, description, and IPFS hash of the artwork idea.
 *   - `voteOnProposal(uint256 _proposalId, bool _vote)`: Members can vote on art proposals. Voting power is weighted by reputation.
 *   - `executeArtProposal(uint256 _proposalId)`: Admin/Reputation-based function to execute approved art proposals (after voting threshold is met).
 *   - `getProposalDetails(uint256 _proposalId)`: Returns details of a specific art proposal.
 *   - `getProposalStatus(uint256 _proposalId)`: Returns the current status of a proposal (Pending, Approved, Rejected, Executed).
 *   - `cancelArtProposal(uint256 _proposalId)`: Artist can cancel their own proposal if it's still pending.
 *
 * **3. Dynamic NFT & Fractionalization:**
 *   - `mintArtNFT(uint256 _proposalId)`: Mints an NFT representing the approved and executed art proposal. Only executable after proposal execution.
 *   - `updateNFTMetadata(uint256 _tokenId, string memory _newIpfsHash)`: Allows the artist (or DAO vote) to update the NFT metadata (dynamic NFTs).
 *   - `fractionalizeNFT(uint256 _tokenId, uint256 _numberOfFractions)`: Allows fractionalizing an art NFT into fungible tokens (ERC-20).
 *   - `redeemFractionalNFT(uint256 _tokenId)`: Allows holders of all fractions to redeem them for the original NFT (governance decision required for implementation details).
 *
 * **4. Collective Treasury & Funding:**
 *   - `depositToTreasury()`: Allows anyone to deposit ETH into the collective treasury.
 *   - `requestFunding(uint256 _proposalId, uint256 _amount)`: Artists can request funding for their approved art proposals during proposal submission.
 *   - `allocateFunding(uint256 _proposalId)`: Admin/Reputation-based function to allocate funds from the treasury to an approved and executed art proposal.
 *   - `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 *
 * **5. Governance & Settings:**
 *   - `setVotingDuration(uint256 _durationInBlocks)`: Admin function to set the voting duration for proposals.
 *   - `setVotingThreshold(uint256 _thresholdPercentage)`: Admin function to set the voting threshold percentage for proposal approval.
 *   - `setReputationThresholdForExecution(uint256 _reputationThreshold)`: Admin function to set the reputation threshold required to execute proposals directly (bypassing admin in the future).
 *   - `transferAdminRole(address _newAdmin)`: Admin function to transfer administrative privileges.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Structs & Enums ---
    enum ProposalStatus { Pending, Approved, Rejected, Executed, Cancelled }

    struct ArtProposal {
        string title;
        string description;
        string ipfsHash;
        address proposer;
        uint256 fundingRequested;
        ProposalStatus status;
        uint256 voteCount;
        uint256 endTime;
        mapping(address => bool) votes; // Address voted or not
    }

    struct FractionalNFT {
        ERC20 tokenContract;
        uint256 totalFractions;
        bool fractionalized;
    }

    // --- State Variables ---
    mapping(address => bool) public members;
    mapping(address => uint256) public memberReputation;
    mapping(address => bool) public pendingMembershipRequests;
    ArtProposal[] public artProposals;
    mapping(uint256 => FractionalNFT) public fractionalizedNFTs;
    Counters.Counter private _proposalCounter;
    Counters.Counter private _nftCounter;

    uint256 public votingDurationInBlocks = 100; // Default voting duration (blocks)
    uint256 public votingThresholdPercentage = 60; // Default voting threshold (%)
    uint256 public reputationThresholdForExecution = 1000; // Reputation needed to execute proposals directly
    uint256 public initialReputation = 100; // Initial reputation for new members
    uint256 public membershipFee = 0.1 ether; // Fee to request membership (can be 0)
    uint256 public reputationRewardForProposalExecution = 50; // Reputation reward for artist when proposal executed

    // --- Events ---
    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRejected(address member);
    event ReputationIncreased(address member, uint256 amount);
    event ReputationDecreased(address member, uint256 amount);
    event ArtProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalExecuted(uint256 proposalId);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address minter);
    event NFTMetadataUpdated(uint256 tokenId, string newIpfsHash);
    event NFTFractionalized(uint256 tokenId, address fractionalTokenContract, uint256 totalFractions);
    event TreasuryDeposit(address depositor, uint256 amount);
    event FundingAllocated(uint256 proposalId, uint256 amount);
    event ProposalCancelled(uint256 proposalId);

    // --- Modifiers ---
    modifier onlyMember() {
        require(isMember(msg.sender), "Not a member of the collective.");
        _;
    }

    modifier onlyAdminOrReputation(uint256 _proposalId) {
        require(msg.sender == owner || memberReputation[msg.sender] >= reputationThresholdForExecution, "Not authorized to execute proposal.");
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId) {
        require(artProposals[_proposalId].proposer == msg.sender, "Only proposer can perform this action.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < artProposals.length, "Invalid proposal ID.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(artProposals[_proposalId].status == _status, "Proposal is not in the required status.");
        _;
    }

    constructor() ERC721("DAAC Art NFT", "DAAC-NFT") Ownable() {
        // Initialize contract - Optionally set initial admin, thresholds, etc.
    }

    // --- 1. Membership & Reputation ---

    function joinCollective() external payable {
        require(!members[msg.sender], "Already a member.");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending.");
        if (membershipFee > 0) {
            require(msg.value >= membershipFee, "Insufficient membership fee.");
        }
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyOwner {
        require(pendingMembershipRequests[_member], "No pending membership request.");
        members[_member] = true;
        memberReputation[_member] = initialReputation;
        pendingMembershipRequests[_member] = false;
        emit MembershipApproved(_member);
    }

    function rejectMembership(address _member) external onlyOwner {
        require(pendingMembershipRequests[_member], "No pending membership request.");
        pendingMembershipRequests[_member] = false;
        emit MembershipRejected(_member);
    }

    function isMember(address _user) public view returns (bool) {
        return members[_user];
    }

    function getMemberReputation(address _member) public view returns (uint256) {
        return memberReputation[_member];
    }

    function increaseReputation(address _member, uint256 _amount) external onlyOwner {
        memberReputation[_member] += _amount;
        emit ReputationIncreased(_member, _amount);
    }

    function decreaseReputation(address _member, uint256 _amount) external onlyOwner {
        require(memberReputation[_member] >= _amount, "Reputation cannot be negative.");
        memberReputation[_member] -= _amount;
        emit ReputationDecreased(_member, _amount);
    }

    // --- 2. Art Proposal & Creation ---

    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _fundingRequested
    ) external onlyMember {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Proposal details cannot be empty.");
        _proposalCounter.increment();
        artProposals.push(ArtProposal({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            fundingRequested: _fundingRequested,
            status: ProposalStatus.Pending,
            voteCount: 0,
            endTime: block.number + votingDurationInBlocks,
            votes: mapping(address => bool)()
        }));
        emit ArtProposalSubmitted(_proposalCounter.current(), msg.sender, _title);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        require(!artProposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");
        require(block.number <= artProposals[_proposalId].endTime, "Voting period has ended.");

        artProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            artProposals[_proposalId].voteCount += getVotingPower(msg.sender); // Voting power based on reputation
        } else {
            artProposals[_proposalId].voteCount -= getVotingPower(msg.sender); // Negative votes can be implemented or just ignore 'false' votes for simplicity
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeArtProposal(uint256 _proposalId) external onlyAdminOrReputation(_proposalId) validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        require(block.number > artProposals[_proposalId].endTime, "Voting period is still ongoing.");
        uint256 totalMembers = 0;
        uint256 activeMembersVotingPower = 0; // Consider only members with reputation > 0 for voting denominator
        for (uint256 i = 0; i < artProposals.length; i++) { // Inefficient, consider better member tracking for large collectives
            if (members[artProposals[i].proposer] && memberReputation[artProposals[i].proposer] > 0) { // Example: Count only members with positive reputation
                totalMembers++;
                activeMembersVotingPower += memberReputation[artProposals[i].proposer]; // Sum voting power of active members
            }
        }
        if (activeMembersVotingPower == 0) activeMembersVotingPower = 1; // Prevent division by zero if no active members
        uint256 requiredVotes = (activeMembersVotingPower * votingThresholdPercentage) / 100;

        if (artProposals[_proposalId].voteCount >= requiredVotes) {
            artProposals[_proposalId].status = ProposalStatus.Approved;
            emit ArtProposalExecuted(_proposalId);
        } else {
            artProposals[_proposalId].status = ProposalStatus.Rejected;
        }
    }

    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getProposalStatus(uint256 _proposalId) external view validProposalId(_proposalId) returns (ProposalStatus) {
        return artProposals[_proposalId].status;
    }

    function cancelArtProposal(uint256 _proposalId) external onlyProposalProposer(_proposalId) validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        artProposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    // --- 3. Dynamic NFT & Fractionalization ---

    function mintArtNFT(uint256 _proposalId) external onlyAdminOrReputation(_proposalId) validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Approved) {
        artProposals[_proposalId].status = ProposalStatus.Executed; // Mark proposal as executed after NFT minting.
        _nftCounter.increment();
        uint256 tokenId = _nftCounter.current();
        _safeMint(artProposals[_proposalId].proposer, tokenId);
        _setTokenURI(tokenId, artProposals[_proposalId].ipfsHash); // Initial IPFS hash from proposal
        emit ArtNFTMinted(tokenId, _proposalId, artProposals[_proposalId].proposer);
        increaseReputation(artProposals[_proposalId].proposer, reputationRewardForProposalExecution); // Reward artist
        allocateFunding(_proposalId); // Allocate funding if requested and approved
    }

    function updateNFTMetadata(uint256 _tokenId, string memory _newIpfsHash) external {
        require(_exists(_tokenId), "NFT does not exist.");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved."); // Allow owner to update, DAO governance could be added here
        _setTokenURI(_tokenId, _newIpfsHash);
        emit NFTMetadataUpdated(_tokenId, _newIpfsHash);
    }

    function fractionalizeNFT(uint256 _tokenId, uint256 _numberOfFractions) external {
        require(_exists(_tokenId), "NFT does not exist.");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved.");
        require(!fractionalizedNFTs[_tokenId].fractionalized, "NFT already fractionalized.");
        require(_numberOfFractions > 0, "Number of fractions must be greater than zero.");

        // Create new ERC20 token contract for fractionalization
        ERC20 fractionalToken = new ERC20(string(abi.encodePacked(name(), " Fractions - Token ID ", _tokenId.toString())), string(abi.encodePacked(symbol(), "-FRAC-", _tokenId.toString())));

        // Mint fractions and distribute to NFT owner (or DAO based on governance)
        fractionalToken.mint(ownerOf(_tokenId), _numberOfFractions); // Initially give all fractions to NFT owner. Governance can decide distribution.

        fractionalizedNFTs[_tokenId] = FractionalNFT({
            tokenContract: fractionalToken,
            totalFractions: _numberOfFractions,
            fractionalized: true
        });

        // Optionally transfer NFT to a vault contract (not implemented here for simplicity) to secure it during fractionalization.

        emit NFTFractionalized(_tokenId, address(fractionalToken), _numberOfFractions);
    }

    // function redeemFractionalNFT(uint256 _tokenId) external {
    //     // Complex logic - Requires governance mechanism to decide redemption process
    //     // - Verify if all fractions are gathered
    //     // - Burn fractional tokens
    //     // - Transfer original NFT back to redeemer (or DAO decision on who gets it).
    //     // Not fully implemented in this example due to complexity of governance and redemption scenarios.
    // }


    // --- 4. Collective Treasury & Funding ---

    function depositToTreasury() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function requestFunding(uint256 _proposalId, uint256 _amount) external onlyMember validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        require(_amount > 0, "Funding request amount must be greater than zero.");
        artProposals[_proposalId].fundingRequested = _amount;
    }

    function allocateFunding(uint256 _proposalId) internal validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Executed) { // Internal, only called after NFT minting & execution
        uint256 fundingAmount = artProposals[_proposalId].fundingRequested;
        if (fundingAmount > 0) {
            require(address(this).balance >= fundingAmount, "Insufficient treasury balance for funding.");
            payable(artProposals[_proposalId].proposer).transfer(fundingAmount);
            emit FundingAllocated(_proposalId, fundingAmount);
        }
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- 5. Governance & Settings ---

    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner {
        votingDurationInBlocks = _durationInBlocks;
    }

    function setVotingThreshold(uint256 _thresholdPercentage) external onlyOwner {
        require(_thresholdPercentage <= 100, "Voting threshold percentage must be <= 100.");
        votingThresholdPercentage = _thresholdPercentage;
    }

    function setReputationThresholdForExecution(uint256 _reputationThreshold) external onlyOwner {
        reputationThresholdForExecution = _reputationThreshold;
    }

    function transferAdminRole(address _newAdmin) external onlyOwner {
        transferOwnership(_newAdmin);
    }

    // --- Utility Functions ---

    function getVotingPower(address _voter) public view returns (uint256) {
        // Example: Voting power based on reputation. Can be customized further.
        return memberReputation[_voter];
    }

    receive() external payable {} // Allow contract to receive ETH

    fallback() external payable {} // Allow contract to receive ETH
}
```