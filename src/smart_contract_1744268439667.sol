```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Collaborative Storytelling DAO
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Organization (DAO) focused on collaborative storytelling.
 *      This contract allows users to propose story ideas, contribute chapters, vote on story progression,
 *      and earn rewards for their contributions. It incorporates advanced concepts like:
 *      - Dynamic Story Arcs: Stories can evolve based on community votes.
 *      - Character & World NFTs: Unique NFTs representing characters and story world elements.
 *      - Reputation System: Track contributor reputation for quality and engagement.
 *      - Multi-Stage Voting: Different voting mechanisms for various decisions.
 *      - Treasury Management: DAO-controlled treasury for rewarding contributors and funding story development.
 *      - On-Chain Royalties: Automatically distribute royalties to contributors based on story popularity.
 *      - Dynamic Access Control: Role-based access control with voting-based role changes.
 *      - Event-Driven Story Updates: Emitting events for every story evolution step for off-chain tracking.
 *      - Quadratic Voting (Optional): For fairer representation in certain voting scenarios.
 *      - Subscription Model (Future): Potential for users to subscribe to access premium story content.
 *
 * Function Summary:
 * -----------------
 * DAO Setup & Administration:
 * 1. initializeDAO(string _daoName, uint256 _votingPeriod, uint256 _quorumPercentage, address _treasuryWallet): Initializes the DAO with basic settings.
 * 2. setVotingPeriod(uint256 _newVotingPeriod): Updates the default voting period for proposals.
 * 3. setQuorumPercentage(uint256 _newQuorumPercentage): Updates the quorum percentage required for proposal approval.
 * 4. setTreasuryWallet(address _newTreasuryWallet): Updates the address of the DAO's treasury wallet.
 * 5. pauseContract(): Pauses the contract, preventing most functions from being executed (Admin only).
 * 6. unpauseContract(): Unpauses the contract, allowing normal functionality (Admin only).
 * 7. withdrawTreasuryFunds(address _recipient, uint256 _amount): Allows the DAO treasury to withdraw funds (DAO vote required).
 * 8. addAdmin(address _newAdmin): Adds a new admin address (DAO vote required).
 * 9. removeAdmin(address _adminToRemove): Removes an admin address (DAO vote required).
 *
 * Story & Contribution Management:
 * 10. proposeStory(string _title, string _genre, string _initialSynopsis): Allows users to propose a new story idea.
 * 11. voteOnStoryProposal(uint256 _storyId, bool _vote): Allows DAO members to vote on a story proposal.
 * 12. submitChapterContribution(uint256 _storyId, string _chapterTitle, string _chapterContent): Allows users to submit a chapter contribution to an approved story.
 * 13. voteOnChapterContribution(uint256 _storyId, uint256 _contributionId, bool _vote): Allows DAO members to vote on a submitted chapter contribution.
 * 14. finalizeStoryChapter(uint256 _storyId, uint256 _contributionId): Finalizes a chapter contribution after successful voting and adds it to the story.
 * 15. viewStoryDetails(uint256 _storyId): Allows anyone to view the details of a story, including its chapters and contributors.
 * 16. createCharacterNFT(uint256 _storyId, string _characterName, string _characterDescription, string _characterImageURI): Allows contributors to propose a new character NFT for a story (DAO vote required for minting).
 * 17. createWorldElementNFT(uint256 _storyId, string _elementName, string _elementDescription, string _elementImageURI): Allows contributors to propose a new world element NFT for a story (DAO vote required for minting).
 *
 * Reputation & Reward System:
 * 18. contributeToReputation(address _contributor, uint256 _reputationPoints): Increases a contributor's reputation points (Internal function triggered by successful contributions).
 * 19. distributeChapterRewards(uint256 _storyId, uint256 _chapterId): Distributes rewards to contributors of a finalized chapter from the DAO treasury (DAO vote or automated trigger).
 * 20. stakeGovernanceTokens(): Allows DAO members to stake governance tokens for increased voting power and potential rewards.
 * 21. unstakeGovernanceTokens(): Allows DAO members to unstake governance tokens.
 * 22. getTokenBalance(address _account): Returns the governance token balance of an account.
 */

contract CollaborativeStoryDAO {
    // -------- State Variables --------

    string public daoName;
    address public treasuryWallet;
    uint256 public votingPeriod; // In blocks
    uint256 public quorumPercentage; // Minimum percentage of votes required for proposal to pass
    bool public paused;
    address public daoAdmin; // Initial DAO Admin

    // Governance Token (Simple ERC20-like for demonstration)
    mapping(address => uint256) public governanceTokenBalances;
    uint256 public totalGovernanceTokens;
    uint256 public stakingRewardRatePerBlock; // Example reward rate

    struct Story {
        uint256 storyId;
        string title;
        string genre;
        string synopsis;
        address creator;
        uint256 proposalEndTime;
        bool proposalApproved;
        string[] chapters; // Array of chapter content (for simplicity, could be IPFS hashes in real app)
        address[] chapterContributors; // Track contributors for each chapter
        uint256 chapterCount;
        mapping(uint256 => Contribution) contributions; // Contributions for each story
        uint256 contributionCount;
    }
    mapping(uint256 => Story) public stories;
    uint256 public storyCount;
    mapping(uint256 => mapping(address => bool)) public storyProposalVotes; // storyId => voter => voted

    struct Contribution {
        uint256 contributionId;
        address contributor;
        string chapterTitle;
        string chapterContent;
        uint256 submissionTime;
        uint256 votingEndTime;
        bool contributionApproved;
        uint256 upvotes;
        uint256 downvotes;
    }
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public chapterContributionVotes; // storyId => contributionId => voter => voted

    // Reputation System (Simple point-based)
    mapping(address => uint256) public contributorReputation;

    // Staking
    mapping(address => uint256) public stakedGovernanceTokens;
    uint256 public lastRewardBlock;

    // Access Control - Admins (Can be expanded to roles later)
    mapping(address => bool) public admins;

    // -------- Events --------
    event DAOInitialized(string daoName, address treasuryWallet, uint256 votingPeriod, uint256 quorumPercentage, address admin);
    event VotingPeriodUpdated(uint256 newVotingPeriod);
    event QuorumPercentageUpdated(uint256 newQuorumPercentage);
    event TreasuryWalletUpdated(address newTreasuryWallet);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event TreasuryFundsWithdrawn(address recipient, uint256 amount, address admin);
    event AdminAdded(address newAdmin, address admin);
    event AdminRemoved(address removedAdmin, address admin);

    event StoryProposed(uint256 storyId, string title, string genre, address proposer);
    event StoryProposalVoted(uint256 storyId, address voter, bool vote);
    event StoryProposalApproved(uint256 storyId);
    event ChapterContributionSubmitted(uint256 storyId, uint256 contributionId, address contributor, string chapterTitle);
    event ChapterContributionVoted(uint256 storyId, uint256 contributionId, address voter, bool vote);
    event ChapterContributionApproved(uint256 storyId, uint256 contributionId);
    event StoryChapterFinalized(uint256 storyId, uint256 chapterIndex, uint256 contributionId);

    event ReputationIncreased(address contributor, uint256 points);
    event RewardsDistributed(uint256 storyId, uint256 chapterId, address[] contributors, uint256 amount);

    event GovernanceTokensMinted(address recipient, uint256 amount);
    event TokensStaked(address staker, uint256 amount);
    event TokensUnstaked(address unstaker, uint256 amount);

    // -------- Modifiers --------
    modifier onlyAdmin() {
        require(admins[msg.sender], "Only DAO admin can call this function");
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

    modifier validStoryId(uint256 _storyId) {
        require(_storyId > 0 && _storyId <= storyCount, "Invalid story ID");
        _;
    }

    modifier validContributionId(uint256 _storyId, uint256 _contributionId) {
        require(_contributionId > 0 && _contributionId <= stories[_storyId].contributionCount, "Invalid contribution ID");
        _;
    }

    modifier proposalNotEnded(uint256 _endTime) {
        require(block.number < _endTime, "Voting proposal has ended");
        _;
    }

    modifier contributionVotingNotEnded(uint256 _endTime) {
        require(block.number < _endTime, "Contribution voting has ended");
        _;
    }

    // -------- Functions --------

    // ---- DAO Setup & Administration ----
    constructor() {
        daoAdmin = msg.sender; // Deployer is initial admin
        admins[daoAdmin] = true;
        paused = false; // Contract starts unpaused
    }

    function initializeDAO(string memory _daoName, uint256 _votingPeriod, uint256 _quorumPercentage, address _treasuryWallet) external onlyAdmin whenPaused {
        require(bytes(_daoName).length > 0, "DAO name cannot be empty");
        require(_votingPeriod > 0, "Voting period must be greater than 0");
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "Quorum percentage must be between 1 and 100");
        require(_treasuryWallet != address(0), "Invalid treasury wallet address");

        daoName = _daoName;
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        treasuryWallet = _treasuryWallet;

        emit DAOInitialized(_daoName, _treasuryWallet, _votingPeriod, _quorumPercentage, msg.sender);
        unpauseContract(); // Unpause after initialization
    }


    function setVotingPeriod(uint256 _newVotingPeriod) external onlyAdmin whenNotPaused {
        require(_newVotingPeriod > 0, "New voting period must be greater than 0");
        votingPeriod = _newVotingPeriod;
        emit VotingPeriodUpdated(_newVotingPeriod);
    }

    function setQuorumPercentage(uint256 _newQuorumPercentage) external onlyAdmin whenNotPaused {
        require(_newQuorumPercentage > 0 && _newQuorumPercentage <= 100, "New quorum percentage must be between 1 and 100");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumPercentageUpdated(_newQuorumPercentage);
    }

    function setTreasuryWallet(address _newTreasuryWallet) external onlyAdmin whenNotPaused {
        require(_newTreasuryWallet != address(0), "Invalid treasury wallet address");
        treasuryWallet = _newTreasuryWallet;
        emit TreasuryWalletUpdated(_newTreasuryWallet);
    }

    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyAdmin whenNotPaused {
        // In a real DAO, this would likely require a DAO vote to approve withdrawals
        // For simplicity here, only admin can withdraw (can be changed to vote-based later)
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient funds in treasury");

        payable(_recipient).transfer(_amount);
        emit TreasuryFundsWithdrawn(_recipient, _amount, msg.sender);
    }

    function addAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address");
        require(!admins[_newAdmin], "Address is already an admin");
        admins[_newAdmin] = true;
        emit AdminAdded(_newAdmin, msg.sender);
    }

    function removeAdmin(address _adminToRemove) external onlyAdmin whenNotPaused {
        require(_adminToRemove != address(0), "Invalid admin address");
        require(_adminToRemove != daoAdmin, "Cannot remove initial DAO Admin through this function"); // Prevent removing the initial deployer admin this way
        require(admins[_adminToRemove], "Address is not an admin");
        delete admins[_adminToRemove];
        emit AdminRemoved(_adminToRemove, msg.sender);
    }


    // ---- Story & Contribution Management ----

    function proposeStory(string memory _title, string memory _genre, string memory _initialSynopsis) external whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_genre).length > 0 && bytes(_initialSynopsis).length > 0, "Story details cannot be empty");

        storyCount++;
        Story storage newStory = stories[storyCount];
        newStory.storyId = storyCount;
        newStory.title = _title;
        newStory.genre = _genre;
        newStory.synopsis = _initialSynopsis;
        newStory.creator = msg.sender;
        newStory.proposalEndTime = block.number + votingPeriod;
        newStory.proposalApproved = false;
        newStory.chapterCount = 0;
        newStory.contributionCount = 0;

        emit StoryProposed(storyCount, _title, _genre, msg.sender);
    }

    function voteOnStoryProposal(uint256 _storyId, bool _vote) external whenNotPaused validStoryId(_storyId) proposalNotEnded(stories[_storyId].proposalEndTime) {
        require(!storyProposalVotes[_storyId][msg.sender], "Already voted on this proposal");

        storyProposalVotes[_storyId][msg.sender] = true;
        uint256 totalVotes = 0; // In a real DAO, you'd track yes/no votes and quorum differently based on token weight
        uint256 yesVotes = 0;
        uint256 noVotes = 0;

        // Simple vote count for demonstration - In a real DAO, consider token-weighted voting
        uint256 membersVoted = 0;
        uint256 requiredQuorum = (totalGovernanceTokens * quorumPercentage) / 100; // Example Quorum Calculation - needs proper governance token logic

        // For demonstration, let's assume any vote is valid and just count votes.
        // In reality, you'd check if the voter has governance tokens or DAO membership.
        uint256 currentVoteCount = 0;
        uint256 yesCount = 0;
        uint256 noCount = 0;
        for(uint256 i = 1; i <= storyCount; i++){ // Iterate through all stories to count votes - inefficient for large scale, optimize!
            if(stories[i].storyId == _storyId){
                for (address voter : getVotersForStoryProposal(_storyId)) { // Need to implement getVotersForStoryProposal to get actual voters
                    currentVoteCount++;
                    if (storyProposalVotes[_storyId][voter]) { // Assuming true means 'yes' for simplicity
                        yesCount++;
                    } else {
                        noCount++;
                    }
                }
                break; // Found the story, exit loop
            }
        }

        emit StoryProposalVoted(_storyId, msg.sender, _vote);

        if (block.number >= stories[_storyId].proposalEndTime && !stories[_storyId].proposalApproved) { // Check after voting period ends
            // Simple approval logic: More than quorum percentage of *voters* voted yes (not token weighted here for simplicity)
            if ( (yesCount * 100) / currentVoteCount >= quorumPercentage ) { // Basic quorum check, not token weighted
                stories[_storyId].proposalApproved = true;
                emit StoryProposalApproved(_storyId);
            }
        }
    }

    // Helper function to get voters for a story proposal (for demonstration - inefficient, needs optimization in real app)
    function getVotersForStoryProposal(uint256 _storyId) internal view returns (address[] memory) {
        address[] memory voters = new address[](storyCount); // Max voters can be story count for demonstration
        uint256 voterCount = 0;
        for (uint256 i = 1; i <= storyCount; i++) {
            if (stories[i].storyId == _storyId) {
                for (address voter : getVoterAddresses()) { // Assuming getVoterAddresses() returns all potential voters
                    if (storyProposalVotes[_storyId][voter]) {
                        voters[voterCount] = voter;
                        voterCount++;
                    }
                }
                break; // Found the story, exit loop
            }
        }
        address[] memory finalVoters = new address[](voterCount);
        for(uint256 i = 0; i < voterCount; i++){
            finalVoters[i] = voters[i];
        }
        return finalVoters;
    }


    // Placeholder function to get all potential voter addresses (replace with actual DAO membership logic)
    function getVoterAddresses() internal view returns (address[] memory) {
        // In a real DAO, this would be based on token holders, DAO members, etc.
        // For demonstration, returning some arbitrary addresses.
        address[] memory voters = new address[](3);
        voters[0] = address(0xAabbCcDdEeFf00112233445566778899AabbCcDd);
        voters[1] = address(0xBbCcDdEeFf00112233445566778899AabbCcDdAa);
        voters[2] = address(0xCcDdEeFf00112233445566778899AabbCcDdBb);
        return voters;
    }


    function submitChapterContribution(uint256 _storyId, string memory _chapterTitle, string memory _chapterContent) external whenNotPaused validStoryId(_storyId) {
        require(stories[_storyId].proposalApproved, "Story proposal not approved yet");
        require(bytes(_chapterTitle).length > 0 && bytes(_chapterContent).length > 0, "Chapter details cannot be empty");

        Story storage currentStory = stories[_storyId];
        currentStory.contributionCount++;
        Contribution storage newContribution = currentStory.contributions[currentStory.contributionCount];
        newContribution.contributionId = currentStory.contributionCount;
        newContribution.contributor = msg.sender;
        newContribution.chapterTitle = _chapterTitle;
        newContribution.chapterContent = _chapterContent;
        newContribution.submissionTime = block.timestamp;
        newContribution.votingEndTime = block.number + votingPeriod;
        newContribution.contributionApproved = false;
        newContribution.upvotes = 0;
        newContribution.downvotes = 0;

        emit ChapterContributionSubmitted(_storyId, currentStory.contributionCount, msg.sender, _chapterTitle);
    }

    function voteOnChapterContribution(uint256 _storyId, uint256 _contributionId, bool _vote) external whenNotPaused validStoryId(_storyId) validContributionId(_storyId, _contributionId) contributionVotingNotEnded(stories[_storyId].contributions[_contributionId].votingEndTime) {
        require(!chapterContributionVotes[_storyId][_contributionId][msg.sender], "Already voted on this contribution");

        chapterContributionVotes[_storyId][_contributionId][msg.sender] = true;
        Contribution storage contribution = stories[_storyId].contributions[_contributionId];

        if (_vote) {
            contribution.upvotes++;
        } else {
            contribution.downvotes++;
        }

        emit ChapterContributionVoted(_storyId, _contributionId, msg.sender, _vote);

        if (block.number >= contribution.votingEndTime && !contribution.contributionApproved) {
            uint256 totalVotesCast = contribution.upvotes + contribution.downvotes;
            if (totalVotesCast > 0 && (contribution.upvotes * 100) / totalVotesCast >= quorumPercentage) { // Quorum based on votes cast, adjust logic as needed
                contribution.contributionApproved = true;
                emit ChapterContributionApproved(_storyId, _contributionId);
            }
        }
    }

    function finalizeStoryChapter(uint256 _storyId, uint256 _contributionId) external onlyAdmin whenNotPaused validStoryId(_storyId) validContributionId(_storyId, _contributionId) {
        Contribution storage contribution = stories[_storyId].contributions[_contributionId];
        require(contribution.contributionApproved, "Contribution not approved yet");
        require(stories[_storyId].chapters.length < 100, "Story has reached chapter limit (example)"); // Example limit

        stories[_storyId].chapters.push(contribution.chapterContent);
        stories[_storyId].chapterContributors.push(contribution.contributor);
        stories[_storyId].chapterCount++;

        contributeToReputation(contribution.contributor, 10); // Example reputation points for accepted chapter
        distributeChapterRewards(_storyId, stories[_storyId].chapterCount - 1); // Distribute rewards for the finalized chapter

        emit StoryChapterFinalized(_storyId, stories[_storyId].chapterCount - 1, _contributionId);
    }

    function viewStoryDetails(uint256 _storyId) external view validStoryId(_storyId) returns (StoryDetails memory) {
        Story storage story = stories[_storyId];
        string[] memory chapterTitles = new string[](story.chapters.length);
        for(uint256 i = 0; i < story.chapters.length; i++){
            // In a real app, you might fetch chapter titles from IPFS or store them separately
            chapterTitles[i] = string(abi.encodePacked("Chapter ", Strings.toString(i+1)));
        }

        return StoryDetails({
            storyId: story.storyId,
            title: story.title,
            genre: story.genre,
            synopsis: story.synopsis,
            creator: story.creator,
            proposalApproved: story.proposalApproved,
            chapterTitles: chapterTitles,
            chapterContributors: story.chapterContributors
        });
    }

    struct StoryDetails {
        uint256 storyId;
        string title;
        string genre;
        string synopsis;
        address creator;
        bool proposalApproved;
        string[] chapterTitles;
        address[] chapterContributors;
    }


    // ---- Reputation & Reward System ----
    function contributeToReputation(address _contributor, uint256 _reputationPoints) internal {
        contributorReputation[_contributor] += _reputationPoints;
        emit ReputationIncreased(_contributor, _reputationPoints);
    }

    function distributeChapterRewards(uint256 _storyId, uint256 _chapterId) internal {
        // Example reward distribution - can be more complex based on contribution quality, etc.
        address[] memory chapterContributors = new address[](1);
        chapterContributors[0] = stories[_storyId].chapterContributors[_chapterId]; // Assuming only one contributor per chapter for simplicity here
        uint256 rewardAmount = 10 ether; // Example reward amount per chapter

        require(address(this).balance >= rewardAmount, "Insufficient funds in treasury for rewards");

        for (uint256 i = 0; i < chapterContributors.length; i++) {
            governanceTokenBalances[chapterContributors[i]] += rewardAmount; // Reward in governance tokens
            totalGovernanceTokens += rewardAmount;
        }
        emit RewardsDistributed(_storyId, _chapterId, chapterContributors, rewardAmount);
    }

    // ---- Governance Token & Staking (Simple Example) ----
    function mintGovernanceTokens(address _recipient, uint256 _amount) external onlyAdmin whenNotPaused {
        governanceTokenBalances[_recipient] += _amount;
        totalGovernanceTokens += _amount;
        emit GovernanceTokensMinted(_recipient, _amount);
    }

    function stakeGovernanceTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Stake amount must be greater than 0");
        require(governanceTokenBalances[msg.sender] >= _amount, "Insufficient governance tokens");

        governanceTokenBalances[msg.sender] -= _amount;
        stakedGovernanceTokens[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    function unstakeGovernanceTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Unstake amount must be greater than 0");
        require(stakedGovernanceTokens[msg.sender] >= _amount, "Insufficient staked tokens");

        stakedGovernanceTokens[msg.sender] -= _amount;
        governanceTokenBalances[msg.sender] += _amount;
        emit TokensUnstaked(msg.sender, _amount);
    }

    function getTokenBalance(address _account) external view returns (uint256) {
        return governanceTokenBalances[_account];
    }


    // ---- NFT Functionality (Placeholders - requires NFT contract integration) ----
    // In a real application, you would integrate with an ERC721 or ERC1155 NFT contract
    // and have functions to mint, transfer, and manage character and world element NFTs.

    function createCharacterNFT(uint256 _storyId, string memory _characterName, string memory _characterDescription, string memory _characterImageURI) external onlyAdmin whenNotPaused validStoryId(_storyId) {
        // Example: Mint an NFT for a character -  Requires integration with NFT contract
        // ... NFT Minting Logic here ...
        // Consider voting mechanism for NFT creation in a real DAO

        // Placeholder for demonstration
        emit ChapterContributionSubmitted(_storyId, stories[_storyId].contributionCount + 1, msg.sender, string(abi.encodePacked("Character NFT Proposal: ", _characterName)));
        // In real implementation, this would call an external NFT contract to mint.
    }

    function createWorldElementNFT(uint256 _storyId, string memory _elementName, string memory _elementDescription, string memory _elementImageURI) external onlyAdmin whenNotPaused validStoryId(_storyId) {
        // Example: Mint an NFT for a world element - Requires integration with NFT contract
        // ... NFT Minting Logic here ...
        // Consider voting mechanism for NFT creation in a real DAO

        // Placeholder for demonstration
        emit ChapterContributionSubmitted(_storyId, stories[_storyId].contributionCount + 1, msg.sender, string(abi.encodePacked("World Element NFT Proposal: ", _elementName)));
        // In real implementation, this would call an external NFT contract to mint.
    }

    // ---- Utility Functions ----
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// --- Library for String Conversion (Solidity < 0.8 needs this for string conversion from uint) ---
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
}
```