// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BookFactory} from "../src/BookFactory.sol";
import {QuickNFT} from "../src/QuickNFT.sol";

// 部署
// cd d:/项目/NFT/proj-template/contracts
// source .env

// forge script script/Deploy.s.sol:DeployScript \
//   --rpc-url $Polkadot_Test_Rpc \
//   --broadcast \
//   -vvvv

// 重新部署NFT合约
// cast send $BookFactory \
//   "deployBook(string,string,string,string,address,uint256)" \
//   "Imperial Pool Book" "IPB" "Red Bank Blockchain" \
//   "https://maroon-fast-porcupine-551.mypinata.cloud/ipfs/bafybeifkoejunfwym5hd5zezaxnzitqpcbhtn33ffxq6hutqc4cj3le27y/" \
//   0x0179e5f250Ae3f77457dc608155DbB0E03918CB2 \
//   0 \
//   --private-key $Private_Key \
//   --rpc-url $Polkadot_Test_Rpc

// mint NFT 方法
// source .env
// cast send $QuickNFT \
//   "mint(address)" 0x0179e5f250Ae3f77457dc608155DbB0E03918CB2 \
//   --private-key $Private_Key \
//   --rpc-url $Polkadot_Test_Rpc

// # 查看工厂部署的第一本书的地址（index 0）
// cast call $BookFactory "deployedBooks(uint256)(address)" 0 --rpc-url $Polkadot_Test_Rpc


// # 先查 QuickNFT 地址
// cast call $BookFactory "deployedBooks(uint256)(address)" 0 --rpc-url $Polkadot_Test_Rpc

// # 查看 tokenURI（把地址替换为上面返回的）
// cast call 0xeaD6C430cFe45A28397e7A642137a6C03E16aeDF "tokenURI(uint256)(string)" 0 --rpc-url $Polkadot_Test_Rpc

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("Private_Key");
        address deployer = vm.envAddress("Depolyer_Address");

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 BookFactory（treasury 用部署者地址，deployFee 设 0 用于测试）
        BookFactory factory = new BookFactory(deployer, 0);
        console.log("BookFactory deployed at:", address(factory));

        // 2. 通过 Factory 部署一本书的 QuickNFT
        // TODO: 替换为你的 metadata 文件夹 IPFS 地址（末尾带 /）
        string memory baseURI = "https://maroon-fast-porcupine-551.mypinata.cloud/ipfs/bafybeifkoejunfwym5hd5zezaxnzitqpcbhtn33ffxq6hutqc4cj3le27y/";

        address bookAddress = factory.deployBook(
            "Imperial Pool Book",      // 书名
            "IPB",               // symbol
            "Red Bank Blockchain",        // 作者名
            baseURI,              // metadata baseURI
            deployer,             // relayer 地址（测试用部署者）
            0 ether            // 押金金额
        );
        console.log("QuickNFT deployed at:", bookAddress);

        // 3. 测试铸造一个 NFT 给部署者
        QuickNFT book = QuickNFT(payable(bookAddress));
        book.mint(deployer);
        console.log("Minted tokenId 0 to:", deployer);

        // 4. 验证 tokenURI
        string memory uri = book.tokenURI(0);
        console.log("tokenURI(0):", uri);

        vm.stopBroadcast();
    }
}
