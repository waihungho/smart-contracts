```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Ecosystem with AI-Driven Evolution and Decentralized Governance
 * @author Bard (Example Smart Contract)
 *
 * @dev This smart contract implements a dynamic NFT ecosystem where NFTs can evolve based on
 * user interactions, on-chain data, and simulated AI-driven factors. It incorporates decentralized
 * governance for community-driven updates and features.
 *
 * **Outline:**
 *
 * 1. **NFT Core Functionality:**
 *    - Minting NFTs with initial attributes.
 *    - Transferring NFTs.
 *    - Retrieving NFT metadata (URI).
 *    - Querying NFT ownership.
 *    - Total NFT supply.
 *
 * 2. **Dynamic Evolution System:**
 *    - NFT Evolution based on staking duration.
 *    - NFT Evolution based on community voting outcomes.
 *    - NFT Evolution influenced by simulated "AI Weather" factor.
 *    - Function to manually trigger evolution (with conditions).
 *    - Function to check NFT evolution status.
 *
 * 3. **Staking and Utility System:**
 *    - Staking NFTs to earn utility tokens.
 *    - Unstaking NFTs and claiming utility tokens.
 *    - Viewing staking status and earned tokens.
 *    - Function to use utility tokens for NFT enhancements (future feature).
 *
 * 4. **Decentralized Governance (Simple):**
 *    - Proposing new evolution rules or contract parameters.
 *    - Voting on proposals using staked NFTs as voting power.
 *    - Executing approved proposals.
 *    - Viewing active and past proposals.
 *
 * 5. **AI Weather Simulation (Simplified On-Chain):**
 *    - Function to simulate and update an "AI Weather" factor (on-chain randomness/oracle simulation).
 *    - Get current AI Weather factor influencing NFT evolution.
 *
 * 6. **Admin and Utility Functions:**
 *    - Setting base metadata URI.
 *    - Pausing and unpausing contract functionalities.
 *    - Retrieving contract parameters and configurations.
 *    - Emergency withdrawal function (owner only).
 *
 * **Function Summary:**
 *
 * **NFT Core:**
 * - `mintNFT(address _to, string memory _baseURI)`: Mints a new NFT to the specified address with initial attributes.
 * - `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another.
 * - `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a given NFT ID.
 * - `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT ID.
 * - `totalSupply()`: Returns the total number of NFTs minted.
 *
 * **Dynamic Evolution:**
 * - `evolveNFT(uint256 _tokenId)`: Triggers NFT evolution based on staking, voting, and AI Weather (if conditions met).
 * - `checkEvolutionStatus(uint256 _tokenId)`: Checks and returns the current evolution status of an NFT.
 * - `setEvolutionStage(uint256 _tokenId, uint8 _stage)`: (Admin) Manually sets the evolution stage of an NFT for testing/emergencies.
 * - `getNFTStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * - `getNFTLastEvolvedTime(uint256 _tokenId)`: Returns the timestamp of the last evolution of an NFT.
 *
 * **Staking and Utility:**
 * - `stakeNFT(uint256 _tokenId)`: Stakes an NFT to start earning utility tokens.
 * - `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT and claims accumulated utility tokens.
 * - `claimUtilityTokens(uint256 _tokenId)`: Claims accumulated utility tokens for a staked NFT without unstaking.
 * - `getStakingStatus(uint256 _tokenId)`: Returns the staking status of an NFT.
 * - `getEarnedUtilityTokens(uint256 _tokenId)`: Returns the amount of utility tokens earned by a staked NFT.
 *
 * **Decentralized Governance:**
 * - `proposeNewRule(string memory _description, bytes memory _ruleData)`: Allows users to propose new evolution rules or contract parameters.
 * - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows users to vote on a specific proposal using staked NFT voting power.
 * - `executeProposal(uint256 _proposalId)`: (Admin/Governance Executor) Executes an approved proposal.
 * - `getProposalDetails(uint256 _proposalId)`: Returns details of a specific governance proposal.
 * - `getActiveProposals()`: Returns a list of active governance proposal IDs.
 *
 * **AI Weather Simulation:**
 * - `updateAIWeather()`: (Admin/Oracle Role) Updates the simulated "AI Weather" factor.
 * - `getCurrentAIWeather()`: Returns the current simulated "AI Weather" factor.
 * - `setAIWeatherInfluence(uint8 _influencePercentage)`: (Admin) Sets the percentage influence of AI Weather on evolution.
 *
 * **Admin and Utility:**
 * - `setBaseURI(string memory _newBaseURI)`: (Admin) Sets the base URI for NFT metadata.
 * - `pauseContract()`: (Admin) Pauses most contract functionalities.
 * - `unpauseContract()`: (Admin) Unpauses contract functionalities.
 * - `getContractPausedStatus()`: Returns the current paused status of the contract.
 * - `emergencyWithdraw(address payable _recipient)`: (Admin) Allows the owner to withdraw accidentally sent Ether or tokens.
 */
