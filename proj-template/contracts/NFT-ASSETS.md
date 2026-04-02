# NFT 资源说明

## 概述

本项目共有 **11 个 NFT**（tokenId 0 ~ 10），每个 NFT 对应一张图片和一份 metadata JSON。最多只能 mint 11 个。

## 目录结构

```
contracts/
├── picture/          # NFT 图片文件（上传到 IPFS）
│   ├── 0
│   ├── 1
│   ├── ...
│   └── 10
├── metadata/         # NFT metadata JSON（上传到 IPFS）
│   ├── 0
│   ├── 1
│   ├── ...
│   └── 10
```

## 上传顺序

必须按以下顺序上传到 IPFS（如 Pinata）：

1. **先上传 `picture/` 文件夹** → 获得图片文件夹 CID
2. **将图片 CID 填入每个 metadata JSON 的 `image` 字段**
3. **再上传 `metadata/` 文件夹** → 获得 metadata 文件夹 CID
4. **将 metadata CID 填入合约部署脚本的 `baseURI`**

## IPFS CID

| 资源 | CID |
|------|-----|
| picture 图片文件夹 | `bafybeih4hnxcovl7brqn3rctldibnjcz3gm6xjo42nmzjhd3ajmtyil5jy` |
| metadata 元数据文件夹 | `bafybeifkoejunfwym5hd5zezaxnzitqpcbhtn33ffxq6hutqc4cj3le27y` |

## Metadata 格式

每个 metadata 文件为无扩展名的 JSON 文件，格式如下：

```json
{
  "name": "帝王池·酱香典藏 #0",
  "description": "源自茅台镇核心产区，采用传统坤沙工艺...",
  "image": "https://<gateway>/ipfs/<PICTURE_FOLDER_CID>/0"
}
```

- `name`: NFT 名称，带编号
- `description`: NFT 描述
- `image`: 指向 IPFS 上对应图片的完整 URL

## Mint 限制

当前合约 **没有 maxSupply 硬性限制**，理论上可以无限 mint。但由于只有 11 份 metadata 和图片（tokenId 0 ~ 10），超出部分的 `tokenURI` 将指向不存在的 IPFS 资源。

**建议**：mint 时控制 tokenId 不超过 10，或在合约中添加 `MAX_SUPPLY = 11` 的链上限制。

## 合约 baseURI

部署时 `baseURI` 设置为：

```
https://maroon-fast-porcupine-551.mypinata.cloud/ipfs/bafybeifkoejunfwym5hd5zezaxnzitqpcbhtn33ffxq6hutqc4cj3le27y/
```

合约通过 `baseURI + tokenId` 拼接生成每个 NFT 的 `tokenURI`。
