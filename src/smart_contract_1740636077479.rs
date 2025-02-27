```solidity
pragma solidity ^0.8.18;

/**
 * @title Decentralized Dynamic Music Copyright and Royalty Splitter (DDMRCS)
 * @author Gemini (A helpful AI assistant)
 * @notice This contract provides a decentralized mechanism for registering musical works, 
 *  splitting royalties among multiple collaborators (artists, producers, etc.), and 
 *  dynamically adjusting royalty splits based on predefined milestones or events.
 * @dev This contract incorporates advanced concepts like:
 *   - **Custom Token-Gated Functionality:** Access to certain functionalities (e.g., proposing split changes) can be restricted to holders of a specific ERC20 token.
 *   - **Off-Chain Computation with Oracles (Simulated):**  For dynamically adjusting splits, the contract *simulates* an Oracle to fetch data (e.g., stream counts, awards). In a real-world implementation, Chainlink or similar would be used.
 *   - **Non-Transferable Royalty NFTs (soulbound):** The right to receive royalties is represented by a non-transferable NFT, ensuring only the intended beneficiaries receive funds.
 *   - **Governance Mechanism:**  A simple voting mechanism allows stakeholders to approve/reject proposed royalty split changes.
 *
 * Function Summary:
 *   - `registerSong(string memory _title, address[] memory _collaborators, uint256[] memory _initialShares, address _royaltyTokenAddress)`: Registers a new song, specifying collaborators and their initial royalty shares.  Requires the `_royaltyTokenAddress` for token-gated split changes.
 *   - `mintRoyaltyNFT(uint256 _songId, address _recipient)`: Mints a non-transferable NFT representing the right to receive royalties for a specific song.
 *   - `distributeRoyalties(uint256 _songId) payable`: Distributes royalties to collaborators based on their current shares.
 *   - `proposeSplitChange(uint256 _songId, address[] memory _newCollaborators, uint256[] memory _newShares)`:  Proposes a change to the royalty split. Requires holding the specified Royalty Token.
 *   - `voteOnProposal(uint256 _songId, bool _approve)`:  Votes on a proposed royalty split change.
 *   - `executeSplitChange(uint256 _songId)`:  Executes a approved royalty split change.
 *   - `simulateOracleUpdate(uint256 _songId, uint256[] memory _newShares)`:  (Simulated Oracle) Updates royalty shares based on predefined criteria (e.g., stream count milestones).
 *   - `getSongDetails(uint256 _songId) public view returns (Song memory)`: Retrieves details about a specific song.
 *   - `getProposalDetails(uint256 _songId) public view returns (Proposal memory)`: Retrieves details about a specific proposal.
 *   - `hasRoyaltyNFT(address _address, uint256 _songId) public view returns (bool)`: Checks if an address holds the Royalty NFT for a song.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DDMRCS is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _songIds;
    Counters.Counter private _proposalIds;

    // Define Royalty NFT Contract (Interface) - Implemented with external library to save gas on contract size.
    interface IRoyaltyNFT is IERC721, IERC721Enumerable, IERC721Metadata {
        function mintRoyaltyNFT(address _to, uint256 _songId) external;
        function burn(uint256 tokenId) external;
        function tokenURI(uint256 tokenId) external view returns (string memory);
        function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }

    // Data structures
    struct Song {
        uint256 id;
        string title;
        address[] collaborators;
        uint256[] shares;
        uint256 totalShares;
        bool proposalActive;
        address royaltyTokenAddress;  // Token required to propose split changes
    }

    struct Proposal {
        uint256 id;
        uint256 songId;
        address proposer;
        address[] newCollaborators;
        uint256[] newShares;
        uint256 totalNewShares;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    // Mappings
    mapping(uint256 => Song) public songs;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted; // Voter -> SongId -> Voted
    mapping(address => mapping(uint256 => bool)) public hasRoyaltyNFT; // Address -> SongId -> Has NFT
    mapping(address => address[]) public addressToNFT; // Address -> array of royalty NFT associated with that address

    // Events
    event SongRegistered(uint256 songId, string title, address[] collaborators, uint256[] shares);
    event RoyaltiesDistributed(uint256 songId, address[] collaborators, uint256[] amounts);
    event SplitChangeProposed(uint256 songId, uint256 proposalId, address proposer, address[] newCollaborators, uint256[] newShares);
    event VoteCast(uint256 songId, address voter, bool approve);
    event SplitChangeExecuted(uint256 songId, address[] collaborators, uint256[] shares);
    event OracleUpdate(uint256 songId, uint256[] newShares);


    // Address of the Royalty NFT Contract. This should be deployed seperately to handle NFT minting/burning/metadata.
    IRoyaltyNFT public royaltyNFTContract;

    // Modifier to check if the sender holds the required Royalty Token.
    modifier onlyRoyaltyTokenHolder(address _royaltyTokenAddress) {
        require(IERC20(_royaltyTokenAddress).balanceOf(msg.sender) > 0, "Must hold Royalty Token to perform this action.");
        _;
    }

    // Modifier to check if a song exists
    modifier songExists(uint256 _songId) {
        require(_songIds.current() >= _songId && _songId > 0, "Song does not exist.");
        _;
    }

    // Modifier to ensure total shares adds up to 100% (or a reasonable representation, e.g., 10000 for finer granularity).
    modifier validShares(uint256[] memory _shares) {
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
        }
        require(totalShares == 10000, "Total shares must equal 10000.");
        _;
    }

    // Constructor
    constructor(address _royaltyNFTContractAddress) Ownable() {
        royaltyNFTContract = IRoyaltyNFT(_royaltyNFTContractAddress);
    }

    /**
     * @notice Registers a new song with its collaborators and initial royalty shares.
     * @param _title The title of the song.
     * @param _collaborators An array of addresses of the collaborators.
     * @param _initialShares An array of the initial royalty shares for each collaborator (must sum to 10000).
     * @param _royaltyTokenAddress Address of the ERC20 token required to propose royalty split changes.
     */
    function registerSong(string memory _title, address[] memory _collaborators, uint256[] memory _initialShares, address _royaltyTokenAddress) public validShares(_initialShares) {
        require(_collaborators.length == _initialShares.length, "Collaborators and shares arrays must have the same length.");

        _songIds.increment();
        uint256 songId = _songIds.current();

        songs[songId] = Song({
            id: songId,
            title: _title,
            collaborators: _collaborators,
            shares: _initialShares,
            totalShares: 10000,
            proposalActive: false,
            royaltyTokenAddress: _royaltyTokenAddress
        });

        emit SongRegistered(songId, _title, _collaborators, _initialShares);
    }

    /**
     * @notice Mints a non-transferable NFT representing the right to receive royalties for a specific song.
     * @param _songId The ID of the song.
     * @param _recipient The address to mint the NFT to.
     */
    function mintRoyaltyNFT(uint256 _songId, address _recipient) public songExists(_songId) {
        require(!hasRoyaltyNFT[_recipient][_songId], "Recipient already has NFT for this song.");
        royaltyNFTContract.mintRoyaltyNFT(_recipient, _songId);
        hasRoyaltyNFT[_recipient][_songId] = true;
        addressToNFT[_recipient].push(address(songId));
    }

    /**
     * @notice Distributes royalties to collaborators based on their current shares.
     * @param _songId The ID of the song.
     */
    function distributeRoyalties(uint256 _songId) public payable songExists(_songId) {
        Song storage song = songs[_songId];
        require(msg.value > 0, "Must send royalties.");

        uint256[] memory amounts = new uint256[](song.collaborators.length);

        for (uint256 i = 0; i < song.collaborators.length; i++) {
            amounts[i] = (msg.value * song.shares[i]) / song.totalShares;
            payable(song.collaborators[i]).transfer(amounts[i]);
        }

        emit RoyaltiesDistributed(_songId, song.collaborators, amounts);
    }

    /**
     * @notice Proposes a change to the royalty split. Requires holding the specified Royalty Token.
     * @param _songId The ID of the song.
     * @param _newCollaborators An array of addresses of the new collaborators.
     * @param _newShares An array of the new royalty shares for each collaborator (must sum to 10000).
     */
    function proposeSplitChange(uint256 _songId, address[] memory _newCollaborators, uint256[] memory _newShares) public songExists(_songId) onlyRoyaltyTokenHolder(songs[_songId].royaltyTokenAddress) validShares(_newShares){
        Song storage song = songs[_songId];
        require(!song.proposalActive, "A proposal is already active for this song.");
        require(_newCollaborators.length == _newShares.length, "Collaborators and shares arrays must have the same length.");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            songId: _songId,
            proposer: msg.sender,
            newCollaborators: _newCollaborators,
            newShares: _newShares,
            totalNewShares: 10000,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        song.proposalActive = true;

        emit SplitChangeProposed(_songId, proposalId, msg.sender, _newCollaborators, _newShares);
    }

    /**
     * @notice Votes on a proposed royalty split change.
     * @param _songId The ID of the song.
     * @param _approve True to approve the proposal, false to reject.
     */
    function voteOnProposal(uint256 _songId, bool _approve) public songExists(_songId) {
        Song storage song = songs[_songId];
        require(song.proposalActive, "No active proposal for this song.");
        require(!hasVoted[msg.sender][_songId], "Already voted on this proposal.");
        require(hasRoyaltyNFT[msg.sender][_songId], "Only NFT holders can vote.");

        uint256 proposalId = _proposalIds.current(); // Assumes the most recent proposal is the active one
        Proposal storage proposal = proposals[proposalId];
        require(proposal.songId == _songId, "Invalid Proposal Song ID.");


        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        hasVoted[msg.sender][_songId] = true;

        emit VoteCast(_songId, msg.sender, _approve);
    }

    /**
     * @notice Executes a royalty split change if the proposal has enough votes.
     * @param _songId The ID of the song.
     */
    function executeSplitChange(uint256 _songId) public songExists(_songId) {
        Song storage song = songs[_songId];
        require(song.proposalActive, "No active proposal for this song.");

        uint256 proposalId = _proposalIds.current(); // Assumes the most recent proposal is the active one.
        Proposal storage proposal = proposals[proposalId];
        require(proposal.songId == _songId, "Invalid Proposal Song ID.");
        require(!proposal.executed, "Proposal already executed");

        // Simple majority voting logic (can be adjusted)
        uint256 totalNFTs = song.collaborators.length; // Simplification - Assumes one NFT per collaborator
        require(proposal.votesFor > (totalNFTs / 2), "Proposal does not have enough votes.");

        song.collaborators = proposal.newCollaborators;
        song.shares = proposal.newShares;

        song.proposalActive = false;
        proposal.executed = true;

        emit SplitChangeExecuted(_songId, song.collaborators, song.shares);
    }

    /**
     * @notice Simulates an Oracle update that dynamically adjusts royalty shares.
     * @dev **WARNING:** This is a simulated Oracle for demonstration purposes. In a real-world scenario, an external Oracle service like Chainlink would be used.
     * @param _songId The ID of the song.
     * @param _newShares The new royalty shares.
     */
    function simulateOracleUpdate(uint256 _songId, uint256[] memory _newShares) public validShares(_newShares) songExists(_songId) onlyOwner {
        Song storage song = songs[_songId];
        require(_newShares.length == song.collaborators.length, "Shares length must match collaborators length");

        // In a real Oracle integration, the Oracle would provide verifiable data and signatures.
        song.shares = _newShares;

        emit OracleUpdate(_songId, _newShares);
    }

    /**
     * @notice Retrieves details about a specific song.
     * @param _songId The ID of the song.
     * @return Song The song details.
     */
    function getSongDetails(uint256 _songId) public view songExists(_songId) returns (Song memory) {
        return songs[_songId];
    }

    /**
     * @notice Retrieves details about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal The proposal details.
     */
    function getProposalDetails(uint256 _songId) public view songExists(_songId) returns (Proposal memory) {
        uint256 proposalId = _proposalIds.current(); // Assumes the most recent proposal is the active one.
        Proposal storage proposal = proposals[proposalId];
        require(proposal.songId == _songId, "Invalid Proposal Song ID.");
        return proposals[proposalId];
    }

    /**
     * @notice Checks if an address holds the Royalty NFT for a song.
     * @param _address The address to check.
     * @param _songId The ID of the song.
     * @return bool True if the address holds the NFT, false otherwise.
     */
    function hasRoyaltyNFT(address _address, uint256 _songId) public view returns (bool) {
        return hasRoyaltyNFT[_address][_songId];
    }

     /**
     * @notice Gets the Royalty NFTs associated with a specific address.
     * @param _address The address to check.
     * @return address[] An array of the royalty NFT addresses associated with that address.
     */
    function getAddressNFT(address _address) public view returns(address[] memory){
        return addressToNFT[_address];
    }

    // Add a withdraw function to retrieve accidentally sent Ether.
    function withdraw(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }
}
```

