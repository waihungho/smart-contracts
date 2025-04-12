```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Not for Production)
 * @notice A smart contract for a Decentralized Autonomous Art Collective.
 * It facilitates collaborative art creation, ownership, governance, and community engagement.
 *
 * **Outline & Function Summary:**
 *
 * **1. Membership & Governance:**
 *    - `joinCollective()`: Allows users to request membership.
 *    - `approveMembership(address _user)`: Admin/Council function to approve membership requests.
 *    - `revokeMembership(address _member)`: Admin/Council function to remove a member.
 *    - `isMember(address _user)`: Checks if an address is a member.
 *    - `proposeGovernanceChange(string _description, bytes _data)`: Members propose changes to collective rules.
 *    - `voteOnGovernanceChange(uint256 _proposalId, bool _support)`: Members vote on governance proposals.
 *    - `executeGovernanceChange(uint256 _proposalId)`: Executes a passed governance proposal.
 *
 * **2. Collaborative Art Creation & NFT Management:**
 *    - `submitArtProposal(string _title, string _description, string _ipfsHash)`: Members propose new art pieces to be created/minted.
 *    - `voteOnArtProposal(uint256 _proposalId, bool _support)`: Members vote on art proposals.
 *    - `mintCollectiveNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal (Council/Admin function).
 *    - `setNFTMetadata(uint256 _tokenId, string _ipfsMetadataHash)`: Sets metadata for a minted NFT (Council/Admin function).
 *    - `transferNFTToCollective(address _nftContract, uint256 _tokenId)`: Allows members to donate existing NFTs to the collective.
 *    - `burnCollectiveNFT(uint256 _tokenId)`: Allows burning of a collective NFT through governance proposal and execution.
 *
 * **3. Fractional Ownership & Revenue Sharing (Advanced Concept):**
 *    - `fractionalizeNFT(uint256 _tokenId, uint256 _fractionCount)`: Fractionalizes a collective NFT into fungible tokens (ERC1155 or similar).
 *    - `buyFractionalToken(uint256 _tokenId, uint256 _amount)`: Allows members to buy fractional ownership tokens.
 *    - `sellFractionalToken(uint256 _tokenId, uint256 _amount)`: Allows members to sell fractional ownership tokens back to the collective or market.
 *    - `distributeRevenueShare(uint256 _tokenId)`: Distributes revenue from NFT sales or royalties to fractional token holders.
 *
 * **4. Community Engagement & Curation:**
 *    - `createExhibitionProposal(string _title, string _description, uint256[] _nftTokenIds)`: Propose an art exhibition featuring collective NFTs.
 *    - `voteOnExhibitionProposal(uint256 _proposalId, bool _support)`: Members vote on exhibition proposals.
 *    - `scheduleExhibition(uint256 _proposalId, uint256 _startTime, uint256 _endTime)`: Council/Admin function to schedule an approved exhibition.
 *    - `rewardActiveMembers(address[] _members, uint256 _amount)`: Rewards active members based on contribution (Council/Admin function, potentially automated based on activity score - not implemented here for simplicity).
 *    - `donateToCollective()`: Allows anyone to donate ETH to the collective.
 *
 * **5. Utility & Information:**
 *    - `getCollectiveNFTs()`: Returns a list of token IDs owned by the collective.
 *    - `getFractionalTokenBalance(uint256 _tokenId, address _member)`: Gets the fractional token balance of a member for a specific NFT.
 *    - `getGovernanceProposalDetails(uint256 _proposalId)`: Returns details of a governance proposal.
 *    - `getArtProposalDetails(uint256 _proposalId)`: Returns details of an art proposal.
 *    - `getExhibitionProposalDetails(uint256 _proposalId)`: Returns details of an exhibition proposal.
 *    - `getMembershipRequests()`: Returns a list of pending membership requests (Admin/Council function).
 *    - `getVersion()`: Returns the contract version.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DecentralizedArtCollective is Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public contractName = "Decentralized Autonomous Art Collective";
    string public version = "1.0.0";

    // --- Data Structures ---
    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        bytes data; // To store encoded function calls for execution
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) voters; // Track who has voted
    }

    struct ArtProposal {
        uint256 proposalId;
        string title;
        string description;
        string ipfsHash; // IPFS hash of the artwork
        address proposer;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
        bool minted;
        mapping(address => bool) voters; // Track who has voted
    }

    struct ExhibitionProposal {
        uint256 proposalId;
        string title;
        string description;
        uint256[] nftTokenIds;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) voters; // Track who has voted
    }

    struct FractionalNFT {
        uint256 tokenId;
        uint256 fractionCount;
        address fractionalTokenContract; // Address of the ERC1155 or similar contract
        mapping(address => uint256) fractionalTokenBalances; // Track balances (example, could use a separate token contract for more robust implementation)
    }

    Counters.Counter private _governanceProposalIds;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    Counters.Counter private _artProposalIds;
    mapping(uint256 => ArtProposal) public artProposals;

    Counters.Counter private _exhibitionProposalIds;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;

    mapping(uint256 => FractionalNFT) public fractionalNFTs;
    Counters.Counter private _fractionalNFTTokenIds; // Counter for fractional NFT token IDs (if using ERC1155 approach)

    EnumerableSet.AddressSet private _members;
    mapping(address => bool) public membershipRequested;
    address[] public membershipRequestList; // Keep track of pending requests for easier admin review

    EnumerableSet.UintSet private _collectiveNFTTokenIds; // Track NFTs owned by the collective

    address payable[] public councilMembers; // Council members for admin/privileged actions (consider more robust governance for production)

    uint256 public votingDuration = 7 days; // Default voting duration

    // --- Events ---
    event MembershipRequested(address indexed user);
    event MembershipApproved(address indexed member, address indexed approvedBy);
    event MembershipRevoked(address indexed member, address indexed revokedBy);
    event GovernanceProposalCreated(uint256 proposalId, string description);
    event GovernanceVoteCast(uint256 proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ArtProposalCreated(uint256 proposalId, string title, address proposer);
    event ArtVoteCast(uint256 proposalId, address indexed voter, bool support);
    event CollectiveNFTMinted(uint256 tokenId, uint256 proposalId);
    event NFTMetadataSet(uint256 tokenId, string metadataHash);
    event NFTTransferredToCollective(address nftContract, uint256 tokenId, address indexed sender);
    event NFTBurnedFromCollective(uint256 tokenId);
    event FractionalizedNFT(uint256 tokenId, uint256 fractionCount, address fractionalTokenContract);
    event FractionalTokenBought(uint256 tokenId, address indexed buyer, uint256 amount);
    event FractionalTokenSold(uint256 tokenId, address indexed seller, uint256 amount);
    event RevenueShareDistributed(uint256 tokenId, uint256 amount);
    event ExhibitionProposalCreated(uint256 proposalId, string title);
    event ExhibitionVoteCast(uint256 proposalId, uint256 proposalIdExhibition, address indexed voter, bool support);
    event ExhibitionScheduled(uint256 proposalId, uint256 startTime, uint256 endTime);
    event DonationReceived(address indexed donor, uint256 amount);
    event RewardDistributed(address[] recipients, uint256 amount);

    // --- Modifiers ---
    modifier onlyMember() {
        require(_members.contains(_msgSender()), "Not a member of the collective.");
        _;
    }

    modifier onlyCouncil() {
        bool isCouncil = false;
        for (uint256 i = 0; i < councilMembers.length; i++) {
            if (councilMembers[i] == payable(_msgSender())) {
                isCouncil = true;
                break;
            }
        }
        require(isCouncil || _msgSender() == owner(), "Only council members or owner can perform this action.");
        _;
    }

    modifier proposalExists(uint256 _proposalId, mapping(uint256 => GovernanceProposal) storage _proposals) {
        require(_proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier artProposalExists(uint256 _proposalId) {
        require(artProposals[_proposalId].proposalId == _proposalId, "Art proposal does not exist.");
        _;
    }

    modifier exhibitionProposalExists(uint256 _proposalId) {
        require(exhibitionProposals[_proposalId].proposalId == _proposalId, "Exhibition proposal does not exist.");
        _;
    }

    modifier votingActive(uint256 _proposalId, mapping(uint256 => GovernanceProposal) storage _proposals) {
        require(block.timestamp >= _proposals[_proposalId].votingStartTime && block.timestamp <= _proposals[_proposalId].votingEndTime, "Voting is not active.");
        _;
    }

    modifier artVotingActive(uint256 _proposalId) {
        require(block.timestamp >= artProposals[_proposalId].votingStartTime && block.timestamp <= artProposals[_proposalId].votingEndTime, "Voting is not active.");
        _;
    }

    modifier exhibitionVotingActive(uint256 _proposalId) {
        require(block.timestamp >= exhibitionProposals[_proposalId].votingStartTime && block.timestamp <= exhibitionProposals[_proposalId].votingEndTime, "Voting is not active.");
        _;
    }

    modifier notVoted(uint256 _proposalId, mapping(uint256 => GovernanceProposal) storage _proposals) {
        require(!_proposals[_proposalId].voters[_msgSender()], "Already voted on this proposal.");
        _;
    }

    modifier artNotVoted(uint256 _proposalId) {
        require(!artProposals[_proposalId].voters[_msgSender()], "Already voted on this art proposal.");
        _;
    }

    modifier exhibitionNotVoted(uint256 _proposalId) {
        require(!exhibitionProposals[_proposalId].voters[_msgSender()], "Already voted on this exhibition proposal.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId, mapping(uint256 => GovernanceProposal) storage _proposals) {
        require(!_proposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier artProposalNotMinted(uint256 _proposalId) {
        require(!artProposals[_proposalId].minted, "Art proposal already minted.");
        _;
    }

    modifier exhibitionProposalNotScheduled(uint256 _proposalId) {
        require(!exhibitionProposals[_proposalId].approved, "Exhibition proposal already scheduled."); // 'approved' here is used as a flag for scheduled
        _;
    }

    // --- 1. Membership & Governance ---
    constructor() payable {
        councilMembers.push(payable(msg.sender)); // Owner is the initial council member
    }

    function joinCollective() external {
        require(!_members.contains(_msgSender()), "Already a member.");
        require(!membershipRequested[_msgSender()], "Membership already requested.");
        membershipRequested[_msgSender()] = true;
        membershipRequestList.push(_msgSender());
        emit MembershipRequested(_msgSender());
    }

    function approveMembership(address _user) external onlyCouncil {
        require(membershipRequested[_user], "Membership not requested.");
        require(!_members.contains(_user), "User is already a member.");
        _members.add(_user);
        membershipRequested[_user] = false;

        // Remove from pending list (inefficient if list is very long, consider optimization for production)
        for (uint256 i = 0; i < membershipRequestList.length; i++) {
            if (membershipRequestList[i] == _user) {
                membershipRequestList[i] = membershipRequestList[membershipRequestList.length - 1];
                membershipRequestList.pop();
                break;
            }
        }

        emit MembershipApproved(_user, _msgSender());
    }

    function revokeMembership(address _member) external onlyCouncil {
        require(_members.contains(_member), "Not a member.");
        _members.remove(_member);
        emit MembershipRevoked(_member, _msgSender());
    }

    function isMember(address _user) external view returns (bool) {
        return _members.contains(_user);
    }

    function proposeGovernanceChange(string memory _description, bytes memory _data) external onlyMember {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _description,
            data: _data,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            voters: mapping(address => bool)()
        });
        emit GovernanceProposalCreated(proposalId, _description);
    }

    function voteOnGovernanceChange(uint256 _proposalId, bool _support)
        external
        onlyMember
        proposalExists(_proposalId, governanceProposals)
        votingActive(_proposalId, governanceProposals)
        notVoted(_proposalId, governanceProposals)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        proposal.voters[_msgSender()] = true;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, _msgSender(), _support);
    }

    function executeGovernanceChange(uint256 _proposalId)
        external
        onlyCouncil
        proposalExists(_proposalId, governanceProposals)
        proposalNotExecuted(_proposalId, governanceProposals)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting still active.");
        require(proposal.yesVotes > proposal.noVotes, "Proposal failed to pass."); // Simple majority, adjust as needed

        (bool success, ) = address(this).call(proposal.data); // Execute the encoded function call
        require(success, "Governance proposal execution failed.");

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    // --- 2. Collaborative Art Creation & NFT Management ---
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember {
        _artProposalIds.increment();
        uint256 proposalId = _artProposalIds.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: _msgSender(),
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            approved: false,
            minted: false,
            voters: mapping(address => bool)()
        });
        emit ArtProposalCreated(proposalId, _title, _msgSender());
    }

    function voteOnArtProposal(uint256 _proposalId, bool _support)
        external
        onlyMember
        artProposalExists(_proposalId)
        artVotingActive(_proposalId)
        artNotVoted(_proposalId)
    {
        ArtProposal storage proposal = artProposals[_proposalId];
        proposal.voters[_msgSender()] = true;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtVoteCast(_proposalId, _msgSender(), _support);
    }

    function mintCollectiveNFT(uint256 _proposalId) external onlyCouncil artProposalExists(_proposalId) artProposalNotMinted(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting still active.");
        require(proposal.yesVotes > proposal.noVotes, "Art proposal failed to pass."); // Simple majority
        proposal.approved = true;

        _collectiveNFTTokenIds.add(_artProposalIds.current()); // Using art proposal ID as token ID for simplicity, consider a separate NFT counter in production
        uint256 tokenId = _artProposalIds.current(); // Or use a separate NFT counter.
        // **In a real scenario, you would mint an actual NFT here using an ERC721/ERC1155 contract and store the token ID.**
        // For simplicity, we are just tracking the token ID within this contract.
        proposal.minted = true;
        emit CollectiveNFTMinted(tokenId, _proposalId);
    }

    function setNFTMetadata(uint256 _tokenId, string memory _ipfsMetadataHash) external onlyCouncil {
        require(_collectiveNFTTokenIds.contains(_tokenId), "Not a collective NFT.");
        // **In a real scenario, you would update the metadata on the NFT contract.**
        // For simplicity, we just emit an event.
        emit NFTMetadataSet(_tokenId, _ipfsMetadataHash);
    }

    function transferNFTToCollective(address _nftContract, uint256 _tokenId) external onlyMember {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == _msgSender(), "Sender is not the NFT owner.");
        nft.safeTransferFrom(_msgSender(), address(this), _tokenId);
        _collectiveNFTTokenIds.add(_tokenId); // Track the donated NFT
        emit NFTTransferredToCollective(_nftContract, _tokenId, _msgSender());
    }

    function burnCollectiveNFT(uint256 _tokenId) external onlyCouncil {
        require(_collectiveNFTTokenIds.contains(_tokenId), "Not a collective NFT.");
        _collectiveNFTTokenIds.remove(_tokenId);
        // **In a real scenario, you would burn the NFT from the actual NFT contract.**
        // For simplicity, we just emit an event.
        emit NFTBurnedFromCollective(_tokenId);
    }


    // --- 3. Fractional Ownership & Revenue Sharing ---
    function fractionalizeNFT(uint256 _tokenId, uint256 _fractionCount) external onlyCouncil {
        require(_collectiveNFTTokenIds.contains(_tokenId), "Not a collective NFT.");
        require(fractionalNFTs[_tokenId].tokenId == 0, "NFT already fractionalized."); // Prevent re-fractionalization

        _fractionalNFTTokenIds.increment();
        uint256 fractionalTokenId = _fractionalNFTTokenIds.current(); // Example token ID if using ERC1155

        fractionalNFTs[_tokenId] = FractionalNFT({
            tokenId: _tokenId,
            fractionCount: _fractionCount,
            fractionalTokenContract: address(0), // **In a real scenario, deploy or link an ERC1155 contract here.**
            fractionalTokenBalances: mapping(address => uint256)()
        });

        // **In a real scenario, mint ERC1155 tokens to the collective contract representing fractions.**
        // Example: Mint _fractionCount tokens of tokenId `fractionalTokenId` to `address(this)` on ERC1155 contract.

        emit FractionalizedNFT(_tokenId, _fractionCount, address(0)); // Replace address(0) with actual token contract address
    }

    function buyFractionalToken(uint256 _tokenId, uint256 _amount) external payable onlyMember {
        require(fractionalNFTs[_tokenId].tokenId == _tokenId, "NFT not fractionalized.");
        FractionalNFT storage fractional = fractionalNFTs[_tokenId];
        // **In a real scenario, you would transfer tokens from the collective to the buyer and handle payment.**
        // Example: Transfer _amount of ERC1155 tokens (tokenId `fractionalTokenId` related to _tokenId) from `address(this)` to `_msgSender()` on ERC1155 contract.
        // Example: Handle ETH payment and potentially store it for revenue distribution.

        fractional.fractionalTokenBalances[_msgSender()] += _amount; // Simple balance tracking - replace with actual token transfer logic
        emit FractionalTokenBought(_tokenId, _msgSender(), _amount);
        emit DonationReceived(_msgSender(), msg.value); // Treat buy as donation for simplicity in this example
    }

    function sellFractionalToken(uint256 _tokenId, uint256 _amount) external onlyMember {
        require(fractionalNFTs[_tokenId].tokenId == _tokenId, "NFT not fractionalized.");
        FractionalNFT storage fractional = fractionalNFTs[_tokenId];
        require(fractional.fractionalTokenBalances[_msgSender()] >= _amount, "Insufficient fractional tokens.");

        // **In a real scenario, you would transfer tokens from the seller back to the collective and handle payment.**
        // Example: Transfer _amount of ERC1155 tokens from `_msgSender()` back to `address(this)` on ERC1155 contract.
        // Example: Send ETH payment back to the seller (from collective balance or market).

        fractional.fractionalTokenBalances[_msgSender()] -= _amount; // Simple balance tracking - replace with actual token transfer logic
        emit FractionalTokenSold(_tokenId, _msgSender(), _amount);
        // **Consider adding logic for pricing and how tokens are bought back (e.g., fixed price, market price, etc.)**
    }

    function distributeRevenueShare(uint256 _tokenId) external onlyCouncil {
        require(fractionalNFTs[_tokenId].tokenId == _tokenId, "NFT not fractionalized.");
        FractionalNFT storage fractional = fractionalNFTs[_tokenId];

        // **In a real scenario, calculate revenue (e.g., from NFT sales, royalties) associated with _tokenId.**
        uint256 totalRevenue = address(this).balance; // Example: Use contract balance as revenue (simplistic for demonstration)

        uint256 totalFractionalTokens = fractional.fractionCount; // Total supply of fractional tokens

        for (EnumerableSet.AddressSetIterator memberIterator = _members.iterator(); EnumerableSet.AddressSetIterator.hasNext(memberIterator); ) {
            address member = EnumerableSet.AddressSetIterator.next(memberIterator);
            uint256 memberFractionalBalance = fractional.fractionalTokenBalances[member];
            if (memberFractionalBalance > 0) {
                uint256 shareAmount = (totalRevenue * memberFractionalBalance) / totalFractionalTokens;
                if (shareAmount > 0) {
                    payable(member).transfer(shareAmount); // Transfer ETH share
                    emit RevenueShareDistributed(_tokenId, shareAmount);
                }
            }
        }
    }

    // --- 4. Community Engagement & Curation ---
    function createExhibitionProposal(string memory _title, string memory _description, uint256[] memory _nftTokenIds) external onlyMember {
        require(_nftTokenIds.length > 0, "Exhibition must include at least one NFT.");
        for (uint256 i = 0; i < _nftTokenIds.length; i++) {
            require(_collectiveNFTTokenIds.contains(_nftTokenIds[i]), "Exhibition can only include collective NFTs.");
        }

        _exhibitionProposalIds.increment();
        uint256 proposalId = _exhibitionProposalIds.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            proposalId: proposalId,
            title: _title,
            description: _description,
            nftTokenIds: _nftTokenIds,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            approved: false,
            startTime: 0,
            endTime: 0,
            voters: mapping(address => bool)()
        });
        emit ExhibitionProposalCreated(proposalId, _title);
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _support)
        external
        onlyMember
        exhibitionProposalExists(_proposalId)
        exhibitionVotingActive(_proposalId)
        exhibitionNotVoted(_proposalId)
    {
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        proposal.voters[_msgSender()] = true;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ExhibitionVoteCast(_proposalId, _proposalId, _msgSender(), _support);
    }

    function scheduleExhibition(uint256 _proposalId, uint256 _startTime, uint256 _endTime)
        external
        onlyCouncil
        exhibitionProposalExists(_proposalId)
        exhibitionProposalNotScheduled(_proposalId)
    {
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting still active.");
        require(proposal.yesVotes > proposal.noVotes, "Exhibition proposal failed to pass."); // Simple majority

        proposal.approved = true; // Mark as scheduled
        proposal.startTime = _startTime;
        proposal.endTime = _endTime;
        emit ExhibitionScheduled(_proposalId, _startTime, _endTime);
    }

    function rewardActiveMembers(address[] memory _members, uint256 _amount) external onlyCouncil {
        require(_amount > 0, "Reward amount must be positive.");
        uint256 totalReward = _amount * _members.length;
        require(address(this).balance >= totalReward, "Insufficient contract balance for rewards.");

        for (uint256 i = 0; i < _members.length; i++) {
            payable(_members[i]).transfer(_amount);
        }
        emit RewardDistributed(_members, _amount);
    }

    function donateToCollective() external payable {
        emit DonationReceived(_msgSender(), msg.value);
    }

    // --- 5. Utility & Information ---
    function getCollectiveNFTs() external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](_collectiveNFTTokenIds.length());
        for (uint256 i = 0; i < _collectiveNFTTokenIds.length(); i++) {
            tokenIds[i] = _collectiveNFTTokenIds.at(i);
        }
        return tokenIds;
    }

    function getFractionalTokenBalance(uint256 _tokenId, address _member) external view returns (uint256) {
        return fractionalNFTs[_tokenId].fractionalTokenBalances[_member];
    }

    function getGovernanceProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getExhibitionProposalDetails(uint256 _proposalId) external view returns (ExhibitionProposal memory) {
        return exhibitionProposals[_proposalId];
    }

    function getMembershipRequests() external view onlyCouncil returns (address[] memory) {
        return membershipRequestList;
    }

    function getVersion() external view returns (string memory) {
        return version;
    }

    receive() external payable {
        emit DonationReceived(_msgSender(), msg.value); // Allow direct donations to contract
    }
}
```