```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Gemini AI (Conceptual Contract - Not Audited)
 * @notice A smart contract for a Decentralized Autonomous Art Collective (DAAC) that allows members to collaboratively create, curate, and manage digital art, utilizing advanced concepts like generative art integration, on-chain reputation, dynamic royalties, and decentralized exhibition management.

 * **Contract Outline and Function Summary:**

 * **1. Membership & Governance:**
 *    - `joinCollective()`: Allows users to become members by staking a specific token amount and undergoing a potential voting process.
 *    - `leaveCollective()`: Allows members to leave the collective and unstake their tokens, subject to potential cooldown periods.
 *    - `proposeNewMember()`: Members can propose new members to join the collective, subject to voting.
 *    - `voteOnMembershipProposal()`: Members can vote on pending membership proposals.
 *    - `getMemberStake()`: Allows members to view their staked tokens and current membership status.
 *    - `getCollectiveMemberCount()`: Returns the current number of members in the collective.

 * **2. Art Creation & Generative Art Integration:**
 *    - `submitArtProposal()`: Members can submit art proposals including a description, artist attribution, and potentially generative art parameters.
 *    - `voteOnArtProposal()`: Members can vote on submitted art proposals.
 *    - `executeArtProposal()`: If an art proposal passes, it triggers the minting of an NFT representing the artwork, potentially incorporating generative art logic.
 *    - `generateArtOnChain()`: (Internal/Abstract) Placeholder for on-chain generative art logic (can be extended with libraries or oracles).
 *    - `setGenerativeArtContract()`: Owner can set an external contract address for more complex generative art logic (if used).

 * **3. Curation & Exhibition Management:**
 *    - `proposeExhibition()`: Members can propose new art exhibitions with a theme, duration, and artwork selection criteria.
 *    - `voteOnExhibitionProposal()`: Members can vote on pending exhibition proposals.
 *    - `executeExhibitionProposal()`: If an exhibition proposal passes, it sets up a new exhibition.
 *    - `addArtworkToExhibition()`: Members can propose adding approved artworks to the current exhibition.
 *    - `voteOnExhibitionArtwork()`: Members can vote on adding specific artworks to an exhibition.
 *    - `removeArtworkFromExhibition()`: Members can propose removing artworks from the current exhibition.
 *    - `getCurrentExhibitionDetails()`: Returns details of the currently active exhibition, including artworks and theme.

 * **4. Royalties & Revenue Distribution:**
 *    - `setDynamicRoyaltySplit()`: Owner can set a dynamic royalty split mechanism (e.g., based on member reputation or contribution).
 *    - `distributeRoyalties()`: (Internal) Function to distribute royalties from secondary sales of collective artworks based on the dynamic split.
 *    - `collectPrimarySaleRevenue()`: Function to collect revenue from primary sales (if implemented) and distribute it to the treasury.
 *    - `withdrawTreasuryFunds()`: Members can propose and vote on proposals to withdraw funds from the collective treasury.

 * **5. Reputation & Contribution Tracking:**
 *    - `recordContribution()`: (Internal/Admin) Function to record member contributions (e.g., art proposals, votes, participation in discussions - could be linked to off-chain systems).
 *    - `getMemberReputation()`: Returns a member's reputation score based on recorded contributions.
 *    - `updateReputationWeights()`: Owner can adjust the weights of different contributions on the reputation score.

 * **6. Utility & Information:**
 *    - `getContractName()`: Returns the name of the smart contract.
 *    - `getVersion()`: Returns the contract version.
 *    - `getMembershipTokenAddress()`: Returns the address of the membership token (if applicable).
 *    - `getVotingQuorum()`: Returns the current voting quorum percentage.
 *    - `setVotingQuorum()`: Owner can set the voting quorum percentage for proposals.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedAutonomousArtCollective is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    string public contractName = "Decentralized Autonomous Art Collective";
    string public version = "1.0.0";

    // --- Membership & Governance ---
    IERC20 public membershipToken; // Token required for membership
    uint256 public membershipStakeAmount; // Amount of tokens required to stake
    mapping(address => uint256) public memberStake; // Staked amount for each member
    mapping(address => bool) public isMember;
    address[] public collectiveMembers;
    uint256 public membershipCooldownPeriod = 7 days; // Cooldown period for leaving
    mapping(address => uint256) public lastMembershipLeaveTime;

    struct MembershipProposal {
        address proposer;
        address proposedMember;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        uint256 proposalStartTime;
    }
    mapping(uint256 => MembershipProposal) public membershipProposals;
    Counters.Counter private membershipProposalCounter;
    uint256 public membershipProposalVotingDuration = 3 days;

    // --- Art Creation & Generative Art ---
    struct ArtProposal {
        address proposer;
        string description;
        string artistAttribution;
        string generativeArtParameters; // Placeholder for parameters, could be more complex struct
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isApproved;
        uint256 proposalStartTime;
    }
    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private artProposalCounter;
    uint256 public artProposalVotingDuration = 5 days;
    Counters.Counter private artworkIdCounter;
    mapping(uint256 => string) public artworkMetadataURIs; // Artwork ID to Metadata URI
    address public generativeArtContract; // Optional external generative art contract

    // --- Curation & Exhibition Management ---
    struct ExhibitionProposal {
        address proposer;
        string title;
        string description;
        uint256 duration; // in days
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isApproved;
        uint256 proposalStartTime;
    }
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    Counters.Counter private exhibitionProposalCounter;
    uint256 public exhibitionProposalVotingDuration = 4 days;
    uint256 public currentExhibitionId;
    mapping(uint256 => uint256[]) public exhibitionArtworks; // Exhibition ID to array of artwork IDs
    string public currentExhibitionTitle;
    string public currentExhibitionDescription;
    uint256 public currentExhibitionEndTime;

    // --- Royalties & Revenue Distribution ---
    uint256 public primarySaleFeePercentage = 5; // 5% primary sale fee
    uint256 public secondarySaleRoyaltyPercentage = 7; // 7% secondary sale royalty
    address public treasuryAddress; // Address to hold collective funds
    mapping(address => uint256) public memberReputation; // Member reputation scores

    struct SpendingProposal {
        address proposer;
        address recipient;
        uint256 amount;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isApproved;
        uint256 proposalStartTime;
    }
    mapping(uint256 => SpendingProposal) public spendingProposals;
    Counters.Counter private spendingProposalCounter;
    uint256 public spendingProposalVotingDuration = 5 days;

    // --- Voting & Quorum ---
    uint256 public votingQuorumPercentage = 50; // Default 50% quorum

    // --- Events ---
    event MemberJoined(address member);
    event MemberLeft(address member);
    event MembershipProposalCreated(uint256 proposalId, address proposer, address proposedMember);
    event MembershipProposalVoted(uint256 proposalId, address voter, bool vote);
    event MembershipProposalExecuted(uint256 proposalId, address newMember, bool approved);
    event ArtProposalCreated(uint256 proposalId, address proposer, string description);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalExecuted(uint256 proposalId, uint256 artworkId, bool approved);
    event ArtworkMinted(uint256 artworkId, address minter, string metadataURI);
    event ExhibitionProposalCreated(uint256 proposalId, address proposer, string title);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionProposalExecuted(uint256 proposalId, uint256 exhibitionId, bool approved);
    event ArtworkAddedToExhibition(uint256 exhibitionId, uint256 artworkId);
    event ArtworkRemovedFromExhibition(uint256 exhibitionId, uint256 artworkId);
    event ExhibitionStarted(uint256 exhibitionId, string title);
    event RoyaltiesDistributed(uint256 artworkId, address[] recipients, uint256[] amounts);
    event SpendingProposalCreated(uint256 proposalId, address proposer, address recipient, uint256 amount);
    event SpendingProposalVoted(uint256 proposalId, address voter, bool vote);
    event SpendingProposalExecuted(uint256 proposalId, address recipient, uint256 amount, bool approved);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event ReputationUpdated(address member, uint256 newReputation);
    event VotingQuorumUpdated(uint256 newQuorumPercentage);


    constructor(
        string memory _name,
        string memory _symbol,
        address _membershipTokenAddress,
        uint256 _membershipStakeAmount,
        address _treasuryAddress
    ) ERC721(_name, _symbol) {
        membershipToken = IERC20(_membershipTokenAddress);
        membershipStakeAmount = _membershipStakeAmount;
        treasuryAddress = _treasuryAddress;
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, _msgSender()); // Optional: Set up admin role if needed for more complex admin control
    }

    modifier onlyMember() {
        require(isMember[_msgSender()], "Not a member of the collective");
        _;
    }

    modifier validProposal(uint256 proposalId, ProposalType proposalType) {
        if (proposalType == ProposalType.Membership) {
            require(membershipProposals[proposalId].isActive, "Membership proposal is not active");
        } else if (proposalType == ProposalType.Art) {
            require(artProposals[proposalId].isActive, "Art proposal is not active");
        } else if (proposalType == ProposalType.Exhibition) {
            require(exhibitionProposals[proposalId].isActive, "Exhibition proposal is not active");
        } else if (proposalType == ProposalType.Spending) {
            require(spendingProposals[proposalId].isActive, "Spending proposal is not active");
        } else {
            revert("Invalid proposal type");
        }
        _;
    }

    modifier votingPeriodActive(uint256 proposalId, ProposalType proposalType) {
        uint256 endTime;
        if (proposalType == ProposalType.Membership) {
            endTime = membershipProposals[proposalId].proposalStartTime + membershipProposalVotingDuration;
        } else if (proposalType == ProposalType.Art) {
            endTime = artProposals[proposalId].proposalStartTime + artProposalVotingDuration;
        } else if (proposalType == ProposalType.Exhibition) {
            endTime = exhibitionProposals[proposalId].proposalStartTime + exhibitionProposalVotingDuration;
        } else if (proposalType == ProposalType.Spending) {
            endTime = spendingProposals[proposalId].proposalStartTime + spendingProposalVotingDuration;
        } else {
            revert("Invalid proposal type");
        }
        require(block.timestamp <= endTime, "Voting period has ended");
        _;
    }

    enum ProposalType { Membership, Art, Exhibition, Spending }

    // --- Membership & Governance Functions ---

    function joinCollective() external nonReentrant {
        require(!isMember[_msgSender()], "Already a member");
        require(membershipToken.allowance(_msgSender(), address(this)) >= membershipStakeAmount, "Approve token transfer first");
        require(membershipToken.transferFrom(_msgSender(), address(this), membershipStakeAmount), "Token transfer failed");

        memberStake[_msgSender()] = membershipStakeAmount;
        isMember[_msgSender()] = true;
        collectiveMembers.push(_msgSender());
        emit MemberJoined(_msgSender());
    }

    function leaveCollective() external onlyMember nonReentrant {
        require(block.timestamp >= lastMembershipLeaveTime[_msgSender()] + membershipCooldownPeriod, "Cooldown period not over yet");
        uint256 stakeToReturn = memberStake[_msgSender()];
        delete memberStake[_msgSender()];
        isMember[_msgSender()] = false;
        lastMembershipLeaveTime[_msgSender()] = block.timestamp;

        // Remove member from collectiveMembers array (inefficient for large arrays, consider alternative if scalability is critical)
        for (uint256 i = 0; i < collectiveMembers.length; i++) {
            if (collectiveMembers[i] == _msgSender()) {
                collectiveMembers[i] = collectiveMembers[collectiveMembers.length - 1];
                collectiveMembers.pop();
                break;
            }
        }

        require(membershipToken.transfer(_msgSender(), stakeToReturn), "Token return failed");
        emit MemberLeft(_msgSender());
    }

    function proposeNewMember(address _proposedMember) external onlyMember nonReentrant {
        require(!isMember[_proposedMember], "Proposed address is already a member");

        membershipProposalCounter.increment();
        uint256 proposalId = membershipProposalCounter.current();
        membershipProposals[proposalId] = MembershipProposal({
            proposer: _msgSender(),
            proposedMember: _proposedMember,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            proposalStartTime: block.timestamp
        });
        emit MembershipProposalCreated(proposalId, _msgSender(), _proposedMember);
    }

    function voteOnMembershipProposal(uint256 _proposalId, bool _vote) external onlyMember nonReentrant validProposal(_proposalId, ProposalType.Membership) votingPeriodActive(_proposalId, ProposalType.Membership) {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        require(proposal.proposer != _msgSender(), "Proposer cannot vote"); // Proposer can vote in some DAOs, decide based on preference

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit MembershipProposalVoted(_proposalId, _msgSender(), _vote);
    }

    function executeMembershipProposal(uint256 _proposalId) external onlyMember nonReentrant validProposal(_proposalId, ProposalType.Membership) votingPeriodActive(_proposalId, ProposalType.Membership) {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        require(proposal.proposer == _msgSender() || owner() == _msgSender(), "Only proposer or owner can execute proposal"); // Or DAO governance can control execution

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (collectiveMembers.length * votingQuorumPercentage) / 100; // Calculate quorum based on current members

        bool approved = (proposal.votesFor > proposal.votesAgainst) && (totalVotes >= quorum);

        proposal.isActive = false;
        proposal.isApproved = approved;

        if (approved) {
            address newMember = proposal.proposedMember;
            isMember[newMember] = true;
            collectiveMembers.push(newMember);
            emit MembershipProposalExecuted(_proposalId, newMember, true);
            emit MemberJoined(newMember);
        } else {
            emit MembershipProposalExecuted(_proposalId, proposal.proposedMember, false);
        }
    }

    function getMemberStake(address _member) external view returns (uint256) {
        return memberStake[_member];
    }

    function getCollectiveMemberCount() external view returns (uint256) {
        return collectiveMembers.length;
    }


    // --- Art Creation & Generative Art Functions ---

    function submitArtProposal(string memory _description, string memory _artistAttribution, string memory _generativeArtParameters, string memory _metadataURI) external onlyMember nonReentrant {
        artProposalCounter.increment();
        uint256 proposalId = artProposalCounter.current();
        artProposals[proposalId] = ArtProposal({
            proposer: _msgSender(),
            description: _description,
            artistAttribution: _artistAttribution,
            generativeArtParameters: _generativeArtParameters,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isApproved: false,
            proposalStartTime: block.timestamp
        });
        artworkMetadataURIs[proposalId] = _metadataURI; // Storing metadata URI temporarily with proposal ID
        emit ArtProposalCreated(proposalId, _msgSender(), _description);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember nonReentrant validProposal(_proposalId, ProposalType.Art) votingPeriodActive(_proposalId, ProposalType.Art) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.proposer != _msgSender(), "Proposer cannot vote");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, _msgSender(), _vote);
    }

    function executeArtProposal(uint256 _proposalId) external onlyMember nonReentrant validProposal(_proposalId, ProposalType.Art) votingPeriodActive(_proposalId, ProposalType.Art) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.proposer == _msgSender() || owner() == _msgSender(), "Only proposer or owner can execute proposal");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (collectiveMembers.length * votingQuorumPercentage) / 100;

        bool approved = (proposal.votesFor > proposal.votesAgainst) && (totalVotes >= quorum);

        proposal.isActive = false;
        proposal.isApproved = approved;

        if (approved) {
            artworkIdCounter.increment();
            uint256 artworkId = artworkIdCounter.current();
            string memory metadataURI = artworkMetadataURIs[_proposalId]; // Retrieve stored metadata URI
            _mint(address(this), artworkId); // Mint to the contract itself initially, then potentially transfer or manage ownership
            _setTokenURI(artworkId, metadataURI);
            emit ArtworkMinted(artworkId, address(this), metadataURI); // Minted by contract, ownership needs further management
            emit ArtProposalExecuted(_proposalId, artworkId, true);
            delete artworkMetadataURIs[_proposalId]; // Clean up temporary storage
        } else {
            emit ArtProposalExecuted(_proposalId, 0, false);
            delete artworkMetadataURIs[_proposalId]; // Clean up even if rejected
        }
    }

    // Placeholder for on-chain generative art logic. Can be expanded with libraries or oracles.
    function generateArtOnChain(string memory _parameters) internal pure returns (string memory metadataURI) {
        // Placeholder - In a real implementation, this would contain complex logic
        // to generate art based on parameters.
        // Could integrate with libraries like Solgraph or external oracles for randomness.
        // For now, return a simple placeholder URI.
        return string(abi.encodePacked("ipfs://placeholder-generative-art-", _parameters));
    }

    function setGenerativeArtContract(address _contractAddress) external onlyOwner {
        generativeArtContract = _contractAddress;
    }


    // --- Curation & Exhibition Management Functions ---

    function proposeExhibition(string memory _title, string memory _description, uint256 _durationDays) external onlyMember nonReentrant {
        exhibitionProposalCounter.increment();
        uint256 proposalId = exhibitionProposalCounter.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            proposer: _msgSender(),
            title: _title,
            description: _description,
            duration: _durationDays,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isApproved: false,
            proposalStartTime: block.timestamp
        });
        emit ExhibitionProposalCreated(proposalId, _msgSender(), _title);
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) external onlyMember nonReentrant validProposal(_proposalId, ProposalType.Exhibition) votingPeriodActive(_proposalId, ProposalType.Exhibition) {
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        require(proposal.proposer != _msgSender(), "Proposer cannot vote");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ExhibitionProposalVoted(_proposalId, _msgSender(), _vote);
    }

    function executeExhibitionProposal(uint256 _proposalId) external onlyOwner nonReentrant validProposal(_proposalId, ProposalType.Exhibition) votingPeriodActive(_proposalId, ProposalType.Exhibition) { // Owner executes exhibition for now, can be DAO controlled
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (collectiveMembers.length * votingQuorumPercentage) / 100;

        bool approved = (proposal.votesFor > proposal.votesAgainst) && (totalVotes >= quorum);

        proposal.isActive = false;
        proposal.isApproved = approved;

        if (approved) {
            currentExhibitionId = _proposalId;
            currentExhibitionTitle = proposal.title;
            currentExhibitionDescription = proposal.description;
            currentExhibitionEndTime = block.timestamp + proposal.duration * 1 days;
            exhibitionArtworks[currentExhibitionId] = new uint256[](0); // Initialize empty artwork array for new exhibition
            emit ExhibitionProposalExecuted(_proposalId, currentExhibitionId, true);
            emit ExhibitionStarted(currentExhibitionId, currentExhibitionTitle);
        } else {
            emit ExhibitionProposalExecuted(_proposalId, 0, false);
        }
    }

    function addArtworkToExhibition(uint256 _artworkId) external onlyMember nonReentrant {
        require(currentExhibitionId != 0, "No active exhibition");
        // Additional checks can be added, like artwork ownership or approval status
        exhibitionArtworks[currentExhibitionId].push(_artworkId);
        emit ArtworkAddedToExhibition(currentExhibitionId, _artworkId);
    }

    function removeArtworkFromExhibition(uint256 _artworkId) external onlyMember nonReentrant {
        require(currentExhibitionId != 0, "No active exhibition");
        uint256[] storage artworks = exhibitionArtworks[currentExhibitionId];
        for (uint256 i = 0; i < artworks.length; i++) {
            if (artworks[i] == _artworkId) {
                artworks[i] = artworks[artworks.length - 1];
                artworks.pop();
                emit ArtworkRemovedFromExhibition(currentExhibitionId, _artworkId);
                return;
            }
        }
        revert("Artwork not found in current exhibition");
    }

    function getCurrentExhibitionDetails() external view returns (uint256 exhibitionId, string memory title, string memory description, uint256 endTime, uint256[] memory artworkIds) {
        return (currentExhibitionId, currentExhibitionTitle, currentExhibitionDescription, currentExhibitionEndTime, exhibitionArtworks[currentExhibitionId]);
    }


    // --- Royalties & Revenue Distribution Functions ---

    function setDynamicRoyaltySplit() external onlyOwner {
        // Example: Future implementation could dynamically adjust royalty splits
        // based on member reputation or contribution to the collective.
        // This is a placeholder for a more advanced feature.
        // For now, using a fixed royalty split.
    }

    function distributeRoyalties(uint256 _artworkId) internal {
        // Example: Simple fixed royalty distribution to all members for now.
        // In a dynamic system, this would be based on reputation/contribution.
        uint256 royaltyAmount = 100; // Example Royalty amount, needs to be calculated from actual sale price
        uint256 membersCount = collectiveMembers.length;
        if (membersCount > 0) {
            uint256 amountPerMember = royaltyAmount.div(membersCount);
            address[] memory recipients = new address[](membersCount);
            uint256[] memory amounts = new uint256[](membersCount);

            for (uint256 i = 0; i < membersCount; i++) {
                recipients[i] = collectiveMembers[i];
                amounts[i] = amountPerMember;
                // In a real system, transfer tokens/ETH to each member here.
                // For this example, just emitting the event.
                // (Consider gas optimization for large member counts)
            }
            emit RoyaltiesDistributed(_artworkId, recipients, amounts);
        }
    }

    // Example function to handle primary sales (if the contract was selling directly)
    function collectPrimarySaleRevenue() external payable {
        uint256 feeAmount = msg.value.mul(primarySaleFeePercentage).div(100);
        uint256 netRevenue = msg.value.sub(feeAmount);
        payable(treasuryAddress).transfer(netRevenue);
        emit TreasuryDeposit(_msgSender(), netRevenue); // Event for deposit to treasury
        // Handle fee distribution if needed (e.g., to owner or specific fee recipients)
    }

    function proposeWithdrawTreasuryFunds(address _recipient, uint256 _amount, string memory _description) external onlyMember nonReentrant {
        spendingProposalCounter.increment();
        uint256 proposalId = spendingProposalCounter.current();
        spendingProposals[proposalId] = SpendingProposal({
            proposer: _msgSender(),
            recipient: _recipient,
            amount: _amount,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isApproved: false,
            proposalStartTime: block.timestamp
        });
        emit SpendingProposalCreated(proposalId, _msgSender(), _recipient, _amount);
    }

    function voteOnSpendingProposal(uint256 _proposalId, bool _vote) external onlyMember nonReentrant validProposal(_proposalId, ProposalType.Spending) votingPeriodActive(_proposalId, ProposalType.Spending) {
        SpendingProposal storage proposal = spendingProposals[_proposalId];
        require(proposal.proposer != _msgSender(), "Proposer cannot vote");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit SpendingProposalVoted(_proposalId, _msgSender(), _vote);
    }

    function executeSpendingProposal(uint256 _proposalId) external onlyOwner nonReentrant validProposal(_proposalId, ProposalType.Spending) votingPeriodActive(_proposalId, ProposalType.Spending) { // Owner executes spending, can be DAO controlled
        SpendingProposal storage proposal = spendingProposals[_proposalId];

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (collectiveMembers.length * votingQuorumPercentage) / 100;

        bool approved = (proposal.votesFor > proposal.votesAgainst) && (totalVotes >= quorum);

        proposal.isActive = false;
        proposal.isApproved = approved;

        if (approved) {
            uint256 amount = proposal.amount;
            address recipient = proposal.recipient;
            payable(recipient).transfer(amount);
            emit SpendingProposalExecuted(_proposalId, recipient, amount, true);
            emit TreasuryWithdrawal(recipient, amount);
        } else {
            emit SpendingProposalExecuted(_proposalId, proposal.recipient, proposal.amount, false);
        }
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance; // Or check balance of treasuryAddress if it's a separate contract
    }


    // --- Reputation & Contribution Tracking Functions ---

    function recordContribution(address _member, uint256 _contributionPoints) external onlyOwner {
        memberReputation[_member] = memberReputation[_member].add(_contributionPoints);
        emit ReputationUpdated(_member, memberReputation[_member]);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    function updateReputationWeights() external onlyOwner {
        // Placeholder for adjusting weights of different contributions in reputation calculation.
        // Could be based on different actions: art proposals, votes, etc.
    }


    // --- Utility & Information Functions ---

    function getContractName() external view returns (string memory) {
        return contractName;
    }

    function getVersion() external view returns (string memory) {
        return version;
    }

    function getMembershipTokenAddress() external view returns (address) {
        return address(membershipToken);
    }

    function getVotingQuorum() external view returns (uint256) {
        return votingQuorumPercentage;
    }

    function setVotingQuorum(uint256 _quorumPercentage) external onlyOwner {
        require(_quorumPercentage <= 100, "Quorum percentage must be <= 100");
        votingQuorumPercentage = _quorumPercentage;
        emit VotingQuorumUpdated(_quorumPercentage);
    }

    // --- ERC721 Overrides for Royalty Support (Example for EIP-2981) ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == 0x2a55205a || // EIP-2981 interface ID
               super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        // Simple example: Fixed royalty receiver (contract owner) and percentage
        return (owner(), (_salePrice * secondarySaleRoyaltyPercentage) / 100);
    }

    // Function to handle secondary sales and trigger royalty distribution (example, needs integration with marketplace or sale mechanism)
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override returns (bytes4) {
        // Example: Trigger royalty distribution on secondary sale.
        // This is a very basic example, actual integration depends on marketplace mechanisms.
        distributeRoyalties(tokenId);
        return this.onERC721Received.selector;
    }

    receive() external payable {
        emit TreasuryDeposit(_msgSender(), msg.value); // Allow direct deposits to treasury
    }
}
```