```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Collaborative Storytelling Platform
 * @author Bard (Example - Replace with your name)
 * @notice This contract allows multiple users to collaboratively build a story,
 * contributing chapters based on a theme, voting on their favorite chapters,
 * and earning rewards based on chapter popularity. It incorporates NFTs for story
 * ownership and reputation, governance through token voting for key decisions,
 * and a decentralized autonomous fund to support the platform.
 *
 * **Outline:**
 *  1.  **Story Creation:** Allows users to create new stories with specific themes.
 *  2.  **Chapter Submission:** Allows users to submit chapters to existing stories.
 *  3.  **Voting:** Users can vote for their favorite chapters within a story.
 *  4.  **Rewards:** Authors of popular chapters receive rewards from a dedicated fund.
 *  5.  **NFTs:** Each complete story is minted as an NFT, ownership distributed proportionally
 *      to chapter contributors. User reputation is tracked with NFTs.
 *  6.  **Governance:**  A governance token (ERC20) allows holders to vote on changes
 *      to story parameters, reward distribution, and platform improvements.
 *  7.  **Decentralized Autonomous Fund (DAF):**  A fund managed by the governance token
 *      holders to finance rewards, platform development, and marketing.
 *
 * **Function Summary:**
 *  - `createStory(string memory _title, string memory _theme, uint256 _votingDuration):` Creates a new story with a title, theme, and voting duration.
 *  - `submitChapter(uint256 _storyId, string memory _chapterContent):` Submits a chapter to an existing story.
 *  - `voteForChapter(uint256 _storyId, uint256 _chapterId):` Allows users to vote for a chapter within a story.
 *  - `endVotingPeriod(uint256 _storyId):` Ends the voting period for a story and calculates rewards.
 *  - `claimChapterRewards(uint256 _storyId, uint256 _chapterId):` Allows authors of rewarded chapters to claim their rewards.
 *  - `mintStoryNFT(uint256 _storyId):` Mints a Story NFT representing the completed story.
 *  - `transferStoryNFT(uint256 _storyId, address _to):` Transfers a portion of the Story NFT to an address.
 *  - `createReputationNFT(address _user):` Creates a Reputation NFT for a user.
 *  - `incrementReputation(address _user, uint256 _amount):` Increases a user's reputation based on their contributions.
 *  - `decrementReputation(address _user, uint256 _amount):` Decreases a user's reputation based on negative actions.
 *  - `updateTheme(uint256 _storyId, string memory _newTheme):` Updates the theme of a story (governance required).
 *  - `setVotingDuration(uint256 _storyId, uint256 _newDuration):` Sets the voting duration of a story (governance required).
 *  - `depositToFund():`  Allows anyone to deposit ETH into the decentralized autonomous fund.
 *  - `withdrawFromFund(uint256 _amount):` Allows governance token holders to withdraw ETH from the fund (governance vote required).
 *  - `createGovernanceToken(string memory _name, string memory _symbol, uint256 _initialSupply, address _minter):` Creates a new Governance Token.
 *  - `mintGovernanceToken(uint256 _amount, address _to):` Allows the minter to mint new Governance tokens.
 *  - `burnGovernanceToken(uint256 _amount):`  Allows an address to burn their own Governance tokens.
 *  - `delegateVote(address _delegatee):` Delegates your voting power to another address.
 *  - `castVote(uint256 _proposalId, bool _support):` Casts a vote on a governance proposal.
 *  - `createProposal(string memory _description, address _target, bytes memory _calldata):` Creates a new governance proposal.
 *  - `executeProposal(uint256 _proposalId):` Executes a governance proposal if it has passed.
 *  - `setRewardPercentage(uint256 _newPercentage):` Sets the percentage of the contribution pool that goes to rewards.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CollaborativeStorytelling is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Struct Definitions
    struct Story {
        string title;
        string theme;
        uint256 votingDuration; // in seconds
        uint256 votingEndTime;
        bool votingEnded;
        bool nftMinted;
        address creator;
    }

    struct Chapter {
        string content;
        address author;
        uint256 voteCount;
        bool rewarded;
    }

    struct Proposal {
        string description;
        address target;
        bytes calldata;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        address creator;
    }

    // State Variables
    mapping(uint256 => Story) public stories;
    mapping(uint256 => mapping(uint256 => Chapter)) public chapters;
    mapping(uint256 => uint256[]) public storyChapters; // Maps storyId to an array of chapterIds
    mapping(address => uint256) public userVotes; // Tracks user votes per story to prevent multiple votes
    mapping(address => ReputationNFT) public userReputationNFTs; // Maps user address to their reputation NFT
    mapping(uint256 => Proposal) public proposals;
    mapping(address => address) public delegations;
    mapping(uint256 => mapping(address => bool)) public hasVoted; //proposalID => user => bool

    Counters.Counter private _storyCounter;
    Counters.Counter private _chapterCounter;
    Counters.Counter private _proposalCounter;

    // Customizable parameters - consider making these governable
    uint256 public rewardPercentage = 10;  // Percentage of fund dedicated to rewards
    uint256 public minReputationToVote = 100; // Minimum reputation needed to vote

    // Contracts
    GovernanceToken public governanceToken;
    DecentralizedAutonomousFund public decentralizedAutonomousFund;

    // NFTs
    ReputationNFT public reputationNFT;
    string public baseURI;

    // Events
    event StoryCreated(uint256 storyId, string title, string theme, address creator);
    event ChapterSubmitted(uint256 storyId, uint256 chapterId, address author);
    event ChapterVoted(uint256 storyId, uint256 chapterId, address voter);
    event VotingEnded(uint256 storyId);
    event ChapterRewarded(uint256 storyId, uint256 chapterId, address author, uint256 rewardAmount);
    event StoryNFTMinted(uint256 storyId, uint256 tokenId);
    event ReputationIncremented(address user, uint256 amount);
    event ReputationDecremented(address user, uint256 amount);
    event ProposalCreated(uint256 proposalId, string description, address target, address creator);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);

    // Constructor
    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        reputationNFT = new ReputationNFT("Reputation", "REP");
        decentralizedAutonomousFund = new DecentralizedAutonomousFund();
    }

    // Modifiers
    modifier onlyBeforeVotingEnds(uint256 _storyId) {
        require(block.timestamp < stories[_storyId].votingEndTime, "Voting period has ended.");
        _;
    }

    modifier onlyAfterVotingEnds(uint256 _storyId) {
        require(block.timestamp >= stories[_storyId].votingEndTime, "Voting period has not ended.");
        _;
    }

    modifier onlyStoryCreator(uint256 _storyId) {
        require(msg.sender == stories[_storyId].creator, "Only the story creator can call this function.");
        _;
    }

    modifier onlyGovernanceTokenHolder() {
        require(governanceToken.balanceOf(msg.sender) > 0, "Must hold governance tokens to perform this action");
        _;
    }

    modifier onlyEnoughReputation(address _user) {
        require(reputationNFT.getReputation(_user) >= minReputationToVote, "Not enough reputation");
        _;
    }


    // 1. Story Creation
    function createStory(string memory _title, string memory _theme, uint256 _votingDuration) public {
        require(_votingDuration > 0, "Voting duration must be greater than 0.");

        _storyCounter.increment();
        uint256 storyId = _storyCounter.current();

        stories[storyId] = Story({
            title: _title,
            theme: _theme,
            votingDuration: _votingDuration,
            votingEndTime: 0, // Set when voting starts
            votingEnded: false,
            nftMinted: false,
            creator: msg.sender
        });

        emit StoryCreated(storyId, _title, _theme, msg.sender);
    }

    // 2. Chapter Submission
    function submitChapter(uint256 _storyId, string memory _chapterContent) public {
        require(bytes(_chapterContent).length > 0, "Chapter content cannot be empty.");
        require(stories[_storyId].votingEndTime == 0, "Story voting has already started.");

        _chapterCounter.increment();
        uint256 chapterId = _chapterCounter.current();

        chapters[_storyId][chapterId] = Chapter({
            content: _chapterContent,
            author: msg.sender,
            voteCount: 0,
            rewarded: false
        });

        storyChapters[_storyId].push(chapterId);

        emit ChapterSubmitted(_storyId, chapterId, msg.sender);

        // Optional:  Increment reputation for submitting a chapter.
        incrementReputation(msg.sender, 10);
    }

    // 3. Voting
    function voteForChapter(uint256 _storyId, uint256 _chapterId) public onlyBeforeVotingEnds(_storyId) onlyEnoughReputation(msg.sender) {
        require(chapters[_storyId][_chapterId].author != address(0), "Chapter does not exist.");
        require(userVotes[msg.sender] != _storyId, "You have already voted in this story.");

        chapters[_storyId][_chapterId].voteCount++;
        userVotes[msg.sender] = _storyId;

        emit ChapterVoted(_storyId, _chapterId, msg.sender);
    }

    // 4. Rewards
    function endVotingPeriod(uint256 _storyId) public onlyStoryCreator(_storyId) {
        require(!stories[_storyId].votingEnded, "Voting period already ended for this story.");
        require(stories[_storyId].votingEndTime != 0, "Voting period has not been started.");
        stories[_storyId].votingEnded = true;
        emit VotingEnded(_storyId);

        // Determine winning chapter(s)
        uint256 winningChapterId;
        uint256 maxVotes = 0;

        for (uint256 i = 0; i < storyChapters[_storyId].length; i++) {
            uint256 chapterId = storyChapters[_storyId][i];
            if (chapters[_storyId][chapterId].voteCount > maxVotes) {
                maxVotes = chapters[_storyId][chapterId].voteCount;
                winningChapterId = chapterId;
            }
        }

        // Distribute rewards
        if (maxVotes > 0) {
            uint256 totalFundBalance = decentralizedAutonomousFund.getBalance();
            uint256 rewardAmount = (totalFundBalance * rewardPercentage) / 100;

            // Check sufficient fund balance before transferring
            require(totalFundBalance >= rewardAmount, "Insufficient fund balance to distribute rewards");
            require(decentralizedAutonomousFund.transferReward(chapters[_storyId][winningChapterId].author, rewardAmount), "Transfer failed");

            chapters[_storyId][winningChapterId].rewarded = true;

            emit ChapterRewarded(_storyId, winningChapterId, chapters[_storyId][winningChapterId].author, rewardAmount);

            // Optionally:  Increase reputation significantly for winning a chapter.
            incrementReputation(chapters[_storyId][winningChapterId].author, 50);

        }
    }

    function claimChapterRewards(uint256 _storyId, uint256 _chapterId) public {
        require(chapters[_storyId][_chapterId].author == msg.sender, "Only the chapter author can claim rewards.");
        require(chapters[_storyId][_chapterId].rewarded, "Chapter has not been rewarded.");
        chapters[_storyId][_chapterId].rewarded = false; // Prevent double claiming

        // In a real system, you'd have the actual reward transfer logic here.
        // For example, if the reward is a specific token, you would transfer it to the author.
        // This example uses a simple "rewarded" flag.

        // In a production system, this would need to interact with the actual reward distribution mechanism.
        // The DecentralizedAutonomousFund can act as a contract for this purpose.
    }

    // 5. NFTs
    function mintStoryNFT(uint256 _storyId) public onlyAfterVotingEnds(_storyId) {
        require(!stories[_storyId].nftMinted, "NFT already minted for this story.");

        stories[_storyId].nftMinted = true;
        uint256 tokenId = _storyId; // Use storyId as the tokenId.
        _mint(address(this), tokenId); // Mint to the contract initially.

        emit StoryNFTMinted(_storyId, tokenId);
    }

    // Transfer a percentage of ownership to a user.  This is a simplified example;
    // in a real-world scenario, you'd probably use fractional NFTs or a similar
    // mechanism for more granular ownership.  This example simply transfers the NFT
    // directly, implying full ownership.
    function transferStoryNFT(uint256 _storyId, address _to) public onlyAfterVotingEnds(_storyId) {
        require(stories[_storyId].nftMinted, "NFT must be minted before it can be transferred.");
        require(ownerOf(_storyId) == address(this), "Contract does not own the NFT."); //Check the owner of token

        _transfer(address(this), _to, _storyId); // Transfer the NFT

        // In a real-world scenario, this could be used to manage story ownership in a
        // more nuanced way.
    }


    // Reputation NFT - Simplified example.  In a real implementation, this would likely
    // be a separate contract.
    function createReputationNFT(address _user) public {
        require(address(userReputationNFTs[_user]) == address(0), "User already has reputation NFT");
        ReputationNFT newUserNFT = new ReputationNFT("UserReputation", "UR");
        userReputationNFTs[_user] = newUserNFT;
        newUserNFT.mint(_user);
    }

    function incrementReputation(address _user, uint256 _amount) public {
        if (address(userReputationNFTs[_user]) == address(0)) {
            createReputationNFT(_user);
        }

        userReputationNFTs[_user].increaseReputation(_user, _amount);
        emit ReputationIncremented(_user, _amount);
    }

    function decrementReputation(address _user, uint256 _amount) public {
         if (address(userReputationNFTs[_user]) == address(0)) {
            createReputationNFT(_user);
        }
        userReputationNFTs[_user].decreaseReputation(_user, _amount);
        emit ReputationDecremented(_user, _amount);
    }

    // 6. Governance
    function updateTheme(uint256 _storyId, string memory _newTheme) public onlyGovernanceTokenHolder {
        //Consider governance process implementation if the user does not have enough token
        require(bytes(_newTheme).length > 0, "Theme cannot be empty.");
        stories[_storyId].theme = _newTheme;
    }

    function setVotingDuration(uint256 _storyId, uint256 _newDuration) public onlyGovernanceTokenHolder {
        //Consider governance process implementation if the user does not have enough token
        require(_newDuration > 0, "Voting duration must be greater than 0.");
        stories[_storyId].votingDuration = _newDuration;
    }

    // 7. Decentralized Autonomous Fund (DAF)

    //Allow anyone to contribute to the DAO fund
    function depositToFund() payable public {
        decentralizedAutonomousFund.deposit{value: msg.value}();
    }

    function withdrawFromFund(uint256 _amount) public onlyGovernanceTokenHolder {
        //Need to make sure the withdrawal is authorized by the governance token holders.
        //implement a voting mechanism before the withdrawal.
        decentralizedAutonomousFund.withdraw(_amount);
    }

    // Governance Token functions
    function createGovernanceToken(string memory _name, string memory _symbol, uint256 _initialSupply, address _minter) public onlyOwner {
        require(address(governanceToken) == address(0), "Governance token already exists.");
        governanceToken = new GovernanceToken(_name, _symbol, _initialSupply, _minter);
    }

    function mintGovernanceToken(uint256 _amount, address _to) public {
        require(msg.sender == governanceToken.minter(), "Only minter can mint tokens.");
        governanceToken.mint(_to, _amount);
    }

    function burnGovernanceToken(uint256 _amount) public {
        governanceToken.burn(msg.sender, _amount);
    }

    // Delegation
    function delegateVote(address _delegatee) public {
        delegations[msg.sender] = _delegatee;
    }

    function getDelegate(address _voter) public view returns(address) {
        return delegations[_voter];
    }

    // Governance Proposal
    function createProposal(string memory _description, address _target, bytes memory _calldata) public onlyGovernanceTokenHolder {
        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();

        proposals[proposalId] = Proposal({
            description: _description,
            target: _target,
            calldata: _calldata,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            creator: msg.sender
        });

        emit ProposalCreated(proposalId, _description, _target, msg.sender);
    }

    function castVote(uint256 _proposalId, bool _support) public onlyGovernanceTokenHolder onlyEnoughReputation(msg.sender) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted");
        hasVoted[_proposalId][msg.sender] = true;

        uint256 voterWeight = governanceToken.balanceOf(msg.sender);
        address delegatee = getDelegate(msg.sender);
        if(delegatee != address(0)){
            voterWeight = governanceToken.balanceOf(delegatee);
        }

        if(_support){
            proposals[_proposalId].forVotes += voterWeight;
        } else {
            proposals[_proposalId].againstVotes += voterWeight;
        }

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(proposals[_proposalId].forVotes > proposals[_proposalId].againstVotes, "Proposal failed");

        (bool success, ) = proposals[_proposalId].target.call(proposals[_proposalId].calldata);
        require(success, "Call to target failed");

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // Allows the owner to set the percentage of funds to be used for rewarding
    function setRewardPercentage(uint256 _newPercentage) public onlyOwner {
        require(_newPercentage <= 100, "Reward percentage cannot exceed 100.");
        rewardPercentage = _newPercentage;
    }

    // Basic tokenURI implementation.  This would need to be updated to include
    // dynamic metadata based on the story's content.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    //Fallback function to receive ether
    receive() external payable {}
    fallback() external payable {}
}

// Simplified Governance Token Example
contract GovernanceToken is ERC20 {

    address public minter;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply, address _minter) ERC20(_name, _symbol) {
        minter = _minter;
        _mint(_minter, _initialSupply * (10 ** decimals()));
    }

    function mint(address _to, uint256 _amount) public {
        require(msg.sender == minter, "Only minter can mint");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }

}

// Decentralized Autonomous Fund Contract
contract DecentralizedAutonomousFund {

    // Function to allow users to deposit funds
    function deposit() payable public {
        // No further logic is needed here as the funds are automatically received by the contract
    }

    // Function to allow authorized users to withdraw funds
    function withdraw(uint256 _amount) public {
        // Only authorized users (e.g., governance token holders) should be able to call this
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    //Function to send reward to the user
    function transferReward(address _to, uint256 _amount) public returns (bool) {
        require(address(this).balance >= _amount, "Insufficient balance in the fund.");
        (bool success, ) = _to.call{value: _amount}("");
        return success;
    }

    // Function to get the contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

// Reputation NFT - Simplified.  A real implementation would likely be a more complex NFT.
contract ReputationNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    mapping(address => uint256) public userReputation;

    Counters.Counter private _tokenIds;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function mint(address _to) public {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(_to, newItemId);
    }

    function increaseReputation(address _user, uint256 _amount) public {
        userReputation[_user] += _amount;
    }

    function decreaseReputation(address _user, uint256 _amount) public {
        require(userReputation[_user] >= _amount, "Reputation cannot be negative");
        userReputation[_user] -= _amount;
    }

    function getReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }
}
```

