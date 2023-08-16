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
      _tokenIds.increment(); //increment tokenId counter
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
    //make sure sender sent enought ETH to pay for listing
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

  //This will return all NFTs currently listed to be sold in marketPlace
  function getAllNFTs() public view returns (ListedToken[] memory) {
    uint nftCount = _tokenIds.current();
    ListedToken[] memory tokens = new ListedToken[](nftCount);
    uint currentIndex = 0;

    //currentlyListed is true for all
    for (uint i=0; i<nftCount; i++) {
      uint currentId = i + 1;
      ListedToken storage currentItem = idToListedToken[currentId];
      tokens[currentIndex] = currentItem;
      currentIndex += 1;
    }

    // tokens has the list of all available NFTs in the marketPlace
    return tokens;
  }

  //returns all the NFTs that the current user is owner or seller
  function getMyNFTs() public view returns (ListedToken[] memory) {
    uint totalItemCount = _tokenIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    //get count of all the NFTd belonging to the current user
    for(uint i=0; i<totalItemCount; i++) {
      if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
        itemCount += 1;
      }
    }

    //create an array and store all nfts in it
    ListedToken[] memory items = new ListedToken[](itemCount);

    for(uint i=0; i<totalItemCount; i++){
      if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
        uint currentId = i + 1;
        ListedToken storage currentItem = idToListedToken[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }  
    }
    return items;
  }

  //nft is transfered to new address if eth sent is equal to price
  function executeSale(uint256 tokenId) public payable {
    uint price = idToListedToken[tokenId].price;
    address seller = idToListedToken[tokenId].seller;

    require(msg.value == price, "Please submit the correct price");

    //Update the details of the token
    idToListedToken[tokenId].currentlyListed = true;
    idToListedToken[tokenId].seller = payable(msg.sender);
    _itemsSold.increment();

    //transfer token to new owner
    _transfer(address(this), msg.sender, tokenId);
    //approve marketplace to sell nfts on my behalf
    approve(address(this), tokenId);

    //transfer the listing fee to the marketplace creator
    payable(owner).transfer(listPrice);
    //Transfer the proceeds from the sale to the seller of the NFT
    payable(seller).transfer(msg.value);
  }

  // a function to resell the nft again
  function resellToken(uint256 tokenId, uint256 newPrice) public payable {
    require(_exists(tokenId), "Token does not exist");
    require(ownerOf(tokenId) == msg.sender, "Only the owner can resell the token" );
    require(idToListedToken[tokenId].currentlyListed, "Token is not currently listed");

    //make sure the sender sent enough ETH to pay for thr new listing price
    require(msg.value == listPrice, "Incorrect listing price");

    idToListedToken[tokenId].price = newPrice;

    emit TokenListedSuccess(
      tokenId, 
      ownerOf(tokenId),
      msg.sender, 
      newPrice, 
      true
    );
  }

  //update the price for listing a new token on marketplace
  function updateListPrice(uint256 _listPrice) public payable {
    require(owner == msg.sender, "Only owner can update listing price");
    listPrice = _listPrice;
  }

  function getListPrice() public view returns (uint256) {
    return listPrice;
  }

  //getting the latest listing in the marketplace
  function getLatestIdToListedToken() public view returns (ListedToken memory) {
    uint256 currentTokenId = _tokenIds.current();
    return idToListedToken[currentTokenId];
  }
  
  //get a specific listed token given the tokenid
  function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) {
    return idToListedToken[tokenId];
  }

  //get current count
  function getCurrentToken() public view returns (uint256) {
    return _tokenIds.current();
  }
}

