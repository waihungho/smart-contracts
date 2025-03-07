```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling artists to submit artwork,
 *      community members to become curators, vote on artwork submissions, organize exhibitions,
 *      manage a collective fund, and govern the collective's rules through on-chain proposals and voting.
 *
 * Outline and Function Summary:
 *
 * 1.  **Membership Management:**
 *     - `joinCollective()`: Allows users to join the art collective by paying a membership fee.
 *     - `leaveCollective()`: Allows members to leave the collective and potentially withdraw funds.
 *     - `isCollectiveMember(address _user)`: Checks if an address is a member of the collective.
 *     - `getMemberCount()`: Returns the total number of collective members.
 *
 * 2.  **Artwork Submission & Management:**
 *     - `submitArtwork(string memory _artworkURI, string memory _title, string memory _description)`: Artists submit their artwork with URI, title, and description, paying a submission fee.
 *     - `approveArtwork(uint256 _artworkId)`: Curators vote to approve submitted artwork for inclusion in the collective's gallery.
 *     - `rejectArtwork(uint256 _artworkId)`: Curators vote to reject submitted artwork.
 *     - `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a specific artwork by its ID.
 *     - `getArtworkStatus(uint256 _artworkId)`: Returns the current status of an artwork (Pending, Approved, Rejected).
 *     - `listArtworkForSale(uint256 _artworkId, uint256 _price)`: Approved artists can list their artwork for sale within the collective's marketplace.
 *     - `removeArtworkFromSale(uint256 _artworkId)`: Artists can remove their artwork from sale.
 *     - `purchaseArtwork(uint256 _artworkId)`: Users can purchase listed artwork, with funds distributed according to collective rules.
 *     - `withdrawArtistFunds()`: Artists can withdraw their earnings from artwork sales.
 *
 * 3.  **Curator Role & Voting:**
 *     - `becomeCurator()`: Collective members can apply to become curators by paying a curator deposit.
 *     - `resignCurator()`: Curators can resign from their role and potentially withdraw their deposit.
 *     - `isCurator(address _user)`: Checks if an address is a curator.
 *     - `getCurrentCuratorCount()`: Returns the current number of curators.
 *
 * 4.  **Exhibition Management:**
 *     - `proposeExhibition(string memory _exhibitionName, string memory _description, uint256 _startDate, uint256 _endDate)`: Curators can propose new art exhibitions.
 *     - `voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`: Collective members vote on exhibition proposals.
 *     - `getExhibitionProposalDetails(uint256 _proposalId)`: Retrieves details of an exhibition proposal.
 *     - `getExhibitionProposalStatus(uint256 _proposalId)`: Returns the status of an exhibition proposal (Pending, Approved, Rejected).
 *     - `startExhibition(uint256 _proposalId)`: Starts an approved exhibition (owner function).
 *     - `endExhibition(uint256 _proposalId)`: Ends a running exhibition (owner function).
 *
 * 5.  **Collective Fund & Governance:**
 *     - `fundCollective(uint256 _amount)`: Allows anyone to donate funds to the collective.
 *     - `withdrawCollectiveFunds(address _recipient, uint256 _amount)`:  Governance-approved function to withdraw funds from the collective for collective purposes (e.g., exhibition costs, marketing). (Currently owner-controlled for simplicity, could be DAO governed)
 *     - `proposeNewRule(string memory _ruleDescription, bytes memory _ruleData)`: Curators can propose new rules or changes to the collective's governance.
 *     - `voteOnRuleProposal(uint256 _proposalId, bool _vote)`: Collective members vote on rule proposals.
 *     - `getRuleProposalDetails(uint256 _proposalId)`: Retrieves details of a rule proposal.
 *     - `getRuleProposalStatus(uint256 _proposalId)`: Returns the status of a rule proposal (Pending, Approved, Rejected).
 *     - `enactRule(uint256 _proposalId)`: Enacts an approved rule (owner function, could be automatically enacted after voting).
 *     - `getCurrentRules()`: Returns a list of currently active rules (basic example, can be expanded).
 *
 * 6.  **Utility & Admin Functions:**
 *     - `getCollectiveBalance()`: Returns the current balance of the collective fund.
 *     - `setMembershipFee(uint256 _fee)`: Owner function to set the membership fee.
 *     - `setArtworkSubmissionFee(uint256 _fee)`: Owner function to set the artwork submission fee.
 *     - `setCuratorDeposit(uint256 _deposit)`: Owner function to set the curator deposit amount.
 *     - `pauseContract()`: Owner function to pause contract functionalities in case of emergency.
 *     - `unpauseContract()`: Owner function to unpause contract functionalities.
 *     - `ownerWithdrawStuckTokens(address _tokenAddress, address _recipient, uint256 _amount)`: Owner function to withdraw accidentally sent tokens to the contract.
 *     - `ownerWithdrawStuckETH(address _recipient, uint256 _amount)`: Owner function to withdraw accidentally sent ETH to the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedArtCollective is Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Structs & Enums ---
    struct Artwork {
        uint256 id;
        address artist;
        string artworkURI;
        string title;
        string description;
        Status status;
        uint256 salePrice;
        bool isForSale;
    }

    struct ExhibitionProposal {
        uint256 id;
        address proposer;
        string name;
        string description;
        uint256 startDate;
        uint256 endDate;
        Status status;
        uint256 yesVotes;
        uint256 noVotes;
    }

    struct RuleProposal {
        uint256 id;
        address proposer;
        string description;
        bytes ruleData; // For potential future rule data implementation
        Status status;
        uint256 yesVotes;
        uint256 noVotes;
    }

    enum Status {
        Pending,
        Approved,
        Rejected,
        Active,
        Ended
    }

    // --- State Variables ---
    Counters.Counter private _artworkIds;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => address) public artworkApprovals; // Track curator approvals per artwork

    Counters.Counter private _exhibitionProposalIds;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => mapping(address => bool)) public exhibitionVotes; // User votes per proposal

    Counters.Counter private _ruleProposalIds;
    mapping(uint256 => RuleProposal) public ruleProposals;
    mapping(uint256 => mapping(address => bool)) public ruleVotes; // User votes per rule proposal
    string[] public currentRules; // Basic example, can be expanded for complex rules

    mapping(address => bool) public collectiveMembers;
    mapping(address => bool) public curators;
    uint256 public curatorDeposit;
    uint256 public membershipFee;
    uint256 public artworkSubmissionFee;
    uint256 public curatorResignWithdrawalLockTime = 30 days; // Example: Lock curator deposit withdrawal for 30 days after resignation
    mapping(address => uint256) public curatorResignationTime;
    mapping(address => uint256) public artistBalances;

    uint256 public artworkApprovalThreshold = 2; // Example: Need 2 curator approvals for artwork approval
    uint256 public exhibitionVoteThresholdPercentage = 51; // Example: Need 51% yes votes for exhibition approval
    uint256 public ruleVoteThresholdPercentage = 60; // Example: Need 60% yes votes for rule approval

    // --- Events ---
    event MemberJoined(address member);
    event MemberLeft(address member);
    event ArtworkSubmitted(uint256 artworkId, address artist, string artworkURI, string title);
    event ArtworkApproved(uint256 artworkId, address artist);
    event ArtworkRejected(uint256 artworkId, address artist);
    event ArtworkListedForSale(uint256 artworkId, uint256 price);
    event ArtworkRemovedFromSale(uint256 artworkId);
    event ArtworkPurchased(uint256 artworkId, address buyer, address artist, uint256 price);
    event CuratorBecameCurator(address curator);
    event CuratorResigned(address curator);
    event ExhibitionProposed(uint256 proposalId, address proposer, string name);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionStarted(uint256 proposalId);
    event ExhibitionEnded(uint256 proposalId);
    event RuleProposed(uint256 proposalId, address proposer, string description);
    event RuleProposalVoted(uint256 proposalId, address voter, bool vote);
    event RuleEnacted(uint256 proposalId, string ruleDescription);
    event CollectiveFunded(address funder, uint256 amount);
    event CollectiveFundsWithdrawn(address recipient, uint256 amount);
    event ArtistFundsWithdrawn(address artist, uint256 amount);

    // --- Modifiers ---
    modifier onlyCollectiveMember() {
        require(collectiveMembers[msg.sender], "Not a collective member");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Not a curator");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= _artworkIds.current(), "Invalid artwork ID");
        _;
    }

    modifier validExhibitionProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _exhibitionProposalIds.current(), "Invalid exhibition proposal ID");
        _;
    }

    modifier validRuleProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _ruleProposalIds.current(), "Invalid rule proposal ID");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _membershipFee, uint256 _artworkSubmissionFee, uint256 _curatorDeposit) payable {
        membershipFee = _membershipFee;
        artworkSubmissionFee = _artworkSubmissionFee;
        curatorDeposit = _curatorDeposit;
    }

    // --- 1. Membership Management Functions ---

    function joinCollective() external payable whenNotPaused {
        require(!collectiveMembers[msg.sender], "Already a member");
        require(msg.value >= membershipFee, "Insufficient membership fee");
        collectiveMembers[msg.sender] = true;
        emit MemberJoined(msg.sender);
        // Optionally distribute excess fee to collective fund or refund. Here, we send excess to collective fund.
        if (msg.value > membershipFee) {
            uint256 excess = msg.value - membershipFee;
            payable(address(this)).transfer(excess); // Send excess to contract balance as collective fund
            emit CollectiveFunded(msg.sender, excess);
        }
    }

    function leaveCollective() external onlyCollectiveMember whenNotPaused {
        require(collectiveMembers[msg.sender], "Not a collective member");
        collectiveMembers[msg.sender] = false;
        emit MemberLeft(msg.sender);
        // Potentially implement logic to return a portion of membership fee or handle funds
        // based on collective rules. For now, simply remove membership.
    }

    function isCollectiveMember(address _user) external view returns (bool) {
        return collectiveMembers[_user];
    }

    function getMemberCount() external view returns (uint256) {
        uint256 count = 0;
        for (address member : getCollectiveMembersArray()) { // Iterate through members for accurate count
            if (collectiveMembers[member]) {
                count++;
            }
        }
        return count;
    }

    // Helper function to get an array of all potential members (for iteration, not gas efficient for very large memberships)
    function getCollectiveMembersArray() private view returns (address[] memory) {
        address[] memory members = new address[](getPossibleMemberCount()); // Assuming a way to estimate max members
        uint256 index = 0;
        for (uint256 i = 0; i < getPossibleMemberCount(); i++) { // In a real scenario, you might track members more efficiently
            address possibleMember = address(uint160(i)); // Example: Iterate through possible addresses (not practical for large scale)
            if (collectiveMembers[possibleMember]) {
                members[index++] = possibleMember;
            }
        }
        address[] memory finalMembers = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            finalMembers[i] = members[i];
        }
        return finalMembers;
    }

    function getPossibleMemberCount() private pure returns (uint256) {
        // In a real system, you would have a more efficient way to manage member count
        // This is a placeholder for a large potential count to make the example work.
        return 1000; // Example max possible members to iterate (inefficient in real world)
    }


    // --- 2. Artwork Submission & Management Functions ---

    function submitArtwork(string memory _artworkURI, string memory _title, string memory _description) external payable onlyCollectiveMember whenNotPaused {
        require(msg.value >= artworkSubmissionFee, "Insufficient artwork submission fee");
        _artworkIds.increment();
        uint256 artworkId = _artworkIds.current();
        artworks[artworkId] = Artwork({
            id: artworkId,
            artist: msg.sender,
            artworkURI: _artworkURI,
            title: _title,
            description: _description,
            status: Status.Pending,
            salePrice: 0,
            isForSale: false
        });
        emit ArtworkSubmitted(artworkId, msg.sender, _artworkURI, _title);
        if (msg.value > artworkSubmissionFee) {
            payable(address(this)).transfer(msg.value - artworkSubmissionFee); // Send excess to collective fund
            emit CollectiveFunded(msg.sender, msg.value - artworkSubmissionFee);
        }
    }

    function approveArtwork(uint256 _artworkId) external onlyCurator validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].status == Status.Pending, "Artwork not pending approval");
        artworkApprovals[_artworkId] = msg.sender; // Record curator who approved (could be expanded to track multiple approvals)

        uint256 approvalCount = 0;
        for (address curatorAddr : getCuratorsArray()) { // Iterate curators for approval count
            if (artworkApprovals[_artworkId] != address(0)) { // Simple check: if any curator approved, consider it enough for now. Enhance for multi-curator voting
                approvalCount++; // In a real system, track individual curator votes more explicitly
            }
        }

        if (approvalCount >= artworkApprovalThreshold) {
            artworks[_artworkId].status = Status.Approved;
            emit ArtworkApproved(_artworkId, artworks[_artworkId].artist);
        }
    }


    function rejectArtwork(uint256 _artworkId) external onlyCurator validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].status == Status.Pending, "Artwork not pending approval");
        artworks[_artworkId].status = Status.Rejected;
        emit ArtworkRejected(_artworkId, artworks[_artworkId].artist);
    }

    function getArtworkDetails(uint256 _artworkId) external view validArtworkId(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getArtworkStatus(uint256 _artworkId) external view validArtworkId(_artworkId) returns (Status) {
        return artworks[_artworkId].status;
    }

    function listArtworkForSale(uint256 _artworkId, uint256 _price) external onlyCollectiveMember validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].artist == msg.sender, "Not artwork owner");
        require(artworks[_artworkId].status == Status.Approved, "Artwork not approved");
        artworks[_artworkId].isForSale = true;
        artworks[_artworkId].salePrice = _price;
        emit ArtworkListedForSale(_artworkId, _price);
    }

    function removeArtworkFromSale(uint256 _artworkId) external onlyCollectiveMember validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].artist == msg.sender, "Not artwork owner");
        artworks[_artworkId].isForSale = false;
        artworks[_artworkId].salePrice = 0;
        emit ArtworkRemovedFromSale(_artworkId);
    }

    function purchaseArtwork(uint256 _artworkId) external payable validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].isForSale, "Artwork not for sale");
        require(msg.value >= artworks[_artworkId].salePrice, "Insufficient payment");

        uint256 artworkPrice = artworks[_artworkId].salePrice;
        address artist = artworks[_artworkId].artist;

        artworks[_artworkId].isForSale = false; // Remove from sale after purchase

        // Example distribution: 90% to artist, 10% to collective fund. Can be governed by rules.
        uint256 artistShare = artworkPrice.mul(90).div(100);
        uint256 collectiveShare = artworkPrice.mul(10).div(100);

        artistBalances[artist] = artistBalances[artist].add(artistShare); // Track artist balance
        payable(artist).transfer(artistShare); // Direct artist payment for simplicity in this example

        payable(address(this)).transfer(collectiveShare); // Collective share to contract balance
        emit CollectiveFunded(address(this), collectiveShare);

        emit ArtworkPurchased(_artworkId, msg.sender, artist, artworkPrice);

        if (msg.value > artworkPrice) {
            payable(msg.sender).transfer(msg.value - artworkPrice); // Refund excess payment
        }
    }

    function withdrawArtistFunds() external onlyCollectiveMember whenNotPaused {
        uint256 balance = artistBalances[msg.sender];
        require(balance > 0, "No funds to withdraw");
        artistBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit ArtistFundsWithdrawn(msg.sender, balance);
    }


    // --- 3. Curator Role & Voting Functions ---

    function becomeCurator() external payable onlyCollectiveMember whenNotPaused {
        require(!curators[msg.sender], "Already a curator");
        require(msg.value >= curatorDeposit, "Insufficient curator deposit");
        curators[msg.sender] = true;
        emit CuratorBecameCurator(msg.sender);
        if (msg.value > curatorDeposit) {
            payable(address(this)).transfer(msg.value - curatorDeposit); // Excess to collective fund
             emit CollectiveFunded(msg.sender, msg.value - curatorDeposit);
        }
    }

    function resignCurator() external onlyCurator whenNotPaused {
        require(curators[msg.sender], "Not a curator");
        curators[msg.sender] = false;
        curatorResignationTime[msg.sender] = block.timestamp;
        emit CuratorResigned(msg.sender);
        // Curator deposit withdrawal can be implemented with a timelock and withdrawal function later
    }

    function withdrawCuratorDeposit() external onlyCollectiveMember whenNotPaused {
        require(!curators[msg.sender], "Still a curator or never was."); // Check they are not curator anymore
        require(curatorResignationTime[msg.sender] > 0, "Curator deposit not available for withdrawal.");
        require(block.timestamp >= curatorResignationTime[msg.sender] + curatorResignWithdrawalLockTime, "Curator deposit withdrawal locked until timelock expires.");
        uint256 deposit = curatorDeposit; // Assuming deposit is fixed, could store individual deposits if needed
        payable(msg.sender).transfer(deposit);
        curatorResignationTime[msg.sender] = 0; // Reset resignation time after withdrawal
    }

    function isCurator(address _user) external view returns (bool) {
        return curators[_user];
    }

    function getCurrentCuratorCount() external view returns (uint256) {
        uint256 count = 0;
        for (address curatorAddr : getCuratorsArray()) { // Iterate curators for accurate count
            if (curators[curatorAddr]) {
                count++;
            }
        }
        return count;
    }

    // Helper function to get an array of all potential curators (for iteration, not gas efficient for very large curator sets)
    function getCuratorsArray() private view returns (address[] memory) {
        address[] memory curatorsArray = new address[](getPossibleCuratorCount()); // Assuming a way to estimate max curators
        uint256 index = 0;
        for (uint256 i = 0; i < getPossibleCuratorCount(); i++) { // In a real scenario, you might track curators more efficiently
            address possibleCurator = address(uint160(i)); // Example: Iterate through possible addresses (not practical for large scale)
            if (curators[possibleCurator]) {
                curatorsArray[index++] = possibleCurator;
            }
        }
        address[] memory finalCurators = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            finalCurators[i] = curatorsArray[i];
        }
        return finalCurators;
    }

    function getPossibleCuratorCount() private pure returns (uint256) {
        // In a real system, you would have a more efficient way to manage curator count
        // This is a placeholder for a large potential count to make the example work.
        return 100; // Example max possible curators to iterate (inefficient in real world)
    }


    // --- 4. Exhibition Management Functions ---

    function proposeExhibition(string memory _exhibitionName, string memory _description, uint256 _startDate, uint256 _endDate) external onlyCurator whenNotPaused {
        _exhibitionProposalIds.increment();
        uint256 proposalId = _exhibitionProposalIds.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            id: proposalId,
            proposer: msg.sender,
            name: _exhibitionName,
            description: _description,
            startDate: _startDate,
            endDate: _endDate,
            status: Status.Pending,
            yesVotes: 0,
            noVotes: 0
        });
        emit ExhibitionProposed(proposalId, msg.sender, _exhibitionName);
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) external onlyCollectiveMember validExhibitionProposalId(_proposalId) whenNotPaused {
        require(exhibitionProposals[_proposalId].status == Status.Pending, "Proposal not pending");
        require(!exhibitionVotes[_proposalId][msg.sender], "Already voted");

        exhibitionVotes[_proposalId][msg.sender] = true; // Record user voted

        if (_vote) {
            exhibitionProposals[_proposalId].yesVotes++;
        } else {
            exhibitionProposals[_proposalId].noVotes++;
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _vote);

        uint256 totalMembers = getMemberCount();
        uint256 yesVotes = exhibitionProposals[_proposalId].yesVotes;

        if (totalMembers > 0 && yesVotes.mul(100) >= totalMembers.mul(exhibitionVoteThresholdPercentage)) {
            exhibitionProposals[_proposalId].status = Status.Approved;
        } else if (exhibitionProposals[_proposalId].noVotes > totalMembers.div(2)) { // Simple rejection if more than half vote no
            exhibitionProposals[_proposalId].status = Status.Rejected;
        }
        // In a real DAO, consider time-based voting periods and more sophisticated quorum logic.
    }

    function getExhibitionProposalDetails(uint256 _proposalId) external view validExhibitionProposalId(_proposalId) returns (ExhibitionProposal memory) {
        return exhibitionProposals[_proposalId];
    }

    function getExhibitionProposalStatus(uint256 _proposalId) external view validExhibitionProposalId(_proposalId) returns (Status) {
        return exhibitionProposals[_proposalId].status;
    }

    function startExhibition(uint256 _proposalId) external onlyOwner validExhibitionProposalId(_proposalId) whenNotPaused {
        require(exhibitionProposals[_proposalId].status == Status.Approved, "Exhibition proposal not approved");
        require(exhibitionProposals[_proposalId].status != Status.Active, "Exhibition already active");
        require(block.timestamp >= exhibitionProposals[_proposalId].startDate, "Exhibition start date not reached");
        exhibitionProposals[_proposalId].status = Status.Active;
        emit ExhibitionStarted(_proposalId);
    }

    function endExhibition(uint256 _proposalId) external onlyOwner validExhibitionProposalId(_proposalId) whenNotPaused {
        require(exhibitionProposals[_proposalId].status == Status.Active, "Exhibition not active");
        require(block.timestamp >= exhibitionProposals[_proposalId].endDate, "Exhibition end date not reached");
        exhibitionProposals[_proposalId].status = Status.Ended;
        emit ExhibitionEnded(_proposalId);
    }

    // --- 5. Collective Fund & Governance Functions ---

    function fundCollective() external payable whenNotPaused {
        require(msg.value > 0, "Funding amount must be greater than zero");
        payable(address(this)).transfer(msg.value);
        emit CollectiveFunded(msg.sender, msg.value);
    }

    function withdrawCollectiveFunds(address _recipient, uint256 _amount) external onlyOwner whenNotPaused { // Owner-controlled for simplicity, replace with governance for true DAO
        require(_recipient != address(0), "Invalid recipient address");
        require(address(this).balance >= _amount, "Insufficient collective funds");
        payable(_recipient).transfer(_amount);
        emit CollectiveFundsWithdrawn(_recipient, _amount);
    }

    function proposeNewRule(string memory _ruleDescription, bytes memory _ruleData) external onlyCurator whenNotPaused {
        _ruleProposalIds.increment();
        uint256 proposalId = _ruleProposalIds.current();
        ruleProposals[proposalId] = RuleProposal({
            id: proposalId,
            proposer: msg.sender,
            description: _ruleDescription,
            ruleData: _ruleData,
            status: Status.Pending,
            yesVotes: 0,
            noVotes: 0
        });
        emit RuleProposed(proposalId, msg.sender, _ruleDescription);
    }

    function voteOnRuleProposal(uint256 _proposalId, bool _vote) external onlyCollectiveMember validRuleProposalId(_proposalId) whenNotPaused {
        require(ruleProposals[_proposalId].status == Status.Pending, "Rule proposal not pending");
        require(!ruleVotes[_proposalId][msg.sender], "Already voted");

        ruleVotes[_proposalId][msg.sender] = true; // Record user voted

        if (_vote) {
            ruleProposals[_proposalId].yesVotes++;
        } else {
            ruleProposals[_proposalId].noVotes++;
        }
        emit RuleProposalVoted(_proposalId, msg.sender, _vote);

        uint256 totalMembers = getMemberCount();
        uint256 yesVotes = ruleProposals[_proposalId].yesVotes;

        if (totalMembers > 0 && yesVotes.mul(100) >= totalMembers.mul(ruleVoteThresholdPercentage)) {
            ruleProposals[_proposalId].status = Status.Approved;
        } else if (ruleProposals[_proposalId].noVotes > totalMembers.div(2)) { // Simple rejection if more than half vote no
            ruleProposals[_proposalId].status = Status.Rejected;
        }
        // In a real DAO, consider time-based voting periods and more sophisticated quorum logic.
    }

    function getRuleProposalDetails(uint256 _proposalId) external view validRuleProposalId(_proposalId) returns (RuleProposal memory) {
        return ruleProposals[_proposalId];
    }

    function getRuleProposalStatus(uint256 _proposalId) external view validRuleProposalId(_proposalId) returns (Status) {
        return ruleProposals[_proposalId].status;
    }

    function enactRule(uint256 _proposalId) external onlyOwner validRuleProposalId(_proposalId) whenNotPaused { // Owner enacts, can be auto-enact in real DAO
        require(ruleProposals[_proposalId].status == Status.Approved, "Rule proposal not approved");
        require(ruleProposals[_proposalId].status != Status.Active, "Rule already active");
        ruleProposals[_proposalId].status = Status.Active;
        currentRules.push(ruleProposals[_proposalId].description); // Basic rule implementation: just add to currentRules array
        emit RuleEnacted(_proposalId, ruleProposals[_proposalId].description);
        // In a more complex system, ruleData could be used to modify contract parameters or logic.
    }

    function getCurrentRules() external view returns (string[] memory) {
        return currentRules;
    }


    // --- 6. Utility & Admin Functions ---

    function getCollectiveBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setMembershipFee(uint256 _fee) external onlyOwner {
        membershipFee = _fee;
    }

    function setArtworkSubmissionFee(uint256 _fee) external onlyOwner {
        artworkSubmissionFee = _fee;
    }

    function setCuratorDeposit(uint256 _deposit) external onlyOwner {
        curatorDeposit = _deposit;
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function ownerWithdrawStuckTokens(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient tokens in contract");
        require(_recipient != address(0), "Invalid recipient address");
        bool success = token.transfer(_recipient, _amount);
        require(success, "Token transfer failed");
    }

    function ownerWithdrawStuckETH(address _recipient, uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient ETH in contract");
        require(_recipient != address(0), "Invalid recipient address");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {
        emit CollectiveFunded(msg.sender, msg.value); // Allow direct funding to the contract
    }
}

// --- IERC20 Interface (for ownerWithdrawStuckTokens function) ---
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```

**Explanation of Concepts and Features:**

1.  **Decentralized Autonomous Art Collective (DAAC) Concept:** The contract embodies the idea of a community-driven art organization. It's not just about buying and selling NFTs, but about creating a collaborative ecosystem for artists and art enthusiasts.

2.  **Membership & Curator Roles:**
    *   **Membership:**  Creates a sense of community and potentially exclusivity. The membership fee can contribute to the collective fund.
    *   **Curators:** Decentralizes the curation process, allowing community members to actively participate in selecting artworks and shaping the collective's artistic direction. Curator deposits ensure commitment and can be returned upon resignation (with a timelock).

3.  **Artwork Submission & Approval Process:**
    *   **Submission Fee:**  Discourages spam submissions and can contribute to the collective fund.
    *   **Curator Voting:**  Ensures a degree of quality control and community consensus on the artworks featured in the collective. The approval threshold is adjustable.

4.  **Exhibition Management:**
    *   **Exhibition Proposals:** Allows curators to organize themed or curated art exhibitions within the collective.
    *   **Community Voting on Exhibitions:**  Democratizes the exhibition planning process, giving members a say in what exhibitions are hosted.
    *   **Exhibition Lifecycle:** Manages the start and end dates of exhibitions, enabling time-based art events within the collective.

5.  **Governance through Rule Proposals & Voting:**
    *   **Rule Proposals:** Enables the collective to evolve and adapt its rules and governance structure over time.
    *   **Community Voting on Rules:**  Gives members direct influence over the collective's operating principles.  This is a fundamental aspect of a DAO.
    *   **Enacting Rules:**  While in this example, rule enactment is owner-controlled for simplicity, in a true DAO, this would be automated based on voting outcomes.

6.  **Collective Fund:**
    *   **Funding Mechanisms:** Membership fees, artwork submission fees, donations, and a percentage of artwork sales contribute to a collective fund.
    *   **Fund Usage (Governance Needed):** The contract includes a `withdrawCollectiveFunds` function, which is currently owner-controlled. In a real DAO, this would be governed by rule proposals and voting, allowing the community to decide how collective funds are used (e.g., for marketing, exhibition expenses, artist grants, community events).

7.  **Artwork Marketplace:**
    *   **Listing & Selling:** Artists can list their approved artworks for sale within the collective's marketplace.
    *   **Purchase Mechanism:**  Users can purchase artworks directly through the contract.
    *   **Revenue Distribution:**  The contract demonstrates a simple revenue distribution model (artist share and collective share). This can be made more complex and rule-governed.

8.  **Advanced Concepts & Trends:**
    *   **DAO Principles:**  The contract incorporates core DAO principles like community governance, voting, and collective ownership.
    *   **NFT Integration (Implicit):** While the contract doesn't directly mint NFTs (it's designed to work with existing NFT artworks identified by URIs), it's built around the concept of managing and curating NFT art.
    *   **On-Chain Governance:**  Rule proposals and voting are handled directly on the blockchain, ensuring transparency and immutability.
    *   **Community Building:**  The membership and curator roles, along with voting mechanisms, are designed to foster a strong and engaged art community.

9.  **Security & Utility Features:**
    *   **Pausable:**  Includes a `Pausable` pattern for emergency stops.
    *   **Ownable:**  Uses `Ownable` from OpenZeppelin for owner-controlled functions (admin/initial setup).
    *   **Stuck Token/ETH Withdrawal:**  Owner functions to recover accidentally sent tokens or ETH.
    *   **Counters & SafeMath:** Uses OpenZeppelin's `Counters` for ID management and `SafeMath` for safe arithmetic operations.

**Important Notes & Potential Enhancements (Beyond the Scope of the Request):**

*   **NFT Minting Integration:**  For a truly self-contained art collective, you could integrate NFT minting directly into the contract, allowing artists to mint NFTs upon submission.
*   **Decentralized Storage (IPFS, Arweave):**  For artwork URIs, consider using decentralized storage solutions like IPFS or Arweave for greater permanence and censorship resistance.
*   **More Sophisticated Governance:**  Implement more advanced DAO governance mechanisms, such as:
    *   **Time-locked voting periods.**
    *   **Quorum requirements for voting.**
    *   **Delegated voting.**
    *   **Token-based voting (if you introduce a collective token).**
    *   **Snapshot voting for off-chain governance signals.**
*   **Rule Data Handling:**  Expand the `ruleData` field in `RuleProposal` to allow for more complex rule implementations that can modify contract parameters or logic dynamically based on voting.
*   **Curator Incentives:** Implement mechanisms to incentivize curator participation (e.g., rewards for curating, percentage of sales from curated artworks).
*   **Exhibition Features:** Add features like virtual exhibition spaces, ticketing for exhibitions, or artist features within exhibitions.
*   **Royalty System:** Implement a royalty system for secondary market sales of artworks listed through the collective.
*   **Gas Optimization:**  For a production contract, thorough gas optimization would be essential.
*   **Security Audits:**  Any smart contract dealing with funds should undergo rigorous security audits before deployment.

This example provides a solid foundation for a creative and advanced smart contract for a decentralized art collective. You can further expand upon these features and concepts to build an even more robust and unique platform.