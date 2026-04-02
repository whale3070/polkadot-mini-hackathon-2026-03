// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract QuickNFT is ERC721, ReentrancyGuard {
    uint256 private _nextTokenId;

    string public author;
    address public publisher;
    string private _baseTokenURI;

    // 押金相关
    uint256 public pledgeAmount;
    mapping(uint256 => uint256) public pledges;
    mapping(uint256 => bool) public listedForSale;

    // 授权的 relayer（后端代付地址）
    mapping(address => bool) public authorizedRelayers;

    // Custom Errors
    error NotPublisher();
    error NotAuthorized();
    error InsufficientPledge(uint256 required, uint256 provided);
    error NotOwner(uint256 tokenId);
    error NotListed(uint256 tokenId);
    error CannotBuyOwnNFT();
    error PledgeReleaseFailed(address receiver, uint256 amount);
    error WithdrawFailed(address receiver, uint256 amount);
    error NoBalance();

    // Events（仅 address 类型加 indexed）
    event RelayerAuthorizationChanged(address indexed relayer, bool authorized);
    event PledgeLocked(uint256 tokenId, address indexed payer, uint256 amount);
    event PledgeReleased(uint256 tokenId, address indexed receiver, uint256 amount);
    event Listed(uint256 tokenId, address indexed seller);
    event ListingCancelled(uint256 tokenId, address indexed seller);
    event SoldWithPledge(uint256 tokenId, address indexed seller, address indexed buyer, uint256 amount);
    event EmergencyWithdraw(address indexed publisher, uint256 amount);

    modifier onlyPublisher() {
        if (msg.sender != publisher) revert NotPublisher();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != publisher && !authorizedRelayers[msg.sender]) revert NotAuthorized();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory author_,
        address publisher_,
        string memory baseURI_,
        address relayer_,
        uint256 pledgeAmount_
    ) ERC721(name_, symbol_) {
        author = author_;
        publisher = publisher_;
        _baseTokenURI = baseURI_;
        pledgeAmount = pledgeAmount_;

        if (relayer_ != address(0)) {
            authorizedRelayers[relayer_] = true;
            emit RelayerAuthorizationChanged(relayer_, true);
        }
    }

    /// @dev 铸造NFT给读者，调用方需附带押金
    /// @param to 接收NFT的读者地址
    function mint(address to) public payable onlyAuthorized {
        if (msg.value < pledgeAmount) revert InsufficientPledge(pledgeAmount, msg.value);
        uint256 tokenId = _nextTokenId;
        _safeMint(to, tokenId);
        pledges[tokenId] = msg.value;
        _nextTokenId++;
        emit PledgeLocked(tokenId, msg.sender, msg.value);
    }

    /// @dev 持有者将NFT挂售
    /// @param tokenId 要挂售的NFT编号
    function listForSale(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert NotOwner(tokenId);
        listedForSale[tokenId] = true;
        emit Listed(tokenId, msg.sender);
    }

    /// @dev 持有者取消挂售
    /// @param tokenId 要取消挂售的NFT编号
    function cancelListing(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert NotOwner(tokenId);
        listedForSale[tokenId] = false;
        emit ListingCancelled(tokenId, msg.sender);
    }

    /// @dev 买家付押金购买NFT，旧押金释放给卖家
    /// @param tokenId 要购买的NFT编号
    function buyWithPledge(uint256 tokenId) external payable nonReentrant {
        if (!listedForSale[tokenId]) revert NotListed(tokenId);
        if (msg.value < pledgeAmount) revert InsufficientPledge(pledgeAmount, msg.value);

        address seller = ownerOf(tokenId);
        if (seller == msg.sender) revert CannotBuyOwnNFT();

        uint256 oldPledge = pledges[tokenId];

        // 更新状态
        pledges[tokenId] = msg.value;
        listedForSale[tokenId] = false;

        // 转移NFT
        _transfer(seller, msg.sender, tokenId);

        // 释放旧押金给卖家
        (bool success, ) = payable(seller).call{value: oldPledge}("");
        if (!success) revert PledgeReleaseFailed(seller, oldPledge);

        emit PledgeReleased(tokenId, seller, oldPledge);
        emit PledgeLocked(tokenId, msg.sender, msg.value);
        emit SoldWithPledge(tokenId, seller, msg.sender, msg.value);
    }

    /// @dev 设置 relayer 授权状态
    /// @param relayer relayer 地址
    /// @param authorized 是否授权
    function setRelayer(address relayer, bool authorized) external onlyPublisher {
        authorizedRelayers[relayer] = authorized;
        emit RelayerAuthorizationChanged(relayer, authorized);
    }

    /// @dev 查询已铸造的NFT总数
    function totalSales() external view returns (uint256) {
        return _nextTokenId;
    }

    /// @dev 查询下一个将铸造的tokenId
    function nextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    /// @dev 紧急提取合约全部余额，仅 publisher 可调用
    function emergencyWithdraw() external onlyPublisher nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoBalance();

        (bool success, ) = payable(publisher).call{value: balance}("");
        if (!success) revert WithdrawFailed(publisher, balance);

        emit EmergencyWithdraw(publisher, balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev 接收原生代币（如 PAS），用于「二次激活」时用户直接向合约地址转账
    receive() external payable {}
}
