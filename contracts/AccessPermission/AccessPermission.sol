// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract AccessPermission is Ownable {
    using Address for address;

    mapping(address => bool) public sharedProxyAddresses;

    event AccessPermissionBought(
        address indexed buyer,
        address indexed creator,
        uint8 accessTypeIndex,
        uint256 endTimeStamp
    );

    event AccessPriceDuationUpdate(
        address indexed creator,
        uint8 accessTypeIndex,
        uint256 price,
        uint256 timeSpan
    );

    address public proxyRegistryAddress;

    // creator address => access index =>  address => permission's end timestamp
    mapping(address => mapping(uint8 => mapping(address => uint256)))
        private accessPermission;

    // creator address => access index => [price,timeSpan]
    mapping(address => mapping(uint8 => uint256[2]))
        private accessPriceDuration;

    /**
     * @dev Throws if called by any account other than the owner or their proxy
     */
    modifier onlyOwnerOrProxy() {
        require(
            _isOwnerOrProxy(msg.sender),
            "ERC1155Tradable#onlyOwner: CALLER_IS_NOT_OWNER"
        );
        _;
    }

    constructor(address _proxyRegistryAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function _isOwnerOrProxy(address _address) internal view returns (bool) {
        return owner() == _address || _isProxyForUser(owner(), _address);
    }

    function setAccessPriceDuration(
        address creator_,
        uint8 accessIndex,
        uint256 price,
        uint256 timeSpan
    ) public {
        require(
            creator_ == msg.sender || _isProxyForUser(creator_, msg.sender),
            "Only the creator or proxy can set access price "
        );

        accessPriceDuration[creator_][accessIndex] = [price, timeSpan];

        emit AccessPriceDuationUpdate(creator_, accessIndex, price, timeSpan);
    }

    function payForAccess(address creator_, uint8 accessIndex) public payable {
        uint256 price = accessPriceDuration[creator_][accessIndex][0];
        require(msg.value >= price, "Insufficient fund");

        uint256 permissionEndTimeStamp = accessPriceDuration[creator_][
            accessIndex
        ][1] + block.timestamp;

        accessPermission[creator_][accessIndex][
            msg.sender
        ] = permissionEndTimeStamp;

        bool sent = payable(msg.sender).send(price - msg.value);
        require(sent, "Failed to send remain Ether back");

        emit AccessPermissionBought(
            msg.sender,
            creator_,
            accessIndex,
            permissionEndTimeStamp
        );
    }

    /**
     * @dev Allows owner to add a shared proxy address
     */
    function addSharedProxyAddress(address _address) public onlyOwnerOrProxy {
        sharedProxyAddresses[_address] = true;
    }

    /**
     * @dev Allows owner to remove a shared proxy address
     */
    function removeSharedProxyAddress(address _address)
        public
        onlyOwnerOrProxy
    {
        delete sharedProxyAddresses[_address];
    }

    // Overrides ERC1155Tradable to allow a shared proxy address
    function _isProxyForUser(address _user, address _address)
        internal
        view
        returns (bool)
    {
        if (sharedProxyAddresses[_address]) {
            return true;
        }

        if (!proxyRegistryAddress.isContract()) {
            return false;
        }
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return address(proxyRegistry.proxies(_user)) == _address;
    }
}
