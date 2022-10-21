// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AssetContract.sol";
import "./TokenIdentifiers.sol";

/**
 * @title AssetContractShared
 * OpenSea shared asset contract - A contract for easily creating custom assets on OpenSea
 */
contract AssetContractShared is AssetContract, ReentrancyGuard {
    mapping(address => bool) public sharedProxyAddresses;

    struct Ownership {
        uint256 id;
        address owner;
    }

    // creator address => access index =>  address => permission's end timestamp
    mapping(address => mapping(uint8 => mapping(address => uint256)))
        private accessPermission;

    // creator address => access index => [price,timeSpan]
    mapping(address => mapping(uint8 => uint256[2]))
        private accessPriceDuration;

    using TokenIdentifiers for uint256;

    event CreatorChanged(uint256 indexed _id, address indexed _creator);

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

    mapping(uint256 => address) internal _creatorOverride;

    /**
     * @dev Require msg.sender to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            _isCreatorOrProxy(_id, _msgSender()),
            "AssetContractShared#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    /**
     * @dev Require the caller to own the full supply of the token
     */
    modifier onlyFullTokenOwner(uint256 _id) {
        require(
            _ownsTokenAmount(_msgSender(), _id, _id.tokenMaxSupply()),
            "AssetContractShared#onlyFullTokenOwner: ONLY_FULL_TOKEN_OWNER_ALLOWED"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _templateURI
    ) AssetContract(_name, _symbol, _proxyRegistryAddress, _templateURI) {}

    /**
     * @dev Allows owner to change the proxy registry
     */
    function setProxyRegistryAddress(address _address) public onlyOwnerOrProxy {
        proxyRegistryAddress = _address;
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

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _quantity,
        bytes memory _data
    ) public override nonReentrant creatorOnly(_tokenId) {
        super.mint(_to, _tokenId, _quantity, _data);
    }

    function batchMint(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _quantities,
        bytes memory _data
    ) public override nonReentrant {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _isCreatorOrProxy(_tokenIds[i], _msgSender()),
                "AssetContractShared#_batchMint: ONLY_CREATOR_ALLOWED"
            );
        }

        (
            uint256[] memory _mainCollectionIdLs,
            uint256[] memory _subCollectionIdLs,
            bytes[] memory _dataLs
        ) = parseData2DataLs(_data);
        require(
            _mainCollectionIdLs.length == _subCollectionIdLs.length &&
                _subCollectionIdLs.length == _dataLs.length &&
                _subCollectionIdLs.length == _quantities.length,
            "Wrong array length"
        );

        _batchMint(
            _to,
            _mainCollectionIdLs,
            _subCollectionIdLs,
            _tokenIds,
            _quantities,
            _dataLs
        );
    }

    /////////////////////////////////
    // CONVENIENCE CREATOR METHODS //
    /////////////////////////////////

    /**
     * @dev Will update the URI for the token
     * @param _id The token ID to update. msg.sender must be its creator, the uri must be impermanent,
     *            and the creator must own all of the token supply
     * @param _uri New URI for the token.
     */
    function setURI(uint256 _id, string memory _uri)
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwner(_id)
    {
        _setURI(_id, _uri);
    }

    /**
     * @dev setURI, but permanent
     */
    function setPermanentURI(uint256 _id, string memory _uri)
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwner(_id)
    {
        _setPermanentURI(_id, _uri);
    }

    /**
     * @dev Change the creator address for given token
     * @param _to   Address of the new creator
     * @param _id  Token IDs to change creator of
     */
    function setCreator(uint256 _id, address _to) public creatorOnly(_id) {
        require(
            _to != address(0),
            "AssetContractShared#setCreator: INVALID_ADDRESS."
        );
        _creatorOverride[_id] = _to;
        emit CreatorChanged(_id, _to);
    }

    /**
     * @dev Get the creator for a token
     * @param _id   The token id to look up
     */
    function creator(uint256 _id) public view returns (address) {
        if (_creatorOverride[_id] != address(0)) {
            return _creatorOverride[_id];
        } else {
            return _id.tokenCreator();
        }
    }

    /**
     * @dev Get the maximum supply for a token
     * @param _id   The token id to look up
     */
    function maxSupply(uint256 _id) public pure returns (uint256) {
        return _id.tokenMaxSupply();
    }

    // Override ERC1155Tradable for birth events
    function _origin(uint256 _id) internal pure override returns (address) {
        return _id.tokenCreator();
    }

    function _requireMintable(address _address, uint256 _id) internal view {
        require(
            _isCreatorOrProxy(_id, _address),
            "AssetContractShared#_requireMintable: ONLY_CREATOR_ALLOWED"
        );
    }

    function _remainingSupply(uint256 _id)
        internal
        view
        override
        returns (uint256)
    {
        return maxSupply(_id) - totalSupply(_id);
    }

    function _isCreatorOrProxy(uint256 _id, address _address)
        internal
        view
        override
        returns (bool)
    {
        address creator_ = creator(_id);
        return creator_ == _address || _isProxyForUser(creator_, _address);
    }

    // Overrides ERC1155Tradable to allow a shared proxy address
    function _isProxyForUser(address _user, address _address)
        internal
        view
        override
        returns (bool)
    {
        if (sharedProxyAddresses[_address]) {
            return true;
        }
        return super._isProxyForUser(_user, _address);
    }

    function setAccessPriceDuration(
        address creator_,
        uint8 accessIndex,
        uint256 price,
        uint256 timeSpan
    ) public {
        require(
            creator_ == msgSender() || _isProxyForUser(creator_, msgSender()),
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
}
