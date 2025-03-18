```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, allowing artists to submit proposals,
 *      community members to vote on them, and accepted artworks to be minted as NFTs.
 *      This contract incorporates advanced concepts like dynamic voting periods, reputation-based voting power,
 *      layered curation, and evolving NFT metadata, aiming for a creative and engaging art ecosystem.
 *
 * Function Outline:
 * -----------------
 * **Core Art Proposal & Voting:**
 * 1. submitArtProposal(string _title, string _description, string _ipfsHash): Allows artists to submit art proposals.
 * 2. getArtProposalDetails(uint256 _proposalId): Retrieves details of a specific art proposal.
 * 3. getArtProposalStatus(uint256 _proposalId): Checks the current status of an art proposal (Pending, Active, Approved, Rejected).
 * 4. startArtProposalVoting(uint256 _proposalId): Starts the voting process for a specific art proposal (admin/curator role).
 * 5. voteOnArtProposal(uint256 _proposalId, bool _vote): Allows community members to vote on art proposals, voting power based on reputation.
 * 6. endArtProposalVoting(uint256 _proposalId): Ends the voting process for an art proposal and determines the outcome (admin/curator role).
 * 7. getProposalVoteCount(uint256 _proposalId): Returns the current vote counts (for and against) for a proposal.
 * 8. getProposalVotingDeadline(uint256 _proposalId): Returns the voting deadline for a proposal.
 * 9. mintArtNFT(uint256 _proposalId): Mints an NFT for an approved art proposal (admin/curator role, only after proposal approval).
 * 10. getArtNFTMetadata(uint256 _nftId): Retrieves metadata URI for a minted art NFT.
 * 11. getTotalArtProposals(): Returns the total number of art proposals submitted.
 * 12. getActiveArtProposals(): Returns a list of IDs of currently active art proposals (in voting phase).
 * 13. getApprovedArtProposals(): Returns a list of IDs of approved art proposals.
 * 14. getRejectedArtProposals(): Returns a list of IDs of rejected art proposals.
 *
 * **Reputation & Community Features:**
 * 15. contributeToCollective(string _contributionDetails): Allows members to contribute to the collective and potentially gain reputation.
 * 16. getMemberReputation(address _member): Returns the reputation score of a community member. (Simple example, can be more complex)
 * 17. delegateVotingPower(address _delegatee): Allows members to delegate their voting power to another member.
 * 18. revokeVotingPowerDelegation(): Allows members to revoke their voting power delegation.
 * 19. proposeReputationAdjustment(address _member, int256 _reputationChange, string _justification): Curator role to propose reputation changes for members.
 * 20. voteOnReputationAdjustment(uint256 _adjustmentProposalId, bool _vote): Community voting on reputation adjustment proposals.
 * 21. executeReputationAdjustment(uint256 _adjustmentProposalId): Executes approved reputation adjustments (admin/curator role).
 * 22. getReputationAdjustmentProposalDetails(uint256 _adjustmentProposalId): View details of a reputation adjustment proposal.
 *
 * **Collective Management & Governance (Basic example - can be expanded significantly):**
 * 23. setCurator(address _curator, bool _isCurator): Allows admin to set or remove curator roles.
 * 24. isCurator(address _account): Checks if an address is a curator.
 * 25. setVotingDuration(uint256 _durationInSeconds): Allows admin to set the default voting duration for proposals.
 * 26. getVotingDuration(): Returns the current default voting duration.
 *
 * **Events:**
 * - ArtProposalSubmitted(uint256 proposalId, address artist, string title)
 * - ArtProposalVotingStarted(uint256 proposalId)
 * - ArtProposalVoted(uint256 proposalId, address voter, bool vote)
 * - ArtProposalApproved(uint256 proposalId)
 * - ArtProposalRejected(uint256 proposalId)
 * - ArtNFTMinted(uint256 nftId, uint256 proposalId, address minter)
 * - ContributionMade(address contributor, string details)
 * - ReputationAdjusted(address member, int256 newReputation, string justification)
 * - VotingPowerDelegated(address delegator, address delegatee)
 * - VotingPowerDelegationRevoked(address delegator)
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DecentralizedArtCollective is Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // --- Structs and Enums ---

    enum ProposalStatus { Pending, Active, Approved, Rejected }

    struct ArtProposal {
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string ipfsHash; // IPFS hash for artwork metadata or image
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct ReputationAdjustmentProposal {
        uint256 proposalId;
        address member;
        int256 reputationChange;
        string justification;
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
    }


    // --- State Variables ---

    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private _artProposalCounter;

    mapping(uint256 => ReputationAdjustmentProposal) public reputationAdjustmentProposals;
    Counters.Counter private _reputationAdjustmentProposalCounter;

    mapping(address => uint256) public memberReputation; // Member address to reputation score
    mapping(address => address) public votingPowerDelegation; // Delegator -> Delegatee

    mapping(uint256 => address) public mintedNFTToProposal; // NFT ID to Proposal ID
    Counters.Counter private _nftIdCounter;
    mapping(uint256 => string) public nftMetadataURIs; // NFT ID to metadata URI

    mapping(address => bool) public curators; // Address to curator status

    uint256 public votingDuration = 7 days; // Default voting duration

    uint256 public reputationThresholdForVoting = 1; // Minimum reputation to vote


    // --- Events ---

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVotingStarted(uint256 proposalId);
    event ArtProposalVoted(uint256 proposalId, uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId);
    event ArtProposalRejected(uint256 proposalId);
    event ArtNFTMinted(uint256 nftId, uint256 proposalId, address minter);
    event ContributionMade(address contributor, string details);
    event ReputationAdjusted(address member, int256 newReputation, string justification);
    event ReputationAdjustmentProposed(uint256 proposalId, address member, int256 reputationChange);
    event ReputationAdjustmentVotingStarted(uint256 proposalId);
    event ReputationAdjustmentVoted(uint256 proposalId, address voter, bool vote);
    event ReputationAdjustmentApproved(uint256 proposalId);
    event ReputationAdjustmentRejected(uint256 proposalId);
    event VotingPowerDelegated(address delegator, address delegatee);
    event VotingPowerDelegationRevoked(address delegator);


    // --- Modifiers ---

    modifier onlyCurator() {
        require(curators[_msgSender()] || _msgSender() == owner(), "Only curators or owner can perform this action.");
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(artProposals[_proposalId].status == ProposalStatus.Active, "Proposal voting is not active.");
        require(block.timestamp <= artProposals[_proposalId].votingEndTime, "Voting period has ended.");
        _;
    }

    modifier onlyPendingProposal(uint256 _proposalId) {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not in pending status.");
        _;
    }

    modifier onlyApprovedProposal(uint256 _proposalId) {
        require(artProposals[_proposalId].status == ProposalStatus.Approved, "Proposal is not approved.");
        _;
    }

    modifier reputationRequirement(address _voter) {
        require(getEffectiveReputation(_voter) >= reputationThresholdForVoting, "Insufficient reputation to vote.");
        _;
    }


    // --- Helper Functions ---

    function getEffectiveReputation(address _member) public view returns (uint256) {
        address delegatee = votingPowerDelegation[_member];
        if (delegatee != address(0)) {
            return memberReputation[delegatee]; // Delegated power goes to delegatee's reputation
        }
        return memberReputation[_member];
    }


    // --- Core Art Proposal & Voting Functions ---

    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) public {
        uint256 proposalId = _artProposalCounter.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            artist: _msgSender(),
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            status: ProposalStatus.Pending,
            votingStartTime: 0,
            votingEndTime: 0,
            votesFor: 0,
            votesAgainst: 0
        });
        _artProposalCounter.increment();
        emit ArtProposalSubmitted(proposalId, _msgSender(), _title);
    }

    function getArtProposalDetails(uint256 _proposalId) public view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getArtProposalStatus(uint256 _proposalId) public view returns (ProposalStatus) {
        return artProposals[_proposalId].status;
    }

    function startArtProposalVoting(uint256 _proposalId) public onlyCurator onlyPendingProposal(_proposalId) {
        artProposals[_proposalId].status = ProposalStatus.Active;
        artProposals[_proposalId].votingStartTime = block.timestamp;
        artProposals[_proposalId].votingEndTime = block.timestamp + votingDuration;
        emit ArtProposalVotingStarted(_proposalId);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) public reputationRequirement(_msgSender()) onlyActiveProposal(_proposalId) {
        if (_vote) {
            artProposals[_proposalId].votesFor++;
        } else {
            artProposals[_proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, _proposalId, _msgSender(), _vote);
    }

    function endArtProposalVoting(uint256 _proposalId) public onlyCurator onlyActiveProposal(_proposalId) {
        require(block.timestamp > artProposals[_proposalId].votingEndTime, "Voting period has not ended yet.");

        if (artProposals[_proposalId].votesFor > artProposals[_proposalId].votesAgainst) {
            artProposals[_proposalId].status = ProposalStatus.Approved;
            emit ArtProposalApproved(_proposalId);
        } else {
            artProposals[_proposalId].status = ProposalStatus.Rejected;
            emit ArtProposalRejected(_proposalId);
        }
    }

    function getProposalVoteCount(uint256 _proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        return (artProposals[_proposalId].votesFor, artProposals[_proposalId].votesAgainst);
    }

    function getProposalVotingDeadline(uint256 _proposalId) public view returns (uint256) {
        return artProposals[_proposalId].votingEndTime;
    }

    function mintArtNFT(uint256 _proposalId, string memory _metadataURI) public onlyCurator onlyApprovedProposal(_proposalId) {
        uint256 nftId = _nftIdCounter.current();
        mintedNFTToProposal[nftId] = _proposalId;
        nftMetadataURIs[nftId] = _metadataURI; // Store metadata URI
        _nftIdCounter.increment();
        emit ArtNFTMinted(nftId, _proposalId, _msgSender());
    }

    function getArtNFTMetadata(uint256 _nftId) public view returns (string memory) {
        return nftMetadataURIs[_nftId];
    }

    function getTotalArtProposals() public view returns (uint256) {
        return _artProposalCounter.current();
    }

    function getActiveArtProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposals = new uint256[](_artProposalCounter.current()); // Max size, will trim
        uint256 count = 0;
        for (uint256 i = 0; i < _artProposalCounter.current(); i++) {
            if (artProposals[i].status == ProposalStatus.Active) {
                activeProposals[count] = i;
                count++;
            }
        }
        // Trim the array to the actual number of active proposals
        assembly {
            mstore(activeProposals, count)
        }
        return activeProposals;
    }

    function getApprovedArtProposals() public view returns (uint256[] memory) {
        uint256[] memory approvedProposals = new uint256[](_artProposalCounter.current());
        uint256 count = 0;
        for (uint256 i = 0; i < _artProposalCounter.current(); i++) {
            if (artProposals[i].status == ProposalStatus.Approved) {
                approvedProposals[count] = i;
                count++;
            }
        }
        assembly {
            mstore(approvedProposals, count)
        }
        return approvedProposals;
    }

    function getRejectedArtProposals() public view returns (uint256[] memory) {
        uint256[] memory rejectedProposals = new uint256[](_artProposalCounter.current());
        uint256 count = 0;
        for (uint256 i = 0; i < _artProposalCounter.current(); i++) {
            if (artProposals[i].status == ProposalStatus.Rejected) {
                rejectedProposals[count] = i;
                count++;
            }
        }
        assembly {
            mstore(rejectedProposals, count)
        }
        return rejectedProposals;
    }


    // --- Reputation & Community Features ---

    function contributeToCollective(string memory _contributionDetails) public {
        // Simple example: increase reputation by 1 for every contribution
        memberReputation[_msgSender()] += 1;
        emit ContributionMade(_msgSender(), _contributionDetails);
    }

    function getMemberReputation(address _member) public view returns (uint256) {
        return memberReputation[_member];
    }

    function delegateVotingPower(address _delegatee) public reputationRequirement(_msgSender()) {
        require(_delegatee != address(0) && _delegatee != _msgSender(), "Invalid delegatee address.");
        votingPowerDelegation[_msgSender()] = _delegatee;
        emit VotingPowerDelegated(_msgSender(), _delegatee);
    }

    function revokeVotingPowerDelegation() public {
        delete votingPowerDelegation[_msgSender()];
        emit VotingPowerDelegationRevoked(_msgSender());
    }

    function proposeReputationAdjustment(address _member, int256 _reputationChange, string memory _justification) public onlyCurator {
        require(_member != address(0), "Invalid member address.");
        uint256 proposalId = _reputationAdjustmentProposalCounter.current();
        reputationAdjustmentProposals[proposalId] = ReputationAdjustmentProposal({
            proposalId: proposalId,
            member: _member,
            reputationChange: _reputationChange,
            justification: _justification,
            status: ProposalStatus.Pending,
            votingStartTime: 0,
            votingEndTime: 0,
            votesFor: 0,
            votesAgainst: 0
        });
        _reputationAdjustmentProposalCounter.increment();
        emit ReputationAdjustmentProposed(proposalId, _member, _reputationChange);
    }

    function startReputationAdjustmentVoting(uint256 _proposalId) public onlyCurator {
        require(reputationAdjustmentProposals[_proposalId].status == ProposalStatus.Pending, "Reputation adjustment proposal is not pending.");
        reputationAdjustmentProposals[_proposalId].status = ProposalStatus.Active;
        reputationAdjustmentProposals[_proposalId].votingStartTime = block.timestamp;
        reputationAdjustmentProposals[_proposalId].votingEndTime = block.timestamp + votingDuration;
        emit ReputationAdjustmentVotingStarted(_proposalId);
    }

    function voteOnReputationAdjustment(uint256 _proposalId, bool _vote) public reputationRequirement(_msgSender()) {
        require(reputationAdjustmentProposals[_proposalId].status == ProposalStatus.Active, "Reputation adjustment proposal voting is not active.");
        require(block.timestamp <= reputationAdjustmentProposals[_proposalId].votingEndTime, "Reputation adjustment voting period has ended.");

        if (_vote) {
            reputationAdjustmentProposals[_proposalId].votesFor++;
        } else {
            reputationAdjustmentProposals[_proposalId].votesAgainst++;
        }
        emit ReputationAdjustmentVoted(_proposalId, _msgSender(), _vote);
    }

    function endReputationAdjustmentVoting(uint256 _proposalId) public onlyCurator {
        require(reputationAdjustmentProposals[_proposalId].status == ProposalStatus.Active, "Reputation adjustment proposal voting is not active.");
        require(block.timestamp > reputationAdjustmentProposals[_proposalId].votingEndTime, "Reputation adjustment voting period has not ended yet.");

        if (reputationAdjustmentProposals[_proposalId].votesFor > reputationAdjustmentProposals[_proposalId].votesAgainst) {
            reputationAdjustmentProposals[_proposalId].status = ProposalStatus.Approved;
            emit ReputationAdjustmentApproved(_proposalId);
        } else {
            reputationAdjustmentProposals[_proposalId].status = ProposalStatus.Rejected;
            emit ReputationAdjustmentRejected(_proposalId);
        }
    }

    function executeReputationAdjustment(uint256 _adjustmentProposalId) public onlyCurator {
        require(reputationAdjustmentProposals[_adjustmentProposalId].status == ProposalStatus.Approved, "Reputation adjustment proposal is not approved.");
        address memberToAdjust = reputationAdjustmentProposals[_adjustmentProposalId].member;
        int256 reputationChange = reputationAdjustmentProposals[_adjustmentProposalId].reputationChange;

        // Safe math considerations are important in real-world scenarios, but for simplicity:
        memberReputation[memberToAdjust] = uint256(int256(memberReputation[memberToAdjust]) + reputationChange); // Cast to int256 for subtraction

        emit ReputationAdjusted(memberToAdjust, int256(memberReputation[memberToAdjust]), reputationAdjustmentProposals[_adjustmentProposalId].justification);
    }

    function getReputationAdjustmentProposalDetails(uint256 _adjustmentProposalId) public view returns (ReputationAdjustmentProposal memory) {
        return reputationAdjustmentProposals[_adjustmentProposalId];
    }


    // --- Collective Management & Governance Functions ---

    function setCurator(address _curator, bool _isCurator) public onlyOwner {
        curators[_curator] = _isCurator;
    }

    function isCurator(address _account) public view returns (bool) {
        return curators[_account];
    }

    function setVotingDuration(uint256 _durationInSeconds) public onlyOwner {
        votingDuration = _durationInSeconds;
    }

    function getVotingDuration() public view returns (uint256) {
        return votingDuration;
    }
}
```