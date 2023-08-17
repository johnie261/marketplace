import Navbar from "./Navbar";
import { useState } from "react";
import { uploadFileToIPFS, uploadJSONToIPFS } from "../pinata";
import Marketplace from '../Marketplace.json';
import { useLocation } from "react-router";
import { ethers } from "ethers";

export default function SellNFT () {
    const [formParams, updateFormParams] = useState({ name: '', description: '', price: ''});
    const [fileURL, setFileURL] = useState(null);
    const ethers = require("ethers");
    const [message, updateMessage] = useState('');
    const location = useLocation();

    const disableButton = async() => {
      const listButton = document.getElementById("list-button");
      listButton.disable= true;
      listButton.style.background = "grey";
      list.style.opacity = 0.3;
    }

    const enableButton = async() => {
      const listButton = document.getElementById("list-button");
      listButton.disable= false;
      listButton.style.background = "A500FF";
      list.style.opacity = 1;
    }

    //function to upload NFT image to ipfs
    const onChangeFile = async(e) => {
      let file = e.target.files[0];
      try {
        //upload file to ipfs
        disableButton();
        updateMessage("Uploading image.. please dont click anything")
        const response = await uploadFileToIPFS(file);
        if(response.success) {
          enableButton()
          updateMessage("")
          console.log("Uploaded image to pinata: ", response.pinataURL)
          setFileURL(response.pinataURL)
        }
      } catch (error) {
        console.log("Error during file upload", error)
      }
    }

    const uploadJSONToIPFS = async() => {
      const {name, description, price} = formParams;
    
      if(!name || !description || !price | fileURL) {
        updateMessage("PLease fill all the fields")
        return -1;
      }

      const nftJSON = {
        name,
        description,
        price,
        image: fileURL
      }

      try {
        // upload metadata json to ipfs
        const response = await uploadJSONToIPFS(nftJSON)
        if(response.success === true) {
          console.log("Upload JSON to Pinata: ", response)
          return response.pinataURL
        }
      } catch (error) {
        console.log("error uploading JSON metadata: ", error)
      }
    }

    const listNFT = async(e) => {
      e.preventDefault();

      //upload data to ipfs
      try {
       const metadataURL = await uploadMetadataToIPFS();
       if (metadataURL === -1) return;

       //get providers and signers
       const provider = new ethers.providers.Web3Provider(window.ethereum);
       const signer = provider.getSigner();
       disableButton()
       updateMessage("Uploading NFT(takes 5 mins).. please dont click anything!")

       //get the deployed contract instance
       let contract = new ethers.Contract(
          Marketplace.address,
          Marketplace.abi,
          signer
       )

       //edit the message to be sent to create NFT request
       const price = ethers.utils.parseUnits(formParams.price, 'ether');
       let listingPrice = await contract.getListPrice();
       listingPrice = listingPrice.toString()

       //actually creating an NFT
       let transaction = await contract.createToken(metadataURL, { value: listingPrice})
       await transaction.wait()

       alert('Successfully listed NFT!')
       enableButton()
       updateMessage('')
       updateFormParams({ name: '', description: '', price: ''});
       window.location.replace("/")
      } catch (error) {
        alert("Upload error" + error)
      }
    }

    return (
        <div className="">
        <Navbar></Navbar>
        <div className="flex flex-col place-items-center mt-10" id="nftForm">
            <form className="bg-white shadow-md rounded px-8 pt-4 pb-8 mb-4">
            <h3 className="text-center font-bold text-purple-500 mb-8">Upload your NFT to the marketplace</h3>
                <div className="mb-4">
                    <label className="block text-purple-500 text-sm font-bold mb-2" htmlFor="name">NFT Name</label>
                    <input className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="name" type="text" placeholder="Axie#4563" onChange={e => updateFormParams({...formParams, name: e.target.value})} value={formParams.name}></input>
                </div>
                <div className="mb-6">
                    <label className="block text-purple-500 text-sm font-bold mb-2" htmlFor="description">NFT Description</label>
                    <textarea className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" cols="40" rows="5" id="description" type="text" placeholder="Axie Infinity Collection" value={formParams.description} onChange={e => updateFormParams({...formParams, description: e.target.value})}></textarea>
                </div>
                <div className="mb-6">
                    <label className="block text-purple-500 text-sm font-bold mb-2" htmlFor="price">Price (in ETH)</label>
                    <input className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" type="number" placeholder="Min 0.01 ETH" step="0.01" value={formParams.price} onChange={e => updateFormParams({...formParams, price: e.target.value})}></input>
                </div>
                <div>
                    <label className="block text-purple-500 text-sm font-bold mb-2" htmlFor="image">Upload Image (&lt;500 KB)</label>
                    <input type={"file"} onChange={""}></input>
                </div>
                <br></br>
                <div className="text-red-500 text-center">{message}</div>
                <button onClick={""} className="font-bold mt-10 w-full bg-purple-500 text-white rounded p-2 shadow-lg" id="list-button">
                    List NFT
                </button>
            </form>
        </div>
        </div>
    )
}