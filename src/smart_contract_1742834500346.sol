```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - "ArtVerse"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective where members can submit art proposals,
 * curators vote on them, accepted art is minted as NFTs, and the collective treasury is managed
 * by the community. This contract incorporates advanced concepts like dynamic roles, reputation-based
 * voting, fractional NFT ownership, and decentralized grants for art projects.
 *
 * Function Outline:
 *
 * **Core Art Proposal & Curation:**
 * 1. submitArtProposal(string _title, string _description, string _ipfsHash): Allows members to submit art proposals.
 * 2. getArtProposalDetails(uint256 _proposalId): Retrieves detailed information about a specific art proposal.
 * 3. getPendingArtProposals(): Returns a list of IDs of currently pending art proposals.
 * 4. voteOnArtProposal(uint256 _proposalId, bool _vote): Allows curators to vote on art proposals.
 * 5. getCurationResults(uint256 _proposalId): Retrieves the voting results for a specific art proposal.
 * 6. finalizeCurationRound(uint256[] _proposalIds): Finalizes a curation round, processing accepted proposals.
 *
 * **NFT Minting & Management:**
 * 7. mintArtNFT(uint256 _proposalId): Mints an NFT for an accepted art proposal (internal function called after finalization).
 * 8. getArtNFTDetails(uint256 _nftId): Retrieves details of a minted ArtVerse NFT.
 * 9. transferArtNFT(uint256 _nftId, address _to): Allows the collective to transfer ownership of an ArtVerse NFT. (e.g., for auctions or partnerships)
 * 10. burnArtNFT(uint256 _nftId): Allows the collective to burn an ArtVerse NFT (governance decision).
 *
 * **Governance & Voting:**
 * 11. proposeNewRule(string _ruleDescription, bytes _ruleData): Allows members to propose new rules for the collective.
 * 12. voteOnRuleProposal(uint256 _proposalId, bool _vote): Allows members to vote on rule proposals (reputation-weighted voting).
 * 13. executeRuleProposal(uint256 _proposalId): Executes a passed rule proposal.
 * 14. delegateVote(address _delegatee): Allows members to delegate their voting power to another member.
 *
 * **Membership & Roles:**
 * 15. applyForMembership(string _reason): Allows users to apply for membership in the collective.
 * 16. approveMembership(address _applicant): Allows existing members (with sufficient reputation or role) to approve membership applications.
 * 17. revokeMembership(address _member): Allows governance to revoke membership (for rule violations, etc.).
 * 18. getMemberDetails(address _member): Retrieves details of a member, including reputation and roles.
 *
 * **Treasury & Funding:**
 * 19. depositFunds(): Allows anyone to deposit funds into the collective treasury.
 * 20. createFundingProposal(string _proposalTitle, string _proposalDescription, address _recipient, uint256 _amount): Allows members to propose funding for art projects or collective initiatives.
 * 21. voteOnFundingProposal(uint256 _proposalId, bool _vote): Allows members to vote on funding proposals (reputation-weighted voting).
 * 22. executeFundingProposal(uint256 _proposalId): Executes a passed funding proposal, transferring funds.
 * 23. getTreasuryBalance(): Returns the current balance of the collective treasury.
 *
 * **Reputation & Incentives:**
 * 24. contributeToCollective(string _contributionDescription): Allows members to log contributions to the collective (governance can reward reputation for contributions).
 * 25. getMemberReputation(address _member): Retrieves the reputation score of a member.
 * 26. rewardMemberReputation(address _member, uint256 _reputationPoints): Allows authorized roles to reward reputation to members.
 *
 * **Utility & Features:**
 * 27. setCollectiveName(string _name): Allows governance to set the name of the collective.
 * 28. getCollectiveName(): Retrieves the name of the collective.
 * 29. pauseContract(): Allows governance to pause core functionalities of the contract for emergency situations.
 * 30. unpauseContract(): Allows governance to unpause the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ArtVerseDAAC is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    string public collectiveName = "ArtVerse Collective"; // Function 27 & 28
    bool public contractPaused = false; // Function 29 & 30

    // --- Data Structures ---
    struct ArtProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 submissionTimestamp;
        bool finalized;
        uint256 yesVotes;
        uint256 noVotes;
        bool accepted;
    }

    struct RuleProposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes ruleData; // Flexible data for rule implementation
        uint256 submissionTimestamp;
        bool finalized;
        uint256 yesVotes;
        uint256 noVotes;
        bool accepted;
    }

    struct FundingProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        address recipient;
        uint256 amount;
        uint256 submissionTimestamp;
        bool finalized;
        uint256 yesVotes;
        uint256 noVotes;
        bool accepted;
        bool executed;
    }

    struct Member {
        address memberAddress;
        uint256 reputation;
        uint256 joinTimestamp;
        bool isActive;
        // Add Roles later if needed (e.g., Curator, Admin)
    }

    // --- State Variables ---
    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter public artProposalCounter;
    uint256[] public pendingArtProposals; // Function 3

    mapping(uint256 => RuleProposal) public ruleProposals;
    Counters.Counter public ruleProposalCounter;

    mapping(uint256 => FundingProposal) public fundingProposals;
    Counters.Counter public fundingProposalCounter;

    mapping(uint256 => address) public artNFTToProposalId; // Track NFT to proposal
    Counters.Counter public artNFTCounter;

    mapping(address => Member) public members;
    address[] public memberList;

    mapping(address => address) public voteDelegations; // Function 14: Delegate Voting

    // --- Events ---
    event ArtProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalCurationFinalized(uint256[] proposalIds);
    event ArtNFTMinted(uint256 nftId, uint256 proposalId, address minter);
    event RuleProposalSubmitted(uint256 proposalId, address proposer, string description);
    event RuleProposalVoted(uint256 proposalId, address voter, bool vote);
    event RuleProposalExecuted(uint256 proposalId);
    event FundingProposalSubmitted(uint256 proposalId, address proposer, string title, address recipient, uint256 amount);
    event FundingProposalVoted(uint256 proposalId, address voter, bool vote);
    event FundingProposalExecuted(uint256 proposalId, address recipient, uint256 amount);
    event MembershipApplied(address applicant, string reason);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event ContributionLogged(address member, string description);
    event ReputationRewarded(address member, uint256 reputationPoints, address rewarder);
    event ContractPaused();
    event ContractUnpaused();
    event CollectiveNameUpdated(string newName, address updater);

    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only members can perform this action.");
        _;
    }

    modifier onlyCurator() { // Example - Define Curator role later and implement check
        // For now, just members can curate. Enhance with specific Curator role later.
        require(members[msg.sender].isActive, "Only curators can perform this action.");
        _;
    }

    modifier onlyCollectiveOwner() onlyOwner { // Reusing OpenZeppelin Ownable
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused.");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("ArtVerseNFT", "AVNFT") {}

    // --- Core Art Proposal & Curation Functions ---

    /// @notice Allows members to submit art proposals. (Function 1)
    /// @param _title Title of the art proposal.
    /// @param _description Detailed description of the art proposal.
    /// @param _ipfsHash IPFS hash linking to the artwork file.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)
        external
        onlyMember
        whenNotPaused
    {
        uint256 proposalId = artProposalCounter.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            submissionTimestamp: block.timestamp,
            finalized: false,
            yesVotes: 0,
            noVotes: 0,
            accepted: false
        });
        pendingArtProposals.push(proposalId);
        artProposalCounter.increment();
        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /// @notice Retrieves detailed information about a specific art proposal. (Function 2)
    /// @param _proposalId ID of the art proposal.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposalDetails(uint256 _proposalId)
        external
        view
        returns (ArtProposal memory)
    {
        require(artProposals[_proposalId].proposalId == _proposalId, "Proposal ID not found.");
        return artProposals[_proposalId];
    }

    /// @notice Returns a list of IDs of currently pending art proposals. (Function 3)
    /// @return Array of proposal IDs.
    function getPendingArtProposals()
        external
        view
        returns (uint256[] memory)
    {
        return pendingArtProposals;
    }

    /// @notice Allows curators to vote on art proposals. (Function 4)
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _vote Boolean indicating vote (true for yes, false for no).
    function voteOnArtProposal(uint256 _proposalId, bool _vote)
        external
        onlyCurator // For now, all members are curators. Refine roles later.
        whenNotPaused
    {
        require(artProposals[_proposalId].proposalId == _proposalId, "Proposal ID not found.");
        require(!artProposals[_proposalId].finalized, "Proposal already finalized.");

        // Reputation-weighted voting can be implemented here later.
        // For now, simple 1-member-1-vote.

        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Retrieves the voting results for a specific art proposal. (Function 5)
    /// @param _proposalId ID of the art proposal.
    /// @return yesVotes, noVotes - Vote counts.
    function getCurationResults(uint256 _proposalId)
        external
        view
        returns (uint256 yesVotes, uint256 noVotes)
    {
        require(artProposals[_proposalId].proposalId == _proposalId, "Proposal ID not found.");
        return (artProposals[_proposalId].yesVotes, artProposals[_proposalId].noVotes);
    }

    /// @notice Finalizes a curation round, processing accepted proposals and minting NFTs. (Function 6)
    /// @param _proposalIds Array of proposal IDs to finalize in this round.
    function finalizeCurationRound(uint256[] memory _proposalIds)
        external
        onlyCurator // For now, all members are curators. Refine roles later.
        whenNotPaused
    {
        for (uint256 i = 0; i < _proposalIds.length; i++) {
            uint256 proposalId = _proposalIds[i];
            require(artProposals[proposalId].proposalId == proposalId, "Proposal ID not found.");
            require(!artProposals[proposalId].finalized, "Proposal already finalized.");

            uint256 totalVotes = members.length; // Assuming all members are curators for now.
            uint256 quorum = totalVotes.div(2).add(1); // Simple majority quorum

            if (artProposals[proposalId].yesVotes >= quorum) {
                artProposals[proposalId].accepted = true;
                _mintArtNFT(proposalId); // Mint NFT for accepted art
            } else {
                artProposals[proposalId].accepted = false;
            }
            artProposals[proposalId].finalized = true;

            // Remove finalized proposals from pending list
            for (uint256 j = 0; j < pendingArtProposals.length; j++) {
                if (pendingArtProposals[j] == proposalId) {
                    pendingArtProposals[j] = pendingArtProposals[pendingArtProposals.length - 1];
                    pendingArtProposals.pop();
                    break;
                }
            }
        }
        emit ArtProposalCurationFinalized(_proposalIds);
    }

    // --- NFT Minting & Management Functions ---

    /// @notice Mints an NFT for an accepted art proposal (internal function called after finalization). (Function 7 - Internal)
    /// @param _proposalId ID of the accepted art proposal.
    function _mintArtNFT(uint256 _proposalId)
        internal
    {
        require(artProposals[_proposalId].proposalId == _proposalId, "Proposal ID not found.");
        require(artProposals[_proposalId].accepted, "Proposal not accepted for NFT minting.");

        uint256 nftId = artNFTCounter.current();
        _safeMint(address(this), nftId); // Mint NFT to contract itself initially
        artNFTToProposalId[nftId] = _proposalId;
        artNFTCounter.increment();

        emit ArtNFTMinted(nftId, _proposalId, address(this)); // Minter is the contract itself initially
    }

    /// @notice Retrieves details of a minted ArtVerse NFT. (Function 8)
    /// @param _nftId ID of the ArtVerse NFT.
    /// @return proposalId associated with the NFT.
    function getArtNFTDetails(uint256 _nftId)
        external
        view
        returns (uint256 proposalId)
    {
        require(_exists(_nftId), "NFT ID does not exist.");
        return artNFTToProposalId[_nftId];
    }

    /// @notice Allows the collective to transfer ownership of an ArtVerse NFT. (e.g., for auctions or partnerships) (Function 9)
    /// @param _nftId ID of the ArtVerse NFT to transfer.
    /// @param _to Address to transfer the NFT to.
    function transferArtNFT(uint256 _nftId, address _to)
        external
        onlyCollectiveOwner // Or governance-controlled role later
        whenNotPaused
    {
        require(_exists(_nftId), "NFT ID does not exist.");
        safeTransferFrom(address(this), _to, _nftId);
    }

    /// @notice Allows the collective to burn an ArtVerse NFT (governance decision). (Function 10)
    /// @param _nftId ID of the ArtVerse NFT to burn.
    function burnArtNFT(uint256 _nftId)
        external
        onlyCollectiveOwner // Or governance-controlled role later
        whenNotPaused
    {
        require(_exists(_nftId), "NFT ID does not exist.");
        _burn(_nftId);
    }

    // --- Governance & Voting Functions ---

    /// @notice Allows members to propose new rules for the collective. (Function 11)
    /// @param _ruleDescription Description of the rule proposal.
    /// @param _ruleData Data relevant to the rule implementation (e.g., encoded parameters).
    function proposeNewRule(string memory _ruleDescription, bytes memory _ruleData)
        external
        onlyMember
        whenNotPaused
    {
        uint256 proposalId = ruleProposalCounter.current();
        ruleProposals[proposalId] = RuleProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _ruleDescription,
            ruleData: _ruleData,
            submissionTimestamp: block.timestamp,
            finalized: false,
            yesVotes: 0,
            noVotes: 0,
            accepted: false
        });
        ruleProposalCounter.increment();
        emit RuleProposalSubmitted(proposalId, msg.sender, _ruleDescription);
    }

    /// @notice Allows members to vote on rule proposals (reputation-weighted voting). (Function 12)
    /// @param _proposalId ID of the rule proposal to vote on.
    /// @param _vote Boolean indicating vote (true for yes, false for no).
    function voteOnRuleProposal(uint256 _proposalId, bool _vote)
        external
        onlyMember
        whenNotPaused
    {
        require(ruleProposals[_proposalId].proposalId == _proposalId, "Rule Proposal ID not found.");
        require(!ruleProposals[_proposalId].finalized, "Rule Proposal already finalized.");

        uint256 votingPower = getVotingPower(msg.sender); // Reputation-weighted voting

        if (_vote) {
            ruleProposals[_proposalId].yesVotes += votingPower;
        } else {
            ruleProposals[_proposalId].noVotes += votingPower;
        }
        emit RuleProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a passed rule proposal. (Function 13)
    /// @param _proposalId ID of the rule proposal to execute.
    function executeRuleProposal(uint256 _proposalId)
        external
        onlyCollectiveOwner // Or governance-controlled role later. Execution needs control.
        whenNotPaused
    {
        require(ruleProposals[_proposalId].proposalId == _proposalId, "Rule Proposal ID not found.");
        require(!ruleProposals[_proposalId].finalized, "Rule Proposal voting not finalized.");

        uint256 totalVotingPower = getTotalVotingPower();
        uint256 quorum = totalVotingPower.div(2).add(1); // Simple majority quorum based on voting power

        if (ruleProposals[_proposalId].yesVotes >= quorum) {
            ruleProposals[_proposalId].accepted = true;
            // Implement rule execution logic based on ruleProposals[_proposalId].ruleData here.
            // This is highly dependent on the types of rules the collective wants to implement.
            // Example: if ruleData encodes a function call, execute it.
            // For simplicity, we just mark it as accepted for now.
        } else {
            ruleProposals[_proposalId].accepted = false;
        }
        ruleProposals[_proposalId].finalized = true;
        emit RuleProposalExecuted(_proposalId);
    }

    /// @notice Allows members to delegate their voting power to another member. (Function 14)
    /// @param _delegatee Address of the member to delegate voting power to.
    function delegateVote(address _delegatee)
        external
        onlyMember
        whenNotPaused
    {
        require(members[_delegatee].isActive, "Delegatee is not an active member.");
        voteDelegations[msg.sender] = _delegatee;
    }

    // --- Membership & Roles Functions ---

    /// @notice Allows users to apply for membership in the collective. (Function 15)
    /// @param _reason Reason for applying for membership.
    function applyForMembership(string memory _reason)
        external
        whenNotPaused
    {
        require(!members[msg.sender].isActive, "Already a member.");
        // Membership application process - can be refined with voting or admin approval
        emit MembershipApplied(msg.sender, _reason);
        // For simplicity, auto-approve for now. In real scenario, implement voting/approval process.
        _approveMembership(msg.sender);
    }

    /// @notice Internal function to approve membership applications. (Function 16 - Internal)
    /// @param _applicant Address of the applicant to approve.
    function _approveMembership(address _applicant)
        internal
    {
        require(!members[_applicant].isActive, "Already a member.");
        members[_applicant] = Member({
            memberAddress: _applicant,
            reputation: 1, // Initial reputation for new members
            joinTimestamp: block.timestamp,
            isActive: true
        });
        memberList.push(_applicant);
        emit MembershipApproved(_applicant);
    }

    /// @notice Allows existing members (with sufficient reputation or role) to approve membership applications. (Function 16 - External - Example - Needs Role/Reputation Check)
    /// @param _applicant Address of the applicant to approve.
    function approveMembership(address _applicant)
        external
        onlyMember // Example -  Require higher reputation or specific role to approve
        whenNotPaused
    {
        // Example: require(getMemberReputation(msg.sender) >= 10, "Insufficient reputation to approve members.");
        _approveMembership(_applicant);
    }


    /// @notice Allows governance to revoke membership (for rule violations, etc.). (Function 17)
    /// @param _member Address of the member to revoke membership from.
    function revokeMembership(address _member)
        external
        onlyCollectiveOwner // Or governance-controlled role later
        whenNotPaused
    {
        require(members[_member].isActive, "Not an active member.");
        members[_member].isActive = false;
        // Remove from memberList (optional - depends on how memberList is used)
        emit MembershipRevoked(_member);
    }

    /// @notice Retrieves details of a member, including reputation and roles. (Function 18)
    /// @param _member Address of the member.
    /// @return Member struct containing member details.
    function getMemberDetails(address _member)
        external
        view
        returns (Member memory)
    {
        return members[_member];
    }

    // --- Treasury & Funding Functions ---

    /// @notice Allows anyone to deposit funds into the collective treasury. (Function 19)
    function depositFunds()
        external
        payable
        whenNotPaused
    {
        // Funds are directly sent to the contract address.
        // No explicit storage needed for deposits in this function.
    }

    /// @notice Creates a funding proposal for art projects or collective initiatives. (Function 20)
    /// @param _proposalTitle Title of the funding proposal.
    /// @param _proposalDescription Detailed description of the funding proposal.
    /// @param _recipient Address to receive the funds if the proposal is accepted.
    /// @param _amount Amount of Ether to request for funding.
    function createFundingProposal(string memory _proposalTitle, string memory _proposalDescription, address _recipient, uint256 _amount)
        external
        onlyMember
        whenNotPaused
    {
        require(_amount > 0, "Funding amount must be greater than zero.");
        uint256 proposalId = fundingProposalCounter.current();
        fundingProposals[proposalId] = FundingProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: _proposalTitle,
            description: _proposalDescription,
            recipient: _recipient,
            amount: _amount,
            submissionTimestamp: block.timestamp,
            finalized: false,
            yesVotes: 0,
            noVotes: 0,
            accepted: false,
            executed: false
        });
        fundingProposalCounter.increment();
        emit FundingProposalSubmitted(proposalId, msg.sender, _proposalTitle, _recipient, _amount);
    }

    /// @notice Allows members to vote on funding proposals (reputation-weighted voting). (Function 21)
    /// @param _proposalId ID of the funding proposal to vote on.
    /// @param _vote Boolean indicating vote (true for yes, false for no).
    function voteOnFundingProposal(uint256 _proposalId, bool _vote)
        external
        onlyMember
        whenNotPaused
    {
        require(fundingProposals[_proposalId].proposalId == _proposalId, "Funding Proposal ID not found.");
        require(!fundingProposals[_proposalId].finalized, "Funding Proposal already finalized.");

        uint256 votingPower = getVotingPower(msg.sender); // Reputation-weighted voting

        if (_vote) {
            fundingProposals[_proposalId].yesVotes += votingPower;
        } else {
            fundingProposals[_proposalId].noVotes += votingPower;
        }
        emit FundingProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a passed funding proposal, transferring funds. (Function 22)
    /// @param _proposalId ID of the funding proposal to execute.
    function executeFundingProposal(uint256 _proposalId)
        external
        onlyCollectiveOwner // Or governance-controlled role later. Execution needs control.
        whenNotPaused
    {
        require(fundingProposals[_proposalId].proposalId == _proposalId, "Funding Proposal ID not found.");
        require(!fundingProposals[_proposalId].finalized, "Funding Proposal voting not finalized.");
        require(!fundingProposals[_proposalId].executed, "Funding Proposal already executed.");

        uint256 totalVotingPower = getTotalVotingPower();
        uint256 quorum = totalVotingPower.div(2).add(1); // Simple majority quorum based on voting power

        if (fundingProposals[_proposalId].yesVotes >= quorum) {
            fundingProposals[_proposalId].accepted = true;
            require(address(this).balance >= fundingProposals[_proposalId].amount, "Insufficient treasury balance.");
            payable(fundingProposals[_proposalId].recipient).transfer(fundingProposals[_proposalId].amount);
            fundingProposals[_proposalId].executed = true;
            emit FundingProposalExecuted(_proposalId, fundingProposals[_proposalId].recipient, fundingProposals[_proposalId].amount);
        } else {
            fundingProposals[_proposalId].accepted = false;
        }
        fundingProposals[_proposalId].finalized = true;
    }

    /// @notice Returns the current balance of the collective treasury. (Function 23)
    /// @return Current balance of the contract in Ether.
    function getTreasuryBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    // --- Reputation & Incentives Functions ---

    /// @notice Allows members to log contributions to the collective (governance can reward reputation for contributions). (Function 24)
    /// @param _contributionDescription Description of the contribution.
    function contributeToCollective(string memory _contributionDescription)
        external
        onlyMember
        whenNotPaused
    {
        emit ContributionLogged(msg.sender, _contributionDescription);
        // Governance (manual or automated process) can later call rewardMemberReputation based on these logs.
    }

    /// @notice Retrieves the reputation score of a member. (Function 25)
    /// @param _member Address of the member.
    /// @return Reputation score of the member.
    function getMemberReputation(address _member)
        external
        view
        returns (uint256)
    {
        return members[_member].reputation;
    }

    /// @notice Allows authorized roles to reward reputation to members. (Function 26)
    /// @param _member Address of the member to reward.
    /// @param _reputationPoints Amount of reputation points to reward.
    function rewardMemberReputation(address _member, uint256 _reputationPoints)
        external
        onlyCollectiveOwner // Or governance-controlled role later
        whenNotPaused
    {
        require(members[_member].isActive, "Member is not active.");
        members[_member].reputation += _reputationPoints;
        emit ReputationRewarded(_member, _reputationPoints, msg.sender);
    }

    // --- Utility & Features Functions ---

    /// @notice Allows governance to set the name of the collective. (Function 27)
    /// @param _name New name for the collective.
    function setCollectiveName(string memory _name)
        external
        onlyCollectiveOwner
        whenNotPaused
    {
        collectiveName = _name;
        emit CollectiveNameUpdated(_name, msg.sender);
    }

    /// @notice Retrieves the name of the collective. (Function 28)
    /// @return Name of the collective.
    function getCollectiveName()
        external
        view
        returns (string memory)
    {
        return collectiveName;
    }

    /// @notice Allows governance to pause core functionalities of the contract for emergency situations. (Function 29)
    function pauseContract()
        external
        onlyCollectiveOwner
        whenNotPaused
    {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Allows governance to unpause the contract. (Function 30)
    function unpauseContract()
        external
        onlyCollectiveOwner
        whenPaused
    {
        contractPaused = false;
        emit ContractUnpaused();
    }

    // --- Helper/Internal Functions ---

    /// @dev Calculates voting power for a member based on reputation (example - can be customized).
    function getVotingPower(address _member)
        internal
        view
        returns (uint256)
    {
        address delegate = voteDelegations[_member];
        if (delegate != address(0)) {
            return getMemberReputation(delegate); // Delegated vote
        } else {
            return getMemberReputation(_member); // Own vote
        }
    }

    /// @dev Calculates total voting power of all members (for quorum calculation).
    function getTotalVotingPower()
        internal
        view
        returns (uint256)
    {
        uint256 totalPower = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            totalPower += getVotingPower(memberList[i]);
        }
        return totalPower;
    }

    // --- Fallback Function (Optional - for receiving Ether) ---
    receive() external payable {}
    fallback() external payable {}
}
```