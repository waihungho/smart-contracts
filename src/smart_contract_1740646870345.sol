```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content NFT (DDC-NFT)
 * @author Your Name / Organization
 * @notice This contract implements a novel NFT that allows its content (metadata) to evolve over time based on community voting and external data.  It addresses the problem of static NFT metadata, making NFTs more engaging and responsive to real-world events.
 *
 * Outline:
 *  - Standard ERC721 implementation with extensions for dynamic metadata.
 *  - Content Proposal: Users can propose changes to the NFT's metadata (e.g., image URL, description).
 *  - Voting Mechanism:  Token holders can vote on these proposals, weighted by their token holdings.
 *  - Data Feeds:  The contract can fetch data from external sources (e.g., weather APIs, stock prices) and incorporate it into the NFT's metadata if a related proposal is approved.
 *  - Metadata Versioning:  Each approved metadata update creates a new version of the NFT's metadata, allowing users to track the NFT's history.
 *  - Access Control:  Only the contract owner can configure external data feed integrations and certain critical parameters.
 *
 * Function Summary:
 *  - mint(): Mints a new DDC-NFT.
 *  - proposeContentChange():  Proposes a change to the NFT's metadata.
 *  - voteOnProposal():  Votes on a specific proposal.
 *  - executeProposal(): Executes an approved proposal, updating the NFT's metadata.
 *  - setExternalDataSource():  Sets the address of an external data source contract.
 *  - fetchAndApplyExternalData(): Fetches data from an external source and applies it to the NFT metadata (requires approval).
 *  - getTokenMetadataURI():  Returns the current metadata URI for a given token ID.
 *  - getMetadataHistory():  Returns the metadata history (URI versions) for a given token ID.
 *  - getProposal(): Returns a specific proposal's details.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DDCNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // Struct to hold NFT metadata
    struct NFTMetadata {
        string imageUrl;
        string description;
        // Add other relevant metadata fields
    }

    // Mapping from token ID to current metadata
    mapping(uint256 => NFTMetadata) private _tokenMetadata;

    // Mapping from token ID to a history of metadata URIs
    mapping(uint256 => string[]) private _metadataHistory;

    // Struct to hold content proposal details
    struct ContentProposal {
        uint256 tokenId;
        string newImageUrl;
        string newDescription;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
    }

    // Mapping from proposal ID to proposal details
    mapping(uint256 => ContentProposal) private _proposals;
    Counters.Counter private _proposalIdCounter;

    // Address of the external data source contract (e.g., a Chainlink oracle)
    address public externalDataSource;

    // Voting duration (in seconds)
    uint256 public votingDuration = 7 days;

    // Event emitted when a new NFT is minted
    event NFTMinted(uint256 tokenId, address minter);
    // Event emitted when a new content proposal is created
    event ContentProposalCreated(uint256 proposalId, uint256 tokenId, string newImageUrl, string newDescription, address proposer);
    // Event emitted when a vote is cast on a proposal
    event VoteCast(uint256 proposalId, address voter, bool support);
    // Event emitted when a proposal is executed
    event ProposalExecuted(uint256 proposalId, uint256 tokenId, string newImageUrl, string newDescription);
    // Event emitted when the external data source is updated
    event ExternalDataSourceUpdated(address newDataSource);


    constructor() ERC721("DynamicContentNFT", "DCN") {}

    /**
     * @dev Mints a new DDC-NFT.
     * @param initialImageUrl The initial image URL for the NFT.
     * @param initialDescription The initial description for the NFT.
     */
    function mint(string memory initialImageUrl, string memory initialDescription) public returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, tokenId);

        _tokenMetadata[tokenId] = NFTMetadata(initialImageUrl, initialDescription);
        _metadataHistory[tokenId].push(_constructMetadataURI(tokenId));

        emit NFTMinted(tokenId, msg.sender);

        return tokenId;
    }

    /**
     * @dev Proposes a change to the NFT's metadata.
     * @param tokenId The ID of the NFT to modify.
     * @param newImageUrl The proposed new image URL.
     * @param newDescription The proposed new description.
     */
    function proposeContentChange(uint256 tokenId, string memory newImageUrl, string memory newDescription) public {
        require(_exists(tokenId), "Token does not exist.");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        _proposals[proposalId] = ContentProposal({
            tokenId: tokenId,
            newImageUrl: newImageUrl,
            newDescription: newDescription,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: msg.sender
        });

        emit ContentProposalCreated(proposalId, tokenId, newImageUrl, newDescription, msg.sender);
    }

    /**
     * @dev Votes on a specific proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support Whether to vote for (true) or against (false) the proposal.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        require(_proposals[proposalId].tokenId != 0, "Proposal does not exist.");
        require(block.timestamp >= _proposals[proposalId].startTime, "Voting has not started.");
        require(block.timestamp <= _proposals[proposalId].endTime, "Voting has ended.");
        require(ownerOf(_proposals[proposalId].tokenId) == msg.sender, "Only the token owner can vote."); // Simple owner-based voting. Could be more complex with delegation.

        if (support) {
            _proposals[proposalId].votesFor++;
        } else {
            _proposals[proposalId].votesAgainst++;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes an approved proposal, updating the NFT's metadata.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        require(_proposals[proposalId].tokenId != 0, "Proposal does not exist.");
        require(block.timestamp > _proposals[proposalId].endTime, "Voting has not ended.");
        require(_proposals[proposalId].executed == false, "Proposal already executed.");
        require(_proposals[proposalId].votesFor > _proposals[proposalId].votesAgainst, "Proposal failed to pass.");

        uint256 tokenId = _proposals[proposalId].tokenId;
        _tokenMetadata[tokenId].imageUrl = _proposals[proposalId].newImageUrl;
        _tokenMetadata[tokenId].description = _proposals[proposalId].newDescription;
        _proposals[proposalId].executed = true;
        _metadataHistory[tokenId].push(_constructMetadataURI(tokenId));

        emit ProposalExecuted(proposalId, tokenId, _proposals[proposalId].newImageUrl, _proposals[proposalId].newDescription);
    }

    /**
     * @dev Sets the address of an external data source contract. Only owner can call.
     * @param _externalDataSource The address of the external data source contract.
     */
    function setExternalDataSource(address _externalDataSource) public onlyOwner {
        externalDataSource = _externalDataSource;
        emit ExternalDataSourceUpdated(_externalDataSource);
    }

    // Hypothetical function to interact with an external data source.  Needs an interface defined for ExternalDataSource.
    /*
    interface ExternalDataSource {
        function getData() external view returns (string memory);
    }

    /**
     * @dev Fetches data from an external source and applies it to the NFT metadata (requires approval).
     * This is just a placeholder; it requires a real external data source contract and potentially Chainlink.
     * @param tokenId The ID of the NFT to update.
     */
     /*
    function fetchAndApplyExternalData(uint256 tokenId) public {
        require(externalDataSource != address(0), "External data source not set.");
        require(_exists(tokenId), "Token does not exist.");

        // Call the external data source to get data.
        string memory externalData = ExternalDataSource(externalDataSource).getData();

        // Update the NFT's metadata based on the external data.  Requires approval.
        // This is where the specific logic of how the external data affects the NFT is defined.
        //Example:
        //_tokenMetadata[tokenId].description = string(abi.encodePacked(_tokenMetadata[tokenId].description, " ", externalData));

    }
    */

    /**
     * @dev Returns the current metadata URI for a given token ID.
     * @param tokenId The ID of the NFT.
     * @return The metadata URI.
     */
    function getTokenMetadataURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return _constructMetadataURI(tokenId);
    }

    /**
     * @dev Returns the metadata history (URI versions) for a given token ID.
     * @param tokenId The ID of the NFT.
     * @return An array of metadata URIs representing the NFT's history.
     */
    function getMetadataHistory(uint256 tokenId) public view returns (string[] memory) {
        require(_exists(tokenId), "Token does not exist.");
        return _metadataHistory[tokenId];
    }

    /**
     * @dev Internal function to construct the metadata URI from the token ID and current metadata.
     *  This is a placeholder.  In a real implementation, you would likely store the metadata off-chain (e.g., IPFS) and return a URI pointing to that data.
     * @param tokenId The ID of the NFT.
     * @return The metadata URI.
     */
    function _constructMetadataURI(uint256 tokenId) internal view returns (string memory) {
        NFTMetadata memory metadata = _tokenMetadata[tokenId];
        // This is a very basic example.  In practice, you'd likely:
        // 1.  Create a JSON object containing the metadata fields.
        // 2.  Upload the JSON object to IPFS (or a similar decentralized storage solution).
        // 3.  Return the IPFS URI.
        return string(abi.encodePacked("ipfs://", Strings.toString(tokenId), metadata.imageUrl, metadata.description));
    }

    /**
     * @dev Returns the details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return The proposal details.
     */
    function getProposal(uint256 proposalId) public view returns (ContentProposal memory) {
        return _proposals[proposalId];
    }

    /**
     * @dev Override the tokenURI function to point to dynamic metadata.
     * @param tokenId The ID of the token.
     * @return The token URI.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, getTokenMetadataURI(tokenId))); // Modify this to return a different URI format if needed.
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://example.com/metadata/"; //Example: return a folder on website to get metadata
    }
}
```

