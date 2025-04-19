```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
 * ----------------------------------------------------------------------------
 *                      Dynamic Trait NFT with Community Curation & Evolution
 * ----------------------------------------------------------------------------
 *
 * Contract Outline:
 * This contract implements a Dynamic Trait NFT, where NFTs have evolvable traits that can be influenced by the community.
 * It features a multi-stage evolution system, community-driven trait proposals, dynamic rarity,
 * staking for governance participation, trait fusion mechanics, and decentralized lore building.
 *
 * Function Summary:
 *
 * 1.  `mintNFT(address recipient, string memory baseURI)`: Mints a new Dynamic Trait NFT to the specified recipient with an initial base URI.
 * 2.  `setBaseURI(string memory _baseURI)`: Sets the base URI for retrieving NFT metadata (Admin only).
 * 3.  `tokenURI(uint256 tokenId)`: Returns the URI for the metadata of a specific NFT.
 * 4.  `getNFTTraits(uint256 tokenId)`: Retrieves the current traits of an NFT.
 * 5.  `proposeTraitChange(uint256 tokenId, string memory traitName, string memory newValue)`: Allows users to propose a change to a specific trait of an NFT.
 * 6.  `voteOnTraitProposal(uint256 proposalId, bool vote)`: Allows users to vote on a trait change proposal.
 * 7.  `executeTraitProposal(uint256 proposalId)`: Executes a trait change proposal if it passes the voting threshold (Governance/Curator role).
 * 8.  `stakeForGovernance(uint256 tokenId)`: Allows NFT holders to stake their NFTs for governance participation.
 * 9.  `unstakeFromGovernance(uint256 tokenId)`: Allows NFT holders to unstake their NFTs from governance.
 * 10. `getGovernancePower(address staker)`: Returns the governance power of a staker (based on staked NFTs).
 * 11. `startEvolutionStage(string memory stageName, uint256 durationInBlocks)`: Starts a new evolution stage for NFTs (Governance/Curator role).
 * 12. `getCurrentEvolutionStage()`: Returns the name of the current evolution stage.
 * 13. `evolveNFT(uint256 tokenId)`: Allows an NFT to evolve to the next stage if it meets certain criteria (e.g., time elapsed, community votes).
 * 14. `fuseNFTs(uint256 tokenId1, uint256 tokenId2)`: Allows users to fuse two NFTs to create a new, potentially rarer NFT (Burn mechanism involved).
 * 15. `setTraitRarity(string memory traitName, uint256 rarityScore)`: Sets the rarity score for a specific trait (Governance/Curator role).
 * 16. `getTraitRarity(string memory traitName)`: Retrieves the rarity score of a trait.
 * 17. `contributeToLore(uint256 tokenId, string memory loreText)`: Allows users to contribute to the decentralized lore of an NFT.
 * 18. `getNFTLore(uint256 tokenId)`: Retrieves the lore associated with an NFT.
 * 19. `pauseContract()`: Pauses the contract, preventing most state-changing functions (Admin only).
 * 20. `unpauseContract()`: Unpauses the contract, restoring normal functionality (Admin only).
 * 21. `withdrawStuckETH()`: Allows the contract owner to withdraw any accidentally sent ETH to the contract (Admin only).
 * 22. `setCuratorRole(address curatorAddress, bool isCurator)`: Assign or revoke Curator role to an address (Admin only).
 * 23. `isCurator(address account)`: Checks if an address has the Curator role.
 *
 */

contract DynamicTraitNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    // Mapping from tokenId to NFT traits (traitName => traitValue)
    mapping(uint256 => mapping(string => string)) public nftTraits;

    // Mapping from tokenId to NFT lore (decentralized story)
    mapping(uint256 => string) public nftLore;

    // Struct to represent a trait change proposal
    struct TraitProposal {
        uint256 tokenId;
        string traitName;
        string newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        address proposer;
        uint256 proposalTimestamp;
    }

    mapping(uint256 => TraitProposal) public traitProposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public proposalVoteDuration = 7 days; // Default vote duration

    // Mapping from tokenId to staking status (true if staked for governance)
    mapping(uint256 => bool) public isStakedForGovernance;

    // Mapping from staker address to total governance power
    mapping(address => uint256) public governancePower;

    // Evolution Stages
    string public currentEvolutionStage = "Stage 0: Genesis";
    string[] public evolutionStages;
    uint256 public evolutionStageDuration = 30 days; // Default evolution stage duration
    uint256 public evolutionStageStartTime;

    // Trait Rarity Scores (traitName => rarityScore) - Higher score means rarer
    mapping(string => uint256) public traitRarityScores;

    // Curator Role - Can execute proposals, manage evolution stages, etc.
    mapping(address => bool) public isCuratorRole;

    bool public paused = false;

    event NFTMinted(uint256 tokenId, address recipient);
    event TraitProposed(uint256 proposalId, uint256 tokenId, string traitName, string newValue, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event TraitProposalExecuted(uint256 proposalId, uint256 tokenId, string traitName, string newValue);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event EvolutionStageStarted(string stageName);
    event NFTEvolved(uint256 tokenId, string newStage);
    event NFTsFused(uint256 newTokenId, uint256 tokenId1, uint256 tokenId2, address fuser);
    event LoreContributed(uint256 tokenId, address contributor);
    event ContractPaused();
    event ContractUnpaused();
    event CuratorRoleSet(address curatorAddress, bool isCurator);


    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        evolutionStages.push("Stage 0: Genesis"); // Initial stage
        evolutionStageStartTime = block.timestamp;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Owner is also admin
        isCuratorRole[owner()] = true; // Owner is also curator by default
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyCurator() {
        require(isCuratorRole[_msgSender()], "Caller is not a curator");
        _;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function mintNFT(address recipient, string memory initialBaseURI) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(recipient, newTokenId);

        // Initialize default traits for new NFTs (Example - can be extended)
        nftTraits[newTokenId]["Background"] = "Default";
        nftTraits[newTokenId]["Type"] = "Genesis";
        nftTraits[newTokenId]["Element"] = "Neutral";

        emit NFTMinted(newTokenId, recipient);
    }

    function getNFTTraits(uint256 tokenId) public view returns (mapping(string => string) memory) {
        require(_exists(tokenId), "NFT does not exist");
        return nftTraits[tokenId];
    }

    function proposeTraitChange(uint256 tokenId, string memory traitName, string memory newValue) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(bytes(traitName).length > 0 && bytes(newValue).length > 0, "Trait name and new value cannot be empty");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        traitProposals[proposalId] = TraitProposal({
            tokenId: tokenId,
            traitName: traitName,
            newValue: newValue,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            proposer: _msgSender(),
            proposalTimestamp: block.timestamp
        });

        emit TraitProposed(proposalId, tokenId, traitName, newValue, _msgSender());
    }

    function voteOnTraitProposal(uint256 proposalId, bool vote) public whenNotPaused {
        require(traitProposals[proposalId].isActive, "Proposal is not active");
        require(block.timestamp < traitProposals[proposalId].proposalTimestamp + proposalVoteDuration, "Voting period ended");

        uint256 voterGovernancePower = getGovernancePower(_msgSender());
        require(voterGovernancePower > 0, "Voter has no governance power"); // Need staked NFT to vote

        // To prevent double voting, you could implement a mapping to track voters per proposal,
        // but for simplicity in this example, we'll skip it (in real scenario, prevent double voting).

        if (vote) {
            traitProposals[proposalId].votesFor += voterGovernancePower;
        } else {
            traitProposals[proposalId].votesAgainst += voterGovernancePower;
        }
        emit VoteCast(proposalId, _msgSender(), vote);
    }

    function executeTraitProposal(uint256 proposalId) public onlyCurator whenNotPaused {
        require(traitProposals[proposalId].isActive, "Proposal is not active");
        require(block.timestamp >= traitProposals[proposalId].proposalTimestamp + proposalVoteDuration, "Voting period not ended");

        uint256 totalGovernancePower = totalSupply(); // Example: Simple total supply as total power, can be more sophisticated
        uint256 quorum = totalGovernancePower / 2; // Simple 50% quorum for example, can be configurable

        if (traitProposals[proposalId].votesFor > quorum && traitProposals[proposalId].votesFor > traitProposals[proposalId].votesAgainst) {
            nftTraits[traitProposals[proposalId].tokenId][traitProposals[proposalId].traitName] = traitProposals[proposalId].newValue;
            traitProposals[proposalId].isActive = false; // Mark proposal as executed
            emit TraitProposalExecuted(proposalId, traitProposals[proposalId].tokenId, traitProposals[proposalId].traitName, traitProposals[proposalId].newValue);
        } else {
            traitProposals[proposalId].isActive = false; // Mark proposal as failed
            // Optionally emit an event for failed proposal
        }
    }

    function stakeForGovernance(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not NFT owner");
        require(!isStakedForGovernance[tokenId], "NFT already staked");

        isStakedForGovernance[tokenId] = true;
        governancePower[_msgSender()]++; // Simple: 1 NFT = 1 governance power. Can be weighted.
        emit NFTStaked(tokenId, _msgSender());
    }

    function unstakeFromGovernance(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not NFT owner");
        require(isStakedForGovernance[tokenId], "NFT not staked");

        isStakedForGovernance[tokenId] = false;
        governancePower[_msgSender()]--;
        emit NFTUnstaked(tokenId, _msgSender());
    }

    function getGovernancePower(address staker) public view returns (uint256) {
        return governancePower[staker];
    }

    function startEvolutionStage(string memory stageName, uint256 durationInBlocks) public onlyCurator whenNotPaused {
        require(bytes(stageName).length > 0, "Stage name cannot be empty");
        evolutionStages.push(stageName);
        currentEvolutionStage = stageName;
        evolutionStageDuration = durationInBlocks;
        evolutionStageStartTime = block.timestamp;
        emit EvolutionStageStarted(stageName);
    }

    function getCurrentEvolutionStage() public view returns (string memory) {
        return currentEvolutionStage;
    }

    function evolveNFT(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not NFT owner");
        require(block.timestamp >= evolutionStageStartTime + evolutionStageDuration, "Evolution stage not yet active");

        uint256 currentStageIndex = evolutionStages.length - 1; // Last stage is current
        if (currentStageIndex < evolutionStages.length - 1) { // Check if there is a next stage (for example purposes, not strictly necessary here)
            string memory nextStageName = evolutionStages[currentStageIndex + 1];
            nftTraits[tokenId]["Stage"] = nextStageName; // Example: Add "Stage" trait or modify existing traits based on evolution
            currentEvolutionStage = nextStageName; // Update current stage - in real scenario, stage evolution might be more controlled
            emit NFTEvolved(tokenId, nextStageName);
        } else {
            // Optionally handle case where NFTs are already at the final stage
        }
    }

    function fuseNFTs(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        require(_exists(tokenId1) && _exists(tokenId2), "One or both NFTs do not exist");
        require(ownerOf(tokenId1) == _msgSender() && ownerOf(tokenId2) == _msgSender(), "Not owner of both NFTs");
        require(tokenId1 != tokenId2, "Cannot fuse the same NFT with itself");

        // Example Fusion Logic (can be highly customized):
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), newTokenId);

        // Inherit traits - Example: Mix traits from both NFTs, or have specific fusion rules
        nftTraits[newTokenId]["Background"] = (block.timestamp % 2 == 0) ? nftTraits[tokenId1]["Background"] : nftTraits[tokenId2]["Background"]; // Example: Random inheritance
        nftTraits[newTokenId]["Type"] = "Fused";
        nftTraits[newTokenId]["Element"] = "Hybrid";

        // Burn the fused NFTs
        _burn(tokenId1);
        _burn(tokenId2);

        emit NFTsFused(newTokenId, tokenId1, tokenId2, _msgSender());
        emit NFTMinted(newTokenId, _msgSender()); // Optional: Emit mint event for fused NFT
    }

    function setTraitRarity(string memory traitName, uint256 rarityScore) public onlyCurator whenNotPaused {
        traitRarityScores[traitName] = rarityScore;
    }

    function getTraitRarity(string memory traitName) public view returns (uint256) {
        return traitRarityScores[traitName];
    }

    function contributeToLore(uint256 tokenId, string memory loreText) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(bytes(loreText).length > 0 && bytes(loreText).length <= 500, "Lore text must be between 1 and 500 characters"); // Example limit

        nftLore[tokenId] = string(abi.encodePacked(nftLore[tokenId], "\n", _msgSender().toString(), ": ", loreText)); // Append lore with contributor address (simple example)
        emit LoreContributed(tokenId, _msgSender());
    }

    function getNFTLore(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "NFT does not exist");
        return nftLore[tokenId];
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function withdrawStuckETH() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    function setCuratorRole(address curatorAddress, bool isCurator) public onlyOwner {
        isCuratorRole[curatorAddress] = isCurator;
        emit CuratorRoleSet(curatorAddress, isCurator);
    }

    function isCurator(address account) public view returns (bool) {
        return isCuratorRole[account];
    }

    // Optional:  Additional functions could include:
    // - Setting proposal vote duration
    // - Setting evolution stage duration
    // - More complex trait evolution logic
    // - NFT gifting/transfer restrictions based on staking
    // - Marketplace integration helpers
    // - Dynamic metadata generation logic based on traits and stage
}
```