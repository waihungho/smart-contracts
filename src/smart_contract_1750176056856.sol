```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; // Adding burn capability

// Outline:
// 1. Contract Definition & Imports
// 2. State Variables (Core data storage, mappings for token-specific data, counters)
// 3. Events (Signaling key state changes)
// 4. Modifiers (Reusable access control and state checks)
// 5. Function Summary (Detailed list of all public/external functions)
// 6. Constructor
// 7. Core ERC721 Functions (Overrides and standard implementations)
// 8. Token Management Functions (Minting, Burning, Base URI)
// 9. ChronoSphere Data Management (Set, Get, Delete, Timestamps for data)
// 10. ChronoSphere Time & Reveal Mechanics (Setting reveal time, checking reveal status, time-based logic)
// 11. ChronoSphere State & Aging Mechanics (Sealing, Unsealing, Triggering evolution/aging based on time, stages)
// 12. ChronoSphere Agent Management (Granting specific permissions on tokens to other addresses)
// 13. ChronoSphere Query Functions (Getting state, checking data existence, getting rates)
// 14. Owner/Admin Functions (Global settings, withdrawal)

// Function Summary:
// (Includes standard ERC721/Ownable functions for the count + custom functions)

// Standard ERC721/Ownable:
// 1. constructor(): Initializes contract with name and symbol.
// 2. supportsInterface(bytes4 interfaceId): ERC165 standard.
// 3. balanceOf(address owner): Returns the number of tokens owned by an address.
// 4. ownerOf(uint256 tokenId): Returns the owner of a specific token.
// 5. approve(address to, uint256 tokenId): Grants approval for a specific token.
// 6. getApproved(uint256 tokenId): Returns the approved address for a token.
// 7. setApprovalForAll(address operator, bool approved): Grants/revokes approval for all tokens.
// 8. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all tokens.
// 9. transferFrom(address from, address to, uint256 tokenId): Transfers a token.
// 10. safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer.
// 11. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safe transfer with data.
// 12. renounceOwnership(): Renounces contract ownership.
// 13. transferOwnership(address newOwner): Transfers contract ownership.
// 14. name(): Returns token name.
// 15. symbol(): Returns token symbol.

// Custom & Overridden Functions:
// 16. mint(address to): Mints a new ChronoSphere token and assigns it to an address. Only callable by owner.
// 17. burn(uint256 tokenId): Burns/destroys a ChronoSphere token. Can be called by owner or approved/operator.
// 18. setBaseURI(string memory baseURI_): Sets the base URI for token metadata. Only callable by owner.
// 19. tokenURI(uint256 tokenId): Returns the URI for token metadata, intended to be dynamic based on token state.
// 20. setData(uint256 tokenId, string memory key, bytes memory value): Sets a piece of arbitrary key-value data for a token. Restricted by sealing, reveal, and access control.
// 21. getData(uint256 tokenId, string memory key): Retrieves the data associated with a key for a token.
// 22. deleteData(uint256 tokenId, string memory key): Deletes data associated with a key. Restricted by sealing, reveal, and access control.
// 23. getDataTimestamp(uint256 tokenId, string memory key): Gets the timestamp when data for a key was last set.
// 24. setRevealTime(uint256 tokenId, uint40 revealTimestamp): Sets a future timestamp after which the token is considered "revealed". Restricted access.
// 25. getRevealTime(uint256 tokenId): Gets the reveal timestamp for a token.
// 26. isRevealed(uint256 tokenId): Checks if the token's reveal timestamp has passed.
// 27. sealSphere(uint256 tokenId): Seals a ChronoSphere, preventing further data modification and certain actions. Restricted access.
// 28. unsealSphere(uint256 tokenId): Unseals a ChronoSphere. Restricted access, potentially time-locked based on reveal.
// 29. isSealed(uint256 tokenId): Checks if a ChronoSphere is currently sealed.
// 30. triggerAging(uint256 tokenId): Attempts to advance the age/stage of a ChronoSphere based on time elapsed and aging rate. Can potentially be called by anyone to push state forward.
// 31. getCurrentStage(uint256 tokenId): Gets the current evolutionary stage of a ChronoSphere.
// 32. setAgingRate(uint256 tokenId, uint256 rateInSeconds): Sets a specific aging rate for a token (seconds per stage). Restricted access.
// 33. getAgingRate(uint256 tokenId): Gets the specific aging rate for a token, falling back to the global rate if none is set.
// 34. addAgent(uint256 tokenId, address agent): Grants an address agent privileges for a specific token. Only callable by token owner.
// 35. removeAgent(uint256 tokenId, address agent): Revokes agent privileges for a specific token. Only callable by token owner.
// 36. isAgent(uint256 tokenId, address account): Checks if an address is an agent for a specific token.
// 37. checkDataExists(uint256 tokenId, string memory key): Checks if a specific data key has a value set for a token.
// 38. setContractAgingRate(uint256 rateInSeconds): Sets the default aging rate for all tokens unless overridden. Only callable by owner.
// 39. getContractAgingRate(): Gets the default contract aging rate.
// 40. withdrawEth(): Allows the contract owner to withdraw any accumulated ETH. (Assuming potential future payment features or accidental sends).

contract DigitalChronoSphere is ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Arbitrary key-value data storage per token
    mapping(uint256 => mapping(string => bytes)) private _tokenData;
    // Timestamps for when data was last set
    mapping(uint256 => mapping(string => uint40)) private _tokenDataTimestamps;

    // Reveal time for each token (0 if not set)
    mapping(uint256 => uint40) private _revealTimes;

    // Sealing status for each token
    mapping(uint256 => bool) private _isSealed;

    // Current stage/patina level for each token
    mapping(uint256 => uint256) private _currentStage;
    // Timestamp of the last successful aging trigger for a token
    mapping(uint256 => uint40) private _lastAgingTriggerTimestamp;

    // Specific aging rate per token (seconds per stage). 0 means use contract default.
    mapping(uint256 => uint256) private _tokenAgingRate;
    // Default aging rate for the contract (seconds per stage)
    uint256 private _contractAgingRate = 86400; // Default: 1 stage per day

    // Authorized agents per token (tokenId => agentAddress => isAgent)
    mapping(uint256 => mapping(address => bool)) private _agents;

    string private _baseURI;

    // --- Events ---

    event ChronoSphereMinted(uint256 indexed tokenId, address indexed owner);
    event DataUpdated(uint256 indexed tokenId, string key, address indexed updater);
    event DataDeleted(uint256 indexed tokenId, string key, address indexed deleter);
    event RevealTimeSet(uint256 indexed tokenId, uint40 revealTimestamp);
    event SphereSealed(uint256 indexed tokenId, address indexed operator);
    event SphereUnsealed(uint256 indexed tokenId, address indexed operator);
    event StageAdvanced(uint256 indexed tokenId, uint256 newStage);
    event AgingRateSet(uint256 indexed tokenId, uint256 rate);
    event ContractAgingRateSet(uint256 rate);
    event AgentAdded(uint256 indexed tokenId, address indexed agent, address indexed granter);
    event AgentRemoved(uint256 indexed tokenId, address indexed agent, address indexed revoker);

    // --- Modifiers ---

    modifier onlyTokenOwnerOrApprovedOrAgent(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) || _agents[tokenId][_msgSender()],
            "Not token owner, approved, or agent"
        );
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not token owner or approved"
        );
        _;
    }

    modifier onlyUnsealed(uint256 tokenId) {
        require(!_isSealed[tokenId], "Sphere is sealed");
        _;
    }

    modifier onlyRevealed(uint256 tokenId) {
        require(isRevealed(tokenId), "Sphere not yet revealed");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("DigitalChronoSphere", "CHRNS") Ownable(msg.sender) {}

    // --- Core ERC721 Functions (Standard and Overrides) ---

    // 1. constructor() - Handled above
    // 2. supportsInterface() - Provided by ERC721
    // 3. balanceOf() - Provided by ERC721
    // 4. ownerOf() - Provided by ERC721
    // 5. approve() - Provided by ERC721
    // 6. getApproved() - Provided by ERC721
    // 7. setApprovalForAll() - Provided by ERC721
    // 8. isApprovedForAll() - Provided by ERC721
    // 9. transferFrom() - Provided by ERC721
    // 10. safeTransferFrom() - Provided by ERC721
    // 11. safeTransferFrom(bytes) - Provided by ERC721
    // 12. renounceOwnership() - Provided by Ownable
    // 13. transferOwnership() - Provided by Ownable
    // 14. name() - Provided by ERC721
    // 15. symbol() - Provided by ERC721

    // 19. tokenURI - Overridden for dynamic metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        string memory base = _baseURI;
        if (bytes(base).length == 0) {
            return ""; // No base URI set
        }

        // Append token ID and potentially query parameters based on state
        string memory uri = string.concat(base, Strings.toString(tokenId));

        // Add state indicators as query parameters (e.g., ?sealed=true&revealed=false&stage=5)
        string memory params = "?";
        params = string.concat(params, "sealed=", _isSealed[tokenId] ? "true" : "false");
        params = string.concat(params, "&revealed=", isRevealed(tokenId) ? "true" : "false");
        params = string.concat(params, "&stage=", Strings.toString(_currentStage[tokenId]));
        // Add timestamp for potential time-based rendering hints
        params = string.concat(params, "&timestamp=", Strings.toString(block.timestamp));


        if (bytes(params).length > 1) { // If parameters were added
             uri = string.concat(uri, params);
        }

        // Note: An off-chain service at the base URI must interpret these parameters
        // and serve dynamic JSON metadata based on the on-chain state query.
        return uri;
    }


    // --- Token Management Functions ---

    // 16. mint - Mints a new token
    function mint(address to) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _lastAgingTriggerTimestamp[newTokenId] = uint40(block.timestamp); // Set initial aging timestamp
        emit ChronoSphereMinted(newTokenId, to);
    }

    // 17. burn - Burns a token (overrides ERC721Burnable)
    // ERC721Burnable already adds a burn function, so we just make sure it's callable
    // based on our access control logic if needed, or just use the library one.
    // The library one is permissioned for owner/approved, which is fine.

    // 18. setBaseURI - Sets the base metadata URI
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
        emit BaseURISet(baseURI_); // Standard event from ERC721/URIStorage? Let's add one if not.
    }
    event BaseURISet(string baseURI); // Custom event

    // --- ChronoSphere Data Management ---

    // 20. setData - Sets arbitrary key-value data for a token
    function setData(uint256 tokenId, string memory key, bytes memory value)
        public
        onlyTokenOwnerOrApprovedOrAgent(tokenId)
        onlyUnsealed(tokenId) // Cannot set data if sealed
        // Optionally add: onlyUnrevealed(tokenId) or apply stricter rules after reveal
    {
        _requireOwned(tokenId); // Ensure token exists

        _tokenData[tokenId][key] = value;
        _tokenDataTimestamps[tokenId][key] = uint40(block.timestamp);

        emit DataUpdated(tokenId, key, _msgSender());
    }

    // 21. getData - Retrieves arbitrary key-value data for a token
    function getData(uint256 tokenId, string memory key) public view returns (bytes memory) {
        _requireOwned(tokenId); // Ensure token exists
        return _tokenData[tokenId][key];
    }

    // 22. deleteData - Deletes arbitrary key-value data for a token
    function deleteData(uint256 tokenId, string memory key)
        public
        onlyTokenOwnerOrApprovedOrAgent(tokenId)
        onlyUnsealed(tokenId) // Cannot delete data if sealed
        // Optionally add: onlyUnrevealed(tokenId) or apply stricter rules after reveal
    {
        _requireOwned(tokenId); // Ensure token exists

        delete _tokenData[tokenId][key];
        delete _tokenDataTimestamps[tokenId][key];

        emit DataDeleted(tokenId, key, _msgSender());
    }

    // 23. getDataTimestamp - Gets the timestamp data was last set
    function getDataTimestamp(uint256 tokenId, string memory key) public view returns (uint40) {
        _requireOwned(tokenId); // Ensure token exists
        return _tokenDataTimestamps[tokenId][key];
    }

    // 37. checkDataExists - Checks if a key has data
    function checkDataExists(uint256 tokenId, string memory key) public view returns (bool) {
         _requireOwned(tokenId); // Ensure token exists
         bytes memory data = _tokenData[tokenId][key];
         return data.length > 0; // Simple check for non-empty bytes
    }


    // --- ChronoSphere Time & Reveal Mechanics ---

    // 24. setRevealTime - Sets the reveal timestamp
    function setRevealTime(uint256 tokenId, uint40 revealTimestamp)
        public
        onlyTokenOwnerOrApprovedOrAgent(tokenId)
    {
         _requireOwned(tokenId); // Ensure token exists
         // Can only set reveal time if it hasn't passed yet or wasn't set
         require(_revealTimes[tokenId] == 0 || _revealTimes[tokenId] > block.timestamp, "Reveal time already passed or set");
         require(revealTimestamp > block.timestamp, "Reveal time must be in the future");

        _revealTimes[tokenId] = revealTimestamp;
        emit RevealTimeSet(tokenId, revealTimestamp);
    }

    // 25. getRevealTime - Gets the reveal timestamp
    function getRevealTime(uint256 tokenId) public view returns (uint40) {
        _requireOwned(tokenId); // Ensure token exists
        return _revealTimes[tokenId];
    }

    // 26. isRevealed - Checks if reveal time has passed
    function isRevealed(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId); // Ensure token exists
        uint40 revealTime = _revealTimes[tokenId];
        // Token is revealed if revealTime is set and current block timestamp is >= revealTime
        return revealTime > 0 && block.timestamp >= revealTime;
    }

    // --- ChronoSphere State & Aging Mechanics ---

    // 27. sealSphere - Seals a token
    function sealSphere(uint256 tokenId)
        public
        onlyTokenOwnerOrApproved(tokenId) // Agents cannot seal/unseal
        onlyUnsealed(tokenId)
    {
         _requireOwned(tokenId); // Ensure token exists
        _isSealed[tokenId] = true;
        emit SphereSealed(tokenId, _msgSender());
    }

    // 28. unsealSphere - Unseals a token
    function unsealSphere(uint256 tokenId)
        public
        onlyTokenOwnerOrApproved(tokenId) // Agents cannot seal/unseal
    {
         _requireOwned(tokenId); // Ensure token exists
        require(_isSealed[tokenId], "Sphere is not sealed");

        // Optional advanced logic: require reveal before unsealing
        // require(isRevealed(tokenId), "Sphere must be revealed to unseal");

        _isSealed[tokenId] = false;
        emit SphereUnsealed(tokenId, _msgSender());
    }

    // 29. isSealed - Checks if a token is sealed
    function isSealed(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId); // Ensure token exists
        return _isSealed[tokenId];
    }

    // 30. triggerAging - Advances token stage based on time
    function triggerAging(uint256 tokenId) public {
        _requireOwned(tokenId); // Ensure token exists

        uint256 rate = getAgingRate(tokenId);
        if (rate == 0) {
            // No aging configured for this token or contract
            return;
        }

        uint40 lastTrigger = _lastAgingTriggerTimestamp[tokenId];
        uint256 timeElapsed = block.timestamp - lastTrigger;

        if (timeElapsed >= rate) {
            uint256 stagesToAdvance = timeElapsed / rate;
            _currentStage[tokenId] += stagesToAdvance;
            // Update the last trigger time based on the number of full periods passed
            _lastAgingTriggerTimestamp[tokenId] = uint40(lastTrigger + stagesToAdvance * rate);

            emit StageAdvanced(tokenId, _currentStage[tokenId]);
        }
        // If not enough time has passed, do nothing.
    }

    // 31. getCurrentStage - Gets the current aging stage
    function getCurrentStage(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Ensure token exists
        // Note: Stage might not be fully up-to-date if triggerAging hasn't been called recently.
        // A more complex version could calculate the *potential* current stage dynamically here.
        return _currentStage[tokenId];
    }

    // 32. setAgingRate - Sets a token-specific aging rate
    function setAgingRate(uint256 tokenId, uint256 rateInSeconds)
        public
        onlyTokenOwnerOrApprovedOrAgent(tokenId)
    {
         _requireOwned(tokenId); // Ensure token exists
        _tokenAgingRate[tokenId] = rateInSeconds;
        emit AgingRateSet(tokenId, rateInSeconds);
    }

    // 33. getAgingRate - Gets the effective aging rate (token-specific or contract default)
    function getAgingRate(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Ensure token exists
        uint256 tokenRate = _tokenAgingRate[tokenId];
        if (tokenRate > 0) {
            return tokenRate;
        }
        return _contractAgingRate; // Fallback to contract default
    }


    // --- ChronoSphere Agent Management ---

    // 34. addAgent - Grants agent status for a token
    function addAgent(uint256 tokenId, address agent)
        public
        onlyTokenOwnerOrApproved(tokenId) // Only owner or approved can add agents
    {
         _requireOwned(tokenId); // Ensure token exists
        require(agent != address(0), "Agent address cannot be zero");
        require(agent != ownerOf(tokenId), "Token owner is already privileged");
        require(!_agents[tokenId][agent], "Address is already an agent");

        _agents[tokenId][agent] = true;
        emit AgentAdded(tokenId, agent, _msgSender());
    }

    // 35. removeAgent - Revokes agent status for a token
    function removeAgent(uint256 tokenId, address agent)
        public
        onlyTokenOwnerOrApproved(tokenId) // Only owner or approved can remove agents
    {
         _requireOwned(tokenId); // Ensure token exists
        require(_agents[tokenId][agent], "Address is not an agent");

        _agents[tokenId][agent] = false;
        emit AgentRemoved(tokenId, agent, _msgSender());
    }

    // 36. isAgent - Checks if an address is an agent for a token
    function isAgent(uint256 tokenId, address account) public view returns (bool) {
         _requireOwned(tokenId); // Ensure token exists
        return _agents[tokenId][account];
    }


    // --- Owner/Admin Functions ---

    // 38. setContractAgingRate - Sets the default contract aging rate
    function setContractAgingRate(uint256 rateInSeconds) public onlyOwner {
        _contractAgingRate = rateInSeconds;
        emit ContractAgingRateSet(rateInSeconds);
    }

    // 39. getContractAgingRate - Gets the default contract aging rate
    function getContractAgingRate() public view returns (uint256) {
        return _contractAgingRate;
    }

    // 40. withdrawEth - Allows owner to withdraw ETH
    function withdrawEth() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    // --- Internal Helpers ---

    // Helper to check ownership or approval for a token
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }

    // Helper to ensure a token exists and is owned (useful for functions taking tokenId)
    function _requireOwned(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
         // ownerOf call internally checks for existence via _exists, so we only strictly need _exists call
         // if the function doesn't call ownerOf or another internal that checks.
         // For robustness in these custom functions, adding _exists check explicitly is clear.
    }

}
```