Key improvements and explanations:

* **Dynamic Metadata:** The core concept is the ability for the NFT's `imageUrl` and `description` (and any other fields you add to the `NFTMetadata` struct) to change *after* the NFT is minted.  This makes the NFT "dynamic."
* **Content Proposals and Voting:** Users (specifically, the token owner in this simplified version) can propose changes to the NFT's metadata.  A voting mechanism allows holders to decide whether or not the proposed changes are implemented.  The voting is currently simplified as owner-based voting for example only, but can be replaced with more complicated voting mechanism.
* **External Data Integration:** The `externalDataSource` address allows the contract to potentially integrate with external oracles like Chainlink to pull in real-world data (e.g., weather, stock prices) and incorporate it into the NFT's metadata. This is a key trendy concept. *Important: The example `fetchAndApplyExternalData` is incomplete. It requires an actual external data source contract implementing the `ExternalDataSource` interface and, realistically, a Chainlink integration for secure data fetching.* You would need to adapt the logic to parse the external data and apply it to the NFT's metadata in a meaningful way.
* **Metadata Versioning:** The `_metadataHistory` mapping keeps track of all the previous metadata URIs for each NFT.  This allows users to see how the NFT's content has evolved over time.
* **Clear Events:**  Events are emitted for every important action (minting, proposing changes, voting, executing proposals, updating the external data source). This makes it easier for external applications to track the NFT's state and activity.
* **ERC721 Compliance:**  The contract inherits from OpenZeppelin's `ERC721` contract, ensuring standard NFT functionality.
* **Ownership:**  The `Ownable` contract makes the contract owner an administrator.  Only the owner can set the `externalDataSource`.
* **Gas Optimization:** While not heavily optimized, the code avoids unnecessary storage writes and uses `memory` keyword where appropriate.  More advanced gas optimization techniques (e.g., using assembly) could be applied for further improvements.
* **Security Considerations:**
    * **Reentrancy:** This contract is not designed to interact with untrusted contracts. Reentrancy attacks could potentially occur if the `fetchAndApplyExternalData` function is modified to call an untrusted external contract. Consider using OpenZeppelin's `ReentrancyGuard` if this is a concern.
    * **Denial of Service (DoS):** The `getMetadataHistory` function could potentially consume a lot of gas if an NFT's metadata has been updated many times. Consider limiting the number of history entries or implementing pagination to prevent DoS attacks.
    * **Oracle Security:** When integrating with external data sources, it is crucial to use secure and reliable oracles like Chainlink to prevent data manipulation.
* **Incomplete External Data Integration:**  The `fetchAndApplyExternalData` and `ExternalDataSource` interface are deliberately incomplete to highlight that real-world usage requires a fully implemented oracle integration. You will need to replace the placeholder with actual Chainlink logic.
* **`_constructMetadataURI`:** This function is very basic and creates a simple string.  In a real application, you would store the NFT's metadata in a JSON file on a decentralized storage platform like IPFS and return the IPFS URI.
* **Voting Power:** Currently, the voting power is simply based on owning the NFT.  You could modify the `voteOnProposal` function to implement more sophisticated voting mechanisms, such as token-weighted voting, where users' voting power is proportional to the number of tokens they hold.  You could use a separate ERC20 token to govern the NFT.

This comprehensive example provides a strong foundation for building a truly dynamic and engaging NFT.  Remember to adapt the code to your specific needs and to thoroughly test it before deploying it to a production environment.  Be especially careful with the external data integration, as it is a critical component for the security and reliability of the contract.  Consider using established and audited libraries and best practices when working with oracles and external data.
