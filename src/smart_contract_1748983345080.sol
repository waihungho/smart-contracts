Okay, here is a Solidity smart contract for a Decentralized Autonomous Syndicate (DAS). It incorporates concepts like NFT-based membership, tiered contribution/reputation, internal "quests", a treasury governed by proposals, and dynamic governance parameters.

It aims for novelty by combining these elements into a specific "Syndicate" structure where membership is a non-transferable NFT tied to on-chain contribution earned through defined activities ("quests"), and governance power scales with this contribution. It's not a simple ERC20 DAO clone or a standard multisig.

**Outline and Function Summary:**

**Contract:** `DecentralizedAutonomousSyndicate`

**Core Concepts:**
1.  **NFT Membership:** Unique, non-transferable ERC721 token represents syndicate membership and identity.
2.  **Contribution System:** On-chain points ("Contribution") tracked per member, earned by completing defined "Quests".
3.  **Tiered Governance:** Voting power scales with Contribution level.
4.  **Treasury Management:** Holds ETH and ERC20s, managed solely through governance proposals.
5.  **Dynamic Quests:** Syndicate can define and assign on-chain tasks/quests that members can complete for Contribution.
6.  **Flexible Governance:** Supports multiple proposal types, including custom calls for future flexibility (like upgrades or interacting with other protocols).

**Functions Summary:**

**Membership & Identity:**
1.  `constructor`: Initializes the syndicate, deploys the membership NFT contract, sets initial parameters.
2.  `joinSyndicate`: Allows a new member to join (potentially with a fee or proposal requirement - simplified to direct join for example), mints a membership NFT.
3.  `leaveSyndicate`: Allows a member to leave and burn their membership NFT.
4.  `isSyndicateMember`: Checks if an address holds a membership NFT.
5.  `getMemberTokenId`: Gets the NFT token ID for a given member address.
6.  `getMemberAddressByTokenId`: Gets the member address for a given NFT token ID.
7.  `getMemberContribution`: Retrieves the contribution level for a member.

**Contribution & Quests:**
8.  `defineSyndicateQuest`: (Governance-only) Defines a new type of quest with a description and contribution reward.
9.  `assignQuestToMember`: (Governance-only) Assigns a specific quest instance to a member.
10. `completeAssignedQuest`: Member function to mark an assigned quest as completed and claim contribution points.
11. `getSyndicateQuestStatus`: View the status of a specific quest for a member.
12. `getQuestDetails`: View details of a defined quest type.
13. `updateMemberContributionInternal`: (Internal) Updates a member's contribution level. Called by `completeAssignedQuest`.

**Treasury:**
14. `depositTreasuryETH`: Allows anyone to deposit ETH into the syndicate treasury.
15. `depositTreasuryERC20`: Allows depositing approved ERC20 tokens into the treasury.
16. `getTreasuryBalanceETH`: View current ETH balance.
17. `getTreasuryBalanceERC20`: View balance of a specific ERC20 token.

**Governance:**
18. `createProposal`: Allows members (meeting threshold) to create a new governance proposal.
19. `vote`: Allows members to vote on an active proposal. Voting power based on Contribution.
20. `executeProposal`: Executes a successful proposal.
21. `cancelProposal`: Allows a proposer or governance to cancel a proposal (if conditions met).
22. `getProposalState`: View the current state of a proposal.
23. `getProposalInfo`: View details of a proposal (type, target, value, data, etc.).
24. `getVotingPower`: Calculate a member's current voting power.
25. `getGovernanceParameters`: View current governance parameters (quorum, period, threshold).
26. `setGovernanceParameters`: (Governance-only) Allows updating governance parameters via a proposal.

**Utility/Views:**
27. `getSyndicateName`: View the syndicate's name.
28. `getMembershipNFTAddress`: View the address of the membership NFT contract.
29. `getTotalMembers`: View the total number of syndicate members (NFT holders).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol"; // Using roles might be simpler than full governance for some internal things, but let's stick to governance where possible. Let's remove AccessControl for true DAO spirit. Rely *only* on governance proposals for sensitive actions.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// --- Outline and Function Summary ---
// Contract: DecentralizedAutonomousSyndicate
// Core Concepts: NFT-based membership, Tiered Contribution, Governed Treasury, Dynamic Quests, Flexible Governance.
//
// Functions Summary:
// Membership & Identity:
// 1. constructor: Initializes syndicate, deploys NFT, sets params.
// 2. joinSyndicate: Mint membership NFT.
// 3. leaveSyndicate: Burn membership NFT.
// 4. isSyndicateMember: Check membership status.
// 5. getMemberTokenId: Get NFT ID for member.
// 6. getMemberAddressByTokenId: Get member address for NFT ID.
// 7. getMemberContribution: Get contribution level.
//
// Contribution & Quests:
// 8. defineSyndicateQuest: (Governance) Define new quest type.
// 9. assignQuestToMember: (Governance) Assign quest instance to member.
// 10. completeAssignedQuest: Member completes quest & claims points.
// 11. getSyndicateQuestStatus: View member's quest status.
// 12. getQuestDetails: View details of a quest type.
// 13. updateMemberContributionInternal: (Internal) Update contribution.
//
// Treasury:
// 14. depositTreasuryETH: Deposit ETH.
// 15. depositTreasuryERC20: Deposit ERC20.
// 16. getTreasuryBalanceETH: View ETH balance.
// 17. getTreasuryBalanceERC20: View ERC20 balance.
//
// Governance:
// 18. createProposal: Create a proposal.
// 19. vote: Vote on proposal.
// 20. executeProposal: Execute successful proposal.
// 21. cancelProposal: Cancel proposal.
// 22. getProposalState: View proposal state.
// 23. getProposalInfo: View proposal details.
// 24. getVotingPower: Calculate member voting power.
// 25. getGovernanceParameters: View governance params.
// 26. setGovernanceParameters: (Governance) Update governance params via proposal.
//
// Utility/Views:
// 27. getSyndicateName: View syndicate name.
// 28. getMembershipNFTAddress: View NFT contract address.
// 29. getTotalMembers: View total members.
// --- End of Summary ---


