import React, { Component } from 'react'
import { Button, Input } from 'antd';
import { ethers } from "ethers";
import TokenArtifact from "../contracts/DirectAward.json";
import contractAddress from "../contracts/contract-address.json";
const { TextArea } = Input;


const text = `
  A dog is a type of domesticated animal.
  Known for its loyalty and faithfulness,
  it can be found as a welcome guest in many households across the world.
`;

const onChange = (key) => {
    console.log(key);
};

export default class DirectAward extends Component {

    constructor(props) {
        super(props);

        // We store multiple things in Dapp's state.
        // You don't need to follow this pattern, but it's an useful example.
        this.initialState = {
            // The info of the token (i.e. It's Name and symbol)
            tokenData: undefined,
            // The user's address and balance
            selectedAddress: undefined,
            balance: undefined,
            // The ID about transactions being sent, and any possible error with them
            txBeingSent: undefined,
            transactionError: undefined,
            networkError: undefined,
        };

        this.state = this.initialState;
    }

    render() {
        return (

            <div>
                <div style={{ marginLeft: "120px", "fontSize": "18px" }}>
                    {/* Accounts you might be interested in */}
                    <div class="alert alert-info" role="alert" style={{ width: "600px" }}>
                    </div>
                </div>
                <Button type="primary" style={{ marginLeft: "120px" , marginTop: "20px" }} onClick={() => this.depositEther()}>DepositEther</Button>


                <div style={{ marginTop: "30px", display: "flex", justifyContent: "space-between", marginLeft: "120px" }}>
                    <div class="form-group">
                        <label for="exampleFormControlTextarea1">Address list:</label>
                        <TextArea rows={4} onChange={(e) => this.textAreaChange(e)} />
                        <Button type="primary" style={{ marginTop: "20px" }} onClick={() => this.connectWallet()}>ConnectWallet</Button>
                        <Button type="primary" style={{ marginLeft: "40px", marginTop: "20px" }} onClick={() => this.transferEthsAvg()}>Award</Button>
                    </div>
                </div>
            </div>

        )

    }

    /**
    * @description: check metamsk
    * @param {*}
    * @return {bool}
    */
    async transferEthsAvg() {
        console.log(this.state.selectedAddress);
        

        this._provider = new ethers.providers.Web3Provider(window.ethereum);
        this._token = new ethers.Contract(
            contractAddress.DirectAward,
            TokenArtifact.abi,
            this._provider.getSigner(0)
        );

        let addresses = this.state.addresses;
        addresses = addresses.split(',');

        console.log(this._token);


        const tx = await this._token.transferEthsAvg(addresses);
        this.setState({ txBeingSent: tx.hash });

        // We use .wait() to wait for the transaction to be mined. This method
        // returns the transaction's receipt.
        const receipt = await tx.wait();

        // The receipt, contains a status flag, which is 0 to indicate an error.
        if (receipt.status === 0) {
            // We can't know the exact error that made the transaction fail when it
            // was mined, so we throw this generic one.
            throw new Error("Transaction failed");
        }
    }

    /**
    * @description: check metamsk
    * @param {*}
    * @return {bool}
    */
    async depositEther() {
        console.log("depositEther");

        this._provider = new ethers.providers.Web3Provider(window.ethereum);
        let send_account = await this._provider.getSigner(0).getAddress();
        console.log(send_account);


        const balance = await this._provider.getBalance('0x5FbDB2315678afecb367f032d93F642f64180aa3');
        console.log(ethers.utils.formatEther(balance.toString()));

        let tx = await this._provider.getSigner(0).sendTransaction({
            to: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
            value: ethers.utils.parseUnits("100", "ether").toHexString(),
            nonce: 0
        });

        const receipt = await tx.wait();

        console.log(receipt);
        const balance1 = await this._provider.getBalance('0x5FbDB2315678afecb367f032d93F642f64180aa3');
        console.log(ethers.utils.formatEther(balance1.toString()));
    }

    /**
     * @description: connectWallet
     * @param {*}
     * @return {*}
     */
    async connectWallet() {
        const [selectedAddress] = await window.ethereum.request({ method: 'eth_requestAccounts' });
        console.log(selectedAddress);

        this.setState({
            selectedAddress: selectedAddress,
        });

        this._initializeEthers();

    }

    async _initializeEthers() {
        // We first initialize ethers by creating a provider using window.ethereum
        this._provider = new ethers.providers.Web3Provider(window.ethereum);
        console.log("_initializeEthers");
        // Then, we initialize the contract using that provider and the token's
        // artifact. You can do this same thing with your contracts.
        this._token = new ethers.Contract(
            contractAddress.DirectAward,
            TokenArtifact.abi,
            this._provider.getSigner(0)
        );
    }


    /**
     * Save Input param to the state;
     * 
     * @param {*} e 
     */
    textAreaChange(e) {
        this.setState({
            addresses: e.target.value
        })
    }

}