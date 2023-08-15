//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// help us to use console to debug
import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {

  constructor() ERC721("NFTMarketplace", "NFTM") {
    owner = payable(msg.sender);
  }

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;  //_tokenId keeps track of minted nfts
  Counters.Counter private _itemsSold; //keeps track of number of items sold

  address payable owner; //owner is the contract address that created the contract
  uint256 listPrice = 0.01 ether; // fee charged by the marketplace

  // structure to store info about listed token
  struct ListedToken {
    uint256 tokenId;
    address payable owner;
    address payable seller;
    uint256 price;
    bool currentlyListed;
  }

  //event to emit when token is successfully listed
  event TokenListedSuccess (
    uint256 indexed tokenId,
    address owner,
    address seller,
    uint256 price,
    bool currentlyListed
  );

  //a mapping that maps tokenId to token info, can be used to retrive details about tokenId
  mapping(uint256 => ListedToken) private idToListedToken;


  //first time a token is created it is listed here
  function createToken(string memory tokenURI, uint256 price)
    public payable returns (uint) {
      _tokenIds.increment(); //incrment tokenId counter
      uint256 newTokenId = _tokenIds.current();

      //Mint the nft with tokenId to the address who called createToken
      _safeMint(msg.sender, newTokenId);
    
      //Map the tokenId to the tokenURI(IPFS url)
      _setTokenURI(newTokenId, tokenURI);

      //a function to update global variables and emit events
      createListedToken(newTokenId, price);

      return newTokenId;
    }

  function createListedToken(uint256 tokenId, uint256 price) private {
    //make sure sender senr enought ETH to pay for listing
    require(msg.value == listPrice, "Please sent the correct price");
    require(price > 0, "Make sure price isnt negative");

    //update mapping of tokenIf to toke details
    idToListedToken[tokenId] = ListedToken(
      tokenId,
      payable(address(this)),
      payable(msg.sender),
      price,
      true
    );

    _transfer(msg.sender, address(this), tokenId);

    //Emit the event for successfull transfer
    emit TokenListedSuccess(
      tokenId, 
      address(this), //owner
      msg.sender, //seller
      price, 
      true
    );
  }


}

