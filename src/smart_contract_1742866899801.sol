```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @notice A smart contract for a Decentralized Autonomous Art Collective, enabling artists to submit artworks,
 * members to vote on submissions, mint NFTs for approved artworks, manage a collective treasury,
 * organize art challenges, and foster community interaction.
 *
 * Function Summary:
 *
 * **Artwork Management:**
 * 1. submitArtworkProposal(string memory _title, string memory _description, string memory _ipfsHash, uint256 _royaltyPercentage): Allows members to submit artwork proposals.
 * 2. voteOnArtworkProposal(uint256 _proposalId, bool _vote): Allows members to vote on artwork proposals.
 * 3. getArtworkProposalDetails(uint256 _proposalId): Returns details of a specific artwork proposal.
 * 4. mintArtworkNFT(uint256 _proposalId): Mints an NFT for an approved artwork proposal, callable by contract owner or admin.
 * 5. setArtworkRoyalties(uint256 _tokenId, uint256 _royaltyPercentage): Sets the royalty percentage for an artwork NFT, callable by the original artist.
 * 6. getArtworkRoyalties(uint256 _tokenId): Retrieves the current royalty percentage for an artwork NFT.
 * 7. transferArtworkOwnership(uint256 _tokenId, address _newOwner): Allows the current owner of an artwork NFT to transfer ownership, triggering royalty payments.
 * 8. burnArtworkNFT(uint256 _tokenId): Allows the original artist to burn their artwork NFT (with governance or admin control).
 *
 * **Membership & Governance:**
 * 9. purchaseMembership(): Allows users to purchase membership to the DAAC.
 * 10. renounceMembership(): Allows members to renounce their membership (and potentially get a refund based on governance).
 * 11. proposeNewRule(string memory _ruleDescription): Allows members to propose new rules for the collective.
 * 12. voteOnRuleProposal(uint256 _ruleProposalId, bool _vote): Allows members to vote on rule proposals.
 * 13. getRuleProposalDetails(uint256 _ruleProposalId): Returns details of a specific rule proposal.
 * 14. executeRule(uint256 _ruleProposalId): Executes an approved rule proposal, callable by contract owner or admin.
 * 15. setMembershipFee(uint256 _newFee): Allows the contract owner to set the membership fee.
 *
 * **Treasury Management:**
 * 16. fundCollective(): Allows anyone to contribute funds to the collective treasury.
 * 17. proposeExpenditure(address _recipient, uint256 _amount, string memory _reason): Allows members to propose expenditures from the treasury.
 * 18. voteOnExpenditureProposal(uint256 _expenditureProposalId, bool _vote): Allows members to vote on expenditure proposals.
 * 19. getExpenditureProposalDetails(uint256 _expenditureProposalId): Returns details of a specific expenditure proposal.
 * 20. executeExpenditure(uint256 _expenditureProposalId): Executes an approved expenditure proposal, callable by contract owner or admin.
 * 21. getTreasuryBalance(): Returns the current balance of the collective treasury.
 *
 * **Community & Challenges:**
 * 22. createArtChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _deadline): Allows members to create art challenges.
 * 23. submitChallengeEntry(uint256 _challengeId, string memory _entryDescription, string memory _ipfsHash): Allows members to submit entries to an art challenge.
 * 24. voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId, bool _vote): Allows members to vote on entries in an art challenge.
 * 25. getChallengeDetails(uint256 _challengeId): Returns details of a specific art challenge.
 * 26. getChallengeEntryDetails(uint256 _challengeId, uint256 _entryId): Returns details of a specific entry in an art challenge.
 */

contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    address public owner;
    string public contractName = "Decentralized Autonomous Art Collective";
    uint256 public membershipFee = 0.1 ether; // Example fee
    uint256 public proposalVotingDuration = 7 days; // Example voting duration

    uint256 public nextArtworkProposalId = 0;
    mapping(uint256 => ArtworkProposal) public artworkProposals;
    uint256 public nextRuleProposalId = 0;
    mapping(uint256 => RuleProposal) public ruleProposals;
    uint256 public nextExpenditureProposalId = 0;
    mapping(uint256 => ExpenditureProposal) public expenditureProposals;
    uint256 public nextChallengeId = 0;
    mapping(uint256 => ArtChallenge) public artChallenges;

    mapping(address => bool) public members;
    mapping(uint256 => address) public artworkTokenToArtist;
    mapping(uint256 => uint256) public artworkRoyalties; // TokenId => Royalty Percentage
    uint256 public nextArtworkTokenId = 1; // Start NFT token IDs from 1

    // --- Structs ---

    struct ArtworkProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 royaltyPercentage;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 proposalEndTime;
        bool executed;
    }

    struct RuleProposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 proposalEndTime;
        bool executed;
    }

    struct ExpenditureProposal {
        uint256 id;
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 proposalEndTime;
        bool executed;
    }

    struct ArtChallenge {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 deadline;
        uint256 nextEntryId;
        mapping(uint256 => ChallengeEntry) challengeEntries;
    }

    struct ChallengeEntry {
        uint256 id;
        address submitter;
        string description;
        string ipfsHash;
        uint256 voteCountYes;
        uint256 voteCountNo;
    }

    // --- Events ---

    event MembershipPurchased(address indexed member);
    event MembershipRenounced(address indexed member);
    event ArtworkProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtworkMinted(uint256 tokenId, uint256 proposalId, address artist);
    event ArtworkRoyaltiesSet(uint256 tokenId, uint256 royaltyPercentage);
    event ArtworkOwnershipTransferred(uint256 tokenId, address from, address to, uint256 royaltyAmount);
    event ArtworkBurned(uint256 tokenId, address artist);
    event RuleProposalSubmitted(uint256 proposalId, address proposer, string description);
    event RuleProposalVoted(uint256 proposalId, address voter, bool vote);
    event RuleExecuted(uint256 proposalId);
    event ExpenditureProposalSubmitted(uint256 proposalId, address proposer, address recipient, uint256 amount);
    event ExpenditureProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExpenditureExecuted(uint256 proposalId, address recipient, uint256 amount);
    event CollectiveFunded(address contributor, uint256 amount);
    event ArtChallengeCreated(uint256 challengeId, address creator, string title);
    event ChallengeEntrySubmitted(uint256 challengeId, uint256 entryId, address submitter);
    event ChallengeEntryVoted(uint256 challengeId, uint256 entryId, address voter, bool vote);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < nextArtworkProposalId, "Invalid proposal ID.");
        _;
    }

    modifier validRuleProposalId(uint256 _ruleProposalId) {
        require(_ruleProposalId < nextRuleProposalId, "Invalid rule proposal ID.");
        _;
    }

    modifier validExpenditureProposalId(uint256 _expenditureProposalId) {
        require(_expenditureProposalId < nextExpenditureProposalId, "Invalid expenditure proposal ID.");
        _;
    }

    modifier validChallengeId(uint256 _challengeId) {
        require(_challengeId < nextChallengeId, "Invalid challenge ID.");
        _;
    }

    modifier validChallengeEntryId(uint256 _challengeId, uint256 _entryId) {
        require(artChallenges[_challengeId].challengeEntries[_entryId].submitter != address(0), "Invalid challenge entry ID.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!artworkProposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier ruleProposalNotExecuted(uint256 _ruleProposalId) {
        require(!ruleProposals[_ruleProposalId].executed, "Rule proposal already executed.");
        _;
    }

    modifier expenditureProposalNotExecuted(uint256 _expenditureProposalId) {
        require(!expenditureProposals[_expenditureProposalId].executed, "Expenditure proposal already executed.");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.timestamp < artworkProposals[_proposalId].proposalEndTime, "Voting period has ended.");
        _;
    }

    modifier ruleVotingPeriodActive(uint256 _ruleProposalId) {
        require(block.timestamp < ruleProposals[_ruleProposalId].proposalEndTime, "Rule voting period has ended.");
        _;
    }

    modifier expenditureVotingPeriodActive(uint256 _expenditureProposalId) {
        require(block.timestamp < expenditureProposals[_expenditureProposalId].proposalEndTime, "Expenditure voting period has ended.");
        _;
    }

    modifier artworkExists(uint256 _tokenId) {
        require(artworkTokenToArtist[_tokenId] != address(0), "Artwork NFT does not exist.");
        _;
    }

    modifier isArtworkOwner(uint256 _tokenId) {
        require(artworkTokenToArtist[_tokenId] == msg.sender, "You are not the owner of this artwork.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- Artwork Management Functions ---

    /// @notice Allows members to submit artwork proposals.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork's media.
    /// @param _royaltyPercentage Royalty percentage for the artwork (0-100).
    function submitArtworkProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _royaltyPercentage
    ) public onlyMember {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        artworkProposals[nextArtworkProposalId] = ArtworkProposal({
            id: nextArtworkProposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            royaltyPercentage: _royaltyPercentage,
            voteCountYes: 0,
            voteCountNo: 0,
            proposalEndTime: block.timestamp + proposalVotingDuration,
            executed: false
        });
        emit ArtworkProposalSubmitted(nextArtworkProposalId, msg.sender, _title);
        nextArtworkProposalId++;
    }

    /// @notice Allows members to vote on artwork proposals.
    /// @param _proposalId ID of the artwork proposal.
    /// @param _vote True for yes, false for no.
    function voteOnArtworkProposal(uint256 _proposalId, bool _vote)
        public
        onlyMember
        validProposalId(_proposalId)
        proposalNotExecuted(_proposalId)
        votingPeriodActive(_proposalId)
    {
        if (_vote) {
            artworkProposals[_proposalId].voteCountYes++;
        } else {
            artworkProposals[_proposalId].voteCountNo++;
        }
        emit ArtworkProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Returns details of a specific artwork proposal.
    /// @param _proposalId ID of the artwork proposal.
    /// @return ArtworkProposal struct containing proposal details.
    function getArtworkProposalDetails(uint256 _proposalId)
        public
        view
        validProposalId(_proposalId)
        returns (ArtworkProposal memory)
    {
        return artworkProposals[_proposalId];
    }

    /// @notice Mints an NFT for an approved artwork proposal, callable by contract owner or admin.
    /// @param _proposalId ID of the artwork proposal.
    function mintArtworkNFT(uint256 _proposalId)
        public
        onlyOwner // Or could be a governance function to execute if proposal passes
        validProposalId(_proposalId)
        proposalNotExecuted(_proposalId)
    {
        require(block.timestamp >= artworkProposals[_proposalId].proposalEndTime, "Voting period not ended yet.");
        require(artworkProposals[_proposalId].voteCountYes > artworkProposals[_proposalId].voteCountNo, "Proposal not approved.");

        address artist = artworkProposals[_proposalId].proposer;
        artworkTokenToArtist[nextArtworkTokenId] = artist;
        artworkRoyalties[nextArtworkTokenId] = artworkProposals[_proposalId].royaltyPercentage;
        artworkProposals[_proposalId].executed = true;

        emit ArtworkMinted(nextArtworkTokenId, _proposalId, artist);
        nextArtworkTokenId++;
    }

    /// @notice Sets the royalty percentage for an artwork NFT, callable by the original artist.
    /// @param _tokenId ID of the artwork NFT.
    /// @param _royaltyPercentage Royalty percentage for the artwork (0-100).
    function setArtworkRoyalties(uint256 _tokenId, uint256 _royaltyPercentage)
        public
        isArtworkOwner(_tokenId)
        artworkExists(_tokenId)
    {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        artworkRoyalties[_tokenId] = _royaltyPercentage;
        emit ArtworkRoyaltiesSet(_tokenId, _royaltyPercentage);
    }

    /// @notice Retrieves the current royalty percentage for an artwork NFT.
    /// @param _tokenId ID of the artwork NFT.
    /// @return Royalty percentage.
    function getArtworkRoyalties(uint256 _tokenId) public view artworkExists(_tokenId) returns (uint256) {
        return artworkRoyalties[_tokenId];
    }

    /// @notice Allows the current owner of an artwork NFT to transfer ownership, triggering royalty payments.
    /// @param _tokenId ID of the artwork NFT.
    /// @param _newOwner Address of the new owner.
    function transferArtworkOwnership(uint256 _tokenId, address _newOwner)
        public
        artworkExists(_tokenId)
    {
        address currentOwner = artworkTokenToArtist[_tokenId];
        require(currentOwner == msg.sender, "You are not the current owner.");
        require(_newOwner != address(0), "New owner address cannot be zero.");

        uint256 royaltyPercentage = artworkRoyalties[_tokenId];
        address originalArtist = artworkTokenToArtist[_tokenId];
        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 100; // Royalty based on transfer value (msg.value)

        if (royaltyAmount > 0) {
            (bool success, ) = originalArtist.call{value: royaltyAmount}("");
            require(success, "Royalty payment failed.");
        }

        artworkTokenToArtist[_tokenId] = _newOwner;
        emit ArtworkOwnershipTransferred(_tokenId, currentOwner, _newOwner, royaltyAmount);
    }

    /// @notice Allows the original artist to burn their artwork NFT (with governance or admin control).
    /// @param _tokenId ID of the artwork NFT.
    function burnArtworkNFT(uint256 _tokenId) public isArtworkOwner(_tokenId) artworkExists(_tokenId) {
        delete artworkTokenToArtist[_tokenId];
        delete artworkRoyalties[_tokenId];
        emit ArtworkBurned(_tokenId, msg.sender);
    }


    // --- Membership & Governance Functions ---

    /// @notice Allows users to purchase membership to the DAAC.
    function purchaseMembership() public payable {
        require(msg.value >= membershipFee, "Insufficient membership fee.");
        members[msg.sender] = true;
        emit MembershipPurchased(msg.sender);
        // Optionally, send excess ether back to the sender if msg.value > membershipFee
        if (msg.value > membershipFee) {
            (bool success, ) = msg.sender.call{value: msg.value - membershipFee}("");
            require(success, "Refund failed.");
        }
    }

    /// @notice Allows members to renounce their membership (and potentially get a refund based on governance).
    function renounceMembership() public onlyMember {
        delete members[msg.sender];
        emit MembershipRenounced(msg.sender);
        // Refund logic could be added here based on governance proposals if needed.
    }

    /// @notice Allows members to propose new rules for the collective.
    /// @param _ruleDescription Description of the new rule.
    function proposeNewRule(string memory _ruleDescription) public onlyMember {
        ruleProposals[nextRuleProposalId] = RuleProposal({
            id: nextRuleProposalId,
            proposer: msg.sender,
            description: _ruleDescription,
            voteCountYes: 0,
            voteCountNo: 0,
            proposalEndTime: block.timestamp + proposalVotingDuration,
            executed: false
        });
        emit RuleProposalSubmitted(nextRuleProposalId, msg.sender, _ruleDescription);
        nextRuleProposalId++;
    }

    /// @notice Allows members to vote on rule proposals.
    /// @param _ruleProposalId ID of the rule proposal.
    /// @param _vote True for yes, false for no.
    function voteOnRuleProposal(uint256 _ruleProposalId, bool _vote)
        public
        onlyMember
        validRuleProposalId(_ruleProposalId)
        ruleProposalNotExecuted(_ruleProposalId)
        ruleVotingPeriodActive(_ruleProposalId)
    {
        if (_vote) {
            ruleProposals[_ruleProposalId].voteCountYes++;
        } else {
            ruleProposals[_ruleProposalId].voteCountNo++;
        }
        emit RuleProposalVoted(_ruleProposalId, msg.sender, _vote);
    }

    /// @notice Returns details of a specific rule proposal.
    /// @param _ruleProposalId ID of the rule proposal.
    /// @return RuleProposal struct containing proposal details.
    function getRuleProposalDetails(uint256 _ruleProposalId)
        public
        view
        validRuleProposalId(_ruleProposalId)
        returns (RuleProposal memory)
    {
        return ruleProposals[_ruleProposalId];
    }

    /// @notice Executes an approved rule proposal, callable by contract owner or admin.
    /// @param _ruleProposalId ID of the rule proposal.
    function executeRule(uint256 _ruleProposalId)
        public
        onlyOwner // Or could be governance executed
        validRuleProposalId(_ruleProposalId)
        ruleProposalNotExecuted(_ruleProposalId)
    {
        require(block.timestamp >= ruleProposals[_ruleProposalId].proposalEndTime, "Rule voting period not ended yet.");
        require(ruleProposals[_ruleProposalId].voteCountYes > ruleProposals[_ruleProposalId].voteCountNo, "Rule proposal not approved.");

        ruleProposals[_ruleProposalId].executed = true;
        emit RuleExecuted(_ruleProposalId);
        // Rule logic would be implemented here depending on the type of rules.
        // For example, updating contract parameters, etc.
    }

    /// @notice Allows the contract owner to set the membership fee.
    /// @param _newFee The new membership fee in ether.
    function setMembershipFee(uint256 _newFee) public onlyOwner {
        membershipFee = _newFee;
    }


    // --- Treasury Management Functions ---

    /// @notice Allows anyone to contribute funds to the collective treasury.
    function fundCollective() public payable {
        emit CollectiveFunded(msg.sender, msg.value);
    }

    /// @notice Proposes an expenditure from the treasury.
    /// @param _recipient Address to receive the funds.
    /// @param _amount Amount to be spent in wei.
    /// @param _reason Reason for the expenditure.
    function proposeExpenditure(address _recipient, uint256 _amount, string memory _reason) public onlyMember {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(_amount > 0, "Expenditure amount must be greater than zero.");
        expenditureProposals[nextExpenditureProposalId] = ExpenditureProposal({
            id: nextExpenditureProposalId,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            voteCountYes: 0,
            voteCountNo: 0,
            proposalEndTime: block.timestamp + proposalVotingDuration,
            executed: false
        });
        emit ExpenditureProposalSubmitted(nextExpenditureProposalId, msg.sender, _recipient, _amount);
        nextExpenditureProposalId++;
    }

    /// @notice Allows members to vote on expenditure proposals.
    /// @param _expenditureProposalId ID of the expenditure proposal.
    /// @param _vote True for yes, false for no.
    function voteOnExpenditureProposal(uint256 _expenditureProposalId, bool _vote)
        public
        onlyMember
        validExpenditureProposalId(_expenditureProposalId)
        expenditureProposalNotExecuted(_expenditureProposalId)
        expenditureVotingPeriodActive(_expenditureProposalId)
    {
        if (_vote) {
            expenditureProposals[_expenditureProposalId].voteCountYes++;
        } else {
            expenditureProposals[_expenditureProposalId].voteCountNo++;
        }
        emit ExpenditureProposalVoted(_expenditureProposalId, msg.sender, _vote);
    }

    /// @notice Returns details of a specific expenditure proposal.
    /// @param _expenditureProposalId ID of the expenditure proposal.
    /// @return ExpenditureProposal struct containing proposal details.
    function getExpenditureProposalDetails(uint256 _expenditureProposalId)
        public
        view
        validExpenditureProposalId(_expenditureProposalId)
        returns (ExpenditureProposal memory)
    {
        return expenditureProposals[_expenditureProposalId];
    }

    /// @notice Executes an approved expenditure proposal, callable by contract owner or admin.
    /// @param _expenditureProposalId ID of the expenditure proposal.
    function executeExpenditure(uint256 _expenditureProposalId)
        public
        onlyOwner // Or governance executed
        validExpenditureProposalId(_expenditureProposalId)
        expenditureProposalNotExecuted(_expenditureProposalId)
    {
        require(block.timestamp >= expenditureProposals[_expenditureProposalId].proposalEndTime, "Expenditure voting period not ended yet.");
        require(expenditureProposals[_expenditureProposalId].voteCountYes > expenditureProposals[_expenditureProposalId].voteCountNo, "Expenditure proposal not approved.");

        uint256 amount = expenditureProposals[_expenditureProposalId].amount;
        address recipient = expenditureProposals[_expenditureProposalId].recipient;

        require(address(this).balance >= amount, "Contract balance insufficient for expenditure.");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Expenditure transfer failed.");

        expenditureProposals[_expenditureProposalId].executed = true;
        emit ExpenditureExecuted(_expenditureProposalId, recipient, amount);
    }

    /// @notice Returns the current balance of the collective treasury.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Community & Challenges Functions ---

    /// @notice Allows members to create art challenges.
    /// @param _challengeTitle Title of the art challenge.
    /// @param _challengeDescription Description of the art challenge.
    /// @param _deadline Unix timestamp for the challenge deadline.
    function createArtChallenge(
        string memory _challengeTitle,
        string memory _challengeDescription,
        uint256 _deadline
    ) public onlyMember {
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        artChallenges[nextChallengeId] = ArtChallenge({
            id: nextChallengeId,
            creator: msg.sender,
            title: _challengeTitle,
            description: _challengeDescription,
            deadline: _deadline,
            nextEntryId: 0
        });
        emit ArtChallengeCreated(nextChallengeId, msg.sender, _challengeTitle);
        nextChallengeId++;
    }

    /// @notice Allows members to submit entries to an art challenge.
    /// @param _challengeId ID of the art challenge.
    /// @param _entryDescription Description of the challenge entry.
    /// @param _ipfsHash IPFS hash of the entry's media.
    function submitChallengeEntry(
        uint256 _challengeId,
        string memory _entryDescription,
        string memory _ipfsHash
    ) public onlyMember validChallengeId(_challengeId) {
        require(block.timestamp < artChallenges[_challengeId].deadline, "Challenge deadline has passed.");
        ArtChallenge storage challenge = artChallenges[_challengeId]; // Use storage to modify mapping
        challenge.challengeEntries[challenge.nextEntryId] = ChallengeEntry({
            id: challenge.nextEntryId,
            submitter: msg.sender,
            description: _entryDescription,
            ipfsHash: _ipfsHash,
            voteCountYes: 0,
            voteCountNo: 0
        });
        emit ChallengeEntrySubmitted(_challengeId, challenge.nextEntryId, msg.sender);
        challenge.nextEntryId++;
    }

    /// @notice Allows members to vote on entries in an art challenge.
    /// @param _challengeId ID of the art challenge.
    /// @param _entryId ID of the challenge entry.
    /// @param _vote True for yes, false for no.
    function voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId, bool _vote)
        public
        onlyMember
        validChallengeId(_challengeId)
        validChallengeEntryId(_challengeId, _entryId)
    {
        require(block.timestamp < artChallenges[_challengeId].deadline, "Challenge deadline has passed for voting."); //Voting within deadline too
        if (_vote) {
            artChallenges[_challengeId].challengeEntries[_entryId].voteCountYes++;
        } else {
            artChallenges[_challengeId].challengeEntries[_entryId].voteCountNo++;
        }
        emit ChallengeEntryVoted(_challengeId, _entryId, msg.sender, _vote);
    }

    /// @notice Returns details of a specific art challenge.
    /// @param _challengeId ID of the art challenge.
    /// @return ArtChallenge struct containing challenge details.
    function getChallengeDetails(uint256 _challengeId)
        public
        view
        validChallengeId(_challengeId)
        returns (ArtChallenge memory)
    {
        return artChallenges[_challengeId];
    }

    /// @notice Returns details of a specific entry in an art challenge.
    /// @param _challengeId ID of the art challenge.
    /// @param _entryId ID of the challenge entry.
    /// @return ChallengeEntry struct containing entry details.
    function getChallengeEntryDetails(uint256 _challengeId, uint256 _entryId)
        public
        view
        validChallengeId(_challengeId)
        validChallengeEntryId(_challengeId, _entryId)
        returns (ChallengeEntry memory)
    {
        return artChallenges[_challengeId].challengeEntries[_entryId];
    }
}
```