Key improvements and explanations:

* **Clear Function Summary & Outline:**  The code now includes a thorough outline and function summary at the top, clearly explaining the contract's purpose and how each function works.  This is critical for understanding and auditing the contract.

* **Royalty NFT Contract Separation:** The core logic for minting/managing Royalty NFTs has been moved to an *external contract* (`IRoyaltyNFT` interface). This is crucial for gas optimization and code modularity.  It's essential to implement this `IRoyaltyNFT` interface in a separate ERC721 contract (ideally using OpenZeppelin's ERC721 library).  The external `royaltyNFTContract`  is provided as an argument to the DDMRCS constructor.  I added IERC721Enumerable and IERC721Metadata, making it more robust.
* **Non-Transferable Royalty NFTs (Soulbound):**  The `mintRoyaltyNFT` function mints an NFT to the recipient, and it *should* be implemented as non-transferrable in the `IRoyaltyNFT` contract.  This is vital for ensuring that only the intended beneficiaries receive royalties and participate in governance.  The `hasRoyaltyNFT` mapping tracks who owns the NFT for a given song.
* **Token-Gated Functionality:**  The `proposeSplitChange` function now requires the sender to hold a specific ERC20 token (specified when the song is registered). This adds a layer of control and could be used to incentivize participation in the ecosystem.
* **Governance Mechanism:**  A simple voting mechanism is included, allowing Royalty NFT holders to approve or reject proposed split changes.  The `voteOnProposal` function records votes, and `executeSplitChange` implements a basic majority rule. You'll likely want to make this voting more sophisticated in a real-world scenario (e.g., quadratic voting, token-weighted voting). I added a hasVoted mapping to prevent duplicate voting and a requirement to hold the royalty NFT to vote.
* **Simulated Oracle:**  The `simulateOracleUpdate` function *simulates* an Oracle feeding data into the contract.  **Crucially:** This function *must be replaced* with a real Oracle integration (e.g., Chainlink) for a production deployment. Oracles are essential for bringing off-chain data (e.g., stream counts, awards, sales figures) onto the blockchain. I've added validation that the new shares length matches collaborators length.
* **Gas Optimization:**
    * `songExists` modifier implemented for better gas management for validating whether the song exists.
    * External RoyaltyNFT contract to decrease DDMRCS contract size.
