```solidity
/**
 * @title Dynamic Evolving NFT with DAO Governance and Staking
 * @author Gemini AI Assistant
 * @dev This contract implements a unique NFT system where NFTs can dynamically evolve based on community proposals and DAO governance.
 * It includes features for NFT minting, transfer, approvals, dynamic trait evolution through proposals,
 * DAO governance for contract parameters and feature changes, NFT staking for rewards, and more.
 * It aims to be a creative and advanced example, avoiding direct duplication of common open-source contracts.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core NFT Functions (ERC721-inspired):**
 *    - `mintDynamicNFT(address recipient, string memory baseURI)`: Mints a new Dynamic NFT to the specified address with an initial base URI.
 *    - `transferNFT(address recipient, uint256 tokenId)`: Transfers an NFT to another address.
 *    - `approveNFT(address approved, uint256 tokenId)`: Approves an address to operate on a specific NFT.
 *    - `getApprovedNFT(uint256 tokenId)`: Gets the approved address for a specific NFT.
 *    - `setApprovalForAllNFT(address operator, bool approved)`: Enables or disables operator approval for all NFTs of the sender.
 *    - `isApprovedForAllNFT(address owner, address operator)`: Checks if an operator is approved for all NFTs of an owner.
 *    - `tokenURINFT(uint256 tokenId)`: Returns the URI for a given NFT token. (Dynamic based on traits)
 *    - `totalSupplyNFT()`: Returns the total number of NFTs minted.
 *    - `balanceOfNFT(address owner)`: Returns the number of NFTs owned by an address.
 *    - `ownerOfNFT(uint256 tokenId)`: Returns the owner of a given NFT.
 *
 * **2. Dynamic NFT Evolution Functions:**
 *    - `proposeTraitEvolution(uint256 tokenId, string memory traitName, string memory traitValue)`: Allows users to propose changes to an NFT's traits.
 *    - `voteOnEvolutionProposal(uint256 proposalId, bool vote)`: Allows NFT holders to vote on trait evolution proposals.
 *    - `executeEvolutionProposal(uint256 proposalId)`: Executes a successful trait evolution proposal, updating the NFT's traits and URI.
 *    - `getNFTTraits(uint256 tokenId)`: Retrieves the current traits of a given NFT.
 *    - `getEvolutionProposalDetails(uint256 proposalId)`: Retrieves details of a specific evolution proposal.
 *
 * **3. DAO Governance Functions:**
 *    - `createGovernanceProposal(string memory description, bytes memory proposalData)`: Allows DAO members to create general governance proposals.
 *    - `voteOnGovernanceProposal(uint256 proposalId, bool vote)`: Allows DAO members to vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 proposalId)`: Executes a successful governance proposal, potentially changing contract parameters or logic.
 *    - `getParameter(string memory parameterName)`: Retrieves a configurable contract parameter.
 *    - `setParameter(string memory parameterName, uint256 parameterValue)`: (Governance controlled) Sets a configurable contract parameter through governance.
 *
 * **4. NFT Staking and Reward Functions:**
 *    - `stakeNFT(uint256 tokenId)`: Allows NFT holders to stake their NFTs to earn rewards.
 *    - `unstakeNFT(uint256 tokenId)`: Allows NFT holders to unstake their NFTs.
 *    - `calculateStakingReward(uint256 tokenId)`: Calculates the staking reward for a given NFT.
 *    - `redeemStakingReward(uint256 tokenId)`: Allows NFT holders to redeem their accumulated staking rewards.
 *    - `getNFTStakingStatus(uint256 tokenId)`: Gets the staking status and accumulated reward for a given NFT.
 *
 * **5. Utility and Configuration Functions:**
 *    - `setBaseURIPrefix(string memory prefix)`: Sets the prefix for the base URI of NFTs.
 *    - `withdrawContractBalance()`: (Owner Only) Allows the contract owner to withdraw contract balance (ETH).
 *    - `pauseContract()`: (Owner Only) Pauses core contract functionalities.
 *    - `unpauseContract()`: (Owner Only) Resumes paused contract functionalities.
 *    - `isContractPaused()`: Returns whether the contract is currently paused.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol"; // Example Governance

