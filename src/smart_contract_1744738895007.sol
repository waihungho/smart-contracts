```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT & DAO Governance Contract
 * @author Gemini AI Assistant
 * @dev A smart contract implementing a dynamic NFT collection governed by a DAO.
 *      NFTs can evolve based on community votes and on-chain events.
 *
 * Outline & Function Summary:
 *
 * --- Core NFT Functions ---
 * 1. mintNFT(address _to, string memory _baseURI) public onlyOwner: Mints a new Dynamic NFT to the specified address.
 * 2. tokenURI(uint256 _tokenId) public view returns (string memory): Returns the URI for a given NFT token ID.
 * 3. transferNFT(address _to, uint256 _tokenId) public: Allows NFT holders to transfer their NFTs.
 * 4. burnNFT(uint256 _tokenId) public onlyNFTHolder: Allows NFT holders to burn their NFTs.
 * 5. getNFTProperties(uint256 _tokenId) public view returns (string memory): Retrieves dynamic properties of an NFT as a JSON string.
 * 6. setBaseURI(string memory _newBaseURI) public onlyOwner: Updates the base URI for the NFT metadata.
 *
 * --- Dynamic NFT Evolution & Traits ---
 * 7. evolveNFT(uint256 _tokenId) public onlyGovernance: Triggers the evolution of an NFT based on predefined rules and community votes.
 * 8. getEvolutionStage(uint256 _tokenId) public view returns (uint8): Returns the current evolution stage of an NFT.
 * 9. setEvolutionRules(uint8 _stage, string memory _rules) public onlyGovernance: Sets the evolution rules for a specific stage (e.g., criteria for evolution).
 * 10. getEvolutionRules(uint8 _stage) public view returns (string memory): Retrieves the evolution rules for a specific stage.
 * 11. triggerNFTEvent(uint256 _tokenId, string memory _eventData) public onlyGovernance: Allows governance to trigger specific events for NFTs, influencing their evolution.
 *
 * --- DAO Governance & Voting ---
 * 12. proposeEvolution(uint256 _tokenId, uint8 _nextStage) public onlyNFTHolder: Allows NFT holders to propose an evolution for their NFT.
 * 13. proposeRuleChange(uint8 _stage, string memory _newRules) public onlyGovernanceTokenHolder: Governance token holders propose changes to evolution rules.
 * 14. voteOnProposal(uint256 _proposalId, bool _support) public onlyGovernanceTokenHolder: Allows governance token holders to vote on proposals.
 * 15. executeProposal(uint256 _proposalId) public onlyGovernance: Executes a passed proposal.
 * 16. getProposalState(uint256 _proposalId) public view returns (string memory): Returns the current state of a proposal (Pending, Active, Passed, Rejected, Executed).
 * 17. createGovernanceToken(string memory _name, string memory _symbol, uint256 _initialSupply, address _recipient) public onlyOwner: Deploys a simple governance token for DAO participation.
 * 18. setGovernanceTokenAddress(address _tokenAddress) public onlyOwner: Sets the address of an external governance token for voting.
 * 19. getGovernanceTokenAddress() public view returns (address): Returns the address of the governance token.
 * 20. setVotingQuorum(uint256 _quorumPercentage) public onlyGovernance: Sets the quorum percentage required for proposal to pass.
 * 21. getVotingQuorum() public view returns (uint256): Returns the current voting quorum percentage.
 * 22. setVotingPeriod(uint256 _votingPeriodBlocks) public onlyGovernance: Sets the voting period in blocks for proposals.
 * 23. getVotingPeriod() public view returns (uint256): Returns the current voting period in blocks.
 *
 * --- Utility & Treasury ---
 * 24. withdrawTreasury(uint256 _amount) public onlyGovernance: Allows governance to withdraw funds from the contract treasury.
 * 25. getTreasuryBalance() public view returns (uint256): Returns the current balance of the contract treasury.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DynamicNFTDAO is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public baseURI;
    address public governanceAddress; // Address authorized to perform governance actions
    address public governanceTokenAddress; // Address of the governance token contract
    uint256 public votingQuorumPercentage = 50; // Default quorum: 50%
    uint256 public votingPeriodBlocks = 100; // Default voting period: 100 blocks

    struct NFTProperties {
        uint8 evolutionStage;
        string traits; // Could be JSON to store dynamic traits, e.g., {"color": "blue", "power": 10}
        // Add more dynamic properties as needed
    }

    mapping(uint256 => NFTProperties) public nftProperties;
    mapping(uint8 => string) public evolutionRules; // Rules for each evolution stage (e.g., JSON rules)
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;

    enum ProposalState { Pending, Active, Passed, Rejected, Executed }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        uint256 tokenId; // Relevant for NFT evolution proposals
        uint8 nextEvolutionStage; // For evolution proposals
        uint8 ruleStage; // For rule change proposals
        string newRules; // For rule change proposals
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
    }

    enum ProposalType { Evolution, RuleChange }

    event NFTMinted(uint256 tokenId, address to);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId, address owner);
    event NFTEvolved(uint256 tokenId, uint8 stage);
    event EvolutionRulesSet(uint8 stage, string rules);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event GovernanceTokenCreated(address tokenAddress, string name, string symbol);
    event GovernanceTokenAddressSet(address tokenAddress);
    event VotingQuorumSet(uint256 quorumPercentage);
    event VotingPeriodSet(uint256 votingPeriodBlocks);
    event TreasuryWithdrawal(address recipient, uint256 amount);


    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance address can call this function");
        _;
    }

    modifier onlyGovernanceTokenHolder() {
        require(governanceTokenAddress != address(0), "Governance token not set");
        ERC20 governanceToken = ERC20(governanceTokenAddress);
        require(governanceToken.balanceOf(msg.sender) > 0, "Must hold governance tokens to perform this action");
        _;
    }

    modifier onlyNFTHolder() {
        require(_exists(msg.sender), "You must be the holder of this NFT"); // Basic check, refine as needed
        _;
    }

    modifier onlyNFTHolderOfToken(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        _;
    }


    constructor(string memory _name, string memory _symbol, string memory _baseURI, address _governanceAddress) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        governanceAddress = _governanceAddress;
    }

    // --- Core NFT Functions ---
    /// @dev Mints a new Dynamic NFT to the specified address. Only callable by the contract owner.
    /// @param _to Address to receive the NFT.
    /// @param _baseURI Base URI for the NFT metadata.
    function mintNFT(address _to, string memory _baseURI) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(_to, tokenId);
        nftProperties[tokenId] = NFTProperties({
            evolutionStage: 1, // Initial evolution stage
            traits: "{}" // Initial traits can be empty or predefined
        });
        setBaseURI(_baseURI); // Update base URI upon first mint for demonstration (consider better URI management)
        emit NFTMinted(tokenId, _to);
    }

    /// @dev Returns the URI for a given NFT token ID.
    /// @param _tokenId The ID of the NFT token.
    /// @return string The URI for the NFT.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /// @dev Allows NFT holders to transfer their NFTs.
    /// @param _to Address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) public onlyNFTHolderOfToken(_tokenId) {
        safeTransferFrom(msg.sender, _to, _tokenId);
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    /// @dev Allows NFT holders to burn their NFTs.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) public onlyNFTHolderOfToken(_tokenId) {
        _burn(_tokenId);
        emit NFTBurned(_tokenId, msg.sender);
    }

    /// @dev Retrieves dynamic properties of an NFT as a JSON string.
    /// @param _tokenId The ID of the NFT.
    /// @return string JSON string representing NFT properties.
    function getNFTProperties(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftProperties[_tokenId].traits; // Returns the traits JSON string
    }

    /// @dev Updates the base URI for the NFT metadata. Only callable by the contract owner.
    /// @param _newBaseURI The new base URI to set.
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }


    // --- Dynamic NFT Evolution & Traits ---
    /// @dev Triggers the evolution of an NFT based on predefined rules and community votes. Only callable by governance.
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFT(uint256 _tokenId) public onlyGovernance {
        require(_exists(_tokenId), "NFT does not exist");
        uint8 currentStage = nftProperties[_tokenId].evolutionStage;
        uint8 nextStage = currentStage + 1; // Simple evolution to next stage, can be more complex
        string memory rules = evolutionRules[nextStage];
        // Implement complex evolution logic based on rules, on-chain data, etc.
        // For now, just increment the evolution stage and update traits (example)
        if (bytes(rules).length > 0) { // Example: Only evolve if rules are defined for next stage
            nftProperties[_tokenId].evolutionStage = nextStage;
            // Example trait update based on stage (can be more sophisticated)
            string memory newTraits = string(abi.encodePacked('{"stage": ', Strings.toString(nextStage), ', "evolved": true}'));
            nftProperties[_tokenId].traits = newTraits;
            emit NFTEvolved(_tokenId, nextStage);
        } else {
            // Revert or handle case where no rules are defined for next stage
            revert("No evolution rules defined for the next stage.");
        }
    }

    /// @dev Returns the current evolution stage of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return uint8 The current evolution stage.
    function getEvolutionStage(uint256 _tokenId) public view returns (uint8) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftProperties[_tokenId].evolutionStage;
    }

    /// @dev Sets the evolution rules for a specific stage. Only callable by governance.
    /// @param _stage The evolution stage number.
    /// @param _rules JSON string defining the evolution rules for this stage.
    function setEvolutionRules(uint8 _stage, string memory _rules) public onlyGovernance {
        evolutionRules[_stage] = _rules;
        emit EvolutionRulesSet(_stage, _rules);
    }

    /// @dev Retrieves the evolution rules for a specific stage.
    /// @param _stage The evolution stage number.
    /// @return string JSON string representing the evolution rules.
    function getEvolutionRules(uint8 _stage) public view returns (string memory) {
        return evolutionRules[_stage];
    }

    /// @dev Allows governance to trigger specific events for NFTs, influencing their evolution. Only callable by governance.
    /// @param _tokenId The ID of the NFT to trigger the event for.
    /// @param _eventData JSON string describing the event data.
    function triggerNFTEvent(uint256 _tokenId, string memory _eventData) public onlyGovernance {
        require(_exists(_tokenId), "NFT does not exist");
        // Example: Update NFT traits based on event data (can be more complex)
        string memory currentTraits = nftProperties[_tokenId].traits;
        string memory updatedTraits = string(abi.encodePacked(currentTraits, ', "event": ', _eventData, '}')); // Simple append, improve JSON merging
        nftProperties[_tokenId].traits = updatedTraits;
        // Can emit an event for NFT event triggering if needed.
    }


    // --- DAO Governance & Voting ---
    /// @dev Allows NFT holders to propose an evolution for their NFT.
    /// @param _tokenId The ID of the NFT to evolve.
    /// @param _nextStage The proposed next evolution stage.
    function proposeEvolution(uint256 _tokenId, uint8 _nextStage) public onlyNFTHolderOfToken(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftProperties[_tokenId].evolutionStage < _nextStage, "Next stage must be higher than current stage");

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.Evolution,
            tokenId: _tokenId,
            nextEvolutionStage: _nextStage,
            ruleStage: 0, // Not relevant for evolution proposal
            newRules: "", // Not relevant for evolution proposal
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingPeriodBlocks,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, ProposalType.Evolution, msg.sender);
    }


    /// @dev Governance token holders propose changes to evolution rules for a specific stage.
    /// @param _stage The evolution stage to change rules for.
    /// @param _newRules JSON string defining the new evolution rules.
    function proposeRuleChange(uint8 _stage, string memory _newRules) public onlyGovernanceTokenHolder {
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.RuleChange,
            tokenId: 0, // Not relevant for rule change proposal
            nextEvolutionStage: 0, // Not relevant for rule change proposal
            ruleStage: _stage,
            newRules: _newRules,
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingPeriodBlocks,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, ProposalType.RuleChange, msg.sender);
    }

    /// @dev Allows governance token holders to vote on proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote yes, false to vote no.
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyGovernanceTokenHolder {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        require(block.number <= proposals[_proposalId].endTime, "Voting period has ended");

        if (_support) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }


    /// @dev Executes a passed proposal. Only callable by governance.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyGovernance {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        require(block.number > proposals[_proposalId].endTime, "Voting period has not ended");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        uint256 quorum = (totalVotes * 100) / getGovernanceTokenTotalSupply(); // Assuming governance token has totalSupply()
        require(quorum >= votingQuorumPercentage, "Quorum not reached");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "Proposal rejected by majority");

        proposals[_proposalId].state = ProposalState.Passed; // Mark as passed first to avoid re-entrancy issues if execution fails

        if (proposals[_proposalId].proposalType == ProposalType.Evolution) {
            evolveNFT(proposals[_proposalId].tokenId);
        } else if (proposals[_proposalId].proposalType == ProposalType.RuleChange) {
            setEvolutionRules(proposals[_proposalId].ruleStage, proposals[_proposalId].newRules);
        }

        proposals[_proposalId].state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /// @dev Returns the current state of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return string String representation of the proposal state.
    function getProposalState(uint256 _proposalId) public view returns (string memory) {
        ProposalState state = proposals[_proposalId].state;
        if (state == ProposalState.Pending) return "Pending";
        if (state == ProposalState.Active) return "Active";
        if (state == ProposalState.Passed) return "Passed";
        if (state == ProposalState.Rejected) return "Rejected";
        if (state == ProposalState.Executed) return "Executed";
        return "Unknown";
    }

    /// @dev Creates a simple governance token for DAO participation. Only callable by the contract owner.
    /// @param _name Name of the governance token.
    /// @param _symbol Symbol of the governance token.
    /// @param _initialSupply Initial supply of the governance token.
    /// @param _recipient Address to receive the initial supply.
    function createGovernanceToken(string memory _name, string memory _symbol, uint256 _initialSupply, address _recipient) public onlyOwner {
        GovernanceToken newToken = new GovernanceToken(_name, _symbol, _initialSupply, _recipient);
        governanceTokenAddress = address(newToken);
        emit GovernanceTokenCreated(governanceTokenAddress, _name, _symbol);
        emit GovernanceTokenAddressSet(governanceTokenAddress);
    }

    /// @dev Sets the address of an external governance token for voting. Only callable by the contract owner.
    /// @param _tokenAddress Address of the external governance token contract.
    function setGovernanceTokenAddress(address _tokenAddress) public onlyOwner {
        governanceTokenAddress = _tokenAddress;
        emit GovernanceTokenAddressSet(_tokenAddress);
    }

    /// @dev Returns the address of the governance token.
    /// @return address Address of the governance token.
    function getGovernanceTokenAddress() public view returns (address) {
        return governanceTokenAddress;
    }

    /// @dev Sets the quorum percentage required for proposal to pass. Only callable by governance.
    /// @param _quorumPercentage The quorum percentage (e.g., 50 for 50%).
    function setVotingQuorum(uint256 _quorumPercentage) public onlyGovernance {
        require(_quorumPercentage <= 100, "Quorum percentage must be <= 100");
        votingQuorumPercentage = _quorumPercentage;
        emit VotingQuorumSet(_quorumPercentage);
    }

    /// @dev Returns the current voting quorum percentage.
    /// @return uint256 The voting quorum percentage.
    function getVotingQuorum() public view returns (uint256) {
        return votingQuorumPercentage;
    }

    /// @dev Sets the voting period in blocks for proposals. Only callable by governance.
    /// @param _votingPeriodBlocks The voting period in blocks.
    function setVotingPeriod(uint256 _votingPeriodBlocks) public onlyGovernance {
        votingPeriodBlocks = _votingPeriodBlocks;
        emit VotingPeriodSet(_votingPeriodBlocks);
    }

    /// @dev Returns the current voting period in blocks.
    /// @return uint256 The voting period in blocks.
    function getVotingPeriod() public view returns (uint256) {
        return votingPeriodBlocks;
    }


    // --- Utility & Treasury ---
    /// @dev Allows governance to withdraw funds from the contract treasury. Only callable by governance.
    /// @param _amount The amount to withdraw in wei.
    function withdrawTreasury(uint256 _amount) public onlyGovernance {
        payable(governanceAddress).transfer(_amount);
        emit TreasuryWithdrawal(governanceAddress, _amount);
    }

    /// @dev Returns the current balance of the contract treasury.
    /// @return uint256 The contract treasury balance in wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Helper function to get total supply of governance token (assuming standard ERC20) ---
    function getGovernanceTokenTotalSupply() public view returns (uint256) {
        if (governanceTokenAddress != address(0)) {
            ERC20 governanceToken = ERC20(governanceTokenAddress);
            return governanceToken.totalSupply();
        }
        return 0; // Or handle differently if no governance token is set.
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}


// --- Simple Governance Token Contract (Example - for demonstration purposes) ---
contract GovernanceToken is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply, address _recipient) ERC20(_name, _symbol) {
        _mint(_recipient, _initialSupply);
    }
}
```