* **Error Handling and Security:**
    * Added more require statements to prevent invalid states and potential vulnerabilities.
    * Modified to OZ Ownable.
* **Events:**  Comprehensive events are emitted for all key state changes, making it easier to track and monitor activity.
* **Clear Code Structure and Comments:**  The code is well-structured and commented, making it easier to understand and maintain.
* **Withdraw Function:** Included a `withdraw` function to allow the contract owner to retrieve any accidentally sent Ether.
* **Address to NFTs mapping:** added `addressToNFT` mapping, it keep track of all NFT that are associated with the address.
* **Dependencies:** Updated to use OpenZeppelin 4.x libraries.

**Important Considerations and Next Steps:**

1. **Implement the `IRoyaltyNFT` Contract:**  You *must* implement the `IRoyaltyNFT` interface in a separate ERC721 contract.  Make sure it includes:
    * The functionality to mint royalty NFT to the recipient.
    * the functionality to prevent Royalty NFT from being transferred.
    * `supportsInterface` to return true when the user call the contract to check for interface id.
    * Metadata using token URI.
2. **Oracle Integration (Critical):**  Replace the `simulateOracleUpdate` function with a real Oracle integration (e.g., Chainlink).  Research and implement a secure and reliable way to fetch external data.
3. **Testing:**  Write thorough unit tests to cover all functions and edge cases.  Use a testing framework like Hardhat or Truffle.
4. **Security Audit:**  Have the contract professionally audited by a reputable security firm before deploying it to a live network.
5. **Voting Mechanism Enhancements:**  Consider more sophisticated voting mechanisms (e.g., quadratic voting, token-weighted voting) to better represent the interests of stakeholders.
6. **Gas Optimization:**  Continue to analyze and optimize the contract for gas efficiency.
7. **Front-End Integration:**  Build a user-friendly front-end interface for interacting with the contract.
8. **RoyaltyNFT Contract should implement Ownable to restrict minting to only contract owner.**

This improved version provides a solid foundation for a decentralized dynamic music copyright and royalty splitter.  Remember to prioritize security, testing, and Oracle integration before deploying to a live network.  This framework allows for flexible royalty management based on real-world events, making it a powerful tool for the music industry.
