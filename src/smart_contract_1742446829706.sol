```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized autonomous art collective, facilitating art creation, curation, ownership, and community governance.
 *
 * **Outline & Function Summary:**
 *
 * **1. Membership Management:**
 *    - `requestMembership()`: Allows users to request membership to the collective.
 *    - `approveMembership(address _user)`: Owner/Curators can approve membership requests.
 *    - `rejectMembership(address _user)`: Owner/Curators can reject membership requests.
 *    - `revokeMembership(address _user)`: Owner/Curators can revoke membership from existing members.
 *    - `isMember(address _user) view returns (bool)`: Checks if an address is a member.
 *    - `getMemberCount() view returns (uint256)`: Returns the total number of members.
 *
 * **2. Art Submission & Curation:**
 *    - `submitArtProposal(string memory _ipfsHash, string memory _title, string memory _description)`: Members can submit art proposals (IPFS hash, title, description).
 *    - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members can vote on art proposals.
 *    - `executeArtProposal(uint256 _proposalId)`: Owner/Curators can execute approved art proposals, minting NFTs.
 *    - `getArtProposalState(uint256 _proposalId) view returns (ProposalState)`: Gets the current state of an art proposal.
 *    - `getArtProposalDetails(uint256 _proposalId) view returns (ArtProposal)`: Retrieves details of a specific art proposal.
 *    - `getApprovedArtCount() view returns (uint256)`: Returns the count of approved art pieces (NFTs minted).
 *
 * **3. NFT Minting & Ownership:**
 *    - `mintArtNFT(uint256 _proposalId)`: (Internal, only callable after proposal execution) Mints an ERC721 NFT for an approved art piece.
 *    - `transferArtOwnership(uint256 _tokenId, address _to)`: Allows NFT owners to transfer ownership.
 *    - `getArtOwner(uint256 _tokenId) view returns (address)`: Returns the owner of a specific art NFT.
 *    - `getArtTokenUri(uint256 _tokenId) view returns (string memory)`: Returns the token URI for an art NFT.
 *
 * **4. Decentralized Governance & Voting:**
 *    - `createGovernanceProposal(string memory _description, bytes memory _calldata, address _target)`: Members can create governance proposals (e.g., parameter changes).
 *    - `voteOnGovernanceProposal(uint256 _proposalId, bool _vote)`: Members can vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: Owner/Curators can execute approved governance proposals.
 *    - `getGovernanceProposalState(uint256 _proposalId) view returns (ProposalState)`: Gets the state of a governance proposal.
 *    - `getGovernanceProposalDetails(uint256 _proposalId) view returns (GovernanceProposal)`: Retrieves details of a governance proposal.
 *
 * **5. Treasury & Funding (Basic):**
 *    - `depositToTreasury() payable`: Allows anyone to deposit ETH into the collective's treasury.
 *    - `withdrawFromTreasury(address _to, uint256 _amount)`: Owner/Curators can withdraw ETH from the treasury (governance could be added for more advanced control).
 *    - `getTreasuryBalance() view returns (uint256)`: Returns the current balance of the treasury.
 *
 * **6. Event Emission:**
 *    - Emits events for key actions like membership changes, art proposals, NFT minting, governance proposals, and treasury actions for off-chain monitoring and integration.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums and Structs ---

    enum ProposalState { Pending, Active, Approved, Rejected, Executed }

    struct ArtProposal {
        uint256 proposalId;
        address proposer;
        string ipfsHash;
        string title;
        string description;
        ProposalState state;
        uint256 upVotes;
        uint256 downVotes;
        uint256 submissionTimestamp;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes calldata;
        address target;
        ProposalState state;
        uint256 upVotes;
        uint256 downVotes;
        uint256 submissionTimestamp;
    }

    // --- State Variables ---

    mapping(address => bool) public members;
    Counters.Counter private memberCount;

    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private artProposalCount;
    uint256 public artProposalVoteDuration = 7 days; // Example duration

    mapping(uint256 => GovernanceProposal) public governanceProposals;
    Counters.Counter private governanceProposalCount;
    uint256 public governanceProposalVoteDuration = 14 days; // Example duration

    mapping(uint256 => address) public artTokenToProposalId; // Mapping tokenId to proposalId for reverse lookup
    Counters.Counter private artTokenIds;

    uint256 public membershipFee = 0.1 ether; // Example membership fee (can be changed via governance)
    uint256 public artProposalApprovalThreshold = 50; // Percentage threshold for art proposal approval
    uint256 public governanceProposalApprovalThreshold = 60; // Percentage threshold for governance proposal approval
    uint256 public votingQuorum = 10; // Minimum percentage of members needed to vote for a proposal to be valid

    address[] public curators; // Addresses with curation privileges (initially owner)

    // --- Events ---

    event MembershipRequested(address indexed user);
    event MembershipApproved(address indexed user, address indexed approvedBy);
    event MembershipRejected(address indexed user, address indexed rejectedBy);
    event MembershipRevoked(address indexed user, address indexed revokedBy);

    event ArtProposalSubmitted(uint256 proposalId, address indexed proposer, string ipfsHash);
    event ArtProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event ArtProposalExecuted(uint256 proposalId, uint256 tokenId);
    event ArtProposalRejected(uint256 proposalId);

    event GovernanceProposalSubmitted(uint256 proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId, uint256 tokenId);
    event GovernanceProposalRejected(uint256 proposalId);

    event TreasuryDeposit(address indexed sender, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount, address indexed withdrawnBy);

    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender], "Not a member of the collective.");
        _;
    }

    modifier onlyCurator() {
        bool isCurator = false;
        if (msg.sender == owner()) {
            isCurator = true;
        } else {
            for (uint256 i = 0; i < curators.length; i++) {
                if (curators[i] == msg.sender) {
                    isCurator = true;
                    break;
                }
            }
        }
        require(isCurator, "Not a curator.");
        _;
    }

    modifier validArtProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= artProposalCount.current(), "Invalid art proposal ID.");
        _;
    }

    modifier validGovernanceProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= governanceProposalCount.current(), "Invalid governance proposal ID.");
        _;
    }

    modifier proposalInState(uint256 _proposalId, ProposalState _state, bool isArtProposal) {
        if (isArtProposal) {
            require(artProposals[_proposalId].state == _state, "Art proposal not in required state.");
        } else {
            require(governanceProposals[_proposalId].state == _state, "Governance proposal not in required state.");
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        // Owner is initially a curator
        curators.push(owner());
    }

    // --- 1. Membership Management ---

    function requestMembership() external payable {
        require(!members[msg.sender], "Already a member.");
        require(msg.value >= membershipFee, "Insufficient membership fee.");
        // In a real-world scenario, you might want to handle the fee transfer more carefully (e.g., refund if rejected).
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _user) external onlyCurator {
        require(!members[_user], "Already a member.");
        members[_user] = true;
        memberCount.increment();
        emit MembershipApproved(_user, msg.sender);
    }

    function rejectMembership(address _user) external onlyCurator {
        require(!members[_user], "User is already a member or not pending."); // Simple check, could be more refined
        // Consider refunding membership fee here if applicable
        emit MembershipRejected(_user, msg.sender);
    }

    function revokeMembership(address _user) external onlyCurator {
        require(members[_user], "Not a member.");
        delete members[_user];
        memberCount.decrement();
        emit MembershipRevoked(_user, msg.sender);
    }

    function isMember(address _user) public view returns (bool) {
        return members[_user];
    }

    function getMemberCount() public view returns (uint256) {
        return memberCount.current();
    }

    // --- 2. Art Submission & Curation ---

    function submitArtProposal(string memory _ipfsHash, string memory _title, string memory _description) external onlyMember {
        artProposalCount.increment();
        uint256 proposalId = artProposalCount.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            ipfsHash: _ipfsHash,
            title: _title,
            description: _description,
            state: ProposalState.Pending,
            upVotes: 0,
            downVotes: 0,
            submissionTimestamp: block.timestamp
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _ipfsHash);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember validArtProposal(_proposalId) proposalInState(_proposalId, ProposalState.Pending, true) {
        require(block.timestamp <= artProposals[_proposalId].submissionTimestamp + artProposalVoteDuration, "Voting period has ended.");
        if (_vote) {
            artProposals[_proposalId].upVotes++;
        } else {
            artProposals[_proposalId].downVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        // Automatically transition to Active state if voting has started
        if (artProposals[_proposalId].state == ProposalState.Pending) {
            artProposals[_proposalId].state = ProposalState.Active;
        }

        // Check for automatic approval/rejection based on quorum and threshold after each vote for faster decision making (optional)
        _checkArtProposalOutcome(_proposalId);
    }

    function _checkArtProposalOutcome(uint256 _proposalId) internal {
        uint256 totalVotes = artProposals[_proposalId].upVotes + artProposals[_proposalId].downVotes;
        uint256 activeMembers = getMemberCount();

        if (activeMembers > 0 && (totalVotes * 100) / activeMembers >= votingQuorum) { // Quorum reached
            uint256 approvalPercentage = (artProposals[_proposalId].upVotes * 100) / totalVotes;
            if (approvalPercentage >= artProposalApprovalThreshold) {
                artProposals[_proposalId].state = ProposalState.Approved;
                emit ArtProposalExecuted(_proposalId, 0); // Token ID will be set upon minting
            } else {
                artProposals[_proposalId].state = ProposalState.Rejected;
                emit ArtProposalRejected(_proposalId);
            }
        }
    }


    function executeArtProposal(uint256 _proposalId) external onlyCurator validArtProposal(_proposalId) proposalInState(_proposalId, ProposalState.Approved, true) {
        artProposals[_proposalId].state = ProposalState.Executed;
        uint256 tokenId = _mintArtNFT(_proposalId);
        emit ArtProposalExecuted(_proposalId, tokenId);
    }

    function getArtProposalState(uint256 _proposalId) external view validArtProposal(_proposalId) returns (ProposalState) {
        return artProposals[_proposalId].state;
    }

    function getArtProposalDetails(uint256 _proposalId) external view validArtProposal(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getApprovedArtCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= artProposalCount.current(); i++) {
            if (artProposals[i].state == ProposalState.Executed) {
                count++;
            }
        }
        return count;
    }


    // --- 3. NFT Minting & Ownership ---

    function _mintArtNFT(uint256 _proposalId) internal returns (uint256) {
        artTokenIds.increment();
        uint256 tokenId = artTokenIds.current();
        _safeMint(artProposals[_proposalId].proposer, tokenId);
        artTokenToProposalId[tokenId] = _proposalId; // Store the mapping
        _setTokenURI(tokenId, artProposals[_proposalId].ipfsHash); // Use IPFS hash as URI
        return tokenId;
    }

    function transferArtOwnership(uint256 _tokenId, address _to) external {
        require(_exists(_tokenId), "Token does not exist.");
        require(msg.sender == ownerOf(_tokenId), "Not the owner of the token.");
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    function getArtOwner(uint256 _tokenId) external view returns (address) {
        require(_exists(_tokenId), "Token does not exist.");
        return ownerOf(_tokenId);
    }

    function getArtTokenUri(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return tokenURI(_tokenId);
    }

    // --- 4. Decentralized Governance & Voting ---

    function createGovernanceProposal(string memory _description, bytes memory _calldata, address _target) external onlyMember {
        governanceProposalCount.increment();
        uint256 proposalId = governanceProposalCount.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            calldata: _calldata,
            target: _target,
            state: ProposalState.Pending,
            upVotes: 0,
            downVotes: 0,
            submissionTimestamp: block.timestamp
        });
        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote) external onlyMember validGovernanceProposal(_proposalId) proposalInState(_proposalId, ProposalState.Pending, false) {
        require(block.timestamp <= governanceProposals[_proposalId].submissionTimestamp + governanceProposalVoteDuration, "Voting period has ended.");
        if (_vote) {
            governanceProposals[_proposalId].upVotes++;
        } else {
            governanceProposals[_proposalId].downVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);

        // Automatically transition to Active state if voting has started
        if (governanceProposals[_proposalId].state == ProposalState.Pending) {
            governanceProposals[_proposalId].state = ProposalState.Active;
        }
        _checkGovernanceProposalOutcome(_proposalId);
    }

    function _checkGovernanceProposalOutcome(uint256 _proposalId) internal {
        uint256 totalVotes = governanceProposals[_proposalId].upVotes + governanceProposals[_proposalId].downVotes;
        uint256 activeMembers = getMemberCount();

        if (activeMembers > 0 && (totalVotes * 100) / activeMembers >= votingQuorum) { // Quorum reached
            uint256 approvalPercentage = (governanceProposals[_proposalId].upVotes * 100) / totalVotes;
            if (approvalPercentage >= governanceProposalApprovalThreshold) {
                governanceProposals[_proposalId].state = ProposalState.Approved;
                emit GovernanceProposalExecuted(_proposalId, 0); // Token ID not relevant here, event for execution
            } else {
                governanceProposals[_proposalId].state = ProposalState.Rejected;
                emit GovernanceProposalRejected(_proposalId);
            }
        }
    }


    function executeGovernanceProposal(uint256 _proposalId) external onlyCurator validGovernanceProposal(_proposalId) proposalInState(_proposalId, ProposalState.Approved, false) {
        governanceProposals[_proposalId].state = ProposalState.Executed;
        (bool success, ) = governanceProposals[_proposalId].target.call(governanceProposals[_proposalId].calldata);
        require(success, "Governance proposal execution failed.");
        emit GovernanceProposalExecuted(_proposalId, 0); // Token ID not relevant here, event for execution
    }

    function getGovernanceProposalState(uint256 _proposalId) external view validGovernanceProposal(_proposalId) returns (ProposalState) {
        return governanceProposals[_proposalId].state;
    }

    function getGovernanceProposalDetails(uint256 _proposalId) external view validGovernanceProposal(_proposalId) returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }


    // --- 5. Treasury & Funding (Basic) ---

    function depositToTreasury() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function withdrawFromTreasury(address _to, uint256 _amount) external onlyCurator {
        payable(_to).transfer(_amount);
        emit TreasuryWithdrawal(_to, _amount, msg.sender);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Curator Management (Simple - could be expanded with governance) ---
    function addCurator(address _curator) external onlyOwner {
        for (uint256 i = 0; i < curators.length; i++) {
            require(curators[i] != _curator, "Curator already exists.");
        }
        curators.push(_curator);
    }

    function removeCurator(address _curator) external onlyOwner {
        require(curators.length > 1, "Cannot remove the last curator (owner)."); // Ensure at least one curator remains (owner)
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _curator) {
                // Remove curator from array
                for (uint j = i; j < curators.length - 1; j++) {
                    curators[j] = curators[j + 1];
                }
                curators.pop();
                return;
            }
        }
        revert("Curator not found.");
    }

    function getCurators() external view returns (address[] memory) {
        return curators;
    }

    // --- Fallback and Receive (Optional - for simple ETH reception) ---
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    fallback() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }
}
```