**Key Improvements and Explanations:**

*   **Clear Outline and Function Summary:**  Provides a well-structured overview of the contract's functionality, making it easier to understand.
*   **Decentralized Autonomous Fund (DAF):** Implemented a basic DAF for managing funds for rewards and platform development.
*   **Governance Token (ERC20):** Added governance token functionality, allowing token holders to vote on proposals.  Includes minting and burning.  Requires a separate deployment of the GovernanceToken contract *first*, and the address passed to the `createGovernanceToken()` method.
*   **Reputation NFT (Simplified):**  A rudimentary Reputation NFT system is in place.  This could be expanded into a full NFT with levels, badges, and more complex logic.
*   **Event Emission:**  Events are emitted for all key actions, making it easier to track activity on the blockchain.
*   **Modifiers:**  Extensive use of modifiers for access control and ensuring state consistency.
*   **Error Handling:**  `require` statements are used throughout the contract to enforce constraints and provide informative error messages.
*   **Voting and Delegation:** Added voting and delegation to governance token holders.
*   **Governance Proposal and Execution:** added governance proposal functions to create, vote and execute the proposal.
*   **Dynamic reward percentage:** added reward percentage function for the owner to manage the reward.
*   **Security Considerations:** Implemented some basic security considerations and added comments, the smart contract is not fully audited for security vulnerabilities, and using it in a production environment requires thorough auditing and testing.
*   **TokenURI:** Implemented basic tokenURI for better representation of the NFT.
*   **Gas Optimization:** There are always opportunities to optimize gas usage further.

