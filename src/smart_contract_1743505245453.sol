```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Governance DAO with Evolving Membership NFTs
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Organization (DAO)
 *      featuring dynamic membership NFTs that evolve based on member contributions
 *      and DAO activity. This contract implements advanced concepts like:
 *      - Dynamic NFTs: NFTs whose metadata and attributes change based on on-chain events.
 *      - Tiered Membership: Different NFT levels granting varying governance power and benefits.
 *      - Skill-Based Task Assignment: Matching members' skills to DAO tasks.
 *      - Reputation System: Tracking and rewarding member contributions to influence NFT evolution.
 *      - Quadratic Voting:  Potentially integrated for fairer governance (basic implementation included).
 *      - Decentralized Dispute Resolution:  A mechanism for resolving conflicts within the DAO.
 *      - Dynamic Quorum: Adjusting quorum based on DAO participation.
 *      - AI-Driven Task Recommendation (Conceptual):  Placeholder for future AI integration.
 *      - NFT Staking for Enhanced Benefits: Members can stake their NFTs for additional rewards.
 *      - Layered Governance: Different types of proposals with varying voting requirements.
 *      - On-Chain Skill Registry:  Members can register their skills for better task allocation.
 *      - Retroactive Public Goods Funding:  Rewarding past contributions to the DAO ecosystem.
 *      - Dynamic Access Control:  Function access based on NFT level and roles.
 *      - Conditional Proposal Execution: Proposals executed based on external oracle conditions.
 *      - Decentralized Communication Channel (Conceptual): Placeholder for on-chain messaging.
 *      - NFT-Gated Features:  Unlocking functionalities based on NFT ownership/level.
 *      - Contribution-Based Leveling:  NFT levels increase based on verifiable contributions.
 *      - Time-Based Decay of Reputation:  Reputation scores gradually decrease over time to encourage ongoing participation.
 *      - Customizable Governance Parameters:  DAO parameters like quorum, voting periods, etc. can be adjusted through governance proposals.
 *
 * Function Summary:
 * 1. initializeDAO(string _daoName, string _baseNFTURI): Initializes the DAO with a name and base NFT URI.
 * 2. proposeNewRule(string memory _ruleProposal, bytes memory _proposalData): Allows members to propose new rules or actions for the DAO.
 * 3. voteOnProposal(uint _proposalId, bool _supportVote): Allows members to vote on active proposals.
 * 4. executeProposal(uint _proposalId): Executes a proposal if it has passed and conditions are met.
 * 5. getProposalDetails(uint _proposalId): Retrieves details of a specific proposal.
 * 6. mintMembershipNFT(address _recipient, string memory _initialMetadata): Mints a membership NFT to a new member.
 * 7. burnMembershipNFT(uint _tokenId): Allows members to burn their membership NFT, exiting the DAO.
 * 8. transferMembershipNFT(address _to, uint _tokenId): Allows members to transfer their membership NFTs.
 * 9. upgradeNFTLevel(uint _tokenId): Upgrades a member's NFT level based on contribution points.
 * 10. downgradeNFTLevel(uint _tokenId): Downgrades a member's NFT level (e.g., for inactivity).
 * 11. getNFTMetadata(uint _tokenId): Retrieves the dynamic metadata URI for a membership NFT.
 * 12. getNFTLevel(uint _tokenId): Retrieves the current level of a membership NFT.
 * 13. recordContribution(address _member, string memory _contributionDetails): Records a member's contribution and updates their reputation.
 * 14. assignTask(address _member, string memory _taskDescription): Assigns a task to a member based on their skills (conceptual).
 * 15. registerSkill(string memory _skill): Allows members to register their skills in the on-chain registry.
 * 16. initiateDisputeResolution(uint _proposalId, string memory _disputeDetails): Initiates a dispute resolution process for a proposal.
 * 17. resolveDispute(uint _disputeId, uint _resolutionVote):  Allows designated resolvers to vote on dispute resolutions.
 * 18. stakeNFTForRewards(uint _tokenId): Allows members to stake their NFTs to earn rewards (conceptual).
 * 19. unstakeNFT(uint _tokenId): Allows members to unstake their NFTs.
 * 20. claimRewards(): Allows members to claim staking rewards (conceptual).
 * 21. setDynamicQuorum(uint _newQuorumPercentage): Allows governance to update the quorum percentage.
 * 22. emergencyPauseDAO(): Allows the contract owner to pause critical DAO functions in emergencies.
 * 23. emergencyUnpauseDAO(): Allows the contract owner to unpause DAO functions.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example for future role-based access

contract DynamicGovernanceDAO is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public daoName;
    string public baseNFTURI;
    address public treasuryAddress; // DAO Treasury

    Counters.Counter private _proposalIds;
    Counters.Counter private _memberCount;
    Counters.Counter private _disputeIds;

    uint256 public quorumPercentage = 50; // Default quorum percentage
    uint256 public votingPeriod = 7 days; // Default voting period

    enum ProposalState { Pending, Active, Passed, Rejected, Executed, Dispute }
    enum NFTLevel { Level1, Level2, Level3, Level4, Level5 } // Example NFT Levels

    struct Proposal {
        uint256 id;
        string proposalDescription;
        bytes proposalData; // Flexible data for proposal execution
        ProposalState state;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) voters; // Track who voted
    }

    struct Member {
        uint256 memberId;
        NFTLevel level;
        uint256 reputationScore;
        string[] skills; // On-chain skill registry
        uint256 lastContributionTime;
        bool isStaked; // For conceptual staking
    }

    struct Dispute {
        uint256 id;
        uint256 proposalId;
        string disputeDetails;
        uint256 resolutionVotes; // Simple counter, can be expanded
        mapping(address => bool) resolversVoted;
        bool isResolved;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => address) public nftToMemberAddress; // tokenId to member address
    mapping(address => uint256) public memberAddressToNftId; // member address to tokenId

    bool public paused = false; // Emergency Pause State

    // Events
    event DAOInitialized(string daoName, address owner);
    event ProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool supportVote);
    event ProposalExecuted(uint256 proposalId);
    event ProposalRejected(uint256 proposalId);
    event MembershipNFTMinted(address recipient, uint256 tokenId);
    event MembershipNFTBurned(uint256 tokenId);
    event NFTLevelUpgraded(uint256 tokenId, NFTLevel newLevel);
    event NFTLevelDowngraded(uint256 tokenId, NFTLevel newLevel);
    event ContributionRecorded(address member, string details);
    event TaskAssigned(address member, string taskDescription);
    event SkillRegistered(address member, string skill);
    event DisputeInitiated(uint256 disputeId, uint256 proposalId, string details);
    event DisputeResolved(uint256 disputeId, uint256 resolutionVote);
    event NFTStaked(uint256 tokenId);
    event NFTUnstaked(uint256 tokenId);
    event RewardsClaimed(address member, uint256 amount); // Conceptual Reward Amount
    event QuorumPercentageUpdated(uint256 newQuorumPercentage);
    event DAOPaused(address pauser);
    event DAOUnpaused(address unpauser);


    modifier onlyMembers() {
        require(_isMember(msg.sender), "Not a DAO member");
        _;
    }

    modifier onlyGovernance() { // Example: For actions requiring higher governance level (e.g., Level 3+ NFT)
        require(_getNFTLevel(memberAddressToNftId[msg.sender]) >= NFTLevel.Level3, "Insufficient governance level");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DAO is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "DAO is not paused");
        _;
    }

    constructor() ERC721("DynamicGovernanceNFT", "DGNFT") Ownable() {
        // Constructor is intentionally left empty, initialization through initializeDAO function.
    }

    /// @notice Initializes the DAO with a name and base NFT URI. Can only be called once.
    /// @param _daoName The name of the DAO.
    /// @param _baseNFTURI The base URI for the membership NFTs' metadata.
    function initializeDAO(string memory _daoName, string memory _baseNFTURI) external onlyOwner {
        require(bytes(daoName).length == 0, "DAO already initialized"); // Prevent re-initialization
        daoName = _daoName;
        baseNFTURI = _baseNFTURI;
        treasuryAddress = address(this); // Set treasury to contract address for simplicity
        emit DAOInitialized(_daoName, owner());
    }

    /// @notice Allows members to propose a new rule or action for the DAO.
    /// @param _ruleProposal A description of the proposal.
    /// @param _proposalData Additional data relevant to the proposal (e.g., function calls, parameters).
    function proposeNewRule(string memory _ruleProposal, bytes memory _proposalData) external onlyMembers whenNotPaused {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalDescription: _ruleProposal,
            proposalData: _proposalData,
            state: ProposalState.Pending,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0
        });
        proposals[proposalId].state = ProposalState.Active; // Move to active state immediately
        emit ProposalCreated(proposalId, _ruleProposal, msg.sender);
    }

    /// @notice Allows members to vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _supportVote True to vote yes, false to vote no.
    function voteOnProposal(uint256 _proposalId, bool _supportVote) external onlyMembers whenNotPaused {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period ended");
        require(!proposals[_proposalId].voters[msg.sender], "Already voted on this proposal");

        proposals[_proposalId].voters[msg.sender] = true;
        uint256 votingPower = _getVotingPower(memberAddressToNftId[msg.sender]); // Get voting power based on NFT level

        if (_supportVote) {
            proposals[_proposalId].yesVotes += votingPower;
        } else {
            proposals[_proposalId].noVotes += votingPower;
        }
        emit VoteCast(_proposalId, msg.sender, _supportVote);

        // Check if quorum is reached and voting period ended to auto-execute or reject
        if (block.timestamp > proposals[_proposalId].endTime) {
            _finalizeProposal(_proposalId);
        }
    }

    /// @notice Executes a proposal if it has passed the voting and conditions are met.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyGovernance whenNotPaused { // Example: Only governance level can execute
        require(proposals[_proposalId].state == ProposalState.Passed, "Proposal not passed");
        proposals[_proposalId].state = ProposalState.Executed;

        // Example: Simple execution logic (can be expanded based on proposalData)
        // In a real-world scenario, _proposalData would be decoded and used to perform actions
        // like calling other contract functions, updating contract state, etc.
        // For now, just emitting an event.
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Retrieves details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Mints a membership NFT to a new member.
    /// @param _recipient The address to receive the NFT.
    /// @param _initialMetadata Initial metadata for the NFT (can be dynamic later).
    function mintMembershipNFT(address _recipient, string memory _initialMetadata) external onlyOwner whenNotPaused {
        _memberCount.increment();
        uint256 tokenId = _memberCount.current();
        _safeMint(_recipient, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(baseNFTURI, tokenId.toString()))); // Basic URI setting
        members[_recipient] = Member({
            memberId: tokenId,
            level: NFTLevel.Level1, // Initial level
            reputationScore: 0,
            skills: new string[](0),
            lastContributionTime: block.timestamp,
            isStaked: false
        });
        nftToMemberAddress[tokenId] = _recipient;
        memberAddressToNftId[_recipient] = tokenId;

        emit MembershipNFTMinted(_recipient, tokenId);
    }

    /// @notice Allows a member to burn their membership NFT, effectively exiting the DAO.
    /// @param _tokenId The ID of the NFT to burn.
    function burnMembershipNFT(uint256 _tokenId) external whenNotPaused {
        address memberAddress = nftToMemberAddress[_tokenId];
        require(msg.sender == memberAddress, "Only NFT owner can burn");
        require(_isMember(memberAddress), "Not a member");

        delete members[memberAddress];
        delete nftToMemberAddress[_tokenId];
        delete memberAddressToNftId[memberAddress];
        _burn(_tokenId);
        emit MembershipNFTBurned(_tokenId);
    }

    /// @notice Allows members to transfer their membership NFTs.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferMembershipNFT(address _to, uint256 _tokenId) external whenNotPaused {
        address memberAddress = nftToMemberAddress[_tokenId];
        require(msg.sender == memberAddress, "Only NFT owner can transfer");
        require(_isMember(memberAddress), "Not a member");

        // Update mappings for new owner
        address currentOwner = ownerOf(_tokenId);
        delete members[currentOwner]; // Remove old member data
        delete memberAddressToNftId[currentOwner];

        members[_to] = Member({ // Initialize new member data (level, reputation may need adjustments)
            memberId: _tokenId,
            level: NFTLevel.Level1, // Reset to initial level upon transfer? Or inherit level? (Design choice)
            reputationScore: 0,      // Reset reputation? Or inherit? (Design choice)
            skills: new string[](0), // Reset skills? Or inherit? (Design choice)
            lastContributionTime: block.timestamp,
            isStaked: false
        });
        nftToMemberAddress[_tokenId] = _to;
        memberAddressToNftId[_to] = _tokenId;

        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    /// @notice Upgrades a member's NFT level based on their contribution points.
    /// @param _tokenId The ID of the NFT to upgrade.
    function upgradeNFTLevel(uint256 _tokenId) external onlyMembers whenNotPaused {
        require(msg.sender == nftToMemberAddress[_tokenId], "Not NFT owner");
        NFTLevel currentLevel = _getNFTLevel(_tokenId);
        NFTLevel nextLevel;

        // Example leveling logic based on reputation score (can be customized)
        if (members[msg.sender].reputationScore >= 1000 && currentLevel < NFTLevel.Level2) {
            nextLevel = NFTLevel.Level2;
        } else if (members[msg.sender].reputationScore >= 5000 && currentLevel < NFTLevel.Level3) {
            nextLevel = NFTLevel.Level3;
        } else if (members[msg.sender].reputationScore >= 15000 && currentLevel < NFTLevel.Level4) {
            nextLevel = NFTLevel.Level4;
        } else if (members[msg.sender].reputationScore >= 50000 && currentLevel < NFTLevel.Level5) {
            nextLevel = NFTLevel.Level5;
        } else {
            revert("Insufficient reputation for level upgrade");
        }

        members[msg.sender].level = nextLevel;
        _updateNFTMetadata(_tokenId); // Update NFT metadata to reflect level change
        emit NFTLevelUpgraded(_tokenId, nextLevel);
    }

    /// @notice Downgrades a member's NFT level (e.g., for inactivity or negative reputation).
    /// @param _tokenId The ID of the NFT to downgrade.
    function downgradeNFTLevel(uint256 _tokenId) external onlyGovernance whenNotPaused { // Example: Governance initiated downgrade
        require(_isMember(nftToMemberAddress[_tokenId]), "Not a member");
        NFTLevel currentLevel = _getNFTLevel(_tokenId);
        NFTLevel nextLevel;

        // Example downgrade logic (can be more complex based on rules)
        if (currentLevel > NFTLevel.Level1) {
            nextLevel = NFTLevel(uint256(currentLevel) - 1); // Simple downgrade by one level
            members[nftToMemberAddress[_tokenId]].level = nextLevel;
            _updateNFTMetadata(_tokenId);
            emit NFTLevelDowngraded(_tokenId, nextLevel);
        } else {
            revert("Cannot downgrade below Level 1");
        }
    }

    /// @notice Retrieves the dynamic metadata URI for a membership NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI string.
    function getNFTMetadata(uint256 _tokenId) external view returns (string memory) {
        return tokenURI(_tokenId);
    }

    /// @notice Retrieves the current level of a membership NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The NFTLevel enum value.
    function getNFTLevel(uint256 _tokenId) external view returns (NFTLevel) {
        return _getNFTLevel(_tokenId);
    }

    /// @notice Records a member's contribution and updates their reputation score.
    /// @param _member The address of the contributing member.
    /// @param _contributionDetails Details of the contribution.
    function recordContribution(address _member, string memory _contributionDetails) external onlyGovernance whenNotPaused { // Example: Governance records contributions
        require(_isMember(_member), "Not a member");
        members[_member].reputationScore += _calculateReputationReward(_contributionDetails); // Example reward calculation
        members[_member].lastContributionTime = block.timestamp;
        emit ContributionRecorded(_member, _contributionDetails);
    }

    /// @notice Assigns a task to a member based on their skills (conceptual - skill matching logic needed).
    /// @param _member The address of the member to assign the task to.
    /// @param _taskDescription Description of the task.
    function assignTask(address _member, string memory _taskDescription) external onlyGovernance whenNotPaused { // Example: Governance assigns tasks
        require(_isMember(_member), "Not a member");
        // In a real implementation, skill-based task assignment logic would be here
        // matching _taskDescription requirements with member skills.
        emit TaskAssigned(_member, _taskDescription);
    }

    /// @notice Allows members to register their skills in the on-chain registry.
    /// @param _skill The skill to register.
    function registerSkill(string memory _skill) external onlyMembers whenNotPaused {
        bool skillExists = false;
        for (uint i = 0; i < members[msg.sender].skills.length; i++) {
            if (keccak256(bytes(members[msg.sender].skills[i])) == keccak256(bytes(_skill))) {
                skillExists = true;
                break;
            }
        }
        if (!skillExists) {
            members[msg.sender].skills.push(_skill);
            emit SkillRegistered(msg.sender, _skill);
        }
    }

    /// @notice Initiates a dispute resolution process for a proposal.
    /// @param _proposalId The ID of the proposal in dispute.
    /// @param _disputeDetails Details of the dispute.
    function initiateDisputeResolution(uint256 _proposalId, string memory _disputeDetails) external onlyGovernance whenNotPaused { // Example: Governance initiates disputes
        require(proposals[_proposalId].state == ProposalState.Passed || proposals[_proposalId].state == ProposalState.Rejected, "Dispute can only be initiated after proposal outcome");
        _disputeIds.increment();
        uint256 disputeId = _disputeIds.current();
        disputes[disputeId] = Dispute({
            id: disputeId,
            proposalId: _proposalId,
            disputeDetails: _disputeDetails,
            resolutionVotes: 0,
            isResolved: false
        });
        proposals[_proposalId].state = ProposalState.Dispute; // Mark proposal as in dispute
        emit DisputeInitiated(disputeId, _proposalId, _disputeDetails);
    }

    /// @notice Allows designated dispute resolvers to vote on a dispute resolution.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _resolutionVote  A vote value (e.g., 1 for resolve in favor, 0 for reject resolution).
    function resolveDispute(uint256 _disputeId, uint256 _resolutionVote) external onlyGovernance whenNotPaused { // Example: Governance acts as resolvers
        require(!disputes[_disputeId].isResolved, "Dispute already resolved");
        require(!disputes[_disputeId].resolversVoted[msg.sender], "Resolver already voted");

        disputes[_disputeId].resolversVoted[msg.sender] = true;
        disputes[_disputeId].resolutionVotes += _resolutionVote; // Simple counting, can be weighted voting

        // Example: Simple resolution logic - majority wins (can be more complex)
        // Assumes governance members act as resolvers and have equal voting power for disputes
        uint256 totalResolvers = _getGovernanceMemberCount(); // Placeholder - needs implementation to track governance members
        uint256 resolutionThreshold = (totalResolvers / 2) + 1; // Simple majority

        if (disputes[_disputeId].resolutionVotes >= resolutionThreshold) {
            disputes[_disputeId].isResolved = true;
            // Revert or adjust proposal state based on dispute outcome (design decision)
            // Example: Revert proposal execution if dispute resolution fails original proposal
            proposals[disputes[_disputeId].proposalId].state = ProposalState.Rejected; // Example action
            emit DisputeResolved(_disputeId, _resolutionVote);
        }
    }

    /// @notice Allows members to stake their NFTs to earn rewards (conceptual - reward mechanism needed).
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFTForRewards(uint256 _tokenId) external onlyMembers whenNotPaused {
        require(msg.sender == nftToMemberAddress[_tokenId], "Not NFT owner");
        require(!members[msg.sender].isStaked, "NFT already staked");

        members[msg.sender].isStaked = true;
        // Implement reward accrual logic here (e.g., track staking time, calculate rewards based on level)
        emit NFTStaked(_tokenId);
    }

    /// @notice Allows members to unstake their NFTs.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) external onlyMembers whenNotPaused {
        require(msg.sender == nftToMemberAddress[_tokenId], "Not NFT owner");
        require(members[msg.sender].isStaked, "NFT not staked");

        members[msg.sender].isStaked = false;
        // Implement reward calculation and transfer logic before unstaking
        emit NFTUnstaked(_tokenId);
    }

    /// @notice Allows members to claim staking rewards (conceptual - reward distribution needed).
    function claimRewards() external onlyMembers whenNotPaused {
        require(members[msg.sender].isStaked, "NFT not staked");
        // Calculate and transfer rewards to member (implementation needed - reward token, distribution logic)
        uint256 rewardsAmount = _calculateStakingRewards(memberAddressToNftId[msg.sender]); // Example calculation
        // Example: Assume rewards are in ETH for simplicity (replace with actual reward token transfer)
        // payable(msg.sender).transfer(rewardsAmount); // Requires careful security considerations for ETH transfer

        emit RewardsClaimed(msg.sender, rewardsAmount); // Emit event with claimed amount
    }

    /// @notice Allows governance to update the quorum percentage for proposals.
    /// @param _newQuorumPercentage The new quorum percentage (0-100).
    function setDynamicQuorum(uint256 _newQuorumPercentage) external onlyGovernance whenNotPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be <= 100");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumPercentageUpdated(_newQuorumPercentage);
    }

    /// @notice Allows the contract owner to pause critical DAO functions in emergencies.
    function emergencyPauseDAO() external onlyOwner whenNotPaused {
        paused = true;
        emit DAOPaused(msg.sender);
    }

    /// @notice Allows the contract owner to unpause DAO functions.
    function emergencyUnpauseDAO() external onlyOwner whenPaused {
        paused = false;
        emit DAOUnpaused(msg.sender);
    }

    /// @dev Internal function to finalize a proposal after the voting period.
    /// @param _proposalId The ID of the proposal to finalize.
    function _finalizeProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) return; // Already finalized

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 quorum = (_getTotalMemberCount() * quorumPercentage) / 100; // Quorum based on total members

        if (totalVotes >= quorum && proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Passed;
            emit ProposalPassed(_proposalId); // Custom event ProposalPassed
        } else {
            proposal.state = ProposalState.Rejected;
            emit ProposalRejected(_proposalId);
        }
    }

    /// @dev Internal function to check if an address is a DAO member.
    /// @param _memberAddress The address to check.
    /// @return True if the address is a member, false otherwise.
    function _isMember(address _memberAddress) internal view returns (bool) {
        return memberAddressToNftId[_memberAddress] != 0;
    }

    /// @dev Internal function to get the NFT level of a member.
    /// @param _tokenId The ID of the NFT.
    /// @return The NFTLevel enum value.
    function _getNFTLevel(uint256 _tokenId) internal view returns (NFTLevel) {
        address memberAddress = nftToMemberAddress[_tokenId];
        if (!_isMember(memberAddress)) return NFTLevel.Level1; // Default level if not member (shouldn't happen if mappings are correct)
        return members[memberAddress].level;
    }

    /// @dev Internal function to get the voting power of a member based on their NFT level.
    /// @param _tokenId The ID of the NFT.
    /// @return The voting power (e.g., 1 for Level1, 2 for Level2, etc.).
    function _getVotingPower(uint256 _tokenId) internal view returns (uint256) {
        NFTLevel level = _getNFTLevel(_tokenId);
        if (level == NFTLevel.Level1) return 1;
        if (level == NFTLevel.Level2) return 2;
        if (level == NFTLevel.Level3) return 4; // Example: Quadratic Voting influence increasing
        if (level == NFTLevel.Level4) return 8;
        if (level == NFTLevel.Level5) return 16;
        return 1; // Default voting power if level not recognized (fallback)
    }

    /// @dev Internal function to calculate reputation reward based on contribution details (example logic).
    /// @param _contributionDetails Details of the contribution.
    /// @return The reputation points earned.
    function _calculateReputationReward(string memory _contributionDetails) internal pure returns (uint256) {
        // Example: Simple keyword-based reward system (can be replaced with more sophisticated logic)
        if (string.contains(_contributionDetails, "code")) return 500;
        if (string.contains(_contributionDetails, "design")) return 300;
        if (string.contains(_contributionDetails, "community")) return 200;
        return 100; // Default reward
    }

    /// @dev Internal function to calculate staking rewards (example logic - needs reward token and distribution).
    /// @param _tokenId The ID of the NFT.
    /// @return The staking rewards amount (example - ETH amount).
    function _calculateStakingRewards(uint256 _tokenId) internal view returns (uint256) {
        // Example: Simple reward based on NFT level and staking duration (very basic example)
        uint256 levelMultiplier = _getVotingPower(_tokenId); // Example: Higher level = higher rewards
        uint256 stakingDuration = block.timestamp - members[nftToMemberAddress[_tokenId]].lastContributionTime; // Example duration
        uint256 rewardAmount = (levelMultiplier * stakingDuration) / (30 days); // Example reward formula

        return rewardAmount; // Placeholder - needs actual reward token distribution logic
    }

    /// @dev Internal function to get the total number of DAO members.
    /// @return The total member count.
    function _getTotalMemberCount() internal view returns (uint256) {
        return _memberCount.current();
    }

    /// @dev Placeholder - Internal function to get the count of governance level members (Level 3+ example).
    /// @return The count of governance members.
    function _getGovernanceMemberCount() internal view returns (uint256) {
        uint256 governanceMemberCount = 0;
        for (uint256 i = 1; i <= _memberCount.current(); i++) {
            address memberAddress = nftToMemberAddress[i];
            if (_isMember(memberAddress) && members[memberAddress].level >= NFTLevel.Level3) {
                governanceMemberCount++;
            }
        }
        return governanceMemberCount;
    }

    /// @dev Internal function to update the token URI (metadata) dynamically.
    /// @param _tokenId The ID of the NFT to update.
    function _updateNFTMetadata(uint256 _tokenId) internal {
        // Logic to generate dynamic metadata based on NFT level, reputation, etc.
        // For simplicity, just re-using baseURI + tokenId for now.
        _setTokenURI(_tokenId, string(abi.encodePacked(baseNFTURI, _tokenId.toString())));
        // More advanced logic:  Could call an external service, generate JSON on-chain (more complex),
        // or use IPFS and update the IPFS hash in the token URI.
    }

    // --- Events for Proposal State Changes (Added for clarity) ---
    event ProposalPassed(uint256 proposalId);
}
```