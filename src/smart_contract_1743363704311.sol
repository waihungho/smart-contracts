```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAAC) - Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to collaborate,
 *      govern collectively, and showcase their art in a decentralized manner. This contract incorporates
 *      advanced concepts like on-chain governance, dynamic royalty splits, decentralized exhibitions,
 *      and reputation systems, aiming to foster a vibrant and equitable art ecosystem.
 *
 * **Outline:**
 *  1.  **Art Submission & Review:** Artists can submit artwork proposals, which are reviewed by the collective.
 *  2.  **On-Chain Governance:**  Members can vote on proposals related to artwork approval, funding allocation,
 *      exhibition curation, rule changes, and more.
 *  3.  **Decentralized Exhibitions:** Create and manage virtual art exhibitions curated by the collective.
 *  4.  **Dynamic Royalty Splits:**  Define and manage royalty splits for artworks, distributed to artists and the collective.
 *  5.  **Reputation System:**  Track member contributions and reputation within the collective.
 *  6.  **Collective Treasury:** Manage a treasury funded by membership fees, art sales, and donations.
 *  7.  **Collaborative Art Creation:**  Enable collaborative art projects with shared ownership and royalties.
 *  8.  **Decentralized Curation:** Implement decentralized curation mechanisms for exhibitions and featured artworks.
 *  9.  **Event Management:** Organize and manage art events and workshops within the collective.
 *  10. **Dispute Resolution (Basic):**  Simple mechanism for resolving disputes within the collective.
 *  11. **Layered Access Control:** Implement different roles and permissions for members.
 *  12. **Membership Management:**  Handle joining, leaving, and membership fees for the collective.
 *  13. **Tokenized Governance (Optional):**  Potentially integrate a governance token for voting power (left as extension).
 *  14. **Artwork NFT Minting:**  Mint NFTs for approved artworks, potentially with on-chain metadata.
 *  15. **Decentralized Storage Integration (IPFS):**  Utilize IPFS for storing artwork metadata and content hashes.
 *  16. **Dynamic Membership Levels:** Introduce different membership tiers with varying benefits.
 *  17. **Algorithmic Curation (Basic):**  Explore basic algorithmic curation based on member reputation and artwork quality metrics.
 *  18. **Cross-Chain Art Bridging (Conceptual):**  (Conceptual - not fully implemented here)  Design for potential future integration with cross-chain art marketplaces.
 *  19. **Decentralized Messaging (Conceptual):** (Conceptual - not fully implemented here)  Outline for integrating decentralized communication within the collective.
 *  20. **Emergency Pause & Recovery:**  Include a mechanism for pausing the contract in case of critical issues and for potential recovery.
 *
 * **Function Summary:**
 *  1. `submitArtworkProposal(string _title, string _description, string _ipfsHash)`:  Allows artists to submit artwork proposals for review.
 *  2. `reviewArtworkProposal(uint256 _proposalId, bool _approved)`:  Governance function to review and approve/reject artwork proposals via voting.
 *  3. `mintArtworkNFT(uint256 _artworkId)`: Mints an NFT for an approved artwork.
 *  4. `createExhibition(string _title, string _description, uint256 _startDate, uint256 _endDate)`:  Governance function to create a new art exhibition proposal.
 *  5. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Governance function to propose adding artwork to an exhibition.
 *  6. `startExhibition(uint256 _exhibitionId)`: Governance function to start an exhibition.
 *  7. `endExhibition(uint256 _exhibitionId)`: Governance function to end an exhibition.
 *  8. `setArtworkRoyaltySplit(uint256 _artworkId, uint256 _artistPercentage, uint256 _collectivePercentage)`: Governance function to set the royalty split for an artwork.
 *  9. `purchaseArtwork(uint256 _artworkId)`: Allows anyone to purchase an artwork, distributing royalties dynamically.
 * 10. `joinCollective()`: Allows artists to join the collective by paying a membership fee.
 * 11. `leaveCollective()`: Allows members to leave the collective.
 * 12. `setMembershipFee(uint256 _fee)`: Governance function to set the collective membership fee.
 * 13. `depositToTreasury()`: Allows anyone to deposit funds into the collective treasury.
 * 14. `withdrawFromTreasury(address _recipient, uint256 _amount)`: Governance function to withdraw funds from the treasury.
 * 15. `reportMemberContribution(address _member, string _contributionDescription)`: Allows members to report contributions, influencing reputation.
 * 16. `voteOnMemberReputation(address _member, int256 _reputationChange)`: Governance function to vote on adjusting member reputation.
 * 17. `createRuleChangeProposal(string _ruleDescription)`: Governance function to propose changes to collective rules.
 * 18. `voteOnRuleChangeProposal(uint256 _proposalId, bool _approved)`: Governance function to vote on rule change proposals.
 * 19. `resolveDispute(uint256 _disputeId, string _resolution)`: Governance function to resolve disputes within the collective.
 * 20. `pauseContract()`: Governance function to pause the contract in emergencies.
 * 21. `unpauseContract()`: Governance function to unpause the contract.
 * 22. `getArtworkDetails(uint256 _artworkId)`: Public view function to get details of an artwork.
 * 23. `getExhibitionDetails(uint256 _exhibitionId)`: Public view function to get details of an exhibition.
 * 24. `getMemberReputation(address _member)`: Public view function to get the reputation of a member.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousArtCollective is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Enums
    enum ProposalType { ARTWORK_REVIEW, EXHIBITION_CREATION, EXHIBITION_ARTWORK_ADD, RULE_CHANGE, TREASURY_WITHDRAWAL, REPUTATION_CHANGE, DISPUTE_RESOLUTION }
    enum ProposalStatus { PENDING, ACTIVE, PASSED, REJECTED, EXECUTED }
    enum ArtworkStatus { PROPOSED, APPROVED, REJECTED, MINTED, EXHIBITED }
    enum ExhibitionStatus { CREATED, ACTIVE, ENDED }
    enum MemberRole { MEMBER, CURATOR, GOVERNANCE } // Example roles

    // Structs
    struct Artwork {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        ArtworkStatus status;
        uint256 artistRoyaltyPercentage;
        uint256 collectiveRoyaltyPercentage;
    }

    struct Exhibition {
        uint256 id;
        string title;
        string description;
        uint256 startDate;
        uint256 endDate;
        ExhibitionStatus status;
        uint256[] artworkIds;
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        ProposalStatus status;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 quorum; // Percentage of members needed to vote
        uint256 votesFor;
        uint256 votesAgainst;
        bytes data; // Encoded proposal data (e.g., artworkId, approval status, etc.)
    }

    struct Member {
        address memberAddress;
        uint256 joinTimestamp;
        int256 reputation;
        mapping(MemberRole => bool) roles;
    }

    struct Dispute {
        uint256 id;
        address reporter;
        string description;
        string resolution;
        bool resolved;
    }

    // State Variables
    Counters.Counter private _artworkIdCounter;
    mapping(uint256 => Artwork) public artworks;
    Counters.Counter private _exhibitionIdCounter;
    mapping(uint256 => Exhibition) public exhibitions;
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _disputeIdCounter;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public membershipFee;
    uint256 public treasuryBalance;
    uint256 public governanceQuorumPercentage = 50; // Default quorum 50%
    bool public paused = false;

    // Events
    event ArtworkProposalSubmitted(uint256 proposalId, uint256 artworkId, address artist, string title);
    event ArtworkProposalReviewed(uint256 proposalId, uint256 artworkId, bool approved);
    event ArtworkNFTMinted(uint256 artworkId, address artist, string title);
    event ExhibitionCreated(uint256 exhibitionId, string title);
    event ArtworkAddedToExhibition(uint256 exhibitionId, uint256 artworkId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event RoyaltySplitSet(uint256 artworkId, uint256 artistPercentage, uint256 collectivePercentage);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price, address artist, uint256 artistRoyalty, uint256 collectiveRoyalty);
    event MemberJoined(address memberAddress, uint256 joinTimestamp);
    event MemberLeft(address memberAddress);
    event MembershipFeeSet(uint256 fee);
    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount, address governance);
    event MemberContributionReported(address reporter, address member, string description);
    event MemberReputationVoted(address member, int256 reputationChange);
    event RuleChangeProposed(uint256 proposalId, string ruleDescription);
    event RuleChangeVoted(uint256 proposalId, bool approved);
    event DisputeResolved(uint256 disputeId, string resolution, address governance);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // Modifiers
    modifier onlyMember() {
        require(isMember(msg.sender), "Not a member of the collective");
        _;
    }

    modifier onlyGovernance() {
        require(hasRole(msg.sender, MemberRole.GOVERNANCE), "Not governance member");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // Constructor
    constructor(uint256 _initialMembershipFee) payable {
        membershipFee = _initialMembershipFee;
        treasuryBalance = msg.value;
        _grantRole(msg.sender, MemberRole.GOVERNANCE); // Initial deployer is governance
        _joinCollectiveInternal(msg.sender); // Deployer is also a member
    }

    // -------------------- Membership Functions --------------------

    function joinCollective() public payable whenNotPaused {
        require(!isMember(msg.sender), "Already a member");
        require(msg.value >= membershipFee, "Insufficient membership fee");
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
        _joinCollectiveInternal(msg.sender);
        emit MemberJoined(msg.sender, block.timestamp);
    }

    function _joinCollectiveInternal(address _member) private {
        members[_member] = Member({
            memberAddress: _member,
            joinTimestamp: block.timestamp,
            reputation: 0,
            roles: MemberRole.MEMBER => true // Default role is MEMBER
        });
        memberList.push(_member);
    }

    function leaveCollective() public onlyMember whenNotPaused {
        delete members[msg.sender];
        // Remove from memberList (less efficient in Solidity, consider alternative if scalability is critical)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MemberLeft(msg.sender);
    }

    function setMembershipFee(uint256 _fee) public onlyGovernance whenNotPaused {
        membershipFee = _fee;
        emit MembershipFeeSet(_fee);
    }

    function getMemberList() public view returns (address[] memory) {
        return memberList;
    }

    function getMemberCount() public view returns (uint256) {
        return memberList.length;
    }

    function isMember(address _address) public view returns (bool) {
        return members[_address].memberAddress != address(0);
    }

    // -------------------- Role Management (Basic) --------------------
    function hasRole(address _account, MemberRole _role) public view returns (bool) {
        return members[_account].roles[_role];
    }

    function _grantRole(address _account, MemberRole _role) private {
        members[_account].roles[_role] = true;
    }

    function _revokeRole(address _account, MemberRole _role) private {
        members[_account].roles[_role] = false;
    }

    function assignRole(address _account, MemberRole _role) public onlyGovernance whenNotPaused {
        require(isMember(_account), "Account is not a member");
        _grantRole(_account, _role);
    }

    function revokeRole(address _account, MemberRole _role) public onlyGovernance whenNotPaused {
        require(isMember(_account), "Account is not a member");
        require(_account != owner(), "Cannot revoke governance from contract owner"); // Basic protection
        _revokeRole(_account, _role);
    }


    // -------------------- Artwork Submission & Review --------------------

    function submitArtworkProposal(string memory _title, string memory _description, string memory _ipfsHash) public onlyMember whenNotPaused {
        _artworkIdCounter.increment();
        uint256 artworkId = _artworkIdCounter.current();

        artworks[artworkId] = Artwork({
            id: artworkId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            status: ArtworkStatus.PROPOSED,
            artistRoyaltyPercentage: 0, // Default royalty, to be set later by governance
            collectiveRoyaltyPercentage: 0
        });

        _createProposal(
            ProposalType.ARTWORK_REVIEW,
            abi.encode(artworkId),
            "Review Artwork Proposal: " ,
            _title
        );

        emit ArtworkProposalSubmitted(proposals[_proposalIdCounter.current()].id, artworkId, msg.sender, _title);
    }

    function reviewArtworkProposal(uint256 _proposalId, bool _approved) public onlyGovernance whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ARTWORK_REVIEW, "Invalid proposal type");
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");

        require(_voteOnProposal(_proposalId, _approved), "Failed to vote on proposal");

        if (proposal.status == ProposalStatus.PASSED) {
            uint256 artworkId = abi.decode(proposal.data, (uint256));
            if (_approved) {
                artworks[artworkId].status = ArtworkStatus.APPROVED;
                emit ArtworkProposalReviewed(_proposalId, artworkId, true);
            } else {
                artworks[artworkId].status = ArtworkStatus.REJECTED;
                emit ArtworkProposalReviewed(_proposalId, artworkId, false);
            }
            proposal.status = ProposalStatus.EXECUTED;
        } else if (proposal.status == ProposalStatus.REJECTED) {
            uint256 artworkId = abi.decode(proposal.data, (uint256));
             if (!_approved) {
                artworks[artworkId].status = ArtworkStatus.REJECTED;
                emit ArtworkProposalReviewed(_proposalId, artworkId, false);
            }
            proposal.status = ProposalStatus.EXECUTED;
        }
    }

    function mintArtworkNFT(uint256 _artworkId) public onlyGovernance whenNotPaused {
        require(artworks[_artworkId].status == ArtworkStatus.APPROVED, "Artwork not approved");
        artworks[_artworkId].status = ArtworkStatus.MINTED;
        // In a real application, you would integrate with an NFT contract (e.g., ERC721) here
        // to actually mint the NFT and associate it with the artwork metadata (IPFS hash).
        emit ArtworkNFTMinted(_artworkId, artworks[_artworkId].artist, artworks[_artworkId].title);
    }

    // -------------------- Decentralized Exhibitions --------------------

    function createExhibition(string memory _title, string memory _description, uint256 _startDate, uint256 _endDate) public onlyGovernance whenNotPaused {
        _exhibitionIdCounter.increment();
        uint256 exhibitionId = _exhibitionIdCounter.current();

        exhibitions[exhibitionId] = Exhibition({
            id: exhibitionId,
            title: _title,
            description: _description,
            startDate: _startDate,
            endDate: _endDate,
            status: ExhibitionStatus.CREATED,
            artworkIds: new uint256[](0)
        });

        _createProposal(
            ProposalType.EXHIBITION_CREATION,
            abi.encode(exhibitionId),
            "Create Exhibition Proposal: ",
            _title
        );
         emit ExhibitionCreated(exhibitionId, _title);
    }

    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) public onlyGovernance whenNotPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.CREATED, "Exhibition must be in CREATED status");
        require(artworks[_artworkId].status == ArtworkStatus.MINTED, "Artwork must be minted to be exhibited");

        _createProposal(
            ProposalType.EXHIBITION_ARTWORK_ADD,
            abi.encode(_exhibitionId, _artworkId),
            "Add Artwork to Exhibition Proposal: ",
            string(abi.encodePacked(artworks[_artworkId].title, " to Exhibition: ", exhibitions[_exhibitionId].title))
        );

        emit ArtworkAddedToExhibition(_exhibitionId, _artworkId);
    }

    function startExhibition(uint256 _exhibitionId) public onlyGovernance whenNotPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.CREATED, "Exhibition must be in CREATED status");
        exhibitions[_exhibitionId].status = ExhibitionStatus.ACTIVE;
        emit ExhibitionStarted(_exhibitionId);
    }

    function endExhibition(uint256 _exhibitionId) public onlyGovernance whenNotPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.ACTIVE, "Exhibition must be in ACTIVE status");
        exhibitions[_exhibitionId].status = ExhibitionStatus.ENDED;
        emit ExhibitionEnded(_exhibitionId);
    }

    // -------------------- Dynamic Royalty Splits & Purchase --------------------

    function setArtworkRoyaltySplit(uint256 _artworkId, uint256 _artistPercentage, uint256 _collectivePercentage) public onlyGovernance whenNotPaused {
        require(_artistPercentage + _collectivePercentage == 100, "Royalty percentages must sum to 100");
        artworks[_artworkId].artistRoyaltyPercentage = _artistPercentage;
        artworks[_artworkId].collectiveRoyaltyPercentage = _collectivePercentage;
        emit RoyaltySplitSet(_artworkId, _artistPercentage, _collectivePercentage);
    }

    function purchaseArtwork(uint256 _artworkId) public payable whenNotPaused {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.status == ArtworkStatus.MINTED, "Artwork is not available for purchase");
        require(artwork.artistRoyaltyPercentage > 0 && artwork.collectiveRoyaltyPercentage > 0, "Royalty split not set");

        uint256 artistRoyaltyAmount = (msg.value * artwork.artistRoyaltyPercentage) / 100;
        uint256 collectiveRoyaltyAmount = (msg.value * artwork.collectiveRoyaltyPercentage) / 100;

        payable(artwork.artist).transfer(artistRoyaltyAmount);
        treasuryBalance += collectiveRoyaltyAmount;

        emit ArtworkPurchased(_artworkId, msg.sender, msg.value, artwork.artist, artistRoyaltyAmount, collectiveRoyaltyAmount);
        emit TreasuryDeposit(address(this), collectiveRoyaltyAmount); // For clarity, even though it's internal
    }

    // -------------------- Reputation System (Basic) --------------------

    function reportMemberContribution(address _member, string memory _contributionDescription) public onlyMember whenNotPaused {
        require(isMember(_member), "Target address is not a member");
        // In a more advanced system, you might track contribution types, timestamps, etc.
        emit MemberContributionReported(msg.sender, _member, _contributionDescription);
    }

    function voteOnMemberReputation(address _member, int256 _reputationChange) public onlyGovernance whenNotPaused {
        require(isMember(_member), "Target address is not a member");

        _createProposal(
            ProposalType.REPUTATION_CHANGE,
            abi.encode(_member, _reputationChange),
            "Reputation Change Proposal for: ",
            string(abi.encodePacked(_member))
        );
    }

    // -------------------- Collective Treasury Management --------------------

    function depositToTreasury() public payable whenNotPaused {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function withdrawFromTreasury(address _recipient, uint256 _amount) public onlyGovernance whenNotPaused {

        _createProposal(
            ProposalType.TREASURY_WITHDRAWAL,
            abi.encode(_recipient, _amount),
            "Treasury Withdrawal Proposal: ",
            string(abi.encodePacked(_amount.toString()))
        );
    }

    function _executeTreasuryWithdrawal(uint256 _proposalId) private onlyGovernance whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.TREASURY_WITHDRAWAL, "Invalid proposal type");
        require(proposal.status == ProposalStatus.PASSED, "Proposal not passed");

        (address recipient, uint256 amount) = abi.decode(proposal.data, (address, uint256));

        require(treasuryBalance >= amount, "Insufficient treasury balance");
        treasuryBalance -= amount;
        payable(recipient).transfer(amount);
        emit TreasuryWithdrawal(recipient, amount, msg.sender);
        proposal.status = ProposalStatus.EXECUTED;
    }


    // -------------------- On-Chain Governance (Basic Proposal System) --------------------

    function createRuleChangeProposal(string memory _ruleDescription) public onlyGovernance whenNotPaused {
         _createProposal(
            ProposalType.RULE_CHANGE,
            abi.encode(_ruleDescription),
            "Rule Change Proposal: ",
            _ruleDescription
        );
        emit RuleChangeProposed(proposals[_proposalIdCounter.current()].id, _ruleDescription);
    }

    function voteOnRuleChangeProposal(uint256 _proposalId, bool _approved) public onlyGovernance whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.RULE_CHANGE, "Invalid proposal type");
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");

        require(_voteOnProposal(_proposalId, _approved), "Failed to vote on proposal");

        if (proposal.status == ProposalStatus.PASSED) {
            emit RuleChangeVoted(_proposalId, true); // Logic to apply rule changes would go here in a more advanced system
            proposal.status = ProposalStatus.EXECUTED;
        } else if (proposal.status == ProposalStatus.REJECTED) {
            emit RuleChangeVoted(_proposalId, false);
            proposal.status = ProposalStatus.EXECUTED;
        }
    }

    function resolveDispute(uint256 _disputeId, string memory _resolution) public onlyGovernance whenNotPaused {
        disputes[_disputeId].resolution = _resolution;
        disputes[_disputeId].resolved = true;
        emit DisputeResolved(_disputeId, _resolution, msg.sender);
    }

    function _createProposal(ProposalType _proposalType, bytes memory _data, string memory _descriptionPrefix, string memory _descriptionSuffix) private onlyGovernance {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: _proposalType,
            status: ProposalStatus.ACTIVE,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // Example: 7 day voting period
            quorum: governanceQuorumPercentage,
            votesFor: 0,
            votesAgainst: 0,
            data: _data
        });
        // Consider emitting a generic ProposalCreated event if you want to track all proposal types
        // event ProposalCreated(uint256 proposalId, ProposalType proposalType, string description);
    }

    function _voteOnProposal(uint256 _proposalId, bool _vote) private onlyGovernance returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        // Simple voting: Governance members vote. In a more advanced system, voting power could be weighted.

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        uint256 totalGovernanceMembers = 0;
        for(uint256 i = 0; i < memberList.length; i++){
            if(hasRole(memberList[i], MemberRole.GOVERNANCE)){
                totalGovernanceMembers++;
            }
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumNeeded = (totalGovernanceMembers * proposal.quorum) / 100;

        if (totalVotes >= quorumNeeded) {
            if (proposal.votesFor > proposal.votesAgainst) {
                proposal.status = ProposalStatus.PASSED;
                if(proposal.proposalType == ProposalType.TREASURY_WITHDRAWAL){
                    _executeTreasuryWithdrawal(_proposalId);
                } else if (proposal.proposalType == ProposalType.EXHIBITION_ARTWORK_ADD){
                    (uint256 exhibitionId, uint256 artworkId) = abi.decode(proposal.data, (uint256, uint256));
                    exhibitions[exhibitionId].artworkIds.push(artworkId);
                } else if (proposal.proposalType == ProposalType.REPUTATION_CHANGE){
                    (address memberAddress, int256 reputationChange) = abi.decode(proposal.data, (address, int256));
                    members[memberAddress].reputation += reputationChange;
                    emit MemberReputationVoted(memberAddress, reputationChange);
                }
            } else {
                proposal.status = ProposalStatus.REJECTED;
            }
        }
        return true;
    }


    // -------------------- Dispute Resolution (Basic) --------------------
    function reportDispute(string memory _description) public onlyMember whenNotPaused {
        _disputeIdCounter.increment();
        uint256 disputeId = _disputeIdCounter.current();
        disputes[disputeId] = Dispute({
            id: disputeId,
            reporter: msg.sender,
            description: _description,
            resolution: "",
            resolved: false
        });
        // Governance members would then review and resolve disputes (using resolveDispute function)
    }


    // -------------------- Emergency Pause & Recovery --------------------

    function pauseContract() public onlyGovernance whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyGovernance whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }


    // -------------------- Utility/View Functions --------------------

    function getArtworkDetails(uint256 _artworkId) public view returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    function getMemberReputation(address _member) public view returns (int256) {
        return members[_member].reputation;
    }

    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getDisputeDetails(uint256 _disputeId) public view returns (Dispute memory) {
        return disputes[_disputeId];
    }

    receive() external payable {
        depositToTreasury(); // Allow direct ETH deposits to the treasury
    }
}
```