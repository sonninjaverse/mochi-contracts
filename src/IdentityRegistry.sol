// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice Handle ownership for Mochi Network.
/// @dev Only the handle mapping is stored, because that is the only part a
///      ranking contract could ever need. Display name, avatar and bio live in
///      event data and are reconstructed by the indexer.
contract IdentityRegistry {
    error HandleTaken();
    error AlreadyRegistered();
    error EmptyHandle();
    error NotRegistered();

    mapping(bytes32 => address) public handleOwner;
    mapping(address => bytes32) public handleOf;

    event Registered(address indexed account, bytes32 indexed handle, string metadataURI);
    event MetadataUpdated(address indexed account, string metadataURI);

    function register(bytes32 handle, string calldata metadataURI) external {
        if (handle == bytes32(0)) revert EmptyHandle();
        if (handleOwner[handle] != address(0)) revert HandleTaken();
        if (handleOf[msg.sender] != bytes32(0)) revert AlreadyRegistered();

        handleOwner[handle] = msg.sender;
        handleOf[msg.sender] = handle;

        emit Registered(msg.sender, handle, metadataURI);
    }

    function setMetadata(string calldata metadataURI) external {
        if (handleOf[msg.sender] == bytes32(0)) revert NotRegistered();
        emit MetadataUpdated(msg.sender, metadataURI);
    }
}
