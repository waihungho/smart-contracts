```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Not for Production Use)
 * @dev A smart contract for a decentralized art collective, enabling members to submit, vote on, curate, and benefit from digital art.
 *
 * **Outline and Function Summary:**
 *
 * **Membership & Governance:**
 * 1. `joinCollective()`: Allows users to join the art collective by paying a membership fee.
 * 2. `leaveCollective()`: Allows members to leave the collective and potentially withdraw funds.
 * 3. `depositMembershipFee()`: Allows members to deposit additional funds to their membership balance.
 * 4. `withdrawMembershipFee()`: Allows members to withdraw a portion of their membership balance (governed by rules).
 * 5. `createGovernanceProposal(string _description, bytes _payload)`: Allows members to create governance proposals for collective decisions.
 * 6. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows members to vote on active governance proposals.
 * 7. `executeProposal(uint256 _proposalId)`: Executes a governance proposal if it reaches quorum and approval.
 * 8. `setVotingDuration(uint256 _duration)`: Governance function to set the voting duration for proposals.
 * 9. `setQuorum(uint256 _quorumPercentage)`: Governance function to set the quorum percentage for proposals.
 *
 * **Art Submission & Curation:**
 * 10. `submitArtProposal(string _title, string _description, string _ipfsHash)`: Allows members to submit art proposals with metadata and IPFS hash.
 * 11. `voteOnArtProposal(uint256 _proposalId, bool _approve)`: Allows members to vote on art proposals for inclusion in the collective's gallery.
 * 12. `finalizeArtProposal(uint256 _proposalId)`: Finalizes an art proposal if it receives enough approvals, minting an NFT for the art.
 * 13. `rejectArtProposal(uint256 _proposalId)`: Rejects an art proposal that does not receive enough approvals.
 * 14. `getArtProposalVotes(uint256 _proposalId)`: Returns the approval and rejection votes for a specific art proposal.
 *
 * **NFT Management & Marketplace:**
 * 15. `mintArtNFT(uint256 _proposalId)`: (Internal) Mints an NFT for an approved art proposal.
 * 16. `listArtForSale(uint256 _tokenId, uint256 _price)`: Allows the collective to list an NFT from its gallery for sale on an internal marketplace.
 * 17. `buyArtNFT(uint256 _tokenId)`: Allows members to buy NFTs listed on the internal marketplace.
 * 18. `withdrawArtistRevenue(uint256 _tokenId)`: Allows the original artist to withdraw their share of revenue from NFT sales.
 * 19. `distributeCollectiveRevenue(uint256 _tokenId)`: Distributes a portion of NFT sale revenue to the collective's treasury.
 * 20. `setMarketplaceFee(uint256 _feePercentage)`: Governance function to set the marketplace fee percentage.
 *
 * **Utility & Information:**
 * 21. `getMemberCount()`: Returns the current number of members in the collective.
 * 22. `getArtCollectionSize()`: Returns the number of NFTs in the collective's art gallery.
 * 23. `getProposalDetails(uint256 _proposalId)`: Returns detailed information about a specific proposal.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    uint256 public membershipFee = 0.1 ether; // Initial membership fee
    uint256 public marketplaceFeePercentage = 5; // 5% marketplace fee
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposals

    mapping(address => bool) public isMember; // Track collective members
    mapping(address => uint256) public membershipBalance; // Track member balances
    Counters.Counter private memberCount;

    struct ArtProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isApproved;
        bool isExecuted;
    }
    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private artProposalCounter;

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes payload; // To execute contract functions (advanced, use with caution)
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isApproved;
        bool isExecuted;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    Counters.Counter private governanceProposalCounter;

    Counters.Counter private artNFTCounter;
    mapping(uint256 => uint256) public artProposalToTokenId; // Mapping proposal ID to minted NFT token ID
    mapping(uint256 => uint256) public listedArtPrice; // Marketplace listing price for NFTs
    mapping(uint256 => address) public artTokenOriginalArtist; // Track original artist for revenue sharing

    // --- Events ---

    event MemberJoined(address indexed member);
    event MemberLeft(address indexed member);
    event MembershipFeeDeposited(address indexed member, uint256 amount);
    event MembershipFeeWithdrawn(address indexed member, uint256 amount);

    event ArtProposalCreated(uint256 proposalId, address proposer, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool approve);
    event ArtProposalFinalized(uint256 proposalId, uint256 tokenId);
    event ArtProposalRejected(uint256 proposalId);

    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);

    event ArtListedForSale(uint256 tokenId, uint256 price);
    event ArtNFTSold(uint256 tokenId, address buyer, uint256 price);
    event ArtistRevenueWithdrawn(uint256 tokenId, address artist, uint256 amount);
    event CollectiveRevenueDistributed(uint256 tokenId, uint256 amount);

    // --- Modifiers ---

    modifier onlyMember() {
        require(isMember[msg.sender], "You are not a member of the collective.");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == owner(), "Only governance can call this function."); // For simplicity, Owner is governance
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0, "Invalid proposal ID.");
        _;
    }

    modifier activeProposal(uint256 _proposalId) {
        require(artProposals[_proposalId].isActive || governanceProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp < (artProposals[_proposalId].endTime != 0 ? artProposals[_proposalId].endTime : governanceProposals[_proposalId].endTime), "Voting period has ended.");
        _;
    }

    modifier notExecutedProposal(uint256 _proposalId) {
        require(!(artProposals[_proposalId].isExecuted || governanceProposals[_proposalId].isExecuted), "Proposal already executed.");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("Decentralized Art Collective", "DAC") Ownable() {}

    // --- Membership & Governance Functions ---

    function joinCollective() public payable {
        require(!isMember[msg.sender], "Already a member.");
        require(msg.value >= membershipFee, "Membership fee is required.");
        isMember[msg.sender] = true;
        membershipBalance[msg.sender] += msg.value;
        memberCount.increment();
        emit MemberJoined(msg.sender);
    }

    function leaveCollective() public onlyMember {
        isMember[msg.sender] = false;
        memberCount.decrement();
        emit MemberLeft(msg.sender);
        // Consider refunding a portion of membership fee based on governance rules
    }

    function depositMembershipFee() public payable onlyMember {
        require(msg.value > 0, "Deposit amount must be positive.");
        membershipBalance[msg.sender] += msg.value;
        emit MembershipFeeDeposited(msg.sender, msg.value);
    }

    function withdrawMembershipFee(uint256 _amount) public onlyMember {
        require(_amount > 0, "Withdrawal amount must be positive.");
        require(_amount <= membershipBalance[msg.sender], "Insufficient membership balance.");
        // Add governance rules for withdrawal limits/conditions if needed
        payable(msg.sender).transfer(_amount);
        membershipBalance[msg.sender] -= _amount;
        emit MembershipFeeWithdrawn(msg.sender, _amount);
    }

    function createGovernanceProposal(string memory _description, bytes memory _payload) public onlyMember {
        governanceProposalCounter.increment();
        uint256 proposalId = governanceProposalCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            payload: _payload,
            approvalVotes: 0,
            rejectionVotes: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            isActive: true,
            isApproved: false,
            isExecuted: false
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _description);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public onlyMember validProposal(_proposalId) activeProposal(_proposalId) notExecutedProposal(_proposalId) {
        if (artProposals[_proposalId].isActive) { // Art Proposal Voting
            require(!artProposals[_proposalId].isExecuted, "Art Proposal already finalized.");
            if (_support) {
                artProposals[_proposalId].approvalVotes++;
            } else {
                artProposals[_proposalId].rejectionVotes++;
            }
            emit ArtProposalVoted(_proposalId, msg.sender, _support);

        } else if (governanceProposals[_proposalId].isActive) { // Governance Proposal Voting
            require(!governanceProposals[_proposalId].isExecuted, "Governance Proposal already executed.");
            if (_support) {
                governanceProposals[_proposalId].approvalVotes++;
            } else {
                governanceProposals[_proposalId].rejectionVotes++;
            }
            emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
        } else {
            revert("Proposal not found or not active."); // Should not reach here if modifiers are correct
        }
    }

    function executeProposal(uint256 _proposalId) public onlyGovernance validProposal(_proposalId) notExecutedProposal(_proposalId) {
        if (artProposals[_proposalId].isActive) { // Execute Art Proposal Finalization
            require(block.timestamp >= artProposals[_proposalId].endTime, "Voting period not ended.");
            require(artProposals[_proposalId].approvalVotes > (memberCount.current() * quorumPercentage) / 100, "Art Proposal did not reach quorum.");
            require(!artProposals[_proposalId].isApproved, "Art Proposal already finalized.");

            artProposals[_proposalId].isActive = false;
            artProposals[_proposalId].isApproved = true;
            artProposals[_proposalId].isExecuted = true;
            mintArtNFT(_proposalId);
            emit ArtProposalFinalized(_proposalId, artProposalToTokenId[_proposalId]);

        } else if (governanceProposals[_proposalId].isActive) { // Execute Governance Proposal
            require(block.timestamp >= governanceProposals[_proposalId].endTime, "Voting period not ended.");
            require(governanceProposals[_proposalId].approvalVotes > (memberCount.current() * quorumPercentage) / 100, "Governance Proposal did not reach quorum.");
            require(!governanceProposals[_proposalId].isApproved, "Governance Proposal already executed.");

            governanceProposals[_proposalId].isActive = false;
            governanceProposals[_proposalId].isApproved = true;
            governanceProposals[_proposalId].isExecuted = true;

            // Example: Basic payload execution (very simplified and potentially risky - use with extreme caution and proper security checks)
            if (governanceProposals[_proposalId].payload.length > 0) {
                (bool success, ) = address(this).delegatecall(governanceProposals[_proposalId].payload);
                require(success, "Governance proposal payload execution failed.");
            }

            emit GovernanceProposalExecuted(_proposalId);
        } else {
            revert("Proposal not found or not active."); // Should not reach here if modifiers are correct
        }
    }

    function setVotingDuration(uint256 _duration) public onlyGovernance {
        votingDuration = _duration;
    }

    function setQuorum(uint256 _quorumPercentage) public onlyGovernance {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _quorumPercentage;
    }

    // --- Art Submission & Curation Functions ---

    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) public onlyMember {
        artProposalCounter.increment();
        uint256 proposalId = artProposalCounter.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            approvalVotes: 0,
            rejectionVotes: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            isActive: true,
            isApproved: false,
            isExecuted: false
        });
        emit ArtProposalCreated(proposalId, msg.sender, _title);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _approve) public onlyMember validProposal(_proposalId) activeProposal(_proposalId) notExecutedProposal(_proposalId) {
        require(artProposals[_proposalId].isActive, "Art Proposal is not active.");
        if (_approve) {
            artProposals[_proposalId].approvalVotes++;
        } else {
            artProposals[_proposalId].rejectionVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _approve);
    }


    function finalizeArtProposal(uint256 _proposalId) public onlyGovernance validProposal(_proposalId) notExecutedProposal(_proposalId) {
        require(artProposals[_proposalId].isActive, "Art Proposal is not active.");
        require(block.timestamp >= artProposals[_proposalId].endTime, "Voting period not ended.");
        require(artProposals[_proposalId].approvalVotes > (memberCount.current() * quorumPercentage) / 100, "Art Proposal did not reach quorum.");
        require(!artProposals[_proposalId].isApproved, "Art Proposal already finalized.");

        artProposals[_proposalId].isActive = false;
        artProposals[_proposalId].isApproved = true;
        artProposals[_proposalId].isExecuted = true;
        mintArtNFT(_proposalId);
        emit ArtProposalFinalized(_proposalId, artProposalToTokenId[_proposalId]);
    }

    function rejectArtProposal(uint256 _proposalId) public onlyGovernance validProposal(_proposalId) notExecutedProposal(_proposalId) {
        require(artProposals[_proposalId].isActive, "Art Proposal is not active.");
        require(block.timestamp >= artProposals[_proposalId].endTime, "Voting period not ended.");
        require(!artProposals[_proposalId].isApproved, "Art Proposal is not approved."); // To prevent double rejection
        require(!artProposals[_proposalId].isExecuted, "Art Proposal already executed.");

        artProposals[_proposalId].isActive = false;
        artProposals[_proposalId].isApproved = false; // Explicitly set to false even if it might be by default
        artProposals[_proposalId].isExecuted = true;
        emit ArtProposalRejected(_proposalId);
    }


    function getArtProposalVotes(uint256 _proposalId) public view validProposal(_proposalId) returns (uint256 approvals, uint256 rejections) {
        return (artProposals[_proposalId].approvalVotes, artProposals[_proposalId].rejectionVotes);
    }

    // --- NFT Management & Marketplace Functions ---

    function mintArtNFT(uint256 _proposalId) internal {
        require(artProposals[_proposalId].isApproved, "Art Proposal not approved.");
        require(artProposalToTokenId[_proposalId] == 0, "NFT already minted for this proposal.");

        artNFTCounter.increment();
        uint256 tokenId = artNFTCounter.current();
        _safeMint(address(this), tokenId); // Mint NFT to the contract itself, collective owns it
        artProposalToTokenId[_proposalId] = tokenId;
        artTokenOriginalArtist[tokenId] = artProposals[_proposalId].proposer; // Track original artist
        _setTokenURI(tokenId, artProposals[_proposalId].ipfsHash); // Set NFT metadata URI
    }

    function listArtForSale(uint256 _tokenId, uint256 _price) public onlyGovernance {
        require(ownerOf(_tokenId) == address(this), "Contract is not the owner of this NFT.");
        require(_price > 0, "Price must be positive.");
        listedArtPrice[_tokenId] = _price;
        emit ArtListedForSale(_tokenId, _price);
    }

    function buyArtNFT(uint256 _tokenId) public payable onlyMember {
        require(listedArtPrice[_tokenId] > 0, "Art is not listed for sale.");
        require(msg.value >= listedArtPrice[_tokenId], "Insufficient payment.");
        uint256 price = listedArtPrice[_tokenId];

        listedArtPrice[_tokenId] = 0; // Remove from marketplace listing

        // Calculate artist and collective share
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 artistShare = price - marketplaceFee;
        uint256 collectiveShare = marketplaceFee;

        // Transfer artist share (if original artist is still a member - can adjust logic)
        if (isMember[artTokenOriginalArtist[_tokenId]]) {
            payable(artTokenOriginalArtist[_tokenId]).transfer(artistShare);
            emit ArtistRevenueWithdrawn(_tokenId, artTokenOriginalArtist[_tokenId], artistShare);
        } else {
            // If artist is not a member, add share to collective treasury or handle differently
            collectiveShare += artistShare;
            // Consider notifying the artist about unclaimed revenue
        }

        // Transfer collective share to contract (treasury) - can implement treasury management later
        payable(address(this)).transfer(collectiveShare);
        emit CollectiveRevenueDistributed(_tokenId, collectiveShare);

        // Transfer NFT to buyer
        _transfer(address(this), msg.sender, _tokenId);
        emit ArtNFTSold(_tokenId, msg.sender, price);
    }

    function withdrawArtistRevenue(uint256 _tokenId) public onlyMember {
        require(msg.sender == artTokenOriginalArtist[_tokenId], "You are not the original artist.");
        // In a real scenario, track artist revenue balance and allow withdrawal based on that.
        // This example assumes revenue is directly transferred during purchase, so this function might be for claiming unclaimed revenue if artist was not member at purchase time.
        // For simplicity, this example function does nothing concrete in terms of withdrawal in this simplified revenue model.
        // In a more advanced version, you would have a balance for each artist and allow withdrawal from that balance.
        emit ArtistRevenueWithdrawn(_tokenId, msg.sender, 0); // Example event, adjust logic as needed.
    }

    function distributeCollectiveRevenue(uint256 _tokenId) public onlyGovernance {
        // In a real scenario, implement logic to distribute accumulated collective revenue to members
        // based on governance rules (e.g., proportional to membership duration, voting participation, etc.)
        emit CollectiveRevenueDistributed(_tokenId, 0); // Example event, adjust logic as needed.
    }

    function setMarketplaceFee(uint256 _feePercentage) public onlyGovernance {
        require(_feePercentage <= 100, "Marketplace fee percentage must be between 0 and 100.");
        marketplaceFeePercentage = _feePercentage;
    }


    // --- Utility & Information Functions ---

    function getMemberCount() public view returns (uint256) {
        return memberCount.current();
    }

    function getArtCollectionSize() public view returns (uint256) {
        return artNFTCounter.current();
    }

    function getProposalDetails(uint256 _proposalId) public view validProposal(_proposalId) returns (
        uint256 proposalId,
        address proposer,
        string memory description,
        uint256 approvalVotes,
        uint256 rejectionVotes,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        bool isApproved,
        bool isExecuted
    ) {
        if (artProposals[_proposalId].proposalId == _proposalId) {
            ArtProposal storage proposal = artProposals[_proposalId];
            return (
                proposal.proposalId,
                proposal.proposer,
                proposal.description,
                proposal.approvalVotes,
                proposal.rejectionVotes,
                proposal.startTime,
                proposal.endTime,
                proposal.isActive,
                proposal.isApproved,
                proposal.isExecuted
            );
        } else if (governanceProposals[_proposalId].proposalId == _proposalId) {
            GovernanceProposal storage proposal = governanceProposals[_proposalId];
            return (
                proposal.proposalId,
                proposal.proposer,
                proposal.description,
                proposal.approvalVotes,
                proposal.rejectionVotes,
                proposal.startTime,
                proposal.endTime,
                proposal.isActive,
                proposal.isApproved,
                proposal.isExecuted
            );
        } else {
            revert("Proposal not found");
        }
    }

    // --- Fallback and Receive (Optional) ---
    receive() external payable {}
    fallback() external payable {}
}
```