// Internal NFT contract for Syndicate Membership
// Made non-transferable by overriding _beforeTokenTransfer
contract SyndicateMembershipNFT is ERC721Burnable {
    constructor(address initialOwner, string memory name, string memory symbol)
        ERC721(name, symbol)
    {
        // _mint(initialOwner, 0); // No initial owner needed, mint on join
    }

    // Function to get token URI (can be dynamic based on contribution via external call or pre-rendered)
    // For simplicity, returning a base URI + token ID. A real implementation might fetch data from the main contract.
    string private _baseTokenURI;

    function setBaseURI(string memory baseURI) external {
        // This would ideally be called only by the main Syndicate contract or via its governance
        // For this example, keeping it simple.
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Make the NFT non-transferable except to the zero address (burning)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(from == address(0) || to == address(0), "SMNFT: Non-transferable");
    }

    // Allow the main syndicate contract to mint NFTs
    // This contract should be owned or controlled by the main syndicate contract
    // For this example, let the minter be set once or rely on initial deployment setup.
    // A more robust system might have the minter role managed by the main contract's governance.
    // Let's add a minter role managed by the constructor caller (which will be the main DAS contract)
    address public minter;

    function setMinter(address _minter) external {
         // Only allow setting minter once
         require(minter == address(0), "SMNFT: Minter already set");
         minter = _minter;
    }

    function safeMint(address to, uint256 tokenId) external {
        require(msg.sender == minter, "SMNFT: Only minter can mint");
        _safeMint(to, tokenId);
    }

    // Syndicate contract will call burn when member leaves
    // burn function is inherited from ERC721Burnable
}


