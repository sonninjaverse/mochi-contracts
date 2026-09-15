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
    event HandleChanged(address indexed account, bytes32 indexed from, bytes32 indexed to);
    event MetadataUpdated(address indexed account, string metadataURI);

    function register(bytes32 handle, string calldata metadataURI) external {
        if (handle == bytes32(0)) revert EmptyHandle();
        if (handleOwner[handle] != address(0)) revert HandleTaken();
        if (handleOf[msg.sender] != bytes32(0)) revert AlreadyRegistered();

        handleOwner[handle] = msg.sender;
        handleOf[msg.sender] = handle;

        emit Registered(msg.sender, handle, metadataURI);
    }

    /// @notice Trades the caller's handle for a different one.
    /// @dev The old name is released in the same call that takes the new one.
    ///      Doing it in either order alone would leave a name stranded or an
    ///      account holding two, and uniqueness is the only thing this
    ///      contract exists to guarantee.
    function changeHandle(bytes32 newHandle) external {
        if (newHandle == bytes32(0)) revert EmptyHandle();

        bytes32 current = handleOf[msg.sender];
        if (current == bytes32(0)) revert NotRegistered();
        // Covers renaming to your own name, which would otherwise free and
        // retake it — a no-op with a gap in the middle.
        if (handleOwner[newHandle] != address(0)) revert HandleTaken();

        delete handleOwner[current];
        handleOwner[newHandle] = msg.sender;
        handleOf[msg.sender] = newHandle;

        emit HandleChanged(msg.sender, current, newHandle);
    }

    function setMetadata(string calldata metadataURI) external {
        if (handleOf[msg.sender] == bytes32(0)) revert NotRegistered();
        emit MetadataUpdated(msg.sender, metadataURI);
    }
}
