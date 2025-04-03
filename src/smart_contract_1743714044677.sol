```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO)
 * that facilitates collaborative research, funding, intellectual property management,
 * and decentralized governance within a research community.

 * **Outline & Function Summary:**

 * **1. Core Functionality - Research Proposals & Funding:**
 *    - `submitResearchProposal(string _title, string _description, uint256 _fundingGoal, string _researchDomain)`: Allows researchers to submit research proposals.
 *    - `fundResearchProposal(uint256 _proposalId)`: Allows anyone to contribute funds to a research proposal.
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves detailed information about a specific research proposal.
 *    - `getProposalFundingStatus(uint256 _proposalId)`: Checks the current funding status of a proposal.
 *    - `withdrawProposalFunds(uint256 _proposalId)`: Allows the proposer to withdraw funds if the proposal is approved and funded.
 *    - `markProposalAsCompleted(uint256 _proposalId)`: Allows the proposer to mark a proposal as completed after research is done.

 * **2. Decentralized Governance & Voting:**
 *    - `createGovernanceProposal(string _title, string _description, bytes _calldata)`: Allows governance members to create proposals for changes to the DARO.
 *    - `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Allows governance members to vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: Executes a governance proposal if it passes the voting threshold.
 *    - `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a governance proposal.
 *    - `getGovernanceProposalVotingStatus(uint256 _proposalId)`: Checks the voting status of a governance proposal.
 *    - `addGovernanceMember(address _member)`: Allows the contract owner to add new governance members.
 *    - `removeGovernanceMember(address _member)`: Allows the contract owner to remove governance members.

 * **3. Intellectual Property (IP) Management with NFTs:**
 *    - `mintResearchNFT(uint256 _proposalId, string _metadataURI)`: Mints a non-fungible token (NFT) representing the IP of a completed research proposal.
 *    - `transferResearchNFT(uint256 _tokenId, address _to)`: Allows the owner of a Research NFT to transfer it.
 *    - `getResearchNFTOwner(uint256 _tokenId)`: Retrieves the owner of a specific Research NFT.
 *    - `burnResearchNFT(uint256 _tokenId)`: Allows the owner to burn a Research NFT (e.g., for public domain release after a certain period).

 * **4. Reputation & Contribution Tracking:**
 *    - `recordContribution(address _contributor, uint256 _proposalId, string _contributionDetails)`: Allows proposal owners or governance to record contributions to a research proposal.
 *    - `getContributorReputation(address _contributor)`: Retrieves a simple reputation score for a contributor (based on number of contributions).

 * **5. Utility & Administrative Functions:**
 *    - `pauseContract()`: Allows the contract owner to pause the contract in case of emergency or upgrade.
 *    - `unpauseContract()`: Allows the contract owner to unpause the contract.
 *    - `setGovernanceVotingPeriod(uint256 _votingPeriod)`: Allows the contract owner to set the voting period for governance proposals.
 *    - `setGovernanceQuorum(uint256 _quorum)`: Allows the contract owner to set the quorum for governance proposals.
 *    - `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to set a platform fee on funding contributions.
 *    - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *    - `isGovernanceMember(address _account)`: Checks if an address is a governance member.
 *    - `getContractBalance()`: Returns the current balance of the contract.
 */

