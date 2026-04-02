// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {QuickNFT} from "./QuickNFT.sol";

/**
 * @title BookFactory
 * @dev 工厂合约 - 出版社通过此合约部署新书的 NFT 合约
 */
contract BookFactory {
    // 收款地址（平台方）
    address public treasury;
    // 部署费用（单位：Wei）
    uint256 public deployFee;

    // 所有已部署的书籍合约
    address[] public deployedBooks;
    // 出版社地址 => 其部署的书籍合约列表
    mapping(address => address[]) public publisherBooks;

    struct BookInfo {
        string name;
        string symbol;
        string author;
        address publisher;
        uint256 deployedAt;
    }
    mapping(address => BookInfo) public bookInfo;

    event BookDeployed(
        address indexed bookContract,
        address indexed publisher,
        string name,
        string symbol,
        string author
    );
    event DeployFeeUpdated(uint256 oldFee, uint256 newFee);
    event TreasuryUpdated(address oldTreasury, address newTreasury);

    constructor(address _treasury, uint256 _deployFee) {
        require(_treasury != address(0), "Invalid treasury address");
        treasury = _treasury;
        deployFee = _deployFee;
    }

    /**
     * @dev 部署新书 NFT 合约
     */
    function deployBook(
        string memory bookName,
        string memory symbol,
        string memory authorName,
        string memory baseURI,
        address relayer,
        uint256 pledgeAmount
    ) external payable returns (address) {
        require(msg.value >= deployFee, "Insufficient deploy fee");
        require(bytes(bookName).length > 0, "Book name required");
        require(bytes(symbol).length > 0, "Symbol required");

        QuickNFT newBook = new QuickNFT(
            bookName,
            symbol,
            authorName,
            msg.sender,
            baseURI,
            relayer,
            pledgeAmount
        );

        address bookAddress = address(newBook);

        // 记录书籍信息
        deployedBooks.push(bookAddress);
        publisherBooks[msg.sender].push(bookAddress);
        bookInfo[bookAddress] = BookInfo({
            name: bookName,
            symbol: symbol,
            author: authorName,
            publisher: msg.sender,
            deployedAt: block.timestamp
        });

        // 转账给平台
        if (msg.value > 0) {
            (bool success, ) = payable(treasury).call{value: msg.value}("");
            require(success, "Transfer failed");
        }

        emit BookDeployed(bookAddress, msg.sender, bookName, symbol, authorName);
        return bookAddress;
    }

    function totalBooks() external view returns (uint256) {
        return deployedBooks.length;
    }

    function getPublisherBooks(address publisher) external view returns (address[] memory) {
        return publisherBooks[publisher];
    }

    function getBookSales(address bookContract) external view returns (uint256) {
        return QuickNFT(payable(bookContract)).totalSales();
    }

    function updateDeployFee(uint256 newFee) external {
        require(msg.sender == treasury, "Only treasury");
        emit DeployFeeUpdated(deployFee, newFee);
        deployFee = newFee;
    }

    function updateTreasury(address newTreasury) external {
        require(msg.sender == treasury, "Only treasury");
        require(newTreasury != address(0), "Invalid address");
        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
    }

    receive() external payable {}
}