contract DynamicEvolvingNFT is ERC721, IERC721Metadata, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string private _baseURIPrefix; // Prefix for token URIs

    // NFT Trait Storage
    struct NF traits {
        mapping(string => string) currentTraits;
    }
    mapping(uint256 => NFTTraits) private _nftTraits;

    // Evolution Proposal Struct
    struct EvolutionProposal {
        uint256 tokenId;
        string traitName;
        string traitValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
        uint256 proposalTimestamp;
    }
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    Counters.Counter private _evolutionProposalCounter;

    // Governance Proposal Struct (Basic Example)
    struct GovernanceProposal {
        string description;
        bytes proposalData; // Flexible data for proposal actions
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
        uint256 proposalTimestamp;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    Counters.Counter private _governanceProposalCounter;

    // Staking Data
    struct StakingData {
        uint256 stakeStartTime;
        uint256 lastRewardClaimTime;
        bool isStaked;
    }
    mapping(uint256 => StakingData) private _nftStakingData;
    uint256 public stakingRewardRatePerDay = 10; // Example reward rate (configurable via governance)

    // Configurable Parameters (Example, managed by DAO in real-world)
    mapping(string => uint256) public contractParameters;

    event NFTMinted(uint256 tokenId, address recipient);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTTraitEvolutionProposed(uint256 proposalId, uint256 tokenId, string traitName, string traitValue, address proposer);
    event NFTTraitEvolutionVoted(uint256 proposalId, address voter, bool vote);
    event NFTTraitEvolutionExecuted(uint256 proposalId, uint256 tokenId);
    event GovernanceProposalCreated(uint256 proposalId, string description, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId, uint256 proposalType); //proposalType could be encoded in proposalData
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, uint256 reward);
    event StakingRewardRedeemed(uint256 tokenId, uint256 reward);
    event ContractPaused();
    event ContractUnpaused();
    event BaseURIPrefixUpdated(string newPrefix);
    event ParameterSetByGovernance(string parameterName, uint256 parameterValue);
    event BalanceWithdrawn(uint256 amount, address recipient);

    constructor(string memory name, string memory symbol, string memory baseURIPrefix_) ERC721(name, symbol) {
        _baseURIPrefix = baseURIPrefix_;
        contractParameters["minStakeDurationDays"] = 7; // Example parameter
    }

    // ------------------------------------------------------------
    // 1. Core NFT Functions (ERC721-inspired)
    // ------------------------------------------------------------

    /**
     * @dev Mints a new Dynamic NFT to the specified address.
     * @param recipient The address to receive the NFT.
     * @param baseURI Initial base URI for the NFT.
     */
    function mintDynamicNFT(address recipient, string memory baseURI) public onlyOwner whenNotPaused {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(_baseURIPrefix, baseURI, "/", newTokenId.toString(), ".json"))); // Initial URI
        emit NFTMinted(newTokenId, recipient);
    }

    /**
     * @dev Transfers ownership of an NFT from the current owner to another address.
     * @param recipient The address to transfer the NFT to.
     * @param tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address recipient, uint256 tokenId) public whenNotPaused {
        safeTransferFrom(_msgSender(), recipient, tokenId);
        emit NFTTransferred(tokenId, _msgSender(), recipient);
    }

    /**
     * @dev Approves or disapproves an address to operate on a single NFT.
     * @param approved Address to be approved for the given NFT ID.
     * @param tokenId NFT ID to be approved.
     */
    function approveNFT(address approved, uint256 tokenId) public whenNotPaused {
        approve(approved, tokenId);
    }

    /**
     * @dev Gets the approved address for a single NFT ID.
     * @param tokenId NFT ID to find the approved address for.
     * @return The approved address for this NFT ID, or zero address if there is none.
     */
    function getApprovedNFT(uint256 tokenId) public view returns (address) {
        return getApproved(tokenId);
    }

    /**
     * @dev Approve or unapprove the operator to operate on all of sender's NFTs.
     * @param operator Address to add to the set of authorized operators.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAllNFT(address operator, bool approved) public whenNotPaused {
        setApprovalForAll(operator, approved);
    }

    /**
     * @dev Query if an address is an authorized operator for another address.
     * @param owner The address that owns the NFTs.
     * @param operator The address that acts on behalf of the owner.
     * @return True if `operator` is an approved operator for `owner`, false otherwise.
     */
    function isApprovedForAllNFT(address owner, address operator) public view returns (bool) {
        return isApprovedForAll(owner, operator);
    }

    /**
     * @dev Returns the URI for a given NFT token.
     * @param tokenId The token ID.
     * @return String representing the token URI.
     */
    function tokenURINFT(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Dynamically generate URI based on NFT traits
        string memory baseURI = _baseURIPrefix;
        string memory tokenIdStr = tokenId.toString();
        string memory traitsJson = _generateTraitsJSON(tokenId);
        string memory jsonContent = string(abi.encodePacked('{"name": "', name(), ' #', tokenIdStr, '", "description": "A Dynamic Evolving NFT.", "image": "', baseURI, 'images/', tokenIdStr, '.png", "attributes": ', traitsJson, '}')); // Example JSON structure

        return string(abi.encodePacked("data:application/json;base64,", vm.base64(bytes(jsonContent))));
    }

    /**
     * @dev Returns the total number of NFTs in existence.
     */
    function totalSupplyNFT() public view returns (uint256) {
        return totalSupply();
    }

    /**
     * @dev Returns the number of NFTs owned by `owner`.
     * @param owner Address to be checked.
     * @return Number of NFTs owned by `owner`.
     */
    function balanceOfNFT(address owner) public view returns (uint256) {
        return balanceOf(owner);
    }

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     * @param tokenId The ID of the NFT to query the owner of.
     * @return Address currently marked as the owner of the given NFT ID.
     */
    function ownerOfNFT(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId);
    }

    // ------------------------------------------------------------
    // 2. Dynamic NFT Evolution Functions
    // ------------------------------------------------------------

    /**
     * @dev Allows users to propose changes to an NFT's traits.
     * @param tokenId The ID of the NFT to propose trait evolution for.
     * @param traitName The name of the trait to evolve.
     * @param traitValue The new value for the trait.
     */
    function proposeTraitEvolution(uint256 tokenId, string memory traitName, string memory traitValue) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOfNFT(tokenId) == _msgSender(), "You are not the owner of this NFT");

        _evolutionProposalCounter.increment();
        uint256 proposalId = _evolutionProposalCounter.current();
        evolutionProposals[proposalId] = EvolutionProposal({
            tokenId: tokenId,
            traitName: traitName,
            traitValue: traitValue,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: _msgSender(),
            proposalTimestamp: block.timestamp
        });

        emit NFTTraitEvolutionProposed(proposalId, tokenId, traitName, traitValue, _msgSender());
    }

    /**
     * @dev Allows NFT holders to vote on trait evolution proposals.
     * @param proposalId The ID of the evolution proposal to vote on.
     * @param vote True for 'for', false for 'against'.
     */
    function voteOnEvolutionProposal(uint256 proposalId, bool vote) public whenNotPaused {
        require(evolutionProposals[proposalId].tokenId > 0, "Proposal does not exist"); // Simple check for proposal existence
        require(ownerOfNFT(evolutionProposals[proposalId].tokenId) == _msgSender(), "Only NFT owner can vote");
        require(!evolutionProposals[proposalId].executed, "Proposal already executed");

        if (vote) {
            evolutionProposals[proposalId].votesFor++;
        } else {
            evolutionProposals[proposalId].votesAgainst++;
        }
        emit NFTTraitEvolutionVoted(proposalId, _msgSender(), vote);
    }

    /**
     * @dev Executes a successful trait evolution proposal, updating the NFT's traits and URI.
     * @param proposalId The ID of the evolution proposal to execute.
     */
    function executeEvolutionProposal(uint256 proposalId) public whenNotPaused {
        require(evolutionProposals[proposalId].tokenId > 0, "Proposal does not exist");
        require(!evolutionProposals[proposalId].executed, "Proposal already executed");
        require(block.timestamp > evolutionProposals[proposalId].proposalTimestamp + 1 days, "Voting period not over"); // Example voting period

        uint256 totalVotes = evolutionProposals[proposalId].votesFor + evolutionProposals[proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast"); // Prevent division by zero
        uint256 quorumPercentage = (evolutionProposals[proposalId].votesFor * 100) / totalVotes;

        require(quorumPercentage > 60, "Proposal does not meet quorum (60%)"); // Example quorum

        uint256 tokenId = evolutionProposals[proposalId].tokenId;
        string memory traitName = evolutionProposals[proposalId].traitName;
        string memory traitValue = evolutionProposals[proposalId].traitValue;

        _nftTraits[tokenId].currentTraits[traitName] = traitValue;
        evolutionProposals[proposalId].executed = true;

        // Re-set token URI to reflect changes
        _setTokenURI(tokenId, tokenURINFT(tokenId)); // Re-generate URI
        emit NFTTraitEvolutionExecuted(proposalId, tokenId);
    }

    /**
     * @dev Retrieves the current traits of a given NFT.
     * @param tokenId The ID of the NFT.
     * @return A mapping of trait names to trait values.
     */
    function getNFTTraits(uint256 tokenId) public view returns (mapping(string => string) memory) {
        require(_exists(tokenId), "NFT does not exist");
        return _nftTraits[tokenId].currentTraits;
    }

    /**
     * @dev Retrieves details of a specific evolution proposal.
     * @param proposalId The ID of the evolution proposal.
     * @return EvolutionProposal struct containing proposal details.
     */
    function getEvolutionProposalDetails(uint256 proposalId) public view returns (EvolutionProposal memory) {
        return evolutionProposals[proposalId];
    }

    // ------------------------------------------------------------
    // 3. DAO Governance Functions (Basic Example)
    // ------------------------------------------------------------

    /**
     * @dev Allows DAO members to create general governance proposals.
     * @param description A description of the governance proposal.
     * @param proposalData Data associated with the proposal (e.g., function call data).
     */
    function createGovernanceProposal(string memory description, bytes memory proposalData) public whenNotPaused {
        // In a real DAO, membership/voting power would be more sophisticated
        require(balanceOfNFT(_msgSender()) > 0, "Only NFT holders can create proposals (DAO members)");

        _governanceProposalCounter.increment();
        uint256 proposalId = _governanceProposalCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            description: description,
            proposalData: proposalData,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: _msgSender(),
            proposalTimestamp: block.timestamp
        });
        emit GovernanceProposalCreated(proposalId, description, _msgSender());
    }

    /**
     * @dev Allows DAO members to vote on governance proposals.
     * @param proposalId The ID of the governance proposal to vote on.
     * @param vote True for 'for', false for 'against'.
     */
    function voteOnGovernanceProposal(uint256 proposalId, bool vote) public whenNotPaused {
        // In a real DAO, voting power would be weighted (e.g., based on NFT holdings, staking, etc.)
        require(governanceProposals[proposalId].proposer != address(0), "Proposal does not exist");
        require(balanceOfNFT(_msgSender()) > 0, "Only NFT holders can vote (DAO members)");
        require(!governanceProposals[proposalId].executed, "Proposal already executed");

        if (vote) {
            governanceProposals[proposalId].votesFor++;
        } else {
            governanceProposals[proposalId].votesAgainst++;
        }
        emit GovernanceProposalVoted(proposalId, _msgSender(), vote);
    }

    /**
     * @dev Executes a successful governance proposal.
     * @param proposalId The ID of the governance proposal to execute.
     */
    function executeGovernanceProposal(uint256 proposalId) public whenNotPaused onlyOwner { // Example: Only owner can execute after DAO approval, can be timelock or DAO controlled
        require(governanceProposals[proposalId].proposer != address(0), "Proposal does not exist");
        require(!governanceProposals[proposalId].executed, "Proposal already executed");
        require(block.timestamp > governanceProposals[proposalId].proposalTimestamp + 2 days, "Voting period not over"); // Example voting period

        uint256 totalVotes = governanceProposals[proposalId].votesFor + governanceProposals[proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast");
        uint256 quorumPercentage = (governanceProposals[proposalId].votesFor * 100) / totalVotes;

        require(quorumPercentage > 70, "Governance proposal does not meet quorum (70%)"); // Example higher quorum for governance

        // Execute proposal logic based on proposalData (Example: parameter change)
        // Decode proposalData and perform actions - This part needs to be designed based on what governance should control
        // For simplicity, let's assume proposalData encodes parameter name and new value
        (string memory parameterName, uint256 parameterValue) = abi.decode(governanceProposals[proposalId].proposalData, (string, uint256));
        if (bytes(parameterName).length > 0) {
            contractParameters[parameterName] = parameterValue;
            emit ParameterSetByGovernance(parameterName, parameterValue);
        }

        governanceProposals[proposalId].executed = true;
        emit GovernanceProposalExecuted(proposalId, 1); // Example proposal type
    }

    /**
     * @dev Retrieves a configurable contract parameter.
     * @param parameterName The name of the parameter to retrieve.
     * @return The value of the parameter.
     */
    function getParameter(string memory parameterName) public view returns (uint256) {
        return contractParameters[parameterName];
    }

    /**
     * @dev (Governance controlled) Sets a configurable contract parameter through governance.
     * This function is intended to be called as part of a successful governance proposal execution.
     * @param parameterName The name of the parameter to set.
     * @param parameterValue The new value for the parameter.
     *
     * Note: In a real DAO, parameter setting would be handled within `executeGovernanceProposal`
     * based on decoding `proposalData`. This function is illustrative and could be removed.
     */
    function setParameter(string memory parameterName, uint256 parameterValue) public onlyOwner { // Example: Only owner can execute governance actions
        contractParameters[parameterName] = parameterValue;
        emit ParameterSetByGovernance(parameterName, parameterValue);
    }


    // ------------------------------------------------------------
    // 4. NFT Staking and Reward Functions
    // ------------------------------------------------------------

    /**
     * @dev Allows NFT holders to stake their NFTs to earn rewards.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOfNFT(tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(!_nftStakingData[tokenId].isStaked, "NFT already staked");
        require(getApproved(tokenId) == address(0) && !isApprovedForAll(ownerOfNFT(tokenId), address(this)), "NFT is approved for transfer, unstake and revoke approvals first."); // Security: Prevent staking approved NFTs

        _nftStakingData[tokenId] = StakingData({
            stakeStartTime: block.timestamp,
            lastRewardClaimTime: block.timestamp,
            isStaked: true
        });

        // Transfer NFT to contract for staking - optional depending on design
        // safeTransferFrom(_msgSender(), address(this), tokenId);

        emit NFTStaked(tokenId, _msgSender());
    }

    /**
     * @dev Allows NFT holders to unstake their NFTs and claim rewards.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 tokenId) public whenNotPaused {
        require(_nftStakingData[tokenId].isStaked, "NFT is not staked");
        require(ownerOfNFT(tokenId) == _msgSender(), "You are not the owner of this NFT");

        uint256 reward = calculateStakingReward(tokenId);
        _nftStakingData[tokenId].isStaked = false;

        // Transfer NFT back to owner if staked NFT was transferred to contract on stake - optional
        // _safeTransfer(address(this), _msgSender(), tokenId, "");

        // Transfer reward to staker (Example - simplified, assumes contract has ETH to reward)
        payable(_msgSender()).transfer(reward); // Simplified reward in ETH for example
        emit NFTUnstaked(tokenId, reward);
    }

    /**
     * @dev Calculates the staking reward for a given NFT.
     * @param tokenId The ID of the NFT.
     * @return The calculated staking reward (in Wei, for example).
     */
    function calculateStakingReward(uint256 tokenId) public view returns (uint256) {
        require(_nftStakingData[tokenId].isStaked, "NFT is not staked");

        uint256 stakeDurationDays = (block.timestamp - _nftStakingData[tokenId].stakeStartTime) / 1 days;
        uint256 minStakeDays = contractParameters["minStakeDurationDays"];
        if (stakeDurationDays < minStakeDays) {
            return 0; // No reward for staking less than minimum duration
        }

        uint256 daysSinceLastClaim = (block.timestamp - _nftStakingData[tokenId].lastRewardClaimTime) / 1 days;
        uint256 reward = daysSinceLastClaim * stakingRewardRatePerDay; // Example reward calculation

        return reward;
    }

    /**
     * @dev Allows NFT holders to redeem their accumulated staking rewards.
     * @param tokenId The ID of the NFT to redeem rewards for.
     */
    function redeemStakingReward(uint256 tokenId) public whenNotPaused {
        require(_nftStakingData[tokenId].isStaked, "NFT is not staked");
        require(ownerOfNFT(tokenId) == _msgSender(), "You are not the owner of this NFT");

        uint256 reward = calculateStakingReward(tokenId);
        require(reward > 0, "No reward to redeem");

        _nftStakingData[tokenId].lastRewardClaimTime = block.timestamp;

        // Transfer reward to staker (Example - simplified, assumes contract has ETH to reward)
        payable(_msgSender()).transfer(reward); // Simplified reward in ETH for example

        emit StakingRewardRedeemed(tokenId, reward);
    }

    /**
     * @dev Gets the staking status and accumulated reward for a given NFT.
     * @param tokenId The ID of the NFT.
     * @return isStaked: Whether the NFT is currently staked.
     *         reward: The accumulated staking reward (not yet redeemed).
     */
    function getNFTStakingStatus(uint256 tokenId) public view returns (bool isStaked, uint256 reward) {
        isStaked = _nftStakingData[tokenId].isStaked;
        reward = calculateStakingReward(tokenId); // Calculate current reward on query
        return (isStaked, reward);
    }

    // ------------------------------------------------------------
    // 5. Utility and Configuration Functions
    // ------------------------------------------------------------

    /**
     * @dev Sets the prefix for the base URI of NFTs.
     * @param prefix The new base URI prefix.
     */
    function setBaseURIPrefix(string memory prefix) public onlyOwner {
        _baseURIPrefix = prefix;
        emit BaseURIPrefixUpdated(prefix);
    }

    /**
     * @dev Allows the contract owner to withdraw contract balance (ETH).
     */
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit BalanceWithdrawn(balance, owner());
    }

    /**
     * @dev Pauses core contract functionalities.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Resumes paused contract functionalities.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Returns whether the contract is currently paused.
     * @return True if the contract is paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return paused();
    }

    // ------------------------------------------------------------
    // Internal Helper Functions
    // ------------------------------------------------------------

    /**
     * @dev Generates a JSON string representing the NFT's traits.
     * @param tokenId The ID of the NFT.
     * @return JSON string of traits.
     */
    function _generateTraitsJSON(uint256 tokenId) internal view returns (string memory) {
        string memory traitsJson = "[";
        bool firstTrait = true;
        mapping(string => string) memory currentTraits = _nftTraits[tokenId].currentTraits;

        string[] memory traitNames = new string[](10); // Example max traits, adjust as needed
        uint traitCount = 0;
        for (uint i = 0; i < traitNames.length; i++) { // Solidity limitations, iterating over mapping is not directly possible
            if(traitCount >= traitNames.length) break; // Safety break
            if (bytes(traitNames[traitCount]).length > 0 ) { // Example - replace with actual trait names dynamically if possible or pre-defined trait list
                string memory traitName = traitNames[traitCount];
                if (bytes(currentTraits[traitName]).length > 0) {
                    if (!firstTrait) {
                        traitsJson = string(abi.encodePacked(traitsJson, ","));
                    }
                    traitsJson = string(abi.encodePacked(traitsJson, '{"trait_type": "', traitName, '", "value": "', currentTraits[traitName], '"}'));
                    firstTrait = false;
                }
                traitCount++;
            } else {
                break; // Stop when no more trait names are in the example array.
            }
        }
        traitsJson = string(abi.encodePacked(traitsJson, "]"));
        return traitsJson;
    }

    // Override _beforeTokenTransfer to add custom checks if needed for transfers in the future
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!_nftStakingData[tokenId].isStaked, "Cannot transfer staked NFT. Unstake first.");
    }

    // Override _setTokenURI to emit an event when URI is updated.
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
        super._setTokenURI(tokenId, _tokenURI);
        //emit TokenURIUpdated(tokenId, _tokenURI); // Optional: Add event if needed.
    }

    receive() external payable {} // Allow contract to receive ETH for staking rewards example
}
```