contract DynamicNFTecosystem {
    // --- State Variables ---

    string public name = "DynamicEvolutionNFT";
    string public symbol = "DENFT";
    string public baseURI;

    uint256 public totalSupplyCount;
    mapping(uint256 => address) public ownerOfNFT;
    mapping(address => uint256) public balanceNFT;
    mapping(uint256 => uint8) public nftEvolutionStage;
    mapping(uint256 => uint256) public nftLastEvolvedTime;

    // Staking related
    mapping(uint256 => bool) public isNFTStaked;
    mapping(uint256 => uint256) public stakeStartTime;
    uint256 public utilityTokensPerDay = 10; // Example reward rate

    // Governance related
    struct Proposal {
        string description;
        bytes ruleData;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool active;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public votingDurationDays = 7; // Example voting duration

    // AI Weather Simulation
    uint8 public currentAIWeatherFactor;
    uint8 public aiWeatherInfluencePercentage = 30; // Example influence percentage

    bool public contractPaused = false;
    address public owner;

    event NFTMinted(uint256 tokenId, address to);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTEvolved(uint256 tokenId, uint8 newStage);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker, uint256 utilityTokensClaimed);
    event UtilityTokensClaimed(uint256 tokenId, address owner, uint256 amount);
    event ProposalCreated(uint256 proposalId);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event AIWeatherUpdated(uint8 newFactor);
    event ContractPaused();
    event ContractUnpaused();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused.");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(ownerOfNFT[_tokenId] != address(0), "NFT does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(ownerOfNFT[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }


    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
        // Initialize AI Weather with a random value on deployment (for demonstration)
        currentAIWeatherFactor = uint8(block.timestamp % 100);
    }

    // --- 1. NFT Core Functionality ---

    /**
     * @dev Mints a new NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The base URI for the NFT metadata (can be overridden).
     */
    function mintNFT(address _to, string memory _baseURI) public onlyOwner whenNotPaused {
        totalSupplyCount++;
        uint256 newTokenId = totalSupplyCount;
        ownerOfNFT[newTokenId] = _to;
        balanceNFT[_to]++;
        nftEvolutionStage[newTokenId] = 1; // Initial stage
        nftLastEvolvedTime[newTokenId] = block.timestamp;

        // You might want to set specific initial attributes here based on some logic.

        baseURI = _baseURI; // In real scenario, manage baseURI more dynamically if needed.

        emit NFTMinted(newTokenId, _to);
    }

    /**
     * @dev Transfers an NFT from one address to another.
     * @param _from The address to transfer the NFT from.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_from == ownerOfNFT[_tokenId], "Incorrect sender address.");
        require(_to != address(0), "Invalid receiver address.");
        require(_from != _to, "Cannot transfer to yourself.");

        ownerOfNFT[_tokenId] = _to;
        balanceNFT[_from]--;
        balanceNFT[_to]++;

        emit NFTTransferred(_tokenId, _from, _to);
    }

    /**
     * @dev Returns the metadata URI for a given NFT ID.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        // In a real application, you might want to generate dynamic URIs based on NFT attributes and stage.
        // For simplicity, we use a base URI and append the token ID.
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Returns the owner of a given NFT ID.
     * @param _tokenId The ID of the NFT.
     * @return The address of the NFT owner.
     */
    function ownerOf(uint256 _tokenId) public view nftExists(_tokenId) returns (address) {
        return ownerOfNFT[_tokenId];
    }

    /**
     * @dev Returns the total number of NFTs minted.
     * @return The total supply count.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupplyCount;
    }


    // --- 2. Dynamic Evolution System ---

    /**
     * @dev Triggers NFT evolution based on staking duration, voting, and AI Weather.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(nftEvolutionStage[_tokenId] < 5, "NFT is already at max evolution stage."); // Example max stage

        uint8 currentStage = nftEvolutionStage[_tokenId];
        uint8 nextStage = currentStage + 1;
        bool canEvolve = true;

        // Evolution Condition 1: Staking Duration (Example: Staked for at least 3 days)
        if (isNFTStaked[_tokenId]) {
            uint256 stakedDuration = block.timestamp - stakeStartTime[_tokenId];
            uint256 daysStaked = stakedDuration / (1 days);
            if (daysStaked < 3) {
                canEvolve = false;
            }
        } else {
            canEvolve = false; // Must be staked to evolve in this example.
        }

        // Evolution Condition 2: Community Voting (Example: Needs a positive vote - not implemented fully here for simplicity, just placeholder)
        // In a real scenario, you'd check voting results related to this NFT or general evolution rules.
        bool voteConditionMet = true; // Placeholder - replace with actual voting logic check.
        if (!voteConditionMet) {
            canEvolve = false;
        }

        // Evolution Condition 3: AI Weather Influence (Example: Favorable AI Weather - simplified)
        uint8 weatherInfluenceThreshold = 50; // Example threshold
        if (currentAIWeatherFactor < weatherInfluenceThreshold && aiWeatherInfluencePercentage > 0) {
            // Chance based on AI Weather influence percentage
            if (uint8(block.timestamp % 100) < aiWeatherInfluencePercentage) {
                canEvolve = false; // Unfavorable AI Weather, reduced chance to evolve
            }
        }

        if (canEvolve) {
            nftEvolutionStage[_tokenId] = nextStage;
            nftLastEvolvedTime[_tokenId] = block.timestamp;
            emit NFTEvolved(_tokenId, nextStage);
        } else {
            revert("Evolution conditions not met.");
        }
    }

    /**
     * @dev Checks and returns the current evolution status of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return A string describing the evolution status.
     */
    function checkEvolutionStatus(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        uint8 stage = nftEvolutionStage[_tokenId];
        uint256 lastEvolved = nftLastEvolvedTime[_tokenId];
        bool staked = isNFTStaked[_tokenId];

        return string(abi.encodePacked("NFT Stage: ", Strings.toString(stage),
                                      ", Last Evolved: ", Strings.toString(lastEvolved),
                                      ", Staked: ", staked ? "Yes" : "No",
                                      ", AI Weather: ", Strings.toString(currentAIWeatherFactor)));
    }

    /**
     * @dev (Admin) Manually sets the evolution stage of an NFT for testing/emergencies.
     * @param _tokenId The ID of the NFT.
     * @param _stage The new evolution stage to set.
     */
    function setEvolutionStage(uint256 _tokenId, uint8 _stage) public onlyOwner nftExists(_tokenId) {
        nftEvolutionStage[_tokenId] = _stage;
        nftLastEvolvedTime[_tokenId] = block.timestamp;
        emit NFTEvolved(_tokenId, _stage);
    }

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The current evolution stage.
     */
    function getNFTStage(uint256 _tokenId) public view nftExists(_tokenId) returns (uint8) {
        return nftEvolutionStage[_tokenId];
    }

    /**
     * @dev Returns the timestamp of the last evolution of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The last evolved timestamp.
     */
    function getNFTLastEvolvedTime(uint256 _tokenId) public view nftExists(_tokenId) returns (uint256) {
        return nftLastEvolvedTime[_tokenId];
    }


    // --- 3. Staking and Utility System ---

    /**
     * @dev Stakes an NFT to start earning utility tokens.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(!isNFTStaked[_tokenId], "NFT is already staked.");
        isNFTStaked[_tokenId] = true;
        stakeStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an NFT and claims accumulated utility tokens.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(isNFTStaked[_tokenId], "NFT is not staked.");
        uint256 earnedTokens = calculateUtilityTokens(_tokenId);
        isNFTStaked[_tokenId] = false;
        delete stakeStartTime[_tokenId]; // Reset stake start time

        // Transfer utility tokens to the owner (in a real system, you'd have a utility token contract)
        // For this example, we just emit an event representing token claim.
        emit NFTUnstaked(_tokenId, msg.sender, earnedTokens);
        emit UtilityTokensClaimed(_tokenId, msg.sender, earnedTokens);
    }

    /**
     * @dev Claims accumulated utility tokens for a staked NFT without unstaking.
     * @param _tokenId The ID of the NFT.
     */
    function claimUtilityTokens(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(isNFTStaked[_tokenId], "NFT is not staked.");
        uint256 earnedTokens = calculateUtilityTokens(_tokenId);
        stakeStartTime[_tokenId] = block.timestamp; // Reset stake start time to current time upon claim.

        emit UtilityTokensClaimed(_tokenId, msg.sender, earnedTokens);
    }

    /**
     * @dev Returns the staking status of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return True if staked, false otherwise.
     */
    function getStakingStatus(uint256 _tokenId) public view nftExists(_tokenId) returns (bool) {
        return isNFTStaked[_tokenId];
    }

    /**
     * @dev Returns the amount of utility tokens earned by a staked NFT.
     * @param _tokenId The ID of the NFT.
     * @return The earned utility tokens.
     */
    function getEarnedUtilityTokens(uint256 _tokenId) public view nftExists(_tokenId) returns (uint256) {
        if (!isNFTStaked[_tokenId]) {
            return 0;
        }
        return calculateUtilityTokens(_tokenId);
    }

    /**
     * @dev Internal function to calculate utility tokens earned based on staking duration.
     * @param _tokenId The ID of the NFT.
     * @return The calculated utility tokens.
     */
    function calculateUtilityTokens(uint256 _tokenId) internal view returns (uint256) {
        uint256 stakedDuration = block.timestamp - stakeStartTime[_tokenId];
        uint256 daysStaked = stakedDuration / (1 days);
        return daysStaked * utilityTokensPerDay; // Example calculation
    }


    // --- 4. Decentralized Governance (Simple) ---

    /**
     * @dev Allows users to propose new evolution rules or contract parameters.
     * @param _description A description of the proposal.
     * @param _ruleData Data associated with the proposal (e.g., new evolution rules encoded).
     */
    function proposeNewRule(string memory _description, bytes memory _ruleData) public whenNotPaused {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.description = _description;
        newProposal.ruleData = _ruleData;
        newProposal.votingStartTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + (votingDurationDays * 1 days);
        newProposal.active = true;

        emit ProposalCreated(proposalCount);
    }

    /**
     * @dev Allows users to vote on a specific proposal using staked NFT voting power.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(proposals[_proposalId].active, "Proposal is not active.");
        require(block.timestamp < proposals[_proposalId].votingEndTime, "Voting period ended.");

        uint256 votingPower = 0;
        // In a more advanced system, voting power might be based on number of staked NFTs, evolution stage, etc.
        // For simplicity, each staked NFT gives 1 unit of voting power.
        for (uint256 i = 1; i <= totalSupplyCount; i++) {
            if (ownerOfNFT[i] == msg.sender && isNFTStaked[i]) {
                votingPower++; // Simple voting power calculation
            }
        }
        require(votingPower > 0, "You need staked NFTs to vote.");

        if (_vote) {
            proposals[_proposalId].votesFor += votingPower;
        } else {
            proposals[_proposalId].votesAgainst += votingPower;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev (Admin/Governance Executor) Executes an approved proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused { // Admin/Governance Executor role
        require(proposals[_proposalId].active, "Proposal is not active.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp > proposals[_proposalId].votingEndTime, "Voting period not ended yet.");

        // Example approval condition: More votes for than against
        if (proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst) {
            proposals[_proposalId].executed = true;
            proposals[_proposalId].active = false; // Mark as inactive after execution
            // Here you would implement the logic to execute the proposed rule change
            // based on proposals[_proposalId].ruleData. This is highly dependent on what rules you want to govern.
            // For example, if the ruleData contains a new utility token reward rate:
            // utilityTokensPerDay = abi.decode(proposals[_proposalId].ruleData, (uint256));

            emit ProposalExecuted(_proposalId);
        } else {
            proposals[_proposalId].active = false; // Mark as inactive even if not approved
            revert("Proposal not approved by community vote.");
        }
    }

    /**
     * @dev Returns details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal details struct.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Returns a list of active governance proposal IDs.
     * @return An array of active proposal IDs.
     */
    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCount);
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].active) {
                activeProposalIds[activeCount] = i;
                activeCount++;
            }
        }
        // Resize the array to remove unused elements
        assembly {
            mstore(activeProposalIds, activeCount)
        }
        return activeProposalIds;
    }


    // --- 5. AI Weather Simulation (Simplified On-Chain) ---

    /**
     * @dev (Admin/Oracle Role) Updates the simulated "AI Weather" factor.
     *  In a real system, this would likely be called by an oracle or off-chain service.
     */
    function updateAIWeather() public onlyOwner whenNotPaused { // Admin or designated oracle role
        // In a real scenario, get AI weather data from an oracle or external source.
        // For this example, we simulate a random change on-chain.
        currentAIWeatherFactor = uint8((block.timestamp + block.difficulty) % 100); // Example random update
        emit AIWeatherUpdated(currentAIWeatherFactor);
    }

    /**
     * @dev Returns the current simulated "AI Weather" factor.
     * @return The current AI Weather factor (0-99).
     */
    function getCurrentAIWeather() public view returns (uint8) {
        return currentAIWeatherFactor;
    }

    /**
     * @dev (Admin) Sets the percentage influence of AI Weather on evolution.
     * @param _influencePercentage The percentage (0-100) of AI Weather influence.
     */
    function setAIWeatherInfluence(uint8 _influencePercentage) public onlyOwner {
        require(_influencePercentage <= 100, "Influence percentage must be <= 100.");
        aiWeatherInfluencePercentage = _influencePercentage;
    }


    // --- 6. Admin and Utility Functions ---

    /**
     * @dev (Admin) Sets the base URI for NFT metadata.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev (Admin) Pauses most contract functionalities.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /**
     * @dev (Admin) Unpauses contract functionalities.
     */
    function unpauseContract() public onlyOwner whenPaused {
        contractPaused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Returns the current paused status of the contract.
     * @return True if paused, false otherwise.
     */
    function getContractPausedStatus() public view returns (bool) {
        return contractPaused;
    }

    /**
     * @dev (Admin) Allows the owner to withdraw accidentally sent Ether or tokens.
     * @param _recipient The address to send the withdrawn funds to.
     */
    function emergencyWithdraw(address payable _recipient) public onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(_recipient).transfer(contractBalance);
    }

    // --- Helper Library (String Conversion) ---
    // (Included for completeness, but in real-world, use OpenZeppelin Strings or similar)
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
}
```