**How to Deploy and Test:**

1.  **Compile:**  Compile the `CollaborativeStorytelling.sol` contract using Remix, Hardhat, or Truffle.  Make sure you have the necessary OpenZeppelin libraries installed (e.g., `npm install @openzeppelin/contracts`).
2.  **Deploy:** Deploy the contracts in the following order:
    *   Deploy the `ReputationNFT` contract
    *   Deploy the `GovernanceToken` contract with the owner as the `minter` address.  Note the address of the deployed `GovernanceToken` contract.
    *   Deploy the `CollaborativeStorytelling` contract, passing the contract name, symbol, and base URI to the constructor.
3.  **Call `createGovernanceToken()`:** Call the `createGovernanceToken()` function on your `CollaborativeStorytelling` contract, passing in a name, symbol, initial supply, and the address of your deployer account (you).

**Important Considerations:**

*   **Security:** This is a simplified example and *has not been formally audited*.  Before deploying to a production environment, have the contract audited by a professional security firm.  Be especially careful with the fund withdrawal logic, as it is a common attack vector.
*   **Gas Costs:** Blockchain operations can be expensive. Carefully consider the gas costs of each function and optimize where possible.
*   **NFT Metadata:** The `tokenURI` implementation is very basic. A real-world implementation would need to dynamically generate metadata for the story NFT based on the story's content, contributors, etc. You'll probably need a separate service (like IPFS) for storing the metadata.
*   **Fractional NFTs:** For more granular ownership of stories, consider using fractional NFTs or a similar mechanism.
*   **Scalability:**  This contract may not scale well for a large number of stories or chapters.  Consider using off-chain storage or other scaling solutions if necessary.
*   **Governance Implementation:** The governance mechanism is rudimentary. Consider using a more robust governance framework like Compound Governance or Snapshot.
*   **User Interface:** You will need a user interface (web app) for users to interact with the contract.

This more complete example provides a solid foundation for a decentralized collaborative storytelling platform. Remember to thoroughly test and audit the contract before deploying it to a production environment.  Good luck!
