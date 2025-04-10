```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Reputation and Utility Platform (DDRUP)
 * @author Bard (Example Smart Contract)
 * @dev A smart contract showcasing advanced concepts including dynamic reputation,
 *      utility NFTs, decentralized governance, data oracles, and programmable access control.
 *      This contract is designed to be creative and trendy, avoiding duplication of common open-source contracts.
 *
 * **Outline:**
 *
 * 1. **Reputation System:**
 *    - Dynamic reputation points earned through platform participation.
 *    - Reputation decay mechanism over time.
 *    - Reputation levels with tiered benefits.
 *
 * 2. **Utility NFTs (Dynamic Traits):**
 *    - NFTs that represent platform membership and access.
 *    - NFT traits that dynamically update based on user reputation.
 *    - Staking NFTs for enhanced platform features.
 *
 * 3. **Decentralized Governance:**
 *    - Proposal submission and voting mechanism using reputation-weighted voting.
 *    - Different proposal types (platform upgrades, feature requests, content moderation policies).
 *    - Time-locked voting and execution of approved proposals.
 *
 * 4. **Data Oracle Integration (Simulated):**
 *    - Placeholder for integrating external data oracles (e.g., for real-world event verification).
 *    - Example function to simulate oracle data updates affecting contract state.
 *
 * 5. **Programmable Access Control:**
 *    - Role-based access control with customizable roles and permissions.
 *    - Dynamic role assignment based on reputation and platform activity.
 *    - Granular control over function access based on roles.
 *
 * 6. **Advanced Features:**
 *    - Referral program with reputation and NFT rewards.
 *    - Content moderation system with decentralized dispute resolution (simplified).
 *    - Dynamic fee structure adjusted by governance proposals.
 *    - Emergency pause mechanism with multi-sig control.
 *
 * **Function Summary:**
 *
 * 1. `registerUser()`: Allows users to register on the platform and receive a base NFT.
 * 2. `getUserReputation(address user)`: Retrieves the current reputation score of a user.
 * 3. `earnReputationForAction(address user, uint256 actionPoints)`: Adds reputation points to a user for platform actions.
 * 4. `decayUserReputation(address user)`: Decreases user reputation over time based on a decay rate.
 * 5. `getReputationLevel(uint256 reputation)`: Determines the reputation level based on a given reputation score.
 * 6. `mintUtilityNFT(address to)`: Mints a dynamic utility NFT to a user.
 * 7. `getNFTTraits(uint256 tokenId)`: Fetches the dynamic traits of a utility NFT based on the token ID.
 * 8. `stakeNFT(uint256 tokenId)`: Allows users to stake their utility NFT for enhanced benefits.
 * 9. `unstakeNFT(uint256 tokenId)`: Allows users to unstake their utility NFT.
 * 10. `submitGovernanceProposal(string memory proposalTitle, string memory proposalDescription, ProposalType proposalType, bytes memory proposalData)`: Allows users with sufficient reputation to submit governance proposals.
 * 11. `voteOnProposal(uint256 proposalId, bool support)`: Allows users to vote on active governance proposals, weighted by reputation.
 * 12. `getProposalDetails(uint256 proposalId)`: Retrieves details of a governance proposal.
 * 13. `executeProposal(uint256 proposalId)`: Executes an approved governance proposal after the voting period.
 * 14. `simulateOracleDataUpdate(uint256 newDataValue)`: (Simulated) Updates contract state based on external oracle data.
 * 15. `addRole(string memory roleName)`: Adds a new custom role to the platform.
 * 16. `assignRoleToUser(address user, string memory roleName)`: Assigns a specific role to a user.
 * 17. `removeRoleFromUser(address user, string memory roleName)`: Removes a role from a user.
 * 18. `hasRole(address user, string memory roleName)`: Checks if a user has a specific role.
 * 19. `setPlatformFee(uint256 newFee)`: (Governance controlled) Sets a platform-wide fee.
 * 20. `pausePlatform()`: (Emergency) Pauses critical platform functions, only callable by multi-sig owners.
 * 21. `unpausePlatform()`: (Emergency) Resumes platform functions after pausing, only callable by multi-sig owners.
 * 22. `referUser(address referrer, address referred)`: Allows a user to refer another user and earn rewards.
 * 23. `reportContent(uint256 contentId, string memory reason)`: Allows users to report content for moderation.
 * 24. `resolveContentReport(uint256 reportId, ContentModerationResult result)`: (Role-based) Resolves a content report and takes action.
 */

contract DDRUP {
    // --- Enums and Structs ---

    enum ProposalType {
        PLATFORM_UPGRADE,
        FEATURE_REQUEST,
        CONTENT_POLICY,
        PARAMETER_CHANGE
    }

    enum ProposalStatus {
        PENDING,
        ACTIVE,
        REJECTED,
        APPROVED,
        EXECUTED
    }

    enum ContentModerationResult {
        ACCEPTED,
        REJECTED,
        WARNING,
        REMOVED
    }

    struct UserProfile {
        uint256 reputation;
        uint256 lastReputationUpdate;
        uint256 utilityNFTId;
        bool nftStaked;
        // ... more profile data can be added
    }

    struct GovernanceProposal {
        uint256 proposalId;
        ProposalType proposalType;
        ProposalStatus status;
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bytes proposalData; // Flexible data for proposal execution
    }

    struct ContentReport {
        uint256 reportId;
        uint256 contentId;
        address reporter;
        string reason;
        bool resolved;
        ContentModerationResult result;
    }

    // --- State Variables ---

    address public owner;
    mapping(address => UserProfile) public userProfiles;
    uint256 public reputationDecayRate = 1; // Reputation points to decay per time unit
    uint256 public reputationDecayInterval = 7 days; // Time interval for reputation decay
    uint256 public nextProposalId = 1;
    mapping(uint256 => GovernanceProposal) public proposals;
    uint256 public votingDuration = 7 days;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => user => voted
    uint256 public platformFee = 10; // Example fee percentage (e.g., 10%)

    uint256 public nextNFTTokenId = 1;
    mapping(uint256 => address) public nftOwnerOf; // tokenId => owner
    mapping(uint256 => bool) public nftStakedStatus; // tokenId => staked
    string public constant nftName = "DDRUP Utility NFT";
    string public constant nftSymbol = "DDRUPNFT";

    uint256 public oracleDataValue; // Simulated oracle data

    mapping(string => bool) public validRoles;
    mapping(address => mapping(string => bool)) public userRoles;
    address[] public multiSigOwners; // Addresses for emergency functions
    bool public platformPaused = false;

    uint256 public nextReportId = 1;
    mapping(uint256 => ContentReport) public contentReports;

    mapping(address => address) public referralMap; // referrer => referred
    uint256 public referralRewardReputation = 100;

    // --- Events ---

    event UserRegistered(address user, uint256 nftId);
    event ReputationEarned(address user, uint256 reputationPoints, uint256 newReputation);
    event ReputationDecayed(address user, uint256 decayedPoints, uint256 newReputation);
    event UtilityNFTMinted(address to, uint256 tokenId);
    event NFTStaked(uint256 tokenId);
    event NFTUnstaked(uint256 tokenId);
    event GovernanceProposalSubmitted(uint256 proposalId, ProposalType proposalType, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, ProposalStatus status);
    event OracleDataUpdated(uint256 newValue);
    event RoleAdded(string roleName);
    event RoleAssigned(address user, string roleName);
    event RoleRemoved(address user, string roleName);
    event PlatformPaused();
    event PlatformUnpaused();
    event ContentReported(uint256 reportId, uint256 contentId, address reporter, string reason);
    event ContentReportResolved(uint256 reportId, ContentModerationResult result);
    event UserReferred(address referrer, address referred);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMultiSigOwner() {
        bool isOwner = false;
        for (uint256 i = 0; i < multiSigOwners.length; i++) {
            if (msg.sender == multiSigOwners[i]) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Only multi-sig owners can call this function.");
        _;
    }

    modifier onlyRole(string memory roleName) {
        require(hasRole(msg.sender, roleName), "Must have the required role.");
        _;
    }

    modifier platformNotPaused() {
        require(!platformPaused, "Platform is currently paused.");
        _;
    }

    // --- Constructor ---

    constructor(address[] memory _multiSigOwners) {
        owner = msg.sender;
        multiSigOwners = _multiSigOwners;
        validRoles["Moderator"] = true; // Default roles
        validRoles["Admin"] = true;
    }

    // --- Reputation System Functions ---

    function registerUser() external platformNotPaused {
        require(userProfiles[msg.sender].reputation == 0, "User already registered.");
        userProfiles[msg.sender] = UserProfile({
            reputation: 100, // Base reputation upon registration
            lastReputationUpdate: block.timestamp,
            utilityNFTId: nextNFTTokenId,
            nftStaked: false
        });
        mintUtilityNFT(msg.sender);
        emit UserRegistered(msg.sender, nextNFTTokenId);
        nextNFTTokenId++;
    }

    function getUserReputation(address user) external view returns (uint256) {
        _applyReputationDecay(user); // Apply decay before returning current reputation
        return userProfiles[user].reputation;
    }

    function earnReputationForAction(address user, uint256 actionPoints) external platformNotPaused {
        require(userProfiles[user].reputation > 0, "User not registered.");
        _applyReputationDecay(user); // Apply decay before updating
        userProfiles[user].reputation += actionPoints;
        userProfiles[user].lastReputationUpdate = block.timestamp;
        emit ReputationEarned(user, actionPoints, userProfiles[user].reputation);
    }

    function decayUserReputation(address user) external platformNotPaused {
        _applyReputationDecay(user);
    }

    function _applyReputationDecay(address user) private {
        if (userProfiles[user].reputation > 0) {
            uint256 timeElapsed = block.timestamp - userProfiles[user].lastReputationUpdate;
            if (timeElapsed >= reputationDecayInterval) {
                uint256 decayCycles = timeElapsed / reputationDecayInterval;
                uint256 decayedPoints = decayCycles * reputationDecayRate;
                if (userProfiles[user].reputation > decayedPoints) {
                    userProfiles[user].reputation -= decayedPoints;
                    emit ReputationDecayed(user, decayedPoints, userProfiles[user].reputation);
                } else {
                    decayedPoints = userProfiles[user].reputation; // Decay to zero if less than decay points
                    userProfiles[user].reputation = 0;
                    emit ReputationDecayed(user, decayedPoints, userProfiles[user].reputation);
                }
                userProfiles[user].lastReputationUpdate = block.timestamp;
            }
        }
    }

    function getReputationLevel(uint256 reputation) external pure returns (string memory) {
        if (reputation >= 10000) {
            return "Legendary";
        } else if (reputation >= 5000) {
            return "Master";
        } else if (reputation >= 1000) {
            return "Expert";
        } else if (reputation >= 500) {
            return "Intermediate";
        } else {
            return "Beginner";
        }
    }

    // --- Utility NFT Functions ---

    function mintUtilityNFT(address to) private {
        uint256 tokenId = nextNFTTokenId;
        nftOwnerOf[tokenId] = to;
        emit UtilityNFTMinted(to, tokenId);
        // In a real NFT contract, you'd implement ERC721 logic here (e.g., _mint, tokenURI)
    }

    function getNFTTraits(uint256 tokenId) external view returns (string memory) {
        address ownerAddress = nftOwnerOf[tokenId];
        require(ownerAddress != address(0), "NFT does not exist.");
        uint256 reputation = getUserReputation(ownerAddress);
        string memory level = getReputationLevel(reputation);
        string memory stakedStatus = nftStakedStatus[tokenId] ? "Staked" : "Unstaked";
        // Dynamically generate NFT traits based on reputation, level, staked status, etc.
        return string(abi.encodePacked("Level: ", level, ", Reputation: ", uintToString(reputation), ", Status: ", stakedStatus));
    }

    function stakeNFT(uint256 tokenId) external platformNotPaused {
        require(nftOwnerOf[tokenId] == msg.sender, "Not NFT owner.");
        require(!nftStakedStatus[tokenId], "NFT already staked.");
        nftStakedStatus[tokenId] = true;
        emit NFTStaked(tokenId);
        // Implement staking benefits here (e.g., boosted reputation gain, access to features)
    }

    function unstakeNFT(uint256 tokenId) external platformNotPaused {
        require(nftOwnerOf[tokenId] == msg.sender, "Not NFT owner.");
        require(nftStakedStatus[tokenId], "NFT not staked.");
        nftStakedStatus[tokenId] = false;
        emit NFTUnstaked(tokenId);
        // Revert staking benefits here
    }


    // --- Governance Functions ---

    function submitGovernanceProposal(
        string memory proposalTitle,
        string memory proposalDescription,
        ProposalType proposalType,
        bytes memory proposalData
    ) external platformNotPaused {
        require(getUserReputation(msg.sender) >= 500, "Insufficient reputation to propose."); // Example reputation threshold
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposalType: proposalType,
            status: ProposalStatus.PENDING,
            title: proposalTitle,
            description: proposalDescription,
            proposer: msg.sender,
            startTime: 0,
            endTime: 0,
            yesVotes: 0,
            noVotes: 0,
            proposalData: proposalData
        });
        emit GovernanceProposalSubmitted(proposalId, proposalType, proposalTitle, msg.sender);
    }

    function voteOnProposal(uint256 proposalId, bool support) external platformNotPaused {
        require(proposals[proposalId].status == ProposalStatus.PENDING, "Proposal not in PENDING status.");
        require(proposals[proposalId].endTime == 0, "Voting has already started/ended.");
        require(!proposalVotes[proposalId][msg.sender], "Already voted on this proposal.");

        if (proposals[proposalId].startTime == 0) {
            proposals[proposalId].startTime = block.timestamp;
            proposals[proposalId].endTime = block.timestamp + votingDuration;
            proposals[proposalId].status = ProposalStatus.ACTIVE;
        }

        uint256 votingPower = getUserReputation(msg.sender); // Reputation-weighted voting
        proposalVotes[proposalId][msg.sender] = true;

        if (support) {
            proposals[proposalId].yesVotes += votingPower;
        } else {
            proposals[proposalId].noVotes += votingPower;
        }
        emit ProposalVoted(proposalId, msg.sender, support);
    }

    function getProposalDetails(uint256 proposalId) external view returns (GovernanceProposal memory) {
        return proposals[proposalId];
    }

    function executeProposal(uint256 proposalId) external platformNotPaused {
        require(proposals[proposalId].status == ProposalStatus.ACTIVE, "Proposal not in ACTIVE status.");
        require(block.timestamp > proposals[proposalId].endTime, "Voting period not ended.");
        require(proposals[proposalId].status != ProposalStatus.EXECUTED, "Proposal already executed.");

        if (proposals[proposalId].yesVotes > proposals[proposalId].noVotes) {
            proposals[proposalId].status = ProposalStatus.APPROVED;
            _executeProposalActions(proposals[proposalId]); // Execute proposal-specific actions
            proposals[proposalId].status = ProposalStatus.EXECUTED;
            emit ProposalExecuted(proposalId, ProposalStatus.EXECUTED);
        } else {
            proposals[proposalId].status = ProposalStatus.REJECTED;
            emit ProposalExecuted(proposalId, ProposalStatus.REJECTED);
        }
    }

    function _executeProposalActions(GovernanceProposal memory proposal) private {
        if (proposal.proposalType == ProposalType.PARAMETER_CHANGE) {
            // Example: Assume proposalData contains new platform fee encoded as uint256
            uint256 newFee = abi.decode(proposal.proposalData, (uint256));
            setPlatformFee(newFee);
        }
        // Add logic for other proposal types (PLATFORM_UPGRADE, FEATURE_REQUEST, CONTENT_POLICY)
    }


    // --- Data Oracle Integration (Simulated) ---

    function simulateOracleDataUpdate(uint256 newDataValue) external onlyOwner {
        oracleDataValue = newDataValue;
        emit OracleDataUpdated(newDataValue);
        // Example: Contract logic can react to oracleDataValue changes
        if (newDataValue > 1000) {
            reputationDecayRate = 2; // Example: Increase decay rate if oracle data is high
        } else {
            reputationDecayRate = 1;
        }
    }


    // --- Programmable Access Control Functions ---

    function addRole(string memory roleName) external onlyOwner {
        require(!validRoles[roleName], "Role already exists.");
        validRoles[roleName] = true;
        emit RoleAdded(roleName);
    }

    function assignRoleToUser(address user, string memory roleName) external onlyRole("Admin") {
        require(validRoles[roleName], "Role does not exist.");
        userRoles[user][roleName] = true;
        emit RoleAssigned(user, roleName);
    }

    function removeRoleFromUser(address user, string memory roleName) external onlyRole("Admin") {
        require(validRoles[roleName], "Role does not exist.");
        delete userRoles[user][roleName];
        emit RoleRemoved(user, roleName);
    }

    function hasRole(address user, string memory roleName) public view returns (bool) {
        return validRoles[roleName] && userRoles[user][roleName];
    }


    // --- Platform Parameter Functions (Governance Controlled) ---

    function setPlatformFee(uint256 newFee) public platformNotPaused {
        // This function is intended to be called via governance proposal execution
        // Security: Ensure only governance can change this, or add access control as needed.
        platformFee = newFee;
    }


    // --- Emergency Pause Mechanism (Multi-Sig Controlled) ---

    function pausePlatform() external onlyMultiSigOwner {
        require(!platformPaused, "Platform already paused.");
        platformPaused = true;
        emit PlatformPaused();
    }

    function unpausePlatform() external onlyMultiSigOwner {
        require(platformPaused, "Platform not paused.");
        platformPaused = false;
        emit PlatformUnpaused();
    }


    // --- Referral Program ---

    function referUser(address referrer, address referred) external platformNotPaused {
        require(userProfiles[referrer].reputation > 0, "Referrer must be registered.");
        require(userProfiles[referred].reputation == 0, "Referred user must not be registered yet.");
        require(referralMap[referred] == address(0), "User already referred by someone.");

        referralMap[referred] = referrer;
        earnReputationForAction(referrer, referralRewardReputation); // Reward referrer
        emit UserReferred(referrer, referred);
    }


    // --- Content Moderation (Simplified) ---

    function reportContent(uint256 contentId, string memory reason) external platformNotPaused {
        uint256 reportId = nextReportId++;
        contentReports[reportId] = ContentReport({
            reportId: reportId,
            contentId: contentId,
            reporter: msg.sender,
            reason: reason,
            resolved: false,
            result: ContentModerationResult.PENDING // Initially pending
        });
        emit ContentReported(reportId, contentId, msg.sender, reason);
    }

    function resolveContentReport(uint256 reportId, ContentModerationResult result) external onlyRole("Moderator") platformNotPaused {
        require(!contentReports[reportId].resolved, "Report already resolved.");
        contentReports[reportId].resolved = true;
        contentReports[reportId].result = result;
        emit ContentReportResolved(reportId, result);
        // Implement actions based on moderation result (e.g., remove content, warn user)
    }


    // --- Utility Function (String Conversion for NFT Traits) ---
    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = uint8((48 + _i % 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
```