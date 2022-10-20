// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is
    ContextMixin,
    ERC1155,
    NativeMetaTransaction,
    Ownable,
    Pausable
{
    using Address for address;

    // Proxy registry address
    address public proxyRegistryAddress;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    /*
        DESIGN NOTES:
        mapping from mainCollectionId => subCollectionId => tokenId => ownerAddress => balance

        mainCollectionId subCollectionId are a concatenation of:
        * creator: hex address of the creator of the token. 160 bits
        * index: 96 bits
        
        tokenId are a concatenation of:
        * creator: hex address of the creator of the token. 160 bits
        * index of asset category. 56 bits.
        * supply: Supply cap for this token, up to 2^40 - 1 (1 trillion).  40 bits
    */
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(address => uint256))))
        private balances;

    mapping(uint256 => uint256) private _supply;

    // tokenId to [mainCollectionId,subCollectionId]
    mapping(uint256 => uint256[2]) private _idPath;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(name);
    }

    /**
     * @dev Throws if called by any account other than the owner or their proxy
     */
    modifier onlyOwnerOrProxy() {
        require(
            _isOwnerOrProxy(_msgSender()),
            "ERC1155Tradable#onlyOwner: CALLER_IS_NOT_OWNER"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than _from or their proxy
     */
    modifier onlyApproved(address _from) {
        require(
            _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
            "ERC1155Tradable#onlyApproved: CALLER_NOT_ALLOWED"
        );
        _;
    }

    function _isOwnerOrProxy(address _address) internal view returns (bool) {
        return owner() == _address || _isProxyForUser(owner(), _address);
    }

    function pause() external onlyOwnerOrProxy {
        _pause();
    }

    function unpause() external onlyOwnerOrProxy {
        _unpause();
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );

        uint256[2] memory idPath = _idPath[tokenId];

        return balances[idPath[0]][idPath[1]][tokenId][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory tokenIds
    ) public view virtual override returns (uint256[] memory) {
        require(
            accounts.length == tokenIds.length,
            "ERC1155: accounts and mainCollectionIds and tokenIds length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], tokenIds[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return _supply[_id];
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contracts for easy trading.
        if (_isProxyForUser(_owner, _operator)) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual override whenNotPaused onlyApproved(from) {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        // _beforeTokenTransfer(
        //     operator,
        //     from,
        //     to,
        //     asSingletonArray(tokenId),
        //     asSingletonArray(amount),
        //     data
        // );

        uint256[2] memory idPath = _idPath[tokenId];
        uint256 fromBalance = balances[idPath[0]][idPath[1]][tokenId][from];

        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        balances[idPath[0]][idPath[1]][tokenId][from] = fromBalance - amount;
        balances[idPath[0]][idPath[1]][tokenId][from] += amount;

        emit TransferSingle(operator, from, to, tokenId, amount);

        doSafeTransferAcceptanceCheck(
            operator,
            from,
            to,
            tokenId,
            amount,
            data
        );
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override whenNotPaused onlyApproved(from) {
        require(
            tokenIds.length == amounts.length,
            "ERC1155: IDS_AMOUNTS_LENGTH_MISMATCH"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            uint256[2] memory idPath = _idPath[tokenId];
            uint256 fromBalance = balances[idPath[0]][idPath[1]][tokenId][from];

            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );

            balances[idPath[0]][idPath[1]][tokenId][from] =
                fromBalance -
                amount;
            balances[idPath[0]][idPath[1]][tokenId][from] += amount;
        }

        emit TransferBatch(operator, from, to, tokenIds, amounts);

        doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            tokenIds,
            amounts,
            data
        );
    }

    /**
     * @dev Hook to be called right before minting
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     */
    function _beforeMint(uint256 _id, uint256 _quantity) internal virtual {}

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to                 Address of the future owner of the token
     * @param _tokenId                 Token ID to mint
     * @param _quantity           Amount of tokens to mint
     * @param _data               Data to pass if receiver is contract
     */
    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _quantity,
        bytes memory _data
    ) public virtual onlyOwnerOrProxy {
        (
            uint256 _mainCollectionId,
            uint256 _subCollectionId,
            bytes memory _uri
        ) = parseData2PathUri(_data);

        _mint(
            _to,
            _mainCollectionId,
            _subCollectionId,
            _tokenId,
            _quantity,
            _uri
        );
    }

    /**
     * @dev Mint tokens for each id in _ids
     * @param _to          The address to mint tokens to
     * @param _ids         Array of ids to mint
     * @param _quantities  Array of amounts of tokens to mint per id
     * @param _data        Data to pass if receiver is contract
     */
    function batchMint(
        address _to,
        uint256[] memory _mainCollectionIds,
        uint256[] memory _subCollectionIds,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public virtual onlyOwnerOrProxy {
        _batchMint(
            _to,
            _mainCollectionIds,
            _subCollectionIds,
            _ids,
            _quantities,
            _data
        );
    }

    /**
     * @dev Burns amount of a given token id
     * @param _from          The address to burn tokens from
     * @param _tokenId          Token ID to burn
     * @param _quantity    Amount to burn
     */
    function burn(
        address _from,
        uint256 _tokenId,
        uint256 _quantity
    ) public virtual onlyApproved(_from) {
        _burn(_from, _tokenId, _quantity);
    }

    /**
     * @dev Burns tokens for each id in _ids
     * @param _from          The address to burn tokens from
     * @param _tokenIds         Array of token ids to burn
     * @param _quantities  Array of the amount to be burned
     */
    function batchBurn(
        address _from,
        uint256[] memory _tokenIds,
        uint256[] memory _quantities
    ) public virtual onlyApproved(_from) {
        _burnBatch(_from, _tokenIds, _quantities);
    }

    /**
     * @dev Returns whether the specified token is minted
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function exists(uint256 _id) public view returns (bool) {
        return _supply[_id] > 0;
    }

    // Overrides ERC1155 _mint to allow changing birth events to creator transfers,
    // and to set _supply
    function _mint(
        address _to,
        uint256 _mainCollectionId,
        uint256 _subCollectionId,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal virtual whenNotPaused {
        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            _to,
            asSingletonArray(_id),
            asSingletonArray(_amount),
            _data
        );

        // _beforeMint(_id, _amount);

        // Add _amount
        balances[_mainCollectionId][_subCollectionId][_id][_to] += _amount;
        _supply[_id] += _amount;

        // Origin of token will be the _from parameter
        address origin = _origin(_id);

        // Emit event
        emit TransferSingle(operator, origin, _to, _id, _amount);

        // Calling onReceive method if recipient is contract
        doSafeTransferAcceptanceCheck(
            operator,
            origin,
            _to,
            _id,
            _amount,
            _data
        );
    }

    // Overrides ERC1155MintBurn to change the batch birth events to creator transfers, and to set _supply
    function _batchMint(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual whenNotPaused {
        require(
            _tokenIds.length == _amounts.length,
            "ERC1155Tradable#batchMint: INVALID_ARRAYS_LENGTH"
        );

        bytes[] memory _dataLs = parseData2DataLs(_data);

        // Number of mints to execute
        uint256 nMint = _tokenIds.length;

        // Origin of tokens will be the _from parameter
        address origin = _origin(_tokenIds[0]);

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            _to,
            _tokenIds,
            _amounts,
            _data
        );

        // Executing all minting
        for (uint256 i = 0; i < nMint; i++) {
            (
                uint256 mainCollectionId,
                uint256 subCollectionId
            ) = parseData2DataLs(_dataLs[i]);
            uint256 tokenId = _tokenIds[i];
            uint256 amount = _amounts[i];

            _beforeMint(tokenId, amount);
            require(
                _origin(tokenId) == origin &&
                    _origin(mainCollectionId) == origin &&
                    _origin(subCollectionId) == origin,
                "ERC1155Tradable#batchMint: MULTIPLE_ORIGINS_NOT_ALLOWED"
            );
            // Update storage balance
            balances[mainCollectionId][subCollectionId][tokenId][_to] += amount;
            _supply[tokenId] += amount;
        }

        // Emit batch mint event
        emit TransferBatch(operator, origin, _to, _tokenIds, _amounts);

        // Calling onReceive method if recipient is contract
        doSafeBatchTransferAcceptanceCheck(
            operator,
            origin,
            _to,
            _tokenIds,
            _amounts,
            _data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal override whenNotPaused {
        require(account != address(0), "ERC1155#_burn: BURN_FROM_ZERO_ADDRESS");
        require(amount > 0, "ERC1155#_burn: AMOUNT_LESS_THAN_ONE");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            asSingletonArray(tokenId),
            asSingletonArray(amount),
            ""
        );

        uint256[2] memory idPath = _idPath[tokenId];
        uint256 accountBalance = balances[idPath[0]][idPath[1]][tokenId][
            account
        ];

        require(
            accountBalance >= amount,
            "ERC1155#_burn: AMOUNT_EXCEEDS_BALANCE"
        );

        balances[idPath[0]][idPath[1]][tokenId][account] =
            accountBalance -
            amount;
        _supply[tokenId] -= amount;

        emit TransferSingle(operator, account, address(0), tokenId, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal override whenNotPaused {
        require(account != address(0), "ERC1155: BURN_FROM_ZERO_ADDRESS");
        require(
            tokenIds.length == amounts.length,
            "ERC1155: IDS_AMOUNTS_LENGTH_MISMATCH"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            tokenIds,
            amounts,
            ""
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            uint256[2] memory idPath = _idPath[tokenId];

            uint256 accountBalance = balances[idPath[0]][idPath[1]][tokenId][
                account
            ];
            require(
                accountBalance >= amount,
                "ERC1155#_burnBatch: AMOUNT_EXCEEDS_BALANCE"
            );
            balances[idPath[0]][idPath[1]][tokenId][account] =
                accountBalance -
                amount;
            _supply[tokenId] -= amount;
        }

        emit TransferBatch(operator, account, address(0), tokenIds, amounts);
    }

    // Override this to change birth events' _from address
    function _origin(
        uint256 /* _id */
    ) internal view virtual returns (address) {
        return address(0);
    }

    // PROXY HELPER METHODS

    function _isProxyForUser(address _user, address _address)
        internal
        view
        virtual
        returns (bool)
    {
        if (!proxyRegistryAddress.isContract()) {
            return false;
        }
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return address(proxyRegistry.proxies(_user)) == _address;
    }

    // Copied from OpenZeppelin
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c3ae4790c71b7f53cc8fff743536dcb7031fed74/contracts/token/ERC1155/ERC1155.sol#L394
    function doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    // Copied from OpenZeppelin
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c3ae4790c71b7f53cc8fff743536dcb7031fed74/contracts/token/ERC1155/ERC1155.sol#L417
    function doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    // Copied from OpenZeppelin
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c3ae4790c71b7f53cc8fff743536dcb7031fed74/contracts/token/ERC1155/ERC1155.sol#L440
    function asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function parseData2PathUri(bytes memory data)
        public
        pure
        returns (
            uint256 mainCollectionId,
            uint256 subCollectionId,
            bytes memory uri
        )
    {
        (mainCollectionId, subCollectionId, uri) = abi.decode(
            data,
            (uint256, uint256, bytes)
        );
    }

    function parseData2DataLs(bytes memory data)
        public
        pure
        returns (bytes[] dataLs)
    {
        (dataLs) = abi.decode(data, (bytes[]));
    }
}
