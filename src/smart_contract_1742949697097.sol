```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to submit art,
 *      community to curate and vote, and rewards distribution based on community consensus.
 *
 * Function Summary:
 * -----------------
 * 1. initializeCollective(string _collectiveName, string _collectiveSymbol, uint256 _curatorDeposit, uint256 _submissionFee, uint256 _votingDurationDays): Initializes the collective with basic parameters.
 * 2. joinCollective(string _artistName, string _artistBio): Allows artists to join the collective by registering their profile.
 * 3. leaveCollective(): Allows artists to leave the collective, removing their membership.
 * 4. submitArtProposal(string _title, string _description, string _ipfsHash): Artists submit their artwork proposals for community curation.
 * 5. curateArtProposal(uint256 _proposalId): Members can become curators by depositing a fee and curating art proposals.
 * 6. voteOnArtProposal(uint256 _proposalId, bool _vote): Members vote on art proposals to decide if they should be accepted.
 * 7. finalizeArtProposal(uint256 _proposalId): Finalizes an art proposal after voting period, minting NFT if approved.
 * 8. mintApprovedArtNFT(uint256 _proposalId): Mints an NFT representing the approved artwork to the artist and collective.
 * 9. setCuratorDeposit(uint256 _newDeposit): Admin function to update the curator deposit amount.
 * 10. setSubmissionFee(uint256 _newFee): Admin function to update the art submission fee.
 * 11. setVotingDuration(uint256 _newDurationDays): Admin function to update the voting duration for proposals.
 * 12. withdrawSubmissionFee(): Allows the contract owner to withdraw accumulated submission fees.
 * 13. withdrawCuratorDeposit(): Allows curators to withdraw their deposit after fulfilling curation duties.
 * 14. getCollectiveInfo(): Retrieves basic information about the art collective.
 * 15. getArtistProfile(address _artistAddress): Retrieves the profile information of a registered artist.
 * 16. getArtProposalDetails(uint256 _proposalId): Retrieves details of a specific art proposal.
 * 17. getProposalVotingStats(uint256 _proposalId): Retrieves voting statistics for a specific art proposal.
 * 18. getMemberCount(): Returns the total number of members in the collective.
 * 19. getActiveProposalCount(): Returns the number of currently active art proposals.
 * 20. isMember(address _address): Checks if an address is a member of the collective.
 * 21. isCurator(address _address): Checks if an address is a curator.
 * 22. renounceCuratorRole(): Allows curators to renounce their curator role and withdraw deposit.
 * 23. proposePolicyChange(string _policyDescription, string _policyDetails): Allows members to propose changes to collective policies.
 * 24. voteOnPolicyChange(uint256 _policyId, bool _vote): Members vote on proposed policy changes.
 * 25. finalizePolicyChange(uint256 _policyId): Finalizes a policy change proposal after voting.
 */

contract DecentralizedArtCollective {
    // --- State Variables ---

    string public collectiveName; // Name of the art collective
    string public collectiveSymbol; // Symbol for the collective (e.g., DAAC)
    address public owner; // Contract owner, initially the deployer

    uint256 public curatorDeposit; // Amount of ETH required to become a curator
    uint256 public submissionFee; // Fee for submitting an art proposal
    uint256 public votingDurationDays; // Duration of voting period for proposals in days
    uint256 public policyVotingDurationDays; // Duration of voting period for policy changes in days

    uint256 public nextProposalId = 1; // Counter for unique proposal IDs
    uint256 public nextPolicyId = 1; // Counter for unique policy change IDs
    uint256 public memberCount = 0; // Number of members in the collective

    mapping(address => ArtistProfile) public artistProfiles; // Artist profiles by address
    mapping(address => bool) public isCuratorRole; // Mapping to track curators
    mapping(uint256 => ArtProposal) public artProposals; // Art proposals by ID
    mapping(uint256 => PolicyChangeProposal) public policyProposals; // Policy change proposals by ID

    // --- Enums ---

    enum ProposalState { Pending, Curating, Voting, Approved, Rejected, Finalized }
    enum PolicyState { Pending, Voting, Approved, Rejected, Finalized }

    // --- Structs ---

    struct ArtistProfile {
        address artistAddress;
        string artistName;
        string artistBio;
        bool isActiveMember;
    }

    struct ArtProposal {
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        ProposalState state;
        uint256 curatorDepositEndTime;
        uint256 votingEndTime;
        uint256 curationDepositCount;
        uint256 yesVotes;
        uint256 noVotes;
        address[] curators;
        mapping(address => bool) votes; // Track votes per address to prevent double voting
    }

    struct PolicyChangeProposal {
        uint256 policyId;
        address proposer;
        string policyDescription;
        string policyDetails;
        PolicyState state;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) votes; // Track votes per address for policy changes
    }

    // --- Events ---

    event CollectiveInitialized(string collectiveName, string collectiveSymbol, address owner);
    event MemberJoined(address artistAddress, string artistName);
    event MemberLeft(address artistAddress);
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event CuratorDepositReceived(address curatorAddress, uint256 proposalId);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint256 proposalId, ProposalState state);
    event CuratorDepositWithdrawn(address curatorAddress, uint256 amount);
    event SubmissionFeeWithdrawn(address owner, uint256 amount);
    event CuratorRoleRenounced(address curatorAddress);
    event PolicyChangeProposed(uint256 policyId, address proposer, string policyDescription);
    event PolicyChangeVoted(uint256 policyId, address voter, bool vote);
    event PolicyChangeFinalized(uint256 policyId, PolicyState state);
    event CuratorRoleAssigned(address curatorAddress);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members of the collective can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator(msg.sender), "Only curators can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID.");
        _;
    }

    modifier validPolicyId(uint256 _policyId) {
        require(_policyId > 0 && _policyId < nextPolicyId, "Invalid policy ID.");
        _;
    }

    modifier proposalInState(uint256 _proposalId, ProposalState _state) {
        require(artProposals[_proposalId].state == _state, "Proposal is not in the required state.");
        _;
    }

    modifier policyInState(uint256 _policyId, PolicyState _state) {
        require(policyProposals[_policyId].state == _state, "Policy proposal is not in the required state.");
        _;
    }

    // --- Functions ---

    /**
     * @dev Initializes the collective. Can only be called once during deployment.
     * @param _collectiveName Name of the collective.
     * @param _collectiveSymbol Symbol for the collective.
     * @param _curatorDeposit Initial curator deposit amount in wei.
     * @param _submissionFee Initial submission fee in wei.
     * @param _votingDurationDays Initial voting duration in days.
     */
    constructor(string memory _collectiveName, string memory _collectiveSymbol, uint256 _curatorDeposit, uint256 _submissionFee, uint256 _votingDurationDays) {
        require(bytes(_collectiveName).length > 0 && bytes(_collectiveSymbol).length > 0, "Collective name and symbol cannot be empty.");
        collectiveName = _collectiveName;
        collectiveSymbol = _collectiveSymbol;
        owner = msg.sender;
        curatorDeposit = _curatorDeposit;
        submissionFee = _submissionFee;
        votingDurationDays = _votingDurationDays;
        policyVotingDurationDays = _votingDurationDays * 2; // Policy voting longer by default
        emit CollectiveInitialized(_collectiveName, _collectiveSymbol, owner);
    }

    /**
     * @dev Allows an artist to join the collective.
     * @param _artistName Name of the artist.
     * @param _artistBio Short bio of the artist.
     */
    function joinCollective(string memory _artistName, string memory _artistBio) external {
        require(!isMember(msg.sender), "Already a member.");
        require(bytes(_artistName).length > 0, "Artist name cannot be empty.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistAddress: msg.sender,
            artistName: _artistName,
            artistBio: _artistBio,
            isActiveMember: true
        });
        memberCount++;
        emit MemberJoined(msg.sender, _artistName);
    }

    /**
     * @dev Allows a member to leave the collective.
     */
    function leaveCollective() external onlyMember {
        require(artistProfiles[msg.sender].isActiveMember, "Not an active member.");
        artistProfiles[msg.sender].isActiveMember = false;
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    /**
     * @dev Allows a member to submit an art proposal. Requires paying the submission fee.
     * @param _title Title of the artwork.
     * @param _description Description of the artwork.
     * @param _ipfsHash IPFS hash of the artwork's metadata.
     */
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember payable {
        require(msg.value >= submissionFee, "Insufficient submission fee.");
        require(bytes(_title).length > 0 && bytes(_ipfsHash).length > 0, "Title and IPFS hash cannot be empty.");

        artProposals[nextProposalId] = ArtProposal({
            proposalId: nextProposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            state: ProposalState.Pending,
            curatorDepositEndTime: 0, // Set when curation starts
            votingEndTime: 0,         // Set when voting starts
            curationDepositCount: 0,
            yesVotes: 0,
            noVotes: 0,
            curators: new address[](0),
            votes: mapping(address => bool)()
        });

        emit ArtProposalSubmitted(nextProposalId, msg.sender, _title);
        nextProposalId++;

        // Refund excess submission fee if paid
        if (msg.value > submissionFee) {
            payable(msg.sender).transfer(msg.value - submissionFee);
        }
    }

    /**
     * @dev Allows members to become curators for a specific art proposal by depositing ETH.
     * @param _proposalId ID of the art proposal to curate.
     */
    function curateArtProposal(uint256 _proposalId) external onlyMember validProposalId(_proposalId) proposalInState(_proposalId, ProposalState.Pending) payable {
        require(msg.value >= curatorDeposit, "Insufficient curator deposit.");
        require(!isCuratorRole[msg.sender], "Already a curator."); // Prevent double curating for same proposal for simplicity
        require(artProposals[_proposalId].curationDepositCount < 5, "Maximum curators reached for this proposal."); // Limit curators to 5 for simplicity

        artProposals[_proposalId].curators.push(msg.sender);
        artProposals[_proposalId].curationDepositCount++;
        isCuratorRole[msg.sender] = true; // Assign curator role
        emit CuratorRoleAssigned(msg.sender); // Emit curator role assignment event

        if (artProposals[_proposalId].curationDepositCount >= 3) { // Start voting if enough curators (e.g., minimum 3)
            artProposals[_proposalId].state = ProposalState.Voting;
            artProposals[_proposalId].votingEndTime = block.timestamp + votingDurationDays * 1 days;
        }

        emit CuratorDepositReceived(msg.sender, _proposalId);
    }

    /**
     * @dev Allows members to vote on an art proposal during the voting period.
     * @param _proposalId ID of the art proposal to vote on.
     * @param _vote True for Yes, False for No.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember validProposalId(_proposalId) proposalInState(_proposalId, ProposalState.Voting) {
        require(block.timestamp <= artProposals[_proposalId].votingEndTime, "Voting period has ended.");
        require(!artProposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");

        artProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Finalizes an art proposal after the voting period ends. Mints NFT if approved.
     * @param _proposalId ID of the art proposal to finalize.
     */
    function finalizeArtProposal(uint256 _proposalId) external validProposalId(_proposalId) proposalInState(_proposalId, ProposalState.Voting) {
        require(block.timestamp > artProposals[_proposalId].votingEndTime, "Voting period is still active.");

        if (artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) {
            artProposals[_proposalId].state = ProposalState.Approved;
            mintApprovedArtNFT(_proposalId); // Mint NFT upon approval
        } else {
            artProposals[_proposalId].state = ProposalState.Rejected;
        }
        artProposals[_proposalId].state = ProposalState.Finalized; // Mark as finalized regardless of outcome
        emit ArtProposalFinalized(_proposalId, artProposals[_proposalId].state);
    }

    /**
     * @dev Mints an NFT representing the approved artwork. (Placeholder - NFT logic needs to be implemented).
     * @param _proposalId ID of the approved art proposal.
     */
    function mintApprovedArtNFT(uint256 _proposalId) private proposalInState(_proposalId, ProposalState.Approved) {
        // --- NFT Minting Logic Placeholder ---
        // In a real implementation, this would involve:
        // 1. Creating an NFT contract (ERC721 or ERC1155).
        // 2. Minting a new NFT with metadata from artProposals[_proposalId].ipfsHash.
        // 3. Transferring the NFT to the artist (and possibly collective treasury for fractional ownership, etc.).

        // For this example, we'll just emit an event and log a message.
        emit ArtProposalFinalized(_proposalId, ProposalState.Approved);
        // Placeholder log:
        // console.log("NFT Minted for proposal ID:", _proposalId, " - Artist:", artProposals[_proposalId].artist);
    }

    /**
     * @dev Allows the contract owner to set a new curator deposit amount.
     * @param _newDeposit New curator deposit amount in wei.
     */
    function setCuratorDeposit(uint256 _newDeposit) external onlyOwner {
        curatorDeposit = _newDeposit;
    }

    /**
     * @dev Allows the contract owner to set a new art submission fee.
     * @param _newFee New submission fee in wei.
     */
    function setSubmissionFee(uint256 _newFee) external onlyOwner {
        submissionFee = _newFee;
    }

    /**
     * @dev Allows the contract owner to set a new voting duration for proposals.
     * @param _newDurationDays New voting duration in days.
     */
    function setVotingDuration(uint256 _newDurationDays) external onlyOwner {
        votingDurationDays = _newDurationDays;
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated submission fees.
     */
    function withdrawSubmissionFee() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 fees = balance - (curatorDeposit * getCuratorCount()); // Assumes curator deposits are also in contract balance.  Adjust if needed.
        require(fees > 0, "No submission fees to withdraw.");
        payable(owner).transfer(fees);
        emit SubmissionFeeWithdrawn(owner, fees);
    }

    /**
     * @dev Allows curators to withdraw their deposit after a proposal is finalized (regardless of outcome).
     */
    function withdrawCuratorDeposit() external onlyCurator {
        require(isCuratorRole[msg.sender], "Not a curator.");

        bool depositWithdrawn = false;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (artProposals[i].state == ProposalState.Finalized) { // Allow withdrawal once proposal is finalized
                for (uint256 j = 0; j < artProposals[i].curators.length; j++) {
                    if (artProposals[i].curators[j] == msg.sender) {
                        payable(msg.sender).transfer(curatorDeposit);
                        isCuratorRole[msg.sender] = false; // Remove curator role
                        emit CuratorDepositWithdrawn(msg.sender, curatorDeposit);
                        depositWithdrawn = true;
                        break; // Only withdraw once per call.
                    }
                }
            }
            if (depositWithdrawn) break; // Exit outer loop if deposit withdrawn
        }
        require(depositWithdrawn, "No deposit to withdraw for finalized proposals.");
    }

    /**
     * @dev Allows curators to renounce their curator role explicitly, withdrawing deposit.
     */
    function renounceCuratorRole() external onlyCurator {
        require(isCuratorRole[msg.sender], "Not a curator.");
        payable(msg.sender).transfer(curatorDeposit);
        isCuratorRole[msg.sender] = false;
        emit CuratorRoleRenounced(msg.sender);
    }


    /**
     * @dev Gets basic information about the art collective.
     * @return collective Name and symbol.
     */
    function getCollectiveInfo() external view returns (string memory, string memory) {
        return (collectiveName, collectiveSymbol);
    }

    /**
     * @dev Gets the profile information of a registered artist.
     * @param _artistAddress Address of the artist.
     * @return Artist profile details.
     */
    function getArtistProfile(address _artistAddress) external view returns (ArtistProfile memory) {
        require(isMember(_artistAddress), "Address is not a member.");
        return artistProfiles[_artistAddress];
    }

    /**
     * @dev Gets details of a specific art proposal.
     * @param _proposalId ID of the art proposal.
     * @return Art proposal details.
     */
    function getArtProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /**
     * @dev Gets voting statistics for a specific art proposal.
     * @param _proposalId ID of the art proposal.
     * @return Yes votes and no votes count.
     */
    function getProposalVotingStats(uint256 _proposalId) external view validProposalId(_proposalId) returns (uint256 yesVotes, uint256 noVotes) {
        return (artProposals[_proposalId].yesVotes, artProposals[_proposalId].noVotes);
    }

    /**
     * @dev Gets the total number of members in the collective.
     * @return Member count.
     */
    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    /**
     * @dev Gets the number of currently active art proposals (Pending or Voting).
     * @return Active proposal count.
     */
    function getActiveProposalCount() external view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (artProposals[i].state == ProposalState.Pending || artProposals[i].state == ProposalState.Voting) {
                activeCount++;
            }
        }
        return activeCount;
    }

    /**
     * @dev Checks if an address is a member of the collective.
     * @param _address Address to check.
     * @return True if member, false otherwise.
     */
    function isMember(address _address) public view returns (bool) {
        return artistProfiles[_address].isActiveMember;
    }

    /**
     * @dev Checks if an address is a curator.
     * @param _address Address to check.
     * @return True if curator, false otherwise.
     */
    function isCurator(address _address) public view returns (bool) {
        return isCuratorRole[_address];
    }

    /**
     * @dev Gets the count of curators.
     * @return Curator count.
     */
    function getCuratorCount() public view returns (uint256) {
        uint256 curatorCount = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            curatorCount += artProposals[i].curationDepositCount;
        }
        return curatorCount;
    }


    // --- Policy Change Proposals ---

    /**
     * @dev Allows members to propose changes to the collective policies.
     * @param _policyDescription Short description of the policy change.
     * @param _policyDetails Detailed text of the policy change.
     */
    function proposePolicyChange(string memory _policyDescription, string memory _policyDetails) external onlyMember {
        require(bytes(_policyDescription).length > 0 && bytes(_policyDetails).length > 0, "Policy description and details cannot be empty.");

        policyProposals[nextPolicyId] = PolicyChangeProposal({
            policyId: nextPolicyId,
            proposer: msg.sender,
            policyDescription: _policyDescription,
            policyDetails: _policyDetails,
            state: PolicyState.Pending,
            votingEndTime: block.timestamp + policyVotingDurationDays * 1 days,
            yesVotes: 0,
            noVotes: 0,
            votes: mapping(address => bool)()
        });
        policyProposals[nextPolicyId].state = PolicyState.Voting; // Immediately move to voting state
        emit PolicyChangeProposed(nextPolicyId, msg.sender, _policyDescription);
        nextPolicyId++;
    }

    /**
     * @dev Allows members to vote on a policy change proposal during the voting period.
     * @param _policyId ID of the policy change proposal.
     * @param _vote True for Yes, False for No.
     */
    function voteOnPolicyChange(uint256 _policyId, bool _vote) external onlyMember validPolicyId(_policyId) policyInState(_policyId, PolicyState.Voting) {
        require(block.timestamp <= policyProposals[_policyId].votingEndTime, "Policy voting period has ended.");
        require(!policyProposals[_policyId].votes[msg.sender], "Already voted on this policy proposal.");

        policyProposals[_policyId].votes[msg.sender] = true;
        if (_vote) {
            policyProposals[_policyId].yesVotes++;
        } else {
            policyProposals[_policyId].noVotes++;
        }
        emit PolicyChangeVoted(_policyId, msg.sender, _vote);
    }

    /**
     * @dev Finalizes a policy change proposal after the voting period ends.
     * @param _policyId ID of the policy change proposal to finalize.
     */
    function finalizePolicyChange(uint256 _policyId) external validPolicyId(_policyId) policyInState(_policyId, PolicyState.Voting) {
        require(block.timestamp > policyProposals[_policyId].votingEndTime, "Policy voting period is still active.");

        if (policyProposals[_policyId].yesVotes > policyProposals[_policyId].noVotes) {
            policyProposals[_policyId].state = PolicyState.Approved;
        } else {
            policyProposals[_policyId].state = PolicyState.Rejected;
        }
        policyProposals[_policyId].state = PolicyState.Finalized; // Mark as finalized regardless of outcome
        emit PolicyChangeFinalized(_policyId, policyProposals[_policyId].state);
    }

    /**
     * @dev Gets details of a specific policy change proposal.
     * @param _policyId ID of the policy change proposal.
     * @return Policy change proposal details.
     */
    function getPolicyProposalDetails(uint256 _policyId) external view validPolicyId(_policyId) returns (PolicyChangeProposal memory) {
        return policyProposals[_policyId];
    }

    /**
     * @dev Gets voting statistics for a specific policy change proposal.
     * @param _policyId ID of the policy change proposal.
     * @return Yes votes and no votes count.
     */
    function getPolicyVotingStats(uint256 _policyId) external view validPolicyId(_policyId) returns (uint256 yesVotes, uint256 noVotes) {
        return (policyProposals[_policyId].yesVotes, policyProposals[_policyId].noVotes);
    }
}
```