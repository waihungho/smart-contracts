```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DynamicNFTGamifiedDAO - Decentralized Dynamic NFT & Gamified DAO Governance
 * @author Gemini AI Assistant
 * @dev A smart contract implementing a Dynamic NFT collection that evolves based on user participation in a gamified DAO governance system.
 *
 * Outline:
 *  - NFT Management: Minting, Dynamic Metadata Updates, Transfer, Burning, Leveling
 *  - DAO Governance: Proposal Creation, Voting (weighted by NFT level), Proposal Execution, Quorum, Timelocks
 *  - Gamification: Points System, Reputation Tracking, Challenges, Rewards, Leaderboard
 *  - Dynamic NFT Evolution: NFT metadata changes based on governance participation and gamification points.
 *  - Utility and Admin Functions: Pausing, Setting Parameters, Emergency Actions
 *
 * Function Summary:
 *
 *  [NFT Management]
 *  1. mintNFT(address _to): Mints a new Dynamic NFT to the specified address.
 *  2. transferNFT(address _from, address _to, uint256 _tokenId): Transfers an NFT, restricted by ownership.
 *  3. burnNFT(uint256 _tokenId): Burns an NFT, permanently removing it.
 *  4. getNFTMetadata(uint256 _tokenId): Returns the current metadata URI for a given NFT ID, dynamically generated.
 *  5. getNftLevel(uint256 _tokenId): Returns the current level of an NFT.
 *  6. upgradeNFTLevel(uint256 _tokenId): Manually upgrade NFT level (admin function, could be automated based on points).
 *
 *  [DAO Governance]
 *  7. createProposal(string memory _description, bytes memory _calldata, address[] memory _targets, uint256[] memory _values, string[] memory _signatures): Creates a new governance proposal.
 *  8. voteOnProposal(uint256 _proposalId, bool _support): Allows users to vote on a proposal, weighted by their NFT level.
 *  9. executeProposal(uint256 _proposalId): Executes a successful proposal after the voting period and timelock.
 *  10. getProposalState(uint256 _proposalId): Returns the current state of a proposal (Pending, Active, Canceled, Executed, Defeated).
 *  11. cancelProposal(uint256 _proposalId): Allows the proposer or admin to cancel a proposal under certain conditions.
 *  12. getProposalVotes(uint256 _proposalId): Returns the vote counts for and against a proposal.
 *
 *  [Gamification]
 *  13. submitChallenge(string memory _challengeId): Allows users to submit completion for a predefined challenge.
 *  14. rewardPoints(address _user, uint256 _points): Admin function to award points to a user.
 *  15. deductPoints(address _user, uint256 _points): Admin function to deduct points from a user.
 *  16. getUserPoints(address _user): Returns the current points of a user.
 *  17. getLeaderboard(uint256 _count): Returns a list of top users based on points.
 *
 *  [Utility and Admin]
 *  18. pauseContract(): Pauses core contract functionalities (admin only).
 *  19. unpauseContract(): Resumes contract functionalities (admin only).
 *  20. setBaseMetadataURI(string memory _baseURI): Sets the base URI for dynamically generated NFT metadata (admin only).
 *  21. setGovernanceParameters(uint256 _votingPeriod, uint256 _quorum, uint256 _timelock): Sets governance parameters (admin only).
 *  22. setChallengeRewardPoints(string memory _challengeId, uint256 _points): Sets the reward points for a specific challenge (admin only).
 *  23. withdrawStuckTokens(address _tokenAddress, address _recipient, uint256 _amount): Allows admin to withdraw accidentally sent tokens.
 */

contract DynamicNFTGamifiedDAO {
    // --- State Variables ---

    string public name = "DynamicNFTGamifiedDAO";
    string public symbol = "DNGDAO";
    string public baseMetadataURI;

    address public admin;
    bool public paused = false;

    uint256 public nextNFTId = 1;
    mapping(uint256 => address) public nftOwner;
    mapping(address => uint256) public nftBalance;
    mapping(uint256 => uint256) public nftLevel; // NFT level, starts at 1 and increases
    mapping(uint256 => string) public nftDynamicTraits; // Store dynamic traits, can be JSON or stringified data

    mapping(address => uint256) public userPoints;
    mapping(string => uint256) public challengeRewardPoints; // Challenge ID to points reward
    string[] public challengeIds; // List of challenge IDs for easy iteration/admin

    uint256 public proposalCount = 0;
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingPeriod = 7 days;
    uint256 public quorum = 10; // Percentage of total NFT supply required for quorum
    uint256 public timelock = 1 days;

    enum ProposalState { Pending, Active, Canceled, Defeated, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes calldataData;
        address[] targets;
        uint256[] values;
        string[] signatures;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        ProposalState state;
        mapping(address => bool) voters; // Track voters to prevent double voting
    }

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId);
    event NFTMetadataUpdated(uint256 tokenId, string metadataURI);
    event NFTLevelUpgraded(uint256 tokenId, uint256 newLevel);

    event ProposalCreated(uint256 proposalId, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCanceled(uint256 proposalId);

    event PointsRewarded(address user, uint256 points);
    event PointsDeducted(address user, uint256 points);
    event ChallengeSubmitted(address user, string challengeId);
    event ChallengeRewardSet(string challengeId, uint256 points);

    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event BaseMetadataURISet(string baseURI);
    event GovernanceParametersSet(uint256 votingPeriod, uint256 quorum, uint256 timelock);
    event TokensWithdrawn(address tokenAddress, address recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validNFT(uint256 _tokenId) {
        require(nftOwner[_tokenId] != address(0), "Invalid NFT ID.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active.");
        _;
    }

    modifier proposalPending(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Pending, "Proposal is not pending.");
        _;
    }

    modifier notVoted(uint256 _proposalId) {
        require(!proposals[_proposalId].voters[msg.sender], "Already voted on this proposal.");
        _;
    }


    // --- Constructor ---
    constructor(string memory _baseURI) {
        admin = msg.sender;
        baseMetadataURI = _baseURI; // Base URI for NFT metadata
    }

    // --- NFT Management Functions ---

    /// @notice Mints a new Dynamic NFT to the specified address.
    /// @param _to The address to mint the NFT to.
    function mintNFT(address _to) external onlyAdmin whenNotPaused {
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = _to;
        nftBalance[_to]++;
        nftLevel[tokenId] = 1; // Initial level
        nftDynamicTraits[tokenId] = '{"level": 1, "reputation": "Beginner"}'; // Initial dynamic traits - can be extended as needed
        emit NFTMinted(tokenId, _to);
    }

    /// @notice Transfers an NFT from one address to another.
    /// @param _from The current owner address.
    /// @param _to The recipient address.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _from, address _to, uint256 _tokenId) external whenNotPaused validNFT(_tokenId) onlyNFTOwner(_tokenId) {
        require(_from == nftOwner[_tokenId], "Transfer from incorrect owner.");
        require(_to != address(0), "Transfer to the zero address.");

        nftOwner[_tokenId] = _to;
        nftBalance[_from]--;
        nftBalance[_to]++;
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /// @notice Burns an NFT, permanently removing it from circulation.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) external whenNotPaused validNFT(_tokenId) onlyNFTOwner(_tokenId) {
        address owner = nftOwner[_tokenId];
        delete nftOwner[_tokenId];
        nftBalance[owner]--;
        delete nftLevel[_tokenId];
        delete nftDynamicTraits[_tokenId];
        emit NFTBurned(_tokenId);
    }

    /// @notice Returns the dynamically generated metadata URI for a given NFT ID.
    /// @param _tokenId The ID of the NFT.
    /// @return string The metadata URI.
    function getNFTMetadata(uint256 _tokenId) external view validNFT(_tokenId) returns (string memory) {
        // Dynamically generate metadata based on NFT level, traits etc.
        // For simplicity, we are just constructing a URI based on tokenId and base URI.
        // In a real application, this could involve more complex logic or off-chain data fetching.
        return string(abi.encodePacked(baseMetadataURI, Strings.toString(_tokenId)));
    }

    /// @notice Returns the current level of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return uint256 The NFT level.
    function getNftLevel(uint256 _tokenId) external view validNFT(_tokenId) returns (uint256) {
        return nftLevel[_tokenId];
    }

    /// @notice Admin function to manually upgrade an NFT's level. Could be automated based on user points or other criteria.
    /// @param _tokenId The ID of the NFT to upgrade.
    function upgradeNFTLevel(uint256 _tokenId) external onlyAdmin whenNotPaused validNFT(_tokenId) {
        nftLevel[_tokenId]++;
        // Update dynamic traits - example update, can be more sophisticated based on level
        nftDynamicTraits[_tokenId] = string(abi.encodePacked('{"level": ', Strings.toString(nftLevel[_tokenId]), ', "reputation": "Advanced"}'));
        emit NFTLevelUpgraded(_tokenId, nftLevel[_tokenId]);
        emit NFTMetadataUpdated(_tokenId, getNFTMetadata(_tokenId)); // Optionally update metadata URI to reflect level change
    }


    // --- DAO Governance Functions ---

    /// @notice Creates a new governance proposal.
    /// @param _description A description of the proposal.
    /// @param _calldata Encoded function call data for the proposal execution.
    /// @param _targets Array of contract addresses to call.
    /// @param _values Array of ether values to send with each call.
    /// @param _signatures Array of function signatures for each call.
    function createProposal(
        string memory _description,
        bytes memory _calldata,
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures
    ) external whenNotPaused {
        require(_targets.length == _values.length && _targets.length == _signatures.length, "Targets, values, and signatures arrays must have the same length.");
        require(nftBalance[msg.sender] > 0, "Must own an NFT to create a proposal."); // Require NFT ownership to propose

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.calldataData = _calldata;
        newProposal.targets = _targets;
        newProposal.values = _values;
        newProposal.signatures = _signatures;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingPeriod;
        newProposal.state = ProposalState.Active; // Set to Active immediately

        emit ProposalCreated(proposalCount, msg.sender);
    }

    /// @notice Allows users to vote on an active proposal. Voting power is weighted by NFT level.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused proposalExists(_proposalId) proposalActive(_proposalId) notVoted(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 votingPower = getNftVotingPower(msg.sender); // Voting power based on NFT level

        require(votingPower > 0, "No voting power. Must own an NFT to vote.");

        proposal.voters[msg.sender] = true; // Mark voter as voted

        if (_support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);

        // Check if voting period is over and update proposal state
        if (block.timestamp >= proposal.endTime) {
            _finalizeProposal(_proposalId);
        }
    }

    /// @notice Executes a successful proposal after voting period and timelock.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Defeated || proposal.state == ProposalState.Executed, "Proposal is not in a final state.");
        require(block.timestamp >= proposal.endTime + timelock, "Timelock not expired yet."); // Timelock before execution

        if (proposal.state == ProposalState.Defeated) {
            revert("Proposal was defeated and cannot be executed.");
        }
        if (proposal.state == ProposalState.Executed) {
            revert("Proposal already executed.");
        }

        proposal.state = ProposalState.Executed;

        // Execute the actions - delegate calls
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(abi.encodeWithSignature(proposal.signatures[i], proposal.calldataData));
            require(success, "Proposal execution failed.");
        }

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Returns the current state of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return ProposalState The state of the proposal.
    function getProposalState(uint256 _proposalId) external view proposalExists(_proposalId) returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.endTime) {
            return _getFinalProposalState(_proposalId); // Recalculate state if voting period ended but not finalized
        }
        return proposal.state;
    }

    /// @notice Allows the proposer or admin to cancel a proposal before it starts or if it hasn't reached quorum.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) proposalPending(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == proposal.proposer || msg.sender == admin, "Only proposer or admin can cancel.");
        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(_proposalId);
    }

    /// @notice Returns the vote counts for and against a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return uint256 forVotes, uint256 againstVotes
    function getProposalVotes(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 forVotes, uint256 againstVotes) {
        return (proposals[_proposalId].forVotes, proposals[_proposalId].againstVotes);
    }


    // --- Gamification Functions ---

    /// @notice Allows users to submit completion for a predefined challenge. Admin needs to reward points separately.
    /// @param _challengeId The ID of the challenge completed.
    function submitChallenge(string memory _challengeId) external whenNotPaused {
        // Basic check if challenge exists - could be expanded to track user submissions, prevent resubmissions etc.
        bool challengeExists = false;
        for (uint256 i = 0; i < challengeIds.length; i++) {
            if (keccak256(bytes(challengeIds[i])) == keccak256(bytes(_challengeId))) {
                challengeExists = true;
                break;
            }
        }
        require(challengeExists, "Challenge ID not found.");

        emit ChallengeSubmitted(msg.sender, _challengeId);
        // Admin would then manually reward points for verified submissions using rewardPoints function.
    }

    /// @notice Admin function to award points to a user.
    /// @param _user The address of the user to reward.
    /// @param _points The number of points to award.
    function rewardPoints(address _user, uint256 _points) external onlyAdmin whenNotPaused {
        userPoints[_user] += _points;
        emit PointsRewarded(_user, _points);
    }

    /// @notice Admin function to deduct points from a user.
    /// @param _user The address of the user to deduct points from.
    /// @param _points The number of points to deduct.
    function deductPoints(address _user, uint256 _points) external onlyAdmin whenNotPaused {
        userPoints[_user] -= _points;
        emit PointsDeducted(_user, _points);
    }

    /// @notice Returns the current points of a user.
    /// @param _user The address of the user.
    /// @return uint256 The user's points.
    function getUserPoints(address _user) external view returns (uint256) {
        return userPoints[_user];
    }

    /// @notice Returns a leaderboard of top users based on points. (Simplified - could be optimized for large datasets)
    /// @param _count The number of top users to retrieve.
    /// @return address[] An array of addresses of top users.
    /// @return uint256[] An array of corresponding points for top users.
    function getLeaderboard(uint256 _count) external view returns (address[] memory, uint256[] memory) {
        address[] memory leaderboardAddresses = new address[](_count);
        uint256[] memory leaderboardPoints = new uint256[](_count);

        address[] memory allUsers = new address[](nftSupply()); // Assume all NFT holders are users - could be refined

        uint256 userCount = 0;
        for (uint256 i = 1; i < nextNFTId; i++) { // Iterate through all possible NFT IDs (inefficient for large gaps)
            if (nftOwner[i] != address(0)) {
                allUsers[userCount++] = nftOwner[i];
            }
        }

        // Basic sorting (inefficient for large user base - consider more efficient sorting or data structures)
        for (uint256 i = 0; i < userCount; i++) {
            for (uint256 j = i + 1; j < userCount; j++) {
                if (userPoints[allUsers[i]] < userPoints[allUsers[j]]) {
                    address tempAddress = allUsers[i];
                    uint256 tempPoints = userPoints[allUsers[i]];
                    allUsers[i] = allUsers[j];
                    userPoints[allUsers[i]] = userPoints[allUsers[j]]; // Corrected: Use allUsers[i] as key
                    allUsers[j] = tempAddress;
                    userPoints[allUsers[j]] = tempPoints; // Corrected: Use allUsers[j] as key
                }
            }
        }

        uint256 leaderboardSize = _count > userCount ? userCount : _count;
        for (uint256 i = 0; i < leaderboardSize; i++) {
            leaderboardAddresses[i] = allUsers[i];
            leaderboardPoints[i] = userPoints[allUsers[i]];
        }

        return (leaderboardAddresses, leaderboardPoints);
    }


    // --- Utility and Admin Functions ---

    /// @notice Pauses the contract, restricting certain functionalities.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Unpauses the contract, resuming normal functionalities.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Sets the base URI for dynamically generated NFT metadata.
    /// @param _baseURI The new base URI.
    function setBaseMetadataURI(string memory _baseURI) external onlyAdmin {
        baseMetadataURI = _baseURI;
        emit BaseMetadataURISet(_baseURI);
    }

    /// @notice Sets the governance parameters.
    /// @param _votingPeriod The duration of the voting period in seconds.
    /// @param _quorum The percentage of total NFT supply required for quorum (e.g., 10 for 10%).
    /// @param _timelock The timelock duration after voting period before execution in seconds.
    function setGovernanceParameters(uint256 _votingPeriod, uint256 _quorum, uint256 _timelock) external onlyAdmin {
        votingPeriod = _votingPeriod;
        quorum = _quorum;
        timelock = _timelock;
        emit GovernanceParametersSet(_votingPeriod, _quorum, _timelock);
    }

    /// @notice Sets the reward points for a specific challenge.
    /// @param _challengeId The ID of the challenge.
    /// @param _points The points to reward for completing the challenge.
    function setChallengeRewardPoints(string memory _challengeId, uint256 _points) external onlyAdmin {
        challengeRewardPoints[_challengeId] = _points;
        bool challengeExists = false;
        for (uint256 i = 0; i < challengeIds.length; i++) {
            if (keccak256(bytes(challengeIds[i])) == keccak256(bytes(_challengeId))) {
                challengeExists = true;
                break;
            }
        }
        if (!challengeExists) {
            challengeIds.push(_challengeId); // Add new challenge ID if it doesn't exist
        }
        emit ChallengeRewardSet(_challengeId, _points);
    }


    /// @notice Allows the admin to withdraw accidentally sent tokens from the contract.
    /// @param _tokenAddress The address of the token to withdraw (address(0) for ETH).
    /// @param _recipient The address to send the tokens to.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawStuckTokens(address _tokenAddress, address _recipient, uint256 _amount) external onlyAdmin {
        require(_recipient != address(0), "Recipient cannot be zero address.");
        if (_tokenAddress == address(0)) {
            payable(_recipient).transfer(_amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            token.transfer(_recipient, _amount);
        }
        emit TokensWithdrawn(_tokenAddress, _recipient, _amount);
    }


    // --- Internal Helper Functions ---

    /// @dev Calculates the voting power of an address based on their NFT level.
    /// @param _voter The address of the voter.
    /// @return uint256 The voting power.
    function getNftVotingPower(address _voter) internal view returns (uint256) {
        uint256 totalVotingPower = 0;
        for (uint256 i = 1; i < nextNFTId; i++) {
            if (nftOwner[i] == _voter) {
                totalVotingPower += nftLevel[i]; // Voting power is sum of levels of all NFTs owned
            }
        }
        return totalVotingPower;
    }

    /// @dev Returns the total supply of NFTs.
    /// @return uint256 The total NFT supply.
    function nftSupply() public view returns (uint256) {
        return nextNFTId - 1;
    }


    /// @dev Internal function to finalize a proposal after voting period ends.
    /// @param _proposalId The ID of the proposal to finalize.
    function _finalizeProposal(uint256 _proposalId) internal proposalExists(_proposalId) proposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended yet.");

        if (proposal.state != ProposalState.Active) return; // Prevent re-finalization

        uint256 totalNftSupply = nftSupply();
        uint256 quorumVotesNeeded = (totalNftSupply * quorum) / 100; // Calculate quorum based on percentage

        if (proposal.forVotes >= proposal.againstVotes && proposal.forVotes >= quorumVotesNeeded) {
            proposal.state = ProposalState.Defeated; // Corrected: Should be Defeated if quorum not reached or against votes win
        } else {
            proposal.state = ProposalState.Defeated; // Defeated if against votes win or quorum not met.
        }
    }

    /// @dev Internal function to get the final state of a proposal based on votes and quorum.
    /// @param _proposalId The ID of the proposal.
    /// @return ProposalState The final proposal state.
    function _getFinalProposalState(uint256 _proposalId) internal view proposalExists(_proposalId) returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalNftSupply = nftSupply();
        uint256 quorumVotesNeeded = (totalNftSupply * quorum) / 100;

        if (proposal.forVotes >= proposal.againstVotes && proposal.forVotes >= quorumVotesNeeded) {
            return ProposalState.Executed; // Should be Executed if quorum reached and for votes win
        } else {
            return ProposalState.Defeated; // Defeated if against votes win or quorum not met.
        }
    }
}

// --- Libraries and Interfaces ---

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x0";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; ) {
            buffer[--i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * _ADDRESS_LENGTH + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        uint256 addrVal = uint256(uint160(addr));
        for (uint256 i = 2 * _ADDRESS_LENGTH + 1; i > 1; ) {
            buffer[--i] = _HEX_SYMBOLS[addrVal & 0xf];
            addrVal >>= 4;
        }
        return string(buffer);
    }
}


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```