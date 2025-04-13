```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Bard (Example Smart Contract - For Educational Purposes)
 * @notice This smart contract implements a Decentralized Dynamic Content Platform (DDCP) where users can create, curate, and consume dynamic content NFTs.
 * It features advanced concepts like dynamic NFT metadata updates, decentralized content moderation via voting,
 * content subscription models, tipping, content remixing, and a reputation system for content creators and curators.
 *
 * **Outline & Function Summary:**
 *
 * **Core Functionality:**
 * 1. `createContentNFT(string _initialContentURI, string _category, string[] _tags)`: Allows users to create a new Dynamic Content NFT with initial content, category, and tags.
 * 2. `updateContentURI(uint256 _tokenId, string _newContentURI)`: Allows the NFT owner to update the content URI of their NFT, triggering dynamic metadata refresh.
 * 3. `setContentMetadataUpdater(address _updaterContract)`: Allows the contract owner to set a dedicated contract responsible for updating NFT metadata (for complex logic).
 * 4. `refreshMetadata(uint256 _tokenId)`:  Allows anyone to trigger a metadata refresh for a specific NFT, useful if external content changes are detected.
 * 5. `getContentDetails(uint256 _tokenId)`: Returns detailed information about a content NFT including owner, content URI, category, tags, reputation, etc.
 *
 * **Decentralized Content Moderation:**
 * 6. `reportContent(uint256 _tokenId, string _reportReason)`: Allows users to report content for violations.
 * 7. `createModerationProposal(uint256 _tokenId, ModerationAction _action, string _proposalDetails)`: Allows moderators to create proposals for actions like content removal or warnings.
 * 8. `voteOnModerationProposal(uint256 _proposalId, bool _vote)`: Allows authorized moderators to vote on moderation proposals.
 * 9. `executeModerationProposal(uint256 _proposalId)`: Executes a moderation proposal if it passes (majority vote).
 * 10. `addModerator(address _moderator)`:  Allows the contract owner to add new moderators.
 * 11. `removeModerator(address _moderator)`: Allows the contract owner to remove moderators.
 * 12. `getModeratorList()`: Returns the list of current moderators.
 *
 * **Content Subscription & Monetization:**
 * 13. `subscribeToContentCreator(address _creator)`: Allows users to subscribe to a content creator for access to premium content (future feature - basic subscription tracking here).
 * 14. `unsubscribeFromContentCreator(address _creator)`: Allows users to unsubscribe from a content creator.
 * 15. `isSubscribed(address _subscriber, address _creator)`: Checks if a user is subscribed to a creator.
 * 16. `tipContentCreator(address _creator)`: Allows users to tip content creators with Ether.
 *
 * **Content Remixing & Collaboration:**
 * 17. `remixContentNFT(uint256 _originalTokenId, string _remixContentURI, string _remixNotes)`: Allows users to remix existing content NFTs, creating derivative NFTs (tracks provenance).
 * 18. `getRemixHistory(uint256 _tokenId)`: Returns the remix history of a content NFT.
 *
 * **Reputation System:**
 * 19. `upvoteContent(uint256 _tokenId)`: Allows users to upvote content, increasing creator reputation.
 * 20. `downvoteContent(uint256 _tokenId)`: Allows users to downvote content, potentially decreasing creator reputation (moderated impact).
 * 21. `getCreatorReputation(address _creator)`: Returns the reputation score of a content creator.
 * 22. `setReputationModifier(address _modifierContract)`: Allows the contract owner to set a dedicated contract to manage complex reputation calculations and modifications.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedDynamicContentPlatform is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Mapping from token ID to content URI
    mapping(uint256 => string) private _contentURIs;
    mapping(uint256 => string) private _contentCategories;
    mapping(uint256 => string[]) private _contentTags;
    mapping(uint256 => address) private _contentCreators;
    mapping(address => int256) private _creatorReputations; // Simple reputation score

    // Content Moderation
    enum ModerationAction { WARN, REMOVE }
    struct ModerationProposal {
        uint256 tokenId;
        ModerationAction action;
        string proposalDetails;
        mapping(address => bool) votes; // Moderator votes
        uint256 voteCount;
        bool executed;
        bool passed;
    }
    mapping(uint256 => ModerationProposal) private _moderationProposals;
    address[] private _moderators;
    uint256 private _moderatorVoteThreshold = 2; // Minimum moderators needed to pass a proposal

    // Content Remixing
    mapping(uint256 => uint256[]) private _remixHistory; // Token ID -> Array of original token IDs

    // Subscription Tracking (Basic - can be expanded)
    mapping(address => mapping(address => bool)) private _subscriptions; // Subscriber -> Creator -> IsSubscribed

    // External Contracts for Advanced Logic (Optional - for extensibility)
    address public metadataUpdaterContract;
    address public reputationModifierContract;

    // Events
    event ContentNFTCreated(uint256 tokenId, address creator, string contentURI);
    event ContentURIUpdated(uint256 tokenId, string newContentURI);
    event ModerationProposalCreated(uint256 proposalId, uint256 tokenId, ModerationAction action, string details, address proposer);
    event ModerationVoteCast(uint256 proposalId, address moderator, bool vote);
    event ModerationProposalExecuted(uint256 proposalId, bool passed, ModerationAction action, uint256 tokenId);
    event ContentReported(uint256 tokenId, address reporter, string reason);
    event ContentRemixed(uint256 newTokenId, uint256 originalTokenId, address remixer);
    event ContentUpvoted(uint256 tokenId, address voter);
    event ContentDownvoted(uint256 tokenId, address voter);
    event CreatorTipped(address creator, address tipper, uint256 amount);
    event SubscribedToCreator(address subscriber, address creator);
    event UnsubscribedFromCreator(address subscriber, address creator);

    constructor() ERC721("DynamicContentNFT", "DCNFT") Ownable() {
        // Initialize contract, maybe set initial moderators in the future
    }

    /**
     * @dev Creates a new Dynamic Content NFT.
     * @param _initialContentURI The initial URI pointing to the content.
     * @param _category The category of the content.
     * @param _tags An array of tags associated with the content.
     */
    function createContentNFT(string memory _initialContentURI, string memory _category, string[] memory _tags) external nonReentrant {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(_msgSender(), tokenId);
        _contentURIs[tokenId] = _initialContentURI;
        _contentCategories[tokenId] = _category;
        _contentTags[tokenId] = _tags;
        _contentCreators[tokenId] = _msgSender();

        emit ContentNFTCreated(tokenId, _msgSender(), _initialContentURI);
    }

    /**
     * @dev Updates the content URI of an existing NFT. Only the owner can call this.
     * @param _tokenId The ID of the NFT to update.
     * @param _newContentURI The new URI pointing to the content.
     */
    function updateContentURI(uint256 _tokenId, string memory _newContentURI) external nonReentrant {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Not NFT owner");

        _contentURIs[_tokenId] = _newContentURI;

        // Optional: Trigger metadata refresh if using external metadata updater
        if (metadataUpdaterContract != address(0)) {
            // Secure external call pattern is crucial here in production
            (bool success, ) = metadataUpdaterContract.call(abi.encodeWithSignature("refreshMetadata(uint256)", _tokenId));
            require(success, "Metadata refresh call failed");
        } else {
            // If no external updater, emit event for off-chain refresh
            emit ContentURIUpdated(_tokenId, _newContentURI);
        }
    }

    /**
     * @dev Sets the address of the contract responsible for updating NFT metadata.
     * @param _updaterContract The address of the metadata updater contract.
     */
    function setContentMetadataUpdater(address _updaterContract) external onlyOwner {
        metadataUpdaterContract = _updaterContract;
    }

    /**
     * @dev Allows anyone to trigger a metadata refresh for a specific NFT.
     *      Useful if external content changes are detected and need to be reflected in metadata.
     * @param _tokenId The ID of the NFT to refresh metadata for.
     */
    function refreshMetadata(uint256 _tokenId) external {
        require(_exists(_tokenId), "Token does not exist");
        emit ContentURIUpdated(_tokenId, _contentURIs[_tokenId]); // Re-emit event to trigger metadata refresh
    }

    /**
     * @dev Returns detailed information about a content NFT.
     * @param _tokenId The ID of the NFT.
     * @return contentURI, category, tags, creator, reputation
     */
    function getContentDetails(uint256 _tokenId) external view returns (string memory contentURI, string memory category, string[] memory tags, address creator, int256 reputation) {
        require(_exists(_tokenId), "Token does not exist");
        return (_contentURIs[_tokenId], _contentCategories[_tokenId], _contentTags[_tokenId], _contentCreators[_tokenId], _creatorReputations[_contentCreators[_tokenId]]);
    }

    /**
     * @dev Reports content for violation. Anyone can report content.
     * @param _tokenId The ID of the NFT being reported.
     * @param _reportReason The reason for the report.
     */
    function reportContent(uint256 _tokenId, string memory _reportReason) external {
        require(_exists(_tokenId), "Token does not exist");
        emit ContentReported(_tokenId, _msgSender(), _reportReason);
        // In a real application, this would trigger further moderation processes,
        // perhaps creating a moderation proposal automatically.
    }

    /**
     * @dev Creates a moderation proposal for a specific content NFT. Only moderators can call this.
     * @param _tokenId The ID of the NFT to moderate.
     * @param _action The moderation action to propose (WARN or REMOVE).
     * @param _proposalDetails Details about the proposal.
     */
    function createModerationProposal(uint256 _tokenId, ModerationAction _action, string memory _proposalDetails) external onlyModerator {
        require(_exists(_tokenId), "Token does not exist");
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        _moderationProposals[proposalId] = ModerationProposal({
            tokenId: _tokenId,
            action: _action,
            proposalDetails: _proposalDetails,
            votes: mapping(address => bool)(),
            voteCount: 0,
            executed: false,
            passed: false
        });

        emit ModerationProposalCreated(proposalId, _tokenId, _action, _proposalDetails, _msgSender());
    }

    /**
     * @dev Allows moderators to vote on a moderation proposal.
     * @param _proposalId The ID of the moderation proposal.
     * @param _vote True for approve, false for reject.
     */
    function voteOnModerationProposal(uint256 _proposalId, bool _vote) external onlyModerator {
        require(_moderationProposals[_proposalId].tokenId != 0, "Proposal does not exist"); // Check if proposal exists
        require(!_moderationProposals[_proposalId].executed, "Proposal already executed");
        require(!_moderationProposals[_proposalId].votes[_msgSender()], "Moderator already voted");

        _moderationProposals[_proposalId].votes[_msgSender()] = true;
        if (_vote) {
            _moderationProposals[_proposalId].voteCount++;
        }

        emit ModerationVoteCast(_proposalId, _msgSender(), _vote);
    }

    /**
     * @dev Executes a moderation proposal if it has passed the voting threshold.
     * @param _proposalId The ID of the moderation proposal to execute.
     */
    function executeModerationProposal(uint256 _proposalId) external onlyModerator nonReentrant {
        require(_moderationProposals[_proposalId].tokenId != 0, "Proposal does not exist");
        require(!_moderationProposals[_proposalId].executed, "Proposal already executed");

        if (_moderationProposals[_proposalId].voteCount >= _moderatorVoteThreshold) {
            _moderationProposals[_proposalId].passed = true;
            ModerationAction action = _moderationProposals[_proposalId].action;
            uint256 tokenId = _moderationProposals[_proposalId].tokenId;

            if (action == ModerationAction.REMOVE) {
                // Remove content - in this example, we'll just clear the content URI.
                // More drastic actions could include burning the NFT (carefully considered and implemented).
                _contentURIs[tokenId] = "ipfs://removed-content"; // Placeholder URI for removed content
                emit ContentURIUpdated(tokenId, _contentURIs[tokenId]); // Indicate content removal in metadata

                // Consider adjusting creator reputation negatively more significantly upon content removal.
                _adjustCreatorReputation(_contentCreators[tokenId], -10); // Example reputation penalty
            } else if (action == ModerationAction.WARN) {
                // Issue a warning - in this example, we'll just emit an event.
                // More advanced warnings could be tracked on-chain or off-chain reputation systems.
                // For now, reputation impact of warnings could be less severe.
                _adjustCreatorReputation(_contentCreators[tokenId], -2); // Example reputation penalty for warning
            }

            emit ModerationProposalExecuted(_proposalId, true, action, tokenId);
        } else {
            emit ModerationProposalExecuted(_proposalId, false, ModerationAction.WARN, _moderationProposals[_proposalId].tokenId); // Indicate failed execution, default action is WARN for consistency in event
        }
        _moderationProposals[_proposalId].executed = true; // Mark proposal as executed regardless of pass/fail.
    }

    /**
     * @dev Adds a new moderator. Only contract owner can call this.
     * @param _moderator The address of the new moderator.
     */
    function addModerator(address _moderator) external onlyOwner {
        _moderators.push(_moderator);
    }

    /**
     * @dev Removes a moderator. Only contract owner can call this.
     * @param _moderator The address of the moderator to remove.
     */
    function removeModerator(address _moderator) external onlyOwner {
        for (uint256 i = 0; i < _moderators.length; i++) {
            if (_moderators[i] == _moderator) {
                delete _moderators[i];
                // To maintain array integrity, you might want to shift elements or use a more complex structure in production.
                // For simplicity in this example, we leave a "hole" in the array.
                break;
            }
        }
    }

    /**
     * @dev Returns the list of current moderators.
     * @return An array of moderator addresses.
     */
    function getModeratorList() external view returns (address[] memory) {
        address[] memory activeModerators = new address[](_moderators.length);
        uint256 count = 0;
        for (uint256 i = 0; i < _moderators.length; i++) {
            if (_moderators[i] != address(0)) { // Skip "holes" from removals
                activeModerators[count] = _moderators[i];
                count++;
            }
        }
        assembly { // Assembly to efficiently resize the array - Solidity only allows resizing in memory or storage arrays, not fixed size arrays.
            mstore(activeModerators, count) // Update the length of the array in memory
        }
        return activeModerators;
    }

    /**
     * @dev Allows a user to subscribe to a content creator.
     * @param _creator The address of the content creator.
     */
    function subscribeToContentCreator(address _creator) external {
        _subscriptions[_msgSender()][_creator] = true;
        emit SubscribedToCreator(_msgSender(), _creator);
    }

    /**
     * @dev Allows a user to unsubscribe from a content creator.
     * @param _creator The address of the content creator.
     */
    function unsubscribeFromContentCreator(address _creator) external {
        _subscriptions[_msgSender()][_creator] = false;
        emit UnsubscribedFromCreator(_msgSender(), _creator);
    }

    /**
     * @dev Checks if a user is subscribed to a content creator.
     * @param _subscriber The address of the subscriber.
     * @param _creator The address of the content creator.
     * @return True if subscribed, false otherwise.
     */
    function isSubscribed(address _subscriber, address _creator) external view returns (bool) {
        return _subscriptions[_subscriber][_creator];
    }

    /**
     * @dev Allows users to tip content creators with Ether.
     * @param _creator The address of the content creator to tip.
     */
    function tipContentCreator(address _creator) external payable {
        require(_creator != address(0), "Invalid creator address");
        payable(_creator).transfer(msg.value);
        emit CreatorTipped(_creator, _msgSender(), msg.value);
        _adjustCreatorReputation(_creator, 1); // Example: Small reputation boost for tips
    }

    /**
     * @dev Allows users to remix an existing content NFT, creating a derivative NFT.
     * @param _originalTokenId The ID of the original content NFT being remixed.
     * @param _remixContentURI The URI of the remixed content.
     * @param _remixNotes Notes about the remix or changes made.
     */
    function remixContentNFT(uint256 _originalTokenId, string memory _remixContentURI, string memory _remixNotes) external nonReentrant {
        require(_exists(_originalTokenId), "Original token does not exist");
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(_msgSender(), newTokenId);
        _contentURIs[newTokenId] = _remixContentURI;
        _contentCategories[newTokenId] = _contentCategories[_originalTokenId]; // Inherit category from original
        _contentTags[newTokenId] = _contentTags[_originalTokenId]; // Inherit tags from original (or allow modification)
        _contentCreators[newTokenId] = _msgSender();

        _remixHistory[_originalTokenId].push(newTokenId); // Track remix history in original NFT
        emit ContentRemixed(newTokenId, _originalTokenId, _msgSender());
    }

    /**
     * @dev Gets the remix history of a content NFT.
     * @param _tokenId The ID of the content NFT.
     * @return An array of token IDs that are remixes of this NFT.
     */
    function getRemixHistory(uint256 _tokenId) external view returns (uint256[] memory) {
        return _remixHistory[_tokenId];
    }

    /**
     * @dev Allows users to upvote content, increasing the creator's reputation.
     * @param _tokenId The ID of the content NFT to upvote.
     */
    function upvoteContent(uint256 _tokenId) external {
        require(_exists(_tokenId), "Token does not exist");
        emit ContentUpvoted(_tokenId, _msgSender());
        _adjustCreatorReputation(_contentCreators[_tokenId], 1); // Example: Increment reputation score
    }

    /**
     * @dev Allows users to downvote content, potentially decreasing the creator's reputation.
     * @param _tokenId The ID of the content NFT to downvote.
     */
    function downvoteContent(uint256 _tokenId) external {
        require(_exists(_tokenId), "Token does not exist");
        emit ContentDownvoted(_tokenId, _msgSender());
        _adjustCreatorReputation(_contentCreators[_tokenId], -1); // Example: Decrement reputation score
    }

    /**
     * @dev Gets the reputation score of a content creator.
     * @param _creator The address of the content creator.
     * @return The reputation score.
     */
    function getCreatorReputation(address _creator) external view returns (int256) {
        return _creatorReputations[_creator];
    }

    /**
     * @dev Sets the address of the contract responsible for modifying creator reputation.
     * @param _modifierContract The address of the reputation modifier contract.
     */
    function setReputationModifier(address _modifierContract) external onlyOwner {
        reputationModifierContract = _modifierContract;
    }

    /**
     * @dev Internal function to adjust creator reputation. Can be extended with external reputation modifier contract.
     * @param _creator The address of the creator.
     * @param _amount The amount to adjust the reputation by (positive or negative).
     */
    function _adjustCreatorReputation(address _creator, int256 _amount) internal {
        if (reputationModifierContract != address(0)) {
            // Secure external call pattern for complex reputation logic
            (bool success, ) = reputationModifierContract.call(abi.encodeWithSignature("modifyReputation(address,int256)", _creator, _amount));
            require(success, "Reputation modifier call failed");
        } else {
            // Simple reputation update within this contract if no external modifier is set
            _creatorReputations[_creator] += _amount;
        }
    }

    /**
     * @dev Modifier to check if the caller is a moderator.
     */
    modifier onlyModerator() {
        bool isModerator = false;
        for (uint256 i = 0; i < _moderators.length; i++) {
            if (_moderators[i] == _msgSender()) {
                isModerator = true;
                break;
            }
        }
        require(isModerator, "Not a moderator");
        _;
    }

    /**
     * @inheritdoc ERC721
     * @dev Overrides the tokenURI function to dynamically generate metadata URI.
     *      This is a basic example, in a real application, you'd likely use a more sophisticated metadata service.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI(); // Inherited from ERC721, can be set to a base IPFS path or similar.
        string memory contentURI = _contentURIs[_tokenId];

        // **Dynamic Metadata Generation Logic (Simplified Example):**
        // In a real application, you would likely have a dedicated service (off-chain or on-chain via metadataUpdaterContract)
        // to generate richer metadata based on the contentURI and other NFT properties.
        string memory metadataJSON = string(abi.encodePacked(
            '{"name": "Dynamic Content NFT #', Strings.toString(_tokenId), '",',
            '"description": "A dynamically updatable content NFT.",',
            '"image": "', contentURI, '",', // Use contentURI as image or derive from it.
            '"category": "', _contentCategories[_tokenId], '",',
            '"tags": ["', joinStrings(_contentTags[_tokenId], '", "'), '"],',
            '"attributes": [',
            '{"trait_type": "Creator", "value": "', Strings.toHexString(uint160(_contentCreators[_tokenId])), '"},', // Creator address as attribute
            '{"trait_type": "Reputation", "value": "', Strings.toString(_creatorReputations[_contentCreators[_tokenId]]), '"}]',
            '}'
        ));

        string memory dataURI = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadataJSON))));
        return dataURI;
    }

    /**
     * @dev Helper function to join strings in an array for metadata.
     */
    function joinStrings(string[] memory strArray, string memory separator) internal pure returns (string memory) {
        if (strArray.length == 0) {
            return "";
        }
        string memory result = strArray[0];
        for (uint256 i = 1; i < strArray.length; i++) {
            result = string(abi.encodePacked(result, separator, strArray[i]));
        }
        return result;
    }

    // The following functions are overrides required by Solidity when extending ERC721URIStorage:
    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://your-base-metadata-uri/"; // Example base URI for metadata. Consider making this configurable.
    }
}

// --- Helper Libraries (Included for Completeness in a single file - In practice, import these) ---
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = 0;
            uint256 temp = value;
            while (temp != 0) {
                length++;
                temp /= 10;
            }
            string memory buffer = string(abi.encodePacked(new bytes(length)));
            uint256 ptr;
            assembly {
                ptr := add(buffer, 32)
            }
            while (value != 0) {
                ptr--;
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        return toHexString(value, 0);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with padding of length `length`.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        unchecked {
            for (uint256 i = 0; i < length; i++) {
                buffer[2 * length + 1 - 2 * i] = _SYMBOLS[value & 0xf];
                buffer[2 * length - 2 * i] = _SYMBOLS[(value >> 4) & 0xf];
                value >>= 8;
            }
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with checksum to its ASCII `string` representation.
     * CAUTION: CHECKSUM IS NOT VALIDATED.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * _ADDRESS_LENGTH + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        unchecked {
            for (uint256 i = 0; i < _ADDRESS_LENGTH; i++) {
                buffer[2 * _ADDRESS_LENGTH + 1 - 2 * i] = _SYMBOLS[uint8(uint160(addr) & 0xf)];
                buffer[2 * _ADDRESS_LENGTH - 2 * i] = _SYMBOLS[uint8((uint160(addr) >> 4) & 0xf)];
                addr = address(uint160(addr) >> 8);
            }
        }
        return string(buffer);
    }
}

library Base64 {
    string private constant _BASE64_ENCODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Encodes a byte array into a base64 string.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) {
            return "";
        }

        // Calculate the encoded length
        uint256 encodedLength = 4 * ((data.length + 2) / 3);

        // Allocate memory for the encoded string
        string memory encoded = string(abi.encodePacked(new bytes(encodedLength)));

        // Iterate over the input data in chunks of 3 bytes
        uint256 inputPtr;
        uint256 outputPtr;
        assembly {
            inputPtr := add(data, 32)
            outputPtr := add(encoded, 32)
        }

        for (uint256 i = 0; i < data.length; i += 3) {
            uint256 chunk;
            assembly {
                chunk := mload(inputPtr)
            }

            // Encode the 3-byte chunk into 4 base64 characters
            uint256 index0 = (chunk >> 18) & 0x3F;
            uint256 index1 = (chunk >> 12) & 0x3F;
            uint256 index2 = (chunk >> 6) & 0x3F;
            uint256 index3 = chunk & 0x3F;

            assembly {
                mstore8(outputPtr, byte(index0, _BASE64_ENCODE_CHARS))
                outputPtr := add(outputPtr, 1)
                mstore8(outputPtr, byte(index1, _BASE64_ENCODE_CHARS))
                outputPtr := add(outputPtr, 1)
            }

            if (i + 1 < data.length) {
                assembly {
                    mstore8(outputPtr, byte(index2, _BASE64_ENCODE_CHARS))
                    outputPtr := add(outputPtr, 1)
                }
            } else {
                assembly {
                    mstore8(outputPtr, byte(61, _BASE64_ENCODE_CHARS)) // '=' padding
                    outputPtr := add(outputPtr, 1)
                }
            }

            if (i + 2 < data.length) {
                assembly {
                    mstore8(outputPtr, byte(index3, _BASE64_ENCODE_CHARS))
                    outputPtr := add(outputPtr, 1)
                }
            } else {
                assembly {
                    mstore8(outputPtr, byte(61, _BASE64_ENCODE_CHARS)) // '=' padding
                    outputPtr := add(outputPtr, 1)
                }
            }

            assembly {
                inputPtr := add(inputPtr, 3)
            }
        }

        return encoded;
    }
}
```