contract DARO {
    // --- Structs and Enums ---
    struct ResearchProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string researchDomain;
        bool isFunded;
        bool isCompleted;
        uint256 submissionTimestamp;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        bytes calldata; // Calldata for execution
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
    }

    // --- State Variables ---
    address public owner;
    bool public paused;
    uint256 public proposalCounter;
    uint256 public governanceProposalCounter;
    uint256 public governanceVotingPeriod; // In seconds
    uint256 public governanceQuorum; // Percentage (e.g., 51 for 51%)
    uint256 public platformFeePercentage; // Percentage (e.g., 2 for 2%)
    uint256 public platformFeesCollected;

    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => bool) public governanceMembers;
    mapping(uint256 => address) public researchNFTOwner; // Token ID to Owner mapping
    mapping(address => uint256) public contributorReputation; // Address to Reputation Score

    // --- Events ---
    event ResearchProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ResearchProposalFunded(uint256 proposalId, address funder, uint256 amount);
    event ResearchProposalApproved(uint256 proposalId);
    event ResearchProposalCompleted(uint256 proposalId);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string title);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ResearchNFTMinted(uint256 tokenId, uint256 proposalId, address owner);
    event ResearchNFTTransferred(uint256 tokenId, address from, address to);
    event ResearchNFTBurned(uint256 tokenId, address owner);
    event ContributionRecorded(address contributor, uint256 proposalId, string details);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier proposalExists(uint256 _proposalId) {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier governanceProposalExists(uint256 _proposalId) {
        require(governanceProposals[_proposalId].id == _proposalId, "Governance proposal does not exist.");
        _;
    }

    modifier onlyGovernance() {
        require(governanceMembers[msg.sender], "Only governance members can call this function.");
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId) {
        require(researchProposals[_proposalId].proposer == msg.sender, "Only proposal proposer can call this function.");
        _;
    }

    modifier proposalNotCompleted(uint256 _proposalId) {
        require(!researchProposals[_proposalId].isCompleted, "Proposal is already marked as completed.");
        _;
    }


    // --- Constructor ---
    constructor(uint256 _initialGovernanceVotingPeriod, uint256 _initialGovernanceQuorum, uint256 _initialPlatformFeePercentage) payable {
        owner = msg.sender;
        paused = false;
        proposalCounter = 1; // Start proposal IDs from 1
        governanceProposalCounter = 1;
        governanceVotingPeriod = _initialGovernanceVotingPeriod;
        governanceQuorum = _initialGovernanceQuorum;
        platformFeePercentage = _initialPlatformFeePercentage;

        // Initially, the contract owner is also a governance member
        governanceMembers[owner] = true;
    }

    // --- 1. Core Functionality - Research Proposals & Funding ---
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _researchDomain
    ) external whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && _fundingGoal > 0 && bytes(_researchDomain).length > 0, "Invalid proposal details.");

        researchProposals[proposalCounter] = ResearchProposal({
            id: proposalCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            researchDomain: _researchDomain,
            isFunded: false,
            isCompleted: false,
            submissionTimestamp: block.timestamp
        });

        emit ResearchProposalSubmitted(proposalCounter, msg.sender, _title);
        proposalCounter++;
    }

    function fundResearchProposal(uint256 _proposalId) external payable whenNotPaused proposalExists(_proposalId) {
        require(!researchProposals[_proposalId].isFunded, "Proposal is already fully funded.");
        require(!researchProposals[_proposalId].isCompleted, "Proposal is already completed.");

        uint256 feeAmount = (msg.value * platformFeePercentage) / 100;
        uint256 fundingAmount = msg.value - feeAmount;

        researchProposals[_proposalId].currentFunding += fundingAmount;
        platformFeesCollected += feeAmount;

        emit ResearchProposalFunded(_proposalId, msg.sender, fundingAmount);

        if (researchProposals[_proposalId].currentFunding >= researchProposals[_proposalId].fundingGoal) {
            researchProposals[_proposalId].isFunded = true;
            emit ResearchProposalApproved(_proposalId);
        }
    }

    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (ResearchProposal memory) {
        return researchProposals[_proposalId];
    }

    function getProposalFundingStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 currentFunding, uint256 fundingGoal, bool isFunded) {
        return (researchProposals[_proposalId].currentFunding, researchProposals[_proposalId].fundingGoal, researchProposals[_proposalId].isFunded);
    }

    function withdrawProposalFunds(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) onlyProposalProposer(_proposalId) {
        require(researchProposals[_proposalId].isFunded, "Proposal is not yet fully funded.");
        require(!researchProposals[_proposalId].isCompleted, "Proposal is already completed.");
        require(researchProposals[_proposalId].currentFunding > 0, "No funds to withdraw.");

        uint256 amountToWithdraw = researchProposals[_proposalId].currentFunding;
        researchProposals[_proposalId].currentFunding = 0;

        (bool success, ) = payable(researchProposals[_proposalId].proposer).call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed.");
    }

    function markProposalAsCompleted(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) onlyProposalProposer(_proposalId) proposalNotCompleted(_proposalId) {
        require(researchProposals[_proposalId].isFunded, "Proposal must be fully funded to be marked as completed.");

        researchProposals[_proposalId].isCompleted = true;
        emit ResearchProposalCompleted(_proposalId);
    }


    // --- 2. Decentralized Governance & Voting ---
    function createGovernanceProposal(
        string memory _title,
        string memory _description,
        bytes memory _calldata
    ) external whenNotPaused onlyGovernance {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Invalid governance proposal details.");

        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            id: governanceProposalCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            calldata: _calldata,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + governanceVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        emit GovernanceProposalCreated(governanceProposalCounter, msg.sender, _title);
        governanceProposalCounter++;
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external whenNotPaused onlyGovernance governanceProposalExists(_proposalId) {
        require(block.timestamp <= governanceProposals[_proposalId].votingEndTime, "Voting period has ended.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");

        if (_support) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    function executeGovernanceProposal(uint256 _proposalId) external whenNotPaused onlyGovernance governanceProposalExists(_proposalId) {
        require(block.timestamp > governanceProposals[_proposalId].votingEndTime, "Voting period has not ended yet.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = governanceProposals[_proposalId].votesFor + governanceProposals[_proposalId].votesAgainst;
        uint256 quorumNeeded = (totalVotes * governanceQuorum) / 100;

        if (governanceProposals[_proposalId].votesFor >= quorumNeeded && governanceProposals[_proposalId].votesFor > governanceProposals[_proposalId].votesAgainst) {
            governanceProposals[_proposalId].passed = true;
            (bool success, ) = address(this).call(governanceProposals[_proposalId].calldata);
            require(success, "Governance proposal execution failed.");
            governanceProposals[_proposalId].executed = true;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            governanceProposals[_proposalId].passed = false;
            governanceProposals[_proposalId].executed = true; // Mark as executed even if failed to prevent re-execution
        }
    }

    function getGovernanceProposalDetails(uint256 _proposalId) external view governanceProposalExists(_proposalId) returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    function getGovernanceProposalVotingStatus(uint256 _proposalId) external view governanceProposalExists(_proposalId) returns (uint256 votesFor, uint256 votesAgainst, uint256 votingEndTime, bool executed, bool passed) {
        return (governanceProposals[_proposalId].votesFor, governanceProposals[_proposalId].votesAgainst, governanceProposals[_proposalId].votingEndTime, governanceProposals[_proposalId].executed, governanceProposals[_proposalId].passed);
    }

    function addGovernanceMember(address _member) external onlyOwner {
        governanceMembers[_member] = true;
    }

    function removeGovernanceMember(address _member) external onlyOwner {
        require(_member != owner, "Cannot remove the contract owner from governance.");
        governanceMembers[_member] = false;
    }

    // --- 3. Intellectual Property (IP) Management with NFTs ---
    uint256 public nextNFTTokenId = 1;

    function mintResearchNFT(uint256 _proposalId, string memory _metadataURI) external whenNotPaused proposalExists(_proposalId) onlyProposalProposer(_proposalId) proposalNotCompleted(_proposalId) {
        require(researchProposals[_proposalId].isFunded, "Proposal must be funded before minting NFT.");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty.");

        researchNFTOwner[nextNFTTokenId] = msg.sender;
        emit ResearchNFTMinted(nextNFTTokenId, _proposalId, msg.sender);
        nextNFTTokenId++;
    }

    function transferResearchNFT(uint256 _tokenId, address _to) external whenNotPaused {
        require(researchNFTOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(_to != address(0), "Invalid recipient address.");

        address previousOwner = researchNFTOwner[_tokenId];
        researchNFTOwner[_tokenId] = _to;
        emit ResearchNFTTransferred(_tokenId, previousOwner, _to);
    }

    function getResearchNFTOwner(uint256 _tokenId) external view returns (address) {
        return researchNFTOwner[_tokenId];
    }

    function burnResearchNFT(uint256 _tokenId) external whenNotPaused {
        require(researchNFTOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        address ownerOfNFT = researchNFTOwner[_tokenId];
        delete researchNFTOwner[_tokenId]; // Remove from mapping
        emit ResearchNFTBurned(_tokenId, ownerOfNFT);
    }


    // --- 4. Reputation & Contribution Tracking ---
    function recordContribution(address _contributor, uint256 _proposalId, string memory _contributionDetails) external whenNotPaused proposalExists(_proposalId) onlyGovernance {
        require(_contributor != address(0), "Invalid contributor address.");
        require(bytes(_contributionDetails).length > 0, "Contribution details cannot be empty.");

        contributorReputation[_contributor]++; // Simple reputation increase
        emit ContributionRecorded(_contributor, _proposalId, _contributionDetails);
    }

    function getContributorReputation(address _contributor) external view returns (uint256) {
        return contributorReputation[_contributor];
    }


    // --- 5. Utility & Administrative Functions ---
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function setGovernanceVotingPeriod(uint256 _votingPeriod) external onlyOwner {
        require(_votingPeriod > 0, "Voting period must be greater than 0.");
        governanceVotingPeriod = _votingPeriod;
    }

    function setGovernanceQuorum(uint256 _quorum) external onlyOwner {
        require(_quorum <= 100 && _quorum > 0, "Quorum must be between 1 and 100.");
        governanceQuorum = _quorum;
    }

    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
    }

    function withdrawPlatformFees() external onlyOwner {
        require(platformFeesCollected > 0, "No platform fees to withdraw.");
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0;
        (bool success, ) = payable(owner).call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed.");
    }

    function isGovernanceMember(address _account) external view returns (bool) {
        return governanceMembers[_account];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```