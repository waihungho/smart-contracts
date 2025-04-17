```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Evolution and Reputation System
 * @author Gemini AI
 * @dev A smart contract for dynamic NFTs that can evolve based on interactions and have an on-chain reputation system.
 *
 * **Outline:**
 * 1. **NFT Core Functionality:** Minting, Transfer, Metadata, Ownership.
 * 2. **Dynamic Evolution System:**  Experience points, Levels, Evolution Stages, Evolution triggers, Attribute updates.
 * 3. **Reputation System:** Reputation points, Reputation levels, Actions affecting reputation (positive/negative), Reporting mechanism, Community voting on reputation.
 * 4. **Community Interaction Features:**  NFT Interaction, Challenges, Leaderboards, Community Proposals, Voting.
 * 5. **Utility and Admin Functions:**  Parameter setting, Emergency functions, Data retrieval, Contract info.
 *
 * **Function Summary:**
 * 1. `mintNFT(address _to, string memory _baseURI)`: Mints a new NFT to the specified address with initial metadata.
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another.
 * 3. `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a given NFT ID.
 * 4. `getNFTData(uint256 _tokenId)`: Returns detailed data about an NFT (level, experience, reputation, stage).
 * 5. `interactWithNFT(uint256 _tokenId)`: Allows users to interact with an NFT, granting experience points.
 * 6. `checkEvolutionMilestone(uint256 _tokenId)`: Checks if an NFT has reached an evolution milestone and triggers evolution.
 * 7. `evolveNFT(uint256 _tokenId)`: Manually triggers the evolution process for an NFT (if conditions are met).
 * 8. `getNFTLevel(uint256 _tokenId)`: Returns the current level of an NFT.
 * 9. `getNFTExperience(uint256 _tokenId)`: Returns the current experience points of an NFT.
 * 10. `getNFTEvolutionStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * 11. `reportNFT(uint256 _tokenId, string memory _reason)`: Allows users to report an NFT for negative behavior, affecting its reputation.
 * 12. `voteOnReport(uint256 _reportId, bool _support)`: Allows community members to vote on a reported NFT.
 * 13. `updateNFTReputation(uint256 _tokenId, int256 _reputationChange)`: Directly updates the reputation of an NFT (admin function).
 * 14. `getNFTReputation(uint256 _tokenId)`: Returns the current reputation score of an NFT.
 * 15. `submitCommunityProposal(string memory _title, string memory _description, bytes memory _calldata)`: Allows users to submit community proposals for contract changes.
 * 16. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows token holders to vote on community proposals.
 * 17. `executeProposal(uint256 _proposalId)`: Executes a community proposal if it reaches the quorum and approval threshold.
 * 18. `setBaseMetadataURI(string memory _newBaseURI)`: Sets the base URI for NFT metadata (admin function).
 * 19. `pauseContract()`: Pauses critical contract functionalities (admin function).
 * 20. `unpauseContract()`: Resumes paused contract functionalities (admin function).
 * 21. `withdrawContractBalance()`: Allows the contract owner to withdraw contract balance (admin function).
 * 22. `getParameter(string memory _paramName)`: Retrieves a contract parameter by name.
 * 23. `setParameter(string memory _paramName, uint256 _value)`: Sets a contract parameter (admin function).
 */

contract DynamicNFTEvolutionReputation {
    // --- State Variables ---

    string public name = "Dynamic Evolution NFT";
    string public symbol = "DENFT";
    string public baseMetadataURI;

    address public owner;
    bool public paused = false;

    uint256 public nextNFTId = 1;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => NFTData) public nftData;
    mapping(address => uint256) public nftBalance;

    uint256 public nextReportId = 1;
    mapping(uint256 => Report) public reports;
    mapping(uint256 => mapping(address => bool)) public reportVotes;

    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes;

    struct NFTData {
        uint256 level;
        uint256 experience;
        int256 reputation;
        uint256 evolutionStage; // e.g., 0: Basic, 1: Advanced, 2: Elite
        uint256 lastInteractionTime;
    }

    struct Report {
        uint256 nftId;
        address reporter;
        string reason;
        uint256 upvotes;
        uint256 downvotes;
        bool resolved;
    }

    struct Proposal {
        string title;
        string description;
        address proposer;
        bytes calldataData;
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
    }

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTInteracted(uint256 tokenId, address user);
    event NFTEvolved(uint256 tokenId, uint256 newStage);
    event NFTReputationChanged(uint256 tokenId, int256 newReputation);
    event NFTReported(uint256 reportId, uint256 tokenId, address reporter, string reason);
    event ReportVoteCast(uint256 reportId, address voter, bool support);
    event CommunityProposalCreated(uint256 proposalId, address proposer, string title);
    event ProposalVoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ParameterUpdated(string paramName, uint256 newValue);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
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
        require(nftOwner[_tokenId] == msg.sender, "Not NFT owner.");
        _;
    }

    // --- Constructor ---
    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseMetadataURI = _baseURI;
    }

    // --- 1. NFT Core Functionality ---

    /**
     * @dev Mints a new NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The base URI for NFT metadata.
     */
    function mintNFT(address _to, string memory _baseURI) public onlyOwner whenNotPaused {
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = _to;
        nftBalance[_to]++;
        nftData[tokenId] = NFTData({
            level: 1,
            experience: 0,
            reputation: 0,
            evolutionStage: 0,
            lastInteractionTime: block.timestamp
        });
        baseMetadataURI = _baseURI; // allow admin to update URI during minting
        emit NFTMinted(tokenId, _to);
    }

    /**
     * @dev Transfers an NFT from one address to another.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused validNFT(_tokenId) onlyNFTOwner(_tokenId) {
        require(_from == msg.sender, "Invalid sender."); // Redundant check but good practice
        require(_to != address(0), "Cannot transfer to zero address.");
        nftOwner[_tokenId] = _to;
        nftBalance[_from]--;
        nftBalance[_to]++;
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /**
     * @dev Returns the metadata URI for a given NFT ID.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 _tokenId) public view validNFT(_tokenId) returns (string memory) {
        // Example: Construct URI based on tokenId and baseURI
        return string(abi.encodePacked(baseMetadataURI, "/", Strings.toString(_tokenId), ".json"));
    }

    /**
     * @dev Returns detailed data about an NFT.
     * @param _tokenId The ID of the NFT.
     * @return NFTData struct containing NFT information.
     */
    function getNFTData(uint256 _tokenId) public view validNFT(_tokenId) returns (NFTData memory) {
        return nftData[_tokenId];
    }

    // --- 2. Dynamic Evolution System ---

    uint256 public interactionExperienceGain = 10;
    uint256 public evolutionMilestoneExperience = 100; // Experience needed to evolve

    /**
     * @dev Allows users to interact with an NFT, granting experience points.
     * @param _tokenId The ID of the NFT being interacted with.
     */
    function interactWithNFT(uint256 _tokenId) public whenNotPaused validNFT(_tokenId) {
        nftData[_tokenId].experience += interactionExperienceGain;
        nftData[_tokenId].lastInteractionTime = block.timestamp;
        emit NFTInteracted(_tokenId, msg.sender);
        checkEvolutionMilestone(_tokenId); // Automatically check for evolution after interaction
    }

    /**
     * @dev Checks if an NFT has reached an evolution milestone and triggers evolution.
     * @param _tokenId The ID of the NFT to check.
     */
    function checkEvolutionMilestone(uint256 _tokenId) private validNFT(_tokenId) {
        if (nftData[_tokenId].experience >= evolutionMilestoneExperience) {
            evolveNFT(_tokenId);
        }
    }

    /**
     * @dev Manually triggers the evolution process for an NFT (if conditions are met).
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public whenNotPaused validNFT(_tokenId) {
        require(nftData[_tokenId].experience >= evolutionMilestoneExperience, "Not enough experience to evolve.");
        nftData[_tokenId].evolutionStage++;
        nftData[_tokenId].experience = 0; // Reset experience after evolution (or adjust as needed)
        emit NFTEvolved(_tokenId, nftData[_tokenId].evolutionStage);
        // Could add more complex evolution logic here, like attribute boosts, metadata updates etc.
    }

    /**
     * @dev Returns the current level of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The level of the NFT.
     */
    function getNFTLevel(uint256 _tokenId) public view validNFT(_tokenId) returns (uint256) {
        return nftData[_tokenId].level;
    }

    /**
     * @dev Returns the current experience points of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The experience points of the NFT.
     */
    function getNFTExperience(uint256 _tokenId) public view validNFT(_tokenId) returns (uint256) {
        return nftData[_tokenId].experience;
    }

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The evolution stage of the NFT.
     */
    function getNFTEvolutionStage(uint256 _tokenId) public view validNFT(_tokenId) returns (uint256) {
        return nftData[_tokenId].evolutionStage;
    }

    // --- 3. Reputation System ---

    int256 public reportUpvoteThreshold = 5;
    int256 public reportDownvoteThreshold = -5;
    int256 public reputationChangeOnReport = -10;

    /**
     * @dev Allows users to report an NFT for negative behavior, affecting its reputation.
     * @param _tokenId The ID of the NFT being reported.
     * @param _reason The reason for reporting.
     */
    function reportNFT(uint256 _tokenId, string memory _reason) public whenNotPaused validNFT(_tokenId) {
        require(nftOwner[_tokenId] != msg.sender, "Cannot report your own NFT."); // Prevent self-reporting
        require(reports[nextReportId].nftId == 0, "Report ID collision."); // Basic check for ID collision (unlikely but good to have)

        reports[nextReportId] = Report({
            nftId: _tokenId,
            reporter: msg.sender,
            reason: _reason,
            upvotes: 0,
            downvotes: 0,
            resolved: false
        });
        emit NFTReported(nextReportId, _tokenId, msg.sender, _reason);
        nextReportId++;
    }

    /**
     * @dev Allows community members to vote on a reported NFT.
     * @param _reportId The ID of the report.
     * @param _support True for upvote (support report), false for downvote (dispute report).
     */
    function voteOnReport(uint256 _reportId, bool _support) public whenNotPaused {
        require(reports[_reportId].nftId != 0, "Invalid report ID.");
        require(!reports[_reportId].resolved, "Report already resolved.");
        require(reportVotes[_reportId][msg.sender] == false, "Already voted on this report.");

        reportVotes[_reportId][msg.sender] = true;
        if (_support) {
            reports[_reportId].upvotes++;
        } else {
            reports[_reportId].downvotes--;
        }
        emit ReportVoteCast(_reportId, msg.sender, _support);

        // Automatically resolve report and update reputation based on vote thresholds
        if (reports[_reportId].upvotes >= reportUpvoteThreshold) {
            updateNFTReputation(reports[_reportId].nftId, reputationChangeOnReport);
            reports[_reportId].resolved = true;
        } else if (reports[_reportId].downvotes <= reportDownvoteThreshold) {
            reports[_reportId].resolved = true; // Report disputed, no reputation change
        }
    }

    /**
     * @dev Directly updates the reputation of an NFT (admin function).
     * @param _tokenId The ID of the NFT.
     * @param _reputationChange The amount to change the reputation by.
     */
    function updateNFTReputation(uint256 _tokenId, int256 _reputationChange) public onlyOwner validNFT(_tokenId) {
        nftData[_tokenId].reputation += _reputationChange;
        emit NFTReputationChanged(_tokenId, nftData[_tokenId].reputation);
    }

    /**
     * @dev Returns the current reputation score of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The reputation score of the NFT.
     */
    function getNFTReputation(uint256 _tokenId) public view validNFT(_tokenId) returns (int256) {
        return nftData[_tokenId].reputation;
    }

    // --- 4. Community Interaction Features ---

    uint256 public proposalQuorum = 10; // Minimum votes for proposal to pass
    uint256 public proposalApprovalThreshold = 60; // Percentage of upvotes needed to pass (60%)

    /**
     * @dev Allows users to submit community proposals for contract changes.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposal.
     * @param _calldata The calldata to execute if the proposal passes (can be empty for informational proposals).
     */
    function submitCommunityProposal(string memory _title, string memory _description, bytes memory _calldata) public whenNotPaused {
        require(proposals[nextProposalId].proposer == address(0), "Proposal ID collision."); // Basic check for ID collision

        proposals[nextProposalId] = Proposal({
            title: _title,
            description: _description,
            proposer: msg.sender,
            calldataData: _calldata,
            upvotes: 0,
            downvotes: 0,
            executed: false
        });
        emit CommunityProposalCreated(nextProposalId, msg.sender, _title);
        nextProposalId++;
    }

    /**
     * @dev Allows token holders to vote on community proposals.
     * @param _proposalId The ID of the proposal.
     * @param _support True for upvote (support proposal), false for downvote (reject proposal).
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(proposals[_proposalId].proposer != address(0), "Invalid proposal ID.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(proposalVotes[_proposalId][msg.sender] == false, "Already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_support) {
            proposals[_proposalId].upvotes++;
        } else {
            proposals[_proposalId].downvotes++;
        }
        emit ProposalVoteCast(_proposalId, msg.sender, _support);

        // Automatically execute proposal if quorum and approval threshold are met
        if (proposals[_proposalId].upvotes >= proposalQuorum) {
            uint256 totalVotes = proposals[_proposalId].upvotes + proposals[_proposalId].downvotes;
            uint256 approvalPercentage = (proposals[_proposalId].upvotes * 100) / totalVotes;
            if (approvalPercentage >= proposalApprovalThreshold) {
                executeProposal(_proposalId);
            }
        }
    }

    /**
     * @dev Executes a community proposal if it reaches the quorum and approval threshold.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused { // Only owner can execute after community vote
        require(proposals[_proposalId].proposer != address(0), "Invalid proposal ID.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(proposals[_proposalId].upvotes >= proposalQuorum, "Proposal quorum not reached.");
        uint256 totalVotes = proposals[_proposalId].upvotes + proposals[_proposalId].downvotes;
        uint256 approvalPercentage = (proposals[_proposalId].upvotes * 100) / totalVotes;
        require(approvalPercentage >= proposalApprovalThreshold, "Proposal approval threshold not reached.");

        if (proposals[_proposalId].calldataData.length > 0) {
            (bool success, ) = address(this).delegatecall(proposals[_proposalId].calldataData); // Use delegatecall for contract state changes
            require(success, "Proposal execution failed.");
        }
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }


    // --- 5. Utility and Admin Functions ---

    /**
     * @dev Sets the base URI for NFT metadata.
     * @param _newBaseURI The new base URI.
     */
    function setBaseMetadataURI(string memory _newBaseURI) public onlyOwner {
        baseMetadataURI = _newBaseURI;
        emit ParameterUpdated("baseMetadataURI", 0); // Using 0 as a placeholder value for string updates
    }

    /**
     * @dev Pauses critical contract functionalities.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Resumes paused contract functionalities.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw contract balance.
     */
    function withdrawContractBalance() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Retrieves a contract parameter by name (example for interactionExperienceGain).
     * @param _paramName The name of the parameter to retrieve.
     * @return The value of the parameter.
     */
    function getParameter(string memory _paramName) public view returns (uint256) {
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("interactionExperienceGain"))) {
            return interactionExperienceGain;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("evolutionMilestoneExperience"))) {
            return evolutionMilestoneExperience;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reportUpvoteThreshold"))) {
            return reportUpvoteThreshold;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reportDownvoteThreshold"))) {
            return reportDownvoteThreshold;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reputationChangeOnReport"))) {
            return uint256(reputationChangeOnReport); // Cast back to uint256 for return type consistency
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalQuorum"))) {
            return proposalQuorum;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalApprovalThreshold"))) {
            return proposalApprovalThreshold;
        }
        revert("Parameter not found.");
    }

    /**
     * @dev Sets a contract parameter (example for interactionExperienceGain).
     * @param _paramName The name of the parameter to set.
     * @param _value The new value for the parameter.
     */
    function setParameter(string memory _paramName, uint256 _value) public onlyOwner {
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("interactionExperienceGain"))) {
            interactionExperienceGain = _value;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("evolutionMilestoneExperience"))) {
            evolutionMilestoneExperience = _value;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reportUpvoteThreshold"))) {
            reportUpvoteThreshold = int256(_value); // Cast to int256 if needed
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reportDownvoteThreshold"))) {
            reportDownvoteThreshold = int256(_value); // Cast to int256 if needed
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reputationChangeOnReport"))) {
            reputationChangeOnReport = int256(_value); // Cast to int256 if needed
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalQuorum"))) {
            proposalQuorum = _value;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalApprovalThreshold"))) {
            proposalApprovalThreshold = _value;
        } else {
            revert("Parameter not found.");
        }
        emit ParameterUpdated(_paramName, _value);
    }
}

// --- Library for String Conversion (Solidity 0.8+ doesn't have built-in string conversion) ---
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

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