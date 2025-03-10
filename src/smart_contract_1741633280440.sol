```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Art Collection - Smart Contract
 * @author Gemini AI (Example - Adaptable and Creative)
 * @dev This contract implements a decentralized dynamic art collection where artworks can evolve based on community interaction,
 *      external events (simulated in this example for simplicity), and artist-defined parameters.
 *      It features dynamic traits, community-driven evolution, artist collaborations, and innovative NFT functionalities.
 *
 * **Outline:**
 * 1. **Art Creation and Management:**
 *    - `createArtwork`: Allows artists to create new artworks with initial traits and evolution rules.
 *    - `setArtworkMetadataURI`: Allows artists to set/update the metadata URI for an artwork.
 *    - `getArtworkDetails`: Retrieves detailed information about a specific artwork.
 *    - `getArtworkTrait`: Retrieves a specific trait value of an artwork.
 *    - `setArtistForArtwork`: Allows the contract owner to assign an artist role to an address for specific artworks.
 *    - `removeArtistForArtwork`: Allows the contract owner to remove an artist role from an address for specific artworks.
 *    - `isArtistForArtwork`: Checks if an address is an artist for a specific artwork.
 *
 * 2. **NFT Minting and Ownership:**
 *    - `mintNFT`: Mints an NFT representing an artwork to a user.
 *    - `transferNFT`: Standard NFT transfer function (ERC721).
 *    - `ownerOf`:  Standard ERC721 ownerOf function.
 *    - `tokenURI`: Standard ERC721 tokenURI function (points to artwork metadata).
 *    - `approve`: Standard ERC721 approve function.
 *    - `getApproved`: Standard ERC721 getApproved function.
 *    - `setApprovalForAll`: Standard ERC721 setApprovalForAll function.
 *    - `isApprovedForAll`: Standard ERC721 isApprovedForAll function.
 *
 * 3. **Dynamic Traits and Evolution:**
 *    - `evolveArtworkTrait`: Allows the contract owner (or designated governance mechanism in a real-world scenario)
 *                         to trigger the evolution of a specific artwork trait based on predefined rules or external factors.
 *    - `setEvolutionRule`: Allows artists to define/update the evolution rule for a specific trait of their artwork.
 *    - `getEvolutionRule`: Retrieves the evolution rule for a specific trait of an artwork.
 *
 * 4. **Community Interaction and Influence (Simulated):**
 *    - `voteForTraitEvolution`: Allows community members to vote on potential trait evolutions (simulated influence).
 *    - `submitCommunityProposal`: Allows community members to submit proposals that might influence artwork evolution (simulated).
 *    - `getProposalDetails`: Retrieves details of a community proposal.
 *    - `voteOnProposal`: Allows community members to vote on community proposals.
 *    - `executeCommunityProposal`: Allows the contract owner (or governance) to execute approved community proposals (simulated effect).
 *
 * 5. **Utility and Information:**
 *    - `supportsInterface`: Standard ERC165 interface support.
 *    - `totalSupply`: Standard ERC721 totalSupply function.
 *    - `balanceOf`: Standard ERC721 balanceOf function.
 *    - `name`: Returns the name of the NFT collection.
 *    - `symbol`: Returns the symbol of the NFT collection.
 *    - `pauseContract`: Allows the contract owner to pause core functionalities.
 *    - `unpauseContract`: Allows the contract owner to unpause core functionalities.
 *    - `withdrawFunds`: Allows the contract owner to withdraw contract balance.
 *
 * **Function Summary:**
 * - **Art Creation & Management:** `createArtwork`, `setArtworkMetadataURI`, `getArtworkDetails`, `getArtworkTrait`, `setArtistForArtwork`, `removeArtistForArtwork`, `isArtistForArtwork`
 * - **NFT Minting & Ownership:** `mintNFT`, `transferNFT`, `ownerOf`, `tokenURI`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `totalSupply`, `balanceOf`, `name`, `symbol`
 * - **Dynamic Traits & Evolution:** `evolveArtworkTrait`, `setEvolutionRule`, `getEvolutionRule`
 * - **Community Interaction (Simulated):** `voteForTraitEvolution`, `submitCommunityProposal`, `getProposalDetails`, `voteOnProposal`, `executeCommunityProposal`
 * - **Utility & Information:** `supportsInterface`, `pauseContract`, `unpauseContract`, `withdrawFunds`
 */
contract DynamicArtCollection {
    // --- State Variables ---

    string public name = "Decentralized Dynamic Art Collection";
    string public symbol = "DDAC";

    uint256 public artworkCount;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => string) public artworkMetadataURIs;
    mapping(uint256 => mapping(string => string)) public artworkTraits; // Artwork ID -> Trait Name -> Trait Value
    mapping(uint256 => mapping(string => EvolutionRule)) public artworkEvolutionRules; // Artwork ID -> Trait Name -> Evolution Rule
    mapping(uint256 => address) public nftOwnerOf; // Token ID -> Owner Address
    mapping(uint256 => address) public nftApproved; // Token ID -> Approved Address
    mapping(address => mapping(address => bool)) public nftApprovalForAll; // Owner -> Operator -> Approved
    mapping(uint256 => address) public artworkArtists; // Artwork ID -> Artist Address (Creator Role)

    uint256 public proposalCount;
    mapping(uint256 => CommunityProposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Proposal ID -> Voter Address -> Voted

    address public owner;
    bool public paused;

    // --- Structs ---

    struct Artwork {
        uint256 id;
        string name;
        string description;
        address creator;
        uint256 creationTimestamp;
    }

    struct EvolutionRule {
        string description;
        // In a real-world scenario, this could be more complex logic, e.g., function pointers, external contract calls, etc.
        // For simplicity, we'll just use a string description and manual evolution in `evolveArtworkTrait`.
        string ruleDetails;
    }

    struct CommunityProposal {
        uint256 id;
        string title;
        string description;
        uint256 artworkId;
        string traitName;
        string proposedNewValue;
        address proposer;
        uint256 voteCount;
        uint256 creationTimestamp;
        bool executed;
    }

    // --- Events ---

    event ArtworkCreated(uint256 artworkId, string name, address creator);
    event ArtworkMetadataUpdated(uint256 artworkId, string metadataURI);
    event NFTMinted(uint256 tokenId, uint256 artworkId, address owner);
    event TraitEvolved(uint256 artworkId, string traitName, string newValue, string evolutionReason);
    event EvolutionRuleSet(uint256 artworkId, string traitName, string ruleDescription);
    event CommunityProposalSubmitted(uint256 proposalId, uint256 artworkId, string traitName, string proposedNewValue, address proposer);
    event CommunityProposalVoted(uint256 proposalId, address voter);
    event CommunityProposalExecuted(uint256 proposalId);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event FundsWithdrawn(address withdrawer, uint256 amount);
    event ArtistAssignedToArtwork(uint256 artworkId, address artist);
    event ArtistRemovedFromArtwork(uint256 artworkId, address artist);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyArtist(uint256 _artworkId) {
        require(isArtistForArtwork(msg.sender, _artworkId), "Only artist for this artwork can call this function.");
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


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        paused = false;
        artworkCount = 0;
        proposalCount = 0;
    }

    // --- 1. Art Creation and Management ---

    /**
     * @dev Creates a new artwork. Only contract owner can initially create artworks (can be adjusted for artist self-creation).
     * @param _name The name of the artwork.
     * @param _description The description of the artwork.
     * @param _initialTraits JSON string representing initial traits (e.g., '{"color": "blue", "style": "abstract"}').
     * @param _metadataURI URI pointing to the artwork's metadata.
     */
    function createArtwork(
        string memory _name,
        string memory _description,
        string memory _initialTraits,
        string memory _metadataURI,
        address _artist
    ) external onlyOwner whenNotPaused {
        artworkCount++;
        uint256 artworkId = artworkCount;

        artworks[artworkId] = Artwork({
            id: artworkId,
            name: _name,
            description: _description,
            creator: msg.sender,
            creationTimestamp: block.timestamp
        });
        artworkMetadataURIs[artworkId] = _metadataURI;
        artworkArtists[artworkId] = _artist; // Assign initial artist role

        // Parse initial traits (basic JSON parsing - could be improved with libraries in real-world)
        string memory traits = _initialTraits;
        string memory key;
        string memory value;
        bool readingKey = true;
        for (uint256 i = 0; i < bytes(traits).length; i++) {
            bytes1 char = bytes(traits)[i];
            if (char == bytes1('{') || char == bytes1('}')) continue; // Skip brackets
            if (char == bytes1('"')) {
                if (readingKey && key.length() == 0) { readingKey = true; } // Start Key
                else if (readingKey) { readingKey = false; }  // End Key, Start Value
                else if (value.length() == 0) { readingKey = false; } // Start Value
                else { // End Value
                    readingKey = true;
                    artworkTraits[artworkId][key] = value;
                    key = "";
                    value = "";
                }
            } else if (char == bytes1(':')) {
                continue; // Skip colon
            } else if (char == bytes1(',')) {
                continue; // Skip comma
            } else if (readingKey) {
                key = string(abi.encodePacked(key, char));
            } else {
                value = string(abi.encodePacked(value, char));
            }
        }


        emit ArtworkCreated(artworkId, _name, msg.sender);
        emit ArtworkMetadataUpdated(artworkId, _metadataURI);
        emit ArtistAssignedToArtwork(artworkId, _artist);
    }

    /**
     * @dev Sets or updates the metadata URI for a specific artwork.
     * @param _artworkId The ID of the artwork.
     * @param _metadataURI The new metadata URI.
     */
    function setArtworkMetadataURI(uint256 _artworkId, string memory _metadataURI) external onlyArtist(_artworkId) whenNotPaused {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        artworkMetadataURIs[_artworkId] = _metadataURI;
        emit ArtworkMetadataUpdated(_artworkId, _metadataURI);
    }

    /**
     * @dev Retrieves detailed information about a specific artwork.
     * @param _artworkId The ID of the artwork.
     * @return Artwork struct containing artwork details.
     */
    function getArtworkDetails(uint256 _artworkId) external view returns (Artwork memory) {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        return artworks[_artworkId];
    }

    /**
     * @dev Retrieves a specific trait value of an artwork.
     * @param _artworkId The ID of the artwork.
     * @param _traitName The name of the trait.
     * @return The trait value (string).
     */
    function getArtworkTrait(uint256 _artworkId, string memory _traitName) external view returns (string memory) {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        return artworkTraits[_artworkId][_traitName];
    }

    /**
     * @dev Sets an address as an artist for a specific artwork. Only contract owner can do this.
     * @param _artworkId The ID of the artwork.
     * @param _artistAddress The address to be set as artist.
     */
    function setArtistForArtwork(uint256 _artworkId, address _artistAddress) external onlyOwner whenNotPaused {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        artworkArtists[_artworkId] = _artistAddress;
        emit ArtistAssignedToArtwork(_artworkId, _artistAddress);
    }

    /**
     * @dev Removes the artist role for an address from a specific artwork. Only contract owner can do this.
     * @param _artworkId The ID of the artwork.
     * @param _artistAddress The address to remove artist role from.
     */
    function removeArtistForArtwork(uint256 _artworkId, address _artistAddress) external onlyOwner whenNotPaused {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        require(artworkArtists[_artworkId] == _artistAddress, "Address is not the artist for this artwork.");
        delete artworkArtists[_artworkId]; // Removing the artist effectively means no artist is assigned anymore.
        emit ArtistRemovedFromArtwork(_artworkId, _artistAddress);
    }

    /**
     * @dev Checks if an address is designated as an artist for a specific artwork.
     * @param _artistAddress The address to check.
     * @param _artworkId The ID of the artwork.
     * @return True if the address is an artist, false otherwise.
     */
    function isArtistForArtwork(address _artistAddress, uint256 _artworkId) public view returns (bool) {
        return artworkArtists[_artworkId] == _artistAddress;
    }


    // --- 2. NFT Minting and Ownership (ERC721-like) ---

    /**
     * @dev Mints an NFT representing a specific artwork. Only artists for the artwork can mint NFTs.
     * @param _artworkId The ID of the artwork to mint as NFT.
     * @param _recipient The address to receive the minted NFT.
     */
    function mintNFT(uint256 _artworkId, address _recipient) external onlyArtist(_artworkId) whenNotPaused {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        uint256 tokenId = _artworkId; // Token ID is same as Artwork ID for simplicity
        require(nftOwnerOf[tokenId] == address(0), "NFT already minted for this artwork."); // Prevent double minting

        nftOwnerOf[tokenId] = _recipient;
        emit NFTMinted(tokenId, _artworkId, _recipient);
    }

    /**
     * @dev Transfers ownership of an NFT (ERC721 transferFrom implementation).
     * @param _from The current owner of the NFT.
     * @param _to The new owner of the NFT.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_from == ownerOf(_tokenId), "Incorrect 'from' address.");
        require(_to != address(0), "Transfer to zero address.");
        require(_from == msg.sender || nftApproved[_tokenId] == msg.sender || nftApprovalForAll[_from][msg.sender], "Not authorized to transfer.");

        _clearApproval(_tokenId);
        nftOwnerOf[_tokenId] = _to;

        // Optional: Emit a Transfer event (standard ERC721 practice)
        // emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Returns the owner of the NFT. (ERC721 ownerOf implementation).
     * @param _tokenId The ID of the NFT.
     * @return The owner address.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(nftOwnerOf[_tokenId] != address(0), "NFT does not exist.");
        return nftOwnerOf[_tokenId];
    }

    /**
     * @dev Returns the URI for the NFT metadata (points to artwork metadata). (ERC721 tokenURI implementation).
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(artworks[_tokenId].id != 0, "Artwork does not exist.");
        return artworkMetadataURIs[_tokenId];
    }

    /**
     * @dev Approve an address to spend/transfer a specific NFT (ERC721 approve implementation).
     * @param _approved The address being approved.
     * @param _tokenId The ID of the NFT being approved for.
     */
    function approve(address _approved, uint256 _tokenId) public whenNotPaused {
        address tokenOwner = ownerOf(_tokenId);
        require(msg.sender == tokenOwner || nftApprovalForAll[tokenOwner][msg.sender], "Not owner or approved for all.");
        nftApproved[_tokenId] = _approved;
        // Optional: Emit an Approval event (standard ERC721 practice)
        // emit Approval(tokenOwner, _approved, _tokenId);
    }

    /**
     * @dev Get the approved address for a specific NFT (ERC721 getApproved implementation).
     * @param _tokenId The ID of the NFT.
     * @return The approved address.
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        require(nftOwnerOf[_tokenId] != address(0), "NFT does not exist.");
        return nftApproved[_tokenId];
    }

    /**
     * @dev Set approval for all NFTs for an operator (ERC721 setApprovalForAll implementation).
     * @param _operator The address to approve as operator.
     * @param _approved Boolean value indicating approval (true) or revocation (false).
     */
    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        nftApprovalForAll[msg.sender][_operator] = _approved;
        // Optional: Emit an ApprovalForAll event (standard ERC721 practice)
        // emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Check if an operator is approved for all NFTs of an owner (ERC721 isApprovedForAll implementation).
     * @param _owner The owner of the NFTs.
     * @param _operator The operator address.
     * @return True if the operator is approved for all, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return nftApprovalForAll[_owner][_operator];
    }

    /**
     * @dev Returns the total number of NFTs minted (ERC721 totalSupply implementation - in this case, artwork count).
     * @return The total supply of NFTs.
     */
    function totalSupply() public view returns (uint256) {
        return artworkCount;
    }

    /**
     * @dev Returns the balance of NFTs owned by an address (ERC721 balanceOf implementation).
     * @param _owner The address to check the balance for.
     * @return The number of NFTs owned by the address.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (nftOwnerOf[i] == _owner) {
                balance++;
            }
        }
        return balance;
    }

    /**
     * @dev Returns the name of the NFT collection.
     * @return The name string.
     */
    function name() public view returns (string memory) {
        return name;
    }

    /**
     * @dev Returns the symbol of the NFT collection.
     * @return The symbol string.
     */
    function symbol() public view returns (string memory) {
        return symbol;
    }

    // --- 3. Dynamic Traits and Evolution ---

    /**
     * @dev Triggers the evolution of a specific artwork trait. Only contract owner can trigger evolution in this example.
     *      In a real-world scenario, this could be triggered by various on-chain or off-chain events, governance, etc.
     * @param _artworkId The ID of the artwork to evolve.
     * @param _traitName The name of the trait to evolve.
     * @param _newValue The new value for the trait.
     * @param _evolutionReason Reason for the trait evolution.
     */
    function evolveArtworkTrait(uint256 _artworkId, string memory _traitName, string memory _newValue, string memory _evolutionReason) external onlyOwner whenNotPaused {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        require(bytes(_traitName).length > 0, "Trait name cannot be empty.");
        artworkTraits[_artworkId][_traitName] = _newValue;
        emit TraitEvolved(_artworkId, _traitName, _newValue, _evolutionReason);
    }

    /**
     * @dev Sets the evolution rule for a specific trait of an artwork. Only artist can set rules for their artwork.
     * @param _artworkId The ID of the artwork.
     * @param _traitName The name of the trait.
     * @param _ruleDescription Description of the evolution rule.
     * @param _ruleDetails Detailed rule information (can be used for more complex logic later).
     */
    function setEvolutionRule(uint256 _artworkId, string memory _traitName, string memory _ruleDescription, string memory _ruleDetails) external onlyArtist(_artworkId) whenNotPaused {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        require(bytes(_traitName).length > 0, "Trait name cannot be empty.");
        artworkEvolutionRules[_artworkId][_traitName] = EvolutionRule({
            description: _ruleDescription,
            ruleDetails: _ruleDetails
        });
        emit EvolutionRuleSet(_artworkId, _traitName, _ruleDescription);
    }

    /**
     * @dev Retrieves the evolution rule for a specific trait of an artwork.
     * @param _artworkId The ID of the artwork.
     * @param _traitName The name of the trait.
     * @return EvolutionRule struct containing the rule details.
     */
    function getEvolutionRule(uint256 _artworkId, string memory _traitName) external view returns (EvolutionRule memory) {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        return artworkEvolutionRules[_artworkId][_traitName];
    }


    // --- 4. Community Interaction and Influence (Simulated) ---

    /**
     * @dev Allows community members to vote for a potential trait evolution (simulated community influence).
     *      This is a simplified voting mechanism. In a real-world scenario, more sophisticated voting systems could be used.
     * @param _proposalId The ID of the community proposal to vote on.
     */
    function voteForTraitEvolution(uint256 _proposalId) external whenNotPaused {
        require(proposals[_proposalId].id != 0, "Proposal does not exist.");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        proposals[_proposalId].voteCount++;
        proposalVotes[_proposalId][msg.sender] = true;
        emit CommunityProposalVoted(_proposalId, msg.sender);
    }

    /**
     * @dev Allows community members to submit proposals for artwork trait evolution (simulated community influence).
     * @param _artworkId The ID of the artwork the proposal is for.
     * @param _traitName The name of the trait to be evolved.
     * @param _proposedNewValue The proposed new value for the trait.
     * @param _title Title of the proposal.
     * @param _description Description of the proposal.
     */
    function submitCommunityProposal(
        uint256 _artworkId,
        string memory _traitName,
        string memory _proposedNewValue,
        string memory _title,
        string memory _description
    ) external whenNotPaused {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        require(bytes(_traitName).length > 0, "Trait name cannot be empty.");

        proposalCount++;
        uint256 proposalId = proposalCount;
        proposals[proposalId] = CommunityProposal({
            id: proposalId,
            title: _title,
            description: _description,
            artworkId: _artworkId,
            traitName: _traitName,
            proposedNewValue: _proposedNewValue,
            proposer: msg.sender,
            voteCount: 0,
            creationTimestamp: block.timestamp,
            executed: false
        });
        emit CommunityProposalSubmitted(proposalId, _artworkId, _traitName, _proposedNewValue, msg.sender);
    }

    /**
     * @dev Retrieves details of a community proposal.
     * @param _proposalId The ID of the proposal.
     * @return CommunityProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (CommunityProposal memory) {
        require(proposals[_proposalId].id != 0, "Proposal does not exist.");
        return proposals[_proposalId];
    }

    /**
     * @dev Allows community members to vote on a community proposal.
     * @param _proposalId The ID of the proposal to vote on.
     */
    function voteOnProposal(uint256 _proposalId) external whenNotPaused {
        voteForTraitEvolution(_proposalId); // Reusing the vote function for simplicity
    }


    /**
     * @dev Executes a community proposal if it receives enough votes (simulated effect). Only contract owner can execute.
     *      In a real-world scenario, this could be automated based on vote thresholds or governance rules.
     * @param _proposalId The ID of the proposal to execute.
     * @param _minVotesRequired Minimum votes required to execute the proposal.
     */
    function executeCommunityProposal(uint256 _proposalId, uint256 _minVotesRequired) external onlyOwner whenNotPaused {
        require(proposals[_proposalId].id != 0, "Proposal does not exist.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(proposals[_proposalId].voteCount >= _minVotesRequired, "Proposal does not have enough votes.");

        evolveArtworkTrait(
            proposals[_proposalId].artworkId,
            proposals[_proposalId].traitName,
            proposals[_proposalId].proposedNewValue,
            "Community Proposal Execution"
        );
        proposals[_proposalId].executed = true;
        emit CommunityProposalExecuted(_proposalId);
    }


    // --- 5. Utility and Information ---

    /**
     * @dev Supports interface identification (ERC165).
     * @param interfaceId The interface ID to check for.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // Example: ERC721 interface ID (0x80ac58cd) - Add more if needed.
        return interfaceId == 0x80ac58cd || interfaceId == 0x01ffc9a7; // ERC721 Interface ID + ERC165 Interface ID
    }

    /**
     * @dev Pauses the contract, preventing core functionalities (except unpause and view functions).
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring core functionalities.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw any Ether in the contract balance.
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit FundsWithdrawn(msg.sender, balance);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to clear approval for a token.
     * @param _tokenId The ID of the token.
     */
    function _clearApproval(uint256 _tokenId) internal {
        if (nftApproved[_tokenId] != address(0)) {
            delete nftApproved[_tokenId];
        }
    }
}
```