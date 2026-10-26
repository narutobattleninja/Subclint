// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
    Dark Node — 1111 oracle NFTs on BNB Chain
    Free Mint : 0.0005 BNB each, max 4 per wallet
    Paid Mint : 0.001  BNB each, max 10 per wallet
    Shared supply: 1111
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DarkNode is ERC721, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1111;

    uint256 public constant FREE_PRICE = 0.0005 ether; // 0.0005 BNB
    uint256 public constant FREE_MAX_PER_WALLET = 4;

    uint256 public constant PAID_PRICE = 0.001 ether;  // 0.001 BNB
    uint256 public constant PAID_MAX_PER_WALLET = 10;

    uint256 public totalSupply;

    bool public freeMintOpen;
    bool public paidMintOpen;
    bool public revealed;

    string private baseURI;        // e.g. ipfs://<CID>/  -> ipfs://<CID>/1.json
    string private unrevealedURI;  // e.g. ipfs://<CID>/hidden.json

    mapping(address => uint256) public freeMinted;
    mapping(address => uint256) public paidMinted;

    event Minted(address indexed to, uint256 firstId, uint256 quantity, bool free);

    error SoldOut();
    error MintClosed();
    error WalletLimit();
    error WrongPayment();
    error ZeroQuantity();

    constructor(string memory _unrevealedURI, address royaltyReceiver)
        ERC721("Dark Node", "DNODE")
        Ownable(msg.sender)
    {
        unrevealedURI = _unrevealedURI;
        _setDefaultRoyalty(royaltyReceiver, 500); // 5% royalty
    }

    // ---------------- Mint ----------------

    function freeMint(uint256 quantity) external payable nonReentrant {
        if (!freeMintOpen) revert MintClosed();
        if (quantity == 0) revert ZeroQuantity();
        if (freeMinted[msg.sender] + quantity > FREE_MAX_PER_WALLET) revert WalletLimit();
        if (msg.value != FREE_PRICE * quantity) revert WrongPayment();
        freeMinted[msg.sender] += quantity;
        _mintMany(msg.sender, quantity, true);
    }

    function paidMint(uint256 quantity) external payable nonReentrant {
        if (!paidMintOpen) revert MintClosed();
        if (quantity == 0) revert ZeroQuantity();
        if (paidMinted[msg.sender] + quantity > PAID_MAX_PER_WALLET) revert WalletLimit();
        if (msg.value != PAID_PRICE * quantity) revert WrongPayment();
        paidMinted[msg.sender] += quantity;
        _mintMany(msg.sender, quantity, false);
    }

    function _mintMany(address to, uint256 quantity, bool free) internal {
        uint256 start = totalSupply + 1;
        if (totalSupply + quantity > MAX_SUPPLY) revert SoldOut();
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, start + i);
        }
        totalSupply += quantity;
        emit Minted(to, start, quantity, free);
    }

    /// Team reserve / giveaways for KOLs (counts toward the 1111).
    function ownerMint(address to, uint256 quantity) external onlyOwner {
        _mintMany(to, quantity, false);
    }

    // ---------------- Metadata ----------------

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        if (!revealed) return unrevealedURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    // ---------------- Admin ----------------

    function setMintOpen(bool _free, bool _paid) external onlyOwner {
        freeMintOpen = _free;
        paidMintOpen = _paid;
    }

    function reveal(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        revealed = true;
    }

    function setUnrevealedURI(string calldata _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setRoyalty(address receiver, uint96 bps) external onlyOwner {
        _setDefaultRoyalty(receiver, bps);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool ok, ) = payable(owner()).call{value: address(this).balance}("");
        require(ok, "withdraw failed");
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC2981) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
