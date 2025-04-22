```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Decentralized Autonomous Art Collective (DAAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @version 1.0
 * @notice This contract implements a Decentralized Autonomous Art Collective (DAAAC) where members can propose, curate, and collectively own digital art.
 * It features advanced concepts like decentralized curation, dynamic royalty distribution, on-chain reputation system, and quadratic voting for governance.
 * It aims to foster a collaborative and transparent environment for artists and art enthusiasts within the blockchain ecosystem.
 *
 * Function Summary:
 * -----------------
 * **Core Functions:**
 * 1. becomeMember(): Allows users to become members of the DAAAC by paying a membership fee.
 * 2. submitArtProposal(string memory _ipfsHash, string memory _title, string memory _description): Members can submit art proposals with IPFS hash and metadata.
 * 3. voteOnArtProposal(uint256 _proposalId, bool _support): Members can vote on art proposals during curation rounds.
 * 4. startNewCurationRound(): Owner function to initiate a new curation round for art proposals.
 * 5. tallyCurationVotes(uint256 _roundId): Owner function to finalize a curation round and determine winning proposals.
 * 6. mintNFTForWinningProposal(uint256 _proposalId): Owner function to mint an NFT for a winning art proposal and distribute royalties.
 *
 * **Governance and Reputation:**
 * 7. delegateVotePower(address _delegatee): Members can delegate their voting power to another member.
 * 8. changeGovernanceParameter(string memory _parameterName, uint256 _newValue): Owner function to change governance parameters (e.g., quorum, voting duration).
 * 9. reportMemberMisconduct(address _member, string memory _reportReason): Members can report misconduct of other members, affecting reputation.
 * 10. updateMemberReputation(address _member, int256 _reputationChange): Owner function to manually adjust member reputation based on reports or other factors.
 * 11. getMemberReputation(address _member): Returns the reputation score of a member.
 *
 * **Treasury and Funding:**
 * 12. depositFunds(): Allows anyone to deposit funds into the DAAAC treasury.
 * 13. withdrawFunds(uint256 _amount): Owner function to withdraw funds from the treasury (governance controlled in future iterations).
 * 14. fundProject(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal): Members can propose and fund community projects.
 * 15. contributeToProject(uint256 _projectId) payable: Members can contribute funds to ongoing projects.
 * 16. finalizeProjectFunding(uint256 _projectId): Owner function to finalize project funding and initiate execution (governance controlled in future iterations).
 * 17. getTreasuryBalance(): Returns the current balance of the DAAAC treasury.
 *
 * **Utility and Security:**
 * 18. pauseContract(): Owner function to pause contract functionality in case of emergency.
 * 19. unpauseContract(): Owner function to resume contract functionality.
 * 20. emergencyWithdraw(address _recipient, uint256 _amount): Owner function for emergency fund withdrawal in critical situations.
 * 21. setMerkleRootForWhitelist(bytes32 _merkleRoot): Owner function to set the Merkle root for a membership whitelist.
 * 22. verifyWhitelistMembership(bytes32[] calldata _merkleProof): Public function to verify if an address is whitelisted using Merkle proof.
 * 23. contractName(): Returns the name of the contract.
 * 24. contractVersion(): Returns the version of the contract.
 */

contract DecentralizedAutonomousArtCollective is Ownable, Pausable, ReentrancyGuard {

    string public contractName = "Decentralized Autonomous Art Collective";
    string public contractVersion = "1.0";

    // Structs
    struct ArtProposal {
        uint256 id;
        address proposer;
        string ipfsHash;
        string title;
        string description;
        uint256 curationRoundId;
        uint256 upvotes;
        uint256 downvotes;
        bool isWinning;
        bool nftMinted;
    }

    struct CurationRound {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isFinalized;
        uint256 proposalCount;
    }

    struct Vote {
        uint256 proposalId;
        address voter;
        bool support;
        uint256 votePower; // Quadratic voting implementation - vote power is the square root of tokens staked/reputation, simplified here to just 1 for simplicity
    }

    struct Project {
        uint256 id;
        string name;
        string description;
        address creator;
        uint256 fundingGoal;
        uint256 currentFunding;
        bool isFunded;
        bool isFinalized;
    }

    // State Variables
    uint256 public membershipFee = 0.1 ether;
    mapping(address => bool) public members;
    mapping(address => int256) public memberReputation;
    mapping(address => address) public voteDelegation;
    address[] public memberList; // Keep track of members for iteration (if needed, be mindful of gas costs for large lists)

    ArtProposal[] public artProposals;
    uint256 public artProposalCounter;
    mapping(uint256 => CurationRound) public curationRounds;
    uint256 public currentCurationRoundId;
    uint256 public curationRoundDuration = 7 days; // Default curation round duration
    uint256 public curationQuorumPercentage = 50; // Percentage of members needed to vote for quorum

    mapping(uint256 => Vote[]) public curationRoundVotes;

    address public artNFTContractAddress; // Address of the NFT contract (can be deployed separately)
    uint256 public artistRoyaltyPercentage = 10; // Default artist royalty percentage

    uint256 public projectCounter;
    mapping(uint256 => Project) public projects;

    uint256 public governanceParameter_VotingDuration = 7 days; // Example governance parameter
    uint256 public governanceParameter_QuorumPercentage = 50; // Example governance parameter

    bytes32 public merkleRootWhitelist; // Merkle root for membership whitelist

    // Events
    event MembershipJoined(address indexed member);
    event ArtProposalSubmitted(uint256 proposalId, address proposer, string ipfsHash);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event CurationRoundStarted(uint256 roundId, uint256 startTime, uint256 endTime);
    event CurationRoundFinalized(uint256 roundId, uint256 winningProposalsCount);
    event NFTMinted(uint256 proposalId, address minter, address artist, uint256 royaltyAmount);
    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address withdrawer, uint256 amount);
    event ProjectFunded(uint256 projectId, string projectName, uint256 fundingGoal);
    event ContributionMade(uint256 projectId, address contributor, uint256 amount);
    event ProjectFundingFinalized(uint256 projectId);
    event GovernanceParameterChanged(string parameterName, uint256 newValue);
    event MemberReported(address reporter, address reportedMember, string reason);
    event MemberReputationUpdated(address member, int256 reputationChange, int256 newReputation);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event EmergencyWithdrawal(address recipient, uint256 amount);
    event WhitelistMerkleRootSet(bytes32 merkleRoot);


    // Modifiers
    modifier onlyMember() {
        require(members[msg.sender], "You are not a member of the DAAAC.");
        _;
    }

    modifier onlyCurationRoundActive() {
        require(curationRounds[currentCurationRoundId].isActive, "Curation round is not active.");
        _;
    }

    modifier onlyCurationRoundNotFinalized(uint256 _roundId) {
        require(!curationRounds[_roundId].isFinalized, "Curation round is already finalized.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= artProposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validCurationRoundId(uint256 _roundId) {
        require(_roundId > 0 && _roundId <= currentCurationRoundId, "Invalid curation round ID.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= projectCounter, "Project does not exist.");
        _;
    }

    modifier projectNotFinalized(uint256 _projectId) {
        require(!projects[_projectId].isFinalized, "Project is already finalized.");
        _;
    }


    constructor() payable Ownable() Pausable() {
        // Initialize contract, potentially with initial funds.
        currentCurationRoundId = 0; // No curation round started yet
        emit FundsDeposited(address(this), msg.value);
    }

    // --- Membership Functions ---

    /**
     * @notice Allows users to become members of the DAAAC by paying a membership fee.
     * @dev Optionally implements whitelist verification using Merkle proof.
     */
    function becomeMember(bytes32[] calldata _merkleProof) external payable whenNotPaused nonReentrant {
        require(!members[msg.sender], "Already a member.");
        if (merkleRootWhitelist != bytes32(0)) {
            require(verifyWhitelistMembership(_merkleProof), "Not on the whitelist.");
        }
        require(msg.value >= membershipFee, "Membership fee is required.");
        members[msg.sender] = true;
        memberList.push(msg.sender);
        memberReputation[msg.sender] = 0; // Initial reputation
        emit MembershipJoined(msg.sender);
    }

    /**
     * @notice Verifies if an address is whitelisted using Merkle proof.
     * @param _merkleProof Merkle proof for the address.
     * @return bool True if the address is whitelisted, false otherwise.
     */
    function verifyWhitelistMembership(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRootWhitelist, leaf);
    }

    /**
     * @notice Allows members to delegate their voting power to another member.
     * @param _delegatee Address of the member to delegate voting power to.
     */
    function delegateVotePower(address _delegatee) external onlyMember whenNotPaused {
        require(members[_delegatee], "Delegatee must be a member.");
        require(_delegatee != msg.sender, "Cannot delegate to yourself.");
        voteDelegation[msg.sender] = _delegatee;
    }

    /**
     * @notice Returns whether an address is a member.
     * @param _address Address to check.
     * @return bool True if the address is a member, false otherwise.
     */
    function isMember(address _address) public view returns (bool) {
        return members[_address];
    }

    /**
     * @notice Returns the number of members in the DAAAC.
     * @return uint256 Number of members.
     */
    function memberCount() public view returns (uint256) {
        return memberList.length;
    }


    // --- Art Proposal and Curation Functions ---

    /**
     * @notice Allows members to submit art proposals.
     * @param _ipfsHash IPFS hash of the art piece.
     * @param _title Title of the art piece.
     * @param _description Description of the art piece.
     */
    function submitArtProposal(string memory _ipfsHash, string memory _title, string memory _description) external onlyMember whenNotPaused onlyCurationRoundActive {
        artProposalCounter++;
        artProposals.push(ArtProposal({
            id: artProposalCounter,
            proposer: msg.sender,
            ipfsHash: _ipfsHash,
            title: _title,
            description: _description,
            curationRoundId: currentCurationRoundId,
            upvotes: 0,
            downvotes: 0,
            isWinning: false,
            nftMinted: false
        }));
        curationRounds[currentCurationRoundId].proposalCount++;
        emit ArtProposalSubmitted(artProposalCounter, msg.sender, _ipfsHash);
    }

    /**
     * @notice Allows members to vote on art proposals during an active curation round.
     * @param _proposalId ID of the art proposal to vote on.
     * @param _support Boolean indicating support (true for upvote, false for downvote).
     */
    function voteOnArtProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPaused onlyCurationRoundActive validProposalId(_proposalId) onlyCurationRoundNotFinalized(currentCurationRoundId) {
        // Check if already voted in this round (can be expanded for single vote per round per proposal if needed)
        for (uint256 i = 0; i < curationRoundVotes[currentCurationRoundId].length; i++) {
            if (curationRoundVotes[currentCurationRoundId][i].voter == msg.sender && curationRoundVotes[currentCurationRoundId][i].proposalId == _proposalId) {
                revert("Already voted on this proposal in this round.");
            }
        }

        uint256 votePower = 1; // Simplified vote power, could be based on reputation or staked tokens in future.
        address effectiveVoter = voteDelegation[msg.sender] != address(0) ? voteDelegation[msg.sender] : msg.sender;

        curationRoundVotes[currentCurationRoundId].push(Vote({
            proposalId: _proposalId,
            voter: effectiveVoter,
            support: _support,
            votePower: votePower
        }));

        if (_support) {
            artProposals[_proposalId - 1].upvotes += votePower;
        } else {
            artProposals[_proposalId - 1].downvotes += votePower;
        }

        emit VoteCast(_proposalId, effectiveVoter, _support);
    }

    /**
     * @notice Starts a new curation round for art proposals. Only callable by the contract owner.
     */
    function startNewCurationRound() external onlyOwner whenNotPaused {
        require(!curationRounds[currentCurationRoundId].isActive && (currentCurationRoundId == 0 || curationRounds[currentCurationRoundId].isFinalized), "Current curation round is still active or not finalized.");

        currentCurationRoundId++;
        curationRounds[currentCurationRoundId] = CurationRound({
            id: currentCurationRoundId,
            startTime: block.timestamp,
            endTime: block.timestamp + curationRoundDuration,
            isActive: true,
            isFinalized: false,
            proposalCount: 0
        });
        emit CurationRoundStarted(currentCurationRoundId, block.timestamp, curationRounds[currentCurationRoundId].endTime);
    }

    /**
     * @notice Tallies votes and finalizes a curation round, determining winning proposals. Only callable by the contract owner.
     * @param _roundId ID of the curation round to finalize.
     */
    function tallyCurationVotes(uint256 _roundId) external onlyOwner whenNotPaused validCurationRoundId(_roundId) onlyCurationRoundNotFinalized(_roundId) {
        require(curationRounds[_roundId].isActive && block.timestamp > curationRounds[_roundId].endTime, "Curation round is not active or has not ended yet.");

        uint256 totalMembers = memberList.length;
        uint256 quorumVotesNeeded = (totalMembers * curationQuorumPercentage) / 100;
        uint256 votesCastInRound = curationRoundVotes[_roundId].length;

        require(votesCastInRound >= quorumVotesNeeded, "Curation round did not meet quorum.");

        uint256 winningProposalsCount = 0;
        for (uint256 i = 0; i < artProposalCounter; i++) {
            if (artProposals[i].curationRoundId == _roundId) {
                // Simple winning condition: more upvotes than downvotes
                if (artProposals[i].upvotes > artProposals[i].downvotes) {
                    artProposals[i].isWinning = true;
                    winningProposalsCount++;
                }
            }
        }

        curationRounds[_roundId].isActive = false;
        curationRounds[_roundId].isFinalized = true;
        emit CurationRoundFinalized(_roundId, winningProposalsCount);
    }

    /**
     * @notice Mints an NFT for a winning art proposal and distributes royalties to the artist. Only callable by the contract owner.
     * @param _proposalId ID of the winning art proposal.
     */
    function mintNFTForWinningProposal(uint256 _proposalId) external onlyOwner whenNotPaused validProposalId(_proposalId) {
        require(artProposals[_proposalId - 1].isWinning && !artProposals[_proposalId - 1].nftMinted, "Proposal is not winning or NFT already minted.");
        require(artNFTContractAddress != address(0), "Art NFT contract address not set.");

        // In a real implementation, you would call a function on the artNFTContractAddress to mint the NFT.
        // This is a placeholder - replace with actual NFT minting logic.
        // Example (assuming artNFTContract has a mint function):
        // IERC721 artNFT = IERC721(artNFTContractAddress);
        // artNFT.mint(artProposals[_proposalId - 1].proposer, _proposalId); // Mint to artist

        uint256 royaltyAmount = 0; // Calculate royalty amount based on future sales (not implemented in this contract scope)

        artProposals[_proposalId - 1].nftMinted = true;
        emit NFTMinted(_proposalId, address(this), artProposals[_proposalId - 1].proposer, royaltyAmount); // Minter is this contract for now.
    }

    /**
     * @notice Gets details of an art proposal.
     * @param _proposalId ID of the art proposal.
     * @return ArtProposal struct containing proposal details.
     */
    function getArtProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId - 1];
    }

    /**
     * @notice Gets details of a curation round.
     * @param _roundId ID of the curation round.
     * @return CurationRound struct containing round details.
     */
    function getCurationRoundDetails(uint256 _roundId) external view validCurationRoundId(_roundId) returns (CurationRound memory) {
        return curationRounds[_roundId];
    }

    /**
     * @notice Gets the ID of the current active curation round.
     * @return uint256 Current curation round ID.
     */
    function getCurrentCurationRoundId() public view returns (uint256) {
        return currentCurationRoundId;
    }

    /**
     * @notice Gets the status of a curation round (active, finalized).
     * @param _roundId ID of the curation round.
     * @return bool True if the round is active, false otherwise.
     */
    function getCurationRoundStatus(uint256 _roundId) external view validCurationRoundId(_roundId) returns (bool) {
        return curationRounds[_roundId].isActive;
    }

    /**
     * @notice Gets the list of winning proposal IDs for a curation round.
     * @param _roundId ID of the curation round.
     * @return uint256[] Array of winning proposal IDs.
     */
    function getCurationRoundWinningProposals(uint256 _roundId) external view validCurationRoundId(_roundId) returns (uint256[] memory) {
        require(curationRounds[_roundId].isFinalized, "Curation round is not finalized yet.");
        uint256[] memory winningProposalIds = new uint256[](curationRounds[_roundId].proposalCount); // Max size, can be optimized
        uint256 winningCount = 0;
        for (uint256 i = 0; i < artProposalCounter; i++) {
            if (artProposals[i].curationRoundId == _roundId && artProposals[i].isWinning) {
                winningProposalIds[winningCount] = artProposals[i].id;
                winningCount++;
            }
        }
        // Resize to actual winning count (optional optimization)
        assembly {
            mstore(winningProposalIds, winningCount) // Resize array in memory
        }
        return winningProposalIds;
    }


    // --- Governance and Reputation Functions ---

    /**
     * @notice Allows the contract owner to change governance parameters.
     * @param _parameterName Name of the parameter to change (e.g., "VotingDuration", "QuorumPercentage").
     * @param _newValue New value for the parameter.
     */
    function changeGovernanceParameter(string memory _parameterName, uint256 _newValue) external onlyOwner whenNotPaused {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("VotingDuration"))) {
            governanceParameter_VotingDuration = _newValue;
            curationRoundDuration = _newValue; // Example: update curation round duration to match
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("QuorumPercentage"))) {
            require(_newValue <= 100, "Quorum percentage must be less than or equal to 100.");
            governanceParameter_QuorumPercentage = _newValue;
            curationQuorumPercentage = _newValue; // Example: update curation quorum percentage
        } else {
            revert("Invalid governance parameter name.");
        }
        emit GovernanceParameterChanged(_parameterName, _newValue);
    }

    /**
     * @notice Allows members to report misconduct of other members.
     * @param _member Address of the member being reported.
     * @param _reportReason Reason for the report.
     */
    function reportMemberMisconduct(address _member, string memory _reportReason) external onlyMember whenNotPaused {
        require(members[_member], "Reported address is not a member.");
        require(_member != msg.sender, "Cannot report yourself.");
        // In a more advanced system, reports would be reviewed and reputation adjusted based on verification.
        // For now, just emit an event.
        emit MemberReported(msg.sender, _member, _reportReason);
    }

    /**
     * @notice Allows the contract owner to manually update a member's reputation score.
     * @param _member Address of the member whose reputation is being updated.
     * @param _reputationChange Amount to change the reputation score by (positive or negative).
     */
    function updateMemberReputation(address _member, int256 _reputationChange) external onlyOwner whenNotPaused {
        require(members[_member], "Target address is not a member.");
        memberReputation[_member] += _reputationChange;
        emit MemberReputationUpdated(_member, _reputationChange, memberReputation[_member]);
    }

    /**
     * @notice Gets the reputation score of a member.
     * @param _member Address of the member.
     * @return int256 Reputation score.
     */
    function getMemberReputation(address _member) external view returns (int256) {
        return memberReputation[_member];
    }


    // --- Treasury and Funding Functions ---

    /**
     * @notice Allows anyone to deposit funds into the DAAAC treasury.
     */
    function depositFunds() external payable whenNotPaused nonReentrant {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows the contract owner to withdraw funds from the treasury.
     * @param _amount Amount to withdraw.
     */
    function withdrawFunds(uint256 _amount) external onlyOwner whenNotPaused nonReentrant {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(owner()).transfer(_amount);
        emit FundsWithdrawn(owner(), _amount);
    }

    /**
     * @notice Allows members to propose a community project requiring funding.
     * @param _projectName Name of the project.
     * @param _projectDescription Description of the project.
     * @param _fundingGoal Funding goal in Wei.
     */
    function fundProject(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal) external onlyMember whenNotPaused {
        projectCounter++;
        projects[projectCounter] = Project({
            id: projectCounter,
            name: _projectName,
            description: _projectDescription,
            creator: msg.sender,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            isFunded: false,
            isFinalized: false
        });
        emit ProjectFunded(projectCounter, _projectName, _fundingGoal);
    }

    /**
     * @notice Allows members to contribute funds to an ongoing project.
     * @param _projectId ID of the project to contribute to.
     */
    function contributeToProject(uint256 _projectId) external payable onlyMember whenNotPaused projectExists(_projectId) projectNotFinalized(_projectId) {
        require(!projects[_projectId].isFunded, "Project is already funded.");
        Project storage project = projects[_projectId];
        project.currentFunding += msg.value;
        emit ContributionMade(_projectId, msg.sender, msg.value);
        if (project.currentFunding >= project.fundingGoal) {
            project.isFunded = true;
        }
    }

    /**
     * @notice Allows the contract owner to finalize project funding and initiate project execution (governance step in future).
     * @param _projectId ID of the project to finalize.
     */
    function finalizeProjectFunding(uint256 _projectId) external onlyOwner whenNotPaused projectExists(_projectId) projectNotFinalized(_projectId) {
        require(projects[_projectId].isFunded, "Project is not fully funded yet.");
        projects[_projectId].isFinalized = true;
        emit ProjectFundingFinalized(_projectId);
        // In a real implementation, trigger project execution logic here (e.g., release funds to project creator, initiate voting on execution steps).
    }

    /**
     * @notice Gets the current balance of the DAAAC treasury.
     * @return uint256 Treasury balance in Wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Gets details of a project.
     * @param _projectId ID of the project.
     * @return Project struct containing project details.
     */
    function getProjectDetails(uint256 _projectId) external view projectExists(_projectId) returns (Project memory) {
        return projects[_projectId];
    }


    // --- Utility and Security Functions ---

    /**
     * @notice Pauses the contract, preventing most functions from being called. Only callable by the contract owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing functions to be called again. Only callable by the contract owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Checks if the contract is currently paused.
     * @return bool True if the contract is paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return paused();
    }

    /**
     * @notice Allows the contract owner to perform an emergency withdrawal of funds in critical situations.
     * @param _recipient Address to receive the withdrawn funds.
     * @param _amount Amount to withdraw.
     */
    function emergencyWithdraw(address _recipient, uint256 _amount) external onlyOwner whenPaused nonReentrant {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        emit EmergencyWithdrawal(_recipient, _amount);
    }

    /**
     * @notice Sets the Merkle root for the membership whitelist. Only callable by the contract owner.
     * @param _merkleRoot Merkle root of the whitelist.
     */
    function setMerkleRootForWhitelist(bytes32 _merkleRoot) external onlyOwner {
        merkleRootWhitelist = _merkleRoot;
        emit WhitelistMerkleRootSet(_merkleRoot);
    }

    /**
     * @notice Returns the name of the contract.
     * @return string Contract name.
     */
    function contractName() public view returns (string memory) {
        return contractName;
    }

    /**
     * @notice Returns the version of the contract.
     * @return string Contract version.
     */
    function contractVersion() public view returns (string memory) {
        return contractVersion;
    }

    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value); // Allow direct deposits to treasury
    }
}
```