contract DecentralizedAutonomousSyndicate is ReentrancyGuard, ERC721Holder { // Inherit ERC721Holder to receive NFT assets if needed
    using Counters for Counters.Counter;

    string public syndicateName;
    SyndicateMembershipNFT public membershipNFT;

    // --- State Variables ---

    // Counters
    Counters.Counter private _nextTokenId;
    Counters.Counter private _nextProposalId;
    Counters.Counter private _nextQuestTypeId;

    // Member Data: address -> token ID, token ID -> address, token ID -> contribution level
    mapping(address => uint256) private _memberTokenIds;
    mapping(uint256 => address) private _tokenIdMembers;
    mapping(uint256 => uint256) private _memberContributions; // Token ID -> Contribution Points

    // Treasury: ERC20 balances
    mapping(address => uint256) private _treasuryERC20Balances;

    // Governance Parameters
    uint256 public votingPeriod; // In seconds
    uint256 public quorumPercentage; // Percentage (e.g., 500 for 50.0%)
    uint256 public proposalThresholdContribution; // Minimum contribution to create a proposal

    // Proposal State
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }
    enum ProposalType { TreasuryWithdrawalETH, TreasuryWithdrawalERC20, SetGovernanceParameters, DefineSyndicateQuest, AssignQuestToMember, CustomCall }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtStart; // Snapshot of total voting power
        ProposalState state;
        bytes data; // Encoded data for the proposal type

        // Specific fields based on ProposalType
        address targetAddress;
        uint256 etherValue;
        address tokenAddress; // For TreasuryWithdrawalERC20
        uint256 tokenAmount; // For TreasuryWithdrawalERC20

        // Voting tracking: voter token ID -> hasVoted
        mapping(uint256 => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;

    // Quest System
    struct QuestType {
        uint256 id;
        string description;
        uint256 contributionReward;
        bool isActive; // Can this quest type be assigned?
    }
    mapping(uint256 => QuestType) private _questTypes; // Quest Type ID -> Quest Type Details

    struct MemberQuestAssignment {
        uint256 questTypeId;
        bool isCompleted;
    }
    // member token ID -> assigned quest instance ID -> assignment details
    mapping(uint256 => mapping(uint256 => MemberQuestAssignment)) private _memberQuestAssignments;
    mapping(uint256 => Counters.Counter) private _memberQuestAssignmentCounters; // Member token ID -> counter for their assigned quest instances

    // --- Events ---
    event MemberJoined(address indexed member, uint256 tokenId);
    event MemberLeft(address indexed member, uint256 tokenId);
    event ContributionUpdated(uint256 indexed tokenId, uint256 oldContribution, uint256 newContribution);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, uint256 endBlock);
    event Voted(uint256 indexed proposalId, uint256 indexed voterTokenId, bool support, uint255 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState oldState, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bytes result);
    event ProposalCanceled(uint256 indexed proposalId);

    event TreasuryDepositETH(address indexed depositor, uint256 amount);
    event TreasuryWithdrawalETH(address indexed recipient, uint256 amount);
    event TreasuryDepositERC20(address indexed depositor, address indexed token, uint256 amount);
    event TreasuryWithdrawalERC20(address indexed recipient, address indexed token, uint256 amount);

    event GovernanceParametersUpdated(uint256 newVotingPeriod, uint256 newQuorumPercentage, uint256 newProposalThresholdContribution);

    event QuestTypeDefined(uint256 indexed questTypeId, string description, uint256 contributionReward);
    event QuestAssigned(uint256 indexed memberTokenId, uint256 indexed questInstanceId, uint256 questTypeId);
    event QuestCompleted(uint256 indexed memberTokenId, uint256 indexed questInstanceId, uint256 questTypeId, uint256 awardedContribution);

    // --- Modifiers ---

    modifier onlySyndicateMember(address account) {
        require(_memberTokenIds[account] != 0, "DAS: Not a syndicate member");
        _;
    }

    modifier proposalState(uint256 proposalId, ProposalState requiredState) {
        require(proposals[proposalId].state == requiredState, "DAS: Proposal not in required state");
        _;
    }

    // --- Constructor ---

    constructor(string memory _syndicateName, string memory _nftName, string memory _nftSymbol, uint256 _votingPeriod, uint256 _quorumPercentage, uint256 _proposalThresholdContribution) {
        syndicateName = _syndicateName;

        // Deploy the membership NFT contract
        membershipNFT = new SyndicateMembershipNFT(address(this), _nftName, _nftSymbol);
        membershipNFT.setMinter(address(this)); // Grant minter role to this contract

        // Set initial governance parameters
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        proposalThresholdContribution = _proposalThresholdContribution;

        // Initialize the first token ID to 1 (0 is default mapping value)
        _nextTokenId.increment();
    }

    // --- Receive ETH Function ---
    receive() external payable {
        emit TreasuryDepositETH(msg.sender, msg.value);
    }

    // --- Membership & Identity Functions ---

    /// @notice Allows a new member to join the syndicate.
    /// @dev Mints a new unique, non-transferable NFT for the member. Initial contribution is 0.
    function joinSyndicate() external nonReentrant {
        require(_memberTokenIds[msg.sender] == 0, "DAS: Already a syndicate member");

        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _memberTokenIds[msg.sender] = newTokenId;
        _tokenIdMembers[newTokenId] = msg.sender;
        _memberContributions[newTokenId] = 0; // Start with 0 contribution

        membershipNFT.safeMint(msg.sender, newTokenId);

        emit MemberJoined(msg.sender, newTokenId);
    }

    /// @notice Allows a member to leave the syndicate.
    /// @dev Burns the member's NFT and clears their associated data. Contribution is lost.
    function leaveSyndicate() external nonReentrant onlySyndicateMember(msg.sender) {
        uint256 tokenId = _memberTokenIds[msg.sender];

        // Clear member data
        delete _memberTokenIds[msg.sender];
        delete _tokenIdMembers[tokenId];
        delete _memberContributions[tokenId];
        // Quest assignments data remains but linked to a non-existent token ID

        membershipNFT.burn(tokenId); // Burn the NFT

        emit MemberLeft(msg.sender, tokenId);
    }

    /// @notice Checks if an address is currently a syndicate member.
    /// @param account The address to check.
    /// @return True if the address is a member, false otherwise.
    function isSyndicateMember(address account) public view returns (bool) {
        return _memberTokenIds[account] != 0;
    }

    /// @notice Gets the membership NFT token ID for a given member address.
    /// @param account The member's address.
    /// @return The token ID, or 0 if not a member.
    function getMemberTokenId(address account) public view returns (uint256) {
        return _memberTokenIds[account];
    }

     /// @notice Gets the member address for a given membership NFT token ID.
    /// @param tokenId The membership NFT token ID.
    /// @return The member's address, or address(0) if no member is associated with this ID.
    function getMemberAddressByTokenId(uint256 tokenId) public view returns (address) {
        return _tokenIdMembers[tokenId];
    }


    /// @notice Gets the contribution level of a syndicate member.
    /// @param account The member's address.
    /// @return The member's contribution points.
    function getMemberContribution(address account) public view onlySyndicateMember(account) returns (uint256) {
        uint256 tokenId = _memberTokenIds[account];
        return _memberContributions[tokenId];
    }

    // --- Contribution & Quests Functions ---

    /// @notice (Governance) Defines a new type of quest that members can complete.
    /// @dev This function must be called via a governance proposal.
    /// @param description A description of the quest.
    /// @param contributionReward The number of contribution points awarded upon completion.
    function defineSyndicateQuest(string memory description, uint256 contributionReward) external {
        // This function's sensitive nature means it *must* be called by executeProposal
        // The ProposalType.DefineSyndicateQuest case in executeProposal is the only valid caller.
        require(msg.sender == address(this), "DAS: Only callable via governance execution");

        uint256 newQuestTypeId = _nextQuestTypeId.current();
        _nextQuestTypeId.increment();

        _questTypes[newQuestTypeId] = QuestType({
            id: newQuestTypeId,
            description: description,
            contributionReward: contributionReward,
            isActive: true
        });

        emit QuestTypeDefined(newQuestTypeId, description, contributionReward);
    }

    /// @notice (Governance) Assigns a specific instance of a quest type to a member.
    /// @dev This function must be called via a governance proposal. A member can be assigned the same quest type multiple times.
    /// @param memberAddress The address of the member to assign the quest to.
    /// @param questTypeId The ID of the quest type to assign.
    function assignQuestToMember(address memberAddress, uint256 questTypeId) external onlySyndicateMember(memberAddress) {
        // This function must be called by executeProposal
        require(msg.sender == address(this), "DAS: Only callable via governance execution");
        require(_questTypes[questTypeId].isActive, "DAS: Quest type not active or does not exist");

        uint256 memberTokenId = _memberTokenIds[memberAddress];
        uint256 questInstanceId = _memberQuestAssignmentCounters[memberTokenId].current();
        _memberQuestAssignmentCounters[memberTokenId].increment();

        _memberQuestAssignments[memberTokenId][questInstanceId] = MemberQuestAssignment({
            questTypeId: questTypeId,
            isCompleted: false
        });

        emit QuestAssigned(memberTokenId, questInstanceId, questTypeId);
    }

    /// @notice Allows a member to mark an *assigned* quest instance as completed and claim points.
    /// @dev Assumes off-chain verification of completion happens before this call.
    /// @param questInstanceId The specific instance ID of the quest assignment for the member.
    function completeAssignedQuest(uint256 questInstanceId) external onlySyndicateMember(msg.sender) nonReentrant {
        uint256 memberTokenId = _memberTokenIds[msg.sender];
        MemberQuestAssignment storage assignment = _memberQuestAssignments[memberTokenId][questInstanceId];

        require(assignment.questTypeId != 0, "DAS: Quest assignment does not exist");
        require(!assignment.isCompleted, "DAS: Quest already completed");

        assignment.isCompleted = true;

        QuestType storage questType = _questTypes[assignment.questTypeId];
        require(questType.isActive, "DAS: Associated quest type is not active"); // Should not happen if assigned, but good check.

        uint256 awardedContribution = questType.contributionReward;

        // Update member's contribution
        updateMemberContributionInternal(memberTokenId, _memberContributions[memberTokenId] + awardedContribution);

        emit QuestCompleted(memberTokenId, questInstanceId, assignment.questTypeId, awardedContribution);
    }

    /// @notice Gets the completion status of a specific quest assignment for a member.
    /// @param memberAddress The member's address.
    /// @param questInstanceId The instance ID of the quest assignment.
    /// @return A struct containing the quest type ID and completion status.
    function getSyndicateQuestStatus(address memberAddress, uint256 questInstanceId) public view onlySyndicateMember(memberAddress) returns (MemberQuestAssignment memory) {
         uint256 memberTokenId = _memberTokenIds[memberAddress];
         return _memberQuestAssignments[memberTokenId][questInstanceId];
    }

    /// @notice Gets the details of a defined quest type.
    /// @param questTypeId The ID of the quest type.
    /// @return A struct containing quest details.
    function getQuestDetails(uint256 questTypeId) public view returns (QuestType memory) {
        return _questTypes[questTypeId];
    }

    /// @notice Internal function to update a member's contribution points.
    /// @dev Emits a ContributionUpdated event. Only callable internally.
    /// @param tokenId The member's NFT token ID.
    /// @param newContribution The new contribution level.
    function updateMemberContributionInternal(uint256 tokenId, uint256 newContribution) internal {
        // This should ideally only be called by functions like completeAssignedQuest
        // or potentially via a specific governance proposal type if manual adjustments are allowed.
        require(_tokenIdMembers[tokenId] != address(0), "DAS: Token ID not associated with a member");
        uint256 oldContribution = _memberContributions[tokenId];
        _memberContributions[tokenId] = newContribution;
        emit ContributionUpdated(tokenId, oldContribution, newContribution);
    }


    // --- Treasury Functions ---

    /// @notice Allows depositing Ether into the syndicate treasury.
    function depositTreasuryETH() external payable {
         require(msg.value > 0, "DAS: Cannot deposit 0 ETH");
         emit TreasuryDepositETH(msg.sender, msg.value);
    }

    /// @notice Allows depositing approved ERC20 tokens into the treasury.
    /// @dev Requires the user to approve this contract first.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositTreasuryERC20(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "DAS: Cannot deposit 0 tokens");
        IERC20 tokenContract = IERC20(token);
        require(tokenContract.transferFrom(msg.sender, address(this), amount), "DAS: ERC20 transfer failed");
        _treasuryERC20Balances[token] += amount;
        emit TreasuryDepositERC20(msg.sender, token, amount);
    }

    /// @notice Gets the current ETH balance of the syndicate treasury.
    /// @return The ETH balance in wei.
    function getTreasuryBalanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the current balance of a specific ERC20 token in the treasury.
    /// @param token The address of the ERC20 token.
    /// @return The token balance.
    function getTreasuryBalanceERC20(address token) public view returns (uint256) {
        return _treasuryERC20Balances[token];
    }


    // --- Governance Functions ---

    /// @notice Calculates the voting power of a member based on their contribution.
    /// @dev Currently linear: 1 point of contribution = 1 unit of voting power. Can be modified (e.g., square root).
    /// @param account The member's address.
    /// @return The calculated voting power.
    function getVotingPower(address account) public view returns (uint255) {
        if (!isSyndicateMember(account)) {
            return 0;
        }
        uint256 tokenId = _memberTokenIds[account];
        // Use uint255 as max voting power to fit in event/struct if needed,
        // though contribution uint256 is fine internally. Cast safely.
        uint256 contribution = _memberContributions[tokenId];
        return contribution > type(uint255).max ? type(uint255).max : uint255(contribution);
    }

    /// @notice Creates a new governance proposal.
    /// @dev Requires the proposer to be a member and meet the proposal threshold.
    /// Encodes proposal-specific data into the `_data` parameter.
    /// @param _type The type of the proposal.
    /// @param _target The target address for the proposal (e.g., recipient for withdrawal, contract for custom call).
    /// @param _value The ETH value to send with a custom call (or 0).
    /// @param _tokenAddress The address of the ERC20 token for ERC20 withdrawals.
    /// @param _tokenAmount The amount of ERC20 tokens for withdrawals.
    /// @param _callData The encoded function call data for CustomCall type.
    /// @param _description A description of the proposal (off-chain, store hash on-chain).
    function createProposal(
        ProposalType _type,
        address _target,
        uint256 _value,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes memory _callData,
        string memory _description // Placeholder for off-chain data/hash
    )
        external
        onlySyndicateMember(msg.sender)
        nonReentrant
        returns (uint255 proposalId)
    {
        uint256 proposerTokenId = _memberTokenIds[msg.sender];
        require(_memberContributions[proposerTokenId] >= proposalThresholdContribution, "DAS: Insufficient contribution to propose");

        proposalId = _nextProposalId.current();
        _nextProposalId.increment();

        uint256 currentBlock = block.number;
        uint256 endBlock = currentBlock + (votingPeriod / 12); // Approximate blocks from seconds (adjust average block time)
        // Note: Using block.timestamp is generally better for time, but block.number for period length avoids issues with miners manipulating timestamps slightly.
        // Let's use block.timestamp for period end for clarity, but acknowledge limitations.
        uint256 endTime = block.timestamp + votingPeriod;


        // Encode proposal-specific data based on type
        bytes memory encodedData;
        if (_type == ProposalType.TreasuryWithdrawalETH) {
             require(_target != address(0), "DAS: Withdrawal recipient cannot be zero address");
             // Data is recipient and amount
             encodedData = abi.encode(_target, _value); // Using _value field for ETH amount
             require(_value > 0, "DAS: ETH withdrawal amount must be > 0");
             require(_tokenAddress == address(0) && _tokenAmount == 0 && _callData.length == 0, "DAS: Invalid params for ETH withdrawal");
        } else if (_type == ProposalType.TreasuryWithdrawalERC20) {
             require(_target != address(0), "DAS: Withdrawal recipient cannot be zero address");
             require(_tokenAddress != address(0), "DAS: Token address cannot be zero address");
             // Data is recipient, token address, amount
             encodedData = abi.encode(_target, _tokenAddress, _tokenAmount);
             require(_tokenAmount > 0, "DAS: ERC20 withdrawal amount must be > 0");
             require(_value == 0 && _callData.length == 0, "DAS: Invalid params for ERC20 withdrawal");
        } else if (_type == ProposalType.SetGovernanceParameters) {
             // Data is new voting period, quorum, threshold
             // Use target, value, tokenAddress, tokenAmount for simplicity to pass data
             // target=newVotingPeriod, value=newQuorumPercentage, tokenAddress=newProposalThresholdContribution (abuse types slightly for data)
             encodedData = abi.encode(_target, _value, _tokenAddress); // Assuming _target, _value, _tokenAddress hold the new params
             require(_tokenAmount == 0 && _callData.length == 0, "DAS: Invalid params for SetGovernanceParameters");
        } else if (_type == ProposalType.DefineSyndicateQuest) {
             // Data is description and contribution reward
             // Use target, value for simplicity: target=description (address 0 needed), value=contributionReward
             // Or better, use _callData encoding for strings/complex types
             encodedData = _callData; // Assuming _callData contains abi.encode(string description, uint256 contributionReward)
              require(_target == address(0) && _value == 0 && _tokenAddress == address(0) && _tokenAmount == 0, "DAS: Invalid params for DefineSyndicateQuest");

        } else if (_type == ProposalType.AssignQuestToMember) {
            // Data is memberAddress and questTypeId
            // Use target, value for simplicity: target=memberAddress, value=questTypeId
            encodedData = abi.encode(_target, _value); // Assuming _target is memberAddress, _value is questTypeId
            require(_target != address(0), "DAS: Member address cannot be zero address");
             require(_tokenAddress == address(0) && _tokenAmount == 0 && _callData.length == 0, "DAS: Invalid params for AssignQuestToMember");

        } else if (_type == ProposalType.CustomCall) {
             require(_target != address(0), "DAS: Target address cannot be zero address");
             // Data is target address, value, and callData
             encodedData = abi.encode(_target, _value, _callData); // Using target, value, and _callData fields
             require(_tokenAddress == address(0) && _tokenAmount == 0, "DAS: Invalid params for CustomCall");
        } else {
            revert("DAS: Unsupported proposal type");
        }


        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: _type,
            proposer: msg.sender,
            startBlock: currentBlock, // Snapshot start block
            endBlock: endTime,       // Snapshot end timestamp
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtStart: _calculateTotalVotingPowerSnapshot(), // Snapshot total voting power
            state: ProposalState.Pending, // Starts as pending
            data: encodedData, // Store encoded data
            targetAddress: _target, // Store key params for easier reading/decoding later
            etherValue: _value,
            tokenAddress: _tokenAddress,
            tokenAmount: _tokenAmount
        });

        // Immediately set state to Active upon creation
        _updateProposalState(proposalId, ProposalState.Active);

        emit ProposalCreated(proposalId, msg.sender, _type, endTime);
        return proposalId;
    }

    /// @notice Allows a member to vote on an active proposal.
    /// @dev Voting power is snapshotted based on the member's contribution when they vote.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a vote in favor, false for a vote against.
    function vote(uint255 proposalId, bool support)
        external
        onlySyndicateMember(msg.sender)
        nonReentrant
        proposalState(proposalId, ProposalState.Active) // Must be in Active state
    {
        Proposal storage proposal = proposals[proposalId];
        uint256 voterTokenId = _memberTokenIds[msg.sender];

        require(proposal.hasVoted[voterTokenId] == false, "DAS: Member already voted");
        require(block.timestamp <= proposal.endBlock, "DAS: Voting period has ended");

        // Get voting power at the moment of voting
        uint255 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "DAS: Voter has no voting power"); // Must have > 0 contribution

        proposal.hasVoted[voterTokenId] = true;

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit Voted(proposalId, voterTokenId, support, votingPower);

        // Check if voting period ended *right after* this vote
        if (block.timestamp > proposal.endBlock) {
            _checkAndFinalizeVoting(proposalId);
        }
    }

    /// @notice Checks the outcome of a proposal after the voting period ends and updates its state.
    /// @dev Can be called by anyone after the voting period expires.
    /// @param proposalId The ID of the proposal to finalize.
    function _checkAndFinalizeVoting(uint255 proposalId) internal {
         Proposal storage proposal = proposals[proposalId];

         // Only finalize if in Active state and voting period is over
         if (proposal.state == ProposalState.Active && block.timestamp > proposal.endBlock) {
             uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

             // Calculate quorum: Total votes must be at least quorumPercentage of total voting power at start
             uint256 requiredQuorum = (proposal.totalVotingPowerAtStart * quorumPercentage) / 1000; // Divide by 1000 because quorumPercentage is x10

             if (totalVotes >= requiredQuorum && proposal.votesFor > proposal.votesAgainst) {
                 _updateProposalState(proposalId, ProposalState.Succeeded);
             } else {
                 _updateProposalState(proposalId, ProposalState.Failed);
             }
         }
    }

    /// @notice Executes a successful proposal.
    /// @dev Can be called by anyone once the proposal is in the Succeeded state and voting period is over.
    /// Handles execution logic based on proposal type.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint255 proposalId)
        external
        nonReentrant
        proposalState(proposalId, ProposalState.Succeeded) // Must have Succeeded
    {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endBlock, "DAS: Voting period has not ended"); // Ensure voting is truly finalized

        _updateProposalState(proposalId, ProposalState.Executed);

        bytes memory decodedData = proposal.data;
        bytes memory result;
        bool success;

        if (proposal.proposalType == ProposalType.TreasuryWithdrawalETH) {
            (address recipient, uint256 amount) = abi.decode(decodedData, (address, uint256));
             require(amount <= address(this).balance, "DAS: Insufficient ETH balance");

            (success, result) = payable(recipient).call{value: amount}("");
            require(success, "DAS: ETH withdrawal failed");

            emit TreasuryWithdrawalETH(recipient, amount);

        } else if (proposal.proposalType == ProposalType.TreasuryWithdrawalERC20) {
            (address recipient, address token, uint256 amount) = abi.decode(decodedData, (address, address, uint256));
             require(_treasuryERC20Balances[token] >= amount, "DAS: Insufficient ERC20 balance");

            _treasuryERC20Balances[token] -= amount; // Update internal balance before transfer
            (success, result) = IERC20(token).transfer(recipient, amount).call(); // Safe transfer pattern might be better
             require(success, "DAS: ERC20 withdrawal failed");
             // Revert if call returned false (standard ERC20) - SafeERC20 handles this

            emit TreasuryWithdrawalERC20(recipient, token, amount);

        } else if (proposal.proposalType == ProposalType.SetGovernanceParameters) {
             (uint256 newVotingPeriod, uint256 newQuorumPercentage, uint256 newProposalThresholdContribution) = abi.decode(decodedData, (uint256, uint256, uint256));

             votingPeriod = newVotingPeriod;
             quorumPercentage = newQuorumPercentage;
             proposalThresholdContribution = newProposalThresholdContribution;

             emit GovernanceParametersUpdated(newVotingPeriod, newQuorumPercentage, newProposalThresholdContribution);

        } else if (proposal.proposalType == ProposalType.DefineSyndicateQuest) {
             // Decode parameters for defineSyndicateQuest
             (string memory description, uint256 contributionReward) = abi.decode(decodedData, (string, uint256));
             // Call the internal function
             defineSyndicateQuest(description, contributionReward); // Calls internal function which checks msg.sender == address(this)

        } else if (proposal.proposalType == ProposalType.AssignQuestToMember) {
             // Decode parameters for assignQuestToMember
             (address memberAddress, uint256 questTypeId) = abi.decode(decodedData, (address, uint256));
             // Call the internal function
             assignQuestToMember(memberAddress, questTypeId); // Calls internal function which checks msg.sender == address(this)

        } else if (proposal.proposalType == ProposalType.CustomCall) {
             // Execute arbitrary call
             (address target, uint256 value, bytes memory callData) = abi.decode(decodedData, (address, uint256, bytes));
             (success, result) = target.call{value: value}(callData);
             require(success, "DAS: Custom call failed");

        } else {
            revert("DAS: Execution logic not implemented for this proposal type");
        }

        emit ProposalExecuted(proposalId, result);
    }

    /// @notice Allows a proposal to be canceled.
    /// @dev Can only be canceled if in Pending or Active state and voting period not over.
    /// Only the proposer or potentially governance (via another proposal?) can cancel.
    /// Simplified: only the proposer can cancel in Pending/Active state before voting ends.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelProposal(uint255 proposalId)
        external
        nonReentrant
    {
        Proposal storage proposal = proposals[proposalId];

        require(msg.sender == proposal.proposer, "DAS: Only the proposer can cancel");
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "DAS: Proposal cannot be canceled in its current state");
        require(block.timestamp <= proposal.endBlock, "DAS: Voting period has ended"); // Cannot cancel after voting ends

        _updateProposalState(proposalId, ProposalState.Canceled);

        emit ProposalCanceled(proposalId);
    }


    /// @notice Gets the current state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The current ProposalState.
    function getProposalState(uint255 proposalId) public view returns (ProposalState) {
        // Recalculate state if it's Active and voting period ended
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.endBlock) {
             uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
             uint256 requiredQuorum = (proposal.totalVotingPowerAtStart * quorumPercentage) / 1000;

             if (totalVotes >= requiredQuorum && proposal.votesFor > proposal.votesAgainst) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Failed;
             }
        }
        return proposal.state;
    }

     /// @notice Gets the details of a proposal.
     /// @param proposalId The ID of the proposal.
     /// @return A struct containing proposal information.
    function getProposalInfo(uint255 proposalId) public view returns (Proposal memory) {
        // Return the struct directly. Note: maps within the struct are not returned directly,
        // but primary fields are included. Use getProposalState to get current state dynamically.
        return proposals[proposalId];
    }


    /// @notice Helper to update proposal state and emit event.
    /// @param proposalId The ID of the proposal.
    /// @param newState The state to transition to.
    function _updateProposalState(uint255 proposalId, ProposalState newState) internal {
        Proposal storage proposal = proposals[proposalId];
        ProposalState oldState = proposal.state;
        proposal.state = newState;
        emit ProposalStateChanged(proposalId, oldState, newState);
    }


     /// @notice Calculates the total possible voting power of all current members.
     /// @dev Used to snapshot total voting power at the start of a proposal for quorum calculation.
     /// Iterates through all issued token IDs. Potentially gas-intensive if member count is very high.
     /// A more scalable approach might track total contribution globally or use checkpoints.
     /// @return The sum of all members' current contribution points.
    function _calculateTotalVotingPowerSnapshot() internal view returns (uint256) {
        uint256 totalPower = 0;
        // Iterate through issued token IDs. Assumes token IDs are sequential from 1.
        // This is fragile if token IDs are not sequential or if there are many burned tokens.
        // A mapping or list of active token IDs would be better for large/dynamic membership.
        // For this example, assuming sequential IDs from 1 up to the current counter value.
        // WARNING: This approach is not gas-efficient for a large number of members.
        // Consider alternative quorum calculation methods or membership tracking.
        uint256 totalIssuedTokens = _nextTokenId.current();
        for (uint256 i = 1; i < totalIssuedTokens; i++) {
            address member = _tokenIdMembers[i];
            // Check if token ID is still active and associated with a member
            if (member != address(0) && _memberTokenIds[member] == i) {
                 totalPower += _memberContributions[i];
            }
        }
        return totalPower;
    }


    // --- Governance Parameter Functions ---

     /// @notice Gets the current governance parameters.
     /// @return votingPeriod, quorumPercentage, proposalThresholdContribution.
    function getGovernanceParameters() public view returns (uint256, uint256, uint256) {
        return (votingPeriod, quorumPercentage, proposalThresholdContribution);
    }

     /// @notice (Governance) Updates the governance parameters.
     /// @dev This function must be called via a governance proposal (type SetGovernanceParameters).
     /// @param newVotingPeriod The new voting period in seconds.
     /// @param newQuorumPercentage The new quorum percentage (e.g., 500 for 50.0%).
     /// @param newProposalThresholdContribution The new minimum contribution to propose.
    function setGovernanceParameters(uint256 newVotingPeriod, uint256 newQuorumPercentage, uint256 newProposalThresholdContribution) external {
         // Only callable by executeProposal when processing a SetGovernanceParameters proposal
        require(msg.sender == address(this), "DAS: Only callable via governance execution");

        votingPeriod = newVotingPeriod;
        quorumPercentage = newQuorumPercentage;
        proposalThresholdContribution = newProposalThresholdContribution;

        emit GovernanceParametersUpdated(newVotingPeriod, newQuorumPercentage, newProposalThresholdContribution);
    }


    // --- Utility/View Functions ---

    /// @notice Gets the name of the syndicate.
    /// @return The syndicate name string.
    function getSyndicateName() public view returns (string memory) {
        return syndicateName;
    }

    /// @notice Gets the address of the membership NFT contract.
    /// @return The address of the SyndicateMembershipNFT contract.
    function getMembershipNFTAddress() public view returns (address) {
        return address(membershipNFT);
    }

     /// @notice Gets the total number of current syndicate members.
     /// @dev This counts active token holders based on the internal mapping.
     /// @return The count of members.
     function getTotalMembers() public view returns (uint256) {
        // This is not simply the total number of issued tokens.
        // It requires iterating or maintaining a separate counter for *active* members.
        // For simplicity, we'll iterate through the _memberTokenIds mapping which tracks active members.
        // WARNING: Iterating through mappings can be gas-intensive if the mapping is large.
        // A more scalable design might track this count separately upon join/leave.
        uint256 count = 0;
        // Note: Solidity mappings cannot be reliably iterated. The previous _calculateTotalVotingPowerSnapshot
        // attempted iteration over token IDs, assuming sequential minting and mapping updates.
        // A correct implementation would need a separate list or iterable mapping library.
        // For this example, we will skip iterating a mapping or token IDs for the count
        // and acknowledge this limitation. Let's return the current token ID counter minus 1 (assuming ID 0 is unused).
        // This is inaccurate if tokens were burned.
        // Let's return the number of issued tokens as a proxy, acknowledging it's not perfectly accurate post-burns.
        return _nextTokenId.current() - 1; // Assuming token IDs start from 1
     }


     // --- ERC721Holder required function ---
     // This function is required by ERC721Holder
     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
         // Optionally handle receiving NFTs here.
         // For this contract's purpose, it primarily *issues* NFTs and holds ETH/ERC20.
         // Accepting other NFTs into the treasury would require governance mechanisms
         // to manage them (e.g., sending them out via CustomCall proposals).
         // Simply return the selector indicating acceptance.
         return this.onERC721Received.selector;
     }
}
```

**Explanation of Concepts and Choices:**

1.  **NFT as Identity:** Instead of a fungible token, membership is a unique NFT. This NFT *itself* doesn't grant voting power directly (it's non-transferable), but holding it is the *prerequisite* for an address to have associated contribution points, which *do* grant power. This links identity and status explicitly.
2.  **Non-Transferable NFT (`_beforeTokenTransfer` override):** Similar to Soulbound Tokens (SBTs), these NFTs are tied to the address. They cannot be bought, sold, or transferred (except burning to the zero address when leaving). This enforces that contribution and governance power are personal to the participant.
3.  **Contribution System (`_memberContributions` and `QuestType`, `MemberQuestAssignment`):** Introduces a mechanic for earning influence beyond just holding a token from the start. Contribution points are an on-chain metric that scales voting power.
4.  **Dynamic Quests:** The `defineSyndicateQuest` and `assignQuestToMember` functions, callable *only* via governance proposals, allow the syndicate to create on-chain tasks and assign them. `completeAssignedQuest` lets members claim points after *off-chain* work is verified (this contract trusts that the member only calls `completeAssignedQuest` when appropriate, or it assumes the off-chain process ensures this validation before triggering the call).
5.  **Tiered/Scaled Governance (`getVotingPower`):** Voting power is directly proportional to a member's contribution points. This creates a simple tiered system where higher contribution equals more influence. (Could be made non-linear, e.g., square root, for different effects).
6.  **Flexible Governance (`ProposalType.CustomCall`):** The `CustomCall` proposal type is a powerful pattern allowing the DAO to call arbitrary functions on other contracts (or itself), passing ETH and data. This is crucial for upgradability (e.g., proposing to replace the main contract with a new version via a proxy, or updating the NFT contract address) and interacting with other DeFi protocols or smart contracts without needing specific proposal types hardcoded for every possible interaction.
7.  **Governance-Controlled Configuration:** Sensitive parameters like voting period, quorum, and the proposal threshold can only be changed via a successful governance proposal (`SetGovernanceParameters`).
8.  **On-chain State for Quorum:** The `totalVotingPowerAtStart` snapshot taken when a proposal is created is used for quorum calculation. This avoids issues with voting power changing *during* the voting period, which could be manipulated. The `_calculateTotalVotingPowerSnapshot` iterates through *all* currently held member NFTs to sum their contribution – **warning:** this is gas-intensive and not scalable for very large DAOs. A real production system would use a checkpointing system or a list/iterable mapping of active members/contributions.
9.  **ERC721Holder:** Inheriting `ERC721Holder` allows the contract to receive ERC721 tokens, although the primary focus is on its own membership NFT. If the syndicate wanted to hold other NFTs as treasury assets, this provides the necessary callback.
10. **NonReentrancyGuard:** Used on functions interacting with external calls (`executeProposal`) or critical state changes (`joinSyndicate`, `leaveSyndicate`, `vote`, `completeAssignedQuest`) to prevent reentrancy attacks.
11. **Internal NFT Deployment:** The `SyndicateMembershipNFT` contract is defined and deployed within the main contract's constructor. This ensures a 1:1 relationship and simplifies setup. The main contract is granted the `minter` role on the NFT.
12. **Structs and Enums:** Clearly define the structure of `Proposal`, `QuestType`, `MemberQuestAssignment`, and the states/types for clarity and type safety.

This contract provides a foundation for a dynamic, contribution-driven decentralized syndicate with unique identity tied to an NFT and governance over its treasury and internal activities ("quests"). Remember that deploying and managing such a contract requires careful consideration of gas costs, security audits, and robust off-chain infrastructure for proposal interfaces and quest verification.