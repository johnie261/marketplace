import Navbar from "./Navbar";
import NFTTile from "./NFTTile";
import MarketplaceJSON from "../Marketplace.json";
import axios from "axios";
import { useState, useEffect } from "react";
import { GetIpfsUrlFromPinata } from "../utils";

export default function Marketplace() {

const [data, updateData] = useState([]);
const [dataFetched, updateFetched] = useState(false);
const [isLoading, setIsLoading] = useState(false)

async function getAllNFTs() {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    let contract = new ethers.Contract(MarketplaceJSON.address, MarketplaceJSON.abi, signer)
    let transaction = await contract.getAllNFTs()

    const items = await Promise.all(transaction.map(async i => {
        var tokenURI = await contract.tokenURI(i.tokenId);
        console.log("getting this tokenUri", tokenURI);
        tokenURI = GetIpfsUrlFromPinata(tokenURI);
        let meta = await axios.get(tokenURI);
        meta = meta.data;

        let price = ethers.utils.formatUnits(i.price.toString(), 'ether');
        let item = {
            price,
            tokenId: i.tokenId.toNumber(),
            seller: i.seller,
            owner: i.owner,
            image: meta.image,
            name: meta.name,
            description: meta.description,
        }
        return item;
    }))

    updateFetched(true);
    updateData(items);
    setIsLoading(false);
}

useEffect(() => {
    if (!dataFetched) {
      setIsLoading(true);
      getAllNFTs();
    }
  }, [dataFetched]);

// if(!dataFetched)
//     getAllNFTs();

return (
    <div>
        <Navbar />
        <div className="flex flex-col place-items-center mt-20 h-screen">
            <div className="md:text-xl font-bold text-white">
                Top NFTs
            </div>
            <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
                {isLoading ? (
                    <div>Loading...</div>
                )
                 : (
                    data.map((value, index) => (
                        <NFTTile data={value} key={index}></NFTTile>
                )))}
            </div>
        </div>            
    </div>
);

}