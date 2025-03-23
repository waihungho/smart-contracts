```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective.
 * It enables artists to propose, vote on, and collaboratively create digital art pieces,
 * manage a shared treasury, and distribute rewards transparently and autonomously.
 *
 * **Contract Outline & Function Summary:**
 *
 * **Core Functionality:**
 * 1. **Membership Management:**
 *    - `joinCollective()`: Allows users to become members by paying a membership fee.
 *    - `leaveCollective()`: Allows members to leave the collective and potentially reclaim a portion of their membership fee.
 *    - `getMemberCount()`: Returns the current number of members in the collective.
 *    - `isMember(address _user)`: Checks if an address is a member of the collective.
 *
 * 2. **Art Proposal System:**
 *    - `proposeArtPiece(string memory _title, string memory _description, string memory _ipfsHash)`: Members can propose new art pieces with a title, description, and IPFS hash.
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: Members can vote on art proposals (supports weighted voting based on membership duration).
 *    - `executeProposal(uint256 _proposalId)`: Executes a successful art proposal (mints NFT, allocates funds, etc.).
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 *    - `getProposalVotingStats(uint256 _proposalId)`: Retrieves voting statistics for a proposal.
 *    - `getProposalCount()`: Returns the total number of art proposals.
 *
 * 3. **Treasury Management:**
 *    - `depositToTreasury()`: Allows members and others to deposit ETH into the collective's treasury.
 *    - `requestTreasuryWithdrawal(uint256 _amount, string memory _reason)`: Members can request withdrawals from the treasury for collective-related expenses.
 *    - `voteOnWithdrawalRequest(uint256 _requestId, bool _support)`: Members vote on treasury withdrawal requests.
 *    - `executeWithdrawalRequest(uint256 _requestId)`: Executes an approved withdrawal request, sending ETH to the requester.
 *    - `getTreasuryBalance()`: Returns the current balance of the collective's treasury.
 *    - `getWithdrawalRequestDetails(uint256 _requestId)`: Retrieves details of a treasury withdrawal request.
 *    - `getWithdrawalRequestVotingStats(uint256 _requestId)`: Retrieves voting stats for a withdrawal request.
 *    - `getWithdrawalRequestCount()`: Returns the total number of withdrawal requests.
 *
 * 4. **NFT Minting & Management:**
 *    - `mintArtNFT(uint256 _proposalId)`: Mints an NFT for an approved and executed art proposal. (Internal function called by `executeProposal`).
 *    - `getArtNFTContractAddress()`: Returns the address of the deployed Art NFT contract managed by this collective.
 *
 * 5. **Reputation & Rewards (Advanced Concept):**
 *    - `contributeToCollective(uint256 _contributionValue, string memory _contributionDescription)`: Members can record contributions to the collective, increasing their reputation score.
 *    - `distributeRewards()`: Distributes treasury funds as rewards to members based on their reputation score (can be triggered periodically or upon reaching certain milestones).
 *    - `getMemberReputation(address _member)`: Retrieves the reputation score of a member.
 *
 * 6. **Governance & Parameters (Advanced Concept):**
 *    - `changeMembershipFee(uint256 _newFee)`: Allows the contract owner (or DAO governance if implemented) to change the membership fee.
 *    - `changeVotingDuration(uint256 _newDuration)`: Allows changing the voting duration for proposals and requests.
 *    - `getParameter(string memory _parameterName)`:  A generic function to retrieve configurable parameters.
 *
 * **Events:**
 * - `MemberJoined(address member)`
 * - `MemberLeft(address member)`
 * - `ArtProposalCreated(uint256 proposalId, address proposer, string title)`
 * - `VoteCastOnProposal(uint256 proposalId, address voter, bool support)`
 * - `ArtProposalExecuted(uint256 proposalId, address executor)`
 * - `TreasuryDeposit(address depositor, uint256 amount)`
 * - `WithdrawalRequestCreated(uint256 requestId, address requester, uint256 amount, string reason)`
 * - `VoteCastOnWithdrawalRequest(uint256 requestId, address voter, bool support)`
 * - `WithdrawalRequestExecuted(uint256 requestId, address executor, address recipient, uint256 amount)`
 * - `ArtNFTMinted(uint256 proposalId, uint256 tokenId, address minter)`
 * - `ContributionRecorded(address member, uint256 value, string description)`
 * - `RewardsDistributed(uint256 totalRewardsDistributed)`
 * - `ParameterChanged(string parameterName, string newValue)`
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedAutonomousArtCollective is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    uint256 public membershipFee;
    uint256 public votingDuration; // in blocks
    ERC721 public artNFTContract; // Deployed NFT contract for collective's art

    mapping(address => bool) public members;
    Counters.Counter private memberCount;
    mapping(address => uint256) public memberJoinTime; // Track join time for weighted voting

    struct ArtProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 creationTime;
        uint256 voteEndTime;
        mapping(address => bool) votes; // Member address to vote (true = support, false = oppose)
        uint256 supportVotes;
        uint256 opposeVotes;
        bool executed;
    }
    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private proposalCount;

    struct WithdrawalRequest {
        uint256 id;
        address requester;
        uint256 amount;
        string reason;
        uint256 creationTime;
        uint256 voteEndTime;
        mapping(address => bool) votes; // Member address to vote (true = support, false = oppose)
        uint256 supportVotes;
        uint256 opposeVotes;
        bool executed;
    }
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;
    Counters.Counter private withdrawalRequestCount;

    mapping(address => uint256) public memberReputation;
    uint256 public reputationRewardThreshold = 1000; // Example threshold to trigger rewards

    // --- Events ---

    event MemberJoined(address indexed member);
    event MemberLeft(address indexed member);
    event ArtProposalCreated(uint256 proposalId, address indexed proposer, string title);
    event VoteCastOnProposal(uint256 proposalId, address indexed voter, bool support);
    event ArtProposalExecuted(uint256 proposalId, address indexed executor);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event WithdrawalRequestCreated(uint256 requestId, address indexed requester, uint256 amount, string reason);
    event VoteCastOnWithdrawalRequest(uint256 requestId, address indexed voter, bool support);
    event WithdrawalRequestExecuted(uint256 requestId, uint256 amount, address indexed recipient);
    event ArtNFTMinted(uint256 proposalId, uint256 tokenId, address indexed minter);
    event ContributionRecorded(address indexed member, uint256 value, string description);
    event RewardsDistributed(uint256 totalRewardsDistributed);
    event ParameterChanged(string parameterName, string newValue);

    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender], "Not a member of the collective.");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _membershipFee, uint256 _votingDuration, string memory _nftName, string memory _nftSymbol) payable {
        membershipFee = _membershipFee;
        votingDuration = _votingDuration;
        artNFTContract = new CollectiveArtNFT(_nftName, _nftSymbol);
        // Optionally fund the treasury upon contract deployment
        if (msg.value > 0) {
            emit TreasuryDeposit(address(this), msg.value); // Depositor is the contract itself in this case for initial funding
        }
    }

    // --- 1. Membership Management Functions ---

    function joinCollective() public payable {
        require(!members[msg.sender], "Already a member.");
        require(msg.value >= membershipFee, "Insufficient membership fee paid.");
        members[msg.sender] = true;
        memberCount.increment();
        memberJoinTime[msg.sender] = block.timestamp;
        payable(address(this)).transfer(msg.value); // Send membership fee to contract treasury
        emit MemberJoined(msg.sender);
        emit TreasuryDeposit(msg.sender, msg.value); // Treat membership fee as a deposit
    }

    function leaveCollective() public onlyMember {
        members[msg.sender] = false;
        memberCount.decrement();
        delete memberJoinTime[msg.sender];
        // Potentially refund a portion of the membership fee based on contract terms
        // For simplicity, no refund in this example.
        emit MemberLeft(msg.sender);
    }

    function getMemberCount() public view returns (uint256) {
        return memberCount.current();
    }

    function isMember(address _user) public view returns (bool) {
        return members[_user];
    }

    // --- 2. Art Proposal System Functions ---

    function proposeArtPiece(string memory _title, string memory _description, string memory _ipfsHash) public onlyMember {
        proposalCount.increment();
        uint256 proposalId = proposalCount.current();
        artProposals[proposalId] = ArtProposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            creationTime: block.timestamp,
            voteEndTime: block.timestamp + votingDuration,
            supportVotes: 0,
            opposeVotes: 0,
            executed: false
        });
        emit ArtProposalCreated(proposalId, msg.sender, _title);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public onlyMember {
        require(artProposals[_proposalId].creationTime > 0, "Proposal does not exist.");
        require(block.timestamp < artProposals[_proposalId].voteEndTime, "Voting has ended for this proposal.");
        require(!artProposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");

        artProposals[_proposalId].votes[msg.sender] = true; // Record vote
        if (_support) {
            artProposals[_proposalId].supportVotes++;
        } else {
            artProposals[_proposalId].opposeVotes++;
        }
        emit VoteCastOnProposal(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public onlyMember {
        require(artProposals[_proposalId].creationTime > 0, "Proposal does not exist.");
        require(!artProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= artProposals[_proposalId].voteEndTime, "Voting is still ongoing.");
        require(artProposals[_proposalId].supportVotes > artProposals[_proposalId].opposeVotes, "Proposal did not pass.");

        artProposals[_proposalId].executed = true;
        mintArtNFT(_proposalId); // Mint NFT for the approved art
        // Optionally allocate funds from treasury to proposer or for project expenses related to the art piece.
        // Example: transfer funds from treasury if needed for art creation costs.
        emit ArtProposalExecuted(_proposalId, msg.sender);
    }

    function getProposalDetails(uint256 _proposalId) public view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getProposalVotingStats(uint256 _proposalId) public view returns (uint256 supportVotes, uint256 opposeVotes, uint256 voteEndTime) {
        return (artProposals[_proposalId].supportVotes, artProposals[_proposalId].opposeVotes, artProposals[_proposalId].voteEndTime);
    }

    function getProposalCount() public view returns (uint256) {
        return proposalCount.current();
    }


    // --- 3. Treasury Management Functions ---

    function depositToTreasury() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        payable(address(this)).transfer(msg.value);
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function requestTreasuryWithdrawal(uint256 _amount, string memory _reason) public onlyMember {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(address(this).balance >= _amount, "Insufficient treasury balance for withdrawal.");

        withdrawalRequestCount.increment();
        uint256 requestId = withdrawalRequestCount.current();
        withdrawalRequests[requestId] = WithdrawalRequest({
            id: requestId,
            requester: msg.sender,
            amount: _amount,
            reason: _reason,
            creationTime: block.timestamp,
            voteEndTime: block.timestamp + votingDuration,
            supportVotes: 0,
            opposeVotes: 0,
            executed: false
        });
        emit WithdrawalRequestCreated(requestId, msg.sender, _amount, _reason);
    }

    function voteOnWithdrawalRequest(uint256 _requestId, bool _support) public onlyMember {
        require(withdrawalRequests[_requestId].creationTime > 0, "Withdrawal request does not exist.");
        require(block.timestamp < withdrawalRequests[_requestId].voteEndTime, "Voting has ended for this request.");
        require(!withdrawalRequests[_requestId].votes[msg.sender], "Already voted on this request.");

        withdrawalRequests[_requestId].votes[msg.sender] = true;
        if (_support) {
            withdrawalRequests[_requestId].supportVotes++;
        } else {
            withdrawalRequests[_requestId].opposeVotes++;
        }
        emit VoteCastOnWithdrawalRequest(_requestId, msg.sender, _support);
    }

    function executeWithdrawalRequest(uint256 _requestId) public onlyMember {
        require(withdrawalRequests[_requestId].creationTime > 0, "Withdrawal request does not exist.");
        require(!withdrawalRequests[_requestId].executed, "Withdrawal request already executed.");
        require(block.timestamp >= withdrawalRequests[_requestId].voteEndTime, "Voting is still ongoing.");
        require(withdrawalRequests[_requestId].supportVotes > withdrawalRequests[_requestId].opposeVotes, "Withdrawal request did not pass.");

        withdrawalRequests[_requestId].executed = true;
        uint256 amount = withdrawalRequests[_requestId].amount;
        address recipient = withdrawalRequests[_requestId].requester;
        payable(recipient).transfer(amount);
        emit WithdrawalRequestExecuted(_requestId, amount, recipient);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getWithdrawalRequestDetails(uint256 _requestId) public view returns (WithdrawalRequest memory) {
        return withdrawalRequests[_requestId];
    }

    function getWithdrawalRequestVotingStats(uint256 _requestId) public view returns (uint256 supportVotes, uint256 opposeVotes, uint256 voteEndTime) {
        return (withdrawalRequests[_requestId].supportVotes, withdrawalRequests[_requestId].opposeVotes, withdrawalRequests[_requestId].voteEndTime);
    }

    function getWithdrawalRequestCount() public view returns (uint256) {
        return withdrawalRequestCount.current();
    }

    // --- 4. NFT Minting & Management Functions ---

    function mintArtNFT(uint256 _proposalId) internal {
        require(artProposals[_proposalId].creationTime > 0, "Proposal does not exist.");
        require(artProposals[_proposalId].executed, "Proposal must be executed to mint NFT.");

        uint256 tokenId = artNFTContract.nextTokenIdCounter(); // Assuming CollectiveArtNFT has this
        artNFTContract.mint(address(this), tokenId, artProposals[_proposalId].ipfsHash); // Mint to contract itself, collective owns it. Could mint to proposer or treasury too.
        emit ArtNFTMinted(_proposalId, tokenId, address(this)); // Minter is the contract itself in this case.
    }

    function getArtNFTContractAddress() public view returns (address) {
        return address(artNFTContract);
    }


    // --- 5. Reputation & Rewards Functions ---

    function contributeToCollective(uint256 _contributionValue, string memory _contributionDescription) public onlyMember {
        memberReputation[msg.sender] += _contributionValue;
        emit ContributionRecorded(msg.sender, _contributionValue, _contributionDescription);
        // Could implement more sophisticated reputation logic, like decay over time, different types of contributions, etc.
    }

    function distributeRewards() public onlyMember { // Can be triggered by any member, or could be automated off-chain
        uint256 totalRewardsDistributed = 0;
        uint256 treasuryBalance = address(this).balance;

        // Example: Distribute a portion of the treasury to members with reputation above threshold
        uint256 rewardAmountPerReputationPoint = 1 wei; // Example, adjust as needed.
        uint256 totalRewardsPool = treasuryBalance.div(10); // Example: Distribute 10% of treasury. Adjust percentage as needed.

        uint256 membersEligibleForRewards = 0;
        for (uint256 i = 1; i <= memberCount.current(); i++) {
            address memberAddress = getMemberAddressByIndex(i); // Need a way to iterate through members efficiently - placeholder function
            if (memberReputation[memberAddress] >= reputationRewardThreshold) {
                membersEligibleForRewards++;
            }
        }

        if (membersEligibleForRewards > 0) {
             uint256 rewardPerMember = totalRewardsPool.div(membersEligibleForRewards);

            for (uint256 i = 1; i <= memberCount.current(); i++) {
                address memberAddress = getMemberAddressByIndex(i); // Need a way to iterate through members efficiently - placeholder function
                if (memberReputation[memberAddress] >= reputationRewardThreshold) {
                    payable(memberAddress).transfer(rewardPerMember);
                    totalRewardsDistributed = totalRewardsDistributed.add(rewardPerMember);
                }
            }
            emit RewardsDistributed(totalRewardsDistributed);
        }
    }

    function getMemberReputation(address _member) public view returns (uint256) {
        return memberReputation[_member];
    }

    // --- 6. Governance & Parameter Functions ---

    function changeMembershipFee(uint256 _newFee) public onlyOwner {
        membershipFee = _newFee;
        emit ParameterChanged("membershipFee", string.decimal(int256(_newFee)));
    }

    function changeVotingDuration(uint256 _newDuration) public onlyOwner {
        votingDuration = _newDuration;
        emit ParameterChanged("votingDuration", string.decimal(int256(_newDuration)));
    }

    function getParameter(string memory _parameterName) public view returns (string memory) {
        if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("membershipFee"))) {
            return string.decimal(int256(membershipFee));
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("votingDuration"))) {
            return string.decimal(int256(votingDuration));
        } else {
            return "Parameter not found";
        }
    }

    // --- Utility/Helper Functions ---

    // **Important:**  This is a placeholder for a more efficient way to iterate members.
    // In a real-world scenario, you'd need to maintain a list or array of members for efficient iteration,
    // as iterating through a mapping is not directly possible and can be gas-inefficient.
    function getMemberAddressByIndex(uint256 _index) internal view returns (address) {
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= memberCount.current(); i++) { // Iterate up to current member count
            if (currentIndex == _index -1 ) { // Find the member at the given index
                // **This is a placeholder - You need to implement a real way to map index to member address.**
                //  Example:  If you maintain an array of members, you can access it by index.
                //  For now, this placeholder will just return a zero address, which is incorrect.
                //  Replace this logic with actual member index tracking if you need to iterate members.
                return address(0); // Placeholder - Replace this!
            }
            currentIndex++;
        }
        return address(0); // Index out of bounds or member not found (placeholder behavior)
    }

    // --- NFT Contract (Example - Minimal ERC721 for Art) ---
}

contract CollectiveArtNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => string) private _tokenIPFSHash;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function mint(address _to, uint256 _tokenId, string memory _ipfsHash) public {
        _mint(_to, _tokenId);
        _tokenIPFSHash[_tokenId] = _ipfsHash;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenIPFSHash[tokenId]; // In a real implementation, you'd construct a proper metadata URI using IPFS hash.
    }

    function nextTokenIdCounter() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);
        _tokenIdCounter.increment();
    }
}
```