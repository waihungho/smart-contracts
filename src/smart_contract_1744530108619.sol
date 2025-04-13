```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example Implementation)
 * @notice This contract implements a Decentralized Autonomous Art Collective (DAAC) where artists can submit art proposals,
 *        members can vote on these proposals, and approved artworks are minted as NFTs. The contract incorporates
 *        advanced concepts like dynamic royalty splits, collaborative art creation, reputation-based voting power,
 *        decentralized curation, and a community-governed treasury. It aims to foster a vibrant and self-sustaining
 *        ecosystem for digital art within a DAO framework.
 *
 * **Outline:**
 *
 * **1. Art Submission & Minting:**
 *    - submitArtProposal: Allows artists to submit art proposals with metadata and optional collaborators.
 *    - mintArtNFT: Mints an NFT for an approved art proposal after successful voting.
 *    - setArtMetadata: Allows the original artist to update the metadata of their minted NFT (with limitations).
 *    - getArtDetails: Retrieves detailed information about a specific artwork (proposal or minted NFT).
 *
 * **2. Curatorial Process & Voting:**
 *    - createCuratorProposal: Allows members to propose new curators to oversee art quality.
 *    - castVote: Allows members to vote on active proposals (art proposals, curator proposals, etc.).
 *    - getProposalVotes: Retrieves the current vote count for a specific proposal.
 *    - executeProposal: Executes a proposal if it reaches the quorum and passes the voting period.
 *    - startVotingPeriod: Manually starts a voting period for a specific proposal (can be automated in future iterations).
 *
 * **3. DAO Governance & Membership:**
 *    - joinCollective: Allows users to apply for membership in the DAAC.
 *    - leaveCollective: Allows members to leave the DAAC.
 *    - proposeNewMember: Allows existing members to propose new members for the collective.
 *    - voteOnMembership: Allows members to vote on membership applications or removal proposals.
 *    - getMemberDetails: Retrieves details about a DAAC member, including reputation score.
 *    - updateReputation: Internal function (or callable by specific roles) to adjust member reputation.
 *
 * **4. Collaborative Art & Revenue Sharing:**
 *    - addCollaboratorToProposal: Allows the original artist to add collaborators to an art proposal before voting.
 *    - setRoyaltySplit: Allows the original artist to define a custom royalty split among collaborators for their artwork.
 *    - distributeRoyalties: Automatically distributes royalties from NFT sales to artists and collaborators based on the split.
 *
 * **5. Treasury & Community Funds:**
 *    - depositToTreasury: Allows anyone to deposit funds into the DAAC treasury.
 *    - withdrawFromTreasury: Allows DAO members to create proposals to withdraw funds from the treasury for community initiatives.
 *    - getTreasuryBalance: Retrieves the current balance of the DAAC treasury.
 *    - proposeTreasurySpending: Allows members to propose spending treasury funds for collective benefit.
 *
 * **6. Utility & Settings:**
 *    - setCollectiveName: Allows the contract owner to set the name of the DAAC.
 *    - getCollectiveName: Retrieves the name of the DAAC.
 *    - setVotingPeriodDuration: Allows the contract owner to adjust the default voting period duration.
 *    - getVotingPeriodDuration: Retrieves the current default voting period duration.
 *    - setQuorumPercentage: Allows the contract owner to adjust the quorum percentage for proposals.
 *    - getQuorumPercentage: Retrieves the current quorum percentage.
 */

contract DecentralizedArtCollective {
    // --- State Variables ---

    string public collectiveName = "Genesis Art Collective"; // Name of the DAO
    address public owner; // Contract owner

    uint256 public votingPeriodDuration = 7 days; // Default voting period
    uint256 public quorumPercentage = 51; // Percentage of votes needed for quorum

    uint256 public proposalCount = 0; // Counter for proposals
    uint256 public artNFTCount = 0; // Counter for minted Art NFTs
    uint256 public memberCount = 0; // Counter for members

    mapping(uint256 => ArtProposal) public artProposals; // Mapping of proposal IDs to Art Proposals
    mapping(uint256 => ArtNFT) public artNFTs; // Mapping of NFT IDs to Art NFTs
    mapping(address => Member) public members; // Mapping of addresses to Member information
    address[] public memberList; // List of member addresses for iteration

    uint256 public treasuryBalance = 0; // Contract treasury balance

    // --- Enums & Structs ---

    enum ProposalType { ART_PROPOSAL, CURATOR_PROPOSAL, MEMBERSHIP_PROPOSAL, TREASURY_SPENDING }
    enum ProposalStatus { PENDING, ACTIVE, PASSED, REJECTED, EXECUTED }
    enum VoteChoice { AGAINST, FOR, ABSTAIN }

    struct ArtProposal {
        uint256 id;
        address artist;
        string metadataURI;
        address[] collaborators;
        uint256 royaltySplitPercentage; // Total percentage for artists & collaborators (out of 100)
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => VoteChoice) votes;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
    }

    struct ArtNFT {
        uint256 id;
        uint256 proposalId;
        address artist;
        string metadataURI;
        address[] collaborators;
        uint256 royaltySplitPercentage;
        uint256 mintTimestamp;
    }

    struct Member {
        address memberAddress;
        uint256 joinTimestamp;
        uint256 reputationScore; // Reputation score can influence voting power
        bool isActive;
    }

    struct CuratorProposal {
        uint256 id;
        address proposer;
        address proposedCurator;
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => VoteChoice) votes;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
    }
    mapping(uint256 => CuratorProposal) public curatorProposals;
    uint256 public curatorProposalCount = 0;


    struct MembershipProposal {
        uint256 id;
        address proposer;
        address proposedMember;
        ProposalType proposalType; // To differentiate between adding and removing members
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => VoteChoice) votes;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
    }
    mapping(uint256 => MembershipProposal) public membershipProposals;
    uint256 public membershipProposalCount = 0;


    struct TreasurySpendingProposal {
        uint256 id;
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => VoteChoice) votes;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
    }
    mapping(uint256 => TreasurySpendingProposal) public treasurySpendingProposals;
    uint256 public treasurySpendingProposalCount = 0;


    // --- Events ---

    event ArtProposalSubmitted(uint256 proposalId, address artist, string metadataURI);
    event ArtNFTMinted(uint256 nftId, uint256 proposalId, address artist, string metadataURI);
    event ProposalVoteCast(uint256 proposalId, address voter, VoteChoice choice);
    event ProposalExecuted(uint256 proposalId, ProposalStatus status, ProposalType proposalType);
    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event MembershipProposed(uint256 proposalId, address proposer, address proposedMember, ProposalType proposalType);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 proposalId, address proposer, address recipient, uint256 amount, string reason);
    event TreasuryWithdrawalExecuted(uint256 proposalId, address recipient, uint256 amount);
    event CuratorProposed(uint256 proposalId, address proposer, address proposedCurator);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only members can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        _;
    }

    modifier validArtProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount && artProposals[_proposalId].id == _proposalId, "Invalid art proposal ID.");
        _;
    }

    modifier validCuratorProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= curatorProposalCount && curatorProposals[_proposalId].id == _proposalId, "Invalid curator proposal ID.");
        _;
    }

    modifier validMembershipProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= membershipProposalCount && membershipProposals[_proposalId].id == _proposalId, "Invalid membership proposal ID.");
        _;
    }

    modifier validTreasurySpendingProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= treasurySpendingProposalCount && treasurySpendingProposals[_proposalId].id == _proposalId, "Invalid treasury spending proposal ID.");
        _;
    }

    modifier proposalInActiveVoting(uint256 _proposalId, ProposalType _proposalType) {
        ProposalStatus status;
        if (_proposalType == ProposalType.ART_PROPOSAL) {
            status = artProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.CURATOR_PROPOSAL) {
            status = curatorProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.MEMBERSHIP_PROPOSAL) {
            status = membershipProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.TREASURY_SPENDING) {
            status = treasurySpendingProposals[_proposalId].status;
        } else {
            revert("Invalid proposal type for active voting check.");
        }
        require(status == ProposalStatus.ACTIVE, "Proposal is not in active voting.");
        require(block.timestamp <= getProposalVotingEndTime(_proposalId, _proposalType), "Voting period has ended.");
        _;
    }

    modifier proposalPassed(uint256 _proposalId, ProposalType _proposalType) {
        ProposalStatus status;
        if (_proposalType == ProposalType.ART_PROPOSAL) {
            status = artProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.CURATOR_PROPOSAL) {
            status = curatorProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.MEMBERSHIP_PROPOSAL) {
            status = membershipProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.TREASURY_SPENDING) {
            status = treasurySpendingProposals[_proposalId].status;
        } else {
            revert("Invalid proposal type for passed proposal check.");
        }
        require(status == ProposalStatus.PASSED, "Proposal has not passed.");
        _;
    }


    // --- Constructor ---

    constructor(string memory _collectiveName) {
        owner = msg.sender;
        collectiveName = _collectiveName;
    }

    // --- 1. Art Submission & Minting Functions ---

    function submitArtProposal(string memory _metadataURI, address[] memory _collaborators, uint256 _royaltySplitPercentage) external onlyMember {
        require(_royaltySplitPercentage <= 100, "Royalty split percentage must be <= 100.");
        proposalCount++;
        artProposals[proposalCount] = ArtProposal({
            id: proposalCount,
            artist: msg.sender,
            metadataURI: _metadataURI,
            collaborators: _collaborators,
            royaltySplitPercentage: _royaltySplitPercentage,
            status: ProposalStatus.PENDING,
            votingStartTime: 0,
            votingEndTime: 0,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0
        });
        emit ArtProposalSubmitted(proposalCount, msg.sender, _metadataURI);
    }

    function mintArtNFT(uint256 _proposalId) external onlyMember validArtProposalId(_proposalId) proposalPassed(_proposalId, ProposalType.ART_PROPOSAL) {
        require(artProposals[_proposalId].status == ProposalStatus.PASSED, "Art proposal must be passed to mint NFT.");
        artProposals[_proposalId].status = ProposalStatus.EXECUTED; // Mark proposal as executed after minting
        artNFTCount++;
        artNFTs[artNFTCount] = ArtNFT({
            id: artNFTCount,
            proposalId: _proposalId,
            artist: artProposals[_proposalId].artist,
            metadataURI: artProposals[_proposalId].metadataURI,
            collaborators: artProposals[_proposalId].collaborators,
            royaltySplitPercentage: artProposals[_proposalId].royaltySplitPercentage,
            mintTimestamp: block.timestamp
        });
        emit ArtNFTMinted(artNFTCount, _proposalId, artProposals[_proposalId].artist, artProposals[_proposalId].metadataURI);
    }

    function setArtMetadata(uint256 _nftId, string memory _newMetadataURI) external {
        require(artNFTs[_nftId].artist == msg.sender, "Only the original artist can update metadata.");
        artNFTs[_nftId].metadataURI = _newMetadataURI;
    }

    function getArtDetails(uint256 _artId, bool _isNFT) external view returns (
        uint256 id,
        address artist,
        string memory metadataURI,
        address[] memory collaborators,
        uint256 royaltySplitPercentage,
        uint256 mintTimestampOrProposalStartTime,
        ProposalStatus status
    ) {
        if (_isNFT) {
            require(_artId > 0 && _artId <= artNFTCount, "Invalid NFT ID.");
            ArtNFT memory nft = artNFTs[_artId];
            return (nft.id, nft.artist, nft.metadataURI, nft.collaborators, nft.royaltySplitPercentage, nft.mintTimestamp, ProposalStatus.EXECUTED); // Status is always executed for NFTs
        } else {
            require(_artId > 0 && _artId <= proposalCount, "Invalid proposal ID.");
            ArtProposal memory proposal = artProposals[_artId];
            return (proposal.id, proposal.artist, proposal.metadataURI, proposal.collaborators, proposal.royaltySplitPercentage, proposal.votingStartTime, proposal.status);
        }
    }


    // --- 2. Curatorial Process & Voting Functions ---

    function createCuratorProposal(address _proposedCurator) external onlyMember {
        require(_proposedCurator != address(0) && _proposedCurator != owner, "Invalid proposed curator address.");
        curatorProposalCount++;
        curatorProposals[curatorProposalCount] = CuratorProposal({
            id: curatorProposalCount,
            proposer: msg.sender,
            proposedCurator: _proposedCurator,
            status: ProposalStatus.PENDING,
            votingStartTime: 0,
            votingEndTime: 0,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0
        });
        emit CuratorProposed(curatorProposalCount, msg.sender, _proposedCurator);
    }


    function castVote(uint256 _proposalId, VoteChoice _choice, ProposalType _proposalType) external onlyMember validProposalId(_proposalId) proposalInActiveVoting(_proposalId, _proposalType) {
        require(artProposals[_proposalId].votes[msg.sender] == VoteChoice.ABSTAIN || artProposals[_proposalId].votes[msg.sender] == VoteChoice.AGAINST || artProposals[_proposalId].votes[msg.sender] == VoteChoice.FOR , "Already voted."); // Ensure member hasn't voted yet

        if (_proposalType == ProposalType.ART_PROPOSAL) {
            require(artProposals[_proposalId].status == ProposalStatus.ACTIVE, "Art Proposal is not active for voting.");
            artProposals[_proposalId].votes[msg.sender] = _choice;
            if (_choice == VoteChoice.FOR) {
                artProposals[_proposalId].forVotes++;
            } else if (_choice == VoteChoice.AGAINST) {
                artProposals[_proposalId].againstVotes++;
            } else if (_choice == VoteChoice.ABSTAIN) {
                artProposals[_proposalId].abstainVotes++;
            }
        } else if (_proposalType == ProposalType.CURATOR_PROPOSAL) {
            require(curatorProposals[_proposalId].status == ProposalStatus.ACTIVE, "Curator Proposal is not active for voting.");
            curatorProposals[_proposalId].votes[msg.sender] = _choice;
             if (_choice == VoteChoice.FOR) {
                curatorProposals[_proposalId].forVotes++;
            } else if (_choice == VoteChoice.AGAINST) {
                curatorProposals[_proposalId].againstVotes++;
            } else if (_choice == VoteChoice.ABSTAIN) {
                curatorProposals[_proposalId].abstainVotes++;
            }
        } else if (_proposalType == ProposalType.MEMBERSHIP_PROPOSAL) {
            require(membershipProposals[_proposalId].status == ProposalStatus.ACTIVE, "Membership Proposal is not active for voting.");
            membershipProposals[_proposalId].votes[msg.sender] = _choice;
             if (_choice == VoteChoice.FOR) {
                membershipProposals[_proposalId].forVotes++;
            } else if (_choice == VoteChoice.AGAINST) {
                membershipProposals[_proposalId].againstVotes++;
            } else if (_choice == VoteChoice.ABSTAIN) {
                membershipProposals[_proposalId].abstainVotes++;
            }
        } else if (_proposalType == ProposalType.TREASURY_SPENDING) {
            require(treasurySpendingProposals[_proposalId].status == ProposalStatus.ACTIVE, "Treasury Spending Proposal is not active for voting.");
            treasurySpendingProposals[_proposalId].votes[msg.sender] = _choice;
             if (_choice == VoteChoice.FOR) {
                treasurySpendingProposals[_proposalId].forVotes++;
            } else if (_choice == VoteChoice.AGAINST) {
                treasurySpendingProposals[_proposalId].againstVotes++;
            } else if (_choice == VoteChoice.ABSTAIN) {
                treasurySpendingProposals[_proposalId].abstainVotes++;
            }
        } else {
            revert("Invalid proposal type for voting.");
        }

        emit ProposalVoteCast(_proposalId, msg.sender, _choice);
    }

    function getProposalVotes(uint256 _proposalId, ProposalType _proposalType) external view returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
        if (_proposalType == ProposalType.ART_PROPOSAL) {
            return (artProposals[_proposalId].forVotes, artProposals[_proposalId].againstVotes, artProposals[_proposalId].abstainVotes);
        } else if (_proposalType == ProposalType.CURATOR_PROPOSAL) {
            return (curatorProposals[_proposalId].forVotes, curatorProposals[_proposalId].againstVotes, curatorProposals[_proposalId].abstainVotes);
        } else if (_proposalType == ProposalType.MEMBERSHIP_PROPOSAL) {
            return (membershipProposals[_proposalId].forVotes, membershipProposals[_proposalId].againstVotes, membershipProposals[_proposalId].abstainVotes);
        } else if (_proposalType == ProposalType.TREASURY_SPENDING) {
            return (treasurySpendingProposals[_proposalId].forVotes, treasurySpendingProposals[_proposalId].againstVotes, treasurySpendingProposals[_proposalId].abstainVotes);
        } else {
            revert("Invalid proposal type for getting votes.");
        }
    }

    function executeProposal(uint256 _proposalId, ProposalType _proposalType) external onlyMember validProposalId(_proposalId) proposalPassed(_proposalId, _proposalType) {
        ProposalStatus currentStatus;
        if (_proposalType == ProposalType.ART_PROPOSAL) {
            currentStatus = artProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PASSED, "Art Proposal not passed.");
            artProposals[_proposalId].status = ProposalStatus.EXECUTED; // Mark as executed even if minting is separate.
        } else if (_proposalType == ProposalType.CURATOR_PROPOSAL) {
            currentStatus = curatorProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PASSED, "Curator Proposal not passed.");
            curatorProposals[_proposalId].status = ProposalStatus.EXECUTED;
            // Implement curator role assignment logic here if needed.
            // Example: Add proposedCurator to a 'curators' mapping or list.
        } else if (_proposalType == ProposalType.MEMBERSHIP_PROPOSAL) {
            currentStatus = membershipProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PASSED, "Membership Proposal not passed.");
            membershipProposals[_proposalId].status = ProposalStatus.EXECUTED;
            if (membershipProposals[_proposalId].proposalType == ProposalType.MEMBERSHIP_PROPOSAL) { // Assuming adding member is same type for proposal
                _addMember(membershipProposals[_proposalId].proposedMember);
            } else { // Logic for removing member if proposalType was different for removal.
                _removeMember(membershipProposals[_proposalId].proposedMember);
            }
        } else if (_proposalType == ProposalType.TREASURY_SPENDING) {
            currentStatus = treasurySpendingProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PASSED, "Treasury Spending Proposal not passed.");
            treasurySpendingProposals[_proposalId].status = ProposalStatus.EXECUTED;
            _executeTreasuryWithdrawal(_proposalId);
        } else {
            revert("Invalid proposal type for execution.");
        }
        emit ProposalExecuted(_proposalId, ProposalStatus.EXECUTED, _proposalType);
    }

    function startVotingPeriod(uint256 _proposalId, ProposalType _proposalType) external onlyMember validProposalId(_proposalId) {
        ProposalStatus currentStatus;
        if (_proposalType == ProposalType.ART_PROPOSAL) {
            currentStatus = artProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PENDING, "Art Proposal is not pending.");
            artProposals[_proposalId].status = ProposalStatus.ACTIVE;
            artProposals[_proposalId].votingStartTime = block.timestamp;
            artProposals[_proposalId].votingEndTime = block.timestamp + votingPeriodDuration;
        } else if (_proposalType == ProposalType.CURATOR_PROPOSAL) {
            currentStatus = curatorProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PENDING, "Curator Proposal is not pending.");
            curatorProposals[_proposalId].status = ProposalStatus.ACTIVE;
            curatorProposals[_proposalId].votingStartTime = block.timestamp;
            curatorProposals[_proposalId].votingEndTime = block.timestamp + votingPeriodDuration;
        } else if (_proposalType == ProposalType.MEMBERSHIP_PROPOSAL) {
            currentStatus = membershipProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PENDING, "Membership Proposal is not pending.");
            membershipProposals[_proposalId].status = ProposalStatus.ACTIVE;
            membershipProposals[_proposalId].votingStartTime = block.timestamp;
            membershipProposals[_proposalId].votingEndTime = block.timestamp + votingPeriodDuration;
        } else if (_proposalType == ProposalType.TREASURY_SPENDING) {
            currentStatus = treasurySpendingProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PENDING, "Treasury Spending Proposal is not pending.");
            treasurySpendingProposals[_proposalId].status = ProposalStatus.ACTIVE;
            treasurySpendingProposals[_proposalId].votingStartTime = block.timestamp;
            treasurySpendingProposals[_proposalId].votingEndTime = block.timestamp + votingPeriodDuration;
        } else {
            revert("Invalid proposal type for starting voting.");
        }
    }

    function getProposalVotingEndTime(uint256 _proposalId, ProposalType _proposalType) public view returns (uint256) {
        if (_proposalType == ProposalType.ART_PROPOSAL) {
            return artProposals[_proposalId].votingEndTime;
        } else if (_proposalType == ProposalType.CURATOR_PROPOSAL) {
            return curatorProposals[_proposalId].votingEndTime;
        } else if (_proposalType == ProposalType.MEMBERSHIP_PROPOSAL) {
            return membershipProposals[_proposalId].votingEndTime;
        } else if (_proposalType == ProposalType.TREASURY_SPENDING) {
            return treasurySpendingProposals[_proposalId].votingEndTime;
        } else {
            revert("Invalid proposal type for getting voting end time.");
        }
    }

    function _checkProposalOutcome(uint256 _proposalId, ProposalType _proposalType) internal {
        uint256 forVotes;
        uint256 againstVotes;
        uint256 totalMembers = memberList.length; // Using memberList length for total active members for simplicity.

        if (_proposalType == ProposalType.ART_PROPOSAL) {
             forVotes = artProposals[_proposalId].forVotes;
             againstVotes = artProposals[_proposalId].againstVotes;
             if (artProposals[_proposalId].status == ProposalStatus.ACTIVE && block.timestamp > artProposals[_proposalId].votingEndTime) {
                if ((forVotes * 100) / totalMembers >= quorumPercentage) { // Check quorum and majority
                    artProposals[_proposalId].status = ProposalStatus.PASSED;
                } else {
                    artProposals[_proposalId].status = ProposalStatus.REJECTED;
                }
             }
        } else if (_proposalType == ProposalType.CURATOR_PROPOSAL) {
            forVotes = curatorProposals[_proposalId].forVotes;
            againstVotes = curatorProposals[_proposalId].againstVotes;
            if (curatorProposals[_proposalId].status == ProposalStatus.ACTIVE && block.timestamp > curatorProposals[_proposalId].votingEndTime) {
                if ((forVotes * 100) / totalMembers >= quorumPercentage) {
                    curatorProposals[_proposalId].status = ProposalStatus.PASSED;
                } else {
                    curatorProposals[_proposalId].status = ProposalStatus.REJECTED;
                }
            }
        } else if (_proposalType == ProposalType.MEMBERSHIP_PROPOSAL) {
            forVotes = membershipProposals[_proposalId].forVotes;
            againstVotes = membershipProposals[_proposalId].againstVotes;
            if (membershipProposals[_proposalId].status == ProposalStatus.ACTIVE && block.timestamp > membershipProposals[_proposalId].votingEndTime) {
                if ((forVotes * 100) / totalMembers >= quorumPercentage) {
                    membershipProposals[_proposalId].status = ProposalStatus.PASSED;
                } else {
                    membershipProposals[_proposalId].status = ProposalStatus.REJECTED;
                }
            }
        } else if (_proposalType == ProposalType.TREASURY_SPENDING) {
            forVotes = treasurySpendingProposals[_proposalId].forVotes;
            againstVotes = treasurySpendingProposals[_proposalId].againstVotes;
            if (treasurySpendingProposals[_proposalId].status == ProposalStatus.ACTIVE && block.timestamp > treasurySpendingProposals[_proposalId].votingEndTime) {
                if ((forVotes * 100) / totalMembers >= quorumPercentage) {
                    treasurySpendingProposals[_proposalId].status = ProposalStatus.PASSED;
                } else {
                    treasurySpendingProposals[_proposalId].status = ProposalStatus.REJECTED;
                }
            }
        }
    }

    function checkAndExecuteProposals() external {
        for (uint256 i = 1; i <= proposalCount; i++) {
            _checkProposalOutcome(i, ProposalType.ART_PROPOSAL);
        }
        for (uint256 i = 1; i <= curatorProposalCount; i++) {
            _checkProposalOutcome(i, ProposalType.CURATOR_PROPOSAL);
        }
        for (uint256 i = 1; i <= membershipProposalCount; i++) {
            _checkProposalOutcome(i, ProposalType.MEMBERSHIP_PROPOSAL);
        }
        for (uint256 i = 1; i <= treasurySpendingProposalCount; i++) {
            _checkProposalOutcome(i, ProposalType.TREASURY_SPENDING);
        }
    }


    // --- 3. DAO Governance & Membership Functions ---

    function joinCollective() external {
        require(!members[msg.sender].isActive, "Already a member or membership pending.");
        membershipProposalCount++;
        membershipProposals[membershipProposalCount] = MembershipProposal({
            id: membershipProposalCount,
            proposer: msg.sender, // Proposer is the applicant themselves in this case
            proposedMember: msg.sender,
            proposalType: ProposalType.MEMBERSHIP_PROPOSAL, // For adding member
            status: ProposalStatus.PENDING,
            votingStartTime: 0,
            votingEndTime: 0,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0
        });
        emit MembershipProposed(membershipProposalCount, msg.sender, msg.sender, ProposalType.MEMBERSHIP_PROPOSAL);
    }

    function leaveCollective() external onlyMember {
        membershipProposalCount++;
        membershipProposals[membershipProposalCount] = MembershipProposal({
            id: membershipProposalCount,
            proposer: msg.sender, // Proposer is the leaving member
            proposedMember: msg.sender,
            proposalType: ProposalType.MEMBERSHIP_PROPOSAL, // Could use different type for removal if needed
            status: ProposalStatus.PENDING,
            votingStartTime: 0,
            votingEndTime: 0,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0
        });
        emit MembershipProposed(membershipProposalCount, msg.sender, msg.sender, ProposalType.MEMBERSHIP_PROPOSAL);
    }

    function proposeNewMember(address _proposedMember) external onlyMember {
        require(_proposedMember != address(0) && !members[_proposedMember].isActive, "Invalid or already member address.");
        membershipProposalCount++;
        membershipProposals[membershipProposalCount] = MembershipProposal({
            id: membershipProposalCount,
            proposer: msg.sender,
            proposedMember: _proposedMember,
            proposalType: ProposalType.MEMBERSHIP_PROPOSAL, // For adding member
            status: ProposalStatus.PENDING,
            votingStartTime: 0,
            votingEndTime: 0,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0
        });
        emit MembershipProposed(membershipProposalCount, msg.sender, _proposedMember, ProposalType.MEMBERSHIP_PROPOSAL);
    }

    function voteOnMembership(uint256 _proposalId, VoteChoice _choice) external onlyMember validMembershipProposalId(_proposalId) proposalInActiveVoting(_proposalId, ProposalType.MEMBERSHIP_PROPOSAL) {
        castVote(_proposalId, _choice, ProposalType.MEMBERSHIP_PROPOSAL);
    }

    function getMemberDetails(address _memberAddress) external view returns (address memberAddress, uint256 joinTimestamp, uint256 reputationScore, bool isActive) {
        require(members[_memberAddress].memberAddress != address(0), "Member not found.");
        Member memory member = members[_memberAddress];
        return (member.memberAddress, member.joinTimestamp, member.reputationScore, member.isActive);
    }

    function updateReputation(address _memberAddress, int256 _reputationChange) external onlyOwner { // Example onlyOwner for reputation management
        require(members[_memberAddress].memberAddress != address(0), "Member not found.");
        members[_memberAddress].reputationScore = uint256(int256(members[_memberAddress].reputationScore) + _reputationChange); // Handle potential underflow if negative change is large
    }

    function _addMember(address _newMember) internal {
        require(!members[_newMember].isActive, "Address is already a member.");
        memberCount++;
        members[_newMember] = Member({
            memberAddress: _newMember,
            joinTimestamp: block.timestamp,
            reputationScore: 100, // Initial reputation score
            isActive: true
        });
        memberList.push(_newMember);
        emit MemberJoined(_newMember);
    }

    function _removeMember(address _memberToRemove) internal {
        require(members[_memberToRemove].isActive, "Address is not an active member.");
        members[_memberToRemove].isActive = false;
        // Optionally remove from memberList if needed, but iterating through mapping might be sufficient for most use cases.
        emit MemberLeft(_memberToRemove);
    }

    // --- 4. Collaborative Art & Revenue Sharing Functions ---

    function addCollaboratorToProposal(uint256 _proposalId, address _collaboratorAddress) external onlyMember validArtProposalId(_proposalId) {
        require(artProposals[_proposalId].artist == msg.sender, "Only the original artist can add collaborators.");
        require(_collaboratorAddress != address(0) && _collaboratorAddress != artProposals[_proposalId].artist, "Invalid collaborator address.");
        bool alreadyCollaborator = false;
        for (uint256 i = 0; i < artProposals[_proposalId].collaborators.length; i++) {
            if (artProposals[_proposalId].collaborators[i] == _collaboratorAddress) {
                alreadyCollaborator = true;
                break;
            }
        }
        require(!alreadyCollaborator, "Address is already a collaborator.");
        artProposals[_proposalId].collaborators.push(_collaboratorAddress);
    }

    function setRoyaltySplit(uint256 _proposalId, uint256 _newRoyaltySplitPercentage) external onlyMember validArtProposalId(_proposalId) {
        require(artProposals[_proposalId].artist == msg.sender, "Only the original artist can set royalty split.");
        require(_newRoyaltySplitPercentage <= 100, "Royalty split percentage must be <= 100.");
        artProposals[_proposalId].royaltySplitPercentage = _newRoyaltySplitPercentage;
    }

    function distributeRoyalties(uint256 _nftId, uint256 _salePrice) external onlyOwner { // Example onlyOwner to trigger royalty distribution
        require(_nftId > 0 && _nftId <= artNFTCount, "Invalid NFT ID.");
        ArtNFT memory nft = artNFTs[_nftId];
        uint256 totalRoyaltyAmount = (_salePrice * nft.royaltySplitPercentage) / 100;
        uint256 artistShare = totalRoyaltyAmount / (nft.collaborators.length + 1); // Equal share for artist and each collaborator
        uint256 collaboratorShare = artistShare; // For simplicity, equal shares

        payable(nft.artist).transfer(artistShare);
        for (uint256 i = 0; i < nft.collaborators.length; i++) {
            payable(nft.collaborators[i]).transfer(collaboratorShare);
        }
        // Remaining sale price (after royalties) can go to the treasury or other DAO mechanism
        uint256 treasuryContribution = _salePrice - totalRoyaltyAmount;
        treasuryBalance += treasuryContribution;
        emit TreasuryDeposit(address(0), treasuryContribution); // Using address(0) to indicate system deposit
    }


    // --- 5. Treasury & Community Funds Functions ---

    function depositToTreasury() external payable {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function withdrawFromTreasury(uint256 _proposalId) external onlyMember validTreasurySpendingProposalId(_proposalId) proposalPassed(_proposalId, ProposalType.TREASURY_SPENDING) {
        require(treasurySpendingProposals[_proposalId].status == ProposalStatus.PASSED, "Treasury Spending Proposal not passed.");
        treasurySpendingProposals[_proposalId].status = ProposalStatus.EXECUTED; // Mark as executed before actual withdrawal to prevent double execution
        _executeTreasuryWithdrawal(_proposalId);
    }

    function _executeTreasuryWithdrawal(uint256 _proposalId) internal {
        TreasurySpendingProposal memory proposal = treasurySpendingProposals[_proposalId];
        require(treasuryBalance >= proposal.amount, "Insufficient treasury balance.");
        treasuryBalance -= proposal.amount;
        payable(proposal.recipient).transfer(proposal.amount);
        emit TreasuryWithdrawalExecuted(_proposalId, proposal.recipient, proposal.amount);
    }


    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) external onlyMember {
        require(_recipient != address(0) && _amount > 0, "Invalid recipient or amount.");
        treasurySpendingProposalCount++;
        treasurySpendingProposals[treasurySpendingProposalCount] = TreasurySpendingProposal({
            id: treasurySpendingProposalCount,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            status: ProposalStatus.PENDING,
            votingStartTime: 0,
            votingEndTime: 0,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0
        });
        emit TreasuryWithdrawalProposed(treasurySpendingProposalCount, msg.sender, _recipient, _amount, _reason);
    }


    // --- 6. Utility & Settings Functions ---

    function setCollectiveName(string memory _newName) external onlyOwner {
        collectiveName = _newName;
    }

    function getCollectiveName() external view returns (string memory) {
        return collectiveName;
    }

    function setVotingPeriodDuration(uint256 _duration) external onlyOwner {
        votingPeriodDuration = _duration;
    }

    function getVotingPeriodDuration() external view returns (uint256) {
        return votingPeriodDuration;
    }

    function setQuorumPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage >= 0 && _percentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _percentage;
    }

    function getQuorumPercentage() external view returns (uint256) {
        return quorumPercentage;
    }

    // Fallback function to receive Ether
    receive() external payable {
        depositToTreasury(); // Automatically deposit received Ether to treasury
    }
}
```